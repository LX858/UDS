-- Cleaned-up version of the decompiled helicopter camera core script.
-- Logic is unchanged; names and structure were reconstructed from the decompiler output.
-- Extends the global `Heli` table shared with the other camera files.

Heli = Heli or {}

---------------------------------------------------------------------------
-- Math helpers
---------------------------------------------------------------------------

local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function wrap360(angle)
    angle = angle % 360.0
    if angle < 0 then
        angle = angle + 360.0
    end
    return angle
end

-- Interpolates between two angles along the shortest path.
local function lerpAngle(a, b, t)
    local diff = ((b - a) + 540.0) % 360.0 - 180.0
    return wrap360(a + diff * t)
end

-- Unit forward vector from a yaw and pitch in degrees.
local function directionFromAngles(yaw, pitch)
    local yawRad = math.rad(yaw)
    local pitchRad = math.rad(pitch)
    local cosPitch = math.cos(pitchRad)
    return vector3(-math.sin(yawRad) * cosPitch, math.cos(yawRad) * cosPitch, math.sin(pitchRad))
end

---------------------------------------------------------------------------
-- Which helicopters may use the camera
---------------------------------------------------------------------------

local allowedModelSet = nil
local allowedModelSource = nil

-- Builds (and caches) a set of model hashes from Config.Vehicles.models.
local function getAllowedModelSet()
    local models = (Config.Vehicles or {}).models or {}

    if allowedModelSet and allowedModelSource == models then
        return allowedModelSet
    end

    allowedModelSet = {}
    for i = 1, #models do
        local entry = models[i]
        if type(entry) == "number" then
            allowedModelSet[entry] = true
        elseif type(entry) == "string" then
            allowedModelSet[GetHashKey(entry)] = true
        end
    end

    allowedModelSource = models
    return allowedModelSet
end

-- Returns the helicopter the player is in if it may use the camera.
-- Otherwise returns nil and optionally a reason: "heli_unsupported" or "driver_blocked".
function Heli.CurrentHeli()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return nil
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if not (vehicle and vehicle ~= 0 and DoesEntityExist(vehicle)) then
        return nil
    end

    local cfg = Config.Vehicles or {}
    local model = GetEntityModel(vehicle)
    local isHeli = IsThisModelAHeli(model)

    if cfg.allowAllHelis then
        if not isHeli then
            return nil
        end
    else
        local allowed = getAllowedModelSet()[model] or false

        -- Fall back to matching by display name.
        if not allowed then
            local displayName = string.lower(GetDisplayNameFromVehicleModel(model) or "")
            local models = cfg.models or {}
            for i = 1, #models do
                if type(models[i]) == "string" and string.lower(models[i]) == displayName then
                    allowed = true
                    break
                end
            end
        end

        if not allowed then
            if isHeli then
                return nil, "heli_unsupported"
            end
            return nil
        end
    end

    -- Optionally stop the pilot from running the camera themselves.
    if cfg.driverCanOperate == false and GetPedInVehicleSeat(vehicle, -1) == ped then
        return nil, "driver_blocked"
    end

    return vehicle
end

---------------------------------------------------------------------------
-- Key bindings
---------------------------------------------------------------------------

local KEY_CODES = {
    B = 29, C = 26, E = 38, F = 23, G = 47, H = 74, Q = 44, R = 45, V = 0, X = 73, Z = 20,
    ["1"] = 157, ["2"] = 158, ["3"] = 159, ["4"] = 160, ["5"] = 161,
    ["6"] = 162, ["7"] = 163, ["8"] = 164, ["9"] = 165,
    SPACE = 22,
    SHIFT = 21, LSHIFT = 21,
    CTRL = 36, LCTRL = 36,
    ALT = 19,
    TAB = 37,
    ENTER = 18,
    BACKSPACE = 177, BACK = 177,
    LEFT = 174, RIGHT = 175, UP = 172, DOWN = 173,
    RMB = 25, MOUSE2 = 25,
    LMB = 24, MOUSE1 = 24,
    F1 = 288, F2 = 289, F3 = 170, F5 = 166, F6 = 167, F7 = 168, F8 = 169,
}

