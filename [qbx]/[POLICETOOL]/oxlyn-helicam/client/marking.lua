-- Cleaned-up version of the decompiled helicopter camera tagging / aim script.
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

-- Returns the player index that owns a ped, or -1 if it isn't a player.
local function playerFromPed(ped)
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerPed(player) == ped then
            return player
        end
    end
    return -1
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local lastTagTime = 0
local tagCounter = 0
local tags = {}              -- { ped, coords, isPlayer, num, expiry }
local hoverCandidate = nil   -- { ped, t } ped currently under the crosshair
local lastAimTime = 0

local blips = {}             -- [key] = blip handle
local blipTokens = {}        -- [key] = counter, so stale removal timers can be ignored

---------------------------------------------------------------------------
-- Aim probe
---------------------------------------------------------------------------

-- Turns an entity hit by a probe into (entity, kind). A ped sitting in a vehicle counts as
-- the vehicle, unless Config.Lock.ignoreVehicleOccupants is false.
local function classifyHit(entity)
    if IsEntityAPed(entity) then
        if not IsEntityDead(entity) then
            local ignoreOccupants = Config.Lock and Config.Lock.ignoreVehicleOccupants
            local vehicle = (ignoreOccupants ~= false and GetVehiclePedIsIn(entity, false)) or 0

            if vehicle ~= 0 then
                return vehicle, "vehicle"
            end
            return entity, "ped"
        end
    elseif IsEntityAVehicle(entity) then
        return entity, "vehicle"
    end
    return nil, nil
end

-- Casts a ray along the camera's look direction.
-- Returns entity, kind ("ped" / "vehicle"), distance to whatever was hit.
local function aimProbe()
    local origin = Heli.pos
    local forward = Heli.lookForward
    if not origin or not forward then
        return nil, nil, nil
    end

    local startPos = origin + forward * 0.8
    local endPos = origin + forward * (Config.Marking.maxRange or 250.0)

    local probe = _ENV["StartExpensiveSynchronousShapeTestLosProbe"](
        startPos.x, startPos.y, startPos.z,
        endPos.x, endPos.y, endPos.z,
        -1, Heli.entity, 4)

    local _, hit, endCoords, _, hitEntity = GetShapeTestResult(probe)

    local distance, entity, kind = nil, nil, nil

    if hit then
        if endCoords then
            distance = #(vector3(endCoords.x, endCoords.y, endCoords.z) - origin)
        end

        if hitEntity and hitEntity ~= 0 then
            entity, kind = classifyHit(hitEntity)
        end
    end

    -- In thermal view, try again with a probe that also hits peds directly.
    if Heli.thermal and not entity then
        local thermalProbe = _ENV["StartExpensiveSynchronousShapeTestLosProbe"](
            startPos.x, startPos.y, startPos.z,
            endPos.x, endPos.y, endPos.z,
            6, Heli.entity, 4)

        local _, thermalHit, _, _, thermalEntity = GetShapeTestResult(thermalProbe)

        if thermalHit and thermalEntity and thermalEntity ~= 0 then
            entity, kind = classifyHit(thermalEntity)
        end
    end

    -- Never target our own helicopter or the people inside it.
    if entity then
        local isOwn = entity == Heli.entity
            or (IsEntityAPed(entity)
                and IsPedInAnyVehicle(entity, false)
                and GetVehiclePedIsIn(entity, false) == Heli.entity)

        if isOwn then
            entity, kind = nil, nil
        end
    end

    return entity, kind, distance
end

local function isTagged(ped)
    for _, tag in ipairs(tags) do
        if tag.ped == ped then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Tagging
---------------------------------------------------------------------------

