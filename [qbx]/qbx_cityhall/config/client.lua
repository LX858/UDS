return {
    useTarget = true,
    debugPoly = false,
    spawnPeds = false, -- Set to false to disable spawning peds

    peds = {
        { -- Cityhall Ped
            model = 'a_m_m_hasjew_01',
            coords = vec4(62.0, -428.32, 38.2, 240.18),
            scenario = 'WORLD_HUMAN_STAND_MOBILE',
            enabled = true,
            cityhall = false,
            zoneOptions = { -- Used for when UseTarget is false
                length = 10.0,
                width = 10.0,
                debugPoly = false,
            },
        },
    },
}