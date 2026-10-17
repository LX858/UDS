fx_version 'cerulean'
game 'gta5'

author 'F7 Scripts'
description 'Hệ thống nghiện cho Lá Đu Đủ'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',  -- Qbox core library (giống qbx_police)
    'config.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',  -- Load QBX global (QUAN TRỌNG!)
    'client/toons.lua',
    'client/trip.lua',
    'client/client.lua',
    'client/doctor.lua'  -- Hệ thống bác sĩ điều trị cai nghiện
}

server_scripts {
    'server/acid.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'sound/*.ogg',
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/img/*.webp',
    'html/img/thuocphien.png',
    'html/img/nghien.png',
    'html/img/avt.png'
}

data_file 'AUDIO_WAVEPACK' 'sound'

lua54 'yes'
