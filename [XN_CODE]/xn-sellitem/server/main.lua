local QBCore = exports['qb-core']:GetCoreObject()
DATA = {}
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

-- Export function để lấy DATA từ các resource khác
exports('GetDATA', function()
    return DATA
end)

QBCore.Functions.CreateCallback('xn-sellitem:server:nCheckItem', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local Item_GoiY_1 = Player.Functions.GetItemByName("note_1")
    local Item_GoiY_3 = Player.Functions.GetItemByName("note_3")
    if Item_GoiY_1 ~= nil and Item_GoiY_3 ~= nil then
        if Item_GoiY_1.amount >= 1 and Item_GoiY_3.amount >= 1 then
            cb(true)
		else
            cb(false)
		end
	else
        cb(false)
	end
end)

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function tableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Tính 6 bước giá từ Min đến Max
function GetPriceSteps(min, max)
    local step1 = min
    local step2 = round(min + (max - min) / 5)
    local step3 = round(min + (max - min) * 2 / 5)
    local step4 = round(min + (max - min) * 3 / 5)
    local step5 = round(min + (max - min) * 4 / 5)
    local step6 = max
    return {step1, step2, step3, step4, step5, step6}
end

-- Random giá từ 6 bước, có thể loại trừ giá hiện tại
function RandomPriceFromSteps(steps, excludePrice)
    local availableSteps = {}
    for _, price in ipairs(steps) do
        if not excludePrice or price ~= excludePrice then
            table.insert(availableSteps, price)
        end
    end
    
    if #availableSteps > 0 then
        math.randomseed(os.time() + math.random(1, 1000))
        return availableSteps[math.random(1, #availableSteps)]
    else
        -- Nếu không có bước nào khác, trả về bước đầu tiên
        return steps[1]
    end
end

-- Tìm bước giá gần nhất với một giá cho trước
function SnapToNearestStep(price, steps)
    local nearest = steps[1]
    local minDiff = math.abs(price - steps[1])
    
    for _, step in ipairs(steps) do
        local diff = math.abs(price - step)
        if diff < minDiff then
            minDiff = diff
            nearest = step
        end
    end
    
    return nearest
end

-- @run Making a price
-- @function InitEconomy
function InitEconomy()
    DATA = {}
    -- print("^2[SELLITEM]^7 Starting InitEconomy...")
    
    MySQL.ready(function()
        -- print("^2[SELLITEM]^7 MySQL ready, loading items...")
        
        -- Đợi database config load xong
        Citizen.Wait(2000)
        
        -- Bước 1: Load tất cả items từ Config.Items
        for k, v in pairs(Config.Items) do
            local categoryName = k
            -- print("^3[SELLITEM]^7 Loading category from Config: "..categoryName)
            
            local itemIndex = 0
            for j, b in pairs(v) do
                itemIndex = itemIndex + 1
                local itemName = j
                local itemData = b
                
                -- Ưu tiên dùng config từ database nếu có
                local dbConfig = DatabaseConfig[categoryName] and DatabaseConfig[categoryName][itemName]
                
                local amountToChange = (dbConfig and dbConfig.AmountToChange and dbConfig.AmountToChange > 0 and dbConfig.AmountToChange) or (itemData.AmountToChange and itemData.AmountToChange > 0 and itemData.AmountToChange) or 50
                local rangeChange = (dbConfig and dbConfig.RangeChange) or itemData.RangeChange or {1, 4}

                local newData = {
                    Price = 0,
                    Min = dbConfig and dbConfig.Min or itemData.Min,
                    Max = dbConfig and dbConfig.Max or itemData.Max,
                    RangeChange = rangeChange,
                    AmountToChange = amountToChange,
                    CurrentAmount = 0,
                    Label = dbConfig and dbConfig.Label or itemData.Label,
                    Status = 'equal',
                    Category = categoryName, -- Lưu category để dùng sau
                    Cooldown = itemData.Cooldown
                }

                -- Kiểm tra xem có nên dùng giá từ database không
                local useDbPrice = false
                local priceSteps = GetPriceSteps(newData.Min, newData.Max)
                
                if dbConfig and dbConfig.CurrentPrice and dbConfig.CurrentPrice > 0 then
                    -- Snap giá database về bước gần nhất trong 6 bước
                    newData.Price = SnapToNearestStep(dbConfig.CurrentPrice, priceSteps)
                    useDbPrice = true
                end
                
                if not useDbPrice then
                    -- Random giá theo 6 bước cố định từ Min đến Max
                    newData.Price = RandomPriceFromSteps(priceSteps, nil)
                end
                
                -- Lưu giá đã snap/random vào DB để restart lần sau tải đúng
                if dbConfig then
                    UpdateItemPrice(categoryName, itemName, newData.Price)
                end

                local center = round((newData.Min + newData.Max) / 2)
                if newData.Price > center then
                    newData.Status = 'up'
                elseif newData.Price < center then
                    newData.Status = 'down'
                else
                    newData.Status = 'equal'
                end

                DATA[itemName] = newData
                ---- print("^2[SELLITEM]^7 Loaded item: "..itemName.." - Price: $"..newData.Price.." - Status: "..newData.Status)
            end
        end
        
        -- Bước 2: Load items từ database mà KHÔNG có trong Config (items mới được tạo qua admin)
        -- print("^3[SELLITEM]^7 Checking for database-only items...")
        for categoryName, categoryItems in pairs(DatabaseConfig) do
            for itemName, dbConfig in pairs(categoryItems) do
                -- Nếu item này chưa có trong DATA (nghĩa là không có trong Config.Items)
                if not DATA[itemName] then
                    -- print("^2[SELLITEM]^7 Found database-only item: "..itemName.." in category: "..categoryName)
                    
                    -- Thêm vào Config.Items runtime
                    if not Config.Items[categoryName] then
                        Config.Items[categoryName] = {}
                    end
                    
                    Config.Items[categoryName][itemName] = {
                        Label = dbConfig.Label,
                        Min = dbConfig.Min,
                        Max = dbConfig.Max,
                        RandomWhenStart = dbConfig.RandomWhenStart,
                        RangeChange = dbConfig.RangeChange,
                        AmountToChange = dbConfig.AmountToChange
                    }
                    
                    -- Thêm vào DATA
                    local priceSteps = GetPriceSteps(dbConfig.Min, dbConfig.Max)
                    local price
                    
                    -- Nếu có CurrentPrice trong DB, snap về bước gần nhất
                    if dbConfig.CurrentPrice and dbConfig.CurrentPrice > 0 then
                        price = SnapToNearestStep(dbConfig.CurrentPrice, priceSteps)
                    else
                        price = RandomPriceFromSteps(priceSteps, nil)
                    end
                    
                    local amountToChange = (dbConfig.AmountToChange and dbConfig.AmountToChange > 0 and dbConfig.AmountToChange) or 50
                    local rangeChange = dbConfig.RangeChange or {1, 4}

                    local newData = {
                        Price = price,
                        Min = dbConfig.Min,
                        Max = dbConfig.Max,
                        RangeChange = rangeChange,
                        AmountToChange = amountToChange,
                        CurrentAmount = 0,
                        Label = dbConfig.Label,
                        Status = 'equal',
                        Category = categoryName -- Fix: cần có Category để UpdateLeaderboard hoạt động
                    }
                    
                    -- Tính status
                    local center = round((newData.Min + newData.Max) / 2)
                    if newData.Price > center then
                        newData.Status = 'up'
                    elseif newData.Price < center then
                        newData.Status = 'down'
                    else
                        newData.Status = 'equal'
                    end
                    
                    DATA[itemName] = newData
                    
                    -- Cập nhật locations
                    for k, location in pairs(Config.Locations) do
                        if location.Items == Config.Items[categoryName] then
                            -- print("^2[SELLITEM]^7 Added "..itemName.." to location: "..location.NPCText)
                        end
                    end
                    
                    -- print("^2[SELLITEM]^7 Loaded database item: "..itemName.." - Price: $"..newData.Price)
                end
            end
        end
        
        -- print("^2[SELLITEM]^7 Economy initialized with "..tableLength(DATA).." items")
        
        -- Bước 3: Auto-sync items từ Config vào database nếu chưa tồn tại
        -- Đảm bảo DatabaseConfig đã được load (đợi thêm nếu cần)
        local waitCount = 0
        while not DatabaseConfig or not next(DatabaseConfig) do
            if waitCount > 10 then
                print("^1[SELLITEM]^7 WARNING: DatabaseConfig not loaded after 5 seconds!")
                break
            end
            Wait(500)
            waitCount = waitCount + 1
        end
        
        print("^3[SELLITEM]^7 Syncing Config.Items to database...")
        print("^3[SELLITEM]^7 DatabaseConfig has "..tableLength(DatabaseConfig).." categories")
        
        local syncCount = 0
        for categoryName, categoryItems in pairs(Config.Items) do
            print("^3[SELLITEM]^7 Checking category: "..categoryName.." with "..tableLength(categoryItems).." items")
            
            for itemName, itemData in pairs(categoryItems) do
                -- Kiểm tra xem item đã có trong database chưa
                local existsInDb = DatabaseConfig[categoryName] and DatabaseConfig[categoryName][itemName]
                
                if not existsInDb then
                    print("^2[SELLITEM]^7 Creating missing item in database: "..itemName.." (Category: "..categoryName..")")
                    
                    -- Lấy giá hiện tại từ DATA (đã được random trong bước 1)
                    local priceSteps = GetPriceSteps(itemData.Min, itemData.Max)
                    local currentPrice = DATA[itemName] and DATA[itemName].Price or RandomPriceFromSteps(priceSteps, nil)
                    
                    -- Tạo item vào database
                    local success = CreateItemConfig(categoryName, itemName, itemData, currentPrice)
                    
                    if success then
                        syncCount = syncCount + 1
                        print("^2[SELLITEM]^7 ✓ Successfully created: "..itemName)
                    else
                        print("^1[SELLITEM]^7 ✗ Failed to create item: "..itemName)
                    end
                    
                    Wait(100) -- Delay để đảm bảo database writes
                else
                    -- print("^7[SELLITEM]^7 Item already exists: "..itemName)
                end
            end
        end
        
        if syncCount > 0 then
            print("^2[SELLITEM]^7 ========================================")
            print("^2[SELLITEM]^7 Database sync completed: "..syncCount.." new items created")
            print("^2[SELLITEM]^7 ========================================")
            -- Rebuild admin cache sau khi sync
            Wait(500)
            BuildAdminItemsCache()
            print("^2[SELLITEM]^7 Admin cache rebuilt with new items")
        else
            print("^2[SELLITEM]^7 No new items to sync - all items exist in database")
        end
        
        -- Sau khi tất cả DATA đã được populate, rebuild admin cache với giá đúng
        BuildAdminItemsCache()
        
        -- Gửi Config.Items đã update cho tất cả clients
        Citizen.Wait(1000)
        -- print("^3[SELLITEM]^7 Broadcasting Config.Items to all clients...")
        local totalCategories = 0
        for category, items in pairs(Config.Items) do
            totalCategories = totalCategories + 1
            local categoryItemCount = 0
            for _ in pairs(items) do categoryItemCount = categoryItemCount + 1 end
            -- print("^3[SELLITEM]^7 Category: "..category.." - Items: "..categoryItemCount)
        end
        TriggerClientEvent('xn-sellitem:syncAllItems', -1, Config.Items)
        -- print("^2[SELLITEM]^7 Config sync completed for all clients")
    end)

    if Config.TuDong_ThayDoiGia then
        -- @thread For Environment Looping
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(Config.ThoiGian_CapNhat * 60000)
                for k, v in pairs(DATA) do
                    Wait(100)
                    
                    local oldPrice = DATA[k].Price
                    
                    -- Tính 6 bước giá
                    local priceSteps = GetPriceSteps(DATA[k].Min, DATA[k].Max)
                    
                    -- Random giá mới từ 6 bước, TRỪ giá hiện tại
                    DATA[k].Price = RandomPriceFromSteps(priceSteps, oldPrice)

                    local center = round((DATA[k].Min + DATA[k].Max) / 2)
                    if DATA[k].Price > center then
                        DATA[k].Status = 'up'
                    elseif DATA[k].Price < center then
                        DATA[k].Status = 'down'
                    else
                        DATA[k].Status = 'equal'
                    end
                    
                    DATA[k].CurrentAmount = 0
                    
                    -- Lưu giá mới vào database
                    if DATA[k].Category then
                        UpdateItemPrice(DATA[k].Category, k, DATA[k].Price)
                    end
                end

                -- @send Update all prices for all users
                TriggerClientEvent('xn-sellitem:setPrices', -1, DATA)
                
                -- Thông báo cho tất cả người chơi
                TriggerClientEvent('QBCore:Notify', -1, '📊 Có biến động giá cả thị trường!', 'primary', 5000)

                -- TriggerClientEvent("chat:addMessage", -1, {
                --     type = "NGƯỜI THU MUA",
                --     typeColor = "#ffad94",
                --     header = "THỊ TRƯỜNG BIẾN ĐỔI",
                --     args = { "Thị trường vừa có sự biến đổi. Tòa Thị Chính đã cập nhật giá mới cho toàn thể Cư Dân của Thành phố" }
                -- })
            end
        end)
    end
    -- ---- print('Setup World Economics')
end

InitEconomy()

-- Helper function để tìm vị trí bán hàng
local function GetLocationName(playerCoords)
    for k, v in pairs(Config.Locations) do
        local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(v.Coords.x, v.Coords.y, v.Coords.z))
        if distance < 10.0 then
            return v.NPCText
        end
    end
    return 'Unknown Location'
