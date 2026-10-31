

--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║   OXLYN-HELICAM  •  config.lua                                          ║
    ║   --------------------------------------------------------------      ║
    ║   A realistic police helicopter camera (FLIR / gimbal). Sit in a       ║
    ║   supported helicopter, press the keybind and control an under-nose    ║
    ║   camera: pan / tilt / zoom, four vision sensors, a searchlight, target ║
    ║   lock (the heli auto-follows a locked target while you pilot) and      ║
    ║   suspect marking. 100% configurable — read the comments.              ║
    ╚══════════════════════════════════════════════════════════════════════╝
]]

Config = {}

-- ════════════════════════════════════════════════════════════════════════
--  GENERAL
-- ════════════════════════════════════════════════════════════════════════

-- Active language. Must match a file in /locales (en, pt, es, fr) or your own.
Config.Locale = 'en'

-- 'auto' lets the bridge detect ESX / QBCore / Qbox automatically.
Config.Framework = 'auto'

-- Notification system used for player-facing messages OUTSIDE the camera feed
-- (in-feed messages are always drawn on the interface). 'auto' detects it.
Config.Notify = 'auto'

-- Verbose console logging. Turn OFF in production.
Config.Debug = false

-- ════════════════════════════════════════════════════════════════════════
--  ACCESS  —  WHO CAN USE THE HELICAM   (OPTIONAL)
--  ------------------------------------------------------------------------
--  A player may open the camera if ANY of these is true:
--    • Config.Access.everyone == true, OR
--    • their JOB name is in Config.Access.jobs, OR
--    • their GANG name is in Config.Access.gangs (QBCore / Qbox only), OR
--    • they pass any ACE in Config.Access.aces.
--  Set everyone = true to make the job requirement OPTIONAL (anyone in a
--  supported helicopter can use it). The server re-validates on open.
-- ════════════════════════════════════════════════════════════════════════
Config.Access = {
    everyone = false,             -- true = no job needed (anyone in a supported heli)

    jobs  = { 'police' },         -- jobs allowed to use the camera
    gangs = {},                   -- QBCore / Qbox only
    aces  = {},                   -- e.g. { 'helicam.use' }
}

-- ════════════════════════════════════════════════════════════════════════
--  UNIT / DEPARTMENT BANNER  —  shown on the feed (all OPTIONAL)
--  ------------------------------------------------------------------------
--  The agency name is chosen by the OPERATOR'S JOB, so a cop sees "LOS SANTOS
--  POLICE DEPARTMENT", a deputy sees the sheriff, etc. Leave everything blank
--  to hide the banner entirely.
-- ════════════════════════════════════════════════════════════════════════
Config.Unit = {
    -- Call-sign shown as the top-left unit id. '' = use the ui_unit locale.
    callsign = 'AIR-1',

    -- Department / agency banner per job name. Falls back to `default`.
    departmentByJob = {
        police  = 'LOS SANTOS POLICE DEPARTMENT',
        sheriff = 'BLAINE COUNTY SHERIFF',
        -- ambulance = 'LOS SANTOS AIR RESCUE',
    },

    -- Shown when the job isn't in the list above. '' = no banner.
    default = '',
}

-- ════════════════════════════════════════════════════════════════════════
--  SUPPORTED VEHICLES  —  WHICH HELICOPTERS CARRY THE CAMERA
--  ------------------------------------------------------------------------
--  The player must be INSIDE one of these to open the camera. Model names are
--  matched case-insensitively.
-- ════════════════════════════════════════════════════════════════════════
Config.Vehicles = {
    -- If true, ANY helicopter (game heli class 15) can use the camera and the
    -- `models` list below is ignored. If false, only the listed models work.
    allowAllHelis = false,

    -- Explicit whitelist (used when allowAllHelis = false).
    -- Use the vehicle's SPAWN NAME, exactly as you spawn it. Addon helicopters
    -- work here too (matched by model hash), e.g. 'pd_heli', 'so_heli'.
    models = {
        'polmav',        -- police maverick
        'maverick',
        'buzzard',
        'buzzard2',
        'frogger',
        'valkyrie',
        'annihilator',
    },

    -- Can the DRIVER/pilot operate the camera? true = yes (the heli then
    -- auto-follows a locked target). Passengers can always operate it. Set
    -- false to force a dedicated, non-pilot camera operator seat.
    driverCanOperate = true,

    -- Tell the player when the aircraft they are in has NO camera fitted (i.e.
    -- it is a helicopter, but not one of the supported models above). Set false
    -- to fail silently instead. Only ever fires when allowAllHelis = false.
    notifyUnsupported = true,
}

