fx_version 'cerulean'
game 'gta5'
lua54 'on'


shared_scripts  {
    'shared.lua',
    '@lr_lib/ws_import.lua'
}
client_scripts {
    'client/*.lua',
}
server_scripts {
    'server/*.lua',
}

escrow_ignore {
    '*.lua',
    '**/*.lua'
  }
