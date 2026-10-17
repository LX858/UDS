local isBusy = false

function decodeJson(raw, fallback)
	if not raw or raw == '' then
		return fallback
	end

	local ok, data = pcall(json.decode, raw)
	if not ok or type(data) ~= 'table' then
		return fallback
	end

	return data
end

function ExecuteSql(query, parameters, cb)
	local promise = promise:new()
	while isBusy do
		Wait(0)
	end
	isBusy = true
	if Config.SQLScript == 'oxmysql' then
		exports.oxmysql:execute(query, parameters, function(data)
			promise:resolve(data)
			isBusy = false

			if cb then
				cb(data)
			end
		end)
	elseif Config.SQLScript == 'ghmattimysql' then
		exports.ghmattimysql:execute(query, parameters, function(data)
			promise:resolve(data)
			isBusy = false

			if cb then
				cb(data)
			end
		end)
	elseif Config.SQLScript == 'mysql-async' then
		MySQL.Async.fetchAll(query, parameters, function(data)
			promise:resolve(data)
			isBusy = false
			if cb then
				cb(data)
			end
		end)
	end
	while isBusy do
		Wait(0)
	end
	return Citizen.Await(promise)
end
