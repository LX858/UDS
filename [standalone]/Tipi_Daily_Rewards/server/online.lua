local OnlineCache = {}

local function getDateKey()
	return os.date('%Y-%m-%d')
end

function OnlineNormalizeToday(today)
	if type(today) == 'number' then
		return {
			minutes = today,
			present = false,
		}
	end

	if type(today) ~= 'table' then
		return {
			minutes = 0,
			present = false,
		}
	end

	return {
		minutes = tonumber(today.minutes) or 0,
		present = today.present == true,
	}
end

function OnlineGetTodayState(row)
	local data = OnlineLoadData(row)
	local key = getDateKey()
	return OnlineNormalizeToday(data[key])
end

function OnlineLoadData(row)
	return decodeJson(row and row.daily_online, {})
end

local function setCache(citizenid, data, dateKey)
	dateKey = dateKey or getDateKey()
	local today = OnlineNormalizeToday(data[dateKey])
	OnlineCache[citizenid] = {
		minutes = today.minutes,
		present = today.present,
		dateKey = dateKey,
		data = data,
	}
	return OnlineCache[citizenid]
end

local function persistOnlineCache(citizenid, cached)
    cached.dirty = true
    local ok, err = pcall(ExecuteSql, 'UPDATE tipi_daily_rewards SET daily_online = ? WHERE citizenid = ?', {
        json.encode(cached.data), citizenid
    })
    if ok then
        cached.dirty = false
        if cached.disconnected and OnlineCache[citizenid] == cached then OnlineCache[citizenid] = nil end
        return true
    end
    if not cached.retryPending then
        cached.retryPending = true
        SetTimeout(5000, function()
            cached.retryPending = false
            WithDailyOnlineLock(citizenid, function()
                local latest = OnlineCache[citizenid]
                if latest and latest.dirty then persistOnlineCache(citizenid, latest) end
            end)
        end)
        print(('[Tipi_Daily_Rewards] Retaining unsaved minutes for retry: %s'):format(tostring(err)))
    end
    return false
end

local function loadCacheFromDb(citizenid)
	local dateKey = getDateKey()
    local pending = OnlineCache[citizenid]
    if pending and pending.dirty then
        pending.dateKey = dateKey
        local today = OnlineNormalizeToday(pending.data[dateKey])
        pending.minutes, pending.present = today.minutes, today.present
        return pending
    end
	local row = ExecuteSql('SELECT daily_online FROM tipi_daily_rewards WHERE citizenid = ?', { citizenid })
	if not row or not row[1] then
		ExecuteSql('INSERT IGNORE INTO tipi_daily_rewards (citizenid) VALUES (?)', { citizenid })
		row = ExecuteSql('SELECT daily_online FROM tipi_daily_rewards WHERE citizenid = ?', { citizenid })
	end
	return setCache(citizenid, OnlineLoadData(row and row[1]), dateKey)
end

function OnlineSaveToday(citizenid, minutes, present)
    if OnlineCache[citizenid] and OnlineCache[citizenid].dirty then loadCacheFromDb(citizenid) end
	local dateKey = getDateKey()
	local cached = OnlineCache[citizenid]
	local data

	if cached and cached.dateKey == dateKey and cached.data then
		data = cached.data
	else
		local row = ExecuteSql('SELECT daily_online FROM tipi_daily_rewards WHERE citizenid = ?', { citizenid })
		data = {}
		if row and row[1] then
			data = OnlineLoadData(row[1])
		end
	end

	local existing = OnlineNormalizeToday(data[dateKey])
	local keepPresent = present == true

	if present == nil then
		keepPresent = existing.present
	end

	data[dateKey] = {
		minutes = math.max(0, math.floor(minutes)),
		present = keepPresent,
	}

	ExecuteSql('UPDATE tipi_daily_rewards SET daily_online = ? WHERE citizenid = ?', { json.encode(data), citizenid })
	setCache(citizenid, data, dateKey)
end

function OnlineGetMinutes(citizenid, row)
	local dateKey = getDateKey()
	local cached = OnlineCache[citizenid]
	if cached and cached.dateKey == dateKey then
		return cached.minutes
	end

	local state = OnlineGetTodayState(row)
	local data = OnlineLoadData(row)
	setCache(citizenid, data, dateKey)
	return state.minutes
