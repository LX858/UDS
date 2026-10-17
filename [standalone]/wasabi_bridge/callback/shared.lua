-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Storage for callback ownership (maps callback name to resource name)
local callbackOwnership = {}

-- Clean up callbacks when a resource stops
AddEventHandler("onResourceStop", function(stoppedResourceName)
    -- Don't clean up if this resource (wasabi_bridge) is stopping
    local invokingResource = GetInvokingResource()
    if invokingResource == stoppedResourceName then
        return
    end
    
    -- Remove all callbacks owned by the stopped resource
    for callbackName, ownerResource in pairs(callbackOwnership) do
        if ownerResource == stoppedResourceName then
            callbackOwnership[callbackName] = nil
        end
    end
end)

-- Set or validate callback ownership
-- @param callbackName string - Name of the callback
-- @param isValid boolean|nil - If true, registers callback; if false/nil, removes it
function SetValidCallback(callbackName, isValid)
    -- Get the resource that's calling this function
    local invokingResource = GetInvokingResource()
    if not invokingResource then
        invokingResource = "wasabi_bridge"
    end
    
    local currentOwner = callbackOwnership[callbackName]
    
    if currentOwner then
        -- If trying to remove the callback
        if not isValid then
            callbackOwnership[callbackName] = nil
            return
        end
        
        -- If the same resource is re-registering, allow it
        if currentOwner == invokingResource then
            return
        end
        
        -- Different resource trying to overwrite - this is an error
        local errorMsg = string.format(
            "^1resource '%s' attempted to overwrite callback '%s' owned by resource '%s'^0",
            invokingResource,
            callbackName,
            currentOwner
        )
        
        print(string.format(
            "^1SCRIPT ERROR: %s^0\n%s",
            errorMsg,
            Citizen.InvokeNative(0xD70AACA0, nil, 0, Citizen.ResultAsString()) or ""
        ))
        
        return
    end
    
    -- Register the callback ownership
    callbackOwnership[callbackName] = invokingResource
end

-- Check if a callback is valid (owned by wasabi_bridge)
-- @param callbackName string - Name of the callback to check
-- @return boolean - true if callback is valid and owned by wasabi_bridge
function IsCallbackValid(callbackName)
    return callbackOwnership[callbackName] == "wasabi_bridge"
end

-- Event name format string for callbacks
local CALLBACK_EVENT_FORMAT = "__wsb_cb_%s"

-- Handle callback validation requests
-- Responds with "cb_invalid" if callback doesn't exist
RegisterNetEvent("wasabi_bridge:validateCallback", function(callbackName, bridgeName, callbackId)
    -- Check if callback is registered
    if callbackOwnership[callbackName] then
        return
    end
    
    -- Build the response event name
    local responseEvent = string.format(CALLBACK_EVENT_FORMAT, bridgeName)
    
    -- Determine if we're running on server or client and send appropriate response
    local gameName = GetGameName()
    if gameName == "fxserver" then
        -- Server side: send to client
        TriggerClientEvent(responseEvent, source, callbackId, "cb_invalid")
    else
        -- Client side: send to server
        TriggerServerEvent(responseEvent, callbackId, "cb_invalid")
    end
end)