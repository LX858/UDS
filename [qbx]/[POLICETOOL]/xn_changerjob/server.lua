QBCore = exports['qb-core']:GetCoreObject()

-- Event xử lý thay đổi job
RegisterNetEvent('xn_changerjob:changeJob', function(newJob, newGrade)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('xn_changerjob:error', src, 'Không thể lấy thông tin người chơi')
        return
    end
    
    -- Kiểm tra citizen ID có trong danh sách được phép không
    local citizenId = Player.PlayerData.citizenid
    
    if not Config.IsAllowedCitizen(citizenId) then
        TriggerClientEvent('xn_changerjob:error', src, 'Bạn không có quyền sử dụng chức năng này')
        return
    end
    
    -- Lấy job hiện tại
    local currentJob = Player.PlayerData.job
    
    -- Kiểm tra điều kiện thay đổi job
    local canChange = false
    
    if currentJob.name == 'police' and currentJob.grade.level >= 11 and newJob == 'hocvien' and newGrade == 4 then
        canChange = true
    elseif currentJob.name == 'hocvien' and currentJob.grade.level == 4 and newJob == 'police' and newGrade == 11 then
        canChange = true
    end
    
    if not canChange then
        TriggerClientEvent('xn_changerjob:error', src, 'Không thể thay đổi job với điều kiện hiện tại')
        return
    end
    
    -- Thực hiện thay đổi job
    Player.Functions.SetJob(newJob, newGrade)
    
    -- Log thay đổi
    print(string.format('[JobChanger] Player %s (%s) changed job from %s:%d to %s:%d', 
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, 
        citizenId, currentJob.name, currentJob.grade.level, newJob, newGrade))
    
    -- Thông báo thành công
    TriggerClientEvent('xn_changerjob:jobChanged', src, newJob, newGrade)
    
    -- Ghi log vào database (tùy chọn)
    saveJobChangeLog(citizenId, currentJob.name, currentJob.grade.level, newJob, newGrade)
end)

-- Hàm ghi log vào database (tùy chọn)
function saveJobChangeLog(citizenId, oldJob, oldGrade, newJob, newGrade)
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    
    -- Sử dụng MySQL Async hoặc oxmysql tùy theo framework
    -- Ví dụ với oxmysql:
    --[[
    exports.oxmysql:execute('INSERT INTO job_change_logs (citizen_id, old_job, old_grade, new_job, new_grade, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
        citizenId, oldJob, oldGrade, newJob, newGrade, timestamp
    })
    --]]
    
    -- Hoặc chỉ in ra console log
    print(string.format('[JobChanger Log] %s: %s changed from %s:%d to %s:%d at %s', 
        timestamp, citizenId, oldJob, oldGrade, newJob, newGrade))
end

-- Command để kiểm tra job hiện tại (dev only)
QBCore.Commands.Add('checkjob', 'Check current job and grade', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        local job = Player.PlayerData.job
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[JobChanger]', string.format('Current job: %s, Grade: %d (%s)', 
                job.name, job.grade.level, job.grade.name)}
        })
    end
end, 'admin')

-- Command để thêm citizenid vào danh sách cho phép
QBCore.Commands.Add('jobchanger_add', 'Add citizenid to allowed list', {{name = 'citizenid', help = 'Citizen ID to add'}}, true, function(source, args)
    local citizenId = args[1]
    if Config.AddAllowedCitizen(citizenId) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[JobChanger]', string.format('Added %s to allowed list', citizenId)}
        })
        print(string.format('[JobChanger] Admin %s added citizenid %s to allowed list', source, citizenId))
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[JobChanger]', string.format('%s is already in allowed list', citizenId)}
        })
    end
end, 'admin')

-- Command để xóa citizenid khỏi danh sách cho phép
QBCore.Commands.Add('jobchanger_remove', 'Remove citizenid from allowed list', {{name = 'citizenid', help = 'Citizen ID to remove'}}, true, function(source, args)
    local citizenId = args[1]
    if Config.RemoveAllowedCitizen(citizenId) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[JobChanger]', string.format('Removed %s from allowed list', citizenId)}
        })
        print(string.format('[JobChanger] Admin %s removed citizenid %s from allowed list', source, citizenId))
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'[JobChanger]', string.format('%s not found in allowed list', citizenId)}
        })
    end
end, 'admin')

-- Command để xem danh sách citizenid được phép
QBCore.Commands.Add('jobchanger_list', 'List all allowed citizenids', {}, false, function(source, args)
    local allowedList = table.concat(Config.AllowedCitizenIds, ', ')
    TriggerClientEvent('chat:addMessage', source, {
        args = {'[JobChanger]', string.format('Allowed citizenids: %s', allowedList)}
    })
end, 'admin')

-- Event khi player join để kiểm tra
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local citizenId = Player.PlayerData.citizenid
    
    -- Kiểm tra có trong danh sách được phép không
    if Config.IsAllowedCitizen(citizenId) then
        print(string.format('[JobChanger] Authorized player %s connected', citizenId))
    end
end)
