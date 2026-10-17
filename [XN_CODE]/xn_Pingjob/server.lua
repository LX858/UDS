local tableDs = {
    ['ambulance'] = {},
    ['police'] = {},
    ['taxi'] = {},
    ['mechanic'] = {}
}

local Info_Job = {
    ['police'] = 'Cảnh Sát',
    ['ambulance'] = 'Bác Sĩ',
    ['taxi'] = 'Taxi',
    ['mechanic'] = 'Cứu Hộ'
}

local blacklistCache = {} -- [citizenId] = { time = timestampMs, reason = string, name = string, blacklister = string, job = string }
local pingCooldowns = {}  -- [src] = timestamp

local logger = require '@qbx_core.modules.logger'

local function logEvent(color, Player, eventName, message)
    CreateThread(function()
        pcall(function()
            logger.log({
                source = eventName,
                webhook = 'https://discord.com/api/webhooks/1347959967319068852/z_rJauEBY6sDQUAB67dgcbajOttgyiPkjPt_Jr2OC3LFDNH62eaM3mZtz9tulyyXnhDO',
                event = eventName,
                color = color,
                message = '\n- Tên nhân vật: `' .. (Player.PlayerData.charinfo.firstname or '') .. ' ' .. (Player.PlayerData.charinfo.lastname or '') ..
                          '`\n- CitizenID: `' .. (Player.PlayerData.pid or 'N/A') ..
                          '`\n- ID hiện tại: `' .. (Player.PlayerData.source or 'N/A') ..
                          '`\n- `' .. message .. '`',
            })
        end)
    end)
end

-- Tải toàn bộ blacklist vào RAM khi khởi động
local function LoadBlacklistCache()
    MySQL.Async.fetchAll('SELECT * FROM 1307_blacklist', {}, function(results)
        local nowMs = os.time() * 1000
        blacklistCache = {}
        if results then
            for i = 1, #results do
                local row = results[i]
                local expiryTime = math.floor(tonumber(row.time) or 0)
                if expiryTime > nowMs then
                    blacklistCache[row.identifier] = {
                        time = expiryTime,
                        reason = row.reason,
                        name = row.name,
                        blacklister = row.blacklister,
                        job = row.job
                    }
                else
                    -- Xóa các bản ghi đã hết hạn
                    MySQL.Async.execute('DELETE FROM 1307_blacklist WHERE identifier = @identifier', {
                        ['@identifier'] = row.identifier
                    })
                end
            end
        end
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadBlacklistCache()
    end
end)

-- Helper lấy số lượng và danh sách on-duty player của 1 job
local function getDutyPlayers(jobName)
    local count, sources = exports.qbx_core:GetDutyCountJob(jobName)
    return count or 0, sources or {}
end

-- Push dữ liệu trực tiếp tới các nhân viên đang On-Duty của job đó (KHÔNG BROADCAST -1)
local function pushJobDataToDuty(jobName)
    tableDs[jobName] = tableDs[jobName] or {}
    for i = 1, #tableDs[jobName] do
        local callerId = tableDs[jobName][i].callerId
        if callerId then
            tableDs[jobName][i].bucket = GetPlayerRoutingBucket(tostring(callerId)) or tableDs[jobName][i].bucket or 0
        end
    end
    local count, dutySources = getDutyPlayers(jobName)
    if count > 0 then
        for i = 1, #dutySources do
            TriggerClientEvent('xn_pingjob:updateJobData', dutySources[i], jobName, tableDs[jobName])
        end
    end
end

-- Push cập nhật danh sách blacklist tới các nhân viên của job đó
local function pushBlacklistUpdate(jobName)
    local count, dutySources = getDutyPlayers(jobName)
    if count > 0 then
        for i = 1, #dutySources do
            TriggerClientEvent('xn_pingjob:refreshBlackList', dutySources[i], jobName)
        end
    end
end

-- Kiểm tra blacklist của người chơi từ RAM cache
local function getPlayerBlacklist(citizenId, jobName)
    if not citizenId then return nil end
    local entry = blacklistCache[citizenId]
    if entry then
        local nowMs = os.time() * 1000
        if entry.time > nowMs then
            if not jobName or entry.job == jobName then
                return entry.time
            end
        else
            blacklistCache[citizenId] = nil
        end
    end
    return nil
