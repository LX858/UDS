Config = {}

-- Quyền mở menu ban (/banmenu hoặc /xnban)
-- Hỗ trợ quyền Qbox / qb-core groups hoặc Ace Permission
Config.AdminGroups = {
    ['admin'] = true,
    ['god'] = true,
    ['mod'] = true,
}

-- Phím tắt hoặc Command
Config.Command = 'banmenu'
Config.AdminAce = 'command.banmenu' -- Quyền ace nếu dùng ace permission

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
