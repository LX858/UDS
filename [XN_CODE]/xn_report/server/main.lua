local QBCore = nil
if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Hàm lấy tất cả Identifiers của một người chơi (Discord, Steam, License)
local function GetPlayerIdentifiersList(src)
    local identifiers = {
        discord = 'Không có',
        discordId = nil,
        steam = 'Không có',
        license = 'Không có'
    }

    local num = GetNumPlayerIdentifiers(src)
    for i = 0, num - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then
            if string.find(id, 'discord:') then
                identifiers.discordId = string.sub(id, 9)
                identifiers.discord = ('<@%s> (%s)'):format(identifiers.discordId, identifiers.discordId)
            elseif string.find(id, 'steam:') then
                identifiers.steam = id
            elseif string.find(id, 'license:') then
                identifiers.license = id
            end
        end
    end

    return identifiers
end

-- Hàm lấy thông tin nhân vật cơ bản (Hỗ trợ Qbox, QBCore, ESX & Standalone)
local function GetFullPlayerData(src)
    local data = {
        id = src,
        name = GetPlayerName(src) or 'Unknown',
        charName = GetPlayerName(src) or 'Unknown',
        citizenid = 'N/A'
    }

    local ids = GetPlayerIdentifiersList(src)
    data.discord = ids.discord
    data.discordId = ids.discordId
    data.steam = ids.steam
    data.license = ids.license

    -- 1. Thử lấy qua qbx_core
    if GetResourceState('qbx_core') == 'started' and exports.qbx_core then
        local player = exports.qbx_core:GetPlayer(src)
        if player and player.PlayerData then
            data.citizenid = player.PlayerData.citizenid or data.citizenid
            if player.PlayerData.charinfo then
                data.charName = ('%s %s'):format(player.PlayerData.charinfo.firstname or '', player.PlayerData.charinfo.lastname or '')
            end
            return data
        end
    end

    -- 2. Thử lấy qua qb-core
    if QBCore then
        local player = QBCore.Functions.GetPlayer(src)
        if player and player.PlayerData then
            data.citizenid = player.PlayerData.citizenid or data.citizenid
            if player.PlayerData.charinfo then
                data.charName = ('%s %s'):format(player.PlayerData.charinfo.firstname or '', player.PlayerData.charinfo.lastname or '')
            end
            return data
        end
    end

    -- 3. Thử lấy qua ESX
    if GetResourceState('es_extended') == 'started' and exports['es_extended'] then
        local ESX = exports['es_extended']:getSharedObject()
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                data.charName = xPlayer.getName() or data.charName
                data.citizenid = xPlayer.identifier or data.citizenid
                return data
            end
        end
    end

    return data
end

-- Kiểm tra xem 1 player có quyền Admin hay không
local function IsPlayerAdmin(src)
    for _, perm in ipairs(Config.AdminPermissions or {}) do
        if IsPlayerAceAllowed(src, perm) or IsPlayerAceAllowed(src, 'command') then
            return true
        end
    end

    if GetResourceState('qbx_core') == 'started' and exports.qbx_core then
        if exports.qbx_core:HasPermission(src, Config.AdminPermissions) then
            return true
        end
    end

    if QBCore then
        for _, perm in ipairs(Config.AdminPermissions or {}) do
            if QBCore.Functions.HasPermission(src, perm) then
                return true
            end
        end
    end

    return false
end

-- Khởi tạo bảng dữ liệu xn_reports khi server khởi động
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `xn_reports` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(60) NOT NULL,
            `license` VARCHAR(100) DEFAULT NULL,
            `reason` TEXT NOT NULL,
            `video_url` TEXT DEFAULT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(success)
        if success then
            print('^2[XN_REPORT] Bảng dữ liệu xn_reports đã sẵn sàng!^7')
        end
    end)
end)

-- Callback lấy danh sách lịch sử report của cá nhân player
lib.callback.register('xn_report:server:getPlayerReports', function(source)
    local src = source
    local reporter = GetFullPlayerData(src)
    local citizenid = reporter.citizenid
    local license = reporter.license

    local success, rows = pcall(function()
        return MySQL.query.await([[
            SELECT id, reason, video_url AS videoUrl, 
                   DATE_FORMAT(created_at, '%H:%i - %d/%m/%Y') AS createdAt
            FROM xn_reports
            WHERE (citizenid = ? AND citizenid != 'N/A' AND citizenid != 'UNKNOWN') 
               OR (license = ? AND license != 'Không có' AND license != 'UNKNOWN')
            ORDER BY id DESC
            LIMIT 50
        ]], { citizenid, license })
    end)

    if success and rows then
        return rows
    end
    return {}
end)

