local rentedCar = nil

local function spawnRentalCar(vehicle, spawnPos, time)
    local playerPed = cache.ped

    DoScreenFadeOut(500)
    Wait(500)

    local rentalCar = utils.createVehicle(vehicle, spawnPos, true, false)
    local Plate = GetVehicleNumberPlateText(rentalCar)
    lib.setVehicleProperties(rentalCar, { plate = Plate })

    Wait(500)
    DoScreenFadeIn(600)

    rentedCar = rentalCar
   
    utils.showNotification("Bạn đã thuê một chiếc xe", "success")
    TaskEnterVehicle(playerPed, rentalCar, -1, -1, 1.0, 1, 0)

    SetTimeout(time, function()
        if DoesEntityExist(rentalCar) then
            if cache.vehicle == rentalCar then
                local Plate = GetVehicleNumberPlateText(rentalCar)
                exports['Renewed-Vehiclekeys']:removeKey(Plate)
                TaskLeaveVehicle(playerPed, rentalCar, 0)

                while cache.vehicle == rentalCar do
                    Wait(10)
                end

                Wait(500)
                NetworkFadeOutEntity(rentalCar, true, true)
                Wait(100)
                if DoesEntityExist(rentalCar) then
                    DeleteVehicle(rentalCar)
                end
                utils.showNotification("Xe trở về ông chủ trung tâm thuê xe", "success")
            else
                DeleteVehicle(rentalCar)
                utils.showNotification("Xe trở về ông chủ trung tâm thuê xe", "success")
            end
        end
        if rentedCar == rentalCar then
            rentedCar = nil
        end
    end)
end

local function calculateRentalCost(price, time, method)
    local cost = 0

    if method == "minutes" then
        cost = math.ceil(price * Config.mpMinutes * time / 200)
        time = time * 60000
    elseif method == "hours" then
        cost = math.ceil(price * Config.mpHours * time / 100)
        time = time * 3600000
    end

    return cost, time
end

local function rentCar(vehicle)
    if rentedCar and DoesEntityExist(rentedCar) then
        if IsEntityDead(rentedCar) then
            rentedCar = nil
        else
            local alert = lib.alertDialog({
                header = 'Hủy thuê xe cũ',
                content = 'Bạn đang có một chiếc xe đang thuê. Bạn có muốn hủy xe cũ để thuê xe mới không? (Xe cũ sẽ bị xóa)',
                centered = true,
                cancel = true
            })
            if alert == "confirm" then
                local plate = GetVehicleNumberPlateText(rentedCar)
                if plate then
                    exports['Renewed-Vehiclekeys']:removeKey(plate)
                end
                if cache.vehicle == rentedCar then
                    TaskLeaveVehicle(cache.ped, rentedCar, 0)
                    Wait(500)
                end
                DeleteVehicle(rentedCar)
                rentedCar = nil
                utils.showNotification("Đã hủy xe thuê cũ.", "success")
            else
                return
            end
        end
    elseif rentedCar then
        rentedCar = nil
    end

    local input = lib.inputDialog('Ars Rental', {
        { type = "number", label = "Thời gian", default = 1 },
        {
            type = "select",
            label = "Thời gian",
            default = "minutes",
            options = {
                { value = "minutes", "Phút" },
            }
        },
    })

    if not input then return end

    local time = input[1]
    local method = input[2]

    -- Kiểm tra thêm để đảm bảo giá trị nằm trong khoảng 1-360
    if time < 1 or time > 360 then
        utils.showNotification("Vui lòng nhập giá trị trong khoảng từ 1 đến 360.", "error")
        return
    end

    local rentalCost, rentalTime = calculateRentalCost(vehicle.price, time, method)
    local money = exports.ox_inventory:Search("count", "money", nil)

    if money >= rentalCost then
        -- Kiểm tra túi đồ có trống để nhận chìa khóa không
        local canCarry = lib.callback.await('ars-rental:canCarryKey', false)
        if not canCarry then
            utils.showNotification("Túi đồ của bạn đã đầy, không thể nhận chìa khóa xe.", "error")
            return
        end

        local alert = lib.alertDialog({
            header = 'Dịch vụ Cho thuê xe',
            content = 'Bạn có chắc chắn muốn tiếp tục không? \n Tổng chi phí sẽ là ' .. rentalCost .. "$",
            centered = true,
            cancel = true
        })
        if alert == "confirm" then
            TriggerServerEvent("ars-rental:removeMoney", { price = rentalCost, coords = vehicle.spawnPosition })
            spawnRentalCar(vehicle.car, vehicle.spawnPosition, rentalTime)
        end
    else
        utils.showNotification("Bạn không có đủ tiền.", "error")
    end
