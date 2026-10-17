fx_version 'cerulean'
game 'gta5'

author 'Anti-Backdoor Scanner'
description 'Phát hiện và cảnh báo backdoor/mã độc trong resources'
version '3.0.0'

server_scripts {
    'config.lua',
    'server/scanner.lua'
}

client_script 'client/client.lua'
