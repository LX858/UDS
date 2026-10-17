fx_version 'cerulean'
game 'gta5'

name 'diemuytin'
description 'Hệ thống điểm uy tín cho FiveM với tù liên bang'
author 'Your Name'
version '2.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql' -- Required for prison system
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/shared/locale.lua',
    'locales/vi.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua', -- Chỉ load main.lua, không load prison.lua
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target' -- Optional - sẽ fallback về keybind nếu không có
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/*.html',
    'html/*.css',
    'html/*.js'
}

lua54 'yes'
