Config = {}

-- Vị trí kho cá nhân
Config.StorageLocation = vec3(-1082.57, -247.0, 37.81)

-- Cấu hình kho
Config.Storage = {
    slots = 500,        -- 500 slot
    weight = 10000000   -- 10.000kg (10,000,000 grams)
}

-- Phí lấy đồ từ kho
Config.WithdrawalFee = {
    enabled = true,     -- Bật/tắt phí lấy đồ
    amount = 1000,       -- Số tiền phí (VD: 100 = $100)
    perItem = true      -- true = tính phí theo item, false = phí cố định mỗi lần mở kho
}

-- Cấu hình target
Config.Target = {
    distance = 2.5,     -- Khoảng cách tương tác
    icon = 'fas fa-box-open',
    label = 'Mở bưu cục'
}

-- Debug mode
Config.Debug = false