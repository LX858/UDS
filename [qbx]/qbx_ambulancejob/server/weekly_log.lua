-- ============================================================
-- Weekly Revive Discord Log & Statistics System
-- ============================================================
local FILE_PATH = 'server/weekly_revives.json'
local DISCORD_WEBHOOK = 'https://discord.com/api/webhooks/1540007233364955207/BTaeO2kc5YbSFLJ8UoBZoLNnzSnqCy82IvfX1s5zitsHTS3iXq8JPr6_AQ1aFLLBMqTu'

local weeklyRevives = {
    last_reset = os.date('%d/%m/%Y %H:%M:%S'),
    reset_timestamp = os.time(),
    next_reset_timestamp = nil,
    players = {}
}
local isDataDirty = false

-- Save data to JSON file
function SaveWeeklyRevivesData(force)
    if not force and not isDataDirty then return end
    local jsonContent = json.encode(weeklyRevives, { indent = true })
    if jsonContent then
        SaveResourceFile(GetCurrentResourceName(), FILE_PATH, jsonContent, -1)
        isDataDirty = false
    end
end

-- Load data from JSON file
function LoadWeeklyRevivesData()
    local content = LoadResourceFile(GetCurrentResourceName(), FILE_PATH)
    if content and content ~= '' then
        local success, decoded = pcall(json.decode, content)
        if success and decoded and type(decoded) == 'table' then
            weeklyRevives = decoded
            if not weeklyRevives.players then weeklyRevives.players = {} end
            return
        end
    end

    weeklyRevives = {
        last_reset = os.date('%d/%m/%Y %H:%M:%S'),
        reset_timestamp = os.time(),
        next_reset_timestamp = nil,
        players = {}
    }
    isDataDirty = true
    SaveWeeklyRevivesData(true)
end

-- Record a revive for doctor
function TrackDoctorRevive(src)
    if not src or src <= 0 then return end
    local player = exports.qbx_core:GetPlayer(src)
    if not player or not player.PlayerData then return end

    local citizenid = player.PlayerData.citizenid
    if not citizenid then return end

    local doctorName = 'N/A'
    if player.PlayerData.charinfo then
        doctorName = (player.PlayerData.charinfo.firstname or '') .. ' ' .. (player.PlayerData.charinfo.lastname or '')
    end

    if not weeklyRevives.players then
        weeklyRevives.players = {}
    end

    if not weeklyRevives.players[citizenid] then
        weeklyRevives.players[citizenid] = {
            name = doctorName,
            citizenid = citizenid,
            count = 0
        }
    end

    weeklyRevives.players[citizenid].name = doctorName
    weeklyRevives.players[citizenid].count = weeklyRevives.players[citizenid].count + 1
    isDataDirty = true
end

