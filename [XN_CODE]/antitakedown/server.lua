local allowedWeapons = {}

for i = 1, #Config.Weapons do
    local name = Config.Weapons[i]
    allowedWeapons[joaat(name)] = name
end

local function dbg(...)
    if Config.Debug then
        print('[understar_melee_guard_v1_8_2]', ...)
    end
end

local function isAllowedWeapon(hash)
    return hash ~= nil and allowedWeapons[hash] ~= nil
end

local function distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function resolveCurrentWeaponHash(playerId)
    local weapon =
        exports.ox_inventory:GetCurrentWeapon(playerId)

    if not weapon then
        return nil, 'NO_CURRENT_WEAPON'
    end

    local hash = tonumber(weapon.hash)

    if not hash and weapon.name then
        hash = joaat(weapon.name)
    end

    if not hash then
        return nil, 'WEAPON_HAS_NO_HASH_OR_NAME'
    end

    if not isAllowedWeapon(hash) then
        return hash, 'WEAPON_NOT_GUARDED'
    end

    return hash, nil
end

local function validatePair(attackerId, victimId, expectedWeaponHash)
    attackerId = tonumber(attackerId)
    victimId = tonumber(victimId)
    expectedWeaponHash = tonumber(expectedWeaponHash)

    if not attackerId
        or not victimId
        or attackerId <= 0
        or victimId <= 0
        or attackerId == victimId
    then
        return false, 'BAD_PAIR'
    end

    if not GetPlayerName(attackerId)
        or not GetPlayerName(victimId)
    then
        return false, 'PLAYER_NOT_CONNECTED'
    end

    if GetPlayerRoutingBucket(attackerId)
        ~= GetPlayerRoutingBucket(victimId)
    then
        return false, 'BUCKET_MISMATCH'
    end

    local weaponHash, weaponErr =
        resolveCurrentWeaponHash(attackerId)

    if weaponErr then
        return false, weaponErr
    end

    if expectedWeaponHash
        and weaponHash ~= expectedWeaponHash
    then
        return false, 'WEAPON_HASH_MISMATCH'
    end

    local attackerPed = GetPlayerPed(attackerId)
    local victimPed = GetPlayerPed(victimId)

    if attackerPed == 0 or victimPed == 0 then
        return false, 'NO_PED'
    end

    local dist = distance(
        GetEntityCoords(attackerPed),
        GetEntityCoords(victimPed)
    )

    if dist > Config.ServerMaxDistance then
        return false, ('DISTANCE_%.2f'):format(dist)
    end

    return true, nil, weaponHash, dist
end

RegisterNetEvent(
    'understar_melee_guard_v1_8_2:armVictimResetFlags',
    function(victimId, expectedWeaponHash)
        local attackerId = source
        victimId = tonumber(victimId)
        expectedWeaponHash = tonumber(expectedWeaponHash)

        local ok, reason, weaponHash, dist =
            validatePair(
                attackerId,
                victimId,
                expectedWeaponHash
            )

        if not ok then
            if Config.Debug then
                dbg(
                    'VICTIM GUARD REJECT',
                    attackerId,
                    victimId,
                    reason
                )
            end
            return
        end

        TriggerClientEvent(
            'understar_melee_guard_v1_8_2:armVictimResetFlags',
            victimId,
            attackerId,
            Config.PlayerVictimLeaseMs,
            weaponHash
        )

        -- Không log mỗi refresh để tránh spam.
    end
)
