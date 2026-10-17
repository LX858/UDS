local QBX = exports.qbx_core
local playerCooldowns = {}
local prisonTimers = {} -- Track prison timers
local playerScreenshotUrls = {} -- Lưu link screenshot cho mỗi player
local playerPenaltyApplied = {} -- Track xem player nào đã bị trừ điểm (cho Discord B)

-- Safe wrapper cho lib commands
local function safeAddCommand(name, options, handler)
    if lib and lib.addCommand then
        lib.addCommand(name, options, handler)
        --print('[DIEMUYTIN] ✅ Registered lib.command: ' .. name)
    else
        -- Fallback to RegisterCommand
        RegisterCommand(name, function(source, args, raw)
            -- Convert args array to named parameters for compatibility
            local namedArgs = {}
            if options.params then
                for i, param in ipairs(options.params) do
                    local value = args[i]
                    if param.type == 'number' then
                        namedArgs[param.name] = tonumber(value)
                    else
                        namedArgs[param.name] = value
                    end
                end
            else
                -- If no params defined, pass args as is
                namedArgs = args
            end
            handler(source, namedArgs, raw)
        end, options.restricted == 'group.admin')
        --print('[DIEMUYTIN] ⚠️ Fallback RegisterCommand: ' .. name)
    end
end

-- Locales
local locale = {
    ['reputation_decreased'] = 'Điểm uy tín của bạn đã giảm %s điểm! Còn lại: %s/100',
    ['combat_forbidden_zone'] = 'Bạn bị trừ điểm uy tín vì đánh nhau trong khu vực cấm: %s',
    ['vehicle_ramming_penalty'] = 'Bạn bị trừ điểm uy tín vì đâm xe vào người chơi khác!',
    ['reputation_low'] = 'Cảnh báo: Điểm uy tín của bạn đang rất thấp!',
    ['reputation_check'] = 'Kiểm tra điểm uy tín của bạn',
    ['target_check_reputation'] = 'Kiểm tra thông tin',
    ['unknown_person'] = '******'
}

-- Hàm kiểm tra xem người chơi có phải công an và đang onduty không
local function isPoliceOnDuty(source)
    local player = QBX:GetPlayer(source)
    if not player then 
        return false 
    end
    
    local job = player.PlayerData.job
    if not job then 
        return false 
    end
    
    -- Kiểm tra job có trong danh sách police jobs hoặc bác sĩ
    local isPoliceJob = false
    for _, policeJob in ipairs(Config.TargetSystem.policeJobs) do
        if job.name == policeJob then
            isPoliceJob = true
            break
        end
    end
    
    -- Thêm bác sĩ vào danh sách được miễn phạt
    local isDoctorJob = (job.name == 'ambulance' or job.name == 'ems')
    
    -- Kiểm tra onduty và có grade đủ cao (grade >= 0)
    local gradeLevel = 0
    if type(job.grade) == "table" then
        gradeLevel = job.grade.level or 0
    elseif type(job.grade) == "number" then
        gradeLevel = job.grade
    end
    
    local result = (isPoliceJob or isDoctorJob) and job.onduty and gradeLevel >= 0
    
    return result
end

-- Hàm tìm tên khu vực cấm dựa trên tọa độ người chơi
local function getForbiddenZoneName(playerSource)
    local player = QBX:GetPlayer(playerSource)
    if not player then return "Khu vực không xác định" end
    
    -- Lấy tọa độ từ client (cần thêm event để lấy)
    -- Tạm thời return generic name, sẽ cần client gửi zone name
    return "Khu vực cấm"
end

-- ============ PRISON SYSTEM FUNCTIONS ============

-- Hàm áp dụng đồng phục tù nhân
local function applyPrisonerUniform(source)
    if not Config.PrisonSystem.uniforms.enabled then return end
    
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    -- Trigger client event để thay đồ
    TriggerClientEvent('diemuytin:applyPrisonerSkin', source)
    
    --print('[DIEMUYTIN PRISON] Applied prisoner uniform for player: ' .. player.PlayerData.citizenid)
end

-- Hàm khôi phục trang phục ban đầu
local function restoreOriginalClothing(source)
    if not Config.PrisonSystem.uniforms.enabled then return end
    
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    -- Trigger client event để khôi phục trang phục
    TriggerClientEvent('diemuytin:restoreOriginalClothing', source)
    
    --print('[DIEMUYTIN PRISON] Restored original clothing for player: ' .. player.PlayerData.citizenid)
end

-- Hàm tạo/cập nhật prison record trong database
local function updatePrisonRecord(citizenid, prisonTime, reason)
    if not Config.PrisonSystem.enabled then return end
    
    local query = [[
        INSERT INTO reputation_prison (citizenid, prison_time, prison_reason, jailed_at, is_active)
        VALUES (?, ?, ?, NOW(), 1)
        ON DUPLICATE KEY UPDATE
        prison_time = VALUES(prison_time),
        prison_reason = VALUES(prison_reason),
        jailed_at = NOW(),
        is_active = 1,
        released_at = NULL
    ]]
    
    exports.oxmysql:insert(query, {citizenid, prisonTime, reason}, function(result)
        if result then
            --print('[DIEMUYTIN PRISON] Updated prison record for: ' .. citizenid)
        else
            --print('[DIEMUYTIN PRISON] Failed to update prison record for: ' .. citizenid)
        end
    end)
end

-- Hàm lấy thông tin tù từ database
local function getPrisonInfo(citizenid, callback)
    if not Config.PrisonSystem.enabled then 
        callback(nil)
        return 
    end
    
    local query = [[
        SELECT prison_time, prison_reason, jailed_at, is_active
        FROM reputation_prison 
        WHERE citizenid = ? AND is_active = 1
        LIMIT 1
    ]]
    
    exports.oxmysql:single(query, {citizenid}, function(result)
        callback(result)
    end)
end

-- Hàm thả người chơi khỏi tù
local function releasePrisoner(citizenid, source)
    if not Config.PrisonSystem.enabled then return end
    
    local query = [[
        UPDATE reputation_prison 
        SET is_active = 0, released_at = NOW(), prison_time = 0
        WHERE citizenid = ? AND is_active = 1
    ]]
    
    exports.oxmysql:update(query, {citizenid}, function(affectedRows)
        if affectedRows > 0 then
            --print('[DIEMUYTIN PRISON] Released prisoner: ' .. citizenid)
            
            -- Đưa về bucket bình thường
            if source and source > 0 then
                SetPlayerRoutingBucket(source, 0)
                
                -- Reset điểm uy tín về 100 khi hết thời gian tù
                local player = QBX:GetPlayer(source)
                if player then
                    player.Functions.SetMetaData('reputation', Config.ReputationSystem.maxReputation)
                    --print('[DIEMUYTIN PRISON] Reset reputation to 100 for released prisoner: ' .. citizenid)
                    
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Phục Hồi Uy Tín',
                        description = 'Điểm uy tín của bạn đã được phục hồi về 100/100!',
                        type = 'success',
                        duration = 5000
                    })
                end
                
                -- Teleport về spawn point bình thường (có thể config thêm)
                TriggerClientEvent('diemuytin:releasedFromPrison', source)
                
                -- Khôi phục trang phục ban đầu
                CreateThread(function()
                    Wait(2000) -- Đợi 2 giây để teleport hoàn tất
                    restoreOriginalClothing(source)
                end)
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Tù Liên Bang',
                    description = Config.PrisonSystem.messages.released,
                    type = 'success',
                    duration = 5000
                })
            end
        end
    end)
end

