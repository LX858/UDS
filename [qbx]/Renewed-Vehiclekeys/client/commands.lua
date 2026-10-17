local utils = require 'utils.client'
local Config = require 'data'

-- Test command: nhận lệnh spawn từ server
RegisterNetEvent('Renewed-Vehiclekeys:client:testSpawnCar', function(modelName)
    local model = joaat(modelName)

    if not IsModelValid(model) then
        lib.notify({ title = 'Test Car', description = 'Model không hợp lệ: ' .. modelName, type = 'error' })
        return
    end

    lib.requestModel(model, 5000)

    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local spawnCoords = vector3(
        coords.x + math.sin(-math.rad(heading)) * 5.0,
        coords.y + math.cos(-math.rad(heading)) * 5.0,
        coords.z
    )

    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)

    local timeout = 5000
    while not DoesEntityExist(vehicle) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end

    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(vehicle) then
        lib.notify({ title = 'Test Car', description = 'Spawn xe thất bại!', type = 'error' })
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)

    -- Spawn NPC ngồi ghế lái để test kéo người ra
    local npcModel = joaat('a_m_m_business_01')
    lib.requestModel(npcModel, 3000)
    local npc = CreatePedInsideVehicle(vehicle, 4, npcModel, -1, true, false)
    if DoesEntityExist(npc) then
        SetEntityAsMissionEntity(npc, true, true)
        SetBlockingOfNonTemporaryEvents(npc, true) -- NPC đứng yên, không chạy đi
        SetPedIntoVehicle(npc, vehicle, -1)
    end
    SetModelAsNoLongerNeeded(npcModel)

    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerServerEvent('Renewed-Vehiclekeys:server:testCarSpawned', plate)
end)

if not Config.useKeyItem then
    lib.callback.register('Renewed-Vehiclekeys:client:getVehicle', function()
        local vehicle = cache.vehicle or utils.getClosestKeyCar()

        return utils.hasKey(GetVehicleNumberPlateText(vehicle)) and VehToNet(vehicle) or false
    end)

    lib.callback.register('Renewed-Vehiclekeys:client:getPlayers', function()
        local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 5.0)

        for i = 1, #players do
            players[i] = GetPlayerServerId(players[i].id)
        end

        return players
    end)
end