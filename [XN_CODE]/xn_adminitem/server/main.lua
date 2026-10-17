-- Server-side code để xử lý tìm kiếm và lấy dữ liệu item

-- ==========================================
-- License Manager & Check Class
-- ==========================================
LicenseManager = {
    limits = {}, -- item_name -> limit
    usage = {},  -- license -> { item_name -> count }
    blacklist = {}, -- item_name -> boolean
}

function LicenseManager:init()
    -- 1. Create tables if not exists
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `xn_adminitem_limits` (
            `item` VARCHAR(50) NOT NULL,
            `limit_val` INT NOT NULL DEFAULT 100,
            PRIMARY KEY (`item`)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `xn_adminitem_usage` (
            `license` VARCHAR(60) NOT NULL,
            `item` VARCHAR(50) NOT NULL,
            `count` INT NOT NULL DEFAULT 0,
            `date` DATE NOT NULL DEFAULT (CURRENT_DATE),
            PRIMARY KEY (`license`, `item`)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `xn_adminitem_blacklist` (
            `item` VARCHAR(50) NOT NULL,
            PRIMARY KEY (`item`)
        )
    ]])

    -- Check if 'date' column exists in xn_adminitem_usage (for backward compatibility)
    local checkColumn = MySQL.query.await([[
        SELECT COUNT(*) AS col_exists 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'xn_adminitem_usage' 
        AND COLUMN_NAME = 'date' 
        AND TABLE_SCHEMA = DATABASE()
    ]])
    if checkColumn and checkColumn[1] and checkColumn[1].col_exists == 0 then
        MySQL.query.await([[
            ALTER TABLE `xn_adminitem_usage` 
            ADD COLUMN `date` DATE NOT NULL DEFAULT (CURRENT_DATE)
        ]])
    end

    -- 2. Migrate existing data from JSON if present
    local content = LoadResourceFile(GetCurrentResourceName(), "limits_data.json")
    if content and content ~= "" then
        local data = json.decode(content)
        if data then
            -- Import limits configuration
            if data.limits then
                for itemName, limitVal in pairs(data.limits) do
                    if itemName and limitVal then
                        MySQL.update.await('INSERT INTO xn_adminitem_limits (item, limit_val) VALUES (?, ?) ON DUPLICATE KEY UPDATE limit_val = ?', {
                            itemName, limitVal, limitVal
                        })
                    end
                end
            end

            -- Import today's usage (only import usage matching current date to prevent legacy usage bleeding)
            local today = os.date("%Y-%m-%d")
            if data.usage and data.usage[today] then
                for license, items in pairs(data.usage[today]) do
                    for itemName, count in pairs(items) do
                        if license and itemName and count then
                            MySQL.update.await('INSERT INTO xn_adminitem_usage (license, item, count, date) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE count = ?, date = ?', {
                                license, itemName, count, today, count, today
                            })
                        end
                    end
                end
            end
            
            print("^3[xn_adminitem] Migrated limits_data.json to MySQL database successfully.^7")
        end
        
        -- Deactivate JSON file by emptying it so migration doesn't run again on next restart
        SaveResourceFile(GetCurrentResourceName(), "limits_data.json", "", -1)
    end

    -- 3. Load limits from DB
    local limits = MySQL.query.await("SELECT `item`, `limit_val` FROM `xn_adminitem_limits`")
    if limits then
        for _, row in ipairs(limits) do
            self.limits[row.item] = row.limit_val
        end
    end

    -- 4. Delete usage entries from previous days to reset them
    local today = os.date("%Y-%m-%d")
    MySQL.query.await("DELETE FROM `xn_adminitem_usage` WHERE `date` != ?", { today })

    -- 5. Load today's usage from DB
    local usages = MySQL.query.await("SELECT `license`, `item`, `count` FROM `xn_adminitem_usage`")
    if usages then
        for _, row in ipairs(usages) do
            if not self.usage[row.license] then
                self.usage[row.license] = {}
            end
            self.usage[row.license][row.item] = row.count
        end
    end

    -- 6. Load blacklist from DB
    local blacklist = MySQL.query.await("SELECT `item` FROM `xn_adminitem_blacklist`")
    if blacklist then
        for _, row in ipairs(blacklist) do
            self.blacklist[row.item] = true
        end
    end

    print("^2[xn_adminitem] Loaded daily limits, blacklist, and usage from database.^7")
end

function LicenseManager:canGetItem(license)
    if not Config or not Config.AllowedGetLicenses then return false end
    return Config.AllowedGetLicenses[license] == true
end

function LicenseManager:canEditLimit(license)
    if not Config or not Config.AllowedEditLicenses then return false end
    return Config.AllowedEditLicenses[license] == true
end

function LicenseManager:isBlacklisted(itemName)
    return self.blacklist[itemName] == true
end

function LicenseManager:setItemBlacklist(itemName, isBlacklisted)
    self.blacklist[itemName] = isBlacklisted
    if isBlacklisted then
        MySQL.update('INSERT INTO xn_adminitem_blacklist (item) VALUES (?) ON DUPLICATE KEY UPDATE item = ?', {itemName, itemName})
    else
        MySQL.update('DELETE FROM xn_adminitem_blacklist WHERE item = ?', {itemName})
    end
end

function LicenseManager:getItemLimit(itemName)
    local defaultLimit = (Config and Config.DefaultLimit) or 100
    return self.limits[itemName] or defaultLimit
end

function LicenseManager:setItemLimit(itemName, limit)
    local limitVal = tonumber(limit) or 100
    self.limits[itemName] = limitVal
    
    -- Async update to DB
    MySQL.update('INSERT INTO xn_adminitem_limits (item, limit_val) VALUES (?, ?) ON DUPLICATE KEY UPDATE limit_val = ?', {
        itemName, limitVal, limitVal
    })
end

function LicenseManager:getUsedQuantity(license, itemName)
    if not self.usage[license] then
        self.usage[license] = {}
    end
    return self.usage[license][itemName] or 0
end

function LicenseManager:addUsedQuantity(license, itemName, amount)
    if not self.usage[license] then
        self.usage[license] = {}
    end
    local current = self.usage[license][itemName] or 0
    local newAmount = current + amount
    self.usage[license][itemName] = newAmount

    -- Async update to DB with today's date
    local today = os.date("%Y-%m-%d")
    MySQL.update('INSERT INTO xn_adminitem_usage (license, item, count, date) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE count = ?, date = ?', {
        license, itemName, newAmount, today, newAmount, today
    })
end

-- Initialize the manager when DB is ready
MySQL.ready(function()
    CreateThread(function()
        LicenseManager:init()
    end)
end)

-- Schedule daily reset of limits usage at 00:00 using lib.cron
lib.cron.new('0 0 * * *', function()
    LicenseManager.usage = {}
    
    MySQL.update('TRUNCATE TABLE xn_adminitem_usage', {}, function()
        print('^2[xn_adminitem] Daily limits usage reset successfully via Cron (00:00).^7')
    end)
end)

local function getPlayerLicense(source)
    local license = GetPlayerIdentifierByType(source, 'license')
    if not license then
        for _, id in ipairs(GetPlayerIdentifiers(source)) do
            if string.sub(id, 1, 8) == "license:" then
                license = id
                break
            end
        end
    end
    return license
end

-- Command mở UI - Chỉ cho phép mod trở lên
lib.addCommand('adminitem', {
    help = 'Mở giao diện quản lý item (Admin)',
    restricted = 'group.mod'
}, function(source)
    TriggerClientEvent('xn_adminitem:openUI', source)
end)

-- Danh sách items cần phân biệt theo metadata
local METADATA_SENSITIVE_ITEMS = {
    ["cloth_outfit"] = true,
    ["cloth_torso"] = true,
    ["cloth_tshirt"] = true,
    ["cloth_arms"] = true,
    ["cloth_pants"] = true,
    ["cloth_shoes"] = true,
    ["cloth_decals"] = true,
    ["cloth_ears"] = true,
    ["cloth_mask"] = true,
    ["cloth_bproof"] = true,
    ["cloth_chain"] = true,
    ["cloth_bags"] = true,
    ["cloth_glasses"] = true,
    ["cloth_watches"] = true,
    ["cloth_bracelets"] = true,
    ["cloth_helmet"] = true
}

local function isClothItem(itemName)
    return itemName and (METADATA_SENSITIVE_ITEMS[itemName] == true or string.sub(itemName, 1, 6) == "cloth_")
end

-- Hàm tạo metadata key duy nhất (PHẢI khai báo trước compareMetadata)
local function getMetadataKey(metadata, itemName)
    if not metadata then return "empty" end
    
    if (itemName and isClothItem(itemName)) or (metadata.drawable ~= nil or metadata.sex ~= nil or metadata.texture ~= nil) then
        local d = tostring(metadata.drawable or "?")
        local s = string.lower(tostring(metadata.sex or ""))
        local t = tostring(metadata.texture or "?")
        local lbl = tostring(metadata.label or "")
        local img = tostring(metadata.imageurl or "")
        return "cloth|d=" .. d .. "|s=" .. s .. "|t=" .. t .. "|lbl=" .. lbl .. "|img=" .. img
    end

    -- Tạo key từ các field quan trọng
    local key = ""
    if metadata.label then key = key .. "|lbl=" .. tostring(metadata.label) end
    if metadata.imageurl then key = key .. "|img=" .. tostring(metadata.imageurl) end
    if metadata.type then key = key .. "|type=" .. tostring(metadata.type) end
    if metadata.serial then key = key .. "|serial=" .. tostring(metadata.serial) end
    if metadata.DoHiem then key = key .. "|dohiem=" .. tostring(metadata.DoHiem) end
    if metadata.Capdo then key = key .. "|capdo=" .. tostring(metadata.Capdo) end
    if metadata.durability then key = key .. "|dur=" .. tostring(metadata.durability) end
    
    return key ~= "" and key or "empty"
end

-- Hàm so sánh metadata cloth (drawable + sex + texture, bỏ qua serial)
local function compareClothMetadata(meta1, meta2)
    if not meta1 and not meta2 then return true end
    if not meta1 or not meta2 then return false end

    local d1 = tostring(meta1.drawable or "?")
    local d2 = tostring(meta2.drawable or "?")
    local s1 = string.lower(tostring(meta1.sex or ""))
    local s2 = string.lower(tostring(meta2.sex or ""))
    local t1 = tostring(meta1.texture or "?")
    local t2 = tostring(meta2.texture or "?")

    if d1 ~= d2 or s1 ~= s2 or t1 ~= t2 then return false end

    if meta2.label and meta1.label and tostring(meta1.label) ~= tostring(meta2.label) then
        return false
    end
    if meta2.imageurl and meta1.imageurl and tostring(meta1.imageurl) ~= tostring(meta2.imageurl) then
        return false
    end

    return true
