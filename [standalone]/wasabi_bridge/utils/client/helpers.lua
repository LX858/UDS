-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Storage for timeout callbacks
local timeoutCallbacks = {}

-- Switch handler for different framework events
-- Routes framework-specific events to Wasabi Bridge unified events
-- @param eventName string - The event name to handle
-- @param eventData any - Data passed with the event
function SwitchHandler(eventName, eventData)
    -- Define event handlers for different scenarios
    local handlers = {
        -- Resource start/initialization
        start = function()
            TriggerEvent("wasabi_bridge:initialize", eventData)
        end,
        
        -- ESX player data update
        ["esx:setPlayerData"] = function()
            TriggerEvent("wasabi_bridge:setPlayerData", eventData)
        end,
        
        -- QBCore player data update
        ["QBCore:Player:SetPlayerData"] = function()
            TriggerEvent("wasabi_bridge:setPlayerData", eventData)
        end,
        
        -- Player logged in
        isLoggedIn = function()
            TriggerEvent("wasabi_bridge:playerLoaded", eventData)
        end,
        
        -- Player logged out
        isLoggedOut = function()
            TriggerEvent("wasabi_bridge:onPlayerLogout")
        end,
        
        -- Job changed
        setJob = function()
            TriggerEvent("wasabi_bridge:setJob", eventData)
        end,
        
        -- Default handler (does nothing)
        default = function()
        end
    }
    
    -- Execute the appropriate handler
    if handlers[eventName] then
        handlers[eventName]()
    else
        handlers.default()
    end
end

-- Export bridge object (capital G for compatibility)
exports("GetBridgeObject", function()
    return WSB
end)

-- Export bridge object (lowercase for compatibility)
exports("getBridgeObject", function()
    return WSB
end)

-- Set a timeout to execute a callback after a delay
-- @param delayMs number - Delay in milliseconds
-- @param callback function - Function to execute after delay
-- @return number - Timeout ID for cancellation
function WSB.setTimeout(delayMs, callback)
    local nextIndex = #timeoutCallbacks + 1
    
    timeoutCallbacks[nextIndex] = {
        time = GetGameTimer() + delayMs,
        cb = callback
    }
    
    return #timeoutCallbacks
end

-- Clear a timeout by its ID
-- @param timeoutId number - The timeout ID to clear
function WSB.clearTimeout(timeoutId)
    timeoutCallbacks[timeoutId] = nil
end

-- Trim whitespace from a string
-- @param str string|nil - String to trim
-- @return string|nil - Trimmed string, or nil if input is nil
function WSB.trim(str)
    if str then
        return string.gsub(str, "^%s*(.-)%s*$", "%1")
    else
        return nil
    end
end

-- Get the Wasabi Bridge version from the server
function WSB.getVersion()
    WSB.serverCallback("wasabi_bridge:getVersion", function(version)
        return version
    end)
end

-- Get player identifier
-- @param idType string|nil - Type of identifier to retrieve (optional)
-- @return string|boolean - Player identifier or false if not found
function WSB.getIdentifier(idType)
    local identifier = WSB.awaitServerCallback("wasabi_bridge:getIdentifier", idType or false)
    return identifier or false
end

-- Dump a table to a formatted string for debugging
-- @param tbl any - Table or value to dump
-- @param indentLevel number|nil - Current indentation level (defaults to 0)
-- @return string - Formatted string representation of the table
function WSB.dumpTable(tbl, indentLevel)
    if indentLevel == nil then
        indentLevel = 0
    end
    
    local valueType = type(tbl)
    
    if valueType == "table" then
        -- Build indentation string
        local indent = ""
        for i = 1, indentLevel + 1, 1 do
            indent = indent .. "    "
        end
        
        local result = "{\n"
        
        -- Iterate through table entries
        for key, value in pairs(tbl) do
            -- Format key (add quotes if not a number)
            if type(key) ~= "number" then
                key = "\"" .. key .. "\""
            end
            
            -- Add indentation for current level
            for i = 1, indentLevel, 1 do
                result = result .. "    "
            end
            
            -- Recursively dump the value
            result = result .. "[" .. key .. "] = " .. WSB.dumpTable(value, indentLevel + 1) .. ",\n"
        end
        
        -- Add closing brace with proper indentation
        for i = 1, indentLevel, 1 do
            result = result .. "    "
        end
        result = result .. "}"
        
        return result
    else
        return tostring(tbl)
    end
end

