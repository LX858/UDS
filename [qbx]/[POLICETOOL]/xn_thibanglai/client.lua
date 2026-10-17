-- DMV School 
-- Tech Development - https://discord.gg/tHAbhd94vS
local QBCore = exports['qb-core']:GetCoreObject()

local cachedLicenses = nil
local cachedMoney = nil
local cachedBank = nil

postNUI = function(data)
    SendNUIMessage(data)
end

-- Thread đếm ngược thời gian thi thực hành
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if practiceActive and practiceTimer > 0 then
            practiceTimer = practiceTimer - 1
            
            -- Khi hết thời gian
            if practiceTimer <= 0 then
                practiceActive = false
                -- local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                
                -- if veh ~= 0 then
                --     local plate = GetVehicleNumberPlateText(veh)
                --     -- Xóa chìa khóa
                --     exports['Renewed-Vehiclekeys']:removeKey(plate)
                --     -- Xóa xe
                --     QBCore.Functions.DeleteVehicle(veh)
                -- end
                
                -- Teleport về NPC
                for k,v in pairs(Config.DMVSchool) do
                    SetEntityCoords(PlayerPedId(), v.x, v.y, v.z)
                    SetEntityHeading(PlayerPedId(), v.w or 0.0)
                    break
                end
                
                -- Ẩn UI
                postNUI({
                    type = "HIDE_PRACTICE_ERROR"
                })
                
                -- Hiển thị kết quả fail
                error = currentMaxErrors + 1 -- Set lỗi = max + 1 để fail
                postNUI({
                    type = "DISPLAY_RISULTATO",
                    errori = error,
                    maxErrors = currentMaxErrors
                })
                SetNuiFocus(true, true)
                step = 0
                sleep = 1000
                
                QBCore.Functions.Notify("Hết thời gian thi! Bạn đã thất bại.", "error")
            end
        end
    end
end)

