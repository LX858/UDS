-- Event chính: Nhận từ client khi dùng item (giống hệ thống nghiện)
RegisterNetEvent('binhlanpd:server:useGear', function(slot, itemType)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local itemName = itemType or 'binhlannghanh'
    
    -- Xóa item trước
    local removed = Player.Functions.RemoveItem(itemName, 1, slot)
    
    if not removed then
        exports.qbx_core:Notify(src, 'Không thể sử dụng item', 'error')
        return
    end
    
    -- Xóa item thành công → Trigger client để đeo gear hoặc refill (chạy progress bar)
    TriggerClientEvent('binhlanpd:client:useGear', src, itemName)
end)

-- Event chỉ xóa item (khi đang đeo loại khác)
RegisterNetEvent('binhlanpd:server:deleteItemOnly', function(slot, itemType)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local itemName = itemType or 'binhlannghanh'
    Player.Functions.RemoveItem(itemName, 1, slot)
end)

-- Event trigger client sau khi item đã bị xóa (không xóa lại)
RegisterNetEvent('binhlanpd:server:triggerUseGear', function(itemType)
    local src = source
    TriggerClientEvent('binhlanpd:client:useGear', src, itemType)
end)

-- Event trả lại bình lặn khi tháo ra
RegisterNetEvent('binhlanpd:server:returnGear', function(itemType)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    if itemType == 'binhlannghanh' or itemType == 'diving_gear' then
        Player.Functions.AddItem(itemType, 1)
    end
end)

