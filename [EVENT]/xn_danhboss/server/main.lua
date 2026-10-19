---@type table?
local boss = nil
local respawnToken = 0
local lastBroadcast = 0
local lastSentHp = -1

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
    return {
        netId = boss.netId,
        hp = boss.hp,
        maxHp = boss.maxHp,
        enraged = boss.enraged,
        dead = boss.dead,
        coords = { x = c.x, y = c.y, z = c.z },
    }
end

local function broadcast(force)
    if not boss then
        TriggerClientEvent('xn_danhboss:sync', -1, nil)
        lastSentHp = -1
        return
    end
    local now = GetGameTimer()
    if force or boss.hp ~= lastSentHp or now - lastBroadcast > 2000 then
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

local function giveRewards()
    local R = Config.Rewards
    local list, total = {}, 0
    for _, c in pairs(boss.contrib) do
        if c.damage >= R.minDamage then
            list[#list + 1] = c
            total = total + c.damage
        end
    end
    table.sort(list, function(a, b) return a.damage > b.damage end)

    local rewarded = {}
    for i, c in ipairs(list) do
        local player = exports.qbx_core:GetPlayerByCitizenId(c.cid)
        if player then
            local src = player.PlayerData.source
            rewarded[src] = true
            local cash = R.baseCash + math.floor(R.cashPool * c.damage / total)
            if i == 1 then cash = cash + R.topBonus end
            player.Functions.AddMoney('cash', cash, 'xn_danhboss-reward')

            if ox_inventory_started() then
                for _, it in ipairs(R.items) do
                    if math.random(100) <= it.chance then
                        local count = math.random(it.min, it.max)
                        if exports.ox_inventory:CanCarryItem(src, it.name, count) then
                            exports.ox_inventory:AddItem(src, it.name, count)
                        end
                    end
                end
            end

            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.Text.title,
                description = Config.Text.reward:format(cash),
                type = 'success',
                icon = 'sack-dollar',
            })
        end
    end

    for _, c in pairs(boss.contrib) do
        if c.damage < R.minDamage then
            TriggerClientEvent('ox_lib:notify', c.src, {
                title = Config.Text.title,
                description = Config.Text.noReward,
                type = 'error',
            })
        end
    end

    if list[1] then
        notifyAll(Config.Text.killed:format(list[1].name, list[1].damage), 'success')
    end
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

local function finishBoss()
    local b = boss
    b.dead = true
    b.hp = 0
    broadcast(true)
    TriggerClientEvent('xn_danhboss:died', -1, b.netId)
    giveRewards()

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
    respawnToken = respawnToken + 1
    if DoesEntityExist(boss.ped) then DeleteEntity(boss.ped) end
    boss = nil
    broadcast(true)
    return true
end

spawnBoss = function()
    if boss and not boss.dead then return false, 'Boss đang tồn tại.' end
    if boss then removeBoss() end

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
        attributed = 0,
        lastDealt = {},
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
        if boss.ready then
            if GetEntityHealth(ped) > 200 then
                boss.confirmed = true
            elseif now - boss.readyAt > 10000 then
                boss.ready = false
                Entity(ped).state:set('xnReady', false, true)
            end
        end
        broadcast(false)
        return
    end

    local hp = math.max(0, math.min(boss.maxHp, GetEntityHealth(ped) - Config.HealthOffset))
    boss.hp = math.min(boss.hp, hp)

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
    boss.readyAt = GetGameTimer()
    Entity(boss.ped).state:set('xnReady', true, true)
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
        for _, pid in ipairs(GetPlayers()) do
            local sid = tonumber(pid)
            local ok, tPed = canHit(sid)
            if ok and #(GetEntityCoords(tPed) - pos) <= S.radius then
                applyDamage(sid, randomInRange(S.damage), pos, true)
            end
        end
        TriggerClientEvent('xn_danhboss:slamFx', -1, pos, S.radius)
    end)
end)

-- Damage attribution: clients report the boss hp they observed dropping after their hits.
-- Server caps the total at the real hp lost, so inflated reports cannot exceed reality.
RegisterNetEvent('xn_danhboss:dealt', function(amount)
    local src = source
    if not boss or not boss.confirmed or boss.dead then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local now = GetGameTimer()
    if boss.lastDealt[src] and now - boss.lastDealt[src] < 800 then return end
    boss.lastDealt[src] = now

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local unattributed = (boss.maxHp - boss.hp) - boss.attributed
    local accepted = math.floor(math.min(amount, unattributed, 3000))
    if accepted <= 0 then return end

    local cid = player.PlayerData.citizenid
    local c = boss.contrib[cid]
    if not c then
        local info = player.PlayerData.charinfo
        c = { cid = cid, src = src, damage = 0, name = ('%s %s'):format(info.firstname, info.lastname) }
        boss.contrib[cid] = c
    end
    c.src = src
    c.damage = c.damage + accepted
    boss.attributed = boss.attributed + accepted
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
end)

CreateThread(function()
    if not Config.Boss.spawnOnStart then return end
    Wait(Config.Boss.startDelay * 1000)
    local ok, err = spawnBoss()
    if not ok then print('[xn_danhboss] ' .. tostring(err)) end
end)
