QBCore = exports['qb-core']:GetCoreObject()

local isFishing = false
local currentZone = nil
local playerData = {}
local advancedZoneBlip = nil

-- Store fishing prop entity for cleanup
local fishingProp = nil

-- Debug function
local function DebugPrint(message)
    if Config.Debug then
        print("[FISHING CLIENT] " .. tostring(message))
    end
end

-- Simplified debug function for water detection
local function DebugWaterDetection(coords)
    if not Config.Debug then return end
    
    local waterLevel = GetWaterHeight(coords.x, coords.y, coords.z)
    
    print(string.format("[WATER DEBUG] Position: %.2f, %.2f, %.2f", coords.x, coords.y, coords.z))
    
    if waterLevel and type(waterLevel) == "number" and waterLevel ~= -1000000.0 then
        print(string.format("[WATER DEBUG] Water found at level: %.2f", waterLevel))
    else
        print("[WATER DEBUG] No water at player position")
    end
end

local function UpdateAdvancedZoneBlip(isOpen)
    if isOpen then
        if not advancedZoneBlip then
            local zoneData = nil
            for _, zone in ipairs(Config.FishingZones) do
                if zone.name == "advanced_zone" then
                    zoneData = zone
                    break
                end
            end
            
            if zoneData then
                advancedZoneBlip = AddBlipForCoord(zoneData.coords.x, zoneData.coords.y, zoneData.coords.z)
                SetBlipSprite(advancedZoneBlip, 68)
                SetBlipDisplay(advancedZoneBlip, 2)
                SetBlipScale(advancedZoneBlip, 1.0)
                SetBlipColour(advancedZoneBlip, 1) -- Red color
                SetBlipAsShortRange(advancedZoneBlip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(zoneData.Label or "Khu câu cá cao cấp")
                EndTextCommandSetBlipName(advancedZoneBlip)
                DebugPrint("Advanced fishing zone blip created (Open)")
            end
        end
    else
        if advancedZoneBlip then
            RemoveBlip(advancedZoneBlip)
            advancedZoneBlip = nil
            DebugPrint("Advanced fishing zone blip removed (Closed)")
        end
    end
end

RegisterNetEvent('xn_cauca:setZoneState')
AddEventHandler('xn_cauca:setZoneState', function(zoneName, isOpen)
    if zoneName == "advanced_zone" then
        UpdateAdvancedZoneBlip(isOpen)
    end
end)

-- Level calculation functions
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

local function GetCurrentLevelProgress(currentXP)
    if not Config.EnableXPSystem then
        return 0, 0
    end
    
    local currentLevel = GetLevelFromXP(currentXP)
    if currentLevel >= Config.MaxLevel then
        return 100, 100 -- Max level
    end
    
    local currentLevelXP = Config.RequiredXP[currentLevel] or 0
    local nextLevelXP = Config.RequiredXP[currentLevel + 1] or 0
    local progressXP = currentXP - currentLevelXP
    local totalXPNeeded = nextLevelXP - currentLevelXP
    
    return progressXP, totalXPNeeded
end

-- Initialize player data (Event-driven system - No more loops!)
local function UpdatePlayerData()
    QBCore.Functions.TriggerCallback('xn_cauca:getPlayerData', function(data)
        if data then
            playerData = data
            
            -- Update dynamic blips based on zoneStates returned from server
            if data.zoneStates then
                for zoneName, isOpen in pairs(data.zoneStates) do
                    if zoneName == "advanced_zone" then
                        UpdateAdvancedZoneBlip(isOpen)
                    end
                end
            end
            
            -- Get player XP from SQL database instead of metadata
            if Config.EnableXPSystem then
                QBCore.Functions.TriggerCallback('xn_cauca:getPlayerFishingXP', function(xp)
                    playerData.xp = xp or 0
                    DebugPrint(string.format("Player data updated - XP: %d", playerData.xp))
                end)
            else
                playerData.xp = 0
                DebugPrint("Player data updated - XP system disabled")
            end
        end
    end)
end

-- Initialize player data on resource start
CreateThread(function()
    -- Wait for player to be loaded
    while not QBCore.Functions.GetPlayerData().citizenid do
        Wait(1000)
    end
    
    -- Initial load
    UpdatePlayerData()
end)

-- Update player data when needed (events)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    DebugPrint("Player loaded - updating data")
    UpdatePlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    DebugPrint("Player unloaded - clearing data")
    playerData = {}
end)

-- Custom event to refresh player data when XP changes
RegisterNetEvent('xn_cauca:refreshPlayerData')
AddEventHandler('xn_cauca:refreshPlayerData', function()
    DebugPrint("XP changed - refreshing player data")
    UpdatePlayerData()
end)

-- Zone detection variables
local inZone = false
local currentZone = nil
local lastZoneCheck = 0

-- Function to check zones (called on-demand)
local function CheckFishingZones()
    local currentTime = GetGameTimer()
    
    -- Throttle checks to prevent spam (max once per 2 seconds)
    if currentTime - lastZoneCheck < 2000 then
        return
    end
    lastZoneCheck = currentTime
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local wasInZone = inZone
    local oldZone = currentZone
    
    inZone = false
    currentZone = nil
    
    -- Check against FishingZones instead of FishingBlips for proper zone data
    for i, zoneData in ipairs(Config.FishingZones) do
        local distance = #(playerCoords - zoneData.coords)
        
        if distance <= zoneData.radius then
            inZone = true
            currentZone = zoneData
            break
        end
    end
    
    -- Only notify if zone status changed
    if inZone ~= wasInZone or currentZone ~= oldZone then
        if inZone and currentZone then
            DebugPrint(string.format("Entered fishing zone: %s", currentZone.name))
        elseif wasInZone then
            DebugPrint("Left fishing zone")
        end
    end
end

-- Check if player is in fishing zone (Event-driven)
function IsInFishingZone()
    CheckFishingZones() -- Force check
    return currentZone
end

-- Check if player meets XP requirements
function CanFishInZone(zone)
    if not Config.EnableXPSystem then
        return true -- XP system disabled, allow all zones
    end
    
    -- Check if zone is valid
    if not zone or not zone.requiredXP or not zone.maxXP then
        DebugPrint("ERROR: Invalid zone data in CanFishInZone")
        return false
    end
    
    local playerXP = playerData.xp or 0 -- Default to 0 if nil
    return playerXP >= zone.requiredXP and playerXP <= zone.maxXP
end

-- Enhanced water detection function
-- Simplified water detection function
function IsNearWater(coords)
    if Config.Debug then
        DebugWaterDetection(coords)
    end
    
    -- Simple water detection - just check if there's water at player position
    local waterLevel = GetWaterHeight(coords.x, coords.y, coords.z)
    
    if waterLevel and type(waterLevel) == "number" and waterLevel ~= -1000000.0 then
        if Config.Debug then
            print("[WATER DEBUG] Water detected at player position")
        end
        return true
    end
    
    -- If enhanced detection is enabled, check around player
    if Config.WaterDetection.enabled then
        local checkRadius = Config.WaterDetection.checkRadius or 5.0
        
        -- Check 4 points around player (simplified from 8 points)
        for i = 1, 4 do
            local angle = (i - 1) * 90.0  -- 0°, 90°, 180°, 270°
            local radians = math.rad(angle)
            local offsetX = math.cos(radians) * checkRadius
            local offsetY = math.sin(radians) * checkRadius
            
            local checkX = coords.x + offsetX
            local checkY = coords.y + offsetY
            local checkWaterLevel = GetWaterHeight(checkX, checkY, coords.z)
            
            if checkWaterLevel and type(checkWaterLevel) == "number" and checkWaterLevel ~= -1000000.0 then
                if Config.Debug then
                    print(string.format("[WATER DEBUG] Water found at angle %d°", angle))
                end
                return true
            end
        end
    end
    
    if Config.Debug then
        print("[WATER DEBUG] No water detected")
    end
    return false