end

-- Hàm so sánh metadata
local function compareMetadata(meta1, meta2)
    if not meta1 and not meta2 then 
        return true 
    end
    if not meta1 or not meta2 then 
        return false 
    end
    
    local key1 = getMetadataKey(meta1)
    local key2 = getMetadataKey(meta2)
    
    return key1 == key2
end

-- Lấy tất cả items từ ox_inventory
local function getItemsList()
    local items = exports.ox_inventory:Items()
    local itemList = {}
    
    for name, data in pairs(items) do
        table.insert(itemList, {
            name = name,
            label = data.label,
            weight = data.weight,
            stack = data.stack or false,
            close = data.close or false,
            description = data.description or ''
        })
    end
    
    return itemList
end

-- Tìm kiếm item theo tên
RegisterNetEvent('xn_adminitem:searchItem', function(searchTerm)
    local src = source
    
    if not searchTerm or searchTerm == "" then
        TriggerClientEvent('xn_adminitem:searchResults', src, {})
        return
    end
    
    local items = exports.ox_inventory:Items()
    local results = {}
    
    searchTerm = string.lower(searchTerm)
    
    for name, data in pairs(items) do
        if string.find(string.lower(name), searchTerm) or string.find(string.lower(data.label), searchTerm) then
            -- Kiểm tra nếu là item cần phân biệt metadata
            if METADATA_SENSITIVE_ITEMS[name] then
                -- Nhóm theo metadata khác nhau
                local metadataGroups = {}
                
                -- 1. Từ kho người chơi
                local playerInventories = MySQL.query.await('SELECT inventory FROM players WHERE inventory IS NOT NULL AND inventory != "[]"')
                for _, row in ipairs(playerInventories) do
                    local success, inventory = pcall(json.decode, row.inventory)
                    if success and inventory then
                        for _, item in pairs(inventory) do
                            if item.name == name then
                                local metadataKey = getMetadataKey(item.metadata, name)
                                if not metadataGroups[metadataKey] then
                                    metadataGroups[metadataKey] = {
                                        count = 0,
                                        metadata = item.metadata or {}
                                    }
                                end
                                metadataGroups[metadataKey].count = metadataGroups[metadataKey].count + (item.count or item.amount or 0)
                            end
                        end
                    end
                end
                
                -- 2. Từ cốp xe
                local vehicleTrunks = MySQL.query.await('SELECT trunk FROM player_vehicles WHERE trunk IS NOT NULL AND trunk != "[]"')
                for _, row in ipairs(vehicleTrunks) do
                    local success, trunk = pcall(json.decode, row.trunk)
                    if success and trunk then
                        for _, item in pairs(trunk) do
                            if item.name == name then
                                local metadataKey = getMetadataKey(item.metadata, name)
                                if not metadataGroups[metadataKey] then
                                    metadataGroups[metadataKey] = {
                                        count = 0,
                                        metadata = item.metadata or {}
                                    }
                                end
                                metadataGroups[metadataKey].count = metadataGroups[metadataKey].count + (item.count or item.amount or 0)
                            end
                        end
                    end
                end
                
                -- 3. Từ các kho khác
                local storages = MySQL.query.await('SELECT data FROM ox_inventory WHERE data IS NOT NULL AND data != "[]"')
                for _, row in ipairs(storages) do
                    local success, storageData = pcall(json.decode, row.data)
                    if success and storageData then
                        for _, item in pairs(storageData) do
                            if item.name == name then
                                local metadataKey = getMetadataKey(item.metadata, name)
                                if not metadataGroups[metadataKey] then
                                    metadataGroups[metadataKey] = {
                                        count = 0,
                                        metadata = item.metadata or {}
                                    }
                                end
                                metadataGroups[metadataKey].count = metadataGroups[metadataKey].count + (item.count or item.amount or 0)
                            end
                        end
                    end
                end
                
                -- Thêm từng metadata variant như một item riêng
                for metadataKey, groupData in pairs(metadataGroups) do
                    table.insert(results, {
                        name = name,
                        label = data.label,
                        count = groupData.count,
                        weight = data.weight,
                        description = data.description or '',
                        metadata = groupData.metadata,
                        isMetadataSensitive = true
                    })
                end
            else
                -- Với items thường: phân biệt theo serial nếu có
                local totalCount = 0
                local serialGroups = {}  -- key = serial string

                local function addItemToCount(item)
                    if item.metadata and item.metadata.serial then
                        local s = tostring(item.metadata.serial)
                        if not serialGroups[s] then
                            serialGroups[s] = { count = 0, metadata = item.metadata }
                        end
                        serialGroups[s].count = serialGroups[s].count + (item.count or item.amount or 0)
                    else
                        totalCount = totalCount + (item.count or item.amount or 0)
                    end
                end

                -- 1. Đếm từ kho người chơi (bảng players, cột inventory)
                local playerInventories = MySQL.query.await('SELECT inventory FROM players WHERE inventory IS NOT NULL AND inventory != "[]"')
                for _, row in ipairs(playerInventories) do
                    local success, inventory = pcall(json.decode, row.inventory)
                    if success and inventory then
                        for _, item in pairs(inventory) do
                            if item.name == name then addItemToCount(item) end
                        end
                    end
                end

                -- 2. Đếm từ cốp xe (bảng player_vehicles, cột trunk)
                local vehicleTrunks = MySQL.query.await('SELECT trunk FROM player_vehicles WHERE trunk IS NOT NULL AND trunk != "[]"')
                for _, row in ipairs(vehicleTrunks) do
                    local success, trunk = pcall(json.decode, row.trunk)
                    if success and trunk then
                        for _, item in pairs(trunk) do
                            if item.name == name then addItemToCount(item) end
                        end
                    end
                end

                -- 3. Đếm từ các kho khác (bảng ox_inventory)
                local storages = MySQL.query.await('SELECT data FROM ox_inventory WHERE data IS NOT NULL AND data != "[]"')
                for _, row in ipairs(storages) do
                    local success, storageData = pcall(json.decode, row.data)
                    if success and storageData then
                        for _, item in pairs(storageData) do
                            if item.name == name then addItemToCount(item) end
                        end
                    end
                end

                -- Items có serial: mỗi serial là một card riêng
                for _, groupData in pairs(serialGroups) do
                    table.insert(results, {
                        name = name,
                        label = data.label,
                        count = groupData.count,
                        weight = data.weight,
                        description = data.description or '',
                        metadata = groupData.metadata,
                        isMetadataSensitive = true
                    })
                end

                -- Items không có serial: gộp thành một card
                if totalCount > 0 then
                    table.insert(results, {
                        name = name,
                        label = data.label,
                        count = totalCount,
                        weight = data.weight,
                        description = data.description or ''
                    })
                end
            end
        end
    end
    
    TriggerClientEvent('xn_adminitem:searchResults', src, results)
end)

-- Tìm kiếm items theo DoHiem metadata
RegisterNetEvent('xn_adminitem:searchByDoHiem', function(doHiem)
    local src = source
    
    if not doHiem or doHiem == "" then
        TriggerClientEvent('xn_adminitem:searchResults', src, {})
        return
    end
    
    local items = exports.ox_inventory:Items()
    local results = {}
    local itemCounts = {} -- Đếm tổng số lượng theo item name
    
    -- Hàm kiểm tra metadata DoHiem
    local function hasDoHiem(metadata, targetDoHiem)
        if not metadata or not metadata.DoHiem then return false end
        return string.lower(metadata.DoHiem) == string.lower(targetDoHiem)
    end
    
    -- Quét kho người chơi
    local playerInventories = MySQL.query.await('SELECT inventory FROM players WHERE inventory IS NOT NULL AND inventory != "[]"')
    for _, row in ipairs(playerInventories) do
        local success, inventory = pcall(json.decode, row.inventory)
        if success and inventory then
            for _, item in pairs(inventory) do
                if item.metadata and hasDoHiem(item.metadata, doHiem) then
                    local metadataKey = item.name .. "|" .. getMetadataKey(item.metadata)
                    if not itemCounts[metadataKey] then
                        itemCounts[metadataKey] = {
                            name = item.name,
                            count = 0,
                            metadata = item.metadata
                        }
                    end
                    itemCounts[metadataKey].count = itemCounts[metadataKey].count + (item.count or item.amount or 0)
                end
            end
        end
    end
    
    -- Quét cốp xe
    local vehicleTrunks = MySQL.query.await('SELECT trunk FROM player_vehicles WHERE trunk IS NOT NULL AND trunk != "[]"')
    for _, row in ipairs(vehicleTrunks) do
        local success, trunk = pcall(json.decode, row.trunk)
        if success and trunk then
            for _, item in pairs(trunk) do
                if item.metadata and hasDoHiem(item.metadata, doHiem) then
                    local metadataKey = item.name .. "|" .. getMetadataKey(item.metadata)
                    if not itemCounts[metadataKey] then
                        itemCounts[metadataKey] = {
                            name = item.name,
                            count = 0,
                            metadata = item.metadata
                        }
                    end
                    itemCounts[metadataKey].count = itemCounts[metadataKey].count + (item.count or item.amount or 0)
                end
            end
        end
    end
    
    -- Quét các kho khác
    local storages = MySQL.query.await('SELECT data FROM ox_inventory WHERE data IS NOT NULL AND data != "[]"')
    for _, row in ipairs(storages) do
        local success, storageData = pcall(json.decode, row.data)
        if success and storageData then
            for _, item in pairs(storageData) do
                if item.metadata and hasDoHiem(item.metadata, doHiem) then
                    local metadataKey = item.name .. "|" .. getMetadataKey(item.metadata)
                    if not itemCounts[metadataKey] then
                        itemCounts[metadataKey] = {
                            name = item.name,
                            count = 0,
                            metadata = item.metadata
                        }
                    end
                    itemCounts[metadataKey].count = itemCounts[metadataKey].count + (item.count or item.amount or 0)
                end
            end
        end
    end
    
    -- Tạo kết quả
    for _, data in pairs(itemCounts) do
        local itemData = items[data.name]
        table.insert(results, {
            name = data.name,
            label = itemData and itemData.label or data.name,
            count = data.count,
            weight = itemData and itemData.weight or 0,
            description = itemData and itemData.description or '',
            metadata = data.metadata,
            isMetadataSensitive = true
        })
    end
    
    -- Sắp xếp theo label
    table.sort(results, function(a, b) return a.label < b.label end)
    
    TriggerClientEvent('xn_adminitem:searchResults', src, results)
end)

