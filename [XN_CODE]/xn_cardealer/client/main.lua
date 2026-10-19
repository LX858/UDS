-- Variables
Client_Vehicle_Data = {}
local QBCore = exports["qb-core"]:GetCoreObject()
local PlayerJob = {}
local onDuty = false 

-- Local Zone 
local DuocPhepXoaXe = false
local CurrentZoneDealer = nil

local function IsShowroomPlate(plate)
    if not plate then return false end
    local cleanPlate = string.upper(string.gsub(tostring(plate), "%s+", ""))
    return string.find(cleanPlate, "XEBAN999") ~= nil or cleanPlate == "XEBAN999"
end

function Delete_Entity(entity)
    if not DoesEntityExist(entity) then return end
    
    if NetworkGetEntityIsNetworked(entity) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        TriggerServerEvent('1307_Cardealer:server:deleteVehicle', netId)
        
        local timeout = 0
        while not NetworkHasControlOfEntity(entity) and timeout < 15 do
            NetworkRequestControlOfEntity(entity)
            Wait(30)
            timeout = timeout + 1
        end
    end
    
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityAsNoLongerNeeded(entity)
    DeleteVehicle(entity)
    DeleteEntity(entity)
end

local function HandleExitShowroomVehicle(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    local plate = GetVehicleNumberPlateText(veh)
    if IsShowroomPlate(plate) then
        local ped = PlayerPedId()
        if IsPedInVehicle(ped, veh, false) then
            local pCoords = GetEntityCoords(ped)
            ClearPedTasksImmediately(ped)
            SetEntityCoords(ped, pCoords.x, pCoords.y, pCoords.z, false, false, false, true)
        end
        CreateThread(function()
            Wait(50)
            if DoesEntityExist(veh) then
                Delete_Entity(veh)
                exports.qbx_core:Notify("Xe trưng bày (" .. (plate or "XEBAN999") .. ") đã bị tự động xóa khi rời khỏi khu vực showroom!", "error", 4000)
            end
        end)
    end
end

-- Tạo Polyzone Farm cho từng Dealer
CreateThread(function()
    for dealerId, dealerCfg in pairs(Config.Dealers) do
        if dealerCfg.zoneFarm and dealerCfg.zoneFarm.points then
            lib.zones.poly({
                name = dealerId .. "_zone",
                points = dealerCfg.zoneFarm.points,
                thickness = dealerCfg.zoneFarm.thickness or 30.0,
                debug = false,
                onExit = function()
                    DuocPhepXoaXe = false
                    CurrentZoneDealer = nil

                    local ped = PlayerPedId()
                    local veh = GetVehiclePedIsIn(ped, false)
                    if not veh or veh == 0 then
                        veh = GetVehiclePedIsIn(ped, true)
                    end
                    HandleExitShowroomVehicle(veh)
                end,  
                onEnter = function()
                    DuocPhepXoaXe = true
                    CurrentZoneDealer = dealerId
                end,
            })
        end
    end
end)

-- Bắt sự kiện khi lên bất kỳ xe nào mang biển XEBAN999 ở ngoài showroom
lib.onCache('vehicle', function(veh)
    if veh and DoesEntityExist(veh) then
        local plate = GetVehicleNumberPlateText(veh)
        if IsShowroomPlate(plate) and not DuocPhepXoaXe then
            HandleExitShowroomVehicle(veh)
        end
    end
end)

local function GetVehicleNameFromList(hash)
	for k, v in pairs(QBCore.Shared.Vehicles) do
		if v.hash == hash then
			if v.model then
				return v.model
			end
		end
	end
end

-- Ox Target để xóa xe trong vùng Showroom của đại lý
exports.ox_target:addGlobalVehicle({
    {
        name = 'cardealer_delete_vehicle',
        icon = 'fas fa-trash',
        label = 'Xóa xe',
        bones = {
            'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r', 'bonnet', 'boot',
            'seat_dside_f', 'seat_pside_f', 'engine', 'forks_u', 'forks_l', 'swingarm',
            'chassis', 'chassis_dummy'
        },
        distance = 2.5,
        canInteract = function(entity, distance, coords, name, bone)
            if not QBX or not QBX.PlayerData or not QBX.PlayerData.job then return false end
            
            local dealerId, dealerCfg = GetDealerByJob(QBX.PlayerData.job.name)
            if not dealerId then return false end
            
            -- Kiểm tra có đang trong vùng zoneFarm của đúng đại lý không HOẶC đứng gần showroom
            local inZone = DuocPhepXoaXe and (not CurrentZoneDealer or CurrentZoneDealer == dealerId)
            if not inZone and dealerCfg and dealerCfg.locations and dealerCfg.locations.duty then
                local pCoords = GetEntityCoords(PlayerPedId())
                if #(pCoords - dealerCfg.locations.duty) < 60.0 then
                    inZone = true
                end
            end
            
            if not inZone then
                return false
            end
            
            if not IsEntityAVehicle(entity) then
                return false
            end
            
            return true
        end,
        onSelect = function(data)
            local vehicle = data.entity
            local vehicleHash = GetEntityModel(vehicle)
            local vehicleName = GetVehicleNameFromList(vehicleHash) or "Unknown Vehicle"
            local plate = GetVehicleNumberPlateText(vehicle)
            
            local alert = lib.alertDialog({
                header = 'Xác nhận xóa xe',
                content = 'Bạn có chắc chắn muốn xóa xe: **' .. vehicleName .. '**\nBiển số: **' .. plate .. '**\n\nHành động này không thể hoàn tác!',
                centered = true,
                cancel = true
            })
            
            if alert == 'confirm' then
                if DoesEntityExist(vehicle) then
                    Delete_Entity(vehicle)
                    exports.qbx_core:Notify('Đã xóa xe biển số: ' .. plate, 'success')
                else
                    exports.qbx_core:Notify('Xe không tồn tại!', 'error')
                end
            else
                exports.qbx_core:Notify('Đã hủy xóa xe', 'error')
            end
        end
    }
})

-- Tạo Blips cho tất cả các Dealer trên bản đồ
CreateThread(function()
    for dealerId, dealerCfg in pairs(Config.Dealers) do
        if dealerCfg.blip and dealerCfg.blip.enabled and dealerCfg.blip.coords then
            local blip = AddBlipForCoord(dealerCfg.blip.coords.x, dealerCfg.blip.coords.y, dealerCfg.blip.coords.z)
            SetBlipSprite(blip, dealerCfg.blip.sprite or 225)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, dealerCfg.blip.scale or 0.7)
            SetBlipAsShortRange(blip, true)
            SetBlipColour(blip, dealerCfg.blip.color or 0)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(dealerCfg.blip.name or dealerCfg.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Khởi tạo Ox Target động cho từng Dealer
CreateThread(function()
    for dealerId, dealerCfg in pairs(Config.Dealers) do
        -- 1. Ox Target Duty / On-Off ca & Quản lý
        if dealerCfg.locations and dealerCfg.locations.duty then
            exports.ox_target:addSphereZone({
                coords = dealerCfg.locations.duty,
                radius = 1.2,
                debug = false,
                options = {
                    {
                        name = dealerId .. '_duty_menu',
                        icon = 'fas fa-user-tie',
                        label = 'Menu Nhân Viên (' .. dealerCfg.label .. ')',
                        distance = 2.0,
                        canInteract = function()
                            return QBX.PlayerData.job and QBX.PlayerData.job.name == dealerCfg.job
                        end,
                        onSelect = function()
                            TriggerEvent('1307_Cardealer:cl:OpenNUI', dealerId)
                        end
                    }
                }
            })
        end

        -- 2. Ox Target Public View Points
        if dealerCfg.publicViewPoints then
            for _, viewPoint in ipairs(dealerCfg.publicViewPoints) do
                if viewPoint.type == 'coords' and viewPoint.coords then
                    exports.ox_target:addSphereZone({
                        coords = viewPoint.coords,
                        radius = viewPoint.radius or 1.5,
                        debug = false,
                        options = {
                            {
                                name = dealerId .. '_public_view',
                                icon = 'fas fa-car',
                                label = viewPoint.label or ('Xem Danh Sách ' .. dealerCfg.label),
                                distance = 2.5,
                                onSelect = function()
                                    TriggerEvent('1307_Cardealer:cl:OpenPublicUI', dealerId)
                                end
                            }
                        }
                    })
                elseif viewPoint.type == 'prop' and viewPoint.model then
                    exports.ox_target:addModel(viewPoint.model, {
                        {
                            name = dealerId .. '_prop_view',
                            icon = 'fas fa-car',
                            label = viewPoint.label or ('Xem Danh Sách ' .. dealerCfg.label),
                            distance = 2.0,
                            onSelect = function()
                                local closestDealer = GetDealerAtCoords(GetEntityCoords(cache.ped), 30.0) or dealerId
                                TriggerEvent('1307_Cardealer:cl:OpenPublicUI', closestDealer)
                            end
                        }
                    })
                end
            end
        end
    end
end)

local function getClosestPlayer(distance)
    local coords = GetEntityCoords(cache.ped)
    local player, playerPed = lib.getClosestPlayer(coords, distance or 2.5)
    if not player then
        exports.qbx_core:Notify('Không có ai ở gần bạn', 'error')
        return nil
    end
    return player, playerPed
end

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local factor = #text / 460
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.3, 0.3)
    SetTextFont(6)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 160)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

