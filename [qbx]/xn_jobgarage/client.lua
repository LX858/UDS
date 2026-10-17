local PlayerData = {}
local isInRange = {}
local lastNotificationTime = {}
local isMenuOpen = false
local isSpawning = false  -- DEBOUNCE: Ngăn spawn nhiều lần
local renderTargets = {}
local spawnedVehicles = {} -- Track spawned vehicles
local jobBlips = {} -- Track job blips
local freeSpawnActive = {} -- Track active free spawn vehicles (aircraft/boat) per garage type

-- FORWARD DECLARATIONS for menu functions
local ShowVehicleMenu
local ShowVehicleActions
local ShowAddVehicleMenu
local ShowChangeVehicleMenu

-- Function to check if player has job access (updated to handle aircraft garages and multiple locations)
local function HasJobAccess(jobName)
    if not PlayerData or not PlayerData.job then
        if Config.Debug then
            print("[DEBUG] PlayerData or job not loaded yet")
        end
        return false
    end
    
    -- Check if player is on duty
    if not PlayerData.job.onduty then
        if Config.Debug then
            print("[DEBUG] Player is not on duty")
        end
        return false
    end
    
    -- Handle aircraft garages (ambulance_aircraft, police_aircraft, mechanic_aircraft)
    local baseJobName = jobName
    if string.find(jobName, "_aircraft") then
        baseJobName = string.gsub(jobName, "_aircraft", "")
    end
    
    -- Handle boat garages (ambulance_boat, police_boat)
    if string.find(jobName, "_boat") then
        baseJobName = string.gsub(jobName, "_boat", "")
    end
    
    -- Handle multiple garage locations (police_2, police_3, ambulance_2, etc.)
    baseJobName = string.gsub(baseJobName, "_[0-9]+$", "")
    
    return PlayerData.job.name == baseJobName
end

-- Function to create blips for accessible garages
local function CreateJobBlips()
    if Config.Debug then
        print("[DEBUG] Creating job blips...")
    end
    
    -- Remove existing blips
    for _, blip in pairs(jobBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    jobBlips = {}
    
    if not PlayerData or not PlayerData.job then
        if Config.Debug then
            print("[DEBUG] No player data available for blips")
        end
        return
    end
    
    if Config.Debug then
        print("[DEBUG] Current player job:", PlayerData.job.name)
    end
    
    -- Create blips for accessible jobs
    for jobName, garage in pairs(Config.JobGarages) do
        if Config.Debug then
            print("[DEBUG] Checking job:", jobName)
        end
        if HasJobAccess(jobName) then
            if Config.Debug then
                print("[DEBUG] Player has access to:", jobName)
            end
            local blip = AddBlipForCoord(garage.drawText.x, garage.drawText.y, garage.drawText.z)
            local blipConfig = Config.BlipSettings[jobName]
            
            if blipConfig then
                SetBlipSprite(blip, blipConfig.sprite)
                SetBlipColour(blip, blipConfig.color)
                SetBlipScale(blip, blipConfig.scale)
                SetBlipAsShortRange(blip, true)
                
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(blipConfig.name)
                EndTextCommandSetBlipName(blip)
                
                jobBlips[jobName] = blip
                if Config.Debug then
                    print("[DEBUG] Successfully created blip for:", jobName)
                end
            else
                if Config.Debug then
                    print("[DEBUG] No blip config found for:", jobName)
                end
            end
        else
            if Config.Debug then
                print("[DEBUG] Player does not have access to:", jobName)
            end
        end
    end
    
    if Config.Debug then
        print("[DEBUG] Total blips created:", #jobBlips)
    end
end

-- Initialize player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = exports.qbx_core:GetPlayerData()
    if Config.Debug then
        print("[DEBUG] Player loaded with job:", PlayerData.job.name)
    end
    -- Create blips when player data is loaded
    Wait(2000) -- Wait for everything to load
    CreateJobBlips()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    if Config.Debug then
        print("[DEBUG] Job changed to:", JobInfo.name)
    end
    -- Clear range status when job changes
    isInRange = {}
    lastNotificationTime = {}
    -- Update blips when job changes
    CreateJobBlips()
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    PlayerData.job.onduty = duty
    if Config.Debug then
        print("[DEBUG] Duty status changed to:", duty)
    end
    -- Update blips when duty changes
    CreateJobBlips()
end)

-- Debounced notification function
local function ShowNotification(notificationKey, cooldown)
    cooldown = cooldown or 3000 -- 3 seconds default cooldown
    local currentTime = GetGameTimer()
    
    if not lastNotificationTime[notificationKey] or 
       (currentTime - lastNotificationTime[notificationKey]) > cooldown then
        if Config.Notifications[notificationKey] then
            lib.notify({
                title = Config.Notifications[notificationKey].title,
                description = Config.Notifications[notificationKey].description,
                type = Config.Notifications[notificationKey].type or 'inform'
            })
        end
        lastNotificationTime[notificationKey] = currentTime
    end
end

-- Function to check if player has required grade for vehicle
local function HasGradeAccess(requiredGrade)
    if not PlayerData or not PlayerData.job then
        return false
    end
    
    return PlayerData.job.grade.level >= requiredGrade
end

-- Function to spawn and attach trailer to vehicle if configured
local function SpawnAndAttachTrailer(vehicle, vehicleModel)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    
    local trailerModel = nil
    if vehicleModel and Config.VehicleTrailers and Config.VehicleTrailers[vehicleModel] then
        trailerModel = Config.VehicleTrailers[vehicleModel]
    end
    
    if not trailerModel and Config.VehicleTrailers then
        local currentModel = GetEntityModel(vehicle)
        for modelName, tModel in pairs(Config.VehicleTrailers) do
            if currentModel == GetHashKey(modelName) then
                trailerModel = tModel
                break
            end
        end
    end
    
    if not trailerModel then return end
    
    local trailerHash = GetHashKey(trailerModel)
    if not IsModelInCdimage(trailerHash) or not IsModelValid(trailerHash) then
        if Config.Debug then
            print("[DEBUG] Invalid trailer model:", trailerModel)
        end
        return
    end
    
    lib.requestModel(trailerHash, 5000)
    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    
    -- Spawn trailer
    local trailer = CreateVehicle(trailerHash, coords.x, coords.y, coords.z, heading, true, false)
    if trailer and trailer ~= 0 and DoesEntityExist(trailer) then
        SetModelAsNoLongerNeeded(trailerHash)
        SetVehicleOnGroundProperly(trailer)
        SetEntityAsMissionEntity(trailer, true, true)
        SetVehicleHasBeenOwnedByPlayer(trailer, true)
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(trailer), true)
        
        local plate = GetVehicleNumberPlateText(vehicle)
        SetVehicleNumberPlateText(trailer, plate)
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
        TriggerEvent("qb-vehiclekeys:client:SetOwner", plate)
        
        Wait(200)
        AttachVehicleToTrailer(vehicle, trailer, 10.0)
        
        if Config.Debug then
            print(string.format("[DEBUG] Attached trailer %s to vehicle %s (Plate: %s)", trailerModel, vehicleModel or "N/A", plate))
        end
        return trailer
    else
        SetModelAsNoLongerNeeded(trailerHash)
    end
end

-- Separate function to handle actual vehicle spawning
local function DoSpawnVehicle(vehicleName, spawnPoint, vehicleType, vehicleFee, jobName, garageName)
    if Config.Debug then
        print("[DEBUG] Attempting to spawn vehicle:", vehicleName)
        print("[DEBUG] Spawn point:", spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w)
        print("[DEBUG] Job Name:", jobName)
        print("[DEBUG] Garage Name:", garageName)
    end
    
    -- Directly spawn vehicle (status already checked in menu)
    DoActualSpawn(vehicleName, spawnPoint, vehicleType, vehicleFee, jobName, garageName)
end

