-- Courtesy of @MadsL
-- https://forum.cfx.re/t/help-how-to-get-the-current-keybind-of-a-registered-keymap/1847600/7

local specialkeyCodes = {
    ['b_100'] = 'LMB', ['b_101'] = 'RMB', ['b_102'] = 'MMB',
    ['b_103'] = 'Mouse.ExtraBtn1', ['b_104'] = 'Mouse.ExtraBtn2',
    ['b_105'] = 'Mouse.ExtraBtn3', ['b_106'] = 'Mouse.ExtraBtn4',
    ['b_107'] = 'Mouse.ExtraBtn5', ['b_108'] = 'Mouse.ExtraBtn6',
    ['b_109'] = 'Mouse.ExtraBtn7', ['b_110'] = 'Mouse.ExtraBtn8',
    ['b_115'] = 'MouseWheel.Up',   ['b_116'] = 'MouseWheel.Down',
    ['b_130'] = 'NumSubstract',    ['b_131'] = 'NumAdd',
    ['b_134'] = 'Num Multiplication', ['b_135'] = 'Num Enter',
    ['b_137'] = 'Num1', ['b_138'] = 'Num2', ['b_139'] = 'Num3',
    ['b_140'] = 'Num4', ['b_141'] = 'Num5', ['b_142'] = 'Num6',
    ['b_143'] = 'Num7', ['b_144'] = 'Num8', ['b_145'] = 'Num9',
    ['b_170'] = 'F1',  ['b_171'] = 'F2',  ['b_172'] = 'F3',  ['b_173'] = 'F4',
    ['b_174'] = 'F5',  ['b_175'] = 'F6',  ['b_176'] = 'F7',  ['b_177'] = 'F8',
    ['b_178'] = 'F9',  ['b_179'] = 'F10', ['b_180'] = 'F11', ['b_181'] = 'F12',
    ['b_182'] = 'F13', ['b_183'] = 'F14', ['b_184'] = 'F15', ['b_185'] = 'F16',
    ['b_186'] = 'F17', ['b_187'] = 'F18', ['b_188'] = 'F19', ['b_189'] = 'F20',
    ['b_190'] = 'F21', ['b_191'] = 'F22', ['b_192'] = 'F23', ['b_193'] = 'F24',
    ['b_194'] = 'Arrow Up',    ['b_195'] = 'Arrow Down',
    ['b_196'] = 'Arrow Left',  ['b_197'] = 'Arrow Right',
    ['b_198'] = 'Delete',      ['b_199'] = 'Escape',
    ['b_200'] = 'Insert',      ['b_201'] = 'End',
    ['b_210'] = 'Delete',      ['b_211'] = 'Insert',      ['b_212'] = 'End',
    ['b_1000'] = 'Shift',      ['b_1002'] = 'Tab',        ['b_1003'] = 'Enter',
    ['b_1004'] = 'Backspace',  ['b_1008'] = 'Home',       ['b_1009'] = 'PageUp',
    ['b_1010'] = 'PageDown',   ['b_1012'] = 'CapsLock',   ['b_1013'] = 'Control',
    ['b_1014'] = 'Right Control', ['b_1015'] = 'Alt',
    ['b_1055'] = 'Home',       ['b_1056'] = 'PageUp',     ['b_2000'] = 'Space',
}

--- Returns the human-readable label for a registered keymap command hash.
--- @param  commandHash number  Control hash from a lib.addKeybind `.hash` field
--- @return string              Key label, or 'unknown' if unrecognised
local function GetKeyLabel(commandHash)
    local key = GetControlInstructionalButton(0, commandHash | 0x80000000, true)
    if string.find(key, 't_') then
        local label, _count = string.gsub(key, 't_', '')
        return label
    end
    return specialkeyCodes[key] or 'unknown'
end

