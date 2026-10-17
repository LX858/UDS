local allowedWeapons = {}

for i = 1, #Config.Weapons do
    local name = Config.Weapons[i]
    allowedWeapons[joaat(name)] = name
end

local usingGuardedWeapon = false
local activeWeaponHash = 0
local activeWeaponName = nil

local sessionActive = false
local sessionSerial = 0

local lastVictimSid = 0
local nextVictimRefresh = 0

local recentTarget = 0
local recentTargetAt = 0
local recentTargetSource = nil

-- Victim-owner reset-flag lease.
local victimGuardUntil = 0
local victimGuardAttackerSid = 0
local victimGuardWeaponHash = 0
local victimGuardLogged = false

local ATTACK_CONTROLS = {
    24,
    140,
    141,
    142,
    257,
    263,
    264,
}

local function dbg(...)
    if Config.Debug then
        print('[understar_melee_guard_v1_8_2]', ...)
    end
end

local function isAllowedWeapon(hash)
    return hash ~= nil and allowedWeapons[hash] ~= nil
end

local function validPed(ped)
    return ped ~= 0
        and DoesEntityExist(ped)
        and IsEntityAPed(ped)
        and not IsEntityDead(ped)
end

local function pedDistance(a, b)
    local ac = GetEntityCoords(a)
    local bc = GetEntityCoords(b)

    local dx = ac.x - bc.x
    local dy = ac.y - bc.y
    local dz = ac.z - bc.z

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function rememberNativeTarget(target, source)
    if validPed(target) then
        recentTarget = target
        recentTargetAt = GetGameTimer()
        recentTargetSource = source
    end
end

local function getRecentNativeTarget(attacker)
    if recentTarget == 0
        or not validPed(recentTarget)
    then
        recentTarget = 0
        return 0, nil
    end

    local age = GetGameTimer() - recentTargetAt

    if age > Config.RecentTargetMs then
        recentTarget = 0
        return 0, nil
    end

    if pedDistance(attacker, recentTarget)
        > Config.RecentTargetMaxDistance
    then
        recentTarget = 0
        return 0, nil
    end

    return recentTarget,
        'RECENT_' .. tostring(recentTargetSource or 'NATIVE')
end

local function applyResetFlags(ped, flags)
    if ped == 0 or not DoesEntityExist(ped) then
        return
    end

    for i = 1, #flags do
        SetPedResetFlag(ped, flags[i], true)
    end
end

local function applyAttackerResetFlags(ped)
    applyResetFlags(ped, Config.AttackerResetFlags)
end

local function applyVictimResetFlags(ped)
    applyResetFlags(ped, Config.VictimResetFlags)
end

local function getNativeTarget(attacker)
    local found, target = GetPlayerTargetEntity(PlayerId())

    if found and validPed(target) then
        rememberNativeTarget(target, 'LOCKON')
        return target, 'LOCKON'
    end

    target = GetMeleeTargetForPed(attacker)

    if validPed(target) then
        rememberNativeTarget(target, 'MELEE')
        return target, 'MELEE'
    end

    return 0, nil
end

local function acquireNativeTarget(attacker)
    local deadline = GetGameTimer() + Config.TargetAcquireMs

    repeat
        local target, source = getNativeTarget(attacker)

        if target ~= 0 then
            return target, source
        end

        Wait(0)
    until GetGameTimer() >= deadline

    -- V1.8.2 fallback:
    -- GTA có thể hụt target đúng vài frame đầu của melee.
    -- Chỉ dùng lại target native vừa thấy, không tự tìm target mới.
    local recent, recentSource =
        getRecentNativeTarget(attacker)

    if recent ~= 0 then
        dbg(
            'RECENT TARGET FALLBACK',
            activeWeaponName or activeWeaponHash,
            recent,
            'ageMs=',
            GetGameTimer() - recentTargetAt,
            'source=',
            recentSource
        )

        return recent, recentSource
    end

    return 0, nil
end

local function getServerIdFromPed(ped)
    if not IsPedAPlayer(ped) then
        return nil
    end

    local idx = NetworkGetPlayerIndexFromPed(ped)

    if idx == -1 then
        return nil
    end

    local sid = GetPlayerServerId(idx)

    if not sid or sid <= 0 then
        return nil
    end

    return sid
end

local function attackWasPressed()
    for i = 1, #ATTACK_CONTROLS do
        if IsControlJustPressed(0, ATTACK_CONTROLS[i]) then
            return true
        end
    end

    return false
end

local function armPlayerVictim(target)
    local sid = getServerIdFromPed(target)

    if not sid then
        return
    end

    local now = GetGameTimer()

    if sid ~= lastVictimSid
        or now >= nextVictimRefresh
    then
        lastVictimSid = sid
        nextVictimRefresh =
            now + Config.PlayerVictimRefreshMs

        TriggerServerEvent(
            'understar_melee_guard_v1_8_2:armVictimResetFlags',
            sid,
            activeWeaponHash
        )
    end
end

