if Config.inventory == 'ox_inventory' then
    lib.callback.register('mt_workshops:server:registerStash', function(source, id, label, slots, weight)
        return exports.ox_inventory:RegisterStash(id, label, slots, weight)
    end)

    lib.callback.register('mt_workshops:server:registerCraft', function(source, id, items, label)
        return exports.ox_inventory:RegisterCraftStation(id, { items = items, label = label })
    end)
end

if Config.inventory ~= 'ox_inventory' and Config.framework == 'qb' then
    lib.callback.register('mt_workshops:server:GetItemCount', function(source, item)
        local src = source
        local Player = Config.core.Functions.GetPlayer(src)
        if not Player then return end
        if Player.Functions.GetItemByName(item) then
            return Player.Functions.GetItemByName(item).amount
        end
        return 0
    end)

    lib.callback.register('mt_workshops:server:openShop', function(source, id, label)
        local src = source
        exports[Config.inventory]:OpenShop(src, id)
        return true
    end)

    lib.callback.register('mt_workshops:server:openStash', function(source, id, data)
        local src = source
        exports[Config.inventory]:OpenInventory(src, id, data)
        return true
    end)
end

if Config.framework == 'esx' then
    lib.callback.register('mt_workshops:server:getPlayerJobESX', function(source)
        local src = source
        local Player = Config.core.GetPlayerFromId(src)
        if not Player then return end
        return Player.getJob().name
    end)

    lib.callback.register('mt_workshops:server:getPlayerJobIsBossESX', function(source)
        local src = source
        local Player = Config.core.GetPlayerFromId(src)
        if not Player then return end
        return (Player.getJob().grade_name == 'boss')
    end)
end

lib.callback.register('mt_workshops:server:removeItem', function(source, item, count, slot)
    local src = source

    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:RemoveItem(src, item, count, nil, slot or nil)
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        Player.Functions.RemoveItem(item, count, slot or nil)
    end
end)

lib.callback.register('mt_workshops:server:addItem', function(source, item, count, metadata)
    local src = source
    local validItem = isValidItem(item)
    if not validItem then return end

    if not Player(src).state.workshopCurrentVehicle then return end

    local vehCoords = GetEntityCoords(NetworkGetEntityFromNetworkId(Player(src).state.workshopCurrentVehicle))
    local pedCoords = GetEntityCoords(GetPlayerPed(src))
    if (not (type(vehCoords) == 'vector3' or type(vehCoords) == 'vector4')) or (not (type(pedCoords) == 'vector3' or type(pedCoords) == 'vector4')) then return end

    local distance = #(pedCoords - vehCoords)
    if not (distance < 20.0) then return end

    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:AddItem(src, item, count, metadata)
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        Player.Functions.AddItem(item, count, nil, metadata)
    end
end)

