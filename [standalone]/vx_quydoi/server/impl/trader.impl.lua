---@class TraderImpl : Impl
local Impl = NewImpl("Trader")

local CATEGORIES = { "chests", "items", "outfits" }
local EMPTY_CATALOG = { chests = {}, items = {}, outfits = {} }
local ITEM_IMAGE_PREFIX = "https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/"
local XN_CLOTHES_ITEMS = {
  component = {
    [1] = { item = "cloth_mask", slot = 7, label = "Mặt nạ" },
    [3] = { item = "cloth_arms", slot = 10, label = "Găng tay" },
    [4] = { item = "cloth_pants", slot = 13, label = "Quần" },
    [5] = { item = "cloth_bags", slot = 17, label = "Túi xách" },
    [6] = { item = "cloth_shoes", slot = 21, label = "Giày" },
    [7] = { item = "cloth_chain", slot = 9, label = "Dây chuyền" },
    [8] = { item = "cloth_tshirt", slot = 18, label = "Áo thun" },
    [9] = { item = "cloth_bproof", slot = 19, label = "Áo chống đạn" },
    [11] = { item = "cloth_torso", slot = 11, label = "Áo khoác" },
  },
  prop = {
    [0] = { item = "cloth_helmet", slot = 6, label = "Mũ" },
    [1] = { item = "cloth_glasses", slot = 8, label = "Kính" },
    [2] = { item = "cloth_ears", slot = 16, label = "Khuyên tai" },
    [6] = { item = "cloth_watches", slot = 12, label = "Đồng hồ" },
    [7] = { item = "cloth_bracelets", slot = 20, label = "Vòng tay" },
  },
}

local function getClothingDefinition(componentId, isProp)
  return (isProp and XN_CLOTHES_ITEMS.prop or XN_CLOTHES_ITEMS.component)[componentId]
end

local function isPositiveInteger(value)
  return type(value) == "number" and value > 0 and value % 1 == 0
end

local function isInteger(value)
  return type(value) == "number" and value % 1 == 0
end

local function copyTable(value)
  if type(value) ~= "table" then return value end

  local result = {}
  for key, nested in pairs(value) do
    result[key] = copyTable(nested)
  end
  return result
end

local function resolveImage(image)
  if type(image) ~= "string" or image == "" then
    return "./assets/no-picture.png"
  end

  if image:find("^https?://") or image:find("^%./") or image:find("^/") then
    return image
  end

  return ("%s%s.webp"):format(ITEM_IMAGE_PREFIX, image)
end

local function resolveOutfitImage(entry)
  if type(entry.image) == "string" and entry.image ~= "" then
    return entry.image
  end

  local imageConfig = Config.XNClothes or {}
  local imageUrl = imageConfig.ImageUrl
  local imageExtension = imageConfig.ImageExtension or "webp"
  if type(imageUrl) ~= "string" or imageUrl == "" then
    return nil
  end

  local gender = entry.gender
  for _, component in ipairs(entry.components or {}) do
    if type(component) == "table" and component.drawable >= 0 then
      return ("%s/%s_%s_%s.%s"):format(
        imageUrl,
        gender,
        component.component_id,
        component.drawable,
        imageExtension
      )
    end
  end

  for _, prop in ipairs(entry.props or {}) do
    local propId = type(prop) == "table" and (prop.component_id or prop.prop_id)
    if type(prop) == "table" and propId and prop.drawable >= 0 then
      return ("%s/%s_prop_%s_%s.%s"):format(
        imageUrl,
        gender,
        propId,
        prop.drawable,
        imageExtension
      )
    end
  end

  return nil
end

function Impl:Init()
  self.entries = {}
  self.catalog = { chests = {}, items = {}, outfits = {} }
  self.locks = {}
  self.cooldowns = {}
  self.maxExchangeQuantity = Config.MaxExchangeQuantity

  if not isPositiveInteger(self.maxExchangeQuantity) then
    self:LogError("Config.MaxExchangeQuantity must be a positive integer; falling back to 999")
    self.maxExchangeQuantity = 999
  end

  self:BuildCatalog()
  self:RegisterHandlers()
  self:LogInfo("%s initialized with %s trades", self:GetName(), self:GetEntryCount())
