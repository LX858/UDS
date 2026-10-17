Config = {}

-- Cấu hình chung
Config.RepairItem = 'repair_kit' -- Tên item cần thiết để sửa xe
Config.DepartmentRepairItem = 'vesuaxenghanh' -- Item sửa xe cho ban ngành
Config.ProgressDuration = math.random(5000, 7000) -- Thời gian sửa xe (5-7 giây)
Config.MiniGameKeys = {'1', '2', '3'} -- Phím cần bấm trong mini game
Config.RepairDistance = 5.0 -- Khoảng cách tối đa để sửa xe

-- Cấu hình engine bone (bao gồm bone cho xe xăng và xe điện)
Config.EngineBones = {
    'bonnet',
    'engine',
    'engine_1',
    'engine_2',
    'motor',
    'boot',
    'chassis',
    'chassis_dummy'
}

-- Xe được phép sửa bởi ban ngành khi mechanic offline
Config.DepartmentVehicles = {
    
    ['amrfreightliner'] = {job = 'ambulance', grade = 0},
    ['a16fpiuamr'] = {job = 'ambulance', grade = 2},
    ['e63amgmedic'] = {job = 'ambulance', grade = 0},
    
    ['dc_mdoracle'] = {job = 'ambulance', grade = 0},
    ['shuttlebus'] = {job = 'ambulance', grade = 1},
    ['dc_mdbuffalo'] = {job = 'ambulance', grade = 6},
    ['dc_mdg4m82'] = {job = 'ambulance', grade = 8},
    ['energym3g80med'] = {job = 'ambulance', grade = 1},
    ['energyvanmed'] = {job = 'ambulance', grade = 0},
    ['energygs1200med'] = {job = 'ambulance', grade = 2},
    ['energyx7med'] = {job = 'ambulance', grade = 5},
    ['polpor'] = {job = 'ambulance', grade = 7},

    ['nkfugivitve'] = {job = 'police', grade = 0},
    ['lapdr1200'] = {job = 'police', grade = 1},
    ['bmwrp'] = {job = 'police', grade = 1},
    ['nkdoradoac'] = {job = 'police', grade = 2},
    ['nkbuffalo4'] = {job = 'police', grade = 1},
    ['nkgtx'] = {job = 'police', grade = 4},
    ['nkvigero2'] = {job = 'police', grade = 7},
    ['polcoq4'] = {job = 'police', grade = 10},
}

-- Job được phép sử dụng tính năng sửa xe ban ngành
Config.AllowedDepartments = {
    'ambulance',
    'police'
}

-- Thông báo
Config.Locale = {
    ['no_repairkit'] = 'Bạn không có repair kit!',
    ['no_department_item'] = 'Bạn không có vé sửa xe ngành!',
    ['vehicle_not_found'] = 'Không tìm thấy xe!',
    ['too_far'] = 'Bạn quá xa xe!',
    ['repairing'] = 'Đang sửa xe...',
    ['repair_success'] = 'Sửa xe thành công!',
    ['repair_cancelled'] = 'Hủy sửa xe!',
    ['minigame_instruction'] = 'Bấm các phím theo thứ tự: 1, 2, 3',
    ['minigame_failed'] = 'Mini game thất bại!',
    ['minigame_success'] = 'Mini game thành công!',
    ['mechanic_online'] = 'Có thợ sửa xe đang online, vui lòng liên hệ thợ!',
    ['not_department_vehicle'] = 'Xe này không thuộc ban ngành của bạn!',
    ['not_allowed_job'] = 'Bạn không có quyền sử dụng tính năng này!',
    ['grade_not_enough'] = 'Cấp bậc của bạn không đủ để sửa xe này!'
}
