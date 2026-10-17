

fx_version 'cerulean'
game 'gta5'

description 'lotus-multijob'
version '1.0.0'
lua54 'yes'
shared_scripts {
	'@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
	'client/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/framework.lua',
	'server/farm_rental.lua',
	'server/server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/*.js',
    'html/assets/*.css',
}

file 'stream/gen_w_am_metaldetector.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/wtmelon_y.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/wtmelon.ytyp'
-- data_file 'DLC_ITYP_REQUEST' 'stream/carrot_y.ytyp'
-- data_file 'DLC_ITYP_REQUEST' 'stream/carrot_y.ytyp'
-- data_file 'DLC_ITYP_REQUEST' 'stream/wtmelon_y.ytyp'
-- data_file 'DLC_ITYP_REQUEST' 'stream/wtmelon.ytyp'

-- lua54 'yes'