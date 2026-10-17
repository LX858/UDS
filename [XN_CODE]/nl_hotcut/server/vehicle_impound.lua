-- ==================== VEHICLE IMPOUND MANAGEMENT ====================
-- Server-side logic cho quản lý xe bị tạm giam

local QBCore = exports['qb-core']:GetCoreObject()
local QBX = nil

if GetResourceState('qbx_core') == 'started' or GetResourceState('qbx_core') == 'starting' then
    QBX = exports.qbx_core
end

local function GetPlayer(source)
    if Config.Framework == 'qbx' and QBX then
        return QBX:GetPlayer(source)
    else
        return QBCore.Functions.GetPlayer(source)
    end
end

-- Lấy danh sách 30 lần xử phạt gần nhất (cả đang giam và đã lấy ra)
-- status = 1: Đã lấy ra, status = 2: Đang giam
lib.callback.register('mini-mdt:getActiveImpounds', function(source)
    local result = MySQL.query.await([[
        SELECT * FROM mini_mdt_vehicle_impound
        WHERE status IN (1, 2)
        ORDER BY impound_date DESC
        LIMIT 30
    ]], {})
    return result or {}
end)

-- Tìm kiếm theo PID chủ xe
lib.callback.register('mini-mdt:searchImpoundByOwnerPID', function(source, data)
    local playerId = data and (data.playerId or data.pid)
    if not playerId then return {} end
    
    local result = MySQL.query.await([[
        SELECT * FROM mini_mdt_vehicle_impound
        WHERE owner_pid = ?
        AND impound_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        ORDER BY impound_date DESC
    ]], { tonumber(playerId) })
    
    return result or {}
end)

-- Tìm kiếm theo PID cảnh sát
lib.callback.register('mini-mdt:searchImpoundByOfficerPID', function(source, data)
    local playerId = data and (data.playerId or data.pid)
    if not playerId then return {} end
    
    local result = MySQL.query.await([[
        SELECT * FROM mini_mdt_vehicle_impound
        WHERE officer_pid = ?
        AND impound_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        ORDER BY impound_date DESC
    ]], { tonumber(playerId) })
    
    return result or {}
end)

