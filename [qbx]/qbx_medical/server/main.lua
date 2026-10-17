local sharedConfig = require 'config.shared'
local logger = require '@qbx_core.modules.logger'

-- Cooldown cho ping EMS (30 giây)
local pingCooldowns = {}
local playersWaitingForEMS = {}
local PING_COOLDOWN = 30 -- giây

---@class Injury
---@field severity integer
---@field weaponHash number

---@class PlayerStatus
---@field injuries table<BodyPartKey, Injury>
---@field isBleeding number

---@alias Source number

local triggerEventHooks = require '@qbx_core.modules.hooks'

local function getDeathState(src)
	local player = exports.qbx_core:GetPlayer(src)
	return player.PlayerData.metadata.isdead and sharedConfig.deathState.DEAD
		or player.PlayerData.metadata.inlaststand and sharedConfig.deathState.LAST_STAND
		or sharedConfig.deathState.ALIVE
end

-- Function để khôi phục dữ liệu y tế
local function restoreMedicalData(src)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end

	local playerState = Player(src).state
	if not playerState then return end

	-- Debug: In ra console để kiểm tra
	--print(string.format("^2[qbx_medical] Restoring medical data for player %s^7", src))

	-- Khôi phục trạng thái mất máu từ metadata
	local savedBleedLevel = player.PlayerData.metadata.bleedLevel or 0
	--print(string.format("^3[qbx_medical] Restored bleed level: %s^7", savedBleedLevel))
	playerState:set(BLEED_LEVEL_STATE_BAG, savedBleedLevel, true)

	-- Khôi phục trạng thái bị thương từ metadata
	local savedInjuries = player.PlayerData.metadata.medicalInjuries or {}
	local injuryCount = 0
	for bodyPartKey in pairs(sharedConfig.bodyParts) do
		local injury = savedInjuries[bodyPartKey]
		if injury then
			injuryCount = injuryCount + 1
			--print(string.format("^3[qbx_medical] Restored injury: %s - Severity: %s^7", bodyPartKey, injury.severity))
		end
		playerState:set(BODY_PART_STATE_BAG_PREFIX .. bodyPartKey, injury, true)
	end
	--print(string.format("^3[qbx_medical] Total restored injuries: %s^7", injuryCount))
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
	local playerState = Player(source).state
	local player = exports.qbx_core:GetPlayer(source)

	-- Khôi phục trạng thái death state
	playerState:set(DEATH_STATE_STATE_BAG, getDeathState(source), true)

	-- Sử dụng CreateThread để đảm bảo player data đã được load đầy đủ
	CreateThread(function()
		Wait(1000) -- Đợi 1 giây để đảm bảo tất cả dữ liệu đã load
		restoreMedicalData(source)
	end)
end)

-- Backup event cho trường hợp QBCore:Server:OnPlayerLoaded không trigger
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
	CreateThread(function()
		Wait(2000) -- Đợi lâu hơn một chút
		restoreMedicalData(source)
	end)
end)

-- Event handler khi người chơi disconnect để đảm bảo dữ liệu được lưu
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end

	local playerState = Player(src).state
	if not playerState then return end

	-- Lưu trạng thái hiện tại vào metadata trước khi disconnect
	local currentBleedLevel = playerState[BLEED_LEVEL_STATE_BAG] or 0
	player.Functions.SetMetaData('bleedLevel', currentBleedLevel)

	local currentInjuries = {}
	for bodyPartKey in pairs(sharedConfig.bodyParts) do
		local injury = playerState[BODY_PART_STATE_BAG_PREFIX .. bodyPartKey]
		if injury then
			currentInjuries[bodyPartKey] = injury
		end
	end
	player.Functions.SetMetaData('medicalInjuries', currentInjuries)
end)

AddStateBagChangeHandler(DEATH_STATE_STATE_BAG, '', function(bagName, _, value)
	local playerId = GetPlayerFromStateBagName(bagName)
	local player = exports.qbx_core:GetPlayer(playerId)
	if not player then return end
	player.Functions.SetMetaData('isdead', value == sharedConfig.deathState.DEAD)
	player.Functions.SetMetaData('inlaststand', value == sharedConfig.deathState.LAST_STAND)
	local isDeadOrLastStand = value == sharedConfig.deathState.DEAD or value == sharedConfig.deathState.LAST_STAND
	Player(playerId).state:set("isDead", isDeadOrLastStand, true)
	Player(playerId).state:set("muted", isDeadOrLastStand, true)
	MumbleSetPlayerMuted(playerId, isDeadOrLastStand)
end)

