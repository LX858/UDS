fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vx_torture'
description 'QBX torture chair with server-owned sessions and FBI3 scenes'
version '1.0.0'

dependencies {
  '/onesync',
  'qbx_core',
  'qbx_medical',
  'ox_inventory',
  'ox_target',
  'ox_lib',
}

shared_scripts {
  '@ox_lib/init.lua',
  'locales/L.lua',
  'locales/lang/*.lua',
  'utils/*.lua',
  'components.lua',
  'config.lua',
  'main.lua',
  'impl.lua',
  'shared/**/*.lua',
}

client_scripts {
  'client/utils.lua',
  'client/bridge.lua',
  'client/impl/*.lua',
}

server_scripts {
  'server/utils.lua',
  'server/bridge.lua',
  'server/impl/*.lua',
}
