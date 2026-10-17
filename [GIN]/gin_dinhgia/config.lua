Config = {}

-- Coordinates cho bàn quy đổi (x, y, z, heading)
Config.Location = vector4(-459.2957, -2646.7876, 8.7611, 45.6807)

-- Cấu hình spawn prop cái bàn
Config.SpawnProp = true
Config.PropModel = `bkr_prop_coke_table01a` -- Model cái bàn (hoặc `prop_table_01`, `bkr_prop_clubhouse_table_01`)

-- Zone đỏ hiển thị tại vị trí bàn quy đổi (Tắt drawMarker = false giúp Resmon 0.00ms tuyệt đối)
Config.Zone = {
    drawMarker = false, -- false: Tắt vòng tròn đỏ (đã có cái Bàn Prop & ox_target) để Resmon 0.00ms, true: Bật vòng đỏ
    markerType = 1, -- Cylinder marker
    radius = 1.8,
    height = 0.6,
    color = { r = 220, g = 38, b = 38, a = 140 } -- Zone màu đỏ
}

-- Cấu hình Blip và Vùng đỏ trên bản đồ (Map & Minimap)
Config.Blip = {
    enabled = true,
    sprite = 500, -- Icon Blip (500: Thỏi vàng, 478: Tiền vàng, 431: Túi tiền)
    display = 4,
    scale = 0.8,
    color = 1, -- Màu đỏ (Red blip)
    name = 'Bàn Định Giá & Quy Đổi Vật Phẩm',
    
    -- Vùng đỏ trên bản đồ mini/map (Radius Blip)
    showRadius = true,
    radius = 100.0, -- Bán kính vùng đỏ trên bản đồ
    radiusColor = 1, -- Màu đỏ
    radiusAlpha = 120 -- Độ mờ của vùng đỏ
}

-- ==============================================================================
-- CẤU HÌNH KHUNG THỜI GIAN HOẠT ĐỘNG (ĐỒNG BỘ THEO GIỜ MÁY CHỦ REAL-TIME)
-- Tối ưu hóa 100%, không dùng vòng lặp, kiểm tra sự kiện trực tiếp khi người chơi tương tác
-- ==============================================================================
Config.TimeRestrictions = {
    enabled = true, -- true: Bật giới hạn thời gian, false: Mở 24/7 không giới hạn
    timezoneOffset = nil , --7 -- Múi giờ UTC+7 (Việt Nam). Đặt nil nếu muốn lấy trực tiếp giờ của hệ điều hành máy chủ

    -- Khung giờ 1: Định giá (Từ 14h00 đến 15h00)
    -- Người chơi chỉ được xem bảng giá, đặt đồ vào ô để kiểm tra giá trị, KHÔNG ĐƯỢC RỬA/QUY ĐỔI TIỀN
    appraisal = {
        startHour = 12,
        startMinute = 30,
        endHour = 14,
        endMinute = 30,
        label = '12:30 - 14:30'
    },

    -- Khung giờ 2: Rửa đồ (Từ 20h00 đến 23h00)
    -- Cho phép người chơi đặt đồ và bấm XÁC NHẬN QUY ĐỔI để nhận tiền mặt
    washing = {
        startHour = 21,
        startMinute = 45,
        endHour = 23,
        endMinute = 45,
        label = '21:45 - 23:45'
    },

    -- Thông báo khi người chơi tương tác ngoài khung giờ
    messages = {
        closed = "Bàn hiện đang đóng cửa!\n- Khung giờ: %s\n- Khung giờ: %s",
        appraisalOnly = "Hiện tại là khung giờ Định Giá (%s)!\nBạn chỉ có thể xem giá trị vật phẩm, khung giờ Rửa tiền là: %s.",
        outsideWash = "Hiện không phải khung giờ Rửa đồ (%s)! Vui lòng quay lại sau."
    }
}


-- Cấu hình hành động (Animation) nhân vật khi đang tiến hành quy đổi
Config.Animation = {
    enabled = true,
    dict = "anim@gangops@morgue@table@", -- Động tác 2 tay mò mẫm/sửa/định giá đồ trên bàn
    anim = "player_search",
    flag = 49 -- Upper body loop
}

-- Số lượng ô chứa ở Tab 2
Config.TotalSlots = 5

-- Số lượng vật phẩm tối thiểu và tối đa ở Tab 2 mới cho phép xác nhận quy đổi
Config.MinItems = 2
Config.MaxItems = 5

-- Thời gian chờ quá trình xử lý quy đổi (tính bằng mili giây - ms)
Config.ProcessTime =  10 * 60 * 1000 

-- Cấu hình Ẩn / Hiện giá "Thực nhận" preview trên UI (true = hiện, false = ẩn để test/sử dụng)
Config.ShowRealPayoutPreview = false

-- Tỷ lệ khoảng giá nhận tiền ngẫu nhiên từ tổng giá niêm yết (Min = 60%, Max = 100%)
-- Ví dụ: Tổng giá 5 món = $25,000 -> Nhận ngẫu nhiên trong khoảng $15,000 đến $25,000 (Ví dụ ~$18,500)
Config.MinPayoutPercent = 0.60
Config.MaxPayoutPercent = 1.00

-- Loại tiền tệ trả thưởng ('money' cho ox_inventory hoặc 'cash')
Config.RewardAccount = 'money'

-- Đường dẫn ảnh item (mặc định của ox_inventory)
Config.ItemImagePath = 'https://raw.githubusercontent.com/xuannguyen995/item_allstars/refs/heads/main/'

-- Cấu hình Ẩn / Hiện hiển thị tỷ giá biến động lên xuống trên UI
Config.ShowPriceTrend = true

-- Cấu hình Tự động tạo tỷ giá mới ngẫu nhiên mỗi khi Restart Resource / Start Server
Config.UpdatePriceOnRestart = true

-- Cấu hình Tự động biến động giá thị trường theo thời gian khi server đang chạy (nếu enabled = true)
Config.DynamicPrices = {
    enabled = true, -- true: Tự động biến động giá ngẫu nhiên sau mỗi khoảng thời gian, false: Sử dụng giá cố định trong Config
    interval = 30 * 60 * 1000, -- Khoảng thời gian cập nhật giá (ms), ví dụ: 30 phút
    minPercentChange = -15, -- Tỷ lệ giảm giá tối đa (-15%)
    maxPercentChange = 15,  -- Tỷ lệ tăng giá tối đa (+15%)
}

-- Danh sách các vật phẩm cho phép quy đổi và giá định giá niêm yết
-- Lịch sử tỷ giá cũ (oldPrice) và giá hiện tại sẽ được tự động lưu & quản lý trong tệp 'prices.json'
Config.ValuedItems = {
    ['goldchain']       = 3830,
    ['rolex']       = 4220,
    ['diamond']   = 6430,
}