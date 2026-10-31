local resourceName = GetCurrentResourceName()

local function debugLog(fmt, ...)
    if not (Config and Config.Debug) then return end
    local msg = select("#", ...) > 0 and fmt:format(...) or fmt
    print("[oxlyn-helicam] " .. msg)
end

-- Camera leases ------------------------------------------------------------

local leases = {}               -- [heliNetId] = { src = playerId, seen = gameTimer }
local LEASE_TIMEOUT  = 20000
local SWEEP_INTERVAL = 10000

local function isValidPlayer(src)
    return src and GetPlayerName(src) ~= nil
end

local function getHeliEntity(netId)
    local ok, entity = pcall(NetworkGetEntityFromNetworkId, netId)
    if not (ok and entity) or entity == 0 then return nil end
    if not DoesEntityExist(entity) then return nil end
    return entity
end

local function isPlayerInVehicle(src, vehicle)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local current = GetVehiclePedIsIn(ped)
    return current ~= nil and current ~= 0 and current == vehicle
end

local function isLeaseValid(lease, netId, now)
    if type(lease) ~= "table" or not lease.src then return false end
    if not isValidPlayer(lease.src) then return false end
    if now - (lease.seen or 0) > LEASE_TIMEOUT then return false end

    local heli = getHeliEntity(netId)
    if heli and not isPlayerInVehicle(lease.src, heli) then
        return false
    end

    return true
end

Framework.RegisterCallback("oxlyn-helicam:claim", function(src, cb, netId)
    netId = tonumber(netId) or 0

    if not Framework.HasAccess(src, Config.Access) then
        return cb({ ok = false, reason = "no_access" })
    end

    -- Non-networked heli: nothing to lease
    if netId <= 0 then
        debugLog("camera granted on a non-networked heli to %s (no lease)", src)
        return cb({ ok = true, exclusive = false })
    end

    local now = GetGameTimer()
    local existing = leases[netId]

    if existing and existing.src ~= src then
        if isLeaseValid(existing, netId, now) then
            debugLog("camera on heli %s denied to %s — operated by %s", netId, src, existing.src)
            return cb({ ok = false, reason = "cam_in_use" })
        end
        debugLog("camera on heli %s taken over by %s — stale lease from %s", netId, src, existing.src)
    end

    leases[netId] = { src = src, seen = now }
    debugLog("camera claimed on heli %s by %s", netId, src)

    cb({ ok = true, exclusive = true })
end)

RegisterNetEvent("oxlyn-helicam:heartbeat", function(netId)
    local src = source
    netId = tonumber(netId)
    if not netId or netId <= 0 then return end

    local now = GetGameTimer()
    local lease = leases[netId]

    if lease then
        if lease.src == src then
            lease.seen = now
        end
        return
    end

    -- No lease on record: let the actual operator re-take it
    local heli = getHeliEntity(netId)
    if heli
        and isPlayerInVehicle(src, heli)
        and Framework.HasAccess(src, Config.Access)
    then
        leases[netId] = { src = src, seen = now }
        debugLog("camera lease on heli %s re-taken by its operator %s", netId, src)
    end
end)

RegisterNetEvent("oxlyn-helicam:release", function(netId)
    local src = source
    netId = tonumber(netId)

    local lease = netId and leases[netId]
    if lease and lease.src == src then
        leases[netId] = nil
        debugLog("camera released on heli %s by %s", netId, src)
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    for netId, lease in pairs(leases) do
        if lease.src == src then
            leases[netId] = nil
        end
    end
end)

CreateThread(function()
    while true do
        Wait(SWEEP_INTERVAL)

        local now = GetGameTimer()
        for netId, lease in pairs(leases) do
            if not isLeaseValid(lease, netId, now) then
                leases[netId] = nil
                debugLog("camera lease on heli %s swept (stale, was %s)", netId, tostring(lease.src))
            end
        end
    end
end)