end

-- Check if player has any fishing rod
function GetPlayerFishingRod()
    for _, rodType in pairs(Config.RequiredItems.rods) do
        local rodCount = exports.ox_inventory:Search('count', rodType)
        if rodCount and rodCount > 0 then
            -- Get rod with durability info
            local rodData = exports.ox_inventory:Search('slots', rodType)
            if rodData and rodData[1] then
                -- Check durability from metadata first, then fallback to item durability
                local durability = 100
                if rodData[1].metadata and rodData[1].metadata.durability then
                    durability = rodData[1].metadata.durability
                elseif rodData[1].durability then
                    durability = rodData[1].durability
                end
                
                -- Update the data with correct durability
                rodData[1].durability = durability
                
                return {
                    type = rodType,
                    data = rodData[1],
                    config = Config.FishingRods[rodType]
                }
            end
        end
    end
    return nil
end

-- Check if player has any fishing rod for specific zone
function GetPlayerFishingRodForZone(zone)
    for _, rodType in pairs(zone.allowedRods) do
        local rodCount = exports.ox_inventory:Search('count', rodType)
        if rodCount and rodCount > 0 then
            -- Get rod with durability info
            local rodData = exports.ox_inventory:Search('slots', rodType)
            if rodData and rodData[1] then
                -- Check durability from metadata first, then fallback to item durability
                local durability = 100
                if rodData[1].metadata and rodData[1].metadata.durability then
                    durability = rodData[1].metadata.durability
                elseif rodData[1].durability then
                    durability = rodData[1].durability
                end
                
                -- Update the data with correct durability
                rodData[1].durability = durability
                
                return {
                    type = rodType,
                    data = rodData[1],
                    config = Config.FishingRods[rodType]
                }
            end
        end
    end
    return nil
end

-- Check if player has a specific fishing rod for a zone
function GetPlayerSpecificRodForZone(rodType, zone)
    -- Check if this rod is allowed in the zone
    local isAllowed = false
    for _, allowedRod in pairs(zone.allowedRods) do
        if allowedRod == rodType then
            isAllowed = true
            break
        end
    end
    
    if not isAllowed then
        return nil
    end
    
    -- Check if player has this specific rod
    local rodCount = exports.ox_inventory:Search('count', rodType)
    if rodCount and rodCount > 0 then
        -- Get rod with durability info
        local rodData = exports.ox_inventory:Search('slots', rodType)
        if rodData and rodData[1] then
            -- Check durability from metadata first, then fallback to item durability
            local durability = 100
            if rodData[1].metadata and rodData[1].metadata.durability then
                durability = rodData[1].metadata.durability
            elseif rodData[1].durability then
                durability = rodData[1].durability
            end
            
            -- Update the data with correct durability
            rodData[1].durability = durability
            
            return {
                type = rodType,
                data = rodData[1],
                config = Config.FishingRods[rodType]
            }
        end
    end
    return nil
end

-- Validate all fishing conditions
function ValidateFishingConditions(zone, specificRodType)
    -- Check if already fishing
    if isFishing then
        lib.notify({
            title = 'Câu cá',
            description = 'Bạn đang câu cá!',
            type = 'error'
        })
        return false
    end
    
    -- Check if in water or near water using improved detection
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    if not IsNearWater(playerCoords) then
        lib.notify({
            title = 'Câu cá',
            description = 'Bạn cần ở gần nước để câu cá!',
            type = 'error'
        })
        return false
    end
    
    -- Check if in fishing zone
    if not zone then
        lib.notify({
            title = 'Câu cá',
            description = 'Bạn không ở trong khu vực câu cá!',
            type = 'error'
        })
        return false
    end
    
    -- Time restriction is verified secure on server-side.
    
    -- Check XP requirements
    if not CanFishInZone(zone) then
        local playerXP = playerData.xp or 0 -- Default to 0 if nil
        local requiredLevel = GetLevelFromXP(zone.requiredXP)
        local currentLevel = GetLevelFromXP(playerXP)
        lib.notify({
            title = 'Câu cá',
            description = string.format('Cần cấp độ %d (%d XP) để câu ở đây! (Cấp độ hiện tại: %d - %d XP)', 
                requiredLevel, zone.requiredXP, currentLevel, playerXP),
            type = 'error'
        })
        return false
    end
    
    -- Check if has fishing rod suitable for this zone
    local playerRod
    if specificRodType then
        -- When using a specific rod (from export), check if player has it and if it's suitable
        playerRod = GetPlayerSpecificRodForZone(specificRodType, zone)
    else
        -- Default behavior - find any suitable rod
        playerRod = GetPlayerFishingRodForZone(zone)
    end
    
    if not playerRod then
        -- Check if player has any rod but not suitable for this zone
        local hasAnyRod = GetPlayerFishingRod()
        if hasAnyRod then
            lib.notify({
                title = 'Câu cá',
                description = string.format('Cần câu %s không phù hợp với khu vực này!', hasAnyRod.config.name),
                type = 'error'
            })
        else
            lib.notify({
                title = 'Câu cá',
                description = 'Bạn cần có cần câu để bắt đầu câu cá!',
                type = 'error'
            })
        end
        return false
    end
    
    -- Check rod durability - check if it will break after use
    local currentDurabilityPercent = playerRod.data.durability or 100
    local rodConfig = playerRod.config
    local damageAfterUse = currentDurabilityPercent - (rodConfig.durabilityLoss or 10)
    
    if currentDurabilityPercent <= 0 then
        lib.notify({
            title = 'Câu cá',
            description = string.format('%s đã hỏng! Hãy sửa chữa hoặc thay thế.', playerRod.config.name),
            type = 'error'
        })
        return false
    end
    
    -- Check if player is on foot
    if IsPedInAnyVehicle(playerPed, false) then
        lib.notify({
            title = 'Câu cá',
            description = 'Bạn không thể câu cá khi đang trong xe!',
            type = 'error'
        })
        return false
    end
    
    -- Check if player is not swimming
    if IsPedSwimming(playerPed) then
        lib.notify({
            title = 'Câu cá',
            description = 'Bạn không thể câu cá khi đang bơi!',
            type = 'error'
        })
        return false
    end
    
    -- Check if has bait by checking ox_inventory directly
    local baitCount = exports.ox_inventory:Search('count', Config.RequiredItems.bait)
    if not baitCount or baitCount <= 0 then
        lib.notify({
            title = 'Câu cá',
            description = 'Bạn cần có mồi câu để bắt đầu câu cá!',
            type = 'error'
        })
        return false
    end
    
    -- Store rod info for later use
    playerData.currentRod = playerRod
    
    return true
end

