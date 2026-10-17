QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = exports.ox_inventory

-- ANTI-SPAM: Bảng khóa chống người chơi gửi event chế tạo liên tục
local CraftingPlayers = {}
local CRAFT_LOCK_TIMEOUT = 10000  -- 10 giây tự động mở khóa nếu có lỗi

local function LockPlayerCraft(playerId, pendingItem, chance)
    if CraftingPlayers[playerId] then return false end
    CraftingPlayers[playerId] = {
        time       = GetGameTimer(),
        pendingItem = tostring(pendingItem or ''),
        chance     = math.max(0, math.min(100, tonumber(chance) or 100))
    }
    SetTimeout(CRAFT_LOCK_TIMEOUT, function()
        if CraftingPlayers[playerId] then
            print('^3[ANTI-SPAM] Tự động mở khóa player ' .. playerId .. ' sau timeout^0')
            CraftingPlayers[playerId] = nil
        end
    end)
    return true
end

local function UnlockPlayerCraft(playerId)
    CraftingPlayers[playerId] = nil
end

-- Helper function: Get weapon rarity from level (giống XNClothes GetDoHiemByDrawable)
function GetWeaponRarity(weaponLevel)
    local level = tonumber(weaponLevel) or 1
    return Config.WeaponRarity[level] or 'Common'
end

local function GenerateText(num)
	local str
	repeat str = {}
		for i = 1, num do str[i] = string.char(math.random(65, 90)) end
		str = table.concat(str)
	until str ~= 'POL' and str ~= 'EMS'
	return str
end

local function GenerateSerial(text)
	if text and text:len() > 3 then
		return text
	end

	-- Format: CT230326GKJ084922 (CT + năm tháng ngày + 3 chữ random + giờ phút giây)
	local date = os.date("*t")
	local year = string.format("%02d", date.year % 100)  -- 2 số cuối năm
	local month = string.format("%02d", date.month)       -- tháng 2 số
	local day = string.format("%02d", date.day)           -- ngày 2 số
	local hour = string.format("%02d", date.hour)         -- giờ 2 số
	local min = string.format("%02d", date.min)           -- phút 2 số
	local sec = string.format("%02d", date.sec)           -- giây 2 số
	local randomText = GenerateText(3)                    -- 3 chữ cái random

	return ('%s%s%s%s%s%s'):format(year, month, day, randomText, hour, min, sec)
end

function CoItem(source, items, amount)
	local hasItem = exports.ox_inventory:Search(source, "count", items)
    if hasItem >= amount then
		return true
	else
		return false
	end
end

-- Helper function: Tìm config của item trong danh sách bàn chế tạo
local function GetCraftItemConfig(itemName)
    for _, craftTable in ipairs(Config) do
        if craftTable.Categories then
            for _, cat in ipairs(craftTable.Categories) do
                if cat.Items then
                    for _, itm in ipairs(cat.Items) do
                        if itm.Item == itemName then
                            return itm
                        end
                    end
                end
            end
        end
    end
    return nil
end

