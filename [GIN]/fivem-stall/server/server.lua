local QBCore = exports['qb-core']:GetCoreObject()

-- Cơ chế khóa gian hàng (Stall Lock) tránh Race Condition ghi đè DB
local StallLocks = {}

-- Lưu trạng thái đã gửi thông báo cảnh báo 30 phút cho từng gian hàng
local WarningSent30Min = {}

-- Thử khóa gian hàng, tự động mở khóa sau 5 giây nếu bị kẹt
local function LockStall(stallId)
    local now = os.time()
    if StallLocks[stallId] and (now - StallLocks[stallId] < 5) then
        return false
    end
    StallLocks[stallId] = now
    return true
end

-- Giải phóng khóa gian hàng
local function UnlockStall(stallId)
    StallLocks[stallId] = nil
end

-- Callbacks
QBCore.Functions.CreateCallback('stall:getStallData', function(source, cb, stallId)
    local stallData = GetStallData(stallId)
    cb(stallData)
end)

QBCore.Functions.CreateCallback('stall:getPlayerStallCount', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(0)
        return
    end
    
    local count = CountPlayerStalls(Player.PlayerData.citizenid)
    cb(count)
end)

QBCore.Functions.CreateCallback('stall:getTransactionHistory', function(source, cb, stallId)
    local stallData = GetStallData(stallId)
    if stallData then
        local history = GetTransactionHistory(stallData.id, 20)
        cb(history)
    else
        cb({})
    end
end)

QBCore.Functions.CreateCallback('stall:getStallItems', function(source, cb, stallId)
    local stallData = GetStallData(stallId)
    if stallData then
        local items = GetStallItems(stallData.id)
        cb(items)
    else
        cb({})
    end
end)

