fx_version 'cerulean'
game 'gta5'

name        'xn_suavukhi'
description 'Sửa chữa độ bền vũ khí - XN_CODE'
version     '1.0.0'
author      'XN_CODE'

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
    'ox_inventory',
    'qbx_core',
}
