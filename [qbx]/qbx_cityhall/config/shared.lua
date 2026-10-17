return {
    cityhalls = {
        {
            coords = vec3(443.1, -990.99, 30.25), --vec3(439.7, -985.5, 30.24)
            showBlip = false,
            blip = {
                label = 'City Services',
                shortRange = true,
                sprite = 487,
                display = 4,
                scale = 0.65,
                colour = 0,
            },
            licenses = {
                -- ['id'] = {
                --     item = 'id_card',
                --     label = 'ID',
                --     cost = 50,
                -- },
                -- ['weapon'] = {
                --     item = 'weaponlicense',
                --     label = 'Weapon License',
                --     cost = 50,
                -- },
            },
        },
    },

    employment = {
        enabled = false, -- Set to false to disable the employment menu
        jobs = {
            unemployed = 'Unemployed',
            trucker = 'Trucker',
            taxi = 'Taxi',
            tow = 'Tow Truck',
            reporter = 'News Reporter',
            garbage = 'Garbage Collector',
            bus = 'Bus Driver',
        },
    },
}
