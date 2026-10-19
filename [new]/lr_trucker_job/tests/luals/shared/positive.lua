local stateBagHandler = AddStateBagChangeHandler("", "", function() end)
if stateBagHandler < 0 then
  error("state bag handler must be non-negative")
end

local app = LR.CreateApplication({ name = "fixture", side = "shared" })
app:RegisterModule({
  id = "shared_fixture",
  create = function(context)
    local instance = {}
    function instance:Start(startContext)
      startContext.logger:Debug("started on %s", context.side)
    end
    return instance
  end,
})

---@class LRShared.FixtureEntity : LRShared.ClassInstance
---@field id string
---@field Describe fun(self: LRShared.FixtureEntity): string

---@class LRShared.FixtureEntityClass : LRShared.Class<LRShared.FixtureEntity, string>
---@field init fun(self: LRShared.FixtureEntity, id: string)
---@field Describe fun(self: LRShared.FixtureEntity): string

---@type LRShared.FixtureEntityClass
local Entity = LR.Class:Define("FixtureEntity")

---@param self LRShared.FixtureEntity
---@param id string
function Entity:init(id)
  self.id = id
end

---@param self LRShared.FixtureEntity
---@return string
function Entity:Describe()
  return self.id
end

---@class LRShared.FixtureTree : LRShared.FixtureEntity
---@field water number

---@class LRShared.FixtureTreeInput
---@field id string
---@field water number

---@class LRShared.FixtureTreeClass : LRShared.Class<LRShared.FixtureTree, LRShared.FixtureTreeInput>
---@field init fun(self: LRShared.FixtureTree, input: LRShared.FixtureTreeInput)

---@type LRShared.FixtureTreeClass
local Tree = Entity:Extend("FixtureTree")

---@param self LRShared.FixtureTree
---@param input LRShared.FixtureTreeInput
function Tree:init(input)
  Entity.init(self, input.id)
  self.water = input.water
end

---@type LRShared.ClassProperty<LRShared.FixtureTree, number>
local WaterProperty = {
  set = function(instance, value)
    local _entityId = instance.id
    return value
  end,
}
Tree:Property("water", WaterProperty)

local fixtureTree = Tree:New({id = "tree_1", water = 50})
local fixtureDescription = fixtureTree:Describe()
local fixtureIsEntity = fixtureTree:IsA(Entity)
if fixtureDescription == "" or not fixtureIsEntity then
  error("typed class fixture failed")
end
