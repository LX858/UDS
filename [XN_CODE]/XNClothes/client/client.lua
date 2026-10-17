QBCore = exports['qb-core']:GetCoreObject()
playerconnected = true 
savedOutfit = nil  -- GLOBAL: Remove 'local' so jobclothing.lua can access it

-- In kết quả getdohiem ra F8 console
RegisterNetEvent('XNClothes:printF8', function(lines)
    if type(lines) == 'table' then
        for _, line in ipairs(lines) do
            Citizen.Trace('[getdohiem] ' .. line .. '\n')
        end
    else
        Citizen.Trace('[getdohiem] ' .. tostring(lines) .. '\n')
    end
end)
tmpCamera = nil
local needReloadClothes = false -- Flag to track if clothes need to be reloaded when closing NUI
skipClothingAnimation = false -- GLOBAL: Flag to skip clothing animations when reloading from NUI

local isBagVisible = true -- Trạng thái ban đầu: true (hiển thị túi)

-- Forward declarations for job clothing mode (defined in jobclothing.lua)
isJobClothingMode = isJobClothingMode or false
currentJobData = currentJobData or {}

-- Store texture preview changes (temporary, not saved to inventory)
local texturePreviewCache = {}

local MALE_FREEMODE_MODEL = joaat('mp_m_freemode_01')
local FEMALE_FREEMODE_MODEL = joaat('mp_f_freemode_01')

local function isFreemodePed(ped)
    ped = ped or PlayerPedId()
    local model = GetEntityModel(ped)
    return model == MALE_FREEMODE_MODEL or model == FEMALE_FREEMODE_MODEL
end

local function isFemalePedForClothes(ped)
    ped = ped or PlayerPedId()
    return IsPedModel(ped, FEMALE_FREEMODE_MODEL)
end

local function getPedSexForClothes(ped)
    -- ALWAYS use ped model as source of truth for gender
    -- This ensures correct gender detection even when player changes ped
    return isFemalePedForClothes(ped) and "female" or "male"
end

-- Sync current ped gender to server (so server-side swap hooks know real ped gender)
-- Called at key moments: player load, ped change events, before opening inventory/NUI
local lastSentGender = nil
function syncPedGenderToServer(force)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local currentGender = getPedSexForClothes(ped)
    if force or currentGender ~= lastSentGender then
        lastSentGender = currentGender
        TriggerServerEvent('clothes:updatePedGender', currentGender)
    end
end

-- Debounce timer cho gender sync (tránh spam server event mỗi inventory update)
local genderSyncTimer = nil

-- PERF FIX: Debounce syncPedGenderToServer - chỉ gửi sau 500ms idle
-- (không dùng timer nếu gender đã được gửi )
AddEventHandler('ox_inventory:updateInventory', function()
    if genderSyncTimer then return end  -- Đang đợi, bỏ qua
    genderSyncTimer = Citizen.SetTimeout(500, function()
        syncPedGenderToServer()
        genderSyncTimer = nil
    end)
end)

-- Sync gender on respawn / ped change
AddEventHandler('playerSpawned', function()
    syncPedGenderToServer(true)
end)

-- Sync gender when player model changes (FiveM event)
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerSpawn' then
        syncPedGenderToServer(true)
    end
end)

local function canUseIlleniumForPed(ped)
    return Config.UseIllenium and isFreemodePed(ped)
end

local function shouldUseNativeOnlyForCustomPed(ped)
    return Config.UseIllenium and not canUseIlleniumForPed(ped)
end

local function applyComponentNative(ped, componentId, drawable, texture)
    SetPedComponentVariation(ped, tonumber(componentId), tonumber(drawable) or 0, tonumber(texture) or 0, 0)
end

local function applyPropNative(ped, propId, drawable, texture)
    local prop = tonumber(propId)
    local draw = tonumber(drawable) or -1
    local tex = tonumber(texture) or 0

    if draw == -1 then
        ClearPedProp(ped, prop)
    else
        SetPedPropIndex(ped, prop, draw, tex, true)
    end
end

-- Helper function to get rarity data using UI name
function getRarityDataByUIName(gender, uiName, rarity)
    local itemName = Config.UIToItemMapping[uiName]
    if not itemName then
        return nil
    end
    
    if Config.Dohiem[gender] and Config.Dohiem[gender][itemName] then
        return Config.Dohiem[gender][itemName][rarity]
    end
    
    return nil
end

-- Helper function to get all rarity data for a UI item
function getAllRarityDataByUIName(gender, uiName)
    local itemName = Config.UIToItemMapping[uiName]
    if not itemName then
        return nil
    end
    
    return Config.Dohiem[gender] and Config.Dohiem[gender][itemName]
end

-- Helper function to convert UI structure to item structure for web client
-- DEPRECATED: This function is no longer used. Rarity data is now queried from SQL via server callback.
-- Use QBCore.Functions.TriggerCallback('clothes:getUICompatibleConfig', callback) instead.
--[[
function getUICompatibleConfig()
    local uiConfig = {
        female = {},
        male = {}
    }
    
    for gender, genderData in pairs(Config.Dohiem) do
        uiConfig[gender] = {}
        for itemName, rarityData in pairs(genderData) do
            -- Find UI name for this item
            local uiName = nil
            for ui, item in pairs(Config.UIToItemMapping) do
                if item == itemName then
                    uiName = ui
                    break
                end
            end
            
            if uiName then
                uiConfig[gender][uiName] = rarityData
            end
        end
    end
    
    return uiConfig
end
--]]

RegisterNUICallback('TatBalo', function(data)
    ----print("Tắt túi")
    -- Chuyển đổi trạng thái bật/tắt
    isBagVisible = not isBagVisible
    -- --print(isBagVisible)
    TriggerServerEvent("gin:server:HienBalo", isBagVisible) -- Tạo sự kiện riêng cho việc hiển thị túi (nếu cần)
    -- --print("Túi đã được hiển thị.")
end)

RegisterNetEvent('gin:dong:inven')
AddEventHandler('gin:dong:inven', function()
    -- TriggerEvent('ox_inventory:updateInventory', ESX.PlayerData.inventory)
    exports.ox_inventory:closeInventory()
end)

