--- Engine lấy dữ liệu BXH theo config — đọc `xn_sellitem_leaderboard`
BoardFetch = BoardFetch or {}

local function buildPlayerEntry(row, value, rank)
	local label = row.label
	if not label or label:gsub('%s', '') == '' then
		label = row.name or ('Người chơi #' .. rank)
	end
	return {
		rank = rank,
		name = row.name,
		label = label,
		level = row.level or 0,
		value = value or 0,
		logoUrl = '',
		slogan = '',
	}
end

function BoardFetch.RunQuery(query, limit)
	if type(query) ~= 'string' or query == '' then return {} end
	limit = tonumber(limit) or Config.DefaultLimit or 10
	local ok, rows = pcall(function()
		return MySQL.query.await(query, { limit })
	end)
	return (ok and rows) or {}
end

local function boardLimit(board, boardId)
	if boardId and BoardRegistry then
		return BoardRegistry.GetLimit(boardId)
	end
	return board.limit or Config.DefaultLimit or 10
end

local function fetchSql(board, boardId)
	local ds = board.dataSource
	if not ds or not ds.query or ds.query == '' then
		return {}
	end

	local limit = boardLimit(board, boardId)
	local rows = {}
	local ok, result = pcall(function()
		return MySQL.query.await(ds.query, { limit })
	end)

	if ok then
		rows = result or {}
	end

	local valueField = ds.valueField or 'sort_value'
	local entries = {}

	for i, row in ipairs(rows) do
		local value = tonumber(row[valueField]) or row[valueField] or 0
		entries[#entries + 1] = buildPlayerEntry(row, value, i)
	end

	return entries
end

function BoardFetch.Fetch(boardId, board)
	local ds = board.dataSource
	if not ds or not ds.type then
		return nil, 'missing_data_source'
	end

	if ds.type == 'sql' then
		return fetchSql(board, boardId)
	end

	return nil, 'unknown_data_source'
end

local function resolveFromList(entries, myKey)
	for i, entry in ipairs(entries) do
		if entry.name == myKey then
			return {
				myEntryKey = myKey,
				myRank = i,
				myValue = entry.value,
				myLabel = entry.label,
			}
		end
	end
	return nil
end

local function resolveSqlOffList(myKey, ctx)
	local row = MySQL.single.await(ctx.lookup, { myKey })
	if not row then return nil end

	local valueField = ctx.valueField or 'value'
	local labelField = ctx.labelField or 'label'
	local value = tonumber(row[valueField]) or row[valueField] or 0

	if ctx.minValue and value < ctx.minValue then
		return nil
	end

	local rank = MySQL.scalar.await(ctx.rank, { value }) or 0
	return {
		myEntryKey = myKey,
		myRank = rank,
		myValue = value,
		myLabel = row[labelField] or myKey,
	}
end

function BoardFetch.ResolvePlayer(entries, myKey, board, _boardId)
	if not myKey or myKey == '' then return nil end

	local onList = resolveFromList(entries, myKey)
	if onList then
		onList.inTopList = true
		return onList
	end

	if board.resolveOffList == true then
		local ctx = board.playerOffList
		if ctx and ctx.lookup and ctx.rank then
			local off = resolveSqlOffList(myKey, ctx)
			if off then
				off.inTopList = false
				return off
			end
		end
	end

	return {
		myEntryKey = myKey,
		inTopList = false,
	}
end
