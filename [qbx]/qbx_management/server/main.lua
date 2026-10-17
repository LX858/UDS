lib.versionCheck('Qbox-project/qbx_management')
if not lib.checkDependency('qbx_core', '1.18.0', true) then error() return end
if not lib.checkDependency('ox_lib', '3.13.0', true) then error() return end

local config = require 'config.server'
local logger = require '@qbx_core.modules.logger'
local JOBS = exports.qbx_core:GetJobs()
local GANGS = exports.qbx_core:GetGangs()
local playersClockedIn = {}
local menus = {}

local function addMenu(defaultGroup, menuData)
    if type(menuData) ~= 'table' or not menuData.coords then return end

    local menuInfo = {}
    for k, v in pairs(menuData) do
        menuInfo[k] = v
    end

    local group = menuData.job or menuData.group or menuData.groupName or defaultGroup
    if not group then return end

    menuInfo.groupName = tostring(group)
    menuInfo.type = menuData.type or 'job'
    menuInfo.size = menuData.size or vec3(1.5, 1.5, 1.5)
    menuInfo.rotation = menuData.rotation or 0.0

    menus[#menus + 1] = menuInfo
end

for key, entry in pairs(config.menus) do
    if type(entry) == 'table' then
        if entry.coords then
            local defaultGroup = type(key) == 'string' and key or nil
            addMenu(defaultGroup, entry)
        else
            local defaultGroup = type(key) == 'string' and key or nil
            for _, subEntry in pairs(entry) do
                if type(subEntry) == 'table' and subEntry.coords then
                    addMenu(defaultGroup, subEntry)
                end
            end
        end
    end
end

local function getMenuEntries(groupName, groupType)
    local menuEntries = {}

    local groupEntries = exports.qbx_core:GetGroupMembers(groupName, groupType)
    for i = 1, #groupEntries do
        local citizenid = groupEntries[i].citizenid
        local grade = groupEntries[i].grade
        local player = exports.qbx_core:GetPlayerByCitizenId(citizenid) or exports.qbx_core:GetOfflinePlayer(citizenid)
        local namePrefix = player.Offline and '❌ ' or '🟢 '
        local playerActivityData = groupType == 'job' and GetPlayerActivityData(citizenid, groupName) or nil
        local playerClockData = playersClockedIn[player.PlayerData.source]
        local playerLastCheckIn = playerClockData and os.date(config.formatDateTime, playerClockData.time) or playerActivityData?.last_checkin
        menuEntries[#menuEntries + 1] = {
            cid = citizenid,
            grade = grade,
            name = namePrefix..player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname,
            onduty = player.PlayerData.job.onduty and not player.Offline,
            hours = playerActivityData?.hours,
            last_checkin = playerLastCheckIn
        }
    end

    return menuEntries
end

-- Get a list of employees for a given group.
---@param groupName string Name of job/gang to get employees of
---@param groupType GroupType
---@return table?
lib.callback.register('qbx_management:server:getEmployees', function(source, groupName, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    if not player.PlayerData[groupType].isboss then return end

    local menuEntries = getMenuEntries(groupName, groupType)
    table.sort(menuEntries, function(a, b)
        return a.grade > b.grade
    end)

    logger.log({
        source = source,
        event = 'qbx_management:server:getEmployees',
        message = locale('logs.retrieved_employees', groupName, groupType),
        webhook = config.discordWebhook
    })

    return menuEntries
end)

-- Callback for updating the grade information of online players
---@param source number
---@param citizenId string CitizenId of player who is being promoted/demoted
---@param oldGrade integer Old grade number of target employee
---@param newGrade integer New grade number of target employee
---@param groupType GroupType
lib.callback.register('qbx_management:server:updateGrade', function(source, citizenId, oldGrade, newGrade, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    local employee = exports.qbx_core:GetPlayerByCitizenId(citizenId)
    local jobName = player.PlayerData[groupType].name
    local gradeLevel = player.PlayerData[groupType].grade.level

    if not player.PlayerData[groupType].isboss then return end

    if player.PlayerData.citizenid == citizenId then
        exports.qbx_core:Notify(source, locale('error.cant_promote_self'), 'error')
        return
    end

    if oldGrade >= gradeLevel or newGrade >= gradeLevel then
        exports.qbx_core:Notify(source, locale('error.cant_promote'), 'error')
        return
    end

    if groupType == 'job' then
        local success, errorResult = exports.qbx_core:AddPlayerToJob(citizenId, jobName, newGrade)
        assert(success, errorResult?.message)
    else
        local success, errorResult = exports.qbx_core:AddPlayerToGang(citizenId, jobName, newGrade)
        assert(success, errorResult?.message)
    end

    if employee then
        local gradeName = groupType == 'gang' and GANGS[jobName].grades[newGrade].name or JOBS[jobName].grades[newGrade].name
        exports.qbx_core:Notify(employee.PlayerData.source, locale('success.promoted_to')..gradeName..'.', 'success')
    end
    exports.qbx_core:Notify(source, locale('success.promoted'), 'success')

    logger.log({
        source = source,
        event = 'qbx_management:server:updateGrade',
        message = locale('logs.updated_grade', citizenId, oldGrade, newGrade, jobName, groupType),
        webhook = config.discordWebhook
    })
end)

-- Callback to hire online player as employee of a given group
---@param employee integer Server ID of target employee to be hired
---@param groupType GroupType
lib.callback.register('qbx_management:server:hireEmployee', function(source, employee, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    local target = exports.qbx_core:GetPlayer(employee)

    if not player.PlayerData[groupType].isboss then return end

    if not target then
        exports.qbx_core:Notify(source, locale('error.not_around'), 'error')
        return
    end

    local groupName = player.PlayerData[groupType].name
    local logArea = groupType == 'gang' and 'Gang' or 'Boss'

    if groupType == 'job' then
        if config.cooldownJobs and config.cooldownJobs[groupName] then
            local cooldown = GetActiveCooldown(target.PlayerData.citizenid)
            if cooldown then
                local remaining = cooldown.expire_time - os.time()
                local daysLeft = math.floor(remaining / 86400)
                local hoursLeft = math.floor((remaining % 86400) / 3600)
                local typeLabel = cooldown.fire_type == 'blacklist' and locale('cooldown.type_blacklist') or locale('cooldown.type_resignation')
                local reasonText = cooldown.reason and (' | Lý do: ' .. cooldown.reason) or ''
                exports.qbx_core:Notify(source, locale('cooldown.on_cooldown_error', typeLabel, daysLeft, hoursLeft, reasonText), 'error')
                return
            end
        end

        local success, errorResult = exports.qbx_core:AddPlayerToJob(target.PlayerData.citizenid, groupName, 0)

        assert(success, errorResult?.message)
        success, errorResult = exports.qbx_core:SetPlayerPrimaryJob(target.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    else
        local success, errorResult = exports.qbx_core:AddPlayerToGang(target.PlayerData.citizenid, groupName, 0)
        assert(success, errorResult?.message)
        success, errorResult = exports.qbx_core:SetPlayerPrimaryGang(target.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    end

    local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local targetFullName = target.PlayerData.charinfo.firstname..' '..target.PlayerData.charinfo.lastname
    local organizationLabel = player.PlayerData[groupType].label

    exports.qbx_core:Notify(source, locale('success.hired_into', targetFullName, organizationLabel), 'success')
    exports.qbx_core:Notify(target.PlayerData.source, locale('success.hired_to')..organizationLabel, 'success')

    logger.log({
        source = source,
        event = 'qbx_management:server:hireEmployee',
        message = locale('logs.hired_employee', logArea, playerFullName, targetFullName, organizationLabel, 0),
        webhook = config.discordWebhook
    })
end)

-- Returns playerdata for a given table of player server ids.
---@param closePlayers table Table of player data for possible hiring
---@return table
lib.callback.register('qbx_management:server:getPlayers', function(_, closePlayers)
    local players = {}
    for _, v in pairs(closePlayers) do
        local player = exports.qbx_core:GetPlayer(v.id)
        if player then
            local hasIdCard = false
            if GetResourceState('ox_inventory') == 'started' then
                local count1 = exports.ox_inventory:GetItemCount(player.PlayerData.source, 'id_card') or 0
                local count2 = exports.ox_inventory:GetItemCount(player.PlayerData.source, 'idcard') or 0
                hasIdCard = (count1 > 0 or count2 > 0)
            else
                local has1, has2 = false, false
                pcall(function()
                    has1 = exports.qbx_core:HasItem(player.PlayerData.source, 'id_card')
                    has2 = exports.qbx_core:HasItem(player.PlayerData.source, 'idcard')
                end)
                hasIdCard = (has1 or has2)
            end

            players[#players + 1] = {
                id = v.id,
                name = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname,
                citizenid = player.PlayerData.citizenid,
                job = player.PlayerData.job,
                gang = player.PlayerData.gang,
                source = player.PlayerData.source,
                dinhdanh = tonumber(player.PlayerData.charinfo.dinhdanh) or 1,
                hasIdCard = hasIdCard
            }
        end
    end

    table.sort(players, function(a, b)
        return a.name < b.name
    end)

    logger.log({
        source = 'qbx_management',
        event = 'qbx_management:server:getPlayers',
        message = locale('logs.retrieved_players'),
        webhook = config.discordWebhook
    })

    return players
end)

lib.callback.register('qbx_management:server:getBossMenus', function()
    logger.log({
        source = 'qbx_management',
        event = 'qbx_management:server:getBossMenus',
        message = locale('logs.retrieved_boss_menus'),
        webhook = config.discordWebhook
    })
    return menus
end)

-- Helper function lấy Discord ID của người chơi từ FiveM identifiers
local function GetDiscordIdForPlayer(player)
    if not player or not player.PlayerData then return nil end

    if not player.Offline and player.PlayerData.source then
        for _, id in ipairs(GetPlayerIdentifiers(player.PlayerData.source)) do
            if string.sub(id, 1, 8) == "discord:" then
                return string.sub(id, 9)
            end
        end
    end

    if player.PlayerData.discord then
        return tostring(player.PlayerData.discord):gsub("discord:", "")
    end

    return nil
end

-- Helper function gửi Webhook Discord cho Nâng/Hạ Cấp Định Danh và Thu Hồi Thẻ Định Danh
local function sendIdentityWebhook(actionType, bossPlayer, targetPlayer, level)
    local jobName = bossPlayer.PlayerData.job and bossPlayer.PlayerData.job.name or (bossPlayer.PlayerData.gang and bossPlayer.PlayerData.gang.name or 'unknown')
    local jobLabel = bossPlayer.PlayerData.job and bossPlayer.PlayerData.job.label or (bossPlayer.PlayerData.gang and bossPlayer.PlayerData.gang.label or jobName)

    local targetWebhooks = {}

    -- Webhook định danh thứ 1
    if type(config.identityWebhook) == 'table' then
        for _, url in ipairs(config.identityWebhook) do
            if url and url ~= '' then
                targetWebhooks[#targetWebhooks + 1] = url
            end
        end
    elseif type(config.identityWebhook) == 'string' and config.identityWebhook ~= '' then
        targetWebhooks[#targetWebhooks + 1] = config.identityWebhook
    end

    -- Webhook định danh thứ 2
    if type(config.identityWebhook2) == 'table' then
        for _, url in ipairs(config.identityWebhook2) do
            if url and url ~= '' then
                local isDuplicate = false
                for _, existingUrl in ipairs(targetWebhooks) do
                    if existingUrl == url then isDuplicate = true break end
                end
                if not isDuplicate then targetWebhooks[#targetWebhooks + 1] = url end
            end
        end
    elseif type(config.identityWebhook2) == 'string' and config.identityWebhook2 ~= '' then
        local isDuplicate = false
        for _, existingUrl in ipairs(targetWebhooks) do
            if existingUrl == config.identityWebhook2 then isDuplicate = true break end
        end
        if not isDuplicate then targetWebhooks[#targetWebhooks + 1] = config.identityWebhook2 end
    end

    -- Webhook job nếu có
    if config.jobWebhooks and config.jobWebhooks[jobName] and config.jobWebhooks[jobName] ~= '' then
        local jobWh = config.jobWebhooks[jobName]
        local isDuplicate = false
        for _, existingUrl in ipairs(targetWebhooks) do
            if existingUrl == jobWh then isDuplicate = true break end
        end
        if not isDuplicate then targetWebhooks[#targetWebhooks + 1] = jobWh end
    end

    if #targetWebhooks == 0 and config.cooldownWebhook and config.cooldownWebhook ~= '' then
        targetWebhooks[#targetWebhooks + 1] = config.cooldownWebhook
    end

    if #targetWebhooks == 0 and config.discordWebhook and config.discordWebhook ~= '' then
        targetWebhooks[#targetWebhooks + 1] = config.discordWebhook
    end

    if #targetWebhooks == 0 then return end

    local bossName = bossPlayer.PlayerData.charinfo.firstname .. ' ' .. bossPlayer.PlayerData.charinfo.lastname
    local bossCid = bossPlayer.PlayerData.citizenid

    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    local targetCid = targetPlayer.PlayerData.citizenid

    local targetDiscordId = GetDiscordIdForPlayer(targetPlayer)
    local targetDiscordStr = targetDiscordId and string.format("<@%s>", targetDiscordId) or "Không có"

    local bossDiscordId = GetDiscordIdForPlayer(bossPlayer)
    local bossDiscordStr = bossDiscordId and string.format("<@%s>", bossDiscordId) or "Không có"

    local title, color, desc, actionLabel

    if actionType == 'revoke' then
        title = "🚫 THÔNG BÁO THU HỒI THẺ ĐỊNH DANH (ID CARD)"
        color = 15158332 -- Red
        actionLabel = "Thu hồi & tiêu hủy Thẻ Định Danh (id_card)"
        desc = string.format("Boss **%s** đã THU HỒI Thẻ Định Danh của người chơi **%s**", bossName, targetName)
    elseif level == 2 then
        title = "⭐ THÔNG BÁO NÂNG CẤP ĐỊNH DANH (CẤP 2)"
        color = 3066993 -- Green
        actionLabel = "Nâng cấp Định danh -> Cấp 2"
        desc = string.format("Boss **%s** đã NÂNG CẤP Định danh cho **%s** lên **Cấp 2**", bossName, targetName)
    else
        title = "🔻 THÔNG BÁO HẠ CẤP ĐỊNH DANH (CẤP 1)"
        color = 15105570 -- Orange
        actionLabel = "Hạ cấp Định danh -> Cấp 1"
        desc = string.format("Boss **%s** đã HẠ CẤP Định danh của **%s** xuống **Cấp 1**", bossName, targetName)
    end

    local embed = {
        ["title"] = title,
        ["description"] = desc,
        ["color"] = color,
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        ["footer"] = {
            ["text"] = "Hệ thống Quản lý Định Danh - QBX Management"
        },
        ["fields"] = {
            {
                ["name"] = "🏢 Cơ quan / Tổ chức",
                ["value"] = string.upper(jobLabel),
                ["inline"] = true
            },
            {
                ["name"] = "⚡ Hành động",
                ["value"] = actionLabel,
                ["inline"] = true
            },
            {
                ["name"] = "👑 Boss thực hiện",
                ["value"] = string.format("**Tên:** %s\n**Discord:** %s\n**Citizen ID:** %s", bossName, bossDiscordStr, bossCid),
                ["inline"] = false
            },
            {
                ["name"] = "👤 Người chơi liên quan",
                ["value"] = string.format("**Tên:** %s\n**Discord:** %s\n**Citizen ID:** %s", targetName, targetDiscordStr, targetCid),
                ["inline"] = false
            }
        }
    }

    local payload = json.encode({
        embeds = { embed }
    })

    for i = 1, #targetWebhooks do
        PerformHttpRequest(targetWebhooks[i], function(err, text, headers)
            if err ~= 200 and err ~= 204 then
                lib.print.error('Discord webhook error:', err, text)
            end
        end, 'POST', payload, {
            ['Content-Type'] = 'application/json'
        })
    end
end

-- Helper function kiểm tra người chơi có vật phẩm Thẻ Định Danh (id_card / idcard) trong túi đồ không
local function HasPlayerIdCard(targetSource)
    if not targetSource or targetSource <= 0 then return false end
    if GetResourceState('ox_inventory') == 'started' then
        local count1 = exports.ox_inventory:GetItemCount(targetSource, 'id_card') or 0
        local count2 = exports.ox_inventory:GetItemCount(targetSource, 'idcard') or 0
        return (count1 > 0 or count2 > 0)
    else
        local has1, has2 = false, false
        pcall(function()
            has1 = exports.qbx_core:HasItem(targetSource, 'id_card')
            has2 = exports.qbx_core:HasItem(targetSource, 'idcard')
        end)
        return (has1 or has2)
    end
end

-- Helper function để cập nhật và đồng bộ PlayerData.charinfo.dinhdanh hoàn chỉnh (RAM, StateBag, Item Metadata, Client sync & Database)
local function SetPlayerDinhDanh(targetPlayer, newLevel)
    newLevel = tonumber(newLevel)
    if not newLevel then return false end

    local source = targetPlayer.PlayerData.source
    local citizenid = targetPlayer.PlayerData.citizenid
    local currentDate = os.date('%d/%m/%Y')

    -- 1. Cập nhật cả 2 trường `dinhdanh` & `ngay_cap` trong bộ nhớ RAM của Player Object
    targetPlayer.PlayerData.charinfo.dinhdanh = newLevel
    targetPlayer.PlayerData.charinfo.ngay_cap = currentDate

    -- 2. Đồng bộ charinfo một lần qua qbx_core.
    exports.qbx_core:SetPlayerData(source, 'charinfo', targetPlayer.PlayerData.charinfo)

    -- 3. Xóa id_card cũ trong túi đồ và cấp vật phẩm id_card mới chứa metadata Cấp định danh mới & Ngày cấp
    if source and source > 0 then
        pcall(function()
            local charinfo = targetPlayer.PlayerData.charinfo
            local metadata = {
                firstname = charinfo.firstname,
                lastname = charinfo.lastname,
                birthdate = charinfo.birthdate,
                gender = charinfo.gender,
                nationality = charinfo.nationality,
                dinhdanh = newLevel,
                ngay_cap = currentDate,
                citizenid = citizenid
            }

            if GetResourceState('ox_inventory') == 'started' then
                -- Xóa id_card hoặc idcard cũ khỏi túi đồ người chơi nếu có
                local count1 = exports.ox_inventory:GetItemCount(source, 'id_card') or 0
                if count1 > 0 then
                    exports.ox_inventory:RemoveItem(source, 'id_card', count1)
                end

                local count2 = exports.ox_inventory:GetItemCount(source, 'idcard') or 0
                if count2 > 0 then
                    exports.ox_inventory:RemoveItem(source, 'idcard', count2)
                end

                -- Cấp lại vật phẩm id_card mới cùng metadata mới
                local added = exports.ox_inventory:AddItem(source, 'id_card', 1, metadata)
                if not added then
                    exports.ox_inventory:AddItem(source, 'idcard', 1, metadata)
                end
            else
                -- Fallback cho qbx_core / qb-inventory
                pcall(function()
                    exports.qbx_core:RemoveItem(source, 'id_card', 1)
                    exports.qbx_core:RemoveItem(source, 'idcard', 1)
                    exports.qbx_core:AddItem(source, 'id_card', 1, false, metadata)
                end)
            end
        end)
    end


    -- 4. Lưu trực tiếp vào cột charinfo (dạng JSON) của bảng `players` trong Database
    local charinfo = targetPlayer.PlayerData.charinfo
    charinfo.dinhdanh = newLevel
    charinfo.ngay_cap = currentDate
    MySQL.update('UPDATE `players` SET `charinfo` = ? WHERE `citizenid` = ?', { json.encode(charinfo), citizenid })

    -- 5. Gọi lệnh lưu player của qbx_core nếu có
    pcall(function()
        exports.qbx_core:SavePlayer(source)
    end)
    pcall(function()
        exports.qbx_core:Save(source)
    end)

    return true
end



-- Callback to update player's  (identity level) between 1 and 2
lib.callback.register('qbx_management:server:setIdentityLevel', function(source, targetSource, newLevel)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'police' or not player.PlayerData.job.isboss then
        exports.qbx_core:Notify(source, locale('report.must_be_boss'), 'error')
        return false
    end

    newLevel = tonumber(newLevel)
    if not newLevel or newLevel < 1 or newLevel > 2 then
        exports.qbx_core:Notify(source, 'Cấp định danh không hợp lệ (min 1, max 2)!', 'error')
        return false
    end

    local target = exports.qbx_core:GetPlayer(targetSource)
    if not target then
        exports.qbx_core:Notify(source, locale('error.not_around'), 'error')
        return false
    end

    local currentLevel = tonumber(target.PlayerData.charinfo.dinhdanh) or 1
    if currentLevel == newLevel then
        exports.qbx_core:Notify(source, string.format('Người chơi đã ở Định danh Cấp %d rồi!', newLevel), 'error')
        return false
    end

    if not HasPlayerIdCard(targetSource) then
        exports.qbx_core:Notify(source, 'Bắt buộc người chơi phải có Thẻ Định Danh (id_card) trong túi đồ mới được thay đổi cấp định danh!', 'error')
        return false
    end

    SetPlayerDinhDanh(target, newLevel)


    local bossName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname

    exports.qbx_core:Notify(source, string.format('Đã thay đổi Cấp định danh của %s thành Cấp %d', targetName, newLevel), 'success')
    exports.qbx_core:Notify(target.PlayerData.source, string.format('Cấp định danh của bạn đã được %s thay đổi thành Cấp %d', bossName, newLevel), 'inform')

    logger.log({
        source = source,
        event = 'qbx_management:server:setIdentityLevel',
        message = string.format('Boss %s (%s) set identity level of %s (%s) to %d', bossName, player.PlayerData.citizenid, targetName, target.PlayerData.citizenid, newLevel),
        webhook = config.discordWebhook
    })

    -- Gửi Discord Webhook log
    sendIdentityWebhook('set_level', player, target, newLevel)

    return true
end)

-- Helper function thu hồi thẻ định danh (id_card) và chuyển định danh về Cấp 1
local function RevokePlayerIdentityCard(targetPlayer)
    local targetSource = targetPlayer.PlayerData.source
    local citizenid = targetPlayer.PlayerData.citizenid

    -- 1. Cập nhật charinfo.dinhdanh về Cấp 1 và xóa ngay_cap
    targetPlayer.PlayerData.charinfo.dinhdanh = 1
    targetPlayer.PlayerData.charinfo.ngay_cap = nil

    -- 2. Đồng bộ charinfo một lần qua qbx_core.
    exports.qbx_core:SetPlayerData(targetSource, 'charinfo', targetPlayer.PlayerData.charinfo)

    -- 3. Thu hồi và xóa toàn bộ vật phẩm id_card / idcard khỏi túi đồ người chơi
    if GetResourceState('ox_inventory') == 'started' then
        local count1 = exports.ox_inventory:GetItemCount(targetSource, 'id_card') or 0
        if count1 > 0 then
            exports.ox_inventory:RemoveItem(targetSource, 'id_card', count1)
        end

        local count2 = exports.ox_inventory:GetItemCount(targetSource, 'idcard') or 0
        if count2 > 0 then
            exports.ox_inventory:RemoveItem(targetSource, 'idcard', count2)
        end
    else
        pcall(function()
            exports.qbx_core:RemoveItem(targetSource, 'id_card', 1)
            exports.qbx_core:RemoveItem(targetSource, 'idcard', 1)
        end)
    end

    -- 4. Lưu Cấp định danh vào MySQL Database
    local charinfo = targetPlayer.PlayerData.charinfo
    charinfo.dinhdanh = 1
    charinfo.ngay_cap = nil
    MySQL.update('UPDATE `players` SET `charinfo` = ? WHERE `citizenid` = ?', { json.encode(charinfo), citizenid })

    pcall(function()
        exports.qbx_core:SavePlayer(targetSource)
    end)

    return true
end

-- Callback thu hồi thẻ định danh (id_card) và chuyển định danh về Cấp 1
lib.callback.register('qbx_management:server:revokeIdentityCard', function(source, targetSource)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'police' or not player.PlayerData.job.isboss then
        exports.qbx_core:Notify(source, locale('report.must_be_boss'), 'error')
        return false
    end

    local target = exports.qbx_core:GetPlayer(targetSource)
    if not target then
        exports.qbx_core:Notify(source, locale('error.not_around'), 'error')
        return false
    end

    local bossName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname

    RevokePlayerIdentityCard(target)

    -- Thông báo cho Boss và người chơi
    exports.qbx_core:Notify(source, string.format('Đã thu hồi Thẻ Định Danh của %s', targetName), 'success')
    exports.qbx_core:Notify(targetSource, string.format('Thẻ Định Danh của bạn đã bị %s thu hồi!', bossName), 'error')

    -- Gửi Discord Webhook log
    sendIdentityWebhook('revoke', player, target, 1)

    return true
end)

-- Helper function gửi Webhook Discord cho Cấp và Thu Hồi Giấy Phép Vũ Khí (giay_phep_sung)
local function sendWeaponLicenseWebhook(actionType, bossPlayer, targetPlayer)
    local jobName = bossPlayer.PlayerData.job and bossPlayer.PlayerData.job.name or 'police'
    local jobLabel = bossPlayer.PlayerData.job and bossPlayer.PlayerData.job.label or 'Cảnh sát'

    local targetWebhooks = {}

    if type(config.weaponLicenseWebhook) == 'table' then
        for _, url in ipairs(config.weaponLicenseWebhook) do
            if url and url ~= '' then
                targetWebhooks[#targetWebhooks + 1] = url
            end
        end
    elseif type(config.weaponLicenseWebhook) == 'string' and config.weaponLicenseWebhook ~= '' then
        targetWebhooks[#targetWebhooks + 1] = config.weaponLicenseWebhook
    end

    if #targetWebhooks == 0 then
        if type(config.identityWebhook) == 'string' and config.identityWebhook ~= '' then
            targetWebhooks[#targetWebhooks + 1] = config.identityWebhook
        elseif config.jobWebhooks and config.jobWebhooks[jobName] and config.jobWebhooks[jobName] ~= '' then
            targetWebhooks[#targetWebhooks + 1] = config.jobWebhooks[jobName]
        elseif config.cooldownWebhook and config.cooldownWebhook ~= '' then
            targetWebhooks[#targetWebhooks + 1] = config.cooldownWebhook
        elseif config.discordWebhook and config.discordWebhook ~= '' then
            targetWebhooks[#targetWebhooks + 1] = config.discordWebhook
        end
    end

    if #targetWebhooks == 0 then return end

    local bossName = bossPlayer.PlayerData.charinfo.firstname .. ' ' .. bossPlayer.PlayerData.charinfo.lastname
    local bossCid = bossPlayer.PlayerData.citizenid

    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    local targetCid = targetPlayer.PlayerData.citizenid
    local targetDinhDanh = tonumber(targetPlayer.PlayerData.charinfo.dinhdanh) or 1

    local targetDiscordId = GetDiscordIdForPlayer(targetPlayer)
    local targetDiscordStr = targetDiscordId and string.format("<@%s>", targetDiscordId) or "Không có"

    local bossDiscordId = GetDiscordIdForPlayer(bossPlayer)
    local bossDiscordStr = bossDiscordId and string.format("<@%s>", bossDiscordId) or "Không có"

    local title, color, desc, actionLabel

    if actionType == 'revoke' then
        title = "🚫 THÔNG BÁO THU HỒI GIẤY PHÉP VŨ KHÍ"
        color = 15158332 -- Red
        actionLabel = "Thu hồi & tiêu hủy Giấy phép vũ khí (giay_phep_sung)"
        desc = string.format("Boss Cảnh sát **%s** đã THU HỒI Giấy phép vũ khí của **%s**", bossName, targetName)
    else
        title = "🔫 THÔNG BÁO CẤP GIẤY PHÉP VŨ KHÍ (GIAY_PHEP_SUNG)"
        color = 3066993 -- Green
        actionLabel = "Cấp Giấy phép vũ khí (giay_phep_sung)"
        desc = string.format("Boss Cảnh sát **%s** đã CẤP Giấy phép vũ khí cho **%s** (Định danh Cấp %d)", bossName, targetName, targetDinhDanh)
    end

    local embed = {
        ["title"] = title,
        ["description"] = desc,
        ["color"] = color,
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        ["footer"] = {
            ["text"] = "Hệ thống Quản lý Cấp Giấy Phép Vũ Khí - QBX Management"
        },
        ["fields"] = {
            {
                ["name"] = "🏢 Cơ quan thực hiện",
                ["value"] = string.upper(jobLabel),
                ["inline"] = true
            },
            {
                ["name"] = "⚡ Hành động",
                ["value"] = actionLabel,
                ["inline"] = true
            },
            {
                ["name"] = "🆔 Định danh đối tượng",
                ["value"] = string.format("Cấp %d (Bắt buộc Cấp 2)", targetDinhDanh),
                ["inline"] = true
            },
            {
                ["name"] = "👑 Cảnh sát thực hiện",
                ["value"] = string.format("**Tên:** %s\n**Discord:** %s\n**Citizen ID:** %s", bossName, bossDiscordStr, bossCid),
                ["inline"] = false
            },
            {
                ["name"] = "👤 Người chơi được cấp / thu hồi",
                ["value"] = string.format("**Tên:** %s\n**Discord:** %s\n**Citizen ID:** %s", targetName, targetDiscordStr, targetCid),
                ["inline"] = false
            }
        }
    }

    local payload = json.encode({
        embeds = { embed }
    })

    for i = 1, #targetWebhooks do
        PerformHttpRequest(targetWebhooks[i], function(err, text, headers)
            if err ~= 200 and err ~= 204 then
                lib.print.error('Discord webhook error:', err, text)
            end
        end, 'POST', payload, {
            ['Content-Type'] = 'application/json'
        })
    end
end


-- Callback cấp Giấy phép vũ khí (giay_phep_sung)
lib.callback.register('qbx_management:server:grantWeaponLicense', function(source, targetSource)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'police' or not player.PlayerData.job.isboss then
        exports.qbx_core:Notify(source, locale('report.must_be_boss'), 'error')
        return false
    end

    local target = exports.qbx_core:GetPlayer(targetSource)
    if not target then
        exports.qbx_core:Notify(source, locale('error.not_around'), 'error')
        return false
    end

    local currentLevel = tonumber(target.PlayerData.charinfo.dinhdanh) or 1
    if currentLevel ~= 2 then
        exports.qbx_core:Notify(source, 'Yêu cầu người chơi phải có CCCD Định danh Cấp 2 mới được cấp Giấy phép vũ khí!', 'error')
        return false
    end

    if not HasPlayerIdCard(targetSource) then
        exports.qbx_core:Notify(source, 'Bắt buộc người chơi phải mang Thẻ Định Danh (id_card) trong túi đồ mới được cấp Giấy phép vũ khí!', 'error')
        return false
    end

    local bossName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname
    local citizenid = target.PlayerData.citizenid
    local currentDate = os.date('%d/%m/%Y')

    -- 1. Cập nhật metadata licences/licenses
    target.PlayerData.metadata = target.PlayerData.metadata or {}
    local metadataLicences = target.PlayerData.metadata.licences or {}
    metadataLicences.weapon = true
    target.PlayerData.metadata.licences = metadataLicences

    local metadataLicenses = target.PlayerData.metadata.licenses or {}
    metadataLicenses.weapon = true
    target.PlayerData.metadata.licenses = metadataLicenses

    if target.Functions and target.Functions.SetMetaData then
        target.Functions.SetMetaData('licences', metadataLicences)
        target.Functions.SetMetaData('licenses', metadataLicenses)
    end
    pcall(function()
        exports.qbx_core:SetMetaData(targetSource, 'licences', metadataLicences)
    end)
    pcall(function()
        exports.qbx_core:SetMetaData(targetSource, 'licenses', metadataLicenses)
    end)

    -- 2. Cấp vật phẩm giay_phep_sung vào túi đồ với đầy đủ metadata
    local itemMeta = {
        name = targetName,
        firstname = target.PlayerData.charinfo.firstname,
        lastname = target.PlayerData.charinfo.lastname,
        ten_nguoi_nhan = targetName,
        ten_nguoi_cap = bossName,
        issued_by = bossName,
        citizenid = citizenid,
        ngay_cap = currentDate,
        birthdate = target.PlayerData.charinfo.birthdate,
        gender = target.PlayerData.charinfo.gender,
        nationality = target.PlayerData.charinfo.nationality,
        description = string.format("Người nhận: %s\nCitizenID: %s\nNgười cấp: %s\nNgày cấp: %s", targetName, citizenid, bossName, currentDate)
    }

    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:AddItem(targetSource, 'giay_phep_sung', 1, itemMeta)
    else
        pcall(function()
            exports.qbx_core:AddItem(targetSource, 'giay_phep_sung', 1, false, itemMeta)
        end)
    end

    -- 3. Thông báo
    exports.qbx_core:Notify(source, string.format('Đã cấp Giấy phép vũ khí (giay_phep_sung) cho %s', targetName), 'success')
    exports.qbx_core:Notify(targetSource, string.format('Bạn đã được Cảnh sát %s cấp Giấy phép vũ khí!', bossName), 'success')

    -- 4. Log Discord Webhook & System log
    logger.log({
        source = source,
        event = 'qbx_management:server:grantWeaponLicense',
        message = string.format('Boss %s (%s) granted weapon license (giay_phep_sung) to %s (%s)', bossName, player.PlayerData.citizenid, targetName, citizenid),
        webhook = config.discordWebhook
    })

    sendWeaponLicenseWebhook('grant', player, target)

    return true
end)

-- Callback thu hồi Giấy phép vũ khí (giay_phep_sung)
lib.callback.register('qbx_management:server:revokeWeaponLicense', function(source, targetSource)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'police' or not player.PlayerData.job.isboss then
        exports.qbx_core:Notify(source, locale('report.must_be_boss'), 'error')
        return false
    end

    local target = exports.qbx_core:GetPlayer(targetSource)
    if not target then
        exports.qbx_core:Notify(source, locale('error.not_around'), 'error')
        return false
    end

    local bossName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    local targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname

    -- 1. Cập nhật metadata licences/licenses
    target.PlayerData.metadata = target.PlayerData.metadata or {}
    local metadataLicences = target.PlayerData.metadata.licences or {}
    metadataLicences.weapon = false
    target.PlayerData.metadata.licences = metadataLicences

    local metadataLicenses = target.PlayerData.metadata.licenses or {}
    metadataLicenses.weapon = false
    target.PlayerData.metadata.licenses = metadataLicenses

    if target.Functions and target.Functions.SetMetaData then
        target.Functions.SetMetaData('licences', metadataLicences)
        target.Functions.SetMetaData('licenses', metadataLicenses)
    end
    pcall(function()
        exports.qbx_core:SetMetaData(targetSource, 'licences', metadataLicences)
    end)
    pcall(function()
        exports.qbx_core:SetMetaData(targetSource, 'licenses', metadataLicenses)
    end)

    -- 2. Tịch thu và xóa vật phẩm giay_phep_sung khỏi túi đồ
    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:GetItemCount(targetSource, 'giay_phep_sung') or 0
        if count > 0 then
            exports.ox_inventory:RemoveItem(targetSource, 'giay_phep_sung', count)
        end
    else
        pcall(function()
            exports.qbx_core:RemoveItem(targetSource, 'giay_phep_sung', 1)
        end)
    end

    -- 3. Thông báo
    exports.qbx_core:Notify(source, string.format('Đã thu hồi Giấy phép vũ khí của %s', targetName), 'success')
    exports.qbx_core:Notify(targetSource, string.format('Giấy phép vũ khí của bạn đã bị Cảnh sát %s thu hồi!', bossName), 'error')

    -- 4. Log Discord Webhook & System log
    logger.log({
        source = source,
        event = 'qbx_management:server:revokeWeaponLicense',
        message = string.format('Boss %s (%s) revoked weapon license from %s (%s)', bossName, player.PlayerData.citizenid, targetName, target.PlayerData.citizenid),
        webhook = config.discordWebhook
    })

    sendWeaponLicenseWebhook('revoke', player, target)

    return true
end)





---@param employeeCitizenId string
---@diagnostic disable-next-line: undefined-doc-name
---@param boss Player | table
---@param groupName string
---@param groupType GroupType
---@return boolean success
local function fireEmployee(employeeCitizenId, boss, groupName, groupType)
    local employee = exports.qbx_core:GetPlayerByCitizenId(employeeCitizenId) or exports.qbx_core:GetOfflinePlayer(employeeCitizenId)

    if employee.PlayerData.citizenid == boss.PlayerData.citizenid then
        local message = groupType == 'gang' and locale('error.kick_yourself') or locale('error.fire_yourself')
        exports.qbx_core:Notify(boss.PlayerData.source, message, 'error')
        return false
    end

    if not employee then
        exports.qbx_core:Notify(boss.PlayerData.source, locale('error.person_doesnt_exist'), 'error')
        return false
    end

    local employeeGrade = groupType == 'job' and employee.PlayerData.jobs?[groupName] or employee.PlayerData.gangs?[groupName]
    local bossGrade = groupType == 'job' and boss.PlayerData.jobs?[groupName] or boss.PlayerData.gangs?[groupName]

    if employeeGrade >= bossGrade then
        exports.qbx_core:Notify(boss.PlayerData.source, locale('error.fire_boss'), 'error')
        return false
    end

    if groupType == 'job' then
        local success, errorResult = exports.qbx_core:RemovePlayerFromJob(employee.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    else
        local success, errorResult = exports.qbx_core:RemovePlayerFromGang(employee.PlayerData.citizenid, groupName)
        assert(success, errorResult?.message)
    end

    if not employee.Offline then
        local message = groupType == 'gang' and locale('error.you_gang_fired', GANGS[groupName].label) or locale('error.you_job_fired', JOBS[groupName].label)
        exports.qbx_core:Notify(employee.PlayerData.source, message, 'error')
    end

    logger.log({
        source = boss.PlayerData.source,
        event = 'qbx_management:server:fireEmployee',
        message = locale('logs.fired_employee', employeeCitizenId, groupName, groupType),
        webhook = config.discordWebhook
    })

    return true
end

-- Callback for firing a player from a given society.
---@param employee string citizenid of employee to be fired
---@param groupType GroupType
lib.callback.register('qbx_management:server:fireEmployee', function(source, employee, groupType)
    local player = exports.qbx_core:GetPlayer(source)
    local firedEmployee = exports.qbx_core:GetPlayerByCitizenId(employee) or exports.qbx_core:GetOfflinePlayer(employee)
    local playerFullName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local organizationLabel = player.PlayerData[groupType].label

    if not player.PlayerData[groupType].isboss then return end
    if not firedEmployee then lib.print.error("not able to find player with citizenid", employee) return end

    local success = fireEmployee(employee, player, player.PlayerData[groupType].name, groupType)
    local employeeFullName = firedEmployee.PlayerData.charinfo.firstname..' '..firedEmployee.PlayerData.charinfo.lastname

    if success then
        local logArea = groupType == 'gang' and 'Gang' or 'Boss'
        local logType = groupType == 'gang' and locale('error.gang_fired') or locale('error.job_fired')
        exports.qbx_core:Notify(source, logType, 'success')
        logger.log({
            source = source,
            event = 'qbx_management:server:fireEmployee',
            message = locale('logs.fired_employee_success', logArea, playerFullName, employeeFullName, organizationLabel),
            webhook = config.discordWebhook
        })
    else
        exports.qbx_core:Notify(source, locale('error.unable_fire'), 'error')
    end
end)

-- Helper function gửi Webhook Discord cho Cooldown/Đình chỉ (Không dùng vòng lặp)
local function sendCooldownWebhook(jobName, fireType, reason, bossPlayer, employeePlayer, expireTime, days)
    local targetWebhooks = {}

    if config.cooldownWebhook and config.cooldownWebhook ~= '' then
        targetWebhooks[#targetWebhooks + 1] = config.cooldownWebhook
    end

    if config.jobWebhooks and config.jobWebhooks[jobName] and config.jobWebhooks[jobName] ~= '' then
        if config.jobWebhooks[jobName] ~= config.cooldownWebhook then
            targetWebhooks[#targetWebhooks + 1] = config.jobWebhooks[jobName]
        end
    end

    if #targetWebhooks == 0 and config.discordWebhook and config.discordWebhook ~= '' then
        targetWebhooks[#targetWebhooks + 1] = config.discordWebhook
    end

    if #targetWebhooks == 0 then return end

    local isBlacklist = fireType == 'blacklist'
    local title = isBlacklist and '⛔ THÔNG BÁO ĐÌNH CHỈ NHÂN VIÊN (BLACKLIST)' or '📋 THÔNG BÁO CHO NGHỈ VIỆC (THÔNG THƯỜNG)'
    local color = isBlacklist and 10038562 or 16744192
    local expireDateStr = os.date("%d/%m/%Y %H:%M", expireTime)

    local bossName = bossPlayer.PlayerData.charinfo.firstname .. ' ' .. bossPlayer.PlayerData.charinfo.lastname
    local bossCid = bossPlayer.PlayerData.citizenid
    local bossGradeLevel = bossPlayer.PlayerData.job and bossPlayer.PlayerData.job.grade and bossPlayer.PlayerData.job.grade.level or 0
    local bossGradeName = JOBS[jobName] and JOBS[jobName].grades and JOBS[jobName].grades[bossGradeLevel] and JOBS[jobName].grades[bossGradeLevel].name or 'Boss'

    local empName = employeePlayer.PlayerData.charinfo.firstname .. ' ' .. employeePlayer.PlayerData.charinfo.lastname
    local empCid = employeePlayer.PlayerData.citizenid
    local empGradeLevel = (employeePlayer.PlayerData.jobs and employeePlayer.PlayerData.jobs[jobName]) or (employeePlayer.PlayerData.job and employeePlayer.PlayerData.job.grade and employeePlayer.PlayerData.job.grade.level) or 0
    local empGradeName = JOBS[jobName] and JOBS[jobName].grades and JOBS[jobName].grades[empGradeLevel] and JOBS[jobName].grades[empGradeLevel].name or 'Nhân viên'

    local empDiscordId = GetDiscordIdForPlayer(employeePlayer)
    local empDiscordStr = empDiscordId and string.format("<@%s>", empDiscordId) or "Không có"

    local embed = {
        ["title"] = title,
        ["color"] = color,
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        ["footer"] = {
            ["text"] = "Hệ thống Quản lý Ban Ngành - QBX Management"
        },
        ["fields"] = {
            {
                ["name"] = "🏢 Ban ngành",
                ["value"] = string.upper(JOBS[jobName] and JOBS[jobName].label or jobName),
                ["inline"] = true
            },
            {
                ["name"] = "📋 Hình thức",
                ["value"] = isBlacklist and "Đình chỉ (Blacklist)" or "Nghỉ việc (Thông thường)",
                ["inline"] = true
            },
            {
                ["name"] = "👮 Người thực hiện sa thải",
                ["value"] = string.format("**Tên:** %s\n**Citizen ID:** %s\n**Chức vụ:** %s", bossName, bossCid, bossGradeName),
                ["inline"] = false
            },
            {
                ["name"] = "👤 Nhân viên bị sa thải",
                ["value"] = string.format("**Tên:** %s\n**Discord:** %s\n**Citizen ID:** %s\n**Chức vụ:** %s", empName, empDiscordStr, empCid, empGradeName),
                ["inline"] = false
            },
            {
                ["name"] = "📝 Lý do sa thải / đình chỉ",
                ["value"] = (reason and reason ~= '') and reason or "Không có",
                ["inline"] = false
            },
            {
                ["name"] = "⏳ Thời hạn Cooldown ban ngành",
                ["value"] = string.format("**%d ngày** (Được gia nhập lại sau: `%s`)", days, expireDateStr),
                ["inline"] = false
            }
        }
    }

    local contentMsg = empDiscordId and string.format("@everyone 🔔 <@%s> Bạn đã bị sa thải/đình chỉ khỏi ban ngành!", empDiscordId) or "@everyone"

    local payload = json.encode({
        content = contentMsg,
        embeds = { embed }
    })

    for i = 1, #targetWebhooks do
        PerformHttpRequest(targetWebhooks[i], function(err, text, headers)
            if err ~= 200 and err ~= 204 then
                lib.print.error('Discord webhook error:', err, text)
            end
        end, 'POST', payload, {
            ['Content-Type'] = 'application/json'
        })
    end
end

-- Callback cho sa thải có Cooldown/Đình chỉ
lib.callback.register('qbx_management:server:fireEmployeeWithCooldown', function(source, employeeCitizenId, groupType, fireType, reason)
    local player = exports.qbx_core:GetPlayer(source)
    local firedEmployee = exports.qbx_core:GetPlayerByCitizenId(employeeCitizenId) or exports.qbx_core:GetOfflinePlayer(employeeCitizenId)

    if not player.PlayerData[groupType].isboss then return false end
    if not firedEmployee then
        exports.qbx_core:Notify(source, locale('error.person_doesnt_exist'), 'error')
        return false
    end

    local jobName = player.PlayerData[groupType].name
    local bossFullName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname

    local success = fireEmployee(employeeCitizenId, player, jobName, groupType)
    if not success then return false end

    if groupType == 'job' and config.cooldownJobs and config.cooldownJobs[jobName] then
        local days = (config.cooldownDurations and config.cooldownDurations[fireType]) or (fireType == 'blacklist' and 15 or 3)
        local expireTime = os.time() + (days * 86400)

        AddJobCooldown(employeeCitizenId, jobName, fireType, reason, player.PlayerData.citizenid, bossFullName, expireTime)
        sendCooldownWebhook(jobName, fireType, reason, player, firedEmployee, expireTime, days)
    end

    local logType = locale('error.job_fired')
    exports.qbx_core:Notify(source, logType, 'success')
    return true
end)

---Creates a boss zone for the specified group
---@param menuInfo MenuInfo
local function registerBossMenu(menuInfo)
    menus[#menus + 1] = menuInfo
    TriggerClientEvent('qbx_management:client:bossMenuRegistered', -1, menuInfo)
    logger.log({
        source = 'qbx_management',
        event = 'qbx_management:server:registerBossMenu',
        message = locale('logs.registered_boss_menu', menuInfo.groupName),
        webhook = config.discordWebhook
    })
end

exports('RegisterBossMenu', registerBossMenu)

---@param source number
---@param citizenid string
---@param job string
local function doPlayerCheckIn(source, citizenid, job)
    playersClockedIn[source] = { citizenid = citizenid, job = job, time = os.time() }
    logger.log({
        source = source,
        event = 'qbx_management:server:doPlayerCheckIn',
        message = locale('logs.player_checkin', citizenid, job),
        webhook = config.discordWebhook
    })
end

---@param source number
local function onPlayerUnload(source)
    if playersClockedIn[source] then
        OnPlayerCheckOut(playersClockedIn[source])
        playersClockedIn[source] = nil
        logger.log({
            source = source,
            event = 'qbx_management:server:onPlayerUnload',
            message = locale('logs.player_unload', source),
            webhook = config.discordWebhook
        })
    end
end

---@param source number
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local player = exports.qbx_core:GetPlayer(source)
    if player == nil then return end
    if player.PlayerData.job.onduty then
        doPlayerCheckIn(player.PlayerData.source, player.PlayerData.citizenid, player.PlayerData.job.name)
    end
end)

---@param source number
---@param job table?
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    if playersClockedIn[source] then
        onPlayerUnload(source)
    end
    local player = exports.qbx_core:GetPlayer(source)
    if player == nil then return end
    if player.PlayerData.job.onduty then
        doPlayerCheckIn(player.PlayerData.source, player.PlayerData.citizenid, job.name)
    end
end)

---@param source number
---@param duty boolean
AddEventHandler('QBCore:Server:SetDuty', function(source, duty)
    local player = exports.qbx_core:GetPlayer(source)
    if player == nil then return end
    if duty then
        doPlayerCheckIn(player.PlayerData.source, player.PlayerData.citizenid, player.PlayerData.job.name)
    else
        onPlayerUnload(player.PlayerData.source)
    end
end)

---@param source number
AddEventHandler('QBCore:Server:OnPlayerUnload', function()
    onPlayerUnload(source)
end)

---@param source number
AddEventHandler('playerDropped', function()
    onPlayerUnload(source)
end)

-- Hàm gửi báo cáo tổng kết nhân viên lên Discord
---@param source number
---@param jobName string
local function sendEmployeeReportToDiscord(source, jobName)
    local player = exports.qbx_core:GetPlayer(source)

    if not player then return end

    if player.PlayerData.job.name ~= jobName then
        exports.qbx_core:Notify(source, 'Bạn không thuộc công việc này!', 'error')
        return
    end

    local webhook = config.jobWebhooks[jobName]
    if not webhook or webhook == '' then
        exports.qbx_core:Notify(source, 'Chưa cấu hình webhook Discord cho công việc này!', 'error')
        return
    end

    -- Lấy danh sách nhân viên
    local menuEntries = getMenuEntries(jobName, 'job')

    if #menuEntries == 0 then
        exports.qbx_core:Notify(source, 'Không có nhân viên nào trong danh sách!', 'error')
        return
    end

    -- Sắp xếp theo số giờ làm việc giảm dần
    table.sort(menuEntries, function(a, b)
        local hoursA = tonumber(a.hours) or 0
        local hoursB = tonumber(b.hours) or 0
        return hoursA > hoursB
    end)

    -- Tính tổng trước
    local totalHours = 0
    local activeEmployees = 0
    for i = 1, #menuEntries do
        local hours = tonumber(menuEntries[i].hours) or 0
        totalHours = totalHours + hours
        if hours > 0 then
            activeEmployees = activeEmployees + 1
        end
    end

    -- Tạo embeds (Discord giới hạn 25 fields/embed, nên chia nhỏ)
    local embeds = {}
    local maxFieldsPerEmbed = 24 -- Giữ 1 slot cho thống kê
    local currentEmbed = nil
    local embedCount = 0

    for i = 1, #menuEntries do
        local entry = menuEntries[i]
        local hours = tonumber(entry.hours) or 0

        -- Tạo embed mới nếu cần
        if (i - 1) % maxFieldsPerEmbed == 0 then
            embedCount = embedCount + 1
            currentEmbed = {
                ["title"] = embedCount == 1 and ("📊 BÁO CÁO TỔNG KẾT NHÂN VIÊN - " .. string.upper(JOBS[jobName] and JOBS[jobName].label or jobName)) or ("📋 DANH SÁCH NHÂN VIÊN (Trang " .. embedCount .. ")"),
                ["description"] = embedCount == 1 and "Tổng số giờ làm việc trong 7 ngày qua" or nil,
                ["color"] = 3447003,
                ["timestamp"] = embedCount == 1 and os.date("!%Y-%m-%dT%H:%M:%SZ") or nil,
                ["footer"] = embedCount == 1 and {
                    ["text"] = "Người tạo: " .. player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
                } or nil,
                ["fields"] = {}
            }
            embeds[#embeds + 1] = currentEmbed

            -- Thêm thống kê vào embed đầu tiên
            if embedCount == 1 then
                currentEmbed["fields"][#currentEmbed["fields"] + 1] = {
                    ["name"] = "📈 THỐNG KÊ TỔNG QUAN",
                    ["value"] = string.format("**Tổng nhân viên:** %d\n**Nhân viên tích cực:** %d\n**Tổng giờ làm:** %.2f giờ\n**Trung bình:** %.2f giờ/người",
                        #menuEntries, activeEmployees, totalHours, totalHours / #menuEntries),
                    ["inline"] = false
                }
            end
        end

        local status = entry.onduty and "🟢 Đang làm" or "🔴 Nghỉ"
        local gradeObj = JOBS[jobName] and JOBS[jobName].grades and (JOBS[jobName].grades[entry.grade] or JOBS[jobName].grades[tostring(entry.grade)] or JOBS[jobName].grades[tonumber(entry.grade)])
        local gradeName = gradeObj and gradeObj.name or ('Cấp ' .. tostring(entry.grade))

        currentEmbed["fields"][#currentEmbed["fields"] + 1] = {
            ["name"] = string.format("%d. %s", i, entry.name),
            ["value"] = string.format("**Cấp:** %s\n**Giờ làm:** %.2f giờ\n**Trạng thái:** %s\n**Lần cuối:** %s",
                gradeName, hours, status, entry.last_checkin or "N/A"),
            ["inline"] = true
        }
    end

    -- Gửi lên Discord
    PerformHttpRequest(webhook, function(err, text, headers)
        if err == 200 or err == 204 then
            exports.qbx_core:Notify(source, 'Đã gửi báo cáo tổng kết lên Discord!', 'success')
        else
            exports.qbx_core:Notify(source, 'Lỗi khi gửi báo cáo lên Discord! Mã lỗi: ' .. tostring(err), 'error')
            lib.print.error('Discord webhook error:', err, text)
        end
    end, 'POST', json.encode({
        content = "@everyone",
        embeds = embeds
    }), {
        ['Content-Type'] = 'application/json'
    })
end

-- Command /tongket cho Police
lib.addCommand('tongket', {
    help = 'Gửi báo cáo tổng kết nhân viên lên Discord (Police & Ambulance Boss)',
    restricted = false,
}, function(source)
    local player = exports.qbx_core:GetPlayer(source)

    if not player then return end

    local jobName = player.PlayerData.job.name
    local jobGrade = player.PlayerData.job.grade.level

    -- Chỉ cho phép Police và Ambulance
    if jobName ~= 'police' and jobName ~= 'ambulance' then
        exports.qbx_core:Notify(source, 'Lệnh này chỉ dành cho Police hoặc Ambulance!', 'error')
        return
    end

    -- Kiểm tra cấp bậc theo từng job
    local requiredGrade = {
        police = 10,
        ambulance = 9
    }

    if jobGrade < requiredGrade[jobName] then
        exports.qbx_core:Notify(source, string.format('Bạn cần đạt cấp bậc %d trở lên để sử dụng lệnh này!', requiredGrade[jobName]), 'error')
        return
    end

    sendEmployeeReportToDiscord(source, jobName)
end)

-- Callback lấy danh sách Cooldown/Countdown cho Admin
lib.callback.register('qbx_management:server:getAdminCooldownList', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end

    local activeCooldowns = GetAllActiveCooldowns()
    local result = {}

    for i = 1, #activeCooldowns do
        local item = activeCooldowns[i]
        local empPlayer = exports.qbx_core:GetPlayerByCitizenId(item.citizenid) or exports.qbx_core:GetOfflinePlayer(item.citizenid)
        local empName = empPlayer and (empPlayer.PlayerData.charinfo.firstname .. ' ' .. empPlayer.PlayerData.charinfo.lastname) or 'N/A'
        local jobLabel = JOBS[item.job] and JOBS[item.job].label or item.job

        local remaining = item.expire_time - os.time()
        if remaining < 0 then remaining = 0 end
        local daysLeft = math.floor(remaining / 86400)
        local hoursLeft = math.floor((remaining % 86400) / 3600)
        local minsLeft = math.floor((remaining % 3600) / 60)

        result[#result + 1] = {
            id = item.id,
            citizenid = item.citizenid,
            job = item.job,
            jobLabel = jobLabel,
            fire_type = item.fire_type,
            reason = item.reason,
            firedBy = item.fired_by,
            firedByName = item.fired_by_name,
            expire_time = item.expire_time,
            expireDateStr = os.date("%d/%m/%Y %H:%M", item.expire_time),
            createdAtStr = item.created_at and tostring(item.created_at) or 'N/A',
            playerName = empName,
            daysLeft = daysLeft,
            hoursLeft = hoursLeft,
            minsLeft = minsLeft
        }
    end

    return result
end)

-- Helper function gửi Webhook Log khi Admin Hủy/Gỡ Countdown
local function sendRemoveCooldownWebhook(adminPlayer, targetCitizenId, cooldownData, removeReason)
    local webhook = config.removeCooldownWebhook or config.cooldownWebhook or config.discordWebhook
    if not webhook or webhook == '' then return end

    local adminName = adminPlayer.PlayerData.charinfo.firstname .. ' ' .. adminPlayer.PlayerData.charinfo.lastname
    local adminCid = adminPlayer.PlayerData.citizenid

    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetCitizenId) or exports.qbx_core:GetOfflinePlayer(targetCitizenId)
    local targetName = targetPlayer and (targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname) or 'N/A'

    local jobName = cooldownData and cooldownData.job or 'N/A'
    local jobLabel = JOBS[jobName] and JOBS[jobName].label or jobName
    local fireType = cooldownData and cooldownData.fire_type
    local fireTypeLabel = fireType == 'blacklist' and 'Đình chỉ (Blacklist)' or 'Nghỉ việc (Thông thường)'
    local reason = cooldownData and cooldownData.reason or 'Không có'
    local expireTimeStr = cooldownData and cooldownData.expire_time and os.date("%d/%m/%Y %H:%M", cooldownData.expire_time) or 'N/A'
    local cleanRemoveReason = (removeReason and removeReason ~= '') and removeReason or 'Không có'

    local embed = {
        ["title"] = "🔓 THÔNG BÁO HỦY COUNTDOWN BAN NGÀNH",
        ["color"] = 3066993,
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        ["footer"] = {
            ["text"] = "Hệ thống Quản lý Ban Ngành - QBX Management"
        },
        ["fields"] = {
            {
                ["name"] = "👑 Admin thực hiện gỡ",
                ["value"] = string.format("**Tên:** %s\n**Citizen ID:** %s", adminName, adminCid),
                ["inline"] = false
            },
            {
                ["name"] = "👤 Người chơi được gỡ",
                ["value"] = string.format("**Tên:** %s\n**Citizen ID:** %s", targetName, targetCitizenId),
                ["inline"] = false
            },
            {
                ["name"] = "✏️ Lý do gỡ Countdown",
                ["value"] = cleanRemoveReason,
                ["inline"] = false
            },
            {
                ["name"] = "🏢 Ban ngành",
                ["value"] = string.upper(jobLabel),
                ["inline"] = true
            },
            {
                ["name"] = "📋 Hình thức ban đầu",
                ["value"] = fireTypeLabel,
                ["inline"] = true
            },
            {
                ["name"] = "📝 Lý do sa thải ban đầu",
                ["value"] = (reason and reason ~= '') and reason or "Không có",
                ["inline"] = false
            },
            {
                ["name"] = "⏳ Thời gian hết hạn ban đầu",
                ["value"] = expireTimeStr,
                ["inline"] = false
            }
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            lib.print.error('Discord remove cooldown webhook error:', err, text)
        end
    end, 'POST', json.encode({
        content = string.format("@everyone 🔓 Admin **%s** đã HỦY COUNTDOWN cho người chơi **%s** (%s)!\n**Lý do gỡ:** %s", adminName, targetName, targetCitizenId, cleanRemoveReason),
        embeds = { embed }
    }), {
        ['Content-Type'] = 'application/json'
    })
end

-- Callback xóa Cooldown cho Admin
lib.callback.register('qbx_management:server:removeCooldown', function(source, cooldownId, targetCitizenId, removeReason)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    -- Lấy thông tin cooldown trước khi xóa để gửi log
    local cooldownData = MySQL.single.await('SELECT * FROM `player_job_cooldowns` WHERE `id` = ? LIMIT 1', { cooldownId })

    local affectedRows = RemoveJobCooldown(cooldownId)
    if affectedRows and affectedRows > 0 then
        exports.qbx_core:Notify(source, string.format('Đã xóa Countdown cho CitizenID: %s', targetCitizenId), 'success')

        local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetCitizenId)
        if targetPlayer then
            local reasonText = (removeReason and removeReason ~= '') and (' | Lý do: ' .. removeReason) or ''
            exports.qbx_core:Notify(targetPlayer.PlayerData.source, 'Countdown ban ngành của bạn đã được Admin xóa!' .. reasonText, 'success')
        end

        -- Gửi Webhook Log
        sendRemoveCooldownWebhook(player, targetCitizenId, cooldownData, removeReason)

        return true
    else
        exports.qbx_core:Notify(source, 'Không thể xóa Countdown hoặc dữ liệu đã bị xóa trước đó!', 'error')
        return false
    end
end)

-- Command cho Admin mở bảng menu Countdown
lib.addCommand('cooldownlist', {
    help = 'Mở bảng danh sách người chơi đang bị Countdown / Cooldown (Admin)',
    restricted = 'group.admin',
}, function(source)
    TriggerClientEvent('qbx_management:client:openAdminCooldownMenu', source)
end)

lib.addCommand('cooldowns', {
    help = 'Mở bảng danh sách người chơi đang bị Countdown / Cooldown (Admin)',
    restricted = 'group.admin',
}, function(source)
    TriggerClientEvent('qbx_management:client:openAdminCooldownMenu', source)
end)

-- Command cho Admin test Đặt/Thay đổi Cấp định danh  bản thân hoặc người khác
lib.addCommand('setdinhdanh', {
    help = 'Đặt/Thay đổi Cấp định danh  cho bản thân hoặc người chơi khác (Admin)',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID người chơi (hoặc Cấp 1/2 nếu tự chọn bản thân)',
            optional = true,
        },
        {
            name = 'level',
            type = 'number',
            help = 'Cấp định danh (1 hoặc 2)',
            optional = true,
        },
    },
    restricted = 'group.admin',
}, function(source, args)
    local targetId = args.target
    local level = args.level

    -- Nếu chỉ truyền 1 tham số và đó là 1 hoặc 2, tự hiểu là đặt cấp cho bản thân (targetId = source)
    if targetId and not level and (targetId == 1 or targetId == 2) then
        level = targetId
        targetId = source
    elseif not targetId then
        targetId = source
    end

    if not level then
        local targetPlayer = exports.qbx_core:GetPlayer(targetId)
        if not targetPlayer then
            exports.qbx_core:Notify(source, string.format('Không tìm thấy người chơi ID: %s', tostring(targetId)), 'error')
            return
        end
        local current = tonumber(targetPlayer.PlayerData.charinfo.dinhdanh) or 1
        local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
        exports.qbx_core:Notify(source, string.format('📌 Cấp định danh hiện tại của %s (ID: %d) là: Cấp %d', targetName, targetId, current), 'inform')
        return
    end

    level = tonumber(level)
    if not level or level < 1 or level > 2 then
        exports.qbx_core:Notify(source, '⚠️ Cấp định danh không hợp lệ! Vui lòng chọn 1 hoặc 2.', 'error')
        return
    end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        exports.qbx_core:Notify(source, string.format('Không tìm thấy người chơi ID: %s', tostring(targetId)), 'error')
        return
    end

    SetPlayerDinhDanh(targetPlayer, level)

    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    if source > 0 then
        exports.qbx_core:Notify(source, string.format('✅ [Admin] Đã đổi Cấp định danh của %s (ID: %d) thành Cấp %d', targetName, targetId, level), 'success')
    else
        print(string.format('[Admin] Đã đổi Cấp định danh của %s (ID: %d) thành Cấp %d', targetName, targetId, level))
    end

    if targetId ~= source then
        exports.qbx_core:Notify(targetId, string.format('Admin đã đổi Cấp định danh của bạn thành Cấp %d', level), 'inform')
    end

    local adminPlayer = source > 0 and exports.qbx_core:GetPlayer(source) or nil
    if not adminPlayer then
        adminPlayer = {
            PlayerData = {
                source = 0,
                citizenid = "CONSOLE",
                charinfo = { firstname = "Server", lastname = "Console" },
                job = { name = "admin", label = "Server Admin" }
            }
        }
    end

    sendIdentityWebhook('set_level', adminPlayer, targetPlayer, level)

    logger.log({
        source = source,
        event = 'qbx_management:server:setdinhdanh',
        message = string.format('Admin %s (%s) set identity level of %s (ID: %d, CID: %s) to Cấp %d', adminPlayer.PlayerData.charinfo.firstname .. ' ' .. adminPlayer.PlayerData.charinfo.lastname, adminPlayer.PlayerData.citizenid, targetName, targetId, targetPlayer.PlayerData.citizenid, level),
        webhook = config.discordWebhook
    })
end)

-- Command cho Admin test Kiểm tra Cấp định danh của bản thân hoặc người khác
lib.addCommand('checkdinhdanh', {
    help = 'Kiểm tra Cấp định danh (dinhdanh) của bản thân hoặc người chơi khác (Admin)',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID người chơi (để trống nếu tự kiểm tra bản thân)',
            optional = true,
        },
    },
    restricted = 'group.admin',
}, function(source, args)
    local targetId = args.target or source
    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        exports.qbx_core:Notify(source, string.format('Không tìm thấy người chơi ID: %s', tostring(targetId)), 'error')
        return
    end
    local current = tonumber(targetPlayer.PlayerData.charinfo.dinhdanh) or 1
    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    exports.qbx_core:Notify(source, string.format('📌 Cấp định danh hiện tại của %s (ID: %d) là: Cấp %d', targetName, targetId, current), 'inform')
end)

-- Command cho Admin Thu hồi và xóa Thẻ định danh (id_card) của bản thân hoặc người chơi khác
lib.addCommand('thuhoicccd', {
    help = 'Thu hồi và xóa Thẻ định danh (id_card) của bản thân hoặc người chơi khác (Admin)',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'ID người chơi (để trống nếu tự thu hồi bản thân)',
            optional = true,
        },
    },
    restricted = 'group.admin',
}, function(source, args)
    local targetId = args.target or source
    if targetId == 0 then
        if source == 0 then
            print('Vui lòng nhập ID người chơi: /thuhoicccd [targetId]')
        end
        return
    end

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        if source > 0 then
            exports.qbx_core:Notify(source, string.format('Không tìm thấy người chơi ID: %s', tostring(targetId)), 'error')
        else
            print(string.format('Không tìm thấy người chơi ID: %s', tostring(targetId)))
        end
        return
    end

    RevokePlayerIdentityCard(targetPlayer)

    local adminPlayer = source > 0 and exports.qbx_core:GetPlayer(source) or nil
    local adminName = adminPlayer and (adminPlayer.PlayerData.charinfo.firstname .. ' ' .. adminPlayer.PlayerData.charinfo.lastname) or 'Server Console'
    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname

    if source > 0 then
        exports.qbx_core:Notify(source, string.format('✅ [Admin] Đã thu hồi Thẻ Định Danh (ID Card) của %s (ID: %d)', targetName, targetId), 'success')
    else
        print(string.format('[Admin] Đã thu hồi Thẻ Định Danh (ID Card) của %s (ID: %d)', targetName, targetId))
    end

    if targetId ~= source then
        exports.qbx_core:Notify(targetPlayer.PlayerData.source, string.format('Thẻ Định Danh (ID Card) của bạn đã bị Admin (%s) thu hồi!', adminName), 'error')
    end

    if not adminPlayer then
        adminPlayer = {
            PlayerData = {
                source = 0,
                citizenid = "CONSOLE",
                charinfo = { firstname = "Server", lastname = "Console" },
                job = { name = "admin", label = "Server Admin" }
            }
        }
    end

    sendIdentityWebhook('revoke', adminPlayer, targetPlayer, 1)

    logger.log({
        source = source,
        event = 'qbx_management:server:thuhoicccd',
        message = string.format('Admin %s (%s) revoked ID card of %s (ID: %d, CID: %s)', adminName, adminPlayer.PlayerData.citizenid, targetName, targetId, targetPlayer.PlayerData.citizenid),
        webhook = config.discordWebhook
    })
end)

