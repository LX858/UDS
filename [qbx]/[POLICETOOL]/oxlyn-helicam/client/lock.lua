-- Cleaned-up version of the decompiled helicopter camera target-lock script.
-- Logic is unchanged; names and structure were reconstructed from the decompiler output.
-- Extends the global `Heli` table shared with the other camera files.

local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local seeking = false        -- the player is trying to acquire a lock
local seekTarget = nil       -- { ent, kind } currently being acquired
local seekProgress = 0.0     -- 0..1 acquisition progress
local candidate = nil        -- { ent, kind } best target under the crosshair
local lastScanTime = 0
local lockSignal = 1.0       -- 1.0 = target visible, drops toward 0 while hidden
local hiddenSince = 0        -- time the locked target became hidden (0 = visible)

local function lockConfig()
    return Config.Lock or {}
end

---------------------------------------------------------------------------
-- Line of sight
---------------------------------------------------------------------------

local function hasLineOfSight(entity)
    if not (Heli.entity and DoesEntityExist(Heli.entity) and DoesEntityExist(entity)) then
        return false
    end

    local isVehicle = IsEntityAVehicle(entity)

    if HasEntityClearLosToEntity(Heli.entity, entity, isVehicle and 19 or 17) then
        return true
    end

    -- Native check failed; confirm with a probe aimed at the target's upper body / roof.
    local origin = Heli.pos
    local targetPos = GetEntityCoords(entity) + vector3(0.0, 0.0, isVehicle and 1.0 or 0.5)
    local distance = #(targetPos - origin)

    local probe = _ENV["StartExpensiveSynchronousShapeTestLosProbe"](
        origin.x, origin.y, origin.z,
        targetPos.x, targetPos.y, targetPos.z,
        1, Heli.entity, 7)

    local _, hit, endCoords = GetShapeTestResult(probe)
    if not hit or not endCoords then
        return true
    end

    local hitDistance = #(vector3(endCoords.x, endCoords.y, endCoords.z) - origin)
    return hitDistance >= distance - (isVehicle and 3.5 or 1.6)
end

-- Thermal view, or LOS checking switched off, means everything counts as visible.
local function canSee(entity)
    if Heli.thermal or not (Config.Lock and Config.Lock.requireLos) then
        return true
    end
    return hasLineOfSight(entity)
end

---------------------------------------------------------------------------
-- Lock management
---------------------------------------------------------------------------

function Heli.LockTargetPos()
    local lock = Heli.lock
    if not (lock and lock.ent and DoesEntityExist(lock.ent)) then
        return nil
    end
    return GetEntityCoords(lock.ent)
end

-- Drops the current lock and acquisition state, optionally notifying the player.
local function releaseLock(messageKey, messageType)
    Heli.lock = nil
    seeking = false
    seekTarget = nil
    seekProgress = 0.0
    lockSignal = 1.0
    hiddenSince = 0
    Heli.lockSignal = 1.0
    Heli.lockGraceUntil = nil

    if messageKey then
        Notify.Send(_U(messageKey), messageType or "info")
    end
end

-- Silent full reset (no notification).
function Heli.ClearLock()
    Heli.lock = nil
    seeking = false
    seekTarget = nil
    seekProgress = 0.0
    candidate = nil

    Heli.lockProgress = 0.0
    Heli.lockState = nil
    Heli.lockGraceUntil = nil
end

function Heli.CancelSeeking()
    seeking = false
    seekTarget = nil
    seekProgress = 0.0
    candidate = nil
end

-- Called when the locked target comes back into view: restores signal and grants a grace period.
function Heli.OnLockReenter()
    if not Heli.lock then return end

    lockSignal = 1.0
    Heli.lockSignal = 1.0
    hiddenSince = 0
    Heli.lockGraceUntil = GetGameTimer() + 3500
end

function Heli.HasLock()
    return Heli.lock ~= nil
end

