-- Discord Webhook Configuration
local DISCORD_WEBHOOK = "" -- Webhook dự phòng (không dùng)
local DISCORD_WEBHOOK_RELEASE = "" -- Webhook log thả tù, chuộc tù, bảo lãnh
local DISCORD_WEBHOOK_PRISON = "" -- Webhook log phạt tù
local DISCORD_WEBHOOK_PHATTU = "https://discord.com/api/webhooks/1548261245084242032/3o75TRWXTG3WF_F5c_JBTGcU-lzkL-lVbBeQRiYS9PvQ49Yp-KVe2dK5IkjpfeqOgXZ1" -- Webhook log lệnh /phattu (admin/mod)

-- Bảng lưu player đang trong quá trình chụp ảnh mugshot (để tránh bị teleport vào tù sớm)
local playersInMugshotProcess = {}

-- Cleanup khi player thoát game (tránh bị stuck trong trạng thái mugshot)
AddEventHandler('playerDropped', function(reason)
    local src = source
    if playersInMugshotProcess[src] then
        print("^3[MUGSHOT] Player " .. src .. " disconnected during mugshot process. Cleaning up.^0")
        playersInMugshotProcess[src] = nil
    end
end)

-- Function gửi log Discord
function SendDiscordLog(title, description, color, fields, customWebhook)
    -- Kiểm tra config có bật gửi log không
    if not Config.EnableDiscordLogs then
        return
    end
    
    local webhook = customWebhook or DISCORD_WEBHOOK
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description or "",
            ["color"] = color or 15158332, -- Red color
            ["fields"] = fields or {},
            ["footer"] = {
                ["text"] = os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Prison System",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Event spawn xe tù và set bucket
RegisterNetEvent('nl_hotcut:server:startPrisonTransport', function(actionsCount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    local playerPID = Player.PlayerData.pid
    
    -- Set bucket = PID của player (mỗi người 1 bucket riêng)
    SetPlayerRoutingBucket(src, playerPID)
    
    -- Flag đã được set trước khi gọi takeMugshot rồi, không cần set lại
    
    -- Trigger client spawn xe và NPC
    TriggerClientEvent('nl_hotcut:client:prisonTransport', src, actionsCount)
end)

-- Event khi xe đến tù rồi
RegisterNetEvent('nl_hotcut:server:arrivedAtPrison', function(actionsCount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    
    -- Xóa flag mugshot process (đã hoàn thành)
    playersInMugshotProcess[src] = nil
    
    -- Đưa vào bucket tù (bucket 1)
    SetPlayerRoutingBucket(src, 1)
    
    -- Đưa vào tù
    TriggerClientEvent('esx_communityservice:inCommunityService', src, actionsCount)
end)

-- Event để set metadata injail cho player
RegisterNetEvent('nl_hotcut:server:setInjail', function(value)
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)
	if not Player then return end
	
	Player.Functions.SetMetaData('injail', value)
end)

-- Event xử lý đánh nhau trong tù
RegisterNetEvent('esx_communityservice:fightInPrison', function()
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)
	if not Player then return end
	
	local identifier = Player.PlayerData.citizenid
	local characterName = Player.PlayerData.charinfo.lastname .. " " .. Player.PlayerData.charinfo.firstname
	local PID = Player.PlayerData.pid
	
	-- Tạo routing bucket RIÊNG cho người này (random từ 2000-9999)
	-- Đảm bảo mỗi người có bucket riêng, không trùng
	local personalBucket = Config.IsolationBucketStart + math.random(1, 7999)
	
	-- Chuyển player sang routing bucket cách ly RIÊNG
	SetPlayerRoutingBucket(src, personalBucket)
	
	-- Lưu isolation_bucket cá nhân vào database (sẽ giữ cho đến khi ra tù)
	MySQL.Async.execute('UPDATE communityservice SET isolation_bucket = ? WHERE identifier = ?', {personalBucket, identifier})
	
	-- Thông báo cho player
	exports.qbx_core:Notify(src, 'Bạn bị cách ly RIÊNG cho đến khi ra tù vì đánh nhau!', 'error', 10000)
	
	-- Log Discord
	local fightLogFields = {
		{
			["name"] = "👤 Tên nhân vật",
			["value"] = characterName,
			["inline"] = false
		},
		{
			["name"] = "🆔 Player ID",
			["value"] = PID,
			["inline"] = false
		},
		{
			["name"] = "⚠️ Hình phạt",
			["value"] = "Cách ly trong thế giới riêng cho đến khi ra tù",
			["inline"] = false
		},
		{
			["name"] = "🌐 Routing Bucket",
			["value"] = "Bucket #" .. personalBucket,
			["inline"] = false
		}
	}
	
	SendDiscordLog(
		"⚔️ Đánh nhau trong tù",
		"Player được đưa đi biệt giam",
		16776960, -- Màu vàng
		fightLogFields,
		DISCORD_WEBHOOK_PRISON
	)
end)

-- Cooldown table để tránh check trùng
local checkCooldowns = {}
local COOLDOWN_TIME = 30000 -- 30 giây cooldown

-- Event khi resource restart - kiểm tra tất cả players đang online
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Đợi một chút để đảm bảo tất cả đã load xong
        Wait(5000)
        
        -- Kiểm tra tất cả players đang online
        local players = GetPlayers()
        for i = 1, #players do
            local playerId = tonumber(players[i])
            if playerId then
                -- print("^3[Community Service] Checking player: " .. playerId .. " on resource start^0")
                TriggerEvent('esx_communityservice:checkIfSentenced', playerId)
            end
        end
    end
end)

-- Event khi player join server - kiểm tra trạng thái phạt lao động
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    -- ✅ TẮT: okokBilling đã xử lý kiểm tra tiền âm
    return
    --[[
    -- Player object được pass vào như parameter, không dùng source
    if not Player or not Player.PlayerData or not Player.PlayerData.source then
        --print("^1[Community Service] ERROR: Invalid Player data in QBCore:Server:PlayerLoaded^0")
        return
    end
    
    local playerSource = Player.PlayerData.source
    --print("^2[Community Service] ===== QBCore:Server:PlayerLoaded TRIGGERED for player: " .. playerSource .. " =====^0")
    
    -- Tạo closure với playerSource
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        
        --print("^3[Community Service] Starting negative money check for player: " .. playerSource .. "^0")
        TriggerEvent('esx_communityservice:checkNegativeMoney', playerSource)
        
        Citizen.Wait(1000)
       -- print("^3[Community Service] Starting sentence check for player: " .. playerSource .. "^0")
        TriggerEvent('esx_communityservice:checkIfSentenced', playerSource)
    end)
    ]]--
end)

-- Thêm event player joining để backup
AddEventHandler('playerJoining', function()
    -- ✅ TẮT: okokBilling đã xử lý kiểm tra tiền âm
    return
    --[[
    local playerSource = source  -- Lưu source ngay lập tức
    
    if not playerSource or playerSource == 0 or playerSource == '' then 
        --print("^1[Community Service] ERROR: Invalid source in playerJoining^0")
        return 
    end
    
    --print("^5[Community Service] ===== playerJoining TRIGGERED for: " .. playerSource .. " =====^0")
    
    -- Đợi 12 giây để đảm bảo QBCore player data đã load (sau khi character selection)
    Citizen.CreateThread(function()
        Citizen.Wait(12000)
        
        local xPlayer = exports.qbx_core:GetPlayer(playerSource)
        if xPlayer then
            --print("^5[Community Service] Delayed check for playerJoining: " .. playerSource .. "^0")
            TriggerEvent('esx_communityservice:checkNegativeMoney', playerSource)
        -- else
        --     print("^1[Community Service] Player data STILL not loaded for: " .. playerSource .. " after 12s^0")
        end
    end)
    ]]--
end)

