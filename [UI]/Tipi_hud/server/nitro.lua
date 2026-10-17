if Config.UseNitro then
	local nitros = {}

	RegisterItem(Config.NitroItem, function(src)
		TriggerClientEvent('tipi-hud:setupNitro', src)
	end)

	lib.callback.register('tipi-hud:getVehicleNitro', function(source, plate, count)
		return nitros[plate]
	end)

	RegisterServerEvent('tipi-hud:setVehicleNitro', function(plate, count)
		nitros[plate] = count
	end)

	RegisterServerEvent('tipi-hud:removeNitroItem', function()
		local Player = getPlayer(source)

		removeItem(Player, Config.NitroItem, 1)
	end)
end
