-- Server Main Script
print("^2============================================^7")
print("^2   Anti-Trigger System - Token-Based Auth^7")
print("^2   Version: 1.0.0                         ^7")
print("^2============================================^7")

-- Initialize system when player connects
RegisterNetEvent('playerConnecting', function()
    local source = source
    Citizen.Wait(1000) -- Wait for player to fully connect
end)

-- Player ready handler
RegisterNetEvent('anti-trigger:playerReady', function()
    local source = source
    Citizen.Wait(0)
    local token = TokenManager:CreateToken(source)
    
    if token then
        TriggerClientEvent('anti-trigger:receiveToken', source, token)
    else
        DropPlayer(source, "[Anti-Trigger] Failed to generate authentication token")
    end
end)

-- Token refresh request
RegisterNetEvent('anti-trigger:requestRefresh', function()
    local source = source
    local token = TokenManager:RefreshToken(source)
    
    if token then
        TriggerClientEvent('anti-trigger:receiveToken', source, token)
    else
        -- If refresh fails, create new token
        token = TokenManager:CreateToken(source)
        if token then
            TriggerClientEvent('anti-trigger:receiveToken', source, token)
        end
    end
end)

-- Token validation endpoint (for external scripts)
RegisterNetEvent('anti-trigger:validateToken', function(token, callback)
    local source = source
    local isValid = TokenManager:ValidateToken(source, token)
    
    if callback and type(callback) == "function" then
        callback(isValid)
    end
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function(reason)
    local source = source
    TokenManager:RemoveToken(source)
end)

-- Clean expired tokens every 5 minutes
Citizen.CreateThread(function()
    Citizen.Wait(0)
    EventManager:InitializePendingRegistrations()
    while true do
        Citizen.Wait(300000) -- 5 minutes
        TokenManager:CleanExpiredTokens()
    end
end)

-- Export functions for other resources
exports('RegisterProtectedEvent', function(eventName, handler)
    if not EventManager.IsReady then
        EventManager.PendingRegistrations = EventManager.PendingRegistrations or {}
        table.insert(EventManager.PendingRegistrations, {
            eventName = eventName,
            handler = handler
        })
        if Config.EnableLogging then
            print(string.format("^3[Anti-Trigger]^7 Queued protected event registration: %s", eventName))
        end
        return true
    end

    EventManager:RegisterProtectedEvent(eventName, handler)
    return true
end)

exports('RegisterProtectedEvents', function(events)
    for eventName, handler in pairs(events) do
        exports['monitors']:RegisterProtectedEvent(eventName, handler)
    end
    return true
end)

exports('ValidateToken', function(source, token)
    return TokenManager:ValidateToken(source, token)
end)

exports('GetPlayerToken', function(source)
    local tokenInfo = TokenManager:GetTokenInfo(source)
    return tokenInfo and tokenInfo.token or nil
end)

exports('IsEventProtected', function(eventName)
    return EventManager:IsProtected(eventName)
end)

-- -- Command to check token status (admin only)
-- RegisterCommand('tokeninfo', function(source, args)
--     if source == 0 then -- Console only
--         if args[1] then
--             local targetSource = tonumber(args[1])
--             local tokenInfo = TokenManager:GetTokenInfo(targetSource)
            
--             if tokenInfo then
--                 print(string.format("^2Token Info for Player %s:^7", GetPlayerName(targetSource)))
--                 print(string.format("  Token: %s", tokenInfo.token))
--                 print(string.format("  Created: %s", os.date("%Y-%m-%d %H:%M:%S", tokenInfo.createdAt)))
--                 print(string.format("  Expires: %s", os.date("%Y-%m-%d %H:%M:%S", tokenInfo.expiresAt)))
--             else
--                 print(string.format("^1No token found for player %s^7", targetSource))
--             end
--         else
--             print("^3Usage: tokeninfo [player_id]^7")
--         end
--     end
-- end)

-- -- Command to list protected events
-- RegisterCommand('protectedevents', function(source)
--     if source == 0 then -- Console only
--         local events = EventManager:GetProtectedEvents()
--         print(string.format("^2Protected Events (%d):^7", #events))
--         for i, eventName in ipairs(events) do
--             print(string.format("  %d. %s", i, eventName))
--         end
--     end
-- end)

print("^2[Anti-Trigger]^7 System initialized successfully!")
