fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'XN Code'
description 'UnderStar QBX Update Notification & Admin Posting System'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
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
    'web/app.js',
    'web/images/logo.png',
    'web/images/banner.jpg',
    'updates.json'
}

dependencies {
    'qbx_core'
}
