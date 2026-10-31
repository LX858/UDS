-- Cleaned-up version of the decompiled helicopter camera HUD script.
-- Logic is unchanged; names and structure were reconstructed from the decompiler output.
-- Extends the global `Heli` table shared with the other camera files.

---------------------------------------------------------------------------
-- HUD open message
---------------------------------------------------------------------------

-- Builds the NUI "open" message: locale strings plus the HUD configuration.
local function buildOpenMessage()
    local unitCfg = Config.Unit or {}

    local job = Framework.GetJob and Framework.GetJob() or nil
    local jobName = job and job.name

    local department = (unitCfg.departmentByJob and jobName and unitCfg.departmentByJob[jobName])
        or unitCfg.default
        or ""

    local callsign = (unitCfg.callsign and unitCfg.callsign ~= "" and unitCfg.callsign)
        or _U("ui_unit")

    return {
        action = "open",
        locale = GetLocaleTable(),
        cfg = {
            unit = callsign,
            department = department,
            lockOn = (Config.Lock and Config.Lock.enabled) or false,
            followOn = (Config.Lock and Config.Lock.follow and Config.Lock.follow.enabled) or false,
            maxRange = (Config.Lock and Config.Lock.maxRange) or 400.0,
            spotOn = (Config.Camera.spotlight and Config.Camera.spotlight.enabled) or false,
            speedLabel = Heli.SpeedLabel(),
            unitsToggle = (Config.Units and Config.Units.allowToggle) ~= false,
            unitsKey = (Config.Units and Config.Units.toggleKey) or nil,
            controls = Config.Controls,
        },
    }
end

function Heli.OpenHUD()
    SendNUIMessage(buildOpenMessage())
end

function Heli.CloseHUD()
    SendNUIMessage({ action = "close" })
end

-- The NUI page asks for its state once it has finished loading.
RegisterNUICallback("ready", function(_, cb)
    if Heli.active then
        SendNUIMessage(buildOpenMessage())

        if Heli.ApplyVisionMode then
            Heli.ApplyVisionMode(true)
        end
        if Heli.PushTelemetry then
            Heli.PushTelemetry()
        end
    else
        SendNUIMessage({ action = "close" })
    end

    cb({ ok = true })
end)

---------------------------------------------------------------------------
-- Telemetry
---------------------------------------------------------------------------

-- Returns plate / speed / model for the vehicle the camera is locked on or aimed at,
-- or nil when there isn't one.
local function getAimedVehicleInfo()
    local target = nil

    if Heli.lock then
        if Heli.lock.kind == "vehicle" and Heli.lock.ent and DoesEntityExist(Heli.lock.ent) then
            target = Heli.lock.ent
        end
    else
        -- Not locked: use the aimed entity if it was seen within the last 500 ms.
        if Heli.aimEnt and DoesEntityExist(Heli.aimEnt) and Heli.aimKind == "vehicle" then
            if GetGameTimer() - (Heli.aimAt or 0) <= 500 then
                target = Heli.aimEnt
            end
        end
    end

    if not target then
        return nil
    end

    local plate = (GetVehicleNumberPlateText(target) or ""):gsub("%s+$", "")

    return {
        plate = plate,
        speed = math.floor(Heli.ToSpeed(GetEntitySpeed(target) * 3.6)),
        model = GetDisplayNameFromVehicleModel(GetEntityModel(target)) or "",
    }
end

-- Sends the current flight / camera / lock state to the HUD.
function Heli.PushTelemetry()
    local camCfg = Config.Camera
    local defaultFov = camCfg.defaultFov or 50.0
    local zoom = defaultFov / (Heli.fov or defaultFov)

    local vehicle = Heli.entity
    local vehicleExists = vehicle and DoesEntityExist(vehicle)

    local heliCoords = Heli.heliCoords
        or (vehicleExists and GetEntityCoords(vehicle))
        or vector3(0, 0, 0)

    local altitude = vehicleExists and math.max(0.0, GetEntityHeightAboveGround(vehicle)) or 0.0
    local speed = vehicleExists and Heli.ToSpeed(GetEntitySpeed(vehicle) * 3.6) or 0.0
    local heliHeading = vehicleExists and GetEntityHeading(vehicle) or 0.0

    local camPos = Heli.camPos or heliCoords

    -- Info about the locked target, if any.
    local lockBearing, targetSpeed, targetType = nil, nil, nil
    local lockEnt = Heli.lock and Heli.lock.ent

    if lockEnt and DoesEntityExist(lockEnt) then
        local delta = GetEntityCoords(lockEnt) - camPos
        lockBearing = math.deg(math.atan(-delta.x, delta.y)) % 360.0
        targetType = Heli.lock.kind

        if Heli.lock.kind == "vehicle" then
            targetSpeed = Heli.ToSpeed(GetEntitySpeed(lockEnt) * 3.6)
        end
    end

    SendNUIMessage({
        action = "telemetry",
        alt = altitude,
        altMsl = heliCoords.z or 0.0,
        speed = speed,
        heading = Heli.dispYaw or 0.0,
        pitch = Heli.dispPitch or 0.0,
        heliHdg = heliHeading,
        zoom = zoom,
        fov = Heli.fov or defaultFov,
        posX = math.floor(camPos.x or 0),
        posY = math.floor(camPos.y or 0),
        spotlight = Heli.spotlight == true,
        spotBeam = Heli.spotRadius
            or (camCfg.spotlight and camCfg.spotlight.radius)
            or 9.0,
        lrf = Heli.lrfDist,
        lockState = Heli.lockState,
        lockProgress = Heli.lockProgress or 0.0,
        lockSignal = Heli.lockSignal or 1.0,
        lockDist = Heli.lockTargetDist,
        lockBearing = lockBearing,
        tgtSpeed = targetSpeed,
        tgtType = targetType,
        aimVeh = getAimedVehicleInfo(),
        clock = string.format("%02d:%02d:%02d", GetClockHours(), GetClockMinutes(), GetClockSeconds()),
        autopilot = Heli.autopilot,
        isDriver = Heli.isDriver == true,
        spotted = Heli.spottedCount or 0,
    })
end