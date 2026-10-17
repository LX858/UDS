-- MINI MDT Server Main
local QBCore = exports['qb-core']:GetCoreObject()
local QBX = nil

-- Try to load QBX if available
if GetResourceState('qbx_core') == 'started' or GetResourceState('qbx_core') == 'starting' then
    QBX = exports.qbx_core
end

-- Global data storage
Records = {}
Offenders = {}
Fines = {}
PatrolStates = {}

-- Officers registry (EVENT-DRIVEN - không cần loop players)
OnlineOfficers = {}

-- Helper function to get player
local function GetPlayer(source)
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
local function GetPlayerFullName(Player)
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
local function GetPlayerGradeName(Player)
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

-- Helper function to get player
local function GetQBPlayers()
    if Config.Framework == 'qbx' and QBX then
        return QBX:GetQBPlayers()
    else
        return QBCore.Functions.GetQBPlayers()
    end
end

-- Helper function to get player by citizenid
local function GetPlayerByCitizenId(citizenid)
    if Config.Framework == 'qbx' and QBX then
        return QBX:GetPlayerByCitizenId(citizenid)
    else
        return QBCore.Functions.GetPlayerByCitizenId(citizenid)
    end
end

-- Helper function to get player job
local function HasPoliceJob(source)
    local Player = GetPlayer(source)
    if not Player then return false end
    return Config.AllowedJobs[Player.PlayerData.job.name] == true
end

-- Helper function to get player name
local function GetPlayerName(citizenid)
    local result = MySQL.query.await('SELECT CONCAT(JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.firstname")), " ", JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.lastname"))) as name FROM ' .. Config.PlayersTable .. ' WHERE citizenid = ?', {citizenid})
    if result and result[1] then
        return result[1].name
    end
    return "Unknown"
end

-- Load all data on resource start
CreateThread(function()
    -- Create patrol logs table if it doesn't exist
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mini_mdt_patrol_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `area_name` VARCHAR(255) NOT NULL,
            `officer_name` VARCHAR(255) NOT NULL,
            `officer_callsign` VARCHAR(50) DEFAULT 'N/A',
            `officer_rank` VARCHAR(100) DEFAULT 'Officer',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_area_name` (`area_name`),
            INDEX `idx_created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Clean up logs older than 7 days
    MySQL.query.await('DELETE FROM mini_mdt_patrol_logs WHERE created_at < NOW() - INTERVAL 7 DAY')

    -- Initialize PatrolStates
    for _, point in ipairs(Config.PatrolPoints) do
        PatrolStates[point.id] = {
            lastPatrolled = 0,
            officerName = "",
            officerRank = "",
            officerCallsign = ""
        }
        
        -- Load the latest log for this point
        local latest = MySQL.query.await('SELECT *, UNIX_TIMESTAMP(created_at) as unix_time FROM mini_mdt_patrol_logs WHERE area_name = ? ORDER BY created_at DESC LIMIT 1', {point.name})
        if latest and latest[1] then
            local unixTime = latest[1].unix_time
            local cooldownSec = (point.cooldown or 15) * 60
            if os.time() - unixTime < cooldownSec then
                PatrolStates[point.id] = {
                    lastPatrolled = unixTime,
                    officerName = latest[1].officer_name,
                    officerRank = latest[1].officer_rank,
                    officerCallsign = latest[1].officer_callsign
                }
            end
        end
    end

    -- Populate OnlineOfficers khi resource start
    local Players = GetQBPlayers()
    for k, v in pairs(Players) do
        local src = v.PlayerData.source
        local job = v.PlayerData.job
        
        if Config.AllowedJobs[job.name] and job.onduty then
            OnlineOfficers[src] = {
                source = src,
                playerId = src,
                citizenid = v.PlayerData.citizenid,
                name = GetPlayerFullName(v),
                rank = GetPlayerGradeName(v),
                onduty = true
            }
        end
    end
    
    -- Load records
    local recordsResult = MySQL.query.await('SELECT * FROM mini_mdt_records ORDER BY created_date DESC', {})
    if recordsResult then
        for i = 1, #recordsResult do
            Records[recordsResult[i].id] = recordsResult[i]
        end
    end
    
    -- Load offenders
    local offendersResult = MySQL.query.await('SELECT * FROM mini_mdt_offenders', {})
    if offendersResult then
        for i = 1, #offendersResult do
            if not Offenders[offendersResult[i].record_id] then
                Offenders[offendersResult[i].record_id] = {}
            end
            table.insert(Offenders[offendersResult[i].record_id], offendersResult[i])
        end
    end
    
    -- Load fines
    local finesResult = MySQL.query.await('SELECT * FROM mini_mdt_fines', {})
    if finesResult then
        for i = 1, #finesResult do
            if not Fines[finesResult[i].record_id] then
                Fines[finesResult[i].record_id] = {}
            end
            table.insert(Fines[finesResult[i].record_id], finesResult[i])
        end
    end
end)

