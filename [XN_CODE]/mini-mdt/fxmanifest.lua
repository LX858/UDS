fx_version 'cerulean'
game 'gta5'

author 'MINI MDT'
description 'Hệ thống quản lý án tích & hồ sơ vụ án'
version '1.0.0'

dependencies {
    'qb-core',
    'qbx_core',
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locale.lua'
}

client_scripts {
    'client/*.lua',
    'client/vehicle_impound.lua',
    'client/vehicle_actions.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/callbacks.lua',
    'server/vehicle_impound.lua'
}

ui_page 'web/index.html'

files {
    'web/**/*'
}

lua54 'yes'
