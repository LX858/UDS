local config = require 'config.client'
local sharedConfig = require 'config.shared'

local deathUIActive = false
local deathTimer = 0
local respawnTimer = 0
local hasBeenTeleported = false
local allowAutoTeleport = false
local isInPrison = false
local justSpawned = true
local screenHidden = false

local function getRedZoneWaitTime()
    local isInRedZone, currentRedZone = exports.qbx_medical:IsInRedZone()
    if isInRedZone and currentRedZone and currentRedZone.waitHTime then
        return currentRedZone.waitHTime
    end

    return config.redZoneWaitHTime or 300
end

-- Function xử lý ragdoll và disable controls khi chết (chỉ chạy khi cần)
local function handleDeathEffects()
    CreateThread(function()
        while deathUIActive and DeathState ~= sharedConfig.deathState.ALIVE do
            Wait(500)
            local ped = cache.ped

            -- Force ragdoll
            if DeathState == sharedConfig.deathState.LAST_STAND and not IsPedRagdoll(ped) and IsPedOnFoot(ped) then
                SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
            end
            SetPedCanRagdoll(ped, false)

            -- Disable vehicle controls nếu trong xe
            if cache.vehicle then
                local vehicle = cache.vehicle
                if GetIsVehicleEngineRunning(vehicle) then
                    SetVehicleEngineOn(vehicle, false, true, true)
                end

                DisableControlAction(0, 75, true) -- Exit Vehicle
                DisableControlAction(0, 71, true) -- Accelerate
                DisableControlAction(0, 72, true) -- Brake
                DisableControlAction(0, 59, true) -- Steering
            end

            -- Disable inventory
            LocalPlayer.state.invBusy = true
        end
    end)
end

-- Function xử lý respawn timer trong tù (chỉ chạy khi cần)
local function handleRespawnTimer()
    CreateThread(function()
        while deathUIActive and respawnTimer > 0 do
            Wait(1000)
            respawnTimer = respawnTimer - 1

            if respawnTimer <= 0 then
                TriggerServerEvent('qbx_medical:server:revivePlayerInPrison')
                Wait(500)
                HideDeathUI()
                exports.qbx_core:Notify('Bạn đã hồi sinh trong tù', 'success')
                break
            end
        end
    end)
end

-- Function xử lý auto teleport timer (chỉ chạy khi cần)
local function handleAutoTeleportTimer()
    CreateThread(function()
        while deathUIActive and deathTimer > 0 do
            Wait(1000)
            deathTimer = deathTimer - 1
            SendNUIMessage({ action = 'updateDeathTimer', time = math.max(0, deathTimer) })

            if deathTimer <= 0 and not hasBeenTeleported and allowAutoTeleport then
                hasBeenTeleported = true
                local ped = cache.ped
                local playerData = QBX.PlayerData
                local isSentenced = LocalPlayer.state.isSentenced or false
                local inJail = playerData.metadata.injail and playerData.metadata.injail > 0

                if isSentenced or inJail then
                    local success, prisonRespawn = pcall(function()
                        return exports['nl_hotcut']:GetRespawnLocation()
                    end)

                    if not success or not prisonRespawn then
                        prisonRespawn = {x = 1679.49, y = 2513.71, z = 45.56}
                    end

                    SetEntityCoords(ped, prisonRespawn.x, prisonRespawn.y, prisonRespawn.z, false, false, false, true)
                    respawnTimer = config.timerespawn
                    SendNUIMessage({action = "DSMenu", open = true, time = config.timerespawn, deathState = DeathState, resourceName = GetCurrentResourceName()})
                    SendNUIMessage({action = "showRespawnTimer"})
                    handleRespawnTimer()
                else
                    TriggerServerEvent('qbx_medical:server:createBillingInvoice')
                    HideDeathUI()

                    DoScreenFadeOut(800)
                    Wait(800)

                    local randomBedIndex = math.random(1, config.totalBeds or 7)
                    TriggerEvent('qbx_ambulancejob:client:putPlayerInBedrv', config.hospitalName or 'pillbox', randomBedIndex, true)
                    Wait(500)
                    TriggerServerEvent('qbx_medical:server:revivePlayerBeforeBed')
                end
                break
            end
        end
    end)
end