-- Event kiểm tra tiền âm và tự động phạt lao động
RegisterNetEvent('esx_communityservice:checkNegativeMoney', function(targetSource)
    -- ✅ TẮT: okokBilling đã xử lý tự động bỏ tù khi âm tiền >= 20k
    return
    --[[
    local src = targetSource or source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    
    if not xPlayer then 
        print("^1[Negative Money Check] Player not found for source: " .. src .. "^0")
        return 
    end
    
    local identifier = xPlayer.PlayerData.citizenid
    
    -- Kiểm tra cooldown để tránh check trùng
    local currentTime = GetGameTimer()
    if checkCooldowns[identifier] and (currentTime - checkCooldowns[identifier]) < COOLDOWN_TIME then
        --print("^3[Negative Money Check] Skipping check for " .. identifier .. " (cooldown active)^0")
        return
    end
    
    -- Cập nhật cooldown
    checkCooldowns[identifier] = currentTime
    
    local bankMoney = xPlayer.Functions.GetMoney('bank')
    local PID = xPlayer.PlayerData.pid
    
    --print("^3[Negative Money Check] Player: " .. src .. " | Bank: $" .. bankMoney .. "^0")
    
    -- Kiểm tra nếu tiền bank âm và dưới -20,000
    if bankMoney < -20000 then
        local negativeMoney = math.abs(bankMoney)
        
        -- Tính số bãi: âm 1000$ = 10 bãi
        local actions = math.floor(negativeMoney / 1000) * 10
        
        --print("^1[Negative Money Check] PUNISHMENT TRIGGERED! Player: " .. src .. " | Negative: $" .. negativeMoney .. " | Actions: " .. actions .. "^0")
        
        -- Lấy thông tin nhân vật
        local characterName = xPlayer.PlayerData.charinfo.lastname .. " " .. xPlayer.PlayerData.charinfo.firstname
        
        -- Gửi log Discord
        local logFields = {
            {
                ["name"] = "👤 Tên nhân vật",
                ["value"] = characterName,
                ["inline"] = false
            },
            {
                ["name"] = "🆔 Player ID",
                ["value"] = PID,
                ["inline"] = false
            },
            {
                ["name"] = "💰 Số tiền âm (Bank)",
                ["value"] = "-$" .. negativeMoney,
                ["inline"] = false
            },
            {
                ["name"] = "⚖️ Số phạt",
                ["value"] = actions .. " bãi lao động",
                ["inline"] = false
            }
        }
        
        -- Gửi log phạt âm tiền
        SendDiscordLog(
            "📋 Log Phạt Âm Tiền",
            "Hệ thống tự động phạt lao động do tiền âm",
            15158332, -- Màu đỏ
            logFields,
            DISCORD_WEBHOOK_PRISON
        )
        
        -- Lưu số tiền âm vào metadata để set về 0 sau khi hoàn thành
        MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {identifier}, function(result)
            if result[1] then
                -- Đã có án phạt, cộng thêm
                local newActions = tonumber(result[1].actions_remaining) + actions
                MySQL.Async.execute('UPDATE communityservice SET actions_remaining = ?, negative_money_clear = ? WHERE identifier = ?',
                    {newActions, 1, identifier}, function()
                        print("^2[Negative Money] Updated existing punishment. New total: " .. newActions .. " actions^0")
                    end)
                exports.qbx_core:Notify(src, 'Bạn bị phạt thêm ' .. actions .. ' bãi do nợ $' .. negativeMoney, 'error', 10000)
            else
                -- Lần đầu phạt do tiền âm
                MySQL.Async.insert('INSERT INTO communityservice (identifier, actions_remaining, negative_money_clear) VALUES (?, ?, ?)',
                    {identifier, actions, 1}, function()
                        print("^2[Negative Money] Created new punishment: " .. actions .. " actions^0")
                    end)
                exports.qbx_core:Notify(src, 'Bạn bị phạt lao động ' .. actions .. ' bãi do nợ $' .. negativeMoney, 'error', 10000)
            end
            
            -- KHÔNG gọi checkIfSentenced ở đây vì sẽ teleport ngay
            -- Client sẽ tự động chạy flow: mugshot -> xe chở -> arrivedAtPrison -> inCommunityService
        end)
    -- else
    --     print("^3[Negative Money Check] Player " .. src .. " has positive money. Total: $" .. totalMoney .. "^0")
    end
    ]]--
end)

-- Command test negative money check (admin only)
lib.addCommand('testnegativemoney', {
    help = 'Test kiểm tra tiền âm của bản thân',
    restricted = false
}, function(source, args)
    local src = source
    print("^5[TEST] Manual trigger negative money check for player: " .. src .. "^0")
    TriggerEvent('esx_communityservice:checkNegativeMoney', src)
end)

-- Export function để có thể gọi từ resource khác
exports('CheckNegativeMoney', function(playerId)
    if playerId and playerId > 0 then
        print("^6[Export] CheckNegativeMoney called for player: " .. playerId .. "^0")
        TriggerEvent('esx_communityservice:checkNegativeMoney', playerId)
        return true
    end
    return false
end)

-- Hook vào QBCore Player Loaded (phương án backup) - Đã xóa vì không safe for net

-- Thêm event player connecting với retry mechanism
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    -- ✅ TẮT: okokBilling đã xử lý kiểm tra tiền âm
    return
    --[[
    local playerSource = source
    deferrals.defer()
    
    Wait(0)
    deferrals.update("Đang kiểm tra thông tin...")
    
    -- Đợi load xong rồi schedule check
    Wait(100)
    deferrals.done()
    
    -- Schedule check sau khi player đã fully connected
    Citizen.CreateThread(function()
        Citizen.Wait(10000)
        
        local xPlayer = exports.qbx_core:GetPlayer(playerSource)
        if xPlayer then
            --print("^6[Community Service] playerConnecting delayed check for: " .. playerSource .. "^0")
            TriggerEvent('esx_communityservice:checkNegativeMoney', playerSource)
        end
    end)
    ]]--
end)


RegisterServerEvent("nl_hotcut:gin:send")
AddEventHandler("nl_hotcut:gin:send", function()
	local xPlayer = exports.qbx_core:GetPlayer(source)
	local _source = source
	--local target = QBCore.Functions.GetPlayer(data.target)
	--local target = QBCore.Functions.GetPlayer(data.target)

	local ped = GetPlayerPed(source)
    local pCoords = GetEntityCoords(ped)
    local Players = GetPlayers()
	
    for i=1, #Players do
        local Player = tonumber(Players[i])
        local target = GetPlayerPed(Player)
        local tCoords = GetEntityCoords(target)
		local member = exports.qbx_core:GetPlayer(Player)

        if target ~= ped and #(pCoords - tCoords) < 20 then
			name = member.PlayerData.charinfo.firstname..' '..member.PlayerData.charinfo.lastname
			TriggerClientEvent('nl_hotcut:client:acp', source, Player, name)
        end

    end

end)

