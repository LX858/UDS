QBCore = exports['qb-core']:GetCoreObject()

local zoneStates = {}

local function UpdateZoneStates()
    local currentHour = os.date("*t").hour
    for _, zone in ipairs(Config.FishingZones) do
        if zone.allowedHours then
            local isOpen = Config.IsTimeAllowed(zone.allowedHours, currentHour)
            local previousState = zoneStates[zone.name]
            
            if previousState == nil then
                zoneStates[zone.name] = isOpen
            elseif previousState ~= isOpen then
                zoneStates[zone.name] = isOpen
                
                -- Trigger client event to update blip
                TriggerClientEvent('xn_cauca:setZoneState', -1, zone.name, isOpen)
                
                -- If it just opened, display a city announcement
                if isOpen then
                    local avatarUrl = 'https://github.com/xuannguyen995/prime_item/blob/main/fishing_time.png?raw=true'
                    if zone.name == "advanced_zone" then
                        exports['xn_thongbao']:SendSpecialAnnouncementToAll(
                            'FISHING',
                            'Khu vực câu cá thế giới đã chính thức mở cửa săn cá mập!',
                            10000,
                            avatarUrl
                        )
                    else
                        exports['xn_thongbao']:SendSpecialAnnouncementToAll(
                            'FISHING',
                            'Khu vực ' .. zone.Label .. ' đã chính thức mở cửa!',
                            10000,
                            avatarUrl
                        )
                    end
                end
            end
        end
    end
end

-- Initialize states immediately on start
UpdateZoneStates()

-- Setup cron job to check every minute
lib.cron.new('* * * * *', function()
    UpdateZoneStates()
end)


-- Level calculation functions (server-side)
local function GetLevelFromXP(xp)
    if not Config.EnableXPSystem or not xp then
        return 1
    end
    
    for level = Config.MaxLevel, 1, -1 do
        if xp >= (Config.RequiredXP[level] or 0) then
            return level
        end
    end
    return 1
end

local function GetXPForNextLevel(currentXP)
    if not Config.EnableXPSystem then
        return 0
    end
    
    local currentLevel = GetLevelFromXP(currentXP)
    if currentLevel >= Config.MaxLevel then
        return 0 -- Max level reached
    end
    
    local nextLevelXP = Config.RequiredXP[currentLevel + 1] or 0
    return nextLevelXP - currentXP
end

-- Database functions for fishing XP
local function GetPlayerFishingXP(citizenid, cb)
    exports.oxmysql:execute('SELECT fishing_xp FROM xn_fishing_xp WHERE citizenid = ?', {citizenid}, function(result)
        if result and result[1] then
            cb(result[1].fishing_xp or 0)
        else
            cb(0)
        end
    end)
end

local function SetPlayerFishingXP(citizenid, xp, totalFish)
    exports.oxmysql:execute('INSERT INTO xn_fishing_xp (citizenid, fishing_xp, total_fish_caught) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE fishing_xp = ?, total_fish_caught = ?', 
    {citizenid, xp, totalFish or 0, xp, totalFish or 0})
end

local function AddPlayerFishingXP(citizenid, xpToAdd, cb)
    exports.oxmysql:execute('SELECT fishing_xp, total_fish_caught FROM xn_fishing_xp WHERE citizenid = ?', {citizenid}, function(result)
        local currentXP = 0
        local totalFish = 0
        
        if result and result[1] then
            currentXP = result[1].fishing_xp or 0
            totalFish = result[1].total_fish_caught or 0
        end
        
        local newXP = currentXP + xpToAdd
        local newTotalFish = totalFish + 1
        
        exports.oxmysql:execute('INSERT INTO xn_fishing_xp (citizenid, fishing_xp, total_fish_caught) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE fishing_xp = ?, total_fish_caught = ?', 
        {citizenid, newXP, newTotalFish, newXP, newTotalFish}, function(affectedRows)
            if cb then cb(newXP, newTotalFish) end
        end)
    end)
end

-- Safe ox_inventory wrapper functions
local function SafeOxCall(func, ...)
    if exports.ox_inventory and exports.ox_inventory[func] then
        local success, result = pcall(function(...)
            return exports.ox_inventory[func](exports.ox_inventory, ...)
        end, ...)
        if success then
            return result
        end
    end
    return nil
end

-- Helper functions for inventory management
local function GetItemCount(source, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not itemName then return 0 end
    
    -- Try ox_inventory first
    local count = SafeOxCall('GetItemCount', source, itemName)
    if count and count > 0 then return count end
    
    -- Try alternative ox_inventory method
    local item = SafeOxCall('GetItem', source, itemName)
    if item and item.count and item.count > 0 then return item.count end
    
    -- Fallback to QBCore inventory
    local qbItem = Player.Functions.GetItemByName(itemName)
    return qbItem and qbItem.amount or 0
end

local function RemoveItem(source, itemName, count)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Try ox_inventory first
    local success = SafeOxCall('RemoveItem', source, itemName, count)
    if success ~= nil then return success end
    
    -- Fallback to QBCore inventory
    return Player.Functions.RemoveItem(itemName, count)
end

local function AddItem(source, itemName, count, metadata)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Try ox_inventory first with metadata support
    if metadata then
        local success = SafeOxCall('AddItem', source, itemName, count, metadata)
        if success ~= nil then return success end
    else
        local success = SafeOxCall('AddItem', source, itemName, count)
        if success ~= nil then return success end
    end
    
    -- Fallback to QBCore inventory (with metadata if supported)
    if metadata and Player.Functions.AddItem then
        return Player.Functions.AddItem(itemName, count, false, metadata)
    else
        return Player.Functions.AddItem(itemName, count)
    end
end

local function CanCarryItem(source, itemName, count)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:CanCarryItem(source, itemName, count)
    end
    
    -- Fallback - check QBCore inventory space
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local item = QBCore.Shared.Items[itemName]
    if not item then return false end
    
    local totalWeight = nil
    if Player.Functions.GetTotalWeight then
        totalWeight = Player.Functions.GetTotalWeight()
    elseif QBCore.Player.GetTotalWeight then
        totalWeight = QBCore.Player.GetTotalWeight(Player.PlayerData.items)
    end
    
    if not totalWeight and Player.PlayerData.items then
        totalWeight = 0
        for _, itemData in pairs(Player.PlayerData.items) do
            if itemData and itemData.weight and itemData.amount then
                totalWeight = totalWeight + (itemData.weight * itemData.amount)
            end
        end
    end
    totalWeight = totalWeight or 0
    
    local itemWeight = (item.weight or 0) * count
    local maxWeight = (QBCore.Config and QBCore.Config.Player and QBCore.Config.Player.MaxWeight) or 120000
    
    return (totalWeight + itemWeight) <= maxWeight
end

local function GetSlotItem(source, slot)
    return SafeOxCall('GetSlot', source, slot)
end

local function SetDurability(source, slot, durability)
    local success = SafeOxCall('SetDurability', source, slot, durability)
    return success ~= nil and success or true -- Return true if no ox_inventory
end

local function RemoveItemFromSlot(source, itemName, count, metadata, slot)
    local success = SafeOxCall('RemoveItem', source, itemName, count, metadata, slot)
    if success ~= nil then return success end
    
    -- Fallback to regular remove
    return RemoveItem(source, itemName, count)
end

-- Safe notification function
local function SendNotification(source, title, description, type)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Try ox_lib notification first
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = title,
            description = description,
            type = type
        })
    else
        -- Fallback to QBCore notification
        local message = string.format("[%s] %s", title, description)
        Player.Functions.Notify(message, type or 'primary')
    end
