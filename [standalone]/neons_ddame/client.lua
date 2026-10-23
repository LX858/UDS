local pInfo = {
    health = 0,
    armour = 0
}

local currentWeapon = nil
local weaponConfigCache = {}

local function DisplayText(nameDisplayMode, playerSrc, player)
    if nameDisplayMode == 1 then
        local playerName = Player(playerSrc).state.name or GetPlayerName(player)
        local playerId = Player(playerSrc).state.idCard or playerSrc
        return "[" .. tostring(playerId) .. "] " .. playerName
    end
    return ""
end

local function getWeaponConfig(weaponHash)
    local cached = weaponConfigCache[weaponHash]
    if cached ~= nil then return cached or nil end

    local weaponConfig = Config.WeaponDamages[weaponHash]
    if not weaponConfig then
        weaponConfigCache[weaponHash] = false
        return nil
    end

    local defaults = Config.WeaponDefaults or {}
    cached = {
        damage = weaponConfig.damage,
        headshot = weaponConfig.headshot,
        recoil = weaponConfig.recoil or defaults.recoil or 0.0,
        spread = weaponConfig.spread ~= nil and weaponConfig.spread or defaults.spread,
        range = weaponConfig.range or defaults.range or 120.0,
        maxRange = weaponConfig.maxRange or defaults.maxRange,
        minDamage = weaponConfig.minDamage or defaults.minDamage or 1
    }
    weaponConfigCache[weaponHash] = cached
    return cached
end

local function applyWeaponSpread(weaponHash, weaponConfig)
    if weaponConfig.spread == nil then return end
    if SetWeaponAccuracySpread then
        SetWeaponAccuracySpread(weaponHash, weaponConfig.spread + 0.0)
    end
end

local function applyWeaponRecoil(weaponHash, weaponConfig)
    if SetWeaponRecoilShakeAmplitude then
        SetWeaponRecoilShakeAmplitude(weaponHash, weaponConfig.recoil + 0.0)
    end
end

local function applyCameraRecoil(weaponConfig)
    local recoil = weaponConfig.recoil or 0.0
    if recoil <= 0.0 then return end

    local pitchKick = recoil * (0.25 + math.random() * 0.35)
    local headingKick = recoil * ((math.random() - 0.5) * 0.25)
    SetGameplayCamRelativePitch(GetGameplayCamRelativePitch() + pitchKick, 1.0)
    SetGameplayCamRelativeHeading(GetGameplayCamRelativeHeading() + headingKick)
end

RegisterFontFile("Oswald")
fontId = RegisterFontId("Oswald")

Citizen.CreateThread(function()
    while true do 
        for k, v in pairs(Config.WeaponDamages) do 
            SetWeaponDamageModifier(k, 0.0000001)
        end
        Wait(100)
    end 
end)

CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        pInfo.health = GetEntityHealth(player)
        pInfo.armour = GetPedArmour(player)
        SetPedSuffersCriticalHits(player, false)
    end
end)
local audioOn = true
AddEventHandler('damage:sounds', function(soundFile, soundVolume)
    if not audioOn then return end
    SendNUIMessage({
      transactionType = 'playSound',
      transactionFile = soundFile,
      transactionVolume = soundVolume
    })
end)

RegisterCommand("tiengdame", function()
    audioOn = not audioOn
end, false)

local DrawText2D = function(text, scale, x, y, a, color)
	SetTextScale(0.33, 0.33)
	SetTextFont(1)
	SetTextColour(color and tonumber(color.r or 0) or 0, color and tonumber(color.g or 0) or 0, color and tonumber(color.b or 0) or 0, 255)
	SetTextCentre(true)
    SetTextDropShadow(1)
    SetTextOutline(1)
    SetTextProportional(1)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName("<font face='Oswald'>".. text .."</font>")
	EndTextCommandDisplayText(x, y)
	ClearDrawOrigin()
end

function DrawText3D(text, x, y, z, color)

	DrawText2D(text, 11, y, z, nil, color)
end

