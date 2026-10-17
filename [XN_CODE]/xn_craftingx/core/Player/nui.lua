QBCore = exports['qb-core']:GetCoreObject()

RegisterNUICallback('close', function(data, cb)
    IsOpen = false
    IsCrafting = false  -- Reset khi đóng UI
    SendNUIMessage({
        type = 'close'
    })
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut()

    cb('ok')
end)

RegisterNUICallback('check-item', function(data, cb)
    -- ANTI-SPAM: Chặn nếu đang trong quá trình chế tạo
    if IsCrafting then
        print('^3[ANTI-SPAM] check-item bị chặn - player đang chế tạo^0')
        cb('blocked')
        return
    end
    IsCrafting = true
    -- Xử lý riêng cho tab repair
    if data.item and data.item.Type == 'repair' then
        local playerData = QBCore.Functions.GetPlayerData()
        local missingItems = {}
        local hasAllItems = true
        local hasCash = true
        
        -- Kiểm tra vật phẩm sửa chữa
        if data.item.CraftItems then
            for itemName, itemData in pairs(data.item.CraftItems) do
                local itemCount = exports.ox_inventory:Search('count', itemName)
                local needCount = itemData[2] or 1
                if itemCount < needCount then
                    hasAllItems = false
                    table.insert(missingItems, itemName)
                end
            end
        end
        
        -- Kiểm tra tiền
        if data.item.Cash and data.item.Cash > 0 then
            if playerData.money.cash < data.item.Cash then
                hasCash = false
            end
        end
        
        -- Gửi kết quả về NUI
        if hasAllItems and hasCash then
            SendNUIMessage({ type = 'item-ready' })
            playAnim()
            local craftLength = tonumber(data.item.Length) or 3000
            Citizen.SetTimeout(craftLength, function()
                if IsCrafting then
                    SendNUIMessage({ type = 'craft-trigger' })
                end
            end)
        else
            IsCrafting = false  -- Reset để player có thể thử lại
            QBCore.Functions.Notify('Không đủ vật phẩm sửa chữa', 'error')
            SendNUIMessage({
                type = 'item-not-ready',
                missingItems = missingItems,
                missingCash = not hasCash
            })
        end
        
        cb('ok')
        return
    end
    
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
    -- ANTI-SPAM: Chặn nếu không phải từ check-item hợp lệ
    if not IsCrafting then
        print('^1[ANTI-SPAM] crafted bị chặn - không có check-item trước đó^0')
        cb('blocked')
        return
    end
    IsCrafting = false  -- Reset ngay để chỉ xử lý 1 lần
    local item = data.item
    -- print("tyle: "..data.lucky)
    ClearPedTasks(PlayerPedId())
    ClearPedSecondaryTask(PlayerPedId())
    
    -- Xử lý sửa chữa vũ khí
    if item.Type == 'repair' then
        -- Lua đã đếm thời gian xong mới gửi craft-trigger → luôn gửi server sửa
        TriggerServerEvent('vierp.craftingx:cfx:repairWeapon', item.WeaponSlot, item.Item, item.CraftItems, item.Cash)
        cb('ok')
        return
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- LOGIC MỚI: CHỈ XÓA VŨ KHÍ KHI THÀNH CÔNG
    -- ═══════════════════════════════════════════════════════════════
    
    -- Pre-calc failedItems (dùng cho cả weapon và upgrade nếu thất bại)
    local failedItems = {}
    if item.Failed then
        for k, v in pairs(item.Failed) do
            math.randomseed(GetGameTimer())
            local amount = math.random(v[1], v[2])
            failedItems[k] = amount
            Citizen.Wait(100)
        end
    end

    if item.Type == 'weapon' then
        -- ═══════════════════════════════════════════════════════════════
        -- SECURE: Kết quả tính phía SERVER qua cfx:processResult
        -- ═══════════════════════════════════════════════════════════════
        TriggerServerEvent('vierp.craftingx:cfx:remove', data.multiply, item.Cash, item.CraftItems, 0, item.Item, item.Chance, item.PermItems)
        TriggerServerEvent('vierp.craftingx:cfx:processResult', data.multiply, item.Item, 'weapon', item.WeaponLevel or 1, failedItems, item.PermItems)

    elseif item.Type == 'upgrade' then
        -- Bước 1: Trừ nguyên liệu và tiền (đăng ký pendingItem = item.Item, chance = 100 cho upgrade)
        TriggerServerEvent('vierp.craftingx:cfx:remove', data.multiply, item.Cash, item.CraftItems, 0, item.Item, 100, item.PermItems)

        -- Bước 2: Kiểm tra thành công/thất bại
        if data.result then
            -- ✅ THÀNH CÔNG: Xóa vũ khí (nếu có) và thêm vũ khí mới
            if CurrentWeaponsToRemove and CurrentRequireData and CurrentRequireData.RemoveWeapons then
                TriggerServerEvent('vierp.craftingx:cfx:removeWeapons', CurrentWeaponsToRemove, #CurrentWeaponsToRemove)
                if Env.Debug then
                    print('DEBUG : Đã xóa ' .. #CurrentWeaponsToRemove .. ' vũ khí để nâng cấp (THÀNH CÔNG)')
                end
            end

            -- Xóa PermItems khi nâng cấp THÀNH CÔNG (nếu có)
            if item.PermItems then
                TriggerServerEvent('vierp.craftingx:cfx:remove2', data.multiply, item.PermItems)
            end

            -- Thêm vũ khí MỚI (lock+item match được kiểm tra phía server)
            TriggerServerEvent('vierp.craftingx:cfx:addWeapon', item.Item, item.WeaponLevel or 2)

            -- LOG THÀNH CÔNG
            TriggerServerEvent('vierp.craftingx:cfx:upgradeWeaponSuccess',
                item.Item,
                item.WeaponLevel or 2,
                item.CraftItems,
                item.RequireWeaponDurability,
                CurrentWeaponsToRemove
            )
        else
            -- ❌ THẤT BẠI: Unlock server lock, ghi log, trả failed items (PermItems không bị mất)
            if Env.Debug and CurrentWeaponsToRemove then
                print('DEBUG : THẤT BẠI - Giữ nguyên ' .. #CurrentWeaponsToRemove .. ' vũ khí và PermItems, chỉ mất nguyên liệu')
            end
            QBCore.Functions.Notify('Nâng cấp thất bại.', 'error')
            TriggerServerEvent('vierp.craftingx:cfx:upgradeWeaponFailed',
                item.Item,
                item.WeaponLevel or 2,
                item.CraftItems,
                item.RequireWeaponDurability,
                CurrentWeaponsToRemove
            )
            TriggerServerEvent('vierp.craftingx:cfx:getFailed', failedItems)
        end

        -- Reset biến
        CurrentWeaponsToRemove = nil
        CurrentRequireData = nil
    else
        -- Pre-calc failedItems cho item type
        local itemFailedItems = {}
        if item.Failed then
            for k, v in pairs(item.Failed) do
                math.randomseed(GetGameTimer())
                local amount = math.random(v[1], v[2])
                itemFailedItems[k] = amount
                Citizen.Wait(100)
            end
        end

        -- SECURE: Kết quả tính phía SERVER qua cfx:processResult (server tự check canCarry)
        TriggerServerEvent('vierp.craftingx:cfx:remove', data.multiply, item.Cash, item.CraftItems, 0, item.Item, item.Chance, item.PermItems)
        TriggerServerEvent('vierp.craftingx:cfx:processResult', data.multiply, item.Item, 'item', 1, itemFailedItems, item.PermItems)
    end

    cb('ok')
end)

-- Server xác nhận chế tạo thành công → hiện overlay React
RegisterNetEvent('vierp.craftingx:craftSuccess')
AddEventHandler('vierp.craftingx:craftSuccess', function()
    SendNUIMessage({ type = 'craft-success' })
end)

-- NUI Callback: Lấy danh sách vũ khí có thể sửa
RegisterNUICallback('getRepairableWeapons', function(data, cb)
    -- Using lib.callback for QBX Core compatibility
    local weapons = lib.callback.await('vierp.craftingx:callback:getRepairableWeapons', false)
    cb(weapons)
end)