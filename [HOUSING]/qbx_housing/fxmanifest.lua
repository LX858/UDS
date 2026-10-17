fx_version 'cerulean'
game 'gta5'

author 'QBX Housing'
description 'Housing system for QBX Core with ox_inventory and mh_garage integration'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/*',
    'html/images/*.jpg',
    'html/images/*.png',
    'html/images/*.svg'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/*.lua'
}

client_scripts {
    'client/gang_clothing.lua', -- Gang clothing system
    'client/main.lua',
    'client/nui.lua',
    'client/mh_garage_integration.lua', -- Load integration trước garage.lua
    'client/garage.lua',
    'client/debug.lua',
    'client/admin.lua' -- Admin UI
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/gang_clothing.lua',         -- Gang clothing system
    'server/mh_garage_integration.lua', -- Integration với mh_garage
    'server/garage.lua',
    'server/admin.lua'                  -- Admin commands
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'mh_garage',
    'oxmysql'
}

lua54 'yes'
