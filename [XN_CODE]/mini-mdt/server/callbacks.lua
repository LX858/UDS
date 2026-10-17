-- MINI MDT Server Callbacks
local QBCore = exports['qb-core']:GetCoreObject()
local QBX = nil

-- Try to load QBX if available
if GetResourceState('qbx_core') == 'started' or GetResourceState('qbx_core') == 'starting' then
    QBX = exports.qbx_core
end

-- Get nearby players within radius (server-side distance check)
lib.callback.register('mini-mdt:getNearbyPlayers', function(source, data)
    local radius = (data and data.radius) or 15.0
    local sourcePed = GetPlayerPed(source)
    local sourceCoords = GetEntityCoords(sourcePed)
    local nearby = {}

    -- Kiểm tra ped của cảnh sát có hợp lệ không
    if sourceCoords.x == 0.0 and sourceCoords.y == 0.0 and sourceCoords.z == 0.0 then
        return nearby
    end

    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid ~= source then
            local ped = GetPlayerPed(pid)
            local coords = GetEntityCoords(ped)

            -- Bỏ qua player có ped chưa spawn (tọa độ 0,0,0)
            if not (coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0) then
                local dist = #(vector3(sourceCoords.x, sourceCoords.y, sourceCoords.z) - vector3(coords.x, coords.y, coords.z))
                if dist <= radius then
                    -- Look up player name + citizenid from QBX/QBCore
                    local Player = nil
                    if Config.Framework == 'qbx' and QBX then
                        Player = QBX:GetPlayer(pid)
                    else
                        Player = QBCore.Functions.GetPlayer(pid)
                    end
                    if Player then
                        local charinfo = Player.PlayerData.charinfo
                        table.insert(nearby, {
                            playerId = Player.PlayerData.source,
                            citizenid = Player.PlayerData.citizenid,
                            name = charinfo.firstname .. ' ' .. charinfo.lastname,
                            dist = math.floor(dist * 10) / 10,
                        })
                    end
                end
            end
        end
    end

    -- Sort by distance ascending
    table.sort(nearby, function(a, b) return a.dist < b.dist end)
    return nearby
end)

-- Helper function to get player
function GetPlayer(source)
    local Player = nil
    if Config.Framework == 'qbx' and QBX then
        local success, result = pcall(function()
            return QBX:GetPlayer(source)
        end)
        if success then Player = result end
    end
    if not Player then
        Player = QBCore.Functions.GetPlayer(source)
    end
    return Player
end

-- Helper function to get player full name safely
function GetPlayerFullName(Player)
    if not Player or not Player.PlayerData or not Player.PlayerData.charinfo then
        return 'Unknown Officer'
    end
    local charinfo = Player.PlayerData.charinfo
    local firstname = charinfo.firstname or ''
    local lastname = charinfo.lastname or ''
    if firstname == '' and lastname == '' then
        return 'Unknown Officer'
    end
    return firstname .. ' ' .. lastname
end

-- Helper function to get player job grade name safely
function GetPlayerGradeName(Player)
    if not Player or not Player.PlayerData or not Player.PlayerData.job then
        return 'Officer'
    end
    local job = Player.PlayerData.job
    local grade = job.grade
    if not grade then
        return 'Officer'
    end
    if type(grade) == 'table' then
        return grade.name or grade.label or 'Officer'
    end
    -- If grade is a number or string, try to look up in Shared.Jobs config
    local gradeStr = tostring(grade)
    if QBCore and QBCore.Shared and QBCore.Shared.Jobs and QBCore.Shared.Jobs[job.name] then
        local jobInfo = QBCore.Shared.Jobs[job.name]
        if jobInfo.grades and jobInfo.grades[gradeStr] then
            return jobInfo.grades[gradeStr].name or jobInfo.grades[gradeStr].label or 'Officer'
        end
    end
    return 'Officer Grade ' .. gradeStr
end

-- Helper function to get all players
function GetQBPlayers()
    if Config.Framework == 'qbx' and QBX then
        return QBX:GetQBPlayers()
    else
        return QBCore.Functions.GetQBPlayers()
    end
end

-- Helper function to get player by citizenid
function GetPlayerByCitizenId(citizenid)
    if Config.Framework == 'qbx' and QBX then
        return QBX:GetPlayerByCitizenId(citizenid)
    else
        return QBCore.Functions.GetPlayerByCitizenId(citizenid)
    end
end

local function GetPayloadPlayerId(data)
    if type(data) == 'table' then
        return tonumber(data.playerId or data.pid or data.offenderPlayerId or data.offenderPid or data.targetPlayerId or data.targetPid)
    end

    return tonumber(data)
end

local function GetPayloadName(data)
    if type(data) == 'table' then
        local value = data.name or data.playerName or data.query or data.search or data.searchTerm
        if value then
            value = tostring(value):gsub('^%s+', ''):gsub('%s+$', '')
            if value ~= '' then return value end
        end
    elseif data ~= nil then
        local value = tostring(data):gsub('^%s+', ''):gsub('%s+$', '')
        if value ~= '' then return value end
    end

    return nil
end

local function BuildPlayerPayload(Player)
    if not Player then return nil end

    local sourceId = tonumber(Player.PlayerData.source)
    return {
        playerId = sourceId,
        citizenid = Player.PlayerData.citizenid,
        name = GetPlayerFullName(Player),
        source = sourceId
    }
end

local function SendPlayerToCommunityService(targetPlayerId, actionsCount, officerSource)
    local targetId = tonumber(targetPlayerId)
    local actions = tonumber(actionsCount)
    local officerId = tonumber(officerSource)

    if not targetId or not actions or actions <= 0 then
        print(('[MINI_MDT] Invalid community service payload target=%s actions=%s officer=%s'):format(
            tostring(targetPlayerId),
            tostring(actionsCount),
            tostring(officerSource)
        ))
        return false
    end

    if GetResourceState('nl_hotcut') == 'started' then
        print(('[MINI_MDT] Sending to nl_hotcut export targetPlayerId=%s actions=%s officer=%s'):format(
            tostring(targetId),
            tostring(actions),
            tostring(officerId)
        ))
        local ok, applied, result = pcall(function()
            return exports['nl_hotcut']:SendToCommunityService(targetId, actions, officerId)
        end)

        if not ok then
            print('[MINI_MDT] nl_hotcut export SendToCommunityService failed: ' .. tostring(applied))
            return false
        end

        if not applied then
            print('[MINI_MDT] nl_hotcut did not apply community service: ' .. tostring(result))
            return false
        end

        print('[MINI_MDT] nl_hotcut applied community service, actions=' .. tostring(result))
        return true
    end

    print('[MINI_MDT] nl_hotcut is not started, cannot apply community service')
    return false
end

-- Search players by PID/ID/Name
lib.callback.register('mini-mdt:searchPlayers', function(source, searchTerm)
    if not searchTerm or searchTerm == '' then
        return {}
    end
    
    -- Search by PID (id), citizenid, or name
    local query = [[
        SELECT 
            id as pid,
            citizenid,
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) as name,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.phone')) as phone,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.nationality')) as nationality
        FROM ]] .. Config.PlayersTable .. [[
        WHERE 
            id LIKE ? OR
            citizenid LIKE ? OR
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) LIKE ?
        LIMIT 20
    ]]
    
    local searchPattern = '%' .. searchTerm .. '%'
    local result = MySQL.query.await(query, {searchPattern, searchPattern, searchPattern})
    
    return result or {}
end)

lib.callback.register('mini-mdt:searchOfflinePrisonPlayers', function(source, data)
    local name = GetPayloadName(data)
    if not name or #name < 2 then
        return {}
    end

    local normalizedName = name:lower():gsub('%s+', ' ')
    local searchPattern = '%' .. normalizedName .. '%'

    local params = {searchPattern, searchPattern, searchPattern, searchPattern, searchPattern}
    local tokenClauses = {}
    for token in normalizedName:gmatch('%S+') do
        if #token >= 2 then
            table.insert(tokenClauses, [[
                (
                    LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname'))) LIKE ?
                    OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) LIKE ?
                )
            ]])
            local tokenPattern = '%' .. token .. '%'
            table.insert(params, tokenPattern)
            table.insert(params, tokenPattern)
        end
    end

    local extraTokenWhere = ''
    if #tokenClauses > 0 then
        extraTokenWhere = ' OR (' .. table.concat(tokenClauses, ' AND ') .. ')'
    end

    local result = MySQL.query.await([[
        SELECT
            pid,
            citizenid,
            CONCAT(
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')),
                ' ',
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))
            ) as name,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.phone')) as phone
        FROM ]] .. Config.PlayersTable .. [[
        WHERE LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname'))) LIKE ?
            OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) LIKE ?
            OR LOWER(CONCAT(
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')),
                ' ',
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))
            )) LIKE ?
            OR LOWER(CONCAT(
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')),
                ' ',
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname'))
            )) LIKE ?
            OR LOWER(citizenid) LIKE ?
            ]] .. extraTokenWhere .. [[
        ORDER BY name ASC
        LIMIT 20
    ]], params)

    return result or {}
