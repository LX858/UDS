

-- ╔═══════════════════════════════════════════════════════════════════════╗
-- ║  OXLYN NOTIFYKIT · config.lua                                          ║
-- ║  Every setting a server owner touches lives in this file. Nothing here ║
-- ║  needs a restart of anything but this resource.                        ║
-- ╠═══════════════════════════════════════════════════════════════════════╣
-- ║  QUICK START                                                           ║
-- ║   1. ensure oxlyn-notifykit  — early: before your framework and the    ║
-- ║      scripts that send notifications.                                  ║
-- ║   2. server.cfg (or paste in the console to apply right away):         ║
-- ║         add_ace group.admin oxlyn.notifykit.admin allow                ║
-- ║         add_principal identifier.license:YOUR_LICENSE group.admin      ║
-- ║   3. In game: /notifyeditor ▸ pick a style ▸ Save. Done.               ║
-- ║   4. Make ESX / QBCore / ox_lib use it too: type in the server console ║
-- ║         notifykit install all        (EXPORTS.md ▸ "Frameworks")       ║
-- ║   Every export, event and option is documented in EXPORTS.md.          ║
-- ╠═══════════════════════════════════════════════════════════════════════╣
-- ║  WHAT IS WHERE                                                         ║
-- ║   Config.Locale / Framework / Debug ........ general                   ║
-- ║   Config.Look ............. how notifications look (the editor saves   ║
-- ║                             over this)                                 ║
-- ║   Config.Types ............ colours, icons, sounds and labels per type ║
-- ║   Config.Limits ........... flood protection, text limits, HTML        ║
-- ║   Config.Announce / Confirm / History ... the special formats          ║
-- ║   Config.GameSounds ....... GTA frontend sounds for the "game" pack    ║
-- ║   Config.Compat ........... drop-in answers for other notify resources ║
-- ║   Config.Commands / Permissions / Admin ... commands and who may use   ║
-- ╠═══════════════════════════════════════════════════════════════════════╣
-- ║  PRECEDENCE                                                            ║
-- ║   this file  ←  the look saved in the editor (data/settings.json)      ║
-- ║             ←  a personal look, only if AllowPlayerSettings is on      ║
-- ║   Delete data/settings.json to go back to this file for everyone.      ║
-- ║   A single notification may still pick its own style / position /     ║
-- ║   colour / icon / duration / sound (see EXPORTS.md).                   ║
-- ╚═══════════════════════════════════════════════════════════════════════╝

Config = {}

-- ═══ GENERAL ═══════════════════════════════════════════════════════════

-- Language of every text this resource shows (editor, history,
-- type labels, samples). English is always the fallback.
Config.Locale    = 'en'       -- 'en' | 'pt' | 'es' | 'fr' | 'de' | 'pl' | 'lt' | 'it' | 'tr'  (server-wide)

-- Only used for admin access and for the job / gang helpers of the server API
-- (NotifyJob / NotifyGang). Detection order is QBox → ESX → QBCore → ox_core →
-- ND_Core; force one if you run a fork that detects wrong. Notifications
-- themselves need no framework.
Config.Framework = 'auto'     -- 'auto' | 'esx' | 'qbcore' | 'qbox' | 'oxcore' | 'ndcore' | 'standalone'

-- Verbose console prints on both sides. Leave it off in production.
Config.Debug     = false

-- ═══ LOOK ══════════════════════════════════════════════════════════════
-- All of this is editable in-game (/notifyeditor). 72 styles in 9 families:
--
--   ESSENTIALS  classic · glass · soft · outline · line · split · pill · minimal
--   DEVICES     mobile · material · desktop · aqua · island · snackbar · watch · lock
--   ROLEPLAY    feed · nopixel · phone · dispatch · radio · sms · breaking · receipt
--   GAMING      achievement · trophy · levelup · quest · loot · arcade · killfeed · mission
--   CYBER       neon · cyber · hologram · terminal · glitch · synthwave · circuit · hud
--   BOLD        solid · gradient · brutal · banner · ribbon · tile · stamp · duo
--   ELEGANT     luxe · paper · frost · mono · elegant · velvet · aurora · editorial
--   COMPACT     toast · chip · dot · ticker · sidebar · ring · bubble · underline
--   PLAYFUL     comic · kawaii · sketch · retro · western · score · sticker · candy
--
-- /notifytest <style> previews one of them.

