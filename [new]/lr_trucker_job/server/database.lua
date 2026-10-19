---@diagnostic disable: undefined-global
LRTruckerServer = LRTruckerServer or {}

local Database = {}
local Sql = assert(LR.CreateDatabaseBridge)("oxmysql")

local function decodeProps(value)
  if type(value) == "table" then return value end
  if type(value) ~= "string" or value == "" then return {} end
  local ok, decoded = pcall(json.decode, value)
  return ok and type(decoded) == "table" and decoded or {}
end

local function normalizeVehicle(row)
  if not row then return nil end
  local state = math.max(0, math.min(2, math.floor(tonumber(row.state) or 0)))
  return {
    vehicleId = math.max(1, math.floor(tonumber(row.id) or 1)),
    model = string.lower(tostring(row.vehicle or "")),
    plate = tostring(row.plate or ""),
    garage = tostring(row.garage or ""),
    state = state,
    tier = math.max(1, math.min(3, math.floor(tonumber(row.tier) or 1))),
    props = decodeProps(row.mods),
  }
end

local function normalizeRental(row)
  if not row then return nil end
  return {
    id = tostring(row.rental_id or ""),
    fee = math.max(0, math.floor(tonumber(row.fee) or 0)),
  }
end

function Database.GetOwnedVehicles(citizenId)
  local rows = Sql:Query([[
    SELECT pv.id, pv.vehicle, pv.plate, pv.garage, pv.state, pv.mods,
      COALESCE(upgrade.tier, 1) AS tier
    FROM player_vehicles pv
    LEFT JOIN lr_trucker_vehicle_upgrades upgrade
      ON upgrade.player_vehicle_id = pv.id AND upgrade.citizen_id = pv.citizenid
    WHERE pv.citizenid = ? AND LOWER(pv.vehicle) IN ('phantom', 'phantom2')
    ORDER BY pv.state = 1 DESC, pv.vehicle ASC, pv.plate ASC
    LIMIT 32
  ]], { citizenId }) or {}
  local vehicles = {}
  for index = 1, #rows do vehicles[index] = normalizeVehicle(rows[index]) end
  return vehicles
end

function Database.GetOwnedVehicle(citizenId, vehicleId)
  return normalizeVehicle(Sql:Single([[
    SELECT pv.id, pv.vehicle, pv.plate, pv.garage, pv.state, pv.mods,
      COALESCE(upgrade.tier, 1) AS tier
    FROM player_vehicles pv
    LEFT JOIN lr_trucker_vehicle_upgrades upgrade
      ON upgrade.player_vehicle_id = pv.id AND upgrade.citizen_id = pv.citizenid
    WHERE pv.id = ? AND pv.citizenid = ?
      AND LOWER(pv.vehicle) IN ('phantom', 'phantom2')
    LIMIT 1
  ]], { vehicleId, citizenId }))
end

function Database.UpgradeOwnedVehicle(citizenId, vehicleId, expectedTier, nextTier)
  Sql:Update([[
    INSERT IGNORE INTO lr_trucker_vehicle_upgrades
      (player_vehicle_id, citizen_id, tier) VALUES (?, ?, 1)
  ]], { vehicleId, citizenId })
  local changed = Sql:Update([[
    UPDATE lr_trucker_vehicle_upgrades upgrade
    INNER JOIN player_vehicles pv ON pv.id = upgrade.player_vehicle_id
    SET upgrade.tier = ?
    WHERE upgrade.player_vehicle_id = ? AND upgrade.citizen_id = ?
      AND upgrade.tier = ? AND pv.citizenid = ? AND pv.state = 1
      AND LOWER(pv.vehicle) IN ('phantom', 'phantom2')
  ]], { nextTier, vehicleId, citizenId, expectedTier, citizenId })
  return tonumber(changed) == 1
end

