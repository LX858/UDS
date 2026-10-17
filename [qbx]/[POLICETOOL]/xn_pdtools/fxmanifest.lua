fx_version 'cerulean'
game 'gta5'

author 'Xuan Nguyen'
description 'Police Vehicle Check Tool'
version '1.0.0'

dependencies {
    'ox_target',
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main_simple.lua',
    'client/test_commands.lua',
    'client/vehicle_tracker.lua',
    'client/police_box.lua'
}

server_scripts {
    'server/main_qbcore.lua',
    'sounds/babel_config.js'
}

files {
    'locales/*.json'
}

lua54 'yes'
