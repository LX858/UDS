local cooldownActive = {}

lib.callback.register('mt_workshops:server:canStartMission', function(source, job)
    return cooldownActive[job]
end)

lib.callback.register('mt_workshops:server:setCooldownState', function(source, job, id)
    cooldownActive[job] = true
    Citizen.CreateThread(function()
        Wait(Config.workshops[job].mission[id].cooldown*60000)
        cooldownActive[job] = false
    end)
    return true
end)

lib.callback.register('mt_workshops:server:giveMissionPayment', function(source, mission)
    local src = source
    local payment = math.random(mission.minPayment, mission.maxPayment)
    if Config.framework == 'qb' then
        local Player = Config.core.Functions.GetPlayer(src)
        if not Player then return end
        Player.Functions.AddMoney('cash', payment, 'workshops-mission-payment')
    elseif Config.framework == 'qbx' then
        local Player = exports.qbx_core:GetPlayer(src)
        if not Player then return end
        Player.Functions.AddMoney('cash', payment, 'workshops-mission-payment')
    elseif Config.framework == 'esx' then
        local Player = Config.core.GetPlayerFromId(src)
        if not Player then return end
        Player.addAccountMoney('money', payment)
    end
end)