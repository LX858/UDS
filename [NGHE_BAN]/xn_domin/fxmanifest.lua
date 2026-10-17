name 'Prospecting'
author 'glitchdetector'
contact 'glitchdetector@gmail.com'

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Prospect for treasure in key locations'
details [[
    Inspired by the Prospect minigame in MySims
    Metal detector model by Vartanyan
    https://www.turbosquid.com/3d-models/3d-metal-detector/1138741
    Converted by glitchdetector
    Yes, I did actually buy it for $11
]]

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory'
}

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

files {
    'lang.json'
}

client_scripts {
    'scripts/cl_multilingual.lua',
    'scripts/cl_prospecting.lua',
    'scripts/cl_prospect.lua'
}

server_scripts {
    'scripts/sv_prospecting.lua',
    'scripts/sv_locations.lua'
}

server_script 'interface.lua' -- Keep for external resources that depend on prospecting

server_exports {
    'AddProspectingTarget',  -- x, y, z, data
    'AddProspectingTargets', -- list
    'StartProspecting',      -- player
    'StopProspecting',       -- player
    'IsProspecting',         -- player
    'SetDifficulty',         -- modifier
}
