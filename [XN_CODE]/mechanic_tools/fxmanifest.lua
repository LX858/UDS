

fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Mechanic Tools - Vehicle Repair System'
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

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}

lua54 'yes'