end

-- Tách riêng logic callService thành function dùng chung
function callServiceFunction(job, src)
    if not src or src <= 0 then return end
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer or not xPlayer.PlayerData then return end

    -- Chống spam gọi liên tục (Debounce 5 giây)
    local now = os.time()
    if pingCooldowns[src] and (now - pingCooldowns[src]) < 5 then
        exports.qbx_core:Notify(src, "Vui lòng đợi vài giây trước khi gọi lại!", "error")
        return
    end
    pingCooldowns[src] = now

    tableDs[job] = tableDs[job] or {}

    -- Kiểm tra người chơi đã có đơn trong danh sách chưa
    for _, v in ipairs(tableDs[job]) do
        if v.callerId == tonumber(src) then
            exports.qbx_core:Notify(src, "Thôi mà, bạn đã gọi dịch vụ rồi ấy, đợi chút xíu nha", "error")
            return
        end
    end

    local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
    local citizenId = xPlayer.PlayerData.pid or xPlayer.PlayerData.citizenid or "N/A"
    local blacklist = getPlayerBlacklist(citizenId, job)

    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local bucket = GetPlayerRoutingBucket(tostring(src)) or 0

    -- Thêm vào danh sách đơn
    table.insert(tableDs[job], {
        callerId = tonumber(src),
        blacklist = blacklist,
        callerName = playerName,
        citizenId = citizenId,
        bucket = bucket,
        accepterId = -1,
        accepterName = 'Chưa Nhận',
        coords = coords,
        lastTime = now
    })

    local count, dutyPlayers = getDutyPlayers(job)
    local textlabel = job == 'mechanic' and 'menumechanic' or job == 'police' and 'menupolice' or job == 'taxi' and 'menutaxi' or 'menumed'

    for i = 1, #dutyPlayers do
        local targetSrc = dutyPlayers[i]
        exports.qbx_core:Notify(targetSrc, "Người chơi " .. playerName .. " đang cần sự trợ giúp kìa các bạn ơi", "info")
        TriggerClientEvent('chat:addMessage', targetSrc, {
            template = string.format(
                '<div class="chat-message %s"><i class="fas fa-%s"></i> <b><span style="color: rgb(255, 167, 84)">[ĐƠN HÀNG] NGƯỜI DÂN CẦN GIÚP:</span></b><div style="margin-top: 5px; font-weight: 300;">- Người chơi %s vừa gọi đơn %s : <b>/%s</b><br>- Để kiểm tra các đơn người dân yêu cầu</div></div>',
                job == 'mechanic' and 'mechanic' or job == 'police' and 'police' or job == 'taxi' and 'taxi' or 'ambulance',
                job == 'mechanic' and 'car-crash' or job == 'police' and 'question' or job == 'taxi' and 'taxi' or 'ambulance',
                playerName, Info_Job[job] or job, textlabel
            ),
            args = {}
        })
        TriggerClientEvent('xn_pingjob:pingSound', targetSrc)
    end

    logEvent('green', xPlayer, 'xn_pingjob | GỌI DỊCH VỤ', string.format("Người chơi %s vừa gọi dịch vụ %s", playerName, Info_Job[job] or job))
    
    -- Push dữ liệu chỉ cho các nhân viên on-duty của job này
    pushJobDataToDuty(job)
end

