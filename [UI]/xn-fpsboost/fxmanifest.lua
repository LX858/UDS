

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name         'oxlyn-fpsboost'
author       'Oxlyn Software'
description  'Oxlyn FPS Boost - FPS monitor and optimiser with a liquid glass panel, real benchmarks, entity cleanup and an adaptive layer (ESX / QBCore / Qbox / standalone)'
version      '2.0.2'
repository   'https://github.com/oxlyn-software/oxlyn-fpsboost'

-- The whole interface is a plain HTML/CSS/JS page. There is no build step and
-- no framework: what you see in html/ is exactly what the game loads.
ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    -- Languages are listed one by one instead of locales/*.lua so the order is
    -- guaranteed: the glob is not promised to be alphabetical on every file
    -- system, and config.lua always has to come first.
    'locales/pt.lua',
    'locales/en.lua',
    'locales/es.lua',
    'locales/fr.lua',
    'locales/de.lua',
    'locales/pl.lua',
    'locales/nl.lua',
    'locales/it.lua',
    'locales/tr.lua',
    'locales/ru.lua',
    'locales/cs.lua',
    'locales/sv.lua',
    'shared/bridge.lua',
}

client_scripts {
    'client/state.lua',      -- settings, presets and per-machine storage
    'client/metrics.lua',    -- entity pools, ping, memory, estimates
    'client/fps.lua',        -- the measuring engine (the only per-frame thread)
    'client/boost.lua',      -- applies the settings to the game
    'client/adaptive.lua',   -- temporary overlay (paused / away / indoors)
    'client/cleanup.lua',    -- entity cleanup
    'client/hud.lua',        -- floating HUD
    'client/preview.lua',    -- before/after benchmark
    'client/main.lua',       -- commands, keys, NUI bridge
}

server_scripts {
    'server/main.lua',
}

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/util.js',
    'html/js/charts.js',
    'html/js/settings.js',
    'html/js/app.js',
}
