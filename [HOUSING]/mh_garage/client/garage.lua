if not lib then return end

local Edit = require 'edit_functions'
local GaragesData = lib.load 'config.garages'
local General = lib.load 'config.general'
local Interior = lib.load 'config.interior'
local ScaleForm = require 'client.carscaleform'
local TempVehicle = {}
local Garage = {}
local hasTextUI, CurrentGarageName, inPreview, InvitedPlayer
local CurrentFloor = 'exit'
local lastMenuTime = 0
local isProcessingTakeout = false -- Anti-spam flag for vehicle takeout
local lastTakeoutAction = 0 -- Timestamp of last takeout
local CLIENT_TAKEOUT_COOLDOWN = 10000 -- 10 seconds (matches server)

lib.locale()

local function format_number(n)
    local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return formatted:gsub("^,", "")
end


local function AwaitFadeIn()
    while IsScreenFadingIn() do
        Wait(200)
    end
end


local function AwaitFadeOut()
    while IsScreenFadingOut() do
        Wait(200)
    end
end


function Garage.DeleteVehicles()
    for i = 1, #TempVehicle do
        if DoesEntityExist(TempVehicle[i]) then
            DeleteEntity(TempVehicle[i])
        end
    end

    TempVehicle = {}

    if General.VehicleScaleFormInfo then
        ScaleForm.HideVehicleStatus()
    end
end

