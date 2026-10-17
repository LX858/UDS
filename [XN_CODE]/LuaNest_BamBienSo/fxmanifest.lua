-------------For support, scripts, and more----------------
--------------- https://discord.gg/VGYkkAYVv2  -------------
---------------------------------------------------------------

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author "LuaNest Studio"
description "LuaNest_BamBienSo | Tham gia Discord tại: https://discord.gg/4SGgaS3xbb"
version "1.0.0"
repository "https://discord.gg/4SGgaS3xbb"

shared_scripts {
    '@ox_lib/init.lua',
    'Config.lua',
}

client_scripts {
    'client/**/*.lua',
}

server_script {
    "server/**/*",
    '@oxmysql/lib/MySQL.lua',
}

files {
    'html/*',
}