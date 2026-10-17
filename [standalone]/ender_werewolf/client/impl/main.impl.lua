---@class CLMainImpl : Impl
local Impl = NewImpl('Main')

function Impl:Init()
	self.isVisible = false
	self.roomState = nil
	self.nuiHudMode = false
	self.npcPed = nil
end

function Impl:OnReady()
	self:LogInfo('ready')
	self:RegisterEvents()
	self:RegisterCommands()
	self:NUICallbacks()
	self:RegisterClientCallbacks()
	self:CreateBlips()
	self:SetupNpc()
end

function Impl:IsInActiveMatch(room)
	if not room then return false end
	return room.state ~= 'lobby' and room.state ~= 'ended'
end

function Impl:UpdateNuiFocus()
	local nuiCfg = Config.Main.Nui or {}
	local keepInput = nuiCfg.KeepInputForVoice ~= false

	if not self.isVisible then
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		SendReactMessage('setHudMode', false)
		self.nuiHudMode = false
		WerewolfEnablePttPassthrough(false)
		local inMatch = self:IsInActiveMatch(self.roomState)
		WerewolfSetInputState(false, false, false, inMatch)
		return
	end

	local room = self.roomState
	local inMatch = self:IsInActiveMatch(room)

	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(keepInput)
	self.nuiHudMode = false
	WerewolfEnablePttPassthrough(keepInput and inMatch)
	WerewolfSetInputState(true, true, false, inMatch)

	SendReactMessage('setHudMode', self.nuiHudMode)
end

function Impl:RegisterClientCallbacks()
	lib.callback.register('ender_werewolf:cb:getReturnCoords', function()
		local ped = cache.ped or PlayerPedId()
		local coords = GetEntityCoords(ped)
		return {
			x = coords.x,
			y = coords.y,
			z = coords.z,
			w = GetEntityHeading(ped),
		}
	end)
end

function Impl:OpenUI()
	self:SendPlayerData()
	local state = lib.callback.await('ender_werewolf:cb:getState', false)
	self.roomState = state
	self:SyncToNui()
	self:ToggleUI(true)
end

function Impl:ToggleUI(state)
	if self.isVisible == state then
		if state then self:UpdateNuiFocus() end
		return
	end
	self.isVisible = state
	SendReactMessage('setVisible', state)
	if not state then
		SendReactMessage('resetUI', true)
	end
	self:UpdateNuiFocus()
end

function Impl:SendPlayerData()
	SendReactMessage('setPlayerData', GetClientPlayerData())
	SendReactMessage('setMyId', cache.serverId)
end

function Impl:SyncToNui()
	SendReactMessage('setRoomState', self.roomState)
end

function Impl:RegisterEvents()
	RegisterNetEvent('ender_werewolf:client:syncRoom', function(state)
		local hadCanAct = self.roomState and self.roomState.canAct
		self.roomState = state
		local inMatch = self:IsInActiveMatch(state)

		if inMatch or state.state == 'lobby' or state.state == 'ended' then
			if not self.isVisible then
				self:SendPlayerData()
				self.isVisible = true
				SendReactMessage('setVisible', true)
			end
		end

		if state.canAct and not hadCanAct then
			Notify('Đến lượt của bạn — chọn trên UI!', 'inform')
			if not self.isVisible then
				self:SendPlayerData()
				self.isVisible = true
				SendReactMessage('setVisible', true)
			end
		end

		if self.isVisible then
			self:SyncToNui()
			self:UpdateNuiFocus()
		end

		if state.state == 'night' and state.canAct and state.actionType == 'werewolf' then
			Notify('Ma Sói: giữ phím radio (mặc định LMENU) — chỉ đồng đội nghe được.', 'inform')
		elseif state.state == 'night' and state.canAct then
			Notify('Đến lượt hành động ban đêm của bạn!', 'inform')
		elseif state.state == 'voting' and state.canAct then
			Notify('Hãy bỏ phiếu!', 'inform')
		elseif state.state == 'ended' then
			local winner = state.winner == 'werewolf' and 'Ma Sói' or 'Dân Làng'
			Notify(('Trò chơi kết thúc! Phe %s thắng.'):format(winner), 'success')
		end
	end)
end

function Impl:RegisterCommands()
	if Config.Settings.UseCommand == false then return end

	local cmd = Config.Settings.Command
	local alias = Config.Settings.CommandAlias

	local openHandler = function()
		if self.isVisible then
			self:ToggleUI(false)
			return
		end
		self:OpenUI()
	end

	RegisterCommand(cmd, openHandler, false)
	if alias and alias ~= cmd then
		RegisterCommand(alias, openHandler, false)
	end

	RegisterKeyMapping(cmd, 'Mở Werewolf', 'keyboard', '')
end

