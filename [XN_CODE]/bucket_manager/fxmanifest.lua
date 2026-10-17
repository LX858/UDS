

fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Bucket Manager - Kiểm tra và reset bucket cho QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib'
}

lua54 'yes'
