local config = require 'config.client'
local sharedConfig = require 'config.shared'

local currentRedZone = nil
local isInsideRedZone = false
local markedRedZones = {}
local redZoneCooldowns = {}
local redZoneDebugActive = config.redZoneDebug or false

exports('IsInRedZone', function()
    return isInsideRedZone, currentRedZone
end)

local redZoneDeathTime = 0

exports('GetRedZoneDeathTime', function()
    return redZoneDeathTime
end)

exports('ResetRedZoneDeathTime', function()
    redZoneDeathTime = 0
end)

local function getRedZoneWaitTime()
    return (currentRedZone and currentRedZone.waitHTime) or config.redZoneWaitHTime or 300
end

--- Push player outside red zone boundary smoothly
local function pushPlayerOutOfZone(redZone)
    if not redZone then return end
    local ped = cache.ped
    local pCoords = GetEntityCoords(ped)
    local dir = vec3(pCoords.x - redZone.coords.x, pCoords.y - redZone.coords.y, 0.0)
    
    if #(dir) < 0.1 then
        dir = vec3(1.0, 0.0, 0.0)
    end
    
    local normDir = dir / #(dir)
    -- Push 6 meters outside the 20m radius boundary
    local pushCoords = redZone.coords + (normDir * (redZone.radius + 6.0))
    local targetZ = pushCoords.z
    local success, groundZ = GetGroundZFor_3dCoord(pushCoords.x, pushCoords.y, pushCoords.z + 10.0, false)
    if success and groundZ > 0 then
        targetZ = groundZ + 0.5
    end

    if cache.vehicle then
        SetEntityCoords(cache.vehicle, pushCoords.x, pushCoords.y, targetZ, false, false, false, true)
    else
        SetEntityCoords(ped, pushCoords.x, pushCoords.y, targetZ, false, false, false, true)
    end
end

-- Synchronize cooldowns from server
RegisterNetEvent('qbx_medical:client:syncRedZoneCooldowns', function(cooldowns)
    redZoneCooldowns = cooldowns or {}
end)

-- Handle Teleport to Hospital from server
RegisterNetEvent('qbx_medical:client:teleportToHospital', function(coords, heading)
    local ped = cache.ped
    DoScreenFadeOut(500)
    Wait(500)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
    if heading then SetEntityHeading(ped, heading) end

    Wait(500)
    DoScreenFadeIn(500)

    SendNUIMessage({ action = 'res' })
end)

-- When player is revived, clear marked state so player can remain in red zone and enter/exit freely
AddEventHandler('qbx_medical:client:onPlayerRevived', function()
    markedRedZones = {}
    redZoneDeathTime = 0
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    redZoneDeathTime = 0
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    redZoneDeathTime = 0
end)

local lastCooldownNotifyTime = {}

local function notifyZoneCooldown(zoneId, remainingSecs)
    local now = GetGameTimer()
    if lastCooldownNotifyTime[zoneId] and (now - lastCooldownNotifyTime[zoneId] < 5000) then
        return
    end
    lastCooldownNotifyTime[zoneId] = now

    local mins = math.floor(remainingSecs / 60)
    local secs = remainingSecs % 60
    local msg = ""
    if mins > 0 then
        msg = string.format("Bạn phải chờ %d phút %d giây mới được vào lại vùng đỏ!", mins, secs)
    else
        msg = string.format("Bạn phải chờ %d giây mới được vào lại vùng đỏ!", secs)
    end
    exports.qbx_core:Notify(msg, 'error')
end