RegisterCommand("helicamreset", function(src)
    local count = 0
    for netId in pairs(leases) do
        leases[netId] = nil
        count = count + 1
    end

    local msg = ("[oxlyn-helicam] cleared %d camera lease(s)."):format(count)

    if src == 0 then
        print(msg)
    else
        TriggerClientEvent("chat:addMessage", src, { args = { "HeliCam", msg } })
    end
end, true)

-- Shared helpers -----------------------------------------------------------

local function jobAllowed(jobName, list)
    if not jobName then return false end
    for _, name in ipairs(list) do
        if name == jobName then return true end
    end
    return false
end

local function resolveShareList(shareWith, ownJob)
    if type(shareWith) == "table" then
        return shareWith
    end
    return { ownJob }
end

-- Tagging ------------------------------------------------------------------

local tagCounter = 0

RegisterNetEvent("oxlyn-helicam:sv:tag", function(data)
    local src = source

    if not Config.Marking.enabled then return end
    if type(data) ~= "table" then return end
    if not Framework.HasAccess(src, Config.Access) then return end

    local job = Framework.GetJob(src)
    local jobName = job and job.name or nil
    local shareJobs = resolveShareList(Config.Marking.shareWith, jobName)

    tagCounter = tagCounter + 1
    local tagId = ("%d-%d"):format(src, tagCounter)

    local coords = data.coords or {}
    local tag = {
        tagId        = tagId,
        targetType   = data.targetType == "player" and "player" or "npc",
        targetServer = tonumber(data.targetServer),
        x            = tonumber(coords.x) or 0.0,
        y            = tonumber(coords.y) or 0.0,
        z            = tonumber(coords.z) or 0.0,
        duration     = Config.Marking.duration,
    }

    for _, id in ipairs(GetPlayers()) do
        local playerId = tonumber(id)
        local playerJob = Framework.GetJob(playerId)

        if playerJob and jobAllowed(playerJob.name, shareJobs) then
            TriggerClientEvent("oxlyn-helicam:client:addTag", playerId, tag)
        end
    end

    debugLog("mark %s from %s (%s) → jobs %s", tagId, src, tag.targetType, table.concat(shareJobs, ","))
end)

-- Markers ------------------------------------------------------------------

RegisterNetEvent("oxlyn-helicam:sv:marker", function(kind, x, y, z)
    local src = source

    if not (Config.Markers and Config.Markers.enabled) then return end
    if not Framework.HasAccess(src, Config.Access) then return end

    local job = Framework.GetJob(src)
    local shareJobs = resolveShareList(Config.Markers.shareWith, job and job.name)

    kind = tonumber(kind) or 0
    x = tonumber(x) or 0.0
    y = tonumber(y) or 0.0
    z = tonumber(z) or 0.0

    for _, id in ipairs(GetPlayers()) do
        local playerId = tonumber(id)

        if playerId ~= src then
            local playerJob = Framework.GetJob(playerId)

            if playerJob and jobAllowed(playerJob.name, shareJobs) then
                TriggerClientEvent("oxlyn-helicam:client:marker", playerId, src, kind, x, y, z)
            end
        end
    end
end)

RegisterNetEvent("oxlyn-helicam:sv:markerClear", function()
    TriggerClientEvent("oxlyn-helicam:client:markerClear", -1, source)
end)

-- Startup banner -----------------------------------------------------------

AddEventHandler("onResourceStart", function(name)
    if name ~= resourceName then return end

    CreateThread(function()
        Wait(500)

        local version = GetResourceMetadata(resourceName, "version", 0) or "?"
        local bar = string.rep("═", 74)

        print("^0^7")
        print("^5╔" .. bar .. "╗^7")
        print("^5║^7  ^3OXLYN HELICAM^7  ·  Airborne Camera Unit  ·  ^2v" .. version .. "^7")
        print("^5║^7")
        print("^5║^7  Setup and options:  ^7config.lua^7  ·  ^7README.md^7")
        print("^5║^7  More assets:  ^4https://oxlynsoftware.com^7")
        print("^5║^7  Support:  ^4https://discord.com/invite/KjWmrSwMXg^7")
        print("^5╚" .. bar .. "╝^7")
    end)
end)