fx_version 'cerulean'
games { 'gta5' }

description 'xn_drilling'
version '3.5'

shared_scripts {
    'config.lua',
}

client_scripts {
    '@ox_lib/init.lua',
    'client/*.lua',
}
server_scripts {
    'server/platform.lua',
    'server/*.lua',
}
files {
    'html/*.html',
    'html/*.png',
    'html/static/**/*',
    'Platforms.json'
}

ui_page 'html/index.html'

escrow_ignore {
    'config.lua',
    'client/standalone.lua',
    'server/standalone.lua',
    'Platforms.json'
}

lua54 'yes'

