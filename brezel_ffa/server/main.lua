local lobbies = {}
local bannedPlayers = {} -- Danh sách người chơi bị kick & cấm tham gia FFA

-- Initialize Database Table if needed
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `brezel_ffa` (
            `identifier` varchar(64) NOT NULL,
            `kills` int(11) NOT NULL DEFAULT 0,
            `deaths` int(11) NOT NULL DEFAULT 0,
            `name` varchar(255) DEFAULT NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])
end)

local function InitLobbies()
    lobbies = {}
    local lobbyCount = 0
    for mapKey, mapData in pairs(BS_C.FFA.maps) do
        local dimension = math.random(100000, 999999)
        SetRoutingBucketPopulationEnabled(dimension, false)
        lobbies[mapKey] = {
            name = mapData.name,
            maxplayers = mapData.maxplayers,
            image = mapData.image,
            players = {},
            dimension = dimension,
            started = false
        }
        lobbyCount = lobbyCount + 1
    end
    print(("[^2BREZEL FFA^0] Khoi tao thanh cong %d phong FFA"):format(lobbyCount))
end

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        InitLobbies()
    end
end)

lib.callback.register('brezel_ffa:getdata', function(source)
    local topPlayers = MySQL.query.await("SELECT * FROM `brezel_ffa` ORDER BY `kills` DESC LIMIT 10") or {}
    local lobbyList = {}
    for lobbyKey, lobbyData in pairs(lobbies) do
        table.insert(lobbyList, {
            playercount = #lobbyData.players,
            maxplayers = lobbyData.maxplayers,
            image = lobbyData.image,
            name = lobbyData.name,
            key = lobbyKey,
            started = lobbyData.started
        })
    end
    return {
        topplayers = topPlayers,
        lobbys = lobbyList
    }
end)

lib.callback.register('brezel_ffa:getuserdata', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local citizenid = player.PlayerData.citizenid
    local playerName = GetPlayerName(source)

    local result = MySQL.single.await("SELECT * FROM `brezel_ffa` WHERE `identifier` = ?", { citizenid })
    if result then
        return {
            identifier = result.identifier,
            kills = tonumber(result.kills) or 0,
            deaths = tonumber(result.deaths) or 0,
            name = result.name or playerName
        }
    else
        MySQL.insert.await("INSERT INTO `brezel_ffa` (`identifier`, `kills`, `deaths`, `name`) VALUES (?, 0, 0, ?)", {
            citizenid,
            playerName
        })
        return {
            identifier = citizenid,
            kills = 0,
            deaths = 0,
            name = playerName
        }
    end
end)

