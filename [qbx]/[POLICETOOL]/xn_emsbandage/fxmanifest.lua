fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'XN EMS Bandage - Hệ thống bán băng gạc cho bác sĩ'
version '1.0.0'
author 'XuanNguyen'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'ox_inventory',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