function ShowDeathUI()
    -- Sử dụng DeathState global từ qbx_medical thay vì exports
    if LocalPlayer.state.vxAirdropActive then return end
    if deathUIActive then return end
    if DeathState == sharedConfig.deathState.ALIVE then return end

    local playerData = QBX.PlayerData
    if not playerData or not playerData.citizenid then
        return
    end

    if justSpawned then
        Wait(100)
        -- Check DeathState trực tiếp thay vì dùng exports
        if DeathState == sharedConfig.deathState.ALIVE then
            return
        end
    end

    deathUIActive = true
    deathTimer = 0
    respawnTimer = 0
    hasBeenTeleported = false
    allowAutoTeleport = false

    isInPrison = LocalPlayer.state.isSentenced or false
    local inJail = playerData.metadata.injail and playerData.metadata.injail > 0

    local waitHTime = getRedZoneWaitTime()
    local elapsedSecs = 0
    local pcallOk, rzDeathTime = pcall(function() return exports.qbx_medical:GetRedZoneDeathTime() end)
    if pcallOk and rzDeathTime and rzDeathTime > 0 then
        elapsedSecs = math.floor((GetGameTimer() - rzDeathTime) / 1000)
    end
    local remainingWaitH = math.max(0, waitHTime - elapsedSecs)

    if isInPrison or inJail then
        deathTimer = config.autoTeleportTime
        allowAutoTeleport = true
        --print('[qbx_medical] Player in prison - auto respawn in ' .. config.autoTeleportTime .. ' seconds')
        SendNUIMessage({action = "DSMenu", open = true, time = config.autoTeleportTime, deathState = DeathState, isRedZone = exports.qbx_medical:IsInRedZone(), redZoneWaitHTime = remainingWaitH, redZoneHHoldTime = config.redZoneHHoldTime or 2, resourceName = GetCurrentResourceName()})
        handleAutoTeleportTimer()
    else
        SendNUIMessage({action = "DSMenu", open = true, time = config.timewait, deathState = DeathState, isRedZone = exports.qbx_medical:IsInRedZone(), redZoneWaitHTime = remainingWaitH, redZoneHHoldTime = config.redZoneHHoldTime or 2, resourceName = GetCurrentResourceName()})
        if DeathState == sharedConfig.deathState.DEAD and not exports.qbx_medical:IsInRedZone() then
            SendNUIMessage({ action = 'res' })
        end
    end

    if config.enableBlur then
        TriggerScreenblurFadeIn(1000)
    end
    disableSounds()
    handleDeathEffects()
end

function HideDeathUI()
    screenHidden = false
    if not deathUIActive then return end

    -- Tắt UI trước để dừng các threads
    deathUIActive = false
    allowAutoTeleport = false

    pcall(function()
        exports.qbx_medical:ResetRedZoneDeathTime()
    end)

    SendNUIMessage({action = "DSMenu", open = false})

    -- Force tắt blur nhiều lần để chắc chắn
    TriggerScreenblurFadeOut(500)
    Wait(100)
    TriggerScreenblurFadeOut(500)
    
    enableSounds()

    -- Đợi threads dừng hoàn toàn (giảm từ 150 xuống 100 vì DeathState đã ALIVE)
    Wait(100)

    -- Clear tất cả states liên quan
    LocalPlayer.state.invBusy = false
    SetPedCanRagdoll(cache.ped, true)

    -- Force unlock thêm 1 lần nữa
    Wait(50)
    LocalPlayer.state.invBusy = false
end

AddEventHandler('qbx_medical:client:onPlayerDied', function(attacker, weapon)
    ShowDeathUI()
end)

AddEventHandler('qbx_medical:client:onPlayerLaststand', function(attacker, weapon)
    ShowDeathUI()
end)

AddEventHandler('qbx_medical:client:onPlayerRevived', function()
    HideDeathUI()
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    justSpawned = true
    SetTimeout(3000, function()
        justSpawned = false
    end)
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    deathUIActive = false
    screenHidden = false
    justSpawned = true
end)

local isHoldingE = false
local eHoldMs = 0

-- Chỉ enable command khi đang chết và không ở tù
lib.addKeybind({
    name = 'callDoctor',
    description = 'Gọi bác sĩ / Hồi sinh khi chết',
    defaultKey = 'E',
    onPressed = function()
        if LocalPlayer.state.vxAirdropActive then return end
        if exports.qbx_medical:IsInRedZone() then return end
        if not deathUIActive or screenHidden or isInPrison or allowAutoTeleport then return end

        if DeathState == sharedConfig.deathState.LAST_STAND or DeathState == sharedConfig.deathState.DEAD then
            if isHoldingE then return end

            local doctorCount = GlobalState['ambulance_count'] or 0
            if doctorCount and doctorCount >= 1 then
                TriggerServerEvent('qbx_medical:server:checkDoctorsAndStartTimer')
                return
            end

            isHoldingE = true
            eHoldMs = 0

            CreateThread(function()
                while isHoldingE and (DeathState == sharedConfig.deathState.DEAD or DeathState == sharedConfig.deathState.LAST_STAND) do
                    Wait(50)
                    if not isHoldingE then break end
                    eHoldMs = eHoldMs + 50
                    local remainingSecs = math.max(1, math.ceil((5000 - eHoldMs) / 1000))

                    SendNUIMessage({ action = 'updateRes', time = remainingSecs })

                    if eHoldMs >= 5000 then
                        isHoldingE = false
                        eHoldMs = 0
                        SendNUIMessage({ action = 'updateRes', time = 0 })

                        TriggerServerEvent('qbx_medical:server:createBillingInvoice')
                        HideDeathUI()

                        DoScreenFadeOut(800)
                        Wait(800)

                        local randomBedIndex = math.random(1, config.totalBeds or 7)
                        TriggerEvent('qbx_ambulancejob:client:putPlayerInBedrv', config.hospitalName or 'pillbox', randomBedIndex, true)
                        Wait(500)
                        TriggerServerEvent('qbx_medical:server:revivePlayerBeforeBed')
                        break
                    end
                end
            end)
        end
    end,
    onReleased = function()
        if isHoldingE then
            isHoldingE = false
            eHoldMs = 0
            SendNUIMessage({ action = 'updateRes', time = 5 })
        end
    end
})

