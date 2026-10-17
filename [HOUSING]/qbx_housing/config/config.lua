Config = {}

-- Cấu hình chung
Config.Debug = false -- Bật debug commands (chỉ dùng khi test)
Config.InteractionDistance = 2.0 -- Khoảng cách để tương tác với cửa
Config.UseTarget = true -- Sử dụng ox_target
Config.DebugPoly = false -- Hiển thị debug zones

-- Loại nhà
Config.HouseTypes = {
    ['slum'] = {
        label = 'Nhà Ổ Chuột',
        price = 50000,
        maxSharedKeys = 1, -- Giới hạn số người chia sẻ chìa khóa
        storage = {
            slots = 25,
            weight = 100000 -- 100kg
        },
        garage = {
            maxVehicles = 2,
            interior = 'low_end' -- MLO interior từ mh_garage
        }
    },
    ['regular'] = {
        label = 'Nhà Thường',
        price = 150000,
        maxSharedKeys = 2, -- Giới hạn số người chia sẻ chìa khóa
        storage = {
            slots = 30,
            weight = 110000 -- 110kg
        },
        garage = {
            maxVehicles = 6,
            interior = 'medium' -- MLO interior từ mh_garage
        }
    },
    ['apartment'] = {
        label = 'Nhà Chung Cư',
        price = 300000,
        maxSharedKeys = 3, -- Giới hạn số người chia sẻ chìa khóa
        storage = {
            slots = 40,
            weight = 130000 -- 120kg
        },
        garage = {
            maxVehicles = 10,
            interior = 'autoshop' -- MLO interior từ mh_garage
        }
    },
    ['homestay'] = {
        label = 'Homestay',
        price = 500000,
        maxSharedKeys = 4, -- Giới hạn số người chia sẻ chìa khóa
        storage = {
            slots = 50,
            weight = 150000 -- 150kg
        },
        garage = {
            maxVehicles = 10,
            interior = 'autoshop' -- MLO interior từ mh_garage
        }
    },
    ['gang'] = {
        label = 'Nhà Xã Đoàn',
        price = 0,
        maxSharedKeys = 50,
        storage = {
            slots = 50,
            weight = 500000 -- 500kg
        },
        garage = {
            maxVehicles = 20,
            interior = 'autoshop'
        }
    }
}

-- Custom Blip Sprites cho từng Gang (nếu không khai báo sẽ dùng sprite mặc định 438)
Config.GangBlipSprites = {
    ['saigondanang'] = 76,
    ['buidoi'] = 77,
    ['dongphuong'] = 78,
    ['dongxuong'] = 79,
    ['tdgang'] = 80,
    ['cuulonghoi'] = 86,
    ['lsf'] = 123,
    ['bakhi'] = 124,
}

