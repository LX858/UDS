-- Helper function để generate random plate
local function GenerateJobPlate(job)
    local plate = string.upper(job:sub(1, 2))
    for i = 1, 6 do
        local rand = math.random(1, 3)
        if rand == 1 then
            plate = plate .. string.char(math.random(65, 90)) -- Random letter
        else
            plate = plate .. math.random(0, 9) -- Random number
        end
    end
    return plate:sub(1, 8)
end

-- Callback to check if player has enough money
lib.callback.register('xn_jobgarage:server:checkMoney', function(source, amount)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then
        return false
    end
    
    local playerMoney = (Player.PlayerData.money['cash'] or 0) + (Player.PlayerData.money['bank'] or 0)
    return playerMoney >= amount
end)

-- Event to charge fee for vehicle
RegisterNetEvent('xn_jobgarage:server:chargeFee', function(amount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return
    end
    
    -- Try to remove from cash first, then bank
    if (Player.PlayerData.money['cash'] or 0) >= amount then
        Player.Functions.RemoveMoney('cash', amount, 'job-garage-fee')
    elseif (Player.PlayerData.money['bank'] or 0) >= amount then
        Player.Functions.RemoveMoney('bank', amount, 'job-garage-fee')
    else
        -- Not enough money (shouldn't happen if callback worked correctly)
        return
    end
    
    -- Notify client about fee charged
    TriggerClientEvent('xn_jobgarage:client:feeCharged', src, amount)
end)

-- Callback lấy DANH SÁCH tất cả xe của player tại garage
lib.callback.register('xn_jobgarage:server:getVehicleList', function(source, jobName, garageName)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { vehicles = {} }
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    if Config.Debug then
        print("^3[DEBUG] Get Vehicle List:^0")
        print("  CitizenID: " .. citizenid)
        print("  Job: " .. jobName)
        print("  Garage: " .. garageName)
    end
    
    -- Lấy TẤT CẢ xe của player tại garage này
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE citizenid = ? AND job = ? AND garage = ?', {
        citizenid, jobName, garageName
    })
    
    local vehicles = {}
    
    if result and #result > 0 then
        for _, veh in ipairs(result) do
            -- Convert is_out to number
            local isOutValue = veh.is_out
            if type(isOutValue) == "boolean" then
                isOutValue = isOutValue and 1 or 0
            else
                isOutValue = tonumber(isOutValue) or 0
            end
            
            table.insert(vehicles, {
                id = veh.id,
                vehicle = veh.vehicle,
                vehicle_label = veh.vehicle_label or veh.vehicle,
                plate = veh.plate,
                body = veh.body or 1000,
                engine = veh.engine or 1000,
                fuel = veh.fuel or 100,
                is_out = isOutValue,
                mods = veh.mods
            })
        end
        
        if Config.Debug then
            print("^2[DEBUG] Found " .. #vehicles .. " vehicle(s)^0")
        end
    else
        if Config.Debug then
            print("^1[DEBUG] No vehicles found^0")
        end
    end
    
    return { vehicles = vehicles }
end)

-- Callback kiểm tra xe đã tồn tại và có đang out không (DEPRECATED - dùng getVehicleList)
lib.callback.register('xn_jobgarage:server:checkVehicleStatus', function(source, jobName, garageName)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { exists = false }
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    if Config.Debug then
        print("^3[DEBUG] Check Vehicle Status:^0")
        print("  CitizenID: " .. citizenid)
        print("  Job: " .. jobName)
        print("  Garage: " .. garageName)
    end
    
    -- Kiểm tra xe trong database
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE citizenid = ? AND job = ? AND garage = ?', {
        citizenid, jobName, garageName
    })
    
    if result and result[1] then
        -- Convert boolean to number if needed
        local isOutValue = result[1].is_out
        if type(isOutValue) == "boolean" then
            isOutValue = isOutValue and 1 or 0
        else
            isOutValue = tonumber(isOutValue) or 0
        end
        
        if Config.Debug then
            print("^2[DEBUG] Vehicle Status Found:^0")
            print("    Plate: " .. result[1].plate)
            print("    Is Out (raw): " .. tostring(result[1].is_out))
            print("    Is Out (converted): " .. tostring(isOutValue))
        end
        
        -- Clone vehicleData and fix is_out to number
        local vehicleData = {
            id = result[1].id,
            citizenid = result[1].citizenid,
            job = result[1].job,
            garage = result[1].garage,
            vehicle = result[1].vehicle,
            plate = result[1].plate,
            mods = result[1].mods,
            body = result[1].body,
            engine = result[1].engine,
            fuel = result[1].fuel,
            is_out = isOutValue  -- Force to number
        }
        
        return {
            exists = true,
            isOut = isOutValue == 0,  -- 0 = OUT/NGOÀI, 1 = IN/TRONG
            plate = result[1].plate,
            vehicleData = vehicleData
        }
    end
    
    if Config.Debug then
        print("^1[DEBUG] No vehicle found in database^0")
    end
    return { exists = false }
