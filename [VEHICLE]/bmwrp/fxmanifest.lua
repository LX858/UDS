fx_version 'cerulean'
game 'gta5'


-- Design by KiaanHoang

files {
    'vehicles.meta',
    'carvariations.meta',
    'carcols.meta',
    'handling.meta',
    'vehiclelayouts.meta',
    'dlctext.meta',
    'caraddoncontentunlocks.meta'
}

data_file 'VEHICLE_METADATA_FILE'        'vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE'       'carvariations.meta'
data_file 'CARCOLS_FILE'                 'carcols.meta'
data_file 'HANDLING_FILE'                'handling.meta'
data_file 'VEHICLE_LAYOUTS_FILE'         'vehiclelayouts.meta'
data_file 'DLC_TEXT_FILE'                'dlctext.meta'
data_file 'CONTENT_UNLOCKING_META_FILE'  'caraddoncontentunlocks.meta'

client_script 'vehicle_names.lua' -- Optional, can be removed if unused
