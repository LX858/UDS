local QBCore

Config.SePay.apiToken = "9SJQAVNP613H4IDPBA89C5NDKZEPE1XCSVETDGR7YDHJMTBORMQSLNVOQUV75REY"
Config.SePay.webhookSecret = "38367931e6839882a119b7f46770dd5dde8dd1d53455c3d659ce69d013b20c72maitranhoanglong"
Config.SePay.discordWebhook = "https://discord.com/api/webhooks/1512480891971047472/g2ClZnusMWSJKDIdxCDlrhnDY5CpgvphhVTW-obJY8Qb6V-f7PLdRpT_yEjMb9eXQ9AC"

local function EnsureCore()
    if QBCore then return QBCore end
    local ok, core = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if not ok or not core then
        error('[xn_case/sepay] Không lấy được Core — đảm bảo qbx_core (hoặc qb-core) start TRƯỚC xn_case')
    end
    QBCore = core
    return QBCore
end

local function GetPlayerPid(Player)
    if not Player or not Player.PlayerData then return nil end

    local pid = Player.PlayerData.pid
    if pid ~= nil and tostring(pid) ~= '' then
        return tostring(pid)
    end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid or citizenid == '' then
        return nil
    end

    local ok, rows = pcall(function()
        return MySQL.query.await(
            'SELECT pid FROM players WHERE citizenid = ? LIMIT 1',
            { citizenid }
        )
    end)

    if ok and rows and rows[1] and rows[1].pid ~= nil and tostring(rows[1].pid) ~= '' then
        local dbPid = tostring(rows[1].pid)
        Player.PlayerData.pid = rows[1].pid
        return dbPid
    end

    return nil
end

local function GetPlayerByPid(pid)
    if not pid then return nil end
    pid = tostring(pid)
    for _, player in pairs(EnsureCore().Functions.GetQBPlayers()) do
        if player.PlayerData and player.PlayerData.pid and tostring(player.PlayerData.pid) == pid then
            return player
        end
    end
    return nil
end

