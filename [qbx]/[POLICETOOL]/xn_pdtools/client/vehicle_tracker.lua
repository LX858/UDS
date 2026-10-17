-- Auto-register vehicles khi spawn để tracking ownership

-- Event listener cho khi xe được spawn
AddEventHandler('entityCreating', function(entity)
    -- Chỉ xử lý vehicle entities
    if GetEntityType(entity) == 2 then -- 2 = vehicle
        -- Đợi một chút để entity được khởi tạo hoàn toàn
        CreateThread(function()
            Wait(1000)
            
            if DoesEntityExist(entity) then
                -- Kiểm tra xem có phải xe NPC không
                local driver = GetPedInVehicleSeat(entity, -1)
                local isNPCVehicle = false
                
                if driver ~= 0 and not IsPedAPlayer(driver) then
                    -- Có driver NPC = xe NPC, không cần đăng ký
                    isNPCVehicle = true
                    print('[xn_pdtools] Skipping NPC vehicle registration')
                    return
                end
                
                local plate = GetVehicleNumberPlateText(entity):gsub("%s+", ""):upper()
                local model = GetEntityModel(entity)
                local modelName = GetDisplayNameFromVehicleModel(model)
                
                -- Tìm player gần nhất (có thể là người spawn xe)
                local players = GetActivePlayers()
                local closestPlayer = nil
                local closestDistance = 50.0 -- Chỉ tìm trong bán kính 50m
                
                local vehCoords = GetEntityCoords(entity)
                
                for _, playerId in ipairs(players) do
                    local playerPed = GetPlayerPed(playerId)
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = #(vehCoords - playerCoords)
                    
                    if distance < closestDistance then
                        closestPlayer = playerId
                        closestDistance = distance
                    end
                end
                
                -- Nếu tìm thấy player gần nhất, đăng ký xe cho họ
                if closestPlayer then
                    local vehicleData = {
                        model = modelName,
                        hash = model
                    }
                    
                    TriggerServerEvent('xn_pdtools:registerVehicle', plate, vehicleData)
                    print('[xn_pdtools] Auto-registered player vehicle: ' .. plate .. ' (Model: ' .. modelName .. ')')
                end
            end
        end)
    end
end)
