Config = Config or {}
Config.DjLocations = Config.DjLocations or {}
Config.DjLocationMarker = Config.DjLocationMarker or {}
Config.DjSoundBoard = Config.DjSoundBoard or {}

local menuOpen              = false   -- DJ menu is currently open
local creatorOpen           = false   -- In-game creator UI is open
local streamerMode          = false   -- Streamer mode (mutes audio)
local nearbyLocationId      = nil     -- ID of the closest DJ location (proximity check)
local activeMenuLocationId  = nil     -- ID of the location whose menu is open

local soundMinDistance      = 1.0    -- Inner edge of audio falloff zone
local volumeLerpSpeed       = 0.25   -- Speed of volume interpolation per tick
local soundTickInterval     = 250    -- ms between sound-update ticks
local quadraticFalloffExp   = 2.0    -- Exponent used by quadratic falloff
local expoFalloffAlpha      = 0.25   -- α used by exponential falloff
local attenuationCutoff     = true   -- Hard-cut volume at max distance

local targetsCreated        = false  -- Target zones already registered
local playerInitialized     = false  -- InitializeDj() has run
local duiHandle             = nil    -- Handle to the DUI browser instance
local duiReady              = false  -- DUI reports it is loaded and ready

local pendingReset          = {}     -- locationId → true when a reset is queued
local activeSoundLinks      = {}     -- locationId → currently playing URL
local activeSoundTypes      = {}     -- locationId → "youtube" | "mp3"
local locationVolumes       = {}     -- locationId → interpolated volume (0-100)
local defaultSoundFalloff   = "quadratic"

local resetmusic = false  -- when true, skip lerp and snap volume immediately (e.g. after a reset)
local lastAliveTimestamp    = 0
local aliveTimeoutMs        = 10000
local aliveCheckInterval    = 1000

-- Effect-spawn distance (updated after the spawn thread constant section)
local effectSpawnDistance   = 500.0

-- Light / laser swing animation
local swingAngleMax   = 60.0   -- degrees each direction
local lightSwingSpeed = 40.0   -- deg/s for stage lights
local laserSwingSpeed = 60.0   -- deg/s for laser heads
local swingState      = { lights = {}, lasers = {} }

-- Creator freecam state (populated when InGameDjCreator is enabled)
local creatorStartCoords  = vector3(0.0, 0.0, 0.0)
local freecamActive       = false
local freecamHandle       = nil
local freecamPosition     = nil
local freecamRotation     = nil
local freecamSpeedBase    = 2.0
local freecamSpeedMed     = 2.2
local freecamSpeedFast    = 2.5
local freecamPitchMin     = -89.0
local freecamPitchMax     = 89.0

-- Creator preview-object tables (populated inside InGameDjCreator block)
local creatorLightObjects    = {}
local creatorSmokeObjects    = {}
local creatorLaserObjects    = {}
local creatorParticleObjects = {}
local creatorLocationName    = ""
local creatorLocationCoords  = vector3(0.0, 0.0, 0.0)
local creatorLocationRotation = vector3(0.0, 0.0, 0.0)
local creatorSelectedElement = nil

-- ─── Utility ──────────────────────────────────────────────────────────────────

function ShowGtaClassicInteraction(text)
    AddTextEntry("gtavclassicinteractionrtxdj", text)
    BeginTextCommandDisplayHelp("gtavclassicinteractionrtxdj")
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function LanguageFile2(key, ...)
    local lang = (Config and Config.Language) or "English"
    local langTable = (Language and Language[lang]) or (Language and Language["English"]) or {}
    local formatStr = langTable[key] or key or ""
    local success, result = pcall(string.format, formatStr, ...)
    if success then return result end
    return formatStr
end

function LanguageFile(key, ...)
    local raw = tostring(LanguageFile2(key, ...))
    return tostring(raw:gsub("^%l", string.upper))
end

function formatTime(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

function IsPlayerNearCoords(playerCoords, targetCoords, maxDist)
    local dist = #(playerCoords - vector3(targetCoords.x, targetCoords.y, targetCoords.z))
    local limit = maxDist or 500.0
    return dist <= limit
end

function Lerp(a, b, t)
    return a + (b - a) * t
end

function Clamp(value, minVal, maxVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

function calcAttenuatedVolume(playerDist, minDist, maxDist, masterVolume, soundType, quadExp, expoAlpha, cutoff)
    local volume = tonumber(masterVolume) or 0
    volume = Clamp(volume, 0, 100)

    local min = tonumber(minDist) or 0.0
    local max = tonumber(maxDist) or 0.0
    local dist = tonumber(playerDist) or max

    if min >= max then
        return Clamp(math.floor(volume + 0.5), 0, 100)
    end
    if min >= dist then
        return Clamp(math.floor(volume + 0.5), 0, 100)
    end

    local tolerance = (max - min) * 0.001 + 0.001

    if cutoff and dist >= max - tolerance then return 0 end

    local t = Clamp((dist - min) / (max - min), 0.0, 1.0)

    if cutoff and t >= 0.999999 then return 0 end

    local factor
    if soundType == "linear" then
        factor = 1.0 - t
    elseif soundType == "quadratic" then
        factor = (1.0 - t) ^ (quadExp or 2.0)
    elseif soundType == "expo" then
        local a = math.max(1.0e-4, expoAlpha or 0.25)
        local range = max - min
        local num = math.exp(-a * (dist - min))
        local den = math.exp(-a * range)
        local denom = 1.0 - den
        if denom <= 1.0e-9 then
            factor = 0.0
        else
            factor = Clamp((num - den) / denom, 0.0, 1.0)
        end
    else
        factor = 1.0 - t
    end

    return Clamp(math.floor(volume * factor + 0.5), 0, 100)
end

function round2(value)
    return math.floor(value * 100 + 0.5) / 100
end

function calcProgress(current, total)
    if not (current and total) or total <= 0 then
        return 0.0
    end
    local ratio = current / total
    if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
    return round2(ratio * 100.0)
end

-- ─── Helpers shared across events ─────────────────────────────────────────────

function GetLocationGlobalState(locationId, suffix)
    return GlobalState["rtxdjlocation-" .. locationId .. suffix]
end

function BuildQueueTable(rawQueue)
    local formatted = {}
    for id, entry in pairs(rawQueue) do
        local typeLabel = ""
        if entry.typequeuedata == "youtube" then typeLabel = "YouTube"
        elseif entry.typequeuedata == "mp3"     then typeLabel = "MP3" end
        formatted[id] = {
            id       = id,
            name     = entry.titlequeuedata,
            artist   = typeLabel,
            duration = formatTime(entry.durationqueuedata),
        }
    end
    local sorted = {}
    for _, v in pairs(formatted) do
        sorted[#sorted + 1] = { id = v.id, name = v.name, artist = v.artist, duration = v.duration }
    end
    table.sort(sorted, function(a, b) return a.id < b.id end)
    return sorted
end

-- ─── Initialization ───────────────────────────────────────────────────────────

function CreateTargets()
    if targetsCreated then return end
    if not Config or not Config.DjLocations then return end
    targetsCreated = true
    for locationId, location in pairs(Config.DjLocations) do
        local zoneName = "rtxdjlocation" .. locationId
        AddTargetZone(
            "coords", zoneName, location.coords,
            0.0, Config.DjMenuMaxOpenDistance,
            Language[Config.Language].djmenu,
            Config.TargetIcons.djicon,
            "rtx_dj:Global:OpenMenuTarget"
        )
    end
end

function InitializeDj()
    if playerInitialized then return end
    playerInitialized = true

    SendNUIMessage({
        message          = "updateinterfacedata",
        interfacecolordata = Config.InterfaceColor,
        djresourcenamedata = tostring(GetCurrentResourceName()),
    })

    if not targetsCreated and Config.Target then
        CreateTargets()
    end

    TriggerServerEvent("rtx_dj:Global:SynchLocations")
end

AddEventHandler("playerSpawned", function()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        InitializeDj()
    end)
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.CreateThread(function()
        while true do
            if NetworkIsPlayerActive(PlayerId()) and DoesEntityExist(PlayerPedId()) then break end
            Citizen.Wait(500)
        end
        Citizen.Wait(1000)
        InitializeDj()
    end)
end)

-- ─── NUI Callbacks ────────────────────────────────────────────────────────────

RegisterNUICallback("closedjmenu", function(data, cb)
    if menuOpen then
        SendNUIMessage({ message = "closedjmenu" })
        SetNuiFocus(false, false)
        menuOpen = false
        TriggerServerEvent("rtx_dj:Global:CloseMenu", activeMenuLocationId)
        activeMenuLocationId = nil
    end
    cb("ok")
end)

RegisterNUICallback("addsongtoqueue", function(data, cb)
    if menuOpen then
        TriggerServerEvent(
            "rtx_dj:Global:PlayMusic",
            activeMenuLocationId,
            math.floor(tonumber(data.durationdata) or 0),
            tostring(data.titledata),
            tostring(data.typedata),
            tostring(data.linkdata)
        )
    end
    cb("ok")
end)

RegisterNUICallback("loopenable", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:ChangeLoop", activeMenuLocationId, data.loopdata)
    end
    cb("ok")
end)

RegisterNUICallback("durationchange", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:ChangeDuration", activeMenuLocationId, tonumber(data.durationdata))
    end
    cb("ok")
end)

RegisterNUICallback("forwardbackward", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:ChangeForwardBackWard", activeMenuLocationId, data.forwardbackwarddata)
    end
    cb("ok")
end)

RegisterNUICallback("resume", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:ResumeMusic", activeMenuLocationId, data.resumedata)
    end
    cb("ok")
end)

RegisterNUICallback("volumechange", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:ChangeVolume", activeMenuLocationId, tonumber(data.volumedata))
    end
    cb("ok")
end)

RegisterNUICallback("radiuschange", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:ChangeDistance", activeMenuLocationId, tonumber(data.radiusdata))
    end
    cb("ok")
end)

RegisterNUICallback("clearqueue", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:ClearQueue", activeMenuLocationId)
    end
    cb("ok")
end)

RegisterNUICallback("stopsong", function(data, cb)
    if menuOpen then
        TriggerServerEvent("rtx_dj:Global:StopSong", activeMenuLocationId)
    end
    cb("ok")
end)

RegisterNUICallback("removequeuemusic", function(data, cb)
    if menuOpen and data.queueiddata ~= nil then
        TriggerServerEvent("rtx_dj:Global:RemoveQueueMusic", activeMenuLocationId, tonumber(data.queueiddata))
    end
    cb("ok")
end)

RegisterNUICallback("soundboard", function(data, cb)
    if menuOpen and data.soundiddata ~= nil then
        TriggerServerEvent("rtx_dj:Global:SoundBoard", activeMenuLocationId, tonumber(data.soundiddata))
    end
    cb("ok")
end)

RegisterNUICallback("effecttoggle", function(data, cb)
    if menuOpen then
        local effect = tostring(data.effect)
        local eventMap = {
            lights    = "rtx_dj:Global:LightHandler",
            fog       = "rtx_dj:Global:FogHandler",
            lasers    = "rtx_dj:Global:LaserHandler",
            particles = "rtx_dj:Global:ParticlesHandler",
        }
        local evt = eventMap[effect]
        if evt then TriggerServerEvent(evt, activeMenuLocationId, data.enabled) end
    end
    cb("ok")
end)

RegisterNUICallback("effectcolor", function(data, cb)
    if menuOpen then
        local effect = tostring(data.effect)
        local color  = { r = tonumber(data.r), g = tonumber(data.g), b = tonumber(data.b) }
        local eventMap = {
            lights = "rtx_dj:Global:LightColorHandler",
            fog    = "rtx_dj:Global:FogColorHandler",
            lasers = "rtx_dj:Global:LaserColorHandler",
        }
        local evt = eventMap[effect]
        if evt then TriggerServerEvent(evt, activeMenuLocationId, color) end
    end
    cb("ok")
end)

RegisterNUICallback("effectmove", function(data, cb)
    if menuOpen then
        local effect = tostring(data.effect)
        if effect == "lights" then
            TriggerServerEvent("rtx_dj:Global:LightMoveHandler", activeMenuLocationId, data.move)
        elseif effect == "lasers" then
            TriggerServerEvent("rtx_dj:Global:LaserMoveHandler", activeMenuLocationId, data.move)
        end
    end
    cb("ok")
end)

-- ─── Net Events ───────────────────────────────────────────────────────────────

RegisterNetEvent("rtx_dj:Global:ChangeTime")
AddEventHandler("rtx_dj:Global:ChangeTime", function(locationId, duration, soundCategory)
    SendDuiMessage(duiHandle, json.encode({
        message       = "changeduration",
        djlocation    = locationId,
        soundduration = duration,
        soundcategory = soundCategory,
    }))
end)

RegisterNetEvent("rtx_dj:Global:ResumeHandler")
AddEventHandler("rtx_dj:Global:ResumeHandler", function(locationId, duration, resumeState, soundCategory)
    SendDuiMessage(duiHandle, json.encode({
        message       = "resumehandler",
        djlocation    = locationId,
        soundduration = duration,
        resumehandler = resumeState,
        soundcategory = soundCategory,
    }))
end)

RegisterNetEvent("rtx_dj:Global:SettingsUpdate")
AddEventHandler("rtx_dj:Global:SettingsUpdate", function(locationId, volume, radius)
    if not menuOpen then return end
    SendNUIMessage({
        message    = "updatesettings",
        djlocation = locationId,
        volumedata = volume,
        radiusvalue = radius,
    })
end)

RegisterNetEvent("rtx_dj:Global:OpenMenuClient")
AddEventHandler("rtx_dj:Global:OpenMenuClient", function(locationId, rawQueue)
    if menuOpen then return end

    local location = Config.DjLocations[locationId]
    if not location then return end
    activeMenuLocationId = locationId

    SendNUIMessage({ message = "updatequeue", queuetable = BuildQueueTable(rawQueue) })

    local soundboardList = {}
    for i, entry in ipairs(Config.DjSoundBoard) do
        local item = entry
        item.id = i
        table.insert(soundboardList, item)
    end
    SendNUIMessage({ message = "updatesoundboard", soundboard = soundboardList })

    menuOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        message    = "djshow",
        djlabel    = location.label,
        loop       = GetLocationGlobalState(locationId, "-loop"),
        stopped    = GetLocationGlobalState(locationId, "-stopped"),
        volumedata = GetLocationGlobalState(locationId, "-currentvolume"),
        radiusvalue = GetLocationGlobalState(locationId, "-currentdistance"),
        maxradius  = location.maxdistance,
        smoke      = location.smoke.enabled,
        particles  = location.particles.enabled,
        lights     = location.lights.enabled,
        lasers     = location.lasers.enabled,
        effects    = {
            lights = {
                enabled = GetLocationGlobalState(locationId, "-lights"),
                move    = GetLocationGlobalState(locationId, "-lightsmove"),
                color   = GetLocationGlobalState(locationId, "-lightscolor"),
            },
            fog = {
                enabled = GetLocationGlobalState(locationId, "-smoke"),
                color   = GetLocationGlobalState(locationId, "-smokecolor"),
            },
            lasers = {
                enabled = GetLocationGlobalState(locationId, "-lasers"),
                move    = GetLocationGlobalState(locationId, "-lasersmove"),
                color   = GetLocationGlobalState(locationId, "-laserscolor"),
            },
            particles = {
                enabled = GetLocationGlobalState(locationId, "-particles"),
            },
        },
    })

    -- Keep idle camera suppressed while menu is open, update track info each tick
    while menuOpen do
        Citizen.Wait(100)
        InvalidateIdleCam()
        InvalidateVehicleIdleCam()

        if GetLocationGlobalState(locationId, "-playing") then
            SendNUIMessage({
                message               = "updatedjmenudata",
                name                  = GetLocationGlobalState(locationId, "-titledata"),
                currenttime           = formatTime(GetLocationGlobalState(locationId, "-currentdurationdata")),
                maxduration           = formatTime(GetLocationGlobalState(locationId, "-maxdurationdata")),
                recalculatedpercentage = calcProgress(
                    GetLocationGlobalState(locationId, "-currentdurationdata"),
                    GetLocationGlobalState(locationId, "-maxdurationdata")
                ) .. "%",
            })
        else
            SendNUIMessage({ message = "hidesonginfo" })
        end
    end
end)

