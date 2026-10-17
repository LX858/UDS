local customColorsApplied = {} -- Track custom colors applied during preview
local modifiedCategories = {} -- Track which categories were actually modified in this session

-- Export custom colors tracking for other files
getCurrentCustomColors = function()
    return customColorsApplied
end
exports('getCurrentCustomColors', getCurrentCustomColors)

local inPreview = false
local previewVehicle = nil
local previewDefaultMods = nil
local previewVehicleDamage = nil

local restoreVehicleDamage = function(veh)
    if not veh or not DoesEntityExist(veh) or not previewVehicleDamage then return end
    SetVehicleAutoRepairDisabled(veh, true)
    if previewVehicleDamage.bodyHealth then SetVehicleBodyHealth(veh, previewVehicleDamage.bodyHealth) end
    if previewVehicleDamage.engineHealth then SetVehicleEngineHealth(veh, previewVehicleDamage.engineHealth) end
    if previewVehicleDamage.tankHealth then SetVehiclePetrolTankHealth(veh, previewVehicleDamage.tankHealth) end
    if previewVehicleDamage.dirtLevel then SetVehicleDirtLevel(veh, previewVehicleDamage.dirtLevel) end
    
    if previewVehicleDamage.doorsDamaged then
        for door, damaged in pairs(previewVehicleDamage.doorsDamaged) do
            if damaged then SetVehicleDoorBroken(veh, door, true) end
        end
    end
    if previewVehicleDamage.windows then
        for window, broken in pairs(previewVehicleDamage.windows) do
            if broken then SmashVehicleWindow(veh, window) end
        end
    end
    if previewVehicleDamage.tyres then
        for tyre, burstState in pairs(previewVehicleDamage.tyres) do
            SetVehicleTyreBurst(veh, tyre, burstState == 1000.0, 1000.0)
        end
    end
end

local restorePreviewVehicle = function(veh, defaultMods)
    if not veh or not DoesEntityExist(veh) or not defaultMods then return end
    SetVehicleAutoRepairDisabled(veh, true)
    
    -- Restore standard mods
    setVehicleMods(veh, defaultMods)
    
    -- Restore window tint
    if defaultMods.windowTint then
        SetVehicleWindowTint(veh, defaultMods.windowTint)
    end
    
    -- Restore tyre smoke
    if defaultMods.tyreSmokeEnabled then
        SetVehicleTyreSmokeColor(veh, defaultMods.tyreSmokeR or 255, defaultMods.tyreSmokeG or 255, defaultMods.tyreSmokeB or 255)
        ToggleVehicleMod(veh, 20, true)
    else
        ToggleVehicleMod(veh, 20, false)
    end
    
    -- Restore custom colors (primary & secondary)
    if defaultMods.hasCustomPrimary and defaultMods.customPrimaryR then
        SetVehicleCustomPrimaryColour(veh, defaultMods.customPrimaryR, defaultMods.customPrimaryG, defaultMods.customPrimaryB)
    else
        ClearVehicleCustomPrimaryColour(veh)
    end
    
    if defaultMods.hasCustomSecondary and defaultMods.customSecondaryR then
        SetVehicleCustomSecondaryColour(veh, defaultMods.customSecondaryR, defaultMods.customSecondaryG, defaultMods.customSecondaryB)
    else
        ClearVehicleCustomSecondaryColour(veh)
    end
    
    -- Restore extra colours (pearlescent and wheel colours)
    local currentPearl, currentWheels = GetVehicleExtraColours(veh)
    local targetPearl = defaultMods.pearlescentColour or currentPearl
    local targetWheels = defaultMods.wheelColour or currentWheels
    SetVehicleExtraColours(veh, targetPearl, targetWheels)
    
    -- Restore dashboard & interior colours
    if defaultMods.dashboardColor then
        SetVehicleDashboardColor(veh, defaultMods.dashboardColor)
    end
    if defaultMods.interiorColor then
        SetVehicleInteriorColor(veh, defaultMods.interiorColor)
    end
    
    -- Restore plate index
    if defaultMods.plateIndex then
        SetVehicleNumberPlateTextIndex(veh, defaultMods.plateIndex)
    end
    
    -- Restore livery
    if defaultMods.modLivery and defaultMods.modLivery ~= -1 then
        SetVehicleLivery(veh, defaultMods.modLivery)
    end
    
    -- Restore damage
    restoreVehicleDamage(veh)
    
    -- Unfreeze vehicle
    FreezeEntityPosition(veh, false)
end

