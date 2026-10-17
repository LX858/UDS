Config = {}

-- Cấu hình job có quyền sử dụng
-- Lưu ý: Đối với QBCore, player cần phải onduty mới được sử dụng
Config.AllowedJobs = {
    'police',
    'sheriff',
    'statepolice'
}

-- Cấu hình ox_target
Config.TargetOptions = {
    distance = 2.5,
    icon = 'fas fa-search',
    label = 'Kiểm tra thông tin xe'
}

-- Cấu hình tính năng xóa xe
Config.DeleteVehicleOptions = {
    distance = 3.0,
    icon = 'fas fa-trash',
    label = 'Xóa xe'
}

-- Cấu hình tính năng mở khóa cửa xe
Config.UnlockVehicleOptions = {
    distance = 2.5,
    icon = 'fas fa-unlock',
    label = 'Mở khóa cửa xe'
}

-- Cấu hình thông tin xe mặc định (có thể lấy từ database)
Config.VehicleInfo = {
    -- Ví dụ dữ liệu xe với biển số phổ biến hơn
    ['ABC123'] = {
        owner = 'Nguyễn Văn A',
        plate = 'ABC123',
        status = 'Bình thường',
        model = 'Sultan',
        color = 'Đỏ',
        registration_date = '2023-01-15'
    },
    ['XYZ456'] = {
        owner = 'Trần Thị B',
        plate = 'XYZ456',
        status = 'Bị truy nã',
        model = 'Adder',
        color = 'Xanh',
        registration_date = '2022-05-20'
    },
    ['DEF789'] = {
        owner = 'Lê Văn C',
        plate = 'DEF789',
        status = 'Bị đánh cắp',
        model = 'Zentorno',
        color = 'Đen',
        registration_date = '2023-03-10'
    },
    -- Thêm một số biển số thường gặp để test
    ['88888888'] = {
        owner = 'Phạm Văn Test',
        plate = '88888888',
        status = 'Bình thường',
        model = 'Turismo',
        color = 'Vàng',
        registration_date = '2024-01-01'
    },
    ['12345678'] = {
        owner = 'Hoàng Thị Demo',
        plate = '12345678',
        status = 'Bình thường',
        model = 'Infernus',
        color = 'Đỏ',
        registration_date = '2024-02-15'
    }
}

-- Cấu hình Police Box Items
Config.PoliceBox = {
    -- Tên vật phẩm của hộp
    itemName = 'box_police',
    
    -- Các vật phẩm sẽ nhận được khi mở hộp
    items = {
        { name = 'weapon_stungun', amount = 1 },
        { name = 'weapon_nightstick', amount = 1 },
        { name = 'handcuffs', amount = 1 }
    }
}