end)

-- Callback để lấy impound cost
lib.callback.register('xn_jobgarage:server:getImpoundCost', function(source)
    -- Có thể tùy chỉnh giá impound ở đây
    return 1000 -- $1000 để chuộc xe
end)

-- Callback để charge impound fee
-- Callback để charge impound fee - SỬA LẠI QUERY THEO VEHICLE ID
lib.callback.register('xn_jobgarage:server:chargeImpound', function(source, vehicleId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        if Config.Debug then
            print("^1[ERROR] No player found^0")
        end
        return { success = false, reason = 'no_player' }
    end
    
    local citizenid = Player.PlayerData.citizenid
    local impoundCost = Config.ImpoundCost or 1000
    
    -- Check cash only
    local cashAmount = Player.PlayerData.money['cash'] or 0
    
    if Config.Debug then
        print("^3[DEBUG] Impound Charge Request:^0")
        print("  Player:", GetPlayerName(src))
        print("  Vehicle ID:", vehicleId)
        print("  Cash: $" .. cashAmount)
        print("  Cost: $" .. impoundCost)
    end
    
    if cashAmount < impoundCost then
        if Config.Debug then
            print("^1[ERROR] Insufficient cash!^0")
        end
        return { 
            success = false, 
            reason = 'insufficient_funds',
            cost = impoundCost,
            playerMoney = cashAmount
        }
    end
    
    -- Verify ownership
    local checkResult = MySQL.query.await('SELECT * FROM job_vehicles WHERE id = ? AND citizenid = ?', {
        vehicleId, citizenid
    })
    
    if not checkResult or not checkResult[1] then
        if Config.Debug then
            print("^1[ERROR] Vehicle not found or not owned by player^0")
        end
        return { success = false, reason = 'vehicle_not_found' }
    end
    
    local plate = checkResult[1].plate
    
    -- Remove cash
    local removed = Player.Functions.RemoveMoney('cash', impoundCost, 'job-vehicle-impound')
    if Config.Debug then
        print("^2[DEBUG] Removed $" .. impoundCost .. " from cash. Success: " .. tostring(removed) .. "^0")
    end
    
    if not removed then
        if Config.Debug then
            print("^1[ERROR] Failed to remove money!^0")
        end
        return { success = false, reason = 'remove_money_failed' }
    end
    
    -- Lấy mods hiện tại và update bodyHealth/engineHealth trong JSON
    local vehicleData = checkResult[1]
    local updatedMods = nil
    if vehicleData.mods then
        local mods = json.decode(vehicleData.mods)
        if mods then
            mods.bodyHealth = 300
            mods.engineHealth = 300
            updatedMods = json.encode(mods)
        end
    end
    
    -- UPDATE THEO ID
    local updated = MySQL.update('UPDATE job_vehicles SET is_out = 1, body = 300, engine = 300, mods = ? WHERE id = ?', {
        updatedMods, vehicleId
    })
    
    if Config.Debug then
        print("^2[DEBUG] Vehicle impounded successfully. Rows updated: " .. (updated or 0) .. "^0")
        print("^2[DEBUG] Vehicle health SET to: body=300 (30%), engine=300 (30%)^0")
    end
    
    -- XÓA XE KHỎI GAME WORLD
    local allVehicles = GetAllVehicles()
    local deletedCount = 0
    
    for _, veh in ipairs(allVehicles) do
        if DoesEntityExist(veh) then
            local vehPlate = GetVehicleNumberPlateText(veh)
            if vehPlate and string.gsub(vehPlate, "%s+", "") == string.gsub(plate, "%s+", "") then
                if Config.Debug then
                    print("^1[IMPOUND] Deleting existing vehicle with plate: " .. vehPlate .. "^0")
                end
                DeleteEntity(veh)
                deletedCount = deletedCount + 1
            end
        end
    end
    
    if deletedCount > 0 then
        if Config.Debug then
            print("^2[IMPOUND] Deleted " .. deletedCount .. " vehicle(s) from world^0")
        end
    end
    
    return { 
        success = true, 
        cost = impoundCost 
    }
end)

-- Callback để spawn XE TỰ DO (aircraft/boat - không lưu SQL)
lib.callback.register('xn_jobgarage:server:spawnVehicleFree', function(source, vehicleData)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { success = false, reason = 'no_player' }
    end
    
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return { success = false, reason = 'no_ped' }
    end
    
    local vehicleModel = vehicleData.model
    local coords = vehicleData.coords
    local vehicleType = vehicleData.vehicleType or "automobile"
    local defaultMods = vehicleData.defaultMods
    
    if Config.Debug then
        print("^3[DEBUG] Free Spawn Vehicle Request:^0")
        print("  Player: " .. GetPlayerName(src))
        print("  Vehicle Model: " .. vehicleModel)
        print("  Vehicle Type: " .. vehicleType)
        print("  Coords: " .. tostring(coords))
    end
    
    -- Generate random plate
    local plate = GenerateJobPlate("JOB")
    
    -- Determine vehicle type for CreateVehicleServerSetter
    local nativeType = "automobile"
    if vehicleType == "aircraft" then
        -- Check if helicopter or plane
        local modelLower = vehicleModel:lower()
        if string.find(modelLower, "heli") or string.find(modelLower, "maverick") or 
           string.find(modelLower, "buzzard") or string.find(modelLower, "frogger") or 
           string.find(modelLower, "polmav") or string.find(modelLower, "annihilator") or
           string.find(modelLower, "volito") or string.find(modelLower, "sparrow") then
            nativeType = "heli"
        else
            nativeType = "plane"
        end
    elseif vehicleType == "boat" then
        nativeType = "boat"
    end
    
    if Config.Debug then
        print("  Native Type: " .. nativeType)
    end
    
    -- Get model hash
    local modelHash = joaat(vehicleModel)
    
    -- Spawn using CreateVehicleServerSetter (more reliable)
    local vehicle = CreateVehicleServerSetter(modelHash, nativeType, coords.x, coords.y, coords.z, coords.w or 0.0)
    
    -- Wait for vehicle to exist
    local attempts = 0
    while not DoesEntityExist(vehicle) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end
    
    if not vehicle or not DoesEntityExist(vehicle) then
        if Config.Debug then
            print("^1[ERROR] Failed to spawn free vehicle - CreateVehicleServerSetter failed^0")
        end
        return { success = false, reason = 'spawn_failed' }
    end
    
    if Config.Debug then
        print("^2[DEBUG] Vehicle created successfully: " .. vehicle .. "^0")
    end
    
    -- Set plate
    SetVehicleNumberPlateText(vehicle, plate)
    
    -- Build mods
    local vehicleMods = {
        plate = plate,
        fuelLevel = 100,
        bodyHealth = 1000,
        engineHealth = 1000
    }
    
    -- Apply default mods from config
    if defaultMods then
        for key, value in pairs(defaultMods) do
            vehicleMods[key] = value
        end
    end
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    
    if Config.Debug then
        print("^2[DEBUG] Free vehicle spawned:^0")
        print("  NetId: " .. netId)
        print("  Plate: " .. plate)
    end
    
    -- GIVE KEYS TO PLAYER (server-side)
    -- Thử qbx_vehiclekeys
    local keySuccess = pcall(function()
        exports.qbx_vehiclekeys:GiveKeys(src, plate)
    end)
    
    if keySuccess then
        if Config.Debug then
            print("^2[DEBUG] Keys given via qbx_vehiclekeys export^0")
        end
    else
        -- Fallback: trigger event
        if Config.Debug then
            print("^3[DEBUG] Trying event for keys...^0")
        end
        TriggerClientEvent('qb-vehiclekeys:client:GiveKeys', src, plate, false)
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    end
    
    return {
        success = true,
        netId = netId,
        plate = plate,
        vehicleMods = vehicleMods
    }
end)

-- =====================================================
-- CLIENT-SIDE SPAWN: Server chỉ validate và trả data
-- =====================================================
lib.callback.register('xn_jobgarage:server:getVehicleDataForSpawn', function(source, vehicleData)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { success = false, reason = 'no_player' }
    end
    
    local citizenid = Player.PlayerData.citizenid
    local jobName = vehicleData.jobName
    local garageName = vehicleData.garageName
    local vehicleModel = vehicleData.model
    
    if Config.Debug then
        print("^3[CLIENT-SPAWN] Get Vehicle Data Request:^0")
        print("  CitizenID: " .. citizenid)
        print("  Job: " .. jobName)
        print("  Garage: " .. garageName)
        print("  Vehicle Model: " .. vehicleModel)
    end
    
    -- Kiểm tra xe trong database
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE citizenid = ? AND job = ? AND garage = ?', {
        citizenid, jobName, garageName
    })
    
    local plate = nil
    local vehicleMods = nil
    local bodyHealth = 1000
    local engineHealth = 1000
    local fuelLevel = 100
    local isFirstTime = false
    local vehicleId = nil
    
    if result and result[1] then
        -- Xe đã tồn tại, load dữ liệu
        vehicleId = result[1].id
        plate = result[1].plate
        vehicleMods = result[1].mods and json.decode(result[1].mods) or nil
        
        bodyHealth = result[1].body or 1000
        engineHealth = result[1].engine or 1000
        fuelLevel = result[1].fuel or 100
        
        if not bodyHealth and vehicleMods and vehicleMods.bodyHealth then
            bodyHealth = vehicleMods.bodyHealth
        end
        bodyHealth = bodyHealth or 1000
        
        if not engineHealth and vehicleMods and vehicleMods.engineHealth then
            engineHealth = vehicleMods.engineHealth
        end
        engineHealth = engineHealth or 1000
        
        -- Update is_out = 0 (xe ra ngoài)
        MySQL.update('UPDATE job_vehicles SET is_out = 0 WHERE id = ?', { result[1].id })
    else
        -- Xe mới, tạo plate mới và insert vào database
        plate = GenerateJobPlate(jobName)
        isFirstTime = true
        
        local insertId = MySQL.insert.await('INSERT INTO job_vehicles (citizenid, job, garage, vehicle, plate, mods, body, engine, fuel, is_out) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            citizenid, jobName, garageName, vehicleModel, plate, nil, 1000, 1000, 100, 0
        })
        vehicleId = insertId
    end
    
    -- XÓA XE TRÙNG BIỂN SỐ TỪ SERVER
    local allVehicles = GetAllVehicles()
    local trimmedPlate = string.gsub(plate, "%s+", "")
    for _, veh in ipairs(allVehicles) do
        if DoesEntityExist(veh) then
            local vehPlate = GetVehicleNumberPlateText(veh)
            if vehPlate and string.gsub(vehPlate, "%s+", "") == trimmedPlate then
                DeleteEntity(veh)
            end
        end
    end
    
    -- Tạo mods cho client (không có plate)
    local modsForClient = nil
    if vehicleMods then
        modsForClient = {}
        for k, v in pairs(vehicleMods) do
            if k ~= 'plate' then
                modsForClient[k] = v
            end
        end
    end
    
    if Config.Debug then
        print("^2[CLIENT-SPAWN] Returning data - Plate: " .. plate .. ", Body: " .. bodyHealth .. ", Engine: " .. engineHealth .. "^0")
    end
    
    return {
        success = true,
        vehicleId = vehicleId,
        plate = plate,
        bodyHealth = bodyHealth,
        engineHealth = engineHealth,
        fuelLevel = fuelLevel,
        vehicleMods = modsForClient,
        isFirstTime = isFirstTime
    }
