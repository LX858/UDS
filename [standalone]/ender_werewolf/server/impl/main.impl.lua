---@class SVMainImpl : Impl
local Impl = NewImpl('Main')

function Impl:Init()
	self.rooms = {}
	self.playerRooms = {}
end

function Impl:OnReady()
	self:LogInfo('ready')
	self:RegisterCallbacks()
	self:RegisterEvents()
	self:RegisterCommands()
	self:Exports()
end

function Impl:GetRoomByPlayer(source)
	local roomId = self.playerRooms[source]
	if not roomId then return end
	return self.rooms[roomId]
end

function Impl:GetActiveLobbyCount()
	return TableCount(self.rooms)
end

function Impl:SyncRoom(room, refreshWorld)
	if refreshWorld then
		TeleportRoomPlayers(self, room, false)
	end

	for src in pairs(room.players) do
		TriggerClientEvent('ender_werewolf:client:syncRoom', src, room:BuildClientState(src))
	end

	ApplyRoomVoice(room)
end

function Impl:RefreshDeadPlayers(room)
	for src, player in pairs(room.players) do
		if not player.alive and room.state ~= Game.Phases.LOBBY then
			TeleportPlayerToLobby(self, room, src, true)
		end
	end
	ApplyRoomVoice(room)
end

function Impl:NotifyRoom(room, message, notifyType)
	for src in pairs(room.players) do
		NotifyPlayer(src, message, notifyType)
	end
end

function Impl:ReleaseRoom(room)
	if not room then return end
	for src, player in pairs(room.players) do
		OnPlayerLeaveRoom(self, src, player)
		self.playerRooms[src] = nil
	end
	self.rooms[room.id] = nil
end

function Impl:RemovePlayerFromRoom(source, reason)
	local room = self:GetRoomByPlayer(source)
	if not room then return end

	local player = room.players[source]
	room:RemovePlayer(source)
	self.playerRooms[source] = nil
	OnPlayerLeaveRoom(self, source, player)

	if room:GetPlayerCount() == 0 then
		self.rooms[room.id] = nil
		return
	end

	if reason then
		room:AddLog(reason)
	end

	if room.state == Game.Phases.LOBBY then
		self:SyncRoom(room, true)
		return
	end

	self:SyncRoom(room, true)
end

function Impl:OnPlayerDisconnected(source)
	local room = self:GetRoomByPlayer(source)
	if not room then return end

	local player = room.players[source]
	if not player then return end

	if room.state == Game.Phases.LOBBY then
		self:RemovePlayerFromRoom(source, ('%s đã rời phòng.'):format(player.name))
		return
	end

	room:MarkDisconnected(source)
	self.playerRooms[source] = nil
	room:AddLog(('%s mất kết nối.'):format(player.name))

	if room:CheckWin() then
		self:SyncRoom(room, true)
		return
	end

	self:SyncRoom(room, false)
end

function Impl:CreateRoom(source)
	if self.playerRooms[source] then
		return false, 'Bạn đã ở trong một phòng'
	end

	if self:GetActiveLobbyCount() >= Config.Main.MaxLobbies then
		return false, ('Đã đạt tối đa %s phòng cùng lúc'):format(Config.Main.MaxLobbies)
	end

	local lobbySlot = GetFreeLobbySlot(self.rooms)
	if not lobbySlot then
		return false, 'Không còn khu vực lobby trống'
	end

	local playerData = GetClientPlayerData(source)
	if not playerData then return false, 'Không tìm thấy người chơi' end

	local roomId
	repeat
		roomId = GenerateRoomCode(Config.Main.RoomCodeLength)
	until not self.rooms[roomId]

	local room = Room(roomId, source, playerData, lobbySlot)
	self.rooms[roomId] = room
	self.playerRooms[source] = roomId

	local lobbyLabel = GetLobbyConfig(lobbySlot).label
	room:AddLog(('%s đã tạo phòng tại %s.'):format(playerData.name, lobbyLabel))
	OnPlayerJoinRoom(self, room, source)
	self:SyncRoom(room)
	return true, roomId
end

function Impl:JoinRoom(source, roomId)
	if self.playerRooms[source] then
		return false, 'Bạn đã ở trong một phòng'
	end

	roomId = type(roomId) == 'string' and roomId:upper() or nil
	local room = roomId and self.rooms[roomId]
	if not room then return false, 'Không tìm thấy phòng' end
	if room.state ~= Game.Phases.LOBBY then return false, 'Trò chơi đã bắt đầu' end
	if room:GetPlayerCount() >= Config.Main.MaxPlayers then return false, 'Phòng đã đầy' end

	local playerData = GetClientPlayerData(source)
	if not playerData then return false, 'Không tìm thấy người chơi' end

	room:AddPlayer(source, playerData)
	self.playerRooms[source] = roomId
	room:AddLog(('%s đã tham gia phòng.'):format(playerData.name))
	OnPlayerJoinRoom(self, room, source)
	self:SyncRoom(room, true)
	return true