local DEFAULT_CONTROLS = {
    mode = 23,       -- F
    spotlight = 38,  -- E
    mark = 47,       -- G
    lock = 25,       -- RMB
    recenter = 22,   -- SPACE
    point = 73,      -- X
    clearPts = 26,   -- C
}

local resolvedControls = nil

-- Returns the control code for an action, using Config.Controls when it names a bindable key.
function Heli.KeyFor(action)
    if not resolvedControls then
        resolvedControls = {}
        local configured = Config.Controls or {}

        for name, default in pairs(DEFAULT_CONTROLS) do
            local setting = configured[name]
            local code = nil

            if setting then
                local keyName = (tostring(setting):upper():gsub("%s", ""))
                code = KEY_CODES[keyName]
            end

            if not code and setting and Config.Debug then
                print(("[oxlyn-helicam] Config.Controls.%s = \"%s\" is not a key I can bind — keeping the default."):format(
                    name, tostring(setting)))
            end

            resolvedControls[name] = code or default
        end
    end

    return resolvedControls[action]
end

-- Flight controls blocked for the pilot while the camera is open (unless Config.Camera.pilotCanFly).
local PILOT_CONTROLS = { 71, 72, 59, 60, 61, 62, 63, 64, 65, 66, 76, 77, 78, 79 }

-- Controls always blocked while the camera is open (look, attack, aim, scroll, etc.).
local CAMERA_CONTROLS = { 1, 2, 24, 25, 22, 23, 38, 47, 14, 15, 241, 242, 75, 73, 26, 19 }

local blockedControls = nil
local blockedControlCount = 0

-- Combines the fixed list with every bound action key, without duplicates.
local function getBlockedControls()
    if blockedControls then
        return blockedControls
    end

    local seen, list = {}, {}
    local function add(code)
        if code and not seen[code] then
            seen[code] = true
            list[#list + 1] = code
        end
    end

    for i = 1, #CAMERA_CONTROLS do
        add(CAMERA_CONTROLS[i])
    end
    for action in pairs(DEFAULT_CONTROLS) do
        add(Heli.KeyFor(action))
    end

    blockedControlCount = #list
    blockedControls = list
    return blockedControls
end

local function disableControls()
    local blocked = getBlockedControls()
    for i = 1, blockedControlCount do
        DisableControlAction(0, blocked[i], true)
    end

    if Heli.isDriver and not Config.Camera.pilotCanFly then
        for i = 1, #PILOT_CONTROLS do
            DisableControlAction(0, PILOT_CONTROLS[i], true)
        end
    end
end

---------------------------------------------------------------------------
-- Camera mount point
---------------------------------------------------------------------------

-- Bones that commonly hold a camera / searchlight, tried in order.
local MOUNT_BONES = {
    "searchlight", "searchlight_dir", "poi_camera", "camera", "weapon_1a", "turret_1base",
}

local DEFAULT_MOUNT = { x = 0.0, y = 1.2, z = -1.1 }

-- Works out where on the helicopter the camera sits: a bone, or an offset.
function Heli.ResolveMount(vehicle)
    local cfg = Config.Camera

    Heli._mountBone = nil
    Heli._mountOff = nil

    if cfg.mountBone ~= "" then
        local bone = -1

        if cfg.mountBone then
            bone = GetEntityBoneIndexByName(vehicle, cfg.mountBone) or -1
        end

        if bone == -1 then
            for i = 1, #MOUNT_BONES do
                bone = GetEntityBoneIndexByName(vehicle, MOUNT_BONES[i]) or -1
                if bone ~= -1 then
                    break
                end
            end
        end

        if bone ~= -1 then
            Heli._mountBone = bone
            Heli._mountDrop = cfg.mountBoneDrop or 0.5
            return
        end
    end

    local modelName = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) or "")
    Heli._mountOff = (cfg.mountByModel and cfg.mountByModel[modelName])
        or cfg.mount
        or DEFAULT_MOUNT
end

function Heli.MountPos(vehicle)
    local bone = Heli._mountBone
    if bone then
        local pos = GetWorldPositionOfEntityBone(vehicle, bone)
        return vector3(pos.x, pos.y, pos.z - (Heli._mountDrop or 0.5))
    end

    local offset = Heli._mountOff or Config.Camera.mount or DEFAULT_MOUNT
    return GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z)
