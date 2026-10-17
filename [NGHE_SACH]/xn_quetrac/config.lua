Config = {}

-- Vị trí mua chổi & nhận nhiệm vụ
Config.BroomShop = {
    coords = vec4(165.9803, -946.2493, 31.9209, 69.4718),
    price = 500, -- Giá mua chổi
    label = "Dọn rác"
}

-- Vị trí các điểm rác
Config.TrashLocations = {
    vec3(214.3169, -907.6649, 29.5),
    vec3(209.6722, -919.1863, 29.5),
    vec3(203.8359, -936.8240, 29.5),
    vec3(196.6365, -955.2106, 29.5),
    vec3(189.2518, -974.5894, 29.5),
    vec3(172.0402, -969.6479, 29.5),
    vec3(174.6862, -962.2634, 29.5),
    vec3(180.1906, -945.5482, 29.5),
    vec3(188.9491, -920.8000, 29.5),
    vec3(196.8759, -900.6779, 29.5)
}

-- Prop settings
Config.TrashProp = {
    model = 'prop_rub_litter_03',
    zOffset = -0.5 -- Điều chỉnh độ cao prop
}

-- Draw text settings
Config.DrawDistance = 2.5 -- Khoảng cách hiển thị text
Config.InteractDistance = 1.5 -- Khoảng cách tương tác

-- Vị trí xử lý rác
Config.RecycleLocation = {
    coords = vec3(125.1, -1180.61, 28.85),
    label = "Khu Xử Lý Rác"
}

-- Thời gian thực hiện
Config.TrashCollectTime = 10000 -- 10 giây
Config.RecycleTime = 15000 -- 15 giây

-- Phần thưởng
Config.Rewards = {
    recyclePlastic = {
        item = "racthaidaphanloai", -- Đảm bảo item này tồn tại trong ox_inventory/data/items.lua
        label = "Nhựa Tái Chế",
        amount = 1 -- Mặc định 1 nhựa tái chế
    }
}

-- Items
Config.Items = {
    broom = "dohotrac", -- Tên item chổi
    trash = "racthai" -- Tên item rác
}

-- Mission settings
Config.MissionEnabled = true -- Bật/tắt hệ thống nhiệm vụ

-- Blip settings
Config.ShowBlips = true
Config.Blips = {
    shop = {
        sprite = 102,
        color = 2,
        scale = 0.8,
        label = "~g~[XÁM HỐI]~s~ Dọn rác"
    },
    recycle = {
        sprite = 467,
        color = 25,
        scale = 0.8,
        label = "~g~[CÔNG XƯỞNG]~s~ Khu xử lý rác"
    },
    mission = {
        sprite = 1,
        color = 5,
        scale = 0.8,
        label = "Vị Trí Dọn Dẹp"
    }
}

Config.Event = {
    enabled = false, -- Bật/tắt hệ thống phần thưởng đặc biệt
    chance = 3, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
    rewards = {
        {item = "banvevukhi1", chance = 30}, -- 25% nhận manhghep1
        {item = "banvevukhi2", chance = 30}, -- 25% nhận manhghep2 (50% tích lũy)
        {item = "banvevukhi3", chance = 10}, -- 25% nhận manhghep4 (75% tích lũy)
        {item = "banvevukhi4", chance = 30}  -- 25% nhận manhghep5 (100% tích lũy)
    }
}
