lib.locale()

-- Track vehicles in preview mode
local vehiclesInPreview = {}

-- Store vehicle original state when preview starts
RegisterNetEvent('mt_workshops:server:startPreview', function(vehicleNetId, originalState)
    local src = source
    if not vehicleNetId then return end
    
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicle) then return end
    
    -- Store original vehicle state and plate
    vehiclesInPreview[src] = {
        vehicleNetId = vehicleNetId,
        originalMods = originalState,
        plate = originalState and originalState.plate or GetVehicleNumberPlateText(vehicle)
    }
end)

-- Clean up when preview ends normally
RegisterNetEvent('mt_workshops:server:endPreview', function(vehicleNetId)
    local src = source
    vehiclesInPreview[src] = nil
end)

lib.callback.register('mt_workshops:server:saveVehicleMods', function(source, vehicle, mods, isTuning, coords, tuningType, itemUsed)
    if not mods or not mods.plate or not isVehicleOwned(mods.plate) then return false end
    if vehiclesInPreview[source] then
        print(string.format('[MT_WORKSHOPS] Blocked saveVehicleMods from source %s while in preview mode!', source))
        return false
    end
    saveVehicleMods(vehicle, mods, isTuning, coords)
    
    -- Log tuning action
    if isTuning then
        logTuning(source, mods.plate, tuningType or 'Unknown', itemUsed, coords)
    end
    return true
end)

-- Chỉ đăng ký command nếu không sử dụng item
if not Config.preview.useItem then
    lib.addCommand(Config.preview.command, {
        help = locale('command_preview_desc'),
    }, function(source, args, raw)
        local src = source
        local Player = nil
        
        -- Get player based on framework
        if Config.framework == 'qb' then
            Player = Config.core.Functions.GetPlayer(src)
        elseif Config.framework == 'esx' then
            Player = Config.core.GetPlayerFromId(src)
        elseif Config.framework == 'qbx' then
            Player = exports.qbx_core:GetPlayer(src)
        end
        
        if not Player then return end
        
        TriggerClientEvent('mt_workshops:client:openPreviewMenu', src)
    end)
end

lib.addCommand(Config.classesCommand, {
    help = locale('command_class_desc'),
}, function(source, args, raw)
    local src = source
    TriggerClientEvent('mt_workshops:client:checkVehicleClass', src)
end)

RegisterNetEvent('mt_workshops:server:setVehicleMod', function(vehicle, modType, modLevel, player, itemUsed)
    TriggerClientEvent('mt_workshops:client:setVehicleMod', -1, vehicle, modType, modLevel, player, itemUsed)
end)

RegisterNetEvent('mt_workshops:server:setVehicleCosmeticMod', function(vehicle, isPaint, wheelType, modType, modLevel, player, customColorData, itemUsed, detailLabel)
    TriggerClientEvent('mt_workshops:client:setVehicleCosmeticMod', -1, vehicle, isPaint, wheelType, modType, modLevel, player, customColorData, itemUsed, detailLabel)
end)

RegisterNetEvent('mt_workshops:server:setVehicleMods', function(vehicle, newMods, player, tuningType)
    TriggerClientEvent('mt_workshops:client:setVehicleMods', -1, vehicle, newMods, player, tuningType)
end)

RegisterNetEvent('mt_workshops:server:payRepair', function(price)
    local src = source
    if Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveMoney('cash', price, 'repair-vehicle')
        end
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if Player then
            Player.removeMoney(price, 'repair-vehicle')
        end
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            Player.Functions.RemoveMoney('cash', price, 'repair-vehicle')
        end
    end
end)

CreateThread(function()
    for _, v in pairs(Config.workshops) do
        TriggerEvent('esx_society:registerSociety', v.job, v.label, 'society_'..v.job, 'society_'..v.job, 'society_'..v.job, { type = 'public' })
    end
end)

-- Server-side cleanup for preview when player disconnects
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    -- Check if this player had a vehicle in preview
    if vehiclesInPreview[src] then
        local previewData = vehiclesInPreview[src]
        local netId = previewData.vehicleNetId
        local originalMods = previewData.originalMods
        local plate = previewData.plate or (originalMods and originalMods.plate)
        
        -- 1. Ensure SQL database mods remain / are reverted to original state
        if originalMods and plate then
            saveVehicleMods(nil, originalMods, false, nil)
        end
        
        -- 2. Delete the vehicle entity from the server world if it still exists
        -- This ensures the player cannot reconnect, find the modified car, and garage-store it to exploit
        if netId then
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            -- Broadcast restore to any remaining clients as backup
            TriggerClientEvent('mt_workshops:client:restoreVehicleFromPreview', -1, netId, originalMods, src)
        end
        
        -- Clean up tracking
        vehiclesInPreview[src] = nil
    end
end)

-- Handle resource restart
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        --print("DEBUG: Resource stopping, cleaning up all preview states")
        -- Trigger cleanup on all clients
        TriggerClientEvent('mt_workshops:client:forceCleanupPreview', -1)
    end
end)