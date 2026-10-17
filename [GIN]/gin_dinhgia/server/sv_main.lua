local QBCore = nil
local QBX = nil

if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local activeUser = nil

local JSON_FILE = 'prices.json'
local ItemPrices = {}

-- Đọc lịch sử giá từ tệp prices.json
local function LoadPriceHistory()
    local fileContent = LoadResourceFile(GetCurrentResourceName(), JSON_FILE)
    if fileContent then
        local status, data = pcall(json.decode, fileContent)
        if status and type(data) == 'table' then
            return data
        end
    end
    return {}
end

-- Lưu lịch sử giá hiện tại và giá cũ vào tệp prices.json
local function SavePriceHistory()
    local dataToSave = {}
    for name, itemData in pairs(ItemPrices) do
        dataToSave[name] = {
            price = itemData.price,
            oldPrice = itemData.oldPrice
        }
    end
    SaveResourceFile(GetCurrentResourceName(), JSON_FILE, json.encode(dataToSave, { indent = true }), -1)
end

-- Khởi tạo dữ liệu tỷ giá hiện tại (price) và tỷ giá trước đó (oldPrice) từ prices.json & config.lua
local function InitItemPrices()
    local savedHistory = LoadPriceHistory()
    local shouldUpdateOnRestart = Config.UpdatePriceOnRestart ~= false

    for name, configVal in pairs(Config.ValuedItems) do
        local cfgPrice = type(configVal) == 'table' and (configVal.price or 0) or configVal

        if savedHistory[name] then
            local previousPrice = savedHistory[name].price or cfgPrice
            
            if shouldUpdateOnRestart then
                -- Mỗi lần restart resource: Lấy giá hiện tại trước đó làm oldPrice, rồi tạo giá mới ngẫu nhiên
                local minPct = Config.DynamicPrices and Config.DynamicPrices.minPercentChange or -15
                local maxPct = Config.DynamicPrices and Config.DynamicPrices.maxPercentChange or 15
                local randPct = math.random(minPct, maxPct) / 100.0
                local newPrice = math.max(100, math.floor(previousPrice * (1 + randPct)))

                ItemPrices[name] = {
                    price = newPrice,
                    oldPrice = previousPrice
                }
            else
                -- Giữ nguyên dữ liệu giá cũ và giá hiện tại đã lưu từ prices.json
                local savedOldPrice = savedHistory[name].oldPrice or previousPrice
                if previousPrice ~= cfgPrice then
                    ItemPrices[name] = {
                        price = cfgPrice,
                        oldPrice = previousPrice
                    }
                else
                    ItemPrices[name] = {
                        price = cfgPrice,
                        oldPrice = savedOldPrice
                    }
                end
            end
        else
            -- Nếu chưa có trong file JSON -> Khởi tạo lần đầu
            if shouldUpdateOnRestart then
                local minPct = Config.DynamicPrices and Config.DynamicPrices.minPercentChange or -15
                local maxPct = Config.DynamicPrices and Config.DynamicPrices.maxPercentChange or 15
                local randPct = math.random(minPct, maxPct) / 100.0
                local newPrice = math.max(100, math.floor(cfgPrice * (1 + randPct)))

                ItemPrices[name] = {
                    price = newPrice,
                    oldPrice = cfgPrice
                }
            else
                ItemPrices[name] = {
                    price = cfgPrice,
                    oldPrice = cfgPrice
                }
            end
        end
    end

    SavePriceHistory()
end

InitItemPrices()

-- Hàm helper lấy giá hiện tại và giá trước đó của vật phẩm
local function GetItemPriceData(itemName)
    if ItemPrices[itemName] then
        return ItemPrices[itemName].price, ItemPrices[itemName].oldPrice
    end
    
    local itemCfg = Config.ValuedItems[itemName]
    if not itemCfg then return 0, 0 end
    
    if type(itemCfg) == 'table' then
        return itemCfg.price or 0, itemCfg.oldPrice or itemCfg.price or 0
    end
    
    return itemCfg, itemCfg
end

local nextPriceUpdate = 0

