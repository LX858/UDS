local QBCore = nil
local ESX = nil

if Framework.Name == 'qb' then
	QBCore = exports['qb-core']:GetCoreObject()
	while QBCore == nil do
		TriggerEvent('QBCore:GetObject', function(obj)
			QBCore = obj
		end)
		Wait(30)
	end
elseif Framework.Name == 'esx' then
	ESX = exports['es_extended']:getSharedObject()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj)
			ESX = obj
		end)
		Wait(30)
	end
end

function FrameworkTriggerCallback(name, cb, ...)
	if Framework.Name == 'qbx' then
		lib.callback(name, false, cb, ...)
		return
	end

	if Framework.Name == 'qb' then
		QBCore.Functions.TriggerCallback(name, cb, ...)
		return
	end

	if Framework.Name == 'esx' then
		ESX.TriggerServerCallback(name, cb, ...)
	end
end

function FrameworkRegisterPlayerLoaded(handler)
	if Framework.Name == 'qbx' or Framework.Name == 'qb' then
		RegisterNetEvent('QBCore:Client:OnPlayerLoaded', handler)
		AddEventHandler('QBCore:Client:OnPlayerLoaded', handler)
		return
	end

	if Framework.Name == 'esx' then
		RegisterNetEvent('esx:playerLoaded', handler)
		AddEventHandler('esx:playerLoaded', handler)
	end
end
