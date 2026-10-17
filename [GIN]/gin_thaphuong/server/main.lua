local function GetPlayerData(src)
    -- 1. Thử qua export qbx_core
    if GetResourceState('qbx_core') == 'started' then
        local success, result = pcall(function() return exports.qbx_core:GetPlayer(src) end)
        if success and result then return result end
    end

    -- 2. Thử qua export qb-core
    if GetResourceState('qb-core') == 'started' then
        local success, result = pcall(function()
            local QBCore = exports['qb-core']:GetCoreObject()
            return QBCore and QBCore.Functions and QBCore.Functions.GetPlayer(src)
        end)
        if success and result then return result end
    end

    -- 3. Thử qua global QBCore
    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
        local success, result = pcall(function() return QBCore.Functions.GetPlayer(src) end)
        if success and result then return result end
    end

    return nil
end

local function getPlayerReputation(source)
    local defaultRep = (Config.ReputationSystem and Config.ReputationSystem.defaultReputation) or 100
    local player = GetPlayerData(source)
    if not player then return defaultRep end
    
    local metadata = player.PlayerData and player.PlayerData.metadata
    if not metadata then return defaultRep end
    
    -- Kiểm tra và khởi tạo metadata nếu chưa có (nil)
    if metadata.reputation == nil then
        if player.Functions and player.Functions.SetMetaData then
            player.Functions.SetMetaData('reputation', defaultRep)
        end
        return defaultRep
    end
    
    return metadata.reputation
end

local function HasItem(src, itemName, amount)
    amount = amount or 1

    -- 1. Thử qua ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        local success, count = pcall(function() return exports.ox_inventory:GetItemCount(src, itemName) end)
        if success and count then return count >= amount end
    end

    -- 2. Thử qua export qbx_core
    if GetResourceState('qbx_core') == 'started' then
        local success, has = pcall(function() return exports.qbx_core:HasItem(src, itemName, amount) end)
        if success and has ~= nil then return has end
    end

    -- 3. Thử qua Player object (QBCore / QBX)
    local player = GetPlayerData(src)
    if player then
        if player.Functions and player.Functions.GetItemByName then
            local item = player.Functions.GetItemByName(itemName)
            return item and (item.amount or item.count or 0) >= amount
        elseif player.PlayerData and player.PlayerData.items then
            for _, item in pairs(player.PlayerData.items) do
                if item and item.name == itemName then
                    return (item.amount or item.count or 0) >= amount
                end
            end
        end
    end

    return false
end

local function RemoveItem(src, itemName, amount)
    amount = amount or 1

    -- 1. Thử qua ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        local success, removed = pcall(function() return exports.ox_inventory:RemoveItem(src, itemName, amount) end)
        if success and removed then return removed end
    end

    -- 2. Thử qua export qbx_core
    if GetResourceState('qbx_core') == 'started' then
        local success, removed = pcall(function() return exports.qbx_core:RemoveItem(src, itemName, amount) end)
        if success and removed then return removed end
    end

    -- 3. Thử qua Player object (QBCore / QBX)
    local player = GetPlayerData(src)
    if player and player.Functions and player.Functions.RemoveItem then
        local success, removed = pcall(function() return player.Functions.RemoveItem(itemName, amount) end)
        if success then return removed end
    end

    return false
end

-- Đăng ký Usable Item cay_huong & cay_huong_luxury cho QB-Core / QBX
CreateThread(function()
    local incenseTypes = Config.IncenseTypes or {}
    for itemCode, _ in pairs(incenseTypes) do
        if GetResourceState('qb-core') == 'started' then
            local pcallOk, QBCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if pcallOk and QBCore and QBCore.Functions and QBCore.Functions.CreateUseableItem then
                QBCore.Functions.CreateUseableItem(itemCode, function(source, item)
                    TriggerClientEvent('gin_thaphuong:client:useIncenseItem', source, itemCode)
                end)
            end
        end

        if GetResourceState('qbx_core') == 'started' then
            if exports.qbx_core and exports.qbx_core.CreateUseableItem then
                pcall(function()
                    exports.qbx_core:CreateUseableItem(itemCode, function(source, item)
                        TriggerClientEvent('gin_thaphuong:client:useIncenseItem', source, itemCode)
                    end)
                end)
            end
        end
    end
end)

