-- Protected skin components that should NEVER be modified by the clothing system
-- These are managed by illenium-appearance for character creation/customization
local protectedSkinComponents = {
    [0] = true,   -- Face shape
    [2] = true,   -- Hair style
    [10] = true,  -- Decals/tattoos
}

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

RegisterNetEvent('setPedComponent', function(components)
    if LocalPlayer.state.vxAirdropActive then return end
    if components.component_id == 53 then 
        return 
    end
    
    -- SAFETY CHECK: Never modify protected skin components!
    if protectedSkinComponents[components.component_id] then
        print('[XNClothes] WARNING: Blocked attempt to modify protected skin component:', components.component_id)
        return
    end
    
    -- GENDER VALIDATION: If sex field provided, check it matches current ped
    if components.sex then
        local playerPed = cache.ped or PlayerPedId()
        local pedGender = IsPedModel(playerPed, FEMALE_FREEMODE_MODEL) and "female" or "male"
        if components.sex ~= pedGender then
            print(string.format('[XNClothes] BLOCKED setPedComponent - Gender mismatch: ped=%s, item=%s, component=%d, drawable=%s',
                pedGender, tostring(components.sex), components.component_id, tostring(components.drawable)))
            return
        end
    end
    
    -- VALIDATE: Ensure drawable and texture are valid numbers >= 0
    local drawable = tonumber(components.drawable) or 0
    local texture = tonumber(components.texture) or 0
    
    if drawable < 0 then
        print('[XNClothes] WARNING: Invalid drawable ' .. drawable .. ' for component ' .. components.component_id .. ', setting to 0')
        drawable = 0
    end
    
    if texture < 0 then
        texture = 0
    end
    
    -- BULLETPROOF: Check drawable exists for current ped model (prevents palette error & wrong-gender items)
    local pedForCheck = cache.ped or PlayerPedId()
    local maxDrawable = GetNumberOfPedDrawableVariations(pedForCheck, components.component_id)
    if maxDrawable > 0 and drawable >= maxDrawable then
        print(string.format('[XNClothes] BLOCKED setPedComponent - drawable %d out of range (max=%d) for component %d on current ped',
            drawable, maxDrawable, components.component_id))
        return
    end
    -- Also validate texture range for this drawable
    local maxTexture = GetNumberOfPedTextureVariations(pedForCheck, components.component_id, drawable)
    if maxTexture > 0 and texture >= maxTexture then
        print(string.format('[XNClothes] WARNING: texture %d out of range (max=%d), resetting to 0', texture, maxTexture))
        texture = 0
    end
    
    -- Update components with validated values
    components.drawable = drawable
    components.texture = texture
    
    local skinPart, skinColor = getSkinParts(components.component_id)
    local playerPed = cache.ped

    -- Xác định giới tính của người chơi
    local isFemale = IsPedModel(playerPed, `mp_f_freemode_01`)
    local sex = isFemale and "female" or "male"

    -- Chơi hoạt hình theo loại quần áo (skip if reloading from NUI)
    if not skipClothingAnimation then
        local componentType = getComponentType(components.component_id)
        if componentType and Config.Clothes[componentType] then
            local animData = Config.Clothes[componentType]
            if animData.dict then
                playClothingAnimation(animData.dict, animData.anim)
            end
        end
    end

    if canUseIlleniumForPed(playerPed) then
        if components.component_id == 11 then
            if components.drawable == 15 then
                TorsoDefault()
            else
                exports["illenium-appearance"]:setPedComponent(PlayerPedId(), components)
                TriggerServerEvent('RefreshArmsAndTShirt')
            end
        else 
            exports["illenium-appearance"]:setPedComponent(PlayerPedId(), components)
        end
    
        -- Save appearance - but only if skipClothingAnimation is false (not during bulk reload)
        -- This prevents saving incomplete appearance during spawn
        if not skipClothingAnimation then
            local appearance = exports["illenium-appearance"]:getPedAppearance(PlayerPedId())
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
    elseif shouldUseNativeOnlyForCustomPed(playerPed) then
        if components.component_id == 11 and components.drawable == 15 then
            TorsoDefault()
        else
            SetPedComponentVariation(playerPed, components.component_id, components.drawable, components.texture, 0)
        end
    else
        QBCore.Functions.TriggerCallback('esx_skin:getPlayerSkin', function(skin)
            if components.component_id == 11 and components.drawable == 15 then
                local defaultTorso = Config.DefaultClothes.torso.components
                for _, comp in ipairs(defaultTorso) do
                    skin[skinPart] = comp.default_male
                    TriggerEvent('skinchanger:loadClothes', skin)
                end
            else
                skin[skinPart] = components.drawable
                skin[skinColor] = components.texture
                TriggerEvent('skinchanger:loadClothes', skin)
            end
            
            TriggerServerEvent('esx_skin:save', skin)
        end)
    end

    ----ResetPedScreen()    
end)

