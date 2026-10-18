local ox_inventory = exports.ox_inventory
local on = {}
local lastOutfitUsed = nil
local QBCore = exports['qb-core']:GetCoreObject()

local MALE_FREEMODE_MODEL = joaat('mp_m_freemode_01')
local FEMALE_FREEMODE_MODEL = joaat('mp_f_freemode_01')

local function isFreemodePed(ped)
    ped = ped or PlayerPedId()
    local model = GetEntityModel(ped)
    return model == MALE_FREEMODE_MODEL or model == FEMALE_FREEMODE_MODEL
end

local function canUseIlleniumForPed(ped)
    return Config.UseIllenium and isFreemodePed(ped)
end

local function shouldUseNativeOnlyForCustomPed(ped)
    return Config.UseIllenium and not canUseIlleniumForPed(ped)
end

local function applyComponentNative(ped, componentId, drawable, texture)
    local comp = tonumber(componentId)
    local draw = tonumber(drawable) or 0
    local tex = tonumber(texture) or 0
    if draw < 0 then draw = 0 end
    -- Check drawable exists for current ped to prevent palette error
    local maxDraw = GetNumberOfPedDrawableVariations(ped, comp)
    if maxDraw > 0 and draw >= maxDraw then
        print(string.format('[XNClothes] BLOCKED applyComponentNative - drawable %d out of range (max=%d) for component %d', draw, maxDraw, comp))
        return
    end
    local maxTex = GetNumberOfPedTextureVariations(ped, comp, draw)
    if maxTex > 0 and tex >= maxTex then tex = 0 end
    SetPedComponentVariation(ped, comp, draw, tex, 0)
end

local function applyPropNative(ped, propId, drawable, texture)
    local prop = tonumber(propId)
    local draw = tonumber(drawable) or -1
    local tex = tonumber(texture) or 0

    if draw == -1 then
        ClearPedProp(ped, prop)
    else
        local maxProp = GetNumberOfPedPropDrawableVariations(ped, prop)
        if maxProp > 0 and draw >= maxProp then
            print(string.format('[XNClothes] BLOCKED applyPropNative - drawable %d out of range (max=%d) for prop %d', draw, maxProp, prop))
            return
        end
        local maxTex = GetNumberOfPedPropTextureVariations(ped, prop, draw)
        if maxTex > 0 and tex >= maxTex then tex = 0 end
        SetPedPropIndex(ped, prop, draw, tex, true)
    end
end

local function getPedSexForClothes(ped)
    ped = ped or PlayerPedId()
    -- ALWAYS use ped model as source of truth for gender
    -- This ensures correct gender detection even when player changes ped
    return IsPedModel(ped, FEMALE_FREEMODE_MODEL) and "female" or "male"
end

function SendReactMessage(action, data)
	SendNUIMessage({
	  action = action,
	  data = data
	})
end



function getSkinParts(type)
	local parts = {
		[1] = {'mask_1', 'mask_2'},
		[4] = {'pants_1', 'pants_2'},
		[6] = {'shoes_1', 'shoes_2'},
		[8] = {'tshirt_1', 'tshirt_2'},
		[11] = {'torso_1', 'torso_2'},
		[9] = {'bproof_1', 'bproof_2'},
		[5] = {'bags_1', 'bags_2'},
		[3] = {'arms', 'arms_2'},
		[7] = {'chain_1', 'chain_2'},
		[10] = {'decals_1', 'decals_2'},
	}
	return parts[type] and parts[type][1], parts[type] and parts[type][2]
end

function getPropParts(type)
	local parts = {
		[0] = {'helmet_1', 'helmet_2'},
		[1] = {'glasses_1', 'glasses_2'},
        [2] = {'ears_1', 'ears_2'},
		[6] = {'watches_1', 'watches_2'},
        [7] = {'bracelets_1', 'bracelets_2'}
    
	}
	return parts[type] and parts[type][1], parts[type] and parts[type][2]
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
        [10] = "decal",
        [11] = "torso"
    }
    return mapping[component_id]
end

-- Chức năng xác định loại prop
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



