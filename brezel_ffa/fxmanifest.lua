fx_version 'cerulean'
game 'gta5'

author 'Patbre'
description 'FFA Deathmatch Arena for Qbox'
version '2.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/localeprovider.lua',
    'locales/languages/*.lua',
    'configs/cl_config.lua',
    'configs/sv_config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/webhook.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/**/*',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql'
}