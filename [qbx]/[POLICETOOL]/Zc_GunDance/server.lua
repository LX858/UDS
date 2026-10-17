local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('Gundance_checkip', function()
	local src = source
	TriggerClientEvent('Gundance_checkipOK', src)
end)
