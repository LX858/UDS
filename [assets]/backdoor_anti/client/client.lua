--[[
    CLIENT SIDE - Thông báo cho admin về kết quả quét
]]

RegisterNetEvent('backdoor_anti:notify')
AddEventHandler('backdoor_anti:notify', function(title, message, type)
    -- Sử dụng notification mặc định của GTA
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
    
    -- In ra console F8
    print("^3[BACKDOOR SCANNER] " .. title .. ": " .. message .. "^7")
end)

-- Có thể mở rộng thêm UI nếu cần