RegisterNetEvent('gin_thaphuong:server:requestPray', function(locationIdx, specifiedItemType)
    local src = source

    if not Config.RequireItem then
        local defaultType = specifiedItemType or Config.DefaultIncenseType or 'cay_huong'
        TriggerClientEvent('gin_thaphuong:client:startPray', src, locationIdx, defaultType)
        return
    end

    -- Nếu đã chỉ định loại hương cụ thể (khi dùng từ túi đồ hoặc chọn menu)
    if specifiedItemType and Config.IncenseTypes and Config.IncenseTypes[specifiedItemType] then
        local info = Config.IncenseTypes[specifiedItemType]
        local itemAmount = info.amount or 1
        local itemLabel = info.label or specifiedItemType

        if not HasItem(src, specifiedItemType, itemAmount) then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Thiếu vật phẩm',
                description = string.format('Bạn cần có %s %s mới có thể thắp hương!', itemAmount, itemLabel),
                type = 'error'
            })
            return
        end

        TriggerClientEvent('gin_thaphuong:client:startPray', src, locationIdx, specifiedItemType)
        return
    end

    -- Nếu bấm E tại lu hương (chưa chọn loại hương)
    local availableItems = {}
    if Config.IncenseTypes then
        for itemCode, info in pairs(Config.IncenseTypes) do
            local itemAmount = info.amount or 1
            if HasItem(src, itemCode, itemAmount) then
                table.insert(availableItems, {
                    name = itemCode,
                    label = info.label,
                    rep = info.reputationGain or 1
                })
            end
        end
    end

    if #availableItems == 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Thiếu vật phẩm',
            description = 'Bạn cần có Cây hương (cay_huong) hoặc Cây hương cao cấp (cay_huong_luxury) mới có thể thắp hương!',
            type = 'error'
        })
    elseif #availableItems == 1 then
        -- Chỉ có 1 loại hương -> Tự chọn loại đó
        TriggerClientEvent('gin_thaphuong:client:startPray', src, locationIdx, availableItems[1].name)
    else
        -- Có nhiều loại hương -> Gửi menu cho client chọn
        TriggerClientEvent('gin_thaphuong:client:openIncenseMenu', src, locationIdx, availableItems)
    end
end)

RegisterNetEvent('gin_thaphuong:server:completeThapHuong', function(itemType)
    local src = source

    local player = GetPlayerData(src)
    if not player then return end

    itemType = itemType or Config.DefaultIncenseType or 'cay_huong'
    local incenseInfo = (Config.IncenseTypes and Config.IncenseTypes[itemType]) or {
        label = 'Cây hương',
        reputationGain = 1,
        amount = 1
    }

    local itemName = itemType
    local itemAmount = incenseInfo.amount or 1
    local itemLabel = incenseInfo.label or 'Cây hương'
    local repGain = incenseInfo.reputationGain or 1

    -- 1. Kiểm tra vật phẩm trước khi hoàn tất
    if Config.RequireItem then
        if not HasItem(src, itemName, itemAmount) then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lỗi thắp hương',
                description = string.format('Bạn không có %s %s để hoàn thành thắp hương!', itemAmount, itemLabel),
                type = 'error'
            })
            return
        end
    end

    -- 2. Trừ nén hương khi thắp xong
    if Config.RemoveItemOnPray then
        RemoveItem(src, itemName, itemAmount)
    end

    -- 3. Cộng điểm uy tín metadata
    local repConfig = Config.ReputationSystem or {}
    local maxReputation = repConfig.maxReputation or 100

    local currentReputation = getPlayerReputation(src)
    local newReputation = math.max(0, math.min(maxReputation, currentReputation + repGain))

    if player.Functions and player.Functions.SetMetaData then
        player.Functions.SetMetaData('reputation', newReputation)
    end

    -- Thông báo cho người chơi qua ox_lib notify
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Uy tín được cộng',
        description = string.format('Bạn đã thắp %s thành công (-%s %s) và được cộng +%s điểm uy tín. Uy tín hiện tại: %s', 
                                   itemLabel, itemAmount, itemLabel, repGain, newReputation),
        type = 'success'
    })
end)
