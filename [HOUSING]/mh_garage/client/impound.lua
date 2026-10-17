if not lib then return end

local cfg = lib.load 'config.impound'
local Impound = { Points = {} }
local Marker = lib.load 'config.general'.Markers.Impound
local hasTextUI
local Edit = require 'edit_functions'
local LastVehicle
-- Removed: local SpawnVehicle = require 'client.garage'.SpawnVehicle
-- Using custom SpawnImpoundVehicle function instead

-- Table to track impounded vehicles for persistent damage
local ImpoundedVehicles = {}

local function FindFreeSpawn(index)
    if cfg.Locations[index] and cfg.Locations[index].spawns then
        for i = 1, #cfg.Locations[index].spawns do
            local coords = cfg.Locations[index].spawns[i]

            if #lib.getNearbyVehicles(coords.xyz, 2.0, false) == 0 then
                return coords
            end
        end
    end

    return false
end

local function SpawnImpoundVehicle(mods, coords)
    if not mods then return end

    local hash = lib.requestModel(mods.model)

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w, true, true)
    
    -- Verify vehicle creation
    if not DoesEntityExist(vehicle) then
        return
    end
    
    -- ULTRA MINIMAL SETUP - testing if any native is causing the issue
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetPedIntoVehicle(cache.ped, vehicle, -1)
    lib.setVehicleProperties(vehicle, mods)
    
    if not success then
        -- If setVehicleProperties fails, at least set the plate manually
        SetVehicleNumberPlateText(vehicle, mods.plate or '')
    end
    
    -- Wait for any operations to complete
    Wait(500)
    
    -- SIMPLE IMPOUND DAMAGE - Just make it clearly damaged
    if DoesEntityExist(vehicle) then
        -- Simple and effective damage
        SetVehicleBodyHealth(vehicle, 300.0) -- 30% body health - clearly damaged
        SetVehicleEngineHealth(vehicle, 300.0) -- 30% engine health - clearly weak
        SetVehiclePetrolTankHealth(vehicle, 200.0) -- 20% fuel tank
        
        -- Visual damage for immediate feedback
        SetVehicleDeformationFixed(vehicle)
        
        -- Break some parts randomly
        if math.random(1, 100) <= 99 then -- 99% chance
            SetVehicleDoorBroken(vehicle, math.random(0, 5), false)
        end
        if math.random(1, 100) <= 99 then -- 99% chance
            SmashVehicleWindow(vehicle, math.random(0, 7))
        end
        
        -- Reduce performance significantly
        SetVehicleEngineTorqueMultiplier(vehicle, 0.5) -- 50% Giảm điện
        
        -- Start with engine off
        SetVehicleEngineOn(vehicle, false, true, true)
        
        -- Simple tracking for anti-repair
        local plate = mods.plate or GetVehicleNumberPlateText(vehicle)
        ImpoundedVehicles[plate] = {
            vehicle = vehicle,
            damaged = true
        }
        -- Simple monitoring to prevent auto-repair
    end
    
end

RegisterNetEvent('mh_garage:dodamevehicle', function()
    local src = source
    local vehicle = GetVehiclePedIsIn(cache.ped, false)

    if DoesEntityExist(vehicle) then
        SetVehicleBodyHealth(vehicle, 300.0)
        SetVehicleEngineHealth(vehicle, 300.0)
        SmashVehicleWindow(vehicle, math.random(0, 7))
         SetVehicleDoorBroken(vehicle, math.random(0, 5), false)
    end

end)

--     -- Start monitoring thread for this vehicle
--  CreateThread(function()
--             while DoesEntityExist(vehicle) and ImpoundedVehicles[plate] do
--                 Wait(1000) -- Check every second
                
--                 -- If health goes above damage threshold, reset it
--                 if GetVehicleBodyHealth(vehicle) > 400 then
--                     SetVehicleBodyHealth(vehicle, 300.0)
--                 end
--                 if GetVehicleEngineHealth(vehicle) > 400 then
--                     SetVehicleEngineHealth(vehicle, 300.0)
--                 end
                
--                 -- Maintain power reduction
--                 SetVehicleEngineTorqueMultiplier(vehicle, 0.5)
--             end
            
--             -- Cleanup when vehicle is gone
--             if ImpoundedVehicles[plate] then
--                 ImpoundedVehicles[plate] = nil
--             end
--         end)

-- Function to remove impound damage tracking (for mechanics to use)
function RemoveImpoundDamageTracking(plate)
    if ImpoundedVehicles[plate] then
        -- Simple cleanup
        ImpoundedVehicles[plate] = nil
        --print('^2[IMPOUND REPAIR]^7 Removed damage tracking for vehicle: ' .. plate)
        return true
    end
    return false
