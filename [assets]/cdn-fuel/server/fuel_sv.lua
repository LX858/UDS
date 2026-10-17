-- Variables
local QBCore = exports[Config.Core]:GetCoreObject()

-- Functions
local function GlobalTax(value)
	local tax = (value / 100 * Config.GlobalTax)
	return tax
end

--- Events
if Config.RenewedPhonePayment then
	RegisterNetEvent('cdn-fuel:server:phone:givebackmoney', function(amount)
		local src = source
		local player = QBCore.Functions.GetPlayer(src)
		player.Functions.AddMoney("bank", math.ceil(amount), Lang:t("phone_refund_payment_label"))
	end)
end

RegisterNetEvent("cdn-fuel:server:OpenMenu", function(amount, inGasStation, hasWeapon, purchasetype, FuelPrice)
	local src = source
	if not src then return end
	local player = QBCore.Functions.GetPlayer(src)
	if not player then return end
	if not amount then if Config.FuelDebug then print("Amount is invalid!") end TriggerClientEvent('QBCore:Notify', src, Lang:t("more_than_zero"), 'error') return end
	local FuelCost = amount*FuelPrice
	local tax = GlobalTax(FuelCost)
	local total = tonumber(FuelCost + tax)
	if inGasStation == true and not hasWeapon then
		if Config.RenewedPhonePayment and purchasetype == "bank" then
			TriggerClientEvent("cdn-fuel:client:phone:PayForFuel", src, amount)
		else
			if Config.Ox.Menu then
				if Config.FuelDebug then print("going to open the context menu (OX)") end
				TriggerClientEvent('cdn-fuel:client:OpenContextMenu', src, total, amount, purchasetype)
			else
				TriggerClientEvent('qb-menu:client:openMenu', src, {
					{
						header = Lang:t("menu_refuel_header"),
						isMenuHeader = true,
						icon = "fas fa-gas-pump",
					},
					{
						header = "",
						icon = "fas fa-info-circle",
						isMenuHeader = true,
						txt = Lang:t("menu_purchase_station_header_1")..math.ceil(total)..Lang:t("menu_purchase_station_header_2") ,
					},
					{
						header = Lang:t("menu_purchase_station_confirm_header"),
						icon = "fas fa-check-circle",
						txt = Lang:t("menu_refuel_accept"),
						params = {
							event = "cdn-fuel:client:RefuelVehicle",
							args = {
								fuelamounttotal = amount,
								purchasetype = purchasetype,
							}
						}
					},
					{
						header = Lang:t("menu_header_close"),
						txt = Lang:t("menu_refuel_cancel"),
						icon = "fas fa-times-circle",
						params = {
							event = "qb-menu:closeMenu",
						}
					},
				})
			end
		end
	end
end)

RegisterNetEvent("cdn-fuel:server:PayForFuel", function(amount, purchasetype, FuelPrice, electric)
	local src = source
	if not src then return end
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then return end
	local total = math.ceil(amount)
	if amount < 1 then
		total = 0
	end
	local moneyremovetype = purchasetype
	if Config.FuelDebug then print("Player is attempting to purchase fuel with the money type: " ..moneyremovetype) end
	if Config.FuelDebug then print("Attempting to charge client: $"..total.." for Fuel @ "..FuelPrice.." PER LITER | PER KW") end
	if purchasetype == "bank" then
		moneyremovetype = "bank"
	elseif purchasetype == "cash" then
		moneyremovetype = "cash"
	end
	local payString = Lang:t("menu_pay_label_1") ..FuelPrice..Lang:t("menu_pay_label_2")
	if electric then payString = Lang:t("menu_electric_payment_label_1") ..FuelPrice..Lang:t("menu_electric_payment_label_2") end
	Player.Functions.RemoveMoney(moneyremovetype, total, payString)
end)

