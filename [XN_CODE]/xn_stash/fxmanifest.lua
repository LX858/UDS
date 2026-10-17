

fx_version 'cerulean'
game 'gta5'

name 'xn_stash'
description 'Stash system for jobs and personal stashes using ox_target and ox_inventory'
author 'XuanNuyen'
version '2.0.0'

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
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target'
}

lua54 'yes'
