-- XN-SELLITEM DATABASE HANDLER
-- Xử lý load/save cấu hình từ database

local QBCore = exports['qb-core']:GetCoreObject()

-- Biến global lưu config từ database
DatabaseConfig = {}

-- Cache dữ liệu admin đã format sẵn để mở admin panel nhanh hơn
AdminItemsCache = {}

-- Load cấu hình từ database khi server khởi động
function LoadConfigFromDatabase()
    local result = MySQL.query.await('SELECT * FROM xn_sellitem_config', {})
    
    if result then
        -- Khởi tạo structure
        DatabaseConfig = {
            fish = {},
            phelieu = {},
            mining = {},
            nuoithu = {},
            traicay = {},
            choden = {}
        }
        
        for _, row in ipairs(result) do
            local category = row.category
            if not DatabaseConfig[category] then
                DatabaseConfig[category] = {}
            end
            local itemName = row.item_name
            
            -- Tạo item config từ database
            local amountToChange = tonumber(row.amount_to_change)
            if not amountToChange or amountToChange <= 0 then
                amountToChange = 50
            end

            DatabaseConfig[category][itemName] = {
                Label = row.label,
                Min = row.min_price,
                Max = row.max_price,
                RandomWhenStart = row.random_when_start == 1,
                CurrentPrice = row.current_price,
                AmountSold = row.amount_sold,
                RangeChange = { row.range_change_min or 1, row.range_change_max or 4 },
                AmountToChange = amountToChange
            }
            
            -- Nếu current_price = 0 và RandomWhenStart = true, random giá ban đầu
            if DatabaseConfig[category][itemName].CurrentPrice == 0 and DatabaseConfig[category][itemName].RandomWhenStart then
                DatabaseConfig[category][itemName].CurrentPrice = math.random(row.min_price, row.max_price)
                
                -- Cập nhật lại vào database
                MySQL.update('UPDATE xn_sellitem_config SET current_price = ? WHERE category = ? AND item_name = ?', {
                    DatabaseConfig[category][itemName].CurrentPrice,
                    category,
                    itemName
                })
            elseif DatabaseConfig[category][itemName].CurrentPrice == 0 then
                -- Nếu không random, dùng giá min
                DatabaseConfig[category][itemName].CurrentPrice = row.min_price
                MySQL.update('UPDATE xn_sellitem_config SET current_price = ? WHERE category = ? AND item_name = ?', {
                    row.min_price,
                    category,
                    itemName
                })
            end
        end
        
        -- print('^2[XN-SELLITEM]^7 Đã load ^3' .. #result .. '^7 items từ database')
        
        -- Build cache sau khi load xong
        BuildAdminItemsCache()
        
        return true
    else
        -- print('^1[XN-SELLITEM]^7 Không thể load config từ database!')
        return false
    end
end

-- Tạo item mới trong database
function CreateItemConfig(category, itemName, data, initialPrice)
    local query = [[
        INSERT INTO xn_sellitem_config 
        (category, item_name, label, min_price, max_price, current_price, amount_sold, 
         random_when_start, range_change_min, range_change_max, amount_to_change)
        VALUES (?, ?, ?, ?, ?, ?, 0, ?, 1, 4, ?)
    ]]
    
    local amountToChange = tonumber(data.AmountToChange)
    if not amountToChange or amountToChange <= 0 then
        amountToChange = 50
    end

    local params = {
        category,
        itemName,
        data.Label,
        data.Min,
        data.Max,
        initialPrice or data.Min,
        data.RandomWhenStart and 1 or 0,
        amountToChange
    }
    
    local success = MySQL.insert.await(query, params)
    
    if success then
        -- Thêm vào DatabaseConfig
        if not DatabaseConfig[category] then
            DatabaseConfig[category] = {}
        end
        
        DatabaseConfig[category][itemName] = {
            Label = data.Label,
            Min = data.Min,
            Max = data.Max,
            RandomWhenStart = data.RandomWhenStart,
            CurrentPrice = initialPrice or data.Min,
            AmountSold = 0,
            RangeChange = { 1, 4 },
            AmountToChange = amountToChange
        }
        
        -- print('^2[XN-SELLITEM]^7 Đã tạo item mới: ^3' .. itemName .. '^7 trong category: ^3' .. category)
        
        -- Rebuild cache sau khi tạo item mới
        BuildAdminItemsCache()
        
        return true
    else
        -- print('^1[XN-SELLITEM]^7 Lỗi khi tạo item: ^3' .. itemName)
        return false
    end
end

-- Lưu cấu hình item vào database (cập nhật item đã tồn tại)
function SaveItemConfig(category, itemName, data)
    local amountToChange = tonumber(data.AmountToChange)
    if not amountToChange or amountToChange <= 0 then
        amountToChange = 50
    end

    local query = [[
        UPDATE xn_sellitem_config 
        SET label = ?, 
            min_price = ?, 
            max_price = ?, 
            random_when_start = ?,
            amount_to_change = ?
        WHERE category = ? AND item_name = ?
    ]]
    
    local params = {
        data.Label,
        data.Min,
        data.Max,
        data.RandomWhenStart and 1 or 0,
        amountToChange,
        category,
        itemName
    }
    
    local success = MySQL.update.await(query, params)
    
    if success then
        -- Cập nhật DatabaseConfig
        if not DatabaseConfig[category] then
            DatabaseConfig[category] = {}
        end
        
        DatabaseConfig[category][itemName] = {
            Label = data.Label,
            Min = data.Min,
            Max = data.Max,
            RandomWhenStart = data.RandomWhenStart,
            RangeChange = data.RangeChange or (DatabaseConfig[category] and DatabaseConfig[category][itemName] and DatabaseConfig[category][itemName].RangeChange) or { 1, 4 },
            AmountToChange = amountToChange,
            CurrentPrice = (DatabaseConfig[category] and DatabaseConfig[category][itemName] and DatabaseConfig[category][itemName].CurrentPrice) or data.Min,
            AmountSold = (DatabaseConfig[category] and DatabaseConfig[category][itemName] and DatabaseConfig[category][itemName].AmountSold) or 0
        }
        
        -- print('^2[XN-SELLITEM]^7 Đã cập nhật config cho item: ^3' .. itemName)
        
        -- Rebuild cache sau khi update config
        BuildAdminItemsCache()
        
        return true
    else
        -- print('^1[XN-SELLITEM]^7 Lỗi khi cập nhật config cho item: ^3' .. itemName)
        return false
    end
end

-- Xóa item khỏi database
function DeleteItemConfig(category, itemName)
    local query = 'DELETE FROM xn_sellitem_config WHERE category = ? AND item_name = ?'
    
    local success = MySQL.update.await(query, {category, itemName})
    
    if success then
        -- Xóa khỏi DatabaseConfig
        if DatabaseConfig[category] and DatabaseConfig[category][itemName] then
            DatabaseConfig[category][itemName] = nil
            -- print('^2[XN-SELLITEM]^7 Đã xóa item khỏi database: ^3' .. itemName)
            
            -- Rebuild cache sau khi xóa item
            BuildAdminItemsCache()
            
            return true
        end
    end
    
    -- print('^1[XN-SELLITEM]^7 Lỗi khi xóa item: ^3' .. itemName)
    return false
end

-- Cập nhật giá hiện tại của item
function UpdateItemPrice(category, itemName, newPrice)
    MySQL.update('UPDATE xn_sellitem_config SET current_price = ? WHERE category = ? AND item_name = ?', {
        newPrice,
        category,
        itemName
    })
    
    if DatabaseConfig[category] and DatabaseConfig[category][itemName] then
        DatabaseConfig[category][itemName].CurrentPrice = newPrice
    end
end

-- Cập nhật số lượng đã bán
function UpdateItemAmountSold(category, itemName, amount)
    MySQL.update('UPDATE xn_sellitem_config SET amount_sold = amount_sold + ? WHERE category = ? AND item_name = ?', {
        amount,
        category,
        itemName
    })
    
    if DatabaseConfig[category] and DatabaseConfig[category][itemName] then
        DatabaseConfig[category][itemName].AmountSold = (DatabaseConfig[category][itemName].AmountSold or 0) + amount
    end
end

-- Reset số lượng đã bán
function ResetItemAmountSold(category, itemName)
    MySQL.update('UPDATE xn_sellitem_config SET amount_sold = 0 WHERE category = ? AND item_name = ?', {
        category,
        itemName
    })
    
    if DatabaseConfig[category] and DatabaseConfig[category][itemName] then
        DatabaseConfig[category][itemName].AmountSold = 0
    end
end

-- Build cache của admin items để load nhanh
function BuildAdminItemsCache()
    AdminItemsCache = {}
    
    -- Lấy biến DATA từ main.lua nếu có (có thể chưa load nếu được gọi sớm)
    local xnSellitemData = nil
    local success, result = pcall(function()
        return exports['xn-sellitem']:GetDATA()
    end)
    if success then
        xnSellitemData = result
    end
    
    for category, categoryItems in pairs(DatabaseConfig) do
        for itemName, itemData in pairs(categoryItems) do
            -- Ưu tiên lấy giá từ DATA runtime (đã snap) nếu có, không thì lấy từ database
            local currentPrice = itemData.CurrentPrice
            if xnSellitemData and xnSellitemData[itemName] and xnSellitemData[itemName].Price then
                currentPrice = xnSellitemData[itemName].Price
            end
            
            table.insert(AdminItemsCache, {
                category = category,
                itemName = itemName,
                label = itemData.Label,
                min = itemData.Min,
                max = itemData.Max,
                randomWhenStart = itemData.RandomWhenStart,
                currentPrice = currentPrice,
                amountSold = itemData.AmountSold,
                amountToChange = itemData.AmountToChange or 50
            })
        end
    end
    
    -- print('^2[XN-SELLITEM CACHE]^7 Cache rebuilt with ^3' .. #AdminItemsCache .. '^7 items')
end

-- Lấy tất cả items để hiển thị admin menu (sử dụng cache)
function GetAllItemsForAdmin()
    -- Nếu cache trống, build lại
    if #AdminItemsCache == 0 then
        BuildAdminItemsCache()
    end
    
    -- Return cache ngay lập tức
    return AdminItemsCache
end

-- Load config khi server start
CreateThread(function()
    Wait(1000) -- Đợi MySQL ready
    LoadConfigFromDatabase()
end)

-- Export functions
exports('LoadConfigFromDatabase', LoadConfigFromDatabase)
exports('SaveItemConfig', SaveItemConfig)
exports('UpdateItemPrice', UpdateItemPrice)
exports('UpdateItemAmountSold', UpdateItemAmountSold)
exports('ResetItemAmountSold', ResetItemAmountSold)
exports('GetAllItemsForAdmin', GetAllItemsForAdmin)
exports('BuildAdminItemsCache', BuildAdminItemsCache)
