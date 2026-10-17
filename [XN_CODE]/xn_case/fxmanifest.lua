

fx_version "adamant"

description "xn_dev_case Opening"

game "gta5"

client_script {
"main/client.lua"
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'main/sepay.lua',
    'main/server.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

shared_script {
    '@ox_lib/init.lua',
    'main/shared.lua',
    'config2.lua',
    'config_card.lua',
    'config_openbox.lua',
    'config_newitems.lua'
}

ui_page "build/index.html"

files {
    'build/index.html',
    'build/assets/**/*.*',
    'assets/**/*.*'
}

lua54 'yes'
