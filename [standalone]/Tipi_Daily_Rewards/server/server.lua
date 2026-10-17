local todayReward, tomorrowReward = nil, nil

local function DispTime(time)
	local days = math.floor(time / 86400)
	local remaining = time % 86400
	local hours = math.floor(remaining / 3600)
	remaining = remaining % 3600
	local minutes = math.floor(remaining / 60)
	remaining = remaining % 60
	local seconds = remaining
	if hours < 10 then hours = '0' .. tostring(hours) end
	if minutes < 10 then minutes = '0' .. tostring(minutes) end
	if seconds < 10 then seconds = '0' .. tostring(seconds) end
	if days > 0 then
		local newnewDays = tonumber(hours) + (tonumber(days) * 24)
		return { Hours = newnewDays, Minutes = minutes, Seconds = seconds, OsTime = time }
	end
	return { Hours = hours, Minutes = minutes, Seconds = seconds, OsTime = time }
end

local function grantConfiguredReward(src, player, identifier, reward)
	if not reward then return end
	local itemType = reward.itemType or 'item'

	if ItemsHelper.IsMoneyType(itemType) then
		FrameworkAddMoney(src, player, reward.itemCount)
		return
	end

	if itemType == 'clothing' then
		if GetResourceState('XNClothes') ~= 'started' then
			print(('[Tipi_Daily_Rewards] XNClothes chưa start — bỏ qua clothing reward (%s)'):format(tostring(reward.clothComponent or reward.itemName)))
			return
		end
		local component = reward.clothComponent or reward.itemName
		local drawable = math.max(1, math.floor(tonumber(reward.clothDrawable) or 1))
		local texture = math.max(1, math.floor(tonumber(reward.clothTexture) or 1))
		local sex = reward.clothSex
		if sex ~= 'male' and sex ~= 'female' then
			sex = nil
		end
		local count = math.max(1, math.floor(tonumber(reward.itemCount) or 1))
		for _ = 1, count do
			local ok, err = exports['XNClothes']:GiveClothingItem(src, component, drawable, texture, 0, sex)
			if not ok then
				print(('[Tipi_Daily_Rewards] GiveClothingItem failed: %s'):format(tostring(err)))
				break
			end
		end
		return
	end

	if itemType == 'item' then
		FrameworkAddItem(src, player, reward.itemName, reward.itemCount)
	end
end

local function ensurePlayerRow(identifier)
	local existingData = ExecuteSql('SELECT * FROM tipi_daily_rewards WHERE citizenid = ?', { identifier })
	if existingData and existingData[1] then return existingData[1] end
	ExecuteSql('INSERT IGNORE INTO tipi_daily_rewards (citizenid) VALUES (?)', { identifier })
	local created = ExecuteSql('SELECT * FROM tipi_daily_rewards WHERE citizenid = ?', { identifier })
	return created and created[1]
end

local function refreshTodayState()
	todayReward = MonthGetTodayDay()
	local secondsLeft = MonthGetSecondsUntilMidnight()
	tomorrowReward = DispTime(secondsLeft)
end

local function getVipPackPrice()
	local settings = DailyCatalog.GetSettings()
	if settings and settings.vipPackPrice ~= nil then
		return math.max(0, math.floor(tonumber(settings.vipPackPrice) or 0))
	end
	local pack = Config.VipMonthPack or {}
	return math.max(0, math.floor(tonumber(pack.price) or 0))
end

local function getPlayerCoin(identifier)
	local pack = Config.VipMonthPack or {}
	local tableName = pack.table or 'players'
	local idColumn = pack.idColumn or 'citizenid'
	local column = pack.column or 'coin'
	local rows = ExecuteSql(('SELECT `%s` AS coin FROM `%s` WHERE `%s` = ? LIMIT 1'):format(column, tableName, idColumn), { identifier })
	if rows and rows[1] then
		return tonumber(rows[1].coin) or 0
	end
	return 0
end

local function setPlayerCoin(identifier, amount, src)
	local pack = Config.VipMonthPack or {}
	local tableName = pack.table or 'players'
	local idColumn = pack.idColumn or 'citizenid'
	local column = pack.column or 'coin'
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	ExecuteSql(('UPDATE `%s` SET `%s` = ? WHERE `%s` = ?'):format(tableName, column, idColumn), { amount, identifier })
	if src and GetResourceState('Tipi_menu') == 'started' then
		TriggerClientEvent('Tipi_menu:cl:syncPlayerCoin', src, amount)
	end
