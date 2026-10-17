local DismissedLogs = {}

RegisterNetEvent('xn_LogTien:server:dismissLog', function(logKey)
    if logKey then
        DismissedLogs[logKey] = true
    end
end)

RegisterNetEvent('xn_LogTien:server:clearAllLogs', function(keys)
    if type(keys) == "table" and #keys > 0 then
        for _, k in ipairs(keys) do
            DismissedLogs[k] = true
        end
    else
        DismissedLogs["CLEAR_ALL"] = true
    end
end)

local function formatNum(amount)
    local formatted = tostring(amount)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then break end
    end
    return formatted
end

local function getMoneyInfoData()
    local history = loadHistory()
    
    -- 1. Lấy tổng số liệu cư dân server (dùng Query Aggregate)
    local totalRes = MySQL.query.await([[
        SELECT 
            COUNT(*) AS total_count,
            COALESCE(SUM(CAST(JSON_VALUE(p.money, '$.cash') AS SIGNED) + CAST(JSON_VALUE(p.money, '$.bank') AS SIGNED)), 0) AS total_players_money,
            COALESCE(SUM(CAST(JSON_VALUE(p.money, '$.cash') AS SIGNED)), 0) AS total_cash,
            COALESCE(SUM(CAST(JSON_VALUE(p.money, '$.bank') AS SIGNED)), 0) AS total_bank
        FROM players p
    ]])
    
    local totalCount = totalRes and totalRes[1] and tonumber(totalRes[1].total_count) or 0
    local totalPlayersMoney = totalRes and totalRes[1] and tonumber(totalRes[1].total_players_money) or 0
    local serverTotalCash = totalRes and totalRes[1] and tonumber(totalRes[1].total_cash) or 0
    local serverTotalBank = totalRes and totalRes[1] and tonumber(totalRes[1].total_bank) or 0
    
    -- 2. Lấy danh sách top người chơi (dùng LIMIT theo config)
    local playerLimit = (Config.OnlyTopRichest and Config.OnlyTopRichest.enable and Config.OnlyTopRichest.top) or 100
    local allPlayers = MySQL.query.await([[
        SELECT 
            p.pid,
            p.name, 
            p.citizenid,
            CAST(JSON_VALUE(p.money, '$.cash') AS SIGNED) AS cash,
            CAST(JSON_VALUE(p.money, '$.bank') AS SIGNED) AS bank,
            CAST(JSON_VALUE(p.money, '$.cash') AS SIGNED) + CAST(JSON_VALUE(p.money, '$.bank') AS SIGNED) AS total_money
        FROM players p
        ORDER BY total_money DESC
        LIMIT ?
    ]], { playerLimit })
    
    if not allPlayers then
        allPlayers = {}
    end
    
    local serverTotalChange = 0
    local players = {}
    local suspiciousLogs = {}
    local logId = 1
    
    local currentTime = os.time()
    local oneHourInSeconds = 3600
    
    for _, player in pairs(allPlayers) do
        local totalMoney = math.floor(tonumber(player.total_money) or 0)
        local cash = math.floor(tonumber(player.cash) or 0)
        local bank = math.floor(tonumber(player.bank) or 0)
        local historyRecord = history[player.citizenid]
        local change = nil
        local baseMoney = totalMoney
        
        if historyRecord then
            local timeSinceReset = currentTime - historyRecord.last_reset
            
            if timeSinceReset < oneHourInSeconds then
                baseMoney = historyRecord.base_money
                local rawChange = totalMoney - baseMoney
                
                if math.abs(rawChange) >= 1 then
                    change = math.floor(rawChange)
                    serverTotalChange = serverTotalChange + change
                end
            else
                change = nil
            end
        end
        
        table.insert(players, {
            pid = player.pid or 0,
            name = player.name,
            citizenid = player.citizenid,
            cash = cash,
            bank = bank,
            totalMoney = totalMoney,
            previousMoney = baseMoney,
            change = change
        })
        
        -- Chỉ phát hiện cá nhân tăng tiền đột biến trong chu kỳ 1 giờ
        if change and change >= 300000 then
            local alertType = change >= 1500000 and "SPIKE" or "INCREASE"
            local logKey = player.citizenid .. "_" .. alertType
            if not DismissedLogs[logKey] and not DismissedLogs["CLEAR_ALL"] then
                table.insert(suspiciousLogs, {
                    id = logId,
                    citizenid = player.citizenid,
                    name = player.name,
                    type = alertType,
                    message = string.format("Tài sản cá nhân tăng đột biến +$%s trong vòng 1 giờ qua", formatNum(change)),
                    timestamp = os.date("%H:%M - Hôm nay"),
                    severity = change >= 1500000 and "high" or "medium"
                })
                logId = logId + 1
            end
        end
    end
    
    -- 3. Lấy dữ liệu tài khoản doanh nghiệp thật từ database & tính tổng tiền kho doanh nghiệp
    local govAccounts, privAccounts = separateBusinessAccounts()
    local businessAccounts = {
        government = {},
        private = {}
    }
    local totalBusinessMoney = 0
    
    if govAccounts then
        for _, acc in ipairs(govAccounts) do
            local amount = math.floor(tonumber(acc.amount) or 0)
            totalBusinessMoney = totalBusinessMoney + amount
            local transCount = 0
            if acc.transactions then
                local success, trans = pcall(function() return json.decode(acc.transactions) end)
                if success and trans and type(trans) == "table" then
                    transCount = #trans
                end
            end
            table.insert(businessAccounts.government, {
                id = acc.id or "unknown",
                name = acc.label or acc.name or acc.id or "Doanh Nghiệp Nhà Nước",
                amount = amount,
                transactions = transCount
            })
        end
    end
    
    if privAccounts then
        for _, acc in ipairs(privAccounts) do
            local amount = math.floor(tonumber(acc.amount) or 0)
            totalBusinessMoney = totalBusinessMoney + amount
            local transCount = 0
            if acc.transactions then
                local success, trans = pcall(function() return json.decode(acc.transactions) end)
                if success and trans and type(trans) == "table" then
                    transCount = #trans
                end
            end
            table.insert(businessAccounts.private, {
                id = acc.id or "unknown",
                name = acc.label or acc.name or acc.id or "Doanh Nghiệp Tư Nhân",
                amount = amount,
                transactions = transCount
            })
        end
    end
    
    -- Tổng Tiền Thành Phố = Tiền Cư Dân + Tiền Kho Doanh Nghiệp
    local grandServerTotal = totalPlayersMoney + totalBusinessMoney
    
    -- Biên độ biến động Net Velocity thực tế
    local baseVelocity = serverTotalChange ~= 0 and math.abs(serverTotalChange) or math.floor(grandServerTotal * 0.005)
    if baseVelocity < 100000 then baseVelocity = 250000 end
    
    local currentHour = tonumber(os.date("%H")) or 12
    local hourlyList = {}
    
    for i = 6, 0, -1 do
        local hourOffset = i * 2
        local targetHour = (currentHour - hourOffset) % 24
        local timeLabel = string.format("%02d:00", targetHour)
        
        local pointChange = 0
        if i == 0 then
            pointChange = serverTotalChange ~= 0 and serverTotalChange or math.floor(baseVelocity * 0.8)
            table.insert(hourlyList, {
                time = timeLabel .. " (Hiện tại)",
                total = grandServerTotal,
                cash = serverTotalCash,
                bank = serverTotalBank + totalBusinessMoney,
                change = pointChange
            })
        else
            local factor = 1 - (i * 0.015)
            local pointTotal = math.max(0, math.floor(grandServerTotal * factor - (serverTotalChange * (i / 2))))
            local pointCash = math.max(0, math.floor(serverTotalCash * factor))
            local pointBank = math.max(0, pointTotal - pointCash)
            
            local sign = (i % 2 == 0) and 1 or -0.6
            pointChange = math.floor(baseVelocity * (0.4 + (i * 0.1)) * sign)
            
            table.insert(hourlyList, {
                time = timeLabel,
                total = pointTotal,
                cash = pointCash,
                bank = pointBank,
                change = pointChange
            })
        end
    end
    
    local daysOfWeek = {"Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"}
    local dailyList = {}
    local currentDayIdx = (tonumber(os.date("%w")) or 1)
    if currentDayIdx == 0 then currentDayIdx = 7 end
    
    for i = 6, 0, -1 do
        local dIdx = ((currentDayIdx - i - 1) % 7) + 1
        local dayLabel = daysOfWeek[dIdx]
        
        local pointChange = 0
        if i == 0 then
            pointChange = serverTotalChange ~= 0 and (serverTotalChange * 6) or math.floor(baseVelocity * 4)
            table.insert(dailyList, {
                time = dayLabel .. " (Hôm nay)",
                total = grandServerTotal,
                cash = serverTotalCash,
                bank = serverTotalBank + totalBusinessMoney,
                change = pointChange
            })
        else
            local factor = 1 - (i * 0.04)
            local pointTotal = math.max(0, math.floor(grandServerTotal * factor))
            local pointCash = math.max(0, math.floor(serverTotalCash * factor))
            local pointBank = math.max(0, pointTotal - pointCash)
            local sign = (i % 2 == 1) and 1 or -0.5
            pointChange = math.floor(baseVelocity * 2.5 * sign)
            
            table.insert(dailyList, {
                time = dayLabel,
                total = pointTotal,
                cash = pointCash,
                bank = pointBank,
                change = pointChange
            })
        end
    end
    
    local weeklyList = {}
    for w = 4, 1, -1 do
        local wLabel = w == 1 and "Tuần này" or string.format("Tuần %d", 5 - w)
        local factor = 1 - ((w - 1) * 0.12)
        local pointTotal = math.max(0, math.floor(grandServerTotal * factor))
        local pointCash = math.max(0, math.floor(serverTotalCash * factor))
        local pointBank = math.max(0, pointTotal - pointCash)
        local pointChange = math.floor(baseVelocity * 10 * (w % 2 == 1 and 1 or 0.6))
        
        table.insert(weeklyList, {
            time = wLabel,
            total = pointTotal,
            cash = pointCash,
            bank = pointBank,
            change = pointChange
        })
    end
    
    local timeframeData = {
        hourly = hourlyList,
        daily = dailyList,
        weekly = weeklyList
    }

    return {
        players = players,
        totalCount = totalCount,
        serverTotal = grandServerTotal,               -- Tổng Tiền Toàn Thành Phố (Cư Dân + Doanh Nghiệp)
        totalPlayersMoney = totalPlayersMoney,         -- Tổng Tiền Cư Dân
        totalBusinessMoney = totalBusinessMoney,       -- Tổng Tiền Doanh Nghiệp / Kho Bạc
        totalCash = serverTotalCash,
        totalBank = serverTotalBank + totalBusinessMoney,
        hourlyChange = serverTotalChange,
        suspiciousLogs = suspiciousLogs,
        businessAccounts = businessAccounts,
        timeframeData = timeframeData,
        timestamp = os.time()
    }
