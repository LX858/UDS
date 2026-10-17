

fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Trash Can Search Resource for QBCore'
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
    'ox_lib',
    'ox_inventory'
}

lua54 'yes'