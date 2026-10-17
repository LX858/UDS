local VoiceResource = Config.Main.Voice.Resource or 'pma-voice'

local currentVoiceMode = nil
WerewolfPttPassthrough = false

local PTT_CONTROLS = { 249, 46 } -- INPUT_PUSH_TO_TALK + alternate

local function IsVoiceResourceReady()
	return Config.Main.Voice.Enabled and GetResourceState(VoiceResource) == 'started'
end

local function SetRadio(channel)
	if not IsVoiceResourceReady() then return end

	pcall(function()
		exports[VoiceResource]:setRadioChannel(channel or 0)
	end)
end

local function SetRadioEnabled(enabled)
	if not IsVoiceResourceReady() then return end

	pcall(function()
		exports[VoiceResource]:setVoiceProperty('radioEnabled', enabled)
	end)
end

local function SetProximity(range, lockCycle)
	if not IsVoiceResourceReady() then return end

	pcall(function()
		if range and range > 0 then
			exports[VoiceResource]:overrideProximityRange(range + 0.0, lockCycle == true)
		else
			exports[VoiceResource]:overrideProximityRange(0.1, true)
		end
	end)
end

local function ClearVoiceOverride()
	if not IsVoiceResourceReady() then return end

	pcall(function()
		exports[VoiceResource]:clearProximityOverride()
		exports[VoiceResource]:setRadioChannel(0)
		exports[VoiceResource]:setVoiceProperty('radioEnabled', false)
	end)

	currentVoiceMode = nil
end

function WerewolfEnablePttPassthrough(enable)
	WerewolfPttPassthrough = enable
end

CreateThread(function()
	while true do
		if WerewolfPttPassthrough then
			for i = 1, #PTT_CONTROLS do
				EnableControlAction(0, PTT_CONTROLS[i], true)

				EnableControlAction(1, PTT_CONTROLS[i], true)

				EnableControlAction(2, PTT_CONTROLS[i], true)
			end

			Wait(0)
		else
			Wait(400)
		end
	end
end)

RegisterNetEvent('ender_werewolf:client:applyVoice', function(voiceState)
	if not voiceState then return end
	currentVoiceMode = voiceState.mode

	SetRadio(voiceState.radio)

	if voiceState.mode == 'werewolf_radio' then
		SetProximity(voiceState.proximity, true)

		SetRadioEnabled(true)
	elseif voiceState.mode == 'dead' then
		SetProximity(voiceState.proximity, true)

		SetRadioEnabled(false)
	else
		SetProximity(voiceState.proximity, voiceState.mode == 'night' or voiceState.mode == 'dead')

		SetRadioEnabled(voiceState.radio and voiceState.radio > 0)
	end

	if Config.Debug then
		print(('[Werewolf Voice] mode=%s radio=%s proximity=%s'):format(voiceState.mode, voiceState.radio or 0, voiceState.proximity or 0))
	end
end)

RegisterNetEvent('ender_werewolf:client:resetVoice', function()
	ClearVoiceOverride()
end)

RegisterNetEvent('ender_werewolf:client:teleport', function(coords, reason)
	if not coords then return end

	DoScreenFadeOut(400)
	while not IsScreenFadedOut() do Wait(0) end

	local ped = cache.ped or PlayerPedId()
	SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
	if coords.w then
		SetEntityHeading(ped, coords.w + 0.0)
	end

	Wait(200)
	DoScreenFadeIn(400)

	if reason == 'spectator' then
		Notify('Bạn đã chết — chỉ được quan sát, không được nói.', 'error')
	elseif reason == 'lobby' then
		Notify('Đã vào khu vực lobby. Giữ PTT (mặc định N) để nói.', 'inform')
	elseif reason == 'werewolf_radio' then
		Notify('Ma Sói: giữ phím radio để bàn — người gần không nghe được.', 'inform')
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end

	WerewolfEnablePttPassthrough(false)

	ClearVoiceOverride()
end)
