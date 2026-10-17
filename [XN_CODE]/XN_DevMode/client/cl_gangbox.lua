local BOX_LABELS = {
    ['qua_gang_1'] = 'Gói Quà Xã Đoàn I',
    ['qua_gang_2'] = 'Gói Quà Xã Đoàn II',
    ['qua_gang_3'] = 'Gói Quà Xã Đoàn III',
}

RegisterNetEvent('xn_gangbox:client:useBox', function(itemName)
    local boxLabel = BOX_LABELS[itemName] or 'Gói Quà Xã Đoàn'

    if IsPedDeadOrDying(PlayerPedId(), true) then
        TriggerEvent('ox_lib:notify', {
            type = 'error',
            description = 'Bạn không thể mở quà khi đang bị thương!'
        })
        return
    end

    if lib.progressBar({
        duration = 3000,
        label = 'Đang mở ' .. boxLabel .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'amb@prop_human_bum_bin@idle_b',
            clip = 'idle_d',
        },
    }) then
        TriggerServerEvent('xn_gangbox:server:openBox', itemName)
    else
        TriggerEvent('ox_lib:notify', {
            type = 'error',
            description = 'Bạn đã hủy mở ' .. boxLabel .. '!'
        })
    end
end)
