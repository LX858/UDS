Config = Config or {}

Config.Logs = {
    enabled = true,
    webhooks = {
        tuning = 'https://discord.com/api/webhooks/1491094405002821774/vBMfhP-rWRcaIEK7lr6MGkrwQsKErpDc8D4kU9nWr_te5bPg7bs-FptFzsmRHxHxpMpW',
    },
    colors = {
        tuning = 3447003, -- Blue
    },
    
    -- Mapping loại độ xe
    tuningTypes = {
        ['Performance'] = 'Nâng cấp hiệu suất',
        ['Cosmetics'] = 'Phụ kiện ngoại thất',
        ['Lights'] = 'Đèn neon/Xenon',
        ['Neons'] = 'Đèn gầm',
        ['Xenons'] = 'Đèn Xenon',
        ['Extras'] = 'Phụ kiện thêm',
    },
    
    -- Mapping chi tiết item -> tên hiển thị
    itemLabels = {
        -- Lights Items
        ['neon_custom'] = 'Bóng đèn gầm',
        ['cosmetics'] = 'Đồ trang trí xe',
        ['neons_controller'] = 'Bộ điều khiển đèn',
        
        -- Performance Items
        ['engine_s'] = 'Động cơ cấp S',
        ['engine_a'] = 'Động cơ cấp A',
        ['engine_b'] = 'Động cơ cấp B',
        ['engine_c'] = 'Động cơ cấp C',
        ['engine_d'] = 'Động cơ cấp D',
        ['transmission_s'] = 'Hộp số cấp S',
        ['transmission_a'] = 'Hộp số cấp A',
        ['transmission_b'] = 'Hộp số cấp B',
        ['transmission_c'] = 'Hộp số cấp C',
        ['transmission_d'] = 'Hộp số cấp D',
        ['brake_s'] = 'Phanh cấp S',
        ['brake_a'] = 'Phanh cấp A',
        ['brake_b'] = 'Phanh cấp B',
        ['brake_c'] = 'Phanh cấp C',
        ['brake_d'] = 'Phanh cấp D',
        ['suspension_s'] = 'Giảm xóc cấp S',
        ['suspension_a'] = 'Giảm xóc cấp A',
        ['suspension_b'] = 'Giảm xóc cấp B',
        ['suspension_c'] = 'Giảm xóc cấp C',
        ['suspension_d'] = 'Giảm xóc cấp D',
        ['armour_s'] = 'Giáp xe cấp S',
        ['armour_a'] = 'Giáp xe cấp A',
        ['armour_b'] = 'Giáp xe cấp B',
        ['armour_c'] = 'Giáp xe cấp C',
        ['armour_d'] = 'Giáp xe cấp D',
        ['turbo_s'] = 'Turbo cấp S',
        ['turbo_a'] = 'Turbo cấp A',
        ['turbo_b'] = 'Turbo cấp B',
        ['turbo_c'] = 'Turbo cấp C',
        ['turbo_d'] = 'Turbo cấp D',
        
        -- Cosmetics Items
        ['mechspray'] = 'Sơn xe',
        ['chameleon_spray'] = 'Sơn Chameleon',
        ['car_wheel'] = 'Mâm xe',
        ['spoiler'] = 'Cánh gió',
        ['front_bumper'] = 'Cản trước',
        ['rear_bumper'] = 'Cản sau',
        ['skirtcar'] = 'Ốp hông',
        ['exhaust'] = 'Ống xả',
        ['car_hood'] = 'Nắp capo',
        ['horn'] = 'Còi xe',
        ['internals'] = 'Phụ kiện nội thất',
        ['seats'] = 'Ghế xe',
        ['engine_block'] = 'Khối động cơ',
        ['vanity_plate'] = 'Biển số trang trí',
        ['livery'] = 'Tem dán',
        ['cosmetics'] = 'Phụ kiện xe',
        
        -- Lights & Extras
        ['neons_controller'] = 'Điều khiển đèn neon',
        ['extras_controller'] = 'Điều khiển phụ kiện',
    }
}