function SpawnShowroom(data)
    local model = data.vehicle
    local display = data.key
    local dealerId = data.dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name)) or 'cardealer'
    local dealerCfg = GetDealerById(dealerId)
    local spawnCoords = (dealerCfg and dealerCfg.showroomLocations and dealerCfg.showroomLocations[display])

    if not spawnCoords then
        exports.qbx_core:Notify("Vị trí showroom không hợp lệ", "error")
        return
    end

    local netid, veh = lib.callback.await('1307_Cardealer:server:spawnVehicle', false, model, spawnCoords, "XEBAN999")
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    
    Wait(300)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        for i = 1, 5 do
            SetVehicleNumberPlateText(vehicle, "XEBAN999")
            Wait(100)
        end
        SetVehicleFuelLevel(vehicle, 100.0)
        SetVehicleEngineOn(vehicle, false, false, true)
        FreezeEntityPosition(vehicle, true)
    end
end

RegisterNetEvent('1307_Cardealer:client:SyncData', function(data)
    Client_Vehicle_Data = data
    SendNUIMessage({
        action = 'updateVehicles',
        vehicles = data
    })
end)

RegisterNetEvent('1307_Cardealer:client:ForceRefreshData', function()
    local data = lib.callback.await("1307_Cardealer:server:GetData")
    Client_Vehicle_Data = data
end)