-- Command phạt tù (admin & mod) theo PID
lib.addCommand('phattu', {
	help = 'Phạt tù người chơi theo PID',
	restricted = {'group.admin', 'group.mod'},
	params = {
		{
			name = 'pid',
			type = 'number',
			help = 'PID người chơi'
		},
		{
			name = 'actions',
			type = 'number',
			help = 'Số bãi muốn phạt (1-999)'
		}
	}
}, function(source, args)
	local src = source
	local Player = exports.qbx_core:GetPlayer(src)

	if src ~= 0 and not Player then return end

	local targetPid = tonumber(args.pid or args[1])
	local actionsCount = tonumber(args.actions or args[2])

	if not targetPid or not actionsCount then
		if src ~= 0 then
			exports.qbx_core:Notify(src, "PID và số bãi phải là số!", "error")
		else
			print("PID và số bãi phải là số!")
		end
		return
	end

	if actionsCount < 1 or actionsCount > 999 then
		if src ~= 0 then
			exports.qbx_core:Notify(src, "Số bãi phải từ 1 đến 999", "error")
		else
			print("Số bãi phải từ 1 đến 999")
		end
		return
	end

	local adminName = "Console"
	local adminPid = 0
	local discordID = "Không có"

	if Player then
		adminName = Player.PlayerData.charinfo.lastname .. " " .. Player.PlayerData.charinfo.firstname
		adminPid = Player.PlayerData.pid
		for _, id in ipairs(GetPlayerIdentifiers(src)) do
			if string.match(id, "discord:") then
				discordID = "<@" .. string.gsub(id, "discord:", "") .. ">"
				break
			end
		end
	end

	-- Lấy citizenid từ PID
	MySQL.Async.fetchAll('SELECT citizenid, charinfo FROM players WHERE pid = ?', {targetPid}, function(result)
		if result[1] then
			local targetIdentifier = result[1].citizenid
			local charInfo = result[1].charinfo and json.decode(result[1].charinfo) or nil
			local offlineTargetName = charInfo and (charInfo.lastname .. " " .. charInfo.firstname) or ("PID " .. targetPid)

			-- Tìm player đang online để gửi event
			local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetIdentifier)

			MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {targetIdentifier}, function(communityResult)
				if communityResult[1] then
					-- Cộng dồn số bãi mới với số bãi hiện tại
					local newActionsCount = tonumber(communityResult[1].actions_remaining) + actionsCount
					MySQL.Async.execute('UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?', {newActionsCount, targetIdentifier})

					local targetName = targetPlayer and (targetPlayer.PlayerData.charinfo.lastname .. " " .. targetPlayer.PlayerData.charinfo.firstname) or offlineTargetName

					-- Nếu player đang online, chụp mugshot (client sẽ tự động chạy flow)
					if targetPlayer then
						-- SET FLAG NGAY ĐỂ TRÁNH BỊ TELEPORT SỚM
						playersInMugshotProcess[targetPlayer.PlayerData.source] = true
						TriggerClientEvent('nl_hotcut:client:takeMugshot', targetPlayer.PlayerData.source, newActionsCount)
					end

					local logFields = {
						{["name"] = "👤 Tù nhân", ["value"] = targetName .. " (PID: " .. targetPid .. ")" .. (targetPlayer and "" or " [Offline]"), ["inline"] = false},
						{["name"] = "👮 Admin/Mod phạt", ["value"] = adminName .. " (PID: " .. adminPid .. ") " .. discordID, ["inline"] = false},
						{["name"] = "➕ Số bãi thêm", ["value"] = actionsCount .. " bãi", ["inline"] = true},
						{["name"] = "📊 Tổng số bãi", ["value"] = newActionsCount .. " bãi", ["inline"] = true}
					}
					SendDiscordLog("🔨 Admin/Mod Phạt Tù (Cộng Dồn)", "Lệnh /phattu", 15158332, logFields, DISCORD_WEBHOOK_PHATTU)

					if src ~= 0 then
						exports.qbx_core:Notify(src, "Đã phạt PID " .. targetPid .. " tổng cộng " .. newActionsCount .. " bãi", "success")
					else
						print("Đã phạt PID " .. targetPid .. " tổng cộng " .. newActionsCount .. " bãi")
					end
				else
					-- Lần đầu phạt
					MySQL.Async.insert('INSERT INTO communityservice (identifier, actions_remaining) VALUES (?, ?)', {targetIdentifier, actionsCount})

					local targetName = targetPlayer and (targetPlayer.PlayerData.charinfo.lastname .. " " .. targetPlayer.PlayerData.charinfo.firstname) or offlineTargetName

					-- Nếu player đang online, chụp mugshot (client sẽ tự động chạy flow)
					if targetPlayer then
						-- SET FLAG NGAY ĐỂ TRÁNH BỊ TELEPORT SỚM
						playersInMugshotProcess[targetPlayer.PlayerData.source] = true
						TriggerClientEvent('nl_hotcut:client:takeMugshot', targetPlayer.PlayerData.source, actionsCount)
					end

					local logFields = {
						{["name"] = "👤 Tù nhân", ["value"] = targetName .. " (PID: " .. targetPid .. ")" .. (targetPlayer and "" or " [Offline]"), ["inline"] = false},
						{["name"] = "👮 Admin/Mod phạt", ["value"] = adminName .. " (PID: " .. adminPid .. ") " .. discordID, ["inline"] = false},
						{["name"] = "⚖️ Số bãi phạt", ["value"] = actionsCount .. " bãi", ["inline"] = false}
					}
					SendDiscordLog("🔨 Admin/Mod Phạt Tù", "Lệnh /phattu", 15158332, logFields, DISCORD_WEBHOOK_PHATTU)

					if src ~= 0 then
						exports.qbx_core:Notify(src, "Đã phạt PID " .. targetPid .. " với " .. actionsCount .. " bãi", "success")
					else
						print("Đã phạt PID " .. targetPid .. " với " .. actionsCount .. " bãi")
					end
				end
			end)
		else
			if src ~= 0 then
				exports.qbx_core:Notify(src, "Không tìm thấy người chơi với PID: " .. targetPid, "error")
			else
				print("Không tìm thấy người chơi với PID: " .. targetPid)
			end
		end
	end)
end)

RegisterNetEvent('esx_communityservice:openOfflinePunishDialog', function()
    local source = source
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player.PlayerData.job.name ~= "police" then
        exports.qbx_core:Notify(source, "Bạn không có quyền sử dụng chức năng này", "error")
        return
    end
    
    TriggerClientEvent('esx_communityservice:showOfflinePunishDialog', source)
end)

-- Xử lý phạt offline
RegisterNetEvent('esx_communityservice:processOfflinePunish', function(pid, reason)
    local source = source
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player.PlayerData.job.name ~= "police" then
        exports.qbx_core:Notify(source, "Bạn không có quyền sử dụng chức năng này", "error")
        return
    end
    
    -- Lấy identifier từ PID
    MySQL.Async.fetchAll('SELECT citizenid FROM players WHERE pid = ?', {pid}, function(result)
        if result[1] then
            local targetIdentifier = result[1].citizenid
            local punisherIdentifier = Player.PlayerData.citizenid
            
            -- Kiểm tra không tự phạt mình
            if targetIdentifier == punisherIdentifier then
                exports.qbx_core:Notify(source, "Bạn không thể phạt chính bản thân bạn", "error")
                return
            end
            
            -- Insert hoặc update vào database
            MySQL.Async.fetchAll('SELECT * FROM offline_punishment WHERE identifier = ?', {targetIdentifier}, function(punishment)
                if punishment[1] then
                    exports.qbx_core:Notify(source, "Người chơi này đã bị phạt offline rồi", "error")
                else
                    MySQL.Async.insert('INSERT INTO offline_punishment (identifier, punished_by, reason) VALUES (?, ?, ?)', 
                    {targetIdentifier, punisherIdentifier, reason}, function(rowsChanged)
                        exports.qbx_core:Notify(source, "Đã phạt offline cho PID: " .. pid, "success")
                        
                        -- Nếu người chơi đang online, teleport và phạt ngay lập tức
                        local targetPlayer = exports.qbx_core:GetPlayer(tonumber(pid))
                        if targetPlayer then
                            TriggerClientEvent('esx_communityservice:startOfflinePunishment', targetPlayer.PlayerData.source)
                        end
                    end)
                end
            end)
        else
            exports.qbx_core:Notify(source, "Không tìm thấy người chơi với PID: " .. pid, "error")
        end
    end)
end)

-- Event hủy phạt offline với dialog
RegisterNetEvent('esx_communityservice:openReleaseOfflineDialog', function()
    local source = source
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player.PlayerData.job.name ~= "police" or Player.PlayerData.job.grade.level < 14 then
        exports.qbx_core:Notify(source, "Bạn không đủ cấp độ để làm việc này", "error")
        return
    end
    
    TriggerClientEvent('esx_communityservice:showReleaseOfflineDialog', source)
end)

