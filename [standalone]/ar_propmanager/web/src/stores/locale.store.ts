import { defineStore } from 'pinia'
import { ref } from 'vue'

export type UILocales = Record<string, string>

const DEFAULTS: UILocales = {
  // PropManagerWindow
  ui_window_title:        'Prop Manager',
  ui_tab_props:           'Props',
  ui_tab_add_prop:        'Add Prop',
  ui_tab_map:             'Map',
  ui_tab_player_access:   'Player Access',

  // PropListWindow
  ui_no_props_found:  'No props found.',
  ui_group_active:    'Active',
  ui_group_inactive:  'Inactive',

  // AddPropWindow
  ui_prop_model_label:        'Prop Model',
  ui_prop_model_placeholder:  'Search or type model name...',
  ui_prop_list_loading:       'Loading prop list...',
  ui_prop_not_in_list:        'Not in list - will be validated in-game',
  ui_group_label:             'Group',
  ui_group_placeholder:       'Select or type group...',
  ui_render_distance_label:   'Render Distance (m)',
  ui_expiry_label:            'Expiry',
  ui_expiry_enabled:          'Enabled',
  ui_expiry_disabled:         'Disabled',
  ui_expiry_notice:           'This prop will expire after {0}.',
  ui_cancel:                  'Cancel',
  ui_placing:                 'Placing...',
  ui_place_prop:              'Place Prop',
  ui_error_invalid_model:     'Invalid model - could not be loaded in-game',
  ui_error_group_no_access:   "This group already exists but you don't have access to it",
  ui_error_place_failed:      'Failed to place prop',

  // PlayerAccessWindow
  ui_restricted_access:           'Restricted Access',
  ui_restricted_desc:             'You have been granted access to manage props within the following areas.',
  ui_accessible_groups:           'Accessible Groups',
  ui_forced_expiry:               'Forced Expiry',
  ui_forced_expiry_player_desc:   'Props you place will expire after {0}.',
  ui_zone_restrictions:           'Zone Restrictions',
  ui_no_zone_restriction:         'No zone restriction - full map access.',
  ui_no_access_entry:             'No access entry found.',
  ui_grant_access:                'Grant Access',
  ui_edit_access_entry:           'Edit Access Entry',
  ui_grant_player_access:         'Grant Player Access',
  ui_player_label:                'Player',
  ui_search_players_placeholder:  'Search online players...',
  ui_loading:                     'Loading...',
  ui_no_players_found:            'No players found',
  ui_no_players_online:           'No players online',
  ui_default_groups:              'Default Groups',
  ui_add_zone:                    'Add Zone',
  ui_no_zones_added:              'No zones added - player has access to the full map.',
  ui_player_restricted_zones:     'Player is restricted to {0}.',
  ui_force_expiry:                'Force Expiry',
  ui_player_expiry_desc:          'Props placed by this player will expire after {0}.',
  ui_duplicate_entry:             'This player already has an access entry. Edit their existing entry instead.',
  ui_save_changes:                'Save Changes',
  ui_no_players_access:  'No players have been granted access.',

  // GizmoOverlay
  ui_gizmo_position: 'Position',
  ui_gizmo_rotation: 'Rotation',
  ui_gizmo_mode:          'Mode',
  ui_gizmo_space:         'Space',
  ui_gizmo_toggle_space:  'Toggle Axis Space',
  ui_gizmo_snap_ground:   'Snap To Ground',
  ui_gizmo_reset_rotation:'Reset Rotation',
  ui_gizmo_zone_valid:    'In Zone',
  ui_gizmo_zone_invalid:  'Outside Zone',
  ui_gizmo_toggle_zones:  'Toggle Zones',

  // PropMapWindow
  ui_map_clusters:      'Clusters',
  ui_map_heatmap:       'Heatmap',
  ui_map_outline_all:   'Outline All',
  ui_map_clear_outlines:'Clear Outlines',
  ui_map_at_location:   'at this location',
  ui_map_delete:        'Delete',
  ui_map_hint_clusters: 'Click a marker or cluster to select',
  ui_map_hint_heatmap:  'Heatmap - density of placed props',

  // MapZonePicker
  ui_zone_map_hint:   'Click map to place vertices · Hover a saved zone to remove it',
  ui_zone_undo:      'Undo',
  ui_zone_clear:     'Clear',
  ui_zone_need_more: 'need {0} more',

  // Shared plural words
  ui_prop:        'prop',
  ui_props:       'props',
  ui_group:       'group',
  ui_groups:      'groups',
  ui_zone:        'zone',
  ui_zones:       'zones',
  ui_point:       'point',
  ui_points:      'points',
  ui_player:      'player',
  ui_players:     'players',
  ui_across:      'across',
  ui_with_access: 'with access',
  ui_saved:       'saved',
  ui_full_map:    'Full Map',

  // Keybind descriptions
  ui_keybind_mode:        'Change Mode',
  ui_keybind_mode_key:    'R',
  ui_keybind_focus:       'Toggle Focus',
  ui_keybind_focus_key:   'F',
  ui_keybind_finish:      'Finish',
  ui_keybind_finish_key:  'E',
  ui_keybind_cancel:      'Cancel',
  ui_keybind_cancel_key:  'Back',
}

export const useLocaleStore = defineStore('locale', () => {
  const locales = ref<UILocales>({ ...DEFAULTS })

  function setLocales(data: UILocales) {
    Object.assign(locales.value, data)
  }

  /** Interpolate a locale string — replace {0}, {1}, … with the given args. */
  function t(key: string, ...args: (string | number)[]): string {
    let str = locales.value[key] ?? key
    args.forEach((arg, i) => { str = str.replace(`{${i}}`, String(arg)) })
    return str
  }

  return { locales, setLocales, t }
})
