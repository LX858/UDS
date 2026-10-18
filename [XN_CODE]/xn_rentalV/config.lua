-- ALLGAMERS VAULT RENTAL
-- Edit this file for normal setup. Restart allgamers_capsulerent after changes.
-- Model/YTYP updates also need a client reconnect.
-- Your own framework, money, keys, prompt or target: fill in the CUSTOM block at the top of
-- server/bridge.lua (framework, money, keys) or client/bridge.lua (prompt, target, notify).
-- Manifest-loaded globals only: do not convert this resource to require/lib.require.
ScootConfig = {
    -- Language for notifications/creator: 'en', 'bs', 'de'.
    locale = 'en',

    -- FRAMEWORK: 'auto' | 'qbx' | 'qb' | 'esx' | 'standalone' | 'custom'
    -- 'auto' takes the first one running: qbx_core, qb-core, es_extended, otherwise standalone.
    -- 'custom' = your own framework. Fill in the CUSTOM block in server/bridge.lua.
    framework = 'auto',

    -- VEHICLE KEYS: 'auto' | 'qbx' | 'qb' | 'none' | 'custom'
    -- 'auto' uses qbx_vehiclekeys or qb-vehiclekeys when one is running, otherwise nothing.
    -- 'custom' = your own key script. Fill in the CUSTOM block in server/bridge.lua.
    keys = 'qb',

    -- INTERACTION: how players open the tablet and confirm returns. Only the chosen one is used.
    --   'allgamers_ui'  built-in E prompt drawn by this resource. No target resource involved.
    --   'ox_lib'        ox_lib TextUI as the E prompt. No target resource involved.
    --   'ox_target'     ox_target eye only. No E prompt.
    --   'qb-target'     qb-target eye only. No E prompt.
    --   'custom'        your own prompt and/or target. Fill in the CUSTOM block in client/bridge.lua.
    interaction = 'ox_lib',
    interactKey = 38,        -- control id, 38 = E
    interactKeyLabel = 'E',  -- what the prompt shows
    interactDistance = 3.0,  -- metres from the tablet
    targetIcon = 'fa-solid fa-car',
    prompt = { title = 'THUÊ XE TỰ ĐỘNG', scale = 1.0 }, -- allgamers_ui prompt only; scale 0.75-1.5

    -- NOTIFICATIONS: 'allgamers_ui' | 'ox_lib' | 'native' | 'custom'
    -- 'ox_lib' falls back to allgamers_ui when ox_lib is not running.
    notify = 'ox_lib',

    -- Standalone rental credits, stored per license in resource KVP (not framework money).
    standalone = { startingCash = 1000, startingBank = 0 },
    debug = false,

    -- RENTAL: price = selected plan price x vehicle multiplier.
    -- Example: Sultan on the 15-minute plan costs 150 x 1.5 = 225.
    -- One active rental per character; time keeps running while disconnected.
    rental = {
        accounts = { 'cash', 'bank' },
        plans = {
            { id = 'short', minutes = 15, price = 150 },
            { id = 'medium', minutes = 30, price = 250 },
            { id = 'long', minutes = 60, price = 400 },
        },
        -- Model must exist on the server AND fit the capsule: max width 2.3m, length 5.6m, height 2.0m.
        -- Use vanilla or streamed addon spawn names only (rs7 is not installed on this server).
        -- Images are relative to web/; add PNGs to web/images/.
        vehicles = {
            { id = 'blista', model = 'blista', label = 'Blista',
                category = 'Xe cỡ nhỏ', image = 'images/blista.png', multiplier = 1.0 },
            { id = 'biroso', model = 'biroso', label = 'Biroso',
                category = 'Thể thao mini', image = 'images/biroso.png', multiplier = 1.0 },
        },
        returnDistance = 18.0, -- How close the rental must be to open a return vault (metres).
        returnTimeout = 180,   -- Seconds to drive into an opened return bay before it can close.
        -- After rent opens: keep bay open until the renter drives out, or this many seconds.
        pickupGraceSeconds = 25,
        requestCooldownMs = 1000,
        warningSeconds = 60,   -- Notify the renter this many seconds before the rental ends.
    },

    -- WORLD TABLET AND SIGN: both are real DUI textures, not a fullscreen rent menu.
    display = {
        title = 'UNDERSTAR',
        subtitle = 'THUÊ XE TỰ ĐỘNG',
        ticker = 'CHỌN XE CỦA BẠN • BẮT ĐẦU HÀNH TRÌNH',
        accent = '#00e5b4',
        animation = false, -- Static textures: no moving highlight/sweep.
    },
    tablet = {
        width = 800, height = 1280, -- Texture resolution; keep in sync with the model/pointer mapping.
        cameraDistance = 1.20,     -- Metres in front of tablet, centred for accurate clicks.
        cameraFov = 40.0,          -- Smaller = closer view; these defaults fill about 91% of screen height.
    },

    -- NPC: already-modelled office chair, not a newly spawned chair.
    -- X is relative to kiosk centre, so the same offset works for left/right layouts.
    -- Y/Z are model-local metres; Z is the seated animation's floor-level root.
    npc = {
        enabled = true,
        model = 'a_m_y_business_03',
        offsetX = 0.289, offsetY = 0.80, z = 1.06,
        seatHeight = 0.62,       -- Pelvis target: chair cushion is ~0.51m + body clearance.
        headingOffset = 0.0,    -- Degrees relative to kiosk; 0 faces the front glass.
        animation = { dict = 'timetable@ron@ig_5_p3', clip = 'ig_5_p3_base' },
    },

    -- LIGHT STRIPS: nearest station colour wins because DUI replacement is shared.
    -- Presets are offered in the creator; arbitrary hex colours are also accepted.
    -- Physical glow strength is baked into the model; screens remain readable.
    glow = {
        color = '#00e5b4',
        presets = { '#00e5b4', '#e50000', '#ffb400', '#7a5cff', '#ff2fb0', '#ffffff' },
    },

    -- STREAMING (metres): stations are created around the player, not all at once.
    spawnDistance = 85.0,
    despawnDistance = 100.0,
    defaultSide = 'right', -- Creator default; each station can use 'left' or 'right'.

    -- CREATOR: /vaultplace and /vaultremove.
    -- Permission example: add_ace group.admin capsulerent.place allow
    -- Placed stations are saved in locations.json; normally leave locations below empty.
    placeAce = 'capsulerent.place',
    creator = {
        command = 'taochotthue', removeCommand = 'xoachotthue', adminAce = 'group.admin',
        maxDistance = 35.0, minimumSpacing = 12.0, maxLocations = 100,
        moveStep = 0.05, rotateStep = 1.0, precisionMultiplier = 0.2,
        capsuleGroundOffset = 0.0, -- Vault at terrain level; no additional Z lift.
        boothGroundOffset = 0.03, -- Rental booth only: lift 3 cm above terrain. Tablet stays on the ground.
        -- Cursor/ground snap and save use each component's offset independently.
    },
    -- Creator supports Rental booth / Freestanding tablet, each placed separately from capsule.
    -- Existing stations without version/terminal keep their original combined layout.
    -- Optional manual station: {coords={x=0,y=0,z=0},heading=0,side='right',
    --   version='tablet',terminal={coords={x=4,y=0,z=0},heading=90},name='Compact'}
    -- terminal.coords is the booth/pedestal centre; maximum separation 20m, clear of the bay.
    locations = {},

    -- MAP ICONS: creator can override these for each individual station.
    blips = {
        enabled = true, sprite = 56, color = 5, scale = 0.7,
        shortRange = true, label = 'Trạm thuê xe',
        sprites = {225, 1, 226, 523}, colors = {3, 1, 2, 5, 7, 8, 11, 15, 17, 18, 38, 46},
    },

    -- SOUND: volume 0..1; distance/refDistance are metres.
    playSounds = true,
    soundVolume = 0.4, soundDistance = 30.0, soundRefDistance = 3.0, soundRolloff = 1.4,
    -- Advanced: authored timeline is 30fps, frames 0..600. Loops stop with motion.
    sounds = {
        {frame=20,endFrame=160,file='rise_v2.ogg',volume=0.85},
        {frame=180,endFrame=250,file='door_open_v2.ogg',volume=0.6},
        {frame=350,endFrame=420,file='door_close_v2.ogg',volume=0.6},
        {frame=440,endFrame=580,file='sink_v2.ogg',volume=0.85},
    },

    -- CREATOR / RENTAL HUD THEME. Offsets are screen percentages.
    -- The world-space tablet uses display.accent above.
    ui = {
        accent = '#00e5b4', accentSecondary = '#36d9ee', panel = '#111918',
        text = '#ffffff', muted = '#aebeb9', scale = 1.0,
        currency = '$', numberLocale = 'en-US',
        menuAnchor = 'right', menuOffsetX = 2.35, menuOffsetY = 6.5,
        rentalAnchor = 'bottom-center', rentalOffsetX = 0.0, rentalOffsetY = 4.0,
    },
}
function ScootTheme() return ScootConfig.ui end
