local utils = require 'utils.server'

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    if plate then
        utils.addKey(source, plate)
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:addKey', function(plate)
    if plate then
        utils.addKey(source, plate)
    end
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:removeKey', function(plate)
    if plate then
        utils.removeKey(source, plate)
    end
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
        return utils.hasKey(id, plate)
    end
end)

exportHandler('HasKey', function(id, plate)
    if id and plate then
        return utils.hasKey(id, plate)
    end
end)


exportHandler('RemoveKeys', function(id, plate)
    if id and plate then
        return utils.removeKey(id, plate)
    end
end)

exportHandler('RemoveKey', function(id, plate)
    if id and plate then
        return utils.removeKey(id, plate)
    end
end)

exportHandler('GiveKeys', function(id, plate)
    if id and plate then
        return utils.addKey(id, plate)
    end
end)

exportHandler('GiveKey', function(id, plate)
    if id and plate then
        return utils.addKey(id, plate)
    end
end)