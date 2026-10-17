QBCore = exports['qb-core']:GetCoreObject()

CanAddItem = function(src, item, qty)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:CanCarryItem(src, item, qty)
    end

    if GetResourceState('qs-inventory') == 'started' then
        return exports['qs-inventory']:CanCarryItem(src, item, qty)
    end

    if QBCore.Functions.CanAddItem then
        local canAdd = QBCore.Functions.CanAddItem(src, item, qty)
        if canAdd ~= nil then return canAdd end
    end

    if Player.Functions.CanAddItem then
        local canAdd = Player.Functions.CanAddItem(item, qty)
        if canAdd ~= nil then return canAdd end
    end

    if Player.PlayerData and Player.PlayerData.items then
        local currentWeight = 0
        for _, itemData in pairs(Player.PlayerData.items) do
            if itemData and itemData.weight and itemData.amount then
                currentWeight = currentWeight + (itemData.weight * itemData.amount)
            end
        end

        local itemInfo = QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[item:lower()]
        local itemWeight = (itemInfo and itemInfo.weight) or 0
        local maxWeight = Player.PlayerData.maxWeight or (QBCore.Config and QBCore.Config.Player and QBCore.Config.Player.MaxWeight) or 120000

        if (currentWeight + (itemWeight * qty)) > maxWeight then
            return false
        end
    end

    return true
end

AddItem = function(src, item, qty)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end

    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(src, item, qty)
    end

    if Player.Functions.AddItem(item, qty) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add")
        return true
    end
    return false
end

RemoveItem = function(src, item, qty)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.Functions.RemoveItem(item, qty) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "remove")
        return true
    end
    return false
end

AddMoney = function(src, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney('cash', amount)
end


Notify = function(src, msg, type)
    TriggerClientEvent('QBCore:Notify', src, msg, type)
end

function MAIN:CallbackHander()
    QBCore.Functions.CreateCallback('ds-drilling:callback:getPlatformData', function(source, cb, index)
        self.Platforms[index]:Join(source)
        cb(self.Platforms[index])
    end)
end

