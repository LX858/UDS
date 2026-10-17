CreateThread(function()
    while true do 
        Wait(1000)
        SetPlayerHealthRechargeMultiplier(cache.playerId, 0.0)
        SetPlayerHealthRechargeLimit(cache.playerId, 0.0)
    end
end)