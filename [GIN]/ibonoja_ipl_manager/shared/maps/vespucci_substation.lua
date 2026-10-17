-- IBONOJA IPL Manager - Vespucci Substation Configuration

table.insert(Maps, {
    ResourceMapName = "ibonoja_vespuci_pd",
    ConfigName = "VespucciSubstation",
    Menu = {
        id = "ibonoja_ipl_manager_vespuci_substation",
        title = "Vespucci Substation",
        options = {
            {
                type = "scroll",
                label = "Central Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "central_blinds",
                configName = "CentralBlinds",
                propset = {
                    coords = vector3(-1488.976, -1020.387, 8.294),
                    milo = "ibonoja_vb_station_int_milo_",
                    pattern = "vespucci_central_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Closed", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Meeting Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "meeting_blinds",
                configName = "MeetingBlinds",
                propset = {
                    coords = vector3(-1488.976, -1020.387, 8.294),
                    milo = "ibonoja_vb_station_int_milo_",
                    pattern = "vespucci_meeting_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Closed", value = { id = 2 } }
                }
            }
        }
    }
})
