local QBCore = exports['qb-core']:GetCoreObject()

local function NormalizeSeconds(val, defaultVal)
    if not val then return defaultVal end
    val = tonumber(val) or defaultVal
    if val > 86400 then
        return math.floor(val / 1000)
    end
    return val
end

local basicBeklemeCd = NormalizeSeconds(Config.BasicCooldown, 1800)
local hardBeklemeCd = NormalizeSeconds(Config.HardCooldown, 1800)
local ox = exports.ox_inventory

local globalCooldownUntil = 0
local lastRobbedShop = nil

local shops = {
    [1] = {
		["son_basic_cd"] = 10000,
        ["son_advanced_cd"] = 10000,
    },
    [2] = {
		["son_basic_cd"] = 20000,
        ["son_advanced_cd"] = 20000,
    },
    [3] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [4] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [5] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [6] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [7] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [8] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [9] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [10] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [11] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [12] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
	[13] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
	[14] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [15] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
	[16] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
    [17] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
	[18] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
	[19] = {
		["son_basic_cd"] = 0,
        ["son_advanced_cd"] = 0,
    },
}

lib.callback.register('xx_shoprobbery:serversidecooldown', function(source, marketNo, tip)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    marketNo = tonumber(marketNo) or 1
    if not shops[marketNo] then marketNo = 1 end

    local currentTime = os.time()

    -- 1. Kiểm tra Cooldown toàn cục: Sau khi một tiệm bị cướp xong, tất cả tiệm khác phải chờ 30 giây
    if globalCooldownUntil and currentTime < globalCooldownUntil then
        if lastRobbedShop and marketNo ~= lastRobbedShop then
            local remaining = globalCooldownUntil - currentTime
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Hồi chiêu cướp',
                description = string.format('Vừa có một tiệm tạp hóa bị cướp xong! Vui lòng đợi %d giây nữa mới có thể cướp tiếp.', remaining),
                type = 'error',
                duration = 4000,
            })
            return false
        end
    end

    if tip == "basic" and (currentTime - (shops[marketNo]["son_basic_cd"] or 0)) > basicBeklemeCd then
        return true
    elseif tip == "hard" and (currentTime - (shops[marketNo]["son_advanced_cd"] or 0)) > hardBeklemeCd then
        return true
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Nơi này đã bị cướp..',
            type = 'error',
            duration = 3000,
        })
        return false
    end   
end)
-- Cooldown toàn cục giữa các vụ cướp tạp hóa
RegisterServerEvent('xx_shoprobbery:Server:BeginCooldown')
AddEventHandler('xx_shoprobbery:Server:BeginCooldown', function(targetShopId)
    local shopId = tonumber(targetShopId) or lastRobbedShop or 1
    lastRobbedShop = shopId
    local globalRobberyCd = tonumber(Config.GlobalRobberyCooldown) or 30
    globalCooldownUntil = os.time() + globalRobberyCd
end)

lib.callback.register('xx_shoprobbery:Cooldown', function(source, targetShopId)
    local currentTime = os.time()
    if globalCooldownUntil and currentTime < globalCooldownUntil then
        targetShopId = tonumber(targetShopId)
        -- Nếu là tiệm khác với tiệm vừa bị cướp
        if not targetShopId or (lastRobbedShop and targetShopId ~= lastRobbedShop) then
            return true, (globalCooldownUntil - currentTime)
        end
    end
    return false, 0
end)


local function GiveRobberyRewards(src, rewardType)
    local rewardList = Config.Rewards and Config.Rewards[rewardType]
    if not rewardList then return false end

    local receivedText = {}
    for _, reward in ipairs(rewardList) do
        local itemName = reward.item or reward.name
        if itemName then
            local chance = tonumber(reward.chance) or 100
            local roll = math.random(1, 100)
            if roll <= chance then
                local min = tonumber(reward.min) or tonumber(reward.count) or 1
                local max = tonumber(reward.max) or tonumber(reward.count) or min
                if min > max then min, max = max, min end
                local amount = (max > min) and math.random(min, max) or min

                if amount > 0 then
                    ox:AddItem(src, itemName, amount)
                    local label = reward.label or itemName
                    table.insert(receivedText, string.format("%sx %s", amount, label))
                end
            end
        end
    end

    if #receivedText > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Thành công',
            description = 'Bạn tìm thấy: ' .. table.concat(receivedText, ', '),
            type = 'success',
            duration = 5000,
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Thông báo',
            description = 'Không tìm thấy vật phẩm nào giá trị!',
            type = 'inform',
            duration = 4000,
        })
    end

    return true
