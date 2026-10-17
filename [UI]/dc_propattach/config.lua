Config = {}
Config.Framework = "qb" -- "esx", "qb", "none"
Config.OnlyAdmins = true -- Set to true to restrict to admins only
Config.Command = 'devpropstool' -- Command to open ui

-- Preset Props
Config.Props = {
    'prop_cs_burger_01',
}

-- Preset Animations
Config.Animations = {
    { label = 'Eat Burger', dict = 'mp_player_inteat@burger', anim = 'mp_player_int_eat_burger', flags = 49 },
    { label = 'Drink Cup', dict = 'mp_player_intdrink', anim = 'loop_bottle', flags = 49 },
    
    -- Everyday Anims (Uncomment if you have the DC Everyday Animations pack)
    --{ label = 'Rollup', dict = 'custom@rollingupanim', anim = 'rollingup_clip', flags = 2  },
    --{ label = 'Hold Drink', dict = 'custom@drinkingbottlehold', anim = 'drinkingbottlehold_clip', flags = 49 },
    --{ label = 'Sip Drink', dict = 'custom@drinkingbottle', anim = 'drinkingbottle_clip', flags = 49 },
    --{ label = 'Plate Eat', dict = 'custom@eatplate', anim = 'eatplate_clip', flags = 49 },
    --{ label = 'Plate Eat Hold', dict = 'custom@eatplate', anim = 'eatplatehold_clip', flags = 49 },
    --{ label = 'Chips Eat', dict = 'custom@chipseat', anim = 'chipseat_clip', flags = 49 },
    --{ label = 'Chips Eat Hold', dict = 'custom@chipseathold', anim = 'chipseathold_clip', flags = 49 },
    --{ label = 'Brush Teeth', dict = 'custom@brushteeth', anim = 'brushteeth_clip', flags = 49 },
}

-- Preset Bones
Config.Bones = {
    { name = "Left Hand",  id = 18905 },
    { name = "Right Hand", id = 57005 },
    { name = "Head",       id = 31086 },
    { name = "Lip",        id = 47419 },
    { name = "Pelvis",     id = 11816 },
    { name = "Right Leg",  id = 36864 },
    { name = "Left Leg",   id = 63931 },
}
