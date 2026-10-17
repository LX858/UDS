fx_version 'cerulean'
game 'gta5'

name 'clothes_exchange'
author 'FiveM Community'
description 'Trao đổi quần áo cùng độ hiếm'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'XNClothes'
}
