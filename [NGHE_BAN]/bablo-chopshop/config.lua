Config = {}

Config.DEBUG = false -- If true, it will print out debug messages in the console.
Config.Logs = false  -- If true, it will send logs to the configured webhook.

Config.Locale = 'en-US'

Config.Interaction = 'ox_lib'

--[[
    Framework - The framework that the script will use. See what frameworks are available in the 'frameworks' folder.

    auto: This will automatically detect the framework.
]]
Config.Framework = 'auto'

--[[
    Inventory - The inventory that the script will use. See what inventories are available in the 'inventories' folder.

    auto: This will automatically detect the inventory.
]]
Config.Inventory = 'auto'

--[[
    Target - The target that the script will use. See what targets are available in the 'interactions' folder.

    auto: This will automatically detect the target.
]]
Config.Target = 'ox_target'

--[[
    MenuSystem - The menu system that the script will use. See what menu systems are available in the 'menus' folder.

    ox_lib_menu: This will use the ox_lib menu system.
    ox_lib_context: This will use the ox_lib context menu system.
    qb-menu: This will use the qb-menu menu system.
    esx_menu_default: This will use the esx_menu_default menu system.
    esx_context: This will use the esx_context menu system.
]]
Config.MenuSystem = 'ox_lib_context'

Config.XPPerVehicle = 2 -- XP per vehicle chopped 2x will be applied for a contract

Config.Levels = {
    {
        xp = 0,
        attributes = {
            ["EXTRA_REWARDS_POINTS"] = 0,      -- Extra rewards point can lead to get more or better loot
            ["INCREASE_RARE_LOOT_CHANCE"] = 0, -- Increase the chance to get rare loot
            ["FASTER_PROGRESS_BAR"] = 0,       -- Increase the speed of the progress bar for example 20% faster so 1.2x
            ["XP_MULTIPLIER"] = 1,             -- XP multiplier for the level, 1.0 = 100% of the XP
        },
    },
    {
        xp = 100,
        attributes = {
            ["EXTRA_REWARDS_POINTS"] = 1,
            ["INCREASE_RARE_LOOT_CHANCE"] = 1,
            ["FASTER_PROGRESS_BAR"] = 5, -- 5% faster progress bar
            ["XP_MULTIPLIER"] = 1.1,     -- 10% more XP
        },
    },
    {
        xp = 1000,
        attributes = {
            ["EXTRA_REWARDS_POINTS"] = 2,
            ["INCREASE_RARE_LOOT_CHANCE"] = 2,
            ["FASTER_PROGRESS_BAR"] = 10,
            ["XP_MULTIPLIER"] = 1.2, -- 20% more XP
        },
    },
    {
        xp = 3000,
        attributes = {
            ["EXTRA_REWARDS_POINTS"] = 3,
            ["INCREASE_RARE_LOOT_CHANCE"] = 3,
            ["FASTER_PROGRESS_BAR"] = 15,
            ["XP_MULTIPLIER"] = 1.3, -- 30% more XP
        },
    },
    {
        xp = 5000,
        attributes = {
            ["EXTRA_REWARDS_POINTS"] = 4,
            ["INCREASE_RARE_LOOT_CHANCE"] = 4,
            ["FASTER_PROGRESS_BAR"] = 20,
            ["XP_MULTIPLIER"] = 1.5, -- 50% more XP
        },
    },

}

