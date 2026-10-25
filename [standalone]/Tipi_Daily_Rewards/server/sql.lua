
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

-- Yield on promises instead of polling a resource-wide SQL busy flag.
DailyOnlineRows = {}
local onlineLocks = {}
local activeOwners = {}
function WithDailyOnlineLock(identifier, fn, ...)
    local thread = coroutine.running()
    local previous = onlineLocks[identifier]
    if activeOwners[identifier] == thread then return fn(...) end
    local ticket = { done = promise.new(), owner = thread }
    onlineLocks[identifier] = ticket
    if previous then Citizen.Await(previous.done) end
    activeOwners[identifier] = thread
    local result = table.pack(pcall(fn, ...))
    activeOwners[identifier] = nil
    if onlineLocks[identifier] == ticket then onlineLocks[identifier] = nil end
    ticket.done:resolve(true)
    if not result[1] then error(result[2], 0) end
    return table.unpack(result, 2, result.n)
end

function ExecuteSql(query, parameters, cb)
    local result
    if Config.SQLScript == 'oxmysql' then
        -- Await rejects on SQL errors; no global lock survives a failed query.
        result = MySQL.query.await(query, parameters)
    else
        local pending = promise.new()
        local function resolve(data) pending:resolve(data) end
        if Config.SQLScript == 'ghmattimysql' then
            exports.ghmattimysql:execute(query, parameters, resolve)
        elseif Config.SQLScript == 'mysql-async' then
            MySQL.Async.fetchAll(query, parameters, resolve)
        else
            error('Unsupported SQLScript: ' .. tostring(Config.SQLScript))
        end
        result = Citizen.Await(pending)
    end
    if query:match('^UPDATE tipi_daily_rewards') and parameters then
        local identifier = parameters[#parameters]
        local cached = DailyOnlineRows[identifier]
        if cached and query:match('SET daily_online =') then
            cached.row.daily_online = parameters[1]
        else
            DailyOnlineRows[identifier] = nil
        end
    end
    if cb then cb(result) end
    return result
end
