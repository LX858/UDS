local QBX = exports.qbx_core

local META_ACCOUNTS = {
	point = true,
	pumpkin = true,
}

local CoinCache = {}
local SrcCitizenMap = {}

local function getCoinColumnCfg()
	return Config.QBX and Config.QBX.coinColumn
end

local function isDbCoinAccount(account)
	local cfg = getCoinColumnCfg()
	return account == 'coin' and cfg and cfg.table and cfg.idColumn and cfg.column
end

local function getDbCoin(citizenid)
	local cfg = getCoinColumnCfg()
	if not cfg or not citizenid then return 0 end
	if CoinCache[citizenid] ~= nil then
		return CoinCache[citizenid]
	end
	local ok, amount = pcall(function()
		return tonumber(MySQL.scalar.await(
			('SELECT %s FROM %s WHERE %s = ? LIMIT 1'):format(cfg.column, cfg.table, cfg.idColumn),
			{ citizenid }
		)) or 0
	end)
	if ok and amount then
		CoinCache[citizenid] = amount
		return amount
	end
	return 0
end

local function setDbCoin(citizenid, amount, source)
	local cfg = getCoinColumnCfg()
	if not cfg or not citizenid then return end
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	CoinCache[citizenid] = amount
	MySQL.update(
		('UPDATE %s SET %s = ? WHERE %s = ?'):format(cfg.table, cfg.column, cfg.idColumn),
		{ amount, citizenid }
	)
	if source then
		TriggerClientEvent('Tipi_menu:cl:syncPlayerCoin', source, amount)
	end
end

AddEventHandler('playerDropped', function()
	local src = source
	local cid = SrcCitizenMap[src]
	if cid then
		CoinCache[cid] = nil
		SrcCitizenMap[src] = nil
	end
end)

function GetPlayerCoinAmount(citizenid)
	if isDbCoinAccount('coin') then
		return getDbCoin(citizenid)
	end
	return 0
end

local function isMetaAccount(account)
	if Config.QBX and Config.QBX.metadataAccounts and Config.QBX.metadataAccounts[account] then
		return true
	end
	return META_ACCOUNTS[account] == true
end

local function metaKey(account)
	if Config.QBX and Config.QBX.metadataAccounts and Config.QBX.metadataAccounts[account] then
		return Config.QBX.metadataAccounts[account]
	end
	return account
end

local function normalizeMoneyAccount(account)
	if account == 'money' then
		return 'cash'
	end
	return account
end

local function getMetaMoney(qbPlayer, account)
	local key = metaKey(account)
	local metadata = qbPlayer.PlayerData.metadata or {}
	return tonumber(metadata[key]) or 0
end

local function setMetaMoney(qbPlayer, account, amount)
	qbPlayer.Functions.SetMetaData(metaKey(account), amount)
end