end

-- Helper function để update leaderboard
local function UpdateLeaderboard(citizenId, playerName, category, points)
    if not citizenId or not category or not points or points <= 0 then
        return
    end
    
    MySQL.Async.fetchScalar('SELECT points FROM xn_sellitem_leaderboard WHERE citizen_id = @citizenId AND category = @category', {
        ['@citizenId'] = citizenId,
        ['@category'] = category
    }, function(currentPoints)
        local newPoints = (currentPoints or 0) + points
        
        MySQL.Async.execute([[
            INSERT INTO xn_sellitem_leaderboard (citizen_id, player_name, category, points, last_updated) 
            VALUES (@citizenId, @playerName, @category, @points, NOW())
            ON DUPLICATE KEY UPDATE 
                points = @points,
                player_name = @playerName,
                last_updated = NOW()
        ]], {
            ['@citizenId'] = citizenId,
            ['@playerName'] = playerName,
            ['@category'] = category,
            ['@points'] = newPoints
        }, function()
            TriggerEvent('xn-sellitem:leaderboardUpdated', category)
        end)
    end)
end

local function GetPoliceCount()
    return GlobalState['police_count'] or 0
end

local SellCooldowns = {}

-- Helper function to check item cooldown
-- Returns: canSell (boolean), allowedAmount (number or nil), message (string or nil)
local function CheckItemCooldown(citizenId, item, requestedAmount, itemEco)
    if not itemEco or not itemEco.Cooldown then
        return true, requestedAmount, nil
    end

    local cooldownConfig = itemEco.Cooldown
    local maxAmount = cooldownConfig.MaxAmount or 100
    local duration = (cooldownConfig.Duration or 15) * 60 -- convert to seconds

    if not SellCooldowns[citizenId] then
        SellCooldowns[citizenId] = {}
    end

    if not SellCooldowns[citizenId][item] then
        SellCooldowns[citizenId][item] = {
            amount = 0,
            resetTime = 0
        }
    end

    local record = SellCooldowns[citizenId][item]
    local currentTime = os.time()

    -- Reset cooldown if time is up
    if currentTime >= record.resetTime then
        record.amount = 0
        record.resetTime = 0
    end

    local remainingQuota = maxAmount - record.amount
    if remainingQuota <= 0 then
        local timeRemaining = record.resetTime - currentTime
        local minutes = math.floor(timeRemaining / 60)
        local seconds = timeRemaining % 60
        local timeStr = ""
        if minutes > 0 then
            timeStr = string.format("%d phút %d giây", minutes, seconds)
        else
            timeStr = string.format("%d giây", seconds)
        end
        return false, 0, string.format("Bạn đã đạt giới hạn bán %s (tối đa %d cái/%d phút). Vui lòng đợi %s.", itemEco.Label, maxAmount, cooldownConfig.Duration, timeStr)
    end

    if requestedAmount > remainingQuota then
        return false, remainingQuota, string.format("Bạn chỉ có thể bán thêm tối đa %d cái %s trong lượt này. Vui lòng đợi %s hoặc giảm số lượng.", remainingQuota, itemEco.Label, record.resetTime > 0 and string.format("%d phút", math.ceil((record.resetTime - currentTime) / 60)) or string.format("%d phút", cooldownConfig.Duration))
    end

    return true, requestedAmount, nil
