-- NUI Client Handler
-- Xử lý mở/đóng NUI và giao tiếp với server cho hệ thống Multi-Dealer

local currentDealerContext = 'cardealer'

-- Hàm mở NUI
function OpenVehicleManagementUI(dealerId)
    local isDealerEmployee = false
    local grade = (QBX and QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.grade and QBX.PlayerData.job.grade.level) or 0
    local activeDealer = dealerId or 'cardealer'
    
    local isMod = lib.callback.await('1307_Cardealer:server:CheckModPerm', false) or false
    
    local playerJob = QBX and QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.name
    local jobDealerId = GetDealerByJob(playerJob)
    if jobDealerId then
        isDealerEmployee = true
        activeDealer = jobDealerId
    else
        isDealerEmployee = false
        if dealerId then activeDealer = dealerId end
    end
    
    currentDealerContext = activeDealer
    
    local dealersList = {}
    for dId, dCfg in pairs(Config.Dealers) do
        table.insert(dealersList, {
            id = dId,
            label = dCfg.label or dId
        })
    end
    table.sort(dealersList, function(a, b) return a.id < b.id end)
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        isCardealer = isDealerEmployee,
        grade = grade,
        isMod = isMod,
        dealerId = activeDealer,
        dealers = dealersList
    })
end

-- Event để mở NUI (public access)
RegisterNetEvent('1307_Cardealer:cl:OpenPublicUI', function(dealerId)
    OpenVehicleManagementUI(dealerId)
end)

-- Event để mở NUI quản lý của nhân viên
RegisterNetEvent('1307_Cardealer:cl:OpenManagementUI', function(dealerId)
    OpenVehicleManagementUI(dealerId)
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getDealers', function(data, cb)
    local dealersList = {}
    for dId, dCfg in pairs(Config.Dealers) do
        table.insert(dealersList, {
            id = dId,
            label = dCfg.label or dId
        })
    end
    table.sort(dealersList, function(a, b) return a.id < b.id end)
    cb({ dealers = dealersList })
end)

-- ── PURCHASE DIALOG CALLBACKS ────────────────────────────────────────────────

RegisterNUICallback('getCoupons', function(data, cb)
    local coupons = lib.callback.await('1307_Cardealer:cb:GetPlayerCoupons', false)
    cb({ coupons = coupons or {} })
end)

RegisterNUICallback('confirmPurchase', function(data, cb)
    if _pendingPurchase then
        TriggerServerEvent(
            "1307_Cardealer:server:ConfirmPurchase",
            _pendingPurchase.vehModel,
            _pendingPurchase.vehPrice,
            _pendingPurchase.sellerId,
            data.couponItem or nil,
            _pendingPurchase.dealerId or 'cardealer'
        )
    end
    SetNuiFocus(false, false)
    _pendingPurchase = nil
    cb('ok')
end)

RegisterNUICallback('declinePurchase', function(data, cb)
    if _pendingPurchase then
        exports.qbx_core:Notify('Bạn đã từ chối mua xe', 'error')
        TriggerServerEvent('1307_Cardealer:server:DeclinePurchase', _pendingPurchase.sellerId)
    end
    SetNuiFocus(false, false)
    _pendingPurchase = nil
    cb('ok')
end)

-- ────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('getVehicles', function(data, cb)
    local targetDealer = (data and data.dealerId) or currentDealerContext
    local vehicles = lib.callback.await("1307_Cardealer:server:GetData", false, targetDealer)
    cb({
        vehicles = vehicles or {}
    })
end)

RegisterNUICallback('getCategories', function(data, cb)
    local targetDealer = (data and data.dealerId) or currentDealerContext
    local categories = lib.callback.await("1307_Cardealer:server:GetCategories", false, targetDealer)
    cb({
        categories = categories or {}
    })
end)

