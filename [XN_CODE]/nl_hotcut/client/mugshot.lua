-- ============= MUGSHOT SYSTEM FOR PRISON =============
-- SỬ DỤNG KAEL-MUGSHOT-MAIN SYSTEM

-- Event chụp mugshot khi đưa vào tù - GỌI KAEL MUGSHOT SYSTEM
RegisterNetEvent("nl_hotcut:client:takeMugshot", function(actionsCount)
    if not Config.EnableMugshot then
        TriggerServerEvent('nl_hotcut:server:startPrisonTransport', actionsCount)
        return
    end

    if not actionsCount or actionsCount < 1 then
        return
    end
    
    -- GỌI KAEL để chụp hình, sau khi xong sẽ callback về
    TriggerEvent("kael-mugshot:client:takemugshot", GetPlayerServerId(PlayerId()), "nl_hotcut:client:mugshotCompleted")
    
    -- Lưu actionsCount để dùng sau khi kael chụp xong
    SetResourceKvpInt("nl_hotcut_pending_actions", actionsCount)

    CreateThread(function()
        Wait(8000)

        local pendingActions = GetResourceKvpInt("nl_hotcut_pending_actions")
        if pendingActions and pendingActions > 0 then
            print("[NL_HOTCUT] Mugshot callback timeout, starting prison transport fallback")
            DeleteResourceKvp("nl_hotcut_pending_actions")
            TriggerServerEvent('nl_hotcut:server:startPrisonTransport', pendingActions)
        end
    end)
end)

-- Callback khi KAEL chụp xong
RegisterNetEvent("nl_hotcut:client:mugshotCompleted", function()
    local actionsCount = GetResourceKvpInt("nl_hotcut_pending_actions")
    DeleteResourceKvp("nl_hotcut_pending_actions")
    
    if actionsCount and actionsCount > 0 then
        TriggerServerEvent('nl_hotcut:server:startPrisonTransport', actionsCount)
    end
end)

