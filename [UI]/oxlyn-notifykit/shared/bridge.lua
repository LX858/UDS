

--------------------------------------------------------------------------------
-- Framework bridge (cleaned from decompiled output)
-- Supports: qbox, esx, qbcore, ox_core, ND_Core, standalone
--------------------------------------------------------------------------------

Bridge = {
    framework = nil,
    isServer = (IsDuplicityVersion and IsDuplicityVersion()) or false,
}

--------------------------------------------------------------------------------
-- Framework detection
--------------------------------------------------------------------------------

local function detectFramework()
    local configured = (Config and Config.Framework) or "auto"
    if configured ~= "auto" then
        return configured
    end

    -- { resource name, framework id }
    local candidates = {
        { "qbx_core",    "qbox"   },
        { "es_extended", "esx"    },
        { "qb-core",     "qbcore" },
        { "ox_core",     "oxcore" },
        { "ND_Core",     "ndcore" },
    }

    -- Prefer a resource that is actually started
    for _, c in ipairs(candidates) do
        if GetResourceState(c[1]) == "started" then
            return c[2]
        end
    end

    -- Otherwise accept anything that exists (starting/stopped/etc.)
    for _, c in ipairs(candidates) do
        if GetResourceState(c[1]) ~= "missing" then
            return c[2]
        end
    end

    return "standalone"
end

Bridge.framework = detectFramework()
local framework = Bridge.framework

--------------------------------------------------------------------------------
-- Core object getters (cached)
--------------------------------------------------------------------------------

local esxObject
local qbObject

local function getESX()
    if esxObject then return esxObject end

    if framework ~= "esx" or GetResourceState("es_extended") ~= "started" then
        return nil
    end

    local ok, obj = pcall(function()
        return exports.es_extended:getSharedObject()
    end)
    if ok and type(obj) == "table" then
        esxObject = obj
    end
    return esxObject
end

local function getQB()
    if qbObject then return qbObject end

    if framework == "qbcore" then
        if GetResourceState("qb-core") == "started" then
            local ok, obj = pcall(function()
                return exports["qb-core"]:GetCoreObject()
            end)
            if ok and type(obj) == "table" then
                qbObject = obj
            end
        end
    elseif framework == "qbox" then
        if GetResourceState("qbx_core") == "started" then
            local ok, obj = pcall(function()
                return exports.qbx_core:GetCoreObject()
            end)
            if ok and type(obj) == "table" then
                qbObject = obj
            end
        end
    end

    return qbObject
end

-- Returns QBCore.Functions (or nil)
local function getQBFunctions()
    local core = getQB()
    if type(core) ~= "table" then return nil end

    local ok, functions = pcall(function() return core.Functions end)
    if ok and type(functions) == "table" then
        return functions
    end
    return nil
end

Bridge.ESX = getESX
Bridge.QB  = getQB

--------------------------------------------------------------------------------
-- ox_core helpers
--------------------------------------------------------------------------------

local function getOxPlayer(src)
    if framework ~= "oxcore" or GetResourceState("ox_core") ~= "started" then
        return nil
    end

    local ok, player = pcall(function()
        return exports.ox_core:GetPlayer(src)
    end)
    if ok and type(player) == "table" and player.charId then
        return player
    end
    return nil
end

local function oxCallPlayer(src, method, arg)
    local ok, r1, r2 = pcall(function()
        return exports.ox_core:CallPlayer(src, method, arg)
    end)
    if ok then
        return r1, r2
    end
    return nil
end

local function oxGroupsByType(groupType)
    local ok, groups = pcall(function()
        return exports.ox_core:GetGroupsByType(groupType)
    end)
    if ok and type(groups) == "table" then
        return groups
    end
    return {}
end

-- Returns (groupName, grade) for the first of `groups` the player belongs to
local function oxGetGroupOfTypes(src, groups)
    if #groups == 0 then return nil end

    local result, extra = oxCallPlayer(src, "getGroup", groups)

    if type(result) == "table" then
        result, extra = result[1], result[2]
    end

    if type(result) == "string" then
        return result, tonumber(extra) or 0
    end
    return nil
end

--------------------------------------------------------------------------------
-- ND_Core helper
--------------------------------------------------------------------------------

