local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

local function assertTrue(value, message)
  if value ~= true then
    error(message or "expected true")
  end
end

local function assertError(callback, expected)
  local ok, err = pcall(callback)
  if ok then
    error("expected operation to fail")
  end
  if expected and not tostring(err):find(expected, 1, true) then
    error(("expected error containing %q, got %q"):format(expected, tostring(err)))
  end
end

LR = nil
dofile("shared/core/lr.lua")
dofile("shared/core/class.lua")

local Entity = LR.Class:Define("Entity")
function Entity:init(id)
  self.id = id
end
function Entity:Describe()
  return "entity:" .. self.id
end

local cyclicConfig = {}
cyclicConfig.self = cyclicConfig
Entity.config = cyclicConfig

local Tree = Entity:Extend("Tree")
Tree.enabled = false
function Tree:init(input)
  Entity.init(self, input.id)
  self.water = input.water
  self.active = false
end

local afterSet = {}
Tree:Property("water", {
  set = function(_, value)
    return math.max(0, math.min(100, value))
  end,
  validate = function(_, value)
    return type(value) == "number", "water must be a number"
  end,
  afterSet = function(_, value, previous)
    afterSet[#afterSet + 1] = { value = value, previous = previous }
  end,
})
Tree:Property("active")
Tree:Property("ready", {
  readonly = true,
  get = function(instance)
    return instance.water >= 100 and instance.active
  end,
})

local tree = Tree:New({ id = "tree_1", water = 120 })
local anotherTree = Tree:New({ id = "tree_2", water = 25 })
local callableOk = pcall(function()
  return Tree({ id = "tree_3", water = 50 })
end)

assertEqual(tree.id, "tree_1")
assertEqual(callableOk, false, "classes must use the typed New constructor")
assertEqual(tree.water, 100, "setter must normalize constructor assignment")
assertEqual(tree.active, false, "property must preserve false values")
assertEqual(tree.ready, false, "getter must preserve false values")
assertEqual(tree.enabled, false, "subclass members must preserve false values")
assertEqual(tree.config, cyclicConfig, "class inheritance must not deep-copy tables")
assertEqual(getmetatable(tree), Tree, "instance must use its class as the shared metatable")
assertEqual(getmetatable(anotherTree), Tree, "instances must reuse the class metatable")
assertEqual(rawget(tree, "Describe"), nil, "instances must not copy methods")
assertEqual(rawget(tree, "water"), nil, "properties must use backing storage")
assertEqual(rawget(tree, "_water"), 100)
assertEqual(afterSet[1].value, 100)
assertEqual(afterSet[1].previous, nil)

assertTrue(tree:IsA(Tree))
assertTrue(tree:IsA(Entity))
assertTrue(Tree:IsSubclassOf(Entity))
assertTrue(Tree:IsSubclassOf(Tree))
assertEqual(tree:GetClass(), Tree)
assertTrue(LR.Class:IsClass(Tree))
assertTrue(LR.Class:IsInstance(tree, Entity))
assertEqual(LR.Class:IsInstance({}, Entity), false)
assertEqual(Entity:IsSubclassOf(Tree), false)

Entity.Describe = function(instance)
  return "updated:" .. instance.id
end
assertEqual(tree:Describe(), "updated:tree_1", "base method updates must reach existing instances")

tree.water = -10
assertEqual(tree.water, 0)
assertEqual(afterSet[3].previous, 100)
assertError(function() tree.water = "wet" end, "water must be a number")
assertEqual(tree.water, 0, "failed validation must not commit")
assertError(function() tree.ready = true end, "is readonly")

tree.note = false
assertEqual(tree.note, false, "normal instance fields must preserve false values")

local propertyOptions = {}
Tree:Property("health", propertyOptions)
propertyOptions.readonly = true
tree.health = 80
assertEqual(tree.health, 80, "property definitions must be copied from caller metadata")

assertError(function() LR.Class:Define("Broken", {}) end, "must be an LR class")
assertError(function() Tree:New("tree_3", 50) end, "at most one argument")
assertError(function() Tree:Property("water") end, "already declared")
assertError(function() Tree:Property("same", { storage = "same" }) end, "must differ")
assertError(function() Tree:Property("bad", { unknown = true }) end, "unsupported property option")
assertError(function() Tree:Property("badGetter", { get = true }) end, "must be a function")
assertError(function()
  Tree:Property("badReadonly", { readonly = true, set = function(_, value) return value end })
end, "cannot define a setter")

print("PASS class specification")
