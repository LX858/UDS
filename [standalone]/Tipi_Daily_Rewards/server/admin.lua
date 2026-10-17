
local function isDailyAdmin(source)
	if source == 0 then return true end
	return IsPlayerAceAllowed(source, Config.Admin.permission or 'group.admin')
		or IsPlayerAceAllowed(source, ('command.%s'):format(Config.Admin.command or 'admindaily'))
end

local function adminDenied(cb)
	cb({ ok = false, error = 'no_permission' })
end

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:AdminGet', function(source, cb, monthKey)
	if not isDailyAdmin(source) then
		adminDenied(cb)
		return
	end

	local calendar = Month.GetCalendarInfo()
	if type(monthKey) ~= 'string' or not monthKey:match('^%d%d%d%d%-%d%d$') then
		monthKey = calendar.monthKey
	end
	local year = tonumber(monthKey:sub(1, 4)) or calendar.year
	local month = tonumber(monthKey:sub(6, 7)) or calendar.month
	if not month or month < 1 or month > 12 then
		monthKey = calendar.monthKey
		year = calendar.year
		month = calendar.month
	end
	local daysInMonth = Month.GetDaysInMonth(year, month)
	local monthData = DailyCatalog.GetMonth(monthKey, daysInMonth)
	local streaks = DailyCatalog.GetStreaks()
	local templateMonth = DailyCatalog.BuildTemplateMonth(daysInMonth)
	local templateStreaks = DailyCatalog.BuildTemplateStreaks()
	local settings = DailyCatalog.GetSettings()
	local templateSettings = DailyCatalog.BuildTemplateSettings()

	cb({
		ok = true,
		monthKey = monthKey,
		calendarYear = year,
		calendarMonth = month,
		daysInMonth = daysInMonth,
		todayDay = calendar.todayDay,
		normal = monthData.normal,
		vip = monthData.vip,
		fromSql = monthData.fromSql == true,
		fromTemplate = monthData.fromTemplate == true,
		streaks = streaks.milestones,
		streaksFromSql = streaks.fromSql == true,
		templateNormal = templateMonth.normal,
		templateVip = templateMonth.vip,
		templateStreaks = templateStreaks.milestones,
		itemTypes = { 'item', 'cash', 'clothing' },
		clothingComponents = ItemsHelper.GetClothingComponents(),
		clothingImageUrl = Config.ClothingImageUrl,
		clothingImageExt = Config.ClothingImageExt,
		vipPackPrice = settings.vipPackPrice,
		missedDayClaimPrice = settings.missedDayClaimPrice,
		missedDayClaimMultiplier = settings.missedDayClaimMultiplier,
		missedDayClaimEnabled = settings.missedDayClaimEnabled,
		maxMissedClaimsPerMonth = settings.maxMissedClaimsPerMonth,
		missedClaimPricePreview = MissedPrice.Preview(
			settings.missedDayClaimPrice,
			settings.missedDayClaimMultiplier,
			settings.maxMissedClaimsPerMonth
		),
		settingsFromSql = settings.fromSql == true,
		templateVipPackPrice = templateSettings.vipPackPrice,
		templateMissedDayClaimPrice = templateSettings.missedDayClaimPrice,
		templateMissedDayClaimMultiplier = templateSettings.missedDayClaimMultiplier,
		templateMissedDayClaimEnabled = templateSettings.missedDayClaimEnabled,
		templateMaxMissedClaimsPerMonth = templateSettings.maxMissedClaimsPerMonth,
	})
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:AdminSaveMonth', function(source, cb, body)
	if not isDailyAdmin(source) then
		adminDenied(cb)
		return
	end

	body = type(body) == 'table' and body or {}
	local monthKey = body.monthKey
	if type(monthKey) ~= 'string' or not monthKey:match('^%d%d%d%d%-%d%d$') then
		cb({ ok = false, error = 'bad_month' })
		return
	end

	local identifier = FrameworkGetIdentifier(FrameworkGetPlayer(source)) or GetPlayerName(source) or 'admin'
	local saved = DailyCatalog.SaveMonth(monthKey, body.normal, body.vip, identifier)
	cb({
		ok = true,
		monthKey = monthKey,
		normal = saved.normal,
		vip = saved.vip,
		fromSql = true,
		fromTemplate = false,
	})
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:AdminSaveStreaks', function(source, cb, body)
	if not isDailyAdmin(source) then
		adminDenied(cb)
		return
	end

	body = type(body) == 'table' and body or {}
	local identifier = FrameworkGetIdentifier(FrameworkGetPlayer(source)) or GetPlayerName(source) or 'admin'
	local saved = DailyCatalog.SaveStreaks(body.milestones, identifier)
	cb({
		ok = true,
		streaks = saved.milestones,
		streaksFromSql = true,
	})
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:AdminSaveSettings', function(source, cb, body)
	if not isDailyAdmin(source) then
		adminDenied(cb)
		return
	end

	body = type(body) == 'table' and body or {}
	local identifier = FrameworkGetIdentifier(FrameworkGetPlayer(source)) or GetPlayerName(source) or 'admin'
	local saved = DailyCatalog.SaveSettings(body, identifier)
	cb({
		ok = true,
		vipPackPrice = saved.vipPackPrice,
		missedDayClaimPrice = saved.missedDayClaimPrice,
		missedDayClaimMultiplier = saved.missedDayClaimMultiplier,
		missedDayClaimEnabled = saved.missedDayClaimEnabled,
		maxMissedClaimsPerMonth = saved.maxMissedClaimsPerMonth,
		missedClaimPricePreview = MissedPrice.Preview(
			saved.missedDayClaimPrice,
			saved.missedDayClaimMultiplier,
			saved.maxMissedClaimsPerMonth
		),
		settingsFromSql = true,
	})
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:AdminIsAllowed', function(source, cb)
	cb({ ok = isDailyAdmin(source) })
end)

exports('IsDailyAdmin', isDailyAdmin)

lib.addCommand(Config.Admin.command or 'admindaily', {
	help = Config.Admin.description or 'Mở bảng quản trị điểm danh ngày',
	restricted = Config.Admin.permission or 'group.admin',
}, function(source)
	TriggerClientEvent('Tipi_Daily_Rewards:Client:OpenAdminPanel', source)
end)