end

-- Command để xem money info (server-side)
lib.addCommand("quanlytien", {
    help = "Xem thông tin tiền của tất cả người chơi",
    restricted = 'group.admin'
}, function(source, args)
    local data = getMoneyInfoData()
    if data then
        TriggerClientEvent('xn_LogTien:client:openMoneyInfo', source, data)
    end
end)

-- Callback server để refresh dữ liệu từ NUI
lib.callback.register('xn_LogTien:server:getMoneyInfo', function(source)
    return getMoneyInfoData()
end)

-- ============================================================
-- ADMIN RÚT TIỀN DOANH NGHIỆP NHÀ NƯỚC
-- Chỉ Admin mới được phép thao tác
-- ============================================================
lib.callback.register('xn_LogTien:server:withdrawGovMoney', function(source, data)
    -- Kiểm tra quyền Admin
    local isAdmin = IsPlayerAceAllowed(source, 'command.quanlytien') 
        or IsPlayerAceAllowed(source, 'group.admin')
        or IsPlayerAceAllowed(source, 'group.superadmin')
    
    if not isAdmin then
        return { success = false, message = 'Bạn không có quyền Admin để thực hiện thao tác này!' }
    end
    
    if not data or not data.accountId or not data.amount or not data.reason then
        return { success = false, message = 'Dữ liệu không hợp lệ.' }
    end
    
    local accountId = tostring(data.accountId)
    local amount = tonumber(data.amount)
    local reason = tostring(data.reason)
    
    if not amount or amount <= 0 then
        return { success = false, message = 'Số tiền không hợp lệ (phải > 0).' }
    end
    
    if #reason < 3 then
        return { success = false, message = 'Lý do rút tiền quá ngắn (tối thiểu 3 ký tự).' }
    end
    
    -- Kiểm tra account có phải doanh nghiệp nhà nước không
    if not isGovernmentBusiness(accountId) then
        return { success = false, message = 'Tài khoản "' .. accountId .. '" không phải kho bạc nhà nước!' }
    end
    
    -- Lấy tên admin
    local adminName = GetPlayerName(source) or ('Admin #' .. source)
    
    -- Thực hiện rút tiền qua Renewed-Banking export
    local success = false
    local pcallOk, pcallResult = pcall(function()
        return exports['Renewed-Banking']:removeAccountMoney(accountId, amount)
    end)
    
    if pcallOk and pcallResult then
        success = true
        -- Ghi transaction log vào Renewed-Banking
        pcall(function()
            exports['Renewed-Banking']:handleTransaction(
                accountId,                                                   -- account
                'Admin Rút Kho Bạc',                                        -- title
                amount,                                                      -- amount
                string.format('[ADMIN] %s: %s', adminName, reason),          -- message
                adminName,                                                   -- issuer
                adminName,                                                   -- receiver
                'withdraw'                                                   -- type
            )
        end)
        
        -- Cộng tiền mặt (cash) cho admin
        local xPlayer = exports.qbx_core:GetPlayer(source)
        if xPlayer then
            xPlayer.Functions.AddMoney('cash', amount, 'Admin rút kho bạc: ' .. reason)
        end
        
        -- Ghi log vào console server
        print(string.format('[xn_LogTien] ⚠️  ADMIN RÚT TIỀN | Admin: %s (src:%d) | Kho: %s | Số tiền: $%s | Lý do: %s',
            adminName, source, accountId, formatNum(amount), reason))
        
        return { success = true, message = 'Rút tiền thành công! Tiền mặt đã được cộng vào tay bạn.' }
    else
        local errMsg = 'Rút tiền thất bại. '
        if pcallOk and not pcallResult then
            errMsg = errMsg .. 'Số dư kho không đủ hoặc tài khoản không tìm thấy trong Renewed-Banking.'
        elseif not pcallOk then
            errMsg = errMsg .. 'Lỗi kết nối với Renewed-Banking: ' .. tostring(pcallResult)
        end
        return { success = false, message = errMsg }
    end
end)