end)

-- Event để client báo spawn thành công (update network id nếu cần)
RegisterNetEvent('xn_jobgarage:server:onClientSpawnSuccess', function(vehicleId, netId)
    local src = source
    if Config.Debug then
        print("^2[CLIENT-SPAWN] Vehicle " .. vehicleId .. " spawned successfully by client, NetId: " .. netId .. "^0")
    end
end)

-- =====================================================
-- LEGACY: Server-side spawn (giữ lại để backup)
-- =====================================================
lib.callback.register('xn_jobgarage:server:spawnVehicle', function(source, vehicleData)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { success = false, reason = 'no_player' }
    end
    
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return { success = false, reason = 'no_ped' }
    end
    
    local citizenid = Player.PlayerData.citizenid
    local jobName = vehicleData.jobName
    local garageName = vehicleData.garageName
    local vehicleModel = vehicleData.model
    
    if Config.Debug then
        print("^3[DEBUG] Spawn Vehicle Request:^0")
        print("  CitizenID: " .. citizenid)
        print("  Job: " .. jobName)
        print("  Garage: " .. garageName)
        print("  Vehicle Model: " .. vehicleModel)
    end
    
    -- Kiểm tra xe trong database
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE citizenid = ? AND job = ? AND garage = ?', {
        citizenid, jobName, garageName
    })
    
    if Config.Debug then
        print("^3[DEBUG] Database Query Result:^0")
        if result and result[1] then
            print("  Found vehicle in DB:")
            print("    Plate: " .. (result[1].plate or "N/A"))
            print("    Is Out: " .. tostring(result[1].is_out))
            print("    Body: " .. (result[1].body or 1000))
            print("    Engine: " .. (result[1].engine or 1000))
        else
            print("  No vehicle found - will create new")
        end
    end
    
    local plate = nil
    local vehicleMods = nil
    local bodyHealth = 1000
    local engineHealth = 1000
    local fuelLevel = 100
    
    if result and result[1] then
        -- Xe đã tồn tại, load dữ liệu
        plate = result[1].plate
        vehicleMods = result[1].mods and json.decode(result[1].mods) or nil
        
        -- ƯU TIÊN: Lấy từ cột body/engine trước, nếu null thì lấy từ mods
        bodyHealth = result[1].body
        engineHealth = result[1].engine
        fuelLevel = result[1].fuel or 100
        
        if not bodyHealth and vehicleMods and vehicleMods.bodyHealth then
            bodyHealth = vehicleMods.bodyHealth
        end
        bodyHealth = bodyHealth or 1000
        
        if not engineHealth and vehicleMods and vehicleMods.engineHealth then
            engineHealth = vehicleMods.engineHealth
        end
        engineHealth = engineHealth or 1000
        
        -- Update is_out = 0 (xe ra ngoài)
        MySQL.update('UPDATE job_vehicles SET is_out = 0 WHERE id = ?', { result[1].id })
        if Config.Debug then
            print("^2[DEBUG] Updated is_out = 0 (OUT) for vehicle ID: " .. result[1].id .. "^0")
        end
    else
        -- Xe mới, tạo plate mới
        plate = GenerateJobPlate(jobName)
        if Config.Debug then
            print("^2[DEBUG] Generated new plate: " .. plate .. "^0")
        end
    end
    
    -- XÓA TẤT CẢ XE TRÙNG BIỂN SỐ TRƯỚC KHI SPAWN
    local allVehicles = GetAllVehicles()
    local deletedCount = 0
    local trimmedPlate = string.gsub(plate, "%s+", "")
    for _, veh in ipairs(allVehicles) do
        if DoesEntityExist(veh) then
            local vehPlate = GetVehicleNumberPlateText(veh)
            if vehPlate and string.gsub(vehPlate, "%s+", "") == trimmedPlate then
                if Config.Debug then
                    print("^1[DEBUG] Found duplicate vehicle with plate: " .. vehPlate .. " - Deleting entity " .. veh .. "^0")
                end
                DeleteEntity(veh)
                deletedCount = deletedCount + 1
            end
        end
    end
    if deletedCount > 0 then
        if Config.Debug then
            print("^2[DEBUG] Deleted " .. deletedCount .. " duplicate vehicle(s) with plate: " .. plate .. "^0")
        end
        Wait(50) -- Short wait for deletion to sync
    end
    
    -- Spawn vehicle using qbx.spawnVehicle với props
    local vehicleProps = {}
    
    -- Nếu có mods, update bodyHealth/engineHealth trong mods trước khi merge
    if vehicleMods then
        -- XÓA PLATE TRONG MODS ĐỂ KHÔNG BỊ GHI ĐÈ SAI
        vehicleMods.plate = nil
        
        vehicleMods.bodyHealth = bodyHealth
        vehicleMods.engineHealth = engineHealth
        vehicleMods.tankHealth = bodyHealth  -- Tank cũng set theo body
        vehicleMods.fuelLevel = fuelLevel
        
        for k, v in pairs(vehicleMods) do
            vehicleProps[k] = v
        end
    else
        -- Không có mods, set trực tiếp
        vehicleProps.bodyHealth = bodyHealth
        vehicleProps.engineHealth = engineHealth
        vehicleProps.tankHealth = bodyHealth
    end
    
    -- SET PLATE SAU CÙNG - ĐẢM BẢO LẤY TỪ DB
    vehicleProps.plate = plate
    vehicleProps.bodyHealth = bodyHealth
    vehicleProps.engineHealth = engineHealth
    vehicleProps.fuelLevel = fuelLevel
    
    local netId, vehicle = qbx.spawnVehicle({
        model = vehicleData.model,
        spawnSource = vector4(vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w),
        warp = vehicleData.warpPlayer and GetPlayerPed(src) or nil,
        props = vehicleProps
    })
    
    if Config.Debug then
        print("^6[SERVER] Spawned with FORCED props - Body: " .. bodyHealth .. ", Engine: " .. engineHealth .. "^0")
    end
    
    if not netId or netId == 0 then
        return { success = false, reason = 'spawn_failed' }
    end
    
    -- Vehicle đã được tạo bởi qbx.spawnVehicle, không cần wait thêm
    if not DoesEntityExist(vehicle) then
        return { success = false, reason = 'vehicle_not_exist' }
    end
    
    -- Set fuel level
    Entity(vehicle).state.fuel = fuelLevel
    
    -- Nếu là lần đầu, lưu vào database
    if not result or not result[1] then
        MySQL.insert('INSERT INTO job_vehicles (citizenid, job, garage, vehicle, plate, mods, body, engine, fuel, is_out) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            citizenid, jobName, garageName, vehicleModel, plate, nil, 1000, 1000, 100, 0  -- 0 = OUT/NGOÀI
        })
    end
    
    -- XÓA PLATE TRONG MODS TRƯỚC KHI GỬI VỀ CLIENT (tránh ghi đè sai)
    local modsForClient = nil
    if vehicleMods then
        modsForClient = {}
        for k, v in pairs(vehicleMods) do
            if k ~= 'plate' then
                modsForClient[k] = v
            end
        end
    end
    
    if Config.Debug then
        print("^3[DEBUG] Returning vehicle data - Body: " .. bodyHealth .. ", Engine: " .. engineHealth .. ", Plate: " .. plate .. "^0")
    end
    
    return { 
        success = true, 
        netId = netId,
        vehicle = vehicle,
        plate = plate,
        bodyHealth = bodyHealth,
        engineHealth = engineHealth,
        fuelLevel = fuelLevel,
        vehicleMods = modsForClient,
        isFirstTime = not (result and result[1])
    }