local function runAttackSession()
    if sessionActive then
        return
    end

    local attacker = PlayerPedId()

    if IsEntityDead(attacker)
        or IsPedRagdoll(attacker)
        or IsPedInAnyVehicle(attacker, false)
        or IsPauseMenuActive()
    then
        return
    end

    local selectedHash = GetSelectedPedWeapon(attacker)

    if not isAllowedWeapon(selectedHash)
        or selectedHash ~= activeWeaponHash
    then
        return
    end

    sessionActive = true
    sessionSerial = sessionSerial + 1

    local mySerial = sessionSerial
    local sessionWeaponHash = activeWeaponHash
    local sessionWeaponName = activeWeaponName

    CreateThread(function()
        local target, source = acquireNativeTarget(attacker)

        if mySerial ~= sessionSerial
            or not usingGuardedWeapon
            or activeWeaponHash ~= sessionWeaponHash
        then
            sessionActive = false
            return
        end

        if target == 0 then
            dbg('NATIVE SWING - NO TARGET', sessionWeaponName)
            sessionActive = false
            return
        end

        local snapshotTarget = target
        local snapshotIsPlayer = IsPedAPlayer(snapshotTarget)

        dbg(
            'NATIVE SESSION',
            sessionWeaponName,
            snapshotTarget,
            source,
            snapshotIsPlayer and 'PLAYER' or 'NPC'
        )

        local deadline =
            GetGameTimer() + Config.AttackSessionMs

        local targetChanged = false

        while GetGameTimer() < deadline do
            if mySerial ~= sessionSerial
                or not usingGuardedWeapon
                or activeWeaponHash ~= sessionWeaponHash
                or IsEntityDead(attacker)
                or not validPed(snapshotTarget)
            then
                break
            end

            -- Outgoing protection:
            -- GTA is told every frame not to choose lethal/takedown actions.
            applyAttackerResetFlags(attacker)

            -- Incoming protection:
            -- For NPC we can set victim reset flags locally every frame.
            -- For Player the owner client receives a server-validated lease.
            if snapshotIsPlayer then
                armPlayerVictim(snapshotTarget)
            else
                applyVictimResetFlags(snapshotTarget)
            end

            local liveTarget =
                select(1, getNativeTarget(attacker))

            if liveTarget ~= 0
                and liveTarget ~= snapshotTarget
            then
                dbg(
                    'TARGET CHANGED - CANCEL',
                    sessionWeaponName,
                    snapshotTarget,
                    '->',
                    liveTarget
                )

                ClearPedTasksImmediately(attacker)

                targetChanged = true
                break
            end

            -- Sau khi native melee action kết thúc, giữ một grace ngắn
            -- để bắt engine đổi target ở đuôi action.
            if not IsPedPerformingMeleeAction(attacker) then
                local grace = GetGameTimer() + 90

                while GetGameTimer() < grace do
                    if mySerial ~= sessionSerial then
                        break
                    end

                    applyAttackerResetFlags(attacker)

                    if snapshotIsPlayer then
                        armPlayerVictim(snapshotTarget)
                    elseif validPed(snapshotTarget) then
                        applyVictimResetFlags(snapshotTarget)
                    end

                    local t =
                        select(1, getNativeTarget(attacker))

                    if t ~= 0
                        and t ~= snapshotTarget
                    then
                        dbg(
                            'TARGET CHANGED - CANCEL',
                            sessionWeaponName,
                            snapshotTarget,
                            '->',
                            t
                        )

                        ClearPedTasksImmediately(attacker)
                        targetChanged = true
                        break
                    end

                    Wait(0)
                end

                break
            end

            Wait(0)
        end

        dbg(
            'SESSION END',
            sessionWeaponName,
            snapshotTarget,
            'targetChanged',
            targetChanged
        )

        sessionActive = false
    end)
end

-- =========================================================
-- Victim owner
-- =========================================================

RegisterNetEvent(
    'understar_melee_guard_v1_8_2:armVictimResetFlags',
    function(attackerSid, leaseMs, attackerWeaponHash)
        local now = GetGameTimer()
        local newAttackerSid = tonumber(attackerSid) or 0
        local newWeaponHash = tonumber(attackerWeaponHash) or 0

        local changed =
            newAttackerSid ~= victimGuardAttackerSid
            or newWeaponHash ~= victimGuardWeaponHash
            or now >= victimGuardUntil

        victimGuardAttackerSid = newAttackerSid
        victimGuardWeaponHash = newWeaponHash
        victimGuardUntil = math.max(
            victimGuardUntil,
            now + (tonumber(leaseMs)
                or Config.PlayerVictimLeaseMs)
        )

        if changed then
            victimGuardLogged = false
        end
    end
)

