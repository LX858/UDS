
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'AllGamers'
version '1.0.0'
description 'AllGamers Vault Rental'

shared_scripts {
    'config.lua',

    'locales/en.lua',
    'locales/bs.lua',
    'locales/de.lua',

    'shared/translations.lua',
    'shared/locale.lua',
    'shared/color.lua',
    'shared/assets.lua',
    'shared/runtime.lua'
}

client_scripts {
    'client/prompt.lua',
    'client/bridge.lua',
    'client/blips.lua',
    'client/audio.lua',
    'client/bunker.lua',
    'client/preview.lua',
    'client/dui.lua',
    'client/placement.lua',
    'client/main.lua'
}

server_scripts {
    'server/bridge.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/**',
    'data/*.json',
    'stream/*.ytyp',
    'locations.json',
    'rentals.json'
}

data_file 'DLC_ITYP_REQUEST' 'stream/ninelabs_capsule_left.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/ninelabs_capsule_right.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/ninelabs_capsule_collision.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/ninelabs_capsule_modular.ytyp'

dependencies {
    '/onesync'
}
