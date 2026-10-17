fx_version 'cerulean'
game 'gta5'

name 'xn_jobgarage'
description 'Job Garage System for QBX Core - Spawn vehicles based on job'
author 'XN'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qbx_core',
    'ox_lib'
}

lua54 'yes'