-- Initialize Red Zones using lib.zone
CreateThread(function()
    Wait(1000)
    if not config.redZones then return end

    for _, redZone in ipairs(config.redZones) do
        lib.zones.sphere({
            coords = redZone.coords,
            radius = redZone.radius,
            debug = false,
            onEnter = function()
                local currentTime = GetCloudTimeAsInt()
                if redZoneCooldowns[redZone.id] and currentTime < redZoneCooldowns[redZone.id] then
                    local remainingSecs = redZoneCooldowns[redZone.id] - currentTime
                    notifyZoneCooldown(redZone.id, remainingSecs)
                    pushPlayerOutOfZone(redZone)
                    return
                end

                currentRedZone = redZone
                isInsideRedZone = true
                TriggerEvent('qbx_medical:client:onEnterRedZone', redZone)

                if DeathState and DeathState ~= sharedConfig.deathState.ALIVE then
                    markedRedZones[redZone.id] = true
                    TriggerServerEvent('qbx_medical:server:markPlayerInRedZone', redZone.id)
                end

                SendNUIMessage({ action = 'updateRedZone', isRedZone = true })
            end,
            onExit = function()
                local wasDeadOrDowned = (DeathState and DeathState ~= sharedConfig.deathState.ALIVE) or markedRedZones[redZone.id]

                if currentRedZone and currentRedZone.id == redZone.id then
                    currentRedZone = nil
                    isInsideRedZone = false
                    TriggerEvent('qbx_medical:client:onExitRedZone', redZone)
                    SendNUIMessage({ action = 'updateRedZone', isRedZone = false })
                end

                if wasDeadOrDowned then
                    markedRedZones[redZone.id] = nil
                    local cdMinutes = redZone.cooldownMinutes or config.redZoneDefaultCooldown or 2
                    local expiryTime = GetCloudTimeAsInt() + (cdMinutes * 60)
                    redZoneCooldowns[redZone.id] = expiryTime
                    TriggerServerEvent('qbx_medical:server:setRedZoneCooldown', redZone.id, expiryTime)
                    notifyZoneCooldown(redZone.id, cdMinutes * 60)
                end
            end,
            inside = function()
                local currentTime = GetCloudTimeAsInt()
                -- Enforce active cooldown check inside loop without spamming notifications
                if redZoneCooldowns[redZone.id] and currentTime < redZoneCooldowns[redZone.id] then
                    local remainingSecs = redZoneCooldowns[redZone.id] - currentTime
                    notifyZoneCooldown(redZone.id, remainingSecs)
                    pushPlayerOutOfZone(redZone)
                    return
                end

                -- Mark player if downed/dead
                if DeathState and DeathState ~= sharedConfig.deathState.ALIVE then
                    if not markedRedZones[redZone.id] then
                        markedRedZones[redZone.id] = true
                        TriggerServerEvent('qbx_medical:server:markPlayerInRedZone', redZone.id)
                    end
                end
            end
        })
    end
end)

-- -- Debug Command & Boundary Render Thread
-- RegisterCommand('redzonedebug', function()
--     local playerData = QBX.PlayerData
--     if not playerData then return end

--     redZoneDebugActive = not redZoneDebugActive
--     local status = redZoneDebugActive and 'Bật' or 'Tắt'
--     exports.qbx_core:Notify('Chế độ Debug Vùng Đỏ: ' .. status, 'inform')
-- end, false)

