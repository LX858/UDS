

Oxlyn = Oxlyn or {}

---------------------------------------------------------------------
-- Helpers / cached natives
---------------------------------------------------------------------

-- Calls a native by name only if it exists in this game build.
local function call(name, ...)
    local fn = _ENV[name]
    if fn then return fn(...) end
end

-- Natives used every frame (cached for speed)
local SetPedDensityMultiplierThisFrame            = SetPedDensityMultiplierThisFrame
local SetVehicleDensityMultiplierThisFrame        = SetVehicleDensityMultiplierThisFrame
local SetParkedVehicleDensityMultiplierThisFrame  = _ENV["SetParkedVehicleDensityMultiplierThisFrame"]
local SetRandomVehicleDensityMultiplierThisFrame  = _ENV["SetRandomVehicleDensityMultiplierThisFrame"]
local SetScenarioPedDensityMultiplierThisFrame    = SetScenarioPedDensityMultiplierThisFrame
local SetAmbientVehicleRangeMultiplierThisFrame   = _ENV["SetAmbientVehicleRangeMultiplierThisFrame"]
local SetAmbientPedRangeMultiplierThisFrame       = SetAmbientPedRangeMultiplierThisFrame
local OverrideLodscaleThisFrame                   = OverrideLodscaleThisFrame
local SetDisableDecalRenderingThisFrame           = SetDisableDecalRenderingThisFrame
local DisableVehicleDistantlights                 = DisableVehicleDistantlights
local DisableScreenblurFade                       = DisableScreenblurFade
local SetNoiseoveride                             = SetNoiseoveride
local SetNoisinessoveride                         = SetNoisinessoveride
local CascadeShadowsSetDynamicDepthMode           = CascadeShadowsSetDynamicDepthMode
local CascadeShadowsSetDynamicDepthValue          = CascadeShadowsSetDynamicDepthValue

-- Natives used in the slow loop / visual settings
local SetPedLodMultiplier        = SetPedLodMultiplier
local SetVehicleLodMultiplier    = SetVehicleLodMultiplier
local GetVisualSettingFloat      = GetVisualSettingFloat
local SetVisualSettingFloat      = SetVisualSettingFloat
local SetPedNonCreationArea      = SetPedNonCreationArea
local ClearPedNonCreationArea    = ClearPedNonCreationArea
local RemoveParticleFxInRange    = RemoveParticleFxInRange

local WATER_OVERRIDES = {
    "WaterOverrideSetOceanwaveamplitude",
    "WaterOverrideSetOceanwaveminamplitude",
    "WaterOverrideSetOceanwavemaxamplitude",
    "WaterOverrideSetOceannoiseminamplitude",
    "WaterOverrideSetShorewaveamplitude",
    "WaterOverrideSetShorewaveminamplitude",
    "WaterOverrideSetShorewavemaxamplitude",
    "WaterOverrideSetRipplebumpiness",
    "WaterOverrideSetRippleminbumpiness",
    "WaterOverrideSetRipplemaxbumpiness",
    "WaterOverrideSetRippledisturb",
}

---------------------------------------------------------------------
-- Visual settings: setting id -> list of game visual-setting keys it scales
---------------------------------------------------------------------

local VISUAL_GROUPS = {
    renderLodLights = {
        "lodlight.small.range", "lodlight.medium.range", "lodlight.large.range",
        "lodlight.small.fade", "lodlight.medium.fade", "lodlight.large.fade",
        "lodlight.small.corona.range", "lodlight.medium.corona.range", "lodlight.large.corona.range",
        "misc.brightlight.distculled.FadeStart", "misc.brightlight.distculled.FadeEnd",
        "trafficLight.farFadeStart", "trafficLight.farFadeEnd",
    },
    renderCoronas = {
        "misc.coronas.sizeScaleGlobal", "misc.coronas.intensityScaleGlobal",
        "misc.coronas.sizeScaleWater", "misc.coronas.intensityScaleWater",
        "lodlight.corona.size",
    },
    renderDistantLights = {
        "distantlights.size", "distantlights.sizeMin", "distantlights.sizeUpscale",
        "distantlights.carlight.farFade", "distantlights.carlight.HDRIntensity",
        "distantlights.streetlight.HDRIntensity",
    },
    renderPuddles = {
        "puddles.range", "puddles.scale", "puddles.strength", "puddles.depth",
    },
    renderPostFx = {
        "bokeh.globalAlpha", "bokeh.sizeMultiplier",
        "bloom.blurblendmult.small", "bloom.blurblendmult.med", "bloom.blurblendmult.large",
    },
    renderVehicleLights = {
        "car.headlights.volume.intensityscale", "car.headlights.volume.outerintensity",
        "car.headlights.volume.sizescale", "car.coronas.CutoffStart", "car.coronas.CutoffEnd",
        "vehicle.lights.fadeDistance.main", "vehicle.lights.fadeDistance.secondary",
        "vehicle.lights.fadeDistance.neon", "vehicle.lights.fadeDistance.sirens",
        "vehicle.lights.fadeDistance.AO",
    },
}