RegisterNUICallback('getQBXVehicles', function(data, cb)
    local qbxVehicles = exports.qbx_core:GetVehiclesByName()
    local vehicleList = {}
    
    local oxInventoryTrunkData = nil
    local oxSuccess, oxData = pcall(function()
        local vehiclesFile = LoadResourceFile('ox_inventory', 'data/vehicles.lua')
        if vehiclesFile then
            local func = load(vehiclesFile)
            if func then
                return func()
            end
        end
        return nil
    end)
    
    if oxSuccess and oxData then
        oxInventoryTrunkData = oxData
    end
    
    for model, vData in pairs(qbxVehicles) do
        local trunkSlots = nil
        local trunkWeight = nil
        
        local vehicleType = vData.type or 'automobile'
        local vehicleCategory = vData.category or ''
        local vehicleClass = vData.class or 0
        local isMotorcycleOrBike = (vehicleType == 'bike' or vehicleType == 'bicycle' or vehicleCategory == 'motorcycles')
        
        if not isMotorcycleOrBike and oxInventoryTrunkData and oxInventoryTrunkData.trunk then
            local modelHash = GetHashKey(model)
            local foundData = false
            
            if oxInventoryTrunkData.trunk.models then
                for hash, trunkData in pairs(oxInventoryTrunkData.trunk.models) do
                    if hash == modelHash and type(trunkData) == "table" then
                        local slots = trunkData[1]
                        local weight = trunkData[2]
                        if slots and slots > 0 then
                            trunkSlots = slots
                            trunkWeight = weight and (weight / 1000) or nil
                        end
                        foundData = true
                        break
                    end
                end
            end
            
            if not foundData then
                if oxInventoryTrunkData.trunk[vehicleClass] and type(oxInventoryTrunkData.trunk[vehicleClass]) == "table" then
                    local trunkData = oxInventoryTrunkData.trunk[vehicleClass]
                    local slots = trunkData[1]
                    local weight = trunkData[2]
                    if slots and slots > 0 then
                        trunkSlots = slots
                        trunkWeight = weight and (weight / 1000) or nil
                    end
                end
            end
        end
        
        table.insert(vehicleList, {
            model = model,
            name = vData.name,
            brand = vData.brand,
            category = vData.category,
            type = vData.type or 'automobile',
            trunkSlots = trunkSlots,
            trunkWeight = trunkWeight
        })
    end
    
    cb({
        vehicles = vehicleList
    })
end)

