fx_version 'cerulean'
game 'gta5'

author 'XN_CODE2'
description 'Hệ thống bán lại xe cũ cho QBX Core'
version '1.0.0'
lua54 'yes'

ui_page 'web/index.html'

files {
    'web/**/*'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'oxmysql'
}