local DrawText2DTweenUp = function(text, scale, x, y, moveheight, speed, color)
    Citizen.CreateThread(function()
        local height = y
        local total_ = height - (y - moveheight) 
        local total = height - (y - moveheight)
        while height > (y - moveheight) do 
            DrawText2D(text, scale, x, height, math.floor(255* (total/total_)), color)
            height = height - 0.002 * speed
            total = total - 0.002 * speed
            Citizen.Wait(1)
        end
    end)
end

local lastHit =  vector3(0, 0, 0)
local DrawText3DTweenUp = function(text, scale, x, y, z, moveheight, speed, color)
    if #(lastHit - vector3(x, y, z)) < 0.3 then 
        z = z + 0.2
    end
    --print(x,y,z)
    Citizen.CreateThread(function()
        local height = z
        local total = height - (z - moveheight)
        while height > (z - moveheight) do 
            DrawText3D(text, x, y, height, color)
            height = height - 0.002 * speed
            total = total - 0.002 * speed
            Citizen.Wait(1)
        end
    end)
end

OnEntityHealthChange = function(victim, value, bonehash, color, dead, zHeight)
    zHeight = zHeight or 0.0
    local coords =  GetEntityCoords(victim) + vec3(0.0, 0.0, zHeight + 0.0)
    local camCoords = GetGameplayCamCoords()
    local distance = #(coords - camCoords)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    if scale < 0.2 then scale = 0.2 end 
    -- DrawText2DTweenUp(tostring(value), 11, 0.550, 0.453, 0.1, 0.18, color)
    TriggerEvent("damage:sounds", "hitmarker", 1.0)
end

AddEventHandler("gameEventTriggered", function(name, data)
    if name ~= "CEventNetworkEntityDamage" then return end

    local ped = cache.ped
    local victim = tonumber(data[1])
    local attacker = tonumber(data[2])
    local weaponHash = tonumber(data[7])
    local attackerPed = NetworkGetPlayerIndexFromPed(attacker)
    local attackerId = GetPlayerServerId(attackerPed)
    if victim == ped then
        local HealthCache = pInfo
        local Health, Armour = HealthCache.health, HealthCache.armour
        local PedArmour = GetPedArmour(ped)
        local PedHealth = GetEntityHealth(ped)
        local HitHealth, HitArmour = 0, 0
        local distance = #(GetEntityCoords(ped) - GetEntityCoords(attacker))
        if Health > PedHealth then 
            HitHealth = Health - PedHealth
        end
        if Armour > PedArmour then 
            HitArmour = Armour - PedArmour
        end
        local FoundLastDamagedBone, LastDamagedBone = GetPedLastDamageBone(ped)
        local IsHead = FoundLastDamagedBone and (LastDamagedBone == 31086 or LastDamagedBone == 12844 or LastDamagedBone == 39317)
        local Damage = HitHealth + HitArmour
        local weaponConfig = getWeaponConfig(weaponHash)
        if weaponConfig then
            if weaponConfig.maxRange and distance > weaponConfig.maxRange then
                Damage = 0
            else
                Damage = IsHead and weaponConfig.headshot or weaponConfig.damage
                -- if distance > weaponConfig.range then
                --     local falloff = (distance - weaponConfig.range) / 10
                --     Damage = Damage - falloff
                --     if Damage < weaponConfig.minDamage then
                --         Damage = weaponConfig.minDamage
                --     end
                -- end
            end
        end
        SetEntityHealth(ped, Health)
        SetPedArmour(ped, Armour)
        if Damage <= 0 then return end
        ApplyDamageToPed(ped, Damage, true)
        PedArmour = GetPedArmour(ped)
        PedHealth = GetEntityHealth(ped)
        HitHealth, HitArmour = 0, 0
        if Health > PedHealth then 
            HitHealth = Health - PedHealth
        end
        if Armour > PedArmour then 
            HitArmour = Armour - PedArmour
        end
        local deathState = LocalPlayer.state['qbx_medical:deathState']
        local victimDied = IsEntityDead(ped) or PedHealth <= 100 or deathState == 2 or deathState == 3
        if not IsPedAPlayer(attacker) or not attackerId then return end 
        WS.TriggerServerEvent("neons_ddame:server:hit", attackerId, HitHealth, HitArmour, victimDied)
        
        local attackerFormattedName = DisplayText(1, attackerId, attackerPed)
        --print("Người bắn: " .. attackerFormattedName .. " | Máu: " .. HitHealth .. " | Giáp: " .. HitArmour .. " | " .. (IsHead and "Bắn Đầu" or "Bắn Người"))
    end
end)

