local QBCore = exports['qb-core']:GetCoreObject()

-- Biến kiểm soát
local isGettingWater = false

-- Khởi tạo hệ thống lấy nước
Citizen.CreateThread(function()
    -- Tạo blip cho các điểm lấy nước
    local locations = WaterSystem.Locations or { WaterSystem.Location }
    for _, loc in ipairs(locations) do
        local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(blip, 464) -- Icon nước
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 26) -- Màu xanh dương
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Điểm Lấy Nước")
        EndTextCommandSetBlipName(blip)
    end
end)

-- Event handler khi sử dụng xô rỗng
RegisterNetEvent('xn_farming:useEmptyBucket', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify('Không thể lấy nước khi đang ngồi trên xe!', 'error')
        return
    end

    local playerCoords = GetEntityCoords(playerPed)
    local nearWater = false
    local locations = WaterSystem.Locations or { WaterSystem.Location }
    
    for _, loc in ipairs(locations) do
        local distance = #(playerCoords - loc)
        if distance <= WaterSystem.InteractionDistance then
            nearWater = true
            break
        end
    end
    
    if nearWater then
        GetWater()
    else
        QBCore.Functions.Notify('Bạn cần đến gần điểm lấy nước để sử dụng xô rỗng!', 'error')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Không cần tạo useable item ở client nữa vì đã làm ở server
end)

-- Đảm bảo event được đăng ký ngay khi script load
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Chờ QBCore load xong
    -- Không cần trigger event nữa
end)

-- Hàm lấy nước
function GetWater()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify('Không thể lấy nước khi đang ngồi trên xe!', 'error')
        return
    end

    if isGettingWater then
        if Config.Debug then
            print("Đang trong quá trình lấy nước...")
        end
        return
    end

    -- Kiểm tra có xô rỗng không
    QBCore.Functions.TriggerCallback('xn_farming:checkEmptyBucket', function(hasEmptyBucket)
        if not hasEmptyBucket then
            QBCore.Functions.Notify('Bạn cần có xô rỗng để lấy nước!', 'error')
            return
        end

        isGettingWater = true
        
        -- Animation lấy nước - sử dụng animation phù hợp hơn
        local playerPed = PlayerPedId()
        local animDict = "amb@world_human_bum_wash@male@low@base"
        local animName = "base"
        
        -- Kiểm tra nếu player đang dưới nước
        local playerCoords = GetEntityCoords(playerPed)
        local isInWater = IsEntityInWater(playerPed)
        local isSwimming = IsPedSwimming(playerPed)
        
        if Config.Debug then
            print("Player coordinates:", playerCoords)
            print("Is in water:", isInWater)
            print("Is swimming:", isSwimming)
        end
        
        -- Chỉ load animation nếu không đang bơi
        if not isSwimming then
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do
                Citizen.Wait(100)
            end
            
            -- Chỉ chạy animation nếu không dưới nước quá sâu
            TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        else
            if Config.Debug then
                print("Player is swimming - skipping animation")
            end
        end
        
        -- Progress bar
        local waterTime = math.random(WaterSystem.WaterTime.min, WaterSystem.WaterTime.max)
        
        if Config.Debug then
            print("Starting progress bar with time:", waterTime)
            print("Player can move:", isSwimming)
            print("Will use animation:", not isSwimming)
        end
        
        local success = lib.progressBar({
            duration = waterTime,
            label = 'Đang lấy nước...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = not isSwimming, -- Cho phép di chuyển nếu đang bơi
                combat = true,
                mouse = false,
            },
            anim = not isSwimming and {
                dict = animDict,
                clip = animName,
                flag = 1,
            } or nil,
        })
        
        -- Dừng animation
        ClearPedTasks(playerPed)
        
        if success then
            -- Thành công - gọi server để đổi vật phẩm
            QBCore.Functions.TriggerCallback('xn_farming:getWater', function(result)
                if result then
                    QBCore.Functions.Notify('Lấy nước thành công! Nhận được xô có nước', 'success')
                    if Config.Debug then
                        print("Lấy nước thành công - nhận được xô có nước")
                    end
                else
                    QBCore.Functions.Notify('Không thể lấy nước! Kiểm tra lại xô rỗng', 'error')
                end
            end)
        else
            if Config.Debug then
                print("Progress bar was cancelled - checking reason...")
                print("Player ped:", playerPed)
                print("Is player still alive:", not IsEntityDead(playerPed))
                print("Player health:", GetEntityHealth(playerPed))
                print("Is player swimming:", IsPedSwimming(playerPed))
                print("Is in water:", IsEntityInWater(playerPed))
            end
            
            QBCore.Functions.Notify('Đã hủy lấy nước (có thể do di chuyển hoặc thay đổi trạng thái)', 'error')
            if Config.Debug then
                print("Hủy lấy nước - progress bar cancelled")
            end
        end
        
        isGettingWater = false
    end)
end

-- Cleanup khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    -- Resource cleanup - không cần hide text vì không có text liên tục
end)
