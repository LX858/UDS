-- Command để mở menu đánh chìa khóa xe
RegisterCommand('testdanhchiakhoa', function()
    TriggerServerEvent('vehiclekey:requestVehicleList')
end, false)

-- Thêm suggestion cho command
TriggerEvent('chat:addSuggestion', '/testdanhchiakhoa', 'Mở menu đánh chìa khóa xe', {})

RegisterNetEvent('vehiclekey:client:openMenu', function()
    TriggerServerEvent('vehiclekey:requestVehicleList')
end)

-- Event hiển thị menu danh sách xe để đánh chìa khóa
RegisterNetEvent('vehiclekey:openMenu', function(vehicles)
    if not vehicles or #vehicles == 0 then
        exports['ox_lib']:notify({
            title = 'Thông báo',
            description = 'Bạn không có xe nào trong garage!',
            type = 'inform'
        })
        return
    end
    
    local options = {}
    
    for _, vehicle in ipairs(vehicles) do
        local hasKey = exports['Renewed-Vehiclekeys']:hasKey(vehicle.plate)
        local label = string.format('%s - %s %s', 
            vehicle.plate, 
            vehicle.vehicle, 
            hasKey and '(Đã có chìa khóa)' or ''
        )
        
        table.insert(options, {
            title = label,
            description = hasKey and 'Bạn đã có chìa khóa xe này' or 'Nhấn để đánh chìa khóa',
            icon = 'car',
            disabled = hasKey,
            onSelect = function()
                TriggerServerEvent('vehiclekey:giveKeyToSelf', vehicle.plate)
            end
        })
    end
    
    lib.registerContext({
        id = 'vehiclekey_menu',
        title = 'Danh sách xe của bạn',
        options = options
    })
    
    lib.showContext('vehiclekey_menu')
end)

-- Event nhận thông báo từ server
RegisterNetEvent('vehiclekey:notify', function(message, type)
    exports['ox_lib']:notify({
        title = type == 'success' and 'Thành công' or 'Lỗi',
        description = message,
        type = type or 'inform'
    })
end)
