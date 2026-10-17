---@class SVPlaytimeImpl : Impl
local Impl = NewImpl('Playtime')

local PlaytimeCache = {}
local PlayerSrcMap = {}
local disconnectQueue = {}
local isProcessingQueue = false
local saveIndex = 0

local function playtimeCfg()
	return Config.Playtime or {}
end

local function ageThresholds()
	return Config.PlaytimeAge or {}
end

local function newbieLabel()
	return playtimeCfg().newbieLabel or 'Newbie'
end

function CalculateAgeFromPlaytime(playtime)
	playtime = tonumber(playtime) or 0
	local thresholds = ageThresholds()
	local first = thresholds[1]

	if not first or playtime < first then
		return newbieLabel(), 0
	end

	for level = 50, 1, -1 do
		local required = thresholds[level]
		if required and playtime >= required then
			return ('Tuổi %d'):format(level), level
		end
	end

	return newbieLabel(), 0
end

local function loadPlaytime(citizenid, src)
	if not citizenid then
		return { joinTime = os.time(), totalPlaytime = 0, src = src }
	end

	if PlaytimeCache[citizenid] then
		if src then
			PlaytimeCache[citizenid].src = src
			PlayerSrcMap[src] = citizenid
		end
		return PlaytimeCache[citizenid]
	end

	local cfg = playtimeCfg()
	local sql = ('SELECT %s AS playtime FROM %s WHERE %s = ? LIMIT 1'):format(
		cfg.column or 'playtime',
		cfg.table or 'players',
		cfg.idColumn or 'citizenid'
	)
	local row = MySQL.single.await(sql, { citizenid })
	local storedPlaytime = row and tonumber(row.playtime) or 0

	PlaytimeCache[citizenid] = {
		joinTime = os.time(),
		totalPlaytime = storedPlaytime,
		src = src,
	}

	if src then
		PlayerSrcMap[src] = citizenid
	end

	return PlaytimeCache[citizenid]
end

local function getTotalPlaytime(citizenid, src)
	local ptData = loadPlaytime(citizenid, src)
	local sessionTime = os.time() - ptData.joinTime
	return ptData.totalPlaytime + sessionTime
end

local function batchSavePlaytimes()
	local updates = {}
	local count = 0

	for citizenid, data in pairs(PlaytimeCache) do
		local sessionTime = os.time() - data.joinTime
		local totalPlaytime = data.totalPlaytime + sessionTime
		local cfg = playtimeCfg()

		updates[#updates + 1] = {
			query = ('UPDATE %s SET %s = ? WHERE %s = ?'):format(
				cfg.table or 'players',
				cfg.column or 'playtime',
				cfg.idColumn or 'citizenid'
			),
			values = { totalPlaytime, citizenid },
		}

		data.joinTime = os.time()
		data.totalPlaytime = totalPlaytime
		count = count + 1
	end

	if count > 0 then
		MySQL.transaction(updates)
	end
end

function Impl:GetPlaytimeBySource(source)
	local player = GetPlayerFromId(source)
	if not player then return 0 end
	return getTotalPlaytime(player.identifier, source)
end

function Impl:GetPlaytimeByCitizenid(citizenid)
	if not citizenid then return 0 end
	if PlaytimeCache[citizenid] then
		return getTotalPlaytime(citizenid, PlaytimeCache[citizenid].src)
	end

	local cfg = playtimeCfg()
	local row = MySQL.single.await(
		('SELECT %s AS playtime FROM %s WHERE %s = ? LIMIT 1'):format(
			cfg.column or 'playtime',
			cfg.table or 'players',
			cfg.idColumn or 'citizenid'
		),
		{ citizenid }
	)
	return row and tonumber(row.playtime) or 0
end

function Impl:GetAgeBySource(source)
	local playtime = self:GetPlaytimeBySource(source)
	local label, level = CalculateAgeFromPlaytime(playtime)
	return label, level, playtime
end

function Impl:SavePlaytime(citizenid, totalPlaytime)
	local cfg = playtimeCfg()
	return MySQL.update.await(
		('UPDATE %s SET %s = ? WHERE %s = ?'):format(
			cfg.table or 'players',
			cfg.column or 'playtime',
			cfg.idColumn or 'citizenid'
		),
		{ totalPlaytime, citizenid }
	)
end

function Impl:AddPlaytime(source, seconds)
	local player = GetPlayerFromId(source)
	if not player then return false, 'player_not_found' end

	seconds = tonumber(seconds) or 0
	if seconds <= 0 then return false, 'invalid_seconds' end

	local citizenid = player.identifier
	local ptData = loadPlaytime(citizenid, source)
	local sessionTime = os.time() - ptData.joinTime
	local newTotal = ptData.totalPlaytime + sessionTime + seconds

	ptData.totalPlaytime = newTotal
	ptData.joinTime = os.time()

	local saved = self:SavePlaytime(citizenid, newTotal)
	if not saved then return false, 'save_failed' end

	local label = select(1, CalculateAgeFromPlaytime(newTotal))
	return true, newTotal, label