--- Builds a table of all UI locale strings to pass to the NUI.
--- @return table
function BuildUILocales()
    local result = {
        -- PropManagerWindow
        ui_window_title       = locale('ui_window_title'),
        ui_tab_props          = locale('ui_tab_props'),
        ui_tab_add_prop       = locale('ui_tab_add_prop'),
        ui_tab_map            = locale('ui_tab_map'),
        ui_tab_player_access  = locale('ui_tab_player_access'),
        -- PropListWindow
        ui_no_props_found = locale('ui_no_props_found'),
        ui_group_active   = locale('ui_group_active'),
        ui_group_inactive = locale('ui_group_inactive'),
        -- AddPropWindow
        ui_prop_model_label       = locale('ui_prop_model_label'),
        ui_prop_model_placeholder = locale('ui_prop_model_placeholder'),
        ui_prop_list_loading      = locale('ui_prop_list_loading'),
        ui_prop_not_in_list       = locale('ui_prop_not_in_list'),
        ui_group_label            = locale('ui_group_label'),
        ui_group_placeholder      = locale('ui_group_placeholder'),
        ui_render_distance_label  = locale('ui_render_distance_label'),
        ui_expiry_label           = locale('ui_expiry_label'),
        ui_expiry_enabled         = locale('ui_expiry_enabled'),
        ui_expiry_disabled        = locale('ui_expiry_disabled'),
        ui_expiry_notice          = locale('ui_expiry_notice'),
        ui_cancel                 = locale('ui_cancel'),
        ui_placing                = locale('ui_placing'),
        ui_place_prop             = locale('ui_place_prop'),
        -- PlayerAccessWindow
        ui_restricted_access          = locale('ui_restricted_access'),
        ui_restricted_desc            = locale('ui_restricted_desc'),
        ui_accessible_groups          = locale('ui_accessible_groups'),
        ui_forced_expiry              = locale('ui_forced_expiry'),
        ui_forced_expiry_player_desc  = locale('ui_forced_expiry_player_desc'),
        ui_zone_restrictions          = locale('ui_zone_restrictions'),
        ui_no_zone_restriction        = locale('ui_no_zone_restriction'),
        ui_no_access_entry            = locale('ui_no_access_entry'),
        ui_grant_access               = locale('ui_grant_access'),
        ui_edit_access_entry          = locale('ui_edit_access_entry'),
        ui_grant_player_access        = locale('ui_grant_player_access'),
        ui_player_label               = locale('ui_player_label'),
        ui_search_players_placeholder = locale('ui_search_players_placeholder'),
        ui_loading                    = locale('ui_loading'),
        ui_no_players_found           = locale('ui_no_players_found'),
        ui_no_players_online          = locale('ui_no_players_online'),
        ui_default_groups             = locale('ui_default_groups'),
        ui_add_zone                   = locale('ui_add_zone'),
        ui_no_zones_added             = locale('ui_no_zones_added'),
        ui_player_restricted_zones    = locale('ui_player_restricted_zones'),
        ui_force_expiry               = locale('ui_force_expiry'),
        ui_player_expiry_desc         = locale('ui_player_expiry_desc'),
        ui_duplicate_entry            = locale('ui_duplicate_entry'),
        ui_save_changes               = locale('ui_save_changes'),
        ui_no_players_access = locale('ui_no_players_access'),
        -- GizmoOverlay
        ui_gizmo_position = locale('ui_gizmo_position'),
        ui_gizmo_rotation = locale('ui_gizmo_rotation'),
        ui_gizmo_mode           = locale('ui_gizmo_mode'),
        ui_gizmo_space          = locale('ui_gizmo_space'),
        ui_gizmo_toggle_space   = locale('ui_gizmo_toggle_space'),
        ui_gizmo_snap_ground    = locale('ui_gizmo_snap_ground'),
        ui_gizmo_reset_rotation = locale('ui_gizmo_reset_rotation'),
        -- PropMapWindow
        ui_map_clusters       = locale('ui_map_clusters'),
        ui_map_heatmap        = locale('ui_map_heatmap'),
        ui_map_outline_all    = locale('ui_map_outline_all'),
        ui_map_clear_outlines = locale('ui_map_clear_outlines'),
        ui_map_at_location    = locale('ui_map_at_location'),
        ui_map_delete         = locale('ui_map_delete'),
        ui_map_hint_clusters  = locale('ui_map_hint_clusters'),
        ui_map_hint_heatmap   = locale('ui_map_hint_heatmap'),
        -- MapZonePicker
        ui_zone_map_hint    = locale('ui_zone_map_hint'),
        ui_zone_undo      = locale('ui_zone_undo'),
        ui_zone_clear     = locale('ui_zone_clear'),
        ui_zone_need_more = locale('ui_zone_need_more'),
        -- Shared plural words
        ui_prop        = locale('ui_prop'),
        ui_props       = locale('ui_props'),
        ui_group       = locale('ui_group'),
        ui_groups      = locale('ui_groups'),
        ui_zone        = locale('ui_zone'),
        ui_zones       = locale('ui_zones'),
        ui_point       = locale('ui_point'),
        ui_points      = locale('ui_points'),
        ui_player      = locale('ui_player'),
        ui_players     = locale('ui_players'),
        ui_across      = locale('ui_across'),
        ui_with_access = locale('ui_with_access'),
        ui_saved       = locale('ui_saved'),
        ui_full_map    = locale('ui_full_map'),
        -- Keybind descriptions
        ui_keybind_mode   = locale('keybind_mode'),
        ui_keybind_focus  = locale('keybind_focus'),
        ui_keybind_finish = locale('keybind_finish'),
        ui_keybind_cancel = locale('keybind_cancel'),
    }
    -- Keys
    result.ui_keybind_mode_key   = GetKeyLabel(keybinds.mode.hash)
    result.ui_keybind_focus_key  = GetKeyLabel(keybinds.focus.hash)
    result.ui_keybind_finish_key = GetKeyLabel(keybinds.finish.hash)
    result.ui_keybind_cancel_key = GetKeyLabel(keybinds.cancel.hash)
    return result
end