-- Send Discord Webhook
function SendDiscordLog(data)
    if not Config.EnableDiscordLogs then return end
    
    local discordWebhook = 'https://discord.com/api/webhooks/1466755498220191794/HD2r0WTMEEHtRG334pmI0TtZaDyYKIlBHCidNzFC7YyuZPktY0JsYtXdEOtRYFBohO-Y'
    if not discordWebhook or discordWebhook == '' then
        return
    end
    
    -- Format officers list
    local officersText = ''
    if data.officers and #data.officers > 0 then
        for i, officer in ipairs(data.officers) do
            officersText = officersText .. string.format('• **%s** - %s\n', officer.name, officer.rank)
        end
    else
        officersText = '_Không có cảnh sát tham gia_'
    end
    
    -- Format offenders list
    local offendersText = ''
    if data.offenders and #data.offenders > 0 then
        for i, offender in ipairs(data.offenders) do
            offendersText = offendersText .. string.format('• **%s** (Player ID: `%s`)\n', 
                offender.name, offender.playerId or offender.pid or 'N/A')
        end
    end
    
    -- Format charges list
    local chargesText = ''
    if data.charges and #data.charges > 0 then
        for i, charge in ipairs(data.charges) do
            chargesText = chargesText .. string.format('• **%s**\n  ├ Tiền phạt: $%s\n  └ Thời gian tù: %s bãi\n', 
                charge.name, 
                charge.selectedFine or charge.fine or 0, 
                charge.selectedJail or charge.jail or 0)
        end
    end
    
    local embed = {
        {
            ['title'] = '⚖️ KẾT ÁN MỚI',
            ['color'] = 3447003, -- Blue color
            ['fields'] = {
                {
                    ['name'] = '👮 Người Xử Lý',
                    ['value'] = string.format('**%s**\nChức vụ: `%s`', data.handler.name, data.handler.rank),
                    ['inline'] = false
                },
                {
                    ['name'] = '👥 Cảnh Sát Tham Gia',
                    ['value'] = officersText,
                    ['inline'] = false
                },
                {
                    ['name'] = '🎯 Tội Phạm',
                    ['value'] = offendersText,
                    ['inline'] = false
                },
                {
                    ['name'] = '⚖️ Các Tội Danh',
                    ['value'] = chargesText,
                    ['inline'] = false
                },
                {
                    ['name'] = '💰 Tổng Mức Án',
                    ['value'] = string.format('**💵 Tiền phạt:** $%s\n**🔒 Thời gian tù:** %s bãi', 
                        data.totalFine or 0, data.totalJail or 0),
                    ['inline'] = false
                }
            },
            ['footer'] = {
                ['text'] = 'UNDER STAR MDT System • ' .. os.date('%d/%m/%Y %H:%M:%S'),
                ['icon_url'] = Config.DiscordBotAvatar
            },
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%S')
        }
    }
    
    PerformHttpRequest(discordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = Config.DiscordBotName,
        avatar_url = Config.DiscordBotAvatar,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Send prison log to Discord
local function SendPrisonLog(action, officerData, prisonerData, reason)
    if not Config.EnableDiscordLogs then return end
    
    local prisonWebhook = 'https://discord.com/api/webhooks/1467240482852573225/mEhTgSijMC5TZ_iN8FLQmscGkgKm-of9DUhmuYjTorYfSkz8jHC3nwR-t18E2hM_okrU'
    if not prisonWebhook or prisonWebhook == '' then
        return
    end
    
    local color = action == 'JAIL' and 16711680 or 65280 -- Red for jail, Green for release
    local title = action == 'JAIL' and '🔒 PHẠT TẠM GIAM' or '🔓 THẢ TẠM GIAM'
    
    local embed = {
        {
            ['title'] = title,
            ['color'] = color,
            ['fields'] = {
                {
                    ['name'] = '👮 Cảnh Sát Xử Lý',
                    ['value'] = string.format('%s - `%s` - %s', 
                        officerData.name or 'N/A',
                        officerData.playerId or officerData.pid or 'N/A',
                        officerData.rank or 'N/A'
                    ),
                    ['inline'] = false
                },
                {
                    ['name'] = '🎯 Người Tạm Giam',
                    ['value'] = string.format('%s - `%s`', 
                        prisonerData.name or 'N/A',
                        prisonerData.playerId or prisonerData.pid or 'N/A'
                    ),
                    ['inline'] = false
                },
                {
                    ['name'] = '📋 Lý Do',
                    ['value'] = reason or 'Không có lý do',
                    ['inline'] = false
                }
            },
            ['footer'] = {
                ['text'] = os.date('%d/%m/%Y %H:%M:%S'),
            },
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%S')
        }
    }
    
    PerformHttpRequest(prisonWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = 'Prison System',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Event: Log phạt tù
RegisterNetEvent('mini-mdt:server:logPrison', function(src, prisonerData, officerData, reason)
    SendPrisonLog('JAIL', officerData, prisonerData, reason)
end)

-- Event: Log thả tù
RegisterNetEvent('mini-mdt:server:logRelease', function(src, prisonerData, officerData, reason)
    SendPrisonLog('RELEASE', officerData, prisonerData, reason or 'Hết thời gian tạm giam')
end)


-- Event-driven officers registry
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(src)
    local Player = GetPlayer(src)
    if not Player then return end
    
    local job = Player.PlayerData.job
    
    if Config.AllowedJobs[job.name] and job.onduty then
        OnlineOfficers[src] = {
            source = src,
            playerId = src,
            citizenid = Player.PlayerData.citizenid,
            name = GetPlayerFullName(Player),
            rank = GetPlayerGradeName(Player),
            onduty = true
        }
    end
end)

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, job)
    if Config.AllowedJobs[job.name] and job.onduty then
        local Player = GetPlayer(source)
        if Player then
            OnlineOfficers[source] = {
                source = source,
                playerId = source,
                citizenid = Player.PlayerData.citizenid,
                name = GetPlayerFullName(Player),
                rank = GetPlayerGradeName(Player),
                onduty = true
            }
        end
    else
        OnlineOfficers[source] = nil
    end
