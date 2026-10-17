Config = {}

Config.Weapons = {
    'WEAPON_WRENCH',
    'WEAPON_BAT',
    'WEAPON_CROWBAR',
    'WEAPON_HATCHET',
}

-- Script KHÔNG quyết định damage.
-- Không pre-shield, không invincible cho normal melee,
-- không SetEntityHealth / ApplyDamageToPed.

Config.TargetAcquireMs = 140

-- GTA đôi khi trả target=0 trong vài frame ngay lúc bấm melee.
-- Chỉ cache TARGET NATIVE mà GTA vừa trả về; không scan entity/player pool.
Config.RecentTargetMs = 320
Config.RecentTargetMaxDistance = 5.50
Config.AttackSessionMs = 1000

-- Server chỉ xác minh event arm victim.
-- GTA có thể lock-on ở khoảng >3m nên 3.10m trước đây quá chặt.
Config.ServerMaxDistance = 5.50

-- CPED_CONFIG_FLAG_DontChangeTargetFromMelee
Config.DontChangeTargetFlag = 458

-- GTA V Ped Reset Flags.
-- Attacker:
-- 155 = PRF_SuppressLethalMeleeActions
-- 438 = PRF_SuppressTakedownMeleeActions
Config.AttackerResetFlags = {
    155,
    438,
}

-- Victim:
-- 187 = PRF_PreventAllMeleeTakedowns
-- 457 = PRF_PreventAllStealthKills
Config.VictimResetFlags = {
    187,
    457,
}

-- Khi attacker đang lock-on Player, server arm victim owner.
Config.PlayerVictimLeaseMs = 700
Config.PlayerVictimRefreshMs = 220

Config.Debug = false
