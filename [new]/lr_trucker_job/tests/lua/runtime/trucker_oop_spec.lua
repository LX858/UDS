local function assertTrue(value, message)
  if value ~= true then error(message or "expected true") end
end

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

LR = {}
dofile("shared/core/lr.lua")
dofile("shared/core/class.lua")

function vector3(x, y, z) return { x = x, y = y, z = z } end
function vector4(x, y, z, w) return { x = x, y = y, z = z, w = w } end
vec4 = vector4
function SetLocale(locale) return locale end
dofile("config.lua")
Config.Routes = { Config.Routes[1] }
Config.Routes[1].pickup.parking = vector4(0, 0, 0, 0)
Config.Routes[1].delivery.parking = vector4(2000, 0, 0, 0)

local orangeStock, holds = 250, {}
local integration = {
  GetCatalog = function()
    return {{ itemName = "orange", label = "Cam sạch", category = "traicay", price = 50, availableAmount = orangeStock }}
  end,
  ReserveLine = function(_, id, itemId, quantity)
    assertEqual(itemId, "orange")
    if orangeStock < quantity then return false, "STOCK_UNAVAILABLE" end
    holds[id], orangeStock = quantity, orangeStock - quantity
    return true, ""
  end,
  SettleLine = function(_, id, delivered)
    local quantity = holds[id]
    if not quantity then return false end
    holds[id] = nil
    if not delivered then orangeStock = orangeStock + quantity end
    return true, ""
  end,
}

dofile("server/classes/trucker/order_board.lua")
dofile("server/classes/trucker/team.lua")
dofile("server/classes/trucker/mission_session.lua")
local paymentRows = {}
local paymentDb = {}
local function paymentKey(missionId, citizenId, kind)
  return missionId .. ":" .. citizenId .. ":" .. kind
end
function paymentDb.EnsurePayment(missionId, citizenId, kind, amount)
  if amount == 0 then return "paid" end
  local key = paymentKey(missionId, citizenId, kind)
  local row = paymentRows[key]
  if not row then
    row = { amount = amount, status = "pending" }
    paymentRows[key] = row
  end
  return row.amount == amount and row.status or nil
end
function paymentDb.PreparePayment(missionId, citizenId, kind, amount)
  if amount == 0 then return "paid" end
  local key = paymentKey(missionId, citizenId, kind)
  local row = paymentRows[key]
  if not row then
    row = { amount = amount, status = "processing" }
    paymentRows[key] = row
  end
  if row.amount ~= amount or (row.status == "processing" and row.claimed_at) then return nil end
  return row.status == "processing" and "prepared" or row.status
end
function paymentDb.ActivatePayment(missionId, citizenId, kind, amount)
  if amount == 0 then return true end
  local row = paymentRows[paymentKey(missionId, citizenId, kind)]
  if not row or row.amount ~= amount or row.claimed_at then return false end
  if row.status == "processing" then row.status = "pending" end
  return row.status == "pending" or row.status == "paid"
end
function paymentDb.ClaimPayment(missionId, citizenId, kind, amount)
  local row = paymentRows[paymentKey(missionId, citizenId, kind)]
  if not row or row.amount ~= amount or row.status ~= "pending" then return false end
  row.status = "processing"
  row.claimed_at = true
  return true
end
function paymentDb.CompletePayment(missionId, citizenId, kind, amount)
  local row = paymentRows[paymentKey(missionId, citizenId, kind)]
  if not row or row.amount ~= amount or row.status ~= "processing" then return false end
  row.status = "paid"
  return true
end
function paymentDb.ResetPayment(missionId, citizenId, kind, amount)
  local row = paymentRows[paymentKey(missionId, citizenId, kind)]
  if not row or row.amount ~= amount or row.status ~= "processing" then return false end
  row.status = "pending"
  row.claimed_at = nil
  return true
