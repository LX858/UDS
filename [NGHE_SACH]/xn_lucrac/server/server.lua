local QBCore = exports['qb-core']:GetCoreObject()

-- Server-side events
exports['monitors']:RegisterProtectedEvent('xn_lucrac:searchTrash', function(src, coords)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Calculate what items to give - only ONE item per search
    local foundItem = nil
    local totalChance = 0
    
    -- Calculate total chance
    for _, itemData in pairs(Config.ItemsToFind) do
        totalChance = totalChance + itemData.chance
    end
    
    -- Random number to select item
    local randomNum = math.random(1, totalChance)
    local currentChance = 0
    
    -- Find which item to give based on weighted random
    for _, itemData in pairs(Config.ItemsToFind) do
        currentChance = currentChance + itemData.chance
        if randomNum <= currentChance then
            local amount = itemData.amount
            if type(amount) == 'table' then
                amount = math.random(amount[1], amount[2])
            end
            
            foundItem = {
                item = itemData.item,
                amount = amount,
                info = itemData.info
            }
            break
        end
    end
    
    -- Give item to player
    if foundItem then
        -- Check if player can carry the item (weight check)
        local canCarry = false
        if exports.ox_inventory then
            canCarry = exports.ox_inventory:CanCarryItem(src, foundItem.item, foundItem.amount)
        else
            -- Fallback for QBCore inventory
            canCarry = Player.Functions.AddItem(foundItem.item, foundItem.amount, false, foundItem.info, true) -- dry run
        end
        
        if canCarry then
            if exports.ox_inventory then
                exports.ox_inventory:AddItem(src, foundItem.item, foundItem.amount)
            else
                Player.Functions.AddItem(foundItem.item, foundItem.amount, false, foundItem.info)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[foundItem.item], "add", foundItem.amount)
            end
            TriggerClientEvent('QBCore:Notify', src, 'Bạn đã tìm thấy ' .. foundItem.amount .. 'x ' .. foundItem.item .. ' trong thùng rác!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Kho đồ của bạn đã đầy! Không thể nhận thêm vật phẩm.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không tìm thấy gì trong thùng rác.', 'error')
    end
end)

-- Refining system
RegisterServerEvent('xn_lucrac:refineItem')
AddEventHandler('xn_lucrac:refineItem', function(recipe)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local recipeData = Config.RefiningRecipes[recipe]
    if not recipeData then return end
    
    -- Check if player has enough input items using ox_inventory
    local itemCount = 0
    if exports.ox_inventory then
        -- Try different methods to get item count
        local success, result = pcall(function()
            return exports.ox_inventory:Search(src, 'count', recipeData.input)
        end)
        if success then
            itemCount = result or 0
        else
            -- Fallback method
            local item = exports.ox_inventory:GetItem(src, recipeData.input)
            itemCount = item and item.count or 0
        end
    else
        -- Fallback to QBCore inventory
        local hasItem = Player.Functions.GetItemByName(recipeData.input)
        itemCount = hasItem and hasItem.amount or 0
    end
    
    if itemCount < recipeData.inputAmount then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có đủ ' .. recipeData.input .. ' để tinh luyện!', 'error')
        return
    end
    
    -- Remove input items
    if exports.ox_inventory then
        exports.ox_inventory:RemoveItem(src, recipeData.input, recipeData.inputAmount)
    else
        Player.Functions.RemoveItem(recipeData.input, recipeData.inputAmount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[recipeData.input], "remove", recipeData.inputAmount)
    end
    
    -- Check if player can carry the output item
    local canCarry = false
    if exports.ox_inventory then
        canCarry = exports.ox_inventory:CanCarryItem(src, recipeData.output, recipeData.outputAmount)
    else
        -- Fallback for QBCore inventory
        canCarry = Player.Functions.AddItem(recipeData.output, recipeData.outputAmount, false, {}, true) -- dry run
    end
    
    -- Add output items
    if canCarry then
        if exports.ox_inventory then
            exports.ox_inventory:AddItem(src, recipeData.output, recipeData.outputAmount)
        else
            Player.Functions.AddItem(recipeData.output, recipeData.outputAmount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[recipeData.output], "add", recipeData.outputAmount)
        end
        TriggerClientEvent('QBCore:Notify', src, 'Tinh luyện thành công! Bạn nhận được ' .. recipeData.outputAmount .. ' ' .. recipeData.output, 'success')
    else
        -- If can't carry, give back the input items
        if exports.ox_inventory then
            exports.ox_inventory:AddItem(src, recipeData.input, recipeData.inputAmount)
        else
            Player.Functions.AddItem(recipeData.input, recipeData.inputAmount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[recipeData.input], "add", recipeData.inputAmount)
        end
        TriggerClientEvent('QBCore:Notify', src, 'Kho đồ của bạn đã đầy! Không thể nhận vật phẩm tinh luyện. Đã hoàn trả nguyên liệu.', 'error')
    end
end)
