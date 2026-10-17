ESX = exports["es_extended"]:getSharedObject()

RegisterNUICallback('close', function(data, cb)
    IsOpen = false
    SendNUIMessage({
        type = 'close'
    })
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut()

    cb('ok')
end)

RegisterNUICallback('check-item', function(data, cb)
    preparePlayerItem(data.item, data.multiply, 0)  -- BÙA MAY MẮN ĐÃ BỎ

    cb('ok')
end)

RegisterNUICallback('check-item-on-click', function(data, cb)
    checkPlayerItemOnClick(data.item, data.multiply)
    cb('ok')
end)

-- RegisterNUICallback('fulltyle', function(data, cb)
--     ESX.ShowNotification('Tỷ lệ đã 100% không thể thêm bùa', 'error')
-- end)

RegisterNUICallback('crafted', function(data, cb)
    local item = data.item
    -- print("tyle: "..data.lucky)  -- BÙA MAY MẮN ĐÃ BỎ
    ClearPedTasks(PlayerPedId())
    ClearPedSecondaryTask(PlayerPedId())
    if item.Type == 'weapon' or item.Type == 'upgrade_weapon' then
        ESX.TriggerServerCallback('vierp.craftingx:callback:hasWeapon', function(has) 
            if has then
                ESX.ShowNotification('Bạn đã có vũ khí', 'error')
            else
                TriggerServerEvent('vierp.craftingx:cfx:remove', data.multiply, item.Cash, item.CraftItems, 0)  -- BÙA MAY MẮN ĐÃ BỎ

                if data.result and (item.Type == 'upgrade_weapon' or item.Type == 'weapon') then
                    if item.PermItems then
                        TriggerServerEvent('vierp.craftingx:cfx:remove2', data.multiply, item.PermItems)
                    end
                    TriggerServerEvent('vierp.craftingx:cfx:addWeapon', item.Item)
                end

                if data.result then
                    ESX.ShowNotification('Chế tạo thành công', 'success')
                else
                    ESX.ShowNotification('Chế tạo thất bại.', 'error')
                    local failedItems = {}
                    for k, v in pairs(item.Failed) do
                        math.randomseed(GetGameTimer())
                        local amount = math.random(v[1], v[2])
                        failedItems[k] = amount
                        Citizen.Wait(100)
                    end

                    TriggerServerEvent('vierp.craftingx:cfx:getFailed', failedItems)
                end
            end
        end, item.Item, item.Cash)
    else
        ESX.TriggerServerCallback('vierp.craftingx:callback:canCarry', function(can)
            if can then
                TriggerServerEvent('vierp.craftingx:cfx:remove', data.multiply, item.Cash, item.CraftItems, 0)  -- BÙA MAY MẮN ĐÃ BỎ

                if data.result and item.Type == 'item' then
                    TriggerServerEvent('vierp.craftingx:cfx:addItem', data.multiply, item.Item, data)
                end

                if data.result then
                    ESX.ShowNotification("Thành công", 'success', 3500)
                else
                    ESX.ShowNotification("Thất bại", 'error', 3500)
                    local failedItems = {}

                    for k, v in pairs(item.Failed) do
                        math.randomseed(GetGameTimer())
                        local amount = math.random(v[1], v[2])
                        failedItems[k] = amount
                        Citizen.Wait(100)
                    end
                    
                    TriggerServerEvent('vierp.craftingx:cfx:getFailed', failedItems, data)
                end
            else
                ESX.ShowNotification('Không thể thêm các mục', 'error')
            end
        end, item.Item, data.multiply)
    end

    cb('ok')
end)