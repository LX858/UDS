QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

RegisterNetEvent('qbx_core:client:playerDataUpdated', function(key, value)
    PlayerData[key] = value
end)

RegisterNetEvent('qbx_core:client:metadataUpdated', function(key, value)
    PlayerData.metadata = PlayerData.metadata or {}
    PlayerData.metadata[key] = value
end)

RegisterNetEvent('qbx_core:client:moneyUpdated', function(moneyType, balance)
    PlayerData.money = PlayerData.money or {}
    PlayerData.money[moneyType] = balance
end)
