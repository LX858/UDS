function GetJob()
	if Config.Framework == 'qb' then
		local data = exports.qbx_core:GetPlayerData()
		return data and data.job
	elseif Config.Framework == 'esx' then
		return Framework.GetPlayerData().job
	end
end

function GetClientPlayerData()
	if Config.Framework == 'qb' then
		local data = exports.qbx_core:GetPlayerData()
		if not data then return nil end
		return {
			id = data.citizenid,
			identifier = data.citizenid,
			source = cache.serverId,
			name = ('%s %s'):format(data.charinfo.firstname, data.charinfo.lastname),
			job = {
				name = data.job.name,
				label = data.job.label,
				grade = data.job.grade.level,
				grade_label = data.job.grade.name,
			},
		}
	elseif Config.Framework == 'esx' then
		local data = Framework.GetPlayerData()
		return {
			id = data.source,
			identifier = data.identifier,
			source = cache.serverId,
			name = data.name or GetPlayerName(PlayerId()),
			job = {
				name = data.job.name,
				label = data.job.label,
				grade = data.job.grade,
				grade_label = data.job.grade_label,
			},
		}
	end

	return {
		id = cache.serverId,
		identifier = tostring(cache.serverId),
		source = cache.serverId,
		name = GetPlayerName(PlayerId()),
		job = { name = 'citizen', label = 'Citizen', grade = 0, grade_label = '' },
	}
end

function Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
	if Config.Framework == 'qb' then
		exports.qbx_core:Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon,
			notifyIconColor)
	elseif Config.Framework == 'esx' then
		Framework.ShowNotification(text, notifyType, duration, subTitle)
	else
		print(('Notify: %s'):format(text))
	end
end
