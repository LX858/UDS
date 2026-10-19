LRTruckerServer = LRTruckerServer or {}

local PACKAGE_MODEL = "prop_boxpile_06a"
local REWARD_ACCOUNT = "cash"
local REWARD_REASON = "lr_trucker_job"
local PROGRESSION_METADATA = "trucker_xp"

local function distance(first, second)
  if not first or not second then return math.huge end
  local x = first.x - second.x
  local y = first.y - second.y
  local z = first.z - second.z
  return math.sqrt(x * x + y * y + z * z)
end

local function playerCoords(playerSource)
  local ped = GetPlayerPed(playerSource)
  if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end
  return GetEntityCoords(ped), ped
end

local function removeEntity(entity)
  if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
end

local function usesTrailer(session)
  return session.vehicleMode ~= "rental"
    or (session.config.Fleet.TrailerRentals or {})[session.order.rentalKey or ""] == true
end

local function cargoVehicle(session)
  return usesTrailer(session) and session.vehicles.trailer or session.vehicles.truck
end

local function rentalOverage(session, now)
  if session.vehicleMode ~= "rental" then return 0 end
  local fleet = session.config.Fleet
  local seconds = math.max(0, now - session.startedAt - (fleet.RentalMinutes or 60) * 60)
  local minutes = math.ceil(seconds / 60)
  return math.ceil((session.order.rentalFee or 0)
    * (fleet.OveragePercentPerMinute or 3) * minutes / 100)
end

local function rearLoadingOffset(session)
  if session.vehicleMode ~= "rental" or session.order.cargoMode == "tanker" then return nil end
  local fleet = session.config.Fleet
  return fleet and fleet.RearLoading and fleet.RearLoading[session.order.vehicleModel]
end

local function rearLoadingPoint(session)
  local offset = rearLoadingOffset(session)
  local truck = session.vehicles.truck
  if not offset or not truck or truck == 0 or not DoesEntityExist(truck) then return nil end
  local coords = GetEntityCoords(truck)
  local heading = math.rad(GetEntityHeading(truck))
  return vector3(
    coords.x + offset.x * math.cos(heading) - offset.y * math.sin(heading),
    coords.y + offset.x * math.sin(heading) + offset.y * math.cos(heading),
    coords.z + offset.z
  )
end

