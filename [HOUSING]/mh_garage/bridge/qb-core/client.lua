if not lib then return end

local QBCore = exports[Shared.framework]:GetCoreObject()
local PlayerData = {}

local SetPlayerInGarage = require 'client.garage'.SetPlayerInGarage
local DeleteVehicles = require 'client.garage'.DeleteVehicles
local CreateImpound = require 'client.impound'.CreatePoints
local DeleteImpound = require 'client.impound'.DeleteImpound

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerLoaded = true

    Wait(1000)
    CreateGarages()
    CreateImpound()

    if PlayerData.metadata and PlayerData.metadata.garage then
        SetPlayerInGarage(PlayerData.metadata.garage.garage, PlayerData.metadata.garage.floor, PlayerData.metadata.garage.inPreview)
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

RegisterNetEvent('qbx_core:client:playerDataUpdated', function(key, value)
    if type(key) == 'string' then PlayerData[key] = value end
end)

RegisterNetEvent('qbx_core:client:metadataUpdated', function(key, value)
    PlayerData.metadata = PlayerData.metadata or {}
    PlayerData.metadata[key] = value
end)


RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerLoaded = false
    ClearAll()
    DeleteVehicles()
    DeleteImpound()
end)


AddEventHandler('onResourceStart', function(resource)
    if cache.resource == resource then
        Wait(1000)
        PlayerData = QBCore.Functions.GetPlayerData()
        PlayerLoaded = true
        CreateGarages()
        CreateImpound()

        if PlayerData.metadata and PlayerData.metadata.garage then
            SetPlayerInGarage(PlayerData.metadata.garage.garage, PlayerData.metadata.garage.floor, PlayerData.metadata.garage.inPreview)
        end
    end
end)
