local BansCache = {
    byLicense = {},
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

-- Ban có thời hạn dài hơn được ưu tiên khi nhiều ban trùng 1 identifier (vĩnh viễn = dài nhất)
local function putBan(map, key, ban)
    if not key then return end
    local current = map[key]
    if not current then
        map[key] = ban
        return
    end
    local currentTs = current.expires_ts or math.huge
    local newTs = ban.expires_ts or math.huge
    if newTs > currentTs then map[key] = ban end
end

local function isBanActive(ban)
    return ban ~= nil and (ban.expires_ts == nil or ban.expires_ts > os.time())
end

-- Tải toàn bộ danh sách Ban còn hiệu lực vào Cache
-- Dựng cache mới rồi mới thay thế để người chơi kết nối trong lúc đang tải không bị lọt ban
local function loadBansCache()
    local query = [[
        SELECT 
            id, ban_id, name, license, discord, gmail, ip, reason, banned_by,
            COALESCE(DATE_FORMAT(banned_at, '%d/%m/%Y %H:%i:%s'), '') AS banned_at,
            COALESCE(DATE_FORMAT(expire_at, '%d/%m/%Y %H:%i:%s'), 'Vĩnh viễn') AS expire_at,
            TIMESTAMPDIFF(SECOND, NOW(), expire_at) AS ttl,
            status
        FROM `xn_bans` 
        WHERE `status` = 1 
        AND (`expire_at` IS NULL OR `expire_at` > NOW())
    ]]
    local results = MySQL.query.await(query, {})
    if not results then
        print('^1[xn_ban]^7 Khong the tai danh sach ban, giu nguyen cache cu!')
        return
    end

    local newCache = { byLicense = {}, byGmail = {}, list = {} }
    local now = os.time()
    for _, ban in ipairs(results) do
        -- Lưu mốc hết hạn theo epoch để kiểm tra lúc kết nối, không phụ thuộc lần tải cache
        ban.expires_ts = ban.ttl and (now + ban.ttl) or nil
        newCache.list[ban.ban_id] = ban

        putBan(newCache.byLicense, cleanIdentifier(ban.license), ban)
        putBan(newCache.byGmail, cleanIdentifier(ban.gmail), ban)
    end

    BansCache = newCache
    print(string.format('^2[xn_ban]^7 Da tai thanh cong %d ban vao bo nho dem!', #results))
end

-- Khởi động tải Cache
local syncOnlinePlayers

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `xn_players` (
            `license` VARCHAR(100) NOT NULL PRIMARY KEY,
            `name` VARCHAR(100) NOT NULL DEFAULT 'Không tên',
            `first_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_name` (`name`),
            INDEX `idx_last_seen` (`last_seen`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {})
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `xn_player_ids` (
            `license` VARCHAR(100) NOT NULL,
            `id_type` VARCHAR(16) NOT NULL,
            `id_value` VARCHAR(150) NOT NULL,
            `seen_count` INT UNSIGNED NOT NULL DEFAULT 1,
            `first_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`license`, `id_type`, `id_value`),
            INDEX `idx_value` (`id_value`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]], {})
    loadBansCache()
    syncOnlinePlayers()
end)

-- Định kỳ tải lại cache (bắt thay đổi từ DB/nhiều server)
CreateThread(function()
    while true do
        Wait(Config.BanCacheRefreshMinutes * 60 * 1000)
        loadBansCache()
    end
end)

-- Chỉ ghi DB khi thông tin đổi hoặc đã quá PlayerRecordInterval, tránh ghi mỗi lần connect ở server đông
local PlayerWriteCache = {}

-- Tách License / Discord / Gmail / IP từ danh sách identifier của người chơi
local function extractIdentifiers(src)
    local result = {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        local idLower = id:lower()
        if idLower:sub(1, 8) == 'license:' then
            result.license = cleanIdentifier(id)
        elseif idLower:sub(1, 8) == 'discord:' then
            result.discord = cleanIdentifier(id)
        elseif idLower:sub(1, 3) == 'ip:' then
            result.ip = cleanIdentifier(id)
        elseif idLower:sub(1, 6) == 'email:' or idLower:sub(1, 6) == 'gmail:' or idLower:sub(1, 5) == 'mail:' then
            result.gmail = cleanIdentifier((id:gsub('^.-:', '')))
        end
    end
    return result
end

local function savePlayerRecord(name, license, discord, gmail)
    if not license then return end

    local sig = table.concat({ name or '', discord or '', gmail or '' }, '|')
    local now = os.time()
    local cached = PlayerWriteCache[license]
    if cached and cached.sig == sig and now - cached.at < Config.PlayerRecordInterval then return end
    PlayerWriteCache[license] = { sig = sig, at = now }

    if Config.Debug then
        print(string.format('^3[xn_ban]^7 Luu nguoi choi "%s" | license=%s | discord=%s | gmail=%s',
            name or '?', license, discord or 'KHONG CO', gmail or 'KHONG CO'))
    end

    local function onWritten(affected)
        if affected == nil then
            PlayerWriteCache[license] = nil
            print('^1[xn_ban]^7 Ghi nguoi choi vao DB that bai: ' .. license)
        end
    end

    MySQL.insert([[
        INSERT INTO `xn_players` (`license`, `name`) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `last_seen` = NOW()
    ]], { license, name or 'Không tên' }, onWritten)

    -- Mỗi identifier có bộ đếm riêng: discord nào xuất hiện nhiều/gần đây nhất sẽ được ưu tiên gợi ý
    local idQuery = [[
        INSERT INTO `xn_player_ids` (`license`, `id_type`, `id_value`) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE `seen_count` = `seen_count` + 1, `last_seen` = NOW()
    ]]
    if discord then MySQL.insert(idQuery, { license, 'discord', discord }, onWritten) end
    if gmail then MySQL.insert(idQuery, { license, 'gmail', gmail }, onWritten) end
end

-- Ghi luôn những người đang online lúc resource (re)start, vì họ sẽ không đi qua playerConnecting nữa
syncOnlinePlayers = function()
    for _, playerId in ipairs(GetPlayers()) do
        local ids = extractIdentifiers(tonumber(playerId))
        savePlayerRecord(GetPlayerName(playerId), ids.license, ids.discord, ids.gmail)
    end
end

CreateThread(function()
    while true do
        Wait(30 * 60 * 1000)
        local now = os.time()
        for license, cached in pairs(PlayerWriteCache) do
            if now - cached.at >= Config.PlayerRecordInterval then
                PlayerWriteCache[license] = nil
            end
        end
    end
end)

-- Quyền Admin cho NetEvents: cùng điều kiện với lệnh mở menu (ox_lib cấp ACE command.<tên lệnh> cho Config.AdminGroups)
local function hasAdminPermission(src, action)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, 'command.' .. Config.Command) or IsPlayerAceAllowed(src, Config.AdminAce) then
        return true
    end
    for _, group in ipairs(Config.AdminGroups) do
        if IsPlayerAceAllowed(src, group) then return true end
    end
    print(string.format('^3[xn_ban]^7 Tu choi %s tu ID %s (%s): khong co quyen. Can ACE command.%s hoac mot trong %s',
        action or 'event', tostring(src), GetPlayerName(src) or '?', Config.Command, table.concat(Config.AdminGroups, ', ')))
    TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Bạn không có quyền sử dụng hệ thống ban!' })
    return false
end

-- Khóa quyết định ban chỉ gồm License và Gmail: trùng 1 trong 2 là bị chặn.
-- Discord/IP có thể đổi hoặc dùng chung nên chỉ lưu tham khảo, không dùng để chặn.
local function findActiveBan(license, gmail)
    local lookups = {
        { BansCache.byLicense, license },
        { BansCache.byGmail, gmail },
    }
    for _, lookup in ipairs(lookups) do
        local key = lookup[2]
        local ban = key and lookup[1][key]
        if isBanActive(ban) then return ban end
    end
    return nil
end

-- HOOK KIỂM TRA PLAYER KHI KẾT NỐI (playerConnecting)
-- Chỉ kiểm tra dữ liệu TRỰC TIẾP gửi lên lúc kết nối, tuyệt đối không truy vấn dữ liệu cũ trong DB
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(50)

    deferrals.update(string.format('Xin chào %s, đang kiểm tra trạng thái cấm kết nối...', name))

    local identifiers = extractIdentifiers(src)
    local playerLicense, playerDiscord, playerGmail = identifiers.license, identifiers.discord, identifiers.gmail

    savePlayerRecord(name, playerLicense, playerDiscord, playerGmail)

    -- Kiểm tra trong Ban Cache (trùng License hoặc Gmail)
    local activeBan = findActiveBan(playerLicense, playerGmail)
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

-- Command mở Menu Quản Lý Ban (lib.addCommand ox_lib - tích hợp sẵn quyền Qbox)
lib.addCommand(Config.Command, {
    help = 'Mở giao diện Quản lý Lệnh Cấm (Ban Management)',
    restricted = Config.AdminGroups, -- ox_lib tự kiểm tra group Qbox, không cần server.cfg
}, function(src)
    TriggerClientEvent('xn_ban:client:openMenu', src)
end)

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
    if not hasAdminPermission(src, 'getBans') then return end
    local bans = fetchBansForAdmin()
    TriggerClientEvent('xn_ban:client:receiveBans', src, bans)
end)

-- Lấy danh sách Online Players cho Admin tiện chọn
RegisterNetEvent('xn_ban:server:getOnlinePlayers', function()
    local src = source
    if not hasAdminPermission(src, 'getOnlinePlayers') then return end

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

local function newSearchEntry(license, name, source)
    return {
        name = name,
        license = license,
        source = source,
        discords = {}, gmails = {},
        seenDiscords = {}, seenGmails = {},
    }
end

-- Gom các ứng viên discord/gmail của 1 người chơi (mỗi giá trị chỉ xuất hiện 1 lần)
local function addCandidate(entry, kind, value, count, lastSeen)
    if not value or value == '' then return end
    local seen = kind == 'discord' and entry.seenDiscords or entry.seenGmails
    local list = kind == 'discord' and entry.discords or entry.gmails

    local existing = seen[value]
    if existing then
        existing.count = math.max(existing.count, count)
        if lastSeen > existing.lastSeen then existing.lastSeen = lastSeen end
        return
    end

    local candidate = { id = value, count = count, lastSeen = lastSeen }
    seen[value] = candidate
    list[#list + 1] = candidate
end

-- Chính xác nhất = xuất hiện nhiều lần nhất, hoà thì dùng cái thấy gần đây nhất
local function candidateSort(a, b)
    if a.count ~= b.count then return a.count > b.count end
    return a.lastSeen > b.lastSeen
end

local function finalizeSearchEntry(entry)
    table.sort(entry.discords, candidateSort)
    table.sort(entry.gmails, candidateSort)
    entry.discord = entry.discords[1] and entry.discords[1].id or ''
    entry.gmail = entry.gmails[1] and entry.gmails[1].id or ''
    entry.seenDiscords, entry.seenGmails = nil, nil
end

-- Tìm kiếm người chơi offline theo chuỗi con (một phần tên / license / discord / email)
-- Nguồn: bảng xn_players/xn_player_ids (ghi lúc người chơi kết nối) + bảng players của Qbox
local function searchOfflinePlayers(query)
    if type(query) ~= 'string' then return {} end
    query = query:sub(1, 64):lower():gsub('^%s*(.-)%s*$', '%1')
    if #query < 2 then return {} end

    local entries, byLicense = {}, {}
    local maxResults = Config.SearchMaxResults

    local function getEntry(license, name, source)
        local entry = byLicense[license]
        if entry then return entry end
        if #entries >= maxResults then return nil end
        entry = newSearchEntry(license, name, source)
        byLicense[license] = entry
        entries[#entries + 1] = entry
        return entry
    end

    -- 1. Bảng xn_players: khớp tên/license hoặc bất kỳ discord/gmail nào từng dùng
    local likeTerm = '%' .. (query:gsub('[%%_\\]', '\\%0')) .. '%'
    local rows = MySQL.query.await([[
        SELECT `license`, `name` FROM `xn_players`
        WHERE `name` LIKE ? OR `license` LIKE ?
           OR `license` IN (SELECT `license` FROM `xn_player_ids` WHERE `id_value` LIKE ?)
        ORDER BY `last_seen` DESC
        LIMIT 10
    ]], { likeTerm, likeTerm, likeTerm }) or {}

    for _, row in ipairs(rows) do
        getEntry(row.license, row.name, 'xn_players')
    end

    -- 2. Nếu tìm chưa đủ, tìm thêm trong database MySQL (bảng players của Qbox)
    if #entries < maxResults then
        local sqlQuery = [[
            SELECT `name`, `license`, `citizenid`, `charinfo` 
            FROM `players` 
            WHERE LOWER(`name`) LIKE ? OR LOWER(`license`) LIKE ? OR LOWER(`citizenid`) LIKE ? OR LOWER(`charinfo`) LIKE ?
            LIMIT 10
        ]]
        local rows = MySQL.query.await(sqlQuery, { likeTerm, likeTerm, likeTerm, likeTerm }) or {}

        for _, row in ipairs(rows) do
            local lic = row.license and cleanIdentifier(row.license)
            if lic and not byLicense[lic] then
                -- Lấy tên nhân vật từ charinfo nếu có
                local charName = nil
                if row.charinfo and row.charinfo ~= '' then
                    local ok, cinfo = pcall(json.decode, row.charinfo)
                    if ok and cinfo and (cinfo.firstname or cinfo.lastname) then
                        charName = string.format('%s %s', cinfo.firstname or '', cinfo.lastname or ''):gsub('^%s*(.-)%s*$', '%1')
                    end
                end

                local displayName = charName and string.format('%s (%s)', charName, row.name) or row.name

                if not getEntry(lic, displayName, 'Database') then break end
            end
        end
    end

    -- Lấy mọi discord/gmail đã lưu từ lúc kết nối cho tất cả kết quả (kể cả kết quả đến từ nguồn khác)
    if #entries > 0 then
        local licenses = {}
        for i, entry in ipairs(entries) do licenses[i] = entry.license end
        local idRows = MySQL.query.await(string.format([[
            SELECT `license`, `id_type`, `id_value`, `seen_count`,
                   DATE_FORMAT(`last_seen`, '%%Y-%%m-%%d %%H:%%i:%%s') AS last_seen
            FROM `xn_player_ids` WHERE `license` IN (%s)
        ]], string.rep('?', #licenses, ',')), licenses) or {}

        for _, row in ipairs(idRows) do
            local entry = byLicense[row.license]
            if entry then
                addCandidate(entry, row.id_type, row.id_value, tonumber(row.seen_count) or 0, row.last_seen or '')
            end
        end
    end

    -- Chọn discord/gmail chính xác nhất cho từng kết quả
    for _, entry in ipairs(entries) do
        finalizeSearchEntry(entry)
    end

    print(string.format('^2[xn_ban]^7 Tim "%s": %d ket qua', query, #entries))
    return entries
end

-- Tìm kiếm người chơi offline (có kiểm tra quyền + giới hạn tần suất để tránh quét DB liên tục)
local lastSearchAt = {}

AddEventHandler('playerDropped', function()
    lastSearchAt[source] = nil
end)

RegisterNetEvent('xn_ban:server:searchOfflinePlayers', function(query)
    local src = source
    if not hasAdminPermission(src, 'searchOfflinePlayers') then return end

    local now = GetGameTimer()
    if lastSearchAt[src] and now - lastSearchAt[src] < Config.SearchCooldownMs then return end
    lastSearchAt[src] = now

    local ok, results = pcall(searchOfflinePlayers, query)
    if not ok then
        print('^1[xn_ban] Loi khi tim kiem offline player:^7 ' .. tostring(results))
        results = {}
    end
    TriggerClientEvent('xn_ban:client:receiveOfflineSearchResults', src, results)
end)

-- Thêm lệnh Ban mới
RegisterNetEvent('xn_ban:server:createBan', function(data)
    local src = source
    if not hasAdminPermission(src, 'createBan') or type(data) ~= 'table' then return end

    local adminName = GetPlayerName(src) or 'Admin'
    local banId = generateBanId()
    local targetName = (data.name and data.name ~= '') and data.name or 'Đối tượng bị cấm'
    local reason = (data.reason and data.reason ~= '') and data.reason or 'Vi phạm quy định máy chủ'
    local license = data.license and cleanIdentifier(data.license) or nil
    local discord = data.discord and cleanIdentifier(data.discord) or nil
    local gmail = type(data.gmail) == 'string' and cleanIdentifier((data.gmail:gsub('^%s*%a*mail:', ''))) or nil
    local ip = data.ip and cleanIdentifier(data.ip) or nil

    if not license and not gmail then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Cần có License hoặc Gmail để ban (đây là 2 khóa quyết định ban)!'
        })
        return
    end

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
            local pLic, pMail = nil, nil

            for _, id in ipairs(pIds) do
                local idLower = id:lower()
                if idLower:sub(1, 8) == 'license:' then pLic = cleanIdentifier(id)
                elseif idLower:sub(1, 6) == 'email:' or idLower:sub(1, 6) == 'gmail:' or idLower:sub(1, 5) == 'mail:' then
                    pMail = cleanIdentifier((id:gsub('^.-:', '')))
                end
            end

            if (license and pLic == license) or (gmail and pMail == gmail) then
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
    if not hasAdminPermission(src, 'revokeBan') then return end

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
