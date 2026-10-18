WS.RegisterEventHandler("neons_ddame:server:hit", function(playerId, attackerId, HitHealth, HitArmour, victimDied)
    victimDied = victimDied == true or victimDied == 1
    WS.TriggerClientEvent("neons_ddame:client:hit", tonumber(attackerId), playerId, HitHealth, HitArmour, victimDied)
    local healthDamage = tonumber(HitHealth) or 0
    if healthDamage > 0 then
        TriggerEvent("neons_ddame:server:healthHit", tonumber(playerId), tonumber(attackerId), healthDamage)
    end
    if victimDied or healthDamage >= 100 then
        TriggerEvent("neons_ddame:server:kill", tonumber(playerId), tonumber(attackerId))
    end
end)

local boatRentalCooldown = {}

local function getStation(stationId)
    stationId = tonumber(stationId)
    if not stationId then return nil end
    return Config.BoatRental and Config.BoatRental.stations[stationId]
end

local function isAllowedBoat(model)
    for _, boat in ipairs(Config.BoatRental.boats) do
        if boat.model == model then return true end
    end
    return false
end

lib.callback.register('neons_ddame:server:rentBoat', function(source, stationId, model, spawnIndex)
    local rentalConfig = Config.BoatRental
    local station = rentalConfig and getStation(stationId)
    spawnIndex = tonumber(spawnIndex)

    if not station or not isAllowedBoat(model) or not spawnIndex or not station.spawns[spawnIndex] then
        return false, 'Thong tin thue thuyen khong hop le.'
    end

    local now = os.time()
    if boatRentalCooldown[source] and now - boatRentalCooldown[source] < 2 then
        return false, 'Vui long thao tac cham lai.'
    end

    local playerPed = GetPlayerPed(source)
    if playerPed == 0 then
        return false, 'Khong tim thay nhan vat cua ban.'
    end

    local playerCoords = GetEntityCoords(playerPed)
    local npcCoords = vector3(station.npc.x, station.npc.y, station.npc.z)
    if #(playerCoords - npcCoords) > 8.0 then
        return false, 'Ban dang o qua xa quay thue thuyen.'
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return false, 'Khong the xac dinh nguoi choi.'
    end

    local price = tonumber(rentalConfig.price) or 2000
    if not player.Functions.RemoveMoney('cash', price, 'boat-rental-' .. model) then
        return false, ('Ban can $%d tien mat de thue thuyen.'):format(price)
    end

    boatRentalCooldown[source] = now
    return true
end)

AddEventHandler('playerDropped', function()
    boatRentalCooldown[source] = nil
end)