-- Export function for ox_inventory item usage
exports('useFishingRod', function(data, slot)
    DebugPrint("useFishingRod export called with data: " .. tostring(data and data.name or "nil"))
    
    -- Ensure we have valid data
    if not data then
        DebugPrint("ERROR: No data provided to useFishingRod export")
        if lib and lib.notify then
            lib.notify({
                title = 'Câu cá',
                description = 'Lỗi: Không có dữ liệu cần câu!',
                type = 'error'
            })
        end
        return
    end
    
    -- Check if player data is loaded
    if not playerData or not QBCore.Functions.GetPlayerData().citizenid then
        DebugPrint("ERROR: Player data not loaded yet - attempting to load")
        
        -- Try to load player data first
        UpdatePlayerData()
        
        if lib and lib.notify then
            lib.notify({
                title = 'Câu cá',
                description = 'Đang tải dữ liệu người chơi, vui lòng thử lại sau ít giây!',
                type = 'success'
            })
        end
        return
    end
    
    -- Use the specific rod type from the item data
    local rodType = data.name or data.item
    
    if not rodType then
        DebugPrint("ERROR: No rod type found in data")
        if lib and lib.notify then
            lib.notify({
                title = 'Câu cá',
                description = 'Lỗi: Không thể xác định loại cần câu!',
                type = 'error'
            })
        end
        return
    end
    
    -- Check if this is a valid fishing rod
    if not Config.FishingRods[rodType] then
        DebugPrint("ERROR: Invalid rod type: " .. tostring(rodType))
        if lib and lib.notify then
            lib.notify({
                title = 'Câu cá',
                description = 'Lỗi: Loại cần câu không hợp lệ!',
                type = 'error'
            })
        end
        return
    end
    
    DebugPrint("Starting fishing with rod type: " .. tostring(rodType))
    StartFishing(rodType)
end)

-- Start fishing process
function StartFishing(specificRodType)
    local zone = IsInFishingZone()
    
    if not ValidateFishingConditions(zone, specificRodType) then
        return
    end
    
    local rodInfo = playerData.currentRod
    
    -- Use the specific rod type passed from item usage, or fall back to detected rod
    local rodType = specificRodType
    if not rodType and rodInfo then
        rodType = rodInfo.type
    end
    
    -- If still no rod type, show error
    if not rodType then
        lib.notify({
            title = 'Câu cá',
            description = 'Không thể xác định loại cần câu!',
            type = 'error'
        })
        return
    end
    
    -- Set fishing state immediately without confirmation dialog
    isFishing = true
    currentZone = zone
    
    -- Send the specific rod type that was used
    if Config.EnableXPSystem then
        -- Get current XP from SQL database
        QBCore.Functions.TriggerCallback('xn_cauca:getPlayerFishingXP', function(currentXP)
            DebugPrint(string.format("Starting fishing with specific rod: %s (XP: %d)", rodType, currentXP))
            exports['monitors']:TriggerProtectedServerEvent('xn_cauca:validateFishing', zone, currentXP, rodType, 0)
        end)
    else
        -- XP system disabled, send 0 XP
        DebugPrint(string.format("Starting fishing with specific rod: %s (XP System Disabled)", rodType))
        exports['monitors']:TriggerProtectedServerEvent('xn_cauca:validateFishing', zone, 0, rodType, 0)
    end
end

-- Register item usage through server event instead of registerHook
RegisterNetEvent('xn_cauca:useFishingRod')
AddEventHandler('xn_cauca:useFishingRod', function()
    StartFishing(nil) -- When called from server, use detected rod
end)

-- Handle server fishing validation result
RegisterNetEvent('xn_cauca:fishingResult')
AddEventHandler('xn_cauca:fishingResult', function(success, reason, zoneData)
    if not success then
        isFishing = false
        currentZone = nil
        
        local errorMessages = {
            LEVEL_REQUIREMENT = 'Bạn không đủ cấp độ để câu ở đây!',
            NO_ROD = 'Bạn không có cần câu!',
            NO_BAIT = 'Bạn không có mồi câu!',
            BAIT_REMOVE_FAILED = 'Không thể sử dụng mồi câu!',
            ROD_BROKEN = 'Cần câu đã hỏng trong quá trình sử dụng!',
            TIME_RESTRICTION = 'Khu vực này chỉ mở cửa vào khung giờ nhất định!'
        }
        
        local description = errorMessages[reason] or 'Có lỗi xảy ra!'
        if reason == 'TIME_RESTRICTION' and zoneData and zoneData.allowedHours then
            description = string.format('Khu vực này chỉ mở cửa vào khung giờ: %s!', Config.GetAllowedHoursString(zoneData.allowedHours))
        end
        
        lib.notify({
            title = 'Câu cá',
            description = description,
            type = 'error'
        })
        return
    end
    
    -- Success - start fishing animation and process
    currentZone = zoneData
    BeginFishingProcess()
end)