RegisterServerEvent('vierp.craftingx:cfx:remove')
AddEventHandler('vierp.craftingx:cfx:remove', function(multiply, cash, items, lucky, pendingItem, chance, permItems)
    local playerId = source
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end

    -- ANTI-SPAM: Chặn nếu player đang trong quá trình chế tạo khác
    if not LockPlayerCraft(playerId, pendingItem, chance) then
        print('^1[ANTI-SPAM] cfx:remove bị chặn cho player ' .. playerId .. ' - đang chế tạo^0')
        return
    end

    -- SECURITY: Validate server-side TRƯỚC khi trừ (chặn gửi items rỗng hoặc không đủ)
    local multiplyN = math.max(1, math.floor(tonumber(multiply) or 1))
    local cashN     = math.max(0, tonumber(cash) or 0)

    if cashN > 0 and Player.PlayerData.money.cash < cashN * multiplyN then
        print('^1[SECURITY] cfx:remove: không đủ tiền - player ' .. playerId .. '^0')
        UnlockPlayerCraft(playerId)
        return
    end

    for k, v in pairs(items or {}) do
        local need = math.max(0, tonumber(v[2]) or 0)
        if need <= 0 then
            print('^1[SECURITY] cfx:remove: amount <= 0 cho item ' .. tostring(k) .. ' - player ' .. playerId .. '^0')
            UnlockPlayerCraft(playerId)
            return
        end
        local has = exports.ox_inventory:Search(playerId, 'count', k)
        if has < need * multiplyN then
            print('^1[SECURITY] cfx:remove: không đủ ' .. tostring(k) .. ' (có ' .. has .. ' cần ' .. (need * multiplyN) .. ') - player ' .. playerId .. '^0')
            UnlockPlayerCraft(playerId)
            return
        end
    end

    if permItems and type(permItems) == 'table' then
        for k, v in pairs(permItems) do
            local need = math.max(0, tonumber(v[2]) or 0)
            if need > 0 then
                local has = exports.ox_inventory:Search(playerId, 'count', k)
                if has < need * multiplyN then
                    print('^1[SECURITY] cfx:remove: không đủ PermItem ' .. tostring(k) .. ' (có ' .. has .. ' cần ' .. (need * multiplyN) .. ') - player ' .. playerId .. '^0')
                    UnlockPlayerCraft(playerId)
                    return
                end
            end
        end
    end

    Player.Functions.RemoveMoney('cash', cashN * multiplyN)
    for k, v in pairs(items or {}) do
        exports.ox_inventory:RemoveItem(playerId, k, v[2] * multiplyN)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- SECURITY: Tính kết quả CHẾ TẠO phía SERVER (weapon + item)
-- ═══════════════════════════════════════════════════════════════
RegisterServerEvent('vierp.craftingx:cfx:processResult')
AddEventHandler('vierp.craftingx:cfx:processResult', function(multiply, itemName, itemType, weaponLevel, failedItems, permItems)
    local playerId = source
    local craftData = CraftingPlayers[playerId]

    -- Phải có lock từ cfx:remove
    if not craftData then
        print('^1[SECURITY] cfx:processResult bị chặn - không có lock (player ' .. playerId .. ')^0')
        return
    end

    -- Item name phải khớp với cái đã đăng ký trong cfx:remove
    if craftData.pendingItem ~= tostring(itemName or '') then
        print('^1[SECURITY] cfx:processResult item không khớp: ' .. tostring(itemName) .. ' vs ' .. tostring(craftData.pendingItem) .. ' (player ' .. playerId .. ')^0')
        UnlockPlayerCraft(playerId)
        return
    end

    local itemConfig = GetCraftItemConfig(itemName)
    local serverChance = craftData.chance
    math.randomseed(os.time() + playerId + GetGameTimer())
    local roll = math.random(1, 100)
    UnlockPlayerCraft(playerId)

    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return end

    -- Xử lý kiểm tra metadata success cho PermItems (nếu config có yêu cầu Success)
    local hasSuccessReq = itemConfig and itemConfig.Success and tonumber(itemConfig.Success) and tonumber(itemConfig.Success) > 0
    local targetPermSlot = nil
    local targetPermItem = nil
    local targetPermName = nil
    local currentSuccess = 0
    local meetsSuccessReq = true

    if hasSuccessReq and itemConfig.PermItems then
        for permKey, _ in pairs(itemConfig.PermItems) do
            local slots = exports.ox_inventory:Search(playerId, 'slots', permKey)
            if slots and #slots > 0 then
                for _, s in pairs(slots) do
                    local sVal = tonumber(s.metadata and s.metadata.success) or 0
                    if not targetPermSlot or sVal > currentSuccess then
                        targetPermSlot = s.slot
                        targetPermItem = s
                        targetPermName = permKey
                        currentSuccess = sVal
                    end
                end
            end
            if targetPermSlot then break end
        end

        local requiredSuccess = tonumber(itemConfig.Success) or 10
        -- Điều kiện: metadata success > Success (ví dụ: > 10 điểm mới có cơ hội thành công)
        meetsSuccessReq = (currentSuccess > requiredSuccess)
    end

    -- Kết quả thành công cuối cùng: Đủ success (> 10) VÀ roll Chance thành công
    local success = meetsSuccessReq and (roll <= serverChance)

    if success then
        -- Xóa PermItems khi thành công
        if permItems and type(permItems) == 'table' then
            local multiplyN = math.max(1, math.floor(tonumber(multiply) or 1))
            for k, v in pairs(permItems) do
                local count = math.max(0, math.floor(tonumber(v[2]) or 1)) * multiplyN
                if count > 0 then
                    if targetPermSlot and k == targetPermName then
                        exports.ox_inventory:RemoveItem(playerId, k, 1, nil, targetPermSlot)
                        if count > 1 then
                            exports.ox_inventory:RemoveItem(playerId, k, count - 1)
                        end
                    else
                        exports.ox_inventory:RemoveItem(playerId, k, count)
                    end
                end
            end
        end

        if itemType == 'weapon' then
            local level    = math.max(1, math.floor(tonumber(weaponLevel) or 1))
            local serialRD = Config.Textserial .. GenerateSerial()
            local metaData = { serial = serialRD, durability = 100, level = level, DoHiem = GetWeaponRarity(level), Capdo = level }
            ox_inventory:AddItem(playerId, itemName, 1, metaData)
            lib.logger(playerId, 'CT VU KHI', {
                message = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' [' .. Player.PlayerData.pid .. '] chế tạo: ' .. itemName .. ' Lv' .. level .. ' serial:' .. serialRD .. ' (roll:' .. roll .. '/' .. serverChance .. ', success:' .. currentSuccess .. ')',
                item = itemName, level = level, serial = serialRD, citizenid = Player.PlayerData.pid
            })
            print('[CRAFT-SERVER] ' .. Player.PlayerData.pid .. ' chế tạo ' .. itemName .. ' roll:' .. roll .. '/' .. serverChance .. ' (success:' .. currentSuccess .. ') SUCCESS')
            TriggerClientEvent('vierp.craftingx:craftSuccess', playerId)
            TriggerClientEvent('QBCore:Notify', playerId, 'Chế tạo thành công!', 'success', 3500)
        elseif itemType == 'item' then
            local amt = math.max(1, math.floor(tonumber(multiply) or 1))
            local added = exports.ox_inventory:AddItem(playerId, itemName, amt)
            if not added then
                TriggerClientEvent('QBCore:Notify', playerId, 'Không thể thêm vật phẩm vào túi!', 'error', 3500)
                return
            end
            TriggerClientEvent('UpdateQuest', playerId, 'quest_crafting', 1)
            lib.logger(playerId, 'CHE TAO ITEM', {
                message = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' [' .. Player.PlayerData.pid .. '] chế tạo: ' .. amt .. 'x ' .. itemName .. ' (roll:' .. roll .. '/' .. serverChance .. ')',
                item = itemName, amount = amt, citizenid = Player.PlayerData.pid
            })
            print('[CRAFT-SERVER] ' .. Player.PlayerData.pid .. ' chế tạo ' .. amt .. 'x ' .. itemName .. ' roll:' .. roll .. '/' .. serverChance .. ' SUCCESS')
            TriggerClientEvent('vierp.craftingx:craftSuccess', playerId)
            TriggerClientEvent('QBCore:Notify', playerId, 'Chế tạo thành công!', 'success', 3500)
        end
    else
        -- Thất bại: PermItems KHÔNG bị trừ, mà CỘNG +1 SUCCESS nếu có yêu cầu Success
        if hasSuccessReq and targetPermSlot and targetPermItem then
            local newSuccess = currentSuccess + 1
            local updatedMeta = targetPermItem.metadata or {}
            updatedMeta.success = newSuccess
            exports.ox_inventory:SetMetadata(playerId, targetPermSlot, updatedMeta)
            
            if not meetsSuccessReq then
                TriggerClientEvent('QBCore:Notify', playerId, 'Nâng cấp thất bại! Cờ lê +1 điểm (Hiện tại: ' .. newSuccess .. ' / Cần > ' .. (itemConfig.Success or 10) .. ' để có tỷ lệ thành công)', 'error', 4500)
            else
                TriggerClientEvent('QBCore:Notify', playerId, 'Nâng cấp thất bại (Tỷ lệ: ' .. serverChance .. '%)! Cờ lê +1 điểm (Hiện tại: ' .. newSuccess .. ')', 'error', 4500)
            end
            print('[CRAFT-SERVER] ' .. Player.PlayerData.pid .. ' nâng cấp ' .. tostring(itemName) .. ' FAIL -> ' .. tostring(targetPermName) .. ' success: ' .. currentSuccess .. ' -> ' .. newSuccess)
        else
            TriggerClientEvent('QBCore:Notify', playerId, 'Chế tạo thất bại!', 'error', 3500)
            print('[CRAFT-SERVER] ' .. Player.PlayerData.pid .. ' chế tạo ' .. tostring(itemName) .. ' roll:' .. roll .. '/' .. serverChance .. ' FAIL')
        end

        -- Hoàn lại failed items nếu có cấu hình
        if failedItems and type(failedItems) == 'table' then
            for k, v in pairs(failedItems) do
                local amount = math.max(0, math.floor(tonumber(v) or 0))
                if amount > 0 then exports.ox_inventory:AddItem(playerId, k, amount) end
            end
        end
    end
end)

RegisterServerEvent('vierp.craftingx:cfx:remove2')
AddEventHandler('vierp.craftingx:cfx:remove2', function(multiply, items)
    local playerId = source
    if not items or type(items) ~= 'table' then return end
    local multiplyN = math.max(1, math.floor(tonumber(multiply) or 1))
    
    for k, v in pairs(items) do
        local count = math.max(0, math.floor(tonumber(v[2]) or 1)) * multiplyN
        if count > 0 then
            exports.ox_inventory:RemoveItem(playerId, k, count)
        end
    end
end)

-- Xóa vũ khí theo slot và serial để đảm bảo xóa đúng vũ khí
RegisterServerEvent('vierp.craftingx:cfx:removeWeapons')
AddEventHandler('vierp.craftingx:cfx:removeWeapons', function(weaponsToRemove, removeCount)
    local playerId = source
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    -- Xóa tất cả vũ khí trong danh sách
    local actualRemoveCount = math.min(#weaponsToRemove, removeCount or #weaponsToRemove)

    -- Kiểm tra tất cả vũ khí phôi phải có số seri hợp lệ bắt đầu bằng "MI" (đọc trực tiếp từ slot inventory)
    local invData = exports.ox_inventory:GetInventory(source)
    if not (invData and invData.items) then
        TriggerClientEvent('ox_lib:notify', playerId, { type = 'error', description = 'Lỗi đọc inventory!' })
        return
    end

    for i = 1, actualRemoveCount do
        local weapon = weaponsToRemove[i]
        if weapon and weapon.slot then
            local invItem = invData.items[weapon.slot]
            if not (invItem and invItem.metadata and type(invItem.metadata.serial) == 'string' and invItem.metadata.serial:find('^MI')) then
                TriggerClientEvent('ox_lib:notify', playerId, {
                    type = 'error',
                    description = 'Số seri không hợp lệ!'
                })
                return
            end
        end
    end

    for i = 1, actualRemoveCount do
        local weapon = weaponsToRemove[i]
        if weapon and weapon.slot then
            -- Xóa item theo slot
            local removed = exports.ox_inventory:RemoveItem(playerId, weapon.name, 1, nil, weapon.slot)
            
            if removed then
                local weaponType = weapon.isMainWeapon and '(Vũ khí chính)' or '(Vũ khí phụ)'
                -- Log console và ox_lib
                lib.logger(playerId, 'XOA VU KHI NANG CAP', {
                    message = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã sử dụng vũ khí để nâng cấp: " .. weapon.name .. " " .. weaponType .. " (Serial: " .. weapon.serial .. ", Độ bền: " .. weapon.durability .. "%)",
                    weapon = weapon.name,
                    serial = weapon.serial,
                    durability = weapon.durability,
                    isMainWeapon = weapon.isMainWeapon,
                    citizenid = Player.PlayerData.pid
                })
                print("[CRAFTING] Đã xóa vũ khí " .. weaponType .. ": " .. weapon.name .. " (Serial: " .. weapon.serial .. ")")
            end
        end
    end
end)


RegisterServerEvent('vierp.craftingx:cfx:upgradeWeapon')
AddEventHandler('vierp.craftingx:cfx:upgradeWeapon', function(parentWeapon, newWeapon, weaponLevel)
    local playerId = source
    local Player = QBCore.Functions.GetPlayer(playerId)

    -- Kiểm tra vũ khí chính cần nâng cấp phải có số seri hợp lệ bắt đầu bằng "MI"
    local parentSlots = exports.ox_inventory:Search(playerId, 'slots', parentWeapon:lower())
    local validParentSerial = false
    if parentSlots and type(parentSlots) == 'table' then
        for _, slot in ipairs(parentSlots) do
            if slot.metadata and type(slot.metadata.serial) == 'string' and slot.metadata.serial:find('^MI') then
                validParentSerial = true
                break
            end
        end
    end
    if not validParentSerial then
        TriggerClientEvent('ox_lib:notify', playerId, {
            type = 'error',
            description = 'Số seri không hợp lệ!'
        })
        return
    end

    local serialRD = Config.Textserial..GenerateSerial()
    local level = weaponLevel or 2  -- Default level 2 nếu không truyền

    if Env.Debug then
        print('DEBUG : Removed ' .. parentWeapon:upper())
        print('DEBUG : Added ' .. newWeapon:upper() .. ' Level ' .. level)
    end

    -- Xóa vũ khí cũ
    Player.Functions.RemoveItem(parentWeapon:upper(), 1)
    
    -- Tạo metadata với level và DoHiem giống addWeapon
    local metaData = {
        serial = serialRD,
        durability = 100,
        level = level,
        DoHiem = GetWeaponRarity(level)  -- Set DoHiem để hiển thị màu theo level
    }
    
    -- Thêm vũ khí mới VỚI METADATA
    ox_inventory:AddItem(source, newWeapon, 1, metaData)
    
    -- Log ox_lib
    lib.logger(playerId, 'NANG CAP VU KHI', {
        message = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã nâng cấp: " .. newWeapon .. " Level " .. level .. " với serial: " .. serialRD,
        weapon = newWeapon,
        level = level,
        serial = serialRD,
        citizenid = Player.PlayerData.pid
    })
    
    -- Log console
    print(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã nâng cấp: " .. newWeapon .. " từ Level " .. (weaponLevel-1 or 1) .. " → Level " .. level .. " với serial: " .. serialRD)
    
    -- Gửi Discord webhook
    if Config.DiscordLogs and Config.DiscordLogs.link then
        local embedData = {
            {
                ["title"] = "⬆️ Nâng Cấp Vũ Khí",
                ["color"] = 3447003,  -- Màu xanh dương cho upgrade
                ["fields"] = {
                    {
                        ["name"] = "👤 Người chơi",
                        ["value"] = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🆔 ID",
                        ["value"] = Player.PlayerData.pid or "N/A",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🔫 Vũ khí cũ",
                        ["value"] = parentWeapon .. " (Level " .. (level-1) .. ")",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "✨ Vũ khí mới",
                        ["value"] = newWeapon .. " (Level " .. level .. ")",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🔢 Serial Number",
                        ["value"] = serialRD,
                        ["inline"] = false
                    },
                    {
                        ["name"] = "📅 Ngày nâng cấp",
                        ["value"] = os.date("%d/%m/%Y lúc %H:%M:%S"),
                        ["inline"] = false
                    },
                },
                ["footer"] = {
                    ["text"] = Config.DiscordLogs.communityName or "Mini City",
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
            }
        }
        
        PerformHttpRequest(Config.DiscordLogs.link, function(err, text, headers) end, 'POST', json.encode({
            username = Config.DiscordLogs.username or "crafting-logs",
            avatar_url = Config.DiscordLogs.avatar,
            embeds = embedData
        }), { ['Content-Type'] = 'application/json' })
    end
end)


RegisterServerEvent('vierp.craftingx:cfx:upgradeWeaponSuccess')
AddEventHandler('vierp.craftingx:cfx:upgradeWeaponSuccess', function(targetWeapon, targetLevel, materials, requireConfig, weaponsUsed)
    local playerId = source
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    -- Tạo chuỗi nguyên liệu đã dùng
    local materialsUsed = {}
    for itemName, itemData in pairs(materials or {}) do
        table.insert(materialsUsed, itemData[1] .. " x" .. itemData[2])
    end
    local materialsStr = table.concat(materialsUsed, ", ")
    
    -- Tạo chuỗi công thức vũ khí
    local recipeStr = "Không rõ"
    if requireConfig then
        local mainWeapon = requireConfig.RequiredWeapon or targetWeapon
        local mainLevel = requireConfig.RequiredLevel or (targetLevel - 1)
        local additionalCount = requireConfig.AdditionalCount or 0
        recipeStr = "**1x " .. mainWeapon .. " Level " .. mainLevel .. "**"
        if additionalCount > 0 then
            recipeStr = recipeStr .. " + **" .. additionalCount .. "x vũ khí phụ**"
        end
    end
    
    -- Tạo chuỗi thông tin vũ khí đã xóa (serial, độ bền)
    local weaponsUsedStr = "Không có"
    local weaponsUsedDetails = {}
    if weaponsUsed and #weaponsUsed > 0 then
        for i, weapon in ipairs(weaponsUsed) do
            local weaponType = weapon.isMainWeapon and '(Vũ khí chính)' or '(Vũ khí phụ)'
            local durability = math.floor(tonumber(weapon.durability) or 0)
            local info = string.format("%s %s - Serial: %s, Độ bền: %d%%", 
                weapon.name or "Unknown", 
                weaponType,
                weapon.serial or "N/A", 
                durability
            )
            table.insert(weaponsUsedDetails, info)
        end
        weaponsUsedStr = table.concat(weaponsUsedDetails, " | ")
    end
    
    -- Log ox_lib
    lib.logger(playerId, 'NANG CAP THANH CONG', {
        message = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] thành công nâng cấp: " .. targetWeapon .. " lên Level " .. targetLevel,
        weapon = targetWeapon,
        targetLevel = targetLevel,
        materialsUsed = materialsStr,
        recipe = recipeStr,
        weaponsUsed = weaponsUsedStr,
        citizenid = Player.PlayerData.pid
    })
    
    -- Log console
    print(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] THÀNH CÔNG nâng cấp: " .. targetWeapon .. " lên Level " .. targetLevel .. " | Dùng: " .. materialsStr .. " | Vũ khí xóa: " .. weaponsUsedStr)
    
    -- Gửi Discord webhook (embed đẹp)
    if Config.DiscordLogs and Config.DiscordLogs.link then
        local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        local embedData = {
            {
                ["title"] = "✅ Nâng Cấp Thành Công",
                ["color"] = 5763719,  -- Màu xanh lá
                ["fields"] = {
                    {
                        ["name"] = "👤 Người chơi",
                        ["value"] = playerName,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🆔 Citizen ID",
                        ["value"] = Player.PlayerData.pid or "N/A",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🔫 Vũ khí",
                        ["value"] = targetWeapon .. " (Level " .. (targetLevel-1) .. " → Level " .. targetLevel .. ")",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🗡️ Vũ khí đã xóa",
                        ["value"] = weaponsUsedStr,
                        ["inline"] = false
                    },
                    {
                        ["name"] = "📦 Nguyên liệu sử dụng",
                        ["value"] = materialsStr,
                        ["inline"] = false
                    },
                },
                ["footer"] = {
                    ["text"] = Config.DiscordLogs.communityName or "Mini City",
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
            }
        }
        
        PerformHttpRequest(Config.DiscordLogs.link, function(err, text, headers) end, 'POST', json.encode({
            username = Config.DiscordLogs.username or "crafting-logs",
            avatar_url = Config.DiscordLogs.avatar,
            embeds = embedData
        }), { ['Content-Type'] = 'application/json' })
    end
end)


RegisterServerEvent('vierp.craftingx:cfx:upgradeWeaponFailed')
AddEventHandler('vierp.craftingx:cfx:upgradeWeaponFailed', function(targetWeapon, targetLevel, materials, requireConfig, weaponsUsed)
    local playerId = source
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    print("^3[DEBUG] upgradeWeaponFailed event triggered!^0")
    print("^3[DEBUG] targetWeapon: " .. tostring(targetWeapon) .. "^0")
    print("^3[DEBUG] targetLevel: " .. tostring(targetLevel) .. "^0")
    
    -- Tạo chuỗi nguyên liệu đã mất
    local materialsLost = {}
    for itemName, itemData in pairs(materials or {}) do
        table.insert(materialsLost, itemData[1] .. " x" .. itemData[2])
    end
    local materialsStr = table.concat(materialsLost, ", ")
    
    -- Tạo chuỗi công thức vũ khí
    local recipeStr = "Không rõ"
    if requireConfig then
        local mainWeapon = requireConfig.RequiredWeapon or targetWeapon
        local mainLevel = requireConfig.RequiredLevel or (targetLevel - 1)
        local additionalCount = requireConfig.AdditionalCount or 0
        recipeStr = "**1x " .. mainWeapon .. " Level " .. mainLevel .. "**"
        if additionalCount > 0 then
            recipeStr = recipeStr .. " + **" .. additionalCount .. "x vũ khí phụ**"
        end
    end
    
    -- Tạo chuỗi thông tin vũ khí đã dùng (serial, độ bền)
    local weaponsUsedStr = "Không có"
    local weaponsUsedDetails = {}
    if weaponsUsed and #weaponsUsed > 0 then
        for i, weapon in ipairs(weaponsUsed) do
            local weaponType = weapon.isMainWeapon and '(Vũ khí chính)' or '(Vũ khí phụ)'
            local durability = math.floor(tonumber(weapon.durability) or 0)
            local info = string.format("%s %s - Serial: %s, Độ bền: %d%%", 
                weapon.name or "Unknown", 
                weaponType,
                weapon.serial or "N/A", 
                durability
            )
            table.insert(weaponsUsedDetails, info)
        end
        weaponsUsedStr = table.concat(weaponsUsedDetails, " | ")
    end
    
    -- Log ox_lib
    lib.logger(playerId, 'NANG CAP THAT BAI', {
        message = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] thất bại khi nâng cấp: " .. targetWeapon .. " lên Level " .. targetLevel,
        weapon = targetWeapon,
        targetLevel = targetLevel,
        materialsLost = materialsStr,
        recipe = recipeStr,
        weaponsUsed = weaponsUsedStr,
        citizenid = Player.PlayerData.pid
    })
    
    -- Log console
    print(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] THẤT BẠI nâng cấp: " .. targetWeapon .. " lên Level " .. targetLevel .. " | Mất: " .. materialsStr .. " | Vũ khí dùng: " .. weaponsUsedStr)
    
    -- Gửi Discord webhook (embed đẹp)
    if Config.DiscordLogs and Config.DiscordLogs.link then
        local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        local embedData = {
            {
                ["title"] = "❌ Nâng Cấp Thất Bại",
                ["color"] = 15158332,  -- Màu đỏ
                ["fields"] = {
                    {
                        ["name"] = "👤 Người chơi",
                        ["value"] = playerName,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🆔 Citizen ID",
                        ["value"] = Player.PlayerData.pid or "N/A",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🔫 Vũ khí",
                        ["value"] = targetWeapon .. " (Level " .. (targetLevel-1) .. " → Level " .. targetLevel .. ")",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "💔 Vũ khí đã dùng (GIỮ NGUYÊN)",
                        ["value"] = weaponsUsedStr,
                        ["inline"] = false
                    },
                    {
                        ["name"] = "📦 Nguyên liệu đã mất",
                        ["value"] = materialsStr,
                        ["inline"] = false
                    },
                },
                ["footer"] = {
                    ["text"] = Config.DiscordLogs.communityName or "Mini City",
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
            }
        }
        
        PerformHttpRequest(Config.DiscordLogs.link, function(err, text, headers) end, 'POST', json.encode({
            username = Config.DiscordLogs.username or "crafting-logs",
            avatar_url = Config.DiscordLogs.avatar,
            embeds = embedData
        }), { ['Content-Type'] = 'application/json' })
    end
end)


RegisterServerEvent('vierp.craftingx:cfx:addWeapon')
AddEventHandler('vierp.craftingx:cfx:addWeapon', function(weapon, weaponLevel)
    local playerId = source
    local craftData = CraftingPlayers[playerId]

    -- SECURITY: Chỉ cho phép nếu có lock từ cfx:remove VÀ item name khớp
    if not craftData then
        print('^1[SECURITY] cfx:addWeapon bị chặn - không có lock (player ' .. playerId .. ')^0')
        return
    end
    if craftData.pendingItem ~= '' and craftData.pendingItem ~= tostring(weapon or '') then
        print('^1[SECURITY] cfx:addWeapon item không khớp: ' .. tostring(weapon) .. ' vs ' .. tostring(craftData.pendingItem) .. ' (player ' .. playerId .. ')^0')
        UnlockPlayerCraft(playerId)
        return
    end

    local Player = QBCore.Functions.GetPlayer(playerId)
    local level = weaponLevel or 1
    UnlockPlayerCraft(playerId)

    -- Nếu là upgrade (level > 1), kiểm tra vũ khí gốc còn trong túi phải có seri MI
    if level > 1 then
        local invData = exports.ox_inventory:GetInventory(source)
        local hasValidWeapon = false
        if invData and invData.items then
            for _, invItem in pairs(invData.items) do
                if invItem and string.upper(invItem.name) == string.upper(weapon) then
                    if invItem.metadata and type(invItem.metadata.serial) == 'string' and invItem.metadata.serial:find('^MI') then
                        hasValidWeapon = true
                        break
                    end
                end
            end
        end
        -- Nếu không còn vũ khí gốc hợp lệ (đã bị removeWeapons xóa đúng) thì cho qua
        -- Nếu VẪN còn vũ khí gốc có seri MI trong túi → removeWeapons đã thành công, tiếp tục
        -- Nếu removeWeapons đã fail (vũ khí vẫn còn trong túi nhưng không có seri MI) → chặn
        local stillHasOriginal = false
        if invData and invData.items then
            for _, invItem in pairs(invData.items) do
                if invItem and string.upper(invItem.name) == string.upper(weapon) then
                    stillHasOriginal = true
                    break
                end
            end
        end
        if stillHasOriginal and not hasValidWeapon then
            TriggerClientEvent('ox_lib:notify', playerId, { type = 'error', description = 'Số seri không hợp lệ!' })
            return
        end
    end

    local serialRD = Config.Textserial..GenerateSerial()
    
    -- Tạo metadata với level
    local metaData = {
        serial = serialRD,
        durability = 100,
        level = level,
        DoHiem = GetWeaponRarity(level),
        Capdo = level
    }
    
    ox_inventory:AddItem(source, weapon, 1, metaData)
    
    -- Log console và ox_lib
    lib.logger(playerId, 'CT VU KHI', {
        message = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã chế tạo thành công: " .. weapon .. " Level " .. level .. " với serial: " .. serialRD,
        weapon = weapon,
        level = level,
        serial = serialRD,
        citizenid = Player.PlayerData.pid
    })
    print(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã chế tạo: " .. weapon .. " Level " .. level .. " với serial: " .. serialRD)
    
    -- Gửi Discord webhook (chỉ log chế tạo vũ khí Level 1 mới, Level > 1 đã có upgradeWeaponSuccess)
    if Config.DiscordLogs and Config.DiscordLogs.link and level == 1 then        local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        local embedData = {
            {
                ["title"] = "🔫 Chế Tạo Vũ Khí",
                ["color"] = 10181046,  -- Màu tím
                ["fields"] = {
                    {
                        ["name"] = "👤 Người chơi",
                        ["value"] = playerName,
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🆔 Citizen ID",
                        ["value"] = Player.PlayerData.pid or "N/A",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🔫 Vũ khí",
                        ["value"] = weapon .. " (Level " .. level .. ")",
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🔢 Serial Number",
                        ["value"] = serialRD,
                        ["inline"] = true
                    },
                },
                ["footer"] = {
                    ["text"] = Config.DiscordLogs.communityName or "Mini City",
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
            }
        }
        
        PerformHttpRequest(Config.DiscordLogs.link, function(err, text, headers) end, 'POST', json.encode({
            username = Config.DiscordLogs.username or "crafting-logs",
            avatar_url = Config.DiscordLogs.avatar,
            embeds = embedData
        }), { ['Content-Type'] = 'application/json' })
    end

    -- Thông báo + hiệu ứng UI
    local msg = level > 1 and 'Nâng cấp thành công!' or 'Chế tạo thành công!'
    TriggerClientEvent('QBCore:Notify', playerId, msg, 'success', 3500)
    TriggerClientEvent('vierp.craftingx:craftSuccess', playerId)
end)


RegisterServerEvent('vierp.craftingx:cfx:addItem')
AddEventHandler('vierp.craftingx:cfx:addItem', function(multiply, item, data)
    local playerId = source
    local craftData = CraftingPlayers[playerId]

    -- SECURITY: Chỉ cho phép nếu có lock VÀ item name khớp
    if not craftData then
        print('^1[SECURITY] cfx:addItem bị chặn - không có lock (player ' .. playerId .. ')^0')
        return
    end
    if craftData.pendingItem ~= '' and craftData.pendingItem ~= tostring(item or '') then
        print('^1[SECURITY] cfx:addItem item không khớp: ' .. tostring(item) .. ' vs ' .. tostring(craftData.pendingItem) .. ' (player ' .. playerId .. ')^0')
        UnlockPlayerCraft(playerId)
        return
    end

    local Player = QBCore.Functions.GetPlayer(playerId)
    exports.ox_inventory:AddItem(playerId, item, multiply)
    UnlockPlayerCraft(playerId)
    TriggerClientEvent("UpdateQuest", source, "quest_crafting", 1)
    
    -- Log chế tạo item
    lib.logger(playerId, 'CHE TAO ITEM', {
        message = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã chế tạo thành công: " .. multiply .. "x " .. item,
        item = item,
        amount = multiply,
        citizenid = Player.PlayerData.pid
    })
    print(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã chế tạo thành công: " .. multiply .. "x " .. item)
    
    -- Gửi Discord webhook (đơn giản)
    if Config.DiscordLogs and Config.DiscordLogs.link then
        local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        local message = string.format("🔧 **%s** [%s] đã chế tạo: **%dx %s**", 
            playerName, 
            Player.PlayerData.pid or "N/A", 
            multiply, 
            item
        )
        
        PerformHttpRequest(Config.DiscordLogs.link, function(err, text, headers) end, 'POST', json.encode({
            username = Config.DiscordLogs.username or "crafting-logs",
            avatar_url = Config.DiscordLogs.avatar,
            content = message
        }), { ['Content-Type'] = 'application/json' })
    end
end)

RegisterServerEvent('vierp.craftingx:cfx:getFailed')
AddEventHandler('vierp.craftingx:cfx:getFailed', function(items, data)
    local playerId = source
    UnlockPlayerCraft(playerId)  -- Mở khóa khi chế tạo thất bại

    for k, v in pairs(items) do
        exports.ox_inventory:AddItem(playerId, k, v)
    end
end)

QBCore.Functions.CreateCallback('vierp.craftingx:callback:hasWeapon', function(source, cb, weaponName, cashNeed)
    local Player = QBCore.Functions.GetPlayer(source)
    local myCash = Player.PlayerData.money.cash

    local c = true  
    -- print(myCash)
    -- print(cashNeed)
    if myCash < cashNeed and cashNeed > 0 then
        c = false
    end

    local hasWeapon = exports.ox_inventory:Search(source, 'count', weaponName:upper()) > 0
    cb(hasWeapon, c)
end)

QBCore.Functions.CreateCallback('vierp.craftingx:callback:hasMoney', function(source, cb, cashNeed)
    local Player = QBCore.Functions.GetPlayer(source)
    local myCash = Player.PlayerData.money.cash

    local c = true

    if myCash < cashNeed and cashNeed > 0 then
        c = false
    end

    cb(c)
end)

QBCore.Functions.CreateCallback('vierp.craftingx:callback:canCarry', function(source, cb, itemName, itemAmount)
    local Player = QBCore.Functions.GetPlayer(source)
    if Env.InventoryType == 'limit' then
        local item = exports.ox_inventory:Search(source, 'slots', itemName)
        cb(item ~= nil)
    else
        local canCarry = exports.ox_inventory:CanCarryItem(source, itemName, itemAmount)
        cb(canCarry)
    end
end)

-- Callback kiểm tra độ bền vũ khí
QBCore.Functions.CreateCallback('vierp.craftingx:callback:checkWeaponDurability', function(source, cb, requireData, cashNeed)
    local Player = QBCore.Functions.GetPlayer(source)
    local myCash = Player.PlayerData.money.cash
    
    local hasEnoughCash = true
    if myCash < cashNeed and cashNeed > 0 then
        hasEnoughCash = false
    end
    
    -- Kiểm tra độ bền vũ khí với logic mới
    local requiredWeapon = requireData.RequiredWeapon  -- Vũ khí chính bắt buộc
    local requiredLevel = requireData.RequiredLevel or 1  -- Level vũ khí chính
    local additionalCount = requireData.AdditionalCount or 1  -- Số vũ khí phụ cần thêm
    local minDurability = requireData.MinDurability or 30
    local acceptableWeapons = requireData.AcceptableWeapons or {}
    
    -- Tạo bảng tra cứu nhanh cho vũ khí phụ
    local weaponLookup = {}
    for _, weaponName in ipairs(acceptableWeapons) do
        weaponLookup[string.upper(weaponName)] = true
    end
    
    -- Lấy tất cả items trong inventory
    local inventory = exports.ox_inventory:GetInventory(source)
    local mainWeaponFound = false
    local mainWeaponSlot = nil
    local additionalWeapons = {}
    local weaponsToRemove = {}
    local noValidSerial = false  -- Có vũ khí đúng tên/level nhưng thiếu seri hợp lệ
    
    if inventory and inventory.items then
        for slot, item in pairs(inventory.items) do
            if item and item.name then
                local itemNameUpper = string.upper(item.name)
                local itemLevel = tonumber(item.metadata and item.metadata.level) or 1
                local durability = tonumber(item.metadata and item.metadata.durability) or 0
                local itemSerial = item.metadata and item.metadata.serial

                -- Kiểm tra vũ khí chính (bắt buộc phải có)
                if not mainWeaponFound and itemNameUpper == string.upper(requiredWeapon) and itemLevel == requiredLevel then
                    if item.metadata and item.metadata.durability and itemSerial then
                        if durability >= minDurability then
                            mainWeaponFound = true
                            mainWeaponSlot = slot
                            table.insert(weaponsToRemove, {
                                slot = slot,
                                name = item.name,
                                serial = itemSerial,
                                durability = durability,
                                level = itemLevel,
                                isMainWeapon = true
                            })
                        end
                    else
                        -- Vũ khí đúng tên/level nhưng không có serial hợp lệ
                        noValidSerial = true
                    end
                -- Kiểm tra vũ khí phụ
                elseif weaponLookup[itemNameUpper] and itemLevel == requiredLevel then
                    if item.metadata and item.metadata.durability and itemSerial then
                        if durability >= minDurability and slot ~= mainWeaponSlot then
                            table.insert(additionalWeapons, {
                                slot = slot,
                                name = item.name,
                                serial = itemSerial,
                                durability = durability,
                                level = itemLevel,
                                isMainWeapon = false
                            })
                        end
                    else
                        -- Vũ khí phụ đúng tên/level nhưng không có serial hợp lệ
                        noValidSerial = true
                    end
                end
            end
        end
    end

    -- Sắp xếp vũ khí phụ theo độ bền thấp -> cao
    table.sort(additionalWeapons, function(a, b)
        return a.durability < b.durability
    end)
    
    -- Lấy số lượng vũ khí phụ cần thiết
    for i = 1, math.min(additionalCount, #additionalWeapons) do
        table.insert(weaponsToRemove, additionalWeapons[i])
    end
    
    local hasEnoughWeapons = mainWeaponFound and #additionalWeapons >= additionalCount
    local validCount = mainWeaponFound and 1 or 0
    validCount = validCount + math.min(additionalCount, #additionalWeapons)
    
    -- Trả về kết quả (thêm noValidSerial để client phân biệt lỗi)
    cb(hasEnoughWeapons, hasEnoughCash, validCount, weaponsToRemove, noValidSerial)
end)

-- Callback: Lấy danh sách vũ khí có thể sửa từ inventory (theo weapon + level)
-- Using lib.callback for QBX Core compatibility
lib.callback.register('vierp.craftingx:callback:getRepairableWeapons', function(source)
    local inventory = exports.ox_inventory:GetInventory(source)
    local repairableWeapons = {}
    
    if inventory and inventory.items then
        for slot, item in pairs(inventory.items) do
            if item and item.name then
                local weaponName = string.upper(item.name)
                local weaponLevel = item.metadata and item.metadata.level or 1
                
                -- Tạo key config: "WEAPON_NAME_LVX" cho level > 1, hoặc "WEAPON_NAME" cho level 1
                local configKey = weaponName
                if weaponLevel > 1 then
                    configKey = weaponName .. '_LV' .. weaponLevel
                end
                
                local weaponConfig = Config.WeaponRepair[configKey]
                
                -- Chỉ thêm vũ khí có trong Config.WeaponRepair với đúng level
                if weaponConfig then
                    local durability = 100
                    if item.metadata and item.metadata.durability then
                        durability = tonumber(item.metadata.durability) or 100
                    end
                    
                    -- Hiển thị TẤT CẢ vũ khí có trong config
                    table.insert(repairableWeapons, {
                        slot = slot,
                        name = item.name,
                        label = weaponConfig.Label or item.name,
                        durability = durability,
                        serial = item.metadata and item.metadata.serial or 'N/A',
                        level = weaponLevel,
                        repairCost = weaponConfig.Cash or 0,
                        repairAmount = weaponConfig.RepairAmount or 20,
                        repairMaterials = weaponConfig.RepairMaterials or {},
                        -- Các field mà React crafted callback sử dụng:
                        Type = 'repair',
                        Item = item.name,
                        WeaponSlot = slot,
                        CraftItems = weaponConfig.RepairMaterials or {},
                        RepairMaterials = weaponConfig.RepairMaterials or {},
                        PermItems = {},
                        Cash = weaponConfig.Cash or 0,
                        Length = weaponConfig.Length or 3000,
                        Chance = 100,
                        Label = weaponConfig.Label or item.name,
                        Tag = 'LV' .. weaponLevel,
                        Max = 1,
                        Failed = {}
                    })
                end
            end
        end
    end
    
    return repairableWeapons
end)

-- Event: Sửa chữa vũ khí (check theo weapon + level)
RegisterServerEvent('vierp.craftingx:cfx:repairWeapon')
AddEventHandler('vierp.craftingx:cfx:repairWeapon', function(weaponSlot, weaponName, materials, cash)
    local playerId = source
    -- ANTI-SPAM: Khóa player trong quá trình sửa
    if not LockPlayerCraft(playerId) then
        print('^1[ANTI-SPAM] cfx:repairWeapon bị chặn cho player ' .. playerId .. '^0')
        return
    end
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    -- Lấy thông tin vũ khí từ slot trước để check level
    local inventory = exports.ox_inventory:GetInventory(playerId)
    
    if inventory.items then
        local weapon = inventory.items[weaponSlot]
        
        if not weapon or string.upper(weapon.name) ~= string.upper(weaponName) then
            UnlockPlayerCraft(playerId)
            TriggerClientEvent('QBCore:Notify', playerId, 'Không tìm thấy vũ khí!', 'error')
            return
        end
        
        -- Tạo key config: "WEAPON_NAME_LVX" cho level > 1, hoặc "WEAPON_NAME" cho level 1
        local weaponLevel = weapon.metadata and weapon.metadata.level or 1
        local configKey = string.upper(weaponName)
        if weaponLevel > 1 then
            configKey = configKey .. '_LV' .. weaponLevel
        end
        
        -- Kiểm tra config vũ khí
        local weaponConfig = Config.WeaponRepair[configKey]
        if not weaponConfig then
            UnlockPlayerCraft(playerId)
            TriggerClientEvent('QBCore:Notify', playerId, 'Vũ khí này không thể sửa chữa!', 'error')
            return
        end
        
        -- Kiểm tra tiền
        local myCash = Player.PlayerData.money.cash
        if myCash < cash then
            UnlockPlayerCraft(playerId)
            TriggerClientEvent('QBCore:Notify', playerId, 'Không đủ tiền!', 'error')
            return
        end
        
        -- Kiểm tra nguyên liệu
        for itemName, itemData in pairs(materials) do
            local hasItem = exports.ox_inventory:Search(playerId, "count", itemName)
            if hasItem < itemData[2] then
                UnlockPlayerCraft(playerId)
                TriggerClientEvent('QBCore:Notify', playerId, 'Không đủ nguyên liệu: ' .. itemData[1], 'error')
                return
            end
        end
        
        local currentDurability = tonumber(weapon.metadata and weapon.metadata.durability or 100)
        if currentDurability >= 100 then
            UnlockPlayerCraft(playerId)
            TriggerClientEvent('QBCore:Notify', playerId, 'Vũ khí này không cần sửa!', 'error')
            return
        end
        
        -- Trừ tiền và nguyên liệu
        Player.Functions.RemoveMoney('cash', cash, 'weapon-repair')
        for itemName, itemData in pairs(materials) do
            exports.ox_inventory:RemoveItem(playerId, itemName, itemData[2])
        end
        
        -- Set độ bền về 100% (sửa chữa full)
        local newDurability = 100
        
        -- Cập nhật metadata
        weapon.metadata.durability = newDurability
        exports.ox_inventory:SetMetadata(playerId, weaponSlot, weapon.metadata)
        
        -- Thông báo
        TriggerClientEvent('QBCore:Notify', playerId, 'Đã sửa vũ khí! Độ bền: ' .. math.floor(currentDurability) .. '% → ' .. math.floor(newDurability) .. '%', 'success')
        TriggerClientEvent('vierp.craftingx:craftSuccess', playerId)
        UnlockPlayerCraft(playerId)  -- Mở khóa sau khi sửa xong
        
        -- Log ox_lib
        lib.logger(playerId, 'SUA VU KHI', {
            message = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã sửa: " .. weaponName .. " (Độ bền: " .. math.floor(currentDurability) .. "% → " .. math.floor(newDurability) .. "%)",
            weapon = weaponName,
            slot = weaponSlot,
            oldDurability = currentDurability,
            newDurability = newDurability,
            citizenid = Player.PlayerData.pid
        })
        
        -- Log console
        print(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. " [" .. Player.PlayerData.pid .. "] đã sửa: " .. weaponName .. " Level " .. weaponLevel .. " (Độ bền: " .. math.floor(currentDurability) .. "% → " .. math.floor(newDurability) .. "%)")
        
        -- Gửi Discord webhook (embed đẹp)
        if Config.DiscordLogs and Config.DiscordLogs.link then
            local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            local weaponSerial = weapon.metadata and weapon.metadata.serial or "N/A"
            
            -- Tạo chuỗi nguyên liệu đã dùng
            local materialsUsed = {}
            for itemName, itemData in pairs(materials) do
                table.insert(materialsUsed, itemData[1] .. " x" .. itemData[2])
            end
            local materialsStr = table.concat(materialsUsed, ", ")
            
            local embedData = {
                {
                    ["title"] = "🔧 Sửa Chữa Vũ Khí",
                    ["color"] = 3066993,  -- Màu xanh lục nhạt
                    ["fields"] = {
                        {
                            ["name"] = "👤 Người chơi",
                            ["value"] = playerName,
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🆔 Citizen ID",
                            ["value"] = Player.PlayerData.pid or "N/A",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🔫 Vũ khí",
                            ["value"] = weaponName .. " (Level " .. weaponLevel .. ")",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🔢 Serial Number",
                            ["value"] = weaponSerial,
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🔩 Độ bền",
                            ["value"] = math.floor(currentDurability) .. "% → " .. math.floor(newDurability) .. "%",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "💰 Chi phí",
                            ["value"] = "$" .. cash,
                            ["inline"] = true
                        },
                        {
                            ["name"] = "📦 Nguyên liệu sử dụng",
                            ["value"] = materialsStr,
                            ["inline"] = false
                        },
                    },
                    ["footer"] = {
                        ["text"] = Config.DiscordLogs.communityName or "Mini City",
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
                }
            }
            
            PerformHttpRequest(Config.DiscordLogs.link, function(err, text, headers) end, 'POST', json.encode({
                username = Config.DiscordLogs.username or "crafting-logs",
                avatar_url = Config.DiscordLogs.avatar,
                embeds = embedData
            }), { ['Content-Type'] = 'application/json' })
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- ║                 ADMIN COMMAND: GIVE WEAPON CRAFT                ║
-- ║  /giveweapon [id] [weapon] [level (1-5, tùy chọn)]              ║
-- ║  Hỗ trợ alias: cole, machete, cle, wrench, bat, v.v.           ║
-- ║  Tự tạo: serial (Config.Textserial), DoHiem, level, durability  ║
-- ═══════════════════════════════════════════════════════════════════

local WeaponAliases = {
    ['cole']        = 'WEAPON_WRENCH',
    ['co_le']       = 'WEAPON_WRENCH',
    ['cờlê']        = 'WEAPON_WRENCH',
    ['cờ lê']       = 'WEAPON_WRENCH',
    ['cle']         = 'WEAPON_WRENCH',
    ['wrench']      = 'WEAPON_WRENCH',
    ['machete']     = 'WEAPON_MACHETE',
    ['dao']         = 'WEAPON_MACHETE',
    ['daomachete']  = 'WEAPON_MACHETE',
    ['bat']         = 'WEAPON_BAT',
    ['gaybongchay'] = 'WEAPON_BAT',
    ['gay']         = 'WEAPON_BAT',
    ['knife']       = 'WEAPON_KNIFE',
    ['daogam']      = 'WEAPON_KNIFE',
    ['switchblade'] = 'WEAPON_SWITCHBLADE',
    ['dagger']      = 'WEAPON_DAGGER',
    ['crowbar']     = 'WEAPON_CROWBAR',
    ['xa_beng']     = 'WEAPON_CROWBAR',
    ['xabeng']      = 'WEAPON_CROWBAR',
    ['hammer']      = 'WEAPON_HAMMER',
    ['bua']         = 'WEAPON_HAMMER',
    ['golfclub']    = 'WEAPON_GOLFCLUB',
    ['gaygolf']     = 'WEAPON_GOLFCLUB',
}

local function ResolveWeaponName(input)
    if not input or type(input) ~= 'string' or input == '' then return nil end
    local cleanInput = string.lower(string.gsub(input, "%s+", ""))
    if WeaponAliases[cleanInput] then
        return WeaponAliases[cleanInput]
    end
    local lowerRaw = string.lower(input)
    if WeaponAliases[lowerRaw] then
        return WeaponAliases[lowerRaw]
    end
    local upperInput = string.upper(cleanInput)
    if not string.find(upperInput, '^WEAPON_') then
        return 'WEAPON_' .. upperInput
    end
    return upperInput
end

local function SendCraftNotify(src, text, notifyType)
    if not src or src == 0 then
        if notifyType == 'error' then
            print('^1[GIVE-WEAPON] ' .. text .. '^0')
        else
            print('^2[GIVE-WEAPON] ' .. text .. '^0')
        end
        return
    end
    TriggerClientEvent('ox_lib:notify', src, {
        description = text,
        type = notifyType or 'info',
        duration = 5000
    })
    TriggerClientEvent('QBCore:Notify', src, text, notifyType or 'info', 5000)
end

local function ParseCommandParams(args)
    if type(args) ~= 'table' then return nil, nil, 1 end

    -- Trường hợp lib.addCommand với named params
    if args.target or args.weapon or args.id or args.item then
        local targetId = tonumber(args.target or args.id)
        local weaponInput = tostring(args.weapon or args.item or '')
        local level = tonumber(args.level) or 1
        return targetId, weaponInput, level
    end

    -- Trường hợp args là mảng thông thường
    local count = #args
    if count == 0 then return nil, nil, 1 end

    local targetId = tonumber(args[1])
    if not targetId then return nil, nil, 1 end

    if count == 1 then
        return targetId, nil, 1
    end

    local level = 1
    local weaponTokens = {}

    local lastArgNum = tonumber(args[count])
    if count >= 3 and lastArgNum and lastArgNum >= 1 and lastArgNum <= 5 then
        level = lastArgNum
        for i = 2, count - 1 do
            table.insert(weaponTokens, args[i])
        end
    else
        for i = 2, count do
            table.insert(weaponTokens, args[i])
        end
    end

    local weaponInput = table.concat(weaponTokens, " ")
    return targetId, weaponInput, level
end

local function ExecuteGiveWeapon(source, args)
    local targetId, weaponInput, level = ParseCommandParams(args)
    level = math.max(1, math.min(5, level or 1))

    if not targetId or not weaponInput or weaponInput == '' then
        SendCraftNotify(source, 'Cú pháp: /giveweapon [id] [vũ khí (cole / machete / WEAPON_...)] [level (1-5)]', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed or targetPed == 0 then
        SendCraftNotify(source, ('Người chơi ID %s không online hoặc không tồn tại!'):format(targetId), 'error')
        return
    end

    local weaponName = ResolveWeaponName(weaponInput)
    if not weaponName then
        SendCraftNotify(source, 'Tên vũ khí không hợp lệ!', 'error')
        return
    end

    local serialRD = Config.Textserial .. GenerateSerial()
    local rarity = GetWeaponRarity(level)
    local metaData = {
        serial = serialRD,
        durability = 100,
        level = level,
        DoHiem = rarity,
        Capdo = level
    }

    local success, response = pcall(function()
        return exports.ox_inventory:AddItem(targetId, weaponName, 1, metaData)
    end)

    if not success or not response then
        SendCraftNotify(source, ('Không thể thêm %s vào túi đồ ID %s (Túi đầy hoặc tên item không tồn tại trong ox_inventory)!'):format(weaponName, targetId), 'error')
        return
    end

    local adminLabel = (source == 0 and "Console") or ("Admin [" .. source .. "]")
    local targetLabel = "Player [" .. targetId .. "]"

    local Player = (exports.qbx_core and exports.qbx_core:GetPlayer(targetId)) or (QBCore and QBCore.Functions and QBCore.Functions.GetPlayer(targetId))
    if Player and Player.PlayerData and Player.PlayerData.charinfo then
        targetLabel = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. ' [' .. targetId .. ']'
    end

    local msgAdmin = string.format("Đã give %s (Lv%d - %s) cho %s | Seri: %s", weaponName, level, rarity, targetLabel, serialRD)
    local msgTarget = string.format("Bạn nhận được %s (Cấp %d - %s) | Seri: %s", weaponName, level, rarity, serialRD)

    SendCraftNotify(source, msgAdmin, 'success')
    if source ~= targetId and source > 0 then
        SendCraftNotify(targetId, msgTarget, 'success')
    elseif source == 0 then
        SendCraftNotify(targetId, msgTarget, 'success')
    end
    print('^2[GIVE-WEAPON] ' .. adminLabel .. ' -> ' .. msgAdmin .. '^0')

    if lib and lib.logger then
        lib.logger(targetId, 'GIVE WEAPON ADMIN', {
            message = adminLabel .. " đã give: " .. weaponName .. " Lv" .. level .. " (" .. rarity .. ") Seri:" .. serialRD .. " cho " .. targetLabel,
            weapon = weaponName,
            level = level,
            rarity = rarity,
            serial = serialRD,
            citizenid = (Player and Player.PlayerData and (Player.PlayerData.pid or Player.PlayerData.citizenid)) or targetId,
            admin = adminLabel
        })
    end
end

-- 1. Đăng ký qua ox_lib (Chuẩn cho Qbox / ox_lib với group.admin)
if lib and lib.addCommand then
    lib.addCommand({'giveweapon', 'givecraftweapon', 'givevk'}, {
        help = 'Give vũ khí crafting có Seri & Độ Hiếm (Admin Only)',
        params = {
            { name = 'target', type = 'playerId', help = 'ID người chơi' },
            { name = 'weapon', type = 'string', help = 'Tên vũ khí (cole, machete, WEAPON_WRENCH...)' },
            { name = 'level', type = 'number', help = 'Level vũ khí (1-5, mặc định 1)', optional = true }
        },
        restricted = 'group.admin'
    }, function(source, args)
        ExecuteGiveWeapon(source, args)
    end)
end

-- 2. Đăng ký qua QBCore.Commands.Add (Dự phòng cho QBCore legacy)
if QBCore and QBCore.Commands and QBCore.Commands.Add then
    QBCore.Commands.Add('giveweapon', 'Give vũ khí crafting có Seri & Độ Hiếm (Admin Only)', {
        { name = 'id', help = 'ID người chơi' },
        { name = 'weapon', help = 'Tên vũ khí (cole, machete, WEAPON_WRENCH...)' },
        { name = 'level', help = 'Level vũ khí (1-5, mặc định 1)' }
    }, true, function(source, args)
        ExecuteGiveWeapon(source, args)
    end, 'admin')

    QBCore.Commands.Add('givecraftweapon', 'Give vũ khí crafting có Seri & Độ Hiếm (Admin Only)', {
        { name = 'id', help = 'ID người chơi' },
        { name = 'weapon', help = 'Tên vũ khí (cole, machete, WEAPON_WRENCH...)' },
        { name = 'level', help = 'Level vũ khí (1-5, mặc định 1)' }
    }, true, function(source, args)
        ExecuteGiveWeapon(source, args)
    end, 'admin')
end

-- 3. Đăng ký trực tiếp FiveM RegisterCommand (Hỗ trợ F8 console / txAdmin / server console)
RegisterCommand('givecraftweapon', function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, 'command') or IsPlayerAceAllowed(source, 'admin') or IsPlayerAceAllowed(source, 'group.admin') then
        ExecuteGiveWeapon(source, args)
    else
        SendCraftNotify(source, 'Bạn không có quyền sử dụng lệnh này!', 'error')
    end
end, false)

