AnimationList = json.decode(LoadResourceFile(GetCurrentResourceName(), "animations.json"))
CurrentAnimation = nil
PlayerProps = {}
PlayerParticles = {}
SecondPropEmote = false
local emoteCooldownUntil = 0
ForbiddenZoneInstances = {}
InForbiddenZone = false

function IsPlayerInForbiddenZone(ped)
	if InForbiddenZone then return true end
	if not ForbiddenZoneInstances or #ForbiddenZoneInstances == 0 then return false end
	ped = ped or PlayerPedId()
	local coords = GetEntityCoords(ped)
	for _, zone in ipairs(ForbiddenZoneInstances) do
		if zone and zone.contains and zone:contains(coords) then
			return true
		end
	end
	return false
end
exports("IsPlayerInForbiddenZone", IsPlayerInForbiddenZone)

local function InitForbiddenZones()
	if not AK4Y.ForbiddenZones or not lib or not lib.zones then return end

	for _, zoneData in ipairs(AK4Y.ForbiddenZones) do
		local zoneType = zoneData.type or 'sphere'
		local data = {
			debug = zoneData.debug or false,
			onEnter = function(self)
				InForbiddenZone = true
				if CurrentAnimation then
					CancelEmote()
				end
				toggleMenu(false)
			end,
			onExit = function(self)
				local ped = PlayerPedId()
				local coords = GetEntityCoords(ped)
				local stillIn = false
				for _, z in ipairs(ForbiddenZoneInstances) do
					if z and z.contains and z:contains(coords) then
						stillIn = true
						break
					end
				end
				InForbiddenZone = stillIn
			end
		}

		if zoneType == 'sphere' then
			data.coords = zoneData.coords
			data.radius = zoneData.radius or 150.0
			table.insert(ForbiddenZoneInstances, lib.zones.sphere(data))
		elseif zoneType == 'box' then
			data.coords = zoneData.coords
			data.size = zoneData.size or vec3(10.0, 10.0, 10.0)
			data.rotation = zoneData.rotation or 0.0
			table.insert(ForbiddenZoneInstances, lib.zones.box(data))
		elseif zoneType == 'poly' then
			data.points = zoneData.points
			data.thickness = zoneData.thickness or 4.0
			table.insert(ForbiddenZoneInstances, lib.zones.poly(data))
		end
	end
end

function isDeadOrLaststand()
	if GetResourceState('qbx_medical') == 'started' then
		return exports.qbx_medical:IsDead() or exports.qbx_medical:IsLaststand()
	end
	return false
end

function isProgressActive()
	if lib and lib.progressActive then
		return lib.progressActive()
	end
	local success, result = pcall(function()
		return exports.ox_lib:progressActive()
	end)
	return success and result
end

function FindEmote(emoteName)
	for _, emote in ipairs(AnimationList) do
		if emote.name == emoteName then
			return emote
		end
	end
end

function EmoteCommand(_, args, _)
	if isDeadOrLaststand() then return end
	if isProgressActive() then return end
	if IsPlayerInForbiddenZone() then
		AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
		return
	end
	local emoteName = args[1]

	if emoteName then
		PlayEmote(emoteName)
	else
		toggleMenu()
	end
end

CreateThread(function()
	InitForbiddenZones()

	RegisterCommand('e', EmoteCommand, false)
	RegisterCommand('emote', EmoteCommand, false)
	RegisterKeyMapping("e", 'Open Emote Menu', 'keyboard', AK4Y.MenuKey)

	TriggerEvent('chat:addSuggestion', '/e', 'Play an emote',
		{ { name = "emotename", help = "dance, camera, sit or any valid emote." } })
	TriggerEvent('chat:addSuggestion', '/emote', 'Play an emote',
		{ { name = "emotename", help = "dance, camera, sit or any valid emote." } })

	local expression = GetResourceKvpString("ak4y_emotes:expression")

	if expression then
		SetFacialIdleAnimOverride(PlayerPedId(), expression)
	end

	local walkStyle = GetResourceKvpString("ak4y_emotes:walkStyle")

	if walkStyle then
		LoadAnimSet(walkStyle)
		SetPedMovementClipset(PlayerPedId(), walkStyle, 0.2)
		RemoveAnimSet(walkStyle)
	end

	while true do
		local sleep = 1000

		if CurrentAnimation and not IsPauseMenuActive() then
			sleep = 0
			local ped = PlayerPedId()

			if IsPedShooting(ped) then
				CancelEmote()
			end

			if IsControlPressed(0, 47) and CurrentAnimation.ptfx then
				PtfxStart()
				Wait(500)
				PtfxStop()
			end
		end

		Wait(sleep)
	end
end)