-- Nhà Ổ Chuột
-- Cấu trúc mỗi house:
--   door: Điểm cửa nhà (để mở NUI)
--   interior: Coords bên trong interior
--   storagePoint: Điểm mở storage
--   packagingPoint: Điểm đóng thùng hàng (chỉ chủ nhà mới thấy)
--   exitPoint: Điểm exit về ngoài
--   garagePoint: Điểm để CẤT XE (parkVehicle trong mh_garage) - Phải đứng gần đây khi trong xe để cất
--   garageSpawn: Điểm SPAWN XE khi lấy ra (vehicleSpawnPoint trong mh_garage)
Config.SlumHouses = {
    {
        id = 'slum_1',
        type = 'slum',
        door = vec3(100.94, -1912.42, 21.41),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(262.77, -1001.12, -98.17),
        exitPoint = vec3(100.94, -1912.42, 21.41),
        garagePoint = vec3(93.04, -1923.97, 19.87),
        garageSpawn = vec4(93.04, -1923.97, 19.87, 57.79)
    },
    {
        id = 'slum_2',
        type = 'slum',
        door = vec3(114.36, -1961.16, 21.33),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(114.36, -1961.16, 21.33),
        garagePoint = vec3(108.99, -1950.55, 19.87),
        garageSpawn = vec4(108.99, -1950.55, 19.87, 300.09)
    },
    {
        id = 'slum_3',
        type = 'slum',
        door = vec3(85.35, -1959.19, 21.12),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(85.35, -1959.19, 21.12),
        garagePoint = vec3(96.17, -1946.71, 19.89),
        garageSpawn = vec4(96.17, -1946.71, 19.89, 19.87)
    },
    {
        id = 'slum_4',
        type = 'slum',
        door = vec3(56.44, -1922.62, 21.91),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(56.44, -1922.62, 21.91),
        garagePoint = vec3(83.2, -1928.21, 19.87),
        garageSpawn = vec4(83.2, -1928.21, 19.87, 48.01)
    },
    {
        id = 'slum_5',
        type = 'slum',
        door = vec3(39.02, -1911.48, 21.95),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(39.02, -1911.48, 21.95),
        garagePoint = vec3(48.74, -1912.13, 20.87),
        garageSpawn = vec4(48.74, -1912.13, 20.87, 323.64)
    },
    {
        id = 'slum_6',
        type = 'slum',
        door = vec3(23.46, -1896.42, 22.97),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(23.46, -1896.42, 22.97),
        garagePoint = vec3(31.97, -1884.81, 21.65),
        garageSpawn = vec4(31.97, -1884.81, 21.65, 50.61)
    },
    {
        id = 'slum_7',
        type = 'slum',
        door = vec3(5.21, -1884.26, 23.7),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(5.21, -1884.26, 23.7),
        garagePoint = vec3(15.88, -1881.92, 22.35),
        garageSpawn = vec4(15.88, -1881.92, 22.35, 316.99)
    },
    {
        id = 'slum_8',
        type = 'slum',
        door = vec3(45.96, -1864.21, 23.28),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(45.96, -1864.21, 23.28),
        garagePoint = vec3(39.92, -1854.63, 22.06),
        garageSpawn = vec4(39.92, -1854.63, 22.06, 136.77)
    },
    {
        id = 'slum_9',
        type = 'slum',
        door = vec3(21.32, -1844.64, 24.6),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(21.32, -1844.64, 24.6),
        garagePoint = vec3(8.34, -1853.56, 23.25),
        garageSpawn = vec4(8.34, -1853.56, 23.25, 230.14)
    },
    {
        id = 'slum_10',
        type = 'slum',
        door = vec3(-20.45, -1858.87, 25.41),
        interior = vec3(266.07, -1007.14, -101.0),
        storagePoint = vec3(266.42, -999.43, -98.90),
        packagingPoint = vec3(268.50, -1001.00, -98.90),
        exitPoint = vec3(-20.45, -1858.87, 25.41),
        garagePoint = vec3(-21.55, -1851.16, 24.33),
        garageSpawn = vec4(-21.55, -1851.16, 24.33, 318.4)
    }
}