-- ════════════════════════════════════════════════════════════════════════
--  CONTROLS  —  OPEN / CLOSE KEYBIND  +  in-feed key hints
--  ------------------------------------------------------------------------
--  toggleKey is a REAL rebindable keybind (GTA Settings > Key Bindings).
--  It OPENS the camera when you're in a supported heli, and CLOSES it while
--  the feed is up. Backspace also closes the feed.
-- ════════════════════════════════════════════════════════════════════════
Config.Controls = {
    -- Default key for opening / closing the camera, e.g. 'F5', 'END', 'HOME'.
    --
    -- IMPORTANT — this is only the DEFAULT, applied the FIRST time a player
    -- loads the resource. FiveM then saves that binding in the player's own
    -- profile, so editing this value later will NOT move an already-bound key.
    -- To change it after that, either:
    --   • rebind it in GTA Settings > Key Bindings > FiveM > "HeliCam", or
    --   • have the player run:  unbind keyboard F5      (then restart)
    -- Every player can rebind it themselves at any time, which is the point.
    toggleKey = 'F10',

    -- IN-FEED KEYS — these are REAL bindings, not just hint labels: change one
    -- here and the camera reads the new key (and the hint bar shows it).
    -- Accepted: B C E F G H Q R V X Z, 1-9, SPACE, SHIFT, CTRL, ALT, TAB,
    --           ENTER, BACKSPACE, arrows (LEFT/RIGHT/UP/DOWN), RMB, LMB,
    --           F1 F2 F3 F5 F6 F7 F8.  Anything else keeps the default below.
    --
    -- IF YOU BIND toggleKey ONTO ONE OF THESE (E is the usual one), the in-feed
    -- action wins the press while the feed is up and BACKSPACE closes the
    -- camera — a single key can no longer fire both at once.
    look       = 'Mouse',      -- display only (the gimbal is always the mouse)
    zoom       = 'Scroll',     -- display only (the wheel is always the zoom)
    mode       = 'F',          -- cycle vision sensor
    spotlight  = 'E',          -- toggle searchlight
    mark       = 'G',          -- mark the reticle contact (suspect blip)
    lock       = 'RMB',        -- acquire / release target lock (heli follows)
    recenter   = 'SPACE',      -- snap the gimbal forward / level
    point      = 'X',          -- drop a numbered ground marker at the aim point
    clearPts   = 'C',          -- clear all ground markers
    close      = 'Backspace',  -- close the camera feed (display only, fixed key)
}