RegisterNetEvent('1307_Cardealer:cl:XoaXeOnly', function()
    local dealerId, dealerCfg = QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name)
    if not dealerId then
        return exports.qbx_core:Notify("Bạn không phải nhân viên đại lý xe", "error")
    end
    if QBX.PlayerData.job.grade.level < 3 then 
        return exports.qbx_core:Notify("Chỉ có giám đốc và phó mới được xóa xe", "error") 
    end
    
    local inZone = DuocPhepXoaXe and (not CurrentZoneDealer or CurrentZoneDealer == dealerId)
    if not inZone and dealerCfg and dealerCfg.locations and dealerCfg.locations.duty then
        local pCoords = GetEntityCoords(PlayerPedId())
        if #(pCoords - dealerCfg.locations.duty) < 60.0 then
            inZone = true
        end
    end
    
    if not inZone then 
        return exports.qbx_core:Notify("Bạn cần ở trong khu vực của Showroom để dùng tính năng này", "error")
    end
    if not IsPedInAnyVehicle(PlayerPedId()) then 
        return exports.qbx_core:Notify("Bạn cần ngồi trong xe để xóa", "error")
    end
    local Vehicle = GetVehiclePedIsIn(PlayerPedId())
    local Plate = GetVehicleNumberPlateText(Vehicle)
    if Plate ~= "XEBAN999" then 
        return exports.qbx_core:Notify("Bạn không thể xóa xe không phải biển số trưng bày", "error")
    end
    Delete_Entity(Vehicle)
end)

