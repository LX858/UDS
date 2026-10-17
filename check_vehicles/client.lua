-- =========================================================================
-- CLIENT-SIDE: IN KẾT QUẢ DANH SÁCH NGƯỜI CÓ TỪ 7/9 XE RA F8 CONSOLE
-- =========================================================================

RegisterNetEvent('checkvehicles:client:printF8', function(qualifiedCitizens, requiredCount, totalTargets)
    local req = requiredCount or 7
    local total = totalTargets or 9

    print("^3========================================================================^7")
    print(("^2[CHECK XE - F8 CONSOLE]^7 DANH SÁCH CITIZENID SỞ HỮU TỪ ^6%s/%s^7 MẪU XE"):format(req, total))
    print("^3========================================================================^7")

    if not qualifiedCitizens or #qualifiedCitizens == 0 then
        print(("^1[CHECK XE]^7 Không tìm thấy ai sở hữu từ %s/%s xe trong danh sách."):format(req, total))
        print("^3========================================================================^7")
        return
    end

    print(("^2[CHECK XE]^7 Tìm thấy tổng cộng: ^6%s^7 người chơi đạt điều kiện:"):format(#qualifiedCitizens))
    print("------------------------------------------------------------------------")

    for idx, player in ipairs(qualifiedCitizens) do
        print(("^3[%s] CitizenID: ^6%s^7 | Tên Nhân Vật: ^2%s^7 | Sở hữu: ^5%s/%s mẫu xe^7 (Tổng %s chiếc)"):format(
            idx, player.citizenid, player.playerName, player.totalUnique, total, #player.vehicleList
        ))
        
        for vIdx, v in ipairs(player.vehicleList) do
            print(("^5     [%s] Tên xe: ^7%-15s ^5| Biển số: ^1%-10s ^5| Garage: ^4%s^7"):format(
                vIdx, v.vehicle, v.plate, v.garage
            ))
        end
        print("------------------------------------------------------------------------")
    end

    print("^2[CHECK XE]^7 Đã in xong danh sách người đạt từ 7/9 xe!")
    print("^3========================================================================^7")
end)

-- Lệnh gõ trực tiếp trong F8: checkvehicles hoặc trong chat: /checkvehicles
RegisterCommand('checkvehicles', function()
    TriggerServerEvent('checkvehicles:server:requestCheck')
end, false)
