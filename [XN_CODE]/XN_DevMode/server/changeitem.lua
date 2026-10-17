local QBX = exports.qbx_core

-- Danh sách các item cần đổi với label
local itemsToConvert = {
    { name = 'banvevukhi1', label = 'Bản vẽ vũ khí I' },
    { name = 'banvevukhi2', label = 'Bản vẽ vũ khí II' },
    { name = 'banvevukhi3', label = 'Bản vẽ vũ khí III' },
    { name = 'banvevukhi4', label = 'Bản vẽ vũ khí IV' },
    { name = 'banvevukhi5', label = 'Bản vẽ vũ khí V' }
}

-- Đăng ký các item có thể sử dụng
for _, itemData in ipairs(itemsToConvert) do
    QBX:CreateUseableItem(itemData.name, function(source, item)
        local src = source
        local Player = QBX:GetPlayer(src)
        
        if not Player then return end
        
        -- Kiểm tra xem player có item không
        local hasItem = Player.Functions.GetItemByName(itemData.name)
        if not hasItem then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không có ' .. itemData.label, 'error')
            return
        end
        
        -- Xóa item cũ
        if Player.Functions.RemoveItem(itemData.name, 1) then
            -- Thêm item mới
            if Player.Functions.AddItem('banvevukhi', 1) then
                TriggerClientEvent('inventory:client:ItemBox', src, QBX:GetItems()[itemData.name], 'remove', 1)
                TriggerClientEvent('inventory:client:ItemBox', src, QBX:GetItems()['banvevukhi'], 'add', 1)
                TriggerClientEvent('QBCore:Notify', src, 'Đã đổi ' .. itemData.label .. ' thành Bản vẽ vũ khí', 'success')
            else
                -- Nếu không thêm được, hoàn lại item cũ
                Player.Functions.AddItem(itemData.name, 1)
                TriggerClientEvent('QBCore:Notify', src, 'Không thể đổi item, túi đồ đầy', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Có lỗi xảy ra khi xóa item', 'error')
        end
    end)
end

print('^2[XN_DevMode]^7 Đã load changeitem.lua - ' .. #itemsToConvert .. ' items đã được đăng ký')