function Heli.TagTarget()
    if not Config.Marking.enabled then return end

    local now = GetGameTimer()

    if now - lastTagTime < (Config.Marking.cooldown or 1.5) * 1000 then
        Notify.Send(_U("tag_cooldown"), "warning")
        return
    end

    -- Prefer the ped that was highlighted a moment ago; otherwise probe now.
    local ped = (hoverCandidate and now - hoverCandidate.t < 400 and hoverCandidate.ped) or nil

    if not ped then
        local entity, kind = aimProbe()
        ped = entity
        if kind ~= "ped" or not entity then
            ped = nil
        end
    end

    if not (ped and DoesEntityExist(ped)) then
        Notify.Send(_U("tag_none"), "error")
        return
    end

    local coords = GetEntityCoords(ped)
    local distance = #(coords - Heli.pos)

    if distance > (Config.Marking.maxRange or 250.0) then
        Notify.Send(_U("tag_out_of_range"), "error")
        return
    end

    -- Tell the server; it will broadcast the tag (and blip) to everyone.
    local isPlayer = IsPedAPlayer(ped)

    if isPlayer then
        local player = playerFromPed(ped)
        local serverId = (player ~= -1 and GetPlayerServerId(player)) or nil

        TriggerServerEvent("oxlyn-helicam:sv:tag", {
            targetType = "player",
            targetServer = serverId,
            coords = { x = coords.x, y = coords.y, z = coords.z },
        })
    elseif Config.Marking.allowNpc then
        TriggerServerEvent("oxlyn-helicam:sv:tag", {
            targetType = "npc",
            coords = { x = coords.x, y = coords.y, z = coords.z },
        })
    else
        Notify.Send(_U("tag_none"), "error")
        return
    end

    -- Track the tag locally so it shows on our HUD: refresh it, or add a new one.
    local duration = (Config.Marking.duration or 12) * 1000
    local found = false

    for _, tag in ipairs(tags) do
        if tag.ped == ped then
            tag.expiry = now + duration
            tag.coords = coords
            found = true
            break
        end
    end

    if not found then
        tagCounter = tagCounter + 1
        tags[#tags + 1] = {
            ped = ped,
            coords = coords,
            isPlayer = isPlayer,
            num = tagCounter,
            expiry = now + duration,
        }
    end

    lastTagTime = now

    Notify.Send(_U("tag_marked"), "success")
    SendNUIMessage({ action = "tag" })
end

---------------------------------------------------------------------------
-- Drawing helpers
---------------------------------------------------------------------------

-- Draws four corner brackets around a box.
local function drawBrackets(cx, cy, w, h, r, g, b, a)
    local thin = 0.0013   -- thickness of vertical arms
    local thick = 0.0023  -- thickness of horizontal arms
    local armW = w * 0.32
    local armH = h * 0.32

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
    SetTextScale(0.26, 0.26)
    SetTextFont(0)
    SetTextColour(r, g, b, a)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Fallback box size (width, height) for a target at a given distance.
local function fallbackBoxSize(distance)
    local scale = clamp(26.0 / math.max(distance, 6.0), 0.3, 1.5)
    return 0.046 * scale, 0.105 * scale
end

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
    local width = math.max((maxX - minX) + padding * 2, 0.02)
    local height = math.max((maxY - minY) + padding * 2, 0.03)
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

---------------------------------------------------------------------------
-- Per-frame aim + tag drawing
---------------------------------------------------------------------------