-- Event xe tù chở về
RegisterNetEvent('nl_hotcut:client:prisonTransport', function(actionsCount)
    local PlayerPed = PlayerPedId()
    
    -- Tọa độ bắt đầu và kết thúc
    local startPos = vector4(1841.69, 3654.91, 34.28, 115.91)
    local endPos = vector4(1861.64, 2609.29, 45.67, 260.6)
    
    -- Khai báo biến xe escort ở ngoài để có thể truy cập từ thread
    local escortFront, driverFront
    
    -- Spawn xe tù (policet - Police Transport Van)
    LoadModel("policet")
    local vehicle = CreateVehicle(GetHashKey("policet"), startPos.x, startPos.y, startPos.z, startPos.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleDoorsLocked(vehicle, 4) -- Lock doors
    
    -- Set full xăng
    SetVehicleFuelLevel(vehicle, 100.0)
    DecorSetFloat(vehicle, "_FUEL_LEVEL", 100.0)
    
    -- Bật còi cảnh sát cho hay
    SetVehicleHasMutedSirens(vehicle, false)
    SetVehicleSiren(vehicle, true)
    SetHornEnabled(vehicle, true)
    
    -- Spawn NPC lái xe tù
    LoadModel("s_m_m_security_01")
    local driver = CreatePed(4, GetHashKey("s_m_m_security_01"), startPos.x, startPos.y, startPos.z, startPos.w, true, false)
    SetPedIntoVehicle(driver, vehicle, -1)
    SetEntityAsMissionEntity(driver, true, true)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedFleeAttributes(driver, 0, false)
    SetPedCombatAttributes(driver, 17, true)
    
    -- Spawn xe cảnh sát hộ tống phía TRƯỚC (cách 10m)
    LoadModel("police")
    local frontOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 10.0, 0.0)
    escortFront = CreateVehicle(GetHashKey("police"), frontOffset.x, frontOffset.y, frontOffset.z, startPos.w, true, false)
    SetEntityAsMissionEntity(escortFront, true, true)
    SetVehicleOnGroundProperly(escortFront)
    SetVehicleEngineOn(escortFront, true, true, false)
    SetVehicleDirtLevel(escortFront, 0.0)
    SetVehicleFuelLevel(escortFront, 100.0)
    DecorSetFloat(escortFront, "_FUEL_LEVEL", 100.0)
    SetVehicleHasMutedSirens(escortFront, false)
    SetVehicleSiren(escortFront, true)
    
    -- Driver cho xe phía trước
    driverFront = CreatePed(4, GetHashKey("s_m_y_cop_01"), frontOffset.x, frontOffset.y, frontOffset.z, startPos.w, true, false)
    SetPedIntoVehicle(driverFront, escortFront, -1)
    SetEntityAsMissionEntity(driverFront, true, true)
    SetBlockingOfNonTemporaryEvents(driverFront, true)
    SetPedFleeAttributes(driverFront, 0, false)
    SetPedCombatAttributes(driverFront, 17, true)
    
    -- Set driving style để biết vượt qua xe khác
    -- 786603 = AvoidTrafficExtremely + IgnoreLights + AllowGoingWrongWay + AvoidHighways
    SetDriveTaskDrivingStyle(driver, 786603)
    SetDriveTaskDrivingStyle(driverFront, 786603)
    
    -- Cho phép lái xe NPC overtake (vượt qua xe khác)
    SetDriverAbility(driver, 100.0) -- Max driving skill
    SetDriverAggressiveness(driver, 100.0) -- Max aggression để dám vượt
    SetDriverAbility(driverFront, 100.0)
    SetDriverAggressiveness(driverFront, 100.0)
    
    -- Force xe không bị chặn bởi traffic
    SetVehicleForwardSpeed(vehicle, 30.0) -- Tốc độ ban đầu để dễ vượt
    SetVehicleForwardSpeed(escortFront, 30.0)
    
    -- Thread xóa HẾT xe NPC cản đường (xóa theo cả xe tù VÀ xe phía trước)
    CreateThread(function()
        while DoesEntityExist(vehicle) do
            local vehCoords = GetEntityCoords(vehicle)
            local frontCoords = DoesEntityExist(escortFront) and GetEntityCoords(escortFront) or vehCoords
            local nearbyVehicles = GetGamePool('CVehicle')
            
            for _, veh in pairs(nearbyVehicles) do
                -- Không xóa xe tù và xe hộ tống phía trước
                if veh ~= vehicle and veh ~= escortFront and DoesEntityExist(veh) then
                    local vehPos = GetEntityCoords(veh)
                    local distanceFromPrison = #(vehCoords - vehPos)
                    local distanceFromFront = #(frontCoords - vehPos)
                    
                    -- Xóa xe nếu gần xe tù (50m) HOẶC gần xe phía trước (60m)
                    if distanceFromPrison < 50.0 or distanceFromFront < 60.0 then
                        local pedDriver = GetPedInVehicleSeat(veh, -1)
                        if pedDriver and not IsPedAPlayer(pedDriver) then
                            DeleteEntity(pedDriver)
                            DeleteEntity(veh)
                        end
                    end
                end
            end
            
            Wait(200) -- Kiểm tra mỗi 0.2 giây (nhanh hơn để xóa kịp)
        end
    end)
    
    -- Fade out màn hình nhanh
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    
    Wait(100)
    
    -- Teleport player vào xe
    SetPedIntoVehicle(PlayerPed, vehicle, 1)
    
    -- Fade in màn hình và xe chạy luôn
    Wait(100)
    DoScreenFadeIn(800)
    while not IsScreenFadedIn() do
        Wait(0)
    end
    
    -- Lái xe đến tù với tốc độ rất cao
    TaskVehicleDriveToCoord(driver, vehicle, endPos.x, endPos.y, endPos.z, 120.0, 1, GetHashKey("policet"), 786603, 5.0, true)
    
    -- Xe hộ tống phía trước - đi trước 10m
    TaskVehicleDriveToCoord(driverFront, escortFront, endPos.x, endPos.y, endPos.z, 120.0, 1, GetHashKey("police"), 786603, 5.0, true)
    
    -- Thread điều khiển xe phía trước luôn ở phía trước 10m
    CreateThread(function()
        while DoesEntityExist(vehicle) and DoesEntityExist(escortFront) do
            local targetCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 10.0, 0.0)
            local frontCoords = GetEntityCoords(escortFront)
            local distance = #(frontCoords - targetCoords)
            
            -- Nếu xe phía trước bị tụt lại quá xa, reset lại vị trí
            if distance > 15.0 then
                ClearPedTasks(driverFront)
                TaskVehicleDriveToCoord(driverFront, escortFront, endPos.x, endPos.y, endPos.z, 120.0, 1, GetHashKey("police"), 786603, 5.0, true)
            end
            
            Wait(1000)
        end
    end)
    
    -- Theo dõi khoảng cách và điều chỉnh tốc độ
    CreateThread(function()
        local hasSlowedDown = false
        local hasStopped = false
        local startTime = GetGameTimer()
        local timeout = 120000 -- 2 phút (120 giây)
        
        while true do
            Wait(500)
            
            -- Kiểm tra timeout
            if GetGameTimer() - startTime > timeout then
                -- Timeout - xe không đến sau 2 phút
                DoScreenFadeOut(500)
                while not IsScreenFadedOut() do
                    Wait(0)
                end
                
                -- Xóa xe tù và xe hộ tống
                if DoesEntityExist(driver) then DeleteEntity(driver) end
                if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
                if DoesEntityExist(driverFront) then DeleteEntity(driverFront) end
                if DoesEntityExist(escortFront) then DeleteEntity(escortFront) end
                
                -- Đưa thẳng vào tù
                Wait(500)
                TriggerServerEvent('nl_hotcut:server:arrivedAtPrison', actionsCount)
                
                Wait(1000)
                DoScreenFadeIn(1000)
                while not IsScreenFadedIn() do
                    Wait(0)
                end
                
                break
            end
            
            if not DoesEntityExist(vehicle) then break end
            
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(vehCoords - vector3(endPos.x, endPos.y, endPos.z))
            
            -- Giai đoạn 1: Khi còn xa (>50m) - tốc độ rất cao
            if distance > 50.0 and not hasSlowedDown then
                -- Giữ tốc độ cao 120
                
            -- Giai đoạn 2: Khi gần (30-50m) - giảm tốc xuống 65
            elseif distance > 30.0 and distance <= 50.0 and not hasSlowedDown then
                ClearPedTasks(driver)
                TaskVehicleDriveToCoord(driver, vehicle, endPos.x, endPos.y, endPos.z, 65.0, 1, GetHashKey("policet"), 786603, 3.0, true)
                
            -- Giai đoạn 3: Khi rất gần (15-30m) - giảm tốc xuống 35
            elseif distance > 15.0 and distance <= 30.0 then
                if not hasSlowedDown then
                    ClearPedTasks(driver)
                    TaskVehicleDriveToCoord(driver, vehicle, endPos.x, endPos.y, endPos.z, 35.0, 1, GetHashKey("policet"), 786603, 2.0, true)
                    hasSlowedDown = true
                end
                
            -- Giai đoạn 4: Khi đến nơi (<5m) - xóa xe và teleport vào tù
            elseif distance <= 5.0 and not hasStopped then
                hasStopped = true
                
                -- Fade out màn hình nhanh
                DoScreenFadeOut(500)
                while not IsScreenFadedOut() do
                    Wait(0)
                end
                
                -- Xóa xe tù và xe hộ tống phía trước
                if DoesEntityExist(driver) then DeleteEntity(driver) end
                if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
                if DoesEntityExist(driverFront) then DeleteEntity(driverFront) end
                if DoesEntityExist(escortFront) then DeleteEntity(escortFront) end
                
                -- Đợi 2 giây
                Wait(2000)
                
                -- Teleport vào tù
                TriggerServerEvent('nl_hotcut:server:arrivedAtPrison', actionsCount)
                
                -- Fade in màn hình sau khi vào tù
                Wait(500)
                DoScreenFadeIn(800)
                while not IsScreenFadedIn() do
                    Wait(0)
                end
                
                break
            end
        end
    end)
end)

-- Helper function LoadModel
function LoadModel(model)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        Wait(0)
    end
end
