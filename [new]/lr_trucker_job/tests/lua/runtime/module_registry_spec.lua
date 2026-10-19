LR = nil
dofile("shared/core/lr.lua")
dofile("shared/core/module_registry.lua")

local function descriptor(id, dependencies)
  return {
    id = id,
    dependencies = dependencies,
    start = "resource",
    create = function()
      return {}
    end,
  }
end

local function assertEquals(actual, expected, message)
  if actual ~= expected then
    error((message or "assertEquals failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function assertFails(fn, text)
  local ok, err = pcall(fn)
  if ok then
    error("expected failure")
  end
  if text and not tostring(err):find(text) then
    error(("expected error containing %s, got %s"):format(text, tostring(err)))
  end
end

local registry = LR.ModuleRegistry:new()
registry:Register(descriptor("database"))
registry:Register(descriptor("inventory", { "database" }))
registry:Register(descriptor("shop", { "inventory" }))

local sorted = registry:ResolveStartOrder()
assertEquals(sorted[1].id, "database", "dependencies start first")
assertEquals(sorted[2].id, "inventory", "dependent module starts after dependency")
assertEquals(sorted[3].id, "shop", "transitive dependent starts last")

if type(LR.Modules) ~= "table" then
  error("LR.Modules must be the module-first descriptor catalog")
end
LR.Modules:Register(descriptor("catalog_entry"))
local catalogDescriptors = LR.Modules:Descriptors()
assertEquals(catalogDescriptors[1].id, "catalog_entry", "catalog preserves registration order")
catalogDescriptors[1] = nil
assertEquals(LR.Modules:Get("catalog_entry").id, "catalog_entry", "descriptor listing must be a copy")

assertFails(function()
  LR.ModuleRegistry:new():Register({ id = "Bad-Id", create = function() return {} end })
end, "module id")

assertFails(function()
  LR.ModuleRegistry:new():Register({ id = "bad", start = "boot", create = function() return {} end })
end, "start")

assertFails(function()
  LR.ModuleRegistry:new():Register({ id = "bad" })
end, "create")

local original = { id = "immutable", create = function() return {} end }
local normalized = LR.ModuleRegistry:new():Register(original)
assertEquals(original.start, nil, "registration must not mutate caller descriptor")
assertEquals(normalized.start, "resource", "registry applies resource default to its copy")

local missing = LR.ModuleRegistry:new()
missing:Register(descriptor("shop", { "inventory" }))
assertFails(function()
  missing:ResolveStartOrder()
end, "Missing dependency")

local cyclic = LR.ModuleRegistry:new()
cyclic:Register(descriptor("a", { "b" }))
cyclic:Register(descriptor("b", { "a" }))
assertFails(function()
  cyclic:ResolveStartOrder()
end, "Cycle")

local invalidPhase = LR.ModuleRegistry:new()
invalidPhase:Register({
  id = "player_data",
  start = "player",
  create = function() return {} end,
})
invalidPhase:Register({
  id = "resource_consumer",
  start = "resource",
  dependencies = { "player_data" },
  create = function() return {} end,
})
assertFails(function()
  invalidPhase:ResolveStartOrder()
end, "cannot depend on player module")
