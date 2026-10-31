--[[
    if not using ox_inventory, you will need to manually add the inventory image links to the items in this list.
        {
            name = 'WEAPON_PISTOL',
            amount = 1,
            imageUrl = 'https://image.png'
        },

]]

CASES = {
    ['gachabox2'] = { -- this index should be the name of the item used if you are triggering this through using an item
        common = {
            {
                name = 'bandage_lv2',
                amount = 5,
            },
            {
                name = 'ao_giap_gang_lv1',
                amount = 1,
            }
        },
        uncommon = {
            {
                name = 'bandage_lv2',
                amount = 10,
            },
            {
                name = 'ao_giap_gang_lv1',
                amount = 2,
            },
            {
                name = 'manhtatto_s',
                amount = 1,
            }
        },
        rare = {
            {
                name = 'bandage_lv2',
                amount = 20,
            },
            {
                name = 'ao_giap_gang_lv1',
                amount = 5,
            },
            {
                name = 'manhtatto_s',
                amount = 3,
            },
            {
                name = 'cong_thuc_machete',
                amount = 1,
            },
            {
                name = 'congcuren',
                amount = 2,
            }
        },
        epic = {
            {
                name = 'bandage_lv2',
                amount = 30,
            },
            {
                name = 'ao_giap_gang_lv1',
                amount = 10,
            },
            {
                name = 'manhtatto_s',
                amount =5,
            },
            {
                name = 'cong_thuc_machete',
                amount = 2,
            },
            {
                name = 'congcuren',
                amount = 2,
            }

        },
        
        legendary = {
            {
                name = 'manhtatto_s',
                amount = 30,
            },
            {
                name = 'cong_thuc_machete',
                amount = 10,
            },
            {
                name = 'gachabox_tattoo',
                label = 'Tattoo',
                amount = 1,
                clothes = {
                    { type = 'gloves', male = 222, female = 272, texture = 0, count = 1 },
                    { type = 'gloves', male = 250, female = 273, texture = 0, count = 1 },
                    { type = 'gloves', male = 267, female = 276, texture = 0, count = 1 },
                },
            }
        },
    }
}


for case, data in pairs(CASES) do
    Bridge.RegisterUsableItem(case, function(src) --register case as a usable item
        if Bridge.removeItem(src, case, 1) then
            local lootPool, winner = GetCaseData(src, case)
            TriggerClientEvent('demi_lootbox:RollCase', src, lootPool, winner)
        end
    end)

    for rarity, items in pairs(data) do
        for i = 1, #items do
            local item = CASES[case][rarity][i]
            if not item.label and item.name then
                local label = Bridge.getitemLabel(item.name)
                if label and label ~= "ERROR" then
                    CASES[case][rarity][i].label = label
                end
            end
        end
    end
end