function Garage.CreateOwnedVehicles(name, interior)
    ----print('^4[GARAGE]^7 CreateOwnedVehicles called | Garage: ' .. tostring(name) .. ' | Interior: ' .. tostring(interior) .. ' | CurrentFloor: ' .. tostring(CurrentFloor))
    
    -- Increase timeout to 5 seconds to handle slow database queries
    local vehicles, slots = lib.callback.await('mh_garage:cb:GetGarageVehicles', 5000, name, CurrentFloor)

    if not vehicles or not slots then 
        ----print('^1[GARAGE DEBUG]^7 Failed to get vehicles or slots for garage:', name)
        ----print('^1[GARAGE DEBUG]^7 Vehicles:', tostring(vehicles), '| Slots:', tostring(slots))
        return 
    end
    
    -- SAFETY CHECK: Validate Interior configuration
    if not Interior[interior] then
        ----print('^1[GARAGE ERROR]^7 Interior configuration not found for:', interior)
        return
    end
    
    if not Interior[interior].Vehicles then
        ----print('^1[GARAGE ERROR]^7 Vehicles configuration not found in interior:', interior)
        return
    end
    
    if not Interior[interior].Vehicles[CurrentFloor] then
        ----print('^1[GARAGE ERROR]^7 Floor ' .. tostring(CurrentFloor) .. ' not found in interior:', interior)
        return
    end

    -- Count vehicles manually
    local vehicleCount = 0
    for _ in pairs(vehicles) do
        vehicleCount = vehicleCount + 1
    end

    ----print('^2[GARAGE DEBUG]^7 Creating vehicles for garage:', name, '| Floor:', CurrentFloor, '| Slots:', #slots, '| Vehicles:', vehicleCount)

    -- Always delete old vehicles first
    Garage.DeleteVehicles()
    Wait(100) -- Small wait for cleanup

    local spawnedCount = 0
    local failedCount = 0

    for id, plate in pairs(slots) do
        if plate and vehicles[plate] then
            local cleanPlate = string.strtrim(plate)
            
            if IsModelInCdimage(vehicles[cleanPlate].model) then
                -- SAFETY CHECK: Ensure coords exist for this slot
                local coords = Interior[interior].Vehicles[CurrentFloor] and Interior[interior].Vehicles[CurrentFloor][id]
                if coords then
                    local model = lib.requestModel(vehicles[cleanPlate].model)
                    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)

                    if DoesEntityExist(vehicle) then
                        for _ = 1, 10 do
                            SetVehicleOnGroundProperly(vehicle)
                            Wait(0)
                        end

                        lib.setVehicleProperties(vehicle, vehicles[cleanPlate])
                        
                        -- Restore fuel level for garage display vehicles
                        local fuelLevel = vehicles[cleanPlate].fuelLevel or 100.0
                        Edit.SetFuel(vehicle, fuelLevel)
                        
                        Edit.GiveCarKey(vehicle, cleanPlate)

                        TempVehicle[#TempVehicle + 1] = vehicle
                        spawnedCount = spawnedCount + 1
                        
                        ----print('^2[GARAGE DEBUG]^7 Spawned vehicle:', cleanPlate, '| Model:', vehicles[cleanPlate].model, '| Slot:', id)
                    else
                        failedCount = failedCount + 1
                        ----print('^1[GARAGE DEBUG]^7 Failed to create vehicle entity:', cleanPlate)
                    end
                else
                    failedCount = failedCount + 1
                    ----print('^3[GARAGE DEBUG]^7 No coords for slot:', id)
                end
            else
                failedCount = failedCount + 1
                ----print('^3[GARAGE DEBUG]^7 Model not in CD image:', vehicles[cleanPlate].model, '| Plate:', cleanPlate)
            end
        end
    end

    ----print('^2[GARAGE DEBUG]^7 Vehicle spawn complete | Spawned:', spawnedCount, '| Failed:', failedCount, '| Total in array:', #TempVehicle)

    if #TempVehicle > 0 then
        if General.VehicleScaleFormInfo then
            ScaleForm.VehicleStatus(TempVehicle)
        end
    end
end

-- Verification thread to ensure vehicles are always spawned in garage
local verificationThread = nil

function Garage.StartVehicleVerification(name, interior)
    -- Stop existing verification thread
    if verificationThread then
        verificationThread = nil
    end
    
    verificationThread = true
    
    CreateThread(function()
        Wait(5000) -- Wait 5 seconds before starting verification (let initial spawn complete)
        
        while verificationThread do
            Wait(5000) -- Check every 5 seconds (reduced frequency)
            
            -- Only verify if we're in a garage
            if CurrentGarageName == name then
                local vehicles, slots = lib.callback.await('mh_garage:cb:GetGarageVehicles', 5000, name, CurrentFloor)
                
                if vehicles and slots then
                    -- Count how many vehicles should exist
                    local expectedCount = 0
                    for id, plate in pairs(slots) do
                        if plate and vehicles[plate] then
                            expectedCount = expectedCount + 1
                        end
                    end
                    
                    -- Count actually spawned vehicles
                    local actualCount = 0
                    for i = 1, #TempVehicle do
                        if DoesEntityExist(TempVehicle[i]) then
                            actualCount = actualCount + 1
                        end
                    end
                    
                    -- Only respawn if there's a significant mismatch and we have vehicles to spawn
                    if actualCount < expectedCount and expectedCount > 0 then
                        ----print('^3[GARAGE VERIFY]^7 Vehicle count mismatch! Expected:', expectedCount, '| Actual:', actualCount, '| Respawning...')
                        Garage.CreateOwnedVehicles(name, interior)
                        Wait(3000) -- Wait 3 seconds after respawn before next check
                    end
                else
                    -- If callback fails, don't spam - just wait longer
                    ----print('^3[GARAGE VERIFY]^7 Failed to get data, will retry in 10 seconds...')
                    Wait(10000)
                end
            else
                -- Exit garage, stop verification
                verificationThread = nil
                break
            end
        end
    end)
end

function Garage.StopVehicleVerification()
    verificationThread = nil
end


-- Function to show vehicle selection menu for fixing
function Garage.ShowFixVehicleMenu(garageName)
    -- Get vehicles from garage
    local vehicles = lib.callback.await('mh_garage:cb:GetFixableVehicles', false, garageName)
    
    if not vehicles or #vehicles == 0 then
        Edit.Notify(locale('no_vehicles_to_fix'), 'error')
        return
    end
    
    local options = {}
    
    -- Add fix all option
    table.insert(options, {
        title = locale("fix_all_vehicles"),
        description = locale("fix_all_vehicles_description"),
        icon = 'fas fa-wrench',
        onSelect = function()
            Garage.FixGarageIssues(garageName)
        end
    })
    
    -- Add separator
    table.insert(options, {
        title = "─────────────────",
        disabled = true
    })
    
    -- Add individual vehicles
    for i, vehicle in ipairs(vehicles) do
        local vehicleName = vehicle.name or vehicle.model or 'Unknown'
        local plate = vehicle.plate or 'Unknown'
        local description = "Model: " .. (vehicle.model or 'Unknown')
        local icon = 'fas fa-car'
        
        -- Special handling for missing vehicles
        if vehicle.missing then
            vehicleName = vehicle.name -- Already formatted as "Missing Vehicle (plate)"
            description = "⚠️ Vehicle in garage slot but not in database"
            icon = 'fas fa-exclamation-triangle'
        end
        
        table.insert(options, {
            title = locale("vehicle_info", vehicleName, plate),
            description = description,
            icon = icon,
            onSelect = function()
                if vehicle.missing then
                    -- Special handling for missing vehicles
                    Garage.FixMissingVehicle(garageName, vehicle)
                else
                    Garage.FixSpecificVehicle(garageName, vehicle)
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'mh_garage:fix_vehicle_select',
        title = locale('select_vehicle_to_fix'),
        options = options
    })
    
    lib.showContext('mh_garage:fix_vehicle_select')
end

-- Function to fix specific vehicle
function Garage.FixSpecificVehicle(garageName, vehicle)
    local vehicleName = vehicle.name or vehicle.model or 'Unknown'
    local plate = vehicle.plate or 'Unknown'
    
    local alert = lib.alertDialog({
        header = locale('fix_vehicle_confirm', vehicleName),
        content = locale('fix_vehicle_confirm_content', vehicleName, plate),
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        local result = lib.callback.await('mh_garage:cb:FixSpecificVehicle', false, garageName, vehicle.plate)
        
        if result and result.success then
            Edit.Notify(locale('fix_vehicle_success', vehicleName), 'success')
            
            -- ALWAYS force refresh garage after successful fix
            Wait(500)
            
            -- Force refresh garage to show the fixed vehicle
            if CurrentGarageName == garageName then
                Garage.DeleteVehicles() -- Clear current display
                
                -- Get fresh data and recreate vehicles
                local vehicles, slots = lib.callback.await('mh_garage:cb:GetGarageVehicles', false, garageName, CurrentFloor)
                if vehicles and next(vehicles) then
                    Garage.CreateVehicles(vehicles, slots)
                    Edit.Notify('Xe đã được fix và hiển thị trong garage', 'success')
                else
                    Edit.Notify('Không tìm thấy xe sau khi fix', 'error')
                end
            end
        else
            Edit.Notify(locale('fix_vehicle_failed', result.error or 'Unknown error'), 'error')
        end
    end
end

-- Function to fix missing vehicle (in garage slot but not in database)
function Garage.FixMissingVehicle(garageName, vehicle)
    local plate = vehicle.plate or 'Unknown'
    
    local alert = lib.alertDialog({
        header = 'Fix Missing Vehicle',
        content = 'Vehicle "' .. plate .. '" is in garage slots but missing from database.\n\nThis will remove it from garage slots.\n\nContinue?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        local result = lib.callback.await('mh_garage:cb:FixMissingVehicle', false, garageName, plate)
        
        if result and result.success then
            Edit.Notify('Successfully removed missing vehicle: ' .. plate, 'success')
        else
            Edit.Notify('Error fixing missing vehicle: ' .. (result.error or 'Unknown error'), 'error')
        end
    end
end

function Garage.FixGarageIssues(garageName)
    -- Show confirmation dialog
    local alert = lib.alertDialog({
        header = locale('fix_garage_confirm_title'),
        content = locale('fix_garage_confirm_content'),
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        -- Trigger server-side garage fix
        local result = lib.callback.await('mh_garage:cb:FixPlayerGarage', 5000, garageName)
        
        if result.success then
            Edit.Notify(locale('fix_garage_success', result.fixed), 'success')
            if result.details and #result.details > 0 then
                -- Show detailed results
                for i, detail in ipairs(result.details) do
                    if i <= 3 then -- Show first 3 details
                        Edit.Notify(detail, 'info')
                    end
                end
                if #result.details > 3 then
                    Edit.Notify(locale('fix_garage_more_details', #result.details - 3), 'info')
                end
            end
            
            -- ALWAYS force refresh garage after successful fix  
            if result.fixed > 0 then
                Wait(500)
                
                -- Force refresh garage to show fixed vehicles
                if CurrentGarageName == garageName then
                    Garage.DeleteVehicles() -- Clear current display
                    
                    -- Get fresh data and recreate vehicles
                    local vehicles, slots = lib.callback.await('mh_garage:cb:GetGarageVehicles', false, garageName, CurrentFloor)
                    if vehicles and next(vehicles) then
                        Garage.CreateVehicles(vehicles, slots)
                        Edit.Notify('Tất cả xe đã được fix và hiển thị trong garage', 'success')
                    else
                        Edit.Notify('Không tìm thấy xe sau khi fix all', 'error')
                    end
                end
            end
        else
            Edit.Notify(locale('fix_garage_failed', result.error or 'Unknown error'), 'error')
        end
    end
end


function Garage.EnterGarage(name, interior)
    if not GaragesData[name] then return end
    if not Interior[interior] then return end

    if not IsIplActive(Interior[interior].ipl) then
        RequestIpl(Interior[interior].ipl)
    end

    if #Interior[interior].Vehicles > 1 then
        local options = {}

        for i = 1, #Interior[interior].Vehicles do
            options[i] = { label = locale("floor_label", i), value = i }
        end

        local floor = lib.inputDialog(locale("choose_floor"), {{ type = 'select', label = locale("choose_floor"), options = options, required = true }})
        if not floor then return end

        CurrentFloor = floor[1]
    else
        CurrentFloor = 1
    end

    CurrentGarageName = name
    Garage.CreateFloor(name, interior)
end

-- Enter garage with specific floor (for NUI)
function Garage.EnterGarageWithFloor(name, interior, floor)
    if not GaragesData[name] then return end
    if not Interior[interior] then return end

    if not IsIplActive(Interior[interior].ipl) then
        RequestIpl(Interior[interior].ipl)
    end

    CurrentFloor = floor or 1
    CurrentGarageName = name
    Garage.CreateFloor(name, interior)
end


function Garage.OpenGarageMenu(name, interior)
    if not GaragesData[name] then return end
    if not Interior[interior] then return end
    
    -- Prevent multiple menu openings using timestamp
    local currentTime = GetGameTimer()
    if currentTime - lastMenuTime < 1000 then -- 1 second cooldown
        ----print('^1[GARAGE MENU DEBUG]^7 Menu cooldown active, ignoring request')
        return
    end
    lastMenuTime = currentTime
    ----print('^2[GARAGE MENU DEBUG]^7 Opening menu for:', name)

    local doesOwn = lib.callback.await('mh_garage:cb:DoesOwn', false, name)
    local menu = {
        id = 'mh_garage:main',
        title = name,
        options = doesOwn and {
            { title = locale("enter_garage_menu"), arrow = true, onSelect = function() 
                Garage.EnterGarage(name, interior) 
            end },
            { title = locale("fix_specific_vehicle"), description = locale("fix_specific_vehicle_description"), arrow = true, onSelect = function() 
                Garage.ShowFixVehicleMenu(name) 
            end },
            -- { title = locale("sell_garage"), arrow = true } TODO
        } or {
            { title = locale("preview_garage"), arrow = true, onSelect = function() 
                Garage.PreviewGarage(name, interior) 
            end },
            {
                title = locale("buy_garage"),
                description = locale("buy_garage_description", format_number(GaragesData[name].price)),
                arrow = true,
                metadata = { GaragesData[name].GarageInfo },
                onSelect = function()
                    TriggerServerEvent('mh_garage:server:BuyGarage', name, interior)
                end
            }
        }
    }

    lib.registerContext(menu)
    lib.showContext(menu.id)
end

function Garage.GeneratePreviewCar(name, interior)
    if not GaragesData[name] then return end
    if not Interior[interior] then return end

    for i = 1, #Interior[interior].Vehicles[1] do
        local model = joaat(General.PreviewModels[GaragesData[name].type][math.random(#General.PreviewModels[GaragesData[name].type])])

        if IsModelInCdimage(model) then
            lib.requestModel(model)
            local coords = Interior[interior].Vehicles[1][i]
            local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, false, false)

            for _ = 1, 10 do
                SetVehicleOnGroundProperly(vehicle)
                Wait(0)
            end

            SetEntityInvincible(vehicle, true)
            -- SetVehicleDoorsLocked(vehicle, 2)

            TempVehicle[#TempVehicle + 1] = vehicle
        end
    end
end


function Garage.CreateCustmozations(name, interior)
    local GarageStyle = lib.callback.await('mh_garage:cb:GetStyle', 100, name, CurrentFloor)

    if table.type(GarageStyle) == 'empty' then return end

    if Interior[interior].Customization.DeactivateInterior then
        Interior[interior].Customization.DeactivateInterior()
    end

    for _, customization in pairs(GarageStyle) do
        if not IsInteriorEntitySetActive(Interior[interior].interiorId, customization.name) then
            ActivateInteriorEntitySet(Interior[interior].interiorId, customization.name)
        end

        if customization.color then
            SetInteriorEntitySetColor(Interior[interior].interiorId, customization.name, customization.color)
        end
    end

    RefreshInterior(Interior[interior].interiorId)
end

function Garage.CreateFloor(name, interior)
    if not GaragesData[name] then return end
    if not Interior[interior] then return end
    
    -- CRITICAL FIX: Ensure CurrentFloor is valid before proceeding
    -- If CurrentFloor is 'exit' or invalid, reset to 1
    if CurrentFloor == 'exit' or CurrentFloor == nil or type(CurrentFloor) ~= 'number' then
        ----print('^3[GARAGE FIX]^7 CurrentFloor was invalid (' .. tostring(CurrentFloor) .. '), resetting to 1')
        CurrentFloor = 1
    end
    
    -- Validate that the floor exists in Interior configuration
    if not Interior[interior].Vehicles or not Interior[interior].Vehicles[CurrentFloor] then
        ----print('^1[GARAGE ERROR]^7 Floor ' .. tostring(CurrentFloor) .. ' not found in interior: ' .. interior .. ', resetting to 1')
        CurrentFloor = 1
    end

    TriggerServerEvent('mh_garage:server:EnterGarage', name, CurrentFloor, false)

    -- Longer fade out to give more time for loading
    DoScreenFadeOut(1500)
    AwaitFadeOut()

    Garage.DeleteVehicles()
    Wait(800) -- Longer wait for vehicle cleanup
    Garage.CreateCustmozations(name, interior)
    Wait(600) -- Longer wait for interior setup

    local coords = Interior[interior].insideSpawn
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, coords.w)

    lib.waitFor(function()
        if HasCollisionLoadedAroundEntity(cache.ped) == true then
            return true
        end
    end, 8000) -- Increase timeout to 8 seconds

    Wait(500) -- Additional wait for stability
    
    -- CRITICAL: Load vehicles BEFORE fading in to ensure player sees them immediately
    -- Try multiple times to ensure vehicles are loaded
    local maxRetries = 5 -- Increased to 5 attempts
    local vehiclesLoaded = false
    
    for attempt = 1, maxRetries do
        Garage.CreateOwnedVehicles(name, interior)
        Wait(600) -- Longer wait for vehicles to spawn (increased from 300ms)
        
        -- Check if vehicles were created
        if #TempVehicle > 0 then
            vehiclesLoaded = true
            ----print('^2[GARAGE ENTER]^7 Vehicles loaded successfully on attempt ' .. attempt .. ' | Count: ' .. #TempVehicle)
            break
        else
            if attempt < maxRetries then
                ----print('^3[GARAGE ENTER]^7 No vehicles loaded on attempt ' .. attempt .. ', retrying...')
                Garage.DeleteVehicles() -- Clean up before retry
                Wait(600) -- Longer wait between retries
            end
        end
    end
    
    if not vehiclesLoaded then
        ----print('^3[GARAGE ENTER]^7 No vehicles found after ' .. maxRetries .. ' attempts (garage may be empty)')
    end
    
    -- Extra wait to ensure everything is stable
    Wait(400)
    
    -- Now fade in - vehicles should already be visible
    DoScreenFadeIn(800)
    AwaitFadeIn()
    
    -- DISABLED: Verification thread causes database spam (4 queries/sec with 20 players)
    -- Since all bugs are fixed, this is no longer needed
    -- Garage.StartVehicleVerification(name, interior)
    ----print('^2[GARAGE DEBUG]^7 Started vehicle verification thread for:', name)
end


function Garage.ExitGarage()
    if not GaragesData[CurrentGarageName] then return end
    if not Interior[GaragesData[CurrentGarageName].interior] then return end

    local options = {}

    if #Interior[GaragesData[CurrentGarageName].interior].Vehicles > 1 and not inPreview and not InvitedPlayer then
        for i = 1, #Interior[GaragesData[CurrentGarageName].interior].Vehicles do
            options[i] = { label = locale("floor_label", i), value = i }
        end

        options[#options + 1] = { label = locale("exit"), value = "exit" }

        local floor = lib.inputDialog('', { { type = 'select', label = locale("choose"), options = options, required = true } })
        if not floor then return end

        CurrentFloor = floor[1]
    else
        CurrentFloor = 'exit'
    end

    if CurrentFloor == 'exit' then
        local coords = GaragesData[CurrentGarageName].enter

        -- Stop vehicle verification thread
        Garage.StopVehicleVerification()
        ----print('^3[GARAGE DEBUG]^7 Stopped vehicle verification thread')

        DoScreenFadeOut(750)
        AwaitFadeOut()

        Wait(300) -- Wait before teleporting
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)

        lib.waitFor(function()
            if HasCollisionLoadedAroundEntity(cache.ped) == true then
                return true
            end
        end, 5000) -- Increase timeout to 5 seconds

        Wait(200) -- Additional wait for stability
        DoScreenFadeIn(500)

        AwaitFadeIn()
        Garage.DeleteVehicles()
        TriggerServerEvent('mh_garage:server:ExitGarage')

        if inPreview then
            inPreview = nil
            if Interior[GaragesData[CurrentGarageName].interior].Customization and Interior[GaragesData[CurrentGarageName].interior].Customization.DeactivateInterior then
                Interior[GaragesData[CurrentGarageName].interior].Customization.DeactivateInterior()
            end
        end

        if InvitedPlayer then
            InvitedPlayer = nil
        end

        CurrentGarageName = nil
        Edit.OnExitGarage()
    else
        -- Switching floors, stop verification and restart with new floor
        -- Ensure CurrentFloor is a valid number before proceeding
        if type(CurrentFloor) ~= 'number' or CurrentFloor < 1 then
            ----print('^1[GARAGE ERROR]^7 Invalid floor selected: ' .. tostring(CurrentFloor) .. ', defaulting to 1')
            CurrentFloor = 1
        end
        
        Garage.StopVehicleVerification()
        Garage.CreateFloor(CurrentGarageName, GaragesData[CurrentGarageName].interior)
    end
end


function Garage.NearbyExit(point)
    ---@diagnostic disable-next-line: param-type-mismatch
    DrawMarker(General.Markers.Exit.id, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, General.Markers.Exit.scaleX, General.Markers.Exit.scaleY, General.Markers.Exit.scaleZ, General.Markers.Exit.red, General.Markers.Exit.green, General.Markers.Exit.blue, 222, false, false, 0, true, false, false, false)

    if point.isClosest and point.currentDistance < 1.2 then
        if not hasTextUI then
            hasTextUI = point
            lib.showTextUI(locale('exit_garage'))
        end

        if IsControlJustReleased(0, 38) then
            Garage.ExitGarage()
            hasTextUI = nil
            lib.hideTextUI()
        end
    elseif hasTextUI == point then
        hasTextUI = nil
        lib.hideTextUI()
    end
end


local PreviousSelected = nil
local OriginalStyle = nil

function Garage.CreateCutomizationMenu(garage, interior)
    if not GaragesData[garage] then return end
    if not Interior[interior] then return end

    if InvitedPlayer then
        Edit.Notify(locale('not_your_garage'), 'error')
        return
    end

    -- Store original style at the beginning
    OriginalStyle = lib.callback.await('mh_garage:cb:GetStyle', 100, garage, CurrentFloor)

    local options = {}

    for name, style in pairs(Interior[interior].Customization.Purchasable) do
        options[#options + 1] = { label = name, args = { style = name }, description = locale('total_options', #style) }
    end

    lib.registerMenu({
        id = 'mh_garage:customization',
        title = locale('customization'),
        position = 'top-right',
        options = options,
    }, function (selected, scrollIndex, args, checked)
        if Interior[interior].Customization.Purchasable[args.style] then
            options = {}

            for numb, data in pairs(Interior[interior].Customization.Purchasable[args.style]) do
                options[#options + 1] = {
                    label = data.label,
                    description = locale('price', data.price),
                    args = {
                        label = data.label,
                        name = data.name,
                        color = data.color or nil,
                        type = data.type
                    }
                }
            end

            PreviousSelected = options[1].args.style

            lib.registerMenu({
                id = 'mh_garage:customization:sub',
                title = args.style,
                position = 'top-right',
                options = options,
                onSelected = function(selected2, secondary2, args2)
                    if PreviousSelected then
                        if IsInteriorEntitySetActive(Interior[interior].interiorId, PreviousSelected) then
                            DeactivateInteriorEntitySet(Interior[interior].interiorId, PreviousSelected)
                        end
                    end

                    if args2.color then
                        if not IsInteriorEntitySetActive(Interior[interior].interiorId, args2.name) then
                            ActivateInteriorEntitySet(Interior[interior].interiorId, args2.name)
                        end

                        SetInteriorEntitySetColor(Interior[interior].interiorId, args2.name, args2.color)
                    else
                        if not IsInteriorEntitySetActive(Interior[interior].interiorId, args2.name) then
                            ActivateInteriorEntitySet(Interior[interior].interiorId, args2.name)
                        end
                    end

                    PreviousSelected = args2.name
                    RefreshInterior(Interior[interior].interiorId)
                end,
                onClose = function(keyPressed2)
                    if inPreview then return end
                    -- Always restore original garage style when closing menu
                    Garage.CreateCustmozations(garage, interior)
                end,
            }, function (selected2, scrollIndex2, args2, checked2)
                if inPreview then return end

                local cb = lib.callback.await('mh_garage:cb:BuyCustomization', 100, {
                    garage = garage,
                    floor = CurrentFloor,
                    interior = args2,
                    int = interior,
                    color = args2.color or nil
                })

                -- Always restore to current saved style from database after purchase attempt
                Garage.CreateCustmozations(garage, interior)
            end)

            lib.showMenu('mh_garage:customization:sub')
        end
    end)

    lib.showMenu('mh_garage:customization')
end


function Garage.NearbyCustomization(point)
    ---@diagnostic disable-next-line: param-type-mismatch
    DrawMarker(General.Markers.CustomizationMenu.id, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, General.Markers.CustomizationMenu.scaleX, General.Markers.CustomizationMenu.scaleY, General.Markers.CustomizationMenu.scaleZ, General.Markers.CustomizationMenu.red, General.Markers.CustomizationMenu.green, General.Markers.CustomizationMenu.blue, 222, false, false, 0, true, false, false, false)

    if point.isClosest and point.currentDistance < 1.2 then
        if not hasTextUI then
            hasTextUI = point
            lib.showTextUI(locale('open_customization'))
        end

        if IsControlJustReleased(0, 38) then
            Garage.CreateCutomizationMenu(point.garage, point.interior)
            hasTextUI = nil
            lib.hideTextUI()
        end
    elseif hasTextUI == point then
        hasTextUI = nil
        lib.hideTextUI()
    end
end


function Garage.PreviewGarage(name, interior)
    if not GaragesData[name] then return end
    if not Interior[interior] then return end

    if not IsIplActive(Interior[interior].ipl) then
        RequestIpl(Interior[interior].ipl)
    end

    if Interior[interior].Customization and Interior[interior].Customization.DeactivateInterior then
        Interior[interior].Customization.DeactivateInterior()
    end

    if Interior[interior].Customization and Interior[interior].Customization.LoadDefault then
        Interior[interior].Customization.LoadDefault()
    end

    DoScreenFadeOut(750)
    AwaitFadeOut()

    Wait(300) -- Wait before teleporting
    SetEntityCoords(cache.ped, Interior[interior].insideSpawn.x, Interior[interior].insideSpawn.y, Interior[interior].insideSpawn.z, false, false, false, false)

    lib.waitFor(function()
        if HasCollisionLoadedAroundEntity(cache.ped) == true then
            return true
        end
    end, 5000) -- Increase timeout to 5 seconds

    Wait(200) -- Additional wait for interior loading
    Garage.GeneratePreviewCar(name, interior)

    DoScreenFadeIn(500)
    AwaitFadeIn()
    inPreview = true
    CurrentFloor = 1
    CurrentGarageName = name
    TriggerServerEvent('mh_garage:server:EnterGarage', name, CurrentFloor, true)
end

function Garage.SetPlayerInGarage(name, floor, inpreview)
    if not GaragesData[name] then return end
    if not Interior[GaragesData[name].interior] then return end

    CurrentGarageName = name
    CurrentFloor = floor

    if inpreview then
        inPreview = true
        CurrentFloor = 'exit'

        if Interior[GaragesData[name].interior].Customization and Interior[GaragesData[name].interior].Customization.LoadDefault then
            Interior[GaragesData[name].interior].Customization.LoadDefault()
        end
    else
        Garage.CreateFloor(name, GaragesData[name].interior)
    end

    TriggerServerEvent('mh_garage:server:UpdateBucket')
end

function Garage.SpawnVehicle(mods, coords)
    if not mods then return end

    local hash = lib.requestModel(mods.model)

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, true)
	local netid = NetworkGetNetworkIdFromEntity(vehicle)
	SetVehicleHasBeenOwnedByPlayer(vehicle, true)
	SetNetworkIdCanMigrate(netid, true)
	SetVehicleNeedsToBeHotwired(vehicle, false)
	SetVehRadioStation(vehicle, 'OFF')
	SetPedIntoVehicle(cache.ped, vehicle, -1)

	lib.setVehicleProperties(vehicle, mods)
    
    -- Handle fuel level with debug logging
    local fuelLevel = mods.fuelLevel or 100.0
    ------print('^3[GARAGE SPAWN]^7 Restoring fuel level:', fuelLevel, 'for plate:', mods.plate)
    Edit.SetFuel(vehicle, fuelLevel)
    
    Edit.GiveCarKey(vehicle, mods.plate)
    TriggerServerEvent('mh_garage:server:Orphan', VehToNet(vehicle))
end

-- STEP 1: Server calls this callback to prepare client for spawn (SYNC - server waits for response)
lib.callback.register('mh_garage:cb:PrepareVehicleSpawn', function(garageName, spawnCoords)
    -- Fadeout
    DoScreenFadeOut(750)
    AwaitFadeOut()
    
    -- EXIT INTERIOR - Check if player is in garage interior
    if CurrentFloor ~= 'exit' and CurrentGarageName then
        -- Player is inside garage, need to exit
        Garage.DeleteVehicles()
        Garage.StopVehicleVerification()
        
        -- Deactivate interior customization if exists
        if GaragesData[CurrentGarageName] and GaragesData[CurrentGarageName].interior then
            local interior = GaragesData[CurrentGarageName].interior
            if Interior[interior] and Interior[interior].Customization and Interior[interior].Customization.DeactivateInterior then
                Interior[interior].Customization.DeactivateInterior()
            end
        end
        
        -- Clear garage state
        CurrentFloor = 'exit'
        CurrentGarageName = nil
        Edit.OnExitGarage()
        lib.hideTextUI()
        keybind:disable(true)
    end
    
    -- Teleport to spawn location (outside garage) - OFFSET from vehicle spawn point
    -- Player needs to be NEAR the spawn point, not AT it (to avoid collision with spawning vehicle)
    if spawnCoords then
        -- Calculate offset position: 3 meters to the left of where vehicle will spawn
        local heading = spawnCoords.w or 0.0
        local headingRad = math.rad(heading)
        -- Offset perpendicular to vehicle heading (left side)
        local offsetX = spawnCoords.x - math.cos(headingRad) * 3.0
        local offsetY = spawnCoords.y - math.sin(headingRad) * 3.0
        
        SetEntityCoords(cache.ped, offsetX, offsetY, spawnCoords.z, false, false, false, false)
        SetEntityHeading(cache.ped, heading + 90.0) -- Face towards vehicle spawn point
        
        -- Wait for collision to load (critical for proper spawn)
        local success = lib.waitFor(function()
            if HasCollisionLoadedAroundEntity(cache.ped) == true then
                return true
            end
        end, 8000) -- 8 seconds max wait
        
        if not success then
            print('^3[MH_GARAGE CLIENT]^7 Collision load timeout, proceeding anyway')
        end
    end
    
    -- Small delay to ensure everything is synced
    Wait(100)
    
    -- Return true to server indicating client is ready for vehicle spawn
    return true
end)

-- STEP 2: Server triggers this after vehicle is spawned (exit vehicle and stand near it)
RegisterNetEvent('mh_garage:client:CompleteVehicleSpawn', function(netId, plate, vehicleStats, garageName, floor, slot)
    if not netId or not plate then return end
    
    -- Wait for vehicle to exist on client
    local vehicle = NetToVeh(netId)
    local timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 100 do
        Wait(50)
        vehicle = NetToVeh(netId)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(vehicle) then
        --print('^1[MH_GARAGE CLIENT ERROR]^7 Vehicle not found from netId: ' .. netId)
        DoScreenFadeIn(500)
        return
    end
    
    -- Player was warped into vehicle by qbx.spawnVehicle, need to exit
    if IsPedInVehicle(cache.ped, vehicle, false) then
        -- Get position near driver door BEFORE exiting (for accurate positioning)
        local spawnPos = GetOffsetFromEntityInWorldCoords(vehicle, -2.0, 0.5, 0.0)
        local vehHeading = GetEntityHeading(vehicle)
        
        -- Instant exit from vehicle (no animation)
        SetEntityCoords(cache.ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
        SetEntityHeading(cache.ped, vehHeading + 90.0) -- Face towards the vehicle
    end
    
    -- FIXED: Apply vehicle stats (fuel, body, engine health) after spawn
    if vehicleStats then
        -- Apply fuel level
        if vehicleStats.fuelLevel then
            Edit.SetFuel(vehicle, vehicleStats.fuelLevel)
        end
        
        -- Apply body health (max 1000)
        if vehicleStats.bodyHealth then
            SetVehicleBodyHealth(vehicle, vehicleStats.bodyHealth)
        end
        
        -- Apply engine health (max 1000)
        if vehicleStats.engineHealth then
            SetVehicleEngineHealth(vehicle, vehicleStats.engineHealth)
        end
    end
    
    -- Give car keys
    Edit.GiveCarKey(vehicle, plate)
    
    -- Register as orphan vehicle
    TriggerServerEvent('mh_garage:server:Orphan', netId)
    
    -- CRITICAL: Confirm successful spawn to server so it can update state and remove slot
    -- This prevents vehicle loss if spawn fails or player disconnects before this point
    TriggerServerEvent('mh_garage:server:ConfirmVehicleSpawnSuccess', plate, garageName, floor, slot)
    
    -- Fadein
    DoScreenFadeIn(500)
    AwaitFadeIn()
end)

-- NUI takeout: Just give keys without teleporting player (vehicle spawns at garage spawn point)
RegisterNetEvent('mh_garage:client:GiveVehicleKeysNUI', function(netId, plate, vehicleStats)
    if not netId or not plate then return end
    
    -- Wait for vehicle to exist on client
    local vehicle = NetToVeh(netId)
    local timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 100 do
        Wait(50)
        vehicle = NetToVeh(netId)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(vehicle) then
        return
    end
    
    -- FIXED: Apply vehicle stats (fuel, body, engine health) after spawn
    if vehicleStats then
        -- Apply fuel level
        if vehicleStats.fuelLevel then
            Edit.SetFuel(vehicle, vehicleStats.fuelLevel)
        end
        
        -- Apply body health (max 1000)
        if vehicleStats.bodyHealth then
            SetVehicleBodyHealth(vehicle, vehicleStats.bodyHealth)
        end
        
        -- Apply engine health (max 1000)
        if vehicleStats.engineHealth then
            SetVehicleEngineHealth(vehicle, vehicleStats.engineHealth)
        end
    end 
    
    -- Give car keys (NO teleporting - player stays where they are)
    Edit.GiveCarKey(vehicle, plate)
    
    -- Register as orphan vehicle
    TriggerServerEvent('mh_garage:server:Orphan', netId)
end)

-- Forward declaration for keybind (used inside OpenVehicleInfoMenu)
local keybind

local function OpenVehicleInfoMenu()
    -- Get current vehicle player is sitting in
    local vehicle = cache.vehicle
    -- if not vehicle or not DoesEntityExist(vehicle) then
    --     Edit.Notify('Bạn chưa ngồi trong xe', 'error')
    --     return
    -- end
    
    local plate = string.strtrim(GetVehicleNumberPlateText(vehicle))
    local model = GetEntityModel(vehicle)
    
    -- Get vehicle display name
    local vehicleName = GetDisplayNameFromVehicleModel(model)
    local label = GetLabelText(vehicleName)
    if label == 'NULL' then
        label = vehicleName
    end
    
    -- Get vehicle stats
    local engineHealth = math.floor(GetVehicleEngineHealth(vehicle) / 10)
    local bodyHealth = math.floor(GetVehicleBodyHealth(vehicle) / 10)
    local fuelLevel = math.floor(GetVehicleFuelLevel(vehicle))
    
    -- Get vehicle class for icon
    local vehClass = GetVehicleClass(vehicle)
    local classNames = {
        [0] = 'Compact', [1] = 'Sedan', [2] = 'SUV', [3] = 'Coupe',
        [4] = 'Muscle', [5] = 'Sports Classic', [6] = 'Sports', [7] = 'Super',
        [8] = 'Motorcycle', [9] = 'Off-road', [10] = 'Industrial',
        [11] = 'Utility', [12] = 'Van', [13] = 'Cycle', [14] = 'Boat',
        [15] = 'Helicopter', [16] = 'Plane', [17] = 'Service', [18] = 'Emergency',
        [19] = 'Military', [20] = 'Commercial', [21] = 'Train', [22] = 'Open Wheel'
    }
    local className = classNames[vehClass] or 'Unknown'
    
    -- Build menu options
    local menuOptions = {
        {
            title = '📋 Thông tin xe',
            description = 'Loại: ' .. className,
            icon = 'circle-info',
            iconColor = '#60a5fa',
            disabled = true
        },
        {
            title = '🔧 Động cơ',
            description = engineHealth .. '%',
            icon = 'gear',
            iconColor = engineHealth > 50 and '#22c55e' or '#ef4444',
            progress = engineHealth,
            colorScheme = engineHealth > 50 and 'green' or 'red',
            disabled = true
        },
        {
            title = '🛡️ Thân xe',
            description = bodyHealth .. '%',
            icon = 'shield',
            iconColor = bodyHealth > 50 and '#22c55e' or '#ef4444',
            progress = bodyHealth,
            colorScheme = bodyHealth > 50 and 'green' or 'red',
            disabled = true
        },
        {
            title = '⛽ Nhiên liệu',
            description = fuelLevel .. '%',
            icon = 'gas-pump',
            iconColor = fuelLevel > 30 and '#22c55e' or '#ef4444',
            progress = fuelLevel,
            colorScheme = fuelLevel > 30 and 'green' or 'red',
            disabled = true
        },
        {
            title = '',
            disabled = true
        },
        {
            title = '🚗 Lấy xe ra',
            description = 'Đưa xe ra khỏi garage',
            icon = 'right-from-bracket',
            iconColor = '#22c55e',
            onSelect = function()
                -- Check anti-spam
                local currentTime = GetGameTimer()
                -- if isProcessingTakeout then
                --     Edit.Notify('Xe đang được xử lý, vui lòng không spam!', 'error')
                --     return
                -- end
                
                if (currentTime - lastTakeoutAction) < CLIENT_TAKEOUT_COOLDOWN then
                    local remainingTime = math.ceil((CLIENT_TAKEOUT_COOLDOWN - (currentTime - lastTakeoutAction)) / 1000)
                    Edit.Notify('Vui lòng đợi ' .. remainingTime .. ' giây...', 'error')
                    return
                end
                
                -- Mark as processing
                isProcessingTakeout = true
                lastTakeoutAction = currentTime
                
                -- Check spawn point
                local freespot = lib.callback.await('mh_garage:cb:CheckSpawnPoint', 100, CurrentGarageName)
                
                if not freespot then
                    isProcessingTakeout = false
                    return Edit.Notify(locale('no_free_spawnpoint'), 'error')
                end
                
                -- Trigger take out vehicle
                Garage.DeleteVehicles()
                TriggerServerEvent('mh_garage:server:TakeVehicleOut', CurrentGarageName, plate)
                CurrentFloor = 'exit'
                lib.hideTextUI()
                keybind:disable(true)
                
                -- Reset processing flag after timeout
                SetTimeout(CLIENT_TAKEOUT_COOLDOWN, function()
                    isProcessingTakeout = false
                end)
            end
        }
    }
    
    -- Register and show context menu
    lib.registerContext({
        id = 'garage_vehicle_info',
        title = '🚗 ' .. label .. ' | ' .. plate,
        options = menuOptions
    })
    
    lib.showContext('garage_vehicle_info')
end

keybind = lib.addKeybind({
    name = 'take_vehicle_out',
    description = locale('keybind_description'),
    defaultKey = 'E',
    onReleased = function(self)
        -- Open vehicle info menu for current vehicle
        OpenVehicleInfoMenu()
    end
})

keybind:disable(true)

lib.onCache('vehicle', function(value)
    -- Only enable keybind when:
    -- 1. Player is inside garage (CurrentFloor is a number, not 'exit')
    -- 2. Not in preview mode
    -- 3. Not an invited player
    -- 4. Currently in a garage (CurrentGarageName exists)
    -- 5. Sitting in a TempVehicle (garage display vehicle)
    
    if CurrentFloor == 'exit' or inPreview or InvitedPlayer or not CurrentGarageName then 
        keybind:disable(true)
        return 
    end

    if type(value) == "number" then
        -- Check if this vehicle is a TempVehicle (garage display vehicle)
        local isGarageVehicle = false
        for i = 1, #TempVehicle do
            if TempVehicle[i] == value then
                isGarageVehicle = true
                break
            end
        end
        
        if isGarageVehicle then
            keybind:disable(false)
            lib.showTextUI(locale('take_out'))
        else
            -- Not a garage vehicle, disable keybind (likely storing from outside)
            keybind:disable(true)
        end
    else
        keybind:disable(true)
        lib.hideTextUI()
    end
end)


lib.callback.register('mh_garage:cb:GetGarageClient', function()
    return { garage = CurrentGarageName, floor = CurrentFloor, preview = inPreview }
end)

RegisterNetEvent('mh_garage:client:InvitePlayer', function(players, data)
    local input = lib.inputDialog('', {{ type = 'select', label = locale('select_player'), options = players, required = true }})
    if not input then return end

    TriggerServerEvent('mh_garage:server:InvitePlayer', input[1], data)
end)

lib.callback.register('mh_garage:cb:SendInvite', function(name)
    return lib.alertDialog({
        header = locale('invite_title'),
        content = locale('invite_msg', name),
        centered = true,
        cancel = true,
        labels = {
            cancel = locale('decline'),
            confirm = locale('accept')
        }
    })
end)

RegisterNetEvent('mh_garage:client:TeleportPlayer', function(GarageStyle, data)
    DoScreenFadeOut(750)
    AwaitFadeOut()

    local interior = GaragesData[data.garage].interior
    local coords = Interior[interior].insideSpawn

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)

    if Interior[interior].Customization and Interior[interior].Customization.DeactivateInterior then
        Interior[interior].Customization.DeactivateInterior()
    end

    for _, customization in pairs(GarageStyle) do
        if not IsInteriorEntitySetActive(Interior[interior].interiorId, customization.name) then
            ActivateInteriorEntitySet(Interior[interior].interiorId, customization.name)
        end

        if customization.color then
            SetInteriorEntitySetColor(Interior[interior].interiorId, customization.name, customization.color)
        end
    end

    RefreshInterior(Interior[interior].interiorId)

    CurrentGarageName = data.garage
    CurrentFloor = data.floor
    InvitedPlayer = true

    DoScreenFadeIn(500)
    AwaitFadeIn()
end)

-- Event to refresh garage display after storing a vehicle
RegisterNetEvent('mh_garage:client:RefreshGarageDisplay', function(garageName)
    -- Only refresh if player is currently in this garage
    if CurrentGarageName == garageName and CurrentGarageName then
        local interior = GaragesData[garageName].interior
        
        -- Delete current vehicle display
        Garage.DeleteVehicles()
        
        -- Wait longer for database to commit and sync (CRITICAL for showing newly stored vehicles)
        Wait(600)
        
        -- Retry logic: try up to 3 times to get fresh data
        local maxRetries = 3
        local retryDelay = 400
        local success = false
        
        for attempt = 1, maxRetries do
            -- Recreate vehicles with fresh data from server
            Garage.CreateOwnedVehicles(garageName, interior)
            
            -- Wait a bit for vehicles to spawn
            Wait(200)
            
            -- Check if vehicles were actually created
            if #TempVehicle > 0 then
                success = true
                ----print('^2[GARAGE REFRESH]^7 Successfully refreshed garage display on attempt ' .. attempt .. ' | Vehicles: ' .. #TempVehicle)
                break
            else
                if attempt < maxRetries then
                    ----print('^3[GARAGE REFRESH]^7 No vehicles found on attempt ' .. attempt .. ', retrying in ' .. retryDelay .. 'ms...')
                    Garage.DeleteVehicles() -- Clean up before retry
                    Wait(retryDelay)
                end
            end
        end
        
        if not success then
            ----print('^1[GARAGE REFRESH]^7 Failed to refresh garage after ' .. maxRetries .. ' attempts')
            -- Try one final time without checking
            Garage.CreateOwnedVehicles(garageName, interior)
        end
    end
end)


AddEventHandler('onResourceStart', function(resource)
    if cache.resource == resource then
        for i = 1, #General.PreviewModels do
            local model = joaat(General.PreviewModels[i])

            if not IsModelInCdimage(model) then
                warn(('%s is not valid model or not part of your game build'):format(General.PreviewModels[i]))
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        if CurrentGarageName and InvitedPlayer then
            TriggerServerEvent('mh_garage:server:TeleportOut', CurrentGarageName)
        end

        if inPreview and CurrentGarageName then
            if Interior[GaragesData[CurrentGarageName].interior].Customization and Interior[GaragesData[CurrentGarageName].interior].Customization.DeactivateInterior then
                Interior[GaragesData[CurrentGarageName].interior].Customization.DeactivateInterior()
            end
        end

        Garage.DeleteVehicles()
        lib.hideTextUI()
    end
end)

-- ========== QBX HOUSING INTEGRATION ==========
-- Export để lấy GaragesData cho qbx_housing
exports('GetGaragesData', function()
    return GaragesData
end)

-- Export để lấy Interior data
exports('GetInteriorData', function()
    return Interior
end)

-- Export để lấy Garage module (cho qbx_housing sử dụng EnterGarage function)
exports('GetGarageModule', function()
    return Garage
end)

-- Event để sync garage từ qbx_housing
RegisterNetEvent('qbx_housing:client:SyncHouseGarage', function(garageName, garageConfig)
    if not garageName or not garageConfig then
        --print('^1[MH_GARAGE ERROR]^7 SyncHouseGarage: Missing garageName or garageConfig')
        return
    end
    
    -- Inject garage vào GaragesData client
    GaragesData[garageName] = garageConfig
    
    --print('^2[MH_GARAGE CLIENT]^7 Synced garage "' .. garageName .. '" with interior "' .. tostring(garageConfig.interior) .. '"')
end)

-- Event để xóa garage
RegisterNetEvent('qbx_housing:client:RemoveHouseGarage', function(garageName)
    if not garageName then return end
    
    GaragesData[garageName] = nil
    --print('^1[MH_GARAGE CLIENT]^7 Removed garage "' .. garageName .. '"')
end)

-- Event để sync tất cả garages (khi player join)
RegisterNetEvent('qbx_housing:client:SyncAllGarages', function(houseGarages)
    if not houseGarages then return end
    
    local count = 0
    for garageName, garageConfig in pairs(houseGarages) do
        GaragesData[garageName] = garageConfig
        count = count + 1
    end
    
    --print('^2[MH_GARAGE CLIENT]^7 Synced ' .. count .. ' house garages')
end)

-- ========== NUI INTEGRATION - CLIENT-SIDE SPAWNING ==========
-- ENABLED: Vehicle spawning is now handled client-side to prevent duplicate spawn issues
-- Server sends vehicle data, client spawns vehicle and confirms back

RegisterNetEvent('mh_garage:client:SpawnVehicleNUI', function(vehicleData, spawnPoint, plate, vehicleId, spawnRequestId)
    if not vehicleData or not spawnPoint or not plate then 
        -- Notify server of failure
        TriggerServerEvent('mh_garage:server:SpawnVehicleResult', vehicleId, spawnRequestId, false, nil, 'Invalid data received')
        return 
    end
    
    local model = vehicleData.model
    if not model then 
        TriggerServerEvent('mh_garage:server:SpawnVehicleResult', vehicleId, spawnRequestId, false, nil, 'No model in vehicle data')
        return 
    end
    
    local hash = type(model) == 'string' and joaat(model) or model
    
    if not IsModelInCdimage(hash) then
        Edit.Notify(locale('invalid_model'), 'error')
        TriggerServerEvent('mh_garage:server:SpawnVehicleResult', vehicleId, spawnRequestId, false, nil, 'Invalid model')
        return
    end
    
    -- Request model
    lib.requestModel(hash)
    
    -- CRITICAL: Check if there's already a vehicle with this plate nearby - and delete it
    -- This prevents any duplicate from existing before we spawn
    local nearbyVehicles = lib.getClosestVehicle(vec3(spawnPoint.x, spawnPoint.y, spawnPoint.z), 50.0, true)
    if nearbyVehicles then
        -- Check ALL vehicles in range, not just closest
        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) then
                local vehPlate = string.strtrim(GetVehicleNumberPlateText(veh))
                if vehPlate == plate then
                    -- Delete existing vehicle with same plate
                    if NetworkHasControlOfEntity(veh) then
                        DeleteEntity(veh)
                    else
                        NetworkRequestControlOfEntity(veh)
                        local timeout = 0
                        while not NetworkHasControlOfEntity(veh) and timeout < 20 do
                            Wait(10)
                            timeout = timeout + 1
                        end
                        if NetworkHasControlOfEntity(veh) then
                            DeleteEntity(veh)
                        end
                    end
                end
            end
        end
    end
    
    -- Small delay after cleanup
    Wait(50)
    
    -- Spawn vehicle - CLIENT-SIDE (no server sync issues)
    local vehicle = CreateVehicle(hash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w or 0.0, true, false)
    
    if not DoesEntityExist(vehicle) then
        Edit.Notify(locale('something_wrong'), 'error')
        TriggerServerEvent('mh_garage:server:SpawnVehicleResult', vehicleId, spawnRequestId, false, nil, 'CreateVehicle failed')
        SetModelAsNoLongerNeeded(hash)
        return
    end
    
    -- CRITICAL: Get network ID BEFORE any async operations
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    
    -- Set ownership flags
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetNetworkIdCanMigrate(netId, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    
    -- Set vehicle on ground properly
    for _ = 1, 10 do
        SetVehicleOnGroundProperly(vehicle)
        Wait(0)
    end
    
    -- Apply vehicle mods/properties
    lib.setVehicleProperties(vehicle, vehicleData)
    
    -- Restore fuel
    local fuelLevel = vehicleData.fuelLevel or 100.0
    Edit.SetFuel(vehicle, fuelLevel)
    
    -- Apply body and engine health
    if vehicleData.bodyHealth then
        SetVehicleBodyHealth(vehicle, vehicleData.bodyHealth)
    end
    if vehicleData.engineHealth then
        SetVehicleEngineHealth(vehicle, vehicleData.engineHealth)
    end
    
    -- Give keys
    Edit.GiveCarKey(vehicle, plate)
    
    -- Clear model from memory
    SetModelAsNoLongerNeeded(hash)
    
    -- Register as orphan vehicle
    TriggerServerEvent('mh_garage:server:Orphan', netId)
    
    -- CRITICAL: Notify server of successful spawn - server will update database
    TriggerServerEvent('mh_garage:server:SpawnVehicleResult', vehicleId, spawnRequestId, true, netId, nil)
    
    -- Notify player
    Edit.Notify('Xe đã được lấy ra tại vị trí spawn', 'success')
end)

return Garage