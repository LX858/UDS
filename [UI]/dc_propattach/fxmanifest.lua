

fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author 'DC Customz'
description 'DC Customz Prop Attach Tool V2'
version '1.0.1'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

shared_scripts {
	'config.lua',
}

client_scripts {
	"client/cl_main.lua",
}

server_scripts {
	"server/sv_main.lua",
}

escrow_ignore {
    'config.lua',
    'server/sv_main.lua'
}