-- Xử lý hủy phạt offline
RegisterNetEvent('esx_communityservice:processReleaseOffline', function(pid)
    local source = source
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player.PlayerData.job.name ~= "police" or Player.PlayerData.job.grade.level < 14 then
        exports.qbx_core:Notify(source, "Bạn không đủ cấp độ để làm việc này", "error")
        return
    end
    
    -- Lấy identifier từ PID
    MySQL.Async.fetchAll('SELECT citizenid FROM players WHERE pid = ?', {pid}, function(result)
        if result[1] then
            local targetIdentifier = result[1].citizenid
            
            -- Xóa khỏi database
            MySQL.Async.execute('DELETE FROM offline_punishment WHERE identifier = ?', {targetIdentifier}, function(rowsChanged)
                if rowsChanged > 0 then
                    exports.qbx_core:Notify(source, "Đã hủy phạt offline cho PID: " .. pid, "success")
                    
                    -- Nếu người chơi đang online, hủy trạng thái phạt
                    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetIdentifier)
                    if targetPlayer then
                        TriggerClientEvent('esx_communityservice:releaseOfflinePunishment', targetPlayer.PlayerData.source)
                        exports.qbx_core:Notify(targetPlayer.PlayerData.source, "Phạt offline của bạn đã được hủy", "success")
                    end
                else
                    exports.qbx_core:Notify(source, "Người chơi này không có án phạt offline", "error")
                end
            end)
        else
            exports.qbx_core:Notify(source, "Không tìm thấy người chơi với PID: " .. pid, "error")
        end
    end)
end)

-- ============= EVENT PHẠT LAO ĐỘNG =============
-- Event mở dialog phạt lao động
RegisterNetEvent('esx_communityservice:openPunishDialog', function()
    local source = source
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player.PlayerData.job.name ~= "police" then
        exports.qbx_core:Notify(source, "Bạn không có quyền sử dụng chức năng này", "error")
        return
    end
    
    TriggerClientEvent('esx_communityservice:showPunishDialog', source)
end)

-- Event mở dialog hủy phạt lao động
RegisterNetEvent('esx_communityservice:openReleasePunishDialog', function()
    local source = source
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player.PlayerData.job.name ~= "police" or Player.PlayerData.job.grade.level < 14 then
        exports.qbx_core:Notify(source, "Bạn không đủ cấp độ để làm việc này", "error")
        return
    end
    
    TriggerClientEvent('esx_communityservice:showReleasePunishDialog', source)
end)

-- Xử lý hủy phạt lao động
RegisterNetEvent('esx_communityservice:processReleasePunish', function(playerIdOrPid)
    local source = source
    local Player = exports.qbx_core:GetPlayer(source)
    
    if Player.PlayerData.job.name ~= "police" or Player.PlayerData.job.grade.level < 14 then
        exports.qbx_core:Notify(source, "Ban khong du cap do de lam viec nay", "error")
        return
    end

    local playerId = tonumber(playerIdOrPid)
    local onlineTarget = playerId and exports.qbx_core:GetPlayer(playerId)

    if onlineTarget then
        TriggerEvent('esx_communityservice:endCommunityServiceCommand', onlineTarget.PlayerData.source, source)
        exports.qbx_core:Notify(source, "Da huy phat lao dong cho Player ID: " .. playerId, "success")
        return
    end
    
    MySQL.Async.fetchAll('SELECT citizenid FROM players WHERE pid = ?', {playerIdOrPid}, function(result)
        if result[1] then
            local targetIdentifier = result[1].citizenid
            local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetIdentifier)
            
            if targetPlayer then
                TriggerEvent('esx_communityservice:endCommunityServiceCommand', targetPlayer.PlayerData.source, source)
                exports.qbx_core:Notify(source, "Da huy phat lao dong cho PID: " .. playerIdOrPid, "success")
            else
                MySQL.Async.execute('DELETE FROM communityservice WHERE identifier = ?', {targetIdentifier}, function(rowsChanged)
                    if rowsChanged > 0 then
                        exports.qbx_core:Notify(source, "Da huy phat lao dong cho PID: " .. playerIdOrPid .. " (offline)", "success")
                    else
                        exports.qbx_core:Notify(source, "Nguoi choi nay khong co an phat", "error")
                    end
                end)
            end
        else
            exports.qbx_core:Notify(source, "Khong tim thay nguoi choi voi Player ID/PID: " .. playerIdOrPid, "error")
        end
    end)
end)

RegisterNetEvent('esx_communityservice:endCommunityServiceCommand', function(targetSource, releaserSource)
	if targetSource then
		-- Hủy phạt lao động cho player target (đã bao gồm cleanup và thông báo)
		releaseFromCommunityService(targetSource, "police", releaserSource)
		
		-- Thông báo cho player bị hủy phạt
		exports.qbx_core:Notify(targetSource, "Phạt lao động của bạn đã được hủy bởi cảnh sát", "success")
	end
end)

RegisterNetEvent('esx_communityservice:finishCommunityService', function()
	-- Event này được gọi khi player tự hoàn thành đủ bãi
	releaseFromCommunityService(source, "complete")
end)

RegisterNetEvent('esx_communityservice:completeService', function()
	local _source = source
	local identifier = exports.qbx_core:GetPlayer(_source).PlayerData.citizenid
    MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {identifier}, function(result)	
		if result[1]  then
		local act = tonumber(result[1].actions_remaining-1)
			MySQL.Async.execute(
            'UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?',
            {act, identifier})
			
		else
			--print ("Lao Động Công Ích ::Sự cố khi khớp số nhận dạng người chơi trong cơ sở dữ liệu để giảm bớt các hành động")
		end
	end)
end)

-- Event chuộc tù
RegisterNetEvent('esx_communityservice:buyoutService', function(amount)
	local src = source
	local xPlayer = exports.qbx_core:GetPlayer(src)
	if not xPlayer then return end
	
	local identifier = xPlayer.PlayerData.citizenid
	local totalPrice = amount * Config.BuyoutPrice
	
	-- Kiểm tra tiền
	if xPlayer.Functions.GetMoney('cash') < totalPrice and xPlayer.Functions.GetMoney('bank') < totalPrice then
		exports.qbx_core:Notify(src, 'Bạn không đủ tiền! Cần $' .. totalPrice, 'error', 5000)
		return
	end
	
	-- Kiểm tra số bãi còn lại
	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {identifier}, function(result)
		if result[1] then
			local currentActions = tonumber(result[1].actions_remaining)
			
			if amount > currentActions then
				exports.qbx_core:Notify(src, 'Bạn chỉ còn ' .. currentActions .. ' bãi!', 'error', 3000)
				return
			end
			
			-- Trừ tiền (ưu tiên cash)
			if xPlayer.Functions.GetMoney('cash') >= totalPrice then
				xPlayer.Functions.RemoveMoney('cash', totalPrice, 'prison-buyout')
			else
				xPlayer.Functions.RemoveMoney('bank', totalPrice, 'prison-buyout')
			end
			
			-- Giảm số bãi
			local newActions = currentActions - amount
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?', {newActions, identifier})
			
			-- Cập nhật số bãi cho client
			TriggerClientEvent('esx_communityservice:updateActions', src, newActions)
			
			-- Thông báo cho client
			exports.qbx_core:Notify(src, 'Đã chuộc ' .. amount .. ' bãi với giá $' .. totalPrice, 'success', 5000)
			
			-- Nếu hết bãi thì thả tự do
			if newActions <= 0 then
				releaseFromCommunityService(src, "buyout", nil, amount, totalPrice)
			end
		end
	end)
end)

RegisterNetEvent('esx_communityservice:extendService', function()

	local _source = source
	local identifier = exports.qbx_core:GetPlayer(_source).PlayerData.citizenid
	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {identifier}, function(result)
		if result[1]  then
			local act = tonumber(result[1].actions_remaining+Config.ServiceExtensionOnEscape)
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?', {act, identifier})
		else
			--print ("Lao Động Công Ích ::Sự cố khi khớp số nhận dạng người chơi trong cơ sở dữ liệu để giảm bớt các hành động.")
		end
	end)
end)