-- Command goibacsi
lib.addCommand('goibacsi', {
    help = 'Gọi bác sĩ khi bạn chết',
    restricted = false
}, function(source)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then return end

    -- Kiểm tra trạng thái chết
    if not (xPlayer.PlayerData.metadata.inlaststand or xPlayer.PlayerData.metadata.isdead) then
        return exports.qbx_core:Notify(src, 'Bạn chưa chết', 'success')
    end

    local playerState = Player(src).state 
    if playerState and playerState.inPvP then 
        return exports.qbx_core:Notify(src, 'Bạn đang ở trong PvP', 'success')
    end
    
    -- Kiểm tra số lượng bác sĩ online
    local doctorCount = getDutyPlayers('ambulance')
    if doctorCount == 0 then
        local price = 2500
        local price2 = 2250
        if xPlayer.Functions.RemoveMoney then
            local removed = xPlayer.Functions.RemoveMoney('cash', price)
            if removed then
                exports['Renewed-Banking']:addAccountMoney('ambulance', price2)
                exports.qbx_core:Notify(src, 'Bạn đã bị trừ $' .. price .. ' để tự động hồi sinh!', 'error')
            else
                exports.qbx_core:Notify(src, 'Bạn không đủ tiền để tự động hồi sinh!', 'error')
                return
            end
        else
            if xPlayer.PlayerData.money.cash >= price then
                xPlayer.PlayerData.money.cash = xPlayer.PlayerData.money.cash - price
                exports.qbx_core:Notify(src, 'Bạn đã bị trừ $' .. price .. ' để tự động hồi sinh!', 'error')
            else
                exports.qbx_core:Notify(src, 'Bạn không đủ tiền để tự động hồi sinh!', 'error')
                return
            end
        end
        exports.qbx_core:Notify(src, 'Không có bác sĩ nào online, tự động hồi sinh...', 'info')
        TriggerClientEvent('hospital:client:RevivePlayertwo', src)
        return
    end
    
    callServiceFunction("ambulance", src)
end)

-- Command goitaxi
lib.addCommand('goitaxi', {
    help = 'Gọi taxi',
    restricted = false
}, function(source)
    local src = source
    local taxiCount = getDutyPlayers('taxi')
    if taxiCount == 0 then
        exports.qbx_core:Notify(src, 'Không có taxi nào online, hãy thuê xe!', 'error')
        return
    end
    callServiceFunction("taxi", src)
end)

-- Command 911
lib.addCommand('911', {
    help = 'Gọi bác sĩ',
    restricted = false
}, function(source)
    local src = source
    local playerState = Player(src).state 
    if playerState and playerState.inPvP then 
        return exports.qbx_core:Notify(src, 'Bạn đang ở trong PvP', 'success')
    end
    
    local docCount = getDutyPlayers('ambulance')
    if docCount == 0 then
        exports.qbx_core:Notify(src, 'Không có bác sĩ nào online!', 'error')
        return
    end
    callServiceFunction("ambulance", src)
end)

-- Command 113
lib.addCommand('113', {
    help = 'Gọi công an',
    restricted = false
}, function(source)
    local src = source
    local policeCount = getDutyPlayers('police')
    if policeCount == 0 then
        exports.qbx_core:Notify(src, 'Không có cảnh sát nào online!', 'error')
        return
    end
    callServiceFunction("police", src)
end)

-- RegisterNetEvent cho việc gọi bác sĩ từ module khác (qbx_medical)
RegisterNetEvent('xn_pingjob:callAmbulance', function(playerId)
    local src = playerId or source
    callServiceFunction("ambulance", src)
end)

-- Event handler cho client gọi
RegisterNetEvent('xn_pingjob:callService', function(job)
    callServiceFunction(job, source)
end)

-- Lấy danh sách cuộc gọi cho 1 job (chỉ gửi khi client mở menu hoặc đổi job)
lib.callback.register('xn_pingjob:getData', function(source)
    local xPlayer = exports.qbx_core:GetPlayer(source)
    if not xPlayer or not xPlayer.PlayerData or not xPlayer.PlayerData.job then
        return {}
    end
    local jobName = xPlayer.PlayerData.job.name
    tableDs[jobName] = tableDs[jobName] or {}
    for i = 1, #tableDs[jobName] do
        local callerId = tableDs[jobName][i].callerId
        if callerId then
            tableDs[jobName][i].bucket = GetPlayerRoutingBucket(tostring(callerId)) or tableDs[jobName][i].bucket or 0
        end
    end
    return tableDs[jobName]
end)

lib.callback.register('xn_pingjob:getPlayerName', function(source, id)
    local xPlayer = exports.qbx_core:GetPlayer(id)
    if xPlayer ~= nil then
        return xPlayer
    else
        local result = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', { tostring(id) })
        if result and result[1] ~= nil then
            return result[1]
        end
    end
    return false
end)

