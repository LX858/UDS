-- ==================== VEHICLE ACTIONS CLIENT ====================
-- Giam xe & xóa xe bằng ox_target khi on duty

local QBCore = exports['qb-core']:GetCoreObject()
local QBX = nil
local targetsAdded = false

if GetResourceState('qbx_core') == 'started' or GetResourceState('qbx_core') == 'starting' then
    QBX = exports.qbx_core
end

-- Get Player Data
local function GetPlayerData()
    if Config.Framework == 'qbx' and QBX then
        return QBX:GetPlayerData()
    else
        return QBCore.Functions.GetPlayerData()
    end
end

-- Get player job grade level safely
local function GetPlayerGradeLevel()
    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.job or not PlayerData.job.grade then
        return 0
    end
    local grade = PlayerData.job.grade
    if type(grade) == 'table' then
        return grade.level or 0
    end
    return tonumber(grade) or 0
end

-- Get officer full name safely
local function GetOfficerFullName()
    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.charinfo then
        return 'Unknown Officer'
    end
    local charinfo = PlayerData.charinfo
    local firstname = charinfo.firstname or ''
    local lastname = charinfo.lastname or ''
    if firstname == '' and lastname == '' then
        return 'Unknown Officer'
    end
    return firstname .. ' ' .. lastname
end

-- Check on duty và có quyền
local function CanUseVehicleActions()
    if not Config.VehicleActions.Enabled then return false end
    
    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.job then return false end
    
    return Config.AllowedJobs[PlayerData.job.name] and PlayerData.job.onduty
end

-- Giam xe
local function ImpoundVehicle(entity)
    if not DoesEntityExist(entity) then return end
    
    local PlayerData = GetPlayerData()
    local playerGrade = GetPlayerGradeLevel()
    
    if playerGrade < Config.VehicleActions.MinGradeImpound then
        lib.notify({
            title = 'Không đủ quyền',
            description = 'Bạn cần cấp bậc ' .. Config.VehicleActions.MinGradeImpound .. ' trở lên để giam xe',
            type = 'error'
        })
        return
    end
    
    local vehicleProps = lib.getVehicleProperties(entity)
    local vehicleLabel = GetLabelText(GetDisplayNameFromVehicleModel(vehicleProps.model))
    
    local officerName = GetOfficerFullName()
    
    -- Lấy charges từ database
    local impoundCharges = lib.callback.await('mini-mdt:getVehicleImpoundCharges', false)
    
    if not impoundCharges or #impoundCharges == 0 then
        lib.notify({
            title = 'Không có mức án',
            description = 'Chưa có mức án giam xe nào. Hãy tạo trong MDT > Quản Lý Mức Án',
            type = 'error'
        })
        return
    end
    
    -- Tạo options từ charges
    local offenceOptions = {}
    for i, charge in ipairs(impoundCharges) do
        table.insert(offenceOptions, {
            label = string.format('%s - Phạt: $%d', 
                charge.charge_name, 
                charge.fine_min
            ), 
            value = i  -- Dùng index thay vì object
        })
    end
    
    local input = lib.inputDialog('🚓 GIAM XE', {
        {type = 'input', label = 'Cảnh sát', default = officerName, required = true, disabled = true},
        {type = 'input', label = 'Xe', default = vehicleLabel, required = true, disabled = true},
        {type = 'input', label = 'Biển số', default = vehicleProps.plate, required = true, disabled = true},
        {
            type = 'select', 
            label = 'Vi phạm', 
            required = true,
            options = offenceOptions,
            default = 1
        },
        {type = 'textarea', label = 'Ghi chú', placeholder = 'Lý do giam xe...', max = 500}
    })
    
    if not input then return end
    
    TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    Wait(2000)
    ClearPedTasks(cache.ped)
    
    local selectedChargeIndex = input[4]
    local selectedCharge = impoundCharges[selectedChargeIndex]  -- Lấy charge từ array bằng index
    local fineAmount = selectedCharge.fine_min -- Lấy tiền phạt từ charge
    local durationMinutes = selectedCharge.impound_duration or 60
    
    -- Gọi server validation và log (CHỜ response)
    local result = lib.callback.await('mini-mdt:impoundVehicle', false, {
        officer_citizenid = PlayerData.citizenid,
        officer_name = officerName,
        officer_pid = PlayerData.source or GetPlayerServerId(PlayerId()),
        owner_citizenid = '', -- Sẽ lấy từ plate ở server
        owner_name = '',
        vehicle_plate = vehicleProps.plate,
        vehicle_model = vehicleLabel,
        offence = selectedCharge.charge_name,
        fine_amount = fineAmount,
        notes = input[5] or '',
        duration_minutes = durationMinutes,
        status = 2 -- 2 = đang giam
    })
    
    -- ✅ CHỈ XÓA XE KHI SERVER CHO PHÉP
    if result and result.success then
        -- Xóa xe khỏi world
        if DoesEntityExist(entity) then
            while not NetworkHasControlOfEntity(entity) do
                NetworkRequestControlOfEntity(entity)
                Wait(100)
            end
            DeleteEntity(entity)
        end
        
        lib.notify({
            title = 'Giam xe thành công',
            description = result.message or ('Xe ' .. vehicleProps.plate .. ' đã bị tạm giam'),
            type = 'success'
        })
    else
        lib.notify({
            title = 'Không thể giam xe',
            description = result and result.message or 'Lỗi không xác định',
            type = 'error',
            duration = 6000
        })
    end
