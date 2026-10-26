local BansCache = {
    byLicense = {},
    byDiscord = {},
    byIp = {},
    byGmail = {},
    list = {}
}

-- Hàm làm sạch chuỗi identifier (bỏ prefix license:, discord:, ip:)
local function cleanIdentifier(id)
    if not id then return nil end
    local clean = tostring(id):gsub('^license:', ''):gsub('^discord:', ''):gsub('^ip:', '')
    clean = clean:match('^%s*(.-)%s*$') -- trim whitespace
    return clean ~= '' and clean:lower() or nil
end

-- Hàm tạo Ban ID ngẫu nhiên định dạng [XXXX-YYYY] như txAdmin
local function generateBanId()
    local chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local part1, part2 = '', ''
    for i = 1, 4 do
        local rand = math.random(1, #chars)
        part1 = part1 .. chars:sub(rand, rand)
    end
    for i = 1, 4 do
        local rand = math.random(1, #chars)
        part2 = part2 .. chars:sub(rand, rand)
    end
    return string.format('%s-%s', part1, part2)
end

-- Gửi Webhook Discord
local function sendDiscordLog(title, description, color, fields)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' then return end
    local embed = {
        {
            ['title'] = title,
            ['description'] = description,
            ['type'] = 'rich',
            ['color'] = color or 15158332,
            ['fields'] = fields or {},
            ['footer'] = {
                ['text'] = 'XN Ban System • ' .. os.date('%d/%m/%Y %H:%M:%S')
            }
        }
    }
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({
        username = Config.BotName,
        avatar_url = Config.BotAvatar,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Tải toàn bộ danh sách Ban còn hiệu lực vào Cache
local function loadBansCache()
    BansCache = {
        byLicense = {},
        byDiscord = {},
        byIp = {},
        byGmail = {},
        list = {}
    }

    local query = [[
        SELECT 
            id, ban_id, name, license, discord, gmail, ip, reason, banned_by,
            COALESCE(DATE_FORMAT(banned_at, '%d/%m/%Y %H:%i:%s'), '') AS banned_at,
            COALESCE(DATE_FORMAT(expire_at, '%d/%m/%Y %H:%i:%s'), 'Vĩnh viễn') AS expire_at,
            status
        FROM `xn_bans` 
        WHERE `status` = 1 
        AND (`expire_at` IS NULL OR `expire_at` > NOW())
    ]]
    local results = MySQL.query.await(query, {})
    if results then
        for _, ban in ipairs(results) do
            BansCache.list[ban.ban_id] = ban

            local lic = cleanIdentifier(ban.license)
            if lic then BansCache.byLicense[lic] = ban end

            local disc = cleanIdentifier(ban.discord)
            if disc then BansCache.byDiscord[disc] = ban end

            local ip = cleanIdentifier(ban.ip)
            if ip then BansCache.byIp[ip] = ban end

            local mail = cleanIdentifier(ban.gmail)
            if mail then BansCache.byGmail[mail] = ban end
        end
    end
    print(string.format('^2[xn_ban]^7 Da tai thanh cong %d ban vao bo nho dem!', results and #results or 0))
end

-- Khởi động tải Cache
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    loadBansCache()
end)

-- Kiểm tra quyền Admin (Qbox/QB-Core/ACE)
local function hasAdminPermission(src)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, Config.AdminAce) or IsPlayerAceAllowed(src, 'command') then
        return true
    end

    -- Kiểm tra qua exports qbx_core / qb-core nếu có
    if exports['qbx_core'] and exports['qbx_core'].HasPermission then
        for group in pairs(Config.AdminGroups) do
            if exports['qbx_core']:HasPermission(src, group) then
                return true
            end
        end
    end

    local QBCore = GetResourceState('qb-core') == 'started' and exports['qb-core']:GetCoreObject()
    if QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            local pGroup = Player.PlayerData.group or (Player.PlayerData.permission)
            if Config.AdminGroups[pGroup] then
                return true
            end
        end
    end

    return false
end

-- HOOK KIỂM TRA PLAYER KHI KẾT NỐI (playerConnecting)
-- Chỉ kiểm tra dữ liệu TRỰC TIẾP gửi lên lúc kết nối, tuyệt đối không truy vấn dữ liệu cũ trong DB
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(50)

    deferrals.update(string.format('Xin chào %s, đang kiểm tra trạng thái cấm kết nối...', name))

    local identifiers = GetPlayerIdentifiers(src)
    local playerLicense, playerDiscord, playerIp, playerGmail = nil, nil, nil, nil

    for _, id in ipairs(identifiers) do
        local idLower = id:lower()
        if string.sub(idLower, 1, 8) == 'license:' then
            playerLicense = cleanIdentifier(id)
        elseif string.sub(idLower, 1, 8) == 'discord:' then
            playerDiscord = cleanIdentifier(id)
        elseif string.sub(idLower, 1, 3) == 'ip:' then
            playerIp = cleanIdentifier(id)
        elseif string.sub(idLower, 1, 6) == 'email:' or string.sub(idLower, 1, 6) == 'gmail:' or string.sub(idLower, 1, 5) == 'mail:' then
            playerGmail = cleanIdentifier(id)
        end
    end

    -- Kiểm tra trong Ban Cache (Trùng 1 trong các thông tin: License, Discord, IP, Gmail)
    local activeBan = nil

    if playerLicense and BansCache.byLicense[playerLicense] then
        activeBan = BansCache.byLicense[playerLicense]
    elseif playerDiscord and BansCache.byDiscord[playerDiscord] then
        activeBan = BansCache.byDiscord[playerDiscord]
    elseif playerIp and BansCache.byIp[playerIp] then
        activeBan = BansCache.byIp[playerIp]
    elseif playerGmail and BansCache.byGmail[playerGmail] then
        activeBan = BansCache.byGmail[playerGmail]
    end

    if activeBan then
        -- Format ngày giờ hiển thị
        local bannedAtStr = activeBan.banned_at and tostring(activeBan.banned_at) or 'N/A'
        local expireStr = activeBan.expire_at and tostring(activeBan.expire_at) or 'Vĩnh viễn'

        local banMessage = string.format(
            Config.BanMessageFormat,
            activeBan.reason or 'Không có lý do',
            activeBan.ban_id or 'N/A',
            activeBan.banned_by or 'Admin',
            bannedAtStr,
            expireStr
        )

        deferrals.done(banMessage)
        CancelEvent()
        return
    end

    deferrals.done()
end)

-- Command mở Menu Quản Lý Ban
RegisterCommand(Config.Command, function(source, args, raw)
    local src = source
    if src == 0 then
        print('^1Command chi danh cho player trong game!^7')
        return
    end

    if not hasAdminPermission(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Bạn không có quyền sử dụng lệnh này!'
        })
        return
    end

    TriggerClientEvent('xn_ban:client:openMenu', src)
end, false)

-- Hàm lấy và chuẩn hóa toàn bộ dữ liệu bans cho Admin UI (Format trực tiếp từ SQL để tránh lỗi Epoch/milisec)
local function fetchBansForAdmin()
    local query = [[
        SELECT 
            id, ban_id, name, license, discord, gmail, ip, reason, banned_by,
            COALESCE(DATE_FORMAT(banned_at, '%d/%m/%Y %H:%i:%s'), '') AS banned_at,
            COALESCE(DATE_FORMAT(expire_at, '%d/%m/%Y %H:%i:%s'), 'Vĩnh viễn') AS expire_at,
            status, revoked_by, revoked_reason,
            COALESCE(DATE_FORMAT(revoked_at, '%d/%m/%Y %H:%i:%s'), '') AS revoked_at
        FROM `xn_bans` 
        ORDER BY `id` DESC LIMIT 200
    ]]
    local bans = MySQL.query.await(query, {}) or {}
    for _, ban in ipairs(bans) do
        ban.status = (ban.status == 1 or ban.status == true or ban.status == '1') and 1 or 0
        if not ban.expire_at or ban.expire_at == '' then
            ban.expire_at = 'Vĩnh viễn'
        end
    end
    return bans
end

-- Lấy danh sách Bans cho UI
RegisterNetEvent('xn_ban:server:getBans', function(filter)
    local src = source
    if not hasAdminPermission(src) then return end

    local bans = fetchBansForAdmin()
    TriggerClientEvent('xn_ban:client:receiveBans', src, bans)
end)

-- Lấy danh sách Online Players cho Admin tiện chọn
RegisterNetEvent('xn_ban:server:getOnlinePlayers', function()
    local src = source
    if not hasAdminPermission(src) then return end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pSrc = tonumber(playerId)
        local pName = GetPlayerName(pSrc)
        local ids = GetPlayerIdentifiers(pSrc)
        local lic, disc, ip, mail = nil, nil, nil, nil

        for _, id in ipairs(ids) do
            local idLower = id:lower()
            if string.sub(idLower, 1, 8) == 'license:' then
                lic = id
            elseif string.sub(idLower, 1, 8) == 'discord:' then
                disc = id
            elseif string.sub(idLower, 1, 3) == 'ip:' then
                ip = id
            elseif string.sub(idLower, 1, 6) == 'email:' or string.sub(idLower, 1, 6) == 'gmail:' or string.sub(idLower, 1, 5) == 'mail:' then
                mail = id:gsub('^.-:', '')
            end
        end

        table.insert(players, {
            id = pSrc,
            name = pName,
            license = lic,
            discord = disc,
            ip = ip,
            gmail = mail
        })
    end

    TriggerClientEvent('xn_ban:client:receiveOnlinePlayers', src, players)
end)

-- Thêm lệnh Ban mới
RegisterNetEvent('xn_ban:server:createBan', function(data)
    local src = source
    if not hasAdminPermission(src) then return end

    local adminName = GetPlayerName(src) or 'Admin'
    local banId = generateBanId()
    local targetName = (data.name and data.name ~= '') and data.name or 'Đối tượng bị cấm'
    local reason = (data.reason and data.reason ~= '') and data.reason or 'Vi phạm quy định máy chủ'
    local license = data.license and cleanIdentifier(data.license) or nil
    local discord = data.discord and cleanIdentifier(data.discord) or nil
    local gmail = data.gmail and cleanIdentifier(data.gmail) or nil
    local ip = data.ip and cleanIdentifier(data.ip) or nil

    local expireAt = nil
    if data.duration and tonumber(data.duration) and tonumber(data.duration) > 0 then
        -- duration theo giờ (lấy giờ local của server)
        expireAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + (tonumber(data.duration) * 3600))
    end

    local insertQuery = [[
        INSERT INTO `xn_bans` (`ban_id`, `name`, `license`, `discord`, `gmail`, `ip`, `reason`, `banned_by`, `expire_at`, `status`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
    ]]

    local insertId = MySQL.insert.await(insertQuery, {
        banId,
        targetName,
        license,
        discord,
        gmail,
        ip,
        reason,
        adminName,
        expireAt
    })

    if insertId then
        -- Tải lại cache
        loadBansCache()

        -- Nếu người chơi bị cấm đang có mặt trong server -> Kick ngay lập tức
        for _, playerId in ipairs(GetPlayers()) do
            local pSrc = tonumber(playerId)
            local pIds = GetPlayerIdentifiers(pSrc)
            local pLic, pDisc, pIp = nil, nil, nil

            for _, id in ipairs(pIds) do
                if string.sub(id, 1, 8) == 'license:' then pLic = cleanIdentifier(id)
                elseif string.sub(id, 1, 8) == 'discord:' then pDisc = cleanIdentifier(id)
                elseif string.sub(id, 1, 3) == 'ip:' then pIp = cleanIdentifier(id) end
            end

            local isMatch = false
            if license and pLic == license then isMatch = true end
            if discord and pDisc == discord then isMatch = true end
            if ip and pIp == ip then isMatch = true end

            if isMatch then
                DropPlayer(pSrc, string.format('Bạn đang bị cấm vì lí do: %s\nMã cấm: [%s]', reason, banId))
            end
        end

        -- Discord Log
        sendDiscordLog('🛡️ LỆNH CẤM MỚI ĐÃ ĐƯỢC TẠO', string.format('Admin **%s** vừa ban đối tượng **%s**', adminName, targetName), 15158332, {
            { name = 'Mã Cấm', value = string.format('`[%s]`', banId), inline = true },
            { name = 'Người cấm', value = adminName, inline = true },
            { name = 'Thời hạn', value = expireAt or 'Vĩnh viễn', inline = true },
            { name = 'Lý do', value = reason, inline = false },
            { name = 'License', value = license or 'Không có', inline = false },
            { name = 'Discord', value = discord or 'Không có', inline = true },
            { name = 'Gmail', value = gmail or 'Không có', inline = true },
            { name = 'IP', value = ip or 'Không có', inline = true },
        })

        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = string.format('Đã ban thành công mã [%s]!', banId)
        })

        -- Gửi lại danh sách cập nhật cho Admin
        local updatedBans = fetchBansForAdmin()
        TriggerClientEvent('xn_ban:client:receiveBans', src, updatedBans)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Có lỗi xảy ra khi tạo lệnh ban!'
        })
    end