end)

-- Get player info by PID (for offline prison - no distance/online check)
lib.callback.register('mini-mdt:getPlayerByPID', function(source, pid)
    print('[MDT SERVER] getPlayerByPID called with PID:', pid)
    
    local query = [[
        SELECT 
            pid,
            citizenid,
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) as name,
            JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.phone')) as phone
        FROM ]] .. Config.PlayersTable .. [[
        WHERE pid = ?
        LIMIT 1
    ]]
    
    local result = MySQL.query.await(query, {pid})
    print('[MDT SERVER] Query result:', json.encode(result))
    
    if result and #result > 0 then
        return {
            success = true,
            data = {
                pid = result[1].pid,
                citizenid = result[1].citizenid,
                name = result[1].name,
                phone = result[1].phone or 'N/A'
            }
        }
    else
        return {
            success = false,
            error = 'Không tìm thấy người chơi với ID này'
        }
    end
end)

-- Get all records
lib.callback.register('mini-mdt:getRecords', function(source)
    local recordsList = {}
    for id, record in pairs(Records) do
        local recordData = {
            id = record.id,
            title = record.title,
            description = record.description,
            handler_officer_name = record.handler_officer_name,
            handler_officer_rank = record.handler_officer_rank,
            status = record.status,
            created_by = record.created_by,
            created_by_name = record.created_by_name,
            created_date = record.created_date
        }
        table.insert(recordsList, recordData)
    end
    
    -- Sort by ID desc
    table.sort(recordsList, function(a, b) return a.id > b.id end)
    
    return recordsList
end)

-- Get today records
lib.callback.register('mini-mdt:getTodayRecords', function(source)
    local result = MySQL.query.await([[
        SELECT * FROM mini_mdt_records 
        WHERE DATE(created_date) = CURDATE()
        ORDER BY id DESC
        LIMIT 100
    ]], {})
    
    if not result then
        return {}
    end
    
    return result
end)

-- Search records by handler name (firstname + lastname)
lib.callback.register('mini-mdt:searchRecordsByHandler', function(source, data)
    local name = GetPayloadName(data)
    if not name then
        return {}
    end

    local search = '%' .. name .. '%'

    local records = MySQL.query.await([[
        SELECT * FROM mini_mdt_records
        WHERE handler_officer_name LIKE ?
        AND created_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        ORDER BY id DESC
        LIMIT 100
    ]], {search})
    
    return records or {}
end)

-- Search records by offender name (firstname + lastname, 30 days)
lib.callback.register('mini-mdt:searchRecordsByOffender', function(source, data)
    local name = GetPayloadName(data)
    if not name then
        return {}
    end

    local search = '%' .. name .. '%'

    local records = MySQL.query.await([[
        SELECT DISTINCT r.*
        FROM mini_mdt_records r
        INNER JOIN mini_mdt_offenders o ON r.id = o.record_id
        WHERE o.offender_name LIKE ?
        AND r.created_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        ORDER BY r.id DESC
        LIMIT 100
    ]], {search})
    
    return records or {}
end)

-- Get record detail
lib.callback.register('mini-mdt:getRecordDetail', function(source, recordId)
    
    -- Get record from database
    local records = MySQL.query.await('SELECT * FROM mini_mdt_records WHERE id = ?', {recordId})
    if not records or #records == 0 then
        return nil
    end
    
    local record = records[1]
    
    -- Get participating officers
    local officers = MySQL.query.await('SELECT * FROM mini_mdt_case_officers WHERE record_id = ?', {recordId})
    
    -- Get offenders with charges and penalties
    local offenders = MySQL.query.await([[
        SELECT 
            offender_id,
            offender_name,
            GROUP_CONCAT(charge_name SEPARATOR ', ') as charges,
            SUM(fine_amount) as total_fine,
            SUM(jail_time) as total_jail
        FROM mini_mdt_offenders 
        WHERE record_id = ?
        GROUP BY offender_id, offender_name
    ]], {recordId})
    
    -- Get all charges details
    local charges = MySQL.query.await([[
        SELECT 
            charge_id,
            charge_name,
            fine_amount,
            jail_time,
            offender_name
        FROM mini_mdt_offenders 
        WHERE record_id = ?
        ORDER BY charge_name
    ]], {recordId})
    
    -- Get current Player IDs for online offenders.
    if offenders and #offenders > 0 then
        for i, offender in ipairs(offenders) do
            local offenderPlayer = GetPlayerByCitizenId(offender.offender_id)
            if offenderPlayer then
                offender.offender_pid = offenderPlayer.PlayerData.source
            else
                offender.offender_pid = 'N/A'
            end
        end
    end
    
    return {
        record = record,
        offenders = offenders or {},
        charges = charges or {},
        officers = officers or {}
    }
end)