lib.callback.register('brezel_ffa:join', function(source, lobbyKey)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or not lobbies[lobbyKey] then return { success = false } end

    local citizenid = player.PlayerData.citizenid
    local playerName = GetPlayerName(source)

    -- Kiểm tra nếu người chơi bị kick/cấm tham gia FFA
    if bannedPlayers[citizenid] then
        return { success = false, banned = true }
    end

    local lobby = lobbies[lobbyKey]
    if #lobby.players >= lobby.maxplayers then
        return { success = false, full = true }
    end

    local result = MySQL.single.await("SELECT * FROM `brezel_ffa` WHERE `identifier` = ?", { citizenid })
    if not result then
        MySQL.insert.await("INSERT INTO `brezel_ffa` (`identifier`, `kills`, `deaths`, `name`) VALUES (?, 0, 0, ?)", {
            citizenid,
            playerName
        })
        result = { kills = 0, deaths = 0 }
    end

    table.insert(lobby.players, {
        source = source,
        identifier = citizenid,
        name = playerName,
        kills = tonumber(result.kills) or 0,
        deaths = tonumber(result.deaths) or 0
    })

    -- Chỉ chuyển routing bucket nếu trận đấu ĐÃ BẮT ĐẦU. Khi đang chờ thì giữ ở bucket 0
    if lobby.started then
        SetPlayerRoutingBucket(source, lobby.dimension)
    else
        SetPlayerRoutingBucket(source, 0)
    end

    -- Clear any existing medical issues
    if GetResourceState('qbx_medical') == 'started' then
        pcall(function()
            exports.qbx_medical:Heal(source)
        end)
    end

    -- Notify other players in the lobby
    for _, pData in ipairs(lobby.players) do
        if pData.source ~= source then
            TriggerClientEvent('ox_lib:notify', pData.source, {
                title = 'FFA Lobby',
                description = ('%s đã tham gia phòng (%d/%d)'):format(playerName, #lobby.players, lobby.maxplayers),
                type = 'inform'
            })
        end
    end

    return {
        success = true,
        started = lobby.started,
        playerCount = #lobby.players,
        maxPlayers = lobby.maxplayers
    }
end)

local function RemovePlayerFromFFA(source)
    SetPlayerRoutingBucket(source, 0)

    for lobbyKey, lobbyData in pairs(lobbies) do
        for playerIndex, playerData in pairs(lobbyData.players) do
            if playerData.source == source then
                table.remove(lobbyData.players, playerIndex)
                if #lobbyData.players == 0 then
                    lobbyData.started = false
                end
                break
            end
        end
    end

    -- Ensure medical health is restored
    if GetResourceState('qbx_medical') == 'started' then
        pcall(function()
            exports.qbx_medical:Heal(source)
        end)
    end
end

lib.callback.register('brezel_ffa:leave', function(source)
    RemovePlayerFromFFA(source)
    return true
end)

RegisterNetEvent('brezel_ffa:server:healPlayer', function()
    local src = source
    if GetResourceState('qbx_medical') == 'started' then
        pcall(function()
            exports.qbx_medical:Heal(src)
        end)
    end
end)

RegisterNetEvent('brezel_ffa:server:revivePlayer', function()
    local src = source
    if GetResourceState('qbx_medical') == 'started' then
        pcall(function()
            exports.qbx_medical:Revive(src)
        end)
    end
end)

RegisterNetEvent('brezel_ffa:server:onDeath', function(killerServerId)
    local victimSrc = source
    local victimPlayer = exports.qbx_core:GetPlayer(victimSrc)
    if not victimPlayer then return end

    local victimCitizenId = victimPlayer.PlayerData.citizenid
    local victimName = GetPlayerName(victimSrc)

    for _, lobbyData in pairs(lobbies) do
        for _, pData in pairs(lobbyData.players) do
            if pData.source == victimSrc then
                pData.deaths = pData.deaths + 1
                MySQL.update("UPDATE `brezel_ffa` SET `deaths` = `deaths` + 1 WHERE `identifier` = ?", { victimCitizenId })

                local killerPlayer = killerServerId and exports.qbx_core:GetPlayer(killerServerId)
                if killerPlayer then
                    local killerCitizenId = killerPlayer.PlayerData.citizenid
                    local killerName = GetPlayerName(killerServerId)

                    TriggerClientEvent('brezel_ffa:client:kill', killerServerId)

                    for _, member in pairs(lobbyData.players) do
                        TriggerClientEvent('brezel_ffa:client:killmessage', member.source, killerName, victimName)
                        if member.source == killerServerId then
                            member.kills = member.kills + 1
                            MySQL.update("UPDATE `brezel_ffa` SET `kills` = `kills` + 1 WHERE `identifier` = ?", { killerCitizenId })
                        end
                    end
                else
                    for _, member in pairs(lobbyData.players) do
                        TriggerClientEvent('brezel_ffa:client:killmessage', member.source, BS_Locale("unknown"), victimName)
                    end
                end
                return
            end
        end
    end
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    RemovePlayerFromFFA(src)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, lobbyData in pairs(lobbies) do
            for _, playerData in pairs(lobbyData.players) do
                SetPlayerRoutingBucket(playerData.source, 0)
                TriggerClientEvent('brezel_ffa:client:leave', playerData.source)
            end
        end
    end
end)

-- Admin Start FFA Event Command
lib.addCommand(BS_C.StartFFACommand or 'startffa', {
    help = BS_Locale("command_start"),
    params = {
        {
            name = 'lobby',
            type = 'string',
            help = 'Lobby Key (Optional, e.g. map1)',
            optional = true,
        },
    },
    restricted = BS_C.KickFFACommandPermission or 'group.admin'
}, function(source, args)
    local targetLobbyKey = args.lobby

    if not targetLobbyKey then
        -- Find the first lobby with players
        for k, v in pairs(lobbies) do
            if #v.players > 0 then
                targetLobbyKey = k
                break
            end
        end
        -- Fallback to map1 if none found
        if not targetLobbyKey then
            targetLobbyKey = "map1"
        end
    end

    local lobby = lobbies[targetLobbyKey]
    if not lobby then
        if source > 0 then
            exports.qbx_core:Notify(source, BS_Locale("lobby_not_found"), "error")
        else
            print(BS_Locale("lobby_not_found"))
        end
        return
    end

    if #lobby.players == 0 then
        if source > 0 then
            exports.qbx_core:Notify(source, BS_Locale("no_players_in_lobby"), "error")
        else
            print(BS_Locale("no_players_in_lobby"))
        end
        return
    end

    lobby.started = true
    local countdown = BS_C.CountdownSeconds or 5

    for _, pData in ipairs(lobby.players) do
        SetPlayerRoutingBucket(pData.source, lobby.dimension)
        TriggerClientEvent('brezel_ffa:client:startMatch', pData.source, targetLobbyKey, countdown)
    end

    if source > 0 then
        exports.qbx_core:Notify(source, ("Đã bắt đầu trận đấu FFA cho phòng [%s] (%d người chơi)"):format(lobby.name, #lobby.players), "success")
    else
        print(("[BREZEL FFA] Da bat dau tran dau FFA cho phong [%s] (%d nguoi choi)"):format(lobby.name, #lobby.players))
    end
end)

-- Admin Stop FFA Event Command
lib.addCommand(BS_C.StopFFACommand or 'stopffa', {
    help = BS_Locale("command_stop"),
    params = {
        {
            name = 'lobby',
            type = 'string',
            help = 'Lobby Key (Optional, e.g. map1)',
            optional = true,
        },
    },
    restricted = BS_C.KickFFACommandPermission or 'group.admin'
}, function(source, args)
    local targetLobbyKey = args.lobby

    local function stopSingleLobby(key, lData)
        lData.started = false
        for _, pData in ipairs(lData.players) do
            SetPlayerRoutingBucket(pData.source, 0)
            TriggerClientEvent('brezel_ffa:client:leave', pData.source)
            TriggerClientEvent('ox_lib:notify', pData.source, {
                title = 'FFA Arena',
                description = BS_Locale("match_stopped"),
                type = 'warning'
            })
        end
        lData.players = {}
    end

    if targetLobbyKey and lobbies[targetLobbyKey] then
        stopSingleLobby(targetLobbyKey, lobbies[targetLobbyKey])
        if source > 0 then
            exports.qbx_core:Notify(source, ("Đã dừng phòng FFA [%s]"):format(targetLobbyKey), "success")
        end
    else
        for k, v in pairs(lobbies) do
            if #v.players > 0 or v.started then
                stopSingleLobby(k, v)
            end
        end
        if source > 0 then
            exports.qbx_core:Notify(source, "Đã dừng toàn bộ các phòng FFA đang hoạt động", "success")
        end
    end
end)

-- Admin Kick & Ban FFA Command (/kickffa [targetId])
lib.addCommand(BS_C.KickFFACommand or 'kickffa', {
    help = BS_Locale("command_kick"),
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target Player ID',
            optional = false,
        },
    },
    restricted = BS_C.KickFFACommandPermission or 'group.admin'
}, function(source, args)
    local targetSource = args.target
    if not targetSource then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetSource)
    if not targetPlayer then
        if source > 0 then
            exports.qbx_core:Notify(source, "Không tìm thấy người chơi này trên máy chủ!", "error")
        end
        return
    end

    local targetCitizenId = targetPlayer.PlayerData.citizenid
    local targetName = GetPlayerName(targetSource)

    -- Đưa vào blacklist cấm tham gia FFA
    bannedPlayers[targetCitizenId] = true

    -- Đuổi người chơi ra khỏi phòng FFA nếu đang ở trong phòng
    RemovePlayerFromFFA(targetSource)
    TriggerClientEvent('brezel_ffa:client:leave', targetSource)
    TriggerClientEvent('ox_lib:notify', targetSource, {
        title = 'FFA Arena',
        description = BS_Locale("kicked_and_banned"),
        type = 'error'
    })

    if source > 0 then
        exports.qbx_core:Notify(source, ("Đã kick và cấm người chơi [%s - ID: %d] tham gia FFA"):format(targetName, targetSource), "success")
    else
        print(("[BREZEL FFA] Da kick va cam nguoi choi [%s - ID: %d] khoi FFA"):format(targetName, targetSource))
    end
end)

-- Admin Unban FFA Command (/unkickffa [targetId])
lib.addCommand('unkickffa', {
    help = BS_Locale("command_unkick"),
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target Player ID',
            optional = false,
        },
    },
    restricted = BS_C.KickFFACommandPermission or 'group.admin'
}, function(source, args)
    local targetSource = args.target
    if not targetSource then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetSource)
    if not targetPlayer then
        if source > 0 then
            exports.qbx_core:Notify(source, "Không tìm thấy người chơi này!", "error")
        end
        return
    end

    local targetCitizenId = targetPlayer.PlayerData.citizenid
    local targetName = GetPlayerName(targetSource)

    if bannedPlayers[targetCitizenId] then
        bannedPlayers[targetCitizenId] = nil
        if source > 0 then
            exports.qbx_core:Notify(source, ("Đã gỡ cấm FFA cho người chơi [%s - ID: %d]"):format(targetName, targetSource), "success")
        end
        TriggerClientEvent('ox_lib:notify', targetSource, {
            title = 'FFA Arena',
            description = "Bạn đã được gỡ lệnh cấm tham gia đấu trường FFA.",
            type = 'success'
        })
    else
        if source > 0 then
            exports.qbx_core:Notify(source, "Người chơi này không nằm trong danh sách bị cấm FFA!", "inform")
        end
    end
end)
