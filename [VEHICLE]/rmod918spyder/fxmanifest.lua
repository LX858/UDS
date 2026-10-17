fx_version 'cerulean'
game 'gta5'

lua54 'yes'
 
files {
    'carcols.meta',
    'vehicles.meta',
    'carvariations.meta',
    'handling.meta',
}

escrow_ignore {
	'*.meta',
  'stream/*.ytd',    
  'stream/**/*.ytd'  

}

data_file 'CARCOLS_FILE' 'carcols.meta'
data_file 'HANDLING_FILE' 'handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'carvariations.meta'
