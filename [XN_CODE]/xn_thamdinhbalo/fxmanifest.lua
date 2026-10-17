fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'XuanNguyen'
description 'Bag Appraisal and Upgrade System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/dist/index.html'

files {
    'html/dist/index.html',
    'html/dist/index.js',
    'html/dist/index.css',
    'html/sound/*.mp3'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'ox_lib'
}
