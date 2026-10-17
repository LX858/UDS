local radioEffectId = CreateAudioSubmix("Megaphone")
SetAudioSubmixEffectRadioFx(radioEffectId, 0)
SetAudioSubmixEffectParamInt(radioEffectId, 0, GetHashKey('default'), 1)
SetAudioSubmixEffectParamFloat(radioEffectId, 0, GetHashKey("freq_hi"), 5000.0)
SetAudioSubmixEffectParamFloat(radioEffectId, 0, GetHashKey("freq_low"), 289.0)
SetAudioSubmixEffectParamFloat(radioEffectId, 0, GetHashKey("rm_mix"), 0.16)
SetAudioSubmixEffectParamFloat(radioEffectId, 0, GetHashKey("o_freq_lo"), 548.0)
SetAudioSubmixOutputVolumes(
    radioEffectId,
    0,
    1.0 --[[ frontLeftVolume ]],
    1.0 --[[ frontRightVolume ]],
    0.0 --[[ rearLeftVolume ]],
    0.0 --[[ rearRightVolume ]],
    1.0 --[[ channel5Volume ]],
    1.0 --[[ channel6Volume ]]
)
AddAudioSubmixOutput(radioEffectId, 0)

-- check if we are in any police veh (or any other with megaphone)
function IsInPoiceVehOrHeli(ped)
	local veh = GetVehiclePedIsIn(ped, false)
	local model = GetEntityModel(veh)
	return Config.PoliceVehicles[model], Config.Helis[model], GetVehicleClass(veh) == 18
end

local megaphone = false

function restoreDefaultSubmix(plyServerId)
	local submix = Player(plyServerId).state.submix
	if not submix then
		MumbleSetSubmixForServerId(plyServerId, -1)
		return
	end
	MumbleSetSubmixForServerId(plyServerId, submixEffect)
end

function toggleMegaphone(plySource, enabled)
	if enabled then
		-- MumbleSetVolumeOverrideByServerId(plySource, 0.85) -- you can enable to increase the volume of voice, while using megaphone, but this will bypass 3d sound and distance calculation
		MumbleSetSubmixForServerId(plySource, radioEffectId)
	elseif not enabled then
		if GetConvarInt('voice_enableSubmix', 1) == 1 then
			SetTimeout(10, function()
				restoreDefaultSubmix(plySource)
			end)
		end
		MumbleSetVolumeOverrideByServerId(plySource, -1.0)
	end
end

function setTalkingOnMegaphone(plySource, enabled)
	toggleMegaphone(plySource, enabled)
end
WS.RegisterEventHandler('pma-voice:setTalkingMegaphone', setTalkingOnMegaphone)

RegisterCommand('+useMegaphone', function()
	local ped = PlayerPedId()
	local police, heli, emveh = IsInPoiceVehOrHeli(ped)
	if not megaphone and (police or heli or emveh) then
	-- if not megaphone then
        megaphone = true
		WS.TriggerServerEvent('pma-voice:setTalkingMegaphone', true)
		exports['pma-voice']:overrideProximityRange(heli and Config.HeliMegaphoneProximity or Config.MegaphoneProximity, false)
		CreateThread(function()
			local checkFailed = false
			while megaphone do
				if IsEntityDead(ped) then -- @TODO
					checkFailed = true
					break
				end
				SetControlNormal(0, 249, 1.0)
				SetControlNormal(1, 249, 1.0)
				SetControlNormal(2, 249, 1.0)
				Wait(0)
				if checkFailed then
					ExecuteCommand("-useMegaphone")
				end
            end
		end)
	end
end, false)

RegisterCommand('-useMegaphone', function()
	megaphone = false
	MumbleClearVoiceTargetPlayers(1.0)
	WS.TriggerServerEvent('pma-voice:setTalkingMegaphone', false)
	exports['pma-voice']:clearProximityOverride()
end, false)

RegisterKeyMapping('+useMegaphone', 'Use megaphone', 'keyboard', Config.DefaultKeybind)