-- Create new record
lib.callback.register('mini-mdt:createRecord', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return false end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    local recordId = MySQL.insert.await([[
        INSERT INTO mini_mdt_records (title, description, crime_tags, status, created_by, created_by_name)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        data.title,
        data.description or '',
        json.encode(data.crime_tags or {}),
        'open',
        Player.PlayerData.citizenid,
        playerName
    })
    
    if recordId then
        -- Add to memory
        Records[recordId] = {
            id = recordId,
            title = data.title,
            description = data.description or '',
            crime_tags = data.crime_tags or {},
            status = 'open',
            created_by = Player.PlayerData.citizenid,
            created_by_name = playerName,
            created_date = os.date('%Y-%m-%d %H:%M:%S')
        }
        
        SendNotify(source, 'Thành công', Locale['record_created'], 'success')
        return recordId
    end
    
    return false
end)

-- Add offender to record
lib.callback.register('mini-mdt:addOffender', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return false end
    
    local offenderId = MySQL.insert.await([[
        INSERT INTO mini_mdt_offenders (record_id, player_id, player_name, player_avatar, charges, added_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        data.recordId,
        data.playerId,
        data.playerName,
        data.playerAvatar or Config.DefaultAvatar,
        json.encode(data.charges or {}),
        Player.PlayerData.citizenid
    })
    
    if offenderId then
        if not Offenders[data.recordId] then
            Offenders[data.recordId] = {}
        end
        
        local offender = {
            id = offenderId,
            record_id = data.recordId,
            player_id = data.playerId,
            player_name = data.playerName,
            player_avatar = data.playerAvatar or Config.DefaultAvatar,
            charges = data.charges or {},
            added_by = Player.PlayerData.citizenid,
            added_date = os.date('%Y-%m-%d %H:%M:%S')
        }
        
        table.insert(Offenders[data.recordId], offender)
        SendNotify(source, 'Thành công', Locale['offender_added'], 'success')
        return offender
    end
    
    return false
end)

-- Add fine
lib.callback.register('mini-mdt:addFine', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return false end
    
    local fineId = MySQL.insert.await([[
        INSERT INTO mini_mdt_fines (record_id, offender_id, player_id, fine_type, amount, jail_time, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.recordId,
        data.offenderId,
        data.playerId,
        data.fineType,
        data.amount,
        data.jailTime,
        Player.PlayerData.citizenid
    })
    
    if fineId then
        if not Fines[data.recordId] then
            Fines[data.recordId] = {}
        end
        
        local fine = {
            id = fineId,
            record_id = data.recordId,
            offender_id = data.offenderId,
            player_id = data.playerId,
            fine_type = data.fineType,
            amount = data.amount,
            jail_time = data.jailTime,
            paid = 0,
            created_by = Player.PlayerData.citizenid,
            created_date = os.date('%Y-%m-%d %H:%M:%S')
        }
        
        table.insert(Fines[data.recordId], fine)
        SendNotify(source, 'Thành công', Locale['fine_added'], 'success')
        return fine
    end
    
    return false
end)

-- Add officer to case
lib.callback.register('mini-mdt:addOfficer', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return false end
    
    local officerId = MySQL.insert.await([[
        INSERT INTO mini_mdt_case_officers (record_id, officer_id, officer_name, officer_rank)
        VALUES (?, ?, ?, ?)
    ]], {
        data.recordId,
        data.officerId,
        data.officerName,
        data.officerRank or 'Officer'
    })
    
    if officerId then
        SendNotify(source, 'Thành công', 'Đã thêm cảnh sát vào vụ án', 'success')
        return true
    end
    
    return false
end)

-- Get online officers (only on-duty) - OPTIMIZED WITH EVENT-DRIVEN SYSTEM
lib.callback.register('mini-mdt:getOnlineOfficers', function(source)
    -- Chuyển từ table key-value sang array
    local officers = {}
    for src, officer in pairs(OnlineOfficers) do
        officers[#officers + 1] = officer
    end
    return officers
end)

-- Helper function
function SendNotify(source, title, message, type)
    TriggerClientEvent('QBCore:Notify', source, message, type)
end

-- ========== NEW CASE WORKFLOW ==========

-- Get current officer info
lib.callback.register('mini-mdt:getCurrentOfficer', function(source)
    local Player = GetPlayer(source)
    if not Player then return nil end
    
    local name = GetPlayerFullName(Player)
    local rank = GetPlayerGradeName(Player)
    
    -- Dynamically ensure they are registered in OnlineOfficers if they have police job & are on duty
    if not OnlineOfficers[source] then
        local job = Player.PlayerData.job
        if Config.AllowedJobs[job.name] and job.onduty then
            OnlineOfficers[source] = {
                source = source,
                playerId = source,
                citizenid = Player.PlayerData.citizenid,
                name = name,
                rank = rank,
                onduty = true
            }
        end
    end
    
    return {
        source = source,
        playerId = source,
        citizenid = Player.PlayerData.citizenid,
        name = name,
        rank = rank
    }
end)

-- Get player info by Player ID (from ONLINE players)
lib.callback.register('mini-mdt:getPlayerInfo', function(source, data)
    -- Wrap everything in pcall to GUARANTEE a response
    local mainSuccess, mainResult = pcall(function()
        local searchValue = GetPayloadPlayerId(data)
        
        if not searchValue then
            return { success = false, error = 'No Player ID provided' }
        end
        
        -- Get officer position
        local officerPed = GetPlayerPed(source)
        local officerCoords = GetEntityCoords(officerPed)
        
        -- Search in ONLINE players only (like getOnlineOfficers)
        local Players = GetQBPlayers()
        local searchPlayerId = tonumber(searchValue)
        
        for k, v in pairs(Players) do
            local playerId = tonumber(v.PlayerData.source)

            if playerId == searchPlayerId then
                -- Check distance (10m radius)
                local targetPed = GetPlayerPed(v.PlayerData.source)
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(officerCoords - targetCoords)
                
                if distance > 10.0 then
                    return { success = false, error = 'Không có tội phạm gần đây' }
                end
                
                local playerData = BuildPlayerPayload(v)
                return { success = true, data = playerData }
            end
        end
        
        return { success = false, error = 'Player not online or not found' }
    end)
    
    -- If ANY error occurs, return error response
    if not mainSuccess then
        return { success = false, error = 'Server error: ' .. tostring(mainResult) }
    end
    
    return mainResult
end)

-- Get Player Info (No distance limit - for offline prison)
lib.callback.register('mini-mdt:getPlayerInfoNoLimit', function(source, data)
    local searchValue = data.playerId or data.pid or data.citizenid
    
    if not searchValue then
        return { success = false, error = 'Không có ID' }
    end
    
    print('[MDT] Searching player with PID:', searchValue)
    
    -- Search in database (online or offline)
    local result = MySQL.query.await([[
        SELECT 
            id as pid,
            citizenid,
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) as name
        FROM ]] .. Config.PlayersTable .. [[
        WHERE id = ? OR citizenid = ?
        LIMIT 1
    ]], {searchValue, tostring(searchValue)})
    
    print('[MDT] Database result:', json.encode(result))
    
    if not result or #result == 0 then
        return { success = false, error = 'Không tìm thấy người chơi với ID này' }
    end
    
    local playerData = {
        pid = result[1].pid,
        citizenid = result[1].citizenid,
        name = result[1].name
    }
    
    return { success = true, data = playerData }
end)

-- Finalize case (create record, send to jail, create fine)
lib.callback.register('mini-mdt:finalizeCase', function(source, data)
    
    local Player = GetPlayer(source)
    if not Player then 
        return {success = false, message = 'Không tìm thấy người chơi'}
    end
    
    -- Validate data
    if not data.offenders or #data.offenders == 0 then
        return {success = false, message = 'Chưa có tội phạm'}
    end
    
    if not data.charges or #data.charges == 0 then
        return {success = false, message = 'Chưa có tội danh'}
    end
    
    if not data.handler then
        return {success = false, message = 'Chưa có người xử lý'}
    end
    
    -- Create charge names list for title
    local chargeNames = {}
    for _, charge in ipairs(data.charges) do
        table.insert(chargeNames, charge.name)
    end
    local chargesTitle = table.concat(chargeNames, ', ')
    
    -- Create offender names list for title
    local offenderNames = {}
    for _, offender in ipairs(data.offenders) do
        table.insert(offenderNames, offender.name)
    end
    local offendersTitle = table.concat(offenderNames, ', ')
    
    -- Create record
    local title = offendersTitle .. ' - ' .. chargesTitle
    
    local recordId = MySQL.insert.await([[
        INSERT INTO mini_mdt_records 
        (title, description, handler_officer_id, handler_officer_name, handler_officer_rank, status, created_by, created_by_name)
        VALUES (?, ?, ?, ?, ?, 'closed', ?, ?)
    ]], {
        title,
        data.notes or '',
        data.handler.citizenid,
        data.handler.name,
        data.handler.rank or 'Officer',
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    })
    
    if not recordId then
        return {success = false, message = 'Không thể tạo hồ sơ'}
    end
    
    -- Add participating officers
    if data.officers and #data.officers > 0 then
        for _, officer in ipairs(data.officers) do
            MySQL.insert.await([[
                INSERT INTO mini_mdt_case_officers (record_id, officer_id, officer_name, officer_rank)
                VALUES (?, ?, ?, ?)
            ]], {recordId, officer.citizenid, officer.name, officer.rank})
        end
    end
    
    -- Process each offender
    for _, offender in ipairs(data.offenders) do
        -- Add each charge for this offender
        for _, charge in ipairs(data.charges) do
            MySQL.insert.await([[
                INSERT INTO mini_mdt_offenders 
                (record_id, offender_id, offender_name, charge_id, charge_name, fine_amount, jail_time, status, added_by)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)
            ]], {
                recordId,
                offender.citizenid,
                offender.name,
                charge.id,
                charge.name,
                charge.selectedFine,
                charge.selectedJail,
                Player.PlayerData.citizenid
            })
        end
        
        -- Apply penalties to offender
        local targetSource = GetPlayerByCitizenId(offender.citizenid)
        if targetSource then
            local targetPlayer = GetPlayer(targetSource.PlayerData.source)
            if targetPlayer then
                local targetSourceId = targetPlayer.PlayerData.source
                local handlerPlayer = GetPlayer(source)
                
                -- Tạo hóa đơn tự động thanh toán (giống okokBilling)
                if data.totalFine > 0 then
                    local targetName = '[' .. targetPlayer.PlayerData.source .. '] ' .. targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
                    local handlerName = '[' .. handlerPlayer.PlayerData.source .. '] ' .. handlerPlayer.PlayerData.charinfo.firstname .. ' ' .. handlerPlayer.PlayerData.charinfo.lastname
                    
                    local invoiceValue = math.ceil(data.totalFine)
                    local playerBankMoney = targetPlayer.PlayerData.money.bank or 0
                    local playerCashMoney = targetPlayer.PlayerData.money.cash or 0
                    local totalAvailableMoney = playerBankMoney + playerCashMoney
                    
                    -- Tính toán số tiền trừ từ bank và cash
                    local amountFromBank = 0
                    local amountFromCash = 0
                    local remainingAmount = invoiceValue
                    local paymentSuccess = false
                    local paymentDetails = {}
                    
                    -- Bước 1: Trừ từ bank trước (nếu có)
                    if playerBankMoney > 0 then
                        amountFromBank = math.min(playerBankMoney, remainingAmount)
                        local bankSuccess = targetPlayer.Functions.RemoveMoney('bank', amountFromBank, 'Phạt cảnh sát - Ngân hàng')
                        if bankSuccess then
                            remainingAmount = remainingAmount - amountFromBank
                            table.insert(paymentDetails, 'Ngân hàng: $' .. amountFromBank)
                        end
                    end
                    
                    -- Bước 2: Nếu còn thiếu, trừ tiếp từ cash
                    if remainingAmount > 0 and playerCashMoney > 0 then
                        amountFromCash = math.min(playerCashMoney, remainingAmount)
                        local cashSuccess = targetPlayer.Functions.RemoveMoney('cash', amountFromCash, 'Phạt cảnh sát - Tiền mặt')
                        if cashSuccess then
                            remainingAmount = remainingAmount - amountFromCash
                            table.insert(paymentDetails, 'Tiền mặt: $' .. amountFromCash)
                        end
                    end
                    
                    -- Kiểm tra kết quả thanh toán
                    local totalPaid = amountFromBank + amountFromCash
                    
                    -- Nếu thanh toán đủ hoặc một phần
                    if totalPaid > 0 then
                        -- Tính toán bonus cho cảnh sát: 50% tiền thực trả chia đều cho các cảnh sát tham gia
                        local officerCount = data.officers and #data.officers or 0
                        local officerBonus = 0
                        local totalOfficerPayout = 0
                        
                        if officerCount > 0 then
                            local bonusPool = math.floor(totalPaid * 0.5) -- 50% số tiền đã trả
                            officerBonus = math.floor(bonusPool / officerCount)
                            totalOfficerPayout = officerBonus * officerCount
                            
                            -- Chia tiền cho từng cảnh sát tham gia (chỉ online)
                            for i, officer in ipairs(data.officers) do
                                
                                local officerSource = GetPlayerByCitizenId(officer.citizenid)
                                if officerSource then
                                    local officerPlayer = GetPlayer(officerSource.PlayerData.source)
                                    if officerPlayer then
                                        local currentCash = officerPlayer.PlayerData.money.cash or 0
                                        local newCash = currentCash + officerBonus
                                        
                                        -- Update PlayerData directly
                                        officerPlayer.Functions.SetMoney('cash', newCash)
                                        
                                        -- Force sync to database
                                        MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', {
                                            json.encode({
                                                bank = officerPlayer.PlayerData.money.bank or 0,
                                                cash = newCash
                                            }),
                                            officer.citizenid
                                        })
                                        
                                        TriggerClientEvent('QBCore:Notify', officerPlayer.PlayerData.source, 
                                            '💰 Bạn nhận được $' .. officerBonus .. ' tiền mặt từ việc xử lý vụ án!', 
                                            'success', 10000)
                                    end
                                end
                            end
                            
                        end
                        
                        -- Chuyển 50% còn lại vào tài khoản police
                        local societyAmount = totalPaid - totalOfficerPayout
                        exports['Renewed-Banking']:addAccountMoney('police', societyAmount)
                        
                        -- Kiểm tra nếu thanh toán đủ hoặc một phần
                        if remainingAmount == 0 then
                            -- Thanh toán đủ → status = autopaid
                            exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date, paid_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL 7 DAY), CURRENT_TIMESTAMP())', {
                                ['@receiver_identifier'] = targetPlayer.PlayerData.citizenid,
                                ['@receiver_name'] = targetName,
                                ['@author_identifier'] = 'police',
                                ['@author_name'] = 'Sở Cảnh Sát',
                                ['@society'] = 'police',
                                ['@society_name'] = 'Sở Cảnh Sát',
                                ['@item'] = chargesTitle,
                                ['@invoice_value'] = invoiceValue,
                                ['@status'] = 'autopaid',
                                ['@notes'] = 'Hóa đơn phạt từ MDT\n' .. chargesTitle .. '\n\nThanh toán: ' .. table.concat(paymentDetails, ' + '),
                            })
                            
                            TriggerClientEvent('QBCore:Notify', targetSourceId, 
                                '⚖️ Hóa đơn phạt $' .. invoiceValue .. ' đã được thanh toán!\n' .. table.concat(paymentDetails, '\n'), 
                                'success', 10000)
                        else
                            -- Thanh toán một phần → tạo 2 hóa đơn: autopaid (phần đã trả) và unpaid (phần còn lại)
                            
                            -- Hóa đơn phần đã thanh toán
                            exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date, paid_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL 7 DAY), CURRENT_TIMESTAMP())', {
                                ['@receiver_identifier'] = targetPlayer.PlayerData.citizenid,
                                ['@receiver_name'] = targetName,
                                ['@author_identifier'] = 'police',
                                ['@author_name'] = 'Sở Cảnh Sát',
                                ['@society'] = 'police',
                                ['@society_name'] = 'Sở Cảnh Sát',
                                ['@item'] = chargesTitle .. ' (Đã thanh toán)',
                                ['@invoice_value'] = totalPaid,
                                ['@status'] = 'autopaid',
                                ['@notes'] = 'Hóa đơn phạt từ MDT\n' .. chargesTitle .. '\n\nThanh toán một phần: ' .. table.concat(paymentDetails, ' + '),
                            })
                            
                            -- Hóa đơn phần còn lại (unpaid)
                            exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL 7 DAY))', {
                                ['@receiver_identifier'] = targetPlayer.PlayerData.citizenid,
                                ['@receiver_name'] = targetName,
                                ['@author_identifier'] = 'police',
                                ['@author_name'] = 'Sở Cảnh Sát',
                                ['@society'] = 'police',
                                ['@society_name'] = 'Sở Cảnh Sát',
                                ['@item'] = chargesTitle .. ' (Còn nợ)',
                                ['@invoice_value'] = remainingAmount,
                                ['@status'] = 'unpaid',
                                ['@notes'] = 'Hóa đơn phạt từ MDT\n' .. chargesTitle .. '\n\nSố tiền còn nợ: $' .. remainingAmount .. ' (Tổng: $' .. invoiceValue .. ', Đã trả: $' .. totalPaid .. ')',
                            })
                            
                            TriggerClientEvent('QBCore:Notify', targetSourceId, 
                                '⚖️ Đã trả một phần: $' .. totalPaid .. '\n' .. table.concat(paymentDetails, '\n') .. '\n\n⚠️ Còn nợ: $' .. remainingAmount, 
                                'error', 15000)
                        end
                    else
                        -- Không có tiền gì cả -> Tạo hóa đơn unpaid toàn bộ
                        
                        exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL 7 DAY))', {
                            ['@receiver_identifier'] = targetPlayer.PlayerData.citizenid,
                            ['@receiver_name'] = targetName,
                            ['@author_identifier'] = 'police',
                            ['@author_name'] = 'Sở Cảnh Sát',
                            ['@society'] = 'police',
                            ['@society_name'] = 'Sở Cảnh Sát',
                            ['@item'] = chargesTitle,
                            ['@invoice_value'] = invoiceValue,
                            ['@status'] = 'unpaid',
                            ['@notes'] = 'Hóa đơn phạt từ MDT\n' .. chargesTitle,
                        })
                        
                        TriggerClientEvent('QBCore:Notify', targetSourceId, 
                            '⚠️ Bạn vừa nhận được hóa đơn phạt $' .. invoiceValue .. '!\n(Không có tiền để thanh toán tự động)', 
                            'error', 10000)
                    end
                end
                
                -- Send to jail immediately via client (để có source context đúng)
                if data.totalJailTime > 0 then
                    -- Kiểm tra và chỉ thả còng nếu đang bị còng
                    local targetPlayer = GetPlayer(targetSourceId)
                    if targetPlayer then
                        local isHandcuffed = targetPlayer.PlayerData.metadata.ishandcuffed
                        if isHandcuffed then
                            -- Chỉ gọi event thả còng nếu đang bị còng
                            TriggerClientEvent('police:client:GetCuffed', targetSourceId, source, false)
                            Wait(1000) -- Đợi 1 giây để thả còng xong
                        end
                    end
                    
                    -- Sau đó mới phạt tù
                    local jailApplied = SendPlayerToCommunityService(targetSourceId, data.totalJailTime, source)
                    if not jailApplied then
                        return { success = false, message = 'Không thể gửi án phạt sang nl_hotcut. Kiểm tra resource nl_hotcut/server console.' }
                    end
                end
                
                -- Build charges notification text
                local chargesText = ''
                for i, charge in ipairs(data.charges) do
                    chargesText = chargesText .. i .. '. ' .. charge.name .. ' | $' .. charge.selectedFine .. ' | ' .. charge.selectedJail .. ' bãi\n'
                end
                
                -- Notify target về bản án
                TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                    '⚖️ Bạn bị kết án:\n' .. chargesText .. 'Tổng phạt: $' .. data.totalFine .. ' | ' .. data.totalJailTime .. ' bãi', 
                    'error', 15000)
            end
        end
    end
    
    -- Notify handler
    SendNotify(source, 'Thành công', 'Đã kết án thành công!', 'success')
    
    -- Update memory
    Records[recordId] = {
        id = recordId,
        title = title,
        description = data.notes or '',
        handler_officer_id = data.handler.citizenid,
        handler_officer_name = data.handler.name,
        handler_officer_rank = data.handler.rank or 'Officer',
        status = 'closed',
        created_by = Player.PlayerData.citizenid,
        created_by_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        created_date = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    -- Send Discord Log
    SendDiscordLog({
        handler = {
            name = data.handler.name,
            rank = data.handler.rank or 'Officer'
        },
        officers = data.officers or {},
        offenders = data.offenders or {},
        charges = data.charges or {},
        totalFine = data.totalFine or 0,
        totalJail = data.totalJailTime or 0
    })
    
    return {success = true, recordId = recordId}
end)

