-- TEST VERSION - Simple client với ox_lib context menu và tính năng mới

local ox_target = exports.ox_target

-- Biến lưu trữ job của player
local PlayerJob = nil

-- Kiểm tra xem player có phải là công an đang onduty không
local function IsPoliceOfficer()
    if not PlayerJob then return false end
    
    for _, job in ipairs(Config.AllowedJobs) do
        if PlayerJob.job == job then
            -- Đối với QBCore, kiểm tra thêm onduty status
            if PlayerJob.onduty ~= nil then
                return PlayerJob.onduty
            else
                -- ESX không có onduty system, mặc định là true
                return true
            end
        end
    end
    return false
end

-- Hàm kiểm tra xem xe có phải NPC không (Logic mới chính xác hơn)
local function IsNPCVehicle(vehicle)
    -- Trong FiveM/QBCore, cách phân biệt xe NPC và xe player:
    
    -- 1. Kiểm tra xe có trong config mẫu không (ưu tiên cao nhất)
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", ""):upper()
    if Config.VehicleInfo[plate] then
        print('[xn_pdtools] Vehicle found in config - Player vehicle')
        return false
    end
    
    -- 2. Kiểm tra driver hiện tại
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver ~= 0 then
        if IsPedAPlayer(driver) then
            -- Có player đang lái = chắc chắn không phải NPC
            print('[xn_pdtools] Player is driving - Player vehicle')
            return false
        else
            -- Có NPC đang lái = có thể là xe NPC traffic
            print('[xn_pdtools] NPC is driving - Checking if traffic vehicle')
            
            -- Kiểm tra thêm: xe có đang trong traffic flow không
            if GetVehicleEngineHealth(vehicle) > 990.0 and 
               not IsVehicleDamaged(vehicle) and
               GetPedType(driver) == 4 then -- PED_TYPE_CIVMALE/CIVFEMALE = 4
                print('[xn_pdtools] Confirmed traffic NPC vehicle')
                return true
            end
        end
    end
    
    -- 3. Kiểm tra xe có được spawn bởi script không
    -- Xe được spawn bởi player thường có entity owner
    local entityOwner = NetworkGetEntityOwner(vehicle)
    if entityOwner > 0 and GetPlayerServerId(entityOwner) > 0 then
        print('[xn_pdtools] Vehicle has player owner - Player vehicle')
        return false
    end
    
    -- 4. Default: nếu không có dấu hiệu rõ ràng là player vehicle thì coi là có thể NPC
    -- Nhưng chúng ta sẽ để server quyết định cuối cùng
    print('[xn_pdtools] Uncertain vehicle type - let server decide')
    return false -- Thay đổi default thành false để tránh false positive
end

