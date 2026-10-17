Config.workshops = Config.workshops or {}

-- This config is made to work with the Kiiya's Los Santos Customs MLO
-- Check: https://kiiya.tebex.io/package/6126959

Config.workshops.mechanic = {
    enabled = true,
    label = 'mechanic',
    job = 'mechanic',
    blip = { enabled = false, coords = vec3(-359.23425292969,-102.63874053955,38.640464782715), color = 3, scale = 1.0, display = 4, sprite = 402 },
    zone = {
        points = {
           vec3(-310.0, -85.0, 38.0),
           vec3(-305.0, -155.0, 38.0),
           vec3(-375.0, -155.0, 38.0),
           vec3(-385.0, -85.0, 38.0)
        },
        thickness = 25
    },
    repairBays = {
        { coords = vec4(-327.1214, -144.2768, 38.2475, 247.7211), radius = 3.0 },
        { coords = vec4(-324.7670, -139.3382, 38.2469, 250.5071), radius = 3.0 },
        { coords = vec4(-323.2890, -134.0577, 38.2478, 250.2346), radius = 3.0 },
        { coords = vec4(-321.2361, -128.5794, 38.2481, 249.3782), radius = 3.0 },
        { coords = vec4(-319.0915, -123.6971, 38.2479, 249.2198), radius = 3.0 },
        { coords = vec4(-317.5959, -118.3321, 38.2480, 249.9398), radius = 3.0 },
        { coords = vec4(-315.2866, -113.5386, 38.2479, 250.5739), radius = 3.0 },  
        { coords = vec4(-314.0433, -108.1751, 38.2478, 251.7126), radius = 3.0 },
        { coords = vec4(-312.5620, -102.5207, 38.2480, 248.7636), radius = 3.0 },
    },
    managements = {
        -- { coords = vec3(-325.2, -130.6, 43.8), radius = 0.45 },
    },
    stashes = {
        -- { coords = vec3(-332.3, -134.8, 39.1), radius = 0.45, slots = 50, weight = 100 },
    },
    crafts = {
        -- { coords = vec3(-331.5, -131.15, 39.0), radius = 0.45, categories = { 'performance', 'others' } },
    },
    shops = {
        -- { coords = vec3(-347.67, -134.23, 39.01), radius = 0.3, categories = { 'performance', 'others' } },
    },
    registers = {
        -- { coords = vec3(-350.6, -138.95, 39.45), radius = 0.3, comission = 10, playersRadius = 5.0 },
    },
    mission = {
        -- { coords = vec3(-323.4, -128.95, 39.25), radius = 0.2, minPayment = 100, maxPayment = 500, cooldown = 10 }
    },
    garage = {
        -- {
        --     coords = vec4(87.5503, -1749.4972, 29.2915, 318.3306),
        --     spawnCoords = vec4(95.8149, -1746.6875, 29.3791, 321.4781),
        --     vehicles = {
        --         { icon = 'fas fa-truck', label = 'Flatbed', id = 'flatbed' },
        --         { icon = 'fas fa-truck', label = 'Tow truck', id = 'towtruck' },
        --     },
        -- },
    },
}