fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'GIN'
description 'Carry dead player script using ox_lib, ox_target, and ox_inventory'
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
