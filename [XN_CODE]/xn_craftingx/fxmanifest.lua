

fx_version 'adamant'
game 'gta5'

author 'VIERP-DEV TEAM'

version '1.2.6'
lua54 'yes'

dependencies {
    'qb-core',
    'ox_target',
    'ox_lib',
    'ox_inventory'
}

shared_scripts {
    'env.lua',
    'config.lua',
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'core/Player/defined.lua',
    'core/Player/functions.lua',
    'core/Player/qb_addon.lua',
    'core/Player/app.lua',
    'core/Player/nui.lua'
}

server_script 'core/App/app.lua'

ui_page 'view-react/index.html'
files {
    'theme-config.js',
    'view-react/index.html',
    'view-react/css/*.css',
    'view-react/js/*.js',
}

escrow_ignore {
    'env.lua',
    'config.lua',
}

