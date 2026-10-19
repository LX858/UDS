LRTruckerServer = LRTruckerServer or {}

local OrderBoard = assert(LRTruckerServer.OrderBoard)
local BusinessOrderBoard = LRTruckerServer.BusinessOrderBoard
if not BusinessOrderBoard then
  BusinessOrderBoard = LR.Class:Define("BusinessOrderBoardFallback")
  ---@diagnostic disable-next-line: inject-field
  function BusinessOrderBoard:init() end
  ---@diagnostic disable-next-line: inject-field
  function BusinessOrderBoard:List() return {}, 0 end
  ---@diagnostic disable-next-line: inject-field
  function BusinessOrderBoard:Find() return nil end
  ---@diagnostic disable-next-line: inject-field
  function BusinessOrderBoard:Recover() return 0 end
end
local Team = assert(LRTruckerServer.Team)
local MissionSession = assert(LRTruckerServer.MissionSession)
local Database = LRTruckerServer.Database or {}
local BusinessIntegration = LR.CreateBusinessIntegrationBridge
  and LR.CreateBusinessIntegrationBridge()
  or { IsSourceOnline = function() return false end, ReleaseNpcHolds = function() return false end }

local ACTION_DISTANCE = 12.0
local REWARD_ACCOUNT = "cash"
local FLEET_ACCOUNT = "bank"
local PROGRESSION_METADATA = "trucker_xp"
local XP_PER_LEVEL = 1000
local MARKET_CYCLE_MS = Config.Market.RefreshMs or 300000

local function shallowCopy(source)
  local copy = {}
  for key, value in pairs(source or {}) do copy[key] = value end
  return copy
end

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

local function idleMission()
  return {
    active = false, status = "idle", id = "", routeIndex = 0, deliveryRouteIndex = 0,
    name = "", step = 0,
    itemLabel = "", destination = "", logisticsUnits = 0,
    packageAmount = 0, loaded = 0, delivered = 0, reward = 0, xp = 0,
    vehicleMode = "", vehicleModel = "", ownedVehicleId = 0, vehiclePlate = "",
    truckNetId = 0, trailerNetId = 0, escortNetId = 0, packages = {},
    orderKind = "market", cargoMode = "pallets", businessId = "", lines = {}, fuelLiters = 0,
    fuelProgress = 0,
    pickupCoords = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
    deliveryCoords = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
  }
end

---@class LRServer.TruckerServiceInput
---@field context LRServer.ModuleContext

---@class LRServer.TruckerService : LRServer.ModuleInstance
---@field context LRServer.ModuleContext
---@field framework LRServer.FrameworkBridge
---@field orderBoard LRServer.TruckerOrderBoard
---@field teams table<string, LRServer.TruckerTeam>
---@field sourceTeams table<integer, string>
---@field citizenTeams table<string, string>
---@field refundProcessing table<string, boolean>
---@field refundChecked table<string, boolean>
---@field mutationLocks table<string, boolean>
---@field pendingSettlements table<string, table>
---@field businessOrderBoard table
---@field businessContexts table<integer, table>
---@field orderPages table<integer, table>
---@field boardCache? table
---@field publicOffers table<string, table>
---@field publicOfferLookup table<string, table>
---@field claimedOffers table<string, boolean>
---@field rentalEntities table<string, integer>
---@field rentalSources table<integer, string>
---@field RentalLease fun(self: LRServer.TruckerService, citizenId: string): table?
---@field RentalTruck fun(self: LRServer.TruckerService, citizenId: string, playerSource: integer, lease: table): integer?
---@field RemoveRentalTruck fun(self: LRServer.TruckerService, citizenId: string)
---@field RentalDebt fun(self: LRServer.TruckerService, citizenId: string): integer?
---@field ResumePendingRental fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData, lease: table): table?, string
---@field AcquireRental fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData, choice: table): table?, integer?, string
---@field ReturnRental fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData, team: LRServer.TruckerTeam?): boolean, string
---@field idCounter integer
---@field instanceNonce integer
---@field stopped boolean
---@field npcHoldsRecovered boolean
---@field net? LRServerTruckerNet
---@field NextId fun(self: LRServer.TruckerService, prefix: string): string
---@field PublicOffer fun(self: LRServer.TruckerService, order: table): table, integer
---@field FindPublicOffer fun(self: LRServer.TruckerService, offerId: string): LRServer.TruckerOrder?
---@field SettleOrder fun(self: LRServer.TruckerService, order: LRServer.TruckerOrder, teamId: string, delivered: boolean): boolean
---@field WithMutationLock fun(self: LRServer.TruckerService, citizenId: string, callback: function): boolean, string
---@field GetOwnedVehicles fun(self: LRServer.TruckerService, citizenId: string): table[]
---@field ResolveRequestedVehicle fun(self: LRServer.TruckerService, citizenId: string, request: table): table?, string?
---@field CanVehicleAccept fun(self: LRServer.TruckerService, choice: table?, order: LRServer.TruckerOrder): boolean, string
---@field LoadForRental fun(self: LRServer.TruckerService, order: LRServer.TruckerOrder, choice: table): LRServer.TruckerOrder
---@field GetFleetSnapshot fun(self: LRServer.TruckerService, citizenId: string): table
---@field GetOrdersForPlayer fun(self: LRServer.TruckerService, player: { citizenId: string }?): table[]
---@field GetOrderPage fun(self: LRServer.TruckerService, player: table?, filter: string, page: integer, pageSize: integer): table
---@field ProcessLegacyRentalRefund fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData)
---@field ProcessPayment fun(self: LRServer.TruckerService, missionId: string, citizenId: string, kind: string, amount: integer, playerSource: integer): boolean
---@field ProcessPendingPayments fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData)
---@field PrepareMission fun(self: LRServer.TruckerService, session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field PayMission fun(self: LRServer.TruckerService, session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field QueueRentalCharge fun(self: LRServer.TruckerService, session: LRServer.TruckerMissionSession, bankDue: integer): boolean
---@field QueueSettlementRetry fun(self: LRServer.TruckerService, order: LRServer.TruckerOrder, teamId: string)
---@field PlayerData fun(self: LRServer.TruckerService, playerSource: integer): LRServer.TruckerPlayerData?
---@field IsEligible fun(self: LRServer.TruckerService, playerSource: integer, requiredLevel?: integer): boolean, string
---@field CreateTeam fun(self: LRServer.TruckerService, player: LRServer.TruckerPlayerData): LRServer.TruckerTeam
---@field EnsureTeam fun(self: LRServer.TruckerService, playerSource: integer): LRServer.TruckerTeam?
---@field DestroyTeam fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam?)
---@field IsHost fun(self: LRServer.TruckerService, playerSource: integer, team: LRServer.TruckerTeam?): boolean
---@field IsNearNpc fun(self: LRServer.TruckerService, playerSource: integer): boolean
---@field SyncTeam fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam)
---@field SyncAllTeams fun(self: LRServer.TruckerService)
---@field NotifyTeam fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam, noticeType: LRServer.FrameworkNotificationType, message: string)
---@field GetSnapshot fun(self: LRServer.TruckerService, playerSource: integer): table
---@field ActionResult fun(self: LRServer.TruckerService, playerSource: integer, success: boolean, message: string): table
---@field CreateMission fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam, order: LRServer.TruckerOrder, ownerSource: integer): LRServer.TruckerMissionSession
---@field HandlePlayerLoaded fun(self: LRServer.TruckerService, playerSource: integer)
---@field HandlePlayerUnloaded fun(self: LRServer.TruckerService, playerSource: integer)
---@field AdvanceMission fun(self: LRServer.TruckerService, playerSource: integer, expectedStep: integer): boolean, string
---@field ActOnPackage fun(self: LRServer.TruckerService, playerSource: integer, action: string, packageIndex: integer): boolean, string
---@field RunQaScenario fun(self: LRServer.TruckerService, playerSource: integer, action: string): table
---@field RegisterNetworkHandlers fun(self: LRServer.TruckerService, startContext: LRServer.ModuleContext)
---@field Start fun(self: LRServer.TruckerService, startContext: LRServer.ModuleContext)
---@field Stop fun(self: LRServer.TruckerService)