-- ════════════════════════════════════════════════════════════════════════
--  UNITS  —  SPEED READ-OUTS IN KM/H  OR  MPH
--  ------------------------------------------------------------------------
--  Every speed on the interface (G/S ground speed, TGT SPD of a locked
--  vehicle, and the plate · speed tag drawn under a tracked vehicle) is
--  printed in the unit chosen here. Altitude / range stay metric.
--  Operators can also flip the unit live while the feed is up.
-- ════════════════════════════════════════════════════════════════════════
Config.Units = {
    -- Default speed unit for everyone: 'kmh' or 'mph'.
    speed = 'kmh',

    -- Let the operator switch km/h ⇄ mph themselves (the key below and the
    -- /helicamunits command). false = locked to the value above for everyone.
    allowToggle = false,

    -- Key that flips km/h ⇄ mph while the camera is open. Read as a RAW key so
    -- it keeps working even though the camera disables the game controls —
    -- which means ANY key can be used here, not just the ones GTA exposes.
    -- Accepts a single letter or digit ('U', '7') or a name:
    --   F1..F12, NUMPAD0..NUMPAD9, INSERT, DELETE, HOME, END, PAGEUP,
    --   PAGEDOWN, TAB, SPACE, ENTER, BACKSPACE, ARROWS (LEFT/UP/RIGHT/DOWN),
    --   COMMA, PERIOD, SLASH, MINUS, EQUALS, SEMICOLON, QUOTE, GRAVE,
    --   LBRACKET, RBRACKET, BACKSLASH, ADD, SUBTRACT, MULTIPLY, DIVIDE.
    toggleKey = 'U',

    -- Remember each player's own choice between sessions (stored on their
    -- client, so it survives a reconnect). false = always start on `speed`.
    remember = true,
}

-- ════════════════════════════════════════════════════════════════════════
--  GROUND MARKERS  —  drop numbered points where the camera is aimed
--  ------------------------------------------------------------------------
--  Press the point key (X) to drop a numbered marker on the surface under the
--  reticle (a ring + number in the world). Great for calling out positions to
--  ground units. Clear them all with the clear key (C); they also clear on close.
-- ════════════════════════════════════════════════════════════════════════
Config.Markers = {
    enabled = false,
    color   = { r = 235, g = 55, b = 45 },    -- designator colour (ring/pole/tag)

    -- DESIGNATOR LOOK — a rotating segmented ring on the deck, a surveyed
    -- centre cross, a ticked vertical pole with a diamond head, and a
    -- DESIGNATION PLATE (zero-padded number on a slab with corner ticks and a
    -- down-chevron) with the slant range under it.
    size        = 9.0,        -- designator ring diameter (metres)
    height      = 18.0,       -- survey-pole height (metres)
    segments    = 6,          -- arc segments in the rotating ring
    rotateSpeed = 0.018,      -- ring rotation (deg per ms; 0 = static)
    showDistance = true,      -- show the viewer's range under the number

    max     = 12,                             -- oldest is dropped past this many
    range   = 1000.0,                         -- max drop distance (metres)

    -- How long a point lives before it removes itself (seconds). A point that
    -- was shared with the unit is normally only cleared by the operator who
    -- dropped it, so without this an operator who disconnects leaves their
    -- survey poles standing in the world for everybody else. 0 = never expire
    -- (the old behaviour: they stay until someone clears them).
    ttl = 600,

    -- How far away (metres) each viewer draws a shared marker. This is a
    -- performance limit for people on the ground. The OPERATOR always sees the
    -- points they can reach: while the camera is open the range above is used
    -- instead, measured from the camera, so a point dropped 900 m away is still
    -- drawn for the person who dropped it.
    viewDistance = 600.0,

    -- Who SEES a dropped marker. 'operatorJob' = the operator's own job (and
    -- anyone in the same helicopter). Or hard-list jobs, e.g. { 'police','sheriff' }.
    shareWith = 'operatorJob',
}