RegisterNetEvent('1307_Cardealer:client:SetOwner')
AddEventHandler('1307_Cardealer:client:SetOwner', function(plate, dealerId)
    local Vehicle = GetVehiclePedIsIn(PlayerPedId())
    local hasKey = exports['Renewed-Vehiclekeys']:hasKey(plate)
    local targetDealerId = dealerId or 'cardealer'
    local dealerCfg = GetDealerById(targetDealerId) or Config.Dealers['cardealer']
    local spawnCoords = dealerCfg.locations and dealerCfg.locations.spawn

    if Vehicle and Vehicle ~= 0 then
        SetVehicleNumberPlateText(Vehicle, plate)
        FreezeEntityPosition(Vehicle, false)
        TriggerServerEvent('qbx_vehiclekeys:server:tookKeys', NetworkGetNetworkIdFromEntity(Vehicle))
        
        if not hasKey then
            TriggerEvent("vehiclekeys:client:SetOwner", plate)
        end
        
        if spawnCoords then
            SetEntityCoords(Vehicle, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
            SetEntityHeading(Vehicle, spawnCoords.w)
        end
    else
        if not hasKey then
            TriggerEvent("vehiclekeys:client:SetOwner", plate)
        end
    end
end)

function GetAvailablePosition()
    for k, v in pairs(Config.PortLocation) do 
        local Busy = GetVehiclesInArea(vector3(v.x, v.y, v.z), 1)
        if #Busy == 0 then 
			return k
        end
    end 
end 

RegisterNetEvent("1307_Cardealer:client:TestDrive", function()
    local player, playerPed = getClosestPlayer()
    if not player then 
        return exports.qbx_core:Notify('Không tìm thấy cư dân', 'error')
    end
    if not IsPedInAnyVehicle(playerPed) then 
        return exports.qbx_core:Notify("Vui lòng cho người chơi ngồi lên xe", "error")
    end
    local Vehicle = GetVehiclePedIsIn(playerPed)
    local Plate = GetVehicleNumberPlateText(Vehicle)
    if Plate ~= "XEBAN999" then 
        return exports.qbx_core:Notify("Không thể cho lái thử xe này", "error")
    end

    local dealerId = QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name) or 'cardealer'
    TriggerServerEvent("1307_Cardealer:server:StartTestDrive", GetPlayerServerId(player), dealerId)
    exports.qbx_core:Notify("Đã gửi yêu cầu lái thử cho người chơi", "success")
end)

RegisterNetEvent("1307_Cardealer:client:SellVehicle", function()
    local player, playerPed = getClosestPlayer()
    if not player then 
        return exports.qbx_core:Notify('Không tìm thấy cư dân', 'error')
    end

    if not IsPedInAnyVehicle(playerPed) then 
        return exports.qbx_core:Notify("Vui lòng cho người chơi ngồi lên xe", "error")
    end

    local Vehicle = GetVehiclePedIsIn(playerPed)
    local Plate = GetVehicleNumberPlateText(Vehicle)
    if Plate ~= "XEBAN999" then 
        return exports.qbx_core:Notify("Không thể bán chiếc xe này", "error")
    end

    local Hash = GetEntityModel(Vehicle)
    local saleInfo = lib.callback.await('1307_Cardealer:server:GetShowroomSaleInfoByHash', false, Hash)
    if not saleInfo or not saleInfo.vehicle then
        return exports.qbx_core:Notify("Xe này đã xảy ra lỗi, hãy báo cho BQL", "error")
    end
    if (saleInfo.stock or 0) <= 0 then
        return exports.qbx_core:Notify("Xe này đã hết hàng", "error")
    end

    local VehModel = saleInfo.vehicle
    local finalPrice = saleInfo.priceToCustomers or 0
    if finalPrice <= 0 then
        return exports.qbx_core:Notify("Chưa có giá bán cho xe này", "error")
    end

    local confirmSale = lib.alertDialog({
        header = '🚗 XÁC NHẬN BÁN XE',
        content = 'Bạn có chắc chắn muốn bán xe **' .. VehModel .. '** với giá **$' .. finalPrice .. '** không?\n\nGiá này được tính theo hệ thống và không thể thay đổi.',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Bán xe ($' .. finalPrice .. ')',
            cancel = 'Hủy bỏ'
        }
    })

    if confirmSale ~= 'confirm' then
        return exports.qbx_core:Notify('Đã hủy bán xe', 'error')
    end

    local playerId = GetPlayerServerId(player)
    local dealerId = QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name) or 'cardealer'
    TriggerServerEvent("1307_Cardealer:server:SendVehiclePurchaseRequest", VehModel, 0, playerId, dealerId)
    exports.qbx_core:Notify("Đã gửi yêu cầu mua xe với giá $" .. finalPrice .. " cho khách hàng", "success")
