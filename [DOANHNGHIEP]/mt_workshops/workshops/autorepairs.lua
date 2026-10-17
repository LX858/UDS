Config.workshops = Config.workshops or {}

-- This config is made to work with the Kiiya's Auto Repairs MLO
-- Check: https://kiiya.tebex.io/package/6629013

Config.workshops.autorepairs = {
    enabled = false,
    label = 'Auto Repairs',
    job = 'autorepairs',
    blip = { enabled = true, coords = vec3(76.5559, -1778.4872, 29.2913), color = 6, scale = 0.8, display = 4, sprite = 402 },
    zone = {
        points = {
            vec3(148.88157653809,-1780.4483642578,28.244287490845),
            vec3(97.46118927002,-1842.9489746094,24.240501403809),
            vec3(20.553804397583,-1779.2774658203,28.291509628296),
            vec3(67.538925170898,-1723.2067871094,28.291509628296),
        },
        thickness = 15
    },
    managements = {
        -- { coords = vec3(1165.55, 2649.95, 37.85), radius = 0.25 },
    },
    stashes = {
        -- { coords = vec3(1175.2, 2635.4, 37.8), radius = 0.8, slots = 50, weight = 100 },
    },
    crafts = {
        -- { coords = vec3(1178.15, 2635.35, 37.95), radius = 0.4, categories = { 'performance', 'others' } },
    },
    registers = {
        -- { coords = vec3(1165.7, 2649.2, 37.9), radius = 0.25, comission = 10, playersRadius = 5.0 },
    },
    mission = {
        -- { coords = vec3(1165.65, 2650.4, 37.85), radius = 0.25, prop = 'hei_prop_hei_bank_phone_01', propHeading = 139.31+180, minPayment = 100, maxPayment = 500, cooldown = 10 }
    },
    garage = {
        {
            coords = vec4(-352.53, -113.22, 38.7, 67.88),
            spawnCoords = vec4(1173.56, 2663.89, 37.84, 358.05),
            vehicles = {
                { icon = 'fas fa-truck', label = 'Flatbed', id = 'flatbed' },
                { icon = 'fas fa-truck', label = 'Tow truck', id = 'towtruck' },
                { icon = 'fas fa-motorcycle', label = 'Xe lưu động', id = 'nudelbikemcn' },
            },
        },
    },
}