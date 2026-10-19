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

Config = {
  Market = {
    Items = { cargo = { label = "Old market value", category = "phelieu", price = 1 } },
    UnitsPerPackage = 12,
    MaxOrderUnits = 250,
    NpcContractFee = 5000,
    NpcPayPerUnit = 100,
    NpcTimeBonusMax = 3000,
  },
  Fleet = { CategoryTier = { phelieu = 0 } },
  Routes = {{
    itemId = "cargo", destination = "Test depot", xp = 100,
    pickup = { parking = { x = 0, y = 0, z = 0 } },
    delivery = { parking = { x = 3000, y = 0, z = 0 } },
  }},
}

local stock, sourceOnline = 250, true
local holds, reserveCalls, failReserve = {}, 0, false
local integration = {
  GetCatalog = function()
    if not sourceOnline then return nil end
    return {{ itemName = "cargo", label = "Hàng sạch", category = "phelieu", price = 600, availableAmount = stock }}
  end,
  ReserveLine = function(_, id, itemId, quantity)
    reserveCalls = reserveCalls + 1
    assertEqual(itemId, "cargo")
    assertEqual(quantity, 250, "reservation did not use item count")
    if failReserve or stock < quantity then return false, "STOCK_UNAVAILABLE" end
    if holds[id] then return holds[id] == "pending", "ALREADY_SETTLED" end
    holds[id] = "pending"
    stock = stock - quantity
    return true, ""
  end,
  SettleLine = function(_, id, delivered)
    if holds[id] ~= "pending" then return false, "RESERVATION_NOT_FOUND" end
    holds[id] = delivered and "delivered" or "cancelled"
    if not delivered then stock = stock + 250 end
    return true, ""
  end,
}

dofile("server/classes/trucker/order_board.lua")
local sequence = 0
local board = LRTruckerServer.OrderBoard:New({
  config = Config,
  integration = integration,
  nextId = function(prefix)
    sequence = sequence + 1
    return prefix .. sequence
  end,
})

-- Pick the upper bound so 250 items must occupy exactly 21 packages.
local originalRandom = math.random
math.random = function(_, maximum) return maximum or 1 end
board:Refill()
math.random = originalRandom

