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
local redZoneBlips = {}
local redZoneVehicleStates = {}
local localDrivenVehicles = {}
local storedVehicleProps = {}
local noCollisionRadius = 50.0
local storageInteractionBusy = false
local storageTextVisible = false

local function distanceSquared2D(first, second)
    local dx = first.x - second.x
    local dy = first.y - second.y
    return (dx * dx) + (dy * dy)
end

local function isInsideIslandRedZone(coords)
    local zones = getRedZones()
    for _, zone in ipairs(zones) do
        if zone.coords and zone.radius then
            if distanceSquared2D(coords, zone.coords) <= (zone.radius * zone.radius) then
                return true, zone
            end
        end
    end
    return false
end

local function applyRedZoneVehicleState(vehicle)
    if not redZoneVehicleStates[vehicle] then
        redZoneVehicleStates[vehicle] = {
            alpha = GetEntityAlpha(vehicle),
            noCollisionEntities = {}
        }
    end

    SetEntityAlpha(vehicle, 50, false)
end

local function setNoCollisionPair(firstEntity, secondEntity, enabled)
    SetEntityNoCollisionEntity(firstEntity, secondEntity, enabled)
    SetEntityNoCollisionEntity(secondEntity, firstEntity, enabled)
end

local function updateNearbyNoCollision(vehicle, vehiclePool, pedPool)
    local state = redZoneVehicleStates[vehicle]
    if not state then return end

    local vehicleCoords = GetEntityCoords(vehicle)
    local nearbyEntities = {}

    for _, otherVehicle in ipairs(vehiclePool) do
        if otherVehicle ~= vehicle and DoesEntityExist(otherVehicle)
            and #(GetEntityCoords(otherVehicle) - vehicleCoords) <= noCollisionRadius then
            nearbyEntities[otherVehicle] = true
        end
    end

    for _, ped in ipairs(pedPool) do
        if DoesEntityExist(ped) and GetVehiclePedIsIn(ped, false) ~= vehicle
            and #(GetEntityCoords(ped) - vehicleCoords) <= noCollisionRadius then
            nearbyEntities[ped] = true
        end
    end

    for entity in pairs(state.noCollisionEntities) do
        if not nearbyEntities[entity] then
            if DoesEntityExist(entity) then
                setNoCollisionPair(vehicle, entity, false)
            end
            state.noCollisionEntities[entity] = nil
        end
    end

    for entity in pairs(nearbyEntities) do
        setNoCollisionPair(vehicle, entity, true)
        state.noCollisionEntities[entity] = true
    end
end

local function restoreVehicleState(vehicle)
    local state = redZoneVehicleStates[vehicle]
    if not state then return end

    if DoesEntityExist(vehicle) then
        SetEntityAlpha(vehicle, state.alpha, false)

        for entity in pairs(state.noCollisionEntities) do
            if DoesEntityExist(entity) then
                setNoCollisionPair(vehicle, entity, false)
            end
        end
    end

    redZoneVehicleStates[vehicle] = nil
end

local function restoreAllVehicleStates()
    for vehicle in pairs(redZoneVehicleStates) do
        restoreVehicleState(vehicle)
    end
end

local function enforceRedZoneVehicleCollision()
    local vehiclePool = GetGamePool('CVehicle')
    local pedPool = GetGamePool('CPed')

    for vehicle in pairs(redZoneVehicleStates) do
        if DoesEntityExist(vehicle)
            and isInsideIslandRedZone(GetEntityCoords(vehicle))
            and GetPedInVehicleSeat(vehicle, -1) ~= 0 then
            updateNearbyNoCollision(vehicle, vehiclePool, pedPool)
        else
            restoreVehicleState(vehicle)
        end
    end
end

local function setStorageTextVisible(visible)
    if visible and not storageTextVisible then
        lib.showTextUI('[E] Lấy phương tiện')
        storageTextVisible = true
    elseif not visible and storageTextVisible then
        lib.hideTextUI()
        storageTextVisible = false
    end
end

local function canRetrieveStoredVehicle()
    local ped = PlayerPedId()
    local state = LocalPlayer.state

    if IsEntityDead(ped) or IsPedFatallyInjured(ped) or IsPedInAnyVehicle(ped, false) then
        return false
    end

    return not state.isDead
        and not state.dead
        and not state.isLaststand
        and not state.laststand
        and not state.inLaststand
end

