

fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Vehicle Freeze System using ox_target and ox_lib'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

dependencies {
    'ox_target',
    'ox_lib'
}

lua54 'yes'