Config.Parts = {
    ['DOOR_DSIDE_F'] = {
        label = 'Cánh cửa trước trái',
        bone = 'door_dside_f',
        prop = 'imp_prop_impexp_car_door_04a',
        door = 0,
        type = 'door',
    },

    ['DOOR_PSIDE_F'] = {
        label = 'Cánh cửa trước phải',
        bone = 'door_pside_f',
        prop = 'imp_prop_impexp_car_door_04a',
        door = 1,
        type = 'door',
    },

    ['DOOR_DSIDE_R'] = {
        label = 'Cánh cửa sau trái',
        bone = 'door_dside_r',
        prop = 'imp_prop_impexp_car_door_04a',
        door = 2,
        type = 'door',
    },

    ['DOOR_PSIDE_R'] = {
        label = 'Cánh cửa sau phải',
        bone = 'door_pside_r',
        prop = 'imp_prop_impexp_car_door_04a',
        door = 3,
        type = 'door',
    },

    ['BOOT'] = {
        label = 'Cốp xe',
        bone = 'boot',
        prop = 'imp_prop_impexp_trunk_01a',
        door = 5,
        type = 'door',
    },

    ['HOOD'] = {
        label = 'Cáp nắp capo',
        bone = 'bonnet',
        prop = 'imp_prop_impexp_bonnet_06a',
        door = 4,
        type = 'door',
    },

    ['WHEEL_LF'] = {
        label = 'Bánh xe trước trái',
        bone = 'wheel_lf',
        prop = 'imp_prop_impexp_tyre_02c',
        type = 'wheel',
        wheelId = 0,
    },

    ['WHEEL_RF'] = {
        label = 'Bánh xe trước phải',
        bone = 'wheel_rf',
        prop = 'imp_prop_impexp_tyre_02c',
        type = 'wheel',
        wheelId = 1,
    },

    ['WHEEL_LR'] = {
        label = 'Bánh xe sau trái',
        bone = 'wheel_lr',
        prop = 'imp_prop_impexp_tyre_02c',
        type = 'wheel',
        wheelId = 2,
    },

    ['WHEEL_RR'] = {
        label = 'Bánh xe sau phải',
        bone = 'wheel_rr',
        prop = 'imp_prop_impexp_tyre_02c',
        type = 'wheel',
        wheelId = 3,
    },

    ['WHEEL_LM1'] = {
        label = 'Bánh xe giữa trái',
        bone = 'wheel_lm1',
        prop = 'imp_prop_impexp_tyre_02c',
        type = 'wheel',
        wheelId = 4,
    },

    ['WHEEL_RM1'] = {
        label = 'Bánh xe giữa phải',
        bone = 'wheel_rm1',
        prop = 'imp_prop_impexp_tyre_02c',
        type = 'wheel',
        wheelId = 5,
    },
}

Config.Animations = {
    door = {
        dict = "anim@scripted@heist@ig9_control_tower@male@",
        lib = "loop",
    },
    wheel = {
        dict = "anim@scripted@heist@ig9_control_tower@male@",
        lib = "loop",
    }
}

Config.PropsAlignment = {
    ['imp_prop_impexp_car_door_04a'] = {
        ["offset"] = {
            ["x"] = 0.06298075616359,
            ["y"] = 0.46020317077636,
            ["z"] = 0.8466408252716
        },
        ["rotation"] = {
            ["x"] = -81.7642822265625,
            ["y"] = -154.15765380859375,
            ["z"] = -40.94169235229492
        },
        bone = 4090,
    },
    ['imp_prop_impexp_trunk_01a'] = {
        ["offset"] = {
            ["x"] = -0.01096697244793,
            ["y"] = -0.08372183144092,
            ["z"] = 0.23483811318874
        },
        ["rotation"] = {
            ["x"] = -117.96595764160156,
            ["y"] = 101.95919799804688,
            ["z"] = 7.95247745513916
        },
        bone = 4090,
    },
    ['imp_prop_impexp_bonnet_06a'] = {
        ["offset"] = {
            ["x"] = -0.12566529214382,
            ["y"] = -0.10592094063758,
            ["z"] = 0.27443206310272
        },
        ["rotation"] = {
            ["x"] = 76.35232543945312,
            ["y"] = 109.7320785522461,
            ["z"] = 3.59581136703491
        },
        bone = 4090,
    },
    ['imp_prop_impexp_tyre_02c'] = {
        offset = {
            ["x"] = 0.01599408127367,
            ["y"] = 0.17700417339801,
            ["z"] = 0.293681204319
        },
        rotation = {
            ["x"] = 0,
            ["y"] = 0,
            ["z"] = -48.53520584106445
        },
        bone = 4090,
    },
}

Config.ChopShops = {
    {
        blip = false,
        dropOff = vector3(-440.42333984375, -1693.4976806641, 19.229410171509),
        ped = {
            position = vector3(-437.75695800781, -1696.2392578125, 18.948623657227 - 0.98),
            heading = 162.82615661621,
            model = "s_m_y_xmech_02",
            label = "Rã xe",
        },
        points = {
            vector3(-398.86364746094, -1676.8055419922, 18.5),
            vector3(-460.5693359375, -1649.0234375, 18.5),
            vector3(-552.54522705078, -1596.5467529297, 18.5),
            vector3(-562.74450683594, -1660.6821289062, 18.5),
            vector3(-531.60791015625, -1720.7532958984, 18.5),
            vector3(-480.52352905273, -1741.7927246094, 18.5),
            vector3(-426.42276000977, -1754.6741943359, 18.5)
        }
    },
}

