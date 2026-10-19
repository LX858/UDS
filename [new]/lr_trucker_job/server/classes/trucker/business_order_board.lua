LRTruckerServer = LRTruckerServer or {}

local Database = assert(LRTruckerServer.Database)

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

local function distance(first, second)
  local x, y, z = first.x - second.x, first.y - second.y, first.z - second.z
  return math.sqrt(x * x + y * y + z * z)
end

local function ceilDivide(value, divisor)
  return math.floor((value + divisor - 1) / divisor)
end

---@class LRServer.BusinessOrderBoard
local BusinessOrderBoard = LR.Class:Define("BusinessOrderBoard")

function BusinessOrderBoard:init(input)
  self.config = input.config.BusinessOrders
  self.integration = input.integration
  self.nextId = input.nextId
  self.logger = input.logger
  self.pendingReleases = {}
  self.delivering = {}
end

function BusinessOrderBoard:ResolveBusiness(playerSource, player, businessId)
  local business = self.config.Businesses[businessId]
  if business then
    if not player or not player.job or player.job.name ~= business.job or player.job.onDuty ~= true then
      return nil, "Bạn phải là nhân viên đang trong ca"
    end
    return business, nil
  end
  local location = tonumber(tostring(businessId):match("^gas_station_(%d+)$"))
  if not location then return nil, "Doanh nghiệp không tồn tại" end
  local context = self.integration:GetFuelContext(playerSource, location)
  if not context then return nil, "Bạn không có quyền đặt hàng cho trạm này" end
  local station
  for _, candidate in ipairs(self.integration:GetFuelStations()) do
    if candidate.location == location then station = candidate break end
  end
  if not station then return nil, "Không tìm thấy vị trí trạm" end
  return {
    label = context.label,
    adapter = "fuel",
    stationLocation = location,
    orderPoint = vector4(station.x, station.y, station.z, station.h),
    delivery = {
      parking = vector4(station.x, station.y, station.z, station.h),
      packages = vector3(station.x, station.y, station.z),
      forklifts = {},
    },
    allowedItems = { dau_tho = true },
    balance = context.balance,
    fuel = context.fuel,
    maxFuel = context.maxFuel,
  }, nil
end

function BusinessOrderBoard:IsNear(playerSource, business)
  local ped = GetPlayerPed(playerSource)
  if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
  return distance(GetEntityCoords(ped), business.orderPoint) <= self.config.ActionDistance
end

function BusinessOrderBoard:CatalogFor(business)
  local source = self.integration:GetCatalog()
  if not source then return {}, false end
  local allowed = {}
  for itemId, enabled in pairs(business.allowedItems) do if enabled then allowed[itemId] = true end end
  local catalog = {}
  for _, item in ipairs(source) do
    local id = tostring(item.itemName or "")
    local mapping = self.config.Items[id]
    if allowed[id] and mapping then
      catalog[#catalog + 1] = {
        itemId = id,
        label = tostring(item.label or id),
        category = tostring(item.category or ""),
        unitPrice = math.max(0, math.floor(tonumber(item.price) or 0)),
        available = math.max(0, math.floor(tonumber(item.availableAmount) or 0)),
        unitsPerPackage = mapping.unitsPerPackage,
        destinationMultiplier = mapping.destinationMultiplier,
        destinationUnit = mapping.destinationUnit,
        destinationItemId = mapping.destinationItemId,
        destinationLabel = mapping.destinationLabel,
      }
    end
  end
  table.sort(catalog, function(first, second) return first.label < second.label end)
  return catalog, true
end