-- Vòng lặp tự động cập nhật biến động tỷ giá thị trường theo thời gian (nếu enabled = true)
CreateThread(function()
    if not Config.DynamicPrices or not Config.DynamicPrices.enabled then return end
    
    local intervalMs = Config.DynamicPrices.interval or (30 * 60 * 1000)
    nextPriceUpdate = os.time() + math.floor(intervalMs / 1000)

    while true do
        Wait(intervalMs)
        nextPriceUpdate = os.time() + math.floor(intervalMs / 1000)

        for name, priceData in pairs(ItemPrices) do
            local currentPrice = priceData.price
            local minPct = Config.DynamicPrices.minPercentChange or -15
            local maxPct = Config.DynamicPrices.maxPercentChange or 15
            local randPct = math.random(minPct, maxPct) / 100.0
            
            local newPrice = math.max(100, math.floor(currentPrice * (1 + randPct)))
            ItemPrices[name] = {
                price = newPrice,
                oldPrice = currentPrice
            }
        end
        SavePriceHistory()
        TriggerClientEvent('gin_dinhgia:client:onPricesUpdated', -1)
    end
end)

local pendingExchanges = {}

-- Helper trao thưởng tự động cho các đơn đã trừ vật phẩm nếu người chơi ngắt kết nối hoặc đóng lock
local function GrantPendingReward(src)
    if pendingExchanges[src] then
        local payout = pendingExchanges[src].payout
        if payout and payout > 0 then
            local added = exports.ox_inventory:AddItem(src, Config.RewardAccount, payout)
            if not added and QBCore then
                local Player = QBCore.Functions.GetPlayer(src)
                if Player then
                    Player.Functions.AddMoney('cash', payout, "dinh-gia-vat-pham-auto")
                end
            end
        end
        pendingExchanges[src] = nil
    end
end

-- ==============================================================================
-- LOGIC KIỂM TRA KHUNG GIỜ HOẠT ĐỘNG ĐỒNG BỘ TRÊN SERVER (0ms, KHÔNG VÒNG LẶP)
-- ==============================================================================
local function GetServerTimeTable()
    local tzOffset = Config.TimeRestrictions and Config.TimeRestrictions.timezoneOffset
    if tzOffset then
        local utcTime = os.time(os.date("!*t"))
        return os.date("*t", utcTime + (tzOffset * 3600))
    else
        return os.date("*t")
    end
end

local function GetCurrentTimeMode()
    if not Config.TimeRestrictions or not Config.TimeRestrictions.enabled then
        return 'washing' -- Mở 24/7 nếu tắt cấu hình
    end

    local now = GetServerTimeTable()
    local currentMinutes = now.hour * 60 + now.min

    local function InRange(cfg)
        if not cfg then return false end
        local startTotal = (cfg.startHour or 0) * 60 + (cfg.startMinute or 0)
        local endTotal = (cfg.endHour or 0) * 60 + (cfg.endMinute or 0)
        if startTotal <= endTotal then
            return currentMinutes >= startTotal and currentMinutes < endTotal
        else
            -- Qua đêm (ví dụ 22h -> 2h)
            return currentMinutes >= startTotal or currentMinutes < endTotal
        end
    end

    -- Khung giờ rửa (20h00 - 23h00)
    if InRange(Config.TimeRestrictions.washing) then
        return 'washing'
    end

    -- Khung giờ định giá (14h00 - 15h00)
    if InRange(Config.TimeRestrictions.appraisal) then
        return 'appraisal'
    end

    return 'closed'
end

-- Lock tương tác (Chỉ 1 người tương tác cùng lúc & Kiểm tra khung giờ đóng/mở)
lib.callback.register('gin_dinhgia:server:requestLock', function(source)
    local currentMode = GetCurrentTimeMode()

    if currentMode == 'closed' then
        local appraisalLabel = Config.TimeRestrictions and Config.TimeRestrictions.appraisal and Config.TimeRestrictions.appraisal.label or '14:00 - 15:00'
        local washingLabel = Config.TimeRestrictions and Config.TimeRestrictions.washing and Config.TimeRestrictions.washing.label or '20:00 - 23:00'
        local msg = Config.TimeRestrictions and Config.TimeRestrictions.messages and Config.TimeRestrictions.messages.closed
            and string.format(Config.TimeRestrictions.messages.closed, appraisalLabel, washingLabel)
            or string.format("Bàn hiện đang đóng cửa!\nKhung giờ Định Giá: %s\nKhung giờ Rửa: %s", appraisalLabel, washingLabel)
        return false, msg, 'closed'
    end

    if activeUser ~= nil and activeUser ~= source then
        if GetPlayerPing(activeUser) > 0 then
            return false, "Khu vực định giá hiện đang có người khác sử dụng, vui lòng chờ!", currentMode
        else
            activeUser = nil
        end
    end
    activeUser = source
    return true, nil, currentMode
end)

