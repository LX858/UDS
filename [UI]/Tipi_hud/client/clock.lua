local wsBaseTime, wsTimeOffset = 0, 0
local wsReady = false

local function isWeatherSyncActive()
    if Config.UseWeatherSync == false then
        return false
    end
    return GetResourceState(Config.WeatherSyncResource or 'qb-weathersync') == 'started'
end

local function requestWeatherSync()
    if not isWeatherSyncActive() then
        return
    end
    TriggerServerEvent('qb-weathersync:server:RequestStateSync')
end

RegisterNetEvent('qb-weathersync:client:SyncTime', function(base, offset, _freeze)
    wsBaseTime = base
    wsTimeOffset = offset
    wsReady = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    requestWeatherSync()
end)

CreateThread(function()
    if not isWeatherSyncActive() then
        return
    end
    Wait(1500)
    requestWeatherSync()
end)

local function getRealWorldDateTime()
    local year, month, day, hour, minute = GetLocalTime()
    if type(year) == 'number' and year >= 2020 and type(month) == 'number' and type(day) == 'number' then
        return hour or 0, minute or 0, day, month, year
    end

    local offset = (Config.RealWorldTimezoneOffset or 7) * 3600
    local cloud = GetCloudTimeAsInt()
    if type(cloud) == 'number' and cloud > 1000000000 then
        local totalSeconds = cloud + offset
        local hours = math.floor(totalSeconds / 3600) % 24
        local minutes = math.floor(totalSeconds / 60) % 60
        local ok, t = pcall(os.date, '!*t', totalSeconds)
        if ok and type(t) == 'table' and t.day and t.month and t.year then
            return hours, minutes, t.day, t.month, t.year
        end
    end

    error('real-world time unavailable')
end

function getGameClockTime()
    if Config.UseRealWorldTime then
        local ok, hours, minutes, day, month, year = pcall(getRealWorldDateTime)
        if ok then
            return hours, minutes, day, month, year
        end
    end

    local hours, minutes
    if not isWeatherSyncActive() then
        hours, minutes = GetClockHours(), GetClockMinutes()
    elseif Config.WeatherSyncRealTime then
        hours, minutes = GetClockHours(), GetClockMinutes()
    elseif wsReady then
        local total = wsBaseTime + wsTimeOffset
        hours, minutes = math.floor((total / 60) % 24), math.floor(total % 60)
    else
        hours, minutes = GetClockHours(), GetClockMinutes()
    end

    local rok, rh, rm, day, month, year = pcall(getRealWorldDateTime)
    if rok then
        return hours, minutes, day, month, year
    end

    return hours, minutes, GetClockDayOfMonth(), GetClockMonth() + 1, GetClockYear()
end
