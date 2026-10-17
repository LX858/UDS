local QBX = exports.qbx_core



-- Callback mua chổi
lib.callback.register('xn_quetrac:server:buyBroom', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    local money = player.PlayerData.money.cash
    if money >= Config.BroomShop.price then
        -- Kiểm tra sức chứa
        local canCarry = exports.ox_inventory:CanCarryItem(source, Config.Items.broom, 1, {durability = 100})
        if not canCarry then
            return false
        end
        
        player.Functions.RemoveMoney('cash', Config.BroomShop.price, 'trash-collector-buy-broom')
        exports.ox_inventory:AddItem(source, Config.Items.broom, 1, {durability = 100})
        return true
    end
    
    return false
end)

-- Callback nhặt rác
lib.callback.register('xn_quetrac:server:collectTrash', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    -- Kiểm tra nếu player đang on duty với job police, ambulance, hoặc cardealer
    -- if player.PlayerData.job and player.PlayerData.job.name then
    --     local blockedJobs = {
    --         ['police'] = true,
    --         ['ambulance'] = true,
    --         ['cardealer'] = true
    --     }
        
    --     -- Chỉ chặn nếu player có job trong danh sách VÀ đang on-duty
    --     if blockedJobs[player.PlayerData.job.name] and player.PlayerData.job.onduty then
    --         TriggerClientEvent('ox_lib:notify', source, {
    --             title = 'Dọn Rác',
    --             description = 'Bạn đang làm việc, không thể nhặt rác!',
    --             type = 'error'
    --         })
    --         return false
    --     end
    -- end
    
    -- Kiểm tra sức chứa
    local canCarry = exports.ox_inventory:CanCarryItem(source, Config.Items.trash, 1)
    if not canCarry then
        return false
    end
    
    -- Thêm rác vào inventory
    --event--
    -- local tile2 = math.random(1, 100)
    -- if tile2 > 1 and tile2 < 11 then
    --     local tiletrong = math.random(100)
    --     if tiletrong <= 25 then
    --         exports.ox_inventory:AddItem(source, 'manhghep1', 1)
    --     elseif tiletrong <= 50 then
    --         exports.ox_inventory:AddItem(source, 'manhghep2', 1)
    --     elseif tiletrong <= 75 then
    --         exports.ox_inventory:AddItem(source, 'manhghep4', 1)
    --     else
    --         exports.ox_inventory:AddItem(source, 'manhghep5', 1)
    --     end
    -- end
    exports.ox_inventory:AddItem(source, Config.Items.trash, 1)

    local currentRep = player.PlayerData.metadata['reputation'] or 0
    if currentRep < 100 then
        local newRepValue = currentRep + 1
        if newRepValue > 100 then newRepValue = 100 end
        player.Functions.SetMetaData('reputation', newRepValue)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Uy Tín',
            description = ('Bạn được cộng 1 điểm uy tín (%d/100)'):format(newRepValue),
            type = 'success'
        })
    end

    return true
end)

-- Callback xử lý rác
lib.callback.register('xn_quetrac:server:recycleTrash', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    -- Kiểm tra nếu player đang on duty với job police, ambulance, hoặc cardealer
    if player.PlayerData.job and player.PlayerData.job.name then
        local blockedJobs = {
            ['police'] = true,
            ['ambulance'] = true,
            ['cardealer'] = true
        }
        
        -- Chỉ chặn nếu player có job trong danh sách VÀ đang on-duty
        if blockedJobs[player.PlayerData.job.name] and player.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Dọn Rác',
                description = 'Bạn đang làm việc, không thể xử lý rác!',
                type = 'error'
            })
            return false
        end
    end
    
    -- Kiểm tra có rác không
    local trashItem = player.Functions.GetItemByName(Config.Items.trash)
    if not trashItem then
        return false
    end
    
    local trashAmount = trashItem.amount
    if trashAmount <= 0 then
        return false
    end
    
    -- Chỉ xử lý 1 rác mỗi lần
    exports.ox_inventory:RemoveItem(source, Config.Items.trash, 1)
    
    -- Tính toán phần thưởng cho 1 rác (mặc định 1 nhựa)
    local plasticAmount = Config.Rewards.recyclePlastic.amount
    
    -- Nhận nhựa tái chế
    local canCarryPlastic = exports.ox_inventory:CanCarryItem(source, Config.Rewards.recyclePlastic.item, plasticAmount)
    if not canCarryPlastic then
        exports.ox_inventory:AddItem(source, Config.Items.trash, 1)
        return false
    end
    exports.ox_inventory:AddItem(source, Config.Rewards.recyclePlastic.item, plasticAmount)
    
    return true, {
        plastic = plasticAmount,
        rare = false,
        rareItem = nil
    }
end)