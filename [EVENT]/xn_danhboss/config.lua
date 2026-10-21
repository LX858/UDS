Config = {}

Config.Debug = true

-- Boss hp is tracked by the server from player hit reports (not by entity health),
-- because neons_ddame sets weapon damage modifiers to ~0 and re-applies damage itself.
-- The entity gets a huge real health so it never dies from real damage.
Config.HealthOffset = 100

Config.Damage = {
    syncResource = 'neons_ddame', -- read WeaponDamages from this resource config.lua ('' to disable)
    weapons = {}, -- manual overrides: [`weapon_x`] = { damage = 20, headshot = 40, maxRange = 100.0 }
    unlistedMax = 150, -- cap for weapons not listed anywhere (client-reported base damage)
    headMult = 2.0, -- headshot multiplier for unlisted weapons
    multiplier = 1.0, -- global damage multiplier against the boss
    defaultMaxRange = 300.0,
    maxHitsPerSecond = 40, -- per player, anti-spam
    realHealth = 1000000,
}

Config.Boss = {
    label = 'BOSS ZOMBIE', -- GTA fonts do not render Vietnamese diacritics
    model = `giuly_driusmah`,
    coords = vec4(-1729.3090, -192.9891, 58.4980, 90.1931),
    health = 10000,
    spawnOnStart = false,
    startDelay = 15, -- seconds after resource start
    autoRespawn = false,
    respawnDelay = 30 * 60, -- seconds after death
    corpseTime = 60 * 1000, -- ms before the corpse is deleted
}

Config.Enrage = {
    threshold = 0.30, -- enrage when hp <= 30%
    damageMult = 1.5,
    cooldownMult = 0.65,
}

-- The boss is frozen at its spawn point and never moves.
Config.AI = {
    aggroRange = 50.0, -- players farther than this are ignored
    randomPickRange = 40.0, -- random target is chosen among players within this range
    retargetMin = 5000, -- ms, interval between random target switches
    retargetMax = 10000,
}

Config.Gun = {
    weapon = `weapon_smg`, -- keep it out of neons_ddame's WeaponDamages list
    intervalMin = 15000, -- ms between gun phases
    intervalMax = 25000,
    windup = 800, -- ms facing the target before the first shot
    shots = 6, -- bullets per gun phase
    shotDelay = 150, -- ms between bullets
    damage = 12, -- damage per bullet (player health is 200)
    spread = 1.2, -- meters of random aim offset
    minRange = 6.0,
    maxRange = 45.0,
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
    damage = { 10, 20 },
    cooldown = 14000,
    delay = 1500, -- telegraph time before the shockwave
    anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', duration = 2200 },
}

Config.Bar = {
    drawDistance = 70.0,
    headOffset = 1.15, -- meters above the head bone
    width = 0.075, -- screen width of the bar
    height = 0.0075,
}

-- Zombie minions: up to `max` alive at once at random spots inside Config.Zone.radius.
-- They have no health bar and their damage does not count for the ranking.
Config.Minions = {
    enabled = true,
    max = 10,
    models = { `u_m_y_zombie_01` },
    hp = 200, -- server-side hp, damage uses the same weapon table as the boss
    realHealth = 100000, -- entity health, so the engine never kills it on its own
    spawnInterval = 1500, -- ms between spawns while below max
    respawnDelay = 5000, -- ms before a replacement after one is killed
    minPlayerDistance = 8.0, -- never spawn closer than this to a player
    corpseTime = 5000, -- ms before the corpse is deleted
    moveSpeed = 2.0, -- 1.0 walk, 2.0 run, 3.0 sprint
    retargetPeriod = 8000, -- ms, minions rotate their chosen player so they spread out
    shake = false, -- camera shake when a minion hits a player: false = off, or { name = 'SMALL_EXPLOSION_SHAKE', amount = 0.4 }
    ragdoll = false, -- false = minion hits never knock the player over (like a normal NPC punch)
    moveRate = 1.0,
    attackRange = 1.8,
    tolerance = 2.0, -- extra range accepted by the server (latency)
    damage = { 1, 2 },
    cooldown = 1200, -- ms
    hitDelay = 300, -- ms from anim start to damage
    anim = { dict = 'melee@unarmed@streamed_core', clip = 'heavy_punch_a', duration = 900 },
}

Config.Blip = { sprite = 84, color = 1, scale = 1.1 }

-- Zone centered on the boss spawn point: players who go down here are revived in place.
Config.Zone = {
    enabled = true,
    radius = 50.0,
    reviveDelay = 30, -- seconds before the in-place revive (qbx_medical Revive)
    onlyWhileBoss = true, -- only while the boss is alive
    blip = true, -- show the zone radius on the map
}

Config.Rewards = {
    item = 'gachabox2', -- must exist in ox_inventory, its label is read from there
    minDamage = 10, -- minimum damage dealt to qualify
    participation = 1, -- items for anyone who qualifies but is outside the top list
    top = { 10, 7, 6, 5, 4, 3, 2, 2, 1, 1 }, -- items for rank 1..10 (also the ranking size)
    showRanking = true, -- open the ranking UI for online participants when the boss dies
}

-- NPC that reopens the ranking UI (also where players can claim their reward).
Config.Npc = {
    model = `a_m_m_business_01`,
    coords = vec4(-1646.4813, -165.0448, 57.2769, 128.2089),
    spawnDistance = 60.0, -- the ped only exists client-side within this distance
    interactDistance = 2.5,
    label = 'Xem bảng xếp hạng Boss',
    icon = 'fa-solid fa-ghost',
}

Config.Text = {
    title = 'Boss Zombie',
    spawned = 'Boss Zombie đã xuất hiện! Kiểm tra vị trí trên bản đồ và tập hợp để hạ gục nó.',
    enraged = 'Boss Zombie đã nổi điên! Nó nhanh và mạnh hơn!',
    gunWarn = 'Boss đang nhắm súng vào bạn! Hãy tìm chỗ nấp!',
    reviveSoon = 'Bạn sẽ được hồi sinh tại chỗ sau %d giây.',
    killed = 'Boss Zombie đã bị hạ gục! Người gây sát thương cao nhất: %s (%d).',
    rankingReady = 'Boss đã bị hạ! Mở bảng xếp hạng để nhận quà (hoặc đến NPC bảng xếp hạng).',
    bossActive = 'Boss đang hoạt động, bảng xếp hạng sẽ có sau khi boss bị hạ.',
    noRanking = 'Chưa có bảng xếp hạng nào.',
    notParticipant = 'Bạn không có phần thưởng ở lượt boss này.',
    alreadyClaimed = 'Bạn đã nhận phần thưởng rồi.',
    busy = 'Đang xử lý, vui lòng thử lại.',
    claimed = 'Đã nhận %d %s.',
    inventoryFull = 'Túi đồ không đủ chỗ để nhận quà. Hãy dọn túi rồi thử lại.',
}
