-- Simple client version WITHOUT ox_lib - chỉ dùng chat notifications

local ox_target = exports.ox_target

-- Biến lưu trữ job của player
local PlayerJob = nil

-- Kiểm tra xem player có phải là công an không
local function IsPoliceOfficer()
    if not PlayerJob then return false end
    
    for _, job in ipairs(Config.AllowedJobs) do
        if PlayerJob.job == job then
            return true
        end
    end
    return false
end

-- Hàm hiển thị thông tin xe bằng chat (đẹp hơn)
local function ShowVehicleInfo(vehicleData)
    local message = string.format([[
^0━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
^4🚔 ^1THÔNG TIN PHƯƠNG TIỆN ^4🚔
^0━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
^3🚗 Biển số: ^7%s
^3👤 Chủ xe: ^7%s  
^3⚠️ Tình trạng: ^7%s
^3🏷️ Mẫu xe: ^7%s
^3🎨 Màu sắc: ^7%s
^3📅 Ngày ĐK: ^7%s
^0━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ]], 
    vehicleData.plate or 'Không xác định',
    vehicleData.owner or 'Không xác định',
    vehicleData.status or 'Không rõ',
    vehicleData.model or 'Không rõ',
    vehicleData.color or 'Không rõ',
    vehicleData.registration_date or 'Không rõ'
    )
    
    -- Nếu có thông tin garage, thêm vào
    if vehicleData.garage then
        message = message .. string.format('^3🏠 Garage: ^7%s\n^0━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', vehicleData.garage)
    end
    
    -- Hiển thị trong chat với màu sắc
    TriggerEvent('chat:addMessage', {
        color = {0, 150, 255},
        multiline = true,
        args = {"", message}
    })
    
    -- Notification đơn giản
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~b~Đã kiểm tra thông tin xe: ~w~" .. (vehicleData.plate or "Unknown"))
    DrawNotification(false, false)
end

-- Hàm xử lý khi target vào xe
local function OnVehicleTarget(data)
    local vehicle = data.entity
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    
    print('[xn_pdtools] Client checking vehicle with plate: ' .. plate)
    
    if not IsPoliceOfficer() then
        -- Notification lỗi
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~Chỉ có công an mới được phép kiểm tra thông tin xe!")
        DrawNotification(false, false)
        
        TriggerEvent('chat:addMessage', {
            color = {255, 50, 50},
            args = {"^1[POLICE SYSTEM]", "^7Chỉ có công an mới được phép kiểm tra thông tin xe!"}
        })
        return
    end
    
    -- Notification đang kiểm tra
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~y~Đang kiểm tra thông tin xe...")
    DrawNotification(false, false)
    
    -- Gửi request lên server
    TriggerServerEvent('xn_pdtools:getVehicleInfo', plate)
end

-- Nhận thông tin job từ server
RegisterNetEvent('xn_pdtools:receivePlayerJob')
AddEventHandler('xn_pdtools:receivePlayerJob', function(jobData)
    PlayerJob = jobData
    print('[xn_pdtools] Received job data: ' .. tostring(jobData and jobData.job or 'nil'))
end)

-- Nhận thông tin xe từ server
RegisterNetEvent('xn_pdtools:receiveVehicleInfo')
AddEventHandler('xn_pdtools:receiveVehicleInfo', function(vehicleData)
    print('[xn_pdtools] Received vehicle data for: ' .. tostring(vehicleData.plate))
    if vehicleData then
        ShowVehicleInfo(vehicleData)
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~Không có dữ liệu về phương tiện này")
        DrawNotification(false, false)
        
        TriggerEvent('chat:addMessage', {
            color = {255, 200, 0},
            args = {"^3[POLICE SYSTEM]", "^7Không có dữ liệu về phương tiện này"}
        })
    end
end)

-- Hàm cập nhật job
local function UpdatePlayerJob()
    TriggerServerEvent('xn_pdtools:getPlayerJob')
end

-- Thêm target cho tất cả các xe
CreateThread(function()
    -- Đợi một chút để đảm bảo mọi thứ đã load
    Wait(2000)
    
    -- Lấy thông tin job ban đầu
    UpdatePlayerJob()
    
    -- Thêm target
    ox_target:addGlobalVehicle({
        {
            name = 'vehicle_check_simple',
            icon = Config.TargetOptions.icon,
            label = Config.TargetOptions.label,
            distance = Config.TargetOptions.distance,
            onSelect = OnVehicleTarget,
            canInteract = function(entity, distance, coords, name, bone)
                return IsPoliceOfficer()
            end
        }
    })
    
    print('[xn_pdtools] Vehicle target added')
end)

-- Event để refresh job khi player đổi job
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    Wait(1000) -- Đợi job update xong
    UpdatePlayerJob()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    Wait(1000) -- Đợi job update xong  
    UpdatePlayerJob()
end)

-- Command để test thủ công
RegisterCommand('checkjob', function()
    UpdatePlayerJob()
    if PlayerJob then
        print('Current job: ' .. PlayerJob.job)
        
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~g~Current job: ~w~" .. PlayerJob.job)
        DrawNotification(false, false)
        
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 200},
            args = {"^2[DEBUG]", "^7Current job: " .. PlayerJob.job}
        })
    else
        print('No job data')
        
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~No job data")
        DrawNotification(false, false)
        
        TriggerEvent('chat:addMessage', {
            color = {255, 50, 50},
            args = {"^1[DEBUG]", "^7No job data"}
        })
    end
end, false)
