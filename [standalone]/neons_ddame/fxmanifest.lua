shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
game 'gta5'
description 'damage'
version '1.0.0'

shared_scripts {
	'@lr_lib/ws_import.lua',
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'island_redzone.lua',
	'rent_boat.lua',
	'client.lua'
}
server_script {
	'server.lua'
}

dependencies {
	'ox_lib',
	'ox_target',
	'qbx_core'
}
ui_page 'html/index.html'
files {
	'html/sounds/*.ogg',
	'html/index.html',
	'html/app.js',
	'html/style.css'
}