end

---------------------------------------------------------------------------
-- Per-frame camera update
---------------------------------------------------------------------------

local function updateCamera(dt)
    local vehicle = Heli.entity
    local mountPos = Heli.MountPos(vehicle)

    Heli.pos = mountPos
    Heli.camPos = mountPos
    Heli.heliCoords = GetEntityCoords(vehicle)

    local camCfg = Config.Camera
    local minPitch = camCfg.minPitch or -90.0
    local maxPitch = camCfg.maxPitch or 15.0

    if Heli.lock then
        -- Locked on a target: aim at it.
        if Heli.LockTargetPos then
            local target = Heli.LockTargetPos()
            if target then
                local delta = target - mountPos
                local horizontal = math.sqrt(delta.x * delta.x + delta.y * delta.y)

                Heli.camYaw = wrap360(math.deg(math.atan(-delta.x, delta.y)))
                Heli.camPitch = clamp(math.deg(math.atan(delta.z, horizontal)), minPitch, maxPitch)
            end
        end
    else
        -- Free look: mouse input, scaled down as the camera zooms in.
        local sensitivity = (camCfg.sensitivity or 2.2) * ((Heli.fov or 50.0) / (camCfg.defaultFov or 50.0))
        local lookX = GetDisabledControlNormal(0, 1) * sensitivity * 6.0
        local lookY = GetDisabledControlNormal(0, 2) * sensitivity * 6.0

        Heli.camYaw = wrap360((Heli.camYaw or 0.0) - lookX)
        Heli.camPitch = clamp((Heli.camPitch or -35.0) - lookY, minPitch, maxPitch)
    end

    -- Smooth the displayed angles and zoom toward their targets.
    local smoothT = clamp((camCfg.smoothing or 10.0) * dt, 0.0, 1.0)
    Heli.dispYaw = lerpAngle(Heli.dispYaw or Heli.camYaw, Heli.camYaw, smoothT)
    Heli.dispPitch = lerp(Heli.dispPitch or Heli.camPitch, Heli.camPitch, smoothT)
    Heli.lookForward = directionFromAngles(Heli.dispYaw, Heli.dispPitch)

    Heli.fov = lerp(
        Heli.fov or camCfg.defaultFov,
        Heli.fovTarget or camCfg.defaultFov,
        clamp(12.0 * dt, 0.0, 1.0))

    if Heli.cam then
        SetCamCoord(Heli.cam, mountPos.x, mountPos.y, mountPos.z)
        SetCamRot(Heli.cam, Heli.dispPitch, 0.0, Heli.dispYaw, 2)
        SetCamFov(Heli.cam, Heli.fov)
    end
end

---------------------------------------------------------------------------
-- Autopilot (follow locked target / hover when idle)
---------------------------------------------------------------------------

local lastAutopilotTask = 0

local function updateAutopilot(now)
    local followCfg = (Config.Lock and Config.Lock.follow) or {}
    local vehicle = Heli.entity
    local ped = PlayerPedId()

    Heli.isDriver = vehicle and GetPedInVehicleSeat(vehicle, -1) == ped

    -- If the pilot flies manually, never run the autopilot.
    if Config.Camera.pilotCanFly then
        Heli.autopilot = nil
        return
    end

    if not (followCfg.enabled and Heli.isDriver) then
        Heli.autopilot = nil
        return
    end

    SetVehicleEngineOn(vehicle, true, true, false)

    if Heli.lock then
        if Heli.lock.ent and DoesEntityExist(Heli.lock.ent) then
            Heli.autopilot = "follow"

            if now - lastAutopilotTask > 700 then
                lastAutopilotTask = now
                local target = GetEntityCoords(Heli.lock.ent)
                local height = followCfg.height or 55.0

                TaskHeliMission(ped, vehicle, 0, 0,
                    target.x, target.y, target.z,
                    4,
                    followCfg.speed or 30.0,
                    followCfg.radius or 60.0,
                    -1.0,
                    math.floor(height),
                    math.floor(height * 0.5),
                    -1.0)
            end
        end
    else
        if followCfg.hoverWhenIdle ~= false then
            Heli.autopilot = "hover"

            if now - lastAutopilotTask > 900 then
                lastAutopilotTask = now
                local position = GetEntityCoords(vehicle)
                local height = math.max(20.0, GetEntityHeightAboveGround(vehicle))

                TaskHeliMission(ped, vehicle, 0, 0,
                    position.x, position.y, position.z,
                    4, 3.0, 6.0, -1.0,
                    math.floor(height),
                    math.floor(height * 0.6),
                    -1.0)
            end
        else
            Heli.autopilot = nil
        end
    end
