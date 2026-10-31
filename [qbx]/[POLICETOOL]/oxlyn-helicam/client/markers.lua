-- Cleaned-up version of the decompiled helicopter camera map-marker script.
-- Logic is unchanged; names and structure were reconstructed from the decompiler output.
-- Extends the global `Heli` table shared with the other camera files.

Heli = Heli or {}

-- All active markers, grouped by the server id of the player who placed them:
-- markers[serverId] = { { n = number, pos = vector3, t = timestamp }, ... }
local markers = {}

local function myServerId()
    return GetPlayerServerId(PlayerId())
end

local function markerConfig()
    return Config.Markers or {}
end

---------------------------------------------------------------------------
-- Drawing helpers
---------------------------------------------------------------------------

-- Pre-computed sine / cosine tables (one entry per degree).
local sinTable, cosTable = {}, {}
for degree = 0, 360 do
    local radians = math.rad(degree)
    sinTable[degree] = math.sin(radians)
    cosTable[degree] = math.cos(radians)
end

local function fastSin(degrees)
    return sinTable[math.floor(degrees % 360)]
end

local function fastCos(degrees)
    return cosTable[math.floor(degrees % 360)]
end

-- Draws an arc (as a polyline) around `center` at height `z`.
local function drawArc(center, radius, startDeg, endDeg, steps, z, color, alpha)
    local prevX, prevY
    local stepSize = (endDeg - startDeg) / steps

    for i = 0, steps do
        local angle = startDeg + stepSize * i
        local x = center.x + fastCos(angle) * radius
        local y = center.y + fastSin(angle) * radius

        if prevX then
            DrawLine(prevX, prevY, z, x, y, z, color.r, color.g, color.b, alpha)
        end

        prevX, prevY = x, y
    end
end

-- Draws a ring made of `segments` arcs, each covering `fraction` of its slot.
-- With `double`, a second, fainter ring is drawn slightly above the first.
local function drawRing(center, radius, z, rotation, segments, fraction, color, alpha, steps, double)
    local slot = 360.0 / segments

    for i = 0, segments - 1 do
        local startDeg = rotation + i * slot
        local endDeg = startDeg + slot * fraction

        drawArc(center, radius, startDeg, endDeg, steps, z, color, alpha)

        if double then
            drawArc(center, radius + 0.2, startDeg, endDeg, steps, z, color, math.floor(alpha * 0.75))
        end
    end
end

-- Draws a four-armed cross centred on `center`.
local function drawCross(center, size, z, color, alpha)
    local inner = size * 0.16
    local outer = size * 0.4
    local x, y = center.x, center.y

    DrawLine(x + inner, y, z, x + outer, y, z, color.r, color.g, color.b, alpha)
    DrawLine(x - inner, y, z, x - outer, y, z, color.r, color.g, color.b, alpha)
    DrawLine(x, y + inner, z, x, y + outer, z, color.r, color.g, color.b, alpha)
    DrawLine(x, y - inner, z, x, y - outer, z, color.r, color.g, color.b, alpha)
end

-- Heights (as fractions of the beam) at which cross-ticks are drawn.
local BEAM_TICKS = { 0.34, 0.67 }

-- Draws the vertical beam above a marker, fading toward the top.
-- With `detailed`, it also gets cross-ticks and a diamond cap.
local function drawBeam(pos, height, size, color, alpha, detailed)
    local bottom = pos.z + 0.05
    local top = pos.z + height
    local segments = detailed and 8 or 3
    local span = top - bottom
    local x, y = pos.x, pos.y

    for i = 0, segments - 1 do
        local z0 = bottom + span * (i / segments)
        local z1 = bottom + span * ((i + 1) / segments)
        local segmentAlpha = math.floor(alpha * (1.0 - (i / segments) * 0.55))
        DrawLine(x, y, z0, x, y, z1, color.r, color.g, color.b, segmentAlpha)
    end

    if not detailed then return end

    for i = 1, 2 do
        local fraction = BEAM_TICKS[i]
        local z = bottom + span * fraction
        local half = size * 0.09 * (1.0 - fraction * 0.4)
        local tickAlpha = math.floor(alpha * 0.8)

        DrawLine(x - half, y, z, x + half, y, z, color.r, color.g, color.b, tickAlpha)
        DrawLine(x, y - half, z, x, y + half, z, color.r, color.g, color.b, tickAlpha)
    end

    -- Diamond cap at the top.
    local d = size * 0.11
    DrawLine(x + d, y, top, x, y + d, top, color.r, color.g, color.b, alpha)
    DrawLine(x, y + d, top, x - d, y, top, color.r, color.g, color.b, alpha)
    DrawLine(x - d, y, top, x, y - d, top, color.r, color.g, color.b, alpha)
    DrawLine(x, y - d, top, x + d, y, top, color.r, color.g, color.b, alpha)