local visualDefaults = {}     -- original game values
local visualCurrent  = {}     -- values currently applied
local visualsCached  = false

local SHADOW_SAMPLE_TYPES = {
    default  = "CSM_ST_DITHER4_RPDB",
    reduced  = "CSM_ST_BOX3x3",
    aircraft = "CSM_ST_TWOTAP",
    off      = "CSM_ST_POINT",
}

local PED_AREA_HALF_SIZE    = 1200.0
local PED_AREA_REFRESH_DIST = 300.0
local lastPedAreaCenter     = nil

---------------------------------------------------------------------
-- Shared state
---------------------------------------------------------------------

Oxlyn.Boost = {
    frameWorkNeeded = false,
    slowWorkNeeded  = false,
    shadowMode      = "default",
    lastAppliedHash = "",
    blockPeds       = false,
    entityLod       = 1.0,
    entityLodDirty  = false,
}
local Boost = Oxlyn.Boost

local function get(name)
    return Oxlyn.Get(name)
end

local function isActive(name)
    return Oxlyn.Active(name)
end

-- Effective value: the user's value if the setting is active, otherwise its default.
local function eff(name)
    if not isActive(name) then
        local setting = Oxlyn.SettingIndex[name]
        return setting and setting.default or nil
    end
    return get(name)
end
Oxlyn.Eff = eff

---------------------------------------------------------------------
-- Visual settings management
---------------------------------------------------------------------

local function cacheVisualDefaults()
    if visualsCached or not GetVisualSettingFloat then return end

    for _, keys in pairs(VISUAL_GROUPS) do
        for _, key in ipairs(keys) do
            -- skip keys this game build doesn't know instead of throwing a script error
            local ok, value = pcall(GetVisualSettingFloat, key)
            if ok and type(value) == "number" then
                value = value + 0.0
                visualDefaults[key] = value
                visualCurrent[key]  = value
            end
        end
    end
    visualsCached = true
end

local function applyVisualScales()
    if not (visualsCached and SetVisualSettingFloat) then return end

    for group, keys in pairs(VISUAL_GROUPS) do
        local scale = get(group)
        if type(scale) ~= "number" then scale = 1.0 end

        for _, key in ipairs(keys) do
            local base = visualDefaults[key]
            if base then
                local target = base * scale
                if visualCurrent[key] ~= target then
                    visualCurrent[key] = target
                    SetVisualSettingFloat(key, target)
                end
            end
        end
    end
end

local function restoreVisualDefaults()
    if not (visualsCached and SetVisualSettingFloat) then return end

    for key, value in pairs(visualDefaults) do
        SetVisualSettingFloat(key, value)
        visualCurrent[key] = value
    end
end

---------------------------------------------------------------------
-- Thailor Boots
---------------------------------------------------------------------

local thailorApplied = false