function getSkinParts(componentId)
    local mapping = {
        [0] = {'face', 'face_1'},
        [1] = {'mask_1', 'mask_2'},
        [2] = {'hair_1', 'hair_2'},
        [3] = {'torso_1', 'torso_2'},
        [4] = {'pants_1', 'pants_2'},
        [5] = {'bags_1', 'bags_2'},
        [6] = {'shoes_1', 'shoes_2'},
        [7] = {'chain_1', 'chain_2'},
        [8] = {'tshirt_1', 'tshirt_2'},
        [9] = {'bproof_1', 'bproof_2'},
        [10] = {'decals_1', 'decals_2'},
        [11] = {'torso_1', 'torso_2'}
    }
    
    return table.unpack(mapping[componentId] or {'', ''})
end

function getPropParts(propId)
    local mapping = {
        [0] = {'helmet_1', 'helmet_2'},
        [1] = {'glasses_1', 'glasses_2'},
        [2] = {'ears_1', 'ears_2'},
        [6] = {'watches_1', 'watches_2'},
        [7] = {'bracelets_1', 'bracelets_2'},
    }
    
    return table.unpack(mapping[propId] or {'', ''})
end

-- Chức năng để xác định loại thành phần
function getComponentType(component_id)
    local mapping = {
        [1] = "mask",
        [3] = "gloves", 
        [4] = "pants",
        [5] = "bag",
        [6] = "shoes",
        [7] = "chain",
        [8] = "shirt",
        [9] = "vest",
        [11] = "torso"
    }
    return mapping[component_id]
end

-- Fonction pour déterminer le type de prop
function getPropType(prop_id)
    local mapping = {
        [0] = "hat",
        [1] = "glasses",
        [2] = "earrings",
        [6] = "watch",
        [7] = "bracelets"
    }
    return mapping[prop_id]
end

-- Có chức năng chơi hoạt hình quần áo



function getAllClothes()
    local ped = PlayerPedId()
    local clothes = {}
    
    for category, mapping in pairs(componentMapping) do
        -- Skip special categories
        if mapping.isSpecial then
            goto continue
        end
        
        if mapping.prop then
            local currentIndex = GetPedPropIndex(ped, mapping.component)

           clothes[category] = {
               max = GetNumberOfPedPropDrawableVariations(ped, mapping.component),
               current = currentIndex,
               currentTexture = GetPedPropTextureIndex(ped, mapping.component),
               maxTextures = GetNumberOfPedPropTextureVariations(ped, mapping.component, currentIndex)
           }

        else
            local currentIndex = GetPedDrawableVariation(ped, mapping.component)
            
            clothes[category] = {
                max = GetNumberOfPedDrawableVariations(ped, mapping.component),
                current = currentIndex,
                currentTexture = GetPedTextureVariation(ped, mapping.component),
                maxTextures = GetNumberOfPedTextureVariations(ped, mapping.component, currentIndex)
            }

        end
        
        ::continue::
    end
    
    -- Add current_outfit as special category showing only worn items
    clothes['current_outfit'] = getCurrentOutfitData()
    
    return clothes
end

-- Get all currently worn clothing items from inventory slots
function getCurrentOutfitData()
    local ped = PlayerPedId()
    local currentItems = {}
    
    -- Get all items from inventory
    local playerItems = exports.ox_inventory:GetPlayerItems()
    
    -- Collect items from clothing slots only
    for category, mapping in pairs(componentMapping) do
        if not mapping.isSpecial and mapping.clothesSlotID then
            -- Get item from this slot
            local item = playerItems[mapping.clothesSlotID]
            
            if item and item.metadata then
                local drawable = item.metadata.drawable or 0
                local originalTexture = item.metadata.texture or 0
                local texture = originalTexture
                
                -- Check if there's a preview texture override for this category
                local cacheKey = category .. "_" .. drawable
                if texturePreviewCache[cacheKey] then
                    texture = texturePreviewCache[cacheKey]
                end
                
                local maxTextures = 0
                
                -- Calculate max textures based on current drawable
                if mapping.prop then
                    maxTextures = GetNumberOfPedPropTextureVariations(ped, mapping.component, drawable)
                else
                    maxTextures = GetNumberOfPedTextureVariations(ped, mapping.component, drawable)
                end
                
                table.insert(currentItems, {
                    category = category,
                    drawable = drawable,
                    texture = texture,
                    originalTexture = originalTexture,
                    maxTextures = maxTextures,
                    isProp = mapping.prop,
                    component = mapping.component,
                    slotID = mapping.clothesSlotID,
                    label = item.metadata.label or item.label,
                    rarity = item.metadata.DoHiem
                })
            end
        end
    end
    
    return {
        items = currentItems,
        isSpecialCategory = true
    }
end

-- Helper function to update clothing data while preserving job filters
function updateClothingData()
    local clothes = getAllClothes()
    
    -- If in job clothing mode, preserve the allowedDrawables filter
    if isJobClothingMode and currentJobData then
        local genderItems = {
            components = currentJobData.allowedComponents or {},
            props = currentJobData.allowedProps or {}
        }
        
        -- Add allowedDrawables back to each category
        for category, mapping in pairs(componentMapping) do
            if clothes[category] then
                local componentId = mapping.component
                local isProp = mapping.prop
                
                if isProp then
                    -- Props use string keys
                    if genderItems.props[tostring(componentId)] then
                        clothes[category].allowedDrawables = genderItems.props[tostring(componentId)]
                    end
                else
                    -- Components use numeric index
                    if genderItems.components[componentId] then
                        clothes[category].allowedDrawables = genderItems.components[componentId]
                    end
                end
            end
        end
        
        --print("^3[Job Clothing DEBUG] Updated clothing data with preserved filters^0")
    end
    
    SendReactMessage('setClothingData', clothes)
end



