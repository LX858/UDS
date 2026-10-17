-- Admin commands để quản lý houses trong database

local QBX = exports.qbx_core

-- ========== NUI CALLBACKS ==========

-- Callback: Tạo nhà mới (từ UI)
lib.callback.register('qbx_housing:server:adminCreateHouse', function(source, data)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Player not found' end
    
    -- Validate admin permission
    if not IsPlayerAceAllowed(source, 'command.createhousing') then
        return false, 'Bạn không có quyền sử dụng lệnh này!'
    end
    
    -- Validate house ID
    if not data.id or data.id == '' then
        return false, 'House ID không được để trống!'
    end
    
    -- Check if ID exists
    local exists = MySQL.scalar.await('SELECT id FROM houses WHERE id = ?', {data.id})
    if exists then
        return false, 'House ID đã tồn tại trong database!'
    end
    
    -- Validate type
    if not Config.HouseTypes[data.type] then
        return false, 'Loại nhà không hợp lệ!'
    end
    
    -- Insert vào database
    local gangName = (data.gang and data.gang ~= '' and data.gang ~= 'none') and data.gang or nil
    local isGang = gangName ~= nil or data.type == 'gang'
    
    local interiorX = isGang and 346.60 or (type(data.interior) == 'table' and data.interior.x or 0.0)
    local interiorY = isGang and -1012.87 or (type(data.interior) == 'table' and data.interior.y or 0.0)
    local interiorZ = isGang and -99.20 or (type(data.interior) == 'table' and data.interior.z or 0.0)
    
    local storageX = isGang and 352.56 or (type(data.storage) == 'table' and data.storage.x or 0.0)
    local storageY = isGang and -998.95 or (type(data.storage) == 'table' and data.storage.y or 0.0)
    local storageZ = isGang and -99.64 or (type(data.storage) == 'table' and data.storage.z or 0.0)

    local success = MySQL.insert.await([[
        INSERT INTO houses (id, type, price, gang,
                            door_x, door_y, door_z,
                            interior_x, interior_y, interior_z,
                            storage_x, storage_y, storage_z,
                            juicer_x, juicer_y, juicer_z,
                            packaging_x, packaging_y, packaging_z,
                            exit_x, exit_y, exit_z,
                            garage_x, garage_y, garage_z,
                            spawn_x, spawn_y, spawn_z, spawn_h,
                            bed_x, bed_y, bed_z, bed_w)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.id, data.type, data.price or nil, gangName,
        data.door.x, data.door.y, data.door.z,
        interiorX, interiorY, interiorZ,
        storageX, storageY, storageZ,
        data.juicer and data.juicer.x or nil,
        data.juicer and data.juicer.y or nil,
        data.juicer and data.juicer.z or nil,
        data.packaging and data.packaging.x or nil,
        data.packaging and data.packaging.y or nil,
        data.packaging and data.packaging.z or nil,
        data.exit.x, data.exit.y, data.exit.z,
        data.garage.x, data.garage.y, data.garage.z,
        data.spawn.x, data.spawn.y, data.spawn.z, data.spawn.h,
        data.bed and data.bed.x or nil,
        data.bed and data.bed.y or nil,
        data.bed and data.bed.z or nil,
        data.bed and (data.bed.w or data.bed.h or 0.0) or nil
    })
    
    if success then        -- DEBUG LOG  
        --print('^2[QBX Housing DEBUG]^7 adminCreateHouse SUCCESS for house: ' .. data.id)
        --print('^2[QBX Housing DEBUG]^7   Type: ' .. data.type)
        --print('^2[QBX Housing DEBUG]^7   Price: ' .. tostring(data.price))
                ----print('[Admin] House created: ' .. data.id)
        
        -- Tạo house object
        local newHouse = {
            id = data.id,
            type = data.type,
            price = data.price or nil,
            gang = gangName,
            level = isGang and 1 or nil,
            blipColor = 1,
            door = vector3(data.door.x, data.door.y, data.door.z),
            interior = isGang and vector4(346.60, -1012.87, -99.20, 0.0) or vector3(interiorX, interiorY, interiorZ),
            storagePoint = vector3(storageX, storageY, storageZ),
            juicerPoint = data.juicer and vector3(data.juicer.x, data.juicer.y, data.juicer.z) or nil,
            packagingPoint = data.packaging and vector3(data.packaging.x, data.packaging.y, data.packaging.z) or nil,
            exitPoint = vector3(data.exit.x, data.exit.y, data.exit.z),
            garagePoint = vector3(data.garage.x, data.garage.y, data.garage.z),
            garageSpawn = vector4(data.spawn.x, data.spawn.y, data.spawn.z, data.spawn.h),
            bedPoint = data.bed and vector3(data.bed.x, data.bed.y, data.bed.z) or nil
        }
        
        -- Add vào server cache
        exports.qbx_housing:AddHouseToCache(newHouse)
        
        -- Tự động kích hoạt garage ngay lập tức cho Nhà Xã Đoàn
        if gangName and GetResourceState('mh_garage') == 'started' then
            pcall(function()
                exports.qbx_housing:CreateHouseGarage(source, data.id, newHouse, Config.HouseTypes[data.type])
            end)
        end
        
        -- Broadcast ADD event (chỉ 1 nhà)
        TriggerClientEvent('qbx_housing:client:addHouse', -1, newHouse)
        
        -- Broadcast to admin NUI in real-time
        local houseAdminItem = {
            id = data.id,
            type = data.type,
            price = data.price or nil,
            gang = gangName,
            door_x = data.door.x, door_y = data.door.y, door_z = data.door.z,
            interior_x = interiorX, interior_y = interiorY, interior_z = interiorZ,
            storage_x = storageX, storage_y = storageY, storage_z = storageZ,
            juicer_x = data.juicer and data.juicer.x or 0.0, juicer_y = data.juicer and data.juicer.y or 0.0, juicer_z = data.juicer and data.juicer.z or 0.0,
            packaging_x = data.packaging and data.packaging.x or 0.0, packaging_y = data.packaging and data.packaging.y or 0.0, packaging_z = data.packaging and data.packaging.z or 0.0,
            exit_x = data.exit.x, exit_y = data.exit.y, exit_z = data.exit.z,
            garage_x = data.garage.x, garage_y = data.garage.y, garage_z = data.garage.z,
            spawn_x = data.spawn.x, spawn_y = data.spawn.y, spawn_z = data.spawn.z, spawn_h = data.spawn.h,
            bed_x = data.bed and data.bed.x or nil, bed_y = data.bed and data.bed.y or nil, bed_z = data.bed and data.bed.z or nil, bed_w = data.bed and (data.bed.w or data.bed.h or 0.0) or nil,
            owner_name = nil
        }
        TriggerClientEvent('qbx_housing:client:adminHouseCreated', -1, houseAdminItem)
        
        return true, 'Tạo nhà thành công: ' .. data.id
    else
        return false, 'Lỗi khi lưu vào database!'
    end
end)

-- Callback: Lấy danh sách tất cả houses
lib.callback.register('qbx_housing:server:adminGetHousesList', function(source)
    local player = QBX:GetPlayer(source)
    if not player then return {} end
    
    if not IsPlayerAceAllowed(source, 'command.createhousing') then
        return {}
    end
    
    -- Get houses with ownership info (including bed_w for vector4 support)
    local result = MySQL.query.await([[
        SELECT h.id, h.type, h.price, h.label, h.enabled, h.gang,
               h.door_x, h.door_y, h.door_z,
               h.interior_x, h.interior_y, h.interior_z,
               h.storage_x, h.storage_y, h.storage_z,
               h.juicer_x, h.juicer_y, h.juicer_z,
               h.packaging_x, h.packaging_y, h.packaging_z,
               h.exit_x, h.exit_y, h.exit_z,
               h.garage_x, h.garage_y, h.garage_z,
               h.spawn_x, h.spawn_y, h.spawn_z, h.spawn_h,
               h.bed_x, h.bed_y, h.bed_z, h.bed_w,
               h.extra_data,
               ph.owner_name 
        FROM houses h
        LEFT JOIN player_houses ph ON h.id = ph.house_id
        WHERE h.enabled = 1
        ORDER BY h.type, h.id
    ]])
    
    return result or {}
end)

-- Callback: Cập nhật house
lib.callback.register('qbx_housing:server:adminUpdateHouse', function(source, data)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Player not found' end
    
    if not IsPlayerAceAllowed(source, 'command.createhousing') then
        return false, 'Bạn không có quyền sử dụng lệnh này!'
    end
    
    -- Validate house exists
    local exists = MySQL.scalar.await('SELECT id FROM houses WHERE id = ?', {data.id})
    if not exists then
        return false, 'House không tồn tại!'
    end
    
    -- Update database
    local gangName = (data.gang and data.gang ~= '' and data.gang ~= 'none') and data.gang or nil
    local isGang = gangName ~= nil or data.type == 'gang'
    
    local interiorX = isGang and 346.60 or (type(data.interior) == 'table' and data.interior.x or 0.0)
    local interiorY = isGang and -1012.87 or (type(data.interior) == 'table' and data.interior.y or 0.0)
    local interiorZ = isGang and -99.20 or (type(data.interior) == 'table' and data.interior.z or 0.0)
    
    local storageX = isGang and 352.56 or (type(data.storage) == 'table' and data.storage.x or 0.0)
    local storageY = isGang and -998.95 or (type(data.storage) == 'table' and data.storage.y or 0.0)
    local storageZ = isGang and -99.64 or (type(data.storage) == 'table' and data.storage.z or 0.0)

    local success = MySQL.update.await([[
        UPDATE houses SET
            type = ?, price = ?, gang = ?,
            door_x = ?, door_y = ?, door_z = ?,
            interior_x = ?, interior_y = ?, interior_z = ?,
            storage_x = ?, storage_y = ?, storage_z = ?,
            juicer_x = ?, juicer_y = ?, juicer_z = ?,
            packaging_x = ?, packaging_y = ?, packaging_z = ?,
            exit_x = ?, exit_y = ?, exit_z = ?,
            garage_x = ?, garage_y = ?, garage_z = ?,
            spawn_x = ?, spawn_y = ?, spawn_z = ?, spawn_h = ?,
            bed_x = ?, bed_y = ?, bed_z = ?, bed_w = ?
        WHERE id = ?
    ]], {
        data.type, data.price or nil, gangName,
        data.door.x, data.door.y, data.door.z,
        interiorX, interiorY, interiorZ,
        storageX, storageY, storageZ,
        data.juicer and data.juicer.x or nil,
        data.juicer and data.juicer.y or nil,
        data.juicer and data.juicer.z or nil,
        data.packaging and data.packaging.x or nil,
        data.packaging and data.packaging.y or nil,
        data.packaging and data.packaging.z or nil,
        data.exit.x, data.exit.y, data.exit.z,
        data.garage.x, data.garage.y, data.garage.z,
        data.spawn.x, data.spawn.y, data.spawn.z, data.spawn.h,
        data.bed and data.bed.x or nil,
        data.bed and data.bed.y or nil,
        data.bed and data.bed.z or nil,
        data.bed and (data.bed.w or data.bed.h or 0.0) or nil,
        data.id
    })
    
    if success then
        -- DEBUG LOG
        --print('^2[QBX Housing DEBUG]^7 adminUpdateHouse SUCCESS for house: ' .. data.id)
        --print('^2[QBX Housing DEBUG]^7   Type: ' .. data.type)
        --print('^2[QBX Housing DEBUG]^7   Door coords: ' .. data.door.x .. ', ' .. data.door.y .. ', ' .. data.door.z)
        
        --print('[Admin] House updated: ' .. data.id)
        
        -- Tạo updated house object
        local updatedGang = (data.gang and data.gang ~= '' and data.gang ~= 'none') and data.gang or nil
        local isGangHouse = updatedGang ~= nil or data.type == 'gang'
        local updatedHouse = {
            id = data.id,
            type = data.type,
            price = data.price or nil,
            gang = updatedGang,
            level = isGangHouse and 1 or nil,
            blipColor = 1,
            door = vector3(data.door.x, data.door.y, data.door.z),
            interior = isGangHouse and vector4(346.60, -1012.87, -99.20, 0.0) or vector3(interiorX, interiorY, interiorZ),
            storagePoint = vector3(storageX, storageY, storageZ),
            juicerPoint = data.juicer and vector3(data.juicer.x, data.juicer.y, data.juicer.z) or nil,
            packagingPoint = data.packaging and vector3(data.packaging.x, data.packaging.y, data.packaging.z) or nil,
            exitPoint = vector3(data.exit.x, data.exit.y, data.exit.z),
            garagePoint = vector3(data.garage.x, data.garage.y, data.garage.z),
            garageSpawn = vector4(data.spawn.x, data.spawn.y, data.spawn.z, data.spawn.h),
            bedPoint = data.bed and vector4(data.bed.x, data.bed.y, data.bed.z, data.bed.w or data.bed.h or 0.0) or nil
        }
        
        -- Update server cache
        exports.qbx_housing:UpdateHouseInCache(updatedHouse)
        
        -- Tự động kích hoạt/cập nhật garage cho Nhà Xã Đoàn
        if updatedGang and GetResourceState('mh_garage') == 'started' then
            pcall(function()
                exports.qbx_housing:CreateHouseGarage(source, data.id, updatedHouse, Config.HouseTypes[data.type])
            end)
        end
        
        -- Nếu nhà đã mua, update garage coords
        if GetResourceState('mh_garage') == 'started' then
            local garageName = 'house_' .. data.id
            if exports.qbx_housing:IsHouseGarage(garageName) then
                -- CRITICAL WARNING: Log this dangerous operation
                print('^3[QBX Housing CRITICAL]^7 Updating garage coords for: ' .. garageName)
                print('^3[QBX Housing CRITICAL]^7 OLD coords will be replaced - entities in garage may be affected!')
                
                -- Update garage coords (remove and recreate with new coords)
                -- IMPORTANT: Delete server-side garage first WITHOUT broadcasting to all clients
                local HouseGarages = exports.qbx_housing:GetHouseGaragesTable()
                if HouseGarages then
                    HouseGarages[garageName] = nil
                end
                
                -- Remove from mh_garage server cache
                pcall(function()
                    exports['mh_garage']:RemoveServerGarage(garageName)
                end)
                
                Wait(100)
                
                -- Recreate garage with new coords
                local houseType = Config.HouseTypes[data.type]
                if houseType and houseType.garage then
                    local garageConfig = {
                        type = 'car',
                        enter = updatedHouse.garagePoint,
                        parkVehicle = updatedHouse.garagePoint,
                        vehicleSpawnPoint = updatedHouse.garageSpawn,
                        price = nil,
                        pricetakeout = 0,
                        blip = { id = 0, scale = 0, colour = 0 },
                        blackListClass = { 14, 15, 16, 19, 21 },
                        GarageInfo = 'Garage nhà ' .. data.id,
                        interior = houseType.garage.interior
                    }
                    
                    -- Update server-side garage
                    exports['mh_garage']:InjectServerGarage(garageName, garageConfig)
                    
                    -- ONLY sync to players who are in this house or nearby
                    local playersToSync = {}
                    for _, playerId in ipairs(GetPlayers()) do
                        local targetId = tonumber(playerId)
                        local targetPed = GetPlayerPed(targetId)
                        local targetCoords = GetEntityCoords(targetPed)
                        local distance = #(vector3(data.door.x, data.door.y, data.door.z) - targetCoords)
                        
                        -- Sync to players within 500m of the house or in the house interior
                        if distance < 500.0 or GetPlayerRoutingBucket(targetId) == exports.qbx_housing:GetHouseBucket(data.id) then
                            TriggerClientEvent('qbx_housing:client:SyncHouseGarage', targetId, garageName, garageConfig)
                        end
                    end
                    --print('[Admin] Updated garage coords for: ' .. garageName .. ' (synced to ' .. #playersToSync .. ' nearby players)')
                end
            end
        end
        
        -- Broadcast UPDATE event (chỉ 1 nhà)
        --print('[Admin] Broadcasting updated house to all clients: ' .. data.id)
        TriggerClientEvent('qbx_housing:client:updateHouse', -1, updatedHouse)
        
        return true, 'Cập nhật thành công: ' .. data.id
    else
        return false, 'Lỗi khi cập nhật database!'
    end
end)

-- Callback: Xóa house
lib.callback.register('qbx_housing:server:adminDeleteHouse', function(source, houseId)
    local player = QBX:GetPlayer(source)
    if not player then return false, 'Player not found' end
    
    if not IsPlayerAceAllowed(source, 'command.createhousing') then
        return false, 'Bạn không có quyền sử dụng lệnh này!'
    end
    
    -- Hard delete from database
    local success = MySQL.query.await('DELETE FROM houses WHERE id = ?', {houseId})
    
    if success then
        -- Xóa ownership nếu có
        MySQL.query.await('DELETE FROM player_houses WHERE house_id = ?', {houseId})
        
        --print('[Admin] House deleted: ' .. houseId)
        
        -- Xóa garage nếu có
        if GetResourceState('mh_garage') == 'started' then
            local garageName = 'house_' .. houseId
            TriggerEvent('qbx_housing:server:DeleteHouseGarage', garageName)
            --print('[Admin] Deleted garage: ' .. garageName)
        end
        
        -- Remove khỏi server cache
        exports.qbx_housing:RemoveHouseFromCache(houseId)
        
        -- Broadcast DELETE event (chỉ 1 nhà)
        TriggerClientEvent('qbx_housing:client:deleteHouse', -1, houseId)
        TriggerClientEvent('qbx_housing:client:adminHouseDeleted', -1, houseId)
        
        return true, 'Xóa thành công'
    else
        return false, 'Lỗi khi xóa house!'
    end
end)

-- ========== OLD COMMANDS (DEPRECATED - DÙNG UI THAY THẾ) ==========

-- Command thêm house mới vào database

lib.addCommand('createhousing', {
    help = 'Thêm house mới vào database',
    restricted = 'group.admin'
}, function(source)
    local player = QBX:GetPlayer(source)
    if not player then return end

    TriggerClientEvent('qbx_housing:client:createHouse', source)
end)

lib.addCommand('addhouse', {
    help = 'Thêm house mới vào database',
    params = {
        { name = 'id', type = 'string', help = 'House ID (vd: slum_11)' },
        { name = 'type', type = 'string', help = 'House type: slum, regular, apartment, homestay' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local houseId = args.id
    local houseType = args.type
    
    -- Validate type
    if not Config.HouseTypes[houseType] then
        lib.notify(source, {
            title = 'Admin House',
            description = 'Loại nhà không hợp lệ! Chọn: slum, regular, apartment, homestay',
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra xem ID đã tồn tại chưa
    local exists = MySQL.scalar.await('SELECT id FROM houses WHERE id = ?', {houseId})
    if exists then
        lib.notify(source, {
            title = 'Admin House',
            description = 'House ID đã tồn tại!',
            type = 'error'
        })
        return
    end
    
    -- Lấy vị trí hiện tại của admin
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Insert vào database (dùng coords hiện tại cho tất cả)
    MySQL.insert.await([[
        INSERT INTO houses (id, type, door_x, door_y, door_z, interior_x, interior_y, interior_z,
                            storage_x, storage_y, storage_z, juicer_x, juicer_y, juicer_z,
                            packaging_x, packaging_y, packaging_z, exit_x, exit_y, exit_z,
                            garage_x, garage_y, garage_z, spawn_x, spawn_y, spawn_z, spawn_h)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        houseId, houseType,
        coords.x, coords.y, coords.z, -- door
        266.07, -1007.14, -101.0, -- interior (mặc định)
        266.42, -999.43, -98.90, -- storage (mặc định)
        264.20, -1002.50, -98.90, -- juicer (mặc định)
        268.50, -1001.00, -98.90, -- packaging (mặc định)
        coords.x, coords.y, coords.z, -- exit (same as door)
        coords.x + 5.0, coords.y, coords.z, -- garage (offset 5m)
        coords.x + 5.0, coords.y, coords.z, heading -- spawn
    })
    
    lib.notify(source, {
        title = 'Admin House',
        description = 'House ' .. houseId .. ' đã được tạo! Hãy dùng /edithouse để chỉnh sửa coords',
        type = 'success'
    })
    
    -- Reload houses
    TriggerEvent('qbx_housing:server:reloadHouses')
end)

-- Command chỉnh sửa coords của house
lib.addCommand('edithouse', {
    help = 'Chỉnh sửa coords của house',
    params = {
        { name = 'id', type = 'string', help = 'House ID' },
        { name = 'type', type = 'string', help = 'door/interior/storage/exit/garage/spawn' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local houseId = args.id
    local coordType = args.type
    
    -- Validate house exists
    local exists = MySQL.scalar.await('SELECT id FROM houses WHERE id = ?', {houseId})
    if not exists then
        lib.notify(source, {
            title = 'Admin House',
            description = 'House ID không tồn tại!',
            type = 'error'
        })
        return
    end
    
    -- Lấy vị trí hiện tại
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Update coords dựa vào type
    if coordType == 'door' then
        MySQL.update.await('UPDATE houses SET door_x = ?, door_y = ?, door_z = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, houseId})
    elseif coordType == 'interior' then
        MySQL.update.await('UPDATE houses SET interior_x = ?, interior_y = ?, interior_z = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, houseId})
    elseif coordType == 'storage' then
        MySQL.update.await('UPDATE houses SET storage_x = ?, storage_y = ?, storage_z = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, houseId})
    elseif coordType == 'juicer' then
        MySQL.update.await('UPDATE houses SET juicer_x = ?, juicer_y = ?, juicer_z = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, houseId})
    elseif coordType == 'packaging' then
        MySQL.update.await('UPDATE houses SET packaging_x = ?, packaging_y = ?, packaging_z = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, houseId})
    elseif coordType == 'exit' then
        MySQL.update.await('UPDATE houses SET exit_x = ?, exit_y = ?, exit_z = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, houseId})
    elseif coordType == 'garage' then
        MySQL.update.await('UPDATE houses SET garage_x = ?, garage_y = ?, garage_z = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, houseId})
    elseif coordType == 'spawn' then
        MySQL.update.await('UPDATE houses SET spawn_x = ?, spawn_y = ?, spawn_z = ?, spawn_h = ? WHERE id = ?',
            {coords.x, coords.y, coords.z, heading, houseId})
    else
        lib.notify(source, {
            title = 'Admin House',
            description = 'Type không hợp lệ! Chọn: door, interior, storage, juicer, packaging, exit, garage, spawn',
            type = 'error'
        })
        return
    end
    
    lib.notify(source, {
        title = 'Admin House',
        description = houseId .. ' - ' .. coordType .. ' coords đã cập nhật!',
        type = 'success'
    })
    
    -- Reload houses
    TriggerEvent('qbx_housing:server:reloadHouses')
end)

-- Command xóa house
lib.addCommand('deletehouse', {
    help = 'Xóa house khỏi database (disable)',
    params = {
        { name = 'id', type = 'string', help = 'House ID' }
    },
    restricted = 'group.admin'
}, function(source, args)
    local houseId = args.id
    
    -- Hard delete from database
    MySQL.query.await('DELETE FROM houses WHERE id = ?', {houseId})
    
    -- Xóa ownership nếu có
    MySQL.query.await('DELETE FROM player_houses WHERE house_id = ?', {houseId})
    
    lib.notify(source, {
        title = 'Admin House',
        description = 'House ' .. houseId .. ' đã bị xóa hoàn toàn',
        type = 'success'
    })
    
    -- Reload houses
    TriggerEvent('qbx_housing:server:reloadHouses')
end)

-- Command reload houses (refresh cache)
lib.addCommand('reloadhouses', {
    help = 'Reload tất cả houses từ database',
    restricted = 'group.admin'
}, function(source)
    TriggerEvent('qbx_housing:server:reloadHouses')
    
    lib.notify(source, {
        title = 'Admin House',
        description = 'Đã reload houses từ database',
        type = 'success'
    })
end)

-- Event reload houses
RegisterNetEvent('qbx_housing:server:reloadHouses', function()
    --print('[Admin] Reloading all houses...')
    
    -- BƯỚC 1: Clear all house garages trước khi reload
    if GetResourceState('mh_garage') == 'started' then
        -- Lấy tất cả houses hiện tại
        local currentHouses = exports.qbx_housing:GetAllHousesArray()
        for _, house in ipairs(currentHouses) do
            local garageName = 'house_' .. house.id
            -- Trigger event để remove garage (cả client và server)
            TriggerEvent('qbx_housing:server:DeleteHouseGarage', garageName)
        end
        --print('[Admin] Cleared all house garages before reload')
        Wait(200) -- Đợi garages clear xong
    end
    
    -- BƯỚC 2: Reload houses từ database
    -- Gọi hàm reload từ main.lua (nó sẽ clear cache và reload)
    TriggerEvent('qbx_housing:internal:reloadFromDB')
    
    -- Đợi 500ms cho DB load xong
    Wait(500)
    
    -- BƯỚC 3: Reload tất cả garages cho nhà đã mua
    if GetResourceState('mh_garage') == 'started' then
        local success = exports.qbx_housing:ReloadAllHouseGarages()
        if success then
            print('[Admin] Successfully reloaded all house garages')
        else
            print('[Admin] Failed to reload house garages')
        end
        Wait(200) -- Đợi garages sync xong
    end
    
    -- BƯỚC 4: Broadcast houses to all clients
    local housesArray = exports.qbx_housing:GetAllHousesArray()
    
    --print('[Admin] Broadcasting ' .. #housesArray .. ' houses to all clients')
    TriggerClientEvent('qbx_housing:client:reloadHouses', -1, housesArray)
end)