-- Tìm kiếm items theo CapDo metadata (Balo)
RegisterNetEvent('xn_adminitem:searchByCapDo', function(itemName, capDo)
    local src = source
    
    if not itemName or not capDo then
        TriggerClientEvent('xn_adminitem:searchResults', src, {})
        return
    end
    
    local items = exports.ox_inventory:Items()
    local results = {}
    local itemCounts = {}
    
    local function hasCapDo(metadata, targetCapDo)
        if not metadata or not metadata.Capdo then return false end
        return tonumber(metadata.Capdo) == tonumber(targetCapDo)
    end
    
    -- Quét kho người chơi
    local playerInventories = MySQL.query.await('SELECT inventory FROM players WHERE inventory IS NOT NULL AND inventory != "[]"')
    for _, row in ipairs(playerInventories) do
        local success, inventory = pcall(json.decode, row.inventory)
        if success and inventory then
            for _, item in pairs(inventory) do
                if item.name == itemName and item.metadata and hasCapDo(item.metadata, capDo) then
                    local metadataKey = item.name .. "|" .. getMetadataKey(item.metadata)
                    if not itemCounts[metadataKey] then
                        itemCounts[metadataKey] = {
                            name = item.name,
                            count = 0,
                            metadata = item.metadata
                        }
                    end
                    itemCounts[metadataKey].count = itemCounts[metadataKey].count + (item.count or item.amount or 0)
                end
            end
        end
    end
    
    -- Quét cốp xe
    local vehicleTrunks = MySQL.query.await('SELECT trunk FROM player_vehicles WHERE trunk IS NOT NULL AND trunk != "[]"')
    for _, row in ipairs(vehicleTrunks) do
        local success, trunk = pcall(json.decode, row.trunk)
        if success and trunk then
            for _, item in pairs(trunk) do
                if item.name == itemName and item.metadata and hasCapDo(item.metadata, capDo) then
                    local metadataKey = item.name .. "|" .. getMetadataKey(item.metadata)
                    if not itemCounts[metadataKey] then
                        itemCounts[metadataKey] = {
                            name = item.name,
                            count = 0,
                            metadata = item.metadata
                        }
                    end
                    itemCounts[metadataKey].count = itemCounts[metadataKey].count + (item.count or item.amount or 0)
                end
            end
        end
    end
    
    -- Quét các kho khác
    local storages = MySQL.query.await('SELECT data FROM ox_inventory WHERE data IS NOT NULL AND data != "[]"')
    for _, row in ipairs(storages) do
        local success, storageData = pcall(json.decode, row.data)
        if success and storageData then
            for _, item in pairs(storageData) do
                if item.name == itemName and item.metadata and hasCapDo(item.metadata, capDo) then
                    local metadataKey = item.name .. "|" .. getMetadataKey(item.metadata)
                    if not itemCounts[metadataKey] then
                        itemCounts[metadataKey] = {
                            name = item.name,
                            count = 0,
                            metadata = item.metadata
                        }
                    end
                    itemCounts[metadataKey].count = itemCounts[metadataKey].count + (item.count or item.amount or 0)
                end
            end
        end
    end
    
    -- Tạo kết quả
    for _, data in pairs(itemCounts) do
        local itemData = items[data.name]
        table.insert(results, {
            name = data.name,
            label = itemData and itemData.label or data.name,
            count = data.count,
            weight = itemData and itemData.weight or 0,
            description = itemData and itemData.description or '',
            metadata = data.metadata,
            isMetadataSensitive = true
        })
    end
    
    table.sort(results, function(a, b) return a.label < b.label end)
    
    TriggerClientEvent('xn_adminitem:searchResults', src, results)
end)

-- Tìm kiếm quần áo theo loại, drawable và giới tính
RegisterNetEvent('xn_adminitem:searchByCloth', function(clothType, drawable, sex)
    local src = source

    if not clothType or clothType == "" then
        TriggerClientEvent('xn_adminitem:searchResults', src, {})
        return
    end

    local items = exports.ox_inventory:Items()
    local itemCounts = {}

    local function matchesFilter(item)
        if item.name ~= clothType then return false end
        if not item.metadata then return false end

        if drawable ~= nil and drawable ~= "" then
            if tostring(item.metadata.drawable) ~= tostring(drawable) then return false end
        end

        if sex ~= nil and sex ~= "" then
            if not item.metadata.sex then return false end
            if string.lower(tostring(item.metadata.sex)) ~= string.lower(tostring(sex)) then return false end
        end

        return true
    end

    local function addToCount(item)
        local drawableVal = item.metadata and item.metadata.drawable
        local sexVal = item.metadata and item.metadata.sex
        local textureVal = item.metadata and item.metadata.texture
        local labelVal = item.metadata and item.metadata.label
        local imageurlVal = item.metadata and item.metadata.imageurl
        local metaKey = item.name
            .. "|d=" .. tostring(drawableVal or "?")
            .. "|s=" .. tostring(sexVal or "?")
            .. "|t=" .. tostring(textureVal or "?")
            .. "|lbl=" .. tostring(labelVal or "")
            .. "|img=" .. tostring(imageurlVal or "")

        if not itemCounts[metaKey] then
            itemCounts[metaKey] = {
                name = item.name,
                count = 0,
                metadata = item.metadata or {}
            }
        end
        itemCounts[metaKey].count = itemCounts[metaKey].count + (item.count or item.amount or 0)
    end

    -- Quét kho người chơi
    local playerInventories = MySQL.query.await('SELECT inventory FROM players WHERE inventory IS NOT NULL AND inventory != "[]"')
    for _, row in ipairs(playerInventories) do
        local ok, inventory = pcall(json.decode, row.inventory)
        if ok and inventory then
            for _, item in pairs(inventory) do
                if matchesFilter(item) then addToCount(item) end
            end
        end
    end

    -- Quét cốp xe
    local vehicleTrunks = MySQL.query.await('SELECT trunk FROM player_vehicles WHERE trunk IS NOT NULL AND trunk != "[]"')
    for _, row in ipairs(vehicleTrunks) do
        local ok, trunk = pcall(json.decode, row.trunk)
        if ok and trunk then
            for _, item in pairs(trunk) do
                if matchesFilter(item) then addToCount(item) end
            end
        end
    end

    -- Quét các kho khác
    local storages = MySQL.query.await('SELECT data FROM ox_inventory WHERE data IS NOT NULL AND data != "[]"')
    for _, row in ipairs(storages) do
        local ok, storageData = pcall(json.decode, row.data)
        if ok and storageData then
            for _, item in pairs(storageData) do
                if matchesFilter(item) then addToCount(item) end
            end
        end
    end

    -- Build kết quả
    local results = {}
    for _, data in pairs(itemCounts) do
        local itemData = items[data.name]
        table.insert(results, {
            name = data.name,
            label = itemData and itemData.label or data.name,
            count = data.count,
            weight = itemData and itemData.weight or 0,
            description = itemData and itemData.description or '',
            metadata = data.metadata,
            isMetadataSensitive = true
        })
    end

    -- Sắp xếp theo drawable rồi sex
    table.sort(results, function(a, b)
        local da = tonumber(a.metadata and a.metadata.drawable) or 0
        local db = tonumber(b.metadata and b.metadata.drawable) or 0
        if da ~= db then return da < db end
        local sa = tostring(a.metadata and a.metadata.sex or "")
        local sb = tostring(b.metadata and b.metadata.sex or "")
        return sa < sb
    end)

    TriggerClientEvent('xn_adminitem:searchResults', src, results)
end)

