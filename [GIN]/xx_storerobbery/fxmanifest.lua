
fx_version 'bodacious'

game 'gta5'

author ''

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}
