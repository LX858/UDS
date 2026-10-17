---@param coords vector
---@param sprite integer
---@param display number
---@param scale number
---@param color integer
---@param label string
---@return integer
createBlip = function(coords, sprite, display, scale, color, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, display)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

---@param coords vector
---@param radius number
---@param options table
---@param distance number
---@param name string
---@return unknown
createSphereZoneTarget = function(coords, radius, options, distance, name)
    if Config.target == 'ox_target' then
        return exports.ox_target:addSphereZone({ debug = Config.debug, coords = coords, radius = radius, options = options })
    elseif Config.target == 'interact' then
        return exports.interact:AddInteraction({ coords = vec3(coords.x, coords.y, coords.z), distance = 1.0, interactDst = 1.0, id = name, name = name, options = options })
    else
        -- Here we use Box Zone cause qb-target Sphere Zone does not exists and the Circle Zone is the big shit ever made
        return exports[Config.target]:AddBoxZone(name, coords, radius, radius, { debugPoly = Config.debug, name = name, minZ = coords.z-radius, maxZ = coords.z+radius }, { options = options, distance = distance })
    end
end

---@param model string
---@param options table
---@param distance number
---@return unknown
createAddModelTarget = function(model, options, distance)
    if Config.target == 'ox_target' then
        return exports.ox_target:addModel(model, options)
    elseif Config.target == 'interact' then
        return exports.interact:AddModelInteraction({ model = model, distance = distance, options = options })
    else
        return exports[Config.target]:AddTargetModel(model, { options = options, distance = distance })
    end
end

---@param options table
---@param distance number
---@return unknown
createGlobalVehicleTarget = function(options, distance)
    if Config.target == 'ox_target' then
        return exports.ox_target:addGlobalVehicle(options)
    elseif Config.target == 'interact' then
        return exports.interact:AddGlobalVehicleInteraction({ distance = distance, options = options })
    else
        return exports[Config.target]:AddGlobalVehicle({ options = options, distance = options })
    end
end

---@param entity integer
---@param options table
---@param distance number
---@param name string
---@return unknown
createEntityTarget = function(entity, options, distance, name)
    if Config.target == 'ox_target' then
        return exports.ox_target:addLocalEntity(entity, options)
    elseif Config.target == 'interact' then
        return exports.interact:AddLocalEntityInteraction({ entity = entity, name = name, id = name, distance = 1.0, interactDst = 1.0, options = options })
    else
        return exports[Config.target]:AddTargetEntity(entity, { name = name, options = options, distance = distance })
    end
end

---@param id string | integer
---@param label string
---@param slots integer
---@param weight integer
openStash = function(id, label, slots, weight)
    if Config.inventory == 'ox_inventory' then
        lib.callback('mt_workshops:server:registerStash', false, function()
            exports.ox_inventory:openInventory('stash', id)
        end, id, label, slots, (weight*1000))
    elseif Config.inventory == 'qb-inventory-old' then
        TriggerEvent("inventory:client:SetCurrentStash", id)
        TriggerServerEvent("inventory:server:OpenInventory", "stash", id, { maxweight = (weight*1000), slots = slots })
    else
        lib.callback.await('mt_workshops:server:openStash', false, id, { maxweight = (weight*1000), slots = slots })
    end
end

