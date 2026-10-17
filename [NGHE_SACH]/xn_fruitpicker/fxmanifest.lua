fx_version 'cerulean'
game 'gta5'


description 'xn-fruitpicker'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'language.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory'
}

escrow_ignore {
    'config.lua',
    'language.lua',
    'Items/shared-items.lua'
}
