return {
    islandCoords = vec3(4840.571, -5174.425, 2.0),

    -- TRUE = show both San Andreas + Cayo on radar/pause map using the fake-island radar interior.
    enableMap = true,

    entitySets = {
        {
            enable = false,
            name = 'pearl_necklace_set',
            color = 1
        },
        {
            enable = true,
            name = 'panther_set',
            color = 1
        },
        {
            enable = false,
            name = 'pink_diamond_set',
            color = 1
        }
    },

    radioStations = {
        disable = true,
        showNoSignal = true,
        stations = {
            ['RADIO_01_CLASS_ROCK'] = true,
            ['RADIO_02_POP'] = true,
            ['RADIO_03_HIPHOP_NEW'] = true,
            ['RADIO_04_PUNK'] = true,
            ['RADIO_05_TALK_01'] = true,
            ['RADIO_06_COUNTRY'] = true,
            ['RADIO_07_DANCE_01'] = true,
            ['RADIO_08_MEXICAN'] = true,
            ['RADIO_09_HIPHOP_OLD'] = true,
            ['RADIO_11_TALK_02'] = true,
            ['RADIO_12_REGGAE'] = true,
            ['RADIO_13_JAZZ'] = true,
            ['RADIO_14_DANCE_02'] = true,
            ['RADIO_15_MOTOWN'] = true,
            ['RADIO_16_SILVERLAKE'] = true,
            ['RADIO_17_FUNK'] = true,
            ['RADIO_18_90S_ROCK'] = true,
            ['RADIO_19_USER'] = true,
            ['RADIO_20_THELAB'] = true,
            ['RADIO_21_DLC_XM17'] = true,
            ['RADIO_22_DLC_BATTLE_MIX1_RADIO'] = true,
            ['RADIO_23_DLC_XM19_RADIO'] = true,
            ['RADIO_27_DLC_PRHEI4'] = true,
            ['RADIO_34_DLC_HEI4_KULT'] = true,
            ['RADIO_35_DLC_HEI4_MLR'] = true,
            ['RADIO_36_AUDIOPLAYER'] = true,
            ['RADIO_37_MOTOMAMI'] = true
        }
    }
}