end

RegisterServerEvent("xx_shoprobbery:givereward")
AddEventHandler("xx_shoprobbery:givereward", function(tip, kasaNo)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if not xPlayer then return end

    kasaNo = tonumber(kasaNo) or 1
    if not shops[kasaNo] then kasaNo = 1 end

    local currentTime = os.time()

    -- Bảo vệ: nếu tiệm khác đang trong thời gian cooldown toàn cục thì từ chối
    if globalCooldownUntil and currentTime < globalCooldownUntil then
        if lastRobbedShop and kasaNo ~= lastRobbedShop then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lỗi',
                description = 'Nơi này chưa thể cướp lúc này!',
                type = 'error',
                duration = 3000,
            })
            return
        end
    end

    local globalRobberyCd = tonumber(Config.GlobalRobberyCooldown) or 30

    if tip == "basic" and (currentTime - (shops[kasaNo]["son_basic_cd"] or 0)) > basicBeklemeCd then
        GiveRobberyRewards(src, "basic")
        shops[kasaNo]["son_basic_cd"] = currentTime
        -- Cướp két tiền xong: Tất cả các tạp hóa khác phải đợi 30 giây mới được cướp tiếp
        globalCooldownUntil = currentTime + globalRobberyCd
        lastRobbedShop = kasaNo
    elseif tip == "hard" and (currentTime - (shops[kasaNo]["son_advanced_cd"] or 0)) > hardBeklemeCd then
        GiveRobberyRewards(src, "hard")
        shops[kasaNo]["son_advanced_cd"] = currentTime
        shops[kasaNo]["son_basic_cd"] = currentTime
        -- Cướp két sắt xong: Tất cả các tạp hóa khác phải đợi 30 giây mới được cướp tiếp
        globalCooldownUntil = currentTime + globalRobberyCd
        lastRobbedShop = kasaNo
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Lỗi',
            description = 'Nơi này đã bị cướp hoặc chưa đủ thời gian hồi chiêu...',
            type = 'error',
            duration = 3000,
        })
    end
end)

RegisterServerEvent("xx_storerobbery:failed")
AddEventHandler("xx_storerobbery:failed",function()
    local src = source
    local cardItem = Config.CardItem or 'blue_card'
    ox:RemoveItem(src, cardItem, 1)
end)

RegisterServerEvent("xx_storerobbery:server:removeLockpick")
AddEventHandler("xx_storerobbery:server:removeLockpick", function()
    local src = source
    local lockpickItem = Config.LockpickItem or 'advalockpicknced'
    local breakChance = tonumber(Config.LockpickBreakChance) or 70
    local roll = math.random(1, 100)

    if roll <= breakChance then
        local removed = false
        if ox and ox.RemoveItem then
            removed = ox:RemoveItem(src, lockpickItem, 1)
        end
        if not removed and QBCore and QBCore.Functions then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player and Player.Functions and Player.Functions.RemoveItem then
                removed = Player.Functions.RemoveItem(lockpickItem, 1)
            end
        end

        local label = Config.LockpickLabel or "Bộ bẻ khóa"
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bẻ khóa',
            description = string.format("%s của bạn đã bị gãy!", label),
            type = 'error',
            duration = 4000
        })
    else
        local label = Config.LockpickLabel or "Bộ bẻ khóa"
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bẻ khóa',
            description = string.format("May mắn! %s không bị hỏng.", label),
            type = 'inform',
            duration = 4000
        })
    end
end)

-- Helper sinh 10 chữ số ngẫu nhiên
local function generate10DigitNumber()
    local str = ""
    for i = 1, 10 do
        str = str .. tostring(math.random(0, 9))
    end
    return str
end

-- Lệnh /addcard để cấp thẻ với metadata hidenumber
local function AddCardToPlayer(targetId)
    local cardItem = Config.CardItem or 'blue_card'
    local hidenumber = generate10DigitNumber()
    local metadata = {
        hidenumber = hidenumber,
        description = "Mã ẩn: " .. hidenumber
    }
    ox:AddItem(targetId, cardItem, 1, metadata)
    return hidenumber
end

