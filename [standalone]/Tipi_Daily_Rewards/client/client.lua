local Opened = false
local AdminOpened = false

local function imagePayload()
	return {
		mysteryImageUrl = Config.MysteryRewardImage,
		inventoryImageTemplate = Config.InventoryImageTemplate,
		inventoryImageCdn = Config.InventoryImageCdn,
		clothingImageUrl = Config.ClothingImageUrl,
		clothingImageExt = Config.ClothingImageExt,
	}
end

local function sendMonthUpdate()
	local calendar = Month.GetCalendarInfo()
	local payload = imagePayload()
	payload.type = 'main'
	payload.bool = 'update'
	payload.locales = Locales[Config.Locales]
	payload.daysInMonth = calendar.daysInMonth
	payload.monthKey = calendar.monthKey
	payload.calendarYear = calendar.year
	payload.calendarMonth = calendar.month
	SendNUIMessage(payload)
end

CreateThread(function()
	FrameworkRegisterPlayerLoaded(function()
		TriggerEvent('Tipi_Daily_Rewards:Client:StartDailyRewards')
	end)
end)

RegisterNUICallback('playClick', function(_, cb)
	PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
	if cb then cb('ok') end
end)

RegisterNUICallback('Close', function(_, cb)
	Config.Hud(true)
	SetNuiFocus(false, false)
	Opened = false
	AdminOpened = false
	if cb then cb('ok') end
end)

RegisterNUICallback('Claimed', function(data, cb)
	local day = type(data) == 'table' and (data.day or data[1]) or data
	local track = type(data) == 'table' and data.track or 'normal'
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:ClaimDailyReward', function(result)
		result = result or { ok = false }
		-- Báo lỗi bằng ox_lib — tuyệt đối không dùng window.alert trong NUI (dễ treo focus)
		if not result.ok and result.error then
			local locale = Locales[Config.Locales] or {}
			local msg = locale['ClaimFailed'] or 'Không nhận được quà'
			if result.error == 'not_enough_money' then
				msg = (locale['MissedDayNeedMoney'] or 'Không đủ tiền để nhận bù ngày (cần %s$)'):format(tostring(result.price or 0))
			elseif result.error == 'max_missed_claims_reached' then
				msg = (locale['MissedLimitReached'] or 'Đã hết lượt nhận bù ngày trong tháng này (tối đa %d lượt)'):format(tonumber(result.maxAllowed) or 0)
			elseif result.error == 'busy' then
				msg = locale['ClaimBusy'] or 'Đang xử lý quà, vui lòng chờ...'
			elseif result.error == 'already_claimed' then
				msg = locale['AlreadyClaimed'] or 'Ngày này đã nhận rồi'
			end
			lib.notify({ title = 'Daily Rewards', description = msg, type = 'error' })
		end
		if cb then cb(result) end
	end, day, track)
end)

RegisterNUICallback('ClaimStreak', function(data, cb)
	local days = type(data) == 'table' and (data.days or data.tier) or data
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:ClaimStreak', function(result)
		if cb then cb(result or { ok = false }) end
	end, tonumber(days))
end)

RegisterNUICallback('BuyVipPack', function(_, cb)
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:BuyVipPack', function(result)
		if result and result.ok then
			SendNUIMessage({ type = 'main', bool = 'vipPackBought', data = result })
		end
		if cb then cb(result or { ok = false }) end
	end)
end)

RegisterNUICallback('RefreshOnline', function(_, cb)
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:GetOnlineProgress', function(data)
		SendNUIMessage({ type = 'main', bool = 'syncOnline', data = data })
		if cb then cb(data) end
	end)
end)

RegisterNUICallback('AdminGet', function(data, cb)
	local monthKey = type(data) == 'table' and data.monthKey or data
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:AdminGet', function(result)
		if cb then cb(result or { ok = false }) end
	end, monthKey)
end)

RegisterNUICallback('AdminSaveMonth', function(data, cb)
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:AdminSaveMonth', function(result)
		if cb then cb(result or { ok = false }) end
	end, data)
end)

RegisterNUICallback('AdminSaveStreaks', function(data, cb)
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:AdminSaveStreaks', function(result)
		if cb then cb(result or { ok = false }) end
	end, data)
end)

RegisterNUICallback('AdminSaveSettings', function(data, cb)
	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:AdminSaveSettings', function(result)
		if cb then cb(result or { ok = false }) end
	end, data)
end)