function toggleNuiFrame(shouldShow, category, isTattoShop)
    if Config.Animation then
        PlayAnimation(Config.AnimationName, Config.AnimationName2)
    end
    getAllPriceClothes()
    SetNuiFocus(shouldShow, shouldShow)
    SendReactMessage('setVisible', shouldShow)

    if shouldShow then
        -- Set player to random routing bucket to isolate from other players
        TriggerServerEvent('XNClothes:setRoutingBucket', true)
        QBCore.Functions.TriggerCallback('clothes:isstaff', function(isStaff)
            SendReactMessage('setIsStaff', isStaff)
        end)

        SendReactMessage('SaveOutfit', isTattoShop and false or Config.SaveOutfit)
        
        local playerPed = PlayerPedId()
        local sex = getPedSexForClothes(playerPed)
        local isFemale = sex == "female"
        
        -- Gửi BlackList theo giới tính
        SendReactMessage('setBlackListClothes', Config.BlackList[sex] or {})
        
        SendReactMessage('setUrl', Config.Url)
        SendReactMessage('setExtension', Config.Extension)
        SendReactMessage('setServerLogo', Config.ServerLogo)
        SendReactMessage('setCategory', category)
        SendReactMessage('setDefaultPrice', Config.DefaultPrice)
        SendReactMessage('setTextureChangePrice', Config.TextureChangePrice)
        
        -- Set gender FIRST before loading rarity data
        SendReactMessage('setGender', { isFemale = isFemale })
        
        -- Get rarity data from SQL via server callback (based on ped gender)
        QBCore.Functions.TriggerCallback('clothes:getUICompatibleConfig', function(rarityData)
            if rarityData then
                SendReactMessage('setBackgroundColor', rarityData)
            end
        end, sex)

        local clothes = getAllClothes()
        SendReactMessage('setClothingData', clothes)
        SendReactMessage('setDefaultOutfit', Config.DefaultOutfit)
        SendReactMessage('setScreenshot', Config.UseScreenshot)
        SendReactMessage('setScreenshotUrl', Config.ScreenshotGetUrl)
        SendReactMessage('setServerName', Config.ServerName)

        -- Gửi cấu hình Custom Shop nếu đang ở tiệm Tatto
        if isTattoShop and Config.TradeShop then
            local allowedDrawables = {}
            local costText = {}
            local categories = Config.TradeShop.Category or { "gloves" }

            for _, cat in ipairs(categories) do
                allowedDrawables[cat] = {}
                costText[cat] = {}

                -- AllowedDrawables
                if Config.TradeShop.AllowedDrawables then
                    if Config.TradeShop.AllowedDrawables[cat] and Config.TradeShop.AllowedDrawables[cat][sex] then
                        allowedDrawables[cat] = Config.TradeShop.AllowedDrawables[cat][sex]
                    elseif Config.TradeShop.AllowedDrawables[sex] and Config.TradeShop.AllowedDrawables[sex][cat] then
                        allowedDrawables[cat] = Config.TradeShop.AllowedDrawables[sex][cat]
                    elseif cat == "gloves" and Config.TradeShop.AllowedDrawables[sex] and #Config.TradeShop.AllowedDrawables[sex] > 0 then
                        allowedDrawables[cat] = Config.TradeShop.AllowedDrawables[sex]
                    end
                end

                -- Items & costText
                local catItems = nil
                if Config.TradeShop.Items then
                    if Config.TradeShop.Items[cat] and Config.TradeShop.Items[cat][sex] then
                        catItems = Config.TradeShop.Items[cat][sex]
                    elseif Config.TradeShop.Items[sex] and Config.TradeShop.Items[sex][cat] then
                        catItems = Config.TradeShop.Items[sex][cat]
                    elseif cat == "gloves" and Config.TradeShop.Items[sex] then
                        catItems = Config.TradeShop.Items[sex]
                    end
                end

                if catItems then
                    for drawableId, itemData in pairs(catItems) do
                        local label = Config.TradeShopItemLabels[itemData.item] or itemData.item
                        costText[cat][tostring(drawableId)] = string.format("%d %s", itemData.count, label)
                    end
                end
            end

            SendReactMessage('setCustomShop', {
                active = true,
                categories = categories,
                allowedDrawables = allowedDrawables,
                costText = costText
            })
        else
            SendReactMessage('setCustomShop', {
                active = false
            })
        end
    else
        SendReactMessage('setCustomShop', {
            active = false
        })
    end
end


-- =====================================================
-- ADMIN: Mở NUI xem toàn bộ quần áo, bỏ qua blacklist
-- =====================================================
local ALL_CATEGORIES = {
    'shirt', 'torso', 'pants', 'shoes', 'gloves',
    'mask', 'vest', 'bag', 'hat', 'glasses',
    'earrings', 'chain', 'watch', 'bracelets'
}

RegisterNetEvent('XNClothes:adminOpenClothes')
AddEventHandler('XNClothes:adminOpenClothes', function()
    if Config.Animation then
        PlayAnimation(Config.AnimationName, Config.AnimationName2)
    end
    getAllPriceClothes()
    SetNuiFocus(true, true)
    SendReactMessage('setVisible', true)

    TriggerServerEvent('XNClothes:setRoutingBucket', true)
    SendReactMessage('setIsStaff', true)
    SendReactMessage('SaveOutfit', Config.SaveOutfit)

    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)
    local isFemale = sex == 'female'

    -- Gửi blacklist rỗng để bỏ qua toàn bộ blacklist
    SendReactMessage('setBlackListClothes', {})

    SendReactMessage('setUrl', Config.Url)
    SendReactMessage('setExtension', Config.Extension)
    SendReactMessage('setServerLogo', Config.ServerLogo)
    SendReactMessage('setCategory', ALL_CATEGORIES)
    SendReactMessage('setDefaultPrice', Config.DefaultPrice)
    SendReactMessage('setTextureChangePrice', Config.TextureChangePrice)
    SendReactMessage('setGender', { isFemale = isFemale })

    QBCore.Functions.TriggerCallback('clothes:getUICompatibleConfig', function(rarityData)
        if rarityData then
            SendReactMessage('setBackgroundColor', rarityData)
        end
    end, sex)

    getOutfits()
    savedOutfit = saveCurrentOutfit()
    local clothes = getAllClothes()
    SendReactMessage('setClothingData', clothes)
    SendReactMessage('setDefaultOutfit', Config.DefaultOutfit)
    SendReactMessage('setScreenshot', Config.UseScreenshot)
    SendReactMessage('setScreenshotUrl', Config.ScreenshotGetUrl)
    SendReactMessage('setServerName', Config.ServerName)

    createCameraForPlayer()
    FreezeEntityPosition(playerPed, true)
