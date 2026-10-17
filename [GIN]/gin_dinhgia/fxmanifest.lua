fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'gin_dinhgia'
author 'GIN'
description 'Hệ thống định giá và quy đổi vật phẩm lấy tiền mặt / vàng'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/cl_main.lua'
}

server_scripts {
    'server/sv_main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

ui_page 'html/index.html'