end

local function CommitItemCooldown(citizenId, item, amount, itemEco)
    if not itemEco or not itemEco.Cooldown then
        return
    end

    local cooldownConfig = itemEco.Cooldown
    local duration = (cooldownConfig.Duration or 15) * 60 -- convert to seconds

    if not SellCooldowns[citizenId] then
        SellCooldowns[citizenId] = {}
    end

    if not SellCooldowns[citizenId][item] then
        SellCooldowns[citizenId][item] = {
            amount = 0,
            resetTime = 0
        }
    end

    local record = SellCooldowns[citizenId][item]
    local currentTime = os.time()

    if record.amount == 0 then
        record.resetTime = currentTime + duration
    end

    record.amount = record.amount + amount
end

local function ProcessPriceDropOnSell(itemName, amountSold)
    local itemData = DATA[itemName]
    if not itemData then return end

    -- Tăng amount_sold trong database
    UpdateItemAmountSold(itemData.Category, itemName, amountSold)

    -- Đảm bảo CurrentAmount tồn tại
    if not itemData.CurrentAmount then
        itemData.CurrentAmount = 0
    end
    itemData.CurrentAmount = itemData.CurrentAmount + amountSold

    local amountToChange = tonumber(itemData.AmountToChange)
    if not amountToChange or amountToChange <= 0 then
        amountToChange = 50
        itemData.AmountToChange = 50
    end

    local rangeChange = itemData.RangeChange
    if type(rangeChange) ~= 'table' or not rangeChange[1] or not rangeChange[2] then
        rangeChange = {1, 4}
    end

    -- Chỉ thực hiện giảm giá khi tích lũy đủ số lượng yêu cầu (CurrentAmount >= amountToChange)
    if itemData.CurrentAmount < amountToChange then
        return
    end

    local priceChanged = false
    while itemData.CurrentAmount >= amountToChange do
        itemData.CurrentAmount = itemData.CurrentAmount - amountToChange
        
        -- Random lượng giảm giá
        math.randomseed(os.time() + math.random(1, 1000))
        local dropPrice = math.random(rangeChange[1], rangeChange[2])
        
        -- Giảm giá
        local newPrice = itemData.Price - dropPrice
        if newPrice < itemData.Min then
            newPrice = itemData.Min
        end

        if itemData.Price ~= newPrice then
            itemData.Price = newPrice
            priceChanged = true
        else
            break -- Nếu giá đã ở Min và không thể giảm thêm
        end
    end

    if priceChanged then
        -- Cập nhật status
        local center = round((itemData.Min + itemData.Max) / 2)
        if itemData.Price > center then
            itemData.Status = 'up'
        elseif itemData.Price < center then
            itemData.Status = 'down'
        else
            itemData.Status = 'equal'
        end

        -- Lưu giá mới vào database
        if itemData.Category then
            UpdateItemPrice(itemData.Category, itemName, itemData.Price)
        end

        -- Gửi update cho tất cả client
        TriggerClientEvent('xn-sellitem:update', -1, itemName, itemData)
    end
end

local PendingRouletteSales, PendingRoulettePayouts = {}, {}

local function AddCashWithFallback(xPlayer, amount, reason)
    if amount <= 0 then return true end

    local moneyAdded = xPlayer.Functions.AddMoney('cash', amount, reason)
    if not moneyAdded or moneyAdded == false then
        xPlayer.Functions.SetMoney('cash', (xPlayer.PlayerData.money.cash or 0) + amount)
    end
    return true
end

local function IsPlayerNearSellCategory(playerId, category, maxDistance)
    if not category or not Config.Items[category] then return false end
    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 then return false end

    local playerCoords = GetEntityCoords(playerPed)
    for _, location in pairs(Config.Locations) do
        if location.Items == Config.Items[category] or location.ExtraItems == Config.Items[category] then
            local locationCoords = vector3(location.Coords.x, location.Coords.y, location.Coords.z)
            if #(playerCoords - locationCoords) <= (maxDistance or 5.0) then
                return true
            end
        end
    end

    return false
end

local function BuildRouletteRedSet()
    local redSet = {}
    local redNumbers = Config.RouletteSell and Config.RouletteSell.RedNumbers or {}
    for _, number in ipairs(redNumbers) do
        redSet[number] = true
    end
    return redSet
end

local RouletteRedSet = BuildRouletteRedSet()