end)

function saveCurrentOutfit()
    local playerPed = PlayerPedId()
    local outfit = {
        components = {},
        props = {}
    }
    
    for i = 0, 11 do
        outfit.components[i] = {
            drawable = GetPedDrawableVariation(playerPed, i),
            texture = GetPedTextureVariation(playerPed, i),
            palette = GetPedPaletteVariation(playerPed, i)
        }
    end
    

    for i = 0, 7 do
        outfit.props[i] = {
            drawable = GetPedPropIndex(playerPed, i),
            texture = GetPedPropTextureIndex(playerPed, i)
        }
    end
    
    return outfit
end

function restoreOutfit(outfit)
    if LocalPlayer.state.vxAirdropActive then return end
    local playerPed = PlayerPedId()
    
    -- Apply visual changes using native functions
    for component, data in pairs(outfit.components) do
        SetPedComponentVariation(playerPed, tonumber(component), data.drawable, data.texture, data.palette)
    end
    
    for prop, data in pairs(outfit.props) do
        if data.drawable == -1 then
            ClearPedProp(playerPed, tonumber(prop))
        else
            SetPedPropIndex(playerPed, tonumber(prop), data.drawable, data.texture, true)
        end
    end
    
    -- TEMPORARILY DISABLED: Testing if Illenium auto-saves before we can restore
    -- Force save restored outfit after visual restore completes
    --[[
    Wait(300)
    if Config.UseIllenium then
        local appearance = exports['illenium-appearance']:getPedAppearance(playerPed)
        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    else
        TriggerEvent('skinchanger:getSkin', function(skin)
            TriggerServerEvent('esx_skin:save', skin)
        end)
    end
    ]]--
end


RegisterNUICallback('hideFrame', function(_, cb)
    toggleNuiFrame(false)
    
    -- Reset routing bucket back to 0
    TriggerServerEvent('XNClothes:setRoutingBucket', false)
    
    -- Clear texture preview cache when closing menu
    texturePreviewCache = {}
    
    -- Reset flags
    needReloadClothes = false
    savedOutfit = nil
    
    -- Reset job clothing mode if active
    if isJobClothingMode then
        isJobClothingMode = false
        currentJobData = {}
    end
    
    if not LocalPlayer.state.vxAirdropActive then
        -- Reload only when no temporary event uniform owns the ped.
        skipClothingAnimation = true
        local currentGender = getPedSexForClothes(PlayerPedId())
        TriggerServerEvent('clothes:reloadPlayerClothes', currentGender)
        Citizen.SetTimeout(1500, function()
            skipClothingAnimation = false
        end)
    end
    
    restoreCamera()
    FreezeEntityPosition(PlayerPedId(), false)
    Wait(100)

    if Config.Animation then
        StopAnimTask(PlayerPedId(), Config.AnimationName, Config.AnimationName2, 2.0)
        ClearPedTasks(PlayerPedId())
    end

    if tmpCamera then
        DeleteEntity(tmpCamera)
    end

    cb({})
end)

RegisterNUICallback('getClothingData', function(data, cb)
  local clothingCounts = {
    tops = GetNumberOfPedDrawableVariations(PlayerPedId(), 11),     
    pants = GetNumberOfPedDrawableVariations(PlayerPedId(), 4),     
    shoes = GetNumberOfPedDrawableVariations(PlayerPedId(), 6),     
    accessories = GetNumberOfPedDrawableVariations(PlayerPedId(), 7)
  }
  
  cb(clothingCounts)
end)

RegisterNUICallback('changeClothing', function(data, cb)
    if LocalPlayer.state.vxAirdropActive then cb({ blocked = true }) return end
    local ped = PlayerPedId()
    local category = data.category
    local index = data.index
    PlaySound()
    if componentMapping[category] then
        -- Use native functions for preview (doesn't auto-save)
        if componentMapping[category].prop then
            SetPedPropIndex(ped, componentMapping[category].component, index, 0, true)
        else
            SetPedComponentVariation(ped, componentMapping[category].component, index, 0, 0)
        end
    end

    -- Use the new function that preserves job clothing filters
    updateClothingData()
    
    cb({})
end)

RegisterNUICallback('changeClothingTexture', function(data, cb)
    if LocalPlayer.state.vxAirdropActive then cb({ blocked = true }) return end
    local ped = PlayerPedId()
    local category = data.category
    local index = data.index
    local texture = data.texture
    PlaySound()
    
    if componentMapping[category] then
        -- Use native functions for preview (doesn't auto-save)
        if componentMapping[category].prop then
            SetPedPropIndex(ped, componentMapping[category].component, index, texture, true)
        else
            SetPedComponentVariation(ped, componentMapping[category].component, index, texture, 0)
        end
        
        -- Store texture preview in cache for current_outfit display
        local cacheKey = category .. "_" .. index
        texturePreviewCache[cacheKey] = texture
    end

    -- Use the new function that preserves job clothing filters
    updateClothingData()
    
    cb({})
end)

-- Preview texture change for owned clothing items (from current_outfit tab) - no save
RegisterNUICallback('previewOwnedClothingTexture', function(data, cb)
    if LocalPlayer.state.vxAirdropActive then cb({ blocked = true }) return end
    local ped = PlayerPedId()
    local category = data.category
    local index = data.index
    local texture = data.texture
    PlaySound()
    
    if componentMapping[category] then
        -- Apply texture change on ped for visual preview only
        if componentMapping[category].prop then
            SetPedPropIndex(ped, componentMapping[category].component, index, texture, true)
        else
            SetPedComponentVariation(ped, componentMapping[category].component, index, texture, 0)
        end
        
        -- Store texture preview in cache
        local cacheKey = category .. "_" .. index
        texturePreviewCache[cacheKey] = texture
    end
    
    cb({})
end)

-- Confirm texture change for owned clothing items (charges money and saves)
RegisterNUICallback('confirmTextureChange', function(data, cb)
    local category = data.category
    local drawable = data.drawable
    local slotID = data.slotID
    local originalTexture = data.originalTexture
    local newTexture = data.newTexture
    local price = data.price
    
    PlaySound()
    
    -- Call server to update texture and charge price
    TriggerServerEvent('XNClothes:confirmTextureChange', slotID, newTexture, price)
    
    cb({})  
end)

-- Handle successful texture change from server
RegisterNetEvent('XNClothes:textureChangeSuccess')
AddEventHandler('XNClothes:textureChangeSuccess', function(slotID, newTexture)
    -- Set flag to reload clothes when closing menu
    needReloadClothes = true
    
    -- Clear texture preview cache for this item
    texturePreviewCache = {}
    
    -- Reset texture change info in UI
    SendReactMessage('clearTextureChangeInfo', true)
    
    -- Update clothing data to reflect changes
    updateClothingData()
end)

-- Forward purchase success notifications to the NUI toast system
RegisterNetEvent('XNClothes:purchaseSuccess')
AddEventHandler('XNClothes:purchaseSuccess', function(data)
    SendReactMessage('purchaseSuccess', data or {})
end)



function PlayAnimation(anim, animName)
    RequestAnimDict(anim)
    while not HasAnimDictLoaded(anim) do
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), anim, animName, 2.0, -2.0, -1, 1, 0, false, false, false)
end