end

local function getMissedDayClaimConfig()
	local settings = DailyCatalog.GetSettings()
	local cfg = Config.MissedDayClaim or {}
	local enabled = cfg.enabled ~= false
	local price = math.max(0, math.floor(tonumber(cfg.price) or 0))
	local multiplier = MissedPrice.NormalizeMultiplier(cfg.multiplier or 2)
	local maxClaimsPerMonth = MissedPrice.ClampMaxClaims(cfg.maxClaimsPerMonth, MissedPrice.MAX_CLAIMS_HARD)
	if settings then
		if settings.missedDayClaimEnabled == false then
			enabled = false
		elseif settings.missedDayClaimEnabled == true then
			enabled = true
		end
		if settings.missedDayClaimPrice ~= nil then
			price = math.max(0, math.floor(tonumber(settings.missedDayClaimPrice) or price))
		end
		if settings.missedDayClaimMultiplier ~= nil then
			multiplier = MissedPrice.NormalizeMultiplier(settings.missedDayClaimMultiplier)
		end
		if settings.maxMissedClaimsPerMonth ~= nil then
			maxClaimsPerMonth = MissedPrice.ClampMaxClaims(settings.maxMissedClaimsPerMonth, MissedPrice.MAX_CLAIMS_HARD)
		end
	end
	-- Không cho vượt số ngày tháng hiện tại
	local calendar = MonthGetCalendarInfo and MonthGetCalendarInfo() or nil
	local daysInMonth = calendar and calendar.daysInMonth or MissedPrice.MAX_CLAIMS_HARD
	maxClaimsPerMonth = MissedPrice.ClampMaxClaims(maxClaimsPerMonth, daysInMonth)
	return {
		enabled = enabled,
		price = price,
		multiplier = multiplier,
		moneyType = cfg.moneyType or Config.MoneyType or 'cash',
		maxClaimsPerMonth = maxClaimsPerMonth,
	}
end

local function buildCallbackData(row, identifier)
	local onlineMinutes = 0
	local presentToday = false
	local calendar = MonthGetCalendarInfo()
	local collectedRaw = decodeJson(row and row.collected or '{}', {})
	local items, daysInMonth, monthKey = {}, calendar.daysInMonth, calendar.monthKey
	local vipItems = {}
	local hasVipPack = false
	local streak = { current = 0, milestones = {} }
	local missedCfg = getMissedDayClaimConfig()
	local monthFreeDays = {}
	local missedClaimsCount = 0

	if row and identifier then
		onlineMinutes = OnlineGetMinutes(identifier, row)
		presentToday = OnlineIsTodayEligibleForMonthClaim(row)
		items, daysInMonth, monthKey = MonthBuildRewards(identifier, row)
		vipItems = select(1, MonthBuildVipRewards(identifier, row))
		hasVipPack = RewardRandom.HasVipPack(row, monthKey)
		streak = DailyStreak.BuildPayload(row, todayReward or calendar.todayDay)
		monthFreeDays = OnlineBuildMonthFreeDays(row)
		local assignments = RewardRandom.LoadAssignments(row)
		local bucket = assignments[monthKey] or {}
		missedClaimsCount = tonumber(bucket.missed_claims_count) or 0
	else
		streak = DailyStreak.BuildPayload(nil, todayReward or calendar.todayDay)
	end

	return {
		playerData = row or {
			usual = json.encode({}),
			collected = json.encode({}),
			daily_online = json.encode({}),
			month_assignments = json.encode({}),
		},
		todayReward = todayReward,
		tomorrowDate = tomorrowReward,
		onlineMinutes = onlineMinutes,
		presentToday = presentToday,
		items = items,
		vipItems = vipItems,
		hasVipPack = hasVipPack,
		vipPackPrice = getVipPackPrice(),
		missedDayClaimEnabled = missedCfg.enabled,
		missedDayClaimPrice = MissedPrice.ForIndex(missedCfg.price, missedCfg.multiplier, missedClaimsCount),
		missedDayClaimBasePrice = missedCfg.price,
		missedDayClaimMultiplier = missedCfg.multiplier,
		missedDayClaimMoneyType = missedCfg.moneyType,
		missedClaimPricePreview = MissedPrice.Preview(missedCfg.price, missedCfg.multiplier, missedCfg.maxClaimsPerMonth),
		monthKey = monthKey,
		daysInMonth = daysInMonth,
		calendarYear = calendar.year,
		calendarMonth = calendar.month,
		monthCollected = MonthFilterProgress(collectedRaw, calendar.monthKey),
		vipMonthCollected = MonthFilterVipProgress(collectedRaw, calendar.monthKey),
		monthEligibleDays = row and identifier and OnlineBuildMonthEligibleDays(row) or {},
		monthFreeDays = monthFreeDays,
		missedClaimsCount = missedClaimsCount,
		maxMissedClaimsPerMonth = missedCfg.maxClaimsPerMonth,
		streak = streak,
	}
