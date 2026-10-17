-- Callback để kiểm tra số lượng mechanic online
lib.callback.register("mechanic_tools:GetMechanicCount", function(source)
    local numMechanics = GlobalState['mechanic_count'] or 0
    return numMechanics
end)

-- Callback để kiểm tra player có repair kit không
lib.callback.register('mechanic_tools:hasRepairKit', function(source)
    -- Kiểm tra có mechanic online không
    local numMechanics = GlobalState['mechanic_count'] or 0
    
    if numMechanics > 0 then
        exports.qbx_core:Notify(source, 'Có thợ sửa xe đang online, vui lòng liên hệ thợ để sửa xe!', 'error')
        return false
    end
    
    -- Kiểm tra có repair kit không
    local itemCount = exports.ox_inventory:Search(source, 'count', Config.RepairItem)
    if itemCount <= 0 then
        exports.qbx_core:Notify(source, Config.Locale['no_repairkit'], 'error')
        return false
    end
    
    return true
end)

-- Callback kiểm tra có thể sửa xe ban ngành không
lib.callback.register('mechanic_tools:canRepairDepartmentVehicle', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    -- Kiểm tra có mechanic online không (chỉ cho phép khi duty <= 0)
    local numMechanics = GlobalState['mechanic_count'] or 0
    
    if numMechanics > 0 then
        exports.qbx_core:Notify(source, Config.Locale['mechanic_online'], 'error')
        return false
    end
    
    -- Kiểm tra job có thuộc ban ngành không
    local playerJob = player.PlayerData.job.name
    local isAllowedJob = false
    
    for _, job in ipairs(Config.AllowedDepartments) do
        if playerJob == job then
            isAllowedJob = true
            break
        end
    end
    
    if not isAllowedJob then
        exports.qbx_core:Notify(source, Config.Locale['not_allowed_job'], 'error')
        return false
    end
    
    -- Kiểm tra có item sửa xe ban ngành không
    local itemCount = exports.ox_inventory:Search(source, 'count', Config.DepartmentRepairItem)
    if itemCount <= 0 then
        exports.qbx_core:Notify(source, Config.Locale['no_department_item'], 'error')
        return false
    end
    
    return true
end)

-- Event để sửa xe
RegisterNetEvent('mechanic_tools:repairVehicle', function(vehicleNetId)
    local src = source
    
    -- Kiểm tra lại có repair kit không
    local itemCount = exports.ox_inventory:Search(src, 'count', Config.RepairItem)
    if itemCount <= 0 then
        exports.qbx_core:Notify(src, Config.Locale['no_repairkit'], 'error')
        return
    end
    
    -- Xóa repair kit
    exports.ox_inventory:RemoveItem(src, Config.RepairItem, 1)
    
    -- Sửa xe (trigger tới tất cả client để sync)
    TriggerClientEvent('mechanic_tools:repairVehicleClient', -1, vehicleNetId)
end)

-- Event để sửa xe ban ngành
RegisterNetEvent('mechanic_tools:repairDepartmentVehicle', function(vehicleNetId, modelName)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    
    if not player then return end
    
    -- Kiểm tra lại có mechanic online không
    local numMechanics = GlobalState['mechanic_count'] or 0
    if numMechanics > 0 then
        exports.qbx_core:Notify(src, Config.Locale['mechanic_online'], 'error')
        return
    end
    
    -- Kiểm tra job có thuộc ban ngành không
    local playerJob = player.PlayerData.job.name
    local playerGrade = player.PlayerData.job.grade.level
    local isAllowedJob = false
    
    for _, job in ipairs(Config.AllowedDepartments) do
        if playerJob == job then
            isAllowedJob = true
            break
        end
    end
    
    if not isAllowedJob then
        exports.qbx_core:Notify(src, Config.Locale['not_allowed_job'], 'error')
        return
    end
    
    -- Kiểm tra xe có thuộc danh sách ban ngành và job đúng không
    local vehicleInfo = Config.DepartmentVehicles[string.lower(modelName)]
    if not vehicleInfo then
        exports.qbx_core:Notify(src, Config.Locale['not_department_vehicle'], 'error')
        return
    end
    
    -- Kiểm tra job phải match với xe
    if vehicleInfo.job ~= playerJob then
        exports.qbx_core:Notify(src, Config.Locale['not_department_vehicle'], 'error')
        return
    end
    
    -- Kiểm tra grade đủ không
    if playerGrade < vehicleInfo.grade then
        exports.qbx_core:Notify(src, Config.Locale['grade_not_enough'], 'error')
        return
    end
    
    -- Kiểm tra lại có item sửa xe ban ngành không
    local itemCount = exports.ox_inventory:Search(src, 'count', Config.DepartmentRepairItem)
    if itemCount <= 0 then
        exports.qbx_core:Notify(src, Config.Locale['no_department_item'], 'error')
        return
    end
    
    -- Xóa item sửa xe ban ngành
    exports.ox_inventory:RemoveItem(src, Config.DepartmentRepairItem, 1)
    
    -- Sửa xe (trigger tới tất cả client để sync)
    TriggerClientEvent('mechanic_tools:repairVehicleClient', -1, vehicleNetId)
    
    -- Log
    print(('[MECHANIC_TOOLS] Player %s (%s) used department repair item on vehicle %s (%s)'):format(
        player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        player.PlayerData.citizenid,
        modelName,
        vehicleNetId
    ))
end)

-- Log khi player sử dụng repair kit
AddEventHandler('mechanic_tools:repairVehicle', function(vehicleNetId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    
    if player then
        print(('[MECHANIC_TOOLS] Player %s (%s) used repair kit on vehicle %s'):format(
            player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
            player.PlayerData.citizenid,
            vehicleNetId
        ))
    end
end)
