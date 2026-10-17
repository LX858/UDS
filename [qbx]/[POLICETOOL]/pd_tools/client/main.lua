local frozenVehicles = {}
local vehicleShields = {}

-- Khởi tạo ox_target cho xe nkscout
CreateThread(function()
    Wait(1000) -- Đợi các resource load xong
    
    exports.ox_target:addModel('nkscout', {
        {
            name = 'freeze_vehicle',
            icon = 'fas fa-snowflake',
            label = 'Đóng băng xe',
            distance = 3.0,
            canInteract = function(entity, distance, coords, name, bone)
                return not frozenVehicles[entity]
            end,
            onSelect = function(data)
                FreezeVehicle(data.entity)
            end
        },
        {
            name = 'unfreeze_vehicle',
            icon = 'fas fa-fire',
            label = 'Bỏ đóng băng xe',
            distance = 3.0,
            canInteract = function(entity, distance, coords, name, bone)
                return frozenVehicles[entity] ~= nil
            end,
            onSelect = function(data)
                UnfreezeVehicle(data.entity)
            end
        },
        {
            name = 'create_vehicle_shield',
            icon = 'fas fa-shield-alt',
            label = 'Tạo khiên bảo vệ',
            distance = 3.0,
            canInteract = function(entity, distance, coords, name, bone)
                return not vehicleShields[entity]
            end,
            onSelect = function(data)
                CreateVehicleShield(data.entity)
            end
        },
        {
            name = 'remove_vehicle_shield',
            icon = 'fas fa-shield',
            label = 'Xóa khiên bảo vệ',
            distance = 3.0,
            canInteract = function(entity, distance, coords, name, bone)
                return vehicleShields[entity] ~= nil
            end,
            onSelect = function(data)
                RemoveVehicleShield(data.entity)
            end
        }
    })
end)