exports('clothes', function(data)
    if LocalPlayer.state.vxAirdropActive then return end
    local ped = cache.ped

    ox_inventory:useItem(data, function(data)
        if data then
            -- Kiểm tra durability trước khi mặc quần áo
            if data.metadata and data.metadata.durability ~= nil then
                if tonumber(data.metadata.durability) == 0 then
                    QBCore.Functions.Notify("Quần áo đã hỏng và không thể sử dụng!", 'error')
                    return
                end
            end
            
            if Config.UseCustomOXInventory == false then
                local clotheConfig = Config.DefaultClothes[data.name]
                on[data.name] = not on[data.name]

                if clotheConfig then
                    if on[data.name] then
                        playAnimationAndChange(ped, data, data.metadata.type, data.metadata.drawable, data.metadata.texture, false, true)
                    else
                        local isFemale = IsPedModel(ped, `mp_f_freemode_01`)

                        RequestAnimDict(Config.Clothes[data.name].dict)
                        while not HasAnimDictLoaded(Config.Clothes[data.name].dict) do
                            Citizen.Wait(100)
                        end
                
                        TaskPlayAnim(ped, Config.Clothes[data.name].dict, Config.Clothes[data.name].anim, 8.0, -8, -1, 49, 0, 0, 0, 0)
                        Citizen.Wait(1500)

                        for _, comp in ipairs(clotheConfig.components) do
                            local defaultValue
                            if comp.default_male and comp.default_female then
                                defaultValue = isFemale and comp.default_female or comp.default_male
                            else
                                defaultValue = comp.default
                            end
                            
                            local componentData = {
                                name = data.name,
                                metadata = {
                                    type = comp.component,
                                    drawable = defaultValue,
                                    texture = 0
                                }
                            }
                            
                            playAnimationAndChange(ped, componentData, comp.component, defaultValue, 0, false, false)
                        end
                    end
                end
            else 
                -- Kiểm tra giới tính của item với giới tính của player
                if data.metadata.sex then
                    local ped = PlayerPedId()
                    local playerSex = getPedSexForClothes(ped)
                    
                    if data.metadata.sex ~= playerSex then
                        QBCore.Functions.Notify("Bạn không thể sử dụng quần áo của giới tính khác.", 'error')
                        return
                    end
                end

                for category, mapping in pairs(componentMapping) do
                    if mapping.itemname == data.name or (mapping.itemname == 'cloth_decals' and data.name == 'cloth_decal') then
                        local component = mapping.component
                        local isProp = mapping.prop
                        local expectedDrawable = data.metadata.drawable
                        local expectedTexture = data.metadata.texture
                        local expectedSlot = mapping.clothesSlotID

                        if data.slot == expectedSlot then

                            QBCore.Functions.Notify("Bạn đã có quần áo này trong khe cắm này.", 'error')
                            return

                        end
                
                        break
                    end
                end
                
                
                

                if canUseIlleniumForPed(cache.ped) then
                    local component = nil
                    for category, mapping in pairs(componentMapping) do
                        if mapping.itemname == data.name or (mapping.itemname == 'cloth_decals' and data.name == 'cloth_decal') then
                            component = mapping
                            break
                        end
                    end

                    if component then
                        if component.prop then
                            local propType = getPropType(component.component)
                            if propType and Config.Clothes[propType] then
                                local animData = Config.Clothes[propType]
                                if animData.dict then
                                    playClothingAnimation(animData.dict, animData.anim)
                                end
                            end

                            exports['illenium-appearance']:setPedProps(cache.ped, {
                                {
                                    prop_id = component.component,
                                    drawable = data.metadata.drawable,
                                    texture = data.metadata.texture
                                }
                            })

                            -- Nếu đeo khuyên tai (prop 2) chia sẻ slot 16 với decal -> gỡ decal (component 10 về 0)
                            if component.component == 2 and component.prop then
                                exports['illenium-appearance']:setPedComponents(cache.ped, {
                                    {
                                        component_id = 10,
                                        drawable = 0,
                                        texture = 0
                                    }
                                })
                            end
                        else
                            local componentType = getComponentType(component.component)
                            if componentType and Config.Clothes[componentType] then
                                local animData = Config.Clothes[componentType]
                                if animData.dict then
                                    playClothingAnimation(animData.dict, animData.anim)
                                end
                            end

                            exports['illenium-appearance']:setPedComponents(cache.ped, {
                                {
                                    component_id = component.component,
                                    drawable = data.metadata.drawable,
                                    texture = data.metadata.texture
                                }
                            })

                            -- Nếu mặc decal (component 10) chia sẻ slot 16 với khuyên tai -> gỡ khuyên tai (prop 2 về -1)
                            if component.component == 10 and not component.prop then
                                exports['illenium-appearance']:setPedProps(cache.ped, {
                                    {
                                        prop_id = 2,
                                        drawable = -1,
                                        texture = -1
                                    }
                                })
                            end
                        end
                        TriggerServerEvent('RefreshArmsAndTShirt')
                        local appearance = exports['illenium-appearance']:getPedAppearance(cache.ped)
                        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
                        --ResetPedScreen()
                    end
                else

                    local component = nil
                    for category, mapping in pairs(componentMapping) do
                        if mapping.itemname == data.name or (mapping.itemname == 'cloth_decals' and data.name == 'cloth_decal') then
                            component = mapping
                            break
                        end
                    end

                    if component then
                        local propType = getPropType(component.component)
                        if propType and Config.Clothes[propType] then
                            local animData = Config.Clothes[propType]
                            if animData.dict then
                                playClothingAnimation(animData.dict, animData.anim)
                            end
                        end
                        local componentType = getComponentType(component.component)
                        if componentType and Config.Clothes[componentType] then
                            local animData = Config.Clothes[componentType]
                            if animData.dict then
                                playClothingAnimation(animData.dict, animData.anim)
                            end
                        end

                        if shouldUseNativeOnlyForCustomPed(ped) then
                            if component.prop then
                                applyPropNative(ped, component.component, data.metadata.drawable, data.metadata.texture)
                                if component.component == 2 and component.prop then
                                    applyComponentNative(ped, 10, 0, 0)
                                end
                            else
                                applyComponentNative(ped, component.component, data.metadata.drawable, data.metadata.texture)
                                if component.component == 10 and not component.prop then
                                    applyPropNative(ped, 2, -1, 0)
                                end
                            end
                        else
                            local skinPart, skinColor = getSkinParts(data.metadata.type)
                
                            TriggerEvent('skinchanger:getData', function(components, maxVals)
                                for k, v in pairs(components) do
                                    if v.name == skinPart then
                                        TriggerEvent('skinchanger:change', skinPart, data.metadata.drawable)
                                        TriggerEvent('skinchanger:change', skinColor, data.metadata.texture)
                                        if component.component == 10 and not component.prop then
                                            TriggerEvent('skinchanger:change', 'ears_1', -1)
                                            TriggerEvent('skinchanger:change', 'ears_2', 0)
                                        elseif component.component == 2 and component.prop then
                                            TriggerEvent('skinchanger:change', 'decals_1', 0)
                                            TriggerEvent('skinchanger:change', 'decals_2', 0)
                                        end
                                        TriggerEvent('skinchanger:getSkin', function(skin)
                                            TriggerServerEvent('esx_skin:save', skin)
                                        end)
                                    end
                                end
                            end)
                        end
                    end
                end 
                --ResetPedScreen()
                TriggerServerEvent('RefreshArmsAndTShirt')
                if Config.UseCustomOXInventory then 
                    TriggerServerEvent('clothes:changeslotclothes', data.metadata, data.slot, data.name, data.label)
                    
                end
                --print("Tên quần áo đang sử dụng:", data.name)
                if data.name == 'cloth_bags' then
                    TriggerServerEvent('XNClothes:loadbalo')
                end
            end 
        end
    end)
end)


