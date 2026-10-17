fx_version "cerulean"
game "gta5"

this_is_a_map 'yes'

version '1.0.2'

files {
  'stream/streamedYtyps/apa_int_mp_stilts_a.ytyp',
  'stream/streamedYtyps/ba_int_01_ba.ytyp',
  'stream/streamedYtyps/ex_int_office_02b_dlc.ytyp',
  'stream/streamedYtyps/ex_int_office_03b_dlc.ytyp',
  'stream/streamedYtyps/m23_2_mp2023_02_dlc_int_4.ytyp',
  'stream/streamedYtyps/sf_dlc_int_01_sec.ytyp',
  'stream/streamedYtyps/sf_dlc_int_02_sec.ytyp',
  'audio/**/*.rel',
  'stream/energy_c_conces_props.ytyp',
  'stream/energy_conce_elevator_met.ytyp',
  'stream/sm_frag_anim_tut.ytyp',
}

data_file 'AUDIO_GAMEDATA' 'audio/cl_conce_door_game.dat'
data_file 'DLC_ITYP_REQUEST' 'stream/streamedYtyps/apa_int_mp_stilts_a.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/streamedYtyps/ba_int_01_ba.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/streamedYtyps/ex_int_office_02b_dlc.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/streamedYtyps/ex_int_office_03b_dlc.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/streamedYtyps/m23_2_mp2023_02_dlc_int_4.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/streamedYtyps/sf_dlc_int_01_sec.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/streamedYtyps/sf_dlc_int_02_sec.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/energy_c_conces_props.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/energy_conce_elevator_met.ityp'
data_file 'DLC_ITYP_REQUEST' 'stream/sm_frag_anim_tut.ityp' 


client_scripts {
  'spawn-vehicles/*.lua',
}

escrow_ignore {
  'spawn-vehicles/*.lua',
  'stream/logo/*.ydr'
}
