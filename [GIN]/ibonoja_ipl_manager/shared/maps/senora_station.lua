-- IBONOJA IPL Manager - Senora Sheriff Station Configuration

table.insert(Maps, {
    ResourceMapName = "ibonoja_senora_sheriff_station",
    ConfigName = "SenoraStation",
    Menu = {
        id = "ibonoja_ipl_manager_senora",
        title = "Senora Sheriff Station",
        options = {
            {
                type = "scroll",
                label = "Briefing Room",
                icon = "fa-solid fa-chalkboard-user",
                statebag = "briefing_room",
                configName = "BriefingRoom",
                propset = {
                    coords = vector3(2810.473, 4731.34, 51.441),
                    milo = "ibonoja_senora_sheriff_interior_milo_",
                    pattern = "senora_briefing_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Pattern 1", value = { id = 1 } },
                    { label = "Pattern 2", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Extra Room",
                icon = "fa-solid fa-door-open",
                statebag = "extra_room",
                configName = "ExtraRoom",
                propset = {
                    coords = vector3(2810.473, 4731.34, 51.441),
                    milo = "ibonoja_senora_sheriff_interior_milo_",
                    pattern = "senora_extra_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Pattern 1", value = { id = 1 } },
                    { label = "Pattern 2", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Detective Room Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "detective_room_blinds",
                configName = "DetectiveRoomBlinds",
                propset = {
                    coords = vector3(2810.473, 4731.34, 51.441),
                    milo = "ibonoja_senora_sheriff_interior_milo_",
                    pattern = "senora_detective_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Closed", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Wall Logos",
                icon = "fa-solid fa-image",
                statebag = "wall_logos",
                configName = "WallLogos",
                propset = {
                    coords = vector3(2810.473, 4731.34, 51.441),
                    milo = "ibonoja_senora_sheriff_interior_milo_",
                    pattern = "senora_logos_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Wrap", value = { id = 1 } },
                    { label = "Normal", value = { id = 2 } }
                }
            }
        }
    }
})
