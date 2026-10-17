local vehicleControlOpen = false

local function getPlayerVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        return nil, ped
    end
    return vehicle, ped
end

local function closeVehicleControl()
    if not vehicleControlOpen then
        return
    end
    vehicleControlOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'setVehicleControlOpen',
        open = false,
    })
end

local function openVehicleControl()
    local vehicle = getPlayerVehicle()
    if not vehicle then
        lib.notify({
            title = 'Điều khiển xe',
            description = 'Bạn cần ở trong xe',
            type = 'error',
        })
        return
    end

    if vehicleControlOpen then
        closeVehicleControl()
        return
    end

    vehicleControlOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'setVehicleControlOpen',
        open = true,
    })
end

RegisterNUICallback('nui:closeVehicleControl', function(_, cb)
    closeVehicleControl()
    cb('ok')
end)

RegisterNUICallback('nui:setVehicleDoor', function(doorIndex, cb)
    cb(CarControl.ToggleDoorState(tonumber(doorIndex)))
end)

RegisterNUICallback('nui:setVehicleLights', function(_, cb)
    cb(CarControl.ToggleVehicleLights())
end)

RegisterNUICallback('nui:setVehicleWindow', function(windowIndex, cb)
    cb(CarControl.ToggleWindow(tonumber(windowIndex)))
end)

RegisterNUICallback('nui:setVehicleIndicator', function(mode, cb)
    cb(CarControl.ToggleIndicator(mode))
end)
RegisterNUICallback('nui:toggleVehicleEngine', function(_, cb)
    local state = CarControl.ToggleEngine()
    cb({ success = state ~= nil, state = state })
end)

RegisterNUICallback('nui:setPedIntoVehicle', function(seatIndex, cb)
    cb(CarControl.SitAtSeat(tonumber(seatIndex)))
end)

if Config.UseVehicleControl then
    RegisterCommand(Config.VehicleControlCommand or 'vehcontrol', function()
        openVehicleControl()
    end, false)

    if Config.VehicleControlKey then
        RegisterKeyMapping(
            Config.VehicleControlCommand or 'vehcontrol',
            'Mở bảng điều khiển xe',
            'keyboard',
            Config.VehicleControlKey
        )
    end
end

exports('OpenVehicleControl', openVehicleControl)
exports('CloseVehicleControl', closeVehicleControl)
exports('SitAtVehicleSeat', CarControl.SitAtSeat)