-- Helper function to get random fish from zone based on weighted probabilities
local function GetRandomFishFromZone(zone)
    if not zone or not zone.fish or #zone.fish == 0 then
        return nil
    end
    
    if zone.fishRates then
        local totalWeight = 0
        for _, fishName in ipairs(zone.fish) do
            totalWeight = totalWeight + (zone.fishRates[fishName] or 0)
        end
        
        if totalWeight > 0 then
            local randomValue = math.random(1, totalWeight)
            local currentSum = 0
            for _, fishName in ipairs(zone.fish) do
                currentSum = currentSum + (zone.fishRates[fishName] or 0)
                if randomValue <= currentSum then
                    return fishName
                end
            end
        end
    end
    
    -- Fallback to uniform distribution if no rates are configured
    local fishIndex = math.random(1, #zone.fish)
    return zone.fish[fishIndex]
end

-- Begin actual fishing process (Optimized)
function BeginFishingProcess()
    local playerPed = PlayerPedId()
    
    -- Use custom animation instead of scenario to have better control
    local animDict = "amb@world_human_stand_fishing@idle_a"
    local animName = "idle_c"
    
    -- Load animation with timeout (using config)
    RequestAnimDict(animDict)
    local animAttempts = 0
    while not HasAnimDictLoaded(animDict) and animAttempts < Config.Performance.maxLoadAttempts do
        Wait(Config.Performance.loadWaitTime)
        animAttempts = animAttempts + 1
    end
    
    if not HasAnimDictLoaded(animDict) then
        DebugPrint("Failed to load fishing animation")
        -- Continue without animation
    end
    
    -- Create fishing rod prop manually for better control
    local propModel = GetHashKey("prop_fishing_rod_01")
    RequestModel(propModel)
    local propAttempts = 0
    while not HasModelLoaded(propModel) and propAttempts < Config.Performance.maxLoadAttempts do
        Wait(Config.Performance.loadWaitTime)
        propAttempts = propAttempts + 1
    end
    
    if HasModelLoaded(propModel) then
        -- Create and attach the prop
        local playerCoords = GetEntityCoords(playerPed)
        fishingProp = CreateObject(propModel, playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
        
        -- Attach to player hand
        AttachEntityToEntity(fishingProp, playerPed, GetPedBoneIndex(playerPed, 18905), 0.1, 0.05, 0.0, 80.0, 120.0, 160.0, true, true, false, true, 1, true)
        
        -- Clean up model
        SetModelAsNoLongerNeeded(propModel)
    else
        DebugPrint("Failed to load fishing prop model")
    end
    
    -- Play animation if loaded
    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    end
    
    -- Play animation
    TaskPlayAnim(playerPed, animDict, animName, 8.0, 8.0, -1, 1, 0, false, false, false)
    
    lib.notify({
        title = 'Câu cá',
        description = 'Đang câu cá... Hãy kiên nhẫn!',
        type = 'success'
    })
    
    -- Pre-select fish to determine fishing time
    if not currentZone or not currentZone.fish or #currentZone.fish == 0 then
        lib.notify({
            title = 'Lỗi',
            description = 'Không thể tìm thấy cá ở khu vực này!',
            type = 'error'
        })
        return
    end
    
    local selectedFish = GetRandomFishFromZone(currentZone)
    if not selectedFish then
        lib.notify({
            title = 'Lỗi',
            description = 'Không thể chọn cá ở khu vực này!',
            type = 'error'
        })
        return
    end
    local fishConfig = Config.FishSettings[selectedFish]
    
    -- Calculate fishing time based on fish rarity
    local baseTime = math.random(Config.FishingTime.min, Config.FishingTime.max)
    local rarityMultiplier = Config.FishingTime.rarityMultiplier[fishConfig.rarity] or 1.0
    local fishingDuration = math.floor(baseTime * rarityMultiplier)
    
    -- Debug log for fishing time calculation
    DebugPrint(string.format("Fishing time calculation: Fish=%s, Rarity=%s, BaseTime=%dms, Multiplier=%.1f, FinalTime=%dms", 
        selectedFish, fishConfig.rarity, baseTime, rarityMultiplier, fishingDuration))
    
    local startTime = GetGameTimer()
    while GetGameTimer() - startTime < fishingDuration do
        Wait(0)
        if IsControlJustReleased(0, 73) or IsControlJustReleased(0, 200) then -- X key hoặc ESC để hủy
            StopFishing()
            return false -- Hủy câu cá
        end
    end
    StartFishingMinigame(selectedFish)
    return true
    -- Hoàn thành thời gian câu cá -- Pass the pre-selected fish
    -- -- Show progress bar
    -- if lib.progressBar({
    --     duration = fishingDuration,
    --     label = string.format('Đang câu cá... (%s)', fishConfig.rarity == "common" and "Thường" or 
    --                                                  fishConfig.rarity == "uncommon" and "Hiếm" or
    --                                                  fishConfig.rarity == "rare" and "Rất hiếm" or
    --                                                  fishConfig.rarity == "epic" and "Sử thi" or "Huyền thoại"),
    --     useWhileDead = false,
    --     canCancel = true,
    --     disable = {
    --         car = true,
    --         move = true,
    --         combat = true
    --     }
    -- }) then
    --     if isFishing then
    --         StartFishingMinigame(selectedFish) -- Pass the pre-selected fish
    --     end
    -- else
    --     StopFishing()
    --     lib.notify({
    --         title = 'Câu cá',
    --         description = 'Đã hủy câu cá!',
    --         type = 'error'
    --     })
    -- end
end

-- Start fishing minigame
function StartFishingMinigame(preSelectedFish)
    if not currentZone then return end
    
    -- Use pre-selected fish or select random fish from zone
    local selectedFish = preSelectedFish
    if not selectedFish then
        selectedFish = GetRandomFishFromZone(currentZone)
    end
    
    if not selectedFish then
        StopFishing()
        return
    end
    
    local fishConfig = Config.FishSettings[selectedFish]
    
    if not fishConfig then
        StopFishing()
        return
    end
    
    -- Get difficulty info for display
    local difficultyText = "Dễ"
    if fishConfig.difficulty == "medium" then
        difficultyText = "Trung bình"
    elseif fishConfig.difficulty == "hard" then
        difficultyText = "Khó"
    elseif fishConfig.difficulty == "veryhard" then
        difficultyText = "Rất khó"
    end
    
    local rarityText = ""
    if fishConfig.rarity == "uncommon" then
        rarityText = " (Hiếm)"
    elseif fishConfig.rarity == "rare" then
        rarityText = " (Rất hiếm)"
    elseif fishConfig.rarity == "epic" then
        rarityText = " (Sử thi)"
    elseif fishConfig.rarity == "legendary" then
        rarityText = " (Huyền thoại)"
    end
    
    lib.notify({
        title = 'Câu cá',
        description = string.format('🐟 %s%s cắn câu!\n🎯 Độ khó: %s\n⌨️ Hoàn thành minigame!', 
            fishConfig.name, rarityText, difficultyText),
        type = 'success',
        duration = 3000
    })
    
    -- Small delay to let player read the notification
    Wait(1500)
    
    -- Start the fishing minigame using fishing-minigame
    exports["fishing-minigame"]:startFishing(fishConfig.difficulty, function(success)
        if success then
            DisableControlAction(0, 24, true)
            -- Success - give fish and XP with celebratory message
            local xpGained = fishConfig.xpReward or 0
            local successEmoji = "🎉"
            
            if fishConfig.rarity == "rare" then
                successEmoji = "✨"
            elseif fishConfig.rarity == "epic" then
                successEmoji = "🌟"
            elseif fishConfig.rarity == "legendary" then
                successEmoji = "👑"
            end
            
            if Config.EnableXPSystem and xpGained > 0 then
                lib.notify({
                    title = 'Thành công!',
                    description = string.format('%s Xuất sắc! Bạn đã câu được %s%s!\n🏆 Nhận được %d XP câu cá', 
                        successEmoji, fishConfig.name, rarityText, xpGained),
                    type = 'success',
                    duration = 4000
                })
                
                -- Add XP using SQL database system
                TriggerServerEvent('xn_cauca:addFishingXP', xpGained)
            else
                lib.notify({
                    title = 'Thành công!',
                    description = string.format('%s Xuất sắc! Bạn đã câu được %s%s!', 
                        successEmoji, fishConfig.name, rarityText),
                    type = 'success',
                    duration = 3000
                })
            end
            
            -- Rod durability already damaged when item was used
            exports['monitors']:TriggerProtectedServerEvent('xn_cauca:giveFish', selectedFish, 1)
            -- TriggerServerEvent('xn_cauca:giveFish', selectedFish, 1)
            
            -- Create fish ped at player's feet
            CreateFishPed(selectedFish)
            
            Wait(1000)
            DisableControlAction(0, 24, false)
        else
            -- Failed with encouraging message
            local failureMessages = {
                "không thể chịu được sức mạnh của bạn và đã thoát!",
                "đã cắn đứt dây câu và bơi đi!",
                "quá nhanh nhẹn và đã thoát khỏi lưỡi câu!",
                "đã chiến thắng trong cuộc đấu này!",
                "không dễ bị bắt và đã rời đi!"
            }
            local randomMessage = failureMessages[math.random(#failureMessages)]
            
            lib.notify({
                title = 'Thất bại',
                description = string.format('💔 %s %s\n🎣 Đừng bỏ cuộc, hãy thử lại!', fishConfig.name, randomMessage),
                type = 'error',
                duration = 3000
            })
        end
        
        StopFishing()
    end)
end

-- Stop fishing
function StopFishing()
    isFishing = false
    currentZone = nil
    -- Clear currentRod reference
    if playerData then
        playerData.currentRod = nil
    end
    
    local playerPed = PlayerPedId()
    
    -- Delete our manually created prop first
    if fishingProp and DoesEntityExist(fishingProp) then
        DeleteEntity(fishingProp)
        fishingProp = nil
        DebugPrint("Deleted manually created fishing prop")
    end
    
    -- Clear all tasks immediately
    ClearPedTasks(playerPed)
    ClearPedTasksImmediately(playerPed)
    
    -- Force stop any animations
    StopAnimTask(playerPed, "amb@world_human_stand_fishing@idle_a", "idle_c", 1.0)
    
    -- Additional cleanup for any scenario-created props (Optimized with config)
    CreateThread(function()
        -- Use config values for cleanup
        for i = 1, Config.Performance.propCleanupAttempts do
            Wait(Config.Performance.propCleanupWaitTime)
            
            local playerCoords = GetEntityCoords(playerPed)
            local fishingRodHashes = {
                GetHashKey("prop_fishing_rod_01"),
                GetHashKey("prop_fishing_rod_02"), 
                GetHashKey("prop_fishing_rod_03"),
                GetHashKey("w_me_fishingrod")
            }
            
            -- Only use GetClosestObjectOfType - avoid expensive GetGamePool
            for _, propHash in ipairs(fishingRodHashes) do
                local closestObj = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 3.0, propHash, false, false, false)
                if DoesEntityExist(closestObj) then
                    DeleteObject(closestObj)
                    DebugPrint(string.format("Deleted prop: %d", propHash))
                end
            end
        end
    end)
    
    -- Set player to normal state
    SetEntityHeading(playerPed, GetEntityHeading(playerPed))
    
    DebugPrint("Fishing stopped and props cleaned up")
end


-- Optimized blip creation
local blips = {}
local zoneBlips = {}

CreateThread(function()
    -- Wait for game to be fully loaded
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    -- Create blips from config (only once)
    for i, blipData in ipairs(Config.FishingBlips) do
        -- Main blip
        local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
        SetBlipSprite(blip, blipData.sprite)
        SetBlipDisplay(blip, 2)
        SetBlipScale(blip, blipData.scale)
        SetBlipColour(blip, blipData.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.name)
        EndTextCommandSetBlipName(blip)
        
        blips[i] = blip
        
        -- Zone circle blip only if enabled
        if blipData.showZoneCircle then
            local zoneBlip = AddBlipForRadius(blipData.coords.x, blipData.coords.y, blipData.coords.z, blipData.distance)
            SetBlipColour(zoneBlip, blipData.zoneCircleColor)
            SetBlipAlpha(zoneBlip, 100)
            zoneBlips[i] = zoneBlip
        end
    end
end)

-- Check zones when player moves significantly (Event-driven)
local lastPlayerPos = vector3(0, 0, 0)
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Only check if player moved more than 50 units
        local distance = #(playerCoords - lastPlayerPos)
        if distance > 50.0 then
            CheckFishingZones()
            lastPlayerPos = playerCoords
        end
        
        Wait(5000) -- Check every 5 seconds instead of constantly
    end
end)

-- Fishing NPC Configuration
local fishingNPC = nil
local fishingNPCCoords = Config.FishingShop.npcLocation
local fishingNPCHeading = Config.FishingShop.npcHeading

-- Create Fishing NPC (Optimized)
CreateThread(function()
    -- Wait for game to be fully loaded
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    -- Request model with better error handling (using config)
    local model = GetHashKey("s_m_y_fishing_01")
    RequestModel(model)
    
    local attempts = 0
    while not HasModelLoaded(model) and attempts < Config.Performance.maxLoadAttempts do
        Wait(Config.Performance.loadWaitTime * 2) -- Double wait time for NPC loading
        attempts = attempts + 1
    end
    
    if not HasModelLoaded(model) then
        print("[FISHING] Failed to load NPC model after 5 seconds")
        return
    end
    
    -- Create NPC
    fishingNPC = CreatePed(4, model, fishingNPCCoords.x, fishingNPCCoords.y, fishingNPCCoords.z, fishingNPCHeading, false, true)
    
    -- Set NPC properties
    FreezeEntityPosition(fishingNPC, true)
    SetEntityInvincible(fishingNPC, true)
    SetPedDiesWhenInjured(fishingNPC, false)
    SetPedCanPlayAmbientAnims(fishingNPC, true)
    SetPedCanRagdollFromPlayerImpact(fishingNPC, false)
    SetEntityCanBeDamaged(fishingNPC, false)
    SetBlockingOfNonTemporaryEvents(fishingNPC, true)
    
    -- Add blip for NPC
    local blip = AddBlipForEntity(fishingNPC)
    SetBlipSprite(blip, 68)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 3)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Cửa hàng câu cá")
    EndTextCommandSetBlipName(blip)
    
    -- Clean up model
    SetModelAsNoLongerNeeded(model)
end)

-- NPC Interaction (Optimized with config)
local isNearNPC = false
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - fishingNPCCoords)
        
        if distance < Config.Performance.npcInteractionDistance then -- Use config value
            if distance < 3.0 then
                if not isNearNPC then
                    isNearNPC = true
                    if lib then
                        lib.showTextUI('[E] Nói chuyện với người bán')
                    end
                end
                
                if IsControlJustReleased(0, 38) then -- E key
                    OpenFishingShop()
                end
                Wait(0) -- Only run every frame when close
            else
                if isNearNPC then
                    isNearNPC = false
                    if lib then
                        lib.hideTextUI()
                    end
                end
                Wait(Config.Performance.npcInteractionNearWait) -- Use config value
            end
        else
            if isNearNPC then
                isNearNPC = false
                if lib then
                    lib.hideTextUI()
                end
            end
            Wait(Config.Performance.npcInteractionFarWait) -- Use config value
        end
    end
