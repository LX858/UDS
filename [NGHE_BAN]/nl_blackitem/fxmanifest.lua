

fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Black Market Item Shop'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'ox_lib'
}

lua54 'yes'
