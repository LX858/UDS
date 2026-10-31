

Locales = Locales or {}

Locales['pt'] = {
    -- ── Acesso / ciclo de vida da HeliCam ───────────────────────────────
    no_access         = 'Não estás autorizado a usar a câmara do helicóptero.',
    not_in_heli       = 'Tens de estar num helicóptero suportado.',
    heli_unsupported  = 'Este helicóptero não tem câmara instalada.',
    need_operator_seat= 'Vai para um lugar de passageiro para operar a câmara.',
    cam_online        = 'Câmara online.',
    marker_dropped    = 'Marcador colocado',
    beam_hint         = 'Shift + Scroll = largura do feixe',
    markers_cleared   = 'Marcadores limpos',
    cam_in_use        = 'A câmara deste helicóptero já está a ser operada.',
    cam_link_failed   = 'Ligação à câmara falhou — sem resposta do servidor. Tenta outra vez.',
    cam_closed_exit   = 'Câmara fechada — saíste do helicóptero.',
    cam_reset         = 'Interface da câmara reposta.',
    ui_unit           = 'UNIDADE AÉREA',
    ui_recenter       = 'GIMBAL RECENTRADO',
    blip_marked       = 'Alvo Marcado',
    ui_follow         = 'A SEGUIR',
    ui_hover          = 'AUTO-HOVER',
    ui_mark_flash     = 'ALVO MARCADO',

    -- ── Ciclo de vida ───────────────────────────────────────────────────
    deploying        = 'A lançar o drone…',
    drone_online     = 'Ligação ao UAV estabelecida.',
    drone_recalled   = 'Drone recolhido.',
    drone_lost       = 'Sinal perdido — drone desligado fora de alcance.',
    drone_crashed    = 'Drone destruído.',
    drone_standby    = 'Drone a manter posição — standby.',

    -- ── Sinal ───────────────────────────────────────────────────────────
    signal_weak      = 'Sinal fraco — estás a afastar-te do alcance.',
    signal_critical  = 'Sinal crítico — regressa em direção ao operador.',
    signal_failing   = 'LIGAÇÃO A FALHAR',
    return_operator  = 'REGRESSA AO OPERADOR',
    signal_regained  = 'Sinal restabelecido.',

    -- ── Bateria ─────────────────────────────────────────────────────────
    battery_low      = 'Bateria fraca (%d%%).',
    battery_critical = 'Bateria crítica (%d%%) — aterra em breve.',
    battery_empty    = 'Bateria esgotada — o drone vai aterrar.',

    -- ── Modos de visão (códigos de sensor reais — mostrados no OSD) ─────
    mode_normal      = 'EO',
    mode_nightvision = 'NVG',
    mode_thermal     = 'IR WHOT',
    mode_bwthermal   = 'BW TGT',
    mode_recon       = 'EO BW',

    -- ── Holofote ────────────────────────────────────────────────────────
    spotlight_on     = 'Holofote LIGADO',
    spotlight_off    = 'Holofote DESLIGADO',

    -- ── Marcação ────────────────────────────────────────────────────────
    tag_marked       = 'Alvo marcado — enviado à tua unidade.',
    tag_none         = 'Nenhum alvo na mira.',
    tag_out_of_range = 'Alvo fora do alcance de marcação.',
    tag_cooldown     = 'Marcação a recarregar…',
    blip_tagged      = 'Suspeito Marcado',
    blip_drone       = 'Drone UAV',

    -- ── HUD ─────────────────────────────────────────────────────────────
    ui_uav           = 'OXLYN UAV-01',
    ui_rec           = 'REC',
    ui_link          = 'LIGAÇÃO',
    ui_no_signal     = 'SEM SINAL',
    ui_acquiring     = 'A OBTER LIGAÇÃO…',
    ui_battery       = 'BAT',
    ui_signal        = 'SINAL',
    ui_altitude      = 'ALT',
    ui_speed         = 'VEL',
    ui_range         = 'DIST',
    ui_heading       = 'RUMO',
    ui_mode          = 'MODO',
    ui_zoom          = 'ZOOM',
    ui_operator      = 'OPERADOR',
    ui_target        = 'ALVO FIXO',
    ui_spotlight     = 'LUZ',
    ui_meters        = 'm',
    ui_agl           = 'AGL',

    -- Vistas de câmara + termos OSD de contacto/track
    ui_cam_gimbal    = 'CAM 1 · GIMBAL',
    ui_cam_ext       = 'CAM 2 · EXTERNA',
    ui_contact       = 'CONTACTO',
    ui_trk           = 'TRK',
    ui_mark          = 'ALVO MARCADO',
    ui_lgt           = 'LUZ',
    ui_sns           = 'SNS',
    ui_lrf           = 'LRF',
    ui_gps           = 'GPS',
    ui_vs            = 'VS',
    ui_tsr           = 'TSR',
    ui_tsr_ready     = 'TSR PRONTO',

    -- ── Target lock ─────────────────────────────────────────────────────
    lock_acquired  = 'Alvo fixado — a seguir.',
    lock_released  = 'Lock libertado.',
    lock_lost      = 'Lock perdido — alvo fora de alcance.',
    lock_no_target = 'Nada para fixar na mira.',
    ui_lock        = 'LOCK',
    ui_acq         = 'ACQ',
    ui_ctrl_lock   = 'Fixar',

    -- ── Widget standby + desligar ───────────────────────────────────────
    ui_standby     = 'UAV STANDBY',
    ui_holding     = 'PARADO',
    ui_tracking    = 'A SEGUIR',
    ui_reenter     = 'usa o item para regressar',
    ui_poweroff    = 'A DESLIGAR',
    ui_ctrl_standby = 'Standby',
    ui_ctrl_poweroff = 'Desligar',

    -- ── Taser ───────────────────────────────────────────────────────────
    taser_fired        = 'Taser disparado.',
    taser_empty        = 'Cartuchos do taser esgotados.',
    taser_no_target    = 'Nenhum alvo na mira.',
    taser_out_of_range = 'Longe demais para o taser — aproxima-te.',
    taser_cooldown     = 'Taser a recarregar…',

    ui_ctrl_move     = 'Mover',
    ui_ctrl_updown   = 'Subir / Descer',
    ui_ctrl_ascend   = 'Subir',
    ui_ctrl_descend  = 'Descer',
    ui_ctrl_boost    = 'Turbo',
    ui_ctrl_look     = 'Olhar',
    ui_ctrl_zoom     = 'Zoom',
    ui_ctrl_mode     = 'Sensor',
    ui_ctrl_view     = 'Câmara',
    ui_ctrl_light    = 'Luz',
    ui_ctrl_tag      = 'Marcar',
    ui_ctrl_taser    = 'Taser',
    ui_ctrl_exit     = 'Recolher',

    -- ── Unidades de velocidade (km/h ⇄ mph) ─────────────────────────────
    ui_kmh        = 'km/h',
    ui_mph        = 'mph',
    ui_ctrl_units = 'Unidades',
    units_kmh     = 'UNIDADES · KM/H',
    units_mph     = 'UNIDADES · MPH',
    units_locked  = 'A unidade de velocidade está fixada pelo servidor.',
}

