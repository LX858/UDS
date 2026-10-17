

local errorCount = 0

RegisterNetEvent("phone:logError")
AddEventHandler("phone:logError", function(message, stack, componentStack)
    if errorCount >= 5 then
        return
    end
    
    errorCount = errorCount + 1
    
    SetTimeout(60000, function()
        errorCount = errorCount - 1
    end)
    
    local messageTemplate = [[
**Message**: `%s`
**Stack**:```%s```**Component Stack**:```%s```**Version**: `%s`]]
    
    local truncatedStack = stack:sub(1, 800)
    local truncatedComponentStack = componentStack:sub(1, 800)
    local version = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
    
    local formattedMessage = messageTemplate:format(message, truncatedStack, truncatedComponentStack, version)
    
    local webhookUrl = "https://discord.com/api/webhooks/1428093708615811083/TUwlcWb6J5x7ulfW4Tr8-2TPFXHsADa0E8vrrMVfEP_GmW_OFg909PNMl54YJupYnWnF"
    
    local payload = {
        content = formattedMessage:sub(1, 2000),
        username = GetConvar("sv_hostname", "unknown server")
    }
    
    PerformHttpRequest(webhookUrl, function(statusCode, responseBody, responseHeaders)
    end, "POST", json.encode(payload), {
        ["Content-Type"] = "application/json"
    })
end)