-- Lock key: release an existing lock, otherwise start / stop acquiring one.
function Heli.LockKey()
    if not lockConfig().enabled then return end
    if Heli.view == "external" then return end

    if Heli.lock then
        releaseLock("lock_released", "info")
        return
    end

    seeking = not seeking
    if not seeking then
        seekTarget = nil
        seekProgress = 0.0
    end
end

---------------------------------------------------------------------------
-- Candidate scanning
---------------------------------------------------------------------------

-- Scan state, set up at the start of each scan and used by considerEntity.
local camX, camY, camZ = 0.0, 0.0, 0.0
local fwdX, fwdY, fwdZ = 0.0, 0.0, 0.0
local maxRangeSq = 0.0
local bestDot = 0.0
local bestEnt = nil
local bestKind = nil

-- Keeps the entity if it is closer to the crosshair direction than the best so far.
local function considerEntity(entity, kind, zOffset)
    if not (entity ~= Heli.entity and DoesEntityExist(entity)) then
        return
    end

    if kind == "ped" and IsEntityDead(entity) then
        return
    end

    -- Ignore people inside our own helicopter.
    if kind == "ped" and IsPedInAnyVehicle(entity, false) then
        if GetVehiclePedIsIn(entity, false) == Heli.entity then
            return
        end
    end

    local coords = GetEntityCoords(entity)
    local dx = coords.x - camX
    local dy = coords.y - camY
    local dz = (coords.z + zOffset) - camZ
    local distSq = dx * dx + dy * dy + dz * dz

    if distSq > maxRangeSq or distSq < 0.25 then
        return
    end

    local invDist = 1.0 / math.sqrt(distSq)
    local dot = (dx * fwdX + dy * fwdY + dz * fwdZ) * invDist

    if dot > bestDot then
        bestDot = dot
        bestEnt = entity
        bestKind = kind
    end
end

-- Finds the ped / vehicle closest to the camera's look direction, within a cone.
local function scanCandidates()
    local cfg = lockConfig()
    local origin = Heli.camPos or Heli.pos
    local forward = Heli.lookForward

    if not origin or not forward then
        candidate = nil
        return
    end

    -- The cone narrows as the camera zooms in.
    local fov = Heli.fov or 55.0
    local coneDegrees = clamp((cfg.lockRadius or 0.1) * fov * 1.6, 3.0, 22.0)
    local maxRange = cfg.maxRange or 220.0

    camX, camY, camZ = origin.x, origin.y, origin.z
    fwdX, fwdY, fwdZ = forward.x, forward.y, forward.z
    maxRangeSq = maxRange * maxRange
    bestDot = math.cos(math.rad(coneDegrees))
    bestEnt, bestKind = nil, nil

    if cfg.peds ~= false then
        local skipOccupants = cfg.ignoreVehicleOccupants ~= false
        local peds = GetGamePool("CPed")
        for i = 1, #peds do
            local ped = peds[i]
            if not (skipOccupants and IsPedInAnyVehicle(ped, false)) then
                considerEntity(ped, "ped", 0.4)
            end
        end
    end

    if cfg.vehicles ~= false then
        local vehicles = GetGamePool("CVehicle")
        for i = 1, #vehicles do
            considerEntity(vehicles[i], "vehicle", 0.2)
        end
    end

    -- A target that is hidden from view can't be picked.
    if bestEnt and not canSee(bestEnt) then
        bestEnt = nil
    end

    -- Fall back to whatever the aim probe is hitting.
    if not bestEnt then
        local aimEnt = Heli.aimEnt
        if aimEnt and aimEnt ~= Heli.entity and DoesEntityExist(aimEnt) then
            local kind = Heli.aimKind
            local acceptable = (kind == "ped" and cfg.peds ~= false and not IsEntityDead(aimEnt))
                or (kind == "vehicle" and cfg.vehicles ~= false)

            if acceptable then
                bestEnt = aimEnt
                bestKind = kind
            end
        end
    end

    candidate = bestEnt and { ent = bestEnt, kind = bestKind } or nil
end

---------------------------------------------------------------------------
-- Screen-space target boxes
---------------------------------------------------------------------------

