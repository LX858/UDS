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

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
