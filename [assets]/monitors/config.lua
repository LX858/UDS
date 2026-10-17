Config = {}

-- Token Configuration
Config.TokenExpireTime = 300000 -- 5 minutes in milliseconds
Config.TokenRefreshInterval = 240000 -- 4 minutes (refresh before expiration)
Config.TokenLength = 64 -- Length of generated token

-- Security Configuration
Config.EnableLogging = false -- Enable security logging
Config.BanOnViolation = true -- Ban player on token violation
Config.MaxViolations = 3 -- Maximum violations before ban
Config.ViolationResetTime = 600000 -- Reset violations after 10 minutes

-- Event Protection
Config.ProtectedEvents = {
    -- Add your protected events here
    -- Example: 'esx:giveItem', 'bank:deposit', etc.
}

-- Webhook Configuration (optional)
Config.Webhook = {
    enabled = false,
    url = '', -- Discord webhook URL
    color = 16711680, -- Red color
}
