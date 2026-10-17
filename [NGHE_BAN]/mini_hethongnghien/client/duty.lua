-- ===============================================
-- Duty System - Bác Sĩ Cai Nghiện
-- ===============================================

local QBX = exports.qbx_core:GetCoreObject()

-- Toggle duty
local function ToggleDuty()
    TriggerServerEvent('QBCore:ToggleDuty')
end

-- Tạo duty zones
CreateThread(function()
    if not Config.Job or not Config.Job.dutyPoints then return end
    
    for i = 1, #Config.Job.dutyPoints do
        local dutyPoint = Config.Job.dutyPoints[i]
        local coords = vec3(dutyPoint.x, dutyPoint.y, dutyPoint.z)
        
        -- Tạo ox_target zone
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.5,
            debug = Config.Debug,
            options = {
                {
                    name = 'bacsinghien_duty',
                    icon = 'fa-solid fa-clipboard',
                    label = 'Thay Đổi Trạng Thái',
                    groups = Config.Job.jobName,  -- Chỉ job bacsinghien mới thấy
                    onSelect = function()
                        ToggleDuty()
                    end
                }
            }
        })
    end
end)
