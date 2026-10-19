-- Run from the resources directory with a Lua 5.3+ runner.
vec4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end
assert(loadfile('[XN_CODE]/xn-sellitem/config.lua'))()

local farm
for _, location in ipairs(Config.Locations) do
    if location.TargetName == 'fram_dolly' then farm = location break end
end
assert(farm, 'farm merchant is missing')
assert(farm.Items == Config.Items.traicay)
assert(farm.ExtraItems == Config.Items.nuoithu)

local offered = Config.GetLocationItems(farm)
assert(offered.conheo == Config.Items.nuoithu.conheo, 'pigs must appear at the farm merchant')
assert(offered.conbo == Config.Items.nuoithu.conbo, 'cattle must appear at the farm merchant')
assert(offered.coconut == Config.Items.traicay.coconut, 'existing produce must remain available')
assert(offered.traidudu == nil, 'black-market goods must not appear at the farm merchant')

Config.Items.nuoithu.new_animal = { Label = 'New animal' }
assert(Config.GetLocationItems(farm).new_animal == Config.Items.nuoithu.new_animal,
    'admin-added livestock must appear without rebuilding the location')
Config.Items.nuoithu.new_animal = nil

local fish = Config.Locations[1]
assert(Config.GetLocationItems(fish) == fish.Items,
    'merchants with one category must preserve their existing item reference')

print('merchant_catalog_spec: ok')