WS.RegisterEventHandler("neons_ddame:client:hit", function(victimId, hitHealth, hitArmour, victimDied)
    local victim = GetPlayerPed(GetPlayerFromServerId(victimId))
    victimDied = victimDied == true or hitHealth >= 100
    if hitArmour > 0 then
        OnEntityHealthChange(victim, hitArmour, nil, {r = 48, g = 152, b = 196}, victimDied, 1.0)
    end
    if hitHealth > 0 then
        OnEntityHealthChange(victim, hitHealth > 100 and "DEAD" or hitHealth, nil,  {r = 212, g = 84, b = 84}, victimDied, 0.0)
    end
end)



local requestedIpl = {
    "h4_mph4_terrain_01_grass_0",
    "h4_mph4_terrain_01_grass_1",
    "h4_mph4_terrain_02_grass_0",
    "h4_mph4_terrain_02_grass_1",
    "h4_mph4_terrain_02_grass_2",
    "h4_mph4_terrain_02_grass_3",
    "h4_mph4_terrain_04_grass_0",
    "h4_mph4_terrain_04_grass_1",
    "h4_mph4_terrain_05_grass_0",
    "h4_mph4_terrain_06_grass_0",
    "h4_islandx_terrain_01",
    "h4_islandx_terrain_01_lod",
    "h4_islandx_terrain_01_slod",
    "h4_islandx_terrain_02",
    "h4_islandx_terrain_02_lod",
    "h4_islandx_terrain_02_slod",
    "h4_islandx_terrain_03",
    "h4_islandx_terrain_03_lod",
    "h4_islandx_terrain_04",
    "h4_islandx_terrain_04_lod",
    "h4_islandx_terrain_04_slod",
    "h4_islandx_terrain_05",
    "h4_islandx_terrain_05_lod",
    "h4_islandx_terrain_05_slod",
    "h4_islandx_terrain_06",
    "h4_islandx_terrain_06_lod",
    "h4_islandx_terrain_06_slod",
    "h4_islandx_terrain_props_05_a",
    "h4_islandx_terrain_props_05_a_lod",
    "h4_islandx_terrain_props_05_b",
    "h4_islandx_terrain_props_05_b_lod",
    "h4_islandx_terrain_props_05_c",
    "h4_islandx_terrain_props_05_c_lod",
    "h4_islandx_terrain_props_05_d",
    "h4_islandx_terrain_props_05_d_lod",
    "h4_islandx_terrain_props_05_d_slod",
    "h4_islandx_terrain_props_05_e",
    "h4_islandx_terrain_props_05_e_lod",
    "h4_islandx_terrain_props_05_e_slod",
    "h4_islandx_terrain_props_05_f",
    "h4_islandx_terrain_props_05_f_lod",
    "h4_islandx_terrain_props_05_f_slod",
    "h4_islandx_terrain_props_06_a",
    "h4_islandx_terrain_props_06_a_lod",
    "h4_islandx_terrain_props_06_a_slod",
    "h4_islandx_terrain_props_06_b",
    "h4_islandx_terrain_props_06_b_lod",
    "h4_islandx_terrain_props_06_b_slod",
    "h4_islandx_terrain_props_06_c",
    "h4_islandx_terrain_props_06_c_lod",
    "h4_islandx_terrain_props_06_c_slod",
    "h4_mph4_terrain_01",
    "h4_mph4_terrain_01_long_0",
    "h4_mph4_terrain_02",
    "h4_mph4_terrain_03",
    "h4_mph4_terrain_04",
    "h4_mph4_terrain_05",
    "h4_mph4_terrain_06",
    "h4_mph4_terrain_06_strm_0",
    "h4_mph4_terrain_lod",
    "h4_mph4_terrain_occ_00",
    "h4_mph4_terrain_occ_01",
    "h4_mph4_terrain_occ_02",
    "h4_mph4_terrain_occ_03",
    "h4_mph4_terrain_occ_04",
    "h4_mph4_terrain_occ_05",
    "h4_mph4_terrain_occ_06",
    "h4_mph4_terrain_occ_07",
    "h4_mph4_terrain_occ_08",
    "h4_mph4_terrain_occ_09",
    "h4_boatblockers",
    "h4_islandx",
    "h4_islandx_disc_strandedshark",
    "h4_islandx_disc_strandedshark_lod",
    "h4_islandx_disc_strandedwhale",
    "h4_islandx_disc_strandedwhale_lod",
    "h4_islandx_props",
    "h4_islandx_props_lod",
    "h4_islandx_sea_mines",
    "h4_mph4_island",
    "h4_mph4_island_long_0",
    "h4_mph4_island_strm_0",
    "h4_aa_guns",
    "h4_aa_guns_lod",
    "h4_beach",
    "h4_beach_bar_props",
    "h4_beach_lod",
    "h4_beach_party",
    "h4_beach_party_lod",
    "h4_beach_props",
    "h4_beach_props_lod",
    "h4_beach_props_party",
    "h4_beach_props_slod",
    "h4_beach_slod",
    "h4_islandairstrip",
    "h4_islandairstrip_doorsclosed",
    "h4_islandairstrip_doorsclosed_lod",
    "h4_islandairstrip_doorsopen",
    "h4_islandairstrip_doorsopen_lod",
    "h4_islandairstrip_hangar_props",
    "h4_islandairstrip_hangar_props_lod",
    "h4_islandairstrip_hangar_props_slod",
    "h4_islandairstrip_lod",
    "h4_islandairstrip_props",
    "h4_islandairstrip_propsb",
    "h4_islandairstrip_propsb_lod",
    "h4_islandairstrip_propsb_slod",
    "h4_islandairstrip_props_lod",
    "h4_islandairstrip_props_slod",
    "h4_islandairstrip_slod",
    "h4_islandxcanal_props",
    "h4_islandxcanal_props_lod",
    "h4_islandxcanal_props_slod",
    "h4_islandxdock",
    "h4_islandxdock_lod",
    "h4_islandxdock_props",
    "h4_islandxdock_props_2",
    "h4_islandxdock_props_2_lod",
    "h4_islandxdock_props_2_slod",
    "h4_islandxdock_props_lod",
    "h4_islandxdock_props_slod",
    "h4_islandxdock_slod",
    "h4_islandxdock_water_hatch",
    "h4_islandxtower",
    "h4_islandxtower_lod",
    "h4_islandxtower_slod",
    "h4_islandxtower_veg",
    "h4_islandxtower_veg_lod",
    "h4_islandxtower_veg_slod",
    "h4_islandx_barrack_hatch",
    "h4_islandx_barrack_props",
    "h4_islandx_barrack_props_lod",
    "h4_islandx_barrack_props_slod",
    "h4_islandx_checkpoint",
    "h4_islandx_checkpoint_lod",
    "h4_islandx_checkpoint_props",
    "h4_islandx_checkpoint_props_lod",
    "h4_islandx_checkpoint_props_slod",
    "h4_islandx_maindock",
    "h4_islandx_maindock_lod",
    "h4_islandx_maindock_props",
    "h4_islandx_maindock_props_2",
    "h4_islandx_maindock_props_2_lod",
    "h4_islandx_maindock_props_2_slod",
    "h4_islandx_maindock_props_lod",
    "h4_islandx_maindock_props_slod",
    "h4_islandx_maindock_slod",
    "h4_islandx_mansion",
    "h4_islandx_mansion_b",
    "h4_islandx_mansion_b_lod",
    "h4_islandx_mansion_b_side_fence",
    "h4_islandx_mansion_b_slod",
    "h4_islandx_mansion_entrance_fence",
    "h4_islandx_mansion_guardfence",
    "h4_islandx_mansion_lights",
    "h4_islandx_mansion_lockup_01",
    "h4_islandx_mansion_lockup_01_lod",
    "h4_islandx_mansion_lockup_02",
    "h4_islandx_mansion_lockup_02_lod",
    "h4_islandx_mansion_lockup_03",
    "h4_islandx_mansion_lockup_03_lod",
    "h4_islandx_mansion_lod",
    "h4_islandx_mansion_office",
    "h4_islandx_mansion_office_lod",
    "h4_islandx_mansion_props",
    "h4_islandx_mansion_props_lod",
    "h4_islandx_mansion_props_slod",
    "h4_islandx_mansion_slod",
    "h4_islandx_mansion_vault",
    "h4_islandx_mansion_vault_lod",
    "h4_island_padlock_props",
    -- "h4_mansion_gate_broken",
    "h4_mansion_gate_closed",
    "h4_mansion_remains_cage",
    "h4_mph4_airstrip",
    "h4_mph4_airstrip_interior_0_airstrip_hanger",
    "h4_mph4_beach",
    "h4_mph4_dock",
    "h4_mph4_island_lod",
    "h4_mph4_island_ne_placement",
    "h4_mph4_island_nw_placement",
    "h4_mph4_island_se_placement",
    "h4_mph4_island_sw_placement",
    "h4_mph4_mansion",
    "h4_mph4_mansion_b",
    "h4_mph4_mansion_b_strm_0",
    "h4_mph4_mansion_strm_0",
    "h4_mph4_wtowers",
    "h4_ne_ipl_00",
    "h4_ne_ipl_00_lod",
    "h4_ne_ipl_00_slod",
    "h4_ne_ipl_01",
    "h4_ne_ipl_01_lod",
    "h4_ne_ipl_01_slod",
    "h4_ne_ipl_02",
    "h4_ne_ipl_02_lod",
    "h4_ne_ipl_02_slod",
    "h4_ne_ipl_03",
    "h4_ne_ipl_03_lod",
    "h4_ne_ipl_03_slod",
    "h4_ne_ipl_04",
    "h4_ne_ipl_04_lod",
    "h4_ne_ipl_04_slod",
    "h4_ne_ipl_05",
    "h4_ne_ipl_05_lod",
    "h4_ne_ipl_05_slod",
    "h4_ne_ipl_06",
    "h4_ne_ipl_06_lod",
    "h4_ne_ipl_06_slod",
    "h4_ne_ipl_07",
    "h4_ne_ipl_07_lod",
    "h4_ne_ipl_07_slod",
    "h4_ne_ipl_08",
    "h4_ne_ipl_08_lod",
    "h4_ne_ipl_08_slod",
    "h4_ne_ipl_09",
    "h4_ne_ipl_09_lod",
    "h4_ne_ipl_09_slod",
    "h4_nw_ipl_00",
    "h4_nw_ipl_00_lod",
    "h4_nw_ipl_00_slod",
    "h4_nw_ipl_01",
    "h4_nw_ipl_01_lod",
    "h4_nw_ipl_01_slod",
    "h4_nw_ipl_02",
    "h4_nw_ipl_02_lod",
    "h4_nw_ipl_02_slod",
    "h4_nw_ipl_03",
    "h4_nw_ipl_03_lod",
    "h4_nw_ipl_03_slod",
    "h4_nw_ipl_04",
    "h4_nw_ipl_04_lod",
    "h4_nw_ipl_04_slod",
    "h4_nw_ipl_05",
    "h4_nw_ipl_05_lod",
    "h4_nw_ipl_05_slod",
    "h4_nw_ipl_06",
    "h4_nw_ipl_06_lod",
    "h4_nw_ipl_06_slod",
    "h4_nw_ipl_07",
    "h4_nw_ipl_07_lod",
    "h4_nw_ipl_07_slod",
    "h4_nw_ipl_08",
    "h4_nw_ipl_08_lod",
    "h4_nw_ipl_08_slod",
    "h4_nw_ipl_09",
    "h4_nw_ipl_09_lod",
    "h4_nw_ipl_09_slod",
    "h4_se_ipl_00",
    "h4_se_ipl_00_lod",
    "h4_se_ipl_00_slod",
    "h4_se_ipl_01",
    "h4_se_ipl_01_lod",
    "h4_se_ipl_01_slod",
    "h4_se_ipl_02",
    "h4_se_ipl_02_lod",
    "h4_se_ipl_02_slod",
    "h4_se_ipl_03",
    "h4_se_ipl_03_lod",
    "h4_se_ipl_03_slod",
    "h4_se_ipl_04",
    "h4_se_ipl_04_lod",
    "h4_se_ipl_04_slod",
    "h4_se_ipl_05",
    "h4_se_ipl_05_lod",
    "h4_se_ipl_05_slod",
    "h4_se_ipl_06",
    "h4_se_ipl_06_lod",
    "h4_se_ipl_06_slod",
    "h4_se_ipl_07",
    "h4_se_ipl_07_lod",
    "h4_se_ipl_07_slod",
    "h4_se_ipl_08",
    "h4_se_ipl_08_lod",
    "h4_se_ipl_08_slod",
    "h4_se_ipl_09",
    "h4_se_ipl_09_lod",
    "h4_se_ipl_09_slod",
    "h4_sw_ipl_00",
    "h4_sw_ipl_00_lod",
    "h4_sw_ipl_00_slod",
    "h4_sw_ipl_01",
    "h4_sw_ipl_01_lod",
    "h4_sw_ipl_01_slod",
    "h4_sw_ipl_02",
    "h4_sw_ipl_02_lod",
    "h4_sw_ipl_02_slod",
    "h4_sw_ipl_03",
    "h4_sw_ipl_03_lod",
    "h4_sw_ipl_03_slod",
    "h4_sw_ipl_04",
    "h4_sw_ipl_04_lod",
    "h4_sw_ipl_04_slod",
    "h4_sw_ipl_05",
    "h4_sw_ipl_05_lod",
    "h4_sw_ipl_05_slod",
    "h4_sw_ipl_06",
    "h4_sw_ipl_06_lod",
    "h4_sw_ipl_06_slod",
    "h4_sw_ipl_07",
    "h4_sw_ipl_07_lod",
    "h4_sw_ipl_07_slod",
    "h4_sw_ipl_08",
    "h4_sw_ipl_08_lod",
    "h4_sw_ipl_08_slod",
    "h4_sw_ipl_09",
    "h4_sw_ipl_09_lod",
    "h4_sw_ipl_09_slod",
    "h4_underwater_gate_closed",
    "h4_islandx_placement_01",
    "h4_islandx_placement_02",
    "h4_islandx_placement_03",
    "h4_islandx_placement_04",
    "h4_islandx_placement_05",
    "h4_islandx_placement_06",
    "h4_islandx_placement_07",
    "h4_islandx_placement_08",
    "h4_islandx_placement_09",
    "h4_islandx_placement_10",
    "h4_mph4_island_placement"
    }
    
    
    
    CreateThread(function()
        for i = #requestedIpl, 1, -1 do
            RequestIpl(requestedIpl[i])
            requestedIpl[i] = nil
        end
    
        requestedIpl = nil
    end)
    
    CreateThread(function()
        while true do
            SetRadarAsExteriorThisFrame()
            SetRadarAsInteriorThisFrame(`h4_fake_islandx`, vec(4700.0, -5145.0), 0, 0)
            Wait(0)
        end
    end)
    
    CreateThread(function()
        SetDeepOceanScaler(0.0)
        local islandLoaded = false
        local islandCoords = vector3(4840.571, -5174.425, 2.0)
    
        while true do
            local pCoords = GetEntityCoords(PlayerPedId())
    
            if #(pCoords - islandCoords) < 2000.0 then
                if not islandLoaded then
                    islandLoaded = true
                    Citizen.InvokeNative(0x9A9D1BA639675CF1, "HeistIsland", 1)
                    Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 1) -- island path nodes (from Disquse)
                    SetScenarioGroupEnabled('Heist_Island_Peds', 1)
                    -- SetAudioFlag('PlayerOnDLCHeist4Island', 1)
                    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', 1, 1)
                    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', 0, 1)
                end
            else
                if islandLoaded then
                    islandLoaded = false
                    Citizen.InvokeNative(0x9A9D1BA639675CF1, "HeistIsland", 0)
                    Citizen.InvokeNative(0xF74B1FFA4A15FBEA, 0)
                    SetScenarioGroupEnabled('Heist_Island_Peds', 0)
                    -- SetAudioFlag('PlayerOnDLCHeist4Island', 0)
                    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', 0, 0)
                    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', 1, 0)
                end
            end
    
            Wait(5000)
        end
    end)
    
    Citizen.CreateThread(function()
      SetDeepOceanScaler(0.0)
    end)
