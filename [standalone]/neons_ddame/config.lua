Config = {
    WeaponDefaults = {
        recoil = 0.0, -- Do giat camera moi vien ban. 0 = tat custom recoil
        spread = nil, -- Do te dan. nil = giu mac dinh weapon meta
        range = 120.0, -- Khoang cach bat dau giam damage
        maxRange = nil, -- Qua tam nay se khong gay damage. nil = khong gioi han
        minDamage = 1
    },

    WeaponDamages = {

        [GetHashKey("weapon_wrench")] = {
            damage = 11,
            headshot = 11,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 11
        },

        [GetHashKey("weapon_nightstick")] = {
            damage = 25,
            headshot = 25,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 25
        },

        [GetHashKey("weapon_revolver_mk2")] = {
            damage = 30,
            headshot = 100,
            recoil = 0,
            spread = 0,
            range = 120.0,
            maxRange = 120.0,
            minDamage = 120
        },

        [GetHashKey("weapon_unarmed")] = {
            damage = 2,
            headshot = 2,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 2
        },

        [GetHashKey("weapon_poolcue")] = {
            damage = 13,
            headshot = 13,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 13
        },

        [GetHashKey("weapon_switchblade")] = {
            damage = 5,
            headshot = 5,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 5
        },

        [GetHashKey("weapon_machete")] = {
            damage = 14,
            headshot = 14,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 14
        },

        [GetHashKey("weapon_bat")] = {
            damage = 14,
            headshot = 14,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 14
        },

        [GetHashKey('weapon_crowbar')] = {
            damage = 7,
            headshot = 7,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 7
        },

        [GetHashKey('weapon_bottle')] = {
            damage = 9,
            headshot = 9,
            recoil = 0,
            spread = 0,
            range = 2.0,
            maxRange = 2.5,
            minDamage = 9
        }
    },

    -- Cau hinh dung chung cho he thong thue thuyen.
    -- Moi lan thue deu bi tru tien mat o server, khong lay gia tu client.
    BoatRental = {
        price = 2000,
        npcModel = 's_m_m_dockwork_01',
        interactionDistance = 2.5,
        blip = {
            sprite = 356,
            color = 3,
            scale = 0.7,
            name = 'Thue thuyen'
        },
        stations = {
            {
                npc = vector4(1297.2118, -3340.2693, 5.9023, 86.8695),
                spawns = {
                    vector4(1312.0710, -3339.0259, 0.2735, 249.6292),
                    vector4(1307.7594, -3327.4243, 0.4172, 239.5034),
                    vector4(1307.1786, -3312.3206, 0.2369, 263.3652)
                }
            },
            {
                npc = vector4(1296.7435, -3063.4348, 5.9066, 107.7410),
                spawns = {
                    vector4(1257.4501, -3048.0823, 0.5428, 324.5516),
                    vector4(1275.5471, -3053.5798, 0.8018, 325.7852),
                    vector4(1300.0132, -3054.4714, 0.9232, 287.2893)
                }
            },
            {
                npc = vector4(979.6691, -2678.8484, 3.1073, 27.9651),
                spawns = {
                    vector4(901.7917, -2647.9172, 0.6609, 218.3478),
                    vector4(925.0811, -2658.0928, 0.2440, 193.7677),
                    vector4(950.0868, -2674.9253, 0.5127, 217.6270)
                }
            }
        },
        boats = {
            {
                model = 'seashark3',
                label = 'Seashark 2 cho',
                description = 'Thuyen cao toc 2 cho'
            },
            {
                model = 'dinghy3',
                label = 'Dinghy 4 cho',
                description = 'Thuyen 4 cho'
            }
        }
    },

    -- Cấu hình lưu trữ phương tiện chung cho RedZone
    RedZoneVehicleStorage = {
        enabled = true,
        bucket = 999,
        propModel = 'null_garage_prop',
        interactionDistance = 3.0,
        retrieveDuration = 5000
    },

    -- Danh sách các IslandRedZone (hỗ trợ cấu hình nhiều khu vực)
    -- blip:
    --   + Dạng boolean: blip = true (bật blip bán kính mặc định), blip = false (tắt blip)
    --   + Dạng table: blip = { enabled = true/false, color = 1, alpha = 125, display = 4, name = '...' }
    IslandRedZones = {
        {
            name = 'Cayo Perico RedZone',
            coords = vector3(4840.571, -5174.425, 2.0),
            radius = 1500.0,
            activationPadding = 300.0,
            scanInterval = 250,
            deleteEmptyVehicles = false,
            vehicleStorage = {
                enabled = true,
                bucket = 999,
                propModel = 'null_garage_prop',
                interactionDistance = 3.0,
                retrieveDuration = 5000
            },
            blip = {
                enabled = true, -- true = hiện blip, false = ẩn blip
                color = 1,
                alpha = 125,
                display = 4,
                name = 'Cayo Perico RedZone'
            }
        },
        {
            name = 'Bãi trồng trái phép',
            coords = vector3(1231.5006, -86.8380, 59.6442),
            radius = 100.0,
            activationPadding = 110.0,
            scanInterval = 250,
            deleteEmptyVehicles = false,
            blip = false -- Đặt false để tắt blip cho khu vực này (hoặc { enabled = false })
        },
        {
            name = 'Chợ đen',
            coords = vector3(-1171.2560, -1571.1517, 3.6636),
            radius = 100.0,
            activationPadding = 110.0,
            scanInterval = 250,
            deleteEmptyVehicles = false,
            blip = false -- Đặt false để tắt blip cho khu vực này (hoặc { enabled = false })
        },
        {
            name = 'Sự kiện Halloween',
            coords = vector3(-1729.3090, -192.9891, 58.4980),
            radius = 150.0,
            activationPadding = 110.0,
            scanInterval = 250,
            deleteEmptyVehicles = false,
            blip = false -- Đặt false để tắt blip cho khu vực này (hoặc { enabled = false })
        },
        {
            name = 'Bãi dò kim loại',
            coords = vector3(-1171.4543, 33.4847, 51.4955),
            radius = 100.0,
            activationPadding = 110.0,
            scanInterval = 250,
            deleteEmptyVehicles = false,
            blip = false -- Đặt false để tắt blip cho khu vực này (hoặc { enabled = false })
        }
    }
}

-- Tương thích ngược: cho phép truy cập qua Config.IslandRedZone
Config.IslandRedZone = Config.IslandRedZones
