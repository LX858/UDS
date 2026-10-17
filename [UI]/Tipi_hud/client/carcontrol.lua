CarControl = CarControl or {}
local CarControl = CarControl

---@type table<number, table<integer, boolean>>
local windowStatesByVehicle = {}

local function getVehicleOrNotify()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        return vehicle
    end
    lib.notify({
        title = 'Điều khiển xe',
        description = 'Bạn cần ở trong xe',
        type = 'error',
    })
    return nil
end

local function getWindowStates(vehicle)
    if not windowStatesByVehicle[vehicle] then
        windowStatesByVehicle[vehicle] = { false, false, false, false }
    end
    return windowStatesByVehicle[vehicle]
end

local function ensureNetworkControl(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return false
    end
    if NetworkHasControlOfEntity(entity) then
        return true
    end
    NetworkRequestControlOfEntity(entity)
    for _ = 1, 30 do
        if NetworkHasControlOfEntity(entity) then
            return true
        end
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

local function isDriver(vehicle)
    return GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()
end

---@param data any
---@return string|nil
function CarControl.ParseIndicatorMode(data)
    if type(data) == 'string' then
        return data
    end
    if type(data) == 'table' then
        return data.mode or data.value or data[1]
    end
    return nil
end

---@param doorIndex number
---@return table
function CarControl.ToggleDoorState(doorIndex)
    local vehicle = getVehicleOrNotify()
    if not vehicle then
        return { success = false }
    end

    if GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0 then
        SetVehicleDoorShut(vehicle, doorIndex, false)
        return { success = true, state = false }
    end

    SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    return { success = true, state = true }
end

---@param windowIndex number 0-3
---@return table
function CarControl.ToggleWindow(windowIndex)
    local vehicle = getVehicleOrNotify()
    if not windowIndex or windowIndex < 0 or windowIndex > 3 then
        return { success = false }
    end
    if not vehicle then
        return { success = false }
    end

    local states = getWindowStates(vehicle)
    local isOpen = not states[windowIndex + 1]
    if isOpen then
        RollDownWindow(vehicle, windowIndex)
    else
        RollUpWindow(vehicle, windowIndex)
    end
    states[windowIndex + 1] = isOpen
    return { success = true, state = isOpen }
end

---@param mode 'left'|'right'|'hazard'|'off'
---@return table
function CarControl.ToggleIndicator(mode)
    local vehicle = getVehicleOrNotify()
    if not vehicle then
        return { success = false }
    end

    mode = CarControl.ParseIndicatorMode(mode)
    if not mode then
        return { success = false }
    end

    if not isDriver(vehicle) then
        lib.notify({
            title = 'Xi-nhan',
            description = 'Chỉ tài xế mới bật xi-nhan',
            type = 'warning',
        })
        return { success = false, state = GetVehicleIndicatorLights(vehicle) }
    end

    if not ensureNetworkControl(vehicle) then
        lib.notify({
            title = 'Xi-nhan',
            description = 'Không thể điều khiển xe này',
            type = 'error',
        })
        return { success = false, state = GetVehicleIndicatorLights(vehicle) }
    end

    local current = GetVehicleIndicatorLights(vehicle)
    if mode == 'off' then
        SetVehicleIndicatorLights(vehicle, 0, false)
        SetVehicleIndicatorLights(vehicle, 1, false)
    elseif mode == 'left' then
        local enable = current ~= 1
        SetVehicleIndicatorLights(vehicle, 0, false)
        SetVehicleIndicatorLights(vehicle, 1, enable)
    elseif mode == 'right' then
        local enable = current ~= 2
        SetVehicleIndicatorLights(vehicle, 1, false)
        SetVehicleIndicatorLights(vehicle, 0, enable)
    elseif mode == 'hazard' then
        local enable = current ~= 3
        SetVehicleIndicatorLights(vehicle, 0, enable)
        SetVehicleIndicatorLights(vehicle, 1, enable)
    else
        return { success = false, state = current }
    end

    return { success = true, state = GetVehicleIndicatorLights(vehicle) }
end

---@return table
function CarControl.ToggleVehicleLights()
    local vehicle = getVehicleOrNotify()
    if not vehicle then
        return { success = false }
    end

    ensureNetworkControl(vehicle)

    local _, lowBeamsOn, highBeamsOn = GetVehicleLightsState(vehicle)
    local isOn = lowBeamsOn == 1 or highBeamsOn == 1
    local newState = isOn and 1 or 2
    SetVehicleLights(vehicle, newState)
    return { success = true, state = not isOn }
end

---@param seatIndex number
---@return boolean
function CarControl.SitAtSeat(seatIndex)
    local vehicle = getVehicleOrNotify()
    if not vehicle then
        return false
    end

    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    if seatIndex < -1 or seatIndex > maxSeats - 2 then
        return false
    end

    local ped = PlayerPedId()
    if IsVehicleSeatFree(vehicle, seatIndex) then
        SetPedIntoVehicle(ped, vehicle, seatIndex)
        return true
    end
    return false
end

---@return boolean|nil
function CarControl.ToggleEngine()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        local isEngineOn = GetIsVehicleEngineRunning(veh)
        SetVehicleEngineOn(veh, not isEngineOn, not isEngineOn, true)
        return not isEngineOn
    end
    lib.notify({
        title = 'Điều khiển xe',
        description = 'Chỉ tài xế mới bật/tắt động cơ',
        type = 'warning',
    })
    return nil
end

---@param vehicle number
---@return table
function CarControl.GetDoorStates(vehicle)
    return {
        isFrontLeftDoorOn = GetVehicleDoorAngleRatio(vehicle, 0) > 0.0,
        isFrontRightDoorOn = GetVehicleDoorAngleRatio(vehicle, 1) > 0.0,
        isBackLeftDoorOn = GetVehicleDoorAngleRatio(vehicle, 2) > 0.0,
        isBackRightDoorOn = GetVehicleDoorAngleRatio(vehicle, 3) > 0.0,
        isHoodOn = GetVehicleDoorAngleRatio(vehicle, 4) > 0.0,
        isTrunkOn = GetVehicleDoorAngleRatio(vehicle, 5) > 0.0,
    }
end

---@param vehicle number
---@return table
function CarControl.GetWindowStates(vehicle)
    local states = getWindowStates(vehicle)
    return {
        isWindowFrontLeftOpen = states[1],
        isWindowFrontRightOpen = states[2],
        isWindowBackLeftOpen = states[3],
        isWindowBackRightOpen = states[4],
    }
end

