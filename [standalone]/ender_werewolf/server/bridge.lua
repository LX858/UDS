function GetPlayerFromId(playerSrc)
	if not playerSrc then return end
	playerSrc = tonumber(playerSrc)

	if Config.Framework == 'qb' then
		return exports.qbx_core:GetPlayer(playerSrc) or (Framework and Framework.Functions.GetPlayer(playerSrc))
	elseif Config.Framework == 'esx' then
		return Framework.GetPlayerFromId(playerSrc)
	end
end

function GetFrameworkPlayerName(player, source)
	if not player then
		source = tonumber(source)
		return GetPlayerName(source) or ('Player %s'):format(source)
	end

	if Config.Framework == 'qb' then
		local charinfo = player.PlayerData and player.PlayerData.charinfo
		if charinfo then
			return ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')
		end
	elseif Config.Framework == 'esx' then
		return player.getName and player.getName() or player.name
	end

	return ('Player %s'):format(source or player.source or 0)
end

function GetPlayerIdentifier(player)
	if not player then return end

	if Config.Framework == 'qb' then
		return player.PlayerData and player.PlayerData.citizenid
	elseif Config.Framework == 'esx' then
		return player.identifier
	end
end

function IsPlayerAdmin(source)
	local player = GetPlayerFromId(source)
	if not player then return false end

	if Config.Framework == 'qb' then
		return IsPlayerAceAllowed(source, 'command') or (player.PlayerData and player.PlayerData.group == 'admin')
	elseif Config.Framework == 'esx' then
		local group = player.getGroup and player.getGroup() or 'user'
		return group == 'admin' or group == 'superadmin'
	end

	return IsPlayerAceAllowed(source, 'command')
end

function NotifyPlayer(source, message, notifyType)
	notifyType = notifyType or 'inform'

	if Config.Framework == 'qb' then
		exports.qbx_core:Notify(source, message, notifyType)
	elseif Config.Framework == 'esx' then
		local player = GetPlayerFromId(source)
		if player and player.showNotification then
			player.showNotification(message)
		else
			TriggerClientEvent('esx:showNotification', source, message)
		end
	else
		TriggerClientEvent('chat:addMessage', source, { args = { 'Werewolf', message } })
	end
end

function GetClientPlayerData(source)
	local player = GetPlayerFromId(source)
	if not player then return nil end

	if Config.Framework == 'qb' then
		local data = player.PlayerData
		return {
			id = data.citizenid,
			identifier = data.citizenid,
			source = source,
			name = GetFrameworkPlayerName(player, source),
			job = {
				name = data.job.name,
				label = data.job.label,
				grade = data.job.grade.level,
				grade_label = data.job.grade.name,
			},
		}
	elseif Config.Framework == 'esx' then
		local job = player.job or {}
		return {
			id = player.source,
			identifier = player.identifier,
			source = source,
			name = GetFrameworkPlayerName(player, source),
			job = {
				name = job.name,
				label = job.label,
				grade = job.grade,
				grade_label = job.grade_label,
			},
		}
	end

	return {
		id = source,
		identifier = tostring(source),
		source = source,
		name = GetFrameworkPlayerName(nil, source),
		job = { name = 'citizen', label = 'Citizen', grade = 0, grade_label = '' },
	}
end
