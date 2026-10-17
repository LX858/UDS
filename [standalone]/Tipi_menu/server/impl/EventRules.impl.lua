---@class SVEventRulesImpl : Impl
local Impl = NewImpl("EventRules")

local CARD_KEY_PATTERN = '^[%w_-]+$'

local function toBoolFlag(value, default)
	if value == nil then return default == true end
	if value == true or value == 1 or value == '1' or value == 'true' then return true end
	if value == false or value == 0 or value == '0' or value == 'false' then return false end
	return (tonumber(value) or 0) == 1
end

local DEFAULT_ADMIN_ACES = {
	'group.admin',
	'group.god',
	'admin',
	'god',
	'command',
}

local function hasAnyAce(source, aces)
	local seen = {}
	for _, ace in ipairs(aces) do
		if type(ace) == 'string' and ace ~= '' and not seen[ace] then
			seen[ace] = true
			if IsPlayerAceAllowed(source, ace) then
				return true
			end
		end
	end
	return false
end

local function isLicenseWhitelisted(source)
	local cfg = Config.EventCards and Config.EventCards.adminLicenses
	if type(cfg) ~= 'table' or #cfg == 0 then return false end

	for i = 0, GetNumPlayerIdentifiers(source) - 1 do
		local identifier = GetPlayerIdentifier(source, i)
		if identifier then
			for _, allowed in ipairs(cfg) do
				if identifier == allowed then
					return true
				end
			end
		end
	end

	return false
end