-- Giải phóng lock khi đóng UI hoặc hủy bỏ
RegisterNetEvent('gin_dinhgia:server:releaseLock', function()
    local src = source
    if activeUser == src then
        GrantPendingReward(src)
        activeUser = nil
    end
end)

-- Tự động giải phóng lock khi người chơi disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if activeUser == src then
        GrantPendingReward(src)
        activeUser = nil
    end
end)

-- Lấy danh sách item hợp lệ trong túi đồ của người chơi cùng thời gian đếm ngược đổi giá
lib.callback.register('gin_dinhgia:server:getPlayerItems', function(source)
    local items = exports.ox_inventory:GetInventoryItems(source)
    local result = {}
    
    if not items then return { items = {}, nextUpdateIn = 0, dynamicEnabled = false, currentMode = GetCurrentTimeMode() } end

    -- Gom nhóm item theo name
    local grouped = {}
    for _, item in pairs(items) do
        if item and item.name and item.count and item.count > 0 then
            local price, oldPrice = GetItemPriceData(item.name)
            if price > 0 then
                if not grouped[item.name] then
                    grouped[item.name] = {
                        name = item.name,
                        label = item.label or item.name,
                        count = 0,
                        price = price,
                        oldPrice = oldPrice,
                        slot = item.slot
                    }
                end
                grouped[item.name].count = grouped[item.name].count + item.count
            end
        end
    end

    for _, itemData in pairs(grouped) do
        table.insert(result, itemData)
    end

    local isDynamic = Config.DynamicPrices and Config.DynamicPrices.enabled
    local remaining = (isDynamic and nextPriceUpdate > 0) and math.max(0, nextPriceUpdate - os.time()) or 0

    return {
        items = result,
        nextUpdateIn = remaining,
        dynamicEnabled = isDynamic,
        currentMode = GetCurrentTimeMode()
    }
end)

