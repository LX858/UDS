local utils = {}

local accentR, accentG, accentB = 0, 255, 255

function utils.setAccentColor(r, g, b)
    accentR = r
    accentG = g
    accentB = b
end

local GetWorldCoordFromScreenCoord = GetWorldCoordFromScreenCoord
local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetShapeTestResultIncludingMaterial = GetShapeTestResultIncludingMaterial
local GetNuiCursorPosition = GetNuiCursorPosition
local GetActiveScreenResolution = GetActiveScreenResolution

---@param flag number
---@return boolean hit
---@return number entityHit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return number materialHash
function utils.raycastFromCamera(flag)
    local coords, normal = GetWorldCoordFromScreenCoord(0.5, 0.5)
    local destination = coords + normal * 10
    local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z,
        flag, cache.ped, 4)

    while true do
        local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(
        handle)

        if retval ~= 1 then
            ---@diagnostic disable-next-line: return-type-mismatch
            return hit, entityHit, endCoords, surfaceNormal, materialHash
        end
        Wait(0)
    end
end

---@param flag number
---@param distance number
---@return boolean hit
---@return number entityHit
---@return vector3 endCoords
function utils.raycastFromCursor(flag, distance)
    local cursorX, cursorY = GetNuiCursorPosition()
    local screenW, screenH = GetActiveScreenResolution()
    local screenX = cursorX / screenW
    local screenY = cursorY / screenH

    local coords, normal = GetWorldCoordFromScreenCoord(screenX, screenY)
    local destination = coords + normal * (distance or 10)
    local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z,
        flag, cache.ped, 4)

    while true do
        local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(handle)

        if retval ~= 1 then
            return hit == 1, entityHit, endCoords
        end
        Wait(0)
    end
end

---Raycast from cursor that includes the player's own ped (doesn't ignore it)
---@param distance number? Max raycast distance (default 10)
---@return boolean hit
---@return number entityHit
---@return vector3 endCoords
function utils.raycastFromCursorIncludeSelf(distance)
    local cursorX, cursorY = GetNuiCursorPosition()
    local screenW, screenH = GetActiveScreenResolution()
    local screenX = cursorX / screenW
    local screenY = cursorY / screenH

    local coords, normal = GetWorldCoordFromScreenCoord(screenX, screenY)
    local destination = coords + normal * (distance or 10)

    local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z,
        30, 0, 4)

    while true do
        local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(handle)

        if retval ~= 1 then
            return hit == 1, entityHit, endCoords
        end
        Wait(0)
    end
end

function utils.getTexture()
    return lib.requestStreamedTextureDict('shared'), 'emptydot_32'
end

-- SetDrawOrigin is limited to 32 calls per frame. Set as 0 to disable.
local drawZoneSprites = GetConvarInt('ox_target:drawSprite', 24)
local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin
local colour = vector(155, 155, 155, 175)
local hover = vector(98, 135, 236, 255)
local currentZones = {}
local previousZones = {}
local drawZones = {}
local drawN = 0
local width = 0.02
local height = width * GetAspectRatio(false)

if drawZoneSprites == 0 then drawZoneSprites = -1 end

---@param coords vector3
---@return CZone[], boolean
function utils.getNearbyZones(coords)
    if not Zones then return currentZones, false end

    local n = 0
    local nearbyZones = lib.zones.getNearbyZones()
    drawN = 0
    previousZones, currentZones = currentZones, table.wipe(previousZones)

    for i = 1, #nearbyZones do
        local zone = nearbyZones[i]
        local contains = zone:contains(coords)

        if contains then
            n += 1
            currentZones[n] = zone
        end

        if drawN <= drawZoneSprites and zone.drawSprite ~= false and (contains or (zone.distance or 7) < 7) then
            drawN += 1
            drawZones[drawN] = zone
            zone.colour = contains and hover or nil
        end
    end

    local previousN = #previousZones

    if n ~= previousN then
        return currentZones, true
    end

    if n > 0 then
        for i = 1, n do
            local zoneA = currentZones[i]
            local found = false

            for j = 1, previousN do
                local zoneB = previousZones[j]

                if zoneA == zoneB then
                    found = true
                    break
                end
            end

            if not found then
                return currentZones, true
            end
        end
    end

    return currentZones, false
end

