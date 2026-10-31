Framework = Framework or {}
Framework.Name  = nil
Framework.Core  = nil
Framework.Ready = false

local isServer = IsDuplicityVersion()

local function isStarted(resource)
    return GetResourceState(resource) == "started"
end

-- Framework detection ------------------------------------------------------

local function detectQbox()
    if not isStarted("qbx_core") then return false end

    local core
    pcall(function() core = exports.qbx_core end)
    if not core then return false end

    Framework.Core, Framework.Name = core, "qbox"
    return true
end

local function detectQBCore()
    if not isStarted("qb-core") then return false end

    local core
    pcall(function() core = exports["qb-core"]:GetCoreObject() end)
    if not core then return false end

    Framework.Core, Framework.Name = core, "qbcore"
    return true
end

local function detectESX()
    if not isStarted("es_extended") then return false end

    local core
    pcall(function() core = exports.es_extended:getSharedObject() end)

    if not core then
        pcall(function()
            TriggerEvent("esx:getSharedObject", function(obj) core = obj end)
        end)
    end
    if not core then return false end

    Framework.Core, Framework.Name = core, "esx"
    return true
end

local function detectFramework()
    local wanted = (Config and Config.Framework) or "auto"

    if wanted == "esx" then return detectESX() end
    if wanted == "qbcore" then return detectQBCore() end
    if wanted == "qbox" then return detectQbox() end

    return detectQbox() or detectQBCore() or detectESX()
end

CreateThread(function()
    local tries = 0

    while not Framework.Ready and tries < 80 do
        if detectFramework() then
            Framework.Ready = true
            if Config and Config.Debug then
                print(("[oxlyn-helicam] Framework detected: %s"):format(Framework.Name))
            end
            break
        end
        tries = tries + 1
        Wait(250)
    end

    if not Framework.Ready and Config and Config.Debug then
        print("[oxlyn-helicam] No framework detected — running framework-agnostic.")
    end
end)

-- Data normalizers ---------------------------------------------------------

local function normalizeEsxJob(job)
    if not job then return nil end

    local onDuty = job.onDuty
    if onDuty == nil then onDuty = true end

    return {
        name       = job.name,
        grade      = tonumber(job.grade) or 0,
        label      = job.label,
        gradeLabel = job.grade_label,
        onDuty     = onDuty,
    }
end

local function normalizeQbJob(job)
    if not job then return nil end

    local grade = job.grade
    local level = (grade and (grade.level or grade)) or 0

    local onDuty = job.onduty
    if onDuty == nil then onDuty = true end

    return {
        name       = job.name,
        grade      = tonumber(level) or 0,
        label      = job.label,
        gradeLabel = grade and grade.name or nil,
        onDuty     = onDuty,
    }
end

local function normalizeGang(gang)
    if not gang then return nil end

    local grade = gang.grade
    local level = (grade and (grade.level or grade)) or 0

    return {
        name  = gang.name,
        grade = tonumber(level) or 0,
        label = gang.label,
    }
end

local function contains(list, value)
    if not list or not value then return false end
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

-- Server -------------------------------------------------------------------

if isServer then

    function Framework.GetPlayer(src)
        if not Framework.Core then return nil end

        if Framework.Name == "esx" then
            return Framework.Core.GetPlayerFromId(src)
        elseif Framework.Name == "qbox" then
            return Framework.Core:GetPlayer(src)
        elseif Framework.Name == "qbcore" then
            return Framework.Core.Functions.GetPlayer(src)
        end

        return nil
    end

    function Framework.GetJob(src)
        local player = Framework.GetPlayer(src)
        if not player then return nil end

        if Framework.Name == "esx" then
            local job = player.getJob and player.getJob() or player.job
            return normalizeEsxJob(job)
        end

        return normalizeQbJob(player.PlayerData and player.PlayerData.job)
    end

    function Framework.GetGang(src)
        local player = Framework.GetPlayer(src)
        if not player then return nil end
        if Framework.Name == "esx" then return nil end

        return normalizeGang(player.PlayerData and player.PlayerData.gang)
    end

    function Framework.GetIdentifier(src)
        local player = Framework.GetPlayer(src)
        if not player then return nil end

        if Framework.Name == "esx" then
            return (player.getIdentifier and player.getIdentifier()) or player.identifier
        end

        return player.PlayerData and player.PlayerData.citizenid
    end

    function Framework.GetName(src)
        local player = Framework.GetPlayer(src)
        if not player then return GetPlayerName(src) end

        if Framework.Name == "esx" then
            return (player.getName and player.getName())
                or player.name
                or GetPlayerName(src)
        end

        local info = player.PlayerData and player.PlayerData.charinfo
        if info then
            return ("%s %s"):format(info.firstname or "", info.lastname or "")
        end

        return GetPlayerName(src)
    end

    function Framework.HasAce(src, ace)
        return IsPlayerAceAllowed(src, ace)
    end

    function Framework.HasAccess(src, access)
        access = access or (Config and Config.Access) or {}

        if access.everyone == true then return true end

        local job = Framework.GetJob(src)
        if job and contains(access.jobs, job.name) then return true end

        local gang = Framework.GetGang(src)
        if gang and contains(access.gangs, gang.name) then return true end

        if access.aces then
            for _, ace in ipairs(access.aces) do
                if Framework.HasAce(src, ace) then return true end
            end
        end

        return false
    end

    function Framework.HasItem(src, item, count)
        count = count or 1

        if Inventory and Inventory.HasItem then
            local ok, result = pcall(Inventory.HasItem, src, item, count)
            if ok then return result end
        end

        if isStarted("ak47_inventory") then
            local ok, amount = pcall(function()
                return exports.ak47_inventory:GetItemCount(src, item)
            end)
            if ok and amount ~= nil then
                return count <= (tonumber(amount) or 0)
            end

            ok, amount = pcall(function()
                return exports.ak47_inventory:GetAmount(src, item)
            end)
            if ok and amount ~= nil then
                return count <= (tonumber(amount) or 0)
            end
        end

        if isStarted("ox_inventory") then
            local ok, amount = pcall(function()
                return exports.ox_inventory:GetItemCount(src, item)
            end)
            if ok then
                return count <= (tonumber(amount) or 0)
            end
        end

        return false
    end

    -- Server callbacks
    local callbacks = {}

    function Framework.RegisterCallback(name, handler)
        callbacks[name] = handler
    end

    RegisterNetEvent("oxlyn-helicam:cb:request", function(name, requestId, args)
        local src = source
        local handler = callbacks[name]

        local function respond(...)
            TriggerClientEvent("oxlyn-helicam:cb:response", src, requestId, { ... })
        end

        if not handler then
            return respond(nil)
        end

        handler(src, respond, table.unpack(args or {}))
    end)