RegisterNetEvent("rtx_dj:Global:UpdateQueue")
AddEventHandler("rtx_dj:Global:UpdateQueue", function(locationId, rawQueue)
    if not menuOpen then return end
    SendNUIMessage({ message = "updatequeue", queuetable = BuildQueueTable(rawQueue) })
end)

RegisterNetEvent("rtx_dj:Global:StopCompletly")
AddEventHandler("rtx_dj:Global:StopCompletly", function(locationId, soundCategory)
    SendDuiMessage(duiHandle, json.encode({
        message       = "stopmusic",
        djlocation    = locationId,
        soundcategory = soundCategory,
    }))
end)

RegisterNetEvent("rtx_dj:Global:Reset")
AddEventHandler("rtx_dj:Global:Reset", function(locationId)
    pendingReset[locationId] = true
end)

RegisterNetEvent("rtx_dj:Global:SoundBoardClient")
AddEventHandler("rtx_dj:Global:SoundBoardClient", function(locationId, soundId)
    local location  = Config.DjLocations[locationId]
    local sound     = Config.DjSoundBoard[soundId]
    if not location or not sound then return end
    local playerPos = GetEntityCoords(PlayerPedId())
    local dist      = #(playerPos - location.coords)

    local radius = GetLocationGlobalState(locationId, "-currentdistance") or 50.0
    local volume = GetLocationGlobalState(locationId, "-currentvolume")   or 100

    if GetLocationGlobalState(locationId, "-currentvolume") == 0 then return end
    if streamerMode then return end

    -- ⚠️ `resetmusic` is a cross-file global flag; when true we skip lerp and set volume immediately
    if locationVolumes[locationId] ~= nil and not resetmusic then
        locationVolumes[locationId] = math.floor(Lerp(locationVolumes[locationId], calcAttenuatedVolume(dist, soundMinDistance, radius, volume, defaultSoundFalloff, quadraticFalloffExp, expoFalloffAlpha, attenuationCutoff), volumeLerpSpeed) + 0.5)
    else
        locationVolumes[locationId] = calcAttenuatedVolume(dist, soundMinDistance, radius, volume, defaultSoundFalloff, quadraticFalloffExp, expoFalloffAlpha, attenuationCutoff)
    end

    SendNUIMessage({
        message    = "playsoundboard",
        soundiddata = math.random(10000, 99999),
        soundsrc   = sound.soundpath,
        soundvolume = math.min(locationVolumes[locationId] / 100.0, 0.5),
    })
end)

RegisterNetEvent("rtx_dj:Global:CreateNewDjLocation")
AddEventHandler("rtx_dj:Global:CreateNewDjLocation", function(locationId, locationData)
    Config.DjLocations[locationId] = locationData
    if Config.Target then
        AddTargetZone(
            "coords",
            "rtxdjlocation" .. locationId,
            locationData.coords,
            0.0, Config.DjMenuMaxOpenDistance,
            Language[Config.Language].djmenu,
            Config.TargetIcons.djicon,
            "rtx_dj:Global:OpenMenuTarget"
        )
    end
end)

RegisterNetEvent("rtx_dj:Global:UpdateDjLocation")
AddEventHandler("rtx_dj:Global:UpdateDjLocation", function(locationId, locationData)
    local location = Config.DjLocations[locationId]
    if not location then return end
    location.edit  = true

    -- Remove old target zone
    if Config.Target then
        local zoneName = "rtxdjlocation" .. locationId
        if Config.Targettype == "qtarget" then
            exports[Config.TargetSystemsNames.qtarget]:RemoveZone(zoneName)
        elseif Config.Targettype == "qbtarget" then
            exports[Config.TargetSystemsNames.qbtarget]:RemoveZone(zoneName)
        elseif Config.Targettype == "oxtarget" then
            exports[Config.TargetSystemsNames.oxtarget]:removeZone(zoneName)
        end
    end

    CleanupLocationEffects(location)

    Citizen.Wait(1500)

    Config.DjLocations[locationId] = locationData
    if Config.Target then
        AddTargetZone(
            "coords",
            "rtxdjlocation" .. locationId,
            locationData.coords,
            0.0, Config.DjMenuMaxOpenDistance,
            Language[Config.Language].djmenu,
            Config.TargetIcons.djicon,
            "rtx_dj:Global:OpenMenuTarget"
        )
    end
end)

RegisterNetEvent("rtx_dj:Global:RemoveDjLocationClient")
AddEventHandler("rtx_dj:Global:RemoveDjLocationClient", function(locationId)
    local location = Config.DjLocations[locationId]
    if not location then return end
    location.edit  = true

    CleanupLocationEffects(location)

    Citizen.Wait(1500)

    Config.DjLocations[locationId] = nil

    if Config.Target then
        local zoneName = "rtxdjlocation" .. locationId
        if Config.Targettype == "qtarget" then
            exports[Config.TargetSystemsNames.qtarget]:RemoveZone(zoneName)
        elseif Config.Targettype == "qbtarget" then
            exports[Config.TargetSystemsNames.qbtarget]:RemoveZone(zoneName)
        elseif Config.Targettype == "oxtarget" then
            exports[Config.TargetSystemsNames.oxtarget]:removeZone(zoneName)
        end
    end
end)

RegisterNetEvent("rtx_dj:Notify")
AddEventHandler("rtx_dj:Notify", function(text)
    Notify(text)
end)

RegisterNetEvent("rtx_dj:CloseMenuEdit")
AddEventHandler("rtx_dj:CloseMenuEdit", function()
    if not menuOpen then return end
    SendNUIMessage({ message = "closedjmenu" })
    SetNuiFocus(false, false)
    menuOpen = false
end)

-- ─── Effect Cleanup Helper ────────────────────────────────────────────────────
-- Used by UpdateDjLocation and RemoveDjLocationClient

function CleanupLocationEffects(location)
    if location.lights.enabled then
        for _, light in ipairs(location.lights.locations) do
            if DoesEntityExist(light.handler)     then DeleteEntity(light.handler) end
            if DoesEntityExist(light.handlermain) then DeleteEntity(light.handlermain) end
            light.handler     = nil
            light.handlermain = nil
        end
    end

    if location.smoke.enabled then
        for _, smoke in ipairs(location.smoke.locations) do
            if DoesParticleFxLoopedExist(smoke.handler2) then StopParticleFxLooped(smoke.handler2, 0) end
            if DoesEntityExist(smoke.handler)             then DeleteEntity(smoke.handler) end
            smoke.handler  = nil
            smoke.handler2 = nil
        end
    end

    if location.lasers.enabled then
        for _, laser in ipairs(location.lasers.locations) do
            if DoesEntityExist(laser.handler2)   then DeleteEntity(laser.handler2) end
            if DoesEntityExist(laser.handler)     then DeleteEntity(laser.handler) end
            if DoesEntityExist(laser.handlermain) then DeleteEntity(laser.handlermain) end
            laser.handler2    = nil
            laser.handler     = nil
            laser.handlermain = nil
        end
    end

    if location.particles.enabled then
        for _, particle in ipairs(location.particles.locations) do
            if DoesParticleFxLoopedExist(particle.handler2) then StopParticleFxLooped(particle.handler2, 0) end
            if DoesEntityExist(particle.handler)             then DeleteEntity(particle.handler) end
            particle.handler  = nil
            particle.handler2 = nil
        end
    end
end

