openRegister = function(job, id)
    local nearbyList = {}
    local nearbyPeds = getPlayersFromCoords(GetEntityCoords(cache.ped), Config.workshops[job].registers[id].playersRadius)
    for _, v in pairs(nearbyPeds) do
        v.source = GetPlayerServerId(v)
    end
    local results = lib.callback.await("mt_workshops:server:getInfoPlayers", false, nearbyPeds)
    if not results then notify(locale('notify_error_register_no_nearby'), 'error') return end

    for _, v in pairs(nearbyPeds) do
        local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(cache.ped))
        if results[v.source] then
            nearbyList[#nearbyList+1] = { value = v.source, label = tostring(results[v.source].text..' ('..math.floor(dist+0.05)..'m)') }
        end
    end
    if #nearbyList == 0 then notify(locale('notify_error_register_no_nearby'), 'error') return end
    local input = lib.inputDialog(Config.workshops[job].registers[id].label, {
        { type = "select", icon = locale('input_register_player_icon'), required = true, label = locale('input_register_player'), default = nearbyList[1] and nearbyList[1].value, options = nearbyList },
        { type = 'select', icon = locale('input_register_payment_type_icon'), required = true, label = locale('input_register_payment_type'), default = 'bank', options = { { value = "money", label = locale('input_register_cash') }, { value = "bank", label = locale('input_register_bank') } } },
        { type = 'number', icon = locale('input_register_amount_icon'), required = true, label = locale('input_register_amount') },
    })
    if input then
        lib.callback.await('mt_workshops:server:chargePlayer', false, input[1], tonumber(input[3]), input[2], job, id)
    end
end

lib.callback.register('mt_workshops:client:registerConfirmPay', function(price, biller, type, job, id)
    local alert = lib.alertDialog({ header = locale('alert_register_confirm_register'), content = locale('alert_register_confirm_register_description', price, Config.workshops[job].label), centered = true, cancel = true })
    if alert == 'confirm' then
        lib.callback.await('mt_workshops:server:confirmPayment', false, price, biller, type, job, id)
    end
    return true
end)