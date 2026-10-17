
fx_version 'adamant'

game 'gta5'
lua54 'yes'


ui_page 'html/index.html'

files {
	'html/**',
	'html/font/*',
	'html/sounds/*',
}

shared_scripts {
    '@qbx_core/modules/playerdata.lua',
	'@ox_lib/init.lua',
	'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	"server.lua"
} 

client_script "client.lua"