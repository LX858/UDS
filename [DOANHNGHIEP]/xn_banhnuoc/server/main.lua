local swapHook, buyHook

-- Debug function
local function debugPrint(...)
    if Config.debug then
        print(...)
    end
end

-- Lưu trữ các giao dịch đang chờ xác nhận (bán trực tiếp)
local pendingTransactions = {}

-- Lưu trữ đơn hàng theo shop
local shopOrders = {}
local orderIdCounter = 0

-- Function lấy số lượng item trong stash
local function GetStashItemCount(stashId, itemName)
    local items = exports.ox_inventory:GetInventoryItems(stashId, false)
    if not items then return 0 end
    
    local count = 0
    for _, item in pairs(items) do
        if item.name == itemName then
            count = count + item.count
        end
    end
    return count
end

-- Lưu trữ giá tùy chỉnh theo shop (shopKey -> itemName -> price)
customShopPrices = {}

-- Load giá tùy chỉnh từ database
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `xn_banhnuoc_prices` (
            `shop_key`  VARCHAR(50) NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `price`     INT         NOT NULL DEFAULT 0,
            PRIMARY KEY (`shop_key`, `item_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local results = MySQL.query.await("SELECT * FROM `xn_banhnuoc_prices`")
    if results then
        for _, row in ipairs(results) do
            if not customShopPrices[row.shop_key] then
                customShopPrices[row.shop_key] = {}
            end
            customShopPrices[row.shop_key][row.item_name] = row.price
        end
        print(string.format("[xn_banhnuoc] Đã tải %d giá tùy chỉnh cho các shop.", #results))
    end
end)

-- Kiểm tra item có phải là item cho phép custom giá hay không
function IsItemCustomPrice(shopKey, itemName)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig or not shopConfig.items then return false end
    local itemCfg = shopConfig.items[itemName]
    if itemCfg == 'custom' or itemCfg == true then
        return true
    elseif type(itemCfg) == 'table' and (itemCfg.custom == true or itemCfg.isCustom == true) then
        return true
    end
    return false
end

-- Kiểm tra player có đủ cấp bậc (grade) để chỉnh giá custom hay không
function CanPlayerManagePrices(source, shopKey)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return false end
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    if player.PlayerData.job.name ~= shopConfig.job or not player.PlayerData.job.onduty then
        return false
    end
    local grade = player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0
    local minGrade = shopConfig.customPriceMinGrade or (Config.GlobalSettings and Config.GlobalSettings.defaultCustomPriceMinGrade) or 4
    return grade >= minGrade
end

-- Function lấy giá item (nếu là custom thì lấy từ database/cache, nếu cố định thì lấy từ config)
function GetItemPrice(shopKey, itemName)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig or not shopConfig.items then return nil end
    local itemCfg = shopConfig.items[itemName]
    if itemCfg == nil then return nil end

    -- Nếu item được đánh dấu là custom
    if IsItemCustomPrice(shopKey, itemName) then
        if customShopPrices[shopKey] and customShopPrices[shopKey][itemName] ~= nil then
            return customShopPrices[shopKey][itemName]
        end
        if type(itemCfg) == 'table' and itemCfg.price then
            return itemCfg.price
        end
        return 0
    end

    -- Item có giá cố định
    if type(itemCfg) == 'table' then
        return itemCfg.price or 0
    elseif type(itemCfg) == 'number' then
        return itemCfg
    end
    return 0
end

-- Function lấy danh sách tất cả items và giá của shop
function GetAllShopItems(shopKey)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig or not shopConfig.items then return {} end
    local itemsMap = {}
    for k, _ in pairs(shopConfig.items) do
        local price = GetItemPrice(shopKey, k) or 0
        itemsMap[k] = price
    end
    return itemsMap
end

-- Cache nhân viên đang on-duty: tránh døýệt toàn bộ players mỗi request
local _employeeCache    = {}   -- { [jobName] = { ids={}, ts=unix } }
local EMPLOYEE_CACHE_TTL = 2   -- giây; thoải mái tăng nếu server ít thay đổi duty

-- Invalidate cache khi có thay đổi duty (player thoát, duty toggle)
AddEventHandler('playerDropped', function()
    _employeeCache = {}
end)

-- Invalidate khi nhân viên đổi duty/job (QBX event)
AddEventHandler('QBCore:Server:OnJobUpdate', function()
    _employeeCache = {}
end)

-- Function lấy tất cả nhân viên online của shop (global để npc.lua dùng được)
function GetOnlineEmployees(jobName)
    local now    = os.time()
    local cached = _employeeCache[jobName]
    if cached and (now - cached.ts) < EMPLOYEE_CACHE_TTL then
        return cached.ids
    end

    local employees = {}
    local players   = exports.qbx_core:GetQBPlayers()
    if players then
        for playerId, player in pairs(players) do
            if player.PlayerData.job.name == jobName and player.PlayerData.job.onduty then
                employees[#employees + 1] = playerId
            end
        end
    end

    _employeeCache[jobName] = { ids = employees, ts = now }
    return employees
end

-- Function gửi thông báo cho tất cả nhân viên
local function NotifyAllEmployees(shopKey, eventName, data)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    local employees = GetOnlineEmployees(shopConfig.job)
    for _, employeeId in ipairs(employees) do
        TriggerClientEvent(eventName, employeeId, data)
    end
end

-- Function tạo order ID
local function GenerateOrderId()
    orderIdCounter = orderIdCounter + 1
    return orderIdCounter
end

-- Khởi tạo orders cho mỗi shop
for shopKey, _ in pairs(Config.Shops) do
    shopOrders[shopKey] = {}
end

function IsJobEmployeeOnDuty(jobName)
    local count = GlobalState[jobName .. '_count'] or 0
    if not count or count == 0 then
        return false, nil
    end

    -- Có nhân viên → lấy tên qua cache (vốn đã warm từ GetOnlineEmployees)
    local employees = GetOnlineEmployees(jobName)
    if employees and employees[1] then
        local player = exports.qbx_core:GetPlayer(employees[1])
        if player then
            local name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            return true, name
        end
    end
    return true, 'Nhân viên'
end

-- Event nhận yêu cầu kiểm tra nhân viên online
RegisterNetEvent('rep_shop:server:checkJobEmployee', function(jobName)
	local source = source
	debugPrint("DEBUG: Kiểm tra job", jobName, "cho player", source)
	
	local isOnline, employeeCount = IsJobEmployeeOnDuty(jobName)
	
	debugPrint("DEBUG: Kết quả - isOnline:", isOnline, "employeeCount:", employeeCount)
	
	TriggerClientEvent('rep_shop:client:jobEmployeeResult', source, isOnline, employeeCount, jobName)
end)

-- Khởi tạo shops với delay nhỏ
SetTimeout(100, function()
	for k, v in pairs(Config.Shops) do
		-- Đăng ký kho lưu trữ chính (main stash)
		local stashMinGrade = v.stash_config and v.stash_config.minGrade or 0
		local stash = {
			id = k,
			label = _(v.label),
			slots = v.stash_config and v.stash_config.slots or 50,
			weight = v.stash_config and v.stash_config.weight or 100000,
		}
		exports.ox_inventory:RegisterStash(stash.id, stash.label, stash.slots, stash.weight, nil, { [v.job] = stashMinGrade })
		debugPrint(_('debug_stash_config', k, stash.slots, stash.weight/1000))

		-- Đăng ký kho bán hàng (stash_sell)
		local sellStashMinGrade = v.stash_sell_config and v.stash_sell_config.minGrade or 0
		local sellStashId = k .. '_sell'
		local sellStash = {
			id = sellStashId,
			label = _(v.label) .. ' (Bán)',
			slots = v.stash_sell_config and v.stash_sell_config.slots or 5,
			weight = v.stash_sell_config and v.stash_sell_config.weight or 100000,
		}
		exports.ox_inventory:RegisterStash(sellStash.id, sellStash.label, sellStash.slots, sellStash.weight, nil, { [v.job] = sellStashMinGrade })
		debugPrint(_('debug_stash_config', sellStashId, sellStash.slots, sellStash.weight/1000))

		-- Khởi tạo shop từ kho bán hàng
		local items = exports.ox_inventory:GetInventoryItems(sellStashId, false)
		local stashItems = {}
		if items and items ~= {} then
			for _, v2 in pairs(items) do
				if v2 and v2.name then
					local price = 0
					-- Kiểm tra metadata và shopData tồn tại trước khi truy cập
					if v2.metadata and v2.metadata.shopData and v2.metadata.shopData.price then
						price = v2.metadata.shopData.price
					end
					stashItems[#stashItems + 1] = { name = v2.name, metadata = v2.metadata, count = v2.count, price = price }
				end
			end

			exports.ox_inventory:RegisterShop(sellStashId, {
				name = _(v.label),
				inventory = stashItems,
				locations = {
					vec3(0,0,0),
				}
			})
		end
	end
	
	-- Đăng ký hook một lần cho tất cả shops
	swapHook = exports.ox_inventory:registerHook('swapItems', function(payload)
		debugPrint("DEBUG: Full payload =", json.encode(payload))

		-- Helper: tìm shop config theo inventory ID (hỗ trợ cả main stash và stash_sell)
		local function GetShopForInventory(invId)
			if Config.Shops[invId] then
				return Config.Shops[invId], invId, false -- shopConfig, shopKey, isSell
			end
			local key = tostring(invId):match('^(.+)_sell$')
			if key and Config.Shops[key] then
				return Config.Shops[key], key, true
			end
			return nil, nil, false
		end

		-- Helper: kiểm tra người chơi có quyền lấy đồ ra khỏi kho hay không
		local function CanPlayerWithdrawFromStash(src, shopConfig, isSell)
			if not shopConfig then return true end
			local cfg = isSell and shopConfig.stash_sell_config or shopConfig.stash_config
			if not cfg then return true end

			-- 1. Kiểm tra cấu hình cấp bậc tối thiểu để lấy đồ (minGradeTake / withdrawMinGrade / ...)
			local minGradeTake = cfg.minGradeTake or cfg.withdrawMinGrade or cfg.minGradeWithdraw or cfg.takeMinGrade
			if minGradeTake ~= nil then
				if not src then return false, minGradeTake end
				local player = exports.qbx_core:GetPlayer(src)
				if not player then return false, minGradeTake end
				local grade = player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0
				if player.PlayerData.job.name == shopConfig.job and grade >= tonumber(minGradeTake) then
					return true, nil
				else
					return false, minGradeTake
				end
			end

			-- 2. Kiểm tra cấu hình chỉ cho phép cất vào (onlyDeposit = true)
			if cfg.onlyDeposit == true or cfg.depositOnly == true or cfg.blockWithdraw == true or cfg.canWithdraw == false or cfg.canTake == false or cfg.onlyPut == true or cfg.deposit_only == true or cfg.only_deposit == true then
				return false, nil
			end

			return true, nil
		end

		-- Kiểm tra toInventory (player đặt item vào kho)
		local toShopConfig, toShopKey, toIsSell = GetShopForInventory(payload.toInventory)
		if toShopConfig then
			if payload.fromInventory ~= payload.toInventory and tonumber(payload.fromInventory) then
				local playerSrc = payload.source or tonumber(payload.fromInventory)

				-- Lấy thông tin item nguồn (từ túi người chơi)
				local fromItem = type(payload.fromSlot) == 'table' and payload.fromSlot or (payload.fromSlot and exports.ox_inventory:GetSlot(payload.fromInventory, payload.fromSlot))
				local itemName = fromItem and fromItem.name

				if not itemName then
					debugPrint(_('debug_no_item_info'))
					return false
				end

				-- Lấy thông tin item đích trong kho (nếu slot đích trong kho đã có item)
				local targetSlotNum = type(payload.toSlot) == 'table' and (payload.toSlot.slot or payload.toSlot[1]) or tonumber(payload.toSlot)
				local destItem = (type(payload.toSlot) == 'table' and payload.toSlot.name and payload.toSlot) or (targetSlotNum and exports.ox_inventory:GetSlot(payload.toInventory, targetSlotNum))

				-- Nếu người chơi không có quyền lấy đồ ra khỏi kho
				local canWithdraw, requiredGrade = CanPlayerWithdrawFromStash(playerSrc, toShopConfig, toIsSell)
				if not canWithdraw then
					-- Nếu ô đích trong kho đã có item:
					if destItem and destItem.name then
						-- 1. Nếu khác loại item -> chắc chắn ox_inventory sẽ swap đổi chỗ làm item trong kho văng ra túi -> CHẶN
						if destItem.name ~= itemName then
							if playerSrc then
								local msg = requiredGrade and _('stash_grade_required', requiredGrade) or _('stash_cannot_swap')
								TriggerClientEvent('ox_lib:notify', playerSrc, {
									title = _(toShopConfig.label) or _('default_shop'),
									description = msg,
									type = 'error'
								})
							end
							return false
						else
							-- 2. Cùng loại item nhưng khác metadata sẽ bị ox_inventory swap thay vì gộp stack -> CHẶN
							local fromMeta = fromItem and fromItem.metadata or {}
							local destMeta = destItem.metadata or {}
							if json.encode(fromMeta) ~= json.encode(destMeta) then
								if playerSrc then
									local msg = requiredGrade and _('stash_grade_required', requiredGrade) or _('stash_cannot_swap')
									TriggerClientEvent('ox_lib:notify', playerSrc, {
										title = _(toShopConfig.label) or _('default_shop'),
										description = msg,
										type = 'error'
									})
								end
								return false
							end
						end
					end
				end

				-- Kiểm tra danh sách cho phép tương ứng (stash_items hoặc stash_sell_items)
				local allowedList = toIsSell and toShopConfig.stash_sell_items or toShopConfig.stash_items
				local allowedInStash = false
				if allowedList then
					for _, allowedItem in ipairs(allowedList) do
						if allowedItem == itemName then
							allowedInStash = true
							break
						end
					end
				else
					allowedInStash = toShopConfig.items and toShopConfig.items[itemName] ~= nil
				end

				local itemPrice = GetItemPrice(toShopKey, itemName) or (toShopConfig.items and toShopConfig.items[itemName]) or 0

				debugPrint("DEBUG: Shop =", payload.toInventory)
				debugPrint("DEBUG: Item name =", itemName)
				debugPrint("DEBUG: isSell =", toIsSell)
				debugPrint("DEBUG: Allowed =", allowedInStash)
				debugPrint("DEBUG: Item price =", itemPrice)

				if not allowedInStash then
					local playerSrc = payload.source or tonumber(payload.fromInventory)
					if playerSrc then
						TriggerClientEvent('ox_lib:notify', playerSrc, {
							title = _('default_shop'),
							description = _('item_not_allowed', itemName),
							type = 'error'
						})
					end
					return false
				end

				-- Chỉ set giá và refresh shop khi bỏ vào kho bán (stash_sell)
				if toIsSell then
					CreateThread(function()
						Wait(500) -- Đợi item được chuyển xong
						local slot = payload.toSlot
						debugPrint("DEBUG: Set giá cho slot", slot, "trong kho bán", payload.toInventory)

						local item = exports.ox_inventory:GetSlot(payload.toInventory, slot)
						if item then
							debugPrint("DEBUG: Tìm thấy item trong slot:", json.encode(item))
							local metadata = item.metadata or {}
							metadata.shopData = {
								shop = payload.toInventory,
								price = itemPrice
							}
							local success = exports.ox_inventory:SetMetadata(payload.toInventory, slot, metadata)
							debugPrint("DEBUG: SetMetadata result:", success)
							debugPrint(_('debug_price_set', itemPrice, itemName, slot))
							Wait(100)
							TriggerEvent('rep_shop:server:lamMoiShop', toShopKey)
						else
							debugPrint("DEBUG: KHÔNG tìm thấy item trong slot", slot, "của kho bán", payload.toInventory)
							local allItems = exports.ox_inventory:GetInventoryItems(payload.toInventory, false)
							if allItems then
								debugPrint("DEBUG: Tất cả items trong kho bán:", json.encode(allItems))
								for slotNum, itemData in pairs(allItems) do
									if itemData.name == itemName then
										debugPrint("DEBUG: Tìm thấy item", itemName, "ở slot", slotNum)
										local metadata = itemData.metadata or {}
										metadata.shopData = {
											shop = payload.toInventory,
											price = itemPrice
										}
										exports.ox_inventory:SetMetadata(payload.toInventory, slotNum, metadata)
										debugPrint("DEBUG: Đã set giá cho slot", slotNum)
										break
									end
								end
							end
							Wait(100)
							TriggerEvent('rep_shop:server:lamMoiShop', toShopKey)
						end
					end)
				end
			end
		end

		-- Kiểm tra fromInventory (player lấy item ra khỏi kho)
		local fromShopConfig, fromShopKey, fromIsSell = GetShopForInventory(payload.fromInventory)
		if fromShopConfig then
			-- Nếu lấy đồ từ kho ra inventory khác (không phải sắp xếp trong kho)
			if payload.fromInventory ~= payload.toInventory then
				local playerSrc = payload.source or tonumber(payload.toInventory)
				local canWithdraw, requiredGrade = CanPlayerWithdrawFromStash(playerSrc, fromShopConfig, fromIsSell)
				if not canWithdraw then
					if playerSrc then
						local msg = requiredGrade and _('stash_grade_required', requiredGrade) or _('stash_deposit_only')
						TriggerClientEvent('ox_lib:notify', playerSrc, {
							title = _(fromShopConfig.label) or _('default_shop'),
							description = msg,
							type = 'error'
						})
					end
					return false
				end
			end

			-- Nếu là swap (có item ở slot đích trong túi người chơi), kiểm tra item bị đổi ngược vào kho có được phép không
			local destSlotNum = type(payload.toSlot) == 'table' and (payload.toSlot.slot or payload.toSlot[1]) or tonumber(payload.toSlot)
			local destItem = (type(payload.toSlot) == 'table' and payload.toSlot.name and payload.toSlot) or (destSlotNum and exports.ox_inventory:GetSlot(payload.toInventory, destSlotNum))
			if destItem and destItem.name then
				local swappedItemName = destItem.name
				local allowedList = fromIsSell and fromShopConfig.stash_sell_items or fromShopConfig.stash_items
				local allowedInStash = false
				if allowedList then
					for _, allowedItem in ipairs(allowedList) do
						if allowedItem == swappedItemName then
							allowedInStash = true
							break
						end
					end
				else
					allowedInStash = fromShopConfig.items and fromShopConfig.items[swappedItemName] ~= nil
				end

				if not allowedInStash then
					debugPrint("DEBUG: Chặn swap - item", swappedItemName, "không được phép vào kho", payload.fromInventory)
					local playerSrc = payload.source or tonumber(payload.toInventory)
					if playerSrc then
						TriggerClientEvent('ox_lib:notify', playerSrc, {
							title = _('default_shop'),
							description = _('item_not_allowed', swappedItemName),
							type = 'error'
						})
					end
					return false
				end
			end
			-- Chỉ refresh shop khi lấy item từ kho bán
			if fromIsSell then
				TriggerEvent('rep_shop:server:lamMoiShop', fromShopKey)
			end
		end
	end, {})

	buyHook = exports.ox_inventory:registerHook('buyItem', function(payload)
		local metadata = payload.metadata
		-- Kiểm tra tất cả shops (item được lấy từ kho bán stash_sell)
		for shopId, _ in pairs(Config.Shops) do
			local sellStashId = shopId .. '_sell'
			if metadata and metadata.shopData and metadata.shopData.shop == sellStashId then
				debugPrint("Người dùng :", payload.toInventory, " đã mua ", payload.itemName, " với số lượng: ", payload.count, " ở cửa hàng ", metadata.shopData.shop)
				exports.ox_inventory:RemoveItem(sellStashId, payload.itemName, payload.count)
				local shopJobName = Config.Shops[shopId] and Config.Shops[shopId].job or shopId
				exports['Renewed-Banking']:addAccountMoney(shopJobName, metadata.shopData.price * payload.count)
				debugPrint(metadata.shopData.shop, metadata.shopData.price)
				break
			end
		end
	end, {})
	
	debugPrint("set up xong")
end)

-- Throttle: mỗi shopKey chỉ refresh 1 lần trong 400ms, tránh spam thread
local _pendingRefresh = {}

RegisterNetEvent('rep_shop:server:lamMoiShop', function(shopKey)
	if _pendingRefresh[shopKey] then return end  -- đã có refresh được lần trong hàng
	_pendingRefresh[shopKey] = true

	SetTimeout(400, function()
		_pendingRefresh[shopKey] = nil
		local shopConfig = Config.Shops[shopKey]
		if not shopConfig then return end
		local sellStashId = shopKey .. '_sell'
		local items = exports.ox_inventory:GetInventoryItems(sellStashId, false)
		local stashItems = {}
		for _, v in pairs(items or {}) do
			if v and v.name then
				local metadata = v.metadata
				if metadata and metadata.shopData then
					local price = metadata.shopData.price or 0
					stashItems[#stashItems + 1] = { name = v.name, metadata = metadata, count = v.count, price = price }
				end
			end
		end
		exports.ox_inventory:RegisterShop(sellStashId, {
			name = _(shopConfig.label),
			inventory = stashItems,
			locations = { vec3(0,0,0) }
		})
	end)
end)

-- =============================================
-- HỆ THỐNG ĐẶT HÀNG MỚI
-- =============================================

-- Callback lấy dữ liệu shop (items + orders nếu là nhân viên)
lib.callback.register('xn_banhnuoc:server:getShopData', function(source, shopKey, isEmployee)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return nil end
    
    local items = {}
    local stashItems = exports.ox_inventory:GetInventoryItems(shopKey .. '_sell', false)

    -- Tạo map để tính tổng số lượng theo item name
    local itemCounts = {}
    if stashItems then
        for _, item in pairs(stashItems) do
            if item and item.name then
                itemCounts[item.name] = (itemCounts[item.name] or 0) + item.count
            end
        end
    end

    -- Lấy items từ config & custom prices với số lượng từ stash_sell
    local allShopItems = GetAllShopItems(shopKey)
    for itemName, defaultPrice in pairs(allShopItems) do
        local count = itemCounts[itemName] or 0
        if count > 0 then
            local itemData = exports.ox_inventory:Items(itemName)
            local currentPrice = GetItemPrice(shopKey, itemName) or defaultPrice
            items[#items + 1] = {
                name = itemName,
                label = itemData and itemData.label or itemName,
                price = currentPrice,
                count = count
            }
        end
    end

    local orders = {}
    if isEmployee then
        -- Lấy các đơn hàng pending và confirmed
        for _, order in pairs(shopOrders[shopKey] or {}) do
            if order.status == 'pending' or order.status == 'confirmed' then
                orders[#orders + 1] = order
            end
        end
        -- Sắp xếp theo thời gian mới nhất
        table.sort(orders, function(a, b) return a.orderTime > b.orderTime end)
    end
    
    debugPrint("DEBUG SERVER: getShopData - shopKey:", shopKey, "items:", #items, "orders:", #orders)

    -- Trạng thái NPC và quyền boss
    local npcStatus = GetNpcStatus and GetNpcStatus(shopKey) or nil
    local isBoss    = false
    if isEmployee then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            local grade    = player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0
            local minGrade = shopConfig.stash_sell_config and shopConfig.stash_sell_config.minGrade or 3
            isBoss = grade >= minGrade
        end
    end

    return {
        items      = items,
        orders     = orders,
        npcStatus  = npcStatus,
        npcSelling = IsNpcSelling and IsNpcSelling(shopKey) or false,
        isBoss     = isBoss,
    }
end)

-- Callback lấy items cho shop (dùng cho bán trực tiếp)
lib.callback.register('xn_banhnuoc:server:getShopItems', function(source, shopKey)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return {} end
    
    local items = {}
    local stashItems = exports.ox_inventory:GetInventoryItems(shopKey .. '_sell', false)
    
    local itemCounts = {}
    if stashItems then
        for _, item in pairs(stashItems) do
            if item and item.name then
                itemCounts[item.name] = (itemCounts[item.name] or 0) + item.count
            end
        end
    end
    
    local allShopItems = GetAllShopItems(shopKey)
    for itemName, defaultPrice in pairs(allShopItems) do
        local count = itemCounts[itemName] or 0
        if count > 0 then
            local itemData = exports.ox_inventory:Items(itemName)
            local currentPrice = GetItemPrice(shopKey, itemName) or defaultPrice
            items[#items + 1] = {
                name = itemName,
                label = itemData and itemData.label or itemName,
                price = currentPrice,
                count = count
            }
        end
    end
    
    return items
end)

-- Event đặt hàng từ khách
RegisterNetEvent('xn_banhnuoc:server:placeOrder', function(shopKey, orderItems, pid, customerName)
    local source = source
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    -- Lấy số điện thoại từ lb-phone (server-side)
    local phone = nil
    local success, result = pcall(function()
        return exports['lb-phone']:GetEquippedPhoneNumber(source)
    end)
    if success and result then
        phone = result
    end
    
    debugPrint("DEBUG SERVER: Nhận đơn hàng từ player", source, "- shopKey:", shopKey, "- phone:", phone)
    
    -- Tính tổng giá và kiểm tra stock
    local totalPrice = 0
    local validItems = {}
    
    for _, item in ipairs(orderItems) do
        local price = GetItemPrice(shopKey, item.name)
        local stock = GetStashItemCount(shopKey .. '_sell', item.name)
        
        if price and stock >= item.quantity then
            totalPrice = totalPrice + (price * item.quantity)
            validItems[#validItems + 1] = {
                name = item.name,
                label = item.label,
                quantity = item.quantity,
                price = price
            }
        end
    end
    
    if #validItems == 0 then
        TriggerClientEvent('xn_banhnuoc:client:orderPlaced', source, false, _('no_items_available'))
        return
    end
    
    -- Tạo đơn hàng
    local orderId = GenerateOrderId()
    local order = {
        id = orderId,
        customerId = source,
        pid = pid or 'N/A',
        customerName = customerName or 'Không rõ',
        phone = phone or 'Không có',
        items = validItems,
        totalPrice = totalPrice,
        orderTime = os.time() * 1000, -- Milliseconds cho JS
        status = 'pending'
    }
    
    -- Lưu đơn hàng
    if not shopOrders[shopKey] then
        shopOrders[shopKey] = {}
    end
    shopOrders[shopKey][orderId] = order
    
    debugPrint("DEBUG SERVER: Đơn hàng mới:", json.encode(order))
    
    -- Thông báo cho khách
    TriggerClientEvent('xn_banhnuoc:client:orderPlaced', source, true, _('order_placed_success'))
    
    -- Thông báo cho tất cả nhân viên
    local employees = GetOnlineEmployees(shopConfig.job)
    for _, employeeId in ipairs(employees) do
        TriggerClientEvent('xn_banhnuoc:client:newOrder', employeeId, order)
    end
end)

-- Event xác nhận đơn hàng
RegisterNetEvent('xn_banhnuoc:server:confirmOrder', function(shopKey, orderId)
    local source = source
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    -- Kiểm tra quyền
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= shopConfig.job then return end
    
    local order = shopOrders[shopKey] and shopOrders[shopKey][orderId]
    if not order or order.status ~= 'pending' then return end
    
    -- Kiểm tra stock
    for i, item in ipairs(order.items) do
        local stock = GetStashItemCount(shopKey .. '_sell', item.name)
        if stock < item.quantity then
            TriggerClientEvent('xn_banhnuoc:client:orderUpdated', source, {
                id = orderId,
                error = _('not_enough_stock', stock)
            })
            return
        end
    end
    
    -- Cập nhật trạng thái
    order.status = 'confirmed'
    order.confirmedBy = source
    order.confirmedAt = os.time() * 1000
    
    -- Lấy thông tin nhân viên xác nhận
    local employeePid = player.PlayerData.pid or player.PlayerData.source
    local employeeName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    order.confirmedByPid = employeePid
    order.confirmedByName = employeeName
    
    debugPrint("DEBUG SERVER: Đơn hàng", orderId, "được xác nhận bởi", source)
    
    -- Thông báo cho tất cả nhân viên
    local employees = GetOnlineEmployees(shopConfig.job)
    for _, employeeId in ipairs(employees) do
        TriggerClientEvent('xn_banhnuoc:client:orderUpdated', employeeId, order)
    end
end)

-- Event hủy đơn hàng
RegisterNetEvent('xn_banhnuoc:server:cancelOrder', function(shopKey, orderId)
    local source = source
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    -- Kiểm tra quyền
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= shopConfig.job then return end
    
    local order = shopOrders[shopKey] and shopOrders[shopKey][orderId]
    if not order then return end
    
    -- Nếu đơn đã được xác nhận, chỉ nhân viên đã xác nhận mới được hủy
    if order.status == 'confirmed' and order.confirmedBy and order.confirmedBy ~= source then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = _('order_owned_by_another'),
            type = 'error'
        })
        return
    end
    
    local customerId = order.customerId
    
    -- Xóa đơn hàng
    shopOrders[shopKey][orderId] = nil
    
    debugPrint("DEBUG SERVER: Đơn hàng", orderId, "bị hủy bởi", source)
    
    -- Thông báo cho tất cả nhân viên
    local employees = GetOnlineEmployees(shopConfig.job)
    for _, employeeId in ipairs(employees) do
        TriggerClientEvent('xn_banhnuoc:client:orderRemoved', employeeId, orderId)
    end
    
    -- Thông báo cho khách (nếu còn online)
    local customer = exports.qbx_core:GetPlayer(customerId)
    if customer then
        TriggerClientEvent('xn_banhnuoc:client:orderCancelled', customerId, _('your_order_cancelled'))
    end
end)

-- Event hoàn thành đơn hàng
RegisterNetEvent('xn_banhnuoc:server:completeOrder', function(shopKey, orderId)
    local source = source
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    -- Kiểm tra quyền
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= shopConfig.job then return end
    
    local order = shopOrders[shopKey] and shopOrders[shopKey][orderId]
    if not order or order.status ~= 'confirmed' then return end
    
    -- Kiểm tra xem có phải nhân viên đã xác nhận đơn này không
    if order.confirmedBy and order.confirmedBy ~= source then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = _('order_owned_by_another'),
            type = 'error'
        })
        return
    end
    
    local customerId = order.customerId
    
    -- NOTE: Không tự động thu tiền/chuyển vật phẩm
    -- Nhân viên và khách tự trao đổi tiền + vật phẩm thủ công
    
    -- Xóa đơn hàng
    shopOrders[shopKey][orderId] = nil
    
    debugPrint("DEBUG SERVER: Đơn hàng", orderId, "hoàn thành")
    
    -- Thông báo cho nhân viên
    local employees = GetOnlineEmployees(shopConfig.job)
    for _, employeeId in ipairs(employees) do
        TriggerClientEvent('xn_banhnuoc:client:orderRemoved', employeeId, orderId)
    end
    
    -- Thông báo thành công cho nhân viên hoàn thành
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Thành công',
        description = _('order_completed_success', order.totalPrice),
        type = 'success'
    })
    
    -- Thông báo cho khách (nếu còn online)
    local customer = exports.qbx_core:GetPlayer(customerId)
    if customer then
        TriggerClientEvent('xn_banhnuoc:client:orderCompleted', customerId, _('your_order_completed'))
    end
end)

-- Event lấy orders cho nhân viên (khi login/đổi duty)
RegisterNetEvent('xn_banhnuoc:server:getEmployeeOrders', function(shopKey)
    local source = source
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= shopConfig.job or not player.PlayerData.job.onduty then
        return
    end
    
    local orders = {}
    for _, order in pairs(shopOrders[shopKey] or {}) do
        if order.status == 'pending' or order.status == 'confirmed' then
            orders[#orders + 1] = order
        end
    end
    
    if #orders > 0 then
        TriggerClientEvent('xn_banhnuoc:client:updateBell', source, orders)
    end
end)

-- =============================================
-- CALLBACK CHO BÁN TRỰC TIẾP (giữ nguyên)
-- =============================================

-- Callback lấy danh sách items trong shop (cho menu bán hàng trực tiếp)
lib.callback.register('rep_shop:server:getShopItems', function(source, shopKey)
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return {} end
    
    local items = {}
    local stashItems = exports.ox_inventory:GetInventoryItems(shopKey .. '_sell', false)
    
    -- Tạo map để tính tổng số lượng theo item name
    local itemCounts = {}
    if stashItems then
        for _, item in pairs(stashItems) do
            if item and item.name then
                itemCounts[item.name] = (itemCounts[item.name] or 0) + item.count
            end
        end
    end
    
    -- Lấy items từ config & custom prices với số lượng từ stash
    local allShopItems = GetAllShopItems(shopKey)
    for itemName, defaultPrice in pairs(allShopItems) do
        local count = itemCounts[itemName] or 0
        if count > 0 then
            local itemData = exports.ox_inventory:Items(itemName)
            local currentPrice = GetItemPrice(shopKey, itemName) or defaultPrice
            items[#items + 1] = {
                name = itemName,
                label = itemData and itemData.label or itemName,
                price = currentPrice,
                count = count,
                isCustom = IsItemCustomPrice(shopKey, itemName)
            }
        end
    end
    
    debugPrint("DEBUG SERVER: getShopItems - shopKey:", shopKey, "items:", json.encode(items))
    return items
end)

-- Callback lấy danh sách các items ĐƯỢC PHÉP CUSTOM GIÁ của shop (chỉ cho nhân viên đạt grade tối thiểu)
lib.callback.register('xn_banhnuoc:server:getManagePrices', function(source, shopKey)
    if not CanPlayerManagePrices(source, shopKey) then
        return nil
    end

    local shopConfig = Config.Shops[shopKey]
    if not shopConfig or not shopConfig.items then return {} end

    local result = {}
    for itemName, _ in pairs(shopConfig.items) do
        if IsItemCustomPrice(shopKey, itemName) then
            local itemData = exports.ox_inventory:Items(itemName)
            local currentPrice = GetItemPrice(shopKey, itemName) or 0
            result[#result + 1] = {
                name = itemName,
                label = itemData and itemData.label or itemName,
                price = currentPrice,
                isCustom = true
            }
        end
    end
    table.sort(result, function(a, b) return a.label < b.label end)
    return result
end)

-- Event cập nhật giá tùy chỉnh cho item của shop
RegisterNetEvent('xn_banhnuoc:server:setCustomPrice', function(shopKey, itemName, newPrice)
    local source = source
    if not CanPlayerManagePrices(source, shopKey) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Lỗi', description = 'Bạn không đủ cấp bậc để chỉnh giá!', type = 'error' })
        return
    end

    if not IsItemCustomPrice(shopKey, itemName) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Lỗi', description = 'Vật phẩm này không thể tùy chỉnh giá!', type = 'error' })
        return
    end

    newPrice = tonumber(newPrice)
    if not newPrice or newPrice < 0 then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Lỗi', description = 'Giá không hợp lệ!', type = 'error' })
        return
    end

    if not customShopPrices[shopKey] then
        customShopPrices[shopKey] = {}
    end
    customShopPrices[shopKey][itemName] = newPrice

    MySQL.query([[
        INSERT INTO `xn_banhnuoc_prices` (shop_key, item_name, price)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE price = VALUES(price)
    ]], { shopKey, itemName, newPrice })

    local itemData = exports.ox_inventory:Items(itemName)
    local itemLabel = itemData and itemData.label or itemName

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Thành công',
        description = string.format('Đã cập nhật giá %s thành %s$', itemLabel, lib.math.groupdigits(newPrice)),
        type = 'success'
    })

    -- Cập nhật lại giá metadata trong kho bán stash_sell
    local sellStashId = shopKey .. '_sell'
    local stashItems = exports.ox_inventory:GetInventoryItems(sellStashId, false)
    if stashItems then
        for slotNum, itemData in pairs(stashItems) do
            if itemData.name == itemName then
                local metadata = itemData.metadata or {}
                metadata.shopData = {
                    shop = sellStashId,
                    price = newPrice
                }
                exports.ox_inventory:SetMetadata(sellStashId, slotNum, metadata)
            end
        end
    end

    TriggerEvent('rep_shop:server:lamMoiShop', shopKey)
end)

-- Event nhận yêu cầu bán từ nhân viên
RegisterNetEvent('rep_shop:server:requestSale', function(targetPlayerId, shopKey, itemName, quantity, price)
    local source = source
    local employee = exports.qbx_core:GetPlayer(source)
    local customer = exports.qbx_core:GetPlayer(targetPlayerId)
    
    if not employee or not customer then
        TriggerClientEvent('rep_shop:client:saleResult', source, false, _('customer_offline'))
        return
    end
    
    local shopConfig = Config.Shops[shopKey]
    if not shopConfig then return end
    
    -- Kiểm tra job của nhân viên
    if employee.PlayerData.job.name ~= shopConfig.job then
        debugPrint("DEBUG SERVER: Nhân viên không có job đúng")
        return
    end
    
    -- Kiểm tra số lượng trong kho
    local stockCount = GetStashItemCount(shopKey .. '_sell', itemName)
    debugPrint("DEBUG SERVER: Stock count for", itemName, ":", stockCount, "requested:", quantity)
    
    if stockCount < quantity then
        TriggerClientEvent('rep_shop:client:saleResult', source, false, _('not_enough_stock', stockCount))
        return
    end
    
    local totalPrice = price * quantity
    local employeeName = employee.PlayerData.charinfo.firstname .. ' ' .. employee.PlayerData.charinfo.lastname
    local jobLabel = employee.PlayerData.job.label or shopConfig.job
    local itemData = exports.ox_inventory:Items(itemName)
    local itemLabel = itemData and itemData.label or itemName
    
    -- Lưu giao dịch đang chờ
    pendingTransactions[targetPlayerId] = {
        employeeId = source,
        shopKey = shopKey,
        itemName = itemName,
        quantity = quantity,
        price = price,
        totalPrice = totalPrice,
        timestamp = os.time()
    }
    
    debugPrint("DEBUG SERVER: Gửi offer đến customer", targetPlayerId)
    
    -- Gửi thông báo cho khách hàng
    TriggerClientEvent('rep_shop:client:receiveSaleOffer', targetPlayerId, employeeName, jobLabel, itemName, itemLabel, quantity, totalPrice, source, shopKey)
end)

-- Helper: kiểm tra cấu hình hoa hồng của shop
local function GetShopCommission(shopConfig)
    if not shopConfig then return false, 0 end
    local enabled = false
    local percent = (Config.GlobalSettings and Config.GlobalSettings.defaultCommissionPercent) or 10

    if type(shopConfig.commission) == 'table' then
        enabled = shopConfig.commission.enabled == true
        percent = shopConfig.commission.percent or shopConfig.commission.rate or percent
    elseif shopConfig.commission == true or shopConfig.employeeCommission == true or shopConfig.enableCommission == true then
        enabled = true
        percent = shopConfig.commissionPercent or shopConfig.commissionRate or percent
    end

    return enabled, percent
end

-- Event khách hàng đồng ý mua
RegisterNetEvent('rep_shop:server:confirmPurchase', function(employeeId, shopKey, itemName, quantity, totalPrice)
    local source = source
    local customer = exports.qbx_core:GetPlayer(source)
    local employee = exports.qbx_core:GetPlayer(employeeId)
    
    if not customer then return end
    
    -- Kiểm tra pending transaction
    local pending = pendingTransactions[source]
    if not pending or pending.employeeId ~= employeeId then
        debugPrint("DEBUG SERVER: Không tìm thấy pending transaction")
        return
    end
    
    -- Xóa pending transaction
    pendingTransactions[source] = nil
    
    -- Kiểm tra lại số lượng trong kho
    local stockCount = GetStashItemCount(shopKey .. '_sell', itemName)
    if stockCount < quantity then
        TriggerClientEvent('rep_shop:client:purchaseResult', source, false, _('not_enough_stock', stockCount))
        if employee then
            TriggerClientEvent('rep_shop:client:saleResult', employeeId, false, _('not_enough_stock', stockCount))
        end
        return
    end
    
    -- Kiểm tra tiền của khách hàng
    local customerMoney = customer.PlayerData.money.cash
    if customerMoney < totalPrice then
        TriggerClientEvent('rep_shop:client:purchaseResult', source, false, _('buyer_not_enough_money', lib.math.groupdigits(totalPrice)))
        if employee then
            TriggerClientEvent('rep_shop:client:saleResult', employeeId, false, _('not_enough_money'))
        end
        return
    end
    
    local itemData = exports.ox_inventory:Items(itemName)
    local itemLabel = itemData and itemData.label or itemName
    
    -- Thực hiện giao dịch
    -- 1. Trừ tiền khách hàng
    customer.Functions.RemoveMoney('cash', totalPrice, 'shop-purchase-' .. shopKey)
    
    -- 2. Xóa item từ kho bán (stash_sell)
    local removed = exports.ox_inventory:RemoveItem(shopKey .. '_sell', itemName, quantity)
    if not removed then
        -- Hoàn tiền nếu không xóa được item
        customer.Functions.AddMoney('cash', totalPrice, 'shop-purchase-refund-' .. shopKey)
        TriggerClientEvent('rep_shop:client:purchaseResult', source, false, _('not_enough_stock', 0))
        if employee then
            TriggerClientEvent('rep_shop:client:saleResult', employeeId, false, _('not_enough_stock', 0))
        end
        return
    end
    
    -- 3. Thêm item cho khách hàng
    local added = exports.ox_inventory:AddItem(source, itemName, quantity)
    if not added then
        -- Hoàn tiền và item nếu không thêm được
        customer.Functions.AddMoney('cash', totalPrice, 'shop-purchase-refund-' .. shopKey)
        exports.ox_inventory:AddItem(shopKey .. '_sell', itemName, quantity)
        TriggerClientEvent('rep_shop:client:purchaseResult', source, false, 'Không thể nhận vật phẩm!')
        if employee then
            TriggerClientEvent('rep_shop:client:saleResult', employeeId, false, 'Khách hàng không thể nhận vật phẩm!')
        end
        return
    end
    
    -- 4. Tính toán hoa hồng và cộng tiền vào quỹ doanh nghiệp / nhân viên
    local shopConfig = Config.Shops[shopKey]
    local shopJobName = shopConfig and shopConfig.job or shopKey
    
    local hasCommission, commissionPercent = GetShopCommission(shopConfig)
    local commissionAmount = 0
    local enterpriseAmount = totalPrice
    
    if hasCommission and employee then
        commissionAmount = math.floor(totalPrice * (commissionPercent / 100))
        enterpriseAmount = totalPrice - commissionAmount
        if commissionAmount > 0 then
            employee.Functions.AddMoney('cash', commissionAmount, 'shop-commission-' .. shopKey)
        end
    end
    
    if enterpriseAmount > 0 then
        exports['Renewed-Banking']:addAccountMoney(shopJobName, enterpriseAmount)
    end
    
    debugPrint("DEBUG SERVER: Giao dịch thành công - ", itemName, "x", quantity, "giá", totalPrice, "Hoa hồng:", commissionAmount, "Quỹ DN:", enterpriseAmount)
    
    if shopConfig and shopConfig.discordWebhook and shopConfig.discordWebhook ~= '' then
        local employeeName = employee and (employee.PlayerData.charinfo.firstname .. ' ' .. employee.PlayerData.charinfo.lastname) or "Không rõ (Offline)"
        local customerName = customer.PlayerData.charinfo.firstname .. ' ' .. customer.PlayerData.charinfo.lastname
        local timeInfo = os.date("%d/%m/%Y %H:%M:%S")
        local priceUnit = pending and pending.price or (totalPrice / quantity)
        local shopLabel = shopConfig.label or shopKey
        local shopIcon = shopConfig.shopIcon or '🛒'
        
        local desc = "**Cửa hàng:** " .. shopLabel .. "\n**Nhân viên:** " .. employeeName .. "\n**Người mua:** " .. customerName .. "\n**Sản phẩm:** " .. itemLabel .. "\n**Số lượng:** " .. quantity .. "\n**Đơn giá:** " .. lib.math.groupdigits(priceUnit) .. " VNĐ\n**Tổng tiền:** " .. lib.math.groupdigits(totalPrice) .. " VNĐ"
        
        if hasCommission and commissionAmount > 0 then
            desc = desc .. "\n**Hoa hồng NV (" .. commissionPercent .. "%):** " .. lib.math.groupdigits(commissionAmount) .. " VNĐ\n**Quỹ doanh nghiệp:** " .. lib.math.groupdigits(enterpriseAmount) .. " VNĐ"
        end
        
        desc = desc .. "\n**Thời gian:** " .. timeInfo
        
        local embedData = {
            {
                ["color"] = (shopConfig.job == 'quanan') and 3447003 or 15105570,
                ["title"] = shopIcon .. " Giao Dịch Bán Hàng",
                ["description"] = desc,
                ["footer"] = {
                    ["text"] = "Hệ thống Log " .. shopLabel
                }
            }
        }
        
        PerformHttpRequest(shopConfig.discordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "Log Hệ Thống", embeds = embedData}), { ['Content-Type'] = 'application/json' })
    end
    
    -- Refresh shop
    TriggerEvent('rep_shop:server:lamMoiShop', shopKey)
    
    -- Thông báo cho cả hai bên
    TriggerClientEvent('rep_shop:client:purchaseResult', source, true, _('purchase_success', quantity, itemLabel, lib.math.groupdigits(totalPrice)))
    if employee then
        if hasCommission and commissionAmount > 0 then
            TriggerClientEvent('rep_shop:client:saleResult', employeeId, true, _('sale_success_commission', quantity, itemLabel, lib.math.groupdigits(totalPrice), lib.math.groupdigits(commissionAmount)))
        else
            TriggerClientEvent('rep_shop:client:saleResult', employeeId, true, _('sale_success', quantity, itemLabel, lib.math.groupdigits(totalPrice)))
        end
    end
end)

-- Event khách hàng từ chối mua
RegisterNetEvent('rep_shop:server:declinePurchase', function(employeeId)
    local source = source
    
    -- Xóa pending transaction
    pendingTransactions[source] = nil
    
    -- Thông báo cho nhân viên
    local employee = exports.qbx_core:GetPlayer(employeeId)
    if employee then
        TriggerClientEvent('rep_shop:client:saleResult', employeeId, false, _('sale_cancelled'))
    end
    
    -- Thông báo cho khách hàng
    TriggerClientEvent('rep_shop:client:purchaseResult', source, false, _('purchase_cancelled'))
end)

-- Cleanup pending transactions cũ (mỗi 5 phút)
CreateThread(function()
    while true do
        Wait(300000) -- 5 phút
        local now = os.time()
        for playerId, transaction in pairs(pendingTransactions) do
            if now - transaction.timestamp > 120 then -- Xóa sau 2 phút
                pendingTransactions[playerId] = nil
                debugPrint("DEBUG SERVER: Cleanup pending transaction for player", playerId)
            end
        end
    end
end)

-- =============================================
-- CRAFTING SYSTEM
-- =============================================

-- Helper: tìm shopKey theo job name
local function GetShopKeyByJob(jobName)
    for shopKey, shopConfig in pairs(Config.Shops) do
        if shopConfig.job == jobName then
            return shopKey
        end
    end
    return nil
end

-- Helper: lấy số lượng item từ stash
local function GetStashCount(stashId, itemName)
    local items = exports.ox_inventory:GetInventoryItems(stashId, false)
    if not items then return 0 end
    local count = 0
    for _, item in pairs(items) do
        if item and item.name == itemName then
            count = count + item.count
        end
    end
    return count
end

-- Callback lấy crafting data với labels đầy đủ
lib.callback.register('xn_banhnuoc:server:getCraftingData', function(source, craftingKey)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    local craftConfig = Config.Crafting[craftingKey]
    if not craftConfig then return nil end

    -- Kiểm tra job nếu có yêu cầu
    if craftConfig.job then
        if player.PlayerData.job.name ~= craftConfig.job or not player.PlayerData.job.onduty then
            return nil
        end
    end

    -- Lấy nguyên liệu từ kho stash của doanh nghiệp (không phải túi player)
    local shopKey = craftConfig.job and GetShopKeyByJob(craftConfig.job) or nil
    local stashItems = {}
    if shopKey then
        local inventoryItems = exports.ox_inventory:GetInventoryItems(shopKey, false)
        if inventoryItems then
            local itemCounts = {}
            for _, item in pairs(inventoryItems) do
                if item and item.name then
                    itemCounts[item.name] = (itemCounts[item.name] or 0) + item.count
                end
            end
            for itemName, count in pairs(itemCounts) do
                local itemData = exports.ox_inventory:Items(itemName)
                stashItems[#stashItems + 1] = {
                    name = itemName,
                    label = itemData and itemData.label or itemName,
                    count = count
                }
            end
        end
    end

    -- Enrich recipes với labels từ ox_inventory
    local enrichedRecipes = {}
    for i, recipe in ipairs(craftConfig.recipes or {}) do
        local recipeItemData = exports.ox_inventory:Items(recipe.name)

        local enrichedIngredients = {}
        for j, ingredient in ipairs(recipe.ingredients or {}) do
            local ingredientData = exports.ox_inventory:Items(ingredient.name)
            enrichedIngredients[j] = {
                name = ingredient.name,
                label = ingredientData and ingredientData.label or ingredient.name,
                count = ingredient.count
            }
        end

        enrichedRecipes[i] = {
            name = recipe.name,
            label = recipe.label or (recipeItemData and recipeItemData.label) or recipe.name,
            count = recipe.count or 1,
            duration = recipe.duration or 5000,
            ingredients = enrichedIngredients
        }
    end

    return {
        recipes = enrichedRecipes,
        playerItems = stashItems  -- Trả về items từ kho stash (NUI dùng field này)
    }
end)

-- Callback kiểm tra nguyên liệu trước khi craft (kiểm tra từ kho stash)
lib.callback.register('xn_banhnuoc:server:checkCraftIngredients', function(source, craftingKey, recipe, quantity)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false, _('error_occurred') end

    local craftConfig = Config.Crafting[craftingKey]
    if not craftConfig then return false, _('error_occurred') end

    -- Kiểm tra job nếu có yêu cầu
    if craftConfig.job then
        if player.PlayerData.job.name ~= craftConfig.job or not player.PlayerData.job.onduty then
            return false, _('wrong_job')
        end
    end

    -- Tìm shopKey để truy cập kho stash
    local shopKey = craftConfig.job and GetShopKeyByJob(craftConfig.job) or nil
    if not shopKey then
        return false, _('error_occurred')
    end

    -- Kiểm tra từng nguyên liệu trong kho stash
    for i, ingredient in ipairs(recipe.ingredients) do
        local needed = ingredient.count * quantity
        local stashCount = GetStashCount(shopKey, ingredient.name)

        if stashCount < needed then
            local itemData = exports.ox_inventory:Items(ingredient.name)
            local itemLabel = itemData and itemData.label or ingredient.name
            return false, _('not_enough_ingredient', itemLabel, needed, stashCount)
        end
    end

    return true, nil
end)

-- Event hoàn thành chế biến
-- Nguyên liệu trừ từ kho stash, sản phẩm thêm vào kho stash_sell
RegisterNetEvent('xn_banhnuoc:server:completeCraft', function(craftingKey, recipe, quantity)
    local source = source
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local craftConfig = Config.Crafting[craftingKey]
    if not craftConfig then return end

    -- Kiểm tra job nếu có yêu cầu
    if craftConfig.job then
        if player.PlayerData.job.name ~= craftConfig.job then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi',
                description = _('wrong_job'),
                type = 'error'
            })
            return
        end
    end

    -- Tìm shopKey
    local shopKey = craftConfig.job and GetShopKeyByJob(craftConfig.job) or nil
    if not shopKey then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = _('error_occurred'),
            type = 'error'
        })
        return
    end
    local sellStashId = shopKey .. '_sell'

    -- Kiểm tra lại nguyên liệu trong kho stash
    for i, ingredient in ipairs(recipe.ingredients) do
        local needed = ingredient.count * quantity
        local stashCount = GetStashCount(shopKey, ingredient.name)

        if stashCount < needed then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lỗi',
                description = _('not_enough_ingredients'),
                type = 'error'
            })
            return
        end
    end

    -- Trừ nguyên liệu từ kho stash
    for _, ingredient in ipairs(recipe.ingredients) do
        local needed = ingredient.count * quantity
        exports.ox_inventory:RemoveItem(shopKey, ingredient.name, needed)
    end

    -- Thêm sản phẩm vào kho stash_sell
    local resultCount = (recipe.count or 1) * quantity
    local added = exports.ox_inventory:AddItem(sellStashId, recipe.name, resultCount)

    if added then
        local itemData = exports.ox_inventory:Items(recipe.name)
        local itemLabel = itemData and itemData.label or recipe.name

        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Thành công',
            description = _('craft_success', resultCount, itemLabel),
            type = 'success'
        })

        -- Refresh kho bán
        TriggerEvent('rep_shop:server:lamMoiShop', shopKey)

        debugPrint("DEBUG SERVER: Chế tạo", resultCount, recipe.name, "-> stash_sell:", sellStashId)
    else
        -- Hoàn lại nguyên liệu vào kho stash nếu không thêm được
        for _, ingredient in ipairs(recipe.ingredients) do
            local needed = ingredient.count * quantity
            exports.ox_inventory:AddItem(shopKey, ingredient.name, needed)
        end

        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Lỗi',
            description = _('craft_failed'),
            type = 'error'
        })
    end
end)