CreateThread(function()
    while true do
        local now = GetGameTimer()

        if now < victimGuardUntil then
            local ped = PlayerPedId()

            -- No invincible. These are engine melee-selection reset flags only.
            applyVictimResetFlags(ped)

            if Config.Debug and not victimGuardLogged then
                dbg(
                    'VICTIM RESET GUARD ON',
                    'attacker=',
                    victimGuardAttackerSid,
                    'weapon=',
                    allowedWeapons[victimGuardWeaponHash]
                        or victimGuardWeaponHash,
                    'flags=187,457'
                )

                victimGuardLogged = true
            end

            Wait(0)
        else
            if victimGuardLogged then
                dbg('VICTIM RESET GUARD OFF')
            end

            victimGuardLogged = false
            victimGuardAttackerSid = 0
            victimGuardWeaponHash = 0

            Wait(100)
        end
    end
end)

-- =========================================================
-- Weapon state
-- =========================================================

local function resetGuardState()
    sessionSerial = sessionSerial + 1
    sessionActive = false
    lastVictimSid = 0
    nextVictimRefresh = 0

    recentTarget = 0
    recentTargetAt = 0
    recentTargetSource = nil
end

local function resolveWeaponHash(weapon)
    local ped = PlayerPedId()

    -- 1) ox_inventory hash nếu có.
    if weapon and weapon.hash then
        local hash = tonumber(weapon.hash)

        if hash and hash ~= 0 then
            return hash
        end
    end

    -- 2) Một số build/custom ox chỉ trả name.
    if weapon and weapon.name then
        local name = tostring(weapon.name):upper()

        if name ~= '' then
            local hash = joaat(name)

            if hash and hash ~= 0 then
                return hash
            end
        end
    end

    -- 3) Fallback trực tiếp từ GTA ped.
    -- Quan trọng khi ox currentWeapon event trả nil/thiếu hash.
    local selected = GetSelectedPedWeapon(ped)

    if selected and selected ~= 0
        and selected ~= joaat('WEAPON_UNARMED')
    then
        return selected
    end

    return 0
end

local function setWeaponState(weapon)
    local newHash = resolveWeaponHash(weapon)
    local newGuarded = isAllowedWeapon(newHash)

    if newHash == activeWeaponHash
        and newGuarded == usingGuardedWeapon
    then
        return
    end

    resetGuardState()

    activeWeaponHash = newHash
    activeWeaponName = allowedWeapons[newHash]
    usingGuardedWeapon = newGuarded

    if not usingGuardedWeapon then
        SetPedConfigFlag(
            PlayerPedId(),
            Config.DontChangeTargetFlag,
            false
        )
    end

    dbg(
        'weapon =',
        activeWeaponName or 'OTHER/NONE',
        'guarded =',
        usingGuardedWeapon
    )
end

AddEventHandler(
    'ox_inventory:currentWeapon',
    function(weapon)
        setWeaponState(weapon)
    end
)

AddEventHandler(
    'onClientResourceStart',
    function(resource)
        if resource ~= GetCurrentResourceName() then
            return
        end

        SetTimeout(500, function()
            setWeaponState(
                exports.ox_inventory:getCurrentWeapon()
            )
        end)
    end
)

-- =========================================================
-- Main guarded-weapon loop
-- =========================================================

CreateThread(function()
    while true do
        if not usingGuardedWeapon then
            Wait(250)
        else
            local ped = PlayerPedId()

            -- V1.8.1 self-heal:
            -- nếu ox_inventory state bị stale sau switch weapon,
            -- lấy trực tiếp selected weapon từ GTA.
            local selected = GetSelectedPedWeapon(ped)

            if selected ~= activeWeaponHash then
                if isAllowedWeapon(selected) then
                    activeWeaponHash = selected
                    activeWeaponName = allowedWeapons[selected]
                    usingGuardedWeapon = true

                    dbg(
                        'weapon sync from GTA =',
                        activeWeaponName,
                        'guarded =',
                        true
                    )
                elseif selected ~= joaat('WEAPON_UNARMED') then
                    activeWeaponHash = selected
                    activeWeaponName = nil
                    usingGuardedWeapon = false

                    SetPedConfigFlag(
                        ped,
                        Config.DontChangeTargetFlag,
                        false
                    )

                    dbg(
                        'weapon sync from GTA = OTHER',
                        selected
                    )

                    Wait(0)
                    goto continue_main_loop
                end
            end

            -- Persistent config flag for target identity.
            SetPedConfigFlag(
                ped,
                Config.DontChangeTargetFlag,
                true
            )

            -- Reset flags MUST be set every frame.
            applyAttackerResetFlags(ped)

            local target =
                select(1, getNativeTarget(ped))

            if target ~= 0 then
                if IsPedAPlayer(target) then
                    armPlayerVictim(target)
                else
                    -- Prevent takedown / stealth kill on current NPC victim.
                    applyVictimResetFlags(target)
                end
            else
                lastVictimSid = 0
            end

            if attackWasPressed() then
                runAttackSession()
            end

            Wait(0)

            ::continue_main_loop::
        end
    end
end)

AddEventHandler(
    'onResourceStop',
    function(resource)
        if resource ~= GetCurrentResourceName() then
            return
        end

        SetPedConfigFlag(
            PlayerPedId(),
            Config.DontChangeTargetFlag,
            false
        )
    end
)