local function SendToCommunityServiceInternal(playerIdOrPid, actions_count, officerSourceOverride)
    local officerSource = tonumber(officerSourceOverride) or source
    local sourcePlayer = exports.qbx_core:GetPlayer(officerSource)
    local actionsCount = tonumber(actions_count)

    if not sourcePlayer then
        print('[NL_HOTCUT] sendToCommunityService blocked: officer/source player not found ' .. tostring(officerSource))
        return false, 'officer_not_found'
    end

    if not actionsCount or actionsCount <= 0 then
        exports.qbx_core:Notify(officerSource, 'So bai phat khong hop le', 'error')
        print('[NL_HOTCUT] sendToCommunityService blocked: invalid actions ' .. tostring(actions_count))
        return false, 'invalid_actions'
    end

    local displayId = tostring(playerIdOrPid)
    local idLabel = 'Player ID'
    local targetPlayer = nil
    local targetIdentifier = nil
    local playerId = tonumber(playerIdOrPid)

    if playerId then
        targetPlayer = exports.qbx_core:GetPlayer(playerId)
        if targetPlayer then
            targetIdentifier = targetPlayer.PlayerData.citizenid
            displayId = tostring(playerId)
        end
    end

    if not targetIdentifier then
        local result = MySQL.query.await('SELECT citizenid FROM players WHERE pid = ? LIMIT 1', {playerIdOrPid})
        if result and result[1] then
            targetIdentifier = result[1].citizenid
            targetPlayer = exports.qbx_core:GetPlayerByCitizenId(targetIdentifier)
            idLabel = 'PID'
        end
    end

    if not targetIdentifier then
        exports.qbx_core:Notify(officerSource, 'Khong tim thay nguoi choi voi Player ID/PID: ' .. tostring(playerIdOrPid), 'error')
        print('[NL_HOTCUT] target not found by Player ID/PID: ' .. tostring(playerIdOrPid))
        return false, 'target_not_found'
    end

    if sourcePlayer.PlayerData.citizenid == targetIdentifier then
        exports.qbx_core:Notify(officerSource, 'Ban khong the phat chinh ban than ban', 'error')
        return false, 'self_punish'
    end

    local affectedRows = MySQL.update.await([[
        INSERT INTO communityservice (identifier, actions_remaining)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE actions_remaining = actions_remaining + ?
    ]], {targetIdentifier, actionsCount, actionsCount})

    print(('[NL_HOTCUT] communityservice upsert target=%s %s citizenid=%s actions=%s affected=%s'):format(
        idLabel,
        displayId,
        targetIdentifier,
        tostring(actionsCount),
        tostring(affectedRows)
    ))

    local row = MySQL.single.await('SELECT actions_remaining FROM communityservice WHERE identifier = ? LIMIT 1', {targetIdentifier})
    if not row then
        exports.qbx_core:Notify(officerSource, 'Ghi SQL communityservice that bai', 'error')
        print('[NL_HOTCUT] ERROR: upsert completed but row not found for ' .. targetIdentifier)
        return false, 'sql_row_missing'
    end

    local currentActions = tonumber(row.actions_remaining) or actionsCount

    if targetPlayer then
        local targetSource = targetPlayer.PlayerData.source
        playersInMugshotProcess[targetSource] = true
        TriggerClientEvent('nl_hotcut:client:takeMugshot', targetSource, currentActions)
        print(('[NL_HOTCUT] triggered mugshot/prison flow targetSource=%s actions=%s'):format(tostring(targetSource), tostring(currentActions)))
    else
        print('[NL_HOTCUT] SQL applied, target is offline: ' .. targetIdentifier)
    end

    local targetName = targetPlayer and (targetPlayer.PlayerData.charinfo.lastname .. ' ' .. targetPlayer.PlayerData.charinfo.firstname) or targetIdentifier
    local policeName = sourcePlayer.PlayerData.charinfo.lastname .. ' ' .. sourcePlayer.PlayerData.charinfo.firstname
    local fields = {
        {
            ['name'] = 'Tu nhan',
            ['value'] = targetName .. ' (' .. idLabel .. ': ' .. displayId .. ')',
            ['inline'] = false
        },
        {
            ['name'] = 'Canh sat phat',
            ['value'] = policeName .. ' (Player ID: ' .. officerSource .. ')',
            ['inline'] = false
        },
        {
            ['name'] = 'So bai phat',
            ['value'] = actionsCount .. ' bai',
            ['inline'] = true
        },
        {
            ['name'] = 'Tong so bai',
            ['value'] = currentActions .. ' bai',
            ['inline'] = true
        }
    }
    SendDiscordLog('Canh Sat Dua Di Tu', 'Canh sat phat lao dong', 3447003, fields, DISCORD_WEBHOOK_PRISON)
    exports.qbx_core:Notify(officerSource, 'Da phat ' .. idLabel .. ' ' .. displayId .. ' voi ' .. actionsCount .. ' bai', 'success')

    return true, currentActions
end

RegisterNetEvent('esx_communityservice:sendToCommunityService', function(playerIdOrPid, actions_count, officerSourceOverride)
    SendToCommunityServiceInternal(playerIdOrPid, actions_count, officerSourceOverride)
end)

exports('SendToCommunityService', function(playerIdOrPid, actions_count, officerSourceOverride)
    return SendToCommunityServiceInternal(playerIdOrPid, actions_count, officerSourceOverride)
end)

RegisterNetEvent('esx_communityservice:checkIfSentenced', function(targetSource)
	local _source = targetSource or source -- Có thể nhận source từ parameter hoặc từ trigger
	local xPlayer = exports.qbx_core:GetPlayer(_source) -- get steam identifier
	
	if not xPlayer then
		--print("^1[Community Service] Player not found for source: " .. tostring(_source) .. "^0")
		return
	end
	
	local identifier = xPlayer.PlayerData.citizenid
	--print("^3[Community Service] Checking player: " .. _source .. " (citizenid: " .. identifier .. ")^0")
	
	-- Kiểm tra phạt offline trước
	MySQL.Async.fetchAll('SELECT * FROM offline_punishment WHERE identifier = ?', {identifier}, function(offlineResult)
		if offlineResult[1] then
			-- Người chơi bị phạt offline, teleport và giữ tại vị trí
			TriggerClientEvent('esx_communityservice:startOfflinePunishment', _source)
			return
		end
		
		-- Kiểm tra phạt lao động thông thường
		MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {identifier}, function(result)
			if result[1] and result[1].actions_remaining > 0 then
				--print("^2[Community Service] Restoring punishment for player: " .. _source .. " (" .. result[1].actions_remaining .. " actions remaining)^0")
				
				-- Kiểm tra nếu player đang trong quá trình chụp ảnh mugshot
				if playersInMugshotProcess[_source] then
					print("^3[Community Service] Player " .. _source .. " is in mugshot process, skipping teleport^0")
					return -- Không teleport vào tù, đợi flow mugshot hoàn thành
				end
				
				-- Kiểm tra nếu đang bị cách ly (isolation_bucket != 0)
				local isolationBucket = result[1].isolation_bucket or 0
				
				if isolationBucket > 0 then
					-- Restore vào bucket cách ly RIÊNG của họ
					SetPlayerRoutingBucket(_source, isolationBucket)
					exports.qbx_core:Notify(_source, 'Bạn vẫn đang bị cách ly trong thế giới riêng vì đánh nhau trong tù!', 'error', 10000)
				else
					-- Chuyển vào bucket 1 bình thường (tù)
					SetPlayerRoutingBucket(_source, 1)
				end
				
				TriggerClientEvent('esx_communityservice:inCommunityService', _source, tonumber(result[1].actions_remaining))
			else
				--print("^3[Community Service] No active punishment found for player: " .. _source .. "^0")
			end
		end)
	end)
end)

