fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'GIN'
description 'Hệ thống trói tay và tháo trói sử dụng ox_lib, ox_inventory, ox_target'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}