function BusinessOrderBoard:Serialize(order, sourceOnline, catalogById, includeIdentity)
  local stockReady, missing = sourceOnline, {}
  local mappingReady = true
  local lines = {}
  local categorySet, categoryKeys = {}, {}
  local cargoUnits = 0
  for _, line in ipairs(order.lines) do
    local category = tostring(line.category or "")
    if category ~= "" and not categorySet[category] then
      categorySet[category] = true
      categoryKeys[#categoryKeys + 1] = category
    end
    cargoUnits = cargoUnits + line.quantity
    if order.adapter == "stash" and (not line.destinationItemId or line.destinationItemId == "") then
      mappingReady = false
    end
    -- Database reservation/escrow fields must never cross the public contract.
    lines[#lines + 1] = {
      itemId = line.itemId, label = line.label, category = line.category,
      quantity = line.quantity, unitPrice = line.unitPrice, subtotal = line.subtotal,
      packages = line.packages, destinationAmount = line.destinationAmount,
      destinationUnit = line.destinationUnit,
      destinationItemId = line.destinationItemId,
      destinationLabel = line.destinationLabel,
    }
    local available = catalogById[line.itemId] and catalogById[line.itemId].available or 0
    if available < line.quantity then
      stockReady = false
      missing[#missing + 1] = ("%s thiếu %d"):format(line.label, line.quantity - available)
    end
  end
  table.sort(categoryKeys)
  local availability = not sourceOnline and "source_unavailable"
    or stockReady and "available" or "stock_low"
  return {
    id = order.id,
    routeIndex = 1,
    name = includeIdentity and ("Giao nguyên liệu cho " .. order.businessLabel) or "Đơn giao doanh nghiệp",
    level = 1,
    itemId = includeIdentity and (order.lines[1] and order.lines[1].itemId or "business") or "business",
    itemLabel = includeIdentity and (#order.lines == 1 and order.lines[1].destinationLabel
      or ("%d mặt hàng"):format(#order.lines)) or "Hàng doanh nghiệp",
    destination = includeIdentity and order.destination or "Tiết lộ sau khi nhận đơn",
    packageAmount = order.packageAmount,
    packagePrice = includeIdentity and order.goodsTotal or 0,
    logisticsUnits = cargoUnits,
    marketStatus = stockReady and "balanced" or "shortage",
    marketBonus = 0,
    availability = availability,
    reward = order.deliveryFee,
    effectiveReward = order.deliveryFee,
    xp = math.max(50, order.packageAmount * 15),
    cargoCategory = order.cargoMode == "tanker" and "fuel" or "business",
    categoryKeys = categoryKeys,
    requiredVehicleTier = order.packageAmount <= 8 and 0
      or order.packageAmount <= 10 and 1
      or order.packageAmount <= 15 and 2 or 3,
    canAccept = availability == "available" and mappingReady,
    lockReason = not mappingReady and "Đơn cần cập nhật nguyên liệu trước khi nhận"
      or not sourceOnline and "Nguồn xn-sellitem đang gián đoạn"
      or (#missing > 0 and (includeIdentity and table.concat(missing, ", ") or "Kho chưa đủ hàng") or ""),
    kind = "business",
    cargoMode = order.cargoMode,
    businessId = includeIdentity and order.businessId or "",
    businessLabel = includeIdentity and order.businessLabel or "",
    businessStatus = order.status,
    distanceKm = includeIdentity and order.distanceKm or 0,
    lines = includeIdentity and lines or {},
  }
end

function BusinessOrderBoard:GetContext(playerSource, player, businessId)
  local business, reason = self:ResolveBusiness(playerSource, player, businessId)
  if not business or not self:IsNear(playerSource, business) then
    return nil, reason or "Bạn đang ở quá xa điểm đặt hàng"
  end
  local catalog, sourceOnline = self:CatalogFor(business)
  if business.adapter == "stash" and self.integration.IsBusinessEnabled
    and not self.integration:IsBusinessEnabled(businessId) then catalog = {} end
  if business.adapter == "fuel" and self.integration.IsFuelEnabled
    and not self.integration:IsFuelEnabled() then catalog = {} end
  local balance = business.balance
  if balance == nil then balance = self.integration:GetSocietyBalance(business.accountId or business.job) end
  if balance == nil then return nil, "Quỹ doanh nghiệp đang gián đoạn" end
  local rows = Database.ListBusinessHistory(businessId, 20)
  local byId = {}
  for _, item in ipairs(catalog) do byId[item.itemId] = item end
  local orders = {}
  for _, row in ipairs(rows) do
    if row.status ~= "delivered" and row.status ~= "cancelled" then
      orders[#orders + 1] = self:Serialize(row, sourceOnline, byId, true)
    end
  end
  return {
    active = true,
    sourceOnline = sourceOnline,
    businessId = businessId,
    label = business.label,
    balance = balance,
    distanceKm = math.max(0.1, distance(self.config.Pickup.parking, business.delivery.parking) / 1000),
    feeBase = 0,
    feePerKm = 0,
    feePerPackage = 0,
    feeMaximum = 0,
    feeRate = self.config.Fees.percent,
    catalog = catalog,
    orders = orders,
  }, nil
end

function BusinessOrderBoard:Create(playerSource, player, businessId, requestedLines)
  local business, reason = self:ResolveBusiness(playerSource, player, businessId)
  if not business or not self:IsNear(playerSource, business) then
    return false, reason or "Bạn đang ở quá xa điểm đặt hàng"
  end
  if business.adapter == "stash" and self.integration.IsBusinessEnabled
    and not self.integration:IsBusinessEnabled(businessId) then
    return false, "Đơn giao cho cửa hàng đang tạm đóng"
  end
  if business.adapter == "fuel" and self.integration.IsFuelEnabled
    and not self.integration:IsFuelEnabled() then
    return false, "Đơn nhập nhiên liệu đang tạm đóng"
  end
  if #requestedLines < 1 or #requestedLines > self.config.MaxLines then
    return false, "Mỗi đơn phải có từ 1 đến 6 mặt hàng"
  end
  local catalog, sourceOnline = self:CatalogFor(business)
  if not sourceOnline then return false, "Nguồn xn-sellitem đang gián đoạn" end
  local byId = {}
  for _, item in ipairs(catalog) do byId[item.itemId] = item end
  local seen, lines, goodsTotal, packageCount, cargoUnits, stockReady = {}, {}, 0, 0, 0, true
  for index, requested in ipairs(requestedLines) do
    local itemId = tostring(requested.itemId or "")
    local quantity = math.floor(tonumber(requested.quantity) or 0)
    local item = byId[itemId]
    if not item or seen[itemId] or quantity < 1 or quantity > 10000 then
      return false, "Giỏ hàng không hợp lệ"
    end
    seen[itemId] = true
    local packages = ceilDivide(quantity, item.unitsPerPackage)
    local subtotal = quantity * item.unitPrice
    packageCount, goodsTotal = packageCount + packages, goodsTotal + subtotal
    cargoUnits = cargoUnits + quantity
    stockReady = stockReady and item.available >= quantity
    lines[index] = {
      itemId = itemId, label = item.label, category = item.category,
      quantity = quantity, unitPrice = item.unitPrice, subtotal = subtotal,
      packages = packages,
      destinationAmount = quantity * item.destinationMultiplier,
      destinationUnit = item.destinationUnit,
      destinationItemId = item.destinationItemId,
      destinationLabel = item.destinationLabel,
    }
  end
  if cargoUnits > self.config.MaxUnits then return false, "Đơn vượt quá tải trọng 250 vật phẩm" end
  if packageCount > self.config.MaxPackages then return false, "Đơn vượt quá 21 kiện quy đổi" end
  if business.adapter == "fuel" then
    local liters = lines[1].destinationAmount
    if (business.fuel or 0) + liters > (business.maxFuel or 0) then
      return false, "Dự trữ trạm không đủ sức chứa"
    end
  end
  if business.adapter == "stash" and not self.integration:CanCarryStashBasket(business.stashId, lines) then
    return false, "Kho không đủ trọng lượng hoặc ô trống cho toàn bộ nguyên liệu nhận"
  end
  local pickup = self.config.Pickup.parking
  local distanceKm = math.max(0.1, distance(pickup, business.delivery.parking) / 1000)
  local deliveryFee = math.floor(goodsTotal * self.config.Fees.percent / 100)
  local orderId = self.nextId("business")
  local total = goodsTotal + deliveryFee
  local paid = business.adapter == "fuel"
    and self.integration:DebitFuel(playerSource, business.stationLocation, orderId, total)
    or self.integration:DebitSociety(business.accountId or business.job, total)
  if not paid then return false, "Quỹ doanh nghiệp không đủ hoặc đang bận" end
  local order = {
    id = orderId, businessId = businessId, businessLabel = business.label,
    adapter = business.adapter, accountId = business.accountId or business.job,
    stashId = business.stashId or "", stationLocation = business.stationLocation or 0,
    createdBy = player.citizenId, status = stockReady and "available" or "waiting_stock",
    cargoMode = business.adapter == "fuel" and "tanker" or "pallets",
    destination = business.label, destinationCoords = business.delivery.parking,
    distanceKm = distanceKm, packageAmount = packageCount, goodsTotal = goodsTotal,
    deliveryFee = deliveryFee, escrowTotal = total, lines = lines,
  }
  if Database.CreateBusinessOrder(order) then return true, "Đã tạo đơn giao nguyên liệu" end
  if business.adapter == "fuel" then
    self.integration:RefundFuel(business.stationLocation, orderId)
  else
    self.integration:RefundSociety(order.accountId, total)
  end
  return false, "Không thể lưu đơn; tiền đã được hoàn"
end

function BusinessOrderBoard:List(filter, page, pageSize)
  local rows, total = Database.ListBusinessOrders("board", page, pageSize)
  local catalog, online = self:CatalogFor({
    allowedItems = { coconut = true, la_che = true, luami = true,
      conheo = true, conbo = true, luanuoc = true, dau_tho = true },
  })
  local byId = {}
  for _, item in ipairs(catalog) do byId[item.itemId] = item end
  local items = {}
  for _, row in ipairs(rows) do items[#items + 1] = self:Serialize(row, online, byId) end
  return items, total
end

function BusinessOrderBoard:Find(orderId)
  local order = Database.GetBusinessOrder(orderId)
  if not order or (order.status ~= "available" and order.status ~= "waiting_stock") then return nil end
  local catalog, online = self:CatalogFor({
    allowedItems = { coconut = true, la_che = true, luami = true,
      conheo = true, conbo = true, luanuoc = true, dau_tho = true },
  })
  local byId = {}
  for _, item in ipairs(catalog) do byId[item.itemId] = item end
  local serialized = self:Serialize(order, online, byId, true)
  if not serialized.canAccept then return nil end
  -- Only mission creation receives these server-only fields; List/GetContext
  -- must continue returning the strict public representation above.
  serialized.businessOrder = order
  serialized.destinationCoords = order.destinationCoords
  serialized.fuelLiters = order.cargoMode == "tanker"
    and (order.lines[1] and order.lines[1].destinationAmount or 0) or 0
  return serialized
end

function BusinessOrderBoard:Reserve(order, teamId)
  local stored = Database.GetBusinessOrder(order.id)
  if not stored or not Database.TransitionBusinessOrder(stored.id, { "available", "waiting_stock" }, "reserving", {
    team_id = teamId, mission_id = stored.id,
  }) then return false, "ORDER_RESERVED" end
  -- Read the version after the conditional claim, never from a cached snapshot.
  -- Versions persist across restarts, so cancelled reservation IDs are not reused.
  stored = Database.GetBusinessOrder(order.id)
  if not stored or stored.status ~= "reserving" or stored.teamId ~= teamId then
    return false, "DATABASE_ERROR"
  end
  local function rollback(reason)
    if not self:Release({ id = stored.id }, teamId) then
      self.pendingReleases[stored.id] = teamId
      return false, "RESERVATION_RELEASE_PENDING"
    end
    return false, reason
  end
  for index, line in ipairs(stored.lines) do
    local reservationId = stored.id .. ":v" .. tostring(stored.version) .. ":" .. tostring(index)
    if #reservationId > 64 then return rollback("DATABASE_ERROR") end
    -- Persist intent before touching the provider, including the crash/timeout window.
    if not Database.SetBusinessLineReservation(stored.id, index, reservationId, "reserved") then
      return rollback("DATABASE_ERROR")
    end
    local ok, reason = self.integration:ReserveLine(reservationId, line.itemId, line.quantity)
    if not ok then
      self.logger:Warn("business reservation %s rejected: %s", reservationId, tostring(reason))
      return rollback(type(reason) == "string" and reason ~= "" and reason or "RESERVATION_REJECTED")
    end
  end
  if not Database.TransitionBusinessOrder(stored.id, { "reserving" }, "in_transit") then
    return rollback("DATABASE_ERROR")
  end
  order.businessOrder = Database.GetBusinessOrder(stored.id)
  return true, ""
end

function BusinessOrderBoard:Deliver(order)
  if self.delivering[order.id] then return false end
  self.delivering[order.id] = true
  local ok, result = pcall(self.DeliverStored, self, order)
  self.delivering[order.id] = nil
  if not ok then self.logger:Warn("business import %s failed: %s", order.id, tostring(result)) end
  return ok and result == true
end

function BusinessOrderBoard:DeliverStored(order)
  local stored = Database.GetBusinessOrder(order.id)
  if not stored then return false end
  if stored.status == "delivered" then return true end
  if stored.status ~= "in_transit" then return false end
  if stored.adapter == "fuel" then
    local liters = 0
    for _, line in ipairs(stored.lines) do liters = liters + line.destinationAmount end
    local delivered, reason = self.integration:CreditFuel(
      stored.stationLocation, stored.id, stored.id .. ":fuel", liters
    )
    if not delivered then
      self.logger:Warn("fuel delivery %s blocked: %s", stored.id, reason)
      return false
    end
  else
    local pending = {}
    for index, line in ipairs(stored.lines) do
      if not line.destinationItemId or line.destinationItemId == "" then return false end
      local deliveryId = stored.id .. ":stash:" .. tostring(index)
      if not Database.HasDeliveryReceipt(deliveryId)
        and not self.integration:HasStashDelivery(stored.stashId, line.destinationItemId, deliveryId) then
        pending[#pending + 1] = line
      end
    end
    if #pending > 0 and not self.integration:CanCarryStashBasket(stored.stashId, pending) then return false end
    for index, line in ipairs(stored.lines) do
      local deliveryId = stored.id .. ":stash:" .. tostring(index)
      if not Database.HasDeliveryReceipt(deliveryId) then
        local metadata = { deliveryId = deliveryId, businessOrderId = stored.id }
        if not self.integration:HasStashDelivery(stored.stashId, line.destinationItemId, deliveryId) then
          if not self.integration:CanCarryStash(stored.stashId, line.destinationItemId, line.destinationAmount, metadata)
            or not self.integration:AddStashItem(stored.stashId, line.destinationItemId, line.destinationAmount, metadata) then
            return false
          end
        end
        if not Database.CreateDeliveryReceipt(deliveryId, stored.id, index, "stash", line.destinationAmount) then
          return false
        end
      end
    end
  end
  for index, line in ipairs(stored.lines) do
    local reservationId = line.reservationId and line.reservationId ~= "" and line.reservationId
      or stored.id .. ":" .. tostring(index)
    if not self.integration:SettleLine(reservationId, true) then return false end
    Database.SetBusinessLineReservation(stored.id, index, reservationId, "settled")
  end
  return Database.TransitionBusinessOrder(stored.id, { "in_transit" }, "delivered", {
    escrow_state = "released",
  })
end

function BusinessOrderBoard:MarkPaid(orderId)
  return Database.TransitionBusinessOrder(orderId, { "delivered" }, "delivered", {
    payout_state = "paid",
  })
end

function BusinessOrderBoard:Release(order, teamId)
  -- Share the settlement lock: cancellation cannot release raw stock while an
  -- import is waiting on its database receipt (or vice versa).
  if self.delivering[order.id] then return false end
  self.delivering[order.id] = true
  local ok, result = pcall(self.ReleaseStored, self, order, teamId)
  self.delivering[order.id] = nil
  if not ok then self.logger:Warn("business release %s failed: %s", order.id, tostring(result)) end
  return ok and result == true
end

function BusinessOrderBoard:ReleaseStored(order, teamId)
  local stored = Database.GetBusinessOrder(order.id)
  if not stored or (stored.teamId ~= "" and stored.teamId ~= teamId) then return false end
  if stored.status ~= "reserving" and stored.status ~= "in_transit" then return false end
  -- Once import has begun, resume settlement instead of releasing raw stock or
  -- allowing a second driver to deliver already-created ingredients.
  if stored.adapter == "stash" then
    for index, line in ipairs(stored.lines) do
      local deliveryId = stored.id .. ":stash:" .. tostring(index)
      if Database.HasDeliveryReceipt(deliveryId) or
        self.integration:HasStashDelivery(stored.stashId, line.destinationItemId, deliveryId) then
        -- Cancellation must not finalize a mission without its normal payout.
        -- Keep it open for Finish/retry; imported goods must never release stock.
        return false
      end
    end
  end
  for index, line in ipairs(stored.lines) do
    if line.reservationState == "reserved" then
      local reservationId = line.reservationId and line.reservationId ~= "" and line.reservationId
        or stored.id .. ":" .. tostring(index)
      local released, reason = self.integration:SettleLine(reservationId, false)
      -- A persisted intent can exist even if the provider never created the hold.
      if not released and reason ~= "RESERVATION_NOT_FOUND" then return false end
      if not Database.SetBusinessLineReservation(stored.id, index, reservationId, "released") then return false end
    end
  end
  local reopened = Database.TransitionBusinessOrder(stored.id, { "reserving", "in_transit" }, "waiting_stock", {
    team_id = "", mission_id = "",
  })
  if reopened then self.pendingReleases[stored.id] = nil end
  return reopened
end

function BusinessOrderBoard:Cancel(playerSource, player, orderId)
  local order = Database.GetBusinessOrder(orderId)
  if not order then return false, "Đơn hàng không tồn tại" end
  local business, reason = self:ResolveBusiness(playerSource, player, order.businessId)
  if not business or not self:IsNear(playerSource, business) then return false, reason or "Bạn đang ở quá xa" end
  if not Database.TransitionBusinessOrder(order.id, { "waiting_stock", "available" }, "cancelled") then
    return false, "Đơn đã có tài xế hoặc đã kết thúc"
  end
  local refunded = order.adapter == "fuel"
    and self.integration:RefundFuel(order.stationLocation, order.id)
    or self.integration:RefundSociety(order.accountId, order.escrowTotal)
  if not refunded then
    Database.TransitionBusinessOrder(order.id, { "cancelled" }, order.status)
    return false, "Chưa thể hoàn quỹ; vui lòng thử lại"
  end
  Database.TransitionBusinessOrder(order.id, { "cancelled" }, "cancelled", { escrow_state = "refunded" })
  return true, "Đã hủy đơn và hoàn toàn bộ tiền"
end

function BusinessOrderBoard:Recover()
  local rows = Database.ListBusinessOrders("active", 1, 10000)
  for _, order in ipairs(rows) do
    if order.status == "reserving" or order.status == "in_transit" then
      self.pendingReleases[order.id] = order.teamId
    end
  end
  return self:RetryPendingReleases()
end

function BusinessOrderBoard:RetryPendingReleases()
  local reopened = 0
  for orderId, teamId in pairs(self.pendingReleases) do
    local stored = Database.GetBusinessOrder(orderId)
    local imported = false
    if stored and stored.adapter == "stash" then
      for index, line in ipairs(stored.lines) do
        local id = orderId .. ":stash:" .. tostring(index)
        if Database.HasDeliveryReceipt(id) or self.integration:HasStashDelivery(stored.stashId, line.destinationItemId, id) then
          imported = true
          break
        end
      end
    end
    if imported then
      if self:Deliver({ id = orderId }) then
        self.pendingReleases[orderId] = nil
        reopened = reopened + 1
      end
    elseif self:Release({ id = orderId }, teamId) then
      reopened = reopened + 1
    end
  end
  return reopened
end

LRTruckerServer.BusinessOrderBoard = BusinessOrderBoard
