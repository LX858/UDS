local holdToSprint = false

-- Check mỗi 2 giây, chỉ khi phát hiện Hold to Sprint mới bật vòng lặp xử lý
CreateThread(function()
    while true do
        Wait(2000)
        holdToSprint = GetProfileSetting(19) == 1
    end
end)

-- Vòng lặp này chỉ xử lý khi holdToSprint = true, còn lại Wait(500) ngủ nhẹ
CreateThread(function()
    while true do
        if holdToSprint then
            Wait(0)
            local ped = PlayerPedId()

            -- Khóa không cho sprint
            SetPedMaxMoveBlendRatio(ped, 1.0)

            -- ===== TEXT BOTTOM =====
            SetTextFont(4)
            SetTextScale(0.45, 0.45)
            SetTextColour(255, 80, 80, 220)
            SetTextCentre(true)
            SetTextOutline()

            BeginTextCommandDisplayText("STRING")
            AddTextComponentString(
                "~r~SERVER REQUIREMENT~n~" ..
                "~w~Vào Settings > Game Pad~n~" ..
                "Tắt HOLD TO SPRINT hoặc Restore Defaults"
            )
            EndTextCommandDisplayText(0.5, 0.80)
        else
            Wait(500) -- Không phải Hold to Sprint -> ngủ, gần như không tốn performance
        end
    end
end)