local function getNDPlayer(src)
    if framework ~= "ndcore" or GetResourceState("ND_Core") ~= "started" then
        return nil
    end

    local ok, player = pcall(function()
        return exports.ND_Core:getPlayer(src)
    end)
    if ok and type(player) == "table" then
        return player
    end
    return nil
end

Bridge.OxPlayer = getOxPlayer
Bridge.NDPlayer = getNDPlayer

--------------------------------------------------------------------------------
-- Server-only: admin checks, names, jobs, gangs
--------------------------------------------------------------------------------

if Bridge.isServer then

    ----------------------------------------------------------------------------
    -- Admin config (defaults merged with Config.Admin)
    ----------------------------------------------------------------------------

    local adminDefaults = {
        methods      = { "ace", "group", "identifier" },
        ace          = "oxlyn.notifykit.admin",
        groups       = { "admin", "superadmin", "god" },
        identifiers  = {},
        allowConsole = true,
        debug        = false,
    }

    local function getAdminConfig()
        local userCfg = (type(Config.Admin) == "table" and Config.Admin) or {}

        local cfg = {}
        for k, v in pairs(adminDefaults) do cfg[k] = v end
        for k, v in pairs(userCfg) do
            if v ~= nil then cfg[k] = v end
        end

        if type(cfg.groups) ~= "table"      then cfg.groups = adminDefaults.groups   end
        if type(cfg.methods) ~= "table"     then cfg.methods = adminDefaults.methods end
        if type(cfg.identifiers) ~= "table" then cfg.identifiers = {}                end
        if type(cfg.ace) ~= "string" or cfg.ace == "" then
            cfg.ace = adminDefaults.ace
        end

        return cfg
    end

    Bridge.AdminConfig = getAdminConfig

    -- ACE prefixes tested for each configured admin group
    local GROUP_ACE_PREFIXES = { "group.", "qbcore.", "qbx.", "esx." }

    ----------------------------------------------------------------------------
    -- Permission group
    ----------------------------------------------------------------------------

    function Bridge.GetGroup(src)
        local groups = getAdminConfig().groups

        if framework == "esx" then
            local ok, group = pcall(function()
                local esx = getESX()
                local xPlayer = esx and esx.GetPlayerFromId(src)
                if xPlayer and xPlayer.getGroup then
                    return xPlayer.getGroup()
                end
                return nil
            end)
            if ok and type(group) == "string" then
                return group
            end

        elseif framework == "qbcore" then
            local functions = getQBFunctions()
            if functions and functions.HasPermission then
                for _, group in ipairs(groups) do
                    local ok, has = pcall(functions.HasPermission, src, group)
                    if ok and has then
                        return group
                    end
                end
            end

        elseif framework == "ndcore" then
            local ok, group = pcall(function()
                local player = getNDPlayer(src)
                local playerGroups = player and player.groups
                if type(playerGroups) ~= "table" then return nil end

                for _, g in ipairs(groups) do
                    if playerGroups[g] then
                        return g
                    end
                end
                return nil
            end)
            if ok and type(group) == "string" then
                return group
            end
        end

        return "user"
    end

    ----------------------------------------------------------------------------
    -- Admin evaluation
    ----------------------------------------------------------------------------

    function Bridge.EvaluateAdmin(src)
        local cfg = getAdminConfig()

        local result = {
            allowed = false,
            reason  = "none",
            sources = {},
        }

        -- Record one check; first successful one becomes the reason
        local function record(name, ok, why)
            result.sources[#result.sources + 1] = {
                name = name,
                ok   = (ok == true),
                why  = why,
            }
            if ok and not result.allowed then
                result.allowed = true
                result.reason  = name
            end
        end

        local enabled = {}
        for _, method in ipairs(cfg.methods or {}) do
            enabled[method] = true
        end

        src = tonumber(src) or 0

        -- Server console
        if src == 0 then
            record("console", cfg.allowConsole ~= false, "server console")
            return result
        end

        -- Custom hook: Config.Admin.check(src) -> boolean | nil
        if type(cfg.check) == "function" then
            local ok, value = pcall(cfg.check, src)
            if ok and type(value) == "boolean" then
                record("check", value, "Config.Admin.check returned " .. tostring(value))
                result.forced  = true
                result.allowed = value
                result.reason  = "check"
                return result
            end
            record("check", false,
                ok and "hook returned nil (fall through)"
                    or ("hook error: " .. tostring(value)))
        end

        -- ACE permission
        if enabled.ace then
            local allowed = (cfg.ace and IsPlayerAceAllowed(src, cfg.ace)) or false
            record("ace", allowed, tostring(cfg.ace))
        end

        -- Framework group / group ACEs
        if enabled.group then
            local allowedGroups = cfg.groups or {}

            local currentGroup = "user"
            local ok, group = pcall(Bridge.GetGroup, src)
            if ok and group then currentGroup = group end
            result.group = currentGroup

            local matched
            local aceTested = {}

            for _, allowedGroup in ipairs(allowedGroups) do
                if currentGroup == allowedGroup and not matched then
                    matched = 'framework group "' .. allowedGroup .. '"'
                end

                for _, prefix in ipairs(GROUP_ACE_PREFIXES) do
                    local ace = prefix .. allowedGroup
                    aceTested[#aceTested + 1] = ace

                    if not matched and IsPlayerAceAllowed(src, ace) then
                        matched = "ace " .. ace
                    end
                end
            end

            record("group", matched ~= nil, matched or (
                'framework group "' .. currentGroup .. '" not in {'
                .. table.concat(allowedGroups, ", ")
                .. "}; aces tested: "
                .. table.concat(aceTested, " ")
            ))
        end

        -- Identifiers
        local identifiers = GetPlayerIdentifiers(src) or {}

        for _, id in ipairs(identifiers) do
            if id:sub(1, 8) == "license:" then
                result.license = id
                break
            end
        end

        if enabled.identifier then
            local matchedId
            for _, playerId in ipairs(identifiers) do
                for _, allowedId in ipairs(cfg.identifiers or {}) do
                    if playerId == allowedId then
                        matchedId = playerId
                        break
                    end
                end
                if matchedId then break end
            end

            record("identifier", matchedId ~= nil, matchedId
                or (#(cfg.identifiers or {}) .. " configured, no match"))
        end

        return result
    end

    -- Returns (allowed, reason)
    function Bridge.IsAdmin(src)
        local ok, result = pcall(Bridge.EvaluateAdmin, src)
        if not ok then
            print(("^5[OXLYN-NOTIFYKIT]^3 admin check failed: %s^7"):format(tostring(result)))
            return false, "error"
        end

        if getAdminConfig().debug then
            print(("^5[OXLYN-NOTIFYKIT]^7 admin check %s → %s (%s)"):format(
                tostring(src),
                result.allowed and "ALLOW" or "DENY",
                result.reason
            ))
        end

        return result.allowed, result.reason
    end

    ----------------------------------------------------------------------------
    -- Player name
    ----------------------------------------------------------------------------

    local function charName(playerData)
        local info = playerData and playerData.charinfo
        if not info then return nil end
        return ("%s %s"):format(info.firstname or "", info.lastname or "")
    end

    function Bridge.GetName(src)
        local ok, name = pcall(function()
            if framework == "esx" then
                local esx = getESX()
                local xPlayer = esx and esx.GetPlayerFromId(src)
                if xPlayer and xPlayer.getName then
                    return xPlayer.getName()
                end

            elseif framework == "qbcore" then
                local functions = getQBFunctions()
                local player = functions and functions.GetPlayer and functions.GetPlayer(src)
                if player and player.PlayerData then
                    return charName(player.PlayerData)
                end

            elseif framework == "qbox" then
                local player = exports.qbx_core:GetPlayer(src)
                if player and player.PlayerData then
                    return charName(player.PlayerData)
                end

            elseif framework == "oxcore" then
                if getOxPlayer(src) then
                    local n = oxCallPlayer(src, "get", "name")
                    if type(n) == "string" then
                        return n
                    end
                end

            elseif framework == "ndcore" then
                local player = getNDPlayer(src)
                if player then
                    if type(player.fullname) == "string" then
                        return player.fullname
                    end
                    if player.firstname or player.lastname then
                        return ("%s %s"):format(player.firstname or "", player.lastname or "")
                    end
                end
            end

            return nil
        end)

        if ok and type(name) == "string" and name ~= " " then
            return name
        end

        return GetPlayerName(src) or ("#" .. tostring(src))
    end

    ----------------------------------------------------------------------------
    -- Job: returns (name, grade, onDuty)
    ----------------------------------------------------------------------------

    function Bridge.GetJob(src)
        local ok, name, grade, onDuty = pcall(function()
            if framework == "esx" then
                local esx = getESX()
                local xPlayer = esx and esx.GetPlayerFromId(src)
                local job
                if xPlayer then
                    job = (xPlayer.getJob and xPlayer.getJob()) or xPlayer.job
                end

                if type(job) == "table" then
                    local duty = job.onDuty
                    if duty == nil then duty = true end
                    return job.name, tonumber(job.grade) or 0, duty
                end

            elseif framework == "qbcore" then
                local functions = getQBFunctions()
                local player = functions and functions.GetPlayer and functions.GetPlayer(src)
                local job = player and player.PlayerData and player.PlayerData.job

                if type(job) == "table" then
                    local g = job.grade
                    if type(g) == "table" then g = g.level end
                    return job.name, tonumber(g) or 0, job.onduty ~= false
                end

            elseif framework == "qbox" then
                local player = exports.qbx_core:GetPlayer(src)
                local job = player and player.PlayerData and player.PlayerData.job

                if type(job) == "table" then
                    local g = job.grade
                    if type(g) == "table" then g = g.level end
                    return job.name, tonumber(g) or 0, job.onduty ~= false
                end

            elseif framework == "oxcore" then
                if not getOxPlayer(src) then return nil end

                local activeGroup = oxCallPlayer(src, "get", "activeGroup")
                local jobGroups = oxGroupsByType("job")

                if type(activeGroup) == "string" then
                    if #jobGroups == 0 or Utils.Contains(jobGroups, activeGroup) then
                        local g = tonumber(oxCallPlayer(src, "getGroup", activeGroup))
                        if g then
                            return activeGroup, g, true
                        end
                    end
                end

                local jobName, jobGrade = oxGetGroupOfTypes(src, jobGroups)
                if jobName then
                    return jobName, jobGrade, jobName == activeGroup
                end

            elseif framework == "ndcore" then
                local player = getNDPlayer(src)
                if not player then return nil end

                local job, jobInfo = player.job, player.jobInfo

                if type(job) ~= "string" and type(player.groups) == "table" then
                    for groupName, groupData in pairs(player.groups) do
                        if type(groupData) == "table" and groupData.isJob then
                            job, jobInfo = groupName, groupData
                            break
                        end
                    end
                end

                if type(job) == "string" then
                    local rank = type(jobInfo) == "table" and jobInfo.rank or nil
                    return job, tonumber(rank) or 0, true
                end
            end

            return nil
        end)

        if ok and type(name) == "string" then
            return name, grade, onDuty
        end
        return nil
    end

    ----------------------------------------------------------------------------
    -- Gang: returns (name, grade)
    ----------------------------------------------------------------------------

    function Bridge.GetGang(src)
        if framework == "oxcore" then
            local ok, name, grade = pcall(function()
                if not getOxPlayer(src) then return nil end
                return oxGetGroupOfTypes(src, oxGroupsByType("gang"))
            end)
            if ok and type(name) == "string" then
                return name, grade
            end
            return nil
        end

        if framework ~= "qbcore" and framework ~= "qbox" then
            return nil
        end

        local ok, name, grade = pcall(function()
            local player
            if framework == "qbox" then
                player = exports.qbx_core:GetPlayer(src)
            else
                local functions = getQBFunctions()
                player = functions and functions.GetPlayer and functions.GetPlayer(src)
            end

            local gang = player and player.PlayerData and player.PlayerData.gang
            if type(gang) == "table" and gang.name and gang.name ~= "none" then
                local g = gang.grade
                if type(g) == "table" then g = g.level end
                return gang.name, tonumber(g) or 0
            end
            return nil
        end)

        if ok and type(name) == "string" then
            return name, grade
        end
        return nil
    end
end

--------------------------------------------------------------------------------
-- Debug output
--------------------------------------------------------------------------------

if Config.Debug then
    print(("^5[OXLYN-NOTIFYKIT]^7 framework=^3%s^7 side=^3%s^7"):format(
        framework,
        Bridge.isServer and "server" or "client"
    ))
end

