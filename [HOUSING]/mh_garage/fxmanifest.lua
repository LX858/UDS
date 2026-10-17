

--[[ FX Information ]] --
fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
version '1.0.5'

dependencies {
    'oxmysql',
    'ox_lib',
    'qbx_core'
}

shared_scripts {
	'@lr_lib/ws_import.lua',
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'init.lua',
    'migration.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'init.lua'
}

ui_page 'html/index.html'

files {
	'edit_functions.lua',
	'client/client.lua',
	'server/server.lua',
	'locales/*.json',
	'bridge/**/client.lua',
	'client/*.lua',
	'config/*.lua',
	'server/*.lua',
	'html/index.html',
	'html/assets/**/*',
	'html/*.png'
}