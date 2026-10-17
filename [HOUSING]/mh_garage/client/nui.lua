-- NUI Client integration for mh_garage
if not lib then return end

local Edit = require 'edit_functions'
local GaragesData = lib.load 'config.garages'
local General = lib.load 'config.general'
local Interior = lib.load 'config.interior'
local Garage = require 'client.garage'

local NUI = {}
local isNuiOpen = false
local currentGarageNUI = nil

-- Anti-spam protection for NUI takeout
local isProcessingTakeout = false
local lastTakeoutTime = 0
local lastTakeoutPlate = nil
local NUI_TAKEOUT_COOLDOWN = 5000 -- 5 seconds cooldown

lib.locale()


-- Dynamic GaragesData Resolver for Housing and Runtime Injected Garages
local function EnsureNuiGarageData(garageName)
    if not garageName then return false end
    if GaragesData and GaragesData[garageName] then return true end
    
    -- 1. Try from mh_garage GetGaragesData export
    local ok1, gData = pcall(function() return exports['mh_garage']:GetGaragesData() end)
    if ok1 and gData and gData[garageName] then
        GaragesData[garageName] = gData[garageName]
        return true
    end
    
    -- 2. Try from qbx_housing GetHouseGarageConfig export
    local ok2, hConf = pcall(function() return exports['qbx_housing']:GetHouseGarageConfig(garageName) end)
    if ok2 and hConf then
        GaragesData[garageName] = hConf
        return true
    end
    
    -- 3. Direct auto-builder for house garages
    if garageName:find('^house_') then
        local houseId = garageName:gsub('^house_', '')
        local ok3, houseConfig = pcall(function() return exports['qbx_housing']:GetHouseConfig(houseId) end)
        if ok3 and houseConfig and houseConfig.garagePoint and houseConfig.garageSpawn then
            local gPoint = houseConfig.garagePoint
            local gSpawn = houseConfig.garageSpawn
            local spawnHeading = gSpawn.w or gSpawn.h or (type(gSpawn) == 'table' and gSpawn[4]) or 0.0
            local gInterior = 'low_end'
            local gMaxVehs = 2
            local isGang = (houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or houseConfig.type == 'gang'
            if isGang then
                local gLevel = tonumber(houseConfig.level) or 1
                if gLevel == 2 then 
                    gInterior = 'medium'
                    gMaxVehs = 6
                elseif gLevel >= 3 then 
                    gInterior = 'autoshop'
                    gMaxVehs = 10
                else
                    gInterior = 'low_end'
                    gMaxVehs = 2
                end
            end
            GaragesData[garageName] = {
                type = 'car',
                enter = vector3(gPoint.x, gPoint.y, gPoint.z),
                parkVehicle = vector3(gPoint.x, gPoint.y, gPoint.z),
                vehicleSpawnPoint = vector4(gSpawn.x, gSpawn.y, gSpawn.z, spawnHeading),
                price = nil,
                pricetakeout = 0,
                blip = { id = 0, scale = 0, colour = 0 },
                blackListClass = { 14, 15, 16, 19, 21 },
                GarageInfo = 'Garage ' .. (isGang and 'Trụ Sở Xã Đoàn' or ('nhà ' .. houseId)) .. '. Có thể để ' .. gMaxVehs .. ' xe.',
                interior = gInterior
            }
            return true
        end
    end
    
    return false
end

-- Open NUI with garage data
function NUI.OpenGarageNUI(garageName, interior)
    EnsureNuiGarageData(garageName)
    if not GaragesData[garageName] then 
        print('^1[NUI ERROR]^7 Garage not found in GaragesData: ' .. tostring(garageName))
        return 
    end
    if interior == 'small' or not Interior[interior] then
        interior = (Interior[interior] and interior) or (Interior['low_end'] and 'low_end') or (Interior['medium'] and 'medium') or 'low_end'
    end
    if not Interior[interior] then 
        print('^1[NUI ERROR]^7 Interior not found: ' .. tostring(interior))
        return 
    end
    if isNuiOpen then 
        print('^3[NUI]^7 NUI already open')
        return 
    end
    
    print('^2[NUI]^7 Opening NUI for garage: ' .. garageName .. ' | Interior: ' .. interior)
    
    isNuiOpen = true
    currentGarageNUI = { name = garageName, interior = interior }
    
    -- Check if player owns garage
    local doesOwn = lib.callback.await('mh_garage:cb:DoesOwn', false, garageName)
    print('^2[NUI]^7 Does player own garage: ' .. tostring(doesOwn))
    
    -- Get vehicles if player owns garage
    local vehicles = {}
    if doesOwn then
        print('^2[NUI]^7 Fetching vehicles...')
        local vehicleData = lib.callback.await('mh_garage:cb:GetNUIVehicles', false, garageName)
        vehicles = vehicleData or {}
        print('^2[NUI]^7 Received ' .. #vehicles .. ' vehicles')
    end
    
    -- Calculate total floors
    local totalFloors = #Interior[interior].Vehicles or 1
    
    -- Get price takeout
    local pricetakeout = GaragesData[garageName].pricetakeout or 0
    
    print('^2[NUI]^7 Sending data to NUI | Vehicles: ' .. #vehicles .. ' | Floors: ' .. totalFloors)
    
    -- Send data to NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGarage',
        garageData = {
            garageName = garageName,
            interior = interior,
            doesOwn = doesOwn,
            vehicles = vehicles,
            price = GaragesData[garageName].price,
            garageInfo = GaragesData[garageName].GarageInfo,
            totalFloors = totalFloors,
            pricetakeout = pricetakeout
        }
    })
end

-- Close NUI
function NUI.CloseGarageNUI()
    if not isNuiOpen then return end
    
    isNuiOpen = false
    currentGarageNUI = nil
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeGarage'
    })
