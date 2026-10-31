-- Helper function to check if a color value is Chameleon (values 161-222)
local function isChameleonColor(colorValue)
    local val = tonumber(colorValue)
    return val and val >= 161 and val <= 222
end

local function getRequiredItemForMod(modData)
    local item = ''
    local money = 0
    local count = 1
    if modData.isPaint then
        if modData.id == 'pearl' or modData.id == 'wheels' then
            if isChameleonColor(modData.value) then
                item = 'chameleon_spray'
            else
                item = 'mechspray'
            end
        elseif modData.isCustomColor then
            item = 'mechspray'
        elseif isChameleonColor(modData.value) then
            item = 'chameleon_spray'
        else
            item = 'mechspray'
        end
        
        -- Look up money from Config.cosmetics based on the item
        for _, mcv in pairs(Config.cosmetics) do
            if mcv.item == item then
                money = mcv.money or 0
                count = mcv.count or 1
                break
            end
        end
    else
        for mck, mcv in pairs(Config.cosmetics) do
            if tonumber(modData.id) == mcv.value or tostring(modData.id) == tostring(mcv.value) then 
                item = mcv.item 
                money = mcv.money or 0
                count = mcv.count or 1
                break 
            end
        end
    end
    
    local itemLabel = Config.itemLabels[item] or item or 'Không rõ'
    return item, itemLabel, money, count
end

---@param data table | nil
---@param item table
openCosmeticsMenu = function(data, item)
    local metadata = item.metadata or item.info
    local plate = metadata.plate or "Không rõ"
    local modsList = {}
    if metadata.modsList then
        for _, mod in ipairs(metadata.modsList) do
            local modCopy = {}
            for k, v in pairs(mod) do
                modCopy[k] = v
            end
            local _, itemLabel, money, count = getRequiredItemForMod(modCopy)
            local reqText = string.format("%dx %s", count, itemLabel)
            if money and money > 0 then
                reqText = string.format("%s, %dx Tiền sạch", reqText, money)
            end
            modCopy.requiredItemLabel = reqText
            modCopy.money = money
            table.insert(modsList, modCopy)
        end
    end
    SendNUI('cosmeticsMenu', { plate = plate, modsList = modsList, slot = item.slot, isMission = metadata.isMission or false })
    ShowNUI('setVisibleCosmeticsMenu', true)
end
RegisterNetEvent('mt_workshops:client:useModsList', openCosmeticsMenu)
exports('openCosmeticsMenu', openCosmeticsMenu)

-- Helper function to get paint category label
local function getPaintCategoryLabel(paintId)
    for _, cat in pairs(Config.paintsCategory) do
        if cat.value == paintId then
            return cat.label
        end
    end
    return paintId
end

-- Helper function to get color name from value
local function getColorNameFromValue(paintType, colorValue)
    if paintType == 'tyresmoke' then
        for _, color in pairs(Config.tyreSmokeColors) do
            if color.value == colorValue then
                return color.label
            end
        end
        return colorValue
    end
    
    -- Check all paint types
    for typeName, colors in pairs(Config.paints) do
        for _, color in pairs(colors) do
            if color.value == colorValue then
                return color.label
            end
        end
    end
    return 'Màu #' .. tostring(colorValue)
end

-- Helper function to get cosmetic label from config
local function getCosmeticLabel(modTypeValue)
    for _, cosmetic in pairs(Config.cosmetics) do
        if tonumber(cosmetic.value) == tonumber(modTypeValue) or tostring(cosmetic.value) == tostring(modTypeValue) then
            return cosmetic.label
        end
    end
    return tostring(modTypeValue)
end

-- Build detailed description for log
local function buildCosmeticDetailLabel(data, item)
    if data.isPaint then
        local categoryLabel = getPaintCategoryLabel(data.id)
        local colorDetail = ''
        
        if data.isCustomColor then
            colorDetail = string.format('RGB(%d, %d, %d)', data.customR or 0, data.customG or 0, data.customB or 0)
        else
            colorDetail = getColorNameFromValue(data.id, data.value)
        end
        
        return string.format('%s: %s', categoryLabel, colorDetail)
    else
        local cosmeticLabel = getCosmeticLabel(data.id)
        return cosmeticLabel
    end
