fx_version 'cerulean'
game 'gta5'

author "File được convert từ tC-Dev"
version "v1.0.0"

client_scripts {
	'@ox_lib/init.lua',
    '@qbx_core/modules/playerdata.lua',

    'client/*.lua',
}

server_script {
    'server/*.lua',
}

shared_scripts {
	'config.lua',
}

lua54 'yes'