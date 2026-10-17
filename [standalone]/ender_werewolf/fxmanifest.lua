fx_version 'cerulean'
description 'Werewolf RP by Ender'
author 'Ender'
version '1.0.0'
dependencies {
	'/server:6116',
	'/onesync',
	'ox_lib',
	'ox_target',
	'pma-voice',
}
lua54 'yes'
games {
	'gta5',
	'rdr3'
}
files {
	'web/build/index.html',
	'web/build/**/*',
	'shared/*.lua',
	'shared/*.json',
}
ui_page 'web/build/index.html'
shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/modules/lib.lua',
	'config.lua',
	'shared/*.lua',
	'main.lua',
	'impl.lua',
}
client_scripts {
	'client/utils.lua',
	'client/bridge.lua',
	'client/input.lua',
	'client/voice.lua',
	'client/classes/*',
	'client/impl/*'
}
server_scripts {
	'server/utils.lua',
	'server/bridge.lua',
	'server/voice.lua',
	'server/classes/*',
	'server/impl/*'
}
escrow_ignore {
	'locales/lang/*.lua',
	'config.lua',
	'main.lua',
	'impl.lua',
	'client/utils.lua',
	'client/bridge.lua',
	'client/input.lua',
	'server/utils.lua',
	'server/bridge.lua',
}

exports {
	'ImplCall',
	'GetImplsList',
	'GetInitializedImpls'
}
