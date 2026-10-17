fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Wasabi Loading Screen'
author 'Wasabi Scripts'
version '1.0.3'

shared_script 'config.lua'
server_script 'server.lua'

files {
  '**',
  'web/assets/**',
  'web/assets/images/**',
}

loadscreen 'web/index.html'
loadscreen_cursor 'yes'
loadscreen_manual_shutdown 'yes'