exports('accessories', function(data)
    if LocalPlayer.state.vxAirdropActive then return end
    local ped = cache.ped

    ox_inventory:useItem(data, function(data)
        if data then
            -- Kiểm tra durability trước khi mặc phụ kiện
            if data.metadata and data.metadata.durability ~= nil then
                if tonumber(data.metadata.durability) == 0 then
                    QBCore.Functions.Notify("Phụ kiện đã hỏng và không thể sử dụng!", 'error')
                    return
                end
            end
            
            local clotheConfig = Config.DefaultClothes[data.name]
            on[data.name] = not on[data.name]

            if clotheConfig then
                if on[data.name] then
                    playAnimationAndChange(ped, data, data.metadata.type, data.metadata.drawable, data.metadata.texture, true, true)
                else
                    local isFemale = IsPedModel(ped, `mp_f_freemode_01`)

                    RequestAnimDict(Config.Clothes[data.name].dict)
                    while not HasAnimDictLoaded(Config.Clothes[data.name].dict) do
                        Citizen.Wait(100)
                    end
            
                    TaskPlayAnim(ped, Config.Clothes[data.name].dict, Config.Clothes[data.name].anim, 8.0, -8, -1, 49, 0, 0, 0, 0)
                    Citizen.Wait(1500)
                    ClearPedTasks(ped)

                    for _, comp in ipairs(clotheConfig.components) do
                        if comp.prop then
                            local defaultValue
                            if comp.default_male and comp.default_female then
                                defaultValue = isFemale and comp.default_female or comp.default_male
                            else
                                defaultValue = comp.default
                            end
                            
                            local componentData = {
                                name = data.name,
                                metadata = {
                                    type = comp.component,
                                    drawable = defaultValue,
                                    texture = 0
                                }
                            }
                            playAnimationAndChange(ped, componentData, comp.component, defaultValue, 0, true, false)
                        end
                    end
                end
            end
        end
    end)
end)

