local function buildAccountsFromPlayerData(pd)
	local accounts = {}
	local money = pd.money or {}

	table.insert(accounts, { name = 'money', money = money.cash or 0 })
	table.insert(accounts, { name = 'bank', money = money.bank or 0 })

	local metadata = pd.metadata or {}
	local metaMap = (Config.QBX and Config.QBX.metadataAccounts) or {
		point = 'point',
		pumpkin = 'pumpkin',
	}

	for accountName, metaKey in pairs(metaMap) do
		table.insert(accounts, {
			name = accountName,
			money = tonumber(metadata[metaKey]) or 0,
		})
	end

	return accounts
end

function UsesDbCoinColumn()
	local cfg = Config.QBX and Config.QBX.coinColumn
	return cfg and cfg.table and cfg.idColumn and cfg.column
end

function GetClientPlayerData()
	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local pd = exports.qbx_core:GetPlayerData()
		if not pd or not pd.citizenid then
			return {
				idCard = '',
				name = '',
				job = { label = '' },
				accounts = {},
			}
		end

		local charinfo = pd.charinfo or {}
		local firstname = charinfo.firstname or ''
		local lastname = charinfo.lastname or ''
		local fullName = pd.name or (firstname .. ' ' .. lastname):gsub('^%s+', ''):gsub('%s+$', '')

		return {
			idCard = pd.citizenid,
			name = fullName,
			job = {
				label = (pd.job and pd.job.label) or '',
			},
			accounts = buildAccountsFromPlayerData(pd),
		}
	end

	if Config.Framework == 'ProjectStarboy' then
		return Framework.PlayerData
	end

	if Config.Framework == 'esx' then
		return Framework.GetPlayerData()
	end

	return {
		idCard = '',
		name = '',
		job = { label = '' },
		accounts = {},
	}
end

function GetJob()
	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		local pd = exports.qbx_core:GetPlayerData()
		return pd and pd.job or nil
	end
	if Config.Framework == 'ProjectStarboy' then
		return Framework.PlayerData.job
	end
	if Config.Framework == 'esx' then
		return Framework.GetPlayerData().job
	end
end

function Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
	if Config.OxNotify then
		lib.notify({
			id = text,
			title = subTitle or 'Thông báo',
			description = text,
			type = notifyType or 'info',
			duration = duration or 5000,
		})
		return
	end
	if Config.Framework == 'qbx' or Config.Framework == 'qb' then
		exports.qbx_core:Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon,
			notifyIconColor)
	elseif Config.Framework == 'ProjectStarboy' then
		Framework.Notify(text, notifyType, duration)
	elseif Config.Framework == 'esx' then
		Framework.ShowNotification(text, notifyType, duration, subTitle)
	else
		print(('Notify: Unsupported framework %s'):format(Config.Framework))
	end
end

function PatchClientFramework()
	Framework = Framework or {}
	Framework.GetPlayerData = GetClientPlayerData
	Framework.ShowNotification = function(text, notifyType, duration, subTitle)
		Notify(text, notifyType, duration, subTitle)
	end
end
