fx_version 'cerulean'
game 'gta5'

author 'Antigravity'
description 'Script check danh sach citizenid so huu xe chi dinh'
version '1.0.2'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