function Heli.DrawTargets()
    if not Heli.active then
        hoverCandidate = nil
        return
    end

    local now = GetGameTimer()

    if Heli.view ~= "external" then
        -- Refresh what the crosshair is pointing at every 150 ms.
        if now - lastAimTime > 150 then
            lastAimTime = now

            local entity, kind, distance = aimProbe()

            hoverCandidate = (Config.Marking.enabled and kind == "ped") and { ped = entity, t = now } or nil

            Heli.lrfDist = distance
            Heli.aimEnt = entity
            Heli.aimKind = kind
            Heli.aimPed = (kind == "ped" and entity) or nil
            Heli.aimDist = entity and (distance or #(GetEntityCoords(entity) - Heli.pos)) or nil
            Heli.aimAt = now
        end

        if not Config.Marking.enabled then
            hoverCandidate = nil
        end

        -- Outline the ped under the crosshair (if it isn't already tagged).
        if hoverCandidate and hoverCandidate.ped
            and DoesEntityExist(hoverCandidate.ped)
            and not isTagged(hoverCandidate.ped) then

            local distance = #(GetEntityCoords(hoverCandidate.ped) - Heli.pos)
            local cx, cy, w, h = getScreenBox(hoverCandidate.ped)

            if cx then
                drawBrackets(cx, cy, w, h, 225, 225, 220, 140)
                drawLabel(("%s · %dm"):format(_U("ui_contact"), math.floor(distance)),
                    cx, cy + h / 2 + 0.006, 225, 225, 220, 190)
            end
        end
    else
        hoverCandidate = nil
    end

    if #tags == 0 then
        Heli.spottedCount = 0
        return
    end

    -- Draw active tags, dropping expired ones.
    local alive = {}
    local pulse = 165 + math.floor(70 * math.abs(math.sin(now / 240.0)))

    for _, tag in ipairs(tags) do
        if now < tag.expiry then
            local coords
            if tag.ped and DoesEntityExist(tag.ped) then
                coords = GetEntityCoords(tag.ped) + vector3(0.0, 0.0, 0.15)
                tag.coords = coords
            else
                coords = tag.coords
            end

            local distance = #(coords - (Heli.pos or coords))

            local sx, sy, w, h = nil, nil, nil, nil
            if tag.ped and DoesEntityExist(tag.ped) then
                sx, sy, w, h = getScreenBox(tag.ped)
            end

            -- No usable box: fall back to a size based on distance.
            if not sx then
                local onScreen, px, py = World3dToScreen2d(coords.x, coords.y, coords.z + 0.75)
                if onScreen then
                    w, h = fallbackBoxSize(distance)
                    sx, sy = px, py
                end
            end

            if sx then
                drawBrackets(sx, sy, w, h, 225, 225, 225, pulse)
                DrawRect(sx, sy, 0.0018, 0.0032, 225, 225, 225, pulse)

                local remaining = math.max(0, math.ceil((tag.expiry - now) / 1000))
                local label = ("%s %02d · %dm · %ds"):format(
                    _U("ui_trk"), tag.num or 0, math.floor(distance), remaining)

                drawLabel(label, sx, sy - h / 2 - 0.022, 225, 225, 225, 235)
            end

            alive[#alive + 1] = tag
        end
    end

    tags = alive
    Heli.spottedCount = #tags
end

function Heli.ClearTags()
    tags = {}
    hoverCandidate = nil
    tagCounter = 0
end

---------------------------------------------------------------------------
-- Blips for tags (broadcast by the server)
---------------------------------------------------------------------------

RegisterNetEvent("oxlyn-helicam:client:addTag", function(data)
    if type(data) ~= "table" then return end

    local blipCfg = Config.Marking.blip or {}
    local duration = (data.duration or Config.Marking.duration or 12) * 1000

    -- One blip per tagged player, or per rough NPC location.
    local key = (data.targetType == "player" and ("p:" .. tostring(data.targetServer)))
        or ("n:" .. ("%.0f_%.0f"):format(data.x or 0, data.y or 0))

    blipTokens[key] = (blipTokens[key] or 0) + 1
    local token = blipTokens[key]

    -- Replace any existing blip for this key.
    if blips[key] and DoesBlipExist(blips[key]) then
        RemoveBlip(blips[key])
    end
    blips[key] = nil

    local blip = nil

    -- Players get a blip attached to their ped when it's streamed in.
    if data.targetType == "player" and data.targetServer then
        local player = GetPlayerFromServerId(data.targetServer)
        if player ~= -1 and NetworkIsPlayerActive(player) then
            local ped = GetPlayerPed(player)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                blip = AddBlipForEntity(ped)
            end
        end
    end

    -- Otherwise, a blip at the tagged coordinates.
    if not blip then
        blip = AddBlipForCoord(data.x or 0.0, data.y or 0.0, data.z or 0.0)
    end

    if not blip or blip == 0 then return end

    SetBlipSprite(blip, blipCfg.sprite or 1)
    SetBlipColour(blip, blipCfg.color or 1)
    SetBlipScale(blip, blipCfg.scale or 0.9)
    SetBlipAsShortRange(blip, blipCfg.shortRange == true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Lang(blipCfg.label or "locale:blip_tagged"))
    EndTextCommandSetBlipName(blip)

    if blipCfg.flashOnTag then
        SetBlipFlashes(blip, true)
        SetTimeout(3000, function()
            if DoesBlipExist(blip) then
                SetBlipFlashes(blip, false)
            end
        end)
    end

    blips[key] = blip

    -- Remove the blip after the tag duration, unless a newer tag replaced it.
    SetTimeout(duration, function()
        if blipTokens[key] == token and blips[key] and DoesBlipExist(blips[key]) then
            RemoveBlip(blips[key])
            blips[key] = nil
        end
    end)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, blip in pairs(blips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end)