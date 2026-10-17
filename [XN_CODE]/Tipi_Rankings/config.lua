
Config = {}

Config.Dependencies = {}
Config.Locale = 'vi'

Config.Settings = {
	locale = Locales[Config.Locale] or Locales['default'],
}

Config.EnableModules = {
	['Main'] = {
		enabled = true,
		client = true,
		priority = 2,
	},
}

Config.Debug = false
Config.Nui = true
Config.Dev = false
---@type 'esx' | 'qb' | 'qbx'
Config.Framework = 'qbx'
Config.ClientLazyLoad = false
Config.OpenCommand = 'bxh'
Config.EnableUiSound = true
Config.CacheTTL = 90
Config.CacheVersion = 3
Config.DefaultLimit = 10

Config.Branding = {
	seasonTagline = 'UnderStars',
	logoUrl = 'https://r2.fivemanage.com/NDMhm0dqVgoz51MxrSmBn/logo_PNG.png',
	discordUsername = 'Ban Quản Trị',
}


Config.SellitemCategoryCount = 5
Config.SellitemBoards = {
	{ key = 'vuanghe', label = '👑 Vua Nghề', description = 'Điểm trung bình từ 5 nghề bán hàng', order = 1 },
	{ key = 'fish', label = '🐟 Hải Sản', description = 'Top doanh thu bán hải sản', order = 2 },
	{ key = 'phelieu', label = '🔩 Phế Liệu', description = 'Top doanh thu bán phế liệu', order = 3 },
	{ key = 'mining', label = '⛏️ Khoáng Sản', description = 'Top doanh thu bán khoáng sản', order = 4 },
	{ key = 'nuoithu', label = '🐄 Nuôi Thú', description = 'Top doanh thu bán thú', order = 5 },
	{ key = 'traicay', label = '🍊 Nông Nghiệp', description = 'Top doanh thu bán nông sản', order = 6 },
	{ key = 'xaydung', label = '⛏️ Xây dựng', description = 'Top doanh thu nghề xây dựng', order = 7 },
	{ key = 'duaxe', label = '🚗 Đua Xe', description = 'Top doanh thu bán đua xe', order = 7 },
}

Config.CustomBoards = {
	-- Ví dụ:
	-- ['fish'] = {
	-- 	id = 'fish',
	-- 	label = '💎 Top Donate',
	-- 	description = 'Người donate nhiều nhất',
	-- 	icon = 'trophy',
	-- 	theme = 'player',
	-- 	order = 10,
	-- 	enabled = true,
	-- 	limit = Config.DefaultLimit,
	-- 	entryType = 'player',
	-- 	valueLabel = 'VNĐ',
	-- 	invalidateOnEvents = { 'Tipi_menu:donateUpdated' },
	-- 	resolveOffList = true,
	-- 	playerOffList = {
	-- 		lookup = 'SELECT total AS value, name AS label FROM donate_log WHERE citizen_id = ? LIMIT 1',
	-- 		rank = 'SELECT COUNT(*) + 1 FROM donate_log WHERE total > ?',
	-- 		minValue = 1,
	-- 	},
	-- 	dataSource = {
	-- 		type = 'sql',
	-- 		query = [[
	-- 			SELECT citizen_id AS name, name AS label, 0 AS level, total AS sort_value
	-- 			FROM donate_log WHERE total > 0
	-- 			ORDER BY total DESC, name ASC LIMIT ?
	-- 		]],
	-- 	},
	-- },
}



local function sellitemBoardId(categoryKey)
	return 'sellitem_' .. categoryKey
end

local function categoryLeaderboardQuery(categoryKey)
	return ([[
		SELECT citizen_id AS name, player_name AS label, 0 AS level, points AS sort_value
		FROM xn_sellitem_leaderboard
		WHERE category = '%s' AND points > 0
		ORDER BY points DESC, player_name ASC
		LIMIT ?
	]]):format(categoryKey)
end