local function isAdmin(source)
	if source == 0 then return true end
	if isLicenseWhitelisted(source) then return true end

	local aces = {}
	local cfg = Config.EventCards
	if cfg then
		if type(cfg.adminAces) == 'table' then
			for _, ace in ipairs(cfg.adminAces) do
				aces[#aces + 1] = ace
			end
		elseif type(cfg.adminAce) == 'string' and cfg.adminAce ~= '' then
			aces[#aces + 1] = cfg.adminAce
		end
	end
	for _, ace in ipairs(DEFAULT_ADMIN_ACES) do
		aces[#aces + 1] = ace
	end

	if hasAnyAce(source, aces) then return true end

	if GetResourceState('qbx_core') == 'started' then
		local ok, perms = pcall(function()
			return exports.qbx_core:GetPermission(source)
		end)
		if ok and type(perms) == 'table' then
			for _, allowed in pairs(perms) do
				if allowed then return true end
			end
		end

		local ok2, allowed = pcall(function()
			return exports.qbx_core:HasPermission(source, { 'admin', 'god', 'mod' })
		end)
		if ok2 and allowed then return true end
	end

	if GetResourceState('qb-core') == 'started' then
		local ok, allowed = pcall(function()
			local QBCore = exports['qb-core']:GetCoreObject()
			return QBCore.Functions.HasPermission(source, { 'admin', 'god', 'mod' })
		end)
		if ok and allowed then return true end
	end

	return false
end

local function notifySource(source, message, notifyType)
	if source == 0 then
		print(('[Tipi_menu] %s'):format(message))
		return
	end
	local player = GetPlayerFromId(source)
	if player then
		Notify(player, message, notifyType or 'error')
	else
		TriggerClientEvent('ox_lib:notify', source, {
			title = 'Tipi_menu',
			description = message,
			type = notifyType or 'error',
		})
	end
end

local function getDefaultCards()
	local cfg = Config.EventCards and Config.EventCards.defaults or {}
	local cards = {}
	for index, item in ipairs(cfg) do
		if type(item) == 'table' and item.key then
			cards[#cards + 1] = {
				card_key = item.key,
				label = item.label or item.key,
				description = item.description or '',
				event_time = item.event_time or '',
				image_url = item.image_url or '',
				background_url = item.background_url or '',
				rules_content = item.rules_content or '',
				action = item.action or '',
				enabled = item.enabled and 1 or 0,
				show_join_button = item.show_join_button and 1 or 0,
				join_export = item.join_export or '',
				sort_order = tonumber(item.sort_order) or index,
			}
		end
	end
	return cards
end

local function resolveBackgroundUrl(cardKey, backgroundUrl)
	if backgroundUrl and backgroundUrl ~= '' then
		return backgroundUrl
	end

	local cfg = Config.EventCards
	if cfg and cfg.defaults then
		for _, item in ipairs(cfg.defaults) do
			if item.key == cardKey and item.background_url and item.background_url ~= '' then
				return item.background_url
			end
		end
	end

	return (cfg and cfg.fallbackBackground) or ''
end

local function rowToCard(row)
	if not row then return nil end
	return {
		cardKey = row.card_key,
		label = row.label or row.card_key,
		description = row.description or '',
		eventTime = row.event_time or '',
		imageUrl = row.image_url or '',
		backgroundUrl = resolveBackgroundUrl(row.card_key, row.background_url or ''),
		rulesContent = row.rules_content or '',
		action = row.action or '',
		enabled = toBoolFlag(row.enabled, true),
		showJoinButton = toBoolFlag(row.show_join_button, false),
		joinExport = row.join_export or '',
		sortOrder = tonumber(row.sort_order) or 0,
	}
end

local function fetchAllRows()
	return MySQL.query.await([[
		SELECT card_key, label, description, event_time, image_url, background_url, rules_content, action, enabled, show_join_button, join_export, sort_order
		FROM event_cards
		ORDER BY sort_order ASC, card_key ASC
	]]) or {}
end

local cachedCardsPayload = nil

local function invalidateCardsCache()
	cachedCardsPayload = nil
end

local function fetchCardsPayload(forceRefresh)
	if cachedCardsPayload and not forceRefresh then
		return cachedCardsPayload
	end
	local rows = fetchAllRows()
	local cards = {}
	for _, row in ipairs(rows) do
		local card = rowToCard(row)
		if card then
			cards[#cards + 1] = card
		end
	end
	cachedCardsPayload = cards
	return cards
end

local function ensureSchema()
	MySQL.query([[
		CREATE TABLE IF NOT EXISTS `event_cards` (
			`card_key` VARCHAR(64) NOT NULL,
			`label` VARCHAR(128) NOT NULL DEFAULT '',
			`description` VARCHAR(512) NOT NULL DEFAULT '',
			`event_time` VARCHAR(128) NOT NULL DEFAULT '',
			`image_url` VARCHAR(512) NOT NULL DEFAULT '',
			`background_url` VARCHAR(512) NOT NULL DEFAULT '',
			`rules_content` TEXT NOT NULL,
			`action` VARCHAR(64) NOT NULL DEFAULT '',
			`enabled` TINYINT(1) NOT NULL DEFAULT 1,
			`show_join_button` TINYINT(1) NOT NULL DEFAULT 0,
			`join_export` VARCHAR(128) NOT NULL DEFAULT '',
			`sort_order` INT(11) NOT NULL DEFAULT 0,
			`updated_by` VARCHAR(64) DEFAULT NULL,
			`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`card_key`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
	]])

	pcall(function()
		MySQL.query.await([[
			INSERT INTO event_cards (card_key, label, description, image_url, background_url, rules_content, action, enabled, sort_order)
			SELECT er.card_key, er.card_key, '', '', '', er.content, '', 1, 0
			FROM event_rules er
			WHERE NOT EXISTS (
				SELECT 1 FROM event_cards ec WHERE ec.card_key = er.card_key
			)
		]])
	end)

	pcall(function()
		MySQL.query.await('ALTER TABLE event_cards ADD COLUMN show_join_button TINYINT(1) NOT NULL DEFAULT 0')
	end)
	pcall(function()
		MySQL.query.await('ALTER TABLE event_cards ADD COLUMN join_export VARCHAR(128) NOT NULL DEFAULT ""')
	end)
	pcall(function()
		MySQL.query.await('ALTER TABLE event_cards ADD COLUMN event_time VARCHAR(128) NOT NULL DEFAULT "" AFTER description')
	end)
end

local function ensureDefaults()
	local defaults = getDefaultCards()
	for _, item in ipairs(defaults) do
		local existing = MySQL.scalar.await('SELECT card_key FROM event_cards WHERE card_key = ? LIMIT 1', { item.card_key })
		if not existing then
			MySQL.insert.await([[
				INSERT INTO event_cards
					(card_key, label, description, event_time, image_url, background_url, rules_content, action, enabled, show_join_button, join_export, sort_order)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			]], {
				item.card_key,
				item.label,
				item.description,
				item.event_time,
				item.image_url,
				item.background_url,
				item.rules_content,
				item.action,
				item.enabled,
				item.show_join_button,
				item.join_export,
				item.sort_order,
			})
		end
	end
end

local function validateCardKey(cardKey)
	return type(cardKey) == 'string' and cardKey:match(CARD_KEY_PATTERN) ~= nil
end

local function parseJoinExport(exportStr)
	if type(exportStr) ~= 'string' or exportStr == '' then return nil end
	local resource, exportName = exportStr:match('^([^%.:]+)[%.:]([%w_%-]+)$')
	if not resource or not exportName then return nil end
	return resource, exportName
end

local function invokeJoinExport(source, exportStr, cardKey)
	local resource, exportName = parseJoinExport(exportStr)
	if not resource or not exportName then
		return false, 'invalid_export'
	end

	local ok, result = pcall(function()
		return exports[resource][exportName](source, cardKey)
	end)

	if not ok then
		return false, result
	end

	return true, result
end

local function normalizeCardPayload(payload)
	if type(payload) ~= 'table' then return nil end
	local cardKey = payload.cardKey or payload.card_key
	if not validateCardKey(cardKey) then return nil end

	return {
		card_key = cardKey,
		label = tostring(payload.label or cardKey):sub(1, 128),
		description = tostring(payload.description or ''):sub(1, 512),
		event_time = tostring(payload.eventTime or payload.event_time or ''):sub(1, 128),
		image_url = tostring(payload.imageUrl or payload.image_url or ''):sub(1, 512),
		background_url = tostring(payload.backgroundUrl or payload.background_url or ''):sub(1, 512),
		rules_content = tostring(payload.rulesContent or payload.rules_content or ''),
		action = tostring(payload.action or ''):sub(1, 64),
		enabled = toBoolFlag(payload.enabled, true) and 1 or 0,
		show_join_button = toBoolFlag(payload.showJoinButton or payload.show_join_button, false) and 1 or 0,
		join_export = tostring(payload.joinExport or payload.join_export or ''):sub(1, 128),
		sort_order = math.max(0, math.floor(tonumber(payload.sortOrder or payload.sort_order) or 0)),
	}
end

function Impl:Init()
	main:LogInfo("%s initialized", self:GetName())

	CreateThread(function()
		ensureSchema()
		ensureDefaults()
	end)

	lib.callback.register('Tipi_menu:sv:getEventCards', function()
		return { cards = fetchCardsPayload() }
	end)

	lib.callback.register('Tipi_menu:sv:getEventCard', function(_, cardKey)
		if not validateCardKey(cardKey) then
			return { card = nil }
		end
		if cachedCardsPayload then
			for _, card in ipairs(cachedCardsPayload) do
				if card.cardKey == cardKey then
					return { card = card }
				end
			end
		end
		local row = MySQL.single.await([[
			SELECT card_key, label, description, event_time, image_url, background_url, rules_content, action, enabled, show_join_button, join_export, sort_order
			FROM event_cards WHERE card_key = ? LIMIT 1
		]], { cardKey })
		return { card = rowToCard(row) }
	end)

	lib.callback.register('Tipi_menu:sv:getAllEventCards', function(source)
		if not isAdmin(source) then
			return { ok = false, message = 'no_permission', cards = {} }
		end

		local ok, cardsOrErr = pcall(fetchCardsPayload)
		if not ok then
			main:LogError('getAllEventCards failed: %s', tostring(cardsOrErr))
			return { ok = false, message = 'db_error', cards = {} }
		end

		return { ok = true, cards = cardsOrErr }
	end)

	lib.callback.register('Tipi_menu:sv:saveEventCard', function(source, payload)
		if not isAdmin(source) then
			return { ok = false, message = 'no_permission' }
		end

		local card = normalizeCardPayload(payload)
		if not card then
			return { ok = false, message = 'invalid_data' }
		end

		local player = GetPlayerFromId(source)
		local updatedBy = player and player.identifier or ('src:%s'):format(source)

		MySQL.update.await([[
			INSERT INTO event_cards
				(card_key, label, description, event_time, image_url, background_url, rules_content, action, enabled, show_join_button, join_export, sort_order, updated_by)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON DUPLICATE KEY UPDATE
				label = VALUES(label),
				description = VALUES(description),
				event_time = VALUES(event_time),
				image_url = VALUES(image_url),
				background_url = VALUES(background_url),
				rules_content = VALUES(rules_content),
				action = VALUES(action),
				enabled = VALUES(enabled),
				show_join_button = VALUES(show_join_button),
				join_export = VALUES(join_export),
				sort_order = VALUES(sort_order),
				updated_by = VALUES(updated_by)
		]], {
			card.card_key,
			card.label,
			card.description,
			card.event_time,
			card.image_url,
			card.background_url,
			card.rules_content,
			card.action,
			card.enabled,
			card.show_join_button,
			card.join_export,
			card.sort_order,
			updatedBy,
		})

		invalidateCardsCache()

		return {
			ok = true,
			card = {
				cardKey = card.card_key,
				label = card.label,
				description = card.description,
				eventTime = card.event_time,
				imageUrl = card.image_url,
				backgroundUrl = card.background_url,
				rulesContent = card.rules_content,
				action = card.action,
				enabled = card.enabled == 1,
				showJoinButton = card.show_join_button == 1,
				joinExport = card.join_export,
				sortOrder = card.sort_order,
			},
		}
	end)

	lib.callback.register('Tipi_menu:sv:deleteEventCard', function(source, cardKey)
		if not isAdmin(source) then
			return { ok = false, message = 'no_permission' }
		end
		if not validateCardKey(cardKey) then
			return { ok = false, message = 'invalid_data' }
		end

		MySQL.update.await('DELETE FROM event_cards WHERE card_key = ?', { cardKey })
		invalidateCardsCache()
		return { ok = true }
	end)

	lib.callback.register('Tipi_menu:sv:joinEventCard', function(source, cardKey)
		if not validateCardKey(cardKey) then
			return { ok = false, message = 'invalid_data' }
		end

		local row = MySQL.single.await([[
			SELECT card_key, show_join_button, join_export, action
			FROM event_cards WHERE card_key = ? LIMIT 1
		]], { cardKey })

		if not row or not toBoolFlag(row.show_join_button, false) then
			return { ok = false, message = 'join_disabled' }
		end

		local joinExport = row.join_export or ''
		if joinExport ~= '' then
			local ok, err = invokeJoinExport(source, joinExport, cardKey)
			if not ok then
				return { ok = false, message = tostring(err or 'export_failed') }
			end
			return { ok = true }
		end

		return { ok = false, message = 'no_export' }
	end)

	lib.addCommand('thelesukien', {
		help = 'Mở bảng chỉnh sự kiện (admin)',
	}, function(source)
		if not isAdmin(source) then
			notifySource(source, 'Bạn không có quyền sử dụng lệnh /thelesukien', 'error')
			return
		end
		TriggerClientEvent('Tipi_menu:cl:openEventRulesAdmin', source)
	end)
end