local function TransactionIdRandom()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local result = ""
    for i = 1, 10 do
        local rand = math.random(1, #charset)
        result = result .. string.sub(charset, rand, rand)
    end
    return result
end

local function GetContentTransaction(content)
    if not content then return nil end
    local prefix = Config.SePay.transactionPrefix or "UDS"
    local upper = string.upper(tostring(content))
    return string.match(upper, "(" .. prefix .. "[A-Z]+%d+)")
end

local function UrlEncode(str)
    if not str then return '' end
    return tostring(str):gsub("([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function ResolveTransactionId(data)
    if type(data) ~= 'table' then return nil end
    local prefix = Config.SePay.transactionPrefix or "UDS"

    if type(data.code) == 'string' and data.code ~= '' then
        local code = string.upper(data.code)
        if string.match(code, "^" .. prefix .. "[A-Z]+%d+") then
            return code
        end
    end

    if data.content then
        return GetContentTransaction(data.content)
    end

    return nil
end

local function GenerateQR(amount, transactionCode)
    return string.format(
        'https://qr.sepay.vn/img?acc=%s&bank=%s&amount=%d&des=%s&template=%s',
        Config.SePay.accountNumber,
        Config.SePay.bankCode,
        amount,
        "SEVQR+" .. transactionCode,
        Config.SePay.template
    )
end

local function GetVietnamTime()
    return os.date("%d/%m/%Y | %H:%M:%S", os.time() + (7 * 3600))
end

local function GetVietnamTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%S", os.time() + (7 * 3600)) .. "+07:00"
end

local function VndToCoin(vndAmount)
    local rate = tonumber(Config.SePay.rate) or 1000
    if rate <= 0 then rate = 1000 end
    return math.floor(vndAmount / rate)
end

local function GetTxAdminId(pid, dbRowId)
    local Player = GetPlayerByPid(pid)
    if Player and Player.PlayerData and Player.PlayerData.source then
        return tostring(Player.PlayerData.source)
    end
    if dbRowId then
        return tostring(dbRowId) .. " (offline)"
    end
    return "Offline"
end

local function GetPlayerDepositInfo(pid)
    local rows = MySQL.query.await(
        'SELECT id, charinfo, coin, coin_da_nap FROM players WHERE pid = ? LIMIT 1',
        { pid }
    )
    if not rows or #rows == 0 then return nil end
    local row = rows[1]

    local name = "Unknown"
    local charinfo = row.charinfo
    if type(charinfo) == 'string' then
        local ok, parsed = pcall(json.decode, charinfo)
        if ok then charinfo = parsed end
    end
    if type(charinfo) == 'table' then
        name = string.format("%s %s", charinfo.firstname or "", charinfo.lastname or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then name = "Unknown" end
    end

    local Player = GetPlayerByPid(pid)
    if Player and Player.PlayerData.charinfo then
        local ci = Player.PlayerData.charinfo
        name = string.format("%s %s", ci.firstname or "", ci.lastname or ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    return {
        name = name,
        txAdminId = GetTxAdminId(pid, row.id),
        oldCoin = tonumber(row.coin) or 0,
        oldCoinDaNap = tonumber(row.coin_da_nap) or 0,
    }
end

local function SendDepositLogToDiscord(logData)
    if not Config.SePay.discordLogEnabled then return end
    local webhook = Config.SePay.discordWebhook
    if type(webhook) ~= 'string' or webhook == '' then return end

    local oldCoin = logData.oldCoin or 0
    local coinAmount = logData.coinAmount or 0
    local oldDaNap = logData.oldCoinDaNap or 0
    local vndAmount = logData.vndAmount or 0

    local embed = {
        {
            author = {
                name = "HỆ THỐNG NẠP XU - UNDERSTAR",
                icon_url = "https://cdn-icons-png.flaticon.com/512/9690/9690169.png"
            },
            color = 5025616,
            thumbnail = {
                url = "https://cdn-icons-png.flaticon.com/512/1170/1170678.png"
            },
            description = table.concat({
                "Người chơi: `" .. tostring(logData.name or "Unknown") .. "`",
                "ID: `" .. tostring(logData.txAdminId or "?") .. "`",
                "Mã giao dịch: `" .. tostring(logData.transactionId or "?") .. "`",
                "",
                "Tiền chuyển: **" .. vndAmount .. " VND**",
                "Nhận Xu: **" .. coinAmount .. " Xu**",
                "Tỷ giá: " .. tostring(Config.SePay.rate or 1000) .. " VND = 1 Xu",
                "",
                "Xu trước: `" .. oldCoin .. "` → sau: **`" .. (oldCoin + coinAmount) .. "`**",
                "Tổng đã nạp trước: `" .. oldDaNap .. "` → sau: **`" .. (oldDaNap + coinAmount) .. "`**",
                "",
                "Thời gian (VN): " .. GetVietnamTime(),
                "Trạng thái: Giao dịch thành công"
            }, "\n"),
            footer = {
                text = "Log Nạp thẻ • xn_case • GMT+7",
                icon_url = "https://cdn-icons-png.flaticon.com/512/5968/5968779.png"
            },
            timestamp = GetVietnamTimestamp()
        }
    }

    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = "Log Nạp thẻ",
        embeds = embed,
        avatar_url = "https://cdn-icons-png.flaticon.com/512/9378/9378304.png"
    }), { ['Content-Type'] = 'application/json' })
end

local processingTransactions = {}
local isPolling = false
local lastPollTimestamp = 0

local function AddCoinByPid(pid, amount)
    local ok = pcall(function()
        local rows = MySQL.query.await(
            'SELECT citizenid, coin FROM players WHERE pid = ? LIMIT 1',
            { pid }
        )
        if not rows or not rows[1] or not rows[1].citizenid then
            error(("Không tìm thấy citizenid cho pid=%s"):format(tostring(pid)))
        end

        local citizenid = rows[1].citizenid
        MySQL.update.await(
            'UPDATE players SET coin = COALESCE(coin, 0) + ?, coin_da_nap = COALESCE(coin_da_nap, 0) + ? WHERE citizenid = ?',
            { amount, amount, citizenid }
        )

        local Player = GetPlayerByPid(pid)
        if Player and Player.PlayerData then
            if Player.PlayerData.coin ~= nil then
                Player.PlayerData.coin = (tonumber(Player.PlayerData.coin) or 0) + amount
            end
            if Player.PlayerData.coin_da_nap ~= nil then
                Player.PlayerData.coin_da_nap = (tonumber(Player.PlayerData.coin_da_nap) or 0) + amount
            end
        end
    end)

    return ok
end

local function AddTransaction(pid, codeTrans, amount, status)
    local created_at = os.time()
    local timeout = Config.SePay.paymentTimeoutMinutes or 15
    local expires_at = created_at + (timeout * 60)

    return pcall(function()
        MySQL.insert.await(
            'INSERT INTO `sepay_transactions` (identifier, transaction_code, type, amount, description, status, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            {
                pid,
                codeTrans,
                'nap-tien',
                amount,
                'Nạp tiền Xu',
                status,
                created_at,
                expires_at
            }
        )
    end)