-- Lấy chi tiết phân bổ item
RegisterNetEvent('xn_adminitem:getItemDetails', function(itemName, pageType, pageNumber, itemMetadata)
    local src = source
    pageType = pageType or 'players'
    pageNumber = pageNumber or 1
    local limit = 10
    local offset = (pageNumber - 1) * limit
    
    local isMetadataSensitive = isClothItem(itemName)
    local metaCompare = isMetadataSensitive and compareClothMetadata or compareMetadata
    
    local details = {
        players = {},
        vehicles = {},
        storages = {},
        pagination = {
            playersTotal = 0,
            vehiclesTotal = 0,
            storagesTotal = 0,
            playersQuantityTotal = 0,
            vehiclesQuantityTotal = 0,
            storagesQuantityTotal = 0,
            currentPage = pageNumber,
            pageType = pageType,
            itemsPerPage = limit
        }
    }
    
    -- 1. Kho người chơi
    local allPlayers = MySQL.query.await([[
        SELECT pid, citizenid, charinfo, inventory 
        FROM players 
        WHERE inventory IS NOT NULL 
        AND inventory != "[]"
        AND inventory LIKE ?
    ]], {'%"' .. itemName .. '"%'})
    
    local allPlayerRecords = {}
    local totalQuantityPlayers = 0
    
    for _, row in ipairs(allPlayers) do
        local success, inventory = pcall(json.decode, row.inventory)
        if success and inventory then
            local charinfo = json.decode(row.charinfo or '{}')
            local playerName = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''))
            
            for slotKey, item in pairs(inventory) do
                if item and item.name == itemName then
                    local shouldInclude = true
                    if isMetadataSensitive and itemMetadata then
                        shouldInclude = metaCompare(item.metadata, itemMetadata)
                    end
                    
                    if shouldInclude then
                        local itemQty = (item.count or item.amount or 1)
                        totalQuantityPlayers = totalQuantityPlayers + itemQty
                        local itemSlot = item.slot or slotKey
                        
                        table.insert(allPlayerRecords, {
                            pid = row.pid,
                            citizenid = row.citizenid,
                            name = playerName,
                            count = itemQty,
                            slot = tostring(itemSlot)
                        })
                    end
                end
            end
        end
    end
    
    table.sort(allPlayerRecords, function(a, b)
        if a.pid ~= b.pid then return (tonumber(a.pid) or 0) < (tonumber(b.pid) or 0) end
        return (tonumber(a.slot) or 0) < (tonumber(b.slot) or 0)
    end)
    details.pagination.playersTotal = #allPlayerRecords
    details.pagination.playersQuantityTotal = totalQuantityPlayers
    
    if pageType == 'players' then
        for i = offset + 1, math.min(offset + limit, #allPlayerRecords) do
            table.insert(details.players, allPlayerRecords[i])
        end
    else
        for i = 1, math.min(10, #allPlayerRecords) do
            table.insert(details.players, allPlayerRecords[i])
        end
    end
    
    -- 2. Cốp xe
    local allVehicles = MySQL.query.await([[
        SELECT plate, vehicle, citizenid, trunk 
        FROM player_vehicles 
        WHERE trunk IS NOT NULL 
        AND trunk != "[]"
        AND trunk LIKE ?
    ]], {'%"' .. itemName .. '"%'})
    
    local allVehicleRecords = {}
    local totalQuantityVehicles = 0
    
    for _, row in ipairs(allVehicles) do
        local success, trunk = pcall(json.decode, row.trunk)
        if success and trunk then
            for slotKey, item in pairs(trunk) do
                if item and item.name == itemName then
                    local shouldInclude = true
                    if isMetadataSensitive and itemMetadata then
                        shouldInclude = metaCompare(item.metadata, itemMetadata)
                    end
                    
                    if shouldInclude then
                        local itemQty = (item.count or item.amount or 1)
                        totalQuantityVehicles = totalQuantityVehicles + itemQty
                        local itemSlot = item.slot or slotKey
                        
                        table.insert(allVehicleRecords, {
                            plate = row.plate,
                            vehicle = row.vehicle,
                            owner = row.citizenid,
                            count = itemQty,
                            slot = tostring(itemSlot)
                        })
                    end
                end
            end
        end
    end
    
    table.sort(allVehicleRecords, function(a, b)
        if a.plate ~= b.plate then return a.plate < b.plate end
        return (tonumber(a.slot) or 0) < (tonumber(b.slot) or 0)
    end)
    details.pagination.vehiclesTotal = #allVehicleRecords
    details.pagination.vehiclesQuantityTotal = totalQuantityVehicles
    
    if pageType == 'vehicles' then
        for i = offset + 1, math.min(offset + limit, #allVehicleRecords) do
            table.insert(details.vehicles, allVehicleRecords[i])
        end
    else
        for i = 1, math.min(10, #allVehicleRecords) do
            table.insert(details.vehicles, allVehicleRecords[i])
        end
    end
    
    -- 3. Các kho khác (ox_inventory)
    local allStorages = MySQL.query.await([[
        SELECT name, owner, data 
        FROM ox_inventory 
        WHERE data IS NOT NULL 
        AND data != "[]"
        AND data LIKE ?
    ]], {'%"' .. itemName .. '"%'})
    
    local allStorageRecords = {}
    local totalQuantityStorages = 0
    
    for _, row in ipairs(allStorages) do
        local success, data = pcall(json.decode, row.data)
        if success and data then
            for slotKey, item in pairs(data) do
                if item and item.name == itemName then
                    local shouldInclude = true
                    if isMetadataSensitive and itemMetadata then
                        shouldInclude = metaCompare(item.metadata, itemMetadata)
                    end
                    
                    if shouldInclude then
                        local itemQty = (item.count or item.amount or 1)
                        totalQuantityStorages = totalQuantityStorages + itemQty
                        local itemSlot = item.slot or slotKey
                        
                        table.insert(allStorageRecords, {
                            storageName = row.name,
                            owner = row.owner or 'N/A',
                            count = itemQty,
                            slot = tostring(itemSlot)
                        })
                    end
                end
            end
        end
    end
    
    table.sort(allStorageRecords, function(a, b)
        if a.storageName ~= b.storageName then return a.storageName < b.storageName end
        return (tonumber(a.slot) or 0) < (tonumber(b.slot) or 0)
    end)
    details.pagination.storagesTotal = #allStorageRecords
    details.pagination.storagesQuantityTotal = totalQuantityStorages
    
    if pageType == 'storages' then
        for i = offset + 1, math.min(offset + limit, #allStorageRecords) do
            table.insert(details.storages, allStorageRecords[i])
        end
    else
        for i = 1, math.min(10, #allStorageRecords) do
            table.insert(details.storages, allStorageRecords[i])
        end
    end
    
    TriggerClientEvent('xn_adminitem:itemDetails', src, details)
end)
    
-- Xóa item
RegisterNetEvent('xn_adminitem:deleteItem', function(itemName, quantity, deleteType, targetData, itemMetadata)
    local src = source
    if not itemName or not quantity or quantity <= 0 or not targetData then
        TriggerClientEvent('xn_adminitem:deleteResult', src, false)
        return
    end

    local isMetadataSensitive = isClothItem(itemName)
    local metaCompare = isMetadataSensitive and compareClothMetadata or compareMetadata
    local success = false
    
    if deleteType == 'player' then
        local pid = targetData.pid
        local citizenid = targetData.citizenid
        local targetSlot = targetData.slot
        local targetSlotNum = tonumber(targetSlot)
        
        -- Nếu chưa có citizenid, truy vấn 1 lần theo pid
        if not citizenid and pid then
            citizenid = MySQL.scalar.await('SELECT citizenid FROM players WHERE pid = ?', {pid})
        end

        -- Kiểm tra player online qua QBX / Core (O(1) in-memory lookup, không loop DB)
        local playerSource = nil
        if citizenid then
            local Player = exports.qbx_core:GetPlayerByCitizenId(citizenid)
            if Player and Player.PlayerData and Player.PlayerData.source then
                playerSource = tonumber(Player.PlayerData.source)
            end
        end
        
        if playerSource then
            -- Player đang online, dùng ox_inventory exports
            if targetSlotNum then
                local removed = exports.ox_inventory:RemoveItem(playerSource, itemName, quantity, nil, targetSlotNum)
                success = (removed ~= nil and removed ~= false)
            end
            
            -- Fallback nếu không có targetSlot hoặc chưa xóa thành công
            if not success then
                local inventory = exports.ox_inventory:GetInventory(playerSource, false)
                if inventory and inventory.items then
                    local remainingQty = quantity
                    for slotKey, item in pairs(inventory.items) do
                        if item and item.name == itemName and remainingQty > 0 then
                            local shouldDelete = true
                            if isMetadataSensitive and itemMetadata then
                                shouldDelete = metaCompare(item.metadata, itemMetadata)
                            end
                            
                            if shouldDelete then
                                local itemQty = item.count or 0
                                local qtyToRemove = math.min(itemQty, remainingQty)
                                local removed = exports.ox_inventory:RemoveItem(playerSource, itemName, qtyToRemove, nil, item.slot or slotKey)
                                if removed then
                                    remainingQty = remainingQty - qtyToRemove
                                end
                            end
                        end
                    end
                    success = (remainingQty < quantity)
                end
            end
        else
            -- Player offline, UPDATE database trực tiếp
            local queryField = pid and 'pid' or 'citizenid'
            local queryVal = pid or citizenid
            local playerData = MySQL.query.await('SELECT inventory FROM players WHERE ' .. queryField .. ' = ?', {queryVal})
            
            if playerData and playerData[1] then
                local inventory = json.decode(playerData[1].inventory or '[]') or {}
                local remainingQty = quantity
                
                -- 1. Nếu có targetSlot, ưu tiên tìm đúng item có slot đó
                if targetSlotNum then
                    for k, item in pairs(inventory) do
                        if type(item) == 'table' and item.name == itemName and tonumber(item.slot) == targetSlotNum then
                            local itemQty = tonumber(item.count) or tonumber(item.amount) or 1
                            if itemQty <= remainingQty then
                                remainingQty = remainingQty - itemQty
                                inventory[k] = nil
                            else
                                local newCount = itemQty - remainingQty
                                item.count = newCount
                                if item.amount then item.amount = newCount end
                                remainingQty = 0
                            end
                            break
                        end
                    end
                end
                
                -- 2. Fallback nếu còn remainingQty
                if remainingQty > 0 then
                    for k, item in pairs(inventory) do
                        if type(item) == 'table' and item.name == itemName and remainingQty > 0 then
                            local shouldDelete = true
                            if isMetadataSensitive and itemMetadata then
                                shouldDelete = metaCompare(item.metadata, itemMetadata)
                            end
                            
                            if shouldDelete then
                                local itemQty = tonumber(item.count) or tonumber(item.amount) or 1
                                if itemQty <= remainingQty then
                                    remainingQty = remainingQty - itemQty
                                    inventory[k] = nil
                                else
                                    local newCount = itemQty - remainingQty
                                    item.count = newCount
                                    if item.amount then item.amount = newCount end
                                    remainingQty = 0
                                end
                            end
                        end
                    end
                end
                
                -- 3. Rebuild clean array trước khi encode JSON
                if remainingQty < quantity then
                    local cleanInventory = {}
                    for _, it in pairs(inventory) do
                        if type(it) == 'table' and it.name and (tonumber(it.count) or tonumber(it.amount) or 0) > 0 then
                            table.insert(cleanInventory, it)
                        end
                    end
                    MySQL.update.await('UPDATE players SET inventory = ? WHERE ' .. queryField .. ' = ?', {
                        json.encode(cleanInventory),
                        queryVal
                    })
                    success = true
                end
            end
        end
        
    elseif deleteType == 'vehicle' then
        -- Xóa từ cốp xe
        local plate = targetData.plate
        local targetSlot = targetData.slot
        local targetSlotNum = tonumber(targetSlot)
        local vehicleData = MySQL.query.await('SELECT trunk FROM player_vehicles WHERE plate = ?', {plate})
        
        if vehicleData and vehicleData[1] then
            local trunk = json.decode(vehicleData[1].trunk or '[]') or {}
            local remainingQty = quantity
            
            -- 1. Nếu có targetSlot, ưu tiên tìm đúng item có slot đó
            if targetSlotNum then
                for k, item in pairs(trunk) do
                    if type(item) == 'table' and item.name == itemName and tonumber(item.slot) == targetSlotNum then
                        local itemQty = tonumber(item.count) or tonumber(item.amount) or 1
                        if itemQty <= remainingQty then
                            remainingQty = remainingQty - itemQty
                            trunk[k] = nil
                        else
                            local newCount = itemQty - remainingQty
                            item.count = newCount
                            if item.amount then item.amount = newCount end
                            remainingQty = 0
                        end
                        break
                    end
                end
            end
            
            -- 2. Fallback nếu còn remainingQty
            if remainingQty > 0 then
                for k, item in pairs(trunk) do
                    if type(item) == 'table' and item.name == itemName and remainingQty > 0 then
                        local shouldDelete = true
                        if isMetadataSensitive and itemMetadata then
                            shouldDelete = metaCompare(item.metadata, itemMetadata)
                        end
                        
                        if shouldDelete then
                            local itemQty = tonumber(item.count) or tonumber(item.amount) or 1
                            if itemQty <= remainingQty then
                                remainingQty = remainingQty - itemQty
                                trunk[k] = nil
                            else
                                local newCount = itemQty - remainingQty
                                item.count = newCount
                                if item.amount then item.amount = newCount end
                                remainingQty = 0
                            end
                        end
                    end
                end
            end
            
            -- 3. Rebuild clean array trước khi encode JSON
            if remainingQty < quantity then
                local cleanTrunk = {}
                for _, it in pairs(trunk) do
                    if type(it) == 'table' and it.name and (tonumber(it.count) or tonumber(it.amount) or 0) > 0 then
                        table.insert(cleanTrunk, it)
                    end
                end
                MySQL.update.await('UPDATE player_vehicles SET trunk = ? WHERE plate = ?', {
                    json.encode(cleanTrunk),
                    plate
                })
                success = true
            end
        end
        
    elseif deleteType == 'storage' then
        -- Xóa từ kho khác (ox_inventory stashes)
        local storageName = targetData.storageName
        local targetSlot = targetData.slot
        local targetSlotNum = tonumber(targetSlot)
        local removedFromOx = false
        
        -- Thử xóa qua ox_inventory export trước (nếu inventory đang được load trong memory của ox_inventory)
        local oxInv = exports.ox_inventory:GetInventory(storageName, false)
        if oxInv then
            if targetSlotNum then
                local removed = exports.ox_inventory:RemoveItem(storageName, itemName, quantity, nil, targetSlotNum)
                if removed then
                    removedFromOx = true
                    success = true
                end
            end
            if not removedFromOx and oxInv.items then
                local remainingQty = quantity
                for slotKey, item in pairs(oxInv.items) do
                    if item and item.name == itemName and remainingQty > 0 then
                        local shouldDelete = true
                        if isMetadataSensitive and itemMetadata then
                            shouldDelete = metaCompare(item.metadata, itemMetadata)
                        end
                        
                        if shouldDelete then
                            local itemQty = item.count or 0
                            local qtyToRemove = math.min(itemQty, remainingQty)
                            local removed = exports.ox_inventory:RemoveItem(storageName, itemName, qtyToRemove, nil, item.slot or slotKey)
                            if removed then
                                remainingQty = remainingQty - qtyToRemove
                            end
                        end
                    end
                end
                if remainingQty < quantity then
                    removedFromOx = true
                    success = true
                end
            end
        end
        
        -- Nếu chưa xóa qua export (kho offline hoặc chưa load), cập nhật trực tiếp DB
        if not success then
            local storageData = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', {storageName})
            
            if storageData and storageData[1] then
                local data = json.decode(storageData[1].data or '[]') or {}
                local remainingQty = quantity
                
                -- 1. Nếu có targetSlot, ưu tiên tìm đúng item có slot đó
                if targetSlotNum then
                    for k, item in pairs(data) do
                        if type(item) == 'table' and item.name == itemName and tonumber(item.slot) == targetSlotNum then
                            local itemQty = tonumber(item.count) or tonumber(item.amount) or 1
                            if itemQty <= remainingQty then
                                remainingQty = remainingQty - itemQty
                                data[k] = nil
                            else
                                local newCount = itemQty - remainingQty
                                item.count = newCount
                                if item.amount then item.amount = newCount end
                                remainingQty = 0
                            end
                            break
                        end
                    end
                end
                
                -- 2. Fallback nếu còn remainingQty
                if remainingQty > 0 then
                    for k, item in pairs(data) do
                        if type(item) == 'table' and item.name == itemName and remainingQty > 0 then
                            local shouldDelete = true
                            if isMetadataSensitive and itemMetadata then
                                shouldDelete = metaCompare(item.metadata, itemMetadata)
                            end
                            
                            if shouldDelete then
                                local itemQty = tonumber(item.count) or tonumber(item.amount) or 1
                                if itemQty <= remainingQty then
                                    remainingQty = remainingQty - itemQty
                                    data[k] = nil
                                else
                                    local newCount = itemQty - remainingQty
                                    item.count = newCount
                                    if item.amount then item.amount = newCount end
                                    remainingQty = 0
                                end
                            end
                        end
                    end
                end
                
                -- 3. Rebuild clean sequential array để tránh tạo sparse object JSON làm hỏng kho
                if remainingQty < quantity then
                    local cleanData = {}
                    for _, it in pairs(data) do
                        if type(it) == 'table' and it.name and (tonumber(it.count) or tonumber(it.amount) or 0) > 0 then
                            table.insert(cleanData, it)
                        end
                    end
                    
                    MySQL.update.await('UPDATE ox_inventory SET data = ? WHERE name = ?', {
                        json.encode(cleanData),
                        storageName
                    })
                    success = true
                end
            end
        end
    end
    
    TriggerClientEvent('xn_adminitem:deleteResult', src, success)
end)

-- Lấy danh sách tất cả items
RegisterNetEvent('xn_adminitem:getAllItems', function()
    local src = source
    local license = getPlayerLicense(src)
    local items = getItemsList()
    local canGet = LicenseManager:canGetItem(license)
    local canEdit = LicenseManager:canEditLimit(license)
    
    for _, item in ipairs(items) do
        item.limit = LicenseManager:getItemLimit(item.name)
        item.used = LicenseManager:getUsedQuantity(license, item.name)
        item.blacklisted = LicenseManager:isBlacklisted(item.name)
    end
    
    TriggerClientEvent('xn_adminitem:allItems', src, {
        items = items,
        canGet = canGet,
        canEdit = canEdit
    })
end)

local function sendToDiscord(license, playerName, itemName, count, reason)
    local webhook = Config.Webhook
    if not webhook or webhook == "" then return end
    
    local items = exports.ox_inventory:Items()
    local itemData = items[itemName]
    local itemLabel = itemData and itemData.label or itemName
    
    local embed = {
        {
            title = "📥 Admin Lấy Vật Phẩm",
            color = 65280, -- Green
            fields = {
                { name = "Người thực hiện", value = string.format("%s (%s)", playerName, license), inline = false },
                { name = "Vật phẩm", value = string.format("%dx **%s** (%s)", count, itemLabel, itemName), inline = true },
                { name = "Lý do", value = reason, inline = false },
                { name = "Thời gian", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true }
            },
            footer = {
                text = "XN Admin Item Logging"
            }
        }
    }
    
    PerformHttpRequest(webhook, function(status, text, headers) end, 'POST', json.encode({ embeds = embed }), { ['Content-Type'] = 'application/json' })
end

-- Lấy item cho mod/admin từ Items Server tab
RegisterNetEvent('xn_adminitem:getServerItem', function(itemName, count, reason)
    local src = source
    local license = getPlayerLicense(src)
    
    if not LicenseManager:canGetItem(license) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Bạn không có quyền lấy vật phẩm!'
        })
        return
    end

    if LicenseManager:isBlacklisted(itemName) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Vật phẩm này đã bị blacklist, không thể lấy!'
        })
        return
    end
    
    if not reason or string.gsub(reason, "%s+", "") == "" then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Lý do lấy không được để trống!'
        })
        return
    end
    
    count = tonumber(count) or 0
    if count <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Số lượng không hợp lệ!'
        })
        return
    end
    
    local limit = LicenseManager:getItemLimit(itemName)
    local used = LicenseManager:getUsedQuantity(license, itemName)
    
    if used + count > limit then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = string.format('Vượt quá giới hạn hàng ngày! Còn lại có thể lấy: %d', math.max(0, limit - used))
        })
        return
    end
    
    -- Thêm item vào inventory của player
    local added = exports.ox_inventory:AddItem(src, itemName, count)
    if added then
        LicenseManager:addUsedQuantity(license, itemName, count)
        
        -- Send Discord log
        local playerName = GetPlayerName(src) or "Unknown"
        local Player = exports.qbx_core:GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        end
        sendToDiscord(license, playerName, itemName, count, reason)
        
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = string.format('Đã lấy %dx %s', count, itemName)
        })
        
        -- Refresh UI for the source
        local items = getItemsList()
        local canGet = LicenseManager:canGetItem(license)
        local canEdit = LicenseManager:canEditLimit(license)
        for _, item in ipairs(items) do
            item.limit = LicenseManager:getItemLimit(item.name)
            item.used = LicenseManager:getUsedQuantity(license, item.name)
            item.blacklisted = LicenseManager:isBlacklisted(item.name)
        end
        TriggerClientEvent('xn_adminitem:allItems', src, {
            items = items,
            canGet = canGet,
            canEdit = canEdit
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Kho đồ không đủ chỗ trống hoặc lỗi!'
        })
    end
