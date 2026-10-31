Config = {}

-- Cấu hình Discord Webhook
Config.DiscordWebhook = {
    enabled = true,
    -- Discord A: Logs đâm xe/đánh tay (screenshot trực tiếp từ client)
    combatScreenshotURL =
    'https://discord.com/api/webhooks/1513563599132430396/3vCV66kCtWTtF5vxLSK2gUhyu2euWnhlXl_uj7XQDrrh76NgkhP4fmn-BpT1D122rq3O',

    -- Discord B: Logs đi tù (với thông tin chi tiết + link ảnh)
    prisonDetailedURL =
    'https://discord.com/api/webhooks/1513563599132430396/3vCV66kCtWTtF5vxLSK2gUhyu2euWnhlXl_uj7XQDrrh76NgkhP4fmn-BpT1D122rq3O',

    screenshotResource = 'screenshot-basic' -- Tên resource screenshot (screenshot-basic hoặc discord-screenshot)
}

-- Cấu hình target system
Config.TargetSystem = {
    enabled = true,
    maxDistance = 3.0, -- Khoảng cách tối đa để target (mét)
    policeJobs = { 'police', 'sheriff', 'state' }, -- Các job được coi là công an
    hideNameFromCivilians = true, -- Ẩn tên khỏi dân thường
    icon = 'fa-solid fa-star', -- Icon hiển thị trong ox_target
    label = 'Kiểm tra thông tin' -- Label hiển thị trong ox_target
}