RegisterNetEvent('setPedProp', function(props) 
    if LocalPlayer.state.vxAirdropActive then return end
    -- Chơi hoạt hình theo loại prop (skip if reloading from NUI)
    if not skipClothingAnimation then
        local propType = getPropType(props.prop_id)
        if propType and Config.Clothes[propType] then
            local animData = Config.Clothes[propType]
            if animData.dict then
                playClothingAnimation(animData.dict, animData.anim)
            end
        end
    end
    
    -- GENDER VALIDATION: If sex field provided, check it matches current ped
    if props.sex then
        local pedNow = cache.ped or PlayerPedId()
        local pedGender = IsPedModel(pedNow, FEMALE_FREEMODE_MODEL) and "female" or "male"
        if props.sex ~= pedGender then
            print(string.format('[XNClothes] BLOCKED setPedProp - Gender mismatch: ped=%s, item=%s, prop=%d',
                pedGender, tostring(props.sex), props.prop_id))
            return
        end
    end
    
    -- VALIDATE: Ensure drawable and texture are valid
    local drawable = tonumber(props.drawable) or -1
    local texture = tonumber(props.texture) or 0
    
    if texture < 0 then
        texture = 0
    end
    
    -- BULLETPROOF: Check prop drawable exists for current ped (prevents palette error & wrong-gender props)
    if drawable >= 0 then
        local pedForCheck = cache.ped or PlayerPedId()
        local maxProp = GetNumberOfPedPropDrawableVariations(pedForCheck, props.prop_id)
        if maxProp > 0 and drawable >= maxProp then
            print(string.format('[XNClothes] BLOCKED setPedProp - drawable %d out of range (max=%d) for prop %d on current ped',
                drawable, maxProp, props.prop_id))
            return
        end
        local maxPropTex = GetNumberOfPedPropTextureVariations(pedForCheck, props.prop_id, drawable)
        if maxPropTex > 0 and texture >= maxPropTex then
            texture = 0
        end
    end
    
    -- Update props with validated values
    props.drawable = drawable
    props.texture = texture
    
    local playerPed = PlayerPedId()

    if canUseIlleniumForPed(playerPed) then
        exports["illenium-appearance"]:setPedProp(PlayerPedId(), props)
    elseif shouldUseNativeOnlyForCustomPed(playerPed) then
        if drawable == -1 then
            ClearPedProp(playerPed, props.prop_id)
        else
            SetPedPropIndex(playerPed, props.prop_id, drawable, texture, true)
        end
    else
        local propName, propColor = getPropParts(props.prop_id)
        QBCore.Functions.TriggerCallback('esx_skin:getPlayerSkin', function(skin)
            skin[propName] = props.drawable
            skin[propColor] = props.texture
            TriggerEvent('skinchanger:loadClothes', skin)
            TriggerServerEvent('esx_skin:save', skin)
        end)
    end

    ----ResetPedScreen()
   
end)

function TorsoDefault()
    local ped = PlayerPedId()
    local isFemale = IsPedModel(ped, `mp_f_freemode_01`)
    local sex = isFemale and "default_female" or "default_male"

    if canUseIlleniumForPed(ped) then
        for _, comp in ipairs(Config.DefaultClothes.torso.components) do
            exports["illenium-appearance"]:setPedComponent(ped, {
                component_id = comp.component,
                drawable = comp[sex],
                texture = 0
            })
        end
    elseif shouldUseNativeOnlyForCustomPed(ped) then
        for _, comp in ipairs(Config.DefaultClothes.torso.components) do
            SetPedComponentVariation(ped, comp.component, comp[sex], 0, 0)
        end
    else 
        for _, comp in ipairs(Config.DefaultClothes.torso.components) do
            TriggerEvent('skinchanger:change', "torso_1", comp.default_male)
        end
    end
