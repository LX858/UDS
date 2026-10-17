DailyCatalog = DailyCatalog or {}

local cache = {
	months = {},
	streaks = nil,
	settings = nil,
	loaded = false,
}

local function copyReward(reward)
	if type(reward) ~= 'table' then return nil end
	return ItemsHelper.EnrichReward(reward)
end

local function normalizeDayMap(raw)
	local out = {}
	if type(raw) ~= 'table' then return out end
	for key, value in pairs(raw) do
		local day = tonumber(key)
		local reward = copyReward(value)
		local hasIdentity = reward and (
			ItemsHelper.IsMoneyType(reward.itemType)
			or (reward.itemName and reward.itemName ~= '')
			or (reward.itemType == 'clothing' and reward.clothComponent and reward.clothComponent ~= '')
		)
		if day and day >= 1 and day <= 31 and hasIdentity then
			out[tostring(day)] = reward
		end
	end
	return out
end

function DailyCatalog.BuildTemplateMonth(daysInMonth)
	daysInMonth = math.max(1, math.floor(tonumber(daysInMonth) or 31))
	local normalDays = Config.DefaultNormalDays or {}
	local vipDays = Config.DefaultVipDays or {}
	local normal, vip = {}, {}

	for day = 1, daysInMonth do
		local n = copyReward(normalDays[day] or normalDays[tostring(day)])
		local v = copyReward(vipDays[day] or vipDays[tostring(day)])
		if n then normal[tostring(day)] = n end
		if v then vip[tostring(day)] = v end
	end

	return { normal = normal, vip = vip, fromTemplate = true }
end

