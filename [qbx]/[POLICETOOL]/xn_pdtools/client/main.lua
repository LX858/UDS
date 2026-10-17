local ox_target = exports.ox_target

-- Kiểm tra xem player có phải là công an không
local function IsPoliceOfficer()
    local playerData = lib.callback.await('xn_pdtools:getPlayerJob', false)
    if not playerData then return false end
    
    for _, job in ipairs(Config.AllowedJobs) do
        if playerData.job == job then
            return true
        end
    end
    return false
end

-- Hàm hiển thị thông tin xe
local function ShowVehicleInfo(vehicleData)
    local alert = lib.alertDialog({
        header = 'Thông tin phương tiện',
        content = string.format([[
**Biển số:** %s
**Tên chủ xe:** %s
**Tình trạng:** %s
**Mẫu xe:** %s
**Màu sắc:** %s
**Ngày đăng ký:** %s
        ]], 
        vehicleData.plate or 'Không xác định',
        vehicleData.owner or 'Không xác định',
        vehicleData.status or 'Không rõ',
        vehicleData.model or 'Không rõ',
        vehicleData.color or 'Không rõ',
        vehicleData.registration_date or 'Không rõ'
        ),
        centered = true,
        cancel = false
    })
end

-- Hàm xử lý khi target vào xe
local function OnVehicleTarget(data)
    local vehicle = data.entity
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    
    if not IsPoliceOfficer() then
        lib.notify({
            title = 'Không có quyền',
            description = 'Chỉ có công an mới được phép kiểm tra thông tin xe!',
            type = 'error'
        })
        return
    end
    
    -- Gửi request lên server để lấy thông tin xe
    lib.callback('xn_pdtools:getVehicleInfo', false, function(vehicleData)
        if vehicleData then
            ShowVehicleInfo(vehicleData)
        else
            lib.notify({
                title = 'Không tìm thấy thông tin',
                description = 'Không có dữ liệu về phương tiện này',
                type = 'warning'
            })
        end
    end, plate)
end

-- Thêm target cho tất cả các xe
CreateThread(function()
    ox_target:addGlobalVehicle({
        {
            name = 'vehicle_check',
            icon = Config.TargetOptions.icon,
            label = Config.TargetOptions.label,
            distance = Config.TargetOptions.distance,
            onSelect = OnVehicleTarget,
            canInteract = function(entity, distance, coords, name, bone)
                return IsPoliceOfficer()
            end
        }
    })
end)

-- Event để refresh job khi player đổi job
RegisterNetEvent('esx:setJob', function(job)
    -- Job đã được update, không cần làm gì thêm
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    -- Job đã được update cho QBCore
end)
