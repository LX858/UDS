local washedVehicles = {}
toolboxProp = nil -- Global variable

-- Hàm gửi Discord log
local function sendRepairLog(actionType, vehicle)
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
    local vehicleLabel = GetLabelText(vehicleName)
    if vehicleLabel == 'NULL' then vehicleLabel = vehicleName end
    
    TriggerServerEvent('mt_workshops:server:discordLog', actionType, vehiclePlate, vehicleModel, vehicleName, vehicleLabel)
end

-- Hàm kiểm tra player có đang trong zone workshop không (luôn check trực tiếp vị trí)
local function isPlayerInWorkshopZone(job)
    -- Luôn check trực tiếp vị trí player với tất cả zone để tránh bug cache
    local playerCoords = GetEntityCoords(cache.ped)
    for k, v in pairs(Config.workshops) do
        if v.enabled and v.job == job then
            if zone[k] and zone[k]:contains(playerCoords) then
                return true
            end
            if v.repairBays then
                for _, bay in ipairs(v.repairBays) do
                    local bayPos = vec3(bay.coords.x, bay.coords.y, bay.coords.z)
                    if #(playerCoords - bayPos) <= 20.0 then
                        return true
                    end
                end
            end
        end
    end
    
    return insideZone[job] == true
end

-- Helper chỉ unfreeze xe nếu xe không trong trạng thái freeze sửa chữa của repair bay
local function unfreezeIfAllowed(vehicle)
    if not DoesEntityExist(vehicle) then return end
    if not Entity(vehicle).state.isRepairFrozen then
        FreezeEntityPosition(vehicle, false)
    end
end

-- Sync freeze xe từ server
RegisterNetEvent('mt_workshops:client:syncVehicleFreeze', function(netId, state)
    if NetworkDoesNetworkIdExist(netId) then
        local vehicle = NetToVeh(netId)
        if DoesEntityExist(vehicle) then
            FreezeEntityPosition(vehicle, state)
        end
    end
end)

AddStateBagChangeHandler('isRepairFrozen', nil, function(bagName, key, value, _unused, replicated)
    local entNet = tonumber(bagName:gsub('entity:', ''), 10)
    if entNet and NetworkDoesNetworkIdExist(entNet) then
        local ent = NetToVeh(entNet)
        if DoesEntityExist(ent) then
            FreezeEntityPosition(ent, value == true)
        end
    end
end)

-- Thread quản lý vị trí sửa xe (Repair Bays) và Freeze / Unfreeze cho Mechanic
CreateThread(function()
    local textUiShown = false
    local currentAction = nil
    local targetVehicle = nil

    while true do
        local sleep = 1000
        local ped = cache.ped
        local playerJob = getPlayerJob()
        
        if playerJob == 'mechanic' and isPlayerOnDuty() and IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local isDriver = (GetPedInVehicleSeat(vehicle, -1) == ped)
            
            if isDriver and DoesEntityExist(vehicle) then
                local isFrozen = Entity(vehicle).state.isRepairFrozen
                local vehCoords = GetEntityCoords(vehicle)
                
                if isFrozen then
                    sleep = 0
                    if not textUiShown or currentAction ~= 'unfreeze' or targetVehicle ~= vehicle then
                        showTextUI('[E] - Gỡ cố định xe', 'unlock')
                        textUiShown = true
                        currentAction = 'unfreeze'
                        targetVehicle = vehicle
                    end
                    
                    if IsControlJustPressed(0, 38) then -- Phím E
                        hideTextUI()
                        textUiShown = false
                        currentAction = nil
                        targetVehicle = nil
                        
                        FreezeEntityPosition(vehicle, false)
                        SetVehicleHandbrake(vehicle, false)
                        TriggerServerEvent('mt_workshops:server:setVehicleRepairFreeze', VehToNet(vehicle), false)
                        notify('Đã gỡ cố định xe thành công!', 'success')
                        Wait(1000)
                    end
                else
                    local inBay = false
                    local matchedBay = nil
                    
                    for _, workshop in pairs(Config.workshops) do
                        if workshop.enabled and workshop.job == 'mechanic' and workshop.repairBays then
                            for _, bay in ipairs(workshop.repairBays) do
                                local bayPos = vec3(bay.coords.x, bay.coords.y, bay.coords.z)
                                local radius = bay.radius or 3.0
                                local dist = #(vehCoords - bayPos)
                                if dist <= radius then
                                    inBay = true
                                    matchedBay = bay
                                    break
                                end
                            end
                        end
                        if inBay then break end
                    end
                    
                    if inBay then
                        sleep = 0
                        if not textUiShown or currentAction ~= 'freeze' or targetVehicle ~= vehicle then
                            showTextUI('[E] - Cố định xe để sửa chữa', 'wrench')
                            textUiShown = true
                            currentAction = 'freeze'
                            targetVehicle = vehicle
                        end
                        
                        if IsControlJustPressed(0, 38) then -- Phím E
                            hideTextUI()
                            textUiShown = false
                            currentAction = nil
                            targetVehicle = nil
                            
                            if matchedBay and matchedBay.coords.w then
                                SetEntityHeading(vehicle, matchedBay.coords.w)
                            end
                            
                            FreezeEntityPosition(vehicle, true)
                            SetVehicleEngineOn(vehicle, false, false, true)
                            SetVehicleHandbrake(vehicle, true)
                            TriggerServerEvent('mt_workshops:server:setVehicleRepairFreeze', VehToNet(vehicle), true)
                            notify('Xe đã được cố định tại vị trí sửa chữa! Bây giờ bạn có thể dùng Hộp dụng cụ (mechanic_toolbox) để sửa xe.', 'success')
                            Wait(1000)
                        end
                    else
                        if textUiShown then
                            hideTextUI()
                            textUiShown = false
                            currentAction = nil
                            targetVehicle = nil
                        end
                    end
                end
            else
                if textUiShown then
                    hideTextUI()
                    textUiShown = false
                    currentAction = nil
                    targetVehicle = nil
                end
            end
        else
            if textUiShown then
                hideTextUI()
                textUiShown = false
                currentAction = nil
                targetVehicle = nil
            end
        end
        
        Wait(sleep)
    end
end)

local isSessionActive = false
local sessionInitialEngineHealth = 0
local sessionInitialBodyHealth = 0
local sessionVehicle = nil
local sessionWashed = false

-- Hàm tính toán số lượng nguyên liệu cần thiết dựa trên độ hư hỏng (cứ 10% hỏng = 1 nguyên liệu)
local function getRepairItemCount(health, maxHealth)
    maxHealth = maxHealth or 1000.0
    local currentHealth = math.max(0.0, math.min(maxHealth, health))
    if currentHealth >= maxHealth then return 0 end
    
    local rawDamagePercent = (maxHealth - currentHealth) / maxHealth * 100
    local damagePercent = math.floor(rawDamagePercent * 100 + 0.5) / 100
    return math.max(1, math.floor(damagePercent / 10))
