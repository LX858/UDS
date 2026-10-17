---@class Room : Class
Room = class()

function Room:Init(id, hostSource, hostData, lobbySlot)
	self.id = id
	self.host = hostSource
	self.lobbySlot = lobbySlot
	self.state = Game.Phases.LOBBY
	self.nightPhase = nil
	self.players = {}
	self.logs = {}
	self.votes = {}
	self.nightActions = {}
	self.investigateResults = {}
	self.witchPotions = {}
	self.pendingHunter = nil
	self.winner = nil
	self.round = 0
	self.timerEnd = 0
	self.timerThread = nil
	self.werewolfKillTarget = nil
	self.nightDeaths = {}
	self.dayDeath = nil

	self:AddPlayer(hostSource, hostData, true)
end

function Room:AddPlayer(source, data, isHost)
	self.players[source] = {
		source = source,
		name = data.name,
		identifier = data.identifier,
		role = nil,
		alive = true,
		ready = isHost or false,
		returnCoords = nil,
		disconnected = false,
	}
	if isHost then
		self.host = source
	end
end

function Room:MarkDisconnected(source)
	local player = self.players[source]
	if not player or player.disconnected then return end

	player.disconnected = true
	player.alive = false
	self.votes[source] = nil
	self.nightActions[source] = nil

	if self.host == source then
		for src, p in pairs(self.players) do
			if src ~= source and not p.disconnected then
				self.host = src
				break
			end
		end
	end
end

function Room:RemovePlayer(source)
	self.players[source] = nil
	self.votes[source] = nil
	self.nightActions[source] = nil
	self.investigateResults[source] = nil
	self.witchPotions[source] = nil

	if self.host == source then
		local nextHost = nil
		for src in pairs(self.players) do
			nextHost = src
			break
		end
		self.host = nextHost
	end
end

function Room:GetPlayerCount()
	return TableCount(self.players)
end

function Room:AllReady()
	for _, player in pairs(self.players) do
		if not player.ready then return false end
	end
	return true
end

function Room:AddLog(message)
	self.logs[#self.logs + 1] = {
		text = message,
		time = os.time(),
	}
end

function Room:ClearTimer()
	self.timerEnd = 0
end

function Room:SetTimer(seconds, onEnd)
	self:ClearTimer()
	self.timerEnd = os.time() + seconds
	if self.timerThread then
		self.timerThread = false
	end

	local threadId = {}
	self.timerThread = threadId
	CreateThread(function()
		Wait(seconds * 1000)
		if self.timerThread == threadId and onEnd then
			onEnd()
		end
	end)
end

function Room:GetRemainingTime()
	if self.timerEnd <= 0 then return 0 end
	return math.max(0, self.timerEnd - os.time())
end

function Room:AssignRoles()
	local count = self:GetPlayerCount()
	local deck = BuildRoleDeck(count)
	if not deck then return false end

	local sources = Shuffle(TableKeys(self.players))
	for i, source in ipairs(sources) do
		local player = self.players[source]
		player.role = deck[i]
		player.alive = true

		if player.role == Game.Roles.WITCH then
			self.witchPotions[source] = { save = true, poison = true }
		end
	end

	return true
end

