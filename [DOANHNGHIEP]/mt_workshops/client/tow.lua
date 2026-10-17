local vehicleTowed = nil
local currentTruck = nil
local canTowVehicle = false
local haveAttachedVehicle = false

createAddModelTarget('mtlscv3', {
    {
        label = locale('target_tow_vehicle'),
        icon = 'far fa-arrow-alt-circle-up',
        canInteract = function()
            if vehicleTowed then return false end
            return true
        end,
        onSelect = function(data)
            currentTruck = data.entity
            canTowVehicle = true
            showTextUI(locale('textui_tow_help'), "eye")
        end,
        action = function(entity)
            currentTruck = entity
            canTowVehicle = true
            showTextUI(locale('textui_tow_help'), "eye")
        end
    },
    {
        label = locale('target_drop_vehicle'),
        icon = 'far fa-arrow-alt-circle-up',
        canInteract = function()
            if vehicleTowed then return true end
            return false
        end,
        onSelect = function()
            dropVehicle()
        end,
        action = function()
            dropVehicle()
        end
    },
}, 2.5)

createGlobalVehicleTarget({
    {
        label = locale('target_tow_vehicle'),
        icon = 'far fa-arrow-alt-circle-up',
        canInteract = function(entity)
            return (GetHashKey(entity) ~= GetHashKey(currentTruck) and canTowVehicle and haveAttachedVehicle == false)
        end,
        onSelect = function(data) towVehicle(data.entity) end,
        action = function(entity) towVehicle(entity) end
    }
}, 2.5)

towVehicle = function(vehicle)
    if not vehicle or not currentTruck or not DoesEntityExist(vehicle) or not DoesEntityExist(currentTruck) then return end
    local bone = GetEntityBoneIndexByName(currentTruck, 'bodyshell')
    if bone == -1 then bone = 0 end
    AttachEntityToEntity(vehicle, currentTruck, bone, 0.0, -1.5 + -0.85, 0.0 + 0.85, 0, 0, 0, 1, 1, 0, 1, 0, 1)
    FreezeEntityPosition(vehicle, true)
    vehicleTowed = vehicle
    haveAttachedVehicle = true
    hideTextUI()
    -- Trigger event khi cau xe (cho cac resource khac lang nghe)
    TriggerEvent('mt_workshops:vehicleTowed', vehicle, currentTruck)
end

dropVehicle = function()
    if not vehicleTowed or not DoesEntityExist(vehicleTowed) or not currentTruck or not DoesEntityExist(currentTruck) then
        vehicleTowed = nil
        haveAttachedVehicle = false
        canTowVehicle = false
        return
    end
    local coord = GetEntityCoords(currentTruck)
    local heading = GetEntityHeading(currentTruck)
    
    local dropX = coord.x - (math.sin(math.rad(heading)) * 8.0)
    local dropY = coord.y - (math.cos(math.rad(heading)) * 8.0)
    local dropZ = coord.z
    
    DetachEntity(vehicleTowed, true, true)
    FreezeEntityPosition(vehicleTowed, false)
    
    SetEntityCoords(vehicleTowed, dropX, dropY, dropZ, false, false, false, true)
    SetEntityHeading(vehicleTowed, heading)
    
    PlaceObjectOnGroundProperly(vehicleTowed)
    
    vehicleTowed = nil
    haveAttachedVehicle = false
    canTowVehicle = false
end