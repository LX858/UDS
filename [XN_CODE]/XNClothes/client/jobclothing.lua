-- Import QBCore and ox_lib
local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Khởi tạo biến global
PlayerJobName = nil
PlayerJobGrade = nil
isJobClothingMode = false
currentJobData = {}

-- Helper function to get all job clothing shops (support both old and new config)
local function GetAllJobShops()
    local shops = {}
    local jobsAdded = {} -- Track which jobs we've already added
    
    -- New config (prioritized)
    if Config.JobClothingShops then
        for _, shop in ipairs(Config.JobClothingShops) do
            table.insert(shops, shop)
            jobsAdded[shop.job] = true -- Mark this job as added from new config
        end
    end
    
    -- Old config (backward compatible - but skip if job already in new config)
    if Config.JobOutifs then
        for _, shop in ipairs(Config.JobOutifs) do
            if not jobsAdded[shop.job] then
                table.insert(shops, shop)
            end
        end
    end
    
    return shops
end

-- Wait for player data to be loaded
Citizen.CreateThread(function()
	-- Wait for QBCore to be ready
	while not QBCore do
		Wait(100)
	end
	
	-- Wait for player data
	while not QBCore.Functions.GetPlayerData().job do
		Wait(100)
	end
	
	local PlayerData = QBCore.Functions.GetPlayerData()
	if PlayerData and PlayerData.job then
		PlayerJobName = PlayerData.job.name
		PlayerJobGrade = PlayerData.job.grade.level
		--print("^2[JobClothes] Job data initialized - Job:", PlayerJobName, "Grade:", PlayerJobGrade, "^0")
	else
		--print("^1[JobClothes] ERROR: Could not load player job data^0")
	end
end)

-- Update job when it changes
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
	if job then
		PlayerJobName = job.name
		PlayerJobGrade = job.grade.level
		--print("^3[JobClothes] Job updated - Job:", PlayerJobName, "Grade:", PlayerJobGrade, "^0")
	end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	local PlayerData = QBCore.Functions.GetPlayerData()
	if PlayerData and PlayerData.job then
		PlayerJobName = PlayerData.job.name
		PlayerJobGrade = PlayerData.job.grade.level
		--print("^2[JobClothes] Player loaded - Job:", PlayerJobName, "Grade:", PlayerJobGrade, "^0")
	end
end)

-- Function để lấy job hiện tại
local function GetCurrentJob()
	-- Luôn ưu tiên lấy từ QBCore trực tiếp
	local PlayerData = QBCore.Functions.GetPlayerData()
	if PlayerData and PlayerData.job and PlayerData.job.name then
		return PlayerData.job.name, PlayerData.job.grade.level
	end
	
	-- Fallback về global variables
	return PlayerJobName, PlayerJobGrade
end

function PlayerHasIsJob(job)
	local currentJob, currentGrade = GetCurrentJob()
	return currentJob ~= nil and job == currentJob
end

local function getSkinParts(component_id)
    local mapping = {
        [1] = "mask_1",      -- Masque
        [3] = "arms",        -- Bras
        [4] = "pants_1",     -- Pantalon
        [5] = "bags_1",      -- Sac
        [6] = "shoes_1",     -- Chaussures
        [7] = "chain_1",     -- Chaîne
        [8] = "tshirt_1",    -- T-shirt
        [9] = "bproof_1",    -- Gilet pare-balles
        [10] = "decals_1",   -- Décalcomanies
        [11] = "torso_1",    -- Torso
    }
    return mapping[component_id]
end

local function getSkinColorParts(component_id)
    local mapping = {
        [1] = "mask_2",      -- Masque texture
        [3] = "arms_2",      -- Bras texture
        [4] = "pants_2",     -- Pantalon texture
        [5] = "bags_2",      -- Sac texture
        [6] = "shoes_2",     -- Chaussures texture
        [7] = "chain_2",     -- Chaîne texture
        [8] = "tshirt_2",    -- T-shirt texture
        [9] = "bproof_2",    -- Gilet pare-balles texture
        [10] = "decals_2",   -- Décalcomanies texture
        [11] = "torso_2",    -- Torso texture
    }
    return mapping[component_id]
end

