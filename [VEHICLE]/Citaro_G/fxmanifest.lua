fx_version 'cerulean'

games { 'gta5' }

author 'GlitchXP'
description 'Mercedes Benz Citaro G'
version '1.0'
lua54 'yes'

files {
    'stream/**/*.ytd',
    'stream/**/*.yft',
    'data/**/*.meta',
}

data_file 'HANDLING_FILE' 'data/**/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/**/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/**/carcols.meta'

escrow_ignore {
	'stream/**/*.ytd',
}