end)

-- Chỉnh sửa giới hạn hàng ngày của item
RegisterNetEvent('xn_adminitem:setItemLimit', function(itemName, limit)
    local src = source
    local license = getPlayerLicense(src)
    
    if not LicenseManager:canEditLimit(license) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Bạn không có quyền chỉnh sửa giới hạn!'
        })
        return
    end
    
    limit = tonumber(limit) or 0
    if limit < 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Giới hạn không hợp lệ!'
        })
        return
    end
    
    LicenseManager:setItemLimit(itemName, limit)
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = string.format('Đã cập nhật giới hạn item %s thành %d', itemName, limit)
    })
    
    -- Refresh UI for the source
    local items = getItemsList()
    local canGet = LicenseManager:canGetItem(license)
    local canEdit = LicenseManager:canEditLimit(license)
    for _, item in ipairs(items) do
        item.limit = LicenseManager:getItemLimit(item.name)
        item.used = LicenseManager:getUsedQuantity(license, item.name)
        item.blacklisted = LicenseManager:isBlacklisted(item.name)
    end
    TriggerClientEvent('xn_adminitem:allItems', src, {
        items = items,
        canGet = canGet,
        canEdit = canEdit
    })
end)

-- Chỉnh sửa trạng thái blacklist của item
RegisterNetEvent('xn_adminitem:setItemBlacklist', function(itemName, isBlacklisted)
    local src = source
    local license = getPlayerLicense(src)
    
    if not LicenseManager:canEditLimit(license) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Bạn không có quyền chỉnh sửa blacklist!'
        })
        return
    end
    
    LicenseManager:setItemBlacklist(itemName, isBlacklisted)
    
    local statusStr = isBlacklisted and "thêm vào blacklist" or "xóa khỏi blacklist"
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = string.format('Đã %s item %s', statusStr, itemName)
    })
    
    -- Refresh UI for the source
    local items = getItemsList()
    local canGet = LicenseManager:canGetItem(license)
    local canEdit = LicenseManager:canEditLimit(license)
    for _, item in ipairs(items) do
        item.limit = LicenseManager:getItemLimit(item.name)
        item.used = LicenseManager:getUsedQuantity(license, item.name)
        item.blacklisted = LicenseManager:isBlacklisted(item.name)
    end
    TriggerClientEvent('xn_adminitem:allItems', src, {
        items = items,
        canGet = canGet,
        canEdit = canEdit
    })
end)