-- GTA5 standard vehicle color palette: colorIndex → {r, g, b}
-- Used to find the closest preset color for pearl/wheels/dashboard (which only support indexed colors)
local GTA_COLOR_RGB = {
    [0] = {13,17,22}, [1] = {28,29,33}, [2] = {50,56,61}, [3] = {69,75,79},
    [4] = {153,157,160}, [5] = {194,196,198}, [6] = {151,154,151}, [7] = {99,115,128},
    [8] = {100,100,100}, [9] = {66,72,74}, [10] = {30,35,41}, [11] = {76,76,76},
    [12] = {19,24,31}, [13] = {38,40,42}, [14] = {81,85,84},
    [27] = {192,14,26}, [28] = {218,25,24}, [29] = {182,17,27}, [30] = {163,30,35},
    [31] = {162,76,76}, [32] = {120,22,32}, [33] = {72,14,16}, [34] = {87,31,35},
    [35] = {202,89,0}, [36] = {255,140,0}, [38] = {233,185,65},
    [39] = {122,7,12}, [40] = {73,13,19}, [41] = {255,103,0}, [42] = {255,207,32},
    [49] = {21,92,45}, [50] = {0,78,42}, [51] = {43,77,55}, [52] = {101,114,55},
    [53] = {60,85,23}, [54] = {18,46,43}, [55] = {102,130,0},
    [61] = {0,46,109}, [62] = {26,24,46}, [63] = {47,56,91}, [64] = {44,64,103},
    [65] = {55,80,130}, [66] = {62,96,139}, [67] = {69,108,162}, [68] = {45,66,107},
    [69] = {40,47,79}, [70] = {0,68,136}, [71] = {68,36,100}, [72] = {43,56,111},
    [73] = {40,50,115}, [74] = {140,167,186},
    [82] = {37,38,75}, [83] = {52,74,112}, [84] = {30,36,66},
    [88] = {94,78,10}, [89] = {170,144,10}, [90] = {101,63,0}, [91] = {74,68,1},
    [92] = {102,130,0}, [94] = {77,51,30}, [95] = {60,40,21}, [96] = {46,24,10},
    [97] = {100,77,46}, [98] = {67,45,22}, [99] = {206,186,124}, [100] = {63,48,28},
    [101] = {96,66,29}, [102] = {108,91,52}, [103] = {83,62,36}, [104] = {97,52,19},
    [105] = {198,172,120}, [106] = {148,130,91}, [107] = {154,140,115},
    [111] = {252,252,252}, [112] = {244,244,244},
    [117] = {194,186,175}, [118] = {100,100,100}, [119] = {188,190,193},
    [128] = {69,89,21}, [131] = {252,249,241},
    [135] = {219,105,150}, [136] = {247,166,172}, [137] = {226,134,168},
    [138] = {252,152,45}, [141] = {0,69,53}, [142] = {61,18,68}, [143] = {80,18,28},
    [145] = {96,60,141}, [147] = {50,50,50}, [148] = {104,50,113}, [149] = {51,10,58},
    [150] = {188,25,16}, [151] = {14,49,17}, [152] = {72,69,40}, [153] = {51,36,19},
    [154] = {174,150,87}, [155] = {36,58,19}, [158] = {163,145,63}, [159] = {186,166,86},
}

--- Find the closest GTA5 color index for a given RGB value (Euclidean distance)
local findClosestColorIndex = function(r, g, b)
    local bestIndex = 0
    local bestDist = math.huge
    for idx, rgb in pairs(GTA_COLOR_RGB) do
        local dr = r - rgb[1]
        local dg = g - rgb[2]
        local db = b - rgb[3]
        local dist = dr*dr + dg*dg + db*db
        if dist < bestDist then
            bestDist = dist
            bestIndex = idx
        end
    end
    return bestIndex
end

-- Helper function to re-apply custom colors
local reApplyCustomColors = function()
    if not previewVehicle then return end
    
    -- Apply custom colors directly without clearing first
    if customColorsApplied['primary'] then
        --print("DEBUG: Re-applying primary custom color:", customColorsApplied['primary'].r, customColorsApplied['primary'].g, customColorsApplied['primary'].b)
        SetVehicleCustomPrimaryColour(previewVehicle, customColorsApplied['primary'].r, customColorsApplied['primary'].g, customColorsApplied['primary'].b)
    end
    if customColorsApplied['secoundary'] then
        --print("DEBUG: Re-applying secondary custom color:", customColorsApplied['secoundary'].r, customColorsApplied['secoundary'].g, customColorsApplied['secoundary'].b)
        SetVehicleCustomSecondaryColour(previewVehicle, customColorsApplied['secoundary'].r, customColorsApplied['secoundary'].g, customColorsApplied['secoundary'].b)
    end
end

---@param value any
---@return string
local getColorLabel = function(value)
    --print("DEBUG: getColorLabel - Looking for color value:", value)
    for pk, _ in pairs(Config.paints) do
        --print("DEBUG: Checking paint category:", pk)
        for _, p2v in pairs(Config.paints[pk]) do
            if p2v.value == value then 
                --print("DEBUG: Found color label:", p2v.label, "in category:", pk)
                return p2v.label 
            end
        end
    end
    --print("DEBUG: No label found for color value:", value)
    return ''
end

