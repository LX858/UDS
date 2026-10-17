Config = {}

-- Debug mode - set to true to see debug messages
Config.debug = false

-- Prospecting blip
Config.EnableBlip = false -- true = hiện blip trên bản đồ, false = tắt blip
Config.BlipLocation = vec3(-1171.4543, 33.4847, 51.4955)
Config.ProspectingBlipText = "<FONT FACE='Oswald'>Bãi Mìn</FONT>"
Config.ProspectingBlipSprite = 486
Config.AreaSize = 100.0

-- Police requirement
Config.RequirePolice = false  -- true = require police onduty, false = no requirement
Config.MinimumPolice = 0  -- Minimum number of police required to be onduty

-- Item pool with drop rates (weight system)
-- Higher weight = more common, tổng weight = 100 (100%)
Config.ItemPool = {
    {item = "vodanhong", label = "Vỏ đạn hỏng", weight = 50},       -- 50% chance (common)
    {item = "khuyentaicu", label = "Khuyên tai cũ", weight = 30},   -- 20% chance
    {item = "machdienchay", label = "Mạch điện cháy", weight = 30}, -- 20% chance
    {item = "traimin", label = "Trái mìn", weight = 30},            -- 10% chance (rare)
    {item = "tinhthach", label = "Thiên thạch", weight = 50}, -- 20% chance
}

-- Fixed dig locations - player will be assigned one randomly when using detector
Config.DigLocations = {
    vec3(-1179.9524, 54.9372, 53.9582),
    vec3(-1198.6379, 83.0586, 56.1458),
    vec3(-1176.6466, 93.0844, 58.2525),
    vec3(-1144.7477, 77.7484, 57.1754),
    vec3(-1115.2831, 49.4591, 53.3633),
    vec3(-1107.1902, 17.0370, 50.8209),
    vec3(-1123.5236, -11.6238, 49.1895),
    vec3(-1155.6923, -18.1753, 46.7440),
    vec3(-1197.2117, -19.5894, 46.6556),
    vec3(-1248.4910, 22.4808, 47.9188), 
}


Config.Event = {
    enabled = true, -- Bật/tắt hệ thống phần thưởng đặc biệt
    chance = 30, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
    rewards = {
        {item = "co_bon_la_10", chance = 100}, -- 25% nhận manhgep1
    }
}