end)

-- Callback kiểm tra xe có thể cất không (phải có trong SQL và is_out = 0)
lib.callback.register('xn_jobgarage:server:canStoreVehicle', function(source, jobName, garageName, plate)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        if Config.Debug then
            print("^1[STORE CHECK] No player found^0")
        end
        return { success = false, reason = 'Không tìm thấy thông tin người chơi' }
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    if Config.Debug then
        print("^3[STORE CHECK] Checking vehicle - Citizen: " .. citizenid .. ", Job: " .. jobName .. ", Garage: " .. garageName .. ", Plate: " .. plate .. "^0")
    end
    
    -- Kiểm tra xe trong database
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE citizenid = ? AND job = ? AND garage = ? AND plate = ?', {
        citizenid, jobName, garageName, plate
    })
    
    if not result or not result[1] then
        if Config.Debug then
            print("^1[STORE CHECK] Vehicle not found in database^0")
        end
        return { success = false, reason = 'Xe này không thuộc garage này' }
    end
    
    -- Kiểm tra is_out phải = 0 (xe đang ở ngoài)
    local isOutValue = result[1].is_out
    if type(isOutValue) == "boolean" then
        isOutValue = isOutValue and 1 or 0
    else
        isOutValue = tonumber(isOutValue) or 1
    end
    
    if Config.Debug then
        print("^3[STORE CHECK] Vehicle found - is_out: " .. tostring(result[1].is_out) .. " (converted: " .. isOutValue .. ")^0")
    end
    
    if isOutValue ~= 0 then
        if Config.Debug then
            print("^1[STORE CHECK] Vehicle already stored (is_out != 0)^0")
        end
        return { success = false, reason = 'Xe đã được cất rồi' }
    end
    
    if Config.Debug then
        print("^2[STORE CHECK] Vehicle can be stored!^0")
    end
    return { success = true }