end

local function closeToolboxMenu()
    if isSessionActive and sessionVehicle and DoesEntityExist(sessionVehicle) then
        local initialEngine = math.max(0.0, math.min(1000.0, sessionInitialEngineHealth))
        local initialBody = math.max(0.0, math.min(1000.0, sessionInitialBodyHealth))
        local currentEngine = math.max(0.0, math.min(1000.0, GetVehicleEngineHealth(sessionVehicle)))
        local currentBody = math.max(0.0, math.min(1000.0, GetVehicleBodyHealth(sessionVehicle)))
        
        local engineRepaired = math.min(100, math.max(0, math.floor((currentEngine - initialEngine) / 10 + 0.5)))
        local bodyRepaired = math.min(100, math.max(0, math.floor((currentBody - initialBody) / 10 + 0.5)))
        
        if engineRepaired > 0 or bodyRepaired > 0 or sessionWashed then
            local plate = GetVehicleNumberPlateText(sessionVehicle)
            TriggerServerEvent('mt_workshops:server:giveRepairInvoice', engineRepaired, bodyRepaired, plate, sessionWashed)
        end
    end
    isSessionActive = false
    sessionVehicle = nil
    sessionInitialEngineHealth = 0
    sessionInitialBodyHealth = 0
    sessionWashed = false
end
exports('closeToolboxMenu', closeToolboxMenu)

openToolboxMenu = function()
    local playerJob = getPlayerJob()
    local onDuty = isPlayerOnDuty()
    
    -- Check if player has mechanic job specifically
    if playerJob ~= 'mechanic' then 
        notify(locale('notify_error_no_job_access'), 'error') 
        return 
    end

    -- Check if mechanic is on duty
    if not onDuty then
        notify('Bạn phải đang On Duty mới có thể sử dụng hộp dụng cụ!', 'error')
        return
    end
    
    local vehicle = getClosestVehicle()
    if not vehicle then notify(locale('notify_error_no_vehicle'), 'error') return end
    
    -- Kiểm tra xe đã được cố định tại vị trí sửa chữa chưa
    local isRepairFrozen = Entity(vehicle).state.isRepairFrozen
    if not isRepairFrozen then
        notify('Xe chưa được cố định tại vị trí sửa chữa! Vui lòng đưa xe vào ô sửa chữa và nhấn [E] để cố định trước.', 'error')
        return
    end
    
    -- Khởi tạo session sửa chữa nếu chưa có hoặc đổi xe khác
    if not isSessionActive or sessionVehicle ~= vehicle then
        isSessionActive = true
        sessionVehicle = vehicle
        sessionInitialEngineHealth = math.max(0.0, math.min(1000.0, GetVehicleEngineHealth(vehicle)))
        sessionInitialBodyHealth = math.max(0.0, math.min(1000.0, GetVehicleBodyHealth(vehicle)))
    end
    
    -- Kiểm tra xe có phải xe đặc biệt không
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleDisplayName = string.lower(GetDisplayNameFromVehicleModel(vehicleModel))
    local isSpecialVehicle = false
    
    for _, specialModel in ipairs(Config.specialVehicles) do
        local specialModelLower = string.lower(specialModel)
        if vehicleDisplayName == specialModelLower or GetHashKey(specialModel) == vehicleModel then
            isSpecialVehicle = true
            break
        end
    end
    
    -- Nếu xe đã được freeze tại repair bay thì đã hợp lệ, ngược lại kiểm tra zone workshop
    if not isRepairFrozen and not (isSpecialVehicle and Config.specialVehiclesIgnoreZone) and not isPlayerInWorkshopZone(playerJob) then 
        notify(locale('notify_error_inside_zone'), 'error') 
        return 
    end
    
    -- Xóa prop cũ nếu tồn tại
    if DoesEntityExist(toolboxProp) then
        DeleteEntity(toolboxProp)
        toolboxProp = nil
    end
    
    -- Animation cầm toolbox
    loadAnimDict('move_weapon@jerrycan@generic')
    TaskPlayAnim(cache.ped, 'move_weapon@jerrycan@generic', 'idle', 8.0, -8.0, -1, 50, 0, false, false, false)
    
    -- Spawn toolbox prop
    loadModel(`prop_toolchest_01`)
    toolboxProp = CreateObject(`prop_toolchest_01`, GetEntityCoords(cache.ped), false, false, false)
    if DoesEntityExist(toolboxProp) then
        AttachEntityToEntity(toolboxProp, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.43, 0.0, -0.07, 0.0, -800.0, 90.06, true, true, false, true, 1, true)
    end
    
    -- Progress bar
    if progressBar('Lấy dụng cụ...', 1000, { car = false, walk = false }) then
        -- Giữ prop trên tay, không thả xuống đất
        Wait(200)
        
        -- Hiển thị NUI
        local neededItems = {}
        for k, v in pairs(Config.repairItems) do
            local itemData = getItemData(v.item)
            neededItems[k] = {
                count = v.count,
                item = v.item,
                label = itemData and itemData.label or v.item
            }
        end
        
        local engineHealth = math.max(0.0, math.min(1000.0, GetVehicleEngineHealth(vehicle)))
        local bodyHealth = math.max(0.0, math.min(1000.0, GetVehicleBodyHealth(vehicle)))
        local tankHealth = math.max(0.0, math.min(1000.0, GetVehiclePetrolTankHealth(vehicle)))
        
        if neededItems.engine then
            neededItems.engine.count = getRepairItemCount(engineHealth, 1000.0)
        end
        if neededItems.body then
            neededItems.body.count = getRepairItemCount(bodyHealth, 1000.0)
        end
        
        SendNUI('repairMenu', {
            engine = math.ceil(engineHealth/10),
            body = math.ceil(bodyHealth/10),
            tank = math.ceil(tankHealth/10),
            dirt = math.floor(GetVehicleDirtLevel(vehicle) / 15 * 100 + 0.5),
            neededItems = neededItems,
            toolboxOptions = Config.toolboxOptions,
            isSpecialVehicle = isSpecialVehicle
        })
        ShowNUI('setVisibleRepairMenu', true)
    else
        -- Hủy bỏ, xóa prop
        if DoesEntityExist(toolboxProp) then
            DetachEntity(toolboxProp, true, true)
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        ClearPedTasks(cache.ped)
    end
end
exports('openToolboxMenu', openToolboxMenu)
lib.callback.register('mt_workshops:client:openToolboxMenu', openToolboxMenu)

RegisterNuiCallback('openPerformanceMenu', function(data, cb)
    ShowNUI('setVisibleRepairMenu', false)
    openPerformanceMenu()
    cb(true)
end)

RegisterNuiCallback('openRepairMenu', function(data, cb)
    ShowNUI('setVisiblePerformanceMenu', false)
    openToolboxMenu()
    cb(true)
end)

