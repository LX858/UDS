Config.workshops = Config.workshops or {}

-- This config is made to work with the Kiiya's LS Auto Shop MLO
-- Check: https://kiiya.tebex.io/package/5845981

Config.workshops.autoshop = {
    enabled = false,
    label = 'Autoshop',
    job = 'autoshop',
    blip = { enabled = true, coords = vec3(1144.52, -773.53, 57.65), color = 6, scale = 0.8, display = 4, sprite = 402 },
    zone = {
        points = {
            vec3(1171.5, -765.25, 57.40),
            vec3(1165.41, -804.57, 57.40),
            vec3(1116.92, -804.56, 57.40),
            vec3(1116.7, -765.53, 57.40)
        },
        thickness = 15
    },
    managements = {
        { coords = vec3(1153.5, -792.25, 57.5), radius = 0.3 },
    },
    stashes = {
        { coords = vec3(1149.1, -789.65, 57.7), radius = 0.45, slots = 50, weight = 100 },
    },
    crafts = {
        { coords = vec3(1150.9, -789.1, 57.8), radius = 0.45, categories = { 'performance', 'others' } },
    },
    shops = {
        { coords = vec3(1135.7, -782.05, 57.6), radius = 0.3, categories = { 'performance', 'others' } },
    },
    registers = {
        { coords = vec3(1135.25, -782.1, 57.65), radius = 0.3, comission = 10, playersRadius = 5.0 },
    },
    mission = {
        { coords = vec3(1137.2, -782.1, 57.5), radius = 0.2, prop = 'hei_prop_hei_bank_phone_01', propHeading = 139.31+180, minPayment = 100, maxPayment = 500, cooldown = 10 }
    },
    garage = {
        {
            coords = vec4(1155.0, -774.86, 56.62, 357.97+180),
            spawnCoords = vec4(1155.4, -767.75, 57.48, 357.44),
            vehicles = {
                { icon = 'fas fa-truck', label = 'Flatbed', id = 'flatbed' },
                { icon = 'fas fa-truck', label = 'Tow truck', id = 'towtruck' },
                { icon = 'fas fa-motorcycle', label = 'Xe lưu động', id = 'nudelbikemcn' },
            },
        },
    },
}