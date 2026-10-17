local GangAccounts = {}
local CooldownPlayers = {} -- Server-side cooldown tracker

-- ============================================================
-- QBX_CORE & OX_LIB & OX_INVENTORY HELPER FUNCTIONS
-- ============================================================

local function GetPlayer(src)
	return exports.qbx_core:GetPlayer(src)
end

local function GetPlayerByCitizenId(citizenid)
	return exports.qbx_core:GetPlayerByCitizenId(citizenid)
end

local function GetItemLabel(itemName)
	if not itemName then return '' end
	local item = exports.ox_inventory:Items(itemName)
	if not item then
		item = exports.ox_inventory:Items(string.lower(itemName))
	end
	if not item then
		item = exports.ox_inventory:Items(string.upper(itemName))
	end
	return (item and item.label) or itemName
end

local function NotifyPlayer(src, message, notifyType, duration)
	exports.qbx_core:Notify(src, message, notifyType or 'info', duration or 5000)
end

function GetGangAccount(account)
	return GangAccounts[account] or 0
end

function AddGangMoney(account, amount)
	if not GangAccounts[account] then
		GangAccounts[account] = 0
	end

	GangAccounts[account] = GangAccounts[account] + amount
	MySQL.insert('INSERT INTO management_funds (job_name, amount, type) VALUES (:job_name, :amount, :type) ON DUPLICATE KEY UPDATE amount = :amount',
		{
			['job_name'] = account,
			['amount'] = GangAccounts[account],
			['type'] = 'gang'
		})
end

function RemoveGangMoney(account, amount)
	local isRemoved = false
	if amount > 0 then
		if not GangAccounts[account] then
			GangAccounts[account] = 0
		end

		if GangAccounts[account] >= amount then
			GangAccounts[account] = GangAccounts[account] - amount
			isRemoved = true
		end

		MySQL.update('UPDATE management_funds SET amount = ? WHERE job_name = ? and type = "gang"', { GangAccounts[account], account })
	end
	return isRemoved
end

-- Server-side cooldown helper (prevents exploit bypass)
local function CheckCooldown(src, action, seconds)
	local key = src .. ':' .. action
	local now = os.time()
	if CooldownPlayers[key] and now - CooldownPlayers[key] < seconds then
		return false
	end
	CooldownPlayers[key] = now
	return true
end

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
	local src = source
	local prefix = tostring(src) .. ':'
	for k, _ in pairs(CooldownPlayers) do
		if string.sub(k, 1, #prefix) == prefix then
			CooldownPlayers[k] = nil
		end
	end
end)

-- Helper: build LIKE pattern for JSON gang column in players table
local function GangLikePattern(gangName)
	return '%"' .. gangName .. '"%'
end

