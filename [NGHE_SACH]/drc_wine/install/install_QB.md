QBCORE INSTALL QUIDE

1. Download all dependencies!
    Dependencies:
    ox_lib | https://github.com/overextended/ox_lib/releases/latest
    es_extended / qb-core
    qtarget / qb-target / ox_target
    ox_inventory / qb-inventory / lj-inventory / qs-inventory
    xsound (with emulator for interact sound) or interactsound


2. Add Images to your inventory
    qb-inventory > html > images
    Paste images from folder images to qb-inventory > html > images 

3. Add Items to your inventory and jobs
    qb-core > shared.lua
    ['wine'] = {
        label = 'Winemaker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            ['0'] = {
                name = 'Recruit',
                payment = 50
            },
            ['1'] = {
                name = 'Novice',
                payment = 75
            },
            ['2'] = {
                name = 'Experienced',
                payment = 100
            },
            ['3'] = {
                name = 'Advanced',
                payment = 125
            },
            ['4'] = {
                name = 'Manager',
                payment = 150
            },
            ['5'] = {
                name = 'Boss',
                isboss = true,
                payment = 150
            },
        },
    },
    qb-core > shared.lua
    ["scissors"] 		 	 	 	 = {["name"] = "scissors",           			["label"] = "Scissors",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "scissors.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},
    ["scissors_dirty"] 		 	 	 	 = {["name"] = "scissors_dirty",           			["label"] = "Dirty scissors",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "scissors_dirty.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},
    ["dirty_wine_bottle"] 		 	 	 	 = {["name"] = "dirty_wine_bottle",           			["label"] = "Dirty wine bottle",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "dirty_wine_bottle.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},
    ["empty_wine_bottle"] 		 	 	 	 = {["name"] = "empty_wine_bottle",           			["label"] = "Empty wine bottle",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "empty_wine_bottle.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},
    ["red_wine_grapes"] 		 	 	 	 = {["name"] = "red_wine_grapes",           			["label"] = "Red grapes",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "red_wine_grapes.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},
    ["red_wine_juice"] 		 	 	 	 = {["name"] = "red_wine_juice",           			["label"] = "Red pressed grapes",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "red_wine_juice.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["red_wine_bottle"] 		 	 	 	 = {["name"] = "red_wine_bottle",           			["label"] = "Red wine bottle",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "red_wine_bottle.png", 			["unique"] = false, 	["useable"] = true, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["red_wine_glass"] 		 	 	 	 = {["name"] = "red_wine_glass",           			["label"] = "Red wine glass",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "red_wine_glass.png", 			["unique"] = false, 	["useable"] = true, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["white_wine_grapes"] 		 	 	 	 = {["name"] = "white_wine_grapes",           			["label"] = "White grapes",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "white_wine_grapes.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["white_wine_juice"] 		 	 	 	 = {["name"] = "white_wine_juice",           			["label"] = "White pressed grapes",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "white_wine_juice.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["white_wine_bottle"] 		 	 	 	 = {["name"] = "white_wine_bottle",           			["label"] = "White wine bottle",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "white_wine_bottle.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["white_wine_glass"] 		 	 	 	 = {["name"] = "white_wine_glass",           			["label"] = "White wine glass",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "white_wine_glass.png", 			["unique"] = false, 	["useable"] = true, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["rose_wine_grapes"] 		 	 	 	 = {["name"] = "rose_wine_grapes",           			["label"] = "Rose grapes",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "rose_wine_grapes.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["rose_wine_juice"] 		 	 	 	 = {["name"] = "rose_wine_juice",           			["label"] = "Rose pressed grapes",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "rose_wine_juice.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["rose_wine_bottle"] 		 	 	 	 = {["name"] = "rose_wine_bottle",           			["label"] = "Rose wine bottle",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "rose_wine_bottle.png", 			["unique"] = false, 	["useable"] = true, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["rose_wine_glass"] 		 	 	 	 = {["name"] = "rose_wine_glass",           			["label"] = "Rose wine glass",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "rose_wine_glass.png", 			["unique"] = false, 	["useable"] = true, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["rose_wine_prepared"] 		 	 	 	 = {["name"] = "rose_wine_prepared",           			["label"] = "Rose grapes prepared",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "rose_wine_prepared.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["red_wine_prepared"] 		 	 	 	 = {["name"] = "red_wine_prepared",           			["label"] = "Red grapes prepared",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "red_wine_prepared.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["white_wine_prepared"] 		 	 	 	 = {["name"] = "white_wine_prepared",           			["label"] = "White grapes prepared",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "white_wine_prepared.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["wine_glass"] 		 	 	 	 = {["name"] = "wine_glass",           			["label"] = "Wine glass",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "wine_glass.png", 			["unique"] = false, 	["useable"] = true, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["wine_glass"] 		 	 	 	 = {["name"] = "wine_glass",           			["label"] = "Wine glass",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "wine_glass.png", 			["unique"] = false, 	["useable"] = true, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["wine_label"] 		 	 	 	 = {["name"] = "wine_label",           			["label"] = "Wine bottle label",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "wine_label.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

    ["empty_wine_bottle_labeled"] 		 	 	 	 = {["name"] = "empty_wine_bottle_labeled",           			["label"] = "Empty wine labeled bottle",	 		["weight"] = 175, 		["type"] = "item", 		["image"] = "empty_wine_bottle_labeled.png", 			["unique"] = false, 	["useable"] = false, 	["shouldClose"] = false,   ["combinable"] = nil, ["description"] = ""},

4. add ensure drc_wine into your server.cfg (make sure to start it after ox_lib and your target system!)

5. ensure wine_props before drc_wine

6. Enjoy your new wine script from DRC SCRIPTS!