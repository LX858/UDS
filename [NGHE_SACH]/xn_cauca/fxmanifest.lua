

fx_version 'cerulean'
game 'gta5'

author 'XN_DEV'
description 'Advanced Fishing System with QBCore, ox_inventory, and ox_lib'
version '2.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'
