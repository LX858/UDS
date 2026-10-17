QBCore = exports['qb-core']:GetCoreObject()

Config.DeleteScreenshotUrl = "https://api2.discordtools.lol/deleteimage"

-- =====================================================
-- STAFF / ADMIN PERMISSION CHECK HELPER
-- =====================================================
function IsPlayerStaff(source)
    if not source or source == 0 then return true end -- console is always staff

    -- 1. Check Ace Permissions (FiveM / txAdmin / server.cfg)
    if IsPlayerAceAllowed(source, 'command.admin') or IsPlayerAceAllowed(source, 'command') or IsPlayerAceAllowed(source, 'admin') then
        return true
    end

    -- 2. Check QBCore / Qbox Permissions
    if QBCore and QBCore.Functions and QBCore.Functions.HasPermission then
        if QBCore.Functions.HasPermission(source, 'god') or QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'mod') then
            return true
        end
    end

    -- 3. Check Config.StaffGroup (by license matching)
    if Config.StaffGroup and #Config.StaffGroup > 0 then
        local playerIdentifiers = {}

        -- Lấy toàn bộ identifiers trực tiếp từ FiveM server engine
        for i = 0, GetNumPlayerIdentifiers(source) - 1 do
            local id = GetPlayerIdentifier(source, i)
            if id then
                local lowId = string.lower(id)
                playerIdentifiers[lowId] = true
                local _, val = string.match(lowId, "^([%w_]+):(.+)$")
                if val then
                    playerIdentifiers[val] = true
                end
            end
        end

        -- Lấy thêm từ QBCore PlayerData nếu player object đã load
        local player = QBCore and QBCore.Functions and QBCore.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.license then
            local pLic = string.lower(player.PlayerData.license)
            playerIdentifiers[pLic] = true
            local _, val = string.match(pLic, "^([%w_]+):(.+)$")
            if val then
                playerIdentifiers[val] = true
            end
        end

        -- So sánh với danh sách Config.StaffGroup
        for _, staffId in ipairs(Config.StaffGroup) do
            if staffId and type(staffId) == 'string' then
                local sId = string.lower(staffId)
                if playerIdentifiers[sId] then
                    return true
                end
                local _, val = string.match(sId, "^([%w_]+):(.+)$")
                if val and playerIdentifiers[val] then
                    return true
                end
            end
        end
    end

    return false
end

-- =====================================================
-- SERIAL GENERATION - Tạo số serial cho items từ giveclothing
-- =====================================================
local function GenerateText(len)
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local result = ''
    for i = 1, len do
        local idx = math.random(1, #charset)
        result = result .. charset:sub(idx, idx)
    end
    return result
end

local function GenerateSerial(middleText)
    -- Format: AD + ngày tháng năm (DDMMYY) + middleText (3 ký tự) + giờ phút giây (HHMMSS)
    -- middleText:
    --   - Admin trong game: A + 2 số cuối citizenid (ví dụ: A45)
    --   - Hệ thống console: HT + 1 chữ cái random (ví dụ: HTX)
    local dateStr = os.date("%d%m%y")  -- 230326
    local timeStr = os.date("%H%M%S")  -- 142530
    return ('%s%s%s%s'):format('MI', dateStr, middleText, timeStr)
end

local function GenerateSerialTattoo(text)
    if text and text:len() > 3 then
        return text
    end
    -- Format: GC + ngày tháng năm (DDMMYY) + 3 chữ cái ngẫu nhiên + giờ phút giây (HHMMSS)
    local dateStr = os.date("%d%m%y")  -- 230326
    local timeStr = os.date("%H%M%S")  -- 142530
    return ('%s%s%s%s'):format('GC', dateStr, text == nil and GenerateText(3) or text, timeStr)
end

-- Routing bucket management for clothing shop isolation
RegisterNetEvent('XNClothes:setRoutingBucket')
AddEventHandler('XNClothes:setRoutingBucket', function(enterShop)
    local src = source
    if enterShop then
        -- Generate random bucket ID (1000000 - 9999999) to avoid collision
        local randomBucket = math.random(1000000, 9999999)
        SetPlayerRoutingBucket(src, randomBucket)
    else
        -- Reset to default bucket 0
        SetPlayerRoutingBucket(src, 0)
    end
end) 

-- Chuyển đổi độ hiếm (DoHiem) sang cấp độ (Capdo)
local function GetCapdoByDoHiem(doHiem)
    local rarityToCapdo = {
        ["Common"] = 1,
        ["Uncommon"] = 2,
        ["Rare"] = 3,
        ["Epic"] = 4,
        ["Legendary"] = 5
    }
    return rarityToCapdo[doHiem] or 1
end

-- =====================================================
-- SQL-BASED RARITY SYSTEM - Hệ thống độ hiếm từ SQL
-- Table structure: one row per (component_id, is_prop, gender)
-- Rarity columns (Common, Uncommon, Rare, Epic, Legendary) = JSON arrays of drawable IDs
-- =====================================================

local RARITY_LEVELS = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'}

-- =====================================================
-- IN-MEMORY CACHE: toàn bộ rarity table load 1 lần khi start
-- Structure: rarityCache[gender][isPropBit][componentId][drawable] = "Rare"
-- Tra cứu O(1), không tốn SQL trên hot path
-- =====================================================
local rarityCache = nil  -- nil = chưa load

local function buildCacheKey(componentId, isProp, gender)
    local bit = isPropToBool(isProp) and 1 or 0
    return gender .. '_' .. bit .. '_' .. tonumber(componentId)
end

-- Decode JSON column safely (handles both raw table from oxmysql and JSON string)
local function decodeDrawables(val)
    if not val then return {} end
    if type(val) == "table" then return val end
    if type(val) == "string" then
        local ok, t = pcall(json.decode, val)
        return (ok and type(t) == "table") and t or {}
    end
    return {}
end

local function loadRarityCache()
    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT `component_id`, `is_prop`, `gender`, `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary` FROM `mclothes_rarity`')
    end)
    rarityCache = {}
    if not ok or not rows then
        print('[XNClothes] Warning: Failed to query mclothes_rarity table.')
        return
    end

    local count = 0
    for _, row in ipairs(rows) do
        local key = buildCacheKey(row.component_id, isPropToBool(row.is_prop), row.gender)
        rarityCache[key] = {}
        for _, rarity in ipairs(RARITY_LEVELS) do
            local drawables = decodeDrawables(row[rarity])
            for _, d in ipairs(drawables) do
                local num = tonumber(d)
                if num then
                    rarityCache[key][num] = rarity
                    count = count + 1
                end
            end
        end
    end
    print(('[XNClothes] Rarity cache loaded from SQL (%d items cached).'):format(count))
end

local function invalidateRarityCache()
    rarityCache = nil
end

local function ensureCacheLoaded()
    if rarityCache == nil then
        loadRarityCache()
    end
end

-- Load cache ngay khi resource start
CreateThread(function()
    Wait(500)  -- đợi MySQL sẵn sàng
    loadRarityCache()
end)

-- Get all rarity columns for a component+gender row (direct SQL, dùng cho write ops)
local function GetRarityRow(componentId, isProp, gender)
    local propVal = isPropToBool(isProp) and 1 or 0
    local result = MySQL.query.await(
        'SELECT `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary` FROM `mclothes_rarity` WHERE `component_id` = ? AND `is_prop` = ? AND `gender` = ?',
        {tonumber(componentId), propVal, gender}
    )
    return result and result[1] or nil
end

-- Get rarity từ cache (O(1), không tốn SQL)
local function GetRarityFromSQL(componentId, drawable, isProp, gender)
    ensureCacheLoaded()
    local key = buildCacheKey(componentId, isProp, gender)
    local row = rarityCache[key]
    if not row then return nil end
    return row[tonumber(drawable)]
end