-- =====================================================
-- CLIENT-SIDE SPAWN: Tối ưu tốc độ spawn xe
-- =====================================================
function DoActualSpawn(vehicleName, spawnPoint, vehicleType, vehicleFee, jobName, garageName)
    -- Check if spawn point is clear with better detection
    local vehicles = GetGamePool('CVehicle')
    
    for _, vehicle in pairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(vehicleCoords - spawnPoint.xyz)
        
        if distance < 3.0 then
            if Config.Debug then
                print("[DEBUG] Spawn blocked by nearby vehicle at distance:", distance)
            end
            ShowNotification('spawnBlocked', 2000)
            return
        end
    end
    
    local vehicleHash = GetHashKey(vehicleName)
    
    if not IsModelInCdimage(vehicleHash) or not IsModelValid(vehicleHash) then
        if Config.Debug then
            print("[DEBUG] Invalid vehicle model:", vehicleName)
        end
        ShowNotification('spawnError', 2000)
        return
    end
    
    if Config.Debug then
        print("[DEBUG] CLIENT-SPAWN: Getting vehicle data from server...")
    end
    
    -- Bước 1: Lấy data từ server (validate + get plate/mods)
    local result = lib.callback.await('xn_jobgarage:server:getVehicleDataForSpawn', false, {
        model = vehicleName,
        jobName = jobName,
        garageName = garageName
    })
    
    if not result or not result.success then
        if Config.Debug then
            print("[DEBUG] Failed to get vehicle data from server:", result and result.reason or "unknown")
        end
        ShowNotification('spawnError', 2000)
        return
    end
    
    if Config.Debug then
        print("[DEBUG] CLIENT-SPAWN: Got data - Plate:", result.plate, "Body:", result.bodyHealth, "Engine:", result.engineHealth)
    end
    
    -- Bước 2: Load model
    lib.requestModel(vehicleHash, 5000)
    
    -- Bước 3: Spawn xe locally
    local vehicle = CreateVehicle(vehicleHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)
    
    if not vehicle or vehicle == 0 then
        if Config.Debug then
            print("[DEBUG] CLIENT-SPAWN: Failed to create vehicle")
        end
        SetModelAsNoLongerNeeded(vehicleHash)
        ShowNotification('spawnError', 2000)
        return
    end
    
    -- Bước 4: Setup vehicle
    SetModelAsNoLongerNeeded(vehicleHash)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(vehicle), true)
    
    -- Set modkit
    SetVehicleModKit(vehicle, 0)
    
    -- Apply saved mods if exists
    if result.vehicleMods then
        result.vehicleMods.plate = nil  -- Đảm bảo không ghi đè plate
        if GetEntityModel(vehicle) == GetHashKey("amrfreightliner") then
            result.vehicleMods.modFrame = 0
            result.vehicleMods.modRoof = 0
            result.vehicleMods.modHood = 0
            result.vehicleMods.modRightFender = 0
            result.vehicleMods.modOrnaments = 3
        end
        lib.setVehicleProperties(vehicle, result.vehicleMods)
    -- else
        -- Apply default liveries for new vehicles
    --     local model = GetEntityModel(vehicle)

    --     if model == GetHashKey("polbuffalo4") then
    --         SetVehicleMod(vehicle, 48, 2, false)
    --     elseif model == GetHashKey("polvigero2") then
    --         SetVehicleMod(vehicle, 48, 0, false)
    --     elseif model == GetHashKey("polmav") then
    --         SetVehicleLivery(vehicle, 0)
    --     elseif model == GetHashKey("poldom") then
    --         SetVehicleMod(vehicle, 48, 0, false)
    --     elseif model == GetHashKey("nkscout") then
    --         SetVehicleMod(vehicle, 48, 0, false)
    --         SetVehicleMod(vehicle, 1, 1, false)
    --     elseif model == GetHashKey("polvstr") then
    --         SetVehicleMod(vehicle, 48, 2, false)
    --     end
    end

    -- Always apply default modifications for amrfreightliner on spawn
    if GetEntityModel(vehicle) == GetHashKey("amrfreightliner") then
        Wait(500)  -- Wait for vehicle components to fully stream in the engine
        SetVehicleModKit(vehicle, 0)
        -- print(string.format("^2[DEBUG xn_jobgarage] Spawned amrfreightliner. ModKit: %s, Chassis (5): %s, Roof (10): %s, Bonnet (7): %s, Wing_R (9): %s, Ornaments (28): %s^0", 
        --     GetVehicleModKit(vehicle),
        --     GetNumVehicleMods(vehicle, 5),
        --     GetNumVehicleMods(vehicle, 10),
        --     GetNumVehicleMods(vehicle, 7),
        --     GetNumVehicleMods(vehicle, 9),
        --     GetNumVehicleMods(vehicle, 28)
        -- ))
        SetVehicleMod(vehicle, 5, 0, false)   -- CHASSIS: Enables Speaker Grill 1 (Skips Grill 2)
        SetVehicleMod(vehicle, 10, 0, false)  -- ROOF: Enables Wire 1 (Skips Wires 2 and 3)
        SetVehicleMod(vehicle, 7, 0, false)   -- BONNET: Enables Backfootsteps
        SetVehicleMod(vehicle, 9, 0, false)   -- WING_R: Enables Footsteps
        SetVehicleMod(vehicle, 28, 3, false)  -- ORNAMENTS: Enables Ornaments 4
    end
    
    -- FORCE SET PLATE
    SetVehicleNumberPlateText(vehicle, result.plate)
    
    -- Set health
    SetVehicleBodyHealth(vehicle, result.bodyHealth + 0.0)
    SetVehicleEngineHealth(vehicle, result.engineHealth + 0.0)
    
    -- Set fuel
    if result.fuelLevel then
        exports['cdn-fuel']:SetFuel(vehicle, result.fuelLevel)
    else
        exports['cdn-fuel']:SetFuel(vehicle, 100.0)
    end
    
    -- Warp player
    if Config.VehicleSettings.warpIntoVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
    
    -- Charge fee if applicable
    if vehicleFee and vehicleFee > 0 then
        TriggerServerEvent('xn_jobgarage:server:chargeFee', vehicleFee)
    end
    
    -- Give keys
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
    TriggerEvent("qb-vehiclekeys:client:SetOwner", plate)
    
    -- Spawn & attach trailer if configured
    SpawnAndAttachTrailer(vehicle, vehicleName)
    
    -- Báo server spawn thành công
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('xn_jobgarage:server:onClientSpawnSuccess', result.vehicleId, netId)
    
    -- Track spawned vehicle
    for jobNameCheck, garage in pairs(Config.JobGarages) do
        if garage.spawnPoint.x == spawnPoint.x and garage.spawnPoint.y == spawnPoint.y and garage.spawnPoint.z == spawnPoint.z then
            spawnedVehicles[jobNameCheck] = {
                vehicle = vehicle,
                coords = spawnPoint.xyz,
                plate = result.plate,
                jobName = jobName,
                garageName = garageName
            }
            break
        end
    end
    
    -- Show notification
    if vehicleType == "aircraft" then
        ShowNotification('aircraftSpawnSuccess', 1000)
    else
        ShowNotification('spawnSuccess', 1000)
    end
    
    if result.isFirstTime then
        lib.notify({
            title = 'Xe Mới',
            description = 'Đây là lần đầu bạn lấy xe này. Biển số: ' .. result.plate,
            type = 'success',
            duration = 5000
        })
    end
    
    if Config.Debug then
        print("[DEBUG] CLIENT-SPAWN: Completed successfully! Vehicle:", vehicle, "Plate:", result.plate)
    end
end

