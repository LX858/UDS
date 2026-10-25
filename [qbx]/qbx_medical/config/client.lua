---@enum WeaponClass
local weaponClasses = { -- Define gta weapon classe numbers
    SMALL_CALIBER = 1,
    MEDIUM_CALIBER = 2,
    HIGH_CALIBER = 3,
    SHOTGUN = 4,
    CUTTING = 5,
    LIGHT_IMPACT = 6,
    HEAVY_IMPACT = 7,
    EXPLOSIVE = 8,
    FIRE = 9,
    SUFFOCATING = 10,
    OTHER = 11,
    WILDLIFE = 12,
    NONE = 13,
}

return {
    weaponClasses = weaponClasses,
    fadeOutTimer = 2, -- Có bao nhiêu ve bị chảy máu xảy ra trước khi fadeout xảy ra
    blackoutTimer = 5, -- Có bao nhiêu ve bị chảy máu xảy ra trước khi bôi đen
    bleedDamageTimer = 2, -- Thiệt hại cơ bản được nhân với mức độ chảy máu mỗi khi xảy ra một con ve bị chảy máu
    advanceBleedTimer = 5, -- Có bao nhiêu ve bị chảy máu xảy ra trước khi mức chảy máu tăng lên
    bleedTickRate = 10, -- Bao nhiêu thời gian, trong vài giây, giữa các ve bị chảy máu
    bleedMovementTick = 30, -- Có bao nhiêu giây bị lấy đi từ tốc độ đánh dấu chảy máu nếu người chơi đang đi bộ, chạy bộ hoặc chạy nước rút
    bleedMovementAdvance = 3, -- Thời gian di chuyển khi bị chảy máu được cộng thêm
    armorDamage = 5, -- Thiệt hại tối thiểu gây ra cho áo giáp trước khi kiểm tra vết thương
    messageTimer = 12, -- Sẽ mất bao lâu để hiển thị thông báo chi/chảy máu
    alertShowInfo = 2, -- Một cầu thủ phải có bao nhiêu chấn thương trước khi được cảnh báo về chúng
    headInjuryTimer = 30, -- Có bao nhiêu thời gian, trong vài giây, có cơ hội có hiệu quả chấn thương đầu
    armInjuryTimer = 30, -- Có bao nhiêu thời gian, trong vài giây, có cơ hội có hiệu quả chấn thương cánh tay
    legInjuryTimer = 15, -- Có bao nhiêu thời gian, trong vài giây, có cơ hội có hiệu quả chấn thương chân
    headInjuryChance = 10, -- Cơ hội, tính theo phần trăm, tác dụng phụ chấn thương đầu được áp dụng
    legInjuryChance = { -- Cơ hội, tính theo phần trăm, tác dụng phụ chấn thương chân được áp dụng
        running = 30,
        walking = 15,
    },
    laststandReviveInterval = 360,
    deathTime = 300,

    -- xn_deathscreen settings
    timewait = 15 * 60 , -- Hiển thị thời gian trên giao diện (phút)
    autoTeleportTime = 5, --Thời gian thực tế để tự động dịch chuyển đến bệnh viện khi không có bác sĩ (tính bằng giây)
    timerespawn = 5, -- Thời gian nằm viện trước khi tự hồi sinh
    enableBlur = true, -- Bật hiệu ứng làm mờ khi nhân vật chết

    -- Respawn location at hospital
    respawnLocation = vec3(306.1616, -1449.6398, 29.9747), --vector3(306.1616, -1449.6398, 29.9747)
    respawnHeading = 346.88,

    -- Hospital bed for auto respawn (when no doctors online)
    hospitalName = 'pillbox',
    totalBeds = 7, -- Tổng số giường để chọn ngẫu nhiên

    -- Auto revive prices (when no doctors online)
    autoRevivePrice = 2500, -- Giá tính cho người chơi
    hospitalShare = 2500, -- Số tiền chuyển vào tài khoản bệnh viện

    -- Red Zone (Vùng Đỏ) Settings
    redZoneDebug = false, -- Hiển thị vòng tròn đỏ (bán kính 20m) để gỡ lỗi
    redZoneDefaultCooldown = 2, -- Default cooldown in minutes before re-entering (2 phút)
    time_cuu_vung_do = 60, -- (giay) Thời gian để cứu người trong vùng đỏ
    redZoneWaitHTime = 300, -- (giây) Thời gian vui lòng chờ trước khi cho phép nhấn nút H (5 phút)
    redZoneHHoldTime = 2, -- (giây) Thời gian nhấn giữ nút H để về bệnh viện
    redZones = {
        {
            id = 'redzone_1',
            name = 'Vùng Đỏ 1',
            coords = vec3(1231.5006, -86.8380, 59.6442), -- Example location 1
            radius = 100.0,
            cooldownMinutes = 30,
            hospitalCoords = vec3(306.3737, -1434.9941, 29.8052),
            hospitalHeading = 139.0527,
        },
        {
            id = 'redzone_2',
            name = 'Vùng Đỏ 2',
            coords = vec3(346.0358, -2048.0103, 21.6413), -- Example location 2
            radius = 100.0,
            cooldownMinutes = 30,
            hospitalCoords = vec3(306.3737, -1434.9941, 29.8052),
            hospitalHeading = 139.0527,
        },
        {
            id = 'redzone_3',
            name = 'Vùng Đỏ 3',
            coords = vec3(1481.9066, -2354.6516, 71.9142), -- Example location 2
            radius = 100.0,
            cooldownMinutes = 30,
            hospitalCoords = vec3(306.3737, -1434.9941, 29.8052),
            hospitalHeading = 139.0527,
        },
        {
            id = 'redzone_4',
            name = 'Vùng Đỏ 4',
            coords = vec3(-1171.4543, 33.4847, 51.4955), -- Example location 2
            radius = 100.0,
            cooldownMinutes = 30,
            hospitalCoords = vec3(306.3737, -1434.9941, 29.8052),
            hospitalHeading = 139.0527,
        },
        {
            id = 'redzone_5',
            name = 'Vùng Đỏ 5',
            -- Vùng đa giác (thay cho coords + radius)
            points = {
                vec2(128.33653259277, -1397.6218261719),
                vec2(57.198749542236, -1492.9559326172),
                vec2(86.357109069824, -1513.9591064453),
                vec2(204.39636230469, -1597.8474121094),
                vec2(281.32073974609, -1659.3487548828),
                vec2(462.11312866211, -1814.1839599609),
                vec2(496.53555297852, -1844.9904785156),
                vec2(518.61859130859, -1890.8748779297),
                vec2(586.87841796875, -2069.3618164063),
                vec2(574.68353271484, -2393.9340820313),
                vec2(542.98968505859, -2416.6586914063),
                vec2(513.91357421875, -2400.3625488281),
                vec2(504.61386108398, -2322.6547851563),
                vec2(448.36227416992, -2293.5390625),
                vec2(418.45721435547, -2253.3813476563),
                vec2(294.56414794922, -2236.1159667969),
                vec2(78.091773986816, -2240.1560058594),
                vec2(74.852439880371, -2054.171875),
                vec2(4.1279220581055, -1953.9331054688),
                vec2(-194.19717407227, -1800.7416992188),
                vec2(-299.47274780273, -1749.8773193359),
                vec2(-351.88922119141, -1687.50390625),
                vec2(-354.1083984375, -1681.5775146484),
                vec2(-357.02651977539, -1676.7650146484),
                vec2(-339.044921875, -1644.5780029297),
                vec2(-268.85870361328, -1513.5474853516),
                vec2(-259.82913208008, -1439.9459228516),
                vec2(-101.86580657959, -1378.1339111328),
                vec2(115.64482116699, -1386.0469970703),
            },
            minZ = -100.0,
            maxZ = 300.0,
            cooldownMinutes = 30,
            hospitalCoords = vec3(306.3737, -1434.9941, 29.8052),
            hospitalHeading = 139.0527,
        },
        {
            id = 'redzone_cayo_island',
            name = 'Vùng Đỏ Cayo Perico',
            coords = vec3(4840.571, -5174.425, 2.0),
            radius = 2000.0,
            waitHTime = 180, -- 3 phút trước khi được giữ H về bệnh viện
            hospitalCoords = vec3(306.3737, -1434.9941, 29.8052),
            hospitalHeading = 139.0527,
        },
    },

    deathControls = {
        mouse = true,
        enable = {245, 38, 0, 322, 288, 213, 249, 46, 47}
    },

    forceInjury = 10, -- Lượng thiệt hại tối đa mà người chơi có thể gây ra trước khi thiệt hại và ảnh hưởng của chi bị buộc phải xảy ra
    healthDamage = 2, -- Thiệt hại tối thiểu đối với sức khỏe trước khi kiểm tra chấn thương
    maxInjuryChanceMulti = 3, -- Maximum chance of an injury from damage above healthDamage
    forceInjuryWeapons = { -- Xác định loại vũ khí nào sẽ luôn gây thương tích
        [weaponClasses.HIGH_CALIBER] = false,
        [weaponClasses.HEAVY_IMPACT] = false,
        [weaponClasses.EXPLOSIVE] = false,
    },

    criticalAreas = { -- Xác định những vùng cơ thể luôn gây chảy máu dù có mặc áo giáp hay không
        UPPER_BODY = { armored = false },
        LOWER_BODY = { armored = false },
        SPINE = { armored = false },
    },

    ---@class StaggerArea Định nghĩa các vùng cơ thể sẽ luôn gây ra sự choáng nếu có mặc áo giáp hay không
    ---@field armored boolean
    ---@field major number
    ---@field minor number

    ---@type table<BodyPartKey, StaggerArea>
    staggerAreas = {
        SPINE = { armored = false, major = 60, minor = 30 },
        UPPER_BODY = { armored = false, major = 60, minor = 30 },
        LLEG = { armored = false, major = 100, minor = 85 },
        RLEG = { armored = false, major = 100, minor = 85 },
        LFOOT = { armored = false, major = 100, minor = 100 },
        RFOOT = { armored = false, major = 100, minor = 100 },
    },

    majorArmoredBleedChance = 0, -- Khả năng, tính theo phần trăm, người chơi sẽ bị hiệu ứng chảy máu khi chịu sát thương nặng khi mặc áo giáp
    minorInjurWeapons = { -- Xác định loại vũ khí nào gây ra thương tích nhỏ
        [weaponClasses.SMALL_CALIBER] = false,
        [weaponClasses.MEDIUM_CALIBER] = false,
        [weaponClasses.CUTTING] = false,
        [weaponClasses.WILDLIFE] = false,
        [weaponClasses.OTHER] = true,
        [weaponClasses.LIGHT_IMPACT] = false,
    },

    majorInjurWeapons = { -- Xác định loại vũ khí nào gây ra thương tích lớn
        [weaponClasses.HIGH_CALIBER] = false,
        [weaponClasses.HEAVY_IMPACT] = true,
        [weaponClasses.SHOTGUN] = false,
        [weaponClasses.EXPLOSIVE] = false,
    },

    damageMinorToMajor = 30, -- Mức độ thiệt hại sẽ phải được áp dụng để một vũ khí nhỏ được coi là sự kiện gây thiệt hại lớn. Đặt cái này ở mức 100 nếu bạn muốn tắt nó
    alwaysBleedChanceWeapons = { -- Xác định loại vũ khí nào sẽ luôn gây chảy máu
        [weaponClasses.SMALL_CALIBER] = false,
        [weaponClasses.MEDIUM_CALIBER] = false,
        [weaponClasses.CUTTING] = false,
        [weaponClasses.WILDLIFE] = false,
    },

    alwaysBleedChance = 0, -- Đặt cơ hội trong số 100 rằng nếu người chơi bị trúng vũ khí, cơ hội đó cũng có cơ hội ngẫu nhiên sẽ gây chảy máu
    ---@type table<number, string>
    bones = { -- Correspond bone hash numbers to their label
        [0]     = 'NONE',
        [31085] = 'HEAD',
        [31086] = 'HEAD',
        [39317] = 'NECK',
        [57597] = 'SPINE',
        [23553] = 'SPINE',
        [24816] = 'SPINE',
        [24817] = 'SPINE',
        [24818] = 'SPINE',
        [10706] = 'UPPER_BODY',
        [64729] = 'UPPER_BODY',
        [11816] = 'LOWER_BODY',
        [45509] = 'LARM',
        [61163] = 'LARM',
        [18905] = 'LHAND',
        [4089]  = 'LFINGER',
        [4090]  = 'LFINGER',
        [4137]  = 'LFINGER',
        [4138]  = 'LFINGER',
        [4153]  = 'LFINGER',
        [4154]  = 'LFINGER',
        [4169]  = 'LFINGER',
        [4170]  = 'LFINGER',
        [4185]  = 'LFINGER',
        [4186]  = 'LFINGER',
        [26610] = 'LFINGER',
        [26611] = 'LFINGER',
        [26612] = 'LFINGER',
        [26613] = 'LFINGER',
        [26614] = 'LFINGER',
        [58271] = 'LLEG',
        [63931] = 'LLEG',
        [2108]  = 'LFOOT',
        [14201] = 'LFOOT',
        [40269] = 'RARM',
        [28252] = 'RARM',
        [57005] = 'RHAND',
        [58866] = 'RFINGER',
        [58867] = 'RFINGER',
        [58868] = 'RFINGER',
        [58869] = 'RFINGER',
        [58870] = 'RFINGER',
        [64016] = 'RFINGER',
        [64017] = 'RFINGER',
        [64064] = 'RFINGER',
        [64065] = 'RFINGER',
        [64080] = 'RFINGER',
        [64081] = 'RFINGER',
        [64096] = 'RFINGER',
        [64097] = 'RFINGER',
        [64112] = 'RFINGER',
        [64113] = 'RFINGER',
        [36864] = 'RLEG',
        [51826] = 'RLEG',
        [20781] = 'RFOOT',
        [52301] = 'RFOOT',
    },

    weapons = { -- Correspond weapon names to their class number
        [`WEAPON_STUNGUN`] = weaponClasses.NONE,
        [`WEAPON_STUNGUN_MP`] = weaponClasses.NONE,
        --[[ Small Caliber ]] --
        [`WEAPON_PISTOL`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_COMBATPISTOL`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_APPISTOL`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_COMBATPDW`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_MACHINEPISTOL`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_MICROSMG`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_MINISMG`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_PISTOL_MK2`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_SNSPISTOL`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_SNSPISTOL_MK2`] = weaponClasses.SMALL_CALIBER,
        [`WEAPON_VINTAGEPISTOL`] = weaponClasses.SMALL_CALIBER,

        --[[ Medium Caliber ]] --
        [`WEAPON_ADVANCEDRIFLE`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_ASSAULTSMG`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_BULLPUPRIFLE`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_BULLPUPRIFLE_MK2`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_CARBINERIFLE`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_CARBINERIFLE_MK2`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_COMPACTRIFLE`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_DOUBLEACTION`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_GUSENBERG`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_HEAVYPISTOL`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_MARKSMANPISTOL`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_PISTOL50`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_REVOLVER`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_REVOLVER_MK2`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_SMG`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_SMG_MK2`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_SPECIALCARBINE`] = weaponClasses.MEDIUM_CALIBER,
        [`WEAPON_SPECIALCARBINE_MK2`] = weaponClasses.MEDIUM_CALIBER,

        --[[ High Caliber ]] --
        [`WEAPON_ASSAULTRIFLE`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_ASSAULTRIFLE_MK2`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_COMBATMG`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_COMBATMG_MK2`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_HEAVYSNIPER`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_HEAVYSNIPER_MK2`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_MARKSMANRIFLE`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_MARKSMANRIFLE_MK2`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_MG`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_MINIGUN`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_MUSKET`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_RAILGUN`] = weaponClasses.HIGH_CALIBER,
        [`WEAPON_HEAVYRIFLE`] = weaponClasses.HIGH_CALIBER,

        --[[ Shotguns ]] --
        [`WEAPON_ASSAULTSHOTGUN`] = weaponClasses.SHOTGUN,
        [`WEAPON_BULLUPSHOTGUN`] = weaponClasses.SHOTGUN,
        [`WEAPON_DBSHOTGUN`] = weaponClasses.SHOTGUN,
        [`WEAPON_HEAVYSHOTGUN`] = weaponClasses.SHOTGUN,
        [`WEAPON_PUMPSHOTGUN`] = weaponClasses.SHOTGUN,
        [`WEAPON_PUMPSHOTGUN_MK2`] = weaponClasses.SHOTGUN,
        [`WEAPON_SAWNOFFSHOTGUN`] = weaponClasses.SHOTGUN,
        [`WEAPON_SWEEPERSHOTGUN`] = weaponClasses.SHOTGUN,

        --[[ Animals ]] --
        [`WEAPON_ANIMAL`] = weaponClasses.WILDLIFE, -- Animal
        [`WEAPON_COUGAR`] = weaponClasses.WILDLIFE, -- Cougar
        [`WEAPON_BARBED_WIRE`] = weaponClasses.WILDLIFE, -- Barbed Wire

        --[[ Cutting Weapons ]] --
        [`WEAPON_BATTLEAXE`] = weaponClasses.CUTTING,
        [`WEAPON_BOTTLE`] = weaponClasses.CUTTING,
        [`WEAPON_DAGGER`] = weaponClasses.CUTTING,
        [`WEAPON_HATCHET`] = weaponClasses.CUTTING,
        [`WEAPON_KNIFE`] = weaponClasses.CUTTING,
        [`WEAPON_MACHETE`] = weaponClasses.CUTTING,
        [`WEAPON_SWITCHBLADE`] = weaponClasses.CUTTING,

        --[[ Light Impact ]] --
        [`WEAPON_KNUCKLE`] = weaponClasses.LIGHT_IMPACT,

        --[[ Heavy Impact ]] --
        [`WEAPON_BAT`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_CROWBAR`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_FIREEXTINGUISHER`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_FIRWORK`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_GOLFLCUB`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_HAMMER`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_PETROLCAN`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_POOLCUE`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_WRENCH`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_RAMMED_BY_CAR`] = weaponClasses.HEAVY_IMPACT,
        [`WEAPON_RUN_OVER_BY_CAR`] = weaponClasses.HEAVY_IMPACT,

        --[[ Explosives ]] --
        [`WEAPON_EXPLOSION`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_GRENADE`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_COMPACTLAUNCHER`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_HOMINGLAUNCHER`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_PIPEBOMB`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_PROXMINE`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_RPG`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_STICKYBOMB`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_HELI_CRASH`] = weaponClasses.EXPLOSIVE,
        [`WEAPON_EMPLAUNCHER`] = weaponClasses.EXPLOSIVE,

        --[[ Other ]] --
        [`WEAPON_FALL`] = weaponClasses.OTHER, -- Fall
        [`WEAPON_HIT_BY_WATER_CANNON`] = weaponClasses.OTHER, -- Water Cannon

        --[[ Fire ]] --
        [`WEAPON_ELECTRIC_FENCE`] = weaponClasses.FIRE,
        [`WEAPON_FIRE`] = weaponClasses.FIRE,
        [`WEAPON_MOLOTOV`] = weaponClasses.FIRE,
        [`WEAPON_FLARE`] = weaponClasses.FIRE,
        [`WEAPON_FLAREGUN`] = weaponClasses.FIRE,

        --[[ Suffocate ]] --
        [`WEAPON_DROWNING`] = weaponClasses.SUFFOCATING, -- Drowning
        [`WEAPON_DROWNING_IN_VEHICLE`] = weaponClasses.SUFFOCATING, -- Drowning Veh
        [`WEAPON_EXHAUSTION`] = weaponClasses.SUFFOCATING, -- Exhaust
        [`WEAPON_BZGAS`] = weaponClasses.SUFFOCATING,
        [`WEAPON_SMOKEGRENADE`] = weaponClasses.SUFFOCATING,
    },
}
