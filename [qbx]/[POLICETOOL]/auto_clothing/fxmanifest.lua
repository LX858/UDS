fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Auto Clothing System for Police'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

lua54 'yes'