end

-- Debug function
local function DebugPrint(message)
    if Config.Debug then
        print("[FISHING SERVER] " .. tostring(message))
    end
end

-- Validate fishing attempt on server
exports['monitors']:RegisterProtectedEvent('xn_cauca:validateFishing', function(source, zoneData, playerXP, rodType, rodSlot)
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    if not zoneData or not zoneData.name then
        TriggerClientEvent('xn_cauca:fishingResult', source, false, 'INVALID_ZONE')
        return
    end
    
    -- Find the matching zone on the server side to prevent client data spoofing
    local serverZone = nil
    for _, zone in pairs(Config.FishingZones) do
        if zone.name == zoneData.name then
            serverZone = zone
            break
        end
    end
    
    if not serverZone then
        TriggerClientEvent('xn_cauca:fishingResult', source, false, 'INVALID_ZONE')
        return
    end
    
    -- Check time restriction if configured
    if serverZone.allowedHours then
        local currentHour = os.date("*t").hour
        if not Config.IsTimeAllowed(serverZone.allowedHours, currentHour) then
            TriggerClientEvent('xn_cauca:fishingResult', source, false, 'TIME_RESTRICTION', serverZone)
            return
        end
    end
    
    -- If XP system is enabled, validate zone requirements
    if Config.EnableXPSystem then
        -- Get real XP from database instead of client data
        local citizenid = Player.PlayerData.citizenid
        GetPlayerFishingXP(citizenid, function(realPlayerXP)
            -- Validate zone requirements using real XP from database
            if realPlayerXP < serverZone.requiredXP or realPlayerXP > serverZone.maxXP then
                TriggerClientEvent('xn_cauca:fishingResult', source, false, 'XP_REQUIREMENT')
                return
            end
            
            -- Continue with fishing validation
            ContinueFishingValidation(source, Player, serverZone, rodType, rodSlot)
        end)
    else
        -- XP system disabled, skip XP checks
        ContinueFishingValidation(source, Player, serverZone, rodType, rodSlot)
    end
end)

