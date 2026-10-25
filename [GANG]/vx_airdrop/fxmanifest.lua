fx_version "cerulean"

description "Two-team airdrop event"
author "Lorraxs"
version '1.0.0'
repository 'https://github.com/Lorraxs/lr_addon'

dependencies {
  '/server:6116',
  '/onesync',
  'oxmysql',
  'ox_lib',
  'ox_inventory',
  'qbx_core',
  'qbx_medical',
  'neons_ddame',
}

lua54 'yes'

game 'gta5'

data_file "DLC_ITYP_REQUEST" "stream/bb_prop_32bit_airdrop.ytyp"

files {
  'web/build/index.html',
  'web/build/**/*',
}

ui_page 'web/build/index.html'

shared_scripts {
  '@ox_lib/init.lua',
  '@lr_lib/ws_import.lua',
  "locales/L.lua",
  "locales/lang/*.lua",
  "utils/*.lua",
  "components.lua",
  "config.lua",
  "main.lua",
  "impl.lua",
  "shared/**/*.lua",
}


client_scripts {
  "client/libs/*.lua",
  "client/utils.lua",
  "client/bridge.lua",
  "client/interfaces/*",
  "client/classes/*",
  "client/impl/*"
}
server_script {
  "client/libs/*.lua",
  "server/utils.lua",
  "server/bridge.lua",
  '@oxmysql/lib/MySQL.lua',
  "server/interfaces/*",
  "server/classes/*",
  "server/impl/*"
}

escrow_ignore {
  "locales/lang/*.lua",
  "config.lua",
  "main.lua",
  "impl.lua",
  "client/utils.lua",
  "client/bridge.lua",
  "server/utils.lua",
  "server/bridge.lua",
}