local function SendFuelSvWebhook(webhookUrl, title, color, fields)
	if not webhookUrl or webhookUrl == '' then return end
	local embedFields = {}
	for _, f in ipairs(fields) do
		embedFields[#embedFields + 1] = {
			name   = f[1],
			value  = tostring(f[2]),
			inline = f[3] or false
		}
	end
	local payload = json.encode({
		username = "CDN-Fuel Logger",
		avatar_url = "https://i.imgur.com/4M34hi2.png",
		embeds = {{
			title       = title,
			color       = color,
			fields      = embedFields,
			footer      = { text = os.date("%d/%m/%Y %H:%M:%S") },
		}}
	})
	PerformHttpRequest(webhookUrl, function(err, text, headers)
		if err ~= 200 and err ~= 204 then
			print(string.format("^1[cdn-fuel] Discord Webhook Error (%s): %s^7", tostring(err), tostring(text)))
		end
	end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent("cdn-fuel:server:purchase:jerrycan", function(purchasetype)
	local src = source if not src then return end
	local Player = QBCore.Functions.GetPlayer(src) if not Player then return end
	local tax = GlobalTax(Config.JerryCanPrice) local total = math.ceil(Config.JerryCanPrice + tax)
	local moneyremovetype = purchasetype
	if purchasetype == "bank" then
		moneyremovetype = "bank"
	elseif purchasetype == "cash" then
		moneyremovetype = "cash"
	end

	local function LogJerryCanPurchase()
		local convarBanCanXang = GetConvar('cdn_fuel_webhook_bancanxang', '')
		if convarBanCanXang == '' then convarBanCanXang = GetConvar('cdn_fuel_webhook_layxang', '') end
		local webhookUrl = (convarBanCanXang ~= '' and convarBanCanXang) or 'https://discord.com/api/webhooks/1536371633982414958/PCic57MxAlcM1HntDSef3Wp8hitpO82IYNEBe9bBA9iOK-O329GbkjC2-SQHAGJEvcCG'
		local charInfo = Player.PlayerData.charinfo
		local pName = (charInfo and charInfo.firstname and charInfo.lastname) and (charInfo.firstname .. " " .. charInfo.lastname) or Player.PlayerData.name
		SendFuelSvWebhook(webhookUrl, "🛢️ Mua Can Xăng (Tại Cây Xăng)", 0xF1C40F, {
			{ "👤 Người Mua",      pName .. " (ID: " .. tostring(src) .. ")", true },
			{ "🪪 Citizen ID",     Player.PlayerData.citizenid or "N/A", true },
			{ "⛽ Dung Tích Can",  tostring(Config.JerryCanGas) .. "L", true },
			{ "💵 Giá Tiền",       "$" .. tostring(total), true },
			{ "💳 Thanh Toán",     (moneyremovetype == 'cash' and "Tiền Mặt" or "Ngân Hàng"), true },
		})
	end

	if Config.Ox.Inventory then
		local info = {cdn_fuel = tostring(Config.JerryCanGas)}
		exports.ox_inventory:AddItem(src, 'can_xang', 1, info)
		local hasItem = exports.ox_inventory:GetItem(src, 'can_xang', info, 1)
		if hasItem then
			Player.Functions.RemoveMoney(moneyremovetype, total, Lang:t("jerry_can_payment_label"))
			LogJerryCanPurchase()
		end
	else
		local info = {gasamount = Config.JerryCanGas}
		if Player.Functions.AddItem("can_xang", 1, false, info) then -- Dont remove money if AddItem() not possible!
			TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['can_xang'], "add")
			Player.Functions.RemoveMoney(moneyremovetype, total, Lang:t("jerry_can_payment_label"))
			LogJerryCanPurchase()
		end
	end
end)

--- Jerry Can
if Config.UseJerryCan then
	QBCore.Functions.CreateUseableItem("can_xang", function(source, item)
		local src = source
		TriggerClientEvent('cdn-fuel:jerrycan:refuelmenu', src, item)
	end)
end

--- Syphoning
if Config.UseSyphoning then
	QBCore.Functions.CreateUseableItem("syphoningkit", function(source, item)
		local src = source
		if Config.Ox.Inventory then
			if item.metadata.cdn_fuel == nil then
				item.metadata.cdn_fuel = '0'
				exports.ox_inventory:SetMetadata(src, item.slot, item.metadata)
			end
		end
		TriggerClientEvent('cdn-syphoning:syphon:menu', src, item)
	end)
end

