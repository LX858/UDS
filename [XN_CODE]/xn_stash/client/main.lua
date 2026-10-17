local QBX = exports.qbx_core
local activeZones = {}

-- Function kiểm tra quyền truy cập local (client-side check)
local function hasStashPermission(stashConfig)
    local playerData = QBX:GetPlayerData()
    if not playerData or not playerData.job then return false end
    
    -- Nếu không có groups trong config, cho phép tất cả
    if not stashConfig.groups then return true end
    
    local playerJob = playerData.job
    
    -- Kiểm tra job và grade
    for jobName, requiredGrade in pairs(stashConfig.groups) do
        if playerJob.name == jobName and playerJob.grade.level >= requiredGrade then
            return true
        end
    end
    
    return false
end

-- Event nhận từ server để mở stash
RegisterNetEvent('xn_stash:client:openStash', function(stashId)
    exports.ox_inventory:openInventory('stash', stashId)
end)

-- Event nhận từ server để mở personal stash
RegisterNetEvent('xn_stash:client:openPersonalStash', function(personalStashId)
    exports.ox_inventory:openInventory('stash', personalStashId)
end)

-- Khởi tạo ox_target cho các kho đồ
local function initializeStashTargets()
    -- Clear any existing zones first
    for zoneName, _ in pairs(activeZones) do
        exports.ox_target:removeZone(zoneName)
    end
    activeZones = {}

    -- Kho đồ job-based
    for jobName, stashData in pairs(Config.Stashes) do
        local zoneName = 'open_stash_' .. jobName
        local targetOptions = {
            name = zoneName,
            icon = stashData.icon,
            label = stashData.label,
            distance = Config.Target.distance,
            groups = stashData.groups,
            onSelect = function()
                -- Gửi request đến server để kiểm tra quyền và mở stash
                TriggerServerEvent('xn_stash:server:checkJobStashAccess', stashData.stashId)
            end,
            canInteract = function()
                -- Client-side check để hiện/ẩn option
                return hasStashPermission(stashData)
            end
        }
        
        -- Thêm yêu cầu item nếu có
        if stashData.requiredItem then
            targetOptions.items = stashData.requiredItem
        end
        
        exports.ox_target:addBoxZone({
            name = zoneName,
            coords = stashData.coords,
            size = vec3(2.0, 2.0, 2.0),
            rotation = 0,
            debug = Config.Target.debug,
            options = { targetOptions }
        })
        activeZones[zoneName] = true
    end
    
    -- Kho đồ cá nhân
    for personalName, stashData in pairs(Config.PersonalStashes) do
        local zoneName = 'open_personal_stash_' .. personalName
        local targetOptions = {
            name = zoneName,
            icon = stashData.icon,
            label = stashData.label,
            distance = Config.Target.distance,
            onSelect = function()
                local playerData = QBX:GetPlayerData()
                if playerData and playerData.citizenid then
                    -- Trigger server để kiểm tra quyền và tạo stash nếu được phép
                    TriggerServerEvent('xn_stash:server:createPersonalStash', stashData.stashId)
                end
            end,
            canInteract = function()
                -- Client-side check để hiện/ẩn option
                return hasStashPermission(stashData)
            end
        }
        
        -- Thêm yêu cầu item nếu có
        if stashData.requiredItem then
            targetOptions.items = stashData.requiredItem
        end
        
        exports.ox_target:addBoxZone({
            name = zoneName,
            coords = stashData.coords,
            size = vec3(2.0, 2.0, 2.0),
            rotation = 0,
            debug = Config.Target.debug,
            options = { targetOptions }
        })
        activeZones[zoneName] = true
    end
end

-- Event handlers (chỉ để reload khi job thay đổi)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    initializeStashTargets()
end)

-- Command reload stash targets
RegisterCommand('reloadstash', function()
    initializeStashTargets()
    exports.ox_lib:notify({
        title = 'Stash System',
        description = 'Stash targets reloaded successfully.',
        type = 'success'
    })
end, false)

-- Khởi tạo targets ngay
initializeStashTargets()