RegisterCommand('addcard', function(source, args)
    local src = source
    if src > 0 then
        local isAdmin = false
        if QBCore and QBCore.Functions and QBCore.Functions.HasPermission then
            isAdmin = QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
        else
            isAdmin = IsPlayerAceAllowed(src, 'command.addcard')
        end

        if not isAdmin then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lỗi',
                description = 'Bạn không có quyền sử dụng lệnh này!',
                type = 'error',
                duration = 5000
            })
            return
        end
    end

    local targetId = tonumber(args[1]) or src
    local hidenumber = AddCardToPlayer(targetId)
    local cardName = Config.CardLabel or Config.CardItem or 'thẻ'
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Thành công',
        description = string.format('Đã nhận %s với Mã Ẩn (hidenumber): %s', cardName, hidenumber),
        type = 'success',
        duration = 5000
    })
end, false)

if QBCore and QBCore.Commands then
    local cardName = Config.CardLabel or Config.CardItem or 'thẻ'
    QBCore.Commands.Add('addcard', 'Nhận ' .. cardName .. ' có metadata hidenumber', {{name = 'id', help = 'Player ID (để trống là bản thân)'}}, false, function(source, args)
        local targetId = tonumber(args[1]) or source
        local hidenumber = AddCardToPlayer(targetId)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Thành công',
            description = string.format('Đã nhận %s với Mã Ẩn: %s', cardName, hidenumber),
            type = 'success',
            duration = 5000
        })
    end, 'admin')
end

-- Server Co-op Hack Sessions Manager
local hackSessions = {}
local shopCooldowns = {}

local function RemoveBlueCardWithHideNumber(targetId, hidenumber)
    if not targetId then return false end
    local cardItem = Config.CardItem or 'blue_card'
    local items = ox:GetInventoryItems(targetId)
    if items then
        for _, item in pairs(items) do
            if item and (item.name == cardItem or item.name == 'blue_card' or item.name == 'card_blue') then
                if item.metadata and item.metadata.hidenumber and tostring(item.metadata.hidenumber) == tostring(hidenumber) then
                    ox:RemoveItem(targetId, item.name, 1, nil, item.slot)
                    return true
                end
            end
        end
    end
    if ox:Search(targetId, 'count', cardItem) > 0 then
        ox:RemoveItem(targetId, cardItem, 1)
        return true
    elseif cardItem ~= 'blue_card' and ox:Search(targetId, 'count', 'blue_card') > 0 then
        ox:RemoveItem(targetId, 'blue_card', 1)
        return true
    elseif cardItem ~= 'card_blue' and ox:Search(targetId, 'count', 'card_blue') > 0 then
        ox:RemoveItem(targetId, 'card_blue', 1)
        return true
    end
    return false
end

local function generate6DigitPassFrom10(hidenumber)
    if not hidenumber or #hidenumber < 10 then
        hidenumber = generate10DigitNumber()
    end
    local indices = {}
    while #indices < 6 do
        local r = math.random(1, 10)
        local exists = false
        for _, v in ipairs(indices) do
            if v == r then exists = true break end
        end
        if not exists then table.insert(indices, r) end
    end
    table.sort(indices)
    local pass = ""
    for _, idx in ipairs(indices) do
        pass = pass .. string.sub(hidenumber, idx, idx)
    end
    return pass
end