-- Khởi tạo bảng xn_gang_inventory và xn_gang_welfare_claims tự động khi server khởi động
MySQL.ready(function()
	MySQL.query([[
		CREATE TABLE IF NOT EXISTS `xn_gang_inventory` (
			`id` INT(11) NOT NULL AUTO_INCREMENT,
			`gang_name` VARCHAR(50) NOT NULL,
			`item` VARCHAR(50) NOT NULL,
			`amount` INT(11) NOT NULL DEFAULT 0,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			UNIQUE KEY `gang_item` (`gang_name`, `item`),
			KEY `idx_gang_name` (`gang_name`)
		);
	]])
	MySQL.query([[
		CREATE TABLE IF NOT EXISTS `xn_gang_welfare_claims` (
			`id` INT(11) NOT NULL AUTO_INCREMENT,
			`name_gang` VARCHAR(50) NOT NULL,
			`milestone_id` INT(11) NOT NULL,
			`item` VARCHAR(50) NOT NULL,
			`claimed_by` VARCHAR(50) NOT NULL,
			`claimed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			UNIQUE KEY `gang_milestone` (`name_gang`, `milestone_id`),
			KEY `idx_name_gang` (`name_gang`)
		);
	]])
end)

-- Helper: Lấy danh sách tài nguyên tồn kho của Gang
local function GetGangWarehouse(gangName)
	if not gangName or gangName == 'none' or gangName == '' then return {} end
	local rows = MySQL.query.await("SELECT `item`, `amount` FROM `xn_gang_inventory` WHERE `gang_name` = ? AND `amount` > 0 ORDER BY `amount` DESC", { gangName })
	local result = {}
	if rows and #rows > 0 then
		for _, row in ipairs(rows) do
			result[#result + 1] = {
				item = row.item,
				label = GetItemLabel(row.item),
				amount = tonumber(row.amount) or 0,
			}
		end
	end
	return result
end

-- Callback: Lấy tài nguyên tồn kho cho UI (ox_lib callback)
lib.callback.register('xn_gangmenu:server:GetGangWarehouse', function(source, gangName)
	local src = source
	local Player = GetPlayer(src)
	local gName = gangName
	if (not gName or gName == '') and Player and Player.PlayerData and Player.PlayerData.gang then
		gName = Player.PlayerData.gang.name
	end
	return GetGangWarehouse(gName)
end)

-- Get data show member gang
lib.callback.register('xn_gangmenu:server:GetEmployees', function(source, gangname)
	local src = source
	local Player = GetPlayer(src)
	local employees = {}
	local hasTipi = GetResourceState('Tipi_menu') == 'started'

	local players = MySQL.query.await(
		"SELECT `citizenid`, `conghien`, `tien_conghien`, `gang`, `charinfo`, `playtime` FROM `players` WHERE `gang` LIKE ? ORDER BY `conghien` DESC",
		{ GangLikePattern(gangname) }
	)

	if not players then
		players = MySQL.query.await(
			"SELECT `citizenid`, `conghien`, `tien_conghien`, `gang`, `charinfo` FROM `players` WHERE `gang` LIKE ? ORDER BY `conghien` DESC",
			{ GangLikePattern(gangname) }
		) or {}
	end

	if players and #players > 0 then
		for _, value in pairs(players) do
			local isOnline = GetPlayerByCitizenId(value.citizenid)
			local playtime = tonumber(value.playtime) or 0
			if isOnline then
				if hasTipi then
					local ok, pTime = pcall(function()
						return exports['Tipi_menu']:GetPlayerPlaytime(isOnline.PlayerData.source)
					end)
					if ok and pTime and pTime > 0 then
						playtime = pTime
					end
				end
				employees[#employees+1] = {
					empSource = isOnline.PlayerData.citizenid,
					conghien = value.conghien,
					tien_conghien = value.tien_conghien,
					grade = isOnline.PlayerData.gang.grade,
					isboss = isOnline.PlayerData.gang.isboss,
					name_show = isOnline.PlayerData.charinfo.firstname .. ' ' .. isOnline.PlayerData.charinfo.lastname,
					playtime = playtime,
					isOnline = true
				}
			else
				local gangData = json.decode(value.gang)
				local charData = json.decode(value.charinfo)
				employees[#employees+1] = {
					empSource = value.citizenid,
					conghien = value.conghien,
					tien_conghien = value.tien_conghien,
					grade = gangData and gangData.grade or { level = 0, name = '' },
					isboss = gangData and gangData.isboss or false,
					name_show = (charData and (charData.firstname .. ' ' .. charData.lastname)) or 'Unknown',
					playtime = playtime,
					isOnline = false
				}
			end
		end
	end

	return employees
end)

-- uplogo gang
RegisterNetEvent("xn_gang:server:update_logo", function(logo)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end

	if Player.PlayerData.gang.isboss then
		if not CheckCooldown(src, 'update_logo', 30) then
			NotifyPlayer(src, "Bạn cần đợi 30 giây trước khi đổi logo mới", "error")
			return
		end
		MySQL.update("UPDATE `xn_gang` SET `logo` = ? WHERE `name_gang` = ?", { logo, Player.PlayerData.gang.name })
		NotifyPlayer(src, "Đã cập nhật logo xã đoàn thành công!", "success")
	else
		NotifyPlayer(src, "Chỉ có Ông Trùm mới có quyền đổi logo xã đoàn!", "error")
	end
	TriggerClientEvent('xn_gangmenu:client:OpenMenu', src)
end)

RegisterNetEvent("xn_gangmenu:server:motagang", function(noi_dung)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end

	if Player.PlayerData.gang.isboss then
		if not CheckCooldown(src, 'motagang', 5) then
			NotifyPlayer(src, "Thao tác quá nhanh, vui lòng thử lại sau vài giây", "error")
			return
		end
		MySQL.update("UPDATE `xn_gang` SET `thong_bao` = ? WHERE `name_gang` = ?", { noi_dung, Player.PlayerData.gang.name })
		NotifyPlayer(src, "Đã cập nhật thông báo mới!", "success")
	else
		NotifyPlayer(src, "Chỉ có Ông Trùm mới có quyền cập nhật thông báo!", "error")
	end
	TriggerClientEvent('xn_gangmenu:client:OpenMenu', src)
end)

-- Helper: Kiểm tra và trừ vật phẩm trong kho tồn kho gang khi nâng cấp
local function CheckAndDeductWarehouseItems(gangName, requiredItems, deduct)
	if not requiredItems or #requiredItems == 0 then return true, {} end

	local rows = MySQL.query.await("SELECT `item`, `amount` FROM `xn_gang_inventory` WHERE `gang_name` = ?", { gangName })
	local currentStock = {}
	if rows then
		for _, r in ipairs(rows) do
			currentStock[r.item] = tonumber(r.amount) or 0
		end
	end

	local missingItems = {}
	local deductList = {}

	for _, req in ipairs(requiredItems) do
		local mainItem = req.item
		local reqAmount = tonumber(req.amount) or 0
		local label = req.label or GetItemLabel(mainItem)

		local totalAvailable = currentStock[mainItem] or 0
		local chosenItem = mainItem

		if totalAvailable < reqAmount and req.alt_items then
			for _, alt in ipairs(req.alt_items) do
				local altStock = currentStock[alt] or 0
				if altStock > totalAvailable then
					totalAvailable = altStock
					chosenItem = alt
				end
			end
		end

		if totalAvailable < reqAmount then
			local missing = reqAmount - totalAvailable
			table.insert(missingItems, {
				item = chosenItem,
				label = label,
				required = reqAmount,
				current = totalAvailable,
				missing = missing
			})
		else
			table.insert(deductList, {
				item = chosenItem,
				amount = reqAmount
			})
		end
	end

	if #missingItems > 0 then
		return false, missingItems
	end

	if deduct then
		for _, d in ipairs(deductList) do
			MySQL.update.await("UPDATE `xn_gang_inventory` SET `amount` = `amount` - ? WHERE `gang_name` = ? AND `item` = ?", { d.amount, gangName, d.item })
		end
	end

	return true, {}
end

-- Get data sql xn_gang
lib.callback.register('xn_gangmenu:getthongbao', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local gangName = Player.PlayerData.gang.name

	local players = MySQL.query.await("SELECT `thong_bao`, `so_member`, `cap_do`, `exp`, `diem_chiemdong`, `logo` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })

	-- Auto-insert gang if not in xn_gang yet
	if not players or players[1] == nil then
		local initMaxMember = (Config.Cap_Do and Config.Cap_Do[1] and Config.Cap_Do[1]["max_member"]) or 20
		MySQL.insert.await("INSERT INTO `xn_gang` (`name_gang`, `cap_do`, `exp`, `so_member`, `diem_chiemdong`) VALUES (?, 1, 0, ?, 0)", { gangName, initMaxMember })
		players = MySQL.query.await("SELECT `thong_bao`, `so_member`, `cap_do`, `exp`, `diem_chiemdong`, `logo` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })
	end

	local memberCount = MySQL.scalar.await("SELECT COUNT(*) FROM `players` WHERE `gang` LIKE ?", { GangLikePattern(gangName) })

	if players and players[1] ~= nil then
		local row = players[1]
		local logo = row.logo or "none"
		local capDo = row.cap_do
		local capConfig = Config.Cap_Do[capDo] or Config.Cap_Do[1]
		local quyGang = exports['Renewed-Banking']:getAccountMoney(gangName) or 0
		return row.thong_bao, row.so_member, capDo, row.exp, row.diem_chiemdong, capConfig["exp"], memberCount or 0, capConfig["phi_nangcap"], logo, quyGang, capConfig["require_items"]
	end
end)

-- Combined callback: return all config data (nhiemvu, doiqua, doiitemcash, doiqua_gang) in 1 DB call
lib.callback.register('xn_gangmenu:getAllConfig', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return { nhiemvu = {}, doiqua = {}, doiitemcash = {}, doiqua_gang = {} } end
	local gangName = Player.PlayerData.gang.name

	local gang = MySQL.query.await("SELECT `cap_do` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })

	if not gang or gang[1] == nil or Config.Cap_Do[gang[1].cap_do] == nil then
		return { nhiemvu = {}, doiqua = {}, doiitemcash = {}, doiqua_gang = {} }
	end

	local capConfig = Config.Cap_Do[gang[1].cap_do]
	local result = {
		nhiemvu = {},
		doiqua = {},
		doiitemcash = {},
		doiqua_gang = {},
	}

	for _, v in pairs(capConfig["nhiemvu"] or {}) do
		result.nhiemvu[#result.nhiemvu+1] = {
			vatpham = v.vatpham,
			sodiem = v.sodiem,
			soluong = tonumber(v.soluong or v.amount) or 1
		}
	end
	for _, v in pairs(capConfig["doiqua"] or {}) do
		local reqItems = {}
		if v.require_items then
			for _, req in ipairs(v.require_items) do
				reqItems[#reqItems + 1] = {
					item = req.item,
					label = req.label or GetItemLabel(req.item),
					amount = tonumber(req.amount) or 1
				}
			end
		end
		result.doiqua[#result.doiqua+1] = {
			vatpham = v.vatpham,
			sodiem = v.sodiem,
			grade = v.grade,
			cash = v.cash or v.require_money,
			soluong = tonumber(v.soluong or v.amount) or 1,
			require_items = reqItems,
		}
	end
	for _, v in pairs(capConfig["doiitemcash"] or {}) do
		result.doiitemcash[#result.doiitemcash+1] = {
			vatpham = v.vatpham,
			sodiem = v.sodiem,
			label = v.label or GetItemLabel(v.vatpham)
		}
	end
	for _, v in pairs(capConfig["doiqua_gang"] or {}) do
		result.doiqua_gang[#result.doiqua_gang+1] = { vatpham = v.vatpham, sodiem = v.sodiem }
	end

	return result
end)

-- doi cash > quy gang
RegisterServerEvent('xn_gang:server:doicash')
AddEventHandler('xn_gang:server:doicash', function (amount)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local amountNum = tonumber(amount)
	if not amountNum or amountNum <= 0 then return end
	if not CheckCooldown(src, 'doicash', 1) then
		NotifyPlayer(src, "Thao tác quá nhanh, vui lòng thử lại sau 1 giây", 'error')
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	if exports.ox_inventory:RemoveItem(src, 'money', amountNum) or Player.Functions.RemoveMoney('cash', amountNum) then
		local gangName = Player.PlayerData.gang.name
		exports['Renewed-Banking']:addAccountMoney(gangName, amountNum)
		local quyGang = exports['Renewed-Banking']:getAccountMoney(gangName) or 0

		local tiench = MySQL.query.await("SELECT `tien_conghien` FROM `players` WHERE `citizenid` = ?", { Player.PlayerData.citizenid })
		if tiench and tiench[1] then
			local tongtien = tiench[1].tien_conghien + amountNum
			MySQL.update("UPDATE `players` SET `tien_conghien` = ? WHERE `citizenid` = ?", { tongtien, Player.PlayerData.citizenid })
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, {
				success = true,
				citizenid = Player.PlayerData.citizenid,
				tien_conghien = tongtien,
				quyGang = quyGang,
			})
		end
		NotifyPlayer(src, "Đã cống hiến " .. amountNum .. "$ tiền quỹ", 'success', 5000)
	else
		NotifyPlayer(src, "Bạn không có đủ tiền để cống hiến", 'error', 5000)
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
	end
end)

-- Update sql xn_gang exp
RegisterServerEvent('xn_gang:server:update_exp')
AddEventHandler('xn_gang:server:update_exp', function (amount)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end

	if Player.PlayerData.gang.isboss then
		MySQL.update("UPDATE `xn_gang` SET `exp` = `exp` + ? WHERE `name_gang` = ?", { tonumber(amount), Player.PlayerData.gang.name })
		NotifyPlayer(src, "+"..amount.." điểm kinh nghiệm Xã đoàn", "success")
	else
		NotifyPlayer(src, "Đừng làm vậy nha bạn. Tay hư !", "error")
	end
	TriggerClientEvent('xn_gangmenu:client:OpenMenu', src)
end)

-- doi item = diem va update diem sql (ox_inventory optimized)
RegisterServerEvent('xn_gang:server:doidiem')
AddEventHandler('xn_gang:server:doidiem', function (vatpham, amount, sodiem)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local amountNum = tonumber(amount)
	if not amountNum or amountNum <= 0 then
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	local gangName = Player.PlayerData.gang.name
	local citizenid = Player.PlayerData.citizenid

	-- Lấy cấu hình cấp độ hiện tại để xác định tỉ lệ số lượng yêu cầu
	local gangData = MySQL.query.await("SELECT `cap_do`, `exp` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })
	local capDo = gangData and gangData[1] and gangData[1].cap_do or 1
	local capConfig = Config.Cap_Do[capDo] or Config.Cap_Do[1]

	local reqAmount = 1
	local pointPerBatch = tonumber(sodiem) or 1

	if capConfig and capConfig["nhiemvu"] then
		for _, m in pairs(capConfig["nhiemvu"]) do
			if m.vatpham == vatpham then
				reqAmount = tonumber(m.soluong or m.amount) or 1
				pointPerBatch = tonumber(m.sodiem) or pointPerBatch
				break
			end
		end
	end

	local batches = math.floor(amountNum / reqAmount)
	if batches < 1 then
		NotifyPlayer(src, "Bạn cần tối thiểu " .. reqAmount .. "x để đổi điểm!", "error", 5000)
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	local actualItemDeduct = batches * reqAmount
	local conghien = batches * pointPerBatch

	if not CheckCooldown(src, 'doidiem', 1) then
		NotifyPlayer(src, "Thao tác quá nhanh, vui lòng thử lại sau 1 giây", 'error')
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	local itemCount = exports.ox_inventory:GetItemCount(src, vatpham) or 0
	if itemCount >= actualItemDeduct then
		exports.ox_inventory:RemoveItem(src, vatpham, actualItemDeduct)

		-- Cập nhật điểm cống hiến cá nhân & EXP của Gang
		local diemch = MySQL.query.await("SELECT `conghien` FROM `players` WHERE `citizenid` = ?", { citizenid })

		local tongdiem = (diemch and diemch[1] and diemch[1].conghien or 0) + conghien
		local newExp = (gangData and gangData[1] and gangData[1].exp or 0) + conghien
		MySQL.update("UPDATE `players` SET `conghien` = ? WHERE `citizenid` = ?", { tongdiem, citizenid })
		MySQL.update("UPDATE `xn_gang` SET `exp` = ? WHERE `name_gang` = ?", { newExp, gangName })

		-- CẬP NHẬT TÀI NGUYÊN TỒN KHO GANG TRONG SQL RIÊNG (xn_gang_inventory)
		MySQL.insert.await([[
			INSERT INTO `xn_gang_inventory` (`gang_name`, `item`, `amount`)
			VALUES (?, ?, ?)
			ON DUPLICATE KEY UPDATE `amount` = `amount` + ?
		]], { gangName, vatpham, actualItemDeduct, actualItemDeduct })

		-- Lấy danh sách tồn kho mới nhất
		local warehouse = GetGangWarehouse(gangName)
		local itemLabel = GetItemLabel(vatpham)

		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, {
			success = true,
			citizenid = citizenid,
			conghien = tongdiem,
			gang_exp = newExp,
			warehouseResources = warehouse,
		})
		NotifyPlayer(src, "Đã cống hiến " .. actualItemDeduct .. "x " .. itemLabel .. " (+" .. conghien .. " điểm CH)", "success")
	else
		NotifyPlayer(src, "Bạn không có đủ " .. actualItemDeduct .. "x vật phẩm này", "error", 5000)
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
	end
end)

-- doi phuc loi (dung nguyen lieu ton kho hoac diem ca nhan)
RegisterServerEvent('xn_gang:server:doiqua')
AddEventHandler('xn_gang:server:doiqua', function (vatpham, amount, sodiem)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local amountNum = tonumber(amount)
	if not amountNum or amountNum <= 0 then
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	if not CheckCooldown(src, 'doiqua', 1) then
		NotifyPlayer(src, "Thao tác quá nhanh, vui lòng thử lại sau 1 giây", 'error')
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	local gangName = Player.PlayerData.gang.name
	local citizenid = Player.PlayerData.citizenid

	-- Lấy cấu hình cấp độ hiện tại của Gang
	local gangData = MySQL.query.await("SELECT `cap_do` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })
	local capDo = (gangData and gangData[1] and gangData[1].cap_do) or 1
	local capConfig = Config.Cap_Do[capDo] or Config.Cap_Do[1]

	-- Tìm cấu hình của vatpham này trong doiqua
	local targetItemConfig = nil
	if capConfig and capConfig["doiqua"] then
		for _, itemCfg in pairs(capConfig["doiqua"]) do
			if itemCfg.vatpham == vatpham then
				targetItemConfig = itemCfg
				break
			end
		end
	end

	-- Kiểm tra cấp bậc yêu cầu (grade)
	local requiredGrade = (targetItemConfig and (tonumber(targetItemConfig.grade) or tonumber(targetItemConfig.min_grade))) or 0
	local playerGrade = (Player.PlayerData.gang and Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level) or 0
	local isBoss = (Player.PlayerData.gang and Player.PlayerData.gang.isboss) or false
	if not isBoss and playerGrade < requiredGrade then
		local gradeName = Config.GangLabel[requiredGrade] or ("Cấp " .. requiredGrade)
		NotifyPlayer(src, "Cấp bậc của bạn chưa đủ để đổi vật phẩm này! (Yêu cầu " .. gradeName .. " trở lên)", "error", 5000)
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	-- Kiểm tra tiền mặt yêu cầu (cash)
	local cashPerUnit = (targetItemConfig and (tonumber(targetItemConfig.cash) or tonumber(targetItemConfig.require_money))) or 0
	local totalCash = cashPerUnit * amountNum
	if totalCash > 0 then
		local currentCash = exports.ox_inventory:GetItemCount(src, 'money') or 0
		if currentCash == 0 and Player.Functions.GetMoney then
			currentCash = Player.Functions.GetMoney('cash') or 0
		end
		if currentCash < totalCash then
			NotifyPlayer(src, "Bạn không đủ tiền mặt! Cần $" .. comma_valueGang(totalCash) .. " để đổi " .. amountNum .. " vật phẩm.", "error", 5000)
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
			return
		end
	end

	-- 1. Nếu cấu hình đổi bằng nguyên liệu tồn kho gang (require_items)
	if targetItemConfig and targetItemConfig.require_items and #targetItemConfig.require_items > 0 then
		local scaledReqItems = {}
		for _, req in ipairs(targetItemConfig.require_items) do
			scaledReqItems[#scaledReqItems + 1] = {
				item = req.item,
				alt_items = req.alt_items,
				label = req.label or GetItemLabel(req.item),
				amount = (tonumber(req.amount) or 1) * amountNum
			}
		end

		local hasItems, missing = CheckAndDeductWarehouseItems(gangName, scaledReqItems, false)
		if not hasItems then
			local errorMsg = "Tồn kho Xã đoàn không đủ nguyên liệu: "
			for i, m in ipairs(missing) do
				errorMsg = errorMsg .. m.label .. " (Thiếu " .. m.missing .. "/" .. m.required .. ")"
				if i < #missing then errorMsg = errorMsg .. ", " end
			end
			NotifyPlayer(src, errorMsg, "error", 6000)
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
			return
		end

		local rewardQty = tonumber(targetItemConfig and (targetItemConfig.soluong or targetItemConfig.amount)) or 1
		local totalGive = amountNum * rewardQty

		if not exports.ox_inventory:CanCarryItem(src, vatpham, totalGive) then
			NotifyPlayer(src, "Túi đồ của bạn đã đầy!", "error", 5000)
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
			return
		end

		-- Trừ tiền mặt nếu có
		if totalCash > 0 then
			if not exports.ox_inventory:RemoveItem(src, 'money', totalCash) then
				if Player.Functions.RemoveMoney then
					Player.Functions.RemoveMoney('cash', totalCash, "Gang exchange: " .. vatpham)
				end
			end
		end

		-- Trừ nguyên liệu tồn kho gang
		CheckAndDeductWarehouseItems(gangName, scaledReqItems, true)
		-- Trao quà cho người chơi
		exports.ox_inventory:AddItem(src, vatpham, totalGive)

		local warehouse = GetGangWarehouse(gangName)
		local itemLabel = GetItemLabel(vatpham)

		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, {
			success = true,
			citizenid = citizenid,
			warehouseResources = warehouse,
		})
		local successMsg = "Bạn đã đổi thành công " .. totalGive .. "x " .. itemLabel .. "!"
		if totalCash > 0 then
			successMsg = successMsg .. " (Trừ $" .. comma_valueGang(totalCash) .. ")"
		end
		NotifyPlayer(src, successMsg, "success", 5000)

	-- 2. Fallback: Đổi bằng điểm cống hiến cá nhân (nếu cấu hình cũ dùng sodiem)
	else
		local rewardQty = tonumber(targetItemConfig and (targetItemConfig.soluong or targetItemConfig.amount)) or 1
		local totalGive = amountNum * rewardQty
		local sodiemNum = tonumber(sodiem) or (targetItemConfig and tonumber(targetItemConfig.sodiem)) or 0
		local conghien = amountNum * sodiemNum

		local datapl = MySQL.query.await("SELECT `conghien` FROM `players` WHERE `citizenid` = ?", { citizenid })
		if datapl and datapl[1] and datapl[1].conghien >= conghien then
			if exports.ox_inventory:CanCarryItem(src, vatpham, totalGive) then
				exports.ox_inventory:AddItem(src, vatpham, totalGive)
				local trudiem = datapl[1].conghien - conghien
				MySQL.update("UPDATE `players` SET `conghien` = ? WHERE `citizenid` = ?", { trudiem, citizenid })
				TriggerClientEvent('xn_gangmenu:client:updatePoints', src, {
					success = true,
					citizenid = citizenid,
					conghien = trudiem,
				})
				NotifyPlayer(src, "Bạn đã đổi " .. conghien .. " điểm cống hiến cá nhân", "success")
			else
				NotifyPlayer(src, "Túi đồ của bạn đã đầy!", "error", 5000)
				TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
			end
		else
			NotifyPlayer(src, "Bạn không đủ điểm để đổi vật phẩm này", "error", 5000)
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		end
	end
end)

-- mua item bang quy gang
RegisterServerEvent('xn_gang:server:mua_item')
AddEventHandler('xn_gang:server:mua_item', function (vatpham, amount, sodiem)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local amountNum = tonumber(amount)
	local sodiemNum = tonumber(sodiem)
	local tongtien = amountNum * sodiemNum

	if not amountNum or amountNum <= 0 or not sodiemNum or sodiemNum <= 0 then
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	if not CheckCooldown(src, 'mua_item', 1) then
		NotifyPlayer(src, "Thao tác quá nhanh, vui lòng thử lại sau 1 giây", 'error')
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	local gradeLevel = (Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level) or 0
	if gradeLevel >= 2 or Player.PlayerData.gang.isboss then
		local gangName = Player.PlayerData.gang.name
		if exports['Renewed-Banking']:removeAccountMoney(gangName, tongtien) then
			exports.ox_inventory:AddItem(src, vatpham, amountNum)
			NotifyPlayer(src, "Bạn đã mua thành công " .. amountNum .. "x " .. GetItemLabel(vatpham) .. " (Trừ $" .. tongtien .. " từ quỹ xã đoàn)", "success")
			local newQuyGang = exports['Renewed-Banking']:getAccountMoney(gangName) or 0
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, {
				success = true,
				quyGang = newQuyGang,
			})
		else
			NotifyPlayer(src, "Quỹ xã đoàn không đủ tiền!", "error", 5000)
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		end
	else
		NotifyPlayer(src, "Cấp bậc của bạn phải từ cấp 2 trở lên mới có thể mua đồ shop xã đoàn", "error", 5000)
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
	end
end)

-- doi diem gang lay qua
RegisterServerEvent('xn_gang:server:doiquagang')
AddEventHandler('xn_gang:server:doiquagang', function (vatpham, amount, sodiem)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local amountNum = tonumber(amount)
	local sodiemNum = tonumber(sodiem)
	local conghien = amountNum * sodiemNum

	if not CheckCooldown(src, 'doiquagang', 1) then
		NotifyPlayer(src, "Thao tác quá nhanh, vui lòng thử lại sau 1 giây", 'error')
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		return
	end

	local gradeLevel = (Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level) or 0
	if gradeLevel >= 2 or Player.PlayerData.gang.isboss then
		local gangName = Player.PlayerData.gang.name
		local datapl = MySQL.query.await("SELECT `exp` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })
		if datapl and datapl[1] and datapl[1].exp >= conghien then
			if exports.ox_inventory:CanCarryItem(src, vatpham, amountNum) then
				exports.ox_inventory:AddItem(src, vatpham, amountNum)
				local newExp = datapl[1].exp - conghien
				MySQL.update("UPDATE `xn_gang` SET `exp` = ? WHERE `name_gang` = ?", { newExp, gangName })
				TriggerClientEvent('xn_gangmenu:client:updatePoints', src, {
					success = true,
					gang_exp = newExp,
				})
				NotifyPlayer(src, "Bạn đã đổi " .. conghien .. " điểm cống hiến xã đoàn", "success")
			else
				NotifyPlayer(src, "Túi đồ của bạn đã đầy!", "error", 5000)
				TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
			end
		else
			NotifyPlayer(src, "Xã đoàn bạn không đủ điểm để đổi vật phẩm này", "error", 5000)
			TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
		end
	else
		NotifyPlayer(src, "Đừng làm vậy nha bạn. Tay hư !", "error")
		TriggerClientEvent('xn_gangmenu:client:updatePoints', src, { success = false })
	end
end)

-- Update sql xn_gang cap_do
RegisterServerEvent('xn_gang:server:update_cap_do')
AddEventHandler('xn_gang:server:update_cap_do', function ()
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end

	if Player.PlayerData.gang.isboss then
		if not CheckCooldown(src, 'update_cap_do', 3) then
			NotifyPlayer(src, "Thao tác nâng cấp đang được xử lý, vui lòng không bấm liên tục!", "error")
			return
		end
		local gangName = Player.PlayerData.gang.name
		local result = MySQL.query.await("SELECT `cap_do`, `exp` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })

		if not result or not result[1] then return end
		local row = result[1]

		if row.cap_do >= Config.Max_Cap_Gang then
			NotifyPlayer(src, "Xã đoàn của bạn đã đạt cấp độ tối đa (" .. Config.Max_Cap_Gang .. ")!", "error")
			return
		end

		local currentCapConfig = Config.Cap_Do[row.cap_do]
		if not currentCapConfig then return end

		-- 1. Kiểm tra Điểm EXP
		local reqExp = currentCapConfig["exp"] or 0
		if row.exp < reqExp then
			NotifyPlayer(src, "Xã đoàn chưa đủ điểm EXP (" .. row.exp .. "/" .. reqExp .. " EXP) để nâng cấp!", "error", 6000)
			return
		end

		-- 2. Kiểm tra Tiền Quỹ Xã Đoàn
		local phi = currentCapConfig["phi_nangcap"] or 5000000
		local currentQuy = exports['Renewed-Banking']:getAccountMoney(gangName) or 0
		if currentQuy < phi then
			local missingMoney = phi - currentQuy
			NotifyPlayer(src, "Quỹ Xã đoàn không đủ tiền! Cần $" .. comma_valueGang(phi) .. " (Còn thiếu $" .. comma_valueGang(missingMoney) .. ")", "error", 7000)
			return
		end

		-- 3. Kiểm tra Vật Phẩm Tồn Kho
		local reqItems = currentCapConfig["require_items"]
		local hasItems, missing = CheckAndDeductWarehouseItems(gangName, reqItems, false)
		if not hasItems then
			local errorMsg = "Tồn kho Xã đoàn còn thiếu nguyên liệu: "
			for i, m in ipairs(missing) do
				errorMsg = errorMsg .. m.label .. " (Thiếu " .. m.missing .. "/" .. m.required .. ")"
				if i < #missing then errorMsg = errorMsg .. ", " end
			end
			NotifyPlayer(src, errorMsg, "error", 9000)
			return
		end

		-- Thực hiện Trừ Tiền Quỹ Xã Đoàn
		if not exports['Renewed-Banking']:removeAccountMoney(gangName, phi) then
			NotifyPlayer(src, "Lỗi khi trừ tiền quỹ xã đoàn!", "error")
			return
		end

		-- Thực hiện Trừ Vật Phẩm Tồn Kho
		CheckAndDeductWarehouseItems(gangName, reqItems, true)

		-- Nâng cấp Level: Reset điểm cống hiến gang về 0
		local cap_do = row.cap_do + 1
		local new_exp = 0
		local nextCapConfig = Config.Cap_Do[cap_do] or Config.Cap_Do[Config.Max_Cap_Gang]
		local newMaxMember = nextCapConfig["max_member"] or 30
		local newMaxExp = nextCapConfig["exp"] or 0
		local newPhiNangcap = nextCapConfig["phi_nangcap"] or 0
		local newRequireItems = nextCapConfig["require_items"] or {}
		local newQuyGang = exports['Renewed-Banking']:getAccountMoney(gangName) or 0
		local newWarehouse = GetGangWarehouse(gangName)

		MySQL.update("UPDATE `xn_gang` SET `cap_do` = ?, `exp` = 0, `so_member` = ? WHERE `name_gang` = ?",
			{ cap_do, newMaxMember, gangName })

		local payload = {
			capDo = cap_do,
			exp = new_exp,
			maxExp = newMaxExp,
			maxMember = newMaxMember,
			phiNangcap = newPhiNangcap,
			quyGang = newQuyGang,
			warehouseResources = newWarehouse,
			requireItems = newRequireItems,
		}

		NotifyPlayer(src, "Chúc mừng! Xã đoàn đã nâng cấp thành công lên Cấp Độ " .. cap_do .. "!", "success", 8000)

		local qbxPlayers = exports.qbx_core:GetQBPlayers()
		for _, targetPl in pairs(qbxPlayers) do
			if targetPl and targetPl.PlayerData.gang and targetPl.PlayerData.gang.name == gangName then
				TriggerClientEvent('xn_gangmenu:client:levelUp', targetPl.PlayerData.source, payload)
			end
		end
	else
		NotifyPlayer(src, "Chỉ Ông Trùm (Boss) mới có quyền nâng cấp xã đoàn!", "error")
	end
end)

RegisterNetEvent("xn_gangmenu:server:withdrawMoney", function(amount)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end

	local gang = Player.PlayerData.gang.name
	if RemoveGangMoney(gang, amount) then
		Player.Functions.AddMoney("cash", amount, 'Rút quỹ từ quỹ xã đoàn')
		--TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Withdraw Money', 'yellow', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' successfully withdrew $' .. amount .. ' (' .. gang .. ')', false)
		NotifyPlayer(src, "You have withdrawn: $" .. amount, "success")
	else
		NotifyPlayer(src, "You dont have enough money in the account!", "error")
	end

	TriggerClientEvent('xn_gangmenu:client:OpenMenu', src)
end)

RegisterNetEvent("xn_gangmenu:server:depositMoney", function(amount)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end

	if Player.Functions.RemoveMoney("cash", amount) then
		local gang = Player.PlayerData.gang.name
		AddGangMoney(gang, amount)
		--TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Deposit Money', 'yellow', Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' successfully deposited $' .. amount .. ' (' .. gang .. ')', false)
		NotifyPlayer(src, "You have deposited: $" .. amount, "success")
	else
		NotifyPlayer(src, "You dont have enough money to add!", "error")
	end
end)

lib.callback.register('xn_gangmenu:server:GetAccount', function(_, GangName)
	return GetGangAccount(GangName)
end)

-- Legacy callbacks
lib.callback.register('xn_gangmenu:getnhiemvu', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return {} end
	local gang = MySQL.query.await("SELECT `cap_do` FROM `xn_gang` WHERE `name_gang` = ?", { Player.PlayerData.gang.name })
	local nhiemvu = {}

	if not gang or gang[1] == nil or Config.Cap_Do[gang[1].cap_do] == nil then return nhiemvu end

	for _, v in pairs(Config.Cap_Do[gang[1].cap_do]["nhiemvu"]) do
		nhiemvu[#nhiemvu+1] = { vatpham = v.vatpham, sodiem = v.sodiem }
	end
	return nhiemvu
end)

lib.callback.register('xn_gangmenu:getdoiqua', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return {} end
	local gang = MySQL.query.await("SELECT `cap_do` FROM `xn_gang` WHERE `name_gang` = ?", { Player.PlayerData.gang.name })
	local nhiemvu = {}

	if not gang or gang[1] == nil or Config.Cap_Do[gang[1].cap_do] == nil then return nhiemvu end

	for _, v in pairs(Config.Cap_Do[gang[1].cap_do]["doiqua"]) do
		nhiemvu[#nhiemvu+1] = { vatpham = v.vatpham, sodiem = v.sodiem }
	end
	return nhiemvu
end)

lib.callback.register('xn_gangmenu:getitemcash_gang', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return {} end
	local gang = MySQL.query.await("SELECT `cap_do` FROM `xn_gang` WHERE `name_gang` = ?", { Player.PlayerData.gang.name })
	local nhiemvu = {}

	if not gang or gang[1] == nil or Config.Cap_Do[gang[1].cap_do] == nil then return nhiemvu end

	for _, v in pairs(Config.Cap_Do[gang[1].cap_do]["doiitemcash"]) do
		nhiemvu[#nhiemvu+1] = {
			vatpham = v.vatpham,
			sodiem = v.sodiem,
			label = v.label or GetItemLabel(v.vatpham)
		}
	end
	return nhiemvu
end)

lib.callback.register('xn_gangmenu:getdoiqua_gang', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return {} end
	local gang = MySQL.query.await("SELECT `cap_do` FROM `xn_gang` WHERE `name_gang` = ?", { Player.PlayerData.gang.name })
	local nhiemvu = {}

	if not gang or gang[1] == nil or Config.Cap_Do[gang[1].cap_do] == nil then return nhiemvu end

	for _, v in pairs(Config.Cap_Do[gang[1].cap_do]["doiqua_gang"]) do
		nhiemvu[#nhiemvu+1] = { vatpham = v.vatpham, sodiem = v.sodiem }
	end
	return nhiemvu
end)

-- Get qua chiem dong + check qua da nhan tu sql
lib.callback.register('xn_gangmenu:quachiemdong', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return {} end

	local my_nv = {}
	local result = MySQL.query.await("SELECT `id_nv` FROM `xn_qua_cd` WHERE `name_gang` = ?", { Player.PlayerData.gang.name })

	if result then
		for _, v in pairs(result) do
			my_nv[#my_nv+1] = { id_nv = v.id_nv }
		end
	end

	return my_nv
end)

-- Nhan qua chiem dong
RegisterServerEvent('xn_gang:server:doi_quacd')
AddEventHandler('xn_gang:server:doi_quacd', function (id_nv, sodiem, item, types, amount)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local gangName = Player.PlayerData.gang.name

	if Player.PlayerData.gang.isboss then
		local result = MySQL.query.await("SELECT `diem_chiemdong` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })
		local data = MySQL.query.await("SELECT `id_nv` FROM `xn_qua_cd` WHERE `name_gang` = ? AND `diem` = ?", { gangName, sodiem })

		if result and result[1] and result[1].diem_chiemdong >= tonumber(sodiem) then
			if not data or data[1] == nil then
				MySQL.insert("INSERT INTO `xn_qua_cd` (`id_nv`, `name_gang`, `diem`, `trang_thai`) VALUES (?, ?, ?, 1)", { id_nv, gangName, sodiem })
				if types == "item" then
					exports.ox_inventory:AddItem(src, item, tonumber(amount))
				elseif types == "money" then
					Player.Functions.AddMoney(item, tonumber(amount), 'money-quachiemdong')
				end
				NotifyPlayer(src, "Nhận thưởng thành công", "success", 5000)
			else
				NotifyPlayer(src, "Bạn đã nhận phần thưởng này", "error", 5000)
			end
		else
			NotifyPlayer(src, "Bạn đã chưa đủ số điểm để nhận phần thưởng này", "error", 5000)
		end
	else
		NotifyPlayer(src, "Đừng làm vậy nha bạn. Tay hư !", "error")
	end
end)

-- Callback: Lấy thông tin phúc lợi gang & các mốc đã nhận
lib.callback.register('xn_gangmenu:server:GetGangWelfare', function(source)
	local src = source
	local Player = GetPlayer(src)
	local milestones = (Config.PhucLoiGang and Config.PhucLoiGang.milestones) or {}
	if not Player or not Player.PlayerData.gang or Player.PlayerData.gang.name == "none" then
		return { claimed = {}, milestones = milestones, qualifiedCount = 0 }
	end

	local gangName = Player.PlayerData.gang.name
	local claimed = {}
	local rows = MySQL.query.await("SELECT `milestone_id` FROM `xn_gang_welfare_claims` WHERE `name_gang` = ?", { gangName })
	if rows then
		for _, r in ipairs(rows) do
			claimed[#claimed + 1] = r.milestone_id
		end
	end

	local requiredPlaytime = (Config.PhucLoiGang and Config.PhucLoiGang.playtimeRequired) or 259200
	local players = MySQL.query.await(
		"SELECT `citizenid`, `playtime` FROM `players` WHERE `gang` LIKE ?",
		{ GangLikePattern(gangName) }
	) or {}

	local hasTipi = GetResourceState('Tipi_menu') == 'started'
	local qualifiedCount = 0

	for _, p in ipairs(players) do
		local isOnline = GetPlayerByCitizenId(p.citizenid)
		local pTime = tonumber(p.playtime) or 0
		if isOnline and hasTipi then
			local ok, liveTime = pcall(function()
				return exports['Tipi_menu']:GetPlayerPlaytime(isOnline.PlayerData.source)
			end)
			if ok and liveTime and liveTime > 0 then
				pTime = liveTime
			end
		end
		if pTime >= requiredPlaytime then
			qualifiedCount = qualifiedCount + 1
		end
	end

	return {
		claimed = claimed,
		milestones = milestones,
		qualifiedCount = qualifiedCount,
		playtimeRequired = requiredPlaytime
	}
end)

-- Callback: Nhận quà phúc lợi gang theo mốc
lib.callback.register('xn_gangmenu:server:ClaimGangWelfare', function(source, milestoneId)
	local src = source
	local Player = GetPlayer(src)
	if not Player or not Player.PlayerData.gang or Player.PlayerData.gang.name == "none" then
		return { success = false, message = "Bạn không ở trong xã đoàn!" }
	end

	local callerGrade = (Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level) or 0
	local canClaim = Player.PlayerData.gang.isboss or callerGrade >= 2
	if not canClaim then
		return { success = false, message = "Chỉ có Lão đại (Cấp 2+) hoặc Trùm xã đoàn mới có quyền nhận phúc lợi!" }
	end

	local gangName = Player.PlayerData.gang.name
	local cfg = Config.PhucLoiGang or {}
	local milestones = cfg.milestones or {}
	local milestone = nil
	for _, m in ipairs(milestones) do
		if m.id == tonumber(milestoneId) then
			milestone = m
			break
		end
	end

	if not milestone then
		return { success = false, message = "Mốc phúc lợi không hợp lệ!" }
	end

	-- Kiểm tra đã nhận chưa
	local existing = MySQL.scalar.await("SELECT 1 FROM `xn_gang_welfare_claims` WHERE `name_gang` = ? AND `milestone_id` = ? LIMIT 1", { gangName, milestone.id })
	if existing then
		return { success = false, message = "Xã đoàn đã nhận gói quà này rồi!" }
	end

	-- Đếm số lượng thành viên đạt thời gian chơi
	local requiredPlaytime = cfg.playtimeRequired or 259200
	local players = MySQL.query.await(
		"SELECT `citizenid`, `playtime` FROM `players` WHERE `gang` LIKE ?",
		{ GangLikePattern(gangName) }
	) or {}

	local hasTipi = GetResourceState('Tipi_menu') == 'started'
	local qualifiedCount = 0

	for _, p in ipairs(players) do
		local isOnline = GetPlayerByCitizenId(p.citizenid)
		local pTime = tonumber(p.playtime) or 0
		if isOnline and hasTipi then
			local ok, liveTime = pcall(function()
				return exports['Tipi_menu']:GetPlayerPlaytime(isOnline.PlayerData.source)
			end)
			if ok and liveTime and liveTime > 0 then
				pTime = liveTime
			end
		end
		if pTime >= requiredPlaytime then
			qualifiedCount = qualifiedCount + 1
		end
	end

	if qualifiedCount < milestone.membersRequired then
		return {
			success = false,
			message = ("Chưa đủ điều kiện! Hiện có %d/%d thành viên đủ 3 ngày chơi."):format(qualifiedCount, milestone.membersRequired)
		}
	end

	if not exports.ox_inventory:CanCarryItem(src, milestone.item, milestone.amount or 1) then
		return { success = false, message = "Túi đồ của bạn không đủ chỗ trống để nhận quà!" }
	end

	local inserted = MySQL.insert.await(
		"INSERT INTO `xn_gang_welfare_claims` (`name_gang`, `milestone_id`, `item`, `claimed_by`) VALUES (?, ?, ?, ?)",
		{ gangName, milestone.id, milestone.item, Player.PlayerData.citizenid }
	)

	if inserted then
		exports.ox_inventory:AddItem(src, milestone.item, milestone.amount or 1)
		-- TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Gang Welfare Claim', 'green',
		-- 	(Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) ..
		-- 	' đã nhận phần thưởng phúc lợi mốc ' .. milestone.membersRequired .. ' người (' .. milestone.item .. ') cho gang ' .. gangName, false)
		NotifyPlayer(src, "Nhận thành công " .. (milestone.label or milestone.item) .. "!", "success", 5000)
		return { success = true, milestoneId = milestone.id, message = "Nhận quà thành công!" }
	else
		return { success = false, message = "Lỗi khi lưu dữ liệu nhận quà!" }
	end
end)

-- BXH gang (optimized)
lib.callback.register('xn_gangmenu:topgang', function(source)
	local allgang = {}
	local gang = MySQL.query.await([[
		SELECT g.name_gang, g.so_member, g.cap_do, g.exp, g.logo,
			(SELECT COUNT(*) FROM players p WHERE p.gang LIKE CONCAT('%"', g.name_gang, '"%')) AS tong_member
		FROM xn_gang g
		ORDER BY g.cap_do DESC, g.exp DESC
	]], {})

	local allGangs = exports.qbx_core:GetGangs()

	if gang then
		for _, value in pairs(gang) do
			local label_gang = "Xã đoàn không tồn tại [Config Gang]"
			if allGangs and allGangs[value.name_gang] then
				label_gang = allGangs[value.name_gang].label or value.name_gang
			end

			allgang[#allgang+1] = {
				name_gang = value.name_gang,
				label_gang = label_gang,
				so_member = value.so_member,
				tong_member = value.tong_member or 0,
				cap_do = value.cap_do,
				exp = value.exp,
				logo = value.logo or "none",
			}
		end
	end

	return allgang
end)

-- BXH chiem dong (optimized)
lib.callback.register('xn_gangmenu:top_chiemdong', function(source)
	local allgang = {}
	local gang = MySQL.query.await([[
		SELECT g.name_gang, g.so_member, g.cap_do, g.diem_chiemdong, g.logo,
			(SELECT COUNT(*) FROM players p WHERE p.gang LIKE CONCAT('%"', g.name_gang, '"%')) AS tong_member
		FROM xn_gang g
		ORDER BY g.diem_chiemdong DESC
	]], {})

	local allGangs = exports.qbx_core:GetGangs()

	if gang then
		for _, value in pairs(gang) do
			local label_gang = "Xã đoàn không tồn tại [Config Gang]"
			if allGangs and allGangs[value.name_gang] then
				label_gang = allGangs[value.name_gang].label or value.name_gang
			end

			allgang[#allgang+1] = {
				name_gang = value.name_gang,
				label_gang = label_gang,
				so_member = value.so_member,
				tong_member = value.tong_member or 0,
				cap_do = value.cap_do,
				diem_chiemdong = value.diem_chiemdong,
				logo = value.logo or "none",
			}
		end
	end

	return allgang
end)

-- Update gang grade
RegisterNetEvent('xn_gangmenu:server:GradeUpdate', function(id_chucvu, id_work, id_empSource)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local Employee = GetPlayerByCitizenId(id_empSource)
	if Employee ~= nil then
		if Player.PlayerData.gang.isboss then
			if id_chucvu > Player.PlayerData.gang.grade.level or id_chucvu >= 3 then
				NotifyPlayer(src, "Bạn không thể thay đổi chức vụ này!", "error")
				return
			end

			if Employee then
				if Employee.Functions.SetGang(Player.PlayerData.gang.name, id_chucvu) then
					NotifyPlayer(src, "Thay đổi chức vụ thành công!", "success")
					NotifyPlayer(Employee.PlayerData.source, "Bạn đã được thay đổi chức vụ.", "success")
				else
					NotifyPlayer(src, "Chức vụ không tồn tại.", "error")
				end
			else
				NotifyPlayer(src, "Thường dân không ở trong thành phố.", "error")
			end
			Employee.Functions.Save()
		else
			NotifyPlayer(src, "Đừng làm vậy nha bạn. Tay hư !", "error")
		end
	else
		NotifyPlayer(src, "Người chơi không online !", "error")
	end
	TriggerClientEvent('xn_gangmenu:client:OpenMenu', src)
end)

-- Thoat gang
RegisterNetEvent('xn_gang:server:thoatgang', function()
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	if Player.PlayerData.gang.isboss then
		NotifyPlayer(src, "Bạn đi rồi ai quản lý gia đình đây. huhu!", "error")
	else
		local gangName = Player.PlayerData.gang.name
		if gangName and gangName ~= 'none' then
			exports.qbx_core:RemovePlayerFromGang(Player.PlayerData.citizenid, gangName)
		end
		Player.Functions.SetGang('none', 0)
		NotifyPlayer(src, "Bạn đã rời khỏi Xã đoàn!", "error")
	end
end)

-- Khai tru
RegisterNetEvent('xn_gangmenu:server:FireMember', function(target)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return end
	local callerGrade = (Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level) or 0
	local canFire = Player.PlayerData.gang.isboss or callerGrade >= 2
	local currentGangName = Player.PlayerData.gang.name

	if canFire then
		if target == Player.PlayerData.citizenid then
			NotifyPlayer(src, "Bạn không thể tự đuổi bản thân!", "error")
			return
		end

		local Employee = GetPlayerByCitizenId(target)
		local empGrade = Employee and (Employee.PlayerData.gang.grade and Employee.PlayerData.gang.grade.level) or 0
		local isEmpBoss = Employee and Employee.PlayerData.gang.isboss or false

		if not Employee then
			local playerRow = MySQL.query.await('SELECT `gang` FROM `players` WHERE `citizenid` = ? LIMIT 1', { target })
			if playerRow and playerRow[1] then
				local empGang = json.decode(playerRow[1].gang)
				empGrade = (empGang and empGang.grade and empGang.grade.level) or 0
				isEmpBoss = (empGang and empGang.isboss) or false
			end
		end

		if not Player.PlayerData.gang.isboss then
			if isEmpBoss then
				NotifyPlayer(src, "Bạn không thể đuổi Trùm xã đoàn!", "error")
				return
			end
			if empGrade >= callerGrade then
				NotifyPlayer(src, "Bạn không thể đuổi người chơi có cấp bậc bằng hoặc cao hơn bạn!", "error")
				return
			end
		end

		exports.qbx_core:RemovePlayerFromGang(target, currentGangName)
		if Employee then
			Employee.Functions.SetGang('none', 0)
			NotifyPlayer(Employee.PlayerData.source, "Bạn đã bị khai trừ khỏi Xã đoàn!", "error")
		end
		NotifyPlayer(src, "Đã khai trừ thành viên khỏi xã đoàn!", "success")
		--TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Gang Fire', 'orange', Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. target .. " (" .. currentGangName .. ")", false)
	else
		NotifyPlayer(src, "Đừng làm vậy nha bạn. Tay hư !", "error")
	end

	TriggerClientEvent('xn_gangmenu:client:removeMember', src, target)
end)

-- Them thanh vien
RegisterNetEvent('xn_gangmenu:server:HireMember', function(recruit)
	local src = source
	local Player = GetPlayer(src)
	local Target = GetPlayer(recruit)

	if Target ~= nil and Player ~= nil then
		if Target.PlayerData.gang.name == "none" then
			local callerGrade = (Player.PlayerData.gang.grade and Player.PlayerData.gang.grade.level) or 0
			local canHire = Player.PlayerData.gang.isboss or callerGrade >= 2
			if canHire then
				local gangName = Player.PlayerData.gang.name
				local result = MySQL.query.await("SELECT `so_member` FROM `xn_gang` WHERE `name_gang` = ?", { gangName })
				local memberCount = MySQL.scalar.await("SELECT COUNT(*) FROM `players` WHERE `gang` LIKE ?", { GangLikePattern(gangName) })

				if result and result[1] ~= nil then
					if memberCount < result[1].so_member then
						if Target.Functions.SetGang(gangName, 0) then
							local allGangs = exports.qbx_core:GetGangs()
							local gradeInfo = allGangs[gangName] and allGangs[gangName].grades and (allGangs[gangName].grades['0'] or allGangs[gangName].grades[0])
							NotifyPlayer(src, "Bạn đã mời " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. " vào " .. Player.PlayerData.gang.label, "success")
							NotifyPlayer(Target.PlayerData.source, "Bạn được mời vào " .. Player.PlayerData.gang.label, "success")
							--TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Recruit', 'yellow', (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname).. ' successfully recruited ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' (' .. gangName .. ')', false)
							Target.Functions.Save()
							local pTime = 0
							if GetResourceState('Tipi_menu') == 'started' then
								local ok, pt = pcall(function()
									return exports['Tipi_menu']:GetPlayerPlaytime(Target.PlayerData.source)
								end)
								if ok and pt then pTime = pt end
							end
							TriggerClientEvent('xn_gangmenu:client:newMember', src, {
								nameShow = Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname,
								empSource = Target.PlayerData.citizenid,
								conghien = 0,
								tien_conghien = 0,
								grade = { name = gradeInfo and gradeInfo.name or 'Đàn em', level = 0 },
								isboss = false,
								playtime = pTime,
								isOnline = true,
							})
						end
					else
						NotifyPlayer(src, "Xã đoàn đã đủ thành viên. Hãy nâng cấp Xã đoàn để mở giới hạn!", "error")
					end
				end
			else
				NotifyPlayer(src, "Đừng làm vậy nha bạn. Tay hư !", "error")
			end
		else
			NotifyPlayer(src, "Người chơi này đã có Xã đoàn!", "error")
		end
	else
		NotifyPlayer(src, "Người chơi không online !", "error")
	end
end)

-- Get closest players data (Client provides nearby IDs, server only does O(1) lookups)
lib.callback.register('xn_gangmenu:server:GetNearbyPlayersData', function(source, nearbyServerIds)
	local src = source
	if not nearbyServerIds or #nearbyServerIds == 0 then return {} end
	local players = {}

	for _, targetId in ipairs(nearbyServerIds) do
		local targetNum = tonumber(targetId)
		if targetNum and targetNum ~= src then
			local ped = GetPlayer(targetNum)
			if ped and ped.PlayerData and ped.PlayerData.charinfo then
				players[#players+1] = {
					id = targetNum,
					name = ped.PlayerData.charinfo.firstname .. " " .. ped.PlayerData.charinfo.lastname,
					citizenid = ped.PlayerData.citizenid,
					sourceplayer = ped.PlayerData.source
				}
			end
		end
	end

	table.sort(players, function(a, b)
		return a.name < b.name
	end)
	return players
end)

-- Legacy fallback
lib.callback.register('xn_gangmenu:getplayers', function(source)
	return {}
end)

-- ============================================================
-- EXPORTS: Cộng điểm bảng xếp hạng từ resource bên ngoài
-- ============================================================

exports('AddConghien', function(citizenid, amount)
	amount = tonumber(amount)
	if not citizenid or not amount or amount <= 0 then return false end

	local result = MySQL.query.await("SELECT `conghien` FROM `players` WHERE `citizenid` = ? LIMIT 1", { citizenid })
	if not result or not result[1] then return false end

	local newValue = result[1].conghien + amount
	MySQL.update("UPDATE `players` SET `conghien` = ? WHERE `citizenid` = ?", { newValue, citizenid })

	local Player = GetPlayerByCitizenId(citizenid)
	if Player then
		TriggerClientEvent('xn_gangmenu:client:updatePoints', Player.PlayerData.source, {
			success = true,
			citizenid = citizenid,
			conghien = newValue,
		})
	end

	return true
end)

exports('AddGangExp', function(gangName, amount)
	amount = tonumber(amount)
	if not gangName or not amount or amount <= 0 then return false end

	local result = MySQL.query.await("SELECT `exp` FROM `xn_gang` WHERE `name_gang` = ? LIMIT 1", { gangName })
	if not result or not result[1] then return false end

	local newExp = result[1].exp + amount
	MySQL.update("UPDATE `xn_gang` SET `exp` = ? WHERE `name_gang` = ?", { newExp, gangName })

	return true
end)

exports('AddDiemChiemdong', function(gangName, amount)
	amount = tonumber(amount)
	if not gangName or not amount or amount <= 0 then return false end

	local result = MySQL.query.await("SELECT `diem_chiemdong` FROM `xn_gang` WHERE `name_gang` = ? LIMIT 1", { gangName })
	if not result or not result[1] then return false end

	local newDiem = result[1].diem_chiemdong + amount
	MySQL.update("UPDATE `xn_gang` SET `diem_chiemdong` = ? WHERE `name_gang` = ?", { newDiem, gangName })

	return true
end)

-- ============================================================
-- HỆ THỐNG ĐĂNG KÝ TẠO GANG & QUẢN LÝ / XÉT DUYỆT GANG
-- ============================================================

MySQL.ready(function()
	MySQL.query([[
		CREATE TABLE IF NOT EXISTS `xn_gang_requests` (
			`id` INT(11) NOT NULL AUTO_INCREMENT,
			`citizenid` VARCHAR(50) NOT NULL,
			`char_name` VARCHAR(100) NOT NULL,
			`gang_label` VARCHAR(100) NOT NULL,
			`gang_tag` VARCHAR(20) NOT NULL,
			`description` TEXT NOT NULL,
			`fee` INT(11) NOT NULL DEFAULT 1000000,
			`status` ENUM('pending', 'approved', 'rejected', 'completed', 'refunded') NOT NULL DEFAULT 'pending',
			`gang_name` VARCHAR(50) DEFAULT NULL,
			`admin_name` VARCHAR(100) DEFAULT NULL,
			`created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			KEY `citizenid` (`citizenid`),
			KEY `status` (`status`)
		);
	]])
end)