local function getPropParts(prop_id)
    local mapping = {
        [0] = "helmet_1",    -- Chapeau
        [1] = "glasses_1",   -- Lunettes
        [2] = "ears_1",      -- Boucles d'oreilles
        [6] = "watches_1",   -- Montre
        [7] = "bracelets_1", -- Bracelets
    }
    return mapping[prop_id]
end

local function getPropColorParts(prop_id)
    local mapping = {
        [0] = "helmet_2",    -- Chapeau texture
        [1] = "glasses_2",   -- Lunettes texture
        [2] = "ears_2",      -- Boucles d'oreilles texture
        [6] = "watches_2",   -- Montre texture
        [7] = "bracelets_2", -- Bracelets texture
    }
    return mapping[prop_id]
end

local function isPlayerNearJobLocker()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local allShops = GetAllJobShops()
    
    for _, jobData in ipairs(allShops) do
        if jobData.pos then
            local dist = #(playerCoords - jobData.pos)
            if dist < 2.0 and PlayerHasIsJob(jobData.job) then
                return true, jobData
            end
        end
    end
    return false, nil
end

local function applyJobOutfit(outfit)
    if LocalPlayer.state.vxAirdropActive then return end
    local ped = PlayerPedId()
    local isFemale = IsPedModel(ped, `mp_f_freemode_01`)
    local sex = isFemale and "female" or "male"
    local data = outfit[sex]
    TriggerServerEvent('clothes:gived', data, sex)

    if Config and Config.UseIllenium then
        if data.components then
            exports['illenium-appearance']:setPedComponents(ped, data.components)
        end
        if data.props then
            exports['illenium-appearance']:setPedProps(ped, data.props)
        end
        local appearance = exports['illenium-appearance']:getPedAppearance(ped)
        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    else
        if data.components then
            for _, comp in ipairs(data.components) do
                local skinPart = getSkinParts(comp.component_id)
                local skinColor = getSkinColorParts(comp.component_id)
                if skinPart then
                    TriggerEvent('skinchanger:change', skinPart, comp.drawable)
                end
                if skinColor then
                    TriggerEvent('skinchanger:change', skinColor, comp.texture)
                end
            end
        end
        if data.props then
            for _, prop in ipairs(data.props) do
                local propPart = getPropParts(prop.prop_id)
                local propColor = getPropColorParts(prop.prop_id)
                if propPart then
                    TriggerEvent('skinchanger:change', propPart, prop.drawable)
                end
                if propColor then
                    TriggerEvent('skinchanger:change', propColor, prop.texture)
                end
            end
        end
        
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerServerEvent('esx_skin:save', skin)
        end)
    end
end

-- Helper function để get allowed items cho grade
local function GetAllowedItemsForGrade(jobConfig, playerGrade)
    if not jobConfig.allowedItems then
        return nil
    end
    
    -- Tìm grade cao nhất mà player có quyền
    local allowedItems = nil
    local highestGrade = -1
    
    for grade, items in pairs(jobConfig.allowedItems) do
        local gradeNum = tonumber(grade)
        if gradeNum and gradeNum <= playerGrade and gradeNum > highestGrade then
            highestGrade = gradeNum
            allowedItems = items
        end
    end
    
    return allowedItems
end

-- Helper function để check if drawable is allowed
local function IsDrawableAllowed(allowedList, drawable)
    if allowedList == "all" then
        return true
    end
    
    if type(allowedList) == "table" then
        for _, allowed in ipairs(allowedList) do
            if allowed == drawable then
                return true
            end
        end
    end
    
    return false
end

