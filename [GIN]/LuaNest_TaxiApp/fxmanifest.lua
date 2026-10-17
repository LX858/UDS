fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'LuaNest_TaxiApp'
description 'Ubee taxi app for lb-phone (React UI, source in web/)'
version '1.0.0'

shared_script 'config.lua'
client_script 'client.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'config_sv.lua', 'server.lua' }

files {
    'ui/index.html',
    'ui/icon.svg',
    'ui/assets/*',
    'ui/img/*',
    'ui/map/**/*',
}
