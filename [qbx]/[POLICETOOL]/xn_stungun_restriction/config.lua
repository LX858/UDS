Config = {}

-- Danh sách vũ khí bị cấm (định dạng đúng cho ox_inventory)
Config.RestrictedWeapons = {
    'WEAPON_STUNGUN',
    'WEAPON_NIGHTSTICK'
}

-- Các nghề được phép sử dụng vũ khí cảnh sát
Config.AllowedJobs = {
    'police',
    'sheriff', 
    'state',
    'fbi'
}

-- Thông báo
Config.Messages = {
    restricted = 'Bạn không có quyền sử dụng vũ khí này! Chỉ lực lượng cảnh sát đang onduty mới được phép sử dụng.'
}