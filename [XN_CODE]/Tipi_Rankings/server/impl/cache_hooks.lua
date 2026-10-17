local function invalidateBoard(boardId)
	local impl = main and main:GetImpl('Main')
	if impl and impl.InvalidateCache then
		impl:InvalidateCache(boardId)
		return
	end
	TriggerEvent('Tipi_Rankings:sv:invalidateCache', boardId)
end

exports('InvalidateCache', invalidateBoard)

local function registerInvalidateHooks()
	if not BoardRegistry then return end
	BoardRegistry.EachEnabled(function(boardId)
		for _, eventName in ipairs(BoardRegistry.GetInvalidateEvents(boardId)) do
			if type(eventName) == 'string' and eventName ~= '' then
				AddEventHandler(eventName, function()
					invalidateBoard(boardId)
				end)
			end
		end
	end)
end

AddEventHandler('onResourceStart', function(resourceName)
	if resourceName ~= GetCurrentResourceName() then return end
	registerInvalidateHooks()
end)

if GetResourceState(GetCurrentResourceName()) == 'started' then
	CreateThread(registerInvalidateHooks)
end
