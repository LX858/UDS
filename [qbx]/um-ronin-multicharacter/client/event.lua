local defaultSpawnCoords = require 'config.main'.defaultSpawnCoords
local reqAndSetPlayer = require 'modules.client.utils'.reqAndSetPlayer

local function houseOrApartmentInside(citizenid)
    local PlayerData = GetPlayerData()
    local insideMeta = PlayerData?.metadata["inside"] or {}

    if GetResourceState('ps-housing') == 'started' then
        local result = lib.callback.await('ps-housing:cb:GetOwnedApartment', source, citizenid)
        if result then
            TriggerEvent("apartments:client:SetHomeBlip", result?.type)
        end
    end

    if insideMeta?.house ~= nil then
        local houseId = insideMeta.house
        TriggerEvent('qb-houses:client:LastLocationHouse', houseId)
    elseif insideMeta?.apartment?.apartmentType ~= nil or insideMeta?.apartment?.apartmentId ~= nil then
        local apartmentType = insideMeta.apartment.apartmentType
        local apartmentId = insideMeta.apartment.apartmentId
        TriggerEvent('qb-apartments:client:LastLocationHouse', apartmentType, apartmentId)
    elseif insideMeta?.propertyId or insideMeta?.property_id then
        TriggerServerEvent('ps-housing:server:enterProperty', tostring(insideMeta.propertyId))
    end
end

RegisterNetEvent('um-ronin-multicharacter:spawnLastLocation', function(data)
    if GetInvokingResource() then return end

    local ped = PlayerPedId()
    local coords = type(data.lastloc) == 'string' and json.decode(data.lastloc) or data.lastloc

    reqAndSetPlayer(coords, ped)

    houseOrApartmentInside(data?.citizenid)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)

    Wait(1000)
    DoScreenFadeIn(1000)
end)RegisterNetEvent('um-ronin-multicharacter:outsideSpawnForNewCharacter', function()
    if GetInvokingResource() then return end

    local ped = PlayerPedId()

    reqAndSetPlayer(defaultSpawnCoords, ped)

    Wait(1000)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    TriggerEvent('qb-weathersync:client:EnableSync')

    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)

    Wait(1000)

    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    DoScreenFadeIn(100)
end)