end)

RegisterNetEvent('QBCore:Server:SetDuty', function(source, onDuty)
    local Player = GetPlayer(source)
    if not Player then return end
    
    if Config.AllowedJobs[Player.PlayerData.job.name] and onDuty then
        OnlineOfficers[source] = {
            source = source,
            playerId = source,
            citizenid = Player.PlayerData.citizenid,
            name = GetPlayerFullName(Player),
            rank = GetPlayerGradeName(Player),
            onduty = true
        }
    else
        OnlineOfficers[source] = nil
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    OnlineOfficers[src] = nil
end)

-- Send notification
local function SendNotify(source, title, message, type)
    TriggerClientEvent('QBCore:Notify', source, message, type)
end

-- ==================== Citizens Management ====================
lib.callback.register('mini-mdt:server:issueCitizenID', function(source, targetPlayerId)
    local OfficerPlayer = GetPlayer(source)
    if not OfficerPlayer then return {success = false, message = 'Không tìm thấy người xử lý'} end
    
    -- Check if officer has police job
    if not HasPoliceJob(source) then
        return {success = false, message = 'Bạn không có quyền thực hiện hành động này'}
    end
    
    -- Get target player
    local TargetPlayer = nil
    targetPlayerId = tonumber(targetPlayerId)
    if targetPlayerId then
        TargetPlayer = GetPlayer(targetPlayerId)
    end
    
    if not TargetPlayer then
        return {success = false, message = 'Không tìm thấy người chơi với Player ID: ' .. tostring(targetPlayerId)}
    end
    
    local targetSource = TargetPlayer.PlayerData.source
    
    -- Check distance between officer and target
    local officerCoords = GetEntityCoords(GetPlayerPed(source))
    local targetCoords = GetEntityCoords(GetPlayerPed(targetSource))
    local distance = #(officerCoords - targetCoords)
    
    if distance > 5.0 then
        return {success = false, message = 'Không có cư dân đó ở đây!'}
    end
    
    -- Check if target has enough money
    local targetMoney = TargetPlayer.PlayerData.money.cash or 0
    if targetMoney < Config.IDCardPrice then
        return {success = false, message = 'Người chơi không đủ tiền! (Cần: $' .. Config.IDCardPrice .. ', Có: $' .. targetMoney .. ')'}
    end
    
    -- Remove money from target
    TargetPlayer.Functions.RemoveMoney('cash', Config.IDCardPrice, 'idcard-issue')
    
    -- Give ID card to target using qbx_idcard export
    local success = pcall(function()
        exports['qbx_idcard']:CreateMetaLicense(targetSource, 'id_card')
    end)
    
    if success then
        -- Notify target
        TriggerClientEvent('QBCore:Notify', targetSource, 'Bạn đã được cấp CCCD! Phí: $' .. Config.IDCardPrice, 'success')
        
        -- Notify officer
        SendNotify(source, 'Thành công', 'Đã cấp CCCD cho ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname, 'success')
        
        return {
            success = true, 
            message = 'Đã cấp CCCD thành công cho ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
        }
    else
        -- Refund money if failed
        TargetPlayer.Functions.AddMoney('cash', Config.IDCardPrice, 'idcard-issue-refund')
        return {success = false, message = 'Lỗi khi cấp CCCD. Vui lòng thử lại!'}
    end
end)

-- Export functions
exports('HasPoliceJob', HasPoliceJob)
exports('GetPlayerName', GetPlayerName)

-- ==================== PERSONAL COOLDOWN SYSTEM (SERVER) ====================
local PersonalCooldowns = {}

local function SetPlayerCooldownServer(targetSrc, minutes, reason)
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return false, "Invalid target ID" end
    
    local TargetPlayer = GetPlayer(targetSrc)
    if not TargetPlayer then return false, "Player not found" end
    
    local mins = tonumber(minutes) or (Config.PersonalCooldown and Config.PersonalCooldown.DefaultDuration) or 30
    local citizenid = TargetPlayer.PlayerData.citizenid
    local expireTime = os.time() + math.floor(mins * 60)
    
    PersonalCooldowns[citizenid] = {
        expireTime = expireTime,
        reason = reason or "Vi phạm"
    }
    
    TriggerClientEvent('mini-mdt:client:setCooldown', targetSrc, mins, reason)
    return true
end

local function ClearPlayerCooldownServer(targetSrc)
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return false, "Invalid target ID" end
    
    local TargetPlayer = GetPlayer(targetSrc)
    if not TargetPlayer then return false, "Player not found" end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    PersonalCooldowns[citizenid] = nil
    
    TriggerClientEvent('mini-mdt:client:clearCooldown', targetSrc)
    return true
end

local function GetPlayerCooldownServer(targetSrc)
    targetSrc = tonumber(targetSrc)
    if not targetSrc then return 0 end
    
    local TargetPlayer = GetPlayer(targetSrc)
    if not TargetPlayer then return 0 end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    local data = PersonalCooldowns[citizenid]
    if not data then return 0 end
    
    local remaining = data.expireTime - os.time()
    if remaining <= 0 then
        PersonalCooldowns[citizenid] = nil
        return 0
    end
    return remaining
end

local function HasPlayerCooldownServer(targetSrc)
    return GetPlayerCooldownServer(targetSrc) > 0
end

-- Server Exports
exports('SetPlayerCooldown', SetPlayerCooldownServer)
exports('ClearPlayerCooldown', ClearPlayerCooldownServer)
exports('GetPlayerCooldown', GetPlayerCooldownServer)
exports('HasPlayerCooldown', HasPlayerCooldownServer)

-- Server Events (có thể gọi từ server hoặc client)
RegisterNetEvent('mini-mdt:server:setCooldown', function(targetSrc, minutes, reason)
    local src = source
    local target = targetSrc or src
    SetPlayerCooldownServer(target, minutes, reason)
end)

RegisterNetEvent('mini-mdt:server:clearCooldown', function(targetSrc)
    local src = source
    local target = targetSrc or src
    ClearPlayerCooldownServer(target)
end)

-- Đồng bộ khi Player vào lại Server
local function SyncPlayerCooldownOnJoin(src)
    local Player = GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local data = PersonalCooldowns[citizenid]
    if data then
        local remainingSec = data.expireTime - os.time()
        if remainingSec > 0 then
            local remainingMins = remainingSec / 60
            TriggerClientEvent('mini-mdt:client:setCooldown', src, remainingMins, data.reason)
        else
            PersonalCooldowns[citizenid] = nil
        end
    end
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    if Player and Player.PlayerData and Player.PlayerData.source then
        SyncPlayerCooldownOnJoin(Player.PlayerData.source)
    end
end)