end

local function UpdateTransaction(codeTrans, webhookAmount, status)
    MySQL.update.await(
        'UPDATE `sepay_transactions` SET status = ?, webhook_amount = ?, completed_at = ? WHERE transaction_code = ?',
        { status, webhookAmount, os.time(), codeTrans }
    )
end

local function CreateTransaction(pid, amount)
    local prefix = Config.SePay.transactionPrefix or "UDS"
    local transactionId = ("%s%s%s"):format(prefix, TransactionIdRandom(), os.time())
    local ok, err = AddTransaction(pid, transactionId, amount, "pending")
    if not ok then
        return nil, err
    end
    return {
        transactionId = transactionId,
        amount = amount
    }, nil
end

local function HandleWebhook(data)
    if not data or type(data) ~= 'table' then
        return false
    end

    if data.transferType and tostring(data.transferType):lower() ~= 'in' then
        return false
    end

    if not data.content and (not data.code or data.code == '') then
        return false
    end

    local transferAmount = tonumber(data.transferAmount)
    if not transferAmount or transferAmount <= 0 or transferAmount > 20000000 then
        return false
    end

    local transactionId = ResolveTransactionId(data)
    if not transactionId then
        return false
    end

    -- 1. Mutex Lock in-memory: Chặn ngay nếu transaction này đang được xử lý bởi 1 luồng khác
    if processingTransactions[transactionId] then
        return false
    end
    processingTransactions[transactionId] = true

    local success = false
    local pcallOk, pcallErr = pcall(function()
        -- 2. Atomic Lock trong MySQL:
        -- Chuyển trạng thái từ 'pending' sang 'processing'.
        -- Chỉ luồng đầu tiên thực hiện thành công (affectedRows > 0) mới được quyền cộng tiền.
        local affectedRows = MySQL.update.await(
            'UPDATE `sepay_transactions` SET status = "processing", webhook_amount = ? WHERE transaction_code = ? AND status = "pending"',
            { transferAmount, transactionId }
        )

        if not affectedRows or affectedRows == 0 then
            -- Giao dịch đã được xử lý hoặc không ở trạng thái pending -> thoát, chống duplicate
            return
        end

        local result = MySQL.query.await(
            'SELECT * FROM `sepay_transactions` WHERE transaction_code = ? LIMIT 1',
            { transactionId }
        )

        if not result or #result == 0 then
            return
        end

        local transaction = result[1]
        local pid = tostring(transaction.identifier)
        local coinAmount = VndToCoin(transferAmount)

        if coinAmount <= 0 then
            MySQL.update.await(
                'UPDATE `sepay_transactions` SET status = "failed" WHERE transaction_code = ?',
                { transactionId }
            )
            return
        end

        local playerInfo = GetPlayerDepositInfo(pid)
        local addOk = AddCoinByPid(pid, coinAmount)
        if not addOk then
            -- Rollback về pending nếu việc cộng coin gặp sự cố database
            MySQL.update.await(
                'UPDATE `sepay_transactions` SET status = "pending" WHERE transaction_code = ?',
                { transactionId }
            )
            return
        end

        -- Cập nhật hoàn thành
        UpdateTransaction(transactionId, transferAmount, "completed")

        -- Gửi Discord log
        SendDepositLogToDiscord({
            name = playerInfo and playerInfo.name or "Unknown",
            txAdminId = playerInfo and playerInfo.txAdminId or "Offline",
            transactionId = transactionId,
            vndAmount = transferAmount,
            coinAmount = coinAmount,
            oldCoin = playerInfo and playerInfo.oldCoin or 0,
            oldCoinDaNap = playerInfo and playerInfo.oldCoinDaNap or 0,
        })

        -- Thông báo người chơi
        local Player = GetPlayerByPid(pid)
        if Player then
            TriggerClientEvent('es-case:depositCompleted', Player.PlayerData.source, {
                amount = coinAmount,
                transactionId = transactionId
            })
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source,
                ('Nạp thành công %s Xu!'):format(coinAmount), 'success')
        end

        success = true
    end)

    processingTransactions[transactionId] = nil

    if not pcallOk then
        print(('[xn_case/sepay] Lỗi trong HandleWebhook GD %s: %s'):format(tostring(transactionId), tostring(pcallErr)))
        return false
    end

    return success
