---@class MainImpl : Impl
local Impl = NewImpl("Main")

local PLAYER_TABLE = "vx_case2_players"
local OPERATION_TABLE = "vx_case2_operations"
local RECEIPT_TABLE = "vx_case2_milestone_receipts"
local REFUND_TABLE = "vx_case2_pending_refunds"

local function now()
  return os.time()
end

local function clampInteger(value, minimum, maximum)
  local number = tonumber(value)
  if not number or number ~= math.floor(number) then return nil end
  if number < minimum or number > maximum then return nil end
  return number
end

local function decodeJson(value, fallback)
  if type(value) ~= "string" or value == "" then return fallback end
  local ok, decoded = pcall(json.decode, value)
  if not ok or decoded == nil then return fallback end
  return decoded
end

local function copyPublicItem(item)
  return {
    id = item.id,
    name = item.name,
    label = item.label,
    image = item.image,
  }
end

function Impl:Init()
  self.locks = {}
  self.priceItemsById = {}
  self.uniquePriceItems = {}

  local names = {}
  for _, item in ipairs(Config.PriceItems or {}) do
    self.priceItemsById[tostring(item.id)] = item
    if not names[item.name] then
      names[item.name] = true
      self.uniquePriceItems[#self.uniquePriceItems + 1] = item
    end
  end

  if #self.uniquePriceItems < 6 then
    error("Config.PriceItems must contain at least 6 unique item names")
  end
  if #(Config.SpinRewards or {}) ~= 8 then
    self:LogWarning("Config.SpinRewards should contain exactly 8 entries")
  end

  self:RegisterCallbacks()
  self:RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
    local playerSource = source
    CreateThread(function()
      Wait(1000)
      local player, citizenid = self:GetPlayer(playerSource)
      if not player then return end
      self:WithLock(citizenid, function()
        local row = self:EnsureState(citizenid)
        self:ProcessPendingRefunds(playerSource, citizenid, player)
        self:RetryMilestone(playerSource, citizenid, row)
      end)
    end)
  end)
  self:LogInfo("%s initialized", self:GetName())
end

function Impl:OnReady()
  self:CreateTables()
end

