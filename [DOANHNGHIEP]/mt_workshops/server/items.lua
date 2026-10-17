for _, v in pairs(Config.performance) do
    if Config.inventory == 'ox_inventory' then
        AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId)
            if name == v.item then
                local item = exports.ox_inventory:GetSlot(playerId, slotId)
                if item then
                    lib.callback.await('mt_workshops:client:usePerformanceItem', playerId, v.modType, v.item, v.level, v.class)
                end
            end
        end)
    else
        if Config.framework == 'qb' then
            Config.core.Functions.CreateUseableItem(v.item, function(source, item)
                local src = source
                local Player = Config.core.Functions.GetPlayer(src)
                if not Player.Functions.GetItemBySlot(item.slot) then return end
                lib.callback.await('mt_workshops:client:usePerformanceItem', src, v.modType, v.item, v.level, v.class)
            end)
        elseif Config.framework == 'qbx' then
            exports.qbx_core:CreateUseableItem(v.item, function(source, item)
                local src = source
                local Player = exports.qbx_core:GetPlayer(src)
                if not Player.Functions.GetItemBySlot(item.slot) then return end
                lib.callback.await('mt_workshops:client:usePerformanceItem', src, v.modType, v.item, v.level, v.class)
            end)
        elseif Config.framework == 'esx' then
            Config.core.RegisterUsableItem(v.item, function(source, item)
                local src = source
                lib.callback.await('mt_workshops:client:usePerformanceItem', src, v.modType, v.item, v.level, v.class)
            end)
        end
    end
end

local function checkPlayerMechanicOnDuty(src)
    if Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if not Player or not Player.PlayerData or not Player.PlayerData.job then return false end
        return Player.PlayerData.job.name == 'mechanic' and Player.PlayerData.job.onduty
    elseif Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if not Player or not Player.PlayerData or not Player.PlayerData.job then return false end
        return Player.PlayerData.job.name == 'mechanic' and Player.PlayerData.job.onduty
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if not Player or not Player.job then return false end
        return Player.job.name == 'mechanic'
    end
    return false
end

if Config.inventory == 'ox_inventory' then
    AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId)
        if name == 'engine_repair_kit' then
            local item = exports.ox_inventory:GetSlot(playerId, slotId)
            if item then
                lib.callback.await('mt_workshops:client:useRepairKit', playerId, 'engine')
            end
        end
    end)

    AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId)
        if name == 'body_repair_kit' then
            local item = exports.ox_inventory:GetSlot(playerId, slotId)
            if item then
                lib.callback.await('mt_workshops:client:useRepairKit', playerId, 'body')
            end
        end
    end)

    AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId)
        if name == 'mechanic_toolbox' then
            if not checkPlayerMechanicOnDuty(playerId) then
                TriggerClientEvent('mt_workshops:client:notify', playerId, 'Bạn phải là nhân viên Mechanic và đang On Duty mới có thể sử dụng hộp dụng cụ!', 'error')
                return
            end
            lib.callback.await('mt_workshops:client:openToolboxMenu', playerId)
        end
    end)
