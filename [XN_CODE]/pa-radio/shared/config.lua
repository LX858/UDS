Config = {
    RadioAnimation = {
        Enable = true,
        Animation = "cellphone_text_read_base",
        Dict = "cellphone@"
    },
    ItemCheckLoop = true,
    RadioItem = "radio",
    VoiceSystem = "pma-voice", -- pma-voice, saltychat
    RestrictedChannels = {
        [1] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            },
            ["gangs"] = { -- Just works for QB
                ballas = true
            }
        },
        [2] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [3] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [4] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [5] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [6] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [7] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [8] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [9] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [10] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [113] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        },
        [115] = {
            ["jobs"] = {
                police = true,
                ambulance = true
            }
        }
    },
    MaxFrequency = 500,
    PAInventory = {
        Enable = false,
        ResourceName = "ox-inventory" -- qb-inventory, ox-inventory
    }
}