local function comma_valueGang(amount)
	local formatted = tostring(amount or 0)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k == 0) then
			break
		end
	end
	return formatted
end

local function SendGangDiscordWebhook(title, description, color, fields)
	local webhook = Config.DiscordWebhook
	if not webhook or webhook == "" or webhook:sub(1, 4) ~= "http" then return end

	local embed = {
		{
			["title"] = title,
			["description"] = description,
			["type"] = "rich",
			["color"] = color or 5793266,
			["fields"] = fields or {},
			["footer"] = {
				["text"] = "Hệ Thống Xã Đoàn • " .. os.date("%d/%m/%Y %H:%M:%S"),
			},
		}
	}

	PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
		username = "Quản Lý Xã Đoàn",
		embeds = embed,
		avatar_url = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png"
	}), { ['Content-Type'] = 'application/json' })
end

local function CountWords(str)
	if not str then return 0 end
	local count = 0
	for _ in string.gmatch(str, "%S+") do
		count = count + 1
	end
	return count
end

local function HasAdminPermission(src)
	if src == 0 then return true end
	if IsPlayerAceAllowed(src, 'command') then return true end
	for group, _ in pairs(Config.AdminGroups or {}) do
		if exports.qbx_core:HasPermission(src, group) or exports.qbx_core:HasGroup(src, group) then
			return true
		end
	end
	return false
