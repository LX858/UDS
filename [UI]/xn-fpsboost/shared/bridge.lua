

-- oxlyn-fpsboost: framework bridge (shared file, runs on client and server)
-- Cleaned from decompiler output (L0_1/L1_2-style registers renamed, control flow restored).

Oxlyn = Oxlyn or {}

local isServer = IsDuplicityVersion()

local Bridge = {
    name = "standalone",
    object = nil,
    ready = false,
}
Oxlyn.Bridge = Bridge

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

--- true if the resource name is set and that resource is started
local function isStarted(resourceName)
    if not resourceName or resourceName == "" then return false end
    local state = GetResourceState(resourceName)
    return state == "started" or state == "starting"
end

local function activeLocale()
    return Oxlyn.ActiveLocale or Config.Locale or "en"
end

function Oxlyn.Debug(...)
    if not Config.Debug then return end

    local parts = { "[oxlyn-fpsboost]" }
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring((select(i, ...)))
    end
    print(table.concat(parts, " "))
end

--- Localised string lookup with optional string.format args
function Oxlyn.L(key, ...)
    local locale = Locales[activeLocale()] or Locales.en or {}
    local text = locale[key] or (Locales.en and Locales.en[key]) or key

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        if ok then return formatted end
    end
    return text
end

--- Resolve a value that may be a plain string or a { en=, pt= } table
function Oxlyn.T(value)
    if type(value) ~= "table" then
        return tostring(value or "")
    end
    return value[activeLocale()] or value.en or value.pt or ""
end

--- Look up "<a>_<b>[_<c>]" in the active locale, falling back to `fallback`
function Oxlyn.SchemaText(a, b, c, fallback)
    local locale = activeLocale()
    local key = c and ("%s_%s_%s"):format(a, b, c) or ("%s_%s"):format(a, b)

    local localeTable = Locales[locale]
    if localeTable and localeTable[key] and localeTable[key] ~= "" then
        return localeTable[key]
    end

    if type(fallback) == "table" then
        return fallback[locale] or fallback.en or fallback.pt or ""
    end
    return fallback and tostring(fallback) or ""
end

---------------------------------------------------------------------
-- Framework detection
---------------------------------------------------------------------

local function detectFramework()
    local forced = Config.Framework

    if forced and forced ~= "auto" then
        if forced == "standalone" then
            return "standalone"
        end
        if isStarted(Config.FrameworkResources[forced]) then
            return forced
        end
        Oxlyn.Debug(('framework forcado "%s" nao esta started; a cair para deteccao automatica'):format(forced))
    end

    if isStarted(Config.FrameworkResources.qbox) then return "qbox" end
    if isStarted(Config.FrameworkResources.qb)   then return "qb"   end
    if isStarted(Config.FrameworkResources.esx)  then return "esx"  end
    return "standalone"
end

local function fetchFrameworkObject(name)
    if name == "esx" then
        local resource = Config.FrameworkResources.esx

        local ok, obj = pcall(function()
            return exports[resource]:getSharedObject()
        end)
        if ok and obj then return obj end

        -- legacy ESX fallback
        local legacy
        TriggerEvent("esx:getSharedObject", function(o) legacy = o end)
        return legacy

    elseif name == "qb" or name == "qbox" then
        local resource = (name == "qbox" and Config.FrameworkResources.qbox)
            or Config.FrameworkResources.qb

        local ok, obj = pcall(function()
            return exports[resource]:GetCoreObject()
        end)
        if ok and obj then return obj end
        return nil
    end

    return nil
end

CreateThread(function()
    Bridge.name = detectFramework()

    if Bridge.name ~= "standalone" then
        -- poll up to 150 times (~30s) for the shared object
        local attempts = 0
        while not Bridge.object and attempts < 150 do
            Bridge.object = fetchFrameworkObject(Bridge.name)
            if Bridge.object then break end
            attempts = attempts + 1
            Wait(200)
        end

        if not Bridge.object then
            Oxlyn.Debug(('"%s" detectado mas sem objecto partilhado; a usar ACE e eventos'):format(Bridge.name))
        end
    end

    Bridge.ready = true
    Oxlyn.Debug("framework:", Bridge.name)

    if Config.ShowBanner then
        print("^1")
        print("   ___  __  __ _  __   ___  __ ")
        print("  / _ \\/ / / /| |/ /  / _ \\/ / ")
        print(" / // / /_/ / |   /  / // / /  ^7oxlyn-fpsboost v1.0.0^1")
        print("/____/\\____/  /_/|_\\ /_//_/_/   ^7framework: " .. Bridge.name .. "^1")
        print("^7")
    end
end)

--- Block until the bridge finished detecting (default timeout 30s)
function Oxlyn.WaitForBridge(timeoutMs)
    local deadline = GetGameTimer() + (timeoutMs or 30000)
    while not Bridge.ready and deadline > GetGameTimer() do
        Wait(50)
    end
    return Bridge.ready
end

function Oxlyn.Framework() return Bridge.name end
function Oxlyn.Core()      return Bridge.object end

---------------------------------------------------------------------
-- SERVER
---------------------------------------------------------------------

