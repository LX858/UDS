-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Get the closest vehicle to a specified position
-- @param coords vector3|nil - Coordinates to search from (defaults to player position)
-- @param maxDistance number|nil - Maximum search distance (defaults to 1000.0)
-- @param includePlayerVehicle boolean|nil - Whether to return player's current vehicle immediately
-- @return number|nil - Vehicle entity handle, or nil if none found
function WSB.getClosestVehicle(coords, maxDistance, includePlayerVehicle)
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- If includePlayerVehicle is true and player is in a vehicle, return it immediately
    if includePlayerVehicle and playerVehicle ~= 0 then
        return playerVehicle
    end
    
    -- Get all vehicles in the game world
    local allVehicles = GetGamePool("CVehicle")
    
    local closestDistance = -1
    local closestVehicle = -1
    
    -- Use provided coords or default to player position
    local searchCoords = coords
    if searchCoords == nil then
        searchCoords = GetEntityCoords(playerPed)
    end
    
    -- Use provided max distance or default to 1000.0
    if maxDistance == nil then
        maxDistance = 1000.0
    end
    
    -- Iterate through all vehicles to find the closest one
    for index = 1, #allVehicles, 1 do
        -- Skip player's current vehicle if it exists
        if playerVehicle then
            if allVehicles[index] == playerVehicle then
                goto continue
            end
        end
        
        local vehicleCoords = GetEntityCoords(allVehicles[index])
        local distance = #(searchCoords - vehicleCoords)
        
        -- Update closest vehicle if this one is closer
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = allVehicles[index]
            closestDistance = distance
        end
        
        ::continue::
    end
    
    -- Return closest vehicle if within max distance
    if closestDistance ~= -1 and maxDistance >= closestDistance then
        return closestVehicle
    else
        return nil
    end
end

-- Get the closest player (by player ID) to a specified position
-- @param coords vector3|nil - Coordinates to search from (defaults to player position)
-- @param maxDistance number|nil - Maximum search distance (defaults to 1000.0)
-- @return number|nil - Player ID, or nil if none found
function WSB.getClosestPlayer(coords, maxDistance)
    local allPlayers = GetActivePlayers()
    local localPlayerId = PlayerId()
    
    local closestDistance = -1
    local closestPlayerId = -1
    
    -- Use provided coords or default to player position
    local searchCoords = coords
    if searchCoords == nil then
        searchCoords = GetEntityCoords(PlayerPedId())
    end
    
    -- Use provided max distance or default to 1000.0
    if maxDistance == nil then
        maxDistance = 1000.0
    end
    
    -- Iterate through all players to find the closest one
    for index = 1, #allPlayers, 1 do
        local playerId = allPlayers[index]
        
        -- Skip local player
        if playerId ~= localPlayerId then
            local playerPed = GetPlayerPed(playerId)
            
            if playerPed ~= nil then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(searchCoords - playerCoords)
                
                -- Update closest player if this one is closer
                if closestDistance == -1 or closestDistance > distance then
                    closestPlayerId = playerId
                    closestDistance = distance
                end
            end
        end
    end
    
    -- Return closest player if within max distance
    if closestDistance ~= -1 and maxDistance >= closestDistance then
        return closestPlayerId
    else
        return nil
    end
end

-- Get the closest player ped entity to a specified position
-- @param coords vector3|nil - Coordinates to search from (defaults to player position)
-- @param maxDistance number|nil - Maximum search distance (defaults to 1000.0)
-- @return number|nil - Player ped entity handle, or nil if none found
function WSB.getClosestPlayerPed(coords, maxDistance)
    local allPlayers = GetActivePlayers()
    local localPlayerId = PlayerId()
    
    local closestDistance = -1
    local closestPlayerPed = -1
    
    -- Use provided coords or default to player position
    local searchCoords = coords
    if searchCoords == nil then
        searchCoords = GetEntityCoords(PlayerPedId())
    end
    
    -- Use provided max distance or default to 1000.0
    if maxDistance == nil then
        maxDistance = 1000.0
    end
    
    -- Iterate through all players to find the closest one
    for index = 1, #allPlayers, 1 do
        local playerId = allPlayers[index]
        
        -- Skip local player
        if playerId ~= localPlayerId then
            local playerPed = GetPlayerPed(playerId)
            
            if playerPed ~= nil then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(searchCoords - playerCoords)
                
                -- Update closest player if this one is closer
                if closestDistance == -1 or closestDistance > distance then
                    closestPlayerPed = playerPed
                    closestDistance = distance
                end
            end
        end
    end
    
    -- Return closest player ped if within max distance
    if closestDistance ~= -1 and maxDistance >= closestDistance then
        return closestPlayerPed
    end
    
    return nil
end

-- Get all nearby vehicles within a specified distance
-- @param coords vector3|nil - Coordinates to search from (defaults to player position)
-- @param maxDistance number|nil - Maximum search distance (defaults to 1000.0)
-- @param includePlayerVehicle boolean|nil - Whether to include player's current vehicle
-- @return table - Array of vehicle entity handles
function WSB.getNearbyVehicles(coords, maxDistance, includePlayerVehicle)
    local nearbyVehicles = {}
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    
    -- Get all vehicles in the game world
    local allVehicles = GetGamePool("CVehicle")
    
    -- Use provided coords or default to player position
    local searchCoords = coords
    if searchCoords == nil then
        searchCoords = GetEntityCoords(playerPed)
    end
    
    -- Use provided max distance or default to 1000.0
    if maxDistance == nil then
        maxDistance = 1000.0
    end
    
    -- Iterate through all vehicles and collect those within range
    for index = 1, #allVehicles, 1 do
        local vehicleCoords = GetEntityCoords(allVehicles[index])
        local distance = #(searchCoords - vehicleCoords)
        
        if not includePlayerVehicle then
            -- Exclude player's current vehicle if flag is false/nil
            if playerVehicle then
                if allVehicles[index] ~= playerVehicle and maxDistance >= distance then
                    local nextIndex = #nearbyVehicles + 1
                    nearbyVehicles[nextIndex] = allVehicles[index]
                end
            end
        elseif maxDistance >= distance then
            -- Include all vehicles within range
            local nextIndex = #nearbyVehicles + 1
            nearbyVehicles[nextIndex] = allVehicles[index]
        end
    end
    
    return nearbyVehicles
