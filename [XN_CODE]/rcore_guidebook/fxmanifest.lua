fx_version 'cerulean'

game 'gta5'
lua54 'yes'

author 'Isigar <info@rcore.cz> & Kralik'
description 'rcore_guidebook complete in-game guide system'
version '2.0.1'

ui_page 'client/ui/index.html'

files {
    "client/ui/**/*",
}

client_scripts {
    'client/api/*.lua',
    'client/init/*.lua',
    'client/lib/*.lua',
    'client/*.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'sconfig.lua',
    'server/api/*.lua',
    'server/init/*.lua',
    'server/lib/**/*.js',
    'server/lib/**/*.lua',
    'server/*.lua'
}

shared_scripts {
    "shared/fw-object.lua",
    "shared/hasPermission.lua",
    "shared/const.lua",
    'permissions.lua',
    'shared/init.lua',
    'locales/*.lua',
    "shared/kvp.lua",
    "shared/common.lua",
    "shared/debug.lua",
    "shared/keys.lua",
    "shared/locale.lua",
    "shared/tableHelper.lua",
    "shared/validate.lua",
    'config.lua',
}

dependencies {
    '/server:4752',
    '/onesync',
}

escrow_ignore {
    'client/api/*.lua',
    'client/lib/*.lua',
    'server/api/*.lua',
    'server/lib/**/*.lua',
    'locales/*.lua',
    'permissions.lua',
    'sconfig.lua',
    'config.lua',
    'shared/*.lua',
}
