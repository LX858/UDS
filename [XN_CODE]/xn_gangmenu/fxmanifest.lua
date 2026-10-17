--shared_script '@WaveShield/resource/waveshield.lua' --this line was automatically written by WaveShield

fx_version 'cerulean'
game 'gta5'

description 'qb-bossmenu'
version '2.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/en.lua',
    'locales/*.lua',
    'client/cl_config.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'ox_target',
    'oxmysql',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}


server_exports {
    'AddMoney',
    'AddGangMoney',
    'RemoveMoney',
    'RemoveGangMoney',
    'GetAccount',
    'GetGangAccount',
}

ui_page 'web/dist/index.html'

files {
  'web/dist/index.html',
  'web/dist/assets/*.js',
  'web/dist/assets/*.css',
  'web/dist/images/*.png',
  'web/dist/images/*.jpg',
  'web/dist/images/*.gif',
}


lua54 'yes'
