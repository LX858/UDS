Config = {}

----------------------
-- Log discord setup--
----------------------

-- --Webhook of your channel (tutorial: https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)
-- Config.WebHook = "http"
-- Config.WebHook_GT = ""

--What information do you want the log to include? (Refer to README.md for more information)
Config.LogMessageType = "short" --Only choose 1: "standard", "short" or "full"
Config.LogMessageType_GT = "short" --Only choose 1: "standard", "short" or "full"

--Avater for your log (optional)
Config.AvatarURL = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/logosv.webp"
Config.AvatarURL_GT = "https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/logosv.webp"

--Name for your log (optional)
Config.ServerName = "UNDER STAR"
Config.ServerName_GT = "UNDER STAR"

--Title for your log (optional)
Config.LogTitle = "TOP 10 NGƯỜI GIÀU NHẤT THÀNH PHỐ"
Config.LogTitle_GT = "TOP 20 TIỀN GIA TỘC"

--Color for your log (optional). Default: green
Config.LogColour = 65352

--Do you want the log to be automatically sent after a certain time?
--By the default, you need to use an admin command to trigger event
Config.SendLogByTime = {
    enable = true, --Enable/disable this feature
    time = 60, --How long do you want the log to be sent (default: 60 minutes)
}

--Do you want only top richest to be sent?
--Or you want to send money log of all players in database?
--I added this because for larger server, you might be over 200 players and it might cause lag when log details of all of them
--So I recommend to leave this as true
Config.OnlyTopRichest = {
    enable = true, --Enable/disable this feature
    top = 50, --How many top players you want to log? (By default: Top 10 richest players)
}

--Business accounts configuration
Config.BusinessAccounts = {
    enable = true, --Enable/disable business accounts logging
    
    -- Doanh nghiệp NHÀ NƯỚC (Cảnh sát + Bác sĩ + Tòa thị chính + Thất nghiệp)
    government = {
        "police", "ambulance", "hospital", 
        "bcso", "sasp", "lspd", "ems",
        "cityhall", "townhall", "government", "gov",
        "unemployed"
    },
    
    -- Số lượng hiển thị
    topGovernment = 10,  -- Top doanh nghiệp nhà nước
    topPrivate = 15,     -- Top doanh nghiệp tư nhân
}

--Batch processing để tối ưu performance
Config.BatchProcessing = {
    enable = true,      -- Bật tắt batch processing
    batchSize = 200,    -- Số records mỗi batch (khuyến nghị: 100-200)
    delayMs = 150,      -- Delay giữa các batch (ms) - 150ms = 0.15 giây
}