---@class LRServer.TruckerMissionSessionInput
---@field order LRServer.TruckerOrder
---@field team LRServer.TruckerTeam
---@field ownerSource integer
---@field config table
---@field framework LRServer.FrameworkBridge
---@field logger LRShared.Logger
---@field settleOrder fun(order: LRServer.TruckerOrder, teamId: string, delivered: boolean): boolean
---@field sync fun()
---@field notify fun(noticeType: LRServer.FrameworkNotificationType, message: string)
---@field returnOwnedVehicle? fun(entity: integer, order: LRServer.TruckerOrder): boolean
---@field clearCompleted fun(session: LRServer.TruckerMissionSession)
---@field markPayout? fun(order: LRServer.TruckerOrder): boolean
---@field prepareTeam? fun(session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field payTeam? fun(session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field queueRentalCharge? fun(session: LRServer.TruckerMissionSession, bankDue: integer): boolean
---@field rentalTruck? integer
---@field assessRental? fun(session: LRServer.TruckerMissionSession, grossReward: integer): integer?, integer?
---@field recoverRentalTruck? fun(): integer?

---@class LRServer.TruckerMissionSession : LRShared.ClassInstance
---@field id string
---@field order LRServer.TruckerOrder
---@field team LRServer.TruckerTeam
---@field route table
---@field routeIndex integer
---@field step integer
---@field status string
---@field closed boolean
---@field transitioning boolean
---@field entitiesCleaned boolean
---@field orderSettled boolean
---@field deliveredSettlement boolean
---@field fuelProgress integer
---@field ownedVehicleReturned boolean
---@field bucket integer
---@field vehicleMode "owned"|"rental"
---@field vehicles table<string, integer>
---@field vehicleSpecs table<string, table>
---@field forklifts table[]
---@field packages table[]
---@field config table
---@field framework LRServer.FrameworkBridge
---@field logger LRShared.Logger
---@field settleOrder fun(order: LRServer.TruckerOrder, teamId: string, delivered: boolean): boolean
---@field sync fun()
---@field notify fun(noticeType: LRServer.FrameworkNotificationType, message: string)
---@field returnOwnedVehicle? fun(entity: integer, order: LRServer.TruckerOrder): boolean
---@field clearCompleted fun(session: LRServer.TruckerMissionSession)
---@field markPayout? fun(order: LRServer.TruckerOrder): boolean
---@field prepareTeam? fun(session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field payTeam? fun(session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field queueRentalCharge? fun(session: LRServer.TruckerMissionSession, bankDue: integer): boolean
---@field startedAt integer
---@field paymentTotal? integer
---@field bankDue? integer
---@field payoutMembers? table[]
---@field payoutPrepared? boolean
---@field cancelRentalDue? integer
---@field rentalTruckShared boolean
---@field rentalAssessmentPrepared? boolean
---@field rentalDebtPending? boolean
---@field assessRental? fun(session: LRServer.TruckerMissionSession, grossReward: integer): integer?, integer?
---@field recoverRentalTruck? fun(): integer?
---@field GiveKeys fun(self: LRServer.TruckerMissionSession, vehicle: integer)
---@field SpawnVehicle fun(self: LRServer.TruckerMissionSession, spec: table, vehicleType: string): integer
---@field PackageSpawnCoords fun(self: LRServer.TruckerMissionSession, index: integer): vector3
---@field DeliverySlot fun(self: LRServer.TruckerMissionSession, index: integer): vector3
---@field SpawnPackageAt fun(self: LRServer.TruckerMissionSession, coords: vector3): integer
---@field CleanupForklifts fun(self: LRServer.TruckerMissionSession)
---@field CleanupEntities fun(self: LRServer.TruckerMissionSession)
---@field ReturnOwnedVehicle fun(self: LRServer.TruckerMissionSession): boolean
---@field SpawnForklifts fun(self: LRServer.TruckerMissionSession, specs: table[], phase: string)
---@field Serialize fun(self: LRServer.TruckerMissionSession): table
---@field GiveReconnectKeys fun(self: LRServer.TruckerMissionSession)
---@field GiveJoinKeys fun(self: LRServer.TruckerMissionSession)
---@field ResetCarriedPackages fun(self: LRServer.TruckerMissionSession, playerSource: integer)
---@field SpawnStepVehicles fun(self: LRServer.TruckerMissionSession, step: integer)
---@field SetStep fun(self: LRServer.TruckerMissionSession, step: integer): boolean, string
---@field IsDriving fun(self: LRServer.TruckerMissionSession, playerSource: integer, vehicle: integer): boolean
---@field IsParkedAt fun(self: LRServer.TruckerMissionSession, vehicle: integer, target: vector4): boolean
---@field ForkliftFor fun(self: LRServer.TruckerMissionSession, playerSource: integer): integer?
---@field CountPackageState fun(self: LRServer.TruckerMissionSession, state: string): integer
---@field PaymentDue fun(self: LRServer.TruckerMissionSession, now: integer): integer, integer
---@field Finish fun(self: LRServer.TruckerMissionSession): boolean, string
---@field Advance fun(self: LRServer.TruckerMissionSession, playerSource: integer, expectedStep: integer): boolean, string
---@field ActOnPackage fun(self: LRServer.TruckerMissionSession, playerSource: integer, action: string, packageIndex: integer): boolean, string
---@field Cancel fun(self: LRServer.TruckerMissionSession, waiveOverage?: boolean): boolean
---@field RecoverMissingEntities fun(self: LRServer.TruckerMissionSession)

---@class LRServer.TruckerMissionSessionClass : LRShared.Class<LRServer.TruckerMissionSession, LRServer.TruckerMissionSessionInput>
---@field init fun(self: LRServer.TruckerMissionSession, input: LRServer.TruckerMissionSessionInput)
---@field GiveKeys fun(self: LRServer.TruckerMissionSession, vehicle: integer)
---@field SpawnVehicle fun(self: LRServer.TruckerMissionSession, spec: table, vehicleType: string): integer
---@field PackageSpawnCoords fun(self: LRServer.TruckerMissionSession, index: integer): vector3
---@field DeliverySlot fun(self: LRServer.TruckerMissionSession, index: integer): vector3
---@field SpawnPackageAt fun(self: LRServer.TruckerMissionSession, coords: vector3): integer
---@field CleanupForklifts fun(self: LRServer.TruckerMissionSession)
---@field CleanupEntities fun(self: LRServer.TruckerMissionSession)
---@field ReturnOwnedVehicle fun(self: LRServer.TruckerMissionSession): boolean
---@field SpawnForklifts fun(self: LRServer.TruckerMissionSession, specs: table[], phase: string)
---@field Serialize fun(self: LRServer.TruckerMissionSession): table
---@field GiveReconnectKeys fun(self: LRServer.TruckerMissionSession)
---@field GiveJoinKeys fun(self: LRServer.TruckerMissionSession)
---@field ResetCarriedPackages fun(self: LRServer.TruckerMissionSession, playerSource: integer)
---@field SpawnStepVehicles fun(self: LRServer.TruckerMissionSession, step: integer)
---@field SetStep fun(self: LRServer.TruckerMissionSession, step: integer): boolean, string
---@field IsDriving fun(self: LRServer.TruckerMissionSession, playerSource: integer, vehicle: integer): boolean
---@field IsParkedAt fun(self: LRServer.TruckerMissionSession, vehicle: integer, target: vector4): boolean
---@field ForkliftFor fun(self: LRServer.TruckerMissionSession, playerSource: integer): integer?
---@field CountPackageState fun(self: LRServer.TruckerMissionSession, state: string): integer
---@field PaymentDue fun(self: LRServer.TruckerMissionSession, now: integer): integer, integer
---@field Finish fun(self: LRServer.TruckerMissionSession): boolean, string
---@field Advance fun(self: LRServer.TruckerMissionSession, playerSource: integer, expectedStep: integer): boolean, string
---@field ActOnPackage fun(self: LRServer.TruckerMissionSession, playerSource: integer, action: string, packageIndex: integer): boolean, string
---@field Cancel fun(self: LRServer.TruckerMissionSession, waiveOverage?: boolean): boolean
---@field RecoverMissingEntities fun(self: LRServer.TruckerMissionSession)

---@type LRServer.TruckerMissionSessionClass
local MissionSession = LR.Class:Define("TruckerMissionSession")

---@param self LRServer.TruckerMissionSession
---@param input LRServer.TruckerMissionSessionInput
function MissionSession:init(input)
  local order = input.order
  self.config = input.config
  local route = input.config.Routes[order.routeIndex]
  if order.kind == "market" then
    local destinationRoute = input.config.Routes[order.deliveryRouteIndex]
    assert(route and destinationRoute, "invalid market route")
    route = {
      vehicles = route.vehicles,
      pickup = route.pickup,
      delivery = destinationRoute.delivery,
    }
  elseif order.kind == "business" then
    local businessConfig = input.config.BusinessOrders.Businesses[order.businessId]
    local pickup = input.config.BusinessOrders.Pickup
    local delivery = businessConfig and businessConfig.delivery or {
      parking = vector4(
        order.destinationCoords.x, order.destinationCoords.y,
        order.destinationCoords.z, order.destinationCoords.w or 0.0
      ),
      packages = vector3(
        order.destinationCoords.x, order.destinationCoords.y, order.destinationCoords.z
      ),
      forklifts = {},
    }
    route = {
      vehicles = {
        truck = { model = order.vehicleModel or "phantom", coords = pickup.vehicles.truck.coords },
        trailer = pickup.vehicles.trailer,
        escort = pickup.vehicles.escort,
      },
      pickup = pickup,
      delivery = delivery,
    }
  end
  self.id = order.id
  self.order = order
  self.team = input.team
  self.route = route
  self.routeIndex = order.routeIndex
  self.step = 1
  self.status = "active"
  self.closed = false
  self.transitioning = false
  self.fuelProgress = 0
  self.entitiesCleaned = false
  self.orderSettled = false
  self.deliveredSettlement = false
  self.startedAt = os.time()
  self.paymentTotal = nil
  self.bankDue = nil
  self.ownedVehicleReturned = false
  self.bucket = GetPlayerRoutingBucket(tostring(input.ownerSource))
  self.vehicleMode = order.vehicleMode or "owned"
  self.rentalTruckShared = input.rentalTruck ~= nil and input.rentalTruck ~= 0
  self.vehicles = {}
  self.vehicleSpecs = {
    truck = {
      model = order.vehicleModel or route.vehicles.truck.model,
      coords = route.vehicles.truck.coords,
      type = "automobile",
      owned = self.vehicleMode == "owned",
      vehicleId = order.ownedVehicleId or 0,
      plate = order.vehiclePlate or "TRUCKER",
      props = order.vehicleProps,
    },
  }
  if order.cargoMode == "tanker" then
    self.vehicleSpecs.trailer = { model = "tanker", coords = route.vehicles.trailer, type = "trailer" }
  elseif usesTrailer(self) then
    self.vehicleSpecs.trailer = { model = "trflat", coords = route.vehicles.trailer, type = "trailer" }
    self.vehicleSpecs.escort = { model = "sadler", coords = route.vehicles.escort, type = "automobile" }
  end
  self.forklifts = {}
  self.packages = {}
  self.config = input.config
  self.framework = input.framework
  self.logger = input.logger
  self.settleOrder = input.settleOrder
  self.sync = input.sync
  self.notify = input.notify
  self.returnOwnedVehicle = input.returnOwnedVehicle
  self.clearCompleted = input.clearCompleted
  self.markPayout = input.markPayout
  self.prepareTeam = input.prepareTeam
  self.payTeam = input.payTeam
  self.queueRentalCharge = input.queueRentalCharge
  self.assessRental = input.assessRental
  self.recoverRentalTruck = input.recoverRentalTruck

  local ok, spawnError = xpcall(function()
    self.vehicles.truck = self.rentalTruckShared and input.rentalTruck
      or self:SpawnVehicle(self.vehicleSpecs.truck, "automobile")
    if self.rentalTruckShared then self.vehicleSpecs.truck = nil end
    if self.vehicleSpecs.trailer then
      self.vehicles.trailer = self:SpawnVehicle(self.vehicleSpecs.trailer, "trailer")
      self.vehicles.escort = self.vehicleSpecs.escort
        and self:SpawnVehicle(self.vehicleSpecs.escort, "automobile") or 0
    else
      self.vehicles.trailer, self.vehicles.escort = 0, 0
    end
    if order.cargoMode ~= "tanker" then
      for index = 1, order.packageAmount do
        self.packages[index] = {
          index = index,
          entity = self:SpawnPackageAt(self:PackageSpawnCoords(index)),
          state = "waiting",
          carrierSource = 0,
          slot = 0,
        }
      end
    end
    self:GiveKeys(self.vehicles.truck)
  end, debug.traceback)
  if not ok then
    self:ReturnOwnedVehicle()
    self:CleanupEntities()
    error(spawnError)
  end
end

---@param self LRServer.TruckerMissionSession
---@param vehicle integer
function MissionSession:GiveKeys(vehicle)
  if not vehicle or vehicle == 0 or type(self.framework.GiveVehicleKeys) ~= "function" then return end
  local online = self.team:OnlineMembers()
  for index = 1, #online do
    self.framework:GiveVehicleKeys(online[index].source, vehicle)
  end
end

---@param self LRServer.TruckerMissionSession
---@param spec table
---@param vehicleType string
---@return integer
function MissionSession:SpawnVehicle(spec, vehicleType)
  local entity = CreateVehicleServerSetter(
    GetHashKey(spec.model),
    vehicleType,
    spec.coords.x,
    spec.coords.y,
    spec.coords.z,
    spec.coords.w
  )
  if not entity or entity == 0 then error(("Khong the tao xe %s"):format(spec.model)) end
  SetEntityOrphanMode(entity, 2)
  SetEntityRoutingBucket(entity, self.bucket or 0)
  SetVehicleNumberPlateText(entity, spec.plate or "TRUCKER")
  if spec.owned and type(self.framework.PrepareOwnedVehicle) == "function" then
    local prepared = self.framework:PrepareOwnedVehicle(entity, {
      vehicleId = spec.vehicleId,
      plate = spec.plate,
      props = spec.props,
    })
    if prepared == false then
      removeEntity(entity)
      error("Khong the khoi tao xe so huu")
    end
  end
  return entity
end

---@param self LRServer.TruckerMissionSession
---@param index integer
---@return vector3
function MissionSession:PackageSpawnCoords(index)
  local base = self.route.pickup.packages
  local column = (index - 1) % 3
  local row = math.floor((index - 1) / 3) % 3
  local stack = math.floor((index - 1) / 9)
  return vector3(base.x + column * 1.35, base.y + row * 1.35, base.z + stack * 1.0 - 0.7)
end

---@param self LRServer.TruckerMissionSession
---@param index integer
---@return vector3
function MissionSession:DeliverySlot(index)
  local base = self.route.delivery.packages
  local localIndex = (index - 1) % 9
  local row = math.floor(localIndex / 3)
  local column = localIndex % 3
  local stack = math.floor((index - 1) / 9)
  return vector3(base.x + (column - 1) * 2.0, base.y + (row - 1) * 2.0, base.z + stack - 1.0)
end

---@param self LRServer.TruckerMissionSession
---@param coords vector3
---@return integer
function MissionSession:SpawnPackageAt(coords)
  local entity = CreateObjectNoOffset(
    GetHashKey(PACKAGE_MODEL),
    coords.x,
    coords.y,
    coords.z,
    true,
    true,
    false
  )
  if not entity or entity == 0 then error("Khong the tao kien hang") end
  SetEntityOrphanMode(entity, 2)
  SetEntityRoutingBucket(entity, self.bucket or 0)
  FreezeEntityPosition(entity, true)
  return entity
end

---@param self LRServer.TruckerMissionSession
function MissionSession:CleanupForklifts()
  for index = 1, #self.forklifts do removeEntity(self.forklifts[index].entity) end
  self.forklifts = {}
end

---@param self LRServer.TruckerMissionSession
function MissionSession:CleanupEntities()
  if self.entitiesCleaned then return end
  self.entitiesCleaned = true
  self:CleanupForklifts()
  if not self.rentalTruckShared then removeEntity(self.vehicles.truck) end
  removeEntity(self.vehicles.trailer)
  removeEntity(self.vehicles.escort)
  self.vehicles = { truck = 0, trailer = 0, escort = 0 }
  for index = 1, #self.packages do
    removeEntity(self.packages[index].entity)
    self.packages[index].entity = 0
  end
end

---@param self LRServer.TruckerMissionSession
---@return boolean
function MissionSession:ReturnOwnedVehicle()
  if self.vehicleMode ~= "owned"
    or (tonumber(self.order.ownedVehicleId) or 0) <= 0
    or self.ownedVehicleReturned then
    return true
  end
  if type(self.returnOwnedVehicle) ~= "function" then return false end
  local returned = self.returnOwnedVehicle(self.vehicles.truck or 0, self.order)
  if returned then self.ownedVehicleReturned = true end
  return returned == true
end

---@param self LRServer.TruckerMissionSession
---@param specs table[]
---@param phase string
function MissionSession:SpawnForklifts(specs, phase)
  self:CleanupForklifts()
  for index = 1, #specs do
    local spec = { model = "forklift", coords = specs[index] }
    self.forklifts[#self.forklifts + 1] = {
      entity = self:SpawnVehicle(spec, "automobile"),
      spec = spec,
      phase = phase,
    }
  end
end

---@param self LRServer.TruckerMissionSession
---@return table
function MissionSession:Serialize()
  local loaded, delivered, packages = 0, 0, {}
  local lines = {}
  for _, line in ipairs(self.order.lines or {}) do
    lines[#lines + 1] = {
      itemId = line.itemId, label = line.label, category = line.category,
      quantity = line.quantity, unitPrice = line.unitPrice, subtotal = line.subtotal,
      packages = line.packages, destinationAmount = line.destinationAmount,
      destinationUnit = line.destinationUnit,
      destinationItemId = line.destinationItemId,
      destinationLabel = line.destinationLabel,
    }
  end
  for index = 1, #self.packages do
    local package = self.packages[index]
    if package.state == "loaded" or package.state == "unloading" or package.state == "delivered" then
      loaded = loaded + 1
    end
    if package.state == "delivered" then delivered = delivered + 1 end
    packages[index] = {
      index = package.index,
      netId = package.entity ~= 0 and DoesEntityExist(package.entity)
        and NetworkGetNetworkIdFromEntity(package.entity) or 0,
      state = package.state,
      carrierSource = package.carrierSource,
      slot = package.slot,
    }
  end
  local function netId(entity)
    return entity and entity ~= 0 and DoesEntityExist(entity)
      and NetworkGetNetworkIdFromEntity(entity) or 0
  end
  return {
    active = self.status ~= "idle",
    status = self.status,
    id = self.id,
    routeIndex = self.routeIndex,
    deliveryRouteIndex = self.order.deliveryRouteIndex or 0,
    name = self.order.name,
    itemLabel = self.order.itemLabel,
    destination = self.order.destination,
    logisticsUnits = self.order.logisticsUnits,
    vehicleMode = self.vehicleMode,
    vehicleModel = self.order.vehicleModel or "",
    ownedVehicleId = self.order.ownedVehicleId or 0,
    vehiclePlate = self.order.vehiclePlate or "",
    step = self.step,
    packageAmount = self.order.packageAmount,
    loaded = loaded,
    delivered = delivered,
    reward = self.order.reward,
    xp = self.order.xp,
    truckNetId = netId(self.vehicles.truck),
    trailerNetId = netId(self.vehicles.trailer),
    escortNetId = netId(self.vehicles.escort),
    packages = packages,
    orderKind = self.order.kind or "market",
    cargoMode = self.order.cargoMode or "pallets",
    businessId = self.order.businessId or "",
    lines = lines,
    fuelLiters = self.order.fuelLiters or 0,
    fuelProgress = self.fuelProgress,
    pickupCoords = {
      x = self.route.pickup.parking.x, y = self.route.pickup.parking.y,
      z = self.route.pickup.parking.z, w = self.route.pickup.parking.w or 0.0,
    },
    deliveryCoords = {
      x = self.route.delivery.parking.x, y = self.route.delivery.parking.y,
      z = self.route.delivery.parking.z, w = self.route.delivery.parking.w or 0.0,
    },
  }
end

---@param self LRServer.TruckerMissionSession
function MissionSession:GiveReconnectKeys()
  self:GiveKeys(self.vehicles.truck)
  self:GiveKeys(self.vehicles.escort)
  for index = 1, #self.forklifts do self:GiveKeys(self.forklifts[index].entity) end
end

---@param self LRServer.TruckerMissionSession
function MissionSession:GiveJoinKeys()
  self:GiveKeys(self.vehicles.truck)
  self:GiveKeys(self.vehicles.escort)
end

---@param self LRServer.TruckerMissionSession
---@param playerSource integer
function MissionSession:ResetCarriedPackages(playerSource)
  for index = 1, #self.packages do
    local package = self.packages[index]
    if package.carrierSource == playerSource then
      local wasUnloading = package.state == "unloading"
      removeEntity(package.entity)
      local coords = self:PackageSpawnCoords(package.index)
      local cargoVehicle = cargoVehicle(self)
      if wasUnloading and cargoVehicle and DoesEntityExist(cargoVehicle) then
        coords = GetEntityCoords(cargoVehicle)
      end
      package.entity = wasUnloading and rearLoadingOffset(self) and 0 or self:SpawnPackageAt(coords)
      package.state = wasUnloading and "loaded" or "waiting"
      package.carrierSource = 0
      if not wasUnloading then package.slot = 0 end
    end
  end
end

---@param self LRServer.TruckerMissionSession
---@param step integer
function MissionSession:SpawnStepVehicles(step)
  if self.order.cargoMode == "tanker" then return end
  if step == 2 then
    if not usesTrailer(self) then return end
    local escort = self.vehicles.escort
    if escort and escort ~= 0 and DoesEntityExist(escort)
      and distance(GetEntityCoords(escort), self.route.vehicles.escort) <= 3.0 then
      removeEntity(escort)
      self.vehicles.escort = 0
      self.vehicleSpecs.escort = nil
    end
  elseif step == 3 then
    self:SpawnForklifts(self.route.pickup.forklifts, "pickup")
  elseif step == 4 then
    self:CleanupForklifts()
  elseif step == 6 then
    self:SpawnForklifts(self.route.delivery.forklifts, "delivery")
  elseif step == 7 then
    self:CleanupForklifts()
  end
end

---@param self LRServer.TruckerMissionSession
---@param step integer
---@return boolean, string
function MissionSession:SetStep(step)
  if self.closed or self.step == step then return false, "Nhiem vu khong con hoat dong" end
  local ok, spawnError = pcall(self.SpawnStepVehicles, self, step)
  if not ok then
    self.logger:Error("mission step spawn failed: %s", tostring(spawnError))
    return false, "Khong the tao phuong tien cho buoc tiep theo"
  end
  self.step = step
  self.sync()
  return true, ""
end

---@param self LRServer.TruckerMissionSession
---@param playerSource integer
---@param vehicle integer
---@return boolean
function MissionSession:IsDriving(playerSource, vehicle)
  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
  local _, ped = playerCoords(playerSource)
  return ped ~= nil and GetPedInVehicleSeat(vehicle, -1) == ped
end

---@param self LRServer.TruckerMissionSession
---@param vehicle integer
---@param target vector4
---@return boolean
function MissionSession:IsParkedAt(vehicle, target)
  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
  if distance(GetEntityCoords(vehicle), target) > 10.0 then return false end
  local headingDifference = math.abs(GetEntityHeading(vehicle) - target.w) % 360.0
  headingDifference = math.min(headingDifference, 360.0 - headingDifference)
  headingDifference = math.min(headingDifference, 180.0 - headingDifference)
  return headingDifference <= 20.0
end

---@param self LRServer.TruckerMissionSession
---@param playerSource integer
---@return integer?
function MissionSession:ForkliftFor(playerSource)
  local _, ped = playerCoords(playerSource)
  if not ped then return nil end
  local vehicle = GetVehiclePedIsIn(ped, false)
  if not vehicle or vehicle == 0 or GetEntityModel(vehicle) ~= GetHashKey("forklift")
    or GetPedInVehicleSeat(vehicle, -1) ~= ped then return nil end
  for index = 1, #self.forklifts do
    if self.forklifts[index].entity == vehicle then return vehicle end
  end
  return nil
end

---@param self LRServer.TruckerMissionSession
---@param state string
---@return integer
function MissionSession:CountPackageState(state)
  local amount = 0
  for index = 1, #self.packages do
    if self.packages[index].state == state then amount = amount + 1 end
  end
  return amount
end

---@param self LRServer.TruckerMissionSession
---@param now integer
---@return integer, integer
function MissionSession:PaymentDue(now)
  local total = self.order.reward
  if self.order.kind == "market" and self.config.Market then
    local economy = self.config.Market
    local elapsed = math.max(0, now - self.startedAt)
    local deadline = (economy.NpcDeadlineBaseMinutes
      + economy.NpcDeadlineMinutesPerKm * (self.order.distanceKm or 0)) * 60
    local bonus = 0
    if elapsed <= deadline then
      bonus = economy.NpcTimeBonusMax
        - math.floor((economy.NpcTimeBonusMax - economy.NpcTimeBonusMin) * elapsed / deadline)
    end
    local bodyHealth = 1000
    if type(GetVehicleBodyHealth) == "function" and self.vehicles.truck
      and self.vehicles.truck ~= 0 and DoesEntityExist(self.vehicles.truck) then
      bodyHealth = tonumber(GetVehicleBodyHealth(self.vehicles.truck)) or 1000
    end
    bodyHealth = math.max(0, math.min(1000, bodyHealth))
    total = economy.NpcContractFee + math.floor(
      ((self.order.logisticsUnits * economy.NpcPayPerUnit) + bonus) * bodyHealth / 1000
    )
  end
  local overage = self.rentalTruckShared and 0 or rentalOverage(self, now)
  return math.max(0, total - overage), math.max(0, overage - total)
end

---@param self LRServer.TruckerMissionSession
---@return boolean, string
function MissionSession:Finish()
  if self.closed then return false, "Nhiem vu da ket thuc" end
  if self.paymentTotal == nil then
    self.paymentTotal, self.bankDue = self:PaymentDue(os.time())
  end
  if self.rentalTruckShared and not self.rentalAssessmentPrepared then
    if type(self.assessRental) ~= "function" then
      return false, "Khong the tinh phu phi thue xe"
    end
    local netReward, bankDue = self.assessRental(self, self.paymentTotal)
    if netReward == nil then
      return false, "Chua the ghi nhan phu phi thue xe; vui long thu lai"
    end
    self.paymentTotal, self.bankDue = netReward, bankDue
    self.rentalAssessmentPrepared = true
  end
  if not self.orderSettled then
    if type(self.prepareTeam) == "function" and not self.payoutPrepared then
      if not self.prepareTeam(self, self.paymentTotal, self.bankDue) then
        return false, "Chua the ghi nhan quyet toan; vui long thu lai"
      end
      self.payoutPrepared = true
    end
    if not self.settleOrder(self.order, self.team.id, true) then
      self.logger:Error("could not settle delivered order %s", self.order.id)
      return false, "Khong the cap nhat thi truong"
    end
    self.orderSettled = true
    self.deliveredSettlement = true
  end
  if not self:ReturnOwnedVehicle() then
    self.logger:Error("could not return owned truck for order %s", self.order.id)
    return false, "Khong the luu xe vao garage; vui long thu lai"
  end
  local online = self.team:OnlineMembers()
  local divisor = math.max(1, #online)
  local money = math.floor(self.paymentTotal / divisor)
  if type(self.payTeam) == "function" then
    if not self.payTeam(self, self.paymentTotal, self.bankDue) then
      return false, "Chua the quyet toan tien cong; vui long thu lai"
    end
  else
    for index = 1, #online do
      if not self.framework:AddMoney(online[index].source, REWARD_ACCOUNT, money, REWARD_REASON) then
        return false, "Chua the tra tien cong"
      end
    end
  end
  if type(self.markPayout) == "function" and not self.markPayout(self.order) then
    return false, "Chua the ghi nhan tien cong; vui long thu lai"
  end
  self.order.reward = self.paymentTotal
  self.closed = true
  self.status = "completed"
  self:CleanupEntities()
  for index = 1, #online do
    local member = online[index]
    if type(self.framework.SetMetadata) == "function" then
      local currentXp = math.max(0, math.floor(tonumber(self.framework:GetMetadata(
        member.source,
        PROGRESSION_METADATA
      )) or 0))
      self.framework:SetMetadata(member.source, PROGRESSION_METADATA, currentXp + self.order.xp)
    end
  end
  self.notify("success", ("Hoan thanh don hang, nhan $%d"):format(money))
  self.sync()
  CreateThread(function()
    Wait(5000)
    self.clearCompleted(self)
  end)
  return true, "Hoan thanh nhiem vu"
end

---@param self LRServer.TruckerMissionSession
---@param playerSource integer
---@param expectedStep integer
---@return boolean, string
function MissionSession:Advance(playerSource, expectedStep)
  if self.closed then return false, "Khong co nhiem vu dang chay" end
  if not self.team:FindMemberBySource(playerSource) then return false, "Ban khong phai chu don" end
  if self.step ~= expectedStep then return false, "Trang thai nhiem vu da thay doi" end
  if self.transitioning then return false, "Nhiem vu dang chuyen buoc" end
  self.transitioning = true
  local success, message = false, "Khong the chuyen buoc"
  if expectedStep == 1 then
    success = self:IsDriving(playerSource, self.vehicles.truck)
      and distance(GetEntityCoords(self.vehicles.truck), self.route.pickup.parking) <= 20.0
    message = success and "Da den diem nhan hang" or "Hay lai xe tai vao diem nhan hang"
    if success then
      local moved, moveError = self:SetStep(2)
      success, message = moved, moved and message or moveError
    end
  elseif expectedStep == 2 then
    local cargoVehicle = cargoVehicle(self)
    success = self:IsDriving(playerSource, self.vehicles.truck)
      and self:IsParkedAt(cargoVehicle, self.route.pickup.parking)
      and distance(GetEntityCoords(self.vehicles.truck), self.route.pickup.parking) <= 15.0
    message = success and "Bat dau boc hang"
      or (not usesTrailer(self) and "Xe thung chua dung vi tri" or "Ro-mooc chua dung vi tri")
    if success then
      local moved, moveError = self:SetStep(self.order.cargoMode == "tanker" and 4 or 3)
      success, message = moved, moved and message or moveError
    end
  elseif expectedStep == 4 then
    success = self:IsDriving(playerSource, self.vehicles.truck)
      and distance(GetEntityCoords(self.vehicles.truck), self.route.delivery.parking) <= 20.0
    message = success and "Da den diem giao hang" or "Hay lai xe tai vao diem giao hang"
    if success then
      local moved, moveError = self:SetStep(5)
      success, message = moved, moved and message or moveError
    end
  elseif expectedStep == 5 then
    local cargoVehicle = cargoVehicle(self)
    success = self:IsDriving(playerSource, self.vehicles.truck)
      and self:IsParkedAt(cargoVehicle, self.route.delivery.parking)
      and distance(GetEntityCoords(self.vehicles.truck), self.route.delivery.parking) <= 15.0
    message = success and "Bat dau giao hang"
      or (not usesTrailer(self) and "Xe thung chua dung vi tri" or "Ro-mooc chua dung vi tri")
    if success then
      local moved, moveError = self:SetStep(6)
      success, message = moved, moved and message or moveError
      if moved and self.order.cargoMode == "tanker" then
        CreateThread(function()
          for progress = 1, 10 do
            Wait(1000)
            if self.closed or self.step ~= 6 then return end
            local trailer = self.vehicles.trailer
            if not self:IsParkedAt(trailer, self.route.delivery.parking) then
              self.fuelProgress = 0
              self:SetStep(5)
              self.notify("warning", "Xe bồn rời vùng giao, tiến trình bơm đã hủy")
              return
            end
            self.fuelProgress = progress * 10
            self.sync()
          end
          self:SetStep(7)
          self.notify("success", "Đã giao xong dầu thô")
        end)
      end
    end
  elseif expectedStep == 7 then
    success = self:IsDriving(playerSource, self.vehicles.truck)
      and ((not usesTrailer(self))
        or self:IsParkedAt(self.vehicles.trailer, self.config.ReturnPoint))
      and distance(GetEntityCoords(self.vehicles.truck), self.config.ReturnPoint) <= 15.0
    message = success and "Hoan thanh nhiem vu"
      or (not usesTrailer(self) and "Hay tra xe thung dung vi tri" or "Hay tra xe va ro-mooc dung vi tri")
    if success then success, message = self:Finish() end
  else
    message = "Buoc nay chi hoan tat khi du kien hang"
  end
  self.transitioning = false
  return success, message
end

---@param self LRServer.TruckerMissionSession
---@param playerSource integer
---@param action string
---@param packageIndex integer
---@return boolean, string
function MissionSession:ActOnPackage(playerSource, action, packageIndex)
  if self.closed then return false, "Khong co nhiem vu dang chay" end
  if not self.team:FindMemberBySource(playerSource) then return false, "Ban khong phai chu don" end
  local package = self.packages[packageIndex]
  if not package then return false, "Kien hang khong ton tai" end
  if package.busy then return false, "Kien hang dang duoc xu ly" end
  local forklift = self:ForkliftFor(playerSource)
  if not forklift then return false, "Ban can lai xe nang cua nhiem vu" end
  local forkliftCoords = GetEntityCoords(forklift)
  local closedVan = rearLoadingOffset(self) ~= nil
  if action == "lift" then
    for index = 1, #self.packages do
      if self.packages[index].carrierSource == playerSource then
        return false, "Ban dang nang mot kien hang khac"
      end
    end
    local expectedState = self.step == 3 and "waiting" or self.step == 6 and "loaded" or nil
    if not expectedState or package.state ~= expectedState then return false, "Khong the nang kien hang nay" end
    if closedVan and self.step == 6 then
      if distance(forkliftCoords, rearLoadingPoint(self)) > 3.0 then
        return false, "Hay dua xe nang toi marker sau duoi xe"
      end
      for index = 1, packageIndex - 1 do
        if self.packages[index].state == "loaded" then
          return false, "Danh sach kien hang da thay doi, hay thu lai"
        end
      end
      -- Keep cargo stored until spawning succeeds; lock against overlapping requests.
      package.busy = true
      local heading = math.rad(GetEntityHeading(forklift))
      local forkCoords = vector3(
        forkliftCoords.x - math.sin(heading) * 1.6,
        forkliftCoords.y + math.cos(heading) * 1.6,
        forkliftCoords.z + 0.15
      )
      local ok, entity = pcall(self.SpawnPackageAt, self, forkCoords)
      package.busy = nil
      if not ok or not entity or entity == 0 or not DoesEntityExist(entity) then
        return false, "Khong the lay kien hang, hay thu lai"
      end
      package.entity = entity
    elseif not DoesEntityExist(package.entity)
      or distance(forkliftCoords, GetEntityCoords(package.entity)) > 4.0 then
      return false, "Xe nang con qua xa kien hang"
    end
    package.state = self.step == 3 and "carried" or "unloading"
    package.carrierSource = playerSource
    -- New van cargo stays frozen until its carrier attaches it to the forks.
    if not (closedVan and self.step == 6) then FreezeEntityPosition(package.entity, false) end
  elseif action == "load" then
    if self.step ~= 3 or package.state ~= "carried" or package.carrierSource ~= playerSource then
      return false, "Ban khong dang nang kien hang nay"
    end
    local cargoVehicle = cargoVehicle(self)
    if closedVan and distance(forkliftCoords, rearLoadingPoint(self)) > 3.0 then
      return false, "Hay dua xe nang toi marker sau duoi xe"
    end
    if not cargoVehicle or cargoVehicle == 0 or not DoesEntityExist(cargoVehicle)
      or (not closedVan and distance(forkliftCoords, GetEntityCoords(cargoVehicle)) > 8.0) then
      return false, not usesTrailer(self) and "Hay dua kien hang lai gan khoang xe" or "Hay dua kien hang lai gan ro-mooc"
    end
    if not DoesEntityExist(package.entity)
      or distance(forkliftCoords, GetEntityCoords(package.entity)) > 4.0 then
      return false, "Kien hang khong nam tren xe nang"
    end
    local nextSlot = self:CountPackageState("loaded") + 1
    package.state = "loaded"
    package.carrierSource = 0
    package.slot = nextSlot
    if closedVan then
      removeEntity(package.entity)
      package.entity = 0
    else
      FreezeEntityPosition(package.entity, false)
    end
    if self:CountPackageState("loaded") == self.order.packageAmount then self:SetStep(4) end
  elseif action == "deliver" then
    if self.step ~= 6 or package.state ~= "unloading" or package.carrierSource ~= playerSource then
      return false, "Ban khong dang nang kien hang nay"
    end
    if distance(forkliftCoords, self.route.delivery.packages) > 10.0 then
      return false, "Hay dua kien hang vao bai giao"
    end
    if not DoesEntityExist(package.entity)
      or distance(forkliftCoords, GetEntityCoords(package.entity)) > 4.0 then
      return false, "Kien hang khong nam tren xe nang"
    end
    local nextSlot = self:CountPackageState("delivered") + 1
    package.state = "delivered"
    package.carrierSource = 0
    package.slot = nextSlot
    local slot = self:DeliverySlot(package.slot)
    SetEntityCoords(package.entity, slot.x, slot.y, slot.z, false, false, false, false)
    FreezeEntityPosition(package.entity, true)
    if self:CountPackageState("delivered") == self.order.packageAmount then self:SetStep(7) end
  else
    return false, "Thao tac kien hang khong hop le"
  end
  self.sync()
  return true, "Da cap nhat kien hang"
end

---@param self LRServer.TruckerMissionSession
---@param waiveOverage? boolean
---@return boolean
function MissionSession:Cancel(waiveOverage)
  if self.closed then return false end
  -- A delivered order may be awaiting payout. It cannot become a cancellation.
  if self.deliveredSettlement then return false end
  if self.cancelRentalDue == nil then
    self.cancelRentalDue = (waiveOverage or self.rentalTruckShared)
      and 0 or rentalOverage(self, os.time())
  end
  if not self.orderSettled then
    if not self.settleOrder(self.order, self.team.id, false) then
      self.logger:Error("could not release cancelled order %s", self.order.id)
      return false
    end
    self.orderSettled = true
  end
  if not self:ReturnOwnedVehicle() then return false end
  if type(self.queueRentalCharge) == "function" then
    local due = self.cancelRentalDue or 0
    if due > 0 and not self.queueRentalCharge(self, due) then return false end
  end
  self:CleanupEntities()
  self.closed = true
  return true
end

---@param self LRServer.TruckerMissionSession
function MissionSession:RecoverMissingEntities()
  if self.closed then return end
  local changed = false
  if self.rentalTruckShared and type(self.recoverRentalTruck) == "function" then
    local truck = self.recoverRentalTruck()
    if truck and truck ~= self.vehicles.truck then
      self.vehicles.truck = truck
      changed = true
    end
  end
  for name, spec in pairs(self.vehicleSpecs) do
    local entity = self.vehicles[name]
    if entity and entity ~= 0 and DoesEntityExist(entity) then
      local coords = GetEntityCoords(entity)
      spec.coords = vector4(coords.x, coords.y, coords.z, GetEntityHeading(entity))
    else
      self.vehicles[name] = self:SpawnVehicle(spec, spec.type)
      changed = true
    end
  end
  for index = 1, #self.forklifts do
    local forklift = self.forklifts[index]
    if not forklift.entity or forklift.entity == 0 or not DoesEntityExist(forklift.entity) then
      forklift.entity = self:SpawnVehicle(forklift.spec, "automobile")
      changed = true
    end
  end
  for index = 1, #self.packages do
    local package = self.packages[index]
    if rearLoadingOffset(self) and (package.state == "loaded"
      or (package.state == "unloading" and not DoesEntityExist(package.entity))) then
      -- Stored van cargo intentionally has no world entity, including after recovery.
      if package.state ~= "loaded" or package.entity ~= 0 then changed = true end
      removeEntity(package.entity)
      package.entity = 0
      package.state, package.carrierSource = "loaded", 0
    elseif not package.entity or package.entity == 0 or not DoesEntityExist(package.entity) then
      if package.state == "carried" then
        package.state, package.carrierSource, package.slot = "waiting", 0, 0
      elseif package.state == "unloading" then
        package.state, package.carrierSource = "loaded", 0
      end
      local coords = self:PackageSpawnCoords(package.index)
      if package.state == "delivered" then coords = self:DeliverySlot(package.slot) end
      local cargoVehicle = cargoVehicle(self)
      if package.state == "loaded" and cargoVehicle and DoesEntityExist(cargoVehicle) then
        coords = GetEntityCoords(cargoVehicle)
      end
      package.entity = self:SpawnPackageAt(coords)
      changed = true
    elseif package.state == "loaded" then
      local cargoVehicle = cargoVehicle(self)
      if cargoVehicle and DoesEntityExist(cargoVehicle)
        and distance(GetEntityCoords(package.entity), GetEntityCoords(cargoVehicle)) > 12.0 then
      local cargoCoords = GetEntityCoords(cargoVehicle)
      SetEntityCoords(package.entity, cargoCoords.x, cargoCoords.y, cargoCoords.z, false, false, false, false)
      FreezeEntityPosition(package.entity, false)
      changed = true
      end
    end
  end
  if changed then self.sync() end
end

LRTruckerServer.MissionSession = MissionSession
