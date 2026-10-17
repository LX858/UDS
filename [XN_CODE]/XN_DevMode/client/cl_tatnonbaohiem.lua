
-- Khởi tạo biến toàn cục
local isHelmetForcedOff = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = GetPlayerPed(-1)
        
        -- Kiểm tra nếu nhân vật đang trên xe
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- Kiểm tra loại xe (xe máy)
                -- Tắt mũ bảo hiểm
                RemovePedHelmet(playerPed, true)
                
                -- Ngăn không cho đội mũ tự động
                SetPedHelmet(playerPed, false)
                
                -- Ép buộc tắt mũ (ngay cả khi đang đội)
                if IsPedWearingHelmet(playerPed) then
                    SetPedHelmet(playerPed, false)
                end
                
                isHelmetForcedOff = true
        end
    end
end)