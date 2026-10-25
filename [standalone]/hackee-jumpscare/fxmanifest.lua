fx_version 'adamant'
game 'gta5'

description 'Jumpscare utility for admins.'
lua54 "yes"
dependency 'qb-core'
shared_script {
    '@ox_lib/init.lua',
    '@lr_lib/ws_import.lua'
}
client_script 'client.lua'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server.lua'
}

ui_page('html/index.html')

files {
    'html/listener.js',
    'html/style.css',
    'html/reset.css',
    'html/index.html',
    'html/yeet.ogg'
}
