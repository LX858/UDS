local state = nil
local blip = nil
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

RegisterNetEvent('xn_danhboss:sync', function(data)
    if data and (not state or state.netId ~= data.netId) then
        shownHp = data.hp + 0.0
    end
    state = data
    updateBlip()
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
    if res == GetCurrentResourceName() and blip then RemoveBlip(blip) end
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

    local scale = math.max(0.55, math.min(1.1, 14.0 / dist))
    local w, h = 0.11 * scale, 0.014 * scale
    local pct = math.max(0.0, math.min(1.0, shownHp / state.maxHp))

    local r, g, b
    if state.enraged then
        local pulse = (math.sin(GetGameTimer() / 120.0) + 1.0) / 2.0
        r, g, b = 255, math.floor(40 * pulse), 0
    elseif pct > 0.6 then
        r, g, b = 70, 200, 70
    elseif pct > 0.3 then
        r, g, b = 240, 190, 40
    else
        r, g, b = 220, 50, 40
    end

    local pad = 0.0015 * scale
    DrawRect(sx, sy, w + pad * 2, h + pad * 3, 0, 0, 0, 200)
    DrawRect(sx, sy, w, h, 50, 50, 50, 220)
    local fill = w * pct
    DrawRect(sx - w / 2 + fill / 2, sy, fill, h, r, g, b, 230)

    local label = state.enraged and (Config.Boss.label .. ' - ENRAGE') or Config.Boss.label
    drawText(label, sx, sy - 0.034 * scale, 0.38 * scale, 255, 255, 255)
    drawText(('%d / %d'):format(math.ceil(shownHp), state.maxHp), sx, sy - 0.0105 * scale, 0.27 * scale, 255, 255, 255)
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

RegisterNetEvent('xn_danhboss:hit', function(dmg, from, heavy)
    local ped = cache.ped
    if IsEntityDead(ped) then return end

    ApplyDamageToPed(ped, dmg, false)
    ShakeGameplayCam(heavy and 'LARGE_EXPLOSION_SHAKE' or 'SMALL_EXPLOSION_SHAKE', heavy and 0.25 or 0.1)

    if IsPedInAnyVehicle(ped, false) then return end
    if heavy or math.random() < Config.Melee.ragdollChance then
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
        SetEntityHealth(ped, 0)
    end
end)

-- Report my hits on the boss; the server computes the damage (neons_ddame zeroes real damage).

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local ped = resolvePed()
    if ped == 0 or args[1] ~= ped or args[2] ~= cache.ped then return end

    local weapon = args[7]
    local found, bone = GetPedLastDamageBone(ped)
    local isHead = found and (bone == 31086 or bone == 12844 or bone == 39317) or false
    TriggerServerEvent('xn_danhboss:damageBoss', weapon, isHead, GetWeaponDamage(weapon, 0))
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

    if first then
        local total = Config.Damage.realHealth + Config.HealthOffset
        SetPedMaxHealth(ped, total)
        SetEntityMaxHealth(ped, total)
        SetEntityHealth(ped, total)
        SetPedArmour(ped, 0)
        FreezeEntityPosition(ped, false)
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

CreateThread(function()
    local setupPed, setupAt = 0, 0
    local target, taskedTarget, nextRetarget = nil, nil, 0
    local lastTaskAt, lastMelee, lastSlam = 0, 0, 0
    local returning = false

    while true do
        Wait(150)
        local ped = resolvePed()

        if ped == 0 or IsEntityDead(ped) or not NetworkHasControlOfEntity(ped) then
            setupPed = 0
            target, taskedTarget, returning = nil, nil, false
            Wait(350)
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

            SetPedMoveRateOverride(ped, enraged and E.moveRate or AI.moveRate)

            if not target then
                local home = Config.Boss.coords
                local dist = #(myPos - vec3(home.x, home.y, home.z))
                if dist > AI.leashRange and not returning then
                    returning = true
                    TaskGoStraightToCoord(ped, home.x, home.y, home.z, 2.0, -1, home.w, 0.5)
                elseif dist <= 5.0 and returning then
                    returning = false
                    ClearPedTasks(ped)
                end
            else
                returning = false
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
                elseif dist > melee.range - 0.5 and (taskedTarget ~= target or now - lastTaskAt > 1200) then
                    taskedTarget, lastTaskAt = target, now
                    TaskGoToEntity(ped, tPed, -1, 1.0, AI.moveSpeed, 1073741824, 0)
                end
            end
        end
    end
end)