-- Nhà Thường
Config.RegularHouses = {
    {
        id = 'regular_1',
        type = 'regular',
        door = vec3(1301.23, -573.55, 71.73),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1301.23, -573.55, 71.73),
        garagePoint = vec3(1295.36, -567.0, 70.38),
        garageSpawn = vec4(1295.36, -567.0, 70.38, 344.26)
    },
    {
        id = 'regular_2',
        type = 'regular',
        door = vec3(1323.98, -581.92, 73.25),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1323.98, -581.92, 73.25),
        garagePoint = vec3(1319.39, -574.55, 72.18),
        garageSpawn = vec4(1319.39, -574.55, 72.18, 337.79)
    },
    {
        id = 'regular_3',
        type = 'regular',
        door = vec3(1367.19, -606.34, 74.71),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1367.19, -606.34, 74.71),
        garagePoint = vec3(1359.96, -601.9, 73.57),
        garageSpawn = vec4(1359.96, -601.9, 73.57, 359.83)
    },
    {
        id = 'regular_4',
        type = 'regular',
        door = vec3(1385.84, -593.28, 74.49),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1385.84, -593.28, 74.49),
        garagePoint = vec3(1378.36, -596.56, 73.57),
        garageSpawn = vec4(1378.36, -596.56, 73.57, 46.06)
    },
    {
        id = 'regular_5',
        type = 'regular',
        door = vec3(1389.02, -569.55, 74.5),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1389.02, -569.55, 74.5),
        garagePoint = vec3(1388.11, -577.82, 73.57),
        garageSpawn = vec4(1388.11, -577.82, 73.57, 114.98)
    },
    {
        id = 'regular_6',
        type = 'regular',
        door = vec3(1348.09, -547.55, 73.89),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1348.09, -547.55, 73.89),
        garagePoint = vec3(1352.89, -554.79, 73.38),
        garageSpawn = vec4(1352.89, -554.79, 73.38, 155.44)
    },
    {
        id = 'regular_7',
        type = 'regular',
        door = vec3(1302.79, -528.36, 71.46),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1302.79, -528.36, 71.46),
        garagePoint = vec3(1308.26, -534.95, 70.52),
        garageSpawn = vec4(1308.26, -534.95, 70.52, 162.81)
    },
    {
        id = 'regular_8',
        type = 'regular',
        door = vec3(1252.16, -494.2, 69.71),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1252.16, -494.2, 69.71),
        garagePoint = vec3(1261.58, -493.79, 68.54),
        garageSpawn = vec4(1261.58, -493.79, 68.54, 258.52)
    },
    {
        id = 'regular_9',
        type = 'regular',
        door = vec3(1242.05, -566.0, 69.66),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1242.05, -566.0, 69.66),
        garagePoint = vec3(1253.75, -576.95, 68.25),
        garageSpawn = vec4(1253.75, -576.95, 68.25, 272.71)
    },
    {
        id = 'regular_10',
        type = 'regular',
        door = vec3(1251.14, -621.54, 69.41),
        interior = vec3(346.45, -1012.38, -99.2),
        storagePoint = vec3(352.47, -998.90, -99.64),
        packagingPoint = vec3(350.00, -1000.50, -99.64),
        exitPoint = vec3(1251.14, -621.54, 69.41),
        garagePoint = vec3(1260.58, -621.65, 68.43),
        garageSpawn = vec4(1260.58, -621.65, 68.43, 295.51)
    }
}

-- Nhà Chung Cư
Config.Apartments = {
    {
        id = 'apartment_1',
        type = 'apartment',
        apartmentNumber = 676,
        door = vec3(-1447.6, -537.37, 34.74),
        interior = vec3(-1452.61, -539.98, 74.04),
        storagePoint = vec3(-1462.68, -550.12, 73.19),
        packagingPoint = vec3(-1460.00, -548.00, 73.19),
        exitPoint = vec3(-1447.6, -537.37, 34.74),
        garagePoint = vec3(-1428.04, -579.02, 29.72),
        garageSpawn = vec4(-1428.04, -579.02, 29.72, 121.8)
    },
    {
        id = 'apartment_2',
        type = 'apartment',
        apartmentNumber = 655,
        door = vec3(-936.63, -379.38, 38.96),
        interior = vec3(-913.99, -365.81, 114.27),
        storagePoint = vec3(-904.61, -376.64, 113.42),
        packagingPoint = vec3(-907.00, -374.00, 113.42),
        exitPoint = vec3(-936.63, -379.38, 38.96),
        garagePoint = vec3(-963.83, -395.87, 37.06),
        garageSpawn = vec4(-963.83, -395.87, 37.06, 116.66)
    },
    {
        id = 'apartment_3',
        type = 'apartment',
        apartmentNumber = 638,
        door = vec3(-595.73, 35.23, 43.61),
        interior = vec3(-604.38, 58.93, 98.2),
        storagePoint = vec3(-601.11, 44.89, 97.35),
        packagingPoint = vec3(-603.00, 47.00, 97.35),
        exitPoint = vec3(-595.73, 35.23, 43.61),
        garagePoint = vec3(-595.98, 23.4, 42.48),
        garageSpawn = vec4(-595.98, 23.4, 42.48, 265.74)
    }
}