local function categoryOffListLookup(categoryKey)
	return ([[
		SELECT points AS value, player_name AS label
		FROM xn_sellitem_leaderboard
		WHERE citizen_id = ? AND category = '%s'
		LIMIT 1
	]]):format(categoryKey)
end


local function categoryOffListRank(categoryKey)
	return ([[
		SELECT COUNT(*) + 1
		FROM xn_sellitem_leaderboard
		WHERE category = '%s' AND points > ?
	]]):format(categoryKey)
end

local function vuangheLeaderboardQuery()
	return ([[
		SELECT citizen_id AS name, player_name AS label, 0 AS level,
			ROUND(SUM(points) / %d) AS sort_value
		FROM xn_sellitem_leaderboard
		GROUP BY citizen_id, player_name
		HAVING SUM(points) > 0
		ORDER BY sort_value DESC, player_name ASC
		LIMIT ?
	]]):format(Config.SellitemCategoryCount)
end

local function buildSellitemBoard(cat)
	local boardId = sellitemBoardId(cat.key)
	local isVuanghe = cat.key == 'vuanghe'

	return boardId, {
		id = boardId,
		label = cat.label,
		description = cat.description,
		icon = 'trophy',
		theme = 'player',
		order = cat.order,
		enabled = true,
		limit = Config.DefaultLimit,
		entryType = 'player',
		valueLabel = 'Điểm',
		invalidateOnEvents = { 'xn-sellitem:leaderboardUpdated' },
		resolveOffList = true,
		playerOffList = isVuanghe and {
			lookup = [[
				SELECT ROUND(SUM(points) / ]] .. Config.SellitemCategoryCount .. [[) AS value, player_name AS label
				FROM xn_sellitem_leaderboard WHERE citizen_id = ?
				GROUP BY citizen_id, player_name LIMIT 1
			]],
			rank = [[
				SELECT COUNT(*) + 1 FROM (
					SELECT ROUND(SUM(points) / ]] .. Config.SellitemCategoryCount .. [[) AS pts
					FROM xn_sellitem_leaderboard
					GROUP BY citizen_id, player_name HAVING SUM(points) > 0
				) ranked WHERE pts > ?
			]],
			minValue = 1,
		} or {
			lookup = categoryOffListLookup(cat.key),
			rank = categoryOffListRank(cat.key),
			minValue = 1,
		},
		dataSource = {
			type = 'sql',
			query = isVuanghe and vuangheLeaderboardQuery() or categoryLeaderboardQuery(cat.key),
		},
	}
end

Config.Boards = {}

for _, cat in ipairs(Config.SellitemBoards) do
	local boardId, board = buildSellitemBoard(cat)
	Config.Boards[boardId] = board
end

for boardId, board in pairs(Config.CustomBoards) do
	if board.enabled ~= false then
		Config.Boards[boardId] = board
		Config.Boards[boardId].id = board.id or boardId
	end
end

function Config.GetPlayerCitizenId(source)
	if Config.Framework == 'qbx' then
		local player = exports.qbx_core:GetPlayer(source)
		return player and player.PlayerData.citizenid or nil
	end

	if Config.Framework == 'qb' then
		local QBCore = exports['qb-core']:GetCoreObject()
		local player = QBCore.Functions.GetPlayer(source)
		return player and player.PlayerData.citizenid or nil
	end

	if Config.Framework == 'esx' and Framework and Framework.GetPlayerFromId then
		local xPlayer = Framework.GetPlayerFromId(source)
		return xPlayer and xPlayer.identifier or nil
	end

	return nil
end

function Config.GetPlayerEntryKey(source, boardId)
	local board = Config.Boards[boardId]
	if not board then return nil end

	if board.entryType == 'player' then
		return Config.GetPlayerCitizenId(source)
	end

	return nil
end

function L(key, ...)
	if Config.Settings.locale[key] then
		return string.format(Config.Settings.locale[key], ...)
	end
	return key
end
