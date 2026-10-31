

--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                        ║
    ║      ██████  ██   ██ ██      ██    ██ ███    ██                        ║
    ║     ██    ██  ██ ██  ██       ██  ██  ████   ██                        ║
    ║     ██    ██   ███   ██        ████   ██ ██  ██   H E L I C A M        ║
    ║     ██    ██  ██ ██  ██         ██    ██  ██ ██   A I R   U N I T      ║
    ║      ██████  ██   ██ ███████    ██    ██   ████                        ║
    ║                                                                        ║
    ║   OXLYN Software®  •  Helicopter Camera  •  ESX / QBCore / Qbox        ║
    ╚══════════════════════════════════════════════════════════════════════╝

    A realistic airborne law-enforcement camera (FLIR / gimbal). Sit in a
    supported helicopter, press the keybind and operate an under-nose camera:
    pan / tilt / zoom, four vision sensors (EO / NVG / IR / B&W thermal), a
    nightsun searchlight, suspect marking that pushes minimap blips to your
    whole unit, and a target lock — lock a person or vehicle and the helicopter
    auto-follows / orbits it while you run the camera.

    Multi-framework (auto-detect) • Optional job gate • EN/PT/ES/FR
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Oxlyn Software'
description 'OXLYN HeliCam — a realistic helicopter surveillance camera: gimbal FLIR OSD, EO/NVG/IR/B&W sensors, nightsun searchlight, suspect marking to the whole unit, and a target lock that auto-follows/orbits the target with the helicopter. Supported vehicles + optional job gate, keybind open/close, km/h or mph read-outs. Multi-framework, EN/PT/ES/FR.'
version '1.2.2'

-- NOTE: framework resources (es_extended / qb-core / qbx_core) are intentionally
-- NOT declared as dependencies. The bridge auto-detects whatever is running so the
-- resource loads cleanly on any (or no) framework.

shared_scripts {
    'config.lua',
    -- Locales (English is the fallback, keep it first)
    'locales/en.lua',
    'locales/pt.lua',
    'locales/es.lua',
    'locales/fr.lua',
    'shared/locale.lua',
    -- Bridges (auto-detect framework / notify system)
    'shared/bridges/framework.lua',
    'shared/bridges/notify.lua',
}

client_scripts {
    'client/main.lua',      -- open/close keybind, close key, chat command
    'client/units.lua',     -- speed units: km/h ⇄ mph (key + /helicamunits)
    'client/heli.lua',      -- runtime core: gimbal camera on the heli, zoom, autopilot follow, master loop
    'client/camera.lua',    -- scripted cam rig, vision sensors (EO/NVG/IR/B&W), searchlight, zoom
    'client/marking.lua',   -- reticle probe (LRF + contact, peds + vehicles), suspect marking, track boxes
    'client/markers.lua',   -- numbered ground markers, shared to the unit (ring + beacon)
    'client/lock.lua',      -- target lock: RMB acquisition %, auto-track state, lock boxes
    'client/hud.lua',       -- NUI bridge: open/close + throttled telemetry
}

server_scripts {
    'server/main.lua',      -- access re-validation + marking → job broadcast
}

ui_page 'html/index.html'

-- The UI ships as ONE pre-built, minified bundle (styles + scripts inlined in
-- index.html). The readable sources live in the -OPENSOURCE build.
files {
    'html/index.html',
}

-- PROTECTED BUILD.
-- Only the files below stay open so servers can fully configure and translate
-- the resource. Everything else (client / server / shared logic) is escrowed,
-- and the UI ships as a pre-built bundle.
-- NOTE: fxmanifest.lua is never encrypted by Cfx — it is always readable.
escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'README.md',
}