-- Hàm bỏ tù người chơi
local function imprisonPlayer(source, prisonTime, reason)
    if not Config.PrisonSystem.enabled then return end
    
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local reputation = player.PlayerData.metadata.reputation or 0
    
    -- Trigger client chụp ảnh trước khi teleport
    if Config.DiscordWebhook.enabled then
        TriggerClientEvent('diemuytin:takePrisonScreenshot', source)
        Wait(500) -- Đợi client chụp ảnh
    end
    
    -- Cập nhật database
    updatePrisonRecord(citizenid, prisonTime, reason)
    
    -- Đưa vào prison bucket
    SetPlayerRoutingBucket(source, Config.PrisonSystem.prisonBucket)
    
    -- Teleport đến tù
    TriggerClientEvent('diemuytin:sendToPrison', source, Config.PrisonSystem.location.spawnPoint)
    
    -- Áp dụng đồng phục tù nhân
    CreateThread(function()
        Wait(2000) -- Đợi 2 giây để teleport hoàn tất
        applyPrisonerUniform(source)
    end)
    
    -- Gửi Discord webhook với thông tin chi tiết
    if Config.DiscordWebhook.enabled then
        local identifiers = GetPlayerIdentifiers(source)
        local license = 'Unknown'
        
        for _, id in pairs(identifiers) do
            if string.match(id, 'license:') then
                license = id
                break
            end
        end
        
        local embed = {
            {
                ['title'] = '👮 TÙ LIÊN BANG - ' .. (reason or 'Điểm uy tín thấp'),
                ['color'] = 15158332,
                ['fields'] = {
                    {
                        ['name'] = '👤 Người chơi',
                        ['value'] = charName,
                        ['inline'] = false
                    },
                    {
                        ['name'] = '⚖️ Lý do',
                        ['value'] = reason or 'Điểm uy tín thấp',
                        ['inline'] = false
                    },
                    {
                        ['name'] = '⏱️ Thời gian',
                        ['value'] = math.ceil(prisonTime / 60) .. ' phút',
                        ['inline'] = true
                    },
                    {
                        ['name'] = '📊 Điểm uy tín',
                        ['value'] = tostring(reputation) .. '/100',
                        ['inline'] = true
                    },
                    {
                        ['name'] = '🆔 PID',
                        ['value'] = tostring(player.PlayerData.pid or source),
                        ['inline'] = true
                    },
                    {
                        ['name'] = '🔑 License',
                        ['value'] = '`' .. license .. '`',
                        ['inline'] = true
                    }
                },
                ['footer'] = {
                    ['text'] = 'Hệ thống Tù Liên Bang'
                },
                ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
        
        PerformHttpRequest(Config.DiscordWebhook.prisonURL, function(err, text, headers) 
            if err == 200 or err == 204 then
                print('[DIEMUYTIN] Prison Discord log sent for ' .. citizenid)
            end
        end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
    
    -- Thông báo
    local minutes = math.ceil(prisonTime / 60)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Tù Liên Bang',
        description = Config.PrisonSystem.messages.imprisoned:format(minutes),
        type = 'error',
        duration = 8000
    })
    
    -- Bắt đầu timer đếm ngược
    prisonTimers[citizenid] = {
        source = source,
        timeLeft = prisonTime,
        startTime = os.time()
    }
    
    --print('[DIEMUYTIN PRISON] Imprisoned player: ' .. citizenid .. ' for ' .. prisonTime .. ' seconds')
end

-- Hàm kiểm tra và xử lý uy tín thấp
local function checkLowReputation(source)
    if not Config.PrisonSystem.enabled then 
        --print('[DIEMUYTIN DEBUG] Prison system disabled')
        return 
    end
    
    local player = QBX:GetPlayer(source)
    if not player then 
        --print('[DIEMUYTIN DEBUG] Player not found for source: ' .. source)
        return 
    end
    
    local reputation = player.PlayerData.metadata.reputation or Config.ReputationSystem.defaultReputation
    local threshold = Config.PrisonSystem.reputationThreshold
    
    --print('[DIEMUYTIN DEBUG] Checking reputation for ' .. player.PlayerData.citizenid .. ' - Reputation: ' .. reputation .. ', Threshold: ' .. threshold)
    
    if reputation < threshold then
        --print('[DIEMUYTIN DEBUG] Player has low reputation, checking prison status...')
        
        -- Kiểm tra xem đã bị tù chưa
        getPrisonInfo(player.PlayerData.citizenid, function(prisonData)
            if not prisonData then
                --print('[DIEMUYTIN DEBUG] Player not in prison, imprisoning...')
                -- Chưa bị tù, tiến hành bỏ tù
                imprisonPlayer(source, Config.PrisonSystem.prisonTime, 'Uy tín quá thấp: ' .. reputation)
            else
                --print('[DIEMUYTIN DEBUG] Player already in prison')
            end
        end)
    else
        --print('[DIEMUYTIN DEBUG] Player reputation OK (' .. reputation .. ' >= ' .. threshold .. ')')
    end
end

-- Hàm lấy tên hiển thị (ẩn nếu không phải police onduty)
local function getDisplayName(checkerSource, targetSource)
    local targetPlayer = QBX:GetPlayer(targetSource)
    if not targetPlayer then return locale['unknown_person'] end
    
    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    
    -- Nếu người check là police onduty thì hiển thị tên thật
    if isPoliceOnDuty(checkerSource) then
        return targetName
    else
        -- Nếu không phải police onduty thì ẩn tên
        return locale['unknown_person']
    end
end
local function getPlayerReputation(source)
    local player = QBX:GetPlayer(source)
    if not player then return Config.ReputationSystem.defaultReputation end
    
    local metadata = player.PlayerData.metadata
    
    -- Kiểm tra và khởi tạo metadata nếu chưa có
    if not metadata.reputation then
        player.Functions.SetMetaData('reputation', Config.ReputationSystem.defaultReputation)
        return Config.ReputationSystem.defaultReputation
    end
    
    return metadata.reputation
end

-- Hàm hiển thị cảnh báo uy tín thấp
local function showReputationWarning(source, reputation)
    -- FUNCTION ĐÃ TẮT - KHÔNG HIỆN THÔNG BÁO GÌ CẢ
    -- local player = QBX:GetPlayer(source)
    -- if not player then return end
    -- TriggerClientEvent('ox_lib:notify', source, {...})
end

-- Hàm cập nhật điểm uy tín
local function updatePlayerReputation(source, amount)
    local player = QBX:GetPlayer(source)
    if not player then return false end
    
    local currentReputation = getPlayerReputation(source)
    local newReputation = math.max(0, math.min(Config.ReputationSystem.maxReputation, currentReputation + amount))
    
    player.Functions.SetMetaData('reputation', newReputation)
    
    -- Kiểm tra cảnh báo uy tín dưới ngưỡng cảnh báo (mặc định 70%)
    local warningThreshold = Config.ReputationSystem.maxReputation * (Config.ReputationSystem.warningThreshold or 0.7)
    if newReputation <= warningThreshold and newReputation >= Config.PrisonSystem.reputationThreshold then
        CreateThread(function()
            Wait(1000) -- Delay 1 giây để thông báo penalty hiện trước
            showReputationWarning(source, newReputation)
        end)
    end
    
    -- Kiểm tra xem có cần bỏ tù không khi uy tín xuống thấp
    if newReputation < Config.PrisonSystem.reputationThreshold then
        CreateThread(function()
            Wait(2000) -- Delay 2 giây để thông báo penalty hiện trước
            -- Gửi event sang nl_hotcut để bỏ tù với số actions có thể config
            TriggerEvent('nl_hotcut:imprisonByReputation', source)
        end)
    end
    
    return newReputation
end

-- Hàm kiểm tra cooldown
local function isOnCooldown(source, actionType)
    local playerId = tostring(source)
    if not playerCooldowns[playerId] then
        playerCooldowns[playerId] = {}
    end
    
    local currentTime = GetGameTimer()
    local lastAction = playerCooldowns[playerId][actionType] or 0
    local cooldownTime = Config.ReputationSystem.cooldown[actionType] * 1000
    
    return (currentTime - lastAction) < cooldownTime
end

-- Hàm đặt cooldown
local function setCooldown(source, actionType)
    local playerId = tostring(source)
    if not playerCooldowns[playerId] then
        playerCooldowns[playerId] = {}
    end
    
    playerCooldowns[playerId][actionType] = GetGameTimer()
end

-- Event xử lý yêu cầu kiểm tra uy tín của chính mình
RegisterNetEvent('diemuytin:requestMyReputation', function()
    local source = source
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local reputation = getPlayerReputation(source)
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    
    TriggerClientEvent('diemuytin:showReputationMenu', source, charName, reputation)
end)

-- Lệnh kiểm tra điểm uy tín
safeAddCommand('diemuytin', {
    help = 'Kiểm tra điểm uy tín của bạn',
    restricted = false
}, function(source, args, raw)
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local reputation = getPlayerReputation(source)
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    
    TriggerClientEvent('diemuytin:showReputationMenu', source, charName, reputation)
end)

-- Lệnh admin để set điểm uy tín
safeAddCommand('setdiemuytin', {
    help = 'Đặt điểm uy tín cho người chơi',
    params = {
        { name = 'playerid', type = 'playerId', help = 'ID của người chơi' },
        { name = 'amount', type = 'number', help = 'Số điểm uy tín (0-100)' }
    },
    restricted = true -- Tạm thời bỏ restriction để test
}, function(source, args, raw)
    -- Debug: In ra thông tin để kiểm tra
    --print('[DIEMUYTIN DEBUG] setreputation called by source: ' .. source)
    --print('[DIEMUYTIN DEBUG] args received:', json.encode(args))
    
    local targetId = args.playerid
    local amount = args.amount
    
    -- Kiểm tra permission (simplified)
    if source ~= 0 then
        local player = QBX:GetPlayer(source)
        if not player then 
            --print('[DIEMUYTIN DEBUG] Player not found for source: ' .. source)
            return 
        end
        
        -- Tạm thời cho phép tất cả để test - sẽ thêm permission sau
        --print('[DIEMUYTIN DEBUG] Player found: ' .. player.PlayerData.citizenid)
    end
    
    if not targetId or not amount then
        local errorMsg = 'Thiếu tham số! Sử dụng: /setreputation [playerid] [số điểm]'
        if source == 0 then
            --print('[DIEMUYTIN] ' .. errorMsg)
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi tham số',
                description = errorMsg,
                type = 'error'
            })
        end
        return
    end
    
    local targetPlayer = QBX:GetPlayer(targetId)
    if not targetPlayer then
        local message = 'Không tìm thấy người chơi với ID: ' .. targetId
        if source == 0 then
            --print('[DIEMUYTIN] ' .. message)
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Không tìm thấy người chơi',
                description = message,
                type = 'error'
            })
        end
        return
    end
    
    local clampedAmount = math.max(0, math.min(Config.ReputationSystem.maxReputation, amount))
    targetPlayer.Functions.SetMetaData('reputation', clampedAmount)
    
    local successMessage = 'Đã đặt điểm uy tín cho ' .. targetPlayer.PlayerData.citizenid .. ' thành: ' .. clampedAmount
    if source == 0 then
        --print('[DIEMUYTIN] ' .. successMessage)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Thành công',
            description = successMessage,
            type = 'success'
        })
    end
    
    --print('[DIEMUYTIN] Successfully set reputation for player ' .. targetId .. ' to ' .. clampedAmount)