end)

-- Open Fishing Shop Menu
function OpenFishingShop()
    if Config.EnableXPSystem then
        -- Get player XP first
        QBCore.Functions.TriggerCallback('xn_cauca:getPlayerFishingXP', function(currentXP)
            ShowFishingShopMenu(currentXP)
        end)
    else
        ShowFishingShopMenu(0)
    end
end

-- Show Fishing Shop Menu
function ShowFishingShopMenu(playerXP)
    local contextMenu = {
        {
            title = 'Cửa hàng câu cá',
            description = 'Chào mừng đến với cửa hàng câu cá!',
            icon = 'fas fa-fish',
            disabled = true
        }
    }
    
    -- Add XP check option if XP system is enabled
    if Config.EnableXPSystem then
        local currentLevel = GetLevelFromXP(playerXP)
        local xpToNext = GetXPForNextLevel(playerXP)
        local progressXP, totalXPNeeded = GetCurrentLevelProgress(playerXP)
        
        table.insert(contextMenu, {
            title = 'Kiểm tra kinh nghiệm',
            description = string.format('Kinh nghiệm câu cá hiện tại: %d XP', playerXP),
            icon = 'fas fa-chart-line',
            onSelect = function()
                lib.notify({
                    title = 'Kinh nghiệm câu cá',
                    description = string.format('Bạn có %d XP câu cá', playerXP),
                    type = 'success'
                })
            end
        })
        
        -- Calculate level with proper XP table
        local levelDescription
        if currentLevel >= Config.MaxLevel then
            levelDescription = string.format('Cấp độ tối đa: %d', currentLevel)
        else
            levelDescription = string.format('Cấp độ hiện tại: %d (Cần %d XP cho cấp tiếp theo)', currentLevel, xpToNext)
        end
        
        table.insert(contextMenu, {
            title = 'Cấp độ câu cá',
            description = levelDescription,
            icon = 'fas fa-star',
            onSelect = function()
                local progressText
                if currentLevel >= Config.MaxLevel then
                    progressText = string.format('Bạn đã đạt cấp độ tối đa %d!', currentLevel)
                else
                    progressText = string.format('Cấp độ %d - Tiến độ: %d/%d XP (%d XP nữa)', 
                        currentLevel, progressXP, totalXPNeeded, xpToNext)
                end
                
                lib.notify({
                    title = 'Cấp độ câu cá',
                    description = progressText,
                    type = 'success'
                })
            end
        })
    end
    
    -- Add separator
    table.insert(contextMenu, {
        title = '──────────────',
        icon = 'fas fa-minus',
        disabled = true
    })
    
    -- Add fishing rod purchase option
    table.insert(contextMenu, {
        title = 'Mua cần câu gỗ',
        description = string.format('Giá: $%d - Cần câu cơ bản cho người mới bắt đầu', Config.FishingShop.prices.rods['can_cau_go']),
        icon = 'fas fa-shopping-cart',
        onSelect = function()
            BuyFishingRod()
        end
    })
    
    -- Add bait purchase option
    table.insert(contextMenu, {
        title = 'Mua mồi câu',
        description = string.format('Giá: $%d/cái - Cần thiết để câu cá', Config.FishingShop.prices.bait),
        icon = 'fas fa-shopping-basket',
        onSelect = function()
            BuyBait()
        end
    })
    
    -- Add fishing zones info
    table.insert(contextMenu, {
        title = 'Thông tin khu vực câu cá',
        description = 'Xem thông tin các khu vực câu cá',
        icon = 'fas fa-map-marked-alt',
        onSelect = function()
            ShowFishingZonesInfo()
        end
    })
    
    -- Add upgrade rod option
    table.insert(contextMenu, {
        title = 'Nâng cấp cần câu',
        description = 'Nâng cấp cần câu của bạn để có hiệu suất tốt hơn',
        icon = 'fas fa-arrow-up',
        onSelect = function()
            OpenFishingPanel()
        end
    })
    
    lib.registerContext({
        id = 'fishing_shop',
        title = 'Cửa hàng câu cá',
        options = contextMenu
    })
    
    lib.showContext('fishing_shop')
