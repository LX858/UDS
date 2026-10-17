fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'SonHoang'
description 'SonHoang Police Vehicle V1'
version '1.8'

files {
	'data/**/*.meta',
    'audioconfig/*.dat151.rel',
    'audioconfig/*.dat54.rel',
    'sfx/**/*.awc'
}

-- Do not change
data_file 'VEHICLE_LAYOUTS_FILE' 'data/**/vehiclelayouts.meta'
data_file 'HANDLING_FILE' 'data/**/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/**/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/**/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/**/carvariations.meta'

data_file 'AUDIO_GAMEDATA' 'audioconfig/ta014srt8_game.dat'
data_file 'AUDIO_SOUNDDATA' 'audioconfig/ta014srt8_sounds.dat'
data_file 'AUDIO_WAVEPACK' 'sfx/dlc_ta014srt8'

client_script 'data/**/vehiclenames.lua'

escrow_ignore {
    "stream/**/*.ytd",
    "data/**/*.meta",
    "data/**/vehiclenames.lua",
    "stream/**/mods/liveries/*.yft",
    "stream/**/mods/screens/*.yft"
}
