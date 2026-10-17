fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Sleep System for FiveM'
version '1.0.0'
author 'XuanNuyen'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}