function ResetPed()
    if LocalPlayer.state.vxAirdropActive then return end
    local ped = cache.ped
    if Config.UseCustomOXInventory then 
        TriggerServerEvent('clothes:DeleteClothes')
    end
    if canUseIlleniumForPed(ped) then
        local sex = getPedSexForClothes(ped)
        if sex == "female" then
            exports['illenium-appearance']:setPedComponents(cache.ped, Config.DefaultOutfitWoman.components)
            exports['illenium-appearance']:setPedProps(cache.ped, Config.DefaultOutfitWoman.props)
        else
            exports['illenium-appearance']:setPedComponents(cache.ped, Config.DefaultOutfit.components)
            exports['illenium-appearance']:setPedProps(cache.ped, Config.DefaultOutfit.props)
        end
        
        local appearance = exports['illenium-appearance']:getPedAppearance(cache.ped)
        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    elseif shouldUseNativeOnlyForCustomPed(ped) then
        for _, data1 in pairs(Config.DefaultOutfit.components) do
            applyComponentNative(ped, data1.component_id, data1.drawable, data1.texture)
        end

        for _, data1 in pairs(Config.DefaultOutfit.props) do
            applyPropNative(ped, data1.prop_id, data1.drawable, data1.texture)
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
end

RegisterNetEvent('clothes:resetPed')
AddEventHandler('clothes:resetPed', function()
    if LocalPlayer.state.vxAirdropActive then return end
    ResetPed()
    Wait(100)
    --ResetPedScreen()
end)


function updateSkinchanger(data, drawable, texture)
    if LocalPlayer.state.vxAirdropActive then return end

    local skinPart, skinColor = getSkinParts(data.metadata.type)
    local playerPed = cache.ped

    -- Chơi hoạt hình theo loại quần áo
    local componentType = getComponentType(data.metadata.type)
    if componentType and Config.Clothes[componentType] then
        local animData = Config.Clothes[componentType]
        if animData.dict then
            playClothingAnimation(animData.dict, animData.anim)
        end
    end


    if skinPart and skinColor then

        if canUseIlleniumForPed(playerPed) then
            exports['illenium-appearance']:setPedComponents(cache.ped, {
                {
                    component_id = data.metadata.type,
                    drawable = drawable,
                    texture = texture
                }
            })
            
            local appearance = exports['illenium-appearance']:getPedAppearance(playerPed)

            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            TriggerServerEvent('RefreshArmsAndTShirt')

        elseif shouldUseNativeOnlyForCustomPed(playerPed) then
            applyComponentNative(playerPed, data.metadata.type, drawable, texture)
        else

            TriggerEvent('skinchanger:getData', function(components, maxVals)
                for k, v in pairs(components) do
                    if v.name == skinPart then
                        TriggerEvent('skinchanger:change', skinPart, drawable)
                        TriggerEvent('skinchanger:change', skinColor, texture)

                        TriggerEvent('skinchanger:getSkin', function(skin)
                            TriggerServerEvent('esx_skin:save', skin)
                        end)
                    end
                end
            end)
        end 
    end