local zoneParticleMap = {}
local aspectRatio = GetAspectRatio(false)
local ZONE_SPAWN_RATE = 1
local ZONE_PARTICLE_BASE_SIZE = 0.0045
local ZONE_PARTICLE_MAX_PER_ZONE = 10
local math_random = math.random
local math_cos = math.cos
local math_sin = math.sin
local math_floor = math.floor
local TWO_PI = 6.2831853

function utils.drawZoneSprites(dict, texture, suppressSpawn)
    if drawN == 0 and not next(zoneParticleMap) then return end

    -- Spawn new particles for visible zones
    if not suppressSpawn then
        for i = 1, drawN do
            local zone = drawZones[i]
            if zone.drawSprite ~= false then
                if not zoneParticleMap[zone] then
                    zoneParticleMap[zone] = {}
                end
                local pts = zoneParticleMap[zone]
                if #pts < ZONE_PARTICLE_MAX_PER_ZONE then
                    for _ = 1, ZONE_SPAWN_RATE do
                        local angle = math_random() * TWO_PI
                        local speed = 0.000067 + math_random() * 0.000133
                        pts[#pts + 1] = {
                            x = 0.0, y = 0.0,
                            vx = math_cos(angle) * speed,
                            vy = math_sin(angle) * speed,
                            alpha = 160 + math_random(80),
                            sz = ZONE_PARTICLE_BASE_SIZE * (0.5 + math_random() * 0.8),
                            life = 198 + math_random(108),
                        }
                    end
                end
            end
        end
    end

    -- Update and draw all zone particles
    for zone, pts in pairs(zoneParticleMap) do
        SetDrawOrigin(zone.coords.x, zone.coords.y, zone.coords.z)
        local j = 0
        for i = 1, #pts do
            local p = pts[i]
            p.x = p.x + p.vx
            p.y = p.y + p.vy
            p.life = p.life - 1
            p.alpha = p.alpha * 0.977

            if p.life > 0 and p.alpha > 3 then
                j = j + 1
                pts[j] = p
                DrawSprite(dict, texture, p.x, p.y, p.sz, p.sz * aspectRatio, 0, accentR, accentG, accentB, math_floor(p.alpha))
            end
        end

        for i = j + 1, #pts do
            pts[i] = nil
        end

        if j == 0 then
            zoneParticleMap[zone] = nil
        end
    end

    ClearDrawOrigin()
end

local drawZoneOutlineEnabled = GetConvarInt('ox_target:drawZoneOutline', 1) == 1
local DrawLine = DrawLine
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi

local glowPasses = {
    { dz = 0.0,   alpha = 240 },
    { dz = 0.015, alpha = 90 },
}

local function drawGlowLine(x1, y1, z1, x2, y2, z2, r, g, b)
    for p = 1, #glowPasses do
        local pass = glowPasses[p]
        local dz = pass.dz
        DrawLine(x1, y1, z1 + dz, x2, y2, z2 + dz, r, g, b, pass.alpha)
    end
end

local DoesEntityExist = DoesEntityExist
local GetEntityModel = GetEntityModel
local GetModelDimensions = GetModelDimensions
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords

function utils.drawEntityGlow(entity)
    if not entity or entity <= 0 or not DoesEntityExist(entity) then return end

    local success, model = pcall(GetEntityModel, entity)
    if not success or not model or model == 0 then return end

    local ok, min, max = pcall(GetModelDimensions, model)
    if not ok or not min or not max then return end

    local r, g, b = accentR, accentG, accentB

    local c1x, c1y, c1z = GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, min.z)
    if not c1z then return end
    local c2x, c2y, c2z = GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, min.z)
    local c3x, c3y, c3z = GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, min.z)
    local c4x, c4y, c4z = GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, min.z)
    local c5x, c5y, c5z = GetOffsetFromEntityInWorldCoords(entity, min.x, min.y, max.z)
    local c6x, c6y, c6z = GetOffsetFromEntityInWorldCoords(entity, max.x, min.y, max.z)
    local c7x, c7y, c7z = GetOffsetFromEntityInWorldCoords(entity, max.x, max.y, max.z)
    local c8x, c8y, c8z = GetOffsetFromEntityInWorldCoords(entity, min.x, max.y, max.z)

    -- Bottom face
    drawGlowLine(c1x, c1y, c1z, c2x, c2y, c2z, r, g, b)
    drawGlowLine(c2x, c2y, c2z, c3x, c3y, c3z, r, g, b)
    drawGlowLine(c3x, c3y, c3z, c4x, c4y, c4z, r, g, b)
    drawGlowLine(c4x, c4y, c4z, c1x, c1y, c1z, r, g, b)
    -- Top face
    drawGlowLine(c5x, c5y, c5z, c6x, c6y, c6z, r, g, b)
    drawGlowLine(c6x, c6y, c6z, c7x, c7y, c7z, r, g, b)
    drawGlowLine(c7x, c7y, c7z, c8x, c8y, c8z, r, g, b)
    drawGlowLine(c8x, c8y, c8z, c5x, c5y, c5z, r, g, b)
    -- Verticals
    drawGlowLine(c1x, c1y, c1z, c5x, c5y, c5z, r, g, b)
    drawGlowLine(c2x, c2y, c2z, c6x, c6y, c6z, r, g, b)
    drawGlowLine(c3x, c3y, c3z, c7x, c7y, c7z, r, g, b)
    drawGlowLine(c4x, c4y, c4z, c8x, c8y, c8z, r, g, b)
