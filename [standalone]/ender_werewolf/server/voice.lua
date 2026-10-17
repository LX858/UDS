local VoiceResource = Config.Main.Voice.Resource or 'pma-voice'

local function IsVoiceEnabled()
	return Config.Main.Voice.Enabled and GetResourceState(VoiceResource) == 'started'
end

local function SetPlayerRadio(source, channel)
	if not IsVoiceEnabled() then return end
	pcall(function()
		exports[VoiceResource]:setPlayerRadio(source, channel or 0)
	end)
end

function BuildPlayerVoiceState(room, source, player)
	local voice = Config.Main.Voice
	local slot = room.lobbySlot
	local radio = 0
	local proximity = voice.DayProximity
	local mode = 'day'

	if not player.alive then
		mode = 'dead'
		proximity = voice.DeadProximity
	elseif room.state == Game.Phases.LOBBY or room.state == Game.Phases.DAY or room.state == Game.Phases.VOTING or room.state == Game.Phases.ENDED then
		mode = room.state
		proximity = voice.DayProximity
	elseif room.state == Game.Phases.NIGHT then
		mode = 'night'
		proximity = voice.NightProximity

		if room.nightPhase == Game.NightPhases.WEREWOLF and Game.IsWerewolf(player.role) then
			mode = 'werewolf_radio'
			radio = GetLobbyRadioChannel(slot)
			proximity = voice.WerewolfProximity or 0.0
		end
	end

	return {
		mode = mode,
		radio = radio,
		proximity = proximity,
		alive = player.alive,
		nightPhase = room.nightPhase,
		lobbySlot = slot,
	}
end

function ApplyRoomVoice(room)
	if not room or not room.lobbySlot then return end

	for src, player in pairs(room.players) do
		local voiceState = BuildPlayerVoiceState(room, src, player)
		SetPlayerRadio(src, voiceState.radio)
		TriggerClientEvent('ender_werewolf:client:applyVoice', src, voiceState)
	end
end

function ResetPlayerVoice(source)
	SetPlayerRadio(source, 0)
	TriggerClientEvent('ender_werewolf:client:resetVoice', source)
end

function TeleportPlayerToLobby(impl, room, source, isSpectator)
	if not room.lobbySlot then return end

	local player = room.players[source]
	if not player then return end

	local total = room:GetPlayerCount()
	local index = GetPlayerSlotIndex(room, source)
	local coords = GetLobbyPlayerCoords(room.lobbySlot, index, total, isSpectator)
	if not coords then return end

	TriggerClientEvent('ender_werewolf:client:teleport', source, {
		x = coords.x,
		y = coords.y,
		z = coords.z,
		w = coords.w,
	}, isSpectator and 'spectator' or 'lobby')
end

function TeleportRoomPlayers(impl, room, onlyAlive)
	for src, player in pairs(room.players) do
		if not onlyAlive or player.alive then
			TeleportPlayerToLobby(impl, room, src, not player.alive and room.state ~= Game.Phases.LOBBY)
		elseif not player.alive and room.state ~= Game.Phases.LOBBY then
			TeleportPlayerToLobby(impl, room, src, true)
		end
	end
end

function RestorePlayerPosition(impl, source, returnCoords)
	if returnCoords then
		TriggerClientEvent('ender_werewolf:client:teleport', source, returnCoords, 'return')
	end
	ResetPlayerVoice(source)
end

function OnPlayerJoinRoom(impl, room, source)
	local returnCoords = lib.callback.await('ender_werewolf:cb:getReturnCoords', source)
	local player = room.players[source]
	if player and returnCoords then
		player.returnCoords = returnCoords
	end

	TeleportPlayerToLobby(impl, room, source, false)
	ApplyRoomVoice(room)
end

function OnPlayerLeaveRoom(impl, source, player)
	if player and player.returnCoords then
		RestorePlayerPosition(impl, source, player.returnCoords)
	else
		ResetPlayerVoice(source)
		local hub = Config.Main.HubLocation
		if hub and hub.coords then
			TriggerClientEvent('ender_werewolf:client:teleport', source, {
				x = hub.coords.x,
				y = hub.coords.y,
				z = hub.coords.z,
				w = 0.0,
			}, 'return')
		end
	end
end

function OnPlayerDeathInRoom(impl, room, source)
	TeleportPlayerToLobby(impl, room, source, true)
	ApplyRoomVoice(room)
end

function OnRoomPhaseChange(impl, room)
	TeleportRoomPlayers(impl, room, false)
	ApplyRoomVoice(room)
end
