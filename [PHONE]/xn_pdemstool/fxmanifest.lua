fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'PD & EMS Department Announcements App for LB Phone'
version '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}
