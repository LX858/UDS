

--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                        ║
    ║      ██████  ██   ██ ██      ██    ██ ███    ██                        ║
    ║     ██    ██  ██ ██  ██       ██  ██  ████   ██                        ║
    ║     ██    ██   ███   ██        ████   ██ ██  ██   N O T I F Y K I T    ║
    ║     ██    ██  ██ ██  ██         ██    ██  ██ ██                        ║
    ║      ██████  ██   ██ ███████    ██    ██   ████                        ║
    ║                                                                        ║
    ║   OXLYN Software®  •  NotifyKit  •  ESX / QBCore / QBox / Standalone  ║
    ║   72 notification styles in 9 families, 25 coloured types, 9          ║
    ║   positions, progress / confirm / announcement formats, history      ║
    ║   panel, in-game editor (/notifyeditor), live previews, sound packs  ║
    ║   and drop-in answers for the popular notification resources.        ║
    ╚══════════════════════════════════════════════════════════════════════╝
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Oxlyn Software'
description 'Oxlyn NotifyKit — 72 notification styles, in-game editor, every framework'
version '1.0.0'

-- ============================================================
--   DEPENDENCIES — none. Frameworks (es_extended / qb-core /
--   qbx_core / ox_core / ND_Core) are auto-detected and only used
--   for admin access and the job / gang helpers of the server API.
--   Runs fully standalone.
-- ============================================================

-- ============================================================
--   REPLACING ANOTHER NOTIFICATION RESOURCE
--   Scripts that call exports['okokNotify']:Alert(...),
--   exports['mythic_notify']:SendAlert(...), exports.pNotify, t-notify,
--   brutal_notify, wasabi_notify, esx_notify, the older oxlyn-notify,
--   vms_notify / vms_notifyv2, k5_notify, codem-notification, FL-Notify,
--   bulletin, origen_notify or renzu_notify keep working: this
--   resource answers those exports / events (Config.Compat) and
--   `provide`s the names. When the real resource is still running,
--   the matching layer stands down on its own.
--   ESX / QBCore / ox_lib: `notifykit install all` in the server console.
-- ============================================================
provide 'esx_notify'
provide 'okokNotify'
provide 'mythic_notify'
provide 'pNotify'
provide 't-notify'
provide 'brutal_notify'
provide 'wasabi_notify'
provide 'oxlyn-notify'
provide 'vms_notify'
provide 'vms_notifyv2'
provide 'k5_notify'
provide 'codem-notification'
provide 'FL-Notify'
provide 'bulletin'
provide 'origen_notify'
provide 'renzu_notify'

shared_scripts {
    'config.lua',
    -- Locales (English is the fallback — keep it first)
    'locales/en.lua',
    'locales/pt.lua',
    'locales/es.lua',
    'locales/fr.lua',
    'locales/de.lua',
    'locales/pl.lua',
    'locales/lt.lua',
    'locales/it.lua',
    'locales/tr.lua',
    'shared/locale.lua',
    'shared/utils.lua',
    'shared/bridge.lua',
}

client_scripts {
    'client/main.lua',       -- NUI plumbing, look, focus, visibility, commands
    'client/keys.lua',       -- key names → virtual keys / game controls (confirm keys)
    'client/notify.lua',     -- the public API: Notify, Update, Progress, Announce, Confirm …
    'client/compat.lua',     -- answers for okokNotify / mythic / pNotify / t-notify / vms / … (open)
    'client/editor.lua',     -- /notifyeditor
    'client/history.lua',    -- /notifications
}

server_scripts {
    'server/main.lua',
    'server/installer.lua',  -- `notifykit install esx | qbcore | oxlib | all` (open)
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/*.css',
    'web/dist/*.js',
    'web/img/*',
    'web/fonts/*.woff2',
    'web/fontawesome/css/*.css',
    'web/fontawesome/webfonts/*.woff2',
}

-- Everything a server owner may need to read or edit stays readable.
-- The Cfx escrow encrypts every file that is NOT listed here, so keep
-- assets (fonts, NUI files) in the list — an encrypted font never loads.
escrow_ignore {
    -- ESCROW edition: only the configuration is open — config.lua and the locales.
    -- Every script in client/, server/ and shared/ is protected by the Cfx escrow and the
    -- NUI ships only as its build (web/dist). The imports stay readable because OTHER
    -- resources load them (@oxlyn-notifykit/imports/client.lua · server.lua) and an escrowed file
    -- cannot be loaded from another resource. Docs and assets stay plain: an encrypted
    -- font or NUI file simply never loads.
    'config.lua',
    'locales/*.lua',
    'imports/*.lua',
    'README.md',
    'EXPORTS.md',
    'CHANGELOG.md',
    'data/*',
    'web/dist/index.html',
    'web/dist/*.css',
    'web/dist/*.js',
    'web/img/*',
    'web/fonts/*',
    'web/fontawesome/**/*',
}