Config.ReputationSystem = {
    maxReputation = 100,
    defaultReputation = 100,

    -- Tự động cất vũ khí khi ở trong vùng an toàn (vùng xanh)
    autoDisarmInZone = true,

    -- Danh sách vũ khí ĐƯỢC PHÉP sử dụng trong vùng an toàn (mặc định cho phép súng điện stungun)
    allowedWeaponsInZone = {
        'WEAPON_STUNGUN',
        'WEAPON_DIGISCANNER',
        'WEAPON_NIGHTSTICK',
    },

    -- Ngưỡng cảnh báo uy tín thấp (100% = luôn hiện UI để test)
    warningThreshold = 1.0, -- TẠM THỜI SET 100% để test UI, sau đổi lại 0.7

    -- Thời gian hiển thị UI cảnh báo (giây)
    warningUIDisplayTime = 30, -- UI sẽ tự động đóng sau 30 giây

    -- Thời gian hiển thị UI cho đánh tay không (giây)
    combatUIDisplayTime = 10, -- UI đánh tay không sẽ tự động đóng sau 10 giây

    -- Ngưỡng uy tín hiện UI cho combat (điểm)
    combatUIThreshold = 100, -- Hiện UI luôn khi đánh tay không (100 = luôn hiện)

    -- Các vị trí không được phép đánh nhau (sẽ bị trừ điểm)
    forbiddenCombatZones = {
        {
            name = "Bệnh viện Pillbox",
            coords = vector3(352.5245, -1407.5192, 32.5110),
            radius = 200.0 -- bán kính 75 mét
        },
        {
            name = "Cardealer Thành phố",
            coords = vector3(-791.6490, -223.1951, 37.2414),
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
            coords = vector3(244.7903, -790.2971, 30.477),
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
            name = "Khu hái dừa",
            coords = vector3(-1850.456, -657.1502, 19.175859),
            radius = 100.0 -- bán kính 100 mét
        },

        {
            name = "Mechanic",
            coords = vector3(-355.3879, -126.1240, 38.0368),
            radius = 120.0 -- bán kính 100 mét
        },
        {
            name = "Khu hái cam",
            coords = vector3(-807.1800, 864.9300, 203.1542),
            radius = 75.0 -- bán kính 50 mét
        },
        {
            name = "LUXURY CARDEALER",
            coords = vector3(733.0587, -966.9283, 24.7018),
            radius = 60.0 -- bán kính 50 mét
        },

        -- Cây xăng (Gas Stations)
        {
            name = "Cây xăng Davis Avenue Ron",
            coords = vector3(167.06, -1553.56, 28.26),
            radius = 50.0
        },
        -- {
        --     name = "Cây xăng Grove Street LTD",
        --     coords = vector3(-40.94, -1751.7, 28.42),
        --     radius = 50.0
        -- },
        {
            name = "Cây xăng Dutch London Xero",
            coords = vector3(-531.2, -1220.83, 17.45),
            radius = 50.0
        },
        {
            name = "Cây xăng Little Seoul LTD",
            coords = vector3(-705.66, -905.04, 18.22),
            radius = 50.0
        },
        {
            name = "Cây xăng Strawberry Ave Xero (Tổng Kho)",
            coords = vector3(288.83, -1267.01, 28.44),
            radius = 50.0
        },
        {
            name = "Cây xăng Popular Street Ron",
            coords = vector3(816.42, -1040.51, 25.75),
            radius = 50.0
        },
        {
            name = "Cây xăng Capital Blvd Ron",
            coords = vector3(1211.13, -1389.18, 34.38),
            radius = 50.0
        },
        {
            name = "Cây xăng Mirror Park LTD",
            coords = vector3(1163.64, -314.21, 68.21),
            radius = 50.0
        },
        {
            name = "Cây xăng Clinton Ave Globe Oil",
            coords = vector3(642.08, 260.59, 102.3),
            radius = 50.0
        },
        {
            name = "Cây xăng North Rockford Ron",
            coords = vector3(-1428.4, -268.69, 45.21),
            radius = 50.0
        },
        {
            name = "Cây xăng Great Ocean Xero",
            coords = vector3(-2074.28, -327.22, 12.32),
            radius = 50.0
        },
        {
            name = "Cây xăng Paleto Blvd Xero",
            coords = vector3(-93.02, 6410.11, 30.64),
            radius = 50.0
        },
        {
            name = "Cây xăng Paleto Ron",
            coords = vector3(170.44, 6633.74, 30.59),
            radius = 50.0
        },
        {
            name = "Cây xăng Paleto Globe Oil",
            coords = vector3(1698.62, 6425.84, 31.76),
            radius = 50.0
        },
        {
            name = "Cây xăng Grapeseed LTD",
            coords = vector3(1704.59, 4917.5, 41.06),
            radius = 50.0
        },
        {
            name = "Cây xăng Sandy Shores Xero",
            coords = vector3(2001.33, 3779.87, 31.18),
            radius = 50.0
        },
        {
            name = "Cây xăng Sandy Shores Globe Oil",
            coords = vector3(1776.57, 3327.36, 40.43),
            radius = 50.0
        },
        {
            name = "Cây xăng Senora Freeway Xero",
            coords = vector3(2673.98, 3266.87, 54.24),
            radius = 50.0
        },
        {
            name = "Cây xăng Harmony Globe Oil",
            coords = vector3(1201.68, 2655.24, 36.85),
            radius = 50.0
        },
        {
            name = "Cây xăng Route 68 Globe Oil",
            coords = vector3(1039.44, 2664.37, 38.55),
            radius = 50.0
        },
        {
            name = "Cây xăng Route 68 Workshop Globe Oil",
            coords = vector3(265.89, 2598.3, 43.84),
            radius = 50.0
        },
        {
            name = "Cây xăng Route 68 Xero",
            coords = vector3(46.53, 2789.05, 56.88),
            radius = 50.0
        },
        {
            name = "Cây xăng Route 68 Ron",
            coords = vector3(-2544.04, 2316.15, 32.22),
            radius = 50.0
        },
        {
            name = "Cây xăng Rex's Diner Globe Oil",
            coords = vector3(2545.02, 2591.72, 36.96),
            radius = 50.0
        },
        {
            name = "Cây xăng Palmino Freeway Ron",
            coords = vector3(2559.36, 373.68, 107.62),
            radius = 50.0
        },
        {
            name = "Cây xăng North Rockford LTD",
            coords = vector3(-1825.33, 800.96, 137.1),
            radius = 50.0
        },
        {
            name = "Cây xăng Alta Street Globe Oil",
            coords = vector3(-342.37, -1482.97, 29.71),
            radius = 50.0
        },
        {
            name = "Quán Bar Sài Gòn Đà Nẵng",
            coords = vector3(381.4493, -342.4826, 47.4023),
            radius = 150.0
        }

        -- Có thể thêm nhiều khu vực khác tại đây
    },

    -- Các khu vực KHÔNG bị trừ điểm (PvP zone tự do - mọi hành động đều miễn phạt)
    noPenaltyZones = {
        -- {
        --     name = "Paleto Bay",
        --     coords = vector3(-905.63, 6665.9, 2.74),
        --     radius = 130.0 -- bán kính 130 mét
        -- },
        -- {
        --     name = "Chumash",
        --     coords = vector3(-2875.02, -463.39, 31.59),
        --     radius = 130.0 -- bán kính 130 mét
        -- }
        -- Có thể thêm nhiều khu vực PvP tự do khác tại đây
    },

    -- Điểm bị trừ
    penalties = {
        combatInForbiddenZone = -5, -- Trừ 3 điểm khi đánh người chơi trong khu vực cấm
        -- npcCombatInForbiddenZone = -2, -- ĐÃ TẮT: Không trừ điểm khi đánh NPC trong khu vực cấm nữa
        vehicleRamming = -20,       -- Trừ 10 điểm khi đâm xe vào người chơi (ÁP DỤNG Ở MỌI NƠI - KHÔNG GIỚI HẠN KHU VỰC)
        -- vehicleRammingNPC = -3, -- ĐÃ TẮT: Không trừ điểm khi đâm xe vào NPC nữa
        -- selfVehicleDamage = -2 -- ĐÃ TẮT: Không trừ điểm khi tự gây sát thương bằng xe nữa
    },

    -- Thời gian cooldown để tránh spam (giây)
    cooldown = {
        combat = 2, -- 2 giây cooldown cho combat
        ramming = 3 -- 3 giây cooldown cho ramming
    },

    -- Cấu hình phát hiện đâm xe
    vehicleRammingDetection = {
        minSpeed = 20,           -- Tốc độ tối thiểu để phát hiện (km/h)
        detectionDistance = 2.5, -- Khoảng cách phát hiện va chạm (mét)
        checkInterval = 100,     -- Kiểm tra mỗi bao nhiêu ms
        cooldownMs = 3000,       -- Cooldown giữa các lần phát hiện (ms)
        minDamage = 10,          -- Sát thương tối thiểu (> giá trị này) mới bị trừ uy tín
        logMinDamage = 2,        -- Sát thương tối thiểu (> giá trị này) mới chụp ảnh + gửi log CRM

        -- Các loại xe bị bỏ qua (không trừ điểm khi lái)
        -- Sử dụng tên model xe (string), ví dụ: 'dodo', 'lazer', 'hydra'
        ignoredVehicles = {
            'dodo', -- Máy bay Dodo
        }
    },

    -- Cấu hình phát hiện combat
    combatDetection = {
        checkInterval = 100, -- Kiểm tra mỗi bao nhiêu ms (không dùng nữa, sử dụng gameEventTriggered)
        cooldownMs = 5000    -- Cooldown giữa các lần phát hiện (ms)
    }
}