end)

-- Lệnh debug kiểm tra metadata
-- safeAddCommand('checkmeta', {
--     help = 'Kiểm tra metadata reputation (debug)',
--     restricted = false
-- }, function(source, args, raw)
--     if source == 0 then return end -- Chỉ cho player
    
--     local player = QBX:GetPlayer(source)
--     if not player then return end
    
--     local metadata = player.PlayerData.metadata
--     local reputation = metadata.reputation
    
--     TriggerClientEvent('ox_lib:notify', source, {
--         title = 'Debug Metadata',
--         description = 'Reputation metadata: ' .. tostring(reputation),
--         type = 'info',
--         duration = 5000
--     })
    
--     --print('[DIEMUYTIN DEBUG] Player ' .. source .. ' (' .. player.PlayerData.citizenid .. ') - Reputation: ' .. tostring(reputation))
-- end)

-- Lệnh test để kiểm tra command system
-- safeAddCommand('testcommand', {
--     help = 'Test command system',
--     params = {
--         { name = 'testparam', type = 'string', help = 'Test parameter' }
--     },
--     restricted = false
-- }, function(source, args, raw)
--     --print('[DIEMUYTIN TEST] Command called by: ' .. source)
--     --print('[DIEMUYTIN TEST] Args received: ', json.encode(args))
--     --print('[DIEMUYTIN TEST] Raw: ' .. (raw or 'nil'))
    
--     local message = 'Test command works! Param: ' .. (args.testparam or 'none')
--     if source == 0 then
--         --print('[DIEMUYTIN TEST] ' .. message)
--     else
--         TriggerClientEvent('ox_lib:notify', source, {
--             title = 'Test Success',
--             description = message,
--             type = 'success'
--         })
--     end
-- end)

-- Event xử lý khi người chơi đánh nhau trong khu vực cấm
RegisterNetEvent('diemuytin:combatInForbiddenZone', function(zoneName, victimServerId)
    local source = source
    local zoneNameDisplay = zoneName or "Khu vực cấm"
    
    -- KIỂM TRA BUCKET - CHỈ TRỪ ĐIỂM Ở BUCKET 0
    local playerBucket = GetPlayerRoutingBucket(source)
    if playerBucket ~= 0 then
        return
    end
    
    -- KIỂM TRA XEM NGƯỜI CHƠI CÓ PHẢI LÀ CÔNG AN ĐANG LÀM VIỆC KHÔNG
    if isPoliceOnDuty(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Hệ thống uy tín',
            description = 'Bạn là ban ngành đang làm việc - được miễn phạt',
            type = 'inform',
            duration = Config.Notifications.duration,
            position = Config.Notifications.position
        })
        return
    end
    
    if isOnCooldown(source, 'combat') then
        return
    end
    
    local newReputation = updatePlayerReputation(source, Config.ReputationSystem.penalties.combatInForbiddenZone)
    setCooldown(source, 'combat')
    
    -- Lưu thông tin để gửi Discord log khi nhận được screenshot
    playerPenaltyApplied[source] = {
        type = 'combat',
        victimServerId = victimServerId,
        zoneName = zoneNameDisplay
    }
    
    -- Hiển thị UI cảnh báo nếu uy tín <= 20 điểm
    if newReputation <= Config.ReputationSystem.combatUIThreshold then
        local player = QBX:GetPlayer(source)
        if player then
            local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            local percentage = math.floor((newReputation / Config.ReputationSystem.maxReputation) * 100)
            
            TriggerClientEvent('diemuytin:showReputationWarning', source, {
                name = charName,
                reputation = newReputation,
                percentage = percentage,
                threshold = Config.PrisonSystem.reputationThreshold,
                reason = string.format('Bạn vừa đánh nhau ở vùng an toàn và bị trừ %d điểm uy tín!', math.abs(Config.ReputationSystem.penalties.combatInForbiddenZone)),
                displayTime = Config.ReputationSystem.combatUIDisplayTime,
                skipVehiclePenalty = true -- KHÔNG tắt máy xe, xuống xe cho combat
            })
        end
    end
end)

-- Event xử lý khi người chơi đâm xe vào người khác
RegisterNetEvent('diemuytin:vehicleRamming', function(victimServerId)
    local source = source
    
    -- KIỂM TRA BUCKET - CHỈ TRỪ ĐIỂM Ở BUCKET 0
    local playerBucket = GetPlayerRoutingBucket(source)
    if playerBucket ~= 0 then
        return
    end
    
    -- KIỂM TRA XEM NGƯỜI CHƠI CÓ PHẢI LÀ CÔNG AN ĐANG LÀM VIỆC KHÔNG
    if isPoliceOnDuty(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Hệ thống uy tín',
            description = 'Bạn là ban ngành đang - được miễn phạt',
            type = 'inform',
            duration = Config.Notifications.duration,
            position = Config.Notifications.position
        })
        return
    end
    
    -- Kiểm tra player tồn tại
    local player = QBX:GetPlayer(source)
    if not player then 
        return 
    end
    
    if isOnCooldown(source, 'ramming') then
        return
    end
    
    -- Trừ điểm uy tín
    local newReputation = updatePlayerReputation(source, Config.ReputationSystem.penalties.vehicleRamming)
    setCooldown(source, 'ramming')
    
    -- Đánh dấu đã trừ điểm để gửi Discord B sau
    playerPenaltyApplied[source] = {
        type = 'ramming',
        victimServerId = victimServerId
    }
    
    -- Hiển thị UI cảnh báo đẹp nếu uy tín thấp
    local warningThreshold = Config.ReputationSystem.maxReputation * Config.ReputationSystem.warningThreshold
    
    if newReputation <= warningThreshold then
        local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        local percentage = math.floor((newReputation / Config.ReputationSystem.maxReputation) * 100)
        
        TriggerClientEvent('diemuytin:showReputationWarning', source, {
            name = charName,
            reputation = newReputation,
            percentage = percentage,
            threshold = Config.PrisonSystem.reputationThreshold,
            reason = string.format('Bạn vừa đâm xe vào người chơi khác và bị trừ %d điểm uy tín!', math.abs(Config.ReputationSystem.penalties.vehicleRamming))
        })
    end