end

function Impl:Init()
	self:LogInfo('initialized')
end

function Impl:OnReady()
	self:LogInfo('ready')

	AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
		if not player or not player.PlayerData then return end
		loadPlaytime(player.PlayerData.citizenid, player.PlayerData.source)
	end)

	AddEventHandler('qbx_core:server:playerLoaded', function(playerData)
		if not playerData or not playerData.citizenid then return end
		loadPlaytime(playerData.citizenid, playerData.source)
	end)

	AddEventHandler('esx:playerLoaded', function(source, xPlayer)
		if not xPlayer or not xPlayer.identifier then return end
		loadPlaytime(xPlayer.identifier, source)
	end)

	AddEventHandler('playerDropped', function()
		local src = source
		local citizenid = PlayerSrcMap[src]
		if not citizenid or not PlaytimeCache[citizenid] then return end

		local totalPlaytime = getTotalPlaytime(citizenid, src)
		self:SavePlaytime(citizenid, totalPlaytime)
		PlaytimeCache[citizenid] = nil
		PlayerSrcMap[src] = nil
	end)

	AddEventHandler('onResourceStop', function(resourceName)
		if resourceName ~= GetCurrentResourceName() then return end
		batchSavePlaytimes()
	end)

	CreateThread(function()
		local interval = playtimeCfg().autoSaveInterval or 30000
		local chunkSize = playtimeCfg().autoSaveChunkSize or 50

		while true do
			Wait(interval)

			for citizenid, data in pairs(PlaytimeCache) do
				local sessionTime = os.time() - data.joinTime
				local totalPlaytime = data.totalPlaytime + sessionTime
				data.joinTime = os.time()
				data.totalPlaytime = totalPlaytime
			end
		end
	end)

	exports('GetPlayerAge', function(src)
		local impl = main:GetImpl('Playtime')
		if not impl then return newbieLabel() end
		local label = select(1, impl:GetAgeBySource(src))
		return label
	end)

	exports('GetPlayerAgeLevel', function(src)
		local impl = main:GetImpl('Playtime')
		if not impl then return 0 end
		local _, level = impl:GetAgeBySource(src)
		return level
	end)

	exports('GetPlayerAgeByCitizenid', function(citizenid)
		local impl = main:GetImpl('Playtime')
		if not impl then return newbieLabel() end
		local playtime = impl:GetPlaytimeByCitizenid(citizenid)
		local label = select(1, CalculateAgeFromPlaytime(playtime))
		return label
	end)

	exports('GetPlayerPlaytime', function(src)
		local impl = main:GetImpl('Playtime')
		if not impl then return 0 end
		return impl:GetPlaytimeBySource(src)
	end)

	exports('GetPlayerPlaytimeByCitizenid', function(citizenid)
		local impl = main:GetImpl('Playtime')
		if not impl then return 0 end
		return impl:GetPlaytimeByCitizenid(citizenid)
	end)

	exports('CalculateAgeFromPlaytime', function(playtime)
		return select(1, CalculateAgeFromPlaytime(playtime))
	end)

	exports('AddPlaytime', function(src, seconds)
		local impl = main:GetImpl('Playtime')
		if not impl then return false end
		local ok = impl:AddPlaytime(src, seconds)
		return ok
	end)

	lib.callback.register('Tipi_menu:sv:usePlaytimeItem', function(source, itemName, slot)
		local itemCfg = Config.PlaytimeItems and Config.PlaytimeItems[itemName]
		if not itemCfg then
			return { success = false, error = 'item_not_configured' }
		end

		local count = exports.ox_inventory:Search(source, 'count', itemName)
		if (count or 0) < 1 then
			return { success = false, error = 'no_item' }
		end

		local removed = exports.ox_inventory:RemoveItem(source, itemName, 1, nil, slot)
		if not removed then
			return { success = false, error = 'remove_failed' }
		end

		local impl = main:GetImpl('Playtime')
		if not impl then
			exports.ox_inventory:AddItem(source, itemName, 1)
			return { success = false, error = 'playtime_unavailable' }
		end

		local ok, total, ageLabel = impl:AddPlaytime(source, itemCfg.seconds)
		if not ok then
			exports.ox_inventory:AddItem(source, itemName, 1)
			return { success = false, error = total or 'add_failed' }
		end

		local player = GetPlayerFromId(source)
		if player and itemCfg.notify then
			local _, level = CalculateAgeFromPlaytime(total)
			Notify(player, itemCfg.notify:format(Config.FormatPlaytimeAgeDisplay(level, ageLabel)), 'success')
		end

		return {
			success = true,
			playtime = total,
			age = ageLabel,
			added = itemCfg.seconds,
		}
	end)
end