DrawText3D = function(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

OpenDMV = function()
    local Player = QBCore.Functions.GetPlayerData()
    postNUI({
        type = "SET_CONFIG",
        config = Config
    })
    postNUI({
        type = "SET_MONEY",
        contanti = Player.money['cash'],
        banca = Player.money['bank']
    })
    postNUI({
        type = "OPEN",
        licenses = {}, -- Không load license lúc mở UI
        license = Config.License
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback('close', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('removeMoney', function(data)
    local account = data.account
    local amount = tonumber(data.amount)
    TriggerServerEvent('ricky-dmv:removeMoney', account, amount)
end)

RegisterNetEvent('ricky-dmv:updateLicense', function()
    QBCore.Functions.TriggerCallback('ricky-dmv:getData', function(licenses) 
        postNUI({
            type = "UPDATE_LICENSE",
            licenses = licenses,
        })
    end)
end)

RegisterNUICallback('theoryOk', function(data)
    local license = data.license
    onCompleteTheory(license)
end)

RegisterNUICallback('practiceOk', function(data)
    local license = data.license
    onCompletePractice(license)
end)

RegisterNUICallback('checkLicenseBeforeStart', function(data)
    local license = data.license
    local examType = data.examType
    
    QBCore.Functions.TriggerCallback('ricky-dmv:checkLicense', function(hasTheory, hasPractice)
        if examType == 'theory' then
            if hasTheory then
                -- Đã thi lý thuyết rồi (dù đậu hay chưa thi thực hành)
                QBCore.Functions.Notify("Bạn đã thi lý thuyết bằng này rồi!", "error", 3000)
            else
                postNUI({
                    type = "START_THEORY_CONFIRMED",
                    license = license
                })
            end
        elseif examType == 'practice' then
            if hasPractice then
                -- Đã có bằng đầy đủ
                QBCore.Functions.Notify("Bạn đã có bằng này rồi!", "error", 3000)
            elseif not hasTheory then
                QBCore.Functions.Notify("Bạn phải thi đậu lý thuyết trước!", "error", 3000)
            else
                postNUI({
                    type = "START_PRACTICE_CONFIRMED",
                    license = license
                })
            end
        end
    end, license)
end)

RegisterNUICallback('checkLicenseBeforeReissue', function(data)
    local license = data.license
    local reissuePrice = data.pricing
    
    QBCore.Functions.TriggerCallback('ricky-dmv:checkLicense', function(hasTheory, hasPractice)
        if hasTheory and hasPractice then
            -- Đã thi đậu cả 2, cho phép cấp lại
            postNUI({
                type = "REISSUE_LICENSE_CONFIRMED",
                license = license,
                reissuePrice = reissuePrice
            })
        else
            -- Chưa thi đậu
            QBCore.Functions.Notify("Bạn phải thi đậu cả lý thuyết và thực hành mới được cấp lại bằng!", "error", 3000)
        end
    end, license)
end)


local step = 0
local maxSpeed = nil
local sleep = 1000
local error = 0
local practiceTimer = 0
local practiceActive = false
local currentMaxErrors = 3
local currentLicenseConfig = nil
local lastCollisionTime = 0
local lastSpeedErrorTime = 0
local maxErrorNotified = false

SetUpMarker = function()
    step = step + 1
    local randomNumber = math.random(1, #Config.PracticeCoords)
    local coords = Config.PracticeCoords[randomNumber]
    coords = coords[step]
    if coords == nil then
        practiceActive = false
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        local plate = GetVehicleNumberPlateText(veh)
        
        -- Xóa chìa khóa trước khi xóa xe
        exports['Renewed-Vehiclekeys']:removeKey(plate)
        
        QBCore.Functions.DeleteVehicle(veh)
        postNUI({
            type = "HIDE_PRACTICE_ERROR"
        })
        postNUI({
            type = "DISPLAY_RISULTATO",
            errori = error,
            maxErrors = currentMaxErrors
        })
        SetNuiFocus(true, true)
        step = 0
        sleep = 1000
        return
    end
    -- Lấy tốc độ tối đa từ config bằng lái
    maxSpeed = currentLicenseConfig and currentLicenseConfig.maxSpeed or 100
    
    coords = coords.coordinate
    SetNewWaypoint(coords.x, coords.y)
    sleep = 5
    
    Citizen.CreateThread(function()
        while true do
          Citizen.Wait(sleep)
          DrawMarker(Config.MarkerSettings.type, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0, Config.MarkerSettings.size, Config.MarkerSettings.color, 100, Config.MarkerSettings.bump, true, 2, Config.MarkerSettings.rotate, false, false, false)
          local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
          if not DoesEntityExist(vehicle) or vehicle == 0 then
            sleep = 1000
            goto continue
          end
            if vehicle ~= nil then
                local currentTime = GetGameTimer()
                
                -- Kiểm tra tốc độ
                local speed = GetEntitySpeed(vehicle) * Config.SpeedMultiplier
                if maxSpeed ~= nil and speed > maxSpeed and (currentTime - lastSpeedErrorTime) > 5000 then
                    lastSpeedErrorTime = currentTime
                    error = error + 1
                    postNUI({
                        type = "UPDATE_PRACTICE_ERROR",
                        error = error,
                        maxError = currentMaxErrors
                    })
                    QBCore.Functions.Notify("Bạn đang chạy quá tốc độ cho phép ("..math.floor(maxSpeed).." km/h)!", "error")
                    
                    -- Kiểm tra nếu vượt quá max lỗi
                    if error > currentMaxErrors and not maxErrorNotified then
                        maxErrorNotified = true
                        QBCore.Functions.Notify("Bạn đã phạm lỗi quá nhiều! Tiếp tục hoàn thành lộ trình.", "error", 5000)
                    end
                end
                
                -- Kiểm tra va chạm
                -- Kiểm tra nếu xe va chạm với bất kỳ thứ gì và đã qua 5 giây từ lần va chạm trước
                if HasEntityCollidedWithAnything(vehicle) and (currentTime - lastCollisionTime) > 5000 then
                    lastCollisionTime = currentTime
                    error = error + 1
                    
                    postNUI({
                        type = "UPDATE_PRACTICE_ERROR",
                        error = error,
                        maxError = currentMaxErrors
                    })
                    QBCore.Functions.Notify("Bạn đã va chạm! Lỗi: "..error.."/"..currentMaxErrors, "error")
                    
                    -- Kiểm tra nếu vượt quá max lỗi sau va chạm
                    if error > currentMaxErrors and not maxErrorNotified then
                        maxErrorNotified = true
                        QBCore.Functions.Notify("Bạn đã phạm lỗi quá nhiều! Tiếp tục hoàn thành lộ trình.", "error", 5000)
                    end
                end
            end
          local distance = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, GetEntityCoords(PlayerPedId()), true)
          if distance < 1.5 then
            SetUpMarker()
            break 
          end
          ::continue::
         end
      end)
end


RegisterNUICallback('startPractice', function(data)
    local license = data.license 
    error = 0 -- Reset lỗi về 0
    practiceActive = true
    lastCollisionTime = 0
    lastSpeedErrorTime = 0
    maxErrorNotified = false
    
    for k,v in pairs(Config.License) do 
        if v.id == license then
            currentLicenseConfig = v
            currentMaxErrors = v.maxErrors or 3
            practiceTimer = v.practiceTimeLimit or 600 -- Lấy thời gian từ config bằng, mặc định 10 phút
            print("Bắt đầu thi thực hành với thời gian:", practiceTimer)
            print("Số lỗi tối đa:", currentMaxErrors)
            print("Tốc độ tối đa xe:", v.maxSpeed, "km/h")
            local vehicle = v.vehicle
            QBCore.Functions.SpawnVehicle(vehicle.model, function(veh) 
                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetEntityHeading(veh, vehicle.heading)
                SetEntityCoords(veh, vehicle.coords.x, vehicle.coords.y, vehicle.coords.z)
                SetPedIntoVehicle(PlayerPedId(), veh, -1)
                SetVehicleEngineOn(veh, true, true)
                
                -- Cấp chìa khóa xe
                local plate = GetVehicleNumberPlateText(veh)
                exports['Renewed-Vehiclekeys']:addKey(plate)
                
                -- Hiển thị UI số lỗi và thời gian sau khi vào xe
                Citizen.Wait(1000)
                print("Gửi SHOW_PRACTICE_ERROR với timeLimit:", practiceTimer)
                postNUI({
                    type = "SHOW_PRACTICE_ERROR",
                    error = 0,
                    maxError = currentMaxErrors,
                    timeLimit = practiceTimer
                })
            end, vehicle.coords, true)
        end
    end
    SetUpMarker()
end)

RegisterNUICallback('practiceOk', function(data)
    local license = data.license
    onCompletePractice(license)
    
    -- Thêm item bằng lái vào inventory
    TriggerServerEvent('ricky-dmv:giveItemLicense', license)
end)

RegisterNUICallback('reissueLicense', function(data)
    local license = data.license
    TriggerServerEvent('ricky-dmv:reissueLicense', license)
end)


-- Spawn NPC at DMV with ox_target
local dmvPed = nil
Citizen.CreateThread(function()
    RequestModel(GetHashKey("s_f_y_airhostess_01"))
    while not HasModelLoaded(GetHashKey("s_f_y_airhostess_01")) do
        Wait(1)
    end
    
    for k,v in pairs(Config.DMVSchool) do
        local heading = v.w or 180.0
        dmvPed = CreatePed(4, GetHashKey("s_f_y_airhostess_01"), v.x, v.y, v.z - 1.0, heading, false, true)
        SetEntityHeading(dmvPed, heading)
        FreezeEntityPosition(dmvPed, true)
        SetEntityInvincible(dmvPed, true)
        SetBlockingOfNonTemporaryEvents(dmvPed, true)
        
        -- Add ox_target to NPC
        exports.ox_target:addLocalEntity(dmvPed, {
            {
                name = 'dmv_school',
                icon = 'fas fa-car',
                label = 'Mở trường lái xe',
                onSelect = function()
                    OpenDMV()
                end
            }
        })
        
        -- Create blip on map
        local blip = AddBlipForCoord(v.x, v.y, v.z)
        SetBlipSprite(blip, 225)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Trường Lái Xe")
        EndTextCommandSetBlipName(blip)
    end
end)
