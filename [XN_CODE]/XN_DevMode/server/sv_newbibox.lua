local QBCore = exports['qb-core']:GetCoreObject()

-- Đăng ký item có thể sử dụng
QBCore.Functions.CreateUseableItem('balonewbie', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    print('1')
    -- Gửi event về client để lấy dữ liệu ped và chạy progress bar
    TriggerClientEvent('xn_onpenbox:client:useBaloNewbie', src)
end)

-- Event nhận từ client sau khi progress bar hoàn thành
RegisterNetEvent('xn_onpenbox:server:openBaloNewbie', function(gender)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Kiểm tra người chơi còn item balonewbie không
    local hasItem = Player.Functions.GetItemByName('balonewbie')
    if not hasItem then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có balo newbie!', 'error')
        return
    end
    
    -- Xóa item balonewbie
    Player.Functions.RemoveItem('balonewbie', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['balonewbie'], 'remove', 1)
    
    -- Xác định drawable dựa trên giới tính
    local drawable = 1 -- Mặc định nam
    if gender == 'female' then
        drawable = 1 -- Nữ
    end
    Wait(500)
    -- Thêm item balo vào inventory thông qua XNClothes
    exports['XNClothes']:GiveClothingItem(src, 'bag', drawable, 0, 0)
    
    -- Thông báo thành công
    TriggerClientEvent('QBCore:Notify', src, 'Bạn đã nhận được balo số 1!', 'success')
    
    -- Log
    print(string.format('[xn_onpenbox] Player %s (ID: %d) opened balo newbie - Gender: %s, Drawable: %d', 
        GetPlayerName(src), src, gender, drawable))
end)