-- Hàm hiển thị thông tin xe bằng alert dialog
local function ShowVehicleInfo(vehicleData)
    local content = ""
    
    -- Nếu là xe NPC, hiển thị thông báo đặc biệt
    if vehicleData.isNPC then
        content = string.format([[
**🤖 THÔNG BÁO**

Đây là **xe NPC** (Non-Player Character)

**🚗 Biển số:** %s  
**📍 Loại:** %s  
**⚠️ Tình trạng:** %s
        ]], 
        vehicleData.plate or 'Không xác định',
        vehicleData.owner or 'Xe NPC',
        vehicleData.status or 'Xe của NPC'
        )
        
        lib.alertDialog({
            header = '🤖 Xe NPC',
            content = content,
            centered = true,
            cancel = false
        })
        return
    end
    
    -- Hiển thị thông tin xe player bình thường
    content = string.format([[
**🚗 Biển số:** %s  
**👤 Chủ xe:** %s  
**⚠️ Tình trạng:** %s  
**🏷️ Mẫu xe:** %s  
**🎨 Màu sắc:** %s  
**📅 Ngày đăng ký:** %s
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
        content = content .. string.format('\n**🏠 Garage:** %s', vehicleData.garage)
    end
    
    lib.alertDialog({
        header = '🚔 Thông tin phương tiện',
        content = content,
        centered = true,
        cancel = false
    })
end

-- Hàm xử lý khi target vào xe để kiểm tra thông tin
local function OnVehicleCheck(data)
    local vehicle = data.entity
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    
    print('[xn_pdtools] Client checking vehicle with plate: ' .. plate)
    
    if not IsPoliceOfficer() then
        local message = 'Chỉ có công an đang onduty mới được phép kiểm tra thông tin xe!'
        if PlayerJob and PlayerJob.onduty == false then
            message = 'Bạn cần phải onduty để sử dụng tính năng này!'
        end
        lib.notify({
            title = 'Không có quyền',
            description = message,
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra xem xe có phải NPC không
    local isNPC = IsNPCVehicle(vehicle)
    
    print('[xn_pdtools] Vehicle is NPC: ' .. tostring(isNPC))
    
    -- Gửi request lên server với thông tin NPC
    TriggerServerEvent('xn_pdtools:getVehicleInfo', plate, isNPC)
end

-- Hàm xử lý khi target vào xe để xóa xe
local function OnVehicleDelete(data)
    local vehicle = data.entity
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    
    if not IsPoliceOfficer() then
        local message = 'Chỉ có công an đang onduty mới được phép xóa xe!'
        if PlayerJob and PlayerJob.onduty == false then
            message = 'Bạn cần phải onduty để sử dụng tính năng này!'
        end
        lib.notify({
            title = 'Không có quyền',
            description = message,
            type = 'error'
        })
        return
    end
    
    -- Xác nhận xóa xe
    local confirm = lib.alertDialog({
        header = '⚠️ Xác nhận xóa xe',
        content = 'Bạn có chắc chắn muốn xóa xe biển số: **' .. plate .. '**?\n\nHành động này không thể hoàn tác!',
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Hủy',
            confirm = 'Xóa xe'
        }
    })
    
    if confirm == 'confirm' then
        -- Kiểm tra xem xe có tồn tại không (kể cả xe bị nổ)
        if DoesEntityExist(vehicle) then
            -- Gửi log lên server trước khi xóa
            TriggerServerEvent('xn_pdtools:logVehicleDelete', plate)
            
            -- Xóa xe ngay lập tức
            DeleteEntity(vehicle)
            
            lib.notify({
                title = 'Thành công',
                description = 'Đã xóa xe biển số: ' .. plate,
                type = 'success'
            })
            
            print('[xn_pdtools] Vehicle deleted: ' .. plate)
        else
            lib.notify({
                title = 'Lỗi',
                description = 'Không thể xóa xe này!',
                type = 'error'
            })
        end
    end
end

-- Hàm xử lý khi target vào xe để mở khóa cửa
local function OnVehicleUnlock(data)
    local vehicle = data.entity
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    
    if not IsPoliceOfficer() then
        local message = 'Chỉ có công an đang onduty mới được phép mở khóa xe!'
        if PlayerJob and PlayerJob.onduty == false then
            message = 'Bạn cần phải onduty để sử dụng tính năng này!'
        end
        lib.notify({
            title = 'Không có quyền',
            description = message,
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra xem xe có bị khóa không
    local isLocked = GetVehicleDoorLockStatus(vehicle)
    
    if isLocked == 0 or isLocked == 1 then
        lib.notify({
            title = 'Thông báo',
            description = 'Xe biển số ' .. plate .. ' đã được mở khóa sẵn!',
            type = 'inform'
        })
        return
    end
    
    -- Mở khóa xe
    SetVehicleDoorsLocked(vehicle, 1) -- 1 = unlocked
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    
    -- Gửi log lên server
    TriggerServerEvent('xn_pdtools:logVehicleUnlock', plate)
    
    -- Hiệu ứng âm thanh
    PlaySoundFrontend(-1, "VEHICLE_LOCKS", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    
    lib.notify({
        title = 'Thành công',
        description = 'Đã mở khóa xe biển số: ' .. plate,
        type = 'success'
    })
    
    print('[xn_pdtools] Vehicle unlocked: ' .. plate)
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
        lib.notify({
            title = 'Không có thông tin',
            description = 'Không có dữ liệu về phương tiện này',
            type = 'warning'
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
    
    -- Thêm target cho kiểm tra thông tin xe
    ox_target:addGlobalVehicle({
        {
            name = 'vehicle_check',
            icon = Config.TargetOptions.icon,
            label = Config.TargetOptions.label,
            distance = Config.TargetOptions.distance,
            onSelect = OnVehicleCheck,
            canInteract = function(entity, distance, coords, name, bone)
                return IsPoliceOfficer()
            end
        },
        {
            name = 'vehicle_delete',
            icon = Config.DeleteVehicleOptions.icon,
            label = Config.DeleteVehicleOptions.label,
            distance = Config.DeleteVehicleOptions.distance,
            onSelect = OnVehicleDelete,
            canInteract = function(entity, distance, coords, name, bone)
                return IsPoliceOfficer()
            end
        },
        {
            name = 'vehicle_unlock',
            icon = Config.UnlockVehicleOptions.icon,
            label = Config.UnlockVehicleOptions.label,
            distance = Config.UnlockVehicleOptions.distance,
            onSelect = OnVehicleUnlock,
            canInteract = function(entity, distance, coords, name, bone)
                return IsPoliceOfficer()
            end
        }
    })
    
    print('[xn_pdtools] Vehicle targets added (check, delete, unlock)')
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

-- Event để refresh job khi player toggle onduty (QBCore)
RegisterNetEvent('QBCore:Client:SetDuty')
AddEventHandler('QBCore:Client:SetDuty', function(duty)
    Wait(500) -- Đợi duty update xong
    UpdatePlayerJob()
    print('[xn_pdtools] Duty status changed: ' .. tostring(duty))
end)

-- Command để test thủ công
RegisterCommand('checkjob', function()
    UpdatePlayerJob()
    if PlayerJob then
        local jobInfo = 'Job: ' .. PlayerJob.job
        if PlayerJob.onduty ~= nil then
            jobInfo = jobInfo .. ' | Onduty: ' .. (PlayerJob.onduty and 'Yes' or 'No')
        end
        print('Current job info: ' .. jobInfo)
        lib.notify({
            title = 'Job hiện tại',
            description = jobInfo,
            type = 'inform'
        })
    else
        print('No job data')
        lib.notify({
            title = 'Lỗi',
            description = 'Không có dữ liệu job',
            type = 'error'
        })
    end
end, false)
