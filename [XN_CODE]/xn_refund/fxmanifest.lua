fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'XN'
description 'XN Refund - Quy doi banhran_ht va pizza_ht thanh tien mat'
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
    'qbx_core',
    'ox_lib',
    'ox_inventory'
}