end

-- Callback: Kiểm tra trạng thái đơn đăng ký của người chơi
lib.callback.register('xn_gangmenu:server:CheckGangRequest', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return nil end

	local result = MySQL.query.await([[
		SELECT `id`, `citizenid`, `char_name`, `gang_label`, `gang_tag`, `description`, `fee`, `status`, `gang_name`, `admin_name`, `created_at`
		FROM `xn_gang_requests`
		WHERE `citizenid` = ? AND `status` IN ('pending', 'approved', 'rejected')
		ORDER BY `id` DESC LIMIT 1
	]], { Player.PlayerData.citizenid })

	if result and result[1] then
		return result[1]
	else
		return nil
	end
end)

-- Callback: Nộp đơn đăng ký tạo gang mới
lib.callback.register('xn_gangmenu:server:SubmitGangRequest', function(source, data)
	local src = source
	local Player = GetPlayer(src)
	if not Player then
		return { success = false, message = "Không tìm thấy dữ liệu nhân vật của bạn trên máy chủ!" }
	end

	if Player.PlayerData.gang.name ~= "none" then
		local currentGangLabel = Player.PlayerData.gang.label or Player.PlayerData.gang.name
		return { success = false, message = "Bạn hiện đang là thành viên của xã đoàn [" .. currentGangLabel .. "]. Hãy rời xã đoàn cũ trước khi thành lập xã đoàn mới!" }
	end

	local existing = MySQL.query.await("SELECT `id`, `gang_label` FROM `xn_gang_requests` WHERE `citizenid` = ? AND `status` = 'pending' LIMIT 1", { Player.PlayerData.citizenid })
	if existing and existing[1] then
		return { success = false, message = "Bạn đã có 1 đơn đăng ký xã đoàn [" .. existing[1].gang_label .. "] đang chờ BQT xét duyệt! Vui lòng kiên nhẫn chờ BQT xử lý xong đơn cũ." }
	end

	local gangLabel = tostring(data.gangLabel or ""):gsub("^%s*(.-)%s*$", "%1")
	local gangTag = tostring(data.gangTag or ""):gsub("^%s*(.-)%s*$", "%1")
	local description = tostring(data.description or ""):gsub("^%s*(.-)%s*$", "%1")

	if gangLabel == "" or #gangLabel < 2 then
		return { success = false, message = "Tên xã đoàn không hợp lệ! Vui lòng nhập tên có từ 2 đến 50 ký tự." }
	end

	if #gangLabel > 50 then
		return { success = false, message = "Tên xã đoàn quá dài! Vui lòng giới hạn dưới 50 ký tự." }
	end

	if gangTag == "" or #gangTag < 2 or #gangTag > 10 then
		return { success = false, message = "Tên viết tắt (Tag) không hợp lệ! Yêu cầu từ 2 đến 10 ký tự (Ví dụ: BBT, BLS, FAM)." }
	end

	if description == "" or #description < 5 then
		return { success = false, message = "Vui lòng nhập phần giới thiệu chi tiết về tôn chỉ hoạt động của xã đoàn!" }
	end

	local wordCount = CountWords(description)
	local maxWords = Config.MaxDescriptionWords or 100
	if wordCount > maxWords then
		return { success = false, message = "Nội dung giới thiệu vượt quá giới hạn " .. maxWords .. " từ! (Bạn đang nhập: " .. wordCount .. " từ). Vui lòng rút ngắn lại." }
	end

	local fee = Config.CreateGangCost or 1000000
	local cash = exports.ox_inventory:GetItemCount(src, 'money') or Player.Functions.GetMoney('cash') or 0

	if cash < fee then
		local missingCash = fee - cash
		return { success = false, message = "Bạn không đủ tiền mặt (Cash) để đăng ký! Cần $" .. comma_valueGang(fee) .. " Cash (Túi bạn có: $" .. comma_valueGang(cash) .. " Cash, còn thiếu: $" .. comma_valueGang(missingCash) .. " Cash)." }
	end

	if not exports.ox_inventory:RemoveItem(src, 'money', fee) and not Player.Functions.RemoveMoney('cash', fee, "Đăng ký tạo xã đoàn: " .. gangLabel) then
		return { success = false, message = "Giao dịch trừ tiền mặt $" .. comma_valueGang(fee) .. " thất bại, vui lòng kiểm tra lại túi tiền hoặc thử lại sau!" }
	end

	local charName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
	local insertId = MySQL.insert.await([[
		INSERT INTO `xn_gang_requests` (`citizenid`, `char_name`, `gang_label`, `gang_tag`, `description`, `fee`, `status`)
		VALUES (?, ?, ?, ?, ?, ?, 'pending')
	]], { Player.PlayerData.citizenid, charName, gangLabel, gangTag, description, fee })

	if insertId then
		SendGangDiscordWebhook(
			"📝 ĐƠN ĐĂNG KÝ TẠO XÃ ĐOÀN MỚI",
			"Có một đơn đăng ký thành lập xã đoàn mới đang chờ Ban Quản Trị xét duyệt!",
			15844367,
			{
				{ ["name"] = "🏢 Tên xã đoàn", ["value"] = gangLabel .. " `[" .. gangTag .. "]`", ["inline"] = true },
				{ ["name"] = "👤 Người đăng ký", ["value"] = charName .. " `(" .. Player.PlayerData.citizenid .. ")`", ["inline"] = true },
				{ ["name"] = "💰 Phí đăng ký", ["value"] = "$" .. comma_valueGang(fee) .. " Cash", ["inline"] = true },
				{ ["name"] = "📝 Giới thiệu xã đoàn", ["value"] = description, ["inline"] = false }
			}
		)

		NotifyPlayer(src, "Nộp đơn tạo xã đoàn thành công! Đang chờ Admin xét duyệt.", "success", 7000)
		return {
			success = true,
			request = {
				id = insertId,
				citizenid = Player.PlayerData.citizenid,
				char_name = charName,
				gang_label = gangLabel,
				gang_tag = gangTag,
				description = description,
				fee = fee,
				status = 'pending',
			}
		}
	else
		exports.ox_inventory:AddItem(src, 'money', fee)
		return { success = false, message = "Lỗi cơ sở dữ liệu khi lưu đơn đăng ký, hệ thống đã hoàn trả lại $" .. comma_valueGang(fee) .. " Cash!" }
	end
end)

