---@class SVMainImpl : Impl
local Impl = NewImpl('Main')

local cache = {}
local cacheMetaVersion = Config.CacheVersion or 1

---@param boardId string|nil
function Impl:InvalidateCache(boardId)
	if boardId then
		cache[boardId] = nil
	else
		cache = {}
	end
	cacheMetaVersion = cacheMetaVersion + 1
end

local function getBoardConfig(boardId)
	if BoardRegistry then
		local board = BoardRegistry.Get(boardId)
		return board
	end
	return Config.Boards[boardId]
end

---@param source number
---@param boardId string
---@return table|nil, string|nil
function Impl:GetLeaderboard(source, boardId)
	local board = getBoardConfig(boardId)
	if not board or not board.enabled then
		return nil, 'board_not_found'
	end

	local now = os.time()
	local cacheKey = boardId
	local cached = cache[cacheKey]
	local entries
	local expectedVersion = Config.CacheVersion or 1

	if cached
		and cached.version == expectedVersion
		and (now - cached.time) < Config.CacheTTL
	then
		entries = cached.entries
	else
		local fetched, err = BoardFetch.Fetch(boardId, board)
		if not fetched then
			return nil, err or 'fetch_failed'
		end
		entries = fetched
		cache[cacheKey] = {
			time = now,
			entries = entries,
			version = expectedVersion,
		}
	end

	local myKey = Config.GetPlayerEntryKey and Config.GetPlayerEntryKey(source, boardId)

	local listLimit = board.limit or Config.DefaultLimit or 20

	local data = {
		boardId = boardId,
		label = board.label,
		description = board.description,
		entryType = board.entryType or 'gang',
		valueLabel = board.valueLabel,
		theme = board.theme or 'default',
		branding = Config.Branding,
		entries = entries,
		listLimit = listLimit,
		updatedAt = now,
		player = BoardFetch.ResolvePlayer(entries, myKey, board, boardId),
	}

	return data
end

function Impl:GetBoardList()
	local boards = {}
	local iterate = BoardRegistry and BoardRegistry.EachEnabled
		or function(fn)
			for id, board in pairs(Config.Boards or {}) do
				if board.enabled ~= false then fn(id, board) end
			end
		end
	iterate(function(id, board)
		boards[#boards + 1] = {
			id = id,
			label = board.label,
			description = board.description,
			icon = board.icon,
			theme = board.theme,
			order = board.order or 99,
		}
	end)
	table.sort(boards, function(a, b)
		if a.order == b.order then return a.label < b.label end
		return a.order < b.order
	end)
	return boards
end

function Impl:GetUiBootstrap()
	return {
		boards = self:GetBoardList(),
		branding = Config.Branding or {},
	}
end

function Impl:Init()
	self:LogInfo('initialized')
	cache = {}
	cacheMetaVersion = Config.CacheVersion or 1
end

function Impl:OnReady()
	self:LogInfo('ready')

	lib.callback.register('Tipi_Rankings:cb:getBoards', function()
		return self:GetUiBootstrap()
	end)

	lib.callback.register('Tipi_Rankings:cb:getLeaderboard', function(source, boardId)
		local data, err = self:GetLeaderboard(source, boardId)
		if not data then
			return { success = false, error = err }
		end
		return { success = true, data = data }
	end)

	RegisterNetEvent('Tipi_Rankings:sv:invalidateCache', function(boardId)
		self:InvalidateCache(boardId)
	end)

end