lib.callback.register('mt_workshops:server:canCraftItem', function(source, ingredients)
    local src = source
    local haveCount = 0
    if Config.inventory == 'ox_inventory' then
        for k, v in pairs(ingredients) do
            if exports.ox_inventory:GetItemCount(src, v.name) >= v.count then haveCount += 1 end
        end
    elseif Config.framework == 'qb' then
        for k, v in pairs(ingredients) do
            local Player = Config.core.Functions.GetPlayer(src)
            local item = Player.Functions.GetItemByName(v.name)
            if item and item.amount >= v.count then haveCount += 1 end
        end
    end
    return (haveCount == #ingredients)
end)

lib.callback.register('mt_workshops:server:craftItem', function(source, item, count, ingredients)
    local src = source
    ingredients = isValidCraftItem(item)

    if not ingredients then return false end

    if Config.inventory == 'ox_inventory' then
        for k, v in pairs(ingredients) do
            exports.ox_inventory:RemoveItem(src, v.name, v.count)
        end
        exports.ox_inventory:AddItem(src, item, count)
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        for k, v in pairs(ingredients) do
            Player.Functions.RemoveItem(v.name, v.count)
        end
        Player.Functions.AddItem(item, count)
    end
    return true
end)

lib.callback.register('mt_workshops:server:setItemMetadata', function(source, item, slot, metadata)
    local src = source
    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:SetMetadata(src, slot, metadata)
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        Player.Functions.RemoveItem(item, slot)
        Player.Functions.AddItem(item, 1, slot, metadata)
    end
end)

lib.callback.register('mt_workshops:server:checkAllMetadataItemIsDone', function(source, plate)
    local src = source
    if Config.inventory == 'ox_inventory' then
        local items = exports.ox_inventory:GetInventoryItems(src)
        local counter = 0
        for k, v in pairs(items) do
            if v.name == 'mods_list' then
                if v.metadata.plate == plate then
                    for mk, mv in pairs(v.metadata.modsList) do
                        if mv.applied then counter += 1 end
                    end
                    return (counter == #v.metadata.modsList)
                end
            end
        end
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        local items = Player.PlayerData.items
        local counter = 0
        for k, v in pairs(items) do
            if v.name == 'mods_list' then
                if v.info.plate == plate then
                    for mk, mv in pairs(v.info.modsList) do
                        if mv.applied then counter += 1 end
                    end
                    return (counter == #v.info.modsList)
                end
            end
        end
    end
end)

lib.callback.register('mt_workshops:server:checkCanRepair', function(source, price)
    local src = source
    if Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if not Player then return false end

        return (Player.Functions.GetMoney('cash') >= price)
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if not Player then return false end

        return (Player.getMoney() >= price)
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if not Player then return false end

        return (Player.Functions.GetMoney('cash') >= price)
    end
    return false
end)

lib.callback.register('mt_workshops:server:checkItemAndMoney', function(source, item, count, money)
    local src = source
    local hasItem = false
    local hasMoney = false
    
    -- 1. Check Item
    if Config.inventory == 'ox_inventory' then
        hasItem = exports.ox_inventory:GetItemCount(src, item) >= count
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if Player then
            local pItem = Player.Functions.GetItemByName(item)
            hasItem = pItem and pItem.amount >= count
        end
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            local pItem = Player.Functions.GetItemByName(item)
            hasItem = pItem and pItem.amount >= count
        end
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if Player then
            local pItem = Player.getInventoryItem(item)
            hasItem = pItem and pItem.count >= count
        end
    end
    
    -- 2. Check Money (Cash)
    if not money or money <= 0 then
        hasMoney = true
    else
        if Config.framework == 'qb' then
            local Player = Config.core.Functions.GetPlayer(src)
            if Player then hasMoney = Player.PlayerData.money['cash'] >= money end
        elseif Config.framework == 'esx' then
            local Player = Config.core.GetPlayerFromId(src)
            if Player then hasMoney = Player.getMoney() >= money end
        elseif Config.framework == 'qbx' then
            local Player = exports.qbx_core:GetPlayer(src)
            if Player then hasMoney = Player.PlayerData.money['cash'] >= money end
        end
    end
    
    return hasItem and hasMoney
end)

lib.callback.register('mt_workshops:server:removeItemAndMoney', function(source, item, count, money, slot)
    local src = source
    local Player = nil
    
    -- 1. Remove Item
    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:RemoveItem(src, item, count, nil, slot or nil)
    elseif Config.framework == 'qb' then
        Player = Config.core.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(item, count, slot or nil)
        end
    elseif Config.framework == 'qbx' then
        Player = exports.qbx_core:GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(item, count, slot or nil)
        end
    elseif Config.framework == 'esx' then
        Player = Config.core.GetPlayerFromId(src)
        if Player then
            Player.removeInventoryItem(item, count)
        end
    end
    
    -- 2. Remove Money (Cash)
    if money and money > 0 then
        local removed = false
        if Config.framework == 'qb' then
            Player = Player or Config.core.Functions.GetPlayer(src)
            if Player then removed = Player.Functions.RemoveMoney('cash', money, 'cosmetic-tuning') end
        elseif Config.framework == 'esx' then
            Player = Player or Config.core.GetPlayerFromId(src)
            if Player then
                Player.removeMoney(money, 'cosmetic-tuning')
                removed = true
            end
        elseif Config.framework == 'qbx' then
            Player = Player or exports.qbx_core:GetPlayer(src)
            if Player then removed = Player.Functions.RemoveMoney('cash', money, 'cosmetic-tuning') end
        end

        if removed then
            pcall(function()
                exports['Renewed-Banking']:addAccountMoney('bcso', money)
            end)
        end
    end
    return true
end)