openPreviewMenu = function()
    if inPreview then return end
    local vehicleCosmetics = {}
    local cosmetics = {}
    if not ((Config.preview.lockJob and insideZone[getPlayerJob()]) or (not Config.preview.lockJob and insideZoneNoJob)) then notify(locale('notify_error_inside_zone'), 'error') return end
    if not IsPedInAnyVehicle(cache.ped, false) then notify(locale('notify_error_no_vehicle_in'), 'error') return end
    previewVehicle = GetVehiclePedIsIn(cache.ped, false)
    for i = 0, (GetVehicleModelNumberOfSeats(GetEntityModel(previewVehicle)) - 2) do
        if not IsVehicleSeatFree(previewVehicle, i) then
            notify(locale('notify_error_no_passenger'), 'error')
            previewVehicle = nil
            return
        end
    end
    inPreview = true
    customColorsApplied = {} -- Reset custom colors tracking
    modifiedCategories = {} -- Reset modified categories tracking
    
    -- Store original vehicle state
    originalVehicleState = getVehicleMods(previewVehicle)
    
    -- Notify server that we're starting preview with original state
    TriggerServerEvent('mt_workshops:server:startPreview', VehToNet(previewVehicle), originalVehicleState)
    
    -- DISABLE CUSTOM COLOR RESTORE FOR NOW
    -- Get vehicle plate for global tracking
    -- local plate = GetVehicleNumberPlateText(previewVehicle)
    -- if not VehicleCustomColors[plate] then VehicleCustomColors[plate] = {} end
    
    -- Restore existing custom colors from global tracking
    -- if VehicleCustomColors[plate].primary then
    --     customColorsApplied['primary'] = VehicleCustomColors[plate].primary
    --     --print("DEBUG: Restored primary custom color from global tracking:", VehicleCustomColors[plate].primary.r, VehicleCustomColors[plate].primary.g, VehicleCustomColors[plate].primary.b)
    -- end
    -- if VehicleCustomColors[plate].secondary then
    --     customColorsApplied['secoundary'] = VehicleCustomColors[plate].secondary
    --     --print("DEBUG: Restored secondary custom color from global tracking:", VehicleCustomColors[plate].secondary.r, VehicleCustomColors[plate].secondary.g, VehicleCustomColors[plate].secondary.b)
    -- end
    
    FreezeEntityPosition(previewVehicle, true)
    SetVehicleAutoRepairDisabled(previewVehicle, true)
    SetVehicleModKit(previewVehicle, 0)
    previewDefaultMods = getVehicleMods(previewVehicle)
    
    previewVehicleDamage = {
        bodyHealth = GetVehicleBodyHealth(previewVehicle),
        engineHealth = GetVehicleEngineHealth(previewVehicle),
        tankHealth = GetVehiclePetrolTankHealth(previewVehicle),
        dirtLevel = GetVehicleDirtLevel(previewVehicle),
        doorsDamaged = {},
        windows = {},
        tyres = {},
    }
    for i = 0, 5 do
        if IsVehicleDoorDamaged(previewVehicle, i) then
            previewVehicleDamage.doorsDamaged[i] = true
        end
    end
    for i = 0, 7 do
        if not IsVehicleWindowIntact(previewVehicle, i) then
            previewVehicleDamage.windows[i] = true
        end
    end
    for i = 0, 5 do
        if IsVehicleTyreBurst(previewVehicle, i, false) then
            previewVehicleDamage.tyres[i] = IsVehicleTyreBurst(previewVehicle, i, true) and 1000.0 or 100.0
        end
    end
    previewDefaultMods.windowTint = (GetVehicleWindowTint(previewVehicle) > -1) and GetVehicleWindowTint(previewVehicle) or 0
    previewDefaultMods.tyreSmokeEnabled = IsToggleModOn(previewVehicle, 20)
    local defSR, defSG, defSB = GetVehicleTyreSmokeColor(previewVehicle)
    previewDefaultMods.tyreSmokeR = defSR
    previewDefaultMods.tyreSmokeG = defSG
    previewDefaultMods.tyreSmokeB = defSB
    
    -- Store original custom colors if any
    local hasCustomPrimary, primaryR, primaryG, primaryB = GetIsVehiclePrimaryColourCustom(previewVehicle)
    local hasCustomSecondary, secondaryR, secondaryG, secondaryB = GetIsVehicleSecondaryColourCustom(previewVehicle)
    
    if hasCustomPrimary then
        previewDefaultMods.hasCustomPrimary = true
        previewDefaultMods.customPrimaryR = primaryR
        previewDefaultMods.customPrimaryG = primaryG
        previewDefaultMods.customPrimaryB = primaryB
    end
    
    if hasCustomSecondary then
        previewDefaultMods.hasCustomSecondary = true
        previewDefaultMods.customSecondaryR = secondaryR
        previewDefaultMods.customSecondaryG = secondaryG
        previewDefaultMods.customSecondaryB = secondaryB
    end
    for k, v in pairs(Config.cosmetics) do
        if v.value == 23 or v.value == 24 then
            local wheelType = IsThisModelABike(GetEntityModel(previewVehicle)) and 6 or Config.rimsCategory[1].value end
        if v.value == 'paints' then
            local colors = {
                dashboard = GetVehicleDashboardColour(previewVehicle),
                interior = GetVehicleInteriorColour(previewVehicle)
            }
            colors.primary, colors.secoundary = GetVehicleColours(previewVehicle)
            colors.pearl, colors.wheels = GetVehicleExtraColours(previewVehicle)
            cosmetics[#cosmetics + 1] = v
            for _, p in pairs(Config.paints[Config.paintsTypes[1].value]) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = p.label,
                    value = p.value,
                    selected = (colors[Config.paintsCategory[1].value] == p.value)
                }
            end
        elseif v.value == 'windowTint' then
            cosmetics[#cosmetics + 1] = v
            for _, w in pairs(Config.windowTint) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = w.label,
                    value = w.value,
                    selected = (GetVehicleWindowTint(previewVehicle) == w.value)
                }
            end
        elseif v.value == 'plates' then
            cosmetics[#cosmetics + 1] = v
            for _, p in pairs(Config.plates) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = p.label,
                    value = p.value,
                    selected = (GetVehicleNumberPlateTextIndex(previewVehicle) == p.value)
                }
            end
        elseif v.value == 'livery' then
            local liveryCount = GetVehicleLiveryCount(previewVehicle)
            if liveryCount > 0 then
                cosmetics[#cosmetics + 1] = v
                for i = -1, liveryCount - 1 do
                    local label = 'Stock'
                    if i > -1 then
                        local liveryName = GetLiveryName(previewVehicle, i)
                        local modLabel = liveryName and GetLabelText(liveryName)
                        label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (i + 1)) or modLabel
                    end
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = label,
                        value = i,
                        selected = (GetVehicleLivery(previewVehicle) == i)
                    }
                end
            end
        elseif v.value == 14 then
            cosmetics[#cosmetics + 1] = v
            for _, h in pairs(Config.horns) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = h.label,
                    value = h.value,
                    selected = (GetVehicleMod(previewVehicle, v.value) == h.value)
                }
            end
        else
            local numMods = GetNumVehicleMods(previewVehicle, v.value)
            if numMods > 0 then
                cosmetics[#cosmetics + 1] = v
                for i = -1, numMods - 1 do
                    local label = 'Stock'
                    if i > -1 then
                        local modLabelText = GetModTextLabel(previewVehicle, v.value, i)
                        local modLabel = modLabelText and GetLabelText(modLabelText)
                        label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (i + 1)) or string.format("%s - %s", (i + 1), modLabel)
                    end
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = label,
                        value = i,
                        selected = (GetVehicleMod(previewVehicle, v.value) == i)
                    }
                end
            end
        end
    end
    SendNUI('helpMenu', {})
    -- Create default colors array from neon colors config
    local defaultColors = {}
    for _, color in pairs(Config.neonsColors) do
        table.insert(defaultColors, color)
    end
    SendNUI('previewMenu', { 
        categories = cosmetics, 
        options = vehicleCosmetics, 
        wheelsCategory = Config.rimsCategory, 
        paintsTypes = Config.paintsTypes, 
        paintsCategory = Config.paintsCategory,
        defaultColors = defaultColors
    })
    ShowNUI('setVisiblePreviewMenu', true)
