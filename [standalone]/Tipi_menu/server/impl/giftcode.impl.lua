---@class SVGiftCodeImpl : Impl
local Impl = NewImpl("GiftCode")

local GC = Config.GiftCode or {}
local COOLDOWN_TIME = GC.CooldownTime or 5000
local MAX_CODE_LENGTH = GC.MaxCodeLength or 100
local MAX_BUNDLE_ITEMS = GC.MaxBundleItems or 20
local ENABLE_HWID = GC.EnableHWIDCheck ~= false
local USE_FAKE_HWID = GC.UseFakeHWIDForLocalhost ~= false
local WEBHOOKS = GC.Webhooks or {}
local WEBHOOK_AVATAR = GC.WebhookAvatar
	or 'https://raw.githubusercontent.com/ghtipi/cdn_bacsigaming/main/assets_UDS/logo.webp'
local WEBHOOK_USERNAME = GC.WebhookUsername or 'Ban quản trị'
local ANNOUNCE_MENTION_EVERYONE = GC.AnnounceMentionEveryone ~= false

local playerCooldowns = {}
local hwidCache = {}
local HWID_CACHE_DURATION = 300000
local regularCodeHWIDTracking = {}
local REGULAR_HWID_TRACKING_DURATION = 3600000

CreateThread(function()
	pcall(function()
		MySQL.query.await('ALTER TABLE giftcodes ADD COLUMN expires_at DATETIME NULL DEFAULT NULL')
	end)
end)