-- Handler để lưu bleed level vào metadata
AddStateBagChangeHandler(BLEED_LEVEL_STATE_BAG, '', function(bagName, _, value)
	local playerId = GetPlayerFromStateBagName(bagName)
	local player = exports.qbx_core:GetPlayer(playerId)
	if not player then return end

	--print(string.format("^4[qbx_medical] Saving bleed level %s for player %s^7", value or 0, playerId))
	player.Functions.SetMetaData('bleedLevel', value or 0)
end)

-- Handler để lưu injuries vào metadata
for bodyPartKey in pairs(sharedConfig.bodyParts) do
	AddStateBagChangeHandler(BODY_PART_STATE_BAG_PREFIX .. bodyPartKey, '', function(bagName, _, value)
		local playerId = GetPlayerFromStateBagName(bagName)
		local player = exports.qbx_core:GetPlayer(playerId)
		if not player then return end

		local currentInjuries = player.PlayerData.metadata.medicalInjuries or {}
		currentInjuries[bodyPartKey] = value

		-- if value then
			--print(string.format("^4[qbx_medical] Saving injury %s (severity: %s) for player %s^7", bodyPartKey, value.severity, playerId))
		-- else
			--print(string.format("^4[qbx_medical] Clearing injury %s for player %s^7", bodyPartKey, playerId))
		-- end

		player.Functions.SetMetaData('medicalInjuries', currentInjuries)
	end)
end

---@param player table|number
local function revivePlayer(player)
    local playerId = type(player) == 'table' and player.PlayerData.source or player --[[@as number]]

    -- Clear medical data when revived
    local playerObj = exports.qbx_core:GetPlayer(playerId)
    if playerObj then
        playerObj.Functions.SetMetaData('bleedLevel', 0)
        playerObj.Functions.SetMetaData('medicalInjuries', {})
    end

    TriggerClientEvent('qbx_medical:client:playerRevived', playerId)
end

exports('Revive', revivePlayer)

---removes all ailments, sets to full health, and fills up hunger and thirst.
---@param src Source
local function heal(src)
    -- Clear medical data from metadata
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        player.Functions.SetMetaData('bleedLevel', 0)
        player.Functions.SetMetaData('medicalInjuries', {})
    end

    TriggerClientEvent('qbx_medical:client:heal', src, 'full')
end

exports('Heal', heal)

---Removes any injuries with severity 2 or lower. Stops bleeding if bleed level is less than 3.
---@param src Source
local function healPartially(src)
    -- Update metadata for partial healing
    local player = exports.qbx_core:GetPlayer(src)
    if player then
        local currentInjuries = player.PlayerData.metadata.medicalInjuries or {}
        local currentBleedLevel = player.PlayerData.metadata.bleedLevel or 0

        -- Remove minor injuries (severity 2 or lower)
        for bodyPartKey, injury in pairs(currentInjuries) do
            if injury and injury.severity and injury.severity <= 2 then
                currentInjuries[bodyPartKey] = nil
            end
        end

        -- Reduce bleed level if less than 3
        if currentBleedLevel < 3 then
            currentBleedLevel = 0
        end

        player.Functions.SetMetaData('medicalInjuries', currentInjuries)
        player.Functions.SetMetaData('bleedLevel', currentBleedLevel)
    end

    TriggerClientEvent('qbx_medical:client:heal', src, 'partial')
end

exports('HealPartially', healPartially)

---Compatibility with txAdmin Menu's heal options.
---This is an admin only server side event that will pass the target player id or -1.
---@class EventData
---@field id number
---@param eventData EventData
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= 'monitor' or type(eventData) ~= 'table' or type(eventData.id) ~= 'number' then
		return
	end

	revivePlayer(eventData.id)
	heal(eventData.id)
end)

local function getPlayerInjuries(state)
	local injuries = {}
	for bodyPartKey in pairs(sharedConfig.bodyParts) do
		injuries[bodyPartKey] = state[BODY_PART_STATE_BAG_PREFIX .. bodyPartKey]
	end
	return injuries
end