-- Callback: Người chơi bấm Xác Nhận nhận Gang đã được duyệt
lib.callback.register('xn_gangmenu:server:ClaimApprovedGang', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return { success = false, message = "Không tìm thấy người chơi!" } end

	local result = MySQL.query.await([[
		SELECT * FROM `xn_gang_requests`
		WHERE `citizenid` = ? AND `status` = 'approved'
		ORDER BY `id` DESC LIMIT 1
	]], { Player.PlayerData.citizenid })

	if not result or not result[1] then
		return { success = false, message = "Không tìm thấy đơn đăng ký hợp lệ nào đã được phê duyệt!" }
	end

	local req = result[1]
	local gangName = req.gang_name

	if not gangName or gangName == "" then
		return { success = false, message = "Tên xã đoàn hệ thống chưa được gán, vui lòng liên hệ BQT!" }
	end

	local bossGrade = 3
	local allGangs = exports.qbx_core:GetGangs()
	if allGangs and allGangs[gangName] and allGangs[gangName].grades then
		local maxLevel = 0
		for k, v in pairs(allGangs[gangName].grades) do
			local lvl = tonumber(k) or 0
			if v.isboss or lvl > maxLevel then
				maxLevel = lvl
				bossGrade = lvl
			end
		end
	end

	if Player.Functions.SetGang(gangName, bossGrade) then
		Player.Functions.Save()

		local initMaxMember = (Config.Cap_Do and Config.Cap_Do[1] and Config.Cap_Do[1]["max_member"]) or 20
		MySQL.insert.await("INSERT INTO `xn_gang` (`name_gang`, `cap_do`, `exp`, `so_member`, `diem_chiemdong`) VALUES (?, 1, 0, ?, 0) ON DUPLICATE KEY UPDATE `cap_do` = `cap_do`", { gangName, initMaxMember })

		MySQL.update("UPDATE `xn_gang_requests` SET `status` = 'completed' WHERE `id` = ?", { req.id })

		NotifyPlayer(src, "Chúc mừng! Bạn đã chính thức trở thành Ông Trùm của " .. req.gang_label .. "!", "success", 8000)
		return { success = true, gangName = gangName, gangLabel = req.gang_label }
	else
		return { success = false, message = "Không thể thiết lập xã đoàn hệ thống (" .. gangName .. "). Hãy kiểm tra config qbx_core / shared gangs!" }
	end
end)