CreateThread(function()
	MySQL.query([[CREATE TABLE IF NOT EXISTS `giftcode_hwid_tracking` (
		`id` int(11) NOT NULL AUTO_INCREMENT,
		`hwid` varchar(255) NOT NULL,
		`citizenid` varchar(50) NOT NULL,
		`pid` int(11) DEFAULT NULL,
		`code` varchar(100) NOT NULL,
		`player_name` varchar(100) DEFAULT NULL,
		`license` varchar(100) DEFAULT NULL,
		`discord` varchar(100) DEFAULT NULL,
		`ip` varchar(50) DEFAULT NULL,
		`redeemed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (`id`),
		KEY `idx_hwid` (`hwid`),
		KEY `idx_citizenid` (`citizenid`),
		KEY `idx_pid` (`pid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
end)

CreateThread(function()
	while true do
		Wait(60000)
		local now = GetGameTimer()
		for code, hwids in pairs(regularCodeHWIDTracking) do
			for hwid, entry in pairs(hwids) do
				if (now - entry.timestamp) > REGULAR_HWID_TRACKING_DURATION then
					regularCodeHWIDTracking[code][hwid] = nil
				end
			end
			if next(regularCodeHWIDTracking[code]) == nil then
				regularCodeHWIDTracking[code] = nil
			end
		end
	end
end)

local function randomCodeGenerator()
	local randomCode = ""
	local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	local length = 16
	local charTable = {}
	for c in chars:gmatch "." do
		table.insert(charTable, c)
	end
	for i = 1, length do
		randomCode = randomCode .. charTable[math.random(1, #charTable)]
	end
	return randomCode
end

local function decodeJsonArrayOrEmpty(value)
	if not value or value == '' then return {} end
	local ok, decoded = pcall(json.decode, value)
	if not ok or type(decoded) ~= 'table' then return {} end
	return decoded
end

local function decodeJsonObjectOrNil(value)
	if not value or value == '' then return nil end
	local ok, decoded = pcall(json.decode, value)
	if not ok or type(decoded) ~= 'table' or decoded[1] ~= nil then return nil end
	return decoded
end

local function isClothingResourceReady()
	return GetResourceState('XNClothes') == 'started'
end

local function isValidClothingComponent(component)
	if not isClothingResourceReady() then return false end
	local ok, valid = pcall(function()
		return exports['XNClothes']:IsValidClothingComponent(component)
	end)
	return ok and valid == true
end

local function getClothingComponentLabel(component)
	if not isClothingResourceReady() then return component end
	local ok, list = pcall(function()
		return exports['XNClothes']:GetComponentList()
	end)
	if not ok or type(list) ~= 'table' then return component end
	for _, entry in ipairs(list) do
		if entry.key == component then
			return entry.label or component
		end
	end
	return component
end

local function normalizeClothingReward(item)
	if type(item) ~= 'table' then return nil, 'Dữ liệu quần áo không hợp lệ' end
	local component = type(item.component) == 'string' and item.component:match('^%s*(.-)%s*$')
		or (type(item.name) == 'string' and item.name:match('^%s*(.-)%s*$'))
		or ''
	if component == '' then
		return nil, 'Thiếu loại quần áo (component)'
	end
	if not isValidClothingComponent(component) then
		return nil, string.format('Loại quần áo không hợp lệ: %s', component)
	end
	local maleDrawable = tonumber(item.maleDrawable)
	local femaleDrawable = tonumber(item.femaleDrawable)
	if not maleDrawable or maleDrawable < 0 or not femaleDrawable or femaleDrawable < 0 then
		return nil, string.format('Drawable Nam/Nữ không hợp lệ cho %s', component)
	end
	return {
		type = 'clothing',
		component = component,
		maleDrawable = math.floor(maleDrawable),
		femaleDrawable = math.floor(femaleDrawable),
		texture = math.max(0, math.floor(tonumber(item.texture) or 1)),
		autoGender = item.autoGender ~= false,
	}, nil
end

local function getPlayerGender(source, player)
	if isClothingResourceReady() then
		local ok, sex = pcall(function()
			return exports['XNClothes']:GetPlayerSex(source)
		end)
		if ok and (sex == 'male' or sex == 'female') then
			return sex
		end
	end
	if player and player._qbx and player._qbx.PlayerData then
		local gender = player._qbx.PlayerData.charinfo and player._qbx.PlayerData.charinfo.gender
		if gender == 1 then return 'female' end
		return 'male'
	end
	return 'male'
end

local function resolveClothingSex(autoGender, source, player)
	if autoGender then
		return getPlayerGender(source, player)
	end
	return math.random() < 0.5 and 'male' or 'female'
end

local function grantClothingReward(source, player, clothingData)
	if not isClothingResourceReady() then
		return false, 'Hệ thống quần áo chưa sẵn sàng'
	end
	local sex = resolveClothingSex(clothingData.autoGender ~= false, source, player)
	local drawable = sex == 'male' and clothingData.maleDrawable or clothingData.femaleDrawable
	if not drawable or drawable < 0 then
		return false, 'Giftcode bị lỗi (drawable quần áo không hợp lệ)'
	end
	local ok, err = pcall(function()
		local success, resultMsg = exports['XNClothes']:GiveClothingItemBySex(
			source,
			clothingData.component,
			drawable,
			clothingData.texture or 1,
			sex,
			0
		)
		if not success then
			error(resultMsg or 'Không thể trao quần áo')
		end
		return resultMsg
	end)
	if not ok then
		return false, (type(err) == 'string' and err) or 'Không thể trao quần áo'
	end
	local label = getClothingComponentLabel(clothingData.component)
	local genderLabel = sex == 'male' and 'Nam' or 'Nữ'
	return true, string.format('%s (drawable %d, %s)', label, drawable, genderLabel)
end

local function mkFail(player, message)
	Notify(player, message, 'error')
	return { status = false, message = message }
end

local function mkSuccess(player, message)
	Notify(player, message, 'success')
	return { status = true, message = message }
end

local function rewardVehicle(source, model, plate)
	local ok, res = pcall(function()
		return exports.gtago_vehicle_garage:GrantOwnedVehicle(source, model, plate)
	end)
	if not ok or not res or not res.status then
		return false, (res and res.message) or 'Không thể thêm xe vào garage'
	end
	return true, res
end

local function resolveExpiresAt(expireHours)
	expireHours = tonumber(expireHours) or 0
	if expireHours <= 0 then return nil end
	return os.date('%Y-%m-%d %H:%M:%S', os.time() + math.floor(expireHours * 3600))
end

local function formatExpiresLabel(expiresAt)
	if not expiresAt or expiresAt == '' then return 'Không hết hạn' end
	return tostring(expiresAt)
end

local function isGiftCodeExpired(data)
	if not data or not data.expires_at then return false end
	local expired = MySQL.scalar.await(
		'SELECT IF(expires_at IS NOT NULL AND expires_at <= NOW(), 1, 0) FROM giftcodes WHERE code = ? LIMIT 1',
		{ data.code }
	)
	return tonumber(expired) == 1
end

local function parseItemsRewardString(itemsStr)
	if type(itemsStr) ~= 'string' or itemsStr == '' then
		return nil, 'Danh sách item không hợp lệ'
	end
	local rewards = {}
	local parts = {}
	for part in string.gmatch(itemsStr, '[^,]+') do
		table.insert(parts, part:match('^%s*(.-)%s*$'))
	end
	if #parts < 1 then return nil, 'Phải có ít nhất 1 item' end
	if #parts > MAX_BUNDLE_ITEMS then
		return nil, string.format('Tối đa %d item mỗi giftcode', MAX_BUNDLE_ITEMS)
	end
	for _, part in ipairs(parts) do
		local name, countStr = part:match('^([^:]+):(%d+)$')
		if not name or not countStr then
			return nil, string.format('Định dạng không hợp lệ: %s (dùng item:soLuong)', part)
		end
		name = name:match('^%s*(.-)%s*$')
		local count = tonumber(countStr)
		if not count or count < 1 then
			return nil, string.format('Số lượng không hợp lệ: %s', part)
		end
		if not exports.ox_inventory:Items(name) then
			return nil, string.format('Không tìm thấy vật phẩm: %s', name)
		end
		table.insert(rewards, { type = 'item', name = name, count = count })
	end
	return rewards
end

local function describeRewards(rewards)
	local parts = {}
	for _, r in ipairs(rewards) do
		if r.type == 'item' or r.type == 'currency' then
			table.insert(parts, string.format('%s x%d', r.name, r.count))
		elseif r.type == 'vehicle' then
			table.insert(parts, string.format('xe %s', r.model or r.name))
		elseif r.type == 'clothing' then
			local label = getClothingComponentLabel(r.component)
			table.insert(parts, string.format('%s (Nam:%d/Nữ:%d)', label, r.maleDrawable, r.femaleDrawable))
		end
	end
	return table.concat(parts, ', ')
end

local function isGiftCodeAdmin(source)
	if source == 0 then return true end
	return IsPlayerAceAllowed(source, 'group.admin')
		or IsPlayerAceAllowed(source, 'command.creategiftcode')
end

local function buildBundleRewards(items)
	if type(items) ~= 'table' or #items < 1 then
		return nil, 'Phải có ít nhất 1 phần thưởng'
	end
	if #items > MAX_BUNDLE_ITEMS then
		return nil, string.format('Tối đa %d phần thưởng mỗi giftcode', MAX_BUNDLE_ITEMS)
	end

	local rewards = {}
	for _, item in ipairs(items) do
		if type(item) ~= 'table' then
			return nil, 'Dữ liệu bundle không hợp lệ'
		end
		if item.type == 'clothing' then
			local clothingReward, clothingErr = normalizeClothingReward(item)
			if not clothingReward then
				return nil, clothingErr
			end
			table.insert(rewards, clothingReward)
		else
			local name = type(item.name) == 'string' and item.name:match('^%s*(.-)%s*$') or ''
			local count = tonumber(item.count) or 0
			if name == '' or count < 1 then
				return nil, 'Item bundle không hợp lệ'
			end
			if not exports.ox_inventory:Items(name) then
				return nil, string.format('Không tìm thấy vật phẩm: %s', name)
			end
			table.insert(rewards, { type = 'item', name = name, count = math.floor(count) })
		end
	end

	if #rewards < 1 then
		return nil, 'Phải có ít nhất 1 phần thưởng hợp lệ'
	end
	return rewards
end

local function isPlayerOnCooldown(src)
	local now = GetGameTimer()
	return playerCooldowns[src] and (now - playerCooldowns[src]) < COOLDOWN_TIME
end

local function setPlayerCooldown(src)
	playerCooldowns[src] = GetGameTimer()
end

local function getCooldownSecondsLeft(src)
	if not playerCooldowns[src] then return 0 end
	return math.ceil((COOLDOWN_TIME - (GetGameTimer() - playerCooldowns[src])) / 1000)
end

local function sendGiftCodeDiscord(webhookKey, title, description, color, content)
	local url = WEBHOOKS[webhookKey]
	if not url or url == '' then return end
	CreateThread(function()
		local payload = {
			username = WEBHOOK_USERNAME,
			avatar_url = WEBHOOK_AVATAR,
			embeds = { {
				color = color or 16753920,
				title = title,
				description = description,
				footer = { text = os.date('%d/%m/%Y %H:%M:%S') },
			} },
		}
		if content and content ~= '' then
			payload.content = content
		end
		PerformHttpRequest(url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
	end)
end

local function getPlayerIdentifiersInfo(src)
	local license, discord, ip
	for _, identifier in pairs(GetPlayerIdentifiers(src)) do
		if string.find(identifier, 'license2:') or string.find(identifier, 'license:') then
			if not license then license = identifier end
		elseif string.find(identifier, 'discord:') then
			discord = identifier
		elseif string.find(identifier, 'ip:') then
			ip = identifier
		end
	end
	return license, discord, ip
end

local function getPlayerHWID(src)
	local hwids = {}
	for i = 0, GetNumPlayerTokens(src) - 1 do
		table.insert(hwids, GetPlayerToken(src, i))
	end
	if #hwids > 0 then
		return hwids[1], hwids
	end
	if USE_FAKE_HWID then
		for _, identifier in pairs(GetPlayerIdentifiers(src)) do
			if string.find(identifier, 'license:') or string.find(identifier, 'steam:') then
				return 'hwid:FAKE_' .. string.sub(identifier, -12), hwids
			end
		end
	end
	return nil, hwids
end

local function getAccountsByHWID(hwid)
	local now = GetGameTimer()
	if hwidCache[hwid] and (now - hwidCache[hwid].timestamp) < HWID_CACHE_DURATION then
		return hwidCache[hwid].data
	end
	local result = MySQL.query.await(
		'SELECT citizenid, pid, code, player_name, discord, redeemed_at FROM giftcode_hwid_tracking WHERE hwid = ? ORDER BY redeemed_at DESC',
		{ hwid }
	)
	hwidCache[hwid] = { data = result or {}, timestamp = now }
	return result or {}
end

local function saveHWIDTracking(hwid, citizenid, pid, code, playerName, license, discord, ip)
	MySQL.insert.await(
		'INSERT INTO giftcode_hwid_tracking (hwid, citizenid, pid, code, player_name, license, discord, ip) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
		{ hwid, citizenid, pid, code, playerName, license, discord, ip }
	)
	hwidCache[hwid] = nil
end

local function isHwidStrict(data)
	if tonumber(data.hwid_strict) == 1 then return true end
	local redeems = decodeJsonArrayOrEmpty(data.redeems)
	if data.hwid_strict == nil and tonumber(data.remaining) == 1 and #redeems == 0 then
		return true
	end
	return false
end

local function buildAbuseAccountsList(accounts, currentCitizenid, currentDiscord)
	local list = '\n\n**DANH SÁCH TÀI KHOẢN DÙNG CODE CHUNG HWID:**\n'
	for i, acc in ipairs(accounts) do
		local discordId = 'N/A'
		if acc.citizenid == currentCitizenid and currentDiscord then
			discordId = currentDiscord:gsub('discord:', '')
		elseif acc.discord then
			discordId = acc.discord:gsub('discord:', '')
		end
		local moneyInfo = 'N/A | N/A'
		local moneyResult = MySQL.query.await('SELECT money FROM players WHERE citizenid = ? LIMIT 1', { acc.citizenid })
		if moneyResult and moneyResult[1] and moneyResult[1].money then
			local moneyData = json.decode(moneyResult[1].money)
			moneyInfo = string.format('$%s | $%s', moneyData.cash or 0, moneyData.bank or 0)
		end
		list = list .. string.format(
			'%d. **%s**\n   ├── PID: `%s` | Discord: `%s`\n   └── Tiền mặt | Ngân hàng: `%s`\n',
			i, acc.player_name or 'Unknown', tostring(acc.pid or 'N/A'), discordId, moneyInfo
		)
	end
	return list
end

---@return boolean allowed
---@return string? failMessage
local function checkHWID(source, player, data, code, playerHWID, hwids, license, discord, ip)
	if not ENABLE_HWID or not playerHWID then
		if ENABLE_HWID and isHwidStrict(data) then
			sendGiftCodeDiscord('AbuseAlert', '🔐 BẢO MẬT: KHÔNG LẤY ĐƯỢC HWID', string.format(
				'**Player:** %s\n**Citizen ID:** %s\n**Code:** `%s`\n**License:** %s\n**Discord:** %s\n**IP:** %s',
				GetPlayerName(source), player.getIdentifier(), code, license or 'N/A', discord or 'N/A',
				ip and ip:gsub('ip:', '') or 'N/A'
			), 15158332)
			return false, 'Không tìm thấy thông tin tài khoản! Vui lòng liên hệ admin.'
		end
		return true
	end

	local citizenid = player.getIdentifier()
	local pid = 'N/A'
	if player._qbx and player._qbx.PlayerData then
		pid = tostring(player._qbx.PlayerData.pid or player._qbx.PlayerData.cid or 'N/A')
	end

	if isHwidStrict(data) then
		local existing = getAccountsByHWID(playerHWID)
		if existing and #existing > 0 then
			local accounts = {}
			for _, acc in ipairs(existing) do
				table.insert(accounts, acc)
			end
			local found = false
			for _, acc in ipairs(accounts) do
				if acc.citizenid == citizenid then found = true break end
			end
			if not found then
				table.insert(accounts, {
					citizenid = citizenid,
					pid = pid,
					player_name = GetPlayerName(source),
					code = code,
					discord = discord,
				})
			end

			local shortHWID = string.sub(table.concat(hwids, ', '), 1, 60) .. '...'
			sendGiftCodeDiscord('AbuseAlert', '⚠️ CẢNH BÁO: ABUSE GIFTCODE (STRICT)', string.format(
				'**Mã code:** `%s`\n**HWID:** `%s`%s',
				code, shortHWID, buildAbuseAccountsList(accounts, citizenid, discord)
			), 15158332)

			MySQL.update.await('DELETE FROM giftcodes WHERE code = ?', { code })
			return false, 'Máy của bạn đã sử dụng giftcode này rồi!'
		end
	else
		if not regularCodeHWIDTracking[code] then
			regularCodeHWIDTracking[code] = {}
		end
		if regularCodeHWIDTracking[code][playerHWID] then
			local prev = regularCodeHWIDTracking[code][playerHWID]
			local accounts = { {
				citizenid = prev.citizenid,
				pid = prev.pid,
				player_name = prev.playerName,
				code = code,
			} }
			if prev.citizenid ~= citizenid then
				table.insert(accounts, {
					citizenid = citizenid,
					pid = pid,
					player_name = GetPlayerName(source),
					code = code,
				})
			end
			local shortHWID = string.sub(table.concat(hwids, ', '), 1, 60) .. '...'
			sendGiftCodeDiscord('AbuseAlert', '⚠️ CẢNH BÁO: ABUSE GIFTCODE', string.format(
				'**Mã code:** `%s` (còn %s lần)\n**HWID:** `%s`%s',
				code, tostring(data.remaining), shortHWID, buildAbuseAccountsList(accounts, citizenid, discord)
			), 15158332)
			return false, 'Máy của bạn đã sử dụng giftcode này rồi!'
		end
	end

	return true
end

local function recordHWIDAfterRedeem(source, player, code, playerHWID, license, discord, ip, strictMode)
	if not ENABLE_HWID or not playerHWID then return end
	local citizenid = player.getIdentifier()
	local pid = nil
	if player._qbx and player._qbx.PlayerData then
		pid = player._qbx.PlayerData.pid or player._qbx.PlayerData.cid
	end

	if strictMode then
		saveHWIDTracking(playerHWID, citizenid, pid, code, GetPlayerName(source), license, discord, ip)
	else
		if not regularCodeHWIDTracking[code] then
			regularCodeHWIDTracking[code] = {}
		end
		regularCodeHWIDTracking[code][playerHWID] = {
			citizenid = citizenid,
			pid = pid,
			playerName = GetPlayerName(source),
			timestamp = GetGameTimer(),
		}
	end
end

local function logRedeemDiscord(source, player, code, data, rewardMessage)
	local citizenid = player.getIdentifier()
	local pid = 'N/A'
	local charName = GetPlayerName(source) or 'Unknown'
	if player._qbx and player._qbx.PlayerData then
		local pd = player._qbx.PlayerData
		pid = tostring(pd.pid or pd.cid or 'N/A')
		local ci = pd.charinfo or {}
		if ci.firstname then
			charName = (ci.firstname .. ' ' .. (ci.lastname or '')):gsub('%s+$', '')
		end
	end
	local cash, bank = 'N/A', 'N/A'
	if player._qbx and player._qbx.PlayerData and player._qbx.PlayerData.money then
		cash = tostring(player._qbx.PlayerData.money.cash or 0)
		bank = tostring(player._qbx.PlayerData.money.bank or 0)
	end
	local strictTag = isHwidStrict(data) and ' (STRICT)' or ''
	sendGiftCodeDiscord('Redeemed', '✅ SỬ DỤNG GIFTCODE THÀNH CÔNG', string.format(
		'%s nhận **%s**\n\n**Code:** `%s`%s\n**Còn lại:** %s lần\n**Tên nhân vật:** %s\n**PID:** %s\n**Citizenid:** %s\n**Tiền mặt:** $%s | **Ngân hàng:** $%s',
		GetPlayerName(source), rewardMessage, code, strictTag, tostring(data.remaining),
		charName, pid, citizenid, cash, bank
	), 5763719)
end

local function formatRemainingLabel(remaining)
	if tonumber(remaining) == -1 then return 'Không giới hạn' end
	return tostring(remaining)
end

local function formatMinLevelLabel(minLevel)
	minLevel = tonumber(minLevel) or 0
	if minLevel > 0 then return tostring(minLevel) end
	return 'Không yêu cầu'
end

local function logCreateDiscord(source, code, giftType, description, remaining, minLevel, expiresAt)
	local adminName = source == 0 and 'CONSOLE' or (GetPlayerName(source) or 'Admin')
	local citizenid = 'N/A'
	local adminDiscord = 'N/A'
	if source ~= 0 then
		local admin = GetPlayerFromId(source)
		if admin then citizenid = admin.getIdentifier() end
		local _, discord = getPlayerIdentifiersInfo(source)
		if discord then adminDiscord = discord:gsub('discord:', '') end
	end
	sendGiftCodeDiscord('Created', 'LOG TẠO GIFTCODE', string.format(
		'**Người tạo:** %s\n**Discord:** `%s`\n**Citizenid:** `%s`\n**Thời gian:** %s\n\n**Mã:** `%s`\n**Loại:** %s\n**Phần thưởng:** %s\n**Lượt dùng:** %s\n**Cấp tối thiểu:** %s\n**Hết hạn:** %s',
		adminName, adminDiscord, citizenid, os.date('%d/%m/%Y %H:%M:%S'), code, giftType, description,
		formatRemainingLabel(remaining), formatMinLevelLabel(minLevel), formatExpiresLabel(expiresAt)
	), 16753920)
end

local function logAnnounceDiscord(code, announceTitle, remaining, expiresAt)
	if _G.type(announceTitle) ~= 'string' or announceTitle == '' then return end
	local mention = ANNOUNCE_MENTION_EVERYONE and '||@everyone||' or nil
	sendGiftCodeDiscord('Announce', announceTitle, string.format(
		' **Mã giftcode:** `%s`\n**Giới hạn GiftCode:** %s\n**Hết hạn:** %s\n\n Nhập mã tại **Menu (ESC) → Gift code**',
		code, formatRemainingLabel(remaining), formatExpiresLabel(expiresAt)
	), 3447003, mention)
end

---@return table|nil
local function getEsxForLevel()
	local ok, fw = pcall(function() return Framework end)
	if ok and fw and _G.type(fw.GetLevelFromExp) == 'function' then return fw end
	local ok2, ex = pcall(function() return exports['es_extended']:getSharedObject() end)
	if ok2 and ex and _G.type(ex.GetLevelFromExp) == 'function' then return ex end
	return nil
end

local function getPlayerRedeemLevel(player)
	if not player then return 0 end
	if GetResourceState('Tipi_menu') == 'started' then
		local ok, level = pcall(function()
			return exports['Tipi_menu']:GetPlayerAgeLevel(player.source)
		end)
		if ok and level then
			return tonumber(level) or 0
		end
	end
	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local qbPlayer = player._qbx
		if qbPlayer and qbPlayer.PlayerData then
			local metadata = qbPlayer.PlayerData.metadata or {}
			local level = tonumber(metadata.level) or tonumber(metadata.explevel)
			if level and level > 0 then return level end
		end
	end
	local esx = getEsxForLevel()
	if esx and _G.type(player.getEXP) == 'function' then
		local ok, exp = pcall(function() return player.getEXP() end)
		if ok and exp ~= nil then
			local ok2, lvl = pcall(function() return esx.GetLevelFromExp(exp) end)
			if ok2 and lvl ~= nil then
				local n = tonumber(lvl)
				if n and n > 0 then return n end
				return 1
			end
		end
	end
	if _G.type(player.getLevel) == 'function' then
		local ok3, lvl3 = pcall(function() return player.getLevel() end)
		if ok3 and lvl3 ~= nil then
			local n3 = tonumber(lvl3)
			if n3 and n3 > 0 then return n3 end
		end
	end
	if _G.type(player.get) == 'function' then
		local ok4, lvl4 = pcall(function() return player.get('level') end)
		if ok4 and lvl4 ~= nil then
			local n4 = tonumber(lvl4)
			if n4 and n4 > 0 then return n4 end
		end
	end
	local src = player.source
	if src and src > 0 then
		local ok5, st = pcall(function() return Player(src).state end)
		if ok5 and st and st.level ~= nil then
			local n5 = tonumber(st.level)
			if n5 and n5 > 0 then return n5 end
		end
	end
	return 0
end

local function precheckItemReward(source, itemName, count)
	if not itemName or not count then return false, 'Giftcode bị lỗi (reward item không hợp lệ)' end
	if not exports.ox_inventory:Items(itemName) then
		return false, string.format('Không tìm thấy vật phẩm: %s', itemName)
	end
	return true
end

local function giveItemReward(source, player, itemName, count, metadata)
	local citizenid = player.getIdentifier()
	metadata = metadata or {}

	-- Thử thêm vào kho đồ người chơi nếu còn đủ chỗ/trọng lượng
	if exports.ox_inventory:CanCarryItem(source, itemName, count) then
		local added = exports.ox_inventory:AddItem(source, itemName, count, metadata)
		if added then
			return true, false
		end
	end

	-- Nếu kho đồ không đủ hoặc AddItem thất bại, gửi về bưu cục của người chơi
	if citizenid and exports.xn_buucuc then
		local sentToBuucuc = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, itemName, count, metadata)
		if sentToBuucuc then
			return true, true
		end
	end

	-- Dự phòng: Thử thêm lại vào ox_inventory nếu bưu cục không có hoặc lỗi
	local fallbackAdded = exports.ox_inventory:AddItem(source, itemName, count, metadata)
	if fallbackAdded then
		return true, false
	end

	return false, 'Kho đồ đầy và không thể gửi vật phẩm về bưu cục'
end

local function precheckRewards(source, data, player)
	if data.type == 'bundle' and data.rewards then
		local rewards = decodeJsonArrayOrEmpty(data.rewards)
		if #rewards < 1 then return false, 'Giftcode bị lỗi (không có phần thưởng)' end
		for _, r in ipairs(rewards) do
			if r.type == 'item' or r.type == 'currency' then
				local ok, msg = precheckItemReward(source, r.name, r.count)
				if not ok then return false, msg end
			elseif r.type == 'vehicle' then
				if not r.model or type(r.model) ~= 'string' or r.model == '' then
					return false, 'Giftcode bị lỗi (reward vehicle không hợp lệ)'
				end
			elseif r.type == 'clothing' then
				local _, clothingErr = normalizeClothingReward(r)
				if clothingErr then return false, clothingErr end
			else
				return false, 'Giftcode bị lỗi (loại reward không hỗ trợ)'
			end
		end
		return true
	end
	if data.type == 'clothing' then
		local clothingData = decodeJsonObjectOrNil(data.rewards)
		local _, clothingErr = normalizeClothingReward(clothingData or { component = data.name })
		if clothingErr then return false, clothingErr end
		return true
	end
	if data.type == 'item' or data.type == 'currency' then
		return precheckItemReward(source, data.name, data.count)
	end
	if data.type == 'vehicle' then
		if not data.name or data.name == '' then return false, 'Giftcode bị lỗi (model xe không hợp lệ)' end
		return true
	end
	return false, 'Loại Giftcode không được hỗ trợ'
end

local function grantRewards(source, player, data)
	if data.type == 'bundle' and data.rewards then
		local rewards = decodeJsonArrayOrEmpty(data.rewards)
		local buucucItems = {}
		for _, r in ipairs(rewards) do
			if r.type == 'item' or r.type == 'currency' then
				local okItem, inBuucucOrErr = giveItemReward(source, player, r.name, r.count, r.metadata)
				if not okItem then return false, inBuucucOrErr end
				if inBuucucOrErr == true then
					table.insert(buucucItems, string.format('%d x %s', r.count, r.name))
				end
			elseif r.type == 'vehicle' then
				local okV, errOrRes = rewardVehicle(source, r.model, r.plate)
				if not okV then return false, errOrRes end
			elseif r.type == 'clothing' then
				local okC, msgC = grantClothingReward(source, player, r)
				if not okC then return false, msgC end
			end
		end
		local msg = 'Nhận quà Giftcode: ' .. describeRewards(rewards)
		if #buucucItems > 0 then
			msg = msg .. ' (Kho đồ đầy: ' .. table.concat(buucucItems, ', ') .. ' đã gửi về Bưu cục)'
		end
		return true, msg
	end
	if data.type == 'clothing' then
		local clothingData = decodeJsonObjectOrNil(data.rewards)
		if not clothingData then
			clothingData = { component = data.name }
		end
		local okC, msgC = grantClothingReward(source, player, clothingData)
		if not okC then return false, msgC end
		return true, 'Bạn nhận được ' .. msgC .. ' từ Giftcode'
	end
	if data.type == 'item' or data.type == 'currency' then
		local okItem, inBuucucOrErr = giveItemReward(source, player, data.name, data.count, data.metadata)
		if not okItem then return false, inBuucucOrErr end
		if inBuucucOrErr == true then
			return true, string.format('Kho đồ đầy! %d x %s đã được gửi về Bưu cục', data.count, data.name)
		end
		return true, string.format('Bạn nhận được %d x %s từ Giftcode', data.count, data.name)
	end
	if data.type == 'vehicle' then
		local okV, errOrRes = rewardVehicle(source, data.name, data.plate)
		if not okV then return false, errOrRes end
		return true, string.format('Bạn nhận được xe %s (biển %s) từ Giftcode', data.name, (errOrRes and errOrRes.plate) or '')
	end
	return false, 'Loại Giftcode không được hỗ trợ'
end

function Impl:Init()
	self:LogInfo("initialized")
end

function Impl:OnReady()
	self:LogInfo("ready")
	self:RegisterEvents()
	self:CommandHandler()
end

function Impl:RegisterEvents()
	lib.callback.register("Tipi_menu:cb:giftCode:redeem", function(source, code)
		local player = GetPlayerFromId(source)
		if not player then return { status = false, message = 'Không tìm thấy người chơi' } end

		if type(code) ~= 'string' or code == '' then
			return mkFail(player, 'Vui lòng nhập mã giftcode')
		end
		code = code:match('^%s*(.-)%s*$') or code
		if code == '' or #code > MAX_CODE_LENGTH then
			return mkFail(player, 'Mã giftcode không hợp lệ')
		end

		if isPlayerOnCooldown(source) then
			return mkFail(player, string.format('Vui lòng đợi %d giây trước khi thử lại', getCooldownSecondsLeft(source)))
		end

		local data = GetGiftCode(code)
		if not data or data.code ~= code then
			return mkFail(player, 'Mã Giftcode không tồn tại')
		end
		data.redeems = decodeJsonArrayOrEmpty(data.redeems)

		if data.remaining ~= -1 and tonumber(data.remaining) < 1 then
			return mkFail(player, 'Mã Giftcode đã hết lượt sử dụng')
		end

		if isGiftCodeExpired(data) then
			return mkFail(player, 'Mã Giftcode đã hết hạn sử dụng')
		end

		local identifier = player.getIdentifier()
		for _, v in ipairs(data.redeems) do
			if v == identifier then
				return mkFail(player, 'Bạn đã sử dụng mã Giftcode này rồi')
			end
		end

		local minLevel = tonumber(data.min_level) or 0
		if minLevel > 0 then
			local plv = getPlayerRedeemLevel(player)
			if plv < minLevel then
				return mkFail(player, string.format('Bạn cần đạt cấp %d mới có thể dùng giftcode này (cấp hiện tại: %d)', minLevel, plv))
			end
		end

		local license, discord, ip = getPlayerIdentifiersInfo(source)
		local playerHWID, hwids = getPlayerHWID(source)
		local strictMode = isHwidStrict(data)
		local hwidOk, hwidMsg = checkHWID(source, player, data, code, playerHWID, hwids, license, discord, ip)
		if not hwidOk then
			return mkFail(player, hwidMsg)
		end

		local canGrant, precheckMsg = precheckRewards(source, data, player)
		if not canGrant then
			return mkFail(player, precheckMsg)
		end

		setPlayerCooldown(source)

		local reserved, reservedData = ReserveGiftCode(code, identifier)
		if not reserved then
			if reservedData == 'expired' then
				return mkFail(player, 'Mã Giftcode đã hết hạn sử dụng')
			elseif reservedData == 'race_condition' or reservedData == 'out_of_uses' then
				return mkFail(player, 'Giftcode này vừa hết lượt sử dụng!')
			elseif reservedData == 'already_redeemed' then
				return mkFail(player, 'Bạn đã sử dụng mã Giftcode này rồi')
			end
			return mkFail(player, 'Mã Giftcode không tồn tại')
		end

		data = reservedData
		local ok, rewardMsg = grantRewards(source, player, data)
		if not ok then
			return mkFail(player, rewardMsg)
		end

		recordHWIDAfterRedeem(source, player, code, playerHWID, license, discord, ip, strictMode)
		logRedeemDiscord(source, player, code, data, rewardMsg)

		if tonumber(data.remaining) == 0 then
			regularCodeHWIDTracking[code] = nil
		end

		return mkSuccess(player, rewardMsg)
	end)

	lib.callback.register("Tipi_menu:cb:giftCode:getClothingComponents", function(source)
		if not isGiftCodeAdmin(source) then
			return { status = false, message = 'Bạn không có quyền', components = {} }
		end
		if not isClothingResourceReady() then
			return { status = false, message = 'Clothes chưa được khởi động', components = {} }
		end
		local ok, components = pcall(function()
			return exports['XNClothes']:GetComponentList()
		end)
		if not ok or type(components) ~= 'table' then
			return { status = false, message = 'Không thể tải danh sách quần áo', components = {} }
		end
		return { status = true, components = components }
	end)

	lib.callback.register("Tipi_menu:cb:giftCode:create", function(source, body)
		if not isGiftCodeAdmin(source) then
			return { status = false, message = 'Bạn không có quyền tạo giftcode' }
		end
		if type(body) ~= 'table' then
			return { status = false, message = 'Dữ liệu không hợp lệ' }
		end

		local mode = body.mode
		local remaining = tonumber(body.remaining) or 1
		local minLevel = tonumber(body.minLevel) or 0
		local expireHours = tonumber(body.expireHours) or 0
		local response

		if mode == 'random' then
			local giftType = body.type
			if giftType == 'clothing' then
				response = self:CreateClothingGiftCode(source, nil, body, remaining, minLevel, expireHours, true)
			else
				local name = type(body.name) == 'string' and body.name:match('^%s*(.-)%s*$') or ''
				local count = tonumber(body.count) or 1
				response = self:CreateGiftCode(source, giftType, name, count, remaining, minLevel, expireHours)
			end
		elseif mode == 'fixed' then
			local code = type(body.code) == 'string' and body.code:match('^%s*(.-)%s*$') or ''
			local giftType = body.type
			if giftType == 'clothing' then
				response = self:CreateClothingGiftCode(source, code, body, remaining, minLevel, expireHours, false)
			elseif giftType == 'vehicle' then
				local name = type(body.name) == 'string' and body.name:match('^%s*(.-)%s*$') or ''
				response = self:CreateVehicleGiftCode(source, code, name, remaining, minLevel, expireHours)
			else
				local name = type(body.name) == 'string' and body.name:match('^%s*(.-)%s*$') or ''
				local count = tonumber(body.count) or 1
				response = self:CreateFixedGiftCode(source, code, giftType, name, count, remaining, minLevel, expireHours)
			end
		elseif mode == 'bundle' then
			local code = type(body.code) == 'string' and body.code:match('^%s*(.-)%s*$') or ''
			local rewards, parseErr = buildBundleRewards(body.items)
			if not rewards then
				return { status = false, message = parseErr }
			end
			response = self:CreateMultiRewardGiftCode(source, code, rewards, remaining, minLevel, expireHours)
		else
			return { status = false, message = 'Chế độ tạo mã không hợp lệ' }
		end

		local announceTitle = nil
		if body.announceToPlayers == true then
			local title = type(body.announceTitle) == 'string' and body.announceTitle:match('^%s*(.-)%s*$') or ''
			if #title > 200 then
				title = title:sub(1, 200)
			end
			if title ~= '' then
				announceTitle = title
			end
		end
		self:HandleCreateResponse(source, response, body.code, announceTitle)
		return response
	end)
end

function Impl:CommandHandler()
	lib.addCommand('creategiftcode', {
		help = 'Mở giao diện tạo mã Giftcode',
		restricted = 'group.admin'
	}, function(source)
		TriggerClientEvent('Tipi_menu:cl:openCreateGiftCode', source)
	end)

	--[[ Tạm tắt: tạo giftcode qua chat command — dùng /creategiftcode (modal UI)
	lib.addCommand('createcode', {
		help = 'Tạo mã Giftcode (item hoặc xe)',
		params = {
			{ name = 'type', type = 'string', help = 'Loại: item, vehicle' },
			{ name = 'name', type = 'string', help = 'Tên item ox_inventory hoặc model xe' },
			{ name = 'count', type = 'number', help = 'Số lượng item (bỏ qua nếu type=vehicle)' },
			{ name = 'remaining', type = 'number', help = 'Số lượt dùng (-1 = không giới hạn)' },
			{ name = 'minLevel', type = 'number', help = 'Cấp tối thiểu (0 = không yêu cầu)' },
			{ name = 'expireHours', type = 'number', help = 'Số giờ hết hạn (0 = không hết hạn)', optional = true },
		},
		restricted = 'group.admin'
	}, function(source, args, raw)
		local response = self:CreateGiftCode(source, args.type, args.name, args.count, args.remaining, args.minLevel, args.expireHours)
		self:HandleCreateResponse(source, response)
	end)

	lib.addCommand('createcodev2', {
		help = 'Tạo mã Giftcode cố định (item hoặc xe)',
		params = {
			{ name = 'code', type = 'string', help = 'Mã Giftcode' },
			{ name = 'type', type = 'string', help = 'Loại: item, vehicle' },
			{ name = 'name', type = 'string', help = 'Tên item ox_inventory hoặc model xe' },
			{ name = 'count', type = 'number', help = 'Số lượng item (bỏ qua nếu type=vehicle)' },
			{ name = 'remaining', type = 'number', help = 'Số lượt dùng (-1 = không giới hạn)' },
			{ name = 'minLevel', type = 'number', help = 'Cấp tối thiểu (0 = không yêu cầu)' },
			{ name = 'expireHours', type = 'number', help = 'Số giờ hết hạn (0 = không hết hạn)', optional = true },
		},
		restricted = 'group.admin'
	}, function(source, args, raw)
		local response = self:CreateFixedGiftCode(source, args.code, args.type, args.name, args.count, args.remaining, args.minLevel, args.expireHours)
		self:HandleCreateResponse(source, response, args.code)
	end)

	lib.addCommand('createcodevehicle', {
		help = 'Tạo mã Giftcode trao xe',
		params = {
			{ name = 'code', type = 'string', help = 'Mã Giftcode' },
			{ name = 'model', type = 'string', help = 'Model xe (spawn name)' },
			{ name = 'remaining', type = 'number', help = 'Số lượt dùng (-1 = không giới hạn)' },
			{ name = 'minLevel', type = 'number', help = 'Cấp tối thiểu (0 = không yêu cầu)' },
			{ name = 'expireHours', type = 'number', help = 'Số giờ hết hạn (0 = không hết hạn)', optional = true },
		},
		restricted = 'group.admin'
	}, function(source, args, raw)
		local response = self:CreateVehicleGiftCode(source, args.code, args.model, args.remaining, args.minLevel, args.expireHours)
		self:HandleCreateResponse(source, response, args.code)
	end)

	lib.addCommand('createcodeitems', {
		help = 'Tạo mã Giftcode bundle nhiều item',
		params = {
			{ name = 'code', type = 'string', help = 'Mã Giftcode' },
			{ name = 'items', type = 'string', help = 'Danh sách item (vd: homnewbie:1,exp100:3,WEAPON_PISTOL:1)' },
			{ name = 'remaining', type = 'number', help = 'Số lượt dùng của Giftcode (-1 = không giới hạn lượt)' },
			{ name = 'minLevel', type = 'number', help = 'Cấp tối thiểu để dùng (0 = không yêu cầu)' },
			{ name = 'expireHours', type = 'number', help = 'Số giờ hết hạn (0 = không hết hạn)', optional = true },
		},
		restricted = 'group.admin'
	}, function(source, args, raw)
		local response = self:CreateMultiItemGiftCode(source, args.code, args.items, args.remaining, args.minLevel, args.expireHours)
		self:HandleCreateResponse(source, response, args.code)
	end)
	--]]
end

function Impl:HandleCreateResponse(source, response, codeOverride, announceTitle)
	if response.status then
		local code = codeOverride or (response.data and response.data.code)
		if code and response.logDescription then
			logCreateDiscord(source, code, response.logType or 'unknown', response.logDescription, response.logRemaining, response.logMinLevel, response.logExpiresAt)
			logAnnounceDiscord(code, announceTitle, response.logRemaining, response.logExpiresAt)
		end
		if source == 0 then
			print('^2', response.message, code or '', '^0')
		else
			local player = GetPlayerFromId(source)
			Notify(player, response.message, 'success')
		end
	else
		if source == 0 then
			print('^1', response.message, '^0')
		else
			local player = GetPlayerFromId(source)
			Notify(player, response.message, 'error')
		end
	end
end

function Impl:CreateGiftCode(source, giftType, name, count, remaining, minLevel, expireHours)
	count = count or 1
	remaining = remaining or 1
	minLevel = tonumber(minLevel) or 0
	if minLevel < 0 then minLevel = 0 end
	local expiresAt = resolveExpiresAt(expireHours)
	if giftType == 'item' then
		if not exports.ox_inventory:Items(name) then return { status = false, message = 'Không tìm thấy vật phẩm' } end
	elseif giftType == 'vehicle' then
		if _G.type(name) ~= 'string' or name == '' then return { status = false, message = 'Model xe không hợp lệ' } end
		count = 1
	else
		return { status = false, message = 'Loại Giftcode không hợp lệ (chỉ item, vehicle)' }
	end
	local randomCode = randomCodeGenerator()
	local id = CreateGiftCode(randomCode, giftType, name, count, remaining, nil, minLevel, expiresAt)
	if not id then return { status = false, message = 'Có lỗi xảy ra khi thêm dữ liệu' } end
	if source ~= 0 then TriggerClientEvent('uls_lib:client:copy', source, randomCode) end
	local expiryMsg = expiresAt and (' (hết hạn: ' .. formatExpiresLabel(expiresAt) .. ')') or ''
	return {
		status = true,
		message = 'Tạo mã Giftcode thành công' .. expiryMsg,
		data = { code = randomCode },
		logType = giftType,
		logDescription = giftType == 'vehicle' and ('xe ' .. name) or string.format('%s x%d', name, count),
		logRemaining = remaining,
		logMinLevel = minLevel,
		logExpiresAt = expiresAt,
	}
end

function Impl:CreateFixedGiftCode(source, code, giftType, name, count, remaining, minLevel, expireHours)
	count = count or 1
	remaining = remaining or 1
	minLevel = tonumber(minLevel) or 0
	if minLevel < 0 then minLevel = 0 end
	local expiresAt = resolveExpiresAt(expireHours)
	if _G.type(code) ~= 'string' or code == '' then return { status = false, message = 'Code không hợp lệ' } end
	if giftType == 'item' then
		if not exports.ox_inventory:Items(name) then return { status = false, message = 'Không tìm thấy vật phẩm' } end
	elseif giftType == 'vehicle' then
		if _G.type(name) ~= 'string' or name == '' then return { status = false, message = 'Model xe không hợp lệ' } end
		count = 1
	else
		return { status = false, message = 'Loại Giftcode không hợp lệ (chỉ item, vehicle)' }
	end
	local id = CreateGiftCode(code, giftType, name, count, remaining, nil, minLevel, expiresAt)
	if not id then return { status = false, message = 'Có lỗi xảy ra khi thêm dữ liệu' } end
	if source ~= 0 then TriggerClientEvent('uls_lib:client:copy', source, code) end
	local expiryMsg = expiresAt and (' (hết hạn: ' .. formatExpiresLabel(expiresAt) .. ')') or ''
	return {
		status = true,
		message = 'Tạo mã Giftcode thành công' .. expiryMsg,
		data = { code = code },
		logType = giftType,
		logDescription = giftType == 'vehicle' and ('xe ' .. name) or string.format('%s x%d', name, count),
		logRemaining = remaining,
		logMinLevel = minLevel,
		logExpiresAt = expiresAt,
	}
end

function Impl:CreateVehicleGiftCode(source, code, model, remaining, minLevel, expireHours)
	remaining = remaining or 1
	minLevel = tonumber(minLevel) or 0
	if minLevel < 0 then minLevel = 0 end
	local expiresAt = resolveExpiresAt(expireHours)
	if _G.type(code) ~= 'string' or code == '' then return { status = false, message = 'Code không hợp lệ' } end
	if _G.type(model) ~= 'string' or model == '' then return { status = false, message = 'Model xe không hợp lệ' } end
	if remaining < 1 and remaining ~= -1 then return { status = false, message = 'Tham số không hợp lệ' } end
	local id = CreateGiftCode(code, 'vehicle', model, 1, remaining, nil, minLevel, expiresAt)
	if not id then return { status = false, message = 'Có lỗi xảy ra khi thêm dữ liệu' } end
	if source ~= 0 then TriggerClientEvent('uls_lib:client:copy', source, code) end
	local expiryMsg = expiresAt and (' (hết hạn: ' .. formatExpiresLabel(expiresAt) .. ')') or ''
	return {
		status = true,
		message = 'Tạo mã Giftcode xe thành công' .. expiryMsg,
		data = { code = code },
		logType = 'vehicle',
		logDescription = 'xe ' .. model,
		logRemaining = remaining,
		logMinLevel = minLevel,
		logExpiresAt = expiresAt,
	}
end

function Impl:CreateClothingGiftCode(source, code, body, remaining, minLevel, expireHours, isRandom)
	remaining = remaining or 1
	minLevel = tonumber(minLevel) or 0
	if minLevel < 0 then minLevel = 0 end
	local expiresAt = resolveExpiresAt(expireHours)

	local clothingReward, clothingErr = normalizeClothingReward(body)
	if not clothingReward then
		return { status = false, message = clothingErr }
	end

	local finalCode = code
	if isRandom then
		finalCode = randomCodeGenerator()
	elseif _G.type(finalCode) ~= 'string' or finalCode == '' then
		return { status = false, message = 'Code không hợp lệ' }
	end

	local id = CreateGiftCode(finalCode, 'clothing', clothingReward.component, 0, remaining, clothingReward, minLevel, expiresAt)
	if not id then return { status = false, message = 'Có lỗi xảy ra khi thêm dữ liệu' } end
	if source ~= 0 then TriggerClientEvent('uls_lib:client:copy', source, finalCode) end
	local expiryMsg = expiresAt and (' (hết hạn: ' .. formatExpiresLabel(expiresAt) .. ')') or ''
	local label = getClothingComponentLabel(clothingReward.component)
	return {
		status = true,
		message = 'Tạo mã Giftcode quần áo thành công' .. expiryMsg,
		data = { code = finalCode },
		logType = 'clothing',
		logDescription = string.format(
			'%s (Nam:%d/Nữ:%d, texture:%d, autoGender:%s)',
			label,
			clothingReward.maleDrawable,
			clothingReward.femaleDrawable,
			clothingReward.texture,
			clothingReward.autoGender and 'bật' or 'tắt'
		),
		logRemaining = remaining,
		logMinLevel = minLevel,
		logExpiresAt = expiresAt,
	}
end

function Impl:CreateMultiRewardGiftCode(source, code, rewards, remaining, minLevel, expireHours)
	remaining = remaining or 1
	minLevel = tonumber(minLevel) or 0
	if minLevel < 0 then minLevel = 0 end
	local expiresAt = resolveExpiresAt(expireHours)
	if _G.type(code) ~= 'string' or code == '' then return { status = false, message = 'Code không hợp lệ' } end
	if remaining < 1 and remaining ~= -1 then return { status = false, message = 'Tham số không hợp lệ' } end
	if type(rewards) ~= 'table' or #rewards < 1 then return { status = false, message = 'Phải có ít nhất 1 phần thưởng' } end

	local id = CreateGiftCode(code, 'bundle', 'bundle', 0, remaining, rewards, minLevel, expiresAt)
	if not id then return { status = false, message = 'Có lỗi xảy ra khi thêm dữ liệu' } end
	if source ~= 0 then TriggerClientEvent('uls_lib:client:copy', source, code) end
	local expiryMsg = expiresAt and (' (hết hạn: ' .. formatExpiresLabel(expiresAt) .. ')') or ''
	return {
		status = true,
		message = 'Tạo mã Giftcode nhiều phần thưởng thành công' .. expiryMsg,
		data = { code = code },
		logType = 'bundle',
		logDescription = describeRewards(rewards),
		logRemaining = remaining,
		logMinLevel = minLevel,
		logExpiresAt = expiresAt,
	}
end

function Impl:CreateMultiItemGiftCode(source, code, itemsStr, remaining, minLevel, expireHours)
	remaining = remaining or 1
	minLevel = tonumber(minLevel) or 0
	if minLevel < 0 then minLevel = 0 end
	local expiresAt = resolveExpiresAt(expireHours)
	if _G.type(code) ~= 'string' or code == '' then return { status = false, message = 'Code không hợp lệ' } end
	if remaining < 1 and remaining ~= -1 then return { status = false, message = 'Tham số không hợp lệ' } end

	local rewards, parseErr = parseItemsRewardString(itemsStr)
	if not rewards then return { status = false, message = parseErr } end

	local id = CreateGiftCode(code, 'bundle', 'bundle', 0, remaining, rewards, minLevel, expiresAt)
	if not id then return { status = false, message = 'Có lỗi xảy ra khi thêm dữ liệu' } end
	if source ~= 0 then TriggerClientEvent('uls_lib:client:copy', source, code) end
	local expiryMsg = expiresAt and (' (hết hạn: ' .. formatExpiresLabel(expiresAt) .. ')') or ''
	return {
		status = true,
		message = 'Tạo mã Giftcode nhiều item thành công' .. expiryMsg,
		data = { code = code },
		logType = 'bundle',
		logDescription = describeRewards(rewards),
		logRemaining = remaining,
		logMinLevel = minLevel,
		logExpiresAt = expiresAt,
	}
end
