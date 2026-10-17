lib.locale()

---@param plate string
---@return any
isVehicleOwned = function(plate)
    if Config.framework == 'esx' then
        return MySQL.scalar.await('SELECT plate FROM owned_vehicles WHERE plate = ?', { plate })
    else
        return MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', { plate })
    end
    return false
end

---@param vehicle any
---@param mods any
---@param isTuning boolean|nil
---@param coords table|nil
saveVehicleMods = function(vehicle, mods, isTuning, coords)
    local coordsStr = nil
    if coords then
        coordsStr = string.format('vec4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, coords.w)
    end
    
    if Config.framework == 'esx' then
        if isTuning and coordsStr then
            MySQL.update('UPDATE owned_vehicles SET vehicle = ?, tuning_coords = ? WHERE plate = ?', { json.encode(mods), coordsStr, mods.plate })
        else
            MySQL.update('UPDATE owned_vehicles SET vehicle = ? WHERE plate = ?', { json.encode(mods), mods.plate })
        end
    else
        if isTuning and coordsStr then
            MySQL.update('UPDATE player_vehicles SET mods = ?, tuning_coords = ? WHERE plate = ?', { json.encode(mods), coordsStr, mods.plate })
        else
            MySQL.update('UPDATE player_vehicles SET mods = ? WHERE plate = ?', { json.encode(mods), mods.plate })
        end
    end
end

---@param plate string
---@return any
getVehicleDatabaseMods = function(plate)
    if Config.framework == 'esx' then
        return MySQL.scalar.await('SELECT vehicle FROM owned_vehicles WHERE plate = ?', { plate })
    else
        return MySQL.scalar.await('SELECT mods FROM player_vehicles WHERE plate = ?', { plate })
    end
end

---@param account string
---@param amount integer
addAccountMoney = function(account, amount)
    if Config.banking == 'Renewed-Banking' then
        exports['Renewed-Banking']:addAccountMoney(account, amount)
    elseif Config.banking == 'esx_addonaccount' then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. account, function(account)
            account.addMoney(amount)
        end)
    else
        exports[Config.banking]:AddMoney(account, amount)
    end
end

isValidItem = function(item)
    local isValidItem = false
    local workshopItems = {
        'body_repair_kit',
        'cosmetics',
        'mechanic_toolbox',
        'neons_controller',
        'mods_list',
        'extras_controller',
        -- Paint items
        'mechspray',
        'chameleon_spray',
        -- Cosmetic items
        'car_wheel',
        'spoiler',
        'front_bumper',
        'rear_bumper',
        'skirtcar',
        'exhaust',
        'car_hood',
        'horn',
        'internals',
        'seats',
        'engine_block',
        'vanity_plate',
        'livery'
    }

    for _, workshopItem in pairs(workshopItems) do
        if workshopItem == item then
            isValidItem = true
            break
        end
    end

    if not isValidItem then
        for _, performance in pairs(Config.performance) do
            if performance.item == item then
                isValidItem = true
                break
            end
        end
    end

    return isValidItem
end

---@param item string
---@return boolean | table
isValidCraftItem = function(item)
    ---@type boolean | table
    local isValidItem = false
    for category, _ in pairs(Config.crafts) do
        for _, craftItem in pairs(Config.crafts[category].items) do
            if craftItem.name == item then
                isValidItem = craftItem.ingredients
                break
            end
        end
    end
    return isValidItem
end

-- Register shops

---@param id string
---@param label string
---@param passedItems table
registerShop = function(id, label, passedItems)
    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:RegisterShop(id, { name = label, slots = #passedItems, inventory = passedItems })
    else
        local items = {}
        for k, v in pairs(passedItems) do
            items[#items + 1] = { name = v.name, price = tonumber(v.price), amount = tonumber(v.count), info = {}, slot = k }
        end
        exports[Config.inventory]:CreateShop({ name = id, label = label, slots = #items, items = items })
    end
end

if Config.inventory ~= 'qb-inventory-old' then
    for k, v in pairs(Config.workshops) do
        if v.enabled and v.shops then
            for sk, sv in pairs(v.shops) do
                for _, cv in pairs(sv.categories) do
                    registerShop(("shop_%s_%s_%s"):format(k, sk, cv), locale("shop_label", Config.shops[cv].categoryLabel), Config.shops[cv].items)
                end
            end
        end
    end
end

-- Discord Webhook Logging
---@param webhook string
---@param title string
---@param message string
---@param color number
sendDiscordLog = function(webhook, title, message, color)
    if not Config.Logs or not Config.Logs.enabled then return end
    if not webhook or webhook == '' then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color or 3447003,
            ["footer"] = {
                ["text"] = os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

---@param source number
---@param plate string
---@param tuningType string
---@param itemUsed string|nil
---@param coords table|nil
logTuning = function(source, plate, tuningType, itemUsed, coords)
    if not Config.Logs or not Config.Logs.enabled then return end
    
    local Player = nil
    local playerName = 'Unknown'
    local citizenId = 'Unknown'
    
    if Config.framework == 'qb' then
        Player = Config.core.Functions.GetPlayer(source)
        if Player then
            playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            citizenId = Player.PlayerData.pid
        end
    elseif Config.framework == 'qbx' then
        Player = exports.qbx_core:GetPlayer(source)
        if Player then
            playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            citizenId = Player.PlayerData.pid
        end
    elseif Config.framework == 'esx' then
        Player = Config.core.GetPlayerFromId(source)
        if Player then
            playerName = Player.getName()
            citizenId = Player.identifier
        end
    end
    
    local coordsStr = 'N/A'
    if coords then
        coordsStr = string.format('vec4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, coords.w or 0)
    end
    
    -- Get detailed labels
    local tuningTypeLabel = Config.Logs.tuningTypes and Config.Logs.tuningTypes[tuningType] or tuningType
    
    -- For Cosmetics, itemUsed already contains detailed label (e.g., "Màu chính: Cam Sáng")
    -- For other types, look up from itemLabels
    local itemLabel = itemUsed or 'N/A'
    local itemCode = itemUsed or 'N/A'
    
    if tuningType == 'Cosmetics' then
        -- itemUsed already contains the detailed description from client
        itemLabel = itemUsed or 'N/A'
        itemCode = '' -- Don't show code for cosmetics since detail is already clear
    else
        -- Look up label for Performance, Lights, Extras
        itemLabel = Config.Logs.itemLabels and Config.Logs.itemLabels[itemUsed] or itemUsed or 'N/A'
        itemCode = itemUsed or 'N/A'
    end
    
    local phukienLine = ''
    if itemCode and itemCode ~= '' then
        phukienLine = string.format('**Phụ kiện:** %s (%s)', itemLabel, itemCode)
    else
        phukienLine = string.format('**Phụ kiện:** %s', itemLabel)
    end
    
    local message = string.format(
        '**Player:** %s\n**Citizen ID:** %s\n**Biển số:** %s\n**Loại độ:** %s\n%s\n**Vị trí:** %s\n**Thời gian:** %s',
        playerName,
        citizenId,
        plate,
        tuningTypeLabel,
        phukienLine,
        coordsStr,
        os.date("%d/%m/%Y %H:%M:%S")
    )
    
    sendDiscordLog(Config.Logs.webhooks.tuning, '🔧 Độ Xe', message, Config.Logs.colors.tuning)
end