end

function Impl:LeaveRoom(source)
	local room = self:GetRoomByPlayer(source)
	if not room then return false, 'Bạn không ở trong phòng nào' end

	if room.state ~= Game.Phases.LOBBY and room.state ~= Game.Phases.ENDED then
		return false, 'Không thể rời khi trận đang diễn ra'
	end

	local name = room.players[source] and room.players[source].name or 'Ai đó'
	self:RemovePlayerFromRoom(source, ('%s đã rời phòng.'):format(name))
	return true
end

function Impl:SetReady(source, ready)
	local room = self:GetRoomByPlayer(source)
	if not room or room.state ~= Game.Phases.LOBBY then return false end
	local player = room.players[source]
	if not player then return false end
	player.ready = ready and true or false
	self:SyncRoom(room)
	return true
end

function Impl:StartGame(source)
	local room = self:GetRoomByPlayer(source)
	if not room then return false, 'Bạn không ở trong phòng nào' end
	if room.host ~= source then return false, 'Chỉ chủ phòng mới có thể bắt đầu' end

	local ok, err = room:StartGame()
	if not ok then return false, err end

	self:NotifyRoom(room, 'Trò chơi bắt đầu! Kiểm tra vai trò của bạn.', 'success')
	self:SyncRoom(room, true)
	self:BeginNightPhase(room)
	return true
end

function Impl:BeginNightPhase(room)
	if room.state ~= Game.Phases.NIGHT then return end

	local phaseLabel = {
		werewolf = 'Ma Sói đang chọn nạn nhân',
		witch = 'Phù Thủy đang hành động',
		doctor = 'Bác Sĩ đang bảo vệ',
		seer = 'Tiên Tri đang điều tra',
	}

	room:AddLog(phaseLabel[room.nightPhase] or 'Ban đêm')
	self:SyncRoom(room, true)

	room:SetTimer(Config.Main.Timers.NightRole, function()
		self:OnNightPhaseTimeout(room)
	end)
end

function Impl:OnNightPhaseTimeout(room)
	if room.state ~= Game.Phases.NIGHT then return end

	local result = room:AdvanceNightPhase()
	if result == 'resolved' then
		self:RefreshDeadPlayers(room)
		if room:CheckWin() then
			self:SyncRoom(room, true)
			return
		end
		self:BeginDayPhase(room)
		return
	end

	self:BeginNightPhase(room)
end

function Impl:BeginDayPhase(room)
	room:BeginDay()
	self:NotifyRoom(room, 'Ban ngày — hãy thảo luận bằng voice trong khu lobby!', 'inform')
	self:SyncRoom(room, true)

	room:SetTimer(Config.Main.Timers.Discussion, function()
		self:BeginVotePhase(room)
	end)
end

function Impl:BeginVotePhase(room)
	if room.state ~= Game.Phases.DAY and room.pendingHunter then return end
	if room.pendingHunter then return end

	room:BeginVoting()
	self:NotifyRoom(room, 'Hãy bỏ phiếu loại người nghi ngờ!', 'inform')
	self:SyncRoom(room, true)

	room:SetTimer(Config.Main.Timers.Voting, function()
		self:OnVoteTimeout(room)
	end)
end

function Impl:OnVoteTimeout(room)
	if room.state ~= Game.Phases.VOTING then return end

	room:ResolveVote()
	self:RefreshDeadPlayers(room)

	if room.pendingHunter then
		self:SyncRoom(room, true)
		room:SetTimer(Config.Main.Timers.HunterShot, function()
			room.pendingHunter = nil
			if room:CheckWin() then
				self:SyncRoom(room, true)
				return
			end
			self:StartNextRound(room)
		end)
		return
	end

	if room:CheckWin() then
		self:SyncRoom(room, true)
		return
	end

	self:StartNextRound(room)
end

function Impl:StartNextRound(room)
	room:StartNextNight()
	self:BeginNightPhase(room)
end

function Impl:NightAction(source, data)
	local room = self:GetRoomByPlayer(source)
	if not room or room.state ~= Game.Phases.NIGHT then return false, 'Không thể hành động' end

	local ok, err = room:RecordNightAction(source, data.action, data.target)
	if not ok then return false, err end

	if room:AllNightActorsDone() then
		room:ClearTimer()
		self:OnNightPhaseTimeout(room)
	else
		self:SyncRoom(room)
	end

	return true