local function getRedZones()
    local zones = Config.IslandRedZones or Config.IslandRedZone
    if not zones then return {} end
    if zones.coords then
        return { zones }
    end
    local list = {}
    for _, v in pairs(zones) do
        if type(v) == 'table' and v.coords and v.radius then
            list[#list + 1] = v
        end
    end
    return list
end

local function getVehicleStorageConfig()
    if Config.RedZoneVehicleStorage then
        return Config.RedZoneVehicleStorage
    end
    local zones = Config.IslandRedZones or Config.IslandRedZone
    if zones then
        if zones.vehicleStorage then return zones.vehicleStorage end
        if zones[1] and zones[1].vehicleStorage then return zones[1].vehicleStorage end
        for _, z in pairs(zones) do
            if type(z) == 'table' and z.vehicleStorage then
                return z.vehicleStorage
            end
        end
    end
    return {
        enabled = true,
        bucket = 999,
        propModel = 'null_garage_prop',
        interactionDistance = 3.0,
        retrieveDuration = 5000
    }
end

local vehicleStorage = getVehicleStorageConfig()
local trackedRedZoneDrivers = {}
local storedRedZoneVehicles = {}

local function getNetworkVehicle(netId)
    netId = tonumber(netId)
    if not netId then return 0 end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return 0
    end

    return vehicle
end

local function isInsideIslandRedZone(coords)
    local zones = getRedZones()
    for _, zone in ipairs(zones) do
        if zone.coords and zone.radius then
            local dx = coords.x - zone.coords.x
            local dy = coords.y - zone.coords.y
            if (dx * dx) + (dy * dy) <= (zone.radius * zone.radius) then
                return true, zone
            end
        end
    end
    return false
end

local function sendStoreFailed(src, netId, reason)
    TriggerClientEvent('neons_ddame:client:redZoneVehicleStoreFailed', src, netId, reason)
end

local function spawnStorageProp(coords, heading, bucket)
    local modelHash = joaat(vehicleStorage.propModel or 'null_garage_prop')
    local prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    if not prop or prop == 0 then return 0 end

    local timeoutAt = GetGameTimer() + 3000
    while not DoesEntityExist(prop) and GetGameTimer() < timeoutAt do
        Wait(0)
    end

    if not DoesEntityExist(prop) then
        return 0
    end

    SetEntityHeading(prop, heading or 0.0)
    FreezeEntityPosition(prop, true)
    exports.qbx_core:SetEntityBucket(prop, bucket)
    return prop
end

local function cleanupStoredVehicle(netId, restoreBucket)
    local storedVehicle = storedRedZoneVehicles[netId]
    if not storedVehicle then return end

    local vehicle = getNetworkVehicle(storedVehicle.vehicleNetId)
    if vehicle ~= 0 and restoreBucket then
        exports.qbx_core:SetEntityBucket(vehicle, storedVehicle.originalBucket)
    end

    local prop = NetworkGetEntityFromNetworkId(storedVehicle.propNetId)
    if prop ~= 0 and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end

    storedRedZoneVehicles[netId] = nil
end

RegisterNetEvent('neons_ddame:server:trackRedZoneVehicle', function(vehicleNetId)
    if not vehicleStorage.enabled then return end

    local src = source
    vehicleNetId = tonumber(vehicleNetId)
    local vehicle = getNetworkVehicle(vehicleNetId)
    local playerPed = GetPlayerPed(src)

    if vehicle == 0 or playerPed == 0 or not DoesEntityExist(playerPed) then return end
    if not isInsideIslandRedZone(GetEntityCoords(vehicle)) then return end
    if GetPedInVehicleSeat(vehicle, -1) ~= playerPed then return end
    if GetEntityRoutingBucket(vehicle) ~= GetPlayerRoutingBucket(src) then return end

    trackedRedZoneDrivers[vehicleNetId] = src
end)

RegisterNetEvent('neons_ddame:server:storeRedZoneVehicle', function(vehicleNetId)
    if not vehicleStorage.enabled then return end

    local src = source
    vehicleNetId = tonumber(vehicleNetId)
    local vehicle = getNetworkVehicle(vehicleNetId)

    if vehicle == 0 then
        return sendStoreFailed(src, vehicleNetId, 'Không tìm thấy phương tiện cần cất.')
    end

    if storedRedZoneVehicles[vehicleNetId] then
        return sendStoreFailed(src, vehicleNetId, 'Phương tiện này đã được cất.')
    end

    if trackedRedZoneDrivers[vehicleNetId] ~= src then
        return sendStoreFailed(src, vehicleNetId, 'Bạn không phải tài xế của phương tiện này.')
    end

    if not isInsideIslandRedZone(GetEntityCoords(vehicle)) then
        return sendStoreFailed(src, vehicleNetId, 'Phương tiện đã ra ngoài vùng đỏ.')
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= 0 then
        return sendStoreFailed(src, vehicleNetId, 'Phương tiện vẫn còn tài xế.')
    end

    local playerPed = GetPlayerPed(src)
    local playerBucket = GetPlayerRoutingBucket(src)
    local vehicleBucket = GetEntityRoutingBucket(vehicle)
    if playerPed == 0 or not DoesEntityExist(playerPed) or vehicleBucket ~= playerBucket then
        return sendStoreFailed(src, vehicleNetId, 'Không thể xác định bucket của phương tiện.')
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    if #(GetEntityCoords(playerPed) - vehicleCoords) > 15.0 then
        return sendStoreFailed(src, vehicleNetId, 'Bạn đang ở quá xa phương tiện.')
    end

    local prop = spawnStorageProp(vehicleCoords, GetEntityHeading(vehicle), vehicleBucket)
    if prop == 0 then
        return sendStoreFailed(src, vehicleNetId, 'Không thể tạo prop thay thế phương tiện.')
    end

    local propNetId = NetworkGetNetworkIdFromEntity(prop)
    if not propNetId or propNetId == 0 then
        DeleteEntity(prop)
        return sendStoreFailed(src, vehicleNetId, 'Không thể đồng bộ prop thay thế.')
    end

    exports.qbx_core:SetEntityBucket(vehicle, vehicleStorage.bucket or 999)
    if GetEntityRoutingBucket(vehicle) ~= (vehicleStorage.bucket or 999) then
        DeleteEntity(prop)
        return sendStoreFailed(src, vehicleNetId, 'Không thể chuyển phương tiện vào bucket lưu trữ.')
    end

    storedRedZoneVehicles[vehicleNetId] = {
        owner = src,
        vehicleNetId = vehicleNetId,
        propNetId = propNetId,
        originalBucket = vehicleBucket,
        coords = vehicleCoords,
        heading = GetEntityHeading(vehicle)
    }
    trackedRedZoneDrivers[vehicleNetId] = nil

    TriggerClientEvent('neons_ddame:client:redZoneVehicleStored', src, vehicleNetId, propNetId)
end)

RegisterNetEvent('neons_ddame:server:retrieveRedZoneVehicle', function(vehicleNetId, propNetId)
    if not vehicleStorage.enabled then return end

    local src = source
    vehicleNetId = tonumber(vehicleNetId)
    propNetId = tonumber(propNetId)
    local storedVehicle = vehicleNetId and storedRedZoneVehicles[vehicleNetId]

    if not storedVehicle or storedVehicle.owner ~= src or storedVehicle.propNetId ~= propNetId then
        return TriggerClientEvent(
            'neons_ddame:client:redZoneVehicleRetrieveResult',
            src,
            false,
            vehicleNetId,
            propNetId,
            'Bạn không có quyền lấy phương tiện này.'
        )
    end

    local vehicle = getNetworkVehicle(vehicleNetId)
    local prop = propNetId and NetworkGetEntityFromNetworkId(propNetId) or 0
    local playerPed = GetPlayerPed(src)
    local playerBucket = GetPlayerRoutingBucket(src)

    if vehicle == 0 or prop == 0 or not DoesEntityExist(prop) or playerPed == 0 or not DoesEntityExist(playerPed) then
        return TriggerClientEvent(
            'neons_ddame:client:redZoneVehicleRetrieveResult',
            src,
            false,
            vehicleNetId,
            propNetId,
            'Phương tiện hoặc prop không còn tồn tại.'
        )
    end

    if GetEntityRoutingBucket(vehicle) ~= (vehicleStorage.bucket or 999) then
        return TriggerClientEvent(
            'neons_ddame:client:redZoneVehicleRetrieveResult',
            src,
            false,
            vehicleNetId,
            propNetId,
            'Phương tiện không còn trong bucket lưu trữ.'
        )
    end

    if GetEntityRoutingBucket(prop) ~= playerBucket then
        return TriggerClientEvent(
            'neons_ddame:client:redZoneVehicleRetrieveResult',
            src,
            false,
            vehicleNetId,
            propNetId,
            'Prop không nằm trong bucket hiện tại của bạn.'
        )
    end

    local playerCoords = GetEntityCoords(playerPed)
    local propCoords = GetEntityCoords(prop)
    if #(playerCoords - propCoords) > ((vehicleStorage.interactionDistance or 3.0) + 1.5) then
        return TriggerClientEvent(
            'neons_ddame:client:redZoneVehicleRetrieveResult',
            src,
            false,
            vehicleNetId,
            propNetId,
            'Bạn đang ở quá xa prop phương tiện.'
        )
    end

    exports.qbx_core:SetEntityBucket(vehicle, playerBucket)
    if GetEntityRoutingBucket(vehicle) ~= playerBucket then
        return TriggerClientEvent(
            'neons_ddame:client:redZoneVehicleRetrieveResult',
            src,
            false,
            vehicleNetId,
            propNetId,
            'Không thể đưa phương tiện về bucket hiện tại.'
        )
    end

    DeleteEntity(prop)
    storedRedZoneVehicles[vehicleNetId] = nil

    TriggerClientEvent(
        'neons_ddame:client:redZoneVehicleRetrieveResult',
        src,
        true,
        vehicleNetId,
        propNetId
    )
end)

local function cleanupStoredVehiclesForPlayer(src)
    for vehicleNetId, storedVehicle in pairs(storedRedZoneVehicles) do
        if storedVehicle.owner == src then
            cleanupStoredVehicle(vehicleNetId, true)
        end
    end

    for vehicleNetId, driverSource in pairs(trackedRedZoneDrivers) do
        if driverSource == src then
            trackedRedZoneDrivers[vehicleNetId] = nil
        end
    end
end

AddEventHandler('playerDropped', function()
    cleanupStoredVehiclesForPlayer(source)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for vehicleNetId in pairs(storedRedZoneVehicles) do
        cleanupStoredVehicle(vehicleNetId, true)
    end

    trackedRedZoneDrivers = {}
end)
