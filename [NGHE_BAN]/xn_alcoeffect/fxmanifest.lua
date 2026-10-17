fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'NRGscripts'
version "1.0.6"


shared_script {
	'locales/*.lua',
	'config/*.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'server/**/*.lua'
}

files {
	'web/build/index.html',
	'web/build/**/*',
    'web/build/*',
	'web/images/*.png',
	'stream/alcomat.ydr'
}

escrow_ignore {

    "client/framework/*.lua",
	"client/notify.lua",
	"client/target.lua",
	
    "server/framework/*.lua",

    "config/*.lua",

	"locales/*.lua",
}

data_file 'DLC_ITYP_REQUEST' 'stream/alcomat.ytyp'

ui_page "web/build/index.html"
client_script "client/**/*.lua"
