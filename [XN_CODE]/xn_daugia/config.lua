Config = {}

-- Chế độ gỡ lỗi (in log ra console F8/Server)
Config.Debug = false

-- Tên item dùng để mở giao diện đấu giá
Config.ItemName = 'the_dau_gia'

-- Lệnh Admin để bắt đầu phiên đấu giá
-- Cú pháp: /daugia [giá_khởi_điểm] [tên_gói_thầu] (Ví dụ: /daugia 1000000 Gói Xe Siêu Cấp)
Config.AdminCommand = 'daugia'

-- Lệnh Admin để huỷ/kết thúc phiên đấu giá khẩn cấp
Config.CancelCommand = 'huydaugia'

-- Quyền admin được phép dùng lệnh (hỗ trợ qbx_core / qb-core groups)
Config.AdminGroups = { 'admin', 'god', 'superadmin', 'mod' }

-- Thời gian đếm ngược sau mỗi lượt đặt cược (giây)
Config.CountdownSeconds = 60

-- Thời gian khoá sau mỗi lần gọi cược (giây)
-- Người gọi cược tiếp theo chỉ được phép đặt cược sau 3 giây (tức là khi đồng hồ đếm ngược <= 7s)
Config.BidLockSeconds = 3

-- Các mốc tiền cược thêm có sẵn (USD)
Config.BetSteps = {
    100000,
    200000,
    300000,
    400000,
    500000,
    600000,
    700000,
    800000,
    900000,
    1000000
}

-- Kiểm tra và trừ tiền:
-- Đặt false: Không check tiền và không trừ tiền người chơi (đấu giá tự do)
Config.CheckMoney = false
Config.DeductMoney = false
Config.PaymentMode = 'none' -- 'none', 'on_win', 'on_bid'

-- Cấu hình hiển thị 3D Text / Tag trên đầu người đặt cược
Config.Overhead = {
    drawDistance = 35.0,     -- Khoảng cách tối đa nhìn thấy tag trên đầu
    heightOffset = 0.75,      -- Độ cao phía trên đầu player (z offset)
    font = 4,                -- Font chữ GTA
    scale = 0.40,            -- Kích thước chữ
    enableSound = true       -- Bật âm thanh tick đếm ngược
}

-- Cấu hình Discord Webhook để ghi log phiên đấu giá
Config.DiscordWebhook = ""

-- Text ngôn ngữ thông báo
Config.Locale = {
    no_active_auction = "Hiện tại không có phiên đấu giá nào đang diễn ra!",
    auction_already_running = "Đang có một phiên đấu giá diễn ra, không thể tạo mới!",
    auction_started = "Phiên đấu giá đã được khởi động với giá khởi điểm: %s$",
    auction_cancelled = "Phiên đấu giá đã bị huỷ bởi Quản trị viên!",
    invalid_price = "Vui lòng nhập giá khởi điểm hợp lệ (lớn hơn 0)!",
    not_enough_money = "Bạn không có đủ %s$ trong tài khoản để đặt cược!",
    bid_lock_cooldown = "Vui lòng đợi %s giây nữa (khi đếm ngược <= %ss) để đặt cược tiếp!",
    bid_too_low = "Mức giá bạn đặt phải cao hơn giá hiện tại (%s$)!",
    bid_placed_success = "Bạn đã đặt thầu thành công với tổng mức giá: %s$",
    outbid_refund = "Bạn đã bị người khác vượt giá! Đã hoàn lại %s$ vào tài khoản của bạn.",
    outbid_broadcast = "[ĐẤU GIÁ] %s (ID: %s) vừa nâng mức giá lên %s$!",
    auction_won_broadcast = "[ĐẤU GIÁ] Chúc mừng %s (ID: %s) đã thắng phiên đấu giá với mức giá %s$!",
    race_condition_rejected = "Lượt đặt thầu của bạn đã bị từ chối do có người đặt giá cao hơn hoặc nhanh hơn vài mili-giây!",
    no_permission = "Bạn không có quyền thực hiện lệnh này!"
}
