Config = {}

-- Cấu hình chung
Config.ScanOnStart = true -- Quét khi server khởi động
Config.AutoScanInterval = 3600000 -- Quét tự động mỗi 1 giờ (ms), 0 = tắt
Config.LogToFile = true -- Ghi log ra file
Config.LogFileName = "backdoor_scan_results.log"
Config.WebhookURL = "" -- Discord webhook URL (để trống nếu không dùng)
Config.NotifyAdmins = true -- Thông báo cho admin ingame

-- Các resource được bỏ qua (whitelist)
Config.WhitelistResources = {
    "backdoor_anti", -- Không quét chính nó
    -- Thêm các resource tin cậy vào đây
}

-- Mức độ cảnh báo
Config.ThreatLevels = {
    CRITICAL = "🔴 CRITICAL",
    HIGH = "🟠 HIGH", 
    MEDIUM = "🟡 MEDIUM",
    LOW = "🟢 LOW"
}

-- Ace permission để sử dụng lệnh scan
Config.AcePermission = "command.scanbackdoor"