-- ======================= TAB PLAYERS =======================
RegisterNetEvent('xn_adminitem:getPlayers', function(data)
    local src = source
    
    -- Xử lý cả trường hợp data là number (old format) hoặc table (new format)
    local page, searchTerm
    if type(data) == 'table' then
        page = data.page or 1
        searchTerm = data.searchTerm or ''
    else
        -- Backward compatibility: data là number
        page = data or 1
        searchTerm = ''
    end
    
    print('[ADMIN ITEM] getPlayers - Page:', page, 'Search:', searchTerm)
    
    local itemsPerPage = 20
    local offset = (page - 1) * itemsPerPage
    
    local players, totalCount
    
    if searchTerm ~= '' then
        -- Tìm kiếm với filter
        local searchPattern = '%' .. searchTerm .. '%'
        print('[ADMIN ITEM] Searching with pattern:', searchPattern)
        
        players = MySQL.query.await([[
            SELECT pid, citizenid, charinfo, inventory 
            FROM players 
            WHERE LOWER(citizenid) LIKE LOWER(?) 
               OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname'))) LIKE LOWER(?)
               OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) LIKE LOWER(?)
               OR CAST(pid AS CHAR) LIKE ?
            ORDER BY pid DESC 
            LIMIT ? OFFSET ?
        ]], {searchPattern, searchPattern, searchPattern, searchPattern, itemsPerPage, offset})
        
        totalCount = MySQL.scalar.await([[
            SELECT COUNT(*) FROM players 
            WHERE LOWER(citizenid) LIKE LOWER(?) 
               OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname'))) LIKE LOWER(?)
               OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) LIKE LOWER(?)
               OR CAST(pid AS CHAR) LIKE ?
        ]], {searchPattern, searchPattern, searchPattern, searchPattern})
        
        print('[ADMIN ITEM] Found', totalCount, 'players')
    else
        -- Load bình thường
        players = MySQL.query.await([[
            SELECT pid, citizenid, charinfo, inventory 
            FROM players 
            ORDER BY pid DESC 
            LIMIT ? OFFSET ?
        ]], {itemsPerPage, offset})
        
        totalCount = MySQL.scalar.await('SELECT COUNT(*) FROM players', {})
    end
    
    local results = {}
    for _, player in ipairs(players) do
        local charinfo = json.decode(player.charinfo or '{}')
        table.insert(results, {
            pid = player.pid,
            citizenid = player.citizenid,
            firstname = charinfo.firstname or 'Unknown',
            lastname = charinfo.lastname or 'Unknown',
            inventory = player.inventory
        })
    end
    
    TriggerClientEvent('xn_adminitem:playersData', src, {
        players = results,
        totalPages = math.ceil(totalCount / itemsPerPage),
        currentPage = page
    })
end)

RegisterNetEvent('xn_adminitem:getPlayerInventory', function(citizenid)
    local src = source
    
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    local targetSource = nil
    if targetPlayer and targetPlayer.PlayerData and targetPlayer.PlayerData.source then
        targetSource = targetPlayer.PlayerData.source
    else
        for _, playerId in ipairs(GetPlayers()) do
            local p = exports.qbx_core:GetPlayer(tonumber(playerId))
            if p and p.PlayerData and p.PlayerData.citizenid == citizenid then
                targetSource = tonumber(playerId)
                break
            end
        end
    end
    
    local inventory = {}
    if targetSource then
        local oxInv = exports.ox_inventory:GetInventory(targetSource, false)
        if oxInv and oxInv.items then
            for _, item in pairs(oxInv.items) do
                if item and item.name then
                    table.insert(inventory, item)
                end
            end
        end
    else
        local player = MySQL.query.await('SELECT inventory FROM players WHERE citizenid = ?', {citizenid})
        if player and player[1] then
            local dbInv = json.decode(player[1].inventory or '[]')
            if type(dbInv) == 'table' then
                for _, item in pairs(dbInv) do
                    if type(item) == 'table' and item.name then
                        table.insert(inventory, item)
                    end
                end
            end
        end
    end
    
    TriggerClientEvent('xn_adminitem:playerInventoryData', src, {
        citizenid = citizenid,
        inventory = inventory
    })
end)

