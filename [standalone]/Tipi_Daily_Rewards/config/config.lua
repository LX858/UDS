Config = Config or {}
Locales = Locales or {}

Config.Framework = 'qbx' -- auto | qbx | qb | esx
Config.Locales = 'VI'
Config.SQLScript = 'oxmysql'
Config.MoneyType = 'cash'

Config.MonthClaimMinMinutes = 1

Config.MissedDayClaim = {
	enabled = true,
	price = 5000,
	multiplier = 1.2,
	moneyType = 'cash',
	maxClaimsPerMonth = 5,
}

Config.MysteryRewardImage = ''
Config.InventoryImageTemplate = 'nui://ox_inventory/web/images/%s.webp'
Config.InventoryImageCdn = 'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp'
Config.ClothingImageUrl = 'https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main'
Config.ClothingImageExt = 'webp'

Config.DefaultNormalDays = {
	[1]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[2]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[3]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[4]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[5]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[6]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[7]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[8]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[9]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[10] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[11] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[12] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[13] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[14] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[15] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[16] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[17] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[18] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[19] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[20] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[21] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[22] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[23] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[24] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[25] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[26] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[27] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[28] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[29] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[30] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[31] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
}

Config.DefaultVipDays = {
	[1]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[2]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[3]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[4]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[5]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[6]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[7]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[8]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[9]  = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[10] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[11] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[12] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[13] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[14] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[15] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[16] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[17] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[18] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[19] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[20] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[21] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[22] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[23] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[24] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[25] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[26] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[27] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[28] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[29] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[30] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
	[31] = { itemType = 'item',itemName = 'money', itemLabel = '$1', itemCount = 1 },
}

Config.StreakMilestones = {
	{ days = 3, reward = { itemName = 'cola', itemLabel = 'coca-cola', itemCount = 5, itemType = 'item' } },
	{ days = 7, reward = { itemName = 'cigarette', itemLabel = 'Thuốc lá', itemCount = 3, itemType = 'item' } },
	{ days = 14, reward = { itemName = 'com_ga', itemLabel = 'cơm gà', itemCount = 10, itemType = 'item' } },
	{ days = 30, reward = { itemName = 'cola', itemLabel = 'coca-cola', itemCount = 20, itemType = 'item' } },
}

Config.VipMonthPack = {
	price = 99,
	table = 'players',
	idColumn = 'citizenid',
	column = 'coin',
}

Config.Admin = {
	command = 'admindaily',
	description = 'Mở bảng quản trị điểm danh ngày',
	permission = 'group.admin',
}

Config.ItemNeed = {
	bool = false,
	itemcode = 'bandage',
}

Config.Command = {
	['Name'] = 'dailyrewards',
	['Description'] = 'Tipi Daily Rewards',
}

function Config.Hud(bool)
	if bool then
		TriggerEvent('ShowHud')
	else
		TriggerEvent('HideHud')
	end
end