end

lib.callback.register('xn_case:createPayment', function(source, data)
    local Player = EnsureCore().Functions.GetPlayer(source)
    if not Player then
        return { success = false, message = "Không tìm thấy người chơi" }
    end

    local pid = GetPlayerPid(Player)
    if not pid then
        return {
            success = false,
            message = "Không tìm thấy PID — player chưa có cột pid trong database"
        }
    end

    local amount = tonumber(data and data.amount) or 0
    local minAmount = Config.SePay.minAmount or 10000

    if amount < minAmount then
        return {
            success = false,
            message = ("Số tiền tối thiểu là %s VND"):format(minAmount)
        }
    end

    local transaction = CreateTransaction(pid, amount)
    if not transaction then
        return {
            success = false,
            message = "Tạo giao dịch thất bại — chạy file sepay.sql để tạo bảng sepay_transactions"
        }
    end

    local timeout = Config.SePay.paymentTimeoutMinutes or 15
    return {
        success = true,
        message = "Tạo giao dịch thành công!",
        data = {
            id = transaction.transactionId,
            amount = transaction.amount,
            image = GenerateQR(transaction.amount, transaction.transactionId),
            endTime = (os.time() + timeout * 60) * 1000
        }
    }
end)

lib.callback.register('xn_case:cancelPayment', function(source, data)
    local Player = EnsureCore().Functions.GetPlayer(source)
    if not Player then
        return { success = false, message = "Không tìm thấy người chơi" }
    end

    local pid = GetPlayerPid(Player)
    local transCode = data and data.id
    if not transCode then
        return { success = false, message = "Thiếu mã giao dịch" }
    end

    local ok, result = pcall(function()
        return MySQL.query.await(
            'SELECT identifier, status FROM `sepay_transactions` WHERE transaction_code = ? LIMIT 1',
            { transCode }
        )
    end)

    if not ok then
        return { success = false, message = "Lỗi database khi hủy giao dịch" }
    end

    if not result or #result == 0 then
        return { success = false, message = "Giao dịch không tồn tại" }
    end

    if tostring(result[1].identifier) ~= tostring(pid) then
        return { success = false, message = "Không có quyền hủy giao dịch này" }
    end

    if result[1].status ~= "pending" then
        return { success = false, message = "Giao dịch không thể hủy" }
    end

    local updated = pcall(function()
        UpdateTransaction(transCode, 0, "failed")
    end)

    if not updated then
        return { success = false, message = "Lỗi database khi cập nhật giao dịch" }
    end

    return { success = true, message = "Đã hủy thanh toán" }
end)