RegisterNuiCallback('repairVehiclePart', function(data, cb)
    local vehicle = getClosestVehicle()
    if not vehicle then 
        notify(locale('notify_error_no_vehicle'), 'error') 
        cb(true)
        return 
    end
    if data.part == 'engine' then
        local engineHealth = GetVehicleEngineHealth(vehicle)
        local requiredCount = getRepairItemCount(engineHealth, 1000.0)
        if requiredCount <= 0 then
            notify('Động cơ không cần sửa chữa!', 'error')
            cb(true)
            return
        end
        if not getHasItem(Config.repairItems.engine.item, requiredCount) then 
            local itemLabel = Config.itemLabels[Config.repairItems.engine.item] or Config.repairItems.engine.item
            notify(locale('notify_missing_item') .. ' ' .. requiredCount .. 'x ' .. itemLabel, 'error') 
            cb(true)
            return 
        end
        ShowNUI('setVisibleRepairMenu', false)
        
        -- Khóa kho đồ
        LocalPlayer.state.invBusy = true
        
        -- Freeze xe và lưu vị trí ban đầu
        FreezeEntityPosition(vehicle, true)
        local initialVehiclePos = GetEntityCoords(vehicle)
        local repairCancelled = false
        local repairCompleted = false
        
        -- Xóa toolbox prop trên tay khi bắt đầu sửa
        if DoesEntityExist(toolboxProp) then
            DetachEntity(toolboxProp, true, true)
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        ClearPedTasks(cache.ped)
        
        -- Tính toán vị trí chính giữa trước đầu xe
        local vehCoords = GetEntityCoords(vehicle)
        local vehHeading = GetEntityHeading(vehicle)
        local forwardVector = GetEntityForwardVector(vehicle)
        local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
        local frontDistance = maxDim.y + 0.3 -- Khoảng cách từ tâm xe đến đầu xe + 0.3m
        
        -- Vị trí đích trước đầu xe
        local targetPos = vector3(
            vehCoords.x + forwardVector.x * frontDistance,
            vehCoords.y + forwardVector.y * frontDistance,
            vehCoords.z
        )
        
        -- Bắt buộc di chuyển tới vị trí trước đầu xe (đi bộ)
        TaskGoStraightToCoord(cache.ped, targetPos.x, targetPos.y, targetPos.z, 1.0, -1, GetEntityHeading(cache.ped), 0.0)
        
        -- Thread kiểm tra khoảng cách trong quá trình di chuyển
        CreateThread(function()
            while not repairCancelled and not repairCompleted do
                Wait(500)
                local pedPos = GetEntityCoords(cache.ped)
                local vehPos = GetEntityCoords(vehicle)
                local playerToVehicleDist = #(pedPos - vehPos)
                local vehicleMovedDist = #(vehPos - initialVehiclePos)
                
                if playerToVehicleDist > 20.0 then
                    repairCancelled = true
                    notify('Sửa xe bị hủy: Bạn đã di chuyển quá xa xe!', 'error')
                    break
                elseif vehicleMovedDist > 10.0 then
                    repairCancelled = true
                    notify('Sửa xe bị hủy: Xe đã bị di chuyển!', 'error')
                    break
                end
            end
        end)
        
        local arrived = false
        local timeout = GetGameTimer() + 10000 -- 10 giây timeout
        while not arrived and GetGameTimer() < timeout do
            local pedPos = GetEntityCoords(cache.ped)
            local dist = #(pedPos - targetPos)
            if dist < 1.0 then
                arrived = true
            end
            Wait(100)
        end
        
        if not arrived or repairCancelled then
            notify(locale('notify_error_no_vehicle'), 'error')
            repairCancelled = true
        end
        
        if repairCancelled then
            -- Mở khóa kho đồ
            LocalPlayer.state.invBusy = false
            -- Unfreeze xe nếu được phép
            unfreezeIfAllowed(vehicle)
            -- Làm hỏng engine
            TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
            -- Xóa toolbox prop
            if DoesEntityExist(toolboxProp) then
                DeleteEntity(toolboxProp)
                toolboxProp = nil
            end
            closeToolboxMenu()
            return
        end
        
        -- Dừng mọi task và set vị trí chính xác
        ClearPedTasks(cache.ped)
        SetEntityCoords(cache.ped, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
        Wait(200)
        
        -- Kiểm tra hủy bỏ
        if repairCancelled then
            LocalPlayer.state.invBusy = false
            unfreezeIfAllowed(vehicle)
            TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
            if DoesEntityExist(toolboxProp) then
                DeleteEntity(toolboxProp)
                toolboxProp = nil
            end
            closeToolboxMenu()
            return
        end
        
        -- Quay nhân vật về phía xe
        TaskTurnPedToFaceEntity(cache.ped, vehicle, 1500)
        Wait(1500)
        
        -- Animation mở nắp capo
        loadAnimDict("rcmnigel3_trunk")
        TaskPlayAnim(cache.ped, "rcmnigel3_trunk", "out_trunk_trevor", 8.0, 8.0, 2000, 1, 0.0, 0, 0, 0)
        Wait(2000)
        SetVehicleDoorOpen(vehicle, 4, false, false)
        Wait(500)
        
        -- Animation cúi xuống nhấc động cơ
        loadAnimDict("anim@heists@box_carry@")
        TaskPlayAnim(cache.ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
        
        -- Spawn prop động cơ
        loadModel(`prop_car_engine_01`)
        local engineProp = CreateObject(`prop_car_engine_01`, GetEntityCoords(cache.ped), false, false, false)
        if DoesEntityExist(engineProp) then
            AttachEntityToEntity(engineProp, cache.ped, GetPedBoneIndex(cache.ped, 11816), 0.01, 0.52, 0.13, -170.7, 80.1, 84.9, true, true, false, true, 1, true)
        end
        
        Wait(2000)
        
        -- Quay người 180 độ để thả động cơ phía sau xe
        local currentHeading = GetEntityHeading(cache.ped)
        SetEntityHeading(cache.ped, currentHeading + 180)
        Wait(1000)
        
        -- Thả động cơ xuống phía trước mặt player (xa khỏi xe)
        ClearPedTasks(cache.ped)
        DetachEntity(engineProp, true, true)
        local dropPos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.0, -0.5)
        SetEntityCoords(engineProp, dropPos.x, dropPos.y, dropPos.z, false, false, false, false)
        PlaceObjectOnGroundProperly(engineProp)
        Wait(500)
        
        -- Kiểm tra hủy bỏ
        if repairCancelled then
            if DoesEntityExist(engineProp) then DeleteEntity(engineProp) end
            ClearPedTasks(cache.ped)
            LocalPlayer.state.invBusy = false
            unfreezeIfAllowed(vehicle)
            TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
            if DoesEntityExist(toolboxProp) then
                DeleteEntity(toolboxProp)
                toolboxProp = nil
            end
            closeToolboxMenu()
            return
        end
        
        -- Bắt đầu sửa động cơ tại chỗ
        if progressBar(locale('progress_repair_engine'), Config.times.repairEngine, { car = true, walk = true }, { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 6 }, { model = `w_me_wrench`, pos = vec3(0.071, -0.017, 0.036), rot = vec3(-121.24, -10.43, 6.64) }) then
            -- Animation hàn (ngồi xuống)
            TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_WELDING", 0, true)
            Wait(5000)
            ClearPedTasks(cache.ped)
            
            -- Kiểm tra hủy bỏ
            if repairCancelled then
                if DoesEntityExist(engineProp) then DeleteEntity(engineProp) end
                LocalPlayer.state.invBusy = false
                unfreezeIfAllowed(vehicle)
                TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
                if DoesEntityExist(toolboxProp) then
                    DeleteEntity(toolboxProp)
                    toolboxProp = nil
                end
                closeToolboxMenu()
                return
            end
            
            -- Animation sửa chữa cơ khí (ngồi xuống)
            loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
            TaskPlayAnim(cache.ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, 5000, 0, 0.0, false, false, false)
            Wait(5000)
            ClearPedTasks(cache.ped)
            
            TriggerServerEvent('mt_workshops:server:fixVehicleEngine', VehToNet(vehicle), cache.serverId)
            
            -- Gửi Discord log
            sendRepairLog("engine", vehicle)
            
            lib.callback.await('mt_workshops:server:removeItem', false, Config.repairItems.engine.item, requiredCount)
            
            -- Đánh dấu sửa xe hoàn thành để dừng thread kiểm tra khoảng cách
            repairCompleted = true
        end
        
        -- Nhặt động cơ lên lại
        loadAnimDict("anim@heists@box_carry@")
        TaskPlayAnim(cache.ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
        
        -- Gắn lại prop động cơ vào tay
        if DoesEntityExist(engineProp) then
            AttachEntityToEntity(engineProp, cache.ped, GetPedBoneIndex(cache.ped, 11816), 0.01, 0.52, 0.13, -170.7, 80.1, 84.9, true, true, false, true, 1, true)
        end
        Wait(2000)
        
        -- Quay lại về phía xe
        SetEntityHeading(cache.ped, currentHeading)
        Wait(1000)
        
        -- Xóa prop động cơ và clear animation
        if DoesEntityExist(engineProp) then
            DeleteEntity(engineProp)
        end
        ClearPedTasks(cache.ped)
        Wait(500)
        
        -- Animation đóng nắp capo
        loadAnimDict("rcmepsilonism8")
        TaskPlayAnim(cache.ped, "rcmepsilonism8", "bag_handler_close_trunk_walk_left", 8.0, 8.0, 2500, 1, 0.0, 0, 0, 0)
        Wait(2500)
        SetVehicleDoorShut(vehicle, 4, false)
        Wait(100)
        
        -- Unfreeze xe nếu được phép
        unfreezeIfAllowed(vehicle)
        
        -- Mở khóa kho đồ
        LocalPlayer.state.invBusy = false
        
        -- Xóa toolbox prop
        if DoesEntityExist(toolboxProp) then
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        
        if repairCompleted then
            Wait(500)
            openToolboxMenu()
        else
            closeToolboxMenu()
        end
    elseif data.part == 'repairAll' then
        -- Xử lý sửa tất cả cho xe đặc biệt
        if not getHasItem(Config.repairItems.repairAll.item, Config.repairItems.repairAll.count) then 
            local itemLabel = Config.itemLabels[Config.repairItems.repairAll.item] or Config.repairItems.repairAll.item
            notify(locale('notify_missing_item') .. ' ' .. itemLabel, 'error') 
            cb(true)
            return 
        end
        
        -- Kiểm tra độ bền xe: chỉ cho sửa khi động cơ hoặc thân vỏ dưới 70%
        local engineHealth = GetVehicleEngineHealth(vehicle)
        local bodyHealth = GetVehicleBodyHealth(vehicle)
        
        if engineHealth > 700 and bodyHealth > 700 then
            notify('Xe chưa hư hỏng đủ để sửa chữa! (Cần động cơ hoặc thân vỏ dưới 70%)', 'error')
            cb(true)
            return
        end
        
        ShowNUI('setVisibleRepairMenu', false)
        
        -- Khóa kho đồ
        LocalPlayer.state.invBusy = true
        
        -- Freeze xe và lưu vị trí ban đầu
        FreezeEntityPosition(vehicle, true)
        local initialVehiclePos = GetEntityCoords(vehicle)
        local repairCancelled = false
        local repairCompleted = false
        
        -- Xóa toolbox prop trên tay khi bắt đầu sửa
        if DoesEntityExist(toolboxProp) then
            DetachEntity(toolboxProp, true, true)
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        ClearPedTasks(cache.ped)
        
        -- Tính toán vị trí chính giữa trước đầu xe
        local vehCoords = GetEntityCoords(vehicle)
        local vehHeading = GetEntityHeading(vehicle)
        local forwardVector = GetEntityForwardVector(vehicle)
        local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
        local frontDistance = maxDim.y + 0.3 -- Khoảng cách từ tâm xe đến đầu xe + 0.3m
        
        -- Vị trí đích trước đầu xe
        local targetPos = vector3(
            vehCoords.x + forwardVector.x * frontDistance,
            vehCoords.y + forwardVector.y * frontDistance,
            vehCoords.z
        )
        
        -- Bắt buộc di chuyển tới vị trí trước đầu xe (đi bộ)
        TaskGoStraightToCoord(cache.ped, targetPos.x, targetPos.y, targetPos.z, 1.0, -1, GetEntityHeading(cache.ped), 0.0)
        
        -- Thread kiểm tra kho ảng cách trong quá trình di chuyển
        CreateThread(function()
            while not repairCancelled and not repairCompleted do
                Wait(500)
                local pedPos = GetEntityCoords(cache.ped)
                local vehPos = GetEntityCoords(vehicle)
                local playerToVehicleDist = #(pedPos - vehPos)
                local vehicleMovedDist = #(vehPos - initialVehiclePos)
                
                if playerToVehicleDist > 20.0 then
                    repairCancelled = true
                    notify('Sửa xe bị hủy: Bạn đã di chuyển quá xa xe!', 'error')
                    break
                elseif vehicleMovedDist > 10.0 then
                    repairCancelled = true
                    notify('Sửa xe bị hủy: Xe đã bị di chuyển!', 'error')
                    break
                end
            end
        end)
        
        local arrived = false
        local timeout = GetGameTimer() + 10000 -- 10 giây timeout
        while not arrived and GetGameTimer() < timeout do
            local pedPos = GetEntityCoords(cache.ped)
            local dist = #(pedPos - targetPos)
            if dist < 1.0 then
                arrived = true
            end
            Wait(100)
        end
        
        if not arrived or repairCancelled then
            notify(locale('notify_error_no_vehicle'), 'error')
            repairCancelled = true
        end
        
        if repairCancelled then
            -- Mở khóa kho đồ
            LocalPlayer.state.invBusy = false
            -- Unfreeze xe nếu được phép
            unfreezeIfAllowed(vehicle)
            -- Làm hỏng engine
            TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
            -- Xóa toolbox prop
            if DoesEntityExist(toolboxProp) then
                DeleteEntity(toolboxProp)
                toolboxProp = nil
            end
            return
        end
        
        -- Dừng mọi task và set vị trí chính xác
        ClearPedTasks(cache.ped)
        SetEntityCoords(cache.ped, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
        Wait(200)
        
        -- Kiểm tra hủy bỏ
        if repairCancelled then
            LocalPlayer.state.invBusy = false
            unfreezeIfAllowed(vehicle)
            TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
            if DoesEntityExist(toolboxProp) then
                DeleteEntity(toolboxProp)
                toolboxProp = nil
            end
            return
        end
        
        -- Quay nhân vật về phía xe
        TaskTurnPedToFaceEntity(cache.ped, vehicle, 1500)
        Wait(1500)
        
        -- Animation mở nắp capo
        loadAnimDict("rcmnigel3_trunk")
        TaskPlayAnim(cache.ped, "rcmnigel3_trunk", "out_trunk_trevor", 8.0, 8.0, 2000, 1, 0.0, 0, 0, 0)
        Wait(2000)
        SetVehicleDoorOpen(vehicle, 4, false, false)
        Wait(500)
        
        -- Animation cúi xuống nhấc động cơ
        loadAnimDict("anim@heists@box_carry@")
        TaskPlayAnim(cache.ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
        
        -- Spawn prop động cơ
        loadModel(`prop_car_engine_01`)
        local engineProp = CreateObject(`prop_car_engine_01`, GetEntityCoords(cache.ped), false, false, false)
        if DoesEntityExist(engineProp) then
            AttachEntityToEntity(engineProp, cache.ped, GetPedBoneIndex(cache.ped, 11816), 0.01, 0.52, 0.13, -170.7, 80.1, 84.9, true, true, false, true, 1, true)
        end
        
        Wait(2000)
        
        -- Quay người 180 độ để thả động cơ phía sau xe
        local currentHeading = GetEntityHeading(cache.ped)
        SetEntityHeading(cache.ped, currentHeading + 180)
        Wait(1000)
        
        -- Thả động cơ xuống phía trước mặt player (xa khỏi xe)
        ClearPedTasks(cache.ped)
        DetachEntity(engineProp, true, true)
        local dropPos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.0, -0.5)
        SetEntityCoords(engineProp, dropPos.x, dropPos.y, dropPos.z, false, false, false, false)
        PlaceObjectOnGroundProperly(engineProp)
        Wait(500)
        
        -- Kiểm tra hủy bỏ
        if repairCancelled then
            if DoesEntityExist(engineProp) then DeleteEntity(engineProp) end
            ClearPedTasks(cache.ped)
            LocalPlayer.state.invBusy = false
            unfreezeIfAllowed(vehicle)
            TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
            if DoesEntityExist(toolboxProp) then
                DeleteEntity(toolboxProp)
                toolboxProp = nil
            end
            return
        end
        
        -- Bắt đầu sửa động cơ tại chỗ (sửa cả động cơ và thân vỏ)
        if progressBar(locale('progress_repair_engine'), Config.times.repairEngine, { car = true, walk = true }, { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 6 }, { model = `w_me_wrench`, pos = vec3(0.071, -0.017, 0.036), rot = vec3(-121.24, -10.43, 6.64) }) then
            -- Animation hàn (ngồi xuống)
            TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_WELDING", 0, true)
            Wait(5000)
            ClearPedTasks(cache.ped)
            
            -- Kiểm tra hủy bỏ
            if repairCancelled then
                if DoesEntityExist(engineProp) then DeleteEntity(engineProp) end
                LocalPlayer.state.invBusy = false
                unfreezeIfAllowed(vehicle)
                TriggerServerEvent('mt_workshops:server:damageVehicleEngine', VehToNet(vehicle), cache.serverId)
                if DoesEntityExist(toolboxProp) then
                    DeleteEntity(toolboxProp)
                    toolboxProp = nil
                end
                return
            end
            
            -- Animation sửa chữa cơ khí (ngồi xuống)
            loadAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
            TaskPlayAnim(cache.ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, 5000, 0, 0.0, false, false, false)
            Wait(5000)
            ClearPedTasks(cache.ped)
            
            -- Sửa cả động cơ và thân vỏ
            TriggerServerEvent('mt_workshops:server:fixVehicleEngine', VehToNet(vehicle), cache.serverId)
            TriggerServerEvent('mt_workshops:server:fixVehicleBody', VehToNet(vehicle), cache.serverId)
            
            -- Gửi Discord log
            sendRepairLog("repairAll", vehicle)
            
            lib.callback.await('mt_workshops:server:removeItem', false, Config.repairItems.repairAll.item, Config.repairItems.repairAll.count)
            
            -- Đánh dấu sửa xe hoàn thành để dừng thread kiểm tra khoảng cách
            repairCompleted = true
        end
        
        -- Nhặt động cơ lên lại
        loadAnimDict("anim@heists@box_carry@")
        TaskPlayAnim(cache.ped, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 50, 0, false, false, false)
        
        -- Gắn lại prop động cơ vào tay
        if DoesEntityExist(engineProp) then
            AttachEntityToEntity(engineProp, cache.ped, GetPedBoneIndex(cache.ped, 11816), 0.01, 0.52, 0.13, -170.7, 80.1, 84.9, true, true, false, true, 1, true)
        end
        Wait(2000)
        
        -- Quay lại về phía xe
        SetEntityHeading(cache.ped, currentHeading)
        Wait(1000)
        
        -- Xóa prop động cơ và clear animation
        if DoesEntityExist(engineProp) then
            DeleteEntity(engineProp)
        end
        ClearPedTasks(cache.ped)
        Wait(500)
        
        -- Animation đóng nắp capo
        loadAnimDict("rcmepsilonism8")
        TaskPlayAnim(cache.ped, "rcmepsilonism8", "bag_handler_close_trunk_walk_left", 8.0, 8.0, 2500, 1, 0.0, 0, 0, 0)
        Wait(2500)
        SetVehicleDoorShut(vehicle, 4, false)
        Wait(100)
        
        -- Unfreeze xe nếu được phép
        unfreezeIfAllowed(vehicle)
        
        -- Mở khóa kho đồ
        LocalPlayer.state.invBusy = false
        
        -- Xóa toolbox prop
        if DoesEntityExist(toolboxProp) then
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
    elseif data.part == 'body' then
        local bodyHealth = GetVehicleBodyHealth(vehicle)
        local requiredCount = getRepairItemCount(bodyHealth, 1000.0)
        if requiredCount <= 0 then
            notify('Thân vỏ không cần sửa chữa!', 'error')
            cb(true)
            return
        end
        if not getHasItem(Config.repairItems.body.item, requiredCount) then 
            local itemLabel = Config.itemLabels[Config.repairItems.body.item] or Config.repairItems.body.item
            notify(locale('notify_missing_item') .. ' ' .. requiredCount .. 'x ' .. itemLabel, 'error') 
            cb(true)
            return 
        end
        ShowNUI('setVisibleRepairMenu', false)
        Wait(1000) -- Chờ 1s ngay sau khi bấm nút sửa trong UI trước khi bắt đầu
        
        -- Khóa kho đồ
        LocalPlayer.state.invBusy = true
        
        -- Xóa toolbox prop trên tay khi bắt đầu sửa
        if DoesEntityExist(toolboxProp) then
            DetachEntity(toolboxProp, true, true)
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        ClearPedTasks(cache.ped)
        
        -- Freeze xe và lưu vị trí ban đầu
        FreezeEntityPosition(vehicle, true)
        local initialVehiclePos = GetEntityCoords(vehicle)
        local repairCancelled = false
        
        -- Kiểm tra xem xe có cửa sau không (door ID 2)
        local hasRearDoors = GetIsDoorValid(vehicle, 2)
        local doorsToRepair = {}
        
        if not hasRearDoors then
            -- Xe 2 cửa: chỉ trái trước và phải trước
            doorsToRepair = {
                {id = 0, bone = "door_dside_f", name = "cửa trái trước"},
                {id = 1, bone = "door_pside_f", name = "cửa phải trước"}
            }
        else
            -- Xe 4 cửa: Sắp xếp theo vòng tròn quanh xe để tránh kẹt/vướng xe khi tự đi
            doorsToRepair = {
                {id = 0, bone = "door_dside_f", name = "cửa trái trước"},
                {id = 2, bone = "door_dside_r", name = "cửa trái sau"},
                {id = 3, bone = "door_pside_r", name = "cửa phải sau"},
                {id = 1, bone = "door_pside_f", name = "cửa phải trước"}
            }
        end
        
        -- Loop qua từng cửa để sửa
        for doorIndex, door in ipairs(doorsToRepair) do
            -- Tính toán vị trí cửa
            local vehPos = GetEntityCoords(vehicle)
            local vehHeading = GetEntityHeading(vehicle)
            local vehForward = GetEntityForwardVector(vehicle)
            local vehRight = vector3(vehForward.y, -vehForward.x, 0.0)
            
            local doorPos
            if door.id == 0 then
                doorPos = vector3(vehPos.x + vehForward.x * 0.5 - vehRight.x * 1.5, vehPos.y + vehForward.y * 0.5 - vehRight.y * 1.5, vehPos.z)
            elseif door.id == 1 then
                doorPos = vector3(vehPos.x + vehForward.x * 0.5 + vehRight.x * 1.5, vehPos.y + vehForward.y * 0.5 + vehRight.y * 1.5, vehPos.z)
            elseif door.id == 2 then
                doorPos = vector3(vehPos.x - vehForward.x * 0.5 - vehRight.x * 1.5, vehPos.y - vehForward.y * 0.5 - vehRight.y * 1.5, vehPos.z)
            elseif door.id == 3 then
                doorPos = vector3(vehPos.x - vehForward.x * 0.5 + vehRight.x * 1.5, vehPos.y - vehForward.y * 0.5 + vehRight.y * 1.5, vehPos.z)
            end
            
            local arrived = false
            
            -- Tự động di chuyển đến và tự động sửa cho mọi cửa
            exports["orbit-ui"]:Show("Mechanic Tool", "Đang di chuyển tới vị trí " .. door.name)
            
            -- Tắt va chạm tạm thời giữa ped và xe để không bị kẹt khi đi vòng
            SetEntityNoCollisionEntity(cache.ped, vehicle, false)
            
            -- Cho nhân vật tự đi đến cửa
            TaskGoStraightToCoord(cache.ped, doorPos.x, doorPos.y, doorPos.z, 1.0, -1, GetEntityHeading(cache.ped), 0.0)
            
            local timeout = GetGameTimer() + 10000 -- 10 giây timeout
            while not arrived and not repairCancelled and GetGameTimer() < timeout do
                local pedPos = GetEntityCoords(cache.ped)
                local dist = #(pedPos - doorPos)
                if dist < 1.2 then
                    arrived = true
                end
                
                -- Kiểm tra khoảng cách và xe di chuyển
                local vehPos = GetEntityCoords(vehicle)
                local playerToVehicleDist = #(pedPos - vehPos)
                local vehicleMovedDist = #(vehPos - initialVehiclePos)
                if playerToVehicleDist > 20.0 then
                    repairCancelled = true
                    notify('Sửa xe bị hủy: Bạn đã di chuyển quá xa xe!', 'error')
                    break
                elseif vehicleMovedDist > 10.0 then
                    repairCancelled = true
                    notify('Sửa xe bị hủy: Xe đã bị di chuyển!', 'error')
                    break
                end
                
                Wait(100)
            end
            
            -- Bật lại va chạm khi đã đến nơi hoặc bị hủy
            SetEntityNoCollisionEntity(cache.ped, vehicle, true)
            
            if not arrived and not repairCancelled then
                -- Nếu hết timeout mà chưa tới, ép vị trí tới luôn để tiếp tục
                arrived = true
            end
            
            -- Nếu bị hủy, break khỏi vòng lặp sửa cửa
            if repairCancelled then
                SetEntityNoCollisionEntity(cache.ped, vehicle, true)
                break
            end
            
            -- Tắt outline trước khi bắt đầu sửa cửa
            -- SetEntityDrawOutline(vehicle, false)
            
            -- Quay về phía xe
            TaskTurnPedToFaceEntity(cache.ped, vehicle, 1000)
            Wait(1000)
            
            -- Mở và làm broken cửa này
            SetVehicleDoorOpen(vehicle, door.id, false, false)
            Wait(300)
            SetVehicleDoorBroken(vehicle, door.id, true)
            Wait(500)
            
            -- Animation hàn
            TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_WELDING", 0, true)
            Wait(5000)
            ClearPedTasks(cache.ped)
            
            -- Progress bar sửa cửa này
            progressBar(locale('progress_repair_body'), Config.times.repairBody, { car = true, walk = true }, { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 50 }, { model = 'imp_prop_impexp_car_door_04a', bone = 57005, pos = vec3(0.31, 0.36, -0.92), rot = vec3(-97.5, -26.0, 29.5) })
            
            -- Tạm thời gắn cửa lại bằng cách fix xe
            local engineHealth = GetVehicleEngineHealth(vehicle)
            local petrolHealth = GetVehiclePetrolTankHealth(vehicle)
            local currentFuel = GetVehicleFuelLevel(vehicle)
            SetVehicleFixed(vehicle)
            SetVehicleEngineHealth(vehicle, engineHealth)
            SetVehiclePetrolTankHealth(vehicle, petrolHealth)
            SetVehicleFuelLevel(vehicle, currentFuel)
            Wait(200)
            
            -- Đóng cửa lại
            SetVehicleDoorShut(vehicle, door.id, false)
            Wait(500)
            
            -- Notify hoàn thành cửa này
            exports["orbit-ui"]:Show("Mechanic Tool", "Đã sửa xong cửa số " .. doorIndex)
            Wait(2000)
        end
        
        -- Unfreeze xe nếu được phép
        unfreezeIfAllowed(vehicle)
        
        if repairCancelled then
            -- Hủy sửa: Set body health về 300 và break tất cả cửa
            TriggerServerEvent('mt_workshops:server:damageVehicleBody', VehToNet(vehicle), cache.serverId)
            exports["orbit-ui"]:Show("Mechanic Tool", "Xe đã bị hư hỏng do sửa chữa bị gián đoạn!")
            Wait(3000)
        else
            -- Hoàn thành: Trigger server để fix toàn bộ và remove item
            TriggerServerEvent('mt_workshops:server:fixVehicleBody', VehToNet(vehicle), cache.serverId)
            
            -- Gửi Discord log
            sendRepairLog("body", vehicle)
            
            lib.callback.await('mt_workshops:server:removeItem', false, Config.repairItems.body.item, requiredCount)
            
            -- Đóng tất cả cánh cửa
            for _, door in ipairs(doorsToRepair) do
                SetVehicleDoorShut(vehicle, door.id, false)
            end
            
            exports["orbit-ui"]:Show("Mechanic Tool", "Đã sửa xong toàn bộ thân xe!")
            Wait(2000)
        end
        
        -- Close orbit-ui sau khi hoàn thành hoặc hủy
        exports["orbit-ui"]:Close()
        
        -- Mở khóa kho đồ
        LocalPlayer.state.invBusy = false
        
        -- Xóa toolbox prop
        if DoesEntityExist(toolboxProp) then
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        
        if not repairCancelled then
            Wait(500)
            openToolboxMenu()
        else
            closeToolboxMenu()
        end
        
        Wait(100)
    elseif data.part == 'tank' then
        if not getHasItem(Config.repairItems.tank.item, Config.repairItems.tank.count) then 
            local itemLabel = Config.itemLabels[Config.repairItems.tank.item] or Config.repairItems.tank.item
            notify(locale('notify_missing_item') .. ' ' .. itemLabel, 'error') 
            cb(true)
            return 
        end
        ShowNUI('setVisibleRepairMenu', false)
        
        -- Xóa toolbox prop trên tay khi bắt đầu sửa
        if DoesEntityExist(toolboxProp) then
            DetachEntity(toolboxProp, true, true)
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        ClearPedTasks(cache.ped)
        
        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped)+180)
        if progressBar(locale('progress_repair_tank'), Config.times.repairTank, { car = true, walk = true }, { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base', flag = 6 }, { model = `w_me_wrench`, pos = vec3(0.071, -0.017, 0.036), rot = vec3(-121.24, -10.43, 6.64) }) then
            TriggerServerEvent('mt_workshops:server:fixVehicleTank', VehToNet(vehicle), cache.serverId)
            lib.callback.await('mt_workshops:server:removeItem', false, Config.repairItems.tank.item, Config.repairItems.tank.count)
        end
        local pCoords = GetEntityCoords(cache.ped)
        SetEntityCoords(cache.ped, pCoords.x, pCoords.y, pCoords.z+0.5, true, false, false, false)
        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped)-180)
        
        -- Xóa toolbox prop
        if DoesEntityExist(toolboxProp) then
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        
        Wait(100)
    elseif data.part == 'wash' then
        if not getHasItem(Config.repairItems.wash.item, Config.repairItems.wash.count) then 
            local itemLabel = Config.itemLabels[Config.repairItems.wash.item] or Config.repairItems.wash.item
            notify(locale('notify_missing_item') .. ' ' .. itemLabel, 'error') 
            cb(true)
            return 
        end
        ShowNUI('setVisibleRepairMenu', false)
        
        -- Khóa kho đồ
        LocalPlayer.state.invBusy = true
        
        -- Xóa toolbox prop trên tay khi bắt đầu rửa xe
        if DoesEntityExist(toolboxProp) then
            DetachEntity(toolboxProp, true, true)
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        ClearPedTasks(cache.ped)
        Wait(200)
        
        -- Quay về phía xe
        TaskTurnPedToFaceEntity(cache.ped, vehicle, 1000)
        Wait(1000)
        
        -- Animation lau xe + progressBar 30 giây
        local washDuration = (Config.times and Config.times.wash) or 30000
        if progressBar(locale('progress_wash'), washDuration, { car = true, walk = true }, { dict = 'timetable@floyd@clean_kitchen@base', clip = 'base', flag = 6 }, { bone = 28422, model = 'prop_sponge_01', pos = vec3(0.0, 0.0, -0.01), rot = vec3(90.0, 0.0, 0.0) }) then
            TriggerServerEvent('mt_workshops:server:washVehicle', VehToNet(vehicle), cache.serverId)
            sessionWashed = true
            
            -- Gửi Discord log
            sendRepairLog("wash", vehicle)
            
            lib.callback.await('mt_workshops:server:removeItem', false, Config.repairItems.wash.item, Config.repairItems.wash.count)
        end
        
        -- Mở khóa kho đồ
        LocalPlayer.state.invBusy = false
        
        -- Dọn dẹp animation & toolbox prop
        ClearPedTasks(cache.ped)
        if DoesEntityExist(toolboxProp) then
            DeleteEntity(toolboxProp)
            toolboxProp = nil
        end
        
        Wait(100)
    end
    cb(true)
end)

RegisterNetEvent('mt_workshops:client:fixVehicleBody', function(vehicle)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    vehicle = NetToVeh(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local petrolHealth = GetVehiclePetrolTankHealth(vehicle)
    local currentFuel = GetVehicleFuelLevel(vehicle)
    SetVehicleFixed(vehicle)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleEngineHealth(vehicle, engineHealth)
    SetVehiclePetrolTankHealth(vehicle, petrolHealth)
    SetVehicleFuelLevel(vehicle, currentFuel)
    if cache.serverId == player then
        lib.callback.await('mt_workshops:server:saveVehicleMods', false, NetToVeh(vehicle), getVehicleMods(NetToVeh(vehicle)))
    end
end)

RegisterNetEvent('mt_workshops:client:damageVehicleBody', function(vehicle)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    vehicle = NetToVeh(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local petrolHealth = GetVehiclePetrolTankHealth(vehicle)
    local currentFuel = GetVehicleFuelLevel(vehicle)
    
    -- Set body health về 300
    SetVehicleBodyHealth(vehicle, 300.0)
    
    -- Break tất cả cửa
    local doorCount = GetNumberOfVehicleDoors(vehicle)
    if doorCount == 2 then
        SetVehicleDoorBroken(vehicle, 0, true)
        SetVehicleDoorBroken(vehicle, 1, true)
    else
        SetVehicleDoorBroken(vehicle, 0, true)
        SetVehicleDoorBroken(vehicle, 1, true)
        SetVehicleDoorBroken(vehicle, 2, true)
        SetVehicleDoorBroken(vehicle, 3, true)
    end
    
    -- Giữ nguyên engine, tank, fuel
    SetVehicleEngineHealth(vehicle, engineHealth)
    SetVehiclePetrolTankHealth(vehicle, petrolHealth)
    SetVehicleFuelLevel(vehicle, currentFuel)
end)

RegisterNetEvent('mt_workshops:client:fixVehicleEngine', function(vehicle)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    SetVehicleEngineHealth(NetToVeh(vehicle), 1000.0)
    if cache.serverId == player then
        lib.callback.await('mt_workshops:server:saveVehicleMods', false, NetToVeh(vehicle), getVehicleMods(NetToVeh(vehicle)))
    end
end)

RegisterNetEvent('mt_workshops:client:damageVehicleEngine', function(vehicle)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    SetVehicleEngineHealth(NetToVeh(vehicle), 300.0)
end)

RegisterNetEvent('mt_workshops:client:fixVehicleTank', function(vehicle)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    SetVehiclePetrolTankHealth(NetToVeh(vehicle), 1000.0)
    if cache.serverId == player then
        lib.callback.await('mt_workshops:server:saveVehicleMods', false, NetToVeh(vehicle), getVehicleMods(NetToVeh(vehicle)))
    end
end)

RegisterNetEvent('mt_workshops:client:washVehicle', function(vehicle)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    SetVehicleDirtLevel(NetToVeh(vehicle), 0.0)
end)

RegisterNetEvent('mt_workshops:client:useRepairInvoice', function(slot, metadata)
    local plate = metadata.plate or "Không rõ"
    local body = math.min(100, math.max(0, tonumber(metadata.body_repaired) or 0))
    local engine = math.min(100, math.max(0, tonumber(metadata.engine_repaired) or 0))
    local washed = metadata.washed or false
    local bodyPrice = (Config.hoadon and Config.hoadon.pricePerPercentBody) or 20
    local enginePrice = (Config.hoadon and Config.hoadon.pricePerPercentEngine) or 20
    local totalAmount = (body * bodyPrice) + (engine * enginePrice)
    if washed then totalAmount = totalAmount + 1000 end

    lib.callback('mt_workshops:server:makePlayersList', false, function(onlineList)
        local nearbyList = {}
        if not onlineList then 
            notify("Không tìm thấy người chơi nào trực tuyến!", "error") 
            return 
        end

        local playerCoords = GetEntityCoords(cache.ped)
        local nearbyPeds = getPlayersFromCoords(playerCoords, 3.0)
        
        for _, v in pairs(nearbyPeds) do
            local targetServerId = GetPlayerServerId(v)
            if targetServerId ~= cache.serverId then
                local targetPed = GetPlayerPed(v)
                local dist = #(GetEntityCoords(targetPed) - playerCoords)
                for i = 1, #onlineList do
                    if onlineList[i].value == targetServerId then
                        nearbyList[#nearbyList+1] = { 
                            value = targetServerId, 
                            label = tostring(onlineList[i].text..' ('..math.floor(dist+0.05)..'m)') 
                        }
                    end
                end
            end
        end

        if #nearbyList == 0 then
            notify("Không tìm thấy người chơi nào trong bán kính 3m!", "error")
            return
        end

        local input = lib.inputDialog("HÓA ĐƠN SỬA XE", {
            { type = "input", label = "Hóa đơn sửa phương tiện (Biển số)", default = plate, disabled = true },
            { type = "input", label = "Thân vỏ đã sửa", default = tostring(body).."%", disabled = true },
            { type = "input", label = "Động cơ đã sửa", default = tostring(engine).."%", disabled = true },
            { type = "input", label = "Rửa xe", default = washed and "Có (+1000$)" or "Không", disabled = true },
            { type = "input", label = "Tổng hóa đơn", default = tostring(totalAmount).."$", disabled = true },
            { type = "select", required = true, label = "Người nhận", default = nearbyList[1].value, options = nearbyList },
        })

        if input and input[6] then
            local targetServerId = input[6]
            TriggerServerEvent('mt_workshops:server:sendRepairInvoiceToPlayer', targetServerId, plate, body, engine, totalAmount, slot)
        end
    end)
end)

RegisterNetEvent('mt_workshops:client:receiveRepairInvoice', function(billerSource, billerName, plate, body, engine, totalAmount, slot, discounts)
    discounts = discounts or {}
    
    local options = {
        { type = "input", label = "Hóa đơn sửa phương tiện (Biển số)", default = plate, disabled = true },
        { type = "input", label = "Thân vỏ đã sửa", default = tostring(body).."%", disabled = true },
        { type = "input", label = "Động cơ đã sửa", default = tostring(engine).."%", disabled = true },
        { type = "input", label = "Tổng hóa đơn", default = tostring(totalAmount).."$", disabled = true },
        { type = "input", label = "Người gửi", default = string.format("%s [%d]", billerName, billerSource), disabled = true },
    }
    
    local discountOptions = {}
    if discounts['phieu_giam_gia_10'] then
        discountOptions[#discountOptions + 1] = { name = 'phieu_giam_gia_10', label = 'Phiếu giảm giá 10%', percent = 10 }
    end
    if discounts['phieu_giam_gia_20'] then
        discountOptions[#discountOptions + 1] = { name = 'phieu_giam_gia_20', label = 'Phiếu giảm giá 20%', percent = 20 }
    end
    if discounts['phieu_giam_gia_30'] then
        discountOptions[#discountOptions + 1] = { name = 'phieu_giam_gia_30', label = 'Phiếu giảm giá 30%', percent = 30 }
    end
    if discounts['phieu_giam_gia_50'] then
        discountOptions[#discountOptions + 1] = { name = 'phieu_giam_gia_50', label = 'Phiếu giảm giá 50%', percent = 50 }
    end
    
    local checkboxStartIndex = #options + 1
    for i = 1, #discountOptions do
        options[#options + 1] = {
            type = "checkbox",
            label = "Sử dụng " .. discountOptions[i].label,
            default = false
        }
    end
    
    local input = lib.inputDialog("YÊU CẦU THANH TOÁN HÓA ĐƠN SỬA XE", options)
    
    if input then
        local chosenDiscount = nil
        local chosenPercent = 0
        for i = 1, #discountOptions do
            local checkboxVal = input[checkboxStartIndex + i - 1]
            if checkboxVal then
                if discountOptions[i].percent > chosenPercent then
                    chosenPercent = discountOptions[i].percent
                    chosenDiscount = discountOptions[i].name
                end
            end
        end
        
        TriggerServerEvent('mt_workshops:server:payRepairInvoice', billerSource, totalAmount, slot, chosenDiscount)
    else
        TriggerServerEvent('mt_workshops:server:rejectRepairInvoice', billerSource)
    end
end)