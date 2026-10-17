local QBX = exports.qbx_core
local isProcessingBid = false

-- Auction State
local Auction = {
    state = 'IDLE', -- 'IDLE', 'RUNNING', 'ENDED'
    title = 'Gói Đấu Giá',
    startingPrice = 0,
    currentPrice = 0,
    highestBidder = nil, -- { source = int, citizenid = str, name = str, id = int, bidAmount = num, paidAmount = num, time = int }
    countdown = 0,
    lastBidTime = 0,
    bidHistory = {},
    timerThreadActive = false
}

-- Helper: Format tiền tệ (vd: 1,000,000)
local function FormatMoney(amount)
    local formatted = tostring(math.floor(amount or 0))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Helper: Lấy thông tin player (Tên, CitizenID)
local function GetPlayerInfo(src)
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        local charinfo = player.PlayerData.charinfo or {}
        local firstname = charinfo.firstname or "Vô"
        local lastname = charinfo.lastname or "Danh"
        local fullname = firstname .. " " .. lastname
        return {
            source = src,
            id = src,
            citizenid = player.PlayerData.citizenid,
            name = fullname,
            player = player
        }
    end

    -- Fallback QBCore nếu có
    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local qbPlayer = QBCore.Functions.GetPlayer(src)
        if qbPlayer then
            local charinfo = qbPlayer.PlayerData.charinfo or {}
            local fullname = (charinfo.firstname or "Vô") .. " " .. (charinfo.lastname or "Danh")
            return {
                source = src,
                id = src,
                citizenid = qbPlayer.PlayerData.citizenid,
                name = fullname,
                player = qbPlayer
            }
        end
    end

    return {
        source = src,
        id = src,
        citizenid = tostring(src),
        name = GetPlayerName(src) or ("Player #" .. src),
        player = nil
    }
end

-- Helper: Kiểm tra số dư tiền
local function GetPlayerMoney(src, moneyType)
    moneyType = moneyType or Config.MoneyType
    local pInfo = GetPlayerInfo(src)
    local player = pInfo.player

    if player then
        if player.PlayerData and player.PlayerData.money and player.PlayerData.money[moneyType] ~= nil then
            return player.PlayerData.money[moneyType]
        end
        if player.Functions and player.Functions.GetMoney then
            return player.Functions.GetMoney(moneyType) or 0
        end
    end

    -- Kiểm tra ox_inventory nếu là cash/money
    if GetResourceState('ox_inventory') == 'started' and moneyType == 'cash' then
        local count = exports.ox_inventory:GetItemCount(src, 'money')
        if count and count > 0 then return count end
    end

    return 0
end

-- Helper: Trừ tiền
local function RemovePlayerMoney(src, amount, reason)
    local moneyType = Config.MoneyType
    local pInfo = GetPlayerInfo(src)
    local player = pInfo.player

    if player and player.Functions and player.Functions.RemoveMoney then
        return player.Functions.RemoveMoney(moneyType, amount, reason or "auction-payment")
    end

    if GetResourceState('ox_inventory') == 'started' and moneyType == 'cash' then
        return exports.ox_inventory:RemoveItem(src, 'money', amount)
    end

    return false
end

-- Helper: Cộng tiền (Hoàn trả)
local function AddPlayerMoney(src, amount, reason)
    local moneyType = Config.MoneyType
    local pInfo = GetPlayerInfo(src)
    local player = pInfo.player

    if player and player.Functions and player.Functions.AddMoney then
        return player.Functions.AddMoney(moneyType, amount, reason or "auction-refund")
    end

    if GetResourceState('ox_inventory') == 'started' and moneyType == 'cash' then
        return exports.ox_inventory:AddItem(src, 'money', amount)
    end

    return false
end

-- Helper: Gửi thông báo tới người chơi
local function SendNotify(src, message, notifyType)
    notifyType = notifyType or 'primary'
    if exports.qbx_core and exports.qbx_core.Notify then
        exports.qbx_core:Notify(src, message, notifyType)
    elseif GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Đấu Giá',
            description = message,
            type = (notifyType == 'primary' and 'info') or notifyType
        })
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 215, 0 },
            multiline = true,
            args = { "[ĐẤU GIÁ]", message }
        })
    end