end

-- Buy Fishing Rod Function
function BuyFishingRod()
    local input = lib.inputDialog('Mua cần câu gỗ', {
        {
            type = 'number',
            label = 'Số lượng',
            description = 'Nhập số lượng cần câu muốn mua',
            required = true,
            min = 1,
            max = 10
        }
    })
    
    if input and input[1] then
        local quantity = tonumber(input[1])
        if quantity and quantity > 0 then
            exports['monitors']:TriggerProtectedServerEvent('xn_cauca:buyFishingRod', 'can_cau_go', quantity)
        end
    end
end

-- Buy Bait Function
function BuyBait()
    local input = lib.inputDialog('Mua mồi câu', {
        {
            type = 'number',
            label = 'Số lượng',
            description = 'Nhập số lượng mồi câu muốn mua',
            required = true,
            min = 1,
            max = 100
        }
    })
    
    if input and input[1] then
        local quantity = tonumber(input[1])
        if quantity and quantity > 0 then
            exports['monitors']:TriggerProtectedServerEvent('xn_cauca:buyBait', quantity)
        end
    end
end

-- Show Fishing Zones Info
function ShowFishingZonesInfo()
    local zonesMenu = {
        {
            title = 'Thông tin khu vực câu cá',
            description = 'Danh sách các khu vực câu cá có sẵn',
            icon = 'fas fa-water',
            disabled = true
        }
    }
    
    for _, zone in pairs(Config.FishingZones) do
        local requiredLevel = GetLevelFromXP(zone.requiredXP)
        local requiredText = ''
        if Config.EnableXPSystem then
            if zone.requiredXP > 0 then
                requiredText = string.format(' (Cần cấp độ %d - %d XP)', requiredLevel, zone.requiredXP)
            else
                requiredText = ' (Tất cả cấp độ)'
            end
        end
        local fishList = table.concat(zone.fish, ', ')
        
        local timeText = ''
        if zone.allowedHours then
            timeText = string.format(' | Giờ mở cửa: %s', Config.GetAllowedHoursString(zone.allowedHours))
        end
        
        table.insert(zonesMenu, {
            title = zone.Label or zone.name,
            description = string.format('Cá có thể câu: %s%s%s', fishList, requiredText, timeText),
            icon = 'fas fa-fish'
        })
    end
    
    lib.registerContext({
        id = 'fishing_zones_info',
        title = 'Khu vực câu cá',
        menu = 'fishing_shop',
        options = zonesMenu
    })
    
    lib.showContext('fishing_zones_info')
end

-- NUI Management
local nuiOpen = false

-- Function to open fishing panel
function OpenFishingPanel()
    if nuiOpen then return end
    
    -- Get player data
    local playerData = QBCore.Functions.GetPlayerData()
    local playerName = playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
    
    -- Get player fishing XP
    QBCore.Functions.TriggerCallback('xn_cauca:getPlayerFishingXP', function(playerXP)
        local currentLevel = GetLevelFromXP(playerXP)
        local nextLevelXP = Config.RequiredXP[currentLevel + 1] or Config.RequiredXP[Config.MaxLevel]
        
        -- Get current rods from inventory
        QBCore.Functions.TriggerCallback('xn_cauca:getPlayerRods', function(rods)
            -- Build all zones list
            local allZones = {}
            for _, z in ipairs(Config.FishingZones) do
                allZones[#allZones + 1] = {
                    name        = z.name,
                    label       = z.Label or z.name or "Khu câu cá",
                    requiredXP  = z.requiredXP or 0,
                    fish        = z.fish or {},
                    allowedRods = z.allowedRods or {}
                }
            end

            -- Detect current zone name (if inside one)
            local currentZoneName = nil
            local zone = IsInFishingZone()
            if zone then currentZoneName = zone.name end

            local panelData = {
                playerName      = playerName,
                level           = currentLevel,
                currentXP       = playerXP,
                nextLevelXP     = nextLevelXP,
                currentRods     = rods,
                allZones        = allZones,
                currentZoneName = currentZoneName
            }

            -- Open NUI
            SetNuiFocus(true, true)
            nuiOpen = true

            SendNUIMessage({
                action = 'openPanel',
                data   = panelData
            })
        end)
    end)
end

-- Function to close fishing panel
function CloseFishingPanel()
    if not nuiOpen then return end
    
    SetNuiFocus(false, false)
    nuiOpen = false
    
    SendNUIMessage({
        action = 'closePanel'
    })
end

-- Function to refresh panel data without reopening NUI
function RefreshPanelData()
    if not nuiOpen then return end  -- Only refresh if panel is open
    
    -- Get player data
    local playerData = QBCore.Functions.GetPlayerData()
    local playerName = playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
    
    -- Get player fishing XP
    QBCore.Functions.TriggerCallback('xn_cauca:getPlayerFishingXP', function(playerXP)
        local currentLevel = GetLevelFromXP(playerXP)
        local nextLevelXP = Config.RequiredXP[currentLevel + 1] or Config.RequiredXP[Config.MaxLevel]
        
        -- Get current rods from inventory
        QBCore.Functions.TriggerCallback('xn_cauca:getPlayerRods', function(rods)
            -- Build all zones list
            local allZones = {}
            for _, z in ipairs(Config.FishingZones) do
                allZones[#allZones + 1] = {
                    name        = z.name,
                    label       = z.Label or z.name or "Khu câu cá",
                    requiredXP  = z.requiredXP or 0,
                    fish        = z.fish or {},
                    allowedRods = z.allowedRods or {}
                }
            end

            local currentZoneName = nil
            local zone = IsInFishingZone()
            if zone then currentZoneName = zone.name end

            local panelData = {
                playerName      = playerName,
                level           = currentLevel,
                currentXP       = playerXP,
                nextLevelXP     = nextLevelXP,
                currentRods     = rods,
                allZones        = allZones,
                currentZoneName = currentZoneName
            }

            -- Send updated data to NUI
            SendNUIMessage({
                action = 'updateData',
                data   = panelData
            })
        end)
    end)
