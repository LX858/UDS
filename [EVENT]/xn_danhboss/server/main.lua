---@type table?
local boss = nil
---@type table<integer, table> -- minion zombies by netId
local minions = {}
local minionCount = 0
local nextMinionAt = 0
local zoneCenter = vec3(Config.Boss.coords.x, Config.Boss.coords.y, Config.Boss.coords.z)
local respawnToken = 0
local lastBroadcast = 0
local lastSentHp = -1
local stateDirty = false -- set by frequent changes (minions), flushed by the 500ms monitor tick
local pendingRevive = {}
---@type table<integer, true> -- players currently inside the boss zone (reported by clients, verified on enter)
local zonePlayers = {}
local zoneCount = 0

RegisterNetEvent('xn_danhboss:zone', function(inside)
    local src = source
    if inside == true then
        if zonePlayers[src] then return end
        local ped = GetPlayerPed(src)
        if ped == 0 or #(GetEntityCoords(ped) - zoneCenter) > Config.Zone.radius + 15.0 then return end
        zonePlayers[src] = true
        zoneCount = zoneCount + 1
    elseif zonePlayers[src] then
        zonePlayers[src] = nil
        zoneCount = zoneCount - 1
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if zonePlayers[src] then
        zonePlayers[src] = nil
        zoneCount = zoneCount - 1
    end
end)

local ox_inventory_started = function() return GetResourceState('ox_inventory') == 'started' end

local function debugPrint(...)
    if Config.Debug then print('[xn_danhboss]', ...) end
end

local function notifyAll(description, ntype)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = Config.Text.title,
        description = description,
        type = ntype or 'inform',
        icon = 'skull',
        duration = 8000,
    })
end

local function buildState()
    if not boss then return nil end
    local c = boss.coords
    local ids = {}
    for netId in pairs(minions) do ids[#ids + 1] = netId end
    return {
        netId = boss.netId,
        hp = boss.hp,
        maxHp = boss.maxHp,
        enraged = boss.enraged,
        dead = boss.dead,
        coords = { x = c.x, y = c.y, z = c.z },
        minions = ids,
    }
end

local function broadcast(force)
    if not boss then
        TriggerClientEvent('xn_danhboss:sync', -1, nil)
        lastSentHp = -1
        return
    end
    local now = GetGameTimer()
    if force or stateDirty or boss.hp ~= lastSentHp or now - lastBroadcast > 2000 then
        stateDirty = false
        lastBroadcast = now
        lastSentHp = boss.hp
        TriggerClientEvent('xn_danhboss:sync', -1, buildState())
    end
end

lib.callback.register('xn_danhboss:getState', function()
    return buildState()
end)

local function randomInRange(range)
    return math.random(range[1], range[2])
end

local function canHit(sid)
    local ped = GetPlayerPed(sid)
    if ped == 0 or GetEntityHealth(ped) <= 0 then return false end
    if GetPlayerRoutingBucket(sid) ~= GetEntityRoutingBucket(boss.ped) then return false end
    local st = Player(sid).state
    if st.isDead or st.inLaststand then return false end
    return true, ped
end

local function applyDamage(sid, dmg, from, heavy)
    if boss.enraged then dmg = dmg * Config.Enrage.damageMult end
    TriggerClientEvent('xn_danhboss:hit', sid, math.floor(dmg), from, heavy)
end

-- Ranking storage: one row per participant, written once when the boss dies,
-- wiped when the next boss spawns, so the table never grows past one round.

local RANK_TABLE = 'xn_danhboss_ranking'

---@type { rows: table[], byCid: table<string, table>, total: integer, totalDamage: integer }
local ranking = { rows = {}, byCid = {}, total = 0, totalDamage = 0 }
local itemInfoCache = nil
local claiming = {}
local lastOpen = {}

local function getItemInfo()
    if itemInfoCache then return itemInfoCache end
    local name = Config.Rewards.item
    local ok, item = pcall(function() return exports.ox_inventory:Items(name) end)
    item = ok and item or nil
    if not item then return { name = name, label = name, image = '' } end

    local image = ('nui://ox_inventory/web/images/%s.png'):format(name)
    local custom = item.client and item.client.image
    if custom then
        image = custom:find('^nui://') and custom or ('nui://ox_inventory/web/images/%s'):format(custom)
    end
    itemInfoCache = { name = name, label = item.label or name, image = image }
    return itemInfoCache
end

local function resetRankingCache()
    ranking = { rows = {}, byCid = {}, total = 0, totalDamage = 0 }
end

-- Builds the top list and per-player lookup from rows sorted by position.
local function buildRankingCache(list)
    resetRankingCache()
    local totalDamage = 0
    for _, e in ipairs(list) do totalDamage = totalDamage + e.damage end

    local topSize = #Config.Rewards.top
    for i, e in ipairs(list) do
        ranking.byCid[e.cid] = e
        if i <= topSize then
            ranking.rows[i] = {
                rank = e.pos,
                name = e.name,
                damage = e.damage,
                percent = math.floor(e.damage / totalDamage * 1000 + 0.5) / 10,
                reward = e.reward,
            }
        end
    end
    ranking.total = #list
    ranking.totalDamage = totalDamage
end

local function loadRanking()
    local res = MySQL.query.await(('SELECT citizenid, name, damage, pos, reward, claimed FROM %s ORDER BY pos ASC'):format(RANK_TABLE))
    local list = {}
    for i, r in ipairs(res or {}) do
        list[i] = { cid = r.citizenid, name = r.name, damage = r.damage, pos = r.pos, reward = r.reward, claimed = r.claimed == 1 }
    end
    buildRankingCache(list)
    debugPrint(('ranking loaded: %d players'):format(#list))
end

local function clearRanking()
    MySQL.query.await(('DELETE FROM %s'):format(RANK_TABLE))
    resetRankingCache()
end

MySQL.ready(function()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS %s (
            citizenid VARCHAR(50) NOT NULL,
            name VARCHAR(100) NOT NULL,
            damage INT UNSIGNED NOT NULL,
            pos SMALLINT UNSIGNED NOT NULL,
            reward SMALLINT UNSIGNED NOT NULL,
            claimed TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (citizenid),
            KEY idx_pos (pos)
        ) ENGINE=InnoDB
    ]]):format(RANK_TABLE))
    loadRanking()