end



function playAnimationAndChange(ped, data, type, drawable, texture, prop, anim)
    if LocalPlayer.state.vxAirdropActive then return end

    if anim then
        RequestAnimDict(Config.Clothes[data.name].dict)
        while not HasAnimDictLoaded(Config.Clothes[data.name].dict) do
            Citizen.Wait(100)
        end

        TaskPlayAnim(ped, Config.Clothes[data.name].dict, Config.Clothes[data.name].anim, 8.0, -8, -1, 49, 0, 0, 0, 0)
        Citizen.Wait(1500)
    end

    if prop then
        updateSkinchangerAccessories(data, drawable, texture)
    else
        updateSkinchanger(data, drawable, texture)
    end

    ClearPedTasks(ped)

end

function updateSkinchangerAccessories(data, drawable, texture)
    if LocalPlayer.state.vxAirdropActive then return end
    local skinPart, skinColor = getPropParts(data.metadata.type)
    local playerPed = cache.ped

        -- Jouer l'animation selon le type de prop
    local propType = getPropType(data.metadata.type)
    if propType and Config.Clothes[propType] then
        local animData = Config.Clothes[propType]
        if animData.dict then
            playClothingAnimation(animData.dict, animData.anim)
        end
    end

    if skinPart and skinColor then


        if canUseIlleniumForPed(playerPed) then
            exports['illenium-appearance']:setPedProps(playerPed, {
                {
                    prop_id = data.metadata.type,
                    drawable = drawable,
                    texture = texture
                }
            })
            local appearance = exports['illenium-appearance']:getPedAppearance(playerPed)

            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            --ResetPedScreen()

        elseif shouldUseNativeOnlyForCustomPed(playerPed) then
            applyPropNative(playerPed, data.metadata.type, drawable, texture)
        else
            TriggerEvent('skinchanger:getData', function(components, maxVals)
                for k, v in pairs(components) do
                    if v.name == skinPart then
                        TriggerEvent('skinchanger:change', skinPart, drawable)
                        TriggerEvent('skinchanger:change', skinColor, texture)

                        TriggerEvent('skinchanger:getSkin', function(skin)
                            TriggerServerEvent('esx_skin:save', skin)
                        end)
                    end
                end

                --ResetPedScreen()
            end)
        end 
    end
end



exports('useClothes', function(data)
    if LocalPlayer.state.vxAirdropActive then return end
    return true
end)


function PlaySound()
    local audioId
    local Library = "HUD_FRONTEND_DEFAULT_SOUNDSET"
    local Sound = "SELECT"
    local IsLooped = false 
    if Config.EnableSound then 
        if not IsLooped then
            PlaySoundFrontend(-1, Sound, Library, true)
        else
            if not audioId then
                Citizen.CreateThread(function()
                    audioId = GetSoundId()
                    PlaySoundFrontend(audioId, Sound, Library, true)
                    Citizen.Wait(0.01)
                    StopSound(audioId)
                    ReleaseSoundId(audioId)
                    audioId = nil
                end)
            end
        end
    end 
end
    



RegisterNetEvent('clothes:getPrice')
AddEventHandler('clothes:getPrice', function()
    getAllPriceClothes()
end)

function getAllPriceClothes()
    QBCore.Functions.TriggerCallback('clothes:getAllPriceClothes', function(priceClothes)
        SendReactMessage('setPriceClothes', priceClothes)
    end)
end

local isStaff = false

-- PERF FIX: Bỏ polling 30s (400 callbacks/phút với 200 người).
-- isStaff được cập nhật ngay khi mở shop trong toggleNuiFrame.
-- Check 1 lần lúc load để có giá trị ban đầu.
QBCore.Functions.TriggerCallback('clothes:isstaff', function(result)
    isStaff = result
end)

