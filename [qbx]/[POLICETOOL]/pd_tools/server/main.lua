local frozenVehicles = {}
local vehicleShields = {}

-- Event xử lý freeze/unfreeze vehicle
RegisterNetEvent('vehicle:freeze', function(netId, isFrozen)
    local source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if isFrozen then
        frozenVehicles[netId] = {
            player = source,
            timestamp = os.time(),
            vehicle = vehicle
        }
        print(string.format('[VEHICLE FREEZE] Player %d đã đóng băng xe (NetID: %d)', source, netId))
    else
        frozenVehicles[netId] = nil
        print(string.format('[VEHICLE FREEZE] Player %d đã bỏ đóng băng xe (NetID: %d)', source, netId))
    end
end)

-- Event xử lý shield vehicle
RegisterNetEvent('vehicle:shield', function(netId, hasShield, shieldType, duration)
    local source = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if hasShield then
        vehicleShields[netId] = {
            player = source,
            timestamp = os.time(),
            vehicle = vehicle,
            shieldType = shieldType,
            duration = duration
        }
        print(string.format('[VEHICLE SHIELD] Player %d đã tạo khiên %s cho xe (NetID: %d)', source, shieldType, netId))
    else
        vehicleShields[netId] = nil
        print(string.format('[VEHICLE SHIELD] Player %d đã xóa khiên xe (NetID: %d)', source, netId))
    end
end)

-- Command để xem danh sách xe đang freeze
RegisterCommand('listfrozen', function(source, args, rawCommand)
    local player = source
    local count = 0
    
    print('=== DANH SÁCH XE ĐANG ĐÓNG BĂNG ===')
    for netId, data in pairs(frozenVehicles) do
        count = count + 1
        local timeStr = os.date('%H:%M:%S %d/%m/%Y', data.timestamp)
        print(string.format('%d. NetID: %d | Player: %d | Thời gian: %s', count, netId, data.player, timeStr))
    end
    
    if count == 0 then
        print('Không có xe nào đang bị đóng băng.')
    end
    
    if player > 0 then
        TriggerClientEvent('chat:addMessage', player, {
            args = {'SYSTEM', string.format('Có %d xe đang bị đóng băng. Kiểm tra console để xem chi tiết.', count)}
        })
    end
end, true)

-- Command để xem danh sách xe có khiên
RegisterCommand('listshields', function(source, args, rawCommand)
    local player = source
    local count = 0
    
    print('=== DANH SÁCH XE CÓ KHIÊN ===')
    for netId, data in pairs(vehicleShields) do
        count = count + 1
        local timeStr = os.date('%H:%M:%S %d/%m/%Y', data.timestamp)
        local durationStr = data.duration > 0 and string.format('%.0f phút', data.duration / 60000) or 'Vĩnh viễn'
        print(string.format('%d. NetID: %d | Player: %d | Loại: %s | Thời gian: %s | Thời lượng: %s', 
              count, netId, data.player, data.shieldType, timeStr, durationStr))
    end
    
    if count == 0 then
        print('Không có xe nào có khiên bảo vệ.')
    end
    
    if player > 0 then
        TriggerClientEvent('chat:addMessage', player, {
            args = {'SYSTEM', string.format('Có %d xe có khiên bảo vệ. Kiểm tra console để xem chi tiết.', count)}
        })
    end
end, true)

-- Command để force unfreeze tất cả xe
RegisterCommand('unfreezeall', function(source, args, rawCommand)
    local count = 0
    
    for netId, data in pairs(frozenVehicles) do
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(vehicle) then
            -- Gửi lệnh unfreeze cho tất cả client
            TriggerClientEvent('vehicle:forceUnfreeze', -1, vehicle)
            count = count + 1
        end
        frozenVehicles[netId] = nil
    end
    
    print(string.format('[ADMIN] Đã bỏ đóng băng %d xe', count))
    
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'ADMIN', string.format('Đã bỏ đóng băng %d xe', count)}
        })
    end
end, true)

-- Command để force remove tất cả shield
RegisterCommand('removeshieldsall', function(source, args, rawCommand)
    local count = 0
    
    for netId, data in pairs(vehicleShields) do
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(vehicle) then
            -- Gửi lệnh remove shield cho tất cả client
            TriggerClientEvent('vehicle:forceRemoveShield', -1, vehicle)
            count = count + 1
        end
        vehicleShields[netId] = nil
    end
    
    print(string.format('[ADMIN] Đã xóa %d khiên xe', count))
    
    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'ADMIN', string.format('Đã xóa %d khiên xe', count)}
        })
    end
end, true)

-- Dọn dẹp data khi player disconnect
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Xóa các frozen vehicle của player
    for netId, data in pairs(frozenVehicles) do
        if data.player == source then
            frozenVehicles[netId] = nil
            print(string.format('[CLEANUP] Đã xóa freeze vehicle (NetID: %d) của player %d', netId, source))
        end
    end
    
    -- Xóa các shield vehicle của player
    for netId, data in pairs(vehicleShields) do
        if data.player == source then
            vehicleShields[netId] = nil
            print(string.format('[CLEANUP] Đã xóa shield vehicle (NetID: %d) của player %d', netId, source))
        end
    end
end)

-- Kiểm tra và dọn dẹp xe không tồn tại
CreateThread(function()
    while true do
        Wait(300000) -- Kiểm tra mỗi 5 phút
        
        -- Dọn dẹp frozen vehicles
        for netId, data in pairs(frozenVehicles) do
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            if not DoesEntityExist(vehicle) then
                frozenVehicles[netId] = nil
                print(string.format('[CLEANUP] Đã xóa frozen vehicle không tồn tại (NetID: %d)', netId))
            end
        end
        
        -- Dọn dẹp shield vehicles
        for netId, data in pairs(vehicleShields) do
            local vehicle = NetworkGetEntityFromNetworkId(netId)
            if not DoesEntityExist(vehicle) then
                vehicleShields[netId] = nil
                print(string.format('[CLEANUP] Đã xóa shield vehicle không tồn tại (NetID: %d)', netId))
            end
        end
    end
end)

print('^2[VEHICLE FREEZE SYSTEM] ^7Server started successfully!')
print('^3Available commands:^7')
print('  - /listfrozen - Xem danh sách xe đang đóng băng')
print('  - /listshields - Xem danh sách xe có khiên')
print('  - /unfreezeall - Bỏ đóng băng tất cả xe (Admin)')
print('  - /removeshieldsall - Xóa tất cả khiên xe (Admin)')
