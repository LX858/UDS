Config.workshops = Config.workshops or {}

-- This config is made to work with the Kiiya's Tuner Shop MLO
-- Check: https://kiiya.tebex.io/package/5148409

Config.workshops.tunershop = {
    enabled = true,
    label = 'Độ xe',
    job = 'doxe',
    blip = { enabled = true, coords = vec3(-925.13, -776.67, 15.07), color = 4, scale = 0.9, display = 4, sprite = 72},
    zone = {
        points = {
            vec3(-187.1530, -1305.2799, 31.3534),
            vec3(-185.5630, -1345.4285, 31.1688),
            vec3(-246.8218, -1344.4800, 31.2465),
            vec3(-247.3060, -1309.6632, 31.2692)
        },
        thickness = 15
    },
    duty = {
        { coords = vec3(-206.28778076172,-1341.3953857422,35.314949035645), radius = 0.5 },
    },
    managements = {
        { coords = vec3(-941.88, -768.88, 15.0), radius = 0.5 },
    },
    stashes = {
        -- { coords = vec3(116.22, -1094.07, 29.4), radius = 0.9, slots = 25, weight = 100 },
    },
    crafts = {
        -- { coords = vec3(115.83, -1101.09, 29.19), radius = 0.6, categories = {'others'} },
    },
    shops = {
        -- { coords = vec3(735.75, -1266.3, 26.8), radius = 0.6, categories = { 'performance', 'others' } },
    },
    registers = {
        -- { coords = vec3(146.21, -1090.25, 29.41), radius = 0.3, comission = 10, playersRadius = 5.0 },
    },
    mission = {
        -- { coords = vec3(757.0, -1293.2, 26.1), radius = 0.2, prop = 'hei_prop_hei_bank_phone_01', propHeading = 139.31+180, minPayment = 100, maxPayment = 500, cooldown = 10 }
    },
    garage = {
        {
            coords = vec4(-352.53, -113.22, 37.7, 67.88+180.0),
            spawnCoords = vec4(726.33, -1290.74, 26.28, 89.37),
            vehicles = {
                { icon = 'fas fa-truck', label = 'Flatbed', id = 'flatbed' },
                { icon = 'fas fa-truck', label = 'Tow truck', id = 'towtruck' },
                { icon = 'fas fa-motorcycle', label = 'Xe lưu động', id = 'nudelbikemcn' },
            },
        },
    },
}