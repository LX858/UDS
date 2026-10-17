return {
    Locations = {
        {
            type = 'car',
            coords = vec3(-209.207, 6209.153, 31.490),
            blip = { id = 524, colour = 1, scale = 0.6 },
            spawns = {
                vec4(-207.559, 6219.600, 31.084, 223.938),
                vec4(-205.136, 6221.833, 31.079, 224.720),
                vec4(-202.652, 6223.741, 31.078, 225.072),
                vec4(-199.926, 6225.770, 30.995, 222.797)
            }
        },
        {
            type = 'car',
            coords = vec3(1707.95, 3757.6, 34.16),
            blip = { id = 524, colour = 1, scale = 0.6 },
            spawns = {
                vec4(1707.5, 3752.7, 34.09, 231.19),
                vec4(1704.62, 3749.86, 34.05, 230.04)
            }
        },
        {
            type = 'car',
            coords = vec3(617.96, 2724.41, 41.4),
            blip = { id = 524, colour = 1, scale = 0.6 },
            spawns = {
                vec4(611.97, 2724.08, 41.43, 5.74),
                vec4(624.2, 2725.45, 41.34, 4.15)
            }
        },
        {
            type = 'car',
            coords = vec3(146.48, -1070.45, 28.49),
            blip = { id = 524, colour = 1, scale = 0.6 },
            spawns = {
                vec4(162.4, -1081.2, 28.77, 0.96),
                vec4(158.2, -1081.9, 28.77, 0.74),
                vec4(154.7, -1081.4, 28.77, 358.95),
                vec4(150.8, -1081.2, 28.77, 359.85),
                vec4(147.1, -1081.4, 28.77, 1.86),
                vec4(143.5, -1081.2, 28.77, 0.84),
                vec4(139.8, -1081.6, 28.77, 2.05),
            }
        }
    },

    -- Name of the garage that police use to store impounded vehicles
    -- Vehicles stored in this garage (state=1) will appear as "Xe bị tạm giam"
    DepotGarageName = 'depot',

    -- Fee for retrieving a police-impounded vehicle
    DepotFee = 2000,

    -- Function to calculate impound fee - fixed at $2000
    calculateImpoundFee = function(vehicleId, modelName)
        return 1000  -- Fixed impound price
    end,

    ImpoundPrices = {
        [0] = 1000,     -- Compacts
        [1] = 1000,     -- Sedans
        [2] = 1000,     -- SUVs
        [3] = 1000,     -- Coupes
        [4] = 1000,     -- Muscle
        [5] = 1000,     -- Sports Classics
        [6] = 1000,     -- Sports
        [7] = 1000,     -- Super
        [8] = 1000,     -- Motorcycles
        [9] = 1000,     -- Off-road
        [10] = 1000,    -- Industrial
        [11] = 1000,    -- Utility
        [12] = 1000,    -- Vans
        [13] = 1000,    -- Cycles
        [14] = 1000,    -- Boats
        [15] = 1000,    -- Helicopters
        [16] = 1000,    -- Planes
        [17] = 1000,    -- Service
        [18] = 1000,    -- Emergency
        [19] = 1000,    -- Military
        [20] = 1000,    -- Commercial
        [21] = 1000     -- Trains
    }
}