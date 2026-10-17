if not lib then return end

local db = require(('bridge.%s.owned_vehicles'):format(Shared.framework))
local Framework = require(('bridge.%s.server'):format(Shared.framework))
local GaragesData = lib.load 'config.garages'
local GeneralConfig = lib.load 'config.general'
local utils = require 'server.functions'
local Interior = lib.load 'config.interior'
local Garages = {}
local PlayerVehicles = {}
local ClassList = lib.load 'config.impound'.ImpoundPrices
local ImpoundConfig = lib.load 'config.impound'

-- Anti-duplicate spawn protection
local PendingGarageSpawns = {} -- Track pending garage vehicle spawns by plate
local PendingImpoundSpawns = {} -- Track pending impound vehicle spawns
local PlayerSpawnLock = {} -- Track if player is currently spawning ANY vehicle
local SPAWN_COOLDOWN = 10 -- Cooldown time in seconds (increased from 5)
local PLAYER_LOCK_TIMEOUT = 15 -- Player lock timeout in seconds

-- HIGH PRECISION: Use GetGameTimer() for millisecond precision (prevents same-second duplicates)
local PendingGarageSpawnsMS = {} -- Track with milliseconds for NUI requests
local SPAWN_COOLDOWN_MS = 5000 -- 5 seconds in milliseconds

-- CRITICAL: Helper function to delete existing vehicles with same vehicleId before spawning
-- This prevents duplicate vehicles from appearing  
-- Uses qbx_vehicles export to find and delete existing vehicle entity
local function DeleteExistingVehiclesByVehicleId(vehicleId)
    if not vehicleId then return 0 end
    
    local deletedCount = 0
    
    -- Method 1: Try qbx_vehicles export (most reliable)
    local success, existingVeh = pcall(function()
        return exports.qbx_vehicles:GetVehicleByVehicleId(vehicleId)
    end)
    
    if success and existingVeh and DoesEntityExist(existingVeh) then
        DeleteEntity(existingVeh)
        deletedCount = deletedCount + 1
        print('^3[ANTI-DUPLICATE]^7 Deleted existing vehicle via qbx_vehicles export | VehicleId: ' .. vehicleId)
    end
    
    -- Method 2: Scan all vehicles for matching entity state (fallback)
    local allVehicles = GetAllVehicles()
    for i = 1, #allVehicles do
        local vehicle = allVehicles[i]
        if DoesEntityExist(vehicle) then
            local entityState = Entity(vehicle).state
            if entityState and entityState.vehicleid and entityState.vehicleid == vehicleId then
                DeleteEntity(vehicle)
                deletedCount = deletedCount + 1
            end
        end
    end
    
    if deletedCount > 0 then
        print('^3[ANTI-DUPLICATE]^7 Total deleted: ' .. deletedCount .. ' vehicle(s) | VehicleId: ' .. vehicleId)
    end
    
    return deletedCount
end

-- Cleanup function: Remove old pending requests every 30 seconds (optimized with SetTimeout)
local function CleanupPendingRequests()
    local currentTime = os.time()
    local currentTimeMS = GetGameTimer()
    local cleanedGarage = 0
    local cleanedImpound = 0
    local cleanedLocks = 0
    local cleanedMS = 0
    
    -- Clean garage spawns older than 60 seconds
    for key, timestamp in pairs(PendingGarageSpawns) do
        if (currentTime - timestamp) > 60 then
            PendingGarageSpawns[key] = nil
            cleanedGarage = cleanedGarage + 1
        end
    end
    
    -- Clean MS-based garage spawns older than 60 seconds (60000 ms)
    for key, timestampMS in pairs(PendingGarageSpawnsMS) do
        if (currentTimeMS - timestampMS) > 60000 then
            PendingGarageSpawnsMS[key] = nil
            cleanedMS = cleanedMS + 1
        end
    end
    
    -- Clean impound spawns older than 60 seconds
    for key, timestamp in pairs(PendingImpoundSpawns) do
        if (currentTime - timestamp) > 60 then
            PendingImpoundSpawns[key] = nil
            cleanedImpound = cleanedImpound + 1
        end
    end
    
    -- Clean player locks older than PLAYER_LOCK_TIMEOUT
    for identifier, timestamp in pairs(PlayerSpawnLock) do
        if (currentTime - timestamp) > PLAYER_LOCK_TIMEOUT then
            PlayerSpawnLock[identifier] = nil
            cleanedLocks = cleanedLocks + 1
        end
    end
    
    if cleanedGarage > 0 or cleanedImpound > 0 or cleanedLocks > 0 or cleanedMS > 0 then
        --print('^3[MH_GARAGE CLEANUP]^7 Cleared ' .. cleanedGarage .. ' garage + ' .. cleanedImpound .. ' impound + ' .. cleanedLocks .. ' player locks + ' .. cleanedMS .. ' MS locks')
    end
    
    -- Schedule next cleanup
    SetTimeout(30000, CleanupPendingRequests)
end

-- Start cleanup cycle
SetTimeout(30000, CleanupPendingRequests)

lib.locale()


MySQL.ready(function()

    local oldTableExists = pcall(MySQL.scalar.await, 'SELECT 1 FROM `uniq_garage` LIMIT 1')
    if oldTableExists then
        MySQL.query('RENAME TABLE `uniq_garage` TO `mh_garage`')
        Wait(200)
    end

    local success, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM `mh_garage` LIMIT 1')

    if not success then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `mh_garage` (
                `owner` varchar(60) DEFAULT NULL,
                `name` varchar(100) NOT NULL,
                `data` longtext DEFAULT NULL,
                UNIQUE KEY `owner` (`owner`,`name`),
                KEY `idx_owner` (`owner`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
        ]])

        --------print('^2[success]^7 database was created successfully!')
    end

    Wait(0)

    -- Load garage data in batches to avoid memory spike
    --print('^3[mh_garage]^7 Loading garage data...')
    -- Intentional: Load all garage data into memory cache at startup
    -- @oxmysql-ignore-warning
    result = MySQL.query.await('SELECT owner, name, data FROM `mh_garage`')

    if result and result[1] then
        local count = 0
        for k,v in pairs(result) do
            local data = json.decode(v.data)

            if not Garages[v.owner] then
                Garages[v.owner] = {}
            end

            Garages[v.owner][v.name] = data
            count = count + 1
        end
        --print('^2[mh_garage]^7 Loaded ' .. count .. ' garage entries')
    end
end)


lib.callback.register('mh_garage:cb:DoesOwn', function(source, garage)
    local identifier = Framework.GetIdentifier(source)

    -- Public garages (price = nil) are accessible to everyone
    if GaragesData[garage] and GaragesData[garage].price == nil then
        return true
    end

    if not Garages[identifier] then
        return false
    end

    return Garages[identifier][garage]
end)


RegisterNetEvent('mh_garage:server:BuyGarage', function(garage, interior)
    local src = source
    local price = GaragesData[garage].price
    local identifier = Framework.GetIdentifier(src)

    if utils.PayPrice(src, price) then
        if not Garages[identifier] then
            Garages[identifier] = {}
        end

        if not Garages[identifier][garage] then
            Garages[identifier][garage] = {}
        end

        Garages[identifier][garage].name = garage
        Garages[identifier][garage].slot = {}
        
        -- Set default style properly for each interior type
        local defaultStyle = {}
        if Interior[interior] and Interior[interior].Customization and Interior[interior].Customization.Default then
            -- Copy the default style from config
            for floor, styles in pairs(Interior[interior].Customization.Default) do
                defaultStyle[tostring(floor)] = {}
                for _, style in ipairs(styles) do
                    table.insert(defaultStyle[tostring(floor)], {
                        name = style.name,
                        type = style.type,
                        color = style.color or nil
                    })
                end
            end
        else
            -- If no default style, create basic style for floor 1
            defaultStyle["1"] = {}
            
            -- Apply LoadDefault function if available
            if Interior[interior] and Interior[interior].Customization and Interior[interior].Customization.LoadDefault then
                -- For interiors with LoadDefault, extract the style from LoadDefault function
                if interior == 'autoshop' then
                    defaultStyle["1"] = {
                        { name = 'entity_set_style_1', type = 'garage_style' },
                        { name = 'entity_set_tints', type = 'garage_tint', color = 0 }
                    }
                elseif interior == 'agency' then
                    defaultStyle["1"] = {
                        { name = 'entity_set_workshop_wall', type = 'wall' }
                    }
                elseif interior == 'hangar' then
                    defaultStyle["1"] = {
                        { name = 'set_tint_shell', color = 1, type = 'tint' },
                        { name = 'set_crane_tint', color = 1, type = 'crane' },
                        { name = 'set_floor_2', type = 'floor' },
                        { name = 'set_floor_decal_1', color = 1, type = 'floor_decal' },
                        { name = 'set_office_basic', type = 'office' },
                        { name = 'set_bedroom_modern', type = 'bedroom' },
                        { name = 'set_bedroom_tint', color = 1, type = 'bedroom_tint' },
                        { name = 'set_bedroom_blinds_open', type = 'blinds' }
                    }
                elseif interior == 'ceo' then
                    defaultStyle["1"] = {
                        { name = 'garage_decor_01', type = 'interior' },
                        { name = 'lighting_option01', type = 'light' },
                        { name = 'numbering_style01_n1', type = 'signage' }
                    }
                elseif interior == 'drugwar' then
                    -- Apply default for all floors
                    for floor = 1, 5 do
                        defaultStyle[tostring(floor)] = {
                            { name = 'entity_set_shell_01', type = 'interior' },
                            { name = 'entity_set_numbers_0' .. floor },
                            { name = 'entity_set_tint_01', type = 'tint', color = 1 }
                        }
                    end
                end
            end
        end
        
        Garages[identifier][garage].style = defaultStyle

        MySQL.insert('INSERT INTO `mh_garage` (owner, name, data) VALUES (?, ?, ?)', { identifier, garage, json.encode(Garages[identifier][garage]) })

        TriggerClientEvent('mh_garage:Notify', src, locale('bought_garage', garage), 'success')
    else
        TriggerClientEvent('mh_garage:Notify', src, locale('no_money'), 'error')
    end
end)

lib.callback.register('mh_garage:cb:BuyCustomization', function(source, data)
    local identifier = Framework.GetIdentifier(source)
    local playerGarage = Garages[identifier] and Garages[identifier][data.garage]
    if not playerGarage then return false end

    -- Ensure style table exists and use string keys for floors
    playerGarage.style = playerGarage.style or {}
    local floorKey = tostring(data.floor)
    playerGarage.style[floorKey] = playerGarage.style[floorKey] or {}
    local floorStyles = playerGarage.style[floorKey]

    -- Check if exact same customization exists
    for _, style in ipairs(floorStyles) do
        if data.interior.color then
            if style.name == data.interior.name and tostring(style.color) == tostring(data.color) then
                TriggerClientEvent('mh_garage:Notify', source, locale('have_customization'), 'error')
                return false
            end
        elseif style.name == data.interior.name then
            TriggerClientEvent('mh_garage:Notify', source, locale('have_customization'), 'error')
            return false
        end
    end

    -- Find price first
    local price
    local interior = Interior[data.int]
    if not interior or not interior.Customization or not interior.Customization.Purchasable then
        return false
    end

    for _, category in pairs(interior.Customization.Purchasable) do
        if category then
            for _, item in pairs(category) do
                if item.label == data.interior.label then
                    price = item.price
                    break
                end
            end
        end
        if price then break end
    end

    if not price or type(price) ~= "number" then return false end

    -- Check money BEFORE making any changes
    if not utils.PayPrice(source, price) then
        TriggerClientEvent('mh_garage:Notify', source, locale('no_money'), 'error')
        return false
    end

    -- Only remove existing style AFTER payment is successful
    for i = #floorStyles, 1, -1 do
        local style = floorStyles[i]
        if style.type == data.interior.type then
            -- Remove existing style of same type to prevent conflicts
            table.remove(floorStyles, i)
        end
    end

    -- Add new customization
    local newStyle = {
        name = data.interior.name,
        color = data.interior.color and data.color or nil,
        type = data.interior.type
    }
    table.insert(floorStyles, newStyle)

    -- Save to DB
    MySQL.execute('UPDATE `mh_garage` SET data = ? WHERE owner = ? AND name = ?', {
        json.encode(playerGarage), identifier, data.garage
    })

    TriggerClientEvent('mh_garage:Notify', source, locale('purchased_customization'), 'success')
    return true
end)


local function isSlotFree(name, identifier)
    if not GaragesData[name] or not Garages[identifier][name].slot then
        return false, false
    end

    local maxFloors = #Interior[GaragesData[name].interior].Vehicles or 1

    for floor = 1, maxFloors do
        if not Garages[identifier][name].slot[floor] then
            Garages[identifier][name].slot[floor] = {}
        end

        for slot = 1, #Interior[GaragesData[name].interior].Vehicles[floor] do
            if not Garages[identifier][name].slot[floor][slot] then
                return floor, slot
            end
        end
    end

    return false, false
end

local function FindSlotByPlate(name, identifier, plate)
    if not GaragesData[name] or not Garages[identifier] or not Garages[identifier][name] or not Garages[identifier][name].slot then
        return false, false
    end

    local maxFloors = #Interior[GaragesData[name].interior].Vehicles or 1
    plate = string.strtrim(plate) -- Ensure plate is trimmed

    for floor = 1, maxFloors do
        if Garages[identifier][name].slot[floor] then
            for slot = 1, #Interior[GaragesData[name].interior].Vehicles[floor] do
                local slotPlate = Garages[identifier][name].slot[floor][slot]
                if slotPlate and string.strtrim(slotPlate) == plate then
                    return floor, slot
                end
            end
        end
    end

    return false, false
end

-- HELPER: Remove a vehicle by plate from ALL garages owned by identifier (both memory and DB)
local function RemoveVehicleFromAllGarages(identifier, plate)
    if not identifier or not plate then return 0 end
    plate = string.strtrim(plate)
    local removedCount = 0
    
    if Garages[identifier] then
        for garageName, garageData in pairs(Garages[identifier]) do
            if garageData.slot then
                local garageModified = false
                for floorNum, slots in pairs(garageData.slot) do
                    if type(slots) == "table" then
                        for slotIdx, slotPlate in pairs(slots) do
                            if slotPlate and string.strtrim(slotPlate) == plate then
                                Garages[identifier][garageName].slot[floorNum][slotIdx] = nil
                                garageModified = true
                                removedCount = removedCount + 1
                            end
                        end
                    end
                end
                
                if garageModified then
                    MySQL.execute('UPDATE `mh_garage` SET data = ? WHERE owner = ? AND name = ?', {
                        json.encode(Garages[identifier][garageName]), identifier, garageName
                    })
                end
            end
        end
    end
    
    if PlayerVehicles[identifier] then
        for garageName, vehicles in pairs(PlayerVehicles[identifier]) do
            if vehicles[plate] then
                PlayerVehicles[identifier][garageName][plate] = nil
            end
        end
    end
    
    return removedCount
end



lib.callback.register('mh_garage:cb:CheckSpawnPoint', function(source, name, plate)
    if not GaragesData[name] then
        ----print('^1[GARAGE ERROR]^7 Garage "' .. tostring(name) .. '" not found in GaragesData')
        return false
    end
    
    if not GaragesData[name].vehicleSpawnPoint then
        ----print('^1[GARAGE ERROR]^7 Garage "' .. name .. '" has no vehicleSpawnPoint configured')
        return false
    end
    
    local spawnPoint = GaragesData[name].vehicleSpawnPoint
    local nearbyVehicles = lib.getNearbyVehicles(vec3(spawnPoint.x, spawnPoint.y, spawnPoint.z), 3.0, false)
    
    if #nearbyVehicles > 0 then
        return false
    end

    return true
end)


