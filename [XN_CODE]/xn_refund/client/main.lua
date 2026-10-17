RegisterNetEvent('xn_refund:client:openSellDialog', function(data)
    local itemName = data.name
    local itemLabel = data.label
    local itemCount = data.count
    local itemPrice = data.price
    local itemIcon = data.icon or 'box'
    local inputType = Config.InputType or 'number'
    local descriptionText = Config.Description or 'Vật phẩm này đã hết hạn sử dụng hãy quy đổi lại thành tiền mặt'
    local fullDescription = ('%s\nGiá đổi: $%s / 1 vật phẩm | Tối thiểu: 1 - Tối đa: %s'):format(descriptionText, itemPrice, itemCount)

    local dialogRows = {}

    if inputType == 'slider' then
        dialogRows[1] = {
            type = 'slider',
            label = ('Số lượng muốn đổi (Đang có: %s)'):format(itemCount),
            description = fullDescription,
            icon = itemIcon,
            default = 1,
            min = 1,
            max = itemCount,
            step = 1,
            required = true
        }
    else
        dialogRows[1] = {
            type = 'number',
            label = ('Số lượng muốn đổi (Đang có: %s)'):format(itemCount),
            description = fullDescription,
            icon = itemIcon,
            default = 1,
            min = 1,
            max = itemCount,
            step = 1,
            required = true
        }
    end

    local input = lib.inputDialog(('Quy Đổi %s'):format(itemLabel), dialogRows)

    if not input or not input[1] then return end

    local amount = tonumber(input[1])
    if amount and amount >= 1 and amount <= itemCount then
        TriggerServerEvent('xn_refund:server:sellItem', itemName, amount)
    else
        lib.notify({
            title = 'Lỗi',
            description = 'Số lượng quy đổi không hợp lệ!',
            type = 'error'
        })
    end
end)
