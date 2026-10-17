Config.Food = {

    ciga_hp = {
        name = "Thuốc Lá",
        effect = "stress",
        amount = 30,
        prop = {
            model = `ba_prop_battle_vape_01`,
            bone = 57005,
            pos = vec3(-0.0290, 0.0070, -0.0050),
            rot = vec3(91.0, 270.0, -360.0),
        },
        anim = {
            dict = 'amb@world_human_smoking@male@male_b@base',
            clip = 'base',
        },
    },

    devkit_applesauce = {
        name = "Apple Sauce",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_applesauce`,
                pos = vec3(0.02, -0.00, 0.01),
                rot = vec3(-11.68, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_bananasundae = {
        name = "Banana Sundae",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_bananasundae`,
                pos = vec3(0.05, 0.02, 0.01),
                rot = vec3(-13.03, -0.70, -14.84),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_bcwaffle = {
        name = "BC Waffle",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_bcwaffle`,
                pos = vec3(0.03, 0.03, 0.02),
                rot = vec3(-13.34, 1.78, 28.00),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_brownie = {
        name = "Brownie",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_brownie`,
                pos = vec3(0.06, 0.02, 0.01),
                rot = vec3(-13.16, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_burritobox = {
        name = "Burrito Box",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_burritobox`,
                pos = vec3(0.07, 0.07, 0.02),
                rot = vec3(-0.88, 3.37, -17.44),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_buttericebowl = {
        name = "Butter Rice Bowl",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_buttericebowl`,
                pos = vec3(0.0700, 0.00, 0.0),
                rot = vec3(0.0, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_cheesepestopizza = {
        name = "Mini Cheese Pesto Pizza",
        effect = "hunger",
        amount = 35,
        prop = {
            {
                model = `devkit_cheesepestopizza`,
                pos = vec3(0.0700, 0.00, 0.0),
                rot = vec3(0.0, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_cinnaroll = {
        name = "Cinnamon Roll",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_cinnaroll`,
                pos = vec3(0.05, 0.01, 0.02),
                rot = vec3(0.0, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_cornbread = {
        name = "Cornbread",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_cornbread`,
                pos = vec3(0.06, 0.00, 0.01),
                rot = vec3(-12.38, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_friedchicken = {
        name = "Fried Chicken Plate",
        effect = "hunger",
        amount = 35,
        prop = {
            {
                model = `devkit_friedchicken`,
                pos = vec3(0.04, 0.04, 0.01),
                rot = vec3(-12.36, -2.62, -4.54),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_fruitplate = {
        name = "Fruit Plate",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_fruitplate`,
                pos = vec3(0.03, 0.03, 0.01),
                rot = vec3(-11.08, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_lavacake = {
        name = "Lava Cake",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_lavacake`,
                pos = vec3(0.05, 0.05, 0.02),
                rot = vec3(5.82, -4.75, 121.05),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_minichickenplate = {
        name = "Mini Chicken Plate",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_minichickenplate`,
                pos = vec3(0.08, 0.03, 0.01),
                rot = vec3(-9.31, 3.97, 33.30),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_nycsteak = {
        name = "NYC Steak",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_nycsteak`,
                pos = vec3(0.08, 0.03, 0.01),
                rot = vec3(0.28, 1.72, 79.84),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_onionrings = {
        name = "Onion Rings",
        effect = "hunger",
        amount = 35,
        prop = {
            {
                model = `devkit_onionrings`,
                pos = vec3(0.04, 0.04, 0.01),
                rot = vec3(-12.36, -2.62, -4.54),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_stickybbq = {
        name = "Sticky BBQ Plate",
        effect = "hunger",
        amount = 35,
        prop = {
            {
                model = `devkit_stickybbq`,
                pos = vec3(0.04, 0.04, 0.01),
                rot = vec3(-12.36, -2.62, -4.54),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_strawberrybowl = {
        name = "Strawberry Bowl",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_strawberrybowl`,
                pos = vec3(0.05, 0.00, 0.00),
                rot = vec3(-11.23, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_teriyakichickenbowl = {
        name = "Teriyaki Chicken Bowl",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_teriyakichickenbowl`,
                pos = vec3(0.07, 0.07, 0.0),
                rot = vec3(0.0, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_whiteraspberrycheesecake = {
        name = "Raspberry Cheesecake",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_whiteraspberrycheesecake`,
                pos = vec3(0.06, 0.04, 0.01),
                rot = vec3(-13.05, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    jerk_jerkwings = {
        name = "Jerk Wings",
        effect = "hunger",
        amount = 45,
        prop = {
            {
                model = `devkit_wingplate`,
                pos = vec3(0.04, 0.04, 0.01),
                rot = vec3(-12.36, -2.62, -4.54),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_wingplate = {
        name = "Mild Wing Plate",
        effect = "hunger",
        amount = 35,
        prop = {
            {
                model = `devkit_wingplate`,
                pos = vec3(0.04, 0.04, 0.01),
                rot = vec3(-12.36, -2.62, -4.54),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    Jerk_Wings = {
        name = "Jerk Wings & Lemon Pepper",
        effect = "hunger",
        amount = 50,
        prop = {
            {
                model = `devkit_wingsandfries`,
                pos = vec3(0.0700, 0.00, 0.0),
                rot = vec3(0.0, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    devkit_wingsandfries = {
        name = "Lemon Pepper Wings & Fries",
        effect = "hunger",
        amount = 35,
        prop = {
            {
                model = `devkit_wingsandfries`,
                pos = vec3(0.0700, 0.00, 0.0),
                rot = vec3(0.0, 0.0, 0.0),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    com_tam = {
        name = "Cơm Tấm",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `devkit_spork`,
                pos = vec3(0.14, 0.02, 0.01),
                rot = vec3(-118.0, 192.0, 24.0),
                bone = 57005,
            },
            {
                model = `devkit_nycsteak`,
                pos = vec3(0.08, 0.03, 0.01),
                rot = vec3(0.28, 1.72, 79.84),
                bone = 60309,
            },
        },
        anim = {
            dict = "eat@fork",
            clip = "fork_clip"
        }
    },

    tacos = {
        name = "Bánh tacos",
        effect = "hunger",
        job = "quanan", --- check job duty
        jobMinOnDuty = 2, -- Số lượng nhân viên onduty tối thiểu để chặn sử dụng
        amount = 30,
        prop = {
            model = 'burrito_beefyfritos',
            bone = 18905,
            pos = vec3(0.130000, -0.020000, 0.060000),
            rot = vec3(-122.831139, 0.000000, 0.400000)
        },
        anim = {
            dict = "mp_player_inteat@burger",
            clip = "mp_player_int_eat_burger"
        }
    },

    com_bo_luc_lac = {
        name = "Cơm bò lúc lắc",
        effect = "hunger",
        amount = 30,
        prop = {
            {
                model = `bzzz_restaurant_food_b`,
                bone = 18905,
                pos = vec3(0.08, -0.04, 0.07),
                rot = vec3(-30.0, 10.0, 0.0),
            },
            {
                model = `bzzz_restaurant_fork_b`,
                bone = 57005,
                pos = vec3(0.1, 0.05, 0.0),
                rot = vec3(-117.0, -68.0, -43.0),
            },
        },
        anim = {
            dict = "bzzz@restaurant@eat",
            clip = "bzzz_restaurant_eat",
        }
    },

    com_suon_tam_9h = {
        name = "Cơm Sườn tấm 9H",
        effect = "hunger",
        amount = 50,
        prop = {
            {
                model = 'xn_prop_com',
                bone = 18905,
                pos = vec3(0.180000, 0.040000, 0.000000),
                rot = vec3(-27.500000, 0.000000, -10.000000),
            },
            {
                model = `bzzz_restaurant_fork_b`,
                bone = 57005,
                pos = vec3(0.1, 0.05, 0.0),
                rot = vec3(-117.0, -68.0, -43.0),
            },
        },
        anim = {
            dict = "bzzz@restaurant@eat",
            clip = "bzzz_restaurant_eat",
        }
    },

}