-- Hàm đóng băng xe
function FreezeVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local alert = lib.alertDialog({
        header = 'Đóng băng xe',
        content = 'Bạn có chắc chắn muốn đóng băng xe này không?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        -- Đóng băng xe
        FreezeEntityPosition(vehicle, true)
        SetEntityInvincible(vehicle, true)
        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleUndriveable(vehicle, true)
        
        -- Lưu trạng thái
        frozenVehicles[vehicle] = true
        
        -- Tạo hiệu ứng băng
        CreateFreezeEffect(vehicle)
        
        lib.notify({
            title = 'Thành công',
            description = 'Xe đã được đóng băng',
            type = 'success'
        })
        
        -- Gửi log cho server
        TriggerServerEvent('vehicle:freeze', NetworkGetNetworkIdFromEntity(vehicle), true)
    end
end

-- Hàm bỏ đóng băng xe
function UnfreezeVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local alert = lib.alertDialog({
        header = 'Bỏ đóng băng xe',
        content = 'Bạn có chắc chắn muốn bỏ đóng băng xe này không?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        -- Bỏ đóng băng xe
        FreezeEntityPosition(vehicle, false)
        SetEntityInvincible(vehicle, false)
        SetVehicleUndriveable(vehicle, false)
        
        -- Xóa trạng thái
        frozenVehicles[vehicle] = nil
        
        -- Xóa hiệu ứng băng
        RemoveFreezeEffect(vehicle)
        
        lib.notify({
            title = 'Thành công',
            description = 'Xe đã được bỏ đóng băng',
            type = 'success'
        })
        
        -- Gửi log cho server
        TriggerServerEvent('vehicle:freeze', NetworkGetNetworkIdFromEntity(vehicle), false)
    end
end

-- Hàm tạo khiên bảo vệ
function CreateVehicleShield(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local input = lib.inputDialog('Tạo khiên bảo vệ', {
        {
            type = 'select',
            label = 'Loại khiên',
            options = {
                {value = 'basic', label = 'Khiên cơ bản'},
                {value = 'advanced', label = 'Khiên nâng cao'},
                {value = 'ultimate', label = 'Khiên tối thượng'}
            },
            required = true
        },
        {
            type = 'number',
            label = 'Thời gian (phút)',
            description = 'Thời gian khiên tồn tại (0 = vĩnh viễn)',
            default = 0,
            min = 0,
            max = 1440
        }
    })
    
    if input then
        local shieldType = input[1]
        local duration = input[2] * 60000 -- Chuyển sang milliseconds
        
        -- Tạo khiên
        SetEntityProofs(vehicle, true, true, true, true, true, true, true, true)
        SetEntityCanBeDamaged(vehicle, false)
        
        -- Lưu thông tin khiên
        vehicleShields[vehicle] = {
            type = shieldType,
            startTime = GetGameTimer(),
            duration = duration
        }
        
        -- Tạo hiệu ứng khiên
        CreateShieldEffect(vehicle, shieldType)
        
        lib.notify({
            title = 'Khiên đã được tạo',
            description = 'Xe được bảo vệ bởi khiên ' .. GetShieldTypeName(shieldType),
            type = 'success'
        })
        
        -- Gửi thông tin cho server
        TriggerServerEvent('vehicle:shield', NetworkGetNetworkIdFromEntity(vehicle), true, shieldType, duration)
        
        -- Tự động xóa khiên sau thời gian quy định
        if duration > 0 then
            SetTimeout(duration, function()
                if vehicleShields[vehicle] then
                    RemoveVehicleShield(vehicle)
                end
            end)
        end
    end
end

-- Hàm xóa khiên bảo vệ
function RemoveVehicleShield(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    if vehicleShields[vehicle] then
        -- Xóa khiên
        SetEntityProofs(vehicle, false, false, false, false, false, false, false, false)
        SetEntityCanBeDamaged(vehicle, true)
        
        -- Xóa hiệu ứng
        RemoveShieldEffect(vehicle)
        
        -- Xóa thông tin khiên
        vehicleShields[vehicle] = nil
        
        lib.notify({
            title = 'Khiên đã bị xóa',
            description = 'Xe không còn được bảo vệ',
            type = 'inform'
        })
        
        -- Gửi thông tin cho server
        TriggerServerEvent('vehicle:shield', NetworkGetNetworkIdFromEntity(vehicle), false)
    end
end

-- Hàm tạo hiệu ứng băng
function CreateFreezeEffect(vehicle)
    local coords = GetEntityCoords(vehicle)
    
    -- Tạo particle effect băng
    CreateThread(function()
        while frozenVehicles[vehicle] do
            -- Hiệu ứng băng quanh xe
            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do
                Wait(1)
            end
            
            UseParticleFxAssetNextCall("core")
            StartParticleFxLoopedOnEntity("ent_amb_smoke_flare", vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, false, false, false)
            
            Wait(5000)
        end
    end)
end

-- Hàm xóa hiệu ứng băng
function RemoveFreezeEffect(vehicle)
    -- Dừng tất cả particle effects trên xe
    RemoveParticleFxFromEntity(vehicle)
end

-- Hàm tạo hiệu ứng khiên
function CreateShieldEffect(vehicle, shieldType)
    local coords = GetEntityCoords(vehicle)
    local color = GetShieldColor(shieldType)
    
    CreateThread(function()
        while vehicleShields[vehicle] do
            -- Tạo hiệu ứng ánh sáng quanh xe
            DrawMarker(28, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                      5.0, 5.0, 3.0, color.r, color.g, color.b, 100, false, true, 2, false, "", "", false)
            Wait(0)
        end
    end)
end

-- Hàm xóa hiệu ứng khiên
function RemoveShieldEffect(vehicle)
    -- Hiệu ứng sẽ tự động dừng khi vehicleShields[vehicle] = nil
end

-- Hàm lấy màu khiên theo loại
function GetShieldColor(shieldType)
    local colors = {
        basic = {r = 0, g = 255, b = 255},      -- Cyan
        advanced = {r = 255, g = 165, b = 0},   -- Orange
        ultimate = {r = 255, g = 215, b = 0}    -- Gold
    }
    return colors[shieldType] or colors.basic
end

-- Hàm lấy tên khiên
function GetShieldTypeName(shieldType)
    local names = {
        basic = 'cơ bản',
        advanced = 'nâng cao',
        ultimate = 'tối thượng'
    }
    return names[shieldType] or 'không xác định'
end

-- Dọn dẹp khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Bỏ đóng băng tất cả xe
        for vehicle, _ in pairs(frozenVehicles) do
            if DoesEntityExist(vehicle) then
                FreezeEntityPosition(vehicle, false)
                SetEntityInvincible(vehicle, false)
                SetVehicleUndriveable(vehicle, false)
            end
        end
        
        -- Xóa tất cả khiên
        for vehicle, _ in pairs(vehicleShields) do
            if DoesEntityExist(vehicle) then
                SetEntityProofs(vehicle, false, false, false, false, false, false, false, false)
                SetEntityCanBeDamaged(vehicle, true)
            end
        end
    end
end)

-- Event xử lý force unfreeze từ server
RegisterNetEvent('vehicle:forceUnfreeze', function(vehicle)
    if DoesEntityExist(vehicle) and frozenVehicles[vehicle] then
        FreezeEntityPosition(vehicle, false)
        SetEntityInvincible(vehicle, false)
        SetVehicleUndriveable(vehicle, false)
        frozenVehicles[vehicle] = nil
        RemoveFreezeEffect(vehicle)
    end
end)

-- Event xử lý force remove shield từ server
RegisterNetEvent('vehicle:forceRemoveShield', function(vehicle)
    if DoesEntityExist(vehicle) and vehicleShields[vehicle] then
        SetEntityProofs(vehicle, false, false, false, false, false, false, false, false)
        SetEntityCanBeDamaged(vehicle, true)
        RemoveShieldEffect(vehicle)
        vehicleShields[vehicle] = nil
    end
end)
