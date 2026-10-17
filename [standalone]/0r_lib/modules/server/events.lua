
RegisterNetEvent("0R:Core:NewPlayerJoined")
AddEventHandler("0R:Core:NewPlayerJoined", function()
    local playerId = source   -- server-side 'source' = the triggering player's ID
    local playerInfo = {}
    info = playerInfo         -- store in the upvalue so inner blocks can write to it

    -- Check whether this player already has an entry in the registry
    local existingEntry = Resmon.Lib.Players[playerId]

    if not existingEntry then
        -- No existing entry yet; build one from the framework player object
        local newEntry = {}

        -- Only proceed if the framework returned a non-empty data table
        -- (the #newEntry == 0 check guards against a race where data isn't ready)
        if #newEntry ~= 0 then
            -- Fetch the framework player object for this source ID
            local frameworkPlayer = Resmon.Lib.xPlayer(playerId)
            info = frameworkPlayer

            -- Normalise first name, last name, and phone number across frameworks
            if Config.Framework == "ESX" then
                -- ESX stores the full name in .name and splits last name in a table
                info.firstname = info.name
                info.lastname  = newEntry[1].lastname   -- first element of ESX name array
                info.phone     = nil                    -- ESX does not expose phone here
            else
                -- QBCore stores character info inside PlayerData.charinfo
                info.firstname = info.PlayerData.charinfo.firstname
                info.lastname  = info.PlayerData.charinfo.lastname
                info.phone     = info.PlayerData.charinfo.phone
            end

            -- Save the populated entry into the shared player registry
            Resmon.Lib.Players[playerId] = info
        end
    end

    -- Notify the joining client that server-side initialisation is complete,
    -- passing their own server ID so the client knows who it is.
    TriggerClientEvent("0R:Core:NewPlayerJoined", playerId, playerId)
end)


-- =============================================================================
-- EVENT: 0R:Core:PlayerDropped  (server-side net event)
-- Internal event used to remove a player from the registry.
-- Fired by the playerDropped handler below so the cleanup logic lives
-- in one place and can also be triggered manually if needed.
--
-- Parameters:
--   droppedPlayerId – server ID of the player who left
--   reason          – drop reason string (unused here, forwarded by caller)
-- =============================================================================
RegisterNetEvent("0R:Core:PlayerDropped")
AddEventHandler("0R:Core:PlayerDropped", function(droppedPlayerId, reason)
    -- If the player has a registry entry, remove it to free memory
    if Resmon.Lib.Players[droppedPlayerId] then
        Resmon.Lib.Players[droppedPlayerId] = nil
    end
end)


-- =============================================================================
-- EVENT: 0R:Core:Server:setJob  (server-side net event)
-- Fired by the client when the player's job changes (via esx:setJob or
-- QBCore:Client:OnJobUpdate in client events.lua).
-- Updates the server-side registry entry so other server-side code always
-- has the current job without needing to query the framework again.
-- =============================================================================
RegisterNetEvent("0R:Core:Server:setJob")
AddEventHandler("0R:Core:Server:setJob", function(newJob)
    local playerId    = source
    local playerEntry = Resmon.Lib.Players[playerId]
    -- Write the new job directly into the registry entry
    playerEntry.job = newJob
end)


-- =============================================================================
-- EVENT: playerDropped  (built-in FiveM server event)
-- Fired by the server runtime whenever any player disconnects.
-- Propagates the drop to:
--   1. The internal "0R:Core:PlayerDropped" server event (cleans the registry)
--   2. The client-side "0R:Core:PlayerDropped" event on the dropping player
--      (allows the client to perform any local teardown before the connection
--       is fully closed).
--
-- Parameter:
--   reason – string describing why the player disconnected
-- =============================================================================
AddEventHandler("playerDropped", function(reason)
    local playerId = source

    -- Clean up the server-side registry
    TriggerEvent("0R:Core:PlayerDropped", playerId, reason)

    -- Notify the dropping client (passes the player's own ID and the reason)
    TriggerClientEvent("0R:Core:PlayerDropped", playerId, playerId, reason)
end)