end

---------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------

function Heli.Recenter()
    if not (Heli.entity and not Heli.lock) then
        return
    end

    Heli.camYaw = GetEntityHeading(Heli.entity)
    Heli.camPitch = -35.0
    SendNUIMessage({ action = "osd", text = _U("ui_recenter") })
end

local function handleInput()
    -- Ignore input briefly after opening so the opening key press isn't reused.
    if GetGameTimer() - (Heli._openedAt or 0) < 250 then
        return
    end

    -- Record that a key was handled, so the "toggle close" request doesn't also fire.
    local function markConsumed()
        Heli._consumedAt = GetGameTimer()
    end

    local scrollUp = IsDisabledControlJustPressed(0, 241) or IsDisabledControlJustPressed(0, 15)
    local scrollDown = IsDisabledControlJustPressed(0, 242) or IsDisabledControlJustPressed(0, 14)

    if scrollUp or scrollDown then
        local direction = scrollUp and -1 or 1
        local step = direction * (Config.Camera.zoomStep or 2.5)
        local shiftHeld = IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21)

        -- Shift + scroll resizes the spotlight beam instead of zooming.
        if Heli.spotlight and shiftHeld then
            Heli.AdjustSpotlight(-step)
        else
            Heli.SetZoom(step)
        end
    end

    if IsDisabledControlJustPressed(0, Heli.KeyFor("mode")) then
        markConsumed()
        Heli.CycleMode()
    end

    if IsDisabledControlJustPressed(0, Heli.KeyFor("spotlight")) then
        markConsumed()
        Heli.ToggleSpotlight()
    end

    if IsDisabledControlJustPressed(0, Heli.KeyFor("mark")) then
        markConsumed()
        Heli.TagTarget()
    end

    if IsDisabledControlJustPressed(0, Heli.KeyFor("lock")) then
        markConsumed()
        Heli.LockKey()
    end

    if IsDisabledControlJustPressed(0, Heli.KeyFor("recenter")) then
        markConsumed()
        Heli.Recenter()
    end

    if IsDisabledControlJustPressed(0, Heli.KeyFor("point")) then
        markConsumed()
        Heli.DropMarker()
    end

    if IsDisabledControlJustPressed(0, Heli.KeyFor("clearPts")) then
        markConsumed()
        Heli.ClearMarkers()
    end

    Heli.UnitsKey()
end

---------------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------------

local function startLoop()
    local session = Heli.session

    CreateThread(function()
        local lastTime = GetGameTimer()

        while true do
            -- Stop if the feed closed or a newer session replaced this one.
            if not Heli.active or Heli.session ~= session then
                break
            end

            local now = GetGameTimer()
            local dt = clamp((now - lastTime) / 1000.0, 0.0, 0.1)
            lastTime = now

            local ped = PlayerPedId()
            Heli._tick = now

            -- Close the feed if the player left the helicopter or died.
            local stillValid = Heli.entity
                and DoesEntityExist(Heli.entity)
                and IsPedInVehicle(ped, Heli.entity, false)
                and not IsEntityDead(ped)

            if not stillValid then
                Heli.Close("exited")
                break
            end

            local ok, err = pcall(function()
                disableControls()

                -- Keep the native searchlight in step with our spotlight (throttled).
                if now - (Heli._slAt or 0) > 250 then
                    Heli._slAt = now
                    SetVehicleSearchlight(Heli.entity,
                        (Config.Camera.useHeliSearchlight and Heli.spotlight) == true, false)
                end

                updateCamera(dt)

                if Heli.spotlight then
                    Heli.RenderSpotlight()
                end

                Heli.LockTick(dt)
                Heli.DrawTargets()
                updateAutopilot(now)
                handleInput()

                -- Send telemetry to the HUD every 200 ms.
                if now - (Heli._teleAt or 0) > 200 then
                    Heli._teleAt = now
                    Heli.PushTelemetry()
                end

                -- Keep the server-side claim alive.
                if Heli.claimNet and now - (Heli._hbAt or 0) > 5000 then
                    Heli._hbAt = now
                    TriggerServerEvent("oxlyn-helicam:heartbeat", Heli.claimNet)
                end
            end)

            if not ok then
                print("^1[oxlyn-helicam] camera frame failed, closing the feed: ^7" .. tostring(err))
                Heli.Close("error")
                break
            end

            -- Deferred "toggle" close: only honoured if no other key consumed the press.
            local closeRequest = Heli._closeReq
            if closeRequest and now - closeRequest >= 40 then
                Heli._closeReq = nil
                if math.abs((Heli._consumedAt or -1.0e9) - closeRequest) > 100 then
                    Heli.Close("toggle")
                    break
                end
            end

            Wait(0)
        end
    end)
