local ipls = {}

local function add(name)
    ipls[#ipls + 1] = name
end

-- Terrain occlusion.
for i = 0, 9 do
    add(('h4_mph4_terrain_occ_%02d'):format(i))
end

-- Grass.
for i = 0, 1 do add(('h4_mph4_terrain_01_grass_%d'):format(i)) end
for i = 0, 3 do add(('h4_mph4_terrain_02_grass_%d'):format(i)) end
for i = 0, 1 do add(('h4_mph4_terrain_04_grass_%d'):format(i)) end
add('h4_mph4_terrain_05_grass_0')
add('h4_mph4_terrain_06_grass_0')

-- Island terrain.
local terrain = {
    {'01', true}, {'02', true}, {'03', false},
    {'04', true}, {'05', true}, {'06', true}
}
for i = 1, #terrain do
    local id, hasSlod = terrain[i][1], terrain[i][2]
    add('h4_islandx_terrain_' .. id)
    add('h4_islandx_terrain_' .. id .. '_lod')
    if hasSlod then add('h4_islandx_terrain_' .. id .. '_slod') end
end

-- Terrain props 05.
for _, suffix in ipairs({'a','b','c','d','e','f'}) do
    local name = 'h4_islandx_terrain_props_05_' .. suffix
    add(name)
    add(name .. '_lod')
    if suffix == 'd' or suffix == 'e' or suffix == 'f' then
        add(name .. '_slod')
    end
end

-- Terrain props 06.
for _, suffix in ipairs({'a','b','c'}) do
    local name = 'h4_islandx_terrain_props_06_' .. suffix
    add(name)
    add(name .. '_lod')
    add(name .. '_slod')
end

local static = {
    'h4_mph4_terrain_01',
    'h4_mph4_terrain_01_long_0',
    'h4_mph4_terrain_02',
    'h4_mph4_terrain_03',
    'h4_mph4_terrain_04',
    'h4_mph4_terrain_05',
    'h4_mph4_terrain_06',
    'h4_mph4_terrain_06_strm_0',
    'h4_mph4_terrain_lod',

    'h4_islandx',
    'h4_islandx_disc_strandedshark',
    'h4_islandx_disc_strandedshark_lod',
    'h4_islandx_disc_strandedwhale',
    'h4_islandx_disc_strandedwhale_lod',
    'h4_islandx_props',
    'h4_islandx_props_lod',

    'h4_mph4_island',
    'h4_mph4_island_long_0',
    'h4_mph4_island_strm_0',

    'h4_beach',
    'h4_beach_bar_props',
    'h4_beach_lod',
    'h4_beach_party',
    'h4_beach_party_lod',
    'h4_beach_props',
    'h4_beach_props_lod',
    'h4_beach_props_party',
    'h4_beach_props_slod',
    'h4_beach_slod',

    'h4_islandairstrip',
    'h4_islandairstrip_doorsopen',
    'h4_islandairstrip_doorsopen_lod',
    'h4_islandairstrip_hangar_props',
    'h4_islandairstrip_hangar_props_lod',
    'h4_islandairstrip_hangar_props_slod',
    'h4_islandairstrip_lod',
    'h4_islandairstrip_props',
    'h4_islandairstrip_propsb',
    'h4_islandairstrip_propsb_lod',
    'h4_islandairstrip_propsb_slod',
    'h4_islandairstrip_props_lod',
    'h4_islandairstrip_props_slod',
    'h4_islandairstrip_slod',

    'h4_islandxcanal_props',
    'h4_islandxcanal_props_lod',
    'h4_islandxcanal_props_slod',

    'h4_islandxdock',
    'h4_islandxdock_lod',
    'h4_islandxdock_props',
    'h4_islandxdock_props_2',
    'h4_islandxdock_props_2_lod',
    'h4_islandxdock_props_2_slod',
    'h4_islandxdock_props_lod',
    'h4_islandxdock_props_slod',
    'h4_islandxdock_slod',
    'h4_islandxdock_water_hatch',

    'h4_islandxtower',
    'h4_islandxtower_lod',
    'h4_islandxtower_slod',
    'h4_islandxtower_veg',
    'h4_islandxtower_veg_lod',
    'h4_islandxtower_veg_slod',

    'h4_islandx_barrack_hatch',
    'h4_islandx_barrack_props',
    'h4_islandx_barrack_props_lod',
    'h4_islandx_barrack_props_slod',

    'h4_islandx_checkpoint',
    'h4_islandx_checkpoint_lod',
    'h4_islandx_checkpoint_props',
    'h4_islandx_checkpoint_props_lod',
    'h4_islandx_checkpoint_props_slod',

    'h4_islandx_maindock',
    'h4_islandx_maindock_lod',
    'h4_islandx_maindock_props',
    'h4_islandx_maindock_props_2',
    'h4_islandx_maindock_props_2_lod',
    'h4_islandx_maindock_props_2_slod',
    'h4_islandx_maindock_props_lod',
    'h4_islandx_maindock_props_slod',
    'h4_islandx_maindock_slod',

    'h4_islandx_mansion',
    'h4_islandx_mansion_b',
    'h4_islandx_mansion_b_lod',
    'h4_islandx_mansion_b_side_fence',
    'h4_islandx_mansion_b_slod',
    'h4_islandx_mansion_entrance_fence',
    'h4_islandx_mansion_guardfence',
    'h4_islandx_mansion_lights',
    'h4_islandx_mansion_lockup_01',
    'h4_islandx_mansion_lockup_01_lod',
    'h4_islandx_mansion_lockup_02',
    'h4_islandx_mansion_lockup_02_lod',
    'h4_islandx_mansion_lockup_03',
    'h4_islandx_mansion_lockup_03_lod',
    'h4_islandx_mansion_lod',
    'h4_islandx_mansion_office',
    'h4_islandx_mansion_office_lod',
    'h4_islandx_mansion_props',
    'h4_islandx_mansion_props_lod',
    'h4_islandx_mansion_props_slod',
    'h4_islandx_mansion_slod',
    'h4_islandx_mansion_vault',
    'h4_islandx_mansion_vault_lod',
    'h4_island_padlock_props',
    'h4_mansion_gate_closed',
    'h4_mansion_remains_cage',

    'h4_mph4_airstrip',
    'h4_mph4_airstrip_interior_0_airstrip_hanger',
    'h4_mph4_beach',
    'h4_mph4_dock',
    'h4_mph4_island_lod',
    'h4_mph4_island_ne_placement',
    'h4_mph4_island_nw_placement',
    'h4_mph4_island_se_placement',
    'h4_mph4_island_sw_placement',
    'h4_mph4_mansion',
    'h4_mph4_mansion_b',
    'h4_mph4_mansion_b_strm_0',
    'h4_mph4_mansion_strm_0',
    'h4_mph4_wtowers'
}

for i = 1, #static do
    add(static[i])
end

-- NE/NW/SE/SW island sectors.
for _, quadrant in ipairs({'ne','nw','se','sw'}) do
    for i = 0, 9 do
        local base = ('h4_%s_ipl_%02d'):format(quadrant, i)
        add(base)
        add(base .. '_lod')
        add(base .. '_slod')
    end
end

for i = 1, 10 do
    add(('h4_islandx_placement_%02d'):format(i))
end

add('h4_mph4_island_placement')

return ipls