-- ======================= TAB VEHICLES =======================
RegisterNetEvent('xn_adminitem:getVehicles', function(data)
    local src = source
    
    -- Xử lý cả trường hợp data là number (old format) hoặc table (new format)
    local page, searchTerm
    if type(data) == 'table' then
        page = data.page or 1
        searchTerm = data.searchTerm or ''
    else
        page = data or 1
        searchTerm = ''
    end
    
    print('[ADMIN ITEM] getVehicles - Page:', page, 'Search:', searchTerm)
    
    local itemsPerPage = 20
    
    -- Lấy TẤT CẢ vehicles (không dùng LIMIT/OFFSET vì cần sort theo itemCount)
    local query = [[
        SELECT 
            pv.citizenid, 
            pv.plate, 
            pv.trunk,
            p.charinfo
        FROM player_vehicles pv
        LEFT JOIN players p ON pv.citizenid = p.citizenid
    ]]
    
    local vehicles
    if searchTerm ~= '' then
        local searchPattern = '%' .. searchTerm .. '%'
        print('[ADMIN ITEM] Searching vehicles with pattern:', searchPattern)
        query = query .. [[ WHERE LOWER(pv.plate) LIKE LOWER(?) OR LOWER(pv.citizenid) LIKE LOWER(?) ]]
        vehicles = MySQL.query.await(query, {searchPattern, searchPattern})
    else
        vehicles = MySQL.query.await(query, {})
    end
    
    local allResults = {}
    for _, vehicle in ipairs(vehicles) do
        local charinfo = json.decode(vehicle.charinfo or '{}')
        
        -- Lấy số lượng items trong trunk từ cột trunk (JSON)
        local itemCount = 0
        if vehicle.trunk then
            local trunkItems = json.decode(vehicle.trunk or '[]')
            if type(trunkItems) == 'table' then
                itemCount = #trunkItems
            end
        end
        
        local ownername = (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
        
        -- Nếu đang search, SQL đã filter rồi, chỉ cần thêm filter ownername
        local matchSearch = true
        if searchTerm ~= '' then
            -- Check thêm ownername vì SQL không filter được field này
            local lowerSearch = searchTerm:lower()
            local lowerOwner = ownername:lower()
            local lowerPlate = vehicle.plate:lower()
            local lowerCitizen = vehicle.citizenid:lower()
            
            matchSearch = lowerPlate:find(lowerSearch, 1, true) ~= nil or
                         lowerCitizen:find(lowerSearch, 1, true) ~= nil or
                         lowerOwner:find(lowerSearch, 1, true) ~= nil
        end
        
        -- Chỉ thêm vào danh sách nếu có item và match search
        if itemCount > 0 and matchSearch then
            table.insert(allResults, {
                citizenid = vehicle.citizenid,
                plate = vehicle.plate,
                trunk = vehicle.trunk,
                ownername = ownername,
                itemCount = itemCount
            })
        end
    end
    
    -- Sắp xếp TOÀN BỘ theo số lượng item từ nhiều đến ít
    table.sort(allResults, function(a, b)
        return (a.itemCount or 0) > (b.itemCount or 0)
    end)
    
    -- Áp dụng pagination SAU khi đã sort
    local offset = (page - 1) * itemsPerPage
    local finalResults = {}
    for i = offset + 1, math.min(offset + itemsPerPage, #allResults) do
        table.insert(finalResults, allResults[i])
    end
    
    TriggerClientEvent('xn_adminitem:vehiclesData', src, {
        vehicles = finalResults,
        totalPages = math.ceil(#allResults / itemsPerPage),
        currentPage = page
    })
end)

RegisterNetEvent('xn_adminitem:getVehicleTrunk', function(plate)
    local src = source
    
    -- Lấy trunk data từ cột trunk trong player_vehicles
    local vehicle = MySQL.query.await('SELECT trunk FROM player_vehicles WHERE plate = ?', {plate})
    
    if vehicle and vehicle[1] and vehicle[1].trunk then
        local trunkData = json.decode(vehicle[1].trunk or '[]')
        TriggerClientEvent('xn_adminitem:vehicleTrunkData', src, {
            plate = plate,
            trunk = trunkData
        })
    else
        TriggerClientEvent('xn_adminitem:vehicleTrunkData', src, {
            plate = plate,
            trunk = {}
        })
    end
end)

-- ======================= TAB MOTELS =======================
RegisterNetEvent('xn_adminitem:getMotels', function()
    local src = source
    
    local motels = MySQL.query.await('SELECT motel, rooms FROM renzu_motels', {})
    
    local results = {}
    for _, motel in ipairs(motels) do
        local rooms = json.decode(motel.rooms or '[]')
        local roomsData = {}
        
        for roomIndex, room in ipairs(rooms) do
            local roomInfo = {
                roomNumber = roomIndex,
                locked = room.lock or false,
                tenants = {}
            }
            
            if room.players and type(room.players) == 'table' then
                for citizenid, playerData in pairs(room.players) do
                    -- Lấy tên từ database
                    local playerInfo = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
                    local charinfo = {}
                    if playerInfo and playerInfo[1] then
                        charinfo = json.decode(playerInfo[1].charinfo or '{}')
                    end
                    
                    table.insert(roomInfo.tenants, {
                        citizenid = citizenid,
                        name = playerData.name or (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or ''),
                        duration = playerData.duration
                    })
                end
            end
            
            -- Lấy số lượng items trong room stash
            -- Format: stash_vinwood_motels_room_1 (tên motel đã bao gồm '_motels')
            local motelNameFormatted = string.lower(motel.motel):gsub(' ', '_')
            -- Nếu tên đã có '_motels' thì không thêm nữa
            if not motelNameFormatted:match('_motels$') then
                motelNameFormatted = motelNameFormatted .. '_motels'
            end
            local stashName = 'stash_' .. motelNameFormatted .. '_room_' .. roomIndex
            local stashData = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', {stashName})
            local itemCount = 0
            if stashData and stashData[1] then
                local items = json.decode(stashData[1].data or '[]')
                itemCount = #items
            end
            roomInfo.itemCount = itemCount
            
            table.insert(roomsData, roomInfo)
        end
        
        table.insert(results, {
            motelName = motel.motel,
            rooms = roomsData
        })
    end
    
    TriggerClientEvent('xn_adminitem:motelsData', src, results)
end)

RegisterNetEvent('xn_adminitem:getMotelRoomInventory', function(motelName, roomNumber)
    local src = source
    
    -- Format stash name theo pattern: stash_vinwood_motels_room_1
    local motelNameFormatted = string.lower(motelName):gsub(' ', '_')
    -- Nếu tên đã có '_motels' thì không thêm nữa
    if not motelNameFormatted:match('_motels$') then
        motelNameFormatted = motelNameFormatted .. '_motels'
    end
    local stashName = 'stash_' .. motelNameFormatted .. '_room_' .. roomNumber
    
    local stash = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', {stashName})
    
    if stash and stash[1] then
        local stashData = json.decode(stash[1].data or '[]')
        TriggerClientEvent('xn_adminitem:motelRoomInventoryData', src, {
            motelName = motelName,
            roomNumber = roomNumber,
            inventory = stashData
        })
    else
        TriggerClientEvent('xn_adminitem:motelRoomInventoryData', src, {
            motelName = motelName,
            roomNumber = roomNumber,
            inventory = {}
        })
    end
end)

-- ======================= TAB OTHER STASHES =======================
RegisterNetEvent('xn_adminitem:getOtherStashes', function(data)
    local src = source
    
    -- Xử lý cả trường hợp data là number (old format) hoặc table (new format)
    local page, searchTerm
    if type(data) == 'table' then
        page = data.page or 1
        searchTerm = data.searchTerm or ''
    else
        page = data or 1
        searchTerm = ''
    end
    
    print('[ADMIN ITEM] getOtherStashes - Page:', page, 'Search:', searchTerm)
    
    local itemsPerPage = 20
    
    -- Lấy TẤT CẢ stashes
    local query = [[
        SELECT 
            oi.owner, 
            oi.name, 
            oi.data,
            p.charinfo
        FROM ox_inventory oi
        LEFT JOIN players p ON oi.owner = p.citizenid
        WHERE oi.name NOT LIKE 'trunk%' 
        AND oi.name NOT LIKE 'glovebox%'
        AND oi.owner IS NOT NULL
    ]]
    
    local stashes
    if searchTerm ~= '' then
        local searchPattern = '%' .. searchTerm .. '%'
        print('[ADMIN ITEM] Searching stashes with pattern:', searchPattern)
        query = query .. [[ AND (LOWER(oi.name) LIKE LOWER(?) OR LOWER(oi.owner) LIKE LOWER(?)) ]]
        stashes = MySQL.query.await(query, {searchPattern, searchPattern})
    else
        stashes = MySQL.query.await(query, {})
    end
    
    local allResults = {}
    for _, stash in ipairs(stashes) do
        local charinfo = json.decode(stash.charinfo or '{}')
        local stashData = json.decode(stash.data or '[]')
        
        local ownerName = (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or '')
        local ownerId = stash.owner
        
        -- Xử lý các kho đặc biệt có citizenid trong tên (vd: buucuc_A151M92Q)
        -- Pattern: tênkho_citizenid
        local stashPrefix, extractedCitizenid = stash.name:match("^([^_]+)_([A-Z0-9]+)$")
        
        if stashPrefix and extractedCitizenid and #extractedCitizenid >= 8 then
            -- Có citizenid trong tên kho, query lại để lấy tên chủ sở hữu
            -- Trim khoảng trắng có thể có
            extractedCitizenid = extractedCitizenid:gsub("%s+", "")
            local ownerData = MySQL.query.await('SELECT charinfo FROM players WHERE TRIM(citizenid) = ?', {extractedCitizenid})
            if ownerData and ownerData[1] then
                local ownerCharinfo = json.decode(ownerData[1].charinfo or '{}')
                ownerName = (ownerCharinfo.firstname or 'Unknown') .. ' ' .. (ownerCharinfo.lastname or '')
                ownerId = extractedCitizenid
            end
        end
        
        local itemCount = #stashData
        
        -- Nếu đang search, SQL đã filter rồi, chỉ cần thêm filter ownername
        local matchSearch = true
        if searchTerm ~= '' then
            -- Check thêm ownername vì SQL không filter được field này
            local lowerSearch = searchTerm:lower()
            local lowerOwner = ownerName:lower()
            local lowerName = stash.name:lower()
            local lowerOwnerId = ownerId:lower()
            
            matchSearch = lowerName:find(lowerSearch, 1, true) ~= nil or
                         lowerOwnerId:find(lowerSearch, 1, true) ~= nil or
                         lowerOwner:find(lowerSearch, 1, true) ~= nil
        end
        
        -- Chỉ thêm vào danh sách nếu có item và match search
        if itemCount > 0 and matchSearch then
            table.insert(allResults, {
                owner = ownerId,
                name = stash.name,
                ownername = ownerName,
                itemCount = itemCount
            })
        end
    end
    
    -- Sắp xếp TOÀN BỘ theo số lượng item từ nhiều đến ít
    table.sort(allResults, function(a, b)
        return (a.itemCount or 0) > (b.itemCount or 0)
    end)
    
    -- Áp dụng pagination SAU khi đã sort
    local offset = (page - 1) * itemsPerPage
    local finalResults = {}
    for i = offset + 1, math.min(offset + itemsPerPage, #allResults) do
        table.insert(finalResults, allResults[i])
    end
    
    TriggerClientEvent('xn_adminitem:otherStashesData', src, {
        stashes = finalResults,
        totalPages = math.ceil(#allResults / itemsPerPage),
        currentPage = page
    })
end)

RegisterNetEvent('xn_adminitem:getStashInventory', function(stashName)
    local src = source
    local inventory = {}
    
    local oxInv = exports.ox_inventory:GetInventory(stashName, false)
    if oxInv and oxInv.items then
        for _, it in pairs(oxInv.items) do
            if it and it.name then
                table.insert(inventory, it)
            end
        end
    else
        local stash = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', {stashName})
        if stash and stash[1] then
            inventory = json.decode(stash[1].data or '[]')
        end
    end
    
    TriggerClientEvent('xn_adminitem:stashInventoryData', src, {
        stashName = stashName,
        inventory = inventory
    })
end)

-- Event lấy item từ player inventory
RegisterNetEvent('xn_adminitem:takeItemFromPlayer', function(data)
    local src = source
    print('[SERVER] takeItemFromPlayer - Admin source:', src, 'Target citizenid:', data.citizenid, 'Item:', data.itemName, 'Count:', data.count)
    
    -- Validate data
    if not data or not data.citizenid or not data.itemName or not data.count then
        print('[SERVER] takeItemFromPlayer - Invalid data received')
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Dữ liệu không hợp lệ'
        })
        return
    end
    
    -- Get target player's source
    local targetSource = nil
    local players = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {data.citizenid})
    
    if not players or not players[1] then
        print('[SERVER] takeItemFromPlayer - Player not found in database')
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không tìm thấy người chơi'
        })
        return
    end
    
    -- Try to find online player
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(data.citizenid)
    if targetPlayer and targetPlayer.PlayerData and targetPlayer.PlayerData.source then
        targetSource = targetPlayer.PlayerData.source
    else
        for _, playerId in ipairs(GetPlayers()) do
            local Player = exports.qbx_core:GetPlayer(tonumber(playerId))
            if Player and Player.PlayerData and Player.PlayerData.citizenid == data.citizenid then
                targetSource = tonumber(playerId)
                break
            end
        end
    end
    
    local count = tonumber(data.count) or 1
    local slot = tonumber(data.slot)
    local itemTaken = false
    local takenMetadata = nil
    
    -- Nếu người chơi online - dùng ox_inventory API
    if targetSource then
        print('[SERVER] takeItemFromPlayer - Target player is ONLINE (source: ' .. tostring(targetSource) .. '), using ox_inventory API')
        
        -- Lấy item metadata và slot từ inventory online nếu có
        local targetInv = exports.ox_inventory:GetInventory(targetSource, false)
        if targetInv and targetInv.items then
            if slot and targetInv.items[slot] and targetInv.items[slot].name == data.itemName then
                takenMetadata = targetInv.items[slot].metadata
            else
                for _, it in pairs(targetInv.items) do
                    if it and it.name == data.itemName then
                        takenMetadata = it.metadata
                        slot = it.slot
                        break
                    end
                end
            end
        end
        
        -- Thử xóa với slot
        local removed = false
        if slot then
            removed = exports.ox_inventory:RemoveItem(targetSource, data.itemName, count, nil, slot)
        end
        
        -- Nếu không xóa được bằng slot, thử xóa theo tên item
        if not removed then
            removed = exports.ox_inventory:RemoveItem(targetSource, data.itemName, count)
        end
        
        if removed then
            print('[SERVER] takeItemFromPlayer - Successfully removed item from online player')
            itemTaken = true
            
            -- Notify target player
            TriggerClientEvent('ox_lib:notify', targetSource, {
                type = 'inform',
                description = 'Admin đã lấy ' .. count .. 'x ' .. data.itemName .. ' từ túi của bạn'
            })
        else
            print('[SERVER] takeItemFromPlayer - Failed to remove item from online player')
        end
    else
        -- Nếu người chơi offline - cập nhật database bảng `players` trực tiếp
        print('[SERVER] takeItemFromPlayer - Target player is OFFLINE, using SQL method on players table')
        
        local playerData = MySQL.query.await('SELECT inventory FROM players WHERE citizenid = ?', {data.citizenid})
        
        if playerData and playerData[1] then
            local inventory = json.decode(playerData[1].inventory or '[]')
            if type(inventory) ~= 'table' then inventory = {} end
            
            print('[SERVER] takeItemFromPlayer - Found offline player inventory')
            
            -- Tìm item trong inventory (ưu tiên theo slot + itemName, nếu không thì theo itemName)
            local itemKey = nil
            local foundItem = nil
            
            for k, item in pairs(inventory) do
                if type(item) == 'table' and item.name == data.itemName then
                    if slot and tonumber(item.slot) == slot then
                        itemKey = k
                        foundItem = item
                        break
                    elseif not foundItem then
                        itemKey = k
                        foundItem = item
                    end
                end
            end
            
            if foundItem and itemKey then
                local currentCount = tonumber(foundItem.count) or tonumber(foundItem.amount) or 1
                takenMetadata = foundItem.metadata
                print('[SERVER] takeItemFromPlayer - Found item with count', currentCount)
                
                if currentCount >= count then
                    if currentCount == count then
                        -- Xóa item hoàn toàn khỏi inventory
                        inventory[itemKey] = nil
                        print('[SERVER] takeItemFromPlayer - Removed item completely from offline inventory')
                    else
                        -- Giảm số lượng
                        local newCount = currentCount - count
                        foundItem.count = newCount
                        if foundItem.amount then foundItem.amount = newCount end
                        inventory[itemKey] = foundItem
                        print('[SERVER] takeItemFromPlayer - Reduced item count to', newCount)
                    end
                    
                    -- Rebuild inventory array để tránh khoảng trống / null keys
                    local cleanInventory = {}
                    for _, it in pairs(inventory) do
                        if type(it) == 'table' and it.name then
                            table.insert(cleanInventory, it)
                        end
                    end
                    
                    local newData = json.encode(cleanInventory)
                    MySQL.update.await('UPDATE players SET inventory = ? WHERE citizenid = ?', {newData, data.citizenid})
                    print('[SERVER] takeItemFromPlayer - Updated offline player inventory in database')
                    
                    itemTaken = true
                else
                    print('[SERVER] takeItemFromPlayer - Not enough items (has:', currentCount, 'need:', count, ')')
                end
            else
                print('[SERVER] takeItemFromPlayer - Item not found in offline inventory')
            end
        else
            print('[SERVER] takeItemFromPlayer - No player record found for offline player')
        end
    end
    
    -- Nếu đã lấy được item, thêm vào túi admin
    if itemTaken then
        local added = exports.ox_inventory:AddItem(src, data.itemName, count, takenMetadata or data.metadata)
        
        if added then
            print('[SERVER] takeItemFromPlayer - Successfully added item to admin')
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                description = 'Đã lấy ' .. count .. 'x ' .. data.itemName .. (targetSource and '' or ' (Offline)')
            })
            
            -- Gửi lại danh sách inventory mới cập nhật cho Admin UI
            local updatedInventory = {}
            if targetSource then
                local oxInv = exports.ox_inventory:GetInventory(targetSource, false)
                if oxInv and oxInv.items then
                    for _, it in pairs(oxInv.items) do
                        if it and it.name then
                            table.insert(updatedInventory, it)
                        end
                    end
                end
            else
                local pData = MySQL.query.await('SELECT inventory FROM players WHERE citizenid = ?', {data.citizenid})
                if pData and pData[1] then
                    local dbInv = json.decode(pData[1].inventory or '[]')
                    if type(dbInv) == 'table' then
                        for _, it in pairs(dbInv) do
                            if type(it) == 'table' and it.name then
                                table.insert(updatedInventory, it)
                            end
                        end
                    end
                end
            end
            
            TriggerClientEvent('xn_adminitem:playerInventoryData', src, {
                citizenid = data.citizenid,
                inventory = updatedInventory
            })
        else
            print('[SERVER] takeItemFromPlayer - Failed to add item to admin')
            
            -- Nếu không thể thêm vào admin, hoàn trả item
            if targetSource then
                exports.ox_inventory:AddItem(targetSource, data.itemName, count, takenMetadata or data.metadata)
            else
                local pData = MySQL.query.await('SELECT inventory FROM players WHERE citizenid = ?', {data.citizenid})
                if pData and pData[1] then
                    local inv = json.decode(pData[1].inventory or '[]')
                    if type(inv) ~= 'table' then inv = {} end
                    
                    local restored = false
                    for _, it in pairs(inv) do
                        if type(it) == 'table' and it.name == data.itemName and slot and tonumber(it.slot) == slot then
                            it.count = (tonumber(it.count) or 1) + count
                            if it.amount then it.amount = (tonumber(it.amount) or 1) + count end
                            restored = true
                            break
                        end
                    end
                    
                    if not restored then
                        table.insert(inv, {
                            name = data.itemName,
                            count = count,
                            slot = slot or 1,
                            metadata = takenMetadata or data.metadata
                        })
                    end
                    
                    local cleanInv = {}
                    for _, it in pairs(inv) do
                        if type(it) == 'table' and it.name then
                            table.insert(cleanInv, it)
                        end
                    end
                    
                    MySQL.update.await('UPDATE players SET inventory = ? WHERE citizenid = ?', {json.encode(cleanInv), data.citizenid})
                    print('[SERVER] takeItemFromPlayer - Returned item to offline player inventory in database')
                end
            end
            
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = 'Túi đồ của bạn đã đầy hoặc không thể nhận item'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không thể lấy item từ người chơi'
        })
    end
