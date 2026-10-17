Config = {}
Config.ThoiGianThanh = 80000
Config.CooldownThanhCong = 3 -- Phút
Config.TimeoutAuto = 180 -- Giây - Tự động reset nếu stuck
Config.Cops = 3
Config.Xa_Beng = 'xa_beng'
-- Config.event = false

-- Vị trí bán nap_cong
Config.ViTriBan = {
    coords = vec4(-658.29, -557.57, 25.25, 56.87),
    minPrice = 3000,
    maxPrice = 6000
}

Config.Event = {
    enabled = true, -- Bật/tắt hệ thống phần thưởng đặc biệt
    chance = 3, -- Tỉ lệ % ra phần thưởng đặc biệt (10 = 10%)
    rewards = {
        {item = "banvevukhi", chance = 70}, -- 25% nhận manhgep1
        {item = "the_sieu_trom", chance = 30}, -- Thẻ Siêu trộm

    }
}