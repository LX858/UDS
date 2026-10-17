local QBCore = exports['qb-core']:GetCoreObject()

-- Event nhận từ server khi sử dụng item balonewbie
RegisterNetEvent('xn_onpenbox:client:useBaloNewbie', function()
    local playerPed = PlayerPedId()
    local pedModel = GetEntityModel(playerPed)
    
    -- Xác định giới tính
    local gender = 'male'
    if pedModel == GetHashKey("mp_f_freemode_01") then
        gender = 'female'
    end
    
    -- Chạy progress bar
    if lib.progressBar({
        duration = 3000,
        label = 'Đang mở balo newbie...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'amb@prop_human_bum_bin@idle_b',
            clip = 'idle_d'
        }
    }) then
        -- Progress bar hoàn thành, gửi event về server với dữ liệu giới tính
        TriggerServerEvent('xn_onpenbox:server:openBaloNewbie', gender)
    else
        -- Người chơi hủy bỏ
        QBCore.Functions.Notify('Bạn đã hủy mở balo!', 'error')
    end
end)