local function CanUseSePayApi()
    return Config.SePay
        and Config.SePay.apiPollEnabled
        and type(Config.SePay.apiToken) == 'string'
        and Config.SePay.apiToken ~= ''
end

local function GetPendingTransactionMap()
    local ok, pending = pcall(function()
        return MySQL.query.await(
            'SELECT transaction_code FROM `sepay_transactions` WHERE status = "pending" AND expires_at > ?',
            { os.time() }
        )
    end)

    if not ok or not pending then
        return nil
    end

    local map = {}
    for _, row in ipairs(pending) do
        map[row.transaction_code] = true
    end
    return map
end

local function BuildWebhookDataFromSePayTx(tx)
    local amountIn = tonumber(tx.amount_in) or tonumber(tx.transferAmount) or 0
    return {
        id = tx.id or tx.reference_number,
        transferType = tx.transfer_type or 'in',
        transferAmount = amountIn,
        code = tx.code,
        content = tx.transaction_content or tx.content,
    }, amountIn
end

local function MatchesOurBankAccount(tx)
    local expectedAcc = tostring(Config.SePay.accountNumber or '')
    if expectedAcc == '' then return true end

    local acc = tostring(tx.account_number or tx.accountNumber or '')
    if acc == '' then return true end

    return acc == expectedAcc
end

local function ProcessIncomingTransactions(transactions, pendingMap)
    if type(transactions) ~= 'table' or type(pendingMap) ~= 'table' then
        return 0
    end

    local matched = 0
    for _, tx in ipairs(transactions) do
        if not MatchesOurBankAccount(tx) then
            goto continue
        end

        local webhookData, amountIn = BuildWebhookDataFromSePayTx(tx)
        if amountIn <= 0 or webhookData.transferType ~= 'in' then
            goto continue
        end

        local resolved = ResolveTransactionId(webhookData)
        if resolved and pendingMap[resolved] then
            -- Xử lý giao dịch và xóa khỏi pending map ngay lập tức
            pendingMap[resolved] = nil
            if HandleWebhook(webhookData) then
                matched = matched + 1
            end
        end

        ::continue::
    end

    return matched
end

local function FetchSePayApi(url, onDone)
    PerformHttpRequest(url, function(status, body)
        onDone(status, body)
    end, 'GET', '', {
        ['Authorization'] = 'Bearer ' .. Config.SePay.apiToken,
        ['Content-Type'] = 'application/json',
    })
end

