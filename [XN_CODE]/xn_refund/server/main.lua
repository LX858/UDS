local function registerUsableItems()
    for itemName, data in pairs(Config.Items) do
        exports.qbx_core:CreateUseableItem(itemName, function(source, item)
            local src = source
            local itemCount = exports.ox_inventory:GetItemCount(src, itemName)

            if not itemCount or itemCount < 1 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Thông báo',
                    description = 'Bạn không có vật phẩm này trong người!',
                    type = 'error'
                })
                return
            end

            local itemData = exports.ox_inventory:Items(itemName)
            local label = itemData and itemData.label or data.label

            TriggerClientEvent('xn_refund:client:openSellDialog', src, {
                name = itemName,
                label = label,
                count = itemCount,
                price = data.price,
                icon = data.icon
            })
        end)
    end
end

CreateThread(function()
    registerUsableItems()
end)

RegisterNetEvent('xn_refund:server:sellItem', function(itemName, amount)
    local src = source
    local itemConfig = Config.Items[itemName]

    if not itemConfig then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Vật phẩm không nằm trong danh sách quy đổi!',
            type = 'error'
        })
        return
    end

    amount = tonumber(amount)
    if not amount or amount < 1 or amount ~= math.floor(amount) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Số lượng không hợp lệ!',
            type = 'error'
        })
        return
    end

    local currentCount = exports.ox_inventory:GetItemCount(src, itemName)
    if not currentCount or currentCount < amount then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = ('Bạn không có đủ số lượng trong người! (Hiện có: %s)'):format(currentCount or 0),
            type = 'error'
        })
        return
    end

    local removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
    if removed then
        local totalMoney = amount * itemConfig.price

        -- Cong tien mat cho nguoi choi qua qbx_core
        exports.qbx_core:AddMoney(src, 'cash', totalMoney, 'sold-' .. itemName)

        local itemData = exports.ox_inventory:Items(itemName)
        local label = itemData and itemData.label or itemConfig.label

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Quy Đổi Thành Công',
            description = ('Bạn đã đổi thành công %s %s và nhận được $%s tiền mặt!'):format(amount, label, totalMoney),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Không thể xóa vật phẩm khỏi túi đồ!',
            type = 'error'
        })
    end
end)