local function CanUseEmote(ped)
	if isDeadOrLaststand() then return false end
	if isProgressActive() then return false end
	if IsPlayerInForbiddenZone(ped) then
		AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
		return false
	end
	if IsPedInMeleeCombat(ped) or IsPedPerformingMeleeAction(ped) then
		return false
	end
	local success, isCooldown = pcall(function()
		return exports['XN_DevMode']:IsMeleeCooldownActive()
	end)
	if success and isCooldown then
		return false
	end
	local success, inIsland = pcall(function()
		return exports['neons_ddame']:inIsland()
	end)
	if success and inIsland then 
		return false
	end
	if LocalPlayer.state.inPvP then return false end
	if emoteCooldownUntil and GetGameTimer() < emoteCooldownUntil then
		return false
	end
	return true
end

function PlayEmote(emoteName, ped, target)
	ped = ped or PlayerPedId()
	if not CanUseEmote(ped) then return end

	local emote = FindEmote(emoteName)

	if not emote then return end

	toggleMenu(false)

	if emote.category == "expression" then
		if emote.anim == "normal" then
			ClearFacialIdleAnimOverride(ped)
			DeleteResourceKvp("ak4y_emotes:expression")
			return
		end

		SetFacialIdleAnimOverride(ped, emote.anim)
		SetResourceKvp("ak4y_emotes:expression", emote.anim)
	elseif emote.category == "walk" then
		if emote.anim == "default" then
			ResetPedMovementClipset(ped, 0.2)
			DeleteResourceKvp("ak4y_emotes:walkStyle")
			return
		end

		LoadAnimSet(emote.anim)
		SetPedMovementClipset(ped, emote.anim, 0.2)
		RemoveAnimSet(emote.anim)
		SetResourceKvp("ak4y_emotes:walkStyle", emote.anim)
	elseif emote.category == "shared" and not target then
		local closestPlayer, closestDist = GetClosestPlayer()

		if not closestPlayer or closestDist >= AK4Y.MaxDistanceForSharedEmotes then
			AK4Y.Notify(_U("no_players_nearby"), _U("error"), "error")

			return
		end

		TriggerServerEvent("ak4y_emotes:request", closestPlayer, emote.name, emote.target_emote, emote.label)

		AK4Y.Notify(_U("emote_request_sent"), _U("info"), "info")
	else
		local inVehicle = IsPedInAnyVehicle(ped, true)

		if not AK4Y.AllowedInCars and inVehicle then
			return
		end

		if ped == PlayerPedId() then
			CancelEmote()

			if IsPedArmed(ped, 7) then
				SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
			end
		end

		if emote.dict == "Scenario" then
			TaskStartScenarioInPlace(ped, emote.anim, 0, true)
		else
			local flag = 0

			if not inVehicle and emote.options then
				if emote.options.loop then
					flag += 1
				end

				if emote.options.moving then
					flag += 48
				end

				if emote.options.stuck then
					flag += 2
				end
			end

			local duration = emote.options and emote.options.duration or -1

			if emote.props then
				Wait(duration)

				for _, prop in ipairs(emote.props) do
					local p1, p2, p3, p4, p5, p6 = table.unpack(prop.placement)

					AddPropToPed(ped, prop.model, prop.bone, p1, p2, p3, p4, p5, p6)
				end
			end

			if target and target ~= -1 then
				local targetEmote = FindEmote(emote.target_emote)
				local attach = emote.attach or targetEmote.attach

				if attach then
					local bone = GetPedBoneIndex(target, attach.bone or 0)

					AttachEntityToEntity(ped, target, bone, attach.xPos or 0.0,
						attach.yPos or 0.0,
						attach.zPos or 0.0,
						attach.xRot or 0.0,
						attach.yRot or 0.0, attach.zRot or 0.0, false, false, false, true, 0,
						true)
				else
					local offset = emote.offset or targetEmote.offset

					function CalculatePos()
						local offX, offY, offZ, offW = 0.0, 1.0, 0.0, GetEntityHeading(target) + 180.0

						if offset then
							offX, offY, offZ, offW = offset.x or 0.0, offset.y or 1.0,
								offset.z or 0.0, offset.w or offW
						end

						local coords = GetOffsetFromEntityInWorldCoords(target, offX, offY, offZ)

						SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, true)
						SetEntityHeading(ped, offW + 0.0)
						FreezeEntityPosition(ped, true)
					end

					CalculatePos()

					CreateThread(function()
						while IsInPreview do
							CalculatePos()

							Wait(0)
						end
					end)
				end
			end

			LoadAnimDict(emote.dict)
			TaskPlayAnim(ped, emote.dict, emote.anim, 8.0, 8.0, duration, flag, 0.0, false, false, false)
			RemoveAnimDict(emote.dict)
		end

		if ped == PlayerPedId() then
			CurrentAnimation = emote
			if emote.cowdown or emote.cooldown or (emote.options and (emote.options.cowdown or emote.options.cooldown)) then
				emoteCooldownUntil = GetGameTimer() + (AK4Y.EmoteCooldownDuration or 3000)
			end
		end
	end
