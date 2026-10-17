-- IBONOJA IPL Manager - Paleto Sheriff Substation Configuration

table.insert(Maps, {
    ResourceMapName = "ibonoja_paleto_sheriff_substation",
    ConfigName = "PaletoSubstation",
    Menu = {
        id = "ibonoja_ipl_manager_paleto_substation",
        title = "Paleto Sheriff Substation",
        options = {
            {
                type = "scroll",
                label = "Briefing Room",
                icon = "fa-solid fa-chalkboard-user",
                statebag = "briefing_room",
                configName = "BriefingRoom",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_briefing_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Pattern 1", value = { id = 1 } },
                    { label = "Pattern 2", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Briefing Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "briefing_blinds",
                configName = "BriefingBlinds",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_briefingblids_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Middle", value = { id = 2 } },
                    { label = "Closed", value = { id = 3 } }
                }
            },
            {
                type = "scroll",
                label = "Reception Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "reception_blinds",
                configName = "ReceptionBlinds",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_receptionblids_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Middle", value = { id = 2 } },
                    { label = "Closed", value = { id = 3 } }
                }
            },
            {
                type = "scroll",
                label = "Central Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "central_blinds",
                configName = "CentralBlinds",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_centralblids_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Middle", value = { id = 2 } },
                    { label = "Closed", value = { id = 3 } }
                }
            },
            {
                type = "scroll",
                label = "Chief Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "chief_blinds",
                configName = "ChiefBlinds",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_chiefblids_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Middle", value = { id = 2 } },
                    { label = "Closed", value = { id = 3 } }
                }
            },
            {
                type = "scroll",
                label = "Meeting Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "meeting_blinds",
                configName = "MeetingBlinds",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_meetingblids_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Middle", value = { id = 2 } },
                    { label = "Closed", value = { id = 3 } }
                }
            },
            {
                type = "scroll",
                label = "Armory Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "armory_blinds",
                configName = "ArmoryBlinds",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_armoryblids_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Middle", value = { id = 2 } },
                    { label = "Closed", value = { id = 3 } }
                }
            },
            {
                type = "scroll",
                label = "Locker Blinds",
                icon = "fa-solid fa-eye-slash",
                statebag = "locker_blinds",
                configName = "LockerBlinds",
                propset = {
                    coords = vector3(-444.65, 6003.49, 35.605),
                    milo = "ibonoja_paleto_sub_station_interior_milo_",
                    pattern = "paleto_lockaerblids_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Middle", value = { id = 2 } },
                    { label = "Closed", value = { id = 3 } }
                }
            }
        }
    }
})