local function openDailyRewardsMenu()
	if Opened or AdminOpened then return end
	Opened = true

	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:GetPlayerForDailyRewards', function(data)
		Config.Hud(false)
		local payload = imagePayload()
		payload.type = 'main'
		payload.bool = 'open'
		payload.data = data
		payload.items = data.items
		payload.daysInMonth = data.daysInMonth
		payload.monthKey = data.monthKey
		payload.calendarYear = data.calendarYear
		payload.calendarMonth = data.calendarMonth
		payload.locales = Locales[Config.Locales]
		SendNUIMessage(payload)
		SetNuiFocus(true, true)
	end)
end

local function openAdminPanel()
	if Opened then return end
	AdminOpened = false

	FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:AdminGet', function(data)
		if not data or data.ok == false then
			lib.notify({
				title = 'Daily Admin',
				description = (data and data.error == 'no_permission') and 'Không có quyền' or 'Không tải được dữ liệu admin',
				type = 'error',
			})
			return
		end

		AdminOpened = true
		Config.Hud(false)
		local payload = imagePayload()
		payload.type = 'admin'
		payload.bool = 'open'
		payload.data = data
		payload.locales = Locales[Config.Locales]
		SendNUIMessage(payload)
		SetNuiFocus(true, true)
	end, nil)
end

RegisterNetEvent('Tipi_Daily_Rewards:Client:OpenAdminPanel', function()
	openAdminPanel()
end)

RegisterNetEvent('onResourceStart', function(resourceName)
	if GetCurrentResourceName() ~= resourceName then return end
	while GetResourceState(GetCurrentResourceName()) ~= 'started' do Wait(100) end
	TriggerEvent('Tipi_Daily_Rewards:Client:StartDailyRewards')
end)

RegisterNetEvent('Tipi_Daily_Rewards:Client:StartDailyRewards', function()
	sendMonthUpdate()
end)

RegisterNetEvent('Tipi_Daily_Rewards:Client:SyncOnline', function(data)
	SendNUIMessage({ type = 'main', bool = 'syncOnline', data = data })
end)

RegisterNetEvent('Tipi_Daily_Rewards:Client:MonthClaimReady', function(data)
	local minutes = math.max(1, math.floor(tonumber(data and data.minutes) or Config.MonthClaimMinMinutes or 1))
	local locale = Locales[Config.Locales] or ({})

	lib.notify({
		id = 'tipi_daily_month_claim_ready',
		title = locale['Daily'] and (locale['Daily'] .. ' ' .. (locale['Rewards'] or '')) or 'Điểm danh tháng',
		description = locale['MonthClaimReady'] and string.format(locale['MonthClaimReady'], minutes)
			or ('Đã online %d phút — có thể nhận quà điểm danh hôm nay!'):format(minutes),
		type = 'success',
		duration = 6000,
	})

	SendNUIMessage({ type = 'main', bool = 'milestoneHud', minutes = minutes, kind = 'month' })
end)

CreateThread(function()
	while true do
		Wait(Opened and 10000 or 60000)
		if Opened then
			FrameworkTriggerCallback('Tipi_Daily_Rewards:Callback:GetOnlineProgress', function(data)
				SendNUIMessage({ type = 'main', bool = 'syncOnline', data = data })
			end)
		end
	end
end)

if not Config.ItemNeed.bool then
	RegisterCommand(Config.Command.Name, function()
		openDailyRewardsMenu()
	end, false)
	TriggerEvent('chat:addSuggestion', '/' .. Config.Command.Name, Config.Command.Description)
else
	RegisterNetEvent('Tipi_Daily_Rewards:OpenMenu', function()
		openDailyRewardsMenu()
	end)
end

exports('GetUiMeta', function()
	local res = GetCurrentResourceName()
	local mystery = Config.MysteryRewardImage
	if not mystery or mystery == '' then
		mystery = ('nui://%s/web/build/images/common.png'):format(res)
	end
	return {
		locales = Locales[Config.Locales],
		mysteryImageUrl = mystery,
		inventoryImageTemplate = Config.InventoryImageTemplate,
		inventoryImageCdn = Config.InventoryImageCdn,
		itemImageResourceTemplate = ('nui://%s/config/itemimages/%%s.png'):format(res),
		clothingImageUrl = Config.ClothingImageUrl,
		clothingImageExt = Config.ClothingImageExt,
		clothingComponents = ItemsHelper and ItemsHelper.GetClothingComponents and ItemsHelper.GetClothingComponents() or nil,
	}
end)
