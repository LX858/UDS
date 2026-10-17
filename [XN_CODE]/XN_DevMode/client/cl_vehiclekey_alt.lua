-- Alternative version using RegisterCommand instead of lib.addCommand
-- Client side cho command /danhchiakhoa

-- RegisterCommand('danhchiakhoa', function(source, args, rawCommand)
--     local ped = PlayerPedId()
--     local vehicle = GetVehiclePedIsIn(ped, false)
    
--     if vehicle == 0 then
--         exports['ox_lib']:notify({
--             title = 'Lỗi',
--             description = 'Bạn cần ngồi trong xe để sử dụng lệnh này!',
--             type = 'error'
--         })
--         return
--     end
    
--     local plate = GetVehicleNumberPlateText(vehicle)
--     if not plate then
--         exports['ox_lib']:notify({
--             title = 'Lỗi',
--             description = 'Không thể lấy biển số xe!',
--             type = 'error'
--         })
--         return
--     end
    
--     -- Kiểm tra xem người chơi đã có chìa khóa xe này chưa
--     local hasKey = exports['Renewed-Vehiclekeys']:hasKey(plate)
--     if hasKey then
--         exports['ox_lib']:notify({
--             title = 'Thông báo',
--             description = 'Bạn đã có chìa khóa xe này rồi!',
--             type = 'inform'
--         })
--         return
--     end
    
--     -- Gửi request đến server để đánh chìa khóa cho mình
--     TriggerServerEvent('vehiclekey:giveKeyToSelf', plate)
-- end, false)

-- Suggest command in chat
TriggerEvent('chat:addSuggestion', '/danhchiakhoa', 'Đánh chìa khóa xe cho chính mình', {})

-- Event nhận thông báo từ server
RegisterNetEvent('vehiclekey:notify', function(message, type)
    exports['ox_lib']:notify({
        title = type == 'success' and 'Thành công' or 'Lỗi',
        description = message,
        type = type or 'inform'
    })
end)