RegisterServerEvent('xx_storerobbery:server:joinSession')
AddEventHandler('xx_storerobbery:server:joinSession', function(shopId, role, cardHideNumber)
    local src = source

    shopId = tonumber(shopId) or 1
    if not shops[shopId] then shopId = 1 end

    local currentTime = os.time()

    -- 0. Kiểm tra Cooldown toàn cục giữa các tiệm tạp hóa (30s sau khi cướp xong tiệm khác)
    if globalCooldownUntil and currentTime < globalCooldownUntil then
        if lastRobbedShop and shopId ~= lastRobbedShop then
            local remaining = globalCooldownUntil - currentTime
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Hồi chiêu cướp',
                description = string.format('Vừa có một tiệm tạp hóa bị cướp xong! Vui lòng đợi %d giây nữa mới có thể cướp tiếp.', remaining),
                type = 'error',
                duration = 5000
            })
            return
        end
    end

    -- 1. Kiểm tra két sắt có đang trong thời gian hồi (cooldown) sau khi cướp không
    local lastAdvancedTime = shops[shopId]["son_advanced_cd"] or 0
    if lastAdvancedTime > 0 and (currentTime - lastAdvancedTime) <= hardBeklemeCd then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Truy cập thất bại',
            description = 'Két sắt ở cửa hàng này vừa bị cướp gần đây, vui lòng quay lại sau!',
            type = 'error',
            duration = 5000
        })
        return
    end

    -- 2. Kiểm tra điều kiện bắt buộc: Bắt buộc mở xong két tiền ngoài (basic_kasa) mới cho mở két sắt trong
    local lastBasicTime = shops[shopId]["son_basic_cd"] or 0
    local isBasicRobbed = (lastBasicTime > 0) and ((currentTime - lastBasicTime) <= basicBeklemeCd) and (lastAdvancedTime <= lastBasicTime)
    if not isBasicRobbed then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Truy cập bị từ chối',
            description = 'Bạn phải cướp/mở két máy tính tiền (két ngoài) trước mới có thể mở két sắt này!',
            type = 'error',
            duration = 5000
        })
        return
    end

    if shopCooldowns[shopId] and os.time() < shopCooldowns[shopId] then
        local remaining = shopCooldowns[shopId] - os.time()
        local mins = math.floor(remaining / 60)
        local secs = remaining % 60
        local timeStr = (mins > 0) and string.format("%d phút %d giây", mins, secs) or string.format("%d giây", secs)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Hệ thống bị khóa',
            description = string.format('Hệ thống an ninh đang bị khóa! Vui lòng chờ %s để thử lại.', timeStr),
            type = 'error',
            duration = 5000
        })
        return
    end

    if not hackSessions[shopId] then
        hackSessions[shopId] = {
            pcPlayer = nil,
            safePlayer = nil,
            hidenumber = nil,
            pass6 = nil,
            attempts = {},
            safeAttempts = 0
        }
    end

    local session = hackSessions[shopId]

    if role == 'safe' then
        -- Kiểm tra nếu đã có người khác đang thao tác tại Két sắt này
        if session.safePlayer and session.safePlayer ~= src then
            if GetPlayerPing(session.safePlayer) > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Két sắt đang bận',
                    description = 'Đang có người khác thao tác tại Két sắt này!',
                    type = 'error',
                    duration = 4000
                })
                return
            else
                session.safePlayer = nil
            end
        end

        -- Xóa thẻ ngay khi quẹt thẻ hiện UI
        if session.safePlayer ~= src then
            if not RemoveBlueCardWithHideNumber(src, cardHideNumber) then
                local cardName = Config.CardLabel or Config.CardItem or 'thẻ'
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Truy cập thất bại',
                    description = string.format('Bạn không có %s hợp lệ trong túi đồ!', cardName),
                    type = 'error',
                    duration = 4000
                })
                return
            end
        end

        session.safePlayer = src
        if cardHideNumber then
            session.hidenumber = cardHideNumber
        end
        if not session.pass6 and session.hidenumber then
            session.pass6 = generate6DigitPassFrom10(session.hidenumber)
            session.attempts = {}
            session.safeAttempts = 0
        end

        local debugPass = Config.ShowCorrectPass and session.pass6 or nil

        -- Mở UI ngay lập tức cho người chơi ở Két sắt để xem dãy 10 chữ số
        TriggerClientEvent('xx_storerobbery:client:startHackingUI', src, 'safe', session.hidenumber, session.attempts, debugPass, session.safeAttempts or 0)

        -- Thông báo kích hoạt cho PC nếu đã có người chơi ở PC chờ
        if session.pcPlayer then
            TriggerClientEvent('xx_storerobbery:client:startHackingUI', session.pcPlayer, 'pc', session.hidenumber, session.attempts, debugPass, session.safeAttempts or 0)
        end
    elseif role == 'pc' then
        -- CHỈ CHO PHÉP MỞ UI MÁY TÍNH KHI NGƯỜI CHƠI Ở KÉT SẮT ĐÃ QUẸT THẺ VÀ MỞ UI
        if not session.safePlayer or not session.hidenumber then
            local cardName = Config.CardLabel or Config.CardItem or 'thẻ'
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Truy cập bị từ chối',
                description = string.format('Cần đồng đội quẹt %s hiển thị mã tại Két Sắt trước!', cardName),
                type = 'error',
                duration = 4000
            })
            return
        end

        -- Kiểm tra nếu đã có đồng đội khác đang thao tác trên Máy tính này
        if session.pcPlayer and session.pcPlayer ~= src then
            if GetPlayerPing(session.pcPlayer) > 0 then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Máy tính đang bận',
                    description = 'Đang có đồng đội khác thao tác trên Máy tính này!',
                    type = 'error',
                    duration = 4000
                })
                return
            else
                session.pcPlayer = nil
            end
        end

        session.pcPlayer = src
        local debugPass = Config.ShowCorrectPass and session.pass6 or nil
        -- Mở UI nhập 6 chữ số cho người chơi ở Máy tính
        TriggerClientEvent('xx_storerobbery:client:startHackingUI', src, 'pc', session.hidenumber, session.attempts, debugPass, session.safeAttempts or 0)
    end
