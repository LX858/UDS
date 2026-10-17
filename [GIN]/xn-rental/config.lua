Config = {}

Config.Target = true

-- Multiplier per minutes/hours
Config.mpMinutes = 60 -- price * Config.Minutes * time >> es. 30000 * 60 * 15 / 200
Config.mpHours = 360  -- price * Config.Hours * time >> es. 30000 * 360 * 15 / 360

Config.PlatePrefix = "RENTAL"

-- Taxi system config
Config.TaxiSystem = {
    enable = false, -- Bật/tắt hệ thống gọi taxi khi có taxi driver online
    pingEvent = "xn_pingjob:pingTaxi" -- Event để gọi taxi
}
Config.Rentals = {
     {
        pos = vector4(288.1049, -1377.8712, 31.5919, 208.3156),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(289.1208, -1379.6143, 30.9727, 138.8940)
            },
            { 
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(289.1208, -1379.6143, 30.9727, 138.8940)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(289.1208, -1379.6143, 30.9727, 138.8940)
            -- },
        }
    },
    {
        pos = vector4(-1791.4873, -683.6566, 10.6413, 133.9725),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(-1797.5455, -689.5410, 9.9087, 48.8137)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(-1797.5455, -689.5410, 9.9087, 48.8137)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(-1797.5455, -689.5410, 9.9087, 48.8137)
            -- },
        }
    },
    {
        pos = vector4(344.3070, 46.2832, 90.8320, 81.7017),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(339.2929, 47.2038, 91.6102, 352.9520)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(339.2929, 47.2038, 91.6102, 352.9520)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(339.2929, 47.2038, 91.6102, 352.9520)
            -- },
        }
    },
    {
        pos = vector4(-238.4933, -978.4618, 28.2877, 269.1399),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(-233.0581, -980.0698, 29.1583, 154.6409)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(-233.0581, -980.0698, 29.1583, 154.6409)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(-233.0581, -980.0698, 29.1583, 154.6409)
            -- },
        }
    },
    {
        pos = vector4(-326.0436, 235.2468, 85.6694, 23.4955),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(-329.3493, 234.7571, 86.4639, 12.4201)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(-329.3493, 234.7571, 86.4639, 12.4201)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(-329.3493, 234.7571, 86.4639, 12.4201)
            -- },
        }
    },
    {
        pos = vector4(1699.6010, 60.5447, 171.058, 10.6201),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
            {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(1697.4083, 66.1105, 171.4006, 76.4247)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(1697.4083, 66.1105, 171.4006, 76.4247)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(1697.4083, 66.1105, 171.4006, 76.4247)
            -- },
        }
    },
    {
        pos = vector4(247.7352, -574.6721, 42.3057, 252.5320),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(242.0448, -566.8775, 43.2788, 256.6155)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(242.0448, -566.8775, 43.2788, 256.6155)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(242.0448, -566.8775, 43.2788, 256.6155)
            -- },
        }
    },
    {
        pos = vector4(216.2561, -815.4969, 29.6442, 159.8248),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(214.9039, -821.2086, 30.5602, 74.0381)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(214.9039, -821.2086, 30.5602, 74.0381)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 100,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(214.9039, -821.2086, 30.5602, 74.0381)
            -- },
        }
    },
    {
        pos = vector4(141.0533, -401.2422, 40.1321, 245.1447),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
            {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(146.7949, -403.9379, 41.0556, 160.7845)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(146.7949, -403.9379, 41.0556, 160.7845)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(146.7949, -403.9379, 41.0556, 160.7845)
            -- },
        }
    },
    {
        pos = vector4(2592.6760, 4689.9004, 32.4734, 314.9588),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
           {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(2595.0493, 4693.7305, 33.2419, 30.3067)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(2595.0493, 4693.7305, 33.2419, 30.3067)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(2595.0493, 4693.7305, 33.2419, 30.3067)
            -- },
        }
    },
    {
        pos = vector4(-1911.7490, 2025.8356, 139.7390, 322.5854),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
            {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(-1906.5764, 2024.2784, 140.7421, 249.7709)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(-1906.5764, 2024.2784, 140.7421, 249.7709)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(-1906.5764, 2024.2784, 140.7421, 249.7709)
            -- },
        }
    },
    {
        pos = vector4(1852.1648, 2581.4753, 45.6721, 247.8374),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
            {
                label = "Cruiser",
                car = "cruiser",
                price = 50,
                image = "https://docs.fivem.net/vehicles/cruiser.webp",
                spawnPosition = vector4(1860.0157, 2583.1023, 45.2480, 180.3531)
            },
            {
                label = "Faggio2",
                car = "faggio2",
                price = 100,
                image = "https://docs.fivem.net/vehicles/faggio2.webp",
                spawnPosition = vector4(1860.0157, 2583.1023, 45.2480, 180.3531)
            },
            -- {
            --     label = "Brioso",
            --     car = "brioso",
            --     price = 200,
            --     image = "https://docs.fivem.net/vehicles/brioso.webp",
            --     spawnPosition = vector4(1860.0157, 2583.1023, 45.2480, 180.3531)
            -- },
        }
    },
    {
        pos = vector4(858.6471, 3673.8496, 31.9304, 89.2507),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
            {
                label = "Marquis",
                car = "marquis",
                price = 300,
                image = "https://docs.fivem.net/vehicles/marquis.webp",
                spawnPosition = vector4(846.9252, 3705.3455, 29.6300, 17.1805)
            },
        }
    },
    {
        pos = vector4(-3428.4438, 967.5532, 8.3467, 265.3134),
        pedModel = "u_f_m_miranda_02",
        blip = {
            enable = true,
            type   = 56,
            color  = 50,
            scale  = 0.8,
            name   = "Thuê phương tiện"
        },
        vehicles = {
            {
                label = "Marquis",
                car = "marquis",
                price = 300,
                image = "https://docs.fivem.net/vehicles/marquis.webp",
                spawnPosition = vector4(-3450.7097, 940.2159, -0.1856, 143.8056)
            },
        }
    },
}