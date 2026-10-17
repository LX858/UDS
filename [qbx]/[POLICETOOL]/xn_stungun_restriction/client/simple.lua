local QBX = exports.qbx_core
local CurrentWeapon = exports.ox_inventory:getCurrentWeapon()
local wpCurrent = false

-- Hook vào ox_inventory khi trang bị vũ khí
AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
    CurrentWeapon = currentWeapon
    
    if CurrentWeapon and CurrentWeapon.name == 'WEAPON_STUNGUN' then
        local playerData = QBX:GetPlayerData()
        if not playerData then return end
        
        -- Kiểm tra job
        local hasPermission = false
        for _, job in ipairs(Config.AllowedJobs) do
            if playerData.job.name == job then
                hasPermission = true
                break
            end
        end
        
        -- Nếu không có quyền thì cấm sử dụng
        if not hasPermission then
            wpCurrent = true
            
            exports.ox_lib:notify({
                title = 'Hệ thống bảo mật',
                description = Config.Messages.restricted,
                type = 'error',
                duration = 5000
            })
            
            -- Đợi một chút rồi disarm
            Wait(500)
            TriggerEvent('ox_inventory:disarm', PlayerPedId(), true)
            
            -- Log cho server
            TriggerServerEvent('xn_stungun:attemptUse')
        end
    else
        wpCurrent = false
    end
end)

-- Function loop disarm nếu cần
function loopWP()
    CreateThread(function()
        while wpCurrent do
            Wait(300)
            TriggerEvent('ox_inventory:disarm', PlayerPedId(), true)
            if not wpCurrent then
                break
            end
        end
    end)
end