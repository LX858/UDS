local Impl = NewImpl("EventRules")

function Impl:Init()
	main:LogInfo("%s initialized", self:GetName())
	self.adminOpen = false
	self:NuiHandler()
	self:EventHandler()
end

function Impl:EventHandler()
	RegisterNetEvent('Tipi_menu:cl:openEventRulesAdmin', function()
		local ok, result = pcall(function()
			return lib.callback.await('Tipi_menu:sv:getAllEventCards', false)
		end)

		if not ok or type(result) ~= 'table' then
			Notify('Không thể mở bảng sự kiện (lỗi server). Kiểm tra bảng event_cards trong database.', 'error')
			return
		end

		if not result.ok then
			if result.message == 'db_error' then
				Notify('Lỗi database: chưa có bảng event_cards. Chạy file data.sql rồi restart Tipi_menu.', 'error')
			else
				Notify('Bạn không có quyền sử dụng lệnh /thelesukien', 'error')
			end
			return
		end

		self.adminOpen = true
		SetNuiFocus(true, true)
		SendReactMessage('setEventCardsAdmin', {
			open = true,
			cards = result.cards or {},
		})
	end)
end

function Impl:CloseAdmin(restoreMenuFocus)
	if not self.adminOpen then return end
	self.adminOpen = false
	SendReactMessage('setEventCardsAdmin', { open = false })
	if restoreMenuFocus then
		SetNuiFocus(true, true)
	else
		SetNuiFocus(false, false)
	end
end

function Impl:NuiHandler()
	RegisterNUICallback('eventCards:getList', function(_, cb)
		local result = lib.callback.await('Tipi_menu:sv:getEventCards', false)
		cb(result or { cards = {} })
	end)

	RegisterNUICallback('eventRules:get', function(body, cb)
		local cardKey = type(body) == 'table' and body.cardKey or body
		local result = lib.callback.await('Tipi_menu:sv:getEventCard', false, cardKey)
		if result and result.card then
			cb({ content = result.card.rulesContent or '', card = result.card })
			return
		end
		cb({ content = '' })
	end)

	RegisterNUICallback('eventCards:save', function(body, cb)
		local result = lib.callback.await('Tipi_menu:sv:saveEventCard', false, body)
		cb(result or { ok = false })
	end)

	RegisterNUICallback('eventCards:delete', function(body, cb)
		local cardKey = body and (body.cardKey or body.card_key)
		local result = lib.callback.await('Tipi_menu:sv:deleteEventCard', false, cardKey)
		cb(result or { ok = false })
	end)

	RegisterNUICallback('eventCards:join', function(body, cb)
		local cardKey = body and (body.cardKey or body.card_key)
		local result = lib.callback.await('Tipi_menu:sv:joinEventCard', false, cardKey)
		cb(result or { ok = false })
		if result and result.ok then
			main:ImplCall('Main', 'ToggleNUI', false)
		end
	end)

	RegisterNUICallback('eventRules:closeAdmin', function(body, cb)
		cb(1)
		local restoreMenuFocus = type(body) == 'table' and body.menuOpen == true
		self:CloseAdmin(restoreMenuFocus)
	end)
end
