Config.workshops = Config.workshops or {}

-- This config is made to work with the FM Shop Rusty Garage MLO
-- Check: https://fmshop.tebex.io/category/2175260

Config.workshops.rustygarage = {
    enabled = false,
    label = 'Rusty Garage',
    job = 'rustygarage',
    blip = { enabled = true, coords = vec3(754.0, -781.06, 26.37), color = 1, scale = 0.8, display = 4, sprite = 402 },
    zone = {
        points = {
            vec3(757.83, -796.48, 26.30),
            vec3(759.24, -763.03, 26.30),
            vec3(726.07, -764.95, 26.30),
            vec3(724.98, -797.14, 26.30)
        },
        thickness = 15
    },
    managements = {
        { coords = vec3(742.8, -790.5, 26.4), radius = 0.3 },
    },
    stashes = {
        { coords = vec3(733.75, -787.45, 27.0), radius = 1.0, slots = 50, weight = 100 },
    },
    crafts = {
        { coords = vec3(732.1, -781.1, 26.4), radius = 0.45, categories = { 'performance', 'others' } },
    },
    shops = {
        { coords = vec3(746.25, -792.25, 26.75), radius = 0.95, categories = { 'performance', 'others' } },
    },
    registers = {
        { coords = vec3(745.8, -788.1, 26.4), radius = 0.45, comission = 10, playersRadius = 5.0 },
    },
    mission = {
        { coords = vec3(728.45, -777.45, 29.3), radius = 0.2, minPayment = 100, maxPayment = 500, cooldown = 10 }
    },
    garage = {
        {
            coords = vec4(756.65, -766.36, 25.46, 185.46+180),
            spawnCoords = vec4(763.05, -774.22, 26.32, 177.79),
            vehicles = {
                { icon = 'fas fa-truck', label = 'Flatbed', id = 'flatbed' },
                { icon = 'fas fa-truck', label = 'Tow truck', id = 'towtruck' },
                { icon = 'fas fa-motorcycle', label = 'Xe lưu động', id = 'nudelbikemcn' },
            },
        },
    },
}