end

function OnlineIsPresentToday(row)
	return OnlineGetTodayState(row).present == true
end

function OnlineGetMonthClaimMinMinutes()
	return math.max(1, math.floor(tonumber(Config.MonthClaimMinMinutes) or 1))
end

function OnlineIsTodayEligibleForMonthClaim(row)
	local state = OnlineGetTodayState(row)
	if state.present ~= true then
		return false
	end
	return state.minutes >= OnlineGetMonthClaimMinMinutes()
end

function OnlineGetDayStateForCalendarDay(row, day)
	local calendar = MonthGetCalendarInfo()
	local dateKey = MonthGetDayKey(tonumber(day), calendar.year, calendar.month)
	local data = OnlineLoadData(row)
	return OnlineNormalizeToday(data[dateKey])
end

function OnlineIsPastDayEligibleForMonthClaim(row, day)
	local state = OnlineGetDayStateForCalendarDay(row, day)
	if state.present ~= true then
		return false
	end
	return state.minutes >= OnlineGetMonthClaimMinMinutes()
end

function OnlineBuildMonthEligibleDays(row)
	local calendar = MonthGetCalendarInfo()
	local eligible = {}
	local settings = DailyCatalog and DailyCatalog.GetSettings and DailyCatalog.GetSettings() or nil
	local missedCfg = Config.MissedDayClaim or {}
	local missedEnabled = missedCfg.enabled ~= false
	if settings then
		if settings.missedDayClaimEnabled == false then
			missedEnabled = false
		elseif settings.missedDayClaimEnabled == true then
			missedEnabled = true
		end
	end

	for day = 1, calendar.todayDay do
		if day == calendar.todayDay then
			if OnlineIsTodayEligibleForMonthClaim(row) then
				eligible[tostring(day)] = true
			end
		elseif missedEnabled then
			eligible[tostring(day)] = true
		elseif OnlineIsPastDayEligibleForMonthClaim(row, day) then
			eligible[tostring(day)] = true
		end
	end

	return eligible
end

function OnlineBuildMonthFreeDays(row)
	local calendar = MonthGetCalendarInfo()
	local free = {}
	for day = 1, calendar.todayDay - 1 do
		if OnlineIsPastDayEligibleForMonthClaim(row, day) then
			free[tostring(day)] = true
		end
	end
	return free
end

function OnlineMarkPresent(citizenid)
    if OnlineCache[citizenid] and OnlineCache[citizenid].dirty then loadCacheFromDb(citizenid) end
	local cached = OnlineCache[citizenid]
	local dateKey = getDateKey()
	if cached and cached.dateKey == dateKey and cached.data then
		local today = OnlineNormalizeToday(cached.data[dateKey])
		cached.data[dateKey] = {
			minutes = today.minutes,
			present = true,
		}
		cached.present = true
		ExecuteSql('UPDATE tipi_daily_rewards SET daily_online = ? WHERE citizenid = ?', {
			json.encode(cached.data),
			citizenid,
		})
		return
	end

	local row = ExecuteSql('SELECT daily_online FROM tipi_daily_rewards WHERE citizenid = ?', { citizenid })
	if not row or not row[1] then
		ExecuteSql('INSERT IGNORE INTO tipi_daily_rewards (citizenid) VALUES (?)', { citizenid })
		OnlineSaveToday(citizenid, 0, true)
		return
	end

	local data = OnlineLoadData(row[1])
	local today = OnlineNormalizeToday(data[dateKey])
	data[dateKey] = {
		minutes = today.minutes,
		present = true,
	}
	ExecuteSql('UPDATE tipi_daily_rewards SET daily_online = ? WHERE citizenid = ?', { json.encode(data), citizenid })
	setCache(citizenid, data, dateKey)
end

