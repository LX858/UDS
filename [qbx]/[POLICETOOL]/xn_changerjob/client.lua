QBCore = exports['qb-core']:GetCoreObject()

local targetLocation = vec3(629.2, -6.24, 82.78)

-- Đợi QBCore load xong
CreateThread(function()
    while not QBCore do
        Wait(500)
    end
    
    -- Tạo target zone sau khi framework load xong
    exports.ox_target:addSphereZone({
        coords = targetLocation,
        radius = 2.0,
        options = {
            {
                name = 'job_changer',
                icon = 'fas fa-exchange-alt',
                label = 'Thay đổi công việc',
                onSelect = function()
                    openJobChangeMenu()
                end,
                canInteract = function()
                    return checkPlayerAccess()
                end
            }
        }
    })
end)

-- Kiểm tra quyền truy cập
function checkPlayerAccess()
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.citizenid then
        return false
    end
    
    -- Sử dụng function từ config
    return Config.IsAllowedCitizen(playerData.citizenid)
end

-- Mở menu thay đổi job
function openJobChangeMenu()
    local playerData = QBCore.Functions.GetPlayerData()
    local currentJob = playerData.job
    
    if not currentJob then
        exports.ox_lib:notify({
            title = 'Lỗi',
            description = 'Không thể lấy thông tin công việc hiện tại',
            type = 'error'
        })
        return
    end
    
    local options = {}
    
    -- Kiểm tra job hiện tại và tạo options tương ứng
    if currentJob.name == 'police' and currentJob.grade.level >= 11 then
        table.insert(options, {
            title = 'Chuyển sang Học viên',
            description = string.format('Thay đổi từ Police bậc %d sang HocVien bậc 4', currentJob.grade.level),
            icon = 'graduation-cap',
            onSelect = function()
                changeJob('hocvien', 4)
            end
        })
    elseif currentJob.name == 'hocvien' and currentJob.grade.level == 4 then
        table.insert(options, {
            title = 'Chuyển sang Police',
            description = 'Thay đổi từ HocVien bậc 4 sang Police bậc 11',
            icon = 'shield-alt',
            onSelect = function()
                changeJob('police', 11)
            end
        })
    else
        exports.ox_lib:notify({
            title = 'Thông báo',
            description = 'Bạn phải có job Police bậc 11+ hoặc HocVien bậc 4 mới có thể thay đổi',
            type = 'warning'
        })
        return
    end
    
    -- Thêm option hủy
    table.insert(options, {
        title = 'Hủy',
        description = 'Đóng menu',
        icon = 'times',
        onSelect = function()
            -- Đóng menu
        end
    })
    
    -- Hiển thị context menu
    exports.ox_lib:registerContext({
        id = 'job_changer_menu',
        title = 'Thay đổi công việc',
        options = options
    })
    
    exports.ox_lib:showContext('job_changer_menu')
end

-- Thay đổi job
function changeJob(newJob, newGrade)
    -- Hiển thị dialog xác nhận
    local alert = exports.ox_lib:alertDialog({
        header = 'Xác nhận thay đổi',
        content = string.format('Bạn có chắc chắn muốn thay đổi công việc thành %s bậc %d?', newJob, newGrade),
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        -- Gửi request đến server
        TriggerServerEvent('xn_changerjob:changeJob', newJob, newGrade)
    end
end

-- Event để cập nhật job sau khi thay đổi thành công
RegisterNetEvent('xn_changerjob:jobChanged', function(newJob, newGrade)
    exports.ox_lib:notify({
        title = 'Thành công',
        description = string.format('Đã thay đổi công việc thành %s bậc %d', newJob, newGrade),
        type = 'success'
    })
    
    -- Refresh player data
    QBCore.Functions.GetPlayerData()
end)

-- Event để hiển thị lỗi
RegisterNetEvent('xn_changerjob:error', function(message)
    exports.ox_lib:notify({
        title = 'Lỗi',
        description = message,
        type = 'error'
    })
end)
