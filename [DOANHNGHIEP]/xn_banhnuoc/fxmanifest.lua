fx_version 'cerulean'
game 'gta5'
lua54 'yes'

dependencies {
	'ox_target',
	'ox_lib',
	'ox_inventory'
}

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/assets/*.js',
	'html/assets/*.css'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/vi.lua',
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}