local function wrapQbxPlayer(qbPlayer)
	if not qbPlayer or not qbPlayer.PlayerData then
		return nil
	end

	local pd = qbPlayer.PlayerData
	local charinfo = pd.charinfo or {}
	local firstname = charinfo.firstname or ''
	local lastname = charinfo.lastname or ''
	local fullName = pd.name or (firstname .. ' ' .. lastname):gsub('^%s+', ''):gsub('%s+$', '')

	if pd.source and pd.citizenid then
		SrcCitizenMap[pd.source] = pd.citizenid
	end

	local wrapper = {
		source = pd.source,
		identifier = pd.citizenid,
		idCard = pd.citizenid,
		name = fullName,
		_qbx = qbPlayer,
	}

	function wrapper.showNotification(msg, notifyType, length, title)
		Notify(wrapper, msg, notifyType, length, title)
	end

	function wrapper.getIdentifier()
		return pd.citizenid
	end

	function wrapper.getAccount(account)
		if isDbCoinAccount(account) then
			return { money = getDbCoin(pd.citizenid) }
		end

		if isMetaAccount(account) then
			return { money = getMetaMoney(qbPlayer, account) }
		end

		local moneyType = normalizeMoneyAccount(account)
		local money = pd.money or {}
		return { money = tonumber(money[moneyType]) or 0 }
	end

	function wrapper.removeAccountMoney(account, amount, reason)
		amount = tonumber(amount) or 0
		if amount <= 0 then return end

		if isDbCoinAccount(account) then
			local current = getDbCoin(pd.citizenid)
			setDbCoin(pd.citizenid, current - amount, pd.source)
			return
		end

		if isMetaAccount(account) then
			local current = getMetaMoney(qbPlayer, account)
			setMetaMoney(qbPlayer, account, current - amount)
			return
		end

		qbPlayer.Functions.RemoveMoney(normalizeMoneyAccount(account), amount, reason or 'Tipi_menu')
	end

	function wrapper.addAccountMoney(account, amount, reason)
		amount = tonumber(amount) or 0
		if amount <= 0 then return end

		if isDbCoinAccount(account) then
			local current = getDbCoin(pd.citizenid)
			setDbCoin(pd.citizenid, current + amount, pd.source)
			return
		end

		if isMetaAccount(account) then
			local current = getMetaMoney(qbPlayer, account)
			setMetaMoney(qbPlayer, account, current + amount)
			return
		end

		qbPlayer.Functions.AddMoney(normalizeMoneyAccount(account), amount, reason or 'Tipi_menu')
	end

	function wrapper.addMoney(amount, reason)
		wrapper.addAccountMoney('cash', amount, reason)
	end

	function wrapper.addInventoryItem(itemName, amount, reason)
		exports.ox_inventory:AddItem(pd.source, itemName, amount)
	end

	return wrapper
end

function GetPlayerFromId(playerSrc)
	if not playerSrc then return end

	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local qbPlayer = QBX:GetPlayer(tonumber(playerSrc))
		return wrapQbxPlayer(qbPlayer)
	end

	if Config.Framework == 'ProjectStarboy' then
		return Framework.GetPlayerFromSource(playerSrc)
	elseif Config.Framework == 'esx' then
		playerSrc = tonumber(playerSrc)
		return Framework.GetPlayerFromId(playerSrc)
	end
end

function GetPlayerRegisteredAt(citizenid)
	if not citizenid then return os.time() * 1000 end

	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local cfg = Config.QBX and Config.QBX.dateRegistered
		if cfg and cfg.table and cfg.idColumn and cfg.dateColumn then
			local sql = ('SELECT %s AS created_at FROM %s WHERE %s = ? LIMIT 1'):format(
				cfg.dateColumn,
				cfg.table,
				cfg.idColumn
			)
			local result = MySQL.single.await(sql, { citizenid })
			if result and result.created_at then
				local value = tonumber(result.created_at) or result.created_at
				if type(value) == 'number' and value < 9999999999 then
					return value * 1000
				end
				return value
			end
		end
		return os.time() * 1000
	end

	local result = MySQL.single.await('SELECT created_at FROM users WHERE identifier = ? LIMIT 1', { citizenid })
	if result and result.created_at then
		return result.created_at
	end
	return os.time() * 1000
end

local function trimPhoneValue(value)
	if type(value) ~= 'string' and type(value) ~= 'number' then return nil end
	local text = tostring(value):match('^%s*(.-)%s*$')
	if not text or text == '' then return nil end
	return text
end

local function getPhoneItemConfig()
	local cfg = Config.QBX and Config.QBX.phoneItem or {}
	return {
		name = cfg.name or 'phone',
		formattedKeys = cfg.formattedKeys or { 'lbFormattedNumber', 'formattedNumber' },
		numberKeys = cfg.numberKeys or { 'lbPhoneNumber', 'phoneNumber', 'number' },
	}
end

local function pickPhoneFromMetadata(metadata, itemCfg)
	if type(metadata) ~= 'table' then return nil end

	for _, key in ipairs(itemCfg.formattedKeys) do
		local value = trimPhoneValue(metadata[key])
		if value then return value end
	end

	for _, key in ipairs(itemCfg.numberKeys) do
		local value = trimPhoneValue(metadata[key])
		if value then return value end
	end

	return nil
end

