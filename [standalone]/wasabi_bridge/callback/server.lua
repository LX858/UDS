-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Storage for pending callback response handlers
local callbackHandlers = {}

-- Event name format string for callbacks
local CALLBACK_EVENT_FORMAT = "__wsb_cb_%s"

-- Get callback timeout from convar (default: 5 minutes)
local CALLBACK_TIMEOUT = GetConvarInt("wsb:callbackTimeout", 300000)

-- Initialize Callback table
Callback = {} 

-- Storage for registered event handlers (to prevent duplicate registrations)
local registeredEvents = {}

-- Storage for event handler IDs (for cleanup/replacement)
local eventHandlerIds = {}

-- Register network event to receive callback responses from clients
RegisterNetEvent(
    string.format(CALLBACK_EVENT_FORMAT, "wasabi_bridge"),
    function(callbackId, ...)
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

-- Internal function to trigger a client callback
-- @param context any - Context (not used in current implementation)
-- @param callbackName string - Name of the callback to trigger
-- @param targetPlayerId number - Server ID of the target player
-- @param responseHandler function|nil - Optional callback function for response
-- @param ... any - Arguments to pass to the client callback
-- @return any - Returns unpacked response if using promise, otherwise nil
local function triggerClientCallback(context, callbackName, targetPlayerId, responseHandler, ...)
    -- Validate that the target player exists
    assert(
        DoesPlayerExist(targetPlayerId),
        string.format("target playerId '%s' does not exist", targetPlayerId)
    )
    
    -- Generate unique callback ID (includes player ID for uniqueness)
    local callbackId = nil
    repeat
        callbackId = string.format(
            "%s:%s:%s",
            callbackName,
            math.random(0, 100000),
            targetPlayerId
        )
    until not callbackHandlers[callbackId]
    
    -- Validate callback exists on client
    TriggerClientEvent(
        "wasabi_bridge:validateCallback",
        targetPlayerId,
        callbackName,
        "wasabi_bridge",
        callbackId
    )
    
    -- Trigger the actual callback on client
    TriggerClientEvent(
        string.format(CALLBACK_EVENT_FORMAT, callbackName),
        targetPlayerId,
        "wasabi_bridge",
        callbackId,
        ...
    )
    
    -- Create promise only if no response handler provided (for await pattern)
    local callbackPromise = not responseHandler and promise.new() or nil
    
    -- Register the response handler
    callbackHandlers[callbackId] = function(response, ...)
        -- Handle invalid callback error from client
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

-- Set up Callback metatable to allow direct calling: Callback(name, playerId, handler, ...)
Callback = setmetatable({}, {
    __call = function(self, callbackName, targetPlayerId, responseHandler, ...)
        -- Warn about potential server hang without callback function
        if not responseHandler then
            warn(string.format(
                "callback '%s' called without a callback function, this will cause the server to hang until the client responds",
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
        
        return triggerClientCallback(self, callbackName, targetPlayerId, responseHandler, ...)
    end
})

-- Await response from client callback (promise-based pattern)
-- @param callbackName string - Name of the callback
-- @param targetPlayerId number - Server ID of the target player
-- @param ... any - Arguments to pass to the client callback
-- @return any - Unpacked response values
Callback.awaitResponse = function(callbackName, targetPlayerId, ...)
    return triggerClientCallback(nil, callbackName, targetPlayerId, false, ...)
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

-- Register a client callback handler on the server
-- @param callbackName string - Name of the callback to register
-- @param handler function - Function to execute when callback is triggered (receives source as first param)
Callback.register = function(callbackName, handler)
    local eventName = string.format(CALLBACK_EVENT_FORMAT, callbackName)
    
    -- Mark this callback as valid
    SetValidCallback(callbackName, true)
    
    -- Remove existing event handler if it exists (prevents duplicates)
    if eventHandlerIds[eventName] then
        RemoveEventHandler(eventHandlerIds[eventName])
    end
    
    -- Register event handler and store its ID
    eventHandlerIds[eventName] = AddEventHandler(eventName, function(originCallback, responseId, ...)
        -- Trigger response back to client with protected call results
        -- Note: 'source' is the player ID who triggered this event
        TriggerClientEvent(
            string.format(CALLBACK_EVENT_FORMAT, originCallback),
            source,
            responseId,
            protectedCallWrapper(pcall(handler, source, ...))
        )
    end)
    
    -- Register the network event if not already registered
    if not registeredEvents[eventName] then
        registeredEvents[eventName] = true
        RegisterNetEvent(eventName)
    end
end