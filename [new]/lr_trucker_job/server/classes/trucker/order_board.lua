LRTruckerServer = LRTruckerServer or {}

---@class LRServer.TruckerOrder
---@field id string
---@field routeIndex integer
---@field deliveryRouteIndex integer
---@field name string
---@field level integer
---@field itemId string
---@field itemLabel string
---@field destination string
---@field packageAmount integer
---@field packagePrice integer
---@field logisticsUnits integer
---@field marketStatus string
---@field marketBonus integer
---@field reward integer
---@field xp integer
---@field cargoCategory string
---@field requiredVehicleTier integer
---@field availability? "available"|"route_busy"|"stock_low"
---@field vehicleMode? "owned"|"rental"
---@field vehicleModel? string
---@field ownedVehicleId? integer
---@field vehicleOwnerCitizenId? string
---@field vehiclePlate? string
---@field vehicleProps? table
---@field rewardMultiplier? integer
---@field baseReward? integer
---@field canAccept? boolean
---@field lockReason? string
---@field effectiveReward? integer
---@field kind? "market"|"business"
---@field cargoMode? "pallets"|"tanker"
---@field businessId? string
---@field businessLabel? string
---@field businessStatus? string
---@field distanceKm? number
---@field lines? table[]
---@field fuelLiters? integer
---@field destinationCoords? table
---@field businessOrder? table
---@field rentalFee? integer
---@field rentalKey? string
---@field rentalId? string

---@class LRServer.TruckerOrderBoardInput
---@field config table
---@field nextId fun(prefix: string): string
---@field integration table

---@class LRServer.TruckerOrderBoard : LRShared.ClassInstance
---@field config table
---@field nextId fun(prefix: string): string
---@field integration table
---@field orders LRServer.TruckerOrder[]
---@field activeRoutes table<integer, string>
---@field activeDestinations table<integer, string>
---@field reservations table<string, table>
---@field catalog table<string, table>
---@field catalogOnline boolean
---@field RefreshCatalog fun(self: LRServer.TruckerOrderBoard)
---@field CreateOrder fun(self: LRServer.TruckerOrderBoard, remaining: table<string, integer>, wantedCategory?: string): LRServer.TruckerOrder?
---@field Refill fun(self: LRServer.TruckerOrderBoard)
---@field TickMarket fun(self: LRServer.TruckerOrderBoard)
---@field Find fun(self: LRServer.TruckerOrderBoard, id: string): LRServer.TruckerOrder?, integer?
---@field RemoveAt fun(self: LRServer.TruckerOrderBoard, index: integer)
---@field ReserveOrder fun(self: LRServer.TruckerOrderBoard, order: LRServer.TruckerOrder, teamId: string): boolean, string
---@field SettleOrder fun(self: LRServer.TruckerOrderBoard, order: LRServer.TruckerOrder, teamId: string, delivered: boolean): boolean
---@field IsRouteReserved fun(self: LRServer.TruckerOrderBoard, routeIndex: integer): boolean
---@field ReserveRoute fun(self: LRServer.TruckerOrderBoard, routeIndex: integer, teamId: string): boolean
---@field ReleaseRoute fun(self: LRServer.TruckerOrderBoard, routeIndex: integer, teamId: string): boolean
---@field Serialize fun(self: LRServer.TruckerOrderBoard): LRServer.TruckerOrder[]
---@field Clear fun(self: LRServer.TruckerOrderBoard)

---@class LRServer.TruckerOrderBoardClass : LRShared.Class<LRServer.TruckerOrderBoard, LRServer.TruckerOrderBoardInput>
---@field init fun(self: LRServer.TruckerOrderBoard, input: LRServer.TruckerOrderBoardInput)
---@field RefreshCatalog fun(self: LRServer.TruckerOrderBoard)
---@field CreateOrder fun(self: LRServer.TruckerOrderBoard, remaining: table<string, integer>, wantedCategory?: string): LRServer.TruckerOrder?
---@field Refill fun(self: LRServer.TruckerOrderBoard)
---@field TickMarket fun(self: LRServer.TruckerOrderBoard)
---@field Find fun(self: LRServer.TruckerOrderBoard, id: string): LRServer.TruckerOrder?, integer?
---@field RemoveAt fun(self: LRServer.TruckerOrderBoard, index: integer)
---@field ReserveOrder fun(self: LRServer.TruckerOrderBoard, order: LRServer.TruckerOrder, teamId: string): boolean, string
---@field SettleOrder fun(self: LRServer.TruckerOrderBoard, order: LRServer.TruckerOrder, teamId: string, delivered: boolean): boolean
---@field IsRouteReserved fun(self: LRServer.TruckerOrderBoard, routeIndex: integer): boolean
---@field ReserveRoute fun(self: LRServer.TruckerOrderBoard, routeIndex: integer, teamId: string): boolean
---@field ReleaseRoute fun(self: LRServer.TruckerOrderBoard, routeIndex: integer, teamId: string): boolean
---@field Serialize fun(self: LRServer.TruckerOrderBoard): LRServer.TruckerOrder[]
---@field Clear fun(self: LRServer.TruckerOrderBoard)

