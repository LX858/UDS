local QBCore = exports['qb-core']:GetCoreObject()

-- Đăng ký item sử dụng
QBCore.Functions.CreateUseableItem(Config.ItemName, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Kích hoạt sự kiện đổi tên trên client
    TriggerClientEvent('thedoiten:client:useItem', source)
end)

-- Đăng ký callback xử lý đổi tên
lib.callback.register('thedoiten:server:renamePlayer', function(source, firstname, lastname)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        return false, "Không tìm thấy thông tin nhân vật."
    end

    local citizenid = Player.PlayerData.citizenid

    -- 1. Kiểm tra số lượng item trong ox_inventory
    local count = exports.ox_inventory:GetItemCount(source, Config.ItemName)
    if not count or count < 1 then
        return false, Config.Lang.no_item
    end

    -- 2. Cập nhật dữ liệu nhân vật trong bộ nhớ RAM (Player.PlayerData)
    -- Điều này cực kỳ quan trọng để khi người chơi thoát game (hoặc tự động lưu),
    -- QB-Core/QBX sẽ không ghi đè tên cũ vào cơ sở dữ liệu.
    Player.PlayerData.charinfo.firstname = firstname
    Player.PlayerData.charinfo.lastname = lastname

    -- Đồng bộ hóa PlayerData mới xuống client
    if Player.Functions.SetPlayerData then
        Player.Functions.SetPlayerData('charinfo', Player.PlayerData.charinfo)
    end
    
    -- 3. Cập nhật trực tiếp vào SQL cơ sở dữ liệu
    local jsonCharInfo = json.encode(Player.PlayerData.charinfo)
    local success = MySQL.update.await('UPDATE players SET charinfo = ? WHERE citizenid = ?', {
        jsonCharInfo,
        citizenid
    })

    if success then
        -- 4. Trừ 1 thẻ đổi tên khỏi túi đồ của người chơi
        local removed = exports.ox_inventory:RemoveItem(source, Config.ItemName, 1)
        if not removed then
            -- Trường hợp hy hữu không trừ được item (ví dụ lag túi đồ)
            -- Phục hồi lại tên trong RAM (nếu cần thiết, hoặc ghi nhận log)
            return false, "Không thể tiêu hao vật phẩm đổi tên."
        end
        TriggerClientEvent('QBCore:Notify', source, 'Đổi tên thành công!', 'success')
        -- Lưu lại Player Data để đồng bộ toàn bộ hệ thống lõi
        Player.Functions.Save()
        
        return true
    else
        return false, Config.Lang.db_error
    end
end)