local listed = board:Serialize()
assertEqual(#listed, 1, "board advertised the same stock ten times")
for _, order in ipairs(listed) do
  assertEqual(order.itemId, "cargo")
  assertEqual(order.itemLabel, "Hàng sạch", "NPC offer ignored source catalog label")
  assertEqual(order.packagePrice, 600, "NPC offer ignored source price")
  assertEqual(order.logisticsUnits, 250)
  assertEqual(order.packageAmount, 21, "250 items require 21 packages of 12")
  assertEqual(order.reward, 33000, "NPC preview did not include fee, units and maximum time bonus")
  assertEqual(order.availability, "available")
end
assertEqual(board.orders[1].distanceKm, 3, "deadline distance must use pickup-to-delivery points")

local order = board.orders[1]
failReserve = true
local ok, reason = board:ReserveOrder(order, "team-1")
assertEqual(ok, false, "source rejected stock but NPC order was accepted")
assertEqual(reason, "STOCK_UNAVAILABLE")
assertEqual(board:IsRouteReserved(order.routeIndex), false, "failed hold kept route locked")
failReserve = false
assertTrue(board:ReserveOrder(order, "team-1"), "NPC stock reservation failed")
assertEqual(stock, 0, "reservation did not hold source stock")
assertEqual(#board:Serialize(), 0, "reserved stock remained advertised")
local callsBeforeConflict = reserveCalls
ok, reason = board:ReserveOrder(order, "team-2")
assertEqual(ok, false, "competing team accepted an active NPC order")
assertEqual(reason, "ORDER_RESERVED")
assertEqual(reserveCalls, callsBeforeConflict, "competing team touched source stock")
assertEqual(board:SettleOrder(order, "team-2", false), false, "foreign team released stock")
assertTrue(board:SettleOrder(order, "team-1", false), "cancellation did not release source stock")
assertEqual(stock, 250, "cancel did not restore source stock")
math.random = function(_, maximum) return maximum or 1 end
local returnedOffer = board:Serialize()[1]
math.random = originalRandom
assertEqual(returnedOffer.availability, "available")

-- xn-sellitem cannot reopen a cancelled reservation ID. The offer needs a new attempt ID.
local freshOffer = board:Find(returnedOffer.id)
assertTrue(board:ReserveOrder(freshOffer, "team-1"), "returned stock could not be reserved")
assertEqual(stock, 0)
assertTrue(board:SettleOrder(freshOffer, "team-1", true), "delivery did not settle source stock")
assertEqual(stock, 0, "delivery returned consumed source stock")
assertEqual(#board:Serialize(), 0, "delivered stock remained advertised")

sourceOnline = false
assertEqual(#board:Serialize(), 0)
board:TickMarket()
assertEqual(#board.orders, 0, "offline source created synthetic NPC orders")
sourceOnline, stock = true, 40
assertEqual(#board:Serialize(), 1, "board did not recover when source stock returned")
assertEqual(board.orders[1].logisticsUnits, 40)

-- Dispatch offers cover stocked categories and only advertise stock once.
local routes = {}
for index = 1, 6 do
  routes[index] = {
    itemId = index == 1 and "scrap" or index == 2 and "ore" or "scrap",
    destination = "Depot " .. index, xp = 100,
    pickup = { parking = { x = index * 100, y = 0, z = 0 } },
    delivery = { parking = { x = index * 1000, y = 100, z = 0 } },
  }
end
local dispatchConfig = {
  Market = {
    Items = { scrap = { category = "phelieu" }, ore = { category = "mining" } },
    UnitsPerPackage = 12, MaxOrderUnits = 250,
    NpcContractFee = 5000, NpcPayPerUnit = 100, NpcTimeBonusMax = 3000,
  },
  Fleet = { CategoryTier = { phelieu = 0, mining = 3 } },
  Routes = routes,
}
local dispatchCatalog = {
  { itemName = "scrap", label = "Phế liệu", category = "phelieu", price = 100, availableAmount = 600 },
  { itemName = "ore", label = "Quặng", category = "mining", price = 200, availableAmount = 50 },
  { itemName = "rare", label = "Khoáng hiếm", category = "mining", price = 300, availableAmount = 1 },
}
local dispatchIntegration = {
  GetCatalog = function() return dispatchCatalog end,
  ReserveLine = function() return true, "" end,
  SettleLine = function() return true end,
}
local dispatchBoard = LRTruckerServer.OrderBoard:New({
  config = dispatchConfig, integration = dispatchIntegration,
  nextId = function(prefix) sequence = sequence + 1; return prefix .. sequence end,
})
math.random = function(_, maximum) return maximum or 1 end
dispatchBoard:Refill()
math.random = originalRandom
local advertised, categories = {}, {}
for _, offer in ipairs(dispatchBoard.orders) do
  advertised[offer.itemId] = (advertised[offer.itemId] or 0) + offer.logisticsUnits
  categories[offer.cargoCategory] = true
  assertTrue(offer.deliveryRouteIndex >= 1 and offer.deliveryRouteIndex <= 6)
  assertTrue(offer.packageAmount <= 21)
end
assertTrue(categories.phelieu and categories.mining, "stocked category was omitted")
for _, item in ipairs(dispatchCatalog) do
  assertTrue((advertised[item.itemName] or 0) <= item.availableAmount,
    "dispatch board advertised more than available stock")
end
assertEqual(dispatchBoard.orders[1].deliveryRouteIndex, 6,
  "destination did not draw from the full six-site pool")
local first = dispatchBoard.orders[1]
assertTrue(dispatchBoard:ReserveOrder(first, "dispatch-team"))
assertEqual(dispatchBoard.activeDestinations[6], "dispatch-team")
assertTrue(dispatchBoard:SettleOrder(first, "dispatch-team", false))
assertEqual(dispatchBoard.activeDestinations[6], nil)

-- A stocked item should win more draws than a thinly stocked item in its category.
dispatchCatalog[2].availableAmount = 1000
dispatchCatalog[3].availableAmount = 10
dispatchBoard:RefreshCatalog()
local weightedRemaining = { ore = 1000, rare = 10 }
local common = 0
for _ = 1, 250 do
  local offer = dispatchBoard:CreateOrder(weightedRemaining, "mining")
  if offer.itemId == "ore" then common = common + 1 end
end
assertTrue(common > 200, "high-stock item was not preferred within its category")

print("trucker_economy_spec: ok")
