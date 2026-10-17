fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "sh_callsignsystem"
description "Callsigns Modified by SonHoang"
author "SonHoang"
version "1.2.0"

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

-- ui_page 'http://localhost:5173/'

ui_page 'html/index.html'

files {
	'html/*.*',
	'html/**/*.*',
}

escrow_ignore {
	'shared/*.lua',
	'client/*.lua',
	'server/*.lua',
}