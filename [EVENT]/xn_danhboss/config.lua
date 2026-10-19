Config = {}

Config.Debug = false

-- Health of a ped is offset by 100 (below that the ped is considered dead).
-- Real entity health = Config.Boss.health + HealthOffset.
Config.HealthOffset = 100

Config.Boss = {
    label = 'BOSS ZOMBIE', -- GTA fonts do not render Vietnamese diacritics
    model = `u_m_y_zombie_01`,
    coords = vec4(121.3979, -1070.3513, 29.1923, 258.1201),
    health = 10000,
    spawnOnStart = true,
    startDelay = 15, -- seconds after resource start
    autoRespawn = true,
    respawnDelay = 30 * 60, -- seconds after death
    corpseTime = 60 * 1000, -- ms before the corpse is deleted
}

Config.Enrage = {
    threshold = 0.30, -- enrage when hp <= 30%
    damageMult = 1.5,
    cooldownMult = 0.65,
    moveRate = 1.6,
}

Config.AI = {
    aggroRange = 120.0, -- detection range
    randomPickRange = 40.0, -- random target is chosen among players within this range
    retargetMin = 5000, -- ms, interval between random target switches
    retargetMax = 10000,
    moveSpeed = 3.0, -- 3.0 = sprint
    moveRate = 1.3, -- run speed multiplier
    leashRange = 150.0, -- with no target, return to spawn when farther than this
}

Config.Melee = {
    range = 2.3,
    tolerance = 2.5, -- extra range accepted by the server (latency)
    damage = { 1, 2},
    cooldown = 1100, -- ms
    hitDelay = 350, -- ms from anim start to damage
    ragdollChance = 0.25,
    anim = { dict = 'melee@unarmed@streamed_core', clip = 'heavy_punch_a', duration = 900 },
}

Config.Slam = {
    triggerRange = 9.0,
    radius = 7.0,
    damage = { 45, 70 },
    cooldown = 14000,
    delay = 1500, -- telegraph time before the shockwave
    anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', duration = 2200 },
}

Config.Bar = {
    drawDistance = 70.0,
    headOffset = 0.55,
}

Config.Blip = { sprite = 84, color = 1, scale = 1.1 }

Config.Rewards = {
    minDamage = 150, -- minimum damage dealt to qualify
    baseCash = 2000,
    cashPool = 40000, -- split by damage share
    topBonus = 10000, -- extra cash for the top damage dealer
    items = { -- item names must exist in ox_inventory
        { name = 'bandage', min = 2, max = 5, chance = 100 },
        { name = 'armour', min = 1, max = 2, chance = 60 },
    },
}

Config.Text = {
    title = 'Boss Zombie',
    spawned = 'Boss Zombie đã xuất hiện! Kiểm tra vị trí trên bản đồ và tập hợp để hạ gục nó.',
    enraged = 'Boss Zombie đã nổi điên! Nó nhanh và mạnh hơn!',
    killed = 'Boss Zombie đã bị hạ gục! Người gây sát thương cao nhất: %s (%d).',
    reward = 'Phần thưởng: $%d tiền mặt.',
    noReward = 'Bạn gây quá ít sát thương nên không nhận được thưởng.',
}
