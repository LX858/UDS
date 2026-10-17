function Shuffle(t)
	local tbl = {}
	for i = 1, #t do
		tbl[i] = t[i]
	end
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

function Copynof(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[Copynof(orig_key)] = Copynof(orig_value)
		end
	else
		if orig_type ~= 'function' then
			copy = orig
		end
	end
	return copy
end

function GenerateRoomCode(length)
	local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
	local code = ''
	for _ = 1, length do
		local idx = math.random(1, #chars)
		code = code .. chars:sub(idx, idx)
	end
	return code
end

function GenerateUUID()
	local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	return string.gsub(template, '[xy]', function(c)
		local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		return string.format('%x', v)
	end)
end

function TableCount(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function TableKeys(tbl)
	local keys = {}
	for k in pairs(tbl) do
		keys[#keys + 1] = k
	end
	return keys
end

function TableValues(tbl)
	local values = {}
	for _, v in pairs(tbl) do
		values[#values + 1] = v
	end
	return values
end

function GetAlivePlayers(room)
	local alive = {}
	for src, player in pairs(room.players) do
		if player.alive then
			alive[#alive + 1] = player
		end
	end
	return alive
end

function GetAliveSources(room)
	local alive = {}
	for src, player in pairs(room.players) do
		if player.alive then
			alive[#alive + 1] = src
		end
	end
	return alive
end

function GetPlayersByRole(room, role)
	local result = {}
	for src, player in pairs(room.players) do
		if player.alive and player.role == role then
			result[#result + 1] = src
		end
	end
	return result
end

function CountAliveByTeam(room)
	local werewolves, villagers = 0, 0
	for _, player in pairs(room.players) do
		if player.alive then
			if Game.IsWerewolf(player.role) then
				werewolves = werewolves + 1
			else
				villagers = villagers + 1
			end
		end
	end
	return werewolves, villagers
end

function MajorityVote(votes)
	local tally = {}
	for _, target in pairs(votes) do
		if target then
			tally[target] = (tally[target] or 0) + 1
		end
	end

	local winner, maxVotes = nil, 0
	local tie = false
	for target, count in pairs(tally) do
		if count > maxVotes then
			maxVotes = count
			winner = target
			tie = false
		elseif count == maxVotes then
			tie = true
		end
	end

	if tie or not winner then return nil end
	return winner
end

function BuildRoleDeck(playerCount)
	local distribution = Config.Main.RoleDistribution[playerCount]
	if not distribution then return nil end

	local deck = {}
	for role, amount in pairs(distribution) do
		for _ = 1, amount do
			deck[#deck + 1] = role
		end
	end
	return Shuffle(deck)
end

function GetUsedLobbySlots(rooms)
	local used = {}
	for _, room in pairs(rooms) do
		if room.lobbySlot then
			used[room.lobbySlot] = true
		end
	end
	return used
end

function GetFreeLobbySlot(rooms)
	local used = GetUsedLobbySlots(rooms)
	for i = 1, Config.Main.MaxLobbies do
		if not used[i] and Config.Main.LobbyLocations[i] then
			return i
		end
	end
end

function GetLobbyConfig(slot)
	return Config.Main.LobbyLocations[slot]
end

function GetLobbyRadioChannel(slot)
	return Config.Main.Voice.RadioBase + slot
end

function GetLobbyPlayerCoords(slot, playerIndex, totalPlayers, isSpectator)
	local lobby = GetLobbyConfig(slot)
	if not lobby then return nil end

	if isSpectator then
		return lobby.spectator
	end

	local center = lobby.center
	local radius = lobby.spawnRadius or 3.0
	local angle = ((playerIndex - 1) / math.max(totalPlayers, 1)) * (2 * math.pi)
	local heading = (center.w + math.deg(angle)) % 360.0

	return vector4(
		center.x + math.cos(angle) * radius,
		center.y + math.sin(angle) * radius,
		center.z,
		heading
	)
end

function GetPlayerSlotIndex(room, source)
	local index = 1
	local sources = TableKeys(room.players)
	table.sort(sources)
	for i, src in ipairs(sources) do
		if src == source then
			return i
		end
	end
	return index
end
