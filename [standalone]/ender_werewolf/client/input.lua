--- State bags cho resource khác đọc (LocalPlayer.state)
--- werewolfUiOpen   : UI werewolf đang hiển thị
--- werewolfUiFocus  : UI đang chiếm chuột + keyboard (Focus mode) — nên chặn inventory/phone
--- werewolfHud      : UI passive ban ngày/chờ lượt — hiện thông tin, KHÔNG chặn PTT
--- werewolfInMatch  : đang trong trận (không phải lobby/ended)

local blockControls = false

local BLOCK_CONTROLS = {
	30, 31, 32, 33, 34, 35, -- move
	21, 22, 36, 44, -- sprint, jump, ctrl, cover
	24, 25, 47, 58, 140, 141, 142, 143, 263, 264, -- combat
	37, 99, 100, -- weapon wheel
	75, 71, 72, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 76, 86, -- vehicle
	85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, -- vehicle misc
}

function WerewolfSetInputState(visible, uiFocus, hudMode, inMatch)
	LocalPlayer.state:set('werewolfUiOpen', visible == true, true)
	LocalPlayer.state:set('werewolfUiFocus', uiFocus == true, true)
	LocalPlayer.state:set('werewolfHud', hudMode == true, true)
	LocalPlayer.state:set('werewolfInMatch', inMatch == true, true)

	local nuiCfg = Config.Main.Nui or {}
	blockControls = uiFocus == true
		and inMatch == true
		and nuiCfg.BlockControlsOnFocus ~= false
end

function WerewolfClearInputState()
	WerewolfSetInputState(false, false, false, false)
	blockControls = false
end

CreateThread(function()
	while true do
		if blockControls then
			DisablePlayerFiring(cache.playerId, true)

			for i = 1, #BLOCK_CONTROLS do
				DisableControlAction(0, BLOCK_CONTROLS[i], true)
				DisableControlAction(1, BLOCK_CONTROLS[i], true)
				DisableControlAction(2, BLOCK_CONTROLS[i], true)
			end

			Wait(0)
		else
			Wait(400)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	WerewolfClearInputState()
end)
