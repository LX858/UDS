-- Tạo bảng tra cứu cho độ giật của từng súng
local weaponRecoil = {
    -- Pistols
    [GetHashKey("WEAPON_PISTOL")] = 0.4,
    [GetHashKey("WEAPON_PISTOL_MK2")] = 0.35,
    [GetHashKey("WEAPON_COMBATPISTOL")] = 0.3,
    [GetHashKey("WEAPON_APPISTOL")] = 0.6,
    [GetHashKey("WEAPON_PISTOL50")] = 0.7,
    [GetHashKey("WEAPON_SNSPISTOL")] = 0.3,
    [GetHashKey("WEAPON_HEAVYPISTOL")] = 0.5,
    [GetHashKey("WEAPON_VINTAGEPISTOL")] = 0.4,
    [GetHashKey("WEAPON_REVOLVER")] = 0.8,
    
    -- SMGs
    [GetHashKey("WEAPON_MICROSMG")] = 0.5,
    [GetHashKey("WEAPON_SMG")] = 0.2,
    [GetHashKey("WEAPON_ASSAULTSMG")] = 0.5,
    [GetHashKey("WEAPON_COMBATPDW")] = 0.45,
    
    -- Assault Rifles
    [GetHashKey("WEAPON_ASSAULTRIFLE_MK2")] = 0.3,
    [GetHashKey("WEAPON_CARBINERIFLE")] = 0.55,
    [GetHashKey("WEAPON_ADVANCEDRIFLE")] = 0.03,
    [GetHashKey("WEAPON_SPECIALCARBINE")] = 0.55,
    [GetHashKey("WEAPON_BULLPUPRIFLE")] = 0.5,
    
    -- Sniper Rifles
    [GetHashKey("WEAPON_SNIPERRIFLE")] = 0.9,
    [GetHashKey("WEAPON_HEAVYSNIPER")] = 1.0,
    [GetHashKey("WEAPON_MARKSMANRIFLE")] = 0.8,
    
    -- Shotguns
    [GetHashKey("WEAPON_PUMPSHOTGUN")] = 12.5,
    [GetHashKey("WEAPON_SAWNOFFSHOTGUN")] = 0.75,
    [GetHashKey("WEAPON_BULLPUPSHOTGUN")] = 0.65,
    [GetHashKey("WEAPON_ASSAULTSHOTGUN")] = 0.8,
    [GetHashKey("WEAPON_MUSKET")] = 0.9,
    [GetHashKey("WEAPON_HEAVYSHOTGUN")] = 0.85,
    
    -- Heavy Weapons
    [GetHashKey("WEAPON_GRENADELAUNCHER")] = 0.9,
    [GetHashKey("WEAPON_RPG")] = 1.0,
    [GetHashKey("WEAPON_MINIGUN")] = 0.9
    
}

-- Giá trị độ giật mặc định nếu không có trong bảng
local defaultRecoil = 0.5

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(0)
        local ply = PlayerPedId()
        -- SetPedSuffersCriticalHits(ply, true)

        if IsPedArmed(ply, 6) then
            DisableControlAction(1, 140, true)
            DisableControlAction(1, 141, true)
            DisableControlAction(1, 142, true)
            -- DisableControlAction(1, 21, true)
        elseif IsPedArmed(ply, 1) then
            N_0x4757f00bc6323cfe(GetHashKey("WEAPON_FLASHLIGHT"), 0.1)   
        else
            N_0x4757f00bc6323cfe(GetHashKey("WEAPON_UNARMED"), 0.35)
        end
        
        if IsPedShooting(ply) then      
            local _, wep = GetCurrentPedWeapon(ply)
            local _, cAmmo = GetAmmoInClip(ply, wep)
            
            -- Áp dụng độ giật tùy chỉnh cho từng loại súng
            local customRecoil = weaponRecoil[wep] or defaultRecoil
            N_0x4757f00bc6323cfe(wep, customRecoil)
            
            local GamePlayCam = GetFollowPedCamViewMode()
            local Vehicled = IsPedInAnyVehicle(ply, false)
            local MovementSpeed = math.ceil(GetEntitySpeed(ply))

            if MovementSpeed > 69 then
                MovementSpeed = 69
            end
            Citizen.Wait(50)
            local _, wep = GetCurrentPedWeapon(ply)
            if wep ~= 126349499 then
                local group = GetWeapontypeGroup(wep)
                local p = GetGameplayCamRelativePitch()
                local cameraDistance = #(GetGameplayCamCoord() - GetEntityCoords(ply))

                -- Áp dụng hệ số độ giật từ bảng tra cứu
                local baseRecoil = weaponRecoil[wep] or defaultRecoil
                local recoil = (math.random(100, 120 + MovementSpeed) / 100) * baseRecoil * 2
                local rifle = false

                if group == 970310034 then
                    rifle = true
                end

                if cameraDistance < 3.3 then
                    cameraDistance = 1.5
                else
                    if cameraDistance < 6.0 then
                        cameraDistance = 3.0
                    else
                        cameraDistance = 5.0
                    end
                end

                if Vehicled then
                    recoil = recoil + (recoil * cameraDistance)
                else
                    recoil = recoil * 0.5
                end

                if GamePlayCam == 3 then
                    recoil = recoil * 0.3
                    if rifle then
                        recoil = recoil * 0.4
                    end
                end

                if rifle then
                    recoil = recoil * 0.4
                end

                local rightleft = math.random(4)
                local h = GetGameplayCamRelativeHeading()
                local hf = math.random(10, 20 + MovementSpeed) / 100

                if Vehicled then
                    hf = hf * 2.0
                end

                if rightleft == 1 then
                    SetGameplayCamRelativeHeading(h + hf)
                elseif rightleft == 2 then
                    SetGameplayCamRelativeHeading(h - hf)
                end 
            
                local set = p + recoil

                SetGameplayCamRelativePitch(set, 0.8)   
            end          
        end
    end
end)