local QBX = exports.qbx_core
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

function FrameworkGetPlayer(src)
	if Framework.Name == 'qbx' then
		return QBX:GetPlayer(src)
	end

	if Framework.Name == 'qb' then
		return QBCore.Functions.GetPlayer(src)
	end

	if Framework.Name == 'esx' then
		return ESX.GetPlayerFromId(src)
	end
end

function FrameworkGetIdentifier(player)
	if not player then return nil end

	if Framework.Name == 'qbx' or Framework.Name == 'qb' then
		return player.PlayerData.citizenid
	end

	if Framework.Name == 'esx' then
		return player.identifier
	end
end

function FrameworkGetLicense(player)
	if not player then return nil end

	if Framework.Name == 'qbx' or Framework.Name == 'qb' then
		return player.PlayerData.license
	end

	if Framework.Name == 'esx' then
		return player.identifier
	end
end

function FrameworkAddMoney(src, player, amount)
	if Framework.Name == 'qbx' then
		return QBX:AddMoney(src, Config.MoneyType, amount)
	end

	if Framework.Name == 'qb' then
		return player.Functions.AddMoney(Config.MoneyType, amount)
	end

	if Framework.Name == 'esx' then
		if Config.MoneyType == 'bank' then
			return player.addAccountMoney(Config.MoneyType, amount)
		end

		return player.addMoney(amount)
	end
end

function FrameworkGetMoney(src, player, moneyType)
	moneyType = moneyType or Config.MoneyType or 'cash'
	if Framework.Name == 'qbx' then
		local pdata = player and player.PlayerData
		if not pdata or not pdata.money then return 0 end
		return math.floor(tonumber(pdata.money[moneyType]) or 0)
	end

	if Framework.Name == 'qb' then
		return math.floor(tonumber(player.Functions.GetMoney(moneyType)) or 0)
	end

	if Framework.Name == 'esx' then
		if moneyType == 'bank' then
			local account = player.getAccount('bank')
			return math.floor(tonumber(account and account.money) or 0)
		end
		return math.floor(tonumber(player.getMoney()) or 0)
	end

	return 0
end

function FrameworkRemoveMoney(src, player, amount, moneyType, reason)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if amount <= 0 then return true end
	moneyType = moneyType or Config.MoneyType or 'cash'
	reason = reason or 'tipi-daily-missed-claim'

	if FrameworkGetMoney(src, player, moneyType) < amount then
		return false
	end

	if Framework.Name == 'qbx' then
		return QBX:RemoveMoney(src, moneyType, amount, reason) ~= false
	end

	if Framework.Name == 'qb' then
		return player.Functions.RemoveMoney(moneyType, amount, reason) ~= false
	end

	if Framework.Name == 'esx' then
		if moneyType == 'bank' then
			player.removeAccountMoney('bank', amount)
			return true
		end
		player.removeMoney(amount)
		return true
	end

	return false
end

function FrameworkAddItem(src, player, itemName, count)
	if Framework.Name == 'qbx' then
		return exports.ox_inventory:AddItem(src, itemName, count)
	end

	if Framework.Name == 'qb' then
		return player.Functions.AddItem(itemName, count)
	end

	if Framework.Name == 'esx' then
		return player.addInventoryItem(itemName, count)
	end
end

function FrameworkCreateCallback(name, handler)
	if Framework.Name == 'qbx' then
		lib.callback.register(name, function(source, ...)
			local p = promise.new()
			handler(source, function(data)
				p:resolve(data)
			end, ...)
			return Citizen.Await(p)
		end)
		return
	end

	if Framework.Name == 'qb' then
		QBCore.Functions.CreateCallback(name, handler)
		return
	end

	if Framework.Name == 'esx' then
		ESX.RegisterServerCallback(name, handler)
	end
end

function FrameworkCreateUseableItem(itemName, handler)
	if Framework.Name == 'qbx' then
		QBX:CreateUseableItem(itemName, handler)
		return
	end

	if Framework.Name == 'qb' then
		QBCore.Functions.CreateUseableItem(itemName, handler)
		return
	end

	if Framework.Name == 'esx' then
		ESX.RegisterUsableItem(itemName, handler)
	end
end
