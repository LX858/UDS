fx_version 'cerulean'
game 'gta5'
lua54 'yes'
description 'NYO Trộm Chó'
version '1.0.0'

dependencies {
	'ox_target',
	'ox_inventory',
	'ox_lib'
}

client_scripts {
	'config.lua',
	'cl_framework.lua',
	'client.lua'
}

server_scripts {
	'config.lua',
	'sv_framework.lua',
	'server.lua'
}

shared_scripts {
	'config.lua',
	'@ox_lib/init.lua'
}

-- Export functions cho ox_inventory items
client_export 'UseXichCho'
client_export 'UseThongLong'
-- V3.2: Không cần exports cho item chó (tự động hiển thị)
