fx_version 'cerulean'
game 'gta5'

description 'xn_quandudu - Sấy & Đóng gói lá đu đủ'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',          -- load config trước client & server
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
    'ox_inventory',
}