function DailyCatalog.BuildTemplateStreaks()
	local list = {}
	for _, row in ipairs(Config.StreakMilestones or {}) do
		local days = math.max(1, math.floor(tonumber(row.days) or 0))
		local reward = copyReward(row.reward)
		if days > 0 and reward then
			list[#list + 1] = { days = days, reward = reward }
		end
	end
	table.sort(list, function(a, b) return a.days < b.days end)
	return { milestones = list, fromTemplate = true }
end

local function monthKeyToCatalogKey(monthKey)
	return ('month:%s'):format(monthKey)
end

function DailyCatalog.EnsureTables()
	ExecuteSql([[
		CREATE TABLE IF NOT EXISTS `tipi_daily_catalog` (
			`catalog_key` varchar(32) NOT NULL,
			`payload` longtext NOT NULL,
			`updated_by` varchar(64) DEFAULT NULL,
			`updated_at` int(11) NOT NULL DEFAULT 0,
			PRIMARY KEY (`catalog_key`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
	]])
end

function DailyCatalog.Invalidate(monthKey)
	if monthKey then
		cache.months[monthKey] = nil
	else
		cache.months = {}
	end
	cache.streaks = nil
	cache.settings = nil
	if RewardRandom and RewardRandom.ClearUiCache then
		RewardRandom.ClearUiCache()
	end
end
local function loadPayload(catalogKey)
	local rows = ExecuteSql('SELECT payload FROM tipi_daily_catalog WHERE catalog_key = ? LIMIT 1', { catalogKey })
	if not rows or not rows[1] then return nil end
	return decodeJson(rows[1].payload, nil)
end

function DailyCatalog.GetMonth(monthKey, daysInMonth)
	monthKey = monthKey or Month.GetCalendarInfo().monthKey
	daysInMonth = daysInMonth or Month.GetDaysInMonth()

	if cache.months[monthKey] then
		return cache.months[monthKey]
	end

	local payload = loadPayload(monthKeyToCatalogKey(monthKey))
	local template = DailyCatalog.BuildTemplateMonth(daysInMonth)
	local normal = normalizeDayMap(payload and payload.normal)
	local vip = normalizeDayMap(payload and payload.vip)
	local fromSql = type(payload) == 'table'

	-- Ngày thiếu trong SQL → fill từ config template
	for day = 1, daysInMonth do
		local key = tostring(day)
		if not normal[key] then
			normal[key] = template.normal[key]
		end
		if not vip[key] then
			vip[key] = template.vip[key]
		end
	end

	local result = {
		normal = normal,
		vip = vip,
		fromSql = fromSql,
		fromTemplate = not fromSql,
		monthKey = monthKey,
		daysInMonth = daysInMonth,
	}
	cache.months[monthKey] = result
	return result
end

function DailyCatalog.GetStreaks()
	if cache.streaks then
		return cache.streaks
	end

	local payload = loadPayload('streaks')
	local template = DailyCatalog.BuildTemplateStreaks()
	local milestones = {}

	if type(payload) == 'table' and type(payload.milestones) == 'table' and #payload.milestones > 0 then
		for _, row in ipairs(payload.milestones) do
			local days = math.max(1, math.floor(tonumber(row.days) or 0))
			local reward = copyReward(row.reward)
			if days > 0 and reward then
				milestones[#milestones + 1] = { days = days, reward = reward }
			end
		end
		table.sort(milestones, function(a, b) return a.days < b.days end)
		cache.streaks = { milestones = milestones, fromSql = true, fromTemplate = false }
	else
		cache.streaks = {
			milestones = template.milestones,
			fromSql = false,
			fromTemplate = true,
		}
	end

	return cache.streaks
end

function DailyCatalog.SaveMonth(monthKey, normal, vip, updatedBy)
	local daysInMonth = Month.GetDaysInMonth(
		tonumber(monthKey:sub(1, 4)),
		tonumber(monthKey:sub(6, 7))
	)
	local payload = {
		normal = normalizeDayMap(normal),
		vip = normalizeDayMap(vip),
	}

	-- vẫn fill thiếu trước khi lưu để admin thấy full tháng
	local template = DailyCatalog.BuildTemplateMonth(daysInMonth)
	for day = 1, daysInMonth do
		local key = tostring(day)
		if not payload.normal[key] then payload.normal[key] = template.normal[key] end
		if not payload.vip[key] then payload.vip[key] = template.vip[key] end
	end

	ExecuteSql(
		[[INSERT INTO tipi_daily_catalog (catalog_key, payload, updated_by, updated_at)
			VALUES (?, ?, ?, ?)
			ON DUPLICATE KEY UPDATE payload = VALUES(payload), updated_by = VALUES(updated_by), updated_at = VALUES(updated_at)]],
		{ monthKeyToCatalogKey(monthKey), json.encode(payload), updatedBy or 'admin', os.time() }
	)
	DailyCatalog.Invalidate(monthKey)
	return DailyCatalog.GetMonth(monthKey, daysInMonth)
end

function DailyCatalog.SaveStreaks(milestones, updatedBy)
	local list = {}
	for _, row in ipairs(milestones or {}) do
		local days = math.max(1, math.floor(tonumber(row.days) or 0))
		local reward = copyReward(row.reward)
		if days > 0 and reward then
			list[#list + 1] = { days = days, reward = reward }
		end
	end
	table.sort(list, function(a, b) return a.days < b.days end)

	local payload = { milestones = list }
	ExecuteSql(
		[[INSERT INTO tipi_daily_catalog (catalog_key, payload, updated_by, updated_at)
			VALUES (?, ?, ?, ?)
			ON DUPLICATE KEY UPDATE payload = VALUES(payload), updated_by = VALUES(updated_by), updated_at = VALUES(updated_at)]],
		{ 'streaks', json.encode(payload), updatedBy or 'admin', os.time() }
	)
	DailyCatalog.Invalidate()
	return DailyCatalog.GetStreaks()
end

function DailyCatalog.BuildTemplateSettings()
	local vipPack = Config.VipMonthPack or {}
	local missed = Config.MissedDayClaim or {}
	return {
		vipPackPrice = math.max(0, math.floor(tonumber(vipPack.price) or 0)),
		missedDayClaimPrice = math.max(0, math.floor(tonumber(missed.price) or 0)),
		missedDayClaimMultiplier = MissedPrice.NormalizeMultiplier(missed.multiplier or 2),
		missedDayClaimEnabled = missed.enabled ~= false,
		maxMissedClaimsPerMonth = MissedPrice.ClampMaxClaims(missed.maxClaimsPerMonth, MissedPrice.MAX_CLAIMS_HARD),
		fromTemplate = true,
		fromSql = false,
	}
end

function DailyCatalog.GetSettings()
	if cache.settings then
		return cache.settings
	end

	local template = DailyCatalog.BuildTemplateSettings()
	local payload = loadPayload('settings')
	if type(payload) == 'table' then
		local missedEnabled = template.missedDayClaimEnabled
		if payload.missedDayClaimEnabled == false then
			missedEnabled = false
		elseif payload.missedDayClaimEnabled == true then
			missedEnabled = true
		end
		cache.settings = {
			vipPackPrice = math.max(0, math.floor(tonumber(payload.vipPackPrice) or template.vipPackPrice)),
			missedDayClaimPrice = math.max(0, math.floor(tonumber(payload.missedDayClaimPrice) or template.missedDayClaimPrice)),
			missedDayClaimMultiplier = MissedPrice.NormalizeMultiplier(
				payload.missedDayClaimMultiplier ~= nil and payload.missedDayClaimMultiplier or template.missedDayClaimMultiplier
			),
			missedDayClaimEnabled = missedEnabled,
			maxMissedClaimsPerMonth = MissedPrice.ClampMaxClaims(
				payload.maxMissedClaimsPerMonth ~= nil and payload.maxMissedClaimsPerMonth or template.maxMissedClaimsPerMonth,
				MissedPrice.MAX_CLAIMS_HARD
			),
			fromSql = true,
			fromTemplate = false,
		}
	else
		cache.settings = template
	end

	return cache.settings
end

function DailyCatalog.SaveSettings(body, updatedBy)
	local template = DailyCatalog.BuildTemplateSettings()
	body = type(body) == 'table' and body or {}
	local payload = {
		vipPackPrice = math.max(0, math.floor(tonumber(body.vipPackPrice) or template.vipPackPrice)),
		missedDayClaimPrice = math.max(0, math.floor(tonumber(body.missedDayClaimPrice) or template.missedDayClaimPrice)),
		missedDayClaimMultiplier = MissedPrice.NormalizeMultiplier(
			body.missedDayClaimMultiplier ~= nil and body.missedDayClaimMultiplier or template.missedDayClaimMultiplier
		),
		missedDayClaimEnabled = body.missedDayClaimEnabled ~= false,
		maxMissedClaimsPerMonth = MissedPrice.ClampMaxClaims(
			body.maxMissedClaimsPerMonth ~= nil and body.maxMissedClaimsPerMonth or template.maxMissedClaimsPerMonth,
			MissedPrice.MAX_CLAIMS_HARD
		),
	}

	ExecuteSql(
		[[INSERT INTO tipi_daily_catalog (catalog_key, payload, updated_by, updated_at)
			VALUES (?, ?, ?, ?)
			ON DUPLICATE KEY UPDATE payload = VALUES(payload), updated_by = VALUES(updated_by), updated_at = VALUES(updated_at)]],
		{ 'settings', json.encode(payload), updatedBy or 'admin', os.time() }
	)
	DailyCatalog.Invalidate()
	return DailyCatalog.GetSettings()
end

CreateThread(function()
	Wait(500)
	DailyCatalog.EnsureTables()
end)