end

local aspectRatio = 1.7777
local lastAspectCheck = 0

-- Draws the numbered badge (and optional distance text) at a screen position.
local function drawMarkerLabel(number, text, sx, sy, color, alpha, scale)
    -- Refresh the aspect ratio once a second.
    local now = GetGameTimer()
    if now - lastAspectCheck > 1000 then
        lastAspectCheck = now
        local ratio = GetAspectRatio(false)
        if ratio and ratio > 0.0 then
            aspectRatio = ratio
        end
    end
    local aspect = aspectRatio

    local label = string.format("%02d", number)
    local badgeH = scale * 0.072
    local badgeW = badgeH * (0.95 + 0.34 * (#label - 2)) / aspect
    local badgeCy = sy + badgeH * 0.5

    -- Dark background and coloured accent bar on the left.
    DrawRect(sx, badgeCy, badgeW, badgeH, 8, 11, 13, math.floor(alpha * 0.62))
    DrawRect(sx - badgeW * 0.5 + 0.0022 / aspect, badgeCy, 0.0044 / aspect, badgeH,
        color.r, color.g, color.b, alpha)

    -- Corner ticks.
    local tickW = badgeH * 0.26 / aspect
    local tickH = badgeH * 0.26
    local thin = 0.0016 / aspect
    local thick = 0.0028

    for i = 1, 4 do
        local dx = (i == 1 or i == 3) and -1 or 1
        local dy = (i <= 2) and -1 or 1
        local cx = sx + dx * (badgeW * 0.5)
        local cy = badgeCy + dy * (badgeH * 0.5)

        DrawRect(cx - dx * tickW * 0.5, cy, tickW, thick, color.r, color.g, color.b, alpha)
        DrawRect(cx, cy - dy * tickH * 0.5, thin, tickH, color.r, color.g, color.b, alpha)
    end

    -- The number.
    SetTextFont(4)
    SetTextCentre(true)
    SetTextDropshadow(2, 0, 0, 0, 255)
    SetTextOutline()
    SetTextScale(scale * 0.86, scale * 0.86)
    SetTextColour(245, 248, 250, alpha)
    SetTextEntry("STRING")
    AddTextComponentString(label)
    DrawText(sx, badgeCy - badgeH * 0.62)

    -- Four bars under the badge that shrink and fade.
    local barW = badgeH * 0.62 / aspect
    for i = 0, 3 do
        local f = i / 3
        DrawRect(
            sx,
            badgeCy + badgeH * 0.5 + i * (badgeH * 0.13),
            barW * (1.0 - f),
            badgeH * 0.13,
            color.r, color.g, color.b,
            math.floor(alpha * (1.0 - f * 0.35)))
    end

    -- Optional distance text below the badge.
    if text then
        local textScale = scale * 0.5
        SetTextScale(textScale, textScale)
        SetTextColour(235, 240, 244, math.floor(alpha * 0.72))
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(sx, badgeCy + badgeH * 1.05)
    end
end

---------------------------------------------------------------------------
-- Placing and clearing markers
---------------------------------------------------------------------------

-- Drops a marker where the camera is looking and shares it with other players.
function Heli.DropMarker()
    local cfg = markerConfig()
    if not cfg.enabled then return end

    local origin = Heli.camPos or Heli.pos
    local forward = Heli.lookForward
    if not origin or not forward then return end

    local range = cfg.range or 1000.0
    local target = origin + forward * range

    local probe = _ENV["StartExpensiveSynchronousShapeTestLosProbe"](
        origin.x, origin.y, origin.z,
        target.x, target.y, target.z,
        17, Heli.entity or 0, 4)

    local _, hit, endCoords = GetShapeTestResult(probe)
    if not hit or not endCoords then return end

    Heli._markerN = (Heli._markerN or 0) + 1

    local me = myServerId()
    markers[me] = markers[me] or {}
    markers[me][#markers[me] + 1] = {
        n = Heli._markerN,
        pos = vector3(endCoords.x, endCoords.y, endCoords.z),
        t = GetGameTimer(),
    }

    -- Drop the oldest markers beyond the limit.
    while #markers[me] > (cfg.max or 12) do
        table.remove(markers[me], 1)
    end

    Heli._StartMarkerDraw()

    TriggerServerEvent("oxlyn-helicam:sv:marker", Heli._markerN, endCoords.x, endCoords.y, endCoords.z)

    SendNUIMessage({ action = "osd", text = _U("marker_dropped") .. " " .. Heli._markerN })
end

-- Clears this player's markers (and tells the server so others stop drawing them).
function Heli.ClearMarkers(silent)
    local me = myServerId()
    if not (markers[me] and #markers[me] > 0) then
        return
    end

    Heli._markerN = 0
    markers[me] = nil
    TriggerServerEvent("oxlyn-helicam:sv:markerClear")

    if not silent then
        SendNUIMessage({ action = "osd", text = _U("markers_cleared") })
    end
end

-- Forgets every marker, including other players' (used on reset).
function Heli.WipeSharedMarkers()
    markers = {}
end

---------------------------------------------------------------------------
-- Markers shared by other players
---------------------------------------------------------------------------

RegisterNetEvent("oxlyn-helicam:client:marker", function(owner, n, x, y, z)
    owner = tonumber(owner)
    if not owner or owner == myServerId() then
        return
    end

    markers[owner] = markers[owner] or {}
    markers[owner][#markers[owner] + 1] = {
        n = n,
        pos = vector3(x + 0.0, y + 0.0, z + 0.0),
        t = GetGameTimer(),
    }

    -- Keep at most 24 markers per other player.
    while #markers[owner] > 24 do
        table.remove(markers[owner], 1)
    end

    Heli._StartMarkerDraw()
end)

RegisterNetEvent("oxlyn-helicam:client:markerClear", function(owner)
    owner = tonumber(owner)
    if owner then
        markers[owner] = nil
    end
end)

---------------------------------------------------------------------------
-- Draw loop
---------------------------------------------------------------------------

local drawLoopRunning = false

-- Starts the draw loop if it isn't already running; it stops itself when no markers remain.
function Heli._StartMarkerDraw()
    if drawLoopRunning then return end
    drawLoopRunning = true

    CreateThread(function()
        while true do
            if next(markers) == nil then
                drawLoopRunning = false
                return
            end

            local drewAny = false
            local cfg = markerConfig()
            local color = cfg.color or { r = 235, g = 55, b = 45 }
            local size = cfg.size or 6.0
            local height = cfg.height or 14.0
            local segments = cfg.segments or 6
            local viewDistance = cfg.viewDistance or 600.0
            local rotation = (GetGameTimer() * (cfg.rotateSpeed or 0.018)) % 360.0
            local now = GetGameTimer()

            -- Expire old markers if a lifetime is configured.
            local ttl = (cfg.ttl or 0) * 1000
            if ttl > 0 then
                for owner, list in pairs(markers) do
                    for i = #list, 1, -1 do
                        if now - (list[i].t or 0) > ttl then
                            table.remove(list, i)
                        end
                    end

                    if #list == 0 then
                        markers[owner] = nil
                    end
                end

                if next(markers) == nil then
                    drawLoopRunning = false
                    return
                end
            end

            local camPos = GetFinalRenderedCamCoord()

            -- Never cull markers closer than the drop range.
            local range = cfg.range or 1000.0
            if viewDistance < range then
                viewDistance = range
            end
            local viewDistanceSq = viewDistance * viewDistance

            for _, list in pairs(markers) do
                for i = 1, #list do
                    local marker = list[i]
                    local pos = marker.pos

                    local dx = pos.x - camPos.x
                    local dy = pos.y - camPos.y
                    local dz = pos.z - camPos.z
                    local distSq = dx * dx + dy * dy + dz * dz

                    if viewDistanceSq > distSq then
                        local dist = math.sqrt(distSq)
                        local z = pos.z + 0.06
                        local radius = size * 0.5
                        local near = dist < 220.0
                        local steps = near and 6 or 3

                        -- Ground disc.
                        DrawMarker(25, pos.x, pos.y, z, 0, 0, 0, 0, 0, 0, size, size, size,
                            color.r, color.g, color.b, 40, false, false, 2, false, nil, nil, false)

                        drawRing(pos, radius, z, rotation, segments, 0.62, color, 220, steps, near)

                        if near then
                            drawArc(pos, radius * 0.55, 0, 360, 18, z, color, 90)
                            drawCross(pos, radius, z, color, 235)
                        end

                        drawBeam(pos, height, size, color, 210, near)

                        -- Expanding pulse ring for the first 1.2 seconds.
                        local age = now - (marker.t or 0)
                        if age < 1200 then
                            local progress = age / 1200.0
                            drawArc(pos, radius * (0.5 + progress * 1.9), 0, 360, 20, z, color,
                                math.floor(200 * (1.0 - progress)))
                        end

                        -- Number badge above the beam.
                        local onScreen, sx, sy = World3dToScreen2d(pos.x, pos.y, pos.z + height + 1.8)
                        if onScreen then
                            local scale = math.max(0.42, math.min(0.78, 52.0 / math.max(dist, 20.0)))
                            local distanceText = (cfg.showDistance ~= false) and (math.floor(dist) .. " m") or nil
                            drawMarkerLabel(marker.n, distanceText, sx, sy, color, 245, scale)
                        end

                        drewAny = true
                    end
                end
            end

            -- Idle slowly when nothing was drawn this frame.
            Wait(drewAny and 0 or 500)
        end
    end)
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        markers = {}
    end
end)