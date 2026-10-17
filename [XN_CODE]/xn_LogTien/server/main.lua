
Config.WebHook = "https://discord.com/api/webhooks/1512572618669162638/muVFM4Ut422P7H4dUwkpcAAZj2juu3QXNhS9BOBgDQViFuGp-qFv2AOY3P-cEZAoAtAq"
Config.WebHook_GT = ""

-- Bảng lưu lịch sử trong RAM
local MoneyHistory = {}

function sendToDiscord(message) --Functions to send the log to discord
    --print("^2[xn_LogTien] Đang gửi log lên Discord...^0")
    --print("^3[xn_LogTien] Độ dài message: " .. #message .. " ký tự^0")
    
    -- Kiểm tra message có quá dài không (Discord limit 4096 cho description)
    if #message > 4000 then
        --print("^1[xn_LogTien] CẢNH BÁO: Message quá dài! Discord có thể từ chối.^0")
        message = string.sub(message, 1, 4000) .. "\n... (đã cắt bớt)"
    end
    
    local time = os.date("*t")

    local embed = {
            {
                ["color"] = Config.LogColour, --Set color
                ["author"] = {
                    ["icon_url"] = Config.AvatarURL, -- et avatar
                    ["name"] = Config.ServerName, --Set name
                },
                ["title"] = "**".. Config.LogTitle .."**", --Set title
                ["description"] = message, --Set message
                ["footer"] = {
                    ["text"] = '' ..time.year.. '/' ..time.month..'/'..time.day..' '.. time.hour.. ':'..time.min, --Get time
                },
            }
        }

    PerformHttpRequest(Config.WebHook, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            --print("^1[xn_LogTien] Lỗi gửi Discord! Error code: " .. tostring(err) .. "^0")
            --print("^1Response: " .. tostring(text) .. "^0")
        else
            --print("^2[xn_LogTien] ✓ Đã gửi log lên Discord thành công!^0")
        end
    end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- Function để format số tiền theo dạng K, M, B
function formatMoney(amount)
    if not amount then return "$0" end
    
    local num = tonumber(amount)
    if not num then return "$0" end
    
    if num >= 1000000000 then
        return "$" .. math.floor(num / 100000000) / 10 .. "B"
    elseif num >= 1000000 then
        return "$" .. math.floor(num / 100000) / 10 .. "M"
    elseif num >= 1000 then
        return "$" .. math.floor(num / 100) / 10 .. "K"
    else
        return "$" .. num
    end
end

-- Function kiểm tra ID có phải là doanh nghiệp nhà nước không
function isGovernmentBusiness(businessId)
    if not businessId then return false end
    local lowerId = string.lower(tostring(businessId))
    for _, govId in ipairs(Config.BusinessAccounts.government) do
        local lowerGov = string.lower(govId)
        if lowerId == lowerGov or string.find(lowerId, lowerGov, 1, true) then
            return true
        end
    end
    return false
end

-- Function lấy tất cả business accounts từ các bảng ngân hàng FiveM
function getAllBusinessAccounts()
    -- 1. Thử query bank_accounts_new (Qbox / QBCore new)
    local success, result = pcall(function()
        return MySQL.query.await([[
            SELECT id, amount, transactions
            FROM bank_accounts_new
            WHERE amount > 0
            ORDER BY amount DESC
        ]])
    end)
    
    if success and result and #result > 0 then
        return result
    end

    -- 2. Thử query bank_accounts (okokBanking / qb-banking)
    success, result = pcall(function()
        return MySQL.query.await([[
            SELECT account_name AS id, amount, transactions
            FROM bank_accounts
            WHERE amount > 0
            ORDER BY amount DESC
        ]])
    end)
    
    if success and result and #result > 0 then
        return result
    end

    -- 3. Thử query management_funds (qb-management)
    success, result = pcall(function()
        return MySQL.query.await([[
            SELECT job AS id, amount
            FROM management_funds
            WHERE amount > 0
            ORDER BY amount DESC
        ]])
    end)
    
    if success and result and #result > 0 then
        return result
    end

    -- 4. Thử query addon_account_data (ESX)
    success, result = pcall(function()
        return MySQL.query.await([[
            SELECT account_name AS id, money AS amount
            FROM addon_account_data
            WHERE money > 0
            ORDER BY money DESC
        ]])
    end)

    if success and result and #result > 0 then
        return result
    end

    return {}
end

-- Function chia business accounts thành 2 loại
function separateBusinessAccounts()
    local allAccounts = getAllBusinessAccounts()
    local government = {}
    local private = {}
    
    for _, account in ipairs(allAccounts) do
        if isGovernmentBusiness(account.id) then
            table.insert(government, account)
        else
            table.insert(private, account)
        end
    end
    
    return government, private
end

-- Function format business message
function formatBusinessAccountMessage(accounts, headerKey, accountKey, totalKey, limit)
    if #accounts == 0 then
        return ""
    end
    
    local message = Lang:t("message." .. headerKey) .. "\n"
    local total = 0
    local displayLimit = math.min(limit, #accounts)
    
    for i = 1, displayLimit do
        local account = accounts[i]
        local amount = tonumber(account.amount) or 0
        total = total + amount
        
        -- Parse transactions JSON
        local transCount = 0
        if account.transactions then
            local success, trans = pcall(function()
                return json.decode(account.transactions)
            end)
            if success and trans and type(trans) == "table" then
                transCount = #trans
            end
        end
        
        message = message .. Lang:t("message." .. accountKey, {
            index = i,
            name = account.id,
            amount = formatMoney(amount),
            transactions = transCount
        }) .. "\n"
    end
    
    -- Tính tổng cho TẤT CẢ (không chỉ limit)
    local totalAll = 0
    for _, account in ipairs(accounts) do
        totalAll = totalAll + (tonumber(account.amount) or 0)
    end
    
    message = message .. Lang:t("message." .. totalKey, {
        totalMoney = formatMoney(totalAll)
    }) .. "\n"
    
    return message
end

-- Function lấy message của tất cả business accounts
function getBusinessAccountsMessage()
    if not Config.BusinessAccounts.enable then
        return ""
    end
    
    local government, private = separateBusinessAccounts()
    local message = ""
    
    -- Doanh nghiệp Nhà nước
    message = message .. formatBusinessAccountMessage(
        government,
        "government_header",
        "government_account",
        "total_government_money",
        Config.BusinessAccounts.topGovernment
    )
    
    -- Doanh nghiệp Tư nhân
    message = message .. formatBusinessAccountMessage(
        private,
        "private_header",
        "private_account",
        "total_private_money",
        Config.BusinessAccounts.topPrivate
    )
    
    return message
end

-- Function để load lịch sử từ database
function loadHistory()
    local success, result = pcall(function()
        return MySQL.Sync.fetchAll("SELECT citizenid, base_money, total_money, UNIX_TIMESTAMP(last_reset) as last_reset FROM money_history", {})
    end)
    
    local history = {}
    
    if success and result then
        for _, row in pairs(result) do
            history[row.citizenid] = {
                base_money = tonumber(row.base_money) or 0,
                total_money = tonumber(row.total_money) or 0,
                last_reset = tonumber(row.last_reset) or os.time()
            }
        end
    end
    
    return history
end

-- Function để lưu/cập nhật lịch sử vào database
function saveHistory(data, history)
    local success = pcall(function()
        local currentTime = os.time()
        local oneHourInSeconds = 3600
        
        for citizenid, currentMoney in pairs(data) do
            local oldRecord = history[citizenid]
            local baseMoney = currentMoney
            local shouldReset = true
            
            if oldRecord then
                -- Kiểm tra xem đã quá 1 tiếng chưa
                local timeSinceReset = currentTime - oldRecord.last_reset
                
                if timeSinceReset < oneHourInSeconds then
                    -- Chưa quá 1 tiếng, giữ base_money cũ
                    baseMoney = oldRecord.base_money
                    shouldReset = false
                end
            end
            
            if shouldReset then
                -- Reset chu kỳ mới
                MySQL.Sync.execute([[
                    INSERT INTO money_history (citizenid, base_money, total_money, last_reset, last_check) 
                    VALUES (?, ?, ?, NOW(), NOW())
                    ON DUPLICATE KEY UPDATE 
                        base_money = VALUES(base_money),
                        total_money = VALUES(total_money),
                        last_reset = NOW(),
                        last_check = NOW()
                ]], {citizenid, currentMoney, currentMoney})
            else
                -- Cập nhật total_money, giữ base_money và last_reset
                MySQL.Sync.execute([[
                    INSERT INTO money_history (citizenid, base_money, total_money, last_reset, last_check) 
                    VALUES (?, ?, ?, FROM_UNIXTIME(?), NOW())
                    ON DUPLICATE KEY UPDATE 
                        total_money = VALUES(total_money),
                        last_check = NOW()
                ]], {citizenid, baseMoney, currentMoney, oldRecord.last_reset})
            end
        end
    end)
    
    return success
end

-- Function để format thay đổi tiền
function formatMoneyChange(current, previous)
    if not previous or type(previous) == "table" then
        return ""
    end
    
    local change = current - previous
    if change == 0 then
        return ""
    end
    
    local sign = change > 0 and "+" or ""
    return " | " .. sign .. formatMoney(math.abs(change)) .. " so với lần trước"
end

-- Function tính tổng tiền server theo batch để tránh lag
function calculateTotalServerMoneyBatch()
    if not Config.BatchProcessing.enable then
        -- Không dùng batch, query trực tiếp
        local total = MySQL.Sync.fetchScalar([[
            SELECT SUM(total_money) AS total_server_money 
            FROM (
                SELECT JSON_VALUE(money, '$.cash') + JSON_VALUE(money, '$.bank') AS total_money
                FROM players
            ) AS player_money
            WHERE total_money > 0
        ]], {})
        return tonumber(total) or 0
    end
    
    -- Dùng batch processing
    local batchSize = Config.BatchProcessing.batchSize
    local delayMs = Config.BatchProcessing.delayMs
    
    -- Đếm tổng số players
    local totalPlayers = MySQL.Sync.fetchScalar("SELECT COUNT(*) FROM players", {})
    totalPlayers = tonumber(totalPlayers) or 0
    
    if totalPlayers == 0 then return 0 end
    
    local totalMoney = 0
    local batches = math.ceil(totalPlayers / batchSize)
    
    print(string.format("^3[xn_LogTien] Tính tổng tiền từ %d players qua %d batches...^0", totalPlayers, batches))
    
    for batchIndex = 0, batches - 1 do
        local offset = batchIndex * batchSize
        
        local batchSum = MySQL.Sync.fetchScalar([[
            SELECT SUM(total_money) AS batch_total
            FROM (
                SELECT JSON_VALUE(money, '$.cash') + JSON_VALUE(money, '$.bank') AS total_money
                FROM players
                LIMIT ? OFFSET ?
            ) AS player_money
            WHERE total_money > 0
        ]], {batchSize, offset})
        
        totalMoney = totalMoney + (tonumber(batchSum) or 0)
        
        -- Delay giữa các batch (trừ batch cuối)
        if batchIndex < batches - 1 then
            Wait(delayMs)
        end
    end
    
    print(string.format("^2[xn_LogTien] Hoàn thành tính tổng: %s^0", formatMoney(totalMoney)))
    return totalMoney
end

-- Function lưu history theo batch
function saveHistoryBatch(data, history)
    if not Config.BatchProcessing.enable then
        -- Không dùng batch, gọi function cũ
        return saveHistory(data, history)
    end
    
    local dataArray = {}
    for key, value in pairs(data) do
        table.insert(dataArray, {key = key, value = value})
    end
    
    local totalRecords = #dataArray
    if totalRecords == 0 then return true end
    
    local batchSize = math.min(50, Config.BatchProcessing.batchSize) -- Max 50 records/batch cho INSERT
    local delayMs = Config.BatchProcessing.delayMs
    local batches = math.ceil(totalRecords / batchSize)
    
    print(string.format("^3[xn_LogTien] Lưu %d records qua %d batches...^0", totalRecords, batches))
    
    local success = true
    local currentTime = os.time()
    local oneHourInSeconds = 3600
    
    for batchIndex = 1, batches do
        local startIdx = (batchIndex - 1) * batchSize + 1
        local endIdx = math.min(batchIndex * batchSize, totalRecords)
        
        local batchSuccess = pcall(function()
            for i = startIdx, endIdx do
                local citizenid = dataArray[i].key
                local currentMoney = dataArray[i].value
                local oldRecord = history[citizenid]
                local baseMoney = currentMoney
                local shouldReset = true
                
                if oldRecord then
                    local timeSinceReset = currentTime - oldRecord.last_reset
                    if timeSinceReset < oneHourInSeconds then
                        baseMoney = oldRecord.base_money
                        shouldReset = false
                    end
                end
                
                if shouldReset then
                    MySQL.Sync.execute([[
                        INSERT INTO money_history (citizenid, base_money, total_money, last_reset, last_check) 
                        VALUES (?, ?, ?, NOW(), NOW())
                        ON DUPLICATE KEY UPDATE 
                            base_money = VALUES(base_money),
                            total_money = VALUES(total_money),
                            last_reset = NOW(),
                            last_check = NOW()
                    ]], {citizenid, currentMoney, currentMoney})
                else
                    MySQL.Sync.execute([[
                        INSERT INTO money_history (citizenid, base_money, total_money, last_reset, last_check) 
                        VALUES (?, ?, ?, FROM_UNIXTIME(?), NOW())
                        ON DUPLICATE KEY UPDATE 
                            total_money = VALUES(total_money),
                            last_check = NOW()
                    ]], {citizenid, baseMoney, currentMoney, oldRecord.last_reset})
                end
            end
        end)
        
        if not batchSuccess then
            success = false
        end
        
        -- Delay giữa các batch (trừ batch cuối)
        if batchIndex < batches then
            Wait(delayMs)
        end
    end
    
    print(string.format("^2[xn_LogTien] Hoàn thành lưu history^0"))
    return success
end

CreateThread(function()
    while (Config.SendLogByTime.enable) do
        Wait(Config.SendLogByTime.time * (60 * 1000)) --Wait time before trigger the event
        TriggerEvent("mb-GetRichPlayer:server:sendLog") --Trigger sending log event
        TriggerEvent("mb-GetRichPlayer:server:sendLog_GT") --Trigger sending log event
    end
end)


lib.addCommand("topmoney", {
    help = "TOP MONEY",
    restricted = 'group.admin'
}, function(source, args)
    if (Config.OnlyTopRichest.enable) then
        TriggerEvent("mb-GetRichPlayer:server:getTopPlayerMoney", Config.LogMessageType)
    else
        TriggerEvent("mb-GetRichPlayer:server:getAllPlayerMoney", Config.LogMessageType)
    end
end)

--Event for TOP RICHEST ONLY
RegisterNetEvent("mb-GetRichPlayer:server:getTopPlayerMoney", function(type)
    -- Load lịch sử lần kiểm tra trước
    local history = loadHistory()
    
    -- Lấy tổng tiền của toàn bộ server (dùng batch processing)
    local totalServerMoney = calculateTotalServerMoneyBatch()
    
    if (type == "full") then
        local topRichestPlayers = MySQL.Sync.fetchAll([[
            SELECT 
                p.name, 
                p.money, 
                p.pid, 
                p.license,
                JSON_VALUE(p.money, '$.cash') + JSON_VALUE(p.money, '$.bank') AS total_money
            FROM players p
            GROUP BY p.pid
            ORDER BY total_money DESC 
            LIMIT ?
        ]], {Config.OnlyTopRichest.top})
        local resultWithLicense = ''
        local newHistory = {}

        for _, v in pairs(topRichestPlayers) do
            local pid = topRichestPlayers[_]["pid"]
            local currentMoney = tonumber(topRichestPlayers[_]["total_money"]) or 0
            local previousMoney = history[pid]
            local changeText = formatMoneyChange(currentMoney, previousMoney)
            
            resultWithLicense = resultWithLicense .. "`" .. _ .. "." .. Lang:t("message.top_with_license", {name = topRichestPlayers[_]["name"], pid = pid, license = topRichestPlayers[_]["license"], money = topRichestPlayers[_]["money"], totalMoney = formatMoney(currentMoney)})
            resultWithLicense = resultWithLicense .. changeText
            
            -- Lưu vào lịch sử mới
            newHistory[pid] = currentMoney
        end
        
        -- Thêm tổng tiền server
        resultWithLicense = resultWithLicense .. Lang:t("message.total_server_money", {totalServerMoney = formatMoney(totalServerMoney)})
        
        -- Thêm thông tin business accounts
        resultWithLicense = resultWithLicense .. getBusinessAccountsMessage()
        
        sendToDiscord(resultWithLicense) --Send log to discord
        
        -- Lưu lịch sử mới SAU KHI gửi Discord (dùng batch processing)
        saveHistoryBatch(newHistory, history)
    elseif (type == "standard") then
        local topRichestPlayers = MySQL.Sync.fetchAll([[
            SELECT 
                p.name, 
                p.money, 
                p.pid,
                JSON_VALUE(p.money, '$.cash') + JSON_VALUE(p.money, '$.bank') AS total_money
            FROM players p
            GROUP BY p.pid
            ORDER BY total_money DESC 
            LIMIT ?
        ]], {Config.OnlyTopRichest.top})
        local resultWithoutLicense = ''
        local newHistory = {}

        for _, v in pairs(topRichestPlayers) do
            local pid = topRichestPlayers[_]["pid"]
            local currentMoney = tonumber(topRichestPlayers[_]["total_money"]) or 0
            local previousMoney = history[pid]
            local changeText = formatMoneyChange(currentMoney, previousMoney)
            
            resultWithoutLicense = resultWithoutLicense .. "`" .. _ .. "." .. Lang:t("message.top_without_license", {name = topRichestPlayers[_]["name"], pid = pid, money = topRichestPlayers[_]["money"], totalMoney = formatMoney(currentMoney)})
            resultWithoutLicense = resultWithoutLicense .. changeText
            
            -- Lưu vào lịch sử mới
            newHistory[pid] = currentMoney
        end
        
        -- Thêm tổng tiền server
        resultWithoutLicense = resultWithoutLicense .. Lang:t("message.total_server_money", {totalServerMoney = formatMoney(totalServerMoney)})
        
        -- Thêm thông tin business accounts
        resultWithoutLicense = resultWithoutLicense .. getBusinessAccountsMessage()
        
        sendToDiscord(resultWithoutLicense) --Send log to discord
        
        -- Lưu lịch sử mới SAU KHI gửi Discord (dùng batch processing)
        saveHistoryBatch(newHistory, history)
    else
        local topRichestPlayers = MySQL.Sync.fetchAll([[
            SELECT 
                p.name, 
                p.pid,
                JSON_VALUE(p.money, '$.cash') + JSON_VALUE(p.money, '$.bank') AS total_money
            FROM players p
            GROUP BY p.pid
            ORDER BY total_money DESC 
            LIMIT ?
        ]], {Config.OnlyTopRichest.top})
        local shortMsg = ''
        local newHistory = {}

        for _, v in pairs(topRichestPlayers) do
            local pid = topRichestPlayers[_]["pid"]
            local currentMoney = tonumber(topRichestPlayers[_]["total_money"]) or 0
            local previousMoney = history[pid]
            local changeText = formatMoneyChange(currentMoney, previousMoney)
            
            shortMsg = shortMsg .. _ .. "." .. Lang:t("message.short_top_message", {name = topRichestPlayers[_]["name"], pid = pid, totalMoney = formatMoney(currentMoney)})
            shortMsg = shortMsg .. changeText .. "\n"
            
            -- Lưu vào lịch sử mới
            newHistory[pid] = currentMoney
        end
        
        -- Thêm tổng tiền server
        shortMsg = shortMsg .. Lang:t("message.total_server_money", {totalServerMoney = formatMoney(totalServerMoney)})

        -- Thêm thông tin business accounts
        shortMsg = shortMsg .. getBusinessAccountsMessage()

        sendToDiscord(shortMsg) --Send log to discord
        
        -- Lưu lịch sử SAU KHI gửi Discord (dùng batch processing)
        saveHistoryBatch(newHistory, history)
    end
end)

--Event for ALL PLAYER
RegisterNetEvent("mb-GetRichPlayer:server:getAllPlayerMoney", function(type)
    -- Load lịch sử lần kiểm tra trước
    local history = loadHistory()
    
    -- Lấy tổng tiền của toàn bộ server (dùng batch processing)
    local totalServerMoney = calculateTotalServerMoneyBatch()
    
    if (type == "full") then
        local topRichestPlayers = MySQL.Sync.fetchAll([[
            SELECT 
                p.name, 
                p.money, 
                p.pid, 
                p.license,
                JSON_VALUE(p.money, '$.cash') + JSON_VALUE(p.money, '$.bank') AS total_money
            FROM players p
            GROUP BY p.pid
            ORDER BY total_money DESC
        ]])
        local resultWithLicense = ''
        local newHistory = {}

        for _, v in pairs(topRichestPlayers) do
            local pid = topRichestPlayers[_]["pid"]
            local currentMoney = tonumber(topRichestPlayers[_]["total_money"]) or 0
            local previousMoney = history[pid]
            local changeText = formatMoneyChange(currentMoney, previousMoney)
            
            resultWithLicense = resultWithLicense .. "`" .. _ .. "." .. Lang:t("message.top_with_license", {name = topRichestPlayers[_]["name"], pid = pid, license = topRichestPlayers[_]["license"], money = topRichestPlayers[_]["money"], totalMoney = formatMoney(currentMoney)})
            resultWithLicense = resultWithLicense .. changeText
            
            -- Lưu vào lịch sử mới
            newHistory[pid] = currentMoney
        end
        
        -- Thêm tổng tiền server
        resultWithLicense = resultWithLicense .. Lang:t("message.total_server_money", {totalServerMoney = formatMoney(totalServerMoney)})

        -- Thêm thông tin business accounts
        resultWithLicense = resultWithLicense .. getBusinessAccountsMessage()

        sendToDiscord(resultWithLicense) --Send log to discord
        
        -- Lưu lịch sử SAU KHI gửi Discord (dùng batch processing)
        saveHistoryBatch(newHistory, history)
    elseif (type == "standard") then
        local topRichestPlayers = MySQL.Sync.fetchAll([[
            SELECT 
                p.name, 
                p.money, 
                p.pid,
                JSON_VALUE(p.money, '$.cash') + JSON_VALUE(p.money, '$.bank') AS total_money
            FROM players p
            GROUP BY p.pid
            ORDER BY total_money DESC
        ]])
        local resultWithoutLicense = ''
        local newHistory = {}

        for _, v in pairs(topRichestPlayers) do
            local pid = topRichestPlayers[_]["pid"]
            local currentMoney = tonumber(topRichestPlayers[_]["total_money"]) or 0
            local previousMoney = history[pid]
            local changeText = formatMoneyChange(currentMoney, previousMoney)
            
            resultWithoutLicense = resultWithoutLicense .. "`" .. _ .. "." .. Lang:t("message.top_without_license", {name = topRichestPlayers[_]["name"], pid = pid, money = topRichestPlayers[_]["money"], totalMoney = formatMoney(currentMoney)})
            resultWithoutLicense = resultWithoutLicense .. changeText
            
            -- Lưu vào lịch sử mới
            newHistory[pid] = currentMoney
        end
        
        -- Thêm tổng tiền server
        resultWithoutLicense = resultWithoutLicense .. Lang:t("message.total_server_money", {totalServerMoney = formatMoney(totalServerMoney)})

        -- Thêm thông tin business accounts
        resultWithoutLicense = resultWithoutLicense .. getBusinessAccountsMessage()

        sendToDiscord(resultWithoutLicense) --Send log to discord
        
        -- Lưu lịch sử SAU KHI gửi Discord (dùng batch processing)
        saveHistoryBatch(newHistory, history)
    else
        local topRichestPlayers = MySQL.Sync.fetchAll([[
            SELECT 
                p.name, 
                p.pid,
                JSON_VALUE(p.money, '$.cash') + JSON_VALUE(p.money, '$.bank') AS total_money
            FROM players p
            GROUP BY p.pid
            ORDER BY total_money DESC
        ]])
        local shortMsg = ''
        local newHistory = {}

        for _, v in pairs(topRichestPlayers) do
            local pid = topRichestPlayers[_]["pid"]
            local currentMoney = tonumber(topRichestPlayers[_]["total_money"]) or 0
            local previousMoney = history[pid]
            local changeText = formatMoneyChange(currentMoney, previousMoney)
            
            shortMsg = shortMsg .. _ .. "." .. Lang:t("message.short_top_message", {name = topRichestPlayers[_]["name"], pid = pid, totalMoney = formatMoney(currentMoney)})
            shortMsg = shortMsg .. changeText .. "\n"
            
            -- Lưu vào lịch sử mới
            newHistory[pid] = currentMoney
        end
        
        -- Thêm tổng tiền server
        shortMsg = shortMsg .. Lang:t("message.total_server_money", {totalServerMoney = formatMoney(totalServerMoney)})

        -- Thêm thông tin business accounts
        shortMsg = shortMsg .. getBusinessAccountsMessage()

        sendToDiscord(shortMsg) --Send log to discord
        
        -- Lưu lịch sử SAU KHI gửi Discord (dùng batch processing)
        saveHistoryBatch(newHistory, history)
    end
end)

--Auto send log to discord
RegisterNetEvent("mb-GetRichPlayer:server:sendLog", function()
    if (Config.OnlyTopRichest.enable) then
        TriggerEvent("mb-GetRichPlayer:server:getTopPlayerMoney", Config.LogMessageType)
    else
        TriggerEvent("mb-GetRichPlayer:server:getAllPlayerMoney", Config.LogMessageType)
    end
end)

-- --========== LOG TIEN GIA TOC
-- function sendToDiscord_GT(message) --Functions to send the log to discord
--     local time = os.date("*t")

--     local embed = {
--             {
--                 ["color"] = Config.LogColour, --Set color
--                 ["author"] = {
--                     ["icon_url"] = Config.AvatarURL_GT, -- et avatar
--                     ["name"] = Config.ServerName_GT, --Set name
--                 },
--                 ["title"] = "**".. Config.LogTitle_GT .."**", --Set title
--                 ["description"] = message, --Set message
--                 ["footer"] = {
--                     ["text"] = '' ..time.year.. '/' ..time.month..'/'..time.day..' '.. time.hour.. ':'..time.min, --Get time
--                 },
--             }
--         }

--     PerformHttpRequest(Config.WebHook_GT, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
-- end

-- QBCore.Commands.Add("loggt", "Test log tiền gia tộc", {}, false, function(source)
--     if (Config.OnlyTopRichest.enable) then
--         TriggerEvent("mb-GetRichPlayer:server:getTopPlayerMoney_GT", Config.LogMessageType_GT)
--     else
--         TriggerEvent("mb-GetRichPlayer:server:getAllPlayerMoney_GT", Config.LogMessageType_GT)
--     end
-- end, "admin")

-- --Event for TOP RICHEST ONLY
-- RegisterNetEvent("mb-GetRichPlayer:server:getTopPlayerMoney_GT", function(type)
--     if (type == "full") then
--         local topRichestPlayers_gt = MySQL.Sync.fetchAll("SELECT `name`, `money`, `citizenid`, `license`, JSON_VALUE(money, '$.crypto') AS `total_money` FROM `players` GROUP BY `name` ORDER BY `total_money` DESC LIMIT ?", {Config.OnlyTopRichest.top})
--         local resultWithLicense_gt = ''

--         for _, v in pairs(topRichestPlayers_gt) do
--             resultWithLicense_gt = resultWithLicense_gt .. "`" .. _ .. "." .. Lang:t("message.top_with_license", {name = topRichestPlayers_gt[_]["name"], citizenid = topRichestPlayers_gt[_]["citizenid"], license = topRichestPlayers_gt[_]["license"], money = topRichestPlayers_gt[_]["money"], totalMoney = topRichestPlayers_gt[_]["total_money"]})
--         end

--         sendToDiscord_GT(resultWithLicense_gt) --Send log to discord
--     elseif (type == "standard") then
--         local topRichestPlayers_gt = MySQL.Sync.fetchAll("SELECT `name`, `money`, `citizenid`, JSON_VALUE(money, '$.crypto') AS `total_money` FROM `players` GROUP BY `name` ORDER BY `total_money` DESC LIMIT ?", {Config.OnlyTopRichest.top})
--         local resultWithoutLicense_gt = ''

--         for _, v in pairs(topRichestPlayers_gt) do
--             resultWithoutLicense_gt = resultWithoutLicense_gt .. "`" .. _ .. "." .. Lang:t("message.top_without_license", {name = topRichestPlayers_gt[_]["name"], citizenid = topRichestPlayers_gt[_]["citizenid"], money = topRichestPlayers_gt[_]["money"], totalMoney = topRichestPlayers_gt[_]["total_money"]})
--         end

--         sendToDiscord_GT(resultWithoutLicense_gt) --Send log to discord
--     else
--         local topRichestPlayers_gt = MySQL.Sync.fetchAll("SELECT `name`, `money`, `citizenid`, JSON_VALUE(money, '$.crypto') AS `total_money` FROM `players` GROUP BY `name` ORDER BY `total_money` DESC LIMIT ?", {Config.OnlyTopRichest.top})
--         local shortMsg_gt = ''

--         for _, v in pairs(topRichestPlayers_gt) do
--             shortMsg_gt = shortMsg_gt .. "`" .. _ .. "." .. Lang:t("message.short_top_message", {name = topRichestPlayers_gt[_]["name"], citizenid = topRichestPlayers_gt[_]["citizenid"], totalMoney = topRichestPlayers_gt[_]["total_money"]})
--         end

--         sendToDiscord_GT(shortMsg_gt) --Send log to discord
--     end
-- end)

-- --Event for ALL PLAYER
-- RegisterNetEvent("mb-GetRichPlayer:server:getAllPlayerMoney_GT", function(type)
--     if (type == "full") then
--         local topRichestPlayers_gt = MySQL.Sync.fetchAll("SELECT `name`, `money`, `citizenid`, `license`, JSON_VALUE(money, '$.crypto') AS `total_money` FROM `players` GROUP BY `name` ORDER BY `total_money` DESC")
--         local resultWithLicense_gt = ''

--         for _, v in pairs(topRichestPlayers_gt) do
--             resultWithLicense_gt = resultWithLicense_gt .. "`" .. _ .. "." .. Lang:t("message.top_with_license", {name = topRichestPlayers_gt[_]["name"], citizenid = topRichestPlayers_gt[_]["citizenid"], license = topRichestPlayers_gt[_]["license"], money = topRichestPlayers_gt[_]["money"], totalMoney = topRichestPlayers_gt[_]["total_money"]})
--         end

--         sendToDiscord_GT(resultWithLicense_gt) --Send log to discord
--     elseif (type == "standard") then
--         local topRichestPlayers_gt = MySQL.Sync.fetchAll("SELECT `name`, `money`, `citizenid`, JSON_VALUE(money, '$.crypto') AS `total_money` FROM `players` GROUP BY `name` ORDER BY `total_money` DESC")
--         local resultWithoutLicense_gt = ''

--         for _, v in pairs(topRichestPlayers_gt) do
--             resultWithoutLicense_gt = resultWithoutLicense_gt .. "`" .. _ .. "." .. Lang:t("message.top_without_license", {name = topRichestPlayers_gt[_]["name"], citizenid = topRichestPlayers_gt[_]["citizenid"], money = topRichestPlayers_gt[_]["money"], totalMoney = topRichestPlayers_gt[_]["total_money"]})
--         end

--         sendToDiscord_GT(resultWithoutLicense_gt) --Send log to discord
--     else
--         local topRichestPlayers_gt = MySQL.Sync.fetchAll("SELECT `name`, `money`, `citizenid`, JSON_VALUE(money, '$.crypto') AS `total_money` FROM `players` GROUP BY `name` ORDER BY `total_money` DESC")
--         local shortMsg_gt = ''

--         for _, v in pairs(topRichestPlayers_gt) do
--             shortMsg_gt = shortMsg_gt .. "`" .. _ .. "." .. Lang:t("message.short_top_message", {name = topRichestPlayers_gt[_]["name"], citizenid = topRichestPlayers_gt[_]["citizenid"], totalMoney = topRichestPlayers_gt[_]["total_money"]})
--         end

--         sendToDiscord_GT(shortMsg_gt) --Send log to discord
--     end
-- end)

-- --Auto send log to discord
-- RegisterNetEvent("mb-GetRichPlayer:server:sendLog_GT", function()
--     if (Config.OnlyTopRichest.enable) then
--         TriggerEvent("mb-GetRichPlayer:server:getTopPlayerMoney_GT", Config.LogMessageType_GT)
--     else
--         TriggerEvent("mb-GetRichPlayer:server:getAllPlayerMoney_GT", Config.LogMessageType_GT)
--     end
-- end)