-- ========== CRIMINAL CHARGES MANAGEMENT ==========

-- Get all charges templates
lib.callback.register('mini-mdt:getCharges', function(source)
    local result = MySQL.query.await([[
        SELECT 
            id,
            charge_name,
            fine_amount_min as fine_min,
            fine_amount_max as fine_max,
            jail_time_min as jail_min,
            jail_time_max as jail_max,
            charge_type,
            impound_duration,
            created_by,
            created_by_name,
            created_date
        FROM mini_mdt_charges_template 
        ORDER BY created_date DESC
    ]], {})
    return result or {}
end)

-- Create new charge template
lib.callback.register('mini-mdt:createCharge', function(source, data)
    local Player = GetPlayer(source)
    if not Player then 
        return { success = false, message = 'Player not found' }
    end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    local chargeId = MySQL.insert.await([[
        INSERT INTO mini_mdt_charges_template (charge_name, charge_type, fine_amount_min, fine_amount_max, jail_time_min, jail_time_max, impound_duration, created_by, created_by_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.charge_name,
        data.charge_type or 'criminal',
        data.fine_amount_min or 0,
        data.fine_amount_max or 0,
        data.jail_time_min or 0,
        data.jail_time_max or 0,
        data.impound_duration or 0,
        Player.PlayerData.citizenid,
        playerName
    })
    
    if chargeId then
        return { success = true }
    end
    
    return { success = false, message = 'Không thể tạo mức án' }
end)

-- Update charge template
lib.callback.register('mini-mdt:updateCharge', function(source, data)
    local Player = GetPlayer(source)
    if not Player then 
        return { success = false, message = 'Player not found' }
    end
    
    local result = MySQL.update.await([[
        UPDATE mini_mdt_charges_template 
        SET charge_name = ?, charge_type = ?, fine_amount_min = ?, fine_amount_max = ?, jail_time_min = ?, jail_time_max = ?, impound_duration = ?
        WHERE id = ?
    ]], {
        data.charge_name,
        data.charge_type or 'criminal',
        data.fine_amount_min or 0,
        data.fine_amount_max or 0,
        data.jail_time_min or 0,
        data.jail_time_max or 0,
        data.impound_duration or 0,
        data.id
    })
    
    if result then
        return { success = true }
    end
    
    return { success = false, message = 'Không thể cập nhật mức án' }
end)

-- Delete charge template
lib.callback.register('mini-mdt:deleteCharge', function(source, chargeId)
    
    local Player = GetPlayer(source)
    if not Player then 
        return { success = false, message = 'Player not found' }
    end
    
    if not chargeId or chargeId == 0 then
        return { success = false, message = 'ID mức án không hợp lệ' }
    end
    
    local success, result = pcall(function()
        return MySQL.query.await('DELETE FROM mini_mdt_charges_template WHERE id = ?', {chargeId})
    end)
    
    if success and result then
        return { success = true, message = 'Đã xóa mức án' }
    else
        return { success = false, message = 'Lỗi database: Không thể xóa mức án' }
    end
end)

-- Get vehicle impound charges only
lib.callback.register('mini-mdt:getVehicleImpoundCharges', function(source)
    local result = MySQL.query.await([[
        SELECT 
            id,
            charge_name,
            fine_amount_min as fine_min,
            fine_amount_max as fine_max,
            impound_duration
        FROM mini_mdt_charges_template 
        WHERE charge_type = 'vehicle_impound'
        ORDER BY charge_name ASC
    ]], {})
    return result or {}
end)

-- Quick Finalize (Kết án nhanh)
lib.callback.register('mini-mdt:quickFinalize', function(source, data)
    local handlerPlayer = GetPlayer(source)
    if not handlerPlayer then
        return { success = false, message = 'Không tìm thấy người xử lý' }
    end
    
    -- Validate
    if not data.offenders or #data.offenders == 0 then
        return { success = false, message = 'Vui lòng thêm ít nhất 1 tội phạm' }
    end
    
    if not data.charges or #data.charges == 0 then
        return { success = false, message = 'Vui lòng chọn ít nhất 1 tội danh' }
    end
    
    if not data.officers or #data.officers == 0 then
        return { success = false, message = 'Vui lòng chọn ít nhất 1 cảnh sát tham gia' }
    end
    
    -- Create record title
    local offenderNames = {}
    for _, offender in ipairs(data.offenders) do
        table.insert(offenderNames, offender.name)
    end
    local title = table.concat(offenderNames, ', ')
    
    local handlerName = handlerPlayer.PlayerData.charinfo.firstname .. ' ' .. handlerPlayer.PlayerData.charinfo.lastname
    local handlerRank = handlerPlayer.PlayerData.job.grade_label or handlerPlayer.PlayerData.job.grade_name
    
    -- Create record
    local recordId = MySQL.insert.await([[
        INSERT INTO mini_mdt_records (title, description, handler_officer_id, handler_officer_name, handler_officer_rank, status, created_by, created_by_name)
        VALUES (?, ?, ?, ?, ?, 'closed', ?, ?)
    ]], {
        title,
        data.notes or '',
        data.handler.citizenid,
        handlerName,
        handlerRank,
        handlerPlayer.PlayerData.citizenid,
        handlerName
    })
    
    if not recordId then
        return { success = false, message = 'Lỗi tạo hồ sơ' }
    end
    
    -- Link officers
    if data.officers and #data.officers > 0 then
        for _, officer in ipairs(data.officers) do
            MySQL.insert.await([[
                INSERT INTO mini_mdt_case_officers (record_id, officer_id, officer_name, officer_rank)
                VALUES (?, ?, ?, ?)
            ]], {recordId, officer.citizenid, officer.name, officer.rank})
        end
    end
    
    -- Process each offender
    for _, offender in ipairs(data.offenders) do
        -- Add each charge for this offender
        for _, charge in ipairs(data.charges) do
            MySQL.insert.await([[
                INSERT INTO mini_mdt_offenders 
                (record_id, offender_id, offender_name, charge_id, charge_name, fine_amount, jail_time, status, added_by)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)
            ]], {
                recordId,
                offender.citizenid,
                offender.name,
                charge.id,
                charge.name,
                charge.selectedFine,
                charge.selectedJail,
                handlerPlayer.PlayerData.citizenid
            })
        end
        
        -- Get offender player
        local offenderPlayer = GetPlayerByCitizenId(offender.citizenid)
        if offenderPlayer then
            local offenderSource = offenderPlayer.PlayerData.source
            
            -- Apply fines
            if data.totalFine > 0 then
                local bankMoney = offenderPlayer.PlayerData.money.bank or 0
                local cashMoney = offenderPlayer.PlayerData.money.cash or 0
                local paymentSuccess = false
                
                if bankMoney >= data.totalFine then
                    paymentSuccess = offenderPlayer.Functions.RemoveMoney('bank', data.totalFine, 'Fine from MDT')
                elseif cashMoney >= data.totalFine then
                    paymentSuccess = offenderPlayer.Functions.RemoveMoney('cash', data.totalFine, 'Fine from MDT')
                end
                
                if paymentSuccess then
                    -- 50% to officers
                    local bonusPool = math.floor(data.totalFine * 0.5)
                    local bonusPerOfficer = math.floor(bonusPool / #data.officers)
                    
                    for _, officer in ipairs(data.officers) do
                        local officerPlayer = GetPlayerByCitizenId(officer.citizenid)
                        if officerPlayer then
                            local currentCash = officerPlayer.PlayerData.money.cash or 0
                            local newCash = currentCash + bonusPerOfficer
                            officerPlayer.Functions.SetMoney('cash', newCash)
                            MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', {
                                json.encode({
                                    bank = officerPlayer.PlayerData.money.bank or 0,
                                    cash = newCash
                                }),
                                officer.citizenid
                            })
                            
                            TriggerClientEvent('QBCore:Notify', officerPlayer.PlayerData.source, 
                                '💰 Bạn nhận được $' .. bonusPerOfficer .. ' tiền mặt từ việc xử lý vụ án!', 
                                'success', 10000)
                        end
                    end
                    
                    -- 50% to society
                    local societyAmount = data.totalFine - bonusPool
                    exports['Renewed-Banking']:addAccountMoney('police', societyAmount)
                    
                    -- Create autopaid invoice
                    local chargeList = {}
                    for _, charge in ipairs(data.charges) do
                        table.insert(chargeList, charge.name)
                    end
                    
                    exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date, paid_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL 7 DAY), CURRENT_TIMESTAMP())', {
                        ['@receiver_identifier'] = offender.citizenid,
                        ['@receiver_name'] = offender.name,
                        ['@author_identifier'] = 'police',
                        ['@author_name'] = 'Sở Cảnh Sát',
                        ['@society'] = 'police',
                        ['@society_name'] = 'Sở Cảnh Sát',
                        ['@item'] = table.concat(chargeList, ', '),
                        ['@invoice_value'] = data.totalFine,
                        ['@status'] = 'autopaid',
                        ['@notes'] = 'Hóa đơn phạt từ MDT (Kết án nhanh)\n' .. table.concat(chargeList, '\n'),
                    })
                    
                    TriggerClientEvent('QBCore:Notify', offenderSource, 
                        'Hóa đơn phạt $' .. data.totalFine .. ' đã được thanh toán tự động!', 
                        'success', 10000)
                else
                    -- Create unpaid invoice
                    local chargeList = {}
                    for _, charge in ipairs(data.charges) do
                        table.insert(chargeList, charge.name)
                    end
                    
                    exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL 7 DAY))', {
                        ['@receiver_identifier'] = offender.citizenid,
                        ['@receiver_name'] = offender.name,
                        ['@author_identifier'] = 'police',
                        ['@author_name'] = 'Sở Cảnh Sát',
                        ['@society'] = 'police',
                        ['@society_name'] = 'Sở Cảnh Sát',
                        ['@item'] = table.concat(chargeList, ', '),
                        ['@invoice_value'] = data.totalFine,
                        ['@status'] = 'unpaid',
                        ['@notes'] = 'Hóa đơn phạt từ MDT (Kết án nhanh)\n' .. table.concat(chargeList, '\n'),
                    })
                    
                    TriggerClientEvent('QBCore:Notify', offenderSource, 
                        'Bạn vừa nhận được hóa đơn phạt $' .. data.totalFine .. '!', 
                        'error', 10000)
                end
            end
            
            -- Send to jail
            if data.totalJailTime > 0 then
                -- Gọi client của cảnh sát để trigger server event (có source context)
                local jailApplied = SendPlayerToCommunityService(offenderSource, data.totalJailTime, source)
                if not jailApplied then
                    return { success = false, message = 'Không thể gửi án phạt sang nl_hotcut. Kiểm tra resource nl_hotcut/server console.' }
                end
            end
            
            -- Build charges notification text
            local chargesText = ''
            for i, charge in ipairs(data.charges) do
                chargesText = chargesText .. i .. '. ' .. charge.name .. ' | $' .. charge.selectedFine .. ' | ' .. charge.selectedJail .. ' bãi\n'
            end
            
            -- Notify target về bản án
            TriggerClientEvent('QBCore:Notify', offenderSource, 
                '⚖️ Bạn bị kết án:\n' .. chargesText .. 'Tổng phạt: $' .. data.totalFine .. ' | ' .. data.totalJailTime .. ' bãi', 
                'error', 15000)
        end
    end
    
    -- Discord log
    SendDiscordLog({
        handler = {
            name = handlerName,
            rank = handlerRank
        },
        officers = data.officers,
        offenders = data.offenders,
        charges = data.charges,
        totalFine = data.totalFine,
        totalJail = data.totalJailTime
    })
    
    return { success = true, recordId = recordId }
