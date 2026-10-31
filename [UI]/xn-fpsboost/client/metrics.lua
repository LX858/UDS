

Oxlyn = Oxlyn or {}

Oxlyn.Metrics = {
    real = {
        peds = 0,
        vehicles = 0,
        objects = 0,
        pickups = 0,
        nearPlayers = 0,
        totalEntities = 0,
        luaMemKb = 0,
        resources = 0,
        screenW = 0,
        screenH = 0,
        ping = 0,
        players = 0,
        maxPlayers = 0,
        serverName = "",
        gameBuild = "",
        onesync = "",
        uptimeMs = 0,
    },
    estimated = {
        cpu = 0,
        gpu = 0,
        ram = 0,
        vram = 0,
    },
}

local Metrics = Oxlyn.Metrics
local real = Metrics.real
local estimated = Metrics.estimated

local NEAR_PLAYER_RADIUS = 150.0
local RESOURCE_COUNT_INTERVAL = 30000
local SMOOTHING = 0.2
local lastResourceCount = -60000

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function clamp01(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

-- Should we be collecting entity data right now?
local function shouldCollect()
    if Oxlyn.State.open then
        return true
    end

    if Oxlyn.Get("hudEnabled") and Oxlyn.Eff("hudShowEntities") then
        return true
    end

    return false
end

---------------------------------------------------------------------
-- Collectors
---------------------------------------------------------------------

local function updateEntityCounts()
    real.peds = #GetGamePool("CPed")
    real.vehicles = #GetGamePool("CVehicle")
    real.objects = #GetGamePool("CObject")
    real.pickups = #GetGamePool("CPickup")
    real.totalEntities = real.peds + real.vehicles + real.objects + real.pickups

    -- Nearby players are only counted while the menu is open
    if not Oxlyn.State.open then return end

    local nearby = 0
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)

    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if ped ~= myPed and DoesEntityExist(ped) then
            local distance = #(GetEntityCoords(ped) - myCoords)
            if distance < NEAR_PLAYER_RADIUS then
                nearby = nearby + 1
            end
        end
    end

    real.nearPlayers = nearby
end

local function updateSystemInfo()
    real.screenW, real.screenH = GetActiveScreenResolution()
    real.luaMemKb = math.floor(collectgarbage("count"))

    -- Counting started resources is slow, so only do it every 30s
    local now = GetGameTimer()
    if now - lastResourceCount > RESOURCE_COUNT_INTERVAL then
        lastResourceCount = now

        local started = 0
        for i = 0, GetNumResources() - 1 do
            local resource = GetResourceByFindIndex(i)
            if resource and GetResourceState(resource) == "started" then
                started = started + 1
            end
        end
        real.resources = started
    end

    real.uptimeMs = GetGameTimer() - Oxlyn.State.sessionStart
end

local function readServerInfo()
    real.gameBuild = tostring(GetConvarInt and GetConvarInt("sv_enforceGameBuild", 0) or 0)
    if real.gameBuild == "0" then
        real.gameBuild = "default"
    end

    real.onesync = GetConvar("onesync", "off")

    real.serverName = GetConvar("sv_projectName", "")
    if real.serverName == "" then
        real.serverName = GetConvar("sv_hostname", "FiveM Server")
    end
    -- Strip colour codes (^1 and ~r~ style)
    real.serverName = real.serverName:gsub("%^%d", ""):gsub("~%a~", "")

    real.maxPlayers = GetConvarInt("sv_maxClients", 32)
end

---------------------------------------------------------------------
-- Estimated CPU / GPU / RAM / VRAM load (heuristic, smoothed)
---------------------------------------------------------------------

local function updateEstimates()
    local fps = Oxlyn.FPS
    if not fps then return end

    local avgFrametime = fps.avgFrametime or 16.7
    local bestFrametime = fps.bestFrametime or avgFrametime
    local frametimeStdDev = fps.frametimeStdDev or 0

    -- GPU: how far the average frametime is from the best one
    local frametimeSpread = 0
    if bestFrametime > 0 then
        frametimeSpread = clamp01((avgFrametime - bestFrametime) / (bestFrametime * 2.0))
    end
    local gpuLoad = 45 + frametimeSpread * 55

    -- CPU: frametime jitter + entity count
    local jitter = clamp01(frametimeStdDev / (avgFrametime * 0.45))
    local entityCpu = clamp01(real.totalEntities / 900.0)
    local cpuLoad = 20 + jitter * 55 + entityCpu * 25

    -- RAM: entities + resources + Lua memory
    local luaMem = clamp01(real.luaMemKb / 8192.0)
    local entityRam = clamp01(real.totalEntities / 1100.0)
    local resourceLoad = clamp01(real.resources / 400.0)
    local ramLoad = 25 + entityRam * 45 + resourceLoad * 20 + luaMem * 10

    -- VRAM: objects + vehicles + resolution (relative to 2560x1440)
    local objectLoad = clamp01(real.objects / 700.0)
    local vehicleLoad = clamp01(real.vehicles / 180.0)
    local resolutionLoad = (real.screenW * real.screenH) / 3686400
    local vramLoad = 20 + objectLoad * 35 + vehicleLoad * 25 + clamp01(resolutionLoad) * 20

    -- Smooth towards the target values
    estimated.cpu = estimated.cpu + (math.min(cpuLoad, 99) - estimated.cpu) * SMOOTHING
    estimated.gpu = estimated.gpu + (math.min(gpuLoad, 99) - estimated.gpu) * SMOOTHING
    estimated.ram = estimated.ram + (math.min(ramLoad, 99) - estimated.ram) * SMOOTHING
    estimated.vram = estimated.vram + (math.min(vramLoad, 99) - estimated.vram) * SMOOTHING
end

---------------------------------------------------------------------
-- Threads
---------------------------------------------------------------------

-- Data collection loop
CreateThread(function()
    Wait(1500)
    readServerInfo()

    while true do
        local collecting = shouldCollect()
        if collecting then
            updateEntityCounts()
            real.players = #GetActivePlayers()
        end
        updateSystemInfo()

        if Oxlyn.State.open then
            Wait(1000)
        elseif collecting then
            Wait(3000)
        else
            Wait(5000)
        end
    end
end)

-- Estimation loop (only runs while the menu is open)
CreateThread(function()
    Wait(2000)
    local wasOpen = false

    while true do
        if Oxlyn.State.open then
            if not wasOpen then
                -- Warm up the smoothing so values don't start at 0
                for _ = 1, 20 do
                    updateEstimates()
                end
            end
            updateEstimates()
            wasOpen = true
            Wait(250)
        else
            wasOpen = false
            Wait(2000)
        end
    end
end)

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------

function Oxlyn.MetricsSnapshot()
    return {
        real = real,
        estimated = {
            cpu = math.floor(estimated.cpu + 0.5),
            gpu = math.floor(estimated.gpu + 0.5),
            ram = math.floor(estimated.ram + 0.5),
            vram = math.floor(estimated.vram + 0.5),
        },
    }
end

