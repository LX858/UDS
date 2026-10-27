fx_version 'cerulean'
game 'gta5'
author '</Tipi>'
lua54 'yes'
files {
    'web/dist/index.html',
    'web/dist/**/*',
    'web/dist/*',
}
ui_page 'web/dist/index.html'
client_scripts {
    'config/config.clientfunction.lua',
    "config/config.lua",
    "client/mainx.lua",
    "client/main.lua"
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/config.serverfunction.lua',
    "config/config.lua",
    'server/rewards.lua',
    "server/server.lua"
}
shared_scripts {
    "@ox_lib/init.lua"
}

dependencies {
    'oxmysql',
    'qbx_core',
    'qbx_medical',
    'ox_inventory',
    'illenium-appearance',
    'ox_lib'
}
export { 'CheckFlag' }
