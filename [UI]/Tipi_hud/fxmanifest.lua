fx_version 'adamant'
game 'gta5'
name 'Tipi_hud'
version '1.0.0'
description 'Tipi_hud - UNDERSTAR'
author '</Tipi>'
lua54 'yes'

ui_page 'web/dist/index.html'

files {
    'web/dist/**/**.**',
    'data/*.lua'
}

shared_script {
    '@ox_lib/init.lua',
    'config.lua',
    '@lr_lib/ws_import.lua'
}

client_script {
    'client/*.lua'
}

server_script {
    '@mysql-async/lib/MySQL.lua',
    'server/*.lua'
}

escrow_ignore {
    'client/*.lua',
    'server/*.lua',
    'config.lua',
    'data/*.lua',
}

dependency 'ox_lib'