end)

-- Event để lưu xe khi cất vào garage
RegisterNetEvent('xn_jobgarage:server:storeVehicle', function(jobName, garageName, vehicleData)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    local plate = vehicleData.plate
    
    -- XÓA PLATE KHỎI MODS TRƯỚC KHI LƯU (tránh ghi đè plate sai khi spawn)
    local modsToSave = vehicleData.mods or {}
    if modsToSave.plate then
        modsToSave.plate = nil
    end
    
    local mods = json.encode(modsToSave)
    local body = math.floor(vehicleData.body or 1000)
    local engine = math.floor(vehicleData.engine or 1000)
    local fuel = math.floor(vehicleData.fuel or 100)
    
    if Config.Debug then
        print("^3[STORE] Storing vehicle - Plate: " .. plate .. ", Body: " .. body .. ", Engine: " .. engine .. "^0")
    end
    
    -- Update database
    MySQL.update('UPDATE job_vehicles SET mods = ?, body = ?, engine = ?, fuel = ?, is_out = 1 WHERE citizenid = ? AND job = ? AND garage = ? AND plate = ?', {  -- 1 = IN/TRONG
        mods, body, engine, fuel, citizenid, jobName, garageName, plate
    })
    
    TriggerClientEvent('xn_jobgarage:client:vehicleStored', src)
end)