-- The 8 corners of a bounding box: 1 = use the max extent on that axis, 0 = use the min.
local BOX_CORNERS = {
    { 0, 0, 0 }, { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 },
    { 1, 1, 0 }, { 1, 0, 1 }, { 0, 1, 1 }, { 1, 1, 1 },
}

local modelDimsCache = {}   -- [model] = { min, max }
local screenBoxCache = {}   -- [entity] = { t, ok, x, y, w, h }
local lastBoxCacheReset = 0

local function getModelDims(model)
    local dims = modelDimsCache[model]
    if not dims then
        local min, max = GetModelDimensions(model)
        dims = { min, max }
        modelDimsCache[model] = dims
    end
    return dims[1], dims[2]
end

-- Projects an entity's bounding box to the screen.
-- Returns centreX, centreY, width, height (screen fractions) or nil if not usable.
-- Results are cached for ~33 ms per entity.
local function getScreenBox(entity)
    local now = GetGameTimer()

    if now - lastBoxCacheReset > 15000 then
        lastBoxCacheReset = now
        screenBoxCache = {}
    end

    local entry = screenBoxCache[entity]
    if entry and now - entry.t < 33 then
        if not entry.ok then
            return nil
        end
        return entry.x, entry.y, entry.w, entry.h
    end

    local min, max = getModelDims(GetEntityModel(entity))

    local minX, minY = 1.0e9, 1.0e9
    local maxX, maxY = -1.0e9, -1.0e9
    local anyVisible = false

    for i = 1, 8 do
        local corner = BOX_CORNERS[i]
        local world = GetOffsetFromEntityInWorldCoords(
            entity,
            corner[1] == 1 and max.x or min.x,
            corner[2] == 1 and max.y or min.y,
            corner[3] == 1 and max.z or min.z)

        local onScreen, sx, sy = World3dToScreen2d(world.x, world.y, world.z)
        if onScreen then
            anyVisible = true
            if minX > sx then minX = sx end
            if maxX < sx then maxX = sx end
            if minY > sy then minY = sy end
            if maxY < sy then maxY = sy end
        end
    end

    if not entry then
        entry = {}
        screenBoxCache[entity] = entry
    end
    entry.t = now

    if not anyVisible then
        entry.ok = false
        return nil
    end

    local padding = 0.01
    local width = math.max((maxX - minX) + padding * 2, 0.022)
    local height = math.max((maxY - minY) + padding * 2, 0.032)
    local centreX = (minX + maxX) * 0.5
    local centreY = (minY + maxY) * 0.5

    -- Reject boxes that are huge or mostly off-screen.
    if width > 0.85 or height > 0.85
        or centreX < -0.25 or centreX > 1.25
        or centreY < -0.25 or centreY > 1.25 then
        entry.ok = false
        return nil
    end

    entry.x, entry.y, entry.w, entry.h = centreX, centreY, width, height
    entry.ok = true
    return centreX, centreY, width, height
end

-- Draws four corner brackets around a box.
local function drawCornerBrackets(cx, cy, w, h, r, g, b, a)
    local thin = 0.0016   -- thickness of vertical arms
    local thick = 0.0028  -- thickness of horizontal arms
    local armW = w * 0.4
    local armH = h * 0.4

    -- Top-left
    DrawRect(cx - w / 2 + armW / 2, cy - h / 2, armW, thick, r, g, b, a)
    DrawRect(cx - w / 2, cy - h / 2 + armH / 2, thin, armH, r, g, b, a)
    -- Top-right
    DrawRect(cx + w / 2 - armW / 2, cy - h / 2, armW, thick, r, g, b, a)
    DrawRect(cx + w / 2, cy - h / 2 + armH / 2, thin, armH, r, g, b, a)
    -- Bottom-left
    DrawRect(cx - w / 2 + armW / 2, cy + h / 2, armW, thick, r, g, b, a)
    DrawRect(cx - w / 2, cy + h / 2 - armH / 2, thin, armH, r, g, b, a)
    -- Bottom-right
    DrawRect(cx + w / 2 - armW / 2, cy + h / 2, armW, thick, r, g, b, a)
    DrawRect(cx + w / 2, cy + h / 2 - armH / 2, thin, armH, r, g, b, a)
