fx_version 'bodacious'

game 'gta5'

lua54 'yes'

version '3.0'

ui_page 'html/index.html'

files {
    'html/**/*'
}

client_scripts {
	'@ox_lib/init.lua',
    '@qbx_core/modules/playerdata.lua',
    '@qbx_core/modules/lib.lua',
	'config.lua',
	'client.lua'
}
server_scripts {
	'@ox_lib/init.lua',
	'config.lua',
	'server.lua'
}
