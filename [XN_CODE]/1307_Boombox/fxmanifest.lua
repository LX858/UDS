fx_version 'cerulean'
game 'gta5'
version '1.0.0'
lua54 'yes'
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}
client_scripts {
    "client/main.lua",
    '@qbx_core/modules/playerdata.lua',
}
server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/main.lua",
}