function Impl:NUICallbacks()
	RegisterNUICallback('hideFrame', function(_, cb)
		cb(1)
		self:ToggleUI(false)
	end)

	RegisterNUICallback('createRoom', function(_, cb)
		local ok, result = lib.callback.await('ender_werewolf:cb:createRoom', false)
		if ok then
			Notify(('Đã tạo phòng: %s'):format(result), 'success')
			self.roomState = lib.callback.await('ender_werewolf:cb:getState', false)
			self:SyncToNui()
		else
			Notify(result or 'Không thể tạo phòng', 'error')
		end
		cb({ ok = ok, data = result })
	end)

	RegisterNUICallback('joinRoom', function(body, cb)
		local ok, result = lib.callback.await('ender_werewolf:cb:joinRoom', false, body.code)
		if ok then
			Notify('Đã tham gia phòng', 'success')
			self.roomState = lib.callback.await('ender_werewolf:cb:getState', false)
			self:SyncToNui()
		else
			Notify(result or 'Không thể tham gia', 'error')
		end
		cb({ ok = ok, message = result })
	end)

	RegisterNUICallback('leaveRoom', function(_, cb)
		local ok, err = lib.callback.await('ender_werewolf:cb:leaveRoom', false)
		if not ok then
			Notify(err or 'Không thể rời phòng', 'error')
			cb(0)
			return
		end
		self.roomState = nil
		self:SyncToNui()
		Notify('Đã rời phòng', 'inform')
		cb(1)
	end)

	RegisterNUICallback('setReady', function(body, cb)
		lib.callback.await('ender_werewolf:cb:setReady', false, body.ready)
		cb(1)
	end)

	RegisterNUICallback('startGame', function(_, cb)
		local ok, err = lib.callback.await('ender_werewolf:cb:startGame', false)
		if not ok then
			Notify(err or 'Không thể bắt đầu', 'error')
		end
		cb({ ok = ok, message = err })
	end)

	RegisterNUICallback('nightAction', function(body, cb)
		local ok, err = lib.callback.await('ender_werewolf:cb:nightAction', false, body)
		if not ok then
			Notify(err or 'Hành động thất bại', 'error')
		end
		cb({ ok = ok, message = err })
	end)

	RegisterNUICallback('vote', function(body, cb)
		local ok, err = lib.callback.await('ender_werewolf:cb:vote', false, body.target)
		if not ok then
			Notify(err or 'Bỏ phiếu thất bại', 'error')
		end
		cb({ ok = ok, message = err })
	end)

	RegisterNUICallback('hunterShot', function(body, cb)
		local ok, err = lib.callback.await('ender_werewolf:cb:hunterShot', false, body.target)
		if not ok then
			Notify(err or 'Không thể bắn', 'error')
		end
		cb({ ok = ok, message = err })
	end)

	RegisterNUICallback('kickPlayer', function(body, cb)
		local ok, err = lib.callback.await('ender_werewolf:cb:kickPlayer', false, body.target)
		if not ok then
			Notify(err or 'Không thể kick', 'error')
		end
		cb({ ok = ok, message = err })
	end)

	RegisterNUICallback('refreshState', function(_, cb)
		self.roomState = lib.callback.await('ender_werewolf:cb:getState', false)
		self:SyncToNui()
		cb(1)
	end)
end

function Impl:CreateBlips()
	if not Config.Main.Blip.enabled then return end
	local hub = Config.Main.HubLocation
	if hub and hub.coords then
		CreateBlip(hub.coords, Config.Main.Blip.label, Config.Main.Blip.sprite, Config.Main.Blip.scale,
			Config.Main.Blip.color)
	end
end

function Impl:SetupNpc()
	local npcCfg = Config.Main.Npc
	if not npcCfg or not npcCfg.enabled then return end
	if GetResourceState('ox_target') ~= 'started' then
		self:LogWarning('ox_target chưa chạy — NPC Werewolf bị tắt')
		return
	end
	self:SpawnNpc()
end

function Impl:SpawnNpc()
	local npcCfg = Config.Main.Npc
	if not npcCfg or not npcCfg.enabled then return end
	if self.npcPed and DoesEntityExist(self.npcPed) then return end

	local model = joaat(npcCfg.model or 'cs_priest')
	lib.requestModel(model, 10000)

	local c = npcCfg.coords
	local ped = CreatePed(0, model, c.x, c.y, c.z - 1.0, c.w or 0.0, false, false)
	if not ped or ped == 0 then
		self:LogError('Không thể spawn NPC model=%s', npcCfg.model)
		return
	end

	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, true)
	SetEntityAsMissionEntity(ped, true, true)
	SetPedCanRagdoll(ped, false)
	SetPedDiesWhenInjured(ped, false)

	if npcCfg.scenario then
		TaskStartScenarioInPlace(ped, npcCfg.scenario, 0, true)
	end

	SetModelAsNoLongerNeeded(model)
	self.npcPed = ped

	exports.ox_target:addLocalEntity(ped, {
		{
			name = 'ender_werewolf:open',
			icon = 'fas fa-moon',
			label = npcCfg.targetLabel or 'Chơi Werewolf',
			distance = npcCfg.targetDistance or 2.5,
			onSelect = function()
				self:OpenUI()
			end,
		},
	})
end

function Impl:DeleteNpc()
	if not self.npcPed or not DoesEntityExist(self.npcPed) then
		self.npcPed = nil
		return
	end

	exports.ox_target:removeLocalEntity(self.npcPed, { 'ender_werewolf:open' })
	DeleteEntity(self.npcPed)
	self.npcPed = nil
end

function Impl:OnResourceStop()
	self:DeleteNpc()
end
