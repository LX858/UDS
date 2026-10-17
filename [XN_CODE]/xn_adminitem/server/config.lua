Config = {}

-- Danh sách license được phép LẤY vật phẩm (mod/admin)
Config.AllowedGetLicenses = {
    ["license:e6104924-2135-4de0-a446-51d929799ad3"] = true, -- demo license
    ["license:e413f60d-1dec-42df-998f-50945a6f080b"] = true, -- demo license
    ["license:a17d2435-8433-4c2c-8650-1fe1509e2cab"] = true, -- demo license
    -- Thêm các license khác ở dưới dạng: ["license:xxx"] = true,
}

-- Danh sách license được phép CHỈNH SỬA giới hạn hàng ngày của item
Config.AllowedEditLicenses = {
    ["license:4718a60e-86b0-44c6-b6e3-4e4e279a978d"] = true, -- demo license
    ["license:dec537b0-c953-4eb3-a3db-a876a4e7cb58"] = true, -- demo license
    ["license:a17d2435-8433-4c2c-8650-1fe1509e2cab"] = true, -- demo license
    -- Thêm các license khác ở dưới dạng: ["license:xxx"] = true,
}

-- Giới hạn lấy vật phẩm hàng ngày mặc định cho mỗi loại item
Config.DefaultLimit = 100

-- Webhook Discord để ghi log khi lấy vật phẩm
Config.Webhook = "https://discord.com/api/webhooks/1529551592016052325/dDMtx0h-7pp_wTZi0GoHBgFqAUhpp-ngT3Ba2TJF37ZSsWljXGQKUyoY3aFDDH5ixBRy"