end

local claimLocks = {}

local function claimMonthReward(src, day, track)
	local player = FrameworkGetPlayer(src)
	local identifier = FrameworkGetIdentifier(player)
	if not identifier then return false, 'no_player' end
	if claimLocks[identifier] then return false, 'busy' end
	claimLocks[identifier] = true

	local function finish(...)
		claimLocks[identifier] = nil
		return ...
	end

	local row = ensurePlayerRow(identifier)
	if not row then return finish(false, 'no_row') end

	local dayNum = tonumber(day)
	if not dayNum or dayNum < 1 or dayNum > todayReward then return finish(false, 'bad_day') end

	local isVip = track == 'vip'
	if isVip and not RewardRandom.HasVipPack(row) then
		return finish(false, 'need_vip_pack')
	end

	local isMissed = dayNum < todayReward
	local missedCfg = getMissedDayClaimConfig()
	local paidAmount = 0
	local incrementMissedCount = false
	local wasOnline = false

	if dayNum == todayReward then
		if not OnlineIsTodayEligibleForMonthClaim(row) then return finish(false, 'not_eligible') end
	elseif isMissed then
		wasOnline = OnlineIsPastDayEligibleForMonthClaim(row, dayNum)
		if wasOnline then
			-- Free claim because they were online
			paidAmount = 0
		else
			if missedCfg.enabled then
				local calendar = MonthGetCalendarInfo()
				local assignments = RewardRandom.LoadAssignments(row)
				local bucket = assignments[calendar.monthKey] or {}
				local missedClaimsCount = tonumber(bucket.missed_claims_count) or 0
				local maxAllowed = tonumber(missedCfg.maxClaimsPerMonth) or 0
				if maxAllowed > 0 and missedClaimsCount >= maxAllowed then
					return finish(false, 'max_missed_claims_reached', { maxAllowed = maxAllowed })
				end

				local chargePrice = MissedPrice.ForIndex(missedCfg.price, missedCfg.multiplier, missedClaimsCount)
				if chargePrice > 0 then
					local okPay = FrameworkRemoveMoney(src, player, chargePrice, missedCfg.moneyType, 'tipi-daily-missed-claim')
					if not okPay then
						return finish(false, 'not_enough_money', { price = chargePrice, moneyType = missedCfg.moneyType })
					end
					paidAmount = chargePrice
				end
				incrementMissedCount = true
			else
				return finish(false, 'not_eligible')
			end
		end
	else
		return finish(false, 'bad_day')
	end

	local dayKey = isVip and MonthGetVipDayKey(dayNum) or MonthGetDayKey(dayNum)
	local collected = decodeJson(row.collected, {})
	if collected[dayKey] then return finish(false, 'already_claimed') end

	local reward = isVip
		and RewardRandom.GetVipDayReward(identifier, row, dayNum)
		or RewardRandom.GetDayReward(identifier, row, dayNum)
	if not reward then return finish(false, 'no_reward') end

	collected[dayKey] = true
	ExecuteSql('UPDATE tipi_daily_rewards SET collected = ? WHERE citizenid = ?', { json.encode(collected), identifier })

	if incrementMissedCount then
		local calendar = MonthGetCalendarInfo()
		local assignments = RewardRandom.LoadAssignments(row)
		assignments[calendar.monthKey] = assignments[calendar.monthKey] or {}
		assignments[calendar.monthKey].missed_claims_count = (assignments[calendar.monthKey].missed_claims_count or 0) + 1
		RewardRandom.SaveAssignments(identifier, assignments)
	end

	grantConfiguredReward(src, player, identifier, reward)

	local streakPayload = nil
	local updatedMissedClaimsCount = 0

	if not isVip then
		-- Re-fetch row từ DB để đảm bảo streak luôn được tính từ dữ liệu persisted (collected đã được UPDATE)
		row = ensurePlayerRow(identifier)
		streakPayload = DailyStreak.BuildPayload(row, todayReward)

		if isMissed then
			local calendar = MonthGetCalendarInfo()
			local assignments = RewardRandom.LoadAssignments(row)
			updatedMissedClaimsCount = assignments[calendar.monthKey] and assignments[calendar.monthKey].missed_claims_count or 0
		end
	end

	return finish(true, reward, {
		paid = paidAmount,
		missed = isMissed,
		isFreeClaim = isMissed and wasOnline,
		missedClaimsCount = updatedMissedClaimsCount,
		nextMissedClaimPrice = MissedPrice.ForIndex(missedCfg.price, missedCfg.multiplier, updatedMissedClaimsCount),
		missedDayClaimBasePrice = missedCfg.price,
		missedDayClaimMultiplier = missedCfg.multiplier,
		streak = streakPayload,
	})