end)

-- ==========================================
-- OFFLINE PRISON MANAGEMENT
-- ==========================================

-- Get offline prison history
lib.callback.register('mini-mdt:getOfflinePrisonHistory', function(source)
    local result = MySQL.query.await([[
        SELECT 
            id,
            offender_pid,
            offender_name,
            punisher_pid,
            punisher_name,
            punisher_rank,
            reason,
            status,
            created_date,
            released_date,
            released_by,
            released_by_name
        FROM mini_mdt_offline_prison
        ORDER BY created_date DESC
        LIMIT 50
    ]], {})
    
    return {
        success = true,
        data = result or {}
    }
end)

-- Save offline prison punishment (called after nl_hotcut event)
lib.callback.register('mini-mdt:saveOfflinePrison', function(source, data)
    print('[MDT SERVER] saveOfflinePrison START - source:', source, 'data:', json.encode(data))
    
    local Player = GetPlayer(source)
    if not Player then 
        print('[MDT SERVER] ERROR: Player not found')
        return { success = false, message = 'Không tìm thấy thông tin cảnh sát' } 
    end
    
    print('[MDT SERVER] Player found:', Player.PlayerData.citizenid)
    
    local punisherPid = source
    local playerName = GetPlayerFullName(Player)
    local playerRank = GetPlayerGradeName(Player)
    
    print('[MDT SERVER] Punisher PID:', punisherPid, 'Name:', playerName)
    print('[MDT SERVER] Searching for offender PID:', GetPayloadPlayerId(data), 'in table:', Config.PlayersTable)
    
    -- Get offender info by PID
    local offenderResult = MySQL.query.await([[
        SELECT 
            pid,
            citizenid,
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) as name
        FROM ]] .. Config.PlayersTable .. [[
        WHERE pid = ?
        LIMIT 1
    ]], {GetPayloadPlayerId(data)})
    
    print('[MDT SERVER] Query result:', json.encode(offenderResult))
    print('[MDT SERVER] Query result count:', offenderResult and #offenderResult or 0)
    
    if not offenderResult or #offenderResult == 0 then
        print('[MDT SERVER] ERROR: Offender not found in database')
        print('[MDT SERVER] Tip: Try searching in MDT first to get the correct Citizen ID')
        return { success = false, message = 'Không tìm thấy người chơi với ID này. Hãy dùng chức năng tìm kiếm trong MDT để lấy đúng ID!' }
    end
    
    local offenderName = offenderResult[1].name
    local offenderPid = offenderResult[1].pid
    
    print('[MDT SERVER] Found offender:', offenderName, 'PID:', offenderPid)
    
    -- Save to database
    local insertId = MySQL.insert.await([[
        INSERT INTO mini_mdt_offline_prison 
        (offender_pid, offender_name, punisher_pid, punisher_name, punisher_rank, reason, status)
        VALUES (?, ?, ?, ?, ?, ?, 'active')
    ]], {
        offenderPid,
        offenderName,
        punisherPid,
        playerName,
        playerRank,
        data.reason
    })
    
    print('[MDT SERVER] Insert result:', insertId)
    
    if insertId then
        return { success = true, message = 'Đã lưu thông tin tạm giam logout' }
    else
        return { success = false, message = 'Lỗi khi lưu vào database' }
    end
end)

