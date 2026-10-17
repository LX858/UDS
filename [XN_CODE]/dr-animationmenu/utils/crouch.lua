local isCrouching = false

-- Tải sẵn animset vào bộ nhớ để chuyển động ngồi tức thì không bị delay
CreateThread(function()
	RequestAnimSet('move_ped_crouched')
	RequestAnimSet('move_ped_crouched_strafing')
end)

local function ResetCrouch(ped)
	isCrouching = false
	ped = ped or PlayerPedId()
	ResetPedMovementClipset(ped, 0.25)
	ResetPedWeaponMovementClipset(ped)
	ResetPedStrafeClipset(ped)
	SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')

	local walkStyle = GetResourceKvpString("ak4y_emotes:walkStyle")
	if walkStyle then
		if not HasAnimSetLoaded(walkStyle) then
			LoadAnimSet(walkStyle)
		end
		SetPedMovementClipset(ped, walkStyle, 0.25)
	end
end

local function ToggleCrouch()
	if isDeadOrLaststand() then return end
	if isProgressActive() then return end
	local ped = PlayerPedId()

	if not IsPedSittingInAnyVehicle(ped) and not IsPedFalling(ped) and not IsPedSwimming(ped) and not IsPedSwimmingUnderWater(ped) and not IsPauseMenuActive() then
		if not isCrouching then
			isCrouching = true
			if not HasAnimSetLoaded('move_ped_crouched') then
				RequestAnimSet('move_ped_crouched')
				while not HasAnimSetLoaded('move_ped_crouched') do Wait(0) end
			end
			SetPedMovementClipset(ped, 'move_ped_crouched', 0.25)
			SetPedStrafeClipset(ped, 'move_ped_crouched_strafing')
			SetPedWeaponMovementClipset(ped, 'move_ped_crouched')
			SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
		else
			ResetCrouch(ped)
		end
	end
end

RegisterKeyMapping("+crouch", "Crouch", "keyboard", AK4Y.CrouchKey or "LCONTROL")
RegisterCommand("+crouch", ToggleCrouch, false)

-- Luồng khóa khom lưng GTA V, bắt trực tiếp phím CTRL để ngồi xuống tức thì và chặn chặt gáy takedown
CreateThread(function()
	while true do
		local ped = PlayerPedId()
		if not IsPedInAnyVehicle(ped, false) then
			-- Chặn INPUT_DUCK (phím CTRL khom lưng mặc định của GTA V)
			DisableControlAction(0, 36, true)

			-- Bắt trực tiếp khi người chơi bấm CTRL (Control 36) để ngồi xuống tức thì
			if IsDisabledControlJustPressed(0, 36) then
				ToggleCrouch()
			end

			-- Ép tắt trạng thái stealth nếu engine cố bật
			if GetPedStealthMovement(ped) then
				SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
			end

			-- Khóa triệt để hành động chặt gáy / Melee Takedown
			SetPedResetFlag(ped, 438, true)
		else
			if isCrouching then
				ResetCrouch(ped)
			end
		end
		Wait(0)
	end
end)