function changeCamera(camera)
    if not Config.Camera[camera] then
        return
    end

    local coords, point = table.unpack(Config.Camera[camera])
    local reverseFactor = reverseCamera and -1 or 1

    if tmpCamera then
        local camCoords = GetOffsetFromEntityInWorldCoords(cache.ped, coords.x * reverseFactor, coords.y * reverseFactor, coords.z * reverseFactor)
        local camPoint = GetOffsetFromEntityInWorldCoords(cache.ped, point.x, point.y, point.z)

        SetCamCoord(tmpCamera, camCoords.x, camCoords.y, camCoords.z)
        PointCamAtCoord(tmpCamera, camPoint.x, camPoint.y, camPoint.z)
    else
        local camCoords = GetOffsetFromEntityInWorldCoords(cache.ped, coords.x * reverseFactor, coords.y * reverseFactor, coords.z * reverseFactor)
        local camPoint = GetOffsetFromEntityInWorldCoords(cache.ped, point.x, point.y, point.z)

        tmpCamera = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 49.0, false, 0)
        PointCamAtCoord(tmpCamera, camPoint.x, camPoint.y, camPoint.z)
        SetCamActiveWithInterp(tmpCamera, cameraHandle, 1000, 1, 1)
    end

    isCameraInterpolating = true
end

RegisterNUICallback('changeCamera', function(data, cb)
    changeCamera(data.camera)
    cb({})
end)

function createCameraForPlayer()
    local coords, point = vector3(0.3, 2.5, 0.2), vector3(0, 0, -0.05)
    local reverseFactor = reverseCamera and -1 or 1

    local camCoords = GetOffsetFromEntityInWorldCoords(cache.ped, coords.x * reverseFactor, coords.y * reverseFactor, coords.z * reverseFactor)
    local camPoint = GetOffsetFromEntityInWorldCoords(cache.ped, point.x, point.y, point.z)

    tmpCamera = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 49.0, false, 0)

    PointCamAtCoord(tmpCamera, camPoint.x, camPoint.y, camPoint.z)

    SetCamActiveWithInterp(tmpCamera, cameraHandle, 1000, 1, 1)

    isCameraInterpolating = true

    RenderScriptCams(true, true, 500, true, true)
end


RegisterNUICallback('resetPed', function(data, cb)
    if LocalPlayer.state.vxAirdropActive then cb({ blocked = true }) return end
    if savedOutfit then
        restoreOutfit(savedOutfit)
    end
    cb({})
end)


RegisterNUICallback('rotatePed', function(data, cb)
    if data.direction == 'left' or data.direction == 'right' then
        local rotationAmount = data.direction == 'left' and -10.0 or 10.0
        local headingplayer = GetEntityHeading(PlayerPedId())
        SetEntityHeading(PlayerPedId(), headingplayer + rotationAmount)
        cb({})
    elseif data.direction == 'up' or data.direction == 'down' then
        local rotationAmount = data.direction == 'up' and -10.0 or 0
        local coords, point = vector3(0.3, 2.5, 0.2), vector3(0, 0, -0.05)
        local reverseFactor = reverseCamera and -1 or 1

        local camCoords = GetOffsetFromEntityInWorldCoords(cache.ped, coords.x * reverseFactor, coords.y * reverseFactor, coords.z * reverseFactor)
        local camPoint = GetOffsetFromEntityInWorldCoords(cache.ped, point.x, point.y, point.z)
        SetCamFov(tmpCamera, 49.0 + rotationAmount)
        cb({})
    end
end)

RegisterNUICallback('holdup', function(data, cb)
    if holdup then
        holdup = false
        ClearPedTasks(PlayerPedId())
    else
        holdup = true
        local dict = "missminuteman_1ig_2"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end
        TaskPlayAnim(PlayerPedId(), dict, "handsup_enter", 8.0, 8.0, -1, 50, 0, false, false, false)

    end
    cb({})
end)

function restoreCamera()
    RenderScriptCams(false, true, 500, true, true)
    SetEntityVisible(PlayerPedId(), true, false) 
    if tmpCamera then
        DeleteEntity(tmpCamera)
    end
end 

RegisterNUICallback('purchaseClothes', function(data, cb)
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)

    TriggerServerEvent('clothes:purchase', data.items, sex)
    
    -- Clear texture preview cache after purchase
    texturePreviewCache = {}

    cb({success = true})
end)

