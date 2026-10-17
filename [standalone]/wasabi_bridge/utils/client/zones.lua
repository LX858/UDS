-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Initialize WSB.zones namespace
WSB.zones = {}

-- Storage for all zones
local allZones = {}

-- Storage for zones player is currently inside
local activeZones = {}

-- Queue for zones being entered (processed in order)
local enterQueue = {}

-- Queue for zones being exited (processed in order)
local exitQueue = {}

-- Check if a point is inside a polygon using ray casting algorithm
-- @param polygon table - Array of vector3 points defining the polygon
-- @param point vector3 - Point to test
-- @return boolean - True if point is inside polygon
local function isPointInPolygon(polygon, point)
    local inside = false
    local numPoints = #polygon
    
    local j = numPoints
    for i = 1, #polygon, 1 do
        local xi = polygon[i].x
        local yi = polygon[i].y
        local xj = polygon[j].x
        local yj = polygon[j].y
        
        if (yi > point.y) ~= (yj > point.y) then
            if point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi then
                inside = not inside
            end
        end
        
        j = i
    end
    
    return inside
end

-- Calculate the center (centroid) of a polygon
-- @param polygon table - Array of vector3 points
-- @return vector3 - Center point of the polygon
local function calculatePolygonCenter(polygon)
    local sumX = 0
    local sumY = 0
    local sumZ = 0
    
    for i = 1, #polygon, 1 do
        sumX = sumX + polygon[i].x
        sumY = sumY + polygon[i].y
        sumZ = sumZ + polygon[i].z
    end
    
    local count = #polygon
    return vector3(sumX / count, sumY / count, sumZ / count)
end

-- Check if a polygon is convex
-- @param polygon table - Array of vector3 points
-- @return boolean - True if polygon is convex
local function isPolygonConvex(polygon)
    local numPoints = #polygon
    
    if numPoints < 4 then
        return true
    end
    
    local sign = nil
    
    for i = 1, numPoints, 1 do
        local p0 = i
        local p1 = (i % numPoints) + 1
        local p2 = ((i + 1) % numPoints) + 1
        
        local dx1 = polygon[p1].x - polygon[p0].x
        local dy1 = polygon[p1].y - polygon[p0].y
        local dx2 = polygon[p2].x - polygon[p1].x
        local dy2 = polygon[p2].y - polygon[p1].y
        
        local crossProduct = dx1 * dy2 - dy1 * dx2
        local currentSign = crossProduct >= 0
        
        if sign == nil then
            sign = currentSign
        elseif sign ~= currentSign then
            return false
        end
    end
    
    return true
end

-- Check if a point is inside a triangle
-- @param p vector3 - Point to test
-- @param a vector3 - Triangle vertex A
-- @param b vector3 - Triangle vertex B
-- @param c vector3 - Triangle vertex C
-- @return boolean - True if point is inside triangle
local function isPointInTriangle(p, a, b, c)
    local function sign(p1, p2, p3)
        return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
    end
    
    local d1 = sign(p, a, b)
    local d2 = sign(p, b, c)
    local d3 = sign(p, c, a)
    
    local hasNeg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    local hasPos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    
    return not (hasNeg and hasPos)
end

-- Check if an ear can be clipped from a polygon
-- @param polygon table - Array of vector3 points
-- @param index number - Index of potential ear vertex
-- @return boolean - True if ear can be clipped
local function canClipEar(polygon, index)
    local numPoints = #polygon
    
    -- Get previous, current, and next vertices
    local prevIndex = (index == 1 and numPoints) or (index - 1)
    local prev = polygon[prevIndex]
    local curr = polygon[index]
    local nextIndex = (index == numPoints and 1) or (index + 1)
    local next = polygon[nextIndex]
    
    -- Calculate cross product to check if ear is convex
    local dx1 = curr.x - prev.x
    local dy1 = curr.y - prev.y
    local dx2 = next.x - curr.x
    local dy2 = next.y - curr.y
    
    local crossProduct = dx1 * dy2 - dy1 * dx2
    
    if crossProduct < 0 then
        return false
    end
    
    -- Check if any other polygon vertex is inside the ear triangle
    for i, vertex in ipairs(polygon) do
        local iPrev = (index == 1 and numPoints) or (index - 1)
        
        if i ~= iPrev and i ~= index then
            local iNext = (index == numPoints and 1) or (index + 1)
            
            if i ~= iNext then
                if isPointInTriangle(vertex, prev, curr, next) then
                    return false
                end
            end
        end
    end
    
    return true