-- SPAWN XE TỰ DO (cho aircraft/boat - không lưu SQL)
local function SpawnVehicleFree(vehicleName, spawnPoint, requiredGrade, vehicleType, vehicleFee, garageName, baseJobName, defaultMods)
    -- DEBOUNCE
    if isSpawning then
        return
    end
    isSpawning = true
    
    if Config.Debug then
        print("[DEBUG] SpawnVehicleFree START:", vehicleName, vehicleType)
    end
    
    -- Check grade
    if not HasGradeAccess(requiredGrade) then
        isSpawning = false
        ShowNotification('gradeRequired', 2000)
        return
    end
    
    -- Spawn từ server (không lưu SQL)
    local result = lib.callback.await('xn_jobgarage:server:spawnVehicleFree', false, {
        model = vehicleName,
        coords = spawnPoint,
        vehicleType = vehicleType,
        defaultMods = defaultMods
    })
    
    if Config.Debug then
        print("[DEBUG] Server callback result:", result and "OK" or "NIL", result and result.success or "N/A")
    end
    
    if not result or not result.success then
        isSpawning = false
        if Config.Debug then
            print("[DEBUG] Spawn failed - result:", json.encode(result or {}))
        end
        -- Notify đúng loại phương tiện
        if vehicleType == "aircraft" then
            ShowNotification('aircraftSpawnError', 2000)
        elseif vehicleType == "boat" then
            ShowNotification('boatSpawnError', 2000)
        else
            ShowNotification('spawnError', 2000)
        end
        return
    end
    
    local netId = result.netId
    local plate = result.plate
    if Config.Debug then
        print("[DEBUG] NetId:", netId, "Plate:", plate)
    end
    
    -- Wait for vehicle with longer timeout
    local vehicle = nil
    local attempts = 0
    local maxAttempts = 100  -- 10 seconds
    
    while not vehicle and attempts < maxAttempts do
        Wait(100)
        attempts = attempts + 1
        
        if NetworkDoesEntityExistWithNetworkId(netId) then
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh and veh ~= 0 and DoesEntityExist(veh) then
                vehicle = veh
                if Config.Debug then
                    print("[DEBUG] Vehicle found after", attempts, "attempts")
                end
            end
        end
    end
    
    if not vehicle then
        isSpawning = false
        if Config.Debug then
            print("[DEBUG] Vehicle NOT found after timeout - NetId:", netId)
        end
        if vehicleType == "aircraft" then
            ShowNotification('aircraftSpawnError', 2000)
        elseif vehicleType == "boat" then
            ShowNotification('boatSpawnError', 2000)
        else
            ShowNotification('spawnError', 2000)
        end
        return
    end
    
    if Config.Debug then
        print("[DEBUG] Setting up vehicle...")
    end
    
    -- Setup vehicle
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    
    -- Apply default mods (XÓA PLATE KHỎI MODS TRƯỚC KHI APPLY)
    if result.vehicleMods then
        result.vehicleMods.plate = nil  -- Đảm bảo không ghi đè plate
        lib.setVehicleProperties(vehicle, result.vehicleMods)
    end
    
    local model = GetEntityModel(vehicle)
    if model == GetHashKey("amrfreightliner") then
        Wait(500)  -- Wait for vehicle components to fully stream in the engine
        SetVehicleModKit(vehicle, 0)
        print(string.format("^2[DEBUG xn_jobgarage] Free Spawned amrfreightliner. ModKit: %s, Chassis (5): %s, Roof (10): %s, Bonnet (7): %s, Wing_R (9): %s, Ornaments (28): %s^0", 
            GetVehicleModKit(vehicle),
            GetNumVehicleMods(vehicle, 5),
            GetNumVehicleMods(vehicle, 10),
            GetNumVehicleMods(vehicle, 7),
            GetNumVehicleMods(vehicle, 9),
            GetNumVehicleMods(vehicle, 28)
        ))
        SetVehicleMod(vehicle, 5, 0, false)   -- CHASSIS: Enables Speaker Grill 1 (Skips Grill 2)
        SetVehicleMod(vehicle, 10, 0, false)  -- ROOF: Enables Wire 1 (Skips Wires 2 and 3)
        SetVehicleMod(vehicle, 7, 0, false)   -- BONNET: Enables Backfootsteps
        SetVehicleMod(vehicle, 9, 0, false)   -- WING_R: Enables Footsteps
        SetVehicleMod(vehicle, 28, 3, false)  -- ORNAMENTS: Enables Ornaments 4
    end
    
    -- FORCE SET PLATE SAU KHI APPLY MODS
    SetVehicleNumberPlateText(vehicle, plate)
    
    -- Warp player
    if Config.VehicleSettings.warpIntoVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
    
    -- Keys đã được server give rồi, không cần làm gì ở client
    
    -- Spawn & attach trailer if configured
    SpawnAndAttachTrailer(vehicle, vehicleName)
    
    -- Set fuel
    local fuelSuccess = pcall(function()
        exports['cdn-fuel']:SetFuel(vehicle, 100)
    end)
    if not fuelSuccess then
        pcall(function()
            Entity(vehicle).state.fuel = 100
        end)
    end
    
    isSpawning = false
    
    if Config.Debug then
        print("[DEBUG] SpawnVehicleFree COMPLETE!")
    end
    
    -- Mark this garage type as having active vehicle
    freeSpawnActive[garageName] = {
        vehicle = vehicle,
        plate = plate,
        vehicleType = vehicleType
    }
    
    if vehicleType == "aircraft" then
        ShowNotification('aircraftSpawnSuccess', 1000)
    elseif vehicleType == "boat" then
        ShowNotification('boatSpawnSuccess', 1000)
    else
        ShowNotification('spawnSuccess', 1000)
    end
end

-- =====================================================
-- CLIENT-SIDE SPAWN BY ID: Tối ưu tốc độ spawn xe
-- =====================================================
local function SpawnVehicleById(vehicleId, spawnPoint, vehicleType, baseJobName, garageName)
    -- DEBOUNCE: Ngăn spam click từ menu
    if isSpawning then
        return
    end
    isSpawning = true
    
    if Config.Debug then
        print("[DEBUG] CLIENT-SPAWN BY ID:", vehicleId)
    end
    
    -- Check spawn point clear
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in pairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(vehicleCoords - spawnPoint.xyz)
        if distance < 3.0 then
            isSpawning = false
            ShowNotification('spawnBlocked', 2000)
            return
        end
    end
    
    -- Bước 1: Lấy data từ server
    local result = lib.callback.await('xn_jobgarage:server:getVehicleDataByIdForSpawn', false, {
        vehicleId = vehicleId
    })
    
    if not result or not result.success then
        isSpawning = false
        if result and result.reason == 'vehicle_already_out' then
            lib.notify({title = 'Lỗi', description = 'Xe đã được lấy ra trước đó!', type = 'error'})
        else
            ShowNotification('spawnError', 2000)
        end
        return
    end
    
    if Config.Debug then
        print("[DEBUG] CLIENT-SPAWN BY ID: Got data - Model:", result.vehicleModel, "Plate:", result.plate)
    end
    
    -- Bước 2: Load model
    local vehicleHash = GetHashKey(result.vehicleModel)
    lib.requestModel(vehicleHash, 5000)
    
    -- Bước 3: Spawn xe locally
    local vehicle = CreateVehicle(vehicleHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)
    
    if not vehicle or vehicle == 0 then
        isSpawning = false
        SetModelAsNoLongerNeeded(vehicleHash)
        ShowNotification('spawnError', 2000)
        return
    end
    
    -- Bước 4: Setup vehicle
    SetModelAsNoLongerNeeded(vehicleHash)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(vehicle), true)
    SetVehicleModKit(vehicle, 0)
    
    -- Apply mods
    if result.vehicleMods then
        result.vehicleMods.plate = nil
        if GetEntityModel(vehicle) == GetHashKey("amrfreightliner") then
            result.vehicleMods.modFrame = 0
            result.vehicleMods.modRoof = 0
            result.vehicleMods.modHood = 0
            result.vehicleMods.modRightFender = 0
            result.vehicleMods.modOrnaments = 4
        end
        lib.setVehicleProperties(vehicle, result.vehicleMods)
    end
    
    -- Always apply default modifications for amrfreightliner on spawn
    if GetEntityModel(vehicle) == GetHashKey("amrfreightliner") then
        Wait(500)  -- Wait for vehicle components to fully stream in the engine
        SetVehicleModKit(vehicle, 0)
        print(string.format("^2[DEBUG xn_jobgarage] Spawned amrfreightliner (By ID). ModKit: %s, Chassis (5): %s, Roof (10): %s, Bonnet (7): %s, Wing_R (9): %s, Ornaments (28): %s^0", 
            GetVehicleModKit(vehicle),
            GetNumVehicleMods(vehicle, 5),
            GetNumVehicleMods(vehicle, 10),
            GetNumVehicleMods(vehicle, 7),
            GetNumVehicleMods(vehicle, 9),
            GetNumVehicleMods(vehicle, 28)
        ))
        SetVehicleMod(vehicle, 5, 0, false)   -- CHASSIS: Enables Speaker Grill 1 (Skips Grill 2)
        SetVehicleMod(vehicle, 10, 0, false)  -- ROOF: Enables Wire 1 (Skips Wires 2 and 3)
        SetVehicleMod(vehicle, 7, 0, false)   -- BONNET: Enables Backfootsteps
        SetVehicleMod(vehicle, 9, 0, false)   -- WING_R: Enables Footsteps
        SetVehicleMod(vehicle, 28, 3, false)  -- ORNAMENTS: Enables Ornaments 4
    end
    
    -- FORCE SET PLATE
    SetVehicleNumberPlateText(vehicle, result.plate)
    
    -- Set health
    SetVehicleBodyHealth(vehicle, result.bodyHealth + 0.0)
    SetVehicleEngineHealth(vehicle, result.engineHealth + 0.0)
    
    -- Set fuel
    exports['cdn-fuel']:SetFuel(vehicle, result.fuelLevel or 100)
    
    -- Warp player
    if Config.VehicleSettings.warpIntoVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
    
    -- Give keys
    local plate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
    TriggerEvent("qb-vehiclekeys:client:SetOwner", plate)
    
    -- Spawn & attach trailer if configured
    SpawnAndAttachTrailer(vehicle, result.vehicleModel)
    
    -- Báo server spawn thành công
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('xn_jobgarage:server:onClientSpawnSuccess', result.vehicleId, netId)
    
    isSpawning = false
    ShowNotification('vehicleSpawned', 2000)
    
    if Config.Debug then
        print("[DEBUG] CLIENT-SPAWN BY ID: Completed! Vehicle:", vehicle, "Plate:", result.plate)
    end
