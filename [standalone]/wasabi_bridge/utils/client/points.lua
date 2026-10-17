-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Storage for all registered points
local registeredPoints = {}

-- Storage for nearby points (within distance)
local nearbyPoints = {}

-- Counter for nearby points
local nearbyPointCount = 0

-- The currently closest point to the player
local closestPoint = nil

-- Interval ID for the nearby points callback loop
local nearbyPointsInterval = nil

-- Remove a point from the system
-- @param point table - The point object to remove
local function removePoint(point)
    -- Clear closest point if it's being removed
    if closestPoint then
        if closestPoint.id == point.id then
            closestPoint = nil
        end
    end
    
    -- Remove from registered points
    registeredPoints[point.id] = nil
end

-- Convert various coordinate formats to vector3
-- @param coords vector3|table|vector4 - Coordinates in various formats
-- @return vector3 - Standardized vector3 coordinates
local function normalizeCoords(coords)
    local coordType = type(coords)
    
    if coordType ~= "vector3" then
        if coordType == "table" or coordType == "vector4" then
            -- Handle array-style or object-style coordinates
            return vec3(
                coords[1] or coords.x,
                coords[2] or coords.y,
                coords[3] or coords.z
            )
        end
        
        error(string.format("expected type 'vector3' or 'table' (received %s)", coordType))
    end
    
    return coords
end

-- Main point update loop
-- Calculates distances, determines closest point, handles enter/exit callbacks
local function updatePoints()
    -- Get current player coordinates
    local playerCoords = GetEntityCoords(WSB.cache.ped)
    WSB.cache.coords = playerCoords
    
    -- Check if closest point is now too far away
    if closestPoint then
        local distanceToClosest = #(playerCoords - closestPoint.coords)
        
        if distanceToClosest > closestPoint.distance then
            closestPoint.isClosest = nil
            closestPoint = nil
        end
    end
    
    -- Reset nearby point counter
    nearbyPointCount = 0
    
    -- Iterate through all registered points
    for pointId, point in pairs(registeredPoints) do
        -- Calculate current distance to player
        local distanceToPlayer = #(playerCoords - point.coords)
        point.currentDistance = distanceToPlayer
        
        -- Check if point is within its defined distance
        if distanceToPlayer <= point.distance then
            -- Update closest point if this one is closer
            if closestPoint then
                if distanceToPlayer < closestPoint.currentDistance then
                    closestPoint.isClosest = nil
                    point.isClosest = true
                    closestPoint = point
                end
            else
                closestPoint.isClosest = nil
                point.isClosest = true
                closestPoint = point
            end
            
            -- Add to nearby points if it has a nearby callback
            if point.nearby then
                nearbyPointCount = nearbyPointCount + 1
                nearbyPoints[nearbyPointCount] = point
            end
            
            -- Handle onEnter callback
            if point.onEnter then
                if not point.inside then
                    point.inside = true
                    point:onEnter()
                end
            else
                -- Mark as inside even without callback
                if not point.inside then
                    point.inside = true
                end
            end
        else
            -- Player is outside the point's range
            if point.inside then
                -- Handle onExit callback
                if point.onExit then
                    point:onExit()
                end
                
                point.inside = nil
            end
            
            point.currentDistance = nil
        end
    end
end

-- WSB Points API
WSB.points = {
    -- Create a new point
    -- @param coords vector3|table - Coordinates or point configuration table
    -- @param distance number|nil - Distance threshold
    -- @param options table|nil - Additional options (callbacks, custom properties)
    -- @return table - Point object with remove() method
    new = function(...)
        local args = {...}
        
        -- Generate unique point ID
        local pointId = #registeredPoints + 1
        local point = nil
        
        -- Check if first argument is a configuration table
        if type(args[1]) == "table" then
            point = args[1]
            point.id = pointId
            point.remove = removePoint
        else
            -- Create point from individual arguments
            point = {
                id = pointId,
                coords = args[1],
                remove = removePoint
            }
        end
        
        -- Normalize coordinates to vector3
        point.coords = normalizeCoords(point.coords)
        
        -- Set distance (from point table or second argument)
        point.distance = point.distance or args[2]
        
        -- Apply additional options from third argument
        if args[3] then
            for key, value in pairs(args[3]) do
                point[key] = value
            end
        end
        
        -- Register the point
        registeredPoints[pointId] = point
        
        return point
    end,
    
    -- Get all registered points
    -- @return table - Table of all points
    getAllPoints = function()
        return registeredPoints
    end,
    
    -- Get all nearby points (within their distance threshold)
    -- @return table - Array of nearby points
    getNearbyPoints = function()
        return nearbyPoints
    end,
    
    -- Get the closest point to the player
    -- @return table|nil - Closest point or nil if none in range
    getClosestPoint = function()
        return closestPoint
    end
}

-- Main update thread
CreateThread(function()
    while true do
        -- Update all points
        updatePoints()
        
        -- Manage nearby points interval
        if nearbyPointCount > 0 then
            -- Start interval if not already running
            if not nearbyPointsInterval then
                nearbyPointsInterval = SetInterval(function()
                    -- Call nearby callback for all nearby points
                    for index = 1, nearbyPointCount, 1 do
                        local point = nearbyPoints[index]
                        
                        if point then
                            -- Protected call to prevent script errors
                            local success, error = pcall(function()
                                point:nearby()
                            end)
                            
                            -- Remove point if callback errors
                            if not success then
                                point:remove()
                            end
                        end
                    end
                end, 0)  -- Execute every frame
            end
        else
            -- Stop interval if no nearby points
            if nearbyPointCount == 0 then
                if nearbyPointsInterval then
                    nearbyPointsInterval = ClearInterval(nearbyPointsInterval)
                end
            end
        end
        
        -- Run main update loop every 300ms
        Wait(300)
    end
end)