end
exports('openPreviewMenu', openPreviewMenu)
RegisterNetEvent('mt_workshops:client:openPreviewMenu', openPreviewMenu)

RegisterNuiCallback('refreshOptions', function(data, cb)
    local vehicleCosmetics = {}
    for k, v in pairs(Config.cosmetics) do
        if v.value == 23 or v.value == 24 then
            local wheelType = IsThisModelABike(SetVehicleWheelType(previewVehicle,  data.wheelsValue)) and 6 or Config.rimsCategory[1].value
        end

        if v.value == 'paints' then
            if data.selectedPaintCategory == 'tyresmoke' then
                local smokeEnabled = IsToggleModOn(previewVehicle, 20)
                local sr, sg, sb = GetVehicleTyreSmokeColor(previewVehicle)
                local currentSmoke = smokeEnabled and string.format('%d,%d,%d', sr, sg, sb) or 'off'
                for _, ts in pairs(Config.tyreSmokeColors) do
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = ts.label,
                        value = ts.value,
                        selected = (currentSmoke == ts.value)
                    }
                end
            else
                local colors = {
                    dashboard = GetVehicleDashboardColour(previewVehicle),
                    interior = GetVehicleInteriorColour(previewVehicle)
                }
                colors.primary, colors.secoundary = GetVehicleColours(previewVehicle)
                colors.pearl, colors.wheels = GetVehicleExtraColours(previewVehicle)
                for _, p in pairs(Config.paints[data.paintsValue]) do
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = p.label,
                        value = p.value,
                        selected = (colors[data.selectedPaintCategory] == p.value)
                    }
                end
            end
        elseif v.value == 'livery' then
            local liveryCount = GetVehicleLiveryCount(previewVehicle)
            if liveryCount > 0 then
                for i = -1, liveryCount - 1 do
                    local label = 'Stock'
                    if i > -1 then
                        local liveryName = GetLiveryName(previewVehicle, i)
                        local modLabel = liveryName and GetLabelText(liveryName)
                        label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (i + 1)) or modLabel
                    end
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = label,
                        value = i,
                        selected = (GetVehicleLivery(previewVehicle) == i)
                    }
                end
            end
        elseif v.value == 'windowTint' then
            for _, w in pairs(Config.windowTint) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = w.label,
                    value = w.value,
                    selected = (GetVehicleWindowTint(previewVehicle) == w.value)
                }
            end
        elseif v.value == 'plates' then
            for _, p in pairs(Config.plates) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = p.label,
                    value = p.value,
                    selected = (GetVehicleNumberPlateTextIndex(previewVehicle) == p.value)
                }
            end
        elseif v.value == 14 then
            for _, h in pairs(Config.horns) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = h.label,
                    value = h.value,
                    selected = (GetVehicleMod(previewVehicle, v.value) == h.value)
                }
            end
        else
            if GetNumVehicleMods(previewVehicle, v.value) > 0 then
                for i = -1, (GetNumVehicleMods(previewVehicle, v.value) - 1) do
                    local modLabel = string.format("%s - %s", (i + 1), GetLabelText(GetModTextLabel(previewVehicle, v.value, i)))
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label =  (i == -1) and 'Stock' or (modLabel == "NULL" or modLabel == nil) and locale('ui_custom') or modLabel,
                        value = i,
                        selected = (GetVehicleMod(previewVehicle, v.value) == i)
                    }
                end
            end
        end
    end
    SendNUI('previewMenuUpdateOptions', { options = vehicleCosmetics })
    cb(true)
end)

RegisterNuiCallback('activeCamera', function(data, cb)
    ShowNUI('setVisiblePreviewMenu', false)
    ShowNUI('setVisibleHelpMenu', true)
    SetNuiFocus(false, false)
    CreateThread(function()
        while true do
            if IsControlJustPressed(0, 202) then
                ShowNUI('setVisiblePreviewMenu', true)
                ShowNUI('setVisibleHelpMenu', false)
                SetNuiFocus(true, true)
                break
            end
            Wait(5) -- Tăng từ 1 lên 5ms để giảm CPU, vẫn đủ responsive cho input
        end
    end)
    cb(true)
end)

