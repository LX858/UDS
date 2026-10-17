-- Tích hợp garage cho qbx_housing
-- Liên kết trực tiếp 100% với giao diện UI của mh_garage

local UsingMhGarage = GetResourceState('mh_garage') == 'started'

if UsingMhGarage then
    print('^2[QBX Housing Garage]^7 Connected to mh_garage NUI system')
else
    print('^3[QBX Housing Garage]^7 Warning: mh_garage not found')
end

-- Export lấy HouseConfig trên client
exports('GetHouseConfig', function(houseId)
    return GetHouseConfigClient(houseId)
end)

-- Helper xác định Garage Config & Interior động theo loại nhà và cấp độ gang
local function BuildClientGarageConfig(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig or not houseConfig.garagePoint or not houseConfig.garageSpawn then 
        return nil, nil, nil
    end
    
    local houseType = Config.HouseTypes[houseConfig.type]
    local gPoint = houseConfig.garagePoint
    local gSpawn = houseConfig.garageSpawn
    local spawnHeading = gSpawn.w or gSpawn.h or (type(gSpawn) == 'table' and gSpawn[4]) or 0.0
    
    local isGang = (houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang'
    local maxVehs = (houseType and houseType.garage and houseType.garage.maxVehicles) or 2
    local garageInterior = (houseType and houseType.garage and houseType.garage.interior) or 'low_end'
    
    if isGang then
        local gLevel = tonumber(houseConfig.level) or 1
        local gCfg = Config.GangHouseLevels and Config.GangHouseLevels[gLevel]
        if gCfg and gCfg.garage then
            garageInterior = gCfg.garage.interior or 'low_end'
            maxVehs = gCfg.garage.maxVehicles or 2
        else
            if gLevel == 2 then
                garageInterior = 'medium'
                maxVehs = 6
            elseif gLevel >= 3 then
                garageInterior = 'autoshop'
                maxVehs = 10
            else
                garageInterior = 'low_end'
                maxVehs = 2
            end
        end
    end
    
    local config = {
        type = 'car',
        enter = vector3(gPoint.x, gPoint.y, gPoint.z),
        parkVehicle = vector3(gPoint.x, gPoint.y, gPoint.z),
        vehicleSpawnPoint = vector4(gSpawn.x, gSpawn.y, gSpawn.z, spawnHeading),
        price = nil,
        pricetakeout = 0,
        blip = { id = 0, scale = 0, colour = 0 },
        blackListClass = { 14, 15, 16, 19, 21 },
        GarageInfo = 'Garage ' .. (isGang and 'Trụ Sở Xã Đoàn' or ('nhà ' .. houseId)) .. '. Có thể để ' .. maxVehs .. ' xe.',
        interior = garageInterior
    }
    
    return config, garageInterior, houseConfig
end

-- Export lấy HouseGarageConfig trên client cho mh_garage
exports('GetHouseGarageConfig', function(garageName)
    local houseId = garageName:gsub('^house_', '')
    local config = BuildClientGarageConfig(houseId)
    return config
end)

-- Helper bảo đảm garage đã được nạp trong mh_garage (Client Self-Healing)
local function EnsureGarageInjected(houseId)
    local fullGarageName = 'house_' .. houseId
    local clientGarageConfig, garageInterior, houseConfig = BuildClientGarageConfig(houseId)
    if not houseConfig or not clientGarageConfig then return nil, nil, nil end
    
    if UsingMhGarage then
        pcall(function()
            exports['mh_garage']:InjectGarage(fullGarageName, clientGarageConfig)
        end)
        
        pcall(function()
            exports['mh_garage']:InjectNuiGarage(fullGarageName, clientGarageConfig)
        end)
    end
    
    return fullGarageName, garageInterior, houseConfig
end

-- Event mở garage menu từ NUI hoặc interaction
RegisterNetEvent('qbx_housing:client:openGarageMenu', function(houseId, garageName)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    -- Kiểm tra khoảng cách
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local garageCoords = houseConfig.garagePoint and vector3(houseConfig.garagePoint.x, houseConfig.garagePoint.y, houseConfig.garagePoint.z)
    local doorCoords = houseConfig.door and vector3(houseConfig.door.x, houseConfig.door.y, houseConfig.door.z)
    
    local distGarage = garageCoords and #(playerCoords - garageCoords) or 999.0
    local distDoor = doorCoords and #(playerCoords - doorCoords) or 999.0
    
    if distGarage > 100.0 and distDoor > 100.0 then
        lib.notify({
            title = 'Garage',
            description = 'Bạn phải đến gần nhà hoặc garage',
            type = 'error'
        })
        return
    end
    
    -- Mở giao diện Garage UI của mh_garage
    OpenGarageMenu(houseId, garageName)
end)

-- Mở Giao diện Garage UI (Liên kết trực tiếp 100% sang mh_garage NUI)
function OpenGarageMenu(houseId, garageName)
    local fullGarageName, garageInterior, houseConfig = EnsureGarageInjected(houseId)
    if not houseConfig then return end
    
    if UsingMhGarage then
        local success, err = pcall(function()
            exports['mh_garage']:OpenGarageNUI(fullGarageName, garageInterior or 'low_end')
        end)
        
        if not success then
            print('^1[QBX Housing]^7 Error opening mh_garage NUI: ' .. tostring(err))
            lib.notify({
                title = 'Garage',
                description = 'Lỗi khi mở giao diện mh_garage: ' .. tostring(err),
                type = 'error'
            })
        end
    else
        lib.notify({
            title = 'Garage',
            description = 'Resource mh_garage chưa được khởi động trên máy chủ',
            type = 'error'
        })
    end
end

-- Cất xe vào garage (khi dùng marker / command)
function StoreVehicleInGarage(houseId, garageName)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Garage',
            description = 'Bạn phải ngồi trong xe',
            type = 'error'
        })
        return
    end
    
    if GetVehicleEngineHealth(vehicle) < 0 then
        lib.notify({
            title = 'Garage',
            description = 'Không thể cất xe hỏng nặng này',
            type = 'error'
        })
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local props = lib.getVehicleProperties(vehicle)
    local class = GetVehicleClass(vehicle)
    
    props.fuelLevel = GetVehicleFuelLevel(vehicle)
    
    TriggerServerEvent('qbx_housing:server:storeVehicle', houseId, garageName, plate, class, props)
    DeleteEntity(vehicle)
end

-- Spawn xe (cho fallback garage)
RegisterNetEvent('qbx_housing:client:spawnVehicle', function(vehicleData, spawnPoint)
    local model = vehicleData.model
    lib.requestModel(model)
    
    local heading = spawnPoint.w or spawnPoint.h or (type(spawnPoint) == 'table' and spawnPoint[4]) or 0.0
    local vehicle = CreateVehicle(model, spawnPoint.x, spawnPoint.y, spawnPoint.z, heading, true, false)
    
    if DoesEntityExist(vehicle) then
        SetVehicleOnGroundProperly(vehicle)
        lib.setVehicleProperties(vehicle, vehicleData)
        
        if vehicleData.fuelLevel then
            SetVehicleFuelLevel(vehicle, vehicleData.fuelLevel)
        end
        
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        
        lib.notify({
            title = 'Garage',
            description = 'Đã lấy xe ra thành công',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Garage',
            description = 'Không thể spawn xe',
            type = 'error'
        })
    end
end)
