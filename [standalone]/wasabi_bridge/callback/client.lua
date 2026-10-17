-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Storage for pending callback response handlers
local callbackHandlers = {}

-- Callback cooldown tracking (prevents spam)
local callbackCooldowns = {}

-- Event name format string for callbacks
local CALLBACK_EVENT_FORMAT = "__wsb_cb_%s"

-- Get callback timeout from convar (default: 5 minutes)
local CALLBACK_TIMEOUT = GetConvarInt("wsb:callbackTimeout", 300000)

-- Initialize Callback table
Callback = {} 

-- Register network event to receive callback responses from server
RegisterNetEvent(
    string.format(CALLBACK_EVENT_FORMAT, "wasabi_bridge"),
    function(callbackId, ...)
        -- Ensure this event came from the server (source will be empty string on client)
        if source == "" then
            return
        end
        
        -- Get the handler for this callback ID
        local handler = callbackHandlers[callbackId]
        if not handler then
            return
        end
        
        -- Remove handler after use (one-time callback)
        callbackHandlers[callbackId] = nil
        
        -- Execute the callback handler with the response data
        handler(...)
    end
)

-- Check if a callback can be triggered (cooldown check)
-- @param callbackName string - Name of the callback
-- @param cooldownMs number|nil - Cooldown period in milliseconds
-- @return boolean - true if callback can be triggered, false if still on cooldown
local function canTriggerCallback(callbackName, cooldownMs)
    if cooldownMs then
        if type(cooldownMs) == "number" and cooldownMs > 0 then
            local currentTime = GetGameTimer()
            local cooldownEndTime = callbackCooldowns[callbackName] or 0
            
            -- Check if still on cooldown
            if currentTime < cooldownEndTime then
                return false
            end
            
            -- Set new cooldown end time
            callbackCooldowns[callbackName] = currentTime + cooldownMs
        end
    end
    
    return true
end

-- Internal function to trigger a server callback
-- @param context any - Context (not used in current implementation)
-- @param callbackName string - Name of the callback to trigger
-- @param cooldownMs number|nil - Optional cooldown in milliseconds
-- @param responseHandler function|nil - Optional callback function for response
-- @param ... any - Arguments to pass to the server callback
-- @return any - Returns unpacked response if using promise, otherwise nil
local function triggerServerCallback(context, callbackName, cooldownMs, responseHandler, ...)
    -- Check cooldown before proceeding
    if not canTriggerCallback(callbackName, cooldownMs) then
        return
    end
    
    -- Generate unique callback ID
    local callbackId = nil
    repeat
        callbackId = string.format("%s:%s", callbackName, math.random(0, 100000))
    until not callbackHandlers[callbackId]
    
    -- Validate callback exists on server
    TriggerServerEvent("wasabi_bridge:validateCallback", callbackName, "wasabi_bridge", callbackId)
    
    -- Trigger the actual callback on server
    TriggerServerEvent(
        string.format(CALLBACK_EVENT_FORMAT, callbackName),
        "wasabi_bridge",
        callbackId,
        ...
    )
    
    -- Create promise only if no response handler provided (for await pattern)
    local callbackPromise = not responseHandler and promise.new() or nil
    
    -- Register the response handler
    callbackHandlers[callbackId] = function(response, ...)
        -- Handle invalid callback error from server
        if response == "cb_invalid" then
            local errorMsg = string.format("callback '%s' does not exist", callbackName)
            
            if callbackPromise then
                callbackPromise:reject(errorMsg)
            else
                error(errorMsg)
            end
            return
        end
        
        -- Pack all response values into a table
        local responseData = {response, ...}
        
        -- If using promise pattern, resolve with response data
        if callbackPromise then
            return callbackPromise:resolve(responseData)
        end
        
        -- If using callback pattern, invoke the handler
        if responseHandler then
            responseHandler(table.unpack(responseData))
        end
    end
    
    -- If using promise pattern, set timeout and await result
    if callbackPromise then
        SetTimeout(CALLBACK_TIMEOUT, function()
            callbackPromise:reject(string.format("callback event '%s' timed out", callbackId))
        end)
        
        return table.unpack(Citizen.Await(callbackPromise))
    end
end

-- Set up Callback metatable to allow direct calling: Callback(name, cooldown, handler, ...)
Callback = setmetatable({}, {
    __call = function(self, callbackName, cooldownMs, responseHandler, ...)
        -- Warn about deprecated usage without callback function
        if not responseHandler then
            warn(string.format(
                "callback '%s' called without a callback function, this will be deprecated in the future",
                callbackName
            ))
        else
            -- Type check for responseHandler
            local handlerType = type(responseHandler)
            
            -- Check if it's a table with __call metamethod (callable table)
            if handlerType == "table" then
                local meta = getmetatable(responseHandler)
                if meta and meta.__call then
                    handlerType = "function"
                end
            end
            
            -- Assert that responseHandler is callable
            assert(
                handlerType == "function",
                string.format("expected argument 3 to have type 'function' (received %s)", handlerType)
            )
        end
        
        return triggerServerCallback(self, callbackName, cooldownMs, responseHandler, ...)
    end
})

-- Await response from server callback (promise-based pattern)
-- @param callbackName string - Name of the callback
-- @param cooldownMs number|nil - Optional cooldown in milliseconds
-- @param ... any - Arguments to pass to the server callback
-- @return any - Unpacked response values
Callback.awaitResponse = function(callbackName, cooldownMs, ...)
    return triggerServerCallback(nil, callbackName, cooldownMs, false, ...)
end

-- Protected call wrapper with error formatting
-- @param success boolean - pcall success status
-- @param errorOrResult any - Error message or first return value
-- @param ... any - Additional return values
-- @return boolean, any... - Success status and return values or error
local function protectedCallWrapper(success, errorOrResult, ...)
    if not success then
        if errorOrResult then
            print(string.format(
                "^1SCRIPT ERROR: %s^0\n%s",
                errorOrResult,
                Citizen.InvokeNative(0xD70AACA0, nil, 0, Citizen.ResultAsString()) or ""
            ))
        end
        return false
    end
    
    return errorOrResult, ...
end

-- Register a server callback handler on the client
-- @param callbackName string - Name of the callback to register
-- @param handler function - Function to execute when callback is triggered
Callback.register = function(callbackName, handler)
    local eventName = string.format(CALLBACK_EVENT_FORMAT, callbackName)
    
    -- Mark this callback as valid
    SetValidCallback(callbackName, true)
    
    -- Register network event to handle incoming callback requests
    RegisterNetEvent(eventName, function(originCallback, responseId, ...)
        -- Trigger response back to server with protected call results
        TriggerServerEvent(
            string.format(CALLBACK_EVENT_FORMAT, originCallback),
            responseId,
            protectedCallWrapper(pcall(handler, ...))
        )
    end)
end