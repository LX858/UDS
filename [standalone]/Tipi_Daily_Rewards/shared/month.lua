Month = Month or {}

local function pad2(n)
	return n < 10 and ('0' .. n) or tostring(n)
end

local function getDateTable()
	if os and type(os.date) == 'function' then
		local ok, t = pcall(os.date, '*t')
		if ok and type(t) == 'table' and tonumber(t.year) and tonumber(t.month) and tonumber(t.month) >= 1 and tonumber(t.month) <= 12 then
			return t
		end
	end

	if type(GetClockYear) == 'function' and type(GetClockMonth) == 'function' and type(GetClockDayOfMonth) == 'function' then
		local y = GetClockYear()
		local mo = GetClockMonth() + 1
		local d = GetClockDayOfMonth()
		local h = type(GetClockHours) == 'function' and GetClockHours() or 0
		local mi = type(GetClockMinutes) == 'function' and GetClockMinutes() or 0
		local s = type(GetClockSeconds) == 'function' and GetClockSeconds() or 0
		if mo >= 1 and mo <= 12 and y and y > 2000 then
			return { year = y, month = mo, day = d, hour = h, min = mi, sec = s }
		end
	end

	print('^1[Tipi_Daily_Rewards] Không lấy được ngày hệ thống (os.date). Kiểm tra đồng hồ máy chủ.^0')
	return { year = 1970, month = 1, day = 1, hour = 0, min = 0, sec = 0 }
end

local function getTimestamp()
	if type(GetClockDate) == 'function' then
		local d, mo, y = GetClockDate()
		local h, mi, s = GetClockTime()
		return 0
	end
	return os.time()
end

function Month.GetKey(year, month)
	if not year or not month then
		local t = getDateTable()
		year, month = t.year, t.month
	end
	return string.format('%04d-%02d', year, month)
end

function Month.GetDayKey(day, year, month)
	local t = getDateTable()
	year = year or t.year
	month = month or t.month
	return string.format('%04d-%02d-%02d', year, month, day)
end

function Month.GetTodayDay()
	return getDateTable().day
end

function Month.GetDaysInMonth(year, month)
	local t = getDateTable()
	year = year or t.year
	month = month or t.month
	if os and os.time then
		return tonumber(os.date('%d', os.time({ year = year, month = month + 1, day = 0 })))
	end
	local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if month == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) then
		return 29
	end
	return days[month] or 30
end

function Month.GetSecondsUntilMidnight()
	local t = getDateTable()
	if os and os.time then
		local now = os.time()
		local midnight = os.time({ year = t.year, month = t.month, day = t.day + 1, hour = 0, min = 0, sec = 0 })
		return math.max(0, midnight - now)
	end
	return math.max(0, (23 - t.hour) * 3600 + (59 - t.min) * 60 + (59 - t.sec) + 1)
end

function Month.GetCalendarInfo()
	local t = getDateTable()
	return {
		year = t.year,
		month = t.month,
		daysInMonth = Month.GetDaysInMonth(t.year, t.month),
		monthKey = Month.GetKey(t.year, t.month),
		todayDay = Month.GetTodayDay(),
	}
end

function Month.GetVipDayKey(day, year, month)
	return Month.GetDayKey(day, year, month) .. '#vip'
end

function Month.FilterProgress(raw, monthKey)
	local filtered = {}
	if type(raw) ~= 'table' then return filtered end

	for key, value in pairs(raw) do
		if value and type(key) == 'string' and key:sub(1, 7) == monthKey and not key:find('#vip', 1, true) then
			local day = tonumber(key:sub(9, 10))
			if day then
				filtered[tostring(day)] = true
			end
		end
	end

	return filtered
end

function Month.FilterVipProgress(raw, monthKey)
	local filtered = {}
	if type(raw) ~= 'table' then return filtered end

	for key, value in pairs(raw) do
		if value and type(key) == 'string' and key:sub(1, 7) == monthKey and key:find('#vip', 1, true) then
			local day = tonumber(key:sub(9, 10))
			if day then
				filtered[tostring(day)] = true
			end
		end
	end

	return filtered
end

function MonthGetKey(year, month)
	return Month.GetKey(year, month)
end

function MonthGetDayKey(day, year, month)
	return Month.GetDayKey(day, year, month)
end

function MonthGetVipDayKey(day, year, month)
	return Month.GetVipDayKey(day, year, month)
end

function MonthGetTodayDay()
	return Month.GetTodayDay()
end

function MonthGetDaysInMonth(year, month)
	return Month.GetDaysInMonth(year, month)
end

function MonthGetSecondsUntilMidnight()
	return Month.GetSecondsUntilMidnight()
end

function MonthGetCalendarInfo()
	return Month.GetCalendarInfo()
end

function MonthFilterProgress(raw, monthKey)
	return Month.FilterProgress(raw, monthKey)
end

function MonthFilterVipProgress(raw, monthKey)
	return Month.FilterVipProgress(raw, monthKey)
end