---@class LRServer.TruckerServiceClass : LRShared.Class<LRServer.TruckerService, LRServer.TruckerServiceInput>
---@field net? LRServerTruckerNet
---@field boardCache? table
---@field npcHoldsRecovered boolean
---@field orderPages table<integer, table>
---@field init fun(self: LRServer.TruckerService, input: LRServer.TruckerServiceInput)
---@field RentalLease fun(self: LRServer.TruckerService, citizenId: string): table?
---@field RentalTruck fun(self: LRServer.TruckerService, citizenId: string, playerSource: integer, lease: table): integer?
---@field RemoveRentalTruck fun(self: LRServer.TruckerService, citizenId: string)
---@field RentalDebt fun(self: LRServer.TruckerService, citizenId: string): integer?
---@field ResumePendingRental fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData, lease: table): table?, string
---@field AcquireRental fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData, choice: table): table?, integer?, string
---@field ReturnRental fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData, team: LRServer.TruckerTeam?): boolean, string
---@field NextId fun(self: LRServer.TruckerService, prefix: string): string
---@field PublicOffer fun(self: LRServer.TruckerService, order: table): table, integer
---@field FindPublicOffer fun(self: LRServer.TruckerService, offerId: string): LRServer.TruckerOrder?
---@field SettleOrder fun(self: LRServer.TruckerService, order: LRServer.TruckerOrder, teamId: string, delivered: boolean): boolean
---@field WithMutationLock fun(self: LRServer.TruckerService, citizenId: string, callback: function): boolean, string
---@field GetOwnedVehicles fun(self: LRServer.TruckerService, citizenId: string): table[]
---@field ResolveRequestedVehicle fun(self: LRServer.TruckerService, citizenId: string, request: table): table?, string?
---@field CanVehicleAccept fun(self: LRServer.TruckerService, choice: table?, order: LRServer.TruckerOrder): boolean, string
---@field LoadForRental fun(self: LRServer.TruckerService, order: LRServer.TruckerOrder, choice: table): LRServer.TruckerOrder
---@field GetFleetSnapshot fun(self: LRServer.TruckerService, citizenId: string): table
---@field GetOrdersForPlayer fun(self: LRServer.TruckerService, player: { citizenId: string }?): table[]
---@field GetOrderPage fun(self: LRServer.TruckerService, player: table?, filter: string, page: integer, pageSize: integer): table
---@field ProcessLegacyRentalRefund fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData)
---@field ProcessPayment fun(self: LRServer.TruckerService, missionId: string, citizenId: string, kind: string, amount: integer, playerSource: integer): boolean
---@field ProcessPendingPayments fun(self: LRServer.TruckerService, playerSource: integer, player: LRServer.TruckerPlayerData)
---@field PrepareMission fun(self: LRServer.TruckerService, session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field PayMission fun(self: LRServer.TruckerService, session: LRServer.TruckerMissionSession, total: integer, bankDue: integer): boolean
---@field QueueRentalCharge fun(self: LRServer.TruckerService, session: LRServer.TruckerMissionSession, bankDue: integer): boolean
---@field QueueSettlementRetry fun(self: LRServer.TruckerService, order: LRServer.TruckerOrder, teamId: string)
---@field PlayerData fun(self: LRServer.TruckerService, playerSource: integer): LRServer.TruckerPlayerData?
---@field IsEligible fun(self: LRServer.TruckerService, playerSource: integer, requiredLevel?: integer): boolean, string
---@field CreateTeam fun(self: LRServer.TruckerService, player: LRServer.TruckerPlayerData): LRServer.TruckerTeam
---@field EnsureTeam fun(self: LRServer.TruckerService, playerSource: integer): LRServer.TruckerTeam?
---@field DestroyTeam fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam?)
---@field IsHost fun(self: LRServer.TruckerService, playerSource: integer, team: LRServer.TruckerTeam?): boolean
---@field IsNearNpc fun(self: LRServer.TruckerService, playerSource: integer): boolean
---@field SyncTeam fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam)
---@field SyncAllTeams fun(self: LRServer.TruckerService)
---@field NotifyTeam fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam, noticeType: LRServer.FrameworkNotificationType, message: string)
---@field GetSnapshot fun(self: LRServer.TruckerService, playerSource: integer): table
---@field ActionResult fun(self: LRServer.TruckerService, playerSource: integer, success: boolean, message: string): table
---@field CreateMission fun(self: LRServer.TruckerService, team: LRServer.TruckerTeam, order: LRServer.TruckerOrder, ownerSource: integer): LRServer.TruckerMissionSession
---@field HandlePlayerLoaded fun(self: LRServer.TruckerService, playerSource: integer)
---@field HandlePlayerUnloaded fun(self: LRServer.TruckerService, playerSource: integer)
---@field AdvanceMission fun(self: LRServer.TruckerService, playerSource: integer, expectedStep: integer): boolean, string
---@field ActOnPackage fun(self: LRServer.TruckerService, playerSource: integer, action: string, packageIndex: integer): boolean, string
---@field RunQaScenario fun(self: LRServer.TruckerService, playerSource: integer, action: string): table
---@field RegisterNetworkHandlers fun(self: LRServer.TruckerService, startContext: LRServer.ModuleContext)
---@field Start fun(self: LRServer.TruckerService, startContext: LRServer.ModuleContext)
---@field Stop fun(self: LRServer.TruckerService)

---@type LRServer.TruckerServiceClass
local TruckerService = LR.Class:Define("TruckerService")

---@param self LRServer.TruckerService
---@param input LRServer.TruckerServiceInput
function TruckerService:init(input)
  self.context = input.context
  self.framework = input.context.services.framework
  if not self.framework then error("trucker requires a framework service") end
  self.teams = {}
  self.sourceTeams = {}
  self.citizenTeams = {}
  self.refundProcessing = {}
  self.refundChecked = {}
  self.mutationLocks = {}
  self.pendingSettlements = {}
  self.businessContexts = {}
  self.orderPages = {}
  self.boardCache = nil
  self.publicOffers = {}
  self.publicOfferLookup = {}
  self.claimedOffers = {}
  self.rentalEntities = {}
  self.rentalSources = {}
  self.idCounter = 0
  self.instanceNonce = type(GetGameTimer) == "function" and GetGameTimer() or 0
  self.stopped = false
  self.npcHoldsRecovered = false
  self.net = nil
  self.orderBoard = OrderBoard:New({
    config = Config,
    nextId = function(prefix) return self:NextId(prefix) end,
    integration = BusinessIntegration,
  })
  self.businessOrderBoard = BusinessOrderBoard:New({
    config = Config,
    integration = BusinessIntegration,
    nextId = function(prefix) return self:NextId(prefix) end,
    logger = self.context.logger,
  })
end

---@param self LRServer.TruckerService
---@param prefix string
---@return string
function TruckerService:NextId(prefix)
  self.idCounter = self.idCounter + 1
  return ("%s-%d-%d-%d"):format(prefix, os.time(), self.instanceNonce, self.idCounter)
end