RegisterNuiCallback('applyCustomColor', function(data, cb)
    if not data.color or not data.category then cb(true) return end
    
    -- Parse RGB color string to r,g,b values
    local r, g, b = string.match(data.color, "rgb%((%d+),%s*(%d+),%s*(%d+)%)")
    if not r or not g or not b then cb(true) return end
    
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not r or not g or not b then cb(true) return end
    
    --print("DEBUG: Applying custom color", r, g, b, "to category", data.category)
    
    -- SIMPLE like preset colors - just apply and track for mod list
    if data.category == 'primary' then
        -- Apply color directly (like preset colors do with SetVehicleColours)
        SetVehicleCustomPrimaryColour(previewVehicle, r, g, b)
        
        -- Store for mod list (like preset colors store modifications)
        customColorsApplied['primary'] = { r = r, g = g, b = b }
        modifiedCategories['primary'] = true
        --print("DEBUG: Applied primary custom color and marked as modified")
        
    elseif data.category == 'secoundary' then
        -- Apply color directly (like preset colors do with SetVehicleColours)
        SetVehicleCustomSecondaryColour(previewVehicle, r, g, b)
        
        -- Store for mod list (like preset colors store modifications)
        customColorsApplied['secoundary'] = { r = r, g = g, b = b }
        modifiedCategories['secoundary'] = true
        --print("DEBUG: Applied secondary custom color and marked as modified")
    
    elseif data.category == 'pearl' then
        local closestIdx = findClosestColorIndex(r, g, b)
        local currentPearl, currentWheels = GetVehicleExtraColours(previewVehicle)
        SetVehicleExtraColours(previewVehicle, closestIdx, currentWheels)
        modifiedCategories['pearl'] = true
        reApplyCustomColors()
    
    elseif data.category == 'wheels' then
        local closestIdx = findClosestColorIndex(r, g, b)
        local currentPearl, currentWheels = GetVehicleExtraColours(previewVehicle)
        SetVehicleExtraColours(previewVehicle, currentPearl, closestIdx)
        modifiedCategories['wheels'] = true
        reApplyCustomColors()
    
    elseif data.category == 'dashboard' then
        local closestIdx = findClosestColorIndex(r, g, b)
        SetVehicleDashboardColor(previewVehicle, closestIdx)
        modifiedCategories['dashboard'] = true
    
    elseif data.category == 'tyresmoke' then
        SetVehicleTyreSmokeColor(previewVehicle, r, g, b)
        ToggleVehicleMod(previewVehicle, 20, true)
    end
    
    cb(true)
end)

RegisterNuiCallback('resetToPreset', function(data, cb)
    if not previewDefaultMods then cb(true) return end
    
    -- Reset to default colors when switching back to preset
    local paintCategory = data.category
    if paintCategory == 'primary' then
        ClearVehicleCustomPrimaryColour(previewVehicle)
        -- Clear tracking for primary custom color
        customColorsApplied['primary'] = nil
        
        -- Clear global tracking
        local plate = GetVehicleNumberPlateText(previewVehicle)
        if VehicleCustomColors[plate] and VehicleCustomColors[plate].primary then
            VehicleCustomColors[plate].primary = nil
            --print("DEBUG: Cleared global tracking for primary, plate:", plate)
        end
        
        -- Get current secondary color to preserve it
        local _, currentSecondary = GetVehicleColours(previewVehicle)
        SetVehicleColours(previewVehicle, previewDefaultMods.color1 or 0, currentSecondary)
        -- Re-apply secondary custom color if it exists
        if customColorsApplied['secoundary'] then
            SetVehicleCustomSecondaryColour(previewVehicle, customColorsApplied['secoundary'].r, customColorsApplied['secoundary'].g, customColorsApplied['secoundary'].b)
        end
        
    elseif paintCategory == 'secoundary' then
        ClearVehicleCustomSecondaryColour(previewVehicle)
        -- Clear tracking for secondary custom color
        customColorsApplied['secoundary'] = nil
        
        -- Clear global tracking
        local plate = GetVehicleNumberPlateText(previewVehicle)
        if VehicleCustomColors[plate] and VehicleCustomColors[plate].secondary then
            VehicleCustomColors[plate].secondary = nil
            --print("DEBUG: Cleared global tracking for secondary, plate:", plate)
        end
        
        -- Get current primary color to preserve it
        local currentPrimary, _ = GetVehicleColours(previewVehicle)
        SetVehicleColours(previewVehicle, currentPrimary, previewDefaultMods.color2 or 0)
        -- Re-apply primary custom color if it exists
        if customColorsApplied['primary'] then
            SetVehicleCustomPrimaryColour(previewVehicle, customColorsApplied['primary'].r, customColorsApplied['primary'].g, customColorsApplied['primary'].b)
        end
    end
    
    cb(true)
end)

