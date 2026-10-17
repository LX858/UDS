Config = {}

-- Lệnh mở menu report
Config.Command = 'rp'
Config.CommandAliases = { 'report', 'baocao' }

-- Cấu hình FiveManage API
Config.FiveManage = {
    ApiKey = 'DYds5MyJBLJRpLO73SRROn09QKfCSr7X',
    UploadUrl = 'https://api.fivemanage.com/api/v3/file',
    Folder = 'reports',
}

-- Discord Webhook để nhận thông tin report
Config.DiscordWebhook = 'https://discord.com/api/webhooks/1553388484230910024/Qps6Kv-zWRLZ9PPyd0zvuIjwpGCdPvQvhHN5qTHw05cut6pPD2StEUchAaXt7DUH_GUT'

-- Thông tin máy chủ hiển thị trên Discord
Config.ServerName = 'UNDER STAR ROLEPLAY'
Config.ServerLogo = 'https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/logosv.webp'

-- Bán kính quét người chơi xung quanh (mét)
Config.NearbyRadius = 50.0

-- Thời lượng ghi hình video mặc định (giây)
Config.RecordDuration = 10

-- Tốc độ khung hình (FPS) khi quay video (30 FPS chuẩn đồng bộ thời gian 1:1)
Config.RecordFPS = 30

-- Thời gian giãn cách giữa 2 lần gửi report của 1 người chơi (15 phút = 900 giây)
Config.Cooldown = 15 * 60

-- Thông báo cho Admin đang online trong game khi có report mới
Config.NotifyAdminsInGame = true

-- Danh sách quyền admin (dùng cho Qbox / QBCore / Ace Permissions)
Config.AdminPermissions = {
    'admin',
    'god',
    'mod',
    'qbox.admin',
    'qbcore.admin',
    'qbcore.god'
}