-- Set rarity in SQL database (upsert row, update JSON arrays)
local function SetRarityToSQL(componentId, drawable, isProp, gender, rarity)
    local validRarities = {}
    for _, r in ipairs(RARITY_LEVELS) do validRarities[r] = true end
    if not validRarities[rarity] then
        return false, "Invalid rarity level"
    end

    local propVal = isPropToBool(isProp) and 1 or 0

    -- Read current row (or start empty)
    local row = GetRarityRow(componentId, isProp, gender) or {}
    local columns = {}
    for _, r in ipairs(RARITY_LEVELS) do
        columns[r] = decodeDrawables(row[r])
    end

    -- Remove drawable from ALL columns to prevent duplicates
    for _, r in ipairs(RARITY_LEVELS) do
        local filtered = {}
        for _, d in ipairs(columns[r]) do
            if tonumber(d) ~= tonumber(drawable) then
                table.insert(filtered, d)
            end
        end
        columns[r] = filtered
    end

    -- Insert into target rarity and sort
    table.insert(columns[rarity], tonumber(drawable))
    table.sort(columns[rarity])

    local result = MySQL.query.await([[
        INSERT INTO `mclothes_rarity` (`component_id`, `is_prop`, `gender`, `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `Common` = VALUES(`Common`), `Uncommon` = VALUES(`Uncommon`),
            `Rare` = VALUES(`Rare`), `Epic` = VALUES(`Epic`),
            `Legendary` = VALUES(`Legendary`), `updated_at` = CURRENT_TIMESTAMP
    ]], {
        tonumber(componentId), propVal, gender,
        #columns.Common     > 0 and json.encode(columns.Common)     or nil,
        #columns.Uncommon   > 0 and json.encode(columns.Uncommon)   or nil,
        #columns.Rare       > 0 and json.encode(columns.Rare)       or nil,
        #columns.Epic       > 0 and json.encode(columns.Epic)       or nil,
        #columns.Legendary  > 0 and json.encode(columns.Legendary)  or nil,
    })

    local ok = result and result.affectedRows > 0
    if ok then invalidateRarityCache() end
    return ok, "Rarity updated"
end

-- Remove rarity of a drawable from SQL
local function RemoveRarityFromSQL(componentId, drawable, isProp, gender)
    local propVal = isPropToBool(isProp) and 1 or 0
    local row = GetRarityRow(componentId, isProp, gender)
    if not row then return false, "Row not found" end

    local columns = {}
    local changed = false
    for _, rarity in ipairs(RARITY_LEVELS) do
        local filtered = {}
        for _, d in ipairs(decodeDrawables(row[rarity])) do
            if tonumber(d) == tonumber(drawable) then
                changed = true
            else
                table.insert(filtered, d)
            end
        end
        columns[rarity] = filtered
    end

    if not changed then return false, "Drawable not found in any rarity" end

    local result = MySQL.query.await([[
        UPDATE `mclothes_rarity`
        SET `Common` = ?, `Uncommon` = ?, `Rare` = ?, `Epic` = ?, `Legendary` = ?, `updated_at` = CURRENT_TIMESTAMP
        WHERE `component_id` = ? AND `is_prop` = ? AND `gender` = ?
    ]], {
        #columns.Common     > 0 and json.encode(columns.Common)     or nil,
        #columns.Uncommon   > 0 and json.encode(columns.Uncommon)   or nil,
        #columns.Rare       > 0 and json.encode(columns.Rare)       or nil,
        #columns.Epic       > 0 and json.encode(columns.Epic)       or nil,
        #columns.Legendary  > 0 and json.encode(columns.Legendary)  or nil,
        tonumber(componentId), propVal, gender
    })

    local ok = result and result.affectedRows > 0
    if ok then invalidateRarityCache() end
    return ok, "Rarity removed"
end

-- Get all drawables for a specific rarity (used for UI display)
local function GetDrawablesByRarity(componentId, isProp, gender, rarity)
    local row = GetRarityRow(componentId, isProp, gender)
    if not row then return {} end
    return decodeDrawables(row[rarity])
end

-- Get rarity by drawable (replacement for GetDoHiemByDrawable)
-- itemType can be either UI name ("torso") or item name ("cloth_torso")
function GetDoHiemByDrawable(sexs, itemType, drawable)
    if not drawable then return nil end
    local drawNum = tonumber(drawable)
    if not drawNum then return nil end

    -- Normalize: find UI name for componentMapping lookup
    -- If itemType is already a UI name (key in componentMapping), use it directly
    -- Otherwise, find UI name by matching itemname field
    local uiName = nil
    if componentMapping[itemType] then
        uiName = itemType
    else
        -- itemType is an item name (e.g. "cloth_torso"), find matching UI name
        for key, mapping in pairs(componentMapping) do
            if mapping.itemname == itemType then
                uiName = key
                break
            end
        end
    end

    -- 1. Ưu tiên lấy từ SQL cache (đã load từ mclothes_rarity)
    if uiName and componentMapping[uiName] then
        local componentId = componentMapping[uiName].component
        local isProp = componentMapping[uiName].prop
        local rarity = GetRarityFromSQL(componentId, drawNum, isProp, sexs)
        if rarity then
            return rarity
        end
    end

    -- 2. Fallback sang Config.Dohiem nếu chưa cấu hình trong SQL
    local itemName = (uiName and componentMapping[uiName] and componentMapping[uiName].itemname) or itemType
    local dohiemData = Config.Dohiem and Config.Dohiem[sexs]
    if not dohiemData then return nil end

    local itemConfig = dohiemData[itemName]
    if not itemConfig then return nil end

    for rarity, drawables in pairs(itemConfig) do
        if type(drawables) == "table" then
            for _, d in ipairs(drawables) do
                if tonumber(d) == drawNum then
                    return rarity
                end
            end
        end
    end

    return nil -- Không có độ hiếm
end

-- Migration function: Import data from Config.Dohiem to SQL
-- Migration function: Import data from Config.Dohiem to SQL (new schema)
-- Groups all drawables per rarity into JSON arrays in one row per component+gender
local function MigrateRarityConfigToSQL()
    local rows = 0
    local skipped = 0

    for gender, genderData in pairs(Config.Dohiem) do
        for itemName, rarityData in pairs(genderData) do
            local uiName = getUINameFromItemName(itemName)
            if uiName and componentMapping[uiName] then
                local componentId = componentMapping[uiName].component
                local isProp = componentMapping[uiName].prop

                -- Build columns for this component+gender
                local columns = {}
                for _, r in ipairs(RARITY_LEVELS) do columns[r] = {} end

                for rarity, drawables in pairs(rarityData) do
                    if rarity and rarity ~= '' and columns[rarity] then
                        for _, d in ipairs(drawables) do
                            table.insert(columns[rarity], tonumber(d))
                        end
                        table.sort(columns[rarity])
                    else
                        skipped = skipped + 1
                    end
                end

                local propVal = isPropToBool(isProp) and 1 or 0
                local result = MySQL.query.await([[
                    INSERT INTO `mclothes_rarity` (`component_id`, `is_prop`, `gender`, `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary`)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE
                        `Common` = VALUES(`Common`), `Uncommon` = VALUES(`Uncommon`),
                        `Rare` = VALUES(`Rare`), `Epic` = VALUES(`Epic`),
                        `Legendary` = VALUES(`Legendary`), `updated_at` = CURRENT_TIMESTAMP
                ]], {
                    tonumber(componentId), propVal, gender,
                    #columns.Common     > 0 and json.encode(columns.Common)     or nil,
                    #columns.Uncommon   > 0 and json.encode(columns.Uncommon)   or nil,
                    #columns.Rare       > 0 and json.encode(columns.Rare)       or nil,
                    #columns.Epic       > 0 and json.encode(columns.Epic)       or nil,
                    #columns.Legendary  > 0 and json.encode(columns.Legendary)  or nil,
                })

                if result and result.affectedRows > 0 then
                    rows = rows + 1
                end
            end
        end
    end

    return rows, skipped
end

-- Admin command to migrate config to SQL
RegisterCommand('migrateRarity', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, 'command.admin') then
        print('[XNClothes] Starting rarity migration from config to SQL...')
        local rows, skipped = MigrateRarityConfigToSQL()
        print(('[XNClothes] Migration complete: %d rows upserted, %d skipped (no rarity)'):format(rows, skipped))

        if source ~= 0 then
            TriggerClientEvent('QBCore:Notify', source, ('Migration: %d component rows, %d bỏ qua'):format(rows, skipped), 'success')
        end
    end
end, false)

-- =====================================================
-- END OF SQL-BASED RARITY SYSTEM
-- =====================================================

-- =====================================================
-- ADMIN COMMAND: Mở NUI xem toàn bộ quần áo, bỏ qua blacklist
-- =====================================================
RegisterCommand('adminclothes', function(source, args, rawCommand)
    if source == 0 then return end -- Không cho console dùng

    if not IsPlayerStaff(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này!', 'error')
        return
    end

    TriggerClientEvent('XNClothes:adminOpenClothes', source)
end, false)

-- Function để lấy cấp độ (level) của balo dựa trên drawable
function GetBagLevelByDrawable(sexs, drawable)
    if not Config.TuiDo or not Config.TuiDo[sexs] then 
        return nil 
    end

    for level, levelData in pairs(Config.TuiDo[sexs]) do
        if levelData.Drawable then
            for _, draw in ipairs(levelData.Drawable) do
                if tonumber(draw) == tonumber(drawable) then
                    return level
                end
            end
        end
    end

    return nil -- Không tìm thấy level
end

local function GetTradeShopItem(category, sex, index)
    if not Config.TradeShop or not Config.TradeShop.Items then
        return nil, nil, nil
    end
    index = tonumber(index)
    
    -- Format 1: Items[category][sex][index]
    if Config.TradeShop.Items[category] and Config.TradeShop.Items[category][sex] then
        local itemData = Config.TradeShop.Items[category][sex][index]
        if itemData then
            return itemData.rarity, itemData.item, itemData.count or 100
        end
    end

    -- Format 2: Items[sex][category][index]
    if Config.TradeShop.Items[sex] and Config.TradeShop.Items[sex][category] then
        local itemData = Config.TradeShop.Items[sex][category][index]
        if itemData then
            return itemData.rarity, itemData.item, itemData.count or 100
        end
    end

    -- Legacy fallback for gloves: Items[sex][index]
    if category == "gloves" and Config.TradeShop.Items[sex] and Config.TradeShop.Items[sex][index] then
        local itemData = Config.TradeShop.Items[sex][index]
        if itemData then
            return itemData.rarity, itemData.item, itemData.count or 100
        end
    end

    return nil, nil, nil
end

local function IsTradeShopCategoryAndDrawable(category, sex, index)
    if not Config.TradeShop then return false end
    index = tonumber(index)
    if not index then return false end

    -- 1. Kiểm tra danh sách AllowedDrawables
    if Config.TradeShop.AllowedDrawables then
        local list = nil
        if Config.TradeShop.AllowedDrawables[category] and Config.TradeShop.AllowedDrawables[category][sex] then
            list = Config.TradeShop.AllowedDrawables[category][sex]
        elseif Config.TradeShop.AllowedDrawables[sex] and Config.TradeShop.AllowedDrawables[sex][category] then
            list = Config.TradeShop.AllowedDrawables[sex][category]
        elseif category == "gloves" and Config.TradeShop.AllowedDrawables[sex] then
            list = Config.TradeShop.AllowedDrawables[sex]
        end

        if list and #list > 0 then
            for _, d in ipairs(list) do
                if tonumber(d) == index then
                    return true
                end
            end
        end
    end

    -- 2. Kiểm tra trong Items
    local _, fragmentItem = GetTradeShopItem(category, sex, index)
    if fragmentItem ~= nil then
        return true
    end

    return false
end

local function IsAllowedTradeShopDrawable(category, sex, index)
    if not IsTradeShopCategoryAndDrawable(category, sex, index) then
        return false
    end

    -- Phải được cấu hình đầy đủ trong Items
    local rarity, fragmentItem, reqCount = GetTradeShopItem(category, sex, index)
    return (fragmentItem ~= nil and reqCount ~= nil and reqCount > 0)
end

RegisterServerEvent('clothes:purchase')
AddEventHandler('clothes:purchase', function(items, sex)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    local money = xPlayer.Functions.GetMoney("cash")
    local totalPrice = 0

    local normalItems = {}
    local tattoItems = {}
    local requiredFragments = {}

    for _, item in pairs(items) do
        local isTradeItem = IsTradeShopCategoryAndDrawable(item.category, sex, item.index)
        local rarity, fragmentItem, reqCount = GetTradeShopItem(item.category, sex, item.index)

        if isTradeItem then
            if not fragmentItem or not reqCount or reqCount <= 0 then
                TriggerClientEvent('QBCore:Notify', source, "Vật phẩm Tattoo này chưa được cấu hình đổi thẻ!", "error")
                return
            end
            table.insert(tattoItems, { item = item, fragment = fragmentItem, count = reqCount })
            requiredFragments[fragmentItem] = (requiredFragments[fragmentItem] or 0) + reqCount
        else
            table.insert(normalItems, item)
            local configPrice = GetConfigPrice(item.category, item.index, sex, componentMapping[item.category].prop)
            local finalPrice = configPrice or item.price
            totalPrice = totalPrice + finalPrice
        end
    end

    -- Validate cash for normal items
    if money < totalPrice then
        TriggerClientEvent('QBCore:Notify', source, Config.Notification.notenoughtmoney, "error")
        return
    end

    -- Validate fragments for tattoo items
    for fragment, neededCount in pairs(requiredFragments) do
        local count = exports.ox_inventory:Search(source, 'count', fragment)
        if not count or count < neededCount then
            local label = "Mảnh ghép"
            if fragment == "manhtatto_b" then label = "Mảnh tatto Classic"
            elseif fragment == "manhtatto_a" then label = "Mảnh tatto Premium"
            elseif fragment == "manhtatto_s" then label = "Mảnh tatto SVIP" end
            TriggerClientEvent('QBCore:Notify', source, "Bạn không có đủ " .. neededCount .. " " .. label .. "!", "error")
            return
        end
    end

    -- Deduct payment
    if totalPrice > 0 then
        xPlayer.Functions.RemoveMoney("cash", totalPrice, "achat-vetements")
    end

    for fragment, neededCount in pairs(requiredFragments) do
        exports.ox_inventory:RemoveItem(source, fragment, neededCount)
    end

    local purchasedCount = 0

    for _, item in pairs(items) do
        if componentMapping[item.category] then
            local imagename

            if Config.NoImage then
                imagename = componentMapping[item.category].itemname
            else
                local propPrefix = componentMapping[item.category].prop and '_prop_' or '_'

                if Config.UrlInventory then
                    imagename = Config.Url .. "/" .. sex .. propPrefix .. componentMapping[item.category].component .. '_' .. item.index .. '.' .. Config.Extension
                else
                    imagename = sex .. propPrefix .. componentMapping[item.category].component .. '_' .. item.index
                end
            end
            
            if isClothingRestrictedByJob(GetJobName(GetPlayerSource(xPlayer)), componentMapping[item.category].component, item.index, sex, componentMapping[item.category].prop) then
                TriggerClientEvent('esx:showNotification', GetPlayerSource(xPlayer), Config.Notification.restrictedClothing)
                return
            end
            local _, fragmentItem = GetTradeShopItem(item.category, sex, item.index)

            local itemMetadata = { 
                type = componentMapping[item.category].component,
                DoHiem = GetDoHiemByDrawable(sex, componentMapping[item.category].itemname, item.index),
                drawable = item.index,
                id = componentMapping[item.category].component,
                sex = sex,  -- IMPORTANT: Store gender in metadata for validation
                description = Config.Decription .. (sex == "male" and "Nam" or "Nữ"),
                texture = item.texture,
                label = componentMapping[item.category].label .. ' ' .. item.index,
                imageurl = imagename
            }

            if fragmentItem or IsTradeShopCategoryAndDrawable(item.category, sex, item.index) then
                itemMetadata.serial = GenerateSerialTattoo()
            end

            AddItem(xPlayer.PlayerData.source, componentMapping[item.category].itemname, itemMetadata)
            purchasedCount = purchasedCount + 1
        end
    end

    if purchasedCount > 0 then
        -- Custom notify for fragments or cash
        local successMsg = "Đã đổi thành công!"
        if totalPrice > 0 then
            successMsg = successMsg .. " -" .. totalPrice .. "$"
        end
        TriggerClientEvent('QBCore:Notify', source, successMsg, "success")

        TriggerClientEvent('XNClothes:purchaseSuccess', source, {
            type = 'success',
            count = purchasedCount,
            totalPrice = totalPrice,
        })
    end
end)

-- =====================================================
-- QUY ĐỔI ĐỒ TATTOO THÀNH THẺ (50%)
-- =====================================================
QBCore.Functions.CreateCallback('clothes:getRefundableTattooItems', function(source, cb, gender)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return cb({}) end

    local inventory = exports.ox_inventory:GetInventory(src, true)
    if not inventory or not inventory.items then return cb({}) end

    local refundable = {}
    local refundRate = (Config.TradeShop and Config.TradeShop.RefundRate) or 0.5

    for slot, item in pairs(inventory.items) do
        if item and type(item) == 'table' and item.name then
            local category = nil
            for catName, map in pairs(componentMapping) do
                if map.itemname == item.name then
                    category = catName
                    break
                end
            end

            if category then
                local metadata = item.metadata or {}
                local drawable = tonumber(metadata.drawable or metadata.id or metadata.type)
                local itemSex = metadata.sex or gender or ((xPlayer.PlayerData.charinfo and xPlayer.PlayerData.charinfo.gender == 0) and "male" or "female")

                -- BẮT BUỘC drawable phải thuộc danh sách AllowedDrawables và được cấu hình trong Items
                if drawable and IsAllowedTradeShopDrawable(category, itemSex, drawable) then
                    local rarity, fragmentItem, reqCount = GetTradeShopItem(category, itemSex, drawable)

                    if fragmentItem and reqCount and reqCount > 0 then
                        local refundAmount = math.floor(reqCount * refundRate)
                        if refundAmount < 1 then refundAmount = 1 end

                        -- Quy đổi thành item được cấu hình trong Config.TradeShop.RefundItem
                        local returnItem = (Config.TradeShop and Config.TradeShop.RefundItem) or "manhtatto_s"
                        local returnLabel = (Config.TradeShopItemLabels and Config.TradeShopItemLabels[returnItem]) or "Thẻ tattoo"
                        local isWorn = (componentMapping[category].clothesSlotID and tonumber(item.slot) == componentMapping[category].clothesSlotID)
                        local catLabel = (componentMapping[category] and componentMapping[category].label) or category
                        local itemNameLabel = metadata.label or item.label or (catLabel .. " #" .. tostring(drawable))
                        local serial = tostring(metadata.serial or "")

                        local propPrefix = componentMapping[category].prop and '_prop_' or '_'
                        local imgUrl = metadata.imageurl
                        if not imgUrl then
                            if Config.UrlInventory then
                                imgUrl = Config.Url .. "/" .. itemSex .. propPrefix .. componentMapping[category].component .. '_' .. drawable .. '.' .. Config.Extension
                            else
                                imgUrl = itemSex .. propPrefix .. componentMapping[category].component .. '_' .. drawable
                            end
                        end

                        table.insert(refundable, {
                            slot = item.slot,
                            name = item.name,
                            label = itemNameLabel,
                            category = category,
                            categoryLabel = catLabel,
                            drawable = drawable,
                            texture = metadata.texture or 0,
                            serial = serial ~= "" and serial or "TATTOO-ITEM",
                            rarity = metadata.DoHiem or rarity or "Epic",
                            originalCost = reqCount,
                            refundAmount = refundAmount,
                            fragmentItem = returnItem,
                            refundLabel = returnLabel,
                            imageUrl = imgUrl,
                            isWorn = isWorn
                        })
                    end
                end
            end
        end
    end

    cb(refundable)
end)

RegisterServerEvent('clothes:refundTattooItem')
AddEventHandler('clothes:refundTattooItem', function(slot, category, drawable)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    slot = tonumber(slot)
    drawable = tonumber(drawable)
    if not slot or not category or not drawable then return end

    local categoryMapping = componentMapping[category]
    if not categoryMapping then return end

    local itemInSlot = exports.ox_inventory:GetSlot(src, slot)
    if not itemInSlot or itemInSlot.name ~= categoryMapping.itemname then
        TriggerClientEvent('QBCore:Notify', src, "Không tìm thấy vật phẩm hợp lệ trong ô đồ!", "error")
        return
    end

    local metadata = itemInSlot.metadata or {}
    local itemDrawable = tonumber(metadata.drawable or metadata.id or metadata.type)
    if itemDrawable ~= drawable then
        TriggerClientEvent('QBCore:Notify', src, "Dữ liệu vật phẩm không trùng khớp!", "error")
        return
    end

    local itemSex = metadata.sex or ((xPlayer.PlayerData.charinfo and xPlayer.PlayerData.charinfo.gender == 0) and "male" or "female")
    
    -- Kiểm tra nghiêm ngặt: Drawable bắt buộc phải nằm trong AllowedDrawables và Config.TradeShop.Items
    if not IsAllowedTradeShopDrawable(category, itemSex, drawable) then
        TriggerClientEvent('QBCore:Notify', src, "Vật phẩm này không thuộc danh sách đổi thẻ Tattoo!", "error")
        return
    end

    local rarity, fragmentItem, reqCount = GetTradeShopItem(category, itemSex, drawable)
    if not fragmentItem or not reqCount or reqCount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Vật phẩm này không thuộc danh sách đổi thẻ Tattoo!", "error")
        return
    end

    local refundRate = (Config.TradeShop and Config.TradeShop.RefundRate) or 0.5
    local refundAmount = math.floor(reqCount * refundRate)
    if refundAmount < 1 then refundAmount = 1 end

    -- Quy đổi thành item được cấu hình trong Config.TradeShop.RefundItem
    local returnItem = (Config.TradeShop and Config.TradeShop.RefundItem) or "manhtatto_s"
    local returnLabel = (Config.TradeShopItemLabels and Config.TradeShopItemLabels[returnItem]) or "Thẻ tattoo"

    -- Xóa vật phẩm khỏi ox_inventory
    local removed = exports.ox_inventory:RemoveItem(src, itemInSlot.name, 1, itemInSlot.metadata, slot)
    if not removed then
        TriggerClientEvent('QBCore:Notify', src, "Lỗi khi thu hồi vật phẩm!", "error")
        return
    end

    -- Cộng lại mảnh manhtatto_s vào túi đồ
    exports.ox_inventory:AddItem(src, returnItem, refundAmount)

    local itemLabel = metadata.label or itemInSlot.label or (categoryMapping.label .. " #" .. drawable)
    TriggerClientEvent('QBCore:Notify', src, string.format("Đã quy đổi %s nhận lại %d %s (50%%)!", itemLabel, refundAmount, returnLabel), "success")

    TriggerClientEvent('XNClothes:refundSuccess', src, {
        slot = slot,
        category = category,
        drawable = drawable,
        refundAmount = refundAmount,
        fragmentItem = returnItem,
        fragmentLabel = returnLabel,
        isWorn = (categoryMapping.clothesSlotID and slot == categoryMapping.clothesSlotID)
    })
end)

-- Event handler for texture change purchase
RegisterServerEvent('clothes:purchaseTextureChange')
AddEventHandler('clothes:purchaseTextureChange', function(category, index, newTexture, price, sex)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    
    -- Get clothing slot for this category
    local categoryMapping = componentMapping[category]
    if not categoryMapping then
        TriggerClientEvent('QBCore:Notify', source, "Lỗi: Không tìm thấy category mapping", "error")
        return
    end
    
    local slotID = categoryMapping.clothesSlotID
    local itemName = categoryMapping.itemname
    
    -- Check if player has the item in inventory
    local itemInSlot = exports.ox_inventory:GetSlot(xPlayer.PlayerData.source, slotID)
    
    -- Case 1: Player HAS item - this is a texture change
    if itemInSlot and itemInSlot.metadata and itemInSlot.metadata.drawable == index then
        -- Check if drawable matches (cà 2 thỉnh hướng đảm bảo khớp từ điều kiện if phía trên)
        -- Check money
        local money = xPlayer.Functions.GetMoney("cash")
        if money < price then
            TriggerClientEvent('QBCore:Notify', source, Config.Notification.notenoughtmoney, "error")
            return
        end

        -- Charge for texture change
        xPlayer.Functions.RemoveMoney("cash", price, "texture-change")
        
        -- Save old metadata and create new metadata with updated texture
        local oldMetadata = itemInSlot.metadata
        local newMetadata = {}
        for k, v in pairs(oldMetadata) do
            newMetadata[k] = v
        end
        newMetadata.texture = newTexture -- Update to new texture
        
        -- Remove old item, then add new item with updated texture (dùng SetTimeout thay Wait)
        exports.ox_inventory:RemoveItem(xPlayer.PlayerData.source, itemName, 1, oldMetadata, slotID)
        
        -- PERF FIX: Dùng Citizen.SetTimeout thay Wait(200) để không block server thread
        Citizen.SetTimeout(200, function()
            -- Kiểm tra player còn online
            if not GetPlayerPed(source) then return end
            exports.ox_inventory:AddItem(xPlayer.PlayerData.source, itemName, 1, newMetadata, slotID)
            
            TriggerClientEvent('QBCore:Notify', source, "Đã đổi màu thành công! -" .. price .. "$", "success")
            TriggerClientEvent('XNClothes:purchaseSuccess', source, {
                type = 'success',
                title = 'Đổi màu thành công',
                totalPrice = price,
            })
        end)
        
    -- Case 2: Player DOESN'T have item - this is buying the item (same drawable, buying for first time or re-buying)
    else
        -- BẢO MẬT: TUYỆT ĐỐI KHÔNG CHO PHÉP MUA MỚI ĐỒ TRADESHOP / TATTOO QUA ĐỔI MÀU BẰNG TIỀN MẶT
        if IsTradeShopCategoryAndDrawable(category, sex, index) then
            TriggerClientEvent('QBCore:Notify', source, "Vật phẩm này chỉ có thể đổi tại Cửa hàng Tattoo bằng thẻ!", "error")
            return
        end

        -- Check money
        local money = xPlayer.Functions.GetMoney("cash")
        if money < price then
            TriggerClientEvent('QBCore:Notify', source, Config.Notification.notenoughtmoney, "error")
            return
        end

        -- Charge for purchase
        xPlayer.Functions.RemoveMoney("cash", price, "clothes-purchase")
        
        -- Generate image name same as clothes:purchase
        local imagename
        if Config.NoImage then
            imagename = categoryMapping.itemname
        else
            local propPrefix = categoryMapping.prop and '_prop_' or '_'
            if Config.UrlInventory then
                imagename = Config.Url .. "/" .. sex .. propPrefix .. categoryMapping.component .. '_' .. index .. '.' .. Config.Extension
            else
                imagename = sex .. propPrefix .. categoryMapping.component .. '_' .. index
            end
        end
        
        -- Create metadata for new item (same structure as clothes:purchase)
        local metadata = {
            type = categoryMapping.component,
            DoHiem = GetDoHiemByDrawable(sex, categoryMapping.itemname, index),
            drawable = index,
            id = categoryMapping.component,
            description = Config.Decription .. (sex == "female" and "nữ" or "nam"),
            texture = newTexture,
            label = categoryMapping.label .. ' ' .. index,
            imageurl = imagename,
            isnew = 'yes'
        }
        
        -- Try to add item at slot
        local success = exports.ox_inventory:AddItem(xPlayer.PlayerData.source, itemName, 1, metadata, slotID)
        
        if success then
            -- Notify success
            TriggerClientEvent('QBCore:Notify', source, "Đã mua thành công! -" .. price .. "$", "success")
            TriggerClientEvent('XNClothes:purchaseSuccess', source, {
                type = 'success',
                count = 1,
                totalPrice = price,
            })
        else
            -- If add failed, refund money
            xPlayer.Functions.AddMoney("cash", price, "clothes-purchase-failed")
            TriggerClientEvent('QBCore:Notify', source, "Không thể thêm item vào inventory!", "error")
        end
    end
    
    -- Refresh clothes
    TriggerClientEvent('RefreshArmsAndTShirt', xPlayer.PlayerData.source)
end)

-- Event handler to update texture on owned clothing item (free - just updates metadata)
RegisterServerEvent('XNClothes:updateClothingTexture')
AddEventHandler('XNClothes:updateClothingTexture', function(slotID, newTexture)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    
    -- Get item from slot
    local itemInSlot = exports.ox_inventory:GetSlot(xPlayer.PlayerData.source, slotID)
    
    if not itemInSlot or not itemInSlot.metadata then
        return
    end
    
    local itemName = itemInSlot.name
    local oldMetadata = itemInSlot.metadata
    
    -- Create new metadata with updated texture
    local newMetadata = {}
    for k, v in pairs(oldMetadata) do
        newMetadata[k] = v
    end
    newMetadata.texture = newTexture
    
    -- PERF FIX: Dùng Citizen.SetTimeout thay Wait(100) để không block server thread
    exports.ox_inventory:RemoveItem(xPlayer.PlayerData.source, itemName, 1, oldMetadata, slotID)
    Citizen.SetTimeout(100, function()
        if not GetPlayerPed(source) then return end
        exports.ox_inventory:AddItem(xPlayer.PlayerData.source, itemName, 1, newMetadata, slotID)
    end)
end)

-- Confirm texture change with payment
RegisterServerEvent('XNClothes:confirmTextureChange')
AddEventHandler('XNClothes:confirmTextureChange', function(slotID, newTexture, price)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return end
    
    -- Check money
    local money = xPlayer.Functions.GetMoney("cash")
    if money < price then
        TriggerClientEvent('QBCore:Notify', source, Config.Notification.notenoughtmoney, "error")
        return
    end
    
    -- Get item from slot
    local itemInSlot = exports.ox_inventory:GetSlot(xPlayer.PlayerData.source, slotID)
    
    if not itemInSlot or not itemInSlot.metadata then
        TriggerClientEvent('QBCore:Notify', source, "Không tìm thấy item!", "error")
        return
    end
    
    -- Charge money
    xPlayer.Functions.RemoveMoney("cash", price, "texture-change")
    
    -- Update metadata directly using SetMetadata (no remove/add)
    local newMetadata = {}
    for k, v in pairs(itemInSlot.metadata) do
        newMetadata[k] = v
    end
    newMetadata.texture = newTexture
    
    exports.ox_inventory:SetMetadata(xPlayer.PlayerData.source, slotID, newMetadata)
    
    TriggerClientEvent('QBCore:Notify', source, "Đã đổi màu thành công! -" .. price .. "$", "success")
    
    -- Send success event to client - no need to call setPedComponent/setPedProp here
    -- because clothes will be reloaded when NUI closes
    TriggerClientEvent('XNClothes:textureChangeSuccess', source, slotID, newTexture)
end)

-- Function để lấy giá từ config theo giới tính
function GetConfigPrice(category, index, sex, isProp)
    if not Config.PriceClothes[sex] then
        return nil
    end

    local categoryComponent = componentMapping[category]
    if not categoryComponent then
        return nil
    end

    local propBool = isPropToBool(isProp)
    for _, priceConfig in pairs(Config.PriceClothes[sex]) do
        if priceConfig.componentNumber == categoryComponent.component and 
           isPropToBool(priceConfig.prop) == propBool then
            for _, configIndex in pairs(priceConfig.index) do
                if configIndex == index then
                    return priceConfig.price
                end
            end
        end
    end

    return nil
end

QBCore.Functions.CreateCallback('clothes:getOutfits', function(source, cb, sex)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local identifier = xPlayer.PlayerData.citizenid

    if sex == "male" then
        sex = 1
    else
        sex = 0
    end

    MySQL.Async.fetchAll('SELECT * FROM mclothes WHERE identifier = ? AND male = ?', {identifier, sex}, function(result)
        cb(result)
    end)
end)

RegisterServerEvent('clothes:deleteOutfit')
AddEventHandler('clothes:deleteOutfit', function(outfitId)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local identifier = xPlayer.PlayerData.citizenid

    MySQL.Async.execute('DELETE FROM mclothes WHERE id = ? AND identifier = ?', {outfitId, identifier})

    PerformHttpRequest(
        Config.DeleteScreenshotUrl .. '/' .. Config.ServerName .. '/outfit_' .. outfitId .. '.jpg',
        function(err, text, headers) end,
        'DELETE'
    )

    TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, Config.Notification.outfitdeleted, "success")
    TriggerClientEvent('clothes:getOutfits', xPlayer.PlayerData.source)
end)

RegisterServerEvent('clothes:saveOutfit')
AddEventHandler('clothes:saveOutfit', function(outfitName, sex)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local identifier = xPlayer.PlayerData.citizenid
    local name = outfitName
    local price = Config.SaveOutfitPrice

    if #outfitName < 3 then
        TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, Config.Notification.outfitnamelength, "error")
        return
    end

    local clothes = GetPlayerClothes(xPlayer.PlayerData.source)

    if not next(clothes) then
        TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, "Vous devez avoir des vêtements équipés pour sauvegarder une tenue", "error")
        return
    end

    if xPlayer.Functions.GetMoney("cash") < price then
        TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, Config.Notification.notenoughtmoney, "error")
        return
    end

    -- PERF FIX: Đổi MySQL.Sync (blocking) → MySQL.Async để không block server thread
    MySQL.Async.fetchScalar('SELECT id FROM mclothes WHERE identifier = ? AND name = ?', {identifier, name}, function(existingOutfit)
        if existingOutfit then
            TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, Config.Notification.outfitnameexists, "error")
            return
        end

        xPlayer.Functions.RemoveMoney("cash", price, "achat-tenue")

        local sexNum = (sex == "male") and 1 or 0

        MySQL.Async.execute('INSERT INTO mclothes (identifier, clothes, name, male) VALUES (?, ?, ?, ?)', {
            identifier,
            json.encode(clothes),
            name,
            sexNum
        }, function()
            if Config.UseScreenshot then
                MySQL.Async.fetchAll('SELECT id FROM mclothes WHERE identifier = ? AND name = ?', {identifier, name},
                function(result)
                    if result and result[1] then
                        TriggerClientEvent('clothes:uploadScreenshot', xPlayer.PlayerData.source, result[1].id)
                    end
                end)
            end

            TriggerClientEvent('QBCore:Notify', xPlayer.PlayerData.source, Config.Notification.outfitsaved, "success")
            TriggerClientEvent('clothes:getOutfits', xPlayer.PlayerData.source)
        end)
    end)
end)




QBCore.Functions.CreateCallback('clothes:getOutfitById', function(source, cb, outfitId, sex)
    local player = QBCore.Functions.GetPlayer(source)
    local identifier = player.PlayerData.citizenid
    local playermoney = player.Functions.GetMoney('cash')

    if playermoney < Config.TakeOutfitPrice then
        TriggerClientEvent('QBCore:Notify', source, Config.Notification.notenoughtmoney, "error")
        cb(nil)
        return
    else
        player.Functions.RemoveMoney('cash', Config.TakeOutfitPrice)
    end

    MySQL.Async.fetchAll('SELECT * FROM mclothes WHERE id = ? AND identifier = ? LIMIT 1', {outfitId, identifier}, function(result)
        if result and #result > 0 then
            local metadata = json.decode(result[1].clothes)
            metadata.sex = sex
            metadata.label = result[1].name
            local item = exports.ox_inventory:GetSlot(player.PlayerData.source, componentMapping.clothes.clothesSlotID)

            if item then
                exports.ox_inventory:RemoveItem(player.PlayerData.source, item.name, 1, item.metadata, componentMapping.clothes.clothesSlotID)
                exports.ox_inventory:AddItem(player.PlayerData.source, item.name, 1, item.metadata)

                for _, component in pairs(componentMapping) do
                    if component.clothesSlotID then
                        local itemInSlot = exports.ox_inventory:GetSlot(player.PlayerData.source, component.clothesSlotID)
                        if itemInSlot then
                            exports.ox_inventory:RemoveItem(player.PlayerData.source, itemInSlot.name, 1, itemInSlot.metadata, component.clothesSlotID)
                        end
                    end
                end
            end

            exports.ox_inventory:AddItem(player.PlayerData.source, 'clothes', 1, metadata, componentMapping.clothes.clothesSlotID)
            Wait(100)
            ClothesMovedToGood(player.PlayerData.source)
            -- PERF FIX: Gọi cb() khi thành công để tránh QBCore callback timeout
            cb(true)
        else
            cb(nil)
        end
    end)
end)

RegisterServerEvent('clothes:copyOutfit')
AddEventHandler('clothes:copyOutfit', function(outfitId, sex)
    local player = QBCore.Functions.GetPlayer(source)
    local identifier = player.PlayerData.citizenid
    local price = Config.CopyOutfitPrice

    MySQL.Async.fetchAll('SELECT * FROM mclothes WHERE id = ?', {outfitId}, function(result)
        if result and #result > 0 then
            local outfitData = result[1].clothes
            local name = result[1].name
            local sexs = result[1].male

            sexs = (sexs == 1) and "male" or "female"

            if sex ~= sexs then
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.othersex, "error")
                return
            end

            if player.Functions.GetMoney('cash') < price then
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.notenoughtmoney, "error")
                return
            else
                player.Functions.RemoveMoney('cash', price)
            end

            MySQL.Async.execute('INSERT INTO mclothes (identifier, clothes, name) VALUES (?, ?, ?)', {identifier, outfitData, name})
            TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.outfitsaved, "success")
            TriggerClientEvent('clothes:getOutfits', player.PlayerData.source)
        else
            TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.outfitnotfound, "error")
        end
    end)
end)

RegisterServerEvent('clothes:exportOutfit')
AddEventHandler('clothes:exportOutfit', function(outfitId, sex)
    local player = QBCore.Functions.GetPlayer(source)
    local identifier = player.PlayerData.citizenid

    MySQL.Async.fetchAll('SELECT clothes, name, male FROM mclothes WHERE id = ?', {outfitId}, function(result)
        if result and #result > 0 then
            local outfitData = result[1].clothes
            local name = result[1].name
            local sexs = result[1].male == 1 and "male" or "female"

            if sex ~= sexs then
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.othersex, "error")
                return
            end

            local success, response = exports.ox_inventory:AddItem(player.PlayerData.source, 'clothes', 1, {
                outfit = outfitData,
                name = name,
                description = Config.Description .. (sex == "male" and "Homme" or "Femme"),
                label = name,
                sex = sex,
                isnew = 'yes'
            })

            if success then
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.outfitexported, "success")
                MySQL.Async.execute('DELETE FROM mclothes WHERE id = ?', {outfitId})
            else
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.outfitexporterror, "error")
            end
        else
            TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.outfitnotfound, "error")
        end
    end)
end)


function GetSlotId(componentId, isProp)
    local propBool = isPropToBool(isProp)
    for key, value in pairs(componentMapping) do
        if value.component == componentId and isPropToBool(value.prop) == propBool then
            return value.clothesSlotID
        end
    end
    return nil
end

function getItemNameByComponentId(componentId, isProp)
    local propBool = isPropToBool(isProp)
    for key, value in pairs(componentMapping) do
        if value.component == componentId and isPropToBool(value.prop) == propBool then
            return value.itemname
        end
    end
    return nil
end


function GiveClothes(id, outfit, sexs)
    local player = QBCore.Functions.GetPlayer(id)
    if not player then
        return
    end

    if not outfit then
        return
    end

    if Config.UseCustomOXInventory == false then
        return
    end

    if type(outfit) == "string" then
        outfit = json.decode(outfit)
    end

    local ClothesItem = exports.ox_inventory:GetSlot(player.PlayerData.source, 53)
    if ClothesItem then
        exports.ox_inventory:RemoveItem(player.PlayerData.source, ClothesItem.name, 1, ClothesItem.metadata, 53)
        exports.ox_inventory:AddItem(player.PlayerData.source, ClothesItem.name, 1, ClothesItem.metadata)
    end

    for _, slotId in pairs(clothesSlotID) do
        local existingItem = exports.ox_inventory:GetSlot(player.PlayerData.source, slotId)
        if existingItem then
            local deleteSuccess = exports.ox_inventory:RemoveItem(player.PlayerData.source, existingItem.name, 1)
            if not deleteSuccess then
                print("Impossible de supprimer l'item existant :", existingItem.name)
            end
        end
    end

    Wait(200)

    if outfit.components then
        for i, component in ipairs(outfit.components) do
            local componentId = component.component_id
            local componentDrawable = component.drawable
            local componentTexture = component.texture

            local slotId = GetSlotId(componentId, false)
            local itemName = getItemNameByComponentId(componentId, false)

            if not itemName then
                goto continue
            end

            local imagenamess
            if sexs == "male" then
                if Config.UrlInventory then
                    imagenamess = Config.Url .. "/male_" .. componentId .. "_" .. componentDrawable .. "." .. Config.Extension
                else
                    imagenamess = "male_" .. componentId .. "_" .. componentDrawable
                end
            else
                if Config.UrlInventory then
                    imagenamess = Config.Url .. "/female_" .. componentId .. "_" .. componentDrawable .. "." .. Config.Extension
                else
                    imagenamess = "female_" .. componentId .. "_" .. componentDrawable
                end
            end

            if component.drawable == 0 or component.drawable == -1 then
                goto continue
            end

            AddItem(player.PlayerData.source, itemName, {
                type = "component",
                DoHiem = GetDoHiemByDrawable(sexs, itemName, componentDrawable),
                drawable = componentDrawable,
                id = componentId,
                texture = componentTexture,
                label = itemName .. " " .. componentId .. "-" .. componentDrawable .. "-" .. math.random(1, 1000),
                description = Config.Decription .. (sexs == "male" and "Homme" or "Femme"),
                imageurl = imagenamess
            }, slotId)

            ::continue::
        end
    end

    Wait(200)
    if outfit.props then
        for i, prop in ipairs(outfit.props) do
            local propId = prop.prop_id
            local propDrawable = prop.drawable
            local propTexture = prop.texture

            local slotId = GetSlotId(propId, true)
            local itemName = getItemNameByComponentId(propId, true)

            if not itemName then
                goto continueProps
            end

            local imagenamess
            if sexs == "male" then
                imagenamess = Config.Url .. "/male_prop_" .. propId .. "_" .. propDrawable .. "." .. Config.Extension
            else
                imagenamess = Config.Url .. "/female_prop_" .. propId .. "_" .. propDrawable .. "." .. Config.Extension
            end

            if prop.drawable == -1 then
                goto continueProps
            end

            AddItem(xPlayer, itemName, { 
                type = "prop",
                DoHiem = GetDoHiemByDrawable(sexs, itemName, propDrawable),
                drawable = propDrawable,
                texture = propTexture,
                id = propId,
                label = itemName .. " " .. propId .. "-" .. propDrawable .. "-" .. math.random(1, 1000),
                description = Config.Decription .. (sexs == "male" and "Homme" or "Femme"),
                imageurl = imagenamess
            }, slotId)

            ::continueProps::
        end
    end

    GetPlayerClothesAndStock(player.PlayerData.source)
    TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.outfitequipped, "success")
end


RegisterServerEvent('clothes:setPrice')
AddEventHandler('clothes:setPrice', function(index, component, price, sex, prop)
    if not IsPlayerStaff(source) then
        DropPlayer(source, 'Vous n\'avez pas les permissions pour modifier les prix')
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM mclothes_price WHERE componentNumber = ? AND prop = ? AND sex = ?', {
        component,
        prop,
        sex
    }, function(result)
        if result and #result > 0 then
            for _, row in ipairs(result) do
                local existingIndexes = json.decode(row.clothes_index) or {}
                if table.contains(existingIndexes, index) then
                    local newIndexes = {}
                    for _, existingIndex in ipairs(existingIndexes) do
                        if existingIndex ~= index then
                            table.insert(newIndexes, existingIndex)
                        end
                    end

                    if #newIndexes > 0 then
                        MySQL.Async.execute('UPDATE mclothes_price SET clothes_index = ? WHERE id = ?', {
                            json.encode(newIndexes),
                            row.id
                        })
                    else
                        MySQL.Async.execute('DELETE FROM mclothes_price WHERE id = ?', {row.id})
                    end
                end
            end

            local found = false
            for _, row in ipairs(result) do
                if row.price == price then
                    local existingIndexes = json.decode(row.clothes_index) or {}
                    if not table.contains(existingIndexes, index) then
                        table.insert(existingIndexes, index)
                        MySQL.Async.execute('UPDATE mclothes_price SET clothes_index = ? WHERE id = ?', {
                            json.encode(existingIndexes),
                            row.id
                        })
                        found = true
                        break
                    end
                end
            end

            if not found then
                local indexList = {index}
                MySQL.Async.execute('INSERT INTO mclothes_price (componentNumber, prop, price, clothes_index, sex) VALUES (?, ?, ?, ?, ?)', {
                    component,
                    prop,
                    price,
                    json.encode(indexList),
                    sex
                })
            end
        else
            local indexList = {index}
            MySQL.Async.execute('INSERT INTO mclothes_price (componentNumber, prop, price, clothes_index, sex) VALUES (?, ?, ?, ?, ?)', {
                component,
                prop,
                price,
                json.encode(indexList),
                sex
            })
        end
    end)

    Wait(100)
    

    TriggerClientEvent('QBCore:Notify', player.PlayerData.source, Config.Notification.priceupdated, "success")
    TriggerClientEvent('clothes:getPrice', -1)
end)

-- =====================================================
-- SET RARITY EVENT - Admin set độ hiếm cho clothing
-- =====================================================
RegisterServerEvent('clothes:setRarity')
AddEventHandler('clothes:setRarity', function(drawable, componentId, rarity, gender, isProp)
    local src = source
    if not IsPlayerStaff(src) then
        DropPlayer(src, 'Không có quyền thay đổi độ hiếm')
        return
    end

    -- Set rarity to SQL
    local success, msg = SetRarityToSQL(componentId, drawable, isProp, gender, rarity)
    
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Đã cập nhật độ hiếm: ' .. rarity, "success")
        
        -- Refresh rarity data for all clients
        TriggerClientEvent('clothes:refreshRarity', -1)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Lỗi: ' .. msg, "error")
    end
end)

-- Event to remove rarity (set item to have no rarity)
RegisterServerEvent('clothes:removeRarity')
AddEventHandler('clothes:removeRarity', function(drawable, componentId, gender, isProp)
    local src = source
    if not IsPlayerStaff(src) then
        DropPlayer(src, 'Không có quyền xóa độ hiếm')
        return
    end

    -- Remove rarity from SQL
    local success, msg = RemoveRarityFromSQL(componentId, drawable, isProp, gender)
    
    if success then
        TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 'Đã xóa độ hiếm (item không có độ hiếm)', "success")
        
        -- Refresh rarity data for all clients
        TriggerClientEvent('clothes:refreshRarity', -1)
    else
        TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 'Item này chưa có độ hiếm', "info")
    end
end)

-- Event to get rarity data for UI
RegisterServerEvent('clothes:getRarityData')
AddEventHandler('clothes:getRarityData', function()
    local src = source
    -- Send rarity data structure (empty for SQL-based system)
    -- UI will request individual item rarity as needed
    TriggerClientEvent('clothes:receiveRarityData', src, {})
end)


function table.contains(table, element)
    if not table then return false end
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

QBCore.Functions.CreateCallback('clothes:getAllPriceClothes', function(source, cb)
    MySQL.Async.fetchAll('SELECT * FROM mclothes_price', {}, function(result)
        cb(result)
    end)
end)


QBCore.Functions.CreateCallback('clothes:isstaff', function(source, cb)
    local isStaff = IsPlayerStaff(source)
    cb(isStaff)
end)

QBCore.Functions.CreateCallback('clothes:getInventoryForOutfit', function(source, cb)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return cb(nil) end

    local inventory = exports.ox_inventory:GetInventory(source, true)
    if not inventory then return cb(nil) end

    cb(inventory)
end)

-- Callback to get UI-compatible rarity config from SQL
-- PERF FIX: Dùng rarityCache thay vì query SQL (75 queries → 0 query, O(1))
QBCore.Functions.CreateCallback('clothes:getUICompatibleConfig', function(source, cb, gender)
    -- Đảm bảo cache đã được load
    ensureCacheLoaded()

    local uiConfig = {
        male = {},
        female = {}
    }

    -- Duyệt componentMapping và tra cứu trực tiếp từ rarityCache (không tốn SQL)
    for uiName, mapping in pairs(componentMapping) do
        local componentId = mapping.component
        local isProp = mapping.prop

        -- Bỏ qua các entry đặc biệt không có component (ví dụ: 'clothes' bundle slot)
        if componentId == nil then
            goto continue_cache
        end

        local key = buildCacheKey(componentId, isProp, gender)
        local cacheRow = rarityCache[key]
        if cacheRow then
            -- Gom drawable theo rarity từ cache
            local categoryRarities = {}
            for drawable, rarity in pairs(cacheRow) do
                if not categoryRarities[rarity] then
                    categoryRarities[rarity] = {}
                end
                table.insert(categoryRarities[rarity], drawable)
            end

            -- Sắp xếp từng mảng drawable để nhất quán
            for _, drawables in pairs(categoryRarities) do
                table.sort(drawables)
            end

            if next(categoryRarities) then
                uiConfig[gender][uiName] = categoryRarities
            end
        end

        ::continue_cache::
    end

    cb(uiConfig)
end)


function AddItem(xPlayer, itemName, itemData, slotId)
    -- Only set sex from PlayerSex if not already provided in itemData
    -- This ensures sex parameter from purchase/gift events takes priority
    if not itemData.sex and PlayerSex[xPlayer] then 
        itemData.sex = PlayerSex[xPlayer]
    end

    -- Đánh dấu item mới mua/được tặng (bắt buộc có để mặc)
    itemData.isnew = 'yes'
    
    local success = false
    
    if Config.NoImage then
        if itemData.imageurl then
            itemData.imageurl = nil
        end
        if slotId then
            success = exports.ox_inventory:AddItem(xPlayer, itemName, 1, itemData, slotId)
        else
            success = exports.ox_inventory:AddItem(xPlayer, itemName, 1, itemData)
        end
    else
        if slotId then
            success = exports.ox_inventory:AddItem(xPlayer, itemName, 1, itemData, slotId)
        else
            success = exports.ox_inventory:AddItem(xPlayer, itemName, 1, itemData)
        end
    end
    
    -- Nếu không thể thêm vào inventory và có bật personal storage
    if not success and Config.Durability and Config.Durability.UsePersonalStorage then
        local player = QBCore.Functions.GetPlayer(xPlayer)
        if player and player.PlayerData then
            local citizenid = player.PlayerData.citizenid
            
            -- Thử gửi về kho bưu cục
            local storageSuccess = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, itemName, 1, itemData)
            
            if storageSuccess then
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 
                    string.format("Inventory đầy! %s đã được gửi về kho bưu cục.", 
                    itemData.label or itemName), 'info')
                return true -- Trả về success vì đã gửi được về kho
            else
                TriggerClientEvent('QBCore:Notify', player.PlayerData.source, 
                    "Không thể mua quần áo: inventory và kho bưu cục đều đầy!", 'error')
                return false
            end
        end
    end
    
    return success
end

RegisterServerEvent('clothes:createBag', function(item, count, metadata, player, itemslot)
    local source = source
    local token = math.random(1, 1000000)
    local itemName = item
    local drawable = metadata.drawable

    for _, data in pairs(Config.DataBag) do
        if data.index == drawable then
            slot = data.slot
            weight = data.weight
        end
    end

    metadata.token = token
    exports.ox_inventory:SetMetadata(source, itemslot, metadata)
    exports.ox_inventory:RegisterStash("bag_" .. token, "bag_" .. token, slot, weight)
    Wait(100)
    exports.ox_inventory:forceOpenInventory(source, 'stash', "bag_" .. token)
end)

RegisterServerEvent('clothes:createbag', function(token, drawable)
    local source = source
    local token = token
    

    for _, data in pairs(Config.DataBag) do
        if data.index == drawable then
            slot = data.slot
            weight = data.weight
        end
    end

    exports.ox_inventory:SetMetadata(source, 53, {token = token})
    exports.ox_inventory:RegisterStash("bag_" .. token, "bag_" .. token, slot, weight)
    exports.ox_inventory:forceOpenInventory(source, 'stash', "bag_" .. token)
end)

-- Function để give quần áo cho player (có thể sử dụng từ exports)
-- sex (optional): 'male' hoặc 'female' — nếu không truyền sẽ dùng PlayerSex[targetId]
function GiveClothingItem(targetId, componentType, drawable, texture, giveSource, sex)
    texture = texture or 0
    giveSource = giveSource or 0
    
    -- Kiểm tra player ID hợp lệ
    if not targetId or not GetPlayerPed(targetId) then
        local errorMsg = "Invalid player ID: " .. tostring(targetId)
        if giveSource == 0 then
            print(errorMsg)
        else
            TriggerClientEvent('QBCore:Notify', giveSource, 'ID người chơi không hợp lệ: ' .. tostring(targetId), 'error')
        end
        return false, errorMsg
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        local errorMsg = "Player not found: " .. targetId
        if giveSource == 0 then
            print(errorMsg)
        else
            TriggerClientEvent('QBCore:Notify', giveSource, 'Không tìm thấy người chơi: ' .. targetId, 'error')
        end
        return false, errorMsg
    end

    -- Kiểm tra component type hợp lệ
    if not componentMapping[componentType] or componentType == "clothes" then
        local errorMsg = "Invalid component type: " .. componentType
        if giveSource == 0 then
            print(errorMsg)
            print("Available components:")
            for key, _ in pairs(componentMapping) do
                if key ~= "clothes" then
                    print("  - " .. key)
                end
            end
        else
            TriggerClientEvent('QBCore:Notify', giveSource, 'Loại component không hợp lệ: ' .. componentType, 'error')
        end
        return false, errorMsg
    end

    -- Kiểm tra drawable hợp lệ
    if not drawable or drawable < 0 then
        local errorMsg = "Invalid drawable value: " .. tostring(drawable)
        if giveSource == 0 then
            print(errorMsg)
        else
            TriggerClientEvent('QBCore:Notify', giveSource, 'Giá trị drawable không hợp lệ: ' .. tostring(drawable), 'error')
        end
        return false, errorMsg
    end

    local component = componentMapping[componentType]
    local playerSex = (sex == 'female' or sex == 'male') and sex or PlayerSex[targetId] or "male"

    -- Xác định 3 ký tự giữa cho serial (middleText)
    local middleText = 'HT' .. GenerateText(1)  -- Mặc định: HT + 1 chữ random (ví dụ: HTX)
    if giveSource ~= 0 then
        -- Admin give - A + 2 số cuối citizenid (ví dụ: A45)
        local adminPlayer = QBCore.Functions.GetPlayer(giveSource)
        if adminPlayer and adminPlayer.PlayerData and adminPlayer.PlayerData.citizenid then
            local citizenid = adminPlayer.PlayerData.citizenid
            local lastTwo = string.sub(citizenid, -2)  -- 2 số cuối
            middleText = 'A' .. lastTwo
        end
    end

    -- Tạo imagename
    local imagename
    if Config.NoImage then
        imagename = nil
    else
        local propPrefix = component.prop and '_prop_' or '_'
        if Config.UrlInventory then
            imagename = Config.Url .. "/" .. playerSex .. propPrefix .. component.component .. '_' .. drawable .. '.' .. Config.Extension
        else
            imagename = playerSex .. propPrefix .. component.component .. '_' .. drawable
        end
    end

    -- Tạo metadata cho item
    local doHiem = GetDoHiemByDrawable(playerSex, component.itemname, drawable)
    local itemData = {
        type = component.prop and "prop" or "component",
        DoHiem = doHiem,
        Capdo = GetCapdoByDoHiem(doHiem),  -- Cấp độ dựa trên độ hiếm
        drawable = drawable,
        id = component.component,
        description = Config.Decription .. (playerSex == "male" and "Nam" or "Nữ"),
        texture = texture,
        label = component.label .. ' ' .. drawable,
        sex = playerSex,
        camera = component.camera,
        serial = GenerateSerial(middleText),  -- Tạo serial: AD + ngày + middleText + giờ
        fromGacha = true,  -- Đánh dấu item từ gacha/admin
        gachaTimestamp = os.time()  -- Thời điểm tạo item
    }

    if imagename then
        itemData.imageurl = imagename
    end

    -- Thêm item vào inventory
    local success = AddItem(targetPlayer.PlayerData.source, component.itemname, itemData)
    
    if success then
        local message = string.format("Đã give %s (drawable: %d, texture: %d) cho %s (ID: %d)", 
            component.label, drawable, texture, targetPlayer.PlayerData.charinfo.firstname, targetId)
        
        if giveSource == 0 then
            print(message)
        else
            TriggerClientEvent('QBCore:Notify', giveSource, message, 'success')
        end
        
        TriggerClientEvent('QBCore:Notify', targetId, 
            string.format("Bạn đã nhận được %s (drawable: %d)", component.label, drawable), 'success')
        
        return true, message
    else
        local errorMsg = "Không thể thêm item vào inventory"
        if giveSource == 0 then
            print(errorMsg)
        else
            TriggerClientEvent('QBCore:Notify', giveSource, errorMsg, 'error')
        end
        return false, errorMsg
    end
end

-- Export function để các resource khác có thể sử dụng
exports('GiveClothingItem', GiveClothingItem)

-- Export với giới tính chỉ định (dành cho resource khác muốn tặng quần áo theo sex cụ thể)
-- Cú pháp: exports['XNClothes']:GiveClothingItemBySex(targetId, componentType, drawable, texture, sex, giveSource)
-- Ví dụ: exports['XNClothes']:GiveClothingItemBySex(playerId, 'shirt', 10, 0, 'female')
local function GiveClothingItemBySex(targetId, componentType, drawable, texture, sex, giveSource)
    return GiveClothingItem(targetId, componentType, drawable, texture, giveSource, sex)
end

exports('GiveClothingItemBySex', GiveClothingItemBySex)

local function isSelectableClothingComponent(componentKey)
    if not componentKey or componentKey == '' then return false end
    local mapping = componentMapping[componentKey]
    return mapping and mapping.component ~= nil and componentKey ~= 'clothes' and componentKey ~= 'current_outfit'
end

local function GetComponentList()
    local list = {}
    for key, mapping in pairs(componentMapping) do
        if isSelectableClothingComponent(key) then
            list[#list + 1] = {
                key = key,
                label = mapping.label or key,
                itemname = mapping.itemname,
            }
        end
    end
    table.sort(list, function(a, b)
        return (a.label or a.key) < (b.label or b.key)
    end)
    return list
end

exports('GetComponentList', GetComponentList)
exports('IsValidClothingComponent', isSelectableClothingComponent)

-- Command để give quần áo cho player (sử dụng ox_lib command)
lib.addCommand('giveclothing', {
    help = 'Give clothing item to a player',
    params = {
        { name = 'target', type = 'playerId', help = 'Người chơi nhận được vật phẩm' },
        { name = 'component', type = 'string', help = 'Loại thành phần (hat, mask, shirt, pants, etc.)' },
        { name = 'drawable', type = 'number', help = 'Drawable ID' },
        { name = 'texture', type = 'number', help = 'Texture ID', optional = true },
        { name = 'sex', type = 'string', help = 'male hoặc female (bỏ trống = tự động theo ped)', optional = true },
    },
    restricted = 'group.admin',
}, function(source, args)
    -- Kiểm tra xem có phải admin hoặc console không
    if source ~= 0 and not IsPlayerStaff(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
        return
    end

    local targetId = args.target
    local componentType = args.component
    local drawable = args.drawable
    local texture = args.texture or 0
    local sex = args.sex and string.lower(args.sex) or nil
    if sex and sex ~= 'male' and sex ~= 'female' then
        TriggerClientEvent('QBCore:Notify', source, 'Sex không hợp lệ: dùng male hoặc female', 'error')
        return
    end

    -- Sử dụng function mới
    local success, response = GiveClothingItem(targetId, componentType, drawable, texture, source, sex)
    
    if not success then
        return Citizen.Trace(('Failed to give %s (drawable: %d, texture: %d) to player %s (%s)'):format(componentType, drawable, texture, targetId, response))
    end

    source = source == 0 and { label = 'console', owner = 'console' } or QBCore.Functions.GetPlayer(source)
    
    if source then
        lib.logger(source.owner or 'console', 'admin', ('"%s" gave %s (drawable: %d, texture: %d, sex: %s) to player %s'):format(source.label or 'console', componentType, drawable, texture, sex or 'auto', targetId))
    end
end)

-- =====================================================
-- GETDOHIEM COMMAND - In danh sách drawable theo độ hiếm ra F8
-- /getdohiem [gender] [slot] [rarity?]
-- Ví dụ: /getdohiem male shirt common
--         /getdohiem female torso          (hiện tất cả rarities)
-- =====================================================
lib.addCommand('getdohiem', {
    help = 'In danh sách drawable theo độ hiếm ra F8',
    params = {
        { name = 'gender',  type = 'string', help = 'male hoặc female' },
        { name = 'slot',    type = 'string', help = 'shirt, torso, pants, shoes, hat, mask, glasses, vest, bag, gloves, chain, earrings, watch, bracelets' },
        { name = 'rarity',  type = 'string', help = 'common / uncommon / rare / epic / legendary (bỏ trống = tất cả)', optional = true },
    },
    restricted = 'group.admin',
}, function(source, args)
    -- Kiểm tra quyền admin
    if source ~= 0 and not IsPlayerStaff(source) then
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
        return
    end

    local gender = string.lower(args.gender)
    local slot   = string.lower(args.slot)
    local rarity = args.rarity and (args.rarity:sub(1,1):upper() .. args.rarity:sub(2):lower()) or nil

    -- Validate gender
    if gender ~= 'male' and gender ~= 'female' then
        local msg = '[getdohiem] Gender không hợp lệ: ' .. gender .. ' (dùng male hoặc female)'
        print(msg)
        if source ~= 0 then TriggerClientEvent('XNClothes:printF8', source, msg) end
        return
    end

    -- Validate slot
    if not componentMapping[slot] or not componentMapping[slot].component then
        local msg = '[getdohiem] Slot không hợp lệ: ' .. slot
        print(msg)
        if source ~= 0 then TriggerClientEvent('XNClothes:printF8', source, msg) end
        return
    end

    local componentId = componentMapping[slot].component
    local isProp      = componentMapping[slot].prop
    local rarityLevels = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'}

    -- Validate rarity nếu có
    if rarity then
        local valid = false
        for _, r in ipairs(rarityLevels) do
            if r == rarity then valid = true break end
        end
        if not valid then
            local msg = '[getdohiem] Rarity không hợp lệ: ' .. rarity .. ' (dùng common/uncommon/rare/epic/legendary)'
            print(msg)
            if source ~= 0 then TriggerClientEvent('XNClothes:printF8', source, msg) end
            return
        end
    end

    -- Build output lines
    local lines = {}
    local levelsToCheck = rarity and {rarity} or rarityLevels

    for _, r in ipairs(levelsToCheck) do
        local drawables = GetDrawablesByRarity(componentId, isProp, gender, r)
        if drawables and #drawables > 0 then
            table.sort(drawables)
            local nums = {}
            for _, d in ipairs(drawables) do
                table.insert(nums, tostring(d))
            end
            table.insert(lines, string.format('%s (%s) [%s]: {%s}', slot, gender, r, table.concat(nums, ',')))
        else
            table.insert(lines, string.format('%s (%s) [%s]: {} (không có)', slot, gender, r))
        end
    end

    -- Print to server console
    for _, line in ipairs(lines) do
        print(line)
    end

    -- Send to admin F8
    if source ~= 0 then
        TriggerClientEvent('XNClothes:printF8', source, lines)
    end
end)

-- Helper function to get rarity data using UI name
function getRarityDataByUIName(gender, uiName, rarity)
    if not componentMapping[uiName] then
        return nil
    end
    
    local componentId = componentMapping[uiName].component
    local isProp = componentMapping[uiName].prop
    
    -- Get from SQL first
    local drawables = GetDrawablesByRarity(componentId, isProp, gender, rarity)
    if drawables and #drawables > 0 then
        return drawables
    end
    
    -- Fallback to config for backward compatibility
    local itemName = Config.UIToItemMapping[uiName]
    if not itemName then
        return nil
    end
    
    if Config.Dohiem[gender] and Config.Dohiem[gender][itemName] then
        return Config.Dohiem[gender][itemName][rarity]
    end
    
    return nil
end

-- Helper function to get all rarity data for a UI item
function getAllRarityDataByUIName(gender, uiName)
    if not componentMapping[uiName] then
        return nil
    end
    
    local componentId = componentMapping[uiName].component
    local isProp = componentMapping[uiName].prop
    
    -- Get all rarities from SQL
    local allRarities = {}
    local rarityLevels = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary'}
    
    for _, rarity in ipairs(rarityLevels) do
        local drawables = GetDrawablesByRarity(componentId, isProp, gender, rarity)
        if drawables and #drawables > 0 then
            allRarities[rarity] = drawables
        end
    end
    
    -- If SQL has data, return it
    if next(allRarities) then
        return allRarities
    end
    
    -- Fallback to config
    local itemName = Config.UIToItemMapping[uiName]
    if not itemName then
        return nil
    end
    
    return Config.Dohiem[gender] and Config.Dohiem[gender][itemName]
end

-- Helper function to get item name from UI name
function getItemNameFromUIName(uiName)
    return Config.UIToItemMapping[uiName]
end

-- Helper function to get UI name from item name
function getUINameFromItemName(itemName)
    for uiName, item in pairs(Config.UIToItemMapping) do
        if item == itemName then
            return uiName
        end
    end
    return nil
end


function showNotification(playerId, mes)
    if Config.FrameWork == "ESX" then
        TriggerClientEvent('esx:showNotification', playerId, mes)

    elseif Config.FrameWork == "QBOX" then
        TriggerClientEvent('QBCore:Notify', playerId, mes, "primary")
    else
        print("Framework non pris en charge pour showNotification")
    end
end

function GetPlayer(source)
    if Config.FrameWork == "ESX" then
        return ESX.GetPlayerFromId(source)
    
    elseif Config.FrameWork == "QBOX" then
        return QBCore.Functions.GetPlayer(source)
    else
        --print("Framework non pris en charge pour GetPlayer")
        return nil
    end
end

function GetPlayerMoney(source)
    local player = GetPlayer(source)
    if not player then return 0 end

    if Config.FrameWork == "ESX" then
        return player.getMoney()

    elseif Config.FrameWork == "QBOX" then
        return player.Functions.GetMoney("cash")

    else
        --print("Framework non pris en charge pour GetPlayerMoney")
        return 0
    end
end

function RemovePlayerMoney(source, amount)
    local player = GetPlayer(source)
    if not player then return false end

    if Config.FrameWork == "ESX" then
        player.removeMoney(amount)
        return true

    elseif Config.FrameWork == "QBOX" then
        player.Functions.RemoveMoney("cash", amount, "script-remove-money")
        return true
    else
        --print("Framework non pris en charge pour RemovePlayerMoney")
        return false
    end
end

function GetPlayerIdentifier(source)
    local player = GetPlayer(source)
    if not player then return nil end

    if Config.FrameWork == "ESX" then
        return player.identifier

    elseif Config.FrameWork == "QBOX" then
        if player.PlayerData and player.PlayerData.citizenid then
            return player.PlayerData.citizenid
        end
        local identifiers = GetPlayerIdentifiers(source)
        for _, id in ipairs(identifiers) do
            if id:match("steam:") or id:match("license:") then
                return id
            end
        end
        return nil
    else
        --print("Framework non pris en charge pour GetPlayerIdentifier")
        return nil
    end
end

function GetPlayerSource(player)
    if not player then return nil end

    if Config.FrameWork == "ESX" then
        return player.source or nil

    elseif Config.FrameWork == "QBOX" then
        return player.PlayerData and player.PlayerData.source or player.source or nil
    else
        --print("Framework non pris en charge pour GetPlayerSource")
        return nil
    end
end

function AddPlayerMoney(source, amount)
    local player = GetPlayer(source)
    if not player then return false end

    if Config.FrameWork == "ESX" then
        player.addMoney(amount)
        return true

    elseif Config.FrameWork == "QBOX" then
        player.Functions.AddMoney("cash", amount, "script-add-money")
        return true

    else
        print("Framework non pris en charge pour AddPlayerMoney")
        return false
    end
end

function GetJobName(source)
    local player = GetPlayer(source)
    if not player then return nil end

    if Config.FrameWork == "ESX" then
        return player.job.name

    elseif Config.FrameWork == "QBOX" then
        return player.PlayerData.job.name
    else
        print("Framework non pris en charge pour GetJobName")
        return nil
    end
end

-- =====================================================
-- ADMIN COMMAND: /setpity AND BALO PITY METADATA UPDATE
-- =====================================================

RegisterCommand('setpity', function(source, args, rawCommand)
    local src = source
    if src == 0 then
        print("Lệnh này chỉ có thể sử dụng trong game bởi Admin.")
        return
    end

    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    -- Phân quyền: QBCore admin/god
    if not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền sử dụng lệnh này!', 'error')
        return
    end

    local targetId = src

    -- Quét kho đồ của người chơi
    local inventory = exports.ox_inventory:GetInventory(targetId, true)
    if not inventory or not inventory.items then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể lấy dữ liệu kho đồ!', 'error')
        return
    end

    local backpacks = {}
    for slot, item in pairs(inventory.items) do
        if item and type(item) == 'table' and item.name == 'cloth_bags' then
            local metadata = item.metadata or {}
            local drawable = metadata.drawable or 0
            local sex = metadata.sex or 'male'
            
            -- Lấy số slot chứa đồ của balo từ configbalo.lua
            local maxSlots = 0
            local level = GetBagLevelByDrawable(sex, drawable)
            if level and Config.TuiDo and Config.TuiDo[sex] and Config.TuiDo[sex][level] then
                maxSlots = Config.TuiDo[sex][level].so_Slot or 0
            end

            table.insert(backpacks, {
                slot = item.slot,
                maxSlots = maxSlots,
                label = item.label or 'Balo',
                serial = metadata.serial or 'Không có',
                drawable = drawable,
                pitynum = metadata.pitynum or 0
            })
        end
    end

    if #backpacks == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có balo nào trong túi đồ!', 'error')
        return
    end

    -- Gửi dữ liệu về client admin để show context menu
    TriggerClientEvent('XNClothes:client:showBaloPityMenu', src, targetId, backpacks)
end, false)

RegisterNetEvent('XNClothes:server:requestBaloMenu', function(targetId, adminId)
    local src = adminId or source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    if not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy người chơi mục tiêu!', 'error')
        return
    end

    local inventory = exports.ox_inventory:GetInventory(targetId, true)
    if not inventory or not inventory.items then
        TriggerClientEvent('QBCore:Notify', src, 'Không thể lấy dữ liệu kho đồ!', 'error')
        return
    end

    local backpacks = {}
    for slot, item in pairs(inventory.items) do
        if item and type(item) == 'table' and item.name == 'cloth_bags' then
            local metadata = item.metadata or {}
            local drawable = metadata.drawable or 0
            local sex = metadata.sex or 'male'
            
            local maxSlots = 0
            local level = GetBagLevelByDrawable(sex, drawable)
            if level and Config.TuiDo and Config.TuiDo[sex] and Config.TuiDo[sex][level] then
                maxSlots = Config.TuiDo[sex][level].so_Slot or 0
            end

            table.insert(backpacks, {
                slot = item.slot,
                maxSlots = maxSlots,
                label = item.label or 'Balo',
                serial = metadata.serial or 'Không có',
                drawable = drawable,
                pitynum = metadata.pitynum or 0
            })
        end
    end

    if #backpacks > 0 then
        TriggerClientEvent('XNClothes:client:showBaloPityMenu', src, targetId, backpacks)
    end
end)

RegisterNetEvent('XNClothes:server:setBaloPity', function(targetId, slot, newPity)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    -- Bảo mật kiểm tra quyền admin
    if not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền thực hiện hành động này!', 'error')
        return
    end

    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy người chơi mục tiêu!', 'error')
        return
    end

    -- Lấy thông tin balo tại slot chỉ định
    local item = exports.ox_inventory:GetSlot(targetId, slot)
    if not item or item.name ~= 'cloth_bags' then
        TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy balo ở slot này!', 'error')
        return
    end

    local metadata = item.metadata or {}
    local oldPity = metadata.pitynum or 0
    metadata.pitynum = newPity

    -- Cập nhật metadata trong ox_inventory
    exports.ox_inventory:SetMetadata(targetId, slot, metadata)

    TriggerClientEvent('QBCore:Notify', src, string.format('Đã cập nhật Pity cho Balo (Slot %d) của ID %d: %d -> %d', slot, targetId, oldPity, newPity), 'success')
    TriggerClientEvent('QBCore:Notify', targetId, string.format('Balo của bạn đã được Admin thay đổi Pity thành %d', newPity), 'primary')

    -- Reload menu balo của admin
    TriggerEvent('XNClothes:server:requestBaloMenu', targetId, src)
end)