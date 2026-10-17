fx_version 'cerulean'
game 'gta5'

author 'Xuan Nguyen'
description 'All Stars Vietnam Announcements System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/*.*',
    'html/assets/*.*',
}

lua54 'yes'
