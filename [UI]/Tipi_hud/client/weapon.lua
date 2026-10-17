local weaponRows = {
    { 'weapon_unarmed', 'Fists' },
    { 'weapon_dagger', 'Dagger' },
    { 'weapon_bat', 'Bat' },
    { 'weapon_bottle', 'Broken Bottle' },
    { 'weapon_crowbar', 'Crowbar' },
    { 'weapon_flashlight', 'Flashlight' },
    { 'weapon_golfclub', 'Golfclub' },
    { 'weapon_hammer', 'Hammer' },
    { 'weapon_hatchet', 'Hatchet' },
    { 'weapon_knuckle', 'Knuckle' },
    { 'weapon_knife', 'Knife' },
    { 'weapon_machete', 'Machete' },
    { 'weapon_switchblade', 'Switchblade' },
    { 'weapon_nightstick', 'Nightstick' },
    { 'weapon_wrench', 'Wrench' },
    { 'weapon_battleaxe', 'Battle Axe' },
    { 'weapon_poolcue', 'Poolcue' },
    { 'weapon_briefcase', 'Briefcase' },
    { 'weapon_briefcase_02', 'Suitcase' },
    { 'weapon_garbagebag', 'Garbage Bag' },
    { 'weapon_handcuffs', 'Handcuffs' },
    { 'weapon_bread', 'Baquette' },
    { 'weapon_stone_hatchet', 'Stone Hatchet' },
    { 'weapon_candycane', 'Candy Cane' },

    -- Handguns
    { 'weapon_pistol', 'Walther P99' },
    { 'weapon_pistol_mk2', 'Pistol Mk II' },
    { 'weapon_combatpistol', 'Combat Pistol' },
    { 'weapon_appistol', 'AP Pistol' },
    { 'weapon_stungun', 'Taser' },
    { 'weapon_pistol50', 'Pistol .50' },
    { 'weapon_snspistol', 'SNS Pistol' },
    { 'weapon_heavypistol', 'Heavy Pistol' },
    { 'weapon_vintagepistol', 'Vintage Pistol' },
    { 'weapon_flaregun', 'Flare Gun' },
    { 'weapon_marksmanpistol', 'Marksman Pistol' },
    { 'weapon_revolver', 'Revolver' },
    { 'weapon_revolver_mk2', 'Violence' },
    { 'weapon_doubleaction', 'Double Action Revolver' },
    { 'weapon_snspistol_mk2', 'SNS Pistol Mk II' },
    { 'weapon_raypistol', 'Up-n-Atomizer' },
    { 'weapon_ceramicpistol', 'Ceramic Pistol' },
    { 'weapon_navyrevolver', 'Navy Revolver' },
    { 'weapon_gadgetpistol', 'Perico Pistol' },
    { 'weapon_pistolxm3', 'Pistol XM3' },

    -- Submachine Guns
    { 'weapon_microsmg', 'Micro SMG' },
    { 'weapon_smg', 'SMG' },
    { 'weapon_smg_mk2', 'SMG Mk II' },
    { 'weapon_assaultsmg', 'Assault SMG' },
    { 'weapon_combatpdw', 'Combat PDW' },
    { 'weapon_machinepistol', 'Tec-9' },
    { 'weapon_minismg', 'Mini SMG' },
    { 'weapon_raycarbine', 'Unholy Hellbringer' },

    -- Shotguns
    { 'weapon_pumpshotgun', 'Pump Shotgun' },
    { 'weapon_sawnoffshotgun', 'Sawn-off Shotgun' },
    { 'weapon_assaultshotgun', 'Assault Shotgun' },
    { 'weapon_bullpupshotgun', 'Bullpup Shotgun' },
    { 'weapon_musket', 'Musket' },
    { 'weapon_heavyshotgun', 'Heavy Shotgun' },
    { 'weapon_dbshotgun', 'Double-barrel Shotgun' },
    { 'weapon_autoshotgun', 'Auto Shotgun' },
    { 'weapon_pumpshotgun_mk2', 'Pumpshotgun Mk II' },
    { 'weapon_combatshotgun', 'Combat Shotgun' },

    -- Assault Rifles
    { 'weapon_assaultrifle', 'Assault Rifle' },
    { 'weapon_assaultrifle_mk2', 'Assault Rifle Mk II' },
    { 'weapon_carbinerifle', 'Carbine Rifle' },
    { 'weapon_carbinerifle_mk2', 'Carbine Rifle Mk II' },
    { 'weapon_advancedrifle', 'Advanced Rifle' },
    { 'weapon_specialcarbine', 'Special Carbine' },
    { 'weapon_bullpuprifle', 'Bullpup Rifle' },
    { 'weapon_compactrifle', 'Compact Rifle' },
    { 'weapon_specialcarbine_mk2', 'Special Carbine Mk II' },
    { 'weapon_bullpuprifle_mk2', 'Bullpup Rifle Mk II' },
    { 'weapon_militaryrifle', 'Military Rifle' },

    -- Light Machine Guns
    { 'weapon_mg', 'Machinegun' },
    { 'weapon_combatmg', 'Combat MG' },
    { 'weapon_gusenberg', 'Thompson SMG' },
    { 'weapon_combatmg_mk2', 'Combat MG Mk II' },

    { 'weapon_sniperrifle', 'Sniper Rifle' },
    { 'weapon_heavysniper', 'Heavy Sniper' },
    { 'weapon_marksmanrifle', 'Marksman Rifle' },
    { 'weapon_remotesniper', 'Remote Sniper' },
    { 'weapon_heavysniper_mk2', 'Heavy Sniper Mk II' },
    { 'weapon_marksmanrifle_mk2', 'Marksman Rifle Mk II' },

    { 'weapon_rpg', 'RPG' },
    { 'weapon_grenadelauncher', 'Grenade Launcher' },
    { 'weapon_grenadelauncher_smoke', 'Smoke Grenade Launcher' },
    { 'weapon_minigun', 'Minigun' },
    { 'weapon_firework', 'Firework Launcher' },
    { 'weapon_railgun', 'Railgun' },
    { 'weapon_railgunxm3', 'Railgun XM3' },
    { 'weapon_hominglauncher', 'Homing Launcher' },
    { 'weapon_compactlauncher', 'Compact Launcher' },
    { 'weapon_rayminigun', 'Widowmaker' },

    -- Throwables
    { 'weapon_grenade', 'Grenade' },
    { 'weapon_bzgas', 'BZ Gas' },
    { 'weapon_molotov', 'Molotov' },
    { 'weapon_stickybomb', 'C4' },
    { 'weapon_proxmine', 'Proxmine Grenade' },
    { 'weapon_snowball', 'Snowball' },
    { 'weapon_pipebomb', 'Pipe Bomb' },
    { 'weapon_ball', 'Ball' },
    { 'weapon_smokegrenade', 'Smoke Grenade' },
    { 'weapon_flare', 'Flare pistol' },
}

