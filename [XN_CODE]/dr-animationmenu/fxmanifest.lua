

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

ui_page 'html/index.html'

files {
	"animations.json",
	'html/**/*',
}

shared_script {
	"config.lua",
	"locale.lua",
	"locales/*.lua",
}

client_scripts {
	"client/main.lua",
	"client/preview.lua",

	"utils/point.lua",
	"utils/crouch.lua",
	"utils/ragdoll.lua",
}

server_script 'server/main.lua'

escrow_ignore {

	'utils/*.lua',
	'stream/*.*',
	'locale.lua',
	'locales/*.lua',
	'config.lua',
}

data_file 'DLC_ITYP_REQUEST' 'stream/taymckenzienz_rpemotes.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/rpemotesreborn_props.ytyp'

data_file 'DLC_ITYP_REQUEST' 'badge1.ytyp'

data_file 'DLC_ITYP_REQUEST' 'pata_props'

data_file 'DLC_ITYP_REQUEST' 'brummie_props'

data_file 'DLC_ITYP_REQUEST' 'copbadge.ytyp'

data_file 'DLC_ITYP_REQUEST' 'bzzz_foodpack'

data_file 'DLC_ITYP_REQUEST' 'bzzz_props'

data_file 'DLC_ITYP_REQUEST' 'bzzz_prop_torch_fire001.ytyp'

data_file 'DLC_ITYP_REQUEST' 'natty_props_lollipops.ytyp'

data_file 'DLC_ITYP_REQUEST' 'apple_1.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_food_icecream_pack.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_food_dessert_a.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_prop_give_gift.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/ultra_ringcase.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_food_xmas22.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/knjgh_pizzas.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/pata_christmasfood.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/pata_cake.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/pata_freevalentinesday.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_prop_cake_love_001.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_prop_cake_birthday_001.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_prop_cake_baby_001.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_prop_cake_casino001.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/brum_heart.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/brum_heartfrappe.ytyp'

data_file 'DLC_ITYP_REQUEST' 'stream/kaykaymods_props.ytyp'


shared_scripts {
	'@ox_lib/init.lua'
}