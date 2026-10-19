local function assertTrue(value, message)
  if value ~= true then error(message or "expected true") end
end

local function assertFalse(value, message)
  if value ~= false then error(message or "expected false") end
end

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

local function assertNear(actual, expected, message)
  if math.abs(actual - expected) > 0.0001 then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

local function v3(x, y, z)
  return { x = x, y = y, z = z }
end

local function v4(x, y, z, w)
  return { x = x, y = y, z = z, w = w }
end

local entities = {}
local nextEntity = 100
local pedVehicles = {}
local playerPeds = { [1] = 1, [2] = 2 }
local delayedThreads = {}
local hashes = { phantom = 1001, trflat = 1002, sadler = 1003, forklift = 1004, prop_boxpile_06a = 1005, speedo = 1006, tanker = 1007, mule = 1008, benson = 1009 }

entities[1] = { coords = v3(0, 0, 0), heading = 0 }
entities[2] = { coords = v3(0, 0, 0), heading = 0 }

local function createEntity(model, coords, heading)
  nextEntity = nextEntity + 1
  entities[nextEntity] = {
    model = model,
    coords = v3(coords.x, coords.y, coords.z),
    heading = heading or coords.w or 0,
    frozen = false,
  }
  return nextEntity
end

local function setCoords(entity, coords)
  entities[entity].coords = v3(coords.x, coords.y, coords.z)
  if coords.w ~= nil then entities[entity].heading = coords.w end
end

local function setDriver(vehicle, playerSource)
  local ped = playerPeds[playerSource]
  entities[vehicle].driver = ped
  pedVehicles[ped] = vehicle
end

function vector3(x, y, z) return v3(x, y, z) end
function vector4(x, y, z, w) return v4(x, y, z, w) end
vec4 = vector4
function GetHashKey(model) return hashes[model] or 9999 end
function GetPlayerRoutingBucket() return 0 end
function GetPlayerPed(playerSource) return playerPeds[playerSource] or 0 end
function DoesEntityExist(entity) return entities[entity] ~= nil end
function GetEntityCoords(entity) return entities[entity].coords end
function GetEntityHeading(entity) return entities[entity].heading end
function GetEntityModel(entity) return entities[entity].model end
function GetVehicleBodyHealth(entity) return entities[entity].bodyHealth or 1000 end
function GetPedInVehicleSeat(vehicle) return entities[vehicle] and entities[vehicle].driver or 0 end
function GetVehiclePedIsIn(ped) return pedVehicles[ped] or 0 end
function NetworkGetNetworkIdFromEntity(entity) return entity + 1000 end
function SetEntityOrphanMode() end
function SetEntityRoutingBucket() end
function SetVehicleNumberPlateText(entity, plate) entities[entity].plate = plate end
function FreezeEntityPosition(entity, frozen) entities[entity].frozen = frozen end
function DeleteEntity(entity)
  if entities[entity] and entities[entity].driver then pedVehicles[entities[entity].driver] = nil end
  entities[entity] = nil
end
function SetEntityCoords(entity, x, y, z) entities[entity].coords = v3(x, y, z) end
function CreateVehicleServerSetter(model, _, x, y, z, heading)
  return createEntity(model, v3(x, y, z), heading)
end
function CreateObjectNoOffset(model, x, y, z)
  return createEntity(model, v3(x, y, z), 0)
