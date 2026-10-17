fx_version 'cerulean'
game 'gta5'

author 'XN_CODE'
description 'Hệ thống Gửi Báo Cáo / Report kèm Ghi Hình Video + Thu Âm Môi Trường & Người Xung Quanh + FiveManage + Discord Log Quét Bán Kính 50m'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}

lua54 'yes'
