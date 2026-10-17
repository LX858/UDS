fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Stall System with Advanced UI'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/server.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    -- 'ui/images/*.webp',
    -- 'ui/images/*.png',
    -- 'ui/images/*.svg',
}

