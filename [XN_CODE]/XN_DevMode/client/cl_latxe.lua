local QBCore = exports['qb-core']:GetCoreObject()

-- Kiểm tra nếu xe đang bị lật ngược
local function IsVehicleUpsideDown(vehicle)
    local roll = GetEntityRoll(vehicle)
    return math.abs(roll) > 75.0
end

-- Tạo ox_target cho tất cả xe
exports.ox_target:addGlobalVehicle({
    {
        name = 'flip_vehicle',
        icon = 'fas fa-undo',
        label = 'Lật xe',
        distance = 3.0,
        onSelect = function(data)
            FlipVehicle(data.entity)
        end,
        canInteract = function(entity, distance, coords, name)
            return IsVehicleUpsideDown(entity) and not IsPedInVehicle(PlayerPedId(), entity, false)
        end
    }
})

-- Hàm lật xe
function FlipVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify('Không tìm thấy xe', 'error')
        return
    end
    
    if not IsVehicleUpsideDown(vehicle) then
        QBCore.Functions.Notify('Xe không bị lật ngược', 'primary')
        return
    end
    
    local playerPed = PlayerPedId()
    local vehicleCoords = GetEntityCoords(vehicle)
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Kiểm tra khoảng cách
    if #(vehicleCoords - playerCoords) > 5.0 then
        QBCore.Functions.Notify('Bạn đang ở quá xa xe', 'error')
        return
    end
    
    -- Bắt đầu animation
    TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_PUSH_PULL_FRONT', 0, true)
    
    -- Chạy progress bar
    if lib.progressBar then
        local success = lib.progressBar({
        duration = 10000, -- 10 giây
        label = 'Đang lật xe...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        }
    })
    
    -- Dừng animation
    ClearPedTasks(playerPed)
    
    if success then
        -- Lật xe
        local vehicleHeading = GetEntityHeading(vehicle)
        local vehicleCoords = GetEntityCoords(vehicle)
        
        -- Tính toán rotation mới để xe đứng thẳng
        local newRotation = vector3(0.0, 0.0, vehicleHeading)
        
        -- Set xe về vị trí đứng thẳng
        SetEntityRotation(vehicle, newRotation.x, newRotation.y, newRotation.z, 2, true)
        
        -- Đặt xe lên một chút để tránh bị kẹt trong đất
        local groundZ = vehicleCoords.z
        for i = 1, 10 do
            local foundGround, groundHeight = GetGroundZFor_3dCoord(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + i, false)
            if foundGround then
                groundZ = groundHeight
                break
            end
        end
        
        SetEntityCoords(vehicle, vehicleCoords.x, vehicleCoords.y, groundZ + 1.0, false, false, false, true)
        
        -- Đặt xe xuống đất một cách tự nhiên
        SetVehicleOnGroundProperly(vehicle)
        
        QBCore.Functions.Notify('Đã lật xe thành công!', 'success')
    else
        QBCore.Functions.Notify('Đã hủy việc lật xe', 'primary')
    end
    else
        -- Fallback nếu ox_lib không có
        QBCore.Functions.Notify('Đang lật xe...', 'primary')
        Wait(10000) -- Đợi 10 giây thay vì progress bar
        
        -- Lật xe
        local vehicleHeading = GetEntityHeading(vehicle)
        local vehicleCoords = GetEntityCoords(vehicle)
        
        -- Tính toán rotation mới để xe đứng thẳng
        local newRotation = vector3(0.0, 0.0, vehicleHeading)
        
        -- Set xe về vị trí đứng thẳng
        SetEntityRotation(vehicle, newRotation.x, newRotation.y, newRotation.z, 2, true)
        
        -- Đặt xe lên một chút để tránh bị kẹt trong đất
        local groundZ = vehicleCoords.z
        for i = 1, 10 do
            local foundGround, groundHeight = GetGroundZFor_3dCoord(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + i, false)
            if foundGround then
                groundZ = groundHeight
                break
            end
        end
        
        SetEntityCoords(vehicle, vehicleCoords.x, vehicleCoords.y, groundZ + 1.0, false, false, false, true)
        
        -- Đặt xe xuống đất một cách tự nhiên
        SetVehicleOnGroundProperly(vehicle)
        
        QBCore.Functions.Notify('Đã lật xe thành công!', 'success')
    end
    
    -- Dừng animation
    ClearPedTasks(playerPed)
end

-- Event để lật xe từ server (nếu cần)
RegisterNetEvent('flipvehicle:client:flipVehicle', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if vehicle and DoesEntityExist(vehicle) then
        FlipVehicle(vehicle)
    end
end)