-- ════════════════════════════════════════════════════════════════════════
--  CAMERA  &  VISION SENSORS
--  ------------------------------------------------------------------------
--  The gimbal hangs under the helicopter. The mouse pans / tilts it, the
--  wheel zooms. Sensors cycle with the mode key; disable any you don't want.
-- ════════════════════════════════════════════════════════════════════════
Config.Camera = {
    -- Where the camera sits relative to the helicopter (metres, local offset:
    -- x = right, y = forward, z = up). Used as the FALLBACK when the heli has
    -- no factory camera bone (see mountBone below).
    mount = { x = 0.0, y = 1.2, z = -1.1 },

    -- Helis with a FACTORY camera ball (polmav, buzzard…) expose a bone for it.
    -- If present we mount OUR lens right there so its housing isn't in the
    -- frame (you look FROM the camera, not AT it). `mountBoneDrop` nudges the
    -- lens just below the housing so no geometry is in view. Empty '' disables.
    mountBone     = 'searchlight',
    mountBoneDrop = 0.55,      -- metres below the bone (clear the housing)

    -- OPTIONAL per-model mount overrides (local offsets), keyed by spawn name,
    -- used only when the bone isn't found. Fine-tune odd airframes here.
    mountByModel = {
        -- polmav = { x = 0.0, y = 2.4, z = -1.5 },
    },

    -- Field of view at default zoom, and the tight / wide limits.
    defaultFov = 50.0,
    minFov     = 6.0,    -- most zoomed IN  (long-range surveillance)
    maxFov     = 65.0,   -- most zoomed OUT
    zoomStep   = 2.5,    -- FOV change per scroll notch

    -- OPTIONAL: let the PILOT keep flying the helicopter while the camera is
    -- open (fly with the KEYBOARD — W/S/A/D + Q/E/Shift/Ctrl — while the MOUSE
    -- runs the gimbal). When true there is NO autopilot (no auto-hover, no
    -- auto-follow) — you fly it yourself. false = the heli flies itself
    -- (hover when idle, orbit a locked target). Passengers are unaffected.
    pilotCanFly = false,

    -- Gimbal look limits (degrees). Pitch lets you look from level to straight down.
    minPitch = -90.0,
    maxPitch =  15.0,

    -- Mouse gimbal sensitivity (scaled down automatically the more you zoom in).
    sensitivity = 2.2,

    -- Smoothing of the gimbal (higher = snappier, lower = heavier/cinematic).
    smoothing = 10.0,

    -- Vision sensors, cycled with the mode key. `id` is fixed (code hooks it).
    --   normal       = plain optical (colour)
    --   nightvision  = light amplification (green)
    --   thermal      = full white-hot infrared (see-through)
    --   bwthermal    = black & white world, heat only on people / vehicles
    modes = {
        { id = 'normal',      enabled = true, label = 'locale:mode_normal' },
        { id = 'nightvision', enabled = true, label = 'locale:mode_nightvision' },
        { id = 'thermal',     enabled = true, label = 'locale:mode_thermal' },
        { id = 'bwthermal',   enabled = true, label = 'locale:mode_bwthermal' },
    },

    -- Thermal wall thickness the see-through can penetrate. HIGH keeps hot
    -- targets visible through buildings and at any range. 0 = engine default.
    seethroughThickness = 2500.0,

    -- We draw our OWN gimbal-aimed beam that already shines out of the heli
    -- toward where the camera looks. On helis that ALSO have a factory
    -- searchlight (polmav…) we keep the vanilla one OFF so there's only ONE
    -- light (ours). Set true only if you'd rather use the heli's native
    -- searchlight instead — not recommended (it aims by the pilot, not the gimbal).
    useHeliSearchlight = false,

    -- Nightsun / searchlight (toggled with the light key). It raycasts to the
    -- surface the gimbal aims at, so it lands correctly from any altitude, and
    -- the wheel resizes the beam while the light is ON.
    spotlight = {
        enabled    = true,
        maxRange   = 400.0,  -- furthest surface the beam can reach (metres)
        intensity  = 1.4,    -- brightness multiplier (helis fly high → brighter)
        radius     = 9.0,    -- default cone size
        minRadius  = 3.0,    -- tightest beam (wheel up)
        maxRadius  = 20.0,   -- widest beam (wheel down)
        radiusStep = 1.0,    -- wheel step per notch
        color      = { r = 235, g = 245, b = 255 },
    },
}