end

exports("PlayEmote", PlayEmote)
RegisterNuiCallback("playEmote", function(emoteName)
	PlayEmote(emoteName)
end)

local lastCancelTime = 0
RegisterCommand("cancel_emote", function()
	local ped = PlayerPedId()
	if not CanUseEmote(ped) then return end

	local cooldown = AK4Y.CancelCooldown or 3000
	if cooldown > 0 then
		local curTime = GetGameTimer()
		if curTime - lastCancelTime < cooldown then
			return
		end
		lastCancelTime = curTime
	end

	if CurrentAnimation then
		CancelEmote()
	elseif AK4Y.CancelHandsUp then
		PlayEmote("handsup")
	end
end, false)
RegisterKeyMapping("cancel_emote", 'Cancel Emote', 'keyboard', AK4Y.CancelKey)

for i = 1, 7 do
	RegisterCommand("e" .. i, function()
		if isDeadOrLaststand() then return end
		if isProgressActive() then return end
		if IsDisabledControlPressed(0, AK4Y.ShortcutKey) or IsControlPressed(0, AK4Y.ShortcutKey) then
			if IsPlayerInForbiddenZone() then
				AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
				return
			end
			Wait(250)
			SendNUIMessage({
				action = 'playerUseShortcut',
				usedKey = i
			})
		end
	end, false)

	RegisterKeyMapping("e" .. i, 'Play Saved Emote ' .. tostring(i), 'keyboard', tostring(i))
end

local lastRequest

RegisterCommand("accept_emote", function()
	if isDeadOrLaststand() then return end
	if isProgressActive() then return end
	if IsPlayerInForbiddenZone() then
		AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
		return
	end
	if lastRequest then
		TriggerServerEvent("ak4y_emotes:response", lastRequest, true)
		lastRequest = nil
		SendNUIMessage({
			action = 'closeRequest'
		})
	end
end, false)

RegisterCommand("deny_emote", function()
	if isDeadOrLaststand() then return end
	if isProgressActive() then return end
	if lastRequest then
		TriggerServerEvent("ak4y_emotes:response", lastRequest, false)
		lastRequest = nil
		SendNUIMessage({
			action = 'closeRequest'
		})
	end
end, false)

RegisterKeyMapping("accept_emote", 'Accept Emote Request', 'keyboard', AK4Y.AnimationAcceptKey)
RegisterKeyMapping("deny_emote", 'Deny Emote Request', 'keyboard', AK4Y.AnimationDeclineKey)

RegisterNetEvent("ak4y_emotes:sendRequest", function(request)
	AK4Y.Notify(_U("emote_request_received"), _U("info"), "info")

	SendNUIMessage({
		action = 'getRequest',
		senderData = request,
	})

	lastRequest = request
end)

RegisterNetEvent("ak4y_emotes:playSharedEmote", function(emoteName, targetPed)
	PlayEmote(emoteName, nil, targetPed == -1 and targetPed or NetToPed(targetPed))
end)

exports("CancelEmote", CancelEmote)
RegisterNetEvent("ak4y_emotes:cancelEmote", CancelEmote)

exports("GetPlayingEmote", function()
	return CurrentAnimation
end)

RegisterNetEvent("ak4y_emotes:notify", function(msg, desc, type)
	AK4Y.Notify(msg, desc, type)
end)

function GetClosestPlayer()
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	local peds = GetGamePool("CPed")
	local closest, closestDist = nil, 0

	for _, targetPed in ipairs(peds) do
		if IsPedAPlayer(targetPed) and targetPed ~= ped then
			local targetCoords = GetEntityCoords(targetPed)
			local distance = #(coords - targetCoords)

			if closest == nil or distance < closestDist then
				closest, closestDist = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed)), distance
			end
		end
	end

	return closest, closestDist
end

function LoadAnimDict(dict)
	local timer = GetGameTimer()

	while GetGameTimer() - timer < 2500 and not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(0)
	end
end

function LoadAnimSet(name)
	local timer = GetGameTimer()

	while GetGameTimer() - timer < 2500 and not HasAnimSetLoaded(name) do
		RequestAnimSet(name)
		Wait(0)
	end
end

function LoadModel(model)
	local timer = GetGameTimer()

	while GetGameTimer() - timer < 2500 and not HasModelLoaded(model) do
		RequestModel(model)
		Wait(0)
	end
end