end

-- Function to spawn vehicle with validation (updated for aircraft)
local function SpawnVehicle(vehicleName, spawnPoint, requiredGrade, vehicleType, vehicleFee, jobName, garageName)
    -- Check grade access first
    if not HasGradeAccess(requiredGrade) then
        ShowNotification('gradeRequired', 2000)
        return
    end
    
    -- Check if player has enough money
    if vehicleFee and vehicleFee > 0 then
        local hasMoney = lib.callback.await('xn_jobgarage:server:checkMoney', false, vehicleFee)
        
        if not hasMoney then
            ShowNotification('insufficientFunds', 2000)
            return
        end
    end
    
    -- Proceed with spawn
    DoSpawnVehicle(vehicleName, spawnPoint, vehicleType, vehicleFee, jobName, garageName)
end

-- Function to delete vehicle
local function DeleteVehicle(jobName, garageName)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    print("^3[DEBUG STORE] DeleteVehicle called - Job: " .. jobName .. ", Garage: " .. garageName .. "^0")
    
    if veh == 0 then
        lib.notify({
            title = 'Lỗi',
            description = 'Bạn phải ngồi trên xe để cất',
            type = 'error'
        })
        return
    end
    
    local plate = GetVehicleNumberPlateText(veh)
    print("^3[DEBUG STORE] Vehicle plate: " .. plate .. "^0")
    local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    
    -- Extract base job name
    local baseJobName = jobName
    if string.find(jobName, "_aircraft") then
        baseJobName = string.gsub(jobName, "_aircraft", "")
    elseif string.find(jobName, "_boat") then
        baseJobName = string.gsub(jobName, "_boat", "")
    end
    baseJobName = string.gsub(baseJobName, "_[0-9]+$", "")
    
    print("^3[DEBUG STORE] Base job: " .. baseJobName .. "^0")
    
    -- Kiểm tra xe có trong SQL và is_out = 0 không
    local canStore = lib.callback.await('xn_jobgarage:server:canStoreVehicle', false, baseJobName, garageName, plate)
    
    print("^3[DEBUG STORE] canStore result: " .. tostring(canStore.success) .. "^0")
    
    if not canStore.success then
        lib.notify({
            title = 'Không Thể Cất Xe',
            description = canStore.reason or 'Xe này không thuộc garage này hoặc đã được cất rồi',
            type = 'error'
        })
        return
    end
    
    -- Get vehicle data to save
    local vehicleMods = lib.getVehicleProperties(veh)
    local bodyHealth = GetVehicleBodyHealth(veh)
    local engineHealth = GetVehicleEngineHealth(veh)
    local fuelLevel = exports['cdn-fuel']:GetFuel(veh) or 100
    
    -- Save vehicle data to server
    TriggerServerEvent('xn_jobgarage:server:storeVehicle', baseJobName, garageName, {
        plate = plate,
        mods = vehicleMods,
        body = bodyHealth,
        engine = engineHealth,
        fuel = fuelLevel
    })
    
    -- Check and delete attached trailer if exists
    local hasTrailer, trailer = GetVehicleTrailerVehicle(veh)
    if (hasTrailer or (trailer and trailer ~= 0 and DoesEntityExist(trailer))) and trailer ~= 0 and DoesEntityExist(trailer) then
        local trailerPlate = GetVehicleNumberPlateText(trailer)
        if trailerPlate then
            pcall(function()
                exports['Renewed-Vehiclekeys']:removeKey(trailerPlate)
            end)
        end
        DeleteEntity(trailer)
    end

    -- Remove keys and delete vehicle
    exports['Renewed-Vehiclekeys']:removeKey(plate)
    DeleteEntity(veh)
    
    -- Clear from spawned vehicles if exists
    if spawnedVehicles[jobName] then
        spawnedVehicles[jobName] = nil
    end
end

-- Function to delete vehicle for FREE spawn (aircraft/boat) - No SQL check
local function DeleteVehicleFree(jobName, garageName)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    print("^3[DEBUG STORE FREE] DeleteVehicleFree called - Job: " .. jobName .. ", Garage: " .. garageName .. "^0")
    
    if veh == 0 then
        lib.notify({
            title = 'Lỗi',
            description = 'Bạn phải ngồi trên xe để cất',
            type = 'error'
        })
        return
    end
    
    local plate = GetVehicleNumberPlateText(veh)
    print("^3[DEBUG STORE FREE] Vehicle plate: " .. plate .. "^0")
    
    -- Check and delete attached trailer if exists
    local hasTrailer, trailer = GetVehicleTrailerVehicle(veh)
    if (hasTrailer or (trailer and trailer ~= 0 and DoesEntityExist(trailer))) and trailer ~= 0 and DoesEntityExist(trailer) then
        local trailerPlate = GetVehicleNumberPlateText(trailer)
        if trailerPlate then
            pcall(function()
                exports['Renewed-Vehiclekeys']:removeKey(trailerPlate)
            end)
        end
        DeleteEntity(trailer)
    end

    -- Remove keys and delete vehicle directly - NO SQL CHECK for aircraft/boat
    exports['Renewed-Vehiclekeys']:removeKey(plate)
    DeleteEntity(veh)
    
    -- Clear from spawned vehicles if exists
    if spawnedVehicles[jobName] then
        spawnedVehicles[jobName] = nil
    end
    
    -- Clear free spawn cache - cho phép lấy xe tiếp
    if freeSpawnActive[jobName] then
        freeSpawnActive[jobName] = nil
        print("^2[DEBUG STORE FREE] Cleared freeSpawnActive cache for: " .. jobName .. "^0")
    end
    
    lib.notify({
        title = 'Cất Xe',
        description = 'Đã cất xe thành công',
        type = 'success'
    })
    
    print("^2[DEBUG STORE FREE] Vehicle deleted successfully^0")
end

-- Function to draw delete marker
local function DrawDeleteMarker(coords)
    DrawMarker(27, coords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 1.0, 255, 0, 0, 150, true, true, 2, false, false, false, false)
end

-- Function to show change vehicle menu (must be defined before ShowVehicleMenu)
ShowChangeVehicleMenu = function(jobName, currentVehicleName)
    local garage = Config.JobGarages[jobName]
    local options = {}
    
    -- Extract base job name
    local baseJobName = jobName
    if string.find(jobName, "_aircraft") then
        baseJobName = string.gsub(jobName, "_aircraft", "")
    elseif string.find(jobName, "_boat") then
        baseJobName = string.gsub(jobName, "_boat", "")
    end
    baseJobName = string.gsub(baseJobName, "_[0-9]+$", "")
    
    table.insert(options, {
        title = 'ℹ️ Chọn Xe Mới',
        description = '⚠️ Dữ liệu xe cũ sẽ bị xóa\n💡 Chọn xe phù hợp với cấp bậc của bạn',
        icon = 'info-circle',
        disabled = true
    })
    
    -- Show all vehicles
    for i, vehicle in ipairs(garage.vehicles) do
        local hasGradeAccess = HasGradeAccess(vehicle.grade or 0)
        local isCurrentVehicle = (currentVehicleName == vehicle.name)
        local vehicleTitle = vehicle.label
        local vehicleDescription = ''
        
        local vehicleIcon = 'car'
        if garage.vehicleType == "aircraft" then
            vehicleIcon = 'plane'
        elseif garage.vehicleType == "boat" then
            vehicleIcon = 'ship'
        end
        
        if isCurrentVehicle then
            vehicleTitle = '⭐ ' .. vehicleTitle .. ' (Xe hiện tại)'
            vehicleDescription = '📌 Đây là xe bạn đang có'
            vehicleIcon = 'check-circle'
            
            table.insert(options, {
                title = vehicleTitle,
                description = vehicleDescription,
                icon = vehicleIcon,
                disabled = true
            })
        else
            -- Build description
            if vehicle.grade and vehicle.grade > 0 then
                vehicleDescription = '⭐ Yêu cầu cấp ' .. vehicle.grade
            else
                vehicleDescription = '✅ Không yêu cầu cấp bậc'
            end
            
            if vehicle.fee and vehicle.fee > 0 then
                vehicleDescription = vehicleDescription .. '\n💰 Phí đổi xe: $' .. vehicle.fee
            else
                vehicleDescription = vehicleDescription .. '\n✅ Miễn phí'
            end
            
            vehicleDescription = vehicleDescription .. '\n\n⚠️ Xe cũ sẽ bị xóa khi đổi'
            
            -- Disable if not enough grade
            local isDisabled = not hasGradeAccess
            if not hasGradeAccess then
                vehicleTitle = vehicleTitle .. ' 🔒'
                vehicleDescription = '🔒 Không đủ cấp bậc (Cần cấp ' .. (vehicle.grade or 0) .. ')'
                vehicleIcon = 'lock'
            end
            
            table.insert(options, {
                title = vehicleTitle,
                description = vehicleDescription,
                icon = vehicleIcon,
                disabled = isDisabled,
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = '⚠️ Xác Nhận Đổi Xe',
                        content = 'Đổi sang: ' .. vehicle.label .. '\n\n⚠️ Dữ liệu xe cũ sẽ bị XÓA hoàn toàn!\n💡 Xe mới sẽ có 100% độ bền\n\nBạn có chắc chắn?',
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = 'Xác Nhận Đổi',
                            cancel = 'Hủy'
                        }
                    })
                    
                    if confirm == 'confirm' then
                        -- Delete old vehicle
                        TriggerServerEvent('xn_jobgarage:server:deleteVehicle', baseJobName, jobName)
                        Wait(200)
                        
                        if Config.Debug then
                            print("[DEBUG] Player changing to vehicle:", vehicle.name)
                        end
                        SpawnVehicle(vehicle.name, garage.spawnPoint, vehicle.grade or 0, garage.vehicleType, vehicle.fee or 0, baseJobName, jobName)
                    end
                    isMenuOpen = false
                end
            })
        end
    end
    
    -- Back button
    
    table.insert(options, {
        title = '← Quay Lại',
        description = 'Quay lại menu chính',
        icon = 'arrow-left',
        onSelect = function()
            isMenuOpen = false
            ShowVehicleMenu(jobName)
        end
    })
    
    lib.registerContext({
        id = 'change_vehicle_' .. jobName,
        title = '🔄 Đổi Xe - ' .. garage.label,
        options = options,
        onExit = function()
            isMenuOpen = false
        end
    })
    
    lib.showContext('change_vehicle_' .. jobName)