RegisterNetEvent('qbx_core:server:playerLoaded', function(source)
    SyncPlayerCooldownOnJoin(source)
end)

-- ==================== ADMIN TEST COMMANDS ====================
-- /setzonecd [id] [minutes] [reason]
QBCore.Commands.Add('setzonecd', 'Set zone cooldown cho player (Admin Only)', {
    {name = 'id', help = 'Player ID (Bỏ trống = bản thân)'},
    {name = 'minutes', help = 'Số phút cooldown (Mặc định: 30)'},
    {name = 'reason', help = 'Lý do áp dụng cooldown'}
}, false, function(source, args)
    local targetId = tonumber(args[1]) or source
    local minutes = tonumber(args[2]) or (Config.PersonalCooldown and Config.PersonalCooldown.DefaultDuration) or 30
    local reason = (args[3] and table.concat(args, " ", 3)) or "Admin Test"

    if not targetId or targetId <= 0 then
        if source == 0 then
            print("[MINI-MDT] Console usage: /setzonecd [id] [minutes] [reason]")
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player ID không hợp lệ!', 'error')
        end
        return
    end

    local success, err = SetPlayerCooldownServer(targetId, minutes, reason)
    if success then
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, string.format("Đã kích hoạt cooldown %d phút cho Player ID %d (Lý do: %s)", minutes, targetId, reason), 'success')
        else
            print(string.format("[MINI-MDT] Set cooldown %d minutes for Player ID %d (Reason: %s)", minutes, targetId, reason))
        end
    else
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, "Lỗi: " .. tostring(err), 'error')
        else
            print("[MINI-MDT] Error: " .. tostring(err))
        end
    end
