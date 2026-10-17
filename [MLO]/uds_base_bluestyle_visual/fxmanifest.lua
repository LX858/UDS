fx_version "cerulean"

game "gta5"


files {
	'stream/*',
	'data/*',
    'visualsettings.dat',
}

data_file 'TIMECYCLEMOD_FILE' 'data/*'
data_file 'WEATHER_FILE' 'data/*'

client_script 'client.lua'