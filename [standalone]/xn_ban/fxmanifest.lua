fx_version 'cerulean'
game 'gta5'

author 'XN_CODE'
description 'Hệ thống Quản lý Ban Người Chơi (License, Discord, Gmail, IP) kèm UI React Vite phong cách txAdmin'
version '1.0.0'

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

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/**/*',
    'web/dist/*'
}

lua54 'yes'