-- Client-side only code (not on server)
if not IsDuplicityVersion() then
    -- Handle framework initialization
    AddEventHandler("wasabi_bridge:initialize", function()
        -- Only allow wasabi_bridge resource to trigger this
        if GetInvokingResource() ~= "wasabi_bridge" then
            return
        end
        
        -- Initialize ESX player data
        if WSB.framework == "esx" then
            WSB.playerData = ESX.GetPlayerData()
            WSB.playerLoaded = true
        end
        
        -- Initialize QBCore player data
        if WSB.framework == "qb" then
            WSB.playerData = QBCore.Functions.GetPlayerData()
            WSB.playerLoaded = true
        end
    end)
    
    -- Handle player data updates
    AddEventHandler("wasabi_bridge:setPlayerData", function(newData)
        -- Only allow wasabi_bridge resource to trigger this
        if GetInvokingResource() ~= "wasabi_bridge" then
            return
        end
        
        -- QBCore: Replace entire player data
        if WSB.framework == "qb" then
            WSB.playerData = newData
            return
        end
        
        -- ESX: Update specific key/value pair
        if WSB.framework == "esx" then
            WSB.playerData[newData.key] = newData.value
        end
    end)
    
    -- Handle player loaded event
    RegisterNetEvent("wasabi_bridge:playerLoaded", function(playerData)
        WSB.playerData = playerData
        WSB.playerLoaded = true
        
        -- For QBCore, refresh player data
        if WSB.framework == "qb" then
            WSB.playerData = QBCore.Functions.GetPlayerData()
        end
    end)
    
    -- Handle player logout event
    RegisterNetEvent("wasabi_bridge:onPlayerLogout", function()
        table.wipe(WSB.playerData)
        WSB.playerLoaded = false
    end)
    
    -- Handle job change event
    RegisterNetEvent("wasabi_bridge:setJob", function(newJob)
        WSB.playerData.job = newJob
        
        -- For QBCore, refresh entire player data
        if WSB.framework == "qb" then
            WSB.playerData = QBCore.Functions.GetPlayerData()
        end
    end)
end

-- Debug print function (sends to server)
-- @param message any - Message to print
function WSB.debugPrint(message)
    TriggerServerEvent("wasabi_bridge:debugPrint", message)
end

-- Storage for interval timers
local intervalTimers = {}

-- Set an interval to repeatedly execute a callback
-- @param callback function|number - Function to execute, or interval ID to update
-- @param intervalMs number - Interval in milliseconds between executions
-- @param ... any - Arguments to pass to the callback
-- @return number - Interval ID for cancellation
function SetInterval(callback, intervalMs, ...)
    -- Default interval to 0 if not provided
    if not intervalMs then
        intervalMs = 0
    end
    
    -- Validate interval is a number
    if type(intervalMs) ~= "number" then
        return error(string.format("Interval must be a number. Received %s", json.encode(intervalMs)))
    end
    
    local callbackType = type(callback)
    
    -- If callback is a number, update existing interval
    if callbackType == "number" then
        if intervalTimers[callback] then
            intervalTimers[callback] = intervalMs or 0
            return
        end
    end
    
    -- Validate callback is a function
    if callbackType ~= "function" then
        return error(string.format("Callback must be a function. Received %s", callbackType))
    end
    
    -- Store callback arguments
    local args = {...}
    
    local intervalId = nil
    
    -- Create the interval thread
    Citizen.CreateThreadNow(function(threadId)
        intervalId = threadId
        intervalTimers[intervalId] = intervalMs or 0
        
        repeat
            -- Get current interval value (can be updated dynamically)
            intervalMs = intervalTimers[intervalId]
            
            Wait(intervalMs)
            
            -- Execute callback with stored arguments
            callback(table.unpack(args))
        until intervalMs < 0  -- Stop if interval set to negative value
        
        -- Clean up
        intervalTimers[intervalId] = nil
    end)
    
    return intervalId
end

-- Clear an interval by its ID
-- @param intervalId number - The interval ID to clear
function ClearInterval(intervalId)
    -- Validate interval ID is a number
    if type(intervalId) ~= "number" then
        return error(string.format("Interval id must be a number. Received %s", json.encode(intervalId)))
    end
    
    -- Check if interval exists
    if not intervalTimers[intervalId] then
        return error(string.format("No interval exists with id %s", intervalId))
    end
    
    -- Set interval to -1 to trigger cleanup in the interval thread
    intervalTimers[intervalId] = -1
end

-- Wait for a condition to be true with timeout
-- @param condition function - Function that returns true when condition is met
-- @param errorMessage string|nil - Error message if timeout occurs
-- @param timeoutMs number|nil - Timeout in milliseconds (defaults to 1000)
-- @return any - Result of the condition function
function WSB.waitFor(condition, errorMessage, timeoutMs)
    -- Validate and default timeout
    if type(timeoutMs) ~= "number" or not timeoutMs then
        timeoutMs = 1000
    end
    
    local startTime = GetGameTimer()
    local result = condition()
    
    while not result do
        Wait(0)
        
        local elapsedTime = GetGameTimer() - startTime
        
        -- Check for timeout
        if timeoutMs < elapsedTime then
            return error(
                string.format(
                    "%s (waited %.1fms)",
                    errorMessage or "failed to resolve callback",
                    elapsedTime
                ),
                2  -- Error level 2 (report error at caller level)
            )
        end
        
        result = condition()
    end
    
    return result
end