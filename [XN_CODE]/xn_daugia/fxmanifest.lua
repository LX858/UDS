fx_version 'cerulean'
game 'gta5'

author 'XN'
description 'XN Auction System - Realtime Bet UI & 3D Overhead Countdown'
version '1.0.0'

lua54 'yes'

ui_page 'web/index.html'

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

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/sounds/*.mp3',
    'web/sounds/*.ogg'
}
