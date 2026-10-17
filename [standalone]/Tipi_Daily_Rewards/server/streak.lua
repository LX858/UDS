DailyStreak = DailyStreak or {}

function DailyStreak.GetClaimKey(days)
	return ('streak#%d'):format(math.floor(tonumber(days) or 0))
end

function DailyStreak.LoadClaimed(collected)
	local claimed = {}
	if type(collected) ~= 'table' then return claimed end
	for key, value in pairs(collected) do
		if value and type(key) == 'string' then
			local days = key:match('^streak#(%d+)$')
			if days then
				claimed[tostring(tonumber(days))] = true
			end
		end
	end
	return claimed
end

--- Tổng số ngày đã điểm danh trong tháng (đếm tất cả, kể cả ngắt quãng) — dùng cho streak milestones.
function DailyStreak.ComputeCurrent(row, todayDay)
	todayDay = math.floor(tonumber(todayDay) or Month.GetTodayDay())
	local collected = decodeJson(row and row.collected, {})
	local streak = 0

	for day = 1, todayDay do
		local dayKey = Month.GetDayKey(day)
		if collected[dayKey] then
			streak = streak + 1
		end
	end

	return streak
end

function DailyStreak.BuildPayload(row, todayDay)
	local streaks = DailyCatalog.GetStreaks()
	local collected = decodeJson(row and row.collected, {})
	local claimed = DailyStreak.LoadClaimed(collected)
	local current = DailyStreak.ComputeCurrent(row, todayDay)
	local list = {}

	for _, milestone in ipairs(streaks.milestones or {}) do
		local key = tostring(milestone.days)
		local isClaimed = claimed[key] == true
		local ready = (not isClaimed) and current >= milestone.days
		list[#list + 1] = {
			days = milestone.days,
			reward = milestone.reward,
			claimed = isClaimed,
			ready = ready,
		}
	end

	return {
		current = current,
		milestones = list,
		fromTemplate = streaks.fromTemplate == true,
	}
end

function DailyStreak.Claim(src, player, identifier, row, days)
	local target = math.floor(tonumber(days) or 0)
	if target < 1 then return false, 'invalid_days' end

	local streaks = DailyCatalog.GetStreaks()
	local milestone = nil
	for _, rowMilestone in ipairs(streaks.milestones or {}) do
		if rowMilestone.days == target then
			milestone = rowMilestone
			break
		end
	end
	if not milestone then return false, 'unknown_milestone' end

	local collected = decodeJson(row.collected, {})
	local claimKey = DailyStreak.GetClaimKey(target)
	if collected[claimKey] then return false, 'already_claimed' end

	local current = DailyStreak.ComputeCurrent(row, Month.GetTodayDay())
	if current < target then return false, 'not_ready' end

	collected[claimKey] = true
	ExecuteSql('UPDATE tipi_daily_rewards SET collected = ? WHERE citizenid = ?', { json.encode(collected), identifier })

	if milestone.reward then
		local reward = milestone.reward
		if ItemsHelper.IsMoneyType(reward.itemType) then
			FrameworkAddMoney(src, player, reward.itemCount)
		elseif reward.itemType == 'clothing' then
			if GetResourceState('XNClothes') == 'started' then
				local component = reward.clothComponent or reward.itemName
				local drawable = math.max(1, math.floor(tonumber(reward.clothDrawable) or 1))
				local texture = math.max(1, math.floor(tonumber(reward.clothTexture) or 1))
				local sex = reward.clothSex
				if sex ~= 'male' and sex ~= 'female' then sex = nil end
				local count = math.max(1, math.floor(tonumber(reward.itemCount) or 1))
				for _ = 1, count do
					exports['XNClothes']:GiveClothingItem(src, component, drawable, texture, 0, sex)
				end
			end
		elseif reward.itemType == 'item' then
			FrameworkAddItem(src, player, reward.itemName, reward.itemCount)
		end
	end

	return true, milestone.reward, DailyStreak.BuildPayload({ collected = json.encode(collected) }, Month.GetTodayDay())
end