-- Function mở job clothing shop với allowed items
function OpenJobClothingShop(jobData, playerGrade)
    if not jobData then
        --print("^1[JobClothes] ERROR: No job data^0")
        QBCore.Functions.Notify("Configuration manquante", "error")
        return
    end
    
    local playerPed = PlayerPedId()
    local isFemale = IsPedModel(playerPed, `mp_f_freemode_01`)
    local sex = isFemale and "female" or "male"
    
    --print("^2[JobClothes] Opening job clothing - Job:", jobData.job, "Grade:", playerGrade, "Sex:", sex, "^0")
    --print("^3[DEBUG] jobData has allowedItems:", jobData.allowedItems ~= nil)
    --print("^3[DEBUG] jobData has outfits:", jobData.outfits ~= nil)
    
    -- Get allowed items for this grade
    local allowedItems = GetAllowedItemsForGrade(jobData, playerGrade)
    
    -- Debug
    --print("^3[DEBUG] allowedItems type:", type(allowedItems))
    if allowedItems then
        --print("^3[DEBUG] allowedItems:", json.encode(allowedItems))
        if allowedItems[sex] then
            --print("^3[DEBUG] Found items for sex:", sex)
        else
            --print("^1[DEBUG] No items for sex:", sex)
        end
    end
    
    if not allowedItems or not allowedItems[sex] then
        QBCore.Functions.Notify("Aucun vêtement disponible pour votre grade", "error")
        --print("^1[JobClothes] No items configured for grade", playerGrade, "and sex", sex, "^0")
        return
    end
    
    local genderItems = allowedItems[sex]
    --print("^2[JobClothes] Allowed components:", json.encode(genderItems.components or {}))
    --print("^2[JobClothes] Allowed props:", json.encode(genderItems.props or {}))
    
    -- Store job clothing data globally
    isJobClothingMode = true
    currentJobData = {
        job = jobData.job,
        grade = playerGrade,
        sex = sex,
        allowedComponents = genderItems.components or {},
        allowedProps = genderItems.props or {}
    }
    
    -- Freeze player
    FreezeEntityPosition(PlayerPedId(), true)
    
    -- Save current outfit
    if saveCurrentOutfit then
        savedOutfit = saveCurrentOutfit()
    end
    
    -- Create camera
    if createCameraForPlayer then
        createCameraForPlayer()
    end
    
    -- Open NUI in job clothing mode
    --print("^2[JobClothes] Opening NUI in job clothing mode^0")
    
    -- Setup NUI manually (don't use toggleNuiFrame - it loads inventory items)
    if Config.Animation then
        PlayAnimation(Config.AnimationName, Config.AnimationName2)
    end
    getAllPriceClothes()
    SetNuiFocus(true, true)
    
    -- Generate clothing data in the format NUI expects (same as getAllClothes())
    local playerPed = PlayerPedId()
    local clothesData = {}
    
    -- Loop through all component categories in componentMapping
    for category, mapping in pairs(componentMapping) do
        local componentId = mapping.component
        local isProp = mapping.prop
        
        if isProp then
            -- This is a prop
            local currentIndex = GetPedPropIndex(playerPed, componentId)
            local maxDrawables = GetNumberOfPedPropDrawableVariations(playerPed, componentId)
            
            -- Check if this prop is allowed (props use string keys in config)
            if genderItems.props and genderItems.props[tostring(componentId)] then
                local allowedList = genderItems.props[tostring(componentId)]
                
                clothesData[category] = {
                    max = maxDrawables,
                    current = currentIndex,
                    currentTexture = GetPedPropTextureIndex(playerPed, componentId),
                    maxTextures = GetNumberOfPedPropTextureVariations(playerPed, componentId, currentIndex),
                    allowedDrawables = allowedList  -- Add allowed list for NUI filtering
                }
            end
        else
            -- This is a component (components are arrays indexed by component ID)
            local currentIndex = GetPedDrawableVariation(playerPed, componentId)
            local maxDrawables = GetNumberOfPedDrawableVariations(playerPed, componentId)
            
            -- Check if this component is allowed (components use numeric array index)
            if genderItems.components and genderItems.components[componentId] then
                local allowedList = genderItems.components[componentId]
                
                clothesData[category] = {
                    max = maxDrawables,
                    current = currentIndex,
                    currentTexture = GetPedTextureVariation(playerPed, componentId),
                    maxTextures = GetNumberOfPedTextureVariations(playerPed, componentId, currentIndex),
                    allowedDrawables = allowedList  -- Add allowed list for NUI filtering
                }
            end
        end
    end
    
    local categoriesCount = 0
    for _ in pairs(clothesData) do categoriesCount = categoriesCount + 1 end
    --print("^2[JobClothes] Generated clothing data for", categoriesCount, "categories^0")
    
    -- Debug: --print which categories were created
    --print("^3[DEBUG] Categories created:")
    for category, data in pairs(clothesData) do
        --print("  -", category, "max:", data.max, "allowedDrawables:", json.encode(data.allowedDrawables))
    end
    
    -- Send all NUI setup messages (same as toggleNuiFrame but with our data)
    SendReactMessage('setVisible', true)
    
    QBCore.Functions.TriggerCallback('clothes:isstaff', function(isStaff)
        SendReactMessage('setIsStaff', isStaff)
    end)
    
    SendReactMessage('SaveOutfit', Config.SaveOutfit)
    SendReactMessage('setBlackListClothes', Config.BlackList[sex] or {})
    SendReactMessage('setUrl', Config.Url)
    SendReactMessage('setExtension', Config.Extension)
    SendReactMessage('setServerLogo', Config.ServerLogo)
    
    -- Create list of categories from clothesData
    local categoryList = {}
    for category, _ in pairs(clothesData) do
        table.insert(categoryList, category)
    end
    --print("^3[DEBUG] Sending categories to NUI:", json.encode(categoryList))
    SendReactMessage('setCategory', categoryList)
    
    SendReactMessage('setDefaultPrice', Config.DefaultPrice)
    
    -- Set gender FIRST before loading rarity data
    SendReactMessage('setGender', { isFemale = (sex == "female") })
    
    -- Get rarity data from SQL via server callback (based on ped gender)
    QBCore.Functions.TriggerCallback('clothes:getUICompatibleConfig', function(rarityData)
        if rarityData then
            SendReactMessage('setBackgroundColor', rarityData)
        end
    end, sex)
    
    SendReactMessage('setDefaultOutfit', Config.DefaultOutfit)
    SendReactMessage('setScreenshot', Config.UseScreenshot)
    SendReactMessage('setScreenshotUrl', Config.ScreenshotGetUrl)
    SendReactMessage('setServerName', Config.ServerName)
    
    -- Send our clothing data
    --print("^3[DEBUG] Sending clothing data to NUI:", json.encode(clothesData))
    SendReactMessage('setClothingData', clothesData)
    
    -- Send job clothing data to NUI
    SendReactMessage('setJobClothingMode', {
        enabled = true,
        job = jobData.job,
        grade = playerGrade,
        allowedComponents = genderItems.components,
        allowedProps = genderItems.props,
        sex = sex
    })
end

-- NUI Callback để apply job outfit
RegisterNUICallback('applyJobOutfit', function(data, cb)
    if LocalPlayer.state.vxAirdropActive then
        cb('blocked')
        return
    end
    if not data then
        --print("^1[JobClothes] ERROR: Invalid outfit data received^0")
        cb('error')
        return
    end
    
    local ped = PlayerPedId()
    
    --print("^2[JobClothes] Applying job outfit:", data.name or "Unknown", "^0")
    
    -- Parse clothes JSON if it's a string
    local clothesData = data.clothes
    if type(clothesData) == "string" then
        clothesData = json.decode(clothesData)
    end
    
    -- Apply components
    if clothesData and clothesData.components then
        for componentId, compData in pairs(clothesData.components) do
            componentId = tonumber(componentId)
            SetPedComponentVariation(ped, componentId, compData.drawable, compData.texture, 0)
        end
    end
    
    -- Apply props
    if clothesData and clothesData.props then
        for propId, propData in pairs(clothesData.props) do
            propId = tonumber(propId)
            if propData.drawable == -1 then
                ClearPedProp(ped, propId)
            else
                SetPedPropIndex(ped, propId, propData.drawable, propData.texture, true)
            end
        end
    end
    
    -- Save appearance
    if Config.UseIllenium then
        local appearance = exports['illenium-appearance']:getPedAppearance(ped)
        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    end
    
    QBCore.Functions.Notify("Tenue appliquée: " .. (data.name or ""), "success")
    --print("^2[JobClothes] Outfit", data.name, "applied and saved^0")
    
    cb('ok')
end)

-- NUI Callback để đóng job clothing
RegisterNUICallback('closeJobClothing', function(data, cb)
    isJobClothingMode = false
    currentJobOutfits = {}
    
    -- Restore camera
    if restoreCamera then
        restoreCamera()
    end
    
    -- Unfreeze player
    FreezeEntityPosition(PlayerPedId(), false)
    
    SetNuiFocus(false, false)
    SendReactMessage('setVisible', false)
    --print("^3[JobClothes] Job clothing menu closed^0")
    cb('ok')
end)

RegisterNetEvent('jobclothes:applyJobOutfit')
AddEventHandler('jobclothes:applyJobOutfit', function(outfit)
    applyJobOutfit(outfit)
end)

-- Debug command để test job locker
RegisterCommand('debugjob', function()
    --print("=== DEBUG JOB INFO ===")
    local currentJob, currentGrade = GetCurrentJob()
    --print("Current Job (from GetCurrentJob):", currentJob)
    --print("Current Grade (from GetCurrentJob):", currentGrade)
    --print("PlayerJobName (global var):", PlayerJobName)
    --print("PlayerJobGrade (global var):", PlayerJobGrade)
    --print("Config.FrameWork:", Config.FrameWork)
    local allShops = GetAllJobShops()
    --print("Total job shops count:", #allShops)
    
    -- Test QBCore directly
    if Config.FrameWork == "QBOX" or Config.FrameWork == "QBCORE" then
        local PlayerData = QBCore.Functions.GetPlayerData()
        --print("QBCore PlayerData exists:", PlayerData ~= nil)
        if PlayerData then
            --print("QBCore PlayerData.job exists:", PlayerData.job ~= nil)
            if PlayerData.job then
                --print("QBCore Job name:", PlayerData.job.name)
                --print("QBCore Job grade:", PlayerData.job.grade and PlayerData.job.grade.level or "nil")
            end
        end
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    --print("Player position:", playerCoords)
    
    for i, jobData in ipairs(Config.JobOutifs) do
        --print("Job", i, ":", jobData.job, "at", jobData.pos)
        if jobData.pos then
            local dist = #(playerCoords - jobData.pos)
            --print("  Distance:", dist)
            --print("  Has Job:", PlayerHasIsJob(jobData.job))
            
            -- Check outfits structure
            if jobData.outfits then
                --print("  Outfits count:", #jobData.outfits)
                for j, outfit in ipairs(jobData.outfits) do
                    --print("    Outfit", j, "- Grade:", outfit.grade, "Label:", outfit.label)
                end
            else
                --print("  WARNING: No outfits configured!")
            end
        end
    end
end, false)

-- Debug command để set job tạm thời (chỉ cho testing)
RegisterCommand('setjobtest', function(source, args)
    if args[1] then
        PlayerJobName = args[1]
        PlayerJobGrade = tonumber(args[2]) or 0
        --print("DEBUG: Manually set job to:", PlayerJobName, "Grade:", PlayerJobGrade)
        --print("Now try going to the job locker!")
    else
        --print("Usage: /setjobtest [jobname] [grade]")
        --print("Example: /setjobtest police 0")
    end
end, false)

Citizen.CreateThread(function()
    local isTextUIShowing = false
    
    while true do
        local playerPed = PlayerPedId()
        local near, jobData = isPlayerNearJobLocker()
        
        if near and jobData then
            -- Kiểm tra config marker có tồn tại không
            if Config.DrawMarker and Config.DrawMarker.type and Config.DrawMarker.scale and Config.DrawMarker.color then
                DrawMarker(Config.DrawMarker.type, jobData.pos.x, jobData.pos.y, jobData.pos.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.DrawMarker.scale, Config.DrawMarker.scale, Config.DrawMarker.scale, Config.DrawMarker.color.r, Config.DrawMarker.color.g, Config.DrawMarker.color.b, Config.DrawMarker.color.a, false, true, 2, false, nil, nil, false)
            end
            
            -- Chỉ hiển thị text UI nếu chưa hiển thị
            if not isTextUIShowing then
                exports["pa-textui-2"]:displayTextUI("Mở tủ quần áo công việc", "E")
                isTextUIShowing = true
            end
            
            if IsControlJustReleased(0, 38) then -- E
                -- Validation jobData
                if not jobData or not jobData.job then
                    --print("^1[JobClothes] ERROR: Invalid jobData^0")
                    return
                end
                
                -- Lấy job và grade hiện tại
                local currentJob, currentGrade = GetCurrentJob()
                local playerGrade = currentGrade or 0
                
                --print("^2[JobClothes] Opening job clothing for:", jobData.job, "Grade:", playerGrade, "^0")
                
                -- Mở NUI với job outfits
                OpenJobClothingShop(jobData, playerGrade)
            end
            
            Wait(0)
        else
            -- Ẩn text UI nếu người chơi không gần marker
            if isTextUIShowing then
                exports["pa-textui-2"]:hideTextUI()
                isTextUIShowing = false
            end
            
            Wait(500)
        end
    end
end)