-- Separate function for continuing fishing validation after XP check
function ContinueFishingValidation(source, Player, zoneData, rodType, rodSlot)
    -- Check if player has the specific rod type AND if it's allowed in this zone
    local hasValidRod = false
    for _, allowedRodType in pairs(zoneData.allowedRods) do
        if allowedRodType == rodType then
            hasValidRod = true
            break
        end
    end
    
    if not hasValidRod then
        DebugPrint(string.format("Rod %s not allowed in zone %s", rodType, zoneData.name))
        TriggerClientEvent('xn_cauca:fishingResult', source, false, 'INVALID_ROD')
        return
    end
    
    -- Search for the SPECIFIC rod type, not just any rod
    local rodItem = nil
    local actualRodSlot = nil
    
    -- Find the specific rod type that was used
    for i = 1, 50 do
        local item = GetSlotItem(source, i)
        if item and item.name == rodType then -- Only look for the specific rod type used
            rodItem = item
            actualRodSlot = i
            break
        end
    end
    
    if not rodItem or not actualRodSlot then
        DebugPrint(string.format("No %s found in player %d inventory", rodType, source))
        TriggerClientEvent('xn_cauca:fishingResult', source, false, 'NO_ROD')
        return
    end
    
    -- Get durability data
    local currentDurability = rodItem.metadata and rodItem.metadata.durability or rodItem.durability or 100
    DebugPrint(string.format("Found %s in slot %d with %.1f%% durability", rodType, actualRodSlot, currentDurability))
    
    if currentDurability <= 0 then
        TriggerClientEvent('xn_cauca:fishingResult', source, false, 'ROD_BROKEN')
        return
    end
    
    -- Check bait count
    local baitCount = 0
    if Config.RequiredItems and Config.RequiredItems.bait then
        baitCount = GetItemCount(source, Config.RequiredItems.bait)
    end
    if baitCount < 1 then
        TriggerClientEvent('xn_cauca:fishingResult', source, false, 'NO_BAIT')
        return
    end
    
    -- DAMAGE THE SPECIFIC ROD TYPE
    local rodConfig = Config.FishingRods[rodType]
    if rodConfig and rodConfig.durabilityLoss then
        local damagePercent = rodConfig.durabilityLoss
        local newDurability = math.max(0, currentDurability - damagePercent)
        
        DebugPrint(string.format("Player %d: Damaging %s in slot %d: %.1f%% -> %.1f%% (-%.1f%%)", 
            source, rodType, actualRodSlot, currentDurability, newDurability, damagePercent))
        
        -- Check if rod will be destroyed
        if newDurability <= 0 then
            -- Check if this rod type is indestructible
            local isIndestructible = false
            if Config.IndestructibleRods then
                for _, indestructibleRod in pairs(Config.IndestructibleRods) do
                    if indestructibleRod == rodType then
                        isIndestructible = true
                        break
                    end
                end
            end
            
            if isIndestructible then
                -- Keep the rod but set durability to 0
                DebugPrint(string.format("Rod %s in slot %d is indestructible, setting durability to 0", rodType, actualRodSlot))
                local success = SetDurability(source, actualRodSlot, 0)
                if success then
                    SendNotification(source, 'Cần câu', string.format('%s đã hỏng hoàn toàn nhưng không bị phá hủy! Hãy sửa chữa để tiếp tục sử dụng.', rodConfig.name), 'warning')
                else
                    DebugPrint(string.format("Failed to set durability to 0 for indestructible %s in slot %d", rodType, actualRodSlot))
                end
            else
                -- Normal destructible rod behavior
                DebugPrint(string.format("Rod %s in slot %d will be destroyed", rodType, actualRodSlot))
                
                -- Remove the rod completely from inventory
                local removeSuccess = RemoveItemFromSlot(source, rodType, 1, rodItem.metadata, actualRodSlot)
                
                if removeSuccess then
                    DebugPrint(string.format("Successfully removed broken %s from slot %d", rodType, actualRodSlot))
                    
                    SendNotification(source, 'Cần câu', string.format('%s đã hỏng và bị phá hủy!', rodConfig.name), 'error')
                    
                    -- Verify removal
                    SetTimeout(100, function()
                        local checkItem = GetSlotItem(source, actualRodSlot)
                        if not checkItem or checkItem.name ~= rodType then
                            DebugPrint(string.format("VERIFY: %s successfully removed from slot %d", rodType, actualRodSlot))
                        else
                            DebugPrint(string.format("WARNING: %s still exists in slot %d after removal", rodType, actualRodSlot))
                        end
                    end)
                else
                    DebugPrint(string.format("Failed to remove broken %s from slot %d, trying alternative method", rodType, actualRodSlot))
                    -- Alternative method: Set durability to 0 as fallback
                    local fallbackSuccess = SetDurability(source, actualRodSlot, 0)
                    if fallbackSuccess then
                        DebugPrint(string.format("Fallback: Set %s durability to 0 in slot %d", rodType, actualRodSlot))
                        SendNotification(source, 'Cần câu', string.format('%s đã hỏng hoàn toàn! Vui lòng thả và nhặt lại để xóa.', rodConfig.name), 'error')
                    else
                        DebugPrint(string.format("CRITICAL: Cannot remove or set durability for %s in slot %d", rodType, actualRodSlot))
                    end
                end
            end
        else
            -- Update durability normally
            local success = SetDurability(source, actualRodSlot, newDurability)
            
            if success then
                DebugPrint(string.format("SetDurability SUCCESS: Updated %s in slot %d to %.1f%%", rodType, actualRodSlot, newDurability))
                -- Warn if durability is low
                if newDurability <= 20 then
                    SendNotification(source, 'Cần câu', string.format('%s sắp hỏng! (Độ bền: %.0f%%)', rodConfig.name, newDurability), 'warning')
                end
            else
                DebugPrint(string.format("SetDurability FAILED for %s in slot %d", rodType, actualRodSlot))
            end
        end
    end
    
    -- Remove bait
    if RemoveItem(source, Config.RequiredItems.bait, 1) then
        TriggerClientEvent('xn_cauca:fishingResult', source, true, 'SUCCESS', zoneData)
    else
        TriggerClientEvent('xn_cauca:fishingResult', source, false, 'BAIT_REMOVE_FAILED')
    end
end

-- Convert fish rarity to metadata format
local function GetFishRarityMetadata(rarity)
    local rarityMap = {
        common = "Common",
        uncommon = "Uncommon", 
        rare = "Rare",
        epic = "Epic",
        legendary = "Legendary"
    }
    
    return rarityMap[rarity] or "Common"
end