lib.callback.register('xn_pingjob:newBlacklist', function(source, identifier, name, time, reason)
    local xPlayer = exports.qbx_core:GetPlayer(source)
    if not xPlayer then return false end
    local jobName = xPlayer.PlayerData.job.name
    if not Config.JobAllow[jobName] then return false end

    local expiryTime = tonumber(time) or 0
    if (os.time() * 1000) >= expiryTime then
        return false
    end

    local blacklisterName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname

    -- Lưu vào memory cache ngay lập tức
    blacklistCache[identifier] = {
        time = expiryTime,
        reason = reason,
        name = name,
        blacklister = blacklisterName,
        job = jobName
    }

    MySQL.Async.execute('INSERT INTO 1307_blacklist (identifier, time, reason, name, blacklister, job) VALUES (@identifier, @time, @reason, @name, @blacklister, @job) ON DUPLICATE KEY UPDATE time = @time, reason = @reason, blacklister = @blacklister',
    {
        ['@identifier'] = identifier,
        ['@time'] = expiryTime,
        ['@reason'] = reason,
        ['@name'] = name,
        ['@blacklister'] = blacklisterName,
        ['@job'] = jobName
    })

    pushBlacklistUpdate(jobName)
    return true
end)

RegisterNetEvent('xn_pingjob:acceptService', function(id)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then return end
    local jobName = xPlayer.PlayerData.job.name
    local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname

    tableDs[jobName] = tableDs[jobName] or {}
    for _, v in pairs(tableDs[jobName]) do 
        if v.callerId == id then
            v.accepterName = playerName
            v.accepterId = tonumber(src)

            TriggerClientEvent("QBCore:Notify", tonumber(v.callerId), (Info_Job[jobName] or jobName) .. " " .. playerName .. " vừa nhận đơn của bạn", 'success', 60000)
            
            local targetPed = GetPlayerPed(v.callerId)
            if DoesEntityExist(targetPed) then
                v.coords = GetEntityCoords(targetPed)
                v.bucket = GetPlayerRoutingBucket(tostring(v.callerId)) or 0
            end

            -- Gửi vị trí cho người nhận đơn
            TriggerClientEvent('xn_pingjob:setWaypoint', src, v.coords, v.callerName, v.callerId, v.bucket)

            logEvent('orange', xPlayer, 'xn_pingjob | CHẤP NHẬN DỊCH VỤ', 
                string.format("Người chơi %s vừa nhận đơn của Momo %s", playerName, tonumber(v.callerId)))
            
            pushJobDataToDuty(jobName)
            return
        end
    end
end)

RegisterNetEvent('xn_pingjob:cancelService', function(id)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then return end
    local jobName = xPlayer.PlayerData.job.name 
    local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname

    tableDs[jobName] = tableDs[jobName] or {}
    for _, v in pairs(tableDs[jobName]) do
        if tonumber(v.callerId) == id then
            v.accepterId = -1
            v.accepterName = 'Chưa nhận'

            local count, dutySources = getDutyPlayers(jobName)
            for i = 1, #dutySources do
                TriggerClientEvent("QBCore:Notify", dutySources[i], string.format("%s %s vừa hủy nhận đơn của %s", Info_Job[jobName] or jobName, playerName, v.callerName), 'info')
            end

            logEvent('red', xPlayer, 'xn_pingjob | HỦY ĐƠN NGƯỜI KHÁC', 
                string.format("Người chơi %s vừa hủy đơn của Momo %s", playerName, tonumber(v.callerId)))
            
            TriggerClientEvent("QBCore:Notify", tonumber(v.callerId), string.format("%s %s vừa hủy nhận đơn của bạn", Info_Job[jobName] or jobName, playerName), 'info')
            
            pushJobDataToDuty(jobName)
            return
        end
    end
end)

RegisterNetEvent('xn_pingjob:deleteService', function(id)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then return end
    local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
    local jobName = xPlayer.PlayerData.job.name

    tableDs[jobName] = tableDs[jobName] or {}
    for k, v in pairs(tableDs[jobName]) do
        if tonumber(v.callerId) == id then
            local callerName = v.callerName
            local callerId = v.callerId
            table.remove(tableDs[jobName], k)

            local count, dutySources = getDutyPlayers(jobName)
            for i = 1, #dutySources do
                TriggerClientEvent("QBCore:Notify", dutySources[i], (Info_Job[jobName] or jobName) .. " " .. playerName .. " vừa xóa đơn của " .. callerName, 'info')
            end

            TriggerClientEvent("QBCore:Notify", tonumber(callerId), (Info_Job[jobName] or jobName) .. " " .. playerName .. " vừa xóa đơn của bạn", 'info')
            
            pushJobDataToDuty(jobName)
            return
        end
    end
end)