end

-- Function to show vehicle menu (updated with vehicle type signs)
ShowVehicleMenu = function(jobName)
    if isMenuOpen then return end
    
    if Config.Debug then
        print("[DEBUG] Opening vehicle menu for job:", jobName)
    end
    
    isMenuOpen = true
    local garage = Config.JobGarages[jobName]
    local options = {}
    
    -- Extract base job name for database
    local baseJobName = jobName
    if string.find(jobName, "_aircraft") then
        baseJobName = string.gsub(jobName, "_aircraft", "")
    elseif string.find(jobName, "_boat") then
        baseJobName = string.gsub(jobName, "_boat", "")
    end
    baseJobName = string.gsub(baseJobName, "_[0-9]+$", "")
    
    -- Add garage type header
    local vehicleTypeConfig = Config.VehicleTypes[garage.vehicleType or "ground"]
    local garageTitle = garage.label
    if vehicleTypeConfig then
        garageTitle = vehicleTypeConfig.label .. " - " .. garage.label
    end
    
    -- KIỂM TRA LOẠI GARAGE: aircraft/boat = spawn tự do, ground = chính chủ
    local isFreeSpawn = garage.vehicleType == "aircraft" or garage.vehicleType == "boat"
    
    if isFreeSpawn then
        -- ========== MENU SPAWN TỰ DO (AIRCRAFT/BOAT) ==========
        local playerGrade = PlayerData.job and PlayerData.job.grade and PlayerData.job.grade.level or 0
        
        -- Kiểm tra xem player đã spawn xe chưa
        local hasActiveVehicle = freeSpawnActive[jobName] ~= nil
        
        if hasActiveVehicle then
            -- Đã có xe đang sử dụng - chỉ hiện nút TRẢ XE
            local activeInfo = freeSpawnActive[jobName]
            local vehicleTypeName = garage.vehicleType == "aircraft" and "máy bay" or "thuyền"
            
            table.insert(options, {
                title = "⚠️ Bạn đang sử dụng " .. vehicleTypeName,
                description = "Biển số: " .. (activeInfo.plate or "N/A") .. "\nHãy trả xe trước khi lấy xe mới",
                icon = "exclamation-triangle",
                iconColor = "orange",
                disabled = true
            })
            
            table.insert(options, {
                title = "🔙 TRẢ " .. string.upper(vehicleTypeName),
                description = "Ngồi trên xe và đến điểm trả để cất xe",
                icon = garage.vehicleType == "aircraft" and "helicopter" or "anchor",
                iconColor = "red"
            })
        else
            -- Chưa có xe - hiện danh sách xe để lấy
            for _, vehicle in ipairs(garage.vehicles) do
                local canAccess = vehicle.grade == nil or vehicle.grade <= playerGrade
                
                table.insert(options, {
                    title = vehicle.label,
                    description = canAccess and "✅ Có thể sử dụng" or ("🔒 Yêu cầu cấp bậc: " .. vehicle.grade),
                    icon = garage.vehicleType == "aircraft" and "helicopter" or "ship",
                    iconColor = canAccess and "green" or "red",
                    disabled = not canAccess,
                    onSelect = function()
                        lib.hideContext(false)
                        isMenuOpen = false
                        -- Spawn trực tiếp không qua SQL
                        SpawnVehicleFree(vehicle.name, garage.spawnPoint, vehicle.grade, garage.vehicleType, vehicle.fee or 0, jobName, baseJobName, vehicle.defaultMods)
                    end
                })
            end
        end
        
        -- BUTTON ĐÓNG
        table.insert(options, {
            title = "❌ ĐÓNG",
            icon = "times",
            onSelect = function()
                isMenuOpen = false
            end
        })
    else
        -- ========== MENU CHÍNH CHỦ (GROUND VEHICLES) ==========
        -- LẤY DANH SÁCH TẤT CẢ XE
        local vehicleList = lib.callback.await('xn_jobgarage:server:getVehicleList', false, baseJobName, jobName)
    
    if Config.Debug then
        print("[DEBUG] Vehicle List Retrieved:")
        print("  Total vehicles:", vehicleList and #vehicleList.vehicles or 0)
    end
    
    -- HIỂN THỊ TỪNG XE
    if vehicleList and vehicleList.vehicles and #vehicleList.vehicles > 0 then
        for _, veh in ipairs(vehicleList.vehicles) do
            -- COPY DỮ LIỆU VÀO LOCAL ĐỂ TRÁNH CLOSURE BUG
            local vehId = veh.id
            local vehVehicle = veh.vehicle
            local vehLabel = veh.vehicle_label or veh.vehicle
            local vehPlate = veh.plate
            local vehBody = veh.body or 1000
            local vehEngine = veh.engine or 1000
            local vehFuel = veh.fuel or 100
            local vehIsOut = veh.is_out
            local vehMods = veh.mods
            
            local bodyPercent = math.floor(vehBody / 10)
            local enginePercent = math.floor(vehEngine / 10)
            local fuelPercent = vehFuel
            local statusIcon = vehIsOut == 0 and "🚨" or "✅"
            local statusText = vehIsOut == 0 and "NGOÀI" or "TRONG"
            
            -- Tạo bản copy vehicle data
            local vehData = {
                id = vehId,
                vehicle = vehVehicle,
                vehicle_label = vehLabel,
                plate = vehPlate,
                body = vehBody,
                engine = vehEngine,
                fuel = vehFuel,
                is_out = vehIsOut,
                mods = vehMods
            }
            
            table.insert(options, {
                title = statusIcon .. " " .. vehLabel,
                description = string.format(
                    "🔖 Biển: %s | 📍 %s\n💪 %d%% | 🔧 %d%% | ⛽ %d%%",
                    vehPlate,
                    statusText,
                    bodyPercent,
                    enginePercent,
                    fuelPercent
                ),
                icon = vehIsOut == 0 and "exclamation-triangle" or "car",
                metadata = {
                    {label = "Trạng thái", value = statusText},
                    {label = "Độ bền", value = bodyPercent .. "%"},
                    {label = "Động cơ", value = enginePercent .. "%"}
                },
                onSelect = function()
                    isMenuOpen = false
                    ShowVehicleActions(jobName, vehData, baseJobName, garage)
                end
            })
        end
    else
        table.insert(options, {
            title = "📭 KHÔNG CÓ XE",
            description = "Bạn chưa có xe nào\n👉 Mua xe mới bên dưới",
            icon = "info-circle",
            disabled = true
        })
    end
    
    -- BUTTON MUA XE MỚI
    table.insert(options, {
        title = "➕ MUA XE MỚI",
        description = "Chọn xe từ danh sách để thêm vào garage",
        icon = "plus-circle",
        iconColor = "green",
        onSelect = function()
            isMenuOpen = false
            ShowAddVehicleMenu(jobName, baseJobName, garage)
        end
    })
    
    -- BUTTON ĐÓNG
    table.insert(options, {
        title = "❌ ĐÓNG",
        description = "Đóng menu",
        icon = "times",
        onSelect = function()
            isMenuOpen = false
        end
    })
    
    end  -- END của if isFreeSpawn else
    
    lib.registerContext({
        id = 'vehicle_list_' .. jobName,
        title = '🚗 ' .. garageTitle,
        options = options,
        onExit = function()
            isMenuOpen = false
        end
    })
    
    lib.showContext('vehicle_list_' .. jobName)
end

-- MENU HÀNH ĐỘNG CHO TỪNG XE
ShowVehicleActions = function(jobName, veh, baseJobName, garage)
    local options = {}
    local vehicleId = veh.id  -- Lưu ID local để tránh closure bug
    
    if veh.is_out == 0 then
        -- XE ĐANG Ở NGOÀI
        options = {
            {
                title = "🚗 LẤY XE",
                description = "⚠️ Xe đang ở ngoài\nCần chuộc xe trước",
                icon = "car",
                disabled = true
            },
            {
                title = "💰 CHUỘC XE",
                description = "Phí chuộc: $" .. (Config.ImpoundCost or 1000) .. "\n⚠️ Xe sẽ còn 30% độ bền",
                icon = "hand-holding-usd",
                iconColor = "yellow",
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = '💰 Xác Nhận Chuộc Xe',
                        content = 'Phí: $' .. (Config.ImpoundCost or 1000) .. '\n\n⚠️ Xe sẽ chỉ còn 30% độ bền!',
                        centered = true,
                        cancel = true
                    })
                    
                    if alert == 'confirm' then
                        -- GỬI VEHICLE ID THAY VÌ JOB/GARAGE
                        local result = lib.callback.await('xn_jobgarage:server:chargeImpound', false, vehicleId)
                        
                        if result.success then
                            lib.notify({title = 'Thành Công', description = 'Xe đã được chuộc!', type = 'success'})
                            Wait(500)
                            ShowVehicleMenu(jobName)
                        else
                            lib.notify({title = 'Lỗi', description = 'Không đủ tiền hoặc có lỗi xảy ra', type = 'error'})
                        end
                    end
                end
            },
            -- NÚt xóa xe đã được tắt
            -- {
            --     title = "🗑️ XÓA XE",
            --     description = "⚠️ Xóa vĩnh viễn xe này",
            --     icon = "trash",
            --     iconColor = "red",
            --     onSelect = function()
            --         local confirm = lib.alertDialog({
            --             header = '⚠️ Xác Nhận Xóa',
            --             content = 'Xóa vĩnh viễn xe ' .. (veh.vehicle_label or veh.vehicle) .. '?',
            --             centered = true,
            --             cancel = true
            --         })
            --         
            --         if confirm == 'confirm' then
            --             TriggerServerEvent('xn_jobgarage:server:deleteVehicleById', veh.id)
            --             Wait(500)
            --             ShowVehicleMenu(jobName)
            --         end
            --     end
            -- },
            {
                title = "← QUAY LẠI",
                icon = "arrow-left",
                onSelect = function()
                    ShowVehicleMenu(jobName)
                end
            }
        }
    else
        -- XE TRONG GARAGE
        options = {
            {
                title = "🚗 LẤY XE",
                description = "Spawn xe ra khỏi garage",
                icon = "car",
                iconColor = "green",
                onSelect = function()
                    -- ĐÓNG MENU NGAY ĐỂ NGĂN CLICK NHIỀU LẦN
                    lib.hideContext(false)
                    isMenuOpen = false
                    SpawnVehicleById(vehicleId, garage.spawnPoint, garage.vehicleType, baseJobName, jobName)
                end
            },
            {
                title = "💰 CHUỘC XE",
                description = "⚠️ Xe đang trong garage\nKhông cần chuộc",
                icon = "hand-holding-usd",
                disabled = true
            },
            -- Nút xóa xe đã được tắt
            -- {
            --     title = "🗑️ XÓA XE",
            --     description = "⚠️ Xóa vĩnh viễn xe này",
            --     icon = "trash",
            --     iconColor = "red",
            --     onSelect = function()
            --         local confirm = lib.alertDialog({
            --             header = '⚠️ Xác Nhận Xóa',
            --             content = 'Xóa vĩnh viễn xe ' .. (veh.vehicle_label or veh.vehicle) .. '?',
            --             centered = true,
            --             cancel = true
            --         })
            --         
            --         if confirm == 'confirm' then
            --             TriggerServerEvent('xn_jobgarage:server:deleteVehicleById', veh.id)
            --             Wait(500)
            --             ShowVehicleMenu(jobName)
            --         end
            --     end
            -- },
            {
                title = "← QUAY LẠI",
                icon = "arrow-left",
                onSelect = function()
                    ShowVehicleMenu(jobName)
                end
            }
        }
    end
    
    lib.registerContext({
        id = 'vehicle_actions_' .. veh.id,
        title = '🎯 ' .. (veh.vehicle_label or veh.vehicle),
        options = options,
        onExit = function()
            isMenuOpen = false
        end
    })
    
    lib.showContext('vehicle_actions_' .. veh.id)