-- =====================================================
-- CLIENT-SIDE SPAWN BY ID: Server chỉ validate và trả data
-- =====================================================
lib.callback.register('xn_jobgarage:server:getVehicleDataByIdForSpawn', function(source, vehicleData)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { success = false, reason = 'no_player' }
    end
    
    local citizenid = Player.PlayerData.citizenid
    local vehicleId = vehicleData.vehicleId
    
    if Config.Debug then
        print("^3[CLIENT-SPAWN BY ID] Request - Vehicle ID: " .. tostring(vehicleId) .. ", CitizenID: " .. citizenid .. "^0")
    end
    
    -- Lấy thông tin xe từ database
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE id = ? AND citizenid = ?', {
        vehicleId, citizenid
    })
    
    if not result or not result[1] then
        return { success = false, reason = 'vehicle_not_found' }
    end
    
    local veh = result[1]
    
    -- CHECK: Xe đã ở ngoài thì không spawn nữa
    local isOutValue = veh.is_out
    if type(isOutValue) == "boolean" then
        isOutValue = isOutValue and 1 or 0
    else
        isOutValue = tonumber(isOutValue) or 1
    end
    
    if isOutValue == 0 then
        return { success = false, reason = 'vehicle_already_out' }
    end
    
    local plate = veh.plate
    local vehicleModel = veh.vehicle
    local vehicleMods = veh.mods and json.decode(veh.mods) or nil
    
    local bodyHealth = veh.body or 1000
    local engineHealth = veh.engine or 1000
    local fuelLevel = veh.fuel or 100
    
    if not bodyHealth and vehicleMods and vehicleMods.bodyHealth then
        bodyHealth = vehicleMods.bodyHealth
    end
    bodyHealth = bodyHealth or 1000
    
    if not engineHealth and vehicleMods and vehicleMods.engineHealth then
        engineHealth = vehicleMods.engineHealth
    end
    engineHealth = engineHealth or 1000
    
    -- XÓA XE TRÙNG BIỂN SỐ TỪ SERVER
    local allVehicles = GetAllVehicles()
    local trimmedPlate = string.gsub(plate, "%s+", "")
    for _, v in ipairs(allVehicles) do
        if DoesEntityExist(v) then
            local vehPlate = GetVehicleNumberPlateText(v)
            if vehPlate and string.gsub(vehPlate, "%s+", "") == trimmedPlate then
                DeleteEntity(v)
            end
        end
    end
    
    -- Update is_out = 0
    MySQL.update('UPDATE job_vehicles SET is_out = 0 WHERE id = ?', { veh.id })
    
    -- Tạo mods cho client (không có plate)
    local modsForClient = nil
    if vehicleMods then
        modsForClient = {}
        for k, v in pairs(vehicleMods) do
            if k ~= 'plate' then
                modsForClient[k] = v
            end
        end
    end
    
    if Config.Debug then
        print("^2[CLIENT-SPAWN BY ID] Returning data - Plate: " .. plate .. ", Model: " .. vehicleModel .. "^0")
    end
    
    return {
        success = true,
        vehicleId = veh.id,
        vehicleModel = vehicleModel,
        plate = plate,
        bodyHealth = bodyHealth,
        engineHealth = engineHealth,
        fuelLevel = fuelLevel,
        vehicleMods = modsForClient
    }
