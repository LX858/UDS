return {
    doctorCallCooldown = 1, -- Time in minutes for cooldown between doctors calls
    wipeInvOnRespawn = true, -- Cho phép vô hiệu hóa xóa tất cả các mục khỏi trình phát trên respawn
    depositSociety = function(society, amount)
        exports['Renewed-Banking']:addAccountMoney(society, amount)
    end
}