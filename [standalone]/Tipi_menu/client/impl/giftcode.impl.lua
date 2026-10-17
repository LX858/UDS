---@class CLGiftCodeImpl : Impl
local Impl = NewImpl("GiftCode")

function Impl:Init()
	self:LogInfo("initialized")
	self.adminOpen = false
end

function Impl:OnReady()
	self:LogInfo("ready")
	self:NUICallbacks()
	self:EventHandler()
end

function Impl:EventHandler()
	RegisterNetEvent('Tipi_menu:cl:openCreateGiftCode', function()
		self.adminOpen = true
		SetNuiFocus(true, true)
		SendReactMessage('setGiftCodeAdmin', { open = true })
	end)
end

function Impl:CloseAdmin(restoreMenuFocus)
	if not self.adminOpen then return end
	self.adminOpen = false
	SendReactMessage('setGiftCodeAdmin', { open = false })
	if restoreMenuFocus then
		SetNuiFocus(true, true)
	else
		SetNuiFocus(false, false)
	end
end

function Impl:NUICallbacks()
	RegisterNUICallback('giftCode:redeem', function(body, cb)
		cb(1)
		if not body then return end
		main:ImplCall('Main', 'ToggleNUI', false)
		lib.callback.await("Tipi_menu:cb:giftCode:redeem", false, body)
	end)

	RegisterNUICallback('inviteCode:redeem', function(body, cb)
		cb(1)
		if not body then return end
		main:ImplCall('Main', 'ToggleNUI', false)
		lib.callback.await("Tipi_menu:cb:inviteCode:redeem", false, body)
	end)

	RegisterNUICallback('giftCode:closeAdmin', function(body, cb)
		cb(1)
		local restoreMenuFocus = type(body) == 'table' and body.menuOpen == true
		self:CloseAdmin(restoreMenuFocus)
	end)

	RegisterNUICallback('giftCode:create', function(body, cb)
		local result = lib.callback.await('Tipi_menu:cb:giftCode:create', false, body)
		cb(result or { status = false, message = 'Lỗi không xác định' })
	end)

	RegisterNUICallback('giftCode:getClothingComponents', function(_, cb)
		local result = lib.callback.await('Tipi_menu:cb:giftCode:getClothingComponents', false)
		cb(result or { status = false, message = 'Lỗi không xác định', components = {} })
	end)
end
