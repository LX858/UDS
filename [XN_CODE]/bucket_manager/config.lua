Config = {}

-- Cấu hình thông báo
Config.Notifications = {
    Duration = 5000, -- Thời gian hiển thị thông báo (ms)
    Position = 'top-right' -- Vị trí hiển thị thông báo
}

-- Cấu hình quyền
Config.Permissions = {
    AdminCommand = 'admin' -- Quyền cần thiết để sử dụng lệnh /setbucket
}

-- Cấu hình bucket
Config.Bucket = {
    DefaultBucket = 0, -- Bucket mặc định khi reset
    MaxBucket = 63 -- Bucket tối đa (FiveM giới hạn 0-63)
}

-- Cấu hình log
Config.Logging = {
    EnableConsoleLog = true, -- Bật/tắt log console
    LogBucketCheck = true, -- Log khi kiểm tra bucket
    LogBucketReset = true, -- Log khi reset bucket
    LogBucketSet = true -- Log khi admin set bucket
}

-- Tin nhắn
Config.Messages = {
    BucketCheck = 'Bucket hiện tại của bạn: %s',
    BucketReset = 'Đã reset bucket từ %s về %s',
    BucketSet = 'Đã set bucket %s cho %s',
    BucketSetReceived = 'Admin đã chuyển bạn đến bucket: %s',
    NoPermission = 'Bạn không có quyền sử dụng lệnh này!',
    PlayerNotFound = 'Không tìm thấy player với ID: %s',
    InvalidUsage = 'Sử dụng: /setbucket [player_id] [bucket_id]',
    InvalidBucket = 'Bucket ID phải từ 0 đến %s'
}
