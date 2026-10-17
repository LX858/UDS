-- IBONOJA IPL Manager - Davis Fire Station Configuration

table.insert(Maps, {
    ResourceMapName = "ibonoja_davis_fire_station",
    ConfigName = "DavisFireStation",
    Menu = {
        id = "ibonoja_ipl_manager_davis_fire",
        title = "Davis Fire Station",
        options = {
            {
                type = "scroll",
                label = "Truck Bay",
                icon = "fa-solid fa-truck",
                statebag = "truck_bay",
                configName = "TruckBay",
                colorReference = "TruckBayColor",
                propset = {
                    coords = vector3(196.123, -1650.152, 34.341),
                    milo = "ibonoja_fire_davis_interior_milo_",
                    pattern = "davisfire_truckbay_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Pattern 1", value = { id = 1 } },
                    { label = "Pattern 2", value = { id = 2 } },
                    { label = "Pattern 3", value = { id = 3 } },
                    { label = "Pattern 4", value = { id = 4 } }
                }
            },
            {
                type = "scroll",
                label = "Truck Bay Color",
                icon = "fa-solid fa-palette",
                statebag = "truck_bay_color",
                configName = "TruckBayColor",
                idReference = "TruckBay",
                propset = {
                    coords = vector3(196.123, -1650.152, 34.341),
                    milo = "ibonoja_fire_davis_interior_milo_",
                    pattern = "davisfire_truckbay_%03d"
                },
                values = {
                    { label = "Color 1", value = { id = "TruckBay", color = 1 } },
                    { label = "Color 2", value = { id = "TruckBay", color = 2 } },
                    { label = "Color 3", value = { id = "TruckBay", color = 3 } },
                    { label = "Color 4", value = { id = "TruckBay", color = 4 } },
                    { label = "Color 5", value = { id = "TruckBay", color = 5 } },
                    { label = "Color 6", value = { id = "TruckBay", color = 6 } },
                    { label = "Color 7", value = { id = "TruckBay", color = 7 } },
                    { label = "Color 8", value = { id = "TruckBay", color = 8 } },
                    { label = "Color 9", value = { id = "TruckBay", color = 9 } }
                }
            },
            {
                type = "scroll",
                label = "Lights",
                icon = "fa-solid fa-lightbulb",
                statebag = "lights",
                configName = "Lights",
                propset = {
                    coords = vector3(196.123, -1650.152, 34.341),
                    milo = "ibonoja_fire_davis_interior_milo_",
                    pattern = "davisfire_lights_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Turned On", value = { id = 1 } },
                    { label = "Turned Off", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Dispatch Blinds",
                icon = "fa-solid fa-microphone",
                statebag = "dispatch_blinds",
                configName = "DispatchBlinds",
                propset = {
                    coords = vector3(196.123, -1650.152, 34.341),
                    milo = "ibonoja_fire_davis_interior_milo_",
                    pattern = "davisfire_dispatch_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Closed", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Meeting Room Blinds",
                icon = "fa-solid fa-people-arrows",
                statebag = "meeting_room_blinds",
                configName = "MeetingBlinds",
                propset = {
                    coords = vector3(196.123, -1650.152, 34.341),
                    milo = "ibonoja_fire_davis_interior_milo_",
                    pattern = "davisfire_meeting_%03d"
                },
                values = {
                    { label = "Off" },
                    { label = "Open", value = { id = 1 } },
                    { label = "Closed", value = { id = 2 } }
                }
            },
            {
                type = "scroll",
                label = "Living Room Blinds",
                icon = "fa-solid fa-bed",
                statebag = "living_room_blinds",
                configName = "LivingBlinds",
                propset = {
                    coords = vector3(196.123, -1650.152, 34.341),
                    milo = "ibonoja_fire_davis_interior_milo_",
                    pattern = "davisfire_room_%03d"
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