-- Ghi log khi có xe bị giam (callback để client chờ validation)
lib.callback.register('mini-mdt:impoundVehicle', function(source, data)
    if not data or not data.vehicle_plate then 
        return {success = false, message = 'Dữ liệu không hợp lệ'}
    end
    
    local Player = GetPlayer(source)
    if not Player then 
        return {success = false, message = 'Không tìm thấy player'}
    end
    
    -- Chuẩn hóa plate: Trim + Uppercase
    local trimmedPlate = string.upper(string.match(data.vehicle_plate, '^%s*(.-)%s*$'))
    data.vehicle_plate = trimmedPlate
    
    -- Nếu không có owner_citizenid, lấy từ plate
    if not data.owner_citizenid or data.owner_citizenid == '' then
        local vehicleResult = MySQL.query.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', { trimmedPlate })
        if vehicleResult and vehicleResult[1] then
            data.owner_citizenid = vehicleResult[1].citizenid
        else
            -- ❌ KHÔNG CHO GIAM XE KHÔNG CÓ CHỦ
            return {
                success = false, 
                message = '⚠️ Xe không có chủ nhân!\n\nXe này chỉ có thể XÓA, KHÔNG thể GIAM được.'
            }
        end
    end
    
    -- Nếu không có owner_name, lấy từ citizenid
    if not data.owner_name or data.owner_name == '' then
        local ownerResult = MySQL.query.await([[
            SELECT CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.firstname")), " ", JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.lastname"))) as name 
            FROM ]] .. Config.PlayersTable .. [[ WHERE citizenid = ? LIMIT 1
        ]], { data.owner_citizenid })
        
        data.owner_name = (ownerResult and ownerResult[1]) and ownerResult[1].name or 'Unknown'
    end
    
    -- Lấy PID của cảnh sát từ database (fallback từ client nếu đã gửi)
    local officerPid = data.officer_pid or 0
    if (not officerPid or officerPid == 0) and data.officer_citizenid and data.officer_citizenid ~= '' then
        local officerPidResult = MySQL.query.await('SELECT pid FROM ' .. Config.PlayersTable .. ' WHERE citizenid = ? LIMIT 1', { data.officer_citizenid })
        officerPid = (officerPidResult and officerPidResult[1]) and officerPidResult[1].pid or 0
    end
    
    -- Lấy PID của chủ xe từ citizenid (query cột pid trong players)
    local ownerPid = 0
    if data.owner_citizenid and data.owner_citizenid ~= '' and data.owner_citizenid ~= 'Unknown' then
        local ownerPidResult = MySQL.query.await('SELECT pid FROM ' .. Config.PlayersTable .. ' WHERE citizenid = ? LIMIT 1', { data.owner_citizenid })
        ownerPid = (ownerPidResult and ownerPidResult[1]) and ownerPidResult[1].pid or 0
    end
    
    -- ✅ CHUẨN HÓA PLATE: Trim + Uppercase (giống xn_policeimpound)
    local trimmedPlate = string.upper(string.match(data.vehicle_plate, '^%s*(.-)%s*$'))
    
    -- ✅ SET STATE = 2 TRONG player_vehicles (Đang tạm giam - giống xn_policeimpound)
    MySQL.execute('UPDATE player_vehicles SET state = 2 WHERE plate = ?', { trimmedPlate })
    
    -- Tính toán release_at từ duration_minutes
    local durationMinutes = data.duration_minutes or 60
    local releaseAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (durationMinutes * 60))
    
    -- ✅ INSERT VÀO mini_mdt_vehicle_impound (map đúng với schema)
    MySQL.insert.await([[
        INSERT INTO mini_mdt_vehicle_impound
            (officer_citizenid, officer_name, officer_pid, owner_citizenid, owner_name, owner_pid, 
             vehicle_plate, vehicle_model, offence, fine_amount, duration_until, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.officer_citizenid or '',
        data.officer_name or 'Unknown Officer',
        officerPid or 0,
        data.owner_citizenid or '',
        data.owner_name or 'Unknown Owner',
        ownerPid or 0,
        trimmedPlate,
        data.vehicle_model or '',
        data.offence or '',
        data.fine_amount or 0,
        releaseAt,
        data.status or 2  -- 2 = đang giam, 3 = cần mở khóa
    })
    
    return {
        success = true,
        message = 'Xe ' .. trimmedPlate .. ' đã bị tạm giam ' .. (data.duration_minutes or 60) .. ' phút'
    }
end)

-- Cập nhật trạng thái khi xe được lấy ra (từ mh_garage)
RegisterNetEvent('mini-mdt:server:releaseImpound', function(plate)
    if not plate then return end
    local trimmedPlate = string.upper(string.match(plate, '^%s*(.-)%s*$'))
    
    -- ✅ SET STATE = 0 TRONG player_vehicles (Xe bên ngoài / out - giống xn_policeimpound)
    -- Theo logic xn_policeimpound: state 0 = out/world, state 1 = garage, state 2 = impound
    MySQL.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ?', { trimmedPlate })
    
    -- Cập nhật status trong mini_mdt_vehicle_impound
    MySQL.execute([[
        UPDATE mini_mdt_vehicle_impound
        SET status = 1, released_at = NOW()
        WHERE vehicle_plate = ? AND status IN (2, 3)
        ORDER BY impound_date DESC
        LIMIT 1
    ]], { trimmedPlate })
end)

-- Backward compatibility wrapper cho TriggerServerEvent (không validation, chỉ log)
-- CHÚ Ý: Function này KHÔNG validate, chỉ dùng cho compatibility với code cũ
RegisterNetEvent('mini-mdt:server:logVehicleImpound', function(data)
    if not data or not data.vehicle_plate then return end
    
    local Player = GetPlayer(source)
    if not Player then return end
    
    local trimmedPlate = string.upper(string.match(data.vehicle_plate, '^%s*(.-)%s*$'))
    data.vehicle_plate = trimmedPlate
    
    -- Check owner (nếu không có thì skip - không notify vì là fire and forget)
    if not data.owner_citizenid or data.owner_citizenid == '' then
        local vehicleResult = MySQL.query.await('SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1', { trimmedPlate })
        if vehicleResult and vehicleResult[1] then
            data.owner_citizenid = vehicleResult[1].citizenid
        else
            -- Không có owner - skip
            return
        end
    end
    
    -- Lấy owner name
    if not data.owner_name or data.owner_name == '' then
        local ownerResult = MySQL.query.await([[
            SELECT CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.firstname")), " ", JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.lastname"))) as name 
            FROM ]] .. Config.PlayersTable .. [[ WHERE citizenid = ? LIMIT 1
        ]], { data.owner_citizenid })
        
        data.owner_name = (ownerResult and ownerResult[1]) and ownerResult[1].name or 'Unknown'
    end
    
    local officerPid = data.officer_pid or 0
    if (not officerPid or officerPid == 0) and data.officer_citizenid and data.officer_citizenid ~= '' then
        local officerPidResult = MySQL.query.await('SELECT pid FROM ' .. Config.PlayersTable .. ' WHERE citizenid = ? LIMIT 1', { data.officer_citizenid })
        officerPid = (officerPidResult and officerPidResult[1]) and officerPidResult[1].pid or 0
    end
    
    local ownerPid = 0
    if data.owner_citizenid and data.owner_citizenid ~= '' then
        local ownerPidResult = MySQL.query.await('SELECT pid FROM ' .. Config.PlayersTable .. ' WHERE citizenid = ? LIMIT 1', { data.owner_citizenid })
        ownerPid = (ownerPidResult and ownerPidResult[1]) and ownerPidResult[1].pid or 0
    end
    
    MySQL.execute('UPDATE player_vehicles SET state = 2 WHERE plate = ?', { trimmedPlate })
    
    local durationMinutes = data.duration_minutes or 60
    local durationUntil = os.date('%Y-%m-%d %H:%M:%S', os.time() + (durationMinutes * 60))
    
    MySQL.insert.await([[
        INSERT INTO mini_mdt_vehicle_impound
            (officer_citizenid, officer_name, officer_pid, owner_citizenid, owner_name, owner_pid,
             vehicle_plate, vehicle_model, offence, fine_amount, notes, duration_until, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.officer_citizenid or '',
        data.officer_name or 'Unknown',
        officerPid,
        data.owner_citizenid or '',
        data.owner_name or 'Unknown',
        ownerPid,
        trimmedPlate,
        data.vehicle_model or '',
        data.offence or '',
        data.fine_amount or 0,
        data.notes or '',
        durationUntil,
        data.status or 2
    })
end)

-- Export để các resource khác có thể gọi
exports('logVehicleImpound', function(data)
    TriggerEvent('mini-mdt:server:logVehicleImpound', data)
end)

-- Xóa xe: Nếu có chủ → SET state=0, Nếu không có chủ → Xóa khỏi world
lib.callback.register('mini-mdt:deleteVehicle', function(source, plate)
    if not plate then 
        return {success = false, message = 'Biển số không hợp lệ'}
    end
    
    local trimmedPlate = string.upper(string.match(plate, '^%s*(.-)%s*$'))
    
    -- Kiểm tra xe có tồn tại trong database
    local vehicleResult = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ? LIMIT 1', { trimmedPlate })
    
    if not vehicleResult or #vehicleResult == 0 then
        -- ✅ XE KHÔNG CÓ CHỦ: Chỉ xóa khỏi world, không cần update database
        return {
            success = true, 
            message = 'Đã xóa xe ' .. trimmedPlate .. ' khỏi world (xe không có chủ)'
        }
    end
    
    -- ✅ XE CÓ CHỦ: SET STATE = 0 (xe ở ngoài) - KHÔNG LƯU LOG
    MySQL.execute('UPDATE player_vehicles SET state = 0 WHERE plate = ?', { trimmedPlate })
    
    return {
        success = true, 
        message = 'Đã xóa xe ' .. trimmedPlate .. ' thành công'
    }
end)