end)

-- =====================================================
-- LEGACY: Server-side spawn by ID (giữ lại để backup)
-- =====================================================
lib.callback.register('xn_jobgarage:server:spawnVehicleById', function(source, vehicleData)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { success = false, reason = 'no_player' }
    end
    
    local ped = GetPlayerPed(src)
    local citizenid = Player.PlayerData.citizenid
    
    if Config.Debug then
        print("^3[SPAWN BY ID] Request - Vehicle ID: " .. tostring(vehicleData.vehicleId) .. ", CitizenID: " .. citizenid .. "^0")
    end
    
    -- Lấy thông tin xe từ database - QUERY CHÍNH XÁC THEO ID
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE id = ? AND citizenid = ?', {
        vehicleData.vehicleId, citizenid
    })
    
    if not result or not result[1] then
        if Config.Debug then
            print("^1[SPAWN BY ID] Vehicle not found with ID: " .. tostring(vehicleData.vehicleId) .. "^0")
        end
        return { success = false, reason = 'vehicle_not_found' }
    end
    
    local veh = result[1]
    
    -- CHECK: Xe đã ở ngoài thì không spawn nữa
    local isOutValue = veh.is_out
    if type(isOutValue) == "boolean" then
        isOutValue = isOutValue and 1 or 0
    else
        isOutValue = tonumber(isOutValue) or 1
    end
    
    if isOutValue == 0 then
        if Config.Debug then
            print("^1[SPAWN BY ID] Vehicle already spawned (is_out = 0)^0")
        end
        return { success = false, reason = 'vehicle_already_out' }
    end
    
    local plate = veh.plate
    local vehicleModel = veh.vehicle
    local vehicleMods = veh.mods and json.decode(veh.mods) or nil
    
    if Config.Debug then
        print("^2[SPAWN BY ID] Found vehicle - ID: " .. veh.id .. ", Model: " .. vehicleModel .. ", Plate: " .. plate .. "^0")
        print("^2[SPAWN BY ID] Mods from DB: " .. tostring(veh.mods) .. "^0")
    end
    
    -- ƯU TIÊN: Lấy từ cột body/engine trước, nếu null thì lấy từ mods
    local bodyHealth = veh.body
    local engineHealth = veh.engine
    local fuelLevel = veh.fuel or 100
    
    if not bodyHealth and vehicleMods and vehicleMods.bodyHealth then
        bodyHealth = vehicleMods.bodyHealth
    end
    bodyHealth = bodyHealth or 1000
    
    if not engineHealth and vehicleMods and vehicleMods.engineHealth then
        engineHealth = vehicleMods.engineHealth
    end
    engineHealth = engineHealth or 1000
    
    -- XÓA XE TRÙNG BIỂN SỐ
    local allVehicles = GetAllVehicles()
    local deletedCount = 0
    local trimmedPlate = string.gsub(plate, "%s+", "")
    for _, v in ipairs(allVehicles) do
        if DoesEntityExist(v) then
            local vehPlate = GetVehicleNumberPlateText(v)
            if vehPlate and string.gsub(vehPlate, "%s+", "") == trimmedPlate then
                DeleteEntity(v)
                deletedCount = deletedCount + 1
            end
        end
    end
    if deletedCount > 0 then
        Wait(50) -- Short wait for deletion to sync
    end
    
    -- Spawn vehicle với props
    local vehicleProps = {}
    if vehicleMods then
        -- XÓA PLATE TRONG MODS ĐỂ KHÔNG BỊ GHI ĐÈ SAI
        vehicleMods.plate = nil
        
        -- FORCE update health trong mods trước khi merge
        vehicleMods.bodyHealth = bodyHealth
        vehicleMods.engineHealth = engineHealth
        vehicleMods.tankHealth = bodyHealth
        vehicleMods.fuelLevel = fuelLevel
        
        for k, v in pairs(vehicleMods) do
            vehicleProps[k] = v
        end
    else
        vehicleProps.bodyHealth = bodyHealth
        vehicleProps.engineHealth = engineHealth
        vehicleProps.tankHealth = bodyHealth
    end
    
    -- SET PLATE SAU CÙNG - ĐẢM BẢO LẤY TỪ DB
    vehicleProps.plate = plate
    vehicleProps.bodyHealth = bodyHealth
    vehicleProps.engineHealth = engineHealth
    vehicleProps.fuelLevel = fuelLevel
    
    local netId, vehicle = qbx.spawnVehicle({
        model = vehicleModel,
        spawnSource = vector4(vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.coords.w),
        warp = vehicleData.warpPlayer and GetPlayerPed(src) or nil,
        props = vehicleProps
    })
    
    if not netId or netId == 0 then
        return { success = false, reason = 'spawn_failed' }
    end
    
    -- Vehicle đã được tạo bởi qbx.spawnVehicle, không cần wait thêm
    if not DoesEntityExist(vehicle) then
        return { success = false, reason = 'vehicle_not_exist' }
    end
    
    -- Set fuel
    Entity(vehicle).state.fuel = fuelLevel
    
    -- Update is_out = 0
    MySQL.update('UPDATE job_vehicles SET is_out = 0 WHERE id = ?', { veh.id })
    
    if Config.Debug then
        print("^2[SPAWN BY ID] Spawned vehicle ID: " .. veh.id .. ", Plate: " .. plate .. "^0")
    end
    
    -- Tạo bản copy mods và xóa plate trước khi gửi về client
    local modsForClient = nil
    if vehicleMods then
        modsForClient = {}
        for k, v in pairs(vehicleMods) do
            if k ~= 'plate' then
                modsForClient[k] = v
            end
        end
    end
    
    return {
        success = true,
        netId = netId,
        plate = plate,
        bodyHealth = bodyHealth,
        engineHealth = engineHealth,
        fuelLevel = fuelLevel,
        vehicleMods = modsForClient
    }
