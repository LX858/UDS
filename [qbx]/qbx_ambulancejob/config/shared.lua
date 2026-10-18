return {
    hoisinh = 2500, -- Giá hồi sinh khi không có bác sĩ
    chuatri = 2000, -- Giá chữa trị vết thương
    checkInCost = 2500, -- Price for using the hospital check-in system
    minForCheckIn = 0, --Số lượng người có công việc xe cứu thương tối thiểu để ngăn hệ thống nhận phòng được sử dụng

    -- Cấu hình điều trị trên giường (CHỮa TRỊT VẾT THƯƠNG - khi đang sống)
    bedTreatment = {
        duration = 5000, -- Thời gian chữa trị vết thương: 60 giây
        nurseModel = 's_f_y_scrubs_01', -- Model NPC y tá

        -- Khu vực cho phép chữa trị (hỗ trợ nhiều bệnh viện)
        treatmentZones = {
            { -- Bệnh viện Pillbox (thành phố)
                center = vec3(-1001.3127, -430.3744, 39.6155),
                radius = 10.0,
                showMarker = false,
            },
            { -- Bệnh viện sa mạc (Paleto)
                center = vec3(1738.7184, 3631.8525, 34.8526),
                radius = 08.0,
                showMarker = true,
            },
        },

        -- Vị trí NPC (offset từ bệnh nhân)
        npcPositions = {
            foot = { x = 0.0, y = 0.8, z = -1.0 }, -- NPC dưới chân
            left = { x = -1.2, y = 0.0, z = -1.7 }, -- NPC bên trái
            right = { x = 1.2, y = 0.0, z = -1.7 }, -- NPC bên phải
        },

        -- Animation cho NPC
        animations = {
            foot = {
                dict = 'mini@strip_club@private_dance@part2',
                anim = 'priv_dance_p2'
            },
            sides = { -- Animation cho 2 bên
                dict = 'mini@repair',
                anim = 'fixing_a_ped'
            }
        }
    },

    -- Cấu hình HỒI SINH TỰ ĐỘNG khi không có bác sĩ (KHI CHẾT)
    autoRevive = {
        duration = 1000, -- Thời gian hồi sinh tự động: 120 giây (2 phút)
        useBedTreatment = true, -- Có spawn 3 NPC y tá giống chữa trị không
    },

    -- Cấu hình Med Lang Băm (Cứu trong vùng đỏ)
    medLangBam = {
        difficulty = 3, -- Độ khó minigame mgc: button_mash
        redZones = {
            {
                id = 1,
                name = "Bãi đu đủ",
                coords = vector3(1231.5006, -86.8380, 59.6442),
                radius = 100.0,
            },
            {
                id = 1,
                name = "Chợ đen",
                coords = vector3(-1171.2560, -1571.1517, 3.6636),
                radius = 100.0,
            },
            {
                id = 3,
                name = "bãi hoa",
                coords = vector3(1481.9066, -2354.6516, 71.9142),
                radius = 100.0,
            },
            {
                id = 2,
                name = "bãi dò kim loại",
                coords = vector3(-1459.4183, -1277.8962, 3.5524),
                radius = 100.0,
            },
            -- Các nhà Gang
            {
                name = "Nhà Gang 1",
                coords = vector3(309.53, -907.07, 29.29),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 2",
                coords = vector3(-223.12, -1601.14, 34.88),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 3",
                coords = vector3(130.58, -1853.29, 25.23),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 4",
                coords = vector3(-83.51, -1622.99, 31.47),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 5",
                coords = vector3(114.37, -1961.13, 21.32),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 6",
                coords = vector3(373.64, -2002.72, 24.24),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 7",
                coords = vector3(-50.37, -1783.21, 28.30),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 8",
                coords = vector3(-69.42, -1526.75, 34.23),
                radius = 60.0,
            },
            {
                name = "Nhà Gang 9",
                coords = vector3(367.54, -1802.21, 29.06),
                radius = 60.0,
            },
            {
                name = "Đảo đầu lâu",
                coords = vector3(4840.571, -5174.425, 2.0),
                radius = 1500.0,
            },
        },
    },

    locations = { -- Various interaction points
        duty = {
            vec3(353.61779785156,-1407.3332519531,32.598197937012),
            vec3(308.21145629883,-595.99682617188,43.291812896729)
        },
        vehicle = {
            -- vec4(294.578, -574.761, 43.179, 35.79),
            -- vec4(-234.28, 6329.16, 32.15, 222.5),
        },
        helicopter = {
            -- vec4(351.58, -587.45, 74.16, 160.5),
            -- vec4(-475.43, 5988.353, 31.716, 31.34),
        },
        armory = {
            {
                shopType = 'AmbulanceArmory',
                name = 'Armory',
                groups = { ambulance = 2 },
                inventory = {
                    { name = 'radio', price = 0 },
                    { name = 'hatgiongbong', price = 10 },
                    { name = 'binhlannghanh', price = 1000 },
                },
                locations = {
                    vec3(327.67965698242,-1439.8696289062,29.894824981689)
                }
            }
        },
        roof = {
            vec3(356.49737548828,-1426.4880371094,32.754261016846),
        },
        main = {
            vec3(348.37454223633,-1426.9364013672,46.893947601318),
        },
        stash = {
            -- {
            --     name = 'ambulanceStash',
            --     label = 'Personal stash',
            --     weight = 100000,
            --     slots = 20,
            --     groups = { ambulance = 0 },
            --     owner = true, -- Set to false for group stash
            --     location = vec3(310.41, -592.32, 43.27), -- tu ca nhan
            -- }
        },

        ---@class Bed
        ---@field coords vector4
        ---@field model number

        ---@type table<string, {coords: vector3, checkIn?: vector3|vector3[], beds: Bed[]}>
        hospitals = {
            pillbox = {
                coords = vec3(353.22775268555,-1407.6306152344,32.598201751709),
                checkIn = vec3(308.13, -582.57, 43.27),
                beds = {
                    {coords = vec4(306.2092, -1410.2085, 29.8740, 230.0000), model = -421052012},
                    {coords = vec4(303.8302, -1413.2146, 29.8740, 230.0000), model = -421052012},
                    {coords = vec4(301.1472, -1415.8984, 29.8740, 230.0000), model = -421052012},
                    {coords = vec4(298.8211, -1418.9619, 29.8740, 230.0000), model = -421052012},
                    {coords = vec4(307.8408, -1419.8619, 29.8740, 50.0000), model = -421052012},
                    {coords = vec4(310.0091, -1417.0189, 29.8740, 50.0000), model = -421052012},
                    {coords = vec4(301.7160, -1422.6102, 29.8740, 46.9228), model = -421052012},
                    {coords = vec4(310.5366, -1411.1178, 29.8740, 235.9010), model = -421052012},
                    {coords = vec4(310.3193, -1425.3982, 29.8740, 313.2775), model = -421052012},
                    {coords = vec4(312.4079, -1422.7852, 29.8740, 330.7304), model = -421052012},
                    {coords = vec4(314.5115, -1420.2607, 29.8740, 319.8773), model = -421052012},
                },
            },
            jail = {
                coords = vec3(1771.8, 2552.22, 45.56),
                beds = {
                    {coords = vec4(1761.96, 2597.74, 45.66, 270.14), model = -421052012},
                    {coords = vec4(1761.96, 2591.51, 45.66, 269.8), model = -421052012},
                    {coords = vec4(1771.8, 2598.02, 45.66, 89.05), model = -421052012},
                    {coords = vec4(1771.85, 2591.85, 45.66, 91.51), model = -421052012},
                },
            },
        },

        stations = {
            -- {label = '~p~[Bệnh Viện]~s~ Thành Phố', coords = vec4(359.4110, -1424.8569, 37.9112, 53.1968)},
            {label = '~p~[Bệnh Viện]~s~ THÀNH PHỐ', coords = vec4(352.5245, -1407.5192, 32.5110, 171.2313)},
        },

        -- Giường bệnh tùy chỉnh cho bác sĩ cứu người
        customBeds = {
            ---BV CU
            vec4(346.99459838867, -590.51318359375, 43.239967346191, 335.7092),
            vec4(350.849609375, -591.68127441406, 43.234077453613, 335.7092),
            vec4(354.27459716797,-592.50982666016,43.234077453613, 335.7092),
            vec4(357.40756225586,-594.16687011719,43.250553131104, 335.7092),
            --Phòng 1
            vec4(350.5480, -1436.0745, 32.4356, 50.0000),
            vec4(348.8848, -1438.5657, 32.4356, 50.0000),
            vec4(346.8762, -1440.7361, 32.4356, 50.0000),
            vec4(344.84008789062, -1443.0684814453, 32.435581207275, 50.0000),
            vec4(342.82357788086,-1445.2568359375,32.435581207275, 50.000),
            vec4(341.17739868164,-1447.1175537109,32.435581207275, 50.000),
            vec4(334.4947, -1441.6682, 32.4354, 230.0000),
            vec4(336.21917724609,-1439.8817138672,32.435359954834, 230.000),
            vec4(338.23492431641,-1437.5748291016,32.435359954834, 230.000),
            -- phòng 2
            vec4(340.10375976562,-1435.4462890625,32.435359954834, 230.000),
            vec4(341.93460083008,-1433.1303710938,32.435359954834, 230.000),
            vec4(343.90182495117,-1430.8255615234,32.435359954834, 230.0000),
            ---BV MOI

            vec4(306.2092, -1410.2085, 29.8740, 230.0000),
            vec4(303.8302, -1413.2146, 29.8740, 230.0000),
            vec4(301.1472, -1415.8984, 29.8740, 230.0000),
            vec4(298.8211, -1418.9619, 29.8740, 230.0000),
            vec4(307.8408, -1419.8619, 29.8740, 50.0000),
            vec4(310.0091, -1417.0189, 29.8740, 50.0000),
            vec4(301.7160, -1422.6102, 29.8740, 46.9228),
            vec4(310.5366, -1411.1178, 29.8740, 235.9010),
            vec4(310.3193, -1425.3982, 29.8740, 313.2775),
            vec4(312.4079, -1422.7852, 29.8740, 330.7304),
            vec4(314.5115, -1420.2607, 29.8740, 319.8773)

        }
    },
}