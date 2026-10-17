fx_version 'cerulean'
game 'gta5'

author 'GIN'
description 'He thong thap huong chua & vai lay'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/*.mp3',
    'html/sounds/*.ogg',
    'html/sounds/*.wav'
}
