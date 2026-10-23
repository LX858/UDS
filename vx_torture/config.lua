Config = {}
Config.Dependencies = {}
Config.Locale = 'default'
Config.Settings = { locale = Locales[Config.Locale] or Locales['default'] }
Config.Debug = false
Config.DebugZones = false
Config.Nui = false
Config.Dev = false
Config.Framework = 'qbx'
Config.ClientLazyLoad = false

local function stage(dict, actor, victim, chair, tool, durationMs, effect)
  local data = {
    dict = dict, actor = actor, victim = victim, chair = chair,
    tool = tool, durationMs = durationMs, effect = effect,
  }
  if dict == 'missfbi3_electrocute' then
    local prefix = actor:gsub('_player$', '')
    data.tool = nil
    data.props = {
      electric = prefix .. '_r_clip',
      clipRight = prefix .. '_l_clip',
    }
  elseif dict == 'missfbi3_waterboard' then
    data.props = { rag = actor:gsub('_player$', '_rag') }
  end
  return data
end

Config.Torture = {
  item = 'torture',
  placementDistance = 1.8,
  placementTimeoutMs = 60000,
  previewAlpha = 170,
  groundClearance = 0.03,
  maxGroundStep = 1.5,
  minSetupSpacing = 4.0,
  candidateDistance = 3.0,
  interactDistance = 2.0,
  actionDistance = 3.0,
  toolTargetRadius = 0.45,
  trolleyTargetPadding = vector3(0.35, 0.35, 0.5),
  sceneHeadingCorrection = 0.0,
  sceneOffset = vector3(0.0, 0.0, 0.0),
  -- FBI3 scene 0, before a tool has been selected (not the waterboard tool idle).
  seatAlignment = { dict = 'missfbi3_weapon_select', chair = 'waterboard_idle_chair',
    victim = 'waterboard_idle_victim', maxDistance = 1.2 },
  -- FBI3 fbi3.c: Local_121 (chair), Local_124 yaw, and weapon-select prop tracks.
  layoutDict = 'missfbi3_weapon_select',
  referenceChair = vector3(142.99, -2201.98, 4.07),
  referenceHeading = 96.61,
  seatTimeoutMs = 6000,
  prepareTimeoutMs = 7000,
  -- Hard failure ceiling; normal stages finish on the actual animation phase.
  stageTimeoutMs = 30000,
  toolPrepareTimeoutMs = 12000,
  toolSelectTimeoutMs = 16000,
  toolIdleTimeoutMs = 10000,
  scenePeerTimeoutMs = 4000,
  toolExitTimeoutMs = 15000,
  toolReturnAnimMs = 1000,
  toolReturnOffset = vector3(0.0, -0.85, 0.0),
  toolExitCameraOffset = vector3(0.0, -2.1, 1.5),
  minimumActionMs = 1200,
  observerFxDistance = 30.0,
  -- restClip reads the exact initial position/rotation from the original
  -- FBI3 animation. Offsets are used for simple props and server bounds.
  propOrder = { 'chair', 'trolley', 'wrench', 'pliers', 'electric', 'waterboard',
    'syringe', 'battery', 'clipRight', 'rag', 'stool', 'ecg' },
  props = {
    chair = { model = 'prop_torture_ch_01', offset = vector3(0.0, 0.0, 0.0), ground = true, required = true },
    trolley = { model = 'p_cs_trolley_01_s', offset = vector3(1.4, 0.15, 0.0), restClip = 'weapon_select_bench_bench', ground = true, required = true },
    wrench = { model = 'prop_cs_wrench', offset = vector3(1.17, 0.37, 0.01), restClip = 'weapon_select_bench_wrench', surface = 'trolley', targetOffset = vector3(0.0, 0.0, 0.0), required = true, tool = true },
    pliers = { model = 'p_pliers_01_s', offset = vector3(1.47, 0.37, 0.01), restClip = 'weapon_select_bench_pliers', surface = 'trolley', targetOffset = vector3(0.0, 0.0, 0.0), required = true, tool = true },
    electric = { model = 'p_ld_crocclips01_s', offset = vector3(1.17, 0.08, 0.01), restClip = 'weapon_select_bench_clip1', surface = 'trolley', targetOffset = vector3(0.0, 0.0, 0.0), required = true, tool = true },
    waterboard = { model = 'w_am_jerrycan', offset = vector3(1.73, 0.05, 0.01), restClip = 'weapon_select_bench_can', surface = 'trolley', targetOffset = vector3(0.0, 0.0, 0.0), required = true, tool = true },
    syringe = { model = 'prop_syringe_01', offset = vector3(1.47, 0.08, 0.01), restClip = 'weapon_select_bench_syringe', surface = 'trolley', targetOffset = vector3(0.0, 0.0, 0.0), required = true, tool = true },
    battery = { model = 'prop_torture_01', offset = vector3(1.95, 0.55, 0.0), restClip = 'weapon_select_bench_battery', surface = 'trolley' },
    clipRight = { model = 'p_ld_crocclips02_s', offset = vector3(1.27, 0.08, 0.01), restClip = 'weapon_select_bench_clip2', surface = 'trolley', required = true },
    rag = { model = 'p_loose_rag_01_s', offset = vector3(1.7, 0.37, 0.02), restClip = 'weapon_select_bench_rag', surface = 'trolley', required = true },
    stool = { model = 'v_ilev_tort_stool', offset = vector3(-1.05, -0.65, 0.0), referencePosition = vector3(143.1199, -2201.345, 4.35), referenceRotation = vector3(0.0, 0.0, 0.0), ground = true },
    ecg = { model = 'prop_ecg_01', offset = vector3(-1.4, 0.55, 0.0), referencePosition = vector3(143.1, -2201.345, 4.502), referenceRotation = vector3(0.0, 0.0, 173.1), ground = true },
  },
  toolOrder = { 'wrench', 'pliers', 'electric', 'waterboard', 'syringe' },
  toolLabels = {
    wrench = 'cờ lê', pliers = 'kìm', electric = 'kẹp điện',
    waterboard = 'can nước', syringe = 'ống tiêm',
  },
  -- fbi3.c func_428: PH_R_Hand = 28422; second electric clip PH_L_Hand = 60309.
  toolHand = {
    wrench = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) },
    pliers = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) },
    electric = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0),
      companion = { key = 'clipRight', bone = 60309, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) } },
    waterboard = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) },
    syringe = { bone = 28422, offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 0.0) },
  },
  -- Scene origin follows the chair. The select clips contain the walk from
  -- trolley to victim; the return walk is scripted because FBI3 has no
  -- matching return clip for every tool.
  toolScenes = {
    wrench = {
      select = { dict = 'missfbi3_weapon_select', actor = 'weapon_select_wrench_player',
        victimLoop = true,
        victim = 'waterboard_idle_victim', camera = 'weapon_select_wrench_cam',
        chair = 'waterboard_idle_chair', tool = 'weapon_select_wrench_wrench',
        bench = { clipRight = 'weapon_bench_wrench_clip2', electric = 'weapon_bench_wrench_clip1',
          waterboard = 'weapon_bench_wrench_can', pliers = 'weapon_bench_wrench_pliers',
          battery = 'weapon_bench_wrench_battery', trolley = 'weapon_bench_wrench_trolley',
          syringe = 'weapon_bench_wrench_syringe', rag = 'weapon_bench_wrench_rag' } },
      idle = { dict = 'missfbi3_wrench', actor = 'wrench_idle_player',
        victim = 'wrench_idle_victim', camera = 'wrench_idle_cam',
        chair = 'wrench_idle_chair', tool = 'wrench_idle_wrench' },
    },
    pliers = {
      select = { dict = 'missfbi3_weapon_select', actor = 'weapon_select_pliers_player',
        victim = 'weapon_select_pliers_victim', camera = 'weapon_select_pliers_cam',
        tool = 'weapon_select_pliers_pliers',
        bench = { wrench = 'weapon_bench_toothpull_wrench',
          electric = 'weapon_bench_toothpull_clip1', clipRight = 'weapon_bench_toothpull_clip2',
          waterboard = 'weapon_bench_toothpull_can', battery = 'weapon_bench_toothpull_battery',
          trolley = 'weapon_bench_toothpull_trolley',
          syringe = 'weapon_bench_toothpull_syringe', rag = 'weapon_bench_toothpull_rag' } },
      idle = { dict = 'missfbi3_toothpull', actor = 'pull_tooth_idle_player',
        victim = 'pull_tooth_idle_victim', camera = 'pull_tooth_idle_cam',
        tool = 'pull_tooth_idle_pliers' },
    },
    electric = {
      select = { dict = 'missfbi3_weapon_select', actor = 'weapon_select_electrocute_player',
        victimLoop = true,
        victim = 'waterboard_idle_victim', camera = 'weapon_select_electrocute_cam',
        chair = 'waterboard_idle_chair',
        props = { electric = 'weapon_select_electrocute_r_clip',
          clipRight = 'weapon_select_electrocute_l_clip' } },
      idle = { dict = 'missfbi3_electrocute', actor = 'clamp_wait_loop_player',
        victim = 'clamp_wait_loop_victim', camera = 'clamp_wait_loop_cam',
        chair = 'clamp_wait_loop_chair',
        props = { electric = 'clamp_wait_loop_r_clip', clipRight = 'clamp_wait_loop_l_clip' } },
    },
    waterboard = {
      select = { dict = 'missfbi3_weapon_select', actor = 'weapon_select_waterboard_player',
        victimLoop = true,
        victim = 'waterboard_idle_victim', camera = 'weapon_select_waterboard_cam',
        chair = 'waterboard_idle_chair', tool = 'weapon_select_waterboard_jerrycan',
        props = { rag = 'weapon_select_waterboard_rag' },
        bench = { wrench = 'weapon_bench_waterboard_wrench',
          electric = 'weapon_bench_waterboard_clip1', clipRight = 'weapon_bench_waterboard_clip2',
          pliers = 'weapon_bench_waterboard_pliers', battery = 'weapon_bench_waterboard_battery',
          trolley = 'weapon_bench_waterboard_trolley',
          syringe = 'weapon_bench_waterboard_syringe' } },
      idle = { dict = 'missfbi3_waterboard', actor = 'waterboard_idle_player',
        victim = 'waterboard_idle_victim', camera = 'waterboard_idle_cam',
        chair = 'waterboard_idle_chair', props = { rag = 'waterboard_idle_rag' } },
    },
    syringe = {
      select = { dict = 'missfbi3_syringe', actor = 'weapon_select_syringe_player',
        victim = 'flatline_intro_victim', camera = 'weapon_select_syringe_cam',
        chair = 'flatline_intro_chair', attachAt = 0.55,
        bench = { wrench = 'weapon_bench_syringe_wrench',
          electric = 'weapon_bench_syringe_clip1', clipRight = 'weapon_bench_syringe_clip2',
          waterboard = 'weapon_bench_syringe_can', pliers = 'weapon_bench_syringe_pliers',
          battery = 'weapon_bench_syringe_battery', trolley = 'weapon_bench_syringe_trolley',
          rag = 'weapon_bench_syringe_rag' } },
      idle = { dict = 'missfbi3_syringe', actor = 'syringe_idle_player',
        victim = 'flatline_loop_victim', camera = 'syringe_idle_cam',
        chair = 'flatline_loop_chair' },
    },
  },
  actions = {
    wrench_left = { tool = 'wrench', label = 'Đánh bên trái', result = { mode = 'damage', amount = 12 }, stages = {
      stage('missfbi3_wrench', 'wrench_attack_left_player', 'wrench_attack_left_victim', 'wrench_attack_left_chair', 'wrench_attack_left_wrench', 4100),
    } },
    wrench_mid = { tool = 'wrench', label = 'Đánh chính diện', result = { mode = 'damage', amount = 18 }, stages = {
      stage('missfbi3_wrench', 'wrench_attack_mid_player', 'wrench_attack_mid_victim', 'wrench_attack_mid_chair', 'wrench_attack_mid_wrench', 4100),
    } },
    wrench_right = { tool = 'wrench', label = 'Đánh bên phải', result = { mode = 'damage', amount = 12 }, stages = {
      stage('missfbi3_wrench', 'wrench_attack_right_player', 'wrench_attack_right_victim', 'wrench_attack_right_chair', 'wrench_attack_right_wrench', 4100),
    } },
    pliers_weak = { tool = 'pliers', label = 'Nhổ nhẹ', result = { mode = 'damage', amount = 12 }, stages = {
      stage('missfbi3_toothpull', 'pull_tooth_ready_intro_player', 'pull_tooth_ready_intro_victim', nil, 'pull_tooth_ready_intro_pliers', 2000),
      stage('missfbi3_toothpull', 'pull_tooth_loop_weak_player', 'pull_tooth_loop_weak_victim', nil, 'pull_tooth_loop_weak_pliers', 3800),
      stage('missfbi3_toothpull', 'pull_tooth_outro_b_player', 'pull_tooth_outro_b_victim', nil, 'pull_tooth_outro_b_pliers', 2000),
    } },
    pliers_pull = { tool = 'pliers', label = 'Nhổ mạnh', result = { mode = 'damage', amount = 25 }, stages = {
      stage('missfbi3_toothpull', 'pull_tooth_intro_player', 'pull_tooth_intro_victim', nil, 'pull_tooth_intro_pliers', 2000),
      stage('missfbi3_toothpull', 'pull_tooth_loop_player', 'pull_tooth_loop_victim', nil, 'pull_tooth_loop_pliers', 3800,
        { particle = 'scr_fbi3_blood_extraction', sound = 'FBI_03_TORTURE_Teeth_Pulling', bank = 'FBI_03_TORTURE_Teeth' }),
      stage('missfbi3_toothpull', 'pull_tooth_outro_player', 'pull_tooth_outro_victim', 'pull_tooth_outro_chair', 'pull_tooth_outro_pliers', 2200),
    } },
    electric_left = { tool = 'electric', label = 'Chích điện bên trái', result = { mode = 'damage', amount = 15 }, stages = {
      stage('missfbi3_electrocute', 'electrocute_left_intro_player', 'electrocute_left_intro_victim', nil, 'electrocute_left_intro_l_clip', 4000,
        { particle = 'scr_fbi3_elec_sparks', sound = 'FBI_03_TORTURE_Electric_Zap', bank = 'FBI_03_TORTURE_Electric' }),
    } },
    electric_right = { tool = 'electric', label = 'Chích điện bên phải', result = { mode = 'damage', amount = 15 }, stages = {
      stage('missfbi3_electrocute', 'electrocute_right_intro_player', 'electrocute_right_intro_victim', nil, 'electrocute_right_intro_r_clip', 4000,
        { particle = 'scr_fbi3_elec_sparks', sound = 'FBI_03_TORTURE_Electric_Zap', bank = 'FBI_03_TORTURE_Electric' }),
    } },
    electric_both = { tool = 'electric', label = 'Chích điện hai bên', result = { mode = 'damage', amount = 30 }, stages = {
      stage('missfbi3_electrocute', 'electrocute_both_intro_player', 'electrocute_both_intro_victim', 'electrocute_both_intro_chair', nil, 2000),
      stage('missfbi3_electrocute', 'electrocute_both_loop_player', 'electrocute_both_loop_victim', 'electrocute_both_loop_chair', nil, 4000,
        { particle = 'scr_fbi3_elec_sparks', sound = 'FBI_03_TORTURE_Electric_Zap', bank = 'FBI_03_TORTURE_Electric' }),
      stage('missfbi3_electrocute', 'electrocute_both_outro_player', 'electrocute_both_outro_victim', 'electrocute_both_outro_chair', nil, 2000),
    } },
    water_pour = { tool = 'waterboard', label = 'Dội nước', result = { mode = 'damage', amount = 20 }, stages = {
      stage('missfbi3_waterboard', 'waterboard_ready_to_loop_player', 'waterboard_ready_to_loop_victim', 'waterboard_ready_to_loop_chair', 'waterboard_ready_to_loop_jerrycan', 2000),
      stage('missfbi3_waterboard', 'waterboard_loop_player', 'waterboard_loop_victim', 'waterboard_loop_chair', 'waterboard_loop_jerrycan', 4000,
        { particle = 'scr_fbi3_dirty_water_pour', sound = 'FBI_03_TORTURE_Water_Pour_Water', bank = 'FBI_03_TORTURE_Water' }),
      stage('missfbi3_waterboard', 'waterboard_loop_to_ready_player', 'waterboard_loop_to_ready_victim', 'waterboard_loop_to_ready_chair', 'waterboard_loop_to_ready_jerrycan', 2000),
    } },
    water_kick = { tool = 'waterboard', label = 'Đạp ghế', result = { mode = 'damage', amount = 15 }, stages = {
      stage('missfbi3_waterboard', 'waterboard_kick_player', 'waterboard_kick_victim', 'waterboard_kick_chair', 'waterboard_kick_jerrycan', 4000),
    } },
    syringe_inject = { tool = 'syringe', label = 'Tiêm thuốc', result = { mode = 'damage', amount = 20 }, stages = {
      stage('missfbi3_syringe', 'syringe_use_player', 'syringe_use_victim', 'syringe_use_chair', nil, 4500),
    } },
    syringe_overdose = { tool = 'syringe', label = 'Tiêm quá liều', result = { mode = 'kill' }, stages = {
      stage('missfbi3_syringe', 'syringe_use_player', 'syringe_use_victim', 'syringe_use_chair', nil, 4500),
      stage('missfbi3_syringe', 'flatline_intro_player', 'flatline_intro_victim', 'flatline_intro_chair', nil, 3500,
        { sound = 'FBI_03_TORTURE_Heart_Monitor_Flatline', bank = 'FBI_03_TORTURE_General' }),
    } },
  },
}

function L(key, ...)
  local pattern = Config.Settings.locale[key] or key
  if select('#', ...) == 0 then return pattern end
  return pattern:format(...)
end