local function applyThailorBoots(enable)
    if enable then
        thailorApplied = true
        call("SetTimecycleModifier", "yell_tunnel_nodirect")
        call("RopeDrawShadowEnabled", false)

        call("CascadeShadowsClearShadowSampleType")
        call("CascadeShadowsSetAircraftMode", false)
        call("CascadeShadowsEnableEntityTracker", true)
        call("CascadeShadowsSetDynamicDepthMode", false)
        call("CascadeShadowsSetEntityTrackerScale", 0.0)
        call("CascadeShadowsSetDynamicDepthValue", 0.0)
        call("CascadeShadowsSetCascadeBoundsScale", 0.0)

        call("SetFlashLightFadeDistance", 0.0)
        call("SetLightsCutoffDistanceTweak", 0.0)
        call("DistantCopCarSirens", false)
    elseif thailorApplied then
        thailorApplied = false
        call("ClearTimecycleModifier")
        call("ClearExtraTimecycleModifier")
        call("RopeDrawShadowEnabled", true)

        call("CascadeShadowsSetDynamicDepthMode", true)
        call("CascadeShadowsSetEntityTrackerScale", 1.0)
        call("CascadeShadowsSetDynamicDepthValue", 1.0)
        call("CascadeShadowsSetCascadeBoundsScale", 1.0)

        call("SetFlashLightFadeDistance", 10.0)
        call("SetLightsCutoffDistanceTweak", 10.0)
    end
end

---------------------------------------------------------------------
-- One-shot settings (applied on ApplyBoost)
---------------------------------------------------------------------

local function applyStaticSettings()
    local shadowMode = get("shadowMode") or "default"
    Boost.shadowMode = shadowMode

    call("CascadeShadowsSetAircraftMode", shadowMode == "aircraft" or shadowMode == "off")
    call("CascadeShadowsEnableEntityTracker", shadowMode == "default")
    call("CascadeShadowsSetShadowSampleType", SHADOW_SAMPLE_TYPES[shadowMode] or SHADOW_SAMPLE_TYPES.default)

    call("SetArtificialLightsState",                 get("artificialLights")    == false)
    call("SetArtificialLightsStateAffectsVehicles",  get("artificialLightsVeh") == false)
    call("DistantCopCarSirens",                      get("distantSirens")       ~= false)
    call("SetForceVehicleTrails",                    get("vehicleTrails")       ~= false)
    call("SetForcePedFootstepsTracks",               get("footstepTracks")      ~= false)
    call("SetDeepOceanScaler",                       get("oceanScaler") + 0.0)

    -- Flat water
    if WaterOverrideSetStrength then
        if get("flatWater") == true then
            for _, name in ipairs(WATER_OVERRIDES) do
                call(name, 0.0)
            end
            WaterOverrideSetStrength(1.0)
        else
            WaterOverrideSetStrength(0.0)
        end
    end

    -- Ambient population toggles
    call("SetGarbageTrucks",                       get("garbageTrucks")      ~= false)
    call("SetRandomBoats",                         get("randomBoats")        ~= false)
    call("SetRandomTrains",                        get("randomTrains")       ~= false)
    call("SetAllLowPriorityVehicleGeneratorsActive", get("lowPriorityVehGens") ~= false)
    call("SetDistantCarsEnabled",                  get("distantCars")        ~= false)
    call("SetNumberOfParkedVehicles",              get("blockParkedSpawns") == true and 0 or -1)

    -- Random cops
    local cops = get("randomCops") ~= false
    call("SetCreateRandomCops", cops)
    call("SetCreateRandomCopsOnScenarios", cops)
    call("SetCreateRandomCopsNotOnScenarios", cops)

    -- Population / model budgets
    call("SetPedPopulationBudget",     math.floor(get("pedLodBudget") or 3))
    call("SetVehiclePopulationBudget", math.floor(get("vehLodBudget") or 3))

    local reduceBudget = get("reduceModelBudget") == true
    call("SetReducePedModelBudget", reduceBudget)
    call("SetReduceVehicleModelBudget", reduceBudget)

    -- Dispatch services (1..15)
    if EnableDispatchService then
        local enabled = get("dispatchServices") ~= false
        for service = 1, 15 do
            EnableDispatchService(service, enabled)
        end
    end

    applyVisualScales()

    -- Entity LOD
    local entityLod = get("entityLod") or 1.0
    Boost.entityLodDirty = entityLod >= 1.0
    Boost.entityLod      = entityLod

    -- Ped spawn blocking
    Boost.blockPeds = get("blockPedSpawns") == true
    if not Boost.blockPeds then
        if lastPedAreaCenter then
            if ClearPedNonCreationArea then ClearPedNonCreationArea() end
            lastPedAreaCenter = nil
        end
    else
        lastPedAreaCenter = nil -- force the area to be re-applied
    end

    -- Motion blur
    call("SetPedMotionBlur", PlayerPedId(), get("motionBlur") ~= false)

    applyThailorBoots(get("thailorBoots") == true)

    -- Decide which loops need to run
    Boost.frameWorkNeeded = (get("pedDensity") or 1) < 1.0

    -- NOTE: reconstructed from garbled decompiler output (intermediate results were lost).
    -- Intent: the slow loop is needed for entity LOD work, weather/wind/rain forcing,
    -- or particle cleanup.
    Boost.slowWorkNeeded = Boost.entityLodDirty
        or Boost.entityLod < 1.0
        or get("forceClearWeather") == true
        or get("killRain") == true
        or get("killWind") == true
        or eff("particleCleanup") == true

    Oxlyn.Debug(("boost aplicado | preset=%s frameLoop=%s slowLoop=%s"):format(
        tostring(Oxlyn.State.activePreset),
        tostring(Boost.frameWorkNeeded),
        tostring(Boost.slowWorkNeeded)
    ))
