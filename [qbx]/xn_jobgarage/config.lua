Config = {}

-- Debug settings
Config.Debug = false  -- Bật debug prints để kiểm tra lỗi

-- General settings
Config.InteractionDistance = 10.0  -- Distance to show 3D text
Config.UseDistance = 4.0          -- Distance to interact
Config.InteractionKey = 38        -- E key (control ID)

Config.ImpoundCost = 1000      -- Chi phí tạm giữ xe

-- Vehicle type settings
Config.VehicleTypes = {
    ground = {
        label = "🚗 Xe Mặt Đất",
        icon = "car"
    },
    aircraft = {
        label = "✈️ Máy Bay",
        icon = "plane"
    },
    boat = {
        label = "🚤 Thuyền",
        icon = "boat"
    }
}

-- Vehicle trailer settings (Xe kéo theo thùng/trailer)
Config.VehicleTrailers = {
    ["citaroflg"] = "trailerscitaroflg"
}

-- Job garage configurations
Config.JobGarages = {
    ambulance = {
        label = "🚑 Ambulance Garage",
        drawText = vector3(301.4660, -1428.7924, 29.9687),
        spawnPoint = vec4(297.3643, -1435.6819, 29.0328, 231.2451),
        vehicleType = "ground",
        vehicles = {
            {name = "energym3g80med", label = "Xe Cơ Bản", grade = 1, fee = 0},
            {name = "energyvanmed", label = "Xe Thực Tập Sinh", grade = 0, fee = 0},
            {name = "energygs1200med", label = "Xe May", grade = 2, fee = 0},
            {name = "energyx7med", label = "Xe Quản Lý", grade = 5, fee = 0},
            {name = "citaroflg", label = "Xe BUS Bác sĩ", grade = 5, fee = 0, trailer = "trailerscitaroflg"},
            {name = "polpor", label = "Xe Cấp cao", grade = 7, fee = 0}
        }
    },
    ambulance_2 = {
        label = "🚑 Ambulance Garage",
        drawText = vec3(297.2003, -604.7017, 43.3153),
        spawnPoint = vec4(290.2450, -613.2732, 42.6423, 70.9054),
        vehicleType = "ground",
        vehicles = {
            {name = "energym3g80med", label = "Xe Cơ Bản", grade = 1, fee = 0},
            {name = "energyvanmed", label = "Xe Thực Tập Sinh", grade = 0, fee = 0},
            {name = "energygs1200med", label = "Xe May", grade = 2, fee = 0},
            {name = "energyx7med", label = "Xe Quản Lý", grade = 5, fee = 0},
            {name = "citaroflg", label = "Xe BUS Bác sĩ", grade = 5, fee = 0, trailer = "trailerscitaroflg"},
            {name = "polpor", label = "Xe Cấp cao", grade = 7, fee = 0}
        }
    },
    ambulance_3 = {
        label = "🚁 Ambulance Aircraft",
        drawText = vec3(1721.7, 3599.94, 35.21),
        spawnPoint = vec4(1713.26, 3595.61, 35.39, 292.67),
        vehicleType = "aircraft",
        vehicles = {
            {name = "energyhelimed", label = "Medical Helicopter", grade = 4, fee = 0},
            {name = "seasparrow", label = "Medical Plane", grade = 3, fee = 0}
        }
    },
    ambulance_aircraft = {
        label = "🚁 Ambulance Aircraft",
        drawText = vector3(336.7373, -1435.9943, 46.5092),
        spawnPoint = vector4(313.1942, -1465.4030, 47.1861, 138.8685),
        vehicleType = "aircraft",
        vehicles = {
            {name = "energyhelimed", label = "Medical Helicopter", grade = 4, fee = 0},
            {name = "seasparrow", label = "Medical Plane", grade = 3, fee = 0}
        }
    },
    ambulance_boat = {
        label = "🚤 Ambulance Boat - 288",
        drawText = vec3(1580.41, 3909.68, 31.28),
        spawnPoint = vec4(1585.14, 3920.82, 30.29, 2.65),
        vehicleType = "boat",
        vehicles = {
            {name = "dinghy4", label = "Thuyền Y Tế Cơ Bản", grade = 0, fee = 0}
        }
    },
    ambulance_boat_1 = {
        label = "🚤 Ambulance Boat - 712 ",
        drawText = vec3(-781.46, -1495.06, 1.49),
        spawnPoint = vec4(-789.19, -1499.24, 0.39, 113.4),
        vehicleType = "boat",
        vehicles = {
            {name = "dinghy4", label = "Thuyền Y Tế Cơ Bản", grade = 0, fee = 0}
        }
    },
    ambulance_boat_2 = {
        label = "🚤 Ambulance Boat - 787",
        drawText = vec3(1196.87, -2704.11, 1.06),
        spawnPoint = vec4(1199.34, -2715.4, 0.5, 181.99),
        vehicleType = "boat",
        vehicles = {
            {name = "dinghy4", label = "Thuyền Y Tế Cơ Bản", grade = 0, fee = 0}
        }
        
    },
    ambulance_boat_3 = {
        label = "🚤 Ambulance Boat - 440",
        drawText = vec3(-2854.92, -48.41, 2.45),
        spawnPoint = vec4(-2862.08, -59.63, 1.24, 162.45),
        vehicleType = "boat",
        vehicles = {
            {name = "dinghy4", label = "Thuyền Y Tế Cơ Bản", grade = 0, fee = 0}
        }
    },
    ambulance_boat_4 = {
        label = "🚤 Ambulance Boat - 067",
        drawText = vec3(920.39, 6633.9, 1.83),
        spawnPoint = vec4(918.12, 6650.0, 0.88, 7.21),
        vehicleType = "boat",
        vehicles = {
            {name = "dinghy4", label = "Thuyền Y Tế Cơ Bản", grade = 0, fee = 0}
        }
    },
    ambulance_boat_5 = {
        label = "🚤 Ambulance Boat - 199",
        drawText = vec3(-3136.79, 3417.25, 1.06),
        spawnPoint = vec4(-3146.39, 3423.63, 0.54, 58.3),
        vehicleType = "boat",
        vehicles = {
            {name = "dinghy4", label = "Thuyền Y Tế Cơ Bản", grade = 0, fee = 0}
        }
    },
    ambulance_boat_6 = {
        label = "🚤 Ambulance Boat - 686",
        drawText = vec3(-1798.67, -971.88, 2.5),
        spawnPoint = vec4(-1806.4, -987.31, 0.49, 125.41),
        vehicleType = "boat",
        vehicles = {
            {name = "dinghy4", label = "Thuyền Y Tế Cơ Bản", grade = 0, fee = 0}
        }
    },
    police = {
        label = "🚔 Police Garage - Trụ Sở Chính",
        drawText = vec3(97.2, -408.05, 39.13),
        spawnPoint = vec4(106.08, -416.25, 39.83, 253.02),
        vehicleType = "ground",
        vehicles = {
            {name = "nkfugitive", label = "Xe Cadet", grade = 1, fee = 0, defaultMods = {modLivery = 0}},
            {name = "bmwrp", label = "Xe giao thông", grade = 2, fee = 0},
            {name = "nkdoradoac", label = "Xe SUV", grade = 3, fee = 0, defaultMods = {modLivery = 0, modSpoilers = 1}},
            {name = "nkbuffalo4", label = "Xe Buffalo4", grade = 2, fee = 0, defaultMods = {modLivery = 0}},
            {name = "nkgtx", label = "Xe Dominator", grade = 5, fee = 0, defaultMods = {modLivery = 0}},
            {name = "nkvigero2", label = "Xe Vigero2", grade = 8, fee = 0, defaultMods = {modLivery = 0}},
            {name = "polcoq4", label = "Xe Coquette", grade = 11, fee = 0, defaultMods = {modLivery = 0}}
        }
    },
    police_5 = {
        label = "🚔 Police Garage - Trụ Sở Chính Bãi Sau",
        drawText = vec3(58.9448, -371.5129, 39.1266), --vector3(58.9448, -371.5129, 39.1266)
        spawnPoint = vec4(49.4768, -377.7080, 39.3857, 70.4777), --vector4(49.4768, -377.7080, 39.3857, 70.4777)
        vehicleType = "ground",
        vehicles = {
            {name = "hvbrickade2", label = "Xe Nước", grade = 4, fee = 0, defaultMods = {modLivery = 0}},
            {name = "hvriot2", label = "Xe Nước", grade = 4, fee = 0, defaultMods = {modLivery = 0}},
            {name = "hvswatsupport", label = "Xe Hỗ Trợ Khí Tài", grade = 4, fee = 0, defaultMods = {modLivery = 0}},
            {name = "hvswatgresly", label = "Xe SUV", grade = 4, fee = 0, defaultMods = {modLivery = 0}},
            {name = "hvswatspeedo", label = "Xe Speedo SWAT", grade = 7, fee = 0, defaultMods = {modLivery = 0}},
            {name = "pbus", label = "Xe Bus", grade = 4, fee = 0, defaultMods = {modLivery = 0}},
        }
    },
    police_2 = {
        label = "🚔 Police Garage - Sandy Shores",
        drawText = vec3(1829.28, 3671.9, 34.34),
        spawnPoint = vec4(1822.94, 3671.5, 33.59, 29.03),
        vehicleType = "ground",
        vehicles = {
            {name = "nkfugitive", label = "Xe Cadet", grade = 0, fee = 0, defaultMods = {modLivery = 0}},
            {name = "bmwrp", label = "Xe giao thông", grade = 1, fee = 0},
            {name = "nkdoradoac", label = "Xe SUV", grade = 2, fee = 0, defaultMods = {modLivery = 0, modSpoilers = 1}},
            {name = "nkbuffalo4", label = "Xe Buffalo4", grade = 1, fee = 0, defaultMods = {modLivery = 2}},
            {name = "nkgtx", label = "Xe Dominator", grade = 4, fee = 0, defaultMods = {modLivery = 0}},
            {name = "nkvigero2", label = "Xe Vigero2", grade = 7, fee = 0, defaultMods = {modLivery = 0}},
            {name = "polcoq4", label = "Xe Coquette", grade = 10, fee = 0, defaultMods = {modLivery = 0}}
        }
    },
     police_aircraft = {
        label = "🚁 Police Aircraft",
        drawText = vec3(86.22, -415.06, 55.33), --vec3(459.23, -977.24, 43.69)
        spawnPoint = vec4(86.4803, -404.1358, 55.0834, 252.2652), --vector4(86.4803, -404.1358, 55.0834, 252.2652)
        vehicleType = "aircraft",
        vehicles = {
            {name = "polmav", label = "Police Helicopter", grade = 4, fee = 0, defaultMods = {livery = 0}},
            {name = "hvannihilator", label = "Swat Helicopter", grade = 4, fee = 0},
            {name = "seasparrow", label = "Police Plane", grade = 4, fee = 0}
        }
    },
    police_3 = {
        label = "🚁 Police Aircraft 2",
        drawText = vec3(1830.8, 3683.69, 38.93), --vec3(459.23, -977.24, 43.69)
        spawnPoint = vec4(1833.43, 3669.18, 38.43, 208.07), --vec4(449.25, -981.41, 43.69, 179.62)
        vehicleType = "aircraft",
        vehicles = {
            {name = "polmav", label = "Police Helicopter", grade = 7, fee = 0}
        }
    },
    police_boat = {
        label = "🚤 Police Boat - 288",
        drawText = vec3(1580.41, 3909.68, 31.28),
        spawnPoint = vec4(1585.14, 3920.82, 30.29, 2.65),
        vehicleType = "boat",
        vehicles = {
            {name = "predator", label = "Thuyền Chiến Thuật", grade = 0, fee = 0}
        }
    },
    police_boat_1 = {
        label = "🚤 Police Boat - 712",
        drawText = vec3(-781.46, -1495.06, 1.49),
        spawnPoint = vec4(-789.19, -1499.24, 0.39, 113.4),
        vehicleType = "boat",
        vehicles = {
            {name = "predator", label = "Thuyền Chiến Thuật", grade = 0, fee = 0}
        }
    },
    police_boat_2 = {
        label = "🚤 Police Boat - 787",
        drawText = vec3(1196.87, -2704.11, 1.06),
        spawnPoint = vec4(1199.34, -2715.4, 0.5, 181.99),
        vehicleType = "boat",
        vehicles = {
            {name = "predator", label = "Thuyền Chiến Thuật", grade = 0, fee = 0}
        }
    },
    police_boat_3 = {
        label = "🚤 Police Boat - 440",
        drawText = vec3(-2854.92, -48.41, 2.45),
        spawnPoint = vec4(-2862.08, -59.63, 1.24, 162.45),
        vehicleType = "boat",
        vehicles = {
            {name = "predator", label = "Thuyền Chiến Thuật", grade = 0, fee = 0}
        }
    },
    police_boat_4 = {
        label = "🚤 Police Boat - 067",
        drawText = vec3(920.39, 6633.9, 1.83),
        spawnPoint = vec4(918.12, 6650.0, 0.88, 7.21),
        vehicleType = "boat",
        vehicles = {
            {name = "predator", label = "Thuyền Chiến Thuật", grade = 0, fee = 0}
        }
    },
    police_boat_5 = {
        label = "🚤 Police Boat - 199",
        drawText = vec3(-3136.79, 3417.25, 1.06),
        spawnPoint = vec4(-3146.39, 3423.63, 0.54, 58.3),
        vehicleType = "boat",
        vehicles = {
            {name = "predator", label = "Thuyền Chiến Thuật", grade = 0, fee = 0}
        }
    },

    toathichinh = {
        label = "🚔 Tòa thị chính",
        drawText = vector3(-1605.8499, -3137.3242, 13.944),
        spawnPoint = vector4(-1596.2505, -3122.0706, 13.1763, 331.6477),
        vehicleType = "ground",
        vehicles = {
            -- Cấp 0 - Thiếu úy
            {name = "onebeast", label = "Xe Tổng Thống", grade = 2, fee = 0},
            {name = "vclass", label = "Vinfast Lạc Hồng", grade = 2, fee = 0}
        }
    },

    toathichinh_1 = {
        label = "🚔 Tòa thị chính 2",
        drawText = vector3(-498.6363, -611.8672, 31.969),
        spawnPoint = vector4(-487.7005, -614.9850, 30.4065, 177.6176),
        vehicleType = "ground",
        vehicles = {
            -- Cấp 0 - Thiếu úy
            {name = "onebeast", label = "Xe Tổng Thống", grade = 2, fee = 0},
            {name = "vclass", label = "Vinfast Lạc Hồng", grade = 2, fee = 0}
        }
    },
   
    mechanic = {
        label = "🔧 Mechanic Garage",
        drawText = vector3(-365.0154, -113.6884, 38.6837), --31.7449, -1764.2417, 29.2915, 48.9877
        spawnPoint = vector4(-370.3463, -122.9407, 38.8039, 132.6219), --17.8252, -1767.8113, 29.3031, 319.9978
        vehicleType = "ground",
        vehicles = {
            {name = "mtlscv3", label = "Xe Đầu Kéo", grade = 0, fee = 1},
            {name = "tcaracaraptorv3", label = "Xe Dây Cáp", grade = 1, fee = 1,},
            {name = "r1250lfv3", label = "Xe Máy", grade = 2, fee = 1,},
            {name = "caracaraptorv3", label = "Xe Máy", grade = 3, fee = 1,}
        }
    },
    mechanic_aircraft = {
        label = "✈️ Mechanic Aircraft",
        drawText = vector3(-327.3967, -143.9047, 60.4663), --vector3(-327.3967, -143.9047, 60.4663)
        spawnPoint = vector4(-342.2985, -142.6998, 60.6088, 120.6951), --vector4(-342.2985, -142.6998, 60.6088, 120.6951)
        vehicleType = "aircraft",
        vehicles = {
            {name = "svolitov3", label = "Volito Helicopter", grade = 3, fee = 1}
        }
    }
}
-- Blip settings
Config.BlipSettings = {
    ambulance = {
        sprite = 100,    -- Blip 100
        color = 1,      -- Red
        scale = 0.1,
        name = "Ambulance Garage"
    },
    ambulance_2 = {
        sprite = 100,    -- Blip 100
        color = 1,      -- Red
        scale = 0.1,
        name = "Ambulance Garage"
    },
    ambulance_3 = {
        sprite = 43,    -- Blip 100
        color = 1,      -- Red
        scale = 0.1,
        name = "Ambulance Garage"
    },

    ambulance_aircraft = {
        sprite = 43,     -- Aircraft blip
        color = 1,      -- Red
        scale = 0.1,
        name = "Ambulance Aircraft"
    },
    ambulance_boat = {
        sprite = 427,    -- Marina/Boat blip
        color = 1,      -- Red
        scale = 0.8,
        name = "Ambulance Boat - Sandy Shores"
    },
    ambulance_boat_1 = {
        sprite = 427,    -- Marina/Boat blip
        color = 1,      -- Red
        scale = 0.8,
        name = "Ambulance Boat - Vespucci Beach"
    },
    ambulance_boat_2 = {
        sprite = 427,    -- Marina/Boat blip
        color = 1,      -- Red
        scale = 0.8,
        name = "Ambulance Boat - Vespucci Beach"
    },
    ambulance_boat_3 = {
        sprite = 427,    -- Marina/Boat blip
        color = 1,      -- Red
        scale = 0.8,
        name = "Ambulance Boat - 440"
    },
    ambulance_boat_4 = {
        sprite = 427,    -- Marina/Boat blip
        color = 1,      -- Red
        scale = 0.8,
        name = "Ambulance Boat - 067"
    },
    ambulance_boat_5 = {
        sprite = 427,    -- Marina/Boat blip
        color = 1,      -- Red
        scale = 0.8,
        name = "Ambulance Boat - 199"
    },
    ambulance_boat_6 = {
        sprite = 427,    -- Marina/Boat blip
        color = 1,      -- Red
        scale = 0.8,
        name = "Ambulance Boat - 686"
    },
    police = {
        sprite = 100,    -- Blip 100
        color = 3,      -- Blue
        scale = 0.1,
        name = "Police Garage - Trụ Sở Chính"
    },
    police_2 = {
        sprite = 100,    -- Blip 100
        color = 3,      -- Blue
        scale = 0.1,
        name = "Police Garage - Mission Row"
    },
    police_3 = {
        sprite = 100,    -- Blip 100
        color = 3,      -- Blue
        scale = 0.1,
        name = "Police Garage - Sandy Shores"
    },
    police_4 = {
        sprite = 100,    -- Blip 100
        color = 3,      -- Blue
        scale = 0.8,
        name = "Police Garage - Paleto Bay"
    },
    hocvien = {
        sprite = 100,    -- Blip 100
        color = 3,      -- Blue
        scale = 0.8,
        name = "Học Viện Garage"
    },
    police_aircraft = {
        sprite = 43,     -- Aircraft blip
        color = 3,      -- Blue
        scale = 0.1,
        name = "Police Aircraft"
    },
    police_boat = {
        sprite = 427,    -- Marina/Boat blip
        color = 3,      -- Blue
        scale = 0.8,
        name = "Police Boat - 288"
    },
    police_boat_1 = {
        sprite = 427,    -- Marina/Boat blip
        color = 3,      -- Blue
        scale = 0.8,
        name = "Police Boat - 712"
    },
    police_boat_2 = {
        sprite = 427,    -- Marina/Boat blip
        color = 3,      -- Blue
        scale = 0.8,
        name = "Police Boat - 787"
    },
    police_boat_3 = {
        sprite = 427,    -- Marina/Boat blip
        color = 3,      -- Blue
        scale = 0.8,
        name = "Police Boat - 440"
    },
    police_boat_4 = {
        sprite = 427,    -- Marina/Boat blip
        color = 3,      -- Blue
        scale = 0.8,
        name = "Police Boat - 067"
    },
    police_boat_5 = {
        sprite = 427,    -- Marina/Boat blip
        color = 3,      -- Blue
        scale = 0.8,
        name = "Police Boat - 199"
    },
    army = {
        sprite = 100,    -- Blip 100
        color = 17,     -- Army Green
        scale = 0.8,
        name = "Army Garage"
    },
    mechanic = {
        sprite = 100,    -- Blip 100
        color = 5,      -- Yellow
        scale = 0.8,
        name = "Mechanic Garage"
    },
    mechanic_aircraft = {
        sprite = 43,     -- Aircraft blip
        color = 5,      -- Yellow
        scale = 0.8,
        name = "Mechanic Aircraft"
    }
}