local Weapons = {}
for _, row in ipairs(weaponRows) do
    local spawn, label = row[1], row[2]
    Weapons[GetHashKey(spawn)] = { spawn = spawn, label = label }
end

local GROUP_MELEE = joaat('GROUP_MELEE')
local GROUP_UNARMED = joaat('GROUP_UNARMED')

local function weaponUsesAmmo(ped, weaponHash)
    local group = GetWeapontypeGroup(weaponHash)
    if group == GROUP_MELEE or group == GROUP_UNARMED then
        return false
    end

    local maxClip = GetMaxAmmoInClip(ped, weaponHash, true)
    local total = GetAmmoInPedWeapon(ped, weaponHash)
    if (maxClip or 0) <= 0 and (total or 0) <= 0 then
        return false
    end

    return true
end

local function getEquippedWeaponDurability()
    if GetResourceState('ox_inventory') ~= 'started' then return nil end
    local ok, currentWeapon = pcall(function()
        return exports.ox_inventory:getCurrentWeapon()
    end)
    if not ok or type(currentWeapon) ~= 'table' or not currentWeapon.metadata then return nil end
    local durability = currentWeapon.metadata.durability
    if type(durability) ~= 'number' then return nil end
    if durability > 100 then
        return math.min(100, math.floor(durability / 10))
    end
    return math.max(0, math.min(100, math.floor(durability)))
end

local function resolveWeaponRow(ped)
    local hash = GetSelectedPedWeapon(ped)
    if not hash or hash == 0 or hash == joaat('WEAPON_UNARMED') then
        return { spawn = 'weapon_unarmed', label = 'Fists' }
    end

    local row = Weapons[hash]
    if row then return row end

    if GetResourceState('ox_inventory') == 'started' then
        local ok, currentWeapon = pcall(function()
            return exports.ox_inventory:getCurrentWeapon()
        end)
        if ok and type(currentWeapon) == 'table' and type(currentWeapon.name) == 'string' then
            local spawn = currentWeapon.name:lower()
            if not spawn:find('^weapon_') then
                spawn = 'weapon_' .. spawn
            end
            if spawn ~= 'weapon_unarmed' then
                return {
                    spawn = spawn,
                    label = currentWeapon.label or currentWeapon.name,
                }
            end
        end
    end

    return { spawn = 'weapon_unarmed', label = 'Fists' }
end

function GetWeaponHudPayload(ped)
    local weapon = GetSelectedPedWeapon(ped)
    if not weapon or weapon == 0 or weapon == joaat('WEAPON_UNARMED') or not IsPedArmed(ped, 7) then
        return { equipped = false }
    end

    local row = resolveWeaponRow(ped)
    if not row or row.spawn == 'weapon_unarmed' then
        return { equipped = false }
    end

    local usesAmmo = weaponUsesAmmo(ped, weapon)
    local inClip, reserve, maxClip = 0, 0, 0

    if usesAmmo then
        local _, clipAmmo = GetAmmoInClip(ped, weapon)
        local total = GetAmmoInPedWeapon(ped, weapon)
        maxClip = GetMaxAmmoInClip(ped, weapon, true)
        if not maxClip or maxClip < 1 then
            maxClip = clipAmmo
        end

        inClip = math.max(0, math.floor(clipAmmo or 0))
        total = math.max(0, math.floor(total or 0))
        maxClip = math.max(inClip, math.floor(maxClip or 0))
        reserve = math.max(0, total - inClip)
    end

    return {
        equipped = true,
        name = row.label or 'Weapon',
        spawn = row.spawn,
        usesAmmo = usesAmmo,
        inClip = inClip,
        reserve = reserve,
        maxClip = maxClip,
        durability = getEquippedWeaponDurability(),
    }
end