-- Send Discord Webhook Summary Report
function SendWeeklyDiscordSummary()
    local list = {}
    if weeklyRevives.players then
        for citizenid, info in pairs(weeklyRevives.players) do
            table.insert(list, {
                name = info.name or 'N/A',
                citizenid = citizenid,
                count = info.count or 0
            })
        end
    end

    table.sort(list, function(a, b)
        return a.count > b.count
    end)

    local descriptionLines = {}
    if #list == 0 then
        table.insert(descriptionLines, '*Trong tuần qua chưa có lượt cứu người nào được ghi nhận.*')
    else
        for i, item in ipairs(list) do
            local medal = ''
            if i == 1 then medal = '🥇 '
            elseif i == 2 then medal = '🥈 '
            elseif i == 3 then medal = '🥉 '
            else medal = '🔹 ' end

            local line = string.format('%s**#%d. %s**\n└ CitizenID: `%s` | Số lần cứu: **%d** lượt', medal, i, item.name, item.citizenid, item.count)
            table.insert(descriptionLines, line)
        end
    end

    local fullDescription = table.concat(descriptionLines, '\n\n')
    if #fullDescription > 4000 then
        fullDescription = string.sub(fullDescription, 1, 3950) .. '\n\n*(Danh sách quá dài, đã tự động rút gọn)*'
    end

    local startDate = weeklyRevives.last_reset or 'N/A'
    local endDate = os.date('%d/%m/%Y %H:%M:%S')

    local payload = json.encode({
        embeds = {
            {
                title = '📊 BÁO CÁO THỐNG KÊ CỨU NGUỜI HÀNG TUẦN (EMS)',
                description = fullDescription,
                color = 3447003,
                fields = {
                    { name = '🗓️ Tuần bắt đầu', value = startDate, inline = true },
                    { name = '🏁 Tuần kết thúc', value = endDate, inline = true },
                },
                footer = { text = 'Hệ thống tự động tổng hợp & Reset lúc 00:00 Chủ Nhật' },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
    })

    PerformHttpRequest(DISCORD_WEBHOOK, function(statusCode, responseText, headers)
        if statusCode == 200 or statusCode == 204 then
            print('^2[qbx_ambulancejob]^0 Đã gửi thành công Discord Log thống kê tuần!')
        else
            print('^1[qbx_ambulancejob]^0 Lỗi khi gửi Discord Log thống kê tuần, status code: ' .. tostring(statusCode))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

-- Reset data for a new week
function ResetWeeklyRevivesData()
    weeklyRevives.last_reset = os.date('%d/%m/%Y %H:%M:%S')
    weeklyRevives.reset_timestamp = os.time()
    weeklyRevives.players = {}
    isDataDirty = true
    SaveWeeklyRevivesData(true)
end

-- Calculate target timestamp for upcoming Sunday 00:00:00
local function getNextSundayTimestamp()
    local now = os.time()
    local date = os.date('*t', now)
    local daysUntilSunday = (8 - date.wday) % 7
    if daysUntilSunday == 0 then
        if date.hour > 0 or date.min > 0 or date.sec > 0 then
            daysUntilSunday = 7
        end
    end

    local targetDate = {
        year = date.year,
        month = date.month,
        day = date.day + daysUntilSunday,
        hour = 0,
        min = 0,
        sec = 0
    }
    return os.time(targetDate)
end

-- SetTimeout scheduler (No loop)
local function scheduleWeeklyReset()
    local now = os.time()

    -- Catch up check if reset timestamp passed during server downtime
    if weeklyRevives.next_reset_timestamp and now >= weeklyRevives.next_reset_timestamp then
        print('^3[qbx_ambulancejob]^0 Phát hiện đã qua mốc 00:00 Chủ Nhật trong thời gian offline. Tiến hành gửi log bù & reset...')
        SendWeeklyDiscordSummary()
        ResetWeeklyRevivesData()
    end

    local nextSundayTS = getNextSundayTimestamp()
    weeklyRevives.next_reset_timestamp = nextSundayTS
    isDataDirty = true
    SaveWeeklyRevivesData(true)

    local diffSeconds = nextSundayTS - now
    if diffSeconds < 0 then diffSeconds = 0 end
    local diffMs = diffSeconds * 1000

    local hours = math.floor(diffSeconds / 3600)
    local mins = math.floor((diffSeconds % 3600) / 60)
    print(string.format('^2[qbx_ambulancejob]^0 Đã hẹn giờ Log tuần Y Tế vào 00:00 Chủ Nhật (%s) - Còn %d giờ %d phút.', os.date('%d/%m/%Y 00:00:00', nextSundayTS), hours, mins))

    SetTimeout(diffMs, function()
        print('^2[qbx_ambulancejob]^0 Đến mốc 00:00 Chủ Nhật! Đang tự động gửi Log tuần & Reset...')
        SendWeeklyDiscordSummary()
        ResetWeeklyRevivesData()
        scheduleWeeklyReset()
    end)
end

-- Initialize system on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    LoadWeeklyRevivesData()
    scheduleWeeklyReset()
end)

-- Auto-save thread (every 5 mins if data changed)
CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)
        SaveWeeklyRevivesData(false)
    end
end)

-- Save on resource stop / server restart
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print("Luu khi  source stop ")
    SaveWeeklyRevivesData(true)
end)

-- Save when a player disconnects from the server
AddEventHandler('playerDropped', function()
    SaveWeeklyRevivesData(false)
end)

-- Admin Commands for Testing
lib.addCommand('testweeklylog', {
    help = '[ADMIN] Test gửi Discord log thống kê cứu người tuần này',
    restricted = 'group.admin',
}, function(source)
    SendWeeklyDiscordSummary()
    if source and source > 0 then
        exports.qbx_core:Notify(source, 'Đã gửi log test thống kê tuần về Discord!', 'success')
    else
        print('^2[qbx_ambulancejob]^0 Đã gửi log test thống kê tuần về Discord!')
    end
end)

lib.addCommand('forceweeklyreset', {
    help = '[ADMIN] Ép gửi Discord log và reset đếm cứu người tuần này',
    restricted = 'group.admin',
}, function(source)
    SendWeeklyDiscordSummary()
    ResetWeeklyRevivesData()
    scheduleWeeklyReset()
    if source and source > 0 then
        exports.qbx_core:Notify(source, 'Đã ép gửi log tuần và reset số liệu đếm thành công!', 'success')
    else
        print('^2[qbx_ambulancejob]^0 Đã ép gửi log tuần và reset số liệu đếm thành công!')
    end
end)

lib.addCommand('checkweeklylog', {
    help = '[ADMIN] Xem danh sách đếm số lượt cứu người của Y Tế tuần này',
    restricted = 'group.admin',
}, function(source)
    local list = {}
    if weeklyRevives.players then
        for citizenid, info in pairs(weeklyRevives.players) do
            table.insert(list, string.format('• %s (%s): %d lượt', info.name or 'N/A', citizenid, info.count or 0))
        end
    end

    local msg = '--- DANH SÁCH CỨU NGUỜI TUẦN NÀY ---\n'
    if #list == 0 then
        msg = msg .. 'Chưa có lượt cứu nào trong tuần này.'
    else
        msg = msg .. table.concat(list, '\n')
    end

    if source and source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 200},
            multiline = true,
            args = {'[Y TẾ LOG]', msg}
        })
    else
        print(msg)
    end
end)