end)

-- Event nhận URL screenshot từ đâm xe và gửi Discord B
RegisterNetEvent('diemuytin:sendScreenshotUrl', function(screenshotUrl, victimServerId)
    local source = source
    
    -- LƯU URL để dùng cho prison log
    playerScreenshotUrls[source] = screenshotUrl
    
    local penaltyData = playerPenaltyApplied[source]
    local isApplied = false
    local targetVictim = victimServerId
    
    if penaltyData == true then
        isApplied = true
    elseif type(penaltyData) == 'table' and penaltyData.type == 'ramming' then
        isApplied = true
        if not targetVictim then
            targetVictim = penaltyData.victimServerId
        end
    end
    
    -- CHỈ GỬI DISCORD B nếu server đã thực sự trừ điểm
    if isApplied and Config.DiscordWebhook.enabled and Config.DiscordWebhook.prisonDetailedURL and screenshotUrl then
        local player = QBX:GetPlayer(source)
        if player then
            local citizenid = player.PlayerData.citizenid
            local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            local currentRep = getPlayerReputation(source)
            local license = player.PlayerData.license or 'N/A'
            
            local fields = {
                { ['name'] = '👤 Người vi phạm (Đâm xe)', ['value'] = string.format('**Tên**: %s\n**Citizen ID**: `%s`\n**Player ID**: `%d`\n**Uy tín hiện tại**: `%d/100`', charName, citizenid, source, currentRep), ['inline'] = false },
                { ['name'] = '🔑 License', ['value'] = '`' .. license .. '`', ['inline'] = true }
            }
            
            if targetVictim then
                local victimPlayer = QBX:GetPlayer(targetVictim)
                if victimPlayer then
                    local vCitizenId = victimPlayer.PlayerData.citizenid
                    local vCharName = victimPlayer.PlayerData.charinfo.firstname .. ' ' .. victimPlayer.PlayerData.charinfo.lastname
                    local vRep = getPlayerReputation(targetVictim)
                    table.insert(fields, {
                        ['name'] = '🎯 Người bị đâm',
                        ['value'] = string.format('**Tên**: %s\n**Citizen ID**: `%s`\n**Player ID**: `%d`\n**Uy tín**: `%d/100`', vCharName, vCitizenId, targetVictim, vRep),
                        ['inline'] = false
                    })
                else
                    table.insert(fields, {
                        ['name'] = '🎯 Người bị đâm',
                        ['value'] = string.format('**Player ID**: `%d` (Đã offline)', targetVictim),
                        ['inline'] = false
                    })
                end
            end
            
            local embed = {
                {
                    ['title'] = '🚗 VI PHẠM ĐÂM XE',
                    ['color'] = 16744192,
                    ['fields'] = fields,
                    ['image'] = { ['url'] = screenshotUrl },
                    ['footer'] = { ['text'] = 'Hệ thống Điểm Uy Tín' },
                    ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
                }
            }
            
            PerformHttpRequest(Config.DiscordWebhook.prisonDetailedURL, function(err, text, headers)
            end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
        end
        
        -- Xóa flag sau khi gửi xong
        playerPenaltyApplied[source] = nil
    end
end)

-- Event nhận URL screenshot từ combat và gửi Discord B
RegisterNetEvent('diemuytin:sendCombatScreenshotUrl', function(screenshotUrl, victimServerId, zoneName)
    local source = source
    
    -- LƯU URL để dùng cho prison log
    playerScreenshotUrls[source] = screenshotUrl
    
    local penaltyData = playerPenaltyApplied[source]
    local isApplied = false
    local targetVictim = victimServerId
    local zoneNameDisplay = zoneName
    
    if penaltyData == true then
        isApplied = true
    elseif type(penaltyData) == 'table' and penaltyData.type == 'combat' then
        isApplied = true
        if not targetVictim then
            targetVictim = penaltyData.victimServerId
        end
        if not zoneNameDisplay then
            zoneNameDisplay = penaltyData.zoneName
        end
    end
    
    -- CHỈ GỬI DISCORD B nếu server đã thực sự trừ điểm
    if isApplied and Config.DiscordWebhook.enabled and Config.DiscordWebhook.prisonDetailedURL and screenshotUrl then
        local player = QBX:GetPlayer(source)
        if player then
            local citizenid = player.PlayerData.citizenid
            local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            local currentRep = getPlayerReputation(source)
            local license = player.PlayerData.license or 'N/A'
            
            local fields = {
                { ['name'] = '👤 Người vi phạm (Đánh nhau)', ['value'] = string.format('**Tên**: %s\n**Citizen ID**: `%s`\n**Player ID**: `%d`\n**Uy tín hiện tại**: `%d/100`', charName, citizenid, source, currentRep), ['inline'] = false },
                { ['name'] = '📍 Địa điểm', ['value'] = tostring(zoneNameDisplay or 'Khu vực cấm'), ['inline'] = false },
                { ['name'] = '🔑 License', ['value'] = '`' .. license .. '`', ['inline'] = true }
            }
            
            if targetVictim then
                local victimPlayer = QBX:GetPlayer(targetVictim)
                if victimPlayer then
                    local vCitizenId = victimPlayer.PlayerData.citizenid
                    local vCharName = victimPlayer.PlayerData.charinfo.firstname .. ' ' .. victimPlayer.PlayerData.charinfo.lastname
                    local vRep = getPlayerReputation(targetVictim)
                    table.insert(fields, {
                        ['name'] = '🎯 Người bị đánh',
                        ['value'] = string.format('**Tên**: %s\n**Citizen ID**: `%s`\n**Player ID**: `%d`\n**Uy tín**: `%d/100`', vCharName, vCitizenId, targetVictim, vRep),
                        ['inline'] = false
                    })
                else
                    table.insert(fields, {
                        ['name'] = '🎯 Người bị đánh',
                        ['value'] = string.format('**Player ID**: `%d` (Đã offline)', targetVictim),
                        ['inline'] = false
                    })
                end
            end
            
            local embed = {
                {
                    ['title'] = '⚔️ VI PHẠM ĐÁNH NHAU TRONG KHU VỰC CẤM',
                    ['color'] = 16711680,
                    ['fields'] = fields,
                    ['image'] = { ['url'] = screenshotUrl },
                    ['footer'] = { ['text'] = 'Hệ thống Điểm Uy Tín' },
                    ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
                }
            }
            
            PerformHttpRequest(Config.DiscordWebhook.prisonDetailedURL, function(err, text, headers)
            end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
        end
        
        -- Xóa flag sau khi gửi xong
        playerPenaltyApplied[source] = nil
    end
end)

-- Event nhận link screenshot từ client (cho prison)
RegisterNetEvent('diemuytin:sendScreenshotForPrison', function(screenshotUrl)
    local source = source
    
    -- Lưu URL vào bảng
    playerScreenshotUrls[source] = screenshotUrl
end)

-- Hook event nl_hotcut:imprisonByReputation để gửi Discord B
AddEventHandler('nl_hotcut:imprisonByReputation', function(source)
    local player = QBX:GetPlayer(source)
    if not player then
        return 
    end
    
    local citizenid = player.PlayerData.citizenid
    local charName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    
    -- Gửi Discord B với thông tin đầy đủ (KHÔNG CẦN ẢNH)
    if Config.DiscordWebhook.enabled and Config.DiscordWebhook.prisonDetailedURL then
            local embed = {
                {
                    ['title'] = '🚔 TÙ LIÊN BANG - Điểm uy tín quá thấp',
                    ['color'] = 15158332, -- Màu đỏ
                    ['fields'] = {
                        {
                            ['name'] = '👤 Tên nhân vật',
                            ['value'] = charName,
                            ['inline'] = true
                        },
                        {
                            ['name'] = '🆔 Citizen ID',
                            ['value'] = '`' .. citizenid .. '`',
                            ['inline'] = true
                        },
                        {
                            ['name'] = '� PID',
                            ['value'] = tostring(player.PlayerData.pid or source),
                            ['inline'] = true
                        }
                    },
                    ['footer'] = {
                        ['text'] = 'Hệ thống Điểm Uy Tín & Tù Liên Bang'
                    },
                    ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
                }
            }
            
            PerformHttpRequest(Config.DiscordWebhook.prisonDetailedURL, function(err, text, headers) 
            end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end)

-- NEW EVENT: Xử lý combat với NPC trong khu vực cấm - ĐÃ TẮT THEO YÊU CẦU
--[[
RegisterNetEvent('diemuytin:npcCombatInForbiddenZone', function(zoneName)
    local source = source
    local zoneNameDisplay = zoneName or "Khu vực cấm"
    --print('[DIEMUYTIN DEBUG] Server nhận event npcCombatInForbiddenZone từ player ' .. source .. ' tại ' .. zoneNameDisplay)
    
    -- KIỂM TRA BUCKET - CHỈ TRỪ ĐIỂM Ở BUCKET 0
    local playerBucket = GetPlayerRoutingBucket(source)
    if playerBucket ~= 0 then
        return
    end
    
    -- KIỂM TRA XEM NGƯỜI CHƠI CÓ PHẢI LÀ CÔNG AN ĐANG LÀM VIỆC KHÔNG
    if isPoliceOnDuty(source) then
        --print('[DIEMUYTIN DEBUG] Player ' .. source .. ' là công an đang làm việc - miễn phạt NPC combat')
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Hệ thống uy tín',
            description = 'Bạn là ban ngành đang làm việc - được miễn phạt',
            type = 'inform',
            duration = Config.Notifications.duration,
            position = Config.Notifications.position
        })
        return
    end
    
    if isOnCooldown(source, 'combat') then
        --print('[DIEMUYTIN DEBUG] Player ' .. source .. ' đang trong combat cooldown')
        return
    end
    
    local newReputation = updatePlayerReputation(source, Config.ReputationSystem.penalties.npcCombatInForbiddenZone)
    setCooldown(source, 'combat')
    
    --print('[DIEMUYTIN DEBUG] Trừ điểm uy tín NPC combat: ' .. math.abs(Config.ReputationSystem.penalties.npcCombatInForbiddenZone) .. ', còn lại: ' .. newReputation)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Uy tín bị giảm',
        description = string.format('Bạn bị trừ %s điểm uy tín do đánh NPC tại %s. Uy tín hiện tại: %s', 
                                   math.abs(Config.ReputationSystem.penalties.npcCombatInForbiddenZone), zoneNameDisplay, newReputation),
        type = 'error',
        duration = Config.Notifications.duration,
        position = Config.Notifications.position
    })
    
    if newReputation <= 20 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale['reputation_low'],
            type = 'warning',
            duration = Config.Notifications.duration,
            position = Config.Notifications.position
        })
    end
