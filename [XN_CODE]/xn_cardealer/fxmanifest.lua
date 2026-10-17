fx_version 'cerulean'

game 'gta5'

author 'd4nny.w'

description 'Cardealer Nhập Cảng'

version '1.1'

shared_scripts {
    '@ox_lib/init.lua',
    'sh_config.lua',
    '@qbx_core/modules/playerdata.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/nui_callbacks.lua',
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/react-styles.css',
    'nui/react-bundle.js',
    -- Original files (backup)
    -- 'nui/index-old.html',
    -- 'nui/style.css',
    -- 'nui/script.js',
}

lua54 'yes'
