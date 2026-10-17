fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Nghe Sach'
description 'Trash Collector Job - Quét Rác'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}