end

-- MENU MUA XE MỚI
ShowAddVehicleMenu = function(jobName, baseJobName, garage)
    local options = {}
    
    -- Lấy grade hiện tại từ PlayerData
    local playerGrade = PlayerData.job and PlayerData.job.grade and PlayerData.job.grade.level or 0
    
    -- Lấy danh sách xe đã mua
    local response = lib.callback.await('xn_jobgarage:server:getVehicleList', false, baseJobName, jobName) or {}
    local ownedVehicles = response.vehicles or {}
    local ownedModels = {}
    for _, v in ipairs(ownedVehicles) do
        ownedModels[v.vehicle] = true
    end
    
    for _, vehicle in ipairs(garage.vehicles) do
        local canBuy = vehicle.grade == nil or vehicle.grade <= playerGrade
        local alreadyOwned = ownedModels[vehicle.name] == true
        
        -- CHỈ HIỂN THỊ XE ĐỦ CẤP BẬC VÀ CHƯA MUA
        if canBuy and not alreadyOwned then
            table.insert(options, {
                title = vehicle.label,
                description = "💰 Phí: $" .. (vehicle.fee or 0),
                icon = "plus",
                iconColor = "green",
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = '✅ Xác Nhận Mua Xe',
                        content = 'Mua ' .. vehicle.label .. '\nPhí: $' .. (vehicle.fee or 0),
                        centered = true,
                        cancel = true
                    })
                    
                    if confirm == 'confirm' then
                        -- Trigger server to add vehicle
                        local result = lib.callback.await('xn_jobgarage:server:addVehicle', false, {
                            jobName = baseJobName,
                            garageName = jobName,
                            vehicleModel = vehicle.name,
                            vehicleLabel = vehicle.label,
                            fee = vehicle.fee or 0,
                            defaultMods = vehicle.defaultMods  -- Gửi defaultMods từ config
                        })
                        
                        if result.success then
                            lib.notify({title = 'Thành Công', description = 'Đã thêm ' .. vehicle.label, type = 'success'})
                            Wait(500)
                            ShowVehicleMenu(jobName)
                        else
                            lib.notify({title = 'Lỗi', description = result.reason or 'Không thể mua xe', type = 'error'})
                        end
                    end
                end
            })
        end
    end
    
    table.insert(options, {
        title = "← QUAY LẠI",
        icon = "arrow-left",
        onSelect = function()
            ShowVehicleMenu(jobName)
        end
    })
    
    lib.registerContext({
        id = 'add_vehicle_' .. jobName,
        title = '➕ Mua Xe Mới',
        options = options,
        onExit = function()
            isMenuOpen = false
        end
    })
    
    lib.showContext('add_vehicle_' .. jobName)
end