CreateThread(function()
    while true do
        if redZoneDebugActive and config.redZones then
            for _, redZone in ipairs(config.redZones) do
                DrawMarker(
                    28,
                    redZone.coords.x, redZone.coords.y, redZone.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    redZone.radius, redZone.radius, redZone.radius,
                    255, 0, 0, 80,
                    false, false, 2, false, nil, nil, false
                )
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('qbx_medical:client:onPlayerDied', function()
    if isInsideRedZone and redZoneDeathTime == 0 then
        redZoneDeathTime = GetGameTimer()
    end
end)

AddEventHandler('qbx_medical:client:onPlayerLaststand', function()
    if isInsideRedZone and redZoneDeathTime == 0 then
        redZoneDeathTime = GetGameTimer()
    end
end)

local isHoldingH = false
local hHoldMs = 0

lib.addKeybind({
    name = 'redzone_hospital_h',
    description = 'Về bệnh viện từ vùng đỏ',
    defaultKey = 'H',
    onPressed = function()
        if not isInsideRedZone then return end
        if DeathState ~= sharedConfig.deathState.DEAD and DeathState ~= sharedConfig.deathState.LAST_STAND then return end
        if isHoldingH then return end

        if redZoneDeathTime == 0 then
            redZoneDeathTime = GetGameTimer()
        end

        local now = GetGameTimer()
        local waitMs = getRedZoneWaitTime() * 1000
        if now - redZoneDeathTime < waitMs then
            local remainingSecs = math.ceil((waitMs - (now - redZoneDeathTime)) / 1000)
            exports.qbx_core:Notify(('Bạn phải chờ %d giây nữa mới có thể bấm nút H!'):format(remainingSecs), 'error')
            return
        end

        isHoldingH = true
        hHoldMs = 0
        local holdTargetMs = (config.redZoneHHoldTime or 2) * 1000

        CreateThread(function()
            while isHoldingH do
                Wait(50)
                if not isHoldingH then break end

                local currentNow = GetGameTimer()
                if currentNow - redZoneDeathTime < waitMs then
                    isHoldingH = false
                    hHoldMs = 0
                    SendNUIMessage({ action = 'updateHHold', holding = false })
                    break
                end

                hHoldMs = hHoldMs + 50
                local remainingSecs = math.max(1, math.ceil((holdTargetMs - hHoldMs) / 1000))

                SendNUIMessage({
                    action = 'updateHHold',
                    holding = true,
                    timer = remainingSecs
                })

                if hHoldMs >= holdTargetMs then
                    isHoldingH = false
                    hHoldMs = 0
                    SendNUIMessage({ action = 'updateHHold', holding = false })

                    local zoneId = currentRedZone and currentRedZone.id
                    TriggerServerEvent('qbx_medical:server:redZoneHospitalRespawn', zoneId)
                    break
                end
            end
        end)
    end,
    onReleased = function()
        if isHoldingH then
            isHoldingH = false
            hHoldMs = 0
            SendNUIMessage({ action = 'updateHHold', holding = false })
        end
    end
})

local function hasMedkitItem()
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search('count', 'medkit_che')
        return count and count >= 1
    end
    return true
end

local isRedZoneReviving = false

local function cancelCurrentRedZoneRevive()
    if not isRedZoneReviving then return end
    isRedZoneReviving = false

    pcall(function()
        lib.cancelSkillCheck()
    end)

    pcall(function()
        lib.cancelProgress()
    end)

    local ped = cache.ped
    if ped and DoesEntityExist(ped) then
        ClearPedTasks(ped)
        ClearPedSecondaryTask(ped)
    end
    exports.qbx_core:Notify('Hành động cứu người bị hủy do bạn bị tấn công!', 'error')
end

AddEventHandler('gameEventTriggered', function(event, data)
    if not isRedZoneReviving then return end
    if event ~= 'CEventNetworkEntityDamage' then return end

    local victim = data[1]
    if victim == cache.ped or NetworkGetPlayerIndexFromPed(victim) == cache.playerId then
        cancelCurrentRedZoneRevive()
    end
end)

-- Revive Action in Red Zone (CPR animation + Minigame + Progressbar + Interrupt on damage)
local function initiateRedZoneRevive(targetServerId, targetPed)
    if not isInsideRedZone then
        exports.qbx_core:Notify('Bạn phải ở trong vùng đỏ để thực hiện cứu hộ!', 'error')
        return
    end

    if DeathState ~= sharedConfig.deathState.ALIVE then
        exports.qbx_core:Notify('Bạn không thể cứu người khi đang bị thương!', 'error')
        return
    end

    if not hasMedkitItem() then
        exports.qbx_core:Notify('Bạn cần phải có 1 Hộp Sơ Cứu (medkit_che) trong túi đồ để cứu người!', 'error')
        return
    end

    isRedZoneReviving = true
    local rescuerPed = cache.ped
    SetEntityCanBeDamaged(rescuerPed, true)
    SetEntityInvincible(rescuerPed, false)
    ClearEntityLastDamageEntity(rescuerPed)
    ClearPedLastDamageBone(rescuerPed)

    local rescuerInitialHealth = GetEntityHealth(rescuerPed)
    local rescuerInitialArmour = GetPedArmour(rescuerPed)

    -- Damage listener thread to interrupt revive action immediately on attack/damage
    CreateThread(function()
        while isRedZoneReviving do
            Wait(0)
            local currentHp = GetEntityHealth(rescuerPed)
            local currentArmour = GetPedArmour(rescuerPed)

            local tookDamage = currentHp < rescuerInitialHealth
                or currentArmour < rescuerInitialArmour
                or HasEntityBeenDamagedByAnyPed(rescuerPed)
                or HasEntityBeenDamagedByAnyVehicle(rescuerPed)
                or HasEntityBeenDamagedByAnyObject(rescuerPed)
                or GetEntityLastDamageCause(rescuerPed) ~= 0
                or IsPedRagdoll(rescuerPed)
                or IsPedInMeleeCombat(rescuerPed)
                or IsPedBeingStunned(rescuerPed, 0)
                or IsPedGettingUp(rescuerPed)
                or IsPedInjured(rescuerPed)
                or IsEntityOnFire(rescuerPed)

            if not tookDamage then
                local pCoords = GetEntityCoords(rescuerPed)
                local nearby = lib.getNearbyPlayers(pCoords, 3.5, false)
                for i = 1, #nearby do
                    local otherPed = nearby[i].ped
                    if otherPed and otherPed ~= rescuerPed then
                        if IsPedInMeleeCombat(otherPed) or IsPedAttacking(otherPed) or IsPedShooting(otherPed) or GetMeleeTargetForPed(otherPed) == rescuerPed then
                            tookDamage = true
                            break
                        end
                    end
                end
            end

            if tookDamage then
                cancelCurrentRedZoneRevive()
                break
            end
        end
    end)


    -- Step 1: Start CPR Animation
    lib.requestAnimDict('mini@cpr@char_a@cpr_str', 2000)
    TaskPlayAnim(rescuerPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Step 2: Minigame (ox_lib skillCheck)
    local skillSuccess = lib.skillCheck({'easy', 'medium', 'easy'}, {'e', 'e', 'e'})

    if not isRedZoneReviving then
        return
    end

    if not skillSuccess then
        isRedZoneReviving = false
        ClearPedTasks(rescuerPed)
        exports.qbx_core:Notify('Thực hiện sơ cứu thất bại!', 'error')
        return
    end

    -- Step 3: Progressbar
    local durationMs = config.time_cuu_vung_do or 3
    if durationMs <= 600 then
        durationMs = durationMs * 1000
    end

    local progressSuccess = lib.progressBar({
        duration = durationMs,
        label = 'Đang cứu...',
        useWhileDead = false,
        allowRagdoll = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'mini@cpr@char_a@cpr_str',
            clip = 'cpr_pumpchest',
            flag = 1
        }
    })

    local wasActive = isRedZoneReviving
    isRedZoneReviving = false

    if not wasActive then
        return
    end

    if progressSuccess then
        ClearPedTasks(rescuerPed)
        TriggerServerEvent('qbx_medical:server:redZoneReviveTarget', targetServerId)
        exports.qbx_core:Notify('Cứu sống nạn nhân thành công!', 'success')
    else
        ClearPedTasks(rescuerPed)
        exports.qbx_core:Notify('Hành động cứu người đã bị hủy!', 'error')
    end
end

-- Target Interaction & Command
CreateThread(function()
    Wait(1500)
        exports.ox_target:addGlobalPlayer({
            {
                name = 'qbx_medical_redzone_revive',
                icon = 'fa-solid fa-heart-pulse',
                label = 'Cứu người (Vùng Đỏ)',
                distance = 3.0,
                canInteract = function(entity, distance, coords, name, bone)
                    if not isInsideRedZone then return false end
                    if not entity or not DoesEntityExist(entity) then return false end

                    local playerIndex = NetworkGetPlayerIndexFromPed(entity)
                    if playerIndex == -1 or playerIndex == cache.playerId then return false end

                    local targetServerId = GetPlayerServerId(playerIndex)
                    if not targetServerId or targetServerId == 0 then return false end

                    local targetState = Player(targetServerId).state['qbx_medical:deathState'] or Entity(entity).state['qbx_medical:deathState']

                    if targetState then
                        return targetState == sharedConfig.deathState.LAST_STAND
                    end

                    return IsEntityPlayingAnim(entity, 'combat@damage@writhe', 'writhe_loop', 3)
                end,
                onSelect = function(data)
                    local targetPed = data.entity
                    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
                    if targetServerId and targetServerId ~= 0 then
                        initiateRedZoneRevive(targetServerId, targetPed)
                    end
                end
            }
        })
   
end)

-- RegisterCommand('cuunguoi', function()
--     if not isInsideRedZone then
--         exports.qbx_core:Notify('Bạn phải ở trong vùng đỏ để dùng lệnh này!', 'error')
--         return
--     end

--     local closestPlayer, closestDistance = lib.getClosestPlayer(GetEntityCoords(cache.ped), 3.0, false)
--     if not closestPlayer or closestPlayer == -1 then
--         exports.qbx_core:Notify('Không có người chơi nào gần bạn!', 'error')
--         return
--     end

--     local targetPed = GetPlayerPed(closestPlayer)
--     local targetServerId = GetPlayerServerId(closestPlayer)
--     local targetState = Player(targetServerId).state['qbx_medical:deathState'] or Entity(targetPed).state['qbx_medical:deathState']

--     if targetState and targetState ~= sharedConfig.deathState.LAST_STAND then
--         exports.qbx_core:Notify('Chỉ có thể cứu người đang ở trạng thái ngất!', 'error')
--         return
--     end

--     initiateRedZoneRevive(targetServerId, targetPed)
-- end, false)