end)

local function buildRankingPayload(cid)
    local me = ranking.byCid[cid]
    return {
        boss = Config.Boss.label,
        item = getItemInfo(),
        rows = ranking.rows,
        me = me and { rank = me.pos, damage = me.damage, reward = me.reward, claimed = me.claimed, total = ranking.total } or nil,
    }
end

-- Runs once when the boss dies: rank, save in bulk, then open the UI for online participants.
local function finalizeRanking(b)
    local R = Config.Rewards
    local list = {}
    for _, c in pairs(b.contrib) do
        if c.damage >= R.minDamage then list[#list + 1] = c end
    end
    if #list == 0 then return end

    table.sort(list, function(x, y)
        if x.damage ~= y.damage then return x.damage > y.damage end
        return x.cid < y.cid
    end)

    local entries = {}
    for i, c in ipairs(list) do
        entries[i] = {
            cid = c.cid,
            name = c.name:sub(1, 100),
            damage = c.damage,
            pos = i,
            reward = R.top[i] or R.participation,
            claimed = false,
        }
    end

    -- Chunked multi-row inserts in one transaction.
    local queries = {}
    local CHUNK = 200
    for i = 1, #entries, CHUNK do
        local marks, params = {}, {}
        for j = i, math.min(i + CHUNK - 1, #entries) do
            local e = entries[j]
            marks[#marks + 1] = '(?, ?, ?, ?, ?)'
            params[#params + 1] = e.cid
            params[#params + 1] = e.name
            params[#params + 1] = e.damage
            params[#params + 1] = e.pos
            params[#params + 1] = e.reward
        end
        queries[#queries + 1] = {
            query = ('INSERT INTO %s (citizenid, name, damage, pos, reward) VALUES %s'):format(RANK_TABLE, table.concat(marks, ',')),
            values = params,
        }
    end

    local ok = MySQL.transaction.await(queries)
    if not ok then
        print('[xn_danhboss] ERROR: could not save the ranking to the database')
        return
    end

    buildRankingCache(entries)
    notifyAll(Config.Text.killed:format(entries[1].name, entries[1].damage), 'success')

    for _, e in ipairs(entries) do
        local player = exports.qbx_core:GetPlayerByCitizenId(e.cid)
        if player then
            local src = player.PlayerData.source
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.title,
                description = Config.Text.rankingReady,
                type = 'success',
                duration = 8000,
            })
            if R.showRanking then
                TriggerClientEvent('xn_danhboss:showRanking', src, buildRankingPayload(e.cid))
            end
        end
    end
end

lib.callback.register('xn_danhboss:getRanking', function(src)
    local now = GetGameTimer()
    if lastOpen[src] and now - lastOpen[src] < 1000 then return nil end
    lastOpen[src] = now

    if boss and not boss.dead then return nil, Config.Text.bossActive end
    if ranking.total == 0 then return nil, Config.Text.noRanking end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    return buildRankingPayload(player.PlayerData.citizenid)
end)

-- Claim is atomic in SQL (claimed 0 -> 1): the row is reserved first, the item is given second,
-- and the reservation is rolled back if the item could not be delivered to the same character.
local function doClaim(src, cid)
    local entry = ranking.byCid[cid]
    if not entry then return false, Config.Text.notParticipant end
    if entry.claimed then return false, Config.Text.alreadyClaimed end
    if not ox_inventory_started() then return false, Config.Text.inventoryFull end

    local item = Config.Rewards.item
    if not exports.ox_inventory:CanCarryItem(src, item, entry.reward) then
        return false, Config.Text.inventoryFull
    end

    local affected = MySQL.update.await(('UPDATE %s SET claimed = 1 WHERE citizenid = ? AND claimed = 0'):format(RANK_TABLE), { cid })
    if affected ~= 1 then
        entry.claimed = true
        return false, Config.Text.alreadyClaimed
    end

    -- The await above yielded: the player may have dropped and the source id been reused.
    local current = exports.qbx_core:GetPlayer(src)
    local sameCharacter = current and current.PlayerData.citizenid == cid
    local okAdd, added = false, false
    if sameCharacter then
        okAdd, added = pcall(function() return exports.ox_inventory:AddItem(src, item, entry.reward) end)
    end

    if not (okAdd and added) then
        MySQL.update.await(('UPDATE %s SET claimed = 0 WHERE citizenid = ?'):format(RANK_TABLE), { cid })
        return false, Config.Text.inventoryFull
    end

    entry.claimed = true
    print(('[xn_danhboss] claim: %s received %d x %s (rank %d)'):format(cid, entry.reward, item, entry.pos))
    return true, Config.Text.claimed:format(entry.reward, getItemInfo().label)
end

local lastClaim = {}

lib.callback.register('xn_danhboss:claim', function(src)
    local now = GetGameTimer()
    if lastClaim[src] and now - lastClaim[src] < 1500 then return false, Config.Text.busy end
    lastClaim[src] = now

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false, Config.Text.notParticipant end
    local cid = player.PlayerData.citizenid
    if claiming[cid] then return false, Config.Text.busy end

    claiming[cid] = true
    local ok, success, msg = pcall(doClaim, src, cid)
    claiming[cid] = nil

    if not ok then
        print('[xn_danhboss] claim error: ' .. tostring(success))
        return false, Config.Text.busy
    end
    return success, msg
end)

AddEventHandler('playerDropped', function()
    lastOpen[source] = nil
    lastClaim[source] = nil
end)

local function clearMinions()
    for _, m in pairs(minions) do
        if DoesEntityExist(m.ped) then DeleteEntity(m.ped) end
    end
    minions, minionCount = {}, 0
end

local spawnBoss

local function scheduleRespawn()
    if not Config.Boss.autoRespawn then return end
    respawnToken = respawnToken + 1
    local token = respawnToken
    SetTimeout(Config.Boss.respawnDelay * 1000, function()
        if token == respawnToken and (not boss or boss.dead) then
            spawnBoss()
        end
    end)
end

local reviveWindow
local lastReviveAttempt = {}

local function isDown(src)
    local st = Player(src).state['qbx_medical:deathState']
    return type(st) == 'number' and st > 1
end

local function isInReviveZone(src, bucket)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and GetPlayerRoutingBucket(src) == bucket
        and #(GetEntityCoords(ped) - zoneCenter) <= Config.Zone.radius
end

local function tryZoneRevive(src, bucket, reason)
    if not Config.Zone.enabled or not isDown(src) or not isInReviveZone(src, bucket) then return end
    local now = GetGameTimer()
    if lastReviveAttempt[src] and now - lastReviveAttempt[src] < 3000 then return end
    lastReviveAttempt[src] = now
    debugPrint(('revive request: player=%s reason=%s'):format(src, reason))
    exports.qbx_medical:Revive(src)
end

local function checkEndRevive(src)
    local window = reviveWindow
    if not window or GetGameTimer() > window.untilAt then return end
    tryZoneRevive(src, window.bucket, 'boss-ended')
end

-- Revives every downed player inside the boss zone when the boss dies or is removed.
-- Recheck for 15 seconds: medical death state can arrive after the boss death.
-- Enumerate connected players so a missed client zone-enter cannot omit anyone.
local function reviveZonePlayers()
    local Z = Config.Zone
    if not (Z.enabled and Z.reviveOnBossDeath) then return end
    local window = { untilAt = GetGameTimer() + 15000, bucket = GetEntityRoutingBucket(boss.ped) }
    reviveWindow = window
    local function sweep()
        if reviveWindow ~= window then return end
        for _, id in ipairs(GetPlayers()) do
            checkEndRevive(tonumber(id))
        end
        if GetGameTimer() < window.untilAt then
            SetTimeout(3000, sweep)
        else
            for _, id in ipairs(GetPlayers()) do
                local src = tonumber(id)
                if isDown(src) and isInReviveZone(src, window.bucket) then
                    debugPrint(('revive still pending at end of window: player=%s'):format(src))
                end
            end
            reviveWindow = nil
        end
    end
    sweep()
    TriggerClientEvent('xn_danhboss:reviveCheck', -1)
end

RegisterNetEvent('xn_danhboss:requestRevive', function()
    checkEndRevive(source)
end)

local function finishBoss()
    local b = boss
    b.dead = true
    b.hp = 0
    clearMinions()
    pendingRevive = {}
    reviveZonePlayers()
    broadcast(true)
    TriggerClientEvent('xn_danhboss:died', -1, b.netId)
    CreateThread(function() finalizeRanking(b) end)

    local ped = b.ped
    SetTimeout(Config.Boss.corpseTime, function()
        if DoesEntityExist(ped) then DeleteEntity(ped) end
        if boss == b then
            boss = nil
            broadcast(true)
        end
    end)
    scheduleRespawn()
end

local function removeBoss()
    if not boss then return false end
    local wasAlive = not boss.dead
    respawnToken = respawnToken + 1
    clearMinions()
    pendingRevive = {}
    if wasAlive then reviveZonePlayers() end
    if DoesEntityExist(boss.ped) then DeleteEntity(boss.ped) end
    boss = nil
    broadcast(true)
    return true
end

spawnBoss = function()
    if boss and not boss.dead then return false, 'Boss đang tồn tại.' end
    if boss then removeBoss() end
    reviveWindow = nil
    clearRanking() -- the previous round's ranking ends when the next boss starts

    local B = Config.Boss
    local c = B.coords
    local ped = CreatePed(4, B.model, c.x, c.y, c.z, c.w, true, true)
    local tries = 0
    while not DoesEntityExist(ped) and tries < 50 do
        Wait(100)
        tries = tries + 1
    end
    if not DoesEntityExist(ped) then return false, 'Không tạo được ped (kiểm tra OneSync/model).' end

    -- Keep the entity alive for far players and avoid falling through unloaded collision.
    SetEntityDistanceCullingRadius(ped, 500.0)
    SetEntityOrphanMode(ped, 2) -- keep the entity when no client owns it (otherwise it is culled)
    FreezeEntityPosition(ped, true)

    boss = {
        ped = ped,
        netId = NetworkGetNetworkIdFromEntity(ped),
        maxHp = B.health,
        hp = B.health,
        coords = vec3(c.x, c.y, c.z),
        enraged = false,
        dead = false,
        ready = false,
        confirmed = false,
        readyAt = 0,
        missing = 0,
        lastMelee = 0,
        lastSlam = 0,
        contrib = {},
        bySrc = {},
    }
    broadcast(true)
    notifyAll(Config.Text.spawned, 'warning')
    debugPrint('boss spawned', boss.netId)
    return true
end

local function monitor()
    local ped = boss.ped
    if not DoesEntityExist(ped) then
        boss.missing = boss.missing + 1
        if boss.missing >= 10 then
            debugPrint('boss entity lost, respawning')
            removeBoss()
            spawnBoss()
        end
        return
    end
    boss.missing = 0
    boss.coords = GetEntityCoords(ped)
    local now = GetGameTimer()

    if not boss.confirmed then
        broadcast(false)
        return
    end

    if not boss.enraged and boss.hp <= boss.maxHp * Config.Enrage.threshold and boss.hp > 0 then
        boss.enraged = true
        notifyAll(Config.Text.enraged, 'error')
        broadcast(true)
    end

    if boss.hp <= 0 then
        finishBoss()
        return
    end
    broadcast(false)
end

CreateThread(function()
    while true do
        Wait(500)
        if boss and not boss.dead then monitor() end
    end
end)

-- Owner client finished initialising health/flags on the entity.
RegisterNetEvent('xn_danhboss:ready', function(netId)
    local src = source
    if not boss or boss.dead or boss.ready or netId ~= boss.netId then return end
    if NetworkGetEntityOwner(boss.ped) ~= src then return end
    boss.ready = true
    boss.confirmed = true
    boss.readyAt = GetGameTimer()
    Entity(boss.ped).state:set('xnReady', true, true)
    debugPrint('boss initialised by', src)
end)

local function isBossOwner(src)
    return boss and boss.confirmed and not boss.dead and DoesEntityExist(boss.ped)
        and NetworkGetEntityOwner(boss.ped) == src
end

RegisterNetEvent('xn_danhboss:melee', function(targetSid)
    local src = source
    if not isBossOwner(src) then return end
    targetSid = tonumber(targetSid)
    if not targetSid then return end

    local M = Config.Melee
    local now = GetGameTimer()
    local cd = M.cooldown * (boss.enraged and Config.Enrage.cooldownMult or 1.0) * 0.6
    if now - boss.lastMelee < cd then return end

    local ok, tPed = canHit(targetSid)
    if not ok then return end
    local bpos = GetEntityCoords(boss.ped)
    if #(bpos - GetEntityCoords(tPed)) > M.range + M.tolerance then return end

    boss.lastMelee = now
    applyDamage(targetSid, randomInRange(M.damage), bpos, false)
end)

RegisterNetEvent('xn_danhboss:gunWarn', function(targetSid)
    local src = source
    if not isBossOwner(src) then return end
    targetSid = math.tointeger(targetSid)
    if not targetSid or GetPlayerPed(targetSid) == 0 then return end
    TriggerClientEvent('ox_lib:notify', targetSid, {
        title = Config.Text.title,
        description = Config.Text.gunWarn,
        type = 'error',
        icon = 'gun',
    })
end)

RegisterNetEvent('xn_danhboss:slam', function()
    local src = source
    if not isBossOwner(src) then return end

    local S = Config.Slam
    local now = GetGameTimer()
    local cd = S.cooldown * (boss.enraged and Config.Enrage.cooldownMult or 1.0) * 0.8
    if now - boss.lastSlam < cd then return end
    boss.lastSlam = now

    local pos = GetEntityCoords(boss.ped)
    TriggerClientEvent('xn_danhboss:slamWarn', -1, pos, S.radius, S.delay)

    local b = boss
    SetTimeout(S.delay, function()
        if boss ~= b or b.dead then return end
        for sid in pairs(zonePlayers) do
            local ok, tPed = canHit(sid)
            if ok and #(GetEntityCoords(tPed) - pos) <= S.radius then
                applyDamage(sid, randomInRange(S.damage), pos, true)
            end
        end
        TriggerClientEvent('xn_danhboss:slamFx', -1, pos, S.radius)
    end)
end)

-- Weapon damage table: manual overrides first, then neons_ddame's config.lua (kept in sync).
local weaponDamage = {}

local function normHash(h)
    return h & 0xFFFFFFFF
end

local function loadWeaponDamage()
    local D = Config.Damage
    weaponDamage = {}

    local res = D.syncResource
    if res and res ~= '' and GetResourceState(res) ~= 'missing' then
        local code = LoadResourceFile(res, 'config.lua')
        local env = setmetatable({}, { __index = _G })
        local fn = code and load(code, '@' .. res .. '/config.lua', 't', env)
        local ok = fn and pcall(fn)
        local cfg = ok and rawget(env, 'Config')
        if cfg and type(cfg.WeaponDamages) == 'table' then
            local n = 0
            for hash, w in pairs(cfg.WeaponDamages) do
                if math.tointeger(hash) and w.damage then
                    weaponDamage[normHash(hash)] = w
                    n = n + 1
                end
            end
            debugPrint(('loaded %d weapons from %s'):format(n, res))
        else
            print(('[xn_danhboss] could not read WeaponDamages from %s'):format(res))
        end
    end

    for hash, w in pairs(D.weapons) do
        weaponDamage[normHash(hash)] = w
    end
end

CreateThread(loadWeaponDamage)

AddEventHandler('onResourceStart', function(res)
    if res == Config.Damage.syncResource then loadWeaponDamage() end
end)

local function addContribution(src, damage)
    local c = boss.bySrc[src]
    if not c then
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return end
        local cid = player.PlayerData.citizenid
        c = boss.contrib[cid]
        if not c then
            local info = player.PlayerData.charinfo
            c = { cid = cid, src = src, damage = 0, name = ('%s %s'):format(info.firstname, info.lastname) }
            boss.contrib[cid] = c
        end
        boss.bySrc[src] = c
    end
    c.src = src
    c.damage = c.damage + damage
end

local hitWindow = {}

AddEventHandler('playerDropped', function()
    hitWindow[source] = nil
    if boss then boss.bySrc[source] = nil end
end)

-- Per-attacker rate limit shared by boss and minion hits; returns how many of `count` hits are allowed.
local function takeHits(attackerSid, count)
    local now = GetGameTimer()
    local w = hitWindow[attackerSid]
    if not w or now - w.start >= 1000 then
        w = { start = now, count = 0 }
        hitWindow[attackerSid] = w
    end
    local allowed = math.max(0, math.min(count, Config.Damage.maxHitsPerSecond - w.count))
    w.count = w.count + allowed
    return allowed
end

-- Damage a player hit deals to `targetEntity` (boss or minion), or nil if the hit is invalid.
local function calcHitDamage(attackerSid, weaponHash, isHead, baseDamage, targetEntity)
    local D = Config.Damage
    local ped = GetPlayerPed(attackerSid)
    if ped == 0 or GetEntityHealth(ped) <= 0 then return nil end

    local cfg = weaponDamage[normHash(weaponHash)]
    local range = (cfg and cfg.maxRange or D.defaultMaxRange) + 3.0
    if #(GetEntityCoords(ped) - GetEntityCoords(targetEntity)) > range then
        if Config.Debug then debugPrint('hit rejected: out of range', attackerSid, weaponHash) end
        return nil
    end

    local dmg
    if cfg then
        dmg = isHead and (cfg.headshot or cfg.damage) or cfg.damage
    else
        dmg = math.max(1, math.min(tonumber(baseDamage) or 1, D.unlistedMax))
        if isHead then dmg = dmg * D.headMult end
    end
    dmg = math.floor(dmg * D.multiplier)
    return dmg > 0 and dmg or nil
end

-- Minion zombies: up to Config.Minions.max alive at once inside the zone while the boss lives.
-- Their damage never counts for the ranking.

local function removeMinion(netId, m)
    minions[netId] = nil
    minionCount = minionCount - 1
    local ped = m.ped
    SetTimeout(Config.Minions.corpseTime, function()
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end)
end

local function spawnMinion()
    local M = Config.Minions
    local owner = NetworkGetEntityOwner(boss.ped)
    if not owner or owner == 0 then return false end

    local angle = math.random() * 2 * math.pi
    local r = math.sqrt(math.random()) * Config.Zone.radius
    local x, y = zoneCenter.x + math.cos(angle) * r, zoneCenter.y + math.sin(angle) * r

    -- The client resolves ground height (the server cannot) and rejects spots too close to players.
    local ok, z = pcall(lib.callback.await, 'xn_danhboss:findSpawn', owner, x, y, zoneCenter.z)
    if not ok or not z then return false end

    local model = M.models[math.random(#M.models)]
    local ped = CreatePed(4, model, x, y, z, math.random(0, 359) + 0.0, true, true)
    local tries = 0
    while not DoesEntityExist(ped) and tries < 30 do
        Wait(100)
        tries = tries + 1
    end
    if not DoesEntityExist(ped) then return false end

    SetEntityDistanceCullingRadius(ped, 300.0)
    SetEntityOrphanMode(ped, 2)
    local netId = NetworkGetNetworkIdFromEntity(ped)
    Entity(ped).state:set('xnMinion', true, true)

    minions[netId] = { ped = ped, netId = netId, hp = M.hp, lastHit = 0 }
    minionCount = minionCount + 1
    stateDirty = true
    return true
end

local function anyPlayerInZone()
    if zoneCount == 0 then return false end
    for src in pairs(zonePlayers) do
        local ped = GetPlayerPed(src)
        if ped ~= 0 and GetEntityHealth(ped) > 0 then return true end
    end
    return false
end

CreateThread(function()
    while true do
        Wait(1000)
        local M = Config.Minions
        if M.enabled and boss and boss.confirmed and not boss.dead then
            local changed = false
            for netId, m in pairs(minions) do
                if not DoesEntityExist(m.ped) then
                    minions[netId] = nil
                    minionCount = minionCount - 1
                    changed = true
                end
            end
            if changed then stateDirty = true end

            local now = GetGameTimer()
            if minionCount < M.max and now >= nextMinionAt and anyPlayerInZone() then
                nextMinionAt = now + M.spawnInterval
                spawnMinion()
            end
        end
    end
end)

-- The owner client of the boss/minions receives the damage events (the attacker client does not
-- reliably get them) and reports who hit what in batches; the server decides the damage.
-- Entry: { t = target netId (0 = boss), a = attacker server id, w = weapon, h = headshot, b = base damage, n = hit count }
local MAX_BATCH = 64

local function applyBossHits(src, e, attackerSid, weapon, count)
    if not isBossOwner(src) then return end
    local allowed = takeHits(attackerSid, count)
    if allowed <= 0 then return end

    local dmg = calcHitDamage(attackerSid, weapon, e.h, e.b, boss.ped)
    if not dmg then return end
    dmg = math.min(dmg * allowed, boss.hp)
    if dmg <= 0 then return end

    boss.hp = boss.hp - dmg
    addContribution(attackerSid, dmg)
    if Config.Debug then debugPrint(('hit %d by %d weapon %d, hp %d'):format(dmg, attackerSid, weapon, boss.hp)) end
    if boss.hp <= 0 then finishBoss() end
end

local function applyMinionHits(src, e, attackerSid, weapon, count)
    local m = minions[e.t]
    if not m or not DoesEntityExist(m.ped) or NetworkGetEntityOwner(m.ped) ~= src then return end
    local allowed = takeHits(attackerSid, count)
    if allowed <= 0 then return end

    local dmg = calcHitDamage(attackerSid, weapon, e.h, e.b, m.ped)
    if not dmg then return end

    m.hp = m.hp - dmg * allowed
    if m.hp <= 0 then
        removeMinion(e.t, m)
        nextMinionAt = math.max(nextMinionAt, GetGameTimer() + Config.Minions.respawnDelay)
        TriggerClientEvent('xn_danhboss:minionDied', -1, e.t)
        stateDirty = true
    end
end

RegisterNetEvent('xn_danhboss:hits', function(batch)
    local src = source
    if type(batch) ~= 'table' or not boss or boss.dead or not boss.confirmed then return end

    for i = 1, math.min(#batch, MAX_BATCH) do
        local e = batch[i]
        if type(e) == 'table' then
            e.t = math.tointeger(e.t)
            local attackerSid = math.tointeger(e.a)
            local weapon = math.tointeger(e.w)
            local count = math.tointeger(e.n)
            if e.t and attackerSid and weapon and count and count > 0 then
                count = math.min(count, Config.Damage.maxHitsPerSecond)
                if e.t == 0 then
                    applyBossHits(src, e, attackerSid, weapon, count)
                else
                    applyMinionHits(src, e, attackerSid, weapon, count)
                end
                if boss.dead then return end
            end
        end
    end
end)

RegisterNetEvent('xn_danhboss:minionHit', function(netId, targetSid)
    local src = source
    netId = math.tointeger(netId)
    targetSid = math.tointeger(targetSid)
    local m = netId and minions[netId]
    if not m or not targetSid or not boss or boss.dead then return end
    if not DoesEntityExist(m.ped) or NetworkGetEntityOwner(m.ped) ~= src then return end

    local M = Config.Minions
    local now = GetGameTimer()
    if now - m.lastHit < M.cooldown * 0.6 then return end

    local ok, tPed = canHit(targetSid)
    if not ok then return end
    local mpos = GetEntityCoords(m.ped)
    if #(mpos - GetEntityCoords(tPed)) > M.attackRange + M.tolerance then return end

    m.lastHit = now
    TriggerClientEvent('xn_danhboss:hit', targetSid, randomInRange(M.damage), mpos, false, {
        shake = M.shake,
        ragdoll = M.ragdoll,
    })
end)

-- Players who go down inside the boss zone are revived in place by qbx_medical after a delay.
-- Auto-revive is strictly enabled ONLY when the boss is active (spawned and alive).

local function startZoneRevive(src)
    local Z = Config.Zone
    if not Z.enabled then return end
    if not (boss and not boss.dead) then return end

    local round = boss
    local bucket = GetEntityRoutingBucket(round.ped)
    if not isInReviveZone(src, bucket) then return end

    if pendingRevive[src] then return end
    TriggerClientEvent('xn_danhboss:hideDeathScreen', src)

    -- A unique ticket prevents an older death/disconnect timer from consuming a new one.
    local ticket = {}
    pendingRevive[src] = ticket
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.Text.title,
        description = Config.Text.reviveSoon:format(Z.reviveDelay),
        type = 'inform',
        icon = 'heart-pulse',
        duration = 6000,
    })

    local attempts = 0
    local function attempt()
        if pendingRevive[src] ~= ticket then return end
        if not (Config.Zone.enabled and boss == round and not round.dead)
            or not isDown(src) or not isInReviveZone(src, bucket) then
            pendingRevive[src] = nil
            TriggerClientEvent('xn_danhboss:restoreDeathScreen', src)
            return
        end
        if attempts >= 5 then
            pendingRevive[src] = nil
            debugPrint(('revive not confirmed after retries: player=%s'):format(src))
            TriggerClientEvent('xn_danhboss:restoreDeathScreen', src)
            return
        end
        attempts = attempts + 1
        tryZoneRevive(src, bucket, 'zone-delay')
        SetTimeout(3000, attempt)
    end
    SetTimeout(Z.reviveDelay * 1000, attempt)
end

-- Instant reaction when qbx_medical flags the player as down.
AddStateBagChangeHandler('qbx_medical:deathState', nil, function(bagName, _, value)
    local src = GetPlayerFromStateBagName(bagName)
    if not src or src == 0 then return end
    if type(value) ~= 'number' or value <= 1 then
        pendingRevive[src] = nil
        return
    end
    -- The new value is not necessarily readable from the bag during this callback.
    SetTimeout(0, function() checkEndRevive(src) end)
    startZoneRevive(src)
end)

-- Fallback for players already down inside the zone when the boss spawns.
CreateThread(function()
    while true do
        Wait(5000)
        if Config.Zone.enabled and boss and not boss.dead then
            for _, id in ipairs(GetPlayers()) do
                local src = tonumber(id)
                if isDown(src) then startZoneRevive(src) end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    pendingRevive[source] = nil
    lastReviveAttempt[source] = nil
end)

lib.addCommand('spawnboss', {
    help = 'Triệu hồi Boss Zombie',
    restricted = 'group.admin',
}, function(source)
    local ok, err = spawnBoss()
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = Config.Text.title,
            description = ok and 'Đã triệu hồi boss.' or err,
            type = ok and 'success' or 'error',
        })
    end
end)

lib.addCommand('removeboss', {
    help = 'Xóa Boss Zombie (không thưởng, không respawn tự động)',
    restricted = 'group.admin',
}, function(source)
    local ok = removeBoss()
    if source > 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = Config.Text.title,
            description = ok and 'Đã xóa boss.' or 'Không có boss.',
            type = ok and 'success' or 'error',
        })
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if boss and DoesEntityExist(boss.ped) then DeleteEntity(boss.ped) end
    clearMinions()
end)

CreateThread(function()
    if not Config.Boss.spawnOnStart then return end
    Wait(Config.Boss.startDelay * 1000)
    for _ = 1, 10 do
        local ok, err = spawnBoss()
        if ok or boss then return end
        print('[xn_danhboss] spawn failed: ' .. tostring(err) .. ' (retry in 10s)')
        Wait(10000)
    end
end)

for _, schedule in ipairs(Config.Boss.spawnSchedule) do
    lib.cron.new(schedule, function()
        if boss and not boss.dead then
            debugPrint(('scheduled spawn skipped (%s): boss is still active'):format(schedule))
            return
        end

        local ok, err = spawnBoss()
        if not ok then
            print(('[xn_danhboss] scheduled spawn failed (%s): %s'):format(schedule, tostring(err)))
        end
    end)
end
