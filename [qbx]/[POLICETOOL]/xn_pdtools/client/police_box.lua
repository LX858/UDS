-- ===================================
-- POLICE BOX ITEM HANDLER - CLIENT
-- ===================================

-- Đăng ký item usable trong ox_inventory
exports('usePoliceBox', function(data, slot)
    local playerPed = PlayerPedId()
    
    -- Animation mở hộp
    lib.requestAnimDict('mp_common')
    TaskPlayAnim(playerPed, 'mp_common', 'givetake1_a', 8.0, 8.0, -1, 49, 0, false, false, false)
    
    -- Progress bar
    if lib.progressBar({
        duration = 3000,
        label = 'Đang mở hộp cảnh sát...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        -- Gọi server để xử lý
        local result = lib.callback.await('xn_pdtools:usePoliceBox', false)
        
        if result and result.success then
            lib.notify({
                title = 'Hộp Cảnh Sát',
                description = result.message,
                type = 'success',
                position = 'top'
            })
        else
            lib.notify({
                title = 'Hộp Cảnh Sát',
                description = result and result.message or 'Không thể mở hộp',
                type = 'error',
                position = 'top'
            })
        end
        
        ClearPedTasks(playerPed)
    else
        -- Người chơi hủy
        ClearPedTasks(playerPed)
        lib.notify({
            title = 'Hộp Cảnh Sát',
            description = 'Đã hủy',
            type = 'info',
            position = 'top'
        })
    end
end)
