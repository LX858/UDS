

fx_version 'cerulean'
game 'gta5'

author 'XuanNuyen'
description 'Rock Mining System for QBCore with OX Integration'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'locales.lua',
    'config.lua'
}

client_scripts {
    'nungda.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
    'debug_commands.lua' -- Optional: Remove this line if you don't want debug commands
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}

lua54 'yes'