function Room:GetWerewolfPartners(forSource)
	local partners = {}
	for src, player in pairs(self.players) do
		if src ~= forSource and player.alive and Game.IsWerewolf(player.role) then
			partners[#partners + 1] = { source = src, name = player.name }
		end
	end
	return partners
end

function Room:CanPlayerAct(source)
	if self.state == Game.Phases.ENDED then return false end
	local player = self.players[source]
	if not player or not player.alive then return false end

	if self.state == Game.Phases.NIGHT then
		if self.nightPhase == Game.NightPhases.WEREWOLF then
			return Game.IsWerewolf(player.role)
		elseif self.nightPhase == Game.NightPhases.WITCH then
			return player.role == Game.Roles.WITCH
		elseif self.nightPhase == Game.NightPhases.DOCTOR then
			return player.role == Game.Roles.DOCTOR
		elseif self.nightPhase == Game.NightPhases.SEER then
			return player.role == Game.Roles.SEER
		end
	elseif self.state == Game.Phases.VOTING then
		return true
	elseif self.state == Game.Phases.DAY and self.pendingHunter == source then
		return player.role == Game.Roles.HUNTER
	end

	return false
end

function Room:GetActionType(source)
	if self.state == Game.Phases.NIGHT then
		return self.nightPhase
	elseif self.state == Game.Phases.VOTING then
		return 'vote'
	elseif self.state == Game.Phases.DAY and self.pendingHunter == source then
		return 'hunter'
	end
end

function Room:BuildClientState(forSource)
	local players = {}
	for src, player in pairs(self.players) do
		local entry = {
			source = src,
			name = player.name,
			alive = player.alive,
			ready = player.ready,
			disconnected = player.disconnected or false,
			hasVoted = self.votes[src] ~= nil,
			hasActed = self.nightActions[src] ~= nil,
		}

		if src == forSource then
			entry.role = player.role
			entry.isMe = true
		elseif not player.alive and self.state == Game.Phases.ENDED then
			entry.role = player.role
		end

		players[#players + 1] = entry
	end

	table.sort(players, function(a, b)
		return a.source < b.source
	end)

	local myPlayer = self.players[forSource]
	local lobbyConfig = self.lobbySlot and GetLobbyConfig(self.lobbySlot)
	local clientState = {
		id = self.id,
		host = self.host,
		lobbySlot = self.lobbySlot,
		lobbyLabel = lobbyConfig and lobbyConfig.label or nil,
		state = self.state,
		nightPhase = self.nightPhase,
		round = self.round,
		players = players,
		logs = self.logs,
		winner = self.winner,
		timer = self:GetRemainingTime(),
		canAct = self:CanPlayerAct(forSource),
		actionType = self:GetActionType(forSource),
		myRole = myPlayer and myPlayer.role,
		myAlive = myPlayer and myPlayer.alive,
		werewolfPartners = Game.IsWerewolf(myPlayer and myPlayer.role) and self:GetWerewolfPartners(forSource) or nil,
		investigateResult = self.investigateResults[forSource],
		witchPotions = self.witchPotions[forSource],
		werewolfTarget = (myPlayer and myPlayer.role == Game.Roles.WITCH and self.nightPhase == Game.NightPhases.WITCH) and self.werewolfKillTarget or nil,
		pendingHunter = self.pendingHunter == forSource,
		playerCount = self:GetPlayerCount(),
		minPlayers = Config.Main.MinPlayers,
		maxPlayers = Config.Main.MaxPlayers,
		maxLobbies = Config.Main.MaxLobbies,
	}

	return clientState
end

function Room:StartGame()
	if self.state ~= Game.Phases.LOBBY then return false, 'Phòng không ở trạng thái chờ' end

	local count = self:GetPlayerCount()
	if count < Config.Main.MinPlayers then
		return false, ('Cần ít nhất %s người chơi'):format(Config.Main.MinPlayers)
	end

	if not self:AssignRoles() then
		return false, 'Không thể phân vai cho số người này'
	end

	self.round = 1
	self.state = Game.Phases.NIGHT
	self.nightPhase = Game.NightPhases.WEREWOLF
	self.votes = {}
	self.nightActions = {}
	self.nightDeaths = {}
	self.werewolfKillTarget = nil
	self:AddLog(('Đêm %s bắt đầu. Mọi người nhắm mắt...'):format(self.round))
	return true
end

function Room:RecordNightAction(source, action, target)
	local player = self.players[source]
	if not player or not player.alive then return false, 'Bạn không thể hành động' end

	if self.nightActions[source] then return false, 'Bạn đã chọn rồi' end

	if action == 'skip' then
		self.nightActions[source] = 'skip'
		return true
	end

	if not self.players[target] or not self.players[target].alive then
		return false, 'Mục tiêu không hợp lệ'
	end

	if self.nightPhase == Game.NightPhases.WEREWOLF and not Game.IsWerewolf(player.role) then
		return false, 'Bạn không phải Ma Sói'
	elseif self.nightPhase == Game.NightPhases.WITCH and player.role ~= Game.Roles.WITCH then
		return false, 'Bạn không phải Phù Thủy'
	elseif self.nightPhase == Game.NightPhases.DOCTOR and player.role ~= Game.Roles.DOCTOR then
		return false, 'Bạn không phải Bác Sĩ'
	elseif self.nightPhase == Game.NightPhases.SEER and player.role ~= Game.Roles.SEER then
		return false, 'Bạn không phải Tiên Tri'
	end

	if self.nightPhase == Game.NightPhases.WITCH then
		if action == 'save' then
			local potions = self.witchPotions[source]
			if not potions or not potions.save then return false, 'Đã hết lọ cứu' end
			potions.save = false
		elseif action == 'poison' then
			local potions = self.witchPotions[source]
			if not potions or not potions.poison then return false, 'Đã hết lọ độc' end
			potions.poison = false
		elseif action ~= 'skip' then
			return false, 'Hành động không hợp lệ'
		end
	end

	self.nightActions[source] = { action = action, target = target }
	return true
end

function Room:AllNightActorsDone()
	local required = {}

	if self.nightPhase == Game.NightPhases.WEREWOLF then
		required = GetPlayersByRole(self, Game.Roles.WEREWOLF)
	elseif self.nightPhase == Game.NightPhases.WITCH then
		required = GetPlayersByRole(self, Game.Roles.WITCH)
	elseif self.nightPhase == Game.NightPhases.DOCTOR then
		required = GetPlayersByRole(self, Game.Roles.DOCTOR)
	elseif self.nightPhase == Game.NightPhases.SEER then
		required = GetPlayersByRole(self, Game.Roles.SEER)
	end

	if #required == 0 then return true end

	for _, src in ipairs(required) do
		if not self.nightActions[src] then
			return false
		end
	end
	return true
end

function Room:ResolveWerewolfPhase()
	local votes = {}
	for src, action in pairs(self.nightActions) do
		local player = self.players[src]
		if player and Game.IsWerewolf(player.role) and action ~= 'skip' and action.target then
			votes[#votes + 1] = action.target
		end
	end

	self.werewolfKillTarget = MajorityVote(votes)
end

function Room:ResolveWitchPhase()
	for src, action in pairs(self.nightActions) do
		local player = self.players[src]
		if player and player.role == Game.Roles.WITCH and type(action) == 'table' then
			if action.action == 'save' and self.werewolfKillTarget then
				self.werewolfKillTarget = nil
			elseif action.action == 'poison' and action.target then
				self.nightDeaths[#self.nightDeaths + 1] = action.target
			end
		end
	end
end

function Room:ResolveDoctorPhase()
	local protected = nil
	for src, action in pairs(self.nightActions) do
		local player = self.players[src]
		if player and player.role == Game.Roles.DOCTOR and type(action) == 'table' and action.target then
			protected = action.target
		end
	end

	if protected and self.werewolfKillTarget == protected then
		self.werewolfKillTarget = nil
	end
end

function Room:ResolveSeerPhase()
	for src, action in pairs(self.nightActions) do
		local player = self.players[src]
		if player and player.role == Game.Roles.SEER and type(action) == 'table' and action.target then
			local target = self.players[action.target]
			if target then
				local alignment = Game.GetAlignment(target.role)
				self.investigateResults[src] = {
					target = action.target,
					targetName = target.name,
					result = alignment == 'werewolf' and 'Ma Sói' or 'Dân Làng',
					isWerewolf = alignment == 'werewolf',
				}
			end
		end
	end
end

function Room:ApplyNightDeaths()
	if self.werewolfKillTarget then
		self.nightDeaths[#self.nightDeaths + 1] = self.werewolfKillTarget
	end

	local uniqueDeaths = {}
	for _, src in ipairs(self.nightDeaths) do
		uniqueDeaths[src] = true
	end

	for src in pairs(uniqueDeaths) do
		local player = self.players[src]
		if player and player.alive then
			player.alive = false
			self:AddLog(('%s đã chết trong đêm.'):format(player.name))
		end
	end

	self.nightDeaths = {}
	self.werewolfKillTarget = nil
end

function Room:CheckWin()
	local werewolves, villagers = CountAliveByTeam(self)
	if werewolves <= 0 then
		self.winner = 'villager'
		self.state = Game.Phases.ENDED
		self:AddLog('Phe Dân Làng chiến thắng!')
		return true
	end
	if werewolves >= villagers then
		self.winner = 'werewolf'
		self.state = Game.Phases.ENDED
		self:AddLog('Phe Ma Sói chiến thắng!')
		return true
	end
	return false
end

function Room:BeginDay()
	self.state = Game.Phases.DAY
	self.nightPhase = nil
	self.votes = {}
	self.nightActions = {}
	self:AddLog(('Ngày %s bắt đầu. Hãy thảo luận!'):format(self.round))
end

function Room:BeginVoting()
	self.state = Game.Phases.VOTING
	self.votes = {}
	self:AddLog('Bắt đầu bỏ phiếu loại người chơi.')
end

function Room:RecordVote(source, target)
	local player = self.players[source]
	if not player or not player.alive then return false, 'Bạn không thể bỏ phiếu' end
	if self.state ~= Game.Phases.VOTING then return false, 'Chưa đến phase bỏ phiếu' end

	if target and (not self.players[target] or not self.players[target].alive) then
		return false, 'Mục tiêu không hợp lệ'
	end

	self.votes[source] = target or false
	return true
end

function Room:AllVotersDone()
	for src, player in pairs(self.players) do
		if player.alive and self.votes[src] == nil then
			return false
		end
	end
	return true
end

function Room:ResolveVote()
	local tally = {}
	for _, target in pairs(self.votes) do
		if target then
			tally[target] = (tally[target] or 0) + 1
		end
	end

	local voteTarget, maxVotes, tie = nil, 0, false
	for target, count in pairs(tally) do
		if count > maxVotes then
			maxVotes = count
			voteTarget = target
			tie = false
		elseif count == maxVotes then
			tie = true
		end
	end

	if tie or not voteTarget then
		self:AddLog('Không có ai bị loại (hòa phiếu).')
		return nil
	end

	local player = self.players[voteTarget]
	if not player then return nil end

	player.alive = false
	self.dayDeath = voteTarget
	self:AddLog(('%s bị loại bởi bỏ phiếu.'):format(player.name))

	if player.role == Game.Roles.HUNTER then
		self.pendingHunter = voteTarget
		self.state = Game.Phases.DAY
		self:AddLog('Thợ Săn có thể bắn một người trước khi chết!')
		return voteTarget
	end

	return voteTarget
end

function Room:RecordHunterShot(source, target)
	if self.pendingHunter ~= source then return false, 'Bạn không thể bắn' end
	if not target or not self.players[target] or not self.players[target].alive then
		return false, 'Mục tiêu không hợp lệ'
	end

	local targetPlayer = self.players[target]
	targetPlayer.alive = false
	self:AddLog(('%s bị Thợ Săn bắn chết.'):format(targetPlayer.name))
	self.pendingHunter = nil
	return true
end

function Room:AdvanceNightPhase()
	self.nightActions = {}

	if self.nightPhase == Game.NightPhases.WEREWOLF then
		self:ResolveWerewolfPhase()
		self.nightPhase = Game.NightPhases.WITCH
		if #GetPlayersByRole(self, Game.Roles.WITCH) == 0 then
			return self:AdvanceNightPhase()
		end
		return Game.NightPhases.WITCH
	elseif self.nightPhase == Game.NightPhases.WITCH then
		self:ResolveWitchPhase()
		self.nightPhase = Game.NightPhases.DOCTOR
		if #GetPlayersByRole(self, Game.Roles.DOCTOR) == 0 then
			return self:AdvanceNightPhase()
		end
		return Game.NightPhases.DOCTOR
	elseif self.nightPhase == Game.NightPhases.DOCTOR then
		self:ResolveDoctorPhase()
		self.nightPhase = Game.NightPhases.SEER
		if #GetPlayersByRole(self, Game.Roles.SEER) == 0 then
			return self:AdvanceNightPhase()
		end
		return Game.NightPhases.SEER
	elseif self.nightPhase == Game.NightPhases.SEER then
		self:ResolveSeerPhase()
		self:ApplyNightDeaths()
		self.nightPhase = nil
		return 'resolved'
	end
end

function Room:StartNextNight()
	self.round = self.round + 1
	self.state = Game.Phases.NIGHT
	self.nightPhase = Game.NightPhases.WEREWOLF
	self.votes = {}
	self.nightActions = {}
	self.nightDeaths = {}
	self.werewolfKillTarget = nil
	self.dayDeath = nil
	self:AddLog(('Đêm %s bắt đầu.'):format(self.round))
end
