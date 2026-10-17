local config = require 'config.server'

local function removeHungerAndThirst(src, player)
    if not QBX.Players[src] or not player or not player.PlayerData then return end
    local playerState = Player(src)?.state
    if not playerState or not playerState.isLoggedIn then return end
    local newHunger = (playerState.hunger or 100) - config.player.hungerRate
    local newThirst = (playerState.thirst or 100) - config.player.thirstRate
    local newSleepiness = (playerState.sleepiness or 100) - config.player.sleepinessRate

    player.Functions.SetMetaData('thirst', math.max(0, newThirst))
    player.Functions.SetMetaData('hunger', math.max(0, newHunger))
    player.Functions.SetMetaData('sleepiness', math.max(0, newSleepiness))
    
    player.Functions.Save()
end

-- local function removeSleepiness(src, player)
--     local playerState = Player(src).state
--     if not playerState.isLoggedIn then return end
    
--     local baseRate = config.player.sleepinessRate or 3.8
--     local currentSleepiness = playerState.sleepiness or 100
    
--     -- Tính toán rate theo thời gian
--     local hour = GlobalState.currentHour or tonumber(os.date('%H'))
--     local timeMultiplier = 1.0
--     if hour >= 22 or hour <= 6 then
--         timeMultiplier = 3.0 -- Ban đêm mệt nhanh hơn
--     elseif hour >= 18 then
--         timeMultiplier = 3.8 -- Buổi tối
--     end
    
--     local newSleepiness = currentSleepiness - (baseRate * timeMultiplier)
--     player.Functions.SetMetaData('sleepiness', math.max(0, newSleepiness))
--     player.Functions.Save()
-- end

CreateThread(function()
    local interval = 60000 * config.updateInterval
    while true do
        Wait(interval)
        for src, player in pairs(QBX.Players) do
            if QBX.Players[src] then
                removeHungerAndThirst(src, player)
                Wait(50)
            end
        end
    end
end)

local function processPaychecks()
    local eligible = {}
    local totalPayment = 0

    -- Bước 1: Quét nhanh in-memory để lọc danh sách người chơi đủ điều kiện nhận lương
    for src, player in pairs(QBX.Players) do
        if player and player.PlayerData then
            local job = player.PlayerData.job
            if job and job.name then
                local jobConfig = GetJob(job.name)
                if jobConfig then
                    local gradeLevel = (type(job.grade) == 'table' and job.grade.level) or tonumber(job.grade) or 0
                    local payment = (jobConfig.grades and jobConfig.grades[gradeLevel] and jobConfig.grades[gradeLevel].payment) or job.payment or 0
                    local isOffDutyPay = jobConfig.offDutyPay or false
                    local isOnDuty = (job.onduty == true or job.onduty == 1)
                    if payment > 0 and (isOffDutyPay or isOnDuty) then
                        eligible[#eligible + 1] = {
                            source = src,
                            player = player,
                            payment = payment,
                        }
                        totalPayment += payment
                    end
                end
            end
        end
    end

    if #eligible == 0 or totalPayment <= 0 then return end

    -- Bước 2: Kiểm tra và trừ 1 LẦN DUY NHẤT từ tài khoản 'bcso'
    if config.money.paycheckSociety then
        local accountName = config.money.paycheckAccount or 'bcso'
        local currentBalance = config.getSocietyAccount(accountName)
        if not currentBalance or currentBalance < totalPayment then
            print(('[QBX Paycheck] Ngân sách %s không đủ tiền! Cần: $%s, Số dư: $%s'):format(accountName, totalPayment, tostring(currentBalance)))
            for i = 1, #eligible do
                local item = eligible[i]
                if QBX.Players[item.source] then
                    Notify(item.source, locale('error.company_too_poor'), 'error')
                end
            end
            return
        end

        local reason = ('Chi trả lương duty định kỳ cho %d nhân viên'):format(#eligible)
        local removed = config.removeSocietyMoney(accountName, totalPayment, reason, 'Tòa Thị Chính')
        if not removed then
            print(('[QBX Paycheck] Trừ tiền ngân sách %s thất bại!'):format(accountName))
            for i = 1, #eligible do
                local item = eligible[i]
                if QBX.Players[item.source] then
                    Notify(item.source, locale('error.company_too_poor'), 'error')
                end
            end
            return
        end
        print(('[QBX Paycheck] Đã trừ $%s từ tài khoản %s để chi trả lương cho %d nhân viên'):format(totalPayment, accountName, #eligible))
    end

    -- Bước 3: Phát tiền cho từng người chơi với Wait(50) phân tán tải mạng
    for i = 1, #eligible do
        local item = eligible[i]
        if QBX.Players[item.source] then
            config.sendPaycheck(item.player, item.payment)
            Wait(50)
        end
    end
end

exports('ProcessPaychecks', processPaychecks)

RegisterCommand('testpaycheck', function(source)
    if source == 0 or IsPlayerAceAllowed(tostring(source), 'admin') or IsPlayerAceAllowed(tostring(source), 'god') then
        print('[QBX Paycheck] Đang chạy kiểm tra chi trả lương duty...')
        processPaychecks()
    end
end, true)

CreateThread(function()
    local interval = 60000 * config.money.paycheckTimeout
    while true do
        Wait(interval)
        processPaychecks()
    end
end)
