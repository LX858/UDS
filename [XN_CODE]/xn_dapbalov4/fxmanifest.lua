fx_version "cerulean"
version '1.0.0'
author 'XN'
description 'XN - Nang cap vat pham quan ao (v4 - React Vite NUI)'

lua54 'yes'

games {
  "gta5",
  "rdr3"
}

ui_page 'web/build/index.html'

shared_scripts {
  "@ox_lib/init.lua",
  "@qbx_core/modules/lib.lua",
  'shared/**/*',
}

client_script "client/**/*"
server_script "server/**/*"

files {
	'web/build/index.html',
	'web/build/**/*',
}