-- Bước 1: Chuẩn bị định giá (progressbar 100% xong -> TRỪ VẬT PHẨM KHỎI TÚI ĐỒ NGAY LẬP TỨC và mở UI kết quả)
lib.callback.register('gin_dinhgia:server:prepareExchange', function(source, slotItems)
    local src = source

    if activeUser ~= src then
        return { success = false, message = "Bạn không có quyền thao tác trên bàn này!" }
    end

    -- Bảo mật tuyệt đối trên Server: Kiểm tra khung giờ rửa
    local currentMode = GetCurrentTimeMode()
    if currentMode ~= 'washing' then
        local appraisalLabel = Config.TimeRestrictions and Config.TimeRestrictions.appraisal and Config.TimeRestrictions.appraisal.label or '14:00 - 15:00'
        local washingLabel = Config.TimeRestrictions and Config.TimeRestrictions.washing and Config.TimeRestrictions.washing.label or '20:00 - 23:00'
        local msg = Config.TimeRestrictions and Config.TimeRestrictions.messages and Config.TimeRestrictions.messages.appraisalOnly
            and string.format(Config.TimeRestrictions.messages.appraisalOnly, appraisalLabel, washingLabel)
            or string.format("Hiện tại là khung giờ Định Giá (%s)!\nBạn chỉ có thể xem giá trị vật phẩm, khung giờ Rửa tiền là: %s.", appraisalLabel, washingLabel)
        return { success = false, message = msg }
    end

    if not slotItems or type(slotItems) ~= 'table' then
        return { success = false, message = "Dữ liệu vật phẩm không hợp lệ!" }
    end

    local count = #slotItems
    if count < Config.MinItems or count > Config.MaxItems then
        return { 
            success = false, 
            message = string.format("Số lượng vật phẩm quy đổi phải từ %d đến %d món!", Config.MinItems, Config.MaxItems) 
        }
    end

    -- Kiểm tra người chơi có thực sự sở hữu các item này không
    local playerItems = exports.ox_inventory:GetInventoryItems(src)
    local itemCountMap = {}
    if playerItems then
        for _, item in pairs(playerItems) do
            if item and item.name and item.count then
                itemCountMap[item.name] = (itemCountMap[item.name] or 0) + item.count
            end
        end
    end

    local requiredCounts = {}
    local totalBaseValue = 0

    for _, item in ipairs(slotItems) do
        local price, _ = GetItemPriceData(item.name)
        if price <= 0 then
            return { success = false, message = "Vật phẩm quy đổi không có giá trị định giá!" }
        end
        requiredCounts[item.name] = (requiredCounts[item.name] or 0) + 1
        totalBaseValue = totalBaseValue + price
    end

    for name, reqCount in pairs(requiredCounts) do
        local owned = itemCountMap[name] or 0
        if owned < reqCount then
            return { 
                success = false, 
                message = string.format("Bạn không đủ số lượng vật phẩm: %s (Cần %d món, có %d món)", name, reqCount, owned) 
            }
        end
    end

    -- TRỪ VẬT PHẨM KHỎI TÚI ĐỒ NGAY LẬP TỨC
    for name, reqCount in pairs(requiredCounts) do
        local removed = exports.ox_inventory:RemoveItem(src, name, reqCount)
        if not removed then
            return { success = false, message = "Không thể trừ vật phẩm khỏi túi đồ!" }
        end
    end

    -- Tính số tiền payout ngẫu nhiên trong khoảng giá
    local minPayout = math.floor(totalBaseValue * Config.MinPayoutPercent)
    local maxPayout = math.floor(totalBaseValue * Config.MaxPayoutPercent)
    local finalPayout = math.random(minPayout, maxPayout)

    -- Lưu đơn quy đổi đã trừ item chờ người chơi bấm nhận tiền
    pendingExchanges[src] = {
        slotItems = slotItems,
        payout = finalPayout,
        timestamp = os.time()
    }

    return {
        success = true,
        amount = finalPayout,
        slotItems = slotItems
    }
end)

-- Bước 2: Người chơi bấm XÁC NHẬN NHẬN TIỀN trên UI -> Nhận tiền vào túi đồ
lib.callback.register('gin_dinhgia:server:claimReward', function(source)
    local src = source

    if activeUser ~= src then
        return { success = false, message = "Bạn không có quyền thao tác trên bàn này!" }
    end

    local exchangeData = pendingExchanges[src]
    if not exchangeData then
        return { success = false, message = "Không tìm thấy dữ liệu định giá chờ nhận thưởng!" }
    end

    local finalPayout = exchangeData.payout

    -- Cộng tiền vào túi đồ của người chơi
    local added = exports.ox_inventory:AddItem(src, Config.RewardAccount, finalPayout)
    if not added and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney('cash', finalPayout, "dinh-gia-vat-pham")
            added = true
        end
    end

    -- Giải phóng lock và dọn dẹp pending
    pendingExchanges[src] = nil
    activeUser = nil

    return {
        success = true,
        amount = finalPayout,
        message = string.format("Quy đổi thành công! Đã nhận $%s vào túi đồ.", lib.math.groupdigits(finalPayout) or tostring(finalPayout))
    }
end)

-- Lệnh Admin: Add tất cả vật phẩm trong Config.ValuedItems vào túi đồ (số lượng 5 mỗi item)
lib.addCommand('adddinhgia', {
    help = 'Add tất cả vật phẩm trong Config.ValuedItems vào túi đồ (Admin)',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID người chơi (Bỏ trống để add cho chính mình)',
            optional = true,
        },
    },
    restricted = 'group.admin'
}, function(source, args)
    local targetSrc = args.target or source
    if not targetSrc or targetSrc == 0 then return end

    local countAdded = 0
    for itemName, _ in pairs(Config.ValuedItems) do
        exports.ox_inventory:AddItem(targetSrc, itemName, 5)
        countAdded = countAdded + 1
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Admin Command',
        description = string.format("Đã thêm %d loại vật phẩm định giá (số lượng 5 mỗi món) vào túi đồ ID: %d!", countAdded, targetSrc),
        type = 'success'
    })