-- Homestay
Config.Homestays = {
    {
        id = 'homestay_1',
        type = 'homestay',
        homestayNumber = 462,
        door = vec3(-1294.35, 454.52, 97.54),
        interior = vec3(-1289.92, 449.28, 97.9),
        storagePoint = vec3(-1290.70, 438.16, 97.69),
        packagingPoint = vec3(-1289.00, 440.50, 97.69),
        exitPoint = vec3(-1294.35, 454.52, 97.54),
        garagePoint = vec3(-1298.2, 457.34, 96.68),
        garageSpawn = vec4(-1298.2, 457.34, 96.68, 89.75)
    },
    {
        id = 'homestay_2',
        type = 'homestay',
        homestayNumber = 510,
        door = vec3(119.32, 564.64, 183.96),
        interior = vec3(117.45, 559.29, 184.3),
        storagePoint = vec3(117.41, 548.75, 184.09),
        packagingPoint = vec3(118.50, 551.00, 184.09),
        exitPoint = vec3(119.32, 564.64, 183.96),
        garagePoint = vec3(131.96, 568.8, 182.63),
        garageSpawn = vec4(131.96, 568.8, 182.63, 90.63)
    },
    {
        id = 'homestay_3',
        type = 'homestay',
        homestayNumber = 480,
        door = vec3(-853.12, 695.64, 148.79),
        interior = vec3(-859.6, 690.14, 152.86),
        storagePoint = vec3(-859.92, 679.95, 152.65),
        packagingPoint = vec3(-860.50, 682.50, 152.65),
        exitPoint = vec3(-853.12, 695.64, 148.79),
        garagePoint = vec3(-860.56, 699.34, 148.16),
        garageSpawn = vec4(-862.99, 698.42, 148.26, 340.64)
    },
    {
        id = 'homestay_4',
        type = 'homestay',
        homestayNumber = 477,
        door = vec3(-686.63, 596.82, 143.64),
        interior = vec3(-681.77, 591.9, 145.39),
        storagePoint = vec3(-674.99, 584.20, 144.96),
        packagingPoint = vec3(-677.00, 586.50, 144.96),
        exitPoint = vec3(-686.63, 596.82, 143.64),
        garagePoint = vec3(-683.31, 603.56, 142.88),
        garageSpawn = vec4(-683.31, 603.56, 142.88, 319.49)
    },
    {
        id = 'homestay_5',
        type = 'homestay',
        homestayNumber = 512,
        door = vec3(373.17, 427.92, 145.68),
        interior = vec3(373.64, 422.91, 145.91),
        storagePoint = vec3(369.97, 413.16, 145.70),
        packagingPoint = vec3(371.00, 415.50, 145.70),
        exitPoint = vec3(373.17, 427.92, 145.68),
        garagePoint = vec3(385.58, 429.98, 143.23),
        garageSpawn = vec4(385.58, 429.98, 143.23, 352.26)
    },
    {
        id = 'homestay_6',
        type = 'homestay',
        homestayNumber = 512,
        door = vec3(346.75, 440.86, 147.7),
        interior = vec3(340.5, 437.04, 149.39),
        storagePoint = vec3(332.29, 432.68, 148.96),
        packagingPoint = vec3(334.50, 434.50, 148.96),
        exitPoint = vec3(346.75, 440.86, 147.7),
        garagePoint = vec3(353.9, 437.62, 145.85),
        garageSpawn = vec4(353.9, 437.62, 145.85, 295.54)
    },
    {
        id = 'homestay_7',
        type = 'homestay',
        homestayNumber = 493,
        door = vec3(-175.44, 502.65, 137.42),
        interior = vec3(-173.85, 496.34, 137.67),
        storagePoint = vec3(-172.06, 486.77, 137.23),
        packagingPoint = vec3(-173.00, 489.00, 137.23),
        exitPoint = vec3(-175.44, 502.65, 137.42),
        garagePoint = vec3(-188.65, 502.03, 133.74),
        garageSpawn = vec4(-188.65, 502.03, 133.74, 103.34)
    }
}

-- Kết hợp tất cả houses
Config.Houses = {}