function releaseFromCommunityService(target, releaseType, releaserSource, buyoutAmount, buyoutPrice)
	local xPlayer = exports.qbx_core:GetPlayer(target) -- get steam identifier
	local identifier = xPlayer.PlayerData.citizenid
	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {identifier}, function(result)
		if result[1] then
            -- Kiểm tra nếu là án phạt do tiền âm, set bank về 0
            if result[1].negative_money_clear and result[1].negative_money_clear == 1 then
                -- Chỉ set bank về 0 (bất kể âm hay dương để tránh bug)
                xPlayer.Functions.SetMoney('bank', 0, 'negative-money-clear')
                exports.qbx_core:Notify(target, 'Tiền bank đã được reset về $0!', 'success', 5000)
			end
			
			-- Xóa record khỏi database (bao gồm cả isolation_bucket)
			MySQL.Async.execute(
			'DELETE from communityservice WHERE identifier = ?',
			{identifier})
			
			--TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_finished', GetPlayerName(target)) }, color = { 147, 196, 109 } })
		end
	end)

	-- Trả player về bucket 0 (thế giới chính) - xóa cả cách ly nếu có
	SetPlayerRoutingBucket(target, 0)
	exports.qbx_core:Notify(target, 'Bạn đã tự do! Cách ly đã được gỡ bỏ.', 'success', 5000)
	
	-- Log Discord - Thả tù (nếu không phải admin command)
	if releaseType and releaseType ~= "admin" then
		local characterName = xPlayer.PlayerData.charinfo.lastname .. " " .. xPlayer.PlayerData.charinfo.firstname
		local releaseReason = ""
		local releaseColor = 5763719 -- Màu xanh lá
		local releaserInfo = ""
		
		if releaseType == "police" then
			releaseReason = "Cảnh sát thả tù"
			if releaserSource then
				local releaserPlayer = exports.qbx_core:GetPlayer(releaserSource)
				if releaserPlayer then
					local releaserName = releaserPlayer.PlayerData.charinfo.lastname .. " " .. releaserPlayer.PlayerData.charinfo.firstname
					releaserInfo = releaserName .. " (PID: " .. releaserPlayer.PlayerData.pid .. ")"
				end
			end
		elseif releaseType == "buyout" then
			releaseReason = "Chuộc tù (Tự trả tiền)"
			releaseColor = 16776960 -- Màu vàng
			if buyoutAmount and buyoutPrice then
				releaserInfo = "Đã trả $" .. buyoutPrice .. " để chuộc " .. buyoutAmount .. " bãi"
			else
				releaserInfo = "Tự chuộc"
			end
		elseif releaseType == "complete" then
			releaseReason = "Hoàn thành bãi (Tự động)"
			releaseColor = 3066993 -- Màu xanh dương nhạt
			releaserInfo = "Hệ thống"
		end
		
		local fields = {
			{
				["name"] = "👤 Tù nhân",
				["value"] = characterName .. " (PID: " .. xPlayer.PlayerData.pid .. ")",
				["inline"] = false
			},
			{
				["name"] = "✅ Lý do thả",
				["value"] = releaseReason,
				["inline"] = false
			}
		}
		
		-- Luôn hiển thị thông tin người thả/hệ thống
		if releaserInfo ~= "" then
			local labelName = "👮 Người thả"
			if releaseType == "complete" then
				labelName = "⚙️ Thả bởi"
			elseif releaseType == "buyout" then
				labelName = "💰 Hành động"
			end
			
			table.insert(fields, {
				["name"] = labelName,
				["value"] = releaserInfo,
				["inline"] = false
			})
		end
		
		SendDiscordLog(
			"🔓 Thả Tù",
			"Tù nhân được thả tự do",
			releaseColor,
			fields,
			DISCORD_WEBHOOK_RELEASE -- Gửi đến webhook riêng cho thả tù
		)
	end
	
	-- Cộng lại điểm uy tín sau khi ra tù (tránh bị tù liên tục)
	TriggerEvent('nl_hotcut:restoreReputation', target, Config.ReputationRestoreAmount)
	
	-- Gọi client event để cleanup TRƯỚC (dừng vòng lặp)
	TriggerClientEvent('esx_communityservice:finishCommunityServiceClient', target)
	
	-- Đợi một chút để client xử lý cleanup
	Wait(500)
	
	-- Teleport về vị trí thả tù SAU KHI cleanup
	local ped = GetPlayerPed(target)
	SetEntityCoords(ped, Config.ReleaseLocation.x, Config.ReleaseLocation.y, Config.ReleaseLocation.z)
end

-- ============= VISIT PRISON SYSTEM =============
-- Lấy danh sách tù nhân để chuộc
RegisterNetEvent('esx_communityservice:requestPrisonerList', function()
	local src = source
	local prisonerList = {}
	
	-- Lấy tất cả players đang ở bucket 1 (trong tù)
	for _, playerId in ipairs(GetPlayers()) do
		local player = exports.qbx_core:GetPlayer(tonumber(playerId))
		if player and GetPlayerRoutingBucket(playerId) == 1 then
			local identifier = player.PlayerData.citizenid
			
			-- Lấy số bãi còn lại
			MySQL.Async.fetchAll('SELECT actions_remaining FROM communityservice WHERE identifier = ?', {identifier}, function(result)
				if result[1] and result[1].actions_remaining > 0 then
					table.insert(prisonerList, {
						source = tonumber(playerId),
						name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
						actionsRemaining = result[1].actions_remaining
					})
				end
			end)
		end
	end
	
	-- Đợi query xong rồi gửi list
	Wait(200)
	TriggerClientEvent('esx_communityservice:showPrisonerList', src, prisonerList)
end)

-- Lấy danh sách tù nhân để thăm
RegisterNetEvent('esx_communityservice:requestVisitList', function()
	local src = source
	local prisonerList = {}
	
	-- Lấy tất cả players đang ở bucket 1 (trong tù)
	for _, playerId in ipairs(GetPlayers()) do
		local player = exports.qbx_core:GetPlayer(tonumber(playerId))
		if player and GetPlayerRoutingBucket(playerId) == 1 and not Player(playerId).state.isVisiting then
			table.insert(prisonerList, {
				source = tonumber(playerId),
				name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
			})
		end
	end
	
	TriggerClientEvent('esx_communityservice:showVisitList', src, prisonerList)
end)

