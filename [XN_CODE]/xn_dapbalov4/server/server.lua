local ITEM_TARGET_UP = {}
local PENDING_UPGRADE = {}

local RateData = 0

local function GenerateText(len)
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local result = ''
    for i = 1, len do
        local idx = math.random(1, #charset)
        result = result .. charset:sub(idx, idx)
    end
    return result
end

local function GenerateSerial(text)
    if text and text:len() > 3 then
        return text
    end
    -- Lấy ngày tháng năm và giờ phút giây
    local date = os.date("%d%m%y")
    local time = os.date("%H%M%S")
    local letters = text == nil and GenerateText(3) or text
    return ('%s%s%s'):format(date, letters, time)
end

local function SendDiscordLog(title, message, color)
    local webhook = Config.DiscordWebhook
    if not webhook or webhook == "" then return end
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        embeds = {{
            title = title,
            description = message,
            color = color or 3447003,
            footer = { text = os.date("%d/%m/%Y %H:%M:%S") }
        }}
    }), { ['Content-Type'] = 'application/json' })
end

local function DebugPrint(...)
    if not Config or not Config.debug then
        return
    end

    print(...)
end

-- ====================== PITY RATE HELPERS ======================
local function GetPityRate(levelConfig)
    if not levelConfig or not levelConfig.pity_rate then return nil end
    if type(levelConfig.pity_rate) == 'number' then
        return levelConfig.pity_rate, levelConfig.pity_rate
    end
    if type(levelConfig.pity_rate) ~= 'table' then return nil end
    local lo = tonumber(levelConfig.pity_rate[1])
    local hi = tonumber(levelConfig.pity_rate[2])
    if not lo or not hi then return nil end
    if hi < lo then lo, hi = hi, lo end
    return lo, hi
end

local function RollPityRate(levelConfig)
    local lo, hi = GetPityRate(levelConfig)
    if not lo then return nil end
    return math.random(lo, hi)
end

-- Merge pity fields vào metadata của slot hiện tại mà không làm mất metadata khác
local function UpdateItemPityMetadata(source, slot, pityrate, pitynum)
    local cur = exports.ox_inventory:GetSlot(source, slot)
    if not cur then return false end
    local merged = {}
    if cur.metadata then
        for k, v in pairs(cur.metadata) do merged[k] = v end
    end
    merged.pityrate = pityrate
    merged.pitynum = pitynum
    exports.ox_inventory:SetMetadata(source, slot, merged)
    return true
end

-- Gán pity metadata cho item lv mới (sau khi nâng cấp thành công)
local function BuildNewItemPityMetadata(metadata, nextLevelConfig)
    metadata.pityrate = nil
    metadata.pitynum = nil
    if nextLevelConfig and nextLevelConfig.pity_rate then
        local newRate = RollPityRate(nextLevelConfig)
        if newRate then
            metadata.pityrate = newRate
            metadata.pitynum = 0
        end
    end
    return metadata
end

-- Hàm chuyển đổi Capdo sang DoHiem
local function GetDoHiemByCapdo(capdo)
    local capdoToRarity = {
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary"
    }
    return capdoToRarity[capdo] or "Common"
end

-- Hàm phân tích stackable item:
-- fishingrod -> {baseName = "fishingrod", level = 1}
-- fishingrod1 -> {baseName = "fishingrod", level = 1}
-- fishingrod2 -> {baseName = "fishingrod", level = 2}
local function ParseStackableItem(itemName)
    for baseName, mapping in pairs(Config.componentMapping) do
        if mapping.isStackable and mapping.type == 'item' then
            -- Kiểm tra xem itemName có khớp chính xác baseName không (fishingrod = level 1)
            if itemName == baseName then
                return {
                    baseName = baseName,
                    level = 1
                }
            end
            -- Kiểm tra xem itemName có bắt đầu bằng baseName và kết thúc bằng số không
            local pattern = "^" .. baseName .. "(%d+)$"
            local levelStr = string.match(itemName, pattern)
            if levelStr then
                return {
                    baseName = baseName,
                    level = tonumber(levelStr)
                }
            end
        end
    end
    return nil
end

local function CheckRequiredLevelItem(itemTarget, itemsList)
    if not itemTarget then return false end
    
    local stackableInfo = ParseStackableItem(itemTarget.name)
    local baseName = stackableInfo and stackableInfo.baseName or itemTarget.name
    local currentCapdo = stackableInfo and stackableInfo.level or (itemTarget.metadata and tonumber(itemTarget.metadata.Capdo)) or 1
    
    local itemConfig = Config.BaloLevels[baseName]
    if not itemConfig then return true end
    
    local levelConfig = itemConfig[currentCapdo]
    if not levelConfig then return true end
    
    local requiredRarity = (levelConfig and levelConfig.hasrarity) or GetDoHiemByCapdo(currentCapdo)
    if not requiredRarity then return true end
    
    local RarityOrder = Config.RarityOrder
    local requiredLevel = (requiredRarity and RarityOrder[requiredRarity]) or currentCapdo or 1
    
    DebugPrint("Kiểm tra nguyên liệu cho " .. itemTarget.name .. " cấp " .. currentCapdo .. " (Yêu cầu rarity >= " .. tostring(requiredRarity) .. ")")
    for i, item in pairs(itemsList) do
        local doHiem = item.metadata and item.metadata.DoHiem or "Common"
        local matLevel = RarityOrder[doHiem] or (item.metadata and tonumber(item.metadata.Capdo)) or 1
        DebugPrint("- Nguyên liệu #" .. i .. ": " .. item.name .. " | DoHiem: " .. doHiem .. " | Level: " .. matLevel)
        if matLevel >= requiredLevel then
            DebugPrint("✅ Đã tìm thấy nguyên liệu phù hợp: " .. item.name .. " (" .. doHiem .. ")")
            return true
        end
    end
    
    DebugPrint("❌ Không tìm thấy nguyên liệu có rarity >= " .. tostring(requiredRarity))
    return false
end


