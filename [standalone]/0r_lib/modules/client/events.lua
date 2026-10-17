
RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function()
    TriggerServerEvent("0R:Core:NewPlayerJoined")
end)


-- -----------------------------------------------------------------------------
-- QBCore: QBCore:Client:OnPlayerLoaded
-- Equivalent hook for QBCore framework – same behaviour as above.
-- -----------------------------------------------------------------------------
RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    TriggerServerEvent("0R:Core:NewPlayerJoined")
end)


-- -----------------------------------------------------------------------------
-- ESX: esx:setJob
-- Fires when the player's job changes in ESX.
-- Updates the local PlayerData cache and syncs the new job to the server.
-- -----------------------------------------------------------------------------
RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(newJob)
    -- Update the local cached player data with the new job
    Resmon.Lib.PlayerData.job = newJob
    -- Inform the server of the job change
    TriggerServerEvent("0R:Core:SetPlayerJob", newJob)
end)


-- -----------------------------------------------------------------------------
-- QBCore: QBCore:Client:OnJobUpdate
-- Equivalent job-update hook for QBCore – same behaviour as above.
-- -----------------------------------------------------------------------------
RegisterNetEvent("QBCore:Client:OnJobUpdate")
AddEventHandler("QBCore:Client:OnJobUpdate", function(newJob)
    -- Update the local cached player data with the new job
    Resmon.Lib.PlayerData.job = newJob
    -- Inform the server of the job change
    TriggerServerEvent("0R:Core:SetPlayerJob", newJob)
end)


-- -----------------------------------------------------------------------------
-- QBCore: qb-spawn:client:openUI
-- Fires when the QBCore spawn-selection UI opens (player is choosing a spawn
-- point after logging in). Treated as a "player joined" signal so the server
-- can initialise data even before the standard OnPlayerLoaded event fires.
-- -----------------------------------------------------------------------------
RegisterNetEvent("qb-spawn:client:openUI")
AddEventHandler("qb-spawn:client:openUI", function()
    TriggerServerEvent("0R:Core:NewPlayerJoined")
end)


-- -----------------------------------------------------------------------------
-- onResourceStart
-- Fires when any resource starts. If this resource itself is (re)starting,
-- re-register the player with the server so data is re-initialised cleanly
-- without needing a full reconnect.
-- -----------------------------------------------------------------------------
AddEventHandler("onResourceStart", function(startedResourceName)
    -- Only act when OUR resource is the one that started
    if GetCurrentResourceName() ~= startedResourceName then
        return
    end
    TriggerServerEvent("0R:Core:NewPlayerJoined")
end)


-- -----------------------------------------------------------------------------
-- 0R:Core:SetPlayerData
-- Server → Client: pushes a complete PlayerData table to this client.
-- Replaces the entire local cache so subsequent calls to Resmon.Lib.PlayerData
-- return up-to-date information.
-- -----------------------------------------------------------------------------
RegisterNetEvent("0R:Core:SetPlayerData")
AddEventHandler("0R:Core:SetPlayerData", function(playerData)
    Resmon.Lib.PlayerData = playerData
end)


-- -----------------------------------------------------------------------------
-- 0R:Core:ServerCallback
-- Server → Client: delivers the result of a server-side callback.
-- Looks up the pending callback function by its request ID, calls it with
-- the returned arguments, then removes the entry to free memory.
-- -----------------------------------------------------------------------------
RegisterNetEvent("0R:Core:ServerCallback")
AddEventHandler("0R:Core:ServerCallback", function(requestId, ...)
    -- Retrieve the stored callback function for this request ID
    local callbackFn = Resmon.Lib.ServerCallbacks[requestId]
    -- Execute the callback with the server-provided return values
    callbackFn(...)
    -- Clean up: remove the callback so it cannot be called again
    Resmon.Lib.ServerCallbacks[requestId] = nil
end)