-- ════════════════════════════════════════════════════════════════════════
--  TARGET LOCK  &  HELI AUTO-FOLLOW
--  ------------------------------------------------------------------------
--  Aim the reticle at a person or vehicle and press the lock key. An ACQ %
--  builds while they stay in the lock ring; at 100% the target is LOCKED and
--  the gimbal auto-tracks it. If the OPERATOR IS PILOTING the helicopter, the
--  heli then AUTO-FOLLOWS / orbits the target at the distance & height below.
--  A lock is never lost by distance — only by the target dying, despawning or
--  leaving the camera line of sight (unless a thermal sensor is active).
-- ════════════════════════════════════════════════════════════════════════
Config.Lock = {
    enabled = true,

    -- Seconds a target must stay in the lock ring to reach 100% lock.
    lockTime = 1.5,

    -- Radius of the central lock ring (fraction of screen height). Bigger =
    -- easier / more forgiving on moving targets.
    lockRadius = 0.11,

    -- ACQUISITION range only (metres) — how far a target can be to START a
    -- lock. Once locked, distance no longer matters.
    maxRange = 400.0,

    -- Outside a thermal sensor the target must be in line of sight. When a
    -- locked target ducks under cover the lock signal decays and, if it stays
    -- hidden past losGraceSeconds, drops. Thermal sees through walls.
    requireLos      = true,
    losGraceSeconds = 4.0,
    hiddenHold      = 700,   -- ms of continuous occlusion before decay starts

    -- What can be locked.
    peds     = true,
    vehicles = true,

    -- When aiming at a vehicle that has people inside, target the VEHICLE, not
    -- its occupants — so the reticle marks the car instead of the passengers.
    ignoreVehicleOccupants = true,

    -- Only used for the on-screen distance / height read-outs.
    followDistance = { min = 20.0, max = 120.0 },
    followHeight   = { min = 15.0, max = 90.0 },

    -- ── HELI AUTO-FOLLOW (autopilot) ────────────────────────────────────
    follow = {
        -- Master toggle. false = locking only auto-tracks the gimbal, the pilot
        -- flies manually (no autopilot).
        enabled = false,

        -- Only take over the flight when the operator is the PILOT (driver).
        -- If a passenger operates the camera, the human pilot keeps flying.
        onlyPilot = false,

        -- Orbit geometry: the heli circles the target at this radius & height.
        radius = 60.0,   -- horizontal orbit radius (metres)
        height = 55.0,   -- altitude above the target (metres)
        speed  = 30.0,   -- cruise speed of the autopilot (m/s)

        -- While the camera is open, you are the pilot and NOTHING is locked,
        -- hold an auto-hover at the current position so the heli doesn't fall
        -- while you run the gimbal. false = the heli keeps its momentum (best
        -- with a dedicated co-pilot). Closing the camera always returns control.
        hoverWhenIdle = true,
    },
}

-- ════════════════════════════════════════════════════════════════════════
--  SUSPECT MARKING  —  tag a target, the whole unit sees a minimap blip
--  ------------------------------------------------------------------------
--  Aim the reticle at a person and press the mark key. A blip is pushed to
--  everyone doing your job (or the jobs below) for `duration` seconds.
-- ════════════════════════════════════════════════════════════════════════
Config.Marking = {
    enabled = true,

    -- Max distance (camera → target) a mark will lock (metres).
    maxRange = 450.0,

    -- How long the blip / box stays before it must be refreshed (seconds).
    duration = 15,

    -- Re-mark cooldown so it can't be spammed (seconds).
    cooldown = 1.5,

    -- Who receives the minimap blips. 'operatorJob' = everyone doing the same
    -- job as the operator. Or hard-list jobs, e.g. { 'police', 'sheriff' }.
    shareWith = 'operatorJob',

    -- Mark NPCs too (not just players)? NPC blips pin to the mark position.
    allowNpc = true,

    -- Minimap blip styling.
    blip = {
        sprite = 1,            -- 1 = round dot; try 458 (suspect), 303 (target)
        color  = 1,            -- 1 = red
        scale  = 0.9,
        label  = 'locale:blip_marked',
        shortRange = false,
        flashOnTag = true,
    },
}