local function getClosestStoredProp(playerCoords)
    local closestProp
    local closestDistance
    local interactionDistance = vehicleStorage.interactionDistance or 3.0

    for propNetId, storedProp in pairs(storedVehicleProps) do
        local prop = NetworkGetEntityFromNetworkId(propNetId)
        if DoesEntityExist(prop) then
            local distance = #(GetEntityCoords(prop) - playerCoords)
            if distance <= interactionDistance and (not closestDistance or distance < closestDistance) then
                closestProp = {
                    propNetId = propNetId,
                    vehicleNetId = storedProp.vehicleNetId,
                    entity = prop
                }
                closestDistance = distance
            end
        else
            storedVehicleProps[propNetId] = nil
        end
    end

    return closestProp
end

local function removeIslandRedZoneBlips()
    for _, blip in ipairs(redZoneBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    redZoneBlips = {}
end

local function isBlipEnabled(blipConfig)
    if blipConfig == nil then return false end
    if type(blipConfig) == 'boolean' then
        return blipConfig
    end
    if type(blipConfig) == 'table' then
        if blipConfig.enabled ~= nil then
            return blipConfig.enabled == true
        end
        return true
    end
    return false
end

local function createIslandRedZoneBlips()
    removeIslandRedZoneBlips()

    local zones = getRedZones()
    for _, zone in ipairs(zones) do
        if zone.coords and zone.radius then
            local blipConfig = zone.blip
            if isBlipEnabled(blipConfig) then
                local coords = zone.coords
                local radius = zone.radius

                local color = 1
                local alpha = 125
                local display = 4

                if type(blipConfig) == 'table' then
                    if blipConfig.color ~= nil then color = blipConfig.color end
                    if blipConfig.alpha ~= nil then alpha = blipConfig.alpha end
                    if blipConfig.display ~= nil then display = blipConfig.display end
                end

                local radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, radius + 0.0)
                SetBlipColour(radiusBlip, color)
                SetBlipAlpha(radiusBlip, alpha)
                SetBlipDisplay(radiusBlip, display)
                redZoneBlips[#redZoneBlips + 1] = radiusBlip

                if type(blipConfig) == 'table' and (blipConfig.sprite or blipConfig.name or blipConfig.showCenterBlip) then
                    local centerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
                    SetBlipSprite(centerBlip, blipConfig.sprite or 161)
                    SetBlipColour(centerBlip, blipConfig.color or color)
                    SetBlipScale(centerBlip, blipConfig.scale or 0.8)
                    SetBlipAsShortRange(centerBlip, true)
                    SetBlipDisplay(centerBlip, blipConfig.display or display)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentSubstringPlayerName(blipConfig.name or zone.name or 'RedZone')
                    EndTextCommandSetBlipName(centerBlip)
                    redZoneBlips[#redZoneBlips + 1] = centerBlip
                end
            end
        end
    end
end

RegisterNetEvent('neons_ddame:client:redZoneVehicleStored', function(vehicleNetId, propNetId)
    vehicleNetId = tonumber(vehicleNetId)
    propNetId = tonumber(propNetId)
    if not vehicleNetId or not propNetId then return end

    local drivenVehicle = localDrivenVehicles[vehicleNetId]
    if drivenVehicle then
        restoreVehicleState(drivenVehicle.entity)
        localDrivenVehicles[vehicleNetId] = nil
    end

    storedVehicleProps[propNetId] = {
        vehicleNetId = vehicleNetId
    }
end)

RegisterNetEvent('neons_ddame:client:redZoneVehicleStoreFailed', function(vehicleNetId, reason)
    vehicleNetId = tonumber(vehicleNetId)
    if vehicleNetId then
        localDrivenVehicles[vehicleNetId] = nil
    end

    if reason then
        lib.notify({
            title = 'Phương tiện',
            description = reason,
            type = 'error'
        })
    end
end)

RegisterNetEvent('neons_ddame:client:redZoneVehicleRetrieveResult', function(success, vehicleNetId, propNetId, reason)
    storageInteractionBusy = false

    if not success then
        lib.notify({
            title = 'Phương tiện',
            description = reason or 'Không thể lấy phương tiện lúc này.',
            type = 'error'
        })
        return
    end

    vehicleNetId = tonumber(vehicleNetId)
    propNetId = tonumber(propNetId)
    if propNetId then
        storedVehicleProps[propNetId] = nil
    end

    if not vehicleNetId then return end

    CreateThread(function()
        local timeoutAt = GetGameTimer() + 5000
        local vehicle

        repeat
            vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
            if DoesEntityExist(vehicle) then break end
            Wait(100)
        until GetGameTimer() >= timeoutAt

        if not vehicle or not DoesEntityExist(vehicle) then
            lib.notify({
                title = 'Phương tiện',
                description = 'Không thể đồng bộ phương tiện trở lại.',
                type = 'error'
            })
            return
        end

        local ped = PlayerPedId()
        SetPedIntoVehicle(ped, vehicle, -1)
        if not IsPedInVehicle(ped, vehicle, false) then
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
        end
    end)
end)

CreateThread(function()
    createIslandRedZoneBlips()
end)

local inIsland = false
exports('inIsland', function()
    return inIsland
end)
exports('inRedZone', function()
    return inIsland
end)
exports('refreshRedZoneBlips', createIslandRedZoneBlips)

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local zones = getRedZones()

        local inActivationZone = false
        local scanInterval = 250

        for _, zone in ipairs(zones) do
            if zone.coords and zone.radius then
                local radius = zone.radius
                local activationRadius = radius + (zone.activationPadding or 300.0)
                if distanceSquared2D(playerCoords, zone.coords) <= (activationRadius * activationRadius) then
                    inActivationZone = true
                    if zone.scanInterval and zone.scanInterval < scanInterval then
                        scanInterval = zone.scanInterval
                    end
                end
            end
        end

        if inActivationZone then
            local vehiclesInRedZone = {}
            local locallyDrivenThisScan = {}
            inIsland = true

            for _, vehicle in ipairs(GetGamePool('CVehicle')) do
                if DoesEntityExist(vehicle) and isInsideIslandRedZone(GetEntityCoords(vehicle)) then
                    local driver = GetPedInVehicleSeat(vehicle, -1)

                    if driver ~= 0 then
                        vehiclesInRedZone[vehicle] = true
                        applyRedZoneVehicleState(vehicle)

                        if driver == playerPed and NetworkGetEntityIsNetworked(vehicle) then
                            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
                            if vehicleNetId and vehicleNetId ~= 0 then
                                locallyDrivenThisScan[vehicleNetId] = vehicle

                                local trackedVehicle = localDrivenVehicles[vehicleNetId]
                                if not trackedVehicle then
                                    trackedVehicle = {
                                        entity = vehicle,
                                        pendingStore = false,
                                        lastTrackAt = 0
                                    }
                                    localDrivenVehicles[vehicleNetId] = trackedVehicle
                                end

                                if GetGameTimer() - trackedVehicle.lastTrackAt >= 1000 then
                                    trackedVehicle.lastTrackAt = GetGameTimer()
                                    TriggerServerEvent('neons_ddame:server:trackRedZoneVehicle', vehicleNetId)
                                end
                            end
                        end
                    end
                end
            end

            for vehicleNetId, trackedVehicle in pairs(localDrivenVehicles) do
                if not locallyDrivenThisScan[vehicleNetId] and not trackedVehicle.pendingStore then
                    local vehicle = trackedVehicle.entity
                    local driver = DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) or 0

                    if DoesEntityExist(vehicle) and isInsideIslandRedZone(GetEntityCoords(vehicle)) and driver == 0 then
                        trackedVehicle.pendingStore = true
                        TriggerServerEvent('neons_ddame:server:storeRedZoneVehicle', vehicleNetId)
                    else
                        localDrivenVehicles[vehicleNetId] = nil
                    end
                end
            end

            for vehicle in pairs(redZoneVehicleStates) do
                if not vehiclesInRedZone[vehicle] then
                    restoreVehicleState(vehicle)
                end
            end

            Wait(scanInterval)
        else
            inIsland = false
            for vehicleNetId in pairs(localDrivenVehicles) do
                localDrivenVehicles[vehicleNetId] = nil
            end
            restoreAllVehicleStates()
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if next(redZoneVehicleStates) then
            -- Phai duy tri SetEntityNoCollisionEntity moi frame.
            enforceRedZoneVehicleCollision()
            Wait(0)
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    if not vehicleStorage.enabled then return end

    while true do
        local wait = 500
        local closestProp

        if canRetrieveStoredVehicle() then
            closestProp = getClosestStoredProp(GetEntityCoords(PlayerPedId()))
        end

        if closestProp and not storageInteractionBusy then
            wait = 0
            setStorageTextVisible(true)

            if IsControlJustReleased(0, 38) then
                storageInteractionBusy = true
                setStorageTextVisible(false)

                local progressSuccess = lib.progressBar({
                    duration = vehicleStorage.retrieveDuration or 5000,
                    label = 'Đang lấy phương tiện...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        move = true,
                        car = true,
                        combat = true,
                        mouse = false
                    }
                })

                if progressSuccess then
                    TriggerServerEvent(
                        'neons_ddame:server:retrieveRedZoneVehicle',
                        closestProp.vehicleNetId,
                        closestProp.propNetId
                    )
                else
                    storageInteractionBusy = false
                end
            end
        else
            setStorageTextVisible(false)
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    setStorageTextVisible(false)

    removeIslandRedZoneBlips()

    restoreAllVehicleStates()
end)