-- Hàm gửi Discord Webhook
local function SendDiscordReport(reporter, reportData, nearbyDetails, reportId)
    if not Config.DiscordWebhook or Config.DiscordWebhook == '' or string.find(Config.DiscordWebhook, 'xxxxxxxx') then
        print('^3[XN_REPORT] CẢNH BÁO: Chưa cấu hình Config.DiscordWebhook hợp lệ trong config.lua!^7')
        return
    end

    local timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    local localTimeStr = os.date('%H:%M:%S - %d/%m/%Y')
    local reportIdDisplay = reportId and ('#' .. tostring(reportId)) or 'N/A'

    -- Tạo nội dung danh sách người chơi xung quanh (50m)
    local nearbyText = ''
    if #nearbyDetails == 0 then
        nearbyText = '*(Không có người chơi nào khác trong bán kính 50m)*'
    else
        for _, p in ipairs(nearbyDetails) do
            if not p.isSelf then
                nearbyText = nearbyText .. string.format(
                    "🔴 **[ID: %s] %s** | **%.1fm**\n" ..
                    "└ **CitizenID:** `%s` | **Discord:** %s\n" ..
                    "└ **Trạng thái:** %s\n\n",
                    p.id,
                    p.charName,
                    p.distance or 0.0,
                    p.citizenid or 'N/A',
                    p.discord or 'Không có',
                    p.inVehicle and '🚗 Đang lái xe' or '🚶 Đi bộ'
                )
            end
        end
        if nearbyText == '' then
            nearbyText = '*(Chỉ có chính người gửi report trong vùng quét)*'
        end
    end

    if string.len(nearbyText) > 1000 then
        nearbyText = string.sub(nearbyText, 1, 980) .. '\n... *(còn nhiều người chơi khác)*'
    end

    -- Video Embed & Link
    local videoFieldText = '⚠️ *Không thể tải video hoặc video đang được xử lý*'
    if reportData.videoUrl and reportData.videoUrl ~= '' then
        videoFieldText = string.format(
            "🎥 **[👉 BẤM VÀO ĐÂY ĐỂ XEM VIDEO BẰNG CHỨNG HD](%s)**\n" ..
            "🔗 Link CDN: `%s`\n" ..
            "⏱️ Thời lượng: **%s giây** | 📺 Độ phân giải: **HD 720p**",
            reportData.videoUrl,
            reportData.videoUrl,
            reportData.duration or 10
        )
    end

    local embed = {
        {
            title = string.format('🚨 [REPORT %s] BÁO CÁO VI PHẠM & GHI HÌNH BẰNG CHỨNG', reportIdDisplay),
            description = 'Một người chơi vừa gửi yêu cầu xử lý vi phạm kèm video ghi hình HD và dữ liệu quét 50m xung quanh.',
            color = 15548997, -- Màu đỏ nổi bật (#ED4245)
            fields = {
                {
                    name = '🆔 Mã Report ID',
                    value = string.format("`%s`", reportIdDisplay),
                    inline = true
                },
                {
                    name = '👤 Thông Tin Người Báo Cáo',
                    value = string.format(
                        "• **Tên Ingame:** %s (Steam: `%s`)\n" ..
                        "• **Server ID:** `%s` | **CitizenID:** `%s`\n" ..
                        "• **Discord:** %s",
                        reporter.charName,
                        reporter.name,
                        reporter.id,
                        reporter.citizenid,
                        reporter.discord
                    ),
                    inline = false
                },
                {
                    name = '📍 Vị Trí Xảy Ra Sự Việc',
                    value = string.format("• **Tọa độ:** `vector3(%.2f, %.2f, %.2f)`", reportData.coords.x, reportData.coords.y, reportData.coords.z),
                    inline = false
                },
                {
                    name = '📝 Nội Dung / Lý Do Báo Cáo',
                    value = string.format("```yaml\n%s\n```", reportData.reason),
                    inline = false
                },
                {
                    name = string.format('👥 Người Chơi Trong Bán Kính 50m (%s người)', #nearbyDetails),
                    value = nearbyText,
                    inline = false
                },
                {
                    name = '📹 Video Bằng Chứng FiveManage (HD)',
                    value = videoFieldText,
                    inline = false
                }
            },
            footer = {
                text = string.format('%s • Hệ Thống Report Bằng Chứng • Thời Gian: %s', Config.ServerName or 'UNDER STAR', localTimeStr),
                icon_url = Config.ServerLogo
            },
            timestamp = timestamp
        }
    }

    local payload = json.encode({
        username = (Config.ServerName or 'UNDER STAR') .. ' - REPORT SYSTEM',
        avatar_url = Config.ServerLogo,
        embeds = embed
    })

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            print(('^1[XN_REPORT] Lỗi gửi Discord Webhook (Mã lỗi: %s): %s^7'):format(err, text or ''))
        else
            print(('^2[XN_REPORT] Đã gửi báo cáo %s của ID %s thành công lên Discord!^7'):format(reportIdDisplay, reporter.id))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

local serverCooldowns = {}

-- Nhận sự kiện submitReport từ Client
RegisterNetEvent('xn_report:server:submitReport', function(data)
    local src = source
    if not data or not data.reason then return end

    local reporter = GetFullPlayerData(src)

    -- Kiểm tra cooldown 15 phút phía server để chống spam / exploit
    local cooldownDuration = Config.Cooldown or (15 * 60)
    local playerKey = (reporter.citizenid and reporter.citizenid ~= 'N/A' and reporter.citizenid ~= 'UNKNOWN') and reporter.citizenid or (reporter.license or src)
    local now = os.time()

    if serverCooldowns[playerKey] and (now - serverCooldowns[playerKey]) < cooldownDuration then
        local remaining = cooldownDuration - (now - serverCooldowns[playerKey])
        local mins = math.floor(remaining / 60)
        local secs = remaining % 60
        local timeMsg = mins > 0 and (secs > 0 and string.format('%d phút %d giây', mins, secs) or string.format('%d phút', mins)) or string.format('%d giây', remaining)

        if GetResourceState('ox_lib') == 'started' then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Hệ Thống Report',
                description = ('Bạn đang trong thời gian chờ! Vui lòng đợi %s nữa.'):format(timeMsg),
                type = 'error',
                duration = 6000
            })
        end
        return
    end

    serverCooldowns[playerKey] = now

    -- 1. Lưu report vào Database để quản lý và hiển thị cho người chơi xem lịch sử
    local insertId = nil
    local success, res = pcall(function()
        return MySQL.insert.await([[
            INSERT INTO `xn_reports` (`citizenid`, `license`, `reason`, `video_url`)
            VALUES (?, ?, ?, ?)
        ]], {
            reporter.citizenid or 'UNKNOWN',
            reporter.license or 'UNKNOWN',
            data.reason or '',
            data.videoUrl or ''
        })
    end)

    if success and res then
        insertId = res
    end

    -- 2. Thu thập thông tin cho từng player trong danh sách 50m
    local nearbyDetails = {}
    if data.nearbyPlayers and type(data.nearbyPlayers) == 'table' then
        for _, np in ipairs(data.nearbyPlayers) do
            local pData = GetFullPlayerData(np.serverId)
            pData.distance = np.distance
            pData.isSelf = np.isSelf
            pData.inVehicle = np.inVehicle
            table.insert(nearbyDetails, pData)
        end
    end

    -- 3. Gửi Webhook Discord
    SendDiscordReport(reporter, data, nearbyDetails, insertId)

    -- 4. Thông báo cho Admin đang online trong game
    if Config.NotifyAdminsInGame then
        local players = GetPlayers()
        local reportTag = insertId and ('[REPORT #' .. insertId .. ']') or '[REPORT MỚI]'
        for _, pId in ipairs(players) do
            local adminSrc = tonumber(pId)
            if adminSrc and IsPlayerAdmin(adminSrc) then
                if GetResourceState('ox_lib') == 'started' then
                    TriggerClientEvent('ox_lib:notify', adminSrc, {
                        title = '🚨 ' .. reportTag,
                        description = ('[ID: %s] %s vừa gửi report: %s'):format(src, reporter.charName, string.sub(data.reason, 1, 60)),
                        type = 'warning',
                        duration = 10000
                    })
                else
                    TriggerClientEvent('chat:addMessage', adminSrc, {
                        color = { 255, 69, 0 },
                        multiline = true,
                        args = { 'REPORT', ('%s [ID: %s] %s gửi report: %s'):format(reportTag, src, reporter.charName, data.reason) }
                    })
                end
            end
        end
    end
end)