end

RegisterNuiCallback('deleteList', function(data, cb)
    ShowNUI('setVisibleCosmeticsMenu', false)
    lib.callback.await('mt_workshops:server:removeItem', false, 'mods_list', 1, data.list)
    cb(true)
end)

RegisterNuiCallback('applyMod', function(data, cb)
    if not insideZone[getPlayerJob()] then notify(locale('notify_error_inside_zone'), 'error') cb(true) return end
    local vehicle = getClosestVehicle()
    if not vehicle then notify(locale('notify_error_no_vehicle'), 'error') cb(true) return end
    
    local item, itemLabel, money, count = getRequiredItemForMod({
        id = data.id,
        value = data.value,
        isPaint = data.isPaint,
        isCustomColor = data.isCustomColor
    })
    
    if not data.isMission then
        local hasRequirements = lib.callback.await('mt_workshops:server:checkItemAndMoney', false, item, count, money)
        if not hasRequirements then
            local msg = locale('notify_missing_item') .. ' ' .. itemLabel
            if money and money > 0 then
                msg = string.format("Bạn thiếu vật phẩm hoặc không đủ tiền! Yêu cầu: %dx %s và %dx Tiền sạch", count, itemLabel, money)
            end
            notify(msg, 'error')
            cb(true)
            return
        end
    end
    if not (data.plate == GetVehicleNumberPlateText(vehicle)) then notify(locale('notify_error_no_vehicle_plate', data.plate), 'error') cb(true) return end
    ShowNUI('setVisibleCosmeticsMenu', false)
    if data.isPaint then
        spraycan = createProp('ng_proc_spraycan01b', vec3(0.0, 0.0, 0.0), 0.0)
        AttachEntityToEntity(spraycan, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.11, 0.05, -0.06, 28.0, 30.0, 0.0, true, true, false, true, 1, true)
        playAnim("switch@franklin@lamar_tagging_wall", "lamar_tagging_wall_loop_lamar", 10000000, 1)
        Wait(2000)
        ClearPedTasks(cache.ped)
        playAnim("switch@franklin@lamar_tagging_wall", "lamar_tagging_exit_loop_lamar", 100000000, 1)
        loadParticle('core')
        Wait(100)
        UseParticleFxAssetNextCall("core")
        local spray = StartParticleFxLoopedOnEntity("ent_amb_steam", spraycan, 0.0, 0.13, 0.0, 90.0, 90.0, 0.0, 0.2, false, false, false)
        SetParticleFxLoopedAlpha(spray, 255.0)
        SetParticleFxLoopedColour(spray, 255, 255, 255, false)
    end
    if progressBar(locale('progress_install_cosmetic'), Config.times.installingCosmetic, { car = true, walk = true }, data.isPaint and {} or { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 6 }, {}) then
        -- Pass custom color data if available
        local customColorData = nil
        if data.isCustomColor then
            customColorData = {
                r = data.customR,
                g = data.customG,
                b = data.customB
            }
        end
        -- Build detailed description for log
        local detailLabel = buildCosmeticDetailLabel(data, item)
        TriggerServerEvent('mt_workshops:server:setVehicleCosmeticMod', VehToNet(vehicle), data.isPaint, data.wheelType, data.id, data.value, cache.serverId, customColorData, item, detailLabel)
        local savedModsList = {}
        for _, mv in ipairs(data.modsList) do
            local modCopy = {}
            for k, v in pairs(mv) do
                if k ~= "requiredItemLabel" and k ~= "money" then
                    modCopy[k] = v
                end
            end
            if modCopy.id == data.id then modCopy.applied = true end
            table.insert(savedModsList, modCopy)
        end
        lib.callback.await('mt_workshops:server:setItemMetadata', false, 'mods_list', data.slot, { plate = data.plate, modsList = savedModsList, isMission = data.isMission })
        if not data.isMission then
            lib.callback.await('mt_workshops:server:removeItemAndMoney', false, item, count, money, data.slot)
        end
        if data.isMission then checkMissionModsFinished() end
        Wait(500)
    end
    openCosmeticsMenu(nil, { slot = data.slot, metadata = { plate = data.plate, modsList = savedModsList, isMission = data.isMission }})
    ClearPedTasks(cache.ped) 
    if spraycan then DeleteEntity(spraycan) spraycan = nil end
    cb(true)
end)