---@param id string | integer
---@param label string
---@param passedItems table
openShop = function(id, label, passedItems)
    if Config.inventory == 'ox_inventory' then
        exports.ox_inventory:openInventory('shop', { type = id })
    elseif Config.inventory == 'qb-inventory-old' then
        local items = {}
        for k, v in pairs(passedItems) do
            items[#items+1] = { name = v.name, price = tonumber(v.price), amount = tonumber(v.count), info = {}, slot = k }
        end
        local Item = { label = label, slots = #items, items = items }
        TriggerServerEvent("inventory:server:OpenInventory", "shop", id, Item)
    else
        lib.callback.await('mt_workshops:server:openShop', false, id, label)
    end
end

---@param item string
---@return table
getItemData = function(item)
   if (Config.framework == 'qb' or Config.framework == 'qbx') and Config.inventory ~= 'ox_inventory' then
        return Config.core.Shared.Items[item]
   else
        return exports.ox_inventory:Items(item)
   end
end

---@param id string | integer
---@param label string
---@param items table
openCraft = function(id, label, items)
    if Config.inventory == 'ox_inventory' and Config.useOxInventoryCraft then
        lib.callback('mt_workshops:server:registerCraft', false, function()
            exports.ox_inventory:openInventory('crafting', { id = id })
        end, id, items, label)
    else
        local newItems = {}
        for k, v in pairs(items) do
            local itemData = getItemData(v.name)
            newItems[k] = { name = v.name, count = v.count, label = itemData and itemData.label or v.name, duration = v.duration, ingredients = {} }
            for ik, iv in pairs(v.ingredients) do
                local ingredientData = getItemData(ik)
                table.insert(newItems[k].ingredients, { name = ik, count = iv, label = ingredientData and ingredientData.label or ik })
            end
        end
        SendNUI('craftingMenu', { id = id, label = label, items = newItems, oldItems = items, inventoryDirectory = Config.inventoryDirectory })
        ShowNUI('setVisibleCraftingMenu', true)
    end
end

managementMenu = function()
    if Config.framework == 'qb' then
        TriggerEvent('qb-bossmenu:client:OpenMenu')
    elseif Config.framework == 'qbx' then
        exports.qbx_management:OpenBossMenu('job')
    elseif Config.framework == 'esx' then
        TriggerEvent('esx_society:openBossMenu', getPlayerJob(), function() end, { wash = false })
    end
end

getPlayerJob = function()
    if Config.framework == 'qb' then
        local PlayerData = Config.core.Functions.GetPlayerData()
        if PlayerData and PlayerData.job then
            return PlayerData.job.name
        end
        return nil
    elseif Config.framework == 'qbx' then
        if QBX and QBX.PlayerData and QBX.PlayerData.job then
            return QBX.PlayerData.job.name
        end
        return nil
    elseif Config.framework == 'esx' then
        return lib.callback.await('mt_workshops:server:getPlayerJobESX', false)
    end
    return nil
end

isPlayerJobBoss = function()
    if Config.framework == 'qb' then
        local PlayerData = Config.core.Functions.GetPlayerData()
        if PlayerData and PlayerData.job then
            return PlayerData.job.isboss
        end
        return false
    elseif Config.framework == 'qbx' then
        if QBX and QBX.PlayerData and QBX.PlayerData.job then
            return QBX.PlayerData.job.isboss
        end
        return false
    elseif Config.framework == 'esx' then
        return lib.callback.await('mt_workshops:server:getPlayerJobIsBossESX', false)
    end
end

isPlayerOnDuty = function()
    if Config.framework == 'qb' then
        local PlayerData = Config.core.Functions.GetPlayerData()
        return PlayerData.job.onduty
    elseif Config.framework == 'qbx' then
        return QBX.PlayerData.job.onduty
    elseif Config.framework == 'esx' then
        return true -- ESX không có onduty mặc định
    end
    return true
end

---@param job string
onZoneEnter = function(job)
    local playerJob = getPlayerJob()
    if playerJob then
        insideZone[playerJob] = true
    end
    insideZone[job] = true
    
    if getPlayerJob() == job then
        if Config.toggleDutyZones then
            if Config.framework == 'qb' then
                local PlayerData = Config.core.Functions.GetPlayerData()
                if not PlayerData.job.onduty then TriggerServerEvent("QBCore:ToggleDuty") end
            elseif Config.framework == 'qbx' then
                if not QBX.PlayerData.job.onduty then TriggerServerEvent("QBCore:ToggleDuty") end
            end
        end
    end
    insideZoneNoJob = true
end

---@param job string
onZoneExit = function(job)
    local playerJob = getPlayerJob()
    if playerJob then
        insideZone[playerJob] = false
    end
    insideZone[job] = false
    
    if getPlayerJob() == job then
        if Config.toggleDutyZones then
            if Config.framework == 'qb' then
                local PlayerData = Config.core.Functions.GetPlayerData()
                if PlayerData.job.onduty then TriggerServerEvent("QBCore:ToggleDuty") end
            elseif Config.framework == 'qbx' then
                if QBX.PlayerData.job.onduty then TriggerServerEvent("QBCore:ToggleDuty") end
            end
        end
    end
    insideZoneNoJob = false
end

---@return any
getClosestVehicle = function()
    return lib.getClosestVehicle(GetEntityCoords(cache.ped), 3.0)
end

---@param message string
---@param type string
notify = function(message, type)
    lib.notify({ description = message, type = type })
end

---@param label string
---@param duration integer
---@param disable table
---@param anim table
---@param prop table
---@return boolean
progressBar = function(label, duration, disable, anim, prop)
	return lib.progressBar({ label = label, duration = duration, position = Config.progressbarPos, useWhileDead = false, canCancel = true, disable = disable, anim = anim, prop = prop })
end

---@param dict string
loadAnimDict = function(dict)
    if not HasAnimDictLoaded(dict) then
        while not HasAnimDictLoaded(dict) do
            RequestAnimDict(dict)
            Wait(5)
        end
    end
end

spawnedWorkshopProps = spawnedWorkshopProps or {}

---@param model string|number
---@return boolean
loadModel = function(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        lib.print.warn('Model is not valid in CDImage: ' .. tostring(model))
        return false
    end
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local time = 200
        while not HasModelLoaded(hash) and time > 0 do
            time = time - 1
            Wait(10)
        end
    end
    return HasModelLoaded(hash)
end

---@param model string|number
---@param coords vector
---@param heading number
---@return integer | nil
createProp = function(model, coords, heading)
    local hash = type(model) == 'number' and model or joaat(model)
    if not loadModel(hash) then return nil end
    local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    if DoesEntityExist(prop) then
        SetEntityHeading(prop, heading or 0.0)
        FreezeEntityPosition(prop, true)
        SetEntityCollision(prop, true, true)
        SetModelAsNoLongerNeeded(hash)
        spawnedWorkshopProps[#spawnedWorkshopProps + 1] = prop
        return prop
    end
    return nil
end

---@param coords vector
---@param model string|number
---@param anim table
---@return integer | nil
createPed = function(coords, model, anim)
    local hash = type(model) == 'number' and model or joaat(model)
    if not loadModel(hash) then return nil end
    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z, coords.w or 0.0, false, true)
    if DoesEntityExist(ped) then
        SetEntityHeading(ped, coords.w or 0.0)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetModelAsNoLongerNeeded(hash)
        if anim then
            if anim.scenario then
                TaskStartScenarioInPlace(ped, anim.scenario, 0, true)
            elseif anim.dict and anim.clip then
                loadAnimDict(anim.dict)
                TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, 0.0, -1, 1, 0.0, false, false, false)
            end
        end
        spawnedWorkshopProps[#spawnedWorkshopProps + 1] = ped
        return ped
    end
    return nil
end

---@param pack string
loadParticle = function(pack)
    if not HasNamedPtfxAssetLoaded(pack) then RequestNamedPtfxAsset(pack) end
    while not HasNamedPtfxAssetLoaded(pack) do Wait(1) end
    SetPtfxAssetNextCall(pack)
end

---@param dict string
loadAnimDict = function(dict)
    if not HasAnimDictLoaded(dict) then
        while not HasAnimDictLoaded(dict) do RequestAnimDict(dict) Wait(5) end
    end
end

---@param animDict string
---@param animName string
---@param duration number
---@param flag integer
playAnim = function(animDict, animName, duration, flag)
	loadAnimDict(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1.0, duration, flag, 1, false, false, false)
end

-- Global table to track vehicle custom colors
VehicleCustomColors = VehicleCustomColors or {}

---@param vehicle integer
---@return table
getVehicleMods = function(vehicle)
    -- Get standard properties ONLY - NO custom color logic
    local props = lib.getVehicleProperties(vehicle)
    
    -- Debug wheel color data
    --print("DEBUG: getVehicleMods - wheelColour:", props.wheelColour)
    --print("DEBUG: getVehicleMods - pearlescentColour:", props.pearlescentColour)
    
    local pearl, wheels = GetVehicleExtraColours(vehicle)
    --print("DEBUG: getVehicleMods - direct natives pearl:", pearl, "wheels:", wheels)
    
    -- DISABLE ALL CUSTOM COLOR LOGIC FOR NOW
    -- local plate = GetVehicleNumberPlateText(vehicle)
    -- if VehicleCustomColors[plate] then
    --     if VehicleCustomColors[plate].primary then
    --         props.customPrimaryColor = VehicleCustomColors[plate].primary
    --     end
    --     
    --     if VehicleCustomColors[plate].secondary then
    --         props.customSecondaryColor = VehicleCustomColors[plate].secondary
    --     end
    -- end
    
    return props
end

---@param vehicle integer
---@param mods table
setVehicleMods = function(vehicle, mods)
    if not vehicle or not DoesEntityExist(vehicle) or not mods then return end
    SetVehicleAutoRepairDisabled(vehicle, true)
    
    local curBodyHealth = GetVehicleBodyHealth(vehicle)
    local curEngineHealth = GetVehicleEngineHealth(vehicle)
    local curTankHealth = GetVehiclePetrolTankHealth(vehicle)
    local curDirt = GetVehicleDirtLevel(vehicle)
    
    SetVehicleModKit(vehicle, 0)
    
    -- Apply standard properties safely
    pcall(function()
        lib.setVehicleProperties(vehicle, mods)
    end)
    
    -- Preserve health/damage if not explicitly specified in mods
    if mods.bodyHealth then
        SetVehicleBodyHealth(vehicle, mods.bodyHealth)
    else
        SetVehicleBodyHealth(vehicle, curBodyHealth)
    end
    
    if mods.engineHealth then
        SetVehicleEngineHealth(vehicle, mods.engineHealth)
    else
        SetVehicleEngineHealth(vehicle, curEngineHealth)
    end
    
    if mods.tankHealth or mods.petrolTankHealth then
        SetVehiclePetrolTankHealth(vehicle, mods.tankHealth or mods.petrolTankHealth)
    else
        SetVehiclePetrolTankHealth(vehicle, curTankHealth)
    end
    
    if mods.dirtLevel then
        SetVehicleDirtLevel(vehicle, mods.dirtLevel)
    else
        SetVehicleDirtLevel(vehicle, curDirt)
    end
    
    -- Check if wheel colors were applied
    local pearl, wheels = GetVehicleExtraColours(vehicle)
    
    -- MANUAL FIX: Ensure wheel colors are applied correctly
    if mods.wheelColour and mods.pearlescentColour then
        SetVehicleExtraColours(vehicle, mods.pearlescentColour, mods.wheelColour)
    elseif mods.wheelColour then
        local currentPearl, _ = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, currentPearl, mods.wheelColour)
    end
    
    -- SIMPLE custom color application - ONLY when mod list has custom color data
    if mods.customPrimaryColor then
        SetVehicleCustomPrimaryColour(vehicle, mods.customPrimaryColor.r, mods.customPrimaryColor.g, mods.customPrimaryColor.b)
    end
    
    if mods.customSecondaryColor then
        SetVehicleCustomSecondaryColour(vehicle, mods.customSecondaryColor.r, mods.customSecondaryColor.g, mods.customSecondaryColor.b)
    end
end

---@param item string
---@param count integer
---@return boolean
getHasItem = function(item, count)
    if Config.inventory == 'ox_inventory' then
        return exports.ox_inventory:GetItemCount(item) >= count
    else
        return lib.callback.await('mt_workshops:server:GetItemCount', false, item) >= count
    end
end

---@param vehicle integer
---@return string | nil
getVehicleClass = function(vehicle)
    local model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    if Config.useQBSharedClasses and (Config.framework == 'qb' or Config.framework == 'qbx') then
        return Config.core.Shared.Vehicles[model].class or 'NONE'
    else
        for ck, cv in pairs(Config.vehicleClasses) do
            if joaat(ck) == GetHashKey(model) then
                return cv
            end
        end
    end

    if Config.useClasses then
        lib.print.warn('Missing class for vehicle: ' .. model)
    else
        lib.print.warn('Classes system disabled!')
    end

    return 'NONE, check F8'
end

---@param text string
---@param icon string
showTextUI = function(text, icon)
    lib.showTextUI(text, { position = "top-center", icon = icon or '' })
end

hideTextUI = function()
    lib.hideTextUI()
end

---@param coords vector
---@param distance number
---@return table
getPlayersFromCoords = function(coords, distance)
    coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
    local players = lib.getNearbyPlayers(coords, distance or 5, true)
    for i = 1, #players do players[i] = players[i].id end
    return players
end

---@param model any
---@param coords vector
---@return any
spawnVehicle = function(model, coords)
    coords = vec4(coords.x, coords.y, coords.z, coords.w or GetEntityHeading(cache.ped))
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end
    loadModel(model)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)
    local netid = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(netid, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    exports['cdn-fuel']:SetFuel(veh, 100.0)
    if Config.keys == 'Renewed-Vehiclekeys' then
        exports['Renewed-Vehiclekeys']:addKey(GetVehicleNumberPlateText(veh))
    else
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
    end
    SetModelAsNoLongerNeeded(model)
    return veh
end

---@param plate string
removeVehicleKey = function(plate)
    if Config.keys == 'Renewed-Vehiclekeys' then
        exports['Renewed-Vehiclekeys']:removeKey(plate)
    end
end

-- Dọn dẹp tất cả prop xưởng khi dừng / restart resource để tránh lỗi Havok collision đè lặp
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if spawnedWorkshopProps then
        for _, prop in ipairs(spawnedWorkshopProps) do
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
        end
        spawnedWorkshopProps = {}
    end
    if toolboxProp and DoesEntityExist(toolboxProp) then
        DeleteEntity(toolboxProp)
        toolboxProp = nil
    end
end)