RegisterNuiCallback('chooseMod', function(data, cb)
    local paintCategory = data.selectedPaintCategory
    if data.category == 'paints' then
        local primary, secoundary = GetVehicleColours(previewVehicle)
        local pearl, wheels = GetVehicleExtraColours(previewVehicle)
        local dashboard = GetVehicleDashboardColour(previewVehicle)
        local interior = GetVehicleInteriorColour(previewVehicle)
        
        if paintCategory == 'primary' then
            -- Clear custom primary and set new preset primary
            ClearVehicleCustomPrimaryColour(previewVehicle)
            -- Clear tracking for primary custom color
            customColorsApplied['primary'] = nil
            -- Mark this category as modified
            modifiedCategories['primary'] = true
            SetVehicleColours(previewVehicle, data.value, secoundary)
            --print("DEBUG: Applied primary preset color, marked category as modified")
            
        elseif paintCategory == 'secoundary' then
            -- Clear custom secondary and set new preset secondary
            ClearVehicleCustomSecondaryColour(previewVehicle)
            -- Clear tracking for secondary custom color
            customColorsApplied['secoundary'] = nil
            -- Mark this category as modified
            modifiedCategories['secoundary'] = true
            SetVehicleColours(previewVehicle, primary, data.value)
            --print("DEBUG: Applied secondary preset color, marked category as modified")
            
        elseif paintCategory == 'pearl' then
            -- Pearl only affects extra colors, preserve custom primary/secondary
            --print("DEBUG: Setting pearl color, preserving custom colors")
            SetVehicleExtraColours(previewVehicle, data.value, wheels)
            -- Mark pearl category as modified
            modifiedCategories['pearl'] = true
            --print("DEBUG: Marked pearl category as modified")
            -- Re-apply custom colors if they exist
            reApplyCustomColors()
            
        elseif paintCategory == 'wheels' then
            -- Wheels only affects extra colors, preserve custom primary/secondary
            --print("DEBUG: Setting wheel color, preserving custom colors")
            SetVehicleExtraColours(previewVehicle, pearl, data.value)
            -- Mark wheels category as modified
            modifiedCategories['wheels'] = true
            --print("DEBUG: Marked wheels category as modified")
            -- Re-apply custom colors if they exist
            reApplyCustomColors()
            
        elseif paintCategory == 'dashboard' then
            -- Dashboard doesn't affect primary/secondary colors
            SetVehicleDashboardColor(previewVehicle, data.value)
            
        elseif paintCategory == 'interior' then
            -- Interior doesn't affect primary/secondary colors
            SetVehicleInteriorColor(previewVehicle, data.value)
        elseif paintCategory == 'tyresmoke' then
            if data.value == 'off' then
                ToggleVehicleMod(previewVehicle, 20, false)
            else
                local r, g, b = string.match(data.value, '(%d+),(%d+),(%d+)')
                SetVehicleTyreSmokeColor(previewVehicle, tonumber(r), tonumber(g), tonumber(b))
                ToggleVehicleMod(previewVehicle, 20, true)
            end
        end
    elseif data.category == 'windowTint' then
        SetVehicleWindowTint(previewVehicle, data.value)
    elseif data.category == 'plates' then
        SetVehicleNumberPlateTextIndex(previewVehicle, data.value)
    elseif data.category == 'livery' then
        SetVehicleLivery(previewVehicle, data.value)
    else
        SetVehicleModKit(previewVehicle, 0)
        if type(data.category) == 'number' then
            local numMods = GetNumVehicleMods(previewVehicle, data.category)
            if data.value == -1 or (numMods > 0 and data.value < numMods) then
                SetVehicleMod(previewVehicle, data.category, data.value, false)
            end
        end
    end
    local vehicleCosmetics = {}
    for k, v in pairs(Config.cosmetics) do
        if v.value == 'paints' then
            if paintCategory == 'tyresmoke' then
                local smokeEnabled = IsToggleModOn(previewVehicle, 20)
                local sr, sg, sb = GetVehicleTyreSmokeColor(previewVehicle)
                local currentSmoke = smokeEnabled and string.format('%d,%d,%d', sr, sg, sb) or 'off'
                for _, ts in pairs(Config.tyreSmokeColors) do
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = ts.label,
                        value = ts.value,
                        selected = (currentSmoke == ts.value)
                    }
                end
            else
                local colors = {
                    dashboard = GetVehicleDashboardColour(previewVehicle),
                    interior = GetVehicleInteriorColour(previewVehicle)
                }
                colors.primary, colors.secoundary = GetVehicleColours(previewVehicle)
                colors.pearl, colors.wheels = GetVehicleExtraColours(previewVehicle)
                for _, p in pairs(Config.paints[data.selectedPaintType]) do
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = p.label,
                        value = p.value,
                        selected = (colors[paintCategory] == p.value)
                    }
                end
            end
        elseif v.value == 'windowTint' then
            for _, w in pairs(Config.windowTint) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = w.label,
                    value = w.value,
                    selected = (GetVehicleWindowTint(previewVehicle) == w.value)
                }
            end
        elseif v.value == 'plates' then
            for _, p in pairs(Config.plates) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = p.label,
                    value = p.value,
                    selected = (GetVehicleNumberPlateTextIndex(previewVehicle) == p.value)
                }
            end
        elseif v.value == 14 then
            for _, h in pairs(Config.horns) do
                vehicleCosmetics[#vehicleCosmetics + 1] = {
                    category = v.value,
                    label = h.label,
                    value = h.value,
                    selected = (GetVehicleMod(previewVehicle, v.value) == h.value)
                }
            end
        elseif v.value == 'livery' then
            local liveryCount = GetVehicleLiveryCount(previewVehicle)
            if liveryCount > 0 then
                for i = -1, liveryCount - 1 do
                    local label = 'Stock'
                    if i > -1 then
                        local liveryName = GetLiveryName(previewVehicle, i)
                        local modLabel = liveryName and GetLabelText(liveryName)
                        label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (i + 1)) or modLabel
                    end
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = label,
                        value = i,
                        selected = (GetVehicleLivery(previewVehicle) == i)
                    }
                end
            end
        else
            local numMods = GetNumVehicleMods(previewVehicle, v.value)
            if numMods > 0 then
                for i = -1, numMods - 1 do
                    local label = 'Stock'
                    if i > -1 then
                        local modLabelText = GetModTextLabel(previewVehicle, v.value, i)
                        local modLabel = modLabelText and GetLabelText(modLabelText)
                        label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (i + 1)) or string.format("%s - %s", (i + 1), modLabel)
                    end
                    vehicleCosmetics[#vehicleCosmetics + 1] = {
                        category = v.value,
                        label = label,
                        value = i,
                        selected = (GetVehicleMod(previewVehicle, v.value) == i)
                    }
                end
            end
        end
    end
    SendNUI('previewMenuUpdateOptions', { options = vehicleCosmetics })
    cb(true)
end)

