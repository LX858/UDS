-- Test script để kiểm tra các tính năng của xn_pdtools

-- Command để spawn xe test
-- RegisterCommand('spawncar', function(source, args)
--     local ped = PlayerPedId()
--     local coords = GetEntityCoords(ped)
--     local model = args[1] or 'adder'
--     local plate = args[2] or 'TEST123'
    
--     RequestModel(model)
--     while not HasModelLoaded(model) do
--         Wait(500)
--     end
    
--     local vehicle = CreateVehicle(model, coords.x + 2, coords.y, coords.z, GetEntityHeading(ped), true, false)
--     SetVehicleNumberPlateText(vehicle, plate)
--     SetEntityAsMissionEntity(vehicle, true, true)
    
--     print('Spawned vehicle: ' .. model .. ' with plate: ' .. plate)
-- end, false)

-- Command để khóa xe
-- RegisterCommand('lockcar', function()
--     local ped = PlayerPedId()
--     local vehicle = GetVehiclePedIsIn(ped, true)
    
--     if vehicle ~= 0 then
--         SetVehicleDoorsLocked(vehicle, 2) -- 2 = locked
--         SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        
--         local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
--         print('Locked vehicle: ' .. plate)
        
--         -- Play sound effect
--         PlaySoundFrontend(-1, "VEHICLE_LOCKS", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
--     else
--         print('No vehicle found')
--     end
-- end, false)

-- -- Command để kiểm tra trạng thái khóa xe
-- RegisterCommand('checklock', function()
--     local ped = PlayerPedId()
--     local vehicle = GetVehiclePedIsIn(ped, true)
    
--     if vehicle ~= 0 then
--         local lockStatus = GetVehicleDoorLockStatus(vehicle)
--         local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
        
--         local statusText = ""
--         if lockStatus == 0 then
--             statusText = "No lock"
--         elseif lockStatus == 1 then
--             statusText = "Unlocked"
--         elseif lockStatus == 2 then
--             statusText = "Locked"
--         elseif lockStatus == 3 then
--             statusText = "Lockout_Player_Only"
--         elseif lockStatus == 4 then
--             statusText = "Locked_Player_Only"
--         else
--             statusText = "Unknown (" .. lockStatus .. ")"
--         end
        
--         print('Vehicle ' .. plate .. ' lock status: ' .. statusText)
--     else
--         print('No vehicle found')
--     end
-- end, false)

-- -- Command để nổ xe (test xóa xe bị nổ)
-- RegisterCommand('explodecar', function()
--     local ped = PlayerPedId()
--     local vehicle = GetVehiclePedIsIn(ped, true)
    
--     if vehicle ~= 0 then
--         local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
--         print('Exploding vehicle: ' .. plate)
        
--         -- Đẩy player ra khỏi xe trước
--         TaskLeaveVehicle(ped, vehicle, 0)
--         Wait(1000)
        
--         -- Nổ xe
--         local coords = GetEntityCoords(vehicle)
--         AddExplosion(coords.x, coords.y, coords.z, 0, 10.0, true, false, 1.0)
--     else
--         print('No vehicle found')
--     end
-- end, false)

-- print('[xn_pdtools] Test commands loaded:')
-- print('  /spawncar [model] [plate] - Spawn a test vehicle')
-- print('  /lockcar - Lock the vehicle you are in')
-- print('  /checklock - Check lock status of vehicle you are in')
-- print('  /explodecar - Explode the vehicle you are in')

-- -- Command để test toggle duty (chỉ hoạt động với QBCore)
-- RegisterCommand('toggleduty', function()
--     TriggerServerEvent('QBCore:ToggleDuty')
--     print('Toggled duty status')
-- end, false)

-- -- Command để manual đăng ký xe hiện tại
-- RegisterCommand('registercar', function()
--     local ped = PlayerPedId()
--     local vehicle = GetVehiclePedIsIn(ped, false)
    
--     if vehicle ~= 0 then
--         local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
--         local model = GetEntityModel(vehicle)
--         local modelName = GetDisplayNameFromVehicleModel(model)
        
--         local vehicleData = {
--             model = modelName,
--             hash = model
--         }
        
--         TriggerServerEvent('xn_pdtools:registerVehicle', plate, vehicleData)
--         print('Registered vehicle: ' .. plate .. ' (Model: ' .. modelName .. ')')
--     else
--         print('You must be in a vehicle to register it')
--     end
-- end, false)

-- -- Command để kiểm tra xe có phải NPC không (Improved)
-- RegisterCommand('checknpc', function()
--     local ped = PlayerPedId()
--     local vehicle = GetVehiclePedIsIn(ped, true) -- true để lấy xe gần đây nhất
    
--     if vehicle == 0 then
--         -- Nếu không trong xe, tìm xe gần nhất
--         local coords = GetEntityCoords(ped)
--         vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
--     end
    
--     if vehicle ~= 0 then
--         local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", ""):upper()
--         local driver = GetPedInVehicleSeat(vehicle, -1)
--         local entityOwner = NetworkGetEntityOwner(vehicle)
--         local isNetworked = NetworkGetEntityIsNetworked(vehicle)
        
--         print('=== VEHICLE DEBUG INFO ===')
--         print('Plate: ' .. plate)
--         print('Entity ID: ' .. vehicle)
--         print('Is Networked: ' .. tostring(isNetworked))
--         print('Entity Owner: ' .. tostring(entityOwner))
        
--         if entityOwner > 0 then
--             print('Owner Server ID: ' .. tostring(GetPlayerServerId(entityOwner)))
--             print('Owner Name: ' .. tostring(GetPlayerName(entityOwner)))
--         end
        
--         if driver ~= 0 then
--             print('Has Driver: true')
--             print('Driver ID: ' .. driver)
--             print('Driver is Player: ' .. tostring(IsPedAPlayer(driver)))
--             if not IsPedAPlayer(driver) then
--                 print('Driver Ped Type: ' .. GetPedType(driver))
--             end
--         else
--             print('Has Driver: false')
--         end
        
--         -- Kiểm tra xe có trong config không
--         if Config.VehicleInfo[plate] then
--             print('Found in Config: true - ' .. Config.VehicleInfo[plate].owner)
--         else
--             print('Found in Config: false')
--         end
        
--         print('Vehicle Health: ' .. GetVehicleEngineHealth(vehicle))
--         print('Is Damaged: ' .. tostring(IsVehicleDamaged(vehicle)))
--         print('========================')
        
--     else
--         print('No vehicle found nearby')
--     end
-- end, false)

-- print('  /registercar - Register current vehicle to yourself')
-- print('  /checknpc - Check if nearby vehicle is NPC')