-- Callback: Người chơi bấm Xác Nhận nhận hoàn tiền khi bị từ chối
lib.callback.register('xn_gangmenu:server:ClaimRejectedRefund', function(source)
	local src = source
	local Player = GetPlayer(src)
	if not Player then return { success = false, message = "Không tìm thấy người chơi!" } end

	local result = MySQL.query.await([[
		SELECT * FROM `xn_gang_requests`
		WHERE `citizenid` = ? AND `status` = 'rejected'
		ORDER BY `id` DESC LIMIT 1
	]], { Player.PlayerData.citizenid })

	if not result or not result[1] then
		return { success = false, message = "Không tìm thấy đơn đăng ký bị từ chối nào cần hoàn tiền!" }
	end

	local req = result[1]
	local refundFee = req.fee or Config.CreateGangCost or 1000000

	if not exports.ox_inventory:AddItem(src, 'money', refundFee) then
		Player.Functions.AddMoney('cash', refundFee, "Hoàn trả phí đăng ký xã đoàn bị từ chối")
	end
	MySQL.update("UPDATE `xn_gang_requests` SET `status` = 'refunded' WHERE `id` = ?", { req.id })

	NotifyPlayer(src, "Đã hoàn lại $" .. comma_valueGang(refundFee) .. " tiền mặt vào tài khoản của bạn!", "success", 7000)
	return { success = true, refundedAmount = refundFee }
end)

