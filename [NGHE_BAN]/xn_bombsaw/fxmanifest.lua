fx_version 'cerulean'
game 'gta5'

shared_scripts {
    'build/index.js',
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
