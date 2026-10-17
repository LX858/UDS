fx_version 'cerulean'
game 'gta5'

author 'Thanoss'
description 'Hái Chè'
version '1.1'

dependencies {
    'ox_lib',
    'ox_target',
    'qb-core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    '@ox_target/init.lua',
    'client.lua',
}

server_script 'server.lua'