Config.Look = {
    style        = 'line',       -- default style (any name above)
    position     = 'center-left',     -- top-left · top-center · top-right · center-left · center ·
                                    -- center-right · bottom-left · bottom-center · bottom-right
    offsetX      = 0,               -- px (at 1080p) moved from the anchor, + = right
    offsetY      = 0,               -- px (at 1080p) moved from the anchor, + = down
    width        = 360,             -- px (at 1080p) — auto-width styles (pill, toast, chip …) use it as a maximum
    scale        = 0.8,             -- 0.6 – 1.6, grows with the resolution on its own (1080p = 1)
    radius       = 14,              -- base corner radius in px (each style derives its own from it)
    gap          = 10,              -- px between two notifications of the same stack
    maxVisible   = 3,               -- per position; the oldest one leaves early to make room
    stack        = 'list',          -- 'list' = one under the other · 'deck' = newest in front, the rest peeking behind
    newestFirst  = true,            -- the newest notification sits nearest to the screen edge
    animation    = 'slide',         -- 'slide' · 'glide' · 'swoop' · 'fade' · 'drop' · 'curtain' · 'reveal' · 'bounce' · 'none'
                                    -- (styles with a signature entrance — island, ribbon, mission … — keep their own)
    duration     = 5000,            -- ms, when a notification gives none (1000 – 60000)
    showProgress = true,            -- the thin bar that shows the time left
    showIcon     = true,
    showTitle    = true,            -- off = only the message (and the type label where a style has one)
    iconMotion   = true,            -- icons play a short entrance animation (pop / shake / ring per type)
    dedupe       = true,            -- the same notification again while it is still visible → "×2" instead of a copy
    markdown     = true,            -- **bold** *italic* __underline__ ~~strike~~ `code` and GTA colours ~r~ ~g~ ~b~ ~y~ …
    hideInPause  = true,            -- hide (and pause the timers) while the pause menu / a loading fade is up
    history      = true,            -- keep a log players can open with /notifications
    colors = {                      -- the panel palette most styles derive from (type colours live in Config.Types)
        surface = '#111216',        -- panel base colour
        text    = '#f4f5f7',
        accent  = '#f2f3f5',        -- neutral highlight (editor chrome, neutral styles)
    },
    sounds       = true,            -- synthesized UI sounds (Web Audio, no files)
    soundPack    = 'bubble',          -- 'soft' · 'crisp' · 'retro' · 'bubble' · 'game' (GTA frontend sounds) · 'none'
    volume       = 0.5,             -- 0.0 – 1.0
}

-- Players may change their own style / position / sound with the history
-- panel ▸ Settings (saved per player in KVP). Off by default: the look is
-- decided by admins in /notifyeditor and every save there applies to all.
Config.AllowPlayerSettings = false

-- ═══ TYPES ═════════════════════════════════════════════════════════════
-- 25 types are built in (shared/utils.lua ▸ Utils.DefaultTypes):
--   success · error · warning · info · primary · neutral · money · bank · police · ems
--   fire · mechanic · phone · message · mail · system · admin · announce · achievement
--   xp · item · vehicle · location · weather · loading
-- Change any of them here, or add your own — then use it by name:
--   exports['oxlyn-notifykit']:Notify({ type = 'gang', message = 'Turf under attack' })
-- icon  = any Font Awesome 7 Free class, an image URL / nui:// path, or an emoji
-- sound = success · error · warning · info · message · money · alert · announce · achievement · soft · none
-- Aliases used by other resources (inform, ambulance, warn, danger, primary …) resolve on their own.

Config.Types = {
    -- success = { color = '#34d399' },
    -- gang    = { label = 'Gang', color = '#a855f7', icon = 'fa-solid fa-skull', sound = 'alert' },
    -- taxi    = { label = 'Taxi', color = '#facc15', icon = 'fa-solid fa-taxi',  sound = 'message' },
}

-- ═══ LIMITS ════════════════════════════════════════════════════════════

Config.Limits = {
    perSecond     = 8,          -- flood guard: more than this in one second from the same client are queued
    queueMax      = 30,         -- beyond this the oldest queued ones are dropped
    titleLength   = 120,        -- characters kept of a title
    messageLength = 600,        -- characters kept of a message
    allowHTML     = false,      -- `html = true` on a notification renders raw HTML (trusted scripts only!)
                                -- off = every text is escaped (a player name can never inject markup)
}