local function PollAllPendingTransactions()
    if not CanUseSePayApi() then return end

    local now = os.time()
    -- Chống race condition & overlap: không cho phép chạy trùng lặp hoặc spam liên tục dưới 3 giây
    if isPolling or (now - lastPollTimestamp < 3) then
        return
    end

    isPolling = true
    lastPollTimestamp = now

    local function FinishPoll()
        isPolling = false
    end

    local pendingMap = GetPendingTransactionMap()
    if not pendingMap then
        FinishPoll()
        return
    end

    local pendingCount = 0
    for _ in pairs(pendingMap) do pendingCount = pendingCount + 1 end
    if pendingCount == 0 then
        FinishPoll()
        return
    end

    local minAmount = Config.SePay.minAmount or 1000
    local dateFrom = os.date("%Y-%m-%d %H:%M:%S", os.time() - (3 * 3600))
    local bankAccountId = Config.SePay.bankAccountId

    local v2Url
    if type(bankAccountId) == 'string' and bankAccountId ~= '' then
        v2Url = string.format(
            'https://userapi.sepay.vn/v2/transactions?bank_account_id=%s&transfer_type=in&transaction_date_from=%s&amount_in_min=%d&per_page=50&transaction_date_sort=desc',
            UrlEncode(bankAccountId),
            UrlEncode(dateFrom),
            minAmount
        )
    else
        local prefix = Config.SePay.transactionPrefix or 'UDS'
        v2Url = string.format(
            'https://userapi.sepay.vn/v2/transactions?transfer_type=in&transaction_date_from=%s&amount_in_min=%d&q=%s&per_page=50&transaction_date_sort=desc',
            UrlEncode(dateFrom),
            minAmount,
            UrlEncode(prefix)
        )
    end

    FetchSePayApi(v2Url, function(status, body)
        if status ~= 200 then
            FinishPoll()
            return
        end

        local ok, parsed = pcall(json.decode, body)
        if not ok or type(parsed) ~= 'table' or parsed.status ~= 'success' then
            FinishPoll()
            return
        end

        local matched = ProcessIncomingTransactions(parsed.data, pendingMap)
        if matched > 0 then
            FinishPoll()
            return
        end

        local v1Url = string.format(
            'https://my.sepay.vn/userapi/transactions/list?limit=100&transaction_date_min=%s',
            UrlEncode(dateFrom)
        )

        FetchSePayApi(v1Url, function(v1Status, v1Body)
            if v1Status == 200 then
                local v1Ok, v1Parsed = pcall(json.decode, v1Body)
                if v1Ok and type(v1Parsed) == 'table' then
                    ProcessIncomingTransactions(v1Parsed.transactions, pendingMap)
                end
            end
            FinishPoll()
        end)
    end)
end

lib.callback.register('xn_case:checkPaymentStatus', function(source, data)
    local transCode = data and data.id
    if not transCode then
        return { status = "unknown" }
    end

    local ok, result = pcall(function()
        return MySQL.query.await(
            'SELECT status FROM `sepay_transactions` WHERE transaction_code = ? LIMIT 1',
            { transCode }
        )
    end)

    if not ok then
        return { status = "error" }
    end

    if not result or #result == 0 then
        return { status = "not_found" }
    end

    local currentStatus = result[1].status
    if currentStatus == 'pending' and CanUseSePayApi() then
        CreateThread(function()
            PollAllPendingTransactions()
        end)
    end

    return { status = currentStatus }
end)

lib.callback.register('xn_case:getPendingPayment', function(source)
    local Player = EnsureCore().Functions.GetPlayer(source)
    if not Player then
        return nil
    end

    local pid = GetPlayerPid(Player)
    if not pid then
        return nil
    end

    local ok, result = pcall(function()
        return MySQL.query.await(
            'SELECT * FROM `sepay_transactions` WHERE identifier = ? AND status = "pending" AND expires_at > ? ORDER BY created_at DESC LIMIT 1',
            { pid, os.time() }
        )
    end)

    if not ok then
        return nil
    end

    if not result or #result == 0 then
        return nil
    end

    local tx = result[1]
    return {
        id = tx.transaction_code,
        amount = tx.amount,
        image = GenerateQR(tx.amount, tx.transaction_code),
        endTime = tx.expires_at * 1000
    }
end)

lib.callback.register('xn_case:getDepositHistory', function(source)
    local Player = EnsureCore().Functions.GetPlayer(source)
    if not Player then
        return {}
    end

    local pid = GetPlayerPid(Player)
    if not pid then
        return {}
    end

    local ok, results = pcall(function()
        return MySQL.query.await(
            'SELECT transaction_code, amount, status, created_at, completed_at FROM `sepay_transactions` WHERE identifier = ? ORDER BY created_at DESC LIMIT 10',
            { pid }
        )
    end)

    if not ok then
        return {}
    end

    local history = {}
    if results then
        for _, v in ipairs(results) do
            history[#history + 1] = {
                transactionId = v.transaction_code,
                amount = v.amount,
                status = v.status,
                createdAt = v.created_at,
                completedAt = v.completed_at
            }
        end
    end

    return history
end)