end

local function drawLabel(text, x, y, r, g, b, a)
    SetTextScale(0.27, 0.27)
    SetTextFont(0)
    SetTextColour(r, g, b, a)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Draws the on-screen box for one target. `state` is "locked", "acq" or anything else (candidate).
local function drawTargetBox(entity, kind, now, state)
    if not DoesEntityExist(entity) then return end

    local cx, cy, w, h = getScreenBox(entity)
    if not cx then return end

    local distance = #(GetEntityCoords(entity) - (Heli.pos or GetEntityCoords(entity)))

    if state == "locked" then
        -- Pulsing red brackets with side ticks and a distance label.
        local alpha = 200 + math.floor(45 * math.abs(math.sin(now / 300.0)))
        drawCornerBrackets(cx, cy, w, h, 255, 68, 56, alpha)
        DrawRect(cx - w / 2 - 0.006, cy, 0.004, 0.007, 255, 68, 56, alpha)
        DrawRect(cx + w / 2 + 0.006, cy, 0.004, 0.007, 255, 68, 56, alpha)

        local label = ("%s · %dm"):format(_U("ui_lock"), math.floor(distance))
        drawLabel(label, cx, cy - h / 2 - 0.024, 255, 68, 56, 240)

    elseif state == "acq" then
        -- Amber brackets that shrink onto the target as acquisition progresses.
        local scale = 1.35 - seekProgress * 0.35
        drawCornerBrackets(cx, cy, w * scale, h * scale, 255, 161, 40, 205)

        local label = ("%s %d%%"):format(_U("ui_acq"), math.floor(seekProgress * 100))
        drawLabel(label, cx, cy - (h * scale) / 2 - 0.024, 255, 161, 40, 235)

    else
        drawCornerBrackets(cx, cy, w, h, 225, 225, 220, 120)
    end

    -- Vehicles also get a plate + speed label underneath.
    if kind == "vehicle" then
        local plate = (GetVehicleNumberPlateText(entity) or ""):gsub("%s+$", "")
        local text = (plate ~= "" and plate) or "—"
        text = text .. "  ·  " .. Heli.FormatSpeed(GetEntitySpeed(entity) * 3.6)

        local r, g, b = 230, 230, 226
        if state == "locked" then
            r, g, b = 255, 68, 56
        elseif state == "acq" then
            r, g, b = 255, 161, 40
        end

        drawLabel(text, cx, cy + h / 2 + 0.016, r, g, b, 225)
    end
end

---------------------------------------------------------------------------
-- Per-frame lock logic
---------------------------------------------------------------------------

