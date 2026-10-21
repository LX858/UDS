fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'xn_danhboss'
description 'Zombie boss hunt (qbx_core + ox_lib, OneSync required)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql',
    'ox_target',
}