end

function utils.drawZoneOutlines(zones)
    if not drawZoneOutlineEnabled or #zones == 0 then return end

    local r, g, b = accentR, accentG, accentB

    for i = 1, #zones do
        local zone = zones[i]

        if zone.__type == 'sphere' then
            local segments = 24
            local cx, cy, cz = zone.coords.x, zone.coords.y, zone.coords.z
            local radius = zone.radius
            local step = (2 * math_pi) / segments

            for s = 0, segments - 1 do
                local a1 = s * step
                local a2 = (s + 1) * step
                drawGlowLine(
                    cx + radius * math_cos(a1), cy + radius * math_sin(a1), cz,
                    cx + radius * math_cos(a2), cy + radius * math_sin(a2), cz,
                    r, g, b
                )
            end
        elseif zone.polygon then
            local n = #zone.polygon
            local halfThick = vec3(0, 0, zone.thickness / 2)

            for v = 1, n do
                local p1 = zone.polygon[v]
                local p2 = zone.polygon[v + 1] or zone.polygon[1]
                local t1 = p1 + halfThick
                local b1 = p1 - halfThick
                local t2 = p2 + halfThick
                local b2 = p2 - halfThick

                drawGlowLine(t1.x, t1.y, t1.z, t2.x, t2.y, t2.z, r, g, b)
                drawGlowLine(b1.x, b1.y, b1.z, b2.x, b2.y, b2.z, r, g, b)
                drawGlowLine(t1.x, t1.y, t1.z, b1.x, b1.y, b1.z, r, g, b)
            end
        end
    end
end

function utils.hasExport(export)
    local resource, exportName = string.strsplit('.', export)

    return pcall(function()
        return exports[resource][exportName]
    end)
end

local playerItems = {}

function utils.getItems()
    return playerItems
end

---@param filter string | string[] | table<string, number>
---@param hasAny boolean?
---@return boolean
function utils.hasPlayerGotItems(filter, hasAny)
    if not playerItems then return true end

    local _type = type(filter)

    if _type == 'string' then
        return (playerItems[filter] or 0) > 0
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            for name, amount in pairs(filter) do
                local hasItem = (playerItems[name] or 0) >= amount

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local hasItem = (playerItems[filter[i]] or 0) > 0

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        end
    end

    return not hasAny
end

---stub
---@param filter string | string[] | table<string, number>
---@return boolean
function utils.hasPlayerGotGroup(filter)
    return true
end

SetTimeout(0, function()
    if utils.hasExport('ox_inventory.Items') then
        setmetatable(playerItems, {
            __index = function(self, index)
                self[index] = exports.ox_inventory:Search('count', index) or 0
                return self[index]
            end
        })

        AddEventHandler('ox_inventory:itemCount', function(name, count)
            playerItems[name] = count
        end)
    end

    if utils.hasExport('ox_core.GetPlayer') then
        require 'client.framework.ox'
    elseif utils.hasExport('es_extended.getSharedObject') then
        require 'client.framework.esx'
    elseif utils.hasExport('qb-core.GetCoreObject') then
        require 'client.framework.qb'
    elseif utils.hasExport('qbx_core.HasGroup') then
        require 'client.framework.qbx'
    elseif utils.hasExport('ND_Core.getPlayer') then
        require 'client.framework.nd'
    end
end)

function utils.warn(msg)
    local trace = Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())
    local _, _, src = string.strsplit('\n', trace, 4)

    warn(('%s ^0%s\n'):format(msg, src:gsub(".-%(", '(')))
end

return utils