-- OLD MENU (kept for backward compatibility - will show error, can be deleted later)
local function ShowVehicleMenu_OLD(jobName)
    if Config.Debug then
        print("[DEBUG] Opening vehicle menu for job:", jobName)
    end
    
    isMenuOpen = true
    local garage = Config.JobGarages[jobName]
    local options = {}
    
    -- Extract base job name for database
    local baseJobName = jobName
    if string.find(jobName, "_aircraft") then
        baseJobName = string.gsub(jobName, "_aircraft", "")
    elseif string.find(jobName, "_boat") then
        baseJobName = string.gsub(jobName, "_boat", "")
    end
    baseJobName = string.gsub(baseJobName, "_[0-9]+$", "")
    
    -- Add garage type header
    local vehicleTypeConfig = Config.VehicleTypes[garage.vehicleType or "ground"]
    local garageTitle = garage.label
    if vehicleTypeConfig then
        garageTitle = vehicleTypeConfig.label .. " - " .. garage.label
    end
    
    -- Check vehicle status in database
    local vehicleStatus = lib.callback.await('xn_jobgarage:server:checkVehicleStatus', false, baseJobName, jobName)
    
    local hasVehicle = vehicleStatus and vehicleStatus.exists
    local isVehicleOut = hasVehicle and vehicleStatus.isOut
    local currentVehicleName = hasVehicle and vehicleStatus.vehicleData.vehicle or nil
    local currentPlate = hasVehicle and vehicleStatus.plate or nil
    
    if Config.Debug then
        print("[DEBUG] Vehicle Status in Menu:")
        print("  Has Vehicle:", hasVehicle)
        if hasVehicle then
            print("  Current Vehicle:", currentVehicleName)
            print("  Plate:", currentPlate)
            print("  Is Out:", isVehicleOut)
            print("  Database is_out value:", vehicleStatus.vehicleData.is_out)
        end
    end
    
    -- If player has a vehicle
    if hasVehicle then
        local vehData = vehicleStatus.vehicleData
        local savedVehicleLabel = currentVehicleName
        
        -- Find the vehicle label
        for i, vehicle in ipairs(garage.vehicles) do
            if vehicle.name == currentVehicleName then
                savedVehicleLabel = vehicle.label
                break
            end
        end
        
        if isVehicleOut then
            -- Header showing vehicle status - CLICKABLE
            local dbIsOut = vehData.is_out or 0
            table.insert(options, {
                title = '📊 TRẠNG THÁI',
                description = '🚗 Xe: ' .. savedVehicleLabel .. '\n🔖 Biển số: ' .. currentPlate .. '\n📍 is_out: ' .. dbIsOut .. ' (Đang ngoài)\n\n👉 Nhấn để xem tùy chọn',
                icon = 'exclamation-circle',
                onSelect = function()
                    isMenuOpen = false
                    -- Show action submenu
                    local actionOptions = {
                        {
                            title = '🚗 LẤY XE RA',
                            description = '🔒 Xe đang ở ngoài\n⚠️ Cần chuộc xe trước',
                            icon = 'car',
                            disabled = true
                        },
                        {
                            title = '💰 CHUỘC XE VỀ GARAGE',
                            description = '⚠️ Phí chuộc: $500\n⚠️ Xe sẽ chỉ còn 30% độ bền!\n\n👉 Nhấn để chuộc xe',
                            icon = 'hand-holding-usd',
                            onSelect = function()
                                local impoundCost = lib.callback.await('xn_jobgarage:server:getImpoundCost', false)
                                
                                local alert = lib.alertDialog({
                                    header = '💰 Xác Nhận Chuộc Xe',
                                    content = 'Xe: ' .. savedVehicleLabel .. '\nBiển số: ' .. currentPlate .. '\n\nPhí chuộc: $' .. impoundCost .. '\n\n⚠️ Xe sẽ chỉ còn 30% độ bền!\n\nBạn có chắc chắn muốn chuộc?',
                                    centered = true,
                                    cancel = true,
                                    labels = {
                                        confirm = 'Chuộc Xe ($' .. impoundCost .. ')',
                                        cancel = 'Hủy'
                                    }
                                })
                                
                                if alert == 'confirm' then
                                    -- Call server callback to charge impound
                                    local result = lib.callback.await('xn_jobgarage:server:chargeImpound', false, baseJobName, jobName)
                                    
                                    if result.success then
                                        lib.notify({
                                            title = 'Thành Công',
                                            description = 'Xe đã được chuộc về garage với phí $' .. result.cost .. '\nBạn có thể lấy xe ngay bây giờ.',
                                            type = 'success'
                                        })
                                        Wait(500)
                                        ShowVehicleMenu(jobName)
                                    else
                                        if result.reason == 'insufficient_funds' then
                                            lib.notify({
                                                title = 'Không Đủ Tiền',
                                                description = 'Bạn cần $' .. result.cost .. ' để chuộc xe\nBạn chỉ có $' .. result.playerMoney,
                                                type = 'error'
                                            })
                                        else
                                            lib.notify({
                                                title = 'Lỗi',
                                                description = 'Không thể chuộc xe. Vui lòng thử lại.',
                                                type = 'error'
                                            })
                                        end
                                    end
                                end
                            end
                        },

                        {
                            title = '← Quay Lại',
                            description = 'Quay lại menu chính',
                            icon = 'arrow-left',
                            onSelect = function()
                                ShowVehicleMenu(jobName)
                            end
                        }
                    }
                    
                    lib.registerContext({
                        id = 'vehicle_action_' .. jobName,
                        title = '🎯 Tùy Chọn - ' .. savedVehicleLabel,
                        options = actionOptions,
                        onExit = function()
                            isMenuOpen = false
                        end
                    })
                    
                    lib.showContext('vehicle_action_' .. jobName)
                end
            })
            
            -- Option to change vehicle (DISABLED when OUT)
            table.insert(options, {
                title = '🔄 ĐỔI XE KHÁC',
                description = '🔒 Xe đang ở ngoài\n⚠️ Chuộc xe trước để đổi xe',
                icon = 'exchange-alt',
                disabled = true
            })
            
        else
            -- Vehicle is IN garage - Show current vehicle info at top
            local bodyPercent = math.floor((vehData.body or 1000) / 10)
            local enginePercent = math.floor((vehData.engine or 1000) / 10)
            local fuelPercent = vehData.fuel or 100
            local dbIsOut = vehData.is_out or 1
            
            -- Header showing vehicle status - CLICKABLE
            table.insert(options, {
                title = '📊 TRẠNG THÁI',
                description = '🚗 Xe: ' .. savedVehicleLabel .. '\n🔖 Biển số: ' .. currentPlate .. '\n📍 is_out: ' .. dbIsOut .. ' (Trong garage)\n💪 Độ bền: ' .. bodyPercent .. '% | 🔧 Động cơ: ' .. enginePercent .. '%\n⛽ Nhiên liệu: ' .. fuelPercent .. '%\n\n👉 Nhấn để xem tùy chọn',
                icon = 'info-circle',
                onSelect = function()
                    isMenuOpen = false
                    -- Show action submenu
                    local actionOptions = {
                        {
                            title = '🚗 LẤY XE RA',
                            description = '👉 Nhấn để lấy xe ' .. savedVehicleLabel,
                            icon = 'car',
                            onSelect = function()
                                if Config.Debug then
                                    print("[DEBUG] Player spawning their saved vehicle:", currentVehicleName)
                                end
                                SpawnVehicle(currentVehicleName, garage.spawnPoint, 0, garage.vehicleType, 0, baseJobName, jobName)
                                isMenuOpen = false
                            end
                        },
                        {
                            title = '💰 CHUỘC XE VỀ GARAGE',
                            description = '🔒 Xe đang trong garage\n⚠️ Không cần chuộc',
                            icon = 'hand-holding-usd',
                            disabled = true
                        },
                        {
                            title = '← Quay Lại',
                            description = 'Quay lại menu chính',
                            icon = 'arrow-left',
                            onSelect = function()
                                ShowVehicleMenu(jobName)
                            end
                        }
                    }
                    
                    lib.registerContext({
                        id = 'vehicle_action_' .. jobName,
                        title = '🎯 Tùy Chọn - ' .. savedVehicleLabel,
                        options = actionOptions,
                        onExit = function()
                            isMenuOpen = false
                        end
                    })
                    
                    lib.showContext('vehicle_action_' .. jobName)
                end
            })
            
            -- Option to change vehicle (upgrade when promoted)
            table.insert(options, {
                title = '🔄 ĐỔI XE KHÁC',
                description = 'Đổi sang xe cao cấp hơn (xóa xe cũ)',
                icon = 'exchange-alt',
                onSelect = function()
                    -- Show submenu to select new vehicle
                    isMenuOpen = false
                    ShowChangeVehicleMenu(jobName, currentVehicleName)
                end
            })
        end
        
    else
        -- No vehicle yet - First time selection
        table.insert(options, {
            title = 'ℹ️ CHỌN XE LẦN ĐẦU',
            description = 'Bạn chưa có xe tại garage này.\nChọn một xe bên dưới để đăng ký.',
            icon = 'info-circle',
            disabled = true
        })
        
        -- Show all vehicles for first-time selection
        for i, vehicle in ipairs(garage.vehicles) do
            local hasGradeAccess = HasGradeAccess(vehicle.grade or 0)
            local vehicleTitle = vehicle.label
            local vehicleDescription = ''
            
            -- Add vehicle type icon
            local vehicleIcon = 'car'
            if garage.vehicleType == "aircraft" then
                vehicleIcon = 'plane'
            elseif garage.vehicleType == "boat" then
                vehicleIcon = 'ship'
            end
            
            -- Build description
            if vehicle.grade and vehicle.grade > 0 then
                vehicleDescription = '⭐ Yêu cầu cấp ' .. vehicle.grade
            else
                vehicleDescription = '✅ Không yêu cầu cấp bậc'
            end
            
            if vehicle.fee and vehicle.fee > 0 then
                vehicleDescription = vehicleDescription .. '\n💰 Phí: $' .. vehicle.fee
            else
                vehicleDescription = vehicleDescription .. '\n✅ Miễn phí'
            end
            
            vehicleDescription = vehicleDescription .. '\n\n📌 Xe này sẽ là xe riêng của bạn'
            
            -- Disable if not enough grade
            if not hasGradeAccess then
                vehicleTitle = vehicleTitle .. ' 🔒'
                vehicleDescription = '🔒 Không đủ cấp bậc (Cần cấp ' .. (vehicle.grade or 0) .. ')'
                vehicleIcon = 'lock'
            end
            
            table.insert(options, {
                title = vehicleTitle,
                description = vehicleDescription,
                icon = vehicleIcon,
                disabled = not hasGradeAccess,
                onSelect = function()
                    if hasGradeAccess then
                        if Config.Debug then
                            print("[DEBUG] Player selected first vehicle:", vehicle.name)
                        end
                        SpawnVehicle(vehicle.name, garage.spawnPoint, vehicle.grade or 0, garage.vehicleType, vehicle.fee or 0, baseJobName, jobName)
                        isMenuOpen = false
                    end
                end
            })
        end
    end
    
    -- Add close option
    
    table.insert(options, {
        title = 'Đóng',
        description = 'Đóng menu garage',
        icon = 'times',
        onSelect = function()
            isMenuOpen = false
        end
    })
    
    lib.registerContext({
        id = 'job_garage_' .. jobName,
        title = garageTitle,
        options = options,
        onExit = function()
            isMenuOpen = false
        end
    })
    
    lib.showContext('job_garage_' .. jobName)