end
function paymentDb.ListPendingRentalCharges(citizenId)
  local pending = {}
  local suffix = ":" .. citizenId .. ":rental_overage"
  for key, row in pairs(paymentRows) do
    if key:sub(-#suffix) == suffix and row.status ~= "paid" then
      pending[#pending + 1] = { missionId = key:match("^(.-):"), amount = row.amount }
    end
  end
  return pending
end
function paymentDb.ListPendingRewards(citizenId)
  local pending = {}
  local suffix = ":" .. citizenId .. ":reward"
  for key, row in pairs(paymentRows) do
    if key:sub(-#suffix) == suffix and row.status == "pending" then
      pending[#pending + 1] = { missionId = key:match("^(.-):"), amount = row.amount }
    end
  end
  return pending
end
function paymentDb.AreMissionChargesPaid(missionId)
  for key, row in pairs(paymentRows) do
    if key:sub(1, #missionId + 1) == missionId .. ":"
      and key:sub(-15) == ":rental_overage" and row.status ~= "paid" then
      return false
    end
  end
  return true
end
function paymentDb.AreMissionRewardsPaid(missionId)
  local found = false
  for key, row in pairs(paymentRows) do
    if key:sub(1, #missionId + 1) == missionId .. ":" and key:sub(-7) == ":reward" then
      found = true
      if row.status ~= "paid" then return false end
    end
  end
  return found
end
LRTruckerServer.Database = paymentDb
dofile("server/services/trucker_service.lua")
dofile("client/classes/trucker/npc.lua")
dofile("client/classes/trucker/mission.lua")
dofile("client/services/trucker_service.lua")

local nextId = 0
local board = LRTruckerServer.OrderBoard:New({
  config = Config,
  integration = integration,
  nextId = function(prefix)
    nextId = nextId + 1
    return prefix .. nextId
  end,
})
local originalRandom = math.random
math.random = function(_, maximum) return maximum or 1 end
board:Refill()
math.random = originalRandom
assertEqual(#board:Serialize(), 1, "order board advertised more than source stock")
local order = board:Serialize()[1]
assertEqual(order.itemId, "orange", "order did not include its market item")
assertEqual(order.itemLabel, "Cam sạch", "source catalog label was not used")
assertEqual(order.logisticsUnits, 250)
assertEqual(order.packageAmount, 21)
assertEqual(order.reward, 33000)
assertTrue(board:ReserveRoute(1, "team1"), "route reservation failed")
assertTrue(board:IsRouteReserved(1), "route reservation was not stored")
assertTrue(not board:ReleaseRoute(1, "other-team"), "foreign team released the route")
assertTrue(board:IsRouteReserved(1), "foreign release removed route ownership")
assertTrue(board:ReleaseRoute(1, "team1"), "route owner could not release route")
assertTrue(not board:IsRouteReserved(1), "route reservation was not released")

local rawOrder = board:Find(order.id)
assertTrue(rawOrder ~= nil, "serialized order could not be found")
local muleLoad = {}
for key, value in pairs(rawOrder) do muleLoad[key] = value end
muleLoad.logisticsUnits = 50
muleLoad.packageAmount = 5
assertTrue(board:ReserveOrder(muleLoad, "team1"), "rental load reservation failed")
assertEqual(orangeStock, 200, "reservation did not hold only the selected rental capacity")
for _, pendingOffer in ipairs(board:Serialize()) do
  assertTrue(pendingOffer.availability ~= "available", "reserved route remained available")
end
assertTrue(board:SettleOrder(muleLoad, "team1", false), "cancelled order did not settle")
assertEqual(orangeStock, 250, "cancelled order did not return source stock")
board:TickMarket()
math.random = function(_, maximum) return maximum or 1 end
local freshOrder = board:Find(board:Serialize()[1].id)
math.random = originalRandom
assertTrue(board:ReserveOrder(freshOrder, "team1"), "returned stock could not be reserved")
assertTrue(board:SettleOrder(freshOrder, "team1", true), "delivered order did not settle")
assertEqual(orangeStock, 0, "delivered stock returned to the source")
board:TickMarket()
assertEqual(#board.orders, 0, "market refresh created offers without source stock")

local team = LRTruckerServer.Team:New({
  id = "team1",
  player = { source = 1, citizenId = "citizen1", name = "Driver", xp = 0, level = 1 },
})
assertEqual(#team:OnlineMembers(), 1, "mission owner was not the sole member")
team:MarkOffline(1)
assertEqual(#team:OnlineMembers(), 0, "offline owner remained active")

assertTrue(type(LRTruckerServer.MissionSession.New) == "function", "server mission class is missing")
assertTrue(type(LRTruckerServer.TruckerService.New) == "function", "server service class is missing")
assertTrue(type(LRTruckerClient.NPC.New) == "function", "client NPC class is missing")
assertTrue(type(LRTruckerClient.Mission.New) == "function", "client mission class is missing")
assertTrue(type(LRTruckerClient.Service.New) == "function", "client service class is missing")

local serverContext = { services = { framework = {} }, logger = {} }
local clientContext = { services = {}, logger = {} }
local serverService = LRTruckerServer.TruckerService:New({ context = serverContext })
local clientService = LRTruckerClient.Service:New({ context = clientContext })
assertTrue(serverService.orderBoard:IsA(LRTruckerServer.OrderBoard), "server service did not compose order board")
assertTrue(clientService.npc:IsA(LRTruckerClient.NPC), "client service did not compose NPC")
assertTrue(clientService.mission:IsA(LRTruckerClient.Mission), "client service did not compose mission")

local marketMission = {
  id = "internal-market", kind = "market", itemId = "orange",
  itemLabel = "Cam sạch", destination = "Kho bí mật", routeIndex = 1,
  level = 1, logisticsUnits = 100, packageAmount = 9, reward = 18000,
  requiredVehicleTier = 0, cargoMode = "pallets", cargoCategory = "traicay", availability = "available",
}
local businessMission = {
  id = "internal-business", kind = "business", businessId = "secret_shop",
  businessLabel = "Nhà hàng bí mật", itemId = "conheo",
  destination = "Nhà hàng bí mật", level = 1, logisticsUnits = 120,
  packageAmount = 10, reward = 9000, requiredVehicleTier = 1,
  cargoMode = "pallets", availability = "available", canAccept = true,
  categoryKeys = { "nuoithu", "traicay" },
}
local originalSerialize = serverService.orderBoard.Serialize
local originalFind = serverService.orderBoard.Find
local originalBusinessList = serverService.businessOrderBoard.List
local originalBusinessFind = serverService.businessOrderBoard.Find
serverService.orderBoard.Serialize = function() return { marketMission } end
serverService.orderBoard.Find = function(_, id)
  if id == marketMission.id then return marketMission end
end
serverService.businessOrderBoard.List = function() return { businessMission }, 1 end
serverService.businessOrderBoard.Find = function(_, id)
  if id == businessMission.id then return businessMission end
end
local dispatchPage = serverService:GetOrderPage(nil, "all", 1, 20)
assertEqual(dispatchPage.total, 2, "business and market offers were not mixed")
assertTrue(dispatchPage.items[1].id ~= dispatchPage.items[2].id,
  "different orders shared a public token")
for _, offer in ipairs(dispatchPage.items) do
  assertTrue(offer.id:find("dispatch", 1, true) == 1, "public token exposed an internal ID")
  assertEqual(#offer.id, 41, "public token revealed the sequential internal counter")
  assertEqual(offer.kind, nil, "public offer exposed its source")
  assertEqual(offer.businessId, nil, "public offer exposed business identity")
  assertEqual(offer.itemId, nil, "public offer exposed its cargo")
  assertEqual(offer.destination, nil, "public offer exposed destination")
  assertEqual(offer.routeIndex, nil, "public offer exposed pickup coordinates")
  assertTrue(serverService:FindPublicOffer(offer.id) ~= nil, "public token did not resolve")
  assertTrue(type(offer.rentalRewards) == "table", "public offer omitted rental rewards")
  assertTrue(type(offer.categories) == "table" and #offer.categories > 0,
    "public offer omitted cargo categories")
  local resolved = serverService:FindPublicOffer(offer.id)
  if resolved.kind == "market" then
    assertEqual(offer.categories[1], "Nông Nghiệp", "market category label changed")
  else
    assertEqual(offer.categories[1], "Nuôi Thú", "business categories were not sorted")
    assertEqual(offer.categories[2], "Nông Nghiệp", "mixed business category was omitted")
  end
  assertEqual(offer.logisticsUnits, nil, "public offer exposed item count")
  assertEqual(offer.packageAmount, nil, "public offer exposed package count")
  for _, rental in ipairs(offer.rentalRewards) do
    assertEqual(rental.logisticsUnits, nil, "rental choice exposed item count")
    assertEqual(rental.packageAmount, nil, "rental choice exposed package count")
  end
end
local repeatedPage = serverService:GetOrderPage(nil, "all", 1, 20)
assertEqual(repeatedPage.items[1].id, dispatchPage.items[1].id, "pagination token changed")
serverService.orderBoard.Serialize = originalSerialize
serverService.orderBoard.Find = originalFind
serverService.businessOrderBoard.List = originalBusinessList
serverService.businessOrderBoard.Find = originalBusinessFind

local fleet = serverService:GetFleetSnapshot("")
assertEqual(#fleet.ownedVehicles, 0, "owned trucks appeared in rental-only fleet")
local expectedRentals = {
  mule = { 50, 5000 }, benson = { 100, 10000 }, pounder = { 150, 15000 },
  hauler = { 200, 20000 }, packer = { 200, 25000 }, phantom = { 250, 30000 },
}
assertEqual(#fleet.rentalOptions, 6, "fleet did not expose all six rentals")
for _, option in ipairs(fleet.rentalOptions) do
  local expected = assert(expectedRentals[option.key], "unexpected rental")
  assertEqual(option.capacity, nil, option.key .. " exposed capacity before acceptance")
  assertEqual(option.fee, expected[2], option.key .. " rental fee")
  assertEqual(option.rewardMultiplier, nil, "rental exposed internal reward multiplier")
  assertEqual(Config.Fleet.Rentals[option.key].capacity, expected[1], option.key .. " capacity")
  assertEqual(Config.Fleet.Rentals[option.key].rewardMultiplier, 100,
    "rental still reduces freight pay")
end
local heavyOrder = { logisticsUnits = 250, cargoMode = "pallets", requiredVehicleTier = 3 }
local mule = assert(serverService:ResolveRequestedVehicle("CID", { mode = "rental", key = "mule" }))
assertEqual(serverService:ResolveRequestedVehicle("CID", { mode = "owned", vehicleId = 1 }), nil,
  "owned truck request was accepted")
local phantom = assert(serverService:ResolveRequestedVehicle("CID", { mode = "rental", key = "phantom" }))
local hauler = assert(serverService:ResolveRequestedVehicle("CID", { mode = "rental", key = "hauler" }))
local packer = assert(serverService:ResolveRequestedVehicle("CID", { mode = "rental", key = "packer" }))
assertEqual(serverService:CanVehicleAccept(mule, heavyOrder), false, "Mule accepted 250 items")
local marketLoad = serverService:LoadForRental({
  kind = "market", logisticsUnits = 250, packageAmount = 21, reward = 33000,
}, mule)
assertEqual(marketLoad.logisticsUnits, 50, "Mule did not set the source quantity")
assertEqual(marketLoad.packageAmount, 5, "Mule package count did not follow its load")
assertEqual(marketLoad.reward, 13000, "Mule reward did not follow its load")
assertTrue(serverService:CanVehicleAccept(mule, marketLoad), "Mule cannot carry its own market load")
local thinStockLoad = serverService:LoadForRental({
  kind = "market", logisticsUnits = 40, packageAmount = 4, reward = 12000,
}, phantom)
assertEqual(thinStockLoad.logisticsUnits, 40, "rental load exceeded the offered stock")
assertEqual(thinStockLoad.packageAmount, 4, "thin stock package count changed")
local businessLoad = { kind = "business", logisticsUnits = 120, packageAmount = 10, reward = 9000 }
assertEqual(serverService:LoadForRental(businessLoad, phantom), businessLoad,
  "business order quantity changed with rental capacity")
assertTrue(serverService:CanVehicleAccept(phantom, heavyOrder), "Phantom rejected 250 items")
local oilOrder = { logisticsUnits = 200, cargoMode = "tanker", requiredVehicleTier = 3 }
assertEqual(serverService:CanVehicleAccept(hauler, oilOrder), false, "Hauler accepted raw oil")
assertTrue(serverService:CanVehicleAccept(packer, oilOrder), "Packer rejected raw oil")
assertEqual(Config.Fleet.Owned.tiers[1].capacity, 120)
assertEqual(Config.Fleet.Owned.tiers[2].capacity, 180)
assertEqual(Config.Fleet.Owned.tiers[3].capacity, 250)

local bodyHealth = 1000
function GetVehicleBodyHealth() return bodyHealth end
function DoesEntityExist() return true end
local paymentSession = {
  config = Config, startedAt = 1000, vehicleMode = "owned", vehicles = { truck = 1 },
  order = { kind = "market", logisticsUnits = 100, distanceKm = 2, reward = 18000 },
}
local paid, bankDue = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 1000)
assertEqual(paid, 18000, "NPC start bonus was not 3000")
assertEqual(bankDue, 0)
paid = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 1600)
assertEqual(paid, 17250, "NPC time bonus did not decline linearly")
paid = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 2200)
assertEqual(paid, 16500, "NPC deadline did not retain minimum bonus")
paid = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 2201)
assertEqual(paid, 15000, "late NPC delivery retained a time bonus")
bodyHealth = 500
paid = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 1000)
assertEqual(paid, 11500, "body damage reduced the fixed 5000 contract fee")

paymentSession.vehicleMode = "rental"
paymentSession.order = { kind = "business", logisticsUnits = 100, reward = 1000, rentalFee = 5000 }
paid, bankDue = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 4600)
assertEqual(paid, 1000, "rental overage started at exactly 60 minutes")
assertEqual(bankDue, 0)
paid = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 4601)
assertEqual(paid, 850, "first overtime minute was not 3 percent of rental fee")
paid = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 4661)
assertEqual(paid, 700, "second overtime minute did not round up")
paymentSession.order.reward = 100
paid, bankDue = LRTruckerServer.MissionSession.PaymentDue(paymentSession, 4601)
assertEqual(paid, 0, "overtime exceeded reward but payout remained positive")
assertEqual(bankDue, 50, "unpaid rental overage was not charged to bank")

local disconnectTeam = LRTruckerServer.Team:New({
  id = "disconnect-team",
  player = { source = 11, citizenId = "disconnect-1", name = "Host", xp = 0, level = 1 },
})
local cancelledSessions = 0
disconnectTeam.session = {
  ResetCarriedPackages = function() end,
  Cancel = function()
    cancelledSessions = cancelledSessions + 1
    return true
  end,
}
serverService.teams[disconnectTeam.id] = disconnectTeam
serverService.sourceTeams[11] = disconnectTeam.id
serverService.citizenTeams["disconnect-1"] = disconnectTeam.id
serverService:HandlePlayerUnloaded(11)
assertEqual(cancelledSessions, 1, "owner disconnect did not cancel the mission exactly once")
assertTrue(serverService.teams[disconnectTeam.id] == nil, "empty team survived the last-member disconnect")
assertTrue(serverService.citizenTeams["disconnect-1"] == nil, "first citizen index survived team cleanup")

local descriptors = {}
LR.Modules = {
  Register = function(_, descriptor) descriptors[#descriptors + 1] = descriptor end,
}
dofile("server/modules/trucker.lua")
dofile("client/modules/trucker.lua")
assertEqual(#descriptors, 2, "thin modules did not register both sides")
assertEqual(descriptors[1].id, "trucker")
assertEqual(descriptors[2].id, "trucker")
assertTrue(descriptors[1].create(serverContext):IsA(LRTruckerServer.TruckerService))
assertTrue(descriptors[2].create(clientContext):IsA(LRTruckerClient.Service))

local originalBusinessBoard = serverService.businessOrderBoard
local releasedOnFailure = 0
serverService.businessOrderBoard = {
  Deliver = function() return false end,
  Release = function() releasedOnFailure = releasedOnFailure + 1 return true end,
}
assertEqual(serverService:SettleOrder({ kind = "business" }, "team1", true), false,
  "failed delivery was treated as a successful cancellation")
assertEqual(releasedOnFailure, 0, "failed delivery released active reservations")
assertTrue(serverService:SettleOrder({ kind = "business" }, "team1", false))
assertEqual(releasedOnFailure, 1, "explicit cancellation did not release reservations")
serverService.businessOrderBoard = originalBusinessBoard

-- A committed payment is read from the ledger on replay. A processing row is
-- intentionally left for manual reconciliation if the transfer outcome is unknown.
local balances = { [1] = 200, [2] = 200 }
local rewards, charges = {}, {}
local failNextReward = false
serverService.context.logger.Error = function() end
serverService.framework = {
  GetPlayer = function(_, source)
    return { citizenId = source == 1 and "pay-1" or "pay-2", name = "Driver" }
  end,
  GetMoney = function(_, source) return balances[source] end,
  AddMoney = function(_, source, _, amount)
    if failNextReward then failNextReward = false return false end
    rewards[source] = (rewards[source] or 0) + amount
    return true
  end,
  RemoveMoney = function(_, source, _, amount)
    charges[source] = (charges[source] or 0) + amount
    balances[source] = balances[source] - amount
    return true
  end,
}
assertTrue(serverService:ProcessPayment("payment-one", "pay-1", "reward", 100, 1))
assertTrue(serverService:ProcessPayment("payment-one", "pay-1", "reward", 100, 1))
assertEqual(rewards[1], 100, "replayed payment paid twice")
paymentRows[paymentKey("uncertain", "pay-1", "reward")] = {
  amount = 75, status = "processing", claimed_at = true,
}
assertEqual(serverService:ProcessPayment("uncertain", "pay-1", "reward", 75, 1), false)
assertEqual(rewards[1], 100, "uncertain payment retried automatically")
failNextReward = true
assertEqual(serverService:ProcessPayment("retry", "pay-1", "reward", 50, 1), false)
assertEqual(paymentRows[paymentKey("retry", "pay-1", "reward")].status, "pending")
assertTrue(serverService:ProcessPayment("retry", "pay-1", "reward", 50, 1))
assertEqual(rewards[1], 150, "explicit transfer failure was not retried")

local payoutTeam = {
  OnlineMembers = function() return {
    { citizenId = "pay-1", source = 1 }, { citizenId = "pay-2", source = 2 },
  } end,
  FindMember = function(_, citizenId)
    if citizenId == "pay-1" then return { online = true, source = 1 } end
    if citizenId == "pay-2" then return { online = true, source = 2 } end
  end,
}
local payoutSession = { id = "team-payment", order = { vehicleOwnerCitizenId = "pay-1" }, team = payoutTeam }
assertTrue(serverService:PayMission(payoutSession, 101, 10))
assertTrue(serverService:PayMission(payoutSession, 101, 10))
assertEqual(rewards[1], 251, "solo driver did not receive the full wage exactly once")
assertEqual(rewards[2], nil, "other player received part of a solo wage")
assertEqual(charges[1], 10, "rental charge was applied twice")

local memberOnline = false
local deferredTeam = {
  OnlineMembers = payoutTeam.OnlineMembers,
  FindMember = function(_, citizenId)
    if citizenId == "pay-1" then return { online = true, source = 1 } end
    if citizenId == "pay-2" then return { online = memberOnline, source = 2 } end
  end,
}
local deferredSession = { id = "deferred-payment", order = { vehicleOwnerCitizenId = "pay-1" }, team = deferredTeam }
assertTrue(serverService:PayMission(deferredSession, 100, 0))
assertEqual(paymentRows[paymentKey("deferred-payment", "pay-2", "reward")], nil)
memberOnline = true
assertTrue(serverService:PayMission(deferredSession, 100, 0))
assertEqual(rewards[1], 351, "solo wage was paid more than once")
assertEqual(rewards[2], nil, "other player received a solo wage")

paymentDb.EnsurePayment("charge-first", "pay-1", "rental_overage", 500)
paymentDb.EnsurePayment("charge-first", "pay-1", "reward", 80)
paymentDb.EnsurePayment("charge-first", "pay-2", "reward", 80)
serverService.businessOrderBoard.MarkPaid = function() return true end
serverService:ProcessPendingPayments(1, { citizenId = "pay-1" })
serverService:ProcessPendingPayments(2, { citizenId = "pay-2" })
assertEqual(rewards[1], 351, "pending reward bypassed an unpaid rental charge")
assertEqual(rewards[2], nil, "legacy member bypassed owner's unpaid charge")
assertEqual(paymentRows[paymentKey("charge-first", "pay-1", "reward")].status, "pending")
balances[1] = 500
serverService:ProcessPendingPayments(1, { citizenId = "pay-1" })
serverService:ProcessPendingPayments(2, { citizenId = "pay-2" })
assertEqual(charges[1], 510, "pending charge was not collected once funds arrived")
assertEqual(rewards[1], 431, "reward did not resume after rental charge")
assertEqual(rewards[2], 80, "legacy member's reward did not resume after rental charge")
paymentRows[paymentKey("uncertain-charge", "pay-1", "rental_overage")] = {
  amount = 25, status = "processing", claimed_at = true,
}
paymentDb.EnsurePayment("uncertain-charge", "pay-1", "reward", 40)
serverService:ProcessPendingPayments(1, { citizenId = "pay-1" })
assertEqual(rewards[1], 431, "reward bypassed a charge needing reconciliation")
paymentRows[paymentKey("uncertain-charge", "pay-1", "rental_overage")].status = "paid"
serverService:ProcessPendingPayments(1, { citizenId = "pay-1" })
assertEqual(rewards[1], 471, "reconciled charge did not release pending reward")

local preparedSession = { id = "prepared-payment", order = { vehicleOwnerCitizenId = "pay-1" }, team = payoutTeam }
assertTrue(serverService:PrepareMission(preparedSession, 100, 0))
assertEqual(paymentRows[paymentKey("prepared-payment", "pay-1", "reward")].status, "processing")
assertEqual(rewards[1], 471, "preparing a wage transferred money before delivery")
preparedSession.payoutPrepared = true
assertTrue(serverService:PayMission(preparedSession, 100, 0))
assertEqual(rewards[1], 571, "prepared solo wage did not activate after delivery")
assertEqual(rewards[2], 80, "legacy member received a new solo wage")
local uncertainSession = { id = "uncertain", order = { vehicleOwnerCitizenId = "pay-1" }, team = {
  OnlineMembers = function() return {{ citizenId = "pay-1", source = 1 }} end,
  FindMember = payoutTeam.FindMember,
} }
uncertainSession.payoutPrepared = true
assertEqual(serverService:PayMission(uncertainSession, 75, 0), false,
  "uncertain transfer was reactivated without reconciliation")
assertEqual(rewards[1], 571)

local savedLease
paymentDb.GetRentalLease = function() return savedLease end
paymentDb.CreateRentalLease = function(citizenId, id, key, model, plate, fee, now, minutes)
  if not savedLease then
    savedLease = {
      citizenId = citizenId, id = id, key = key, model = model,
      plate = plate, fee = fee, startedAt = now, expiresAt = now + minutes * 60,
      assessedOverage = 0, status = "pending",
    }
  end
  return savedLease
end
paymentDb.ActivateRentalLease = function()
  savedLease.status = "active"
  return true
end
paymentDb.GetRentalDebt = function() return 0 end
paymentDb.CommitRentalAssessment = function() return true end
serverService.RentalTruck = function() return 999 end
balances[1] = 100000
local rentalChoice = { key = "mule", model = "mule", fee = 5000 }
local firstLease, firstTruck = serverService:AcquireRental(1, { citizenId = "pay-1" }, rentalChoice)
assertTrue(firstLease ~= nil, "first order could not acquire a lease")
assertEqual(firstTruck, 999)
local baseCharges = charges[1]
assertEqual(baseCharges, 5510, "first rental did not charge exactly one base fee")
local secondLease, secondTruck = serverService:AcquireRental(1, { citizenId = "pay-1" }, rentalChoice)
assertEqual(secondLease.id, firstLease.id, "second order created a new lease")
assertEqual(secondTruck, firstTruck, "second order did not reuse the truck")
assertEqual(charges[1], baseCharges, "second order charged another rental fee")
savedLease.status = "pending"
local resumedLease = serverService:ResumePendingRental(1, { citizenId = "pay-1" }, savedLease)
assertEqual(resumedLease.status, "active", "paid pending rental did not resume")
assertEqual(charges[1], baseCharges, "resuming paid rental charged a second base fee")
assertEqual(serverService:AcquireRental(1, { citizenId = "pay-1" },
  { key = "benson", model = "benson", fee = 10000 }), nil,
  "owner changed rental model without returning the old truck")
balances[1] = 0
local overdueSession = {
  id = "lease-overage", order = { vehicleOwnerCitizenId = "pay-1", rentalId = firstLease.id },
  team = payoutTeam, payoutPrepared = false,
}
assertTrue(serverService:PayMission(overdueSession, 0, 50),
  "unpaid overage prevented cargo settlement")
assertEqual(paymentRows[paymentKey("lease-overage", "pay-1", "rental_overage")].status,
  "pending", "unpaid overage was not recorded")
assertTrue(overdueSession.rentalDebtPending == true, "mission did not flag unpaid overage")

local removedRentalOwner
serverService.rentalSources[77] = "pay-1"
serverService.framework.GetPlayer = nil
serverService.RemoveRentalTruck = function(_, citizenId) removedRentalOwner = citizenId end
serverService:HandlePlayerUnloaded(77)
assertEqual(removedRentalOwner, "pay-1",
  "disconnect after framework unload left the rental entity behind")
assertEqual(serverService.rentalSources[77], nil,
  "disconnect kept a stale source-to-rental mapping")

local stopCleanups = 0
serverService.teams = { shutdown = { session = {
  order = { vehicleMode = "owned" },
  CleanupEntities = function() stopCleanups = stopCleanups + 1 end,
  Cancel = function() error("resource Stop called a foreign SQL settlement export") end,
} } }
serverService:Stop()
assertEqual(stopCleanups, 1, "resource Stop did not clean mission entities")

print("trucker_oop_spec: ok")