RegisterNetEvent('mh_garage:server:TakeVehicleOut', function(name, plate)
    plate = string.strtrim(plate)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    -- CRITICAL: Player-level lock - only allow ONE spawn at a time per player
    if PlayerSpawnLock[identifier] then
        local lockAge = os.time() - PlayerSpawnLock[identifier]
        if lockAge < PLAYER_LOCK_TIMEOUT then
            TriggerClientEvent('mh_garage:Notify', src, 'Vui lòng đợi, xe đang được xử lý... (' .. (PLAYER_LOCK_TIMEOUT - lockAge) .. 's)', 'error')
            --print('^3[ANTI-SPAM]^7 Player ' .. identifier .. ' tried to spawn while locked (age: ' .. lockAge .. 's)')
            return
        end
    end
    
    -- ANTI-DUPLICATE: Check if there's already a pending spawn for this plate
    local spawnKey = identifier .. ':' .. plate
    if PendingGarageSpawns[spawnKey] then
        local timeSinceRequest = os.time() - PendingGarageSpawns[spawnKey]
        if timeSinceRequest < SPAWN_COOLDOWN then
            TriggerClientEvent('mh_garage:Notify', src, 'Xe này đang được lấy ra, vui lòng không spam!', 'error')
            --print('^3[ANTI-SPAM]^7 Blocked duplicate spawn for plate ' .. plate .. ' (within ' .. timeSinceRequest .. 's)')
            return
        end
    end
    
    -- ATOMIC: Mark BOTH locks immediately before any processing
    PlayerSpawnLock[identifier] = os.time()
    PendingGarageSpawns[spawnKey] = os.time()
    
    local floor, slot = FindSlotByPlate(name, identifier, plate)

    if not floor or not slot then 
        PendingGarageSpawns[spawnKey] = nil -- Clear pending
        PlayerSpawnLock[identifier] = nil -- Clear player lock
        TriggerClientEvent('mh_garage:Notify', src, 'Không tìm thấy xe trong garage', 'error')
        return 
    end

    if Garages[identifier][name].slot[floor] and Garages[identifier][name].slot[floor][slot] then
        -- Check if garage has pricetakeout and charge the player
        local pricetakeout = GaragesData[name].pricetakeout or 0
        
        if pricetakeout > 0 then
            -- Check and deduct money
            if not utils.PayPrice(src, pricetakeout) then
                TriggerClientEvent('mh_garage:Notify', src, locale('no_money_takeout', pricetakeout), 'error')
                PendingGarageSpawns[spawnKey] = nil
                PlayerSpawnLock[identifier] = nil
                return
            end
            
            TriggerClientEvent('mh_garage:Notify', src, locale('paid_takeout', pricetakeout), 'info')
        end
        
        -- Get spawn coords
        local spawnCoords = GaragesData[name].vehicleSpawnPoint
        if not spawnCoords then
            --print('^1[MH_GARAGE ERROR]^7 No vehicleSpawnPoint for garage: ' .. name)
            TriggerClientEvent('mh_garage:Notify', src, 'Lỗi spawn vehicle: không tìm thấy vị trí spawn', 'error')
            PendingGarageSpawns[spawnKey] = nil
            PlayerSpawnLock[identifier] = nil
            return
        end
        
        -- GET: vehicleId from plate
        local vehicleId = exports.qbx_vehicles:GetVehicleIdByPlate(plate)
        if not vehicleId then
            --print('^1[MH_GARAGE ERROR]^7 Vehicle ID not found for plate: ' .. plate)
            PendingGarageSpawns[spawnKey] = nil
            PlayerSpawnLock[identifier] = nil
            TriggerClientEvent('mh_garage:Notify', src, 'Không tìm thấy thông tin xe', 'error')
            return
        end
        
        -- GET: Full vehicle data
        local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
        if not playerVehicle then
            --print('^1[MH_GARAGE ERROR]^7 Vehicle data not found for ID: ' .. vehicleId)
            PendingGarageSpawns[spawnKey] = nil
            PlayerSpawnLock[identifier] = nil
            TriggerClientEvent('mh_garage:Notify', src, 'Lỗi dữ liệu xe', 'error')
            return
        end
        
        -- Use plate from database (parameter) - always correct
        local originalPlate = string.strtrim(plate)
        
        -- STEP 1: EXIT GARAGE FIRST - Move player to outside world
        exports.qbx_core:SetPlayerBucket(src, 0)
        Framework.ClearMeta(src, 'garage', nil)
        
        -- STEP 2: PREPARE SPAWN DATA FIRST - Create deep copy to avoid modifying original
        local spawnProps = {}
        for k, v in pairs(playerVehicle.props) do
            if type(v) == 'table' then
                spawnProps[k] = {}
                for k2, v2 in pairs(v) do
                    spawnProps[k][k2] = v2
                end
            else
                spawnProps[k] = v
            end
        end
        
        -- FORCE SET PLATE - Đảm bảo plate chính xác trước spawn
        spawnProps.plate = originalPlate
        
        -- Validate spawn coordinates (ensure it's vec4)
        if type(spawnCoords) ~= 'vector4' then
            spawnCoords = vec4(spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w or 0.0)
        end
        
        -- Validate model hash - MUST be number
        local modelHash = type(spawnProps.model) == 'string' and joaat(spawnProps.model) or spawnProps.model
        if type(modelHash) ~= 'number' then
            --print('^1[MH_GARAGE ERROR]^7 Invalid model hash for plate: ' .. originalPlate .. ' | Model: ' .. tostring(spawnProps.model))
            TriggerClientEvent('mh_garage:Notify', src, 'Lỗi: Model xe không hợp lệ', 'error')
            PendingGarageSpawns[spawnKey] = nil
            PlayerSpawnLock[identifier] = nil
            return
        end
        
        -- STEP 3: Wait for client to prepare (exit interior, teleport to spawn location)
        -- Using callback ensures client is 100% ready before spawning
        local clientReady = lib.callback.await('mh_garage:cb:PrepareVehicleSpawn', src, name, spawnCoords)
        
        if not clientReady then
            --print('^1[MH_GARAGE ERROR]^7 Client not ready for spawn: ' .. originalPlate)
            TriggerClientEvent('mh_garage:Notify', src, 'Lỗi: Client không sẵn sàng', 'error')
            PendingGarageSpawns[spawnKey] = nil
            PlayerSpawnLock[identifier] = nil
            return
        end
        
        -- STEP 4: DELETE any existing vehicles with same vehicleId BEFORE spawning
        -- This is the CRITICAL fix for duplicate vehicle issue
        DeleteExistingVehiclesByVehicleId(vehicleId)
        Wait(50) -- Small delay to ensure deletion is processed
        
        -- STEP 5: SPAWN VEHICLE at coords with WARP to ensure ownership
        -- warp = ped ensures immediate ownership assignment, avoiding timeout
        local ped = GetPlayerPed(src)
        local netId, veh = qbx.spawnVehicle({
            model = modelHash,
            spawnSource = spawnCoords,
            props = spawnProps,  -- Props with guaranteed correct plate
            warp = ped  -- CRITICAL: Warp player into vehicle for immediate ownership
        })
        
        if not netId or not veh then
            --print('^1[MH_GARAGE ERROR]^7 Failed to spawn vehicle: ' .. originalPlate .. ' | Model: ' .. tostring(modelHash) .. ' | Coords: ' .. tostring(spawnCoords))
            TriggerClientEvent('mh_garage:Notify', src, 'Lỗi spawn vehicle', 'error')
            PendingGarageSpawns[spawnKey] = nil
            PlayerSpawnLock[identifier] = nil
            return
        end
        
        -- NOTE: Plate verification is handled by qbx.spawnVehicle via client-side setVehicleProperties
        -- GetVehicleNumberPlateText/SetVehicleNumberPlateText are CLIENT-SIDE ONLY natives
        Wait(50)
        
        -- Set vehicle metadata
        Entity(veh).state:set('vehicleid', vehicleId, false)
        
        -- NOTE: State and slot removal moved to ConfirmVehicleSpawnSuccess callback
        -- This prevents vehicle loss if client fails to complete spawn
        
        -- Send vehicle to client for final setup (teleport near vehicle, give keys)
        -- FIXED: Send vehicle stats (fuel, body, engine) to client for proper restoration
        local vehicleStats = {
            fuelLevel = spawnProps.fuelLevel or 100.0,
            bodyHealth = spawnProps.bodyHealth or 1000.0,
            engineHealth = spawnProps.engineHealth or 1000.0
        }
        -- Send garage info so client can confirm back to server
        TriggerClientEvent('mh_garage:client:CompleteVehicleSpawn', src, netId, originalPlate, vehicleStats, name, floor, slot)
        
        -- NOTE: Pending spawn flag cleared in ConfirmVehicleSpawnSuccess after client confirms
        
        --print('^2[GARAGE SPAWN SUCCESS]^7 Player ' .. identifier .. ' spawned vehicle: ' .. originalPlate)
    else
        -- Clear pending spawn flag if garage slot not found
        PendingGarageSpawns[spawnKey] = nil
        PlayerSpawnLock[identifier] = nil
    end
end)

-- CALLBACK: Client confirms successful vehicle spawn - NOW we can safely update database
RegisterNetEvent('mh_garage:server:ConfirmVehicleSpawnSuccess', function(plate, garageName, floor, slot)
    plate = string.strtrim(plate)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local spawnKey = identifier .. ':' .. plate
    
    -- Get vehicle entity to update state
    local vehicles = GetAllVehicles()
    local veh = nil
    for _, vehicle in ipairs(vehicles) do
        local vehPlate = string.strtrim(GetVehicleNumberPlateText(vehicle))
        if vehPlate == plate then
            veh = vehicle
            break
        end
    end
    
    if veh then
        -- NOW it's safe to update vehicle state to OUT
        exports.qbx_vehicles:SaveVehicle(veh, {
            state = 0 -- VehicleState.OUT
        })
    end
    
    -- CRITICAL: Update database to set state=0 AND clear garage field
    db.UpdateStored(plate, identifier, 0)
    
    -- Remove from all garage slots and caches + persist to mh_garage table
    RemoveVehicleFromAllGarages(identifier, plate)
    
    -- Clear pending spawn flag after client confirms success
    PendingGarageSpawns[spawnKey] = nil
    PlayerSpawnLock[identifier] = nil
    
    --print('^2[GARAGE STATE UPDATED]^7 Player ' .. identifier .. ' confirmed spawn: ' .. plate)
end)

RegisterNetEvent('mh_garage:server:TakeVehicleOutPhone', function(name, plate)
    plate = string.strtrim(plate)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    -- ANTI-DUPLICATE: Check if there's already a pending spawn for this plate
    local spawnKey = identifier .. ':' .. plate
    if PendingGarageSpawns[spawnKey] then
        local timeSinceRequest = os.time() - PendingGarageSpawns[spawnKey]
        if timeSinceRequest < SPAWN_COOLDOWN then
            TriggerClientEvent('mh_garage:Notify', src, 'Vui lòng đợi, xe đang được lấy ra...', 'error')
            return
        end
    end
    
    -- Mark this spawn as pending
    PendingGarageSpawns[spawnKey] = os.time()
    
    -- Find the vehicle in ANY garage (ignore the 'name' parameter if it's "unknown")
    local actualGarageName = nil
    local floor = nil
    local slot = nil
    
    if Garages[identifier] then
        for gName, gData in pairs(Garages[identifier]) do
            if gData.slot then
                for fNum, fSlots in pairs(gData.slot) do
                    for sIdx, sPlate in pairs(fSlots) do
                        if sPlate and string.strtrim(sPlate) == plate then
                            actualGarageName = gName
                            floor = fNum
                            slot = sIdx
                            break
                        end
                    end
                    if actualGarageName then break end
                end
                if actualGarageName then break end
            end
        end
    end

    if not actualGarageName or not floor or not slot then 
        PendingGarageSpawns[spawnKey] = nil -- Clear pending
        return 
    end

    -- Use the actual garage name we found, not the parameter
    if Garages[identifier][actualGarageName].slot[floor] and Garages[identifier][actualGarageName].slot[floor][slot] then
        -- Charge phone takeout fee (fixed price from config)
        local phoneTakeoutPrice = GeneralConfig.PhoneTakeoutPrice or 0
        
        if phoneTakeoutPrice > 0 then
            -- Check and deduct money
            if not utils.PayPrice(src, phoneTakeoutPrice) then
                TriggerClientEvent('mh_garage:Notify', src, locale('no_money_takeout', phoneTakeoutPrice), 'error')
                PendingGarageSpawns[spawnKey] = nil -- Clear pending on payment failure
                return
            end
            
            TriggerClientEvent('mh_garage:Notify', src, locale('paid_takeout', phoneTakeoutPrice), 'info')
        end
        
        -- Update database FIRST: set state=0 AND clear garage field
        db.UpdateStored(plate, identifier, 0)
        
        exports.qbx_core:SetPlayerBucket(src, 0)
        Framework.ClearMeta(src, 'garage', nil)

        -- TriggerClientEvent('mh_garage:client:TakeVehicleOut', src, name, PlayerVehicles[identifier][name][plate])

        -- CRITICAL: Remove vehicle from ALL garage slots in memory and database
        RemoveVehicleFromAllGarages(identifier, plate)
        TriggerClientEvent('mh_garage:Notify', src, 'Xe đã được lấy ra hoàn toàn khỏi tất cả garage', 'success')
        
        -- Clear pending spawn flag after success
        PendingGarageSpawns[spawnKey] = nil
    else
        -- Clear pending spawn flag if vehicle not found
        PendingGarageSpawns[spawnKey] = nil
    end
end)

lib.callback.register('mh_garage:cb:GetImpoundPrice', function(source, vehicleClass, modelName, vehicleId)
    local price
    
    --------print("=== PRICE CALLBACK DEBUG ===")
    --------print("Plate:", vehicleId)
    --------print("Model:", modelName)
    --------print("Class:", vehicleClass)
    
    -- Use new calculateImpoundFee function if available
    if ImpoundConfig.calculateImpoundFee and modelName then
        price = ImpoundConfig.calculateImpoundFee(vehicleId, modelName)
        --------print("Dynamic price result:", price)
        
        -- If dynamic pricing failed, use class-based fallback
        if not price or price == 1000 then
            --------print("Dynamic failed, using class fallback")
            price = ClassList[vehicleClass] or 1000
            --------print("Class-based price:", price)
        end
    else
        -- Fallback to old class-based pricing
        price = ClassList[vehicleClass] or 1000
        --------print("No dynamic pricing, class price:", price)
    end
    
    --------print("Final returned price:", price)
    --------print("============================")
    return price
end)

lib.callback.register('mh_garage:cb:HasMoney', function(source, vehicleClass, modelName, vehicleId, clientCalculatedPrice)
    local identifier = Framework.GetIdentifier(source)
    local plate = string.strtrim(vehicleId) -- vehicleId is actually the plate
    
    -- ANTI-DUPLICATE: Check if there's already a pending impound spawn for this plate
    local spawnKey = identifier .. ':' .. plate
    if PendingImpoundSpawns[spawnKey] then
        local timeSinceRequest = os.time() - PendingImpoundSpawns[spawnKey]
        if timeSinceRequest < SPAWN_COOLDOWN then
            return false -- Block duplicate request
        end
    end
    
    -- Mark this spawn as pending
    PendingImpoundSpawns[spawnKey] = os.time()
    
    -- ═══════════════════════════════════════════════════════
    -- KIỂM TRA LOCK XE - CHẶN CHUỘT TỪ IMPOUND TRONG 30 PHÚT
    -- ═══════════════════════════════════════════════════════
    local cleanPlate = string.gsub(plate, "%s+", "")
    local successQuery, lockTime = pcall(function()
        return MySQL.scalar.await(
            'SELECT dismantle_lock_time FROM player_vehicles WHERE plate = ? OR plate = ?',
            { plate, cleanPlate }
        )
    end)
    
    if not successQuery then
        lockTime = nil
    end
    
    if lockTime and lockTime > 0 then
        local currentTime = os.time()
        local elapsedTime = currentTime - lockTime
        local lockDuration = 1800 -- 30 phút = 1800 giây
        
        if elapsedTime < lockDuration then
            -- Tính thời gian còn lại
            local remainingSeconds = lockDuration - elapsedTime
            local remainingMinutes = math.ceil(remainingSeconds / 60)
            
            -- Thông báo và reject
            TriggerClientEvent('mh_garage:Notify', source, 
                string.format('⛔ Xe đang bị khóa! Còn %d phút nữa mới có thể chuột từ kho xe thất lạc.', remainingMinutes), 
                'error'
            )
            
            print(string.format('[mh_garage] 🔒 BLOCKED impound retrieval - Plate: %s | Remaining: %d minutes', plate, remainingMinutes))
            
            -- Clear pending spawn
            PendingImpoundSpawns[spawnKey] = nil
            return false
        else
            -- Đã hết thời gian lock, xóa lock
            pcall(function()
                MySQL.update('UPDATE player_vehicles SET dismantle_lock_time = NULL WHERE plate = ? OR plate = ?',
                    { plate, cleanPlate }
                )
            end)
            print(string.format('[mh_garage] 🔓 Lock expired for plate: %s', plate))
        end
    end
    
    -- ALWAYS calculate price server-side (ignore client price to prevent exploits)
    local price
    if ImpoundConfig.calculateImpoundFee and modelName then
        price = ImpoundConfig.calculateImpoundFee(vehicleId, modelName)
        
        -- If dynamic pricing failed, use class-based fallback
        if not price or price == 1000 then
            price = ClassList[vehicleClass] or 1000
        end
    else
        -- Fallback to old class-based pricing
        price = ClassList[vehicleClass] or 1000
    end
    
    -- Check if player has enough money and process payment
    local success = utils.PayPrice(source, price)
    
    if success then
        -- PAYMENT SUCCESSFUL - Now handle vehicle retrieval logic
        ----print('^2[IMPOUND RETRIEVE]^7 ' .. Framework.GetName(source) .. ' paid $' .. price .. ' for vehicle: ' .. plate .. ' (Model: ' .. (modelName or 'Unknown') .. ')')
        
        -- Transfer 70% of impound fee to mechanic fund
        -- local mechanicShare = math.floor(price * 0.7)
        -- local transferSuccess = pcall(function()
        --     exports['Renewed-Banking']:addAccountMoney('mechanic', mechanicShare)
        -- end)
        
        -- if transferSuccess then
        --     ------print('^2[MECHANIC FUND]^7 Transferred $' .. mechanicShare .. ' (70% of $' .. price .. ') to mechanic fund from impound fee')
        -- else
        --     ------print('^1[MECHANIC FUND ERROR]^7 Failed to transfer $' .. mechanicShare .. ' to mechanic fund - Renewed-Banking not available')
        -- end
        
        -- Step 1: Delete ALL existing vehicles with this plate from world
        local deletedCount = db.DeleteWorldVehiclesByPlate(plate)
        if deletedCount > 0 then
            --------print('^3[IMPOUND]^7 Deleted ' .. deletedCount .. ' duplicate vehicles with plate: ' .. plate)
        end
        
        -- Step 2: Update vehicle state to 1 (stored) temporarily
        -- This prevents the vehicle from appearing in impound list again immediately
        db.UpdateStored(plate, identifier, 1)
        
        -- Step 3: Clear any garage slots and caches for this vehicle (memory and database)
        RemoveVehicleFromAllGarages(identifier, plate)
        
        --------print('^2[IMPOUND]^7 Vehicle ' .. plate .. ' prepared for spawn - duplicates cleared, state updated')
    else
        --------print('^1[IMPOUND]^7 ' .. Framework.GetName(source) .. ' insufficient funds for vehicle: ' .. plate .. ' (Required: $' .. price .. ')')
        PendingImpoundSpawns[spawnKey] = nil -- Clear pending on failure
    end
    
    return success
end)

-- Handle final impound retrieve completion
RegisterNetEvent('mh_garage:server:ImpoundRetrieveComplete', function(plate, impoundIndex)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    plate = string.strtrim(plate)
    
    -- GET: vehicleId from plate
    local vehicleId = exports.qbx_vehicles:GetVehicleIdByPlate(plate)
    if not vehicleId then
        --print('^1[MH_GARAGE ERROR]^7 Vehicle ID not found for plate: ' .. plate)
        TriggerClientEvent('mh_garage:Notify', src, 'Không tìm thấy xe', 'error')
        return
    end
    
    -- GET: Full vehicle data
    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if not playerVehicle then
        --print('^1[MH_GARAGE ERROR]^7 Vehicle data not found for ID: ' .. vehicleId)
        TriggerClientEvent('mh_garage:Notify', src, 'Lỗi dữ liệu xe', 'error')
        return
    end
    
    -- Get spawn coords from impound config
    local impoundCfg = lib.load('config.impound')
    if not impoundCfg.Locations[impoundIndex] or not impoundCfg.Locations[impoundIndex].spawns then
        --print('^1[MH_GARAGE ERROR]^7 Invalid impound location: ' .. impoundIndex)
        TriggerClientEvent('mh_garage:Notify', src, 'Lỗi: vị trí impound không hợp lệ', 'error')
        return
    end
    
    -- Request client to find free spawn and trigger callback
    TriggerClientEvent('mh_garage:client:SpawnImpoundVehicle', src, vehicleId, impoundIndex)
end)

-- Server-side impound vehicle spawn
-- Converted to client-side spawning to avoid qbx.spawnVehicle duplicates
lib.callback.register('mh_garage:cb:SpawnImpoundVehicle', function(source, vehicleId, spawnCoords)
    local src = source
    local identifier = Framework.GetIdentifier(src)

    if not vehicleId or not spawnCoords then
        return false
    end

    -- GET: Full vehicle data
    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if not playerVehicle then
        return false
    end

    -- Get plate and ensure it's valid
    local originalPlate = string.strtrim(playerVehicle.props.plate or '')
    if originalPlate == '' then
        return false
    end

    -- Deep‑copy props so we can apply impound damage without mutating cache
    local damagedProps = {}
    for k, v in pairs(playerVehicle.props) do
        if type(v) == 'table' then
            damagedProps[k] = {}
            for k2, v2 in pairs(v) do
                damagedProps[k][k2] = v2
            end
        else
            damagedProps[k] = v
        end
    end

    -- Apply impound damage
    damagedProps.bodyHealth = 300.0
    damagedProps.engineHealth = 300.0
    damagedProps.tankHealth = 200.0
    damagedProps.doors = {}
    for i = 0, 5 do
        if math.random(1, 100) <= 80 then
            damagedProps.doors[i] = true
        end
    end
    damagedProps.plate = originalPlate

    -- Normalize coords
    if type(spawnCoords) ~= 'vector4' then
        spawnCoords = vec4(spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w or 0.0)
    end

    -- Validate model
    local modelHash = type(damagedProps.model) == 'string' and joaat(damagedProps.model) or damagedProps.model
    if type(modelHash) ~= 'number' then
        return false
    end

    -- delete existing vehicles with same id before asking client to spawn
    DeleteExistingVehiclesByVehicleId(vehicleId)
    Wait(50)

    -- Prepare spawn request id and store metadata for callback
    local currentTimeMS = GetGameTimer()
    local spawnRequestId = identifier .. ':' .. originalPlate .. ':' .. tostring(currentTimeMS)
    PendingSpawnRequests = PendingSpawnRequests or {}
    PendingSpawnRequests[spawnRequestId] = {
        src = src,
        identifier = identifier,
        plate = originalPlate,
        vehicleId = vehicleId,
        impound = true,
        spawnKey = identifier .. ':' .. originalPlate,
        spawnKeyMS = nil,
        timestamp = os.time()
    }

    -- send request to client to perform the actual CreateVehicle call
    TriggerClientEvent('mh_garage:client:SpawnVehicleNUI', src, damagedProps, spawnCoords, originalPlate, vehicleId, spawnRequestId)

    -- wait for client to report result (timeout after 5 seconds)
    local waited = 0
    while PendingSpawnRequests[spawnRequestId] and not PendingSpawnRequests[spawnRequestId].handled and waited < 100 do
        Wait(50)
        waited = waited + 1
    end

    local result = PendingSpawnRequests[spawnRequestId]
    if result and result.success then
        -- clear pending impound flag as well
        local spawnKey = identifier .. ':' .. originalPlate
        if PendingImpoundSpawns[spawnKey] then
            PendingImpoundSpawns[spawnKey] = nil
        end
        -- remove request entry
        PendingSpawnRequests[spawnRequestId] = nil
        return result.netId, originalPlate
    end

    -- failure or timeout
    PendingSpawnRequests[spawnRequestId] = nil
    -- clear impound pending in case we timed out
    local spawnKey = identifier .. ':' .. originalPlate
    if PendingImpoundSpawns[spawnKey] then
        PendingImpoundSpawns[spawnKey] = nil
    end
    return false
end)

-- ============================
-- DEPOT (XE BỊ TẠM GIAM) SECTION
-- ============================

lib.callback.register('mh_garage:cb:GetDepotList', function(source)
    local identifier = Framework.GetIdentifier(source)
    local vehicles = db.GetDepotList(identifier)
    return vehicles
end)

-- Get all vehicles for recover menu
lib.callback.register('mh_garage:cb:GetRecoverList', function(source)
    local identifier = Framework.GetIdentifier(source)
    local vehicles = db.GetAllVehiclesForRecover(identifier)
    return vehicles
end)

-- Check if player has money for recover (same price as impound)
lib.callback.register('mh_garage:cb:HasMoneyRecover', function(source, modelName, plate)
    local identifier = Framework.GetIdentifier(source)
    plate = string.strtrim(plate)

    -- Check vehicle state
    local vehicle = MySQL.query.await(
        'SELECT `state` FROM `player_vehicles` WHERE `citizenid` = ? AND `plate` = ?',
        { identifier, plate }
    )

    if not vehicle or not vehicle[1] then
        return false
    end

    -- Block if state = 2 (impounded by police)
    if vehicle[1].state == 2 then
        return false
    end

    -- Anti-duplicate check
    local spawnKey = 'recover:' .. identifier .. ':' .. plate
    if PendingImpoundSpawns[spawnKey] then
        local timeSince = os.time() - PendingImpoundSpawns[spawnKey]
        if timeSince < SPAWN_COOLDOWN then
            return false
        end
    end
    PendingImpoundSpawns[spawnKey] = os.time()

    -- ═══════════════════════════════════════════════════════
    -- KIỂM TRA LOCK XE - CHẶN CHUỘT XE LỖI TRONG 30 PHÚT
    -- ═══════════════════════════════════════════════════════
    local cleanPlate = string.gsub(plate, "%s+", "")
    local lockTime = MySQL.scalar.await(
        'SELECT dismantle_lock_time FROM player_vehicles WHERE plate = ? OR plate = ?',
        { plate, cleanPlate }
    )
    
    if lockTime and lockTime > 0 then
        local currentTime = os.time()
        local elapsedTime = currentTime - lockTime
        local lockDuration = 1800 -- 30 phút = 1800 giây
        
        if elapsedTime < lockDuration then
            -- Tính thời gian còn lại
            local remainingSeconds = lockDuration - elapsedTime
            local remainingMinutes = math.ceil(remainingSeconds / 60)
            
            -- Thông báo và reject
            TriggerClientEvent('mh_garage:Notify', source, 
                string.format('⛔ Xe đang bị khóa! Còn %d phút nữa mới có thể chuộc xe lỗi.', remainingMinutes), 
                'error'
            )
            
            print(string.format('[mh_garage] 🔒 BLOCKED recover retrieval - Plate: %s | Remaining: %d minutes', plate, remainingMinutes))
            
            -- Clear pending spawn
            PendingImpoundSpawns[spawnKey] = nil
            return false
        else
            -- Đã hết thời gian lock, xóa lock
            MySQL.update('UPDATE player_vehicles SET dismantle_lock_time = NULL WHERE plate = ? OR plate = ?',
                { plate, cleanPlate }
            )
            print(string.format('[mh_garage] 🔓 Lock expired for plate: %s', plate))
        end
    end

    -- Calculate price using impound config (same as normal impound)
    local price = 1000 -- Default
    if ImpoundConfig.calculateImpoundFee and modelName then
        price = ImpoundConfig.calculateImpoundFee(plate, modelName)
    end

    -- Check if player has enough money and process payment
    local success = utils.PayPrice(source, price)
    
    if success then
        print('^2[RECOVER]^7 ' .. Framework.GetName(source) .. ' paid $' .. price .. ' to recover vehicle: ' .. plate)
    else
        PendingImpoundSpawns[spawnKey] = nil
    end
    
    return success
end)

-- Handle recover vehicle completion (similar to depot)
RegisterNetEvent('mh_garage:server:RecoverVehicleComplete', function(plate, impoundIndex)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    plate = string.strtrim(plate)

    -- Get vehicleId from plate
    local vehicleId = exports.qbx_vehicles:GetVehicleIdByPlate(plate)
    if not vehicleId then
        TriggerClientEvent('mh_garage:Notify', src, 'Không tìm thấy xe', 'error')
        return
    end

    -- Check vehicle state again
    local vehicle = MySQL.query.await(
        'SELECT `state` FROM `player_vehicles` WHERE `citizenid` = ? AND `plate` = ?',
        { identifier, plate }
    )

    if not vehicle or not vehicle[1] then
        TriggerClientEvent('mh_garage:Notify', src, 'Xe không tồn tại', 'error')
        return
    end

    -- Block if state = 2 (impounded by police)
    if vehicle[1].state == 2 then
        TriggerClientEvent('mh_garage:Notify', src, '⚠️ Xe đang bị tạm giam!\n\nVui lòng sử dụng mục "Xe bị tạm giam" để chuộc xe.', 'error')
        return
    end

    -- Delete existing vehicles with same plate from world
    local deletedCount = db.DeleteWorldVehiclesByPlate(plate)
    if deletedCount > 0 then
        print('^3[RECOVER]^7 Deleted ' .. deletedCount .. ' duplicate vehicles with plate: ' .. plate)
    end

    -- NOTE: State update moved to SpawnVehicleResult callback after client confirms successful spawn
    -- This prevents vehicle loss if spawn fails or player disconnects
    -- MySQL.execute('UPDATE `player_vehicles` SET `state` = 0 WHERE `plate` = ?', { plate })

    -- Spawn vehicle using same method as impound/depot
    TriggerClientEvent('mh_garage:client:SpawnImpoundVehicle', src, vehicleId, impoundIndex)
end)

lib.callback.register('mh_garage:cb:HasMoneyDepot', function(source, modelName, plate)
    local identifier = Framework.GetIdentifier(source)
    plate = string.strtrim(plate)

    local spawnKey = 'depot:' .. identifier .. ':' .. plate
    if PendingImpoundSpawns[spawnKey] then
        local timeSince = os.time() - PendingImpoundSpawns[spawnKey]
        if timeSince < SPAWN_COOLDOWN then
            return false
        end
    end
    PendingImpoundSpawns[spawnKey] = os.time()

    -- ═══════════════════════════════════════════════════════
    -- KIỂM TRA LOCK XE - CHẶN CHUỘT XE BỊ TẠM GIAM TRONG 30 PHÚT
    -- ═══════════════════════════════════════════════════════
    local cleanPlate = string.gsub(plate, "%s+", "")
    local lockTime = MySQL.scalar.await(
        'SELECT dismantle_lock_time FROM player_vehicles WHERE plate = ? OR plate = ?',
        { plate, cleanPlate }
    )
    
    if lockTime and lockTime > 0 then
        local currentTime = os.time()
        local elapsedTime = currentTime - lockTime
        local lockDuration = 1800 -- 30 phút = 1800 giây
        
        if elapsedTime < lockDuration then
            -- Tính thời gian còn lại
            local remainingSeconds = lockDuration - elapsedTime
            local remainingMinutes = math.ceil(remainingSeconds / 60)
            
            -- Thông báo và reject
            TriggerClientEvent('mh_garage:Notify', source, 
                string.format('⛔ Xe đang bị khóa! Còn %d phút nữa mới có thể chuộc xe bị tạm giam.', remainingMinutes), 
                'error'
            )
            
            print(string.format('[mh_garage] 🔒 BLOCKED depot retrieval - Plate: %s | Remaining: %d minutes', plate, remainingMinutes))
            
            -- Clear pending spawn
            PendingImpoundSpawns[spawnKey] = nil
            return false
        else
            -- Đã hết thời gian lock, xóa lock
            MySQL.update('UPDATE player_vehicles SET dismantle_lock_time = NULL WHERE plate = ? OR plate = ?',
                { plate, cleanPlate }
            )
            print(string.format('[mh_garage] 🔓 Lock expired for plate: %s', plate))
        end
    end

    local fee = ImpoundConfig.DepotFee or 2000
    local success = utils.PayPrice(source, fee)

    if not success then
        PendingImpoundSpawns[spawnKey] = nil
    end

    return success
end)

RegisterNetEvent('mh_garage:server:DepotRetrieveComplete', function(plate, impoundIndex)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    plate = string.strtrim(plate)

    local vehicleId = exports.qbx_vehicles:GetVehicleIdByPlate(plate)
    if not vehicleId then
        TriggerClientEvent('mh_garage:Notify', src, 'Không tìm thấy xe', 'error')
        return
    end

    -- NOTE: State update moved to SpawnVehicleResult callback after client confirms successful spawn
    -- This prevents vehicle loss if spawn fails or player disconnects
    -- Release vehicle from police impound: set state=0 (out/world)
    -- MySQL.execute('UPDATE `player_vehicles` SET `state` = 0 WHERE `citizenid` = ? AND `plate` = ? AND `state` = 2',
    --     { identifier, plate })

    -- ✅ TRIGGER mini-mdt để cập nhật status trong mini_mdt_vehicle_impound
    TriggerEvent('mini-mdt:server:releaseImpound', plate)

    -- Also update the police_impound table status if it exists (mark as park-out)
    pcall(function()
        MySQL.execute('UPDATE `police_impound` SET `status` = 1 WHERE `vehicle_plate` = ? AND `status` != 1',
            { plate })
    end)

    -- Spawn like a normal impound vehicle
    local impoundCfg = lib.load('config.impound')
    if not impoundCfg.Locations[impoundIndex] or not impoundCfg.Locations[impoundIndex].spawns then
        TriggerClientEvent('mh_garage:Notify', src, 'Lỗi: vị trí impound không hợp lệ', 'error')
        return
    end

    TriggerClientEvent('mh_garage:client:SpawnImpoundVehicle', src, vehicleId, impoundIndex)
end)

RegisterNetEvent('mh_garage:server:UpdateBucket', function()
    local src = source
    exports.qbx_core:SetPlayerBucket(src, src)
end)


-- Anti-duplicate protection: Track pending store requests
local PendingStoreRequests = {}

lib.callback.register('mh_garage:cb:CanStore', function(source, garage, plate, class, properties)
    if GaragesData[garage] then
        local identifier = Framework.GetIdentifier(source)
        plate = string.strtrim(plate)
        
        -- HOUSE GARAGE OWNER CHECK: Kiểm tra xem có phải house garage không
        if garage:find('^house_') then
            -- Extract houseId từ garage name format: house_{houseId} (houseId có thể là slum_9, mansion_1, etc.)
            local houseId = garage:match('^house_(.+)$')
            if houseId then
                -- Kiểm tra xem player có phải owner của nhà không (KHÔNG cho phép người có key)
                local isOwner = exports.qbx_housing:IsOwner(identifier, houseId)
                if not isOwner then
                    -- Không phải owner - từ chối cất xe
                    --print('^3[MH_GARAGE]^7 Player ' .. identifier .. ' tried to store vehicle in house_' .. houseId .. ' but is NOT owner')
                    TriggerClientEvent('mh_garage:Notify', source, 'Bạn không có quyền cất xe ở đây. Chỉ chủ nhà mới có thể cất xe vào garage này.', 'error')
                    -- Return true với empty message để không trigger notify thứ 2 ở client
                    return false, ''
                else
                    --print('^2[MH_GARAGE]^7 Player ' .. identifier .. ' is OWNER of house_' .. houseId .. ' - allowing store')
                end
            end
        end
        
        -- ANTI-DUPLICATE: Check if there's already a pending store request for this plate
        local requestKey = identifier .. ':' .. plate
        if PendingStoreRequests[requestKey] then
            local timeSinceRequest = os.time() - PendingStoreRequests[requestKey]
            if timeSinceRequest < 5 then -- Block duplicate requests within 5 seconds
                ----print('^3[ANTI-DUPLICATE]^7 Blocked duplicate store request for plate ' .. plate .. ' from ' .. Framework.GetName(source) .. ' (within ' .. timeSinceRequest .. 's)')
                return false, 'request_in_progress'
            end
        end
        
        -- Mark this request as pending
        PendingStoreRequests[requestKey] = os.time()

        if lib.table.contains(GaragesData[garage].blackListClass, class) then
            PendingStoreRequests[requestKey] = nil -- Clear pending
            return false, 'cant_store_here'
        end

        -- AUTO-CREATE GARAGE: If price = nil (free garage), auto-create garage ownership on first vehicle store
        if not Garages[identifier] or not Garages[identifier][garage] then
            local garagePrice = GaragesData[garage].price
            
            if garagePrice == nil then
                -- Free garage - auto-create ownership
                if not Garages[identifier] then
                    Garages[identifier] = {}
                end
                
                if not Garages[identifier][garage] then
                    Garages[identifier][garage] = {}
                end
                
                Garages[identifier][garage].name = garage
                Garages[identifier][garage].slot = {}
                
                -- Set default style for the interior
                local interior = GaragesData[garage].interior
                local defaultStyle = {}
                if Interior[interior] and Interior[interior].Customization and Interior[interior].Customization.Default then
                    for floor, styles in pairs(Interior[interior].Customization.Default) do
                        defaultStyle[tostring(floor)] = {}
                        for _, style in ipairs(styles) do
                            table.insert(defaultStyle[tostring(floor)], {
                                name = style.name,
                                type = style.type,
                                color = style.color or nil
                            })
                        end
                    end
                else
                    defaultStyle["1"] = {}
                end
                
                Garages[identifier][garage].style = defaultStyle
                
                -- Save to database
                MySQL.insert('INSERT INTO `mh_garage` (owner, name, data) VALUES (?, ?, ?)', { 
                    identifier, garage, json.encode(Garages[identifier][garage]) 
                })
                
                TriggerClientEvent('mh_garage:Notify', source, locale('auto_imported_garage', garage), 'success')
            else
                -- Paid garage - user must buy it first
                PendingStoreRequests[requestKey] = nil -- Clear pending
                return false, 'doesnt_own'
            end
        end

        local owner = db.GetVehicleOwner(plate)

        if not owner then
            PendingStoreRequests[requestKey] = nil -- Clear pending
            return false, 'doesnt_own2'
        end

        if owner == identifier then
            -- CRITICAL: Check if target garage has free slot BEFORE deleting vehicle or modifying DB
            -- This prevents vehicle loss if garage is full
            local floor, slot = isSlotFree(garage, identifier)
            
            if type(slot) ~= "number" then
                -- Garage is full - DO NOT delete vehicle
                PendingStoreRequests[requestKey] = nil
                ----print('^1[STORE BLOCKED]^7 Garage \"' .. garage .. '\" is FULL - vehicle ' .. plate .. ' NOT deleted')
                return false, 'garage_full'
            end

            -- AUTO-CLEANUP: If vehicle is still recorded in another garage (or previous slot in mh_garage),
            -- purge it from all garage slots (both memory Garages and database mh_garage table)
            RemoveVehicleFromAllGarages(identifier, plate)

            -- Re-check free slot in target garage to get the most accurate slot position after cleanup
            floor, slot = isSlotFree(garage, identifier)
            if type(slot) ~= "number" then
                PendingStoreRequests[requestKey] = nil
                return false, 'garage_full'
            end
            
            -- Garage has space - safe to delete duplicates and store
            local deletedCount = db.DeleteWorldVehiclesByPlate(plate)
            if deletedCount > 0 then
                ----print('^3[STORE]^7 Deleted ' .. deletedCount .. ' duplicate vehicle(s) with plate: ' .. plate)
            end

            -- Store vehicle in database FIRST before adding to slot
            local cb = db.StoreVehicle(plate, garage, properties, GaragesData[garage].type)
            
            if cb > 0 then
                -- Only add to slot after successful database update
                Garages[identifier][garage].slot[floor][slot] = plate
                
                -- CRITICAL: Save garage slots to database immediately to ensure persistence
                MySQL.execute('UPDATE `mh_garage` SET data = ? WHERE owner = ? AND name = ?', {
                    json.encode(Garages[identifier][garage]), identifier, garage
                })
                
                -- FORCE CLEAR PlayerVehicles cache to ensure fresh data on next query
                if PlayerVehicles[identifier] and PlayerVehicles[identifier][garage] then
                    PlayerVehicles[identifier][garage] = {}
                    ----print('^3[STORE]^7 Cleared PlayerVehicles cache for garage: ' .. garage)
                end
                
                -- Clear pending request after successful store
                PendingStoreRequests[requestKey] = nil
                
                -- Wait a moment for database to fully commit (critical for synchronization)
                Wait(150)
                
                -- Trigger client-side garage refresh if player is in garage
                TriggerClientEvent('mh_garage:client:RefreshGarageDisplay', source, garage)
                
                ----print('^2[STORE SUCCESS]^7 Stored vehicle ' .. plate .. ' in garage "' .. garage .. '" | Floor: ' .. floor .. ' | Slot: ' .. slot)
                return true
            else
                -- Database update failed
                PendingStoreRequests[requestKey] = nil
                ----print('^1[STORE ERROR]^7 Failed to update database for plate: ' .. plate)
                return false, 'store_failed'
            end
        end
    else
        return false, 'something_wrong'
    end
end)


lib.callback.register('mh_garage:cb:GetImpoundList', function(source, index)
    local identifier = Framework.GetIdentifier(source)
    local vehicles = db.GetImpoundList(index, identifier)

    return vehicles
end)


lib.callback.register('mh_garage:cb:GetStyle', function(source, garage, floor)
    local identifier = Framework.GetIdentifier(source)
    local garageData = Garages[identifier] and Garages[identifier][garage]
    
    if not garageData or not garageData.style then
        return {}
    end
    
    -- Handle both old and new data format
    local style = garageData.style
    
    -- Old format: style = [[...]] or style = [...]
    if type(style) == 'table' and style[1] and type(style[1]) == 'table' then
        -- Convert old format to new format on the fly
        local newStyle = {}
        if style[1] and type(style[1]) == 'table' and style[1][1] then
            -- Format: [[...]]
            newStyle["1"] = style[1]
        else
            -- Format: [...]
            newStyle["1"] = style
        end
        
        -- Update in memory and database
        garageData.style = newStyle
        MySQL.execute('UPDATE `mh_garage` SET data = ? WHERE owner = ? AND name = ?', {
            json.encode(garageData), identifier, garage
        })
        
        return newStyle[tostring(floor)] or {}
    end
    
    -- New format: style = {["1"] = [...]}
    return style[tostring(floor)] or {}
end)


lib.callback.register('mh_garage:cb:GetGarageVehicles', function(source, garage, floor)
    local identifier = Framework.GetIdentifier(source)
    
    ----print('^5[CALLBACK DEBUG]^7 GetGarageVehicles called | Garage: "' .. tostring(garage) .. '" | Floor: ' .. tostring(floor) .. ' | Source: ' .. source)
    
    -- Safety checks
    if not identifier then
        ----print('^1[GARAGE ERROR]^7 No identifier for source:', source)
        return {}, {}
    end
    
    if not garage then
        ----print('^1[GARAGE ERROR]^7 No garage name provided')
        return {}, {}
    end
    
    if not Garages[identifier] then
        ----print('^1[GARAGE ERROR]^7 No garages found for identifier:', identifier)
        return {}, {}
    end
    
    ----print('^5[CALLBACK DEBUG]^7 Checking if garage exists in Garages[identifier]...')
    
    -- Debug: List all garages for this player
    local garageList = {}
    for garageName, _ in pairs(Garages[identifier]) do
        table.insert(garageList, '"' .. garageName .. '"')
    end
    ----print('^5[CALLBACK DEBUG]^7 Available garages: ' .. table.concat(garageList, ', '))

    if Garages[identifier][garage] then
        if not PlayerVehicles[identifier] then
            PlayerVehicles[identifier] = {}
        end

        if not PlayerVehicles[identifier][garage] then
            PlayerVehicles[identifier][garage] = {}
        end

        -- ALWAYS refresh vehicle data from database to ensure data integrity
        local vehicles = db.GetPlayerVehicles(identifier, garage)
        
        -- Count vehicles from database
        local vehicleCount = 0
        for _ in pairs(vehicles or {}) do
            vehicleCount = vehicleCount + 1
        end
        
        ----print('^2[GET VEHICLES]^7 Garage: "' .. garage .. '" | Identifier: ' .. identifier .. ' | Vehicles from DB: ' .. vehicleCount)
        
        if vehicles then
            -- Clear and rebuild cache with fresh data
            PlayerVehicles[identifier][garage] = {}
            for plate, mods in pairs(vehicles) do
                PlayerVehicles[identifier][garage][plate] = mods
                ------print('^2[GET VEHICLES]^7 Loaded vehicle: ' .. plate .. ' | Model: ' .. (mods.model or 'unknown'))
            end
        -- else
        --     ----print('^3[GET VEHICLES]^7 No vehicles returned from database for garage: ' .. garage)
        end

        -- AUTO DUPLICATE DETECTION AND FIX when loading garage
        local duplicateFixed = false
        local duplicateCount = 0
        local missingVehicleFixed = false
        local missingCount = 0
        
        -- Check for duplicates and missing vehicles in garage slots
        if Garages[identifier][garage].slot then
            for floorNum, slots in pairs(Garages[identifier][garage].slot) do
                if type(slots) == "table" then
                    local plateCount = {}
                    local duplicatePlates = {}
                    local cleanedSlots = {}
                    local seenPlates = {}
                    
                    -- Count occurrences of each plate
                    for i, plate in ipairs(slots) do
                        local cleanPlate = string.strtrim(plate)
                        plateCount[cleanPlate] = (plateCount[cleanPlate] or 0) + 1
                    end
                    
                    -- Find duplicates
                    for plate, count in pairs(plateCount) do
                        if count > 1 then
                            duplicatePlates[plate] = count
                            duplicateCount = duplicateCount + (count - 1)
                        end
                    end
                    
                    -- Process slots: remove duplicates and verify vehicles exist in database
                    for i, plate in ipairs(slots) do
                        local cleanPlate = string.strtrim(plate)
                        
                        -- Skip if already seen (removes duplicates)
                        if not seenPlates[cleanPlate] then
                            -- Verify vehicle exists in database
                            if PlayerVehicles[identifier][garage][cleanPlate] then
                                table.insert(cleanedSlots, cleanPlate)
                                seenPlates[cleanPlate] = true
                            else
                                -- Vehicle in slot but not in database - remove it
                                missingVehicleFixed = true
                                missingCount = missingCount + 1
                                ----print('^3[GARAGE VERIFY]^7 Removed missing vehicle from slot: ' .. cleanPlate .. ' in garage "' .. garage .. '"')
                            end
                        end
                    end
                    
                    -- Update slots if anything changed
                    if next(duplicatePlates) or missingVehicleFixed then
                        Garages[identifier][garage].slot[floorNum] = cleanedSlots
                        duplicateFixed = true
                    end
                end
            end
        end
        
        -- Save to database if any fixes were made
        if duplicateFixed or missingVehicleFixed then
            local garageData = json.encode(Garages[identifier][garage])
            MySQL.execute('INSERT INTO mh_garage (owner, name, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
                identifier, garage, garageData
            })
            
            local playerName = Framework.GetName(source)
            local message = ''
            
            if duplicateCount > 0 then
                message = message .. duplicateCount .. ' xe trùng lặp'
            end
            
            if missingCount > 0 then
                if message ~= '' then message = message .. ' và ' end
                message = message .. missingCount .. ' xe không tồn tại'
            end
            
            ----print('^2[AUTO GARAGE FIX]^7 ' .. playerName .. ' - Đã sửa ' .. message .. ' trong garage "' .. garage .. '"')
            
            -- Notify player
            TriggerClientEvent('mh_garage:Notify', source, 
                'Đã tự động sửa ' .. message .. ' trong garage', 'success')
        end

        -- Get slot data for requested floor
        local floorIndex = tonumber(floor) or 1
        local slotData = {}
        
        if Garages[identifier][garage].slot then
            if Garages[identifier][garage].slot[floorIndex] then
                slotData = Garages[identifier][garage].slot[floorIndex]
            else
                local floorKey = tostring(floorIndex)
                if Garages[identifier][garage].slot[floorKey] then
                    slotData = Garages[identifier][garage].slot[floorKey]
                end
            end
        end

        return PlayerVehicles[identifier][garage], slotData
    else
        ----print('^3[GARAGE ERROR]^7 Garage not found:', garage, '| Identifier:', identifier)
        ----print('^3[GARAGE ERROR]^7 Available garages:', json.encode(Garages[identifier] and table.unpack(Garages[identifier]) or 'none'))
        return {}, {}
    end
end)

-- Callback: Get list of all vehicles in garage for menu display
lib.callback.register('mh_garage:cb:GetGarageVehicleList', function(source, garageName)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier or not garageName then
        return {}
    end
    
    if not Garages[identifier] or not Garages[identifier][garageName] then
        return {}
    end
    
    -- Get vehicles from database
    local vehicles = db.GetPlayerVehicles(identifier, garageName)
    if not vehicles then
        return {}
    end
    
    -- Build vehicle list with plate and model info
    local vehicleList = {}
    
    -- Collect all plates from all floors
    if Garages[identifier][garageName].slot then
        for floorNum, slots in pairs(Garages[identifier][garageName].slot) do
            if type(slots) == "table" then
                for _, plate in ipairs(slots) do
                    local cleanPlate = string.strtrim(plate)
                    if vehicles[cleanPlate] then
                        local vehicleData = vehicles[cleanPlate]
                        table.insert(vehicleList, {
                            plate = cleanPlate,
                            model = vehicleData.model,
                            props = vehicleData
                        })
                    end
                end
            end
        end
    end
    
    return vehicleList
end)

-- Player self-fix garage callback
lib.callback.register('mh_garage:cb:FixPlayerGarage', function(source, garageName)
    local identifier = Framework.GetIdentifier(source)
    local playerName = Framework.GetName(source)
    
    if not garageName or garageName == '' then
        return { success = false, error = 'Invalid garage name' }
    end
    
    local fixedCount = 0
    local details = {}
    
    local success, result = pcall(function()
        -- Get all player's vehicles with state=1 in this garage
        local dbVehicles
        local isQBCore = Shared.qb == true
        
        if isQBCore then
            dbVehicles = MySQL.query.await('SELECT citizenid, plate, garage, mods FROM player_vehicles WHERE citizenid = ? AND garage = ? AND state = 1', {identifier, garageName})
        else
            dbVehicles = MySQL.query.await('SELECT owner, plate, garage, vehicle FROM owned_vehicles WHERE owner = ? AND garage = ? AND stored = 1', {identifier, garageName})
        end
        
        ------print('^6[PLAYER GARAGE FIX]^7 ' .. playerName .. ' fixing garage "' .. garageName .. '" - Found ' .. #dbVehicles .. ' vehicles')
        
        -- Initialize garage structure if needed
        if not Garages[identifier] then
            Garages[identifier] = {}
        end
        if not Garages[identifier][garageName] then
            Garages[identifier][garageName] = { slot = {}, style = { ['1'] = {} }, name = garageName }
        end
        
        -- Initialize PlayerVehicles
        if not PlayerVehicles[identifier] then
            PlayerVehicles[identifier] = {}
        end
        if not PlayerVehicles[identifier][garageName] then
            PlayerVehicles[identifier][garageName] = {}
        end
        
        -- Process each vehicle
        for i, vehicle in ipairs(dbVehicles) do
            local plate = string.strtrim(vehicle.plate)
            local mods = isQBCore and vehicle.mods or vehicle.vehicle
            local vehicleData = json.decode(mods)
            
            -- Check if missing from PlayerVehicles
            if not PlayerVehicles[identifier][garageName][plate] then
                -- Add to PlayerVehicles cache
                vehicleData.plate = plate
                PlayerVehicles[identifier][garageName][plate] = vehicleData
                
                -- Add to garage slots (nested array format)
                if not Garages[identifier][garageName].slot[1] then
                    Garages[identifier][garageName].slot[1] = {}
                end
                
                -- Check if not already in slot array
                local foundInSlots = false
                for j, slotPlate in ipairs(Garages[identifier][garageName].slot[1]) do
                    if slotPlate == plate then
                        foundInSlots = true
                        break
                    end
                end
                
                if not foundInSlots then
                    table.insert(Garages[identifier][garageName].slot[1], plate)
                    ------print('^6[PLAYER GARAGE FIX]^7 Added ' .. plate .. ' to slot array position: ' .. #Garages[identifier][garageName].slot[1])
                else
                    ------print('^3[PLAYER GARAGE FIX]^7 ' .. plate .. ' already exists in slot array')
                end
                
                fixedCount = fixedCount + 1
                -- Get vehicle model name (hash or string)
                local modelName = 'Unknown'
                if vehicleData.model then
                    if type(vehicleData.model) == "string" then
                        modelName = vehicleData.model
                    else
                        -- Convert hash to string representation
                        modelName = tostring(vehicleData.model)
                    end
                end
                table.insert(details, 'Fixed: ' .. plate .. ' (' .. modelName .. ')')
            end
        end
        
        -- Save to database if any fixes were made
        if fixedCount > 0 then
            local garageData = json.encode(Garages[identifier][garageName])
            MySQL.execute('INSERT INTO mh_garage (owner, name, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
                identifier, garageName, garageData
            })
            
            ------print('^2[PLAYER GARAGE FIX]^7 ' .. playerName .. ' fixed ' .. fixedCount .. ' vehicles in garage "' .. garageName .. '"')
        else
            ------print('^3[PLAYER GARAGE FIX]^7 ' .. playerName .. ' - No issues found in garage "' .. garageName .. '"')
        end
    end)
    
    if not success then
        ------print('^1[PLAYER GARAGE FIX ERROR]^7 ' .. playerName .. ' - Error: ' .. tostring(result))
        return { success = false, error = tostring(result) }
    end
    
    return { 
        success = true, 
        fixed = fixedCount,
        details = details
    }
end)

-- Get vehicles for fix menu
lib.callback.register('mh_garage:cb:GetFixableVehicles', function(source, garageName)
    local identifier = Framework.GetIdentifier(source)
    local playerName = Framework.GetName(source)
    
    if not garageName or garageName == '' then
        return {}
    end
    
    local vehicles = {}
    local isQBCore = Shared.qb == true
    
    ----print('^4[GET FIXABLE VEHICLES]^7 Player: ' .. playerName .. ' | Garage: "' .. garageName .. '"')
    
    local success, result = pcall(function()
        -- Get all player's vehicles in this garage from database
        local dbVehicles
        if isQBCore then
            dbVehicles = MySQL.query.await('SELECT plate, mods FROM player_vehicles WHERE citizenid = ? AND garage = ? AND state = 1', {identifier, garageName})
        else
            dbVehicles = MySQL.query.await('SELECT plate, vehicle FROM owned_vehicles WHERE owner = ? AND garage = ? AND stored = 1', {identifier, garageName})
        end
        
        ----print('^4[GET FIXABLE VEHICLES]^7 Found ' .. #dbVehicles .. ' vehicles in database')
        
        -- Also get garage slot data to compare
        local garageSlots = {}
        local totalSlots = 0
        if Garages[identifier] and Garages[identifier][garageName] and Garages[identifier][garageName].slot then
            for floorNum, slots in pairs(Garages[identifier][garageName].slot) do
                if type(slots) == "table" then
                    for i, plate in ipairs(slots) do
                        garageSlots[string.strtrim(plate)] = true
                        totalSlots = totalSlots + 1
                        ----print('^3[GARAGE SLOTS]^7 Floor ' .. floorNum .. ' has plate: "' .. plate .. '"')
                    end
                end
            end
        end
        
        ----print('^4[GET FIXABLE VEHICLES]^7 Garage has ' .. totalSlots .. ' plates in slots')
        
        for i, vehicle in ipairs(dbVehicles) do
            local plate = string.strtrim(vehicle.plate)
            local mods = isQBCore and vehicle.mods or vehicle.vehicle
            local vehicleData = json.decode(mods)
            
            -- Get vehicle name from model
            local modelName = 'Unknown'
            if vehicleData.model then
                if type(vehicleData.model) == "string" then
                    modelName = vehicleData.model
                else
                    -- Try to get vehicle name from hash safely
                    local success, name = pcall(function()
                        return GetDisplayNameFromVehicleModel(vehicleData.model)
                    end)
                    if success and name and name ~= 'NULL' and name ~= '' then
                        modelName = name
                    else
                        modelName = tostring(vehicleData.model)
                    end
                end
            end
            
            ----print('^2[VEHICLE FOUND]^7 Plate: "' .. plate .. '" | Model: ' .. modelName .. ' | In Garage Slots: ' .. (garageSlots[plate] and 'YES' or 'NO'))
            
            table.insert(vehicles, {
                plate = plate,
                model = vehicleData.model,
                name = modelName,
                mods = vehicleData
            })
        end
        
        -- Check for missing vehicles (in garage slots but not in database)
        for plate, _ in pairs(garageSlots) do
            local foundInDB = false
            for i, vehicle in ipairs(vehicles) do
                if vehicle.plate == plate then
                    foundInDB = true
                    break
                end
            end
            
            if not foundInDB then
                ----print('^1[MISSING VEHICLE]^7 Plate "' .. plate .. '" is in garage slots but NOT found in database!')
                
                -- Add as unknown vehicle for fixing
                table.insert(vehicles, {
                    plate = plate,
                    model = 'Unknown',
                    name = 'Missing Vehicle (' .. plate .. ')',
                    mods = nil,
                    missing = true
                })
            end
        end
    end)
    
    if not success then
        ----print('^1[GET FIXABLE VEHICLES ERROR]^7 Error: ' .. tostring(result))
        return {}
    end
    
    ----print('^2[GET FIXABLE VEHICLES]^7 Returning ' .. #vehicles .. ' vehicles total')
    return vehicles
end)

-- Fix specific vehicle
lib.callback.register('mh_garage:cb:FixSpecificVehicle', function(source, garageName, plate)
    local identifier = Framework.GetIdentifier(source)
    local playerName = Framework.GetName(source)
    
    if not garageName or garageName == '' or not plate or plate == '' then
        return { success = false, error = 'Invalid parameters' }
    end
    
    local success, result = pcall(function()
        -- Get specific vehicle from database
        local dbVehicle
        local isQBCore = Shared.qb == true
        
        if isQBCore then
            dbVehicle = MySQL.single.await('SELECT plate, mods FROM player_vehicles WHERE citizenid = ? AND garage = ? AND plate = ? AND state = 1', {identifier, garageName, plate})
        else
            dbVehicle = MySQL.single.await('SELECT plate, vehicle FROM owned_vehicles WHERE owner = ? AND garage = ? AND plate = ? AND stored = 1', {identifier, garageName, plate})
        end
        
        if not dbVehicle then
            return { success = false, error = 'Vehicle not found in database' }
        end
        
        local cleanPlate = string.strtrim(dbVehicle.plate)
        local mods = isQBCore and dbVehicle.mods or dbVehicle.vehicle
        local vehicleData = json.decode(mods)
        
        -- Initialize structures if needed
        if not Garages[identifier] then
            Garages[identifier] = {}
        end
        if not Garages[identifier][garageName] then
            Garages[identifier][garageName] = { slot = {}, style = { ['1'] = {} }, name = garageName }
        end
        if not PlayerVehicles[identifier] then
            PlayerVehicles[identifier] = {}
        end
        if not PlayerVehicles[identifier][garageName] then
            PlayerVehicles[identifier][garageName] = {}
        end
        
        local fixed = false
        
        -- Check if missing from PlayerVehicles
        if not PlayerVehicles[identifier][garageName][cleanPlate] then
            vehicleData.plate = cleanPlate
            PlayerVehicles[identifier][garageName][cleanPlate] = vehicleData
            fixed = true
        end
        
        -- Ensure garage slot structure exists
        if not Garages[identifier][garageName].slot[1] then
            Garages[identifier][garageName].slot[1] = {}
        end
        
        -- Check if not in slot array
        local foundInSlots = false
        for j, slotPlate in ipairs(Garages[identifier][garageName].slot[1]) do
            if slotPlate == cleanPlate then
                foundInSlots = true
                break
            end
        end
        
        if not foundInSlots then
            table.insert(Garages[identifier][garageName].slot[1], cleanPlate)
            fixed = true
        end
        
        -- Save to database if any fixes were made
        if fixed then
            local garageData = json.encode(Garages[identifier][garageName])
            MySQL.execute('INSERT INTO mh_garage (owner, name, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
                identifier, garageName, garageData
            })
            
            -- IMPORTANT: Clear cache to force fresh data on next request
            if PlayerVehicles[identifier] and PlayerVehicles[identifier][garageName] then
                -- Force reload from database by clearing cache
                PlayerVehicles[identifier][garageName] = nil
            end
            
            ----print('^2[SPECIFIC VEHICLE FIX]^7 ' .. playerName .. ' fixed vehicle ' .. cleanPlate .. ' in garage "' .. garageName .. '" - Cache cleared')
        end
        
        return { 
            success = true, 
            fixed = fixed,
            refreshNeeded = fixed,
            plate = cleanPlate
        }
    end)
    
    if not success then
        ----print('^1[SPECIFIC VEHICLE FIX ERROR]^7 ' .. playerName .. ' - Error: ' .. tostring(result))
        return { success = false, error = tostring(result) }
    end
    
    return result
end)

-- Fix missing vehicle (remove from garage slots)
lib.callback.register('mh_garage:cb:FixMissingVehicle', function(source, garageName, plate)
    local identifier = Framework.GetIdentifier(source)
    local playerName = Framework.GetName(source)
    
    if not garageName or garageName == '' or not plate or plate == '' then
        return { success = false, error = 'Invalid parameters' }
    end
    
    local success, result = pcall(function()
        local cleanPlate = string.strtrim(plate)
        
        ----print('^3[FIX MISSING VEHICLE]^7 ' .. playerName .. ' removing missing vehicle "' .. cleanPlate .. '" from garage "' .. garageName .. '"')
        
        -- Initialize structures if needed
        if not Garages[identifier] then
            Garages[identifier] = {}
        end
        if not Garages[identifier][garageName] then
            return { success = false, error = 'Garage not found' }
        end
        
        local removed = false
        
        -- Remove from garage slots
        if Garages[identifier][garageName].slot then
            for floorNum, slots in pairs(Garages[identifier][garageName].slot) do
                if type(slots) == "table" then
                    for i = #slots, 1, -1 do
                        if string.strtrim(slots[i]) == cleanPlate then
                            table.remove(slots, i)
                            removed = true
                            ----print('^2[FIX MISSING VEHICLE]^7 Removed "' .. cleanPlate .. '" from floor ' .. floorNum .. ' slot ' .. i)
                        end
                    end
                end
            end
        end
        
        -- Remove from PlayerVehicles cache if exists
        if PlayerVehicles[identifier] and PlayerVehicles[identifier][garageName] and PlayerVehicles[identifier][garageName][cleanPlate] then
            PlayerVehicles[identifier][garageName][cleanPlate] = nil
            ----print('^2[FIX MISSING VEHICLE]^7 Removed "' .. cleanPlate .. '" from PlayerVehicles cache')
        end
        
        -- Save to database if any changes were made
        if removed then
            local garageData = json.encode(Garages[identifier][garageName])
            MySQL.execute('INSERT INTO mh_garage (owner, name, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
                identifier, garageName, garageData
            })
            
            ----print('^2[FIX MISSING VEHICLE]^7 Successfully removed missing vehicle "' .. cleanPlate .. '" from garage "' .. garageName .. '"')
        else
            ----print('^3[FIX MISSING VEHICLE]^7 Vehicle "' .. cleanPlate .. '" was not found in garage slots')
        end
        
        return { 
            success = true, 
            removed = removed,
            plate = cleanPlate
        }
    end)
    
    if not success then
        ----print('^1[FIX MISSING VEHICLE ERROR]^7 ' .. playerName .. ' - Error: ' .. tostring(result))
        return { success = false, error = tostring(result) }
    end
    
    return result
end)

-- Force refresh garage vehicles callback (ignores cache)
lib.callback.register('mh_garage:cb:ForceRefreshGarage', function(source, garage, floor)
    local identifier = Framework.GetIdentifier(source)

    if not Garages[identifier] or not Garages[identifier][garage] then
        return {}, {}
    end

    -- Force clear cache for this garage
    if PlayerVehicles[identifier] and PlayerVehicles[identifier][garage] then
        PlayerVehicles[identifier][garage] = {}
    end

    if not PlayerVehicles[identifier] then
        PlayerVehicles[identifier] = {}
    end

    if not PlayerVehicles[identifier][garage] then
        PlayerVehicles[identifier][garage] = {}
    end

    -- Force reload from database
    local vehicles = db.GetPlayerVehicles(identifier, garage)
    local dbVehicleCount = 0
    
    if vehicles then
        for plate, mods in pairs(vehicles) do
            PlayerVehicles[identifier][garage][plate] = mods
            dbVehicleCount = dbVehicleCount + 1
        end
    end

    -- Debug slot data properly
    local floorIndex = tonumber(floor) or 1
    local slotData = {}
    
    if Garages[identifier][garage].slot then
        if Garages[identifier][garage].slot[floorIndex] then
            slotData = Garages[identifier][garage].slot[floorIndex]
        end
    end

    ------print('^2[FORCE REFRESH]^7 ' .. identifier .. ' - Garage: "' .. garage .. '" | DB Vehicles: ' .. dbVehicleCount .. ' | Slots: ' .. json.encode(slotData))

    return PlayerVehicles[identifier][garage], slotData
end)


RegisterNetEvent('mh_garage:server:EnterGarage', function(garage, floor, inPreview)
    local playerId = source

    exports.qbx_core:SetPlayerBucket(playerId, playerId)
    Framework.SetMetadata(playerId, 'garage', { garage = garage, floor = floor, inPreview = inPreview == true or nil })
end)


RegisterNetEvent('mh_garage:server:ExitGarage', function(garage)
    local playerId = source

    exports.qbx_core:SetPlayerBucket(playerId, 0)
    Framework.ClearMeta(playerId, 'garage', nil)
end)

RegisterNetEvent('mh_garage:server:Orphan', function(id)
    local ent = NetworkGetEntityFromNetworkId(id)

    SetEntityOrphanMode(ent, 2)
end)


local function saveToDB()
    local insertTable = {}
    local query = 'UPDATE `mh_garage` SET `data` = ? WHERE `owner` = ? AND `name` = ?'

    for owner, garages in pairs(Garages) do
        for name, garageData in pairs(garages) do
            insertTable[#insertTable + 1] = { query = query, values = { json.encode(garageData), owner, name } }
        end
    end

    if #insertTable > 0 then
        local success, response = pcall(MySQL.transaction, insertTable)

        if not success then --------print(response)
        end
    end
end


exports('DoesPlayerOwnGarage', function(identifier)
    return Garages[identifier]
end)

-- Periodic cleanup for old pending requests (every 60 seconds) - optimized
local function CleanupStoreRequests()
    local currentTime = os.time()
    local cleaned = 0
    
    for key, timestamp in pairs(PendingStoreRequests) do
        if (currentTime - timestamp) > 60 then -- Remove requests older than 60 seconds
            PendingStoreRequests[key] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        ----print(string.format("^3[mh_garage] Periodic cleanup: Removed %d old pending requests^0", cleaned))
    end
    
    -- Schedule next cleanup
    SetTimeout(60000, CleanupStoreRequests)
end

-- Start cleanup cycle
SetTimeout(60000, CleanupStoreRequests)

SetInterval(saveToDB, 600000)


local Commands = lib.load 'config.server'.Commands

if Commands.invite.enable then
    lib.addCommand(Commands.invite.name, {
        help = Commands.invite.help,
        restricted = false
    }, function(source, args, raw)
        local data = lib.callback.await('mh_garage:cb:GetGarageClient', source)

        if not data.garage or not data.floor then
            TriggerClientEvent('mh_garage:Notify', source, locale('only_in_garage'), 'error')
            return
        end

        if data.preview then
            TriggerClientEvent('mh_garage:Notify', source, locale('not_in_preview'), 'error')
            return
        end

        local identifier = Framework.GetIdentifier(source)

        if not Garages[identifier][data.garage] then
            TriggerClientEvent('mh_garage:Notify', source, locale('not_your_garage'), 'error')
            return
        end

        local players = lib.getNearbyPlayers(GaragesData[data.garage].enter, 10.0, false)

        if #players == 0 then
            TriggerClientEvent('mh_garage:Notify', source, locale('no_player_nearby'), 'error')
            return
        end

        local options = {}

        for i = 1, #players do
            options[i] = { label = Framework.GetName(players[i].id), value = players[i].id }
        end

        TriggerClientEvent('mh_garage:client:InvitePlayer', source, options, data)
    end)
end

-- Admin command to reset vehicle state from stored (1) to out (0) - IMPROVED
lib.addCommand('resetvehicle', {
    help = 'Reset vehicle state from stored to out (Admin only)',
    restricted = 'group.admin',
    params = {
        { name = 'plate', type = 'string', help = 'Vehicle plate number' },
        { name = 'target', type = 'string', help = 'Target player ID or citizenid (optional)', optional = true }
    }
}, function(source, args, raw)
    local plate = args.plate
    if not plate then
        TriggerClientEvent('mh_garage:Notify', source, 'Usage: /resetvehicle [plate] [target_id]', 'error')
        return
    end
    
    plate = string.strtrim(plate:upper()) -- Normalize plate
    local targetIdentifier
    
    if args.target then
        -- If target specified, get their identifier
        local targetPlayer = tonumber(args.target)
        if targetPlayer and GetPlayerPed(targetPlayer) ~= 0 then
            targetIdentifier = Framework.GetIdentifier(targetPlayer)
        else
            -- Assume it's a citizenid/identifier directly
            targetIdentifier = args.target
        end
    else
        -- No target, use command executor
        targetIdentifier = Framework.GetIdentifier(source)
    end
    
    if not targetIdentifier then
        TriggerClientEvent('mh_garage:Notify', source, 'Invalid target player or identifier', 'error')
        return
    end
    
    -- IMPROVED: Direct MySQL queries with better error handling
    local success, result = pcall(function()
        -- Detect framework and query appropriately
        local vehicleData
        local isQBCore = Shared.qb == true
        
        if isQBCore then
            -- QBCore/QBX
            vehicleData = MySQL.query.await('SELECT citizenid, plate, garage, state FROM player_vehicles WHERE plate = ?', {plate})
        else
            -- ESX
            vehicleData = MySQL.query.await('SELECT owner, plate, garage, stored as state FROM owned_vehicles WHERE plate = ?', {plate})
        end
        
        if not vehicleData or #vehicleData == 0 then
            TriggerClientEvent('mh_garage:Notify', source, 'Vehicle "' .. plate .. '" not found in database', 'error')
            return
        end
        
        local vehicle = vehicleData[1]
        local owner = isQBCore and vehicle.citizenid or vehicle.owner
        local currentState = vehicle.state
        local currentGarage = vehicle.garage
        
        ----print('^3[RESET DEBUG]^7 Found vehicle - Owner: ' .. owner .. ', State: ' .. currentState .. ', Garage: ' .. (currentGarage or 'NULL'))
        
        if owner ~= targetIdentifier then
            TriggerClientEvent('mh_garage:Notify', source, 
                'Vehicle "' .. plate .. '" belongs to ' .. owner .. ', not ' .. targetIdentifier, 'error')
            return
        end
        
        if currentState == 0 then
            TriggerClientEvent('mh_garage:Notify', source, 
                'Vehicle "' .. plate .. '" is already out (state=0)', 'warning')
            return
        end
        
        -- Reset vehicle state to 0 (out) - DIRECT MySQL
        local updateResult
        if isQBCore then
            updateResult = MySQL.update.await('UPDATE player_vehicles SET state = 0, garage = NULL WHERE plate = ? AND citizenid = ?', 
                {plate, targetIdentifier})
        else
            updateResult = MySQL.update.await('UPDATE owned_vehicles SET stored = 0, garage = NULL WHERE plate = ? AND owner = ?', 
                {plate, targetIdentifier})
        end
        
        ----print('^2[RESET]^7 Database update result: ' .. (updateResult or 0) .. ' rows affected')
        
        -- Remove from garage memory and mh_garage database
        local removedFromMemory = RemoveVehicleFromAllGarages(targetIdentifier, plate)
        local removedFromCache = removedFromMemory
        
        -- Delete world vehicles with this plate
        local deletedWorldVehicles = 0
        local worldVehicles = GetAllVehicles()
        for i = 1, #worldVehicles do
            local vehicle = worldVehicles[i]
            if DoesEntityExist(vehicle) then
                local vehPlate = GetVehicleNumberPlateText(vehicle)
                if vehPlate and string.strtrim(vehPlate:upper()) == plate then
                    DeleteEntity(vehicle)
                    deletedWorldVehicles = deletedWorldVehicles + 1
                end
            end
        end
        
        -- Success notification
        local targetName = args.target and (Framework.GetName(tonumber(args.target)) or args.target) or Framework.GetName(source)
        local message = string.format(
            'RESET SUCCESS: Vehicle "%s" for %s | DB: %d rows | Memory: %d slots | Cache: %d | World: %d vehicles',
            plate, targetName, updateResult or 0, removedFromMemory, removedFromCache, deletedWorldVehicles
        )
        
        TriggerClientEvent('mh_garage:Notify', source, message, 'success')
        
        ----print('^2[RESET COMPLETE]^7 ' .. Framework.GetName(source) .. ' reset vehicle ' .. plate)
        ----print('  - Owner: ' .. targetIdentifier)
        ----print('  - Previous garage: ' .. (currentGarage or 'none'))
        ----print('  - Database rows updated: ' .. (updateResult or 0))
        ----print('  - Memory slots cleared: ' .. removedFromMemory)
        ----print('  - Cache entries removed: ' .. removedFromCache)
        ----print('  - World vehicles deleted: ' .. deletedWorldVehicles)
    end)
    
    if not success then
        TriggerClientEvent('mh_garage:Notify', source, 'ERROR: ' .. tostring(result), 'error')
        ----print('^1[RESET ERROR]^7 ' .. tostring(result))
    end
end)

-- Admin command to check vehicle status
lib.addCommand('checkvehicle', {
    help = 'Check vehicle status in database (Admin only)',
    restricted = 'group.admin',
    params = {
        { name = 'plate', type = 'string', help = 'Vehicle plate number' }
    }
}, function(source, args, raw)
    local plate = args.plate
    if not plate then
        TriggerClientEvent('mh_garage:Notify', source, 'Usage: /checkvehicle [plate]', 'error')
        return
    end
    
    plate = string.strtrim(plate:upper())
    
    -- Check vehicle owner
    local owner = db.GetVehicleOwner(plate)
    if not owner then
        TriggerClientEvent('mh_garage:Notify', source, 'Vehicle "' .. plate .. '" not found in database', 'error')
        return
    end
    
    -- Get vehicle state
    local state, garage = db.CheckVehicleState(plate, owner)
    
    local stateText = state == 1 and 'Stored in garage' or 'Out/Impounded'
    local garageText = garage and (' (' .. garage .. ')') or ''
    
    -- Count world vehicles with this plate
    local worldVehicles = GetAllVehicles()
    local worldCount = 0
    
    for i = 1, #worldVehicles do
        local vehicle = worldVehicles[i]
        if DoesEntityExist(vehicle) then
            local vehPlate = GetVehicleNumberPlateText(vehicle)
            if vehPlate and string.strtrim(vehPlate) == plate then
                worldCount = worldCount + 1
            end
        end
    end
    
    -- Send detailed info
    TriggerClientEvent('mh_garage:Notify', source, 
        'Vehicle "' .. plate .. '": ' .. stateText .. garageText .. 
        ' | Owner: ' .. owner .. ' | World duplicates: ' .. worldCount, 'info')
        
    --------print('^3[mh_garage]^7 Vehicle status check by ' .. Framework.GetName(source) .. ':')
    --------print('  - Plate: ' .. plate)
    --------print('  - Owner: ' .. owner)
    --------print('  - State: ' .. (state or 'unknown') .. ' (' .. stateText .. ')')
    --------print('  - Garage: ' .. (garage or 'none'))
    --------print('  - World duplicates: ' .. worldCount)
end)

-- DANGEROUS: Admin command to reset ALL vehicles in server to state=0
lib.addCommand('resetallvehicles', {
    help = 'DANGEROUS: Reset ALL vehicles in server to out state (Super Admin only)',
    restricted = 'group.admin',
    params = {
        { name = 'confirm', type = 'string', help = 'Type CONFIRM_RESET_ALL to execute' }
    }
}, function(source, args, raw)
    local confirmation = args.confirm
    
    -- Safety check: Require exact confirmation text
    if confirmation ~= 'CONFIRM_RESET_ALL' then
        TriggerClientEvent('mh_garage:Notify', source, 
            'DANGEROUS COMMAND: Type "/resetallvehicles CONFIRM_RESET_ALL" to reset ALL vehicles in server', 'error')
        return
    end
    
    -- Additional safety: Check if admin has super admin permission (customize this check)
    local adminName = Framework.GetName(source)
    local adminIdentifier = Framework.GetIdentifier(source)
    
    -- Log the dangerous operation immediately
    --------print('^1[DANGER]^7 ' .. adminName .. ' (' .. adminIdentifier .. ') initiated MASS VEHICLE RESET')
    --------print('^1[DANGER]^7 This will reset ALL vehicles in the server to state=0')
    
    -- Broadcast warning to all admins online
    local players = GetPlayers()
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if IsPlayerAceAllowed(playerId, 'group.admin') then
            TriggerClientEvent('mh_garage:Notify', playerId, 
                'WARNING: Admin ' .. adminName .. ' is performing MASS VEHICLE RESET', 'error')
        end
    end
    
    -- Start the mass reset process (no CreateThread needed - command already async)
    local totalVehicles = 0
    local resetCount = 0
    local errorCount = 0
    local clearedGarages = 0
    
    TriggerClientEvent('mh_garage:Notify', source, 'Starting mass vehicle reset... This may take a while.', 'info')
    
    -- Step 1: Reset all vehicles in database
        local vehicles
        if Shared.framework == 'qb-core' or Shared.framework == 'qbx_core' then
            vehicles = MySQL.query.await('SELECT `plate`, `citizenid`, `state` FROM `player_vehicles` WHERE `state` = 1')
        elseif Shared.framework == 'es_extended' then
            vehicles = MySQL.query.await('SELECT `plate`, `owner`, `stored` as state FROM `owned_vehicles` WHERE `stored` = 1')
        end
        
        if vehicles and #vehicles > 0 then
            totalVehicles = #vehicles
            --------print('^3[MASS RESET]^7 Found ' .. totalVehicles .. ' stored vehicles to reset')
            
            for i = 1, #vehicles do
                local vehicle = vehicles[i]
                local plate = vehicle.plate
                local owner = vehicle.citizenid or vehicle.owner
                
                if plate and owner then
                    -- Reset in database
                    local success = pcall(db.UpdateStored, plate, owner, 0)
                    if success then
                        resetCount = resetCount + 1
                        if resetCount % 50 == 0 then
                            --------print('^2[PROGRESS]^7 Reset ' .. resetCount .. '/' .. totalVehicles .. ' vehicles')
                        end
                    else
                        errorCount = errorCount + 1
                        --------print('^1[ERROR]^7 Failed to reset vehicle: ' .. plate)
                    end
                end
                
                -- Small delay to prevent server strain
                if i % 100 == 0 then
                    Wait(100)
                end
            end
        end
        
        -- Step 2: Clear all garage slots in memory
        local garageCount = 0
        for identifier, garages in pairs(Garages) do
            for garageName, garageData in pairs(garages) do
                if garageData.slot then
                    garageData.slot = {}
                    garageCount = garageCount + 1
                end
            end
        end
        clearedGarages = garageCount
        
        -- Step 3: Clear PlayerVehicles cache
        PlayerVehicles = {}
        
        -- Step 4: Delete all world vehicles (nuclear option)
        local worldVehicles = GetAllVehicles()
        local deletedWorldVehicles = 0
        
        if #worldVehicles > 0 then
            --------print('^3[MASS RESET]^7 Deleting ' .. #worldVehicles .. ' world vehicles')
            for i = 1, #worldVehicles do
                local vehicle = worldVehicles[i]
                if DoesEntityExist(vehicle) then
                    DeleteEntity(vehicle)
                    deletedWorldVehicles = deletedWorldVehicles + 1
                end
                
                -- Prevent server strain
                if i % 50 == 0 then
                    Wait(50)
                end
            end
        end
        
        -- Final report
        local reportMessage = string.format(
            'MASS RESET COMPLETE: Reset %d vehicles, Cleared %d garages, Deleted %d world vehicles, %d errors',
            resetCount, clearedGarages, deletedWorldVehicles, errorCount
        )
        
        TriggerClientEvent('mh_garage:Notify', source, reportMessage, 'success')
    
    -- Detailed console log
    --------print('^2[MASS RESET COMPLETE]^7 Operation finished by ' .. adminName)
    --------print('  - Database resets: ' .. resetCount .. '/' .. totalVehicles)
    --------print('  - Garage slots cleared: ' .. clearedGarages)
    --------print('  - World vehicles deleted: ' .. deletedWorldVehicles)
    --------print('  - Errors: ' .. errorCount)
    
    -- Broadcast completion to all admins
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if IsPlayerAceAllowed(playerId, 'group.admin') and playerId ~= source then
            TriggerClientEvent('mh_garage:Notify', playerId, 
                'Mass vehicle reset by ' .. adminName .. ' completed: ' .. resetCount .. ' vehicles reset', 'info')
        end
    end
end)

-- TESTING: Quick reset for test environment (Vietnamese friendly)
lib.addCommand('testmotreset', {
    help = 'Reset tất cả vehicle cho test (Admin only)',
    restricted = 'group.admin'
}, function(source, args, raw)
    local adminName = Framework.GetName(source)
    local adminIdentifier = Framework.GetIdentifier(source)
    
    --------print('^6[TEST RESET]^7 ' .. adminName .. ' đang reset môi trường test...')
    
    -- Notify admin starting
    TriggerClientEvent('mh_garage:Notify', source, 'Bắt đầu reset toàn bộ vehicle cho test...', 'info')
    
    -- Execute reset (no CreateThread needed)
    local resetCount = 0
    local errorCount = 0
    
    -- 1. Reset database quickly (no confirmation needed for test)
        local success, result = pcall(function()
            if Framework.name == 'qb' then
                MySQL.update('UPDATE player_vehicles SET state = 0, garage = NULL', {})
            else -- ESX
                MySQL.update('UPDATE owned_vehicles SET stored = 0, garage = NULL', {})
            end
        end)
        
        if success then
            resetCount = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. (Framework.name == 'qb' and 'player_vehicles' or 'owned_vehicles'))
            --------print('^2[TEST]^7 Database reset thành công: ' .. resetCount .. ' vehicles')
        else
            errorCount = errorCount + 1
            --------print('^1[TEST ERROR]^7 Database reset failed: ' .. tostring(result))
        end
        
        -- 2. Clear garage memory
        local clearedGarages = 0
        for owner, garages in pairs(Garages) do
            for garageName, garageData in pairs(garages) do
                if garageData.slot then
                    garageData.slot = {}
                    clearedGarages = clearedGarages + 1
                end
            end
        end
        
        -- 3. Clear PlayerVehicles cache
        PlayerVehicles = {}
        
        -- 4. Delete all world vehicles
        local worldVehicles = GetAllVehicles()
        local deletedWorldVehicles = 0
        
        for i = 1, #worldVehicles do
            local vehicle = worldVehicles[i]
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
                deletedWorldVehicles = deletedWorldVehicles + 1
            end
        end
        
        -- Report results
        local message = string.format(
            'TEST RESET HOÀN THÀNH! DB: %d vehicles | Memory: %d garages | World: %d vehicles | Errors: %d',
            resetCount, clearedGarages, deletedWorldVehicles, errorCount
        )
        
        TriggerClientEvent('mh_garage:Notify', source, message, errorCount > 0 and 'warning' or 'success')
    
    --------print('^2[TEST COMPLETE]^7 ' .. adminName .. ' - ' .. message)
    
    -- Notify other admins
    local players = GetPlayers()
    for i = 1, #players do
        local playerId = tonumber(players[i])
        if IsPlayerAceAllowed(playerId, 'group.admin') and playerId ~= source then
            TriggerClientEvent('mh_garage:Notify', playerId, 
                'Test reset by ' .. adminName .. ' - ' .. resetCount .. ' vehicles reset', 'info')
        end
    end
end)

-- Fix vehicles with state=1 but missing from garage memory
lib.addCommand('fixmissingvehicles', {
    help = 'Fix xe có state=1 nhưng không có trong garage theo biển số (Admin only)',
    params = {
        { name = 'plate', type = 'string', help = 'Biển số xe cần fix' }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local adminName = Framework.GetName(source)
    local targetPlate = args.plate
    
    if not targetPlate or targetPlate == '' then
        TriggerClientEvent('mh_garage:Notify', source, 'Usage: /fixmissingvehicles [plate]', 'error')
        return
    end
    
    targetPlate = string.strtrim(string.upper(targetPlate))
    TriggerClientEvent('mh_garage:Notify', source, 'Đang tìm kiếm xe: ' .. targetPlate, 'info')
    
    -- Execute fix (no CreateThread needed)
    -- Debug: Add error handling and logging
    local success, result = pcall(function()
            -- Query specific vehicle with state=1 from database
            local dbVehicle
            
            -- Detect framework properly using Shared table
            local isQBCore = Shared.qb == true
            local isESX = Shared.esx == true
            
            ------print('^3[FIX DEBUG]^7 Framework detection - QB: ' .. tostring(isQBCore) .. ', ESX: ' .. tostring(isESX))
            
            if isQBCore then
                local queryResult = MySQL.query.await('SELECT citizenid, plate, garage, mods FROM player_vehicles WHERE plate = ? AND state = 1', {targetPlate})
                dbVehicle = queryResult and queryResult[1] or nil
                ------print('^3[FIX DEBUG QB]^7 Query result for plate ' .. targetPlate .. ': ' .. (dbVehicle and 'FOUND' or 'NOT FOUND'))
            elseif isESX then
                local queryResult = MySQL.query.await('SELECT owner, plate, garage, vehicle FROM owned_vehicles WHERE plate = ? AND stored = 1', {targetPlate})
                dbVehicle = queryResult and queryResult[1] or nil
                ------print('^3[FIX DEBUG ESX]^7 Query result for plate ' .. targetPlate .. ': ' .. (dbVehicle and 'FOUND' or 'NOT FOUND'))
            else
                TriggerClientEvent('mh_garage:Notify', source, 'Framework không được detect đúng!', 'error')
                return
            end
            
            if not dbVehicle then
                TriggerClientEvent('mh_garage:Notify', source, 
                    'Không tìm thấy xe ' .. targetPlate .. ' với state=1 trong database', 'error')
                return
            end
            
            local identifier = isQBCore and dbVehicle.citizenid or dbVehicle.owner
            local plate = string.strtrim(dbVehicle.plate)
            local garage = dbVehicle.garage
            local mods = isQBCore and dbVehicle.mods or dbVehicle.vehicle
            
            ------print('^3[FIX DEBUG]^7 Vehicle found - Owner: ' .. identifier .. ', Garage: ' .. (garage or 'NULL') .. ', Plate: ' .. plate)
            
            -- Skip if no garage assigned
            if not garage or garage == '' or garage == 'NULL' then
                TriggerClientEvent('mh_garage:Notify', source, 
                    'Xe ' .. plate .. ' không có garage được assign (garage: ' .. tostring(garage) .. ')', 'error')
                return
            end
            
            -- Check if garage exists in memory
            if not Garages[identifier] then
                Garages[identifier] = {}
            end
            
            if not Garages[identifier][garage] then
                Garages[identifier][garage] = { slot = {} }
            end
            
            -- Parse vehicle data
            local vehicleData = json.decode(mods)
            
            -- Check if vehicle exists in garage memory (RAM)
            local foundInMemory = false
            if PlayerVehicles[identifier] and PlayerVehicles[identifier][garage] and PlayerVehicles[identifier][garage][plate] then
                foundInMemory = true
            end
            
            -- Check if vehicle exists in persistent garage database (mh_garage table)
            local foundInPersistent = false
            local garageDbData = MySQL.query.await('SELECT data FROM mh_garage WHERE owner = ? AND name = ?', {identifier, garage})
            if garageDbData and garageDbData[1] then
                local success, parsedGarage = pcall(json.decode, garageDbData[1].data)
                if success and parsedGarage and parsedGarage.slot then
                    -- Check all floors for the vehicle plate
                    for floorIndex, floorSlots in pairs(parsedGarage.slot) do
                        if type(floorSlots) == "table" then
                            for _, slotPlate in ipairs(floorSlots) do
                                if slotPlate == plate then
                                    foundInPersistent = true
                                    break
                                end
                            end
                        end
                        if foundInPersistent then break end
                    end
                end
            end
            
            ------print('^3[FIX DEBUG]^7 Vehicle check - Memory: ' .. tostring(foundInMemory) .. ', Persistent: ' .. tostring(foundInPersistent))
            
            if foundInMemory and foundInPersistent then
                TriggerClientEvent('mh_garage:Notify', source, 
                    'Xe ' .. plate .. ' đã tồn tại đầy đủ trong cả memory và persistent storage - không cần fix', 'info')
            elseif foundInMemory and not foundInPersistent then
                TriggerClientEvent('mh_garage:Notify', source, 
                    'Xe ' .. plate .. ' có trong memory nhưng THIẾU trong persistent storage - đang fix...', 'warning')
                -- Force rebuild persistent storage from memory
            elseif not foundInMemory and foundInPersistent then
                TriggerClientEvent('mh_garage:Notify', source, 
                    'Xe ' .. plate .. ' có trong persistent storage nhưng THIẾU trong memory - đang fix...', 'warning')
                -- Force rebuild memory from database vehicle data
            elseif not foundInMemory and not foundInPersistent then
                TriggerClientEvent('mh_garage:Notify', source, 
                    'Xe ' .. plate .. ' THIẾU hoàn toàn - đang rebuild từ database...', 'error')
            end
            
            -- If ANY issue found, rebuild both memory and persistent storage
            if not foundInMemory or not foundInPersistent then
                -- Vehicle missing from memory or persistent storage - rebuild both
                if not PlayerVehicles[identifier] then
                    PlayerVehicles[identifier] = {}
                end
                if not PlayerVehicles[identifier][garage] then
                    PlayerVehicles[identifier][garage] = {}
                end
                
                -- Restore vehicle to memory
                vehicleData.plate = plate
                PlayerVehicles[identifier][garage][plate] = vehicleData
                
                -- IMPORTANT: Also save to persistent garage database
                if not Garages[identifier] then
                    Garages[identifier] = {}
                end
                if not Garages[identifier][garage] then
                    Garages[identifier][garage] = { slot = {} }
                end
                
                -- Add vehicle to Garages persistent storage
                if not Garages[identifier][garage].slot then
                    Garages[identifier][garage].slot = {}
                end
                
                -- Find available slot or create new one
                local floor = '1' -- Default floor
                
                -- Initialize correct format: slot = [floorArray1, floorArray2, ...]
                if not Garages[identifier][garage].slot then
                    Garages[identifier][garage].slot = {}
                end
                
                -- Ensure floor array exists (floor 1 = index 1)
                local floorIndex = tonumber(floor) or 1
                if not Garages[identifier][garage].slot[floorIndex] then
                    Garages[identifier][garage].slot[floorIndex] = {}
                end
                
                local currentFloorSlots = Garages[identifier][garage].slot[floorIndex]
                
                -- Check if vehicle already exists in floor array
                local existingIndex = nil
                for i, slotPlate in ipairs(currentFloorSlots) do
                    if slotPlate == plate then
                        existingIndex = i
                        break
                    end
                end
                
                if existingIndex then
                    ------print('^6[FIX DEBUG SLOT]^7 Vehicle already in floor ' .. floorIndex .. ' at position: ' .. existingIndex)
                else
                    -- Add to floor array
                    table.insert(currentFloorSlots, plate)
                    ------print('^6[FIX DEBUG SLOT]^7 Added vehicle to floor ' .. floorIndex .. ' at position: ' .. #currentFloorSlots)
                end
                
                -- Save to database immediately
                local garageData = json.encode(Garages[identifier][garage])
                MySQL.execute('INSERT INTO mh_garage (owner, name, data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', {
                    identifier, garage, garageData
                })
                
                -- DEBUG: Show current garage structure
                ------print('^6[FIX DEBUG GARAGE]^7 Garage structure for ' .. identifier .. ':')
                ------print('^6[FIX DEBUG GARAGE]^7 Garage name: "' .. garage .. '"')
                ------print('^6[FIX DEBUG GARAGE]^7 Garage data: ' .. garageData)
                
                -- DEBUG: Show PlayerVehicles structure  
                if PlayerVehicles[identifier] and PlayerVehicles[identifier][garage] then
                    local vehicleCount = 0
                    for vPlate, vData in pairs(PlayerVehicles[identifier][garage]) do
                        vehicleCount = vehicleCount + 1
                        ------print('^6[FIX DEBUG VEHICLES]^7 Vehicle ' .. vehicleCount .. ': ' .. vPlate .. ' (' .. (vData.model or 'Unknown') .. ')')
                    end
                    ------print('^6[FIX DEBUG VEHICLES]^7 Total vehicles in PlayerVehicles[' .. identifier .. '][' .. garage .. ']: ' .. vehicleCount)
                else
                    ------print('^1[FIX DEBUG ERROR]^7 PlayerVehicles structure missing!')
                end
                
                local statusText = ''
                if not foundInMemory and not foundInPersistent then
                    statusText = 'REBUILT hoàn toàn'
                elseif not foundInMemory then
                    statusText = 'RESTORED memory từ database'
                elseif not foundInPersistent then
                    statusText = 'RESTORED persistent storage từ memory'
                end
                
                local message = string.format('%s xe %s (%s) trong garage %s (floor %d, position %d)', 
                    statusText, plate, vehicleData.model or 'Unknown', garage, floorIndex, #currentFloorSlots)
                TriggerClientEvent('mh_garage:Notify', source, message, 'success')
                
                ------print('^2[FIX MISSING]^7 ' .. adminName .. ' fixed vehicle: ' .. plate .. ' in garage: ' .. garage .. ' (Status: ' .. statusText .. ')')
                
                -- Notify other admins
                local players = GetPlayers()
                for i = 1, #players do
                    local playerId = tonumber(players[i])
                    if IsPlayerAceAllowed(playerId, 'group.admin') and playerId ~= source then
                        TriggerClientEvent('mh_garage:Notify', playerId, 
                            'Vehicle ' .. plate .. ' fixed by ' .. adminName, 'info')
                    end
                end
            end
        end)
        
        if not success then
            ------print('^1[FIX ERROR]^7 Error in fixmissingvehicles: ' .. tostring(result))
            TriggerClientEvent('mh_garage:Notify', source, 
                'Lỗi khi fix xe: ' .. tostring(result), 'error')
        end
end)

-- Debug command to check garage data
lib.addCommand('checkgaragedata', {
    help = 'Check garage data cho player (Admin only)',
    params = {
        { name = 'citizenid', type = 'string', help = 'Citizen ID của player' },
        { name = 'garage', type = 'string', help = 'Tên garage cần check' }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local adminName = Framework.GetName(source)
    local citizenid = args.citizenid
    local garageName = args.garage
    
    if not citizenid or not garageName then
        TriggerClientEvent('mh_garage:Notify', source, 'Usage: /checkgaragedata [citizenid] [garage_name]', 'error')
        return
    end
    
    TriggerClientEvent('mh_garage:Notify', source, 'Checking garage data...', 'info')
    
    -- Execute check (no CreateThread needed)
    -- Check Garages memory
    ----print('^6[GARAGE DEBUG]^7 === GARAGE DATA CHECK ===')
        ----print('^6[GARAGE DEBUG]^7 Admin: ' .. adminName)
        ----print('^6[GARAGE DEBUG]^7 Checking: ' .. citizenid .. ' -> "' .. garageName .. '"')
        
        if Garages[citizenid] then
            ----print('^6[GARAGE DEBUG]^7 Player exists in Garages memory')
            if Garages[citizenid][garageName] then
                ----print('^6[GARAGE DEBUG]^7 Garage "' .. garageName .. '" exists')
                ----print('^6[GARAGE DEBUG]^7 Garage data: ' .. json.encode(Garages[citizenid][garageName]))
                
                -- Specifically check slot structure
                if Garages[citizenid][garageName].slot then
                    ----print('^6[GARAGE DEBUG]^7 === SLOT ANALYSIS ===')
                    ----print('^6[GARAGE DEBUG]^7 Slot type: ' .. type(Garages[citizenid][garageName].slot))
                    ----print('^6[GARAGE DEBUG]^7 Slot data: ' .. json.encode(Garages[citizenid][garageName].slot))
                    
                    for k, v in pairs(Garages[citizenid][garageName].slot) do
                        ----print('^6[GARAGE DEBUG]^7 Slot key "' .. tostring(k) .. '" (type: ' .. type(k) .. ') -> ' .. json.encode(v))
                        if type(v) == 'table' then
                            for i, plate in ipairs(v) do
                                ----print('^6[GARAGE DEBUG]^7   - Position ' .. i .. ': "' .. tostring(plate) .. '"')
                            end
                        end
                    end
                end
            else
                ----print('^1[GARAGE DEBUG]^7 Garage "' .. garageName .. '" NOT FOUND')
                ----print('^6[GARAGE DEBUG]^7 Available garages:')
                for gName, gData in pairs(Garages[citizenid]) do
                    ----print('^6[GARAGE DEBUG]^7 - "' .. gName .. '"')
                end
            end
        else
            ----print('^1[GARAGE DEBUG]^7 Player NOT FOUND in Garages memory')
        end
        
        -- Check PlayerVehicles memory
        if PlayerVehicles[citizenid] then
            ----print('^6[GARAGE DEBUG]^7 Player exists in PlayerVehicles memory')
            if PlayerVehicles[citizenid][garageName] then
                ----print('^6[GARAGE DEBUG]^7 PlayerVehicles garage "' .. garageName .. '" exists')
                local vehicleCount = 0
                for plate, vData in pairs(PlayerVehicles[citizenid][garageName]) do
                    vehicleCount = vehicleCount + 1
                    ----print('^6[GARAGE DEBUG]^7 Vehicle: ' .. plate .. ' (' .. (vData.model or 'Unknown') .. ')')
                end
                ----print('^6[GARAGE DEBUG]^7 Total vehicles: ' .. vehicleCount)
            else
                ----print('^1[GARAGE DEBUG]^7 PlayerVehicles garage "' .. garageName .. '" NOT FOUND')
                ----print('^6[GARAGE DEBUG]^7 Available garages:')
                for gName, gData in pairs(PlayerVehicles[citizenid]) do
                    ----print('^6[GARAGE DEBUG]^7 - "' .. gName .. '"')
                end
            end
        else
            ----print('^1[GARAGE DEBUG]^7 Player NOT FOUND in PlayerVehicles memory')
        end
        
        -- Check database with detailed parsing
        local dbResult = MySQL.query.await('SELECT data FROM mh_garage WHERE owner = ? AND name = ?', {citizenid, garageName})
        if dbResult[1] then
            ----print('^6[GARAGE DEBUG]^7 Database record EXISTS')
            ----print('^6[GARAGE DEBUG]^7 Raw DB data: ' .. dbResult[1].data)
            
            -- Try to parse database data
            local success, parsedData = pcall(json.decode, dbResult[1].data)
            if success then
                ----print('^6[GARAGE DEBUG]^7 === PARSED DB DATA ===')
                ----print('^6[GARAGE DEBUG]^7 Parsed successfully: ' .. json.encode(parsedData))
                
                if parsedData.slot then
                    ----print('^6[GARAGE DEBUG]^7 === DB SLOT ANALYSIS ===')
                    ----print('^6[GARAGE DEBUG]^7 DB Slot type: ' .. type(parsedData.slot))
                    ----print('^6[GARAGE DEBUG]^7 DB Slot data: ' .. json.encode(parsedData.slot))
                    
                    for k, v in pairs(parsedData.slot) do
                        ----print('^6[GARAGE DEBUG]^7 DB Slot key "' .. tostring(k) .. '" (type: ' .. type(k) .. ') -> ' .. json.encode(v))
                    end
                end
            else
                ----print('^1[GARAGE DEBUG]^7 Failed to parse DB data: ' .. tostring(parsedData))
            end
        else
            ----print('^1[GARAGE DEBUG]^7 Database record NOT FOUND')
        end
        
        ----print('^6[GARAGE DEBUG]^7 === END CHECK ===')
    
    TriggerClientEvent('mh_garage:Notify', source, 'Garage data check completed - see console', 'success')
end)

RegisterNetEvent('mh_garage:server:InvitePlayer', function(target, data)
    local src = source
    local inviter = Framework.GetName(src)
    local identifier = Framework.GetIdentifier(src)
    local cb = lib.callback.await('mh_garage:cb:SendInvite', target, inviter)

    if cb == 'cancel' then
        TriggerClientEvent('mh_garage:Notify', src, locale('declined_invite'), 'info')
        return
    end

    exports.qbx_core:SetPlayerBucket(target, src)
    local garageStyle = Garages[identifier] and Garages[identifier][data.garage] and Garages[identifier][data.garage].style
    local floorStyle = garageStyle and garageStyle[data.floor] or {}
    TriggerClientEvent('mh_garage:client:TeleportPlayer', target, floorStyle, data)
end)

RegisterNetEvent('mh_garage:server:TeleportOut', function(name)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GaragesData[name].enter

    -- Add a small delay to ensure client is ready
    Wait(200)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    exports.qbx_core:SetPlayerBucket(src, 0)
end)


AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then saveToDB() end
end)


AddEventHandler('txAdmin:events:serverShuttingDown', function()
	saveToDB()
end)


AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining ~= 60 then return end

	saveToDB()
end)


AddEventHandler('playerDropped', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    -- Cleanup pending store requests for this player
    if identifier then
        for requestKey, timestamp in pairs(PendingStoreRequests) do
            if string.find(requestKey, identifier, 1, true) then
                PendingStoreRequests[requestKey] = nil
            end
        end
    end
    
	if GetNumPlayerIndices() == 0 then
		saveToDB()
	end
end)

-- NEW: Command to check sync between vehicle SQL and mh_garage data
lib.addCommand('checksync', {
    help = 'Kiểm tra đồng bộ giữa vehicle SQL và mh_garage data (Admin only)',
    params = {
        { name = 'citizenid', type = 'string', help = 'Citizen ID của player' },
        { name = 'garage', type = 'string', help = 'Tên garage cần check (optional)', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local adminName = Framework.GetName(source)
    local citizenid = args.citizenid
    local specificGarage = args.garage
    
    if not citizenid then
        TriggerClientEvent('mh_garage:Notify', source, 'Usage: /checksync [citizenid] [garage_name_optional]', 'error')
        return
    end
    
    TriggerClientEvent('mh_garage:Notify', source, 'Checking vehicle-garage sync...', 'info')
    
    -- Execute sync check (no CreateThread needed)
    ----print('^5[SYNC CHECK]^7 === VEHICLE-GARAGE SYNC CHECK ===')
        ----print('^5[SYNC CHECK]^7 Admin: ' .. adminName)
        ----print('^5[SYNC CHECK]^7 Target: ' .. citizenid .. (specificGarage and (' -> "' .. specificGarage .. '"') or ' (all garages)'))
        
        -- Get all stored vehicles from SQL
        local storedVehicles
        local isQBCore = Shared.qb == true
        
        if isQBCore then
            if specificGarage then
                storedVehicles = MySQL.query.await('SELECT plate, garage FROM player_vehicles WHERE citizenid = ? AND state = 1 AND garage = ?', {citizenid, specificGarage})
            else
                storedVehicles = MySQL.query.await('SELECT plate, garage FROM player_vehicles WHERE citizenid = ? AND state = 1', {citizenid})
            end
        else
            if specificGarage then
                storedVehicles = MySQL.query.await('SELECT plate, garage FROM owned_vehicles WHERE owner = ? AND stored = 1 AND garage = ?', {citizenid, specificGarage})
            else
                storedVehicles = MySQL.query.await('SELECT plate, garage FROM owned_vehicles WHERE owner = ? AND stored = 1', {citizenid})
            end
        end
        
        ----print('^5[SYNC CHECK]^7 Found ' .. #storedVehicles .. ' stored vehicles in SQL')
        
        local syncIssues = {}
        local totalChecked = 0
        
        for i, vehicle in ipairs(storedVehicles) do
            local plate = string.strtrim(vehicle.plate)
            local garage = vehicle.garage
            totalChecked = totalChecked + 1
            
            ----print('^5[SYNC CHECK]^7 [' .. totalChecked .. '] Checking: ' .. plate .. ' in garage "' .. garage .. '"')
            
            -- Check if vehicle exists in mh_garage persistent storage
            local foundInPersistent = false
            local garageDbData = MySQL.query.await('SELECT data FROM mh_garage WHERE owner = ? AND name = ?', {citizenid, garage})
            
            if garageDbData and garageDbData[1] then
                local success, parsedGarage = pcall(json.decode, garageDbData[1].data)
                if success and parsedGarage and parsedGarage.slot then
                    for floorIndex, floorSlots in pairs(parsedGarage.slot) do
                        if type(floorSlots) == "table" then
                            for _, slotPlate in ipairs(floorSlots) do
                                if slotPlate == plate then
                                    foundInPersistent = true
                                    break
                                end
                            end
                        end
                        if foundInPersistent then break end
                    end
                end
            end
            
            -- Check if vehicle exists in memory
            local foundInMemory = false
            if PlayerVehicles[citizenid] and PlayerVehicles[citizenid][garage] and PlayerVehicles[citizenid][garage][plate] then
                foundInMemory = true
            end
            
            local status = 'OK'
            if not foundInPersistent and not foundInMemory then
                status = 'MISSING_BOTH'
            elseif not foundInPersistent then
                status = 'MISSING_PERSISTENT'
            elseif not foundInMemory then
                status = 'MISSING_MEMORY'
            end
            
            if status ~= 'OK' then
                table.insert(syncIssues, {
                    plate = plate,
                    garage = garage,
                    status = status,
                    inMemory = foundInMemory,
                    inPersistent = foundInPersistent
                })
                ----print('^1[SYNC ISSUE]^7 ' .. plate .. ' -> ' .. status)
            else
                ----print('^2[SYNC OK]^7 ' .. plate .. ' -> OK')
            end
        end
        
        -- Summary report
        ----print('^5[SYNC CHECK]^7 === SUMMARY ===')
        ----print('^5[SYNC CHECK]^7 Total vehicles checked: ' .. totalChecked)
        ----print('^5[SYNC CHECK]^7 Issues found: ' .. #syncIssues)
        
        if #syncIssues > 0 then
            ----print('^5[SYNC CHECK]^7 === ISSUES DETAIL ===')
            for i, issue in ipairs(syncIssues) do
                ----print('^1[ISSUE ' .. i .. ']^7 ' .. issue.plate .. ' (' .. issue.garage .. ') -> ' .. issue.status)
                ----print('  Memory: ' .. tostring(issue.inMemory) .. ', Persistent: ' .. tostring(issue.inPersistent))
            end
            
            TriggerClientEvent('mh_garage:Notify', source, 
                'Found ' .. #syncIssues .. ' sync issues out of ' .. totalChecked .. ' vehicles - see console', 'error')
        else
            TriggerClientEvent('mh_garage:Notify', source, 
                'All ' .. totalChecked .. ' vehicles are in sync!', 'success')
        end
        
        ----print('^5[SYNC CHECK]^7 === END CHECK ===')
end)

lib.addCommand('fixduplicates', {
    help = 'Fix duplicate plates trong mh_garage data (Admin only)',
    params = {
        { name = 'citizenid', type = 'string', help = 'Citizen ID của player' },
        { name = 'garage', type = 'string', help = 'Tên garage cần fix (optional)', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local adminName = Framework.GetName(source)
    local citizenid = args.citizenid
    local specificGarage = args.garage
    
    if not citizenid then
        TriggerClientEvent('mh_garage:Notify', source, 'Usage: /fixduplicates [citizenid] [garage_name_optional]', 'error')
        return
    end
    
    TriggerClientEvent('mh_garage:Notify', source, 'Scanning for duplicate plates...', 'info')
    
    -- Execute duplicate fix (no CreateThread needed)
    ----print('^4[FIX DUPLICATES]^7 === DUPLICATE PLATE SCANNER ===')
        ----print('^4[FIX DUPLICATES]^7 Admin: ' .. adminName)
        ----print('^4[FIX DUPLICATES]^7 Target: ' .. citizenid .. (specificGarage and (' -> "' .. specificGarage .. '"') or ' (all garages)'))
        
        local totalFixed = 0
        local totalGaragesChecked = 0
        local duplicatesFound = {}
        
        -- Get all garages for this player
        local garageQuery
        if specificGarage then
            garageQuery = MySQL.query.await('SELECT name, data FROM mh_garage WHERE owner = ? AND name = ?', {citizenid, specificGarage})
        else
            garageQuery = MySQL.query.await('SELECT name, data FROM mh_garage WHERE owner = ?', {citizenid})
        end
        
        for _, garageRow in ipairs(garageQuery) do
            local garageName = garageRow.name
            local rawData = garageRow.data
            totalGaragesChecked = totalGaragesChecked + 1
            
            ----print('^4[FIX DUPLICATES]^7 Checking garage: "' .. garageName .. '"')
            
            local success, garageData = pcall(json.decode, rawData)
            if not success then
                ----print('^1[FIX DUPLICATES ERROR]^7 Failed to parse garage data for: ' .. garageName)
                goto continue
            end
            
            if not garageData.slot then
                ----print('^3[FIX DUPLICATES]^7 No slot data in garage: ' .. garageName)
                goto continue
            end
            
            local modified = false
            
            -- Check each floor for duplicates
            for floorIndex, floorSlots in pairs(garageData.slot) do
                if type(floorSlots) == "table" then
                    ----print('^4[FIX DUPLICATES]^7 Floor ' .. floorIndex .. ' has ' .. #floorSlots .. ' slots')
                    
                    -- Count occurrences of each plate
                    local plateCount = {}
                    for i, plate in ipairs(floorSlots) do
                        local cleanPlate = string.strtrim(plate)
                        plateCount[cleanPlate] = (plateCount[cleanPlate] or 0) + 1
                    end
                    
                    -- Find duplicates
                    local duplicatesInFloor = {}
                    for plate, count in pairs(plateCount) do
                        if count > 1 then
                            table.insert(duplicatesInFloor, {plate = plate, count = count})
                            if not duplicatesFound[garageName] then
                                duplicatesFound[garageName] = {}
                            end
                            table.insert(duplicatesFound[garageName], {
                                floor = floorIndex,
                                plate = plate,
                                count = count
                            })
                        end
                    end
                    
                    if #duplicatesInFloor > 0 then
                        ----print('^1[FIX DUPLICATES]^7 Floor ' .. floorIndex .. ' duplicates:')
                        for _, dup in ipairs(duplicatesInFloor) do
                            ----print('^1[FIX DUPLICATES]^7   - "' .. dup.plate .. '" appears ' .. dup.count .. ' times')
                        end
                        
                        -- Remove duplicates - keep only first occurrence
                        local cleanedSlots = {}
                        local seenPlates = {}
                        
                        for i, plate in ipairs(floorSlots) do
                            local cleanPlate = string.strtrim(plate)
                            if not seenPlates[cleanPlate] then
                                table.insert(cleanedSlots, plate)
                                seenPlates[cleanPlate] = true
                            else
                                totalFixed = totalFixed + 1
                                ----print('^2[FIX DUPLICATES]^7 Removed duplicate: "' .. cleanPlate .. '"')
                            end
                        end
                        
                        -- Update the floor with cleaned slots
                        garageData.slot[floorIndex] = cleanedSlots
                        modified = true
                        
                        ----print('^2[FIX DUPLICATES]^7 Floor ' .. floorIndex .. ' cleaned: ' .. #floorSlots .. ' -> ' .. #cleanedSlots .. ' slots')
                    end
                end
            end
            
            -- Save if modified
            if modified then
                local newData = json.encode(garageData)
                MySQL.execute('UPDATE mh_garage SET data = ? WHERE owner = ? AND name = ?', {
                    newData, citizenid, garageName
                })
                
                -- Also update memory if exists
                if Garages[citizenid] and Garages[citizenid][garageName] then
                    Garages[citizenid][garageName] = garageData
                    ----print('^2[FIX DUPLICATES]^7 Updated memory for garage: ' .. garageName)
                end
                
                ----print('^2[FIX DUPLICATES]^7 Saved cleaned garage: ' .. garageName)
            end
            
            ::continue::
        end
        
        -- Summary report
        ----print('^4[FIX DUPLICATES]^7 === SUMMARY ===')
        ----print('^4[FIX DUPLICATES]^7 Garages checked: ' .. totalGaragesChecked)
        ----print('^4[FIX DUPLICATES]^7 Duplicates removed: ' .. totalFixed)
        
        if totalFixed > 0 then
            ----print('^4[FIX DUPLICATES]^7 === DUPLICATES FOUND ===')
            for garageName, dups in pairs(duplicatesFound) do
                ----print('^1[DUPLICATES]^7 Garage "' .. garageName .. '":')
                for _, dup in ipairs(dups) do
                    ----print('^1[DUPLICATES]^7   Floor ' .. dup.floor .. ': "' .. dup.plate .. '" x' .. dup.count)
                end
            end
            
            TriggerClientEvent('mh_garage:Notify', source, 
                'Fixed ' .. totalFixed .. ' duplicate plates in ' .. totalGaragesChecked .. ' garages', 'success')
        else
            TriggerClientEvent('mh_garage:Notify', source, 
                'No duplicates found in ' .. totalGaragesChecked .. ' garages', 'info')
        end
    
    ----print('^4[FIX DUPLICATES]^7 === END FIX ===')
end)

lib.addCommand('debugvehicle', {
    help = 'Debug specific vehicle in database và garage (Admin only)',
    params = {
        { name = 'citizenid', type = 'string', help = 'Citizen ID của player' },
        { name = 'plate', type = 'string', help = 'Biển số xe cần check' }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local adminName = Framework.GetName(source)
    local citizenid = args.citizenid
    local plate = args.plate
    
    if not citizenid or not plate then
        TriggerClientEvent('mh_garage:Notify', source, 'Usage: /debugvehicle [citizenid] [plate]', 'error')
        return
    end
    
    -- Execute debug (no CreateThread needed)
    ----print('^4[DEBUG VEHICLE]^7 === VEHICLE DEBUG REPORT ===')
        ----print('^4[DEBUG VEHICLE]^7 Admin: ' .. adminName)
        ----print('^4[DEBUG VEHICLE]^7 Target: ' .. citizenid)
        ----print('^4[DEBUG VEHICLE]^7 Vehicle Plate: "' .. plate .. '"')
        
        local cleanPlate = string.strtrim(plate)
        local isQBCore = Shared.qb == true
        
        -- Check in database
        ----print('^4[DEBUG VEHICLE]^7 === DATABASE CHECK ===')
        local dbVehicle
        if isQBCore then
            dbVehicle = MySQL.single.await('SELECT citizenid, plate, garage, mods, state FROM player_vehicles WHERE citizenid = ? AND plate = ?', {citizenid, cleanPlate})
        else
            dbVehicle = MySQL.single.await('SELECT owner, plate, garage, vehicle, stored FROM owned_vehicles WHERE owner = ? AND plate = ?', {citizenid, cleanPlate})
        end
        
        if dbVehicle then
            ----print('^2[DEBUG VEHICLE]^7 FOUND in database:')
            if isQBCore then
                ----print('^2[DEBUG VEHICLE]^7   CitizenID: ' .. dbVehicle.citizenid)
                ----print('^2[DEBUG VEHICLE]^7   Plate: "' .. dbVehicle.plate .. '"')
                ----print('^2[DEBUG VEHICLE]^7   Garage: "' .. (dbVehicle.garage or 'NULL') .. '"')
                ----print('^2[DEBUG VEHICLE]^7   State: ' .. (dbVehicle.state or 'NULL'))
                
                local mods = json.decode(dbVehicle.mods or '{}')
                ----print('^2[DEBUG VEHICLE]^7   Model: ' .. (mods.model or 'Unknown'))
            else
                ----print('^2[DEBUG VEHICLE]^7   Owner: ' .. dbVehicle.owner)
                ----print('^2[DEBUG VEHICLE]^7   Plate: "' .. dbVehicle.plate .. '"')
                ----print('^2[DEBUG VEHICLE]^7   Garage: "' .. (dbVehicle.garage or 'NULL') .. '"')
                ----print('^2[DEBUG VEHICLE]^7   Stored: ' .. (dbVehicle.stored or 'NULL'))
                
                local vehicle = json.decode(dbVehicle.vehicle or '{}')
                ----print('^2[DEBUG VEHICLE]^7   Model: ' .. (vehicle.model or 'Unknown'))
            end
        else
            ----print('^1[DEBUG VEHICLE]^7 NOT FOUND in database!')
        end
        
        -- Check in mh_garage memory
        ----print('^4[DEBUG VEHICLE]^7 === GARAGE MEMORY CHECK ===')
        local foundInGarages = {}
        if Garages[citizenid] then
            for garageName, garageData in pairs(Garages[citizenid]) do
                if garageData.slot then
                    for floorNum, slots in pairs(garageData.slot) do
                        if type(slots) == "table" then
                            for i, slotPlate in ipairs(slots) do
                                if string.strtrim(slotPlate) == cleanPlate then
                                    table.insert(foundInGarages, {
                                        garage = garageName,
                                        floor = floorNum,
                                        position = i
                                    })
                                    ----print('^2[DEBUG VEHICLE]^7 FOUND in garage "' .. garageName .. '" floor ' .. floorNum .. ' position ' .. i)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if #foundInGarages == 0 then
            ----print('^1[DEBUG VEHICLE]^7 NOT FOUND in any garage slots!')
        end
        
        -- Check in PlayerVehicles cache
        ----print('^4[DEBUG VEHICLE]^7 === PLAYER VEHICLES CACHE CHECK ===')
        local foundInCache = {}
        if PlayerVehicles[citizenid] then
            for garageName, vehicles in pairs(PlayerVehicles[citizenid]) do
                if vehicles[cleanPlate] then
                    table.insert(foundInCache, garageName)
                    ----print('^2[DEBUG VEHICLE]^7 FOUND in PlayerVehicles cache for garage "' .. garageName .. '"')
                end
            end
        end
        
        if #foundInCache == 0 then
            ----print('^1[DEBUG VEHICLE]^7 NOT FOUND in PlayerVehicles cache!')
        end
        
        -- Summary
        ----print('^4[DEBUG VEHICLE]^7 === SUMMARY ===')
        ----print('^4[DEBUG VEHICLE]^7 Database: ' .. (dbVehicle and 'FOUND' or 'NOT FOUND'))
        ----print('^4[DEBUG VEHICLE]^7 Garage Slots: ' .. #foundInGarages .. ' locations')
        ----print('^4[DEBUG VEHICLE]^7 Cache: ' .. #foundInCache .. ' garages')
        
        if dbVehicle and #foundInGarages == 0 then
            ----print('^3[DEBUG VEHICLE]^7 ISSUE: Vehicle exists in database but not in garage slots!')
        elseif not dbVehicle and #foundInGarages > 0 then
            ----print('^1[DEBUG VEHICLE]^7 ISSUE: Vehicle in garage slots but NOT in database!')
        elseif dbVehicle and #foundInGarages > 0 then
            ----print('^2[DEBUG VEHICLE]^7 STATUS: Vehicle properly synced')
        end
        
        TriggerClientEvent('mh_garage:Notify', source, 
            'Debug complete for plate "' .. cleanPlate .. '". Check console for details.', 'info')
    
    ----print('^4[DEBUG VEHICLE]^7 === END DEBUG ===')
end)

-- ========== QBX HOUSING INTEGRATION EXPORTS ==========
-- Helper function to get table keys count
local function GetTableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        keys[#keys + 1] = k
    end
    return keys
end

-- Export để inject garage động từ qbx_housing
exports('InjectServerGarage', function(garageName, garageConfig)
    if not garageName or not garageConfig then
        --print('^1[MH_GARAGE ERROR]^7 InjectServerGarage: Missing garageName or garageConfig')
        return false
    end
    
    -- CRITICAL VALIDATION: Kiểm tra vehicleSpawnPoint
    if not garageConfig.vehicleSpawnPoint then
        --print('^1[MH_GARAGE ERROR]^7 InjectServerGarage: vehicleSpawnPoint is NULL for ' .. garageName)
        return false
    end
    
    if not garageConfig.vehicleSpawnPoint.x or not garageConfig.vehicleSpawnPoint.y or not garageConfig.vehicleSpawnPoint.z then
        --print('^1[MH_GARAGE ERROR]^7 InjectServerGarage: vehicleSpawnPoint invalid coords for ' .. garageName)
        --print('^1[MH_GARAGE ERROR]^7 vehicleSpawnPoint: ' .. json.encode(garageConfig.vehicleSpawnPoint))
        return false
    end
    
    if not garageConfig.parkVehicle then
        --print('^1[MH_GARAGE ERROR]^7 InjectServerGarage: parkVehicle is NULL for ' .. garageName)
        return false
    end
    
    if not garageConfig.enter then
        --print('^1[MH_GARAGE ERROR]^7 InjectServerGarage: enter is NULL for ' .. garageName)
        return false
    end
    
    if not garageConfig.interior then
        --print('^1[MH_GARAGE ERROR]^7 InjectServerGarage: interior is NULL for ' .. garageName)
        return false
    end
    
    -- CRITICAL: Kiểm tra không ghi đè garage public
    if GaragesData[garageName] and not garageName:find('^house_') then
        --print('^1[MH_GARAGE ERROR]^7 InjectServerGarage: Cannot overwrite public garage "' .. garageName .. '"')
        return false
    end
    
    -- Inject garage vào GaragesData
    GaragesData[garageName] = garageConfig
    
    --print('^2[MH_GARAGE]^7 Injected garage "' .. garageName .. '" with interior "' .. tostring(garageConfig.interior) .. '"')
    --print('^3[MH_GARAGE]^7   vehicleSpawnPoint: ' .. json.encode(garageConfig.vehicleSpawnPoint))
    --print('^3[MH_GARAGE]^7   GaragesData now has ' .. #GetTableKeys(GaragesData) .. ' garages')
    return true
end)

-- Export để xóa garage động
exports('RemoveServerGarage', function(garageName)
    if not garageName then
        --print('^1[MH_GARAGE ERROR]^7 RemoveServerGarage: Missing garageName')
        return false
    end
    
    GaragesData[garageName] = nil
    --print('^1[MH_GARAGE]^7 Removed garage "' .. garageName .. '"')
    return true
end)

-- ========== NUI CALLBACKS ==========

-- Get vehicles for NUI display (all floors combined)
lib.callback.register('mh_garage:cb:GetNUIVehicles', function(source, garage)
    local identifier = Framework.GetIdentifier(source)
    
    --print('^5[NUI DEBUG]^7 GetNUIVehicles called | Garage: "' .. tostring(garage) .. '" | Identifier: ' .. tostring(identifier))
    
    if not identifier or not garage then
        print('^1[NUI ERROR]^7 Missing identifier or garage')
        return {}
    end
    
    -- Check if garage is a public garage (no ownership needed) vs owned garage
    local isPublicGarage = GaragesData[garage] and GaragesData[garage].price == nil
    
    if not isPublicGarage then
        -- For owned garages, check ownership
        if not Garages[identifier] or not Garages[identifier][garage] then
            print('^1[NUI ERROR]^7 Player does not own garage: ' .. garage)
            return {}
        end
    end
    
    -- Get vehicles from database
    local vehicles = db.GetPlayerVehicles(identifier, garage)
    if not vehicles then
        print('^1[NUI ERROR]^7 No vehicles returned from db.GetPlayerVehicles')
        return {}
    end
    
    -- Count vehicles
    local count = 0
    for _ in pairs(vehicles) do
        count = count + 1
    end
    --print('^2[NUI DEBUG]^7 Found ' .. count .. ' vehicles in database for garage')
    
    -- Helper function to get vehicle label
    local function getVehicleLabel(model)
        if not model then return 'Unknown' end
        -- Try to get from QBCore shared vehicles
        if exports['qbx_core'] then
            local success, vehicles = pcall(function()
                return exports['qbx_core']:GetVehiclesByName()
            end)
            if success and vehicles and vehicles[model] then
                return vehicles[model].name or model
            end
        end
        -- Fallback to model name with first letter uppercase
        return model:gsub("^%l", string.upper)
    end
    
    -- Helper function to get vehicle class from qbx_core
    local function getVehicleClass(model)
        if not model then return 0 end
        
        -- Category name to class ID mapping
        local categoryMap = {
            ['compacts'] = 0, ['sedans'] = 1, ['suvs'] = 2, ['coupes'] = 3, ['muscle'] = 4,
            ['sportsclassics'] = 5, ['sports'] = 6, ['super'] = 7, ['motorcycles'] = 8,
            ['offroad'] = 9, ['industrial'] = 10, ['utility'] = 11, ['vans'] = 12,
            ['cycles'] = 13, ['boats'] = 14, ['helicopters'] = 15, ['planes'] = 16,
            ['service'] = 17, ['emergency'] = 18, ['military'] = 19, ['commercial'] = 20, ['trains'] = 21
        }
        
        if exports['qbx_core'] then
            local success, vehicles = pcall(function()
                return exports['qbx_core']:GetVehiclesByName()
            end)
            if success and vehicles and vehicles[model] then
                local cat = vehicles[model].category
                if cat then
                    if type(cat) == 'number' then return cat end
                    return categoryMap[string.lower(cat)] or 0
                end
            end
        end
        return 0
    end
    
    -- Build NUI vehicle list with formatted data
    local nuiVehicles = {}
    
    -- For owned garages with slots
    if Garages[identifier] and Garages[identifier][garage] and Garages[identifier][garage].slot then
        -- Get all vehicles from garage slots (across all floors)
        local slotVehicles = {}
        for floorNum, slots in pairs(Garages[identifier][garage].slot) do
            if type(slots) == "table" then
                for slotIdx, plate in pairs(slots) do
                    if plate then
                        local cleanPlate = string.strtrim(plate)
                        slotVehicles[cleanPlate] = true
                    end
                end
            end
        end
        
        for plate, mods in pairs(vehicles) do
            local cleanPlate = string.strtrim(plate)
            
            -- Only include vehicles that are in a slot
            if slotVehicles[cleanPlate] then
                -- Use vehicle spawn name for image, fallback to model
                local vehicleSpawn = mods.vehicle or mods.model or 'unknown'
                local vehicleName = getVehicleLabel(vehicleSpawn)
                local fuelLevel = mods.fuelLevel or 100
                -- Body health: 0-1000, convert to percentage
                local bodyHealth = mods.bodyHealth and math.floor(mods.bodyHealth / 10) or 100
                -- Engine health: 0-1000, convert to percentage  
                local engineHealth = mods.engineHealth and math.floor(mods.engineHealth / 10) or 100
                
                -- Get vehicle class from qbx_core
                local vehicleClass = getVehicleClass(vehicleSpawn)
                
                table.insert(nuiVehicles, {
                    plate = cleanPlate,
                    model = mods.model or 'unknown',
                    vehicle = vehicleSpawn, -- For image URL
                    name = vehicleName,
                    class = vehicleClass,
                    fuel = fuelLevel,
                    body = bodyHealth,
                    engine = engineHealth
                })
                
                --print('^2[NUI DEBUG]^7 Added vehicle from slot: ' .. cleanPlate .. ' | Vehicle: ' .. vehicleSpawn .. ' | Name: ' .. vehicleName)
            end
        end
    else
        -- For public garages or garages without slot system, show all vehicles
        for plate, mods in pairs(vehicles) do
            local cleanPlate = string.strtrim(plate)
            -- Use vehicle spawn name for image, fallback to model
            local vehicleSpawn = mods.vehicle or mods.model or 'unknown'
            local vehicleName = getVehicleLabel(vehicleSpawn)
            local fuelLevel = mods.fuelLevel or 100
            -- Body health: 0-1000, convert to percentage
            local bodyHealth = mods.bodyHealth and math.floor(mods.bodyHealth / 10) or 100
            -- Engine health: 0-1000, convert to percentage  
            local engineHealth = mods.engineHealth and math.floor(mods.engineHealth / 10) or 100
            
            -- Get vehicle class from qbx_core
            local vehicleClass = getVehicleClass(vehicleSpawn)
            
            table.insert(nuiVehicles, {
                plate = cleanPlate,
                model = mods.model or 'unknown',
                vehicle = vehicleSpawn, -- For image URL
                name = vehicleName,
                class = vehicleClass,
                fuel = fuelLevel,
                body = bodyHealth,
                engine = engineHealth
            })
            
            --print('^2[NUI DEBUG]^7 Added vehicle: ' .. cleanPlate .. ' | Vehicle: ' .. vehicleSpawn .. ' | Name: ' .. vehicleName)
        end
    end
    
    --print('^2[NUI DEBUG]^7 Returning ' .. #nuiVehicles .. ' vehicles to NUI')
    return nuiVehicles
end)

-- Get vehicles for specific floor (NUI)
lib.callback.register('mh_garage:cb:GetNUIVehiclesFloor', function(source, garage, floor)
    local identifier = Framework.GetIdentifier(source)
    
    if not identifier or not garage then
        return {}
    end
    
    -- Check if garage is a public garage (no ownership needed)
    local isPublicGarage = GaragesData[garage] and GaragesData[garage].price == nil
    
    if not isPublicGarage then
        if not Garages[identifier] or not Garages[identifier][garage] then
            return {}
        end
    end
    
    -- Get vehicles from database
    local vehicles = db.GetPlayerVehicles(identifier, garage)
    if not vehicles then
        return {}
    end
    
    -- Helper function to get vehicle label
    local function getVehicleLabel(model)
        if not model then return 'Unknown' end
        if exports['qbx_core'] then
            local success, vehicles = pcall(function()
                return exports['qbx_core']:GetVehiclesByName()
            end)
            if success and vehicles and vehicles[model] then
                return vehicles[model].name or model
            end
        end
        return model:gsub("^%l", string.upper)
    end
    
    -- Helper function to get vehicle class from qbx_core
    local function getVehicleClass(model)
        if not model then return 0 end
        
        -- Category name to class ID mapping
        local categoryMap = {
            ['compacts'] = 0, ['sedans'] = 1, ['suvs'] = 2, ['coupes'] = 3, ['muscle'] = 4,
            ['sportsclassics'] = 5, ['sports'] = 6, ['super'] = 7, ['motorcycles'] = 8,
            ['offroad'] = 9, ['industrial'] = 10, ['utility'] = 11, ['vans'] = 12,
            ['cycles'] = 13, ['boats'] = 14, ['helicopters'] = 15, ['planes'] = 16,
            ['service'] = 17, ['emergency'] = 18, ['military'] = 19, ['commercial'] = 20, ['trains'] = 21
        }
        
        if exports['qbx_core'] then
            local success, vehicles = pcall(function()
                return exports['qbx_core']:GetVehiclesByName()
            end)
            if success and vehicles and vehicles[model] then
                local cat = vehicles[model].category
                if cat then
                    if type(cat) == 'number' then return cat end
                    return categoryMap[string.lower(cat)] or 0
                end
            end
        end
        return 0
    end
    
    -- Build NUI vehicle list
    local nuiVehicles = {}
    
    -- For owned garages with slots
    if Garages[identifier] and Garages[identifier][garage] and Garages[identifier][garage].slot then
        local floorIndex = tonumber(floor) or 1
        local slotData = Garages[identifier][garage].slot[floorIndex] or Garages[identifier][garage].slot[tostring(floorIndex)] or {}
        
        for slotIdx, plate in pairs(slotData) do
            if plate then
                local cleanPlate = string.strtrim(plate)
                local mods = vehicles[cleanPlate]
                
                if mods then
                    local vehicleSpawn = mods.vehicle or mods.model or 'unknown'
                    local vehicleName = getVehicleLabel(vehicleSpawn)
                    local fuelLevel = mods.fuelLevel or 100
                    
                    -- Get vehicle class from qbx_core
                    local vehicleClass = getVehicleClass(vehicleSpawn)
                    
                    table.insert(nuiVehicles, {
                        plate = cleanPlate,
                        model = mods.model or 'unknown',
                        vehicle = vehicleSpawn,
                        name = vehicleName,
                        class = vehicleClass,
                        fuel = fuelLevel
                    })
                end
            end
        end
    else
        -- For public garages, show all vehicles
        for plate, mods in pairs(vehicles) do
            local cleanPlate = string.strtrim(plate)
            local vehicleSpawn = mods.vehicle or mods.model or 'unknown'
            local vehicleName = getVehicleLabel(vehicleSpawn)
            local fuelLevel = mods.fuelLevel or 100
            
            -- Get vehicle class from qbx_core
            local vehicleClass = getVehicleClass(vehicleSpawn)
            
            table.insert(nuiVehicles, {
                plate = cleanPlate,
                model = mods.model or 'unknown',
                vehicle = vehicleSpawn,
                name = vehicleName,
                class = vehicleClass,
                fuel = fuelLevel
            })
        end
    end
    
    return nuiVehicles
end)

-- Take vehicle out via NUI (from outside garage) - Uses same logic as TakeVehicleOutPhone
RegisterNetEvent('mh_garage:server:TakeVehicleOutNUI', function(name, plate)
    plate = string.strtrim(plate)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local currentTimeMS = GetGameTimer() -- Millisecond precision
    
    --print('^5[NUI TAKEOUT]^7 TakeVehicleOutNUI called | Garage: ' .. tostring(name) .. ' | Plate: ' .. plate)
    
    -- CRITICAL: HIGH-PRECISION check using milliseconds to prevent same-second duplicates
    local spawnKeyMS = identifier .. ':' .. plate
    if PendingGarageSpawnsMS[spawnKeyMS] then
        local timeSinceRequestMS = currentTimeMS - PendingGarageSpawnsMS[spawnKeyMS]
        if timeSinceRequestMS < SPAWN_COOLDOWN_MS and timeSinceRequestMS >= 0 then
            TriggerClientEvent('mh_garage:Notify', src, 'Xe này đang được lấy ra, vui lòng không spam! (' .. math.ceil((SPAWN_COOLDOWN_MS - timeSinceRequestMS) / 1000) .. 's)', 'error')
            return
        end
    end
    
    -- Mark this plate as pending with MS precision IMMEDIATELY
    PendingGarageSpawnsMS[spawnKeyMS] = currentTimeMS
    
    -- CRITICAL: Player-level lock - only allow ONE spawn at a time per player
    if PlayerSpawnLock[identifier] then
        local lockAge = os.time() - PlayerSpawnLock[identifier]
        if lockAge < PLAYER_LOCK_TIMEOUT then
            TriggerClientEvent('mh_garage:Notify', src, 'Vui lòng đợi, xe đang được xử lý... (' .. (PLAYER_LOCK_TIMEOUT - lockAge) .. 's)', 'error')
            PendingGarageSpawnsMS[spawnKeyMS] = nil -- Clear MS lock since we're returning
            return
        end
    end
    
    -- ANTI-DUPLICATE: Check if there's already a pending spawn for this plate (seconds-based)
    local spawnKey = identifier .. ':' .. plate
    if PendingGarageSpawns[spawnKey] then
        local timeSinceRequest = os.time() - PendingGarageSpawns[spawnKey]
        if timeSinceRequest < SPAWN_COOLDOWN then
            TriggerClientEvent('mh_garage:Notify', src, 'Xe này đang được lấy ra, vui lòng không spam!', 'error')
            PendingGarageSpawnsMS[spawnKeyMS] = nil -- Clear MS lock since we're returning
            return
        end
    end
    
    -- ATOMIC: Mark BOTH locks immediately before any processing
    PlayerSpawnLock[identifier] = os.time()
    PendingGarageSpawns[spawnKey] = os.time()
    
    -- Get spawn coords
    local spawnCoords = GaragesData[name] and GaragesData[name].vehicleSpawnPoint
    if not spawnCoords then
        TriggerClientEvent('mh_garage:Notify', src, 'Lỗi: không tìm thấy vị trí spawn', 'error')
        PendingGarageSpawns[spawnKey] = nil
        PendingGarageSpawnsMS[spawnKeyMS] = nil
        PlayerSpawnLock[identifier] = nil
        return
    end
    
    -- GET: vehicleId from plate
    local vehicleId = exports.qbx_vehicles:GetVehicleIdByPlate(plate)
    if not vehicleId then
        TriggerClientEvent('mh_garage:Notify', src, 'Không tìm thấy thông tin xe', 'error')
        PendingGarageSpawns[spawnKey] = nil
        PendingGarageSpawnsMS[spawnKeyMS] = nil
        PlayerSpawnLock[identifier] = nil
        return
    end
    
    -- GET: Full vehicle data
    local playerVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if not playerVehicle then
        TriggerClientEvent('mh_garage:Notify', src, 'Lỗi dữ liệu xe', 'error')
        PendingGarageSpawns[spawnKey] = nil
        PendingGarageSpawnsMS[spawnKeyMS] = nil
        PlayerSpawnLock[identifier] = nil
        return
    end
    
    -- Check if garage has pricetakeout and charge the player
    local pricetakeout = GaragesData[name] and GaragesData[name].pricetakeout or 0
    
    if pricetakeout > 0 then
        if not utils.PayPrice(src, pricetakeout) then
            TriggerClientEvent('mh_garage:Notify', src, locale('no_money_takeout', pricetakeout), 'error')
            PendingGarageSpawns[spawnKey] = nil
            PendingGarageSpawnsMS[spawnKeyMS] = nil
            PlayerSpawnLock[identifier] = nil
            return
        end
        TriggerClientEvent('mh_garage:Notify', src, locale('paid_takeout', pricetakeout), 'info')
    end
    
    -- PREPARE SPAWN DATA - Create deep copy to avoid modifying original
    local spawnProps = {}
    for k, v in pairs(playerVehicle.props) do
        if type(v) == 'table' then
            spawnProps[k] = {}
            for k2, v2 in pairs(v) do
                spawnProps[k][k2] = v2
            end
        else
            spawnProps[k] = v
        end
    end
    
    -- FORCE SET PLATE
    spawnProps.plate = plate
    
    -- Validate spawn coordinates (ensure it's vec4)
    if type(spawnCoords) ~= 'vector4' then
        spawnCoords = vec4(spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w or 0.0)
    end
    
    -- Validate model hash - MUST be number
    local modelHash = type(spawnProps.model) == 'string' and joaat(spawnProps.model) or spawnProps.model
    if type(modelHash) ~= 'number' then
        --print('^1[NUI TAKEOUT ERROR]^7 Invalid model hash: ' .. tostring(spawnProps.model))
        TriggerClientEvent('mh_garage:Notify', src, 'Lỗi: Model xe không hợp lệ', 'error')
        PendingGarageSpawns[spawnKey] = nil
        PendingGarageSpawnsMS[spawnKeyMS] = nil
        PlayerSpawnLock[identifier] = nil
        return
    end
    
    -- Generate unique spawn request ID to prevent duplicate processing
    local spawnRequestId = identifier .. ':' .. plate .. ':' .. tostring(currentTimeMS)
    
    -- Store pending spawn data for confirmation callback
    if not PendingSpawnRequests then PendingSpawnRequests = {} end
    PendingSpawnRequests[spawnRequestId] = {
        src = src,
        identifier = identifier,
        plate = plate,
        vehicleId = vehicleId,
        garageName = name,
        spawnKey = spawnKey,
        spawnKeyMS = spawnKeyMS,
        timestamp = os.time()
    }
    
    -- PREPARE: Vehicle data for client-side spawning
    spawnProps.model = modelHash -- Ensure model hash is correct type
    spawnProps.fuelLevel = spawnProps.fuelLevel or 100.0
    spawnProps.bodyHealth = spawnProps.bodyHealth or 1000.0
    spawnProps.engineHealth = spawnProps.engineHealth or 1000.0
    
    -- CLIENT-SIDE SPAWN: Send vehicle data to client - client will spawn and confirm back
    -- This avoids qbx.spawnVehicle server-side sync issues that cause duplicate vehicles
    TriggerClientEvent('mh_garage:client:SpawnVehicleNUI', src, spawnProps, spawnCoords, plate, vehicleId, spawnRequestId)
    
    --print('^3[NUI TAKEOUT]^7 Sent spawn request to client: ' .. plate .. ' | RequestId: ' .. spawnRequestId)
end)

-- Server event to handle spawn result from client (CLIENT-SIDE SPAWNING)
-- Client spawns vehicle locally, then notifies server of success/failure
PendingSpawnRequests = PendingSpawnRequests or {}

RegisterNetEvent('mh_garage:server:SpawnVehicleResult', function(vehicleId, spawnRequestId, success, netId, errorMsg)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    -- Get pending request data
    local requestData = PendingSpawnRequests[spawnRequestId]
    if not requestData then
        --print('^1[SPAWN RESULT]^7 Unknown spawn request: ' .. tostring(spawnRequestId))
        return
    end
    
    -- Security check - make sure source matches
    if requestData.src ~= src or requestData.identifier ~= identifier then
        --print('^1[SPAWN RESULT]^7 Source mismatch for request: ' .. spawnRequestId)
        return
    end
    
    local plate = requestData.plate
    local spawnKey = requestData.spawnKey
    local spawnKeyMS = requestData.spawnKeyMS
    local garageName = requestData.garageName

    -- If this was an impound spawn, update state and finish
    if requestData.impound then
        local spawnKeyImp = identifier .. ':' .. plate
        if not success then
            -- clear impound lock on failure
            if PendingImpoundSpawns[spawnKeyImp] then
                PendingImpoundSpawns[spawnKeyImp] = nil
            end
            PendingSpawnRequests[spawnRequestId].success = false
            PendingSpawnRequests[spawnRequestId].handled = true
            TriggerClientEvent('mh_garage:Notify', src, 'Lỗi spawn impound xe: ' .. tostring(errorMsg), 'error')
            return
        end

        -- success: update metadata/state and database
        if netId then
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh and DoesEntityExist(veh) then
                Entity(veh).state:set('vehicleid', vehicleId, false)
                exports.qbx_vehicles:SaveVehicle(veh, { state = 0 })
            end
        end

        -- ensure stored flag cleared in database as well
        db.UpdateStored(plate, identifier, 0)

        -- clear impound lock
        if PendingImpoundSpawns[spawnKeyImp] then
            PendingImpoundSpawns[spawnKeyImp] = nil
        end

        PendingSpawnRequests[spawnRequestId].success = true
        PendingSpawnRequests[spawnRequestId].netId = netId
        PendingSpawnRequests[spawnRequestId].handled = true
        return
    end

    if not success then
        -- Spawn failed - clear locks and cleanup
        --print('^1[SPAWN RESULT]^7 Client spawn failed for ' .. plate .. ': ' .. tostring(errorMsg))
        PendingGarageSpawns[spawnKey] = nil
        PendingGarageSpawnsMS[spawnKeyMS] = nil
        PlayerSpawnLock[identifier] = nil
        PendingSpawnRequests[spawnRequestId] = nil
        TriggerClientEvent('mh_garage:Notify', src, 'Lỗi spawn xe: ' .. tostring(errorMsg), 'error')
        return
    end
    
    -- SUCCESS: Update database and caches
    --print('^2[SPAWN RESULT]^7 Client spawn SUCCESS for ' .. plate .. ' | NetId: ' .. tostring(netId))
    
    -- Get vehicle entity from netId for state setting
    local veh = netId and NetworkGetEntityFromNetworkId(netId) or nil
    
    if veh and DoesEntityExist(veh) then
        -- Set vehicle metadata
        Entity(veh).state:set('vehicleid', vehicleId, false)
        
        -- UPDATE: Vehicle state to OUT via qbx_vehicles
        exports.qbx_vehicles:SaveVehicle(veh, {
            state = 0 -- VehicleState.OUT
        })
    end
    
    -- CRITICAL: Update database: set state=0 AND clear garage field
    db.UpdateStored(plate, identifier, 0)
    
    -- CRITICAL: Remove vehicle from ALL garage slots in memory and database
    RemoveVehicleFromAllGarages(identifier, plate)
    
    -- Cleanup pending request
    PendingSpawnRequests[spawnRequestId] = nil
    
    -- Clear locks after spawn (with small delay for safety)
    SetTimeout(3000, function()
        PendingGarageSpawns[spawnKey] = nil
        PendingGarageSpawnsMS[spawnKeyMS] = nil
        PlayerSpawnLock[identifier] = nil
    end)
end)

-- Cleanup stale spawn requests periodically (prevent memory leak)
CreateThread(function()
    while true do
        Wait(60000) -- Every 60 seconds
        local currentTime = os.time()
        local cleanedCount = 0
        
        for requestId, data in pairs(PendingSpawnRequests) do
            if currentTime - data.timestamp > 30 then -- Requests older than 30 seconds
                PendingSpawnRequests[requestId] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        if cleanedCount > 0 then
            --print('^3[SPAWN CLEANUP]^7 Cleaned ' .. cleanedCount .. ' stale spawn requests')
        end
    end
end)

-- Admin command to sync mh_garage slots with player_vehicles table
RegisterCommand('syncgarage', function(source, args)
    if source ~= 0 then
        local player = exports.qbx_core:GetPlayer(source)
        if not player or not IsPlayerAceAllowed(source, 'admin') then
            return
        end
    end
    
    --print('^3[GARAGE SYNC]^7 Starting synchronization...')
    
    -- OPTIMIZATION: Pre-load all stored vehicles in ONE query (avoid N+1 problem)
    local allVehicles = MySQL.query.await('SELECT plate, citizenid, state, garage FROM player_vehicles WHERE state = 1')
    local vehicleCache = {}
    for _, v in ipairs(allVehicles or {}) do
        local key = string.strtrim(v.plate) .. ':' .. v.citizenid
        vehicleCache[key] = { state = v.state, garage = v.garage }
    end
    --print('^3[GARAGE SYNC]^7 Loaded ' .. #(allVehicles or {}) .. ' stored vehicles into cache')
    
    -- Intentional: Admin command needs to scan all garage entries
    -- @oxmysql-ignore-warning
    local garageData = MySQL.query.await('SELECT owner, name, data FROM mh_garage')
    local fixedCount = 0
    local totalSlots = 0
    local updatedGarages = {}
    
    for _, garage in ipairs(garageData or {}) do
        local identifier = garage.owner
        local garageName = garage.name
        local data = json.decode(garage.data)
        
        if data and data.slot then
            local modified = false
            
            for floorNum, slots in pairs(data.slot) do
                if type(slots) == "table" then
                    for slotNum, plate in pairs(slots) do
                        if plate then
                            totalSlots = totalSlots + 1
                            plate = string.strtrim(plate)
                            
                            -- Use cached data instead of individual query
                            local cacheKey = plate .. ':' .. identifier
                            local vehicle = vehicleCache[cacheKey]
                            
                            if not vehicle then
                                -- Vehicle doesn't exist in player_vehicles, remove from slot
                               -- print('^1[GARAGE SYNC]^7 Removing orphan slot: ' .. plate .. ' (vehicle not found)')
                                data.slot[floorNum][slotNum] = nil
                                modified = true
                                fixedCount = fixedCount + 1
                            elseif vehicle.state == 0 then
                                -- Vehicle was taken out, remove from slot
                                --print('^3[GARAGE SYNC]^7 Removing slot for taken-out vehicle: ' .. plate)
                                data.slot[floorNum][slotNum] = nil
                                modified = true
                                fixedCount = fixedCount + 1
                            elseif vehicle.garage ~= garageName then
                                -- Vehicle is in a different garage, remove from this slot
                              -- print('^3[GARAGE SYNC]^7 Removing slot (vehicle in different garage): ' .. plate)
                                data.slot[floorNum][slotNum] = nil
                                modified = true
                                fixedCount = fixedCount + 1
                            end
                        end
                    end
                end
            end
            
            if modified then
                -- Batch updates instead of immediate execute
                table.insert(updatedGarages, {
                    data = json.encode(data),
                    owner = identifier,
                    name = garageName,
                    parsed = data
                })
            end
        end
    end
    
    -- Batch update all modified garages
    if #updatedGarages > 0 then
        local updateQueries = {}
        for _, g in ipairs(updatedGarages) do
            table.insert(updateQueries, {
                query = 'UPDATE mh_garage SET data = ? WHERE owner = ? AND name = ?',
                values = { g.data, g.owner, g.name }
            })
            -- Update in-memory cache
            if Garages[g.owner] and Garages[g.owner][g.name] then
                Garages[g.owner][g.name] = g.parsed
            end
        end
        MySQL.transaction(updateQueries)
        --print('^2[GARAGE SYNC]^7 Updated ' .. #updatedGarages .. ' garages in batch')
    end
    
    --print('^2[GARAGE SYNC]^7 Completed! Fixed ' .. fixedCount .. ' slots out of ' .. totalSlots .. ' total slots')
    
    if source ~= 0 then
        TriggerClientEvent('mh_garage:Notify', source, 'Đồng bộ hoàn tất! Đã sửa ' .. fixedCount .. ' slots', 'success')
    end
end, false)

lib.versionCheck('mod-haven/mh_garage')