end


-- NUI Callbacks
RegisterNUICallback('panelOpened', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('panelClosed', function(data, cb)
    CloseFishingPanel()
    cb('ok')
end)

RegisterNUICallback('performUpgrade', function(data, cb)
    local rodItem = data.rodItem
    
    -- Trigger server-side upgrade
    QBCore.Functions.TriggerCallback('xn_cauca:performRodUpgrade', function(result)
        -- Send result to NUI (this will happen after 5 second server delay)
        SendNUIMessage({
            action = 'upgradeResult',
            result = result
        })
        
        -- Refresh panel data after receiving server response with small delay
        -- to ensure inventory is updated on server side
        SetTimeout(500, function()
            RefreshPanelData()
        end)
    end, rodItem)
    
    cb('ok')
end)

RegisterNUICallback('refreshPanel', function(data, cb)
    -- Refresh panel data after upgrade animation with small delay
    SetTimeout(200, function()
        RefreshPanelData()
    end)
    cb('ok')
end)

RegisterNUICallback('performRepair', function(data, cb)
    local rodItem = data.rodItem
    local rodSlot = data.rodSlot
    
    -- Trigger server-side repair
    QBCore.Functions.TriggerCallback('xn_cauca:performRodRepair', function(result)
        -- Send result to NUI
        SendNUIMessage({
            action = 'repairResult',
            result = result
        })
        
        -- Refresh panel data after receiving server response
        SetTimeout(500, function()
            RefreshPanelData()
        end)
    end, rodItem, rodSlot)
    
    cb('ok')
end)

RegisterNUICallback('getRepairRequirements', function(data, cb)
    local rodItem = data.rodItem
    
    -- Get repair requirements from server
    QBCore.Functions.TriggerCallback('xn_cauca:getRepairRequirements', function(result)
        cb(result)
    end, rodItem)
end)

-- Event to trigger immediate panel refresh when materials are removed
RegisterNetEvent('xn_cauca:refreshPanelData')
AddEventHandler('xn_cauca:refreshPanelData', function()
    RefreshPanelData()
end)

-- Fishing Panel NPC Configuration
local fishingPanelNPC = nil
local fishingPanelNPCCoords = vector3(190.2856, -907.0928, 31.5268)
local fishingPanelNPCHeading = 176.3828

-- Create Fishing Panel NPC
CreateThread(function()
    -- Wait for game to be fully loaded
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    -- Request model
    local model = GetHashKey("s_m_y_construct_02") -- Construction worker model
    RequestModel(model)
    
    local attempts = 0
    while not HasModelLoaded(model) and attempts < Config.Performance.maxLoadAttempts do
        Wait(Config.Performance.loadWaitTime * 2)
        attempts = attempts + 1
    end
    
    if not HasModelLoaded(model) then
        print("[FISHING] Failed to load Fishing Panel NPC model after 5 seconds")
        return
    end
    
    -- Create NPC
    fishingPanelNPC = CreatePed(4, model, fishingPanelNPCCoords.x, fishingPanelNPCCoords.y, fishingPanelNPCCoords.z - 1.0, fishingPanelNPCHeading, false, true)
    
    -- Set NPC properties
    FreezeEntityPosition(fishingPanelNPC, true)
    SetEntityInvincible(fishingPanelNPC, true)
    SetPedDiesWhenInjured(fishingPanelNPC, false)
    SetPedCanPlayAmbientAnims(fishingPanelNPC, true)
    SetPedCanRagdollFromPlayerImpact(fishingPanelNPC, false)
    SetEntityCanBeDamaged(fishingPanelNPC, false)
    SetBlockingOfNonTemporaryEvents(fishingPanelNPC, true)
    
    -- Add blip for NPC
    local blip = AddBlipForEntity(fishingPanelNPC)
    SetBlipSprite(blip, 280) -- Hammer icon for upgrade/crafting
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5) -- Yellow color
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Cần thủ")
    EndTextCommandSetBlipName(blip)
    
    -- Add ox_target interaction
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(fishingPanelNPC, {
            {
                name = 'fishing_upgrade_panel',
                icon = 'fas fa-tools',
                label = 'Thông tin cần thủ',
                onSelect = function()
                    OpenFishingPanel()
                end,
                distance = 2.5
            }
        })
        DebugPrint("Added ox_target interaction for Fishing Panel NPC")
    else
        DebugPrint("ox_target not found, using fallback interaction")
        -- Fallback interaction without ox_target
        CreateThread(function()
            local isNearUpgradeNPC = false
            while DoesEntityExist(fishingPanelNPC) do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - fishingPanelNPCCoords)
                
                if distance < 3.0 then
                    if not isNearUpgradeNPC then
                        isNearUpgradeNPC = true
                        if lib then
                            lib.showTextUI('[E] Nâng cấp cần câu')
                        end
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        OpenFishingPanel()
                    end
                    Wait(0)
                else
                    if isNearUpgradeNPC then
                        isNearUpgradeNPC = false
                        if lib then
                            lib.hideTextUI()
                        end
                    end
                    Wait(500)
                end
            end
        end)
    end
    
    -- Clean up model
    SetModelAsNoLongerNeeded(model)
    DebugPrint("Fishing Panel NPC created successfully")
end)

-- Cleanup when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Clean up fishing panel NPC
        if fishingPanelNPC and DoesEntityExist(fishingPanelNPC) then
            if GetResourceState('ox_target') == 'started' then
                exports.ox_target:removeLocalEntity(fishingPanelNPC, 'fishing_upgrade_panel')
            end
            DeleteEntity(fishingPanelNPC)
            fishingPanelNPC = nil
            DebugPrint("Fishing Panel NPC cleaned up")
        end
        
        -- Clean up fishing shop NPC
        if fishingNPC and DoesEntityExist(fishingNPC) then
            DeleteEntity(fishingNPC)
            fishingNPC = nil
            DebugPrint("Fishing Shop NPC cleaned up")
        end
        
        -- Clean up fishing prop if exists
        if fishingProp and DoesEntityExist(fishingProp) then
            DeleteEntity(fishingProp)
            fishingProp = nil
        end
        
        -- Clean up dynamic advanced zone blip if exists
        if advancedZoneBlip then
            RemoveBlip(advancedZoneBlip)
            advancedZoneBlip = nil
        end
    end
end)

