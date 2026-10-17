local rentalPeds = {}
local rentalBlips = {}
local rentedBoats = {}
local rentalBusy = false

local function notify(description, notificationType)
    lib.notify({
        title = 'Thue thuyen',
        description = description,
        type = notificationType or 'inform'
    })
end

local function getBoatByModel(model)
    for _, boat in ipairs(Config.BoatRental.boats) do
        if boat.model == model then return boat end
    end
end

local function getAvailableSpawn(station)
    for index, spawn in ipairs(station.spawns) do
        if not IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, 4.0) then
            return index, spawn
        end
    end
end

local function spawnRentedBoat(station, model, modelHash, spawnIndex)
    local spawn = station.spawns[spawnIndex]

    local vehicle = CreateVehicle(modelHash, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    if not DoesEntityExist(vehicle) then
        notify('Khong the tao thuyen, vui long thu lai.', 'error')
        return
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetEntityHeading(vehicle, spawn.w)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)

    rentedBoats[#rentedBoats + 1] = vehicle

    while not DoesEntityExist(vehicle) do Wait(500) end

    local playerPed = PlayerPedId()
    SetPedIntoVehicle(playerPed, vehicle, -1)

    if not IsPedInVehicle(playerPed, vehicle, false) then
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    end

    notify(('Da thue %s voi gia $%d.'):format(getBoatByModel(model).label, Config.BoatRental.price), 'success')
end

local function rentBoat(stationId, model)
    if rentalBusy then return end

    local station = Config.BoatRental.stations[stationId]
    local boat = getBoatByModel(model)
    if not station or not boat then return end

    local spawnIndex = getAvailableSpawn(station)
    if not spawnIndex then
        notify('Tat ca vi tri ha thuyen dang co thuyen khac.', 'error')
        return
    end

    local modelHash = joaat(model)
    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        notify(('Khong tim thay model thuyen %s.'):format(model), 'error')
        return
    end

    if not lib.requestModel(modelHash, 10000) then
        notify('Khong the tai model thuyen, vui long thu lai.', 'error')
        return
    end

    rentalBusy = true
    local success, reason = lib.callback.await(
        'neons_ddame:server:rentBoat',
        false,
        stationId,
        model,
        spawnIndex
    )
    rentalBusy = false

    if not success then
        SetModelAsNoLongerNeeded(modelHash)
        notify(reason or 'Khong the thue thuyen luc nay.', 'error')
        return
    end

    spawnRentedBoat(station, model, modelHash, spawnIndex)
end

local function openBoatMenu(stationId)
    local menuId = ('neons_ddame_boat_rental_%s'):format(stationId)
    local options = {}

    for _, boat in ipairs(Config.BoatRental.boats) do
        local model = boat.model
        options[#options + 1] = {
            title = boat.label,
            description = ('%s | Gia thue: $%d'):format(boat.description, Config.BoatRental.price),
            icon = 'ship',
            onSelect = function()
                rentBoat(stationId, model)
            end
        }
    end

    lib.registerContext({
        id = menuId,
        title = 'Thue thuyen',
        options = options
    })
    lib.showContext(menuId)
end

local function createRentalPed(stationId, station)
    local modelHash = joaat(Config.BoatRental.npcModel)
    if not lib.requestModel(modelHash, 10000) then
        print(('[neons_ddame] Khong the tai NPC thue thuyen tai station %s'):format(stationId))
        return
    end

    local npc = station.npc
    local ped = CreatePed(4, modelHash, npc.x, npc.y, npc.z - 1.0, npc.w, false, true)
    SetModelAsNoLongerNeeded(modelHash)

    if not DoesEntityExist(ped) then return end

    SetEntityAsMissionEntity(ped, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    rentalPeds[#rentalPeds + 1] = ped
    exports.ox_target:addLocalEntity(ped, {
        {
            name = ('neons_ddame_rent_boat_%s'):format(stationId),
            icon = 'fa-solid fa-sailboat',
            label = 'Thue thuyen',
            distance = Config.BoatRental.interactionDistance,
            onSelect = function()
                openBoatMenu(stationId)
            end
        }
    })
end

local function createRentalBlip(station)
    local blipConfig = Config.BoatRental.blip or {}
    local npc = station.npc
    local blip = AddBlipForCoord(npc.x, npc.y, npc.z)

    SetBlipSprite(blip, blipConfig.sprite or 356)
    SetBlipColour(blip, blipConfig.color or 3)
    SetBlipScale(blip, blipConfig.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipConfig.name or 'Thue thuyen')
    EndTextCommandSetBlipName(blip)

    rentalBlips[#rentalBlips + 1] = blip
end

CreateThread(function()
    for stationId, station in ipairs(Config.BoatRental.stations) do
        createRentalBlip(station)
        createRentalPed(stationId, station)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, ped in ipairs(rentalPeds) do
        if DoesEntityExist(ped) then
            exports.ox_target:removeLocalEntity(ped)
            DeleteEntity(ped)
        end
    end

    for _, vehicle in ipairs(rentedBoats) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end

    for _, blip in ipairs(rentalBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)
