local webhooks = {
    ['police'] = 'https://discord.com/api/webhooks/1512205781813166091/-UocYt4_GRrX82qyJpJq0qiOLuG6XQt8XCC-8tTav0FhL2SAqYE8kE-hynbQIDo9wmuz',
    ['ambulance'] = 'https://discord.com/api/webhooks/1512205559628169318/bX3GNNSglzpUL7YjkZvfvPnHVT8a58brSNKuyNzxhOhWSSOVxBzYamO-Y8aRpXwF5HfJ',
    ['cardealer'] = '',
    ['cayxang'] = 'https://discord.com/api/webhooks/1536371081613672558/Ufe8ESX_QoRqMXqhwMzcRN3t1uGhDxI6hK7Zxf5E9UEz3cSvud-PB24jq30yvErcxCwd',
}
local hooks = webhooks 

local function formatTimeRegular(time)
    if not time or not time.hour or not time.min then return "N/A" end
    local hour, minute = time.hour, time.min
    local type = "AM"
    if hour >= 12 then
        type = "PM"
        if hour > 12 then hour = hour - 12 end
    elseif hour == 0 then
        hour = 12
    end
    return string.format('%d:%02d %s', hour, minute, type)
end

local function getPlayerJob(source)
    local xPlayer = exports.qbx_core:GetPlayer(source)
    return xPlayer and xPlayer.PlayerData.job.name or "unknown"
end

local function getPlayerName(source)
    local xPlayer = exports.qbx_core:GetPlayer(source)
    if xPlayer and xPlayer.PlayerData.charinfo then
        return string.format('%s %s', xPlayer.PlayerData.charinfo.firstname, xPlayer.PlayerData.charinfo.lastname)
    end
    return "unknown"
end

local function getPlayerCallsign(source)
    local xPlayer = exports.qbx_core:GetPlayer(source)
    if xPlayer and xPlayer.PlayerData.metadata and xPlayer.PlayerData.metadata.callsign then
        return xPlayer.PlayerData.metadata.callsign
    end
    return ""
end

local function calculateDutyTime(clockin, clockout)
    local dutyTime = os.difftime(os.time(clockout), os.time(clockin))
    local hours = math.floor(dutyTime / 3600)
    local minutes = math.floor((dutyTime % 3600) / 60)
    local seconds = dutyTime % 60
    return string.format('%02d:%02d:%02d', hours, minutes, seconds)
end

monitor = { storedClockins = {} }

function monitor:new(source)
    if self.storedClockins[tostring(source)] then return end
    self.storedClockins[tostring(source)] = os.date('*t')
end

function monitor:log(source, job)
    local clockin_time = self.storedClockins[tostring(source)]
    if not clockin_time or not clockin_time.year then return end  
    self.storedClockins[tostring(source)] = nil
    local clockout_time = os.date('*t')
    local name = getPlayerName(source)
    local callsign = getPlayerCallsign(source)
    local dutyTime = calculateDutyTime(clockin_time, clockout_time)
    
    local format_clockin = string.format('Ngày %02d | Tháng %02d | Giờ %s', clockin_time.day, clockin_time.month, formatTimeRegular(clockin_time))
    local format_clockout = string.format('Ngày %02d | Tháng %02d | Giờ %s', clockout_time.day, clockout_time.month, formatTimeRegular(clockout_time))

    local title_text = string.format('🕒 Duty Log - %s', name)
    if callsign and callsign ~= "" then
        title_text = string.format('🕒 Duty Log - %s (%s)', name, callsign)
    end

    local discordLogData = {
        username = 'DUTY BAN NGÀNH',
        avatar_url = 'https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/logosv.webp',
        embeds = {
            {
                title = title_text,
                color = 65280,
                footer = { text = 'Hệ thống tự động tính toán thời gian Duty', icon_url = 'https://r2.fivemanage.com/QtScYt7BSlPh2po8ZsKrS/logosv.webp' },
                fields = {
                    { name = "✅ VÀO LÀM LÚC", value = format_clockin, inline = false },
                    { name = "⛔ RỜI CA LÚC", value = format_clockout, inline = false },
                    { name = "⏱️ Tổng thời gian hoạt động", value = dutyTime, inline = false }
                }
            }
        }
    }

    PerformHttpRequest(hooks[job], function() end, 'POST', json.encode(discordLogData), { ['Content-Type'] = 'application/json' })
end


RegisterNetEvent('QBCore:Server:SetDuty', function(source, duty)
    local job = getPlayerJob(source)
    if not hooks[job] then return end
    if duty then
        monitor:new(source)
    else
        monitor:log(source, job)
    end
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
    Citizen.Wait(2500)
    local job = player.PlayerData.job.name
    if hooks[job] and player.PlayerData.job.onduty then
        monitor:new(player.PlayerData.source)
    end
end)

AddEventHandler('playerDropped', function()
    local job = getPlayerJob(source)
    if monitor.storedClockins[tostring(source)] then
        monitor:log(source, job)
    end
end)