end

-- Helper: Broadcast thông báo tới tất cả người chơi
local function BroadcastNotify(message, notifyType)
    TriggerClientEvent('xn_daugia:client:broadcastNotify', -1, message, notifyType or 'primary')
end

-- Helper: Gửi Discord Webhook
local function SendDiscordLog(title, description, color)
    if not Config.DiscordWebhook or Config.DiscordWebhook == "" then return end
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16766720, -- Gold
            ["footer"] = {
                ["text"] = "XN Auction System"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Hệ Thống Đấu Giá",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Helper: Kiểm tra quyền Admin
local function HasAdminPermission(src)
    if src == 0 then return true end -- Server Console
    
    -- Check QBX / QBCore Permission
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        for _, group in ipairs(Config.AdminGroups) do
            if exports.qbx_core:HasGroup(src, group) or (player.PlayerData.optin and IsPlayerAceAllowed(src, 'command')) then
                return true
            end
        end
    end

    if IsPlayerAceAllowed(src, 'admin') or IsPlayerAceAllowed(src, 'command') then
        return true
    end

    return false
end

-- Helper: Lấy bảng xếp hạng các người cược cao nhất (Leaderboard)
local function GenerateLeaderboard()
    local userBids = {}
    for _, bid in ipairs(Auction.bidHistory) do
        userBids[bid.citizenid] = {
            id = bid.id,
            name = bid.name,
            citizenid = bid.citizenid,
            finalBid = bid.amount,
            time = bid.time
        }
    end

    local list = {}
    for _, v in pairs(userBids) do
        table.insert(list, v)
    end

    table.sort(list, function(a, b)
        return a.finalBid > b.finalBid
    end)

    return list
end

-- Helper: Lấy dữ liệu Auction State hiện tại để gửi về Client
local function GetAuctionClientData()
    return {
        state = Auction.state,
        title = Auction.title,
        startingPrice = Auction.startingPrice,
        currentPrice = Auction.currentPrice,
        highestBidder = Auction.highestBidder,
        countdown = Auction.countdown,
        bidLockSeconds = Config.BidLockSeconds,
        countdownSeconds = Config.CountdownSeconds,
        betSteps = Config.BetSteps,
        bidHistory = Auction.bidHistory,
        leaderboard = GenerateLeaderboard()
    }
end

-- Đồng bộ State cho toàn bộ Client
local function SyncAuctionState()
    local data = GetAuctionClientData()
    TriggerClientEvent('xn_daugia:client:syncAuctionState', -1, data)
end

-- Vòng lặp đếm ngược độc lập trên Server
local function StartCountdownTimer()
    if Auction.timerThreadActive then return end
    Auction.timerThreadActive = true

    CreateThread(function()
        while Auction.state == 'RUNNING' and Auction.countdown > 0 do
            Wait(1000)
            if Auction.state ~= 'RUNNING' then break end

            Auction.countdown = Auction.countdown - 1
            TriggerClientEvent('xn_daugia:client:syncCountdown', -1, Auction.countdown, Auction.highestBidder and Auction.highestBidder.id or nil)

            if Auction.countdown <= 0 then
                -- HẾT GIỜ (10s) VÀ CÓ NGƯỜI ĐẶT THẦU -> CHỐT NGƯỜI CHIẾN THẮNG
                if Auction.highestBidder ~= nil then
                    Auction.state = 'ENDED'
                    Auction.timerThreadActive = false

                    local winner = Auction.highestBidder
                    local leaderboard = GenerateLeaderboard()

                    if Config.DeductMoney and Config.PaymentMode == 'on_win' then
                        local winnerSrc = winner.source
                        local balance = GetPlayerMoney(winnerSrc, Config.MoneyType)
                        if balance >= winner.bidAmount then
                            RemovePlayerMoney(winnerSrc, winner.bidAmount, "auction-win-payment")
                        else
                            RemovePlayerMoney(winnerSrc, balance, "auction-win-partial")
                        end
                    end

                    local winMsg = string.format(Config.Locale.auction_won_broadcast, winner.name, winner.id, FormatMoney(winner.bidAmount))
                    BroadcastNotify(winMsg, 'success')

                    SendDiscordLog(
                        "🏆 ĐẤU GIÁ KẾT THÚC - CÓ NGƯỜI THẮNG",
                        string.format("**Gói thầu:** %s\n**Người thắng:** %s (ID: %s | CID: %s)\n**Giá chốt:** $%s\n**Tổng lượt cược:** %d",
                            Auction.title, winner.name, winner.id, winner.citizenid, FormatMoney(winner.bidAmount), #Auction.bidHistory
                        ),
                        3066993 -- Green
                    )

                    -- Gửi event kết thúc tới toàn bộ client
                    TriggerClientEvent('xn_daugia:client:auctionEnded', -1, {
                        winner = winner,
                        leaderboard = leaderboard,
                        bidHistory = Auction.bidHistory,
                        finalPrice = Auction.currentPrice,
                        title = Auction.title
                    })
                end
                break
            end
        end
        Auction.timerThreadActive = false
    end)
end

-- ===========================
-- ADMIN COMMANDS
-- ===========================

-- Lệnh bắt đầu phiên đấu giá: /daugia [giá_khởi_điểm] [tên_gói_thầu]
RegisterCommand(Config.AdminCommand, function(source, args, rawCommand)
    if not HasAdminPermission(source) then
        SendNotify(source, Config.Locale.no_permission, 'error')
        return
    end

    if Auction.state == 'RUNNING' then
        SendNotify(source, Config.Locale.auction_already_running, 'error')
        return
    end

    local startPrice = tonumber(args[1])
    if not startPrice or startPrice <= 0 then
        SendNotify(source, Config.Locale.invalid_price, 'error')
        return
    end

    -- Lấy tên gói thầu nếu có
    local title = "Gói Đấu Giá"
    if args[2] then
        table.remove(args, 1)
        title = table.concat(args, " ")
    end

    -- Khởi tạo phiên đấu giá (ở trạng thái chờ lượt đặt thầu đầu tiên)
    Auction.state = 'RUNNING'
    Auction.title = title
    Auction.startingPrice = startPrice
    Auction.currentPrice = startPrice
    Auction.highestBidder = nil
    Auction.countdown = 0 -- Chưa đếm ngược cho đến khi có người mở màn đặt thầu
    Auction.lastBidTime = GetGameTimer()
    Auction.bidHistory = {}
    Auction.timerThreadActive = false

    local startMsg = string.format(Config.Locale.auction_started, FormatMoney(startPrice))
    BroadcastNotify(startMsg, 'primary')

    SendDiscordLog(
        "📢 PHIÊN ĐẤU GIÁ MỚI BẮT ĐẦU",
        string.format("**Gói thầu:** %s\n**Giá khởi điểm:** $%s\n**Người mở:** %s",
            title, FormatMoney(startPrice), source == 0 and "Console" or GetPlayerName(source)
        ),
        16766720
    )

    SyncAuctionState()
end, false)

-- Lệnh huỷ phiên đấu giá: /huydaugia
RegisterCommand(Config.CancelCommand, function(source, args, rawCommand)
    if not HasAdminPermission(source) then
        SendNotify(source, Config.Locale.no_permission, 'error')
        return
    end

    if Auction.state == 'IDLE' then
        SendNotify(source, Config.Locale.no_active_auction, 'error')
        return
    end

    -- Hoàn tiền cho người đang giữ thầu cao nhất nếu ở chế độ on_bid và có trừ tiền
    if Config.DeductMoney and Config.PaymentMode == 'on_bid' and Auction.highestBidder and Auction.highestBidder.paidAmount and Auction.highestBidder.paidAmount > 0 then
        AddPlayerMoney(Auction.highestBidder.source, Auction.highestBidder.paidAmount, "auction-cancelled-refund")
        SendNotify(Auction.highestBidder.source, string.format(Config.Locale.outbid_refund, FormatMoney(Auction.highestBidder.paidAmount)), 'success')
    end

    Auction.state = 'IDLE'
    Auction.highestBidder = nil
    Auction.bidHistory = {}
    Auction.countdown = 0

    BroadcastNotify(Config.Locale.auction_cancelled, 'error')
    TriggerClientEvent('xn_daugia:client:auctionCancelled', -1)
    SyncAuctionState()
end, false)

-- ===========================
-- USABLE ITEM: the_dau_gia
-- ===========================

local function UseAuctionItem(source)
    local src = source
    if Auction.state == 'IDLE' then
        SendNotify(src, Config.Locale.no_active_auction, 'error')
        return
    end

    local data = GetAuctionClientData()
    TriggerClientEvent('xn_daugia:client:openAuctionUI', src, data)
end

-- Đăng ký qua qbx_core
if exports.qbx_core and exports.qbx_core.CreateUseableItem then
    exports.qbx_core:CreateUseableItem(Config.ItemName, function(source)
        UseAuctionItem(source)
    end)
end

-- Đăng ký fallback QBCore
if GetResourceState('qb-core') == 'started' then
    local QBCore = exports['qb-core']:GetCoreObject()
    if QBCore and QBCore.Functions and QBCore.Functions.CreateUseableItem then
        QBCore.Functions.CreateUseableItem(Config.ItemName, function(source)
            UseAuctionItem(source)
        end)
    end
end

-- Event hỗ trợ ox_inventory hoặc client trigger
RegisterNetEvent('xn_daugia:server:useItem', function()
    UseAuctionItem(source)
end)

-- ===========================
-- XỬ LÝ ĐẶT CƯỢC & ATOMIC LOCK
-- ===========================

RegisterNetEvent('xn_daugia:server:placeBid', function(addedAmount, clientExpectedPrice)
    local src = source
    addedAmount = tonumber(addedAmount)

    if not addedAmount or addedAmount <= 0 then return end

    -- 1. Atomic Mutex Lock để tuần tự hoá các request từ nhiều người chơi cùng một lúc
    while isProcessingBid do
        Wait(50)
    end
    isProcessingBid = true

    -- Đảm bảo an toàn: Tự giải phóng lock nếu xảy ra lỗi bất ngờ
    local success, err = pcall(function()
        -- Kiểm tra phiên đấu giá có đang diễn ra không
        if Auction.state ~= 'RUNNING' then
            SendNotify(src, Config.Locale.no_active_auction, 'error')
            return
        end

        -- Không cho phép người đang giữ giá cao nhất tự đặt thêm
        if Auction.highestBidder ~= nil and (Auction.highestBidder.source == src or Auction.highestBidder.id == src) then
            SendNotify(src, "Bạn đang là người giữ mức giá cao nhất, vui lòng đợi người khác nâng giá!", 'error')
            return
        end

        -- Kiểm tra Cooldown 3s:
        -- Người gọi cược tiếp theo chỉ được phép sau 3s (tức là countdown <= Config.CountdownSeconds - Config.BidLockSeconds = 7s)
        -- Trừ trường hợp đây là lượt đầu tiên (chưa có ai bid)
        if Auction.highestBidder ~= nil then
            local maxAllowedCountdown = Config.CountdownSeconds - Config.BidLockSeconds
            if Auction.countdown > maxAllowedCountdown then
                local waitSeconds = Auction.countdown - maxAllowedCountdown
                SendNotify(src, string.format(Config.Locale.bid_lock_cooldown, waitSeconds, maxAllowedCountdown), 'error')
                return
            end
        end

        -- Tính toán mức giá mới
        local newPrice = Auction.currentPrice + addedAmount

        -- Race Condition Arbitration:
        -- Nếu mức giá mới không lớn hơn giá hiện tại (do người khác đã cược trước trong tích tắc)
        if newPrice <= Auction.currentPrice then
            SendNotify(src, Config.Locale.race_condition_rejected, 'error')
            return
        end

        -- Lấy thông tin người đặt thầu
        local pInfo = GetPlayerInfo(src)

        -- Kiểm tra và xử lý tiền nếu bật Config.CheckMoney
        if Config.CheckMoney then
            local requiredMoney = newPrice
            local playerMoney = GetPlayerMoney(src, Config.MoneyType)

            if Config.PaymentMode == 'on_bid' then
                local needed = requiredMoney
                if Auction.highestBidder and Auction.highestBidder.source == src then
                    needed = addedAmount
                end

                if playerMoney < needed then
                    SendNotify(src, string.format(Config.Locale.not_enough_money, FormatMoney(needed)), 'error')
                    return
                end

                if Config.DeductMoney then
                    local removeSuccess = RemovePlayerMoney(src, needed, "auction-place-bid")
                    if not removeSuccess then
                        SendNotify(src, string.format(Config.Locale.not_enough_money, FormatMoney(needed)), 'error')
                        return
                    end

                    if Auction.highestBidder and Auction.highestBidder.source ~= src and Auction.highestBidder.paidAmount and Auction.highestBidder.paidAmount > 0 then
                        local prevBidderSrc = Auction.highestBidder.source
                        local prevPaid = Auction.highestBidder.paidAmount
                        AddPlayerMoney(prevBidderSrc, prevPaid, "auction-outbid-refund")
                        SendNotify(prevBidderSrc, string.format(Config.Locale.outbid_refund, FormatMoney(prevPaid)), 'primary')
                    end
                end
            elseif Config.PaymentMode == 'on_win' then
                if playerMoney < requiredMoney then
                    SendNotify(src, string.format(Config.Locale.not_enough_money, FormatMoney(requiredMoney)), 'error')
                    return
                end
            end
        end

        -- Cập nhật State Đấu Giá
        local prevBidder = Auction.highestBidder
        Auction.currentPrice = newPrice
        Auction.highestBidder = {
            source = src,
            id = src,
            citizenid = pInfo.citizenid,
            name = pInfo.name,
            bidAmount = newPrice,
            paidAmount = (Config.PaymentMode == 'on_bid') and newPrice or 0,
            time = os.time()
        }
        Auction.countdown = Config.CountdownSeconds -- Reset lại 10s
        Auction.lastBidTime = GetGameTimer()

        -- Ghi nhận vào lịch sử
        table.insert(Auction.bidHistory, {
            id = src,
            name = pInfo.name,
            citizenid = pInfo.citizenid,
            amount = newPrice,
            addedAmount = addedAmount,
            time = os.date("%H:%M:%S")
        })

        -- Thông báo cho người đặt thành công
        SendNotify(src, string.format(Config.Locale.bid_placed_success, FormatMoney(newPrice)), 'success')

        -- Broadcast toàn server
        local broadcastMsg = string.format(Config.Locale.outbid_broadcast, pInfo.name, src, FormatMoney(newPrice))
        BroadcastNotify(broadcastMsg, 'primary')

        -- Đồng bộ State & kích hoạt 3D Overhead trên đầu người mới
        SyncAuctionState()
        StartCountdownTimer()
        TriggerClientEvent('xn_daugia:client:bidPlacedOverhead', -1, {
            source = src,
            name = pInfo.name,
            price = newPrice,
            formattedPrice = FormatMoney(newPrice),
            countdown = Config.CountdownSeconds
        })
    end)

    isProcessingBid = false

    if not success then
        print("^1[xn_daugia ERROR] Error processing bid: " .. tostring(err) .. "^7")
    end
end)

-- Callback yêu cầu lấy dữ liệu state mới nhất
RegisterNetEvent('xn_daugia:server:requestState', function()
    local src = source
    local data = GetAuctionClientData()
    TriggerClientEvent('xn_daugia:client:syncAuctionState', src, data)
end)