end

function Impl:Vote(source, target)
	local room = self:GetRoomByPlayer(source)
	if not room or room.state ~= Game.Phases.VOTING then return false, 'Không thể bỏ phiếu' end

	local ok, err = room:RecordVote(source, target)
	if not ok then return false, err end

	if room:AllVotersDone() then
		room:ClearTimer()
		self:OnVoteTimeout(room)
	else
		self:SyncRoom(room)
	end

	return true
end

function Impl:HunterShot(source, target)
	local room = self:GetRoomByPlayer(source)
	if not room then return false, 'Không ở trong phòng' end

	local ok, err = room:RecordHunterShot(source, target)
	if not ok then return false, err end

	room:ClearTimer()
	self:RefreshDeadPlayers(room)

	if room:CheckWin() then
		self:SyncRoom(room, true)
		return true
	end

	self:StartNextRound(room)
	return true
end

function Impl:KickPlayer(source, target)
	local room = self:GetRoomByPlayer(source)
	if not room or room.host ~= source then return false, 'Không có quyền' end
	if not room.players[target] then return false, 'Người chơi không tồn tại' end
	if target == source then return false, 'Không thể kick chính mình' end
	if room.state ~= Game.Phases.LOBBY then return false, 'Không thể kick khi trận đang diễn ra' end

	self:RemovePlayerFromRoom(target, ('%s bị chủ phòng kick.'):format(room.players[target].name))
	NotifyPlayer(target, 'Bạn đã bị kick khỏi phòng Werewolf', 'error')
	return true
end

function Impl:RegisterCallbacks()
	lib.callback.register('ender_werewolf:cb:getState', function(source)
		local room = self:GetRoomByPlayer(source)
		if not room then return nil end
		return room:BuildClientState(source)
	end)

	lib.callback.register('ender_werewolf:cb:getLobbyInfo', function(source)
		return {
			activeLobbies = self:GetActiveLobbyCount(),
			maxLobbies = Config.Main.MaxLobbies,
		}
	end)

	lib.callback.register('ender_werewolf:cb:createRoom', function(source)
		return self:CreateRoom(source)
	end)

	lib.callback.register('ender_werewolf:cb:joinRoom', function(source, roomId)
		return self:JoinRoom(source, roomId)
	end)

	lib.callback.register('ender_werewolf:cb:leaveRoom', function(source)
		return self:LeaveRoom(source)
	end)

	lib.callback.register('ender_werewolf:cb:setReady', function(source, ready)
		return self:SetReady(source, ready)
	end)

	lib.callback.register('ender_werewolf:cb:startGame', function(source)
		return self:StartGame(source)
	end)

	lib.callback.register('ender_werewolf:cb:nightAction', function(source, data)
		return self:NightAction(source, data)
	end)

	lib.callback.register('ender_werewolf:cb:vote', function(source, target)
		return self:Vote(source, target)
	end)

	lib.callback.register('ender_werewolf:cb:hunterShot', function(source, target)
		return self:HunterShot(source, target)
	end)

	lib.callback.register('ender_werewolf:cb:kickPlayer', function(source, target)
		return self:KickPlayer(source, target)
	end)
end

function Impl:RegisterEvents()
	AddEventHandler('playerDropped', function()
		self:OnPlayerDisconnected(source)
	end)
end

function Impl:RegisterCommands()
	RegisterCommand('wwadmin', function(src, args)
		if src == 0 then return end
		if not IsPlayerAdmin(src) then
			NotifyPlayer(src, 'Không có quyền', 'error')
			return
		end

		local action = args[1]
		if action == 'list' then
			local count = 0
			for id, room in pairs(self.rooms) do
				count = count + 1
				local lobby = GetLobbyConfig(room.lobbySlot)
				print(('%s | %s | %s players | %s'):format(id, lobby and lobby.label or '?', room:GetPlayerCount(), room.state))
			end
			NotifyPlayer(src, ('Đang có %s/%s phòng'):format(count, Config.Main.MaxLobbies), 'inform')
		elseif action == 'close' and args[2] then
			local room = self.rooms[args[2]:upper()]
			if room then
				self:ReleaseRoom(room)
				NotifyPlayer(src, 'Đã đóng phòng', 'success')
			end
		end
	end, false)
end

function Impl:Exports()
	exports('GetRoomByPlayer', function(source)
		return self:GetRoomByPlayer(source)
	end)

	exports('GetRoom', function(roomId)
		return self.rooms[roomId]
	end)

	exports('GetActiveLobbyCount', function()
		return self:GetActiveLobbyCount()
	end)
end