Config.VehicleModels = {
    "akuma",
    "admiral",
    "alpha",
    "asterope",
    "asterope2",
    "baller",
    "banshee",
    "bati",
    "biff",
    "bison",
    "bison2",
    "blista",
    "bodhi2",
    "buccaneer",
    "buffalo",
    "buffalo5",
    "burrito",
    "bus",
    "camper",
    "carbonizzare",
    "carbonrs",
    "cavalcade",
    "chargerf8",
    "cinquemila",
    "cogcabrio",
    "comet2",
    "daemon",
    "dilettante",
    "dloader",
    "dominator",
    "dominator3",
    "dubsta",
    "dubsta2",
    "dubsta3",
    "elegy",
    "emperor",
    "faggio",
    "felon",
    "felon2",
    "feltzer2",
    "feltzer3",
    "flashgt",
    "fnflan",
    "fnfmk4",
    "fugitive",
    "furoregt",
    "fusilade",
    "futo",
    "futo2",
    "gauntlet",
    "glendale",
    "gresley",
    "infernus",
    "ingot",
    "intruder",
    "issi2",
    "jackal",
    "jester",
    "manana",
    "manana2",
    "minivan",
    "minivan2",
    "mixer",
    "mule",
    "neon",
    "ninef",
    "oracle",
    "oracle2",
    "panto",
    "penumbra",
    "peyote",
    "picador",
    "prairie",
    "premier",
    "primo",
    -- "r2f2fgts",
    -- "r2f2fgtr34",
    -- "r2f2fs2000",
    "radi",
    "raiden",
    "rapidgt",
    "ratloader",
    "regina",
    "rhapsody",
    "ruiner",
    "sabreturbo",
    "sandking2",
    "schafter2",
    "schwarzer",
    "seminole",
    "sentinel2",
    "sentinelxs",
    "serrano",
    -- "sh350",
    "shinobi",
    "stanier",
    "stratum",
    "sultan",
    "surano",
    "surge",
    "taco",
    -- "thecivir23",
    -- "titanh2",
    "tornado",
    "vigero",
    "voltic",
    "warrener",
    "washington",
    -- "yaz",
    "yosemite2",
    "youga",
    "zion",
}

Config.VehicleModelAliases = {
    admiral = "washington",
    comet = "comet2",
    issi = "issi2",
    sabreturbo = "sabregt",
    sandkingxl = "sandking",
    sentinelxs = "sentinel2",
}

Config.Contracts = {
    ["easy"] = {
        min = 1,
        max = 2,
        vehicles = Config.VehicleModels,
        label = "Hoá đơn dễ",
        minLevelRequired = 0, -- Available from level 1 (starting level)
        price = 10000,       -- Phí nhận hợp đồng ($10.000)
    },
    ["medium"] = {
        min = 3,
        max = 3,
        vehicles = Config.VehicleModels,
        label = "Hoá đơn thường",
        minLevelRequired = 3, -- Requires level 2 to unlock
        price = 10000,        -- Phí nhận hợp đồng ($10.000)
    },
    ["hard"] = {
        min = 4,
        max = 6,
        vehicles = Config.VehicleModels,
        label = "Hoá đơn khó",
        minLevelRequired = 5, -- Requires level 3 to unlock
        price = 10000,        -- Phí nhận hợp đồng ($10.000)
    },
}

--[[
    ContractCooldown - Prevents players from requesting contracts too quickly.

    enabled  : Set to true to activate the cooldown.
    cooldown : Time in seconds a player must wait between contracts.
               900 = 15 minutes. 1800 = 30 minutes.
]]
Config.ContractCooldown = {
    enabled  = true,
    cooldown = 900, -- Cooldown 15 phút (900 giây)
}

Config.PoliceOnDutyRequired = 0 -- SỐ CẢNH SÁT TRÊN SERVER ĐANG TRỰC (0 = KHÔNG YÊU CẦU)
Config.PoliceJobs = { 'police' } -- Danh sách các job cảnh sát
Config.PoliceCallChance = 30 -- Percentage chance (0 to 100) to alert the police when dismantling a vehicle part
Config.StressPerPart = 1.0    -- Stress added when dismantling a vehicle part