-- Cấu hình hệ thống tù liên bang
Config.PrisonSystem = {
    enabled = false,          --
    reputationThreshold = 50, -- Uy tín dưới mức này sẽ bị tù
    prisonTime = 10800,       -- Thời gian tù (giây) - 5 phút
    prisonBucket = 999,       -- Bucket riêng cho tù nhân
    checkInterval = 30,       -- Kiểm tra uy tín mỗi 30 giây

    -- Vị trí tù liên bang
    location = {
        center = vector3(1699.86, 2605.15, 45.56),      -- Tâm khu vực tù
        radius = 200,                                   -- Bán kính khu vực tù
        spawnPoint = vector3(1752.41, 2505.34, 45.56),  -- Điểm spawn khi bị tù
        releasePoint = vector3(1852.11, 2604.87, 45.67) -- Điểm được thả khi hết thời gian tù
    },

    -- NPC Quản giáo
    guardNpc = {
        enabled = true,
        model = `s_m_y_cop_01`,                   -- Model của NPC quản giáo
        coords = vector3(1753.88, 2502.49, 44.6), -- Vị trí NPC
        heading = 24.3,                           -- Hướng nhìn của NPC
        scenario = "WORLD_HUMAN_CLIPBOARD",       -- Animation cho NPC
        interactions = {
            checkTime = {
                icon = "fa-solid fa-clock",
                label = "Kiểm tra thời gian tù"
            },
            info = {
                icon = "fa-solid fa-info-circle",
                label = "Thông tin nhà tù"
            }
        }
    },

    -- Thông báo
    messages = {
        imprisoned = "Bạn đã bị tù liên bang do uy tín quá thấp! Thời gian: %s phút",
        released = "Bạn đã được thả khỏi tù liên bang!",
        escapeAttempt = "Cảnh báo: Bạn đang cố gắng trốn tù! Sẽ bị gia hạn thời gian tù.",
        timeRemaining = "Thời gian tù còn lại: %s"
    },

    -- Đồng phục tù nhân
    uniforms = {
        enabled = true, -- Bật tắt hệ thống thay đồ tù nhân
        ['male'] = {
            outfitData = {
                ['t-shirt'] = { item = 15, texture = 0 }, -- Áo thun
                ['torso2'] = { item = 146, texture = 7 }, -- Áo khoác tù nhân
                ['arms'] = { item = 0, texture = 0 },   -- Tay áo
                ['pants'] = { item = 7, texture = 15 }, -- Quần tù nhân
                ['shoes'] = { item = 5, texture = 0 },  -- Giày
            }
        },
        ['female'] = {
            outfitData = {
                ['t-shirt'] = { item = 3, texture = 0 }, -- Áo thun nữ
                ['torso2'] = { item = 38, texture = 3 }, -- Áo khoác tù nhân nữ
                ['arms'] = { item = 2, texture = 0 },  -- Tay áo nữ
                ['pants'] = { item = 0, texture = 0 }, -- Quần tù nhân nữ
                ['shoes'] = { item = 5, texture = 0 }, -- Giày nữ
            }
        },
    },

    -- Hệ thống nhặt rác giảm án
    trashCollection = {
        enabled = true,
        timeReduction = 60, -- Giảm 5 giây mỗi túi rác
        respawnDelay = 3,   -- Delay 3 giây trước khi tạo lại túi rác mới
        trashBin = {
            coords = vec3(1775.25, 2551.97, 45.56),
            heading = 92.97 - 180,
            blip = {
                sprite = 632,
                scale = 0.9,
                color = 6, -- Màu tím
                name = "Thùng rác tù"
            }
        },
        trashBags = {
            vector3(1708.22, 2543.72, 45.56),
            vector3(1713.44, 2548.81, 45.56),
            vector3(1721.17, 2544.8, 45.56),
            vector3(1721.24, 2535.16, 45.56),
            vector3(1731.48, 2531.37, 45.56),
            vector3(1734.79, 2539.42, 45.56),
            vector3(1735.71, 2547.14, 45.57),
            vector3(1742.87, 2543.8, 45.57),
            vector3(1749.57, 2543.77, 45.57),
            vector3(1749.34, 2553.23, 45.57)
        },
        bagModel = `hei_prop_heist_binbag`,
        binModel = `prop_dumpster_01a`,
        blipSprite = 365,
        interaction = {
            distance = 2.0,
            key = 38 -- E key
        }
    }
}

-- Cấu hình thông báo
Config.Notifications = {
    duration = 5000,
    position = 'top'
}