RegisterNUICallback('handleClothingRightClick', function(data, cb)
    if not isStaff then 
        cb({})
        return 
    end

    -- Show unified dialog with both price and rarity options
    local input = lib.inputDialog('Admin - Sửa Item', {
        {
            type = 'number',
            label = 'Giá',
            description = 'Nhập giá mới cho item này (bỏ trống để không đổi)',
            required = false,
            min = 1
        },
        {
            type = 'select',
            label = 'Độ hiếm',
            description = 'Chọn độ hiếm cho item này',
            required = false,
            options = {
                {value = 'none', label = '-- Không thay đổi --'},
                {value = 'remove', label = '🗑️ Xóa độ hiếm (không có độ hiếm)'},
                {value = 'Common', label = '🟢 Common (Xanh lá)'},
                {value = 'Uncommon', label = '🔵 Uncommon (Xanh dương)'},
                {value = 'Rare', label = '🟣 Rare (Tím)'},
                {value = 'Epic', label = '🟡 Epic (Vàng)'},
                {value = 'Legendary', label = '🔴 Legendary (Đỏ)'}
            },
            default = 'none'
        }
    })
    
    if not input then
        cb({})
        return
    end
    
    local price = input[1]
    local rarityChoice = input[2]
    
    -- Update price if provided
    if price and price > 0 then
        if data.sex == "male" then
            TriggerServerEvent('clothes:setPrice', data.index, data.component, price, 0, data.prop)
        else
            TriggerServerEvent('clothes:setPrice', data.index, data.component, price, 1, data.prop)
        end
    end
    
    -- Update rarity if changed
    if rarityChoice and rarityChoice ~= 'none' then
        local gender = data.sex == "male" and "male" or "female"
        
        if rarityChoice == 'remove' then
            -- Remove rarity from database
            TriggerServerEvent('clothes:removeRarity', data.index, data.component, gender, data.prop)
        else
            -- Set rarity
            TriggerServerEvent('clothes:setRarity', data.index, data.component, rarityChoice, gender, data.prop)
        end
    end

    cb({})
end)

-- Event to refresh rarity data when admin updates
RegisterNetEvent('clothes:refreshRarity')
AddEventHandler('clothes:refreshRarity', function()
    -- Request updated rarity config from server (based on ped gender)
    local sex = getPedSexForClothes(PlayerPedId())
    QBCore.Functions.TriggerCallback('clothes:getUICompatibleConfig', function(rarityData)
        if rarityData then
            SendReactMessage('setBackgroundColor', rarityData)
        end
    end, sex)
end)

RegisterNetEvent('clothes:refreshClothes')
AddEventHandler('clothes:refreshClothes', function(clothesList)
    if LocalPlayer.state.vxAirdropActive then return end
    for _, data in pairs(clothesList) do
        if type(data) == "table" and data.component_id then  
            local componentId = data.component_id
            local drawable = tonumber(data.drawable) or 0
            local texture = tonumber(data.texture) or 0
            local propId = data.prop_id
            
            -- Validate drawable and texture
            if drawable < 0 then drawable = 0 end
            if texture < 0 then texture = 0 end

            -- BULLETPROOF: Check drawable exists for current ped to prevent palette error
            if propId == false then
                local maxDraw = GetNumberOfPedDrawableVariations(cache.ped, componentId)
                if maxDraw > 0 and drawable >= maxDraw then
                    print(string.format('[XNClothes] refreshClothes BLOCKED - drawable %d out of range for component %d (max=%d)', drawable, componentId, maxDraw))
                    goto continue_refresh
                end
                local maxTex = GetNumberOfPedTextureVariations(cache.ped, componentId, drawable)
                if maxTex > 0 and texture >= maxTex then texture = 0 end
            elseif drawable >= 0 then
                local maxProp = GetNumberOfPedPropDrawableVariations(cache.ped, componentId)
                if maxProp > 0 and drawable >= maxProp then
                    print(string.format('[XNClothes] refreshClothes BLOCKED - prop drawable %d out of range for prop %d (max=%d)', drawable, componentId, maxProp))
                    goto continue_refresh
                end
                local maxTex = GetNumberOfPedPropTextureVariations(cache.ped, componentId, drawable)
                if maxTex > 0 and texture >= maxTex then texture = 0 end
            end

            if canUseIlleniumForPed(cache.ped) then
                if propId == false then 
                    exports['illenium-appearance']:setPedComponents(cache.ped, {
                        {
                            component_id = componentId,
                            drawable = drawable,
                            texture = texture
                        }
                    })
                else
                    exports['illenium-appearance']:setPedProps(cache.ped, {
                        {
                            prop_id = componentId,
                            drawable = drawable,
                            texture = texture
                        }
                    })
                end

                local appearance = exports['illenium-appearance']:getPedAppearance(cache.ped)
                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            else
                if propId == false then
                    SetPedComponentVariation(cache.ped, componentId, drawable, texture, 0)
                else
                    if drawable == -1 then
                        ClearPedProp(cache.ped, componentId)
                    else
                        SetPedPropIndex(cache.ped, componentId, drawable, texture, true)
                    end
                end
            end
        end
        ::continue_refresh::
    end

    --ResetPedScreen()
end)

