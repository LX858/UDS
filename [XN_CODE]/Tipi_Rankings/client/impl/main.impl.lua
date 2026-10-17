---@class CLMainImpl : Impl
local Impl = NewImpl('Main')

function Impl:Init()
	self.isOpen = false
	self:LogInfo('initialized')
end

function Impl:Open(boardId)
	if self.isOpen then return end
	self.isOpen = true

	local boardsPayload = lib.callback.await('Tipi_Rankings:cb:getBoards', false)
	local boards = boardsPayload.boards or boardsPayload
	local branding = boardsPayload.branding

	local defaultBoard = boardId
	if not defaultBoard and boards[1] then
		defaultBoard = boards[1].id
	end

	SetNuiFocus(true, true)
	SendReactMessage('setVisible', {
		visible = true,
		boardId = defaultBoard,
		boards = boards,
		branding = branding,
	})
end

function Impl:Close()
	if not self.isOpen then return end
	self.isOpen = false
	SetNuiFocus(false, false)
	SendReactMessage('setVisible', { visible = false })
end

function Impl:OnReady()
	self:LogInfo('ready')

	RegisterNUICallback('close', function(_, cb)
		self:Close()
		cb('ok')
	end)

	RegisterNUICallback('getBoards', function(_, cb)
		local payload = lib.callback.await('Tipi_Rankings:cb:getBoards', false)
		cb(payload)
	end)

	RegisterNUICallback('playClick', function(_, cb)
		if Config.EnableUiSound ~= false then
			PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
		end
		cb('ok')
	end)

	RegisterNUICallback('getLeaderboard', function(data, cb)
		local boardId = data and data.boardId
		if not boardId then
			cb({ success = false, error = 'missing_board_id' })
			return
		end
		local result = lib.callback.await('Tipi_Rankings:cb:getLeaderboard', false, boardId)
		cb(result)
	end)

	if Config.OpenCommand and Config.OpenCommand ~= '' then
		RegisterCommand(Config.OpenCommand, function()
			self:Open()
		end, false)
	end

	exports('Open', function(boardId)
		self:Open(boardId)
	end)

	exports('Close', function()
		self:Close()
	end)

	RegisterNetEvent('Tipi_Rankings:cl:open', function(boardId)
		self:Open(boardId)
	end)

	CreateThread(function()
		while true do
			if self.isOpen and IsControlJustReleased(0, 322) then -- ESC
				self:Close()
			end
			Wait(0)
		end
	end)
end
