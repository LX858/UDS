fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

description 'Aether Scripts - Prop Manager'
author 'Colbss'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_script {
    '@ox_lib/init.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/bridge/server/*.lua',
	'modules/server/*.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'modules/bridge/client/*.lua',
	'modules/client/*.lua',
}

ui_page 'web/dist/index.html'

files {
    'config.lua',
    'config_prop.lua',
    'locales/*.json',
	'web/dist/index.html',
	'web/dist/**/*',
}