end

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:ClaimDailyReward', function(source, cb, day, track)
	local ok, rewardOrErr, meta = claimMonthReward(source, day, track == 'vip' and 'vip' or 'normal')
	if not ok then
		cb({
			ok = false,
			error = type(rewardOrErr) == 'string' and rewardOrErr or 'claim_failed',
			price = meta and meta.price,
			moneyType = meta and meta.moneyType,
			maxAllowed = meta and meta.maxAllowed,
		})
		return
	end
	cb({
		ok = true,
		reward = rewardOrErr,
		paid = meta and meta.paid or 0,
		missed = meta and meta.missed == true,
		isFreeClaim = meta and meta.isFreeClaim == true,
		missedClaimsCount = meta and meta.missedClaimsCount or 0,
		nextMissedClaimPrice = meta and meta.nextMissedClaimPrice,
		missedDayClaimBasePrice = meta and meta.missedDayClaimBasePrice,
		missedDayClaimMultiplier = meta and meta.missedDayClaimMultiplier,
		streak = meta and meta.streak,
	})
end)

-- Giữ event cũ (menu/legacy) — vẫn trừ tiền nếu nhận bù
RegisterNetEvent('Tipi_Daily_Rewards:Server:ClaimDailyReward', function(day, track)
	claimMonthReward(source, day, track == 'vip' and 'vip' or 'normal')
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:ClaimStreak', function(source, cb, days)
	local player = FrameworkGetPlayer(source)
	local identifier = FrameworkGetIdentifier(player)
	if not identifier then
		cb({ ok = false, error = 'no_player' })
		return
	end
	local row = ensurePlayerRow(identifier)
	if not row then
		cb({ ok = false, error = 'no_row' })
		return
	end
	local ok, rewardOrErr, streakPayload = DailyStreak.Claim(source, player, identifier, row, days)
	if not ok then
		cb({ ok = false, error = rewardOrErr })
		return
	end
	cb({ ok = true, reward = rewardOrErr, streak = streakPayload })
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:BuyVipPack', function(source, cb)
	local player = FrameworkGetPlayer(source)
	local identifier = FrameworkGetIdentifier(player)
	if not identifier then
		cb({ ok = false, error = 'no_player' })
		return
	end

	local row = ensurePlayerRow(identifier)
	if not row then
		cb({ ok = false, error = 'no_row' })
		return
	end

	local calendar = MonthGetCalendarInfo()
	if RewardRandom.HasVipPack(row, calendar.monthKey) then
		cb({ ok = false, error = 'already_owned', hasVipPack = true })
		return
	end

	local price = getVipPackPrice()
	local coin = getPlayerCoin(identifier)
	if coin < price then
		cb({ ok = false, error = 'not_enough_coin', coin = coin, price = price })
		return
	end

	setPlayerCoin(identifier, coin - price, source)
	RewardRandom.MarkVipPackPurchased(identifier, row, calendar.monthKey)

	row = ensurePlayerRow(identifier)
	cb({
		ok = true,
		hasVipPack = true,
		vipPackPrice = price,
		coin = coin - price,
		monthKey = calendar.monthKey,
		vipItems = select(1, MonthBuildVipRewards(identifier, row)),
		vipMonthCollected = MonthFilterVipProgress(decodeJson(row.collected, {}), calendar.monthKey),
	})
end)