RegisterNUICallback('purchaseTextureChange', function(data, cb)
    -- Purchase texture change with rarity-based pricing
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)

    TriggerServerEvent('clothes:purchaseTextureChange', data.category, data.index, data.texture, data.price, sex)

    -- Clear savedOutfit so the purchased item is kept when closing menu
    savedOutfit = nil
    
    -- Clear texture preview cache after purchase
    texturePreviewCache = {}

    cb({success = true})
end)

RegisterNUICallback('purchaseClothesoutfit', function(data, cb)
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)

    TriggerServerEvent('clothes:purchase', data.items, sex)
    
    -- Clear texture preview cache after purchase
    texturePreviewCache = {}

    -- Clear savedOutfit so the purchased items are kept when closing menu
    savedOutfit = nil

    cb({success = true})
end)

RegisterNUICallback('getRefundableTattooItems', function(data, cb)
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)
    
    QBCore.Functions.TriggerCallback('clothes:getRefundableTattooItems', function(items)
        cb(items or {})
    end, sex)
end)

RegisterNUICallback('refundTattooItem', function(data, cb)
    if data and data.slot and data.category and data.drawable then
        TriggerServerEvent('clothes:refundTattooItem', data.slot, data.category, data.drawable)
        texturePreviewCache = {}
        cb({ success = true })
    else
        cb({ success = false, error = "Dữ liệu không hợp lệ" })
    end
end)

RegisterNetEvent('XNClothes:refundSuccess')
AddEventHandler('XNClothes:refundSuccess', function(data)
    SendReactMessage('onRefundSuccess', data)
    if LocalPlayer.state.vxAirdropActive then return end
    
    if data.isWorn and data.category and componentMapping[data.category] then
        local ped = PlayerPedId()
        local mapping = componentMapping[data.category]
        if mapping.prop then
            ClearPedProp(ped, mapping.component)
        else
            local defaultIndex = (Config.DefaultOutfit and Config.DefaultOutfit[data.category]) or 0
            SetPedComponentVariation(ped, mapping.component, defaultIndex, 0, 0)
        end
    end
end)

RegisterNUICallback('saveOutfit', function(data, cb)
    local outfitName = data.name
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)

    TriggerServerEvent('clothes:saveOutfit', outfitName, sex)
    
    cb({success = true})
end)

RegisterNUICallback('loadOutfit', function(data, cb)
    if LocalPlayer.state.vxAirdropActive then cb({ blocked = true }) return end
    local outfitId = data.outfitId
    local currentPed = PlayerPedId()
    ResetPed()

    if outfitId == nil then 
        if Config.DefaultOutfit then
            if canUseIlleniumForPed(currentPed) then
                local sex = getPedSexForClothes(currentPed)
                if sex == "female" then
                    exports['illenium-appearance']:setPedComponents(currentPed, Config.DefaultOutfitWoman.components)
                    exports['illenium-appearance']:setPedProps(currentPed, Config.DefaultOutfitWoman.props)
                else
                    exports['illenium-appearance']:setPedComponents(currentPed, Config.DefaultOutfit.components)
                    exports['illenium-appearance']:setPedProps(currentPed, Config.DefaultOutfit.props)
                end

                local appearance = exports['illenium-appearance']:getPedAppearance(currentPed)
                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            elseif shouldUseNativeOnlyForCustomPed(currentPed) then
                for _, data1 in pairs(Config.DefaultOutfit.components) do
                    applyComponentNative(currentPed, data1.component_id, data1.drawable, data1.texture)
                end

                for _, data1 in pairs(Config.DefaultOutfit.props) do
                    applyPropNative(currentPed, data1.prop_id, data1.drawable, data1.texture)
                end
            else


                for _, data1 in pairs(Config.DefaultOutfit.components) do
                    local skinPart, skinColor = getSkinParts(data1.component_id)
                    if skinPart and skinPart ~= '' then
                        TriggerEvent('skinchanger:change', skinPart, data1.drawable)
                        TriggerEvent('skinchanger:change', skinColor, data1.texture)
                    end
                end

                for _, data in pairs(Config.DefaultOutfit.props) do
                    local propPart, propColor = getPropParts(data.prop_id)
                    if propPart and propPart ~= '' then
                        TriggerEvent('skinchanger:change', propPart, data.drawable)
                        TriggerEvent('skinchanger:change', propColor, data.texture)
                    end
                end


                TriggerEvent('skinchanger:getSkin', function(skin)
                    TriggerServerEvent('esx_skin:save', skin)
                end)
            end

            Wait(100)

            TriggerServerEvent('clothes:defaultoutfit')
    
            if savedOutfit then
                savedOutfit = nil
                savedOutfit = saveCurrentOutfit()
            end
            cb({success = true})
            return
        end
    end


    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)

    QBCore.Functions.TriggerCallback('clothes:getOutfitById', function(outfit)
        if outfit then
            local outfitData = json.decode(outfit)
            if canUseIlleniumForPed(currentPed) then
                exports['illenium-appearance']:setPedComponents(currentPed, outfitData.components)
                
                exports['illenium-appearance']:setPedProps(currentPed, outfitData.props)
                local appearance = exports['illenium-appearance']:getPedAppearance(currentPed)

                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            elseif shouldUseNativeOnlyForCustomPed(currentPed) then
                for componentId, data1 in pairs(outfitData.components) do
                    applyComponentNative(currentPed, componentId, data1.drawable, data1.texture)
                end

                for propId, data1 in pairs(outfitData.props) do
                    applyPropNative(currentPed, propId, data1.drawable, data1.texture)
                end
            else
                for componentId, data in pairs(outfitData.components) do
                    local skinPart, skinColor = getSkinParts(tonumber(componentId))
                    if skinPart and skinColor then
                        TriggerEvent('skinchanger:change', skinPart, data.drawable)
                        TriggerEvent('skinchanger:change', skinColor, data.texture)
                    end
                end
                for propId, data in pairs(outfitData.props) do
                    local propPart, propColor = getPropParts(tonumber(propId))
                    if propPart and propColor then
                        if data.drawable == -1 then
                            TriggerEvent('skinchanger:change', propPart, 0)
                            TriggerEvent('skinchanger:change', propColor, 0)
                        else
                            TriggerEvent('skinchanger:change', propPart, data.drawable)
                            TriggerEvent('skinchanger:change', propColor, data.texture)
                        end
                    end
                end

                TriggerEvent('skinchanger:getSkin', function(skin)
                    TriggerServerEvent('esx_skin:save', skin)
                end)
            end
        else
            QBCore.Functions.Notify(Config.Notification.outfitnotfound, 'error')
        end
    end, outfitId, sex)
    
    Wait(500)
    
    if savedOutfit then
        savedOutfit = nil
        savedOutfit = saveCurrentOutfit()
    end

    cb({})