function GetPhoneFromInventory(source)
	if not source or GetResourceState('ox_inventory') ~= 'started' then return nil end

	local itemCfg = getPhoneItemConfig()

	local ok, slots = pcall(function()
		return exports.ox_inventory:Search(source, 'slots', itemCfg.name)
	end)
	if ok and type(slots) == 'table' then
		for _, item in pairs(slots) do
			if type(item) == 'table' and item.name == itemCfg.name then
				local phone = pickPhoneFromMetadata(item.metadata, itemCfg)
				if phone then return phone end
			end
		end
	end

	local okItems, items = pcall(function()
		return exports.ox_inventory:GetInventoryItems(source)
	end)
	if okItems and type(items) == 'table' then
		for _, item in pairs(items) do
			if type(item) == 'table' and item.name == itemCfg.name then
				local phone = pickPhoneFromMetadata(item.metadata, itemCfg)
				if phone then return phone end
			end
		end
	end

	return nil
end

function GetPlayerPhoneNumber(player)
	if not player then return nil end

	if player.source then
		local fromInventory = GetPhoneFromInventory(player.source)
		if fromInventory then return fromInventory end
	end

	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local qbPlayer = player._qbx
		if qbPlayer and qbPlayer.PlayerData and qbPlayer.PlayerData.charinfo then
			local phone = qbPlayer.PlayerData.charinfo.phone
			if phone and phone ~= '' then
				return phone
			end
		end

		local cfg = Config.QBX and Config.QBX.phone
		if cfg and cfg.table and cfg.idColumn and cfg.column then
			return MySQL.scalar.await(
				('SELECT %s FROM %s WHERE %s = ? LIMIT 1'):format(cfg.column, cfg.table, cfg.idColumn),
				{ player.identifier }
			)
		end
		return nil
	end

	return MySQL.scalar.await('SELECT phone_number FROM zp_users WHERE citizenid = ?', { player.identifier })
end

function GetItemLabel(itemName)
	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local item = exports.ox_inventory:Items(itemName)
		return item and item.label or itemName
	end

	if Framework and Framework.GetItemLabel then
		return Framework.GetItemLabel(itemName)
	end

	return itemName
end

function HasItem(player, itemName, amount)
	if Config.Framework == 'ProjectStarboy' then
		return player.hasItem({
			itemName = itemName,
			amount = amount
		})
	elseif Config.Framework == 'esx' then
		local xItem = player.hasItem(itemName)
		if not xItem then return false end
		return xItem.count >= amount
	elseif Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local count = exports.ox_inventory:Search(player.source, 'count', itemName)
		return (count or 0) >= amount
	end
end

function RemoveItem(player, itemName, amount)
	if Config.Framework == 'ProjectStarboy' then
		return player.removeInventoryItem({
			itemName = itemName,
			amount = amount
		})
	elseif Config.Framework == 'esx' then
		return player.removeInventoryItem(itemName, amount)
	elseif Config.Framework == 'qbx' or Config.Framework == 'qb' then
		return exports.ox_inventory:RemoveItem(player.source, itemName, amount)
	end
end

function AddMoney(player, amount)
	if Config.Framework == 'ProjectStarboy' then
		return player.addAccountMoney('money', amount)
	elseif Config.Framework == 'esx' then
		return player.addMoney(amount)
	elseif Config.Framework == 'qbx' or Config.Framework == 'qb' then
		return player.addMoney(amount)
	end
end

function ShowNotification(player, msg)
	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		TriggerClientEvent('ox_lib:notify', player.source, {
			description = msg,
			type = 'inform',
		})
		return
	end
	return player.showNotification(msg)
end

function Notify(player, message, type, length, title)
	if Config.OxNotify then
		TriggerClientEvent('ox_lib:notify', player.source, {
			id = message,
			title = title or 'Thông báo',
			description = message,
			type = type or 'info',
			duration = length or 5000
		})
		return
	end

	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		exports.qbx_core:Notify(player.source, message, type, length, title)
	elseif Config.Framework == 'ProjectStarboy' then
		player.showNotification(message)
	elseif Config.Framework == 'esx' then
		player.showNotification(message, type, length, title)
	end
end

function PatchServerFramework()
	Framework = Framework or {}
	Framework.GetPlayerFromId = GetPlayerFromId
	Framework.GetItemLabel = GetItemLabel
end
