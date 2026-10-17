-- Server main script using QBox native exports and ox_lib callbacks

-- Debug logging helper
local function DebugPrint(...)
    if Config.Debug then
        print(...)
    end
end

-- Callback to retrieve all announcements
lib.callback.register('xn_pdemstool:server:getAnnouncements', function(source)
    DebugPrint("^3[xn_pdemstool] Server: getAnnouncements callback triggered by source: " .. tostring(source) .. "^7")
    local result = exports.oxmysql:query_async('SELECT * FROM ' .. Config.TableName .. ' ORDER BY id DESC', {})
    DebugPrint("^3[xn_pdemstool] Server: getAnnouncements database returned " .. tostring(result and #result or 0) .. " rows^7")
    return result or {}
end)

-- Callback to check current player's permission to post
lib.callback.register('xn_pdemstool:server:checkPermissions', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then 
        DebugPrint("^1[xn_pdemstool] Player not found for source: " .. tostring(source) .. "^7")
        return { canPost = false } 
    end

    local job = Player.PlayerData.job
    local jobName = job.name
    
    -- Handle job grade as table or number
    local gradeLevel = 0
    if type(job.grade) == "table" then
        gradeLevel = tonumber(job.grade.level) or 0
    else
        gradeLevel = tonumber(job.grade) or 0
    end

    DebugPrint("^3[xn_pdemstool] Checking permissions for " .. GetPlayerName(source) .. " | Job: " .. tostring(jobName) .. " | Grade: " .. tostring(gradeLevel) .. "^7")

    local perm = Config.Permissions[jobName]
    if perm then
        DebugPrint("^3[xn_pdemstool] Found config for job: " .. jobName .. " | Min Grade required: " .. tostring(perm.minGrade) .. "^7")
        if gradeLevel >= perm.minGrade then
            DebugPrint("^2[xn_pdemstool] Permission GRANTED for category: " .. tostring(perm.tab) .. "^7")
            return {
                canPost = true,
                category = perm.tab
            }
        else
            DebugPrint("^1[xn_pdemstool] Permission DENIED: grade too low (" .. tostring(gradeLevel) .. " < " .. tostring(perm.minGrade) .. ")^7")
            return { canPost = false }
        end
    else
        DebugPrint("^1[xn_pdemstool] Permission DENIED: job config not found for " .. tostring(jobName) .. "^7")
        return { canPost = false }
    end
end)

-- Callback to delete an announcement
lib.callback.register('xn_pdemstool:server:deleteAnnouncement', function(source, id)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then 
        DebugPrint("^1[xn_pdemstool] Server: Player not found for source: " .. tostring(source) .. "^7")
        return false 
    end

    local job = Player.PlayerData.job
    local jobName = job.name
    
    local gradeLevel = 0
    if type(job.grade) == "table" then
        gradeLevel = tonumber(job.grade.level) or 0
    else
        gradeLevel = tonumber(job.grade) or 0
    end

    local perm = Config.Permissions[jobName]
    if not perm or gradeLevel < perm.minGrade then
        DebugPrint("^1[xn_pdemstool] Server: Delete permission check failed for source: " .. tostring(source) .. "^7")
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Bạn không có quyền xóa thông báo!' })
        return false
    end

    -- Get announcement to verify category match
    local ann = exports.oxmysql:single_async('SELECT category FROM ' .. Config.TableName .. ' WHERE id = ?', { id })
    if not ann then
        DebugPrint("^1[xn_pdemstool] Server: Announcement not found for ID: " .. tostring(id) .. "^7")
        return false
    end

    if ann.category ~= perm.tab then
        DebugPrint("^1[xn_pdemstool] Server: Category mismatch! Player category: " .. tostring(perm.tab) .. " | Announcement category: " .. tostring(ann.category) .. "^7")
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Bạn không thể xóa thông báo của ban ngành khác!' })
        return false
    end

    local rowsChanged = exports.oxmysql:update_async('DELETE FROM ' .. Config.TableName .. ' WHERE id = ?', { id })
    if rowsChanged and rowsChanged > 0 then
        DebugPrint("^2[xn_pdemstool] Server: Delete successful! ID: " .. tostring(id) .. "^7")
        TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Xóa thông báo thành công!' })
        -- Notify all clients to reload their list
        TriggerClientEvent('xn_pdemstool:client:refreshAnnouncements', -1)
        return true
    else
        return false
    end
end)


-- Event to insert a new announcement
RegisterNetEvent('xn_pdemstool:server:postAnnouncement', function(data)
    local src = source
    DebugPrint("^3[xn_pdemstool] Server: postAnnouncement event triggered by source: " .. tostring(src) .. "^7")
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then 
        DebugPrint("^1[xn_pdemstool] Server: Player not found for source: " .. tostring(src) .. "^7")
        return 
    end

    local job = Player.PlayerData.job
    local jobName = job.name
    
    -- Handle job grade as table or number
    local gradeLevel = 0
    if type(job.grade) == "table" then
        gradeLevel = tonumber(job.grade.level) or 0
    else
        gradeLevel = tonumber(job.grade) or 0
    end

    DebugPrint("^3[xn_pdemstool] Server: Player Job: " .. tostring(jobName) .. " | Grade: " .. tostring(gradeLevel) .. "^7")

    local perm = Config.Permissions[jobName]
    if not perm or gradeLevel < perm.minGrade then
        DebugPrint("^1[xn_pdemstool] Server: Permission check failed on server side!^7")
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Bạn không có quyền đăng thông báo!' })
        return
    end

    -- Validate fields
    if not data or not data.title or data.title == "" or not data.content or data.content == "" or not data.apply_time or data.apply_time == "" then
        DebugPrint("^1[xn_pdemstool] Server: Validation failed: empty fields!^7")
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Vui lòng điền đầy đủ thông tin!' })
        return
    end

    -- Force category to match the job permission to prevent exploits
    local targetCategory = perm.tab

    local charinfo = Player.PlayerData.charinfo
    local senderName = charinfo.firstname .. " " .. charinfo.lastname
    local citizenid = Player.PlayerData.citizenid

    DebugPrint("^3[xn_pdemstool] Server: Inserting announcement: Title: " .. tostring(data.title) .. " | Category: " .. tostring(targetCategory) .. " | Sender: " .. tostring(senderName) .. "^7")

    exports.oxmysql:insert('INSERT INTO ' .. Config.TableName .. ' (sender_name, sender_citizenid, category, title, content, apply_time) VALUES (?, ?, ?, ?, ?, ?)', {
        senderName,
        citizenid,
        targetCategory,
        data.title,
        data.content,
        data.apply_time
    }, function(insertId)
        if insertId then
            DebugPrint("^2[xn_pdemstool] Server: Insert successful! ID: " .. tostring(insertId) .. "^7")
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Đăng thông báo thành công!' })
            -- Notify all clients to reload their list if they have the app open
            TriggerClientEvent('xn_pdemstool:client:refreshAnnouncements', -1)
        else
            DebugPrint("^1[xn_pdemstool] Server: Insert failed!^7")
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Đã xảy ra lỗi khi lưu thông báo vào CSDL!' })
        end
    end)
end)
