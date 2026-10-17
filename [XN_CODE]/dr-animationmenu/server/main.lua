local Requests = {}
local Targets = {}

CreateThread(function()
	while true do
		for k, v in pairs(Requests) do
			if GetGameTimer() - v.timeout > 0 and not Requests[k].accepted then
				TriggerClientEvent("ak4y_emotes:notify", v.sender, _U("request_expired"), _U("request_expired_desc"),
					"error")
				Requests[k] = nil
			end
		end

		Wait(1000)
	end
end)

RegisterServerEvent("ak4y_emotes:request", function(target, senderEmote, targetEmote, emoteLabel)
	local src = source

	Requests[target] = {
		sender = src,
		target = target,
		emoteLabel = emoteLabel,
		senderEmote = senderEmote,
		targetEmote = targetEmote,
		senderName = GetPlayerName(src),
		accepted = false,
		timeout = GetGameTimer() + 5000,
	}

	TriggerClientEvent("ak4y_emotes:sendRequest", target, Requests[target])
end)

RegisterServerEvent("ak4y_emotes:response", function(request, response)
	local src = source

	local request = Requests[request.target]

	if not request or request.target ~= src then return end

	if response then
		local senderPed = GetPlayerPed(request.sender)
		local senderCoords = GetEntityCoords(senderPed)
		local targetCoords = GetEntityCoords(GetPlayerPed(src))

		if #(senderCoords - targetCoords) <= AK4Y.MaxDistanceForSharedEmotes then
			request.accepted = true

			TriggerClientEvent("ak4y_emotes:playSharedEmote", request.sender, request.senderEmote, -1)
			TriggerClientEvent("ak4y_emotes:playSharedEmote", request.target, request.targetEmote,
				NetworkGetNetworkIdFromEntity(senderPed))
		else
			TriggerClientEvent("ak4y_emotes:notify", src, _U("too_far"), _U("no_players_nearby"), "error")
		end
	else
		TriggerClientEvent("ak4y_emotes:notify", request.sender, _U("declined_request"), _U("declined_request_desc"),
			"error")
		Requests[request.target] = nil
	end
end)

RegisterServerEvent("ak4y_emotes:cancelShared", function()
	local src = source

	for _, req in pairs(Requests) do
		if src == req.sender or src == req.target then
			TriggerClientEvent("ak4y_emotes:cancelEmote", src == req.sender and req.target or req.sender)
			Requests[req.target] = nil
			break
		end
	end
end)