end)
--]]

-- NEW EVENT: Xử lý ramming với NPC - ĐÃ TẮT THEO YÊU CẦU
-- RegisterNetEvent('diemuytin:vehicleRammingNPC', function()
--     local source = source
--     --print('[DIEMUYTIN DEBUG] Server nhận event vehicleRammingNPC từ player ' .. source)
--     
--     -- KIỂM TRA XEM NGƯỜI CHƠI CÓ PHẢI LÀ CÔNG AN ĐANG LÀM VIỆC KHÔNG
--     if isPoliceOnDuty(source) then
--         --print('[DIEMUYTIN DEBUG] Player ' .. source .. ' là công an đang làm việc - miễn phạt NPC ramming')
--         TriggerClientEvent('ox_lib:notify', source, {
--             title = 'Hệ thống uy tín',
--             description = 'Bạn là công an đang làm việc - được miễn phạt khi đâm NPC',
--             type = 'inform',
--             duration = Config.Notifications.duration,
--             position = Config.Notifications.position
--         })
--         return
--     end
--     
--     local player = QBX:GetPlayer(source)
--     if not player then 
--         --print('[DIEMUYTIN DEBUG] Player not found, rejecting NPC ramming event')
--         return 
--     end
--     
--     if isOnCooldown(source, 'ramming') then
--         --print('[DIEMUYTIN DEBUG] Player ' .. source .. ' đang trong ramming cooldown')
--         return
--     end
--     
--     local newReputation = updatePlayerReputation(source, Config.ReputationSystem.penalties.vehicleRammingNPC)
--     setCooldown(source, 'ramming')
--     
--     --print('[DIEMUYTIN DEBUG] Trừ điểm uy tín NPC ramming: ' .. math.abs(Config.ReputationSystem.penalties.vehicleRammingNPC) .. ', còn lại: ' .. newReputation)
--     
--     TriggerClientEvent('ox_lib:notify', source, {
--         title = 'Uy tín bị giảm',
--         description = string.format('Bạn bị trừ %s điểm uy tín do đâm xe vào NPC. Uy tín hiện tại: %s', 
--                                    math.abs(Config.ReputationSystem.penalties.vehicleRammingNPC), newReputation),
--         type = 'error',
--         duration = Config.Notifications.duration,
--         position = Config.Notifications.position
--     })
--     
--     if newReputation <= 20 then
--         TriggerClientEvent('ox_lib:notify', source, {
--             title = locale['reputation_low'],
--             type = 'warning',
--             duration = Config.Notifications.duration,
--             position = Config.Notifications.position
--         })
--     end
-- end)

-- NEW EVENT: Xử lý tự gây sát thương bằng xe - ĐÃ TẮT THEO YÊU CẦU
--[[
RegisterNetEvent('diemuytin:selfVehicleDamage', function()
    local source = source
    --print('[DIEMUYTIN DEBUG] Server nhận event selfVehicleDamage từ player ' .. source)
    
    -- KIỂM TRA BUCKET - CHỈ TRỪ ĐIỂM Ở BUCKET 0
    local playerBucket = GetPlayerRoutingBucket(source)
    if playerBucket ~= 0 then
        return
    end
    
    -- KIỂM TRA XEM NGƯỜI CHƠI CÓ PHẢI LÀ CÔNG AN ĐANG LÀM VIỆC KHÔNG
    if isPoliceOnDuty(source) then
        --print('[DIEMUYTIN DEBUG] Player ' .. source .. ' là công an đang làm việc - miễn phạt self damage')
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Hệ thống uy tín',
            description = 'Bạn là ban ngành đang làm việc - được miễn phạt',
            type = 'inform',
            duration = Config.Notifications.duration,
            position = Config.Notifications.position
        })
        return
    end
    
    local player = QBX:GetPlayer(source)
    if not player then 
        --print('[DIEMUYTIN DEBUG] Player not found, rejecting self damage event')
        return 
    end
    
    if isOnCooldown(source, 'ramming') then
        --print('[DIEMUYTIN DEBUG] Player ' .. source .. ' đang trong ramming cooldown')
        return
    end
    
    local newReputation = updatePlayerReputation(source, Config.ReputationSystem.penalties.selfVehicleDamage)
    setCooldown(source, 'ramming')
    
    --print('[DIEMUYTIN DEBUG] Trừ điểm uy tín self damage: ' .. math.abs(Config.ReputationSystem.penalties.selfVehicleDamage) .. ', còn lại: ' .. newReputation)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Uy tín bị giảm',
        description = string.format('Bạn bị trừ %s điểm uy tín do tự gây sát thương bằng xe. Uy tín hiện tại: %s', 
                                   math.abs(Config.ReputationSystem.penalties.selfVehicleDamage), newReputation),
        type = 'error',
        duration = Config.Notifications.duration,
        position = Config.Notifications.position
    })
    
    if newReputation <= 20 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale['reputation_low'],
            type = 'warning',
            duration = Config.Notifications.duration,
            position = Config.Notifications.position
        })
    end
end)
--]]

