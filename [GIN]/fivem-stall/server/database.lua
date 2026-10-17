-- Không cần local MySQL = exports.oxmysql vì đã import qua @oxmysql/lib/MySQL.lua

local QBCore = exports['qb-core']:GetCoreObject()

-- Tạo bảng database
function CreateTables()
    -- Bảng stall chính
    local stallTable = [[
        CREATE TABLE IF NOT EXISTS stall_system (
            id INT AUTO_INCREMENT PRIMARY KEY,
            stall_id INT NOT NULL,
            citizenid VARCHAR(50),
            owner_name VARCHAR(100),
            rent_start INT NULL DEFAULT NULL,
            rent_end INT NULL DEFAULT NULL,
            revenue INT DEFAULT 0,
            unclaimed_money INT DEFAULT 0,
            is_active BOOLEAN DEFAULT FALSE,
            created_at INT NULL DEFAULT NULL
        )
    ]]

    -- Bảng vật phẩm trong stall - ĐÃ XÓA CÁC CỘT KHÔNG CẦN THIẾT
    local stallItemsTable = [[
        CREATE TABLE IF NOT EXISTS stall_items (
            id INT AUTO_INCREMENT PRIMARY KEY,
            stall_id INT NOT NULL,
            item_name VARCHAR(100) NOT NULL,
            item_label VARCHAR(100),
            quantity INT NOT NULL DEFAULT 0,
            price INT NOT NULL DEFAULT 0,
            item_metadata LONGTEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]]

    -- Bảng lịch sử giao dịch
    local transactionsTable = [[
        CREATE TABLE IF NOT EXISTS stall_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            stall_id INT NOT NULL,
            seller_identifier VARCHAR(50),
            buyer_identifier VARCHAR(50),
            buyer_name VARCHAR(100),
            item_name VARCHAR(100),
            item_label VARCHAR(100),
            item_metadata LONGTEXT,
            quantity INT,
            price_per_unit INT,
            total_price INT,
            tax INT,
            transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]]

    MySQL.query(stallTable, {}, function(result)
        if result then
            print("^2[StallSystem] Stall table created successfully^7")
            
            -- Tự động chuyển đổi các cột TIMESTAMP sang INT nếu đang ở kiểu cũ
            MySQL.query([[
                ALTER TABLE stall_system 
                MODIFY COLUMN rent_start INT NULL DEFAULT NULL,
                MODIFY COLUMN rent_end INT NULL DEFAULT NULL,
                MODIFY COLUMN created_at INT NULL DEFAULT NULL;
            ]], {}, function(alterResult)
                print("^2[StallSystem] Migrated columns to INT if needed^7")
            end)

            -- Kiểm tra xem index UNIQUE stall_id có tồn tại không trước khi xóa
            local checkIndexQuery = [[
                SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'stall_system' 
                AND INDEX_NAME = 'stall_id' 
                LIMIT 1
            ]]
            MySQL.query(checkIndexQuery, {}, function(indexResult)
                if indexResult and #indexResult > 0 then
                    MySQL.query('ALTER TABLE stall_system DROP INDEX stall_id', {}, function(res)
                        print("^3[StallSystem] Executed index drop query for 'stall_id'^7")
                    end)
                end
            end)
        else
            print("^1[StallSystem] Failed to create stall table^7")
        end
    end)

    MySQL.query(stallItemsTable, {}, function(result)
        if result then
            print("^2[StallSystem] Stall items table created successfully^7")
        else
            print("^1[StallSystem] Failed to create stall items table^7")
        end
    end)

    MySQL.query(transactionsTable, {}, function(result)
        if result then
            print("^2[StallSystem] Transactions table created successfully^7")
        else
            print("^1[StallSystem] Failed to create stall transactions table^7")
        end
    end)
end

-- Lấy thông tin gian hàng - CHỈ LẤY ACTIVE
function GetStallData(stallId)
    local promise = promise.new()
    
    MySQL.query('SELECT * FROM stall_system WHERE stall_id = ? AND is_active = 1', 
        {stallId}, 
        function(result)
            promise:resolve(result)
        end
    )
    
    local result = Citizen.Await(promise)
    if result and #result > 0 then
        local stallData = result[1]
        local items = GetStallItems(stallData.id)
        stallData.items = items
        return stallData
    else
        return nil
    end
end

-- Lấy thông tin gian hàng thô (chỉ check is_active = 1, dùng để check hết hạn)
function GetStallDataRaw(stallId)
    local promise = promise.new()
    
    MySQL.query('SELECT * FROM stall_system WHERE stall_id = ? AND is_active = 1', 
        {stallId}, 
        function(result)
            promise:resolve(result)
        end
    )
    
    local result = Citizen.Await(promise)
    if result and #result > 0 then
        local stallData = result[1]
        local items = GetStallItems(stallData.id)
        stallData.items = items
        return stallData
    else
        return nil
    end
end

-- Lấy thông tin gian hàng theo citizenid
function GetStallDataByCitizenId(citizenid)
    local promise = promise.new()
    
    MySQL.query('SELECT * FROM stall_system WHERE citizenid = ? AND is_active = 1 LIMIT 1', 
        {citizenid}, 
        function(result)
            promise:resolve(result)
        end
    )
    
    local result = Citizen.Await(promise)
    if result and #result > 0 then
        local stallData = result[1]
        local items = GetStallItems(stallData.id)
        stallData.items = items
        return stallData
    else
        return nil
    end
end

-- Danh sách item_name đặc biệt (Clothes)
local CLOTHES_ITEMS = {
    "cloth_mask",      -- Mặt nạ
    "cloth_helmet",    -- Mũ
    "cloth_ears",      -- Phụ kiện tai
    "cloth_glasses",   -- Kính mắt
    "cloth_bags",      -- Túi xách
    "cloth_tshirt",    -- Áo thun
    "cloth_torso",     -- Áo khoác / phần thân trên
    "cloth_bproof",    -- Áo chống đạn
    "cloth_bracelets", -- Vòng tay
    "cloth_watches",   -- Đồng hồ
    "cloth_chain",     -- Dây chuyền
    "cloth_pants",     -- Quần dài
    "cloth_shoes",     -- Giày
    "cloth_arms",      -- Tay (phụ kiện hoặc phần thân)
    "clothes"          -- Quần áo
}

-- Hàm kiểm tra item có phải clothes không
function IsClothesItem(itemName)
    for _, name in ipairs(CLOTHES_ITEMS) do
        if name == itemName then
            return true
        end
    end
    return false
end

-- Hàm lấy label từ ox_inventory
function GetItemLabelFromOx(itemName)
    local itemData = exports.ox_inventory:GetItem(itemName)
    if itemData and itemData.label then
        return itemData.label
    end
    return nil
end
-- Lấy danh sách items của stall
function GetStallItems(stallId)
    local promise = promise.new()
    
    MySQL.query('SELECT * FROM stall_items WHERE stall_id = ? ORDER BY id ASC', 
        {stallId}, 
        function(result)
            if result then
                local items = {}
                for _, row in ipairs(result) do
                    local metadata = {}
                    
                    -- Lấy metadata từ item_metadata (nếu có)
                    if row.item_metadata and row.item_metadata ~= 'null' then
                        metadata = json.decode(row.item_metadata) or {}
                    end
                    
                    -- Lấy label từ cột item_label (đã được lưu sẵn)
                    local itemLabel = row.item_label or row.item_name
                    
                    -- Nếu có label trong metadata, ưu tiên dùng metadata label (cho các item có metadata)
                    if metadata.label and metadata.label ~= '' then
                        itemLabel = metadata.label
                    end
                    
                    local item = {
                        name = row.item_name,
                        label = itemLabel,
                        count = row.quantity,
                        price = row.price,
                        metadata = metadata
                    }
                    
                    table.insert(items, item)
                end
                promise:resolve(items)
            else
                promise:resolve({})
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Tạo hoặc cập nhật gian hàng dựa trên citizenid và stallId
function CreateStall(stallId, citizenid, ownerName, hours)
    local promise = promise.new()
    
    if not hours or hours <= 0 then
        print("^1[StallSystem] Invalid hours: " .. tostring(hours) .. "^7")
        promise:resolve(nil)
        return Citizen.Await(promise)
    end
    
    local now = os.time()
    local endTime = now + (hours * 3600)
    
    -- Kiểm tra xem người chơi đã từng thuê bất kỳ gian hàng nào và hiện đang hết hạn không (is_active = 0)
    MySQL.query('SELECT id FROM stall_system WHERE citizenid = ? AND is_active = 0 LIMIT 1', 
        {citizenid}, 
        function(result)
            if result and #result > 0 then
                -- Đã từng thuê và hiện đang hết hạn -> update lại stall_id mới và is_active = 1
                local systemId = result[1].id
                print("^3[StallSystem] Player " .. citizenid .. " has an expired stall record (System ID: " .. systemId .. "), updating to stall " .. stallId .. " and setting is_active = 1^7")
                
                MySQL.update('UPDATE stall_system SET stall_id = ?, owner_name = ?, rent_start = ?, rent_end = ?, created_at = ?, is_active = 1 WHERE id = ?',
                    {stallId, ownerName, now, endTime, now, systemId},
                    function(affectedRows)
                        if affectedRows and affectedRows > 0 then
                            print("^2[StallSystem] ✅ Updated existing stall record " .. systemId .. " to stall " .. stallId .. " for player " .. citizenid .. "^7")
                            promise:resolve(systemId)
                        else
                            print("^1[StallSystem] ❌ Failed to update stall record " .. systemId .. " for player " .. citizenid .. "^7")
                            promise:resolve(nil)
                        end
                    end
                )
            else
                -- Chưa từng thuê hoặc không có gian hàng nào hết hạn -> insert dòng mới
                print("^3[StallSystem] Player " .. citizenid .. " has no expired stall record, inserting new record for stall " .. stallId .. "^7")
                
                MySQL.insert('INSERT INTO stall_system (stall_id, citizenid, owner_name, rent_start, rent_end, created_at, is_active) VALUES (?, ?, ?, ?, ?, ?, 1)',
                    {stallId, citizenid, ownerName, now, endTime, now},
                    function(insertId)
                        if insertId then
                            print("^2[StallSystem] ✅ Created new record for player " .. citizenid .. " with stall " .. stallId .. " (System ID: " .. insertId .. ")^7")
                            promise:resolve(insertId)
                        else
                            print("^1[StallSystem] ❌ Failed to insert stall " .. insertId .. " for player " .. citizenid .. "^7")
                            promise:resolve(nil)
                        end
                    end
                )
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Gia hạn gian hàng
function RenewStall(stallId, citizenid, additionalHours)
    local promise = promise.new()
    
    if not additionalHours or additionalHours <= 0 then
        promise:resolve(false)
        return Citizen.Await(promise)
    end
    
    MySQL.query('SELECT rent_end FROM stall_system WHERE stall_id = ? AND citizenid = ? AND is_active = 1', 
        {stallId, citizenid}, 
        function(result)
            if result and #result > 0 then
                local newEnd = os.time() + (additionalHours * 3600)
                
                MySQL.update('UPDATE stall_system SET rent_end = ? WHERE stall_id = ? AND citizenid = ? AND is_active = 1',
                    {newEnd, stallId, citizenid},
                    function(affectedRows)
                        if affectedRows and affectedRows > 0 then
                            print("^2[StallSystem] ✅ Renewed stall " .. stallId .. " for " .. citizenid .. " (+" .. additionalHours .. " hours)^7")
                            promise:resolve(true)
                        else
                            print("^1[StallSystem] ❌ Failed to renew stall " .. stallId .. "^7")
                            promise:resolve(false)
                        end
                    end
                )
            else
                print("^1[StallSystem] Stall " .. stallId .. " not found or not owned by " .. citizenid .. "^7")
                promise:resolve(false)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Hàm chuyển đổi metadata
function ConvertMetadataTypes(metadata)
    if not metadata then return {} end
    
    local converted = {}
    for k, v in pairs(metadata) do
        if k == 'id' or k == 'drawable' or k == 'texture' or k == 'type' or k == 'durability' then
            if v ~= nil and v ~= '' then
                converted[k] = tonumber(v)
            else
                converted[k] = v
            end
        else
            converted[k] = v
        end
    end
    return converted
end
-- Cập nhật items trong gian hàng
function UpdateStallItems(stallId, items)
    local promise = promise.new()
    
    MySQL.query('DELETE FROM stall_items WHERE stall_id = ?', {stallId}, function(deleteResult)
        if items and #items > 0 then
            local count = #items
            local successCount = 0
            local hasError = false
            
            for _, item in ipairs(items) do
                local metadata = item.metadata or {}
                local convertedMetadata = {}
                
                -- Chỉ chuyển đổi các field nếu có giá trị
                for k, v in pairs(metadata) do
                    if v ~= nil and v ~= '' then
                        if k == 'id' or k == 'drawable' or k == 'texture' or k == 'type' or k == 'durability' then
                            convertedMetadata[k] = tonumber(v)
                        else
                            convertedMetadata[k] = v
                        end
                    end
                end
                
                -- Lấy label từ ox_inventory cho item (dùng để hiển thị)
                local itemLabel = item.label or GetItemLabelFromOx(item.name) or item.name
                
                -- Nếu có label trong metadata, ưu tiên dùng metadata label
                if metadata.label and metadata.label ~= '' then
                    itemLabel = metadata.label
                end
                
                -- CHỈ LƯU METADATA NẾU CÓ DỮ LIỆU (không bao gồm label)
                local hasMetadata = false
                local metadataToSave = {}
                for k, v in pairs(convertedMetadata) do
                    if k ~= 'label' and v ~= nil and v ~= '' then
                        metadataToSave[k] = v
                        hasMetadata = true
                    end
                end
                
                local metadataStr = nil
                if hasMetadata then
                    metadataStr = json.encode(metadataToSave)
                end
                
                -- Thực hiện INSERT đơn lẻ cho từng item để tránh lỗi lệch tham số do giá trị nil trong Lua
                MySQL.insert('INSERT INTO stall_items (stall_id, item_name, item_label, quantity, price, item_metadata) VALUES (?, ?, ?, ?, ?, ?)',
                    {stallId, item.name, itemLabel, item.count, item.price, metadataStr},
                    function(insertId)
                        successCount = successCount + 1
                        if not insertId then
                            hasError = true
                        end
                        
                        if successCount == count then
                            promise:resolve(not hasError)
                        end
                    end
                )
            end
        else
            promise:resolve(true)
        end
    end)
    
    return Citizen.Await(promise)
end

-- Cập nhật doanh thu
function UpdateStallRevenue(stallId, revenue, unclaimedMoney)
    local promise = promise.new()
    
    MySQL.update('UPDATE stall_system SET revenue = revenue + ?, unclaimed_money = unclaimed_money + ? WHERE stall_id = ? AND is_active = 1',
        {revenue, unclaimedMoney, stallId},
        function(affectedRows)
            if affectedRows then
                promise:resolve(true)
            else
                promise:resolve(false)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Lấy tiền chưa nhận
function GetUnclaimedMoney(stallId, citizenid)
    local promise = promise.new()
    
    MySQL.query('SELECT unclaimed_money FROM stall_system WHERE stall_id = ? AND citizenid = ? AND is_active = 1',
        {stallId, citizenid},
        function(result)
            if result and #result > 0 then
                promise:resolve(result[1].unclaimed_money)
            else
                promise:resolve(0)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Rút tiền chưa nhận
function WithdrawUnclaimedMoney(stallId, citizenid)
    local promise = promise.new()
    
    MySQL.query('SELECT unclaimed_money FROM stall_system WHERE stall_id = ? AND citizenid = ? AND is_active = 1', 
        {stallId, citizenid},
        function(result)
            if result and #result > 0 then
                local amount = result[1].unclaimed_money
                
                if amount and amount > 0 then
                    MySQL.update('UPDATE stall_system SET unclaimed_money = 0 WHERE stall_id = ? AND citizenid = ?',
                        {stallId, citizenid},
                        function(affectedRows)
                            if affectedRows and affectedRows > 0 then
                                promise:resolve(amount)
                            else
                                promise:resolve(0)
                            end
                        end
                    )
                else
                    promise:resolve(0)
                end
            else
                promise:resolve(0)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Đếm số gian hàng của người chơi
function CountPlayerStalls(citizenid)
    local promise = promise.new()
    
    MySQL.query('SELECT COUNT(*) as count FROM stall_system WHERE citizenid = ? AND is_active = 1',
        {citizenid},
        function(result)
            if result and #result > 0 then
                promise:resolve(result[1].count)
            else
                promise:resolve(0)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Thêm lịch sử giao dịch
function AddTransaction(stallId, sellerIdentifier, buyerIdentifier, buyerName, itemName, itemLabel, itemMetadata, quantity, pricePerUnit, totalPrice, tax)
    local metadataJson = json.encode(itemMetadata or {})
    
    MySQL.insert('INSERT INTO stall_transactions (stall_id, seller_identifier, buyer_identifier, buyer_name, item_name, item_label, item_metadata, quantity, price_per_unit, total_price, tax) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            stallId, 
            sellerIdentifier, 
            buyerIdentifier, 
            buyerName, 
            itemName, 
            itemLabel or itemName,
            metadataJson,
            quantity, 
            pricePerUnit, 
            totalPrice, 
            tax
        }
    )
end

-- Lấy lịch sử giao dịch
function GetTransactionHistory(stallId, limit)
    limit = limit or 20
    local promise = promise.new()
    
    MySQL.query('SELECT * FROM stall_transactions WHERE stall_id = ? ORDER BY transaction_time DESC LIMIT ?',
        {stallId, limit},
        function(result)
            if result then
                for _, row in ipairs(result) do
                    if row.item_metadata then
                        row.item_metadata = json.decode(row.item_metadata) or {}
                    else
                        row.item_metadata = {}
                    end
                end
            end
            promise:resolve(result or {})
        end
    )
    
    return Citizen.Await(promise)
end

-- UPDATE KHI HẾT HẠN
function UpdateExpiredStall(stallId, citizenid)
    local promise = promise.new()
    
    print("^3[StallSystem] Updating expired stall " .. stallId .. " for citizenid: " .. (citizenid or "N/A") .. "^7")
    
    MySQL.update('UPDATE stall_system SET owner_name = NULL, rent_start = NULL, rent_end = NULL, created_at = NULL, is_active = 0, revenue = 0 WHERE stall_id = ? AND citizenid = ?',
        {stallId, citizenid},
        function(affectedRows)
            if affectedRows and affectedRows > 0 then
                print("^2[StallSystem] ✅ Stall " .. stallId .. " for owner " .. citizenid .. " has been deactivated and reset^7")
                promise:resolve(true)
            else
                print("^1[StallSystem] ❌ Failed to update stall " .. stallId .. " for owner " .. citizenid .. "^7")
                promise:resolve(false)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- FORCE EXPIRE STALL
function ForceExpireStall(stallId)
    local promise = promise.new()
    
    MySQL.query('SELECT id, citizenid, owner_name, rent_start, rent_end FROM stall_system WHERE stall_id = ? AND is_active = 1', 
        {stallId},
        function(result)
            promise:resolve(result)
        end
    )
    
    local result = Citizen.Await(promise)
    if result and #result > 0 then
        local systemId = result[1].id
        local citizenid = result[1].citizenid
        local ownerName = result[1].owner_name
        local rentStart = result[1].rent_start
        local rentEnd = result[1].rent_end
        
        print("^3[StallSystem] Force expiring stall " .. stallId .. " (rental ID: " .. systemId .. ") - Owner: " .. (ownerName or "Unknown") .. " (citizenid: " .. (citizenid or "N/A") .. ")^7")
        
        -- Lấy danh sách các vật phẩm còn lại trong gian hàng trước khi kết thúc
        local items = GetStallItems(systemId)
        
        -- Tạo nội dung log chi tiết
        local timeStr = os.date("%Y-%m-%d %H:%M:%S")
        local startStr = rentStart and os.date("%Y-%m-%d %H:%M:%S", rentStart) or "Không rõ"
        local endStr = rentEnd and os.date("%Y-%m-%d %H:%M:%S", rentEnd) or "Không rõ"
        local durationHrs = (rentStart and rentEnd) and math.floor((rentEnd - rentStart) / 3600) or 0

        local logHeader = string.format("==================== GIAN HÀNG HẾT HẠN (STALL EXPIRED) ====================\n" ..
                                        "Thời gian ghi log: %s\n" ..
                                        "Gian hàng ID: %d (Rental System ID: %d)\n" ..
                                        "Chủ gian hàng: %s (CitizenID: %s)\n" ..
                                        "Thời gian thuê: Từ %s đến %s (Tổng cộng: %d giờ)\n" ..
                                        "---------------- Danh sách vật phẩm đang bán ----------------\n",
                                        timeStr, stallId, systemId, ownerName or "Không rõ", citizenid or "Không rõ", startStr, endStr, durationHrs)

        local logItems = ""
        if items and #items > 0 then
            for i, item in ipairs(items) do
                local metaStr = json.encode(item.metadata or {})
                logItems = logItems .. string.format("[%d] %s (%s) - Số lượng: %d - Giá: %d$ - Metadata: %s\n",
                                                     i, item.label or item.name, item.name, item.count, item.price, metaStr)
            end
        else
            logItems = "Không có vật phẩm nào trong gian hàng.\n"
        end

        local logFooter = "========================================================================\n\n"
        local fullLog = logHeader .. logItems .. logFooter

        -- 1. In log ra console server
        print("^1[StallSystem] GIAN HÀNG HẾT HẠN - Ghi log hệ thống...^7")
        print(fullLog)

        -- 2. Ghi log vào file expired_stalls.log trong thư mục resource
        local existing = LoadResourceFile(GetCurrentResourceName(), "expired_stalls.log") or ""
        local newLog = existing .. fullLog
        SaveResourceFile(GetCurrentResourceName(), "expired_stalls.log", newLog, -1)

        -- 3. Gửi log qua Discord Webhook nếu được cấu hình
        if Config.DiscordWebhook and Config.DiscordWebhook ~= "" then
            local fields = {
                { name = "Gian hàng ID", value = tostring(stallId), inline = true },
                { name = "Chủ gian hàng", value = string.format("%s (%s)", ownerName or "Không rõ", citizenid or "Không rõ"), inline = true },
                { name = "Thời gian log", value = timeStr, inline = true },
                { name = "Thời gian thuê", value = string.format("Từ: %s\nĐến: %s\n(Tổng cộng: %d giờ)", startStr, endStr, durationHrs), inline = false }
            }
            print("ok dícord")
            
            local itemLines = {}
            if items and #items > 0 then
                for i, item in ipairs(items) do
                    table.insert(itemLines, string.format("- **%s** (`%s`) x%d | Giá: %d$", item.label or item.name, item.name, item.count, item.price))
                end
            else
                table.insert(itemLines, "Không có vật phẩm nào.")
            end
            
            local itemsText = table.concat(itemLines, "\n")
            if #itemsText > 1024 then
                itemsText = string.sub(itemsText, 1, 1021) .. "..."
            end
            
            table.insert(fields, { name = "Vật phẩm đang bán", value = itemsText, inline = false })
            
            local embed = {
                {
                    title = "🔴 GIAN HÀNG HẾT HẠN (STALL EXPIRED)",
                    color = 16711680, -- Màu đỏ
                    fields = fields,
                    footer = { text = "Stall System Log" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
            
            PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) 
                if err ~= 200 and err ~= 204 then
                    print("^1[StallSystem] Discord Webhook Error: " .. tostring(err) .. " - Response: " .. tostring(text) .. "^7")
                else
                    print("^2[StallSystem] Discord Webhook sent successfully!^7")
                end
            end, 'POST', json.encode({username = "Stall System Bot", embeds = embed}), { ['Content-Type'] = 'application/json' })
        end

        -- Xóa các vật phẩm gắn với rental ID (stall_system.id) (Không xóa vật phẩm khi hết hạn)
        -- MySQL.query('DELETE FROM stall_items WHERE stall_id = ?', {systemId})
        
        local success = UpdateExpiredStall(stallId, citizenid)
        return success
    else
        print("^1[StallSystem] Stall " .. stallId .. " not found or not active^7")
        return false
    end
end

-- Đếm tổng số items đã bán
function GetTotalItemsSold(stallId)
    local promise = promise.new()
    
    MySQL.query('SELECT SUM(quantity) as total FROM stall_transactions WHERE stall_id = ?',
        {stallId},
        function(result)
            if result and #result > 0 then
                promise:resolve(result[1].total or 0)
            else
                promise:resolve(0)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Lấy số lượng item cụ thể trong stall
function GetItemCountInStall(stallId, itemName, metadata)
    local promise = promise.new()
    
    local query = 'SELECT quantity FROM stall_items WHERE stall_id = ? AND item_name = ?'
    local params = {stallId, itemName}
    
    -- Chỉ lọc theo metadata nếu có
    if metadata then
        -- Vì metadata được lưu dưới dạng JSON, cần sử dụng JSON_EXTRACT
        local conditions = {}
        if metadata.drawable then
            table.insert(conditions, 'JSON_EXTRACT(item_metadata, "$.drawable") = ?')
            table.insert(params, tonumber(metadata.drawable) or metadata.drawable)
        end
        if metadata.texture then
            table.insert(conditions, 'JSON_EXTRACT(item_metadata, "$.texture") = ?')
            table.insert(params, tonumber(metadata.texture) or metadata.texture)
        end
        if metadata.type then
            table.insert(conditions, 'JSON_EXTRACT(item_metadata, "$.type") = ?')
            table.insert(params, tonumber(metadata.type) or metadata.type)
        end
        if metadata.sex then
            table.insert(conditions, 'JSON_EXTRACT(item_metadata, "$.sex") = ?')
            table.insert(params, metadata.sex)
        end
        if metadata.id then
            table.insert(conditions, 'JSON_EXTRACT(item_metadata, "$.id") = ?')
            table.insert(params, tonumber(metadata.id) or metadata.id)
        end
        if metadata.durability then
            table.insert(conditions, 'JSON_EXTRACT(item_metadata, "$.durability") = ?')
            table.insert(params, tonumber(metadata.durability) or metadata.durability)
        end
        
        if #conditions > 0 then
            query = query .. ' AND ' .. table.concat(conditions, ' AND ')
        end
    end
    
    MySQL.query(query, params, function(result)
        if result and #result > 0 then
            promise:resolve(result[1].quantity or 0)
        else
            promise:resolve(0)
        end
    end)
    
    return Citizen.Await(promise)
end

-- Kiểm tra stall có đang active không
function IsStallActive(stallId)
    local promise = promise.new()
    
    MySQL.query('SELECT id FROM stall_system WHERE stall_id = ? AND is_active = 1', 
        {stallId}, 
        function(result)
            if result and #result > 0 then
                promise:resolve(true)
            else
                promise:resolve(false)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Kiểm tra người chơi có stall active không
function HasPlayerActiveStall(citizenid)
    local promise = promise.new()
    
    MySQL.query('SELECT COUNT(*) as count FROM stall_system WHERE citizenid = ? AND is_active = 1',
        {citizenid},
        function(result)
            if result and #result > 0 then
                promise:resolve(result[1].count > 0)
            else
                promise:resolve(false)
            end
        end
    )
    
    return Citizen.Await(promise)
end

-- Tạo tables khi server start
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    CreateTables()
end)