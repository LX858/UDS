fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Forlax'
description 'Fishing Minigame'
version '1.0.0'

ui_page 'nui/index.html'

files {
    'nui/**/*',
}

client_scripts {
    'client/**.lua'
}

-- Export APIs
exports {
    'StartMinigame',
    'StopMinigame'
}

-- fx_version 'cerulean'
-- game 'gta5'
-- lua54 'yes'

-- ui_page 'html/index.html'

-- files {
--     'html/index.html',
--     'html/style.css',
--     'html/main.js',
--     'html/fish-cdd1ab3e.png'
-- }

-- client_script 'client/**.lua'