--[[
    Scanner & Vehicle Spawning Configuration (Hệ thống tìm xe bằng Máy dò / DigiScanner)
]]
Config.GiveScannerOnContract = false -- Tự động cấp Máy Dò (WEAPON_DIGISCANNER) khi nhận hợp đồng (false = Tắt cấp máy dò)
Config.SearchRadius = 130.0         -- Bán kính vùng khoanh vùng (Zone Blip) trên bản đồ (mét)
Config.PoliceAlertOnFound = true    -- Báo cảnh sát khi người chơi tìm thấy xe mục tiêu

-- Danh sách các vị trí xuất hiện xe ngẫu nhiên khi nhận hợp đồng
Config.VehicleCoords = {
    [1]  = { coords = vector4(-1074.953, -1160.545, 1.66, 119.0), radarCoords = vector3(-1074.953, -1160.545, 1.66) },
    [2]  = { coords = vector4(-1023.625, -890.401, 5.20, 216.0),   radarCoords = vector3(-1023.625, -890.401, 5.20) },
    [3]  = { coords = vector4(-1609.647, -382.792, 42.70, 52.5),   radarCoords = vector3(-1609.647, -382.792, 42.70) },
    [4]  = { coords = vector4(97.578, -1946.472, 20.28, 215.9),    radarCoords = vector3(97.578, -1946.472, 20.28) },
    [5]  = { coords = vector4(437.542, -1925.465, 24.00, 28.8),     radarCoords = vector3(437.542, -1925.465, 24.00) },
    [6]  = { coords = vector4(438.448, -1838.672, 27.47, 42.8),     radarCoords = vector3(438.448, -1838.672, 27.47) },
    [7]  = { coords = vector4(724.89, -587.65, 26.65, 89.2),       radarCoords = vector3(724.89, -587.65, 26.65) },
    [8]  = { coords = vector4(1185.35, -3114.73, 5.03, 90.0),      radarCoords = vector3(1185.35, -3114.73, 5.03) },
    [9]  = { coords = vector4(-2174.65, -387.89, 12.33, 150.0),    radarCoords = vector3(-2174.65, -387.89, 12.33) },
    [10] = { coords = vector4(968.41, -127.35, 73.35, 55.0),        radarCoords = vector3(968.41, -127.35, 73.35) },
    [11] = { coords = vector4(-153.25, 6310.22, 30.56, 45.0),      radarCoords = vector3(-153.25, 6310.22, 30.56) },
    [12] = { coords = vector4(1707.82, 3274.61, 40.16, 195.0),     radarCoords = vector3(1707.82, 3274.61, 40.16) },
    [13] = { coords = vector4(222.24, -2017.48, 18.17, 135.5),     radarCoords = vector3(222.24, -2017.48, 18.17) },
    [14] = { coords = vector4(-580.82, -1214.22, 17.38, 25.0),     radarCoords = vector3(-580.82, -1214.22, 17.38) },
    [15] = { coords = vector4(1141.48, -1994.49, 30.43, 270.0),    radarCoords = vector3(1141.48, -1994.49, 30.43) },
    [16] = { coords = vector4(-1385.12, -493.89, 32.16, 212.0),    radarCoords = vector3(-1385.12, -493.89, 32.16) },
}

Config.Rewards = {
    {
        name = 'rubber',
        count = {10, 20},
        points = 1,
        limit = 1,
        percent = 50
    },
    {
        name = 'hdpe',
        count = {10, 20},
        points = 1,
        limit = 1,
        percent = 50
    },
    {
        name = 'metalscrap',
        count = {10, 20},
        points = 1,
        limit = 1,
        percent = 50
    },
    {
        name = 'dochoixe',
        count = {10, 20},
        points = 1,
        limit = 1,
        percent = 50
    },
    {
        name = 'rubber',
        count = {20, 30},
        points = 1,
        limit = 1,
        percent = 50,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'hdpe',
        count = {20, 30},
        points = 1,
        limit = 1,
        percent = 50,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'metalscrap',
        count = {20, 30},
        points = 1,
        limit = 1,
        percent = 50,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'dochoixe',
        count = {20, 30},
        points = 1,
        limit = 1,
        percent = 50,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'cosmetics',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'mechspray',
        count = 1,
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'car_wheel',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'spoiler',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'front_bumper',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'rear_bumper',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'skirtcar',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'car_hood',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'exhaust',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'horn',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'internals',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'seats',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'vanity_plate',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
    {
        name = 'engine_block',
        count = { 1, 2 },
        points = 1,
        limit = 1,
        percent = 10,
        contract_type = { "medium", "hard" }
    },
}

Config.VehicleHashes = json.decode(LoadResourceFile(GetCurrentResourceName(), "vehicleHashes.json"))
