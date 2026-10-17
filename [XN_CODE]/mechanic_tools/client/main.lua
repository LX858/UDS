-- Function để lấy control key từ string (không cần thiết nữa với ox_lib)
function GetControlKey(keyString)
    local keyMap = {
        ['1'] = 157, -- INPUT_SELECT_CHARACTER_MICHAEL (1 key)
        ['2'] = 158, -- INPUT_SELECT_CHARACTER_FRANKLIN (2 key)
        ['3'] = 160  -- INPUT_SELECT_CHARACTER_TREVOR (3 key)
    }
    return keyMap[keyString] or 0
end

-- Function để vẽ text trên màn hình
function DrawText2D(x, y, text, scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(scale or 1.0, scale or 1.0)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Function để tìm xe gần nhất
local function getClosestVehicle(coords, maxDistance)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = maxDistance or 5.0
    
    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end
    
    return closestVehicle
end

-- Function lấy tên model xe từ hash
local function getVehicleModelName(vehicle)
    local model = GetEntityModel(vehicle)
    -- Loop qua config và so sánh hash
    for vehicleName, _ in pairs(Config.DepartmentVehicles) do
        if joaat(vehicleName) == model then
            return vehicleName
        end
    end
    return nil
end

-- Function kiểm tra xe có bị hỏng không (hỗ trợ cả xe xăng và xe điện)
local function isVehicleDamaged(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local isDriveable = IsVehicleDriveable(vehicle, false)
    
    return engineHealth < 1000.0 or bodyHealth < 1000.0 or not isDriveable
end

-- Function kiểm tra xe có thuộc ban ngành không
local function isDepartmentVehicle(vehicle)
    local modelName = getVehicleModelName(vehicle)
    return modelName ~= nil
end

-- Function để sửa xe ban ngành
local function repairDepartmentVehicle(targetEntity)
    -- Kiểm tra điều kiện (server sẽ validate)
    local canRepair, reason = lib.callback.await('mechanic_tools:canRepairDepartmentVehicle', false)
    if not canRepair then
        return
    end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = (targetEntity and DoesEntityExist(targetEntity)) and targetEntity or getClosestVehicle(coords, Config.RepairDistance)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Sửa Xe Ban Ngành',
            description = Config.Locale['vehicle_not_found'],
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra xe có thuộc ban ngành không
    local modelName = getVehicleModelName(vehicle)
    local vehicleInfo = Config.DepartmentVehicles[modelName]
    
    if not vehicleInfo then
        lib.notify({
            title = 'Sửa Xe Ban Ngành',
            description = Config.Locale['not_department_vehicle'],
            type = 'error'
        })
        return
    end
    
    -- Bắt đầu mini game
    local miniGameSuccess = lib.skillCheck({'easy', 'easy', 'easy'}, {'1', '2', '3'})
    
    if not miniGameSuccess then
        lib.notify({
            title = 'Mini Game',
            description = Config.Locale['minigame_failed'],
            type = 'error'
        })
        return
    end
    
    lib.notify({
        title = 'Mini Game', 
        description = Config.Locale['minigame_success'],
        type = 'success'
    })
    
    -- Progress bar với animation
    if lib.progressBar({
        duration = Config.ProgressDuration,
        label = Config.Locale['repairing'],
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            mouse = false,
            combat = true,
        },
        anim = {
            dict = "amb@world_human_vehicle_mechanic@male@base",
            clip = "base",
            flag = 0,
        },
        prop = {
            model = "prop_tool_screwdvr01",
            bone = 57005,
            pos = vec3(0.02, 0.02, -0.02),
            rot = vec3(0.0, 0.0, 0.0),
        },
    }) then
        -- Sửa xe thành công
        TriggerServerEvent('mechanic_tools:repairDepartmentVehicle', NetworkGetNetworkIdFromEntity(vehicle), modelName)
        lib.notify({
            title = 'Sửa Xe Ban Ngành',
            description = Config.Locale['repair_success'],
            type = 'success'
        })
    else
        lib.notify({
            title = 'Sửa Xe Ban Ngành',
            description = Config.Locale['repair_cancelled'],
            type = 'info'
        })
    end
end

-- Function để sửa xe
local function repairVehicle(targetEntity)
    -- Kiểm tra có repair kit không (server sẽ tự notify nếu có mechanic hoặc không có repair kit)
    local hasItem = lib.callback.await('mechanic_tools:hasRepairKit', false)
    if not hasItem then
        return
    end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = (targetEntity and DoesEntityExist(targetEntity)) and targetEntity or getClosestVehicle(coords, Config.RepairDistance)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        lib.notify({
            title = 'Mechanic Tools',
            description = Config.Locale['vehicle_not_found'],
            type = 'error'
        })
        return
    end
        
    -- Bắt đầu mini game sử dụng ox_lib skill check
    local miniGameSuccess = lib.skillCheck({'easy', 'easy', 'easy'}, {'1', '2', '3'})
    
    if not miniGameSuccess then
        lib.notify({
            title = 'Mini Game',
            description = Config.Locale['minigame_failed'],
            type = 'error'
        })
        return
    end
    
    lib.notify({
        title = 'Mini Game', 
        description = Config.Locale['minigame_success'],
        type = 'success'
    })
    
    -- Nếu mini game thành công, tiến hành sửa xe
    -- Sử dụng ox_lib progressbar với animation mechanic
    if lib.progressBar({
        duration = Config.ProgressDuration,
        label = Config.Locale['repairing'],
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            mouse = false,
            combat = true,
        },
        anim = {
            dict = "amb@world_human_vehicle_mechanic@male@base",
            clip = "base",
            flag = 0,
        },
        prop = {
            model = "prop_tool_screwdvr01",
            bone = 57005,
            pos = vec3(0.02, 0.02, -0.02),
            rot = vec3(0.0, 0.0, 0.0),
        },
    }) then
        -- Sửa xe thành công
        TriggerServerEvent('mechanic_tools:repairVehicle', NetworkGetNetworkIdFromEntity(vehicle))
        lib.notify({
            title = 'Mechanic Tools',
            description = Config.Locale['repair_success'],
            type = 'success'
        })
    else
        -- Hủy sửa xe
        lib.notify({
            title = 'Mechanic Tools',
            description = Config.Locale['repair_cancelled'],
            type = 'info'
        })
    end
