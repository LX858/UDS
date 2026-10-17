fx_version 'cerulean'

game 'gta5'

author 'DRC Scripts'
description 'DRC WINEMAKER'

version '1.2.0'

lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'server/*.lua',
}

files {
	'locales/*.json'
}