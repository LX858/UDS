local Translations = {
    command = {
        name = "ktmoneytp",
        help = "Xuất danh sách những người chơi nhiều tiền nhất",
    },
    message = {
        top_without_license = "%{name} (%{pid}) | %{money} | TỔNG: %{totalMoney}`\n", --DO NOT REMOVE "`" AT THE END OF THIS STRING
        top_with_license = "%{name} (%{pid}) | %{license} | %{money} | TỔNG: %{totalMoney}`\n", --DO NOT REMOVE "`" AT THE END OF THIS STRING
        short_top_message = "%{name} (%{pid}) | TỔNG: %{totalMoney}", --Removed ` and \n for inline format
        total_server_money = "\n**TỔNG TIỀN TOÀN SERVER: %{totalServerMoney}**", --Total money message
        
        -- Doanh nghiệp Nhà báo
        government_header = "\n\n🏛️ ══════════ **DOANH NGHIỆP NHÀ BÁO** ══════════\n*(Cảnh sát + Y tế + Cardealer)*",
        government_account = "%{index}. %{name} | Số dư: %{amount}",
        total_government_money = "**💰 Tổng DN Nhà báo: %{totalMoney}**",
        
        -- Doanh nghiệp Tư nhân
        private_header = "\n\n🏢 ══════════ **DOANH NGHIỆP TƯ NHÂN** ══════════",
        private_account = "%{index}. %{name} | Số dư: %{amount}",
        total_private_money = "**💼 Tổng DN Tư nhân: %{totalMoney}**",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})