
function setTalkingMegaphone(source, talking)
	for player, _ in pairs(GetPlayers()) do
		if player ~= source then
			WS.TriggerClientEvent('pma-voice:setTalkingMegaphone', player, source, talking)
		end
	end
end

WS.RegisterEventHandler('pma-voice:setTalkingMegaphone', setTalkingMegaphone)