end

-- NUI Callbacks
RegisterNUICallback('closeNUI', function(data, cb)
    NUI.CloseGarageNUI()
    cb({})
end)

RegisterNUICallback('enterGarage', function(data, cb)
    local garageName = data.garageName
    local floor = data.floor
    EnsureNuiGarageData(garageName)
    
    if not garageName or not GaragesData[garageName] then 
        cb({ success = false })
        return 
    end
    
    local interior = GaragesData[garageName].interior
    
    -- Close NUI first
    NUI.CloseGarageNUI()
    
    -- Use existing garage enter logic with floor
    if cache.vehicle then
        Edit.Notify(locale('leave_vehicle_first'))
        cb({ success = false })
        return
    end
    
    -- Set the floor if provided
    if floor and type(floor) == 'number' then
        -- Enter garage with specified floor
        Garage.EnterGarageWithFloor(garageName, interior, floor)
    else
        Garage.EnterGarage(garageName, interior)
    end
    
    cb({ success = true })
end)

RegisterNUICallback('buyGarage', function(data, cb)
    local garageName = data.garageName
    local interior = data.interior
    
    if not garageName or not GaragesData[garageName] then 
        cb({ success = false })
        return 
    end
    
    -- Close NUI first
    NUI.CloseGarageNUI()
    
    -- Trigger buy event
    TriggerServerEvent('mh_garage:server:BuyGarage', garageName, interior)
    
    cb({ success = true })
end)

RegisterNUICallback('previewGarage', function(data, cb)
    local garageName = data.garageName
    local interior = data.interior
    
    if not garageName or not GaragesData[garageName] then 
        cb({ success = false })
        return 
    end
    
    -- Close NUI first
    NUI.CloseGarageNUI()
    
    -- Use existing preview logic
    Garage.PreviewGarage(garageName, interior)
    
    cb({ success = true })
end)

RegisterNUICallback('refreshGarage', function(data, cb)
    local garageName = data.garageName
    
    if not garageName or not GaragesData[garageName] then 
        cb({ success = false })
        return 
    end
    
    -- Show fix vehicle menu (keeping NUI open)
    NUI.CloseGarageNUI()
    Garage.ShowFixVehicleMenu(garageName)
    
    cb({ success = true })
end)