function Impl:CreateTables()
  MySQL.query.await(([=[
    CREATE TABLE IF NOT EXISTS `%s` (
      `citizenid` VARCHAR(64) NOT NULL,
      `coin_balance` INT UNSIGNED NOT NULL DEFAULT 0,
      `purchase_progress` INT UNSIGNED NOT NULL DEFAULT 0,
      `spin_credits` INT UNSIGNED NOT NULL DEFAULT 1,
      `pending_discount` TINYINT UNSIGNED NULL,
      `shop_item_ids` LONGTEXT NOT NULL,
      `first_spin_granted` TINYINT(1) NOT NULL DEFAULT 1,
      `milestone_claimed` TINYINT(1) NOT NULL DEFAULT 0,
      `spin_locked_until` BIGINT UNSIGNED NOT NULL DEFAULT 0,
      `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ]=]):format(PLAYER_TABLE))

  MySQL.query.await(([=[
    CREATE TABLE IF NOT EXISTS `%s` (
      `request_id` VARCHAR(80) NOT NULL,
      `citizenid` VARCHAR(64) NOT NULL,
      `action` VARCHAR(24) NOT NULL,
      `status` ENUM('processing', 'completed') NOT NULL DEFAULT 'processing',
      `response_json` LONGTEXT NULL,
      `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`request_id`),
      KEY `idx_case2_operation_citizen` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ]=]):format(OPERATION_TABLE))

  MySQL.query.await(([=[
    CREATE TABLE IF NOT EXISTS `%s` (
      `citizenid` VARCHAR(64) NOT NULL,
      `reward_key` VARCHAR(80) NOT NULL,
      `status` ENUM('processing', 'delivered') NOT NULL DEFAULT 'processing',
      `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`citizenid`, `reward_key`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ]=]):format(RECEIPT_TABLE))

  MySQL.query.await(([=[
    CREATE TABLE IF NOT EXISTS `%s` (
      `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
      `citizenid` VARCHAR(64) NOT NULL,
      `account` VARCHAR(24) NOT NULL,
      `amount` INT UNSIGNED NOT NULL,
      `reason` VARCHAR(80) NOT NULL,
      `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `idx_case2_refund_citizen` (`citizenid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ]=]):format(REFUND_TABLE))

  self:LogSuccess("Database tables are ready")
end

function Impl:GetPlayer(source)
  local player = exports.qbx_core:GetPlayer(source)
  if not player or not player.PlayerData or not player.PlayerData.citizenid then
    return nil, nil
  end
  return player, player.PlayerData.citizenid
end

function Impl:WithLock(citizenid, callback)
  if self.locks[citizenid] then
    return { ok = false, message = "Thao tác trước đang được xử lý, vui lòng thử lại" }
  end

  self.locks[citizenid] = true
  local packed = table.pack(xpcall(callback, debug.traceback))
  self.locks[citizenid] = nil
  if not packed[1] then
    self:LogError("Mutation failed for %s: %s", citizenid, packed[2])
    return { ok = false, message = "Hệ thống đang bận, vui lòng thử lại" }
  end
  return table.unpack(packed, 2, packed.n)
end

function Impl:GenerateShop(previousIds)
  local pool = {}
  for index, item in ipairs(self.uniquePriceItems) do pool[index] = item end
  for index = #pool, 2, -1 do
    local swap = math.random(index)
    pool[index], pool[swap] = pool[swap], pool[index]
  end

  local selected = {}
  for index = 1, 6 do selected[index] = pool[index].id end

  if previousIds and #previousIds == 6 then
    local previousSet = {}
    for _, itemId in ipairs(previousIds) do previousSet[tostring(itemId)] = true end
    local sameContents = true
    for _, itemId in ipairs(selected) do
      if not previousSet[tostring(itemId)] then
        sameContents = false
        break
      end
    end
    if sameContents then
      for _, candidate in ipairs(pool) do
        if not previousSet[tostring(candidate.id)] then
          selected[6] = candidate.id
          break
        end
      end
    end
  end
  return selected
end

function Impl:GetRow(citizenid)
  return MySQL.single.await(("SELECT * FROM `%s` WHERE `citizenid` = ? LIMIT 1"):format(PLAYER_TABLE), { citizenid })
end

function Impl:IsValidShop(itemIds)
  if type(itemIds) ~= "table" or #itemIds ~= 6 then return false end
  local names = {}
  for _, itemId in ipairs(itemIds) do
    local item = self.priceItemsById[tostring(itemId)]
    if not item or names[item.name] then return false end
    names[item.name] = true
  end
  return true
end

function Impl:EnsureState(citizenid)
  local row = self:GetRow(citizenid)
  if row then
    local itemIds = decodeJson(row.shop_item_ids, {})
    if self:IsValidShop(itemIds) then return row end
    local repairedIds = self:GenerateShop(itemIds)
    MySQL.update.await(("UPDATE `%s` SET `shop_item_ids` = ? WHERE `citizenid` = ?"):format(PLAYER_TABLE), {
      json.encode(repairedIds), citizenid
    })
    return self:GetRow(citizenid)
  end

  local shopIds = self:GenerateShop()
  MySQL.insert.await(([=[
    INSERT IGNORE INTO `%s`
      (`citizenid`, `coin_balance`, `purchase_progress`, `spin_credits`, `shop_item_ids`, `first_spin_granted`)
    VALUES (?, 0, 0, 1, ?, 1)
  ]=]):format(PLAYER_TABLE), { citizenid, json.encode(shopIds) })
  return self:GetRow(citizenid)
end

function Impl:EffectivePrice(basePrice, discount)
  local price = math.max(0, math.floor(tonumber(basePrice) or 0))
  if price == 0 then return 0 end
  if not discount or discount <= 0 then return price end
  return math.max(1, math.floor(price * (100 - discount) / 100))
end

function Impl:SerializeState(source, row)
  local discount = tonumber(row.pending_discount)
  local itemIds = decodeJson(row.shop_item_ids, {})
  local shopItems = {}
  for _, itemId in ipairs(itemIds) do
    local item = self.priceItemsById[tostring(itemId)]
    if item then
      local public = copyPublicItem(item)
      public.basePrice = math.floor(tonumber(item.price) or 0)
      public.price = self:EffectivePrice(item.price, discount)
      if item.priceMoney ~= nil then
        public.basePriceMoney = math.floor(tonumber(item.priceMoney) or 0)
        public.priceMoney = self:EffectivePrice(item.priceMoney, discount)
      end
      shopItems[#shopItems + 1] = public
    end
  end

  local cashBalance = 0
  local player = exports.qbx_core:GetPlayer(source)
  if player and player.Functions and player.Functions.GetMoney then
    cashBalance = tonumber(player.Functions.GetMoney(Config.CashAccount)) or 0
  end

  local lockedUntil = tonumber(row.spin_locked_until) or 0
  local spinCredits = tonumber(row.spin_credits) or 0
  return {
    coins = tonumber(row.coin_balance) or 0,
    cashBalance = cashBalance,
    progress = math.min(tonumber(row.purchase_progress) or 0, Config.MilestoneTarget),
    milestoneTarget = Config.MilestoneTarget,
    spinCredits = spinCredits,
    canSpin = spinCredits > 0 and discount == nil and lockedUntil <= now(),
    pendingDiscount = discount,
    shopItems = shopItems,
    refreshCost = Config.RefreshCost,
    maxPurchaseQuantity = Config.MaxPurchaseQuantity,
    milestoneClaimed = tonumber(row.milestone_claimed) == 1,
    actionLockedUntil = lockedUntil,
    serverTime = now(),
    spinRewards = Config.SpinRewards,
  }
end

function Impl:DeliverItem(source, citizenid, itemName, amount, metadata)
  local inventoryCall, added, inventoryMessage = pcall(function()
    return exports.ox_inventory:AddItem(source, itemName, amount, metadata or {})
  end)
  if inventoryCall and added then return true, "inventory" end
  if not inventoryCall then inventoryMessage = added end

  if GetResourceState("xn_buucuc") == "started" then
    local canCall, canStore, storageMessage = pcall(function()
      return exports.xn_buucuc:CanAddToPersonalStorage(citizenid, itemName, amount)
    end)
    if canCall and canStore then
      local storeCall, stored, addMessage = pcall(function()
        return exports.xn_buucuc:AddItemToPersonalStorage(citizenid, itemName, amount, metadata or {})
      end)
      if storeCall and stored then return true, "postal" end
      inventoryMessage = (storeCall and addMessage or stored) or inventoryMessage
    elseif canCall then
      inventoryMessage = storageMessage or inventoryMessage
    end
  end

  return false, inventoryMessage or "Không còn chỗ nhận vật phẩm"
end

function Impl:CanDeliver(source, citizenid, itemName, amount, metadata)
  local inventoryCall, canCarry = pcall(function()
    return exports.ox_inventory:CanCarryItem(source, itemName, amount, metadata or {})
  end)
  if inventoryCall and canCarry then return true end

  if GetResourceState("xn_buucuc") == "started" then
    local postalCall, canStore = pcall(function()
      return exports.xn_buucuc:CanAddToPersonalStorage(citizenid, itemName, amount)
    end)
    if postalCall and canStore then return true end
  end
  return false
end

function Impl:ProcessPendingRefunds(source, citizenid, player)
  local refunds = MySQL.query.await(("SELECT * FROM `%s` WHERE `citizenid` = ? ORDER BY `id` ASC"):format(REFUND_TABLE), { citizenid }) or {}
  for _, refund in ipairs(refunds) do
    local refunded = player.Functions.AddMoney(refund.account, tonumber(refund.amount), refund.reason)
    if refunded == true then
      MySQL.update.await(("DELETE FROM `%s` WHERE `id` = ?"):format(REFUND_TABLE), { refund.id })
      TriggerClientEvent("vx_case2:client:notify", source, ("Đã hoàn lại %s IG từ giao dịch trước"):format(refund.amount), "success")
    else
      break
    end
  end
end

function Impl:RefundCash(citizenid, player, amount)
  local refunded = player and player.Functions and player.Functions.AddMoney
    and player.Functions.AddMoney(Config.CashAccount, amount, "vx-case2-purchase-refund")
  if refunded == true then return true end

  MySQL.insert.await(("INSERT INTO `%s` (`citizenid`, `account`, `amount`, `reason`) VALUES (?, ?, ?, ?)"):format(REFUND_TABLE), {
    citizenid, Config.CashAccount, amount, "vx-case2-pending-refund"
  })
  return false
end

function Impl:RetryMilestone(source, citizenid, row)
  if tonumber(row.milestone_claimed) == 1 then return false end
  if (tonumber(row.purchase_progress) or 0) < Config.MilestoneTarget then return false end
  if #(Config.RewardItems or {}) == 0 then
    self:LogWarning("Milestone reached by %s but Config.RewardItems is empty", citizenid)
    return false
  end

  for _, reward in ipairs(Config.RewardItems) do
    local receipt = MySQL.single.await(("SELECT `status` FROM `%s` WHERE `citizenid` = ? AND `reward_key` = ?"):format(RECEIPT_TABLE), {
      citizenid, reward.key
    })
    if not receipt then
      local reserved = MySQL.update.await(("INSERT IGNORE INTO `%s` (`citizenid`, `reward_key`, `status`) VALUES (?, ?, 'processing')"):format(RECEIPT_TABLE), {
        citizenid, reward.key
      })
      if reserved and reserved > 0 then
        local delivered = self:DeliverItem(source, citizenid, reward.name, reward.amount or 1, reward.metadata)
        if delivered then
          MySQL.update.await(("UPDATE `%s` SET `status` = 'delivered' WHERE `citizenid` = ? AND `reward_key` = ?"):format(RECEIPT_TABLE), {
            citizenid, reward.key
          })
        else
          MySQL.update.await(("DELETE FROM `%s` WHERE `citizenid` = ? AND `reward_key` = ? AND `status` = 'processing'"):format(RECEIPT_TABLE), {
            citizenid, reward.key
          })
          return false
        end
      end
    elseif receipt.status ~= "delivered" then
      return false
    end
  end

  local deliveredCount = tonumber(MySQL.scalar.await(("SELECT COUNT(*) FROM `%s` WHERE `citizenid` = ? AND `status` = 'delivered'"):format(RECEIPT_TABLE), { citizenid })) or 0
  if deliveredCount >= #Config.RewardItems then
    MySQL.update.await(("UPDATE `%s` SET `milestone_claimed` = 1 WHERE `citizenid` = ?"):format(PLAYER_TABLE), { citizenid })
    return true
  end
  return false
end

function Impl:GetCachedOperation(requestId, citizenid, action)
  if type(requestId) ~= "string" or #requestId < 8 or #requestId > 80 then
    return nil, "Mã yêu cầu không hợp lệ"
  end
  local operation = MySQL.single.await(("SELECT * FROM `%s` WHERE `request_id` = ? LIMIT 1"):format(OPERATION_TABLE), { requestId })
  if operation then
    if operation.citizenid ~= citizenid or operation.action ~= action then
      return nil, "Mã yêu cầu đã được sử dụng"
    end
    if operation.status == "completed" then
      return decodeJson(operation.response_json, { ok = false, message = "Không đọc được kết quả cũ" }), nil
    end
    return nil, "Yêu cầu đang được xử lý"
  end
  MySQL.insert.await(("INSERT INTO `%s` (`request_id`, `citizenid`, `action`) VALUES (?, ?, ?)"):format(OPERATION_TABLE), {
    requestId, citizenid, action
  })
  return false, nil
end

function Impl:CompleteOperation(requestId, response)
  MySQL.update.await(("UPDATE `%s` SET `status` = 'completed', `response_json` = ? WHERE `request_id` = ?"):format(OPERATION_TABLE), {
    json.encode(response), requestId
  })
  return response
end

function Impl:GetState(source)
  local player, citizenid = self:GetPlayer(source)
  if not player then return { ok = false, message = "Không tìm thấy nhân vật" } end
  return self:WithLock(citizenid, function()
    self:ProcessPendingRefunds(source, citizenid, player)
    local row = self:EnsureState(citizenid)
    self:RetryMilestone(source, citizenid, row)
    row = self:GetRow(citizenid)
    return { ok = true, state = self:SerializeState(source, row) }
  end)
end

function Impl:Spin(source, data)
  local _, citizenid = self:GetPlayer(source)
  if not citizenid then return { ok = false, message = "Không tìm thấy nhân vật" } end
  return self:WithLock(citizenid, function()
    local requestId = data and data.requestId
    local cached, operationError = self:GetCachedOperation(requestId, citizenid, "spin")
    if cached then
      cached.state = self:SerializeState(source, self:EnsureState(citizenid))
      return cached
    end
    if operationError then return { ok = false, message = operationError } end

    local row = self:EnsureState(citizenid)
    local response
    if (tonumber(row.spin_locked_until) or 0) > now() then
      response = { ok = false, message = "Vòng quay đang khóa trong thời gian nhận thưởng", state = self:SerializeState(source, row) }
    elseif row.pending_discount ~= nil then
      response = { ok = false, message = "Hãy dùng ưu đãi hiện tại trước khi quay tiếp", state = self:SerializeState(source, row) }
    elseif (tonumber(row.spin_credits) or 0) <= 0 then
      response = { ok = false, message = "Bạn chưa có lượt quay", state = self:SerializeState(source, row) }
    elseif #(Config.SpinRewards or {}) == 0 then
      response = { ok = false, message = "Chưa cấu hình phần thưởng vòng quay", state = self:SerializeState(source, row) }
    else
      local rewardIndex = math.random(#Config.SpinRewards)
      local reward = Config.SpinRewards[rewardIndex]
      local credits = math.max(0, (tonumber(row.spin_credits) or 0) - 1)
      local coins = tonumber(row.coin_balance) or 0
      local discount = nil
      if reward.type == "coins" then
        coins = coins + math.max(0, math.floor(tonumber(reward.value) or 0))
        credits = credits + 1
      elseif reward.type == "freeSpin" then
        credits = credits + math.max(1, math.floor(tonumber(reward.value) or 1))
      elseif reward.type == "discount" then
        discount = math.max(1, math.min(99, math.floor(tonumber(reward.value) or 0)))
      else
        response = { ok = false, message = "Loại phần thưởng không hợp lệ", state = self:SerializeState(source, row) }
      end

      if not response then
        local lockedUntil = now() + Config.ActionLockSeconds
        MySQL.update.await(([=[
          UPDATE `%s`
          SET `coin_balance` = ?, `spin_credits` = ?, `pending_discount` = ?, `spin_locked_until` = ?
          WHERE `citizenid` = ?
        ]=]):format(PLAYER_TABLE), { coins, credits, discount, lockedUntil, citizenid })
        row = self:GetRow(citizenid)
        response = {
          ok = true,
          message = "Bắt đầu quay, chúc bạn may mắn!",
          state = self:SerializeState(source, row),
          result = { index = rewardIndex - 1, reward = reward },
        }
      end
    end
    return self:CompleteOperation(requestId, response)
  end)
end

function Impl:RefreshItems(source, data)
  local _, citizenid = self:GetPlayer(source)
  if not citizenid then return { ok = false, message = "Không tìm thấy nhân vật" } end
  return self:WithLock(citizenid, function()
    local requestId = data and data.requestId
    local cached, operationError = self:GetCachedOperation(requestId, citizenid, "refresh")
    if cached then
      cached.state = self:SerializeState(source, self:EnsureState(citizenid))
      return cached
    end
    if operationError then return { ok = false, message = operationError } end

    local row = self:EnsureState(citizenid)
    local response
    if (tonumber(row.spin_locked_until) or 0) > now() then
      response = { ok = false, message = "Vui lòng chờ vòng quay kết thúc", state = self:SerializeState(source, row) }
    elseif (tonumber(row.coin_balance) or 0) < Config.RefreshCost then
      response = { ok = false, message = "Bạn không đủ xu để làm mới", state = self:SerializeState(source, row) }
    else
      local oldIds = decodeJson(row.shop_item_ids, {})
      local newIds = self:GenerateShop(oldIds)
      local updated = MySQL.update.await(("UPDATE `%s` SET `coin_balance` = `coin_balance` - ?, `shop_item_ids` = ? WHERE `citizenid` = ? AND `coin_balance` >= ?"):format(PLAYER_TABLE), {
        Config.RefreshCost, json.encode(newIds), citizenid, Config.RefreshCost
      })
      row = self:GetRow(citizenid)
      if updated == 1 then
        response = { ok = true, message = "Đã làm mới cửa hàng", state = self:SerializeState(source, row) }
      else
        response = { ok = false, message = "Bạn không đủ xu để làm mới", state = self:SerializeState(source, row) }
      end
    end
    return self:CompleteOperation(requestId, response)
  end)
end

function Impl:Purchase(source, data)
  local player, citizenid = self:GetPlayer(source)
  if not player then return { ok = false, message = "Không tìm thấy nhân vật" } end
  return self:WithLock(citizenid, function()
    local requestId = data and data.requestId
    local cached, operationError = self:GetCachedOperation(requestId, citizenid, "purchase")
    if cached then
      cached.state = self:SerializeState(source, self:EnsureState(citizenid))
      return cached
    end
    if operationError then return { ok = false, message = operationError } end

    local row = self:EnsureState(citizenid)
    local response
    if (tonumber(row.spin_locked_until) or 0) > now() then
      response = { ok = false, message = "Vui lòng chờ vòng quay kết thúc", state = self:SerializeState(source, row) }
      return self:CompleteOperation(requestId, response)
    end

    local quantity = clampInteger(data and data.quantity, 1, Config.MaxPurchaseQuantity)
    local itemId = data and data.itemId
    local currency = data and data.currency
    if not quantity then
      response = { ok = false, message = "Số lượng không hợp lệ", state = self:SerializeState(source, row) }
      return self:CompleteOperation(requestId, response)
    end

    local allowed = false
    for _, configuredId in ipairs(decodeJson(row.shop_item_ids, {})) do
      if tostring(configuredId) == tostring(itemId) then allowed = true break end
    end
    local item = allowed and self.priceItemsById[tostring(itemId)] or nil
    if not item then
      response = { ok = false, message = "Vật phẩm không còn trong cửa hàng", state = self:SerializeState(source, row) }
      return self:CompleteOperation(requestId, response)
    end
    if currency ~= "coins" and currency ~= "cash" then
      response = { ok = false, message = "Loại thanh toán không hợp lệ", state = self:SerializeState(source, row) }
      return self:CompleteOperation(requestId, response)
    end
    if currency == "cash" and item.priceMoney == nil then
      response = { ok = false, message = "Vật phẩm này chỉ có thể mua bằng xu", state = self:SerializeState(source, row) }
      return self:CompleteOperation(requestId, response)
    end

    local discount = tonumber(row.pending_discount)
    local unitCoinPrice = self:EffectivePrice(item.price, discount)
    local paymentUnitPrice = currency == "cash" and self:EffectivePrice(item.priceMoney, discount) or unitCoinPrice
    local total = paymentUnitPrice * quantity
    local paid = false

    if not self:CanDeliver(source, citizenid, item.name, quantity, item.metadata) then
      response = { ok = false, message = "Túi đồ và bưu cục không còn chỗ nhận vật phẩm", state = self:SerializeState(source, row) }
      return self:CompleteOperation(requestId, response)
    end

    if currency == "coins" then
      if (tonumber(row.coin_balance) or 0) < total then
        response = { ok = false, message = "Bạn không đủ xu", state = self:SerializeState(source, row) }
        return self:CompleteOperation(requestId, response)
      end
      local deducted = MySQL.update.await(("UPDATE `%s` SET `coin_balance` = `coin_balance` - ? WHERE `citizenid` = ? AND `coin_balance` >= ?"):format(PLAYER_TABLE), {
        total, citizenid, total
      })
      paid = deducted == 1
      if not paid then
        row = self:GetRow(citizenid)
        response = { ok = false, message = "Bạn không đủ xu", state = self:SerializeState(source, row) }
        return self:CompleteOperation(requestId, response)
      end
    else
      local cash = tonumber(player.Functions.GetMoney(Config.CashAccount)) or 0
      if cash < total then
        response = { ok = false, message = "Bạn không đủ tiền mặt", state = self:SerializeState(source, row) }
        return self:CompleteOperation(requestId, response)
      end
      paid = player.Functions.RemoveMoney(Config.CashAccount, total, "vx-case2-purchase") == true
      if not paid then
        response = { ok = false, message = "Không thể trừ tiền", state = self:SerializeState(source, row) }
        return self:CompleteOperation(requestId, response)
      end
    end

    local delivered, destination = self:DeliverItem(source, citizenid, item.name, quantity, item.metadata)
    if not delivered then
      if currency == "coins" then
        MySQL.update.await(("UPDATE `%s` SET `coin_balance` = `coin_balance` + ? WHERE `citizenid` = ?"):format(PLAYER_TABLE), { total, citizenid })
      elseif paid then
        self:RefundCash(citizenid, player, total)
      end
      row = self:GetRow(citizenid)
      response = { ok = false, message = "Không thể giao vật phẩm; giao dịch đã được hoàn lại", state = self:SerializeState(source, row) }
      return self:CompleteOperation(requestId, response)
    end

    local progressGain = unitCoinPrice * quantity
    MySQL.update.await(([=[
      UPDATE `%s`
      SET `purchase_progress` = LEAST(?, `purchase_progress` + ?),
          `spin_credits` = `spin_credits` + 1,
          `pending_discount` = NULL
      WHERE `citizenid` = ?
    ]=]):format(PLAYER_TABLE), { Config.MilestoneTarget, progressGain, citizenid })

    row = self:GetRow(citizenid)
    local milestoneDelivered = self:RetryMilestone(source, citizenid, row)
    row = self:GetRow(citizenid)
    response = {
      ok = true,
      message = destination == "postal"
        and "Túi đồ đầy, vật phẩm đã được chuyển vào bưu cục"
        or "Mua vật phẩm thành công",
      state = self:SerializeState(source, row),
      result = {
        itemId = item.id,
        quantity = quantity,
        currency = currency,
        total = total,
        milestoneDelivered = milestoneDelivered,
      },
    }
    return self:CompleteOperation(requestId, response)
  end)
end

function Impl:RegisterCallbacks()
  lib.callback.register("vx_case2:server:GetCaseState", function(source)
    return self:GetState(source)
  end)
  lib.callback.register("vx_case2:server:Spin", function(source, data)
    return self:Spin(source, data or {})
  end)
  lib.callback.register("vx_case2:server:RefreshItems", function(source, data)
    return self:RefreshItems(source, data or {})
  end)
  lib.callback.register("vx_case2:server:Purchase", function(source, data)
    return self:Purchase(source, data or {})
  end)
end

function Impl:OnResourceStop()
  self.locks = {}
end