function CancelEmote(ped)
	if emoteCooldownUntil and GetGameTimer() < emoteCooldownUntil then
		return
	end
	if CurrentAnimation then
		ped = ped or PlayerPedId()

		DetachEntity(ped, true, true)
		SetEntityCollision(ped, true, true)
		FreezeEntityPosition(ped, false)


		if CurrentAnimation.dict == "Scenario" then
			ClearPedTasksImmediately(ped)
			ClearAreaOfObjects(GetEntityCoords(ped), 3.0, 0)
		else
			PtfxStop()
			ClearPedTasks(ped)
			DestroyAllProps()
		end

		if CurrentAnimation.category == "shared" then
			TriggerServerEvent("ak4y_emotes:cancelShared")
		end


		CurrentAnimation = nil
	end
end

function AddPropToPed(ped, model, bone, off1, off2, off3, rot1, rot2, rot3)
	LoadModel(model)

	local x, y, z = table.unpack(GetEntityCoords(ped))

	local prop = CreateObject(GetHashKey(model), x, y, z + 0.2, ped == PlayerPedId(), true, true)

	-- Fix prop collision với xe cộ - tắt physics và collision
	SetEntityCollision(prop, false, false) -- Tắt hoàn toàn collision của prop
	SetEntityNoCollisionEntity(prop, ped, false) -- Không collision với ped
	SetEntityHasGravity(prop, false) -- Tắt gravity để prop không rơi
	SetEntityDynamic(prop, false) -- Tắt physics động
	
	-- Disable collision với tất cả vehicles xung quanh
	local vehicles = GetGamePool("CVehicle")
	for _, vehicle in ipairs(vehicles) do
		SetEntityNoCollisionEntity(prop, vehicle, false)
	end

	AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone), off1, off2, off3, rot1, rot2, rot3, true, true,
		true, true, 1, true)

	if ped == PlayerPedId() then
		table.insert(PlayerProps, prop)
		
		-- Thread để liên tục disable collision với xe mới spawn
		CreateThread(function()
			while DoesEntityExist(prop) do
				local nearbyVehicles = GetGamePool("CVehicle")
				for _, veh in ipairs(nearbyVehicles) do
					if DoesEntityExist(veh) then
						SetEntityNoCollisionEntity(prop, veh, false)
					end
				end
				Wait(500)
			end
		end)
	else
		table.insert(FakeProps, prop)
		SetEntityAlpha(prop, 150, true)
	end
end

function DestroyAllProps()
	for _, prop in pairs(PlayerProps) do
		DeleteEntity(prop)
	end

	PlayerProps = {}
end

function PtfxStart()
	local ptfx = CurrentAnimation.ptfx
	local ptfxAt = ptfx.no_prop and PlayerPedId() or PlayerProps[1]
	local p1, p2, p3, p4, p5, p6 = table.unpack(ptfx.placement)

	UseParticleFxAssetNextCall(ptfx.asset)

	local particle = StartNetworkedParticleFxLoopedOnEntityBone(ptfx.name, ptfxAt, p1, p2, p3, p4, p5, p6,
		GetEntityBoneIndexByName(ptfx.name, "VFX"), 1065353216, 0, 0, 0, 1065353216, 1065353216, 1065353216, 0)

	SetParticleFxLoopedColour(particle, 1.0, 1.0, 1.0)

	table.insert(PlayerParticles, particle)
end

function PtfxStop()
	for _, particle in pairs(PlayerParticles) do
		StopParticleFxLooped(particle, false)
	end

	PlayerParticles = {}
end

UILoaded = false
UIOpen = false

function toggleMenu(override)
	if not UILoaded then return end
	if isDeadOrLaststand() then return end
	
	local targetState
	if type(override) == "boolean" then
		targetState = override
	else
		targetState = not UIOpen
	end

	if targetState and isProgressActive() then
		return
	end

	if targetState and IsPlayerInForbiddenZone(PlayerPedId()) then
		AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
		return
	end

	-- Không cho mở menu khi đang ở trên xe
	if targetState and IsPedInAnyVehicle(PlayerPedId(), false) then
		return
	end

	UIOpen = targetState

	SetNuiFocus(UIOpen, UIOpen)
	SendNUIMessage({
		action = 'display',
		payload = UIOpen
	})
end

RegisterCommand("emotes", function()
	if isDeadOrLaststand() then return end
	if isProgressActive() then return end
	if IsPlayerInForbiddenZone() then
		AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
		return
	end
	toggleMenu()
end, false)

RegisterNuiCallback("closeMenu", function()
	toggleMenu(false)
end)


RegisterNuiCallback('loaded', function(_, cb)
	UILoaded = true

	cb({
		locales = Locales[AK4Y.Language],
		animationList = AnimationList,
	})
end)


RegisterCommand('anim',function()
	if isDeadOrLaststand() then return end
	if isProgressActive() then return end
	if IsPlayerInForbiddenZone() then
		AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
		return
	end
	toggleMenu(true)
end)