RegisterNetEvent('cdn-fuel:info', function(type, amount, srcPlayerData, itemdata)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local srcPlayerData = srcPlayerData
	local ItemName = itemdata.name

	if Config.Ox.Inventory then
		if itemdata == "can_xang" then
			if amount < 1 or amount > Config.JerryCanCap then if Config.FuelDebug then print("Error, amount is invalid (< 1 or > "..Config.SyphonKitCap..")! Amount:" ..amount) end return end
		elseif itemdata == "syphoningkit" then
			if amount < 1 or amount > Config.SyphonKitCap then if Config.SyphonDebug then print("Error, amount is invalid (< 1 or > "..Config.SyphonKitCap..")! Amount:" ..amount) end return end
		end
		if ItemName ~= nil then
			-- Ignore --
			itemdata.metadata = itemdata.metadata
			itemdata.slot = itemdata.slot
			if ItemName == 'can_xang' then
				local fuel_amount = tonumber(itemdata.metadata.cdn_fuel)
				if type == "add" then
					fuel_amount = fuel_amount + amount
					itemdata.metadata.cdn_fuel = tostring(fuel_amount)
					exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
				elseif type == "remove" then
					fuel_amount = fuel_amount - amount
					itemdata.metadata.cdn_fuel = tostring(fuel_amount)
					exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
				else
					if Config.FuelDebug then print("error, type is invalid!") end
				end
			elseif ItemName == 'syphoningkit' then
				local fuel_amount = tonumber(itemdata.metadata.cdn_fuel)
				if type == "add" then
					fuel_amount = fuel_amount + amount
					itemdata.metadata.cdn_fuel = tostring(fuel_amount)
					exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
				elseif type == "remove" then
					fuel_amount = fuel_amount - amount
					itemdata.metadata.cdn_fuel = tostring(fuel_amount)
					exports.ox_inventory:SetMetadata(src, itemdata.slot, itemdata.metadata)
				else
					if Config.SyphonDebug then print("error, type is invalid!") end
				end
			end
		else
			if Config.FuelDebug then
				print("ItemName is invalid!")
			end
		end
	else
		if itemdata.info.name == "can_xang" then
			if amount < 1 or amount > Config.JerryCanCap then if Config.FuelDebug then print("Error, amount is invalid (< 1 or > "..Config.SyphonKitCap..")! Amount:" ..amount) end return end
		elseif itemdata.info.name == "syphoningkit" then
			if amount < 1 or amount > Config.SyphonKitCap then if Config.SyphonDebug then print("Error, amount is invalid (< 1 or > "..Config.SyphonKitCap..")! Amount:" ..amount) end return end
		end

		if type == "add" then
			if not srcPlayerData.items[itemdata.slot].info.gasamount then
				srcPlayerData.items[itemdata.slot].info = {
					gasamount = amount,
				}
			else
				srcPlayerData.items[itemdata.slot].info.gasamount = srcPlayerData.items[itemdata.slot].info.gasamount + amount
			end
			Player.Functions.SetInventory(srcPlayerData.items)
		elseif type == "remove" then
			srcPlayerData.items[itemdata.slot].info.gasamount = srcPlayerData.items[itemdata.slot].info.gasamount - amount
			Player.Functions.SetInventory(srcPlayerData.items)
		else
			if Config.SyphonDebug then print("error, type is invalid!") end
		end
	end
end)

RegisterNetEvent('cdn-syphoning:callcops', function(coords)
    TriggerClientEvent('cdn-syphoning:client:callcops', -1, coords)
end)

--- Update Alerts
local updatePath
local resourceName

local function checkVersion(err, responseText, headers)
    local curVersion = LoadResourceFile(GetCurrentResourceName(), "version")
	if responseText == nil then print("^1"..resourceName.." check for updates failed ^7") return end
    if curVersion ~= nil and responseText ~= nil then
		if curVersion == responseText then Color = "^2" else Color = "^1" end
        print("\n^1----------------------------------------------------------------------------------^7")
        print(resourceName.."'s latest version is: ^2"..responseText.."!\n^7Your current version: "..Color..""..curVersion.."^7!\nIf needed, update from https://github.com"..updatePath.."")
        print("^1----------------------------------------------------------------------------------^7")
    end
end

CreateThread(function()
	updatePath = "/CodineDev/cdn-fuel"
	resourceName = "cdn-fuel ("..GetCurrentResourceName()..")"
	PerformHttpRequest("https://raw.githubusercontent.com"..updatePath.."/master/version", checkVersion, "GET")
end)

-- Chặn đồng bộ nổ cây xăng & bình gas trên toàn server
AddEventHandler('explosionEvent', function(sender, ev)
	-- 9: EXP_TAG_PETROL_PUMP, 10: EXP_TAG_PROPANE, 18: EXP_TAG_DIR_PROPANE, 23: EXP_TAG_DIR_GAS_CANISTER, 31: EXP_TAG_DIR_PETROL_CANISTER
	if ev.explosionType == 9 or ev.explosionType == 10 or ev.explosionType == 18 or ev.explosionType == 23 or ev.explosionType == 31 then
		CancelEvent()
	end
end)