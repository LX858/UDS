-- IBONOJA IPL Manager - LEO Training Center Configuration
-- Defines all configurable options for the LEO Training Center map

local leoTrainingConfig = {
    ResourceMapName = "ibonoja_sa_training_center",
    ConfigName = "LEOTrainingCenter",
    Menu = {
        id = "ibonoja_ipl_manager_leo_training_center",
        title = "LEO Training Center",
        options = {
            {
                type = "scroll",
                label = "Hangar Kill House",
                icon = "fa-solid fa-biohazard",
                statebag = "killhouse",
                configName = "HangarKillHouse",
                propset = {
                    milo = "ibonoja_leo_hangar_kill_int_milo_",
                    coords = vector3(2515.977, -460.42, 96.603),
                    pattern = "leohangar_kilhouse_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Pattern 1", value = {id = 1, color = 1}},
                    {label = "Pattern 2", value = {id = 2, color = 1}},
                    {label = "Pattern 3", value = {id = 3, color = 1}}
                }
            },
            {
                type = "scroll",
                label = "Hangar Helicopter Floor",
                icon = "fa-solid fa-helicopter",
                statebag = "hangar_helicopter",
                configName = "HangarHelicopter",
                colorReference = "HangarHelicopterColor",
                propset = {
                    milo = "ibonoja_leo_hangar_heli_int_milo_",
                    coords = vector3(2485.404, -447.428, 96.236),
                    pattern = "leoheli_floor_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Pattern 1", value = {id = 1}},
                    {label = "Pattern 2", value = {id = 2}},
                    {label = "Pattern 3", value = {id = 3}},
                    {label = "Pattern 4", value = {id = 4}}
                }
            },
            {
                type = "scroll",
                label = "Hangar Helicopter Color",
                icon = "fa-solid fa-palette",
                statebag = "hangar_helicopter_color",
                configName = "HangarHelicopterColor",
                idReference = "HangarHelicopter",
                propset = {
                    milo = "ibonoja_leo_hangar_heli_int_milo_",
                    coords = vector3(2485.404, -447.428, 96.236),
                    pattern = "leoheli_floor_%03d"
                },
                values = {
                    {label = "Color 1", value = {id = "HangarHelicopter", color = 1}},
                    {label = "Color 2", value = {id = "HangarHelicopter", color = 2}},
                    {label = "Color 3", value = {id = "HangarHelicopter", color = 3}},
                    {label = "Color 4", value = {id = "HangarHelicopter", color = 4}},
                    {label = "Color 5", value = {id = "HangarHelicopter", color = 5}},
                    {label = "Color 6", value = {id = "HangarHelicopter", color = 6}},
                    {label = "Color 7", value = {id = "HangarHelicopter", color = 7}},
                    {label = "Color 8", value = {id = "HangarHelicopter", color = 8}},
                    {label = "Color 9", value = {id = "HangarHelicopter", color = 9}}
                }
            },
            {
                type = "scroll",
                label = "Briefing Room",
                icon = "fa-solid fa-chalkboard-user",
                statebag = "briefing_room",
                configName = "BriefingRoom",
                propset = {
                    milo = "ibonoja_leo_interior_milo_",
                    coords = vector3(2521.879, -293.299, 99.151),
                    pattern = "leocentral_briefing_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 1}},
                    {label = "Level 2", value = {id = 2, color = 1}},
                    {label = "Level 3", value = {id = 3, color = 1}}
                }
            },
            {
                type = "scroll",
                label = "Paleto Room",
                icon = "fa-solid fa-tree",
                statebag = "paleto_room",
                configName = "PaletoRoom",
                propset = {
                    milo = "ibonoja_leo_interior_milo_",
                    coords = vector3(2521.879, -293.299, 99.151),
                    pattern = "leocentral_paleto_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 1}},
                    {label = "Level 2", value = {id = 2, color = 1}}
                }
            },
            {
                type = "scroll",
                label = "Great Ocean Room",
                icon = "fa-solid fa-water",
                statebag = "great_ocean_room",
                configName = "GreatOceanRoom",
                propset = {
                    milo = "ibonoja_leo_interior_milo_",
                    coords = vector3(2521.879, -293.299, 99.151),
                    pattern = "leocentral_greatocean_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 1}},
                    {label = "Level 2", value = {id = 2, color = 1}}
                }
            },
            {
                type = "scroll",
                label = "Sandy Room",
                icon = "fa-solid fa-water",
                statebag = "sandy_room",
                configName = "SandyRoom",
                propset = {
                    milo = "ibonoja_leo_interior_milo_",
                    coords = vector3(2521.879, -293.299, 99.151),
                    pattern = "leocentral_sandy_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 1}},
                    {label = "Level 2", value = {id = 2, color = 2}}
                }
            },
            {
                type = "scroll",
                label = "Mission Row Room",
                icon = "fa-solid fa-building-shield",
                statebag = "mrpd_room",
                configName = "MissionRowRoom",
                propset = {
                    milo = "ibonoja_leo_interior_milo_",
                    coords = vector3(2521.879, -293.299, 99.151),
                    pattern = "leocentral_mrpd_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 2}},
                    {label = "Level 2", value = {id = 2, color = 2}}
                }
            },
            {
                type = "scroll",
                label = "Senora Room",
                icon = "fa-solid fa-mountain-sun",
                statebag = "senora_room",
                configName = "SenoraRoom",
                propset = {
                    milo = "ibonoja_leo_interior_milo_",
                    coords = vector3(2521.879, -293.299, 99.151),
                    pattern = "leocentral_senora_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 2}},
                    {label = "Level 2", value = {id = 2, color = 2}}
                }
            },
            {
                type = "scroll",
                label = "Vespucci Room",
                icon = "fa-solid fa-umbrella-beach",
                statebag = "vespucci_room",
                configName = "VespucciRoom",
                propset = {
                    milo = "ibonoja_leo_training_02_milo_",
                    coords = vector3(2521.879, -293.299, 98.151),
                    pattern = "leocentral_vespucci_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 1}},
                    {label = "Level 2", value = {id = 2, color = 1}}
                }
            },
            {
                type = "scroll",
                label = "Vinewood Room",
                icon = "fa-solid fa-film",
                statebag = "vinewood_room",
                configName = "VinewoodRoom",
                propset = {
                    milo = "ibonoja_leo_training_02_milo_",
                    coords = vector3(2521.879, -293.299, 98.151),
                    pattern = "leocentral_vinewood_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 3}},
                    {label = "Level 2", value = {id = 2, color = 3}}
                }
            },
            {
                type = "scroll",
                label = "Under Left Section",
                icon = "fa-solid fa-shield-halved",
                statebag = "under_left_section",
                configName = "UnderLeftSection",
                propset = {
                    milo = "ibonoja_leo_galeria_tiro_int_milo_",
                    coords = vector3(2463.174, -386.264, 90.992),
                    pattern = "leogaleria_izda_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 1}},
                    {label = "Level 2", value = {id = 2, color = 1}}
                }
            },
            {
                type = "checkbox",
                label = "Under Left Section Targets",
                icon = "fa-solid fa-flag-checkered",
                statebag = "under_left_section_targets",
                configName = "UnderLeftSectionTargets",
                propset = {
                    milo = "ibonoja_leo_galeria_tiro_int_milo_",
                    coords = vector3(2463.174, -386.264, 90.992),
                    pattern = "leogaleria_izdatarget_001"
                }
            },
            {
                type = "scroll",
                label = "Under Right Section",
                icon = "fa-solid fa-shield-halved",
                statebag = "under_right_section",
                configName = "UnderRightSection",
                propset = {
                    milo = "ibonoja_leo_galeria_tiro_int_milo_",
                    coords = vector3(2463.174, -386.264, 90.992),
                    pattern = "leogaleria_dcha_%03d"
                },
                values = {
                    {label = "Off"},
                    {label = "Level 1", value = {id = 1, color = 1}},
                    {label = "Level 2", value = {id = 2, color = 1}}
                }
            },
            {
                type = "checkbox",
                label = "Under Right Section Targets",
                icon = "fa-solid fa-flag-checkered",
                statebag = "under_right_section_targets",
                configName = "UnderRightSectionTargets",
                propset = {
                    milo = "ibonoja_leo_galeria_tiro_int_milo_",
                    coords = vector3(2463.174, -386.264, 90.992),
                    pattern = "leogaleria_dchatarget_001"
                }
            },
            {
                type = "scroll",
                label = "Circuit",
                icon = "fa-solid fa-route",
                statebag = "circuit",
                configName = "Circuit",
                ymap = {
                    pattern = "ibonoja_evoc_config_%d"
                },
                values = {
                    {label = "Off"},
                    {label = "Pattern 1", value = {id = 1}},
                    {label = "Pattern 2", value = {id = 2}},
                    {label = "Pattern 3", value = {id = 3}}
                }
            },
            {
                type = "checkbox",
                label = "Car Generator",
                icon = "fa-solid fa-car",
                statebag = "car_generator",
                configName = "CarGenerator",
                ymap = {
                    name = "ibonoja_leo_car_gen"
                }
            },
            {
                type = "checkbox",
                label = "Perimetral Fence",
                icon = "fa-solid fa-xmarks-lines",
                statebag = "perimetral_fence",
                configName = "PerimetralFence",
                ymap = {
                    name = "ibonoja_leo_fence"
                }
            }
        }
    }
}

Maps[#Maps + 1] = leoTrainingConfig