-- Chuộc tù cho người khác
RegisterNetEvent('esx_communityservice:buyoutForOther', function(targetSource, amount)
	local src = source
	local xPlayer = exports.qbx_core:GetPlayer(src)
	local targetPlayer = exports.qbx_core:GetPlayer(targetSource)
	
	if not xPlayer or not targetPlayer then return end
	
	local targetIdentifier = targetPlayer.PlayerData.citizenid
	local totalPrice = amount * Config.BuyoutPrice
	
	-- Kiểm tra tiền
	if xPlayer.Functions.GetMoney('cash') < totalPrice and xPlayer.Functions.GetMoney('bank') < totalPrice then
		exports.qbx_core:Notify(src, 'Bạn không đủ tiền! Cần $' .. totalPrice, 'error', 5000)
		return
	end
	
	-- Kiểm tra số bãi còn lại
	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = ?', {targetIdentifier}, function(result)
		if result[1] then
			local currentActions = tonumber(result[1].actions_remaining)
			
			if amount > currentActions then
				exports.qbx_core:Notify(src, 'Tù nhân chỉ còn ' .. currentActions .. ' bãi!', 'error', 3000)
				return
			end
			
			-- Trừ tiền (ưu tiên cash)
			if xPlayer.Functions.GetMoney('cash') >= totalPrice then
				xPlayer.Functions.RemoveMoney('cash', totalPrice, 'prison-buyout-other')
			else
				xPlayer.Functions.RemoveMoney('bank', totalPrice, 'prison-buyout-other')
			end
			
			-- Giảm số bãi
			local newActions = currentActions - amount
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?', {newActions, targetIdentifier})
			
			-- Cập nhật số bãi cho tù nhân
			TriggerClientEvent('esx_communityservice:updateActions', targetSource, newActions)
			
			-- Thông báo
			local buyerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
			local prisonerName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
			
			exports.qbx_core:Notify(src, 'Đã chuộc ' .. amount .. ' bãi cho ' .. prisonerName .. ' với giá $' .. totalPrice, 'success', 5000)
			exports.qbx_core:Notify(targetSource, buyerName .. ' đã chuộc ' .. amount .. ' bãi cho bạn!', 'success', 5000)
			
			-- Log Discord - Bảo lãnh (chuộc tù cho người khác)
			SendDiscordLog(
				"💰 Bảo Lãnh Tù Nhân",
				"Người chơi chuộc tù cho người khác",
				16776960, -- Màu vàng
				{
					{
						["name"] = "👤 Tù nhân",
						["value"] = prisonerName .. " (PID: " .. targetPlayer.PlayerData.pid .. ")",
						["inline"] = false
					},
					{
						["name"] = "🤝 Người bảo lãnh",
						["value"] = buyerName .. " (PID: " .. xPlayer.PlayerData.pid .. ")",
						["inline"] = false
					},
					{
						["name"] = "📊 Số bãi chuộc",
						["value"] = amount .. " bãi",
						["inline"] = true
					},
					{
						["name"] = "💵 Số tiền trả",
						["value"] = "$" .. totalPrice,
						["inline"] = true
					},
					{
						["name"] = "📉 Còn lại",
						["value"] = newActions .. " bãi",
						["inline"] = true
					}
				},
				DISCORD_WEBHOOK_RELEASE -- Gửi đến webhook thả tù
			)
			
			-- Nếu hết bãi thì thả tự do (không log vì đã log bảo lãnh ở trên)
			if newActions <= 0 then
				-- Xóa khỏi database
				MySQL.Async.execute('DELETE from communityservice WHERE identifier = ?', {targetIdentifier})
				
				-- Trả về bucket 0
				SetPlayerRoutingBucket(targetSource, 0)
				exports.qbx_core:Notify(targetSource, 'Bạn đã tự do! Đã được bảo lãnh hết bãi.', 'success', 5000)
				
				-- Cộng lại điểm uy tín
				TriggerEvent('nl_hotcut:restoreReputation', targetSource, Config.ReputationRestoreAmount)
				
				-- Gọi client cleanup TRƯỚC (dừng vòng lặp)
				TriggerClientEvent('esx_communityservice:finishCommunityServiceClient', targetSource)
				
				-- Đợi một chút để client xử lý cleanup
				Wait(500)
				
				-- Teleport về vị trí thả tù SAU KHI cleanup
				local ped = GetPlayerPed(targetSource)
				SetEntityCoords(ped, Config.ReleaseLocation.x, Config.ReleaseLocation.y, Config.ReleaseLocation.z)
			end
		end
	end)
end)

-- Gửi yêu cầu thăm tù
RegisterNetEvent('esx_communityservice:requestVisit', function(prisonerSource)
	local src = source
	local visitor = exports.qbx_core:GetPlayer(src)
	local prisoner = exports.qbx_core:GetPlayer(prisonerSource)
	
	if not visitor or not prisoner then return end
	
	local visitorName = visitor.PlayerData.charinfo.firstname .. ' ' .. visitor.PlayerData.charinfo.lastname
	
	-- Gửi popup cho tù nhân
	TriggerClientEvent('esx_communityservice:receiveVisitRequest', prisonerSource, visitorName, src)
	exports.qbx_core:Notify(src, 'Đã gửi yêu cầu thăm tù', 'success', 3000)
end)

-- Chấp nhận thăm tù
RegisterNetEvent('esx_communityservice:acceptVisit', function(visitorSource)
	local prisonerSource = source
	local visitor = exports.qbx_core:GetPlayer(visitorSource)
	local prisoner = exports.qbx_core:GetPlayer(prisonerSource)
	
	if not visitor or not prisoner then return end
	
	-- Kiểm tra tiền của người thăm trước
	if visitor.Functions.GetMoney('cash') < Config.VisitFee and visitor.Functions.GetMoney('bank') < Config.VisitFee then
		exports.qbx_core:Notify(visitorSource, 'Bạn không đủ tiền để thăm tù! Cần $' .. Config.VisitFee, 'error', 5000)
		exports.qbx_core:Notify(prisonerSource, 'Người thăm không đủ tiền', 'error', 3000)
		return
	end
	
	-- Trừ tiền ngay
	if visitor.Functions.GetMoney('cash') >= Config.VisitFee then
		visitor.Functions.RemoveMoney('cash', Config.VisitFee, 'prison-visit-fee')
	else
		visitor.Functions.RemoveMoney('bank', Config.VisitFee, 'prison-visit-fee')
	end
	
	-- Lưu vị trí cũ của visitor
	local ped = GetPlayerPed(visitorSource)
	local oldCoords = GetEntityCoords(ped)
	Player(visitorSource).state.oldCoords = {x = oldCoords.x, y = oldCoords.y, z = oldCoords.z}
	Player(visitorSource).state.isVisiting = true
	
	-- Teleport visitor vào tù
	SetEntityCoords(ped, Config.ServiceLocation.x, Config.ServiceLocation.y, Config.ServiceLocation.z)
	SetPlayerRoutingBucket(visitorSource, 1)
	
	-- Thông báo
	local prisonerName = prisoner.PlayerData.charinfo.firstname .. ' ' .. prisoner.PlayerData.charinfo.lastname
	exports.qbx_core:Notify(visitorSource, 'Đã trừ $' .. Config.VisitFee .. ' và bắt đầu thăm ' .. prisonerName, 'success', 5000)
	exports.qbx_core:Notify(prisonerSource, 'Đã chấp nhận yêu cầu thăm tù', 'success', 3000)
end)

-- Từ chối thăm tù
RegisterNetEvent('esx_communityservice:denyVisit', function(visitorSource)
	exports.qbx_core:Notify(visitorSource, 'Tù nhân đã từ chối yêu cầu thăm tù', 'error', 3000)
end)

-- Kết thúc thăm tù
RegisterNetEvent('esx_communityservice:endVisit', function()
	local src = source
	local xPlayer = exports.qbx_core:GetPlayer(src)
	
	if not xPlayer then return end
	
	-- Kiểm tra có đang thăm tù không
	if not Player(src).state.isVisiting then
		exports.qbx_core:Notify(src, 'Bạn không đang thăm tù!', 'error', 3000)
		return
	end
	
	-- Teleport về vị trí cũ hoặc release location
	local oldCoords = Player(src).state.oldCoords
	local ped = GetPlayerPed(src)
	
	if oldCoords then
		SetEntityCoords(ped, oldCoords.x, oldCoords.y, oldCoords.z)
	else
		SetEntityCoords(ped, Config.ReleaseLocation.x, Config.ReleaseLocation.y, Config.ReleaseLocation.z)
	end
	
	-- Trả về bucket 0
	SetPlayerRoutingBucket(src, 0)
	Player(src).state.isVisiting = false
	Player(src).state.oldCoords = nil
	
	exports.qbx_core:Notify(src, 'Đã kết thúc thăm tù', 'success', 3000)
end)

-- Event nhận từ Diemuytin khi người chơi hết uy tín
RegisterNetEvent('nl_hotcut:imprisonByReputation', function(targetSource)
	local xPlayer = exports.qbx_core:GetPlayer(targetSource)
	if not xPlayer then return end
	
	local identifier = xPlayer.PlayerData.citizenid
	
	-- Kiểm tra cooldown để tránh phạt trùng
	local currentTime = GetGameTimer()
	if checkCooldowns[identifier] and (currentTime - checkCooldowns[identifier]) < COOLDOWN_TIME then
		--print("^3[Reputation Prison] Skipping for " .. identifier .. " (cooldown active)^0")
		return
	end
	
	-- Cập nhật cooldown
	checkCooldowns[identifier] = currentTime
	
	local actions = Config.ReputationPrisonActions or 200
	
	-- Bỏ tù với số actions đã config
	MySQL.insert('INSERT INTO communityservice (identifier, actions_remaining) VALUES (?, ?) ON DUPLICATE KEY UPDATE actions_remaining = actions_remaining + ?',
		{xPlayer.PlayerData.citizenid, actions, actions},
		function(rowsChanged)
			if rowsChanged then
				exports.qbx_core:Notify(targetSource, 'Bạn đã bị bỏ tù do điểm uy tín quá thấp! (' .. actions .. ' bãi)', 'error', 10000)
				
				-- Log Discord - Đi tù do điểm uy tín
				local characterName = xPlayer.PlayerData.charinfo.lastname .. " " .. xPlayer.PlayerData.charinfo.firstname
                local reputationLogFields = {
                    {
                        ["name"] = "👤 Tù nhân",
                        ["value"] = characterName .. " (PID: " .. xPlayer.PlayerData.pid .. ")",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "⚖️ Số bãi phạt",
                        ["value"] = actions .. " bãi",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "📉 Lý do",
                        ["value"] = "Điểm uy tín quá thấp",
                        ["inline"] = false
                    }
                }
                
                -- Gửi log phạt uy tín
                SendDiscordLog(
                    "⚠️ Đi Tù Do Điểm Uy Tín",
                    "Hệ thống tự động phạt do điểm uy tín quá thấp",
                    15105570, -- Màu cam
                    reputationLogFields,
                    DISCORD_WEBHOOK_PRISON
                )
                
				TriggerEvent('esx_communityservice:checkIfSentenced', targetSource)
			end
		end
	)
end)