end)



RegisterServerEvent('xx_storerobbery:server:submitGuess')
AddEventHandler('xx_storerobbery:server:submitGuess', function(shopId, guess)
    local src = source
    local session = hackSessions[shopId]
    if not session or not session.pass6 then return end

    -- Anti-spam server side (chờ 4.5s giữa các lần thử)
    if session.lastGuessTime and (GetGameTimer() - session.lastGuessTime < 4500) then
        return
    end
    session.lastGuessTime = GetGameTimer()

    local pass6 = session.pass6
    local results = {}
    local correctCount = 0

    for i = 1, 6 do
        local gChar = string.sub(guess, i, i)
        local pChar = string.sub(pass6, i, i)
        if gChar == pChar then
            results[i] = 'correct'
            correctCount = correctCount + 1
        else
            results[i] = 'wrong'
        end
    end

    local attemptData = {
        guess = guess,
        results = results
    }
    table.insert(session.attempts, attemptData)

    -- Đồng bộ lịch sử thử nghiệm cho cả 2 người chơi
    if session.pcPlayer then
        TriggerClientEvent('xx_storerobbery:client:updateAttempts', session.pcPlayer, session.attempts)
    end
    if session.safePlayer then
        TriggerClientEvent('xx_storerobbery:client:updateAttempts', session.safePlayer, session.attempts)
    end

    -- Nếu đoán đúng cả 6 vị trí
    if correctCount == 6 then
        if session.pcPlayer then
            TriggerClientEvent('ox_lib:notify', session.pcPlayer, {
                title = 'TÌM THẤY MẬT KHẨU!',
                description = 'Tất cả 6 chữ số đều chính xác! Báo 6 chữ số này cho đồng đội ở Két sắt để mở khóa.',
                type = 'success',
                duration = 6000
            })
        end
        if session.safePlayer then
            TriggerClientEvent('ox_lib:notify', session.safePlayer, {
                title = 'ĐỒNG ĐỘI ĐÃ DÒ RA PASS!',
                description = 'Đồng đội ở PC đã tìm thấy chuỗi 6 chữ số chính xác! Hãy nhập mã vào ô bên dưới để Mở Két.',
                type = 'success',
                duration = 6000
            })
        end
    else
        -- Đoán sai trên PC, kiểm tra nếu số lần thử check pass vượt giới hạn
        local maxAttempts = Config.MaxPassAttempts or 8
        local lockoutDuration = Config.LockoutDuration or 180
        if #session.attempts >= maxAttempts then
            shopCooldowns[shopId] = os.time() + lockoutDuration

            local mins = math.floor(lockoutDuration / 60)
            local secs = lockoutDuration % 60
            local timeStr = (mins > 0) and string.format("%d phút %d giây", mins, secs) or string.format("%d giây", secs)

            local lockMsg = string.format('Đã thử check pass sai quá %d/%d lần! Hệ thống an ninh đã bị khóa trong %s.', maxAttempts, maxAttempts, timeStr)
            if session.pcPlayer then
                TriggerClientEvent('ox_lib:notify', session.pcPlayer, {
                    title = 'HỆ THỐNG BỊ KHÓA!',
                    description = lockMsg,
                    type = 'error',
                    duration = 6000
                })
                TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.pcPlayer)
            end
            if session.safePlayer then
                TriggerClientEvent('ox_lib:notify', session.safePlayer, {
                    title = 'HỆ THỐNG BỊ KHÓA!',
                    description = lockMsg,
                    type = 'error',
                    duration = 6000
                })
                TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.safePlayer)
            end
            hackSessions[shopId] = nil
        end
    end