-- Client -------------------------------------------------------------------

else

    local jobData  = nil
    local gangData = nil

    local function getPlayerData()
        if not Framework.Core then return nil end

        if Framework.Name == "esx" then
            if Framework.Core.GetPlayerData then
                return Framework.Core.GetPlayerData()
            end
            return nil
        elseif Framework.Name == "qbox" then
            local data
            pcall(function() data = Framework.Core:GetPlayerData() end)
            return data
        elseif Framework.Name == "qbcore" then
            return Framework.Core.Functions.GetPlayerData()
        end

        return nil
    end

    local function refreshPlayerData()
        local data = getPlayerData()
        if not data then return end

        if Framework.Name == "esx" then
            jobData = normalizeEsxJob(data.job)
        else
            jobData  = normalizeQbJob(data.job)
            gangData = normalizeGang(data.gang)
        end
    end

    function Framework.GetJob()
        if not jobData then refreshPlayerData() end
        return jobData
    end

    function Framework.GetGang()
        if not gangData then refreshPlayerData() end
        return gangData
    end

    function Framework.IsOnDuty()
        local job = Framework.GetJob()
        return job ~= nil and job.onDuty == true
    end

    function Framework.HasAccess(access)
        access = access or (Config and Config.Access) or {}

        if access.everyone == true then return true end

        local job = Framework.GetJob()
        if job and contains(access.jobs, job.name) then return true end

        local gang = Framework.GetGang()
        if gang and contains(access.gangs, gang.name) then return true end

        return false
    end

    CreateThread(function()
        while not Framework.Ready do Wait(100) end
        refreshPlayerData()
    end)

    -- ESX
    RegisterNetEvent("esx:playerLoaded", refreshPlayerData)
    RegisterNetEvent("esx:setJob", function(job)
        jobData = normalizeEsxJob(job)
    end)

    -- QBCore
    RegisterNetEvent("QBCore:Client:OnPlayerLoaded", refreshPlayerData)
    RegisterNetEvent("QBCore:Client:OnJobUpdate", function(job)
        jobData = normalizeQbJob(job)
    end)
    RegisterNetEvent("QBCore:Client:OnGangUpdate", function(gang)
        gangData = normalizeGang(gang)
    end)
    RegisterNetEvent("QBCore:Client:SetDuty", refreshPlayerData)

    -- Qbox
    RegisterNetEvent("qbx_core:client:onSetJob", refreshPlayerData)
    RegisterNetEvent("qbx_core:client:onSetGang", refreshPlayerData)

    -- Client callbacks
    local pending = {}
    local nextRequestId = 0

    function Framework.TriggerCallback(name, cb, ...)
        nextRequestId = nextRequestId + 1
        local requestId = nextRequestId

        pending[requestId] = cb
        TriggerServerEvent("oxlyn-helicam:cb:request", name, requestId, { ... })

        -- Timeout: resolve with nil if the server never answers
        SetTimeout(8000, function()
            if pending[requestId] then
                pending[requestId] = nil
                if cb then cb(nil) end
            end
        end)
    end

    RegisterNetEvent("oxlyn-helicam:cb:response", function(requestId, args)
        local cb = pending[requestId]
        if not cb then return end

        pending[requestId] = nil
        cb(table.unpack(args or {}))
    end)
end