end

-- Get all nearby players (by player ID) within a specified distance
-- @param coords vector3|nil - Coordinates to search from (defaults to player position)
-- @param maxDistance number|nil - Maximum search distance (defaults to 1000.0)
-- @return table - Array of player IDs
function WSB.getNearbyPlayers(coords, maxDistance)
    local allPlayers = GetActivePlayers()
    local localPlayerId = PlayerId()
    local nearbyPlayers = {}
    
    -- Use provided coords or default to player position
    local searchCoords = coords
    if searchCoords == nil then
        searchCoords = GetEntityCoords(PlayerPedId())
    end
    
    -- Use provided max distance or default to 1000.0
    if maxDistance == nil then
        maxDistance = 1000.0
    end
    
    -- Iterate through all players and collect those within range
    for index = 1, #allPlayers, 1 do
        local playerId = allPlayers[index]
        
        -- Skip local player
        if playerId ~= localPlayerId then
            local playerPed = GetPlayerPed(playerId)
            
            if playerPed ~= nil then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(searchCoords - playerCoords)
                
                if maxDistance >= distance then
                    local nextIndex = #nearbyPlayers + 1
                    nearbyPlayers[nextIndex] = playerId
                end
            end
        end
    end
    
    return nearbyPlayers
end

-- Get all nearby player ped entities within a specified distance
-- @param coords vector3|nil - Coordinates to search from (defaults to player position)
-- @param maxDistance number|nil - Maximum search distance (defaults to 1000.0)
-- @return table - Array of player ped entity handles
function WSB.getNearbyPlayerPeds(coords, maxDistance)
    local allPlayers = GetActivePlayers()
    local localPlayerId = PlayerId()
    local nearbyPlayerPeds = {}
    
    -- Use provided coords or default to player position
    local searchCoords = coords
    if searchCoords == nil then
        searchCoords = GetEntityCoords(PlayerPedId())
    end
    
    -- Use provided max distance or default to 1000.0
    if maxDistance == nil then
        maxDistance = 1000.0
    end
    
    -- Iterate through all players and collect their peds if within range
    for index = 1, #allPlayers, 1 do
        local playerId = allPlayers[index]
        
        -- Skip local player
        if playerId ~= localPlayerId then
            local playerPed = GetPlayerPed(playerId)
            
            if playerPed ~= nil then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(searchCoords - playerCoords)
                
                if maxDistance >= distance then
                    local nextIndex = #nearbyPlayerPeds + 1
                    nearbyPlayerPeds[nextIndex] = playerPed
                end
            end
        end
    end
    
    return nearbyPlayerPeds
end

-- Force ownership of an entity to the local player
-- This is necessary for performing certain operations on network entities
-- @param callback function - Callback to execute once ownership is obtained (receives true on success, false on failure)
-- @param entity number - Entity handle to take ownership of
function WSB.forceEntityOwnership(callback, entity)
    local localPlayerId = PlayerId()
    
    -- Check if entity exists
    if not DoesEntityExist(entity) then
        callback(false)
        return
    end
    
    -- Get network ID for the entity
    local networkId = NetworkGetNetworkIdFromEntity(entity)
    
    -- Configure network properties for the entity
    SetNetworkIdCanMigrate(networkId, true)
    SetNetworkIdExistsOnAllMachines(networkId, true)
    NetworkSetNetworkIdDynamic(networkId, true)
    SetNetworkIdSyncToPlayer(networkId, localPlayerId, true)
    
    -- Check if we already own the entity
    local currentOwner = NetworkGetEntityOwner(entity)
    
    if currentOwner ~= localPlayerId then
        -- Request ownership until we get it
        while NetworkGetEntityOwner(entity) ~= localPlayerId do
            NetworkRequestControlOfEntity(entity)
            Wait(30)
        end
    end
    
    -- Ownership obtained successfully
    callback(true)
end

-- Disable control actions (keyboard/gamepad inputs)
-- @param controls number|table|nil - Single control ID, array of control IDs, or nil/empty table to disable all
function WSB.disableKeys(controls)
    local controlType = type(controls)
    
    if controlType == "number" then
        -- Disable single control
        DisableControlAction(0, controls, true)
    else
        -- Check if it's an empty table or nil
        if controls and next(controls) then
            -- Disable specific controls from array
            for index = 1, #controls, 1 do
                DisableControlAction(0, controls[index], true)
            end
        else
            -- Disable all controls
            DisableAllControlActions(0)
        end
    end
end

-- Check if the player is a boss/manager in their job/gang
-- @return boolean - True if player is a boss, false otherwise
function WSB.isPlayerBoss()
    local isBoss = WSB.awaitServerCallback("wasabi_bridge:isPlayerBoss")
    return isBoss or false
end