RegisterNetEvent('qbx_medical:client:doctorCheckResult', function(hasDoctors)
    if hasDoctors then
        exports.qbx_core:Notify('Đã gọi bác sĩ! Hãy kiên nhẫn chờ đợi.', 'success')
    else
        if DeathState == sharedConfig.deathState.LAST_STAND then
            exports.qbx_core:Notify('Không có bác sĩ online.', 'error')
            return
        end

        if allowAutoTeleport then return end
        exports.qbx_core:Notify('Không có bác sĩ online. Bạn sẽ được đưa đến bệnh viện sau ' .. config.autoTeleportTime .. ' giây.', 'error')
        deathTimer = config.autoTeleportTime
        allowAutoTeleport = true
        handleAutoTeleportTimer()
    end
end)

function disableSounds()
    StartAudioScene("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_01_STAGE",false)
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_02_MAIN_ROOM",false)
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_03_BACK_ROOM",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_STREETRACE",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_SALTON_DIRT_BIKE",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_SALTON",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_NEXT_TO_CAR",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_CAR",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_BIKE",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_MILITARY_PLANES_SMALL",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_MILITARY_PLANES_BIG",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_MECHANIC",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_EMPTY",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_BUSINESSMEN",false)
    SetScenarioTypeEnabled("WORLD_VEHICLE_BIKE_OFF_ROAD_RACE",false)
    StartAudioScene("FBI_HEIST_H5_MUTE_AMBIENCE_SCENE")
    StartAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")
    SetAudioFlag("PoliceScannerDisabled",true)
    SetAudioFlag("DisableFlightMusic",true)
    SetPlayerCanUseCover(PlayerId(),false)
    SetRandomEventFlag(false)
    SetDeepOceanScaler(0.0)
end

function enableSounds()
    StopAudioScene("DLC_MPHEIST_TRANSITION_TO_APT_FADE_IN_RADIO_SCENE")
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_01_STAGE",true)
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_02_MAIN_ROOM",true)
    SetStaticEmitterEnabled("LOS_SANTOS_VANILLA_UNICORN_03_BACK_ROOM",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_STREETRACE",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_SALTON_DIRT_BIKE",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_SALTON",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_NEXT_TO_CAR",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_CAR",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_POLICE_BIKE",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_MILITARY_PLANES_SMALL",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_MILITARY_PLANES_BIG",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_MECHANIC",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_EMPTY",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_BUSINESSMEN",true)
    SetScenarioTypeEnabled("WORLD_VEHICLE_BIKE_OFF_ROAD_RACE",true)
    StopAudioScene("FBI_HEIST_H5_MUTE_AMBIENCE_SCENE")
    StopAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")
    SetAudioFlag("PoliceScannerDisabled",false)
    SetAudioFlag("DisableFlightMusic",false)
    SetPlayerCanUseCover(PlayerId(),true)
    SetRandomEventFlag(true)
    SetDeepOceanScaler(1.0)
end

exports('ShowDeathUI', ShowDeathUI)
exports('HideDeathUI', HideDeathUI)

-- Chỉ ẩn giao diện màn hình chết (NUI + blur), không thay đổi trạng thái chết/timer/redzone.
-- Trong lúc ẩn, phím E (gọi bác sĩ / hồi sinh) bị vô hiệu hóa; HideDeathUI sẽ reset cờ này.
local function HideDeathScreen()
    screenHidden = true
    isHoldingE = false
    eHoldMs = 0
    SendNUIMessage({action = "DSMenu", open = false})
    TriggerScreenblurFadeOut(500)
end

exports('HideDeathScreen', HideDeathScreen)

AddStateBagChangeHandler(DEATH_STATE_STATE_BAG, ('player:%s'):format(cache.serverId), function(_, _, value)
    if deathUIActive and value then
        local waitHTime = getRedZoneWaitTime()
        local elapsedSecs = 0
        local pcallOk, rzDeathTime = pcall(function() return exports.qbx_medical:GetRedZoneDeathTime() end)
        if pcallOk and rzDeathTime and rzDeathTime > 0 then
            elapsedSecs = math.floor((GetGameTimer() - rzDeathTime) / 1000)
        end
        local remainingWaitH = math.max(0, waitHTime - elapsedSecs)

        SendNUIMessage({action = "updateDeathState", deathState = value, redZoneWaitHTime = remainingWaitH})
        if value == sharedConfig.deathState.DEAD and not exports.qbx_medical:IsInRedZone() then
            SendNUIMessage({ action = 'res' })
        end
    end
end)

