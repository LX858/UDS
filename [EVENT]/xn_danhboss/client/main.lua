local state = nil
local blip = nil
local zoneBlip = nil
local shownHp = 0.0
local telegraphs = {}

local AI = Config.AI

local function debugPrint(...)
    if Config.Debug then print('[xn_danhboss]', ...) end
end

local function resolvePed()
    if not state or state.dead then return 0 end
    if NetworkDoesEntityExistWithNetworkId(state.netId) then
        local ped = NetworkGetEntityFromNetworkId(state.netId)
        if DoesEntityExist(ped) then return ped end
    end
    return 0
end

local function updateBlip()
    local showZone = state and not state.dead and Config.Zone.enabled and Config.Zone.blip
    if showZone and not (zoneBlip and DoesBlipExist(zoneBlip)) then
        local h = Config.Boss.coords
        zoneBlip = AddBlipForRadius(h.x, h.y, h.z, Config.Zone.radius)
        SetBlipColour(zoneBlip, Config.Blip.color)
        SetBlipAlpha(zoneBlip, 110)
    elseif not showZone and zoneBlip then
        RemoveBlip(zoneBlip)
        zoneBlip = nil
    end

    if not state or state.dead then
        if blip then RemoveBlip(blip) blip = nil end
        return
    end
    local c = state.coords
    if not blip or not DoesBlipExist(blip) then
        local B = Config.Blip
        blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(blip, B.sprite)
        SetBlipColour(blip, B.color)
        SetBlipScale(blip, B.scale)
        SetBlipAsShortRange(blip, false)
        SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Boss.label)
        EndTextCommandSetBlipName(blip)
    end
    SetBlipCoords(blip, c.x, c.y, c.z)
end

local restoreDeathScreenIfNeeded

RegisterNetEvent('xn_danhboss:sync', function(data)
    if data and (not state or state.netId ~= data.netId) then
        shownHp = data.hp + 0.0
    end
    state = data
    updateBlip()
    if not (state and not state.dead) and restoreDeathScreenIfNeeded then
        restoreDeathScreenIfNeeded()
    end
end)

CreateThread(function()
    Wait(2000)
    local data = lib.callback.await('xn_danhboss:getState', false)
    if data and not state then
        state = data
        shownHp = data.hp + 0.0
        updateBlip()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if blip then RemoveBlip(blip) end
        if zoneBlip then RemoveBlip(zoneBlip) end
        if restoreDeathScreenIfNeeded then restoreDeathScreenIfNeeded() end
    end
end)

-- Zone Death Screen & Revive Handling
local deathScreenHiddenByBoss = false
local deathScreenGeneration = 0

local function isInsideBossZone()
    local ped = cache.ped or PlayerPedId()
    if not ped or ped == 0 then return false end
    local pcoords = GetEntityCoords(ped)
    local h = Config.Boss.coords
    return #(pcoords - vec3(h.x, h.y, h.z)) <= Config.Zone.radius
end

local function isBossActive()
    return state and not state.dead
end

-- force = true when the server already validated zone + boss (no local checks needed)
local function hideBossZoneDeathScreen(force)
    if not force then
        if not Config.Zone.enabled then return end
        if not isBossActive() then return end
        if not isInsideBossZone() then return end
    end

    deathScreenHiddenByBoss = true
    deathScreenGeneration = deathScreenGeneration + 1
    local generation = deathScreenGeneration
    CreateThread(function()
        for _ = 1, 5 do
            if not deathScreenHiddenByBoss or generation ~= deathScreenGeneration then return end
            exports.qbx_medical:HideDeathScreen()
            Wait(200)
        end
    end)
end

restoreDeathScreenIfNeeded = function()
    if not deathScreenHiddenByBoss then return end
    deathScreenHiddenByBoss = false
    local st = LocalPlayer.state['qbx_medical:deathState']
    if st and st > 1 then
        pcall(function()
            exports.qbx_medical:HideDeathUI()
            Wait(100)
            exports.qbx_medical:ShowDeathUI()
        end)
    end