end)

Citizen.CreateThread(function()
    if Config.TradeShop then
        table.insert(Config.Coords, {
            x = Config.TradeShop.Coords.x,
            y = Config.TradeShop.Coords.y,
            z = Config.TradeShop.Coords.z,
            blips = true,
            BlipsName = Config.TradeShop.BlipsName,
            blipsid = Config.TradeShop.BlipsId,
            blipcolor = Config.TradeShop.BlipColor,
            category = Config.TradeShop.Category,
            isTattoShop = true,
            drawtext = Config.TradeShop.DrawText
        })
    end

    local isTextUIShowing = false
    
    for _, coord in pairs(Config.Coords) do
        if coord.blips then
            local blip = AddBlipForCoord(coord.x, coord.y, coord.z)
            SetBlipSprite(blip, coord.blipsid)
            SetBlipScale(blip, Config.Blips.scale)
            SetBlipColour(blip, coord.blipcolor)
            SetBlipAsShortRange(blip, Config.Blips.shortRange)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(coord.BlipsName)
            EndTextCommandSetBlipName(blip)
        end
    end

    while true do
        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)
        local isPlayerNearMarker = false

        for _, coord in pairs(Config.Coords) do
            local distance = GetDistanceBetweenCoords(coord.x, coord.y, coord.z, pCoords, true)

            if distance < 3.0 then
                isPlayerNearMarker = true

                if Config.DrawMarker.draw then
                    DrawMarker(Config.DrawMarker.type, coord.x, coord.y, coord.z , 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.DrawMarker.scale, Config.DrawMarker.scale, Config.DrawMarker.scale, Config.DrawMarker.color.r, Config.DrawMarker.color.g, Config.DrawMarker.color.b, Config.DrawMarker.color.a, false, true, 2, false, nil, nil, false)
                end 

                -- Chỉ hiển thị text UI nếu chưa hiển thị
                if not isTextUIShowing then
                    local text = coord.drawtext or "Mở cửa hàng quần áo"
                    exports["pa-textui-2"]:displayTextUI(text, "E")
                    isTextUIShowing = true
                end

                if IsControlJustPressed(0, 38) then
                    FreezeEntityPosition(playerPed, true)
                    getOutfits()
                    savedOutfit = saveCurrentOutfit()
                    toggleNuiFrame(true, coord.category, coord.isTattoShop)
                    createCameraForPlayer()
                end
                break -- Thoát khỏi vòng lặp khi tìm thấy marker gần nhất
            end
        end

        -- Ẩn text UI nếu người chơi không gần marker nào
        if not isPlayerNearMarker and isTextUIShowing then
            exports["pa-textui-2"]:hideTextUI()
            isTextUIShowing = false
        end

        Citizen.Wait(isPlayerNearMarker and 0 or 1000)
    end
end)

function getOutfits()
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)
    QBCore.Functions.TriggerCallback('clothes:getOutfits', function(outfits)
        SendReactMessage('setOutfits', outfits)
    end, sex)
end

RegisterNUICallback('deleteOutfit', function(data, cb)
    TriggerServerEvent('clothes:deleteOutfit', data.outfitId)
    cb({})
end)

RegisterNetEvent('clothes:getOutfits')
AddEventHandler('clothes:getOutfits', function(outfits)
    getOutfits()
end)

RegisterNUICallback('copyOutfit', function(data, cb)
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)
    TriggerServerEvent('clothes:copyOutfit', data.outfitId, sex)
    cb({})
end)

RegisterNetEvent('clothes:uploadScreenshot')
AddEventHandler('clothes:uploadScreenshot', function(outfitId)
    local playerPed = PlayerPedId()
    local serverName = Config.ServerName
    local screenshotUrl = Config.ScreenshotUrl
    if Config.UseScreenshot then 
        exports['screenshot-basic']:requestScreenshotUpload(screenshotUrl .. '/' .. serverName .. '/' .. outfitId, 'files[]', function(data)
            local resp = json.decode(data)
        end)
    end 
end)


RegisterNUICallback('requestOutfitScreenshot', function(data, cb)
    TriggerEvent('clothes:uploadScreenshot', data.outfitId)
    cb({})
end)

RegisterNUICallback('exportOutfit', function(data, cb)
    local playerPed = PlayerPedId()
    local sex = getPedSexForClothes(playerPed)
    
    if not data.outfitId then
        QBCore.Functions.Notify('ID de tenue invalide', 'error')
        cb({ success = false })
        return
    end
    
    TriggerServerEvent('clothes:exportOutfit', data.outfitId, sex)
    cb({ success = true })
end)

-- REMOVED: Spam loop that was calling server events every 4 seconds
-- This was causing high server resmon usage
-- sex:loadPlayer and clothes:initMonitoring are now called ONCE in QBCore:Client:OnPlayerLoaded

function ShowHelpNotification(msg, thisFrame, beep, duration)
    AddTextEntry("esxHelpNotification", msg)
    if thisFrame then
        DisplayHelpTextThisFrame("esxHelpNotification", false)
    else
        BeginTextCommandDisplayHelp("esxHelpNotification")
        EndTextCommandDisplayHelp(0, false, beep == nil or beep, duration or -1)
    end
end

RegisterCommand('debuginv', function()
    -- PERF FIX: Dùng Citizen.Trace thay print (không spam console production)
    Citizen.Trace('[XNClothes] debuginv: ' .. json.encode(exports.ox_inventory:GetPlayerItems()) .. '\n')
end, false)

