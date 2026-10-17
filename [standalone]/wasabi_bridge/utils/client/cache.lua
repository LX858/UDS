-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Initialize the cache table in WSB namespace
WSB.cache = {
    ped = nil,      -- Current player ped entity
    vehicle = nil,  -- Current vehicle player is in (if any)
    seat = nil,     -- Current seat index in vehicle (if in vehicle)
    weapon = nil    -- Current weapon hash (if holding a weapon)
}

-- Cache the player ID (client-side player index)
WSB.cache.playerId = PlayerId()

-- Cache the server ID (server-side player index)
WSB.cache.serverId = GetPlayerServerId(WSB.cache.playerId)

-- Native function references for performance
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehicleMaxNumberOfPassengers = GetVehicleMaxNumberOfPassengers
local GetCurrentPedWeapon = GetCurrentPedWeapon

-- Update cache value and trigger events if value changed
-- @param cacheKey string - The cache key to update (e.g., "ped", "vehicle", "seat", "weapon")
-- @param newValue any - The new value to set
local function updateCacheValue(cacheKey, newValue)
    local currentValue = WSB.cache[cacheKey]
    
    -- Only update if value has changed
    if currentValue ~= newValue then
        WSB.cache[cacheKey] = newValue
        
        -- Trigger specific cache update event
        TriggerEvent("wasabi_bridge:cache:" .. cacheKey, newValue)
        
        -- Trigger general cache update event
        TriggerEvent("wasabi_bridge:updateCache", cacheKey, newValue)
    end
end

-- Main cache monitoring thread
CreateThread(function()
    while true do
        -- Get current player ped
        local currentPed = PlayerPedId()
        updateCacheValue("ped", currentPed)
        
        -- Check if player is in a vehicle
        local currentVehicle = GetVehiclePedIsIn(currentPed, false)
        
        if currentVehicle > 0 then
            -- Player is in a vehicle
            updateCacheValue("vehicle", currentVehicle)
            
            -- Determine which seat the player is in
            local needsSeatUpdate = false
            
            -- Check if we need to update seat (either no seat cached or ped in cached seat changed)
            if WSB.cache.seat then
                local pedInCachedSeat = GetPedInVehicleSeat(currentVehicle, WSB.cache.seat)
                needsSeatUpdate = (pedInCachedSeat ~= currentPed)
            else
                needsSeatUpdate = true
            end
            
            if needsSeatUpdate then
                -- Search through all seats to find which one the player is in
                -- Seats: -1 = driver, 0+ = passengers
                local maxPassengers = GetVehicleMaxNumberOfPassengers(currentVehicle) - 1
                
                for seatIndex = -1, maxPassengers, 1 do
                    local pedInSeat = GetPedInVehicleSeat(currentVehicle, seatIndex)
                    
                    if pedInSeat == currentPed then
                        updateCacheValue("seat", seatIndex)
                        break
                    end
                end
            end
        else
            -- Player is not in a vehicle
            updateCacheValue("vehicle", false)
            updateCacheValue("seat", false)
        end
        
        -- Get current weapon
        local hasWeapon, currentWeaponHash = GetCurrentPedWeapon(currentPed, true)
        
        -- Update weapon cache (false if no weapon, hash if has weapon)
        updateCacheValue("weapon", (hasWeapon and currentWeaponHash) or false)
        
        -- Wait 100ms before next update cycle
        Wait(100)
    end
end)