function TruckerService:PublicOffer(order)
  local key = order.kind .. ":" .. order.id
  local entry = self.publicOffers[key]
  if not entry then
    local token
    repeat
      token = ("dispatch-%08x%08x%08x%08x"):format(
        math.random(0, 2147483647), math.random(0, 2147483647),
        math.random(0, 2147483647), math.random(0, 2147483647)
      )
    until not self.publicOfferLookup[token]
    entry = { id = token, key = key, sortKey = math.random(1, 2147483647) }
    self.publicOffers[key] = entry
    self.publicOfferLookup[entry.id] = entry
  end
  local rentalRewards = {}
  for _, rentalKey in ipairs({ "mule", "benson", "pounder", "hauler", "packer", "phantom" }) do
    local rental = Config.Fleet.Rentals[rentalKey]
    if rental and (order.kind == "market" or rental.capacity >= order.logisticsUnits)
      and (order.cargoMode ~= "tanker" or Config.Fleet.FuelRentals[rentalKey]) then
      local load = self:LoadForRental(order, rental)
      rentalRewards[#rentalRewards + 1] = {
        key = rentalKey,
        reward = load.reward,
      }
    end
  end
  local categories = {}
  local keys = order.kind == "business" and order.categoryKeys or { order.cargoCategory }
  local categoryLabels = Config.Market.CategoryLabels or {}
  for _, category in ipairs(keys or {}) do
    categories[#categories + 1] = categoryLabels[category] or "Hàng hóa"
  end
  if #categories == 0 then categories[1] = "Hàng hóa" end
  return {
    id = entry.id,
    level = order.level,
    categories = categories,
    reward = order.reward,
    rentalRewards = rentalRewards,
    availability = order.availability,
    canAccept = order.canAccept,
    lockReason = order.canAccept and "" or "Đơn chưa sẵn sàng để nhận",
  }, entry.sortKey
end

function TruckerService:FindPublicOffer(offerId)
  local entry = self.publicOfferLookup[offerId]
  if not entry then return nil end
  local kind, id = entry.key:match("^(%w+):(.+)$")
  if kind == "market" then return self.orderBoard:Find(id) end
  if kind == "business" then return self.businessOrderBoard:Find(id) end
  return nil
end

---@param self LRServer.TruckerService
function TruckerService:SettleOrder(order, teamId, delivered)
  local settled
  if order.kind == "business" then
    if delivered then
      settled = self.businessOrderBoard:Deliver(order)
    else
      settled = self.businessOrderBoard:Release(order, teamId)
    end
  else
    settled = self.orderBoard:SettleOrder(order, teamId, delivered)
  end
  if settled then
    self.boardCache = nil
    self.orderPages = {}
  end
  return settled
end

function TruckerService:QueueSettlementRetry(order, teamId)
  self.pendingSettlements[order.id] = { order = order, teamId = teamId }
end

function TruckerService:WithMutationLock(citizenId, callback)
  if self.mutationLocks[citizenId] then return false, "Thao tac truoc dang duoc xu ly" end
  self.mutationLocks[citizenId] = true
  local ok, first, second = xpcall(callback, debug.traceback)
  self.mutationLocks[citizenId] = nil
  if not ok then
    self.context.logger:Error("fleet mutation failed for %s: %s", citizenId, tostring(first))
    return false, "Khong the cap nhat doi xe"
  end
  return first, second
end

function TruckerService:GetOwnedVehicles(citizenId)
  if type(Database.GetOwnedVehicles) ~= "function" then return {} end
  return Database.GetOwnedVehicles(citizenId)
end

function TruckerService:ResolveRequestedVehicle(citizenId, request)
  if type(request) ~= "table" or request.mode ~= "rental" then
    return nil, "Hien chi ho tro xe thue"
  end
  local option = Config.Fleet.Rentals[request.key]
  if not option then return nil, "Mau xe thue khong hop le" end
  return {
    mode = "rental", key = request.key, model = option.model,
    capacity = option.capacity, rewardMultiplier = option.rewardMultiplier,
    tier = 0, fee = option.fee, ownedVehicleId = 0, vehiclePlate = "TRUCKER",
  }, ""
end

function TruckerService:CanVehicleAccept(choice, order)
  if not choice or choice.mode ~= "rental" then return false, "Hien chi ho tro xe thue" end
  if order.kind ~= "market" and order.logisticsUnits > choice.capacity then
    return false, "Vuot qua tai trong xe da chon"
  end
  if order.cargoMode == "tanker" then
    if not Config.Fleet.FuelRentals[choice.key] then
      return false, "Đơn dầu cần xe bồn"
    end
  end
  return true, ""
end

function TruckerService:LoadForRental(order, choice)
  if order.kind ~= "market" then return order end
  local load = shallowCopy(order)
  load.logisticsUnits = math.min(order.logisticsUnits, choice.capacity)
  load.packageAmount = math.ceil(load.logisticsUnits / Config.Market.UnitsPerPackage)
  load.reward = Config.Market.NpcContractFee
    + load.logisticsUnits * Config.Market.NpcPayPerUnit
    + Config.Market.NpcTimeBonusMax
  return load
end

function TruckerService:RentalLease(citizenId)
  if type(Database.GetRentalLease) ~= "function" then return nil end
  local ok, lease = pcall(Database.GetRentalLease, citizenId)
  if not ok then
    self.context.logger:Error("rental lease lookup failed: %s", tostring(lease))
    return nil
  end
  return lease
end

function TruckerService:RentalTruck(citizenId, playerSource, lease)
  if not lease or lease.status ~= "active" then return nil end
  self.rentalSources[playerSource] = citizenId
  local entity = self.rentalEntities[citizenId]
  if entity and entity ~= 0 and DoesEntityExist(entity) then return entity end
  local spawn = Config.Routes[1].vehicles.truck.coords
  entity = CreateVehicleServerSetter(GetHashKey(lease.model), "automobile",
    spawn.x, spawn.y, spawn.z, spawn.w)
  if not entity or entity == 0 then return nil end
  SetEntityOrphanMode(entity, 2)
  SetEntityRoutingBucket(entity, GetPlayerRoutingBucket(tostring(playerSource)))
  SetVehicleNumberPlateText(entity, lease.plate)
  self.rentalEntities[citizenId] = entity
  if type(self.framework.GiveVehicleKeys) == "function" then
    self.framework:GiveVehicleKeys(playerSource, entity)
  end
  return entity
end

function TruckerService:RemoveRentalTruck(citizenId)
  local entity = self.rentalEntities[citizenId]
  self.rentalEntities[citizenId] = nil
  if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
end

function TruckerService:RentalDebt(citizenId)
  if type(Database.GetRentalDebt) ~= "function" then return 0 end
  local ok, debt = pcall(Database.GetRentalDebt, citizenId)
  if not ok then
    self.context.logger:Error("rental debt lookup failed: %s", tostring(debt))
    return nil
  end
  return debt
end

function TruckerService:ResumePendingRental(playerSource, player, lease)
  if not lease or lease.status ~= "pending" then return lease, "" end
  if not self:ProcessPayment(lease.id, player.citizenId,
    "rental_fee", lease.fee, playerSource) then
    return nil, "Chua the thanh toan phi thue; vui long thu lai"
  end
  local ok, activated = pcall(Database.ActivateRentalLease, player.citizenId, lease.id,
    os.time(), Config.Fleet.RentalMinutes or 60)
  if not ok or activated ~= true then
    return nil, "Chua the kich hoat luot thue"
  end
  lease = self:RentalLease(player.citizenId)
  if not lease or lease.status ~= "active" then
    return nil, "Chua the tai luot thue da kich hoat"
  end
  return lease, ""
end

function TruckerService:AcquireRental(playerSource, player, choice)
  local lease = self:RentalLease(player.citizenId)
  if lease and lease.key ~= choice.key then
    return nil, nil, "Hay tra xe dang thue truoc khi chon xe khac"
  end
  if lease and lease.status == "returning" then
    return nil, nil, "Luot thue dang cho quyet toan"
  end
  local newlyCreated = not lease
  if not lease then
    local id = self:NextId("rent")
    local plate = ("LR%06d"):format(self.idCounter % 1000000)
    local ok, created = pcall(Database.CreateRentalLease, player.citizenId,
      id, choice.key, choice.model, plate, choice.fee, os.time(),
      Config.Fleet.RentalMinutes or 60)
    if not ok or not created then
      self.context.logger:Error("could not create rental lease: %s", tostring(created))
      return nil, nil, "Khong the ghi nhan luot thue"
    end
    lease = created
    if lease.id ~= id then return nil, nil, "Da co xe thue dang duoc xu ly" end
  end
  if lease.status == "pending" then
    local pendingError
    lease, pendingError = self:ResumePendingRental(playerSource, player, lease)
    if not lease then return nil, nil, pendingError end
  end
  local truck = self:RentalTruck(player.citizenId, playerSource, lease)
  if not truck then
    if newlyCreated then
      pcall(Database.MarkRentalReturning, player.citizenId, lease.id)
      pcall(Database.CloseRentalLease, player.citizenId, lease.id)
      pcall(Database.QueueRentalRefund, "technical:" .. lease.id,
        player.citizenId, lease.fee)
    end
    return nil, nil, newlyCreated
      and "Khong the tao xe thue; phi thue dang cho hoan"
      or "Khong the khoi phuc xe thue; vui long thu lai"
  end
  return lease, truck, ""
end

function TruckerService:ReturnRental(playerSource, player, team)
  if team and team.session and not team.session.closed then
    return false, "Hay hoan thanh hoac huy don dang chay truoc"
  end
  local lease = self:RentalLease(player.citizenId)
  if not lease then return false, "Ban khong co xe thue" end
  if lease.status == "pending" then return false, "Phi thue xe dang cho xu ly" end
  if lease.status == "active" then
    local truck = self.rentalEntities[player.citizenId]
    local coords, ped = playerCoords(playerSource)
    if not truck or not DoesEntityExist(truck) or not ped
      or GetPedInVehicleSeat(truck, -1) ~= ped
      or distance(coords, Config.ReturnPoint) > 15.0
      or distance(GetEntityCoords(truck), Config.ReturnPoint) > 15.0 then
      return false, "Hay lai xe thue den diem tra xe"
    end
    local settlementId = "return-" .. lease.id
    local ok, assessment = pcall(Database.PrepareRentalAssessment, lease,
      settlementId, 0, os.time(), Config.Fleet.OveragePercentPerMinute or 3)
    if not ok or not assessment then return false, "Chua the chot phu phi thue xe" end
    if assessment.bankDue > 0 then
      local saved, status = pcall(Database.EnsurePayment, settlementId,
        player.citizenId, "rental_overage", assessment.bankDue)
      if not saved or not status then return false, "Chua the ghi no phu phi thue xe" end
    end
    local committed, result = pcall(Database.CommitRentalAssessment,
      player.citizenId, lease.id, settlementId)
    if not committed or result ~= true then return false, "Chua the chot luot thue" end
    local marked, returning = pcall(Database.MarkRentalReturning, player.citizenId, lease.id)
    if not marked or returning ~= true then return false, "Chua the chot luot thue" end
  end
  local closed, result = pcall(Database.CloseRentalLease, player.citizenId, lease.id)
  if not closed or result ~= true then return false, "Chua the dong luot thue" end
  self:RemoveRentalTruck(player.citizenId)
  self:ProcessPendingPayments(playerSource, player)
  local debt = self:RentalDebt(player.citizenId) or 0
  return true, debt > 0 and "Da tra xe; phu phi con no dang cho thanh toan"
    or "Da tra xe thue"
end

function TruckerService:GetFleetSnapshot(citizenId)
  local rentalOptions = {}
  for _, key in ipairs({ "mule", "benson", "pounder", "hauler", "packer", "phantom" }) do
    local option = Config.Fleet.Rentals[key]
    rentalOptions[#rentalOptions + 1] = {
      key = key, label = option.label, model = option.model, fee = option.fee,
    }
  end
  local lease = citizenId ~= "" and self:RentalLease(citizenId) or nil
  local entity = lease and self.rentalEntities[citizenId] or nil
  local due = 0
  if lease and lease.status == "active" then
    local minutes = math.ceil(math.max(0, os.time() - lease.expiresAt) / 60)
    due = math.max(0, math.ceil(lease.fee * (Config.Fleet.OveragePercentPerMinute or 3)
      * minutes / 100) - lease.assessedOverage)
  end
  return {
    bank = 0,
    ownedVehicles = {},
    rentalOptions = rentalOptions,
    rental = {
      active = lease ~= nil and lease.status == "active",
      status = lease and lease.status or "none",
      key = lease and lease.key or "",
      model = lease and lease.model or "",
      plate = lease and lease.plate or "",
      startedAt = lease and lease.startedAt or 0,
      expiresAt = lease and lease.expiresAt or 0,
      truckNetId = entity and entity ~= 0 and DoesEntityExist(entity)
        and NetworkGetNetworkIdFromEntity(entity) or 0,
      overageDue = due,
      debt = citizenId ~= "" and (self:RentalDebt(citizenId) or 0) or 0,
    },
  }
end

function TruckerService:GetOrdersForPlayer(_player)
  local serialized = self.orderBoard:Serialize()
  for index = 1, #serialized do
    local order = serialized[index]
    order.canAccept = order.availability == "available"
    order.lockReason = order.availability == "route_busy" and "Tuyen dang ban"
      or order.availability == "stock_low" and "Kho khong du hang"
      or ""
    order.effectiveReward = order.reward
    order.kind = "market"
    order.cargoMode = order.cargoMode or "pallets"
    order.businessId = ""
    order.businessLabel = ""
    order.businessStatus = ""
    order.distanceKm = order.distanceKm or 0
    order.lines = {}
  end
  return serialized
end

function TruckerService:GetOrderPage(player, filter, page, pageSize)
  filter = "all"
  page = math.max(1, math.floor(tonumber(page) or 1))
  pageSize = math.max(1, math.min(20, math.floor(tonumber(pageSize) or 20)))
  local cache = self.boardCache
  if not cache or cache.expiresAt <= os.time() then
    local market = self:GetOrdersForPlayer(player)
    local business = self.businessOrderBoard:List("business", 1, 10000)
    local combined = {}
    local visibleKeys = {}
    for _, order in ipairs(market) do
      if order.canAccept then
        local offer, sortKey = self:PublicOffer(order)
        visibleKeys[order.kind .. ":" .. order.id] = true
        combined[#combined + 1] = {offer = offer, sortKey = sortKey}
      end
    end
    for _, order in ipairs(business) do
      if order.canAccept then
        local offer, sortKey = self:PublicOffer(order)
        visibleKeys[order.kind .. ":" .. order.id] = true
        combined[#combined + 1] = {offer = offer, sortKey = sortKey}
      end
    end
    for key, entry in pairs(self.publicOffers) do
      if not visibleKeys[key] and not self.claimedOffers[entry.id] then
        self.publicOfferLookup[entry.id] = nil
        self.publicOffers[key] = nil
      end
    end
    table.sort(combined, function(a, b) return a.sortKey < b.sortKey end)
    cache = { expiresAt = os.time() + 10, items = combined }
    self.boardCache = cache
  end
  local total = #cache.items
  page = math.min(page, math.max(1, math.ceil(total / pageSize)))
  local items, first = {}, (page - 1) * pageSize + 1
  for index = first, math.min(total, first + pageSize - 1) do
    items[#items + 1] = cache.items[index].offer
  end
  return { filter = filter, page = page, pageSize = pageSize, total = total, items = items }
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@return LRServer.TruckerPlayerData?
function TruckerService:PlayerData(playerSource)
  local player = self.framework:GetPlayer(playerSource)
  if not player or not player.citizenId then return nil end
  local xp = 0
  if type(self.framework.GetMetadata) == "function" then
    xp = math.max(0, math.floor(tonumber(self.framework:GetMetadata(
      playerSource,
      PROGRESSION_METADATA
    )) or 0))
  end
  return {
    source = playerSource,
    citizenId = player.citizenId,
    name = player.name or ("Player %d"):format(playerSource),
    xp = xp,
    level = math.max(1, math.floor(xp / XP_PER_LEVEL) + 1),
    job = player.job,
  }
end


function TruckerService:ProcessLegacyRentalRefund(playerSource, player)
  if not player or self.refundChecked[player.citizenId] or self.refundProcessing[player.citizenId] then return end
  if type(Database.ClaimLegacyRentalRefund) ~= "function" then return end
  self.refundProcessing[player.citizenId] = true
  local total = 0
  for _ = 1, 32 do
    local ok, refund = pcall(Database.ClaimLegacyRentalRefund, player.citizenId, os.time())
    if not ok then
      self.context.logger:Warn("rental refund failed for %s: %s", player.citizenId, tostring(refund))
      break
    end
    if not refund then
      self.refundChecked[player.citizenId] = true
      break
    end
    local paid = refund.amount <= 0 or self.framework:AddMoney(
      playerSource,
      FLEET_ACCOUNT,
      refund.amount,
      "trucker-rental-refund"
    )
    Database.CompleteLegacyRentalRefund(refund.id, paid == true)
    if not paid then break end
    total = total + refund.amount
  end
  if total > 0 then
    self.framework:Notify(playerSource, {
      type = "success",
      message = ("Da hoan $%d phi thue xe"):format(total),
    })
  end
  self.refundProcessing[player.citizenId] = nil
end

-- A processing ledger row is deliberately never claimed again automatically:
-- the framework transfer could have completed before a crash or DB failure.
function TruckerService:ProcessPayment(missionId, citizenId, kind, amount, playerSource)
  local ok, status = pcall(Database.EnsurePayment, missionId, citizenId, kind, amount)
  if not ok or not status then
    self.context.logger:Error("could not persist payment intent %s/%s (%s, %s): %s",
      missionId, citizenId, tostring(kind), tostring(amount),
      ok and "ledger row missing or amount mismatch" or tostring(status))
    return false
  end
  if status == "paid" then return true end
  if status ~= "pending" then return false end
  local player = self:PlayerData(playerSource)
  if not player or player.citizenId ~= citizenId then return false end
  if kind ~= "reward" and self.framework:GetMoney(playerSource, FLEET_ACCOUNT) < amount then
    return false
  end
  local claimed, claimResult = pcall(Database.ClaimPayment, missionId, citizenId, kind, amount)
  if not claimed or claimResult ~= true then return false end
  local transferred, result = pcall(function()
    if kind == "reward" then
      return self.framework:AddMoney(playerSource, REWARD_ACCOUNT, amount, "lr_trucker_job")
    end
    return self.framework:RemoveMoney(playerSource, FLEET_ACCOUNT, amount,
      kind == "rental_fee" and "trucker-rental" or "trucker-rental-overage")
  end)
  if not transferred then
    self.context.logger:Error("uncertain payment transfer %s/%s: %s", missionId, citizenId, tostring(result))
    return false
  end
  if result ~= true then
    pcall(Database.ResetPayment, missionId, citizenId, kind, amount)
    return false
  end
  local completed, saved = pcall(Database.CompletePayment, missionId, citizenId, kind, amount)
  if not completed or saved ~= true then
    self.context.logger:Error("payment needs reconciliation %s/%s", missionId, citizenId)
    return false
  end
  return true
end


function TruckerService:ProcessPendingPayments(playerSource, player)
  if type(Database.ListPendingRentalFees) == "function" then
    local feesOk, fees = pcall(Database.ListPendingRentalFees, player.citizenId)
    if not feesOk then return end
    for _, entry in ipairs(fees) do
      if not self:ProcessPayment(entry.missionId, player.citizenId,
        "rental_fee", entry.amount, playerSource) then return end
    end
  end
  local ok, charges = pcall(Database.ListPendingRentalCharges, player.citizenId)
  if not ok then return end
  for _, entry in ipairs(charges) do
    if not self:ProcessPayment(entry.missionId, player.citizenId,
      "rental_overage", entry.amount, playerSource) then return end
  end
  ok, charges = pcall(Database.ListPendingRewards, player.citizenId)
  if ok then
    for _, entry in ipairs(charges) do
      local checked, chargesPaid = pcall(Database.AreMissionChargesPaid, entry.missionId)
      if checked and chargesPaid and self:ProcessPayment(entry.missionId, player.citizenId,
        "reward", entry.amount, playerSource) then
        local checked, allPaid = pcall(Database.AreMissionRewardsPaid, entry.missionId)
        if checked and allPaid then self.businessOrderBoard:MarkPaid(entry.missionId) end
      end
    end
  end
end

local function freezePayoutMembers(session, total)
  if not session.payoutMembers then
    session.payoutMembers = { {
      citizenId = session.order.vehicleOwnerCitizenId,
      amount = total,
    } }
  end
end

function TruckerService:PrepareMission(session, total, bankDue)
  freezePayoutMembers(session, total)
  local ownerId = session.order.vehicleOwnerCitizenId or ""
  if bankDue > 0 then
    local ok, status = pcall(Database.PreparePayment, session.id, ownerId,
      "rental_overage", bankDue)
    if not ok or not status then return false end
  end
  for _, member in ipairs(session.payoutMembers) do
    local ok, status = pcall(Database.PreparePayment, session.id, member.citizenId,
      "reward", member.amount)
    if not ok or not status then return false end
  end
  return true
end

function TruckerService:PayMission(session, total, bankDue)
  freezePayoutMembers(session, total)
  local ownerId = session.order.vehicleOwnerCitizenId or ""
  if session.order.rentalId then
    local ok, committed = pcall(Database.CommitRentalAssessment,
      ownerId, session.order.rentalId, session.id)
    if not ok or committed ~= true then return false end
  end
  if session.payoutPrepared then
    if bankDue > 0 then
      local ok, activated = pcall(Database.ActivatePayment, session.id, ownerId,
        "rental_overage", bankDue)
      if not ok or activated ~= true then return false end
    end
    for _, member in ipairs(session.payoutMembers) do
      local ok, activated = pcall(Database.ActivatePayment, session.id, member.citizenId,
        "reward", member.amount)
      if not ok or activated ~= true then return false end
    end
  end
  local chargeStatus = "paid"
  if bankDue > 0 then
    local ok, status = pcall(Database.EnsurePayment, session.id, ownerId,
      "rental_overage", bankDue)
    if not ok or not status then return false end
    chargeStatus = status
  end
  for _, member in ipairs(session.payoutMembers) do
    local ok, status = pcall(Database.EnsurePayment, session.id, member.citizenId,
      "reward", member.amount)
    if not ok or not status then return false end
  end
  if chargeStatus ~= "paid" then
    local owner = session.team:FindMember(ownerId)
    local paid = owner and owner.online and self:ProcessPayment(session.id, ownerId,
      "rental_overage", bankDue, owner.source)
    if not paid then
      if not session.order.rentalId then return false end
      session.rentalDebtPending = true
    end
  end
  for _, entry in ipairs(session.payoutMembers) do
    local member = session.team:FindMember(entry.citizenId)
    if not member or not member.online or not self:ProcessPayment(session.id,
      entry.citizenId, "reward", entry.amount, member.source) then return false end
  end
  return true
end

function TruckerService:QueueRentalCharge(session, bankDue)
  local ownerId = session.order.vehicleOwnerCitizenId or ""
  local ok, status = pcall(Database.EnsurePayment, session.id, ownerId,
    "rental_overage", bankDue)
  if not ok or not status then return false end
  if status == "paid" then return true end
  local owner = session.team:FindMember(ownerId)
  if owner and owner.online then
    self:ProcessPayment(session.id, ownerId, "rental_overage", bankDue, owner.source)
  end
  return true
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@param requiredLevel? integer
---@return boolean, string
function TruckerService:IsEligible(playerSource, requiredLevel)
  local player = self:PlayerData(playerSource)
  if not player then return false, "Khong tim thay nhan vat Qbox" end
  if player.level < (requiredLevel or 1) then
    return false, ("Can cap do %d"):format(requiredLevel or 1)
  end
  local requiredJob = Config.Job.RequiredName
  if requiredJob ~= "" and (not player.job or player.job.name ~= requiredJob) then
    return false, "Cong viec hien tai khong duoc phep nhan don"
  end
  if Config.Job.RequireOnDuty and (not player.job or player.job.onDuty ~= true) then
    return false, "Ban can bat dau ca lam viec"
  end
  return true, ""
end
---@return LRServer.TruckerTeam
function TruckerService:CreateTeam(player)
  local team = Team:New({ id = self:NextId("team"), player = player })
  self.teams[team.id] = team
  self.sourceTeams[player.source] = team.id
  self.citizenTeams[player.citizenId] = team.id
  return team
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@return LRServer.TruckerTeam?
function TruckerService:EnsureTeam(playerSource)
  local player = self:PlayerData(playerSource)
  if not player then return nil end
  local teamId = self.sourceTeams[playerSource] or self.citizenTeams[player.citizenId]
  local team = teamId and self.teams[teamId] or nil
  if not team then return self:CreateTeam(player) end
  if #team.members ~= 1 or not team:IsHost(player.citizenId) then return nil end
  local member = team:Reconnect(player)
  if not member then return self:CreateTeam(player) end
  self.sourceTeams[playerSource] = team.id
  self.citizenTeams[player.citizenId] = team.id
  return team
end

---@param self LRServer.TruckerService
---@param team LRServer.TruckerTeam?
function TruckerService:DestroyTeam(team)
  if not team or not self.teams[team.id] then return end
  if team.session and not team.session:Cancel() then return end
  for index = 1, #team.members do
    local member = team.members[index]
    self.sourceTeams[member.source] = nil
    self.citizenTeams[member.citizenId] = nil
  end
  self.teams[team.id] = nil
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@param team LRServer.TruckerTeam?
---@return boolean
function TruckerService:IsHost(playerSource, team)
  local player = self:PlayerData(playerSource)
  return player ~= nil and team ~= nil and team:IsHost(player.citizenId)
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@return boolean
function TruckerService:IsNearNpc(playerSource)
  local coords = playerCoords(playerSource)
  return distance(coords, Config.NPC.coords) <= ACTION_DISTANCE
end

---@param self LRServer.TruckerService
---@param team LRServer.TruckerTeam
function TruckerService:SyncTeam(team)
  if not team or not self.net then return end
  local Net = self.net
  ---@cast Net LRServerTruckerNet
  local online = team:OnlineMembers()
  for index = 1, #online do
    local playerSource = online[index].source
    Net.events.sync:Emit(playerSource, { snapshot = self:GetSnapshot(playerSource) })
  end
end

---@param self LRServer.TruckerService
function TruckerService:SyncAllTeams()
  for _, team in pairs(self.teams) do self:SyncTeam(team) end
end

---@param self LRServer.TruckerService
---@param team LRServer.TruckerTeam
---@param noticeType LRServer.FrameworkNotificationType
---@param message string
function TruckerService:NotifyTeam(team, noticeType, message)
  local Net = assert(self.net)
  local online = team:OnlineMembers()
  for index = 1, #online do
    local playerSource = online[index].source
    Net.events.notice:Emit(playerSource, { type = noticeType, message = message })
  end
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@return table
function TruckerService:GetSnapshot(playerSource)
  local player = self:PlayerData(playerSource)
  if player then self:ProcessLegacyRentalRefund(playerSource, player) end
  if player then
    local lease = self:RentalLease(player.citizenId)
    if lease and lease.status == "active" then
      self:RentalTruck(player.citizenId, playerSource, lease)
    end
  end
  local team = player and self:EnsureTeam(playerSource) or nil
  local cash = 0
  local bank = 0
  if player and type(self.framework.GetMoney) == "function" then
    cash = self.framework:GetMoney(playerSource, REWARD_ACCOUNT)
    bank = self.framework:GetMoney(playerSource, FLEET_ACCOUNT)
  end
  local citizenId = player and player.citizenId or ""
  local fleet = self:GetFleetSnapshot(citizenId)
  fleet.bank = bank
  local business = self.businessContexts[playerSource] or {
    active = false, sourceOnline = BusinessIntegration:IsSourceOnline(), businessId = "",
    label = "", balance = 0, distanceKm = 0.0, feeBase = 0, feePerKm = 0,
    feePerPackage = 0, feeMaximum = 0, feeRate = 0, catalog = {}, orders = {},
  }
  local previousPage = self.orderPages[playerSource]
  local orderPage = self:GetOrderPage(player, "all",
    previousPage and previousPage.page or 1,
    previousPage and previousPage.pageSize or Config.BusinessOrders.PageSize)
  self.orderPages[playerSource] = orderPage
  return {
    player = {
      source = player and player.source or 0,
      citizenId = player and player.citizenId or "",
      name = player and player.name or "",
      cash = cash,
      bank = bank,
      level = player and player.level or 1,
      xp = player and player.xp or 0,
    },
    orderPage = orderPage,
    business = business,
    fleet = fleet,
    mission = team and team.session and team.session:Serialize() or idleMission(),
  }
end
---@return table
function TruckerService:ActionResult(playerSource, success, message)
  return { success = success, message = message, snapshot = self:GetSnapshot(playerSource) }
end

---@param self LRServer.TruckerService
---@param team LRServer.TruckerTeam
---@param order LRServer.TruckerOrder
---@param ownerSource integer
---@return LRServer.TruckerMissionSession
function TruckerService:CreateMission(team, order, ownerSource)
  local ownerId = order.vehicleOwnerCitizenId or ""
  local lease = order.rentalId and self:RentalLease(ownerId) or nil
  return MissionSession:New({
    order = order,
    team = team,
    ownerSource = ownerSource,
    config = Config,
    framework = self.framework,
    logger = self.context.logger,
    rentalTruck = lease and self.rentalEntities[ownerId] or nil,
    recoverRentalTruck = function()
      local current = self:RentalLease(ownerId)
      return current and self:RentalTruck(ownerId, ownerSource, current) or nil
    end,
    assessRental = function(session, grossReward)
      local current = self:RentalLease(ownerId)
      if not current or current.id ~= order.rentalId then return nil, nil end
      local ok, assessment = pcall(Database.PrepareRentalAssessment, current,
        session.id, grossReward, os.time(), Config.Fleet.OveragePercentPerMinute or 3)
      if not ok or not assessment then
        self.context.logger:Error("rental assessment failed for %s: %s",
          session.id, tostring(assessment))
        return nil, nil
      end
      return assessment.netReward, assessment.bankDue
    end,
    settleOrder = function(settledOrder, teamId, delivered)
      return self:SettleOrder(settledOrder, teamId, delivered)
    end,
    sync = function() self:SyncTeam(team) end,
    notify = function(noticeType, message) self:NotifyTeam(team, noticeType, message) end,
    markPayout = function(missionOrder)
      return missionOrder.kind ~= "business"
        or self.businessOrderBoard:MarkPaid(missionOrder.id)
    end,
    prepareTeam = function(session, total, bankDue)
      return self:PrepareMission(session, total, bankDue)
    end,
    payTeam = function(session, total, bankDue)
      return self:PayMission(session, total, bankDue)
    end,
    queueRentalCharge = function(session, bankDue)
      return self:QueueRentalCharge(session, bankDue)
    end,
    returnOwnedVehicle = function(entity, missionOrder)
      if missionOrder.vehicleMode ~= "owned" or missionOrder.ownedVehicleId == 0 then return true end
      local props = shallowCopy(missionOrder.vehicleProps)
      props.plate = missionOrder.vehiclePlate
      if entity and entity ~= 0 and DoesEntityExist(entity) then
        if type(GetVehicleBodyHealth) == "function" then props.bodyHealth = GetVehicleBodyHealth(entity) end
        if type(GetVehicleEngineHealth) == "function" then props.engineHealth = GetVehicleEngineHealth(entity) end
      end
      local ok, returned = pcall(
        Database.ReturnOwnedVehicle,
        missionOrder.vehicleOwnerCitizenId,
        missionOrder.ownedVehicleId,
        missionOrder.id,
        props
      )
      if not ok then
        self.context.logger:Error("owned truck return failed for %s: %s", missionOrder.id, tostring(returned))
        return false
      end
      return returned == true
    end,
    clearCompleted = function(session)
      if not self.stopped and team.session == session then
        team.session = nil
        self:SyncTeam(team)
      end
    end,
  })
end
---@param self LRServer.TruckerService
---@param playerSource integer
function TruckerService:HandlePlayerLoaded(playerSource)
  local player = self:PlayerData(playerSource)
  if not player then return end
  self.rentalSources[playerSource] = player.citizenId
  self:ProcessLegacyRentalRefund(playerSource, player)
  self:ProcessPendingPayments(playerSource, player)
  local lease = self:RentalLease(player.citizenId)
  if lease and lease.status == "pending" then
    lease = self:ResumePendingRental(playerSource, player, lease)
  end
  if lease and lease.status == "active" then
    self:RentalTruck(player.citizenId, playerSource, lease)
  end
  local teamId = self.citizenTeams[player.citizenId]
  local team = teamId and self.teams[teamId] or nil
  if not team then return end
  local member = team:Reconnect(player)
  if not member then return end
  self.sourceTeams[playerSource] = team.id
  if team.session then team.session:GiveReconnectKeys() end
  self:SyncTeam(team)
end

---@param self LRServer.TruckerService
---@param playerSource integer
function TruckerService:HandlePlayerUnloaded(playerSource)
  local teamId = self.sourceTeams[playerSource]
  local team = teamId and self.teams[teamId] or nil
  self.sourceTeams[playerSource] = nil
  local member = team and team:FindMemberBySource(playerSource) or nil
  local player = type(self.framework.GetPlayer) == "function" and self:PlayerData(playerSource) or nil
  local citizenId = player and player.citizenId or member and member.citizenId
    or self.rentalSources[playerSource]
  self.rentalSources[playerSource] = nil
  if not team then
    if citizenId then self:RemoveRentalTruck(citizenId) end
    return
  end
  if not member then
    if citizenId then self:RemoveRentalTruck(citizenId) end
    return
  end
  team:MarkOffline(playerSource)
  if team.session then team.session:ResetCarriedPackages(playerSource) end
  if #team:OnlineMembers() == 0 then self:DestroyTeam(team) else self:SyncTeam(team) end
  self:RemoveRentalTruck(citizenId or member.citizenId)
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@param expectedStep integer
---@return boolean, string
function TruckerService:AdvanceMission(playerSource, expectedStep)
  local team = self:EnsureTeam(playerSource)
  local session = team and team.session
  if not session or session.closed then return false, "Khong co nhiem vu dang chay" end
  return session:Advance(playerSource, expectedStep)
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@param action string
---@param packageIndex integer
---@return boolean, string
function TruckerService:ActOnPackage(playerSource, action, packageIndex)
  local team = self:EnsureTeam(playerSource)
  local session = team and team.session
  if not session or session.closed then return false, "Khong co nhiem vu dang chay" end
  return session:ActOnPackage(playerSource, action, packageIndex)
end

---@param self LRServer.TruckerService
---@param playerSource integer
---@param action string
---@return table
function TruckerService:RunQaScenario(playerSource, action)
  local function result(ok, errorCode, state, replayVerified, deleted)
    return {
      ok = ok,
      errorCode = errorCode or "",
      retryable = false,
      data = {
        state = state,
        replayVerified = replayVerified == true,
        deleted = deleted == true,
        snapshot = self:GetSnapshot(playerSource),
      },
    }
  end

  local team = self:EnsureTeam(playerSource)
  local session = team and team.session or nil
  if action == "snapshot" then
    local mission = self:GetSnapshot(playerSource).mission
    local state = mission.status == "completed" and "COMPLETED"
      or mission.step == 3 and "LOADING"
      or (mission.step == 4 or mission.step == 5) and "IN_TRANSIT"
      or mission.step == 6 and "UNLOADING"
      or mission.active and "ACTIVE"
      or "IDLE"
    return result(true, "", state, false, false)
  end
  if not team or not session or session.closed then
    return result(false, "NO_ACTIVE_MISSION", "IDLE", false, false)
  end

  local function setStep(expected, nextStep)
    if session.step ~= expected then return false end
    return session:SetStep(nextStep)
  end

  if action == "startManualLoading" then
    local moved = setStep(1, 2)
    if not moved then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    moved = setStep(2, 3)
    if not moved then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    return result(true, "", "LOADING", false, false)
  elseif action == "startLoading" then
    if session.step ~= 3 then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    for index = 1, #session.packages do
      local package = session.packages[index]
      package.state, package.carrierSource, package.slot = "loaded", 0, index
    end
    if not session:SetStep(4) then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    return result(true, "", "IN_TRANSIT", false, false)
  elseif action == "positionTutorialDelivery" then
    if not setStep(4, 5) then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    return result(true, "", "IN_TRANSIT", false, false)
  elseif action == "startManualUnloading" then
    if not setStep(5, 6) then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    return result(true, "", "UNLOADING", false, false)
  elseif action == "runTutorialDelivery" then
    if session.step ~= 6 then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    for index = 1, #session.packages do
      local package = session.packages[index]
      package.state, package.carrierSource, package.slot = "delivered", 0, index
    end
    if not session:SetStep(7) then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    local completed = session:Finish()
    if not completed then return result(false, "FINISH_FAILED", "ACTIVE", false, false) end
    local replayed = session:Finish()
    return result(true, "", "COMPLETED", replayed == false, false)
  elseif action == "deleteAssignedVehicle" then
    local truck = session.vehicles.truck
    if not truck or truck == 0 or not DoesEntityExist(truck) then
      return result(false, "VEHICLE_NOT_FOUND", "ACTIVE", false, false)
    end
    DeleteEntity(truck)
    return result(true, "", "ACTIVE", false, true)
  elseif action == "cleanup" then
    if not session:Cancel() then return result(false, "INVALID_STATE", "ACTIVE", false, false) end
    team.session = nil
    self:SyncTeam(team)
    return result(true, "", "CANCELLED", false, false)
  end

  return result(false, "UNSUPPORTED_ACTION", "ACTIVE", false, false)
end

---@param self LRServer.TruckerService
---@param startContext LRServer.ModuleContext
function TruckerService:RegisterNetworkHandlers(startContext)
  local Net = assert(self.net)
  local function authorize(playerSource)
    return type(playerSource) == "number"
      and playerSource > 0
      and startContext.services.framework:IsPlayerLoaded(playerSource)
  end

  startContext.disposables:Add(Net.rpc.getState:Handle(function(playerSource)
    return self:GetSnapshot(playerSource)
  end))

  startContext.disposables:Add(Net.rpc.getBusinessContext:Handle(
    function(playerSource, request)
      if not authorize(playerSource) then return self:ActionResult(playerSource, false, "Chưa sẵn sàng") end
      local player = self:PlayerData(playerSource)
      local context, message = self.businessOrderBoard:GetContext(
        playerSource, player, request.businessId
      )
      if not context then return self:ActionResult(playerSource, false, message) end
      self.businessContexts[playerSource] = context
      return self:ActionResult(playerSource, true, "Đã tải cổng đặt hàng")
    end
  ))

  startContext.disposables:Add(Net.rpc.listOrderBoard:Handle(
    function(playerSource, request)
      local page = self:GetOrderPage(
        self:PlayerData(playerSource), request.filter, request.page, request.pageSize
      )
      self.orderPages[playerSource] = page
      return page
    end
  ))

  startContext.disposables:Add(Net.rpc.createBusinessOrder:Handle({
    Authorize = authorize,
    Execute = function(playerSource, request)
      local player = self:PlayerData(playerSource)
      if not player then return self:ActionResult(playerSource, false, "Người chơi không hợp lệ") end
      local success, message = self:WithMutationLock("business:" .. request.businessId, function()
        return self.businessOrderBoard:Create(playerSource, player, request.businessId, request.lines)
      end)
      if success then
        self.businessContexts[playerSource] = self.businessOrderBoard:GetContext(
          playerSource, player, request.businessId
        )
        self.orderPages = {}
        self.boardCache = nil
        self:SyncAllTeams()
      end
      return self:ActionResult(playerSource, success, message)
    end,
  }))

  startContext.disposables:Add(Net.rpc.cancelBusinessOrder:Handle({
    Authorize = authorize,
    Execute = function(playerSource, request)
      local player = self:PlayerData(playerSource)
      if not player then return self:ActionResult(playerSource, false, "Người chơi không hợp lệ") end
      local existing = Database.GetBusinessOrder(request.orderId)
      local success, message = self:WithMutationLock("business-order:" .. request.orderId, function()
        return self.businessOrderBoard:Cancel(playerSource, player, request.orderId)
      end)
      if existing then
        self.businessContexts[playerSource] = self.businessOrderBoard:GetContext(
          playerSource, player, existing.businessId
        )
      else
        self.businessContexts[playerSource] = nil
      end
      self.orderPages = {}
      self.boardCache = nil
      if success then self:SyncAllTeams() end
      return self:ActionResult(playerSource, success, message)
    end,
  }))

  startContext.disposables:Add(Net.rpc.upgradeVehicle:Handle({
    Authorize = authorize,
    Execute = function(playerSource)
      return self:ActionResult(playerSource, false, "Tam dung nang cap xe; hien chi ho tro xe thue")
    end,
  }))

  startContext.disposables:Add(Net.rpc.acceptOrder:Handle({
    Authorize = authorize,
    Execute = function(playerSource, request)
      local team = self:EnsureTeam(playerSource)
      if not team or not self:IsHost(playerSource, team) or #team.members ~= 1 then
        return self:ActionResult(playerSource, false, "Chi chu don co the nhan don")
      end
      if team.session then return self:ActionResult(playerSource, false, "Doi dang co nhiem vu") end
      if not self:IsNearNpc(playerSource) then
        return self:ActionResult(playerSource, false, "Ban dang o qua xa nguoi dieu phoi")
      end
      local order = self:FindPublicOffer(request.offerId)
      if not order then return self:ActionResult(playerSource, false, "Don hang khong con kha dung") end
      if self.claimedOffers[request.offerId] then
        return self:ActionResult(playerSource, false, "Don hang dang duoc doi khac nhan")
      end
      self.claimedOffers[request.offerId] = true
      local eligible, reason = self:IsEligible(playerSource, order.level)
      if not eligible then
        self.claimedOffers[request.offerId] = nil
        return self:ActionResult(playerSource, false, reason)
      end
      local player = self:PlayerData(playerSource)
      if not player then
        self.claimedOffers[request.offerId] = nil
        return self:ActionResult(playerSource, false, "Nguoi choi khong hop le")
      end
      local success, message = self:WithMutationLock(player.citizenId, function()
        local debt = self:RentalDebt(player.citizenId)
        if debt == nil then return false, "Khong the kiem tra no thue xe" end
        if debt > 0 then return false, "Hay thanh toan phu phi thue xe con no" end
        local vehicle, vehicleError = self:ResolveRequestedVehicle(player.citizenId, request.vehicle)
        if not vehicle then return false, vehicleError end
        local existingLease = self:RentalLease(player.citizenId)
        if existingLease and existingLease.key ~= vehicle.key then
          return false, "Hay tra xe dang thue truoc khi chon xe khac"
        end
        local vehicleAllowed, allowedError = self:CanVehicleAccept(vehicle, order)
        if not vehicleAllowed then return false, allowedError end
        order = self:LoadForRental(order, vehicle)
        local reserved, reserveError
        if order.kind == "business" then
          reserved, reserveError = self.businessOrderBoard:Reserve(order, team.id)
        else
          reserved, reserveError = self.orderBoard:ReserveOrder(order, team.id)
        end
        if not reserved then
          if reserveError == "STOCK_UNAVAILABLE" then
            return false, "Kho khong con du hang cho don nay"
          elseif reserveError == "SOURCE_UNAVAILABLE" then
            return false, "Nguon xn-sellitem dang gian doan"
          elseif reserveError == "DATABASE_ERROR" then
            return false, "Khong the khoa don hang; vui long thu lai"
          elseif reserveError == "RESERVATION_RELEASE_PENDING" then
            return false, "Don dang cho hoan giu hang; vui long thu lai sau"
          elseif reserveError == "ORDER_EXPIRED" then
            return false, "Phieu dieu phoi da duoc lam moi; vui long chon phieu khac"
          elseif order.kind == "business" and reserveError ~= "ORDER_RESERVED" then
            return false, "Kho tu choi giu hang (" .. tostring(reserveError) .. "); vui long thu lai"
          end
          return false, "Tuyen duong nay dang duoc doi khac su dung"
        end
        local missionOrder = shallowCopy(order)
        missionOrder.vehicleMode = vehicle.mode
        missionOrder.vehicleModel = vehicle.model
        missionOrder.ownedVehicleId = vehicle.ownedVehicleId
        missionOrder.vehiclePlate = vehicle.vehiclePlate
        missionOrder.vehicleProps = vehicle.vehicleProps
        missionOrder.vehicleOwnerCitizenId = player.citizenId
        missionOrder.originalGarage = vehicle.originalGarage
        missionOrder.baseReward = order.reward
        missionOrder.reward = order.reward
        missionOrder.rentalFee = vehicle.fee or 0
        missionOrder.rentalKey = vehicle.key or ""
        local lease
        if vehicle.mode == "rental" then
          local rentalError
          lease, _, rentalError = self:AcquireRental(playerSource, player, vehicle)
          if not lease then
            self:SettleOrder(missionOrder, team.id, false)
            return false, rentalError
          end
          missionOrder.rentalId = lease.id
          missionOrder.rentalFee = lease.fee
          missionOrder.rentalKey = lease.key
          missionOrder.vehiclePlate = lease.plate
        else
          local checkoutOk, checkedOut = pcall(
            Database.CheckoutOwnedVehicle,
            player.citizenId,
            vehicle.ownedVehicleId,
            missionOrder.id
          )
          if not checkoutOk or not checkedOut then
            self:SettleOrder(missionOrder, team.id, false)
            pcall(
              Database.ReturnOwnedVehicle,
              player.citizenId,
              vehicle.ownedVehicleId,
              missionOrder.id,
              vehicle.vehicleProps
            )
            if not checkoutOk then
              startContext.logger:Error("owned truck checkout failed: %s", tostring(checkedOut))
            end
            return false, "Xe vua duoc su dung o noi khac"
          end
          missionOrder.vehicleModel = checkedOut.model
          missionOrder.vehiclePlate = checkedOut.plate
          missionOrder.vehicleProps = checkedOut.props
          missionOrder.originalGarage = checkedOut.originalGarage
        end
        local ok, sessionOrError = pcall(self.CreateMission, self, team, missionOrder, playerSource)
        if not ok then
          if not self:SettleOrder(missionOrder, team.id, false) then
            self:QueueSettlementRetry(missionOrder, team.id)
          end
          if vehicle.mode == "owned" then
            local returned, returnError = pcall(
              Database.ReturnOwnedVehicle,
              player.citizenId,
              vehicle.ownedVehicleId,
              missionOrder.id,
              missionOrder.vehicleProps
            )
            if not returned or returnError ~= true then
              startContext.logger:Error("owned truck rollback failed: %s", tostring(returnError))
            end
          end
          startContext.logger:Error("mission spawn failed: %s", tostring(sessionOrError))
          return false, "Khong the tao nhiem vu; xe thue van con hieu luc"
        end
        team.session = sessionOrError
        if missionOrder.kind ~= "business" then
          local _, currentOrderIndex = self.orderBoard:Find(missionOrder.id)
          if currentOrderIndex then self.orderBoard:RemoveAt(currentOrderIndex) end
        end
        self.orderPages = {}
        self.boardCache = nil
        local offerEntry = self.publicOfferLookup[request.offerId]
        if offerEntry then self.publicOffers[offerEntry.key] = nil end
        self.publicOfferLookup[request.offerId] = nil
        self:SyncAllTeams()
        return true, "Da nhan don hang"
      end)
      self.claimedOffers[request.offerId] = nil
      return self:ActionResult(playerSource, success, message)
    end,
  }))
  startContext.disposables:Add(Net.rpc.cancelMission:Handle({
    Authorize = authorize,
    Execute = function(playerSource)
      local team = self:EnsureTeam(playerSource)
      local session = team and team.session or nil
      if not team or not session then return self:ActionResult(playerSource, false, "Khong co nhiem vu") end
      if not self:IsHost(playerSource, team) then
        return self:ActionResult(playerSource, false, "Chi chu don co the huy")
      end
      if not session:Cancel() then
        return self:ActionResult(playerSource, false, "Chua the quyet toan ton kho; vui long thu lai")
      end
      team.session = nil
      self:NotifyTeam(team, "warning", "Nhiem vu da bi huy")
      self:SyncTeam(team)
      return self:ActionResult(playerSource, true, "Da huy nhiem vu")
    end,
  }))

  startContext.disposables:Add(Net.rpc.returnRental:Handle({
    Authorize = authorize,
    Execute = function(playerSource)
      local player = self:PlayerData(playerSource)
      local team = self:EnsureTeam(playerSource)
      if not player or not team or not self:IsHost(playerSource, team) then
        return self:ActionResult(playerSource, false, "Ban khong phai chu xe thue")
      end
      local success, message = self:WithMutationLock(player.citizenId, function()
        return self:ReturnRental(playerSource, player, team)
      end)
      return self:ActionResult(playerSource, success, message)
    end,
  }))

  startContext.disposables:Add(Net.rpc.settleRentalDebt:Handle({
    Authorize = authorize,
    Execute = function(playerSource)
      local player = self:PlayerData(playerSource)
      if not player then return self:ActionResult(playerSource, false, "Nguoi choi khong hop le") end
      local success, message = self:WithMutationLock(player.citizenId, function()
        self:ProcessPendingPayments(playerSource, player)
        local lease = self:RentalLease(player.citizenId)
        if lease and lease.status == "pending" then
          local resumed, rentalError = self:ResumePendingRental(playerSource, player, lease)
          if not resumed then return false, rentalError end
          if not self:RentalTruck(player.citizenId, playerSource, resumed) then
            return false, "Chua the khoi phuc xe thue; vui long thu lai"
          end
        end
        local debt = self:RentalDebt(player.citizenId)
        if debt == nil then return false, "Khong the kiem tra phu phi con no" end
        return debt == 0, debt == 0 and "Da thanh toan phu phi" or "Van con phu phi chua thanh toan"
      end)
      return self:ActionResult(playerSource, success, message)
    end,
  }))

  startContext.disposables:Add(Net.rpc.advance:Handle({
    Authorize = authorize,
    Execute = function(playerSource, request)
      local success, message = self:AdvanceMission(playerSource, request.expectedStep)
      return self:ActionResult(playerSource, success, message)
    end,
  }))

  startContext.disposables:Add(Net.rpc.packageAction:Handle({
    Authorize = authorize,
    Execute = function(playerSource, request)
      local success, message = self:ActOnPackage(playerSource, request.action, request.packageIndex)
      return self:ActionResult(playerSource, success, message)
    end,
  }))
end
function TruckerService:Start(startContext)
  self.net = startContext.net.Trucker
  math.randomseed(os.time() + GetGameTimer())
  if Config.BusinessOrders.Enabled then
    local ok, restored = pcall(function() return self.businessOrderBoard:Recover() end)
    if ok and restored > 0 then
      startContext.logger:Warn("reopened %d interrupted business order(s)", restored)
    elseif not ok then
      startContext.logger:Error("could not recover business orders: %s", tostring(restored))
    end
  end
  if type(Database.RecoverStaleCheckouts) == "function" then
    local ok, restored = pcall(Database.RecoverStaleCheckouts)
    if ok and restored > 0 then
      startContext.logger:Warn("restored %d stale owned truck checkout(s)", restored)
    elseif not ok then
      startContext.logger:Error("could not recover owned truck checkouts: %s", tostring(restored))
    end
  end
  if type(Database.RecoverRefundClaims) == "function" then
    local ok, released = pcall(Database.RecoverRefundClaims)
    if ok and released > 0 then
      startContext.logger:Warn("released %d interrupted legacy rental refund claim(s)", released)
    elseif not ok then
      startContext.logger:Error("could not recover legacy rental refunds: %s", tostring(released))
    end
  end
  if BusinessIntegration:IsSourceOnline() then
    self.npcHoldsRecovered = BusinessIntegration:ReleaseNpcHolds()
  end
  if self.npcHoldsRecovered then
    self.orderBoard:Refill()
  else
    startContext.logger:Warn("NPC order board waiting for xn-sellitem reservation recovery")
  end
  self:RegisterNetworkHandlers(startContext)

  if GetConvar("qa_mode", "disabled") == "attach-full" then
    startContext.disposables:Add(startContext.public.Trucker:Register({
      qaScenario = {
        Authorize = function(invokingResource)
          return invokingResource == GetConvar("lr_trucker_qa_adapter_resource", "qbx_qa_adapter")
        end,
        Execute = function(_, request)
          return self:RunQaScenario(request.playerSource, request.action)
        end,
      },
    }))
  end

  startContext.disposables:Add(self.framework:OnPlayerLoaded(function(playerSource)
    self:HandlePlayerLoaded(playerSource)
  end))
  startContext.disposables:Add(self.framework:OnPlayerUnloaded(function(playerSource)
    self:HandlePlayerUnloaded(playerSource)
  end))

  local getPlayers = rawget(_G, "GetPlayers")
  if type(getPlayers) == "function" then
    CreateThread(function()
      Wait(0)
      if self.stopped then return end
      for _, source in ipairs(getPlayers()) do
        self:HandlePlayerLoaded(tonumber(source) or source)
      end
    end)
  end

  CreateThread(function()
    local marketElapsed = 0
    local businessRecoveryElapsed = 0
    while not self.stopped do
      Wait(2000)
      if not self.npcHoldsRecovered and BusinessIntegration:IsSourceOnline() then
        self.npcHoldsRecovered = BusinessIntegration:ReleaseNpcHolds()
        if self.npcHoldsRecovered then
          self.orderBoard:TickMarket()
          self.orderPages = {}
          self.boardCache = nil
          self:SyncAllTeams()
        end
      end
      marketElapsed = marketElapsed + 2000
      businessRecoveryElapsed = businessRecoveryElapsed + 2000
      if businessRecoveryElapsed >= 10000 then
        businessRecoveryElapsed = 0
        if type(self.businessOrderBoard.RetryPendingReleases) == "function" then
          local ok, reopened = pcall(self.businessOrderBoard.RetryPendingReleases, self.businessOrderBoard)
          if ok and reopened > 0 then
            self.orderPages = {}
            self.boardCache = nil
            self:SyncAllTeams()
          elseif not ok then
            self.context.logger:Error("business reservation recovery failed: %s", tostring(reopened))
          end
        end
      end
      for _, team in pairs(self.teams) do
        if team.session then
          if #team:OnlineMembers() == 0 then
            self:DestroyTeam(team)
          else
            local ok, recoveryError = xpcall(function()
              team.session:RecoverMissingEntities()
            end, debug.traceback)
            if not ok then
              self.context.logger:Error("mission recovery failed for %s: %s", team.id, tostring(recoveryError))
            end
          end
        end
      end
      for orderId, pending in pairs(self.pendingSettlements) do
        if self:SettleOrder(pending.order, pending.teamId, false) then
          self.pendingSettlements[orderId] = nil
        end
      end
      if self.npcHoldsRecovered and marketElapsed >= MARKET_CYCLE_MS then
        marketElapsed = 0
        self.orderBoard:TickMarket()
        self.orderPages = {}
        self.boardCache = nil
        self:SyncAllTeams()
      end
    end
  end)

  startContext.logger:Info("trucker server started with %d dynamic routes", #Config.Routes)
end
---@param self LRServer.TruckerService
function TruckerService:Stop()
  self.stopped = true
  for _, team in pairs(self.teams) do
    if team.session then
      if team.session.order and team.session.order.vehicleMode == "rental"
        and not team.session.order.rentalId
        and not team.session.deliveredSettlement
        and (team.session.order.rentalFee or 0) > 0
        and type(Database.QueueRentalRefund) == "function" then
        Database.QueueRentalRefund(
          "technical-stop:" .. team.session.order.id,
          team.session.order.vehicleOwnerCitizenId,
          team.session.order.rentalFee
        )
      end
      -- Foreign settlement exports can await SQL after this script host is gone.
      -- xn-sellitem releases NPC holds in its own onResourceStop handler;
      -- business orders and owned checkouts recover on the next start.
      team.session:CleanupEntities()
    end
  end
  for citizenId in pairs(self.rentalEntities) do self:RemoveRentalTruck(citizenId) end
  self.orderBoard:Clear()
  self.teams = {}
  self.sourceTeams = {}
  self.citizenTeams = {}
  self.refundProcessing = {}
  self.refundChecked = {}
  self.mutationLocks = {}
  self.pendingSettlements = {}
  self.businessContexts = {}
  self.orderPages = {}
  self.boardCache = nil
  self.publicOffers = {}
  self.publicOfferLookup = {}
  self.claimedOffers = {}
  self.rentalEntities = {}
  self.rentalSources = {}
end

LRTruckerServer.TruckerService = TruckerService
