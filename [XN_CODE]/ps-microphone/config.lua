Config = {}

Config.Showzone = true

Config.MicrophoneZones = {
    [1] = {
        name = "vinewood_bowl", 
        coords = vector3(683.37, 569.31, 130.46),
        length = 3.4,
        width = 3.6,
        spawnProp = true, -- if set to true, it will let you spawn the prop at location
        data = {
            debugPoly = Config.Showzone,
            heading = 340,
            minZ = 127.86,
            maxZ = 131.86,
            data = {
                range = 50.0 -- range for the voice
            }
        }
    },

    [2] = {
        name = "hociven", 
        coords = vector3(2497.9719, -320.6680, 98.6852), --vector3(2497.9719, -320.6680, 98.6852)
        length = 3.4,
        width = 3.6,
        spawnProp = true, -- if set to true, it will let you spawn the prop at location
        data = {
            debugPoly = Config.Showzone,
            heading = 0.0, -- Adjust this angle (0-360) to rotate the box if needed
            minZ = 20.49,  -- Ground level (22.49) minus 2.0
            maxZ = 24.99,  -- Ground level (22.49) plus 2.5
            data = {
                range = 50.0 -- range for the voice
            }
        }
    },
}