-- Notification settings
Config.Notifications = {
    spawnSuccess = {
        title = 'Garage Công Việc',
        description = 'Xe đã được mang đến!',
        type = 'success'
    },
    aircraftSpawnSuccess = {
        title = 'Garage Máy Bay',
        description = 'Máy bay đã được mang đến!',
        type = 'success'
    },
    boatSpawnSuccess = {
        title = 'Garage Thuyền',
        description = 'Thuyền đã được mang đến!',
        type = 'success'
    },
    aircraftSpawnError = {
        title = 'Garage Máy Bay',
        description = 'Hiện không thể lấy máy bay!',
        type = 'error'
    },
    boatSpawnError = {
        title = 'Garage Thuyền',
        description = 'Hiện không thể lấy thuyền!',
        type = 'error'
    },
    spawnError = {
        title = 'Garage Công Việc',
        description = 'Hiện không thể lấy xe!',
        type = 'error'
    },
    spawnBlocked = {
        title = 'Garage Công Việc',
        description = 'Vị trí lấy xe bị chặn! Có xe khác đang đỗ trong khu vực.',
        type = 'error'
    },
    vehicleDeleted = {
        title = 'Garage Công Việc',
        description = 'Xe đã được xóa thành công!',
        type = 'success'
    },
    noVehicleToDelete = {
        title = 'Garage Công Việc',
        description = 'Không tìm thấy xe để xóa!',
        type = 'error'
    },
    accessDenied = {
        title = 'Từ Chối Truy Cập',
        description = 'Bạn không có quyền sử dụng garage này!',
        type = 'error'
    },
    gradeRequired = {
        title = 'Cấp Bậc Không Đủ',
        description = 'Bạn cần cấp bậc cao hơn để sử dụng phương tiện này!',
        type = 'error'
    },
    insufficientFunds = {
        title = 'Không Đủ 💵',
        description = 'Bạn không có đủ 💵 để lấy xe này!',
        type = 'error'
    },
    feeCharged = {
        title = 'Phí Lấy Xe',
        description = 'Đã trừ phí lấy xe: $%s',
        type = 'inform'
    }
}

-- Vehicle settings
Config.VehicleSettings = {
    warpIntoVehicle = false,    -- Auto warp player into spawned vehicle
    engineOn = false,           -- Start engine automatically
    setAsOwned = true         -- Set vehicle as owned (if using vehicle ownership system)
}

-- Marker settings
Config.MarkerSettings = {
    type = 37,           -- Marker type (37 is a nice circle marker)
    size = {
        x = 2.0,
        y = 2.0,
        z = 1.5
    },
    colors = {
        accessible = {r = 0, g = 255, b = 0},      -- Green
        restricted = {r = 255, g = 0, b = 0},      -- Red
        default = {r = 255, g = 102, b = 0}        -- Orange
    },
    alpha = 100,         -- Transparency
    bobUpAndDown = true,
    faceCamera = true,
    p19 = 2,
    rotate = false
}