-- ═══ ANNOUNCEMENTS ═════════════════════════════════════════════════════
-- exports['oxlyn-notifykit']:Announce(...) and /notifyall — a bigger, centred
-- notification for server-wide messages.

Config.Announce = {
    style    = 'mission',       -- any style; 'mission' · 'banner' · 'breaking' · 'ribbon' · 'luxe' suit it best
    position = 'top-center',
    duration = 8000,
    type     = 'announce',
    sound    = 'announce',
}

-- ═══ CONFIRM ═══════════════════════════════════════════════════════════
-- exports['oxlyn-notifykit']:Confirm({...}) → true / false / nil (timeout).
-- A notification with two keys; nothing takes the mouse.

Config.Confirm = {
    acceptKey   = 'Y',
    declineKey  = 'N',          -- N is also push-to-talk: it is disabled only while a confirm is up
    duration    = 15000,        -- ms before it answers nil
    type        = 'primary',
    disableGameControls = true, -- the game actions on those keys are blocked while the confirm is up
}

-- ═══ HISTORY ═══════════════════════════════════════════════════════════
-- /notifications opens a panel with everything a player received this
-- session: filter by type, clear, Do Not Disturb, mute.

Config.History = {
    enabled  = true,
    max      = 60,              -- entries kept per player (newest first)
    key      = '',              -- optional default key for the panel (players can rebind it in GTA settings), e.g. 'F7'
    allowDnd = true,            -- players may switch on Do Not Disturb (only announcements and confirms show)
}

-- ═══ GAME SOUNDS (soundPack = 'game') ══════════════════════════════════
-- PlaySoundFrontend(name, set) per sound. Any sound name / set works.

