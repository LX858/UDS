--DeleteResourceKvp('renzu_motels')
GlobalState.Motels = nil
GlobalState.MotelOffices = {}
local db = import 'server/sql'
local logger = require '@qbx_core.modules.logger'
local rental_period = {
	['hour'] = 3600,      -- 1 giờ = 3600 giây
	['day'] = 86400,      -- 1 ngày = 86400 giây (24 giờ)
	['month'] = 2592000   -- 1 tháng = 2592000 giây (30 ngày)
}

-- Helper function: Lấy tên blip của motel để hiển thị trong log
local function GetMotelBlipLabel(motelId)
	for k, v in pairs(config.motels) do
		if v.motel == motelId then
			return v.blipLabel or v.label or motelId
		end
	end
	return motelId
end

-- Helper function: Lấy ID duy nhất của từng motel để tránh trùng routing bucket giữa các khách sạn khác nhau
local motelIdMap = {}
local nextDynamicMotelId = 100
local function GetMotelUniqueId(motelName)
	if not motelName then return 1 end
	if motelIdMap[motelName] then
		return motelIdMap[motelName]
	end

	if config and config.motels then
		for k, v in pairs(config.motels) do
			if v.motel == motelName then
				local numKey = tonumber(k)
				local id = (numKey and numKey > 0) and numKey or nil
				if not id then
					id = nextDynamicMotelId
					nextDynamicMotelId = nextDynamicMotelId + 1
				end
				motelIdMap[motelName] = id
				return id
			end
		end
	end

	local id = nextDynamicMotelId
	nextDynamicMotelId = nextDynamicMotelId + 1
	motelIdMap[motelName] = id
	return id
end

local ServerMotels = {}

-- Function to check if a room is currently rented by an active tenant
local function IsRoomCurrentlyRented(room, curTime)
	if not room or not room.players then return false end
	for _, playerData in pairs(room.players) do
		if playerData.duration and playerData.duration > curTime then
			return true
		end
	end
	return false
end

-- Helper function to calculate trash: 6 piles / 6 hours / 1 room ONLY if rented
local function UpdateRoomTrash(room, curTime)
	if not room then return false end
	curTime = curTime or os.time()
	local isRented = IsRoomCurrentlyRented(room, curTime)
	
	if not isRented then
		-- Phòng không có người thuê: luôn sạch và reset mốc thời gian
		if (room.trashCount and room.trashCount > 0) or not room.lastCleaned then
			room.trashCount = 0
			room.lastCleaned = curTime
			return true
		end
		room.lastCleaned = curTime
		return false
	end

	-- Phòng đang có người thuê: cứ đúng 6 giờ (21600 giây) tăng 6 bãi rác, tối đa 12
	if not room.lastCleaned then
		room.lastCleaned = curTime
		room.trashCount = 0
		return true
	end

	local elapsedCycles = math.floor((curTime - room.lastCleaned) / 21600)
	if elapsedCycles > 0 then
		room.trashCount = math.min(12, (room.trashCount or 0) + (elapsedCycles * 6))
		room.lastCleaned = room.lastCleaned + (elapsedCycles * 21600)
		return true
	end

	return false
end

-- Helper to get player's character info (offline or online) with O(1) lookup
local function GetPlayerInfo(identifier)
	local citizenid = identifier
	local pid = ''
	local playerName = 'Unknown'

	if exports.qbx_core and exports.qbx_core.GetPlayerByCitizenId then
		local p = exports.qbx_core:GetPlayerByCitizenId(identifier)
		if p and p.PlayerData then
			citizenid = p.PlayerData.citizenid or identifier
			pid = tostring(p.PlayerData.pid or '')
			if p.PlayerData.charinfo then
				playerName = (p.PlayerData.charinfo.firstname or '') .. ' ' .. (p.PlayerData.charinfo.lastname or '')
			end
			return citizenid, pid, playerName
		end
	end

	if QBCORE then
		local onlinePlayer = QBCORE.Functions.GetPlayerByCitizenId(identifier)
		if onlinePlayer and onlinePlayer.PlayerData then
			citizenid = onlinePlayer.PlayerData.citizenid or identifier
			pid = tostring(onlinePlayer.PlayerData.pid or '')
			if onlinePlayer.PlayerData.charinfo then
				playerName = (onlinePlayer.PlayerData.charinfo.firstname or '') .. ' ' .. (onlinePlayer.PlayerData.charinfo.lastname or '')
			end
			return citizenid, pid, playerName
		end
	elseif ESX then
		local onlinePlayer = ESX.GetPlayerFromIdentifier(identifier)
		if onlinePlayer then
			pid = tostring(onlinePlayer.source or '')
			playerName = onlinePlayer.getName() or (onlinePlayer.get('firstName') .. ' ' .. onlinePlayer.get('lastName'))
			return citizenid, pid, playerName
		end
	end

	-- Offline DB query
	if QBCORE then
		local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {identifier})
		if result and result[1] and result[1].charinfo then
			local success, charinfo = pcall(json.decode, result[1].charinfo)
			if success and charinfo and charinfo.firstname and charinfo.lastname then
				playerName = charinfo.firstname .. ' ' .. charinfo.lastname
			end
		end
	elseif ESX then
		local result = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ?', {identifier})
		if result and result[1] and result[1].firstname and result[1].lastname then
			playerName = result[1].firstname .. ' ' .. result[1].lastname
		end
	end

	return citizenid, pid, playerName
end

-- Helper to get player's character name (offline or online)
local function GetPlayerCharName(identifier)
	local _, _, name = GetPlayerInfo(identifier)
	return name
end

-- Helper to get player's phone number (offline or online)
local function GetPlayerPhoneNumber(identifier)
	local phone = "N/A"
	local targetSrc = nil
	if QBCORE then
		local p = QBCORE.Functions.GetPlayerByCitizenId(identifier)
		if p then targetSrc = p.PlayerData.source end
	elseif ESX then
		local p = ESX.GetPlayerFromIdentifier(identifier)
		if p then targetSrc = p.source end
	end

	if targetSrc then
		local phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(targetSrc)
		if phoneNumber then return phoneNumber end
	end

	-- Offline or no phone equipped, lookup standard schemas
	if QBCORE then
		local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {identifier})
		if result and result[1] and result[1].charinfo then
			local success, charinfo = pcall(json.decode, result[1].charinfo)
			if success and charinfo and charinfo.phone then
				phone = charinfo.phone
			end
		end
	elseif ESX then
		local result = MySQL.query.await('SELECT phone_number FROM users WHERE identifier = ?', {identifier})
		if result and result[1] and result[1].phone_number then
			phone = result[1].phone_number
		else
			-- Fallback to phone_phones table for lb-phone
			local phoneResult = MySQL.query.await("SHOW TABLES LIKE 'phone_phones'")
			if phoneResult and #phoneResult > 0 then
				local dbPhone = MySQL.query.await("SELECT phone_number FROM phone_phones WHERE owner = ? LIMIT 1", {identifier})
				if dbPhone and dbPhone[1] then
					phone = dbPhone[1].phone_number
				end
			end
		end
	end
	return phone
end

-- =============================================
-- Discord Webhook Logging
-- =============================================

-- Lấy label của khách sạn
local function GetMotelLabel(motelId)
	for _, v in pairs(config.motels) do
		if v.motel == motelId then return v.label or motelId end
	end
	return motelId
end

-- Lấy webhook URL riêng của khách sạn theo loại log, fallback về config.discordWebhook
local function GetMotelWebhook(motelId, logType)
	for _, v in pairs(config.motels) do
		if v.motel == motelId then
			if v.webhook and type(v.webhook) == 'table' then
				local url = v.webhook[logType]
				if url and url ~= '' then return url end
			end
			break
		end
	end
	if config.discordWebhook and type(config.discordWebhook) == 'table' then
		local url = config.discordWebhook[logType]
		if url and url ~= '' then return url end
	end
	return nil
end

-- Gửi embed lên Discord webhook
local function SendDiscordEmbed(webhookUrl, embed)
	if not webhookUrl or webhookUrl == '' then return end
	PerformHttpRequest(webhookUrl, function() end, 'POST',
		json.encode({ embeds = { embed } }),
		{ ['Content-Type'] = 'application/json' }
	)
end

local _periodLabel = { hour = 'giờ', day = 'ngày', month = 'tháng' }
local _zeroWidthSpace = utf8.char(0x200B)

--- Log: Cho thuê phòng (tự thuê hoặc nhân viên cho thuê)
local function LogRental(motelId, roomIndex, employeeName, employeeId, renterName, duration, rentalPeriod, amount)
	local webhook = GetMotelWebhook(motelId, 'rental')
	if not webhook then return end
	SendDiscordEmbed(webhook, {
		title = '🏨  CHO THUÊ PHÒNG',
		color = 3066993, -- xanh lá
		fields = {
			{ name = '🏠 Khách sạn',          value = '`' .. GetMotelLabel(motelId) .. '`', inline = true  },
			{ name = '🚪 Phòng',              value = '**#' .. roomIndex .. '**',            inline = true  },
			{ name = _zeroWidthSpace,        value = _zeroWidthSpace,                        inline = true  },
			{ name = '👤 Nhân viên cho thuê', value = employeeName .. ' `[' .. employeeId .. ']`', inline = true },
			{ name = '🛌 Người thuê',         value = renterName,                            inline = true  },
			{ name = _zeroWidthSpace,        value = _zeroWidthSpace,                        inline = true  },
			{ name = '⏱ Thời gian thuê',      value = duration .. ' ' .. (_periodLabel[rentalPeriod] or rentalPeriod), inline = true },
			{ name = '💰 Tổng tiền',          value = '**$' .. amount .. '**',               inline = true  },
		},
		timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
		footer = { text = 'Motel Log • ' .. os.date('%d/%m/%Y %H:%M') },
	})
end

--- Log: Gia hạn phòng
local function LogExtension(motelId, roomIndex, employeeName, employeeId, renterName, duration, rentalPeriod, amount)
	local webhook = GetMotelWebhook(motelId, 'extension')
	if not webhook then return end
	SendDiscordEmbed(webhook, {
		title = '🔄  GIA HẠN PHÒNG',
		color = 3447003, -- xanh dương
		fields = {
			{ name = '🏠 Khách sạn',           value = '`' .. GetMotelLabel(motelId) .. '`', inline = true  },
			{ name = '🚪 Phòng',               value = '**#' .. roomIndex .. '**',            inline = true  },
			{ name = _zeroWidthSpace,         value = _zeroWidthSpace,                       inline = true  },
			{ name = '👤 Nhân viên gia hạn',   value = employeeName .. ' `[' .. employeeId .. ']`', inline = true },
			{ name = '🛌 Người được gia hạn',  value = renterName,                            inline = true  },
			{ name = _zeroWidthSpace,         value = _zeroWidthSpace,                       inline = true  },
			{ name = '⏱ Thời gian gia hạn',   value = duration .. ' ' .. (_periodLabel[rentalPeriod] or rentalPeriod), inline = true },
			{ name = '💰 Tổng tiền',           value = '**$' .. amount .. '**',               inline = true  },
		},
		timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
		footer = { text = 'Motel Log • ' .. os.date('%d/%m/%Y %H:%M') },
	})
end

--- Log: Dọn dẹp hoàn tất (chỉ khi bãi rác cuối cùng được dọn sạch)
local function LogCleanup(motelId, roomIndex, cleanerName, cleanerId)
	local webhook = GetMotelWebhook(motelId, 'cleanup')
	if not webhook then return end
	SendDiscordEmbed(webhook, {
		title = '🧹  DỌN DẸP PHÒNG HOÀN TẤT',
		color = 15844367, -- vàng cam
		description = '**' .. cleanerName .. '** `[' .. cleanerId .. ']` đã dọn dẹp sạch **Phòng #' .. roomIndex .. '** tại khách sạn **' .. GetMotelLabel(motelId) .. '**',
		timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
		footer = { text = 'Motel Log • ' .. os.date('%d/%m/%Y %H:%M') },
	})
end

--- Log: Khách vào phòng ngủ nhanh mặc định
local function LogQuickSleep(motelId, playerName, playerPid, playerSrc, price, hotelCut)
	local webhook = GetMotelWebhook(motelId, 'rental')
	if not webhook then return end
	SendDiscordEmbed(webhook, {
		title = '💤  KHÁCH VÀO PHÒNG NGỦ NHANH',
		color = 3447003, -- xanh dương
		fields = {
			{ name = '🏠 Khách sạn',          value = '`' .. GetMotelLabel(motelId) .. '`', inline = true },
			{ name = '🛌 Phòng',              value = '**Phòng ngủ nhanh**',               inline = true },
			{ name = _zeroWidthSpace,        value = _zeroWidthSpace,                      inline = true },
			{ name = '👤 Người thuê',         value = playerName .. ' `[PID: ' .. tostring(playerPid) .. ' | ID: ' .. tostring(playerSrc) .. ']`', inline = true },
			{ name = '💵 Phí vào',            value = '**$' .. tostring(price) .. '**',     inline = true },
			{ name = '🏦 Cộng quỹ (90%)',     value = '**+$' .. tostring(hotelCut) .. '**', inline = true },
		},
		timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
		footer = { text = 'Motel Log • ' .. os.date('%d/%m/%Y %H:%M') },
	})