RegisterNetEvent('xn_pingjob:resetPlayerBucket', function(targetId)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer or not xPlayer.PlayerData or not xPlayer.PlayerData.job then return end
    if not xPlayer.PlayerData.job.onduty then return end
    local jobName = xPlayer.PlayerData.job.name

    targetId = tonumber(targetId)
    if not targetId then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        return exports.qbx_core:Notify(src, "Người chơi không online hoặc không tồn tại!", "error")
    end

    local currentBucket = GetPlayerRoutingBucket(tostring(targetId)) or 0
    if currentBucket == 0 then
        exports.qbx_core:Notify(src, "Người chơi đã ở Bucket 0 rồi!", "info")
    else
        SetPlayerRoutingBucket(tostring(targetId), 0)
        local targetName = targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname
        local staffName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
        exports.qbx_core:Notify(src, string.format("Đã đưa %s từ Bucket %s về Bucket 0!", targetName, currentBucket), "success")
        exports.qbx_core:Notify(targetId, string.format("Bạn đã được nhân viên %s đưa về không gian chính (Bucket 0)!", staffName), "info")
    end

    -- Cập nhật lại bucket trong bảng tableDs
    if tableDs[jobName] then
        for _, v in ipairs(tableDs[jobName]) do
            if v.callerId == targetId then
                v.bucket = 0
            end
        end
        pushJobDataToDuty(jobName)
    end
end)

-- Callback lấy tọa độ thời gian thực (live coords) mới nhất của người chơi
lib.callback.register('xn_pingjob:getLivePlayerCoords', function(source, targetId)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer or not xPlayer.PlayerData or not xPlayer.PlayerData.job then return nil end
    local jobName = xPlayer.PlayerData.job.name
    
    targetId = tonumber(targetId)
    if not targetId then return nil end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        if tableDs[jobName] then
            for _, v in ipairs(tableDs[jobName]) do
                if v.callerId == targetId then
                    return {
                        success = true,
                        isLive = false,
                        coords = v.coords,
                        bucket = v.bucket or 0,
                        name = v.callerName
                    }
                end
            end
        end
        return nil
    end

    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then return nil end

    local liveCoords = GetEntityCoords(targetPed)
    local liveBucket = GetPlayerRoutingBucket(tostring(targetId)) or 0
    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname

    -- Đồng bộ lại tọa độ mới nhất vào tableDs
    if tableDs[jobName] then
        for _, v in ipairs(tableDs[jobName]) do
            if v.callerId == targetId then
                v.coords = liveCoords
                v.bucket = liveBucket
                break
            end
        end
    end

    return {
        success = true,
        isLive = true,
        coords = liveCoords,
        bucket = liveBucket,
        name = targetName
    }
end)

-- Event kéo xác người chơi về sát vị trí bác sĩ
RegisterNetEvent('xn_pingjob:pullPlayerBody', function(targetId)
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer or not xPlayer.PlayerData or not xPlayer.PlayerData.job then return end
    if not xPlayer.PlayerData.job.onduty then 
        return exports.qbx_core:Notify(src, "Bạn cần On-Duty để thực hiện thao tác này!", "error")
    end
    local jobName = xPlayer.PlayerData.job.name

    targetId = tonumber(targetId)
    if not targetId then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        return exports.qbx_core:Notify(src, "Người chơi không online hoặc không tồn tại!", "error")
    end

    local docPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(docPed) or not DoesEntityExist(targetPed) then return end

    local docCoords = GetEntityCoords(docPed)
    local targetCoords = GetEntityCoords(targetPed)
    local dist = #(docCoords - targetCoords)

    -- Trong bán kính 150m (phòng trường hợp người chơi rơi sâu dưới lòng đất)
    if dist > 150.0 then
        return exports.qbx_core:Notify(src, "Bạn đang ở quá xa vị trí người chơi (cần trong bán kính 150m)!", "error")
    end

    local docBucket = GetPlayerRoutingBucket(tostring(src)) or 0
    local targetBucket = GetPlayerRoutingBucket(tostring(targetId)) or 0

    if targetBucket ~= docBucket then
        SetPlayerRoutingBucket(tostring(targetId), docBucket)
    end

    local pullCoords = vector3(docCoords.x + 0.6, docCoords.y + 0.6, docCoords.z + 0.1)

    SetEntityCoords(targetPed, pullCoords.x, pullCoords.y, pullCoords.z, false, false, false, true)
    TriggerClientEvent('xn_pingjob:pulledToCoords', targetId, pullCoords)

    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    local staffName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname

    exports.qbx_core:Notify(src, string.format("Đã kéo người chơi %s lại gần bạn thành công!", targetName), "success")
    exports.qbx_core:Notify(targetId, string.format("Bạn đã được %s kéo lại gần!", staffName), "info")

    if tableDs[jobName] then
        for _, v in ipairs(tableDs[jobName]) do
            if v.callerId == targetId then
                v.coords = pullCoords
                v.bucket = docBucket
            end
        end
        pushJobDataToDuty(jobName)
    end
end)

