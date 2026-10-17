local Utils = require 'utils.client'

RegisterNetEvent('vehiclekeys:client:SetOwner', function(plate)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
end)

exports('addKey', function(plate)
    TriggerServerEvent('Renewed-Vehiclekeys:server:addKey', plate)
end)

exports('removeKey', function(plate)
    TriggerServerEvent('Renewed-Vehiclekeys:server:removeKey', plate)
end)

local qbCompat = {
    'qb-vehiclekeys',
    'qbx-vehiclekeys',
    'qbx_vehiclekeys',
    'wasabi_carlock',
}

local function exportHandler(exportName, func)
    for i = 1, #qbCompat do
        AddEventHandler(('__cfx_export_%s_%s'):format(qbCompat[i], exportName), function(setCB)
            setCB(func)
        end)
    end
end

exportHandler('HasKeys', function(id, plate)
    if id and plate then
        return Utils.hasKey(plate)
    end
end)

exportHandler('HasKey', function(id, plate)
    if id and plate then
        return Utils.hasKey(plate)
    end
end)

exportHandler('GiveKey', function(plate)
    if plate then
        TriggerServerEvent('Renewed-Vehiclekeys:server:addKey', plate)
    end
end)

exportHandler('RemoveKey', function(plate)
    if plate then
        TriggerServerEvent('Renewed-Vehiclekeys:server:removeKey', plate)
    end
end)