-- Add offline prison
lib.callback.register('mini-mdt:addOfflinePrison', function(source, data)
    local Player = GetPlayer(source)
    if not Player then 
        return { success = false, message = 'Không tìm thấy thông tin cảnh sát' } 
    end
    
    -- Lấy thông tin cảnh sát đang thực hiện
    local punisherPid = source
    local punisherName = GetPlayerFullName(Player)
    local punisherRank = GetPlayerGradeName(Player)
    
    -- Get offender info by PID
    local offenderResult = MySQL.query.await([[
        SELECT 
            pid,
            citizenid,
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) as name
        FROM ]] .. Config.PlayersTable .. [[
        WHERE pid = ?
        LIMIT 1
    ]], {GetPayloadPlayerId(data)})
    
    if not offenderResult or #offenderResult == 0 then
        return { success = false, message = 'Không tìm thấy người chơi với Player ID/PID này' }
    end
    
    local offenderName = offenderResult[1].name
    local offenderPid = offenderResult[1].pid
    local offenderCitizenId = offenderResult[1].citizenid
    local punisherCitizenId = Player.PlayerData.citizenid
    
    -- Kiểm tra không tự phạt mình
    if offenderCitizenId == punisherCitizenId then
        return { success = false, message = 'Bạn không thể phạt chính bản thân bạn' }
    end
    
    -- Kiểm tra xem đã bị phạt offline chưa
    local checkExisting = MySQL.query.await('SELECT * FROM offline_punishment WHERE identifier = ?', {offenderCitizenId})
    
    if checkExisting and #checkExisting > 0 then
        return { success = false, message = 'Người chơi này đã bị phạt offline rồi' }
    end
    
    -- Insert vào bảng offline_punishment (bảng của nl_hotcut)
    local offlinePunishId = MySQL.insert.await(
        'INSERT INTO offline_punishment (identifier, punished_by, reason) VALUES (?, ?, ?)',
        {offenderCitizenId, punisherCitizenId, data.reason}
    )
    
    if not offlinePunishId then
        return { success = false, message = 'Lỗi khi lưu vào bảng offline_punishment' }
    end
    
    -- Save to database MDT
    local insertId = MySQL.insert.await([[
        INSERT INTO mini_mdt_offline_prison 
        (offender_pid, offender_name, punisher_pid, punisher_name, punisher_rank, reason, status)
        VALUES (?, ?, ?, ?, ?, ?, 'active')
    ]], {
        offenderPid,
        offenderName,
        punisherPid,
        punisherName,
        punisherRank,
        data.reason
    })
    
    if insertId then
        -- Lấy PID thực của cảnh sát từ database
        local punisherPidResult = MySQL.query.await('SELECT pid FROM players WHERE citizenid = ?', {punisherCitizenId})
        local punisherPidNum = 'N/A'
        if punisherPidResult and #punisherPidResult > 0 then
            punisherPidNum = punisherPidResult[1].pid
        end
        
        -- Gửi log Discord
        TriggerEvent('mini-mdt:server:logPrison', source, {
            name = offenderName,
            pid = offenderPid,
            citizenid = offenderCitizenId
        }, {
            name = punisherName,
            pid = punisherPidNum,
            citizenid = punisherCitizenId,
            rank = punisherRank
        }, data.reason)
        
        return { success = true, message = 'Đã tạm giam logout thành công' }
    else
        return { success = false, message = 'Lỗi khi lưu vào database' }
    end