---Get human readable info on a player's health
---@param src Source
---@return {injuries: string[], bleedLevel: integer, bleedState: string, damageCauses: table<number, true>}
local function getPlayerStatus(src)
	local state = Player(src).state
	local bleedLevel = state[BLEED_LEVEL_STATE_BAG]
	local injuries = getPlayerInjuries(state)

	local injuryStatuses = {}
	local weaponsThatDamagedPlayer = {}
	local i = 0
	for bodyPartKey, injury in pairs(injuries) do
        local bodyPart = sharedConfig.bodyParts[bodyPartKey]
		i += 1
        injuryStatuses[i] = bodyPart.label .. ' (' .. sharedConfig.woundLevels[injury.severity].label .. ')'
		weaponsThatDamagedPlayer[injury.weaponHash] = true
	end

	local status = {
		injuries = injuryStatuses,
		bleedLevel = bleedLevel,
		bleedState = sharedConfig.bleedingStates[bleedLevel],
		damageCauses = weaponsThatDamagedPlayer
	}

	return status
end

exports('GetPlayerStatus', getPlayerStatus)

---Đồng bộ trạng thái y tế từ StateBags vào metadata
---@param src Source
local function syncMedicalDataToMetadata(src)
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return false end

	local playerState = Player(src).state
	if not playerState then return false end

	-- Sync bleed level
	local currentBleedLevel = playerState[BLEED_LEVEL_STATE_BAG] or 0
	player.Functions.SetMetaData('bleedLevel', currentBleedLevel)

	-- Sync injuries
	local currentInjuries = {}
	for bodyPartKey in pairs(sharedConfig.bodyParts) do
		local injury = playerState[BODY_PART_STATE_BAG_PREFIX .. bodyPartKey]
		if injury then
			currentInjuries[bodyPartKey] = injury
		end
	end
	player.Functions.SetMetaData('medicalInjuries', currentInjuries)

	return true
end

exports('SyncMedicalData', syncMedicalDataToMetadata)

-- Export để force restore dữ liệu y tế
exports('RestoreMedicalData', restoreMedicalData)

---@param amount number
lib.callback.register('qbx_medical:server:setArmor', function(source, amount)
	local player = exports.qbx_core:GetPlayer(source)
	player.Functions.SetMetaData('armor', amount)
end)

local function resetHungerAndThirst(player)
	if type(player) == 'number' then
		player = exports.qbx_core:GetPlayer(player)
	end

	if not player then return end

	-- Lấy giá trị đói và khát hiện tại
	local currentHunger = player.PlayerData.metadata.hunger or 100
	local currentThirst = player.PlayerData.metadata.thirst or 100
    local sleepiness = player.PlayerData.metadata.sleepiness or 100

	player.Functions.SetMetaData('hunger', currentHunger)
	player.Functions.SetMetaData('thirst', currentThirst)
	if currentHunger < 30 then
        player.Functions.SetMetaData('hunger', 30)
    end
	if currentThirst < 30 then
        player.Functions.SetMetaData('thirst', 30)
    end
    if sleepiness < 50 then
        player.Functions.SetMetaData('sleepiness', 50)
    end
	TriggerClientEvent('hud:client:UpdateNeeds', player.PlayerData.source, currentHunger, currentThirst)
end

lib.callback.register('qbx_medical:server:resetHungerAndThirst', resetHungerAndThirst)