-- Callback: Admin lấy danh sách các đơn đăng ký pending
lib.callback.register('xn_gangmenu:server:GetPendingRequests', function(source)
	local src = source
	if not HasAdminPermission(src) then
		return { success = false, message = "Bạn không có quyền quản trị!", requests = {} }
	end

	local requests = MySQL.query.await([[
		SELECT `id`, `citizenid`, `char_name`, `gang_label`, `gang_tag`, `description`, `fee`, `status`, `created_at`
		FROM `xn_gang_requests`
		WHERE `status` = 'pending'
		ORDER BY `id` ASC
	]], {})

	return { success = true, requests = requests or {} }
end)

-- Callback: Admin Duyệt Đơn
lib.callback.register('xn_gangmenu:server:AdminApproveGang', function(source, data)
	local src = source
	local AdminPlayer = GetPlayer(src)
	if not AdminPlayer or not HasAdminPermission(src) then
		return { success = false, message = "Bạn không có quyền thực hiện thao tác này!" }
	end

	local requestId = tonumber(data.requestId)
	local gangName = tostring(data.gangName or ""):gsub("^%s*(.-)%s*$", "%1"):lower()

	if not requestId or requestId <= 0 then
		return { success = false, message = "ID đơn không hợp lệ!" }
	end

	if gangName == "" then
		return { success = false, message = "Vui lòng nhập tên xã đoàn hệ thống trong qbx_core (ví dụ: ballas, families...)!" }
	end

	local req = MySQL.query.await("SELECT * FROM `xn_gang_requests` WHERE `id` = ? AND `status` = 'pending' LIMIT 1", { requestId })
	if not req or not req[1] then
		return { success = false, message = "Đơn đăng ký không tồn tại hoặc đã được xử lý trước đó!" }
	end

	local requestData = req[1]
	local adminName = AdminPlayer.PlayerData.charinfo.firstname .. " " .. AdminPlayer.PlayerData.charinfo.lastname .. " (" .. AdminPlayer.PlayerData.name .. ")"

	MySQL.update.await([[
		UPDATE `xn_gang_requests`
		SET `status` = 'approved', `gang_name` = ?, `admin_name` = ?
		WHERE `id` = ?
	]], { gangName, adminName, requestId })

	SendGangDiscordWebhook(
		"✅ ĐƠN ĐĂNG KÝ XÃ ĐOÀN ĐÃ ĐƯỢC DUYỆT",
		"Ban Quản Trị đã phê duyệt đơn đăng ký thành lập xã đoàn!",
		3066993,
		{
			{ ["name"] = "🏢 Tên xã đoàn", ["value"] = requestData.gang_label .. " `[" .. requestData.gang_tag .. "]`", ["inline"] = true },
			{ ["name"] = "⚙️ Mã hệ thống (qbx_core)", ["value"] = "`" .. gangName .. "`", ["inline"] = true },
			{ ["name"] = "👤 Người đăng ký", ["value"] = requestData.char_name .. " `(" .. requestData.citizenid .. ")`", ["inline"] = true },
			{ ["name"] = "🛡️ Admin phê duyệt", ["value"] = adminName, ["inline"] = true }
		}
	)

	local TargetPlayer = GetPlayerByCitizenId(requestData.citizenid)
	if TargetPlayer then
		NotifyPlayer(TargetPlayer.PlayerData.source, "Đơn đăng ký xã đoàn [" .. requestData.gang_label .. "] đã được phê duyệt! Hãy mở menu xã đoàn để nhận quyền.", "success", 10000)
	end

	NotifyPlayer(src, "Đã duyệt đơn đăng ký thành công cho " .. requestData.gang_label .. "!", "success")
	return { success = true }
end)