end)

-- XÓA XE THEO ID
RegisterNetEvent('xn_jobgarage:server:deleteVehicleById', function(vehicleId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Verify ownership
    local result = MySQL.query.await('SELECT * FROM job_vehicles WHERE id = ? AND citizenid = ?', {
        vehicleId, citizenid
    })
    
    if result and result[1] then
        MySQL.query('DELETE FROM job_vehicles WHERE id = ?', { vehicleId })
        if Config.Debug then
            print("^2[DELETE] Deleted vehicle ID: " .. vehicleId .. "^0")
        end
    end
end)

-- THÊM XE MỚI
lib.callback.register('xn_jobgarage:server:addVehicle', function(source, data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return { success = false, reason = 'no_player' }
    end
    
    local citizenid = Player.PlayerData.citizenid
    local fee = data.fee or 0
    
    -- Check money
    if fee > 0 then
        local cashAmount = Player.PlayerData.money['cash'] or 0
        local bankAmount = Player.PlayerData.money['bank'] or 0
        
        if cashAmount + bankAmount < fee then
            return { success = false, reason = 'Không đủ tiền' }
        end
        
        -- Try cash first, then bank
        if cashAmount >= fee then
            Player.Functions.RemoveMoney('cash', fee, 'job-vehicle-purchase')
        elseif bankAmount >= fee then
            Player.Functions.RemoveMoney('bank', fee, 'job-vehicle-purchase')
        else
            return { success = false, reason = 'Không đủ tiền' }
        end
    end
    
    -- Generate plate
    local plate = string.upper(data.jobName:sub(1, 2))
    for i = 1, 6 do
        local rand = math.random(1, 3)
        if rand == 1 then
            plate = plate .. string.char(math.random(65, 90))
        else
            plate = plate .. math.random(0, 9)
        end
    end
    plate = plate:sub(1, 8)
    
    -- Lưu defaultMods nếu có từ config
    local modsJson = nil
    if data.defaultMods then
        modsJson = json.encode(data.defaultMods)
    end
    
    -- Insert into database
    MySQL.insert('INSERT INTO job_vehicles (citizenid, job, garage, vehicle, vehicle_label, plate, mods, body, engine, fuel, is_out) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenid,
        data.jobName,
        data.garageName,
        data.vehicleModel,
        data.vehicleLabel,
        plate,
        modsJson,
        1000,
        1000,
        100,
        1  -- IN garage
    })
    
    if Config.Debug then
        print("^2[ADD VEHICLE] Added " .. data.vehicleLabel .. " for " .. citizenid .. "^0")
    end
    
    return { success = true }
end)

-- Event để xóa xe cũ khi đổi xe (DEPRECATED - dùng deleteVehicleById)
RegisterNetEvent('xn_jobgarage:server:deleteVehicle', function(jobName, garageName)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Delete vehicle from database
    MySQL.query('DELETE FROM job_vehicles WHERE citizenid = ? AND job = ? AND garage = ?', {
        citizenid, jobName, garageName
    })
    
    if Config.Debug then
        print("^3[DEBUG] Deleted old vehicle for citizen: " .. citizenid .. " at garage: " .. garageName .. "^0")
    end
end)