end, 'admin')

-- /clearzonecd [id]
QBCore.Commands.Add('clearzonecd', 'Xóa zone cooldown của player (Admin Only)', {
    {name = 'id', help = 'Player ID (Bỏ trống = bản thân)'}
}, false, function(source, args)
    local targetId = tonumber(args[1]) or source
    if not targetId or targetId <= 0 then
        if source == 0 then
            print("[MINI-MDT] Console usage: /clearzonecd [id]")
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player ID không hợp lệ!', 'error')
        end
        return
    end

    local success, err = ClearPlayerCooldownServer(targetId)
    if success then
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, string.format("Đã gỡ bỏ cooldown cho Player ID %d", targetId), 'success')
        else
            print(string.format("[MINI-MDT] Cleared cooldown for Player ID %d", targetId))
        end
    else
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, "Lỗi: " .. tostring(err), 'error')
        else
            print("[MINI-MDT] Error: " .. tostring(err))
        end
    end
end, 'admin')

-- /checkzonecd [id]
QBCore.Commands.Add('checkzonecd', 'Kiểm tra zone cooldown của player (Admin Only)', {
    {name = 'id', help = 'Player ID (Bỏ trống = bản thân)'}
}, false, function(source, args)
    local targetId = tonumber(args[1]) or source
    if not targetId or targetId <= 0 then
        if source == 0 then
            print("[MINI-MDT] Console usage: /checkzonecd [id]")
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player ID không hợp lệ!', 'error')
        end
        return
    end

    local rem = GetPlayerCooldownServer(targetId)
    if rem > 0 then
        local m = math.floor(rem / 60)
        local s = math.floor(rem % 60)
        local msg = string.format("Player ID %d đang bị cooldown: %d phút %d giây", targetId, m, s)
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, msg, 'primary')
        else
            print("[MINI-MDT] " .. msg)
        end
    else
        local msg = string.format("Player ID %d hiện KHÔNG bị cooldown", targetId)
        if source > 0 then
            TriggerClientEvent('QBCore:Notify', source, msg, 'primary')
        else
            print("[MINI-MDT] " .. msg)
        end
    end
end, 'admin')