RegisterNUICallback('testDriveVehicle', function(data, cb)
    local model = data.model
    local name = data.name
    local targetDealer = (data and data.dealerId) or currentDealerContext
    local dealerCfg = GetDealerById(targetDealer) or Config.Dealers['cardealer']
    
    cb({ success = true })
    
    CreateThread(function()
        local testSpawn = dealerCfg.locations and dealerCfg.locations.testSpawn or vector4(516.80, -268.61, 46.54, 144.04)
        local testBack = dealerCfg.locations and dealerCfg.locations.testBack or vector4(-791.64, -223.19, 37.24, 0.0)
        local PlayerPed = PlayerPedId()
        local TestPlate = "XETEST"..math.random(10, 99)
        
        exports.qbx_core:Notify("Đang spawn xe " .. name .. " để lái thử...", "info")
        
        DoScreenFadeOut(500)
        Wait(500)
        
        SetEntityCoords(PlayerPed, testSpawn.x, testSpawn.y, testSpawn.z, false, false, false, true)
        SetEntityHeading(PlayerPed, testSpawn.w)
        
        Wait(500)
        DoScreenFadeIn(500)
        
        local success, netid, veh, bucket = pcall(function()
            return lib.callback.await('1307_Cardealer:server:spawnTestDriveVehicle', false, model, testSpawn, TestPlate)
        end)
        
        if not success or not netid then
            exports.qbx_core:Notify("Lỗi spawn xe lái thử!", "error")
            TriggerServerEvent('1307_Cardealer:server:ResetBucket')
            return
        end
        
        local Vehicle = NetworkGetEntityFromNetworkId(netid)
        local timeout = 0
        while not DoesEntityExist(Vehicle) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        
        if not DoesEntityExist(Vehicle) then
            exports.qbx_core:Notify("Không thể kết nối với xe lái thử!", "error")
            TriggerServerEvent('1307_Cardealer:server:ResetBucket')
            return
        end
        
        SetVehicleFuelLevel(Vehicle, 100.0)
        SetVehicleNumberPlateText(Vehicle, TestPlate)
        SetEntityAsMissionEntity(Vehicle, true, true)
        SetVehicleEngineOn(Vehicle, true, true, false)
        SetVehicleDoorsLocked(Vehicle, 1)
        FreezeEntityPosition(Vehicle, false)
        
        Wait(500)
        TaskWarpPedIntoVehicle(PlayerPed, Vehicle, -1)
        Wait(1000)
        
        exports['Renewed-Vehiclekeys']:addKey(TestPlate)
        Wait(200)
        
        exports.qbx_core:Notify("Bạn được lái thử xe " .. name .. " trong 60 giây", "success")
        
        local InTestDrive = true
        local TimeTestDrive = GetGameTimer()
        local TestDriveTime = Config.TestDriveTimer or 60000
        
        CreateThread(function()
            while InTestDrive and (GetGameTimer() - TimeTestDrive) < TestDriveTime do 
                local remainingTime = math.ceil((TestDriveTime - (GetGameTimer() - TimeTestDrive)) / 1000)
                
                SetTextFont(4)
                SetTextProportional(1)
                SetTextScale(0.5, 0.5)
                SetTextColour(16, 185, 129, 255)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextDropShadow()
                SetTextOutline()
                SetTextCentre(1)
                SetTextEntry("STRING")
                AddTextComponentString("~g~LÁI THỬ XE: ~w~" .. name .. "\n~y~Thời gian còn lại: ~w~" .. remainingTime .. " giây\n~o~Nhấn ~r~[E]~o~ để kết thúc sớm\n~b~[Khu vực riêng]")
                DrawText(0.5, 0.85)
                
                if IsControlJustReleased(0, 38) then
                    InTestDrive = false
                end
                Wait(0)
            end 
            
            DoScreenFadeOut(500)
            Wait(500)
            
            exports['Renewed-Vehiclekeys']:removeKey(TestPlate)
            
            if DoesEntityExist(Vehicle) then
                local ped = PlayerPedId()
                if IsPedInVehicle(ped, Vehicle, false) then
                    TaskLeaveVehicle(ped, Vehicle, 16)
                    Wait(1000)
                end
                SetEntityAsMissionEntity(Vehicle, true, true)
                SetEntityAsNoLongerNeeded(Vehicle)
                DeleteEntity(Vehicle)
                DeleteVehicle(Vehicle)
            end
            
            TriggerServerEvent('1307_Cardealer:server:ResetBucket')
            Wait(500)
            
            local playerPed = PlayerPedId()
            SetEntityCoords(playerPed, testBack.x, testBack.y, testBack.z, false, false, false, true)
            SetEntityHeading(playerPed, testBack.w or 0.0)
            
            Wait(500)
            DoScreenFadeIn(500)
            exports.qbx_core:Notify("Đã hết thời gian lái thử - Đã trở về khu vực chung", "info")
        end)
    end)
end)

RegisterNUICallback('addVehicle', function(data, cb)
    data.dealerId = data.dealerId or currentDealerContext
    local result = lib.callback.await('1307_Cardealer:server:AddVehicle', false, data)
    if result and result.message then
        exports.qbx_core:Notify(result.message, result.success and 'success' or 'error')
    end
    cb(result or { success = false })
end)

