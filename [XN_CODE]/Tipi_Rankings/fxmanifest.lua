fx_version 'cerulean'
name 'Tipi_Rankings'
author 'Tipi'
description 'Bảng xếp hạng UnderStars'
version '1.0.0'
dependencies {
	'/server:6116',
	'/onesync',
	'oxmysql',
	'ox_lib',
}
lua54 'yes'
games {
	'gta5',
	'rdr3'
}
files {
	'web/build/index.html',
	'web/build/**/*',
}
ui_page 'web/build/index.html'
shared_scripts {
	'@ox_lib/init.lua',
	'locales/L.lua',
	'locales/lang/*.lua',
	'config.lua',
	'main.lua',
	'impl.lua',
}
client_scripts {
	'client/utils.lua',
	'client/impl/*'
}
server_script {
	'@oxmysql/lib/MySQL.lua',
	'server/impl/*'
}
escrow_ignore {
	'locales/lang/*.lua',
	'config.lua',
	'main.lua',
	'impl.lua',
	'client/utils.lua',
	'server/impl/*',
}

exports {
	'Open',
	'Close',
	'InvalidateCache',
}
