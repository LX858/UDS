Config = {}

-- Cấu hình database
Config.Database = {
    tableName = 'stall_system',
    transactionsTable = 'stall_transactions'
}

-- Cấu hình admin groups
Config.AdminGroups = {
    'admin',
    'mod',
    'owner'
}

-- Cấu hình gian hàng - SỬ DỤNG MẢNG
Config.Stalls = {
    {
        id = 1,
        name = "Gian hàng 1",
        position = vector3(451.7950, -799.9730, 27.4949),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(451.7950, -799.9730, 27.4949, 265.8806),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 2,
        name = "Gian hàng 2",
        position = vector3(462.9391, -793.4408, 27.3578),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(462.9391, -793.4408, 27.3578, 93.8200),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 3,
        name = "Gian hàng 3",
        position = vector3(462.9587, -786.4391, 27.3578),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(462.9587, -786.4391, 27.3578, 90.3905),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 4,
        name = "Gian hàng 4",
        position = vector3(460.9468, -777.2457, 27.3578),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(460.9468, -777.2457, 27.3578, 93.7448),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 5,
        name = "Gian hàng 5",
        position = vector3(452.1610, -774.2493, 27.3578),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(452.1610, -774.2493, 27.3578, 273.2032),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 6,
        name = "Gian hàng 6",
        position = vector3(460.4636, -769.3743, 27.3578),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(460.4636, -769.3743, 27.3578, 89.5613),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 7,
        name = "Gian hàng 7",
        position = vector3(461.8863, -751.9375, 27.3579),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(461.8863, -751.9375, 27.3579, 94.0121),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 8,
        name = "Gian hàng 8",
        position = vector3(451.5759, -738.0474, 27.3576),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(451.5759, -738.0474, 27.3576, 269.5275),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 9,
        name = "Gian hàng 9",
        position = vector3(451.1514, -724.2696, 27.3591),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(451.1514, -724.2696, 27.3591, 272.7935),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 10,
        name = "Gian hàng 10",
        position = vector3(451.2964, -711.4128, 27.3591),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(451.2964, -711.4128, 27.3591, 272.0943),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 11,
        name = "Gian hàng 11",
        position = vector3(451.2516, -738.1647, 27.3576),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(451.2516, -738.1647, 27.3576, 245.5612),
        rentPrice = 499,
        maxHours = 24
    },
    {
        id = 12,
        name = "Gian hàng 12",
        position = vector3(451.6213, -730.7295, 27.3576),
        npcModel = "a_m_m_business_01",
        npcPosition = vector4(451.6213, -730.7295, 27.3576, 276.0722),
        rentPrice = 499,
        maxHours = 24
    }
}

-- Cấu hình chung
Config.MaxStalls = 1
Config.TaxRate = 0.02
Config.MaxSlots = 50
Config.DisplayDistance = 20.0

-- Cấu hình độ hiếm
Config.Rarity = {
    common = {
        label = "Thường",
        color = "#9d9d9d",
        glow = "none"
    },
    uncommon = {
        label = "Không phổ biến",
        color = "#1eff00",
        glow = "0 0 5px #1eff00"
    },
    rare = {
        label = "Hiếm",
        color = "#0070dd",
        glow = "0 0 8px #0070dd"
    },
    epic = {
        label = "Sử thi",
        color = "#a335ee",
        glow = "0 0 10px #a335ee"
    },
    legendary = {
        label = "Huyền thoại",
        color = "#ff8000",
        glow = "0 0 12px #ff8000"
    }
}

-- Cấu hình Blip cho vị trí gian hàng
Config.Blip = {
    enabled = true,
    coords = vector3(451.7950, -799.9730, 27.4949), -- Tọa độ khu vực gian hàng
    sprite = 52, -- Ký hiệu Store (Chợ/Cửa hàng)
    color = 2, -- Màu xanh lá cây
    scale = 0.8,
    label = "Khu Vực Gian Hàng"
}

-- Cấu hình danh sách vật phẩm cấm (Không hiển thị ở UI túi đồ và không cho phép đăng bán)
Config.BlacklistItems = {
    ['money'] = true,        -- Tiền mặt / Sạch
    ['black_money'] = true,  -- Tiền bẩn
    ['markedbills'] = true,  -- Tiền bẩn túi
    ['crypto'] = true,       -- Tiền ảo
    ['thedoithongtin'] = true,       -- Thẻ thông tin
    -- Thêm các vật phẩm khác vào đây theo mẫu: ['tên_item'] = true
}

-- Cấu hình Discord Webhook để log khi gian hàng hết hạn (để trống nếu không dùng)
Config.DiscordWebhook = "https://discord.com/api/webhooks/1528586525632102452/z7_33tByIuEEI3y2cgfcDQgabN_nenf_hAQBSExfrh3K5bWjj1uBmOyPyhLFZ9CSb6up"

-- Cấu hình Discord Webhook để log khi người chơi đăng bán vật phẩm (để trống nếu không dùng)
Config.AddItemWebhook = "https://discord.com/api/webhooks/1528585891399077899/Ap8vEByt3bADbbPMUpHjTXydzMVlpgw40CiTT_k07sjJ4lsPbuEny1nAMzd2UE6BvA-R"