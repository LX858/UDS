Inventory = Inventory or {};

if Config.Inventory ~= 'qb-inventory' then
    return
end

function Inventory:Init()
    while GetResourceState('qb-inventory') ~= 'started' do
        Wait(100)
    end

    QBCore = QBCore or exports['qb-core']:GetCoreObject()

    for _, v in pairs(Main.usableItems) do
        QBCore.Functions.CreateUseableItem(v.name, function(src, item)
            item.metadata = item.info or {}

            v.use(src, item)
        end)
    end
end

function Inventory:getPlayerItemsCount(src)
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        return false
    end

    local inventory = player.PlayerData.items

    if not inventory then
        return false
    end

    local items = {}

    for _, v in pairs(inventory) do
        if not items[v.name] then
            items[v.name] = v.amount
        else
            items[v.name] = items[v.name] + v.amount
        end
    end

    return items
end

function Inventory:getPlayerInventory(src)
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        return {}
    end

    local inventory = player.PlayerData.items

    if not inventory then
        return {}
    end

    local items = {}

    for _, v in pairs(inventory) do
        table.insert(items, {
            item = v.name,
            slot = v.slot,
            quantity = v.amount,
            metadata = v.info,
        })
    end

    return items
end

function Inventory:addPlayerItem(src, item, amount, metadata, options)
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        return {}
    end

    if options then
        metadata = metadata or {}

        if options.description then
            metadata.description = options.description
        end

        if options.label then
            metadata.label = options.label
        end
    end

    if amount > 1 and items and items[item]?.unique then
        -- Give multiple unique items one by one to prevent duplicated metadata

        for i = 1, amount do
            if not exports['qb-inventory']:AddItem(src, item, 1, false, metadata or false, 'bablo_chopshop:addPlayerItem') then
                return false
            end
        end
    else
        local res = exports['qb-inventory']:AddItem(src, item, amount, false, metadata or false,
            'bablo_chopshop:addPlayerItem')

        if not res then
            return false
        end
    end

    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add', amount)

    if Player(src).state.inv_busy then
        TriggerClientEvent('qb-inventory:client:updateInventory', src)
    end

    return true
end

function Inventory:removePlayerItem(src, item, amount)
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        return false
    end

    local res = exports['qb-inventory']:RemoveItem(src, item, amount, false, 'bablo_chopshop:removePlayerItem')

    if res then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove', amount)

        if Player(src).state.inv_busy then
            TriggerClientEvent('qb-inventory:client:updateInventory', src)
        end
    end

    return res
end

function Inventory:getSpecificPlayerItem(src, data)
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        return false
    end

    local item = exports['qb-inventory']:GetItemBySlot(src, data.slot)

    if not item then
        return false
    end

    return {
        item = item.name,
        metadata = item.info,
    }
end

function Inventory:removeSpecificPlayerItem(src, data, amount)
    local player = QBCore?.Functions.GetPlayer(src)

    if not player then
        return false
    end

    local res = exports['qb-inventory']:RemoveItem(src, data.item, amount, data.slot,
        'bablo_chopshop:removePlayerItem')

    if res then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[data.item], 'remove', amount)

        if Player(src).state.inv_busy then
            TriggerClientEvent('qb-inventory:client:updateInventory', src)
        end
    end

    return res
end

function Inventory:setMetadata(src, data, metadata)
    local player = QBCore.Functions.GetPlayer(src)

    if not player then
        return false
    end

    local item = player.PlayerData.items[data.slot]
    if not item then
        return false
    end

    item.info = metadata

    player.Functions.SetPlayerData("items", player.PlayerData.items)

    if Player(src).state.inv_busy then
        TriggerClientEvent('inventory:client:UpdatePlayerInventory', src, false)
    end

    return true
end

function Inventory:canCarryItem(src, item, amount)
    local canAdd, reason = exports['qb-inventory']:CanAddItem(src, item, amount)

    return canAdd
end