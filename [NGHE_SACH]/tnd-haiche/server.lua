local QBCore = exports['qb-core']:GetCoreObject()

-- Trừ 5% độ bền cái rổ đang dùng (theo slot), xoá đúng slot khi hết bền
local function reduceDurability(src)
    if not Config.ItemRequire then return end
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    if not inventory then return end

    local targetSlot = nil
    local targetDurability = nil

    for _, slot in pairs(inventory) do
        if slot.name == Config.ItemRequireName then
            local dur = (slot.metadata and slot.metadata.durability) or 100
            if targetSlot == nil or dur < targetDurability then
                targetSlot = slot.slot
                targetDurability = dur
            end
        end
    end

    if not targetSlot then return end

    local newDurability = targetDurability - 5

    if newDurability <= 0 then
        exports.ox_inventory:RemoveItem(src, Config.ItemRequireName, 1, nil, targetSlot)
        TriggerClientEvent('QBCore:Notify', src, 'Rổ của bạn đã hỏng!', 'error')
    else
        exports.ox_inventory:SetMetadata(src, targetSlot, { durability = newDurability })
        if newDurability <= 20 then
            TriggerClientEvent('QBCore:Notify', src, 'Rổ sắp hỏng! Độ bền còn ' .. math.floor(newDurability) .. '%', 'error')
        end
    end
end

-- tắt tính năng rổ hái chè
-- QBCore.Functions.CreateUseableItem("rodungche", function(source, item)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if Player.Functions.GetItemBySlot(item.slot) ~= nil then
--         TriggerClientEvent("Nos-haiche:roHai", source)
--         TriggerClientEvent('Nos-haiche:client:dobenRoHai', source, item.slot)
--     end
-- end)

RegisterNetEvent('Nos-haiche:server:startHarvest')
AddEventHandler('Nos-haiche:server:startHarvest', function()
    local src = source
    TriggerClientEvent('Nos-haiche:roHai', src)
end)

RegisterServerEvent('Nos-haiche:giveItems')
AddEventHandler('Nos-haiche:giveItems', function()
    local src = source
    exports.ox_inventory:AddItem(src, 'la_che', 1)
    reduceDurability(src)
end) 

