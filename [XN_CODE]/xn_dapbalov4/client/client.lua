local PlayerData = {}
local targetItem = nil
local createdProps = {}

-- Kiểm tra xem item có phải là vật liệu nâng cấp không (clothing items trừ excluded)
local function IsUpgradeMaterial(name)
	local clothingConfig = Config.componentMapping[name]
	if not clothingConfig then return false end
	if clothingConfig.isStackable then return false end
	-- Kiểm tra danh sách loại trừ
	for _, excluded in pairs(Config.ExcludedUpgradeMaterials) do
		if excluded == name then return false end
	end
	return true
end

-- Lấy danh sách items có thể nâng cấp (BaloLevels)
-- Hàm phân tích stackable item:
-- fishingrod -> {baseName = "fishingrod", level = 1}
-- fishingrod1 -> {baseName = "fishingrod", level = 1}
-- fishingrod2 -> {baseName = "fishingrod", level = 2}
local function ParseStackableItem(itemName)
	for baseName, mapping in pairs(Config.componentMapping) do
		if mapping.isStackable and mapping.type == 'item' then
			-- Kiểm tra xem itemName có khớp chính xác baseName không (fishingrod = level 1)
			if itemName == baseName then
				return {
					baseName = baseName,
					level = 1
				}
			end
			-- Kiểm tra xem itemName có bắt đầu bằng baseName và kết thúc bằng số không
			local pattern = "^" .. baseName .. "(%d+)$"
			local levelStr = string.match(itemName, pattern)
			if levelStr then
				return {
					baseName = baseName,
					level = tonumber(levelStr)
				}
			end
		end
	end
	return nil
end

