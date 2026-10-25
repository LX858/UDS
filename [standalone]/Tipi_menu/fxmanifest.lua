fx_version "cerulean"
description "Lorraxs + Tipi custom version 1"
author "Lorraxs"
version '1.0.0'
repository 'https://github.com/Lorraxs/lr_addon'
dependencies {
  '/server:6116',
  '/onesync',
  'oxmysql',
  'ox_lib',
  'qbx_core',
  'ox_inventory',
  'Tipi_Daily_Rewards',
}
lua54 'yes'
games {
  "gta5",
  "rdr3"
}

files {
  'web/build/index.html',
  'web/build/**/*',
}
ui_page 'web/build/index.html'
shared_scripts {
  '@ox_lib/init.lua',
  "locales/L.lua",
  "locales/lang/*.lua",
  '@PolyZone/client.lua',
  '@PolyZone/BoxZone.lua',
  '@PolyZone/EntityZone.lua',
  '@PolyZone/CircleZone.lua',
  '@PolyZone/ComboZone.lua',
  "config.lua",
  "main.lua",
  "impl.lua",
}
client_scripts {
  '@qbx_core/modules/playerdata.lua',
  "client/utils.lua",
  "client/bridge.lua",
  "client/playtime_items.lua",
  "client/classes/*",
  "client/impl/*"
}
server_script {
  "server/utils.lua",
  "server/bridge.lua",
  '@oxmysql/lib/MySQL.lua',
  "server/classes/InviteCodeStore.lua",
  "server/impl/*"
}
server_exports {
  'GetPlayerAge',
  'GetPlayerAgeLevel',
  'GetPlayerAgeByCitizenid',
  'GetPlayerPlaytime',
  'GetPlayerPlaytimeByCitizenid',
  'CalculateAgeFromPlaytime',
  'AddPlaytime',
}

escrow_ignore {
  "locales/lang/*.lua",
  "config.lua",
  "main.lua",
  "impl.lua",
  "client/utils.lua",
  "client/bridge.lua",
  "client/playtime_items.lua",
  "server/utils.lua",
  "server/bridge.lua",
  "server/classes/InviteCodeStore.lua",
  "server/impl/*",
}
