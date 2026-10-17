Config = {}

-- General Settings
Config.ServerName = "UNDER STAR ROLEPLAY"
Config.AutoOpenOnJoin = true -- Tự động hiện bảng tin khi player vừa load vào máy chủ
Config.CommandName = "capnhap" -- Lệnh xem cập nhật: /newupdate (hoặc /updates)

-- Qbox / QB Admin Groups allowed to post/delete updates
Config.AdminGroups = {
    ['god'] = true,
    ['admin'] = true,
    ['mod'] = true
}

-- Categories configuration for filter & badge tags
Config.Categories = {
    { id = 'all', label = 'Tất cả' },
    { id = 'feature', label = 'Tính năng mới', badgeClass = 'badge-feature' },
    { id = 'fix', label = 'Sửa lỗi', badgeClass = 'badge-fix' },
    { id = 'update', label = 'Cập nhật hệ thống', badgeClass = 'badge-update' },
    { id = 'event', label = 'Sự kiện', badgeClass = 'badge-event' }
}

-- Default fallback sample update in case DB table is empty
Config.DefaultUpdates = {
    {
        id = 1,
        title = "Chào mừng tới UNDER STAR ROLEPLAY!",
        category = "update",
        categoryLabel = "Cập nhật hệ thống",
        version = "v1.0.0",
        author = "BQL UnderStar",
        date = "08/08/2026",
        content = "Chào mừng tất cả cư dân đến với thành phố UnderStar Roleplay!\n\n✨ Hệ thống đã sẵn sàng với nhiều tính năng hấp dẫn:\n• Giao diện Cyan Neon sắc nét, tối ưu hiệu năng tối đa.\n• Hệ thống Paintball, Đua xe, Casino, Bắn súng nảy lửa.\n• Quản lý tài sản, nhà cửa và phương tiện đa dạng.\n\nNhấn nút **ĐÃ ĐỌC** ở phía dưới để vào thành phố trải nghiệm ngay!"
    }
}