function Database.CheckoutOwnedVehicle(citizenId, vehicleId, missionId)
  local transactionOk = Sql:Transaction({
    {
      query = [[
        INSERT INTO lr_trucker_active_vehicles
          (player_vehicle_id, citizen_id, mission_id, original_garage)
        SELECT id, citizenid, ?, COALESCE(garage, '')
        FROM player_vehicles
        WHERE id = ? AND citizenid = ? AND state = 1
          AND LOWER(vehicle) IN ('phantom', 'phantom2')
      ]],
      values = { missionId, vehicleId, citizenId },
    },
    {
      query = [[
        UPDATE player_vehicles pv
        INNER JOIN lr_trucker_active_vehicles active
          ON active.player_vehicle_id = pv.id AND active.mission_id = ?
        SET pv.state = 0
        WHERE pv.id = ? AND pv.citizenid = ? AND pv.state = 1
      ]],
      values = { missionId, vehicleId, citizenId },
    },
  })
  if not transactionOk then return nil end
  local checkout = Sql:Single([[
    SELECT active.original_garage
    FROM lr_trucker_active_vehicles active
    INNER JOIN player_vehicles pv ON pv.id = active.player_vehicle_id
    WHERE active.player_vehicle_id = ? AND active.citizen_id = ?
      AND active.mission_id = ? AND pv.state = 0
    LIMIT 1
  ]], { vehicleId, citizenId, missionId })
  if not checkout then return nil end
  local vehicle = Database.GetOwnedVehicle(citizenId, vehicleId)
  if not vehicle then return nil end
  vehicle.originalGarage = tostring(checkout.original_garage or "")
  return vehicle
end

function Database.ReturnOwnedVehicle(citizenId, vehicleId, missionId, props)
  local active = Sql:Single([[
    SELECT original_garage FROM lr_trucker_active_vehicles
    WHERE player_vehicle_id = ? AND citizen_id = ? AND mission_id = ? LIMIT 1
  ]], { vehicleId, citizenId, missionId })
  if not active then return true end
  local encodedProps = type(props) == "table" and json.encode(props) or nil
  local changed
  if encodedProps then
    changed = Sql:Update([[
      UPDATE player_vehicles SET state = 1, garage = ?, mods = ?
      WHERE id = ? AND citizenid = ? AND state = 0
    ]], { tostring(active.original_garage or ""), encodedProps, vehicleId, citizenId })
  else
    changed = Sql:Update([[
      UPDATE player_vehicles SET state = 1, garage = ?
      WHERE id = ? AND citizenid = ? AND state = 0
    ]], { tostring(active.original_garage or ""), vehicleId, citizenId })
  end
  if tonumber(changed) ~= 1 then
    local restored = Sql:Single([[
      SELECT id FROM player_vehicles
      WHERE id = ? AND citizenid = ? AND state = 1 LIMIT 1
    ]], { vehicleId, citizenId })
    if not restored then return false end
  end
  Sql:Update([[
    DELETE FROM lr_trucker_active_vehicles
    WHERE player_vehicle_id = ? AND citizen_id = ? AND mission_id = ?
  ]], { vehicleId, citizenId, missionId })
  return true
end

function Database.RecoverStaleCheckouts()
  local restored = Sql:Update([[
    UPDATE player_vehicles pv
    INNER JOIN lr_trucker_active_vehicles active ON active.player_vehicle_id = pv.id
    SET pv.state = 1, pv.garage = active.original_garage
    WHERE pv.citizenid = active.citizen_id
  ]])
  Sql:Update('DELETE FROM lr_trucker_active_vehicles')
  return math.max(0, math.floor(tonumber(restored) or 0))
end

function Database.RecoverRefundClaims()
  return math.max(0, math.floor(tonumber(Sql:Update([[
    UPDATE lr_trucker_rental_refunds SET claimed_at = NULL
    WHERE paid_at IS NULL AND claimed_at IS NOT NULL
  ]])) or 0))
end

function Database.QueueRentalRefund(refundId, citizenId, amount)
  local queued = Sql:Update([[
    INSERT IGNORE INTO lr_trucker_rental_refunds
      (rental_id, citizen_id, amount) VALUES (?, ?, ?)
  ]], { refundId, citizenId, math.max(0, math.floor(tonumber(amount) or 0)) })
  return tonumber(queued) == 1 or tonumber(queued) == 0
