
local function usePlaytimeItem(itemName, slot)
	local result = lib.callback.await('Tipi_menu:sv:usePlaytimeItem', false, itemName, slot)
	if not result or not result.success then
		if Config.OxNotify then
			lib.notify({
				title = 'Thông báo',
				description = 'Không thể sử dụng vật phẩm này',
				type = 'error',
			})
		end
	end
end

for itemName, itemCfg in pairs(Config.PlaytimeItems or {}) do
	local exportName = itemCfg.export or itemName
	exports(exportName, function(_, slot)
		usePlaytimeItem(itemName, slot)
	end)
end