end

function playClothingAnimation(dict, anim)
    Citizen.CreateThread(function()
        lib.requestAnimDict(dict)
        TaskPlayAnim(PlayerPedId(), dict, anim, 5.0, 5.0, -1, 48)
        Wait(2000)
        ClearPedTasks(PlayerPedId())
        RemoveAnimDict(dict)
    end)
end

 
local startPedScreen, clonedPed = false, nil

local playerPed = cache.ped
lib.onCache('ped', function(ped)
	playerPed = ped
end)

local function createPed(model, locationx, locationy, locationz)
    lib.requestModel(model, 1)
    return CreatePed(26, model, locationx, locationy, locationz, 0, false, false)
end

function PedScreenDelete()
    startPedScreen = false 
    
    if clonedPed and DoesEntityExist(clonedPed) then
        SetEntityAsMissionEntity(clonedPed, true, true)
        DeleteEntity(clonedPed)

        local timeout = 100
        while DoesEntityExist(clonedPed) and timeout > 0 do
            Wait(10)
            timeout = timeout - 1
        end
    end

    DisableIdleCamera(false)


    clonedPed = nil
end


function RenderCam()
    local totalTime = 1000 
    local elapsed = 0
    local startingPitch = GetGameplayCamRelativePitch() 
    local targetPitch = 0.0
    local rate = 1.0
    local pitchThreshold = 30.00  
    
    if math.abs(startingPitch + 7.0) < pitchThreshold then
        return
    end

    if LocalPlayer.state.invOpen then 
        if math.abs(startingPitch - targetPitch) > 0.01 then
            CreateThread(function()
                while elapsed < totalTime and startPedScreen do
                    Wait(3)
                    elapsed = elapsed + 10 
                    local progress = elapsed / totalTime
                    local currentPitch = (1.0 - progress) * startingPitch + progress * targetPitch
                    SetGameplayCamRelativePitch(currentPitch, rate)
                end
            end)
        end
    end
end

RegisterNetEvent('clothes:animPed')
AddEventHandler('clothes:animPed', function()
    local name = "michael_tux_fidget"
    local dict = "missmic4"
    
    lib.requestAnimDict(dict)
    TaskPlayAnim(clonedPed, dict, name, 5.0, 5.0, -1, 1)
    TaskPlayAnim(PlayerPedId(), dict, name, 5.0, 5.0, -1, 48)
    Wait(3000)
    ClearPedTasks(clonedPed)
    ClearPedTasks(PlayerPedId())
end)

