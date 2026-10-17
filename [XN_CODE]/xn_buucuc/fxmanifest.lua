fx_version 'cerulean'
game 'gta5'

name 'xn_buucuc'
author 'XN_CODE'
description 'Personal Storage System with ox_inventory + qbxcore'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua',
    'demo.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'qbx_core'
}

lua54 'yes'