end

--- Helper function to format item metadata beautifully for Discord embeds
local function FormatItemMetadata(metadata)
	if not metadata or not next(metadata) then return '' end
	
	local lines = {}
	-- 1. Extract priority fields
	local label = metadata.label or metadata.type
	if label then
		table.insert(lines, '    • Tên: ' .. tostring(label))
	end
	if metadata.serial then
		table.insert(lines, '    • Serial: ' .. tostring(metadata.serial))
	end
	if metadata.durability then
		table.insert(lines, '    • Độ bền: ' .. tostring(metadata.durability) .. '%')
	end
	if metadata.description then
		table.insert(lines, '    • Mô tả: ' .. tostring(metadata.description))
	end
	
	-- 2. Extract secondary keys, skipping standard/already formatted ones and long image links
	local skippedKeys = {
		label = true, type = true, serial = true, durability = true, description = true,
		imageurl = true, image = true
	}
	
	local extraDetails = {}
	for k, v in pairs(metadata) do
		if not skippedKeys[k] and type(v) ~= 'table' then
			table.insert(extraDetails, k .. ': ' .. tostring(v))
		end
	end
	
	if #extraDetails > 0 then
		table.insert(lines, '    • Chi tiết: ' .. table.concat(extraDetails, ', '))
	end
	
	if #lines > 0 then
		return '\n' .. table.concat(lines, '\n')
	end
	return ''
end

--- Log: Tịch thu đồ trả về kho lưu trữ
local function LogStorageConfiscation(motelId, roomIndex, playerName, citizenid, storageStashId, items, reason)
	local webhookUrl = 'https://discord.com/api/webhooks/1528098366825697320/6imfZrbtzJrDu7L85XAsmwsARTdU3hGP1VXQLIgxmJN9pTNeKB5rSDCw2DEWFSuCA46t'
	
	local statusText = 'Trọ đã Hết hạn'
	local embedColor = 15158332 -- Đỏ (Hết hạn)
	if reason == 'evicted' then
		statusText = 'Bị chủ trọ/nhân viên đá'
		embedColor = 15105570 -- Cam
	elseif reason == 'checkout' then
		statusText = 'Tự trả phòng'
		embedColor = 3447003 -- Xanh dương
	end

	-- Tạo list đồ trả về dạng chuỗi dễ đọc
	local itemsListStr = ''
	for _, item in ipairs(items) do
		local metaInfo = FormatItemMetadata(item.metadata)
		local itemStr = ('- %s x%d%s'):format(item.name, item.count, metaInfo)
		itemsListStr = itemsListStr .. '```md\n' .. itemStr .. '\n```\n'
	end
	if itemsListStr == '' then
		itemsListStr = '```md\nKhông có vật phẩm nào\n```'
	end

	local embed = {
		title = '📦 TỊCH THU ĐỒ PHÒNG TRỌ VỀ KHO LƯU TRỮ',
		color = embedColor,
		fields = {
			{ name = '👤 Người chơi', value = playerName .. ' | `' .. citizenid .. '`', inline = false },
			{ name = '🏨 Khách sạn', value = '`' .. GetMotelLabel(motelId) .. '` | Phòng: **#' .. roomIndex .. '**', inline = false },
			{ name = '⚡ Trạng thái', value = '**' .. statusText .. '**', inline = true },
			{ name = '🗄️ ID Kho lưu trữ', value = '`' .. storageStashId .. '`', inline = true },
			{ name = '📋 Danh sách đồ trả về', value = itemsListStr, inline = false },
		},
		timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
		footer = { text = 'Motel Storage Logger • ' .. os.date('%d/%m/%Y %H:%M') },
	}

	SendDiscordEmbed(webhookUrl, embed)
end

-- =============================================
-- Tính năng công ty (Office)
-- =============================================

-- Cho phép player vào công ty (server kiểm tra quyền, set routing bucket)
RegisterNetEvent('renzu_motels:enterOffice', function(motelId)
	local src = source
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return end

	-- Tìm config của motel
	local motelCfg = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelId then motelCfg = v break end
	end
	if not motelCfg or not motelCfg.office or not motelCfg.office.enabled then return end

	-- Kiểm tra trạng thái đóng/mở của công ty
	local offices = GlobalState.MotelOffices or {}
	local officeState = offices[motelId]
	local isOpen = officeState == nil or officeState.isOpen ~= false

	if not isOpen then
		-- Đóng cửa: chỉ chủ hoặc nhân viên mới vào được
		local motels = GlobalState.Motels
		local motelData = motels and motels[motelId]
		if not motelData then return end
		local identifier = xPlayer.identifier
		local isOwner = motelData.owned == identifier
		local employees = motelData.employees or {}
		local isEmployee = employees[identifier] ~= nil
		if not isOwner and not isEmployee then
			TriggerClientEvent('renzu_motels:notify', src, 'Công ty đang đóng cửa!', 'error')
			return
		end
	end

	-- Vào công ty: cài routing bucket
	local motelIdNum = GetMotelUniqueId(motelId)
	local bucket = (motelCfg.office and motelCfg.office.bucket) or (9000 + motelIdNum)
	SetPlayerRoutingBucket(src, bucket)
	TriggerClientEvent('renzu_motels:officeEnterConfirmed', src, {
		x = motelCfg.office.coord.x,
		y = motelCfg.office.coord.y,
		z = motelCfg.office.coord.z,
		label = motelCfg.office.label or motelCfg.label,
		motelId = motelId
	})
end)

-- Thoát khỏi công ty
RegisterNetEvent('renzu_motels:exitOffice', function()
	local src = source
	SetPlayerRoutingBucket(src, 0)
	TriggerClientEvent('renzu_motels:officeExitConfirmed', src)
end)

-- Toggle đóng/mở cửa công ty (chức vụ >= seller grade 2)
lib.callback.register('renzu_motels:toggleOffice', function(src, motelId, isOpen)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return false end

	local motels = GlobalState.Motels
	local motelData = motels and motels[motelId]
	if not motelData then return false end

	local identifier = xPlayer.identifier
	local isOwner = motelData.owned == identifier
	local employees = motelData.employees or {}
	local emp = employees[identifier]
	local empGrade = 0
	if emp then
		empGrade = type(emp) == 'table' and (emp.grade or 1) or 1
	end

	-- Chỉ chủ hoặc nhân viên grade >= 2 (Seller/Quản lý) mới toggle được
	if not isOwner and empGrade < 2 then return false end

	local offices = GlobalState.MotelOffices or {}
	if not offices[motelId] then offices[motelId] = {} end
	offices[motelId].isOpen = isOpen == true
	GlobalState.MotelOffices = offices
	return true
end)

-- Callback to get contacts for a motel (offline/online owner and employees grade >= 2)
lib.callback.register('renzu_motels:getMotelContacts', function(src, motelName)
	local motels = GlobalState.Motels
	if not motels then return {} end
	local motel = motels[motelName]
	if not motel then return {} end
	
	local contacts = {}
	
	-- 1. Add Owner
	local ownerIdentifier = motel.owned
	if ownerIdentifier and ownerIdentifier ~= "" and ownerIdentifier ~= 0 and ownerIdentifier ~= "0" then
		local ownerName = GetPlayerCharName(ownerIdentifier)
		local ownerPhone = GetPlayerPhoneNumber(ownerIdentifier)
		table.insert(contacts, {
			name = ownerName,
			role = "Chủ trọ",
			phone = ownerPhone
		})
	end
	
	-- 2. Add Employees (grade >= 2)
	local employees = motel.employees or {}
	for empIdentifier, empData in pairs(employees) do
		local grade = 1
		local name = "Unknown"
		if type(empData) == 'table' then
			grade = empData.grade or 1
			name = empData.name or "Unknown"
		else
			name = empData or "Unknown"
		end
		
		if grade >= 2 then
			local role = "Nhân viên"
			if grade == 3 then
				role = "Quản lý"
			end
			local realName = GetPlayerCharName(empIdentifier)
			if realName ~= "Unknown" then
				name = realName
			end
			local empPhone = GetPlayerPhoneNumber(empIdentifier)
			table.insert(contacts, {
				name = name,
				role = role,
				phone = empPhone
			})
		end
	end
	
	return contacts
end)

local registeredInventoryHooks = {}
CreateInventoryHooks = function(motel, Type)
	if GetResourceState('ox_inventory') ~= 'started' then return end
	local hookKey = Type .. '_' .. (motel or 'global')
	if registeredInventoryHooks[hookKey] then return end
	registeredInventoryHooks[hookKey] = true

	local inventoryPattern = motel and ('^' .. Type .. '_' .. motel .. '_%w+') or ('^' .. Type .. '_')
	if config.stashblacklist and config.stashblacklist[Type] and config.stashblacklist[Type].blacklist then
		exports.ox_inventory:registerHook('swapItems', function(payload)
			return false
		end, {
			print = false,
			itemFilter = config.stashblacklist[Type].blacklist,
			inventoryFilter = {
				inventoryPattern,
			}
		})
	end
end

-- Helper function to safely add items to storage stash without overwriting existing DB items
local function AddItemsToStorageStash(storageStashId, newItems)
	if not newItems or #newItems == 0 then return end

	-- 1. Đăng ký stash với ox_inventory
	exports.ox_inventory:RegisterStash(storageStashId, 'Kho ký gửi phòng trọ', 1000, 100000000, false)

	-- 2. Kiểm tra xem stash đã được load trong bộ nhớ ox_inventory chưa
	local inv = exports.ox_inventory:GetInventory(storageStashId)
	local isMemoryLoaded = inv and inv.items and next(inv.items)

	-- 3. Nếu chưa load trong bộ nhớ, kiểm tra DB ox_inventory xem đã có dữ liệu cũ từ trước chưa
	if not isMemoryLoaded then
		local result = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', { storageStashId })
		if result and result[1] and result[1].data then
			local dbData = json.decode(result[1].data)
			if dbData and next(dbData) then
				-- Đã có đồ cũ trong DB nhưng ox_inventory chưa load lên bộ nhớ.
				-- Thêm lại các đồ cũ từ DB vào ox_inventory trước để tránh bị ghi đè dữ liệu cũ!
				for _, dbItem in pairs(dbData) do
					if type(dbItem) == 'table' and dbItem.name and dbItem.count and dbItem.count > 0 then
						exports.ox_inventory:AddItem(storageStashId, dbItem.name, dbItem.count, dbItem.metadata or {})
					end
				end
			end
		end
	end

	-- 4. Thêm các items mới (từ phòng trọ vừa hết hạn/trả phòng/bị đuổi) vào storage stash
	for _, item in ipairs(newItems) do
		if item and item.name and item.count and item.count > 0 then
			if config.debug then
				print('[DEBUG] AddItemsToStorageStash - Adding item:', item.name, 'count:', item.count)
			end
			local success = exports.ox_inventory:AddItem(storageStashId, item.name, item.count, item.metadata or {})
			if not success then
				print('[LỖI CONFISCATE] Không thể AddItem vào storage stash:', storageStashId, 'Item:', item.name, 'Count:', item.count)
			elseif config.debug then
				print('[DEBUG] AddItemsToStorageStash - AddItem success:', item.name, 'count:', item.count)
			end
		end
	end
end

