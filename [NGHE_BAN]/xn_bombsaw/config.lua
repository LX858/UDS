Config = {}

Config.NPCHash = 'a_m_m_hillbilly_01'
Config.NPCPosition = vector4(1531.81, 1728.08, 109.92, 98.97)

Config.ProspectorPrice = 500

Config.BombSawingSuccess = 20 -- số lần bấm e thành công (tổng cả 2 người)
Config.BombSawingSuccessPerPerson = 6 -- mỗi người phải thành công tối thiểu bấy nhiêu lần
Config.BombSawingFail = 3 -- số lần bấm e thất bại (tổng cả 2 người)

-- Phần thưởng khi cưa bom thành công (luôn nhận)
Config.BombRewards = {
    {item = 'thuocsung', amount = 1},
    {item = 'manh_boom_vo', amount = 1},
}

-- Phần thưởng may mắn (tỷ lệ % nhận được)
Config.BonusRewards = {
    {item = 'manhkimloai', amount = 1, chance = 10}, -- 5% cơ hội
}

-- Blacklist khu vực không thể đặt bom
Config.BlacklistZones = {
    {
        name = "Bệnh viện Pillbox",
        coords = vector3(298.67, -584.50, 43.26),
        radius = 75.0 -- bán kính 75 mét
    },
    {
        name = "Cardealer Thành phố",
        coords = vector3(565.3312, -239.4595, 49.9806),
        radius = 75.0 -- bán kính 75 mét
    },
    {
        name = "Sở cảnh sát LSPD",
        coords = vector3(82.11, -416.29, 41.62),
        radius = 75.0 -- bán kính 75 mét
    },
    {
        name = "Vườn nuôi thú",
        coords = vector3(1490.9781, 1066.0985, 114.3341),
        radius = 75.0 -- bán kính 75 mét
    },
    {
        name = "Bãi đá",
        coords = vector3(2954.3057, 2785.4248, 41.2918),
        radius = 75.0 -- bán kính 75 mét
    },
    {
        name = "Công viên trung tâm",
        coords = vector3(192.5118, -939.3913, 29.7680),
        radius = 100.0 -- bán kính 75 mét
    },
    {
        name = "Garage Legion Square",
        coords = vector3(190.0, -946.36, 29.61),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu câu cá",
        coords = vector3(1685.64, 40.05, 161.77),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 1",
        coords = vector3(2537.0, 4814.0, 34.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 2",
        coords = vector3(2485.0, 4841.0, 36.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 3",
        coords = vector3(1914.0, 4763.0, 42.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 4",
        coords = vector3(1886.0, 4794.0, 43.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 5",
        coords = vector3(1861.0, 4817.0, 44.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 6",
        coords = vector3(1956.0, 4795.0, 43.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 7",
        coords = vector3(2033.0, 4877.0, 43.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 8",
        coords = vector3(2005.0, 4904.0, 44.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 9",
        coords = vector3(2043.0, 4941.0, 42.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Khu ruộng 10",
        coords = vector3(2070.0, 4915.0, 41.0),
        radius = 100.0 -- bán kính 100 mét
    },
    {
        name = "Mechanic",
        coords = vector3(-355.3879, -126.1240, 38.0368),
        radius = 120.0 -- bán kính 100 mét
    },
    {
        name = "Khu hái dừa",
        coords = vector3(-1850.456, -657.1502, 19.175859),
        radius = 100.0 -- bán kính 100 mét
    }
}

Config.BlacklistZoneRadius = 50.0 -- Bán kính khu vực cấm (meters)

Config.AllowedZone = {
    coords = vector3(72.9097, -167.7050, 55.1173),
    radius = 1000.0
}


Config.Event = {
    enabled = true, -- Bật/tắt hệ thống phần thưởng đặc biệt
    chance = 30, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
    rewards = {
        {item = "banvevukhi", chance = 100} -- 25% nhận manhgep1
    }
}

Config.CuaBomSuccessCount = 6 -- Số lần cưa bom thành công liên tiếp để hoàn thành
Config.Anticheat = false