exports('bag', function(data)
    if LocalPlayer.state.vxAirdropActive then return end

    exports.ox_inventory:useItem(data, function(data)
        if data then
            local item = data.name
            local count = data.count
            local metadata = data.metadata
            local player = data.player
            local itemslot = data.slot
            local pass = false

            for _, data in pairs(Config.DataBag) do
                if data.index == metadata.drawable then
                    pass = true
                end
            end


            if pass then
                for category, mapping in pairs(componentMapping) do
                    if mapping.itemname == item then
                        if mapping.clothesSlotID == itemslot then
                            if metadata.token then
                                exports.ox_inventory:closeInventory()
                                Wait(200)
                                success = exports.ox_inventory:openInventory('stash', 'bag_' .. metadata.token)
                                if not success then
                                    TriggerServerEvent('clothes:createbag', metadata.token, metadata.drawable)
                                end
                            else 
                                local token = math.random(1, 1000000)
                                metadata.token = token
                                TriggerServerEvent('clothes:createBag', item, count, metadata, player, itemslot)
                            end
                        else 
                            QBCore.Functions.Notify("Veuillez mettre le sac sur vous", 'error')
                        end
                    end
                end
            else 
                QBCore.Functions.Notify("Ce sac n'a pas de capiciter de stockage", 'error')
            end
        end
    end)
end)

-- =====================================================
-- ADMIN BALO PITY MENU & DIALOG
-- =====================================================

RegisterNetEvent('XNClothes:client:showBaloPityMenu', function(targetId, backpacks)
    local options = {}

    for _, balo in ipairs(backpacks) do
        table.insert(options, {
            title = balo.label .. " (Ô đồ: " .. balo.slot .. ")",
            description = string.format("Dung lượng: %d slot | Seri: %s | Drawable: %d | Pity: %d", balo.maxSlots, balo.serial, balo.drawable, balo.pitynum),
            icon = 'briefcase',
            arrow = true,
            event = 'XNClothes:client:inputBaloPity',
            args = {
                targetId = targetId,
                slot = balo.slot,
                serial = balo.serial,
                drawable = balo.drawable,
                currentPity = balo.pitynum
            }
        })
    end

    lib.registerContext({
        id = 'setpity_balo_menu',
        title = 'Balo của Player ID: ' .. targetId,
        options = options
    })

    lib.showContext('setpity_balo_menu')
end)

RegisterNetEvent('XNClothes:client:inputBaloPity', function(args)
    local input = lib.inputDialog('Thay đổi Pity Balo', {
        {
            type = 'number',
            label = 'Số lượng Pity mới',
            description = string.format("Seri: %s | Drawable: %d\nNhập số lượng pitynum muốn thay đổi cho balo này.", args.serial, args.drawable),
            default = args.currentPity,
            required = true,
            min = 0
        }
    })

    if not input or not input[1] then
        -- Admin hủy hoặc đóng nhập liệu, quay lại menu danh sách balo
        TriggerServerEvent('XNClothes:server:requestBaloMenu', args.targetId)
        return
    end

    local newPity = tonumber(input[1])
    TriggerServerEvent('XNClothes:server:setBaloPity', args.targetId, args.slot, newPity)
end)
