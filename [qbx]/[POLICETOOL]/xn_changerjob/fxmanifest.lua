fx_version 'cerulean'
game 'gta5'

author 'XuanNuyen'
description 'Job Changer Script - Police <-> HocVien'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua',
}

dependencies {
    'ox_target',
    'ox_lib',
    'qb-core' -- QBCore framework
}

lua54 'yes'
