-- Cleaned-up version of the decompiled helicopter camera script.
-- Logic is unchanged; names and structure were reconstructed from the decompiler output.
-- Extends the global `Heli` table, which is defined in another file.

local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

local visionModes = {}
local isShaking = false

-- Spotlight state
local beamDistance = 60.0
local lastProbeTime = 0
local lastProbeForward = nil
local beamHitPos = nil

---------------------------------------------------------------------------
-- Vision modes (loaded from config)
---------------------------------------------------------------------------

CreateThread(function()
    for _, mode in ipairs(Config.Camera.modes or {}) do
        if mode.enabled ~= false then
            visionModes[#visionModes + 1] = mode
        end
    end

    -- Always have at least a normal mode.
    if #visionModes == 0 then
        visionModes = { { id = "normal", label = "locale:mode_normal" } }
    end
end)

---------------------------------------------------------------------------
-- Camera lifecycle
---------------------------------------------------------------------------

function Heli.SetupCamera()
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local pos = Heli.pos or GetEntityCoords(PlayerPedId())

    SetCamCoord(cam, pos.x, pos.y, pos.z)
    SetCamRot(cam, Heli.camPitch or -25.0, 0.0, Heli.camYaw or 0.0, 2)
    SetCamFov(cam, Heli.fov or Config.Camera.defaultFov)

    Heli.cam = cam
    RenderScriptCams(true, true, 600, true, true)
    ClearTimecycleModifier()
end

function Heli.DestroyCamera()
    RenderScriptCams(false, true, 400, true, true)

    if Heli.cam then
        StopCamShaking(Heli.cam, true)
        SetCamActive(Heli.cam, false)
        DestroyCam(Heli.cam, false)
        Heli.cam = nil
    end

    isShaking = false

    SetNightvision(false)
    SetSeethrough(false)
    pcall(function()
        SetSeethroughMaxThicknessToWaterMark(0.0)
    end)
    ClearTimecycleModifier()
    SetTimecycleModifierStrength(1.0)
end

---------------------------------------------------------------------------
-- Vision modes
---------------------------------------------------------------------------

function Heli.CurrentMode()
    return visionModes[Heli.modeIndex] or visionModes[1]
end

function Heli.ApplyVisionMode(silent)
    local mode = Heli.CurrentMode()
    local id = (mode and mode.id) or "normal"

    -- Reset everything, then enable what the mode needs.
    SetNightvision(false)
    SetSeethrough(false)
    ClearTimecycleModifier()
    SetTimecycleModifierStrength(1.0)

    local isThermal = (id == "thermal" or id == "bwthermal")

    if id == "normal" then
        -- nothing extra
    elseif id == "nightvision" then
        SetNightvision(true)
    elseif isThermal then
        SetSeethrough(true)
        pcall(function()
            SetSeethroughMaxThicknessToWaterMark(Config.Camera.seethroughThickness or 2500.0)
        end)
    end

    Heli.thermal = isThermal

    local label = Lang((mode and mode.label) or "locale:mode_normal")
    SendNUIMessage({ action = "mode", id = id, label = label })

    if not silent then
        SendNUIMessage({ action = "osd", text = _U("ui_sns") .. " · " .. label })
    end
end

function Heli.CycleMode()
    if #visionModes <= 1 then return end

    Heli.modeIndex = (Heli.modeIndex % #visionModes) + 1
    Heli.ApplyVisionMode(false)
end

---------------------------------------------------------------------------
-- Spotlight
---------------------------------------------------------------------------

function Heli.ToggleSpotlight()
    local cfg = Config.Camera.spotlight
    if not (cfg and cfg.enabled) then return end

    Heli.spotlight = not Heli.spotlight
    SendNUIMessage({ action = "spotlight", on = Heli.spotlight })

    local text = _U(Heli.spotlight and "spotlight_on" or "spotlight_off")
    if Heli.spotlight then
        text = text .. "  ·  " .. _U("beam_hint")
    end
    SendNUIMessage({ action = "osd", text = text })

    -- When switching off, clear the synced state bag so other players stop drawing the beam.
    if not Heli.spotlight and Heli.entity then
        pcall(function()
            Entity(Heli.entity).state:set("oxlynSpot", nil, true)
        end)
    end
end

-- direction: +1 / -1 to grow / shrink the beam radius.
function Heli.AdjustSpotlight(direction)
    local cfg = Config.Camera.spotlight
    if not (cfg and cfg.enabled) then return end

    local current = Heli.spotRadius or cfg.radius or 7.0
    local step = cfg.radiusStep or 1.0

    Heli.spotRadius = clamp(
        current + direction * step,
        cfg.minRadius or 2.5,
        cfg.maxRadius or 16.0)
end

function Heli.DrawSpotBeam(origin, direction, radius, distance)
    local cfg = Config.Camera.spotlight
    if not cfg then return end

    local x, y, z = origin.x, origin.y, origin.z - 0.3

    local range = math.min((distance or 60.0) + 20.0, cfg.maxRange or 260.0)
    local intensity = (2.6 + range * 0.09) * (cfg.intensity or 1.0)

    -- Small point light at the source, plus the shadow-casting cone.
    DrawLightWithRange(x, y, z, cfg.color.r, cfg.color.g, cfg.color.b, 1.9, 3.0)
    DrawSpotLightWithShadow(
        x, y, z,
        direction.x, direction.y, direction.z,
        cfg.color.r, cfg.color.g, cfg.color.b,
        range, intensity, 0.0, radius, 1.0, 0)
end

function Heli.RenderSpotlight()
    if not (Heli.spotlight and Heli.active) then return end

    local cfg = Config.Camera.spotlight
    local origin = Heli.camPos or Heli.pos
    local forward = Heli.lookForward or vector3(0.0, 0.0, -1.0)
    if not origin then return end

    local maxRange = cfg.maxRange or 320.0
    local now = GetGameTimer()

    -- Re-run the line-of-sight probe at most every 100 ms to find where the beam lands.
    if not lastProbeForward or (now - lastProbeTime) > 100 then
        lastProbeTime = now
        lastProbeForward = forward

        local target = origin + forward * maxRange
        local probe = _ENV["StartExpensiveSynchronousShapeTestLosProbe"](
            origin.x, origin.y, origin.z,
            target.x, target.y, target.z,
            19, Heli.entity or 0, 4)

        local _, hit, endCoords = GetShapeTestResult(probe)
        if hit and endCoords then
            beamHitPos = vector3(endCoords.x, endCoords.y, endCoords.z)
            beamDistance = #(beamHitPos - origin)
        else
            beamHitPos = nil
            beamDistance = maxRange
        end
    end

    -- Aim the beam at the hit point when there is one.
    local beamOrigin = vector3(origin.x, origin.y, origin.z - 0.3)
    local direction = forward
    if beamHitPos then
        local toHit = beamHitPos - beamOrigin
        local length = #toHit
        if length > 0.5 then
            direction = toHit / length
        end
    end

    local radius = Heli.spotRadius or cfg.radius or 8.0
    Heli.DrawSpotBeam(origin, direction, radius, beamDistance)
end

---------------------------------------------------------------------------
-- Zoom, view and shake
---------------------------------------------------------------------------

function Heli.SetZoom(delta)
    local current = Heli.fovTarget or Heli.fov or Config.Camera.defaultFov
    Heli.fovTarget = clamp(current + delta, Config.Camera.minFov, Config.Camera.maxFov)
end

-- Switches between the gimbal view and an external orbit view.
function Heli.ToggleView()
    local external = Config.Camera.external
    if not (external and external.enabled ~= false) then return end

    Heli.view = (Heli.view == "external") and "gimbal" or "external"
    Heli.extCamPos = nil

    if Heli.view == "external" then
        Heli.orbYaw = Heli.camYaw
        Heli.orbPitch = external.startPitch or -16.0
        Heli.orbDist = external.distance or 4.0
    else
        Heli.camYaw = Heli.orbYaw or Heli.camYaw
    end

    local label = _U(Heli.view == "external" and "ui_cam_ext" or "ui_cam_gimbal")
    SendNUIMessage({ action = "view", id = Heli.view, label = label })
    SendNUIMessage({ action = "osd", text = label })
end

function Heli.ApplyShake(amplitude)
    if not Heli.cam then return end

    -- Negligible amplitude: stop shaking.
    if not amplitude or amplitude <= 0.01 then
        if isShaking then
            StopCamShaking(Heli.cam, true)
            isShaking = false
        end
        return
    end

    if not isShaking then
        ShakeCam(Heli.cam, "HAND_SHAKE", amplitude)
        isShaking = true
    else
        SetCamShakeAmplitude(Heli.cam, amplitude)
    end
end