if isServer then

    function Oxlyn.GetPlayerName(src)
        return GetPlayerName(src) or ("ID " .. tostring(src))
    end

    --- Prefer the license identifier, else "src:<id>"
    function Oxlyn.GetIdentifier(src)
        for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do
            if id:sub(1, 8) == "license:" then
                return id
            end
        end
        return ("src:%s"):format(src)
    end

    local function groupMatches(group, allowed)
        for _, g in ipairs(allowed) do
            if group == g then return true end
        end
        return false
    end

    function Oxlyn.IsAdmin(src)
        -- console / invalid source is always allowed
        if not src or src == 0 then return true end

        if Config.Admin.ace and IsPlayerAceAllowed(src, Config.Admin.ace) then
            return true
        end
        if Config.Admin.allowConsoleAce and IsPlayerAceAllowed(src, "command") then
            return true
        end

        local groups = Config.Admin.groups or {}
        local core = Bridge.object

        if Bridge.name == "esx" and core then
            local player = core.GetPlayerFromId and core.GetPlayerFromId(src)
            if player then
                local group = (player.getGroup and player.getGroup()) or player.group
                return groupMatches(group, groups)
            end
            return false
        end

        if (Bridge.name == "qb" or Bridge.name == "qbox") and core then
            local functions = core.Functions

            if functions and functions.HasPermission then
                for _, g in ipairs(groups) do
                    local ok, has = pcall(functions.HasPermission, src, g)
                    if ok and has then return true end
                end
                -- also try the whole list at once
                local ok, has = pcall(functions.HasPermission, src, groups)
                if ok and has then return true end
            end

            local player = functions and functions.GetPlayer and functions.GetPlayer(src)
            if player and player.PlayerData then
                local group = player.PlayerData.group
                if not group and player.PlayerData.job then
                    group = player.PlayerData.job.name
                end
                return groupMatches(group, groups)
            end
            return false
        end

        return false
    end

    function Oxlyn.NotifyServer(src, message)
        local mode = Config.Notify.type
        if mode == "none" then return end

        if mode == "ui" then
            TriggerClientEvent("oxlyn_fps:notify", src, message)
            return
        end

        if mode == "auto" or mode == "framework" then
            if Bridge.name == "esx" then
                TriggerClientEvent("esx:showNotification", src, message)
                return
            elseif Bridge.name == "qbox" then
                local ok = pcall(function()
                    exports[Config.FrameworkResources.qbox]:Notify(src, message, "inform")
                end)
                if ok then return end
            elseif Bridge.name == "qb" then
                TriggerClientEvent("QBCore:Notify", src, message, "primary", Config.Notify.duration)
                return
            end
        end

        -- fallback: chat message
        TriggerClientEvent("chat:addMessage", src, {
            color = { 255, 46, 67 },
            multiline = true,
            args = { Config.Notify.title, message },
        })
    end

    return -- nothing below runs on the server
end

---------------------------------------------------------------------
-- CLIENT
---------------------------------------------------------------------

function Oxlyn.Notify(message, kind)
    local mode = Config.Notify.type
    if mode == "none" or not message then return end

    if mode == "ui" then
        SendNUIMessage({
            action = "toast",
            message = message,
            kind = kind or "info",
            duration = Config.Notify.duration,
            title = Config.Notify.title,
        })
        return
    end

    if mode == "auto" or mode == "framework" then
        local core = Bridge.object

        if Bridge.name == "esx" and core then
            if core.ShowNotification then
                core.ShowNotification(message)
                return
            end
        elseif core and core.Functions and core.Functions.Notify then
            core.Functions.Notify(message, kind == "error" and "error" or "primary", Config.Notify.duration)
            return
        elseif Bridge.name == "qbox" then
            local ok = pcall(function()
                exports[Config.FrameworkResources.qbox]:Notify(message, kind == "error" and "error" or "inform")
            end)
            if ok then return end
        end
    end

    if mode == "chat" then
        TriggerEvent("chat:addMessage", {
            color = { 255, 46, 67 },
            multiline = true,
            args = { Config.Notify.title, message },
        })
        return
    end

    -- fallback: native GTA feed ticker
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

--- Returns (true, reason) if the local player is dead / downed
function Oxlyn.IsPlayerDown()
    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    if IsEntityDead(ped) then
        return true, "native IsEntityDead"
    end

    local core = Bridge.object

    if Bridge.name == "esx" and core then
        if core.PlayerData and core.PlayerData.dead then
            return true, "ESX.PlayerData.dead"
        end

    elseif (Bridge.name == "qb" or Bridge.name == "qbox") and core then
        local data = core.Functions and core.Functions.GetPlayerData and core.Functions.GetPlayerData()
        if data and data.metadata then
            if data.metadata.isdead then
                return true, "metadata.isdead"
            end
            if data.metadata.inlaststand then
                return true, "metadata.inlaststand"
            end
        end
    end

    return false
end

--- true if the local player is the driver of a vehicle moving faster than 2.0 m/s
function Oxlyn.IsDriving()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return false end

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return false end

    return GetEntitySpeed(vehicle) > 2.0
end

