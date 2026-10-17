--- Resource Local Cache for qbx_ambulancejob (following QBX Cache Optimization Rules)
PlayerCache = {
    loaded = false,
    data = {},
    citizenid = nil,
    charinfo = {},
    job = {
        name = nil,
        label = nil,
        type = nil,
        onduty = false,
        grade = {}
    },
    gang = {
        name = nil,
        label = nil,
        grade = {}
    }
}

---Clears the local player cache upon player unload
function ClearPlayerCache()
    PlayerCache.loaded = false
    PlayerCache.data = {}
    PlayerCache.citizenid = nil
    PlayerCache.charinfo = {}
    PlayerCache.job = {
        name = nil,
        label = nil,
        type = nil,
        onduty = false,
        grade = {}
    }
    PlayerCache.gang = {
        name = nil,
        label = nil,
        grade = {}
    }
end

---Refreshes the local player cache from qbx_core
function RefreshPlayerCache()
    local data = exports.qbx_core:GetPlayerData()
    if not data or not next(data) then
        ClearPlayerCache()
        return
    end

    PlayerCache.data = data
    PlayerCache.citizenid = data.citizenid
    PlayerCache.charinfo = data.charinfo or {}
    PlayerCache.job = data.job or {}
    PlayerCache.gang = data.gang or {}
    PlayerCache.loaded = true
end

---Check if player is an EMS member
---@return boolean
function IsEms()
    return PlayerCache.loaded and PlayerCache.job and PlayerCache.job.type == 'ems'
end

---Check if player is currently on duty
---@return boolean
function IsOnDuty()
    return PlayerCache.loaded and PlayerCache.job and PlayerCache.job.onduty == true
end

---Check if player has ambulance job name
---@return boolean
function IsAmbulance()
    return PlayerCache.loaded and PlayerCache.job and PlayerCache.job.name == 'ambulance'
end

---Get player job grade level safely
---@return number
function GetJobGradeLevel()
    if PlayerCache.loaded and PlayerCache.job and PlayerCache.job.grade and PlayerCache.job.grade.level then
        return PlayerCache.job.grade.level
    end
    return 0
end

---Get player character info safely
---@return table
function GetPlayerCharInfo()
    return PlayerCache.charinfo or {}
end

---Get player metadata safely
---@param key string
---@return any
function GetPlayerMeta(key)
    if PlayerCache.loaded and PlayerCache.data and PlayerCache.data.metadata then
        return PlayerCache.data.metadata[key]
    end
    return nil
end

-- ============================================================
-- Event-Driven Cache Synchronization
-- ============================================================

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

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if PlayerCache.job then
        PlayerCache.job.onduty = duty
    end
    if PlayerCache.data and PlayerCache.data.job then
        PlayerCache.data.job.onduty = duty
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    if val and next(val) then
        PlayerCache.data = val
        PlayerCache.citizenid = val.citizenid
        PlayerCache.charinfo = val.charinfo or {}
        PlayerCache.job = val.job or {}
        PlayerCache.gang = val.gang or {}
        PlayerCache.loaded = true
    end
end)

RegisterNetEvent('qbx_core:client:playerDataUpdated', function(key, value)
    if type(key) ~= 'string' then return end
    PlayerCache.data[key] = value
    if key == 'job' then PlayerCache.job = value or {} end
    if key == 'gang' then PlayerCache.gang = value or {} end
    if key == 'charinfo' then PlayerCache.charinfo = value or {} end
    if key == 'citizenid' then PlayerCache.citizenid = value end
end)

RegisterNetEvent('qbx_core:client:metadataUpdated', function(key, value)
    if type(key) ~= 'string' then return end
    PlayerCache.data.metadata = PlayerCache.data.metadata or {}
    PlayerCache.data.metadata[key] = value
end)

RegisterNetEvent('qbx_core:client:moneyUpdated', function(moneyType, balance)
    if type(moneyType) ~= 'string' then return end
    PlayerCache.data.money = PlayerCache.data.money or {}
    PlayerCache.data.money[moneyType] = balance
end)

AddEventHandler('ox_inventory:updateInventory', function()
    if not PlayerCache.loaded or GetResourceState('ox_inventory') ~= 'started' then return end
    PlayerCache.data.items = exports.ox_inventory:GetPlayerItems()
end)

-- Handle resource restart when player is already logged in
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    RefreshPlayerCache()
end)