Config.GameSounds = {
    success     = { 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET' },
    error       = { 'CHECKPOINT_MISSED', 'HUD_MINI_GAME_SOUNDSET' },
    warning     = { 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET' },
    info        = { 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    message     = { 'Text_Arrive_Tone', 'Phone_SoundSet_Default' },
    money       = { 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
    alert       = { 'Event_Message_Purple', 'GTAO_FM_Events_Soundset' },
    announce    = { 'Boss_Message_Orange', 'GTAO_Boss_Goons_FM_Soundset' },
    achievement = { 'MEDAL_UP', 'HUD_MINI_GAME_SOUNDSET' },
    soft        = { 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET' },
}

-- ═══ COMPATIBILITY ═════════════════════════════════════════════════════
-- Scripts written for these resources keep working with no change: their
-- exports are answered here (and the manifest `provide`s the names). Each
-- layer only registers when the REAL resource is not running.
--
--   exports['esx_notify']:Notify(type, length, message, title, position)
--   exports['okokNotify']:Alert(title, message, time, type, playSound)
--   exports['mythic_notify']:SendAlert(type, text, length, style) · DoHudText · DoShortHudText · DoLongHudText
--   exports['pNotify']:SendNotification({ text, type, timeout, layout })
--   exports['t-notify']:Alert({ style, message, duration }) · Custom · Image · Icon
--   exports['brutal_notify']:SendAlert(title, message, time, type, sound)
--   exports['wasabi_notify']:notify(title, message, time, type, sound, icon, color)
--   exports['oxlyn-notify']:ShowNotification(type, title, message, duration)
--   exports['vms_notify']:Notification(title, message, time, color, icon)
--   exports['vms_notifyv2']:Notification({ title, description, time, color, icon, preset }) · TopNotification
--   exports['k5_notify']:notify(title, text, type, duration)
--   TriggerEvent('codem-notification:Create', text, type, header, duration)
--   exports['FL-Notify']:Notify(title, subTitle, content, timeout, type, position)
--   exports.bulletin:Send(message, timeout, position, progress, theme) · SendAdvanced · SendPinned · Unpin
--   exports['origen_notify']:ShowNotification(message)
--   TriggerEvent('renzu_notify:Notify', type, title, message, options)
--
-- ESX.ShowNotification, QBCore.Functions.Notify and ox_lib's lib.notify live
-- INSIDE those resources, so they are switched with one console command
-- (a one-line bridge with a backup, undone the same way):
--   notifykit install esx | qbcore | oxlib | all
--   notifykit uninstall esx | qbcore | oxlib | all
--   notifykit status

--
-- FRAMEWORKS (Config.Framework = 'auto' finds the one you run)
--   framework     notifications                          admin groups / jobs / gangs
--   ESX Legacy    notifykit install esx   (+ event)      ✔ group · job · —
--   QBCore        notifykit install qbcore (+ event)     ✔ permission · job · gang
--   QBox          same as QBCore (qbx_core)              ✔ permission · job · gang
--   ox_core       exports / ox_lib                       ✔ ace group · job group · gang group
--   ND_Core       exports / ox_lib                       ✔ groups · job · —
--   ox_lib        notifykit install oxlib (+ events)     —
--   standalone    exports / events                       ACE + identifier list
--
-- Every flag below: true = answer that resource's exports / events when it
-- is NOT running · false = never touch it (keep your own copy of it).

Config.Compat = {
    -- ─── notification resources (exports + events) ───────────────────────
    esx_notify         = true,  -- esx_notify
    okokNotify         = true,  -- okokNotify
    mythic_notify      = true,  -- mythic_notify
    pNotify            = true,  -- pNotify
    t_notify           = true,  -- t-notify
    brutal_notify      = true,  -- brutal_notify
    wasabi_notify      = true,  -- wasabi_notify
    oxlyn_notify       = true,  -- oxlyn-notify (the older OXLYN Notify System)
    vms_notify         = true,  -- vms_notify
    vms_notifyv2       = true,  -- vms_notifyv2
    k5_notify          = true,  -- k5_notify
    codem_notification = true,  -- codem-notification (CodeM mNotification)
    fl_notify          = true,  -- FL-Notify
    bulletin           = true,  -- bulletin
    origen_notify      = true,  -- origen_notify
    renzu_notify       = true,  -- renzu_notify

    -- ─── framework events (only while the owning resource is stopped) ───
    oxlibEvents        = true,  -- ox_lib:notify / ox_lib:defaultNotify   (ox_lib not started)
    qbcoreEvent        = true,  -- QBCore:Notify                          (qb-core / qbx_core not started)
    esxEvent           = true,  -- esx:showNotification                   (es_extended not started)
}

-- ═══ COMMANDS ══════════════════════════════════════════════════════════

Config.Commands = {
    editor       = 'notifyeditor',          -- in-game editor (admins) — every save applies to all players
    test         = 'notifytest',            -- /notifytest [style] [type]   a burst of samples
    style        = 'notifystyle',           -- /notifystyle <style> [global] quick style switch
    announce     = 'notifyall',             -- /notifyall <message>          announcement to everyone
    history      = 'notifications',         -- /notifications                the history panel
    access       = 'notifyaccess',          -- notifyaccess <id>             why can (or can't) a player use the admin tools
    installer    = 'notifykit',             -- notifykit status | install | uninstall | restore <esx | qbcore | oxlib | all>
                                            -- (server console; in game for admins)
}

-- Who can use what: 'everyone' | 'admin' | 'none' (command not registered)
Config.Permissions = {
    editor      = 'admin',
    test        = 'admin',
    style       = 'everyone',      -- personal style (needs Config.AllowPlayerSettings)
    globalStyle = 'admin',         -- `/notifystyle <style> global` and the editor's Save
    announce    = 'admin',         -- /notifyall and the editor's "Send to everyone"
    history     = 'everyone',
}

-- ═══ ADMIN ACCESS ══════════════════════════════════════════════════════
-- The check ALWAYS runs on the server. Access is an OR of independent
-- sources — ANY of them grants it: ACE → framework group → identifier list.
--
-- server.cfg recipe:
--   add_ace group.admin oxlyn.notifykit.admin allow
--   add_principal identifier.license:YOUR_LICENSE_HERE group.admin
--
--   ⚠ an add_ace only applies on a full server START (a resource restart is
--     not enough — paste the two lines in the server console to apply now)
--   ⚠ the license prefix is written ONCE: identifier.license:abc123
--
-- Diagnose: `notifyaccess <id>` in the server console (or in-game as an
-- admin) prints every source with its verdict and the lines to paste.

Config.Admin = {
    methods      = { 'ace', 'group', 'identifier' },
    ace          = 'oxlyn.notifykit.admin',
    groups       = { 'admin', 'superadmin', 'god' },   -- ESX groups / QB permissions (also tested as group.<name> aces — txAdmin)
    identifiers  = {
        -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    },
    allowConsole = true,                                -- console (src 0) is always admin
    debug        = false,                               -- log every allow / deny with its reason
    -- Custom integration: return true / false to decide yourself, nil to fall
    -- through to the sources above. Runs on the server.
    check = function(src)
        return nil
    end,
}

