fx_version 'cerulean'
game 'gta5'

author 'Tipi'
description 'Tipi Daily Rewards'
version '1.3.1'

ui_page 'web/build/index.html'

shared_scripts {
	'@ox_lib/init.lua',
	'config/config.lua',
	'config/locales/*.lua',
	'shared/framework.lua',
	'shared/items.lua',
	'shared/month.lua',
	'shared/missed_price.lua',
}

client_scripts {
	'client/bridge.lua',
	'client/client.lua',
}

client_exports {
	'GetUiMeta',
}

server_scripts {
	'server/bridge.lua',
	'server/sql.lua',
	'server/online.lua',
	'server/catalog.lua',
	'server/rewards.lua',
	'server/streak.lua',
	'server/admin.lua',
	'server/server.lua',
}

files {
	'web/build/index.html',
	'web/build/**/*',
	'config/itemimages/*.*',
}

dependencies {
	'ox_lib',
	'oxmysql',
}

escrow_ignore {
	'client/*.lua',
	'server/*.lua',
	'shared/*.lua',
	'web/**/*',
	'config/config.lua',
	'config/locales/*.lua',
	'config/itemimages/*.*',
}

lua54 'yes'
