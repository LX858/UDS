-- IBONOJA IPL Manager - MRPD Map Configuration

table.insert(Maps, {
    ResourceMapName = {
        "ibonoja_mrpd_full_editable",
        "ibonoja_mrpd"
    },
    ConfigName = "MRPD",
    Menu = {
        id = "ibonoja_ipl_manager_mrpd",
        title = "Mission Row PD",
        options = {
            {
                type = "checkbox",
                label = "Toilets",
                icon = "fa-solid fa-toilet",
                statebag = "toilets",
                configName = "Toilets",
                propset = {
                    coords = vector3(457.204, -996.1261, 36.0902),
                    milo = "interior_MRPD_milo_",
                    pattern = "mrpd_toilet_001"
                }
            }
        }
    }
})
