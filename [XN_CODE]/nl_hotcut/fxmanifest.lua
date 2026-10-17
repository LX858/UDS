

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'QBX Community Service with ox_lib zones'

version '2.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'locale.lua',
	'locales/en.lua',
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'locale.lua',
	'locales/en.lua',
	'config.lua',
	'client/main.lua',
	'client/mugshot.lua'
}

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

ui_page 'html/index.html'

files {
  'html/*.css',
  'html/*.js',
  'html/*.gif',
  'html/*.png',
  'html/index.html',
}

lua54 'yes'