resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

files {
    'data/**/carcols.meta',
    'data/**/carvariations.meta',
    'data/**/handling.meta',
    'data/**/vehiclelayouts.meta',
    'data/**/vehicles.meta',
    'audioconfig/*.dat151.rel',
    'audioconfig/*.dat54.rel',
    'sfx/**/*.awc'
}

data_file 'VEHICLE_LAYOUTS_FILE'    'data/**/vehiclelayouts.meta'
data_file 'HANDLING_FILE'           'data/**/handling.meta'
data_file 'VEHICLE_METADATA_FILE'   'data/**/vehicles.meta'
data_file 'CARCOLS_FILE'            'data/**/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE'  'data/**/carvariations.meta'

data_file 'AUDIO_GAMEDATA'          'audioconfig/aq77bmws85_game.dat'
data_file 'AUDIO_SOUNDDATA'         'audioconfig/aq77bmws85_sounds.dat'
data_file 'AUDIO_WAVEPACK'          'sfx/dlc_aq77bmws85'