end)

-- Gỡ cấm (Revoke Ban)
RegisterNetEvent('xn_ban:server:revokeBan', function(banId, revokeReason)
    local src = source
    if not hasAdminPermission(src) then return end

    local adminName = GetPlayerName(src) or 'Admin'
    local reason = (revokeReason and revokeReason ~= '') and revokeReason or 'Admin gỡ cấm'

    local updateQuery = [[
        UPDATE `xn_bans` 
        SET `status` = 0, `revoked_by` = ?, `revoked_reason` = ?, `revoked_at` = NOW()
        WHERE `ban_id` = ? AND `status` = 1
    ]]
    local affectedRows = MySQL.update.await(updateQuery, { adminName, reason, banId })

    if affectedRows and affectedRows > 0 then
        loadBansCache()

        sendDiscordLog('🔓 ĐÃ GỠ LỆNH CẤM (REVOKED)', string.format('Admin **%s** đã gỡ lệnh cấm cho mã **[%s]**', adminName, banId), 3066993, {
            { name = 'Mã Cấm', value = string.format('`[%s]`', banId), inline = true },
            { name = 'Người gỡ', value = adminName, inline = true },
            { name = 'Lý do gỡ', value = reason, inline = false }
        })

        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = string.format('Đã gỡ cấm thành công mã [%s]!', banId)
        })

        local updatedBans = fetchBansForAdmin()
        TriggerClientEvent('xn_ban:client:receiveBans', src, updatedBans)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Không tìm thấy mã ban hoặc lệnh ban đã được gỡ trước đó!'
        })
    end
end)