end)

-- Nhận request mua xe từ nhân viên
RegisterNetEvent("1307_Cardealer:client:ReceivePurchaseRequest", function(vehModel, vehPrice, sellerName, sellerId, dealerId)
    local VehName = vehModel
    local qbxVehicles = exports.qbx_core:GetVehiclesByName()
    if qbxVehicles and qbxVehicles[vehModel] and qbxVehicles[vehModel].name then
        VehName = qbxVehicles[vehModel].name
    else
        for k, v in pairs(QBCore.Shared.Vehicles) do
            if v.model == vehModel then
                VehName = v.name
                break
            end
        end
    end

    _pendingPurchase = {
        vehModel   = vehModel,
        vehPrice   = vehPrice,
        sellerName = sellerName,
        sellerId   = sellerId,
        dealerId   = dealerId or 'cardealer',
    }

    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'showPurchaseDialog',
        vehModel   = vehModel,
        vehName    = VehName,
        vehPrice   = vehPrice,
        sellerName = sellerName,
    })
end)

local function DrawText2D(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

RegisterNetEvent("1307_Cardealer:client:StartTestDrive", function(dealerId)
    local PlayerPed = PlayerPedId()
    if not IsPedInAnyVehicle(PlayerPed) then 
        return exports.qbx_core:Notify("Bạn cần ngồi lên xe để chạy thử")
    end
    local Vehicle = GetVehiclePedIsIn(PlayerPed)
    local Plate = GetVehicleNumberPlateText(Vehicle)
    if Plate ~= "XEBAN999" then 
        return exports.qbx_core:Notify("Chiếc xe này không thể chạy thử")
    end
    exports.qbx_core:Notify("Bạn được lái thử chiếc xe này trong "..(Config.TestDriveTimer/1000).." giây")
    local TestPlate = "XETEST"..math.random(10, 99)

    local targetDealer = GetDealerById(dealerId) or Config.Dealers['cardealer']
    local testSpawn = targetDealer.locations and targetDealer.locations.testSpawn or vector4(516.80, -268.61, 46.54, 144.04)
    local testBack = targetDealer.locations and targetDealer.locations.testBack or vector4(-791.64, -223.19, 37.24, 0.0)

    SetVehicleNumberPlateText(Vehicle, TestPlate)
    FreezeEntityPosition(Vehicle, false)
    SetEntityCoords(Vehicle, testSpawn.x, testSpawn.y, testSpawn.z)
    SetEntityHeading(Vehicle, testSpawn.w)
    FreezeEntityPosition(Vehicle, false)

    local vehicleNetId = NetworkGetNetworkIdFromEntity(Vehicle)
    TriggerServerEvent('1307_Cardealer:server:SetTestDriveBucket', vehicleNetId)

    Wait(1000)
    exports['Renewed-Vehiclekeys']:addKey(TestPlate)
    Wait(500)

    InTestDrive = true
    TimeTestDrive = GetGameTimer()
    CreateThread(function()
        while InTestDrive and (GetGameTimer() - TimeTestDrive) < Config.TestDriveTimer do 
            DrawText2D('Thời Gian Lái Thử: '..math.ceil((Config.TestDriveTimer - (GetGameTimer() - TimeTestDrive)) / 1000)..' giây\nNếu xong, hãy nhấn ~y~[E]~w~ để quay về', 4, 0.5, 0.9, 0.50, 255, 255, 255, 180)
            if IsControlJustReleased(0, 38) then 
                InTestDrive = false
            end 
            Wait(0)
        end 
        
        exports['Renewed-Vehiclekeys']:removeKey(TestPlate)
        TriggerServerEvent('1307_Cardealer:server:ResetBucket')
        exports.qbx_core:Notify("Đã hết thời gian lái thử")
        DeleteVehicle(Vehicle)
        SetEntityCoords(PlayerPed, testBack.x, testBack.y, testBack.z, false, false, false, true)
        SetEntityHeading(PlayerPed, testBack.w or 0.0)
    end)
end)

RegisterNetEvent('1307_Cardealer:client:OrderedVehicles', function(vehicle, plate)
    local Available = GetAvailablePosition()
    if not Available then 
        return exports.qbx_core:Notify("Không còn chỗ trống ở cảng", "error")
    end
    local netid, veh = lib.callback.await('1307_Cardealer:server:spawnVehicle', false, vehicle, Config.PortLocation[Available], plate)
    SetVehicleFuelLevel(veh, 100.0)
    SetVehicleNumberPlateText(veh, plate)
    SetEntityAsMissionEntity(veh, true, true)
end)

function OrderingVehicle(vehicle, price, brand, dealerId)
    local Balance = lib.callback.await("1307_Cardealer:server:GetBalance", false, dealerId)
    local Price = price
    if tonumber(Balance) < tonumber(Price) then
        exports.qbx_core:Notify("Số dư của quỹ doanh nghiệp không đủ", "error")
    else 
        local Available = GetAvailablePosition()
        if not Available then 
            return exports.qbx_core:Notify("Không còn chỗ trống ở cảng", "error")
        end
        exports['rpemotes']:EmoteCommandStart("tablet2")
        if lib.progressCircle({
            duration = 10000,
            position = 'bottom',
            label =  "Đang đặt hàng...",
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, mouse = false, combat = true, },
        }) then
            local NhapXe = lib.callback.await("1307_Cardealer:server:NhapXe", false, vehicle, brand, dealerId)
            if not NhapXe then
                return exports.qbx_core:Notify("Xe đợt này đã hết!", "error")
            end
            TriggerServerEvent('1307_Cardealer:server:OrderVehicles', vehicle, price, dealerId)
            exports['rpemotes']:EmoteCancel()
        else 
            exports['rpemotes']:EmoteCancel()
            exports.qbx_core:Notify("Đã dừng..", "error")
        end
    end 
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    PlayerJob = QBX.PlayerData.job
    local data = lib.callback.await("1307_Cardealer:server:GetData")
    Client_Vehicle_Data = data
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function() 
	PlayerJob = QBX.PlayerData.job
	onDuty = PlayerJob.onduty
    local data = lib.callback.await("1307_Cardealer:server:GetData")
    Client_Vehicle_Data = data
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
end)

