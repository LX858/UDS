
fx_version 'cerulean'
game 'gta5'

description 'RCore Pool'

version '2.2.4'

client_scripts {
    'config.lua',
    'client/*.lua',
}

server_scripts { 
    'config.lua',
    'object.lua',
    'server/framework/*.lua',
    'server/*.lua',
}

dependencies {
    '/server:4752',
    '/onesync',
}

ui_page('client/html/sound.html')

files {
    'client/html/sound.html',
    'client/html/*.ogg',
}

lua54 'yes'