-- Event để lấy thông tin điểm uy tín (method ổn định cho mọi server)
RegisterNetEvent('diemuytin:requestReputation', function()
    local source = source
    local reputation = getPlayerReputation(source)
    TriggerClientEvent('diemuytin:receiveReputation', source, reputation)
end)

-- ============================================
-- Sám hối SYSTEM - Server Events
-- ============================================

-- Event xử lý hoàn thành yoga và cộng điểm uy tín
RegisterNetEvent('xamhoi:completeYoga', function()
    local src = source
    local Player = QBX:GetPlayer(src)
    
    if not Player then
        --print('[XAMHOI ERROR] Không tìm thấy player data cho source: ' .. src)
        return
    end
    
    local citizenId = Player.PlayerData.citizenid
    
    --print('[XAMHOI DEBUG] Player ' .. citizenId .. ' hoàn thành yoga')
    
    -- Lấy uy tín hiện tại từ metadata
    local currentReputation = Player.PlayerData.metadata.reputation or Config.ReputationSystem.defaultReputation
    
    -- Tính điểm uy tín cần cộng = số điểm còn thiếu để đạt 100
    local reputationGain = Config.ReputationSystem.maxReputation - currentReputation
    local newReputation = Config.ReputationSystem.maxReputation -- Luôn = 100 sau khi Sám hối
    
    --print('[XAMHOI DEBUG] Reputation update: ' .. currentReputation .. ' -> ' .. newReputation .. ' (gain: +' .. reputationGain .. ')')
    
    -- Cập nhật metadata và lưu vào database
    Player.Functions.SetMetaData('reputation', newReputation)
    
    -- Thông báo cho người chơi
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Sám Hối Thành Công',
        description = string.format('Bạn được cộng %s điểm uy tín qua tình yêu nước. Uy tín hiện tại: %s/100', 
                                   reputationGain, newReputation),
        type = 'success'
    })
end)

-- ============================================

-- Event kiểm tra uy tín của người chơi khác qua target
RegisterNetEvent('diemuytin:checkTargetReputation', function(targetServerId)
    local source = source
    
    if not targetServerId then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Không thể xác định người chơi được target!',
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra người kiểm tra có phải police onduty không
    if not isPoliceOnDuty(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Chỉ công an đang làm việc mới có thể kiểm tra thông tin!',
            type = 'error'
        })
        return
    end
    
    -- Lấy thông tin người chơi target
    local targetPlayer = QBX:GetPlayer(targetServerId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Người chơi không tồn tại!',
            type = 'error'
        })
        return
    end
    
    -- Lấy thông tin người kiểm tra
    local checkerPlayer = QBX:GetPlayer(source)
    if not checkerPlayer then return end
    
    local checkerName = checkerPlayer.PlayerData.charinfo.firstname .. ' ' .. checkerPlayer.PlayerData.charinfo.lastname
    
    -- Kiểm tra xem người bị target có đang bị còng không
    local isCuffed = targetPlayer.PlayerData.metadata.ishandcuffed or false
    
    if isCuffed then
        -- Người bị còng - hiển thị thông tin trực tiếp không cần xác nhận
        local targetReputation = getPlayerReputation(targetServerId)
        local displayName = getDisplayName(source, targetServerId)
        local targetPID = targetPlayer.PlayerData.pid or targetPlayer.PlayerData.citizenid or targetServerId
        
        -- Gửi thông tin về client để hiển thị menu
        TriggerClientEvent('diemuytin:showTargetReputationMenu', source, displayName, targetReputation, true, targetPID)
        
        -- Thông báo cho người bị kiểm tra
        TriggerClientEvent('ox_lib:notify', targetServerId, {
            title = 'Kiểm tra thông tin',
            description = checkerName .. ' đã kiểm tra thông tin của bạn (bị còng tay)',
            type = 'warning',
            duration = 3000
        })
        
        print('[DIEMUYTIN] Police Check (Cuffed) - ' .. checkerName .. ' checked ' .. displayName .. ' - Reputation: ' .. targetReputation)
    else
        -- Không bị còng - gửi yêu cầu xác nhận
        TriggerClientEvent('diemuytin:requestReputationCheck', targetServerId, source, checkerName)
        
        -- Thông báo cho người kiểm tra
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Đang chờ xác nhận',
            description = 'Đã gửi yêu cầu kiểm tra thông tin. Vui lòng chờ đối phương xác nhận...',
            type = 'info',
            duration = 5000
        })
    end
end)

-- Event xử lý phản hồi xác nhận từ người bị kiểm tra
RegisterNetEvent('diemuytin:respondReputationCheck', function(checkerSource, accepted)
    local targetSource = source
    
    if not accepted then
        -- Người bị kiểm tra từ chối
        TriggerClientEvent('ox_lib:notify', checkerSource, {
            title = 'Bị từ chối',
            description = 'Người chơi đã từ chối yêu cầu kiểm tra thông tin của bạn!',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Người bị kiểm tra chấp nhận - tiến hành hiển thị thông tin
    local targetPlayer = QBX:GetPlayer(targetSource)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', checkerSource, {
            title = 'Lỗi',
            description = 'Không thể lấy thông tin người chơi!',
            type = 'error'
        })
        return
    end
    
    local targetReputation = getPlayerReputation(targetSource)
    local displayName = getDisplayName(checkerSource, targetSource)
    
    -- Lấy PID - kiểm tra nhiều nguồn có thể
    local targetPID = targetPlayer.PlayerData.pid or targetPlayer.PlayerData.citizenid or targetSource
    
    -- Debug PID value
    --print('[DIEMUYTIN DEBUG] Target PID: ' .. tostring(targetPID) .. ' (Type: ' .. type(targetPID) .. ')')
    
    -- Gửi thông tin về client để hiển thị menu (thêm PID)
    TriggerClientEvent('diemuytin:showTargetReputationMenu', checkerSource, displayName, targetReputation, isPoliceOnDuty(checkerSource), targetPID)
    
    -- Thông báo cho người bị kiểm tra
    local checkerPlayer = QBX:GetPlayer(checkerSource)
    if checkerPlayer then
        local checkerName = checkerPlayer.PlayerData.charinfo.firstname .. ' ' .. checkerPlayer.PlayerData.charinfo.lastname
        TriggerClientEvent('ox_lib:notify', targetSource, {
            title = 'Đã chia sẻ thông tin',
            description = 'Bạn đã chia sẻ thông tin uy tín với ' .. checkerName,
            type = 'success',
            duration = 3000
        })
    end
    
    -- Log cho police nếu là police check
    if isPoliceOnDuty(checkerSource) then
        local checkerName = checkerPlayer.PlayerData.charinfo.firstname .. ' ' .. checkerPlayer.PlayerData.charinfo.lastname
        local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
        
        --print('[DIEMUYTIN] Police Check - ' .. checkerName .. ' (' .. checkerSource .. ') checked reputation of ' .. targetName .. ' (' .. targetSource .. ') - Reputation: ' .. targetReputation)
    end
end)

-- Khởi tạo điểm uy tín mặc định cho người chơi mới
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local reputation = Player.PlayerData.metadata.reputation
    if not reputation then
        Player.Functions.SetMetaData('reputation', Config.ReputationSystem.defaultReputation)
        --print('[DIEMUYTIN] Đã khởi tạo điểm uy tín mặc định (' .. Config.ReputationSystem.defaultReputation .. ') cho người chơi: ' .. Player.PlayerData.citizenid)
    end
end)

-- Event khởi tạo metadata khi người chơi join (backup)
AddEventHandler('playerJoining', function()
    local source = source
    
    -- Đợi một chút để đảm bảo player data đã load
    SetTimeout(2000, function()
        local player = QBX:GetPlayer(source)
        if player then
            local reputation = player.PlayerData.metadata.reputation
            if not reputation then
                player.Functions.SetMetaData('reputation', Config.ReputationSystem.defaultReputation)
                --print('[DIEMUYTIN] Backup: Đã khởi tạo điểm uy tín cho người chọi: ' .. player.PlayerData.citizenid)
            end
        end
    end)
end)

-- ============ PRISON SYSTEM EVENTS ============

-- Trash collection system for prison
local takenBags = {} -- Track taken bags per player
local playerHandBag = {} -- Track players holding bags