-- Command giảm thời gian tù (admin & mod, hỗ trợ live console & PID)
lib.addCommand('giamthoigiantu', {
	help = 'Giảm thời gian tù của người chơi (PID hoặc Server ID)',
	restricted = {'group.admin', 'group.mod'},
	params = {
		{
			name = 'target',
			type = 'number',
			help = 'PID hoặc Server ID người chơi'
		},
		{
			name = 'actions',
			type = 'number',
			help = 'Số bãi muốn giảm'
		}
	}
}, function(source, args)
	local src = source
	local inputTarget = tonumber(args.target or args.playerId or args[1])
	local actionsToReduce = tonumber(args.actions or args[2])

	local function notifySender(msg, msgType)
		if src ~= 0 then
			exports.qbx_core:Notify(src, msg, msgType or 'inform', 3000)
		else
			print("[giamthoigiantu] " .. msg)
		end
	end

	if not inputTarget or not actionsToReduce or actionsToReduce <= 0 then
		notifySender("Vui lòng nhập đúng PID/Server ID và số bãi cần giảm (> 0)!", "error")
		return
	end

	-- Lấy thông tin người thực hiện lệnh
	local adminName = "Console"
	local adminPid = 0
	local discordID = "Không có"
	if src ~= 0 then
		local adminPlayer = exports.qbx_core:GetPlayer(src)
		if adminPlayer then
			adminName = adminPlayer.PlayerData.charinfo.lastname .. " " .. adminPlayer.PlayerData.charinfo.firstname
			adminPid = adminPlayer.PlayerData.pid
		end
		for _, id in ipairs(GetPlayerIdentifiers(src)) do
			if string.match(id, "discord:") then
				discordID = "<@" .. string.gsub(id, "discord:", "") .. ">"
				break
			end
		end
	end

	local function processReduction(cid, pid, pName, onlineTarget)
		MySQL.query('SELECT actions_remaining FROM communityservice WHERE identifier = ?', {cid}, function(result)
			if result and result[1] then
				local currentActions = tonumber(result[1].actions_remaining) or 0
				local newActions = math.max(0, currentActions - actionsToReduce)
				local actualReduced = currentActions - newActions

				if newActions == 0 then
					-- Thả tù nếu hết bãi
					if onlineTarget then
						exports.qbx_core:Notify(onlineTarget.PlayerData.source, 'Đã được thả tù do admin giảm hết thời gian!', 'success', 5000)
						releaseFromCommunityService(onlineTarget.PlayerData.source, "admin")
					else
						-- Offline: Xóa khỏi database
						MySQL.Async.execute('DELETE FROM communityservice WHERE identifier = ?', {cid})
					end

					notifySender('Đã giảm ' .. actualReduced .. ' bãi và thả tù player PID ' .. pid, 'success')

					-- Log Discord
					local logFields = {
						{["name"] = "👤 Tù nhân", ["value"] = pName .. " (PID: " .. pid .. ")" .. (onlineTarget and "" or " [Offline]"), ["inline"] = false},
						{["name"] = "👮 Người thực hiện", ["value"] = adminName .. " (PID: " .. adminPid .. ") " .. discordID, ["inline"] = false},
						{["name"] = "📉 Số bãi giảm", ["value"] = actualReduced .. " bãi (từ " .. currentActions .. " → 0)", ["inline"] = false},
						{["name"] = "✅ Kết quả", ["value"] = "Đã thả tù", ["inline"] = false}
					}
					SendDiscordLog("🔓 Giảm Thời Gian & Thả Tù", "Lệnh /giamthoigiantu", 5763719, logFields, DISCORD_WEBHOOK_RELEASE)
				else
					-- Giảm số bãi
					MySQL.execute('UPDATE communityservice SET actions_remaining = ? WHERE identifier = ?', {newActions, cid}, function()
						if onlineTarget then
							exports.qbx_core:Notify(onlineTarget.PlayerData.source, 'Admin đã giảm ' .. actualReduced .. ' bãi! Còn lại: ' .. newActions .. ' bãi', 'success', 5000)
							TriggerClientEvent('esx_communityservice:updateActions', onlineTarget.PlayerData.source, newActions)
							TriggerEvent('esx_communityservice:checkIfSentenced', onlineTarget.PlayerData.source)
						end

						notifySender('Đã giảm ' .. actualReduced .. ' bãi cho player PID ' .. pid .. '. Còn lại: ' .. newActions .. ' bãi', 'success')

						-- Log Discord
						local logFields = {
							{["name"] = "👤 Tù nhân", ["value"] = pName .. " (PID: " .. pid .. ")" .. (onlineTarget and "" or " [Offline]"), ["inline"] = false},
							{["name"] = "👮 Người thực hiện", ["value"] = adminName .. " (PID: " .. adminPid .. ") " .. discordID, ["inline"] = false},
							{["name"] = "📉 Số bãi giảm", ["value"] = actualReduced .. " bãi (từ " .. currentActions .. " → " .. newActions .. ")", ["inline"] = false},
							{["name"] = "📊 Còn lại", ["value"] = newActions .. " bãi", ["inline"] = false}
						}
						SendDiscordLog("📉 Giảm Thời Gian Tù", "Lệnh /giamthoigiantu", 5763719, logFields, DISCORD_WEBHOOK_RELEASE)
					end)
				end
			else
				notifySender('Người chơi này không có án tù trong hệ thống!', 'error')
			end
		end)
	end

	-- Kiểm tra online theo Server ID trước
	local targetPlayer = exports.qbx_core:GetPlayer(inputTarget)
	if targetPlayer then
		local citizenid = targetPlayer.PlayerData.citizenid
		local targetPid = targetPlayer.PlayerData.pid
		local targetName = targetPlayer.PlayerData.charinfo.lastname .. " " .. targetPlayer.PlayerData.charinfo.firstname
		processReduction(citizenid, targetPid, targetName, targetPlayer)
	else
		-- Tra cứu qua database theo PID
		MySQL.Async.fetchAll('SELECT citizenid, pid, charinfo FROM players WHERE pid = ? LIMIT 1', {inputTarget}, function(pResult)
			if pResult and pResult[1] then
				local dbCitizenId = pResult[1].citizenid
				local dbPid = pResult[1].pid
				local charInfo = pResult[1].charinfo and json.decode(pResult[1].charinfo) or nil
				local dbName = charInfo and (charInfo.lastname .. " " .. charInfo.firstname) or ("PID " .. dbPid)
				local onlineP = exports.qbx_core:GetPlayerByCitizenId(dbCitizenId)
				if onlineP then
					dbName = onlineP.PlayerData.charinfo.lastname .. " " .. onlineP.PlayerData.charinfo.firstname
				end
				processReduction(dbCitizenId, dbPid, dbName, onlineP)
			else
				notifySender('Không tìm thấy người chơi với ID/PID: ' .. inputTarget, 'error')
			end
		end)
	end
end)
