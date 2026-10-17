-- Debug Commands cho Housing (Chỉ dùng để test)
-- Comment out hoặc xóa file này khi deploy production

if Config.Debug then
    -- Command để test NUI
    RegisterCommand('testhouse', function(source, args)
        local houseId = args[1] or 'slum_1'
        OpenHousingNUI(houseId)
    end, false)
    
    -- Command để đóng NUI
    RegisterCommand('closehouse', function()
        CloseHousingNUI()
    end, false)
    
    -- Command để teleport đến nhà
    RegisterCommand('gotohouse', function(source, args)
        local houseId = args[1] or 'slum_1'
        local houseConfig = GetHouseConfigClient(houseId)
        
        if houseConfig then
            SetEntityCoords(PlayerPedId(), houseConfig.door.x, houseConfig.door.y, houseConfig.door.z)
            lib.notify({
                title = 'Debug',
                description = 'Teleported to ' .. houseId,
                type = 'info'
            })
        else
            lib.notify({
                title = 'Debug',
                description = 'House not found',
                type = 'error'
            })
        end
    end, false)
    
    -- Command để list tất cả houses
    RegisterCommand('listhouse', function()
        print('===== QBX HOUSING LIST =====')
        for i, house in ipairs(Config.Houses) do
            print(string.format('%d. %s (%s) - %s', i, house.id, house.type, Config.HouseTypes[house.type].label))
        end
        print('============================')
    end, false)
    
    print('^2[QBX Housing] Debug commands loaded:^0')
    print('^3/testhouse [houseId]^0 - Test NUI')
    print('^3/closehouse^0 - Close NUI')
    print('^3/gotohouse [houseId]^0 - Teleport to house')
    print('^3/listhouse^0 - List all houses')
end