end

-- Xóa xe
local function DeleteVehicle(entity)
    if not DoesEntityExist(entity) then return end
    
    local PlayerData = GetPlayerData()
    local playerGrade = GetPlayerGradeLevel()
    
    if playerGrade < Config.VehicleActions.MinGradeDelete then
        lib.notify({
            title = 'Không đủ quyền',
            description = 'Bạn cần cấp bậc ' .. Config.VehicleActions.MinGradeDelete .. ' trở lên để xóa xe',
            type = 'error'
        })
        return
    end
    
    local vehicleProps = lib.getVehicleProperties(entity)
    local confirm = lib.alertDialog({
        header = '⚠️ XÓA XE',
        content = 'Bạn có muốn xóa xe này không?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Xác nhận',
            cancel = 'Hủy'
        }
    })
    
    if confirm == 'confirm' then
        TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
        
        local result = lib.callback.await('mini-mdt:deleteVehicle', false, vehicleProps.plate)
        
        ClearPedTasks(cache.ped)
        
        if result and result.success then
            -- Xóa xe khỏi world
            if DoesEntityExist(entity) then
                while not NetworkHasControlOfEntity(entity) do
                    NetworkRequestControlOfEntity(entity)
                    Wait(100)
                end
                DeleteEntity(entity)
            end
            
            lib.notify({
                title = 'Xóa xe thành công',
                description = result.message or ('Đã xóa xe biển số ' .. vehicleProps.plate),
                type = 'success'
            })
        else
            lib.notify({
                title = 'Xóa xe thất bại',
                description = result and result.message or 'Lỗi không xác định',
                type = 'error'
            })
        end
    end
end

-- Add targets
local function AddVehicleTargets()
    if targetsAdded then return end
    
    if Config.VehicleActions.Target == 'ox' then
        exports.ox_target:addGlobalVehicle({
            {
                name = 'mdt_impound_vehicle',
                label = '🚓 Giam xe',
                icon = 'fa-solid fa-car-burst',
                iconColor = '#f59e0b',
                distance = 2.5,
                onSelect = function(data)
                    ImpoundVehicle(data.entity)
                end
            },
            {
                name = 'mdt_delete_vehicle',
                label = '🗑️ Xóa xe',
                icon = 'fa-solid fa-trash',
                iconColor = '#ef4444',
                distance = 2.5,
                canInteract = function(entity, dist, coords, name)
                    local PlayerData = GetPlayerData()
                    local playerGrade = GetPlayerGradeLevel()
                    return playerGrade >= Config.VehicleActions.MinGradeDelete
                end,
                onSelect = function(data)
                    DeleteVehicle(data.entity)
               end
            }
        })
        targetsAdded = true
    elseif Config.VehicleActions.Target == 'qb' then
        exports['qb-target']:AddGlobalVehicle({
            options = {
                {
                    label = '🚓 Giam xe',
                    icon = 'fa-solid fa-car-burst',
                    action = function(entity)
                        ImpoundVehicle(entity)
                    end
                },
                {
                    label = '🗑️ Xóa xe',
                    icon = 'fa-solid fa-trash',
                    action = function(entity)
                        DeleteVehicle(entity)
                    end
                }
            },
            distance = 2.5
        })
        targetsAdded = true
    end
end

-- Remove targets
local function RemoveVehicleTargets()
    if not targetsAdded then return end
    
    if Config.VehicleActions.Target == 'ox' then
        exports.ox_target:removeGlobalVehicle({'mdt_impound_vehicle', 'mdt_delete_vehicle'})
    elseif Config.VehicleActions.Target == 'qb' then
        exports['qb-target']:RemoveGlobalVehicle('🚓 Giam xe')
        exports['qb-target']:RemoveGlobalVehicle('🗑️ Xóa xe')
    end
    
    targetsAdded = false
end

-- Job update handler
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Wait(100)
    if CanUseVehicleActions() then
        AddVehicleTargets()
    else
        RemoveVehicleTargets()
    end
end)

-- Duty toggle handler
RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    Wait(100)
    if CanUseVehicleActions() then
        AddVehicleTargets()
    else
        RemoveVehicleTargets()
    end
end)

-- Player loaded
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    if CanUseVehicleActions() then
        AddVehicleTargets()
    end
end)

-- Resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        if CanUseVehicleActions() then
            AddVehicleTargets()
        end
    end
end)

-- Resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveVehicleTargets()
    end
end)