RegisterNUICallback('changeFloor', function(data, cb)
    local garageName = data.garageName
    local floor = data.floor
    
    if not garageName or not GaragesData[garageName] then 
        cb({ success = false, vehicles = {} })
        return 
    end
    
    -- Get vehicles for the specified floor
    local vehicleData = lib.callback.await('mh_garage:cb:GetNUIVehiclesFloor', false, garageName, floor)
    
    -- Send updated vehicles back to NUI
    SendNUIMessage({
        action = 'updateVehicles',
        vehicles = vehicleData or {}
    })
    
    cb({ success = true, vehicles = vehicleData or {} })
end)

RegisterNUICallback('takeoutVehicle', function(data, cb)
    local garageName = data.garageName
    local plate = data.plate
    local vehicleData = data.vehicle
    EnsureNuiGarageData(garageName)
    
    if not garageName or not plate or not GaragesData[garageName] then 
        cb({ success = false })
        return 
    end
    
    -- ANTI-DUPLICATE: Check if already processing a takeout
    if isProcessingTakeout then
        print('^3[NUI TAKEOUT]^7 Blocked - already processing takeout')
        cb({ success = false, reason = 'processing' })
        return
    end
    
    -- ANTI-DUPLICATE: Check cooldown
    local currentTime = GetGameTimer()
    if currentTime - lastTakeoutTime < NUI_TAKEOUT_COOLDOWN then
        local remaining = math.ceil((NUI_TAKEOUT_COOLDOWN - (currentTime - lastTakeoutTime)) / 1000)
        Edit.Notify('Vui lòng đợi ' .. remaining .. ' giây trước khi lấy xe tiếp', 'error')
        cb({ success = false, reason = 'cooldown' })
        return
    end
    
    -- ANTI-DUPLICATE: Check if same plate as last takeout (double-click protection)
    if lastTakeoutPlate == plate and currentTime - lastTakeoutTime < NUI_TAKEOUT_COOLDOWN then
        print('^3[NUI TAKEOUT]^7 Blocked - same plate within cooldown')
        cb({ success = false, reason = 'duplicate' })
        return
    end
    
    -- Set processing flag IMMEDIATELY before any async operations
    isProcessingTakeout = true
    lastTakeoutTime = currentTime
    lastTakeoutPlate = plate
    
    -- Close NUI first to prevent further clicks
    NUI.CloseGarageNUI()
    
    -- Check spawn point
    local freespot = lib.callback.await('mh_garage:cb:CheckSpawnPoint', 100, garageName)
    
    if not freespot then
        Edit.Notify(locale('no_free_spawnpoint'), 'error')
        isProcessingTakeout = false
        cb({ success = false })
        return
    end
    
    -- Trigger take out vehicle from outside garage
    TriggerServerEvent('mh_garage:server:TakeVehicleOutNUI', garageName, plate)
    
    -- Reset processing flag after a delay (server handles the actual spawn)
    SetTimeout(3000, function()
        isProcessingTakeout = false
    end)
    
    cb({ success = true })
end)

-- Export function
exports('OpenGarageNUI', function(garageName, interior)
    NUI.OpenGarageNUI(garageName, interior)
end)

exports('CloseGarageNUI', function()
    NUI.CloseGarageNUI()
end)

exports('IsNuiOpen', function()
    return isNuiOpen
end)

-- ESC key to close
CreateThread(function()
    while true do
        Wait(0)
        if isNuiOpen then
            if IsControlJustPressed(0, 322) then -- ESC key
                NUI.CloseGarageNUI()
            end
        else
            Wait(500)
        end
    end
end)



-- =========================================================================
-- QBX HOUSING DYNAMIC GARAGES SYNC FOR NUI
-- =========================================================================
RegisterNetEvent('qbx_housing:client:SyncHouseGarage', function(garageName, garageConfig)
    if garageName and garageConfig then
        GaragesData[garageName] = garageConfig
    end
end)

RegisterNetEvent('qbx_housing:client:SyncAllGarages', function(houseGarages)
    if not houseGarages then return end
    for garageName, garageConfig in pairs(houseGarages) do
        GaragesData[garageName] = garageConfig
    end
end)

exports('InjectNuiGarage', function(garageName, garageConfig)
    if garageName and garageConfig then
        GaragesData[garageName] = garageConfig
        return true
    end
    return false
end)

return NUI
