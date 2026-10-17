TokenManager = {}
TokenManager.ActiveTokens = {}
TokenManager.ActiveTokensBySource = {}
TokenManager.PlayerViolations = {}

function TokenManager:GetIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end

    for _, identifier in ipairs(identifiers) do
        if identifier and identifier ~= '' then
            if identifier:sub(1, 8) == 'license:' or identifier:sub(1, 6) == 'steam:' or identifier:sub(1, 6) == 'discord:' then
                return identifier
            end
        end
    end

    return identifiers[1]
end

-- Generate random token
function TokenManager:GenerateToken(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local token = ""
    math.randomseed(os.time() + GetGameTimer())
    
    for i = 1, length do
        local rand = math.random(1, #charset)
        token = token .. string.sub(charset, rand, rand)
    end
    
    return token
end

-- Create token for player
function TokenManager:CreateToken(source)
    local identifier = self:GetIdentifier(source)
    if not identifier then return nil end
    
    local token = self:GenerateToken(Config.TokenLength)
    local expiresAt = GetGameTimer() + Config.TokenExpireTime
    
    self.ActiveTokens[identifier] = {
        token = token,
        source = source,
        expiresAt = expiresAt,
        createdAt = GetGameTimer()
    }
    self.ActiveTokensBySource[source] = identifier
    
    if Config.EnableLogging then
        print(string.format("^2[Anti-Trigger]^7 Token created for player %s (%s)", GetPlayerName(source), identifier))
    end
    
    return token
end

-- Validate token
function TokenManager:ValidateToken(source, token)
    local identifier = self:GetIdentifier(source)
    if not identifier then return false end
    
    local tokenData = self.ActiveTokens[identifier]
    
    -- Check if token exists for current identifier or migrated source mapping
    if not tokenData and self.ActiveTokensBySource[source] then
        local mappedIdentifier = self.ActiveTokensBySource[source]
        tokenData = self.ActiveTokens[mappedIdentifier]
        identifier = mappedIdentifier
    end
    
    if not tokenData then
        local currentName = GetPlayerName(source)
        if currentName then
            for storedIdentifier, storedTokenData in pairs(self.ActiveTokens) do
                if storedTokenData and storedTokenData.source == source then
                    tokenData = storedTokenData
                    identifier = storedIdentifier
                    break
                end
            end
        end
    end
    
    -- Check if token exists
    if not tokenData then
        self:RecordViolation(source, "No token found")
        return false
    end
    
    -- Check if token matches
    if tokenData.token ~= token then
        self:RecordViolation(source, "Invalid token")
        return false
    end
    
    -- Check if token expired
    if GetGameTimer() > tokenData.expiresAt then
        self:RecordViolation(source, "Token expired")
        self.ActiveTokens[identifier] = nil
        self.ActiveTokensBySource[source] = nil
        return false
    end
    
    -- Check if source matches
    if tokenData.source ~= source then
        tokenData.source = source
        self.ActiveTokensBySource[source] = identifier
    end
    
    return true
end

-- Refresh token
function TokenManager:RefreshToken(source)
    local identifier = self:GetIdentifier(source)
    if not identifier then return nil end
    
    local tokenData = self.ActiveTokens[identifier]
    if not tokenData then return nil end
    
    -- Generate new token
    local newToken = self:GenerateToken(Config.TokenLength)
    local expiresAt = GetGameTimer() + Config.TokenExpireTime
    
    self.ActiveTokens[identifier] = {
        token = newToken,
        source = source,
        expiresAt = expiresAt,
        createdAt = GetGameTimer()
    }
    self.ActiveTokensBySource[source] = identifier
    
    if Config.EnableLogging then
        print(string.format("^3[Anti-Trigger]^7 Token refreshed for player %s (%s)", GetPlayerName(source), identifier))
    end
    
    return newToken
end

-- Remove token
function TokenManager:RemoveToken(source)
    local identifier = self:GetIdentifier(source)
    if not identifier then return end
    
    self.ActiveTokens[identifier] = nil
    self.ActiveTokensBySource[source] = nil
    self.PlayerViolations[identifier] = nil
    
    if Config.EnableLogging then
        print(string.format("^1[Anti-Trigger]^7 Token removed for player %s (%s)", GetPlayerName(source), identifier))
    end
end

-- Record violation
function TokenManager:RecordViolation(source, reason)
    local identifier = self:GetIdentifier(source)
    if not identifier then return end
    
    if not self.PlayerViolations[identifier] then
        self.PlayerViolations[identifier] = {
            count = 0,
            lastViolation = 0,
            violations = {}
        }
    end
    
    local violations = self.PlayerViolations[identifier]
    local now = GetGameTimer()
    
    -- Reset violations if enough time has passed
    if now - violations.lastViolation > Config.ViolationResetTime then
        violations.count = 0
        violations.violations = {}
    end
    
    violations.count = violations.count + 1
    violations.lastViolation = now
    table.insert(violations.violations, {
        reason = reason,
        time = now
    })
    
    -- Log violation
    print(string.format("^1[Anti-Trigger] VIOLATION^7 Player: %s (%s) | Reason: %s | Count: %d/%d", 
        GetPlayerName(source), identifier, reason, violations.count, Config.MaxViolations))
    
    -- Send webhook notification
    if Config.Webhook.enabled then
        self:SendWebhook(source, identifier, reason, violations.count)
    end
    
    -- Ban if violations exceed limit
    if Config.BanOnViolation and violations.count >= Config.MaxViolations then
        DropPlayer(source, string.format("[Anti-Trigger] Banned for security violations (%d/%d)", violations.count, Config.MaxViolations))
        print(string.format("^1[Anti-Trigger] BANNED^7 Player %s (%s) for %d violations", GetPlayerName(source), identifier, violations.count))
    end
end

-- Send webhook notification
function TokenManager:SendWebhook(source, identifier, reason, violationCount)
    if not Config.Webhook.url or Config.Webhook.url == '' then return end
    
    local embed = {
        {
            ["color"] = Config.Webhook.color,
            ["title"] = "🚨 Anti-Trigger Violation Detected",
            ["description"] = "A player has triggered a security violation",
            ["fields"] = {
                {
                    ["name"] = "Player",
                    ["value"] = GetPlayerName(source),
                    ["inline"] = true
                },
                {
                    ["name"] = "Identifier",
                    ["value"] = identifier,
                    ["inline"] = true
                },
                {
                    ["name"] = "Reason",
                    ["value"] = reason,
                    ["inline"] = false
                },
                {
                    ["name"] = "Violations",
                    ["value"] = string.format("%d/%d", violationCount, Config.MaxViolations),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Anti-Trigger System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
        }
    }
    
    PerformHttpRequest(Config.Webhook.url, function(err, text, headers) end, 'POST', json.encode({
        username = 'Anti-Trigger System',
        embeds = embed
    }), {['Content-Type'] = 'application/json'})
end

-- Get token info
function TokenManager:GetTokenInfo(source)
    local identifier = GetPlayerIdentifiers(source)[1]
    if not identifier then return nil end
    
    return self.ActiveTokens[identifier]
end

-- Clean expired tokens (run periodically)
function TokenManager:CleanExpiredTokens()
    local currentTime = GetGameTimer()
    local cleaned = 0
    
    for identifier, tokenData in pairs(self.ActiveTokens) do
        if currentTime > tokenData.expiresAt then
            self.ActiveTokensBySource[tokenData.source] = nil
            self.ActiveTokens[identifier] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 and Config.EnableLogging then
        print(string.format("^3[Anti-Trigger]^7 Cleaned %d expired tokens", cleaned))
    end
end
