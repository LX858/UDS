fx_version 'cerulean'
game 'gta5'
description 'RTX DJ'

server_scripts {
	--'@mysql-async/lib/MySQL.lua',  -- enable this and remove oxmysql line (line 11) if you use mysql-async (only enable this for qbcore/esx framework)
	'@oxmysql/lib/MySQL.lua', -- enable this and remove mysql async line (line 10) if you use oxmysql (only enable this for qbcore/esx framework)
	'config.lua',
	'language/main.lua',
	'server/main.lua',
	'server/other.lua'
}

client_scripts {
	'config.lua',
	'language/main.lua',
	'client/main.lua'
}

files {
	'html/ui.html',
	'html/sounds/*.mp3',
	'html/*.css',
	'html/gizmoapi.js',
	'html/scripts.js',
	'html/BebasNeueBold.ttf',
	'html/dj/video.html',
	'html/dj/video.css',	
	'html/dj/video.js',
}

ui_page 'html/ui.html'

lua54 'yes'


data_file 'DLC_ITYP_REQUEST' 'stream/rtx_djn_laser_box_dj_system.ytyp'