local function BuildRouletteBlackNumbers()
    local blackNumbers = {}
    for number = 1, 36 do
        if not RouletteRedSet[number] then
            blackNumbers[#blackNumbers + 1] = number
        end
    end
    return blackNumbers
end

local RouletteBlackNumbers = BuildRouletteBlackNumbers()

local function GetRouletteResultColor(result)
    if result == 37 or result == 38 then return 'green' end
    return RouletteRedSet[result] and 'red' or 'black'
end

local function GetRouletteResultLabel(result)
    if result == 37 then return '0' end
    if result == 38 then return '00' end
    return tostring(result)
end

local function ClampNumber(value, min, max)
    value = tonumber(value) or min
    if value < min then return min end
    if value > max then return max end
    return value
end

local function GetRandomRouletteNumberByColor(color)
    if color == 'red' then
        local redNumbers = Config.RouletteSell and Config.RouletteSell.RedNumbers or {}
        return redNumbers[math.random(1, #redNumbers)]
    end

    return RouletteBlackNumbers[math.random(1, #RouletteBlackNumbers)]
end

local function RollRouletteSaleOutcome(choice)
    local winChance = ClampNumber(Config.RouletteSell and Config.RouletteSell.WinChance, 0, 100)
    local zeroChanceOnLose = ClampNumber(Config.RouletteSell and Config.RouletteSell.ZeroChanceOnLose, 0, 100)
    local win = (math.random() * 100) <= winChance
    local result

    if win then
        result = GetRandomRouletteNumberByColor(choice)
    elseif (math.random() * 100) <= zeroChanceOnLose then
        result = math.random(37, 38)
    else
        result = GetRandomRouletteNumberByColor(choice == 'red' and 'black' or 'red')
    end

    local resultColor = GetRouletteResultColor(result)
    return result, resultColor, resultColor == choice
end

local function FinishRoulettePayout(playerId)
    local payout = PendingRoulettePayouts[playerId]
    if not payout or payout.paid then return end

    local now = os.time()
    if payout.earliestPayAt and now < payout.earliestPayAt then
        Wait((payout.earliestPayAt - now) * 1000)
        payout = PendingRoulettePayouts[playerId]
        if not payout or payout.paid then return end
    end

    payout.paid = true
    PendingRoulettePayouts[playerId] = nil

    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    if not xPlayer then return end

    if payout.reward > 0 then
        AddCashWithFallback(xPlayer, payout.reward, 'Roulette x2 bán `x'..payout.amount..' '..payout.label..'` tại Người Thu Mua')

        if payout.category then
            local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
            UpdateLeaderboard(xPlayer.PlayerData.citizenid, playerName, payout.category, payout.reward)
        end
    end

    TriggerClientEvent('xn-sellitem:client:roulettePayout', playerId, payout)
end

local function ValidateRouletteSaleRequest(playerId, item, amount, sellAll)
    if not Config.RouletteSell or not Config.RouletteSell.Enable then
        return false, "Roulette bán hàng đang tắt"
    end

    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    if not xPlayer then return false, nil end

    local itemEco = DATA[item]
    if not itemEco then
        return false, "Item này không thể bán tại đây"
    end

    local rouletteCategory = Config.RouletteSell.Category or 'fish'
    if itemEco.Category ~= rouletteCategory then
        return false, "Roulette x2 hiện chỉ áp dụng cho Hải Sản"
    end

    if not IsPlayerNearSellCategory(playerId, rouletteCategory, 5.0) then
        return false, "Bạn phải đứng gần Người Thu Mua Hải Sản để thử vận may"
    end

    local itemTarget = xPlayer.Functions.GetItemByName(item)
    if not itemTarget then
        return false, "Bạn không có vật phẩm này để bán"
    end

    local sellAmount = sellAll and itemTarget.amount or tonumber(amount)
    if not sellAmount or sellAmount <= 0 then
        return false, "Số lượng không hợp lệ"
    end

    local citizenId = xPlayer.PlayerData.citizenid
    local canSell, allowedAmount, errMessage = CheckItemCooldown(citizenId, item, sellAmount, itemEco)
    if not canSell then
        if sellAll and allowedAmount and allowedAmount > 0 then
            sellAmount = allowedAmount
            TriggerClientEvent("QBCore:Notify", playerId, string.format("Bạn chỉ có thể bán tối đa %d cái %s. Đã điều chỉnh số lượng.", sellAmount, itemEco.Label), "primary")
        else
            return false, errMessage
        end
    end

    if itemTarget.amount < sellAmount then
        return false, "Hiện tại trong túi đồ chỉ có: x"..itemTarget.amount.." "..itemTarget.label.." mà muốn bán x"..sellAmount.." "..itemTarget.label.." sao?"
    end

    return true, {
        xPlayer = xPlayer,
        itemTarget = itemTarget,
        itemEco = itemEco,
        amount = sellAmount,
        citizenId = citizenId
    }
end

local function StartRouletteSale(playerId, item, amount, sellAll)
    local pending = PendingRouletteSales[playerId]
    if pending and pending.expiresAt and pending.expiresAt > os.time() then
        TriggerClientEvent("QBCore:Notify", playerId, "Bạn đang có một lượt roulette bán hàng chưa hoàn tất", "error")
        return
    end

    local valid, result = ValidateRouletteSaleRequest(playerId, item, amount, sellAll)
    if not valid then
        if result then TriggerClientEvent("QBCore:Notify", playerId, result, "error") end
        return
    end

    local timeout = tonumber(Config.RouletteSell.Timeout) or 30
    local basePrice = math.abs(result.itemEco.Price * result.amount)

    PendingRouletteSales[playerId] = {
        item = item,
        amount = result.amount,
        itemLabel = result.itemTarget.label,
        unitPrice = result.itemEco.Price,
        basePrice = basePrice,
        category = result.itemEco.Category,
        expiresAt = os.time() + timeout
    }

    TriggerClientEvent('xn-sellitem:client:rouletteStart', playerId, {
        item = item,
        label = result.itemTarget.label,
        amount = result.amount,
        basePrice = basePrice,
        multiplier = Config.RouletteSell.Multiplier or 2,
        timeout = timeout
    })
end

exports['monitors']:RegisterProtectedEvent('xn-sellitem:cfx:roulette-action-all', function(playerId, item)
    StartRouletteSale(playerId, item, nil, true)
end)

exports['monitors']:RegisterProtectedEvent('xn-sellitem:cfx:roulette-cancel', function(playerId)
    PendingRouletteSales[playerId] = nil
end)

exports['monitors']:RegisterProtectedEvent('xn-sellitem:cfx:roulette-choice', function(playerId, choice)
    if choice ~= 'red' and choice ~= 'black' then return end

    local pending = PendingRouletteSales[playerId]
    PendingRouletteSales[playerId] = nil

    if not pending then
        TriggerClientEvent('xn-sellitem:client:rouletteAbort', playerId, "Không tìm thấy lượt roulette bán hàng")
        return
    end

    if pending.expiresAt < os.time() then
        TriggerClientEvent('xn-sellitem:client:rouletteAbort', playerId, "Lượt roulette đã hết hạn")
        return
    end

    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    if not xPlayer then return end

    local itemEco = DATA[pending.item]
    local itemTarget = xPlayer.Functions.GetItemByName(pending.item)
    if not itemEco or not itemTarget or itemTarget.amount < pending.amount then
        TriggerClientEvent('xn-sellitem:client:rouletteAbort', playerId, "Bạn không còn đủ vật phẩm để hoàn tất roulette")
        return
    end

    local result, resultColor, win = RollRouletteSaleOutcome(choice)
    local multiplier = Config.RouletteSell.Multiplier or 2
    local reward = win and math.abs(pending.basePrice * multiplier) or 0

    if xPlayer.Functions.RemoveItem(pending.item, pending.amount) then
        local citizenId = xPlayer.PlayerData.citizenid
        CommitItemCooldown(citizenId, pending.item, pending.amount, itemEco)
        ProcessPriceDropOnSell(pending.item, pending.amount)

        TriggerClientEvent('inventory:client:ItemBox', playerId, QBCore.Shared.Items[pending.item], 'remove')
        TriggerClientEvent('alive_quest:action', playerId, 'sell_' .. pending.item, pending.amount)

        PendingRoulettePayouts[playerId] = {
            item = pending.item,
            label = pending.itemLabel,
            amount = pending.amount,
            basePrice = pending.basePrice,
            reward = reward,
            multiplier = multiplier,
            result = result,
            resultLabel = GetRouletteResultLabel(result),
            resultColor = resultColor,
            chosen = choice,
            win = win,
            category = itemEco.Category,
            earliestPayAt = os.time() + (tonumber(Config.RouletteSell.PayoutDelay) or 16),
            paid = false
        }

        TriggerClientEvent('xn-sellitem:client:rouletteResult', playerId, {
            item = pending.item,
            label = pending.itemLabel,
            amount = pending.amount,
            basePrice = pending.basePrice,
            reward = reward,
            multiplier = multiplier,
            result = result,
            resultLabel = GetRouletteResultLabel(result),
            resultColor = resultColor,
            chosen = choice,
            win = win
        })

        CreateThread(function()
            Wait((tonumber(Config.RouletteSell.ForcePayoutAfter) or 30) * 1000)
            FinishRoulettePayout(playerId)
        end)
    else
        TriggerClientEvent('xn-sellitem:client:rouletteAbort', playerId, "Không thể xóa item khỏi túi đồ")
    end
end)

exports['monitors']:RegisterProtectedEvent('xn-sellitem:cfx:roulette-finished', function(playerId)
    FinishRoulettePayout(playerId)
end)

AddEventHandler('playerDropped', function()
    PendingRouletteSales[source] = nil
    PendingRoulettePayouts[source] = nil
end)

exports['monitors']:RegisterProtectedEvent('xn-sellitem:cfx:action', function(playerId, item, amount)
    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    
    ---- print("^3[SELLITEM DEBUG]^7 Player "..playerId.." trying to sell "..tostring(amount).." of "..tostring(item))
    
    -- Kiểm tra player hợp lệ
    if not xPlayer then
        ---- print("^1[SELLITEM ERROR]^7 Player not found")
        return
    end
    
    local itemTarget = xPlayer.Functions.GetItemByName(item)
    local itemEco = DATA[item]

    ---- print("^3[SELLITEM DEBUG]^7 ItemTarget:", itemTarget ~= nil, "ItemEco:", itemEco ~= nil)

    -- Kiểm tra item có trong config không
    if not itemEco then
        ---- print("^1[SELLITEM ERROR]^7 Item not found in config: "..tostring(item))
        TriggerClientEvent("QBCore:Notify", playerId, "Item này không thể bán tại đây", "error")
        return
    end

    if not IsPlayerNearSellCategory(playerId, itemEco.Category, 5.0) then
        TriggerClientEvent("QBCore:Notify", playerId, "Bạn phải đứng gần đúng người thu mua để bán vật phẩm này", "error")
        return
    end

    -- Kiểm tra điều kiện Cảnh sát cho Chợ Đen (choden)
    if itemEco.Category == 'choden' then
        local policeCount = GetPoliceCount()
        local requiredCops = Config.ChodenRequiredCops or 3
        if policeCount < requiredCops then
            TriggerClientEvent("QBCore:Notify", playerId, string.format("Chợ Đen chỉ hoạt động khi có tối thiểu %d cảnh sát online!", requiredCops), "error")
            return
        end
    end

    -- Kiểm tra item có trong inventory không
    if not itemTarget then
        ---- print("^1[SELLITEM ERROR]^7 Item not found in inventory: "..tostring(item))
        TriggerClientEvent("QBCore:Notify", playerId, "Bạn không có vật phẩm này để bán", "error")
        return
    end

    ---- print("^3[SELLITEM DEBUG]^7 Player has "..itemTarget.amount.." of "..item..", wants to sell "..amount)

    -- Kiểm tra số lượng hợp lệ
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        ---- print("^1[SELLITEM ERROR]^7 Invalid amount: "..tostring(amount))
        TriggerClientEvent("QBCore:Notify", playerId, "Số lượng không hợp lệ", "error")
        return
    end

    -- Kiểm tra Cooldown
    local citizenId = xPlayer.PlayerData.citizenid
    local canSell, allowedAmount, errMessage = CheckItemCooldown(citizenId, item, amount, itemEco)
    if not canSell then
        TriggerClientEvent("QBCore:Notify", playerId, errMessage, "error")
        return
    end

    -- Kiểm tra có đủ item để bán không
    if itemTarget.amount < amount then
        ---- print("^1[SELLITEM ERROR]^7 Not enough items. Has: "..itemTarget.amount..", wants: "..amount)
        TriggerClientEvent("QBCore:Notify", playerId, "Hiện tại trong túi đồ chỉ có: x"..itemTarget.amount.." "..itemTarget.label.." mà muốn bán x"..amount.." "..itemTarget.label.." sao?", "error")
        return
    end

    -- Thực hiện bán
    local totalPrice = math.abs(itemEco.Price * amount)
    
    -- print("^3[SELLITEM DEBUG]^7 Player "..playerId.." selling "..amount.." of "..item.." for $"..totalPrice)
    
    if xPlayer.Functions.RemoveItem(item, amount) then
        CommitItemCooldown(citizenId, item, amount, itemEco)
        ProcessPriceDropOnSell(item, amount)
        -- print("^2[SELLITEM]^7 Item removed successfully")
        
        -- Thử cả 2 cách add money
        local moneyAdded = xPlayer.Functions.AddMoney('cash', totalPrice, 'Bán `x'..amount..' '..itemTarget.label..'` tại Người Thu Mua')
        
        -- print("^2[SELLITEM]^7 AddMoney result:", moneyAdded, "Amount:", totalPrice)
        -- print("^2[SELLITEM]^7 Player cash before:", xPlayer.PlayerData.money.cash or 0)
        
        -- Nếu AddMoney không hoạt động, thử cách khác
        if not moneyAdded or moneyAdded == false then
            -- print("^1[SELLITEM ERROR]^7 AddMoney failed, trying alternative method")
            -- Thử add trực tiếp
            xPlayer.Functions.SetMoney('cash', (xPlayer.PlayerData.money.cash or 0) + totalPrice)
        end
        
        -- print("^2[SELLITEM]^7 Player cash after:", xPlayer.PlayerData.money.cash or 0)
        
        TriggerClientEvent('inventory:client:ItemBox', playerId, QBCore.Shared.Items[item], 'remove')
        TriggerClientEvent("QBCore:Notify", playerId, "Bán thành công x"..amount.." "..itemTarget.label.." với giá "..totalPrice.."$ (Tiền mặt)", "success")

        -- Update leaderboard (1$ = 1 point)
        local citizenId = xPlayer.PlayerData.citizenid
        local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
        local category = itemEco.Category
        if category then
            UpdateLeaderboard(citizenId, playerName, category, totalPrice)
        end

        -- Log với ox_lib
        local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
        local locationName = GetLocationName(playerCoords)
        
        lib.logger(playerId, 'Chợ đầu mối', string.format(
            'Người chơi: %s %s (%s) | Tại vị trí: %s | Đã bán vật phẩm: %s x%d | Với giá: $%d',
            xPlayer.PlayerData.charinfo.firstname,
            xPlayer.PlayerData.charinfo.lastname,
            xPlayer.PlayerData.pid,
            locationName,
            itemTarget.label,
            amount,
            totalPrice
        ))
        -- print(string.format('^2[SELLITEM LOG]^7 %s %s bán %s x%d tại %s với giá $%d',
        --     xPlayer.PlayerData.charinfo.firstname,
        --     xPlayer.PlayerData.charinfo.lastname,
        --     itemTarget.label,
        --     amount,
        --     locationName,
        --     totalPrice
        -- ))

        -- Quest trigger
        TriggerClientEvent('alive_quest:action', playerId, 'sell_' .. item, amount)
    else
        ---- print("^1[SELLITEM ERROR]^7 Failed to remove item from inventory")
        TriggerClientEvent("QBCore:Notify", playerId, "Không thể xóa item khỏi túi đồ", "error")
    end
end)

exports['monitors']:RegisterProtectedEvent('xn-sellitem:cfx:action-all', function(playerId, item)
    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    
    -- Kiểm tra player hợp lệ
    if not xPlayer then
        return
    end
    
    local itemTarget = xPlayer.Functions.GetItemByName(item)
    local itemEco = DATA[item]

    -- Kiểm tra item có trong config không
    if not itemEco then
        TriggerClientEvent("QBCore:Notify", playerId, "Item này không thể bán tại đây", "error")
        return
    end

    if not IsPlayerNearSellCategory(playerId, itemEco.Category, 5.0) then
        TriggerClientEvent("QBCore:Notify", playerId, "Bạn phải đứng gần đúng người thu mua để bán vật phẩm này", "error")
        return
    end

    -- Kiểm tra điều kiện Cảnh sát cho Chợ Đen (choden)
    if itemEco.Category == 'choden' then
        local policeCount = GetPoliceCount()
        local requiredCops = Config.ChodenRequiredCops or 3
        if policeCount < requiredCops then
            TriggerClientEvent("QBCore:Notify", playerId, string.format("Chợ Đen chỉ hoạt động khi có tối thiểu %d cảnh sát online!", requiredCops), "error")
            return
        end
    end

    -- Kiểm tra item có trong inventory không
    if not itemTarget then
        TriggerClientEvent("QBCore:Notify", playerId, "Bạn không có vật phẩm này để bán", "error")
        return
    end

    local Amount = itemTarget.amount 
    if Amount <= 0 then
        TriggerClientEvent("QBCore:Notify", playerId, "Bạn không có vật phẩm này để bán", "error")
        return
    end

    -- Kiểm tra Cooldown
    local citizenId = xPlayer.PlayerData.citizenid
    local canSell, allowedAmount, errMessage = CheckItemCooldown(citizenId, item, Amount, itemEco)
    if not canSell then
        if allowedAmount and allowedAmount > 0 then
            Amount = allowedAmount
            TriggerClientEvent("QBCore:Notify", playerId, string.format("Bạn chỉ có thể bán tối đa %d cái %s. Đã điều chỉnh số lượng.", Amount, itemEco.Label), "primary")
        else
            TriggerClientEvent("QBCore:Notify", playerId, errMessage, "error")
            return
        end
    end

    -- Thực hiện bán tất cả
    local totalPrice = math.abs(itemEco.Price * Amount)
    
    -- print("^3[SELLITEM DEBUG]^7 Player "..playerId.." selling ALL "..Amount.." of "..item.." for $"..totalPrice)
    
    if xPlayer.Functions.RemoveItem(item, Amount) then
        CommitItemCooldown(citizenId, item, Amount, itemEco)
        ProcessPriceDropOnSell(item, Amount)
        -- print("^2[SELLITEM]^7 Item removed successfully")
        
        -- Thử cả 2 cách add money
        local moneyAdded = xPlayer.Functions.AddMoney('cash', totalPrice, 'Bán `x'..Amount..' '..itemTarget.label..'` tại Người Thu Mua')
        
        -- print("^2[SELLITEM]^7 AddMoney result:", moneyAdded, "Amount:", totalPrice)
        -- print("^2[SELLITEM]^7 Player cash before:", xPlayer.PlayerData.money.cash or 0)
        
        -- Nếu AddMoney không hoạt động, thử cách khác
        if not moneyAdded or moneyAdded == false then
            -- print("^1[SELLITEM ERROR]^7 AddMoney failed, trying alternative method")
            xPlayer.Functions.SetMoney('cash', (xPlayer.PlayerData.money.cash or 0) + totalPrice)
        end
        
        -- print("^2[SELLITEM]^7 Player cash after:", xPlayer.PlayerData.money.cash or 0)
        
        TriggerClientEvent('inventory:client:ItemBox', playerId, QBCore.Shared.Items[item], 'remove')
        TriggerClientEvent("QBCore:Notify", playerId, "Bán thành công x"..Amount.." "..itemTarget.label.." với giá "..totalPrice.."$ (Tiền mặt)", "success")

        -- Update leaderboard (1$ = 1 point)
        local citizenId = xPlayer.PlayerData.citizenid
        local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
        local category = itemEco.Category
        if category then
            UpdateLeaderboard(citizenId, playerName, category, totalPrice)
        end

        -- Log với ox_lib
        local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
        local locationName = GetLocationName(playerCoords)
        
        -- lib.logger(playerId, 'Chợ đầu mối', string.format(
        --     'Người chơi: %s %s (%s) | Tại vị trí: %s | Đã bán hết vật phẩm: %s x%d (ALL) | Với giá: $%d',
        --     xPlayer.PlayerData.charinfo.firstname,
        --     xPlayer.PlayerData.charinfo.lastname,
        --     xPlayer.PlayerData.pid,
        --     locationName,
        --     itemTarget.label,
        --     Amount,
        --     totalPrice
        -- ))
        -- print(string.format('^2[SELLITEM LOG]^7 %s %s bán ALL %s x%d tại %s với giá $%d',
        --     xPlayer.PlayerData.charinfo.firstname,
        --     xPlayer.PlayerData.charinfo.lastname,
        --     itemTarget.label,
        --     Amount,
        --     locationName,
        --     totalPrice
        -- ))

        -- Quest trigger
        TriggerClientEvent('alive_quest:action', playerId, 'sell_' .. item, Amount)
    else
        TriggerClientEvent("QBCore:Notify", playerId, "Không thể xóa item khỏi túi đồ", "error")
    end
end)

RegisterServerEvent('xn-sellitem:cfx:getPrices')
AddEventHandler('xn-sellitem:cfx:getPrices', function()
    local playerId = source
    -- @send a whole value to player that just joined
    TriggerClientEvent('xn-sellitem:setPrices', playerId, DATA)
end)

-- Handle explicit price requests (e.g., when opening shop after restart)
RegisterServerEvent('xn-sellitem:requestPrices')
AddEventHandler('xn-sellitem:requestPrices', function()
    local playerId = source
    -- print('^3[SELLITEM DEBUG]^7 Player ' .. playerId .. ' requested prices, sending ' .. #DATA .. ' items')
    TriggerClientEvent('xn-sellitem:setPrices', playerId, DATA)
end)

-- Handle request for all items (including database-only items)
RegisterServerEvent('xn-sellitem:requestAllItems')
AddEventHandler('xn-sellitem:requestAllItems', function()
    local playerId = source
    -- print('^3[SELLITEM DEBUG]^7 Player ' .. playerId .. ' requested all items')
    TriggerClientEvent('xn-sellitem:syncAllItems', playerId, Config.Items)
end)

QBCore.Functions.CreateCallback('xn-sellitem:server:getInv', function(source, cb)
    local inventory = {}
    -- Lấy toàn bộ items trong ox_inventory của player
    local items = exports.ox_inventory:GetInventoryItems(source)
    if items then
        for _, item in pairs(items) do
            if item and item.name and item.count and item.count > 0 then
                -- Cộng dồn nếu item xuất hiện nhiều slot
                inventory[item.name] = (inventory[item.name] or 0) + item.count
            end
        end
    end
    return cb(inventory)
end)

-- ========================================
-- ADMIN SHOP MANAGEMENT SYSTEM
-- ========================================

-- Command để reset tất cả giá về random (Admin only)
QBCore.Commands.Add('resetprices', 'Reset tất cả giá về random (Admin)', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god') then
        local count = 0
        for itemName, itemData in pairs(DATA) do
            Wait(10)
            local priceSteps = GetPriceSteps(itemData.Min, itemData.Max)
            local newPrice = RandomPriceFromSteps(priceSteps, nil)
            itemData.Price = newPrice
            itemData.CurrentAmount = 0
            
            local center = round((itemData.Min + itemData.Max) / 2)
            if newPrice > center then
                itemData.Status = 'up'
            elseif newPrice < center then
                itemData.Status = 'down'
            else
                itemData.Status = 'equal'
            end
            
            DATA[itemName] = itemData
            
            -- Cập nhật database
            if itemData.Category then
                UpdateItemPrice(itemData.Category, itemName, newPrice)
            elseif DatabaseConfig then
                for category, items in pairs(DatabaseConfig) do
                    if items[itemName] then
                        UpdateItemPrice(category, itemName, newPrice)
                        break
                    end
                end
            end
            
            count = count + 1
        end
        
        -- Gửi giá mới cho tất cả người chơi
        TriggerClientEvent('xn-sellitem:setPrices', -1, DATA)
        TriggerClientEvent('QBCore:Notify', source, 'Đã reset '..count..' giá sản phẩm về random!', 'success')
        -- print('^2[SELLITEM]^7 Admin '..Player.PlayerData.name..' reset '..count..' prices to random')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này!', 'error')
    end
end)

-- Command để mở admin menu
QBCore.Commands.Add('adminshop', 'Mở menu quản lý shop (Admin Only)', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Kiểm tra quyền admin
    if QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god') then
        TriggerClientEvent('xn-sellitem:client:openAdminMenu', source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này!', 'error')
    end
end, 'admin')

-- Command để rebuild cache admin items (nếu cần troubleshoot)
QBCore.Commands.Add('refreshadmincache', 'Rebuild admin items cache', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    if QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god') then
        BuildAdminItemsCache()
        TriggerClientEvent('QBCore:Notify', source, 'Cache admin items đã được rebuild!', 'success')
        print('^2[XN-SELLITEM]^7 Admin cache manually rebuilt by player: ' .. GetPlayerName(source))
    else
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này!', 'error')
    end
end, 'admin')

-- Command để sync Config items vào database
QBCore.Commands.Add('syncshopitems', 'Sync Config items to database', {}, false, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    if QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god') then
        TriggerClientEvent('QBCore:Notify', source, 'Đang sync items từ Config vào database...', 'info')
        print("^3[SELLITEM]^7 ========================================")
        print("^3[SELLITEM]^7 Manual sync started by: " .. GetPlayerName(source))
        print("^3[SELLITEM]^7 ========================================")
        
        local syncCount = 0
        local categoryStats = {}
        
        for categoryName, categoryItems in pairs(Config.Items) do
            categoryStats[categoryName] = { total = 0, new = 0 }
            
            for itemName, itemData in pairs(categoryItems) do
                categoryStats[categoryName].total = categoryStats[categoryName].total + 1
                local existsInDb = DatabaseConfig[categoryName] and DatabaseConfig[categoryName][itemName]
                
                if not existsInDb then
                    print("^2[SELLITEM]^7 Creating: "..itemName.." in category: "..categoryName)
                    local priceSteps = GetPriceSteps(itemData.Min, itemData.Max)
                    local currentPrice = DATA[itemName] and DATA[itemName].Price or RandomPriceFromSteps(priceSteps, nil)
                    local success = CreateItemConfig(categoryName, itemName, itemData, currentPrice)
                    
                    if success then
                        syncCount = syncCount + 1
                        categoryStats[categoryName].new = categoryStats[categoryName].new + 1
                        print("^2[SELLITEM]^7 ✓ Created: "..itemName)
                    else
                        print("^1[SELLITEM]^7 ✗ Failed: "..itemName)
                    end
                    Wait(100)
                end
            end
        end
        
        print("^3[SELLITEM]^7 ========================================")
        print("^3[SELLITEM]^7 Sync Results:")
        for cat, stats in pairs(categoryStats) do
            print("^3[SELLITEM]^7   "..cat..": "..stats.new.." new / "..stats.total.." total")
        end
        print("^3[SELLITEM]^7 ========================================")
        
        if syncCount > 0 then
            BuildAdminItemsCache()
            TriggerClientEvent('QBCore:Notify', source, 'Đã sync '..syncCount..' items mới vào database!', 'success')
            print('^2[SELLITEM]^7 Total: '..syncCount..' new items synced')
            print('^2[SELLITEM]^7 Admin cache rebuilt')
            
            -- Refresh admin panel cho người đang mở
            TriggerClientEvent('xn-sellitem:client:refreshAdminData', source, GetAllItemsForAdmin())
        else
            TriggerClientEvent('QBCore:Notify', source, 'Tất cả items đã tồn tại trong database!', 'info')
            print('^2[SELLITEM]^7 No new items to sync')
        end
    else
        TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này!', 'error')
    end
end, 'admin')

-- Callback để lấy tất cả items cho admin menu
QBCore.Functions.CreateCallback('xn-sellitem:server:getAdminItems', function(source, cb)
    -- print('^3[ADMIN]^7 Getting admin items...')
    local items = GetAllItemsForAdmin()
    -- print('^3[ADMIN]^7 Found ' .. #items .. ' items')
    cb(items)
end)

-- Callback để cập nhật item config
RegisterNetEvent('xn-sellitem:server:updateItemConfig', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Kiểm tra quyền admin
    if not (QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')) then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền thực hiện hành động này!', 'error')
        return
    end
    
    -- Validate data
    if not data.category or not data.itemName then
        TriggerClientEvent('QBCore:Notify', src, 'Dữ liệu không hợp lệ!', 'error')
        return
    end
    
    local itemData = {
        Label = data.label,
        Min = tonumber(data.min),
        Max = tonumber(data.max),
        RandomWhenStart = data.randomWhenStart,
        AmountToChange = tonumber(data.amountToChange) or 50
    }
    
    -- Validate số
    if itemData.Min >= itemData.Max then
        TriggerClientEvent('QBCore:Notify', src, 'Giá Min phải nhỏ hơn Max!', 'error')
        return
    end
    
    -- Lưu vào database
    local success = SaveItemConfig(data.category, data.itemName, itemData)
    
    if success then
        -- Cập nhật DATA runtime
        if DATA[data.itemName] then
            local oldMin = DATA[data.itemName].Min
            local oldMax = DATA[data.itemName].Max
            local currentPrice = DATA[data.itemName].Price
            
            DATA[data.itemName].Min = itemData.Min
            DATA[data.itemName].Max = itemData.Max
            DATA[data.itemName].Label = itemData.Label
            DATA[data.itemName].AmountToChange = itemData.AmountToChange
            
            -- Kiểm tra nếu Min/Max thay đổi hoặc giá hiện tại vượt quá khoảng mới
            local needRandomPrice = false
            
            if oldMin ~= itemData.Min or oldMax ~= itemData.Max then
                -- Min/Max đã thay đổi - random lại giá trong khoảng mới
                needRandomPrice = true
            elseif currentPrice < itemData.Min or currentPrice > itemData.Max then
                -- Giá hiện tại vượt quá khoảng mới - random lại
                needRandomPrice = true
            end
            
            if needRandomPrice then
                -- Random giá mới từ 6 bước giá
                local priceSteps = GetPriceSteps(itemData.Min, itemData.Max)
                local newPrice = priceSteps[math.random(1, #priceSteps)]
                DATA[data.itemName].Price = newPrice
                UpdateItemPrice(data.category, data.itemName, newPrice)
                -- print(string.format('^3[ADMIN]^7 Random new price for %s: $%d (4 steps: $%d, $%d, $%d, $%d)', data.itemName, newPrice, priceSteps[1], priceSteps[2], priceSteps[3], priceSteps[4]))
            end
            
            -- Cập nhật status
            local center = round((itemData.Min + itemData.Max) / 2)
            if DATA[data.itemName].Price > center then
                DATA[data.itemName].Status = 'up'
            elseif DATA[data.itemName].Price < center then
                DATA[data.itemName].Status = 'down'
            else
                DATA[data.itemName].Status = 'equal'
            end
        end
        
        -- Log admin action
        -- lib.logger(src, 'Admin Shop Config', string.format(
        --     'Admin %s %s (%s) đã cập nhật config cho item: %s (Category: %s) - Min: %d, Max: %d, RangeChange: [%d, %d], AmountToChange: %d',
        --     Player.PlayerData.charinfo.firstname,
        --     Player.PlayerData.charinfo.lastname,
        --     Player.PlayerData.pid,
        --     data.itemName,
        --     data.category,
        --     itemData.Min,
        --     itemData.Max,
        --     itemData.RangeChange[1],
        --     itemData.RangeChange[2],
        --     itemData.AmountToChange
        -- ))
        -- print(string.format('^3[ADMIN LOG]^7 %s %s cập nhật config item: %s (Cat: %s) - Min: %d, Max: %d',
        --     Player.PlayerData.charinfo.firstname,
        --     Player.PlayerData.charinfo.lastname,
        --     data.itemName,
        --     data.category,
        --     itemData.Min,
        --     itemData.Max
        -- ))
        
        TriggerClientEvent('QBCore:Notify', src, 'Cập nhật thành công item: ' .. itemData.Label, 'success')
        
        -- Cập nhật giá cho tất cả người chơi (bao gồm cả shop UI và phone app)
        TriggerClientEvent('xn-sellitem:setPrices', -1, DATA)
        
        -- Gửi update riêng cho item vừa sửa
        TriggerClientEvent('xn-sellitem:update', -1, data.itemName, DATA[data.itemName])
        
        -- Refresh admin menu cho admin vừa sửa
        QBCore.Functions.CreateUseableItem('__admin_refresh', function(source)
            local items = GetAllItemsForAdmin()
            TriggerClientEvent('xn-sellitem:refreshAdminData', source, items)
        end)
        
        -- Gửi refresh cho admin
        local items = GetAllItemsForAdmin()
        TriggerClientEvent('xn-sellitem:refreshAdminData', src, items)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Lỗi khi lưu vào database!', 'error')
    end
end)

-- Handler tạo item mới
RegisterNetEvent('xn-sellitem:server:createNewItem', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Kiểm tra quyền admin
    if not (QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')) then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền thực hiện hành động này!', 'error')
        return
    end
    
    -- Validate data
    if not data.category or not data.itemName or not data.label then
        TriggerClientEvent('QBCore:Notify', src, 'Dữ liệu không hợp lệ! Thiếu thông tin bắt buộc.', 'error')
        return
    end
    
    -- Validate tên item (chỉ chữ thường, số, dấu gạch dưới)
    if not string.match(data.itemName, "^[a-z0-9_]+$") then
        TriggerClientEvent('QBCore:Notify', src, 'Tên item không hợp lệ! Chỉ dùng chữ thường, số và dấu gạch dưới (_)', 'error')
        return
    end
    
    -- Kiểm tra item đã tồn tại chưa
    if DATA[data.itemName] then
        TriggerClientEvent('QBCore:Notify', src, 'Item này đã tồn tại trong hệ thống!', 'error')
        return
    end
    
    local amountToChange = tonumber(data.amountToChange)
    if not amountToChange or amountToChange <= 0 then
        amountToChange = 50
    end

    local itemData = {
        Label = data.label,
        Min = tonumber(data.min),
        Max = tonumber(data.max),
        RandomWhenStart = data.randomWhenStart,
        AmountToChange = amountToChange
    }
    
    -- Validate số
    if itemData.Min >= itemData.Max then
        TriggerClientEvent('QBCore:Notify', src, 'Giá Min phải nhỏ hơn Max!', 'error')
        return
    end
    
    if itemData.Min < 1 or itemData.Max < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Các giá trị phải lớn hơn 0!', 'error')
        return
    end
    
    -- Tạo giá khởi tạo từ 6 bước giá
    local priceSteps = GetPriceSteps(itemData.Min, itemData.Max)
    local initialPrice = priceSteps[math.random(1, #priceSteps)]
    
    -- Lưu vào database
    local success = CreateItemConfig(data.category, data.itemName, itemData, initialPrice)
    
    if success then
        -- Thêm vào DATA runtime
        local newData = {
            Price = initialPrice,
            Min = itemData.Min,
            Max = itemData.Max,
            RangeChange = { 1, 4 },
            AmountToChange = itemData.AmountToChange,
            CurrentAmount = 0,
            Label = itemData.Label,
            Status = 'equal',
            Category = data.category
        }
        
        -- Tính status
        local center = round((itemData.Min + itemData.Max) / 2)
        if initialPrice > center then
            newData.Status = 'up'
        elseif initialPrice < center then
            newData.Status = 'down'
        else
            newData.Status = 'equal'
        end
        
        DATA[data.itemName] = newData
        
        -- Thêm vào Config.Items runtime
        if not Config.Items[data.category] then
            Config.Items[data.category] = {}
        end
        
        Config.Items[data.category][data.itemName] = {
            Label = itemData.Label,
            Min = itemData.Min,
            Max = itemData.Max,
            RandomWhenStart = itemData.RandomWhenStart,
            AmountToChange = itemData.AmountToChange
        }
        
        -- Cập nhật Config.Locations để thêm item vào location tương ứng
        for k, location in pairs(Config.Locations) do
            -- Tìm location có Items trỏ đến category này
            if location.Items == Config.Items[data.category] then
                -- Location này sẽ tự động có item mới vì Items là reference
                -- print('^2[ADMIN]^7 Item ' .. data.itemName .. ' đã được thêm vào location: ' .. location.NPCText)
            end
        end
        
        -- Log admin action
        -- print(string.format('^2[ADMIN LOG]^7 %s %s tạo item mới: %s (Cat: %s) - Price: $%d, Min: $%d, Max: $%d',
        --     Player.PlayerData.charinfo.firstname,
        --     Player.PlayerData.charinfo.lastname,
        --     data.itemName,
        --     data.category,
        --     initialPrice,
        --     itemData.Min,
        --     itemData.Max
        -- ))
        
        TriggerClientEvent('QBCore:Notify', src, 'Tạo thành công item: ' .. itemData.Label .. ' với giá $' .. initialPrice, 'success')
        
        -- Cập nhật giá cho tất cả người chơi (shop UI và phone app)
        TriggerClientEvent('xn-sellitem:setPrices', -1, DATA)
        
        -- Gửi thông báo cho tất cả người chơi về item mới
        TriggerClientEvent('QBCore:Notify', -1, '📦 Sản phẩm mới: ' .. itemData.Label .. ' đã có mặt tại ' .. (Config.CategoryNames[data.category] or data.category), 'success', 5000)
        
        -- Refresh admin menu cho tất cả admin đang mở
        local items = GetAllItemsForAdmin()
        TriggerClientEvent('xn-sellitem:refreshAdminData', -1, items)
        
        -- Gửi event để client update Config.Items
        TriggerClientEvent('xn-sellitem:syncNewItem', -1, data.category, data.itemName, itemData)
        
        -- Gửi dữ liệu mới về cho admin để refresh menu
        TriggerClientEvent('xn-sellitem:client:refreshAdminData', src, GetAllItemsForAdmin())
        
        -- print('^2[ADMIN]^7 Config updated for item: ^3' .. data.itemName .. '^7 - New Min: $' .. itemData.Min .. ', Max: $' .. itemData.Max)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Lỗi khi cập nhật vào database!', 'error')
    end
end)

-- Handler xóa item
RegisterNetEvent('xn-sellitem:server:deleteItem', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Kiểm tra quyền admin
    if not (QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')) then
        TriggerClientEvent('QBCore:Notify', src, 'Bạn không có quyền thực hiện hành động này!', 'error')
        return
    end
    
    -- Validate data
    if not data.category or not data.itemName then
        TriggerClientEvent('QBCore:Notify', src, 'Dữ liệu không hợp lệ!', 'error')
        return
    end
    
    local itemName = data.itemName
    local category = data.category
    
    -- Kiểm tra item có tồn tại không
    if not DATA[itemName] then
        TriggerClientEvent('QBCore:Notify', src, 'Item không tồn tại trong hệ thống!', 'error')
        return
    end
    
    local itemLabel = DATA[itemName].Label
    
    -- Xóa khỏi database
    local success = DeleteItemConfig(category, itemName)
    
    if success then
        -- Xóa khỏi DATA runtime
        DATA[itemName] = nil
        
        -- Xóa khỏi Config.Items runtime
        if Config.Items[category] and Config.Items[category][itemName] then
            Config.Items[category][itemName] = nil
        end
        
        -- Log admin action
        -- print(string.format('^1[ADMIN LOG]^7 %s %s xóa item: %s (Cat: %s)',
        --     Player.PlayerData.charinfo.firstname,
        --     Player.PlayerData.charinfo.lastname,
        --     itemName,
        --     category
        -- ))
        
        TriggerClientEvent('QBCore:Notify', src, 'Đã xóa item: ' .. itemLabel, 'success')
        
        -- Cập nhật giá cho tất cả người chơi
        TriggerClientEvent('xn-sellitem:setPrices', -1, DATA)
        
        -- Gửi thông báo cho tất cả người chơi
        TriggerClientEvent('QBCore:Notify', -1, '🗑️ Sản phẩm "' .. itemLabel .. '" đã ngừng kinh doanh', 'error', 5000)
        
        -- Refresh admin menu
        local items = GetAllItemsForAdmin()
        TriggerClientEvent('xn-sellitem:refreshAdminData', -1, items)
        
        -- Gửi event xóa item trên client
        TriggerClientEvent('xn-sellitem:removeItem', -1, category, itemName)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Lỗi khi xóa khỏi database!', 'error')
    end
end)

local SELL_CATEGORIES = { 'fish', 'phelieu', 'mining', 'nuoithu', 'traicay' }
local VUANGHE_DIVISOR = #SELL_CATEGORIES

local function fetchLeaderboardRows(category, limit)
    limit = tonumber(limit) or 10

    if category == 'vuanghe' then
        return MySQL.query.await(([[
            SELECT citizen_id, player_name, ROUND(SUM(points) / %d) AS points
            FROM xn_sellitem_leaderboard
            GROUP BY citizen_id, player_name
            HAVING SUM(points) > 0
            ORDER BY points DESC, player_name ASC
            LIMIT ?
        ]]):format(VUANGHE_DIVISOR), { limit }) or {}
    end

    return MySQL.query.await([[
        SELECT citizen_id, player_name, points
        FROM xn_sellitem_leaderboard
        WHERE category = ? AND points > 0
        ORDER BY points DESC, player_name ASC
        LIMIT ?
    ]], { category, limit }) or {}
end

exports('GetSellCategories', function()
    return SELL_CATEGORIES
end)

exports('GetCategoryCount', function()
    return VUANGHE_DIVISOR
end)

exports('GetLeaderboard', function(category, limit)
    if not category then return {} end
    return fetchLeaderboardRows(category, limit)
end)

exports('xn_sellitem_leaderboard', function(arg1, arg2, arg3)
    if type(arg1) == "number" then
        local source = arg1
        local category = arg2
        local points = tonumber(arg3) or 0
        
        local citizenId, playerName
        if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
            local xPlayer = QBCore.Functions.GetPlayer(source)
            if xPlayer then
                citizenId = xPlayer.PlayerData.citizenid
                playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
            end
        end
        
        if not citizenId then
            local pcallSuccess, qbCoreObj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if pcallSuccess and qbCoreObj and qbCoreObj.Functions then
                local xPlayer = qbCoreObj.Functions.GetPlayer(source)
                if xPlayer then
                    citizenId = xPlayer.PlayerData.citizenid
                    playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
                end
            end
        end
        
        if not citizenId then
            local pcallSuccess, esxObj = pcall(function() return exports['es_extended']:getSharedObject() end)
            if pcallSuccess and esxObj then
                local xPlayer = esxObj.GetPlayerFromId(source)
                if xPlayer then
                    citizenId = xPlayer.identifier
                    playerName = xPlayer.getName()
                end
            end
        end
        
        if citizenId and playerName and category and points > 0 then
            UpdateLeaderboard(citizenId, playerName, category, points)
        end
    else
        return fetchLeaderboardRows(arg1, arg2)
    end
end)


exports('GetPlayerPoints', function(citizenId, category)
    if not citizenId or not category then return 0 end

    if category == 'vuanghe' then
        local row = MySQL.single.await([[
            SELECT ROUND(SUM(points) / ?) AS points
            FROM xn_sellitem_leaderboard
            WHERE citizen_id = ?
        ]], { VUANGHE_DIVISOR, citizenId })
        return row and (row.points or 0) or 0
    end

    local points = MySQL.scalar.await([[
        SELECT points FROM xn_sellitem_leaderboard
        WHERE citizen_id = ? AND category = ?
        LIMIT 1
    ]], { citizenId, category })
    return points or 0
end)

exports('NotifyLeaderboardUpdated', function(category)
    TriggerEvent('xn-sellitem:leaderboardUpdated', category)
end)