end)

-- Update offline prison status to released
lib.callback.register('mini-mdt:releaseOfflinePrison', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return { success = false, message = 'Không tìm thấy thông tin cảnh sát' } end
    
    local citizenId = Player.PlayerData.citizenid
    local playerName = GetPlayerFullName(Player)
    
    -- Get offender full info
    local offenderResult = MySQL.query.await([[
        SELECT 
            pid,
            citizenid,
            CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) as name
        FROM ]] .. Config.PlayersTable .. [[
        WHERE pid = ?
        LIMIT 1
    ]], {GetPayloadPlayerId(data)})
    
    if not offenderResult or #offenderResult == 0 then
        return { success = false, message = 'Không tìm thấy người chơi với Player ID/PID này' }
    end
    
    local offenderCitizenId = offenderResult[1].citizenid
    local offenderName = offenderResult[1].name
    local offenderPid = offenderResult[1].pid
    
    -- KIỂM TRA: Người này có trong danh sách tạm giam không?
    local checkPrison = MySQL.query.await('SELECT * FROM offline_punishment WHERE identifier = ?', {offenderCitizenId})
    
    if not checkPrison or #checkPrison == 0 then
        return { success = false, message = 'Người chơi này không có trong danh sách tạm giam logout' }
    end
    
    -- Xóa khỏi bảng offline_punishment (bảng của nl_hotcut)
    local deleteOffline = MySQL.update.await(
        'DELETE FROM offline_punishment WHERE identifier = ?',
        {offenderCitizenId}
    )
    
    -- Nếu người chơi đang online, thả tự do
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(offenderCitizenId)
    if targetPlayer then
        TriggerClientEvent('esx_communityservice:releaseOfflinePunishment', targetPlayer.PlayerData.source)
        exports.qbx_core:Notify(targetPlayer.PlayerData.source, 'Phạt offline của bạn đã được hủy', 'success')
    end
    
    -- Update status to released trong MDT
    local affectedRows = MySQL.update.await([[
        UPDATE mini_mdt_offline_prison
        SET status = 'released',
            released_date = NOW(),
            released_by = ?,
            released_by_name = ?
        WHERE offender_pid = ? AND status = 'active'
    ]], {
        citizenId,
        playerName,
        GetPayloadPlayerId(data)
    })
    
    if deleteOffline and deleteOffline > 0 then
        -- Lấy PID thực của cảnh sát từ database
        local releaserPidResult = MySQL.query.await('SELECT pid FROM players WHERE citizenid = ?', {citizenId})
        local releaserPid = 'N/A'
        if releaserPidResult and #releaserPidResult > 0 then
            releaserPid = releaserPidResult[1].pid
        end
        
        -- Lấy rank
        local releaserRank = GetPlayerGradeName(Player)
        
        -- Gửi log Discord
        TriggerEvent('mini-mdt:server:logRelease', source, {
            name = offenderName,
            pid = offenderPid,
            citizenid = offenderCitizenId
        }, {
            name = playerName,
            pid = releaserPid,
            citizenid = citizenId,
            rank = releaserRank
        }, data.reason or 'Hủy phạt tạm giam logout')
        
        return { success = true, message = 'Đã thả tạm giam logout thành công' }
    else
        return { success = false, message = 'Không tìm thấy người chơi đang bị tạm giam' }
    end
end)

-- Search offline prison by PID
lib.callback.register('mini-mdt:searchOfflinePrison', function(source, data)
    local result = MySQL.query.await([[
        SELECT 
            id,
            offender_pid,
            offender_name,
            punisher_pid,
            punisher_name,
            punisher_rank,
            reason,
            status,
            created_date,
            released_date,
            released_by,
            released_by_name
        FROM mini_mdt_offline_prison
        WHERE offender_pid = ?
        ORDER BY created_date DESC
        LIMIT 50
    ]], {GetPayloadPlayerId(data)})
    
    return {
        success = true,
        data = result or {}
    }
end)

-- Update Badge Photo
lib.callback.register('mini-mdt:updateBadgePhoto', function(source, data)
    local Player = GetPlayer(source)
    if not Player then 
        return { success = false, message = 'Player không tồn tại' } 
    end
    
    local pid = GetPayloadPlayerId(data)
    local photoUrl = data.photoUrl
    
    if not pid or not photoUrl then
        return { success = false, message = 'Thiếu thông tin PID hoặc link ảnh' }
    end
    
    -- Get citizenid from PID
    local playerData = MySQL.query.await([[
        SELECT citizenid, 
        CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) as name
        FROM ]] .. Config.PlayersTable .. [[
        WHERE pid = ?
        LIMIT 1
    ]], {pid})
    
    if not playerData or #playerData == 0 then
        return { success = false, message = 'Không tìm thấy người chơi với Player ID/PID này' }
    end
    
    local citizenid = playerData[1].citizenid
    local targetName = playerData[1].name
    
    -- Check if badge photo record exists
    local existingPhoto = MySQL.query.await([[
        SELECT id FROM stevo_badge_photos 
        WHERE identifier = ?
        LIMIT 1
    ]], {citizenid})
    
    local success = false
    
    if existingPhoto and #existingPhoto > 0 then
        -- Update existing record
        local affectedRows = MySQL.update.await([[
            UPDATE stevo_badge_photos 
            SET image = ? 
            WHERE identifier = ?
        ]], {photoUrl, citizenid})
        success = affectedRows > 0
    else
        -- Insert new record
        local insertId = MySQL.insert.await([[
            INSERT INTO stevo_badge_photos (identifier, image) 
            VALUES (?, ?)
        ]], {citizenid, photoUrl})
        success = insertId > 0
    end
    
    if success then
        -- Log the action
        local updaterName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local updaterPid = Player.PlayerData.cid or source
        
        print(string.format('[MINI-MDT] %s (PID: %s) đã cập nhật ảnh thẻ cho %s (PID: %s)', 
            updaterName, updaterPid, targetName, pid))
        
        return { 
            success = true, 
            message = 'Đã cập nhật ảnh thẻ thành công cho ' .. targetName 
        }
    else
        return { success = false, message = 'Lỗi khi cập nhật database' }
    end
end)

-- ========== PRISON MANAGEMENT ==========

