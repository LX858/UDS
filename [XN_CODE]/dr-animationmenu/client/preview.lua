FakeProps = {}
IsInPreview = false
local KeyBinds = {
	{
		code = 24,
		label = "Play Animation",
	},
	{
		code = 25,
		label = "Cancel",
	},
	{
		code = 241,
		label = "Left",
	},
	{
		code = 242,
		label = "Right",
	},
}

function RotationToDirection(rotation)
	local radianZ = rotation.z * 0.0174532924
	local radianX = rotation.x * 0.0174532924

	local x = -math.sin(radianZ) * math.cos(radianX)
	local y = math.cos(radianZ) * math.cos(radianX)
	local z = math.sin(radianX)

	return vec3(x, y, z)
end

function RayCastGamePlayCamera(distance)
	local camCoord = GetGameplayCamCoord()
	local camRot = GetGameplayCamRot(0)
	local direction = RotationToDirection(camRot)
	local destination = camCoord + direction * distance

	local rayId = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, destination.x, destination.y, destination.z,
		4294967295,
		PlayerPedId(), 7)

	local _, hit, coords, _, entity = GetShapeTestResult(rayId)

	return hit, coords, entity, destination
end

function PreviewEmote(emoteName)
	if isDeadOrLaststand() then return end
	if isProgressActive() then return end
	if IsPlayerInForbiddenZone and IsPlayerInForbiddenZone() then
		AK4Y.Notify(_U("forbidden_zone"), _U("error"), "error")
		return
	end
	if not IsInPreview then
		local emote = FindEmote(emoteName)

		if not emote or emote.category == "expression" or emote.category == "walk" then return end

		IsInPreview = true

		CreateThread(function()
			local peds = { ClonePed(PlayerPedId(), false, false, true) }
			local ped = peds[1]

			if emote.category == "shared" then
				peds[2] = ClonePed(PlayerPedId(), false, false, true)
			end

			for _, p in ipairs(peds) do
				SetEntityInvincible(p, true)
				FreezeEntityPosition(p, true)
				SetEntityLocallyVisible(p)
				SetEntityAlpha(p, 150, false)
				SetEntityCollision(p, false, false)
				TaskSetBlockingOfNonTemporaryEvents(p, false)
			end

			PlayEmote(emoteName, ped, -1)
			if peds[2] then
				PlayEmote(emote.target_emote, peds[2], ped)
			end

			local scaleform = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")
			while not HasScaleformMovieLoaded(scaleform) do Wait(0); end

			PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
			PopScaleformMovieFunctionVoid()

			PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
			PushScaleformMovieFunctionParameterInt(200)
			PopScaleformMovieFunctionVoid()

			for i, key in ipairs(KeyBinds) do
				if emote.dict == "Scenario" and (key.label == "Left" or key.label == "Right") then
					goto continue
				end

				PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
				PushScaleformMovieFunctionParameterInt(i)
				ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(0, key.code, true))
				BeginTextCommandScaleformString("STRING")
				AddTextComponentScaleform(key.label)
				EndTextCommandScaleformString()
				PopScaleformMovieFunctionVoid()

				::continue::
			end

			if emote.dict == "Scenario" then
				PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
				PushScaleformMovieFunctionParameterInt(3)
				ScaleformMovieMethodAddParamPlayerNameString("")
				BeginTextCommandScaleformString("STRING")
				AddTextComponentScaleform("This is a scenario, you can't rotate it!")
				EndTextCommandScaleformString()
				PopScaleformMovieFunctionVoid()
			end

			PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
			PopScaleformMovieFunctionVoid()

			while IsInPreview and DoesEntityExist(ped) do
				local target

				if emote.dict ~= "Scenario" then
					local hit, hitcoords, _, destination = RayCastGamePlayCamera(AK4Y.MaxDistancesForPreview
						[GetFollowPedCamViewMode()])
					target = hitcoords

					if hit ~= 1 then
						local _, groundZ = GetGroundZFor_3dCoord(destination.x, destination.y, destination.z, true)

						target = vector3(destination.x, destination.y, groundZ)
					end

					SetEntityCoords(ped, target.x, target.y, target.z, false, false, false, false)
				else
					target = GetEntityCoords(ped)
					local dist = #(GetEntityCoords(PlayerPedId()) - target)

					if dist >= 10.0 then
						IsInPreview = false
						SetScaleformMovieAsNoLongerNeeded(scaleform)

						for _, ped in ipairs(peds) do
							DeleteEntity(ped)
						end

						for _, prop in ipairs(FakeProps) do
							DeleteEntity(prop)
						end

						FakeProps = {}
					end
				end

				DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

				for _, key in ipairs(KeyBinds) do
					DisableControlAction(0, key.code, true)

					if IsDisabledControlPressed(0, key.code) then
						if key.label == "Play Animation" or key.label == "Cancel" then
							SetScaleformMovieAsNoLongerNeeded(scaleform)

							if key.label == "Play Animation" then
								if emote.category ~= "shared" then
									local playerPed = PlayerPedId()
									TaskGoStraightToCoord(playerPed, target.x, target.y, target.z, 1.0, -1,
										GetEntityHeading(ped), 0.0)

									local timer = GetGameTimer()

									while #(GetEntityCoords(playerPed) - target) >= 1.001 do
										if GetGameTimer() - timer >= 3000 then
											break
										end

										Wait(250)
									end

									SetEntityCoords(playerPed, target.x, target.y, target.z, false, false, false, false)
									SetEntityHeading(playerPed, GetEntityHeading(ped))

									Wait(500)
								end

								PlayEmote(emoteName)
							end

							for _, p in ipairs(peds) do
								DeleteEntity(p)
							end

							for _, prop in ipairs(FakeProps) do
								DeleteEntity(prop)
							end

							FakeProps = {}
							IsInPreview = false
						elseif key.label == "Left" then
							SetEntityHeading(ped, GetEntityHeading(ped) + 7.5)
						elseif key.label == "Right" then
							SetEntityHeading(ped, GetEntityHeading(ped) - 7.5)
						end
					end
				end

				Wait(0)
			end

			SetScaleformMovieAsNoLongerNeeded(scaleform)
		end)
	end
end

RegisterNuiCallback("previewEmote", PreviewEmote)
