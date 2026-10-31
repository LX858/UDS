

Locales = Locales or {}

Locales['en'] = {
    -- ── HeliCam access / lifecycle ──────────────────────────────────────
    no_access         = 'You are not authorised to use the helicopter camera.',
    not_in_heli       = 'You must be in a supported helicopter.',
    heli_unsupported  = 'This helicopter has no camera fitted.',
    need_operator_seat= 'Move to a passenger seat to operate the camera.',
    cam_online        = 'Camera online.',
    marker_dropped    = 'Marker dropped',
    beam_hint         = 'Shift + Scroll = beam width',
    markers_cleared   = 'Markers cleared',
    cam_in_use        = 'This helicopter camera is already being operated.',
    cam_link_failed   = 'Camera link failed — no answer from the server. Try again.',
    cam_closed_exit   = 'Camera closed — left the helicopter.',
    cam_reset         = 'Camera interface reset.',
    ui_unit           = 'AIR UNIT',
    ui_recenter       = 'GIMBAL RE-CENTERED',
    blip_marked       = 'Marked Target',
    ui_follow         = 'FOLLOW',
    ui_hover          = 'AUTO-HOVER',
    ui_mark_flash     = 'TARGET MARKED',

    -- ── Lifecycle ───────────────────────────────────────────────────────
    deploying        = 'Deploying drone…',
    drone_online     = 'UAV link established.',
    drone_recalled   = 'Drone recalled.',
    drone_lost       = 'Signal lost — drone disconnected out of range.',
    drone_crashed    = 'Drone destroyed.',
    drone_standby    = 'Drone holding position — standby.',

    -- ── Signal ──────────────────────────────────────────────────────────
    signal_weak      = 'Signal weak — you are drifting out of range.',
    signal_critical  = 'Signal critical — return toward the operator.',
    signal_failing   = 'CONNECTION FAILING',
    return_operator  = 'RETURN TO OPERATOR',
    signal_regained  = 'Signal re-established.',

    -- ── Battery ─────────────────────────────────────────────────────────
    battery_low      = 'Battery low (%d%%).',
    battery_critical = 'Battery critical (%d%%) — land soon.',
    battery_empty    = 'Battery depleted — drone landing.',

    -- ── Vision modes (real gimbal sensor codes — shown on the OSD) ──────
    mode_normal      = 'EO',
    mode_nightvision = 'NVG',
    mode_thermal     = 'IR WHOT',
    mode_bwthermal   = 'BW TGT',
    mode_recon       = 'EO BW',

    -- ── Spotlight ───────────────────────────────────────────────────────
    spotlight_on     = 'Spotlight ON',
    spotlight_off    = 'Spotlight OFF',

    -- ── Tagging ─────────────────────────────────────────────────────────
    tag_marked       = 'Target tagged — relayed to your unit.',
    tag_none         = 'No target in the reticle.',
    tag_out_of_range = 'Target out of tagging range.',
    tag_cooldown     = 'Tag recharging…',
    blip_tagged      = 'Tagged Suspect',
    blip_drone       = 'UAV Drone',

    -- ── HUD (rendered inside the NUI) ───────────────────────────────────
    ui_uav           = 'OXLYN UAV-01',
    ui_rec           = 'REC',
    ui_link          = 'LINK',
    ui_no_signal     = 'NO SIGNAL',
    ui_acquiring     = 'ACQUIRING LINK…',
    ui_battery       = 'BATT',
    ui_signal        = 'SIGNAL',
    ui_altitude      = 'ALT',
    ui_speed         = 'SPD',
    ui_range         = 'RANGE',
    ui_heading       = 'HDG',
    ui_mode          = 'MODE',
    ui_zoom          = 'ZOOM',
    ui_operator      = 'OPERATOR',
    ui_target        = 'TARGET LOCK',
    ui_spotlight     = 'LIGHT',
    ui_meters        = 'm',
    ui_agl           = 'AGL',

    -- Camera views + contact/track OSD terms
    ui_cam_gimbal    = 'CAM 1 · GIMBAL',
    ui_cam_ext       = 'CAM 2 · AIRFRAME',
    ui_contact       = 'CONTACT',
    ui_trk           = 'TRK',
    ui_mark          = 'TARGET MARKED',
    ui_lgt           = 'LGT',
    ui_sns           = 'SNS',
    ui_lrf           = 'LRF',
    ui_gps           = 'GPS',
    ui_vs            = 'VS',
    ui_tsr           = 'TSR',
    ui_tsr_ready     = 'TSR RDY',

    -- ── Target lock ─────────────────────────────────────────────────────
    lock_acquired  = 'Target locked — tracking.',
    lock_released  = 'Lock released.',
    lock_lost      = 'Lock lost — target out of reach.',
    lock_no_target = 'Nothing to lock under the reticle.',
    ui_lock        = 'LOCK',
    ui_acq         = 'ACQ',
    ui_ctrl_lock   = 'Lock',

    -- ── Standby widget + power-off ──────────────────────────────────────
    ui_standby     = 'UAV STANDBY',
    ui_holding     = 'HOLDING',
    ui_tracking    = 'TRACKING',
    ui_reenter     = 'use item to re-enter',
    ui_poweroff    = 'POWERING OFF',
    ui_ctrl_standby = 'Standby',
    ui_ctrl_poweroff = 'Power off',

    -- ── Taser ───────────────────────────────────────────────────────────
    taser_fired        = 'Taser discharged.',
    taser_empty        = 'Taser cartridges spent.',
    taser_no_target    = 'No target under the reticle.',
    taser_out_of_range = 'Too far for the taser — close in.',
    taser_cooldown     = 'Taser recharging…',

    -- Control hints (bottom bar)
    ui_ctrl_move     = 'Move',
    ui_ctrl_updown   = 'Up / Down',
    ui_ctrl_ascend   = 'Ascend',
    ui_ctrl_descend  = 'Descend',
    ui_ctrl_boost    = 'Boost',
    ui_ctrl_look     = 'Look',
    ui_ctrl_zoom     = 'Zoom',
    ui_ctrl_mode     = 'Sensor',
    ui_ctrl_view     = 'Camera',
    ui_ctrl_light    = 'Light',
    ui_ctrl_tag      = 'Mark',
    ui_ctrl_taser    = 'Taser',
    ui_ctrl_exit     = 'Recall',

    -- ── Speed units (km/h ⇄ mph) ────────────────────────────────────────
    ui_kmh        = 'km/h',
    ui_mph        = 'mph',
    ui_ctrl_units = 'Units',
    units_kmh     = 'UNITS · KM/H',
    units_mph     = 'UNITS · MPH',
    units_locked  = 'The speed unit is fixed by the server.',
}