end)

RegisterServerEvent('xx_storerobbery:server:submitFinalUnlock')
AddEventHandler('xx_storerobbery:server:submitFinalUnlock', function(shopId, pass)
    local src = source
    local session = hackSessions[shopId]
    if not session or not session.pass6 then return end

    if pass == session.pass6 then
        if session.pcPlayer then
            TriggerClientEvent('ox_lib:notify', session.pcPlayer, {
                title = 'THÀNH CÔNG!',
                description = 'Đồng đội đã nhập mật khẩu giải mã thành công! Két đã mở.',
                type = 'success',
                duration = 5000
            })
            TriggerClientEvent('xx_storerobbery:client:hackSuccess', session.pcPlayer)
        end
        if session.safePlayer then
            TriggerClientEvent('ox_lib:notify', session.safePlayer, {
                title = 'THÀNH CÔNG!',
                description = 'Mật khẩu chính xác! Két sắt đã được mở khóa.',
                type = 'success',
                duration = 5000
            })
            TriggerClientEvent('xx_storerobbery:client:hackSuccess', session.safePlayer)
        end
        hackSessions[shopId] = nil
    else
        session.safeAttempts = (session.safeAttempts or 0) + 1
        local maxSafeAttempts = Config.MaxSafePassAttempts or 3
        local lockoutDuration = Config.LockoutDuration or 180

        if session.safePlayer then
            TriggerClientEvent('xx_storerobbery:client:updateSafeAttempts', session.safePlayer, session.safeAttempts)
        end

        if session.safeAttempts >= maxSafeAttempts then
            shopCooldowns[shopId] = os.time() + lockoutDuration

            local mins = math.floor(lockoutDuration / 60)
            local secs = lockoutDuration % 60
            local timeStr = (mins > 0) and string.format("%d phút %d giây", mins, secs) or string.format("%d giây", secs)

            local lockMsg = string.format('Bạn đã nhập sai mật khẩu Két sắt %d/%d lần! Hệ thống an ninh đã bị khóa trong %s.', session.safeAttempts, maxSafeAttempts, timeStr)
            if session.pcPlayer then
                TriggerClientEvent('ox_lib:notify', session.pcPlayer, {
                    title = 'HỆ THỐNG BỊ KHÓA!',
                    description = lockMsg,
                    type = 'error',
                    duration = 6000
                })
                TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.pcPlayer)
            end
            if session.safePlayer then
                TriggerClientEvent('ox_lib:notify', session.safePlayer, {
                    title = 'HỆ THỐNG BỊ KHÓA!',
                    description = lockMsg,
                    type = 'error',
                    duration = 6000
                })
                TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.safePlayer)
            end
            hackSessions[shopId] = nil
        else
            local remaining = maxSafeAttempts - session.safeAttempts
            local mins = math.floor(lockoutDuration / 60)
            local secs = lockoutDuration % 60
            local timeStr = (mins > 0) and string.format("%d phút %d giây", mins, secs) or string.format("%d giây", secs)

            TriggerClientEvent('ox_lib:notify', src, {
                title = 'MẬT KHẨU SAI',
                description = string.format('Mật khẩu Két sắt không chính xác! (Đã thử %d/%d lần). Nhập sai %d lần nữa hệ thống sẽ bị khóa %s!', session.safeAttempts, maxSafeAttempts, remaining, timeStr),
                type = 'error',
                duration = 5000
            })
        end
    end
end)

RegisterServerEvent('xx_storerobbery:server:closeSession')

AddEventHandler('xx_storerobbery:server:closeSession', function(shopId)
    local src = source
    local session = hackSessions[shopId]
    if session then
        -- Đồng bộ đóng UI cho cả 2 người chơi khi 1 trong 2 người thoát
        if session.pcPlayer then
            TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.pcPlayer)
        end
        if session.safePlayer then
            TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.safePlayer)
        end
        hackSessions[shopId] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for shopId, session in pairs(hackSessions) do
        if session.pcPlayer == src or session.safePlayer == src then
            if session.pcPlayer and session.pcPlayer ~= src then
                TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.pcPlayer)
            end
            if session.safePlayer and session.safePlayer ~= src then
                TriggerClientEvent('xx_storerobbery:client:closeHackingUI', session.safePlayer)
            end
            hackSessions[shopId] = nil
        end
    end
end)
