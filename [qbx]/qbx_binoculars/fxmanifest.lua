fx_version 'cerulean'
game 'gta5'

description 'qbx_binoculars'
version '1.1.1'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}