end

RegisterNetEvent('xn_danhboss:hideDeathScreen', function()
    hideBossZoneDeathScreen(true)
end)

RegisterNetEvent('xn_danhboss:died', function()
    restoreDeathScreenIfNeeded()
end)

RegisterNetEvent('xn_danhboss:restoreDeathScreen', function()
    restoreDeathScreenIfNeeded()
end)

RegisterNetEvent('xn_danhboss:reviveCheck', function()
    Wait(1500) -- let the server-side revive finish first
    if not isInsideBossZone() then return end
    local st = LocalPlayer.state['qbx_medical:deathState']
    if st and st > 1 then
        TriggerServerEvent('xn_danhboss:requestRevive')
    end
end)

AddEventHandler('qbx_medical:client:onPlayerDied', function()
    hideBossZoneDeathScreen()
end)

AddEventHandler('qbx_medical:client:onPlayerLaststand', function()
    hideBossZoneDeathScreen()
end)

AddStateBagChangeHandler('qbx_medical:deathState', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value and value > 1 then
        hideBossZoneDeathScreen()
    else
        deathScreenHiddenByBoss = false
    end
end)

AddEventHandler('qbx_medical:client:onPlayerRevived', function()
    deathScreenHiddenByBoss = false
end)

CreateThread(function()
    while true do
        if deathScreenHiddenByBoss then
            local st = LocalPlayer.state['qbx_medical:deathState']
            if not st or st <= 1 then
                deathScreenHiddenByBoss = false
            elseif not isInsideBossZone() then
                restoreDeathScreenIfNeeded()
            end
        end
        Wait(1000)
    end
end)

-- Health bar above the boss head

local function drawText(text, x, y, scale, r, g, b)
    SetTextFont(4)
    SetTextScale(0.0, scale)
    SetTextColour(r, g, b, 255)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawBar(worldPos, dist)
    local onScreen, sx, sy = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z)
    if not onScreen then return end

    local B = Config.Bar
    local scale = math.max(0.6, math.min(1.0, 12.0 / dist))
    local w, h = B.width * scale, B.height * scale
    local pct = math.max(0.0, math.min(1.0, shownHp / state.maxHp))

    local r, g, b
    if state.enraged then
        local pulse = (math.sin(GetGameTimer() / 120.0) + 1.0) / 2.0
        r, g, b = 235, math.floor(30 + 40 * pulse), 25
    elseif pct > 0.6 then
        r, g, b = 80, 195, 90
    elseif pct > 0.3 then
        r, g, b = 235, 185, 50
    else
        r, g, b = 220, 60, 45
    end

    -- Keep the border the same thickness horizontally and vertically.
    local padX = 0.0014 * scale
    local padY = padX * GetAspectRatio(false)

    DrawRect(sx, sy, w + padX * 2, h + padY * 2, 0, 0, 0, 185)
    DrawRect(sx, sy, w, h, 38, 32, 44, 235)

    local fill = w * pct
    if fill > 0.0 then
        local cx = sx - w / 2 + fill / 2
        DrawRect(cx, sy, fill, h, r * 0.7, g * 0.7, b * 0.7, 255)
        DrawRect(cx, sy - h / 4, fill, h / 2, math.min(255, r + 40), math.min(255, g + 40), math.min(255, b + 40), 255)
    end

    for i = 1, 3 do
        DrawRect(sx - w / 2 + w * i / 4, sy, 0.0006 * scale, h, 0, 0, 0, 150)
    end

    local label = state.enraged and (Config.Boss.label .. '  -  ENRAGE') or Config.Boss.label
    local lr, lg, lb = 240, 240, 240
    if state.enraged then lr, lg, lb = 255, 120, 100 end
    drawText(label, sx, sy - h / 2 - padY - 0.026 * scale, 0.26 * scale, lr, lg, lb)
    drawText(('%d / %d'):format(math.ceil(shownHp), state.maxHp), sx, sy + h / 2 + padY + 0.0015 * scale, 0.2 * scale, 215, 215, 215)
end

