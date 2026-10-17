local config = require 'config.client'

PlayerCache = {
    loaded = false,
    data = {},
    citizenid = nil,
    job = {
        name = nil,
        label = nil,
        onduty = false,
        grade = {}
    },
    gang = {
        name = nil,
        label = nil,
        grade = {}
    },
    metadata = {}
}

function ClearPlayerCache()
    PlayerCache.loaded = false
    PlayerCache.data = {}
    PlayerCache.citizenid = nil
    PlayerCache.job = {
        name = nil,
        label = nil,
        onduty = false,
        grade = {}
    }
    PlayerCache.gang = {
        name = nil,
        label = nil,
        grade = {}
    }
    PlayerCache.metadata = {}
end

function RefreshPlayerCache()
    local data = (QBX and QBX.PlayerData and QBX.PlayerData.citizenid and QBX.PlayerData) or exports.qbx_core:GetPlayerData()
    if not data or not data.citizenid then
        ClearPlayerCache()
        return
    end

    PlayerCache.data = data
    PlayerCache.citizenid = data.citizenid
    PlayerCache.job = data.job or {}
    PlayerCache.gang = data.gang or {}
    PlayerCache.metadata = data.metadata or {}
    PlayerCache.loaded = true
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    RefreshPlayerCache()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ClearPlayerCache()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerCache.job = job or {}
    if PlayerCache.data then
        PlayerCache.data.job = job
    end
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerCache.gang = gang or {}
    if PlayerCache.data then
        PlayerCache.data.gang = gang
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if not val or type(val) ~= 'table' then return end
    PlayerCache.data = val
    PlayerCache.citizenid = val.citizenid or PlayerCache.citizenid
    PlayerCache.job = val.job or PlayerCache.job
    PlayerCache.gang = val.gang or PlayerCache.gang
    PlayerCache.metadata = val.metadata or PlayerCache.metadata
    PlayerCache.loaded = true
end)

-- Khởi tạo cache khi resource start trong lúc player đã login
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    RefreshPlayerCache()
end)

function GetPlayerCache()
    if not PlayerCache.loaded then
        RefreshPlayerCache()
    end
    return PlayerCache
end
