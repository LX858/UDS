Config = {}

-- NPC Configuration
Config.NPCLocations = {
    vec4(596.04, -457.02, 24.74, 358.42),
    vec4(124.1902, -574.3678, 18.8079, 151.3327),
    vec4(-1497.0831, -317.9692, 46.9419, 205.2950)
    -- Bạn có thể thêm nhiều vị trí khác tại đây
}
Config.RandomNPCLocation = true -- true: chỉ chọn ngẫu nhiên 1 vị trí trong danh sách để spawn, false: spawn tại tất cả các vị trí
Config.ChangeNPCLocationOnRefresh = true -- true: thay đổi vị trí NPC mỗi khi làm mới vật phẩm/giá, false: giữ nguyên vị trí cho đến khi restart hoặc đóng cửa
Config.NPCLocation = vec4(596.04, -457.02, 24.74, 358.42) -- Vị trí NPC mặc định (fallback)
Config.NPCModel = 'g_m_y_lost_01' -- Model của NPC
Config.NPCName = 'Dealer Vật Phẩm Đen'

-- Shop Configuration
Config.CurrencyItem = 'money' -- Tên item tiền bẩn trong database
Config.CurrencyLabel = 'Tiền sạch'
Config.MaxPurchaseQuantity = 3 -- Giới hạn số lượng tối đa mỗi lần mua
Config.RefreshItemAfterPurchase = true -- Làm mới vật phẩm sau khi mua

-- Items for sale
Config.Items = {
    {
        item = 'xa_beng',
        label = 'Xa Beng',
        description = 'Vật phẩm nguy hiểm',
        minPrice = 500,
        maxPrice = 2000,
        icon = 'fas fa-skull'
    },
    {
        item = 'xichcho',
        label = 'Xích Chó',
        description = 'Vật phẩm nguy hiểm',
        minPrice = 500,
        maxPrice = 2000,
        icon = 'fas fa-skull'
    },
    {
        item = 'saubenh',
        label = 'Sâu Bệnh',
        description = 'Dùng để thả sâu bệnh cây trồng',
        minPrice = 100,
        maxPrice = 300,
        icon = 'fas fa-skull'
    }
}

-- Random item selection
Config.RandomItemSelection = {
    enabled = false, -- Bật chế độ ngẫu nhiên chọn 1 vật phẩm (đã tắt để bán tất cả cùng lúc)
    refreshInterval = 300000 -- 5 phút - thời gian thay đổi vật phẩm
}

-- Price refresh interval (in milliseconds)
Config.PriceRefreshInterval = 300000 -- 5 phút

-- Time restrictions (24-hour format)
Config.TimeRestrictions = {
    enabled = true,
    startHour = 21, -- 21:00 (9:00 PM)
    endHour = 4     -- 04:00 (4:00 AM)
}

-- Language
Config.Lang = {
    ['npc_label'] = 'Mua vật phẩm',
    ['shop_title'] = 'Chợ Đen - Vật Phẩm Bất Hợp Pháp',
    ['buy_item'] = 'Mua %s',
    ['price_info'] = 'Giá: %d %s',
    ['quantity_input'] = 'Nhập số lượng',
    ['quantity_placeholder'] = 'Số lượng...',
    ['confirm_purchase'] = 'Xác nhận mua %d x %s với giá %d %s?',
    ['purchase_success'] = 'Đã mua thành công %d x %s với giá %d %s',
    ['not_enough_money'] = 'Bạn không có đủ %s để mua vật phẩm này',
    ['invalid_quantity'] = 'Số lượng không hợp lệ',
    ['max_quantity_exceeded'] = 'Bạn chỉ được mua tối đa %d vật phẩm mỗi lần',
    ['inventory_full'] = 'Túi đồ đã đầy',
    ['purchase_cancelled'] = 'Đã hủy giao dịch',
    ['npc_not_available'] = 'Dealer chỉ hoạt động từ 19:00 đến 04:00',
    ['time_restriction'] = 'Chợ đen chỉ mở cửa vào ban đêm (19:00 - 04:00)',
    ['item_changed'] = 'Dealer đã thay đổi hàng hóa!',
    ['no_items_available'] = 'Hiện tại không có vật phẩm nào để bán'
}