lib.addCommand('revive', {
    help = locale('info.revive_player_a'),
	restricted = 'group.mod',
	params = {
        { name = 'id', help = locale('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		exports.qbx_core:Notify(source, locale('error.not_online'), 'error')
		return
	end
	revivePlayer(args.id)
end)

lib.addCommand('kill', {
    help =  locale('info.kill'),
	restricted = 'group.mod',
	params = {
        { name = 'id', help = locale('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		exports.qbx_core:Notify(source, locale('error.not_online'), 'error')
		return
	end
	lib.callback.await('qbx_medical:client:killPlayer', args.id)
end)

lib.addCommand('aheal', {
    help =  locale('info.heal_player_a'),
	restricted = 'group.mod',
	params = {
        { name = 'id', help = locale('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		exports.qbx_core:Notify(source, locale('error.not_online'), 'error')
		return
	end
	heal(args.id)
end)

lib.addCommand('checkmedical', {
    help = 'Kiểm tra trạng thái y tế được lưu trữ của người chơi',
	restricted = 'group.admin',
	params = {
        { name = 'id', help = locale('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		exports.qbx_core:Notify(source, 'Người chơi không online', 'error')
		return
	end

	local bleedLevel = player.PlayerData.metadata.bleedLevel or 0
	local injuries = player.PlayerData.metadata.medicalInjuries or {}

	local injuryCount = 0
	local injuryList = {}
	for bodyPart, injury in pairs(injuries) do
		if injury then
			injuryCount = injuryCount + 1
			table.insert(injuryList, string.format("%s (Độ nặng: %s)", bodyPart, injury.severity or 'N/A'))
		end
	end

	local message = string.format(
		"Trạng thái y tế của %s:\n- Mức độ mất máu: %d\n- Số chấn thương: %d\n- Chi tiết: %s",
		player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
		bleedLevel,
		injuryCount,
		#injuryList > 0 and table.concat(injuryList, ', ') or 'Không có chấn thương'
	)

	exports.qbx_core:Notify(source, message, 'primary', 8000)
end)

lib.addCommand('restoremedical', {
    help = 'Force khôi phục dữ liệu y tế từ database',
	restricted = 'group.admin',
	params = {
        { name = 'id', help = locale('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		exports.qbx_core:Notify(source, 'Người chơi không online', 'error')
		return
	end

	restoreMedicalData(args.id)
	exports.qbx_core:Notify(source, string.format('Đã force khôi phục dữ liệu y tế cho ID: %s', args.id), 'success')
end)

lib.callback.register('qbx_medical:server:respawn', function(source)
	if not triggerEventHooks('respawn', {source = source}) then return false end
	TriggerEvent('qbx_medical:server:playerRespawned', source)
	return true
end)

lib.callback.register('qbx_medical:server:log', function(_, event, message)
	logger.log({source = 'qbx_medical', event = event, message = message})
end)

-- Event để xử lý yêu cầu sync dữ liệu từ client
RegisterNetEvent('qbx_medical:server:requestDataSync', function()
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player then
		--print(string.format("^1[qbx_medical] Cannot get player object for ID: %s^7", src))
		return
	end

	--print(string.format("^5[qbx_medical] Client requested data sync for player %s^7", src))

	-- Sync dữ liệu từ metadata vào StateBags
	local playerState = Player(src).state

	-- Sync bleed level
	local savedBleedLevel = player.PlayerData.metadata.bleedLevel or 0
	--print(string.format("^5[qbx_medical] Syncing bleed level: %s^7", savedBleedLevel))
	playerState:set(BLEED_LEVEL_STATE_BAG, savedBleedLevel, true)

	-- Sync injuries
	local savedInjuries = player.PlayerData.metadata.medicalInjuries or {}
	local syncCount = 0
	for bodyPartKey in pairs(sharedConfig.bodyParts) do
		local injury = savedInjuries[bodyPartKey]
		if injury then
			syncCount = syncCount + 1
			--print(string.format("^5[qbx_medical] Syncing injury: %s (severity: %s)^7", bodyPartKey, injury.severity))
		end
		playerState:set(BODY_PART_STATE_BAG_PREFIX .. bodyPartKey, injury, true)
	end
	--print(string.format("^5[qbx_medical] Synced %s injuries for player %s^7", syncCount, src))
end)

-- [TỐI ƯU 200+ PLAYERS] Dữ liệu y tế đã được tự động đồng bộ theo thời gian thực qua StateBag handlers
-- (AddStateBagChangeHandler) và khi thoát game (OnPlayerUnload). Thread backup định kỳ 30s đã được
-- tắt để tránh lặp O(N) qua toàn bộ 200+ người chơi gây lag/sụt tick server.

-- Helper lấy danh sách player ID theo Job
local function getDutyPlayers(jobName)
    local players = exports.vx_gps:ImplCall("Main", "GetJobPlayers", jobName) or {}
    return players
end

RegisterNetEvent('qbx_medical:server:createBillingInvoice', function()
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then
        --print('[qbx_medical] ERROR: Could not get player data for source ' .. src .. ' in createBillingInvoice')
        return
    end

    local config = require 'config.client'
    local price = config.autoRevivePrice
    local targetFullName = '[' .. xPlayer.PlayerData.pid .. '] ' .. xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
    local authorFullName = 'Bệnh viện'

    exports.oxmysql:execute('INSERT INTO okokBilling (receiver_identifier, receiver_name, author_identifier, author_name, society, society_name, item, invoice_value, status, notes, sent_date, limit_pay_date) VALUES (@receiver_identifier, @receiver_name, @author_identifier, @author_name, @society, @society_name, @item, @invoice_value, @status, @notes, CURRENT_TIMESTAMP(), DATE_ADD(CURRENT_TIMESTAMP(), INTERVAL @limit_pay_date DAY))', {
        ['@receiver_identifier'] = xPlayer.PlayerData.citizenid,
        ['@receiver_name'] = targetFullName,
        ['@author_identifier'] = 'hospital',
        ['@author_name'] = authorFullName,
        ['@society'] = 'ambulance',
        ['@society_name'] = 'Bệnh viện',
        ['@item'] = 'Dịch vụ cấp cứu tự động',
        ['@invoice_value'] = price,
        ['@status'] = "unpaid",
        ['@notes'] = 'Phí hồi sinh tự động (không có bác sĩ online)',
        ['@limit_pay_date'] = 1
    }, function(result)
        TriggerClientEvent('okokNotify:Alert', src, "HÓA ĐƠN", "Bạn vừa nhận được hóa đơn dịch vụ cấp cứu tự động $"..price.."!", 10000, 'info')
    end)
end)

RegisterNetEvent('qbx_medical:server:revivePlayerInPrison', function()
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then
        --print('[qbx_medical] ERROR: Could not get player data for source ' .. src .. ' in revivePlayerInPrison')
        return
    end

    exports.qbx_medical:Revive(src)
end)

RegisterNetEvent('qbx_medical:server:revivePlayerBeforeBed', function()
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then
        --print('[qbx_medical] ERROR: Could not get player data for source ' .. src .. ' in revivePlayerBeforeBed')
        return
    end

    exports.qbx_medical:Revive(src)
end)

RegisterNetEvent('qbx_medical:server:checkDoctorsAndStartTimer', function()
    local src = source
    local xPlayer = exports.qbx_core:GetPlayer(src)
    if not xPlayer then
        --print('[qbx_medical] ERROR: Could not get player data for source ' .. src .. ' in checkDoctorsAndStartTimer')
        return
    end

    -- Kiểm tra cooldown
    local currentTime = os.time()
    if pingCooldowns[src] and currentTime < pingCooldowns[src] then
        local remaining = pingCooldowns[src] - currentTime
        exports.qbx_core:Notify(src, 'Vui lòng đợi ' .. remaining .. ' giây trước khi ping lại!', 'error')
        return
    end

    -- Set cooldown
    pingCooldowns[src] = currentTime + PING_COOLDOWN

    local doctorCount = GlobalState['ambulance_count'] or 0

    if doctorCount == 0 then
        TriggerClientEvent('qbx_medical:client:doctorCheckResult', src, false)
    else
        local playerState = Player(src).state 
        if playerState and playerState.inPvP then 
            return exports.qbx_core:Notify(src, 'Bạn đang ở trong PvP', 'success')
        end
        local playerName = xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
        local citizenId = xPlayer.PlayerData.pid

        playersWaitingForEMS[src] = {
            name = playerName,
            citizenId = citizenId,
            timestamp = os.time()
        }

        TriggerEvent('xn_pingjob:callAmbulance', src)
        TriggerClientEvent('qbx_medical:client:doctorCheckResult', src, true)
    end
end)

RegisterNetEvent('qbx_medical:server:playerRevived', function()
    local src = source
    -- Clear cooldown khi revive
    pingCooldowns[src] = nil

    if playersWaitingForEMS[src] then
        playersWaitingForEMS[src] = nil
        local dutyEMS = getDutyPlayers('ambulance')
        for i = 1, #dutyEMS do
            TriggerClientEvent('qbx_medical:client:removePlayerGlow', dutyEMS[i], src)
        end
    end
end)

-- Queue system cho Discord webhook để tránh rate limit
local discordQueue = {}
local isProcessingQueue = false
local WEBHOOK_DELAY = 2000 -- 2 giây giữa mỗi webhook (max 30/phút)

-- Hàm xử lý queue
local function ProcessDiscordQueue()
    if isProcessingQueue then return end
    isProcessingQueue = true

    CreateThread(function()
        while #discordQueue > 0 do
            local logData = table.remove(discordQueue, 1)

            local webhookURL = "https://discord.com/api/webhooks/1512311677021065237/3293HSy_qNj061hK9qEqt3Qys8D2UhVFy7M23JCwadWvbCz3b3cFLYYgYX9-yukNo2UV"
            local embedColor = logData.isSuicide and 11447982 or 15158332
            local embedTitle = logData.isSuicide and "💀 Tử vong (Tự tử)" or "☠️ Tử vong (Bị giết)"

            local embeds = {
                {
                    ["title"] = embedTitle,
                    ["color"] = embedColor,
                    ["fields"] = {
                        {
                            ["name"] = "👤 Nạn nhân",
                            ["value"] = string.format("**[%s]** %s", logData.victim.citizenid, logData.victim.name),
                            ["inline"] = false
                        },
                        {
                            ["name"] = "⚔️ Người gây ra",
                            ["value"] = logData.killer,
                            ["inline"] = false
                        },
                        {
                            ["name"] = "🔫 Vũ khí",
                            ["value"] = logData.weapon,
                            ["inline"] = true
                        },
                        {
                            ["name"] = "📍 Vị trí",
                            ["value"] = "```" .. logData.position .. "```",
                            ["inline"] = false
                        }
                    },
                    ["footer"] = {
                        ["text"] = "Medical System - Death Log",
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
                }
            }

            local payload = json.encode({
                username = "Medical System",
                embeds = embeds
            })

            --print("^2[DISCORD] Sending webhook... (Queue: " .. #discordQueue .. " remaining)^7")

            PerformHttpRequest(webhookURL, function(err, text, headers)
                -- if err == 200 or err == 204 then
                --     --print("^2[DISCORD] Webhook sent successfully!^7")
                -- else
                --     --print("^1[DISCORD] Webhook failed! Error: " .. tostring(err) .. " Response: " .. tostring(text) .. "^7")
                -- end
            end, 'POST', payload, {
                ['Content-Type'] = 'application/json'
            })

            -- Chờ trước khi gửi webhook tiếp theo (tránh rate limit)
            if #discordQueue > 0 then
                Wait(WEBHOOK_DELAY)
            end
        end

        isProcessingQueue = false
    end)
end

-- Hàm thêm log vào queue
local function SendDiscordLog(victim, killer, weapon, position, isSuicide)
    table.insert(discordQueue, {
        victim = victim,
        killer = killer,
        weapon = weapon,
        position = position,
        isSuicide = isSuicide
    })

    --print("^3[DISCORD] Log added to queue. Total in queue: " .. #discordQueue .. "^7")
    ProcessDiscordQueue()
end

-- Event xử lý khi player bị thương/ngất (Last Stand)
RegisterNetEvent('qbx_medical:server:onPlayerLaststand', function(attackerSource, weaponHash)
    local src = source

    -- Loại trừ nếu player đang trong mini-csgo
    -- if exports['mini-csgo']:IsPlayerInGame(src) then
    --     return
    -- end

    local victim = exports.qbx_core:GetPlayer(src)
    if not victim then return end

    local victimCoords = GetEntityCoords(GetPlayerPed(src))
    local victimPosition = string.format("vector3(%.2f, %.2f, %.2f)", victimCoords.x, victimCoords.y, victimCoords.z)
    local victimName = victim.PlayerData.charinfo.firstname .. ' ' .. victim.PlayerData.charinfo.lastname
    local victimCitizenid = victim.PlayerData.pid

    local killerInfo = "Tự tử"
    local killerName = "Tự tử"
    local killerCitizenid = "N/A"
    local isSuicide = true

    -- Kiểm tra xem có phải tự chết không
    if attackerSource and attackerSource ~= src then
        local attacker = exports.qbx_core:GetPlayer(attackerSource)
        if attacker then
            killerName = attacker.PlayerData.charinfo.firstname .. ' ' .. attacker.PlayerData.charinfo.lastname
            killerCitizenid = attacker.PlayerData.pid
            killerInfo = string.format("[%s] %s", killerCitizenid, killerName)
            isSuicide = false
        end
    end

    -- Lấy tên vũ khí nếu có
    local weaponName = "Unknown"
    if weaponHash and weaponHash ~= 0 then
        local weapons = exports.qbx_core:GetWeapons()
        if weapons and weapons[weaponHash] then
            weaponName = weapons[weaponHash].label or weapons[weaponHash].name or "Unknown"
        end
    end

    -- Log death trong console
    local logMessage = string.format(
        "^3💀 DEATH LOG (Ngất)^7\n" ..
        "^1Nạn nhân:^7 [%s] %s\n" ..
        "^2Người gây ra:^7 %s\n" ..
        "^4Vũ khí:^7 %s\n" ..
        "^5Vị trí:^7 %s",
        victimCitizenid,
        victimName,
        killerInfo,
        weaponName,
        victimPosition
    )

    --print(logMessage)

    -- Gửi log tới Discord webhook
    SendDiscordLog(
        {citizenid = victimCitizenid, name = victimName},
        killerInfo,
        weaponName,
        victimPosition,
        isSuicide
    )

    -- Gửi log tới hệ thống log khác nếu có
    TriggerEvent('qb-log:server:CreateLog', 'death', 'Player Laststand', 'orange', logMessage, false)
end)

-- Event xử lý khi player chết và log death
RegisterNetEvent('qbx_medical:server:onPlayerDied', function(attackerSource, weaponHash)
    local src = source

    -- -- Loại trừ nếu player đang trong mini-csgo
    -- if exports['mini-csgo']:IsPlayerInGame(src) then
    --     return
    -- end

    local victim = exports.qbx_core:GetPlayer(src)
    if not victim then return end

    local victimCoords = GetEntityCoords(GetPlayerPed(src))
    local victimPosition = string.format("vector3(%.2f, %.2f, %.2f)", victimCoords.x, victimCoords.y, victimCoords.z)
    local victimName = victim.PlayerData.charinfo.firstname .. ' ' .. victim.PlayerData.charinfo.lastname
    local victimCitizenid = victim.PlayerData.pid

    local killerInfo = "Tự tử"
    local killerName = "Tự tử"
    local killerCitizenid = "N/A"
    local isSuicide = true

    -- Kiểm tra xem có phải tự chết không
    if attackerSource and attackerSource ~= src then
        local attacker = exports.qbx_core:GetPlayer(attackerSource)
        if attacker then
            killerName = attacker.PlayerData.charinfo.firstname .. ' ' .. attacker.PlayerData.charinfo.lastname
            killerCitizenid = attacker.PlayerData.pid
            killerInfo = string.format("[%s] %s", killerCitizenid, killerName)
            isSuicide = false
        end
    end

    -- Lấy tên vũ khí nếu có
    local weaponName = "Unknown"
    if weaponHash and weaponHash ~= 0 then
        local weapons = exports.qbx_core:GetWeapons()
        if weapons and weapons[weaponHash] then
            weaponName = weapons[weaponHash].label or weapons[weaponHash].name or "Unknown"
        end
    end

    -- Log death trong console
    local logMessage = string.format(
        "^3💀 DEATH LOG (Chết)^7\n" ..
        "^1Nạn nhân:^7 [%s] %s\n" ..
        "^2Người gây ra:^7 %s\n" ..
        "^4Vũ khí:^7 %s\n" ..
        "^5Vị trí:^7 %s",
        victimCitizenid,
        victimName,
        killerInfo,
        weaponName,
        victimPosition
    )

    --print(logMessage)

    -- Gửi log tới Discord webhook
    SendDiscordLog(
        {citizenid = victimCitizenid, name = victimName},
        killerInfo,
        weaponName,
        victimPosition,
        isSuicide
    )

    -- Gửi log tới hệ thống log khác nếu có
    TriggerEvent('qb-log:server:CreateLog', 'death', 'Player Death', 'red', logMessage, false)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source

    -- Clear cooldown khi disconnect
    pingCooldowns[src] = nil

    if playersWaitingForEMS[src] then
        local playerInfo = playersWaitingForEMS[src]

        TriggerEvent('xn_Pingjob:markPlayerDisconnected', src)

        local dutyEMS = getDutyPlayers('ambulance')
        for i = 1, #dutyEMS do
            local emsSrc = dutyEMS[i]
            exports.qbx_core:Notify(emsSrc, '⚠️ Người chơi ' .. playerInfo.name .. ' (đã ping) vừa thoát game!', 'error')
            TriggerClientEvent('qbx_medical:client:removePlayerGlow', emsSrc, src)
        end

        playersWaitingForEMS[src] = nil
    end
end)