end

-- Watchdog: if the camera loop stops ticking, force everything closed.
CreateThread(function()
    while true do
        Wait(1000)

        if Heli.active then
            if GetGameTimer() - (Heli._tick or 0) > 2500 then
                print("^3[oxlyn-helicam] camera loop stalled — forcing the feed closed.^7")
                pcall(Heli.Close, "watchdog")
                Heli.HardReset(true)
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------------

function Heli.Open()
    if Heli.active or Heli.opening then
        return
    end

    Heli.session = (Heli.session or 0) + 1
    local session = Heli.session

    local heli, reason = Heli.CurrentHeli()
    if not heli then
        local silent = (Config.Vehicles or {}).notifyUnsupported == false

        if reason == "driver_blocked" then
            Notify.Send(_U("need_operator_seat"), "error")
        elseif not silent then
            Notify.Send(_U(reason == "heli_unsupported" and "heli_unsupported" or "not_in_heli"), "error")
        end
        return
    end

    local netId = (NetworkGetEntityIsNetworked(heli) and NetworkGetNetworkIdFromEntity(heli)) or 0

    Heli.opening = true

    -- Ask the server to claim this helicopter's camera.
    Framework.TriggerCallback("oxlyn-helicam:claim", function(result)
        Heli.opening = false

        local function release()
            if netId > 0 then
                TriggerServerEvent("oxlyn-helicam:release", netId)
            end
        end

        -- A newer session started, or the camera opened another way, while we waited.
        if Heli.session ~= session or Heli.active then
            release()
            return
        end

        if type(result) ~= "table" then
            release()
            Notify.Send(_U("cam_link_failed"), "error")
            return
        end

        if not result.ok then
            Notify.Send(_U(result.reason or "cam_in_use"), "error")
            return
        end

        -- The player must still be in the same helicopter.
        if Heli.CurrentHeli() ~= heli then
            release()
            return
        end

        Heli.claimNet = (netId > 0 and result.exclusive ~= false and netId) or nil
        Heli._doOpen(heli)
    end, netId)
end

function Heli._doOpen(vehicle)
    Heli.entity = vehicle
    Heli.operator = PlayerPedId()

    Heli.camYaw = GetEntityHeading(vehicle)
    Heli.camPitch = -35.0
    Heli.dispYaw = Heli.camYaw
    Heli.dispPitch = Heli.camPitch

    Heli.fov = Config.Camera.defaultFov
    Heli.fovTarget = Config.Camera.defaultFov

    Heli.modeIndex = 1
    Heli.spotlight = false
    Heli.spotRadius = nil
    Heli.lock = nil
    Heli.view = "gimbal"
    Heli._markerN = 0

    Heli._slAt = 0
    Heli._teleAt = 0
    Heli._hbAt = GetGameTimer()
    Heli._tick = GetGameTimer()
    Heli._openedAt = GetGameTimer()
    Heli._consumedAt = nil
    Heli._closeReq = nil

    Heli.ResolveMount(vehicle)
    Heli.pos = Heli.MountPos(vehicle)
    Heli.camPos = Heli.pos
    Heli.lookForward = directionFromAngles(Heli.dispYaw, Heli.dispPitch)

    -- Remember the native searchlight state so it can be restored on close.
    Heli._nativeSL = IsVehicleSearchlightOn(vehicle)
    if Config.Camera.useHeliSearchlight then
        SetVehicleSearchlight(vehicle, false, false)
    end

    SetUserRadioControlEnabled(false)

    Heli.SetupCamera()
    Heli.ApplyVisionMode(true)
    Heli.OpenHUD()
    Heli.active = true

    Notify.Send(_U("cam_online"), "success")
    startLoop()
end

function Heli.Close(reason)
    if not Heli.active then
        Heli.HardReset(true)
        return
    end

    Heli.active = false
    Heli.opening = false
    Heli._closeReq = nil
    Heli.session = (Heli.session or 0) + 1

    Heli.DestroyCamera()

    if Heli.ClearLock then
        Heli.ClearLock()
    end
    if Heli.ClearTags then
        Heli.ClearTags(true)
    end

    Heli.CloseHUD()
    SetUserRadioControlEnabled(true)

    -- Restore the helicopter's native searchlight.
    if Heli.entity and DoesEntityExist(Heli.entity) then
        SetVehicleSearchlight(Heli.entity, Heli._nativeSL == true, true)
    end

    -- Stop any autopilot task if we were the pilot.
    if Heli.entity and DoesEntityExist(Heli.entity) then
        if GetPedInVehicleSeat(Heli.entity, -1) == PlayerPedId() then
            ClearPedTasks(PlayerPedId())
        end
    end

    Heli.autopilot = nil
    Heli.entity = nil

    if Heli.ClearMarkers then
        Heli.ClearMarkers(true)
    end

    if Heli.claimNet then
        TriggerServerEvent("oxlyn-helicam:release", Heli.claimNet)
        Heli.claimNet = nil
    end

    if reason == "exited" then
        Notify.Send(_U("cam_closed_exit"), "info")
    end
end

-- Opens the camera, or requests a close (closing is deferred so a key press
-- that triggered another action in the same frame doesn't also close the feed).
function Heli.Toggle()
    if Heli.active then
        Heli._closeReq = GetGameTimer()
    elseif Heli.opening then
        Heli.opening = false
        Heli.session = (Heli.session or 0) + 1
    else
        Heli.Open()
    end
end

-- Forcefully tears down everything, each stage protected so one failure can't block the rest.
function Heli.HardReset(silent)
    Heli.active = false
    Heli.opening = false
    Heli._consumedAt = nil
    Heli._closeReq = nil
    Heli.spotlight = false
    Heli.autopilot = nil

    pcall(function()
        SendNUIMessage({ action = "close" })
        SendNUIMessage({ action = "reset" })
        SetNuiFocus(false, false)
    end)

    pcall(function()
        if Heli.DestroyCamera then
            Heli.DestroyCamera()
        end
        RenderScriptCams(false, false, 0, true, true)
        SetNightvision(false)
        SetSeethrough(false)
        ClearTimecycleModifier()
        SetTimecycleModifierStrength(1.0)
    end)

    pcall(function()
        if Heli.ClearLock then
            Heli.ClearLock()
        end
        if Heli.ClearTags then
            Heli.ClearTags(true)
        end
        if Heli.ClearMarkers then
            Heli.ClearMarkers(true)
        end
        if Heli.WipeSharedMarkers then
            Heli.WipeSharedMarkers()
        end
    end)

    pcall(function()
        SetUserRadioControlEnabled(true)
        if Heli.entity and DoesEntityExist(Heli.entity) then
            SetVehicleSearchlight(Heli.entity, Heli._nativeSL == true, true)
        end
    end)

    if Heli.claimNet then
        pcall(TriggerServerEvent, "oxlyn-helicam:release", Heli.claimNet)
        Heli.claimNet = nil
    end

    Heli.entity = nil

    if not silent then
        Notify.Send(_U("cam_reset"), "success")
    end
end

---------------------------------------------------------------------------
-- Resource lifecycle
---------------------------------------------------------------------------

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Heli.active then
        pcall(Heli.Close, "stop")
    end
    Heli.HardReset(true)
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Heli.HardReset(true)
end)