end

-- Function to draw marker with color based on access
local function DrawGarageMarker(coords, hasAccess)
    local r, g, b = 255, 102, 0  -- Default orange
    if hasAccess then
        r, g, b = 0, 255, 0  -- Green for accessible
    else
        r, g, b = 255, 0, 0  -- Red for restricted
    end
    
    DrawMarker(37, coords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 1.5, r, g, b, 100, true, true, 2, false, false, false, false)
end

-- Initialize player data on start
CreateThread(function()
    if Config.Debug then
        print("[DEBUG] Waiting for QBX player data...")
    end
    while not exports.qbx_core:GetPlayerData().job do
        Wait(100)
    end
    PlayerData = exports.qbx_core:GetPlayerData()
    if Config.Debug then
        print("[DEBUG] PlayerData initialized:", PlayerData.job.name)
        print("[DEBUG] OnDuty status:", PlayerData.job.onduty)
    end
    
    -- Wait a bit more to ensure everything is loaded
    Wait(3000)
    
    -- Create initial blips
    CreateJobBlips()
end)

-- Optimized main thread with state management
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local foundNearby = false
        
        -- Clear previous render targets
        renderTargets = {}
        
        for jobName, garage in pairs(Config.JobGarages) do
            local distance = #(playerCoords - garage.drawText)
            local wasInRange = isInRange[jobName]
            local nowInRange = distance < Config.InteractionDistance
            
            -- Update range status
            isInRange[jobName] = nowInRange
            
            if nowInRange then
                foundNearby = true
                sleep = 0
                
                local hasAccess = HasJobAccess(jobName)
                
                -- Add to render targets
                renderTargets[jobName] = {
                    coords = garage.drawText,
                    hasAccess = hasAccess,
                    label = garage.label,
                    distance = distance
                }
            end
        end
        
        -- Adaptive sleep based on proximity
        if foundNearby then
            sleep = 50
        else
            sleep = 1000
        end
        
        Wait(sleep)
    end
end)

-- Separate thread for interaction handling
CreateThread(function()
    while true do
        local sleep = 500
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        -- Check for E key press only when near garages
        for jobName, garage in pairs(Config.JobGarages) do
            local distance = #(playerCoords - garage.drawText)
            
            if distance < Config.UseDistance then
                sleep = 0
                
                local hasAccess = HasJobAccess(jobName)
                
                if hasAccess then
                    -- Check for E key press
                    if IsControlJustPressed(0, Config.InteractionKey) and not isMenuOpen then
                        if Config.Debug then
                            print("[DEBUG] E pressed - Opening menu for:", jobName)
                        end
                        ShowVehicleMenu(jobName)
                        break -- Exit loop to prevent multiple menus
                    end
                end
            end
        end
        
        -- Check if player can store vehicle at any garage
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            for jobName, garage in pairs(Config.JobGarages) do
                local garageCoords = garage.spawnPoint.xyz
                local dist = #(playerCoords - garageCoords)
                
                if dist < 3.0 then
                    sleep = 0
                    local hasAccess = HasJobAccess(jobName)
                    if hasAccess then
                        if IsControlJustPressed(0, Config.InteractionKey) then
                            if Config.Debug then
                                print("[DEBUG] E pressed - Storing vehicle at:", jobName)
                            end
                            -- Check if it's aircraft or boat (free spawn) - no SQL check needed
                            local isFreeSpawn = garage.vehicleType == "aircraft" or garage.vehicleType == "boat"
                            if isFreeSpawn then
                                DeleteVehicleFree(jobName, jobName)
                            else
                                -- Ground vehicle - check SQL ownership
                                DeleteVehicle(jobName, jobName)
                            end
                            break
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Separate rendering thread for markers only
CreateThread(function()
    while true do
        local sleep = 0
        local hasTargets = false
        
        for jobName, target in pairs(renderTargets) do
            hasTargets = true
            
            -- Draw marker only
            DrawGarageMarker(target.coords, target.hasAccess)
        end
        
        -- Draw delete markers when player is in any vehicle near garage
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local playerCoords = GetEntityCoords(ped)
            
            for jobName, garage in pairs(Config.JobGarages) do
                local garageCoords = garage.spawnPoint.xyz
                local dist = #(playerCoords - garageCoords)
                
                if dist < 50.0 then -- Hiển thị marker trong bán kính 50m
                    hasTargets = true
                    DrawDeleteMarker(garageCoords)
                end
            end
        end
        
        if not hasTargets then
            sleep = 100
        end
        
        Wait(sleep)
    end
end)

-- Handle fee charged notification from server
RegisterNetEvent('xn_jobgarage:client:feeCharged', function(amount)
    local notification = Config.Notifications.feeCharged
    lib.notify({
        title = notification.title,
        description = string.format(notification.description, amount),
        type = notification.type
    })
end)

-- Handle vehicle stored notification
RegisterNetEvent('xn_jobgarage:client:vehicleStored', function()
    lib.notify({
        title = 'Xe Đã Cất',
        description = 'Xe của bạn đã được lưu trữ an toàn vào garage',
        type = 'success'
    })
end)

-- Handle impound success
RegisterNetEvent('xn_jobgarage:client:impoundSuccess', function(cost)
    lib.notify({
        title = 'Chuộc Xe Thành Công',
        description = 'Bạn đã trả $' .. cost .. ' để chuộc xe. Xe hiện ở trong garage với 30% độ bền.',
        type = 'success',
        duration = 5000
    })
end)

-- Handle impound failed
RegisterNetEvent('xn_jobgarage:client:impoundFailed', function(reason)
    if reason == 'insufficient_funds' then
        lib.notify({
            title = 'Không Đủ Tiền',
            description = 'Bạn không có đủ tiền để chuộc xe',
            type = 'error'
        })
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        isInRange = {}
        lastNotificationTime = {}
        isMenuOpen = false
        spawnedVehicles = {}
        
        -- Remove all blips
        for _, blip in pairs(jobBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        jobBlips = {}
    end
end)