else
    if Config.framework == 'qb' and Config.inventory ~= 'ox_inventory' then
        Config.core.Functions.CreateUseableItem('mods_list', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            TriggerClientEvent('mt_workshops:client:useModsList', src, nil, item)
        end)

        Config.core.Functions.CreateUseableItem('mechanic_toolbox', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            if not checkPlayerMechanicOnDuty(src) then
                TriggerClientEvent('mt_workshops:client:notify', src, 'Bạn phải là nhân viên Mechanic và đang On Duty mới có thể sử dụng hộp dụng cụ!', 'error')
                return
            end
            lib.callback.await('mt_workshops:client:openToolboxMenu', src)
        end)

        Config.core.Functions.CreateUseableItem('neons_controller', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            lib.callback.await('mt_workshops:client:openLightsController', src)
        end)

        Config.core.Functions.CreateUseableItem('extras_controller', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            lib.callback.await('mt_workshops:client:openExtrasMenu', src)
        end)

        Config.core.Functions.CreateUseableItem('engine_repair_kit', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            lib.callback.await('mt_workshops:client:useRepairKit', src, 'engine')
        end)

        Config.core.Functions.CreateUseableItem('body_repair_kit', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            lib.callback.await('mt_workshops:client:useRepairKit', src, 'body')
        end)
    elseif Config.framework == 'qb' and Config.inventory == 'ox_inventory' then
        Config.core.Functions.CreateUseableItem('engine_repair_kit', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            lib.callback.await('mt_workshops:client:useRepairKit', src, 'engine')
        end)

        Config.core.Functions.CreateUseableItem('body_repair_kit', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            if not Player.Functions.GetItemBySlot(item.slot) then return end
            lib.callback.await('mt_workshops:client:useRepairKit', src, 'body')
        end)
    elseif Config.framework == 'esx' then
        Config.core.RegisterUsableItem('engine_repair_kit', function(source, item)
            local src = source
            lib.callback.await('mt_workshops:client:useRepairKit', src, 'engine')
        end)

        Config.core.RegisterUsableItem('body_repair_kit', function(source, item)
            local src = source
            lib.callback.await('mt_workshops:client:useRepairKit', src, 'body')
        end)
    end
end

-- Tuner Pad Item for Preview Menu
if Config.preview.useItem then
    if Config.inventory == 'ox_inventory' then
        AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId)
            if name == Config.preview.item then
                local item = exports.ox_inventory:GetSlot(playerId, slotId)
                if item then
                    TriggerClientEvent('mt_workshops:client:openPreviewMenu', playerId)
                end
            end
        end)
    else
        if Config.framework == 'qb' then
            Config.core.Functions.CreateUseableItem(Config.preview.item, function(source, item)
                local src = source
                local Player = Config.core.Functions.GetPlayer(src)
                if not Player.Functions.GetItemBySlot(item.slot) then return end
                
                TriggerClientEvent('mt_workshops:client:openPreviewMenu', src)
            end)
        elseif Config.framework == 'qbx' then
            exports.qbx_core:CreateUseableItem(Config.preview.item, function(source, item)
                local src = source
                local Player = exports.qbx_core:GetPlayer(src)
                if not Player.Functions.GetItemBySlot(item.slot) then return end
                
                TriggerClientEvent('mt_workshops:client:openPreviewMenu', src)
            end)
        elseif Config.framework == 'esx' then
            Config.core.RegisterUsableItem(Config.preview.item, function(source, item)
                local src = source
                TriggerClientEvent('mt_workshops:client:openPreviewMenu', src)
            end)
        end
    end
end

-- Hóa đơn sửa xe
if Config.inventory == 'ox_inventory' then
    AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId)
        if name == 'hoadonsuaxe' then
            local item = exports.ox_inventory:GetSlot(playerId, slotId)
            if item then
                TriggerClientEvent('mt_workshops:client:useRepairInvoice', playerId, slotId, item.metadata or {})
            end
        end
    end)
else
    if Config.framework == 'qb' then
        Config.core.Functions.CreateUseableItem('hoadonsuaxe', function(source, item)
            local src = source
            local Player = Config.core.Functions.GetPlayer(src)
            local itemData = Player.Functions.GetItemBySlot(item.slot)
            if not itemData then return end
            TriggerClientEvent('mt_workshops:client:useRepairInvoice', src, item.slot, itemData.info or itemData.metadata or {})
        end)
    elseif Config.framework == 'qbx' then
        exports.qbx_core:CreateUseableItem('hoadonsuaxe', function(source, item)
            local src = source
            local Player = exports.qbx_core:GetPlayer(src)
            local itemData = Player.Functions.GetItemBySlot(item.slot)
            if not itemData then return end
            TriggerClientEvent('mt_workshops:client:useRepairInvoice', src, item.slot, itemData.info or itemData.metadata or {})
        end)
    elseif Config.framework == 'esx' then
        Config.core.RegisterUsableItem('hoadonsuaxe', function(source, item)
            local src = source
            TriggerClientEvent('mt_workshops:client:useRepairInvoice', src, nil, item.metadata or item.info or {})
        end)
    end
end