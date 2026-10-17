fx_version 'cerulean'
game 'gta5'
lua54 'yes' 

client_scripts {
    'client_admin.lua',
    'client_game.lua'
}

server_scripts {
    'server.lua'
}

shared_scripts {
    'config.lua'
}

ui_page "html/admin.html"

files {
    'html/*.*',
    'html/img/*.*',
    'html/join.js',
    'html/admin.html',
    'html/admin.js',
}