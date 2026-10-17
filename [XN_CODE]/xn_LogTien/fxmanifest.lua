fx_version 'cerulean'
game 'gta5'

author 'XN_CODE2'
description 'Money Logging System with NUI'
version '2.0.0'

-- Server scripts
server_scripts {
    'config.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/nui.lua',
}

-- Client scripts
client_scripts {
    'client/nui.lua',
}

-- Shared scripts
shared_script {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'locales/en.lua',
    'locales/*.lua',
    '@ox_lib/init.lua',
}

-- NUI
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/*.js',
    'html/assets/*.css',
}

lua54 'yes'

escrow_ignore {
    'config.lua',
    'server/*.lua',
    'client/*.lua',
    'locales/*.lua',
}
