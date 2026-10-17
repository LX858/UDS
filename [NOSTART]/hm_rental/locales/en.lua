Locale = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- CHUNG
-- ═══════════════════════════════════════════════════════════════════════════

Locale.general = {
    press_to_interact = '[E] Tương tác',
    loading = 'Đang tải...',
    processing = 'Đang xử lý...',
    cancel = 'Hủy',
    confirm = 'Xác nhận',
    close = 'Đóng',
    back = 'Quay lại',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- THÔNG BÁO
-- ═══════════════════════════════════════════════════════════════════════════

Locale.notify = {
    -- Thành công
    rental_success = 'Bạn đã thuê %s với giá $%s!',
    rental_success_deposit = 'Bạn đã thuê %s! Tiền cọc: $%s',
    return_success = 'Đã trả xe! Hoàn lại tiền cọc: $%s',
    return_success_no_deposit = 'Đã trả xe thành công!',
    return_with_fee = 'Đã trả xe! Phí thuê: $%s',
    
    -- Lỗi
    not_enough_money = 'Không đủ tiền! Cần: $%s',
    already_renting = 'Bạn đang có một phương tiện thuê rồi!',
    no_vehicle_rented = 'Bạn chưa thuê phương tiện nào!',
    not_rental_vehicle = 'Đây không phải là phương tiện thuê!',
    too_far_from_station = 'Bạn ở quá xa trạm thuê xe!',
    vehicle_not_found = 'Không tìm thấy phương tiện!',
    spawn_failed = 'Không thể tạo phương tiện!',
    invalid_vehicle_type = 'Loại phương tiện không hợp lệ!',
    cooldown_active = 'Vui lòng chờ %s giây trước khi thuê tiếp!',
    rate_limit = 'Quá nhiều yêu cầu! Vui lòng chờ một chút.',
    deposit_lost = 'Mất tiền cọc: $%s (Phương tiện không được trả tại trạm)',
    
    -- Thông tin
    no_vehicles_available = 'Không có phương tiện khả dụng',
    
    -- Khóa/Mở khóa phương tiện
    vehicle_locked = 'Đã khóa phương tiện',
    vehicle_unlocked = 'Đã mở khóa phương tiện',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- MENU
-- ═══════════════════════════════════════════════════════════════════════════

Locale.menu = {
    -- Menu chính
    title = 'Thuê Phương Tiện',
    subtitle = 'Chọn phương tiện muốn thuê',
    
    -- Chọn phương tiện
    select_vehicle = 'Chọn Phương Tiện',
    rent_now = 'Thuê Ngay',
    rental_fee = 'Phí Thuê',
    deposit = 'Tiền Cọc',
    total_cost = 'Tổng Chi Phí',
    per_minute = 'mỗi phút',
    one_time = 'Một lần',
    available = 'Khả dụng',
    rented = 'Đã thuê',
    
    -- Trả xe
    return_title = 'Trả Phương Tiện?',
    return_text = 'Bạn có muốn trả phương tiện này không?',
    return_deposit_info = 'Bạn sẽ được hoàn lại tiền cọc $%s.',
    return_fee_info = 'Phí thuê: $%s',
    
    -- Thông tin thuê hiện tại
    rental_info_title = 'Đang Thuê',
    rental_info_vehicle = 'Phương tiện: %s',
    rental_info_time = 'Thời gian thuê: %s phút',
    rental_info_cost = 'Chi phí hiện tại: $%s',
    rental_info_deposit = 'Tiền cọc: $%s',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- THUÊ XE / TRẠM
-- ═══════════════════════════════════════════════════════════════════════════

Locale.rental = {
    open_station = 'Thuê Phương Tiện',
    return_vehicle = 'Trả Phương Tiện',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- PHƯƠNG TIỆN
-- ═══════════════════════════════════════════════════════════════════════════

Locale.vehicles = {
    -- Xe đạp
    bicycle = {
        name = 'Xe Đạp',
        desc = 'Xe đạp tiêu chuẩn',
    },
    mountainbike = {
        name = 'Xe Đạp Địa Hình',
        desc = 'Xe đạp địa hình bền bỉ',
    },
    racer = {
        name = 'Xe Đạp Đua',
        desc = 'Xe đạp đua tốc độ cao',
    },
    
    -- Xe scooter
    scooter = {
        name = 'Xe Điện Scooter',
        desc = 'Xe scooter điện',
    },
    sport_scooter = {
        name = 'Scooter Thể Thao',
        desc = 'Xe scooter thể thao tốc độ cao',
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- LỆNH ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

Locale.commands = {
    -- Thống kê
    stats = 'Thống Kê Thuê Xe',
    total_rentals = 'Tổng lượt thuê: %s',
    active_rentals = 'Đang thuê: %s',
    total_revenue = 'Tổng doanh thu: $%s',
    
    -- Quản lý trạm
    spawned_station = 'Đã tạo trạm thuê xe: %s',
    removed_station = 'Đã xóa trạm thuê xe: %s',
    no_station = 'Không tìm thấy trạm nào gần đây!',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- BLIPS
-- ═══════════════════════════════════════════════════════════════════════════

Locale.blips = {
    rental = 'Thuê Phương Tiện',
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ĐỊNH DẠNG THỜI GIAN
-- ═══════════════════════════════════════════════════════════════════════════

Locale.time = {
    minutes_short = 'phút',
    seconds_short = 'giây',
}

return Locale