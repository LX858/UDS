-- Client Token Manager
local CurrentToken = nil
local TokenExpiresAt = 0
local IsReady = false
local TokenRequestInFlight = false
local LastTokenRequestAt = 0

-- Clientloader - Auto token management
local function RequestToken(eventName)
    local now = GetGameTimer()
    if TokenRequestInFlight and (now - LastTokenRequestAt) < 5000 then
        return
    end

    TokenRequestInFlight = true
    LastTokenRequestAt = now
    TriggerServerEvent(eventName)
end

Citizen.CreateThread(function()
    -- Wait for player to spawn
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end
    
    Citizen.Wait(1000) -- Additional wait for stability
    
    -- Request initial token
    RequestToken('anti-trigger:playerReady')
    
    -- Auto-refresh token before expiration
    while true do
        Citizen.Wait(1000)
        
        if CurrentToken and IsReady then
            local timeLeft = TokenExpiresAt - GetGameTimer()
            
            -- Request refresh when 1 minute left
            if timeLeft < 60000 and timeLeft > 0 then
                RequestToken('anti-trigger:requestRefresh')
                Citizen.Wait(5000) -- Wait before checking again
            elseif timeLeft <= 0 then
                -- Token expired, request new one
                CurrentToken = nil
                IsReady = false
                RequestToken('anti-trigger:playerReady')
                Citizen.Wait(5000)
            end
        end
    end
end)

-- Receive token from server
RegisterNetEvent('anti-trigger:receiveToken', function(token)
    CurrentToken = token
    TokenExpiresAt = GetGameTimer() + Config.TokenExpireTime
    IsReady = true
    TokenRequestInFlight = false
    
    if Config.EnableLogging then
        print(string.format("^2[Anti-Trigger]^7 Token received and will expire in %d seconds", Config.TokenExpireTime / 1000))
    end
end)

-- Get current token
function GetCurrentToken()
    return CurrentToken
end

-- Check if token is ready
function IsTokenReady()
    return IsReady and CurrentToken ~= nil
end

-- Trigger protected event with token
function TriggerProtectedServerEvent(eventName, ...)
    if not IsTokenReady() then
        print(string.format("^1[Anti-Trigger]^7 Cannot trigger event '%s': Token not ready", eventName))
        return false
    end
    
    -- Send token as first argument
    TriggerServerEvent(eventName, CurrentToken, ...)
    return true
end

-- Export functions
exports('GetCurrentToken', GetCurrentToken)
exports('IsTokenReady', IsTokenReady)
exports('TriggerProtectedServerEvent', TriggerProtectedServerEvent)

-- Global helper function
_TriggerProtectedServerEvent = TriggerProtectedServerEvent

print("^2[Anti-Trigger]^7 Clientloader initialized")