function Heli.LockTick(dt)
    local cfg = lockConfig()
    if not Heli.active then return end

    if not cfg.enabled then
        Heli.lockProgress = 0.0
        Heli.lockState = nil
        return
    end

    if not (dt and dt > 0.0) then
        dt = 0.016
    end

    local now = GetGameTimer()

    -- While not locked, keep looking for candidates (faster while actively seeking).
    if Heli.lock then
        candidate = nil
    else
        local interval = seeking and 66 or 250
        if now - lastScanTime > interval then
            lastScanTime = now
            scanCandidates()
        end
    end

    -- Maintain an existing lock.
    if Heli.lock then
        local lock = Heli.lock

        -- Re-resolve the entity from its network id if the handle went stale.
        if not (lock.ent and DoesEntityExist(lock.ent)) then
            if lock.net and lock.net ~= 0 and NetworkDoesNetworkIdExist(lock.net) then
                local entity = NetworkGetEntityFromNetworkId(lock.net)
                if entity and entity ~= 0 and DoesEntityExist(entity) then
                    lock.ent = entity
                end
            end
        end

        local lost = not DoesEntityExist(lock.ent)

        if lost then
            -- Give a short grace period before giving up on a vanished target.
            if not Heli.lockGraceUntil then
                Heli.lockGraceUntil = now + 2500
            end

            if now < Heli.lockGraceUntil then
                Heli.lockProgress = 1.0
                Heli.lockState = "locked"
                return
            end

            releaseLock("lock_lost", "error")

        elseif lock.kind == "ped" and IsEntityDead(lock.ent) then
            releaseLock("lock_lost", "error")

        else
            Heli.lockGraceUntil = nil

            if canSee(lock.ent) then
                hiddenSince = 0
                lockSignal = math.min(1.0, lockSignal + dt * 3.0)
            else
                if hiddenSince == 0 then
                    hiddenSince = now
                end

                -- After being hidden for a while, the signal fades; at zero the lock drops.
                if now - hiddenSince > (cfg.hiddenHold or 700) then
                    lockSignal = lockSignal - dt / (cfg.losGraceSeconds or 4.0)

                    if lockSignal <= 0.0 then
                        releaseLock("lock_lost", "error")
                        Heli.lockState = nil
                        Heli.lockProgress = 0.0
                        Heli.lockSignal = 1.0
                        return
                    end
                end
            end

            Heli.lockSignal = lockSignal
            drawTargetBox(lock.ent, lock.kind, now, "locked")
            Heli.lockProgress = 1.0
            Heli.lockState = "locked"
            return
        end
    end

    -- Acquiring a new lock.
    if seeking and Heli.view ~= "external" then
        if candidate and DoesEntityExist(candidate.ent) then
            seekTarget = candidate
            seekProgress = math.min(1.0, seekProgress + dt / (cfg.lockTime or 1.6))
            drawTargetBox(seekTarget.ent, seekTarget.kind, now, "acq")

            if seekProgress >= 1.0 then
                local target = seekTarget
                local targetPos = GetEntityCoords(target.ent)
                local distanceCfg = cfg.followDistance or {}
                local heightCfg = cfg.followHeight or {}

                local horizontalDistance = #vector3(Heli.pos.x - targetPos.x, Heli.pos.y - targetPos.y, 0.0)

                local netId = 0
                if NetworkGetEntityIsNetworked(target.ent) then
                    netId = NetworkGetNetworkIdFromEntity(target.ent)
                end

                Heli.lock = { ent = target.ent, kind = target.kind, net = netId }
                Heli.lockDist = clamp(horizontalDistance, distanceCfg.min or 8.0, distanceCfg.max or 40.0)
                Heli.lockHeight = clamp(Heli.pos.z - targetPos.z, heightCfg.min or 6.0, heightCfg.max or 50.0)

                seeking = false
                seekTarget = nil
                seekProgress = 0.0
                Heli.lockSignal = 1.0
                hiddenSince = 0
                lockSignal = 1.0

                Notify.Send(_U("lock_acquired"), "success")
                SendNUIMessage({ action = "tag" })
            end
        else
            -- Lost the candidate: progress drains back down.
            seekProgress = math.max(0.0, seekProgress - dt * 1.3)

            if seekTarget and DoesEntityExist(seekTarget.ent) then
                drawTargetBox(seekTarget.ent, seekTarget.kind, now, "acq")
            end
        end
    else
        -- Not seeking: just outline the current candidate.
        if candidate and DoesEntityExist(candidate.ent) then
            drawTargetBox(candidate.ent, candidate.kind, now, "candidate")
        end
    end

    -- Publish state for the HUD.
    Heli.lockState = (Heli.lock and "locked") or (seeking and "acq") or nil
    Heli.lockProgress = (Heli.lock and 1.0) or seekProgress
    Heli.lockSeeking = seeking

    local targetEnt = (Heli.lock and Heli.lock.ent)
        or (seekTarget and seekTarget.ent)
        or (candidate and candidate.ent)

    Heli.lockTargetDist = (targetEnt and DoesEntityExist(targetEnt)
        and #(GetEntityCoords(targetEnt) - Heli.pos)) or nil
end