-- ─── Proximity / Interaction Thread ──────────────────────────────────────────

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local interactionAllowed  = true
        local markerShouldDraw    = false
        local menuShouldOpen      = false
        local markerLocationId    = -1
        local closestMenuDist     = -1
        local closestMenuLocation = nil
        local playerPos           = GetEntityCoords(PlayerPedId())

        if Config and Config.DjLocations then
            for locId, location in pairs(Config.DjLocations) do
                local dist = #(playerPos - location.coords)

                -- Check if within menu-open range
                if Config.DjMenuMaxOpenDistance and dist < Config.DjMenuMaxOpenDistance and (closestMenuDist == -1 or dist < closestMenuDist) then
                    closestMenuDist     = dist
                    menuShouldOpen      = true
                    closestMenuLocation = locId
                end

                -- Check if within marker-draw range
                if Config.DjLocationMarker and Config.DjLocationMarker.enabled then
                    if dist < Config.DjLocationMarker.markerdistance and (markerLocationId == -1 or dist < markerLocationId) then
                        markerLocationId  = locId
                        markerShouldDraw  = true
                    end
                end
            end
        end

        -- Draw marker
        if markerShouldDraw and not menuOpen and not creatorOpen then
            local loc = Config.DjLocations[markerLocationId] or Config.DjLocations[closestMenuLocation]
            if loc then
                interactionAllowed = false
                local m = Config.DjLocationMarker
                DrawMarker(m.markertype, loc.coords.x, loc.coords.y, loc.coords.z,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    m.markersize.x, m.markersize.y, m.markersize.z,
                    m.markercolor.r, m.markercolor.g, m.markercolor.b, 100,
                    false, true, 2, false, nil, nil, false)
            end
        end

        -- Show interaction prompt
        if menuShouldOpen and not menuOpen and not creatorOpen then
            local loc = Config.DjLocations[closestMenuLocation]
            nearbyLocationId  = closestMenuLocation
            interactionAllowed = false

            if not Config.Target then
                local style = Config.DjInteractionSystem
                if style == 1 then
                    SendNUIMessage({
                        message        = "infonotifyshow",
                        infonotifytext = Language[Config.Language].pressfordjinteract,
                    })
                elseif style == 2 then
                    DrawText3D(loc.coords.x, loc.coords.y, loc.coords.z, Language[Config.Language].pressfordj)
                elseif style == 3 then
                    ShowGtaClassicInteraction(Language[Config.Language].pressfordjinteractclassic)
                end
            end
        else
            if nearbyLocationId ~= nil and Config.DjInteractionSystem == 1 then
                SendNUIMessage({ message = "hidenotify" })
            end
            nearbyLocationId = nil
        end

        if interactionAllowed then
            Citizen.Wait(1000)
        end
    end
end)

-- ─── DUI / Sound Attenuation Thread ───────────────────────────────────────────

RegisterNUICallback("readyyt", function(data, cb)
    if IsDuiAvailable(duiHandle) then
        duiReady = true
    end
    cb("ok")
end)

local duiInitialized = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(soundTickInterval)

        local outOfRange = true
        local playerPos  = GetEntityCoords(PlayerPedId())

        if not duiInitialized then
            duiInitialized = true
            duiReady       = false
            local resourceUrl = "https://cfx-nui-" .. GetCurrentResourceName() .. "/html/dj/video.html"
            duiHandle = CreateDui(resourceUrl, 100, 100)
        end

        if duiReady and Config and Config.DjLocations then
            for locId, location in pairs(Config.DjLocations) do
                if GetLocationGlobalState(locId, "-playing") then
                    local withinRange = IsPlayerNearCoords(playerPos, location.coords, location.maxdistance + 10.0)
                    if withinRange then outOfRange = false end

                    local linkChanged = false
                    local currentLink = activeSoundLinks[locId]
                    local globalLink  = GetLocationGlobalState(locId, "-linkdata")

                    if currentLink == nil then
                        activeSoundLinks[locId] = globalLink
                        activeSoundTypes[locId] = GetLocationGlobalState(locId, "-typedata")
                    elseif currentLink ~= globalLink then
                        activeSoundLinks[locId] = globalLink
                        linkChanged = true
                    end

                    -- Check for pending reset flag
                    if pendingReset[locId] ~= nil then
                        linkChanged = true
                        pendingReset[locId] = nil
                        activeSoundLinks[locId] = GetLocationGlobalState(locId, "-linkdata")
                    end

                    local dist   = #(playerPos - location.coords)
                    local radius = GetLocationGlobalState(locId, "-currentdistance") or 50.0
                    local volume = GetLocationGlobalState(locId, "-currentvolume")   or 100

                    local soundType    = location.soundtype
                    local outOfHearing = dist >= radius or streamerMode or volume == 0

                    if outOfHearing then
                        locationVolumes[locId] = 0
                        SendDuiMessage(duiHandle, json.encode({
                            message       = "playmusic",
                            djlocation    = locId,
                            soundsrc      = GetLocationGlobalState(locId, "-linkdata"),
                            soundvolume   = 0,
                            soundcategory = GetLocationGlobalState(locId, "-typedata"),
                            soundduration = GetLocationGlobalState(locId, "-currentdurationdata"),
                            resetplayer   = linkChanged,
                        }))
                    else
                        local targetVol = calcAttenuatedVolume(dist, soundMinDistance, radius, volume, soundType, quadraticFalloffExp, expoFalloffAlpha, attenuationCutoff)
                        if targetVol < 0   then targetVol = 0   end
                        if targetVol > 100 then targetVol = 100 end

                        if locationVolumes[locId] == nil or linkChanged then
                            locationVolumes[locId] = targetVol
                        elseif targetVol == 0 then
                            locationVolumes[locId] = 0
                        else
                            locationVolumes[locId] = math.floor(Lerp(locationVolumes[locId], targetVol, volumeLerpSpeed) + 0.5)
                        end

                        SendDuiMessage(duiHandle, json.encode({
                            message        = "playmusic",
                            djlocation     = locId,
                            soundsrc       = GetLocationGlobalState(locId, "-linkdata"),
                            soundvolume    = locationVolumes[locId],
                            soundcategory  = GetLocationGlobalState(locId, "-typedata"),
                            soundduration  = GetLocationGlobalState(locId, "-currentdurationdata"),
                            resetplayer    = linkChanged,
                            resetcategory  = activeSoundTypes[locId],
                        }))
                    end

                    if linkChanged then
                        activeSoundTypes[locId] = GetLocationGlobalState(locId, "-typedata")
                        Citizen.Wait(100)
                        -- ⚠️ Original code references `u` here (appears to be a decompiler artifact);
                        --    based on context this should be `locId` (the current location ID)
                        SendDuiMessage(duiHandle, json.encode({
                            message       = "changeduration",
                            djlocation    = locId,
                            soundduration = GetLocationGlobalState(locId, "-currentdurationdata"),
                            soundcategory = activeSoundTypes[locId],
                        }))
                    end
                else
                    -- Location stopped playing: clear local tracking
                    activeSoundLinks[locId] = nil
                    locationVolumes[locId]  = nil
                end
            end
        end

        if outOfRange then
            Citizen.Wait(1000)
        end
    end
end)

-- ─── DUI Alive Watchdog ────────────────────────────────────────────────────────

RegisterNUICallback("alive", function(data, cb)
    lastAliveTimestamp = GetGameTimer()
    cb({ ok = true })
end)

function ResetDui()
    print("[rtx_dj] no alive signal -> reset ui")
    if duiHandle then
        DestroyDui(duiHandle)
        duiHandle = nil
    end
    duiReady       = false
    duiInitialized = false  -- allow the sound thread to recreate the DUI on next tick
    Wait(100)
    local resourceUrl = "https://cfx-nui-" .. GetCurrentResourceName() .. "/html/dj/video.html"
    duiHandle = CreateDui(resourceUrl, 100, 100)
    duiInitialized = true
end

lastAliveTimestamp = GetGameTimer()
CreateThread(function()
    while true do
        Wait(aliveCheckInterval)
        if (GetGameTimer() - lastAliveTimestamp) > aliveTimeoutMs then
            if duiReady then
                lastAliveTimestamp = GetGameTimer()
                ResetDui()
            end
        end
    end
end)

-- ─── Model Load Helper ────────────────────────────────────────────────────────

function LoadModel(modelName)
    local hash = type(modelName) == "string" and GetHashKey(modelName) or modelName
    if not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash)       then return true  end

    RequestModel(hash)
    local deadline = GetGameTimer() + 4000
    while true do
        if HasModelLoaded(hash)  then break end
        if GetGameTimer() > deadline then break end
        Citizen.Wait(0)
    end
    return HasModelLoaded(hash)
end

function PinInteriorForCoords(coords, timeout)
    local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interior == 0 then return interior end

    if IsValidInterior(interior) then
        PinInteriorInMemory(interior)
        local deadline = GetGameTimer() + (timeout or 2000)
        while true do
            if IsInteriorReady(interior) then break end
            if GetGameTimer() > deadline  then break end
            Citizen.Wait(0)
        end
    end
    return interior
end

function SetEntityInInterior(entity, coords)
    if not DoesEntityExist(entity) then return end
    local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interior == 0 or not IsValidInterior(interior) then return end

    local room = 0
    local playerPed = PlayerPedId()
    if GetInteriorFromEntity(playerPed) == interior then
        local key = GetRoomKeyFromEntity(playerPed)
        if key and key ~= 0 then
            local idx = GetInteriorRoomIndexByHash(interior, key)
            if idx and idx >= 0 then room = idx end
        end
    end

    ForceRoomForEntity(entity, interior, room)
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
    UnpinInterior(interior)
end

