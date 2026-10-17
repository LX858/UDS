local calls = 0

RegisterNetEvent('vx_monitor_fixture:net', function(value)
    calls = calls + 1
    assert(type(value) == 'string')
end)

AddEventHandler('vx_monitor_fixture:local', function(value)
    Wait(25)
    calls = calls + value
end)

AddEventHandler('vx_monitor_fixture:local', function(value)
    calls = calls + value
end)

AddEventHandler('vx_monitor_fixture:error', function()
    error('intentional fixture error')
end)

exports('echo', function(value)
    return value, nil, calls
end)

RegisterCommand('vx_monitor_fixture_test', function(player)
    TriggerEvent('vx_monitor_fixture:local', 1)
    local first, middle, count = exports.vx_runtime_monitor_fixture:echo('ok')
    assert(first == 'ok' and middle == nil and type(count) == 'number')
    if player and player > 0 then
        TriggerClientEvent('vx_monitor_fixture:client', player, 'metadata-only')
    end
end, true)

RegisterCommand('vx_monitor_fixture_error', function()
    TriggerEvent('vx_monitor_fixture:error')
end, true)