-- Create fish ped at player's feet after catching a fish
function CreateFishPed(fishType)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Fish ped models (you can customize these based on your fish types)
    local fishPedModels = {
        -- Common fish
        ["tramco"] = "a_c_fish",
        ["rophi"] = "a_c_fish", 
        ["cachep"] = "a_c_fish",
        
        -- Intermediate fish
        ["ca_chim"] = "a_c_fish",
        ["ca_hoi"] = "a_c_fish",
        
        -- Advanced fish
        ["ca_thu"] = "a_c_fish",
        ["tom_hum"] = "a_c_fish", -- or "a_c_crab" if available
        ["ca_ngu"] = "a_c_fish",
        ["shark"] = "a_c_sharktiger", -- shark ped model
        
        -- Special fish
        ["keysiver"] = "a_c_fish"
    }
    
    -- Default fish ped if specific model not found
    local pedModel = fishPedModels[fishType] or "a_c_fish"
    local pedHash = GetHashKey(pedModel)
    
    -- Request the model
    RequestModel(pedHash)
    local attempts = 0
    while not HasModelLoaded(pedHash) and attempts < 50 do
        Wait(50)
        attempts = attempts + 1
    end
    
    if HasModelLoaded(pedHash) then
        -- Create the fish ped closer to player and slightly above ground for drop effect
        local pedCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 0.5, 0.0) -- Closer to player (0.5 instead of 1.0)
        
        -- Adjust Z coordinate to be on the ground
        local groundZ = pedCoords.z
        local foundGround, groundHeight = GetGroundZFor_3dCoord(pedCoords.x, pedCoords.y, pedCoords.z, groundZ, false)
        if foundGround then
            groundZ = groundHeight
        end
        
        -- Create ped above ground for drop effect (1.5 units above ground)
        local dropHeight = groundZ + 1.5
        local fishPed = CreatePed(1, pedHash, pedCoords.x, pedCoords.y, dropHeight, 0.0, true, true)
        
        if DoesEntityExist(fishPed) then
            -- Enable physics so it can fall
            SetEntityCollision(fishPed, true, true)
            SetPedCanRagdoll(fishPed, true)
            
            -- Make the ped look dead/caught but allow physics initially
            SetEntityHealth(fishPed, 0)
            SetEntityCanBeDamaged(fishPed, false)
            SetPedCanBeTargetted(fishPed, false)
            SetEntityInvincible(fishPed, true)
            
            -- Apply slight downward velocity for more realistic drop
            SetEntityVelocity(fishPed, 0.0, 0.0, -2.0)
            
            -- Wait a moment then apply ragdoll for falling effect
            SetTimeout(100, function()
                if DoesEntityExist(fishPed) then
                    SetPedToRagdoll(fishPed, 3000, 3000, 0, true, true, false)
                end
            end)
            
            -- After 1 second, freeze the ped in place (after it hits ground)
            SetTimeout(1000, function()
                if DoesEntityExist(fishPed) then
                    FreezeEntityPosition(fishPed, true)
                end
            end)
            
            -- Make it smaller if it's a regular fish (not shark)
            if fishType ~= "shark" then
                SetPedComponentVariation(fishPed, 0, 0, 0, 0)
                -- You can also use SetEntityScale if supported
                -- SetEntityScale(fishPed, 0.5) -- Make it smaller
            end
            
            DebugPrint(string.format("Created fish ped %s at player's feet with drop effect", pedModel))
            
            -- Set a timer to delete the ped after 3 seconds
            SetTimeout(3000, function()
                if DoesEntityExist(fishPed) then
                    DeleteEntity(fishPed)
                    DebugPrint(string.format("Deleted fish ped %s after 3 seconds", pedModel))
                end
            end)
        else
            DebugPrint(string.format("Failed to create fish ped %s", pedModel))
        end
        
        -- Clean up model
        SetModelAsNoLongerNeeded(pedHash)
    else
        DebugPrint(string.format("Failed to load fish ped model %s", pedModel))
    end
end

-- Client event to handle may_cau usage
RegisterNetEvent('xn_cauca:client:useMayCau')
AddEventHandler('xn_cauca:client:useMayCau', function()
    QBCore.Functions.TriggerCallback('xn_cauca:getIndestructibleRodsForRepair', function(data)
        local rods = data.rods
        local mayCauCount = data.mayCauCount or 0
        
        if not rods or #rods == 0 then
            lib.notify({
                title = 'Sửa chữa cần câu',
                description = 'Không tìm thấy cần câu LV2 trở lên nào trong túi đồ!',
                type = 'error'
            })
            return
        end
        
        local options = {}
        for _, rod in ipairs(rods) do
            local canRepair = rod.durability <= 50
            local hasEnoughBait = mayCauCount >= rod.requiredMayCau
            
            local description = string.format('Độ bền: %.1f%% | Cần: %d Máy câu (Bạn có: %d)', rod.durability, rod.requiredMayCau, mayCauCount)
            if not canRepair then
                description = description .. ' (Độ bền > 50%, không cần sửa)'
            elseif not hasEnoughBait then
                description = description .. ' (Không đủ Máy câu)'
            end
            
            table.insert(options, {
                title = rod.label,
                description = description,
                icon = 'fas fa-tools',
                onSelect = function()
                    if not canRepair then
                        lib.notify({
                            title = 'Sửa chữa',
                            description = 'Cần câu có độ bền lớn hơn 50% không thể sửa chữa!',
                            type = 'error'
                        })
                        return
                    end
                    
                    if not hasEnoughBait then
                        lib.notify({
                            title = 'Sửa chữa',
                            description = string.format('Bạn không có đủ Máy câu! Cần %d Máy câu nhưng bạn chỉ có %d.', rod.requiredMayCau, mayCauCount),
                            type = 'error'
                        })
                        return
                    end
                    
                    -- Confirmation menu
                    lib.registerContext({
                        id = 'confirm_repair_rod',
                        title = 'Xác nhận sửa chữa',
                        menu = 'may_cau_repair_menu',
                        options = {
                            {
                                title = 'Sửa chữa',
                                description = string.format('Tiêu hao %d Máy câu để sửa về 100%% độ bền', rod.requiredMayCau),
                                icon = 'fas fa-check',
                                onSelect = function()
                                    -- Perform progress bar with animation and prop in hand
                                    if lib.progressBar({
                                        duration = 5000,
                                        label = 'Đang sửa chữa cần câu...',
                                        useLibClip = true,
                                        anim = {
                                            dict = 'mini@repair',
                                            clip = 'fixing_a_ped'
                                        },
                                        prop = {
                                            model = `prop_fishing_rod_01`,
                                            bone = 18905,
                                            pos = vec3(0.1, 0.05, 0.0),
                                            rot = vec3(80.0, 120.0, 160.0)
                                        },
                                        disable = {
                                            car = true,
                                            move = true,
                                            combat = true
                                        }
                                    }) then
                                        -- Trigger server to consume item and update durability
                                        exports['monitors']:TriggerProtectedServerEvent('xn_cauca:server:repairRod', rod.slot, rod.name)
                                    else
                                        lib.notify({
                                            title = 'Sửa chữa',
                                            description = 'Đã hủy sửa chữa!',
                                            type = 'warning'
                                        })
                                    end
                                end
                            },
                            {
                                title = 'Hủy',
                                icon = 'fas fa-times',
                                onSelect = function()
                                    lib.showContext('may_cau_repair_menu')
                                end
                            }
                        }
                    })
                    lib.showContext('confirm_repair_rod')
                end
            })
        end
        
        lib.registerContext({
            id = 'may_cau_repair_menu',
            title = '🔧 Sửa chữa cần câu',
            options = options
        })
        lib.showContext('may_cau_repair_menu')
    end)
end)
