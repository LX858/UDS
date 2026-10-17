Config = {}

Config.Trashcans = { -- The models of the trashcans you want to be searchable!
    -- Common dumpsters
    `prop_dumpster_01a`,
    `prop_dumpster_02a`,
    `prop_dumpster_02b`,
    `prop_dumpster_4a`,
    `prop_dumpster_4b`,
    
    -- Bins
    `prop_bin_01a`,
    `prop_bin_02a`,
    `prop_bin_03a`,
    `prop_bin_04a`,
    `prop_bin_05a`,
    `prop_bin_06a`,
    `prop_bin_07a`,
    `prop_bin_07b`,
    `prop_bin_07c`,
    `prop_bin_07d`,
    `prop_bin_08a`,
    `prop_bin_08open`,
    `prop_bin_10a`,
    `prop_bin_10b`,
    `prop_bin_11a`,
    `prop_bin_12a`,
    `prop_bin_13a`,
    `prop_bin_14a`,
    `prop_bin_14b`,
    
    -- Street bins
    `prop_street_bin_01`,
    `prop_street_bin_02`,
    `prop_street_bin_08`,
    
    -- CS bins
    `prop_cs_bin_01`,
    `prop_cs_bin_02`,
    `prop_cs_bin_03`,
    
    -- Recycling bins
    `prop_recyclebin_02_c`,
    `prop_recyclebin_02_d`,
    `prop_recyclebin_03_a`,
    `prop_recyclebin_04_a`,
    `prop_recyclebin_04_b`,
    `prop_recyclebin_05_a`,
}

Config.ItemsToFind = { -- The items that can be found in trashcans
    {
        item = 'lockpick', -- The ID/Name of the item from inventory
        price = 0, -- Just leave this at 0
        amount = math.random(1, 2), -- Can be a solid number
        info = {}, -- If you want a specific data to be assigned for the item
        type = 'item', -- Just the category of the item
        chance = 10 -- How high a chance it is to find!
    },
    -- {
    --     item = 'manhgepgacha',
    --     price = 0,
    --     amount = math.random(1, 2),
    --     info = {},
    --     type = 'item',
    --     chance = 5
    -- },
    {
        item = 'volon',
        price = 0,
        amount = math.random(1, 2), 
        info = {},
        type = 'item',
        chance = 50
    },
    {
        item = 'vochai',
        price = 0,
        amount = math.random(1, 2),
        info = {},
        type = 'item',
        chance = 50
    },
    {
        item = 'racthai',
        price = 0,
        amount = 1,
        info = {},
        type = 'item',
        chance = 70
    },
    {
        item = 'co_bon_la_2',
        price = 0,
        amount = 1,
        info = {},
        type = 'item',
        chance = 1
    },
    -- {
    --     item = 'com_ga',
    --     price = 0,
    --     amount = 1,
    --     info = {},
    --     type = 'item',
    --     chance = 10
    -- },
}

Config.SearchTime = 10000 -- 10 seconds in milliseconds
Config.CooldownTime = 15 * 60 * 1000 -- 15 minutes in milliseconds

-- Refining system
Config.RefiningLocation = vec3(125.02, -1181.42, 29.5)
Config.RefiningTime = 10000 -- 10 seconds in milliseconds

Config.RefiningRecipes = {
    aluminum = {
        input = 'volon',
        inputAmount = 3,
        output = 'aluminum',
        outputAmount = 1,
        label = 'Tinh luyện Aluminum'
    },
    plastic = {
        input = 'vochai',
        inputAmount = 3,
        output = 'plastic',
        outputAmount = 1,
        label = 'Tinh luyện Plastic'
    }
}


Config.InventoryLabel = "Trash"
Config.InventorySlots = 25
Config.InventoryWeight = 50000 -- In grams
Config.Target = "ox_target" -- ox_target or qb-target
Config.OXTarget = { -- ONLY USE IF YOU USE OX_TARGET!
    label = "Mở thùng rác",
    icon = "fa-solid fa-trash-can",
    distance = 2.0,
    onSelect = function()
        TriggerServerEvent('lion_trashbin:createTempStash')
    end
}
Config.QBTarget = { -- ONLY USE IF YOU USE QB-TARGET!
    {
        label = "Mở thùng rác",
        icon = "fa-solid fa-trash-can",
        action = function(entity)
            TriggerServerEvent('lion_trashbin:createTempStash')
        end
    }
}
Config.Props = { -- If you want add or remove props / https://gta-objects.xyz/objects/search?text=bin
    "prop_bin_01a",
    "prop_bin_05a",
    "prop_bin_02a",
    "prop_bin_06a",
    "prop_cs_dumpster_01a",
    "p_dumpster_t",
    "prop_dumpster_3a",
    "prop_dumpster_4b",
    "prop_dumpster_4a",
    "prop_dumpster_01a",
    "prop_dumpster_02a",
    "prop_dumpster_02b",
    "prop_snow_dumpster_01",
    "prop_bin_04a",
}