--

fx_version 'adamant'
game 'gta5'
author 'okok#3488'
description 'okokBilling'

dependencies {
	'ox_target'
}

ui_page 'web/ui.html'
files {
	'web/*.*'
}
shared_script 'config.lua'
client_scripts {
	'client.lua',
}
server_scripts {
	'sv_config.lua',
	'server.lua',
}