local finishPreview = function()
    if not inPreview or not previewVehicle or not previewDefaultMods then return end
    
    local veh = previewVehicle
    local defaultMods = previewDefaultMods
    local currentMods = getVehicleMods(veh)

    inPreview = false
    ShowNUI('setVisiblePreviewMenu', false)
    
    -- Notify server that we're ending preview normally
    TriggerServerEvent('mt_workshops:server:endPreview', VehToNet(veh))
    
    if not currentMods then
        restorePreviewVehicle(veh, defaultMods)
        previewVehicleDamage = nil
        previewDefaultMods = nil
        previewVehicle = nil
        customColorsApplied = {}
        modifiedCategories = {}
        return
    end

    local modsList = {}
    
    for ck, cv in pairs(Config.cosmetics) do
        if cv.value == 'paints' then
            for pk, pv in pairs(Config.paintsCategory) do
                -- Handle tyresmoke separately within paints
                if pv.value == 'tyresmoke' then
                    local currentEnabled = IsToggleModOn(veh, 20)
                    local sr, sg, sb = GetVehicleTyreSmokeColor(veh)
                    local changed = currentEnabled ~= defaultMods.tyreSmokeEnabled
                        or sr ~= defaultMods.tyreSmokeR
                        or sg ~= defaultMods.tyreSmokeG
                        or sb ~= defaultMods.tyreSmokeB
                    if changed then
                        local newValue = currentEnabled and string.format('%d,%d,%d', sr, sg, sb) or 'off'
                        local valueLabel = 'Tắt'
                        for _, ts in pairs(Config.tyreSmokeColors) do
                            if ts.value == newValue then valueLabel = ts.label break end
                        end
                        if valueLabel == 'Tắt' and currentEnabled then
                            valueLabel = string.format('RGB(%d,%d,%d)', sr, sg, sb)
                        end
                        modsList[#modsList + 1] = {
                            isPaint = true,
                            id = 'tyresmoke',
                            value = newValue,
                            idLabel = pv.label,
                            valueLabel = valueLabel
                        }
                    end
                    goto continue
                end
                local hasCustomColor = false
                local customR, customG, customB = 0, 0, 0
                local valueLabel = getColorLabel(currentMods[pv.modsId])
                
                -- Check if this paint category has custom color from our tracking
                if pv.value == 'primary' and customColorsApplied['primary'] then
                    hasCustomColor = true
                    customR = customColorsApplied['primary'].r
                    customG = customColorsApplied['primary'].g
                    customB = customColorsApplied['primary'].b
                    valueLabel = string.format('Custom RGB(%d,%d,%d)', customR, customG, customB)
                elseif pv.value == 'secoundary' and customColorsApplied['secoundary'] then
                    hasCustomColor = true
                    customR = customColorsApplied['secoundary'].r
                    customG = customColorsApplied['secoundary'].g
                    customB = customColorsApplied['secoundary'].b
                    valueLabel = string.format('Custom RGB(%d,%d,%d)', customR, customG, customB)
                end
                
                -- Save to mods list ONLY if category was modified in this session
                if modifiedCategories[pv.value] then
                    local modData = {
                        isPaint = true,
                        id = pv.value,
                        value = currentMods[pv.modsId],
                        idLabel = pv.label,
                        valueLabel = valueLabel
                    }
                    
                    -- Add custom color data if present
                    if hasCustomColor then
                        modData.isCustomColor = true
                        modData.customR = customR
                        modData.customG = customG
                        modData.customB = customB
                    end
                    
                    modsList[#modsList + 1] = modData
                end
                
                ::continue::
            end
            
            -- Handle wheel colors (pearl and wheels) separately
            local currentPearl, currentWheels = GetVehicleExtraColours(veh)
            if modifiedCategories['pearl'] then
                local pearlLabel = getColorLabel(currentPearl) or string.format("Color %d", currentPearl)
                modsList[#modsList + 1] = {
                    isPaint = true,
                    id = 'pearl',
                    value = currentPearl,
                    idLabel = 'Pearl Color',
                    valueLabel = pearlLabel
                }
            end
            
        elseif cv.value == 'windowTint' then
            if currentMods.windowTint ~= defaultMods.windowTint then
                for wp, wv in pairs(Config.windowTint) do
                    if currentMods.windowTint == wv.value then
                        modsList[#modsList + 1] = {
                            id = 'windowTint',
                            value = currentMods.windowTint,
                            idLabel = cv.label,
                            valueLabel = wv.label
                        }
                    end
                end
            end
        elseif cv.value == 'plates' then
            if currentMods.plateIndex ~= defaultMods.plateIndex then
                for pk, pv in pairs(Config.plates) do
                    if pv.value == currentMods.plateIndex then
                        modsList[#modsList + 1] = {
                            id = 'plates',
                            value = currentMods.plateIndex,
                            idLabel = cv.label,
                            valueLabel = pv.label
                        }
                    end
                end
            end
        elseif cv.value == 'livery' then
            local value = currentMods[cv.modsId]
            if value ~= defaultMods[cv.modsId] then
                if GetVehicleLiveryCount(veh) > 0 then
                    local label = 'Stock'
                    if value > -1 then
                        local liveryName = GetLiveryName(veh, value)
                        local modLabel = liveryName and GetLabelText(liveryName)
                        label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (value + 1)) or string.format("%s - %s", (value + 1), modLabel)
                    end
                    modsList[#modsList + 1] = {
                        wheelType = false,
                        id = cv.value,
                        value = value,
                        idLabel = cv.label,
                        valueLabel = label
                    }
                end
            end
        elseif cv.value == 14 then
            if currentMods.modHorns ~= defaultMods.modHorns then
                for hk, hv in pairs(Config.horns) do
                    if hv.value == currentMods.modHorns then
                        modsList[#modsList + 1] = {
                            id = 14,
                            value = currentMods.modHorns,
                            idLabel = cv.label,
                            valueLabel = hv.label
                        }
                    end
                end
            end
        else
            local value = currentMods[cv.modsId]
            if (value ~= defaultMods[cv.modsId]) then
                if (cv.value == 23 or cv.value == 24) and (modifiedCategories['wheels'] or modifiedCategories['pearl']) then
                    goto skipWheelMod
                end
                
                if GetNumVehicleMods(veh, cv.value) > 0 then
                    local label = 'Stock'
                    if value > -1 then
                        local modLabelText = GetModTextLabel(veh, cv.value, value)
                        local modLabel = modLabelText and GetLabelText(modLabelText)
                        label = (modLabel == "NULL" or modLabel == nil) and (locale('ui_custom') .. ' ' .. (value + 1)) or string.format("%s - %s", (value + 1), modLabel)
                    end
                    modsList[#modsList + 1] = {
                        wheelType = (cv.value == 23 or cv.value == 24) and (IsThisModelABike(GetEntityModel(veh)) and 6 or GetVehicleWheelType(veh)) or false,
                        id = cv.value,
                        value = value,
                        idLabel = cv.label,
                        valueLabel = label
                    }
                end
            end
            ::skipWheelMod::
        end
    end

    -- 100% RESTORE VEHICLE TO ORIGINAL STATE (PREVENT EXPLOIT)
    restorePreviewVehicle(veh, defaultMods)
    previewVehicleDamage = nil
    previewDefaultMods = nil
    previewVehicle = nil
    
    if not (#modsList > 0) then
        customColorsApplied = {}
        modifiedCategories = {}
        return
    end

    Player(cache.serverId).state:set('workshopCurrentVehicle', VehToNet(veh), true)
    lib.callback.await('mt_workshops:server:addItem', false, 'mods_list', 1, { plate = currentMods.plate, modsList = modsList })
    Player(cache.serverId).state:set('workshopCurrentVehicle', nil, true)
    
    -- Notify about custom colors if any were saved
    local hasCustomColors = false
    for _, mod in pairs(modsList) do
        if mod.isCustomColor then
            hasCustomColors = true
            break
        end
    end
    if hasCustomColors then
        notify(locale('notify_custom_color_saved'), 'success')
    end
    
    customColorsApplied = {} -- Clear custom colors tracking
    modifiedCategories = {} -- Clear modified categories tracking
end

RegisterNuiCallback('finishPreview', function(data, cb)
    finishPreview()
    cb(true)
end)

RegisterNuiCallback('cancelPreview', function(data, cb)
    if not inPreview or not previewVehicle or not previewDefaultMods then cb(true) return end
    local veh = previewVehicle
    local defaultMods = previewDefaultMods

    inPreview = false
    ShowNUI('setVisiblePreviewMenu', false)
    TriggerServerEvent('mt_workshops:server:endPreview', VehToNet(veh))
    
    restorePreviewVehicle(veh, defaultMods)
    previewVehicleDamage = nil
    previewDefaultMods = nil
    previewVehicle = nil
    customColorsApplied = {}
    modifiedCategories = {}
    cb(true)
end)

CreateThread(function()
    while true do
        if inPreview then
            DisableControlAction(0, 75, true)
            Wait(5)
        else
            Wait(1000)
        end
    end
end)

-- Cleanup function for unexpected disconnections/restarts/exits
local cleanupPreview = function()
    if not inPreview or not previewVehicle or not previewDefaultMods then return end
    
    local veh = previewVehicle
    local defaultMods = previewDefaultMods
    
    inPreview = false
    previewVehicle = nil
    previewDefaultMods = nil
    customColorsApplied = {}
    modifiedCategories = {}
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "setVisiblePreviewMenu",
        data = false
    })
    
    if DoesEntityExist(veh) then
        TriggerServerEvent('mt_workshops:server:endPreview', VehToNet(veh))
        restorePreviewVehicle(veh, defaultMods)
    end
    previewVehicleDamage = nil
