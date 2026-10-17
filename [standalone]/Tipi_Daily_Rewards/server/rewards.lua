RewardRandom = RewardRandom or {}

local uiMonthCache = {}

local function copyReward(reward)
	if not reward then return nil end
	return ItemsHelper.EnrichReward(reward)
end

function RewardRandom.ClearUiCache()
	uiMonthCache = {}
end

function RewardRandom.LoadAssignments(row)
	return decodeJson(row and row.month_assignments, {})
end

function RewardRandom.SaveAssignments(citizenid, assignments)
	ExecuteSql(
		'UPDATE tipi_daily_rewards SET month_assignments = ? WHERE citizenid = ?',
		{ json.encode(assignments), citizenid }
	)
end

local function ensureMonthBucket(assignments, monthKey)
	assignments[monthKey] = assignments[monthKey] or {}
	return assignments[monthKey]
end

local function getCachedUiRewards(monthKey, track, daysInMonth, sourceMap)
	local cacheKey = ('%s:%s:%s'):format(monthKey, track, daysInMonth)
	local cached = uiMonthCache[cacheKey]
	if cached then
		return cached
	end

	local rewards = {}
	for day = 1, daysInMonth do
		local reward = sourceMap[tostring(day)]
		if reward then
			rewards[tostring(day - 1)] = copyReward(reward)
		end
	end
	uiMonthCache[cacheKey] = rewards
	return rewards
end

--- Quà theo ngày lấy từ catalog SQL (fallback config). Không random theo player.
function RewardRandom.EnsureMonthRewards(_citizenid, _row, monthKey, daysInMonth)
	local calendar = Month.GetCalendarInfo()
	monthKey = monthKey or calendar.monthKey
	daysInMonth = daysInMonth or calendar.daysInMonth
	local month = DailyCatalog.GetMonth(monthKey, daysInMonth)
	return getCachedUiRewards(monthKey, 'normal', daysInMonth, month.normal), daysInMonth, monthKey
end

function RewardRandom.EnsureVipMonthRewards(_citizenid, _row, monthKey, daysInMonth)
	local calendar = Month.GetCalendarInfo()
	monthKey = monthKey or calendar.monthKey
	daysInMonth = daysInMonth or calendar.daysInMonth
	local month = DailyCatalog.GetMonth(monthKey, daysInMonth)
	return getCachedUiRewards(monthKey, 'vip', daysInMonth, month.vip), daysInMonth, monthKey
end
function RewardRandom.HasVipPack(row, monthKey)
	monthKey = monthKey or Month.GetCalendarInfo().monthKey
	local assignments = RewardRandom.LoadAssignments(row)
	local bucket = assignments[monthKey]
	return type(bucket) == 'table' and bucket.vip_purchased == true
end

function RewardRandom.MarkVipPackPurchased(citizenid, row, monthKey)
	monthKey = monthKey or Month.GetCalendarInfo().monthKey
	local assignments = RewardRandom.LoadAssignments(row)
	local bucket = ensureMonthBucket(assignments, monthKey)
	bucket.vip_purchased = true
	RewardRandom.SaveAssignments(citizenid, assignments)
	return true
end

function RewardRandom.GetDayReward(citizenid, row, day)
	local rewards = select(1, RewardRandom.EnsureMonthRewards(citizenid, row))
	return rewards[tostring(tonumber(day) - 1)]
end

function RewardRandom.GetVipDayReward(citizenid, row, day)
	local rewards = select(1, RewardRandom.EnsureVipMonthRewards(citizenid, row))
	return rewards[tostring(tonumber(day) - 1)]
end

function MonthBuildRewards(citizenid, row)
	return RewardRandom.EnsureMonthRewards(citizenid, row)
end

function MonthBuildVipRewards(citizenid, row)
	return RewardRandom.EnsureVipMonthRewards(citizenid, row)
end