end

function Database.ClaimLegacyRentalRefund(citizenId, now)
  now = tonumber(now) or os.time()
  local rental = normalizeRental(Sql:Single([[
    SELECT rental_id, fee FROM lr_trucker_rentals
    WHERE citizen_id = ? AND expires_at > ? LIMIT 1
  ]], { citizenId, now }))
  if rental then
    Sql:Update([[
      INSERT IGNORE INTO lr_trucker_rental_refunds
        (rental_id, citizen_id, amount) VALUES (?, ?, ?)
    ]], { rental.id, citizenId, rental.fee })
  end
  Sql:Update('DELETE FROM lr_trucker_rentals WHERE citizen_id = ?', { citizenId })
  local pending = Sql:Single([[
    SELECT rental_id, amount FROM lr_trucker_rental_refunds
    WHERE citizen_id = ? AND paid_at IS NULL AND claimed_at IS NULL
    ORDER BY created_at ASC LIMIT 1
  ]], { citizenId })
  if not pending then return nil end
  local claimed = Sql:Update([[
    UPDATE lr_trucker_rental_refunds SET claimed_at = CURRENT_TIMESTAMP
    WHERE rental_id = ? AND paid_at IS NULL AND claimed_at IS NULL
  ]], { pending.rental_id })
  if tonumber(claimed) ~= 1 then return nil end
  return {
    id = tostring(pending.rental_id),
    amount = math.max(0, math.floor(tonumber(pending.amount) or 0)),
  }
end

function Database.CompleteLegacyRentalRefund(rentalId, paid)
  if paid then
    Sql:Update([[
      UPDATE lr_trucker_rental_refunds SET paid_at = CURRENT_TIMESTAMP
      WHERE rental_id = ? AND paid_at IS NULL
    ]], { rentalId })
  else
    Sql:Update([[
      UPDATE lr_trucker_rental_refunds SET claimed_at = NULL
      WHERE rental_id = ? AND paid_at IS NULL
    ]], { rentalId })
  end
end

local function normalizeLease(row)
  if not row then return nil end
  return {
    citizenId = tostring(row.citizen_id or ""),
    id = tostring(row.rental_id or ""),
    key = tostring(row.rental_key or ""),
    model = tostring(row.model or ""),
    plate = tostring(row.plate or ""),
    fee = math.max(0, math.floor(tonumber(row.fee) or 0)),
    startedAt = math.max(0, math.floor(tonumber(row.started_at) or 0)),
    expiresAt = math.max(0, math.floor(tonumber(row.expires_at) or 0)),
    assessedOverage = math.max(0, math.floor(tonumber(row.assessed_overage) or 0)),
    status = tostring(row.status or "pending"),
  }
end

function Database.GetRentalLease(citizenId)
  return normalizeLease(Sql:Single([[
    SELECT * FROM lr_trucker_rental_leases WHERE citizen_id = ? LIMIT 1
  ]], { citizenId }))
end