RegisterNetEvent('1307_Cardealer:cl:OpenXemXe', function(dealerId)
    TriggerEvent('1307_Cardealer:cl:OpenPublicUI', dealerId)
end)

local function handleVehicleStockIn(vehicle, dealerId)
    local plate = GetVehicleNumberPlateText(vehicle)
    local trimmedPlate = plate and plate:match('^%s*(.-)%s*$') or ''
    
    -- Chỉ cho phép nhập xe từ cảng có 2 ký tự đầu là 'XN'
    if string.sub(trimmedPlate:upper(), 1, 2) ~= 'XN' then
        exports.qbx_core:Notify("Điểm này chỉ nhập xe chuyển từ cảng về (biển số XN)!", "error")
        return
    end

    local model = GetEntityModel(vehicle)
    local name = GetDisplayNameFromVehicleModel(model):lower()

    TriggerServerEvent("1307_Cardealer:server:stockIn", name, trimmedPlate, dealerId)
    exports.qbx_core:Notify("Đã nhập xe vào kho thành công", "success")
    if DoesEntityExist(vehicle) then
        SetTimeout(1000, function()
            SetEntityAsMissionEntity(vehicle, true, true)
            Delete_Entity(vehicle)
        end)
    end
end

-- Thread kiểm tra nhập xe vào kho (Động theo từng dealer)
CreateThread(function()
    while true do
        local sleep = 1000
        local pos = GetEntityCoords(PlayerPedId())
        if LocalPlayer.state.isLoggedIn and QBX.PlayerData.job then 
            local dealerId, dealerCfg = GetDealerByJob(QBX.PlayerData.job.name)
            if dealerId and dealerCfg and dealerCfg.locations and dealerCfg.locations.stockIn then
                local stockDist = #(pos - dealerCfg.locations.stockIn)
                if stockDist < 7 then
                    sleep = 0
                    if IsPedInAnyVehicle(PlayerPedId()) then
                        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                        local plate = GetVehicleNumberPlateText(vehicle)
                        DrawMarker(1, dealerCfg.locations.stockIn.x, dealerCfg.locations.stockIn.y, dealerCfg.locations.stockIn.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 252, 186, 3, 255, false, false, false, true, false, false, false)
                        DrawText3Ds(dealerCfg.locations.stockIn.x, dealerCfg.locations.stockIn.y, dealerCfg.locations.stockIn.z, 'E NHẬP XE VÀO KHO')
                        if IsControlJustPressed(0, 38) then
                            handleVehicleStockIn(vehicle, dealerId)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Thread xóa xe kéo (Động theo từng dealer)
CreateThread(function()
    while true do 
        local sleep = 1000
        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        if LocalPlayer.state.isLoggedIn and QBX.PlayerData.job then 
            local dealerId, dealerCfg = GetDealerByJob(QBX.PlayerData.job.name)
            if dealerId and dealerCfg and dealerCfg.locations and dealerCfg.locations.removeFlatbed then
                local dist = #(pos - dealerCfg.locations.removeFlatbed)
                if dist < 3 then
                    sleep = 0
                    if IsPedInAnyVehicle(playerPed) then
                        DrawMarker(2, dealerCfg.locations.removeFlatbed.x, dealerCfg.locations.removeFlatbed.y, dealerCfg.locations.removeFlatbed.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 252, 186, 3, 255, false, false, false, true, false, false, false)
                        DrawText3Ds(dealerCfg.locations.removeFlatbed.x, dealerCfg.locations.removeFlatbed.y, dealerCfg.locations.removeFlatbed.z, "~g~[E]~w~ Trả Xe Kéo Flatbed")
                        if IsControlJustPressed(0, 38) then
                            local vehicle = GetVehiclePedIsIn(playerPed, false)
                            if DoesEntityExist(vehicle) then
                                local model = GetEntityModel(vehicle)
                                local isAllowedFlatbed = Config.AllowedFlatbeds and Config.AllowedFlatbeds[model]
                                if isAllowedFlatbed or model == `flatbed` or model == `slamtruck` then
                                    SetTimeout(500, function()
                                        SetEntityAsMissionEntity(vehicle, true, true)
                                        Delete_Entity(vehicle)
                                        exports.qbx_core:Notify("Đã cất xe kéo doanh nghiệp", "success")
                                    end)
                                else
                                    exports.qbx_core:Notify("Điểm này chỉ để cất xe kéo (Flatbed), không thể xóa các loại xe khác!", "error")
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Menu Nhân Viên khi tương tác tại Duty Zone
RegisterNetEvent('1307_Cardealer:cl:OpenNUI', function(dealerId)
    local currentDealerId = dealerId or (QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name)) or 'cardealer'
    local dealerCfg = GetDealerById(currentDealerId) or Config.Dealers['cardealer']

    local allowedItems = {
        { 
            title = "🔔 | VÀO / TAN CA", 
            onSelect = function() 
                TriggerServerEvent('QBCore:ToggleDuty')
            end
        },
    }
    
    if QBX.PlayerData.job.grade.level >= 1 then
        table.insert(allowedItems, {
            title = "⚙️ | QUẢN LÝ",
            onSelect = function()
                if not QBX.PlayerData.job.onduty then 
                    return exports.qbx_core:Notify('Bạn chưa On Duty', 'error')
                end
                TriggerEvent('1307_Cardealer:cl:OpenManagementUI', currentDealerId)
            end
        })
    end
    
    lib.registerContext({
        id = '1307_Cardealer_DutyMenu',
        title = dealerCfg.label:upper(),
        options = {
            { readOnly = true, title = 'Vui lòng chọn mục bạn muốn thao tác', description = '' },
            table.unpack(allowedItems)
        }
    })
    lib.showContext('1307_Cardealer_DutyMenu')
end)

-- Command để force clear showroom (chỉ dành cho quản lý/admin)
RegisterCommand('forceclearshowroom', function()
    local dealerId = QBX.PlayerData.job and GetDealerByJob(QBX.PlayerData.job.name)
    if dealerId and QBX.PlayerData.job.grade.level >= 3 then
        ForceClearShowroomArea(dealerId)
    else
        exports.qbx_core:Notify('Bạn không có quyền sử dụng lệnh này', 'error')
    end
end, false)