-- Event xử lý yêu cầu nhặt túi rác
RegisterNetEvent('diemuytin:requestTakeBag', function(bagIndex)
    local source = source
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Kiểm tra xem người chơi có đang bị tù không
    if not prisonTimers[citizenid] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Chỉ tù nhân mới có thể nhặt rác!',
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra túi rác đã được nhặt chưa
    if not takenBags[citizenid] then
        takenBags[citizenid] = {}
    end
    
    if takenBags[citizenid][bagIndex] then
        TriggerClientEvent('diemuytin:takeBagResponse', source, false, bagIndex)
        return
    end
    
    -- Kiểm tra người chơi đã cầm túi rác chưa
    if playerHandBag[citizenid] then
        TriggerClientEvent('diemuytin:takeBagResponse', source, false, bagIndex)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Cảnh báo',
            description = 'Bạn đã cầm một túi rác rồi!',
            type = 'warning'
        })
        return
    end
    
    -- Đánh dấu túi rác đã được nhặt
    takenBags[citizenid][bagIndex] = true
    playerHandBag[citizenid] = bagIndex
    
    TriggerClientEvent('diemuytin:takeBagResponse', source, true, bagIndex)
    
    --print('[DIEMUYTIN PRISON] Player ' .. citizenid .. ' picked up trash bag ' .. bagIndex)
end)

-- Event xử lý đặt túi rác vào thùng
RegisterNetEvent('diemuytin:disposeBag', function()
    local source = source
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Kiểm tra người chơi có đang cầm túi rác không
    if not playerHandBag[citizenid] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Bạn không có túi rác để đặt!',
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra người chơi có đang bị tù không
    if not prisonTimers[citizenid] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Chỉ tù nhân mới có thể làm việc này!',
            type = 'error'
        })
        return
    end
    
    -- Giảm thời gian tù
    local timeReduction = Config.PrisonSystem.trashCollection.timeReduction
    local oldTime = prisonTimers[citizenid].timeLeft
    prisonTimers[citizenid].timeLeft = math.max(0, prisonTimers[citizenid].timeLeft - timeReduction)
    local newTime = prisonTimers[citizenid].timeLeft
    
    -- Cập nhật database
    local query = [[
        UPDATE reputation_prison 
        SET prison_time = ? 
        WHERE citizenid = ? AND is_active = 1
    ]]
    exports.oxmysql:update(query, {newTime, citizenid})
    
    -- Reset túi rác đã nhặt sau 30 giây (để spawn lại)
    local bagIndex = playerHandBag[citizenid]
    CreateThread(function()
        Wait(30000) -- 30 giây
        if takenBags[citizenid] then
            takenBags[citizenid][bagIndex] = nil
        end
    end)
    
    -- Reset trạng thái cầm túi rác
    playerHandBag[citizenid] = nil
    
    -- Thông báo thành công
    local oldMinutes = math.ceil(oldTime / 60)
    local newMinutes = math.ceil(newTime / 60)
    local reductionMinutes = math.ceil(timeReduction / 60)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Thu Gom Rác',
        description = string.format('Đã thu gom túi rác! Giảm %d phút tù. (Từ %d phút → %d phút)', reductionMinutes, oldMinutes, newMinutes),
        type = 'success'
    })
    
    TriggerClientEvent('diemuytin:bagDisposed', source)
    
    -- Kiểm tra xem có cần respawn túi rác mới không
    TriggerClientEvent('diemuytin:checkRespawnTrash', source)
    
    --print('[DIEMUYTIN PRISON] Player ' .. citizenid .. ' disposed trash bag. Time reduced by ' .. timeReduction .. ' seconds')
end)

-- Event để request thời gian tù còn lại từ NPC quản giáo
RegisterNetEvent('diemuytin:requestPrisonTime', function()
    local source = source
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Kiểm tra xem player có đang bị tù không
    if prisonTimers[citizenid] then
        local timeLeft = prisonTimers[citizenid].timeLeft
        local minutes = math.floor(timeLeft / 60)
        local seconds = timeLeft % 60
        
        local timeString = ""
        if minutes > 0 then
            timeString = string.format("%d phút %d giây", minutes, seconds)
        else
            timeString = string.format("%d giây", seconds)
        end
        
        -- Gửi thông tin về client
        TriggerClientEvent('diemuytin:showPrisonTimeDialog', source, {
            timeLeft = timeLeft,
            timeString = timeString,
            canReduce = Config.PrisonSystem.trashCollection.enabled
        })
    else
        -- Player không bị tù
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Bạn không đang bị tù!',
            type = 'error'
        })
    end
end)

-- Event khi người chọi join server - kiểm tra có đang bị tù không
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local source = source
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    if Config.PrisonSystem.enabled then
        getPrisonInfo(player.PlayerData.citizenid, function(prisonData)
            if prisonData and prisonData.prison_time > 0 then
                -- Người chơi vẫn đang bị tù, tiếp tục phạt
                SetPlayerRoutingBucket(source, Config.PrisonSystem.prisonBucket)
                
                -- Khôi phục timer
                prisonTimers[player.PlayerData.citizenid] = {
                    source = source,
                    timeLeft = prisonData.prison_time,
                    startTime = os.time()
                }
                
                -- Gửi về tù với flag restore để setup lại NPC và trash bags
                TriggerClientEvent('diemuytin:sendToPrison', source, Config.PrisonSystem.location.spawnPoint, false, true)
                
                -- Áp dụng đồng phục tù nhân khi khôi phục
                CreateThread(function()
                    Wait(3000) -- Đợi 3 giây để setup hoàn tất
                    applyPrisonerUniform(source)
                end)
                
                local minutesLeft = math.ceil(prisonData.prison_time / 60)
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Tù Liên Bang',
                    description = 'Bạn vẫn đang bị tù. Thời gian còn lại: ' .. minutesLeft .. ' phút',
                    type = 'error',
                    duration = 8000
                })
                
                --print('[DIEMUYTIN PRISON] Restored prison for player: ' .. player.PlayerData.citizenid .. ' with ' .. prisonData.prison_time .. ' seconds left')
            end
        end)
    end
end)

-- Event kiểm tra escape attempt
RegisterNetEvent('diemuytin:checkPrisonEscape', function(playerCoords)
    local source = source
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    if Config.PrisonSystem.enabled then
        local citizenid = player.PlayerData.citizenid
        
        if prisonTimers[citizenid] then
            local prisonCenter = Config.PrisonSystem.location.center
            local distance = #(playerCoords - prisonCenter)
            
            if distance > Config.PrisonSystem.location.radius then
                -- Cố gắng trốn tù - gia hạn thời gian
                prisonTimers[citizenid].timeLeft = prisonTimers[citizenid].timeLeft + 300 -- Thêm 5 phút
                
                -- Teleport về tù với flag là escape attempt
                TriggerClientEvent('diemuytin:sendToPrison', source, Config.PrisonSystem.location.spawnPoint, true)
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Cảnh Báo Tù',
                    description = Config.PrisonSystem.messages.escapeAttempt,
                    type = 'error',
                    duration = 5000
                })
                
                --print('[DIEMUYTIN PRISON] Escape attempt by: ' .. citizenid)
            end
        end
    end
end)

-- Event kiểm tra trạng thái tù khi client resource start
RegisterNetEvent('diemuytin:checkPrisonStateOnStart', function()
    local source = source
    local player = QBX:GetPlayer(source)
    if not player or not Config.PrisonSystem.enabled then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Kiểm tra xem có trong prisonTimers không (trường hợp server không restart)
    if prisonTimers[citizenid] then
        --print('[DIEMUYTIN PRISON] Player ' .. citizenid .. ' found in prisonTimers, sending to prison...')
        TriggerClientEvent('diemuytin:sendToPrison', source, Config.PrisonSystem.location.spawnPoint, false, true)
        return
    end
    
    -- Kiểm tra database (trường hợp server restart nhưng client chưa)
    getPrisonInfo(citizenid, function(prisonData)
        if prisonData and prisonData.prison_time > 0 then
            --print('[DIEMUYTIN PRISON] Player ' .. citizenid .. ' found in database, restoring prison state...')
            
            -- Khôi phục timer
            prisonTimers[citizenid] = {
                source = source,
                timeLeft = prisonData.prison_time,
                startTime = os.time()
            }
            
            -- Đưa về prison bucket
            SetPlayerRoutingBucket(source, Config.PrisonSystem.prisonBucket)
            
            -- Gửi về tù với flag restore
            TriggerClientEvent('diemuytin:sendToPrison', source, Config.PrisonSystem.location.spawnPoint, false, true)
        end
    end)
end)

