Config = {}

-- Quyền mở menu ban (/banmenu hoặc /xnban)
-- Hỗ trợ quyền Qbox / qb-core groups hoặc Ace Permission
-- Quyền Admin dùng group Qbox tích hợp sẵn (ox_lib tự kiểm tra, không cần setup thủ công)
Config.AdminGroups = { 'group.admin', 'group.superadmin', 'group.mod' }

-- Command để mở menu ban
Config.Command = 'banmenu'

-- Ace Permission cho NetEvents (vẫn giữ dùng cho kiểm tra server-side ngoài command)
Config.AdminAce = 'group.admin'

-- Định dạng thông báo khi người chơi bị chặn kết nối (playerConnecting)
Config.BanMessageFormat = [[
❌ BẠN ĐÃ BỊ CHẶN KẾT NỐI VÀO MÁY CHỦ!

Bạn đang bị cấm vì lí do: %s

Mã Cấm: [%s]
Người thực hiện: %s
Thời gian cấm: %s
Thời hạn: %s

Nếu bạn cho rằng đây là quyết định nhầm lẫn, vui lòng liên hệ Ban Quản Trị Discord server.
]]

-- Discord Webhook Logs
Config.DiscordWebhook = '' -- Điền URL webhook Discord nếu muốn ghi log
Config.BotName = 'XN Ban System'
Config.BotAvatar = 'https://i.imgur.com/8Q0y9p8.png'

-- Tối ưu cho server đông người
Config.PlayerRecordInterval = 1800 -- Giây: không ghi lại DB nếu thông tin người chơi không đổi trong khoảng này
Config.BanCacheRefreshMinutes = 5 -- Phút: tự tải lại danh sách ban từ DB
Config.Debug = false -- In log mỗi khi lưu người chơi (cho biết có nhận được discord/gmail hay không). Tắt khi đã ổn định
Config.SearchCooldownMs = 1000 -- Mili giây: khoảng cách tối thiểu giữa 2 lần tìm của 1 admin
Config.SearchMaxResults = 15 -- Số kết quả tối đa mỗi lần tìm