end)

-- Event lấy item từ kho khác (stashes)
RegisterNetEvent('xn_adminitem:takeItemFromStash', function(data)
    local src = source
    print('[SERVER] takeItemFromStash - Admin source:', src, 'Stash:', data.stashName, 'Item:', data.itemName, 'Count:', data.count)
    
    -- Validate data
    if not data or not data.stashName or not data.itemName or not data.count then
        print('[SERVER] takeItemFromStash - Invalid data received')
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Dữ liệu không hợp lệ'
        })
        return
    end
    
    local count = tonumber(data.count) or 1
    local slot = tonumber(data.slot)
    local itemTaken = false
    local takenMetadata = nil
    local stashName = data.stashName
    
    -- 1. Thử lấy qua ox_inventory API (nếu stash đang active/loaded trong memory)
    local oxInv = exports.ox_inventory:GetInventory(stashName, false)
    if oxInv and oxInv.items then
        print('[SERVER] takeItemFromStash - Stash is active in ox_inventory memory')
        if slot and oxInv.items[slot] and oxInv.items[slot].name == data.itemName then
            takenMetadata = oxInv.items[slot].metadata
        else
            for _, it in pairs(oxInv.items) do
                if it and it.name == data.itemName then
                    takenMetadata = it.metadata
                    slot = it.slot
                    break
                end
            end
        end
        
        local removed = false
        if slot then
            removed = exports.ox_inventory:RemoveItem(stashName, data.itemName, count, nil, slot)
        end
        
        if not removed then
            removed = exports.ox_inventory:RemoveItem(stashName, data.itemName, count)
        end
        
        if removed then
            itemTaken = true
            print('[SERVER] takeItemFromStash - Successfully removed item via ox_inventory API')
        end
    end
    
    -- 2. Nếu chưa lấy được từ memory, lấy trực tiếp từ database table ox_inventory
    if not itemTaken then
        print('[SERVER] takeItemFromStash - Stash is in database, querying ox_inventory table')
        local stashDb = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', {stashName})
        
        if stashDb and stashDb[1] then
            local stashItems = json.decode(stashDb[1].data or '[]')
            if type(stashItems) ~= 'table' then stashItems = {} end
            
            local itemKey = nil
            local foundItem = nil
            
            for k, item in pairs(stashItems) do
                if type(item) == 'table' and item.name == data.itemName then
                    if slot and tonumber(item.slot) == slot then
                        itemKey = k
                        foundItem = item
                        break
                    elseif not foundItem then
                        itemKey = k
                        foundItem = item
                    end
                end
            end
            
            if foundItem and itemKey then
                local currentCount = tonumber(foundItem.count) or tonumber(foundItem.amount) or 1
                takenMetadata = foundItem.metadata
                print('[SERVER] takeItemFromStash - Found item in DB stash with count', currentCount)
                
                if currentCount >= count then
                    if currentCount == count then
                        stashItems[itemKey] = nil
                        print('[SERVER] takeItemFromStash - Removed item completely from DB stash')
                    else
                        local newCount = currentCount - count
                        foundItem.count = newCount
                        if foundItem.amount then foundItem.amount = newCount end
                        stashItems[itemKey] = foundItem
                        print('[SERVER] takeItemFromStash - Reduced item count to', newCount)
                    end
                    
                    local cleanStash = {}
                    for _, it in pairs(stashItems) do
                        if type(it) == 'table' and it.name and (tonumber(it.count) or tonumber(it.amount) or 0) > 0 then
                            table.insert(cleanStash, it)
                        end
                    end
                    
                    MySQL.update.await('UPDATE ox_inventory SET data = ? WHERE name = ?', {
                        json.encode(cleanStash),
                        stashName
                    })
                    print('[SERVER] takeItemFromStash - Updated stash inventory in database')
                    itemTaken = true
                else
                    print('[SERVER] takeItemFromStash - Not enough items (has:', currentCount, 'need:', count, ')')
                end
            else
                print('[SERVER] takeItemFromStash - Item not found in DB stash')
            end
        else
            print('[SERVER] takeItemFromStash - Stash not found in database')
        end
    end
    
    -- 3. Nếu đã trừ được từ kho, thêm vào túi Admin
    if itemTaken then
        local added = exports.ox_inventory:AddItem(src, data.itemName, count, takenMetadata or data.metadata)
        
        if added then
            print('[SERVER] takeItemFromStash - Successfully added item to admin')
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                description = 'Đã lấy ' .. count .. 'x ' .. data.itemName .. ' từ kho ' .. stashName
            })
            
            -- Gửi lại danh sách inventory mới cập nhật cho Admin UI
            local updatedInventory = {}
            local activeInv = exports.ox_inventory:GetInventory(stashName, false)
            if activeInv and activeInv.items then
                for _, it in pairs(activeInv.items) do
                    if it and it.name then
                        table.insert(updatedInventory, it)
                    end
                end
            else
                local sData = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', {stashName})
                if sData and sData[1] then
                    local dbInv = json.decode(sData[1].data or '[]')
                    if type(dbInv) == 'table' then
                        for _, it in pairs(dbInv) do
                            if type(it) == 'table' and it.name then
                                table.insert(updatedInventory, it)
                            end
                        end
                    end
                end
            end
            
            TriggerClientEvent('xn_adminitem:stashInventoryData', src, {
                stashName = stashName,
                inventory = updatedInventory
            })
        else
            print('[SERVER] takeItemFromStash - Failed to add item to admin, reverting item')
            
            -- Revert item back to stash
            local activeInv = exports.ox_inventory:GetInventory(stashName, false)
            if activeInv then
                exports.ox_inventory:AddItem(stashName, data.itemName, count, takenMetadata or data.metadata)
            else
                local sData = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', {stashName})
                if sData and sData[1] then
                    local inv = json.decode(sData[1].data or '[]')
                    if type(inv) ~= 'table' then inv = {} end
                    
                    local restored = false
                    for _, it in pairs(inv) do
                        if type(it) == 'table' and it.name == data.itemName and slot and tonumber(it.slot) == slot then
                            it.count = (tonumber(it.count) or 1) + count
                            if it.amount then it.amount = (tonumber(it.amount) or 1) + count end
                            restored = true
                            break
                        end
                    end
                    
                    if not restored then
                        table.insert(inv, {
                            name = data.itemName,
                            count = count,
                            slot = slot or 1,
                            metadata = takenMetadata or data.metadata
                        })
                    end
                    
                    local cleanInv = {}
                    for _, it in pairs(inv) do
                        if type(it) == 'table' and it.name then
                            table.insert(cleanInv, it)
                        end
                    end
                    
                    MySQL.update.await('UPDATE ox_inventory SET data = ? WHERE name = ?', {
                        json.encode(cleanInv),
                        stashName
                    })
                end
            end
            
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = 'Túi đồ của bạn đã đầy hoặc không thể nhận item'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không thể lấy item từ kho'
        })
    end
end)
