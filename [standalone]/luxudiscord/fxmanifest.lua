fx_version "cerulean"
games { "gta5" }

skipYarn 'true'

author 'Luxu#0001 <luxu@luxu.gg>'
description "Luxu.gg Discord Bot"
version "1.1.1"
lua54 'yes'

ui_page "nui/index.html"
files { 'nui/*' }

shared_scripts { '@ox_lib/init.lua', '@LuxuModules/init.lua', 'locales/*.lua', }

client_script "client/client.lua"
server_scripts { "bot.lua", "config.lua", "server/server.lua", "server/index.js", "server/misc/*.js",
      'server/commands/**/*.js' }

dependencies {
      '/server:6464',
      'ox_lib',
      'screenshot-basic',
      'LuxuModules',

}