-- ─── Effect Spawn Thread ──────────────────────────────────────────────────────
-- Spawns / despawns prop entities for lights, lasers, smoke, particles
-- as players move within effectSpawnDistance of each DJ location.

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        local needsSlowTick = false
        local playerPos     = GetEntityCoords(PlayerPedId())

        if Config and Config.DjLocations then
            for locId, location in pairs(Config.DjLocations) do
                if not IsPlayerNearCoords(playerPos, location.coords, effectSpawnDistance) then
                    goto continue
                end

            if location.edit then goto continue end

            -- ── Lights ──
            if location.lights.enabled then
                for _, light in ipairs(location.lights.locations) do
                    if not IsPlayerNearCoords(playerPos, light.coords, effectSpawnDistance) then goto skipLight end
                    if creatorOpen then goto skipLight end

                    needsSlowTick = false
                    if not DoesEntityExist(light.handlermain) then
                        if LoadModel("prop_cs_burger_01") then
                            local interior = PinInteriorForCoords(light.coords)
                            light.handlermain = CreateObjectNoOffset(GetHashKey("prop_cs_burger_01"), light.coords.x, light.coords.y, light.coords.z, false, true, true)
                            SetEntityRotation(light.handlermain, light.rotation.x, light.rotation.y, light.rotation.z)
                            FreezeEntityPosition(light.handlermain, true)
                            SetEntityVisible(light.handlermain, false)
                            SetEntityCollision(light.handlermain, false, false)
                            SetEntityInInterior(light.handlermain, light.coords)
                            SetModelAsNoLongerNeeded(GetHashKey("prop_cs_burger_01"))
                        end
                    end

                    if DoesEntityExist(light.handlermain) and not DoesEntityExist(light.handler) then
                        if LoadModel("prop_spot_clamp_02") then
                            PinInteriorForCoords(light.coords)
                            light.handler = CreateObjectNoOffset(GetHashKey("prop_spot_clamp_02"), light.coords.x, light.coords.y, light.coords.z, false, true, true)
                            SetEntityRotation(light.handler, light.rotation.x, light.rotation.y, light.rotation.z)
                            FreezeEntityPosition(light.handler, true)
                            SetEntityInInterior(light.handler, light.coords)
                            if DoesEntityExist(light.handlermain) then
                                AttachEntityToEntity(light.handler, light.handlermain, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                            end
                            SetModelAsNoLongerNeeded(GetHashKey("prop_spot_clamp_02"))
                        end
                    end

                    -- Apply light color or disable based on GlobalState
                    if DoesEntityExist(light.handler) then
                        local lightsOnState = GetLocationGlobalState(locId, "-lights")
                        if lightsOnState then
                            local col = GetLocationGlobalState(locId, "-lightscolor") or {r=255,g=255,b=255}
                            SetObjectLightColor(light.handler, 1, col.r, col.g, col.b)
                            SetEntityLights(light.handler, false)
                        else
                            SetEntityLights(light.handler, true)
                        end
                    end

                    ::skipLight::
                end
            end

            -- ── Lasers ──
            if location.lasers.enabled then
                for _, laser in ipairs(location.lasers.locations) do
                    if not IsPlayerNearCoords(playerPos, laser.coords, effectSpawnDistance) then goto skipLaser end
                    if creatorOpen then goto skipLaser end

                    needsSlowTick = false
                    if not DoesEntityExist(laser.handlermain) then
                        if LoadModel("prop_cs_burger_01") then
                            laser.handlermain = CreateObjectNoOffset(GetHashKey("prop_cs_burger_01"), laser.coords.x, laser.coords.y, laser.coords.z, false, true, true)
                            SetEntityRotation(laser.handlermain, laser.rotation.x, laser.rotation.y, laser.rotation.z)
                            FreezeEntityPosition(laser.handlermain, true)
                            SetEntityVisible(laser.handlermain, false)
                            SetEntityCollision(laser.handlermain, false, false)
                            SetEntityInInterior(laser.handlermain, laser.coords)
                            SetModelAsNoLongerNeeded(GetHashKey("prop_cs_burger_01"))
                        end
                    end

                    if DoesEntityExist(laser.handlermain) and not DoesEntityExist(laser.handler) then
                        if LoadModel("prop_spot_clamp") then
                            PinInteriorForCoords(laser.coords)
                            laser.handler = CreateObjectNoOffset(GetHashKey("prop_spot_clamp"), laser.coords.x, laser.coords.y, laser.coords.z, false, true, true)
                            SetEntityRotation(laser.handler, laser.rotation.x, laser.rotation.y, laser.rotation.z)
                            FreezeEntityPosition(laser.handler, true)
                            SetEntityInInterior(laser.handler, laser.coords)
                            if DoesEntityExist(laser.handlermain) then
                                AttachEntityToEntity(laser.handler, laser.handlermain, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                            end
                            SetModelAsNoLongerNeeded(GetHashKey("prop_spot_clamp"))
                        end
                    end

                    if DoesEntityExist(laser.handler) and not DoesEntityExist(laser.handler2) then
                        if LoadModel("rtx_djn_laser_box_dj_system") then
                            PinInteriorForCoords(laser.coords)
                            laser.handler2 = CreateObjectNoOffset(GetHashKey("rtx_djn_laser_box_dj_system"), laser.coords.x, laser.coords.y, laser.coords.z, false, true, true)
                            SetEntityRotation(laser.handler2, laser.rotation.x, laser.rotation.y, laser.rotation.z)
                            FreezeEntityPosition(laser.handler2, true)
                            SetEntityInInterior(laser.handler2, laser.coords)
                            AttachEntityToEntity(laser.handler2, laser.handler, 0, 0.0, 0.0, -0.1, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                            SetModelAsNoLongerNeeded(GetHashKey("rtx_djn_laser_box_dj_system"))
                        end
                    end

                    ::skipLaser::
                end
            end

            -- ── Smoke ──
            if location.smoke.enabled then
                for _, smoke in ipairs(location.smoke.locations) do
                    if not IsPlayerNearCoords(playerPos, smoke.coords, effectSpawnDistance) then goto skipSmoke end

                    local smokeOn = GetLocationGlobalState(locId, "-smoke")
                    if smokeOn and not creatorOpen then
                        needsSlowTick = false
                        if not DoesEntityExist(smoke.handler) then
                            if LoadModel("h4_prop_club_smoke_machine") then
                                PinInteriorForCoords(smoke.coords)
                                smoke.handler = CreateObjectNoOffset(GetHashKey("h4_prop_club_smoke_machine"), smoke.coords.x, smoke.coords.y, smoke.coords.z, false, true, true)
                                SetEntityRotation(smoke.handler, smoke.rotation.x, smoke.rotation.y, smoke.rotation.z)
                                FreezeEntityPosition(smoke.handler, true)
                                SetEntityVisible(smoke.handler, true)
                                SetEntityInInterior(smoke.handler, smoke.coords)
                                SetModelAsNoLongerNeeded(GetHashKey("h4_prop_club_smoke_machine"))
                            end
                        end

                        if DoesEntityExist(smoke.handler) then
                            if not DoesParticleFxLoopedExist(smoke.handler2) then
                                SetWindSpeed(0.0)
                                SetWindDirection(0.0)
                                RequestNamedPtfxAsset("scr_ar_planes")
                                while not HasNamedPtfxAssetLoaded("scr_ar_planes") do
                                    Citizen.Wait(5)
                                    RequestNamedPtfxAsset("scr_ar_planes")
                                end
                                SetPtfxAssetNextCall("scr_ar_planes")
                                smoke.handler2 = StartParticleFxLoopedOnEntity("scr_ar_trail_smoke", smoke.handler, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                            end
                            -- Keep colour synced from GlobalState
                            if DoesParticleFxLoopedExist(smoke.handler2) then
                                local col = GetLocationGlobalState(locId, "-smokecolor") or {r=255,g=255,b=255}
                                SetParticleFxLoopedColour(smoke.handler2, col.r / 255.0, col.g / 255.0, col.b / 255.0, 0)
                                SetParticleFxLoopedAlpha(smoke.handler2, 0.1)
                            end
                        end
                    else
                        -- Smoke toggled off: clean up
                        if DoesParticleFxLoopedExist(smoke.handler2) then StopParticleFxLooped(smoke.handler2, 0) end
                        if DoesEntityExist(smoke.handler) then DeleteEntity(smoke.handler) end
                        smoke.handler  = nil
                        smoke.handler2 = nil
                    end

                    ::skipSmoke::
                end
            end

            -- ── Particles (flamethrower type) ──
            if location.particles.enabled then
                for _, particle in ipairs(location.particles.locations) do
                    if not IsPlayerNearCoords(playerPos, particle.coords, effectSpawnDistance) then goto skipParticle end

                    local particleOn = GetLocationGlobalState(locId, "-particles")
                    if particleOn and not creatorOpen then
                        needsSlowTick = false
                        if not DoesEntityExist(particle.handler) then
                            if LoadModel("prop_cs_burger_01") then
                                PinInteriorForCoords(particle.coords)
                                particle.handler = CreateObjectNoOffset(GetHashKey("prop_cs_burger_01"), particle.coords.x, particle.coords.y, particle.coords.z, false, true, true)
                                SetEntityRotation(particle.handler, particle.rotation.x, particle.rotation.y, particle.rotation.z)
                                FreezeEntityPosition(particle.handler, true)
                                SetEntityVisible(particle.handler, false)
                                SetEntityInInterior(particle.handler, particle.coords)
                                SetModelAsNoLongerNeeded(GetHashKey("prop_cs_burger_01"))
                            end
                        end

                        if DoesEntityExist(particle.handler) and not DoesParticleFxLoopedExist(particle.handler2) then
                            SetWindSpeed(0.0)
                            SetWindDirection(0.0)
                            RequestNamedPtfxAsset(particle.animdict)
                            while not HasNamedPtfxAssetLoaded(particle.animdict) do
                                Citizen.Wait(5)
                                RequestNamedPtfxAsset(particle.animdict)
                            end
                            SetPtfxAssetNextCall(particle.animdict)
                            particle.handler2 = StartParticleFxLoopedOnEntity(particle.animname, particle.handler, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 0.25, false, false, false, false)
                        end
                    else
                        -- Particles toggled off: clean up
                        if DoesParticleFxLoopedExist(particle.handler2) then StopParticleFxLooped(particle.handler2, 0) end
                        if DoesEntityExist(particle.handler) then DeleteEntity(particle.handler) end
                        particle.handler  = nil
                        particle.handler2 = nil
                    end

                    ::skipParticle::
                end
            end

            ::continue::
        end
        end

        if needsSlowTick then Citizen.Wait(1000) end
    end
end)

-- ─── DrawLaserBeam ────────────────────────────────────────────────────────────
-- Draws a fan of lines from a laser entity to simulate a beam cone.
-- (cols, rows, spreadX, spreadZ, offsetY)

function DrawLaserBeam(entity, color, cols, rows, spreadX, spreadZ, offsetY, baseOffsetY)
    if not DoesEntityExist(entity) then return end

    cols    = math.max(1, cols    or 9)
    rows    = math.max(1, rows    or 1)
    spreadX = spreadX or 35.0
    spreadZ = spreadZ or 6.0
    offsetY = offsetY or 0.0
    baseOffsetY = baseOffsetY or -0.15

    local origin = GetOffsetFromEntityInWorldCoords(entity, 0.0, baseOffsetY, 0.0)

    local function normalizedPosition(index, count)
        if count <= 1 then return 0.0 end
        return ((index - 1) / (count - 1) - 0.5) * 2.0
    end

    for row = 1, rows do
        local rowT  = normalizedPosition(row, rows)
        local rowZ  = rowT * offsetY

        for col = 1, cols do
            local colT  = normalizedPosition(col, cols)
            local colX  = colT * spreadX
            local tip   = GetOffsetFromEntityInWorldCoords(entity, colX, -spreadZ, rowZ)

            local r = (color and color.r) or 255
            local g = (color and color.g) or 255
            local b = (color and color.b) or 255
            DrawLine(origin.x, origin.y, origin.z, tip.x, tip.y, tip.z, r, g, b, 255)
        end
    end
end

-- ─── Light / Laser Animation Thread ──────────────────────────────────────────
-- Swings light/laser entities back and forth when the move flag is enabled.

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local frameTime = GetFrameTime()
        local playerPos = GetEntityCoords(PlayerPedId())
        local slowTick  = true

        if Config and Config.DjLocations then
            for locId, location in pairs(Config.DjLocations) do
                if not IsPlayerNearCoords(playerPos, location.coords, effectSpawnDistance) then
                    goto continue
                end

            -- Lights swing animation
            if location.lights.enabled then
                local lightsOn   = GetLocationGlobalState(locId, "-lights")
                local lightsMove = GetLocationGlobalState(locId, "-lightsmove")
                local lightsColor = GetLocationGlobalState(locId, "-lightscolor")

                if lightsOn then
                    swingState.lights[locId] = swingState.lights[locId] or {}

                    for idx, light in ipairs(location.lights.locations) do
                        if IsPlayerNearCoords(playerPos, light.coords, effectSpawnDistance) then
                            slowTick = false
                        end

                        if DoesEntityExist(light.handler) then
                            if lightsMove then
                                -- Initialise per-entity swing state
                                if not swingState.lights[locId][idx] then
                                    swingState.lights[locId][idx] = { base = 0.0, off = 0.0, dir = 1, spd = lightSwingSpeed }
                                end
                                local s = swingState.lights[locId][idx]

                                s.off = s.off + s.dir * s.spd * frameTime
                                if s.off >= swingAngleMax  then s.off = swingAngleMax;  s.dir = -1 end
                                if s.off <= -swingAngleMax then s.off = -swingAngleMax; s.dir =  1 end

                                AttachEntityToEntity(light.handler, light.handlermain, 0, 0.0, 0.0, 0.0, 0.0, 0.0, s.base + s.off, false, false, false, false, 5, true)
                            else
                                -- Reset to base
                                if swingState.lights[locId] and swingState.lights[locId][idx] then
                                    swingState.lights[locId][idx] = nil
                                end
                                AttachEntityToEntity(light.handler, light.handlermain, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                            end
                        end
                    end
                else
                    if swingState.lights[locId] then
                        for idx, light in ipairs(location.lights.locations) do
                            if DoesEntityExist(light.handler) then
                                AttachEntityToEntity(light.handler, light.handlermain, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                            end
                        end
                        swingState.lights[locId] = nil
                    end
                end
            end

            -- Lasers: draw beams + optional swing
            if location.lasers.enabled then
                local lasersOn    = GetLocationGlobalState(locId, "-lasers")

                if lasersOn then
                    swingState.lasers[locId] = swingState.lasers[locId] or {}

                    for idx, laser in ipairs(location.lasers.locations) do
                        if not IsPlayerNearCoords(playerPos, laser.coords, effectSpawnDistance) then goto skipLaser end
                        slowTick = false

                        if DoesEntityExist(laser.handler) then
                            local laserColor = GetLocationGlobalState(locId, "-laserscolor")
                            DrawLaserBeam(laser.handler2, laserColor, 11, 1, 30.0, 7.5, 0.0, -0.15)

                            if GetLocationGlobalState(locId, "-lasersmove") then
                                if not swingState.lasers[locId][idx] then
                                    swingState.lasers[locId][idx] = { base = 0.0, off = 0.0, dir = 1, spd = laserSwingSpeed }
                                end
                                local s = swingState.lasers[locId][idx]

                                s.off = s.off + s.dir * s.spd * frameTime
                                if s.off >= swingAngleMax  then s.off = swingAngleMax;  s.dir = -1 end
                                if s.off <= -swingAngleMax then s.off = -swingAngleMax; s.dir =  1 end

                                AttachEntityToEntity(laser.handler, laser.handlermain, 0, 0.0, 0.0, 0.0, 0.0, 0.0, s.base + s.off, false, false, false, false, 5, true)
                            end
                        else
                            if swingState.lasers[locId] and swingState.lasers[locId][idx] then
                                swingState.lasers[locId][idx] = nil
                            end
                        end

                        ::skipLaser::
                    end
                else
                    if swingState.lasers[locId] then
                        for _, laser in ipairs(location.lasers.locations) do
                            if DoesEntityExist(laser.handler) then
                                AttachEntityToEntity(laser.handler, laser.handlermain, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                            end
                        end
                        swingState.lasers[locId] = nil
                    end
                end
            end

            ::continue::
        end
        end

        if slowTick then Citizen.Wait(1000) end
    end
end)

-- ─── Open-Menu Command / Key Binding ─────────────────────────────────────────

if not Config.Target then
    RegisterCommand("rtxdjmenu", function()
        if nearbyLocationId ~= nil and not menuOpen and not creatorOpen then
            TriggerServerEvent("rtx_dj:Global:OpenMenu", nearbyLocationId)
        end
    end)
    local menuLabel = (Language and Config and Language[Config.Language] and Language[Config.Language].djmenu) or "MENU DJ"
    local openKey   = (Config and Config.DjOpenKey) or "E"
    RegisterKeyMapping("rtxdjmenu", menuLabel, "keyboard", openKey)
else
    RegisterNetEvent("rtx_dj:Global:OpenMenuTarget")
    AddEventHandler("rtx_dj:Global:OpenMenuTarget", function()
        if nearbyLocationId ~= nil and not menuOpen and not creatorOpen then
            TriggerServerEvent("rtx_dj:Global:OpenMenu", nearbyLocationId)
        end
    end)
end

-- ─── Creator Freecam (always registered, used only when creator is enabled) ───

function DisableControlscreator()
    local controls = { 0, 1, 2, 16, 17, 22, 23, 24, 25, 26, 36, 37, 44, 47, 55, 69, 81, 82, 91, 92, 99, 106, 114, 115, 121, 122, 135, 140, 142, 199, 200, 245, 257, 30, 31 }
    for _, id in ipairs(controls) do
        DisableControlAction(0, id, true)
    end
end

function SetupCreatorFreecam()
    TriggerEvent("rtx_housing:Global:EnterFreecam")

    local ped      = PlayerPedId()
    local pedPos   = GetEntityCoords(ped)
    local camRot   = GetGameplayCamRot(2)

    freecamPosition = vector3(pedPos.x, pedPos.y, pedPos.z + 5.5)
    freecamRotation = vector3(camRot.x, camRot.y, camRot.z)

    freecamHandle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(freecamHandle, freecamPosition.x, freecamPosition.y, freecamPosition.z)
    SetCamRot(freecamHandle, freecamRotation.x, freecamRotation.y, freecamRotation.z, 2)
    SetCamFov(freecamHandle, GetGameplayCamFov())
    SetCamActive(freecamHandle, true)
    RenderScriptCams(true, true, 500, true, true)
    FreezeEntityPosition(ped, true)
end

function DestroyCreatorFreecam()
    local ped = PlayerPedId()
    ClearFocus()

    if freecamHandle then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(freecamHandle, false)
        DestroyCam(freecamHandle, false)
        freecamHandle = nil
    end

    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)
    FreezeEntityPosition(ped, false)
end

function IsControlAlwaysPressed(inputGroup, control)
    return IsControlPressed(inputGroup, control) or IsDisabledControlPressed(inputGroup, control)
end

function RunCreatorFreecamThread()
    Citizen.CreateThread(function()
        while freecamHandle and freecamPosition and freecamRotation do
            DisableControlscreator()

            if IsDisabledControlPressed(0, 25) or IsControlPressed(0, 25) then
                local mouseX  = GetDisabledControlNormal(0, 220)
                local mouseY  = GetDisabledControlNormal(0, 221)
                local lookX   = GetDisabledControlNormal(0, 1)
                local lookY   = GetDisabledControlNormal(0, 2)

                local yawDelta   = -freecamSpeedMed * mouseX + (-freecamSpeedMed * lookX * 8.0)
                local pitchDelta = -freecamSpeedFast * mouseY + (-freecamSpeedFast * lookY * 8.0)

                local newPitch  = Clamp(freecamRotation.x + pitchDelta, freecamPitchMin, freecamPitchMax)
                local newYaw    = freecamRotation.z + yawDelta
                freecamRotation = vector3(newPitch, freecamRotation.y, newYaw)
            end

            -- Movement speed modifiers (Shift = fast, Ctrl = medium, Alt = slow)
            local speed = freecamSpeedBase
            if IsControlAlwaysPressed(0, 21) then speed = speed * 2.0
            elseif IsControlAlwaysPressed(0, 19) then speed = speed * 4.0
            elseif IsControlAlwaysPressed(0, 36) then speed = speed * 0.25 end

            local dt     = GetFrameTime()
            local step   = speed * dt * 10.0
            local yawRad   = math.rad(freecamRotation.z)
            local pitchRad = math.rad(freecamRotation.x)

            local forward = vector3(-math.sin(yawRad) * math.cos(pitchRad), math.cos(yawRad) * math.cos(pitchRad), math.sin(pitchRad))
            local right   = vector3(math.cos(yawRad), math.sin(yawRad), 0.0)
            local up      = vector3(0.0, 0.0, 1.0)

            if IsControlAlwaysPressed(0, 32) then freecamPosition = freecamPosition + forward * step end
            if IsControlAlwaysPressed(0, 33) then freecamPosition = freecamPosition - forward * step end
            if IsControlAlwaysPressed(0, 34) then freecamPosition = freecamPosition - right   * step end
            if IsControlAlwaysPressed(0, 35) then freecamPosition = freecamPosition + right   * step end
            if IsControlAlwaysPressed(0, 44) then freecamPosition = freecamPosition - up      * step end
            if IsControlAlwaysPressed(0, 38) then freecamPosition = freecamPosition + up      * step end

            SetCamCoord(freecamHandle, freecamPosition.x, freecamPosition.y, freecamPosition.z)
            SetCamRot(freecamHandle, freecamRotation.x, freecamRotation.y, freecamRotation.z, 2)

            Citizen.Wait(0)
        end
    end)
end

function ToggleCreatorFreecam(enable)
    if enable == nil then enable = freecamActive end
    freecamActive = enable
    if enable then
        SetupCreatorFreecam()
        RunCreatorFreecamThread()
    else
        DestroyCreatorFreecam()
    end
    SetUserRadioControlEnabled(not enable)
end

-- ─── In-Game Creator System ───────────────────────────────────────────────────

if Config.InGameDjCreator then

    -- Helpers for serialising vector3/rotation values for NUI transfer

    function SerialiseCoords(v)
        return { x = v.x + 0.0, y = v.y + 0.0, z = v.z + 0.0 }
    end

    function SerialiseRotation(v)
        return {
            x = v and (v.x + 0.0) or 0.0,
            y = v and (v.y + 0.0) or 0.0,
            z = v and (v.z + 0.0) or 0.0,
        }
    end

    function SerialiseLocationList(rawLocations)
        local out = {}
        for _, loc in ipairs(rawLocations or {}) do
            out[#out + 1] = {
                id       = loc.id or #out + 1,
                coords   = SerialiseCoords(loc.coords),
                rotation = SerialiseRotation(loc.rotation),
            }
        end
        return out
    end

    function SerialiseParticleList(rawLocations)
        local out = {}
        for _, loc in ipairs(rawLocations or {}) do
            out[#out + 1] = {
                id       = loc.id or #out + 1,
                coords   = SerialiseCoords(loc.coords),
                rotation = SerialiseRotation(loc.rotation),
                animdict = loc.animdict,
                animname = loc.animname,
            }
        end
        return out
    end

    function BuildEditableLocationsList()
        local list = {}
        for locId, location in pairs(Config.DjLocations) do
            if GetLocationGlobalState(locId, "-editable") then
                local entry = {
                    id    = locId,
                    label = location.label or ("Location " .. locId),
                    coords       = location.coords    and SerialiseCoords(location.coords)    or nil,
                    maxdistance  = location.maxdistance or 100.0,
                    soundtype    = location.soundtype   or "linear",
                    lights    = { enabled = location.lights    and location.lights.enabled    or false, locations = {} },
                    smoke     = { enabled = location.smoke     and location.smoke.enabled     or false, locations = {} },
                    lasers    = { enabled = location.lasers    and location.lasers.enabled    or false, locations = {} },
                    particles = { enabled = location.particles and location.particles.enabled or false, locations = {} },
                    permissions = {
                        everyone    = location.permissions and location.permissions.everyone or false,
                        permissions = {},
                    },
                }

                if location.lights    and location.lights.locations    then entry.lights.locations    = SerialiseLocationList(location.lights.locations)    end
                if location.smoke     and location.smoke.locations      then entry.smoke.locations     = SerialiseLocationList(location.smoke.locations)     end
                if location.lasers    and location.lasers.locations     then entry.lasers.locations    = SerialiseLocationList(location.lasers.locations)    end
                if location.particles and location.particles.locations  then entry.particles.locations = SerialiseParticleList(location.particles.locations)  end

                if location.permissions and location.permissions.permissions then
                    for _, perm in ipairs(location.permissions.permissions) do
                        entry.permissions.permissions[#entry.permissions.permissions + 1] = {
                            permissiontype = perm.permissiontype,
                            permission     = perm.permission,
                        }
                    end
                end

                list[#list + 1] = entry
            end
        end
        return list
    end

    function BuildCreatorLocationPayload(id, rawData)
        if not rawData then return nil end

        local payload = {
            id          = rawData.id or id,
            label       = rawData.name or rawData.label or ("Location " .. tostring(id)),
            coords      = SerialiseCoords(rawData.location or rawData.coords or vector3(0, 0, 0)),
            maxdistance = tonumber(rawData.maxDistance or rawData.maxdistance) or 100.0,
            soundtype   = rawData.soundtype or "linear",
            lights    = { enabled = false, locations = {} },
            smoke     = { enabled = false, locations = {} },
            lasers    = { enabled = false, locations = {} },
            particles = { enabled = false, locations = {} },
            permissions = {
                everyone    = rawData.permissions and rawData.permissions.everyone or false,
                permissions = rawData.permissions and rawData.permissions.permissions or {},
            },
        }

        if rawData.lights  then
            payload.lights.enabled   = rawData.lights.enabled  or false
            payload.lights.locations = SerialiseLocationList(rawData.lights.locations or {})
        end
        if rawData.smoke   then
            payload.smoke.enabled    = rawData.smoke.enabled   or false
            payload.smoke.locations  = SerialiseLocationList(rawData.smoke.locations or {})
        end
        if rawData.lasers  then
            payload.lasers.enabled   = rawData.lasers.enabled  or false
            payload.lasers.locations = SerialiseLocationList(rawData.lasers.locations or {})
        end
        if rawData.particles then
            payload.particles.enabled   = rawData.particles.enabled   or false
            payload.particles.locations = SerialiseParticleList(rawData.particles.locations or {})
        end

        return payload
    end

    -- Creator Gizmo integration (DJC = DJ Creator)

    function DJC_GetCamForwardVector(entity)
        if entity and DoesEntityExist(entity) then
            local rot = GetEntityRotation(entity, 2)
            return GetEntityCoords(entity), rot
        end
        local pos = GetFinalRenderedCamCoord()
        local rot = GetFinalRenderedCamRot(2)
        return pos, rot
    end

    function DJC_VecLength(v)
        return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    end

    function DJC_ShapeTestCapsule(startPos, endPos, radius, flags, ignore)
        local handle = StartShapeTestCapsule(
            startPos.x, startPos.y, startPos.z,
            endPos.x,   endPos.y,   endPos.z,
            radius, flags or 511, ignore or 0, 7
        )
        local _, hit, impactPos, _, hitEntity = GetShapeTestResult(handle)
        local blocked   = hit == 1
        local hitCoords = impactPos
        return blocked, hitCoords, hitEntity or 0
    end

    function DJC_GetCinePlacementAlways(camForward, opts)
        opts = opts or {}
        local maxDist      = tonumber(opts.maxDist)      or 12.0
        local fallbackDist = tonumber(opts.fallbackDist) or 6.0
        local radius       = tonumber(opts.radius)       or 0.25
        local placeOnGround = opts.placeOnGround == true

        local camPos, camRot = DJC_GetCamForwardVector(camForward)
        local camLen         = DJC_VecLength(camRot)
        local origin         = camPos + camRot * (camLen * 0.6)
        local target         = origin  + camRot * (camLen * maxDist)

        local hit, hitPos, _ = DJC_ShapeTestCapsule(origin, target, radius, 511, PlayerPedId())

        local placementPos
        if not hit or not hitPos then
            placementPos = origin + camRot * (camLen * fallbackDist)
        else
            placementPos = hitPos - camRot * (camLen * 0.001)
        end

        if placeOnGround then
            local grounded, groundZ = GetGroundZFor_3dCoord(placementPos.x, placementPos.y, placementPos.z, false)
            if grounded then
                placementPos = vector3(placementPos.x, placementPos.y, groundZ)
            end
        end

        return placementPos, camRot.z or 0.0, _
    end

    function GizmoStart(entity)
        creatorSelectedElement = entity
        SendNUIMessage({
            action = "setGizmoEntity",
            data   = {
                handle   = creatorSelectedElement,
                position = GetEntityCoords(creatorSelectedElement),
                rotation = GetEntityRotation(creatorSelectedElement),
            },
        })
    end

    -- Creator preview object spawning helpers

    function SpawnCreatorLight(lightData)
        while not HasModelLoaded(GetHashKey("hei_prop_bank_spotlight_01b")) do
            RequestModel(GetHashKey("hei_prop_bank_spotlight_01b"))
            Citizen.Wait(5)
        end
        if lightData.removeinprogress then return end
        lightData.handler = CreateObjectNoOffset(GetHashKey("hei_prop_bank_spotlight_01b"), lightData.coords.x, lightData.coords.y, lightData.coords.z, false, true, true)
        SetEntityRotation(lightData.handler, lightData.rotation.x, lightData.rotation.y, lightData.rotation.z)
        FreezeEntityPosition(lightData.handler, true)
        SetEntityVisible(lightData.handler, false)
    end

    function SpawnCreatorSmoke(smokeData)
        while not HasModelLoaded(GetHashKey("h4_prop_club_smoke_machine")) do
            RequestModel(GetHashKey("h4_prop_club_smoke_machine"))
            Citizen.Wait(5)
        end
        if smokeData.removeinprogress then return end
        smokeData.handler = CreateObjectNoOffset(GetHashKey("h4_prop_club_smoke_machine"), smokeData.coords.x, smokeData.coords.y, smokeData.coords.z, false, true, true)
        SetEntityRotation(smokeData.handler, smokeData.rotation.x, smokeData.rotation.y, smokeData.rotation.z)
        FreezeEntityPosition(smokeData.handler, true)
        SetEntityVisible(smokeData.handler, true)

        if not DoesParticleFxLoopedExist(smokeData.particlehandler) then
            SetWindSpeed(0.0)
            SetWindDirection(0.0)
            RequestNamedPtfxAsset(smokeData.dict)
            while not HasNamedPtfxAssetLoaded(smokeData.dict) do
                Citizen.Wait(5)
                RequestNamedPtfxAsset(smokeData.dict)
            end
            SetPtfxAssetNextCall(smokeData.dict)
            smokeData.particlehandler = StartParticleFxLoopedOnEntity(smokeData.name, smokeData.handler, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 0.25, false, false, false, false)
        end
    end

    function SpawnCreatorLaser(laserData)
        while not HasModelLoaded(GetHashKey("prop_cs_burger_01")) do
            RequestModel(GetHashKey("prop_cs_burger_01"))
            Citizen.Wait(5)
        end
        if laserData.removeinprogress then return end
        laserData.handler = CreateObjectNoOffset(GetHashKey("prop_cs_burger_01"), laserData.coords.x, laserData.coords.y, laserData.coords.z, false, true, true)
        SetEntityRotation(laserData.handler, laserData.rotation.x, laserData.rotation.y, laserData.rotation.z)
        FreezeEntityPosition(laserData.handler, true)
        SetEntityVisible(laserData.handler, false)

        laserData.handler2 = CreateObjectNoOffset(GetHashKey("prop_cs_burger_01"), laserData.coords.x, laserData.coords.y, laserData.coords.z, false, true, true)
        AttachEntityToEntity(laserData.handler2, laserData.handler, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
        FreezeEntityPosition(laserData.handler2, true)
        SetEntityVisible(laserData.handler2, false)
    end

    function SpawnCreatorParticle(particleData)
        while not HasModelLoaded(GetHashKey("prop_cs_burger_01")) do
            RequestModel(GetHashKey("prop_cs_burger_01"))
            Citizen.Wait(5)
        end
        if particleData.removeinprogress then return end
        particleData.handler = CreateObjectNoOffset(GetHashKey("prop_cs_burger_01"), particleData.coords.x, particleData.coords.y, particleData.coords.z, false, true, true)
        SetEntityRotation(particleData.handler, particleData.rotation.x, particleData.rotation.y, particleData.rotation.z)
        FreezeEntityPosition(particleData.handler, true)
        SetEntityVisible(particleData.handler, false)

        if not DoesParticleFxLoopedExist(particleData.particlehandler) then
            SetWindSpeed(0.0)
            SetWindDirection(0.0)
            RequestNamedPtfxAsset(particleData.dict)
            while not HasNamedPtfxAssetLoaded(particleData.dict) do
                Citizen.Wait(5)
                RequestNamedPtfxAsset(particleData.dict)
            end
            SetPtfxAssetNextCall(particleData.dict)
            particleData.particlehandler = StartParticleFxLoopedOnEntity(particleData.name, particleData.handler, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 0.25, false, false, false, false)
        end
    end

    function CleanupAllCreatorObjects()
        -- Lights
        for _, obj in pairs(creatorLightObjects) do obj.removeinprogress = true end
        Citizen.Wait(50)
        for _, obj in pairs(creatorLightObjects) do
            if DoesEntityExist(obj.handler) then DeleteEntity(obj.handler) end
        end
        creatorLightObjects = {}

        -- Smoke
        for _, obj in pairs(creatorSmokeObjects) do obj.removeinprogress = true end
        Citizen.Wait(50)
        for _, obj in pairs(creatorSmokeObjects) do
            if DoesParticleFxLoopedExist(obj.particlehandler) then StopParticleFxLooped(obj.particlehandler, 0) end
            if DoesEntityExist(obj.handler) then DeleteEntity(obj.handler) end
        end
        creatorSmokeObjects = {}

        -- Lasers
        for _, obj in pairs(creatorLaserObjects) do obj.removeinprogress = true end
        Citizen.Wait(50)
        for _, obj in pairs(creatorLaserObjects) do
            if DoesEntityExist(obj.handler)  then DeleteEntity(obj.handler)  end
            if DoesEntityExist(obj.handler2) then DeleteEntity(obj.handler2) end
        end
        creatorLaserObjects = {}

        -- Particles
        for _, obj in pairs(creatorParticleObjects) do obj.removeinprogress = true end
        Citizen.Wait(50)
        for _, obj in pairs(creatorParticleObjects) do
            if DoesParticleFxLoopedExist(obj.particlehandler) then StopParticleFxLooped(obj.particlehandler, 0) end
            if DoesEntityExist(obj.handler) then DeleteEntity(obj.handler) end
        end
        creatorParticleObjects = {}
    end

    -- Creator NUI Callbacks

    RegisterNUICallback("djcreatorready", function(data, cb)
        SendNUIMessage({
            message    = "creatordata",
            locations  = BuildEditableLocationsList(),
            soundboard = Config.DjSoundBoard,
        })
        cb("ok")
    end)

    RegisterNUICallback("selectlocation", function(data, cb)
        local locId    = tonumber(data.locationid)
        local location = locId and Config.DjLocations[locId]
        if location then
            creatorStartCoords = location.coords
            SendNUIMessage({
                message    = "locationselected",
                locationid = locId,
                data       = BuildCreatorLocationPayload(locId, location),
            })
        end
        cb("ok")
    end)

    RegisterNUICallback("creatorsavelocation", function(data, cb)
        if data and data.name then
            TriggerServerEvent("rtx_dj:Global:CreateDjLocation", data)
            Notify(LanguageFile("locationcreated", tostring(data.name)))
        end
        cb("ok")
    end)

    -- DJ Creator command
    RegisterCommand(Config.InGameCreatorCommand, function()
        if creatorOpen or menuOpen then return end
        TriggerServerEvent("rtx_dj:Global:DjCreator")
    end)

end  -- if Config.InGameDjCreator

-- ─── ESC / Close-Creator Callback ────────────────────────────────────────────

RegisterNUICallback("closemenuesc", function(data, cb)
    if menuOpen then
        SendNUIMessage({ message = "closedjmenu" })
        SetNuiFocus(false, false)
        menuOpen = false
        TriggerServerEvent("rtx_dj:Global:CloseMenu", activeMenuLocationId)
        activeMenuLocationId = nil
    elseif creatorOpen then
        SendNUIMessage({ message = "hidecreator" })
        creatorOpen = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)

        ToggleCreatorFreecam(false)

        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetEntityCoordsNoOffset(ped, creatorStartCoords)
        Citizen.Wait(100)
        FreezeEntityPosition(ped, false)
        SetFocusEntity(PlayerPedId())

        CleanupAllCreatorObjects()
    end
    cb("ok")
end)

-- ─── Streamer Mode ────────────────────────────────────────────────────────────

RegisterCommand(Config.StreamerModeCommand, function()
    if streamerMode then
        streamerMode = false
        Notify(Language[Config.Language].streamerdeactivated)
    else
        streamerMode = true
        Notify(Language[Config.Language].streamerdactivated)
    end
end)

RegisterNetEvent(Config.StreamerModeTriggerEvent)
AddEventHandler(Config.StreamerModeTriggerEvent, function(state)
    if state == nil then
        streamerMode = true
    else
        streamerMode = state
    end
end)

-- ─── In-Game Creator: gizmo state vars ────────────────────────────────────────
-- (only relevant when Config.InGameDjCreator == true)

-- Snap preset tables for translate and rotation
local translateSnapPresets = {}
local rotationSnapPresets  = {}

-- Active gizmo entity and mode flags
local gizmoEntity          = nil   -- entity currently controlled by the gizmo
local gizmoPlacingType     = ""    -- "lights" | "smoke" | "lasers" | "particles" | "location" | ""
local gizmoActive          = false -- gizmo placement session is in progress
local gizmoTransformMode   = false -- true = rotation, false = translate
local gizmoPlacedCoords    = vector3(0.0, 0.0, 0.0)
local gizmoPlacedRotation  = vector3(0.0, 0.0, 0.0)
local previewSmokeParticle = nil   -- particle fx handle for smoke preview
local previewLaserMesh     = nil   -- secondary prop for laser preview

-- Snap level indices (1-based index into preset arrays)
local translateSnapIndex   = 1
local rotationSnapIndex    = 1


-- ─── RoundNumber (global – used by creator gizmo callbacks) ───────────────────

function RoundNumber(value, decimals)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    return math.floor(value * factor + 0.5) / factor
end

-- ─── In-Game Creator NUI Callbacks (Config.InGameDjCreator block) ─────────────

if Config.InGameDjCreator then

    -- Build the full editable-location list and send it to NUI
    function SendLocationsToNui()
        SendNUIMessage({
            message   = "setlocations",
            locations = BuildEditableLocationsList(),
        })
    end

    RegisterNUICallback("requestLocations", function(data, cb)
        SendLocationsToNui()
        cb({ ok = true })
    end)

    RegisterNUICallback("removeLocation", function(data, cb)
        local locId = tonumber(data.id)
        if locId and Config.DjLocations[locId] then
            TriggerServerEvent("rtx_dj:Global:RemoveDjLocation", locId)
            SendLocationsToNui()
            cb({ ok = true })
        else
            cb({ ok = false, error = "invalid id" })
        end
    end)

    -- savecreator: edit an existing location and close the creator
    RegisterNUICallback("savecreator", function(data, cb)
        local locId   = tonumber(data.id)
        local payload = data.data

        if not locId or not payload then
            cb({ ok = false, error = "missing id/data" })
            return
        end

        -- Close the creator and teleport the player back
        creatorOpen = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        ToggleCreatorFreecam(false)

        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetEntityCoordsNoOffset(ped, creatorStartCoords)
        Citizen.Wait(100)
        FreezeEntityPosition(ped, false)
        SetFocusEntity(PlayerPedId())

        CleanupAllCreatorObjects()

        -- Validate payload has name and location before triggering edit
        local hasName     = payload.name     ~= nil
        local hasLocation = type(payload.location) == "table"

        if not hasName or not hasLocation then
            print("^1[DJC] ERROR: Missing name or location.^7")
            cb("error")
            return
        end

        print(string.format("[DJC] Edited location: '%s' @ (%.3f, %.3f, %.3f)",
            tostring(payload.name),
            payload.location.x or 0.0,
            payload.location.y or 0.0,
            payload.location.z or 0.0))

        TriggerServerEvent("rtx_dj:Global:EditDjLocation", locId, payload)
        if Notify then Notify(LanguageFile("locationedited", tostring(payload.name))) end
        cb("ok")
    end)

    -- closecreator: discard changes and exit creator
    RegisterNUICallback("closecreator", function(data, cb)
        if creatorOpen then
            creatorOpen = false
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            ToggleCreatorFreecam(false)

            local ped = PlayerPedId()
            FreezeEntityPosition(ped, true)
            SetEntityCoordsNoOffset(ped, creatorStartCoords)
            Citizen.Wait(100)
            FreezeEntityPosition(ped, false)
            SetFocusEntity(PlayerPedId())

            CleanupAllCreatorObjects()
        end
        cb("ok")
    end)

    -- finishcreator: save a brand-new location and close
    RegisterNUICallback("finishcreator", function(data, cb)
        if not creatorOpen then cb("ok") return end

        creatorOpen = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        ToggleCreatorFreecam(false)

        local ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetEntityCoordsNoOffset(ped, creatorStartCoords)
        Citizen.Wait(100)
        FreezeEntityPosition(ped, false)
        SetFocusEntity(PlayerPedId())

        CleanupAllCreatorObjects()

        local hasName     = data and data.name ~= nil
        local hasLocation = data and type(data.location) == "table"

        if not hasName or not hasLocation then
            print("^1[DJC] ERROR: Missing name or location.^7")
            cb("error")
            return
        end

        print(string.format("[DJC] Creating location: '%s' @ (%.3f, %.3f, %.3f)",
            tostring(data.name),
            data.location.x or 0.0,
            data.location.y or 0.0,
            data.location.z or 0.0))

        TriggerServerEvent("rtx_dj:Global:CreateDjLocation", data)
        if Notify then Notify(LanguageFile("locationcreated", tostring(data.name))) end
        cb("ok")
    end)

    -- ── Gizmo position/rotation change from NUI ──────────────────────────────

    -- Round a raw axis value: use 1 decimal when fractional part is 0, else 3 decimals
    function RoundAxisValue(v)
        local _, frac = math.modf(v)
        if frac == 0 then
            return tonumber(string.format("%.1f", v))
        else
            return RoundNumber(v, 3)
        end
    end

    RegisterNUICallback("gizmo:ChangePosition", function(data, cb)
        if data.handle and gizmoActive and DoesEntityExist(gizmoEntity) then
            local px = RoundAxisValue(data.position.x)
            local py = RoundAxisValue(data.position.y)
            local pz = RoundAxisValue(data.position.z)
            local rx = RoundAxisValue(data.rotation.x)
            local ry = RoundAxisValue(data.rotation.y)  -- usually 0
            local rz = RoundAxisValue(data.rotation.z)

            gizmoPlacedCoords   = vector3(px, py, pz)
            gizmoPlacedRotation = vector3(rx, ry, rz)

            SetEntityCoords(gizmoEntity, px, py, pz)
            SetEntityRotation(gizmoEntity, rx, ry, rz)

            SendNUIMessage({ action = "djc:setPlacement", x = px, y = py, z = pz })
            SendNUIMessage({ action = "djc:setRotation",  x = rx, y = ry, z = rz })
        end
        cb(1)
    end)

    -- ── Gizmo camera-sync + location-marker thread ───────────────────────────

    CreateThread(function()
        while true do
            Wait(0)
            if DoesEntityExist(gizmoEntity) then
                if gizmoActive then
                    SendNUIMessage({
                        action = "setCameraPosition",
                        data   = {
                            position = GetFinalRenderedCamCoord(),
                            rotation = GetFinalRenderedCamRot(),
                        },
                    })

                    -- Draw marker at placed location to preview it
                    if gizmoPlacingType == "location" then
                        DrawMarker(1,
                            gizmoPlacedCoords.x, gizmoPlacedCoords.y, gizmoPlacedCoords.z,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            1.0, 1.0, 1.0,
                            0, 255, 0, 100,
                            false, true, 2, false, nil, nil, false)
                    end
                end

                -- G key (47) toggles translate↔rotate
                DisableControlAction(0, 47, true)
                if IsDisabledControlJustPressed(0, 47) or IsControlJustPressed(0, 47) then
                    gizmoTransformMode = not gizmoTransformMode
                    SendNUIMessage({
                        action = "SetGizmoTransformMode",
                        data   = { transformhandler = gizmoTransformMode },
                    })
                end
            else
                Wait(1000)
            end
        end
    end)

    -- ── locationadd: begin placement of a new effect element ─────────────────

    function BeginGizmoPlacement(elementType, modelName, isWorldSpace)
        if gizmoActive then return end

        gizmoPlacingType = elementType
        gizmoActive      = true

        if DoesEntityExist(gizmoEntity) then DeleteEntity(gizmoEntity) end

        local hash = GetHashKey(modelName)
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            RequestModel(hash)
            Citizen.Wait(5)
        end

        local spawnPos, spawnHeading = DJC_GetCinePlacementAlways(freecamHandle, {
            maxDist = 5.0, fallbackDist = 6.0, radius = 0.25
        })

        if DoesEntityExist(gizmoEntity) then DeleteEntity(gizmoEntity) end
        gizmoEntity = CreateObjectNoOffset(hash, spawnPos.x, spawnPos.y, spawnPos.z, false, true, true)
        SetEntityCollision(gizmoEntity, false, false)
        FreezeEntityPosition(gizmoEntity, true)
        SetEntityRotation(gizmoEntity, 0.0, 0.0, spawnHeading, 2, true)

        gizmoPlacedCoords   = spawnPos
        gizmoPlacedRotation = vector3(0.0, 0.0, spawnHeading)

        -- Outline for lights
        if elementType == "lights" then
            SetEntityDrawOutlineColor(255, 255, 255, 10)
            SetEntityDrawOutline(gizmoEntity, true)
        end

        -- Smoke preview
        if elementType == "smoke" then
            SetEntityDrawOutlineColor(255, 255, 255, 10)
            SetEntityDrawOutline(gizmoEntity, true)
        end

        -- Apply snap settings
        local tSnap = translateSnapPresets[translateSnapIndex]
        local rSnap = rotationSnapPresets[rotationSnapIndex]
        if tSnap then SendNUIMessage({ action = "SetTranslateSnap", data = { translatesnapdata = tSnap.snapdata } }) end
        if rSnap then SendNUIMessage({ action = "SetRotationSnap",  data = { rotationsnapdata  = rSnap.snapdata } }) end

        SendNUIMessage({ action = "SetGizmoTransformMode", data = { transformhandler = false } })
        SendNUIMessage({ action = "SetSpaceMode",          data = { spacehandler = isWorldSpace } })
        SendNUIMessage({ message = "objecteditorposshow" })
        SendNUIMessage({ action = "djc:setPlacement", x = spawnPos.x,     y = spawnPos.y,     z = spawnPos.z })
        SendNUIMessage({ action = "djc:setRotation",  x = 0.0, y = 0.0, z = spawnHeading })

        GizmoStart(gizmoEntity)
    end

    RegisterNUICallback("locationadd", function(data, cb)
        if not creatorOpen or data.locationdata == nil then cb("ok") return end

        local elementType = tostring(data.locationdata)

        if elementType == "lights" then
            BeginGizmoPlacement("lights",    "prop_spot_clamp_02",           true)
        elseif elementType == "smoke" then
            BeginGizmoPlacement("smoke",     "h4_prop_club_smoke_machine",   false)
        elseif elementType == "lasers" then
            BeginGizmoPlacement("lasers",    "prop_spot_clamp",              true)
        elseif elementType == "particles" then
            BeginGizmoPlacement("particles", "prop_cs_burger_01",            false)
        elseif elementType == "location" then
            BeginGizmoPlacement("location",  "prop_cs_burger_01",            true)
            SetEntityVisible(gizmoEntity, false)
        end
        cb("ok")
    end)

    -- ── closeadd: cancel in-progress gizmo placement ─────────────────────────

    RegisterNUICallback("closeadd", function(data, cb)
        if creatorOpen and gizmoActive then
            gizmoActive      = false
            gizmoPlacingType = ""

            if DoesEntityExist(gizmoEntity) then DeleteEntity(gizmoEntity) end

            -- Clean up smoke preview particle
            if DoesParticleFxLoopedExist(previewSmokeParticle) then
                StopParticleFxLooped(previewSmokeParticle, 0)
                previewSmokeParticle = nil
            end

            -- Clean up laser secondary prop
            if DoesEntityExist(previewLaserMesh) then
                DeleteEntity(previewLaserMesh)
                previewLaserMesh = nil
            end

            SendNUIMessage({ action = "setGizmoEntity", data = {} })
        end
        cb("ok")
    end)

    -- ── confirmadd: commit placed element into the creator session tables ─────

    RegisterNUICallback("confirmadd", function(data, cb)
        if not creatorOpen or data.locationdata == nil then cb("ok") return end

        local elementType = tostring(data.locationdata)
        local elementId   = tonumber(data.locationiddata)
        local coords      = vector3(data.coords.x, data.coords.y, data.coords.z)
        local rotation    = vector3(data.rotation.x, data.rotation.y, data.rotation.z)

        if elementType == "lights" then
            creatorLightObjects[elementId] = {
                handler         = nil,
                removeinprogress = false,
                coords          = coords,
                rotation        = rotation,
            }
        elseif elementType == "smoke" then
            creatorSmokeObjects[elementId] = {
                handler         = nil,
                particlehandler = nil,
                removeinprogress = false,
                coords          = coords,
                rotation        = rotation,
            }
        elseif elementType == "lasers" then
            creatorLaserObjects[elementId] = {
                handler         = nil,
                handler2        = nil,
                removeinprogress = false,
                coords          = coords,
                rotation        = rotation,
            }
        elseif elementType == "particles" then
            creatorParticleObjects[elementId] = {
                handler         = nil,
                particlehandler = nil,
                dict            = tostring(data.particledict),
                name            = tostring(data.particlename),
                removeinprogress = false,
                coords          = coords,
                rotation        = rotation,
            }
        elseif elementType == "location" then
            -- DJ booth start point — update creatorStartCoords so finishcreator saves the correct position
            creatorStartCoords = coords
        end
        cb("ok")
    end)

    -- ── deletelocation: remove a single element from the session tables ───────

    RegisterNUICallback("deletelocation", function(data, cb)
        if not creatorOpen or data.locationdata == nil then cb("ok") return end

        local elementType = tostring(data.locationdata)
        local elementId   = tonumber(data.locationiddata)

        local function destroySingle(tbl, id, hasParticle, hasHandler2)
            local entry = tbl[id]
            if not entry then return end
            entry.removeinprogress = true
            Citizen.Wait(50)
            if DoesEntityExist(entry.handler)  then DeleteEntity(entry.handler)  end
            if hasHandler2 and DoesEntityExist(entry.handler2) then DeleteEntity(entry.handler2) end
            if hasParticle and DoesParticleFxLoopedExist(entry.particlehandler) then
                StopParticleFxLooped(entry.particlehandler, 0)
            end
            tbl[id] = nil
        end

        if     elementType == "lights"    then destroySingle(creatorLightObjects,    elementId, false, false)
        elseif elementType == "smoke"     then destroySingle(creatorSmokeObjects,    elementId, true,  false)
        elseif elementType == "lasers"    then destroySingle(creatorLaserObjects,    elementId, false, true)
        elseif elementType == "particles" then destroySingle(creatorParticleObjects, elementId, true,  false)
        end
        cb("ok")
    end)

    -- ── deletelocationall: wipe all elements of a given type ─────────────────

    RegisterNUICallback("deletelocationall", function(data, cb)
        if not creatorOpen or data.locationdata == nil then cb("ok") return end

        local elementType = tostring(data.locationdata)

        if     elementType == "lights"    then CleanupCreatorTable(creatorLightObjects,    false, false); creatorLightObjects    = {}
        elseif elementType == "smoke"     then CleanupCreatorTable(creatorSmokeObjects,    true,  false); creatorSmokeObjects    = {}
        elseif elementType == "lasers"    then CleanupCreatorTable(creatorLaserObjects,    false, true);  creatorLaserObjects    = {}
        elseif elementType == "particles" then CleanupCreatorTable(creatorParticleObjects, true,  false); creatorParticleObjects = {}
        end
        cb("ok")
    end)

    function CleanupCreatorTable(tbl, hasParticle, hasHandler2)
        for _, entry in pairs(tbl) do entry.removeinprogress = true end
        Citizen.Wait(50)
        for _, entry in pairs(tbl) do
            if hasParticle  and DoesParticleFxLoopedExist(entry.particlehandler) then StopParticleFxLooped(entry.particlehandler, 0) end
            if DoesEntityExist(entry.handler)  then DeleteEntity(entry.handler)  end
            if hasHandler2 and DoesEntityExist(entry.handler2) then DeleteEntity(entry.handler2) end
        end
    end

    -- ── editlocationstoggle: open a location for editing in the gizmo ────────

    function OpenLocationInEditor(locId)
        local location = Config.DjLocations[locId]
        if not location then return end

        -- Load existing sub-locations into creator preview tables
        creatorLightObjects = {}
        if location.lights and location.lights.locations then
            for idx, item in ipairs(location.lights.locations) do
                creatorLightObjects[idx] = {
                    handler = nil,
                    removeinprogress = false,
                    coords = item.coords,
                    rotation = item.rotation
                }
            end
        end

        creatorSmokeObjects = {}
        if location.smoke and location.smoke.locations then
            for idx, item in ipairs(location.smoke.locations) do
                creatorSmokeObjects[idx] = {
                    handler = nil,
                    particlehandler = nil,
                    removeinprogress = false,
                    coords = item.coords,
                    rotation = item.rotation
                }
            end
        end

        creatorLaserObjects = {}
        if location.lasers and location.lasers.locations then
            for idx, item in ipairs(location.lasers.locations) do
                creatorLaserObjects[idx] = {
                    handler = nil,
                    handler2 = nil,
                    removeinprogress = false,
                    coords = item.coords,
                    rotation = item.rotation
                }
            end
        end

        creatorParticleObjects = {}
        if location.particles and location.particles.locations then
            for idx, item in ipairs(location.particles.locations) do
                creatorParticleObjects[idx] = {
                    handler = nil,
                    particlehandler = nil,
                    dict = item.animdict or "weap_xs_vehicle_weapons",
                    name = item.animname or "muz_xs_turret_flamethrower_looping",
                    removeinprogress = false,
                    coords = item.coords,
                    rotation = item.rotation
                }
            end
        end

        local payload = BuildCreatorLocationPayload(locId, location)
        SendNUIMessage({ action = "djc:openEditor", mode = "edit", location = payload })
        SetNuiFocus(true, true)
    end

    local function DJC_Vector3FromPayload(value)
        value = value or {}
        return vector3(
            tonumber(value.x) or 0.0,
            tonumber(value.y) or 0.0,
            tonumber(value.z) or 0.0
        )
    end

    local function DJC_CopyPointList(list)
        local out = {}
        for _, point in ipairs(list or {}) do
            out[#out + 1] = {
                coords = DJC_Vector3FromPayload(point.coords),
                rotation = DJC_Vector3FromPayload(point.rotation),
                handler = nil,
                handler2 = nil,
            }
        end
        return out
    end

    local function DJC_CopyParticleList(list)
        local out = {}
        for _, point in ipairs(list or {}) do
            out[#out + 1] = {
                animdict = point.animdict,
                animname = point.animname,
                coords = DJC_Vector3FromPayload(point.coords),
                rotation = DJC_Vector3FromPayload(point.rotation),
                handler = nil,
                handler2 = nil,
            }
        end
        return out
    end

    local function DJC_SaveLocationLocal(location)
        local locId = tonumber(location.id) or location.id
        Config.DjLocations[locId] = {
            label = location.label,
            coords = DJC_Vector3FromPayload(location.coords),
            maxdistance = location.maxdistance or 500.0,
            soundtype = location.soundtype or "linear",
            permissions = {
                everyone = location.permissions and location.permissions.everyone or false,
                permissions = location.permissions and location.permissions.permissions or {},
            },
            smoke = {
                enabled = location.smoke and location.smoke.enabled or false,
                locations = DJC_CopyPointList(location.smoke and location.smoke.locations),
            },
            lights = {
                enabled = location.lights and location.lights.enabled or false,
                locations = DJC_CopyPointList(location.lights and location.lights.locations),
            },
            lasers = {
                enabled = location.lasers and location.lasers.enabled or false,
                locations = DJC_CopyPointList(location.lasers and location.lasers.locations),
            },
            particles = {
                enabled = location.particles and location.particles.enabled or false,
                locations = DJC_CopyParticleList(location.particles and location.particles.locations),
            },
        }
    end

    RegisterNUICallback("djc:clickEdit", function(data, cb)
        OpenLocationInEditor(tonumber(data.id))
        cb("ok")
    end)

    RegisterNUICallback("djc:clickRemove", function(data, cb)
        local locId = tonumber(data.id)
        if locId and Config.DjLocations[locId] then
            Config.DjLocations[locId] = nil
        end
        SendNUIMessage({ message = "setlocations", locations = BuildEditableLocationsList() })
        cb({ ok = true })
    end)

    RegisterNUICallback("djc:saveLocation", function(data, cb)
        local location = data and data.location
        if not location or not location.id then
            cb({ ok = false, reason = "bad_payload" })
            return
        end

        DJC_SaveLocationLocal(location)
        cb({ ok = true })
    end)

    RegisterNUICallback("editlocationstoggle", function(data, cb)
        local locId = tonumber(data.locationdiddata)

        -- Cleanup existing creator preview objects before loading new location
        CleanupAllCreatorObjects()

        if locId and Config.DjLocations[locId] then
            OpenLocationInEditor(locId)
        end
        cb("ok")
    end)

    -- ── DjCreatorClient net event: server confirmed creator can open ──────────

    RegisterNetEvent("rtx_dj:Global:DjCreatorClient")
    AddEventHandler("rtx_dj:Global:DjCreatorClient", function()
        if creatorOpen then return end

        creatorOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ message = "gizmoshow" })
        SendNUIMessage({ message = "djcreatorshow" })
        InvalidateIdleCam()
        InvalidateVehicleIdleCam()

        local ped = PlayerPedId()
        creatorStartCoords = GetEntityCoords(ped)

        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        ToggleCreatorFreecam(true)
        SendLocationsToNui()

        -- Creator keepalive loop: re-spawn any dropped preview objects each second
        while creatorOpen do
            Citizen.Wait(1000)
            InvalidateIdleCam()
            InvalidateVehicleIdleCam()

            -- Light preview objects (prop_spot_clamp_02)
            for _, obj in pairs(creatorLightObjects) do
                if not obj.removeinprogress and not DoesEntityExist(obj.handler) then
                    local hash = GetHashKey("prop_spot_clamp_02")
                    RequestModel(hash)
                    while not HasModelLoaded(hash) do RequestModel(hash); Citizen.Wait(5) end
                    if not obj.removeinprogress then
                        obj.handler = CreateObjectNoOffset(hash, obj.coords.x, obj.coords.y, obj.coords.z, false, true, true)
                        SetEntityRotation(obj.handler, obj.rotation.x, obj.rotation.y, obj.rotation.z)
                        FreezeEntityPosition(obj.handler, true)
                    end
                end
            end

            -- Smoke preview objects (h4_prop_club_smoke_machine + scr_ar_planes particle)
            for _, obj in pairs(creatorSmokeObjects) do
                if not obj.removeinprogress then
                    if not DoesEntityExist(obj.handler) then
                        local hash = GetHashKey("h4_prop_club_smoke_machine")
                        RequestModel(hash)
                        while not HasModelLoaded(hash) do RequestModel(hash); Citizen.Wait(5) end
                        if not obj.removeinprogress then
                            obj.handler = CreateObjectNoOffset(hash, obj.coords.x, obj.coords.y, obj.coords.z, false, true, true)
                            SetEntityRotation(obj.handler, obj.rotation.x, obj.rotation.y, obj.rotation.z)
                            FreezeEntityPosition(obj.handler, true)
                            SetEntityVisible(obj.handler, true)
                        end
                    end

                    if DoesEntityExist(obj.handler) and not DoesParticleFxLoopedExist(obj.particlehandler) then
                        SetWindSpeed(0.0); SetWindDirection(0.0)
                        RequestNamedPtfxAsset("scr_ar_planes")
                        while not HasNamedPtfxAssetLoaded("scr_ar_planes") do Citizen.Wait(5); RequestNamedPtfxAsset("scr_ar_planes") end
                        SetPtfxAssetNextCall("scr_ar_planes")
                        obj.particlehandler = StartParticleFxLoopedOnEntity("scr_ar_trail_smoke", obj.handler, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
                        SetParticleFxLoopedColour(obj.particlehandler, 1.0, 1.0, 1.0, 0)
                        SetParticleFxLoopedAlpha(obj.particlehandler, 0.1)
                    end
                end
            end

            -- Laser preview objects (prop_spot_clamp + rtx_djn_laser_box_dj_system)
            for _, obj in pairs(creatorLaserObjects) do
                if not obj.removeinprogress then
                    if not DoesEntityExist(obj.handler) then
                        local hash = GetHashKey("prop_spot_clamp")
                        RequestModel(hash)
                        while not HasModelLoaded(hash) do RequestModel(hash); Citizen.Wait(5) end
                        if not obj.removeinprogress then
                            obj.handler = CreateObjectNoOffset(hash, obj.coords.x, obj.coords.y, obj.coords.z, false, true, true)
                            SetEntityRotation(obj.handler, obj.rotation.x, obj.rotation.y, obj.rotation.z)
                            FreezeEntityPosition(obj.handler, true)
                        end
                    end

                    if DoesEntityExist(obj.handler) and not DoesEntityExist(obj.handler2) then
                        local boxHash = GetHashKey("rtx_djn_laser_box_dj_system")
                        RequestModel(boxHash)
                        while not HasModelLoaded(boxHash) do RequestModel(boxHash); Citizen.Wait(5) end
                        if not obj.removeinprogress then
                            obj.handler2 = CreateObjectNoOffset(boxHash, obj.coords.x, obj.coords.y, obj.coords.z, false, true, true)
                            SetEntityRotation(obj.handler2, obj.rotation.x, obj.rotation.y, obj.rotation.z)
                            FreezeEntityPosition(obj.handler2, true)
                            AttachEntityToEntity(obj.handler2, obj.handler, 0, 0.0, 0.0, -0.1, 0.0, 0.0, 0.0, false, false, false, false, 5, true)
                        end
                    end
                end
            end

            -- Particle preview objects
            for _, obj in pairs(creatorParticleObjects) do
                if not obj.removeinprogress then
                    if not DoesEntityExist(obj.handler) then
                        local hash = GetHashKey("prop_cs_burger_01")
                        RequestModel(hash)
                        while not HasModelLoaded(hash) do RequestModel(hash); Citizen.Wait(5) end
                        if not obj.removeinprogress then
                            obj.handler = CreateObjectNoOffset(hash, obj.coords.x, obj.coords.y, obj.coords.z, false, true, true)
                            SetEntityRotation(obj.handler, obj.rotation.x, obj.rotation.y, obj.rotation.z)
                            FreezeEntityPosition(obj.handler, true)
                            SetEntityVisible(obj.handler, false)
                        end
                    end

                    if DoesEntityExist(obj.handler) and not DoesParticleFxLoopedExist(obj.particlehandler) then
                        SetWindSpeed(0.0); SetWindDirection(0.0)
                        RequestNamedPtfxAsset(obj.dict)
                        while not HasNamedPtfxAssetLoaded(obj.dict) do Citizen.Wait(5); RequestNamedPtfxAsset(obj.dict) end
                        SetPtfxAssetNextCall(obj.dict)
                        obj.particlehandler = StartParticleFxLoopedOnEntity(obj.name, obj.handler, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 0.25, false, false, false, false)
                    end
                end
            end
        end
    end)

end  -- if Config.InGameDjCreator (creator callbacks block)