end

---------------------------------------------------------------------
-- Per-frame cache (refreshed in ApplyBoost, consumed by BoostFrame)
---------------------------------------------------------------------

local frame = {
    pedActive = false,       pedValue = 1.0,
    vehActive = false,       vehValue = 1.0,
    parkedActive = false,    parkedValue = 1.0,
    randomVehActive = false, randomVehValue = 1.0,
    scenarioActive = false,  scenarioValue = 1.0,
    vehRangeActive = false,  vehRangeValue = 1.0,
    pedRangeActive = false,  pedRangeValue = 1.0,
    lodActive = false,       lodValue = 1.0,
    disableDecals = false,
    disableDistantVehLights = false,
    disableScreenBlur = false,
    noiseOverride = false,
    noisinessOverride = false,
    shadowOverride = false,
    shadowDepthMode = 1,
    shadowDepthValue = 1.0,
}

local function refreshFrameCache()
    local pedDensity      = get("pedDensity")        or 1.0
    local vehDensity      = get("vehicleDensity")    or 1.0
    local parkedDensity   = get("parkedDensity")     or 1.0
    local randomVeh       = get("randomVehDensity")  or 1.0
    local scenarioDensity = get("scenarioDensity")   or 1.0
    local vehRange        = get("ambientVehRange")   or 1.0
    local pedRange        = get("ambientPedRange")   or 1.0
    local lodScale        = get("lodScale")          or 1.0
    local shadowMode      = Boost.shadowMode

    frame.pedActive,       frame.pedValue       = pedDensity < 1.0,      pedDensity + 0.0
    frame.vehActive,       frame.vehValue       = vehDensity < 1.0,      vehDensity + 0.0
    frame.parkedActive,    frame.parkedValue    = parkedDensity < 1.0,   parkedDensity + 0.0
    frame.randomVehActive, frame.randomVehValue = randomVeh < 1.0,       randomVeh + 0.0
    frame.scenarioActive,  frame.scenarioValue  = scenarioDensity < 1.0, scenarioDensity + 0.0
    frame.vehRangeActive,  frame.vehRangeValue  = vehRange < 1.0,        vehRange + 0.0
    frame.pedRangeActive,  frame.pedRangeValue  = pedRange < 1.0,        pedRange + 0.0
    frame.lodActive,       frame.lodValue       = lodScale < 1.0,        lodScale + 0.0

    frame.disableDecals          = get("disableDecals")        == true
    frame.disableDistantVehLights = get("vehicleDistantLights") == false
    frame.disableScreenBlur      = get("screenBlur")           == false

    local noGrain = get("filmGrain") == false
    frame.noiseOverride      = noGrain and SetNoiseoveride ~= nil
    frame.noisinessOverride  = noGrain and SetNoisinessoveride ~= nil

    frame.shadowOverride   = shadowMode ~= "default"
    frame.shadowDepthMode  = shadowMode == "off" and 0 or 1
    frame.shadowDepthValue = (get("shadowDistance") or 1.0) + 0.0
end

