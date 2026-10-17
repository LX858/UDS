fx_version "cerulean"

description "Small script for FiveM"
version '1.0.0'
lua54 'yes'

games {
  "gta5",
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