lib.callback.register("qb-upgrade-bag:startUpgrade", function(source, listSelected)
    DebugPrint("========================================")
    DebugPrint("[SERVER] CALLBACK CALLED - qb-upgrade-bag:startUpgrade")
    DebugPrint("[SERVER] Source:", source)
    DebugPrint("[SERVER] ListSelected:", json.encode(listSelected, { indent = true }))
    DebugPrint("========================================")
    local xPlayer = exports.qbx_core:GetPlayer(source)
    local ItemTargetData = exports.ox_inventory:GetSlot(source, ITEM_TARGET_UP[source])
    if not ItemTargetData then
        return false
    end
    if ItemTargetData.name == "sleeping_bag" then
        if not ItemTargetData.metadata.durability or ItemTargetData.metadata.durability < 100 then
            exports.qbx_core:Notify(source, 'Túi ngủ đã sử dụng không thể nâng cấp', 'error')
            return false
        end
    end
    
    -- listSelected giờ là [{name, quantity, slot}] thay vì [slot1, slot2, ...]
    local itemSelectedData = {}
    for k, v in pairs(listSelected) do
        local itemData = exports.ox_inventory:GetSlot(source, v.slot)
        if not itemData then
            DebugPrint("[ERROR] Item not found in slot:", v.slot)
            return false
        end
        -- Kiểm tra số lượng có đủ không
        if itemData.count < (v.quantity or 1) then
            DebugPrint("[ERROR] Not enough items:", itemData.name, "has", itemData.count, "need", v.quantity)
            exports.qbx_core:Notify(source, 'Không đủ ' .. itemData.name, 'error')
            return false
        end
        -- Kiểm tra fromGacha cho clothing material
        local clothingConfig = Config.componentMapping[itemData.name]
        if clothingConfig and not clothingConfig.isStackable then
            if not itemData.metadata or not itemData.metadata.fromGacha then
                DebugPrint("[ERROR] Item missing fromGacha:", itemData.name)
                exports.qbx_core:Notify(source, 'Vật phẩm ' .. itemData.name .. ' không hợp lệ (thiếu fromGacha)', 'error')
                return false
            end
        end
        -- Thêm quantity vào itemData
        itemData.selectedQuantity = v.quantity or 1
        table.insert(itemSelectedData, itemData)
    end
    local hasRequiredLevel = CheckRequiredLevelItem(ItemTargetData, itemSelectedData)
    local RealRateData = 0 -- Tỷ lệ thực sự dùng để xác định thành công/thất bại
    if not hasRequiredLevel then
        RateData = 0
        RealRateData = 0
    else
        -- Chuyển đổi itemSelectedData thành format cần thiết cho CalcPercent
        local calcData = {}
        for _, item in pairs(itemSelectedData) do
            table.insert(calcData, {
                name = item.name,
                quantity = item.selectedQuantity or 1,
                DoHiem = item.metadata and item.metadata.DoHiem or "Common"
            })
        end
        RateData = CalcPercent(ItemTargetData, calcData) -- Tỷ lệ hiển thị (capped by maxtile)
        RealRateData = CalcRealPercent(ItemTargetData, calcData) -- Tỷ lệ thực sự (capped by realtile)
    end
    
    DebugPrint("=== DEBUG UPGRADE ===")
    DebugPrint("Target Item:", ItemTargetData.name)
    DebugPrint("Target Capdo:", ItemTargetData.metadata.Capdo or "NIL")
    DebugPrint("RateData (Display Rate - maxtile):", RateData)
    DebugPrint("RealRateData (Actual Rate - realtile):", RealRateData)
    
    DebugPrint("=== REMOVING MATERIALS ===")
    for k, v in pairs(itemSelectedData) do
        local removeCount = v.selectedQuantity or 1
        DebugPrint(string.format("Removing material #%d: %s (slot %d, count %d of %d)", k, v.name, v.slot, removeCount, v.count))
        -- Xóa đúng số lượng đã chọn, không phải toàn bộ
        local success = exports.ox_inventory:RemoveItem(source, v.name, removeCount, nil, v.slot)
        DebugPrint(string.format("  -> Remove result: %s", tostring(success)))
        if not success then
            DebugPrint("ERROR: Failed to remove item, aborting upgrade!")
            return false
        end
    end
    DebugPrint("=== ALL MATERIALS REMOVED SUCCESSFULLY ===")
    
    -- Discord Log: Bắt đầu nâng cấp
    local playerName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
    local citizenid = xPlayer.PlayerData.citizenid
    local Pid = xPlayer.PlayerData.pid
    local stackableInfoLog = ParseStackableItem(ItemTargetData.name)
    local itemLabel = ItemTargetData.label or ItemTargetData.name
    local itemNumber = ""
    if stackableInfoLog then
        itemNumber = " (0)"
    elseif ItemTargetData.metadata and ItemTargetData.metadata.drawable then
        itemNumber = " (" .. tostring(ItemTargetData.metadata.drawable) .. ")"
    end
    
    local matListStr = ""
    for _, v in pairs(itemSelectedData) do
        local matLabel = v.label or v.name
        matListStr = matListStr .. "- " .. matLabel .. " x" .. (v.selectedQuantity or 1) .. "\n"
    end
    
    SendDiscordLog("🔨 Bắt đầu nâng cấp", string.format(
        "**Player:** %s\n**PID:** %s\n**Vật phẩm:** %s%s (Cấp %s)\n**Tỉ lệ hiển thị:** %s%%\n**Nguyên liệu:**\n%s",
        playerName, Pid, itemLabel, itemNumber, tostring(ItemTargetData.metadata.Capdo or 1), tostring(RateData), matListStr
    ), 3447003)
    
    local random = math.random(1, 100)
    DebugPrint("Random Roll:", random)
    DebugPrint("Success Check (using RealRateData):", random, "<=", RealRateData, "=>", random <= RealRateData)
    
    -- Create a COPY of metadata, not a reference
    local curData = {}
    for k, v in pairs(ItemTargetData.metadata) do
        curData[k] = v
    end
    
    -- Ensure Capdo exists and is a number
    if not curData.Capdo then
        curData.Capdo = 1
        DebugPrint("WARNING: Capdo was NIL, initialized to 1")
    else
        curData.Capdo = tonumber(curData.Capdo) or 1
    end
    
    DebugPrint("[DEBUG] Original Capdo:", ItemTargetData.metadata.Capdo)
    DebugPrint("[DEBUG] Working with Capdo:", curData.Capdo)
    
    -- Kiểm tra xem có phải stackable item không
    local stackableInfo = ParseStackableItem(ItemTargetData.name)
    local baseName = stackableInfo and stackableInfo.baseName or ItemTargetData.name
    
    -- Với stackable items, level được lấy từ tên item, không phải metadata
    if stackableInfo then
        curData.Capdo = stackableInfo.level
        curData.baseName = stackableInfo.baseName
        DebugPrint("[DEBUG] Stackable item detected:", ItemTargetData.name, "-> baseName:", baseName, ", level:", curData.Capdo)
    end
    
    -- Lấy config level từ BaloLevels (dùng baseName thay vì tên gốc)
    local itemConfig = Config.BaloLevels[baseName]
    local levelConfig = itemConfig and itemConfig[curData.Capdo]
    
    -- QUY ĐỊNH ẨN 1: Kiểm tra phôi / hasrarity - Chấp nhận rarity yêu cầu HOẶC CAO HƠN
    local requiredRarity = (levelConfig and levelConfig.hasrarity) or GetDoHiemByCapdo(curData.Capdo)
    local RarityOrder = Config.RarityOrder
    local requiredLevel = (requiredRarity and RarityOrder[requiredRarity]) or curData.Capdo or 1
    local hasRequiredItem = false
    
    -- Kiểm tra xem có nguyên liệu với rarity đủ yêu cầu không
    for _, item in pairs(itemSelectedData) do
        local matDoHiem = item.metadata and item.metadata.DoHiem or "Common"
        local matLevel = RarityOrder[matDoHiem] or (item.metadata and tonumber(item.metadata.Capdo)) or 1
        if matLevel >= requiredLevel then
            hasRequiredItem = true
            DebugPrint("[DEBUG] ✅ Đã có nguyên liệu rarity phù hợp: " .. item.name .. " (" .. matDoHiem .. ", yêu cầu: " .. tostring(requiredRarity) .. " trở lên)")
            break
        end
    end
    
    if not hasRequiredItem then
        DebugPrint("[DEBUG] ⚠️ QUY ĐỊNH ẨN 1: Thiếu nguyên liệu rarity " .. tostring(requiredRarity) .. " trở lên - nâng cấp sẽ luôn thất bại")
    end
    
    -- QUY ĐỊNH ẨN 2: Kiểm tra tỷ lệ >= 30% (trừ khi level có realtile)
    local hasRealtile = levelConfig and levelConfig.realtile
    local isSuccess = false
    
    if hasRequiredItem then
        -- Nếu level có realtile, BỎ QUA điều kiện >= 30%
        if hasRealtile then
            isSuccess = random <= RealRateData
            DebugPrint("[DEBUG] ✅ Level có REALTILE - bỏ qua điều kiện >= 30%, tỷ lệ thực: " .. RealRateData .. "%")
        else
            -- Level không có realtile, áp dụng điều kiện >= 30%
            if RealRateData >= 30 then
                isSuccess = random <= RealRateData
            else
                isSuccess = false
                DebugPrint("[DEBUG] ⛔ QUY ĐỊNH ẨN 2: Tỉ lệ dưới 30% (" .. RealRateData .. "%) - BẮT BUỘC THẤT BẠI")
            end
        end
    else
        isSuccess = false -- Thiếu hasrarity = luôn thất bại
        DebugPrint("[DEBUG] ⛔ QUY ĐỊNH ẨN 1: Thiếu nguyên liệu rarity yêu cầu - BẮT BUỘC THẤT BẠI")
    end
    
    DebugPrint("[DEBUG] Has Required Item:", hasRequiredItem)
    DebugPrint("[DEBUG] Has Realtile:", tostring(hasRealtile))
    DebugPrint("[DEBUG] Final Success:", tostring(isSuccess))

    -- ====================== PITY RATE OVERRIDE ======================
    -- Nếu level hiện tại có config pity_rate, override toàn bộ logic tỷ lệ ở trên
    local lo, hi = GetPityRate(levelConfig)
    local usePity = lo ~= nil and hi ~= nil
    local pityFail = false
    local pityNewRate, pityNewNum = nil, nil

    if usePity then
        local existingRate = tonumber(curData.pityrate)
        local existingNum = tonumber(curData.pitynum) or 0

        if not existingRate then
            -- Lần nâng cấp đầu tiên với pity (chưa từng có pityrate): bắt buộc thất bại + init metadata
            pityNewRate = RollPityRate(levelConfig)
            if hasRequiredItem then
                pityNewNum = 1
                DebugPrint("[PITY] Init metadata (có phôi hợp lệ >= " .. tostring(requiredRarity) .. ") - pityrate:", pityNewRate, "pitynum: 1 => FAIL (+1 pity)")
            else
                pityNewNum = 0
                DebugPrint("[PITY] Init metadata (KHÔNG có phôi hợp lệ >= " .. tostring(requiredRarity) .. ") - pityrate:", pityNewRate, "pitynum: 0 => FAIL (KHÔNG cộng pity)")
            end
            isSuccess = false
            pityFail = true
        else
            -- Đã có pityrate từ trước: kiểm tra nếu pityrate cũ không khớp với khoảng [lo, hi] trong config mới
            if existingRate < lo or existingRate > hi then
                local rolledRate = RollPityRate(levelConfig)
                DebugPrint(string.format("[PITY] ⚠️ Pityrate trong metadata (%s) không khớp config [%s, %s]! Roll lại pityrate mới: %s", tostring(existingRate), tostring(lo), tostring(hi), tostring(rolledRate)))
                existingRate = rolledRate
                -- Nếu số lần fail tích lũy vượt quá pityrate mới, cap lại bằng pityrate mới
                if existingNum > existingRate then
                    existingNum = existingRate
                end
            end

            if hasRequiredItem then
                -- Có phôi ở cấp độ yêu cầu -> ĐƯỢC TÍNH + PITY_RATE
                local newNum = existingNum + 1
                if newNum >= existingRate then
                    -- Đủ pity -> chắc chắn thành công, NHƯNG vẫn phải qua các quy định ẩn
                    local passHidden = true
                    if RateData < 30 then
                        passHidden = false
                    end

                    if passHidden then
                        isSuccess = true
                        pityFail = false
                        pityNewRate = existingRate
                        pityNewNum = newNum
                        DebugPrint("[PITY] Đạt pity:", newNum, "/", existingRate, "=> SUCCESS")
                    else
                        -- Pity đủ nhưng không đạt quy định ẩn (<30%) => vẫn FAIL
                        -- Giữ pitynum cap tại pityrate để lần sau (khi đạt điều kiện) chắc chắn thành công
                        isSuccess = false
                        pityFail = true
                        pityNewRate = existingRate
                        pityNewNum = existingRate
                        DebugPrint("[PITY] Đủ pity nhưng KHÔNG đạt quy định ẩn (RateData < 30%) => FAIL, giữ pitynum =", pityNewNum)
                    end
                else
                    isSuccess = false
                    pityFail = true
                    pityNewRate = existingRate
                    pityNewNum = newNum
                    DebugPrint("[PITY] Có phôi hợp lệ, tăng pitynum:", newNum, "/", existingRate, "=> FAIL")
                end
            else
                -- KHÔNG có phôi ở cấp độ yêu cầu -> KHÔNG ĐƯỢC CỘNG PITY_RATE (giữ nguyên existingNum)
                isSuccess = false
                pityFail = true
                pityNewRate = existingRate
                pityNewNum = existingNum
                DebugPrint("[PITY] ⛔ Thiếu phôi cấp độ tương ứng (" .. tostring(requiredRarity) .. ") -> KHÔNG tính + pity! Giữ nguyên pitynum =", pityNewNum, "/", existingRate)
            end
        end

        -- Ghi pity hiện tại vào curData để truyền theo nếu thành công (sẽ bị clear sau)
        curData.pityrate = pityNewRate
        curData.pitynum = pityNewNum
    else
        -- Nếu level này không dùng pity nhưng item vẫn còn dính metadata pityrate/pitynum cũ, xóa đi
        if ItemTargetData.metadata and (ItemTargetData.metadata.pityrate or ItemTargetData.metadata.pitynum) then
            UpdateItemPityMetadata(source, ItemTargetData.slot, nil, nil)
            curData.pityrate = nil
            curData.pitynum = nil
            DebugPrint("[PITY] Level hiện tại không dùng pity -> Đã xóa pity metadata cũ khỏi item")
        end
    end

    if isSuccess then
        -- THÀNH CÔNG: Tăng cấp
        local newCapdo = curData.Capdo + 1
        curData.Capdo = newCapdo
        
        -- Cập nhật DoHiem dựa trên Capdo mới
        curData.DoHiem = GetDoHiemByCapdo(curData.Capdo)
        
        -- Tên item mới sẽ được lưu để claim
        local newItemName = ItemTargetData.name
        
        -- Xử lý stackable items (fishingrod, chaodaivang)
        if stackableInfo then
            -- Tên item mới = baseName + newLevel
            newItemName = stackableInfo.baseName .. newCapdo
            
            -- Lấy label từ componentMapping
            local componentConfig = Config.componentMapping[stackableInfo.baseName]
            local baseLabel = componentConfig and componentConfig.label or stackableInfo.baseName
            curData.label = baseLabel .. " LV" .. newCapdo
            
            -- Lấy imageUrl cho stackable item
            curData.imageurl = "https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/" .. newItemName .. ".webp"
            
            DebugPrint("[DEBUG SUCCESS] Stackable item upgrade:", ItemTargetData.name, "->", newItemName)
        elseif baseName == "cloth_bags" then
            -- Sử dụng cấu trúc mới BaloLevels cho clothing
            local successLevelConfig = Config.BaloLevels[baseName][curData.Capdo]
            local gender = xPlayer.PlayerData.charinfo.gender == 0 and "male" or "female"
            local drawableList = successLevelConfig and successLevelConfig[gender]
            
            -- Nếu level hiện tại không có drawable, thử lấy từ nextadd của level trước
            if (not drawableList or #drawableList == 0) and curData.Capdo > 1 then
                local prevLevelConfig = Config.BaloLevels[baseName][curData.Capdo - 1]
                if prevLevelConfig and prevLevelConfig.nextadd and prevLevelConfig.nextadd[gender] then
                    drawableList = prevLevelConfig.nextadd[gender]
                end
            end
            
            if drawableList and #drawableList > 0 then
                local newDrawable = drawableList[math.random(1, #drawableList)]
                
                -- Tạo imageUrl dựa theo format của XN_DapBaloV2 (KHÔNG có texture)
                local component = Config.componentMapping[baseName].component
                local imageName = string.format("%s_%d_%d", gender, component, newDrawable)
                local imageUrl = "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main/" .. imageName .. ".webp"
                
                -- Cập nhật metadata đầy đủ như XN_DapBaloV2
                curData.type = component
                curData.drawable = newDrawable
                curData.texture = 0
                curData.sex = gender
                curData.id = component
                curData.description = "Thời trang của " .. (gender == "male" and "Nam" or "Nữ")
                curData.label = Config.componentMapping[baseName].label .. ' ' .. newDrawable
                curData.imageurl = imageUrl
                
                DebugPrint("[DEBUG] Generated imageUrl:", imageUrl)
            end
        end

        -- Gán pity metadata cho item lv mới (clear pity cũ; nếu cấp tiếp theo có pity_rate thì roll mới)
        local nextLevelConfig = Config.BaloLevels[baseName] and Config.BaloLevels[baseName][curData.Capdo]
        BuildNewItemPityMetadata(curData, nextLevelConfig)

        -- XÓA item cũ
        DebugPrint("[DEBUG SUCCESS] ===================")
        DebugPrint("[DEBUG SUCCESS] Old metadata:", json.encode(ItemTargetData.metadata))
        DebugPrint("[DEBUG SUCCESS] New metadata:", json.encode(curData))
        DebugPrint("[DEBUG SUCCESS] Removing old item:", ItemTargetData.name, "from slot:", ItemTargetData.slot)
        local removeSuccess = exports.ox_inventory:RemoveItem(source, ItemTargetData.name, 1, nil, ItemTargetData.slot)
        DebugPrint("[DEBUG SUCCESS] Remove result:", removeSuccess)
        
        -- Tạo serial cho item
        curData.serial = Config.Textserial .. GenerateSerial()
        
        -- LƯU thông tin item mới để chờ player claim
        PENDING_UPGRADE[source] = {
            name = newItemName,
            metadata = curData
        }
        
        DebugPrint("[DEBUG SUCCESS] Item saved to PENDING_UPGRADE:", newItemName)
        DebugPrint("[DEBUG SUCCESS] ===================")
        
        TriggerEvent("qb-logs:server:createLog", "playerinventory", "UpgradeBag",
            "Nâng cấp thành công lên cấp: " .. curData.Capdo, xPlayer.PlayerData.source)
        
        lib.logger(source, 'UpgradeBag', string.format("Nâng cấp thành công %s lên cấp %s (Balo số: %s, Serial: %s)", curData.label or newItemName, tostring(curData.Capdo), tostring(curData.drawable or (ItemTargetData.metadata and ItemTargetData.metadata.drawable) or "N/A"), curData.serial or (ItemTargetData.metadata and ItemTargetData.metadata.serial) or "N/A"),
            "result:success",
            "item:" .. newItemName,
            "level:" .. tostring(curData.Capdo),
            "serial:" .. (curData.serial or (ItemTargetData.metadata and ItemTargetData.metadata.serial) or "N/A"),
            "drawable:" .. tostring(curData.drawable or (ItemTargetData.metadata and ItemTargetData.metadata.drawable) or "N/A")
        )
        
        SendDiscordLog("✅ Nâng cấp thành công", string.format(
            "**Player:** %s\n**PID:** %s\n**Vật phẩm:** %s%s\n**Cấp:** %s → %s\n**Nhận được:** %s\n**Serial:** %s",
            playerName, Pid, itemLabel, itemNumber, tostring((curData.Capdo or 2) - 1), tostring(curData.Capdo), curData.label or newItemName, curData.serial or "N/A"
        ), 3066993)
        
        -- Thông báo toàn server khi nâng cấp thành công từ LV2 trở lên
        if curData.Capdo >= 2 then
            local fullPlayerName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
            local baseItemLabel = Config.componentMapping[baseName] and Config.componentMapping[baseName].label or baseName
            local announceMsg = 'Chúc mừng ' .. fullPlayerName .. ' đã nâng cấp thành công ' .. baseItemLabel .. ' LV' .. curData.Capdo
            local imageUrl = curData.imageurl or ""
            exports['xn_thongbao']:SendSpecialAnnouncementToAll('NÂNG CẤP', announceMsg, 20000, imageUrl)
        end
        
        -- Trả về thông tin item mới sau khi upgrade thành công
        return true, {
            label = curData.label or ItemTargetData.label,
            imageurl = curData.imageurl or "",
            drawable = curData.drawable,
            Capdo = curData.Capdo
        }
    else
        -- THẤT BẠI: Rớt cấp hoặc giữ nguyên
        -- Sử dụng cấu trúc mới BaloLevels (dùng baseName)
        local failLevelConfig = Config.BaloLevels[baseName] and Config.BaloLevels[baseName][curData.Capdo]
        
        -- Tên item mới sẽ được lưu để claim
        local newItemName = ItemTargetData.name
        
        -- Kiểm tra xem có sử dụng bùa may mắn (bua_may_man) không
        local hasLuckyCharm = false
        for _, v in ipairs(itemSelectedData) do
            if v.name == "bua_may_man" then
                hasLuckyCharm = true
                break
            end
        end
        
        local shouldDemote = false
        local demotedLevel = curData.Capdo
        
        if failLevelConfig and not hasLuckyCharm then
            if failLevelConfig.downlevel then
                shouldDemote = true
                if failLevelConfig.failBackTo then
                    demotedLevel = failLevelConfig.failBackTo
                else
                    demotedLevel = math.max(1, curData.Capdo - 1)
                end
            end
        end

        -- ====================== PITY FAIL: KHÔNG HẠ CẤP, CHỈ CẬP NHẬT METADATA ======================
        -- Thất bại trong hệ thống pity -> KHÔNG rớt cấp
        if pityFail then
            shouldDemote = false
            UpdateItemPityMetadata(source, ItemTargetData.slot, pityNewRate, pityNewNum)

            DebugPrint("[PITY FAIL] Slot:", ItemTargetData.slot, "pityrate:", pityNewRate, "pitynum:", pityNewNum)

            if not hasRequiredItem then
                TriggerEvent("qb-logs:server:createLog", "playerinventory", "UpgradeBag",
                    ("Nâng cấp thất bại (thiếu phôi cấp độ, không tính pity %s/%s) - giữ nguyên cấp %s"):format(pityNewNum, pityNewRate, tostring(curData.Capdo)), xPlayer.PlayerData.source)

                lib.logger(source, 'UpgradeBag', string.format("Nâng cấp thất bại (Thiếu phôi cấp %s, không cộng Pity) %s giữ nguyên cấp %s (Balo số: %s, Pity: %s/%s)", tostring(curData.Capdo), ItemTargetData.metadata.label or ItemTargetData.label, tostring(curData.Capdo), tostring(ItemTargetData.metadata.drawable or "N/A"), tostring(pityNewNum), tostring(pityNewRate)),
                    "result:fail_pity_no_material",
                    "item:" .. ItemTargetData.name,
                    "level:" .. tostring(curData.Capdo),
                    "serial:" .. (ItemTargetData.metadata.serial or "N/A"),
                    "drawable:" .. tostring(ItemTargetData.metadata.drawable or "N/A"),
                    "pity:" .. tostring(pityNewNum) .. "/" .. tostring(pityNewRate)
                )

                SendDiscordLog("❌ Nâng cấp thất bại (Thiếu phôi cấp độ)", string.format(
                    "**Player:** %s\n**PID:** %s\n**Vật phẩm:** %s%s\n**Giữ nguyên cấp:** %s\n**Pity:** %s / %s *(Không tăng do thiếu phôi cấp độ)*",
                    playerName, Pid, itemLabel, itemNumber, tostring(curData.Capdo), tostring(pityNewNum), tostring(pityNewRate)
                ), 15158332)
            else
                TriggerEvent("qb-logs:server:createLog", "playerinventory", "UpgradeBag",
                    ("Nâng cấp thất bại (pity %s/%s) - giữ nguyên cấp %s"):format(pityNewNum, pityNewRate, tostring(curData.Capdo)), xPlayer.PlayerData.source)

                lib.logger(source, 'UpgradeBag', string.format("Nâng cấp thất bại (Pity) %s giữ nguyên cấp %s (Balo số: %s, Pity: %s/%s)", ItemTargetData.metadata.label or ItemTargetData.label, tostring(curData.Capdo), tostring(ItemTargetData.metadata.drawable or "N/A"), tostring(pityNewNum), tostring(pityNewRate)),
                    "result:fail_pity",
                    "item:" .. ItemTargetData.name,
                    "level:" .. tostring(curData.Capdo),
                    "serial:" .. (ItemTargetData.metadata.serial or "N/A"),
                    "drawable:" .. tostring(ItemTargetData.metadata.drawable or "N/A"),
                    "pity:" .. tostring(pityNewNum) .. "/" .. tostring(pityNewRate)
                )

                SendDiscordLog("❌ Nâng cấp thất bại (Pity)", string.format(
                    "**Player:** %s\n**PID:** %s\n**Vật phẩm:** %s%s\n**Giữ nguyên cấp:** %s\n**Pity:** %s / %s",
                    playerName, Pid, itemLabel, itemNumber, tostring(curData.Capdo), tostring(pityNewNum), tostring(pityNewRate)
                ), 15158332)
            end

            return false, {
                label = ItemTargetData.metadata.label or ItemTargetData.label,
                imageurl = ItemTargetData.metadata.imageurl or "",
                drawable = ItemTargetData.metadata.drawable,
                Capdo = ItemTargetData.metadata.Capdo or curData.Capdo,
                pityrate = pityNewRate,
                pitynum = pityNewNum,
            }
        end
        
        if shouldDemote then
            curData.Capdo = demotedLevel
            
            -- Cập nhật DoHiem dựa trên Capdo mới sau khi rớt cấp
            curData.DoHiem = GetDoHiemByCapdo(curData.Capdo)
            
            -- Xử lý stackable items
            if stackableInfo then
                -- Tên item mới = baseName + demotedLevel
                newItemName = stackableInfo.baseName .. demotedLevel
                
                -- Lấy label từ componentMapping
                local componentConfig = Config.componentMapping[stackableInfo.baseName]
                local baseLabel = componentConfig and componentConfig.label or stackableInfo.baseName
                curData.label = baseLabel .. " LV" .. demotedLevel
                
                -- Lấy imageUrl cho stackable item
                curData.imageurl = "https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/" .. newItemName .. ".webp"
                
                DebugPrint("[DEBUG FAIL] Stackable item downgrade:", ItemTargetData.name, "->", newItemName)
            elseif baseName == "cloth_bags" then
                local downLevelConfig = Config.BaloLevels[baseName][curData.Capdo]
                local gender = xPlayer.PlayerData.charinfo.gender == 0 and "male" or "female"
                local drawableList = downLevelConfig and downLevelConfig[gender]
                
                if drawableList and #drawableList > 0 then
                    local newDrawable = drawableList[math.random(1, #drawableList)]
                    
                    -- Tạo imageUrl dựa theo format của XN_DapBaloV2 (KHÔNG có texture)
                    local component = Config.componentMapping[baseName].component
                    local imageName = string.format("%s_%d_%d", gender, component, newDrawable)
                    local imageUrl = "https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main/" .. imageName .. ".webp"
                    
                    -- Cập nhật metadata đầy đủ như XN_DapBaloV2
                    curData.type = component
                    curData.drawable = newDrawable
                    curData.texture = 0
                    curData.sex = gender
                    curData.id = component
                    curData.description = "Thời trang của " .. (gender == "male" and "Nam" or "Nữ")
                    curData.label = Config.componentMapping[baseName].label .. ' ' .. newDrawable
                    curData.imageurl = imageUrl
                    
                    DebugPrint("[DEBUG FAIL] Generated imageUrl:", imageUrl)
                end
            end

            -- Gán pity metadata cho item lv mới (clear pity cũ; nếu cấp mới có pity_rate thì roll mới)
            local downLevelConfig = Config.BaloLevels[baseName] and Config.BaloLevels[baseName][curData.Capdo]
            BuildNewItemPityMetadata(curData, downLevelConfig)

            -- XÓA item cũ
            DebugPrint("[DEBUG FAIL] Removing old item:", ItemTargetData.name, "from slot:", ItemTargetData.slot)
            local removeSuccess = exports.ox_inventory:RemoveItem(source, ItemTargetData.name, 1, nil, ItemTargetData.slot)
            DebugPrint("[DEBUG FAIL] Remove result:", removeSuccess)
            
            -- Tạo serial cho item
            curData.serial = Config.Textserial .. GenerateSerial()
            
            -- LƯU thông tin item thất bại để chờ player claim
            PENDING_UPGRADE[source] = {
                name = newItemName,
                metadata = curData,
                isFail = true
            }
            
            DebugPrint("[DEBUG FAIL] Item saved to PENDING_UPGRADE:", newItemName)
            DebugPrint("[DEBUG FAIL] Capdo:", curData.Capdo)
        end
        
        TriggerEvent("qb-logs:server:createLog", "playerinventory", "UpgradeBag",
            "Nâng cấp thất bại về cấp: " .. curData.Capdo, xPlayer.PlayerData.source)
        
        lib.logger(source, 'UpgradeBag', string.format("Nâng cấp thất bại %s rớt về cấp %s (Balo số: %s, Serial: %s)", curData.label or newItemName, tostring(curData.Capdo), tostring(curData.drawable or (ItemTargetData.metadata and ItemTargetData.metadata.drawable) or "N/A"), curData.serial or (ItemTargetData.metadata and ItemTargetData.metadata.serial) or "N/A"),
            "result:fail",
            "item:" .. newItemName,
            "level:" .. tostring(curData.Capdo),
            "serial:" .. (curData.serial or (ItemTargetData.metadata and ItemTargetData.metadata.serial) or "N/A"),
            "drawable:" .. tostring(curData.drawable or (ItemTargetData.metadata and ItemTargetData.metadata.drawable) or "N/A")
        )
        
        SendDiscordLog("❌ Nâng cấp thất bại", string.format(
            "**Player:** %s\n**PID:** %s\n**Vật phẩm:** %s%s\n**Rớt về cấp:** %s\n**Nhận được:** %s\n**Serial:** %s",
            playerName, Pid, itemLabel, itemNumber, tostring(curData.Capdo), curData.label or newItemName, curData.serial or "N/A"
        ), 15158332)
        
        -- Trả về thông tin item thất bại để hiển thị
        return false, {
            label = curData.label or ItemTargetData.label,
            imageurl = curData.imageurl or "",
            drawable = curData.drawable,
            Capdo = curData.Capdo
        }
    end
end)

lib.callback.register("qb-upgrade-bag:claimItem", function(source)
    DebugPrint("[SERVER] Claim item callback called for source:", source)
    
    if not PENDING_UPGRADE[source] then
        DebugPrint("[SERVER] No pending upgrade found for source:", source)
        return false
    end
    
    local pendingData = PENDING_UPGRADE[source]
    DebugPrint("[SERVER] Adding item:", pendingData.name, "with metadata:", json.encode(pendingData.metadata))
    
    local xPlayer = exports.qbx_core:GetPlayer(source)
    local playerName = xPlayer and xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname or "Unknown"
    local citizenid = xPlayer and xPlayer.PlayerData.citizenid or "Unknown"
    local Pid = xPlayer and xPlayer.PlayerData.pid or "Unknown"
    local claimLabel = pendingData.metadata and pendingData.metadata.label or pendingData.name
    local claimCapdo = pendingData.metadata and pendingData.metadata.Capdo or "?"
    local resultType = pendingData.isFail and "Thất bại" or "Thành công"

    local addSuccess = exports.ox_inventory:AddItem(source, pendingData.name, 1, pendingData.metadata)
    DebugPrint("[SERVER] Add result:", addSuccess)
    
    if addSuccess then
        SendDiscordLog("📦 Nhận vật phẩm", string.format(
            "**Player:** %s\n**PID:** %s\n**Kết quả:** %s\n**Nhận được:** %s (Cấp %s)\n**Serial:** %s",
            playerName, Pid, resultType, claimLabel, tostring(claimCapdo), pendingData.metadata and pendingData.metadata.serial or "N/A"
        ), pendingData.isFail and 15105570 or 3066993)

        PENDING_UPGRADE[source] = nil
        DebugPrint("[SERVER] Item claimed successfully, cleared pending upgrade")
        return true
    else
        -- Kho đồ đầy, gửi vật phẩm về kho lưu trữ cá nhân (bưu cục)
        DebugPrint("[SERVER] Inventory full, sending to personal storage")
        if citizenid and citizenid ~= "Unknown" and exports.xn_buucuc then
            exports.xn_buucuc:AddItemToPersonalStorage(citizenid, pendingData.name, 1, pendingData.metadata)
            exports.qbx_core:Notify(source, 'Kho đồ đã đầy! Vật phẩm ' .. claimLabel .. ' đã được gửi về kho lưu trữ cá nhân (bưu cục).', 'warning')
            
            SendDiscordLog("📬 Gửi về bưu cục (kho đầy)", string.format(
                "**Player:** %s\n**PID:** %s\n**Kết quả:** %s\n**Vật phẩm:** %s (Cấp %s)\n**Serial:** %s\n**Lý do:** Kho đồ đầy",
                playerName, Pid, resultType, claimLabel, tostring(claimCapdo), pendingData.metadata and pendingData.metadata.serial or "N/A"
            ), 15105570)

            PENDING_UPGRADE[source] = nil
            return true
        else
            exports.qbx_core:Notify(source, 'Kho đồ đầy và không thể gửi về kho lưu trữ! Vui lòng dọn dẹp kho đồ.', 'error')
            DebugPrint("[SERVER] Failed to add item and personal storage not available")
            return false
        end
    end
end)

-- Khi player disconnect/crash, gửi vật phẩm pending về bưu cục
AddEventHandler("playerDropped", function()
    local src = source
    local pendingData = PENDING_UPGRADE[src]
    if not pendingData then return end

    local xPlayer = exports.qbx_core:GetPlayer(src)
    local citizenid = xPlayer and xPlayer.PlayerData.citizenid
    local playerName = xPlayer and (xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname) or "Unknown"
    local Pid = xPlayer and xPlayer.PlayerData.pid or "Unknown"
    local claimLabel = pendingData.metadata and pendingData.metadata.label or pendingData.name
    local claimCapdo = pendingData.metadata and pendingData.metadata.Capdo or "?"
    local resultType = pendingData.isFail and "Thất bại" or "Thành công"

    if citizenid and exports.xn_buucuc then
        exports.xn_buucuc:AddItemToPersonalStorage(citizenid, pendingData.name, 1, pendingData.metadata)

        SendDiscordLog("📬 Gửi về bưu cục (disconnect)", string.format(
            "**Player:** %s\n**PID:** %s\n**Kết quả:** %s\n**Vật phẩm:** %s (Cấp %s)\n**Serial:** %s\n**Lý do:** Player disconnect/crash",
            playerName, Pid, resultType, claimLabel, tostring(claimCapdo), pendingData.metadata and pendingData.metadata.serial or "N/A"
        ), 15105570)

        DebugPrint("[SERVER] Player dropped, sent pending item to personal storage:", pendingData.name)
    else
        SendDiscordLog("⚠️ Mất vật phẩm (disconnect)", string.format(
            "**Player:** %s\n**PID:** %s\n**Kết quả:** %s\n**Vật phẩm:** %s (Cấp %s)\n**Serial:** %s\n**Lý do:** Player disconnect, không có bưu cục",
            playerName, Pid, resultType, claimLabel, tostring(claimCapdo), pendingData.metadata and pendingData.metadata.serial or "N/A"
        ), 15158332)

        DebugPrint("[SERVER] Player dropped, NO personal storage available! Item lost:", pendingData.name)
    end

    PENDING_UPGRADE[src] = nil
    ITEM_TARGET_UP[src] = nil
end)

RegisterNetEvent("xn-upgrade:selectTarget", function(slot)
    ITEM_TARGET_UP[source] = slot
    if not slot or type(slot) ~= 'number' then return end

    local item = exports.ox_inventory:GetSlot(source, slot)
    if not item or not item.metadata then return end

    local stackableInfo = ParseStackableItem(item.name)
    local baseName = stackableInfo and stackableInfo.baseName or item.name
    local capdo = stackableInfo and stackableInfo.level or (item.metadata.Capdo and tonumber(item.metadata.Capdo)) or 1

    local itemConfig = Config.BaloLevels[baseName]
    local levelConfig = itemConfig and itemConfig[capdo]
    if not levelConfig then return end

    local lo, hi = GetPityRate(levelConfig)
    if lo and hi then
        local existingRate = tonumber(item.metadata.pityrate)
        local existingNum = tonumber(item.metadata.pitynum) or 0
        if existingRate then
            if existingRate < lo or existingRate > hi then
                local newRate = RollPityRate(levelConfig)
                local newNum = existingNum
                if newNum > newRate then
                    newNum = newRate
                end
                UpdateItemPityMetadata(source, slot, newRate, newNum)
                DebugPrint(string.format("[PITY selectTarget] Pityrate cũ (%s) không khớp config [%s, %s] -> Đã cập nhật pityrate mới: %s (pitynum: %s)", tostring(existingRate), tostring(lo), tostring(hi), tostring(newRate), tostring(newNum)))
            end
        end
    elseif item.metadata.pityrate or item.metadata.pitynum then
        UpdateItemPityMetadata(source, slot, nil, nil)
        DebugPrint("[PITY selectTarget] Level hiện tại không dùng pity -> Đã xóa pity metadata cũ khỏi item")
    end
end)
lib.callback.register("qb-upgrade-bag:getPossibleRewards", function(source, data)
    DebugPrint("[DEBUG] getPossibleRewards called for source:", source)
    DebugPrint("[DEBUG] Data received:", json.encode(data))
    
    local xPlayer = exports.qbx_core:GetPlayer(source)
    
    if not xPlayer then
        DebugPrint("[ERROR] No xPlayer found")
        return {}
    end
    
    -- Lấy player metadata (giới tính)
    local gender = xPlayer.PlayerData.charinfo.gender or 0 -- 0 = male, 1 = female
    local genderKey = gender == 0 and "male" or "female"
    DebugPrint("[DEBUG] Player gender:", gender, "genderKey:", genderKey)
    
    -- Lấy item hiện tại từ inventory - sử dụng slot từ data
    local itemSlot = data.slot or ITEM_TARGET_UP[source]
    if not itemSlot then
        DebugPrint("[ERROR] No target item slot found for source:", source)
        return {}
    end
    
    DebugPrint("[DEBUG] Using slot:", itemSlot)
    local currentItem = exports.ox_inventory:GetSlot(source, itemSlot)
    
    if not currentItem then
        DebugPrint("[ERROR] No item in slot:", itemSlot)
        return {}
    end
    
    DebugPrint("[DEBUG] Current item:", currentItem.name, "Slot:", itemSlot)
    
    -- Kiểm tra xem có phải stackable item không
    local stackableInfo = ParseStackableItem(currentItem.name)
    local baseItemName = stackableInfo and stackableInfo.baseName or currentItem.name
    
    -- Lấy level hiện tại - với stackable items lấy từ tên, không phải metadata
    local currentLevel = stackableInfo and stackableInfo.level or (currentItem.metadata.Capdo or 1)
    
    DebugPrint("[DEBUG] Current level:", currentLevel, "Base item name:", baseItemName)
    DebugPrint("[DEBUG] Stackable info:", stackableInfo and "yes" or "no")
    
    -- Lấy danh sách reward cho cấp tiếp theo (success) và cấp hiện tại (fail)
    local rewards = {}
    local nextLevel = currentLevel + 1
    
    -- Lấy thông tin component từ config
    local componentInfo = Config.componentMapping[baseItemName]
    if not componentInfo then
        DebugPrint("[ERROR] No component mapping for item:", baseItemName)
        return {}
    end
    
    DebugPrint("[DEBUG] Component info found, label:", componentInfo.label, "type:", componentInfo.type or 'clothing')
    
    -- Kiểm tra nếu là item stackable (type = 'item')
    if componentInfo.type == 'item' then
        -- Đây là item phân theo cấp: fishingrod1, fishingrod2, chaodaivang1, chaodaivang2, ...
        local maxLevel = componentInfo.maxLevel or 5
        
        if currentLevel < maxLevel then
            -- Success reward: item cấp tiếp theo
            local nextItemName = baseItemName .. nextLevel
            local imageUrl = "https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/" .. nextItemName .. ".webp"
            
            DebugPrint("[DEBUG] Adding stackable success reward:", nextItemName)
            table.insert(rewards, {
                type = 'success',
                name = nextItemName,
                label = componentInfo.label,
                metadata = {
                    Capdo = nextLevel,
                    DoHiem = GetDoHiemByCapdo(nextLevel),
                    imageurl = imageUrl
                }
            })
            
            local itemConfig = Config.BaloLevels[baseItemName]
            if itemConfig and itemConfig[currentLevel] then
                local levelConfig = itemConfig[currentLevel]
                local failLevel = nil
                if levelConfig.downlevel then
                    if levelConfig.failBackTo then
                        failLevel = levelConfig.failBackTo
                    else
                        failLevel = math.max(1, currentLevel - 1)
                    end
                end
                
                if failLevel then
                    local failItemName = baseItemName .. failLevel
                    local failImageUrl = "https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/" .. failItemName .. ".webp"
                    
                    DebugPrint("[DEBUG] Adding stackable fail reward:", failItemName)
                    table.insert(rewards, {
                        type = 'fail',
                        name = failItemName,
                        label = componentInfo.label,
                        metadata = {
                            Capdo = failLevel,
                            DoHiem = GetDoHiemByCapdo(failLevel),
                            imageurl = failImageUrl
                        }
                    })
                end
            end
        else
            DebugPrint("[DEBUG] Item already at max level:", maxLevel)
        end
        
        DebugPrint("[DEBUG] Total stackable rewards:", #rewards)
        return rewards
    end
    
    -- Xử lý clothing items (logic cũ)
    -- Sử dụng cấu trúc mới BaloLevels
    local itemConfig = Config.BaloLevels[baseItemName]
    if not itemConfig then
        DebugPrint("[ERROR] No BaloLevels config for item:", baseItemName)
        return {}
    end
    
    -- Success rewards (cấp tiếp theo)
    local nextLevelConfig = itemConfig[nextLevel]
    if nextLevelConfig then
        local drawableList = nextLevelConfig[genderKey]
        
        -- Nếu không có drawable ở level tiếp theo, thử lấy từ nextadd của level hiện tại
        if (not drawableList or #drawableList == 0) then
            local currentLevelConfig = itemConfig[currentLevel]
            if currentLevelConfig and currentLevelConfig.nextadd and currentLevelConfig.nextadd[genderKey] then
                drawableList = currentLevelConfig.nextadd[genderKey]
            end
        end
        
        if drawableList and #drawableList > 0 then
            DebugPrint("[DEBUG] Adding success rewards for level:", nextLevel)
            for _, drawableId in pairs(drawableList) do
                table.insert(rewards, {
                    type = 'success',
                    name = baseItemName,
                    label = componentInfo.label,
                    metadata = {
                        Capdo = nextLevel,
                        component = componentInfo.component,
                        drawable = drawableId,
                        texture = 0,
                        sex = genderKey,
                        DoHiem = GetDoHiemByCapdo(nextLevel)
                    }
                })
            end
        end
    end
    
    -- Fail rewards (cấp rớt về)
    local currentLevelConfig = itemConfig[currentLevel]
    if currentLevelConfig then
        local failLevel = nil
        if currentLevelConfig.downlevel then
            if currentLevelConfig.failBackTo then
                failLevel = currentLevelConfig.failBackTo
            else
                failLevel = math.max(1, currentLevel - 1)
            end
        end
        
        if failLevel then
            local failLevelConfig = itemConfig[failLevel]
            if failLevelConfig then
                local failDrawableList = failLevelConfig[genderKey]
                if failDrawableList and #failDrawableList > 0 then
                    DebugPrint("[DEBUG] Adding fail rewards for level:", failLevel)
                    for _, drawableId in pairs(failDrawableList) do
                        table.insert(rewards, {
                            type = 'fail',
                            name = baseItemName,
                            label = componentInfo.label,
                            metadata = {
                                Capdo = failLevel,
                                component = componentInfo.component,
                                drawable = drawableId,
                                texture = 0,
                                sex = genderKey,
                                DoHiem = GetDoHiemByCapdo(failLevel)
                            }
                        })
                    end
                end
            end
        end
    end
    
    DebugPrint("[DEBUG] Total rewards:", #rewards)
    return rewards
end)