RegisterNetEvent('mt_workshops:client:setVehicleCosmeticMod', function(vehicle, isPaint, wheelType, modType, modLevel, player, customColorData, itemUsed, detailLabel)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    vehicle = NetToVeh(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local plate = GetVehicleNumberPlateText(vehicle)
    
    if isPaint then
        if modType == 'primary' then
            if customColorData then
                -- Apply custom primary color
                SetVehicleCustomPrimaryColour(vehicle, customColorData.r, customColorData.g, customColorData.b)
                
                -- Track custom color globally
                if not VehicleCustomColors[plate] then VehicleCustomColors[plate] = {} end
                VehicleCustomColors[plate].primary = customColorData
            else
                -- Apply preset primary color
                local _, secoundary = GetVehicleColours(vehicle)
                ClearVehicleCustomPrimaryColour(vehicle)
                SetVehicleColours(vehicle, modLevel, secoundary)
                
                -- Clear custom color tracking
                if VehicleCustomColors[plate] and VehicleCustomColors[plate].primary then
                    VehicleCustomColors[plate].primary = nil
                end
            end
        elseif modType == 'secoundary' then
            if customColorData then
                -- Apply custom secondary color
                SetVehicleCustomSecondaryColour(vehicle, customColorData.r, customColorData.g, customColorData.b)
                
                -- Track custom color globally
                if not VehicleCustomColors[plate] then VehicleCustomColors[plate] = {} end
                VehicleCustomColors[plate].secondary = customColorData
            else
                -- Apply preset secondary color
                local primary, _ = GetVehicleColours(vehicle)
                ClearVehicleCustomSecondaryColour(vehicle)
                SetVehicleColours(vehicle, primary, modLevel)
                
                -- Clear custom color tracking
                if VehicleCustomColors[plate] and VehicleCustomColors[plate].secondary then
                    VehicleCustomColors[plate].secondary = nil
                end
            end
        elseif modType == 'pearl' then
            local pearl, wheel = GetVehicleExtraColours(vehicle)
            SetVehicleExtraColours(vehicle, modLevel, wheel)
        elseif modType == 'wheels' then
            local pearl, wheel = GetVehicleExtraColours(vehicle)
            SetVehicleExtraColours(vehicle, pearl, modLevel)
        elseif modType == 'interior' then
            SetVehicleInteriorColor(vehicle, modLevel)
        elseif modType == 'dashboard' then
            SetVehicleDashboardColor(vehicle, modLevel)
        elseif modType == 'tyresmoke' then
            if modLevel == 'off' then
                ToggleVehicleMod(vehicle, 20, false)
            else
                local r, g, b = string.match(modLevel, '(%d+),(%d+),(%d+)')
                SetVehicleTyreSmokeColor(vehicle, tonumber(r), tonumber(g), tonumber(b))
                ToggleVehicleMod(vehicle, 20, true)
            end
        end
    elseif modType == 'plates' then
        SetVehicleNumberPlateTextIndex(vehicle, modLevel)
    elseif modType == 'windowTint' then
        SetVehicleWindowTint(vehicle, modLevel)
    elseif modType == 'livery' then
        SetVehicleLivery(vehicle, modLevel)
    else
        SetVehicleModKit(vehicle, 0)
        if type(modType) == 'number' then
            if (modType == 23 or modType == 24) and wheelType then
                SetVehicleWheelType(vehicle, wheelType)
            end
            local numMods = GetNumVehicleMods(vehicle, modType)
            if modLevel == -1 or (numMods > 0 and modLevel < numMods) then
                SetVehicleMod(vehicle, modType, modLevel, false)
            end
        end
    end
    if cache.serverId == player then
        -- Save vehicle mods (global tracking will include custom colors)
        local coords = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)
        lib.callback.await('mt_workshops:server:saveVehicleMods', false, vehicle, getVehicleMods(vehicle), true, { x = coords.x, y = coords.y, z = coords.z, w = heading }, 'Cosmetics', detailLabel or itemUsed)
    end
end)