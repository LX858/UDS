-- NC PROTECT+
server_scripts { '@nc_PROTECT+/exports/sv.lua' }
client_scripts { '@nc_PROTECT+/exports/cl.lua' }

fx_version 'adamant'

game 'gta5'

description 'ZC-Gundance Updated by SonHoang'

version '1.0.0'


dependencies {
    'qb-core',
    'ox_lib'
}

client_scripts {
    'clientx.lua',
	'config.lua',
	'client.lua'
}
server_scripts {
	'config.lua',
	'server.lua'
}

ui_page 'ui/index.html'
files {
    'ui/index.html',
    'ui/css/*.css',
    'ui/js/locales/*.js',
    'ui/js/*.js',
    'ui/img/*.jpg',
    'ui/img/*.png',
    'ui/sounds/*.mp3'
}