RegisterNUICallback('updateVehicle', function(data, cb)
    data.dealerId = data.dealerId or currentDealerContext
    local result = lib.callback.await('1307_Cardealer:server:UpdateVehicle', false, data)
    if result and result.message then
        exports.qbx_core:Notify(result.message, result.success and 'success' or 'error')
    end
    cb(result or { success = false })
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    local result = lib.callback.await('1307_Cardealer:server:DeleteVehicle', false, data.id)
    if result and result.message then
        exports.qbx_core:Notify(result.message, result.success and 'success' or 'error')
    end
    cb(result or { success = false })
end)

RegisterNUICallback('renameCategory', function(data, cb)
    local targetDealer = (data and data.dealerId) or currentDealerContext
    local result = lib.callback.await('1307_Cardealer:server:RenameCategory', false, data.oldName, data.newName, targetDealer)
    if result and result.message then
        exports.qbx_core:Notify(result.message, result.success and 'success' or 'error')
    end
    cb(result or { success = false })
end)

RegisterNUICallback('getSalesHistory', function(data, cb)
    local page = data.page or 1
    local limit = data.limit or 10
    local search = data.search or ''
    local targetDealer = (data and data.dealerId) or currentDealerContext
    local result = lib.callback.await('1307_Cardealer:server:GetSalesHistory', false, page, limit, search, targetDealer)
    cb(result or { success = false, data = {}, hasMore = false })
end)

RegisterNUICallback('getShowroomPositions', function(data, cb)
    local targetDealer = (data and data.dealerId) or currentDealerContext
    local dealerCfg = GetDealerById(targetDealer) or Config.Dealers['cardealer']
    local positions = {}
    
    if dealerCfg and dealerCfg.showroomLocations then
        for k, v in pairs(dealerCfg.showroomLocations) do
            local coords = vector3(v.x, v.y, v.z)
            local vehiclesInArea = GetVehiclesInArea(coords, 1.5)
            local hasVehicle = false
            local vehicleModel = nil
            
            if #vehiclesInArea > 0 then
                for _, veh in ipairs(vehiclesInArea) do
                    if DoesEntityExist(veh) then
                        hasVehicle = true
                        vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                        break
                    end
                end
            end
            
            table.insert(positions, {
                id = k,
                coords = v,
                hasVehicle = hasVehicle,
                vehicleModel = vehicleModel
            })
        end
    end
    
    cb({
        positions = positions
    })
end)

RegisterNUICallback('spawnShowroom', function(data, cb)
    local model = data.vehicle
    local positionId = data.position
    local targetDealer = (data and data.dealerId) or currentDealerContext
    local dealerCfg = GetDealerById(targetDealer) or Config.Dealers['cardealer']
    
    if not dealerCfg.showroomLocations or not dealerCfg.showroomLocations[positionId] then
        cb({ success = false, message = "Vị trí không hợp lệ" })
        return
    end
    
    local coords = vector3(dealerCfg.showroomLocations[positionId].x, dealerCfg.showroomLocations[positionId].y, dealerCfg.showroomLocations[positionId].z)
    local vehiclesInArea = GetVehiclesInArea(coords, 1.5)
    
    if #vehiclesInArea > 0 then
        for _, veh in ipairs(vehiclesInArea) do
            if DoesEntityExist(veh) then
                local vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                cb({ 
                    success = false, 
                    message = "Vị trí này đã có xe " .. vehicleName .. "! Vui lòng xóa xe cũ trước khi trưng bày xe mới." 
                })
                return
            end
        end
    end
    
    local spawnData = {
        vehicle = model,
        key = positionId,
        dealerId = targetDealer
    }
    
    SpawnShowroom(spawnData)
    cb({ success = true })
end)

RegisterNUICallback('notify', function(data, cb)
    local notifType = data.type or 'success'
    exports.qbx_core:Notify(data.message, notifType)
    cb('ok')
end)

RegisterNetEvent('1307_Cardealer:client:CallbackResponse', function(response)
    SendNUIMessage({
        action = 'response',
        data = response
    })
    if response.message then
        local notifType = response.success and 'success' or 'error'
        exports.qbx_core:Notify(response.message, notifType)
    end
end)
