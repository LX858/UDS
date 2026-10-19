local function assertTrue(value, message)
  if value ~= true then error(message or "expected true") end
end

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. (": expected %s, got %s"):format(tostring(expected), tostring(actual)))
  end
end

function vector3(x, y, z) return { x = x, y = y, z = z } end
function vector4(x, y, z, w) return { x = x, y = y, z = z, w = w } end
function GetPlayerPed() return 1 end
function DoesEntityExist() return true end
function GetEntityCoords() return vector3(0, 0, 0) end

LR = {}
dofile("shared/core/lr.lua")
dofile("shared/core/class.lua")
dofile("shared/core/schema.lua")
dofile("client/generated/contracts/trucker.lua")
local snapshot = LR.Generated.Contracts.trucker.nui.state.snapshot.default
dofile("server/generated/contracts/trucker.lua")
local contract = LR.Generated.Contracts.trucker

local savedOrder
local receipts, imports = {}, {}
local capacity, failImport = true, false
local failReceipt, failSettle = false, false
local transitions = {}
LRTruckerServer = {
  Database = {
    CreateBusinessOrder = function(order)
      savedOrder = order
      savedOrder.version, savedOrder.teamId = 1, ""
      return true
    end,
    ListBusinessHistory = function() return savedOrder and { savedOrder } or {} end,
    ListBusinessOrders = function() return savedOrder and { savedOrder } or {}, savedOrder and 1 or 0 end,
    GetBusinessOrder = function() return savedOrder end,
    TransitionBusinessOrder = function(_, fromStatuses, status, fields)
      local allowed = false
      for _, from in ipairs(fromStatuses) do if savedOrder.status == from then allowed = true end end
      if not allowed then return false end
      transitions[#transitions + 1] = status
      savedOrder.status = status
      savedOrder.version = savedOrder.version + 1
      if fields and fields.team_id then savedOrder.teamId = fields.team_id end
      return true
    end,
    SetBusinessLineReservation = function(_, index, id, state)
      savedOrder.lines[index].reservationId = id
      savedOrder.lines[index].reservationState = state
      return true
    end,
    HasDeliveryReceipt = function(id) return receipts[id] == true end,
    CreateDeliveryReceipt = function(id)
      if failReceipt then return false end
      receipts[id] = true return true
    end,
  },
}

local failSecond = false
local failRelease = false
local rejectReason
local coconutStock = 0
local reservations, released = {}, {}
local holds = { ["business-test:1"] = "cancelled", ["business-test:2"] = "cancelled" }
local integration = {
  GetCatalog = function()
    return {
      { itemName = "coconut", label = "Dừa", category = "traicay", price = 100, availableAmount = coconutStock },
      { itemName = "luami", label = "Lúa mì", category = "traicay", price = 80, availableAmount = 10 },
    }
  end,
  GetSocietyBalance = function() return 100000 end,
  DebitSociety = function(_, _, amount) return amount == 308 end,
  RefundSociety = function() return true end,
  CanCarryStashBasket = function(_, _, lines)
    for _, line in ipairs(lines) do assertTrue(line.destinationItemId == 'dua_soche' or line.destinationItemId == 'gao') end
    return capacity
  end,
  HasStashDelivery = function(_, _, _, id) return imports[id] ~= nil end,
  CanCarryStash = function() return capacity end,
  AddStashItem = function(_, stash, item, amount, metadata)
    if failImport then return false end
    assertEqual(stash, 'restaurant_shop')
    assertEqual(imports[metadata.deliveryId], nil, 'duplicate inventory import')
    imports[metadata.deliveryId] = { item = item, amount = amount }
    return true
  end,
  ReserveLine = function(_, reservationId, itemId, quantity)
    assertTrue(itemId == 'coconut' or itemId == 'luami' or itemId == 'la_che' or itemId == 'dau_tho',
      'reserved output instead of source')
    assertTrue(quantity > 0)
    reservations[#reservations + 1] = reservationId
    if rejectReason ~= nil then return false, rejectReason end
    if failSecond and #reservations == 2 then return false, "STOCK_UNAVAILABLE" end
    -- Match xn-sellitem: a cancelled ID can never be reserved again.
    if holds[reservationId] then return holds[reservationId] == "pending", "" end
    holds[reservationId] = "pending"
    return true, ""
  end,
  SettleLine = function(_, reservationId, delivered)
    if failSettle and delivered then return false, 'SOURCE_UNAVAILABLE' end
    if failRelease then return false, "SOURCE_UNAVAILABLE" end
    if not holds[reservationId] then return false, "RESERVATION_NOT_FOUND" end
    local target = delivered and "delivered" or "cancelled"
    if holds[reservationId] ~= "pending" and holds[reservationId] ~= target then
      return false, "ALREADY_SETTLED"
    end
    holds[reservationId] = target
    released[#released + 1] = { id = reservationId, delivered = delivered }
    return true, ""
  end,
}

local config = {
  BusinessOrders = {
    MaxLines = 6,
    MaxPackages = 21,
    MaxUnits = 250,
    ActionDistance = 12,
    Fees = { percent = 10 },
    Pickup = { parking = vector4(0, 0, 0, 0) },
    Items = {
      coconut = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = "item", destinationItemId = 'dua_soche', destinationLabel = 'Dừa sơ chế' },
      luami = { unitsPerPackage = 12, destinationMultiplier = 1, destinationUnit = "item", destinationItemId = 'gao', destinationLabel = 'Gạo' },
    },
    Businesses = {
      restaurant_shop = {
        label = "Quán ăn", adapter = "stash", job = "quanan", stashId = "restaurant_shop",
        orderPoint = vector4(0, 0, 0, 0),
        delivery = { parking = vector4(1000, 0, 0, 0) },
        allowedItems = { coconut = true, luami = true },
      },
    },
  },
}

dofile("server/classes/trucker/business_order_board.lua")
local board = LRTruckerServer.BusinessOrderBoard:New({
  config = config,
  integration = integration,
  nextId = function() return "business-test" end,
  logger = { Warn = function() end },
})
local player = { citizenId = "CID1", job = { name = "quanan", onDuty = true } }

-- Validate the deployed item mappings, not only the complete test fixture.
SetLocale = function() return {} end
dofile("config.lua")
local deployedConfig = Config
for itemId, mapping in pairs(deployedConfig.BusinessOrders.Items) do
  assertTrue(type(mapping.unitsPerPackage) == "number" and mapping.unitsPerPackage >= 1,
    "missing unitsPerPackage for " .. itemId)
end
local deployedBoard = LRTruckerServer.BusinessOrderBoard:New({
  config = deployedConfig, integration = integration,
  nextId = function() return "deployed-test" end, logger = { Warn = function() end },
})
GetEntityCoords = function() return deployedConfig.BusinessOrders.Businesses.bar.orderPoint end
local context, contextError = deployedBoard:GetContext(1,
  { citizenId = "CID1", job = { name = "quannuoc", onDuty = true } }, "bar")
assertTrue(context ~= nil, contextError)
local previousBusiness = snapshot.business
snapshot.business = context
local validContext, contextDetail = contract.net.rpc.clientToServer.getBusinessContext.response({
  success = true, message = "Đã tải cổng đặt hàng", snapshot = snapshot,
})
assertTrue(validContext, contextDetail)
snapshot.business = previousBusiness
GetEntityCoords = function() return vector3(0, 0, 0) end

local created, message = board:Create(1, player, "restaurant_shop", {
  { itemId = "coconut", quantity = 2 },
  { itemId = "luami", quantity = 1 },
})
assertTrue(created, message)
assertEqual(savedOrder.status, "waiting_stock", "missing source stock must keep the order waiting")
assertEqual(savedOrder.packageAmount, 2, "package conversion changed")
assertEqual(savedOrder.goodsTotal, 280, "wholesale price was not locked")
assertEqual(savedOrder.deliveryFee, 28, "delivery fee must be 10 percent of locked goods total")
assertEqual(savedOrder.escrowTotal, 308, "business escrow must hold goods and driver fee")
assertEqual(savedOrder.lines[1].destinationItemId, 'dua_soche')
assertEqual(savedOrder.lines[2].destinationItemId, 'gao')
integration.IsBusinessEnabled = function() return false end
assertEqual(board:Create(1, player, 'restaurant_shop', {{ itemId = 'luami', quantity = 1 }}), false,
  'disabled business accepted a new order')
local disabledContext = board:GetContext(1, player, 'restaurant_shop')
assertTrue(disabledContext ~= nil, 'disabled business hid existing orders')
assertEqual(#disabledContext.catalog, 0, 'disabled business still offered a catalog')
assertEqual(#disabledContext.orders, 1, 'disabled business hid an existing order')
integration.IsBusinessEnabled = nil
capacity = false
assertEqual(board:Create(1, player, 'restaurant_shop', {{ itemId = 'luami', quantity = 1 }}), false)
capacity = true

-- Real database rows contain reservation fields that must not reach the NUI.
for index, line in ipairs(savedOrder.lines) do
  line.index = index
  line.reservationId = savedOrder.id .. ":" .. index
  line.reservationState = "pending"
end
local function assertPublicSnapshot()
  local items, total = board:List("business", 1, 20)
  local context, contextError = board:GetContext(1, player, "restaurant_shop")
  assertTrue(context ~= nil, contextError)
  local publicOffer = {
    id = "dispatch-test", level = items[1].level,
    categories = { "Nông Nghiệp" },
    reward = items[1].reward,
    rentalRewards = { {
      key = "mule", reward = items[1].reward,
    } },
    availability = items[1].availability,
    canAccept = items[1].canAccept,
    lockReason = "",
  }
  snapshot.orderPage = { filter = "all", page = 1, pageSize = 20, total = total, items = { publicOffer } }
  snapshot.business = context
  local valid, detail = contract.net.events.serverToClient.sync.validate({ snapshot = snapshot })
  assertTrue(valid, detail)
  valid, detail = contract.net.rpc.clientToServer.listOrderBoard.response(snapshot.orderPage)
  assertTrue(valid, detail)
  valid, detail = contract.net.rpc.clientToServer.createBusinessOrder.response({
    success = true, message = "Đã tạo đơn", snapshot = snapshot,
  })
  assertTrue(valid, detail)
  assertEqual(items[1].businessOrder, nil, "public order leaked database record")
  assertEqual(items[1].destinationCoords, nil, "public order leaked private destination")
  assertEqual(items[1].fuelLiters, nil, "public order leaked mission-only fuel amount")
  assertEqual(items[1].name, "Đơn giao doanh nghiệp", "public name identified the business")
  assertEqual(items[1].businessId, "", "public order leaked business ID")
  assertEqual(items[1].businessLabel, "", "public order leaked business name")
  assertEqual(items[1].itemId, "business", "public order leaked an identifying raw item")
  assertEqual(items[1].itemLabel, "Hàng doanh nghiệp", "public order leaked an identifying label")
  assertEqual(items[1].destination, "Tiết lộ sau khi nhận đơn", "public order leaked delivery target")
  assertEqual(items[1].distanceKm, 0, "public order leaked delivery distance")
  assertEqual(items[1].packagePrice, 0, "public order leaked goods value")
  assertEqual(#items[1].lines, 0, "public order leaked basket lines")
  assertEqual(items[1].reward, 28, "public order hid driver pay")
  assertEqual(items[1].categoryKeys[1], "traicay", "business category was lost")
  assertEqual(context.orders[1].businessLabel, "Quán ăn", "business staff lost their own order identity")
  assertEqual(context.orders[1].lines[1].reservationId, nil, "business context leaked source hold")
  assertTrue(context.orders[1].lines[1] ~= savedOrder.lines[1], "serializer aliased a database line")
  assertEqual(savedOrder.lines[1].reservationId, "business-test:1", "serialization mutated database record")
  publicOffer.logisticsUnits = 2
  valid = contract.net.events.serverToClient.sync.validate({ snapshot = snapshot })
  assertEqual(valid, false, "public offer contract accepted hidden item count")
  publicOffer.logisticsUnits = nil
  -- Confirm this is the strict transport validator, not a permissive test stub.
  publicOffer.businessOrder = savedOrder
  valid = contract.net.events.serverToClient.sync.validate({ snapshot = snapshot })
  assertEqual(valid, false, "transport accepted internal business data")
  publicOffer.businessOrder = nil
end
assertPublicSnapshot()
local mixed = {}
for key, value in pairs(savedOrder) do mixed[key] = value end
mixed.lines = {}
for index, line in ipairs(savedOrder.lines) do
  mixed.lines[index] = {}
  for key, value in pairs(line) do mixed.lines[index][key] = value end
end
mixed.lines[2].category = "nuoithu"
local categorized = board:Serialize(mixed, true, {
  coconut = { available = 10 }, luami = { available = 10 },
})
assertEqual(categorized.categoryKeys[1], "nuoithu", "mixed categories were not sorted")
assertEqual(categorized.categoryKeys[2], "traicay", "mixed category was omitted")
coconutStock = 10
assertPublicSnapshot()
local missionOrder = board:Find(savedOrder.id)
assertTrue(missionOrder ~= nil, "available business order not found")
assertEqual(missionOrder.businessId, "restaurant_shop", "accepted mission lost business identity")
assertEqual(missionOrder.businessLabel, "Quán ăn", "accepted mission lost destination name")
assertEqual(missionOrder.businessOrder, savedOrder, "mission lost its internal database record")
assertEqual(missionOrder.destinationCoords, savedOrder.destinationCoords, "mission lost its delivery location")

failSecond = true
local reserved, reserveError = board:Reserve(missionOrder, "team-1")
assertEqual(reserved, false, "partial reservation unexpectedly succeeded")
assertEqual(reserveError, "STOCK_UNAVAILABLE", "partial reservation returned wrong reason")
assertEqual(#released, 1, "partial reservation did not roll back the first line")
assertEqual(released[1].delivered, false, "rollback settled source stock as delivered")
assertEqual(transitions[#transitions], "waiting_stock", "failed reservation did not reopen order")

failSecond = false
local firstAttemptId = reservations[1]
assertTrue(firstAttemptId:find(":v2:1", 1, true) ~= nil, "reservation did not use the claimed database version")
assertEqual(holds[firstAttemptId], "cancelled")
local function acceptAgain()
  local found = board:Find(savedOrder.id)
  assertTrue(found ~= nil, "released order is no longer available")
  local ok, reason = board:Reserve(found, "team-1")
  assertTrue(ok, reason)
  assertEqual(savedOrder.status, "in_transit")
  for _, line in ipairs(savedOrder.lines) do
    assertEqual(holds[line.reservationId], "pending", "persisted ID differs from provider hold")
    assertTrue(#line.reservationId <= 64, "reservation ID exceeds provider limit")
  end
  return found
end
local accepted = acceptAgain()
local secondAttemptId = savedOrder.lines[1].reservationId
assertTrue(secondAttemptId ~= firstAttemptId, "partial rollback reused a cancelled ID")
local beforeConflict = #reservations
local duplicate, duplicateError = board:Reserve(accepted, "team-2")
assertEqual(duplicate, false)
assertEqual(duplicateError, "ORDER_RESERVED")
assertEqual(#reservations, beforeConflict, "competing team touched provider stock")
assertEqual(board:Release(accepted, "team-2"), false, "foreign team released reservation")
assertTrue(board:Release(accepted, "team-1"))
assertEqual(holds[secondAttemptId], "cancelled")
accepted = acceptAgain()
local restartAttemptId = savedOrder.lines[1].reservationId
assertTrue(restartAttemptId ~= secondAttemptId, "driver cancellation reused a hold")

-- Restart reconstructs recovery from persisted lines, without an in-memory mission.
local restarted = LRTruckerServer.BusinessOrderBoard:New({
  config = config, integration = integration,
  nextId = function() return "business-test" end,
  logger = { Warn = function() end },
})
failRelease = true
assertEqual(restarted:Recover(), 0, "recovery reopened an order before source rollback succeeded")
assertEqual(savedOrder.status, "in_transit")
assertEqual(holds[restartAttemptId], "pending")
failRelease = false
assertEqual(restarted:RetryPendingReleases(), 1)
assertEqual(holds[restartAttemptId], "cancelled")
assertEqual(restarted:RetryPendingReleases(), 0, "completed recovery remained queued")
board = restarted
accepted = acceptAgain()
assertTrue(savedOrder.lines[1].reservationId ~= restartAttemptId, "restart reused a cancelled hold")
assertTrue(board:Release(accepted, "team-1"))

-- A rejection is not a network outage; rollback itself must also be recoverable.
rejectReason = ""
local rejected, rejectedError = board:Reserve(board:Find(savedOrder.id), "team-1")
assertEqual(rejected, false)
assertEqual(rejectedError, "RESERVATION_REJECTED", "business rejection was mislabeled as source outage")
rejectReason = "STOCK_UNAVAILABLE"
failRelease = true
rejected, rejectedError = board:Reserve(board:Find(savedOrder.id), "team-1")
assertEqual(rejectedError, "RESERVATION_RELEASE_PENDING")
assertEqual(savedOrder.status, "reserving", "failed rollback unlocked the order")
failRelease = false
assertEqual(board:RetryPendingReleases(), 1)
rejectReason = nil

-- Simulate a crash after intent was saved but before the external hold was created.
assertTrue(LRTruckerServer.Database.TransitionBusinessOrder(savedOrder.id, { "waiting_stock" }, "reserving", { team_id = "team-1" }))
assertTrue(LRTruckerServer.Database.SetBusinessLineReservation(savedOrder.id, 1, "crash-intent", "reserved"))
assertEqual(board:Recover(), 1, "uncreated reservation intent prevented restart recovery")
accepted = acceptAgain()
local deliveryId = savedOrder.lines[1].reservationId
-- A stale in-memory record must not override persisted reservation IDs.
accepted.businessOrder = { id = savedOrder.id, lines = {{ reservationId = "business-test:1" }} }
config.BusinessOrders.Items.coconut.destinationMultiplier = 9
config.BusinessOrders.Items.coconut.destinationItemId = 'changed_config'
capacity = false
assertEqual(board:Deliver(accepted), false, 'full basket capacity not checked')
assertEqual(next(imports), nil, 'full stash partially imported')
capacity, failImport = true, true
assertEqual(board:Deliver(accepted), false, 'failed inventory import settled source')
assertEqual(holds[deliveryId], 'pending')
failImport = false
failReceipt = true
local originalAdd = integration.AddStashItem
integration.AddStashItem = function(...)
  assertEqual(board:Release(accepted, 'team-1'), false, 'cancel raced active import')
  assertEqual(board:Deliver(accepted), false, 'concurrent import bypassed lock')
  return originalAdd(...)
end
assertEqual(board:Deliver(accepted), false, 'failed receipt was ignored')
integration.AddStashItem = originalAdd
assertEqual(board:Release(accepted, 'team-1'), false, 'partial import returned raw stock')
failReceipt, failSettle = false, true
assertEqual(board:Deliver(accepted), false, 'failed source settlement ignored')
failSettle = false
assertTrue(board:Deliver(accepted), "delivery did not use persisted IDs from the latest attempt")
assertTrue(board:Deliver(accepted), 'repeated completion is not idempotent')
assertEqual(imports['business-test:stash:1'].item, 'dua_soche', 'config changed paid mapping')
assertEqual(imports['business-test:stash:1'].amount, 2, 'config changed paid amount')
assertEqual(imports['business-test:stash:2'].item, 'gao')
assertEqual(holds[deliveryId], "delivered")
assertEqual(holds["business-test:1"], "cancelled", "delivery changed a legacy reservation")
assertEqual(savedOrder.status, "delivered")

-- Both outputs in the drink shop, using persisted mappings after restart.
receipts, imports, holds = {}, {}, {}
integration.GetCatalog = function()
  return {
    { itemName = 'coconut', label = 'Dừa', price = 100, availableAmount = 10 },
    { itemName = 'la_che', label = 'Lá chè', price = 100, availableAmount = 10 },
  }
end
integration.DebitSociety = function() return true end
integration.CanCarryStashBasket = function(_, stash, lines)
  assertEqual(stash, 'bar')
  for _, line in ipairs(lines) do assertTrue(line.destinationItemId == 'dua_soche' or line.destinationItemId == 'tra_kho') end
  return true
end
integration.AddStashItem = function(_, stash, item, amount, metadata)
  assertEqual(stash, 'bar')
  assertEqual(imports[metadata.deliveryId], nil, 'restart duplicated import')
  imports[metadata.deliveryId] = { item = item, amount = amount }
  return true
end
config.BusinessOrders.Items.coconut.destinationItemId = 'dua_soche'
config.BusinessOrders.Items.coconut.destinationMultiplier = 1
config.BusinessOrders.Items.la_che = { unitsPerPackage = 4, destinationMultiplier = 1, destinationUnit = 'item', destinationItemId = 'tra_kho', destinationLabel = 'Trà khô' }
config.BusinessOrders.Businesses.bar = {
  label = 'Quán nước', adapter = 'stash', job = 'quannuoc', stashId = 'bar',
  orderPoint = vector4(0, 0, 0, 0), delivery = { parking = vector4(1000, 0, 0, 0) },
  allowedItems = { coconut = true, la_che = true },
}
player.job.name = 'quannuoc'
assertTrue(board:Create(1, player, 'bar', {{ itemId = 'coconut', quantity = 1 }, { itemId = 'la_che', quantity = 2 }}))
accepted = acceptAgain()
failReceipt = true
assertEqual(board:Deliver(accepted), false)
failReceipt = false
local recovery = LRTruckerServer.BusinessOrderBoard:New({
  config = config, integration = integration, nextId = function() return 'unused' end, logger = { Warn = function() end },
})
assertEqual(recovery:Recover(), 1, 'restart did not finish partial import')
assertEqual(savedOrder.status, 'delivered', 'partially imported order reopened')
assertEqual(imports['business-test:stash:1'].item, 'dua_soche')
assertEqual(imports['business-test:stash:2'].item, 'tra_kho')
assertEqual(imports['business-test:stash:2'].amount, 2)
assertEqual(recovery:RetryPendingReleases(), 0)

-- The 250-item ceiling still fits in 21 packages when each package holds 12.
integration.GetCatalog = function()
  return {{ itemName = 'coconut', label = 'Dừa', price = 100, availableAmount = 250 }}
end
player.job.name = 'quannuoc'
assertTrue(board:Create(1, player, 'bar', {{ itemId = 'coconut', quantity = 250 }}))
assertEqual(savedOrder.packageAmount, 21, '250 units did not fit in 21 packages')
assertEqual(savedOrder.goodsTotal, 25000)
assertEqual(savedOrder.deliveryFee, 2500, 'bulk fee was not 10 percent of goods')
assertEqual(savedOrder.escrowTotal, 27500)
assertEqual(board:Create(1, player, 'bar', {{ itemId = 'coconut', quantity = 251 }}), false,
  'business order exceeded the 250-unit limit')
config.BusinessOrders.MaxUnits = 300
assertEqual(board:Create(1, player, 'bar', {{ itemId = 'coconut', quantity = 253 }}), false,
  'business order exceeded the 21-package limit')
config.BusinessOrders.MaxUnits = 250

-- Raw oil is bought in item units and credited to the station in liters.
config.BusinessOrders.Items.dau_tho = {
  unitsPerPackage = 12, destinationMultiplier = 20, destinationUnit = 'liter',
  destinationItemId = '', destinationLabel = 'Nhiên liệu',
}
integration.GetCatalog = function()
  return {{ itemName = 'dau_tho', label = 'Dầu thô', price = 300, availableAmount = 10 }}
end
integration.GetFuelContext = function() return { label = 'Trạm xăng A', balance = 5000, fuel = 0, maxFuel = 10000 } end
integration.GetFuelStations = function()
  return {{ location = 1, label = 'Trạm xăng A', x = 0, y = 0, z = 0, h = 0 }}
end
local fuelDebit, fuelCredit
integration.DebitFuel = function(_, _, _, _, amount) fuelDebit = amount return true end
integration.RefundFuel = function() return true end
integration.CreditFuel = function(_, _, _, _, liters)
  if failImport then return false, 'STATION_CAPACITY' end
  assertEqual(fuelCredit, nil, 'duplicate fuel import')
  fuelCredit = liters
  return true, ''
end
local fuelBoard = LRTruckerServer.BusinessOrderBoard:New({
  config = config, integration = integration,
  nextId = function() return 'fuel-order' end,
  logger = { Warn = function() end },
})
assertTrue(fuelBoard:Create(1, player, 'gas_station_1', {{ itemId = 'dau_tho', quantity = 10 }}))
assertEqual(savedOrder.lines[1].destinationAmount, 200, '10 raw oil did not become 200 liters')
assertEqual(savedOrder.goodsTotal, 3000)
assertEqual(savedOrder.deliveryFee, 300)
assertEqual(savedOrder.escrowTotal, 3300)
assertEqual(fuelDebit, 3300, 'station escrow did not include goods and 10 percent fee')
assertEqual(savedOrder.cargoMode, 'tanker')
local fuelPublic = fuelBoard:List('business', 1, 20)
assertEqual(fuelPublic[1].businessLabel, '', 'public fuel offer identified the station')
assertEqual(#fuelPublic[1].lines, 0, 'public fuel offer exposed raw oil')
local fuelMission = assert(fuelBoard:Find(savedOrder.id))
assertEqual(fuelMission.fuelLiters, 200, 'accepted mission lost its fuel volume')
assertTrue(fuelBoard:Reserve(fuelMission, 'fuel-team'))
failImport = true
assertEqual(fuelBoard:Deliver(fuelMission), false, 'failed station import consumed source oil')
assertEqual(savedOrder.status, 'in_transit')
failImport = false
assertTrue(fuelBoard:Deliver(fuelMission), 'fuel delivery was not credited')
assertEqual(fuelCredit, 200)
assertEqual(savedOrder.status, 'delivered')
assertTrue(fuelBoard:Deliver(fuelMission), 'repeated fuel delivery was not idempotent')

print("trucker_business_order_spec: ok")