-- Admin command để thả người khỏi tù
safeAddCommand('thatulb', {
    help = 'Thả người chơi khỏi tù (admin only)',
    restricted = 'group.admin',
    params = {
        {name = 'id', type = 'playerId', help = 'Player server ID'}
    }
}, function(source, args, raw)
    local targetId = args.id
    if not targetId then return end
    
    local targetPlayer = QBX:GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = 'Không tìm thấy người chơi',
            type = 'error'
        })
        return
    end
    
    releasePrisoner(targetPlayer.PlayerData.citizenid, targetId)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Thành Công',
        description = 'Đã thả người chơi ' .. targetId .. ' khỏi tù',
        type = 'success'
    })
end)

-- Command kiểm tra thời gian tù còn lại
safeAddCommand('kiemtrathoigiantu', {
    help = 'Kiểm tra thời gian tù còn lại',
    restricted = false
}, function(source, args, raw)
    if source == 0 then return end
    
    local player = QBX:GetPlayer(source)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    if prisonTimers[citizenid] then
        local minutesLeft = math.ceil(prisonTimers[citizenid].timeLeft / 60)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Thời Gian Tù',
            description = 'Còn lại: ' .. minutesLeft .. ' phút',
            type = 'info'
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Thông Tin',
            description = 'Bạn không bị tù',
            type = 'info'
        })
    end
end)

-- Command test: Bỏ tù ngay lập tức để test (admin only)
-- LỆNH ĐÃ CHUYỂN SANG nl_hotcut - TẮT ĐI
-- safeAddCommand('giamthoigiantu', {
--     help = 'Test bỏ tù ngay lập tức (admin only)',
--     restricted = 'group.admin',
--     params = {
--         {name = 'id', type = 'playerId', help = 'Player server ID (hoặc để trống để tự bỏ tù)'},
--         {name = 'seconds', type = 'number', help = 'Thời gian tù (giây, mặc định 60s cho test)'}
--     }
-- }, function(source, args, raw)
--     local targetId = args.id or source
--     local prisonTimeTest = args.seconds or 60 -- Mặc định 1 phút để test
    
--     local targetPlayer = QBX:GetPlayer(targetId)
--     if not targetPlayer then
--         TriggerClientEvent('ox_lib:notify', source, {
--             title = 'Lỗi',
--             description = 'Không tìm thấy người chơi',
--             type = 'error'
--         })
--         return
--     end
    
--     -- Force imprisonment regardless of reputation
--     imprisonPlayer(targetId, prisonTimeTest, 'Test bởi admin')
    
--     TriggerClientEvent('ox_lib:notify', source, {
--         title = 'Test Prison',
--         description = string.format('Đã bỏ tù player %d trong %d giây', targetId, prisonTimeTest),
--         type = 'success'
--     })
    
--     --print('[DIEMUYTIN PRISON TEST] Admin ' .. source .. ' imprisoned player ' .. targetId .. ' for ' .. prisonTimeTest .. ' seconds')
-- end)

-- Command test: Setup trash bags manually (admin only)
safeAddCommand('setuptrash', {
    help = 'Setup trash bags manually (admin only)',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('diemuytin:setupTrashBags', source)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Debug',
        description = 'Đã gửi lệnh setup trash bags',
        type = 'info'
    })
end)

-- Command để xem danh sách khu vực cấm
safeAddCommand('listzones', {
    help = 'Xem danh sách khu vực cấm đánh nhau',
    restricted = false
}, function(source, args, raw)
    if source == 0 then return end -- Chỉ cho player
    
    local zoneList = "📍 **Các khu vực cấm đánh nhau:**\n"
    
    for i, zone in ipairs(Config.ReputationSystem.forbiddenCombatZones) do
        zoneList = zoneList .. string.format("%d. %s (Bán kính: %.0fm)\n", i, zone.name, zone.radius)
    end
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Khu Vực Cấm',
        description = zoneList,
        type = 'info',
        duration = 10000,
        position = Config.Notifications.position
    })
end)

-- ============ PRISON SYSTEM THREADS ============
-- ĐÃ TẮT: Prison system không dùng nữa, dùng nl_hotcut thay thế
-- Xóa các vòng lặp while true không cần thiết

-- Event handler khi resource start/restart - khôi phục trạng thái tù
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        --print('[DIEMUYTIN] Resource started - checking for active prisoners...')
        
        if Config.PrisonSystem.enabled then
            CreateThread(function()
                Wait(5000) -- Đợi 5 giây để đảm bảo tất cả đã load
                
                local playerList = GetPlayers()
                
                for _, playerId in ipairs(playerList) do
                    local player = QBX:GetPlayer(tonumber(playerId))
                    if player and player.PlayerData then
                        local citizenid = player.PlayerData.citizenid
                        
                        -- Kiểm tra trong database xem có đang bị tù không
                        getPrisonInfo(citizenid, function(prisonData)
                            if prisonData and prisonData.prison_time > 0 then
                                local source = tonumber(playerId)
                                
                                -- Khôi phục prison timer
                                prisonTimers[citizenid] = {
                                    source = source,
                                    timeLeft = prisonData.prison_time,
                                    startTime = os.time()
                                }
                                
                                -- Đưa về prison bucket
                                SetPlayerRoutingBucket(source, Config.PrisonSystem.prisonBucket)
                                
                                -- Gửi về tù với flag restore
                                TriggerClientEvent('diemuytin:sendToPrison', source, Config.PrisonSystem.location.spawnPoint, false, true)
                                
                                -- Áp dụng đồng phục tù nhân khi khôi phục
                                CreateThread(function()
                                    Wait(3000) -- Đợi 3 giây để setup hoàn tất
                                    applyPrisonerUniform(source)
                                end)
                                
                                local minutesLeft = math.ceil(prisonData.prison_time / 60)
                                TriggerClientEvent('ox_lib:notify', source, {
                                    title = 'Khôi Phục Tù',
                                    description = 'Resource đã restart. Thời gian tù còn lại: ' .. minutesLeft .. ' phút',
                                    type = 'warning',
                                    duration = 8000
                                })
                                
                                --print('[DIEMUYTIN PRISON] Restored prison state for ' .. citizenid .. ' after resource restart')
                            end
                        end)
                    end
                end
            end)
        end
    end
end)
-- mdc- discord
RegisterNetEvent('diemuytin:imprisonPlayer', function(targetSource, prisonTime, reason)
    imprisonPlayer(targetSource, prisonTime, reason)
end)

-- Event nhận từ nl_hotcut khi ra tù để cộng lại điểm uy tín
RegisterNetEvent('nl_hotcut:restoreReputation', function(targetSource, restoreAmount)
    local Player = exports.qbx_core:GetPlayer(targetSource)
    if not Player then 
        print('[DIEMUYTIN] ERROR: Cannot get player for reputation restore')
        return 
    end
    
    -- Sử dụng giá trị được truyền từ nl_hotcut, hoặc mặc định 70
    restoreAmount = restoreAmount or 70
    
    -- Lấy uy tín hiện tại
    local currentReputation = Player.PlayerData.metadata.reputation or 0
    local newReputation = currentReputation + restoreAmount
    
    -- Giới hạn tối đa 100 điểm uy tín
    if newReputation > 100 then
        newReputation = 100
    end
    
    local actualRestore = newReputation - currentReputation
    
    -- Cập nhật uy tín
    Player.Functions.SetMetaData('reputation', newReputation)
    
    -- Thông báo cho người chơi
    TriggerClientEvent('ox_lib:notify', targetSource, {
        title = 'Hoàn Thành Án Tù',
        description = 'Uy tín của bạn đã được khôi phục +' .. actualRestore .. ' điểm. Uy tín hiện tại: ' .. newReputation .. '/100',
        type = 'success',
        duration = 8000
    })
end)