---@type LRServer.TruckerOrderBoardClass
local OrderBoard = LR.Class:Define("TruckerOrderBoard")

local ORDER_COUNT = 10

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

local function distance(first, second)
  local x, y, z = first.x - second.x, first.y - second.y, first.z - second.z
  return math.sqrt(x * x + y * y + z * z)
end

---@param self LRServer.TruckerOrderBoard
---@param input LRServer.TruckerOrderBoardInput
function OrderBoard:init(input)
  self.config = input.config
  self.nextId = input.nextId
  self.integration = input.integration
  self.orders = {}
  self.activeRoutes = {}
  self.activeDestinations = {}
  self.reservations = {}
  self.catalog = {}
  self.catalogOnline = false
end

local function capacityTier(packageAmount)
  if packageAmount <= 8 then return 0 end
  if packageAmount <= 10 then return 1 end
  if packageAmount <= 15 then return 2 end
  return 3
end

local function weightedChoice(choices)
  local total = 0
  for _, choice in ipairs(choices) do total = total + choice.available end
  if total <= 0 then return nil end
  local roll = math.random(1, total)
  for _, choice in ipairs(choices) do
    roll = roll - choice.available
    if roll <= 0 then return choice end
  end
end

local function availableChoices(self, remaining, wantedCategory)
  local choices = {}
  for _, item in pairs(self.catalog) do
    local available = remaining[item.itemName] or 0
    if available > 0 and (not wantedCategory or item.category == wantedCategory) then
      local routes = {}
      for routeIndex, route in ipairs(self.config.Routes) do
        local configured = self.config.Market.Items[route.itemId]
        if configured and configured.category == item.category then
          routes[#routes + 1] = routeIndex
        end
      end
      if #routes > 0 then
        choices[#choices + 1] = { item = item, routes = routes, available = available }
      end
    end
  end
  return choices
end

local function requiredTier(config, category, packageAmount)
  local categoryTier = config.Fleet.CategoryTier[category] or 3
  return math.max(categoryTier, capacityTier(packageAmount))
end

---@param self LRServer.TruckerOrderBoard
---@return LRServer.TruckerOrder?
function OrderBoard:CreateOrder(remaining, wantedCategory)
  local choice = weightedChoice(availableChoices(self, remaining, wantedCategory))
  if not choice then return nil end
  local routeIndex = choice.routes[math.random(1, #choice.routes)]
  local deliveryRouteIndex = math.random(1, #self.config.Routes)
  local item = choice.item
  local route = self.config.Routes[routeIndex]
  local deliveryRoute = self.config.Routes[deliveryRouteIndex]
  local maximum = math.min(self.config.Market.MaxOrderUnits, choice.available,
    self.config.Market.UnitsPerPackage * 21)
  -- This is the maximum stock assigned to the hidden offer. The chosen
  -- rental determines the actual amount reserved when the driver accepts it.
  local logisticsUnits = maximum
  local packageAmount = math.ceil(logisticsUnits / self.config.Market.UnitsPerPackage)
  local marketStatus = choice.available <= 50 and "shortage"
    or choice.available >= self.config.Market.MaxOrderUnits and "surplus" or "balanced"
  local routeDistanceKm = distance(route.pickup.parking, deliveryRoute.delivery.parking) / 1000
  local category = tostring(item.category or "")
  return {
    id = self.nextId("order"),
    routeIndex = routeIndex,
    deliveryRouteIndex = deliveryRouteIndex,
    name = ("Phân phối %s"):format(item.label),
    level = 1,
    itemId = item.itemName,
    itemLabel = item.label,
    destination = deliveryRoute.destination,
    packageAmount = packageAmount,
    packagePrice = item.price,
    logisticsUnits = logisticsUnits,
    marketStatus = marketStatus,
    marketBonus = 0,
    reward = self.config.Market.NpcContractFee
      + logisticsUnits * self.config.Market.NpcPayPerUnit
      + self.config.Market.NpcTimeBonusMax,
    xp = route.xp,
    cargoCategory = category,
    requiredVehicleTier = requiredTier(self.config, category, packageAmount),
    kind = "market",
    cargoMode = item.itemName == "dau_tho" and "tanker" or "pallets",
    distanceKm = routeDistanceKm,
  }
end

---@param self LRServer.TruckerOrderBoard
function OrderBoard:RefreshCatalog()
  local source = self.integration and self.integration:GetCatalog()
  self.catalogOnline = type(source) == "table"
  self.catalog = {}
  if not self.catalogOnline then return end
  for _, item in ipairs(source) do
    local id = tostring(item.itemName or "")
    if id ~= "" then
      self.catalog[id] = {
        itemName = id, label = tostring(item.label or id),
        category = tostring(item.category or ""),
        price = math.max(0, math.floor(tonumber(item.price) or 0)),
        availableAmount = math.max(0, math.floor(tonumber(item.availableAmount) or 0)),
      }
    end
  end
end

---@param self LRServer.TruckerOrderBoard
function OrderBoard:Refill()
  self:RefreshCatalog()
  if not self.catalogOnline then return end
  local remaining = {}
  for itemId, item in pairs(self.catalog) do remaining[itemId] = item.availableAmount end
  local existing = self.orders
  self.orders = {}
  for _, order in ipairs(existing) do
    if not self.reservations[order.id]
      and (remaining[order.itemId] or 0) >= order.logisticsUnits then
      self.orders[#self.orders + 1] = order
      remaining[order.itemId] = remaining[order.itemId] - order.logisticsUnits
    end
  end
  local categories = {}
  for _, route in ipairs(self.config.Routes) do
    local configured = self.config.Market.Items[route.itemId]
    if configured then categories[configured.category] = true end
  end
  local categoryNames = {}
  for category in pairs(categories) do categoryNames[#categoryNames + 1] = category end
  table.sort(categoryNames)
  for _, category in ipairs(categoryNames) do
    if #self.orders >= ORDER_COUNT then break end
    local hasOffer = false
    for _, order in ipairs(self.orders) do
      if order.cargoCategory == category then hasOffer = true; break end
    end
    if not hasOffer then
      local order = self:CreateOrder(remaining, category)
      if order then
        self.orders[#self.orders + 1] = order
        remaining[order.itemId] = remaining[order.itemId] - order.logisticsUnits
      end
    end
  end
  while #self.orders < ORDER_COUNT do
    local order = self:CreateOrder(remaining)
    if not order then break end
    self.orders[#self.orders + 1] = order
    remaining[order.itemId] = remaining[order.itemId] - order.logisticsUnits
  end
end

---@param self LRServer.TruckerOrderBoard
function OrderBoard:TickMarket()
  self.orders = {}
  self:Refill()
end

---@param self LRServer.TruckerOrderBoard
---@param id string
---@return LRServer.TruckerOrder?, integer?
function OrderBoard:Find(id)
  for index = 1, #self.orders do
    if self.orders[index].id == id then return self.orders[index], index end
  end
  return nil, nil
end

---@param self LRServer.TruckerOrderBoard
---@param index integer
function OrderBoard:RemoveAt(index)
  table.remove(self.orders, index)
  self:Refill()
end

---@param self LRServer.TruckerOrderBoard
---@param order LRServer.TruckerOrder
---@param teamId string
---@return boolean, string
function OrderBoard:ReserveOrder(order, teamId)
  if self.reservations[order.id] then return false, "ORDER_RESERVED" end
  local advertised = self:Find(order.id)
  if not advertised or order.logisticsUnits < 1
    or order.logisticsUnits > advertised.logisticsUnits then return false, "ORDER_EXPIRED" end
  if self.activeRoutes[order.routeIndex]
    or self.activeDestinations[order.deliveryRouteIndex] then return false, "ROUTE_RESERVED" end
  self.activeRoutes[order.routeIndex] = teamId
  self.activeDestinations[order.deliveryRouteIndex] = teamId
  -- The source keeps cancelled reservation IDs for idempotency. A later
  -- attempt on the same board offer therefore needs a fresh hold ID.
  local reservationId = self.nextId("npc-hold")
  local reserved, reason = self.integration:ReserveLine(reservationId, order.itemId, order.logisticsUnits)
  if not reserved then
    self.activeRoutes[order.routeIndex] = nil
    self.activeDestinations[order.deliveryRouteIndex] = nil
    return false, reason or "STOCK_UNAVAILABLE"
  end
  self.reservations[order.id] = {
    teamId = teamId,
    routeIndex = order.routeIndex,
    deliveryRouteIndex = order.deliveryRouteIndex,
    reservationId = reservationId,
  }
  return true, ""
end

---@param self LRServer.TruckerOrderBoard
---@param order LRServer.TruckerOrder
---@param teamId string
---@param delivered boolean
---@return boolean
function OrderBoard:SettleOrder(order, teamId, delivered)
  local reservation = self.reservations[order.id]
  if not reservation or reservation.teamId ~= teamId
    or self.activeRoutes[reservation.routeIndex] ~= teamId
    or self.activeDestinations[reservation.deliveryRouteIndex] ~= teamId then return false end
  local settled = self.integration:SettleLine(reservation.reservationId, delivered)
  if not settled then return false end
  self.reservations[order.id] = nil
  self.activeRoutes[reservation.routeIndex] = nil
  self.activeDestinations[reservation.deliveryRouteIndex] = nil
  return true
end

---@param self LRServer.TruckerOrderBoard
---@param routeIndex integer
---@return boolean
function OrderBoard:IsRouteReserved(routeIndex)
  return self.activeRoutes[routeIndex] ~= nil
end

---@param self LRServer.TruckerOrderBoard
---@param routeIndex integer
---@param teamId string
---@return boolean
function OrderBoard:ReserveRoute(routeIndex, teamId)
  if self.activeRoutes[routeIndex] then return false end
  self.activeRoutes[routeIndex] = teamId
  return true
end

---@param self LRServer.TruckerOrderBoard
---@param routeIndex integer
---@param teamId string
---@return boolean
function OrderBoard:ReleaseRoute(routeIndex, teamId)
  if self.activeRoutes[routeIndex] ~= teamId then return false end
  self.activeRoutes[routeIndex] = nil
  return true
end

---@param self LRServer.TruckerOrderBoard
---@return LRServer.TruckerOrder[]
function OrderBoard:Serialize()
  self:Refill()
  local orders = {}
  for index = 1, #self.orders do
    local order = self.orders[index]
    local source = self.catalog[order.itemId]
    local availability = not self.catalogOnline and "source_unavailable" or "available"
    if availability == "available" and (self.activeRoutes[order.routeIndex]
      or self.activeDestinations[order.deliveryRouteIndex]) then
      availability = "route_busy"
    elseif availability == "available" and (not source or source.availableAmount < order.logisticsUnits) then
      availability = "stock_low"
    end
    orders[index] = {
      id = order.id,
      routeIndex = order.routeIndex,
      name = order.name,
      level = order.level,
      itemId = order.itemId,
      itemLabel = order.itemLabel,
      destination = order.destination,
      packageAmount = order.packageAmount,
      packagePrice = order.packagePrice,
      logisticsUnits = order.logisticsUnits,
      marketStatus = order.marketStatus,
      marketBonus = order.marketBonus,
      availability = availability,
      reward = order.reward,
      xp = order.xp,
      cargoCategory = order.cargoCategory,
      requiredVehicleTier = order.requiredVehicleTier,
      cargoMode = order.cargoMode,
      distanceKm = order.distanceKm,
    }
  end
  return orders
end

---@param self LRServer.TruckerOrderBoard
function OrderBoard:Clear()
  self.orders = {}
  self.activeRoutes = {}
  self.activeDestinations = {}
  self.reservations = {}
  self.catalog = {}
  self.catalogOnline = false
end

LRTruckerServer.OrderBoard = OrderBoard