-- Handle successful fish catch
exports['monitors']:RegisterProtectedEvent('xn_cauca:giveFish', function(source, fishType, amount)
    -- print(fishType, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    local tile = math.random(1, 100)
    local tile2 = math.random(1, 100)

    if not Player then return end
    
    -- Validate fish type exists in config
    local validFish = Config.FishSettings[fishType] ~= nil
    
    -- Double check if fish exists in any zone
    if validFish then
        local fishInZone = false
        for _, zone in pairs(Config.FishingZones) do
            for _, fish in pairs(zone.fish) do
                if fish == fishType then
                    fishInZone = true
                    break
                end
            end
            if fishInZone then break end
        end
        validFish = fishInZone
    end
    
    if validFish then
        -- Check inventory weight before adding item
        local canCarry = CanCarryItem(source, fishType, amount or 1)
          if not canCarry then
            -- Cannot carry the item due to weight/space constraints
            SendNotification(source, 'Câu cá', 'Túi đồ đầy hoặc quá nặng! Không thể nhận cá.', 'error')
            DebugPrint(string.format("Player %s cannot carry %s x%d - inventory full/overweight", 
                Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, fishType, amount or 1))
            return
        end
        
        -- Create metadata with rarity information
        local fishConfig = Config.FishSettings[fishType]
        local metadata = {
            DoHiem = GetFishRarityMetadata(fishConfig.rarity),
            description = fishConfig.name,
            quality = fishConfig.rarity
        }
        
        local success = AddItem(source, fishType, amount or 1, metadata)
        
        if success then
            -- Log successful catch with XP info
            DebugPrint(string.format("Player %s caught %s (%s) - Gained %d XP - Metadata: DoHiem=%s", 
                Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, 
                fishConfig.name, fishConfig.rarity, fishConfig.xpReward, metadata.DoHiem))
            -- Notify player of successful catch
            SendNotification(source, 'Câu cá', string.format('Đã nhận %s vào túi đồ! (Độ hiếm: %s)', fishConfig.name, metadata.DoHiem), 'success')
            
            -- Xử lý phần thưởng item đặc biệt theo bãi câu
            local playerPed = GetPlayerPed(source)
            local playerCoords = GetEntityCoords(playerPed)
            local currentZone = nil
            
            -- Xác định zone theo tọa độ player
            for _, zone in pairs(Config.FishingZones) do
                if zone.coords and zone.radius then
                    local distance = #(playerCoords - zone.coords)
                    if distance <= (zone.radius + 30.0) then
                        currentZone = zone
                        break
                    end
                end
            end
            
            -- Fallback xác định zone theo loại cá nếu player ở rìa bãi
            if not currentZone then
                for _, zone in pairs(Config.FishingZones) do
                    if zone.fish then
                        for _, fish in pairs(zone.fish) do
                            if fish == fishType then
                                currentZone = zone
                                break
                            end
                        end
                    end
                    if currentZone then break end
                end
            end
            
            -- Trao item đặc biệt nếu trúng tỷ lệ của bãi câu
            if currentZone and currentZone.specialReward and (currentZone.specialReward.chance or 0) > 0 then
                local roll = math.random(1, 100)
                if roll <= currentZone.specialReward.chance then
                    local specialItemName = currentZone.specialReward.item or "the_cau_ca"
                    local specialItemAmount = currentZone.specialReward.amount or 1
                    local specialItemLabel = currentZone.specialReward.label or "Thẻ Câu Cá"
                    
                    if CanCarryItem(source, specialItemName, specialItemAmount) then
                        local rewardSuccess = AddItem(source, specialItemName, specialItemAmount)
                        if rewardSuccess then
                            SendNotification(source, 'Phần thưởng may mắn', string.format('🎉 Bạn nhận được thêm x%d %s!', specialItemAmount, specialItemLabel), 'success')
                            DebugPrint(string.format("Player %s received special reward: x%d %s from %s (Roll: %d <= %d%%)", 
                                Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, 
                                specialItemAmount, specialItemName, currentZone.name or "zone", roll, currentZone.specialReward.chance))
                        end
                    else
                        SendNotification(source, 'Câu cá', string.format('Túi đồ đầy! Không thể nhận thêm %s.', specialItemLabel), 'error')
                    end
                end
            end
        else
            -- Failed to add item (should not happen after CanCarry check, but just in case)
            SendNotification(source, 'Câu cá', 'Lỗi khi thêm vật phẩm vào túi đồ!', 'error')
            DebugPrint(string.format("AddItem failed for %s despite CanCarry check", fishType))
        end
    else
        -- Invalid fish type - possible cheating attempt
        DebugPrint(string.format("Player %s attempted to spawn invalid fish: %s", 
            Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, fishType))
    end
end)

-- Get player fishing data (items only, level will be handled client-side)
QBCore.Functions.CreateCallback('xn_cauca:getPlayerData', function(source, cb)
    -- Always return a valid table to prevent callback errors
    local defaultData = {
        hasRod = false,
        hasBait = false,
        baitCount = 0,
        zoneStates = zoneStates
    }
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(defaultData)
        return 
    end
    
    -- Wrap in pcall to catch any errors
    local success, result = pcall(function()
        -- Check for any valid fishing rod
        local hasRod = false
        if Config.RequiredItems and Config.RequiredItems.rods then
            for _, rodType in pairs(Config.RequiredItems.rods) do
                local rodCount = GetItemCount(source, rodType)
                if rodCount > 0 then
                    hasRod = true
                    break
                end
            end
        end
        
        local baitCount = 0
        if Config.RequiredItems and Config.RequiredItems.bait then
            baitCount = GetItemCount(source, Config.RequiredItems.bait)
        end
        
        return {
            hasRod = hasRod,
            hasBait = baitCount > 0,
            baitCount = baitCount,
            zoneStates = zoneStates
        }
    end)
    
    if success and result then
        cb(result)
    else
        DebugPrint(string.format("Error in getPlayerData callback: %s", tostring(result)))
        cb(defaultData)
    end
end)

-- Handle fishing rod usage
RegisterNetEvent('xn_cauca:useFishingRod')
AddEventHandler('xn_cauca:useFishingRod', function()
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Safely check if player has any fishing rod
    local hasRod = false
    if Config.RequiredItems and Config.RequiredItems.rods then
        for _, rodType in pairs(Config.RequiredItems.rods) do
            local rodCount = GetItemCount(source, rodType)
            if rodCount > 0 then
                hasRod = true
                break
            end
        end
    end
    
    if hasRod then
        TriggerClientEvent('xn_cauca:useFishingRod', source)
    end
end)

-- Handle fishing XP addition
-- Handle fishing XP addition
RegisterServerEvent('xn_cauca:addFishingXP')
AddEventHandler('xn_cauca:addFishingXP', function(xpAmount)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player or not xpAmount or xpAmount <= 0 then return end
    
    -- Check if XP system is enabled
    if not Config.EnableXPSystem then
        DebugPrint("XP System is disabled, skipping XP addition")
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Get current XP before adding new XP
    GetPlayerFishingXP(citizenid, function(currentXP)
        local oldLevel = GetLevelFromXP(currentXP)
        
        -- Add XP using SQL database
        AddPlayerFishingXP(citizenid, xpAmount, function(newXP, totalFish)
            local newLevel = GetLevelFromXP(newXP)
            
            DebugPrint(string.format("Player %s gained %d fishing XP (Total: %d, Fish Caught: %d, Level: %d)", 
                Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, 
                xpAmount, newXP, totalFish, newLevel))
            
            -- Check for level up
            if newLevel > oldLevel then
                -- Level up notification
                SendNotification(source, 'Câu cá', string.format('🎉 Chúc mừng! Bạn đã lên cấp %d! 🎉', newLevel), 'success')
                SendNotification(source, 'Câu cá', string.format('Bạn đã nhận %d XP câu cá! (Tổng: %d XP)', xpAmount, newXP), 'success')
            else
                -- Regular XP gain notification
                local xpToNext = GetXPForNextLevel(newXP)
                local levelInfo = ''
                if newLevel < Config.MaxLevel then
                    levelInfo = string.format(' (Cần %d XP để lên cấp %d)', xpToNext, newLevel + 1)
                else
                    levelInfo = ' (Cấp độ tối đa)'
                end
                SendNotification(source, 'Câu cá', string.format('Bạn đã nhận %d XP câu cá! (Tổng: %d XP)%s', xpAmount, newXP, levelInfo), 'success')
            end
            
            -- Trigger client to refresh player data (Event-driven update)
            TriggerClientEvent('xn_cauca:refreshPlayerData', source)
        end)
    end)
end)

-- Get player fishing XP (callback for client)
QBCore.Functions.CreateCallback('xn_cauca:getPlayerFishingXP', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(0)
        return 
    end
    
    -- If XP system is disabled, return 0
    if not Config.EnableXPSystem then
        cb(0)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    GetPlayerFishingXP(citizenid, function(xp)
        cb(xp)
    end)
end)

-- Admin command to check/set fishing XP
QBCore.Commands.Add('fishingxp', 'Check or set fishing XP (Admin Only)', {
    {name = 'id', help = 'Player ID'},
    {name = 'amount', help = 'XP amount to set (optional)'}
}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Check if player has admin permission (adjust as needed for your permission system)
    if not QBCore.Functions.HasPermission(source, 'admin') then
        Player.Functions.Notify('You do not have permission to use this command!', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local xpAmount = tonumber(args[2])
    
    if not targetId then
        Player.Functions.Notify('Please specify a player ID!', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        Player.Functions.Notify('Player not found!', 'error')
        return
    end
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    
    if xpAmount then
        -- Set XP
        SetPlayerFishingXP(citizenid, xpAmount, 0)
        local newLevel = GetLevelFromXP(xpAmount)
        Player.Functions.Notify(string.format('Set %s fishing XP to %d (Level %d)', TargetPlayer.PlayerData.charinfo.firstname, xpAmount, newLevel), 'success')
        TargetPlayer.Functions.Notify(string.format('Your fishing XP has been set to %d (Level %d)', xpAmount, newLevel), 'info')
    else
        -- Check XP
        GetPlayerFishingXP(citizenid, function(xp)
            local level = GetLevelFromXP(xp)
            local xpToNext = GetXPForNextLevel(xp)
            local levelInfo
            
            if level >= Config.MaxLevel then
                levelInfo = string.format('(Max Level %d)', level)
            else
                levelInfo = string.format('(Level %d, %d XP to next)', level, xpToNext)
            end
            
            Player.Functions.Notify(string.format('%s has %d fishing XP %s', TargetPlayer.PlayerData.charinfo.firstname, xp, levelInfo), 'primary')
        end)
    end
end, 'admin')

-- Function to get rod tier from rod type
local function GetRodTier(rodType)
    -- Check if rod exists in FishingRods config
    if not Config.FishingRods[rodType] then return 1 end
    
    -- Get tier from FishingRods config, default to 1
    return Config.FishingRods[rodType].tier or 1
end

-- Function to create rod metadata with DoHiem
local function CreateRodMetadata(rodType)
    local tier = GetRodTier(rodType)
    local doHiem = Config.RodUpgradeSystem.tierRarity[tier] or "Common"
    
    return {
        DoHiem = doHiem,
        tier = tier,
        type = "fishing_rod"
    }
end

-- Handle fishing rod purchase
exports['monitors']:RegisterProtectedEvent('xn_cauca:buyFishingRod', function(source, rodType, quantity)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    quantity = tonumber(quantity)
    
    if not Player or not quantity or quantity <= 0 then return end
    
    -- Get price from config
    local price = Config.FishingShop.prices.rods[rodType]
    if not price then
        SendNotification(source, 'Cửa hàng', 'Loại cần câu không hợp lệ!', 'error')
        return
    end
    
    local totalPrice = price * quantity
    local playerMoney = Player.PlayerData.money.cash
    
    -- Check if player has enough money
    if playerMoney < totalPrice then
        SendNotification(source, 'Cửa hàng', string.format('Bạn cần $%d để mua %d cần câu!', totalPrice, quantity), 'error')
        return
    end
    
    -- Check if player can carry the items
    if not CanCarryItem(source, rodType, quantity) then
        SendNotification(source, 'Cửa hàng', 'Túi đồ không đủ chỗ!', 'error')
        return
    end
    
    -- Remove money and add items with metadata
    if Player.Functions.RemoveMoney('cash', totalPrice) then
        -- Create metadata for the rod
        local rodMetadata = CreateRodMetadata(rodType)
        
        -- Add each rod individually with metadata
        local success = true
        for i = 1, quantity do
            if not AddItem(source, rodType, 1, rodMetadata) then
                success = false
                break
            end
        end
        
        if success then
            local rodName = Config.FishingRods[rodType] and Config.FishingRods[rodType].name or rodType
            local doHiem = rodMetadata.DoHiem
            SendNotification(source, 'Cửa hàng', string.format('Đã mua %d %s (%s) với giá $%d!', quantity, rodName, doHiem, totalPrice), 'success')
            DebugPrint(string.format("Player %s bought %d %s (%s) for $%d", 
                Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, 
                quantity, rodType, doHiem, totalPrice))
        else
            -- Refund money if item addition failed
            Player.Functions.AddMoney('cash', totalPrice)
            SendNotification(source, 'Cửa hàng', 'Lỗi khi thêm vật phẩm!', 'error')
        end
    else
        SendNotification(source, 'Cửa hàng', 'Lỗi khi thanh toán!', 'error')
    end
end)

-- Handle bait purchase
exports['monitors']:RegisterProtectedEvent('xn_cauca:buyBait', function(source, quantity)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    quantity = tonumber(quantity)
    
    if not Player or not quantity or quantity <= 0 then return end
    
    local baitPrice = Config.FishingShop.prices.bait
    local totalPrice = baitPrice * quantity
    local playerMoney = Player.PlayerData.money.cash
    
    -- Check if player has enough money
    if playerMoney < totalPrice then
        SendNotification(source, 'Cửa hàng', string.format('Bạn cần $%d để mua %d mồi câu!', totalPrice, quantity), 'error')
        return
    end
    
    -- Check if player can carry the items
    if not CanCarryItem(source, 'moi_cau', quantity) then
        SendNotification(source, 'Cửa hàng', 'Túi đồ không đủ chỗ!', 'error')
        return
    end
    
    -- Remove money and add items
    if Player.Functions.RemoveMoney('cash', totalPrice) then
        if AddItem(source, 'moi_cau', quantity) then
            SendNotification(source, 'Cửa hàng', string.format('Đã mua %d mồi câu với giá $%d!', quantity, totalPrice), 'success')
            DebugPrint(string.format("Player %s bought %d bait for $%d", 
                Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, 
                quantity, totalPrice))
        else
            -- Refund money if item addition failed
            Player.Functions.AddMoney('cash', totalPrice)
            SendNotification(source, 'Cửa hàng', 'Lỗi khi thêm vật phẩm!', 'error')
        end
    else
        SendNotification(source, 'Cửa hàng', 'Lỗi khi thanh toán!', 'error')
    end
end)

-- Callback to get player rods from inventory with metadata
QBCore.Functions.CreateCallback('xn_cauca:getPlayerRods', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({})
        return 
    end
    
    local rods = {}
    
    -- Get all inventory slots to check for rods with metadata
    for slot = 1, 50 do
        local item = GetSlotItem(source, slot)
        if item and item.name then
            -- Check if this item is a fishing rod
            for _, rodType in pairs(Config.RequiredItems.rods) do
                if item.name == rodType then
                    -- Get metadata information
                    local metadata = item.metadata or {}
                    local doHiem = metadata.DoHiem or "Unknown"
                    local tier = metadata.tier or GetRodTier(rodType)
                    
                    -- Find if this rod type already exists in our rods table
                    local existingRod = nil
                    for i, rod in ipairs(rods) do
                        if rod.item == rodType then
                            existingRod = rod
                            break
                        end
                    end
                    
                    if existingRod then
                        -- Add to existing count
                        existingRod.count = existingRod.count + (item.count or 1)
                        
                        -- Get durability information
                        local durability = item.metadata and item.metadata.durability or item.durability or 100
                        
                        -- Update metadata if this one has better info
                        if metadata.DoHiem and not existingRod.metadata.DoHiem then
                            existingRod.metadata = metadata
                            existingRod.doHiem = doHiem
                            existingRod.tier = tier
                        end
                        
                        -- Update durability if this item has lower durability (showing worst condition)
                        if durability < (existingRod.durability or 100) then
                            existingRod.durability = durability
                        end
                    else
                        -- Get durability information
                        local durability = item.metadata and item.metadata.durability or item.durability or 100
                        
                        -- Add new rod entry
                        table.insert(rods, {
                            item = rodType,
                            label = Config.FishingRods[rodType].name,
                            count = item.count or 1,
                            metadata = metadata,
                            doHiem = doHiem,
                            tier = tier,
                            slot = slot,
                            durability = durability
                        })
                    end
                    break
                end
            end
        end
    end
    
    -- Fallback: If no rods found with ox_inventory, try QBCore method
    if #rods == 0 then
        for _, rodType in pairs(Config.RequiredItems.rods) do
            local item = Player.Functions.GetItemByName(rodType)
            if item and item.amount > 0 then
                -- Create default metadata for legacy items
                local defaultMetadata = CreateRodMetadata(rodType)
                
                table.insert(rods, {
                    item = rodType,
                    label = Config.FishingRods[rodType].name,
                    count = item.amount,
                    metadata = defaultMetadata,
                    doHiem = defaultMetadata.DoHiem,
                    tier = defaultMetadata.tier,
                    slot = nil, -- No specific slot for QBCore items
                    durability = 100 -- Default durability for legacy items
                })
            end
        end
    end
    
    cb(rods)
end)

-- Callback to get player materials for upgrading
QBCore.Functions.CreateCallback('xn_cauca:getPlayerMaterials', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({})
        return 
    end
    
    local materials = {}
    
    -- Get money
    materials['money'] = Player.Functions.GetMoney('cash')
    
    -- Get all upgrade materials
    for material, _ in pairs(Config.RodUpgradeSystem.materialNames) do
        if material ~= 'money' then
            local item = Player.Functions.GetItemByName(material)
            materials[material] = item and item.amount or 0
            if Config.Debug then
                print(string.format("[FISHING DEBUG] Player %s has %d %s", Player.PlayerData.name, materials[material], material))
            end
        end
    end
    
    cb(materials)
end)

-- Callback to perform rod upgrade
QBCore.Functions.CreateCallback('xn_cauca:performRodUpgrade', function(source, cb, rodItem)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check if rod upgrade system is enabled
    if not Config.RodUpgradeSystem.enabled then
        cb({success = false, message = 'Hệ thống nâng cấp đã bị tắt'})
        return
    end
    
    -- Check if player has the rod
    local rodSlot = Player.Functions.GetItemByName(rodItem)
    if not rodSlot or rodSlot.amount <= 0 then
        cb({success = false, message = 'Bạn không có cần câu này'})
        return
    end
    
    -- Get upgrade requirements
    local upgradeReq = Config.RodUpgradeSystem.upgradeRequirements[rodItem]
    if not upgradeReq then
        cb({success = false, message = 'Cần câu này không thể nâng cấp'})
        return
    end
    
    -- Check if player has required materials
    for material, required in pairs(upgradeReq.materials) do
        if material == 'money' then
            local playerMoney = Player.Functions.GetMoney('cash')
            if Config.Debug then
                print(string.format("[FISHING DEBUG] Money check: Player has %d, needs %d", playerMoney, required))
            end
            if playerMoney < required then
                cb({success = false, message = 'Không đủ ⭐'})
                return
            end
        else
            local item = Player.Functions.GetItemByName(material)
            local playerAmount = item and item.amount or 0
            if Config.Debug then
                print(string.format("[FISHING DEBUG] Material check: Player has %d %s, needs %d", playerAmount, material, required))
            end
            if playerAmount < required then
                cb({success = false, message = 'Không đủ ' .. (Config.RodUpgradeSystem.materialNames[material] or material)})
                return
            end
        end
    end
    
    -- Remove materials first (before animation)
    for material, required in pairs(upgradeReq.materials) do
        if material == 'money' then
            Player.Functions.RemoveMoney('cash', required)
        else
            Player.Functions.RemoveItem(material, required)
        end
    end
    
    -- Remove old rod (before animation)
    Player.Functions.RemoveItem(rodItem, 1)
    
    -- Trigger immediate UI refresh to show removed materials and rod
    TriggerClientEvent('xn_cauca:refreshPanelData', source)
    
    -- Calculate upgrade success (before animation)
    local success = math.random(1, 100) <= upgradeReq.successRate
    
    -- Add 5 second delay to sync with client animation
    SetTimeout(5000, function()
        -- Re-check if player still exists after delay
        local PlayerAfterDelay = QBCore.Functions.GetPlayer(source)
        if not PlayerAfterDelay then 
            cb({success = false, message = 'Player disconnected during upgrade'})
            return 
        end
        
        if success then
            -- Create metadata for the new rod
            local newRodMetadata = CreateRodMetadata(upgradeReq.targetRod)
            
            -- Give new rod with metadata
            AddItem(source, upgradeReq.targetRod, 1, newRodMetadata)
            
            -- Notify player
            local rodName = Config.FishingRods[upgradeReq.targetRod].name
            local doHiem = newRodMetadata.DoHiem
            TriggerClientEvent('QBCore:Notify', source, string.format('Nâng cấp thành công! Nhận được %s (%s)', rodName, doHiem), 'success')
            
            -- Trigger UI refresh to show new rod
            TriggerClientEvent('xn_cauca:refreshPanelData', source)
            
            cb({
                success = true, 
                message = 'Nâng cấp thành công!',
                newRod = upgradeReq.targetRod,
                newRodRarity = doHiem
            })
        else
            -- Upgrade failed, give back some materials (optional)
            local refundPercent = 0.5 -- 50% refund on failure
            for material, required in pairs(upgradeReq.materials) do
                if material == 'money' then
                    PlayerAfterDelay.Functions.AddMoney('cash', math.floor(required * refundPercent))
                else
                    PlayerAfterDelay.Functions.AddItem(material, math.floor(required * refundPercent))
                end
            end
            
            -- Notify player
            TriggerClientEvent('QBCore:Notify', source, 'Nâng cấp thất bại! Hoàn lại 50% nguyên liệu', 'error')
            
            -- Trigger UI refresh to show refunded materials
            TriggerClientEvent('xn_cauca:refreshPanelData', source)
            
            cb({
                success = false, 
                message = 'Nâng cấp thất bại! Hoàn lại 50% nguyên liệu'
            })
        end
    end)
end)

-- Admin command to give upgrade materials (for testing)
-- RegisterCommand('givematerials', function(source, args, rawCommand)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end
    
--     -- Check if player is admin (you can customize this check)
--     if not QBCore.Functions.HasPermission(source, 'admin') then
--         TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
--         return
--     end
    
--     -- Give materials for testing
--     Player.Functions.AddItem('damatho', 50)
--     Player.Functions.AddItem('diamond', 50)
--     Player.Functions.AddMoney('cash', 50000)
    
--     TriggerClientEvent('QBCore:Notify', source, 'Đã cấp nguyên liệu nâng cấp cần câu', 'success')
-- end, false)

-- -- Admin command to check player materials
-- RegisterCommand('checkmaterials', function(source, args, rawCommand)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end
    
--     -- Check if player is admin
--     if not QBCore.Functions.HasPermission(source, 'admin') then
--         TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
--         return
--     end
    
--     local materials = {}
--     materials['money'] = Player.Functions.GetMoney('cash')
    
--     for material, _ in pairs(Config.RodUpgradeSystem.materialNames) do
--         if material ~= 'money' then
--             local item = Player.Functions.GetItemByName(material)
--             materials[material] = item and item.amount or 0
--         end
--     end
    
--     -- Print to console
--     print("=== PLAYER MATERIALS ===")
--     for material, amount in pairs(materials) do
--         print(string.format("%s: %d", Config.RodUpgradeSystem.materialNames[material] or material, amount))
--     end
--     print("========================")
    
--     TriggerClientEvent('QBCore:Notify', source, 'Kiểm tra console để xem nguyên liệu', 'info')
-- end, false)

-- Callback to get repair requirements for indestructible rods
QBCore.Functions.CreateCallback('xn_cauca:getRepairRequirements', function(source, cb, rodItem)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check if repair system is enabled
    if not Config.RodRepairSystem or not Config.RodRepairSystem.enabled then
        cb({success = false, message = 'Hệ thống sửa chữa đã bị tắt'})
        return
    end
    
    -- Check if this rod is indestructible and can be repaired
    local isIndestructible = false
    if Config.IndestructibleRods then
        for _, indestructibleRod in pairs(Config.IndestructibleRods) do
            if indestructibleRod == rodItem then
                isIndestructible = true
                break
            end
        end
    end
    
    if not isIndestructible then
        cb({success = false, message = 'Cần câu này không thể sửa chữa'})
        return
    end
    
    -- Get repair requirements
    local repairReq = Config.RodRepairSystem.repairRequirements[rodItem]
    if not repairReq then
        cb({success = false, message = 'Không tìm thấy yêu cầu sửa chữa cho cần câu này'})
        return
    end
    
    -- Check player's materials
    local materials = {}
    for material, required in pairs(repairReq.materials) do
        if material == 'money' then
            materials[material] = Player.Functions.GetMoney('cash')
        else
            local item = Player.Functions.GetItemByName(material)
            materials[material] = item and item.amount or 0
        end
    end
    
    cb({
        success = true,
        requirements = repairReq,
        playerMaterials = materials,
        rodName = Config.FishingRods[rodItem].name
    })
end)

-- Callback to perform rod repair
QBCore.Functions.CreateCallback('xn_cauca:performRodRepair', function(source, cb, rodItem, rodSlot)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({success = false, message = 'Player not found'})
        return 
    end
    
    -- Check if repair system is enabled
    if not Config.RodRepairSystem or not Config.RodRepairSystem.enabled then
        cb({success = false, message = 'Hệ thống sửa chữa đã bị tắt'})
        return
    end
    
    -- Get repair requirements
    local repairReq = Config.RodRepairSystem.repairRequirements[rodItem]
    if not repairReq then
        cb({success = false, message = 'Không tìm thấy yêu cầu sửa chữa cho cần câu này'})
        return
    end
    
    -- Check if player has the rod
    local rodData = Player.Functions.GetItemByName(rodItem)
    if not rodData or rodData.amount <= 0 then
        cb({success = false, message = 'Bạn không có cần câu này'})
        return
    end
    
    -- Check if player has enough materials
    for material, required in pairs(repairReq.materials) do
        local playerAmount = 0
        if material == 'money' then
            playerAmount = Player.Functions.GetMoney('cash')
        else
            local item = Player.Functions.GetItemByName(material)
            playerAmount = item and item.amount or 0
        end
        
        if playerAmount < required then
            cb({success = false, message = 'Không đủ ' .. (Config.RodUpgradeSystem.materialNames[material] or material)})
            return
        end
    end
    
    -- Find the rod in inventory to get its slot
    local actualRodSlot = nil
    for i = 1, 50 do
        local item = GetSlotItem(source, i)
        if item and item.name == rodItem then
            actualRodSlot = i
            break
        end
    end
    
    if not actualRodSlot then
        cb({success = false, message = 'Không tìm thấy cần câu trong túi đồ'})
        return
    end
    
    -- Remove materials
    for material, required in pairs(repairReq.materials) do
        if material == 'money' then
            Player.Functions.RemoveMoney('cash', required)
        else
            Player.Functions.RemoveItem(material, required)
        end
    end
    
    -- Repair the rod (set durability to repairAmount)
    local success = SetDurability(source, actualRodSlot, repairReq.repairAmount)
    
    if success then
        local rodName = Config.FishingRods[rodItem].name
        TriggerClientEvent('QBCore:Notify', source, string.format('Đã sửa chữa %s thành công!', rodName), 'success')
        
        -- Trigger UI refresh
        TriggerClientEvent('xn_cauca:refreshPanelData', source)
        
        cb({success = true, message = 'Sửa chữa thành công'})
    else
        -- Refund materials if repair failed
        for material, required in pairs(repairReq.materials) do
            if material == 'money' then
                Player.Functions.AddMoney('cash', required)
            else
                Player.Functions.AddItem(material, required)
            end
        end
        
        cb({success = false, message = 'Không thể sửa chữa cần câu'})
    end
end)

-- Admin command to test rod with metadata (for testing)
-- RegisterCommand('testrod', function(source, args, rawCommand)
--     local Player = QBCore.Functions.GetPlayer(source)
--     if not Player then return end
    
--     -- Check if player is admin
--     if not QBCore.Functions.HasPermission(source, 'admin') then
--         TriggerClientEvent('QBCore:Notify', source, 'Bạn không có quyền sử dụng lệnh này', 'error')
--         return
--     end
    
--     local rodType = args[1] or 'can_cau_go'
    
--     -- Check if rod type exists
--     if not Config.FishingRods[rodType] then
--         TriggerClientEvent('QBCore:Notify', source, 'Loại cần câu không tồn tại: ' .. rodType, 'error')
--         return
--     end
    
--     local metadata = CreateRodMetadata(rodType)
    
--     if AddItem(source, rodType, 1, metadata) then
--         local rodName = Config.FishingRods[rodType].name
--         TriggerClientEvent('QBCore:Notify', source, string.format('Đã nhận %s với metadata: %s (Tier %d)', rodName, metadata.DoHiem, metadata.tier), 'success')
--         print(string.format("[FISHING] Admin %s got %s with metadata: DoHiem=%s, tier=%d", Player.PlayerData.charinfo.firstname, rodType, metadata.DoHiem, metadata.tier))
--     else
--         TriggerClientEvent('QBCore:Notify', source, 'Lỗi khi thêm cần câu!', 'error')
--     end
-- end, false)

-- Register may_cau as usable item using qbx_core
exports.qbx_core:CreateUseableItem('may_cau', function(source, item)
    TriggerClientEvent('xn_cauca:client:useMayCau', source)
end)

-- Callback to get indestructible/upgradeable rods for repair (Level 2+)
QBCore.Functions.CreateCallback('xn_cauca:getIndestructibleRodsForRepair', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({rods = {}, mayCauCount = 0})
        return 
    end
    
    local rods = {}
    -- Scan slots to find fishing rods Level 2+ (fishingrod2, fishingrod3, fishingrod4, fishingrod5)
    for slot = 1, 100 do
        local item = GetSlotItem(source, slot)
        if item and item.name then
            if item.name == "fishingrod2" or item.name == "fishingrod3" or item.name == "fishingrod4" or item.name == "fishingrod5" then
                local durability = item.metadata and item.metadata.durability or item.durability or 100
                local requiredMayCau = Config.RodRepairSystem.repairRequirements[item.name] 
                                       and Config.RodRepairSystem.repairRequirements[item.name].materials['may_cau'] 
                                       or 1
                table.insert(rods, {
                    slot = slot,
                    name = item.name,
                    label = Config.FishingRods[item.name] and Config.FishingRods[item.name].name or item.name,
                    durability = durability,
                    requiredMayCau = requiredMayCau
                })
            end
        end
    end
    local mayCauCount = GetItemCount(source, 'may_cau')
    cb({
        rods = rods,
        mayCauCount = mayCauCount
    })
end)

-- Event to repair a fishing rod
exports['monitors']:RegisterProtectedEvent('xn_cauca:server:repairRod', function(source, slot, rodName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Get required may_cau count from config
    local requiredMayCau = Config.RodRepairSystem.repairRequirements[rodName] 
                           and Config.RodRepairSystem.repairRequirements[rodName].materials['may_cau'] 
                           or 1
    
    -- Verify the player still has the may_cau item
    local mayCauCount = GetItemCount(source, 'may_cau')
    if mayCauCount < requiredMayCau then
        SendNotification(source, 'Sửa chữa', string.format('Bạn không có đủ Máy câu để sửa chữa! (Cần %d máy câu)', requiredMayCau), 'error')
        return
    end
    
    -- Verify the rod in the slot
    local item = GetSlotItem(source, slot)
    if not item or item.name ~= rodName then
        SendNotification(source, 'Sửa chữa', 'Không tìm thấy cần câu tương ứng!', 'error')
        return
    end
    
    local durability = item.metadata and item.metadata.durability or item.durability or 100
    if durability > 50 then
        SendNotification(source, 'Sửa chữa', 'Cần câu có độ bền lớn hơn 50% không thể sửa chữa!', 'error')
        return
    end
    
    -- Consume may_cau
    if RemoveItem(source, 'may_cau', requiredMayCau) then
        -- Repair rod to 100% durability
        local success = SetDurability(source, slot, 100)
        if success then
            local label = Config.FishingRods[rodName] and Config.FishingRods[rodName].name or rodName
            SendNotification(source, 'Sửa chữa', string.format('Sửa chữa %s thành công!', label), 'success')
            TriggerClientEvent('xn_cauca:refreshPanelData', source)
        else
            -- Refund if durability failed to update
            AddItem(source, 'may_cau', requiredMayCau)
            SendNotification(source, 'Sửa chữa', 'Lỗi khi đặt độ bền cần câu!', 'error')
        end
    else
        SendNotification(source, 'Sửa chữa', 'Lỗi khi tiêu hao Máy câu!', 'error')
    end
end)