RegisterNetEvent('animation:clothes')
AddEventHandler('animation:clothes', function()
    playClothingAnimation("missmic4", "michael_tux_fidget")
end)

-- Track if appearance has been loaded by illenium-appearance
local appearanceLoadedByIllenium = false
local clothesInitialized = false

-- Function to wait for illenium-appearance to finish loading
local function WaitForAppearanceLoaded(timeout)
    timeout = timeout or 10000 -- Default 10 seconds timeout
    local startTime = GetGameTimer()

    if not canUseIlleniumForPed(PlayerPedId()) then
        return true
    end
    
    while not appearanceLoadedByIllenium and (GetGameTimer() - startTime) < timeout do
        Wait(100)
        
        -- Check if appearance exists using illenium-appearance export
        if canUseIlleniumForPed(PlayerPedId()) then
            local success, appearance = pcall(function()
                return exports['illenium-appearance']:getPedAppearance(PlayerPedId())
            end)
            
            -- If we got a valid appearance with components, consider it loaded
            if success and appearance and appearance.components and #appearance.components > 0 then
                appearanceLoadedByIllenium = true
                break
            end
        end
    end
    
    return appearanceLoadedByIllenium
end

-- Function to preserve skin data (face, hair, etc.) before modifying clothes
local function GetPreservedSkinData()
    local playerPed = PlayerPedId()
    local preservedData = {}
    
    if canUseIlleniumForPed(playerPed) then
        local success, appearance = pcall(function()
            return exports['illenium-appearance']:getPedAppearance(playerPed)
        end)
        
        if success and appearance then
            preservedData = {
                headBlend = appearance.headBlend,
                headOverlays = appearance.headOverlays,
                faceFeatures = appearance.faceFeatures,
                hair = appearance.hair,
                eyeColor = appearance.eyeColor,
                model = appearance.model,
                tattoos = appearance.tattoos,
            }
        end
    end
    
    return preservedData
end

-- Function to initialize player clothes (reused for both events)
local function InitializePlayerClothes(forceWait)
    while LocalPlayer.state.vxAirdropActive do Wait(1000) end
    -- Prevent double initialization
    if clothesInitialized and not forceWait then 
        return 
    end
    
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return end
    
    local sex = getPedSexForClothes(playerPed)
    local canUseIllenium = canUseIlleniumForPed(playerPed)
    
    -- Step 1: Wait for illenium-appearance to load the character's appearance first
    -- This ensures hair, face, etc. are loaded before we touch clothes
    if canUseIllenium then
        local appeared = WaitForAppearanceLoaded(8000)
        if not appeared then
            -- Warning: silent fallback sau timeout, không cần log
        end
        
        -- Extra wait to ensure appearance is fully applied
        Wait(1000)
    else
        Wait(2000)
    end

    while LocalPlayer.state.vxAirdropActive do Wait(1000) end
    
    -- Step 2: Preserve current skin data (face, hair, etc.) before modifying anything
    local preservedSkin = GetPreservedSkinData()
    
    -- Step 3: Initialize server-side tracking
    TriggerServerEvent('sex:loadPlayer', sex)
    TriggerServerEvent('clothes:initMonitoring')
    Wait(500)
    
    -- Step 4: Load backpack/bag data
    TriggerServerEvent('XNClothes:loadbalo')
    Wait(500)
    
    -- Step 5: Skip clothing animation during reload to prevent visual glitches
    skipClothingAnimation = true
    
    -- Step 6: Reload clothes from inventory slots
    -- This will only change clothing components (1, 3, 4, 5, 6, 7, 8, 9, 11) and props (0, 1, 2, 6, 7)
    -- It will NOT touch skin data like face (component 0), hair (component 2), or headBlend
    TriggerServerEvent('clothes:reloadPlayerClothes', sex)
    
    -- Wait for clothes to finish loading
    Wait(1500)
    
    -- Step 7: Restore any preserved skin data if needed (safety check)
    if canUseIllenium and preservedSkin and preservedSkin.hair then
        local currentAppearance = exports['illenium-appearance']:getPedAppearance(playerPed)
        
        -- Check if hair was accidentally reset
        if currentAppearance and currentAppearance.hair then
            if preservedSkin.hair.style ~= currentAppearance.hair.style then
                print('[XNClothes] Warning: Hair was changed during clothes reload, restoring...')
                exports['illenium-appearance']:setPlayerAppearance({
                    hair = preservedSkin.hair,
                    headBlend = preservedSkin.headBlend,
                    headOverlays = preservedSkin.headOverlays,
                    faceFeatures = preservedSkin.faceFeatures,
                    eyeColor = preservedSkin.eyeColor,
                })
            end
        end
    end
    
    skipClothingAnimation = false
    clothesInitialized = true
end

-- Listen for illenium-appearance loaded event (if it exists)
RegisterNetEvent('illenium-appearance:client:loadClothing', function()
    appearanceLoadedByIllenium = true
end)

-- Alternative event name
RegisterNetEvent('qb-clothing:client:loadPlayerClothing', function()
    appearanceLoadedByIllenium = true
end)

-- Another possible event
RegisterNetEvent('illenium-appearance:client:playerLoaded', function()
    appearanceLoadedByIllenium = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Reset flags for new session
    appearanceLoadedByIllenium = false
    clothesInitialized = false
    
    -- Wait a bit for initial game loading
    Wait(3000)
    
    -- Initialize clothes after appearance is loaded
    InitializePlayerClothes()
end)

-- Handle resource restart when player is already loaded
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Reset flags
    clothesInitialized = false
    
    -- Wait for player to be fully loaded
    Wait(4000)
    
    -- Check if player is already logged in (resource restart scenario)
    local playerPed = PlayerPedId()
    if playerPed and playerPed ~= 0 then
        local playerData = QBCore.Functions.GetPlayerData()
        if playerData and playerData.citizenid then
            -- For resource restart, appearance should already be loaded
            appearanceLoadedByIllenium = true
            InitializePlayerClothes(true) -- Force wait
        end
    end
end)
