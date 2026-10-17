fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
this_is_a_map 'yes'

name 'scully_cayoperico'
author 'Scullyy / READY integration for Understar'
version '1.0.2-understar-ready'
license 'GPL-3.0'
repository 'https://github.com/Scullyy/scully_cayoperico'
description 'Dual-map Cayo Perico + San Andreas loader, packaged for use with tstudio_cayo_bridge.'

dependencies {
    '/server:7290',
    'ox_lib'
}

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/safety.lua',
    'client/main.lua'
}

server_script 'server/main.lua'

files {
    'locales/*.json',
    'config.lua',
    'data/*.lua'
}

ox_libs {
    'locale'
}