--- Cộng 1 phút online — ưu tiên cache để tránh SELECT lặp (SQL global busy lock).
function OnlineAddMinute(citizenid, amount)
	local dateKey = getDateKey()
	local cached = OnlineCache[citizenid]
	if not cached or cached.dateKey ~= dateKey or not cached.data then
		cached = loadCacheFromDb(citizenid)
	end

	local previousMinutes = cached.minutes
	local minutes = previousMinutes + (amount or 1)
	local monthMin = OnlineGetMonthClaimMinMinutes()
	local monthClaimReady = previousMinutes < monthMin and minutes >= monthMin

	cached.data[dateKey] = {
		minutes = minutes,
		present = true,
	}
	cached.minutes = minutes
	cached.present = true

    cached.disconnected = false
    persistOnlineCache(citizenid, cached)

	return minutes, monthClaimReady
end

-- Serialize character read/modify/write operations, including nested calls.
for _, name in ipairs({ 'OnlineAddMinute', 'OnlineMarkPresent', 'OnlineSaveToday' }) do
    local original = _G[name]
    _G[name] = function(identifier, ...)
        return WithDailyOnlineLock(identifier, original, identifier, ...)
    end
end

local onlineSources = {}
local function onlineIdentifier(src)
    if Framework.Name == 'qbx' then return exports.qbx_core:GetPlayerCitizenId(src) end
    return FrameworkGetIdentifier(FrameworkGetPlayer(src))
end
CreateThread(function()
    while true do
        local players = GetPlayers()
        local seen = {}
        for i, id in ipairs(players) do
            local src, now = tonumber(id), GetGameTimer()
            local citizenid = onlineIdentifier(src)
            seen[src] = true
            if citizenid then
                local session = onlineSources[src]
                if not session or session.citizenid ~= citizenid then
                    session = { citizenid = citizenid, lastMinute = now }
                    onlineSources[src] = session
                end
                local minutes = math.floor((now - session.lastMinute) / 60000)
                if minutes > 0 then
                    local ok, err = pcall(function()
                        local _, ready = OnlineAddMinute(citizenid, minutes)
                        session.lastMinute = session.lastMinute + minutes * 60000
                        if onlineSources[src] ~= session or onlineIdentifier(src) ~= citizenid then return end
                        if ready then
                            TriggerClientEvent('Tipi_Daily_Rewards:Client:MonthClaimReady', src, {
                                minutes = OnlineGetMonthClaimMinMinutes(), todayReward = MonthGetTodayDay()
                            })
                        end
                        if DailyOnline and DailyOnline.PushSync then DailyOnline.PushSync(src, citizenid) end
                    end)
                    if not ok then print(('[Tipi_Daily_Rewards] Online update failed: %s'):format(tostring(err))) end
                end
            end
            if i % 16 == 0 then Wait(0) end
        end
        for src in pairs(onlineSources) do if not seen[src] then onlineSources[src] = nil end end
        Wait(1000)
    end
end)

AddEventHandler('playerDropped', function()
	local src = source
	local player = FrameworkGetPlayer(src)
	local citizenid = onlineSources[src] and onlineSources[src].citizenid or FrameworkGetIdentifier(player)
    onlineSources[src] = nil
	if citizenid then
        DailyOnlineRows[citizenid] = nil
        local cached = OnlineCache[citizenid]
        if cached and cached.dirty then cached.disconnected = true
        else OnlineCache[citizenid] = nil end
	end
end)

CreateThread(function()
	if Framework.Name == 'qbx' or Framework.Name == 'qb' then
		AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
			local citizenid = Player and Player.PlayerData and Player.PlayerData.citizenid
			if citizenid then
				OnlineMarkPresent(citizenid)
			end
		end)
	elseif Framework.Name == 'esx' then
		AddEventHandler('esx:playerLoaded', function(_, xPlayer)
			if xPlayer and xPlayer.identifier then
				OnlineMarkPresent(xPlayer.identifier)
			end
		end)
	end
end)

local function flushPendingOnline()
    for citizenid, cached in pairs(OnlineCache) do
        if cached.dirty then WithDailyOnlineLock(citizenid, function() persistOnlineCache(citizenid, cached) end) end
    end
end
AddEventHandler('txAdmin:events:serverShuttingDown', flushPendingOnline)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then flushPendingOnline() end
end)
