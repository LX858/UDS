Inventory = Inventory or {};

if Config.Inventory ~= 'ox_inventory' then
    return
end

    local ox_inventory = exports.ox_inventory

    function Inventory:Init()
        while GetResourceState('ox_inventory') ~= 'started' do
            Wait(100)
        end

        if Config.Framework == 'esx' then
            ESX = ESX or exports['es_extended']:getSharedObject()

            for _, v in pairs(Main.usableItems) do
                ESX.RegisterUsableItem(v.name, function(src, name, item)
                    v.use(src, item)
                end)
            end
        elseif Config.Framework == 'qbcore' then
            QBCore = QBCore or exports['qb-core']:GetCoreObject()

            for _, v in pairs(Main.usableItems) do
                QBCore.Functions.CreateUseableItem(v.name, function(src, item)
                    v.use(src, item)
                end)
            end
        elseif Config.Framework == 'qbox' then
            for _, v in pairs(Main.usableItems) do
                exports.qbx_core:CreateUseableItem(v.name, function(src, item)
                    v.use(src, item)
                end)
            end
        elseif Config.Framework == 'oxcore' then
            for _, v in pairs(Main.usableItems) do
                ox_inventory:CreateUsableItem(v.name, function(src, item)
                    v.use(src, item)
                end)
            end
        else
            Trace('Unsupported framework for ox_inventory')
        end
    end

    local items = nil

    function Inventory:getItems()
        if not items then
            items = {}

            for k, v in pairs(ox_inventory:Items()) do
                table.insert(items, {
                    name = k,
                    label = v.label or k,
                    description = v.description,
                    weight = v.weight or 0,
                    image = 'nui://ox_inventory/web/images/' .. (v.client?.image or k .. '.png'),
                    unique = v.stack == false or v.unique
                })
            end
        end

        return items
    end

    function Inventory:getPlayerItemsCount(src)
        local inventory = ox_inventory:GetInventory(src)

        if not inventory then
            return false
        end

        local items = {}

        for _, v in pairs(inventory.items) do
            if not items[v.name] then
                items[v.name] = v.count
            else
                items[v.name] = items[v.name] + v.count
            end
        end

        return items
    end

    function Inventory:getPlayerInventory(src)
        local inventory = ox_inventory:GetInventory(src)

        if not inventory then
            return false
        end

        local items = {}

        for _, v in pairs(inventory.items) do
            table.insert(items, {
                item = v.name,
                slot = v.slot,
                quantity = v.count,
                metadata = v.metadata,
            })
        end

        return items
    end

    function Inventory:addPlayerItem(src, item, amount, metadata, options)
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
                if not ox_inventory:AddItem(src, item, 1, metadata) then
                    return false
                end
            end

            return true
        end

        return ox_inventory:AddItem(src, item, amount, metadata)
    end

    function Inventory:removePlayerItem(src, item, amount)
        return ox_inventory:RemoveItem(src, item, amount)
    end

    function Inventory:getSpecificPlayerItem(src, data)
        local slot = ox_inventory:GetSlot(src, data.slot)

        if slot then
            return {
                item = slot.name,
                metadata = slot.metadata,
            }
        end

        return false
    end

    function Inventory:removeSpecificPlayerItem(src, data, amount)
        return ox_inventory:RemoveItem(src, data.item, amount, nil, data.slot)
    end

    function Inventory:setMetadata(src, data, metadata)
        local beforeItem = ox_inventory:GetSlot(src, data.slot)
        local beforeMetadata = beforeItem and beforeItem.metadata or {}

        ox_inventory:SetMetadata(src, data.slot, metadata)

        local afterItem = ox_inventory:GetSlot(src, data.slot)
        local afterMetadata = afterItem and afterItem.metadata or {}

        local success = afterItem ~= nil


        return success
    end

    function Inventory:canCarryItems(src, items)
        local totalWeight = 0

        for _, v in pairs(items) do
            local name, amount = v.name, v.amount or 1

            for _, item in pairs(getItems()) do
                if item.name == name then
                    totalWeight = totalWeight + item.weight * amount
                    break
                end
            end
        end

        local canCarryWeight = ox_inventory:CanCarryWeight(src, totalWeight)

        return canCarryWeight
    end