local function LoadUpgradeableItems()
	debugPrint("[DEBUG] LoadUpgradeableItems START")
	local upgradeableItems = {}
	local playerData = exports.qbx_core:GetPlayerData()
	if not playerData or not playerData.charinfo then
		debugPrint("[DEBUG] No player data")
		return upgradeableItems
	end
	local gender = playerData.charinfo.gender == 0 and "male" or "female"
	debugPrint("[DEBUG] Gender:", gender)
	
	local items = exports.ox_inventory:GetPlayerItems()
	if not items then
		debugPrint("[DEBUG] No items found")
		return upgradeableItems
	end
	
	for k, v in pairs(items) do
		local itemConfig = Config.BaloLevels[v.name]
		local baseName = v.name
		local stackableInfo = nil
		
		-- Nếu không tìm thấy config trực tiếp, thử phân tích như stackable item
		if not itemConfig then
			stackableInfo = ParseStackableItem(v.name)
			if stackableInfo then
				itemConfig = Config.BaloLevels[stackableInfo.baseName]
				baseName = stackableInfo.baseName
				debugPrint("[DEBUG] Parsed stackable item:", v.name, "->", stackableInfo.baseName, "level:", stackableInfo.level)
			end
		end
		
		if itemConfig then
			-- Ensure metadata exists
			if not v.metadata then
				v.metadata = {}
			end
			
			-- Xác định level trước khi kiểm tra serial
			local currentLevel
			if stackableInfo then
				currentLevel = stackableInfo.level
				v.metadata.Capdo = stackableInfo.level
				v.metadata.baseName = stackableInfo.baseName -- Lưu baseName để sử dụng sau
			elseif not v.metadata.Capdo then
				v.metadata.Capdo = 1
				currentLevel = 1
			else
				v.metadata.Capdo = tonumber(v.metadata.Capdo) or 1
				currentLevel = v.metadata.Capdo
			end
			
			-- ✅ KIỂM TRA SERIAL - Level 1 của cloth_bags/fishingrod/chaodaivang không cần serial
			local requireSerial = true
			if currentLevel == 1 and (baseName == "cloth_bags" or baseName == "fishingrod" or baseName == "chaodaivang") then
				requireSerial = false
				debugPrint("[DEBUG] Level 1 item, serial not required:", v.name)
			end
			
			if requireSerial and (not v.metadata.serial or v.metadata.serial == "") then
				debugPrint("[DEBUG] Skipped item:", v.name, "- No serial number (Level", currentLevel, "requires serial)")
				goto continue
			end
			
			-- Kiểm tra xem level hiện tại có thể nâng cấp không
			local levelConfig = itemConfig[v.metadata.Capdo]
			if not levelConfig then
				debugPrint("[DEBUG] Skipped item:", v.name, "- No level config for Capdo:", v.metadata.Capdo)
				goto continue
			end
			
			-- Bỏ qua item đã đạt max level (maxtile = 0 hoặc tyle rỗng)
			if levelConfig.maxtile == 0 or not levelConfig.tyle or next(levelConfig.tyle) == nil then
				debugPrint("[DEBUG] Skipped item:", v.name, "- Already at max level (Capdo:", v.metadata.Capdo, ")")
				goto continue
			end
			
			-- Kiểm tra drawable có trong danh sách cho phép không (cho clothing items)
			local clothingConfig = Config.componentMapping[baseName]
			if clothingConfig and not clothingConfig.isStackable then
				-- Đây là clothing item, cần kiểm tra drawable (try both 'drawable' and 'item' metadata fields)
				local drawable = tonumber(v.metadata.drawable) or tonumber(v.metadata.item)
				if drawable then
					local allowedDrawables = levelConfig[gender] or {}
					local isAllowed = false
					for _, allowedId in ipairs(allowedDrawables) do
						if allowedId == drawable then
							isAllowed = true
							break
						end
					end
					if not isAllowed then
						debugPrint("[DEBUG] Skipped item:", v.name, "- Drawable", drawable, "not in allowed list for", gender)
						goto continue
					end
				end
			end
			
			debugPrint("[DEBUG] Found upgradeable item:", v.name, "slot:", k, "Capdo:", v.metadata.Capdo)
			
			v.slot = k
			
			-- Always compute image URL (force overwrite)
			v.metadata.imageurl = GetItemImageUrl(baseName, v.metadata, gender)
			
			-- Get item label
			local itemInfo = exports.ox_inventory:Items(v.name)
			if itemInfo then
				v.label = itemInfo.label or v.name
			else
				v.label = v.name
			end
			
			-- Thêm số drawable vào label cho clothing items (không phải stackable)
			local clothingCfg = Config.componentMapping[baseName]
			if clothingCfg and not clothingCfg.isStackable and v.metadata.drawable then
				v.label = v.label .. " " .. tostring(v.metadata.drawable)
			end
			
			table.insert(upgradeableItems, v)
		end
		::continue::
	end
	
	debugPrint("[DEBUG] LoadUpgradeableItems END - found:", #upgradeableItems)
	return upgradeableItems
end

local function LoadInventory()
	local invData = {}

	-- Nếu chưa chọn targetItem, không load inventory nguyên liệu
	if not targetItem then
		debugPrint("=== LOAD INVENTORY DEBUG ===")
		debugPrint("Target Item: NIL - Skipping inventory load")
		SendReactMessage("updateInventory", invData)
		return
	end

	debugPrint("=== LOAD INVENTORY DEBUG ===")
	if targetItem then
		debugPrint(string.format("Target Item: %s (Capdo: %s)", targetItem.name, targetItem.metadata and targetItem.metadata.Capdo or "NIL"))
	else
		debugPrint("Target Item: NIL")
	end

	for k, v in pairs(exports.ox_inventory:GetPlayerItems()) do
		debugPrint(string.format("Checking item: %s (slot %s, Capdo: %s)", v.name, k, v.metadata and v.metadata.Capdo or "NIL"))
		
		if v.slot >= 6 and v.slot <= 21 then 
			debugPrint("  -> Skipped: slot between 6-21 (equipped clothing)")
			goto continue 
		end
		
		-- Ensure metadata and Capdo exist
		if not v.metadata then
			v.metadata = {}
		end
		if not v.metadata.Capdo then
			v.metadata.Capdo = 1
		end
		
		local shouldAdd = false
		
		-- Kiểm tra stackable item để lấy baseName
		local stackableInfo = ParseStackableItem(targetItem.name)
		local baseName = stackableInfo and stackableInfo.baseName or targetItem.name
		local targetCapdo = stackableInfo and stackableInfo.level or targetItem.metadata.Capdo
		
		local levelConfig = Config.BaloLevels[baseName] and Config.BaloLevels[baseName][targetCapdo]
		if not levelConfig or not levelConfig.tyle then
			debugPrint("  -> No level config for target (baseName:", baseName, "Capdo:", targetCapdo, ")")
		else
			-- Kiểm tra xem item có phải là clothing material hoặc bua_may_man không
			local isClothingMaterial = IsUpgradeMaterial(v.name)
			if v.name == "bua_may_man" then
				shouldAdd = true
				debugPrint("  -> ADDED whitelist: bua_may_man")
			elseif isClothingMaterial then
				-- Phải có fromGacha = true mới dùng làm phôi nâng cấp
				if not v.metadata or not v.metadata.fromGacha then
					debugPrint(string.format("  -> Skipped: %s không có fromGacha", v.name))
				else
					-- Lấy rarity từ metadata
					local doHiem = v.metadata and v.metadata.DoHiem or "Common"
					if levelConfig.tyle[doHiem] then
						shouldAdd = true
						debugPrint(string.format("  -> ADDED: %s (rarity: %s) gives %s%%", v.name, doHiem, levelConfig.tyle[doHiem]))
					end
				end
			else
				debugPrint(string.format("  -> Not a clothing material: %s", v.name))
			end
		end
		
		if shouldAdd then
			v.slot = k
			-- Debug: dump metadata keys for material items
			local metaKeys = {}
			if v.metadata then
				for mk, mv in pairs(v.metadata) do
					table.insert(metaKeys, mk .. "=" .. tostring(mv))
				end
			end
			debugPrint(string.format("[xn_dapbalov3] Material item %s metadata: %s", v.name, table.concat(metaKeys, ", ")))
			-- Always compute image URL (force overwrite)
			local playerData = exports.qbx_core:GetPlayerData()
			local gender = playerData.charinfo and playerData.charinfo.gender == 0 and "male" or "female"
			v.metadata.imageurl = GetItemImageUrl(v.name, v.metadata, gender)
			debugPrint(string.format("[xn_dapbalov3] Material %s imageurl: %s", v.name, v.metadata.imageurl))
			table.insert(invData, v)
		end
		
		::continue::
	end
	
	debugPrint(string.format("=== TOTAL ITEMS LOADED: %s ===", #invData))
	SendReactMessage("updateInventory", invData)
end
local listSelected = {}

local function Open()
	debugPrint("[DEBUG] Open() START")
	listSelected = {}
	PlayerData = exports.qbx_core:GetPlayerData()
	
	if not PlayerData then
		debugPrint("[DEBUG] No PlayerData, aborting")
		return
	end
	
	debugPrint("[DEBUG] Loading upgradeable items...")
	-- Load và gửi danh sách items có thể nâng cấp
	local upgradeableItems = LoadUpgradeableItems()
	debugPrint("[DEBUG] Sending updateUpgradeableItems:", #upgradeableItems, "items")
	SendReactMessage("updateUpgradeableItems", upgradeableItems)
	
	debugPrint("[DEBUG] Opening UI focus...")
	-- Mở UI
	SetNuiFocus(true, true)
	debugPrint("[DEBUG] Sending reset...")
	SendReactMessage('reset')
	debugPrint("[DEBUG] Sending setVisible...")
	SendReactMessage("setVisible", true)
	debugPrint("[DEBUG] Sending openUI...")
	SendReactMessage("openUI", {
		gender = PlayerData.charinfo and PlayerData.charinfo.gender == 0 and "male" or "female",
	})
	
	debugPrint("[DEBUG] Open() END - targetItem is:", targetItem and targetItem.name or "nil")
	-- Nếu chưa có target item, không gửi setItemTarget
	if targetItem then
		-- Ensure metadata and Capdo exist
		if not targetItem.metadata then
			targetItem.metadata = {}
		end
		if not targetItem.metadata.Capdo then
			targetItem.metadata.Capdo = 1
		end
		
		-- Add imageurl to target item if not present
		if not targetItem.metadata.imageurl then
			local gender = PlayerData.charinfo.gender == 0 and "male" or "female"
			targetItem.metadata.imageurl = GetItemImageUrl(targetItem.name, targetItem.metadata, gender)
		end
		
		-- Update label với drawable number cho clothing items
		local clothingConfig = Config.componentMapping[targetItem.name]
		if clothingConfig and not clothingConfig.isStackable and targetItem.metadata.drawable then
			local itemInfo = exports.ox_inventory:Items(targetItem.name)
			local baseLabel = (itemInfo and itemInfo.label) or targetItem.name
			targetItem.label = baseLabel .. " " .. tostring(targetItem.metadata.drawable)
		end
		
		-- Load inventory cho target đã chọn
		LoadInventory()
		
		local levelConfig = Config.BaloLevels[targetItem.name] and Config.BaloLevels[targetItem.name][targetItem.metadata.Capdo]

		SendReactMessage("setItemTarget", {
			target = targetItem,
			nextLevel = Config.BaloLevels[targetItem.name][targetItem.metadata.Capdo + 1] and
				(targetItem.metadata.Capdo + 1) or 0,
			nextLevelFail = levelConfig and (levelConfig.downlevel and (levelConfig.failBackTo or math.max(1, targetItem.metadata.Capdo - 1)) or targetItem.metadata.Capdo) or targetItem.metadata.Capdo
		})
	end
end

RegisterNUICallback("hideFrame", function(data, cb)
	isOpen = false
	targetItem = nil
	SetNuiFocus(false, false)
	cb("ok")
end)

-- NUI callback cho việc chọn target item từ panel trái
RegisterNUICallback("selectTargetItem", function(data, cb)
	local slot = data.slot
	local allItems = exports.ox_inventory:GetPlayerItems()
	
	-- Tìm item theo slot
	for k, v in pairs(allItems) do
		if k == slot then
			targetItem = v
			targetItem.slot = k
			
			-- Kiểm tra stackable item và parse level từ tên
			local stackableInfo = ParseStackableItem(targetItem.name)
			local baseName = stackableInfo and stackableInfo.baseName or targetItem.name
			
			-- Ensure metadata exists
			if not targetItem.metadata then
				targetItem.metadata = {}
			end
			
			-- Với stackable items, level lấy từ tên; với clothing lấy từ metadata
			if stackableInfo then
				targetItem.metadata.Capdo = stackableInfo.level
				targetItem.metadata.baseName = stackableInfo.baseName
			elseif not targetItem.metadata.Capdo then
				targetItem.metadata.Capdo = 1
			else
				targetItem.metadata.Capdo = tonumber(targetItem.metadata.Capdo) or 1
			end
			
			-- Add imageurl
			local playerData = exports.qbx_core:GetPlayerData()
			local gender = playerData.charinfo and playerData.charinfo.gender == 0 and "male" or "female"
			if not targetItem.metadata.imageurl then
				targetItem.metadata.imageurl = GetItemImageUrl(targetItem.name, targetItem.metadata, gender)
			end
			
			-- Update label với drawable number cho clothing items
			local clothingConfig = Config.componentMapping[baseName]
			if clothingConfig and not clothingConfig.isStackable and targetItem.metadata.drawable then
				local itemInfo = exports.ox_inventory:Items(targetItem.name)
				local baseLabel = (itemInfo and itemInfo.label) or targetItem.name
				targetItem.label = baseLabel .. " " .. tostring(targetItem.metadata.drawable)
			end
			
			-- Thông báo server về target mới
			TriggerServerEvent("xn-upgrade:selectTarget", slot)
			
			-- Load inventory phù hợp với target mới
			LoadInventory()
			
			-- Gửi thông tin target mới đến UI (dùng baseName để lookup config)
			local itemConfig = Config.BaloLevels[baseName]
			local levelConfig = itemConfig and itemConfig[targetItem.metadata.Capdo]
			
			SendReactMessage("setItemTarget", {
				target = targetItem,
				nextLevel = itemConfig and itemConfig[targetItem.metadata.Capdo + 1] and
					(targetItem.metadata.Capdo + 1) or 0,
				nextLevelFail = levelConfig and (levelConfig.downlevel and (levelConfig.failBackTo or math.max(1, targetItem.metadata.Capdo - 1)) or targetItem.metadata.Capdo) or targetItem.metadata.Capdo
			})
			
			break
		end
	end
	
	cb("ok")
end)

RegisterNUICallback("selectItem", function(data, cb)
	listSelected = data
	-- Kiểm tra targetItem trước khi tính percent
	if not targetItem then
		cb(0)
		return
	end
	-- Enrich data với DoHiem từ actual inventory items
	local allItems = exports.ox_inventory:GetPlayerItems()
	local enrichedData = {}
	for _, v in pairs(data) do
		local doHiem = "Common"
		for slot, item in pairs(allItems) do
			if slot == v.slot then
				doHiem = item.metadata and item.metadata.DoHiem or "Common"
				break
			end
		end
		table.insert(enrichedData, {
			name = v.name,
			quantity = v.quantity or 1,
			DoHiem = doHiem
		})
	end
	cb(CalcPercent(targetItem, enrichedData))
end)

RegisterNUICallback("startUpgrade", function(data, cb)
	debugPrint("[CLIENT] ========================================")
	debugPrint("[CLIENT] NUI Callback startUpgrade called")
	-- data là danh sách materials với quantity: [{name, quantity, slot}]
	local items = {}
	local materials = data or listSelected
	for k, v in pairs(materials) do
		-- Gửi item name và quantity đến server
		table.insert(items, {
			name = v.name,
			quantity = v.quantity or 1,
			slot = v.slot
		})
	end
	debugPrint("[CLIENT] Items to send:", json.encode(items))
	debugPrint("[CLIENT] Number of item types:", #items)
	if #items == 0 then
		Notify("Bạn cần chọn ít nhất 1 món đồ để làm nguyên liệu nâng cấp", "error")
		return cb({
			result = false,
			ready = false
		})
	end
	-- Enrich materials với DoHiem trước khi gọi CalcPercent
	local allItems = exports.ox_inventory:GetPlayerItems()
	local enrichedList = {}
	for _, v in pairs(materials) do
		local doHiem = "Common"
		for slot, item in pairs(allItems) do
			if slot == v.slot then
				doHiem = item.metadata and item.metadata.DoHiem or "Common"
				break
			end
		end
		table.insert(enrichedList, {
			name = v.name,
			quantity = v.quantity or 1,
			DoHiem = doHiem
		})
	end
	local upgradeChance = CalcPercent(targetItem, enrichedList)
	debugPrint("[CLIENT] Upgrade chance:", upgradeChance)
	if upgradeChance <= 0 then
		Notify("Tỉ lệ nâng cấp quá thấp (0%), vui lòng chọn thêm nguyên liệu", "error")
		return cb({
			result = false,
			ready = false
		})
	end
	debugPrint("[CLIENT] Calling server callback...")
	LocalPlayer.state:set("inv_busy", true, true)
	local result, newItemData = lib.callback.await("qb-upgrade-bag:startUpgrade", false, items)
	debugPrint("[CLIENT] Server callback result:", result)
	debugPrint("[CLIENT] New item data:", json.encode(newItemData or {}))
	LocalPlayer.state:set("inv_busy", false, true)
	cb({
		result = result,
		ready = true,
		newItemData = newItemData
	})
	debugPrint("[CLIENT] ========================================")
end)

local autoClaimDone = false

-- Auto claim: server add item vào inventory sau 3s, NUI không thay đổi
RegisterNUICallback("autoClaimItem", function(data, cb)
	debugPrint("[CLIENT] Auto claiming upgraded item (silent)...")
	local success = lib.callback.await("qb-upgrade-bag:claimItem", false)
	debugPrint("[CLIENT] Auto claim result:", success)
	
	if success then
		autoClaimDone = true
		TriggerServerEvent("qb-clothes:loadPlayerSkin")
		Wait(500)
		
		-- Reset target item và reload danh sách items
		targetItem = nil
		listSelected = {}
		
		-- Reload danh sách items có thể nâng cấp
		local upgradeableItems = LoadUpgradeableItems()
		SendReactMessage("updateUpgradeableItems", upgradeableItems)
		-- KHÔNG send reset - giữ NUI hiển thị kết quả
	end
	cb("ok")
end)

-- Player click nút claim: nếu đã auto claim thì chỉ reset NUI, nếu chưa thì claim + reset
RegisterNUICallback("claimUpgradedItem", function(data, cb)
	debugPrint("[CLIENT] Claiming upgraded item...")
	
	if autoClaimDone then
		-- Đã auto claim rồi, chỉ reset NUI
		debugPrint("[CLIENT] Already auto-claimed, just resetting NUI")
		autoClaimDone = false
		cb("ok")
		SendReactMessage('reset')
		SendReactMessage("updateInventory", {})
		return
	end
	
	local success = lib.callback.await("qb-upgrade-bag:claimItem", false)
	debugPrint("[CLIENT] Claim result:", success)
	
	if success then
		cb("ok")
		TriggerServerEvent("qb-clothes:loadPlayerSkin")
		Wait(500)
		
		-- Reset target item và reload danh sách items
		targetItem = nil
		listSelected = {}
		
		-- Reload danh sách items có thể nâng cấp
		local upgradeableItems = LoadUpgradeableItems()
		SendReactMessage("updateUpgradeableItems", upgradeableItems)
		
		-- Send reset để xóa item đang nâng cấp
		SendReactMessage('reset')
		
		-- Xóa inventory nguyên liệu vì chưa chọn target
		SendReactMessage("updateInventory", {})
	else
		cb("error")
		Notify("Không thể nhận item, vui lòng thử lại", "error")
	end
end)

RegisterNUICallback("qb-upgrade-bag:getPossibleRewards", function(data, cb)
	debugPrint("[CLIENT] getPossibleRewards callback called with data:", json.encode(data))
	local rewards = lib.callback.await("qb-upgrade-bag:getPossibleRewards", false, data)
	debugPrint("[CLIENT] Received rewards count:", #rewards)
	if #rewards > 0 then
		debugPrint("[CLIENT] First reward sample:", json.encode(rewards[1]))
	end
	cb(rewards)
end)

RegisterNUICallback("endUpgrade", function(data, cb)
	cb("ok")
	TriggerServerEvent("qb-clothes:loadPlayerSkin")

	Wait(500) -- Đợi server cập nhật metadata
	
	-- Reset target item và reload danh sách items
	targetItem = nil
	listSelected = {}
	
	-- Reload danh sách items có thể nâng cấp
	local upgradeableItems = LoadUpgradeableItems()
	SendReactMessage("updateUpgradeableItems", upgradeableItems)
	
	-- Send reset để xóa item đang nâng cấp
	SendReactMessage('reset')
	
	-- Xóa inventory nguyên liệu vì chưa chọn target
	SendReactMessage("updateInventory", {})
end)

function WaitForModel(model)
	if not IsModelValid(model) then
		return;
	end;
	if not HasModelLoaded(model) then
		RequestModel(model);
	end;
	while not HasModelLoaded(model) do
		Citizen.Wait(0);
	end;
end;

WaitForModel(0x49EA5685);

-- Không cần SelectTarget menu nữa - mở UI trực tiếp

for k, v in pairs(Config.Locations) do
	local BLIP = AddBlipForCoord(v.x, v.y, v.z)
	SetBlipSprite(BLIP, 566)
	SetBlipDisplay(BLIP, 4)
	SetBlipScale(BLIP, 0.6)
	SetBlipAsShortRange(BLIP, true)
	SetBlipColour(BLIP, 5)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName("[~y~Nâng Cấp Vật Phẩm~s~]")
	EndTextCommandSetBlipName(BLIP)

	local propHash = `prop_tablesaw_01`
	RequestModel(propHash)
	while not HasModelLoaded(propHash) do
		Wait(1)
	end
        
	local prop = CreateObject(propHash, v.x, v.y, v.z - 1.0, false, false, false)
	SetEntityHeading(prop, v.w)
	FreezeEntityPosition(prop, true)
	SetEntityInvincible(prop, true)
        
	-- Lưu prop để cleanup sau này
	createdProps[k] = prop
        -- Thêm ox_target cho prop
	exports.ox_target:addLocalEntity(prop, {
		{
			name = 'upgrade_bag',
			icon = 'fas fa-hammer',
			label = 'Nâng cấp vật phẩm',
			onSelect = function(data)
				if IsPedAPlayer(data.entity) then return end
				-- Mở UI trực tiếp, không cần menu chọn item
				targetItem = nil -- Reset target khi mở mới
				Open()
			end,
			canInteract = function(entity, distance, coords, name, bone)
				if IsPedAPlayer(entity) then return false end
				return true
			end,
			distance = 3.0
		},
		{
			name = 'nangthu',
			event = 'vie-chamsocthucung:client:OpenUpgradeUI',
			icon = 'fas fa-hammer',
			label = 'Nâng cấp nuôi thú',
			distance = 3.0
		}
	})
        
     SetModelAsNoLongerNeeded(propHash)
end



-- Add this at the bottom of the file
RegisterNetEvent("qb-upgrade-bag:showCelebration", function(coords)
	-- Play celebration sound
	PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)

	-- Spawn fireworks
	local fireworkTypes = {
		"scr_indep_firework_fountain",
		"scr_indep_firework_starburst",
		"scr_indep_firework_shotburst"
	}

	RequestNamedPtfxAsset("scr_indep_fireworks")
	while not HasNamedPtfxAssetLoaded("scr_indep_fireworks") do
		Wait(1)
	end

	for i = 1, 3 do
		UseParticleFxAssetNextCall("scr_indep_fireworks")
		local firework = StartParticleFxLoopedAtCoord(fireworkTypes[i],
			coords.x, coords.y, coords.z + 5.0,
			0.0, 0.0, 0.0, 1.0, false, false, false, false)

		-- Stop particle after 3 seconds
		SetTimeout(3000, function()
			StopParticleFxLooped(firework, 0)
		end)

		Wait(500) -- Space out the fireworks
	end
end)

RegisterNetEvent("qb-upgrade-bag:showFailure", function(coords)
	-- Only play sound if player is within 10.0 units of the effect
	local playerCoords = GetEntityCoords(PlayerPedId())
	local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))

	if distance <= 10.0 then
		-- Calculate volume based on distance (1.0 at 0 distance, 0.0 at 10.0 distance)
		local volume = 1.0 - (distance / 10.0)
		PlaySoundFrontend(-1, "Bed", "WastedSounds", volume)
	end

	-- ...existing smoke effect code...
	RequestNamedPtfxAsset("core")
	while not HasNamedPtfxAssetLoaded("core") do
		Wait(1)
	end

	UseParticleFxAssetNextCall("core")
	local smoke = StartParticleFxLoopedAtCoord("exp_grd_bzgas_smoke",
		coords.x, coords.y, coords.z + 0.5,
		0.0, 0.0, 0.0, 0.3,
		false, false, false, false)

	SetTimeout(3000, function()
		StopParticleFxLooped(smoke, 0)
	end)
end)
