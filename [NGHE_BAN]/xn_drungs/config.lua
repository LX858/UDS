Config = {}
Config.debug = false

Config.TARGET = 'ox' -- ox or qb

Config.RequiredCops = 3


Config.Cooldown = {
    npc = { -- Cooldown between deliveries, min and max in minutes
        min = 1,
        max = 3,
    },
    delivery = { -- Cooldown between new job, min and max in minutes
        min = 10,
        max = 15,
    },
    globalDealer = 3 -- Cooldown in minutes for each dealer on the server
}

Config.Price = {
    cocaine = 400,
    weed = 150,
    meth = 600,
    priceCocaineSelling = math.random(2800, 3000),
}

Config.Dealers = {
    cocaine = {
        npc1 = {
            coords = vector4(-1292.4316, -592.7633, 28.3024, 133.0292),
            vehicleSpawn = vector4(-1311.9146, -595.7169, 27.8714, 31.6643),
            RenderDistance = 20
        },
        npc2 = {
            coords = vector4(164.1136, 152.1317, 104.1783, 158.3421),
            vehicleSpawn = vector4(152.1471, 163.0018, 104.2379, 250.0082),
            RenderDistance = 20
        },
        npc3 = {
            coords = vector4(933.0724, -1151.3251, 25.0525, 279.6548),
            vehicleSpawn = vector4(938.2886, -1140.5945, 24.3648, 359.4180),
            RenderDistance = 20
        },
    },
}

Config.itemhang = 'package'
Config.ConversionRate = 3  -- 3 goi_dudu_say = 1 itemhang
Config.PackagesPerMission = 5 -- so itemhang moi chuyen (5 diem giao)

Config.Blueprint = {
    enabled = true,
    item = 'banvevukhi',
    chance = 10 -- 10% chance to get blueprint when delivering
}

Config.MissionVehicles = {
    "banshee",
    "buffalo",
    "buffalo2",
    "carbonizzare",
    "comet2",
    "futo",
    "penumbra",
    "rapidgt",
    "rapidgt2",
    "schafter2",
    "sultan",
    "surano",
}

Config.Models = {
    "a_m_m_hillbilly_02",
    "a_m_m_salton_04",
    "a_m_m_polynesian_01",
    "a_m_m_polynesian_01",
    "a_m_m_salton_02",
    "a_m_m_salton_03",
    "a_m_m_skater_01",
    "a_m_m_soucent_04",
    "a_m_m_soucent_03",
    "a_m_m_skidrow_01",
    "a_m_m_socenlat_01",
    "a_m_m_soucent_01",
    "a_m_o_beach_01",
    "a_m_o_soucent_03",
    "a_m_o_tramp_01",
    "a_m_o_soucent_02",
    "a_m_o_salton_01",
    "a_f_m_skidrow_01",
    "a_f_m_tourist_01",
    "a_f_m_trampbeac_01",
    "a_f_o_indian_01",
    "a_f_y_clubcust_02",
    "a_f_y_hipster_02",
    "a_f_y_rurmeth_01"
}

Config.Buyers = {
    npc1 = {
        coords = vector4(-1067.0746, -504.5410, 35.0798, 25.4282),
        RenderDistance = 35
    },
    npc2 = {
        coords = vector4(54.5449, 163.6573, 103.7610, 273.0411),
        RenderDistance = 35
    },
    npc3 = {
        coords = vector4(167.4547, -1248.3344, 28.1984, 78.3712),
        RenderDistance = 35
    },
    npc4 = {
        coords = vector4(-324.8175, -1356.3646, 30.2957, 99.2964),
        RenderDistance = 35
    },
    npc5 = {
        coords = vector4(-1995.7758, -504.8550, 11.0130, 238.6174),
        RenderDistance = 35
    },
    npc6 = {
        coords = vector4(-3102.0952, 367.3326, 6.1191, 147.8980),
        RenderDistance = 35
    },
    npc7 = {
        coords = vector4(-1690.8997, -431.7747, 41.3730, 246.4736),
        RenderDistance = 35
    },
    npc8 = {
        coords = vector4(-1496.6851, -318.3724, 45.9418, 126.6329),
        RenderDistance = 35
    },
    npc9 = {
        coords = vector4(-1336.2859, -226.7334, 41.9637, 297.6121),
        RenderDistance = 35
    },
    npc10 = {
        coords = vector4(-297.0966, 303.4752, 89.7184, 0.0307),
        RenderDistance = 35
    },
    npc11 = {
        coords = vector4(-497.5015, 79.3391, 54.9189, 80.6300),
        RenderDistance = 35
    },
    npc12 = {
        coords = vector4(-594.6409, 179.6907, 64.3169, 170.0314),
        RenderDistance = 35
    },
    npc13 = {
        coords = vector4(59.7535, -41.5417, 68.2935, 253.3634),
        RenderDistance = 35
    }
}


Config.Notify = {
    dealFailed = {
        title = 'Giao đu đủ',
        description = Locales.deal_failed,
        duration = 10000,
        type = 'error'
    },
    notEnoughMoney = {
        title = 'Giao đu đủ',
        description = Locales.not_enough_money,
        duration = 10000,
        type = 'error'
    },
    StartJob = {
        title = 'Giao đu đủ',
        description = Locales.start_job,
        duration = 10000,
        type = 'info'
    },
    buyerLocation = {
        title = 'Giao đu đủ',
        description = Locales.buyer_located,
        duration = 10000,
        type = 'success'
    }
}