end

-- Export function for other resources to use
exports('RemoveImpoundDamageTracking', RemoveImpoundDamageTracking)

local function DeletePreview()
    while DoesEntityExist(LastVehicle) do
        NetworkRequestControlOfEntity(LastVehicle)
        DeleteVehicle(LastVehicle)
        Wait(0)
    end
    LastVehicle = nil
end


function Impound.CreateImpoundList(index)
    local vehicles = lib.callback.await('mh_garage:cb:GetImpoundList', 100, index)

    if not vehicles then
        return Edit.Notify(locale('impound_empty'))
    end

    -- Create a simple table of all vehicles first
    local vehicleList = {}
    for plate, data in pairs(vehicles) do
        vehicleList[#vehicleList + 1] = {plate = plate, data = data}
    end
    
    --print("=== CLIENT: TOTAL VEHICLES FOUND:", #vehicleList, "===")
    
    -- Process each vehicle with DIRECT price calculation (no callback)
    local options = {}
    local vehiclePrices = {}
    
    for i = 1, #vehicleList do
        local plate = vehicleList[i].plate
        local mods = vehicleList[i].data
        
        --print("CLIENT: Processing vehicle", i, "of", #vehicleList, "- Plate:", plate)
        
        -- Use the calculateImpoundFee function from config
        local modelName
        if type(mods.model) == 'string' then
            modelName = mods.model
        else
            -- Convert hash to string instead of using GetDisplayNameFromVehicleModel
            modelName = tostring(mods.model)
        end
        
        -- Get the price and vehicle name using improved logic
        local finalPrice = 1000 -- Fixed impound price (same as server config)
        local vehicleDisplayName = "Unknown Vehicle"
        local foundVehicle = false
        
        -- Try to get vehicle data from qbx_core
        local success, VEHICLES = pcall(function()
            return exports.qbx_core:GetVehiclesByName()
        end)
        
        if success and VEHICLES then
            -- If mods.model is a hash, need to search differently
            for vehicleName, vehicleData in pairs(VEHICLES) do
                -- Check if model matches hash or string
                local modelMatch = false
                if type(mods.model) == 'string' then
                    modelMatch = (vehicleName:lower() == mods.model:lower())
                else
                    -- mods.model is hash, check if vehicleData has hash field
                    modelMatch = (vehicleData.hash == mods.model) or (GetHashKey(vehicleName) == mods.model)
                end
                
                if modelMatch then
                    foundVehicle = true
                    
                    -- Use fixed price (don't calculate from vehicle price)
                    -- finalPrice is already set to 2000 above
                    
                    -- Use the vehicle name from database as display name
                    vehicleDisplayName = vehicleData.name or vehicleName
                    break
                end
            end
        end
        
        -- Fallback for display name if still unknown
        if not foundVehicle then
            if type(mods.model) == 'string' then
                vehicleDisplayName = mods.model:upper()
            else
                vehicleDisplayName = "Xe #" .. tostring(mods.model)
            end
        end
        
        vehiclePrices[plate] = finalPrice

        --print('^3[CLIENT IMPOUND]^7 Vehicle: ' .. vehicleDisplayName .. ' | Plate: ' .. plate .. ' | Price: $' .. finalPrice)

        -- Create context menu option with vehicle name first, then plate
        local label = ('%s - %s - $%s'):format(vehicleDisplayName, plate, finalPrice)
        options[#options + 1] = { 
            title = label, 
            description = ('Xe: %s | Phí chuộc: $%s'):format(vehicleDisplayName, finalPrice),
            metadata = {
                { label = 'Biển số', value = plate },
                { label = 'Phí chuộc', value = '$' .. finalPrice }
            },
            onSelect = function()
                --print("=== CLIENT IMPOUND RETRIEVE ===")
                --print("Selected plate:", plate)
                
                local vehicleData = vehicles[plate]
                --print("Vehicle data exists:", vehicleData ~= nil)
                
                if vehicleData then
                    -- Double check: player shouldn't be in vehicle when retrieving
                    if IsPedInAnyVehicle(cache.ped, false) then
                        Edit.Notify('Bạn không thể chuộc xe khi đang ngồi trong xe khác!', 'error')
                        return
                    end
                    
                    -- ✅ CHECK VỊ TRÍ TRỐNG TRƯỚC KHI TRỪ TIỀN
                    local coords = FindFreeSpawn(index)
                    if not coords then
                        Edit.Notify(locale('no_free_spawnpoint'), 'error')
                        isProcessingImpound = false -- Reset flag
                        return
                    end
                    
                    --print("Vehicle model:", vehicleData.model)
                    --print("Model type:", type(vehicleData.model))
                        
                    -- Get model name - always use the model as string or convert hash to string
                    local modelName
                    if type(vehicleData.model) == 'string' then
                        modelName = vehicleData.model
                        --print("Using string model name:", modelName)
                    else
                        -- Convert hash to string instead of using GetDisplayNameFromVehicleModel
                        modelName = tostring(vehicleData.model)
                        --print("Converted hash to string:", modelName)
                    end
                    
                    --print("Final model name:", modelName)
                    
                    --print("Calling HasMoney callback...")
                    -- Pass the calculated price instead of letting server recalculate
                    local expectedPrice = vehiclePrices[plate] or 1000
                    --print('^3[CLIENT IMPOUND]^7 Retrieving ' .. plate .. ' | Expected price: $' .. expectedPrice .. ' | Model: ' .. modelName)
                    local cb = lib.callback.await('mh_garage:cb:HasMoney', 100, 0, modelName, plate, expectedPrice)
                    --print("Callback result:", cb)

                    if not cb then
                        local expectedPrice = vehiclePrices[plate] or 100
                        local message = ('You need $%s to retrieve this vehicle'):format(expectedPrice)
                        Edit.Notify(message, 'error')
                        --print("Not enough money! Required:", expectedPrice)
                        isProcessingImpound = false -- Reset flag
                        return
                    end

                    -- Spawn the damaged impound vehicle via server
                    TriggerServerEvent('mh_garage:server:ImpoundRetrieveComplete', plate, index)
                    
                    -- Reset processing flag after a delay (vehicle should spawn soon)
                    SetTimeout(2000, function()
                        isProcessingImpound = false
                    end)
                else
                    --print("Vehicle data is nil!")
                    Edit.Notify(locale('invalid_model'))
                    isProcessingImpound = false -- Reset flag
                end
                --print("===========================")
            end
        }
        
        --print("CLIENT: Added option for", plate, "with price", finalPrice)
    end
    
    --print("CLIENT: Menu creation complete. Total options:", #options)

    if #options == 0 then
        return Edit.Notify(locale('impound_empty'))
    end

    lib.registerContext({
        id = 'mh_garage:impound',
        title = locale('impound_title'),
        options = options
    })

    lib.showContext('mh_garage:impound')
end

function Impound.CreateDepotList(index)
    local vehicles = lib.callback.await('mh_garage:cb:GetDepotList', 100)

    if not vehicles or not next(vehicles) then
        return Edit.Notify(locale('depot_empty'))
    end

    local options = {}

    for plate, mods in pairs(vehicles) do
        local vehicleDisplayName = 'Unknown Vehicle'

        local success, VEHICLES = pcall(function()
            return exports.qbx_core:GetVehiclesByName()
        end)

        if success and VEHICLES then
            for vehicleName, vehicleData in pairs(VEHICLES) do
                local modelMatch = false
                if type(mods.model) == 'string' then
                    modelMatch = (vehicleName:lower() == mods.model:lower())
                else
                    modelMatch = (vehicleData.hash == mods.model) or (GetHashKey(vehicleName) == mods.model)
                end
                if modelMatch then
                    vehicleDisplayName = vehicleData.name or vehicleName
                    break
                end
            end
        else
            vehicleDisplayName = type(mods.model) == 'string' and mods.model:upper() or ('Xe #' .. tostring(mods.model))
        end

        local fee = cfg.DepotFee or 2000
        local label = ('%s - %s - $%s'):format(vehicleDisplayName, plate, fee)

        options[#options + 1] = {
            title = label,
            description = ('Xe: %s | Phí chuộc: $%s'):format(vehicleDisplayName, fee),
            metadata = {
                { label = 'Biển số', value = plate },
                { label = 'Phí chuộc', value = '$' .. fee }
            },
            onSelect = function()
                if IsPedInAnyVehicle(cache.ped, false) then
                    Edit.Notify('Bạn không thể chuộc xe khi đang ngồi trong xe khác!', 'error')
                    return
                end

                -- ✅ CHECK VỊ TRÍ TRỐNG TRƯỚC KHI TRỪ TIỀN
                local coords = FindFreeSpawn(index)
                if not coords then
                    Edit.Notify(locale('no_free_spawnpoint'), 'error')
                    return
                end

                local modelName = type(mods.model) == 'string' and mods.model or tostring(mods.model)
                local paid = lib.callback.await('mh_garage:cb:HasMoneyDepot', 100, modelName, plate)

                if not paid then
                    Edit.Notify(('Bạn cần $%s để chuộc xe này!'):format(fee), 'error')
                    return
                end

                TriggerServerEvent('mh_garage:server:DepotRetrieveComplete', plate, index)
            end
        }
    end

    if #options == 0 then
        return Edit.Notify(locale('depot_empty'))
    end

    lib.registerContext({
        id = 'mh_garage:depot',
        title = locale('depot_title'),
        options = options
    })

    lib.showContext('mh_garage:depot')
end

-- CREATE RECOVER LIST (Xe lỗi)
function Impound.CreateRecoverList(index)
    local vehicles = lib.callback.await('mh_garage:cb:GetRecoverList', 100)

    if not vehicles or not next(vehicles) then
        return Edit.Notify('Bạn không có xe nào để khôi phục')
    end

    local options = {}
    local vehiclePrices = {}

    for plate, mods in pairs(vehicles) do
        local vehicleDisplayName = 'Unknown Vehicle'
        local stateText = 'Không rõ'
        local stateColor = '⚪'
        local canRecover = true

        -- Determine state
        if mods.dbState == 0 then
            stateText = 'Ở ngoài'
            stateColor = '🟢'
        elseif mods.dbState == 1 then
            stateText = 'Trong garage'
            stateColor = '🔵'
        elseif mods.dbState == 2 then
            stateText = '🔒 Đang tạm giam'
            stateColor = '🔴'
            canRecover = false
        end

        -- Get vehicle display name
        local success, VEHICLES = pcall(function()
            return exports.qbx_core:GetVehiclesByName()
        end)

        if success and VEHICLES then
            for vehicleName, vehicleData in pairs(VEHICLES) do
                local modelMatch = false
                if type(mods.model) == 'string' then
                    modelMatch = (vehicleName:lower() == mods.model:lower())
                else
                    modelMatch = (vehicleData.hash == mods.model) or (GetHashKey(vehicleName) == mods.model)
                end
                if modelMatch then
                    vehicleDisplayName = vehicleData.name or vehicleName
                    break
                end
            end
        else
            vehicleDisplayName = type(mods.model) == 'string' and mods.model:upper() or ('Xe #' .. tostring(mods.model))
        end

        -- Calculate price (same as impound)
        local finalPrice = 1000 -- Default impound price
        vehiclePrices[plate] = finalPrice

        local label = ('%s %s - %s - $%s'):format(stateColor, vehicleDisplayName, plate, finalPrice)

        options[#options + 1] = {
            title = label,
            description = ('Trạng thái: %s | Phí chuộc: $%s'):format(stateText, finalPrice),
            metadata = {
                { label = 'Biển số', value = plate },
                { label = 'Trạng thái', value = stateText },
                { label = 'Garage', value = mods.dbGarage or 'N/A' },
                { label = 'Phí chuộc', value = '$' .. finalPrice }
            },
            disabled = not canRecover,
            onSelect = function()
                if not canRecover then
                    Edit.Notify('⚠️ Xe đang bị tạm giam!\n\nVui lòng sử dụng mục "Xe bị tạm giam" để chuộc xe.', 'error')
                    return
                end

                if IsPedInAnyVehicle(cache.ped, false) then
                    Edit.Notify('Bạn không thể khôi phục xe khi đang ngồi trong xe khác!', 'error')
                    return
                end

                -- ✅ CHECK VỊ TRÍ TRỐNG TRƯỚC KHI TRỪ TIỀN
                local coords = FindFreeSpawn(index)
                if not coords then
                    Edit.Notify(locale('no_free_spawnpoint'), 'error')
                    return
                end

                -- Get model name for payment
                local modelName = type(mods.model) == 'string' and mods.model or tostring(mods.model)
                
                -- Check if player has enough money (same price as impound)
                local paid = lib.callback.await('mh_garage:cb:HasMoneyRecover', 100, modelName, plate)

                if not paid then
                    local expectedPrice = vehiclePrices[plate] or 1000
                    Edit.Notify(('Bạn cần $%s để khôi phục xe này!'):format(expectedPrice), 'error')
                    return
                end

                -- Trigger server event to spawn vehicle (same as depot)
                TriggerServerEvent('mh_garage:server:RecoverVehicleComplete', plate, index)
            end
        }
    end

    if #options == 0 then
        return Edit.Notify('Không có xe nào để khôi phục')
    end

    lib.registerContext({
        id = 'mh_garage:recover',
        title = '🔧 Khôi phục xe',
        options = options
    })

    lib.showContext('mh_garage:recover')
end

local function OpenImpoundMenu(index)
    lib.registerContext({
        id = 'mh_garage:impound_main',
        title = locale('impound_menu_title'),
        options = {
            {
                title = locale('impound_title'),
                description = 'Chuộc xe bị thất lạc của bạn',
                icon = 'car',
                onSelect = function()
                    Impound.CreateImpoundList(index)
                end
            },
            {
                title = locale('depot_title'),
                description = 'Chuộc xe bị cảnh sát tạm giam',
                icon = 'shield',
                onSelect = function()
                    Impound.CreateDepotList(index)
                end
            },
            {
                title = 'Chuộc xe lỗi',
                description = 'Chuộc những xe bị mất hoặc lỗi',
                icon = 'wrench',
                onSelect = function()
                    Impound.CreateRecoverList(index)
                end
            }
        }
    })
    lib.showContext('mh_garage:impound_main')
end

local function NearbyImpound(point)
    ---@diagnostic disable-next-line: param-type-mismatch
    DrawMarker(Marker.id, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Marker.scaleX, Marker.scaleY, Marker.scaleZ, Marker.red, Marker.green, Marker.blue, 222, false, false, 0, true, false, false, false)

    if point.isClosest and point.currentDistance < 1.2 then
        -- Only show TextUI if player is not in a vehicle
        if not hasTextUI and not IsPedInAnyVehicle(cache.ped, false) then
            hasTextUI = point
            lib.showTextUI(locale('open_impound'))
        elseif hasTextUI and IsPedInAnyVehicle(cache.ped, false) then
            -- Hide TextUI if player gets in a vehicle
            hasTextUI = nil
            lib.hideTextUI()
        end

        if IsControlJustReleased(0, 38) then
            -- Check if player is in a vehicle
            if IsPedInAnyVehicle(cache.ped, false) then
                Edit.Notify('Bạn không thể truy cập bãi giữ xe khi đang ngồi trong xe!', 'error')
                return
            end
            
            OpenImpoundMenu(point.index)
        end
    elseif hasTextUI == point then
        hasTextUI = nil
        lib.hideTextUI()
    end
end

function Impound.CreatePoints()
    for i = 1, #cfg.Locations do
        local coords = cfg.Locations[i].coords

        local point = lib.points.new({
            coords = coords,
            distance = 30.0,
            nearby = NearbyImpound,
            index = i
        })

        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, cfg.Locations[i].blip.id)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, cfg.Locations[i].blip.scale)
        SetBlipColour(blip, cfg.Locations[i].blip.colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(locale('impound'))
        EndTextCommandSetBlipName(blip)

        Impound.Points[#Impound.Points + 1] = point
    end
end

function Impound.DeleteImpound()
    for i = 1, #Impound.Points do
        Impound.Points[i]:remove()
    end
end

-- Handle impound vehicle spawn from server
RegisterNetEvent('mh_garage:client:SpawnImpoundVehicle', function(vehicleId, impoundIndex)
    if not vehicleId or not impoundIndex then return end
    
    -- Find free spawn point
    local coords = FindFreeSpawn(impoundIndex)
    
    if not coords then
        Edit.Notify(locale('no_free_spawnpoint'), 'error')
        return
    end
    
    -- Request server to spawn vehicle with warp (returns netId and plate)
    local netId, plate = lib.callback.await('mh_garage:cb:SpawnImpoundVehicle', 1000, vehicleId, coords)
    
    if not netId or not plate then
        Edit.Notify('Lỗi spawn vehicle từ impound', 'error')
        return
    end
    
    -- Wait for vehicle to exist on client (server already warped player)
    local vehicle = NetToVeh(netId)
    local timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 100 do
        Wait(50)
        vehicle = NetToVeh(netId)
        timeout = timeout + 1
    end
    
    if DoesEntityExist(vehicle) then
        -- Double-check plate is set correctly on client
        SetVehicleNumberPlateText(vehicle, plate)
        
        -- Set fuel (low for impound vehicles)
        Edit.SetFuel(vehicle, 20.0)
        
        -- Give car keys with correct plate
        Edit.GiveCarKey(vehicle, plate)
        
        -- Register as orphan
        TriggerServerEvent('mh_garage:server:Orphan', netId)
    end
    
    -- Notify success
    Edit.Notify('Xe được lấy ra khỏi kho chuộc!', 'success')
end)

AddEventHandler('onResourceStop', function(resource)
    if cache.resource == resource then
        DeletePreview()
    end
end)


return Impound