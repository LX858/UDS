local utils = require 'utils.server'
local Config = require 'data'

-- Test command: spawn xe + tặng chìa khóa
lib.addCommand('testcar', {
    help = '[TEST] Spawn xe và nhận chìa khóa',
    params = {
        {
            name = 'model',
            type = 'string',
            help = 'Tên model xe (vd: adder, zentorno)',
            optional = true,
        },
    },
    restricted = 'group.admin'
}, function(source, args)
    local model = args.model or 'adder'
    TriggerClientEvent('Renewed-Vehiclekeys:client:testSpawnCar', source, model)
end)

RegisterNetEvent('Renewed-Vehiclekeys:server:testCarSpawned', function(plate)
    local src = source
    if not plate or plate == '' then return end
    utils.addKey(src, plate)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Test Car',
        description = ('Đã spawn xe và thêm chìa khóa biển **%s**'):format(plate),
        type = 'success',
        duration = 5000,
    })
end)

lib.addCommand('addkey', {
    help = 'Give a vehicle key to a player',
    params = {
        {
            name = 'target',
            type = 'pid',
            help = 'Target player\'s server id',
            optional = true,
        },
        {
            name = 'plate',
            type = 'string',
            help = 'Plate of the vehicle (Case sensitive)',
            optional = true,
        },
    },
    restricted = 'group.admin'
}, function(source, args)

    if args.target and args.plate then
        utils.addKey(args.target, args.plate)
    elseif not args.target and not args.plate then
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(source), false)

        if vehicle > 0 then
            utils.addKey(source, GetVehicleNumberPlateText(vehicle))
        end
    end
end)

if not Config.useKeyItem then
    lib.addCommand('givekeys', {
        help = 'Give keys to nearby or a specific player',
        params = {
            {
                name = 'target',
                type = 'pid',
                help = 'Target player\'s server id',
                optional = true
            },
        },
    }, function(source, args)
        local netId = lib.callback.await('Renewed-Vehiclekeys:client:getVehicle', source)

        local vehicle = netId and utils.getEntityFromNetId(netId)

        if vehicle and vehicle > 0 then
            local plate = GetVehicleNumberPlateText(vehicle)
            if utils.hasKey(source, plate) then

                if args.target then
                    utils.addKey(args.target, plate)
                else
                    local players = lib.callback.await('Renewed-Vehiclekeys:client:getPlayers', source)

                    for i = 1, #players do
                        utils.addKey(players[i], plate)
                    end
                end

            end
        end
    end)
end