CreateThread(function()
    while true do
        local sleep = 500
        if state and not state.dead then
            local ped = resolvePed()
            if ped ~= 0 then
                local dist = #(GetEntityCoords(cache.ped) - GetEntityCoords(ped))
                if dist <= Config.Bar.drawDistance and not IsEntityDead(ped) then
                    sleep = 0
                    shownHp = shownHp + (state.hp - shownHp) * 0.15
                    local head = GetPedBoneCoords(ped, 31086, 0.0, 0.0, Config.Bar.headOffset)
                    drawBar(head, dist)
                end
            end
        end
        Wait(sleep)
    end
end)

-- Slam telegraph and effects

RegisterNetEvent('xn_danhboss:slamWarn', function(pos, radius, delay)
    telegraphs[#telegraphs + 1] = { pos = pos, radius = radius, startAt = GetGameTimer(), delay = delay }
end)

RegisterNetEvent('xn_danhboss:slamFx', function(pos, radius)
    local dist = #(GetEntityCoords(cache.ped) - pos)
    if dist < 60.0 then
        ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', math.max(0.05, 0.3 - dist / 200.0))
    end
    if dist < 150.0 then
        lib.requestNamedPtfxAsset('core')
        UseParticleFxAsset('core')
        StartParticleFxNonLoopedAtCoord('ent_dst_concrete_large', pos.x, pos.y, pos.z - 0.9, 0.0, 0.0, 0.0, radius / 2.0, false, false, false)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        if #telegraphs > 0 then
            sleep = 0
            local now = GetGameTimer()
            local playerPos = GetEntityCoords(cache.ped)
            for i = #telegraphs, 1, -1 do
                local t = telegraphs[i]
                local progress = (now - t.startAt) / t.delay
                if progress >= 1.0 then
                    table.remove(telegraphs, i)
                elseif #(playerPos - t.pos) < 150.0 then
                    local d = t.radius * 2.0
                    DrawMarker(1, t.pos.x, t.pos.y, t.pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, d, d, 0.5,
                        255, 30, 0, math.floor(60 + 90 * progress), false, false, 2, false, nil, nil, false)
                    local f = t.radius * 2.0 * progress
                    DrawMarker(1, t.pos.x, t.pos.y, t.pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, f, f, 0.6,
                        255, 120, 0, 140, false, false, 2, false, nil, nil, false)
                end
            end
        end
        Wait(sleep)
    end
end)

-- Damage received from the boss (server decides, client applies)

RegisterNetEvent('xn_danhboss:hit', function(dmg, from, heavy, opts)
    opts = opts or {}
    local ped = cache.ped
    if IsEntityDead(ped) then return end

    ApplyDamageToPed(ped, dmg, false)
    if opts.shake ~= false then
        local shake = opts.shake
        local shakeName = shake and shake.name or (heavy and 'LARGE_EXPLOSION_SHAKE' or 'SMALL_EXPLOSION_SHAKE')
        local shakeAmount = shake and shake.amount or (heavy and 0.25 or 0.1)
        ShakeGameplayCam(shakeName, shakeAmount)
    end

    if IsPedInAnyVehicle(ped, false) then return end
    local ragdoll = opts.ragdoll
    if ragdoll == nil then ragdoll = heavy or math.random() < Config.Melee.ragdollChance end
    if ragdoll then
        local dir = GetEntityCoords(ped) - from
        dir = vec3(dir.x, dir.y, 0.0)
        if #dir < 0.01 then dir = GetEntityForwardVector(ped) else dir = dir / #dir end
        local force = heavy and 14.0 or 6.0
        SetPedToRagdoll(ped, heavy and 2000 or 1200, heavy and 2000 or 1200, 0, false, false, false)
        ApplyForceToEntity(ped, 1, dir.x * force, dir.y * force, force * 0.5, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    end
end)

RegisterNetEvent('xn_danhboss:died', function(netId)
    if blip then RemoveBlip(blip) blip = nil end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end
    local ped = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(ped) and NetworkGetEntityOwner(ped) == cache.playerId then
        FreezeEntityPosition(ped, false)
        SetEntityHealth(ped, 0)
    end
end)

-- Damage ranking UI

local uiOpen = false

local function openRanking(data)
    uiOpen = true
    SendNUIMessage({ action = 'open', data = data })
    SetNuiFocus(true, true)
end

RegisterNetEvent('xn_danhboss:showRanking', openRanking)

RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('claim', function(_, cb)
    local ok, msg = lib.callback.await('xn_danhboss:claim', false)
    lib.notify({ title = Config.Text.title, description = msg, type = ok and 'success' or 'error' })
    cb({ ok = ok, msg = msg })
end)

local function requestRanking()
    if uiOpen then return end
    local data, msg = lib.callback.await('xn_danhboss:getRanking', false)
    if data then
        openRanking(data)
    elseif msg then
        lib.notify({ title = Config.Text.title, description = msg, type = 'inform' })
    end
end

-- Ranking target: a plain ox_target sphere zone, no ped.
local rankingZoneId = nil

local function removeRankingZone()
    if rankingZoneId then
        exports.ox_target:removeZone(rankingZoneId)
        rankingZoneId = nil
    end
end

do
    local N = Config.Npc
    rankingZoneId = exports.ox_target:addSphereZone({
        coords = N.coords,
        radius = N.radius,
        options = {
            {
                name = 'xn_danhboss_ranking',
                icon = N.icon,
                label = N.label,
                distance = N.interactDistance,
                onSelect = requestRanking,
            },
        },
    })
end

-- The server keeps a set of players inside the boss zone instead of scanning every player.
do
    local h = Config.Boss.coords
    lib.zones.sphere({
        coords = vec3(h.x, h.y, h.z),
        radius = Config.Zone.radius,
        onEnter = function() TriggerServerEvent('xn_danhboss:zone', true) end,
        onExit = function() TriggerServerEvent('xn_danhboss:zone', false) end,
    })
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    removeRankingZone()
end)

-- Hits are merged per target/attacker/weapon and sent every 200ms in one event, so the owner of the
-- boss does not flood the server when many players shoot at once.
local hitQueue = {}

local function queueHit(target, attackerSid, weapon, isHead)
    local key = ('%d:%d:%d:%s'):format(target, attackerSid, weapon, isHead and 'h' or 'b')
    local e = hitQueue[key]
    if e then
        e.n = e.n + 1
    else
        hitQueue[key] = { t = target, a = attackerSid, w = weapon, h = isHead, b = GetWeaponDamage(weapon, 0), n = 1 }
    end
end

CreateThread(function()
    while true do
        Wait(200)
        if next(hitQueue) then
            local batch = {}
            for _, e in pairs(hitQueue) do batch[#batch + 1] = e end
            hitQueue = {}
            TriggerServerEvent('xn_danhboss:hits', batch)
        end
    end
end)

-- Only the client that owns the boss/minion receives the damage event, so it reports every player hit.

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if not state or state.dead then return end

    local attacker = args[2]
    if not attacker or attacker == 0 or not IsPedAPlayer(attacker) then return end

    local victim = args[1]
    if not victim or victim == 0 or not DoesEntityExist(victim) or not NetworkHasControlOfEntity(victim) then return end

    local isBoss = victim == resolvePed()
    local isMinion = not isBoss and NetworkGetEntityIsNetworked(victim) and Entity(victim).state.xnMinion
    if not isBoss and not isMinion then return end

    local idx = NetworkGetPlayerIndexFromPed(attacker)
    if idx == -1 then return end

    local found, bone = GetPedLastDamageBone(victim)
    local isHead = found and (bone == 31086 or bone == 12844 or bone == 39317) or false
    local target = isBoss and 0 or NetworkGetNetworkIdFromEntity(victim)
    queueHit(target, GetPlayerServerId(idx), math.tointeger(args[7]) or 0, isHead)
end)

-- Boss AI (runs only on the client that owns the entity)

local function setupBoss(ped, first)
    AddRelationshipGroup('XN_BOSS')
    SetPedRelationshipGroupHash(ped, `XN_BOSS`)
    SetRelationshipBetweenGroups(5, `XN_BOSS`, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, `XN_BOSS`)

    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedSuffersCriticalHits(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedRagdollOnCollision(ped, false)
    SetPedCanEvasiveDive(ped, false)
    SetPedKeepTask(ped, true)
    SetPedPathAvoidFire(ped, false)
    FreezeEntityPosition(ped, true) -- the boss never moves from its spawn point

    if first then
        local total = Config.Damage.realHealth + Config.HealthOffset
        SetPedMaxHealth(ped, total)
        SetEntityMaxHealth(ped, total)
        SetEntityHealth(ped, total)
        SetPedArmour(ped, 0)
        TriggerServerEvent('xn_danhboss:ready', state.netId)
    end
end

local function isValidPlayer(idx)
    local pPed = GetPlayerPed(idx)
    if pPed == 0 or IsEntityDead(pPed) or not IsEntityVisible(pPed) then return false end
    local st = Player(GetPlayerServerId(idx)).state
    if st.isDead or st.inLaststand then return false end
    return true, pPed
end

local function pickTarget(coords, current)
    local candidates, nearest, nearestDist = {}, nil, math.huge
    for _, idx in ipairs(GetActivePlayers()) do
        local ok, pPed = isValidPlayer(idx)
        if ok then
            local d = #(coords - GetEntityCoords(pPed))
            if d <= AI.aggroRange then
                if d < nearestDist then nearest, nearestDist = idx, d end
                if d <= AI.randomPickRange then candidates[#candidates + 1] = idx end
            end
        end
    end
    if #candidates > 1 and current then
        for i = #candidates, 1, -1 do
            if candidates[i] == current then table.remove(candidates, i) break end
        end
    end
    if #candidates > 0 then return candidates[math.random(#candidates)] end
    return nearest
end

local function playAnim(ped, anim)
    if not pcall(lib.requestAnimDict, anim.dict, 1000) then return end
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, anim.duration, 0, 0.0, false, false, false)
end

local function faceTarget(ped, from, to)
    SetEntityHeading(ped, GetHeadingFromVector_2d(to.x - from.x, to.y - from.y))
end

-- Random player in gun range with a clear line of sight.
local function pickGunTarget(ped, coords)
    local G = Config.Gun
    local list = {}
    for _, idx in ipairs(GetActivePlayers()) do
        local ok, pPed = isValidPlayer(idx)
        if ok then
            local d = #(coords - GetEntityCoords(pPed))
            if d >= G.minRange and d <= G.maxRange and HasEntityClearLosToEntity(ped, pPed, 17) then
                list[#list + 1] = idx
            end
        end
    end
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

-- Blocking: face the target, fire a burst of scripted bullets, then back to normal melee.
-- Scripted bullets work on any ped model (a ped shoot task needs weapon animations).
-- If the target dies/leaves mid-burst, another player is picked so the burst is not cut short.
-- Returns the number of bullets fired.
local function doGun(ped, idx)
    local G = Config.Gun
    local tPed = GetPlayerPed(idx)
    TriggerServerEvent('xn_danhboss:gunWarn', GetPlayerServerId(idx))

    RequestWeaponAsset(G.weapon, 31, 0)
    local loadTimeout = GetGameTimer() + 2000
    while not HasWeaponAssetLoaded(G.weapon) and GetGameTimer() < loadTimeout do Wait(0) end

    ClearPedTasks(ped)

    local function targetOk()
        return DoesEntityExist(tPed) and not IsEntityDead(tPed) and (select(1, isValidPlayer(idx)))
    end

    local function ensureTarget()
        if targetOk() then return true end
        local newIdx = pickGunTarget(ped, GetEntityCoords(ped))
        if not newIdx then return false end
        idx, tPed = newIdx, GetPlayerPed(newIdx)
        TriggerServerEvent('xn_danhboss:gunWarn', GetPlayerServerId(newIdx))
        return true
    end

    local windupEnd = GetGameTimer() + G.windup
    while GetGameTimer() < windupEnd and DoesEntityExist(ped) and NetworkGetEntityOwner(ped) == cache.playerId do
        if ensureTarget() then
            faceTarget(ped, GetEntityCoords(ped), GetEntityCoords(tPed))
        end
        Wait(50)
    end

    local fired = 0
    for _ = 1, G.shots do
        if not DoesEntityExist(ped) or IsEntityDead(ped) or NetworkGetEntityOwner(ped) ~= cache.playerId then break end
        if not ensureTarget() then break end

        local from = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.8, 0.5)
        local to = GetPedBoneCoords(tPed, 24816, 0.0, 0.0, 0.0)
        local s = G.spread
        to = to + vec3((math.random() - 0.5) * s, (math.random() - 0.5) * s, (math.random() - 0.5) * s)
        faceTarget(ped, from, to)
        ShootSingleBulletBetweenCoords(from.x, from.y, from.z, to.x, to.y, to.z, G.damage, true, G.weapon, ped, true, false, 400.0)
        fired = fired + 1
        Wait(G.shotDelay)
    end

    RemoveWeaponAsset(G.weapon)
    return fired
end

CreateThread(function()
    local setupPed, setupAt = 0, 0
    local target, taskedTarget, nextRetarget = nil, nil, 0
    local lastTaskAt, lastMelee, lastSlam = 0, 0, 0
    local mode = nil -- 'idle' | 'attack'
    local G = Config.Gun
    local nextGunAt = GetGameTimer() + math.random(G.intervalMin, G.intervalMax)

    while true do
        Wait(150)
        local ped = resolvePed()

        if ped == 0 or IsEntityDead(ped) or NetworkGetEntityOwner(ped) ~= cache.playerId then
            setupPed = 0
            target, taskedTarget, mode = nil, nil, nil
            Wait(state and 350 or 1500)
        else
            local now = GetGameTimer()
            if setupPed ~= ped then
                setupPed, setupAt = ped, now
                setupBoss(ped, not Entity(ped).state.xnReady)
            elseif not Entity(ped).state.xnReady and now - setupAt > 6000 then
                setupPed = 0 -- server did not confirm init, redo it
            end

            local enraged = state.enraged
            local E = Config.Enrage
            local myPos = GetEntityCoords(ped)

            if GetEntityHealth(ped) < Config.Damage.realHealth * 0.5 then
                SetEntityHealth(ped, Config.Damage.realHealth + Config.HealthOffset)
            end
            if target then
                local ok, pPed = isValidPlayer(target)
                if not ok or #(myPos - GetEntityCoords(pPed)) > AI.aggroRange * 1.3 then target = nil end
            end

            if not target or now >= nextRetarget then
                local newTarget = pickTarget(myPos, target)
                if newTarget ~= target then taskedTarget = nil end
                target = newTarget
                local interval = math.random(AI.retargetMin, AI.retargetMax)
                nextRetarget = now + (enraged and interval * 0.6 or interval)
            end

            local gunTarget = nil
            if now >= nextGunAt then
                nextGunAt = now + 1000 -- no valid target now, retry soon
                gunTarget = pickGunTarget(ped, myPos)
            end

            if gunTarget then
                mode = nil
                local fired = doGun(ped, gunTarget)
                if fired < math.ceil(G.shots / 2) then
                    nextGunAt = GetGameTimer() + 1500 -- burst got cut short, retry soon
                else
                    local interval = math.random(G.intervalMin, G.intervalMax)
                    nextGunAt = GetGameTimer() + (enraged and interval * E.cooldownMult or interval)
                end
                taskedTarget = nil
            elseif not target then
                if mode ~= 'idle' then
                    mode = 'idle'
                    ClearPedTasks(ped)
                end
            else
                mode = 'attack'
                local tPed = GetPlayerPed(target)
                local tPos = GetEntityCoords(tPed)
                local dist = #(myPos - tPos)
                local melee, slam = Config.Melee, Config.Slam
                local cdMult = enraged and E.cooldownMult or 1.0
                local meleeReady = now - lastMelee >= melee.cooldown * cdMult
                local slamReady = now - lastSlam >= slam.cooldown * cdMult

                if slamReady and dist <= slam.triggerRange and (dist > melee.range or math.random() < 0.35) then
                    lastSlam = now
                    faceTarget(ped, myPos, tPos)
                    playAnim(ped, slam.anim)
                    TriggerServerEvent('xn_danhboss:slam')
                    Wait(slam.delay + 500)
                    taskedTarget = nil
                elseif meleeReady and dist <= melee.range then
                    lastMelee = now
                    faceTarget(ped, myPos, tPos)
                    playAnim(ped, melee.anim)
                    Wait(melee.hitDelay)
                    if DoesEntityExist(tPed) and #(GetEntityCoords(ped) - GetEntityCoords(tPed)) <= melee.range + 1.0 then
                        TriggerServerEvent('xn_danhboss:melee', GetPlayerServerId(target))
                    end
                    Wait(math.max(0, melee.anim.duration - melee.hitDelay))
                    taskedTarget = nil
                elseif now - lastTaskAt > 300 then
                    lastTaskAt = now
                    faceTarget(ped, myPos, tPos)
                end
            end
        end
    end
end)

-- Minion zombies: each one is driven by the client that owns its entity.

local minionAI = {}

-- Ground height for a server-chosen spawn point; nil if unsuitable or too close to a player.
lib.callback.register('xn_danhboss:findSpawn', function(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    local found, gz = false, 0.0
    for _ = 1, 20 do
        found, gz = GetGroundZFor_3dCoord(x, y, z + 40.0, false)
        if found then break end
        Wait(50)
    end
    if not found or math.abs(gz - z) > 20.0 then return nil end

    local spot = vec3(x, y, gz)
    for _, idx in ipairs(GetActivePlayers()) do
        if #(GetEntityCoords(GetPlayerPed(idx)) - spot) < Config.Minions.minPlayerDistance then return nil end
    end
    return gz
end)

RegisterNetEvent('xn_danhboss:minionDied', function(netId)
    minionAI[netId] = nil
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end
    local ped = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(ped) and NetworkGetEntityOwner(ped) == cache.playerId then
        SetEntityHealth(ped, 0)
    end
end)

local function setupMinion(ped)
    local M = Config.Minions
    AddRelationshipGroup('XN_BOSS')
    SetPedRelationshipGroupHash(ped, `XN_BOSS`)
    SetRelationshipBetweenGroups(5, `XN_BOSS`, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, `XN_BOSS`)

    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedSuffersCriticalHits(ped, false)
    SetPedKeepTask(ped, true)
    SetPedArmour(ped, 0)

    if GetEntityHealth(ped) < M.realHealth * 0.5 then
        local total = M.realHealth + Config.HealthOffset
        SetPedMaxHealth(ped, total)
        SetEntityMaxHealth(ped, total)
        SetEntityHealth(ped, total)
    end
end

-- Only players inside the zone are targets, sorted so every client sees the same order.
local zoneCenter = vec3(Config.Boss.coords.x, Config.Boss.coords.y, Config.Boss.coords.z)

local function collectPlayers()
    local list = {}
    for _, idx in ipairs(GetActivePlayers()) do
        local pPed = GetPlayerPed(idx)
        local pos = GetEntityCoords(pPed)
        if #(vec2(pos.x, pos.y) - vec2(zoneCenter.x, zoneCenter.y)) <= Config.Zone.radius and isValidPlayer(idx) then
            list[#list + 1] = { idx = idx, ped = pPed, sid = GetPlayerServerId(idx), pos = pos }
        end
    end
    table.sort(list, function(a, b) return a.sid < b.sid end)
    return list
end

local function startAttack(ped, netId, ai, pos, victim, now)
    local M = Config.Minions
    ai.lastHit = now
    ai.target, ai.lastTask = nil, 0
    faceTarget(ped, pos, victim.pos)
    playAnim(ped, M.anim)
    local sid = victim.sid
    SetTimeout(M.hitDelay, function()
        if DoesEntityExist(ped) and not IsEntityDead(ped) and NetworkGetEntityOwner(ped) == cache.playerId then
            TriggerServerEvent('xn_danhboss:minionHit', netId, sid)
        end
    end)
end

local function tickMinion(ped, netId, ai, players, now)
    local M = Config.Minions
    local R = Config.Zone.radius
    if GetEntityHealth(ped) < M.realHealth * 0.5 then
        SetEntityHealth(ped, M.realHealth + Config.HealthOffset)
    end
    SetPedMoveRateOverride(ped, M.moveRate)

    local pos = GetEntityCoords(ped)
    local fromCenter = #(vec2(pos.x, pos.y) - vec2(zoneCenter.x, zoneCenter.y))

    -- Never leave the zone: walk back in before doing anything else.
    if fromCenter > R then
        if ai.mode ~= 'return' or now - ai.lastTask > 2000 then
            ai.mode, ai.lastTask, ai.target = 'return', now, nil
            local k = (R * 0.7) / fromCenter
            local px = zoneCenter.x + (pos.x - zoneCenter.x) * k
            local py = zoneCenter.y + (pos.y - zoneCenter.y) * k
            TaskGoStraightToCoord(ped, px, py, pos.z, M.moveSpeed, -1, 0.0, 0.5)
        end
        return
    elseif ai.mode == 'return' then
        if fromCenter > R * 0.9 then return end
        ai.mode = nil
    end

    if #players == 0 then
        if ai.target then
            ai.target = nil
            ClearPedTasks(ped)
        end
        return
    end

    -- Bite whoever is already in reach.
    local adjacent, adjacentDist
    for _, p in ipairs(players) do
        local d = #(pos - p.pos)
        if not adjacentDist or d < adjacentDist then adjacent, adjacentDist = p, d end
    end
    if adjacentDist <= M.attackRange then
        if now - ai.lastHit >= M.cooldown then startAttack(ped, netId, ai, pos, adjacent, now) end
        return
    end

    -- Otherwise chase a player picked by netId + time bucket so minions spread across players.
    local bucket = math.floor(now / M.retargetPeriod)
    local chosen = players[(netId + bucket) % #players + 1]
    if ai.target ~= chosen.idx or now - ai.lastTask > 1500 then
        ai.target, ai.lastTask = chosen.idx, now
        TaskGoToEntity(ped, chosen.ped, -1, 1.0, M.moveSpeed, 1073741824, 0)
    end
end

-- Validity/zone checks are rebuilt once a second; positions are refreshed every tick.
local playerCache, playerCacheAt = {}, 0

local function getZonePlayers(now)
    if now - playerCacheAt >= 1000 then
        playerCache, playerCacheAt = collectPlayers(), now
    else
        for _, p in ipairs(playerCache) do
            if DoesEntityExist(p.ped) then p.pos = GetEntityCoords(p.ped) end
        end
    end
    return playerCache
end

CreateThread(function()
    while true do
        Wait(250)
        local list = state and not state.dead and state.minions
        if list and #list > 0 then
            local now = GetGameTimer()
            local alive, players = {}, nil

            for _, netId in ipairs(list) do
                alive[netId] = true
                if NetworkDoesEntityExistWithNetworkId(netId) then
                    local ped = NetworkGetEntityFromNetworkId(netId)
                    if DoesEntityExist(ped) and not IsEntityDead(ped) and NetworkGetEntityOwner(ped) == cache.playerId then
                        local ai = minionAI[netId]
                        if not ai or ai.ped ~= ped then
                            ai = { ped = ped, lastTask = 0, lastHit = 0 }
                            minionAI[netId] = ai
                            setupMinion(ped)
                        end
                        players = players or getZonePlayers(now)
                        tickMinion(ped, netId, ai, players, now)
                    end
                end
            end

            for netId in pairs(minionAI) do
                if not alive[netId] then minionAI[netId] = nil end
            end
        else
            Wait(750)
        end
    end
end)