for _, house in ipairs(Config.SlumHouses) do
    table.insert(Config.Houses, house)
end

for _, house in ipairs(Config.RegularHouses) do
    table.insert(Config.Houses, house)
end

for _, house in ipairs(Config.Apartments) do
    table.insert(Config.Houses, house)
end

for _, house in ipairs(Config.Homestays) do
    table.insert(Config.Houses, house)
end


-- Cấu hình Cấp Độ & Nâng Cấp Trụ Sở Xã Đoàn (Gang House Upgrades)
Config.GangHouseLevels = {
    [1] = {
        level = 1,
        label = 'Cấp 1 - Trụ Sở Sơ Cấp',
        interior = vec4(346.60, -1012.87, -99.20, 0.0),
        stashCoords = vec3(352.56, -998.95, -99.64),
        storage = {
            slots = 50,
            weight = 500000, -- 500kg
            label = 'Kho Trụ Sở Cấp 1 (50 Ô - 500KG)'
        },
        garage = {
            interior = 'low_end',
            maxVehicles = 2,
            label = 'Garage Cấp 1 (2 Xe)'
        },
        requirements = nil -- Cấp mặc định ban đầu
    },
    [2] = {
        level = 2,
        label = 'Cấp 2 - Trụ Sở Trung Cấp',
        interior = vec4(-31.4107, -595.1233, 80.0309, 244.8473),
        stashCoords = vec3(-12.889921188354, -596.69024658203, 79.556922912598),
        storage = {
            slots = 100,
            weight = 1000000, -- 1000kg
            label = 'Kho Trụ Sở Cấp 2 (100 Ô - 1000KG)'
        },
        garage = {
            interior = 'medium',
            maxVehicles = 6,
            label = 'Garage Cấp 2 (Medium - 6 Xe)'
        },
        requirements = {
            cash = 10000000, -- Tiền mặt cash
            items = {
                { vatpham = 'hoa_mynhan', soluong = 2400, sodiem = '1' },
                { vatpham = 'traidudu', soluong = 2400, sodiem = '1' },
                { vatpham = 'the_sieu_trom', soluong = 100, sodiem = '1' },
                { vatpham = 'afk_rare_reward', soluong =  1000, sodiem = '1' },
                { vatpham = 'tinhthach', soluong = 4000, sodiem = '1' },
            }
        }
    },
    [3] = {
        level = 3,
        label = 'Cấp 3 - Trụ Sở Cao Cấp',
        interior = vec4(342.2681, 437.8397, 149.3809, 105.3746),
        stashCoords = vec3(338.62582397461, 437.19735717773, 142.03758239746),
        storage = {
            slots = 150,
            weight = 1500000, -- 1500kg
            label = 'Kho Trụ Sở Cấp 3 (150 Ô - 1500KG)'
        },
        garage = {
            interior = 'autoshop',
            maxVehicles = 10,
            label = 'Garage Cấp 3 (Autoshop - 10 Xe)'
        },
        requirements = {
            cash = 20000000, -- Tiền mặt cash
            items = {
                { vatpham = 'hoa_mynhan', soluong = 4800, sodiem = '2' },
                { vatpham = 'traidudu', soluong = 4800, sodiem = '2' },
                { vatpham = 'the_sieu_trom', soluong = 300, sodiem = '2' },
                { vatpham = 'afk_rare_reward', soluong =  3000, sodiem = '2' },
                { vatpham = 'tinhthach', soluong = 8000, sodiem = '2' },
            }
        }
    }
}

-- Cấu hình NPC/Điểm thay đồ Xã Đoàn công cộng
Config.PublicGangClothing = {
    {
        coords = vec4(4630.2266, -4464.4565, 4.2828, 172.5347),
        model = 'g_m_y_salvagoon_01',
        scenario = 'WORLD_HUMAN_GUARD_STAND',
        blip = {
            enabled = true,
            sprite = 73,
            color = 1,
            scale = 0.7,
            name = 'Tủ Đồ Xã Đoàn (Công Cộng)'
        }
    }
}