end)

-- Lệnh Admin: Thay đổi giá hiện tại của 1 item và tự động lưu giá cũ vào prices.json
lib.addCommand('setprice', {
    help = 'Đặt giá định giá mới cho vật phẩm và lưu lịch sử vào prices.json (Admin)',
    params = {
        { name = 'item', type = 'string', help = 'Tên item (ví dụ: iron, gold)' },
        { name = 'price', type = 'number', help = 'Giá mới' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local itemName = args.item
    local newPrice = args.price

    if not Config.ValuedItems[itemName] then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Lỗi', description = 'Vật phẩm không nằm trong Config.ValuedItems!', type = 'error' })
        return
    end

    local currentPrice = ItemPrices[itemName] and ItemPrices[itemName].price or newPrice
    ItemPrices[itemName] = {
        price = newPrice,
        oldPrice = currentPrice
    }
    SavePriceHistory()

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Cập nhật giá thành công',
        description = string.format("Vật phẩm '%s': Giá cũ $%s -> Giá mới $%s (Đã lưu vào prices.json)", itemName, lib.math.groupdigits(currentPrice), lib.math.groupdigits(newPrice)),
        type = 'success'
    })
end)

-- Lệnh Admin: Tạo biến động giá ngẫu nhiên cho tất cả vật phẩm và cập nhật prices.json
lib.addCommand('updateprices', {
    help = 'Tự động tạo biến động tỷ giá ngẫu nhiên cho tất cả vật phẩm và lưu prices.json (Admin)',
    restricted = 'group.admin'
}, function(source, args)
    for name, priceData in pairs(ItemPrices) do
        local currentPrice = priceData.price
        local minPct = Config.DynamicPrices and Config.DynamicPrices.minPercentChange or -15
        local maxPct = Config.DynamicPrices and Config.DynamicPrices.maxPercentChange or 15
        local randPct = math.random(minPct, maxPct) / 100.0
        
        local newPrice = math.max(100, math.floor(currentPrice * (1 + randPct)))
        ItemPrices[name] = {
            price = newPrice,
            oldPrice = currentPrice
        }
    end
    SavePriceHistory()

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Cập Nhật Tỷ Giá',
        description = 'Đã tạo biến động tỷ giá ngẫu nhiên cho toàn bộ vật phẩm và lưu vào prices.json!',
        type = 'success'
    })
end)

-- Lệnh kiểm tra khung giờ hoạt động định giá & rửa tiền hiện tại của server
lib.addCommand('checkdinhgia', {
    help = 'Kiểm tra giờ máy chủ và trạng thái bàn Định Giá & Rửa tiền',
}, function(source)
    local now = GetServerTimeTable()
    local mode = GetCurrentTimeMode()
    local appraisalLabel = Config.TimeRestrictions and Config.TimeRestrictions.appraisal and Config.TimeRestrictions.appraisal.label or '14:00 - 15:00'
    local washingLabel = Config.TimeRestrictions and Config.TimeRestrictions.washing and Config.TimeRestrictions.washing.label or '20:00 - 23:00'

    local statusText = "ĐANG ĐÓNG CỬA"
    local notifType = 'inform'
    if mode == 'washing' then
        statusText = "ĐANG MỞ: GIỜ RỬA TIỀN (Được quy đổi)"
        notifType = 'success'
    elseif mode == 'appraisal' then
        statusText = "ĐANG MỞ: GIỜ ĐỊNH GIÁ (Chỉ xem giá, chưa được rửa)"
        notifType = 'warning'
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Bàn Định Giá & Rửa',
        description = string.format("Giờ Server: %02d:%02d\nTrạng thái: %s\n- Giờ Định Giá: %s\n- Giờ Rửa: %s", 
            now.hour, now.min, statusText, appraisalLabel, washingLabel
        ),
        type = notifType
    })
end)