end

-- Triangulate a polygon using ear clipping method
-- @param polygon table - Array of vector3 points
-- @return table - Array of triangles (each triangle is an array of 3 vertices)
local function triangulatePolygon(polygon)
    local triangles = {}
    local numPoints = #polygon
    
    if numPoints < 3 then
        return triangles
    end
    
    -- If convex, use simple fan triangulation
    if isPolygonConvex(polygon) then
        for i = 2, numPoints - 1, 1 do
            table.insert(triangles, {
                polygon[1],
                polygon[i],
                polygon[i + 1]
            })
        end
        return triangles
    end
    
    -- Ear clipping for concave polygons
    local remaining = {}
    for i = 1, #polygon, 1 do
        remaining[i] = polygon[i]
    end
    
    while #remaining > 3 do
        local clipped = false
        
        for i = 1, #remaining, 1 do
            if canClipEar(remaining, i) then
                -- Get triangle vertices
                local prevIndex = (i == 1 and #remaining) or (i - 1)
                local prev = remaining[prevIndex]
                local curr = remaining[i]
                local nextIndex = (i == #remaining and 1) or (i + 1)
                local next = remaining[nextIndex]
                
                -- Add triangle
                table.insert(triangles, {prev, curr, next})
                
                -- Remove ear vertex
                table.remove(remaining, i)
                clipped = true
                break
            end
        end
        
        if not clipped then
            print("Unable to triangulate polygon for debug drawing.")
            break
        end
    end
    
    -- Add final triangle
    if #remaining == 3 then
        table.insert(triangles, {
            remaining[1],
            remaining[2],
            remaining[3]
        })
    end
    
    return triangles
end

-- Normalize coordinates to vector3
-- @param coords vector3|table - Coordinates in various formats
-- @return vector3 - Normalized vector3
local function normalizeCoords(coords)
    if type(coords) == "vector3" then
        return coords
    elseif type(coords) == "table" then
        return vector3(
            coords.x or coords[1],
            coords.y or coords[2],
            coords.z or coords[3]
        )
    else
        error("Invalid coordinate type, expected vector3 or table.")
    end
end

-- Remove a zone from the system
-- @param zone table - Zone object to remove
local function removeZone(zone)
    -- Remove from all zones
    allZones[zone.id] = nil
    
    -- Remove from active zones
    activeZones[zone.id] = nil
    
    -- Remove from enter queue
    for index, queuedZone in ipairs(enterQueue) do
        if queuedZone.id == zone.id then
            table.remove(enterQueue, index)
            break
        end
    end
    
    -- Remove from exit queue
    for index, queuedZone in ipairs(exitQueue) do
        if queuedZone.id == zone.id then
            table.remove(exitQueue, index)
            break
        end
    end
end

-- Draw debug visualization for a polygon/box zone
-- @param zone table - Zone object with polygon and debug color
local function drawPolygonDebug(zone)
    if not zone.triangles then
        return
    end
    
    -- Draw filled triangles
    for index, triangle in ipairs(zone.triangles) do
        DrawPoly(
            triangle[1].x, triangle[1].y, triangle[1].z,
            triangle[2].x, triangle[2].y, triangle[2].z,
            triangle[3].x, triangle[3].y, triangle[3].z,
            zone.debugColour.r,
            zone.debugColour.g,
            zone.debugColour.b,
            zone.debugColour.a
        )
    end
    
    -- Draw outline
    for i = 1, #zone.polygon, 1 do
        local p1 = zone.polygon[i]
        local nextIndex = (i % #zone.polygon) + 1
        local p2 = zone.polygon[nextIndex]
        
        DrawLine(
            p1.x, p1.y, p1.z,
            p2.x, p2.y, p2.z,
            zone.debugColour.r,
            zone.debugColour.g,
            zone.debugColour.b,
            255
        )
    end
end

-- Draw debug visualization for a sphere zone
-- @param zone table - Zone object with coords, radius, and debug color
local function drawSphereDebug(zone)
    DrawMarker(
        28,  -- Sphere marker type
        zone.coords.x,
        zone.coords.y,
        zone.coords.z,
        0, 0, 0,  -- Direction
        0, 0, 0,  -- Rotation
        zone.radius,
        zone.radius,
        zone.radius,
        zone.debugColour.r,
        zone.debugColour.g,
        zone.debugColour.b,
        zone.debugColour.a,
        false, false, 2, false, nil, nil, false
    )
end

-- Check if a point is inside a polygon zone (2D with Z bounds)
-- @param zone table - Zone object with polygon
-- @param point vector3 - Point to test
-- @return boolean - True if point is inside
local function isPointInPolygonZone(zone, point)
    point = normalizeCoords(point)
    return isPointInPolygon(zone.polygon, point)
end

-- Check if a point is inside a sphere zone
-- @param zone table - Zone object with coords and radius
-- @param point vector3 - Point to test
-- @return boolean - True if point is inside
local function isPointInSphereZone(zone, point)
    point = normalizeCoords(point)
    local distance = #(zone.coords - point)
    return distance < zone.radius
end

-- Set debug visualization for a zone
-- @param zone table - Zone object
-- @param enabled boolean - Enable/disable debug drawing
-- @param color table|nil - Optional color {r, g, b, a}
local function setZoneDebug(zone, enabled, color)
    if not enabled then
        zone.debugColour = nil
        zone.triangles = nil
        zone.debug = nil
        activeZones[zone.id] = nil
        return
    end
    
    -- Set debug color (default: orange)
    local debugColor = {
        r = (color and color.r) or 255,
        g = (color and color.g) or 42,
        b = (color and color.b) or 24,
        a = (color and color.a) or 100
    }
    
    zone.debugColour = debugColor
    
    -- Set appropriate debug function
    if zone.type == "sphere" then
        zone.debug = drawSphereDebug
    elseif zone.type == "box" or zone.type == "poly" then
        zone.triangles = triangulatePolygon(zone.polygon)
        zone.debug = drawPolygonDebug
    end
end

-- Main zone update thread
CreateThread(function()
    while true do
        local waitTime = 300
        local playerCoords = GetEntityCoords(WSB.cache.ped)
        
        -- Update all zones
        for zoneId, zone in pairs(allZones) do
            -- Calculate distance to zone center
            local distance = #(zone.coords - playerCoords)
            zone.distance = distance
            
            -- Check if player is inside zone
            if zone:contains(playerCoords) then
                -- Player entered zone
                if not zone.insideZone then
                    zone.insideZone = true
                    
                    -- Queue onEnter callback
                    if zone.onEnter then
                        table.insert(enterQueue, zone)
                    end
                    
                    -- Add to active zones for inside callback
                    if zone.inside then
                        activeZones[zone.id] = zone
                    end
                end
            else
                -- Player exited zone
                if zone.insideZone then
                    zone.insideZone = false
                    
                    -- Remove from active zones
                    activeZones[zone.id] = nil
                    
                    -- Queue onExit callback
                    if zone.onExit then
                        table.insert(exitQueue, zone)
                    end
                end
            end
            
            -- Handle debug drawing
            if zone.debug then
                if type(zone.debug) == "function" then
                    waitTime = 0  -- Run every frame for drawing
                    zone:debug()
                else
                    zone:setDebug(true, zone.debugColour)
                end
            end
        end
        
        -- Process enter queue (sorted by distance, closest first)
        if #enterQueue > 0 then
            table.sort(enterQueue, function(a, b)
                return a.distance < b.distance
            end)
            
            for index, zone in ipairs(enterQueue) do
                if zone.onEnter then
                    zone:onEnter()
                end
            end
            
            enterQueue = {}
        end
        
        -- Process exit queue (sorted by distance, farthest first)
        if #exitQueue > 0 then
            table.sort(exitQueue, function(a, b)
                return a.distance > b.distance
            end)
            
            for index, zone in ipairs(exitQueue) do
                if zone.onExit then
                    zone:onExit()
                end
            end
            
            exitQueue = {}
        end
        
        -- Call inside callback for active zones
        for zoneId, zone in pairs(activeZones) do
            if zone.inside then
                zone:inside()
            end
        end
        
        Wait(waitTime)
    end
end)

-- Create a polygon zone
-- @param zoneData table - Zone configuration {points, thickness, onEnter, onExit, inside}
-- @return table - Zone object
function WSB.zones.poly(zoneData)
    -- Generate unique ID
    zoneData.id = #allZones + 1
    
    -- Set default thickness
    zoneData.thickness = zoneData.thickness or 4
    
    -- Normalize all points to vector3
    local polygon = {}
    for index, point in ipairs(zoneData.points) do
        table.insert(polygon, normalizeCoords(point))
    end
    
    zoneData.polygon = polygon
    zoneData.coords = calculatePolygonCenter(zoneData.polygon)
    zoneData.type = "poly"
    
    -- Add methods
    zoneData.remove = function(self)
        removeZone(self)
    end
    
    zoneData.contains = function(self, point)
        return isPointInPolygonZone(self, point)
    end
    
    zoneData.setDebug = function(self, enabled, color)
        setZoneDebug(self, enabled, color)
    end
    
    -- Register zone
    allZones[zoneData.id] = zoneData
    
    return zoneData
end

-- Create a box zone (rotated rectangle)
-- @param zoneData table - Zone configuration {coords, size, rotation, onEnter, onExit, inside}
-- @return table - Zone object
function WSB.zones.box(zoneData)
    -- Generate unique ID
    zoneData.id = #allZones + 1
    
    -- Normalize coordinates
    zoneData.coords = normalizeCoords(zoneData.coords)
    
    -- Set default size
    local size = normalizeCoords(zoneData.size) or vector3(2, 2, 2)
    local halfWidth = size.x / 2
    local halfLength = size.y / 2
    
    -- Set default rotation
    zoneData.rotation = zoneData.rotation or 0
    local rotationRad = math.rad(zoneData.rotation)
    
    -- Create box corners (before rotation)
    local corners = {
        vector3(halfWidth, halfLength, 0),
        vector3(-halfWidth, halfLength, 0),
        vector3(-halfWidth, -halfLength, 0),
        vector3(halfWidth, -halfLength, 0)
    }
    
    -- Apply rotation and translation to create polygon
    local polygon = {}
    for index, corner in ipairs(corners) do
        local rotatedX = corner.x * math.cos(rotationRad) - corner.y * math.sin(rotationRad)
        local rotatedY = corner.x * math.sin(rotationRad) + corner.y * math.cos(rotationRad)
        
        table.insert(polygon, vector3(
            rotatedX + zoneData.coords.x,
            rotatedY + zoneData.coords.y,
            zoneData.coords.z
        ))
    end
    
    zoneData.polygon = polygon
    zoneData.type = "box"
    
    -- Add methods
    zoneData.remove = function(self)
        removeZone(self)
    end
    
    zoneData.contains = function(self, point)
        return isPointInPolygonZone(self, point)
    end
    
    zoneData.setDebug = function(self, enabled, color)
        setZoneDebug(self, enabled, color)
    end
    
    -- Register zone
    allZones[zoneData.id] = zoneData
    
    return zoneData
end

-- Create a sphere zone
-- @param zoneData table - Zone configuration {coords, radius, onEnter, onExit, inside}
-- @return table - Zone object
function WSB.zones.sphere(zoneData)
    -- Generate unique ID
    zoneData.id = #allZones + 1
    
    -- Normalize coordinates
    zoneData.coords = normalizeCoords(zoneData.coords)
    
    -- Set default radius
    zoneData.radius = zoneData.radius or 2
    zoneData.type = "sphere"
    
    -- Add methods
    zoneData.remove = function(self)
        removeZone(self)
    end
    
    zoneData.contains = function(self, point)
        return isPointInSphereZone(self, point)
    end
    
    zoneData.setDebug = function(self, enabled, color)
        setZoneDebug(self, enabled, color)
    end
    
    -- Register zone
    allZones[zoneData.id] = zoneData
    
    return zoneData
end

-- Get all zones
-- @return table - Table of all registered zones
function WSB.zones.getAllZones()
    return allZones
end

-- Get zones player is currently inside
-- @return table - Table of active zones
function WSB.zones.getCurrentZones()
    return activeZones
end