-- Get paginated prison list from communityservice table
lib.callback.register('mini-mdt:getPrisonList', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return { success = false, message = 'Không tìm thấy người dùng' } end

    local page = (data and data.page) or 1
    local limit = 10
    local offset = (page - 1) * limit

    -- Total count
    local countResult = MySQL.query.await('SELECT COUNT(*) as total FROM communityservice WHERE actions_remaining > 0', {})
    local total = (countResult and countResult[1]) and countResult[1].total or 0

    -- Paginated rows joined with players table for name + pid
    local rows = MySQL.query.await([[
        SELECT
            c.identifier,
            c.actions_remaining,
            p.pid,
            CONCAT(
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.firstname')),
                ' ',
                JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, '$.lastname'))
            ) AS name
        FROM communityservice c
        LEFT JOIN ]] .. Config.PlayersTable .. [[ p ON p.citizenid = c.identifier
        WHERE c.actions_remaining > 0
        ORDER BY c.actions_remaining DESC
        LIMIT ? OFFSET ?
    ]], {limit, offset})

    return {
        success = true,
        data = rows or {},
        total = total,
        page = page,
        totalPages = math.ceil(total / limit),
    }
end)

-- Add prison time (phạt thêm)
lib.callback.register('mini-mdt:addPrisonTime', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return { success = false, message = 'Không tìm thấy người dùng' } end

    local identifier = data and data.identifier
    local amount = data and tonumber(data.amount)
    if not identifier or not amount or amount < 1 then
        return { success = false, message = 'Dữ liệu không hợp lệ' }
    end

    local existing = MySQL.query.await('SELECT actions_remaining FROM communityservice WHERE identifier = ?', {identifier})
    local newActions

    if existing and #existing > 0 then
        newActions = tonumber(existing[1].actions_remaining) + amount
        MySQL.update.await('UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?', {newActions, identifier})
    else
        newActions = amount
        MySQL.insert.await('INSERT INTO communityservice (identifier, actions_remaining) VALUES (?, ?)', {identifier, newActions})
    end

    -- Notify online player if present
    local targetPlayer = nil
    if Config.Framework == 'qbx' and QBX then
        targetPlayer = QBX:GetPlayerByCitizenId(identifier)
    else
        targetPlayer = QBCore.Functions.GetPlayerByCitizenId(identifier)
    end
    if targetPlayer then
        local tSrc = targetPlayer.PlayerData.source
        TriggerClientEvent('esx_communityservice:updateActions', tSrc, newActions)
        TriggerClientEvent('QBCore:Notify', tSrc, 'Bạn bị phạt thêm ' .. amount .. ' bãi. Tổng còn lại: ' .. newActions, 'error', 8000)
    end

    local officerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    print(string.format('[MINI-MDT] %s đã phạt thêm %d bãi cho identifier %s (tổng: %d)', officerName, amount, identifier, newActions))

    return { success = true, newActions = newActions }
end)

-- Reduce prison time (giảm án)
lib.callback.register('mini-mdt:reducePrisonTime', function(source, data)
    local Player = GetPlayer(source)
    if not Player then return { success = false, message = 'Không tìm thấy người dùng' } end

    local identifier = data and data.identifier
    local amount = data and tonumber(data.amount)
    if not identifier or not amount or amount < 1 then
        return { success = false, message = 'Dữ liệu không hợp lệ' }
    end

    local existing = MySQL.query.await('SELECT actions_remaining FROM communityservice WHERE identifier = ?', {identifier})
    if not existing or #existing == 0 then
        return { success = false, message = 'Không tìm thấy hồ sơ phạt tù' }
    end

    local current = tonumber(existing[1].actions_remaining)
    local newActions = math.max(0, current - amount)

    if newActions == 0 then
        -- Release from prison entirely
        MySQL.update.await('DELETE FROM communityservice WHERE identifier = ?', {identifier})

        local targetPlayer = nil
        if Config.Framework == 'qbx' and QBX then
            targetPlayer = QBX:GetPlayerByCitizenId(identifier)
        else
            targetPlayer = QBCore.Functions.GetPlayerByCitizenId(identifier)
        end
        if targetPlayer then
            local tSrc = targetPlayer.PlayerData.source
            TriggerEvent('esx_communityservice:endCommunityServiceCommand', tSrc, source)
        end
    else
        MySQL.update.await('UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?', {newActions, identifier})

        local targetPlayer = nil
        if Config.Framework == 'qbx' and QBX then
            targetPlayer = QBX:GetPlayerByCitizenId(identifier)
        else
            targetPlayer = QBCore.Functions.GetPlayerByCitizenId(identifier)
        end
        if targetPlayer then
            local tSrc = targetPlayer.PlayerData.source
            TriggerClientEvent('esx_communityservice:updateActions', tSrc, newActions)
            TriggerClientEvent('QBCore:Notify', tSrc, 'Án phạt của bạn được giảm ' .. amount .. ' bãi. Còn lại: ' .. newActions, 'success', 8000)
        end
    end

    local officerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    print(string.format('[MINI-MDT] %s đã giảm %d bãi cho identifier %s (còn: %d)', officerName, amount, identifier, newActions))

    return { success = true, newActions = newActions, released = newActions == 0 }
end)

-- ========== PATROL SYSTEM CALLBACKS ==========

-- Get patrol data (points, states, logs)
lib.callback.register('mini-mdt:getPatrolData', function(source)
    local Player = GetPlayer(source)
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        return { success = false, message = "Không có quyền!" }
    end

    -- Get weekly logs (last 7 days)
    local logs = MySQL.query.await('SELECT *, UNIX_TIMESTAMP(created_at) as unix_time FROM mini_mdt_patrol_logs WHERE created_at >= NOW() - INTERVAL 7 DAY ORDER BY created_at DESC LIMIT 100', {})
    
    local points = {}
    local now = os.time()
    for _, pt in ipairs(Config.PatrolPoints) do
        local state = PatrolStates[pt.id] or { lastPatrolled = 0, officerName = "", officerRank = "", officerCallsign = "" }
        table.insert(points, {
            id = pt.id,
            name = pt.name,
            coords = { x = pt.coords.x, y = pt.coords.y, z = pt.coords.z },
            radius = pt.radius,
            cooldown = pt.cooldown or 15,
            state = {
                lastPatrolled = state.lastPatrolled,
                officerName = state.officerName,
                officerRank = state.officerRank,
                officerCallsign = state.officerCallsign,
                serverTime = now
            }
        })
    end

    return {
        success = true,
        points = points,
        logs = logs or {}
    }
end)

-- Get patrol states only
lib.callback.register('mini-mdt:getPatrolStates', function(source)
    local states = {}
    local now = os.time()
    for id, state in pairs(PatrolStates) do
        states[id] = {
            lastPatrolled = state.lastPatrolled,
            officerName = state.officerName,
            officerRank = state.officerRank,
            officerCallsign = state.officerCallsign,
            serverTime = now
        }
    end
    return states
end)

-- Perform patrol action
lib.callback.register('mini-mdt:patrolArea', function(source, pointId)
    local Player = GetPlayer(source)
    if not Player or not Config.AllowedJobs[Player.PlayerData.job.name] then
        return { success = false, message = "Không có quyền!" }
    end

    local point = nil
    for _, pt in ipairs(Config.PatrolPoints) do
        if pt.id == pointId then
            point = pt
            break
        end
    end

    if not point then
        return { success = false, message = "Khu vực tuần tra không hợp lệ!" }
    end

    local state = PatrolStates[pointId]
    local now = os.time()

    local cooldownSec = (point.cooldown or 15) * 60
    if state and state.lastPatrolled and now - state.lastPatrolled < cooldownSec then
        local diff = cooldownSec - (now - state.lastPatrolled)
        local minutes = math.floor(diff / 60)
        local seconds = diff % 60
        return { success = false, message = string.format("Khu vực này đã được tuần tra, vui lòng đợi %d phút %d giây!", minutes, seconds) }
    end

    -- Update state
    local officerName = GetPlayerFullName(Player)
    local officerRank = GetPlayerGradeName(Player)
    local officerCallsign = Player.PlayerData.metadata.callsign or "N/A"

    PatrolStates[pointId] = {
        lastPatrolled = now,
        officerName = officerName,
        officerRank = officerRank,
        officerCallsign = officerCallsign
    }

    -- Insert log
    MySQL.insert.await('INSERT INTO mini_mdt_patrol_logs (area_name, officer_name, officer_callsign, officer_rank) VALUES (?, ?, ?, ?)', {
        point.name,
        officerName,
        officerCallsign,
        officerRank
    })

    -- Clean up logs older than 7 days
    MySQL.query('DELETE FROM mini_mdt_patrol_logs WHERE created_at < NOW() - INTERVAL 7 DAY')

    -- Broadcast update to all clients
    local updatedState = {
        lastPatrolled = now,
        officerName = officerName,
        officerRank = officerRank,
        officerCallsign = officerCallsign,
        serverTime = now
    }
    TriggerClientEvent('mini-mdt:client:updatePatrolState', -1, pointId, updatedState)

    return { success = true, state = updatedState }
end)

