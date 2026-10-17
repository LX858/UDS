EventManager = {}
EventManager.ProtectedEvents = {}
EventManager.Handlers = {}
EventManager.PendingRegistrations = {}
EventManager.IsReady = false

-- Register protected event
function EventManager:RegisterProtectedEvent(eventName, handler)
    -- Store or update handler
    self.Handlers[eventName] = handler
    
    if self.ProtectedEvents[eventName] then
        if Config.EnableLogging then
            print(string.format("^3[Anti-Trigger]^7 Re-registering protected event: %s", eventName))
        end
        return
    end
    
    self.ProtectedEvents[eventName] = true
    
    RegisterNetEvent(eventName, function(...)
        local source = source
        local args = {...}
        
        -- First argument should be the token
        local token = args[1]
        
        if type(token) ~= "string" then
            TokenManager:RecordViolation(source, string.format("Event '%s' called without token", eventName))
            print(string.format("^1[Anti-Trigger]^7 Blocked event '%s' from player %s (no token)", eventName, GetPlayerName(source)))
            return
        end
        
        -- Validate token
        if not TokenManager:ValidateToken(source, token) then
            print(string.format("^1[Anti-Trigger]^7 Blocked event '%s' from player %s (invalid token)", eventName, GetPlayerName(source)))
            return
        end
        
        -- Remove token from arguments
        table.remove(args, 1)
        
        -- Call the actual handler with remaining arguments
        local currentHandler = EventManager.Handlers[eventName]
        if currentHandler then
            currentHandler(source, table.unpack(args))
        end
    end)
    
    if Config.EnableLogging then
        print(string.format("^2[Anti-Trigger]^7 Protected event registered: %s", eventName))
    end
end

function EventManager:InitializePendingRegistrations()
    if self.IsReady then return end
    self.IsReady = true

    if not self.PendingRegistrations or #self.PendingRegistrations == 0 then
        return
    end

    local pending = self.PendingRegistrations
    self.PendingRegistrations = {}

    for _, registration in ipairs(pending) do
        self:RegisterProtectedEvent(registration.eventName, registration.handler)
    end
end

-- Register multiple protected events
function EventManager:RegisterProtectedEvents(events)
    for eventName, handler in pairs(events) do
        self:RegisterProtectedEvent(eventName, handler)
    end
end

-- Check if event is protected
function EventManager:IsProtected(eventName)
    return self.ProtectedEvents[eventName] ~= nil
end

-- Get protected events list
function EventManager:GetProtectedEvents()
    local events = {}
    for eventName, _ in pairs(self.ProtectedEvents) do
        table.insert(events, eventName)
    end
    return events
end

-- Unregister protected event
function EventManager:UnregisterProtectedEvent(eventName)
    if not self.ProtectedEvents[eventName] then
        print(string.format("^3[Anti-Trigger]^7 Warning: Event '%s' is not protected", eventName))
        return
    end
    
    self.ProtectedEvents[eventName] = nil
    
    if Config.EnableLogging then
        print(string.format("^3[Anti-Trigger]^7 Unprotected event: %s", eventName))
    end
end