end

exports('isInPreview', function()
    return inPreview
end)

exports('cleanupPreview', cleanupPreview)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if inPreview then 
        cleanupPreview()
    end
end)

-- Handle ESX player unload
RegisterNetEvent('esx:onPlayerLogout', function()
    if inPreview then 
        cleanupPreview()
    end
end)

-- Handle QBX player unload  
RegisterNetEvent('qbx_core:client:OnPlayerUnload', function()
    if inPreview then 
        cleanupPreview()
    end
end)

RegisterNetEvent('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and inPreview then
        cleanupPreview()
    end
end)

-- Additional safety check for player dropping
AddEventHandler('playerDropped', function()
    if inPreview then
        cleanupPreview()
    end
end)

-- Handle cleanup requests from server
RegisterNetEvent('mt_workshops:client:cleanupPreviewForPlayer', function(droppedPlayerId)
    if inPreview then
        cleanupPreview()
    end
end)

RegisterNetEvent('mt_workshops:client:forceCleanupPreview', function()
    if inPreview then
        cleanupPreview()
    end
end)

lib.onCache('vehicle', function(value)
    if inPreview and (cache.vehicle ~= value) then 
        cleanupPreview() 
    end
end)

-- Server-side cleanup helper when player disconnects during preview
RegisterNetEvent('mt_workshops:client:restoreVehicleFromPreview')
AddEventHandler('mt_workshops:client:restoreVehicleFromPreview', function(vehicleNetId, originalState, disconnectedPlayer)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        if originalState then
            restorePreviewVehicle(vehicle, originalState)
        end
        if inPreview and (previewVehicle == vehicle or GetVehiclePedIsIn(PlayerPedId(), false) == vehicle) then
            inPreview = false
            previewVehicle = nil
            previewDefaultMods = nil
            customColorsApplied = {}
            modifiedCategories = {}
            
            SetNuiFocus(false, false)
            SendNUIMessage({
                action = "setVisiblePreviewMenu",
                data = false
            })
        end
    end
end)