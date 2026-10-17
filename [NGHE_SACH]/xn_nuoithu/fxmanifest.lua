

fx_version 'cerulean'
game 'gta5'
author 'VIE-TEAM'
description 'Script Chăm Sóc Thú Cưng chỉnh sửa bởi VIRP-DEV'
version '1.0.0'

client_script {
    'Config.lua',
    'client/main.lua', 
    'client/npc_interact.lua'
}

server_script {
    '@oxmysql/lib/MySQL.lua',
    'Config.lua',
    'server/main.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua'
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*'
}

lua54 'yes'