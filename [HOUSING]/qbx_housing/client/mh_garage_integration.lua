-- Tích hợp với mh_garage để sử dụng MLO interior
-- File này chỉ chạy khi mh_garage đang hoạt động

if GetResourceState('mh_garage') ~= 'started' then
    --print('^3[QBX Housing]^7 mh_garage not found, using fallback garage system')
    return
end

-- Bảng lưu garages của houses
local HouseGarages = {}

-- Nhận garage config từ server và inject vào mh_garage
RegisterNetEvent('qbx_housing:client:SyncHouseGarage', function(garageName, garageConfig)
    --print('^3[QBX Housing]^7 Received garage sync: ' .. garageName)
    
    -- CRITICAL: Remove old garage first if it exists to prevent conflicts
    if HouseGarages[garageName] then
        --print('^3[QBX Housing]^7 Removing old garage before re-inject: ' .. garageName)
        pcall(function()
            exports['mh_garage']:RemoveGarage(garageName)
        end)
        Wait(50) -- Small delay to ensure cleanup completes
    end
    
    -- Update cache
    HouseGarages[garageName] = garageConfig
    
    -- Inject garage config vào GaragesData của mh_garage DIRECTLY với error handling chi tiết
    local success, err = pcall(function()
        local result = exports['mh_garage']:InjectGarage(garageName, garageConfig)
        if not result then
            error('InjectGarage returned false')
        end
    end)
    
    if success then
        print('^2[QBX Housing]^7 Successfully injected garage into mh_garage: ' .. garageName)
        
        -- Đợi một chút để đảm bảo zones được tạo
        Wait(100)
        print('^2[QBX Housing]^7 Garage "' .. garageName .. '" is ready for use')
    else
        print('^1[QBX Housing]^7 Failed to inject garage config: ' .. tostring(err))
        print('^3[QBX Housing]^7 Make sure to restart mh_garage after updating exports')
    end
end)

-- Nhận tất cả garages cùng lúc (khi resource start hoặc player join)
RegisterNetEvent('qbx_housing:client:SyncAllGarages', function(allGarages)
    local count = 0
    for garageName, garageConfig in pairs(allGarages) do
        HouseGarages[garageName] = garageConfig
        
        -- Inject vào mh_garage với error handling
        pcall(function()
            exports['mh_garage']:InjectGarage(garageName, garageConfig)
        end)
        count = count + 1
    end
end)

-- Xóa garage zone
RegisterNetEvent('qbx_housing:client:RemoveHouseGarage', function(garageName)
    -- Remove từ cache
    HouseGarages[garageName] = nil
    
    -- Remove từ mh_garage GaragesData DIRECTLY
    pcall(function()
        exports['mh_garage']:RemoveGarage(garageName)
    end)
    
    --print('^1[QBX Housing]^7 Removed house garage: ' .. garageName)
end)

-- Export để lấy garage config
exports('GetHouseGarage', function(houseId)
    local garageName = 'house_' .. houseId
    return HouseGarages[garageName]
end)

--print('^2[QBX Housing]^7 mh_garage client integration loaded')