function PedScreenCreate(animation, control, type, data)
    if not control then 
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if GetEntitySpeed(vehicle) * 3.5 > 80 then 
            return
        else 
            SetEntityNoCollisionEntity(clonedPed, vehicle, false)
        end 
    end

    SetGameplayCamRelativePitch(1.0, 1.0)
    --PedScreenDelete()
    RenderCam()

    local screenX = GetDisabledControlNormal(0, 239)
    local screenY = GetDisabledControlNormal(0, 240)
    clonedPed = ClonePed(PlayerPedId())
    if animation.dict and animation.anim then
        lib.requestAnimDict(animation.dict)
    
        TaskPlayAnimAdvanced(
            clonedPed,
            animation.dict,
            animation.anim,
            GetEntityCoords(clonedPed).x,
            GetEntityCoords(clonedPed).y,
            GetEntityCoords(clonedPed).z,
            0.0, 0.0, GetEntityHeading(clonedPed),
            8.0,
            8.0, 
            -1,    
            1,    
            0.0,    
            0, 0    
        )
    end
    
    SetEntityCompletelyDisableCollision(clonedPed, false, true)
    SetEntityInvincible(clonedPed, true)
    NetworkSetEntityInvisibleToNetwork(clonedPed, false)
    SetBlockingOfNonTemporaryEvents(clonedPed, true)
    DisableIdleCamera(true)



    startPedScreen = true 
    CreateThread(function()
        local positionBuffer = {}
        local bufferSize, scaleWidth, upTempOffset, depth
        local screenCoordX, screenCoordY
        local slotsClothes = exports['ox_inventory']:getslotsclothes()

        if type ~= "animation" then
            depth = Config.PedDepth
            bufferSize = 1 
            scaleWidth = 0.50
            upTempOffset = -0.55
            if slotsClothes == 'middle' then
                screenCoordX, screenCoordY = 0.5, 0.450 
            elseif slotsClothes == 'left' then
                screenCoordX, screenCoordY = 0.2, 0.450 
            elseif slotsClothes == 'right' then
                screenCoordX, screenCoordY = 0.8, 0.450 
            end
        end

        while startPedScreen do 
            local world, normal
            if type == "animation" then 
                depth = data.depth
                bufferSize = data.bufferSize
                scaleWidth = data.scaleWidth
                upTempOffset = data.upTempOffset
                world, normal = GetWorldCoordFromScreenCoord(0.7003, 0.2587)
            else
                world, normal = GetWorldCoordFromScreenCoord(screenCoordX, screenCoordY)
            end
            local target = world + normal * depth
            local camRot = GetGameplayCamRot(2)
            local rotZ = camRot.z + 180.0

            SetEntityCoordsNoOffset(clonedPed, target.x, target.y, target.z, true, true, true)
            SetEntityRotation(clonedPed, 0.0, 0.0, rotZ, 2, true)
            local forward, right, up = GetEntityMatrix(clonedPed)
            SetEntityMatrix(clonedPed, forward, right * scaleWidth, up + vector3(0, 0, upTempOffset), target)
            if control then DisableAllControlActions(0) end
            
            Wait(0) 
        end
    end)
end

function ResetPedScreen()
    -- local wasInventoryOpen = LocalPlayer.state.invOpen
    -- PedScreenDelete()
    -- if wasInventoryOpen then
    --     if LocalPlayer.state.invOpen then
    --         PedScreenCreate({
    --             dict = "anim@amb@nightclub@peds@", 
    --             anim = "rcmme_amanda1_stand_loop_cop"
    --         })
    --     end
    -- end
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



RegisterNetEvent('refreshaandtshirt')
AddEventHandler('refreshaandtshirt', function(armsData, tShirtData)
    local playerPed = PlayerPedId()
    local playerGender = IsPedModel(playerPed, FEMALE_FREEMODE_MODEL) and "female" or "male"
    
    -- Validate gender for arms
    if armsData and armsData.sex and armsData.sex ~= playerGender then
        print('[XNClothes] Gender mismatch for arms - Player: ' .. playerGender .. ', Item: ' .. armsData.sex)
        armsData = nil  -- Skip this item
    end
    
    -- Validate gender for tshirt
    if tShirtData and tShirtData.sex and tShirtData.sex ~= playerGender then
        print('[XNClothes] Gender mismatch for tshirt - Player: ' .. playerGender .. ', Item: ' .. tShirtData.sex)
        tShirtData = nil  -- Skip this item
    end
    
    if Config.UseIllenium then
        if armsData then
            exports["illenium-appearance"]:setPedComponent(PlayerPedId(), {
                component_id = armsData.component_id,
                drawable = armsData.drawable,
                texture = armsData.texture
            })
        end

        if tShirtData then
            exports["illenium-appearance"]:setPedComponent(PlayerPedId(), {
                component_id = tShirtData.component_id,
                drawable = tShirtData.drawable,
                texture = tShirtData.texture
            })
        end
    else
        QBCore.Functions.TriggerCallback('esx_skin:getPlayerSkin', function(skin)
            if armsData then
                TriggerEvent('skinchanger:change', "arms", armsData.drawable)
            end
            
            if tShirtData then
                TriggerEvent('skinchanger:change', "torso_1", tShirtData.drawable)
                TriggerEvent('skinchanger:change', "torso_2", tShirtData.texture)
            end
            
            TriggerServerEvent('esx_skin:save', skin)
        end)
    end

    ----ResetPedScreen()
end)


AddEventHandler('onResourceStop', function(resourceName)
    --PedScreenDelete()
end)

exports('ResetPedScreen', ResetPedScreen)
exports('PedScreenDelete', PedScreenDelete)
exports('PedScreenCreate', PedScreenCreate)
