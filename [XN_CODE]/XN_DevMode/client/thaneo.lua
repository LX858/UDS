local QBCore = exports['qb-core']:GetCoreObject()

-- Register keybind K cho thả neo
RegisterKeyMapping("thaneo", "Thả/Hủy neo thuyền", "keyboard", "K")

-- Function to send notifications
local function SendNotification(message, type)
    if Config.NotificationType == 'ox_lib' then
        lib.notify({
            title = 'Boat Anchor',
            description = message,
            type = type or 'inform',
            position = Config.NotificationPosition
        })
    else
        QBCore.Functions.Notify(message, type or 'primary', 5000)
    end
end

-- Main anchor command
RegisterCommand("thaneo", function(source, args, rawCommand)
    local ped = PlayerPedId()
    
    -- Check if player is in a vehicle
    if not IsPedInAnyVehicle(ped, false) then
        SendNotification(Config.Messages.notInBoat, 'error')
        return
    end
    
    local boat = GetVehiclePedIsIn(ped, false)
    local vehicleClass = GetVehicleClass(boat)
    
    -- Check if vehicle is boat (14) or plane/heli (15, 16) on water
    local isBoat = vehicleClass == 14
    local isAircraft = vehicleClass == 15 or vehicleClass == 16
    local isOnWater = IsEntityInWater(boat)
    
    if not isBoat and not (isAircraft and isOnWater) then
        SendNotification(Config.Messages.notInBoat, 'error')
        return
    end
    
    -- Check if player is the driver
    if GetPedInVehicleSeat(boat, -1) ~= ped then
        SendNotification(Config.Messages.notDriver, 'error')
        return
    end
    
    -- Check speed
    local currentSpeed = GetEntitySpeed(boat) * 3.6 -- Convert to km/h
    if currentSpeed > Config.MaxSpeedToDeploy then
        SendNotification(Config.Messages.tooFast, 'error')
        return
    end
    
    -- Toggle anchor
    if IsBoatAnchoredAndFrozen(boat) then
        -- Raise anchor
        SetBoatAnchor(boat, false)
        SetBoatFrozenWhenAnchored(boat, false)
        SetForcedBoatLocationWhenAnchored(boat, false)
        SendNotification(Config.Messages.anchorRaised, 'success')
        
        -- Trigger server event for logging/tracking if needed
        TriggerServerEvent('boat_anchor:anchorRaised', NetworkGetNetworkIdFromEntity(boat))
    else
        -- Deploy anchor
        if CanAnchorBoatHere(boat) then
            SetBoatAnchor(boat, true)
            SetBoatFrozenWhenAnchored(boat, true)
            SetForcedBoatLocationWhenAnchored(boat, true)
            SendNotification(Config.Messages.anchorLowered, 'success')
            
            -- Trigger server event for logging/tracking if needed
            TriggerServerEvent('boat_anchor:anchorLowered', NetworkGetNetworkIdFromEntity(boat))
        else
            SendNotification(Config.Messages.notInWater, 'error')
        end
    end
end, false)

-- Sợi chỉ để kiểm tra thuyền neo khi vào
-- CreateThread(function()
--     while true do
--         Wait(Config.CheckInterval)
        
--         local ped = PlayerPedId()
--         local vehicle = GetVehiclePedIsEntering(ped)
        
--         if vehicle and vehicle ~= 0 then
--             if IsBoatAnchoredAndFrozen(vehicle) then
--                 SendNotification(Config.Messages.boatAnchored, 'inform')
--             end
--         end
--     end
-- end)

-- Thêm menu ngữ cảnh OX_LIB cho các tùy chọn bổ sung (tùy chọn)
local function OpenAnchorMenu()
    local ped = PlayerPedId()
    
    if not IsPedInAnyVehicle(ped, false) then
        SendNotification(Config.Messages.notInBoat, 'error')
        return
    end
    
    local boat = GetVehiclePedIsIn(ped, false)
    local vehicleClass = GetVehicleClass(boat)
    local isBoat = vehicleClass == 14
    local isAircraft = vehicleClass == 15 or vehicleClass == 16
    local isOnWater = IsEntityInWater(boat)
    
    if not isBoat and not (isAircraft and isOnWater) then
        SendNotification(Config.Messages.notInBoat, 'error')
        return
    end
    
    local isAnchored = IsBoatAnchoredAndFrozen(boat)
    
    lib.registerContext({
        id = 'boat_anchor_menu',
        title = 'Boat Anchor',
        options = {
            {
                title = isAnchored and 'Nâng neo' or 'Hạ neo',
                description = isAnchored and 'Nâng neo thuyền' or 'Hạ neo thuyền',
                icon = isAnchored and 'fas fa-arrow-up' or 'fas fa-arrow-down',
                onSelect = function()
                    ExecuteCommand('thaneo')
                end
            },
            {
                title = 'Cancel',
                description = 'Đóng menu',
                icon = 'fas fa-times'
            }
        }
    })
    
    lib.showContext('boat_anchor_menu')
end

-- Register the menu command (optional - can be triggered by other means)
RegisterCommand('thaoneomenu', OpenAnchorMenu, false)

-- Admin event to check anchor status
RegisterNetEvent('boat_anchor:checkStatus', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle and vehicle ~= 0 then
        local isAnchored = IsBoatAnchoredAndFrozen(vehicle)
        local model = GetEntityModel(vehicle)
        local coords = GetEntityCoords(vehicle)
        
        print(string.format('Boat Status - Model: %s, Anchored: %s, Coords: %s', 
            model, tostring(isAnchored), coords))
        
        SendNotification(string.format('Boat is %s', isAnchored and 'anchored' or 'not anchored'), 'inform')
    else
        SendNotification('No boat found', 'error')
    end
end)

-- Export functions for other resources
exports('IsBoatAnchored', function(vehicle)
    return IsBoatAnchoredAndFrozen(vehicle)
end)

exports('ToggleAnchor', function(vehicle)
    if IsBoatAnchoredAndFrozen(vehicle) then
        SetBoatAnchor(vehicle, false)
        SetBoatFrozenWhenAnchored(vehicle, false)
        SetForcedBoatLocationWhenAnchored(vehicle, false)
        return false
    else
        if CanAnchorBoatHere(vehicle) then
            SetBoatAnchor(vehicle, true)
            SetBoatFrozenWhenAnchored(vehicle, true)
            SetForcedBoatLocationWhenAnchored(vehicle, true)
            return true
        end
    end
    return nil
end)


RegisterCommand("gamebuild", function()
    local build = GetGameBuildNumber()
    print("Current Game Build: " .. build)
    TriggerEvent("chat:addMessage", {
        args = {"^2[System]", "Game Build hiện tại: ^1" .. build}
    })
end, false)