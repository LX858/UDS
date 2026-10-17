local QBX = exports.qbx_core
local CurrentWeapon = exports.ox_inventory:getCurrentWeapon()
local wpCurrent = false

-- Kiểm tra job có được phép không
local function IsJobAllowed()
    local playerData = QBX:GetPlayerData()
    if not playerData or not playerData.job then return false end
    
    -- Kiểm tra xem có đúng job không
    local hasJob = false
    for _, job in ipairs(Config.AllowedJobs) do
        if playerData.job.name == job then
            hasJob = true
            break
        end
    end
    
    -- Phải có đúng job VÀ phải onduty
    if hasJob and playerData.job.onduty then
        return true
    end
    
    return false
end

-- Kiểm tra vũ khí có bị cấm không
local function IsWeaponRestricted(weaponName)
    for _, weapon in ipairs(Config.RestrictedWeapons) do
        if weaponName == weapon or weaponName == weapon:lower() then
            return true
        end
    end
    return false
end

-- Hook vào ox_inventory khi trang bị vũ khí
AddEventHandler('ox_inventory:currentWeapon', function(currentWeapon)
    CurrentWeapon = currentWeapon
    
    -- Kiểm tra nếu là vũ khí bị cấm
    if CurrentWeapon and IsWeaponRestricted(CurrentWeapon.name) then
        
        -- Nếu không có quyền thì cấm sử dụng
        if not IsJobAllowed() then
            wpCurrent = true
            
            exports.ox_lib:notify({
                title = 'Hệ thống bảo mật',
                description = Config.Messages.restricted,
                type = 'error',
                duration = 5000
            })
            
            -- Đợi một chút rồi disarm
            CreateThread(function()
                Wait(500)
                TriggerEvent('ox_inventory:disarm', PlayerPedId(), true)
                
                -- Log cho server
                
            end)
            
            -- Bắt đầu loop disarm để đảm bảo
            loopWP()
        end
    else
        wpCurrent = false
    end
end)

-- Thread kiểm tra liên tục (backup method)
CreateThread(function()
    while true do
        Wait(2000)
        
        if IsJobAllowed() then
            goto continue
        end
        
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        
        -- Kiểm tra tất cả vũ khí bị cấm
        local isRestricted = false
        for _, restrictedWeapon in ipairs(Config.RestrictedWeapons) do
            if weapon == GetHashKey(restrictedWeapon) then
                isRestricted = true
                break
            end
        end
        
        if isRestricted then
            wpCurrent = true
            
            exports.ox_lib:notify({
                title = 'Hệ thống bảo mật',
                description = Config.Messages.restricted,
                type = 'error',
                duration = 3000
            })
            
            -- Force disarm
            RemoveWeaponFromPed(ped, weapon)
            SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
            
            
        end
        
        ::continue::
    end
end)

-- Function loop disarm nếu cần
function loopWP()
    CreateThread(function()
        while wpCurrent do
            Wait(300)
            if CurrentWeapon and IsWeaponRestricted(CurrentWeapon.name) then
                TriggerEvent('ox_inventory:disarm', PlayerPedId(), true)
            end
            
            if not wpCurrent then
                break
            end
        end
    end)
end