-- Callback: Admin Từ Chối Đơn
lib.callback.register('xn_gangmenu:server:AdminRejectGang', function(source, data)
	local src = source
	local AdminPlayer = GetPlayer(src)
	if not AdminPlayer or not HasAdminPermission(src) then
		return { success = false, message = "Bạn không có quyền thực hiện thao tác này!" }
	end

	local requestId = tonumber(data.requestId)
	local reason = tostring(data.reason or "Chưa đủ điều kiện thành lập"):gsub("^%s*(.-)%s*$", "%1")

	if not requestId or requestId <= 0 then
		return { success = false, message = "ID đơn không hợp lệ!" }
	end

	local req = MySQL.query.await("SELECT * FROM `xn_gang_requests` WHERE `id` = ? AND `status` = 'pending' LIMIT 1", { requestId })
	if not req or not req[1] then
		return { success = false, message = "Đơn đăng ký không tồn tại hoặc đã được xử lý trước đó!" }
	end

	local requestData = req[1]
	local adminName = AdminPlayer.PlayerData.charinfo.firstname .. " " .. AdminPlayer.PlayerData.charinfo.lastname .. " (" .. AdminPlayer.PlayerData.name .. ")"

	MySQL.update.await([[
		UPDATE `xn_gang_requests`
		SET `status` = 'rejected', `admin_name` = ?
		WHERE `id` = ?
	]], { adminName, requestId })

	local TargetPlayer = GetPlayerByCitizenId(requestData.citizenid)
	if TargetPlayer then
		NotifyPlayer(TargetPlayer.PlayerData.source, "Đơn đăng ký xã đoàn [" .. requestData.gang_label .. "] đã bị từ chối. Hãy mở menu xã đoàn để nhận lại tiền phí!", "error", 10000)
	end

	NotifyPlayer(src, "Đã từ chối đơn đăng ký của " .. requestData.gang_label .. "!", "success")
	return { success = true }
end)

-- ============================================================
-- COMMANDS (lib.addCommand - Quyền Mod trở lên)
-- ============================================================

-- Lệnh /gangmenu: Mở Menu Gang
lib.addCommand('gangmenu', {
	help = 'Mở Menu Xã Đoàn (Yêu cầu quyền Mod trở lên)',
	params = {},
	restricted = 'group.mod'
}, function(source, args, raw)
	if source > 0 then
		if HasAdminPermission(source) or IsPlayerAceAllowed(source, 'command.gangmenu') then
			TriggerClientEvent('xn_gangmenu:client:OpenMenu', source)
		else
			NotifyPlayer(source, "Bạn không có quyền sử dụng lệnh này!", "error")
		end
	end
end)

-- Lệnh /quanlygang: Mở bảng quản lý duyệt đơn đăng ký Gang
lib.addCommand('quanlygang', {
	help = 'Mở bảng quản lý duyệt đơn đăng ký Xã Đoàn (Admin/Mod)',
	params = {},
	restricted = 'group.mod'
}, function(source, args, raw)
	if source > 0 then
		if HasAdminPermission(source) or IsPlayerAceAllowed(source, 'command.quanlygang') then
			TriggerClientEvent('xn_gangmenu:client:OpenAdminManagement', source)
		else
			NotifyPlayer(source, "Bạn không có quyền sử dụng lệnh này!", "error")
		end
	end
end)

-- Lệnh /removegang: Xóa Gang của người chơi về No Gang (Admin/Mod)
lib.addCommand('removegang', {
	help = 'Xóa Gang của người chơi về No Gang (Admin/Mod)',
	params = {
		{
			name = 'target',
			type = 'playerId',
			help = 'ID người chơi trên Server',
		},
	},
	restricted = 'group.mod'
}, function(source, args, raw)
	local targetPlayer = exports.qbx_core:GetPlayer(args.target)
	if not targetPlayer then
		if source > 0 then
			NotifyPlayer(source, "Người chơi không online!", "error")
		else
			print("^1[xn_gangmenu] Người chơi không online!^0")
		end
		return
	end

	local citizenid = targetPlayer.PlayerData.citizenid
	local gangName = targetPlayer.PlayerData.gang and targetPlayer.PlayerData.gang.name

	if gangName and gangName ~= 'none' then
		exports.qbx_core:RemovePlayerFromGang(citizenid, gangName)
	end
	targetPlayer.Functions.SetGang('none', 0)

	MySQL.update("UPDATE `players` SET `conghien` = 0, `tien_conghien` = 0 WHERE `citizenid` = ?", { citizenid })

	local targetName = (targetPlayer.PlayerData.charinfo and (targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname)) or citizenid

	if source > 0 then
		NotifyPlayer(source, ("Đã xóa Gang của %s (ID: %s) về No Gang thành công!"):format(targetName, args.target), "success")
	else
		print(("[xn_gangmenu] Đã xóa Gang của %s (ID: %s) về No Gang thành công!"):format(targetName, args.target))
	end

	NotifyPlayer(targetPlayer.PlayerData.source, "Bạn đã được quản trị viên xóa khỏi Gang / Xã đoàn!", "info")
	--TriggerEvent('qb-log:server:CreateLog', 'gangmenu', 'Admin Remove Gang', 'red', 'Admin đã xóa gang của ' .. targetName .. ' (' .. citizenid .. ')', false)
end)