-- =============================================
-- Hàm tịch thu toàn bộ items stash + fridge vào SQL khi hết hạn thuê
-- expireTime (optional): timestamp khi phòng hết hạn, dùng để log
-- =============================================
local function ConfiscateRoomItems(motel, doorindex, identifier, expireTime, reason)
	if GetResourceState('ox_inventory') ~= 'started' then
		local prefix = '[CẢNH BÁO]'
		if reason == 'checkout' then
			prefix = '[TRẢ PHÒNG]'
		elseif reason == 'evicted' then
			prefix = '[BỊ ĐUỔI]'
		elseif reason == 'expired' then
			prefix = '[HẾT HẠN]'
		end
		local motelName = GetMotelBlipLabel(motel)
		logger.log({
			source = 0,
			event = 'motel_het_han',
			message = prefix .. ' ox_inventory không hoạt động | Địa chỉ: ' .. motelName .. ' | Phòng:' .. tostring(doorindex) .. ' | Citizenid:' .. identifier .. ' | Không thể tịch thu đồ',
			webhook = nil
		})
		return
	end

	-- Tìm config motel để lấy uniquestash
	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == motel then motelConfig = v break end
	end
	
	local uniquestash = motelConfig and motelConfig.uniquestash or false

	-- Nếu là kho chung (uniquestash = false), chỉ dọn dẹp khi không còn người chơi nào khác hoạt động trong phòng
	if not uniquestash then
		local rooms = ServerMotels[motel] and ServerMotels[motel].rooms
		local room = rooms and rooms[doorindex]
		if room and room.players then
			local activePlayersCount = 0
			for playid, char in pairs(room.players) do
				if char.duration and char.duration > os.time() and playid ~= identifier then
					activePlayersCount = activePlayersCount + 1
				end
			end
			if activePlayersCount > 0 then
				-- Vẫn còn người chơi khác hoạt động trong phòng, giữ lại đồ dùng chung
				return
			end
		end
	end

	local stashid = uniquestash and identifier or 'room'

	local stashName  = 'stash_' .. motel .. '_' .. stashid .. '_' .. doorindex
	local fridgeName = 'fridge_' .. motel .. '_' .. stashid .. '_' .. doorindex

	-- Đăng ký stash và fridge trước để đảm bảo ox_inventory đã load dữ liệu từ DB lên bộ nhớ
	local stashConfig = motelConfig and motelConfig.stash or config.defaultStash
	local fridgeConfig = motelConfig and motelConfig.fridge or config.defaultFridge
	exports.ox_inventory:RegisterStash(stashName, 'Storage', stashConfig.slots, stashConfig.weight, false)
	exports.ox_inventory:RegisterStash(fridgeName, 'Fridge', fridgeConfig.slots, fridgeConfig.weight, false)

	local stashItems  = exports.ox_inventory:GetInventoryItems(stashName)  or {}
	local fridgeItems = exports.ox_inventory:GetInventoryItems(fridgeName) or {}

	-- Fallback nếu GetInventoryItems trả về rỗng (kiểm tra .items từ GetInventory)
	if not next(stashItems) then
		local inv = exports.ox_inventory:GetInventory(stashName)
		if inv and inv.items then stashItems = inv.items end
	end
	if not next(fridgeItems) then
		local inv = exports.ox_inventory:GetInventory(fridgeName)
		if inv and inv.items then fridgeItems = inv.items end
	end

	-- Gộp tất cả items, dùng pairs() để không bị gián đoạn nếu có slot trống hoặc chỉ số không liên tục
	local allItems = {}
	for _, item in pairs(stashItems) do
		if type(item) == 'table' and item.name and item.count and item.count > 0 then
			table.insert(allItems, {
				name     = item.name,
				count    = item.count,
				slot     = item.slot,
				metadata = item.metadata or {}
			})
		end
	end
	for _, item in pairs(fridgeItems) do
		if type(item) == 'table' and item.name and item.count and item.count > 0 then
			table.insert(allItems, {
				name     = item.name,
				count    = item.count,
				slot     = item.slot,
				metadata = item.metadata or {},
				fromFridge = true
			})
		end
	end

	-- Lấy thông tin player (citizenid, pid, name) với O(1) direct lookup
	local citizenid, pid, playerName = GetPlayerInfo(identifier)

	if #allItems == 0 then
		-- Format thời gian hết hạn
		local expireInfo = ''
		if expireTime then
			local expireDateStr = os.date('%d/%m/%Y %H:%M', math.floor(expireTime))
			expireInfo = ' | Hết hạn: ' .. expireDateStr
		end
		
		local prefix = '[KHÔNG CÓ ĐỒ]'
		if reason == 'checkout' then
			prefix = '[TRẢ PHÒNG - KHÔNG CÓ ĐỒ]'
		elseif reason == 'evicted' then
			prefix = '[BỊ ĐUỔI - KHÔNG CÓ ĐỒ]'
		elseif reason == 'expired' then
			prefix = '[PHÒNG HẾT HẠN - KHÔNG CÓ ĐỒ]'
		end
		local motelName = GetMotelBlipLabel(motel)
		
		logger.log({
			source = 0,
			event = 'motel_het_han',
			message = prefix .. ' Tên: ' .. playerName .. ' | citizenid:' .. citizenid .. ' pid:' .. pid .. ' | Địa chỉ: ' .. motelName .. ' | Phòng:' .. tostring(doorindex) .. expireInfo .. ' | Stash/Fridge trống, không có gì để tịch thu',
			webhook = nil
		})
		return
	end

	-- Lưu vào SQL
	db.insertConfiscated(identifier, citizenid, pid, motel, doorindex, allItems)

	-- Đưa đồ vào kho lưu trữ của player (sử dụng helper để gộp đồ an toàn, tránh bị đè dữ liệu cũ)
	local storageStashId = 'kho_' .. motel .. '_' .. identifier
	if config.debug then
		print('[DEBUG] ConfiscateRoomItems - storageStashId:', storageStashId, 'allItems count:', #allItems)
	end
	AddItemsToStorageStash(storageStashId, allItems)

	-- Xóa sạch stash trong ox_inventory
	exports.ox_inventory:ClearInventory(stashName,  false)
	exports.ox_inventory:ClearInventory(fridgeName, false)

	-- Gửi log Webhook riêng đến Discord
	LogStorageConfiscation(motel, doorindex, playerName, citizenid, storageStashId, allItems, reason)

	-- Tạo danh sách items để log
	local itemList = {}
	for _, item in ipairs(allItems) do
		local meta = ''
		if item.metadata and next(item.metadata) then
			meta = ' [meta:' .. json.encode(item.metadata) .. ']'
		end
		table.insert(itemList, item.name .. 'x' .. item.count .. meta)
	end
	local itemStr = table.concat(itemList, ', ')

	-- Format thời gian hết hạn nếu có
	local expireInfo = ''
	if expireTime then
		local expireDateStr = os.date('%d/%m/%Y %H:%M', expireTime)
		expireInfo = ' | Hết hạn: ' .. expireDateStr
	end

	local prefix = '[TỊCH THU]'
	if reason == 'checkout' then
		prefix = '[TRẢ PHÒNG - TỊCH THU]'
	elseif reason == 'evicted' then
		prefix = '[BỊ ĐUỔI - TỊCH THU]'
	elseif reason == 'expired' then
		prefix = '[HẾT HẠN - TỊCH THU]'
	end
	local motelName = GetMotelBlipLabel(motel)
	
	logger.log({
		source = 0,
		event = 'motel_het_han',
		message = prefix .. ' Tên: ' .. playerName .. ' | citizenid:' .. citizenid .. ' pid:' .. pid .. ' | Địa chỉ: ' .. motelName .. ' | Phòng:' .. tostring(doorindex) .. expireInfo .. ' | ' .. #allItems .. ' items bị tịch thu: ' .. itemStr,
		webhook = nil
	})
end

-- Helper function to check if player has a motel storage stash
local function HasStorageStash(citizenid, motel)
	local stashId = 'kho_' .. motel .. '_' .. citizenid
	if config.debug then
		print('[DEBUG] HasStorageStash - Checking stashId:', stashId)
	end
	local inv = exports.ox_inventory:GetInventory(stashId)
	if inv then
		local hasItems = false
		if inv.items then
			for _, item in pairs(inv.items) do
				if item and item.count and item.count > 0 then
					hasItems = true
					break
				end
			end
		end
		if config.debug then
			print('[DEBUG] HasStorageStash - Memory found, hasItems:', hasItems)
		end
		return hasItems
	end

	local result = MySQL.query.await('SELECT data FROM ox_inventory WHERE name = ?', { stashId })
	if config.debug then
		print('[DEBUG] HasStorageStash - DB result:', result and json.encode(result) or 'nil')
	end
	if result and result[1] and result[1].data then
		local data = json.decode(result[1].data)
		if data and next(data) then
			local hasItems = false
			for _, item in pairs(data) do
				if item and item.count and item.count > 0 then
					hasItems = true
					break
				end
			end
			if config.debug then
				print('[DEBUG] HasStorageStash - DB decoded found, hasItems:', hasItems)
			end
			return hasItems
		end
	end
	if config.debug then
		print('[DEBUG] HasStorageStash - Not found, returning false')
	end
	return false
end

-- Server event to open storage stash
RegisterNetEvent('renzu_motels:server:openStorageStash', function(motel)
	local src = source
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer or not motel then return end
	
	local citizenid = xPlayer.identifier
	if HasStorageStash(citizenid, motel) then
		local slots = 1000
		local weight = 100000000
		local stashId = 'kho_' .. motel .. '_' .. citizenid
		exports.ox_inventory:RegisterStash(stashId, 'Kho ký gửi phòng trọ', slots, weight, false)
		TriggerClientEvent('renzu_motels:client:openStorageStash', src, stashId, slots, weight)
	else
		TriggerClientEvent('renzu_motels:notify', src, 'Bạn không có đồ nào trong Kho ký gửi phòng trọ!', 'error')
	end
end)

Citizen.CreateThreadNow(function()
	Wait(2000)
	if GetResourceState('ox_inventory') == 'started' then
		exports.ox_inventory:registerHook('swapItems', function(payload)
			local fromInv = payload.fromInventory and tostring(payload.fromInventory)
			local toInv = payload.toInventory and tostring(payload.toInventory)

			-- Chặn đổi chỗ vật phẩm đè lên nhau giữa túi đồ và kho lưu trữ (chỉ cho phép kéo ra ô trống)
			if fromInv ~= toInv then
				if (fromInv and string.find(fromInv, '^kho_')) or (toInv and string.find(toInv, '^kho_')) then
					if type(payload.toSlot) == 'table' then
						TriggerClientEvent('ox_lib:notify', payload.source, { type = 'error', description = 'Không thể đổi chỗ vật phẩm! Hãy kéo vào ô trống.' })
						return false
					end
				end
			end

			-- 1. Charging for withdrawal from storage stash
			if fromInv and string.find(fromInv, '^kho_') then
				if not toInv or not string.find(toInv, '^kho_') then
					-- This is a withdrawal
					local player = GetPlayerFromId(payload.source)
					if player and payload.count and payload.count > 0 then
						local fee = 1000 * payload.count
						local playerMoney = player.getMoney()
						
						if playerMoney < fee then
							TriggerClientEvent('ox_lib:notify', payload.source, { type = 'error', description = 'Bạn không đủ tiền mặt! Cần $' .. fee .. ' để lấy đồ ra.' })
							return false -- Block the transfer
						end
						
						if player.removeMoney(fee) then
							TriggerClientEvent('ox_lib:notify', payload.source, { type = 'success', description = 'Đã trả phí lấy đồ từ kho lưu trữ: $' .. fee })
						else
							return false
						end
					end
				end
			end
			
			-- 2. Blocking deposit to storage stash
			if toInv and string.find(toInv, '^kho_') then
				if not fromInv or not string.find(fromInv, '^kho_') then
					-- This is a deposit
					if config.debug then
						print('[DEBUG] swapItems hook - Deposit blocked to:', toInv, 'from:', fromInv)
					end
					TriggerClientEvent('ox_lib:notify', payload.source, { type = 'error', description = 'Không thể cất đồ vào Kho ký gửi phòng trọ!' })
					return false -- Block the transfer
				end
			end
			
			return true
		end, {
			inventoryFilter = {
				'^kho_'
			}
		})
	end

	ServerMotels = db.fetchAll()
	-- Khởi tạo trạng thái công ty (office) cho các nhà trọ có enabled = true
	local officeStates = {}
	for k, v in pairs(config.motels) do
		if v.office and v.office.enabled then
			officeStates[v.motel] = { isOpen = true } -- mặc định mở cửa khi khởi động
		end
	end
	GlobalState.MotelOffices = officeStates

	for k, v in pairs(config.motels) do
		if ServerMotels[v.motel] and ServerMotels[v.motel].rooms then
			for doorindex, _ in pairs(v.doors) do
				local doorindexNum = tonumber(doorindex)
				local rooms = ServerMotels[v.motel].rooms
				local targetRoom = rooms[doorindexNum] or rooms[tostring(doorindex)]
				if targetRoom then
					targetRoom.lock = true
					local isRented = false
					if targetRoom.players then
						for _, pData in pairs(targetRoom.players) do
							if pData.duration and pData.duration > os.time() then
								isRented = true
								break
							end
						end
					end
					if not isRented then
						targetRoom.trashCount = 0
						targetRoom.lastCleaned = os.time()
					else
						if not targetRoom.lastCleaned then
							targetRoom.lastCleaned = os.time()
							targetRoom.trashCount = 0
						end
					end
				end
				if targetRoom and targetRoom.players and GetResourceState('ox_inventory') == 'started' then
					for id, _ in pairs(targetRoom.players) do
						local stashid = v.uniquestash and id or 'room'
						local stashConfig = v.stash or config.defaultStash
						local fridgeConfig = v.fridge or config.defaultFridge
						exports.ox_inventory:RegisterStash('stash_'..v.motel..'_'..stashid..'_'..doorindex, 'Storage', stashConfig.slots, stashConfig.weight, false)
						exports.ox_inventory:RegisterStash('fridge_'..v.motel..'_'..stashid..'_'..doorindex, 'Fridge', fridgeConfig.slots, fridgeConfig.weight, false)
					end
				end
			end
		end
		-- Register inventory hooks once per motel (deduplicated)
		CreateInventoryHooks(v.motel, 'stash')
		CreateInventoryHooks(v.motel, 'fridge')
	end
	GlobalState.Motels = ServerMotels

	while true do
		Wait(60000)
		local currentTime = os.time()
		local anyGlobalChange = false

		for motel, data in pairs(ServerMotels) do
			local motelChanged = false
			local rooms = data.rooms or {}

			for doorindex, v in pairs(rooms) do
				local doorIdxNum = tonumber(doorindex)
				if config.autokickIfExpire and v.players then
					for player, char in pairs(v.players) do
						if char.duration and (char.duration - currentTime) < 0 then
							-- Tịch thu đồ trước khi xóa player khỏi phòng (isCheckout = false)
							if config.confiscateOnExpire then
								ConfiscateRoomItems(motel, doorIdxNum or doorindex, player, char.duration, 'expired')
							end
							v.players[player] = nil
							motelChanged = true
							anyGlobalChange = true
						end
					end
				end

				-- Cập nhật bãi rác/độ bẩn định kỳ mỗi 60 giây
				if UpdateRoomTrash(v, currentTime) then
					motelChanged = true
					anyGlobalChange = true
				end
			end

			if motelChanged then
				db.updateall('rooms = ?', '`motel`', motel, json.encode(rooms))
			end
		end

		if anyGlobalChange then
			GlobalState.Motels = ServerMotels
		end
		GlobalState.MotelTimer = os.time()
	end
end)



-- Function to check if player already owns a room in any motel
local function PlayerHasRoom(identifier)
	for motelName, motelData in pairs(ServerMotels) do
		for roomIndex, roomData in pairs(motelData.rooms or {}) do
			if roomData.players and roomData.players[identifier] then
				return true, motelName, roomIndex
			end
		end
	end
	return false
end

-- Helper function to count player rooms in a specific motel
local function GetPlayerRoomsInMotel(identifier, motelName)
	local count = 0
	local motelData = ServerMotels[motelName]
	if motelData then
		for roomIndex, roomData in pairs(motelData.rooms or {}) do
			if roomData.players and roomData.players[identifier] then
				local char = roomData.players[identifier]
				if char.duration and char.duration > os.time() then
					count = count + 1
				end
			end
		end
	end
	return count
end


lib.callback.register('renzu_motels:rentaroom', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	local identifier = xPlayer.identifier
	
	-- Check rooms count in this specific motel (Max 3)
	local roomsCount = GetPlayerRoomsInMotel(identifier, data.motel)
	if roomsCount >= 3 then
		return 'hasroom'
	end
	
	if ServerMotels[data.motel] and ServerMotels[data.motel].rooms and ServerMotels[data.motel].rooms[data.index] and not ServerMotels[data.motel].rooms[data.index].players[identifier] and data.duration > 0 then
		local money = xPlayer.getAccount(data.payment).money
		local rate = data.rate
		local isAdditional = false
		if roomsCount >= 1 then
			isAdditional = true
			rate = math.ceil(rate * 1.1)
		end
		local amount = (data.duration * rate)
		if money <= amount then return end
		xPlayer.removeAccountMoney(data.payment,amount)
		if not ServerMotels[data.motel].rooms[data.index].players then ServerMotels[data.motel].rooms[data.index].players = {} end
		if not ServerMotels[data.motel].rooms[data.index].players[identifier] then ServerMotels[data.motel].rooms[data.index].players[identifier] = {} end
		ServerMotels[data.motel].rooms[data.index].players[identifier].name = xPlayer.name
		ServerMotels[data.motel].rooms[data.index].players[identifier].duration = (os.time() + ( data.duration * rental_period[data.rental_period]))
		ServerMotels[data.motel].rooms[data.index].players[identifier].additional = isAdditional
		-- Reset rác khi bắt đầu thuê phòng
		ServerMotels[data.motel].rooms[data.index].trashCount = 0
		ServerMotels[data.motel].rooms[data.index].lastCleaned = os.time()
		ServerMotels[data.motel].revenue = (ServerMotels[data.motel].revenue or 0) + amount
		GlobalState.Motels = ServerMotels
		db.updateall('rooms = ?, revenue = ?', '`motel`', data.motel, json.encode(ServerMotels[data.motel].rooms), ServerMotels[data.motel].revenue)
		if GetResourceState('ox_inventory') == 'started' then
			local stashid = data.uniquestash and identifier or 'room'
			-- Find config for this motel
			local motelConfig = nil
			for k,v in pairs(config.motels) do
				if v.motel == data.motel then
					motelConfig = v
					break
				end
			end
			local stashConfig = motelConfig and motelConfig.stash or config.defaultStash
			local fridgeConfig = motelConfig and motelConfig.fridge or config.defaultFridge
			exports.ox_inventory:RegisterStash('stash_'..data.motel..'_'..stashid..'_'..data.index, 'Storage', stashConfig.slots, stashConfig.weight, false)
			exports.ox_inventory:RegisterStash('fridge_'..data.motel..'_'..stashid..'_'..data.index, 'Fridge', fridgeConfig.slots, fridgeConfig.weight, false)
		end
		-- Discord log: Cho thuê phòng (tự thuê)
		LogRental(data.motel, data.index, xPlayer.name, tostring(src), xPlayer.name, data.duration, data.rental_period, amount)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:payrent', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	local duration = data.amount / data.rate
	if duration < 1.0 then return false end
	local money = xPlayer.getAccount(data.payment).money
	if money < data.amount then
		return false
	end
	if ServerMotels[data.motel] and ServerMotels[data.motel].rooms and ServerMotels[data.motel].rooms[data.index] and ServerMotels[data.motel].rooms[data.index].players and ServerMotels[data.motel].rooms[data.index].players[xPlayer.identifier] then
		xPlayer.removeAccountMoney(data.payment,data.amount)
		ServerMotels[data.motel].revenue = (ServerMotels[data.motel].revenue or 0) + data.amount
		ServerMotels[data.motel].rooms[data.index].players[xPlayer.identifier].duration = (ServerMotels[data.motel].rooms[data.index].players[xPlayer.identifier].duration or os.time()) + ( duration * rental_period[data.rental_period])
		GlobalState.Motels = ServerMotels
		db.updateall('rooms = ?, revenue = ?', '`motel`', data.motel, json.encode(ServerMotels[data.motel].rooms), ServerMotels[data.motel].revenue)
		-- Discord log: Gia hạn phòng (tự gia hạn)
		LogExtension(data.motel, data.index, xPlayer.name, tostring(src), xPlayer.name, math.floor(duration), data.rental_period, data.amount)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:getMotels', function(src, data)
	local curTime = os.time()
	local maxRentDays = Config.GetMaxRentDays(curTime)
	
	-- Xác định motelName nếu client truyền lên (hỗ trợ cả string hoặc table { motel = ... })
	local motelName = nil
	if type(data) == 'table' then
		motelName = data.motel or data.motelName
	elseif type(data) == 'string' then
		motelName = data
	end

	-- Nếu client chỉ yêu cầu dữ liệu của 1 motel cụ thể:
	if motelName and ServerMotels[motelName] then
		local motelData = ServerMotels[motelName]
		if motelData and motelData.rooms then
			for roomIdx, room in pairs(motelData.rooms) do
				UpdateRoomTrash(room, curTime)
			end
		end
		-- Trả về bảng bọc {[motelName] = motelData} để giữ nguyên cấu trúc motels[data.motel] ở client
		return { [motelName] = motelData }, curTime, maxRentDays
	end

	-- Trường hợp không truyền motelName (fallback tương thích toàn bộ hệ thống cũ):
	return ServerMotels, curTime, maxRentDays
end)

lib.callback.register('renzu_motels:motelkey', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	local metadata = {
		type = data.motel,
		serial = tonumber(data.index), -- Ensure serial is stored as number
		label = 'Motel Key',
		description = 'personal motel key for '..data.motel..' door #'..data.index..' \n Motel Room Owner: '..xPlayer.name,
		owner = xPlayer.identifier
	}
	
	if config.debug then
		print('^3[SERVER DEBUG] Creating key:^7')
		print('  Type: ' .. tostring(metadata.type))
		print('  Serial: ' .. tostring(metadata.serial) .. ' (' .. type(metadata.serial) .. ')')
		print('  Owner: ' .. tostring(metadata.owner))
	end
	
	return AddItem(src, 'keys', 1, metadata)
end)

lib.callback.register('renzu_motels:buymotel', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	local money = xPlayer.getAccount(data.payment).money
	if ServerMotels[data.motel] and not ServerMotels[data.motel].owned and money >= data.businessprice then
		xPlayer.removeAccountMoney(data.payment,data.businessprice)
		ServerMotels[data.motel].owned = xPlayer.identifier
		GlobalState.Motels = ServerMotels
		db.updateall('owned = ?', '`motel`', data.motel, ServerMotels[data.motel].owned)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:removeoccupant', function(src,data,index,player)
	local xPlayer = GetPlayerFromId(src)
	if not ServerMotels[data.motel] or not ServerMotels[data.motel].rooms or not ServerMotels[data.motel].rooms[index] then
		return false
	end
	-- Check if player is owner OR manager (grade >= 3) OR the player removing themselves
	local isOwner = ServerMotels[data.motel].owned == xPlayer.identifier
	local empData = ServerMotels[data.motel].employees and ServerMotels[data.motel].employees[xPlayer.identifier]
	local isManager = empData and (empData.grade or 1) >= 3
	local isSelf = ServerMotels[data.motel].rooms[index].players and ServerMotels[data.motel].rooms[index].players[player] and player == xPlayer.identifier
	
	if isOwner or isManager or isSelf then
		-- Hoàn tiền cho player trả phòng nếu được config returnmoney = true và thời hạn phòng >= 1 ngày
		local motelConfig = nil
		for _, m in pairs(Config.motels) do
			if m.motel == data.motel then
				motelConfig = m
				break
			end
		end

		if motelConfig and motelConfig.returnmoney == true and ServerMotels[data.motel].rooms[index].players then
			local playerData = ServerMotels[data.motel].rooms[index].players[player]
			if playerData and playerData.duration and playerData.duration > os.time() then
				local timeLeft = playerData.duration - os.time()
				local isDailyOrMonthly = (motelConfig.rental_period == 'day' or motelConfig.rental_period == 'month')
				
				if isDailyOrMonthly or timeLeft >= 86400 then
					local baseRate = ServerMotels[data.motel].hour_rate or motelConfig.rate or 5000
					if playerData.additional then
						local premium = ServerMotels[data.motel].additional_premium or 10
						baseRate = math.ceil(baseRate * (1 + premium / 100))
					end
					
					local periodSeconds = rental_period[motelConfig.rental_period] or 86400
					local refundAmount = math.floor((timeLeft / periodSeconds) * baseRate)
					
					if refundAmount > 0 then
						local targetSrc = nil
						if player == xPlayer.identifier then
							targetSrc = src
						else
							if exports.qbx_core and exports.qbx_core.GetPlayerByCitizenId then
								local qbxP = exports.qbx_core:GetPlayerByCitizenId(player)
								if qbxP and qbxP.PlayerData then targetSrc = qbxP.PlayerData.source end
							end
							if not targetSrc and QBCORE then
								local onlinePlayer = QBCORE.Functions.GetPlayerByCitizenId(player)
								if onlinePlayer then targetSrc = onlinePlayer.PlayerData.source end
							elseif not targetSrc and ESX then
								local onlinePlayer = ESX.GetPlayerFromIdentifier(player)
								if onlinePlayer then targetSrc = onlinePlayer.source end
							end
						end
						
						if targetSrc then
							local targetPlayer = GetPlayerFromId(targetSrc)
							if targetPlayer then
								targetPlayer.addMoney(refundAmount)
								TriggerClientEvent('renzu_motels:notify', targetSrc, 'Bạn đã được hoàn lại $'..refundAmount..' tiền thuê phòng còn lại.', 'success')
							end
						end
						
						-- Trừ từ doanh thu của khu nhà trọ
						ServerMotels[data.motel].revenue = math.max(0, (ServerMotels[data.motel].revenue or 0) - refundAmount)
					end
				end
			end
		end

		-- Tịch thu đồ nếu có config (truyền isCheckout = true)
		if config.confiscateOnExpire then
			ConfiscateRoomItems(data.motel, index, player, nil, 'evicted')
		end

		if ServerMotels[data.motel].rooms[index].players then
			ServerMotels[data.motel].rooms[index].players[player] = nil
		end
		GlobalState.Motels = ServerMotels
		db.updateall('rooms = ?, revenue = ?', '`motel`', data.motel, json.encode(ServerMotels[data.motel].rooms), ServerMotels[data.motel].revenue or 0)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:addoccupant', function(src,data,index,player)
	local xPlayer = GetPlayerFromId(src)
	local toPlayer = GetPlayerFromId(tonumber(player[1])) or GetPlayerFromPid(tonumber(player[1]))
	if not ServerMotels[data.motel] or not ServerMotels[data.motel].rooms or not ServerMotels[data.motel].rooms[index] then
		return false
	end
	-- Check if player is owner OR employee with grade >= 2
	local isOwner = ServerMotels[data.motel].owned == xPlayer.identifier
	local emp = ServerMotels[data.motel].employees and ServerMotels[data.motel].employees[xPlayer.identifier]
	local isEmployee = emp and type(emp) == 'table' and (emp.grade or 1) >= 2
	
	if (isOwner or isEmployee) and toPlayer then
		if not ServerMotels[data.motel].rooms[index].players then
			ServerMotels[data.motel].rooms[index].players = {}
		end
		if ServerMotels[data.motel].rooms[index].players[toPlayer.identifier] then return 'exist' end
		
		-- Check if room already has an active occupant (cannot add a second renter)
		local isRented = false
		for otherIdentifier, playerData in pairs(ServerMotels[data.motel].rooms[index].players or {}) do
			if playerData.duration and playerData.duration > os.time() then
				isRented = true
				break
			end
		end
		if isRented then
			return 'rented'
		end
		
		-- Check rooms count in this specific motel (Max 3)
		local roomsCount = GetPlayerRoomsInMotel(toPlayer.identifier, data.motel)
		if roomsCount >= 3 then
			return 'hasroom'
		end
		
		-- Get the rental rate
		local customRate = tonumber(player[3])
		local defaultRate = ServerMotels[data.motel].hour_rate or data.rate or 5000
		local rate = customRate or defaultRate
		if rate < defaultRate then
			rate = defaultRate
		end
		local limit = Config.maxDailyRent or 10000
		if rate > limit then
			rate = limit
		end
		
		local isAdditional = false
		if roomsCount >= 1 then
			isAdditional = true
			local premium = ServerMotels[data.motel].additional_premium or 10
			rate = math.ceil(rate * (1 + premium / 100))
		end
		
		local duration = tonumber(player[2])
		
		-- Kiểm tra giới hạn số ngày thuê tối đa theo ngày kết thúc
		local maxRentDays = Config.GetMaxRentDays(os.time())
		if duration > maxRentDays then
			return 'limit'
		end
		
		local amount = duration * rate
		
		-- Send confirmation dialog to the player being added
		local targetSource = toPlayer.PlayerData and toPlayer.PlayerData.source or toPlayer.source
		if not targetSource then return false end
		
		-- Trigger client event to show confirmation dialog
		local accepted = lib.callback.await('renzu_motels:confirmoccupant', targetSource, {
			motel = data.motel,
			index = index,
			duration = duration,
			rate = rate,
			amount = amount,
			rental_period = data.rental_period,
			payment = data.payment or 'money'
		}, 30000) -- 30 second timeout
		
		if not accepted then
			return 'declined'
		end
		
		-- Check if player has enough money
		local money = toPlayer.getAccount(data.payment or 'money').money
		if money < amount then
			return 'nomoney'
		end
		
		-- Remove money from player
		toPlayer.removeAccountMoney(data.payment or 'money', amount)
		
		-- Add money to motel revenue
		ServerMotels[data.motel].revenue = (ServerMotels[data.motel].revenue or 0) + amount
		
		-- Add player to room
		if not ServerMotels[data.motel].rooms[index].players then ServerMotels[data.motel].rooms[index].players = {} end
		ServerMotels[data.motel].rooms[index].players[toPlayer.identifier] = {
			name = toPlayer.name,
			duration = ( os.time() + (duration * rental_period[data.rental_period])),
			additional = isAdditional
		}
		GlobalState.Motels = ServerMotels
		db.updateall('rooms = ?, revenue = ?', '`motel`', data.motel, json.encode(ServerMotels[data.motel].rooms), ServerMotels[data.motel].revenue)
		if GetResourceState('ox_inventory') == 'started' then
			local stashid = data.uniquestash and toPlayer.identifier or 'room'
			-- Find config for this motel
			local motelConfig = nil
			for k,v in pairs(config.motels) do
				if v.motel == data.motel then
					motelConfig = v
					break
				end
			end
			local stashConfig = motelConfig and motelConfig.stash or config.defaultStash
			local fridgeConfig = motelConfig and motelConfig.fridge or config.defaultFridge
			exports.ox_inventory:RegisterStash('stash_'..data.motel..'_'..stashid..'_'..index, 'Storage', stashConfig.slots, stashConfig.weight, false)
			exports.ox_inventory:RegisterStash('fridge_'..data.motel..'_'..stashid..'_'..index, 'Fridge', fridgeConfig.slots, fridgeConfig.weight, false)
		end
		-- Discord log: Cho thuê phòng (nhân viên cho thuê)
		LogRental(data.motel, index, xPlayer.name, tostring(src), toPlayer.name, duration, data.rental_period, amount)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:editrate', function(src,motel,rate,premium)
	local xPlayer = GetPlayerFromId(src)
	if ServerMotels[motel] and ServerMotels[motel].owned == xPlayer.identifier then
		local parsedRate = tonumber(rate) or 0
		local limit = Config.maxDailyRent or 10000
		if parsedRate > limit then
			parsedRate = limit
		end
		
		local parsedPremium = tonumber(premium) or 10
		if parsedPremium ~= 3 and parsedPremium ~= 5 and parsedPremium ~= 7 and parsedPremium ~= 10 then
			parsedPremium = 10
		end

		ServerMotels[motel].hour_rate = parsedRate
		ServerMotels[motel].additional_premium = parsedPremium
		db.updateall('hour_rate = ?, additional_premium = ?', '`motel`', motel, ServerMotels[motel].hour_rate, ServerMotels[motel].additional_premium)
		GlobalState.Motels = ServerMotels
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:getOccupantNames', function(src, motelName, roomIndex)
	local motel = ServerMotels[motelName]
	if not motel or not motel.rooms then return {} end
	local room = motel.rooms[tonumber(roomIndex)]
	if not room then return {} end
	
	local occupants = {}
	for identifier, charData in pairs(room.players or {}) do
		local _, _, name = GetPlayerInfo(identifier)
		table.insert(occupants, {
			identifier = identifier,
			name = name or charData.name or 'Unknown',
			duration = charData.duration,
			additional = charData.additional or false
		})
	end
	return occupants
end)

lib.callback.register('renzu_motels:getTargetRoomsCount', function(src, motelName, targetId)
	local targetPlayer = GetPlayerFromId(tonumber(targetId)) or GetPlayerFromPid(tonumber(targetId))
	if not targetPlayer then return 0 end
	return GetPlayerRoomsInMotel(targetPlayer.identifier, motelName)
end)


lib.callback.register('renzu_motels:addemployee', function(src,motel,id)
	local xPlayer = GetPlayerFromId(src)
	local toPlayer = GetPlayerFromId(tonumber(id)) or GetPlayerFromPid(tonumber(id))
	if not ServerMotels[motel] then return false end
	local isOwner = ServerMotels[motel].owned == xPlayer.identifier
	local emp = ServerMotels[motel].employees and ServerMotels[motel].employees[xPlayer.identifier]
	local isManager = emp and type(emp) == 'table' and emp.grade == 3

	if (isOwner or isManager) and toPlayer then
		if not ServerMotels[motel].employees then ServerMotels[motel].employees = {} end
		ServerMotels[motel].employees[toPlayer.identifier] = {
			name = toPlayer.name,
			grade = 1
		}
		GlobalState.Motels = ServerMotels
		db.updateall('employees = ?', '`motel`', motel, json.encode(ServerMotels[motel].employees))
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:removeemployee', function(src,motel,identifier)
	local xPlayer = GetPlayerFromId(src)
	if not ServerMotels[motel] or not ServerMotels[motel].employees then return false end
	local isOwner = ServerMotels[motel].owned == xPlayer.identifier
	local emp = ServerMotels[motel].employees[xPlayer.identifier]
	local isManager = emp and type(emp) == 'table' and emp.grade == 3

	if isOwner then
		ServerMotels[motel].employees[identifier] = nil
		GlobalState.Motels = ServerMotels
		db.updateall('employees = ?', '`motel`', motel, json.encode(ServerMotels[motel].employees))
		return true
	elseif isManager then
		local targetEmp = ServerMotels[motel].employees[identifier]
		local targetGrade = 1
		if type(targetEmp) == 'table' then
			targetGrade = targetEmp.grade or 1
		end
		if targetGrade < 3 then
			ServerMotels[motel].employees[identifier] = nil
			GlobalState.Motels = ServerMotels
			db.updateall('employees = ?', '`motel`', motel, json.encode(ServerMotels[motel].employees))
			return true
		end
	end
	return false
end)

lib.callback.register('renzu_motels:promoteemployee', function(src, motel, targetIdentifier, newGrade)
	local xPlayer = GetPlayerFromId(src)
	if not ServerMotels[motel] or not ServerMotels[motel].employees then return false end
	local isOwner = ServerMotels[motel].owned == xPlayer.identifier
	local emp = ServerMotels[motel].employees[xPlayer.identifier]
	local isManager = emp and type(emp) == 'table' and emp.grade == 3

	local targetEmp = ServerMotels[motel].employees[targetIdentifier]
	if not targetEmp then return false end

	local targetName = type(targetEmp) == 'table' and targetEmp.name or targetEmp
	local currentGrade = type(targetEmp) == 'table' and targetEmp.grade or 1

	newGrade = tonumber(newGrade)
	if not newGrade or newGrade < 1 or newGrade > 3 then return false end

	if isOwner then
		-- Owner can promote anyone up to Manager (3)
		ServerMotels[motel].employees[targetIdentifier] = {
			name = targetName,
			grade = newGrade
		}
		GlobalState.Motels = ServerMotels
		db.updateall('employees = ?', '`motel`', motel, json.encode(ServerMotels[motel].employees))
		return true
	elseif isManager then
		-- Manager can only promote/demote up to Seller (2)
		-- They cannot touch Managers (3) or promote anyone to Manager (3)
		if currentGrade < 3 and newGrade < 3 then
			ServerMotels[motel].employees[targetIdentifier] = {
				name = targetName,
				grade = newGrade
			}
			GlobalState.Motels = ServerMotels
			db.updateall('employees = ?', '`motel`', motel, json.encode(ServerMotels[motel].employees))
			return true
		end
	end
	return false
end)

lib.callback.register('renzu_motels:transfermotel', function(src,motel,id)
	local xPlayer = GetPlayerFromId(src)
	local toPlayer = GetPlayerFromId(tonumber(id)) or GetPlayerFromPid(tonumber(id))
	if ServerMotels[motel] and ServerMotels[motel].owned == xPlayer.identifier and toPlayer then
		ServerMotels[motel].owned = toPlayer.identifier
		GlobalState.Motels = ServerMotels
		db.updateall('owned = ?', '`motel`', motel, ServerMotels[motel].owned)
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:sellmotel', function(src,data)
	local xPlayer = GetPlayerFromId(src)
	if ServerMotels[data.motel] and ServerMotels[data.motel].owned == xPlayer.identifier then
		ServerMotels[data.motel].owned = nil
		ServerMotels[data.motel].employees = {}
		GlobalState.Motels = ServerMotels
		xPlayer.addMoney(data.businessprice / 2)
		db.updateall('owned = ?, employees = ?', '`motel`', data.motel, 'NULL', '[]')
		return true
	end
	return false
end)

lib.callback.register('renzu_motels:withdrawfund', function(src,motel,amount)
	local xPlayer = GetPlayerFromId(src)
	if not ServerMotels[motel] then return false end
	local isOwner = ServerMotels[motel].owned == xPlayer.identifier
	local emp = ServerMotels[motel].employees and ServerMotels[motel].employees[xPlayer.identifier]
	local isManager = emp and type(emp) == 'table' and emp.grade == 3

	if isOwner or isManager then
		local curRevenue = ServerMotels[motel].revenue or 0
		if curRevenue < amount or amount < 0 then return false end
		ServerMotels[motel].revenue = curRevenue - amount
		GlobalState.Motels = ServerMotels
		db.updateall('revenue = ?', '`motel`', motel, ServerMotels[motel].revenue)
		xPlayer.addMoney(tonumber(amount))
		return true
	end
	return false
end)

-- =============================================
-- Tính năng phòng ngủ nhanh mặc định (Quick Sleep)
-- =============================================
lib.callback.register('renzu_motels:enterQuickSleep', function(src, motelName)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return false, 'no_player' end

	local motelCfg = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelName then
			motelCfg = v
			break
		end
	end

	if not motelCfg then return false, 'invalid_motel' end

	local quickCfg = motelCfg.quickSleep or config.quickSleep or {}
	if quickCfg.enabled == false then
		return false, 'disabled'
	end

	local price = tonumber(quickCfg.price) or 1500
	local paymentType = quickCfg.payment or 'money'
	local account = xPlayer.getAccount(paymentType)
	local currentMoney = account and account.money or 0

	if currentMoney < price then
		return false, 'not_enough_money'
	end

	-- Trừ tiền của người chơi
	xPlayer.removeAccountMoney(paymentType, price)

	-- 90% số tiền chuyển vào quỹ của khách sạn đó
	local hotelCutRatio = tonumber(quickCfg.hotelCut) or 0.90
	local hotelCutAmount = math.floor(price * hotelCutRatio)
	if ServerMotels[motelName] then
		ServerMotels[motelName].revenue = (ServerMotels[motelName].revenue or 0) + hotelCutAmount
		GlobalState.Motels = ServerMotels
		db.updateall('revenue = ?', '`motel`', motelName, ServerMotels[motelName].revenue)
	end

	-- Gửi log webhook
	local citizenid, pid, playerName = GetPlayerInfo(xPlayer.identifier)
	LogQuickSleep(motelName, playerName, pid, src, price, hotelCutAmount)

	return true, {
		motel = motelName,
		price = price,
		hotelCut = hotelCutAmount,
		shell = quickCfg.shell or motelCfg.shell or 'standard'
	}
end)

local routings = {}

lib.callback.register('renzu_motels:SetRouting', function(src,data,Type)
	if Type == 'enter' then
		routings[src] = GetPlayerRoutingBucket(src)
		
		-- Calculate trash since lastCleaned for this specific room (skip if quick sleep)
		if not data.isQuickSleep and tonumber(data.index) ~= 0 then
			local rooms = ServerMotels[data.motel] and ServerMotels[data.motel].rooms
			if rooms then
				local room = rooms[data.index] or rooms[tostring(data.index)] or rooms[tonumber(data.index)]
				if room then
					local curTime = os.time()
					if UpdateRoomTrash(room, curTime) then
						GlobalState.Motels = ServerMotels
						db.updateall('rooms = ?', '`motel`', data.motel, json.encode(ServerMotels[data.motel].rooms))
					end
				end
			end
		end

		local motelId = GetMotelUniqueId(data.motel)
		local bucket
		if data.isQuickSleep or tonumber(data.index) == 0 then
			-- Phòng ngủ nhanh: mỗi player có 1 bucket riêng biệt trong motel đó để ngủ riêng tư
			bucket = (motelId * 10000) + 5000 + (src % 1000)
		else
			local roomIndex = tonumber(data.index) or 1
			bucket = (motelId * 10000) + roomIndex
		end
		SetPlayerRoutingBucket(src, bucket)
	else
		SetPlayerRoutingBucket(src, 0)
		routings[src] = nil
	end
	return true
end)

-- Dọn dẹp routing bucket khi người chơi disconnect
AddEventHandler('playerDropped', function(reason)
	local src = source
	if routings[src] then
		routings[src] = nil
	end
end)

lib.callback.register('renzu_motels:cleanTrashPile', function(src, motel, roomIndex)
	local rooms = ServerMotels[motel] and ServerMotels[motel].rooms
	if rooms then
		local room = rooms[roomIndex] or rooms[tostring(roomIndex)] or rooms[tonumber(roomIndex)]
		if room then
			local currentTrash = room.trashCount or 0
			if currentTrash > 0 then
				room.trashCount = currentTrash - 1
				room.lastCleaned = os.time()
				if room.trashCount == 0 then
					GlobalState.Motels = ServerMotels
					db.updateall('rooms = ?', '`motel`', motel, json.encode(ServerMotels[motel].rooms))
					local xCleaner = GetPlayerFromId(src)
					LogCleanup(motel, roomIndex, xCleaner and xCleaner.name or 'Unknown', tostring(src))
				end
			end
			return room.trashCount == 0
		end
	end
	return false
end)

lib.callback.register('renzu_motels:autoCleanRoom', function(src, data)
	local motel = data.motel
	local roomIndex = tonumber(data.index or data.roomIndex)

	if not motel or not roomIndex or not ServerMotels[motel] or not ServerMotels[motel].rooms then
		return false, 'Phòng không tồn tại!'
	end

	local rooms = ServerMotels[motel].rooms
	local room = rooms[roomIndex] or rooms[tostring(roomIndex)] or rooms[tonumber(roomIndex)]
	if not room then
		return false, 'Không tìm thấy thông tin phòng!'
	end

	local trashCount = room.trashCount or 0
	if trashCount <= 0 then
		return false, 'Phòng đã sạch sẽ, không cần dọn dẹp!'
	end

	local pricePerPile = Config.cleanPricePerPile or 20
	local totalCost = trashCount * pricePerPile

	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then
		return false, 'Không tìm thấy thông tin người chơi!'
	end

	-- Kiểm tra quyền: Chủ khách sạn, nhân viên hoặc người đang thuê phòng
	local isOwner = ServerMotels[motel].owned == xPlayer.identifier
	local emp = ServerMotels[motel].employees and ServerMotels[motel].employees[xPlayer.identifier]
	local isEmployee = emp ~= nil
	local isTenant = room.players and room.players[xPlayer.identifier] ~= nil

	if not isOwner and not isEmployee and not isTenant then
		return false, 'Bạn không có quyền dọn dẹp phòng này!'
	end

	local motelRevenue = ServerMotels[motel].revenue or 0
	if motelRevenue < totalCost then
		return false, 'tiền quỹ khách sản này không có đủ để chi trả'
	end

	-- Trừ tiền từ quỹ của khách sạn
	ServerMotels[motel].revenue = motelRevenue - totalCost

	-- Cập nhật trạng thái phòng sạch
	room.trashCount = 0
	room.lastCleaned = os.time()

	GlobalState.Motels = ServerMotels

	db.updateall('rooms = ?, revenue = ?', '`motel`', motel, json.encode(ServerMotels[motel].rooms), ServerMotels[motel].revenue)

	LogCleanup(motel, roomIndex, xPlayer.name or 'Unknown', tostring(src))

	TriggerClientEvent('ox_lib:notify', src, {
		title = 'Dọn Dẹp',
		description = ('Đã dọn dẹp sạch phòng! Đã trừ $%s từ quỹ khách sạn.'):format(totalCost),
		type = 'success'
	})

	return true, totalCost
end)

lib.callback.register('renzu_motels:MessageOwner', function(src,data)
	if not ServerMotels[data.motel] or ServerMotels[data.motel].owned ~= data.identifier then return end
	local xPlayer = GetPlayerFromId(data.identifier)
	if xPlayer then
		TriggerClientEvent('renzu_motels:MessageOwner',xPlayer.source, data)
		return true
	end
	return false
end)

RegisterServerEvent("renzu_motels:Door")
AddEventHandler('renzu_motels:Door', function(data)
	local source = source
	TriggerClientEvent('renzu_motels:Door', -1, data)
	if not data.Mlo then
		if ServerMotels[data.motel] and ServerMotels[data.motel].rooms and ServerMotels[data.motel].rooms[data.index] then
			ServerMotels[data.motel].rooms[data.index].lock = not ServerMotels[data.motel].rooms[data.index].lock
			GlobalState.Motels = ServerMotels
		end
	end
end)

-- =============================================
-- Dùng item chuotdonhatro để lấy lại đồ bị tịch thu
-- Kiểm tra: đồ phải còn trong vòng 7 ngày
-- =============================================
local CONFISCATE_EXPIRE_DAYS = 7
local CONFISCATE_EXPIRE_SEC  = CONFISCATE_EXPIRE_DAYS * 86400

lib.callback.register('renzu_motels:claimConfiscated', function(src)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return false, 'error' end

	local identifier = xPlayer.identifier
	local rows = db.getConfiscated(identifier)
	local citizenid, pid, playerName = GetPlayerInfo(identifier)

	if not rows or #rows == 0 then
		if xPlayer.PlayerData and xPlayer.PlayerData.charinfo then
			local firstname = xPlayer.PlayerData.charinfo.firstname or ''
			local lastname = xPlayer.PlayerData.charinfo.lastname or ''
			playerName = firstname .. ' ' .. lastname
		end
		logger.log({
			source = src,
			event = 'motel_het_han',
			message = '[KHO TRỐNG] Tên: ' .. playerName .. ' | citizenid:' .. identifier .. ' pid:' .. pid .. ' | Cố gắng chuộc đồ nhưng không có đồ nào trong kho tịch thu.',
			webhook = nil
		})
		return false, 'noitems'
	end

	local now = os.time()
	local totalReturned = 0
	local validRows = {}
	local expiredRows = {}

	-- Phân loại rows còn hạn / hết hạn trước
	for _, row in ipairs(rows) do
		local age = now - (tonumber(row.confiscated_at) or 0)
		if age > CONFISCATE_EXPIRE_SEC then
			table.insert(expiredRows, row)
		else
			table.insert(validRows, row)
		end
	end

	-- Xóa các dòng hết hạn và ghi log chi tiết
	local pid = tostring(xPlayer.PlayerData and xPlayer.PlayerData.pid or '')
	local playerName = 'Unknown'
	if xPlayer.PlayerData and xPlayer.PlayerData.charinfo then
		local firstname = xPlayer.PlayerData.charinfo.firstname or ''
		local lastname = xPlayer.PlayerData.charinfo.lastname or ''
		playerName = firstname .. ' ' .. lastname
	end
	
	for _, row in ipairs(expiredRows) do
		-- Tính thời gian hết hạn chính xác
		local confiscatedAt = tonumber(row.confiscated_at) or 0
		local expireTime = confiscatedAt + CONFISCATE_EXPIRE_SEC
		local expireDateStr = os.date('%d/%m/%Y %H:%M', expireTime)
		
		-- Decode items để log chi tiết
		local itemList = {}
		local ok, items = pcall(json.decode, row.items)
		if ok and items then
			for _, item in ipairs(items) do
				if item.name and item.count and item.count > 0 then
					table.insert(itemList, item.name .. 'x' .. item.count)
				end
			end
		end
		local itemStr = #itemList > 0 and table.concat(itemList, ', ') or 'no items'
		
		-- Log xóa đồ hết hạn
		local motelName = GetMotelBlipLabel(row.motel)
		logger.log({
			source = src,
			event = 'motel_het_han',
			message = '[XÓA ĐỒ HẾT HẠN - SAU 7 NGÀY TỊCH THU] Tên: ' .. playerName .. ' | citizenid:' .. identifier .. ' pid:' .. pid .. ' | Địa chỉ: ' .. motelName .. ' | Phòng:' .. tostring(row.room) .. ' | Hết hạn: ' .. expireDateStr .. ' | Đồ bị xóa: ' .. itemStr,
			webhook = nil
		})
		
		db.deleteConfiscated(row.id)
	end

	if #validRows == 0 then
		-- Log: đồ hết hạn, không trả
		local pid = tostring(xPlayer.PlayerData and xPlayer.PlayerData.pid or '')
		local playerName = 'Unknown'
		if xPlayer.PlayerData and xPlayer.PlayerData.charinfo then
			local firstname = xPlayer.PlayerData.charinfo.firstname or ''
			local lastname = xPlayer.PlayerData.charinfo.lastname or ''
			playerName = firstname .. ' ' .. lastname
		end
		logger.log({
			source = src,
			event = 'motel_het_han',
			message = '[HẾT HẠN] Tên: ' .. playerName .. ' | ' .. identifier .. ' pid:' .. pid .. ' dùng chuotdonhatro nhưng đồ đã quá 7 ngày, bị tiêu hủy.',
			webhook = nil
		})
		return false, 'expired'
	end

	-- Xóa item chuotdonhatro TRƯỚC khi add đồ
	RemoveItem(src, 'chuotdonhatro', 1)

	-- Trả đồ về inventory player hoặc buucuc nếu không đủ chỗ
	local pid = tostring(xPlayer.PlayerData and xPlayer.PlayerData.pid or '')
	local playerName = 'Unknown'
	if xPlayer.PlayerData and xPlayer.PlayerData.charinfo then
		local firstname = xPlayer.PlayerData.charinfo.firstname or ''
		local lastname = xPlayer.PlayerData.charinfo.lastname or ''
		playerName = firstname .. ' ' .. lastname
	end
	
	-- Tạo stash buucuc cho player (nếu chưa có)
	local buucucStashId = 'buucuc_' .. identifier
	if GetResourceState('ox_inventory') == 'started' then
		exports.ox_inventory:RegisterStash(buucucStashId, 'Kho cá nhân', 500, 10000000)
	end
	
	local totalToBuucuc = 0
	
	for _, row in ipairs(validRows) do
		local ok, items = pcall(json.decode, row.items)
		if ok and items then
			local itemsToInventory = {}
			local itemsToBuucuc = {}
			
			for _, item in pairs(items) do
				if type(item) == 'table' and item.name and item.count and item.count > 0 then
					-- Kiểm tra xem player có thể mang item này không
					local canCarry = exports.ox_inventory:CanCarryItem(src, item.name, item.count, item.metadata or {})
					
					if canCarry then
						-- Thêm vào inventory player
						AddItem(src, item.name, item.count, item.metadata or {})
						totalReturned = totalReturned + item.count
						
						local meta = ''
						if item.metadata and next(item.metadata) then
							meta = ' [meta:' .. json.encode(item.metadata) .. ']'
						end
						table.insert(itemsToInventory, item.name .. 'x' .. item.count .. meta)
					else
						-- Không đủ chỗ, thêm vào buucuc stash
						if GetResourceState('ox_inventory') == 'started' then
							local added = exports.ox_inventory:AddItem(buucucStashId, item.name, item.count, item.metadata or {})
							if not added then
								print('[LỖI CHUỘC ĐỒ] Không thể AddItem vào bưu cục stash:', buucucStashId, 'Item:', item.name, 'Count:', item.count)
							end
							totalReturned = totalReturned + item.count
							totalToBuucuc = totalToBuucuc + item.count
							
							local meta = ''
							if item.metadata and next(item.metadata) then
								meta = ' [meta:' .. json.encode(item.metadata) .. ']'
							end
							table.insert(itemsToBuucuc, item.name .. 'x' .. item.count .. meta)
						end
					end
				end
			end
			
			-- Log chi tiết
			local motelName = GetMotelBlipLabel(row.motel)
			local logMessage = '[CHUỘC ĐỒ] Tên: ' .. playerName .. ' | citizenid:' .. identifier .. ' pid:' .. pid .. ' | Địa chỉ: ' .. motelName .. ' | Phòng:' .. tostring(row.room)
			
			if #itemsToInventory > 0 then
				logMessage = logMessage .. ' | Nhận vào túi: ' .. table.concat(itemsToInventory, ', ')
			end
			
			if #itemsToBuucuc > 0 then
				logMessage = logMessage .. ' | Gửi vào Bưu cục (không đủ chỗ): ' .. table.concat(itemsToBuucuc, ', ')
			end
			
			logger.log({
				source = src,
				event = 'motel_het_han',
				message = logMessage,
				webhook = nil
			})
		end
		db.deleteConfiscated(row.id)
	end

	return true, totalReturned, totalToBuucuc
end)

-- =============================================
-- Callback: renewRoom (for new UI)
-- Gia hạn phòng hiện tại của player
-- =============================================
lib.callback.register('renzu_motels:renewRoom', function(src, data)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return false end
	
	local identifier = xPlayer.identifier
	local motel = data.motel
	local index = data.index
	local days = data.days or 1
	local amount = data.amount or 0
	
	-- Kiểm tra nếu khu trọ đã có chủ
	local motelOwner = ServerMotels[motel] and ServerMotels[motel].owned
	if motelOwner and motelOwner ~= "" and motelOwner ~= 0 and motelOwner ~= "0" then
		return false, 'Khu trọ đã có chủ, bạn không thể tự gia hạn!'
	end

	-- Kiểm tra player có phòng này không
	if not ServerMotels[motel] or not ServerMotels[motel].rooms or not ServerMotels[motel].rooms[index] then
		return false
	end
	
	if not ServerMotels[motel].rooms[index].players or not ServerMotels[motel].rooms[index].players[identifier] then
		return false -- Player không có phòng này
	end
	
	local roomPlayer = ServerMotels[motel].rooms[index].players[identifier]
	local baseRate = ServerMotels[motel].hour_rate or 5000
	for _, mConfig in pairs(Config.motels) do
		if mConfig.motel == motel then
			baseRate = ServerMotels[motel].hour_rate or mConfig.rate or 5000
			break
		end
	end
	
	if roomPlayer.additional then
		local premium = ServerMotels[motel].additional_premium or 10
		baseRate = math.ceil(baseRate * (1 + premium / 100))
	end
	local amount = days * baseRate
	
	-- Kiểm tra tiền
	local money = xPlayer.getAccount('money').money
	if money < amount then
		return false, 'Không đủ tiền để gia hạn!'
	end
	
	-- Tính thời gian gia hạn (days * rental_period['day'])
	local addTime = days * rental_period['day']
	local currentDuration = ServerMotels[motel].rooms[index].players[identifier].duration or os.time()
	local newDuration = currentDuration + addTime
	
	-- Kiểm tra giới hạn ngày thuê tối đa theo ngày kết thúc
	if Config.dayrent and Config.dayrent ~= "" then
		local day, month, year = string.match(Config.dayrent, "(%d+)/(%d+)/(%d+)")
		if day and month and year then
			local limitTime = os.time({
				day = tonumber(day),
				month = tonumber(month),
				year = tonumber(year),
				hour = 23,
				min = 59,
				sec = 59
			})
			if newDuration > limitTime then
				return false, 'Vượt quá giới hạn ngày thuê cho phép!'
			end
		end
	end

	-- Trừ tiền và gia hạn
	xPlayer.removeAccountMoney('money', amount)
	ServerMotels[motel].rooms[index].players[identifier].duration = newDuration
	ServerMotels[motel].revenue = (ServerMotels[motel].revenue or 0) + amount
	
	-- Cập nhật GlobalState và database
	GlobalState.Motels = ServerMotels
	db.updateall('rooms = ?, revenue = ?', '`motel`', motel, json.encode(ServerMotels[motel].rooms), ServerMotels[motel].revenue)
	
	return true
end)

-- Callback: ownerRenewRoom (for owners/employees to renew occupants)
lib.callback.register('renzu_motels:ownerRenewRoom', function(src, data)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return false, 'Không tìm thấy người chơi!' end
	
	local motel = data.motel
	local index = data.index
	local days = data.days or 1
	
	if not ServerMotels[motel] or not ServerMotels[motel].rooms or not ServerMotels[motel].rooms[index] then
		return false, 'Không tìm thấy phòng!'
	end
	
	-- Kiểm tra quyền (chủ trọ hoặc nhân viên grade >= 2)
	local isOwner = ServerMotels[motel].owned == xPlayer.identifier
	local emp = ServerMotels[motel].employees and ServerMotels[motel].employees[xPlayer.identifier]
	local isEmployee = emp and type(emp) == 'table' and (emp.grade or 1) >= 2
	if not isOwner and not isEmployee then
		return false, 'Bạn không có quyền quản lý khu trọ này!'
	end
	
	-- Lấy occupant hiện tại
	local room = ServerMotels[motel].rooms[index]
	local occupantIdentifier = nil
	local occupantData = nil
	for id, ply in pairs(room.players or {}) do
		if ply.duration and ply.duration > os.time() then
			occupantIdentifier = id
			occupantData = ply
			break
		end
	end
	
	if not occupantIdentifier or not occupantData then
		return false, 'Phòng trống, không thể gia hạn!'
	end
	
	-- Tính thời gian gia hạn (days * rental_period['day'])
	local addTime = days * rental_period['day']
	local newDuration = occupantData.duration + addTime
	
	-- Kiểm tra giới hạn ngày thuê tối đa theo ngày kết thúc
	if Config.dayrent and Config.dayrent ~= "" then
		local day, month, year = string.match(Config.dayrent, "(%d+)/(%d+)/(%d+)")
		if day and month and year then
			local limitTime = os.time({
				day = tonumber(day),
				month = tonumber(month),
				year = tonumber(year),
				hour = 23,
				min = 59,
				sec = 59
			})
			if newDuration > limitTime then
				return false, 'Vượt quá giới hạn ngày thuê cho phép!'
			end
		end
	end
	
	-- Kiểm tra người thuê (chủ phòng) có online và đứng trong phạm vi 5.0m không
	local toPlayer = nil
	if exports.qbx_core and exports.qbx_core.GetPlayerByCitizenId then
		local qbxP = exports.qbx_core:GetPlayerByCitizenId(occupantIdentifier)
		if qbxP and qbxP.PlayerData and qbxP.PlayerData.source then
			toPlayer = GetPlayerFromId(qbxP.PlayerData.source)
		end
	end
	if not toPlayer and QBCORE then
		local qbP = QBCORE.Functions.GetPlayerByCitizenId(occupantIdentifier)
		if qbP and qbP.PlayerData and qbP.PlayerData.source then
			toPlayer = GetPlayerFromId(qbP.PlayerData.source)
		end
	elseif not toPlayer and ESX then
		toPlayer = ESX.GetPlayerFromIdentifier(occupantIdentifier)
	end
	
	if not toPlayer then
		return false, 'Chủ phòng hiện không online!'
	end

	local targetSource = toPlayer.PlayerData and toPlayer.PlayerData.source or toPlayer.source
	local managerPed = GetPlayerPed(src)
	local targetPed = GetPlayerPed(targetSource)
	if not targetPed or targetPed == 0 then
		return false, 'Không tìm thấy vị trí chủ phòng!'
	end

	local dist = #(GetEntityCoords(managerPed) - GetEntityCoords(targetPed))
	if dist > 5.0 then
		return false, 'Chủ phòng phải đứng gần bạn trong phạm vi 5.0m để gia hạn!'
	end
	
	local customRate = tonumber(data.customRate)
	local defaultRate = ServerMotels[motel].hour_rate or data.rate or 5000
	local rate = customRate or defaultRate
	if rate < defaultRate then
		rate = defaultRate
	end
	local limit = Config.maxDailyRent or 10000
	if rate > limit then
		rate = limit
	end
	if occupantData.additional then
		local premium = ServerMotels[motel].additional_premium or 10
		rate = math.ceil(rate * (1 + premium / 100))
	end
	local amount = days * rate
	local targetSource = toPlayer.PlayerData and toPlayer.PlayerData.source or toPlayer.source
	
	-- Hỏi người chơi xác nhận thanh toán gia hạn
	local accepted = lib.callback.await('renzu_motels:confirmoccupant', targetSource, {
		motel = motel,
		index = index,
		duration = days,
		rate = rate,
		amount = amount,
		rental_period = 'day',
		payment = 'money'
	}, 30000)
	
	if not accepted then
		return false, 'Người chơi từ chối yêu cầu gia hạn!'
	end
	
	-- Kiểm tra tiền
	local money = toPlayer.getAccount('money').money
	if money < amount then
		return false, 'Người chơi không đủ tiền thanh toán!'
	end
	
	-- Trừ tiền của người chơi
	toPlayer.removeAccountMoney('money', amount)
	
	-- Thêm tiền vào doanh thu khu trọ
	ServerMotels[motel].revenue = (ServerMotels[motel].revenue or 0) + amount
	
	-- Cập nhật thời hạn phòng
	ServerMotels[motel].rooms[index].players[occupantIdentifier].duration = newDuration
	GlobalState.Motels = ServerMotels
	db.updateall('rooms = ?, revenue = ?', '`motel`', motel, json.encode(ServerMotels[motel].rooms), ServerMotels[motel].revenue)
	
	return true
end)

-- Callback to resolve character names of nearby players
lib.callback.register('renzu_motels:getNearbyNames', function(src, list)
	local resolved = {}
	for _, p in ipairs(list) do
		local targetPlayer = GetPlayerFromId(p.id)
		local name = 'Người chơi #' .. p.id
		if targetPlayer then
			if targetPlayer.PlayerData and targetPlayer.PlayerData.charinfo then
				local charinfo = targetPlayer.PlayerData.charinfo
				name = charinfo.firstname .. ' ' .. charinfo.lastname .. ' (' .. p.id .. ')'
			else
				name = targetPlayer.name .. ' (' .. p.id .. ')'
			end
		end
		table.insert(resolved, { id = p.id, name = name, dist = p.dist })
	end
	return resolved
end)

-- =============================================
-- Callback: rentRoom (for new UI)
-- Thuê phòng mới từ UI
-- =============================================
lib.callback.register('renzu_motels:rentRoom', function(src, data)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return false end
	
	local identifier = xPlayer.identifier
	local motel = data.motel
	local index = data.index
	local days = data.days or 1
	local amount = data.amount or 0
	local payment = data.payment or 'money'
	
	-- Kiểm tra giới hạn số ngày thuê tối đa theo ngày kết thúc
	local maxRentDays = Config.GetMaxRentDays(os.time())
	if days > maxRentDays then
		return 'limit'
	end
	
	-- Kiểm tra nếu khu trọ đã có chủ
	local motelOwner = ServerMotels[motel] and ServerMotels[motel].owned
	if motelOwner and motelOwner ~= "" and motelOwner ~= 0 and motelOwner ~= "0" then
		return 'owned'
	end

	-- Kiểm tra player đã có phòng chưa (tối đa 3 phòng tại khu trọ này)
	local roomsCount = GetPlayerRoomsInMotel(identifier, motel)
	if roomsCount >= 3 then
		return 'hasroom'
	end
	
	-- Kiểm tra phòng có tồn tại không
	if not ServerMotels[motel] or not ServerMotels[motel].rooms or not ServerMotels[motel].rooms[index] then
		return false
	end
	
	-- Kiểm tra phòng đã có người thuê chưa
	if ServerMotels[motel].rooms[index].players and ServerMotels[motel].rooms[index].players[identifier] then
		return 'exist' -- Phòng đã được thuê
	end
	
	-- Kiểm tra có người khác đang thuê không
	for otherIdentifier, playerData in pairs(ServerMotels[motel].rooms[index].players or {}) do
		if playerData.duration and playerData.duration > os.time() then
			return 'exist' -- Phòng đã có người thuê
		end
	end
	
	-- Lấy tiền phòng và tính toán 10% nếu thuê phòng thứ 2 trở lên
	local baseRate = ServerMotels[motel].hour_rate or 5000
	for _, mConfig in pairs(Config.motels) do
		if mConfig.motel == motel then
			baseRate = ServerMotels[motel].hour_rate or mConfig.rate or 5000
			break
		end
	end
	
	local isAdditional = false
	if roomsCount >= 1 then
		isAdditional = true
		local premium = ServerMotels[motel].additional_premium or 10
		baseRate = math.ceil(baseRate * (1 + premium / 100))
	end
	local amount = days * baseRate
	
	-- Kiểm tra tiền
	local money = xPlayer.getAccount(payment).money
	if money < amount then
		return 'nomoney'
	end
	
	-- Trừ tiền và thuê phòng
	xPlayer.removeAccountMoney(payment, amount)
	
	if not ServerMotels[motel].rooms[index].players then
		ServerMotels[motel].rooms[index].players = {}
	end
	
	-- Tính thời gian thuê
	local duration = days * rental_period['day']
	ServerMotels[motel].rooms[index].players[identifier] = {
		name = xPlayer.name,
		duration = os.time() + duration,
		additional = isAdditional
	}
	
	-- Reset rác và mốc thời gian dọn khi bắt đầu thuê phòng
	ServerMotels[motel].rooms[index].trashCount = 0
	ServerMotels[motel].rooms[index].lastCleaned = os.time()

	ServerMotels[motel].revenue = (ServerMotels[motel].revenue or 0) + amount
	
	-- Cập nhật GlobalState và database
	GlobalState.Motels = ServerMotels
	db.updateall('rooms = ?, revenue = ?', '`motel`', motel, json.encode(ServerMotels[motel].rooms), ServerMotels[motel].revenue)
	
	-- Đăng ký stash nếu dùng ox_inventory
	if GetResourceState('ox_inventory') == 'started' then
		local uniquestash = data.uniquestash or false
		local stashid = uniquestash and identifier or 'room'
		
		-- Find motel config
		local motelConfig = nil
		for k, v in pairs(config.motels) do
			if v.motel == motel then
				motelConfig = v
				break
			end
		end
		
		local stashConfig = motelConfig and motelConfig.stash or config.defaultStash
		local fridgeConfig = motelConfig and motelConfig.fridge or config.defaultFridge
		
		exports.ox_inventory:RegisterStash('stash_'..motel..'_'..stashid..'_'..index, 'Storage', stashConfig.slots, stashConfig.weight, false)
		exports.ox_inventory:RegisterStash('fridge_'..motel..'_'..stashid..'_'..index, 'Fridge', fridgeConfig.slots, fridgeConfig.weight, false)
	end
	
	return true
end)

-- =============================================
-- Checkout Room (Trả Phòng)
-- =============================================
lib.callback.register('renzu_motels:checkoutRoom', function(src, motel, index)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then 
		return false 
	end
	
	local identifier = xPlayer.identifier
	
	if not ServerMotels or not ServerMotels[motel] or not ServerMotels[motel].rooms or not ServerMotels[motel].rooms[index] then
		return false
	end
	
	local room = ServerMotels[motel].rooms[index]
	
	-- Kiểm tra xem người chơi có quyền trả phòng này không
	if not room.players or not room.players[identifier] then
		return false
	end

	-- Hoàn tiền nếu returnmoney = true và còn thời gian thuê
	local motelConfig = nil
	for _, m in pairs(config.motels) do
		if m.motel == motel then motelConfig = m break end
	end

	if motelConfig and motelConfig.returnmoney == true then
		local playerData = room.players[identifier]
		if playerData and playerData.duration and playerData.duration > os.time() then
			local timeLeft = playerData.duration - os.time()
			local isDailyOrMonthly = (motelConfig.rental_period == 'day' or motelConfig.rental_period == 'month')

			if isDailyOrMonthly or timeLeft >= 86400 then
				local baseRate = ServerMotels[motel].hour_rate or motelConfig.rate or 5000
				if playerData.additional then
					local premium = ServerMotels[motel].additional_premium or 10
					baseRate = math.ceil(baseRate * (1 + premium / 100))
				end

				local periodSeconds = rental_period[motelConfig.rental_period] or 86400
				local refundAmount = math.floor((timeLeft / periodSeconds) * baseRate)

				if refundAmount > 0 then
					xPlayer.addMoney(refundAmount)
					TriggerClientEvent('renzu_motels:notify', src, 'Bạn đã được hoàn lại $'..refundAmount..' tiền thuê phòng còn lại.', 'success')
					-- Trừ từ doanh thu của khu nhà trọ
					ServerMotels[motel].revenue = math.max(0, (ServerMotels[motel].revenue or 0) - refundAmount)
				end
			end
		end
	end

	-- Tịch thu đồ nếu có config (truyền isCheckout = true)
	if config.confiscateOnExpire then
		ConfiscateRoomItems(motel, index, identifier, nil, 'checkout')
	end
	
	-- Xóa người chơi khỏi phòng (update trực tiếp vào motels table)
	ServerMotels[motel].rooms[index].players[identifier] = nil
	
	-- Nếu không còn ai thuê thì reset phòng
	local hasPlayers = false
	for _ in pairs(ServerMotels[motel].rooms[index].players or {}) do
		hasPlayers = true
		break
	end
	
	if not hasPlayers then
		ServerMotels[motel].rooms[index].players = nil
	end
	
	-- Cập nhật GlobalState và database
	GlobalState.Motels = ServerMotels
	db.updateall('rooms = ?, revenue = ?', '`motel`', motel, json.encode(ServerMotels[motel].rooms), ServerMotels[motel].revenue or 0)
	
	return true
end)

-- =============================================
-- motel_ped: Lưu / lấy / xóa ped tùy chỉnh
-- =============================================
lib.callback.register('renzu_motels:getPed', function(src)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return nil end
	return db.getPed(xPlayer.identifier)
end)

RegisterNetEvent('renzu_motels:savePed', true)
AddEventHandler('renzu_motels:savePed', function(data)
	local src = source
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer or not data or not data.ped_model then return end
	db.savePed(xPlayer.identifier, data.ped_model, data.components or {}, data.textures or {})
end)

RegisterNetEvent('renzu_motels:resetPed', true)
AddEventHandler('renzu_motels:resetPed', function()
	local src = source
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return end
	db.deletePed(xPlayer.identifier)
end)

-- Lấy appearance mặc định từ playerskins (freemode model)
lib.callback.register('renzu_motels:getDefaultAppearance', function(src)
	local xPlayer = GetPlayerFromId(src)
	if not xPlayer then return nil end
	local citizenid = xPlayer.identifier

	-- Xác định giới tính từ charinfo trước (0 = nam, 1 = nữ)
	local gender = xPlayer.PlayerData and xPlayer.PlayerData.charinfo and xPlayer.PlayerData.charinfo.gender
	local freemodeModel = (gender == 1) and 'mp_f_freemode_01' or 'mp_m_freemode_01'

	-- Ưu tiên lấy row freemode đúng giới tính + active
	local row = MySQL.single.await(
		"SELECT model, skin FROM playerskins WHERE citizenid = ? AND model = ? AND active = 1 LIMIT 1",
		{ citizenid, freemodeModel }
	)

	if row then return row end

	-- Không có row active → lấy row freemode đúng giới tính bất kỳ
	row = MySQL.single.await(
		"SELECT model, skin FROM playerskins WHERE citizenid = ? AND model = ? ORDER BY id DESC LIMIT 1",
		{ citizenid, freemodeModel }
	)

	if row then return row end

	-- Vẫn không có → trả model rỗng để client tự dùng đúng freemode theo giới tính
	return { model = freemodeModel, skin = nil }
end)

-- =============================================
-- Admin command: setped <pid> <ped_model>
-- Gán ped tùy chỉnh cho player (không có trang phục cụ thể)
-- =============================================
lib.addCommand('setped', {
	help = 'Gán ped model cho player (admin)',
	params = {
		{ name = 'target', type = 'number', help = 'PID của player' },
		{ name = 'ped_model', type = 'string', help = 'Tên model ped (vd: pedm_kien)' },
	},
	restricted = 'group.admin',
}, function(source, args)
	local toPlayer = exports.qbx_core:GetPlayerByPid(args.target)
	if not toPlayer then
		return lib.notify(source, { description = 'Không tìm thấy player với PID ' .. args.target, type = 'error' })
	end

	local citizenid = toPlayer.PlayerData.citizenid
	local playerName = (toPlayer.PlayerData.charinfo and (toPlayer.PlayerData.charinfo.firstname .. ' ' .. toPlayer.PlayerData.charinfo.lastname)) or toPlayer.PlayerData.name or citizenid

	-- Lưu với components mặc định (toàn 0)
	local comps, texs = {}, {}
	for i = 0, 11 do comps[i] = 0 ; texs[i] = 0 end

	db.savePed(citizenid, args.ped_model, comps, texs)

	-- Thông báo cho admin
	lib.notify(source, {
		description = ('Đã gán ped "%s" cho %s (cid: %s)'):format(args.ped_model, playerName, citizenid),
		type = 'success'
	})

	-- Thông báo cho player và áp dụng ngay trên client
	TriggerClientEvent('renzu_motels:applyPed', toPlayer.PlayerData.source, args.ped_model, comps, texs)
end)

-- =============================================
-- Admin command: resetped <pid>
-- Xóa ped tùy chỉnh của player về mặc định
-- =============================================
lib.addCommand('resetped', {
	help = 'Xóa ped tùy chỉnh của player (admin)',
	params = {
		{ name = 'target', type = 'number', help = 'PID của player' },
	},
	restricted = 'group.admin',
}, function(source, args)
	local toPlayer = exports.qbx_core:GetPlayerByPid(args.target)
	if not toPlayer then
		return lib.notify(source, { description = 'Không tìm thấy player với PID ' .. args.target, type = 'error' })
	end

	local citizenid = toPlayer.PlayerData.citizenid
	local playerName = (toPlayer.PlayerData.charinfo and (toPlayer.PlayerData.charinfo.firstname .. ' ' .. toPlayer.PlayerData.charinfo.lastname)) or toPlayer.PlayerData.name or citizenid

	db.deletePed(citizenid)

	lib.notify(source, {
		description = ('Đã xóa ped tùy chỉnh của %s (cid: %s)'):format(playerName, citizenid),
		type = 'success'
	})

	TriggerClientEvent('renzu_motels:notify', toPlayer.PlayerData.source, 'Admin đã đặt lại ped của bạn về mặc định. Vui lòng reconnect.', 'inform')
end)

-- Command to set a room in pinkcages_motels to dirty for testing/demo
RegisterCommand('dirtyroom', function(source, args, rawCommand)
	local src = source
	local roomIndex = tonumber(args[1]) or 1
	local trashAmount = tonumber(args[2]) or 6
	
	local motelName = 'pinkcages_motels'
	local rooms = ServerMotels[motelName] and ServerMotels[motelName].rooms
	local room = rooms and (rooms[roomIndex] or rooms[tostring(roomIndex)] or rooms[tonumber(roomIndex)])
	if room then
		room.trashCount = trashAmount
		-- Set last cleaned based on 6-hour dirt cycle
		room.lastCleaned = os.time() - 21600
		
		GlobalState.Motels = ServerMotels
		db.updateall('rooms = ?', '`motel`', motelName, json.encode(ServerMotels[motelName].rooms))
		
		if src > 0 then
			TriggerClientEvent('ox_lib:notify', src, {
				title = 'Test System',
				description = 'Đã đặt Phòng #' .. roomIndex .. ' của PinkCage thành BẨN (' .. trashAmount .. ' rác)!',
				type = 'success'
			})
		else
			print('Set room #' .. roomIndex .. ' of pinkcages_motels to dirty with ' .. trashAmount .. ' trash.')
		end
	else
		if src > 0 then
			TriggerClientEvent('ox_lib:notify', src, {
				title = 'Test System',
				description = 'Phòng không tồn tại!',
				type = 'error'
			})
		else
			print('Room #' .. roomIndex .. ' of pinkcages_motels does not exist!')
		end
	end
end, false)