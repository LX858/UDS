fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'GIN'
description 'Script rút xăng từ xe bằng bình xăng rỗng sử dụng ox_lib, ox_target và ox_inventory'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

server_scripts {
    '@ox_lib/init.lua',
    'server/main.lua'
}
