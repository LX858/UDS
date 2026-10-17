fx_version 'cerulean'
game 'gta5'

author 'XN Admin Item'
description 'Admin Item Management System - React + Vite'
version '2.0.0'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/config.lua',
    'server/main.lua'
}

files {
    'web/build/**/*'
}