function Database.CreateRentalLease(citizenId, rentalId, key, model, plate, fee, now, minutes)
  Sql:Update([[
    INSERT IGNORE INTO lr_trucker_rental_leases
      (citizen_id, rental_id, rental_key, model, plate, fee, started_at, expires_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ]], { citizenId, rentalId, key, model, plate, fee, now, now + minutes * 60 })
  return Database.GetRentalLease(citizenId)
end

function Database.ActivateRentalLease(citizenId, rentalId, now, minutes)
  local changed = Sql:Update([[
    UPDATE lr_trucker_rental_leases
    SET status = 'active', started_at = ?, expires_at = ?
    WHERE citizen_id = ? AND rental_id = ? AND status = 'pending'
  ]], { now, now + minutes * 60, citizenId, rentalId })
  if tonumber(changed) == 1 then return true end
  local lease = Database.GetRentalLease(citizenId)
  return lease ~= nil and lease.id == rentalId and lease.status == "active"
end

function Database.MarkRentalReturning(citizenId, rentalId)
  local changed = Sql:Update([[
    UPDATE lr_trucker_rental_leases SET status = 'returning'
    WHERE citizen_id = ? AND rental_id = ? AND status = 'active'
  ]], { citizenId, rentalId })
  if tonumber(changed) == 1 then return true end
  local lease = Database.GetRentalLease(citizenId)
  return lease ~= nil and lease.id == rentalId and lease.status == "returning"
end

function Database.CloseRentalLease(citizenId, rentalId)
  return tonumber(Sql:Update([[
    DELETE FROM lr_trucker_rental_leases
    WHERE citizen_id = ? AND rental_id = ? AND status = 'returning'
  ]], { citizenId, rentalId })) == 1
end

function Database.AbortPendingRentalLease(citizenId, rentalId)
  return tonumber(Sql:Update([[
    DELETE FROM lr_trucker_rental_leases
    WHERE citizen_id = ? AND rental_id = ? AND status = 'pending'
  ]], { citizenId, rentalId })) == 1
end

function Database.PrepareRentalAssessment(lease, settlementId, grossReward, now, percent)
  local row = Sql:Single([[
    SELECT * FROM lr_trucker_rental_assessments WHERE settlement_id = ? LIMIT 1
  ]], { settlementId })
  if not row then
    local minutes = math.ceil(math.max(0, now - lease.expiresAt) / 60)
    local cumulative = math.ceil(lease.fee * percent * minutes / 100)
    local delta = math.max(0, cumulative - lease.assessedOverage)
    local netReward = math.max(0, grossReward - delta)
    local bankDue = math.max(0, delta - grossReward)
    Sql:Update([[
      INSERT IGNORE INTO lr_trucker_rental_assessments
        (settlement_id, rental_id, cumulative_due, gross_reward, net_reward, bank_due)
      VALUES (?, ?, ?, ?, ?, ?)
    ]], { settlementId, lease.id, cumulative, grossReward, netReward, bankDue })
    row = Sql:Single([[
      SELECT * FROM lr_trucker_rental_assessments WHERE settlement_id = ? LIMIT 1
    ]], { settlementId })
  end
  if not row or row.rental_id ~= lease.id
    or tonumber(row.gross_reward) ~= grossReward then return nil end
  return {
    cumulativeDue = tonumber(row.cumulative_due) or 0,
    netReward = tonumber(row.net_reward) or 0,
    bankDue = tonumber(row.bank_due) or 0,
    committed = tonumber(row.committed) == 1,
  }
end

function Database.CommitRentalAssessment(citizenId, rentalId, settlementId)
  local row = Sql:Single([[
    SELECT cumulative_due FROM lr_trucker_rental_assessments
    WHERE settlement_id = ? AND rental_id = ? LIMIT 1
  ]], { settlementId, rentalId })
  if not row then return false end
  local changed = Sql:Update([[
    UPDATE lr_trucker_rental_leases
    SET assessed_overage = GREATEST(assessed_overage, ?)
    WHERE citizen_id = ? AND rental_id = ?
  ]], { row.cumulative_due, citizenId, rentalId })
  if tonumber(changed) == nil then return false end
  local lease = Database.GetRentalLease(citizenId)
  if not lease or lease.id ~= rentalId
    or lease.assessedOverage < (tonumber(row.cumulative_due) or 0) then return false end
  local committed = Sql:Update([[
    UPDATE lr_trucker_rental_assessments SET committed = 1
    WHERE settlement_id = ? AND rental_id = ?
  ]], { settlementId, rentalId })
  return tonumber(committed) ~= nil
end

function Database.GetRentalDebt(citizenId)
  local row = Sql:Single([[
    SELECT COALESCE(SUM(amount), 0) AS total FROM lr_trucker_payments
    WHERE citizen_id = ? AND kind = 'rental_overage' AND status <> 'paid'
  ]], { citizenId })
  return math.max(0, math.floor(tonumber(row and row.total) or 0))
end

local function normalizeBusinessOrder(row, lines)
  if not row then return nil end
  return {
    id = tostring(row.id or ""),
    businessId = tostring(row.business_id or ""),
    businessLabel = tostring(row.business_label or ""),
    adapter = tostring(row.adapter or "stash"),
    accountId = tostring(row.account_id or ""),
    stashId = tostring(row.stash_id or ""),
    stationLocation = math.max(0, math.floor(tonumber(row.station_location) or 0)),
    createdBy = tostring(row.created_by or ""),
    status = tostring(row.status or "waiting_stock"),
    escrowState = tostring(row.escrow_state or "held"),
    cargoMode = tostring(row.cargo_mode or "pallets"),
    destination = tostring(row.destination_label or ""),
    destinationCoords = {
      x = tonumber(row.destination_x) or 0.0,
      y = tonumber(row.destination_y) or 0.0,
      z = tonumber(row.destination_z) or 0.0,
    },
    distanceKm = math.max(0, tonumber(row.distance_km) or 0),
    packageAmount = math.max(1, math.floor(tonumber(row.package_count) or 1)),
    goodsTotal = math.max(0, math.floor(tonumber(row.goods_total) or 0)),
    deliveryFee = math.max(0, math.floor(tonumber(row.delivery_fee) or 0)),
    escrowTotal = math.max(0, math.floor(tonumber(row.escrow_total) or 0)),
    teamId = tostring(row.team_id or ""),
    missionId = tostring(row.mission_id or ""),
    version = math.max(1, math.floor(tonumber(row.version) or 1)),
    payoutState = tostring(row.payout_state or "pending"),
    lines = lines or {},
  }
end

local function normalizeBusinessLine(row)
  return {
    index = math.max(1, math.floor(tonumber(row.line_index) or 1)),
    itemId = tostring(row.item_id or ""),
    label = tostring(row.item_label or row.item_id or ""),
    category = tostring(row.category or ""),
    quantity = math.max(1, math.floor(tonumber(row.quantity) or 1)),
    unitPrice = math.max(0, math.floor(tonumber(row.unit_price) or 0)),
    subtotal = math.max(0, math.floor(tonumber(row.subtotal) or 0)),
    packages = math.max(1, math.floor(tonumber(row.package_count) or 1)),
    destinationAmount = math.max(1, math.floor(tonumber(row.destination_amount) or 1)),
    destinationUnit = tostring(row.destination_unit or "item"),
    -- NULL is retained for historical rows; never derive paid mappings from config.
    destinationItemId = tostring(row.destination_item_id or ""),
    destinationLabel = tostring(row.destination_label or (row.destination_unit == "liter" and "Nhiên liệu") or row.item_label or row.item_id or ""),
    reservationId = tostring(row.reservation_id or ""),
    reservationState = tostring(row.reservation_state or "none"),
  }
end

local function getBusinessLines(orderId)
  local rows = Sql:Query([[
    SELECT * FROM lr_trucker_business_order_lines
    WHERE order_id = ? ORDER BY line_index ASC
  ]], { orderId }) or {}
  local lines = {}
  for index = 1, #rows do lines[index] = normalizeBusinessLine(rows[index]) end
  return lines
end

function Database.CreateBusinessOrder(order)
  local queries = {{
    query = [[
      INSERT INTO lr_trucker_business_orders
        (id, business_id, business_label, adapter, account_id, stash_id,
         station_location, created_by, status, cargo_mode, destination_label,
         destination_x, destination_y, destination_z, distance_km, package_count,
         goods_total, delivery_fee, escrow_total)
      VALUES (?, ?, ?, ?, NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, 0), ?, ?, ?,
        ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]],
    values = {
      order.id, order.businessId, order.businessLabel, order.adapter,
      order.accountId or "", order.stashId or "", order.stationLocation or 0,
      order.createdBy, order.status, order.cargoMode, order.destination,
      order.destinationCoords.x, order.destinationCoords.y, order.destinationCoords.z,
      order.distanceKm, order.packageAmount, order.goodsTotal, order.deliveryFee,
      order.escrowTotal,
    },
  }}
  for index = 1, #order.lines do
    local line = order.lines[index]
    queries[#queries + 1] = {
      query = [[
        INSERT INTO lr_trucker_business_order_lines
          (order_id, line_index, item_id, item_label, category, quantity,
           unit_price, subtotal, package_count, destination_amount, destination_unit,
           destination_item_id, destination_label)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ]],
      values = {
        order.id, index, line.itemId, line.label, line.category, line.quantity,
        line.unitPrice, line.subtotal, line.packages, line.destinationAmount,
        line.destinationUnit, line.destinationItemId, line.destinationLabel,
      },
    }
  end
  return Sql:Transaction(queries) == true
end

function Database.GetBusinessOrder(orderId)
  local row = Sql:Single('SELECT * FROM lr_trucker_business_orders WHERE id = ? LIMIT 1', { orderId })
  return row and normalizeBusinessOrder(row, getBusinessLines(orderId)) or nil
end

function Database.ListBusinessOrders(filter, page, pageSize)
  local where = "status IN ('waiting_stock','available')"
  if filter == "active" then
    where = "status IN ('waiting_stock','available','reserving','in_transit')"
  end
  local totalRow = Sql:Single(('SELECT COUNT(*) AS total FROM lr_trucker_business_orders WHERE %s'):format(where))
  local rows = Sql:Query(([[
    SELECT * FROM lr_trucker_business_orders WHERE %s
    ORDER BY created_at ASC LIMIT ? OFFSET ?
  ]]):format(where), { pageSize, (page - 1) * pageSize }) or {}
  local orders = {}
  for index = 1, #rows do
    orders[index] = normalizeBusinessOrder(rows[index], getBusinessLines(rows[index].id))
  end
  return orders, math.max(0, math.floor(tonumber(totalRow and totalRow.total) or 0))
end

function Database.ListBusinessHistory(businessId, limit)
  local rows = Sql:Query([[
    SELECT * FROM lr_trucker_business_orders WHERE business_id = ?
    ORDER BY created_at DESC LIMIT ?
  ]], { businessId, limit or 20 }) or {}
  local orders = {}
  for index = 1, #rows do
    orders[index] = normalizeBusinessOrder(rows[index], getBusinessLines(rows[index].id))
  end
  return orders
end

function Database.TransitionBusinessOrder(orderId, fromStatuses, toStatus, fields)
  local placeholders = {}
  local parameters = { toStatus }
  local sets = { "status = ?", "version = version + 1" }
  for column, value in pairs(fields or {}) do
    if column == "team_id" or column == "mission_id" or column == "escrow_state"
      or column == "payout_state" then
      sets[#sets + 1] = column .. " = ?"
      parameters[#parameters + 1] = value
    end
  end
  for index = 1, #fromStatuses do
    placeholders[index] = "?"
    parameters[#parameters + 1] = fromStatuses[index]
  end
  parameters[#parameters + 1] = orderId
  local query = ("UPDATE lr_trucker_business_orders SET %s WHERE status IN (%s) AND id = ?")
    :format(table.concat(sets, ", "), table.concat(placeholders, ","))
  return tonumber(Sql:Update(query, parameters)) == 1
end

function Database.SetBusinessLineReservation(orderId, lineIndex, reservationId, state)
  return tonumber(Sql:Update([[
    UPDATE lr_trucker_business_order_lines
    SET reservation_id = NULLIF(?, ''), reservation_state = ?
    WHERE order_id = ? AND line_index = ?
  ]], { reservationId or "", state, orderId, lineIndex })) == 1
end

function Database.CreateDeliveryReceipt(deliveryId, orderId, lineIndex, adapter, amount)
  local changed = Sql:Update([[
    INSERT IGNORE INTO lr_trucker_business_delivery_receipts
      (delivery_id, order_id, line_index, destination_adapter, amount)
    VALUES (?, ?, ?, ?, ?)
  ]], { deliveryId, orderId, lineIndex, adapter, amount })
  return tonumber(changed) == 1
end

function Database.HasDeliveryReceipt(deliveryId)
  return Sql:Single([[
    SELECT delivery_id FROM lr_trucker_business_delivery_receipts
    WHERE delivery_id = ? LIMIT 1
  ]], { deliveryId }) ~= nil
end

function Database.RecoverBusinessOrders()
  return math.max(0, math.floor(tonumber(Sql:Update([[
    UPDATE lr_trucker_business_orders SET status = 'waiting_stock',
      team_id = NULL, mission_id = NULL, version = version + 1
    WHERE status IN ('reserving','in_transit')
  ]])) or 0))
end

local function paymentKey(missionId, citizenId, kind, amount)
  local numericAmount = tonumber(amount)
  if type(missionId) ~= "string" or missionId == "" or #missionId > 64
    or type(citizenId) ~= "string" or citizenId == "" or #citizenId > 64
    or (kind ~= "reward" and kind ~= "rental_overage" and kind ~= "rental_fee")
    or not numericAmount or numericAmount < 0 or numericAmount > 4294967295
    or numericAmount % 1 ~= 0 then
    return nil
  end
  return numericAmount
end

-- Persist the amount and recipient before importing cargo. A prepared row is
-- nonpayable until the delivery has committed; claimed_at stays NULL so it is
-- distinguishable from an uncertain money transfer after a crash.
function Database.PreparePayment(missionId, citizenId, kind, amount)
  local value = paymentKey(missionId, citizenId, kind, amount)
  if not value then return nil end
  if value == 0 then return "paid" end
  Sql:Update([[
    INSERT INTO lr_trucker_payments
      (mission_id, citizen_id, kind, amount, status)
    VALUES (?, ?, ?, ?, 'processing')
    ON DUPLICATE KEY UPDATE amount = amount
  ]], { missionId, citizenId, kind, value })
  local row = Sql:Single([[
    SELECT amount, status, claimed_at FROM lr_trucker_payments
    WHERE mission_id = ? AND citizen_id = ? AND kind = ? LIMIT 1
  ]], { missionId, citizenId, kind })
  if not row or tonumber(row.amount) ~= value then return nil end
  if row.status == "processing" then
    return row.claimed_at == nil and "prepared" or nil
  end
  return (row.status == "pending" or row.status == "paid") and row.status or nil
end

function Database.ActivatePayment(missionId, citizenId, kind, amount)
  local value = paymentKey(missionId, citizenId, kind, amount)
  if not value then return false end
  if value == 0 then return true end
  local row = Sql:Single([[
    SELECT amount, status, claimed_at FROM lr_trucker_payments
    WHERE mission_id = ? AND citizen_id = ? AND kind = ? LIMIT 1
  ]], { missionId, citizenId, kind })
  if not row or tonumber(row.amount) ~= value then return false end
  if row.status == "pending" or row.status == "paid" then return true end
  if row.status ~= "processing" or row.claimed_at ~= nil then return false end
  return tonumber(Sql:Update([[
    UPDATE lr_trucker_payments SET status = 'pending'
    WHERE mission_id = ? AND citizen_id = ? AND kind = ?
      AND amount = ? AND status = 'processing' AND claimed_at IS NULL
  ]], { missionId, citizenId, kind, value })) == 1
end

-- A payment's amount is immutable. A processing row needs manual reconciliation
-- after a crash, because the money transfer may have succeeded before the crash.
function Database.EnsurePayment(missionId, citizenId, kind, amount)
  local value = paymentKey(missionId, citizenId, kind, amount)
  if not value then return nil end
  if value > 0 then
    Sql:Update([[
      INSERT INTO lr_trucker_payments
        (mission_id, citizen_id, kind, amount)
      VALUES (?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE amount = amount
    ]], { missionId, citizenId, kind, value })
  end
  local row = Sql:Single([[
    SELECT amount, status FROM lr_trucker_payments
    WHERE mission_id = ? AND citizen_id = ? AND kind = ? LIMIT 1
  ]], { missionId, citizenId, kind })
  if not row then return value == 0 and "paid" or nil end
  if tonumber(row.amount) ~= value then return nil end
  local status = tostring(row.status or "")
  return (status == "pending" or status == "processing" or status == "paid") and status or nil
end

function Database.ClaimPayment(missionId, citizenId, kind, amount)
  local value = paymentKey(missionId, citizenId, kind, amount)
  if not value or value == 0 then return false end
  return tonumber(Sql:Update([[
    UPDATE lr_trucker_payments
    SET status = 'processing', claimed_at = CURRENT_TIMESTAMP
    WHERE mission_id = ? AND citizen_id = ? AND kind = ?
      AND amount = ? AND status = 'pending'
  ]], { missionId, citizenId, kind, value })) == 1
end

function Database.CompletePayment(missionId, citizenId, kind, amount)
  local value = paymentKey(missionId, citizenId, kind, amount)
  if not value or value == 0 then return false end
  return tonumber(Sql:Update([[
    UPDATE lr_trucker_payments
    SET status = 'paid', paid_at = CURRENT_TIMESTAMP
    WHERE mission_id = ? AND citizen_id = ? AND kind = ?
      AND amount = ? AND status = 'processing'
  ]], { missionId, citizenId, kind, value })) == 1
end

-- Call only when the money API explicitly reports failure. Never reset an
-- uncertain transfer result or a processing row found during restart.
function Database.ResetPayment(missionId, citizenId, kind, amount)
  local value = paymentKey(missionId, citizenId, kind, amount)
  if not value or value == 0 then return false end
  return tonumber(Sql:Update([[
    UPDATE lr_trucker_payments
    SET status = 'pending', claimed_at = NULL
    WHERE mission_id = ? AND citizen_id = ? AND kind = ?
      AND amount = ? AND status = 'processing'
  ]], { missionId, citizenId, kind, value })) == 1
end

local function listPendingPayments(citizenId, kind, includeProcessing)
  if type(citizenId) ~= "string" or citizenId == "" or #citizenId > 64 then return {} end
  local statusClause = includeProcessing and "status IN ('pending','processing')"
    or "status = 'pending'"
  local rows = Sql:Query(([[
    SELECT mission_id, amount FROM lr_trucker_payments
    WHERE citizen_id = ? AND kind = ? AND %s
    ORDER BY created_at ASC, mission_id ASC
  ]]):format(statusClause), { citizenId, kind }) or {}
  local payments = {}
  for index = 1, #rows do
    payments[index] = {
      missionId = tostring(rows[index].mission_id or ""),
      amount = math.max(0, math.floor(tonumber(rows[index].amount) or 0)),
    }
  end
  return payments
end

function Database.ListPendingRentalCharges(citizenId)
  -- A processing charge is included so login cannot pay rewards while its
  -- transfer still needs manual reconciliation.
  return listPendingPayments(citizenId, "rental_overage", true)
end

function Database.ListPendingRentalFees(citizenId)
  return listPendingPayments(citizenId, "rental_fee", true)
end

function Database.ListPendingRewards(citizenId)
  return listPendingPayments(citizenId, "reward")
end

function Database.AreMissionChargesPaid(missionId)
  if type(missionId) ~= "string" or missionId == "" or #missionId > 64 then return false end
  local row = Sql:Single([[
    SELECT COUNT(*) AS unpaid FROM lr_trucker_payments
    WHERE mission_id = ? AND kind = 'rental_overage' AND status <> 'paid'
  ]], { missionId })
  return row ~= nil and tonumber(row.unpaid) == 0
end

function Database.AreMissionRewardsPaid(missionId)
  if type(missionId) ~= "string" or missionId == "" or #missionId > 64 then return false end
  local row = Sql:Single([[
    SELECT COUNT(*) AS total, SUM(status = 'paid') AS paid
    FROM lr_trucker_payments
    WHERE mission_id = ? AND kind = 'reward'
  ]], { missionId })
  local total = tonumber(row and row.total) or 0
  return total > 0 and tonumber(row.paid) == total
end

LRTruckerServer.Database = Database