-- Called every frame by the main resource.
function Oxlyn.BoostFrame()
    if not Boost.frameWorkNeeded then return end

    if frame.pedActive       then SetPedDensityMultiplierThisFrame(frame.pedValue) end
    if frame.vehActive       then SetVehicleDensityMultiplierThisFrame(frame.vehValue) end
    if frame.parkedActive    then SetParkedVehicleDensityMultiplierThisFrame(frame.parkedValue) end
    if frame.randomVehActive then SetRandomVehicleDensityMultiplierThisFrame(frame.randomVehValue) end
    if frame.scenarioActive  then SetScenarioPedDensityMultiplierThisFrame(frame.scenarioValue, frame.scenarioValue) end
    if frame.vehRangeActive  then SetAmbientVehicleRangeMultiplierThisFrame(frame.vehRangeValue) end
    if frame.pedRangeActive  then SetAmbientPedRangeMultiplierThisFrame(frame.pedRangeValue) end
    if frame.lodActive       then OverrideLodscaleThisFrame(frame.lodValue) end

    if frame.disableDecals           then SetDisableDecalRenderingThisFrame() end
    if frame.disableDistantVehLights then DisableVehicleDistantlights(true) end
    if frame.noiseOverride           then SetNoiseoveride(false) end
    if frame.noisinessOverride       then SetNoisinessoveride(0.0) end

    if frame.shadowOverride then
        CascadeShadowsSetDynamicDepthMode(frame.shadowDepthMode)
        CascadeShadowsSetDynamicDepthValue(frame.shadowDepthValue)
    end

    if frame.disableScreenBlur and not Oxlyn.State.open then
        DisableScreenblurFade()
    end
end

function Oxlyn.ApplyBoost()
    applyStaticSettings()
    refreshFrameCache()
end

---------------------------------------------------------------------
-- Threads
---------------------------------------------------------------------

-- Initial visual-settings capture
CreateThread(function()
    Wait(1500)
    cacheVisualDefaults()
    applyVisualScales()
end)