lib.callback.register('xn_pingjob:editBlacklist', function(source, identifier, time, reason)
    local expiryTime = tonumber(time) or 0
    if (os.time() * 1000) >= expiryTime then
        return false
    end
    local xPlayer = exports.qbx_core:GetPlayer(source)
    if not xPlayer then return false end
    local jobName = xPlayer.PlayerData.job.name

    if blacklistCache[identifier] then
        blacklistCache[identifier].time = expiryTime
        blacklistCache[identifier].reason = reason
    end

    MySQL.Async.execute('UPDATE 1307_blacklist SET `time` = @time, `reason` = @reason WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@time'] = expiryTime,
        ['@reason'] = reason
    })

    pushBlacklistUpdate(jobName)
    return true
end)

lib.callback.register('xn_pingjob:deleteBlacklist', function(source, identifier)
    local xPlayer = exports.qbx_core:GetPlayer(source)
    if not xPlayer then return false end
    local jobName = xPlayer.PlayerData.job.name

    blacklistCache[identifier] = nil

    MySQL.Async.execute('DELETE FROM 1307_blacklist WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })

    pushBlacklistUpdate(jobName)
    return true
end)

lib.callback.register('xn_pingjob:getBlacklist', function(source)
    local xPlayer = exports.qbx_core:GetPlayer(source)
    if not xPlayer or not xPlayer.PlayerData or not xPlayer.PlayerData.job then return {} end
    return MySQL.query.await('SELECT * FROM 1307_blacklist WHERE job = ?', {
        xPlayer.PlayerData.job.name
    }) or {}
end)

-- Tự động dọn dẹp khi người chơi thoát game (playerDropped)
AddEventHandler('playerDropped', function()
    local src = source
    pingCooldowns[src] = nil

    for jobName, list in pairs(tableDs) do
        local changed = false
        for i = #list, 1, -1 do
            local item = list[i]
            if item.callerId == src then
                table.remove(list, i)
                changed = true
            elseif item.accepterId == src then
                item.accepterId = -1
                item.accepterName = 'Chưa Nhận'
                changed = true
            end
        end
        if changed then
            pushJobDataToDuty(jobName)
        end
    end
end)

-- Hàm / Export / Event dọn đơn của người chơi khi được hồi sinh
local function removePlayerCall(src, job)
    if not src then return end
    local targetJobs = job and { job } or { 'ambulance', 'police', 'taxi', 'mechanic' }
    for _, jobName in ipairs(targetJobs) do
        if tableDs[jobName] then
            local changed = false
            for i = #tableDs[jobName], 1, -1 do
                if tableDs[jobName][i].callerId == src then
                    table.remove(tableDs[jobName], i)
                    changed = true
                end
            end
            if changed then
                pushJobDataToDuty(jobName)
            end
        end
    end
end

exports('removePlayerCall', removePlayerCall)
RegisterNetEvent('xn_pingjob:removePlayerCall', removePlayerCall)

-- Lắng nghe event hồi sinh từ qbx_medical để tự động xóa đơn cứu thương
RegisterNetEvent('qbx_medical:server:playerRevived', function()
    local src = source
    removePlayerCall(src, 'ambulance')
end)

-- Định kỳ 1 tiếng kiểm tra dọn blacklist hết hạn từ DB và RAM
function Tick()
    SetTimeout(3600000, function()
        LoadBlacklistCache()
        Tick()
    end)
end

Tick()