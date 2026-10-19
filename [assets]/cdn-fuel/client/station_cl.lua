if Config.PlayerOwnedGasStationsEnabled then -- This is so Player Owned Gas Stations are a Config Option, instead of forced. Set this option in shared/config.lua!
    -- Variables
    local QBCore = exports[Config.Core]:GetCoreObject()
    local PedsSpawned = false

    -- These are for fuel pickup:
    local CreatedEventHandler = false
    local locationSwapHandler
    local spawnedTankerTrailer
    local spawnedDeliveryTruck
    local ReservePickupData = {}
    local IsDeliveryInProgress = false -- FIX: chặn nhiều event pickup chạy đồng thời trên cùng client

    -- Functions
    local function RequestAndLoadModel(model)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(5)
        end
    end

    local function UpdateStationInfo(info)
        if Config.FuelDebug then print("Fetching Information for Location #" ..CurrentLocation) end
        QBCore.Functions.TriggerCallback('cdn-fuel:server:fetchinfo', function(result)
            if result then
                for _, v in pairs(result) do
                    -- Reserves --
                    if info == "all" or info == "reserves" then
                        if Config.FuelDebug then print("Fetched Reserve Levels: "..v.fuel.." Liters!") end
                        Currentreserveamount = v.fuel
                        ReserveLevels = Currentreserveamount
                        if Currentreserveamount < Config.MaxFuelReserves then
                            ReservesNotBuyable = false
                        else
                            ReservesNotBuyable = true
                        end
                        if Config.UnlimitedFuel then ReservesNotBuyable = true if Config.FuelDebug then print("Reserves are not buyable, because Config.UnlimitedFuel is set to true.") end end
                    end
                    -- Fuel Price --
                    if info == "all" or info == "fuelprice" then
                        StationFuelPrice = v.fuelprice
                    end
                    -- Fuel Station's Balance --
                    if info == "all" or info == "balance" then
                        StationBalance = v.balance
                        if Config.FuelDebug then print("Successfully Fetched: Balance") end
                    end
                    -- Electric Reserves --
                    if info == "all" or info == "electric" or info == "reserves" then
                        ElectricReserveLevels = tonumber(v.electric) or 0
                    end
                    ----------------
                end
            end
        end, CurrentLocation)
    end exports(UpdateStationInfo, UpdateStationInfo)

    local function SpawnGasStationPeds()
        if not Config.GasStations or not next(Config.GasStations) or PedsSpawned then return end
        local centralStationId = Config.CentralStation or 5
        local current = Config.GasStations[centralStationId]
        if current then
            current.pedmodel = type(current.pedmodel) == 'string' and joaat(current.pedmodel) or current.pedmodel
            RequestAndLoadModel(current.pedmodel)
            local ped = CreatePed(0, current.pedmodel, current.pedcoords.x, current.pedcoords.y, current.pedcoords.z, current.pedcoords.h, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            exports['qtarget']:AddTargetEntity(ped, {
                options = {
                    {
                        type = "client",
                        label = Lang:t("station_talk_to_ped"),
                        icon = "fas fa-building",
                        action = function()
                            TriggerEvent('cdn-fuel:stations:openmenu', centralStationId)
                        end,
                    },
                },
                distance = 2.0
            })
        end
        PedsSpawned = true
    end

    local function GenerateRandomTruckModel()
        local possibleTrucks = Config.PossibleDeliveryTrucks
        if possibleTrucks and #possibleTrucks > 0 then
            return possibleTrucks[math.random(#possibleTrucks)]
        end
        return "hauler"
    end

    local function GiveVehicleKeys(veh)
        if not veh or not DoesEntityExist(veh) then return end
        local plate = QBCore.Functions.GetPlate(veh) or GetVehicleNumberPlateText(veh)

        SetVehicleDoorsLocked(veh, 1)
        SetVehicleDoorsLockedForAllPlayers(veh, false)
        SetVehicleNeedsToBeHotwired(veh, false)
        SetVehicleEngineOn(veh, true, true, false)

        Entity(veh).state.keys = true

        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        TriggerServerEvent('qb-vehiclekeys:server:AddKeys', plate)

        TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
        TriggerEvent('vehiclekeys:client:SetOwner', plate)

        if GetResourceState('qbx_vehiclekeys') == 'started' then
            pcall(function() exports.qbx_vehiclekeys:GiveKeys(veh) end)
            pcall(function() exports.qbx_vehiclekeys:GiveKeys(plate) end)
        end
        if GetResourceState('qb-vehiclekeys') == 'started' then
            pcall(function() exports['qb-vehiclekeys']:GiveKeys(plate) end)
        end
        if GetResourceState('wasabi_carlock') == 'started' then
            pcall(function() exports.wasabi_carlock:GiveKeys(plate) end)
        end
    end

    local function SpawnInitialTruck()
        local spawnCoords = Config.DeliveryTruckSpawns['initial_truck'] or vector4(279.1309, -1292.4058, 29.6764, 89.5983)
        local truckModel = joaat(GenerateRandomTruckModel())
        RequestAndLoadModel(truckModel)

        -- Dọn dẹp xe cũ nếu có
        if spawnedDeliveryTruck and DoesEntityExist(spawnedDeliveryTruck) then
            DeleteEntity(spawnedDeliveryTruck)
            spawnedDeliveryTruck = nil
        end

        spawnedDeliveryTruck = CreateVehicle(truckModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
        SetModelAsNoLongerNeeded(truckModel)
        if spawnedDeliveryTruck ~= 0 then
            SetEntityAsMissionEntity(spawnedDeliveryTruck, true, true)
            GiveVehicleKeys(spawnedDeliveryTruck)
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            if #(pCoords - vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)) < 50.0 then
                TaskWarpPedIntoVehicle(ped, spawnedDeliveryTruck, -1)
            end
            return true
        end
        return false
    end

    local function SpawnTankerWithTruck()
        local truckSpawn = Config.DeliveryTruckSpawns['truck'] or vector4(1727.08, -1664.01, 112.62, 189.62)
        local trailerSpawn = Config.DeliveryTruckSpawns['trailer'] or vector4(1724.0, -1649.7, 112.57, 194.24)

        -- Xóa xe đầu kéo đơn trước đó
        if spawnedDeliveryTruck and DoesEntityExist(spawnedDeliveryTruck) then
            DeleteEntity(spawnedDeliveryTruck)
            spawnedDeliveryTruck = nil
        end
        if spawnedTankerTrailer and DoesEntityExist(spawnedTankerTrailer) then
            DeleteEntity(spawnedTankerTrailer)
            spawnedTankerTrailer = nil
        end

        local trailerModel = joaat('tanker')
        local truckModel = joaat(GenerateRandomTruckModel())
        RequestAndLoadModel(truckModel)
        RequestAndLoadModel(trailerModel)

        spawnedDeliveryTruck = CreateVehicle(truckModel, truckSpawn.x, truckSpawn.y, truckSpawn.z, truckSpawn.w, true, false)
        spawnedTankerTrailer = CreateVehicle(trailerModel, trailerSpawn.x, trailerSpawn.y, trailerSpawn.z, trailerSpawn.w, true, false)

        SetModelAsNoLongerNeeded(truckModel)
        SetModelAsNoLongerNeeded(trailerModel)

        if spawnedDeliveryTruck ~= 0 and spawnedTankerTrailer ~= 0 then
            SetEntityAsMissionEntity(spawnedDeliveryTruck, true, true)
            SetEntityAsMissionEntity(spawnedTankerTrailer, true, true)
            AttachVehicleToTrailer(spawnedDeliveryTruck, spawnedTankerTrailer, 15.0)
            GiveVehicleKeys(spawnedDeliveryTruck)
            local ped = PlayerPedId()
            TaskWarpPedIntoVehicle(ped, spawnedDeliveryTruck, -1)
            return true
        end
        return false
    end

    -- Events
    RegisterNetEvent('cdn-fuel:stations:updatelocation', function(updatedlocation)
        if Config.FuelDebug then if CurrentLocation == nil then CurrentLocation = 0 end
            if updatedlocation == nil then updatedlocation = 0 end
            print('Location: '..CurrentLocation..' has been replaced with a new location: ' ..updatedlocation)
        end
        CurrentLocation = updatedlocation or 0
    end)

    RegisterNetEvent('cdn-fuel:stations:client:buyreserves', function(data)
        local location = data.location
        local price = data.price
        local amount = data.amount
        TriggerServerEvent('cdn-fuel:stations:server:buyreserves', location, price, amount)
        if Config.FuelDebug then print("^5Attempting Purchase of ^2"..amount.. "^5 Fuel Reserves for location #"..location.."! Purchase Price: ^2"..price) end
    end)

    RegisterNetEvent('cdn-fuel:station:client:initiatefuelpickup', function(amountBought, finalReserveAmountAfterPurchase, location)
        if IsDeliveryInProgress then
            if spawnedDeliveryTruck and DoesEntityExist(spawnedDeliveryTruck) and not IsEntityDead(spawnedDeliveryTruck) then
                QBCore.Functions.Notify("Bạn đang có một chuyến xe vận chuyển xăng chưa hoàn tất!", "error", 7500)
                return
            else
                TriggerEvent('cdn-fuel:station:client:resetDelivery')
            end
        end

        if not amountBought or not location then
            if Config.FuelDebug then
                print("An error has occurred. The amountBought / location is nil: `cdn-fuel:station:client:initiatefuelpickup`")
            end
            return
        end

        local spawned = SpawnInitialTruck()
        if not spawned then
            QBCore.Functions.Notify("Không thể spawn xe đầu kéo! Vui lòng thử lại.", "error", 7500)
            return
        end

        IsDeliveryInProgress = true
        ReservePickupData = {
            finalAmount = finalReserveAmountAfterPurchase,
            amountBought = amountBought,
            location = location,
            stage = "go_to_depot",
        }

        TriggerServerEvent('cdn-fuel:station:server:vehiclePickedUp', location)

        local depotPos = vector3(Config.DeliveryTruckSpawns.truck.x, Config.DeliveryTruckSpawns.truck.y, Config.DeliveryTruckSpawns.truck.z)
        SetNewWaypoint(depotPos.x, depotPos.y)
        SetUseWaypointAsDestination(true)

        ReservePickupData.blip = CreateBlip(depotPos, "Gắn Bồn Chứa Xăng")
        SetBlipColour(ReservePickupData.blip, 5)

        QBCore.Functions.Notify("Đã nhận xe đầu kéo! Hãy lái xe đến Xưởng Dầu (theo định vị GPS) để gắn bồn chứa xăng.", 'success', 7500)

        CreateThread(function()
            local centralCoords = vector3(Config.DeliveryTruckSpawns['initial_truck'].x, Config.DeliveryTruckSpawns['initial_truck'].y, Config.DeliveryTruckSpawns['initial_truck'].z)
            local depotCoords = vector3(Config.DeliveryTruckSpawns.truck.x, Config.DeliveryTruckSpawns.truck.y, Config.DeliveryTruckSpawns.truck.z)

            while IsDeliveryInProgress and ReservePickupData do
                Wait(0)
                local ped = PlayerPedId()

                -- Kiểm tra xe bị phá hủy
                if spawnedDeliveryTruck and DoesEntityExist(spawnedDeliveryTruck) and IsEntityDead(spawnedDeliveryTruck) then
                    QBCore.Functions.Notify("Xe vận chuyển xăng đã bị phá hủy! Nhiệm vụ nhập xăng đã thất bại.", 'error', 7500)
                    local failedLocation = ReservePickupData and ReservePickupData.location
                    if failedLocation then
                        TriggerServerEvent('cdn-fuel:station:server:fuelpickup:failed', failedLocation)
                    end
                    TriggerEvent('cdn-fuel:station:client:resetDelivery')
                    break
                end

                -- GIAI ĐOẠN 1: ĐANG ĐẾN XƯỞNG DẦU ĐỂ GẮN BỒN CHỨA
                if ReservePickupData and ReservePickupData.stage == "go_to_depot" then
                    local pCoords = GetEntityCoords(ped)
                    local distToDepot = #(pCoords - depotCoords)

                    if distToDepot <= 30.0 then
                        if Config.Ox.DrawText then
                            lib.showTextUI('[E] - Gắn bồn chứa xăng', { position = 'left-center' })
                        else
                            exports[Config.Core]:DrawText('[E] - Gắn bồn chứa xăng', 'left')
                        end

                        if IsControlJustReleased(0, 38) then
                            if Config.Ox.DrawText then lib.hideTextUI() else exports[Config.Core]:HideText() end

                            if SpawnTankerWithTruck() then
                                ReservePickupData.stage = "return_to_central"
                                if ReservePickupData.blip then RemoveBlip(ReservePickupData.blip) end

                                SetNewWaypoint(centralCoords.x, centralCoords.y)
                                SetUseWaypointAsDestination(true)

                                ReservePickupData.blip = CreateBlip(centralCoords, "Trả Xăng Kho Tổng")
                                SetBlipColour(ReservePickupData.blip, 2)

                                QBCore.Functions.Notify("Đã gắn bồn chứa xăng thành công! Hãy kéo bồn xăng về Tổng Kho Cây Xăng Trung Tâm để hoàn tất nhập kho.", 'success', 7500)
                            else
                                QBCore.Functions.Notify("Không thể gắn bồn chứa! Vui lòng thử lại.", 'error', 7500)
                            end
                        end
                    else
                        Wait(500)
                    end

                -- GIAI ĐOẠN 2: KÉO BỒN XĂNG VỀ TRẠM XĂNG TRUNG TÂM (TỔNG KHO)
                elseif ReservePickupData and ReservePickupData.stage == "return_to_central" then
                    local pCoords = GetEntityCoords(ped)
                    local distToCentral = #(pCoords - centralCoords)

                    if distToCentral <= 35.0 then
                        if GetVehiclePedIsIn(ped, false) == spawnedDeliveryTruck then
                            if Config.Ox.DrawText then
                                lib.showTextUI('[E] - Hoàn tất nhập xăng vào Kho Tổng', { position = 'left-center' })
                            else
                                exports[Config.Core]:DrawText('[E] - Hoàn tất nhập xăng vào Kho Tổng', 'left')
                            end

                            if IsControlJustReleased(0, 38) then
                                local hasTrailer = false
                                if spawnedTankerTrailer and DoesEntityExist(spawnedTankerTrailer) then
                                    local distTruckTrailer = #(GetEntityCoords(spawnedDeliveryTruck) - GetEntityCoords(spawnedTankerTrailer))
                                    if distTruckTrailer <= 15.0 then
                                        hasTrailer = true
                                    end
                                end

                                if not hasTrailer then
                                    QBCore.Functions.Notify("Bồn chứa xăng (trailer) ở quá xa hoặc bị ngắt kết nối! Hãy kéo bồn lại gần trạm.", 'error', 7500)
                                else
                                    if Config.Ox.DrawText then lib.hideTextUI() else exports[Config.Core]:HideText() end

                                    local deliveryLocation = ReservePickupData.location or (Config.CentralStation or 5)
                                    local truckNetId = NetworkGetNetworkIdFromEntity(spawnedDeliveryTruck)
                                    local trailerNetId = NetworkGetNetworkIdFromEntity(spawnedTankerTrailer)

                                    TaskLeaveVehicle(ped, spawnedDeliveryTruck, 1)
                                    Wait(1500)

                                    if spawnedDeliveryTruck and DoesEntityExist(spawnedDeliveryTruck) then
                                        DeleteEntity(spawnedDeliveryTruck)
                                    end
                                    if spawnedTankerTrailer and DoesEntityExist(spawnedTankerTrailer) then
                                        DeleteEntity(spawnedTankerTrailer)
                                    end

                                    TriggerServerEvent('cdn-fuel:station:server:deleteDeliveryVehicles', truckNetId, trailerNetId)
                                    TriggerServerEvent('cdn-fuel:station:server:fuelpickup:finished', deliveryLocation)

                                    if ReservePickupData and ReservePickupData.blip then RemoveBlip(ReservePickupData.blip) end
                                    spawnedDeliveryTruck = nil
                                    spawnedTankerTrailer = nil
                                    IsDeliveryInProgress = false
                                    ReservePickupData = nil
                                    break
                                end
                            end
                        else
                            Wait(250)
                        end
                    else
                        Wait(500)
                    end
                end
            end
        end)
    end)

    RegisterNetEvent('cdn-fuel:station:client:resetDelivery', function()
        if Config.Ox.DrawText then
            lib.hideTextUI()
        else
            exports[Config.Core]:HideText()
        end

        if ReservePickupData then
            if ReservePickupData.blip then RemoveBlip(ReservePickupData.blip) end
            if ReservePickupData.PolyZone then
                pcall(function() ReservePickupData.PolyZone:destroy() end)
            end
            ReservePickupData = nil
        end

        if CreatedEventHandler and locationSwapHandler then
            RemoveEventHandler(locationSwapHandler)
            CreatedEventHandler = false
        end

        if spawnedDeliveryTruck and DoesEntityExist(spawnedDeliveryTruck) then
            DeleteEntity(spawnedDeliveryTruck)
            spawnedDeliveryTruck = nil
        end

        if spawnedTankerTrailer and DoesEntityExist(spawnedTankerTrailer) then
            DeleteEntity(spawnedTankerTrailer)
            spawnedTankerTrailer = nil
        end

        IsDeliveryInProgress = false
    end)

    RegisterCommand('cancelfueldelivery', function()
        if IsDeliveryInProgress or ReservePickupData then
            local loc = ReservePickupData and ReservePickupData.location
            TriggerServerEvent('cdn-fuel:station:server:fuelpickup:failed', loc)
            TriggerEvent('cdn-fuel:station:client:resetDelivery')
            QBCore.Functions.Notify("Đã hủy nhiệm vụ nhập xăng.", "primary", 5000)
        else
            QBCore.Functions.Notify("Bạn không có nhiệm vụ nhập xăng nào đang diễn ra.", "error", 5000)
        end
    end)
    RegisterCommand('huynhapxang', function()
        ExecuteCommand('cancelfueldelivery')
    end)

    RegisterNetEvent('cdn-fuel:stations:client:purchaselocation', function(data)
        local location = type(data) == 'table' and data.location or tonumber(data)
        if not location then location = CurrentLocation end
        local PlayerData = QBCore.Functions.GetPlayerData()
        local jobName = PlayerData.job and PlayerData.job.name
        local jobGrade = PlayerData.job and PlayerData.job.grade and tonumber(PlayerData.job.grade.level or PlayerData.job.grade) or 0

        if jobName ~= "cayxang" or jobGrade < 2 then
            QBCore.Functions.Notify("Bạn cần có công việc Doanh Nghiệp Cây Xăng (Cấp bậc >= 2) mới có thể mua cây xăng!", "error", 7500)
            return
        end

        local CitizenID = PlayerData.citizenid
        CanOpen = false
        Wait(5)
        QBCore.Functions.TriggerCallback('cdn-fuel:server:locationpurchased', function(result)
            if result then
                if Config.FuelDebug then print("The Location: "..location.." is owned!") end
                IsOwned = true
            else
                if Config.FuelDebug then print("The Location: "..location.." is not owned.") end
                IsOwned = false
            end
        end, location)
        Wait(Config.WaitTime)

        if not IsOwned then
            TriggerServerEvent('cdn-fuel:server:buyStation', location, CitizenID)
        elseif IsOwned then
            QBCore.Functions.Notify(Lang:t("station_already_owned"), 'error', 7500)
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:sellstation', function(data)
        local location = data.location
        local SalePrice = data.SalePrice
        local CitizenID = QBCore.Functions.GetPlayerData().citizenid
        CanSell = false
        Wait(5)
        QBCore.Functions.TriggerCallback('cdn-fuel:server:isowner', function(result)
            if result then
                if Config.FuelDebug then print("The Location: "..location.." is owned by ID: "..CitizenID) end
                CanSell = true
            else
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                if Config.FuelDebug then print("The Location: "..location.." is not owned by ID: "..CitizenID) end
                CanSell = false
            end
        end, location)
        Wait(Config.WaitTime)
        if CanSell then
            if Config.FuelDebug then print("Attempting to sell for: $"..SalePrice) end
            TriggerServerEvent('cdn-fuel:stations:server:sellstation', location)
            if Config.FuelDebug then print("Event Triggered") end
        else
            QBCore.Functions.Notify(Lang:t("station_cannot_sell"), 'error', 7500)
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:purchasereserves:final', function(location, price, amount) -- Menu, seens after selecting the "purchase reserves" option.
        local location = location
        local price = 0
        local amount = tonumber(amount) or 1000
        local requiredDauTho = math.ceil((amount / 1000) * 3)

        CanOpen = false
        Wait(5)
        if Config.FuelDebug then print("checking ownership/employee of "..location) end
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name == 'cayxang' then
            CanOpen = true
        else
            QBCore.Functions.TriggerCallback('cdn-fuel:server:checkStationAccess', function(access)
                if access and (access.isOwner or access.isEmployee or access.grade >= 0) then
                    CanOpen = true
                else
                    QBCore.Functions.Notify("Bạn không có quyền nhập xăng tại cây xăng này!", 'error', 7500)
                    CanOpen = false
                end
            end, location)
            Wait(Config.WaitTime)
        end
        if CanOpen then
            if Config.Ox.Menu then
                lib.registerContext({
                    id = 'purchasereservesmenu',
                    title = "Nhập " .. amount .. "L Dự Trữ - " .. Config.GasStations[location].label,
                    options = {
                        {
                            title = "Xác nhận nhập " .. amount .. "L Dự Trữ",
                            description = "Chi phí: " .. requiredDauTho .. "x Dầu Thô",
                            icon = "fas fa-gas-pump",
                            arrow = false,
                            event = 'cdn-fuel:stations:client:buyreserves',
                            args = {
                                location = location,
                                price = 0,
                                amount = amount,
                            }
                        },
                        {
                            title = Lang:t("menu_header_close"),
                            description = Lang:t("menu_ped_close_footer"),
                            icon = "fas fa-times-circle",
                            arrow = false,
                            onSelect = function()
                                lib.hideContext()
                            end,
                        },
                    },
                })
                lib.showContext('purchasereservesmenu')
            else
                exports['qb-menu']:openMenu({
                    {
                        header = "Nhập " .. amount .. "L Dự Trữ - " .. Config.GasStations[location].label,
                        isMenuHeader = true,
                        icon = "fas fa-gas-pump",
                    },
                    {
                        header = "Xác nhận nhập " .. amount .. "L Dự Trữ",
                        txt = "Chi phí: " .. requiredDauTho .. "x Dầu Thô",
                        icon = "fas fa-gas-pump",
                        params = {
                            event = "cdn-fuel:stations:client:buyreserves",
                            args = {
                                location = location,
                                price = 0,
                                amount = amount,
                            },
                        },
                    },
                    {
                        header = Lang:t("menu_header_close"),
                        txt = Lang:t("menu_station_reserves_cancel_footer"),
                        icon = "fas fa-times-circle",
                        params = {
                            event = "qb-menu:closeMenu",
                        }
                    },
                })
            end
        else
            if Config.FuelDebug then print("Not showing menu, as the player doesn't have proper permissions.") end
        end
    end)

    local function GetPlayerDauThoCount(cb)
        if GetResourceState('ox_inventory') == 'started' then
            cb(exports.ox_inventory:Search('count', 'dau_tho') or 0)
        else
            QBCore.Functions.TriggerCallback('cdn-fuel:server:getDauThoCount', function(count)
                cb(count or 0)
            end)
        end
    end

    RegisterNetEvent('cdn-fuel:stations:client:purchasereserves', function(data)
        local CanOpen = false
        local location = data and data.location or CurrentLocation
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name == 'cayxang' then
            CanOpen = true
        else
            QBCore.Functions.TriggerCallback('cdn-fuel:server:checkStationAccess', function(access)
                if access and (access.isOwner or access.isEmployee or access.grade >= 0) then
                    CanOpen = true
                else
                    QBCore.Functions.Notify("Bạn không có quyền nhập xăng tại cây xăng này!", 'error', 7500)
                    CanOpen = false
                end
            end, location)
            Wait(Config.WaitTime)
        end
        if CanOpen then
            UpdateStationInfo("reserves")
            Wait(100)
            local currentFuel = tonumber(ReserveLevels) or 0
            local maxCanImport = Config.MaxFuelReserves - currentFuel
            if maxCanImport < 1000 then
                QBCore.Functions.Notify("Kho dự trữ của trạm đã đầy!", "error", 7500)
                return
            end

            GetPlayerDauThoCount(function(dauThoCount)
                if not dauThoCount or dauThoCount < 3 then
                    QBCore.Functions.Notify("Bạn không đủ Dầu Thô! (Cần tối thiểu 3x Dầu Thô để nhập 1,000L)", "error", 7500)
                    return
                end

                local maxAffordLiters = math.floor(dauThoCount / 3) * 1000
                local maxAllowedInput = math.min(maxCanImport, maxAffordLiters)

                if maxAllowedInput < 1000 then
                    QBCore.Functions.Notify("Bạn không đủ Dầu Thô để nhập thêm tối thiểu 1000L!", "error", 7500)
                    return
                end

                local amount = nil
                if Config.Ox.Input then
                    local input = lib.inputDialog('Nhập Dự Trữ Nhiên Liệu', {
                        { type = 'input', label = 'Dự trữ trạm hiện tại', default = currentFuel .. ' / ' .. Config.MaxFuelReserves .. ' Lít', disabled = true },
                        { type = 'input', label = 'Dầu Thô hiện có', default = dauThoCount .. 'x Dầu Thô (Nhập tối đa ' .. maxAllowedInput .. 'L)', disabled = true },
                        { type = 'number', label = 'Nhập số Lít cần nhập (1000L = 3x Dầu Thô)', default = 1000, min = 1000, max = maxAllowedInput, step = 1000 }
                    })
                    if not input or not input[3] then return end
                    amount = tonumber(input[3])
                else
                    local input = exports['qb-input']:ShowInput({
                        header = "Nhập Dự Trữ (Có: " .. dauThoCount .. "x Dầu Thô | Tối đa " .. maxAllowedInput .. "L)",
                        submitText = "Tiếp tục",
                        inputs = { {
                            type = 'number',
                            isRequired = true,
                            name = 'amount',
                            text = 'Nhập số Lít (1000L = 3x Dầu Thô)'
                        }}
                    })
                    if not input or not input.amount then return end
                    amount = tonumber(input.amount)
                end

                if not amount or amount < 1000 then
                    QBCore.Functions.Notify("Số lượng nhập tối thiểu là 1000L!", "error", 7500)
                    return
                end

                local requiredDauTho = math.ceil((amount / 1000) * 3)
                if dauThoCount < requiredDauTho then
                    QBCore.Functions.Notify("Bạn không đủ Dầu Thô! Cần " .. requiredDauTho .. "x Dầu Thô (bạn hiện có " .. dauThoCount .. "x)", "error", 7500)
                    return
                end

                if amount > maxCanImport then
                    QBCore.Functions.Notify("Số lượng nhập vượt quá sức chứa tối đa của trạm!", "error", 7500)
                    return
                end

                TriggerEvent("cdn-fuel:stations:client:purchasereserves:final", location, 0, amount)
            end)
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:changefuelprice', function(data)
        CanOpen = false
        local location = data.location
        QBCore.Functions.TriggerCallback('cdn-fuel:server:isowner', function(result)
            local CitizenID = QBCore.Functions.GetPlayerData().citizenid
            if result then
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is owned by ID: "..CitizenID) end
                CanOpen = true
            else
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is not owned by ID: "..CitizenID) end
                CanOpen = false
            end
        end, location)
        Wait(Config.WaitTime)
        if CanOpen then
            if Config.FuelDebug then print("Showing Input for Fuel Price Change!") end
            if Config.Ox.Input then
                local fuelprice = lib.inputDialog('Fuel Prices', {
                    { type = "input", label = 'Current Price',
                    default = '$'.. Comma_Value(StationFuelPrice) .. ' Per Liter',
                    disabled = true },
                    { type = "number", label = 'Enter New Fuel Price Per Liter',
                    default = StationFuelPrice,
                    min = Config.MinimumFuelPrice,
                    max = Config.MaxFuelPrice
                    },
                })
                if not fuelprice then return end
                fuelPrice = tonumber(fuelprice[2])
                if fuelprice then
                    if Config.FuelDebug then print("Attempting to change fuel price!") end
                    Wait(100)
                    if not fuelPrice then QBCore.Functions.Notify(Lang:t("station_amount_invalid"), 'error', 7500) return end
                    NewFuelPrice = tonumber(fuelPrice)
                    if NewFuelPrice < Config.MinimumFuelPrice then QBCore.Functions.Notify(Lang:t("station_price_too_low"), 'error', 7500) return end
                    if NewFuelPrice > Config.MaxFuelPrice then
                        QBCore.Functions.Notify("Giá xăng không được vượt quá giá mặc định tự động ($" .. Config.MaxFuelPrice .. ")!", "error", 7500)
                    else
                        TriggerServerEvent("cdn-fuel:station:server:updatefuelprice", NewFuelPrice, CurrentLocation)
                    end
                end
            else
                local fuelprice = exports['qb-input']:ShowInput({
                    header = Lang:t("input_alter_fuel_price_header_1")..StationFuelPrice..Lang:t("input_alter_fuel_price_header_2"),
                    submitText = Lang:t("input_alter_fuel_price_submit_text"),
                    inputs = { {
                        type = 'number',
                        isRequired = true,
                        name = 'price',
                        text = Lang:t("input_alter_fuel_price_submit_text")
                    }}
                })
                if fuelprice then
                    if Config.FuelDebug then print("Attempting to change fuel price!") end
                    Wait(100)
                    if not fuelprice.price then QBCore.Functions.Notify(Lang:t("station_amount_invalid"), 'error', 7500) return end
                    NewFuelPrice = tonumber(fuelprice.price)
                    if NewFuelPrice < Config.MinimumFuelPrice then QBCore.Functions.Notify(Lang:t("station_price_too_low"), 'error', 7500) return end
                    if NewFuelPrice > Config.MaxFuelPrice then
                        QBCore.Functions.Notify("Giá xăng không được vượt quá giá mặc định tự động ($" .. Config.MaxFuelPrice .. ")!", "error", 7500)
                    else
                        TriggerServerEvent("cdn-fuel:station:server:updatefuelprice", NewFuelPrice, CurrentLocation)
                    end
                end
            end
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:sellstation:menu', function(data) -- Menu, seen after selecting the Sell this Location option.
        local location = data.location
        local CitizenID = QBCore.Functions.GetPlayerData().citizenid
        QBCore.Functions.TriggerCallback('cdn-fuel:server:isowner', function(result)
            if result then
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is owned by ID: "..CitizenID) end
                CanOpen = true
            else
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is not owned by ID: "..CitizenID) end
                CanOpen = false
            end
        end, CurrentLocation)
        Wait(Config.WaitTime)
        if CanOpen then
            local GasStationCost = Config.GasStations[location].cost + GlobalTax(Config.GasStations[location].cost)
            local SalePrice = math.percent(Config.GasStationSellPercentage, GasStationCost)
            if Config.Ox.Menu then
                lib.registerContext({
                    id = 'sellstationmenu',
                    title = Lang:t("menu_sell_station_header")..Config.GasStations[location].label,
                    options = {
                        {
                            title = Lang:t("menu_sell_station_header_accept"),
                            description = Lang:t("menu_sell_station_footer_accept")..Comma_Value(SalePrice)..".",
                            icon = "fas fa-usd",
                            arrow = false, -- puts arrow to the right
                            event = 'cdn-fuel:stations:client:sellstation',
                            args = {
                                location = location,
                                SalePrice = SalePrice,
                            }
                        },
                        {
                            title = Lang:t("menu_header_close"),
                            description = Lang:t("menu_refuel_cancel"),
                            icon = "fas fa-times-circle",
                            arrow = false, -- puts arrow to the right
                            onSelect = function()
                                lib.hideContext()
                              end,
                        },
                    },
                })
                lib.showContext('sellstationmenu')
                TriggerServerEvent("cdn-fuel:stations:server:stationsold", location)
            else
                exports['qb-menu']:openMenu({
                    {
                        header = Lang:t("menu_sell_station_header")..Config.GasStations[location].label,
                        isMenuHeader = true,
                        icon = "fas fa-gas-pump",
                    },
                    {
                        header = Lang:t("menu_sell_station_header_accept"),
                        txt = Lang:t("menu_sell_station_footer_accept")..SalePrice..".",
                        icon = "fas fa-usd",
                        params = {
                            event = "cdn-fuel:stations:client:sellstation",
                            args = {
                                location = location,
                                SalePrice = SalePrice,
                            }
                        },
                    },
                    {
                        header = Lang:t("menu_header_close"),
                        txt = Lang:t("menu_sell_station_footer_close"),
                        icon = "fas fa-times-circle",
                        params = {
                            event = "qb-menu:closeMenu",
                        }
                    },
                })
                TriggerServerEvent("cdn-fuel:stations:server:stationsold", location)
            end
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:changestationname', function() -- Menu for changing the label of the owned station.
        if not Config.GasStationNameChanges then
            QBCore.Functions.Notify("Tính năng đổi tên cây xăng đã bị vô hiệu hóa!", 'error', 7500)
            return
        end
        CanOpen = false
        QBCore.Functions.TriggerCallback('cdn-fuel:server:isowner', function(result)
            local CitizenID = QBCore.Functions.GetPlayerData().citizenid
            if result then
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is owned by ID: "..CitizenID) end
                CanOpen = true
            else
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is not owned by ID: "..CitizenID) end
                CanOpen = false
            end
        end, CurrentLocation)
        Wait(Config.WaitTime)
        if CanOpen then
            if Config.FuelDebug then print("Showing Input for name Change!") end
            if Config.Ox.Input then
                local NewName = lib.inputDialog('Name Changer', {
                    { type = "input", label = 'Current Name',
                    default = Config.GasStations[CurrentLocation].label,
                    disabled = true },
                    { type = "input", label = 'Enter New Station Name',
                    placeholder = 'New Name'
                    },
                })
                if not NewName then return end
                NewNameName = NewName[2]
                if NewName then
                    if Config.FuelDebug then print("Attempting to alter stations name!") end
                    if not NewNameName then QBCore.Functions.Notify(Lang:t("station_name_invalid"), 'error', 7500) return end
                    NewName = NewNameName
                    if type(NewName) ~= "string" then QBCore.Functions.Notify(Lang:t("station_name_invalid"), 'error') return end
                    if Config.ProfanityList[NewName] then QBCore.Functions.Notify(Lang:t("station_name_invalid"), 'error', 7500)
                        -- You can add logs for people that put prohibited words into the name changer if wanted, and here is where you would do it.
                        return
                    end
                    if string.len(NewName) > Config.NameChangeMaxChar then QBCore.Functions.Notify(Lang:t("station_name_too_long"), 'error') return end
                    if string.len(NewName) < Config.NameChangeMinChar then QBCore.Functions.Notify(Lang:t("station_name_too_short"), 'error') return end
                    Wait(100)
                    TriggerServerEvent("cdn-fuel:station:server:updatelocationname", NewName, CurrentLocation)
                end
            else
                local NewName = exports['qb-input']:ShowInput({
                    header = Lang:t("input_change_name_header_1")..Config.GasStations[CurrentLocation].label..Lang:t("input_change_name_header_2"),
                    submitText = Lang:t("input_change_name_submit_text"),
                    inputs = { {
                        type = 'text',
                        isRequired = true,
                        name = 'newname',
                        text = Lang:t("input_change_name_text")
                    }}
                })
                if NewName then
                    if Config.FuelDebug then print("Attempting to alter stations name!") end
                    if not NewName.newname then QBCore.Functions.Notify(Lang:t("station_name_invalid"), 'error', 7500) return end
                    NewName = NewName.newname
                    if type(NewName) ~= "string" then QBCore.Functions.Notify(Lang:t("station_name_invalid"), 'error') return end
                    if Config.ProfanityList[NewName] then QBCore.Functions.Notify(Lang:t("station_name_invalid"), 'error', 7500)
                        -- You can add logs for people that put prohibited words into the name changer if wanted, and here is where you would do it.
                        return
                    end
                    TriggerServerEvent("cdn-fuel:station:server:updatelocationname", NewName, CurrentLocation)
                end
            end
        end
    end)

local function OpenRecruitEmployeeMenu(location)
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    local players = QBCore.Functions.GetPlayersFromCoords(myCoords, 3.0)
    local targetServerIds = {}

    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            table.insert(targetServerIds, GetPlayerServerId(playerId))
        end
    end

    if #targetServerIds == 0 then
        QBCore.Functions.Notify("Không có người chơi nào ở gần bạn (bán kính 3m)!", "error", 7500)
        return
    end

    QBCore.Functions.TriggerCallback('cdn-fuel:server:getnearbyplayersinfo', function(playersData)
        if not playersData or #playersData == 0 then
            QBCore.Functions.Notify("Không tìm thấy thông tin người chơi ở gần!", "error")
            return
        end

        QBCore.Functions.TriggerCallback('cdn-fuel:server:checkStationAccess', function(access)
            local isOwner = access and access.isOwner
            local myGrade = access and (access.grade or 0) or 0

            if not isOwner then
                QBCore.Functions.Notify("Chỉ Phó Giám Đốc (Cấp 2) trở lên mới có quyền tuyển dụng nhân sự!", "error", 7500)
                return
            end

            local options = {}
            for _, pData in ipairs(playersData) do
                local playerTitle = "[ID: " .. pData.serverId .. "] " .. pData.name

                table.insert(options, {
                    title = playerTitle,
                    description = "Nhấp để tuyển vào Doanh Nghiệp Cây Xăng",
                    icon = "fas fa-user-plus",
                    arrow = true,
                    onSelect = function()
                        local gradeOptions = {
                            {
                                title = "Bậc 1: Nhân Viên (Level 0)",
                                description = "Nhân viên trực tiếp hỗ trợ bơm xăng",
                                icon = "fas fa-user",
                                onSelect = function()
                                    TriggerServerEvent('cdn-fuel:server:hireEmployee', pData.serverId, 0, location)
                                end
                            },
                            {
                                title = "Bậc 2: Quản Lý (Level 1)",
                                description = "Quản lý hoạt động tại các trạm xăng",
                                icon = "fas fa-user-tie",
                                onSelect = function()
                                    TriggerServerEvent('cdn-fuel:server:hireEmployee', pData.serverId, 1, location)
                                end
                            }
                        }

                        if myGrade >= 3 then
                            table.insert(gradeOptions, {
                                title = "Bậc 3: Phó Giám Đốc (Level 2)",
                                description = "Ban lãnh đạo, có quyền tuyển dụng & quản lý nhân sự",
                                icon = "fas fa-user-shield",
                                onSelect = function()
                                    TriggerServerEvent('cdn-fuel:server:hireEmployee', pData.serverId, 2, location)
                                end
                            })
                        end

                        table.insert(gradeOptions, {
                            title = Lang:t("menu_header_close"),
                            icon = "fas fa-times-circle",
                            onSelect = function() lib.hideContext() end
                        })

                        if Config.Ox.Menu then
                            lib.registerContext({
                                id = 'selectemployeegrade',
                                title = "Chọn Chức Vụ Cho " .. pData.name,
                                options = gradeOptions
                            })
                            lib.showContext('selectemployeegrade')
                        else
                            local qbGradeOpts = { { header = "Chọn Chức Vụ Cho " .. pData.name, isMenuHeader = true } }
                            for _, gOpt in ipairs(gradeOptions) do
                                if gOpt.onSelect then
                                    table.insert(qbGradeOpts, {
                                        header = gOpt.title,
                                        txt = gOpt.description or "",
                                        params = { isAction = true, action = gOpt.onSelect }
                                    })
                                end
                            end
                            exports['qb-menu']:openMenu(qbGradeOpts)
                        end
                    end
                })
            end

            table.insert(options, {
                title = Lang:t("menu_header_close"),
                icon = "fas fa-times-circle",
                onSelect = function() lib.hideContext() end
            })

            if Config.Ox.Menu then
                lib.registerContext({
                    id = 'recruitmenu',
                    title = 'Tuyển Nhân Viên Doanh Nghiệp Cây Xăng',
                    options = options
                })
                lib.showContext('recruitmenu')
            else
                local qbOptions = { { header = 'Tuyển Nhân Viên Doanh Nghiệp Cây Xăng', isMenuHeader = true } }
                for _, opt in ipairs(options) do
                    if opt.onSelect then
                        table.insert(qbOptions, {
                            header = opt.title,
                            txt = opt.description or "",
                            params = { isAction = true, action = opt.onSelect }
                        })
                    end
                end
                exports['qb-menu']:openMenu(qbOptions)
            end
        end, location)
    end, targetServerIds)
end

local function OpenEmployeeListMenu(location)
    QBCore.Functions.TriggerCallback('cdn-fuel:server:getEmployeeList', function(employees)
        if not employees or #employees == 0 then
            QBCore.Functions.Notify("Hiện chưa có nhân viên nào trong Doanh Nghiệp Cây Xăng!", "error", 7500)
            return
        end

        QBCore.Functions.TriggerCallback('cdn-fuel:server:checkStationAccess', function(access)
            local isOwner = access and access.isOwner
            local options = {}
            for _, emp in ipairs(employees) do
                local statusText = emp.isOnline and "🟢 Online" or "🔴 Offline"
                local gradeText = (emp.gradeLevel >= 2 and "Phó Giám Đốc (Level " .. emp.gradeLevel .. ")") or (emp.gradeLevel == 1 and "Quản Lý (Level 1)") or "Nhân Viên (Level 0)"
                local titleStr = emp.name .. " (" .. gradeText .. ")"

                table.insert(options, {
                    title = titleStr,
                    description = "CID: " .. emp.citizenid .. " | Trạng thái: " .. statusText,
                    icon = emp.gradeLevel >= 2 and "fas fa-user-shield" or (emp.gradeLevel == 1 and "fas fa-user-tie" or "fas fa-user"),
                    arrow = true,
                    onSelect = function()
                        local subOptions = {}

                        if isOwner then
                            table.insert(subOptions, {
                                title = "Sa Thải Nhân Viên",
                                description = "Xóa nhân viên " .. emp.name .. " khỏi Doanh Nghiệp",
                                icon = "fas fa-user-minus",
                                onSelect = function()
                                    TriggerServerEvent('cdn-fuel:server:fireEmployeeByCitizenId', emp.citizenid, location)
                                end
                            })

                            if emp.gradeLevel == 0 then
                                table.insert(subOptions, 1, {
                                    title = "Thăng Chức -> Quản Lý (Level 1)",
                                    description = "Nâng cấp lên vị trí Quản Lý trạm",
                                    icon = "fas fa-arrow-up",
                                    onSelect = function()
                                        TriggerServerEvent('cdn-fuel:server:setEmployeeGradeByCitizenId', emp.citizenid, 1, location)
                                    end
                                })
                            elseif emp.gradeLevel == 1 then
                                table.insert(subOptions, 1, {
                                    title = "Hạ Chức -> Nhân Viên (Level 0)",
                                    description = "Giảm chức vụ xuống Nhân Viên",
                                    icon = "fas fa-arrow-down",
                                    onSelect = function()
                                        TriggerServerEvent('cdn-fuel:server:setEmployeeGradeByCitizenId', emp.citizenid, 0, location)
                                    end
                                })
                            end
                        else
                            table.insert(subOptions, {
                                title = "Không có quyền quản lý",
                                description = "Chỉ Phó Giám Đốc trở lên mới có thể quản lý nhân sự",
                                icon = "fas fa-lock"
                            })
                        end

                        table.insert(subOptions, {
                            title = Lang:t("menu_header_close"),
                            icon = "fas fa-times-circle",
                            onSelect = function() lib.hideContext() end
                        })

                        if Config.Ox.Menu then
                            lib.registerContext({
                                id = 'manage_emp_' .. emp.citizenid,
                                title = 'Quản Lý: ' .. emp.name,
                                options = subOptions
                            })
                            lib.showContext('manage_emp_' .. emp.citizenid)
                        else
                            local qbOpts = { { header = 'Quản Lý: ' .. emp.name, isMenuHeader = true } }
                            for _, opt in ipairs(subOptions) do
                                if opt.onSelect then
                                    table.insert(qbOpts, {
                                        header = opt.title,
                                        txt = opt.description or "",
                                        params = { isAction = true, action = opt.onSelect }
                                    })
                                end
                            end
                            exports['qb-menu']:openMenu(qbOpts)
                        end
                    end
                })
            end

            table.insert(options, {
                title = Lang:t("menu_header_close"),
                icon = "fas fa-times-circle",
                onSelect = function() lib.hideContext() end
            })

            if Config.Ox.Menu then
                lib.registerContext({
                    id = 'employeelistmenu',
                    title = 'Nhân Viên Cây Xăng #' .. location .. ' (' .. #employees .. ')',
                    options = options
                })
                lib.showContext('employeelistmenu')
            else
                local qbOptions = { { header = 'Nhân Viên Cây Xăng #' .. location .. ' (' .. #employees .. ')', isMenuHeader = true } }
                for _, opt in ipairs(options) do
                    if opt.onSelect then
                        table.insert(qbOptions, {
                            header = opt.title,
                            txt = opt.description or "",
                            params = { isAction = true, action = opt.onSelect }
                        })
                    end
                end
                exports['qb-menu']:openMenu(qbOptions)
            end
        end, location)
    end, location)
end

RegisterNetEvent('cdn-fuel:stations:client:recruitmenu', function(data)
    local location = data and data.location or CurrentLocation
    OpenRecruitEmployeeMenu(location)
end)

RegisterNetEvent('cdn-fuel:stations:client:firemenu', function(data)
    local location = data and data.location or CurrentLocation
    OpenEmployeeListMenu(location)
end)

    -- NUI Callbacks --
    RegisterNUICallback('closeUI', function(data, cb)
        SetNuiFocus(false, false)
        cb('ok')
    end)

    RegisterNUICallback('toggleDuty', function(data, cb)
        TriggerServerEvent('cdn-fuel:server:toggleDuty')
        cb('ok')
    end)

    RegisterNUICallback('purchaseFuelReserves', function(data, cb)
        if data and data.location and data.amount then
            TriggerServerEvent('cdn-fuel:stations:server:buyreserves', data.location, data.amount)
        end
        cb('ok')
    end)

    RegisterNUICallback('purchaseElectricReserves', function(data, cb)
        if data and data.location and data.amount then
            TriggerServerEvent('cdn-fuel:stations:server:purchaseelectricreserves', data.location, data.amount)
        end
        cb('ok')
    end)



    RegisterNUICallback('changeFuelPrice', function(data, cb)
        if data and data.location and data.price then
            TriggerServerEvent('cdn-fuel:stations:server:alterfuelprice', data.location, data.price)
        end
        cb('ok')
    end)

    RegisterNUICallback('manageFunds', function(data, cb)
        if data and data.location and data.amount and data.actionType then
            if data.actionType == 'deposit' then
                TriggerServerEvent('cdn-fuel:stations:server:depositmoney', data.location, data.amount)
            elseif data.actionType == 'withdraw' then
                TriggerServerEvent('cdn-fuel:stations:server:withdrawmoney', data.location, data.amount)
            end
        end
        cb('ok')
    end)

    RegisterNUICallback('changeStationName', function(data, cb)
        if not Config.GasStationNameChanges then
            QBCore.Functions.Notify("Tính năng đổi tên cây xăng đã bị vô hiệu hóa!", 'error', 7500)
            cb('disabled')
            return
        end
        if data and data.location and data.name then
            TriggerServerEvent('cdn-fuel:station:server:updatelocationname', data.name, data.location)
        end
        cb('ok')
    end)

    RegisterNUICallback('hireEmployee', function(data, cb)
        local targetSrc = data and (data.targetSource or data.targetServerId or data.source or data.serverId)
        if data and targetSrc and data.location then
            TriggerServerEvent('cdn-fuel:server:hireEmployee', tonumber(targetSrc), data.grade or 0, data.location)
        end
        cb('ok')
    end)

    RegisterNUICallback('recruitPlayer', function(data, cb)
        local targetSrc = data and (data.targetSource or data.targetServerId or data.source or data.serverId)
        if data and targetSrc and data.location then
            TriggerServerEvent('cdn-fuel:server:hireEmployee', tonumber(targetSrc), data.grade or 0, data.location)
        end
        cb('ok')
    end)

    RegisterNUICallback('fireEmployee', function(data, cb)
        if data and data.citizenid then
            local location = data.location or CurrentLocation
            TriggerServerEvent('cdn-fuel:server:fireEmployee', data.citizenid, location)
        end
        cb('ok')
    end)

    RegisterNUICallback('setEmployeeGrade', function(data, cb)
        if data and data.citizenid and data.grade ~= nil then
            local location = data.location or CurrentLocation
            TriggerServerEvent('cdn-fuel:server:setEmployeeGrade', data.citizenid, data.grade, location)
        end
        cb('ok')
    end)

    RegisterNUICallback('sellStation', function(data, cb)
        if data and data.location then
            TriggerServerEvent('cdn-fuel:stations:server:sellstation', data.location)
        end
        cb('ok')
    end)

    RegisterNUICallback('getNearbyPlayersForTransfer', function(payload, cb)
        local location = payload and payload.location or CurrentLocation
        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)
        local nearbyIds = {}
        local radius = (payload and tonumber(payload.radius)) or 5.0

        if QBCore.Functions.GetPlayersFromCoords then
            local players = QBCore.Functions.GetPlayersFromCoords(pCoords, radius)
            for _, player in ipairs(players) do
                if player ~= PlayerId() then
                    table.insert(nearbyIds, GetPlayerServerId(player))
                end
            end
        else
            for _, player in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(player)
                if targetPed ~= playerPed then
                    local targetCoords = GetEntityCoords(targetPed)
                    if #(pCoords - targetCoords) <= radius then
                        table.insert(nearbyIds, GetPlayerServerId(player))
                    end
                end
            end
        end

        if #nearbyIds == 0 then
            cb({ players = {} })
            return
        end

        QBCore.Functions.TriggerCallback('cdn-fuel:server:getnearbyplayersinfo', function(nearbyPlayers)
            cb({ players = nearbyPlayers or {} })
        end, nearbyIds)
    end)

    RegisterNUICallback('transferStation', function(data, cb)
        local targetSrc = data and (data.targetSource or data.targetServerId or data.source or data.serverId)
        if data and data.location and targetSrc then
            TriggerServerEvent('cdn-fuel:stations:server:transferStation', data.location, tonumber(targetSrc), data.targetCitizenId)
        end
        SetNuiFocus(false, false)
        cb('ok')
    end)

    RegisterNetEvent('cdn-fuel:stations:client:updateStationBalance', function(location, newBalance)
        StationBalance = tonumber(newBalance) or 0
        SendNUIMessage({
            action = 'updateBalance',
            data = {
                location = location,
                balance = StationBalance
            }
        })
    end)

    RegisterNetEvent('cdn-fuel:stations:client:updateStationFuelPrice', function(location, newPrice)
        StationFuelPrice = tonumber(newPrice) or StationFuelPrice
        SendNUIMessage({
            action = 'updatePrice',
            data = {
                location = location,
                fuelprice = StationFuelPrice
            }
        })
    end)

    RegisterNetEvent('cdn-fuel:stations:client:managemenu', function() -- Modern React Cyan NUI Manager
        local location = CurrentLocation
        if not location or location <= 0 then return end

        QBCore.Functions.TriggerCallback('cdn-fuel:server:checkStationAccess', function(access)
            if not access or (not access.isOwner and access.grade < 0) then
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                return
            end

            local isOwner = access.isOwner
            local isManager = (access.isOwner or access.grade >= 1)
            local isStaff = (access.isOwner or access.grade >= 0)

            UpdateStationInfo("all")
            Wait(150)

            QBCore.Functions.TriggerCallback('cdn-fuel:server:getEmployeeList', function(employees)
                employees = employees or {}

                local playerPed = PlayerPedId()
                local pCoords = GetEntityCoords(playerPed)
                local nearbyIds = {}
                if QBCore.Functions.GetPlayersFromCoords then
                    local players = QBCore.Functions.GetPlayersFromCoords(pCoords, 3.0)
                    for _, player in ipairs(players) do
                        if player ~= PlayerId() then
                            table.insert(nearbyIds, GetPlayerServerId(player))
                        end
                    end
                else
                    for _, player in ipairs(GetActivePlayers()) do
                        local targetPed = GetPlayerPed(player)
                        if targetPed ~= playerPed then
                            local targetCoords = GetEntityCoords(targetPed)
                            if #(pCoords - targetCoords) <= 3.0 then
                                table.insert(nearbyIds, GetPlayerServerId(player))
                            end
                        end
                    end
                end

                QBCore.Functions.TriggerCallback('cdn-fuel:server:getnearbyplayersinfo', function(nearbyPlayers)
                    nearbyPlayers = nearbyPlayers or {}

                    local PlayerData = QBCore.Functions.GetPlayerData()
                    local onDuty = PlayerData.job and PlayerData.job.onduty or false

                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = 'openStationManager',
                        data = {
                            location = location,
                            label = Config.GasStations[location].label or "Trạm Xăng",
                            fuel = tonumber(ReserveLevels) or 0,
                            maxFuel = Config.MaxFuelReserves or 10000,
                            electric = tonumber(ElectricReserveLevels) or 0,
                            maxElectric = Config.MaxElectricReserves or 10000,
                            balance = tonumber(StationBalance) or 0,
                            fuelprice = tonumber(StationFuelPrice) or Config.CostMultiplier,
                            isOwner = isOwner,
                            isManager = isManager,
                            isStaff = isStaff,
                            onDuty = onDuty,
                            employees = employees,
                            nearbyPlayers = nearbyPlayers,
                            fuelPerDauTho = Config.FuelPerDauTho or 100,
                            electricPerPin = Config.ElectricPerPinNangLuong or 100,
                            allowNameChange = (Config.GasStationNameChanges == true)
                        }
                    })
                end, nearbyIds)
            end, location)
        end, location)
    end)

    RegisterNetEvent('cdn-fuel:stations:client:purchaseelectricreserves', function(data)
        local location = data and data.location or CurrentLocation
        if not location or location <= 0 then return end
        UpdateStationInfo("electric")
        Wait(100)

        local maxElectric = Config.MaxElectricReserves or 10000
        local currentElectric = ElectricReserveLevels or 0

        if currentElectric >= maxElectric then
            QBCore.Functions.Notify("Dự trữ điện của trạm sạc đã đầy (" .. maxElectric .. " KW)!", "error", 7500)
            return
        end

        local amount = nil
        if Config.Ox.Input then
            local input = lib.inputDialog('NẠP DỰ TRỮ ĐIỆN TRẠM SẠC', {
                { type = 'input', label = 'Dự trữ điện hiện tại', default = currentElectric .. ' / ' .. maxElectric .. ' KW', disabled = true },
                { type = 'number', label = 'Số KW điện cần nạp (1000 KW = 3x Pin Năng Lượng)', default = 1000, min = 1, max = (maxElectric - currentElectric), required = true }
            })

            if not input or not input[2] then return end
            amount = tonumber(input[2])
        else
            local dialog = exports['qb-input']:ShowInput({
                header = "NẠP DỰ TRỮ ĐIỆN (Hiện có: " .. currentElectric .. " / " .. maxElectric .. " KW)",
                submitText = "Nạp Điện",
                inputs = {
                    {
                        text = "Số KW điện cần nạp (3x Pin Năng Lượng = 1000 KW)",
                        name = "amount",
                        type = "number",
                        isRequired = true,
                        default = "1000"
                    }
                }
            })

            if not dialog or not dialog.amount then return end
            amount = tonumber(dialog.amount)
        end

        if not amount or amount < 1 then return end
        local requiredPin = math.ceil((amount / 1000) * 3)

        if Config.Ox.Menu then
            lib.registerContext({
                id = 'purchaseelectricreservesmenu',
                title = "Nạp " .. amount .. " KW Điện - " .. Config.GasStations[location].label,
                options = {
                    {
                        title = "Xác nhận nạp " .. amount .. " KW Điện Dự Trữ",
                        description = "Chi phí: " .. requiredPin .. "x Pin Năng Lượng",
                        icon = "fas fa-bolt",
                        arrow = false,
                        onSelect = function()
                            TriggerServerEvent('cdn-fuel:stations:server:purchaseelectricreserves', location, amount)
                        end
                    },
                    {
                        title = Lang:t("menu_header_close"),
                        icon = "fas fa-times-circle",
                        arrow = false,
                        onSelect = function() lib.hideContext() end,
                    },
                },
            })
            lib.showContext('purchaseelectricreservesmenu')
        else
            exports['qb-menu']:openMenu({
                {
                    header = "Nạp " .. amount .. " KW Điện - " .. Config.GasStations[location].label,
                    isMenuHeader = true,
                    icon = "fas fa-bolt",
                },
                {
                    header = "Xác nhận nạp " .. amount .. " KW Điện Dự Trữ",
                    txt = "Chi phí: " .. requiredPin .. "x Pin Năng Lượng",
                    icon = "fas fa-bolt",
                    params = {
                        isAction = true,
                        action = function()
                            TriggerServerEvent('cdn-fuel:stations:server:purchaseelectricreserves', location, amount)
                        end
                    },
                },
                {
                    header = Lang:t("menu_header_close"),
                    icon = "fas fa-times-circle",
                    params = { event = "qb-menu:closeMenu" }
                },
            })
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:buyjerrycanfromreserves', function(data)
        local loc = data and data.location or CurrentLocation
        UpdateStationInfo("reserves")
        Wait(100)

        local amount = nil
        if Config.Ox.Input then
            local input = lib.inputDialog('Mua / Chiết Can Xăng', {
                { type = "input", label = 'Dự trữ trạm hiện tại', default = ReserveLevels .. ' Lít', disabled = true },
                { type = "number", label = 'Lượng xăng cần chiết vào can (25L - 100L)', default = 25, min = 25, max = 100 }
            })
            if not input or not input[2] then return end
            amount = tonumber(input[2])
        else
            local input = exports['qb-input']:ShowInput({
                header = "Mua / Chiết Can Xăng (Dự trữ: " .. ReserveLevels .. "L)",
                submitText = "Chiết Can Xăng",
                inputs = { {
                    type = 'number',
                    isRequired = true,
                    name = 'amount',
                    text = 'Nhập lượng xăng từ 25 đến 100 (Lít)'
                }}
            })
            if not input or not input.amount then return end
            amount = tonumber(input.amount)
        end

        if not amount or amount < 25 or amount > 100 then
            QBCore.Functions.Notify("Lượng xăng mỗi can phải từ 25L đến 100L!", "error", 7500)
            return
        end

        if amount > tonumber(ReserveLevels) then
            QBCore.Functions.Notify("Dự trữ nhiên liệu tại trạm không đủ! (Hiện có: " .. ReserveLevels .. "L)", "error", 7500)
            return
        end

        TriggerServerEvent('cdn-fuel:stations:server:buyjerrycanfromreserves', loc, amount)
    end)

    RegisterNetEvent('cdn-fuel:stations:client:managefunds', function(location) -- Menu, seen after selecting the Manage this Location Option.
        QBCore.Functions.TriggerCallback('cdn-fuel:server:isowner', function(result)
            local CitizenID = QBCore.Functions.GetPlayerData().citizenid
            if result then
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is owned by ID: "..CitizenID) end
                CanOpen = true
            else
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is not owned by ID: "..CitizenID) end
                CanOpen = false
            end
        end, CurrentLocation)
        UpdateStationInfo("all")
        Wait(5)
        Wait(Config.WaitTime)
        if CanOpen then

            if Config.Ox.Menu then
                lib.registerContext({
                    id = 'managefundsmenu',
                    title = Lang:t("menu_manage_company_funds_header_2")..Config.GasStations[CurrentLocation].label,
                    options = {
                        {
                            title = Lang:t("menu_manage_company_funds_withdraw_header"),
                            description = Lang:t("menu_manage_company_funds_withdraw_footer"),
                            icon = "fas fa-arrow-left",
                            arrow = false, -- puts arrow to the right
                            event = 'cdn-fuel:stations:client:WithdrawFunds',
                            args = {
                                location = location,
                            }
                        },
                        {
                            title = Lang:t("menu_manage_company_funds_deposit_header"),
                            description = Lang:t("menu_manage_company_funds_deposit_footer"),
                            icon = "fas fa-arrow-right",
                            arrow = false, -- puts arrow to the right
                            event = 'cdn-fuel:stations:client:DepositFunds',
                            args = {
                                location = location,
                            }
                        },
                        {
                            title = Lang:t("menu_manage_company_funds_return_header"),
                            description = Lang:t("menu_manage_company_funds_return_footer"),
                            icon = "fas fa-circle-left",
                            arrow = false, -- puts arrow to the right
                            event = 'cdn-fuel:stations:client:managemenu',
                            args = {
                                location = location,
                            }
                        },
                        {
                            title = Lang:t("menu_header_close"),
                            description = Lang:t("menu_refuel_cancel"),
                            icon = "fas fa-times-circle",
                            arrow = false, -- puts arrow to the right
                            onSelect = function()
                                lib.hideContext()
                              end,
                        },
                    },
                })
                lib.showContext('managefundsmenu')
            else
                exports['qb-menu']:openMenu({
                    {
                        header = Lang:t("menu_manage_company_funds_header_2")..Config.GasStations[CurrentLocation].label,
                        isMenuHeader = true,
                        icon = "fas fa-gas-pump",
                    },
                    {
                        header = Lang:t("menu_manage_company_funds_withdraw_header"),
                        icon = "fas fa-arrow-left",
                        txt = Lang:t("menu_manage_company_funds_withdraw_footer"),
                        params = {
                            event = "cdn-fuel:stations:client:WithdrawFunds",
                            args = {
                                location = location,
                            }
                        },
                    },
                    {
                        header = Lang:t("menu_manage_company_funds_deposit_header"),
                        icon = "fas fa-arrow-right",
                        txt = Lang:t("menu_manage_company_funds_deposit_footer"),
                        params = {
                            event = "cdn-fuel:stations:client:DepositFunds",
                            args = {
                                location = location,
                            }
                        },
                    },
                    {
                        header = Lang:t("menu_manage_company_funds_return_header"),
                        txt = Lang:t("menu_manage_company_funds_return_footer"),
                        icon = "fas fa-circle-left",
                        params = {
                            event = "cdn-fuel:stations:client:managemenu",
                            args = {
                                location = location,
                            }
                        },
                    },
                })
            end
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:WithdrawFunds', function(data)
        if Config.FuelDebug then print("Triggered Event for: Withdraw!") end
        CanOpen = false
        local location = CurrentLocation
        QBCore.Functions.TriggerCallback('cdn-fuel:server:isowner', function(result)
            local CitizenID = QBCore.Functions.GetPlayerData().citizenid
            if result then
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is owned by ID: "..CitizenID) end
                CanOpen = true
            else
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is not owned by ID: "..CitizenID) end
                CanOpen = false
            end
        end, CurrentLocation)
        Wait(Config.WaitTime)
        if CanOpen then
            if Config.FuelDebug then print("Showing Input for Withdraw!") end
            UpdateStationInfo("balance")
            Wait(50)
            if Config.Ox.Input then
                local Withdraw = lib.inputDialog('Withdraw Funds', {
                    { type = "input", label = 'Current Station Balance',
                    default = '$'..Comma_Value(StationBalance),
                    disabled = true },
                    { type = "number", label = 'Withdraw Amount',
                    },
                })
                if not Withdraw then return end
                WithdrawAmounts = tonumber(Withdraw[2])
                if Withdraw then
                    if Config.FuelDebug then print("Attempting to Withdraw!") end
                    Wait(100)
                    local amount = tonumber(WithdrawAmounts)
                    if not WithdrawAmounts then QBCore.Functions.Notify(Lang:t("station_amount_invalid"), 'error', 7500) return end
                    if amount < 1 then QBCore.Functions.Notify(Lang:t("station_withdraw_too_little"), 'error', 7500) return end
                    if amount > StationBalance then QBCore.Functions.Notify(Lang:t("station_withdraw_too_much"), 'error', 7500) return end
                    WithdrawAmount = tonumber(amount)
                    if (StationBalance - WithdrawAmount) < 0 then
                        QBCore.Functions.Notify(Lang:t("station_withdraw_too_much"), 'error', 7500)
                    else
                        TriggerServerEvent('cdn-fuel:station:server:Withdraw', amount, location, StationBalance)
                    end
                end
            else
                local Withdraw = exports['qb-input']:ShowInput({
                    header = Lang:t("input_withdraw_funds_header") ..StationBalance,
                    submitText = Lang:t("input_withdraw_submit_text"),
                    inputs = { {
                        type = 'number',
                        isRequired = true,
                        name = 'amount',
                        text = Lang:t("input_withdraw_text")
                    }}
                })
                if Withdraw then
                    if Config.FuelDebug then print("Attempting to Withdraw!") end
                    Wait(100)
                    local amount = tonumber(Withdraw.amount)
                    if not Withdraw.amount then QBCore.Functions.Notify(Lang:t("station_amount_invalid"), 'error', 7500) return end
                    if amount < 1 then QBCore.Functions.Notify(Lang:t("station_withdraw_too_little"), 'error', 7500) return end
                    if amount > StationBalance then QBCore.Functions.Notify(Lang:t("station_withdraw_too_much"), 'error', 7500) return end
                    WithdrawAmount = tonumber(amount)
                    if (StationBalance - WithdrawAmount) < 0 then
                        QBCore.Functions.Notify(Lang:t("station_withdraw_too_much"), 'error', 7500)
                    else
                        TriggerServerEvent('cdn-fuel:station:server:Withdraw', amount, location, StationBalance)
                    end
                end
            end
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:DepositFunds', function(data)
        if Config.FuelDebug then print("Triggered Event for: Deposit!") end
        CanOpen = false
        local location = CurrentLocation
        QBCore.Functions.TriggerCallback('cdn-fuel:server:isowner', function(result)
            local CitizenID = QBCore.Functions.GetPlayerData().citizenid
            if result then
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is owned by ID: "..CitizenID) end
                CanOpen = true
            else
                QBCore.Functions.Notify(Lang:t("station_not_owner"), 'error', 7500)
                if Config.FuelDebug then print("The Location: "..CurrentLocation.." is not owned by ID: "..CitizenID) end
                CanOpen = false
            end
        end, CurrentLocation)
        Wait(Config.WaitTime)
        if CanOpen then
            local bankmoney = QBCore.Functions.GetPlayerData().money['bank']
            if Config.FuelDebug then print("Showing Input for Deposit!") end
            UpdateStationInfo("balance")
            Wait(50)
            if Config.Ox.Input then
                local Deposit = lib.inputDialog('Deposit Funds', {
                    { type = "input", label = 'Current Station Balance',
                    default = '$'..Comma_Value(StationBalance),
                    disabled = true },
                    { type = "number", label = 'Deposit Amount',
                    },
                })
                if not Deposit then return end
                DepositAmounts = tonumber(Deposit[2])
                if Deposit then
                    if Config.FuelDebug then print("Attempting to Deposit!") end
                    Wait(100)
                    local amount = tonumber(DepositAmounts)
                    if not DepositAmounts then QBCore.Functions.Notify(Lang:t("station_amount_invalid"), 'error', 7500) return end
                    if amount < 1 then QBCore.Functions.Notify(Lang:t("station_deposit_too_little"), 'error', 7500) return end
                    DepositAmount = tonumber(amount)
                    if (DepositAmount) > bankmoney then
                        QBCore.Functions.Notify(Lang:t("station_deposity_too_much"), "error")
                    else
                        TriggerServerEvent('cdn-fuel:station:server:Deposit', amount, location, StationBalance)
                    end
                end
            else
                local Deposit = exports['qb-input']:ShowInput({
                    header = Lang:t("input_deposit_funds_header") ..StationBalance,
                    submitText = Lang:t("input_deposit_submit_text"),
                    inputs = { {
                        type = 'number',
                        isRequired = true,
                        name = 'amount',
                        text = Lang:t("input_deposit_text")
                    }}
                })
                if Deposit then
                    if Config.FuelDebug then print("Attempting to Deposit!") end
                    Wait(100)
                    local amount = tonumber(Deposit.amount)
                    if not Deposit.amount then QBCore.Functions.Notify(Lang:t("station_amount_invalid"), 'error', 7500) return end
                    if amount < 1 then QBCore.Functions.Notify(Lang:t("station_deposit_too_little"), 'error', 7500) return end
                    DepositAmount = tonumber(amount)
                    if (DepositAmount) > bankmoney then
                        QBCore.Functions.Notify(Lang:t("station_deposity_too_much"), "error")
                    else
                        TriggerServerEvent('cdn-fuel:station:server:Deposit', amount, location, StationBalance)
                    end
                end
            end
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:client:Shutoff', function(location)
        TriggerServerEvent("cdn-fuel:stations:server:Shutoff", location)
    end)

    RegisterNetEvent('cdn-fuel:stations:client:purchasemenu', function(location) -- Menu, seen after selecting the purchase this location option.
        local PlayerData = QBCore.Functions.GetPlayerData()
        local jobName = PlayerData.job and PlayerData.job.name
        local jobGrade = PlayerData.job and PlayerData.job.grade and tonumber(PlayerData.job.grade.level or PlayerData.job.grade) or 0

        if jobName ~= "cayxang" or jobGrade < 2 then
            QBCore.Functions.Notify("Bạn cần có công việc Doanh Nghiệp Cây Xăng (Cấp bậc >= 2) mới có thể mua cây xăng!", "error", 7500)
            return
        end

        local bankmoney = PlayerData.money['bank']
        local costofstation = Config.GasStations[location].cost + GlobalTax(Config.GasStations[location].cost)

        if Config.OneStationPerPerson == true then
            QBCore.Functions.TriggerCallback('cdn-fuel:server:doesPlayerOwnStation', function(result)
                if result then
                    if Config.FuelDebug then print("Player already owns a station, so disallowing purchase.") end
                    PlayerOwnsAStation = true
                else
                    if Config.FuelDebug then print("Player doesn't own a station, so continuing purchase checks.") end
                    PlayerOwnsAStation = false
                end
            end)

            Wait(Config.WaitTime)

            if PlayerOwnsAStation == true then
                QBCore.Functions.Notify('You can only buy one station, and you already own one!', 'error')
                return
            end
        end


        if bankmoney < costofstation then
            QBCore.Functions.Notify(Lang:t("not_enough_money_in_bank").." $"..costofstation, 'error', 7500) return
        end

        if Config.Ox.Menu then
            lib.registerContext({
                id = 'purchasemenu',
                title = Config.GasStations[location].label,
                options = {
                    {
                        title = Lang:t("menu_purchase_station_confirm_header"),
                        description = 'I am interested in purchasing this station!',
                        icon = "fas fa-usd",
                        arrow = true, -- puts arrow to the right
                        event = 'cdn-fuel:stations:client:purchaselocation',
                        args = {
                            location = location,
                        },
                        metadata = {
                            {label = 'Station Cost: $', value = Comma_Value(costofstation)..Lang:t("menu_purchase_station_header_2")},
                        },
                    },
                    {
                        title = Lang:t("menu_header_close"),
                        description = Lang:t("menu_refuel_cancel"),
                        icon = "fas fa-times-circle",
                        arrow = false, -- puts arrow to the right
                        onSelect = function()
                            lib.hideContext()
                          end,
                    },
                },
            })
            lib.showContext('purchasemenu')
        else
            exports['qb-menu']:openMenu({
                {
                    header = Config.GasStations[location].label,
                    isMenuHeader = true,
                    icon = "fas fa-gas-pump",
                },
                {
                    header = "",
                    icon = "fas fa-info-circle",
                    isMenuHeader = true,
                    txt = Lang:t("menu_purchase_station_header_1")..costofstation..Lang:t("menu_purchase_station_header_2"),
                },
                {
                    header = Lang:t("menu_purchase_station_confirm_header"),
                    icon = "fas fa-check-circle",
                    txt = Lang:t("menu_purchase_station_confirm_footer")..costofstation..'!' ,
                    params = {
                        event = "cdn-fuel:stations:client:purchaselocation",
                        args = {
                            location = location,
                        }
                    }
                },
                {
                    header = Lang:t("menu_header_close"),
                    txt = Lang:t("menu_purchase_station_cancel_footer"),
                    icon = "fas fa-times-circle",
                    params = {
                        event = "qb-menu:closeMenu",
                    }
                },
            })
        end
    end)

    RegisterNetEvent('cdn-fuel:stations:openmenu', function(data) -- Menu #1, the first menu you see.
        local loc = nil
        if type(data) == 'table' then
            loc = data.location or data.args
        elseif type(data) == 'number' then
            loc = data
        end

        if not loc or loc <= 0 then
            loc = GetLocation() or CurrentLocation
        end

        if not loc or loc <= 0 or not Config.GasStations[loc] then
            if Config.FuelDebug then print("openmenu: Invalid location!") end
            return
        end

        CurrentLocation = loc
        DisablePurchase = true
        DisableOwnerMenu = true
        ShutOffDisabled = false

        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name == 'cayxang' then
            DisableOwnerMenu = false
        else
            DisableOwnerMenu = true
        end

        if Config.EmergencyShutOff then
            QBCore.Functions.TriggerCallback('cdn-fuel:server:checkshutoff', function(result)
                if result == true then
                    PumpState = "disabled."
                elseif result == false then
                    PumpState = "enabled."
                else
                    PumpState = "nil"
                end

                if Config.FuelDebug then print("The result from Callback: Config.GasStations["..CurrentLocation.."].shutoff = "..PumpState) end
            end, CurrentLocation)
        else
            PumpState = "enabled."
            ShutOffDisabled = true
        end

        Wait(Config.WaitTime)

        if not CurrentLocation or not Config.GasStations[CurrentLocation] then return end
        local stationConfig = Config.GasStations[CurrentLocation]
        local StationCost = (stationConfig.cost or 0) + GlobalTax(stationConfig.cost or 0)
        local PriceDesc = "Giá mua: $" .. Comma_Value(StationCost)

        if Config.Ox.Menu then
            lib.registerContext({
                id = 'stationmainmenu',
                title = Config.GasStations[CurrentLocation].label,
                options = {
                    {
                        title = Lang:t("menu_ped_manage_location_header"),
                        description = Lang:t("menu_ped_manage_location_footer"),
                        icon = "fas fa-gas-pump",
                        arrow = false, -- puts arrow to the right
                        event = 'cdn-fuel:stations:client:managemenu',
                        args = CurrentLocation,
                        disabled = DisableOwnerMenu,
                    },
                    {
                        title = Lang:t("menu_ped_purchase_location_header"),
                        description = PriceDesc,
                        icon = "fas fa-usd",
                        arrow = false, -- puts arrow to the right
                        event = 'cdn-fuel:stations:client:purchasemenu',
                        args = CurrentLocation,
                        disabled = DisablePurchase,
                    },
                    {
                        title = Lang:t("menu_ped_emergency_shutoff_header"),
                        description = Lang:t("menu_ped_emergency_shutoff_footer")..PumpState,
                        icon = "fas fa-gas-pump",
                        arrow = false, -- puts arrow to the right
                        event = 'cdn-fuel:stations:client:Shutoff',
                        args = CurrentLocation,
                        disabled = ShutOffDisabled,
                    },
                    {
                        title = Lang:t("menu_header_close"),
                        description = Lang:t("menu_refuel_cancel"),
                        icon = "fas fa-times-circle",
                        arrow = false, -- puts arrow to the right
                        onSelect = function()
                            lib.hideContext()
                          end,
                    },
                },
            })
            lib.showContext('stationmainmenu')
        else
            exports['qb-menu']:openMenu({
                {
                    header = Config.GasStations[CurrentLocation].label,
                    isMenuHeader = true,
                    icon = "fas fa-gas-pump",
                },
                {
                    header = Lang:t("menu_ped_manage_location_header"),
                    txt = Lang:t("menu_ped_manage_location_footer"),
                    icon = "fas fa-usd",
                    params = {
                        event = "cdn-fuel:stations:client:managemenu",
                        args = CurrentLocation,
                    },
                    disabled = DisableOwnerMenu,
                },
                {
                    header = Lang:t("menu_ped_purchase_location_header"),
                    txt = PriceDesc,
                    icon = "fas fa-usd",
                    params = {
                        event = "cdn-fuel:stations:client:purchasemenu",
                        args = CurrentLocation,
                    },
                    disabled = DisablePurchase,
                },
                {
                    header = Lang:t("menu_ped_emergency_shutoff_header"),
                    txt = Lang:t("menu_ped_emergency_shutoff_footer")..PumpState,
                    icon = "fas fa-gas-pump",
                    params = {
                        event = "cdn-fuel:stations:client:Shutoff",
                        args = CurrentLocation,
                    },
                    disabled = ShutOffDisabled,
                },
                {
                    header = Lang:t("menu_ped_close_header"),
                    txt = Lang:t("menu_ped_close_footer"),
                    icon = "fas fa-times-circle",
                    params = {
                        event = "qb-menu:closeMenu",
                    }
                },
            })
        end
    end)

    RegisterNetEvent('cdn-fuel:client:sellJerryCanDialog', function(entity)
        local targetPed = entity
        if not targetPed or not DoesEntityExist(targetPed) then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer(coords)
            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                targetPed = GetPlayerPed(closestPlayer)
            end
        end

        if not targetPed or not DoesEntityExist(targetPed) then
            QBCore.Functions.Notify("Không tìm thấy người chơi ở gần!", "error", 7500)
            return
        end

        local targetPlayerIndex = NetworkGetPlayerIndexFromPed(targetPed)
        if not targetPlayerIndex or targetPlayerIndex == -1 then
            QBCore.Functions.Notify("Không tìm thấy người chơi!", "error", 7500)
            return
        end

        local targetServerId = GetPlayerServerId(targetPlayerIndex)
        if not targetServerId or targetServerId <= 0 then
            QBCore.Functions.Notify("Không thể xác định người chơi!", "error", 7500)
            return
        end

        local location = GetLocation()
        local pricePerLiter = Config.JerryCanPricePerLiter or 25

        if Config.Ox.Menu or GetResourceState('ox_lib') == 'started' then
            local input = lib.inputDialog('BÁN CAN XĂNG CHO NGƯỜI CHƠI', {
                {
                    type = 'number',
                    label = 'Dung tích / Lượng xăng (Lít)',
                    description = 'Nhập số lít (1L - 100L). Giá bán tự động: $' .. pricePerLiter .. '/Lít.',
                    default = 25,
                    min = 1,
                    max = 100,
                    required = true
                }
            })

            if not input then return end

            local amount = tonumber(input[1])
            if not amount or amount < 1 or amount > 100 then
                QBCore.Functions.Notify("Số lượng xăng nhập vào không hợp lệ!", "error", 7500)
                return
            end

            TriggerServerEvent('cdn-fuel:server:sellJerryCanToPlayer', targetServerId, amount, location)
        else
            local dialog = exports['qb-input']:ShowInput({
                header = "BÁN CAN XĂNG CHO NGƯỜI CHƠI",
                submitText = "Bán Can Xăng",
                inputs = {
                    {
                        text = "Lượng xăng (1L - 100L) - Giá tự động: $" .. pricePerLiter .. "/L",
                        name = "amount",
                        type = "number",
                        isRequired = true,
                        default = "25"
                    }
                }
            })

            if not dialog then return end

            local amount = tonumber(dialog.amount)
            if not amount or amount < 1 or amount > 100 then
                QBCore.Functions.Notify("Số lượng xăng nhập vào không hợp lệ!", "error", 7500)
                return
            end

            TriggerServerEvent('cdn-fuel:server:sellJerryCanToPlayer', targetServerId, amount, location)
        end
    end)

    RegisterNetEvent('cdn-fuel:client:confirmJerryCanPurchase', function(sellerSrc, sellerName, amount, cost, location)
        if Config.Ox.Menu or GetResourceState('ox_lib') == 'started' then
            local alert = lib.alertDialog({
                header = 'ĐỀ NGHỊ MUA CAN XĂNG',
                content = string.format("### ĐỀ NGHỊ MUA CAN XĂNG\n- **Nhân viên bán:** %s\n- **Dung tích:** %d Lít\n- **Tổng tiền:** $%d ($25/Lít)\n\n*Bạn có đồng ý mua Can Xăng này không?*",
                    tostring(sellerName), tonumber(amount), tonumber(cost)),
                centered = true,
                cancel = true,
                labels = {
                    confirm = 'Xác nhận mua ($' .. cost .. ')',
                    cancel = 'Từ chối'
                }
            })

            if alert == 'confirm' then
                TriggerServerEvent('cdn-fuel:server:confirmSellJerryCan', sellerSrc, amount, cost, location)
            else
                TriggerServerEvent('cdn-fuel:server:rejectSellJerryCan', sellerSrc)
            end
        else
            exports['qb-menu']:openMenu({
                {
                    header = "ĐỀ NGHỊ MUA CAN XĂNG",
                    isMenuHeader = true,
                    icon = "fas fa-gas-pump"
                },
                {
                    header = "Nhân viên: " .. sellerName,
                    txt = "Dung tích: " .. amount .. "L | Tổng tiền: $" .. cost,
                    isMenuHeader = true,
                    icon = "fas fa-info-circle"
                },
                {
                    header = "Xác nhận mua ($" .. cost .. ")",
                    icon = "fas fa-check-circle",
                    params = {
                        isAction = true,
                        action = function()
                            TriggerServerEvent('cdn-fuel:server:confirmSellJerryCan', sellerSrc, amount, cost, location)
                        end
                    }
                },
                {
                    header = "Từ chối",
                    icon = "fas fa-times-circle",
                    params = {
                        isAction = true,
                        action = function()
                            TriggerServerEvent('cdn-fuel:server:rejectSellJerryCan', sellerSrc)
                        end
                    }
                }
            })
        end
    end)

    -- Threads
    CreateThread(function() -- Spawn the Peds for Gas Stations when the resource starts.
        SpawnGasStationPeds()

        Wait(2000)
        if GetResourceState('ox_target') == 'started' or Config.TargetResource == 'ox_target' then
            exports.ox_target:addGlobalPlayer({
                {
                    name = 'cdn-fuel:selljerrycan',
                    icon = 'fas fa-gas-pump',
                    label = 'Bán Can Xăng',
                    groups = 'cayxang',
                    distance = 2.5,
                    onSelect = function(data)
                        TriggerEvent('cdn-fuel:client:sellJerryCanDialog', data.entity)
                    end,
                    canInteract = function(entity, distance, coords, name, bone)
                        local PlayerData = QBCore.Functions.GetPlayerData()
                        return PlayerData and PlayerData.job and PlayerData.job.name == 'cayxang'
                    end
                }
            })
        end
        if GetResourceState('qb-target') == 'started' or Config.TargetResource == 'qb-target' then
            exports['qb-target']:AddGlobalPlayer({
                options = {
                    {
                        type = 'client',
                        icon = 'fas fa-gas-pump',
                        label = 'Bán Can Xăng',
                        job = 'cayxang',
                        action = function(entity)
                            TriggerEvent('cdn-fuel:client:sellJerryCanDialog', entity)
                        end
                    }
                },
                distance = 2.5
            })
        end
    end)

    local ActiveElectricDelivery = nil

    local function SpawnElectricDeliveryVehicle(coords)
        local modelHash = `benson`
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 100 do
            Wait(50)
            timeout = timeout + 1
        end
        if not HasModelLoaded(modelHash) then
            return nil
        end

        local veh = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        SetModelAsNoLongerNeeded(modelHash)

        local plate = "ELEC" .. tostring(math.random(1000, 9999))
        SetVehicleNumberPlateText(veh, plate)

        GiveVehicleKeys(veh)

        return veh
    end

    RegisterNetEvent('cdn-fuel:client:startElectricDelivery', function(data)
        if not data or not data.location or not data.amount then return end

        if ActiveElectricDelivery then
            QBCore.Functions.Notify("Bạn đang có một chuyến xe chở điện chưa hoàn thành!", "error", 7500)
            return
        end

        local spawnCoords = vector4(2112.9500, 1939.8751, 93.5844, 359.8942)
        
        -- KHÔNG spawn xe ngay lập tức, chỉ tạo điểm marker
        local pickupBlip = AddBlipForCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
        SetBlipSprite(pickupBlip, 477)
        SetBlipColour(pickupBlip, 3)
        SetBlipScale(pickupBlip, 0.85)
        SetBlipRoute(pickupBlip, true)
        SetBlipRouteColour(pickupBlip, 3)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Xe Benson Chở Điện")
        EndTextCommandSetBlipName(pickupBlip)

        SetNewWaypoint(spawnCoords.x, spawnCoords.y)
        QBCore.Functions.Notify("Đơn hàng điện đã sẵn sàng! Hãy đến điểm lấy xe và bấm [E] để nhận xe Benson.", "success", 7500)

        ActiveElectricDelivery = {
            location = data.location,
            amount = data.amount,
            vehicle = nil, -- Xe chưa spawn
            pickupBlip = pickupBlip,
            stationBlip = nil,
            stage = 'waiting_spawn', -- Trạng thái mới: đang chờ player đến spawn xe
            spawnCoords = spawnCoords
        }

        CreateThread(function()
            while ActiveElectricDelivery and ActiveElectricDelivery.stage ~= 'finished' do
                local sleep = 1000

                if not ActiveElectricDelivery then break end

                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)

                -- BƯỚC 1: Chờ player đến điểm và bấm E để spawn xe
                if ActiveElectricDelivery.stage == 'waiting_spawn' then
                    local dist = #(pedCoords - vector3(ActiveElectricDelivery.spawnCoords.x, ActiveElectricDelivery.spawnCoords.y, ActiveElectricDelivery.spawnCoords.z))
                    
                    if dist <= 10.0 then
                        sleep = 0
                        -- Hiển thị text hướng dẫn
                        if Config.Ox.DrawText then
                            lib.showTextUI('[E] - Lấy xe Benson chở điện', {
                                position = 'left-center'
                            })
                        else
                            exports[Config.Core]:DrawText('[E] - Lấy xe Benson chở điện', 'left')
                        end
                        
                        if IsControlJustReleased(0, 38) then -- E key
                            -- Ẩn text
                            if Config.Ox.DrawText then
                                lib.hideTextUI()
                            else
                                exports[Config.Core]:HideText()
                            end
                            
                            -- Kiểm tra vị trí spawn có clear không
                            if not IsSpawnPointClear(ActiveElectricDelivery.spawnCoords, 4.5) then
                                QBCore.Functions.Notify("Vị trí nhập điện (2112.95, 1939.87) đang có xe khác dừng đỗ! Vui lòng dọn dẹp trước.", "error", 7500)
                            else
                                -- Spawn xe
                                local veh = SpawnElectricDeliveryVehicle(ActiveElectricDelivery.spawnCoords)
                                
                                if veh and DoesEntityExist(veh) then
                                    ActiveElectricDelivery.vehicle = veh
                                    
                                    -- Đưa player vào xe
                                    Wait(500)
                                    TaskWarpPedIntoVehicle(ped, veh, -1)
                                    
                                    -- Chuyển sang stage pickup (đã có xe, đang lái về trạm)
                                    ActiveElectricDelivery.stage = 'pickup'
                                    
                                    if ActiveElectricDelivery.pickupBlip then
                                        RemoveBlip(ActiveElectricDelivery.pickupBlip)
                                        ActiveElectricDelivery.pickupBlip = nil
                                    end
                                    
                                    -- Tạo blip về trạm
                                    local stData = Config.GasStations[ActiveElectricDelivery.location]
                                    local targetPos
                                    if stData then
                                        if stData.pedcoords then
                                            targetPos = vector3(stData.pedcoords.x, stData.pedcoords.y, stData.pedcoords.z)
                                        elseif stData.coords then
                                            targetPos = vector3(stData.coords.x, stData.coords.y, stData.coords.z)
                                        end
                                    end
                                    
                                    if targetPos then
                                        ActiveElectricDelivery.stationBlip = AddBlipForCoord(targetPos.x, targetPos.y, targetPos.z)
                                        SetBlipSprite(ActiveElectricDelivery.stationBlip, 361)
                                        SetBlipColour(ActiveElectricDelivery.stationBlip, 3)
                                        SetBlipScale(ActiveElectricDelivery.stationBlip, 0.9)
                                        SetBlipRoute(ActiveElectricDelivery.stationBlip, true)
                                        SetBlipRouteColour(ActiveElectricDelivery.stationBlip, 3)
                                        BeginTextCommandSetBlipName("STRING")
                                        AddTextComponentString("Điểm Nạp Điện Trạm Xăng")
                                        EndTextCommandSetBlipName(ActiveElectricDelivery.stationBlip)
                                        
                                        SetNewWaypoint(targetPos.x, targetPos.y)
                                        QBCore.Functions.Notify("Đã nhận xe Benson! Hãy lái về " .. Config.GasStations[ActiveElectricDelivery.location].label .. " để nạp điện.", "success", 7500)
                                    end
                                else
                                    QBCore.Functions.Notify("Không thể tạo xe Benson! Vui lòng thử lại.", "error", 7500)
                                end
                            end
                        end
                    else
                        -- Ẩn text khi player ra xa
                        if Config.Ox.DrawText then
                            lib.hideTextUI()
                        else
                            exports[Config.Core]:HideText()
                        end
                        sleep = (dist < 30.0) and 500 or 1500
                    end
                    
                -- BƯỚC 2: Đang lái xe về trạm - Kiểm tra khi player đến gần trạm
                elseif ActiveElectricDelivery.stage == 'pickup' then
                    sleep = 1000
                    if ActiveElectricDelivery.vehicle and DoesEntityExist(ActiveElectricDelivery.vehicle) then
                        local stData = Config.GasStations[ActiveElectricDelivery.location]
                        local targetPos
                        if stData then
                            if stData.pedcoords then
                                targetPos = vector3(stData.pedcoords.x, stData.pedcoords.y, stData.pedcoords.z)
                            elseif stData.coords then
                                targetPos = vector3(stData.coords.x, stData.coords.y, stData.coords.z)
                            end
                        end
                        
                        if targetPos then
                            local vehCoords = GetEntityCoords(ActiveElectricDelivery.vehicle)
                            local dist = #(vehCoords - targetPos)
                            
                            if dist <= 20.0 then
                                -- Đến gần trạm, chuyển sang stage deliver
                                ActiveElectricDelivery.stage = 'deliver'
                                sleep = 0
                            else
                                sleep = (dist < 100.0) and 500 or 1500
                            end
                        end
                    end
                    
                -- BƯỚC 3: Đã đến trạm, chờ bấm E để nạp điện
                elseif ActiveElectricDelivery.stage == 'deliver' then
                    local stData = Config.GasStations[ActiveElectricDelivery.location]
                    local targetPos
                    if stData then
                        if stData.pedcoords then
                            targetPos = vector3(stData.pedcoords.x, stData.pedcoords.y, stData.pedcoords.z)
                        elseif stData.coords then
                            targetPos = vector3(stData.coords.x, stData.coords.y, stData.coords.z)
                        end
                    end

                    if targetPos and ActiveElectricDelivery.vehicle and DoesEntityExist(ActiveElectricDelivery.vehicle) then
                        local vehCoords = GetEntityCoords(ActiveElectricDelivery.vehicle)
                        local dist = #(vehCoords - targetPos)

                        if dist <= 15.0 then
                            sleep = 0
                            -- Hiển thị text hướng dẫn
                            if Config.Ox.DrawText then
                                lib.showTextUI('[E] - Nạp điện vào trạm sạc', { position = 'left-center' })
                            else
                                exports[Config.Core]:DrawText('[E] - Nạp điện vào trạm sạc', 'left')
                            end
                            
                            if IsControlJustReleased(0, 38) then -- Key E
                                -- Ẩn text
                                if Config.Ox.DrawText then
                                    lib.hideTextUI()
                                else
                                    exports[Config.Core]:HideText()
                                end

                                QBCore.Functions.Progressbar("deposit_electric_kw", "Đang nạp điện vào kho dự trữ trạm...", 5000, false, true, {
                                    disableMovement = true,
                                    disableCarMovement = true,
                                    disableMouse = false,
                                    disableCombat = true,
                                }, {}, {}, {}, function()
                                    local curPed = PlayerPedId()
                                    if IsPedInAnyVehicle(curPed, false) then
                                        TaskLeaveVehicle(curPed, ActiveElectricDelivery.vehicle, 0)
                                        Wait(1500)
                                    end

                                    if DoesEntityExist(ActiveElectricDelivery.vehicle) then
                                        DeleteEntity(ActiveElectricDelivery.vehicle)
                                    end

                                    if ActiveElectricDelivery.stationBlip then
                                        RemoveBlip(ActiveElectricDelivery.stationBlip)
                                    end

                                    TriggerServerEvent('cdn-fuel:stations:server:finishElectricDelivery', ActiveElectricDelivery.location, ActiveElectricDelivery.amount)

                                    ActiveElectricDelivery.stage = 'finished'
                                    ActiveElectricDelivery = nil
                                end)
                            end
                        else
                            -- Ẩn text khi ra xa trạm
                            if Config.Ox.DrawText then
                                lib.hideTextUI()
                            else
                                exports[Config.Core]:HideText()
                            end
                            sleep = (dist < 50.0) and 500 or 1500
                        end
                    end
                end

                Wait(sleep)
            end
        end)
    end)
end -- For Config.PlayerOwnedGasStationsEnabled check, don't remove!