-- Slow loop: weather, entity LOD, ped spawn area, particle cleanup
CreateThread(function()
    Wait(2500)

    local lastParticleCleanup = 0
    local lastLodPass         = 0
    local lodApplied          = {}   -- entities already processed
    local lodAppliedSince     = 0
    local lastLod             = 1.0

    while true do
        if Boost.slowWorkNeeded then
            if get("killRain") == true and SetRainLevel then
                SetRainLevel(0.0)
            end

            if get("killWind") == true then
                if SetWind then SetWind(0.0) end
                if SetWindSpeed then SetWindSpeed(0.0) end
            end

            if get("forceClearWeather") == true then
                if ClearOverrideWeather then ClearOverrideWeather() end
                if SetWeatherTypeNowPersist then SetWeatherTypeNowPersist("EXTRASUNNY") end
            end

            -- Entity LOD multiplier
            local lod = Boost.entityLod + 0.0
            if lod < 1.0 or lastLod < 1.0 then
                local now = GetGameTimer()

                if lod ~= lastLod then
                    lodApplied, lodAppliedSince = {}, now
                elseif now - lodAppliedSince > 10000 then
                    lodApplied, lodAppliedSince = {}, now
                end

                if now - lastLodPass > 2000 or lod ~= lastLod then
                    lastLodPass = now
                    local playerPed = PlayerPedId()

                    if SetPedLodMultiplier then
                        for _, ped in ipairs(GetGamePool("CPed")) do
                            if not lodApplied[ped] and ped ~= playerPed and not IsPedAPlayer(ped) then
                                lodApplied[ped] = true
                                SetPedLodMultiplier(ped, lod)
                            end
                        end
                    end

                    if SetVehicleLodMultiplier then
                        local playerVeh = GetVehiclePedIsIn(playerPed, false)
                        for _, veh in ipairs(GetGamePool("CVehicle")) do
                            if not lodApplied[veh] and veh ~= playerVeh then
                                lodApplied[veh] = true
                                SetVehicleLodMultiplier(veh, lod)
                            end
                        end
                    end

                    lastLod = lod
                    if lod >= 1.0 then
                        Boost.entityLodDirty = false
                        Oxlyn.ApplyBoost()
                    end
                end
            end

            -- Block ped spawns in a large box around the player
            if Boost.blockPeds then
                local coords = GetEntityCoords(PlayerPedId())
                local needsUpdate = true

                if lastPedAreaCenter then
                    local dx = coords.x - lastPedAreaCenter.x
                    local dy = coords.y - lastPedAreaCenter.y
                    needsUpdate = (dx * dx + dy * dy) > (PED_AREA_REFRESH_DIST * PED_AREA_REFRESH_DIST)
                end

                if needsUpdate then
                    lastPedAreaCenter = coords
                    SetPedNonCreationArea(
                        coords.x - PED_AREA_HALF_SIZE, coords.y - PED_AREA_HALF_SIZE, coords.z - 500.0,
                        coords.x + PED_AREA_HALF_SIZE, coords.y + PED_AREA_HALF_SIZE, coords.z + 500.0
                    )
                end
            end

            -- Particle cleanup around the player
            if eff("particleCleanup") == true and RemoveParticleFxInRange then
                local now = GetGameTimer()
                if now - lastParticleCleanup > 5000 then
                    lastParticleCleanup = now
                    local coords = GetEntityCoords(PlayerPedId())
                    local radius = eff("particleRadius") or 200.0
                    RemoveParticleFxInRange(coords.x, coords.y, coords.z, radius + 0.0)
                end
            end

            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

-- Periodic re-apply (the game can reset some values on its own)
CreateThread(function()
    Wait(8000)

    while true do
        Wait(20000)

        local idle = Oxlyn.State.activePreset == "off" and next(Oxlyn.State.overrides) == nil
        if not idle then
            Oxlyn.ApplyBoost()
        end
    end
end)

AddEventHandler("playerSpawned", function()
    SetTimeout(2000, Oxlyn.ApplyBoost)
end)

---------------------------------------------------------------------
-- Cleanup: restore game defaults when the resource stops
---------------------------------------------------------------------

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    applyThailorBoots(false)

    call("CascadeShadowsSetAircraftMode", false)
    call("CascadeShadowsEnableEntityTracker", true)
    call("CascadeShadowsSetShadowSampleType", SHADOW_SAMPLE_TYPES.default)
    if CascadeShadowsSetDynamicDepthMode  then CascadeShadowsSetDynamicDepthMode(0) end
    if CascadeShadowsSetDynamicDepthValue then CascadeShadowsSetDynamicDepthValue(1.0) end

    call("SetArtificialLightsState", false)
    call("SetArtificialLightsStateAffectsVehicles", false)
    call("DistantCopCarSirens", true)
    call("SetForceVehicleTrails", true)
    call("SetForcePedFootstepsTracks", true)
    call("SetDeepOceanScaler", 1.0)
    call("SetGarbageTrucks", true)
    call("SetRandomBoats", true)
    call("SetRandomTrains", true)
    call("SetDistantCarsEnabled", true)
    call("SetNumberOfParkedVehicles", -1)
    if ClearPedNonCreationArea then ClearPedNonCreationArea() end
    call("WaterOverrideSetStrength", 0.0)

    restoreVisualDefaults()

    if SetPedLodMultiplier then
        for _, ped in ipairs(GetGamePool("CPed")) do
            SetPedLodMultiplier(ped, 1.0)
        end
    end
    if SetVehicleLodMultiplier then
        for _, veh in ipairs(GetGamePool("CVehicle")) do
            SetVehicleLodMultiplier(veh, 1.0)
        end
    end

    call("SetCreateRandomCops", true)
    call("SetCreateRandomCopsOnScenarios", true)
    call("SetCreateRandomCopsNotOnScenarios", true)
    call("SetAllLowPriorityVehicleGeneratorsActive", true)
    call("SetPedPopulationBudget", 3)
    call("SetVehiclePopulationBudget", 3)
    call("SetReducePedModelBudget", false)
    call("SetReduceVehicleModelBudget", false)
    call("SetPedMotionBlur", PlayerPedId(), true)

    if EnableDispatchService then
        for service = 1, 15 do
            EnableDispatchService(service, true)
        end
    end

    if TriggerScreenblurFadeOut then TriggerScreenblurFadeOut(0.0) end
    SetNuiFocus(false, false)
end)

