-- Server side garage integration

-- Callback lấy danh sách xe trong garage
lib.callback.register('qbx_housing:server:getGarageVehicles', function(source, houseId, garageName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end
    
    if not IsOwner(player.PlayerData.citizenid, houseId) then
        return {}
    end
    
    local fullGarageName = garageName or ('house_' .. houseId)
    local vehicles = MySQL.query.await([[
        SELECT * FROM player_vehicles 
        WHERE citizenid = ? AND (garage = ? OR garage IS NULL)
        ORDER BY vehicle ASC
    ]], {player.PlayerData.citizenid, fullGarageName})
    
    local list = {}
    if vehicles then
        for _, veh in ipairs(vehicles) do
            local mods = veh.mods
            if type(mods) == 'string' then
                mods = json.decode(mods) or {}
            end
            local engineVal = (veh.engine or (mods and mods.engineHealth) or 1000)
            local bodyVal = (veh.body or (mods and mods.bodyHealth) or 1000)
            local fuelVal = (veh.fuel or (mods and mods.fuelLevel) or 100)
            
            table.insert(list, {
                name = veh.vehicle or (mods and mods.model) or 'Phương tiện',
                model = veh.vehicle,
                plate = veh.plate,
                engine = math.floor(engineVal / 10),
                body = math.floor(bodyVal / 10),
                fuel = math.floor(fuelVal),
                state = veh.state
            })
        end
    end
    return list
end)

-- Lấy danh sách xe trong garage của nhà (event cũ)
RegisterNetEvent('qbx_housing:server:getVehicleList', function(houseId, garageName)
    local source = source
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    -- Kiểm tra quyền truy cập - CHỈ CHỦ NHÀ mới được xem danh sách xe (không phải người có chìa khóa)
    if not IsOwner(player.PlayerData.citizenid, houseId) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage',
            description = 'Chỉ chủ nhà mới có quyền truy cập garage này',
            type = 'error'
        })
        return
    end
    
    -- Lấy danh sách xe từ database (player_vehicles)
    local vehicles = MySQL.query.await([[
        SELECT * FROM player_vehicles 
        WHERE citizenid = ? AND (garage = ? OR garage IS NULL)
        ORDER BY vehicle ASC
    ]], {player.PlayerData.citizenid, garageName})
    
    if vehicles then
        -- Parse vehicle data
        for i, veh in ipairs(vehicles) do
            if veh.mods then
                veh.mods = json.decode(veh.mods)
            end
        end
        
        TriggerClientEvent('qbx_housing:client:showVehicleList', source, vehicles, houseId, garageName)
    end
end)

-- Lấy xe ra khỏi garage
RegisterNetEvent('qbx_housing:server:takeOutVehicle', function(houseId, garageName, plate)
    local source = source
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    -- Kiểm tra quyền truy cập - CHỈ CHỦ NHÀ mới được lấy xe (không phải người có chìa khóa)
    if not IsOwner(player.PlayerData.citizenid, houseId) then 
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage',
            description = 'Chỉ chủ nhà mới có thể lấy xe từ garage',
            type = 'error'
        })
        return
    end
    
    -- Lấy thông tin xe
    local vehicle = MySQL.query.await([[
        SELECT * FROM player_vehicles 
        WHERE citizenid = ? AND plate = ?
    ]], {player.PlayerData.citizenid, plate})
    
    if not vehicle or not vehicle[1] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage',
            description = 'Không tìm thấy xe',
            type = 'error'
        })
        return
    end
    
    local veh = vehicle[1]
    
    -- Kiểm tra xe có trong garage không
    if veh.state ~= 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage',
            description = 'Xe không có trong garage',
            type = 'error'
        })
        return
    end
    
    -- Cập nhật trạng thái xe (state = 1 = ngoài)
    MySQL.update.await('UPDATE player_vehicles SET state = ? WHERE plate = ?', {1, plate})
    
    -- Parse vehicle mods
    local vehicleData = {
        model = veh.vehicle,
        plate = veh.plate,
    }
    
    if veh.mods then
        local mods = type(veh.mods) == 'string' and json.decode(veh.mods) or veh.mods
        for k, v in pairs(mods) do
            vehicleData[k] = v
        end
    end
    
    -- Lấy spawn point từ config
    local houseConfig = GetHouseConfig(houseId)
    if houseConfig and houseConfig.garageSpawn then
        TriggerClientEvent('qbx_housing:client:spawnVehicle', source, vehicleData, houseConfig.garageSpawn)
    end
end)

-- Cất xe vào garage
RegisterNetEvent('qbx_housing:server:storeVehicle', function(houseId, garageName, plate, vehicleClass, vehicleProps)
    local source = source
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    -- Kiểm tra quyền truy cập - CHỈ CHỦ NHÀ mới được cất xe (không phải người có chìa khóa)
    if not IsOwner(player.PlayerData.citizenid, houseId) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage',
            description = 'Chỉ chủ nhà mới có thể cất xe vào garage',
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra blacklist class (14, 15, 16, 19, 21 = heli, plane, boat)
    local blackListClass = { 14, 15, 16, 19, 21 }
    for _, bannedClass in ipairs(blackListClass) do
        if vehicleClass == bannedClass then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Garage',
                description = 'Không thể cất loại xe này',
                type = 'error'
            })
            return
        end
    end
    
    -- Kiểm tra xe có thuộc về player không
    local vehicle = MySQL.query.await([[
        SELECT * FROM player_vehicles 
        WHERE citizenid = ? AND plate = ?
    ]], {player.PlayerData.citizenid, plate})
    
    if not vehicle or not vehicle[1] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage',
            description = 'Bạn không sở hữu xe này',
            type = 'error'
        })
        return
    end
    
    -- Lấy house config để kiểm tra giới hạn
    local houseConfig = GetHouseConfig(houseId)
    if not houseConfig then return end
    
    local houseType = Config.HouseTypes[houseConfig.type]
    local maxVehicles = houseType.garage.maxVehicles
    
    -- Đếm số xe hiện tại trong garage
    local count = MySQL.query.await([[
        SELECT COUNT(*) as count 
        FROM player_vehicles 
        WHERE garage = ? AND state = 0 AND citizenid = ?
    ]], {garageName, player.PlayerData.citizenid})
    
    local currentCount = count and count[1] and count[1].count or 0
    
    if currentCount >= maxVehicles then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Garage',
            description = 'Garage đã đầy (' .. currentCount .. '/' .. maxVehicles .. ' xe)',
            type = 'error'
        })
        return
    end
    
    -- Cập nhật vehicle: state = 0 (trong garage), garage = garageName, mods = vehicleProps
    MySQL.update.await([[
        UPDATE player_vehicles 
        SET state = ?, garage = ?, mods = ? 
        WHERE plate = ?
    ]], {0, garageName, json.encode(vehicleProps), plate})
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Garage',
        description = 'Đã cất xe vào garage (' .. (currentCount + 1) .. '/' .. maxVehicles .. ')',
        type = 'success'
    })
end)