-- Event rentStall
RegisterNetEvent('stall:rentStall', function(stallId, hours)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        print("^1[StallSystem] Player not found for source: " .. src .. "^7")
        return 
    end
    
    if not hours or hours <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Số giờ không hợp lệ!', 'error')
        return
    end
    
    print("^3[StallSystem] Player " .. Player.PlayerData.charinfo.firstname .. " attempting to rent stall " .. stallId .. " for " .. hours .. " hours^7")
    
    -- KIỂM TRA STALL ĐÃ CÓ NGƯỜI THUÊ CHƯA
    local isActive = IsStallActive(stallId)
    if isActive then
        TriggerClientEvent('QBCore:Notify', src, 'Gian hàng này đã có người thuê!', 'error')
        return
    end
    
    local currentStalls = CountPlayerStalls(Player.PlayerData.citizenid)
    print("^3[StallSystem] Current stalls: " .. currentStalls .. "/" .. Config.MaxStalls .. "^7")
    
    if currentStalls >= Config.MaxStalls then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn đã đạt giới hạn thuê gian hàng! (Tối đa ' .. Config.MaxStalls .. ' gian hàng)', 'error')
        return
    end
    
    local configStall = nil
    for _, stall in ipairs(Config.Stalls) do
        if stall.id == stallId then
            configStall = stall
            break
        end
    end
    if not configStall then 
        print("^1[StallSystem] Stall config not found for ID: " .. stallId .. "^7")
        TriggerClientEvent('QBCore:Notify', src, 'Gian hàng không tồn tại!', 'error')
        return 
    end
    
    local totalCost = configStall.rentPrice * hours
    
    local hasEnoughMoney = false
    if Player.PlayerData.money.bank >= totalCost then
        hasEnoughMoney = true
        Player.Functions.RemoveMoney('bank', totalCost, 'stall-rent')
    elseif Player.PlayerData.money.cash >= totalCost then
        hasEnoughMoney = true
        Player.Functions.RemoveMoney('cash', totalCost, 'stall-rent')
    end
    
    if not hasEnoughMoney then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không đủ tiền! Cần ' .. totalCost .. '$', 'error')
        return
    end
    
    -- Tạo stall với citizenid (KHÔNG có citizenid)
    local insertId = CreateStall(
        stallId, 
        Player.PlayerData.citizenid, 
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, 
        hours
    )
    print("^3[StallSystem] Create stall result: " .. tostring(insertId) .. "^7")
    if insertId then
        TriggerClientEvent('QBCore:Notify', src, 'Thuê gian hàng thành công! Bạn đã thuê ' .. hours .. ' giờ với giá ' .. totalCost .. '$', 'success')
        TriggerClientEvent('stall:refreshTargets', -1)
        print("^2[StallSystem] Stall " .. stallId .. " rented successfully by " .. Player.PlayerData.charinfo.firstname .. " (citizenid: " .. Player.PlayerData.citizenid .. ")^7")
        
        -- Gửi log thuê gian hàng qua Discord Webhook
        if Config.DiscordWebhook and Config.DiscordWebhook ~= "" then
            local startTimeStr = os.date("%Y-%m-%d %H:%M:%S")
            local endTimeStr = os.date("%Y-%m-%d %H:%M:%S", os.time() + hours * 3600)
            
            local fields = {
                { name = "Gian hàng", value = string.format("**%s** (ID: %d)", configStall.name or "Gian hàng", stallId), inline = true },
                { name = "Người thuê", value = string.format("%s (%s)", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, Player.PlayerData.citizenid), inline = true },
                { name = "Số giờ thuê", value = tostring(hours) .. " giờ", inline = true },
                { name = "Chi phí thuê", value = string.format("Đơn giá: %d$/giờ\nTổng thanh toán: %d$", configStall.rentPrice, totalCost), inline = true },
                { name = "Thời hạn thuê", value = string.format("Bắt đầu: %s\nHết hạn: %s", startTimeStr, endTimeStr), inline = false }
            }
            
            local embed = {
                {
                    title = "🟢 THUÊ GIAN HÀNG THÀNH CÔNG (STALL RENTED)",
                    color = 3066993, -- Màu xanh lá cây
                    fields = fields,
                    footer = { text = "Stall System Log" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
            
            PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers)
                if err ~= 200 and err ~= 204 then
                    print("^1[StallSystem] Discord Rent Webhook Error: " .. tostring(err) .. " - Response: " .. tostring(text) .. "^7")
                else
                    print("^2[StallSystem] Discord Rent Webhook sent successfully!^7")
                end
            end, 'POST', json.encode({username = "Stall System Bot", embeds = embed}), { ['Content-Type'] = 'application/json' })
        end
    else
        Player.Functions.AddMoney('bank', totalCost, 'stall-rent-refund')
        TriggerClientEvent('QBCore:Notify', src, 'Có lỗi xảy ra, vui lòng thử lại! Tiền đã được hoàn.', 'error')
        print("^1[StallSystem] Failed to create stall record for stall " .. stallId .. "^7")
    end
end)

-- Gia hạn gian hàng
RegisterNetEvent('stall:renewStall', function(stallId, hours)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        print("^1[StallSystem] Player not found for source: " .. src .. "^7")
        return
    end
    
    if not hours or hours <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Số giờ không hợp lệ!', 'error')
        return
    end
    
    local stallData = GetStallData(stallId)
    if not stallData then
        TriggerClientEvent('QBCore:Notify', src, 'Gian hàng không tồn tại hoặc đã hết hạn!', 'error')
        return
    end
    
    if stallData.citizenid ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không phải chủ gian hàng này!', 'error')
        return
    end
    
    local configStall = nil
    for _, stall in ipairs(Config.Stalls) do
        if stall.id == stallId then
            configStall = stall
            break
        end
    end
    if not configStall then
        TriggerClientEvent('QBCore:Notify', src, 'Gian hàng không tồn tại!', 'error')
        return
    end
    
    local totalCost = configStall.rentPrice * hours
    
    local hasEnoughMoney = false
    if Player.PlayerData.money.bank >= totalCost then
        hasEnoughMoney = true
        Player.Functions.RemoveMoney('bank', totalCost, 'stall-renew')
    elseif Player.PlayerData.money.cash >= totalCost then
        hasEnoughMoney = true
        Player.Functions.RemoveMoney('cash', totalCost, 'stall-renew')
    end
    
    if not hasEnoughMoney then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không đủ tiền! Cần ' .. totalCost .. '$', 'error')
        return
    end
    
    local success = RenewStall(stallId, Player.PlayerData.citizenid, hours)
    
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Gia hạn gian hàng thành công! Thêm ' .. hours .. ' giờ với giá ' .. totalCost .. '$', 'success')
        TriggerClientEvent('stall:refreshTargets', -1)
        
        -- Gửi log gia hạn gian hàng qua Discord Webhook
        if Config.DiscordWebhook and Config.DiscordWebhook ~= "" then
            local newEndTimeStr = os.date("%Y-%m-%d %H:%M:%S", os.time() + hours * 3600)
            
            local fields = {
                { name = "Gian hàng", value = string.format("**%s** (ID: %d)", configStall.name or "Gian hàng", stallId), inline = true },
                { name = "Người gia hạn", value = string.format("%s (%s)", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, Player.PlayerData.citizenid), inline = true },
                { name = "Số giờ gia hạn thêm", value = tostring(hours) .. " giờ", inline = true },
                { name = "Chi phí gia hạn", value = string.format("Đơn giá: %d$/giờ\nTổng thanh toán: %d$", configStall.rentPrice, totalCost), inline = true },
                { name = "Thời hạn hết hạn mới", value = newEndTimeStr, inline = false }
            }
            
            local embed = {
                {
                    title = "🔵 GIA HẠN GIAN HÀNG THÀNH CÔNG (STALL RENEWED)",
                    color = 3447003, -- Màu xanh dương
                    fields = fields,
                    footer = { text = "Stall System Log" },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
            
            PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers)
                if err ~= 200 and err ~= 204 then
                    print("^1[StallSystem] Discord Renew Webhook Error: " .. tostring(err) .. " - Response: " .. tostring(text) .. "^7")
                else
                    print("^2[StallSystem] Discord Renew Webhook sent successfully!^7")
                end
            end, 'POST', json.encode({username = "Stall System Bot", embeds = embed}), { ['Content-Type'] = 'application/json' })
        end
    else
        Player.Functions.AddMoney('bank', totalCost, 'stall-renew-refund')
        TriggerClientEvent('QBCore:Notify', src, 'Có lỗi xảy ra, vui lòng thử lại! Tiền đã được hoàn.', 'error')
    end
end)

-- Mua item từ gian hàng
RegisterNetEvent('stall:buyItem', function(stallId, itemIndex, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        print("^1[StallSystem] Player not found for source: " .. src .. "^7")
        return 
    end
    
    -- Thử khóa gian hàng tránh spam mua đồ cùng lúc gây mất đồ
    if not LockStall(stallId) then
        TriggerClientEvent('QBCore:Notify', src, 'Hệ thống đang xử lý một giao dịch khác tại gian hàng này, vui lòng thử lại sau!', 'error')
        return
    end

    local function executeBuyItem()
        print("^3[StallSystem] Buy item - Stall: " .. stallId .. ", Index: " .. itemIndex .. ", Quantity: " .. quantity .. "^7")
        
        local stallData = GetStallData(stallId)
        if not stallData then
            TriggerClientEvent('QBCore:Notify', src, 'Gian hàng không tồn tại hoặc đã hết hạn!', 'error')
            return false
        end
        
        local items = stallData.items or {}
        
        -- Debug: In ra danh sách items
        print("^3[StallSystem] Total items in stall: " .. #items)
        for i, item in ipairs(items) do
            print("  [" .. i .. "] " .. item.name .. " x" .. item.count .. " - Price: " .. item.price)
        end
        
        -- Kiểm tra itemIndex hợp lệ
        if not items[itemIndex] then
            print("^1[StallSystem] Item not found at index: " .. itemIndex .. "^7")
            TriggerClientEvent('QBCore:Notify', src, 'Vật phẩm không tồn tại trong gian hàng!', 'error')
            return false
        end
        
        local itemData = items[itemIndex]
        print("^3[StallSystem] Selected item: " .. itemData.name .. " x" .. itemData.count .. " - Price: " .. itemData.price .. "^7")
        
        if itemData.count < quantity then
            TriggerClientEvent('QBCore:Notify', src, 'Số lượng không đủ! Chỉ còn ' .. itemData.count .. ' cái', 'error')
            return false
        end
        
        local pricePerUnit = itemData.price or 100
        local subtotal = pricePerUnit * quantity
        local tax = math.floor(subtotal * Config.TaxRate)
        local totalPrice = subtotal + tax
        
        -- Kiểm tra tiền
        local hasEnoughMoney = false
        if Player.PlayerData.money.bank >= totalPrice then
            hasEnoughMoney = true
            Player.Functions.RemoveMoney('bank', totalPrice, 'stall-buy')
        elseif Player.PlayerData.money.cash >= totalPrice then
            hasEnoughMoney = true
            Player.Functions.RemoveMoney('cash', totalPrice, 'stall-buy')
        end
        
        if not hasEnoughMoney then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không đủ tiền! Cần ' .. totalPrice .. '$', 'error')
            return false
        end
        
        -- Lấy metadata
        local itemMetadata = itemData.metadata or {}
        local itemName = itemData.name or 'unknown'
        local itemLabel = itemMetadata.label or itemName
        
        -- Cập nhật số lượng - GIỮ NGUYÊN CÁC ITEM KHÁC
        local updatedItems = {}
        for i, item in ipairs(items) do
            if i == itemIndex then
                -- Giảm số lượng item được mua
                local newCount = item.count - quantity
                if newCount > 0 then
                    -- Vẫn giữ item nếu còn số lượng
                    local newItem = {
                        name = item.name,
                        count = newCount,
                        price = item.price,
                        metadata = item.metadata
                    }
                    table.insert(updatedItems, newItem)
                    print("^3[StallSystem] Updated item " .. item.name .. " new count: " .. newCount .. "^7")
                else
                    print("^3[StallSystem] Removed item " .. item.name .. " (count: 0)^7")
                end
            else
                -- giữ nguyên các item khác
                table.insert(updatedItems, {
                    name = item.name,
                    count = item.count,
                    price = item.price,
                    metadata = item.metadata
                })
            end
        end
        
        print("^3[StallSystem] Updated items count: " .. #updatedItems .. "^7")
        
        local success = UpdateStallItems(stallData.id, updatedItems)
        if not success then
            Player.Functions.AddMoney('bank', totalPrice, 'stall-buy-refund')
            TriggerClientEvent('QBCore:Notify', src, 'Có lỗi xảy ra! Tiền đã được hoàn.', 'error')
            return false
        end
        
        -- Thêm item cho người mua với TOÀN BỘ metadata
        print("^3[StallSystem] Adding item to player inventory: " .. itemName .. " x" .. quantity .. " with metadata: " .. json.encode(itemMetadata or {}) .. "^7")
        exports.ox_inventory:AddItem(src, itemName, quantity, itemMetadata)
        
        -- Cập nhật doanh thu
        UpdateStallRevenue(stallId, subtotal, subtotal)
        
        -- Thêm lịch sử giao dịch
        AddTransaction(
            stallData.id,
            stallData.citizenid,
            Player.PlayerData.citizenid,
            Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            itemName,
            itemLabel,
            itemMetadata,
            quantity,
            pricePerUnit,
            subtotal,
            tax
        )
        
        local ownerPlayer = QBCore.Functions.GetPlayerByCitizenId(stallData.citizenid)
        if ownerPlayer then
            TriggerClientEvent('QBCore:Notify', ownerPlayer.PlayerData.source, 
                '🛒 ' .. Player.PlayerData.charinfo.firstname .. ' đã mua ' .. quantity .. 'x ' .. itemLabel .. ' từ gian hàng của bạn! (+' .. subtotal .. '$)', 
                'success')
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'Mua hàng thành công! Bạn đã mua ' .. quantity .. 'x ' .. itemLabel .. ' với giá ' .. totalPrice .. '$', 'success')
        TriggerClientEvent('stall:refreshTargets', -1)
        return true
    end

    executeBuyItem()
    UnlockStall(stallId) -- Chắc chắn giải phóng khóa sau khi kết thúc
end)

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
-- Thêm item vào gian hàng
RegisterNetEvent('stall:addItem', function(stallId, itemName, price, quantity, itemMetadata, slot, clientItemLabel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        print("^1[StallSystem] Player not found for source: " .. src .. "^7")
        return 
    end

    -- Kiểm tra vật phẩm có bị cấm bán không
    if Config.BlacklistItems and Config.BlacklistItems[itemName] then
        TriggerClientEvent('QBCore:Notify', src, 'Vật phẩm này không được phép bán!', 'error')
        return
    end

    -- Kiểm tra giá bán tối đa
    if not price or price <= 0 or price > 9999999 then
        TriggerClientEvent('QBCore:Notify', src, 'Giá bán không hợp lệ (Tối đa 9,999,999$!)', 'error')
        return
    end
    
    -- Thử khóa gian hàng tránh spam đăng bán cùng lúc gây mất đồ
    if not LockStall(stallId) then
        TriggerClientEvent('QBCore:Notify', src, 'Hệ thống đang xử lý một giao dịch khác tại gian hàng này, vui lòng thử lại sau!', 'error')
        return
    end

    local function executeAddItem()
        local stallData = GetStallData(stallId)
        if not stallData then
            TriggerClientEvent('QBCore:Notify', src, 'Gian hàng không tồn tại!', 'error')
            return false
        end
        if stallData.citizenid ~= Player.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không phải chủ gian hàng này!', 'error')
            return false
        end
        
        print("^3[StallSystem] ===== ADD ITEM =====^7")
        print("^3[StallSystem] Item name: " .. itemName .. "^7")
        print("^3[StallSystem] Quantity: " .. quantity .. "^7")
        print("^3[StallSystem] Price: " .. price .. "^7")
        print("^3[StallSystem] Slot to remove: " .. (slot or "N/A") .. "^7")
        print("^3[StallSystem] Received Metadata: " .. json.encode(itemMetadata or {}) .. "^7")
        
        -- REMOVE ITEM ĐÚNG SLOT BẰNG OX_INVENTORY
        local removed = false
        local targetItem = nil
        local originalMetadata = nil
        
        if slot then
            -- Sử dụng ox_inventory:GetSlot để lấy item theo slot
            targetItem = exports.ox_inventory:GetSlot(src, slot)
            
            if targetItem then
                print("^3[StallSystem] Found item in slot " .. slot .. ": " .. targetItem.name .. " x" .. targetItem.count .. "^7")
                print("^3[StallSystem] Item metadata: " .. json.encode(targetItem.metadata or {}) .. "^7")
                
                -- Lưu metadata gốc của item
                originalMetadata = targetItem.metadata or {}
                
                -- Kiểm tra tên item khớp
                if targetItem.name == itemName then
                    -- Kiểm tra số lượng đủ
                    if targetItem.count >= quantity then
                        -- Remove item bằng ox_inventory với metadata gốc và chỉ định đúng slot
                        if originalMetadata and next(originalMetadata) then
                            removed = exports.ox_inventory:RemoveItem(src, itemName, quantity, originalMetadata, slot)
                        else
                            removed = exports.ox_inventory:RemoveItem(src, itemName, quantity, nil, slot)
                        end
                        
                        if removed then
                            print("^2[StallSystem] Successfully removed " .. quantity .. "x " .. itemName .. " from slot: " .. slot .. "^7")
                        else
                            print("^1[StallSystem] Failed to remove item from slot: " .. slot .. "^7")
                        end
                    else
                        print("^1[StallSystem] Not enough quantity in slot " .. slot .. ": have " .. targetItem.count .. ", need " .. quantity .. "^7")
                        TriggerClientEvent('QBCore:Notify', src, 'Không đủ số lượng trong slot này!', 'error')
                        return false
                    end
                else
                    print("^1[StallSystem] Item name mismatch in slot " .. slot .. ": expected " .. itemName .. ", got " .. targetItem.name .. "^7")
                    TriggerClientEvent('QBCore:Notify', src, 'Vật phẩm trong slot không khớp!', 'error')
                    return false
                end
            else
                print("^1[StallSystem] No item found in slot: " .. slot .. "^7")
                TriggerClientEvent('QBCore:Notify', src, 'Không tìm thấy vật phẩm trong slot này!', 'error')
                return false
            end
        else
            -- Nếu không có slot, thử tìm theo metadata (fallback)
            print("^3[StallSystem] No slot provided, trying to find by metadata...^7")
            
            local inventory = exports.ox_inventory:GetInventory(src)
            if inventory then
                for _, item in ipairs(inventory) do
                    if item.name == itemName then
                        local invMetadata = item.metadata or {}
                        
                        -- Kiểm tra metadata match
                        local matchCount = 0
                        local totalCheck = 0
                        local importantFields = {'drawable', 'type', 'sex', 'id', 'texture', 'label', 'DoHiem', 'durability'}
                        
                        for _, field in ipairs(importantFields) do
                            local clientVal = itemMetadata[field]
                            local invVal = invMetadata[field]
                            
                            if clientVal ~= nil and clientVal ~= '' then
                                totalCheck = totalCheck + 1
                                if invVal ~= nil and invVal ~= '' and tostring(invVal) == tostring(clientVal) then
                                    matchCount = matchCount + 1
                                end
                            end
                        end
                        
                        local matchPercentage = totalCheck > 0 and (matchCount / totalCheck) or 0
                        print("^3[StallSystem] Item match percentage: " .. (matchPercentage * 100) .. "% (" .. matchCount .. "/" .. totalCheck .. ")")
                        
                        if matchPercentage >= 0.5 or totalCheck == 0 then
                            if item.count >= quantity then
                                originalMetadata = item.metadata or {}
                                if originalMetadata and next(originalMetadata) then
                                    removed = exports.ox_inventory:RemoveItem(src, itemName, quantity, originalMetadata, item.slot)
                                else
                                    removed = exports.ox_inventory:RemoveItem(src, itemName, quantity, nil, item.slot)
                                end
                                if removed then
                                    print("^2[StallSystem] Successfully removed item with metadata from slot: " .. (item.slot or "N/A") .. "^7")
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Nếu vẫn chưa remove được, thử remove item đầu tiên cùng tên và chỉ định slot của nó
        if not removed then
            print("^3[StallSystem] Still not removed, trying to remove first item with same name^7")
            -- Lấy inventory để lấy metadata và slot
            local targetSlot = nil
            local inventory = exports.ox_inventory:GetInventory(src)
            if inventory then
                for _, item in ipairs(inventory) do
                    if item.name == itemName then
                        originalMetadata = item.metadata or {}
                        targetSlot = item.slot
                        break
                    end
                end
            end
            
            if targetSlot then
                removed = exports.ox_inventory:RemoveItem(src, itemName, quantity, originalMetadata, targetSlot)
            else
                removed = exports.ox_inventory:RemoveItem(src, itemName, quantity)
            end
            
            if removed then
                print("^2[StallSystem] Successfully removed first item with same name from slot: " .. (targetSlot or "N/A") .. "^7")
            end
        end
        
        if not removed then
            TriggerClientEvent('QBCore:Notify', src, 'Có lỗi khi lấy vật phẩm từ túi đồ! Vui lòng thử lại.', 'error')
            return false
        end
        
        -- Lấy items hiện có
        local items = GetStallItems(stallData.id)
        
        -- Kiểm tra số slot
        if #items >= Config.MaxSlots then
            -- Trả lại item cho người chơi với metadata gốc
            if originalMetadata and next(originalMetadata) then
                exports.ox_inventory:AddItem(src, itemName, quantity, originalMetadata)
            else
                exports.ox_inventory:AddItem(src, itemName, quantity)
            end
            TriggerClientEvent('QBCore:Notify', src, 'Gian hàng đã đầy! Tối đa ' .. Config.MaxSlots .. ' vật phẩm', 'error')
            return false
        end
        
        -- XỬ LÝ METADATA - CHỈ LƯU NẾU CÓ DỮ LIỆU (KHÔNG BAO GỒM LABEL)
        local finalMetadata = {}
        
        -- Ưu tiên dùng metadata gốc từ item (nếu có)
        if originalMetadata and next(originalMetadata) then
            for k, v in pairs(originalMetadata) do
                -- Bỏ qua label vì sẽ lưu riêng vào cột item_label
                if k ~= 'label' and v ~= nil and v ~= '' then
                    finalMetadata[k] = v
                end
            end
        end
        
        -- Nếu không có metadata gốc, dùng metadata từ client (nếu có)
        if not next(finalMetadata) and itemMetadata and next(itemMetadata) then
            for k, v in pairs(itemMetadata) do
                -- Bỏ qua label vì sẽ lưu riêng vào cột item_label
                if k ~= 'label' and v ~= nil and v ~= '' then
                    finalMetadata[k] = v
                end
            end
        end
        
        -- KIỂM TRA NẾU KHÔNG CÓ METADATA -> ĐỂ RỖNG
        local hasMetadata = next(finalMetadata)
        print("^3[StallSystem] Has metadata: " .. tostring(hasMetadata) .. "^7")
        print("^3[StallSystem] Final Metadata: " .. json.encode(finalMetadata) .. "^7")
        
        -- Lấy label đúng từ ox_inventory hoặc client để hiển thị và lưu vào item_label
        local itemLabel = clientItemLabel or GetItemLabelFromOx(itemName) or itemName
        print("^3[StallSystem] Item Label: " .. itemLabel .. "^7")
        
        -- KIỂM TRA ITEM ĐÃ TỒN TẠI CHƯA (tránh trùng lặp)
        local existingIndex = nil
        for i, existingItem in ipairs(items) do
            -- So sánh name và metadata
            if existingItem.name == itemName then
                local existingMeta = existingItem.metadata or {}
                
                -- Kiểm tra các field quan trọng (chỉ khi có metadata)
                local isSame = true
                if hasMetadata then
                    local checkFields = {'drawable', 'texture', 'type', 'sex', 'id', 'durability'}
                    for _, field in ipairs(checkFields) do
                        local existingVal = existingMeta[field]
                        local newVal = finalMetadata[field]
                        
                        -- So sánh giá trị (chuyển về string để so sánh)
                        if newVal ~= nil and newVal ~= '' then
                            if tostring(existingVal) ~= tostring(newVal) then
                                isSame = false
                                break
                            end
                        end
                    end
                else
                    -- Nếu không có metadata, kiểm tra existing item cũng không có metadata
                    if next(existingMeta) then
                        isSame = false
                    end
                end
                
                if isSame then
                    existingIndex = i
                    break
                end
            end
        end
        
        if existingIndex then
            -- Cập nhật số lượng item đã tồn tại
            items[existingIndex].count = items[existingIndex].count + quantity
            -- Cập nhật giá mới nếu cần
            items[existingIndex].price = price
            -- Cập nhật label đúng
            items[existingIndex].label = itemLabel
            -- Cập nhật metadata mới (gộp metadata) - CHỈ GỘP NẾU CÓ DỮ LIỆU
            if hasMetadata then
                local mergedMetadata = {}
                for k, v in pairs(items[existingIndex].metadata) do
                    if k ~= 'label' then
                        mergedMetadata[k] = v
                    end
                end
                for k, v in pairs(finalMetadata) do
                    if v ~= nil and v ~= '' then
                        mergedMetadata[k] = v
                    end
                end
                items[existingIndex].metadata = mergedMetadata
            else
                -- Nếu không có metadata, giữ nguyên metadata cũ hoặc để rỗng
                if not next(items[existingIndex].metadata) then
                    items[existingIndex].metadata = {}
                end
            end
            print("^3[StallSystem] Updated existing item: " .. itemName .. " new count: " .. items[existingIndex].count .. "^7")
        else
            -- Tạo item mới với metadata (có thể rỗng)
            local newItem = {
                name = itemName,
                label = itemLabel,
                count = quantity,
                price = price,
                metadata = finalMetadata
            }
            table.insert(items, newItem)
            print("^3[StallSystem] Added new item: " .. itemName .. " x" .. quantity .. "^7")
            print("^3[StallSystem] Metadata saved: " .. json.encode(finalMetadata) .. "^7")
        end
        
        local success = UpdateStallItems(stallData.id, items)
        if success then
            TriggerClientEvent('QBCore:Notify', src, 'Đã thêm ' .. quantity .. 'x ' .. itemLabel .. ' vào gian hàng với giá ' .. price .. '$/cái', 'success')
            TriggerClientEvent('stall:updateAllClients', -1)
            
            -- Gửi log đăng bán qua Discord Webhook
            if Config.AddItemWebhook and Config.AddItemWebhook ~= "" then
                local rentEnd = stallData.rent_end
                local endStr = rentEnd and os.date("%Y-%m-%d %H:%M:%S", rentEnd) or "Không rõ"
                local remainingSecs = rentEnd and (rentEnd - os.time()) or 0
                local remainingStr = "Đã hết hạn"
                if remainingSecs > 0 then
                    local hrs = math.floor(remainingSecs / 3600)
                    local mins = math.floor((remainingSecs % 3600) / 60)
                    remainingStr = string.format("%d giờ %d phút", hrs, mins)
                end

                local fields = {
                    { name = "Gian hàng ID", value = tostring(stallId), inline = true },
                    { name = "Người đăng bán", value = string.format("%s (%s)", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, Player.PlayerData.citizenid), inline = true },
                    { name = "Thời hạn thuê còn lại", value = string.format("%s\n(Hết hạn: %s)", remainingStr, endStr), inline = true },
                    { name = "Vật phẩm", value = string.format("%s (`%s`)", itemLabel, itemName), inline = true },
                    { name = "Số lượng", value = tostring(quantity), inline = true },
                    { name = "Giá bán / cái", value = price .. "$", inline = true },
                    { name = "Tổng giá trị", value = (price * quantity) .. "$", inline = true }
                }
                
                -- metadata
                local metaText = "Không có"
                if finalMetadata and next(finalMetadata) then
                    metaText = json.encode(finalMetadata)
                    if #metaText > 1024 then
                        metaText = string.sub(metaText, 1, 1021) .. "..."
                    end
                end
                table.insert(fields, { name = "Metadata", value = "`" .. metaText .. "`", inline = false })
                
                local embed = {
                    {
                        title = "🟢 ĐĂNG BÁN VẬT PHẨM (ITEM LISTED)",
                        color = 3066993, -- Màu xanh lá cây
                        fields = fields,
                        footer = { text = "Stall System Log" },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                    }
                }
                
                PerformHttpRequest(Config.AddItemWebhook, function(err, text, headers)
                    if err ~= 200 and err ~= 204 then
                        print("^1[StallSystem] Discord AddItem Webhook Error: " .. tostring(err) .. " - Response: " .. tostring(text) .. "^7")
                    end
                end, 'POST', json.encode({username = "Stall System Bot", embeds = embed}), { ['Content-Type'] = 'application/json' })
            end
        else
            -- Trả lại item nếu lưu thất bại
            if originalMetadata and next(originalMetadata) then
                exports.ox_inventory:AddItem(src, itemName, quantity, originalMetadata)
            else
                exports.ox_inventory:AddItem(src, itemName, quantity)
            end
            TriggerClientEvent('QBCore:Notify', src, 'Có lỗi xảy ra, vật phẩm đã được hoàn trả!', 'error')
        end
        return success
    end

    executeAddItem()
    UnlockStall(stallId) -- Chắc chắn giải phóng khóa sau khi kết thúc
end)

-- Rút item khỏi gian hàng
RegisterNetEvent('stall:removeItem', function(stallId, itemIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Thử khóa gian hàng tránh spam hủy bán cùng lúc gây mất đồ
    if not LockStall(stallId) then
        TriggerClientEvent('QBCore:Notify', src, 'Hệ thống đang xử lý một giao dịch khác tại gian hàng này, vui lòng thử lại sau!', 'error')
        return
    end

    local function executeRemoveItem()
        local stallData = GetStallData(stallId)
        if not stallData then
            TriggerClientEvent('QBCore:Notify', src, 'Gian hàng không tồn tại hoặc đã hết hạn!', 'error')
            return false
        end
        
        if stallData.citizenid ~= Player.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không phải chủ gian hàng này!', 'error')
            return false
        end
        
        local items = stallData.items or {}
        if not items[itemIndex] then
            TriggerClientEvent('QBCore:Notify', src, 'Vật phẩm không tồn tại!', 'error')
            return false
        end
        
        local itemData = items[itemIndex]
        local quantity = itemData.count
        local itemName = itemData.name
        local metadata = itemData.metadata or {}
        
        -- Kiểm tra có thể thêm vào inventory không
        local canAdd = exports.ox_inventory:CanCarryItem(src, itemName, quantity)
        if not canAdd then
            TriggerClientEvent('QBCore:Notify', src, 'Bạn không đủ chỗ trong túi đồ!', 'error')
            return false
        end
        
        -- Thêm lại vào inventory với metadata gốc
        if metadata and next(metadata) then
            exports.ox_inventory:AddItem(src, itemName, quantity, metadata)
        else
            exports.ox_inventory:AddItem(src, itemName, quantity)
        end
        
        -- Xóa khỏi stall
        local updatedItems = {}
        for i, item in ipairs(items) do
            if i ~= itemIndex then
                table.insert(updatedItems, {
                    name = item.name,
                    count = item.count,
                    price = item.price,
                    metadata = item.metadata
                })
            end
        end
        
        local success = UpdateStallItems(stallData.id, updatedItems)
        if success then
            local itemLabel = metadata.label or itemName
            TriggerClientEvent('QBCore:Notify', src, 'Đã rút ' .. quantity .. 'x ' .. itemLabel .. ' khỏi gian hàng!', 'success')
            TriggerClientEvent('stall:refreshTargets', -1)
        end
        return success
    end

    executeRemoveItem()
    UnlockStall(stallId) -- Chắc chắn giải phóng khóa sau khi kết thúc
end)

-- Nhận tiền chưa nhận
RegisterNetEvent('stall:withdrawMoney', function(stallId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local stallData = GetStallData(stallId)
    if not stallData then return end
    
    if stallData.citizenid ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không phải chủ gian hàng này!', 'error')
        return
    end
    
    local amount = WithdrawUnclaimedMoney(stallId, Player.PlayerData.citizenid)
    
    if amount > 0 then
        Player.Functions.AddMoney('bank', amount, 'stall-revenue')
        TriggerClientEvent('QBCore:Notify', src, 'Đã nhận ' .. amount .. '$ từ doanh thu gian hàng!', 'success')
        TriggerClientEvent('stall:refreshTargets', -1)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Không có tiền để nhận!', 'error')
    end
end)

-- LỆNH TEST: Kết thúc thời gian thuê ngay lập tức
local function HandleForceEndStall(source, args)
    if source == 0 then
        print("^1[StallSystem] This command must be used in-game^7")
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not args[1] then
        TriggerClientEvent('QBCore:Notify', source, '⚠️ Sử dụng lệnh kèm theo Stall ID!', 'error')
        return
    end
    
    local stallId = tonumber(args[1])
    if not stallId then
        TriggerClientEvent('QBCore:Notify', source, '⚠️ Stall ID phải là số!', 'error')
        return
    end
    
    -- Kiểm tra stall có tồn tại không
    local stallData = GetStallDataRaw(stallId)
    if not stallData then
        TriggerClientEvent('QBCore:Notify', source, '⚠️ Không tìm thấy gian hàng ' .. stallId .. ' đang hoạt động!', 'error')
        return
    end
    
    -- Kiểm tra quyền (Admin hoặc Chủ gian hàng)
    local hasPermission = false
    local playerGroup = Player.PlayerData.group or 'user'
    for _, group in ipairs(Config.AdminGroups) do
        if playerGroup == group then
            hasPermission = true
            break
        end
    end
    
    local isOwner = (stallData.citizenid == Player.PlayerData.citizenid)
    
    if not hasPermission and not isOwner then
        TriggerClientEvent('QBCore:Notify', source, '⚠️ Bạn không có quyền kết thúc gian hàng này!', 'error')
        return
    end
    
    print("^3[StallSystem] Force ending stall " .. stallId .. " by " .. Player.PlayerData.charinfo.firstname .. "^7")
    
    -- Force expire stall
    local success = ForceExpireStall(stallId)
    
    if success then
        WarningSent30Min[stallId] = nil
        TriggerClientEvent('QBCore:Notify', source, '✅ Đã kết thúc thời gian thuê của gian hàng ' .. stallId .. '!', 'success')
        TriggerClientEvent('stall:refreshTargets', -1)
    else
        TriggerClientEvent('QBCore:Notify', source, '❌ Có lỗi xảy ra khi kết thúc gian hàng!', 'error')
    end
end

-- RegisterCommand('endstall', HandleForceEndStall, false)
-- RegisterCommand('ketthuc', HandleForceEndStall, false)

-- Check hết hạn gian hàng
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10 * 60 * 1000) -- Kiểm tra 10 phút / 1 lần
        for _, stall in ipairs(Config.Stalls) do
            local stallData = GetStallDataRaw(stall.id)
            if stallData and stallData.rent_end then
                local endTime = nil
                if type(stallData.rent_end) == 'number' then
                    if stallData.rent_end > 9999999999 then
                        endTime = math.floor(stallData.rent_end / 1000)
                    else
                        endTime = stallData.rent_end
                    end
                elseif type(stallData.rent_end) == 'string' then
                    -- Hỗ trợ phân tích chuỗi linh hoạt hơn (cả định dạng khoảng trắng và định dạng chữ T)
                    local year, month, day, hour, min, sec = string.match(stallData.rent_end, "(%d+)-(%d+)-(%d+)[ T](%d+):(%d+):(%d+)")
                    if year and month and day and hour and min and sec then
                        endTime = os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
                    end
                end
                
                if endTime then
                    local nowTime = os.time()
                    local remaining = endTime - nowTime
                    
                    -- Cảnh báo trước 30 phút (1800 giây)
                    if remaining > 0 and remaining <= 1800 then
                        if not WarningSent30Min[stall.id] then
                            WarningSent30Min[stall.id] = true
                            local ownerPlayer = QBCore.Functions.GetPlayerByCitizenId(stallData.citizenid)
                            if ownerPlayer then
                                TriggerClientEvent('QBCore:Notify', ownerPlayer.PlayerData.source, 
                                    '⚠️ Gian hàng "' .. (stallData.owner_name or stall.name) .. '" của bạn chỉ còn lại 30 phút thuê! Vui lòng gia hạn hoặc thu dọn đồ.', 
                                    'warning', 10000)
                            end
                            print("^3[StallSystem] Warning: Stall " .. stall.id .. " only has " .. math.floor(remaining / 60) .. " minutes remaining. Owner notified.^7")
                        end
                    elseif remaining > 1800 then
                        -- Reset cảnh báo nếu được gia hạn qua mốc 30 phút
                        WarningSent30Min[stall.id] = nil
                    end

                    -- Khi hết hạn
                    if remaining <= 0 then
                        print("^3[StallSystem] Stall " .. stall.id .. " has expired. Owner: " .. (stallData.owner_name or "Unknown") .. "^7")
                        
                        local ownerPlayer = QBCore.Functions.GetPlayerByCitizenId(stallData.citizenid)
                        if ownerPlayer then
                            TriggerClientEvent('QBCore:Notify', ownerPlayer.PlayerData.source, 
                                '⏰ Gian hàng "' .. (stall.name or "của bạn") .. '" đã hết hạn thuê!', 
                                'error', 10000)
                            TriggerClientEvent('stall:closeUI', ownerPlayer.PlayerData.source)
                        end
                        
                        -- Reset warning cache
                        WarningSent30Min[stall.id] = nil
                        
                        -- Xóa stall và lịch sử
                        ForceExpireStall(stall.id)
                        TriggerClientEvent('stall:refreshTargets', -1)
                    end
                end
            end
        end
    end
end)