end
function CreateThread(callback) delayedThreads[#delayedThreads + 1] = callback end
function Wait() end
function SetLocale() return {} end
dofile("config.lua")

LR = {}
dofile("shared/core/lr.lua")
dofile("shared/core/class.lua")
dofile("server/classes/trucker/team.lua")
dofile("server/classes/trucker/mission_session.lua")

local config = {
  Fleet = Config.Fleet,
  Market = Config.Market,
  ReturnPoint = v4(30, 0, 0, 90),
  BusinessOrders = {
    Pickup = {
      vehicles = {
        truck = { coords = v4(0, 0, 0, 0) },
        trailer = v4(2, 0, 0, 0),
        escort = v4(4, 0, 0, 0),
      },
      parking = v4(10, 0, 0, 90),
      packages = v4(12, 0, 1, 0),
      forklifts = {},
    },
    Businesses = {},
  },
  Routes = {
    {
      vehicles = {
        truck = { model = "phantom", coords = v4(0, 0, 0, 0) },
        trailer = v4(2, 0, 0, 0),
        escort = v4(4, 0, 0, 0),
      },
      pickup = {
        parking = v4(10, 0, 0, 90),
        packages = v4(12, 0, 1, 0),
        forklifts = { v4(12, 0, 0, 90) },
      },
      delivery = {
        parking = v4(20, 0, 0, 90),
        packages = v3(22, 0, 1),
        forklifts = { v4(22, 0, 0, 90) },
      },
    },
  },
}

local balances = { [1] = 0, [2] = 0 }
local metadata = { [1] = 25, [2] = 50 }
local keys = {}
local framework = {}
local currentTime = 1000000
os.time = function() return currentTime end

function framework:GiveVehicleKeys(playerSource, vehicle)
  keys[#keys + 1] = { source = playerSource, vehicle = vehicle }
end

function framework:AddMoney(playerSource, account, amount, reason)
  assertEqual(account, "cash", "mission paid the wrong account")
  assertEqual(reason, "lr_trucker_job", "mission used the wrong payout reason")
  balances[playerSource] = balances[playerSource] + amount
  return true
end

function framework:GetMetadata(playerSource, key)
  assertEqual(key, "trucker_xp", "mission read the wrong metadata key")
  return metadata[playerSource]
end

function framework:SetMetadata(playerSource, key, value)
  assertEqual(key, "trucker_xp", "mission wrote the wrong metadata key")
  metadata[playerSource] = value
  return true
end

local team = LRTruckerServer.Team:New({
  id = "team-1",
  player = { source = 1, citizenId = "citizen-1", name = "Driver", xp = 0, level = 1 },
})
team:AddMember({ source = 2, citizenId = "citizen-2", name = "Loader", xp = 0, level = 1 })

local orderSequence = 0
local function newSession(packageAmount, vehicleMode, ownedVehicleId, rentalModel, options)
  options = options or {}
  orderSequence = orderSequence + 1
  local stats = { settlements = 0, delivered = nil, returns = 0, syncs = 0, clears = 0, notices = {} }
  local session
  session = LRTruckerServer.MissionSession:New({
    order = {
      id = "order-" .. orderSequence,
      name = "Runtime route",
      itemLabel = "Cam",
      destination = "Runtime destination",
      kind = options.kind or "market",
      distanceKm = options.distanceKm or 1,
      logisticsUnits = options.logisticsUnits or (packageAmount or 2) * 4,
      routeIndex = 1,
      deliveryRouteIndex = options.deliveryRouteIndex or 1,
      packageAmount = packageAmount or 2,
      reward = options.reward or 1000,
      xp = 100,
      vehicleMode = vehicleMode or "owned",
      vehicleModel = vehicleMode == "rental" and (rentalModel or "speedo") or "phantom",
      rentalFee = options.rentalFee or 0,
      rentalId = options.rentalId,
      ownedVehicleId = ownedVehicleId or 0,
      vehiclePlate = ownedVehicleId and "OWNED77" or "TRUCKER",
    },
    team = team,
    ownerSource = 1,
    config = config,
    framework = framework,
    logger = { Error = function() end },
    settleOrder = function(order, teamId, delivered)
      assertEqual(order.routeIndex, 1)
      assertEqual(teamId, "team-1")
      stats.settlements = stats.settlements + 1
      stats.delivered = delivered
      return true
    end,
    sync = function() stats.syncs = stats.syncs + 1 end,
    notify = function(noticeType, message)
      stats.notices[#stats.notices + 1] = { type = noticeType, message = message }
    end,
    returnOwnedVehicle = function(entity, order)
      assertTrue(DoesEntityExist(entity), "owned vehicle was deleted before being stored")
      assertEqual(order.ownedVehicleId, ownedVehicleId, "wrong owned vehicle was returned")
      stats.returns = stats.returns + 1
      return true
    end,
    clearCompleted = function(completed)
      stats.clears = stats.clears + 1
      assertEqual(completed, session)
    end,
    prepareTeam = options.prepareTeam,
    payTeam = options.payTeam,
    markPayout = options.markPayout,
    queueRentalCharge = options.queueRentalCharge,
    rentalTruck = options.rentalTruck,
    assessRental = options.assessRental,
    recoverRentalTruck = options.recoverRentalTruck,
  })
  return session, stats
end

local leasedTruck = createEntity(hashes.mule, v4(0, 0, 0, 0), 0)
local leaseOptions = {
  rentalId = "lease-1", rentalTruck = leasedTruck,
  assessRental = function(_, gross) return gross, 0 end,
  prepareTeam = function() return true end,
  payTeam = function() return true end,
}
local firstLeaseJob = newSession(1, "rental", nil, "mule", leaseOptions)
assertEqual(firstLeaseJob.vehicles.truck, leasedTruck, "first order did not use the leased truck")
assertTrue(firstLeaseJob:Finish(), "first leased order did not finish")
assertTrue(DoesEntityExist(leasedTruck), "finishing the order deleted the rented truck")
local secondLeaseJob = newSession(1, "rental", nil, "mule", leaseOptions)
assertEqual(secondLeaseJob.vehicles.truck, leasedTruck, "second order spawned a different truck")
assertTrue(secondLeaseJob:Cancel(), "second leased order did not cancel")
assertTrue(DoesEntityExist(leasedTruck), "cancelling the order deleted the rented truck")
DeleteEntity(leasedTruck)
keys = {}
metadata[1], metadata[2] = 25, 50
delayedThreads = {}

local payouts, marks, preparations = {}, 0, 0
local session, stats
session, stats = newSession(2, nil, nil, nil, {
  prepareTeam = function(_, total, bankDue)
    assertEqual(stats.settlements, 0, "payment intent was recorded after cargo import")
    assertEqual(total, 8800)
    assertEqual(bankDue, 0)
    preparations = preparations + 1
    return true
  end,
  payTeam = function(delivering, total, bankDue)
    assertEqual(delivering.order.kind, "market")
    assertEqual(total, 8800, "NPC payout formula was not passed to the team callback")
    assertEqual(bankDue, 0)
    assertEqual(stats.settlements, 1, "payment ran before cargo settlement")
    payouts[#payouts + 1] = total
    local members = delivering.team:OnlineMembers()
    local each = math.floor(total / #members)
    for _, member in ipairs(members) do
      assertTrue(framework:AddMoney(member.source, "cash", each, "lr_trucker_job"))
    end
    return true
  end,
  markPayout = function()
    assertEqual(#payouts, 1, "payout was marked before the payment callback")
    marks = marks + 1
    return true
  end,
})
assertEqual(session.step, 1)
assertEqual(#session.packages, 2)
assertFalse(session:Advance(99, 1), "other player advanced the driver's mission")
assertFalse(session:ActOnPackage(99, "lift", 1), "other player touched the driver's cargo")
assertEqual(#keys, 2, "owned truck keys were not shared with the team")
assertFalse(session:Advance(1, 2), "a stale expected step advanced the mission")

setCoords(session.vehicles.truck, config.Routes[1].pickup.parking)
setDriver(session.vehicles.truck, 1)
assertTrue(session:Advance(1, 1), "step 1 did not advance at the pickup")
assertEqual(session.step, 2)
assertEqual(session.vehicles.escort, 0, "unused escort vehicle was not cleaned at step 2")
assertFalse(session:Advance(1, 2), "step 2 advanced before the trailer was parked")

setCoords(session.vehicles.trailer, config.Routes[1].pickup.parking)
setCoords(session.vehicles.truck, config.Routes[1].pickup.parking)
setDriver(session.vehicles.truck, 1)
assertTrue(session:Advance(1, 2), "step 2 did not advance with the parked trailer")
assertEqual(session.step, 3)
assertEqual(#session.forklifts, 1)
assertFalse(session:ActOnPackage(1, "lift", 1), "package lift succeeded without the mission forklift")

local function loadPackage(packageIndex)
  local forklift = session.forklifts[1].entity
  local package = session.packages[packageIndex]
  setDriver(forklift, 1)
  setCoords(forklift, config.Routes[1].pickup.packages)
  setCoords(package.entity, config.Routes[1].pickup.packages)
  assertTrue(session:ActOnPackage(1, "lift", packageIndex), "package lift failed")
  assertEqual(package.state, "carried")
  setCoords(forklift, config.Routes[1].pickup.parking)
  setCoords(package.entity, config.Routes[1].pickup.parking)
  setCoords(session.vehicles.trailer, config.Routes[1].pickup.parking)
  assertTrue(session:ActOnPackage(1, "load", packageIndex), "package load failed")
  assertEqual(package.state, "loaded")
end

loadPackage(1)
assertEqual(session.step, 3)
loadPackage(2)
assertEqual(session.step, 4, "loading every package did not advance to transit")
assertEqual(#session.forklifts, 0, "pickup forklifts were not cleaned after loading")

setCoords(session.vehicles.truck, config.Routes[1].delivery.parking)
setDriver(session.vehicles.truck, 1)
assertTrue(session:Advance(1, 4), "step 4 did not advance at delivery")
assertEqual(session.step, 5)
setCoords(session.vehicles.trailer, config.Routes[1].delivery.parking)
setCoords(session.vehicles.truck, config.Routes[1].delivery.parking)
setDriver(session.vehicles.truck, 1)
assertTrue(session:Advance(1, 5), "step 5 did not advance with the parked trailer")
assertEqual(session.step, 6)
assertEqual(#session.forklifts, 1)

local function deliverPackage(packageIndex)
  local forklift = session.forklifts[1].entity
  local package = session.packages[packageIndex]
  setDriver(forklift, 1)
  setCoords(forklift, config.Routes[1].delivery.parking)
  setCoords(package.entity, config.Routes[1].delivery.parking)
  assertTrue(session:ActOnPackage(1, "lift", packageIndex), "delivery lift failed")
  assertEqual(package.state, "unloading")
  setCoords(forklift, config.Routes[1].delivery.packages)
  setCoords(package.entity, config.Routes[1].delivery.packages)
  assertTrue(session:ActOnPackage(1, "deliver", packageIndex), "package delivery failed")
  assertEqual(package.state, "delivered")
end

deliverPackage(1)
assertEqual(session.step, 6)
deliverPackage(2)
assertEqual(session.step, 7, "delivering every package did not advance to return")
assertEqual(#session.forklifts, 0, "delivery forklifts were not cleaned after unloading")

setCoords(session.vehicles.truck, config.ReturnPoint)
setCoords(session.vehicles.trailer, config.ReturnPoint)
setDriver(session.vehicles.truck, 1)
assertEqual(#payouts, 0, "key handoff or delivery paid too early")
assertEqual(marks, 0, "key handoff or delivery marked paid too early")
assertTrue(session:Advance(1, 7), "step 7 did not complete at the return point")
assertTrue(session.closed)
assertEqual(session.status, "completed")
assertEqual(stats.settlements, 1, "completed mission did not settle its order exactly once")
assertEqual(preparations, 1, "completion did not persist its payout before cargo import")
assertTrue(stats.delivered, "completed mission did not mark its cargo delivered")
assertEqual(#payouts, 1, "team callback was not invoked exactly once")
assertEqual(marks, 1, "successful reward was not marked paid exactly once")
assertEqual(balances[1], 4400, "host payout was not split evenly")
assertEqual(balances[2], 4400, "member payout was not split evenly")
assertEqual(metadata[1], 125, "host XP was not awarded")
assertEqual(metadata[2], 150, "member XP was not awarded")
assertEqual(#stats.notices, 1, "completion notification was not emitted")
assertFalse(session:Advance(1, 7), "completed mission accepted an idempotent replay")
assertEqual(balances[1], 4400, "replayed completion paid the host twice")
assertEqual(marks, 1, "replayed completion marked payout twice")
assertEqual(#delayedThreads, 1, "completion cleanup was not scheduled")
delayedThreads[1]()
assertEqual(stats.clears, 1, "completed mission was not cleared after the delay")

local economy = newSession(1)
economy.order.logisticsUnits = 10
local startedAt = economy.startedAt
assertEqual(economy:PaymentDue(startedAt), 9000, "initial NPC time bonus is wrong")
assertEqual(economy:PaymentDue(startedAt + 450), 8250, "midpoint NPC time bonus is wrong")
assertEqual(economy:PaymentDue(startedAt + 900), 7500, "deadline NPC time bonus is wrong")
assertEqual(economy:PaymentDue(startedAt + 901), 6000, "late NPC delivery retained a bonus")
entities[economy.vehicles.truck].bodyHealth = 500
assertEqual(economy:PaymentDue(startedAt), 7000, "body damage did not reduce the variable pay")
entities[economy.vehicles.truck].bodyHealth = 0
assertEqual(economy:PaymentDue(startedAt), 5000, "body damage reduced the fixed contract fee")
assertTrue(economy:Cancel())

local queuedOverages = {}
local overtime = newSession(1, "rental", nil, "mule", {
  rentalFee = 1234,
  queueRentalCharge = function(_, amount)
    queuedOverages[#queuedOverages + 1] = amount
    return true
  end,
})
startedAt = overtime.startedAt
assertEqual(overtime:PaymentDue(startedAt + 3600), 5400, "60-minute rental accrued overtime")
assertEqual(overtime:PaymentDue(startedAt + 3601), 5362, "61st minute did not round the fee up")
assertEqual(overtime:PaymentDue(startedAt + 3661), 5325, "second overtime minute was rounded incorrectly")
overtime.order.kind = "business"
overtime.order.reward = 10
local payment, bankDue = overtime:PaymentDue(startedAt + 3601)
assertEqual(payment, 0, "rental overtime did not consume the reward first")
assertEqual(bankDue, 28, "rental overtime shortfall did not go to the bank charge")
currentTime = startedAt + 3601
assertTrue(overtime:Cancel(), "overtime rental could not be cancelled")
assertEqual(queuedOverages[1], 38, "cancellation did not queue the full overtime fee")
currentTime = startedAt

local cancelled, cancelledStats = newSession(1)
assertTrue(cancelled:Cancel(), "active mission could not be cancelled")
assertTrue(cancelled.closed)
assertEqual(cancelledStats.settlements, 1, "cancel did not release the reserved cargo")
assertFalse(cancelledStats.delivered, "cancelled cargo was marked delivered")
assertFalse(cancelled:Cancel(), "cancel replay succeeded")
assertEqual(cancelledStats.settlements, 1, "cancel replay released the cargo twice")
assertEqual(balances[1], 4400, "cancelled mission paid a reward")

local owned, ownedStats = newSession(1, "owned", 77)
assertEqual(entities[owned.vehicles.truck].plate, "OWNED77", "owned plate was not applied")
assertTrue(owned:Cancel(), "owned mission could not be cancelled")
assertEqual(ownedStats.returns, 1, "owned truck was not returned exactly once")
assertFalse(owned:Cancel(), "owned cancellation replay succeeded")
assertEqual(ownedStats.returns, 1, "owned cancellation returned the truck twice")

local recovered, recoveredStats = newSession(1)
local missingTruck = recovered.vehicles.truck
DeleteEntity(missingTruck)
recovered:RecoverMissingEntities()
assertTrue(recovered.vehicles.truck ~= missingTruck, "missing mission truck was not replaced")
assertTrue(DoesEntityExist(recovered.vehicles.truck), "replacement truck does not exist")
assertEqual(recoveredStats.syncs, 1, "entity recovery was not synchronized")

local carried = recovered.packages[1]
carried.state = "carried"
carried.carrierSource = 1
local carriedEntity = carried.entity
recovered:ResetCarriedPackages(1)
assertEqual(carried.state, "waiting", "disconnected carrier package was not reset")
assertEqual(carried.carrierSource, 0)
assertTrue(carried.entity ~= carriedEntity, "disconnected carrier package was not respawned")
assertTrue(DoesEntityExist(carried.entity))
recovered:Cancel()

local rental, rentalStats = newSession(1, "rental")
assertEqual(rental.vehicles.trailer, 0, "rental mission spawned a trailer")
assertEqual(rental.vehicles.escort, 0, "rental mission spawned an escort")
setCoords(rental.vehicles.truck, config.Routes[1].pickup.parking)
setDriver(rental.vehicles.truck, 1)
assertTrue(rental:Advance(1, 1), "rental truck did not reach pickup")
assertTrue(rental:Advance(1, 2), "rental truck required a trailer to start loading")
assertEqual(rental.step, 3)
assertTrue(rental:Cancel())
assertEqual(rentalStats.settlements, 1, "rental cancellation did not settle")

-- Closed vans store packages logically; loading/unloading uses the rear marker.
config.Routes[1].delivery.forklifts[2] = v4(24, 0, 0, 90)
for _, model in ipairs({ "speedo", "mule", "benson" }) do
  local van = newSession(2, "rental", nil, model)
  local offset = config.Fleet.RearLoading[model]
  assertTrue(offset.y < -3, "rear marker must sit behind the cargo bay")
  -- Exercise the same storage path for a business order as well as system orders.
  if model == "mule" then van.order.kind = "business"; van.order.cargoMode = "pallets" end
  setCoords(van.vehicles.truck, config.Routes[1].pickup.parking)
  setDriver(van.vehicles.truck, 1)
  assertTrue(van:Advance(1, 1))
  assertTrue(van:Advance(1, 2))
  local forklift = van.forklifts[1].entity
  -- Heading 90 rotates the local rear offset along world +X.
  local rear = v3(10 - offset.y, offset.x, offset.z)
  for index = 1, 2 do
    local package = van.packages[index]
    setDriver(forklift, 1)
    setCoords(forklift, GetEntityCoords(package.entity))
    assertFalse(van:ActOnPackage(2, "lift", index), "non-driver used the forklift")
    assertTrue(van:ActOnPackage(1, "lift", index))
    if index == 1 then
      van:ResetCarriedPackages(1)
      assertEqual(package.state, "waiting", "pickup disconnect lost cargo")
      setCoords(forklift, GetEntityCoords(package.entity))
      assertTrue(van:ActOnPackage(1, "lift", index))
    end
    setCoords(forklift, v3(rear.x + 3.01, rear.y, rear.z))
    setCoords(package.entity, GetEntityCoords(forklift))
    assertFalse(van:ActOnPackage(1, "load", index), "load allowed outside rear radius")
    setCoords(forklift, rear)
    setCoords(package.entity, rear)
    local removedEntity = package.entity
    assertTrue(van:ActOnPackage(1, "load", index))
    assertEqual(package.entity, 0, "loaded van cargo retained an entity")
    assertFalse(DoesEntityExist(removedEntity), "stored package remained visible")
    assertEqual(van:Serialize().packages[index].netId, 0)
    assertFalse(van:ActOnPackage(1, "load", index), "duplicate load accepted")
  end
  assertEqual(van.step, 4, "van did not advance after all cargo was stored")
  local beforeRecovery = nextEntity
  van:RecoverMissingEntities()
  assertEqual(nextEntity, beforeRecovery, "watchdog respawned hidden cargo")
  setCoords(van.vehicles.truck, config.Routes[1].delivery.parking)
  setDriver(van.vehicles.truck, 1)
  assertTrue(van:Advance(1, 4))
  assertTrue(van:Advance(1, 5))
  forklift = van.forklifts[1].entity
  local otherForklift = van.forklifts[2].entity
  -- Also validate a rotated truck at heading zero, without relying on world axes.
  setCoords(van.vehicles.truck, v4(20, 0, 0, 0))
  rear = v3(20 + offset.x, offset.y, offset.z)
  setDriver(forklift, 1)
  setDriver(otherForklift, 2)
  setCoords(forklift, v3(rear.x, rear.y - 3.01, rear.z))
  assertFalse(van:ActOnPackage(1, "lift", 1), "remote unload accepted")
  setCoords(forklift, rear)
  setCoords(otherForklift, rear)
  assertFalse(van:ActOnPackage(1, "lift", 2), "unload skipped the first stored package")
  local originalSpawn = van.SpawnPackageAt
  van.SpawnPackageAt = function() error("test spawn failure") end
  assertFalse(van:ActOnPackage(1, "lift", 1), "failed spawn was accepted")
  assertEqual(van.packages[1].state, "loaded", "spawn failure removed stored cargo")
  assertEqual(van.packages[1].entity, 0)
  van.SpawnPackageAt = function(self, coords)
    assertFalse(self:ActOnPackage(2, "lift", 1), "overlapping request took the same package")
    return originalSpawn(self, coords)
  end
  assertTrue(van:ActOnPackage(1, "lift", 1))
  van.SpawnPackageAt = originalSpawn
  assertFalse(van:ActOnPackage(2, "lift", 1), "second member took an unloading package")
  assertFalse(van:ActOnPackage(1, "lift", 2), "loaded forklift took another package")
  local detachedEntity = van.packages[1].entity
  van:ResetCarriedPackages(1)
  assertEqual(van.packages[1].state, "loaded", "delivery disconnect did not restore stored cargo")
  assertEqual(van.packages[1].entity, 0)
  assertFalse(DoesEntityExist(detachedEntity))
  van:RecoverMissingEntities()
  assertEqual(van.packages[1].entity, 0, "disconnect recovery exposed hidden cargo")
  assertTrue(van:ActOnPackage(1, "lift", 1))
  DeleteEntity(van.packages[1].entity)
  van:RecoverMissingEntities()
  assertEqual(van.packages[1].state, "loaded", "lost unloading entity was not restored to storage")
  assertEqual(van.packages[1].entity, 0)
  assertTrue(van:ActOnPackage(1, "lift", 1))
  assertTrue(van:ActOnPackage(2, "lift", 2), "second member could not take the next package")
  for index = 1, 2 do
    local carrier = index == 1 and forklift or otherForklift
    setCoords(carrier, config.Routes[1].delivery.packages)
    setCoords(van.packages[index].entity, config.Routes[1].delivery.packages)
    assertTrue(van:ActOnPackage(index, "deliver", index))
    assertEqual(van.packages[index].state, "delivered")
  end
  assertEqual(van.step, 7, "van did not advance after all cargo was delivered")
  assertTrue(van:Cancel())
end

local tankerStats = { settlements = 0, syncs = 0, payoutAttempts = 0, marks = 0 }
local allowBusinessPayment = false
local tanker = LRTruckerServer.MissionSession:New({
  order = {
    id = "business-tanker", name = "Dầu thô", itemLabel = "Dầu thô",
    destination = "Trạm xăng", logisticsUnits = 4, routeIndex = 1,
    packageAmount = 1, reward = 50, goodsTotal = 500, deliveryFee = 50,
    xp = 100, vehicleMode = "rental",
    vehicleModel = "phantom", ownedVehicleId = 0, vehiclePlate = "TANKER",
    kind = "business", cargoMode = "tanker", businessId = "gas_station_1",
    destinationCoords = v4(20, 0, 0, 90), fuelLiters = 100,
    lines = {{
      itemId = "dau_tho", label = "Dầu thô", category = "fuel", quantity = 1,
      unitPrice = 500, subtotal = 500, packages = 1,
      destinationAmount = 100, destinationUnit = "liter", destinationItemId = "", destinationLabel = "Nhiên liệu",
      index = 1, reservationId = "business-tanker:1", reservationState = "reserved",
    }},
  },
  team = team, ownerSource = 1, config = config, framework = framework,
  logger = { Error = function() end },
  settleOrder = function(_, _, delivered)
    tankerStats.settlements = tankerStats.settlements + 1
    return delivered
  end,
  sync = function() tankerStats.syncs = tankerStats.syncs + 1 end,
  notify = function() end,
  clearCompleted = function() end,
  payTeam = function(delivering, total, bankDue)
    assertEqual(tankerStats.settlements, 1, "business payout ran before warehouse import")
    assertEqual(total, 50, "business driver pay changed from the locked 10% fee")
    assertEqual(bankDue, 0)
    tankerStats.payoutAttempts = tankerStats.payoutAttempts + 1
    return allowBusinessPayment
  end,
  markPayout = function()
    assertTrue(allowBusinessPayment, "failed payout was marked paid")
    tankerStats.marks = tankerStats.marks + 1
    return true
  end,
})
assertEqual(#tanker.packages, 0, "tanker mission spawned pallet cargo")
assertTrue(tanker.vehicles.trailer ~= 0, "tanker rental did not spawn its tanker trailer")
entities[tanker.vehicles.truck].bodyHealth = 200
assertEqual(tanker:PaymentDue(tanker.startedAt), 50, "business pay was reduced by body damage")
dofile("shared/core/schema.lua")
dofile("client/generated/contracts/trucker.lua")
local missionSnapshot = LR.Generated.Contracts.trucker.nui.state.snapshot.default
missionSnapshot.mission = tanker:Serialize()
dofile("server/generated/contracts/trucker.lua")
local validMission, missionError = LR.Generated.Contracts.trucker.net.events.serverToClient.sync.validate({
  snapshot = missionSnapshot,
})
assertTrue(validMission, missionError)
assertEqual(missionSnapshot.mission.lines[1].reservationId, nil, "mission leaked private reservation")
assertEqual(tanker.order.lines[1].reservationId, "business-tanker:1", "mission serialization mutated its order")
setCoords(tanker.vehicles.truck, config.BusinessOrders.Pickup.parking)
setDriver(tanker.vehicles.truck, 1)
assertTrue(tanker:Advance(1, 1), "tanker did not reach source")
setCoords(tanker.vehicles.trailer, config.BusinessOrders.Pickup.parking)
assertTrue(tanker:Advance(1, 2), "tanker did not skip pallet loading")
assertEqual(tanker.step, 4)
setCoords(tanker.vehicles.truck, v4(20, 0, 0, 90))
setDriver(tanker.vehicles.truck, 1)
assertTrue(tanker:Advance(1, 4), "tanker did not reach station")
setCoords(tanker.vehicles.trailer, v4(20, 0, 0, 90))
assertTrue(tanker:Advance(1, 5), "tanker pump did not start")
assertEqual(tanker.step, 6)
delayedThreads[#delayedThreads]()
assertEqual(tanker.step, 7, "server-controlled tanker pump did not finish")
assertEqual(tanker.fuelProgress, 100, "tanker pump progress did not reach 100")
assertEqual(tankerStats.payoutAttempts, 0, "business payout ran before mission completion")
assertEqual(tankerStats.marks, 0, "key handoff marked the business order paid")
setCoords(tanker.vehicles.truck, config.ReturnPoint)
setCoords(tanker.vehicles.trailer, config.ReturnPoint)
setDriver(tanker.vehicles.truck, 1)
assertFalse(tanker:Advance(1, 7), "failed business payout completed the mission")
assertEqual(tankerStats.settlements, 1, "failed payout repeated warehouse import")
assertEqual(tankerStats.marks, 0, "failed business payout marked the order paid")
assertFalse(tanker.closed, "failed business payout closed the mission")
allowBusinessPayment = true
assertTrue(tanker:Advance(1, 7), "tanker could not return and settle")
assertEqual(tankerStats.settlements, 1, "tanker delivery settled more than once")
assertEqual(tankerStats.payoutAttempts, 2, "business payout did not retry after known failure")
assertEqual(tankerStats.marks, 1, "business order was not marked after payment")
assertFalse(tanker:Advance(1, 7), "business completion replay was accepted")
assertEqual(tankerStats.marks, 1, "business completion replay marked payout twice")

-- Client interaction must target the rear marker, never an invisible cargo entity.
LRTruckerClient = {}
dofile("client/classes/trucker/mission.lua")
local marker, helpText, markerArgs, parkingLines
local gameTime = 5000
function PlayerPedId() return 1 end
function PlayerId() return 0 end
function GetPlayerServerId() return 1 end
function NetworkDoesEntityExistWithNetworkId(netId) return entities[netId - 1000] ~= nil end
function NetToVeh(netId) return netId - 1000 end
function NetToObj(netId) return netId - 1000 end
function GetGameTimer() return gameTime end
function IsControlJustReleased() return true end
function IsEntityAttachedToEntity() return true end
function GetOffsetFromEntityInWorldCoords(entity, x, y, z)
  local coords = GetEntityCoords(entity)
  local heading = math.rad(GetEntityHeading(entity))
  return v3(coords.x + x * math.cos(heading) - y * math.sin(heading),
    coords.y + x * math.sin(heading) + y * math.cos(heading), coords.z + z)
end
function DrawMarker(...)
  markerArgs = table.pack(...)
  marker = v3(markerArgs[2], markerArgs[3], markerArgs[4])
end
function DrawLine(...)
  parkingLines[#parkingLines + 1] = table.pack(...)
end
function BeginTextCommandDisplayHelp() end
function AddTextComponentSubstringPlayerName(text) helpText = text end
function EndTextCommandDisplayHelp() end

for _, model in ipairs({ "speedo", "mule", "benson" }) do
  local truck = createEntity(hashes[model], v3(0, 0, 0), 90)
  local offset = Config.Fleet.RearLoading[model]
  local rear = v3(-offset.y, offset.x, offset.z)
  local forklift = createEntity(hashes.forklift, rear, 0)
  local box = createEntity(hashes.prop_boxpile_06a, rear, 0)
  setDriver(forklift, 1)
  local requests = {}
  local client = LRTruckerClient.Mission:New({
    snapshot = {}, advance = function() end,
    packageAction = function(request) requests[#requests + 1] = request end,
  })
  local view = {
    vehicleMode = "rental", vehicleModel = model, cargoMode = "pallets", step = 3,
    truckNetId = truck + 1000,
    packages = {{ index = 1, state = "carried", carrierSource = 1, netId = box + 1000 }},
  }
  client:HandlePackages(view, config.Routes[1])
  assertEqual(#requests, 1, "rear marker did not submit a load")
  assertEqual(requests[1].action, "load")
  assertEqual(marker.x, rear.x, "client rear marker used a cargo slot")
  assertTrue(helpText:find("Cất kiện vào xe", 1, true) ~= nil)
  view.step = 6
  -- Intentionally reverse the array: choose the smallest index, not first table entry.
  view.packages = {
    { index = 2, state = "loaded", carrierSource = 0, netId = 0 },
    { index = 1, state = "loaded", carrierSource = 0, netId = 0 },
  }
  gameTime = gameTime + 2000
  client:HandlePackages(view, config.Routes[1])
  assertEqual(#requests, 2, "hidden package could not be retrieved from rear marker")
  assertEqual(requests[2].action, "lift")
  assertEqual(requests[2].packageIndex, 1)
  assertTrue(helpText:find("Lấy kiện khỏi xe", 1, true) ~= nil)
  client:HandlePackages(view, config.Routes[1])
  assertEqual(#requests, 2, "rapid duplicate interaction was not throttled")
  gameTime = gameTime + 2000
  client.requestPending = true
  client:HandlePackages(view, config.Routes[1])
  assertEqual(#requests, 2, "pending request allowed another interaction")
  client.requestPending = false
  setCoords(forklift, v3(rear.x + 3.01, rear.y, rear.z))
  client:HandlePackages(view, config.Routes[1])
  assertEqual(#requests, 2, "client allowed interaction outside the rear radius")
end

-- Marker orientation must use the same target heading as both parking validators.
local parkingSession = newSession(1)
local parkingClient = LRTruckerClient.Mission:New({
  snapshot = {}, advance = function() end, packageAction = function() end,
})
local parkingTrailer = parkingSession.vehicles.trailer
for _, heading in ipairs({ 0, 90, 180, 270, 359, 250.5054 }) do
  local target = v4(50, 60, 7, heading)
  for _, case in ipairs({
    { delta = 0, accepted = true },
    { delta = 19.9, accepted = true },
    { delta = -19.9, accepted = true },
    { delta = 20.1, accepted = false },
    { delta = 90, accepted = false },
    { delta = 180, accepted = true },
    { delta = 270, accepted = false },
  }) do
    setCoords(parkingTrailer, v4(target.x, target.y, target.z, (heading + case.delta) % 360))
    parkingLines = {}
    local clientAccepted = parkingClient:TrailerParked(parkingTrailer, target)
    assertEqual(clientAccepted, case.accepted, "client parking heading check changed")
    assertEqual(parkingSession:IsParkedAt(parkingTrailer, target), clientAccepted,
      "client and server disagree on parking alignment")
    assertEqual(markerArgs[1], 28, "parking center marker type changed")
    assertNear(markerArgs[2], target.x, "parking marker center x differs from validation target")
    assertNear(markerArgs[3], target.y, "parking marker center y differs from validation target")
    assertNear(markerArgs[4], target.z + 0.12, "parking marker center z is below the road")
    assertEqual(#parkingLines, 4, "parking outline is incomplete")
    local radians = math.rad(target.w)
    local expectedRearLeftX = target.x - 1.4 * math.cos(radians) + 4.0 * math.sin(radians)
    local expectedRearLeftY = target.y - 1.4 * math.sin(radians) - 4.0 * math.cos(radians)
    assertNear(parkingLines[1][1], expectedRearLeftX,
      "parking outline x does not follow the configured heading")
    assertNear(parkingLines[1][2], expectedRearLeftY,
      "parking outline y does not follow the configured heading")
    assertNear(parkingLines[1][3], target.z + 0.08,
      "parking outline z is below the road")
  end
  setCoords(parkingTrailer, v4(target.x + 10.1, target.y, target.z, heading))
  assertFalse(parkingClient:TrailerParked(parkingTrailer, target), "distant trailer accepted by client")
  assertFalse(parkingSession:IsParkedAt(parkingTrailer, target), "distant trailer accepted by server")
end
assertTrue(parkingSession:Cancel())

config.Routes[2] = {
  delivery = {
    parking = v4(88, 90, 0, 180), packages = v3(89, 90, 1),
    forklifts = { v4(89, 90, 0, 180) },
  },
}
local randomRouteSession = newSession(1, nil, nil, nil, { deliveryRouteIndex = 2 })
assertEqual(randomRouteSession.route.pickup.parking.x, 10,
  "random destination changed the category pickup")
assertEqual(randomRouteSession.route.delivery.parking.x, 88,
  "mission ignored the independently selected delivery site")
assertEqual(randomRouteSession:Serialize().deliveryRouteIndex, 2)
assertTrue(randomRouteSession:Cancel())

print("trucker_mission_session_spec: ok")