end

function Impl:GetEntryCount()
  local count = 0
  for _ in pairs(self.entries) do count = count + 1 end
  return count
end

function Impl:ValidateItem(itemName, context)
  if type(itemName) ~= "string" or not exports.ox_inventory:Items(itemName) then
    self:LogError("Invalid inventory item '%s' in %s", tostring(itemName), context)
    return false
  end
  return true
end

function Impl:ValidateOutfit(entry)
  if entry.gender ~= "male" and entry.gender ~= "female" then
    return false, "gender must be male or female"
  end
  local components = entry.components or {}
  local props = entry.props or {}
  if type(components) ~= "table" or type(props) ~= "table" or (#components == 0 and #props == 0) then
    return false, "components or props must not be empty"
  end

  for index, component in ipairs(components) do
    local definition = type(component) == "table" and getClothingDefinition(component.component_id, false)
    if type(component) ~= "table"
      or not definition
      or not isInteger(component.component_id)
      or component.component_id < 0
      or not isInteger(component.drawable)
      or component.drawable < -1
      or not isInteger(component.texture)
      or component.texture < 0 then
      return false, ("invalid component at index %s"):format(index)
    end
  end
  for index, prop in ipairs(props) do
    local propId = type(prop) == "table" and (prop.component_id or prop.prop_id)
    local definition = type(prop) == "table" and getClothingDefinition(propId, true)
    if type(prop) ~= "table"
      or not definition
      or not isInteger(propId)
      or propId < 0
      or not isInteger(prop.drawable)
      or prop.drawable < -1
      or not isInteger(prop.texture)
      or prop.texture < 0 then
      return false, ("invalid prop at index %s"):format(index)
    end
  end
  return true
end

function Impl:NormalizeEntry(category, entry, context, seenIds)
  if type(entry) ~= "table"
    or type(entry.id) ~= "string"
    or entry.id == ""
    or seenIds[entry.id] then
    self:LogError("Invalid or duplicate trade id in %s", context)
    return nil
  end
  if type(entry.name) ~= "string" or entry.name == "" then
    self:LogError("Missing trade name in %s", context)
    return nil
  end
  if type(entry.costs) ~= "table" or #entry.costs == 0 then
    self:LogError("Trade costs must not be empty in %s", context)
    return nil
  end
  if entry.maxQuantity ~= nil and not isPositiveInteger(entry.maxQuantity) then
    self:LogError("Invalid maxQuantity in %s", context)
    return nil
  end

  local costItems = {}
  for costIndex, cost in ipairs(entry.costs) do
    if type(cost) ~= "table"
      or not self:ValidateItem(cost.item, ("%s.costs[%s]"):format(context, costIndex))
      or not isPositiveInteger(cost.amount) then
      self:LogError("Invalid trade cost in %s.costs[%s]", context, costIndex)
      return nil
    end
    if costItems[cost.item] then
      self:LogError("Duplicate cost item '%s' in %s", cost.item, context)
      return nil
    end
    costItems[cost.item] = true
  end

  if category == "outfits" then
    local outfitValid, reason = self:ValidateOutfit(entry)
    if not outfitValid then
      self:LogError("Invalid outfit in %s: %s", context, reason)
      return nil
    end
    for componentId, definition in pairs(XN_CLOTHES_ITEMS.component) do
      if not self:ValidateItem(definition.item, context .. ".component_items[" .. componentId .. "]") then
        return nil
      end
    end
    for propId, definition in pairs(XN_CLOTHES_ITEMS.prop) do
      if not self:ValidateItem(definition.item, context .. ".prop_items[" .. propId .. "]") then
        return nil
      end
    end
  elseif type(entry.reward) ~= "table" then
    self:LogError("Invalid reward in %s", context)
    return nil
  elseif entry.reward.type == "vehicle" then
    if type(entry.reward.model) ~= "string" or entry.reward.model == "" then
      self:LogError("Vehicle reward model is missing in %s", context)
      return nil
    end
  elseif not self:ValidateItem(entry.reward.item, context .. ".reward")
    or not isPositiveInteger(entry.reward.amount) then
    self:LogError("Invalid reward in %s", context)
    return nil
  end

  local normalized = copyTable(entry)
  normalized.category = category
  local configuredImage = category == "outfits" and resolveOutfitImage(entry) or entry.image
  normalized.image = resolveImage(configuredImage)
  if category == "outfits" then
    normalized.props = normalized.props or {}
    normalized.maxQuantity = 1
  end
  if normalized.reward and normalized.reward.type == "vehicle" then
    normalized.maxQuantity = 1
  end
  return normalized
end

function Impl:BuildCatalog()
  local seenIds = {}

  for _, category in ipairs(CATEGORIES) do
    local configured = Config.Trades and Config.Trades[category] or {}
    if type(configured) ~= "table" then
      self:LogError("Config.Trades.%s must be a table", category)
    else
      for index, entry in ipairs(configured) do
        local context = ("Config.Trades.%s[%s]"):format(category, index)
        local normalized = self:NormalizeEntry(category, entry, context, seenIds)
        if normalized then
          seenIds[entry.id] = true
          self.entries[entry.id] = normalized
          self.catalog[category][#self.catalog[category] + 1] = normalized
        end
      end
    end
  end
end

function Impl:GetRewards(entry)
  if entry.reward and entry.reward.type == "vehicle" then
    return {}
  end

  if entry.category ~= "outfits" then
    return {{
      item = entry.reward.item,
      amount = entry.reward.amount,
      metadata = entry.reward.metadata,
    }}
  end

  local rewards = {}
  local imageConfig = Config.XNClothes or {}
  local imageExtension = imageConfig.ImageExtension or "webp"

  for _, component in ipairs(entry.components or {}) do
    local definition = getClothingDefinition(component.component_id, false)
    if definition and component.drawable >= 0 then
      rewards[#rewards + 1] = {
        item = definition.item,
        amount = 1,
        slot = definition.slot,
        metadata = {
          type = "component",
          sex = entry.gender,
          drawable = component.drawable,
          id = component.component_id,
          texture = component.texture,
          label = ("%s %s-%s"):format(definition.label, component.component_id, component.drawable),
          description = ("Trang phục %s"):format(entry.gender == "male" and "Nam" or "Nữ"),
          imageurl = ("%s/%s_%s_%s.%s"):format(imageConfig.ImageUrl, entry.gender, component.component_id, component.drawable, imageExtension),
        },
      }
    end
  end

  for _, prop in ipairs(entry.props or {}) do
    local propId = prop.component_id or prop.prop_id
    local definition = getClothingDefinition(propId, true)
    if definition and prop.drawable >= 0 then
      rewards[#rewards + 1] = {
        item = definition.item,
        amount = 1,
        slot = definition.slot,
        metadata = {
          type = "prop",
          sex = entry.gender,
          drawable = prop.drawable,
          id = propId,
          texture = prop.texture,
          label = ("%s %s-%s"):format(definition.label, propId, prop.drawable),
          description = ("Trang phục %s"):format(entry.gender == "male" and "Nam" or "Nữ"),
          imageurl = ("%s/%s_prop_%s_%s.%s"):format(imageConfig.ImageUrl, entry.gender, propId, prop.drawable, imageExtension),
        },
      }
    end
  end

  return rewards
end

function Impl:GetCatalog(source)
  local player = exports.qbx_core:GetPlayer(source)
  if not player then return copyTable(EMPTY_CATALOG) end

  local result = { chests = {}, items = {}, outfits = {} }
  local owned = {}

  for _, category in ipairs(CATEGORIES) do
    for _, entry in ipairs(self.catalog[category]) do
      local displayEntry = {
        id = entry.id,
        name = entry.name,
        image = entry.image,
        badge = entry.badge,
        gender = entry.gender,
        special = entry.special,
        vehicleModel = entry.reward and entry.reward.type == "vehicle" and entry.reward.model or nil,
        rewardAmount = entry.reward and entry.reward.type == "vehicle"
          and 1
          or (entry.category == "outfits" and 1 or entry.reward.amount),
        maxQuantity = math.min(self.maxExchangeQuantity, entry.maxQuantity or self.maxExchangeQuantity),
        costs = {},
      }

      for _, cost in ipairs(entry.costs) do
        if owned[cost.item] == nil then
          owned[cost.item] = exports.ox_inventory:GetItemCount(source, cost.item) or 0
        end
        local itemData = exports.ox_inventory:Items(cost.item)
        displayEntry.costs[#displayEntry.costs + 1] = {
          item = cost.item,
          label = itemData and itemData.label or cost.item,
          owned = owned[cost.item],
          required = cost.amount,
        }
        displayEntry.maxQuantity = math.min(
          displayEntry.maxQuantity,
          math.floor(owned[cost.item] / cost.amount)
        )
      end

      result[category][#result[category] + 1] = displayEntry
    end
  end

  return result
end

function Impl:RollbackCosts(source, removedCosts)
  local restored = true
  for _, cost in ipairs(removedCosts) do
    local success, reason = exports.ox_inventory:AddItem(source, cost.item, cost.amount)
    if not success then
      restored = false
      self:LogError(
        "CRITICAL: failed to restore %sx %s for player %s: %s",
        cost.amount,
        cost.item,
        source,
        tostring(reason)
      )
    end
  end
  return restored
end

function Impl:PerformExchange(source, entryId, quantity)
  local player = exports.qbx_core:GetPlayer(source)
  if not player then
    return { success = false, code = "player_not_found", message = "Không tìm thấy người chơi." }
  end

  local entry = type(entryId) == "string" and self.entries[entryId] or nil
  if not entry then
    return { success = false, code = "invalid_entry", message = "Vật phẩm quy đổi không hợp lệ." }
  end

  if not isPositiveInteger(quantity) or quantity > self.maxExchangeQuantity then
    return { success = false, code = "invalid_quantity", message = "Số lượng quy đổi không hợp lệ." }
  end
  if entry.reward and entry.reward.type == "vehicle" and quantity ~= 1 then
    return { success = false, code = "invalid_quantity", message = "Mỗi lần chỉ được đổi một phương tiện." }
  end

  local now = GetGameTimer()
  local lastExchange = self.cooldowns[source]
  if lastExchange and now - lastExchange < Config.ExchangeCooldown then
    return { success = false, code = "cooldown", message = "Vui lòng chờ trước khi quy đổi tiếp." }
  end

  for _, cost in ipairs(entry.costs) do
    local count = exports.ox_inventory:GetItemCount(source, cost.item) or 0
    local requiredAmount = cost.amount * quantity
    if count < requiredAmount then
      return {
        success = false,
        code = "not_enough_items",
        message = ("Bạn không đủ %s."):format((exports.ox_inventory:Items(cost.item) or {}).label or cost.item),
        catalog = self:GetCatalog(source),
      }
    end
  end

  local rewards = self:GetRewards(entry)
  if entry.reward and entry.reward.type == "vehicle" then
    self.cooldowns[source] = now
    local removedCosts = {}

    for _, cost in ipairs(entry.costs) do
      local requiredAmount = cost.amount * quantity
      local removed = exports.ox_inventory:RemoveItem(source, cost.item, requiredAmount)
      if not removed then
        self:RollbackCosts(source, removedCosts)
        return {
          success = false,
          code = "remove_failed",
          message = "Nguyên liệu đã thay đổi, vui lòng thử lại.",
          catalog = self:GetCatalog(source),
        }
      end
      removedCosts[#removedCosts + 1] = { item = cost.item, amount = requiredAmount }
    end

    local vehicleId, vehicleError = exports.qbx_vehicles:CreatePlayerVehicle({
      model = entry.reward.model,
      citizenid = player.PlayerData.citizenid,
      garage = entry.reward.garage,
    })
    if not vehicleId then
      local restored = self:RollbackCosts(source, removedCosts)
      self:LogWarning(
        "Failed to create vehicle %s for player %s: %s",
        entry.reward.model,
        source,
        json.encode(vehicleError or {})
      )
      return {
        success = false,
        code = restored and "vehicle_create_failed" or "rollback_failed",
        message = restored
          and "Không thể thêm phương tiện; nguyên liệu đã được hoàn lại."
          or "Có lỗi khi hoàn nguyên liệu, vui lòng liên hệ quản trị viên.",
        catalog = self:GetCatalog(source),
      }
    end

    return {
      success = true,
      code = "success",
      message = ("Phương tiện %s đã được thêm vào garage."):format(entry.reward.model),
      catalog = self:GetCatalog(source),
    }
  end

  for _, reward in ipairs(rewards) do
    if reward.slot and exports.ox_inventory:GetSlot(source, reward.slot) then
      return { success = false, code = "inventory_full", message = "Vị trí trang phục chưa trống." }
    end
    if not exports.ox_inventory:CanCarryItem(source, reward.item, reward.amount * quantity, reward.metadata) then
      return { success = false, code = "inventory_full", message = "Túi đồ không đủ chỗ trống." }
    end
  end

  self.cooldowns[source] = now
  local removedCosts = {}
  for _, cost in ipairs(entry.costs) do
    local requiredAmount = cost.amount * quantity
    local removed = exports.ox_inventory:RemoveItem(source, cost.item, requiredAmount)
    if not removed then
      self:RollbackCosts(source, removedCosts)
      return {
        success = false,
        code = "remove_failed",
        message = "Nguyên liệu đã thay đổi, vui lòng thử lại.",
        catalog = self:GetCatalog(source),
      }
    end
    removedCosts[#removedCosts + 1] = {
      item = cost.item,
      amount = requiredAmount,
    }
  end

  local addedRewards = {}
  for _, reward in ipairs(rewards) do
    local amount = reward.amount * quantity
    local added, reason = exports.ox_inventory:AddItem(
      source,
      reward.item,
      amount,
      reward.metadata,
      reward.slot
    )
    if not added then
      for _, addedReward in ipairs(addedRewards) do
        exports.ox_inventory:RemoveItem(
          source,
          addedReward.item,
          addedReward.amount,
          addedReward.metadata,
          addedReward.slot
        )
      end
      local restored = self:RollbackCosts(source, removedCosts)
      self:LogWarning("Failed to add reward %s for player %s: %s", reward.item, source, tostring(reason))
      return {
        success = false,
        code = restored and "add_failed" or "rollback_failed",
        message = restored
          and "Không thể thêm phần thưởng; nguyên liệu đã được hoàn lại."
          or "Có lỗi khi hoàn nguyên liệu, vui lòng liên hệ quản trị viên.",
        catalog = self:GetCatalog(source),
      }
    end
    addedRewards[#addedRewards + 1] = {
      item = reward.item,
      amount = amount,
      metadata = reward.metadata,
      slot = reward.slot,
    }
  end

  return {
    success = true,
    code = "success",
    message = "Vật phẩm đã được thêm vào túi đồ.",
    catalog = self:GetCatalog(source),
  }
end

function Impl:RegisterHandlers()
  lib.callback.register("vx_trader:server:getCatalog", function(source)
    return self:GetCatalog(source)
  end)

  lib.callback.register("vx_trader:server:exchange", function(source, entryId, quantity)
    if self.locks[source] then
      return { success = false, code = "busy", message = "Giao dịch trước đang được xử lý." }
    end

    self.locks[source] = true
    local ok, result = xpcall(function()
      return self:PerformExchange(source, entryId, quantity)
    end, debug.traceback)
    self.locks[source] = nil

    if not ok then
      self:LogError("Exchange error for player %s: %s", source, result)
      return { success = false, code = "server_error", message = "Máy chủ không thể xử lý giao dịch." }
    end
    return result
  end)

  AddEventHandler("playerDropped", function()
    local playerSource = source
    self.locks[playerSource] = nil
    self.cooldowns[playerSource] = nil
  end)
end
