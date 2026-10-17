
fx_version 'bodacious'
lua54 'yes' 
game 'gta5' 

author 'R1CKY®#2220'
description 'DMV School - Tech Development'
version '1.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
   '@mysql-async/lib/MySQL.lua',
   'server.lua'
}

ui_page 'web/index.html'

files {
    'web/*.html',
    'web/css/*.css',
    'web/js/*.js',
    'web/img/*.png',
}
