local QBX = exports.qbx_core

-- /poop - Reset poop metadata về 0
RegisterCommand('poop', function(source, args, rawCommand)
    local src = source
    local player = QBX:GetPlayer(src)

    if not player then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không tìm thấy player!'
        })
        return
    end

    player.Functions.SetMetaData('poop', 0)

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = 'Đã đi vệ sinh (poop) xong!'
    })

    print(('[xn_pooppee] Player %s (%s) đã reset metadata poop về 0'):format(
        player.PlayerData.name,
        src
    ))
end, false)

-- /pee - Reset pee metadata về 0
RegisterCommand('pee', function(source, args, rawCommand)
    local src = source
    local player = QBX:GetPlayer(src)

    if not player then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không tìm thấy player!'
        })
        return
    end

    player.Functions.SetMetaData('pee', 0)

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = 'Đã đi vệ sinh (pee) xong!'
    })

    print(('[xn_pooppee] Player %s (%s) đã reset metadata pee về 0'):format(
        player.PlayerData.name,
        src
    ))
end, false)