local function buildOnlineProgressPayload(row, identifier)
	local calendar = MonthGetCalendarInfo()
	return {
		onlineMinutes = identifier and OnlineGetMinutes(identifier, row) or 0,
		todayReward = todayReward or calendar.todayDay,
		presentToday = row and OnlineIsTodayEligibleForMonthClaim(row) or false,
		monthEligibleDays = row and OnlineBuildMonthEligibleDays(row) or {},
		hasVipPack = row and RewardRandom.HasVipPack(row, calendar.monthKey) or false,
		vipPackPrice = getVipPackPrice(),
		streak = DailyStreak.BuildPayload(row, todayReward or calendar.todayDay),
	}
end

local function buildSummaryData(row, identifier)
	local calendar = MonthGetCalendarInfo()
	local collectedRaw = decodeJson(row and row.collected or '{}', {})
	local monthCollected = MonthFilterProgress(collectedRaw, calendar.monthKey)
	local checkedCount = 0
	for _, claimed in pairs(monthCollected) do
		if claimed then
			checkedCount = checkedCount + 1
		end
	end

	local today = todayReward or calendar.todayDay
	local todayKey = tostring(today)
	local eligibleToday = row and OnlineIsTodayEligibleForMonthClaim(row) or false
	local claimedToday = monthCollected[todayKey] == true

	return {
		checkedCount = checkedCount,
		daysInMonth = calendar.daysInMonth,
		onlineMinutes = identifier and OnlineGetMinutes(identifier, row) or 0,
		presentToday = eligibleToday,
		todayReward = today,
		canClaimToday = eligibleToday and not claimedToday,
		hasVipPack = row and RewardRandom.HasVipPack(row, calendar.monthKey) or false,
		vipPackPrice = getVipPackPrice(),
	}
end

DailyOnline = DailyOnline or {}

function DailyOnline.PushSync(src, identifier)
	if not src or not identifier then return end
	local row = ensurePlayerRow(identifier)
	if not row then return end
	TriggerClientEvent('Tipi_Daily_Rewards:Client:SyncOnline', src, buildOnlineProgressPayload(row, identifier))
end

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:GetPlayerForDailyRewards', function(source, cb)
	local player = FrameworkGetPlayer(source)
	local identifier = FrameworkGetIdentifier(player)
	if not identifier then
		cb(buildCallbackData(nil, nil))
		return
	end
	local row = ensurePlayerRow(identifier)
	cb(buildCallbackData(row, identifier))
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:GetSummary', function(source, cb)
	local player = FrameworkGetPlayer(source)
	local identifier = FrameworkGetIdentifier(player)
	if not identifier then
		cb(buildSummaryData(nil, nil))
		return
	end
	local row = ensurePlayerRow(identifier)
	cb(buildSummaryData(row, identifier))
end)

FrameworkCreateCallback('Tipi_Daily_Rewards:Callback:GetOnlineProgress', function(source, cb)
	local player = FrameworkGetPlayer(source)
	local identifier = FrameworkGetIdentifier(player)
	if not identifier then
		cb({
			onlineMinutes = 0,
			presentToday = false,
			monthEligibleDays = {},
			hasVipPack = false,
		})
		return
	end
	local row = ensurePlayerRow(identifier)
	cb(buildOnlineProgressPayload(row, identifier))
end)

CreateThread(function()
	refreshTodayState()
	while true do
		refreshTodayState()
		Wait(30000)
	end
end)

if Config.ItemNeed.bool then
	FrameworkCreateUseableItem(Config.ItemNeed.itemcode, function(source)
		TriggerClientEvent('Tipi_Daily_Rewards:OpenMenu', source)
	end)
end