local function GetWebhookPath()
    local configured = Config.SePay and Config.SePay.webhookPath
    if type(configured) ~= 'string' or configured == '' then
        configured = 'sepay-webhook'
    end
    configured = configured:gsub('^/+', ''):gsub('/+$', '')
    return '/' .. configured:lower()
end

local function IsWebhookPath(path)
    if not path then return false end
    path = tostring(path):lower():gsub('/+$', '')
    local expected = GetWebhookPath():gsub('^/+', '')
    local resName = (GetCurrentResourceName and GetCurrentResourceName() or 'xn_case'):lower()

    return path == '/' .. expected
        or path == expected
        or path == '/webhook'
        or path == '/' .. resName .. '/' .. expected
        or path == resName .. '/' .. expected
end

pcall(function()
    SetHttpHandler(function(req, res)
        local path = req.path or ''

        if not IsWebhookPath(path) then
            res.writeHead(404, { ['Content-Type'] = 'application/json' })
            res.send(json.encode({ error = 'Not Found' }))
            return
        end

        if req.method ~= 'POST' then
            res.writeHead(405, { ['Content-Type'] = 'application/json' })
            res.send(json.encode({ error = 'Method Not Allowed' }))
            return
        end

        req.setDataHandler(function(body)
            local ok, parsed = pcall(json.decode, body)
            if not ok or type(parsed) ~= 'table' then
                res.writeHead(400, { ['Content-Type'] = 'application/json' })
                res.send(json.encode({ error = 'Invalid JSON' }))
                return
            end

            if parsed.secretKey ~= nil and parsed.secretKey ~= '' then
                if tostring(parsed.secretKey) ~= tostring(Config.SePay.webhookSecret) then
                    res.writeHead(403, { ['Content-Type'] = 'application/json' })
                    res.send(json.encode({ error = 'Invalid Secret Key' }))
                    return
                end
            end

            if not parsed.content and (not parsed.code or parsed.code == '') then
                res.writeHead(400, { ['Content-Type'] = 'application/json' })
                res.send(json.encode({ error = 'Bad Request' }))
                return
            end

            res.writeHead(200, { ['Content-Type'] = 'application/json' })
            res.send(json.encode({ success = true }))

            CreateThread(function()
                pcall(HandleWebhook, parsed)
            end)
        end)
    end)
end)

if CanUseSePayApi() then
    CreateThread(function()
        Wait(10000)
        while true do
            PollAllPendingTransactions()
            Wait((tonumber(Config.SePay.apiPollIntervalSeconds) or 15) * 1000)
        end
    end)
end

RegisterCommand('sepay_poll', function(source)
    if source ~= 0 then return end
    PollAllPendingTransactions()
end, true)

RegisterCommand('sepay_test', function(source, args)
    if source ~= 0 then return end
    local code = args[1]
    local amount = tonumber(args[2]) or 10000
    if not code then return end
    HandleWebhook({
        id = 99999,
        transferType = 'in',
        transferAmount = amount,
        code = code,
        content = 'SEVQR+' .. code,
    })
end, true)

RegisterCommand('sepay_complete', function(source, args)
    if source ~= 0 then return end
    local code = args[1]
    if not code then return end

    local ok, rows = pcall(function()
        return MySQL.query.await(
            'SELECT transaction_code, amount, status FROM `sepay_transactions` WHERE transaction_code = ? LIMIT 1',
            { code }
        )
    end)

    if not ok or not rows or not rows[1] or rows[1].status ~= 'pending' then
        return
    end

    local tx = rows[1]
    HandleWebhook({
        id = 88888,
        transferType = 'in',
        transferAmount = tx.amount,
        code = tx.transaction_code,
        content = 'SEVQR+' .. tx.transaction_code,
    })
end, true)
