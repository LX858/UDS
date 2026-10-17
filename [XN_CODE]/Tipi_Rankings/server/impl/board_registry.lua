--- Đọc Config.Boards — mọi tính năng server chỉ lấy config qua đây
BoardRegistry = BoardRegistry or {}

function BoardRegistry.Get(boardId)
	if not boardId or boardId == '' then return nil end
	local board = Config.Boards and Config.Boards[boardId]
	if not board or board.enabled == false then return nil end
	return board
end

function BoardRegistry.EachEnabled(callback)
	local ids = {}
	for boardId, board in pairs(Config.Boards or {}) do
		if board.enabled ~= false then
			ids[#ids + 1] = boardId
		end
	end
	table.sort(ids)
	for _, boardId in ipairs(ids) do
		callback(boardId, Config.Boards[boardId])
	end
end

function BoardRegistry.GetFeature(boardId, featureName)
	local board = BoardRegistry.Get(boardId)
	if not board then return nil end
	local feature = board[featureName]
	if not feature or feature.enabled == false then return nil end
	return feature
end

function BoardRegistry.ListWithFeature(featureName)
	local list = {}
	BoardRegistry.EachEnabled(function(boardId, board)
		local f = board[featureName]
		if f and f.enabled ~= false then
			list[#list + 1] = boardId
		end
	end)
	return list
end

function BoardRegistry.GetLimit(boardId)
	local board = BoardRegistry.Get(boardId)
	if not board then return Config.DefaultLimit or 20 end
	return board.limit or Config.DefaultLimit or 20
end

function BoardRegistry.GetInvalidateEvents(boardId)
	local board = BoardRegistry.Get(boardId)
	if not board then return {} end
	return board.invalidateOnEvents or {}
end

function BoardRegistry.GetDiscordWebhook(boardId, featureName)
	local board = BoardRegistry.Get(boardId)
	if not board or not featureName then return nil end
	local feature = board[featureName]
	if not feature or type(feature.discordWebhook) ~= 'string' or feature.discordWebhook == '' then
		return nil
	end
	return feature.discordWebhook
end
