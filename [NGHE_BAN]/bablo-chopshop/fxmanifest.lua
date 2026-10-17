games {
    "gta5"
}

version "1.0.5"

fx_version "cerulean"

nui_callback_strict_mode 'true'

use_experimental_fxv2_oal "yes"

ui_page 'src/web/dist/index.html'

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua",
    "locales/*.lua",
    "src/resource/shared/**/*"
}

client_scripts {
    "src/menus/*.lua",
    "src/interactions/*.lua",
    "src/target/*.lua",
    'src/inventories/*.lua',
    "src/resource/client/**/*",
    "frameworks/qbox/client.lua",
    'frameworks/custom/client.lua',
    "frameworks/esx/client.lua",
    "frameworks/qbcore/client.lua"
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "src/resource/server/**/*",
    'src/inventories/*.lua',
    'frameworks/qbox/server.lua',
    'frameworks/custom/server.lua',
    'frameworks/esx/server.lua',
    'frameworks/qbcore/server.lua',
    "webhooks.lua",
}

files {
    "vehicleHashes.json",
    "webhooks.lua",
    "src/web/dist/**/*",
}

lua54 "yes"