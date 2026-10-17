fx_version "cerulean"

description "Small script for FiveM"
author "Lorraxs"
version '1.0.0'
repository 'https://github.com/Lorraxs/lr_addon'

dependencies {
  '/server:6116',
  '/onesync',
  'oxmysql',
  'ox_lib',
}

lua54 'yes'

games {
  "gta5",
  "rdr3"
}

files {
  'web/build/index.html',
  'web/build/**/*',
  "ws_import.lua"
}

ui_page 'web/build/index.html'

shared_scripts {
  '@ProjectStarboy/imports.lua',
  '@ox_lib/init.lua',
  "locales/L.lua",
  "locales/lang/*.lua",
  "config.lua",
  "main.lua",
  "impl.lua",
  "shared/**/*.lua"
}


client_scripts {
  "client/ws.lua",
  "client/utils.lua",
  "client/bridge.lua",
  "client/classes/*",
  "client/impl/*"
}
server_script {
  "server/ws.js",
  "server/config.lua",
  "server/utils.lua",
  "server/bridge.lua",
  '@oxmysql/lib/MySQL.lua',
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
