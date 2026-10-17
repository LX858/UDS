fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Under Star Community / OpenAI'
description 'Doorless long shipping container body with attachable animated doors and ox_target synchronization'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/editable.lua',
    'client/main.lua'
}

server_scripts {
    'server/editable.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target'
}
