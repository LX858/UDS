---@class LRShared.NegativeTree : LRShared.ClassInstance
---@field id string
---@field water number
---@field Rename fun(self: LRShared.NegativeTree, name: string)

---@class LRShared.NegativeTreeInput
---@field id string
---@field water number

---@class LRShared.NegativeTreeClass : LRShared.Class<LRShared.NegativeTree, LRShared.NegativeTreeInput>
---@field init fun(self: LRShared.NegativeTree, input: LRShared.NegativeTreeInput)
---@field Rename fun(self: LRShared.NegativeTree, name: string)

---@type LRShared.NegativeTreeClass
local NegativeTree = LR.Class:Define("NegativeTree")

---@param self LRShared.NegativeTree
---@param input LRShared.NegativeTreeInput
function NegativeTree:init(input)
  self.id = input.id
  self.water = input.water
end

---@param self LRShared.NegativeTree
---@param name string
function NegativeTree:Rename(name)
  self.id = name
end

local tree = NegativeTree:New({id = "tree_1", water = 50})
local _badNew = NegativeTree:New({id = 100, water = "wet"})
tree.water = "wet"
tree:Rename(100)