end

-- Tạo target cho engine bone
CreateThread(function()
    Wait(1000)
    
    -- Sử dụng ox_target để target engine bones - Sửa xe thường & xe điện
    exports.ox_target:addGlobalVehicle({
        {
            name = 'repair_vehicle',
            icon = 'fas fa-wrench',
            label = 'Sửa xe',
            bones = Config.EngineBones,
            distance = Config.RepairDistance,
            onSelect = function(data)
                repairVehicle(data.entity)
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return isVehicleDamaged(entity)
            end
        },
        {
            name = 'repair_department_vehicle',
            icon = 'fas fa-ambulance',
            label = 'Sửa xe ban ngành',
            bones = Config.EngineBones,
            distance = Config.RepairDistance,
            onSelect = function(data)
                repairDepartmentVehicle(data.entity)
            end,
            canInteract = function(entity, distance, coords, name, bone)
                if not isVehicleDamaged(entity) then
                    return false
                end
                
                -- Kiểm tra xe có thuộc danh sách ban ngành không
                return isDepartmentVehicle(entity)
            end
        }
    })
end)

-- Event để sửa xe từ server
RegisterNetEvent('mechanic_tools:repairVehicleClient', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if DoesEntityExist(vehicle) then
        -- Khôi phục engine health về 100%
        SetVehicleEngineHealth(vehicle, 1000.0)
        
        -- Khôi phục body health về 100%
        SetVehicleBodyHealth(vehicle, 1000.0)
        
        -- Reset trạng thái xe bị vô hiệu hóa
        SetVehicleUndriveable(vehicle, false)
        
        -- Sửa tất cả các bộ phận bị hỏng
        SetVehicleFixed(vehicle)
    end
end)
