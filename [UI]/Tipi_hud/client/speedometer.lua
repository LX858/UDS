local beltOn = false
local lastVehicle = 0
local vehicleMaxSpeedKmh = Config.MaxSpeed

local function isSeatbeltAllowed(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return false
    end

    if GetVehicleType(vehicle) == 'bike' then
        return false
    end

    local vehicleClass = GetVehicleClass(vehicle)
    if vehicleClass == 8 or vehicleClass == 13 then
        return false
    end

    return true
end

local function resolveVehicleMaxSpeedKmh(vehicle)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        return Config.MaxSpeed
    end

    local estimated = GetVehicleEstimatedMaxSpeed(vehicle) * 3.6
    if not estimated or estimated < 20 then
        return Config.MaxSpeed
    end

    return estimated
end

RegisterCommand("toggleBelt", function()
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    if Config.UseSeatBelt == true then

        if playerVehicle ~= 0 and isSeatbeltAllowed(playerVehicle) then

            beltOn = not beltOn
            if beltOn == true then
                notify('belt_true')
            else
                notify('belt_false')
            end

            SendNUIMessage({
                action = "belt",
                value = beltOn
            })
        end
    end
end, false)

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)

        if playerVehicle ~= 0 and isSeatbeltAllowed(playerVehicle) and not beltOn then
            SendNUIMessage({
                action = "alarm"
            })
        end
        Citizen.Wait(3000)
    end
end)

RegisterKeyMapping('toggleBelt', 'Toggle Seat Belt', 'keyboard', Config.BeltKey)


-- Seatbelt control block needs to run every frame to reliably hold,
-- so it gets its own tight thread instead of sharing the 50ms data loop below.
Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        if beltOn and IsPedInAnyVehicle(playerPed, false) then
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            if isSeatbeltAllowed(playerVehicle) then
                DisableControlAction(0, 75, true)
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

local cachedSeatCount = 4
local carControlTick = 0
local cachedDoorStates = {}
local cachedWindowStates = {}

Citizen.CreateThread(function()
    local sleep = 1000
    while true do
        local playerPed = PlayerPedId()
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)

        if playerVehicle ~= 0 then
            if playerVehicle ~= lastVehicle then
                lastVehicle = playerVehicle
                vehicleMaxSpeedKmh = resolveVehicleMaxSpeedKmh(playerVehicle)
                cachedSeatCount = GetVehicleModelNumberOfSeats(GetEntityModel(playerVehicle))
                if not isSeatbeltAllowed(playerVehicle) then
                    beltOn = false
                end
            end

            local isDriver = GetPedInVehicleSeat(playerVehicle, -1) == playerPed
            local maxSpeed = vehicleMaxSpeedKmh
            local speed = GetEntitySpeed(playerVehicle) * SpeedMultiplier
            local speedPercent = maxSpeed > 0 and ((speed / maxSpeed) * 100) or 0
            local isEngineRunning = GetIsVehicleEngineRunning(playerVehicle)
            local areDoorsLocked = GetVehicleDoorLockStatus(playerVehicle)
            local light = isVehicleHeadlightOn(playerVehicle)
            local altitude = isDriver and GetHelicopterDistanceFromGround(playerVehicle) or 0
            local health = GetVehicleHealthPercentage(playerVehicle)
            local doorsLocked = areDoorsLocked ~= 1
            local seatCount = cachedSeatCount
            local seatIndex = -1
            for i = -1, seatCount - 2 do
                if GetPedInVehicleSeat(playerVehicle, i) == playerPed then
                    seatIndex = i
                    break
                end
            end
            if speedPercent > 100 then
                speedPercent = 100
            end

            local payload = {
                action = "updateVehicleInfo",
                speed = math.floor(speed),
                speedPercent = speedPercent,
                maxSpeed = math.floor(maxSpeed + 0.5),
                belt = isSeatbeltAllowed(playerVehicle) and beltOn or false,
                doorsLocked = doorsLocked,
                engineOn = isEngineRunning,
                light = light,
                altitude = altitude,
                health = health,
                engineHealth = math.floor((GetVehicleEngineHealth(playerVehicle) / 1000.0) * 100),
                bodyHealth = math.floor((GetVehicleBodyHealth(playerVehicle) / 1000.0) * 100),
                gear = isDriver and GetVehicleCurrentGear(playerVehicle) or 0,
                seatIndex = seatIndex,
                seatCount = seatCount,
                nitro = isDriver and getNitro() or 0,
                indicatorLights = GetVehicleIndicatorLights(playerVehicle),
                value = true,
            }

            -- Door/window states rarely change; only poll them a few times a second
            -- instead of every 50ms tick to cut down on native call overhead while driving.
            if CarControl then
                carControlTick = carControlTick + 1
                if carControlTick >= 4 or playerVehicle ~= lastVehicle then
                    carControlTick = 0
                    cachedDoorStates = CarControl.GetDoorStates(playerVehicle)
                    cachedWindowStates = CarControl.GetWindowStates(playerVehicle)
                end
                for key, value in pairs(cachedDoorStates) do
                    payload[key] = value
                end
                for key, value in pairs(cachedWindowStates) do
                    payload[key] = value
                end
            end

            SendNUIMessage(payload)

            sleep = 50
            CheckRadarDisplay()
        else
            lastVehicle = 0
            SendNUIMessage({
                action = "updateVehicleInfo",
                value = false
            })

            CheckRadarDisplay()
            sleep = 1000
        end
        Citizen.Wait(sleep)
    end
end)


Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)

        if playerVehicle ~= 0 and GetPedInVehicleSeat(playerVehicle, -1) == playerPed then
            SendNUIMessage({
                action = "updateFuel",
                fuel = getFuel(playerVehicle)
            })
        end
        Citizen.Wait(3000)
    end
end)

function isVehicleHeadlightOn(vehicle)
    local _, lightsOn, highBeams = GetVehicleLightsState(vehicle)
    return lightsOn == 1 or highBeams == 1
end

function GetHelicopterDistanceFromGround(vehicle)
    if vehicle ~= 0 and IsPedInAnyHeli(PlayerPedId()) then
        local vehicleCoords = GetEntityCoords(vehicle)
        local groundFound, groundZ = GetGroundZFor_3dCoord(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 50, 0)
        if groundFound then
            local val = vehicleCoords.z - groundZ
            if val < 2 then
                return 0
            else
                return val * 3.281
            end
        end
    end
    return 0
end


function GetVehicleHealthPercentage(vehicle)
    if vehicle ~= 0 and IsEntityAVehicle(vehicle) then
        local engineHealth = GetVehicleEngineHealth(vehicle)  
        local bodyHealth = GetVehicleBodyHealth(vehicle)      

        local engineHealthPercent = (engineHealth / 1000.0) * 100
        local bodyHealthPercent = (bodyHealth / 1000.0) * 100

        local averageHealth = (engineHealthPercent + bodyHealthPercent) / 2

        return averageHealth
    end
    return 0
end