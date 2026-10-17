

fx_version 'cerulean'
game 'gta5'
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/playerdata.lua',
    '@qbx_core/modules/lib.lua',
    '@oxmysql/lib/MySQL.lua'
}

server_script 'server/*.lua'

client_script 'client/*.lua'

files {
    'config/*.lua',
}

lua54 'yes'
