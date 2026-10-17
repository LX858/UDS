-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Register callback: Get Wasabi Bridge version
WSB.registerCallback("wasabi_bridge:getVersion", function(source, callback)
    callback(WSB.getVersion())
end)

-- Register callback: Get player identifier
-- @param source number - Player server ID
-- @param callback function - Callback function to return result
-- @param identifierType string|nil - Type of identifier to retrieve (optional)
WSB.registerCallback("wasabi_bridge:getIdentifier", function(source, callback, identifierType)
    -- If no identifier type specified, use source (player ID)
    if not identifierType then
        identifierType = source
    end
    
    callback(WSB.getIdentifier(identifierType))
end)

-- Register callback: Check if player is boss/manager
-- @param source number - Player server ID
-- @param callback function - Callback function to return result
WSB.registerCallback("wasabi_bridge:isPlayerBoss", function(source, callback)
    callback(WSB.isPlayerBoss(source))
end)