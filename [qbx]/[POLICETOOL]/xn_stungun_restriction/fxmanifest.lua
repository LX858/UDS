

fx_version 'cerulean'
game 'gta5'

name 'xn_police_weapon_restriction'
author 'XN_CODE'
description 'Police Weapon Restriction System - Stun Gun & Nightstick for QBX Core'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/backup.lua'
}

server_scripts {
    'server/main.lua',
    'services/main.js'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'