end

function openRentalMenu(data)
    -- print("^3[CLIENT] Opening rental menu, taxi system enabled: " .. tostring(Config.TaxiSystem.enable) .. "^7")
    
    -- Kiểm tra có taxi driver nào đang on duty không

    print("^1[CLIENT] No taxi drivers, showing rental menu^7")
    -- Không có taxi driver, hiển thị menu thuê xe bình thường
    showRentalMenu(data)
    
    if Config.TaxiSystem.enable then
        print("^3[CLIENT] Checking for taxi drivers...^7")
        
        
        -- lib.callback('ars-rental:checkTaxiDrivers', false, function(hasTaxiDrivers)
        --     print("^3[CLIENT] Callback received, has taxi drivers: " .. tostring(hasTaxiDrivers) .. "^7")
            
        --     if hasTaxiDrivers then
        --         print("^2[CLIENT] Showing taxi menu^7")
        --         -- Hiển thị menu gọi taxi thay vì thuê xe
        --         lib.registerContext({
        --             id = 'taxi_call_menu',
        --             title = 'Gọi Taxi',
        --             options = {
        --                 {
        --                     title = '📞 Gọi Taxi',
        --                     description = 'Có tài xế taxi đang trực, bấm để gọi taxi đến đón bạn',
        --                     icon = 'fa-solid fa-taxi',
        --                     onSelect = function()
        --                         TriggerEvent(Config.TaxiSystem.pingEvent)
        --                         utils.showNotification("Đã gọi taxi, vui lòng chờ tài xế liên lạc!", "success")
        --                     end,
        --                 }
        --             }
        --         })
        --         lib.showContext('taxi_call_menu')
        --     else
        --         print("^1[CLIENT] No taxi drivers, showing rental menu^7")
        --         -- Không có taxi driver, hiển thị menu thuê xe bình thường
        --         showRentalMenu(data)
        --     end
        -- end)
    else
        print("^1[CLIENT] Taxi system disabled, showing rental menu^7")
        -- Tính năng taxi bị tắt, hiển thị menu thuê xe bình thường
        showRentalMenu(data)
    end
end

function showRentalMenu(data)
    local vehicles = {}

    for i = 1, #data.vehicles, 1 do
        local vehicle = data.vehicles[i]
        table.insert(vehicles, {
            title = vehicle.label,
            description = "Giá thuê xe:" ..math.ceil(vehicle.price * Config.mpMinutes * 1 / 200).."$/phút",
            onSelect = function()
                rentCar(vehicle)
            end,
        })
    end

    lib.registerContext({
        id = 'ars_rental_menu',
        title = 'Rent vehicle',
        options = vehicles
    })

    lib.showContext('ars_rental_menu')
end

-- TEST COMMAND - Xóa khi không cần
RegisterCommand('checktaxi', function()
    print("^3[TEST] Checking taxi system...^7")
    
    if Config.TaxiSystem.enable then
        lib.callback('ars-rental:checkTaxiDrivers', false, function(hasTaxiDrivers)
            TriggerEvent('chat:addMessage', {
                color = {255, 255, 0},
                multiline = true,
                args = {"[TEST]", "Taxi drivers online: " .. tostring(hasTaxiDrivers)}
            })
        end)
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"[TEST]", "Taxi system is DISABLED"}
        })
    end
end, false)
