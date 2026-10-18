local Config = ScootConfig
local Bridge = ScootServerBridge

local locations = {}
local rentalsById = {}
local rentalsBySource = {}
local stationBusy = {}
local requestCooldown = {}
local nextToken = 0
local HOLD_FRAME = 250
local CLOSE_FRAME = 600
local OPEN_MS = math.floor(HOLD_FRAME / 0.03)
local CLOSE_MS = math.floor((CLOSE_FRAME - HOLD_FRAME) / 0.03)

function fail(errorKey)
  return { ok = false, error = ScootT(errorKey) }
end

function nextCycleToken()
  nextToken = (nextToken % 2147483647) + 1
  return nextToken
end

function loadJsonFile(name, fallback)
  local raw = LoadResourceFile(GetCurrentResourceName(), name)
  if not raw or raw == "" then
    return fallback
  end
  local ok, data = pcall(json.decode, raw)
  if ok and type(data) == "table" then
    return data
  end
  return fallback
end

function saveJsonFile(name, data)
  return SaveResourceFile(GetCurrentResourceName(), name, json.encode(data), -1)
end

function cloneCoords(coords)
  if not coords then
    return nil
  end
  return {
    x = tonumber(coords.x) or 0.0,
    y = tonumber(coords.y) or 0.0,
    z = tonumber(coords.z) or 0.0,
  }
end

function normalizeLocation(entry, id)
  if type(entry) ~= "table" or type(entry.coords) ~= "table" then
    return nil
  end

  local side = entry.side == "left" and "left" or "right"
  local normalized = {
    id = tostring(id or entry.id or ""),
    name = type(entry.name) == "string" and entry.name or nil,
    coords = cloneCoords(entry.coords),
    heading = tonumber(entry.heading) or 0.0,
    side = side,
    version = entry.version == "tablet" and "tablet" or (entry.version == "booth" and "booth" or entry.version),
    color = ScootColor(entry.color) or entry.color,
    revision = tonumber(entry.revision) or 1,
    blip = type(entry.blip) == "table" and entry.blip or nil,
  }

  if type(entry.terminal) == "table" and type(entry.terminal.coords) == "table" then
    normalized.terminal = {
      coords = cloneCoords(entry.terminal.coords),
      heading = tonumber(entry.terminal.heading) or normalized.heading,
    }
  end

  if normalized.id == "" then
    normalized.id = ("%s_%s_%s"):format(
      math.floor(normalized.coords.x * 100),
      math.floor(normalized.coords.y * 100),
      math.floor(normalized.heading)
    )
  end

  return normalized
end

function publicLocations()
  local out = {}
  for id, entry in pairs(locations) do
    out[id] = entry
  end
  for index, entry in ipairs(Config.locations or {}) do
    local normalized = normalizeLocation(entry, entry.id or ("cfg_" .. index))
    if normalized then
      out[normalized.id] = normalized
    end
  end
  return out
end

function broadcastLocations(target)
  local payload = publicLocations()
  if target then
    TriggerClientEvent("capsulerent:setLocations", target, payload)
  else
    TriggerClientEvent("capsulerent:setLocations", -1, payload)
  end
end

function persistLocations()
  local serializable = {}
  for id, entry in pairs(locations) do
    serializable[id] = entry
  end
  if not saveJsonFile("locations.json", serializable) then
    return false
  end
  broadcastLocations()
  return true
end

function persistRentals()
  local serializable = {}
  for id, rental in pairs(rentalsById) do
    serializable[id] = {
      id = rental.id,
      identifier = rental.identifier,
      vehicleId = rental.vehicleId,
      model = rental.model,
      plate = rental.plate,
      account = rental.account,
      price = rental.price,
      stationId = rental.stationId,
      endsAt = rental.endsAt,
      warned = rental.warned == true,
    }
  end
  saveJsonFile("rentals.json", serializable)
end

function findPlan(planId)
  for _, plan in ipairs(Config.rental.plans or {}) do
    if plan.id == planId then
      return plan
    end
  end
end

function findVehicle(vehicleId)
  for _, vehicle in ipairs(Config.rental.vehicles or {}) do
    if vehicle.id == vehicleId or vehicle.model == vehicleId then
      return vehicle
    end
  end
end

function rentalPrice(vehicle, plan)
  return math.floor((tonumber(plan.price) or 0) * (tonumber(vehicle.multiplier) or 1.0))
end

function rateLimited(source)
  local now = GetGameTimer()
  local cooldown = tonumber(Config.rental.requestCooldownMs) or 1000
  local last = requestCooldown[source] or 0
  if now - last < cooldown then
    return true
  end
  requestCooldown[source] = now
  return false
end

function distanceToStation(source, stationId)
  local entry = publicLocations()[stationId]
  if not entry then
    return math.huge
  end
  local ped = GetPlayerPed(source)
  if ped == 0 then
    return math.huge
  end
  local coords = GetEntityCoords(ped)
  local station = vector3(entry.coords.x, entry.coords.y, entry.coords.z)
  local dist = #(coords - station)
  if entry.terminal and entry.terminal.coords then
    local terminal = Capsule.service(entry)
    dist = math.min(dist, #(coords - terminal))
  end
  return dist, entry
end

function activeRentalFor(source)
  return rentalsBySource[source]
end

function findRentalByIdentifier(identifier)
  for _, rental in pairs(rentalsById) do
    if rental.identifier == identifier then
      return rental
    end
  end
end

function rentalPayload(rental, source)
  if not rental then
    return nil
  end

  local remaining = math.max(0, math.floor((rental.endsAt - os.time())))
  local netId = nil
  local recoverable = true

  if rental.vehicle and DoesEntityExist(rental.vehicle) then
    netId = NetworkGetNetworkIdFromEntity(rental.vehicle)
    rental.netId = netId
    recoverable = false
  else
    -- Vehicle went missing (restart, despawn, bug). Allow recover / cancel.
    rental.vehicle = nil
    rental.netId = nil
    recoverable = true
  end

  return {
    id = rental.id,
    model = rental.model,
    plate = rental.plate,
    vehicleId = rental.vehicleId,
    remaining = remaining,
    netId = netId,
    recoverable = recoverable,
    stationId = rental.stationId,
  }
end

function pushRentalUpdate(source, rental)
  TriggerClientEvent("capsulerent:rentalUpdate", source, rentalPayload(rental, source))
end

function notifyPlayer(source, message)
  TriggerClientEvent("capsulerent:notify", source, message)
end

function setStationCycle(stationId, state)
  stationBusy[stationId] = state
  TriggerClientEvent("capsulerent:cycle", -1, stationId, state)
end

function clearStationCycle(stationId)
  stationBusy[stationId] = nil
  TriggerClientEvent("capsulerent:cycle", -1, stationId, false)
end

-- Auto-clear stuck busy stations after 3 minutes.
CreateThread(function()
  while true do
    Wait(15000)
    local now = GetGameTimer()
    for stationId, busy in pairs(stationBusy) do
      if busy and busy.startedAt and (now - busy.startedAt) > 180000 then
        print(("[allgamers_capsulerent] clearing stuck cycle at %s"):format(stationId))
        clearStationCycle(stationId)
      end
    end
  end
end)

function waitForEntity(entity, timeoutMs)
  local deadline = GetGameTimer() + (timeoutMs or 5000)
  while not DoesEntityExist(entity) and GetGameTimer() < deadline do
    Wait(0)
  end
  return DoesEntityExist(entity)
end

function makePlate()
  local chars = "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
  local plate = "AG"
  for _ = 1, 6 do
    local index = math.random(1, #chars)
    plate = plate .. chars:sub(index, index)
  end
  return plate
end

function spawnRentalVehicle(entry, vehicleDef, plate, fit)
  local model = joaat(vehicleDef.model)
  if not model or model == 0 then
    print(("[allgamers_capsulerent] invalid model name: %s"):format(tostring(vehicleDef.model)))
    return nil
  end

  plate = string.upper((tostring(plate or ""):match("^%s*(.-)%s*$")) or "")
  if plate == "" then
    return nil
  end

  local variant = Capsule.variant(entry.side)
  -- Spawn on the closed/start platform so the car rises with the open animation.
  local curve = Capsule.curves[1] or Capsule.curves[HOLD_FRAME + 1] or Capsule.curves[#Capsule.curves]
  local offsetX = variant.capsuleCenter[1]
  local offsetY = variant.capsuleCenter[2] or 0.0
  local offsetZ = (curve and curve.platformTopZ) or 0.06

  if type(fit) == "table" then
    offsetX = offsetX - (tonumber(fit.x) or 0.0)
    offsetY = offsetY - (tonumber(fit.y) or 0.0)
    offsetZ = offsetZ - (tonumber(fit.z) or 0.0)
  end

  local world = Capsule.world(entry, offsetX, offsetY, offsetZ)
  -- Server-side only: do NOT call client natives (SetEntityAsMissionEntity,
  -- SetVehicleHasBeenOwnedByPlayer, RequestModel, etc.) — they are nil here.
  local vehicle = CreateVehicle(model, world.x, world.y, world.z, entry.heading or 0.0, true, true)
  if not vehicle or vehicle == 0 then
    print(("[allgamers_capsulerent] CreateVehicle failed for %s at %.2f %.2f %.2f"):format(
      tostring(vehicleDef.model), world.x, world.y, world.z
    ))
    return nil
  end

  local deadline = GetGameTimer() + 5000
  while not DoesEntityExist(vehicle) and GetGameTimer() < deadline do
    Wait(0)
  end
  if not DoesEntityExist(vehicle) then
    print("[allgamers_capsulerent] vehicle entity never existed after CreateVehicle")
    return nil
  end

  SetEntityHeading(vehicle, entry.heading or 0.0)
  SetVehicleNumberPlateText(vehicle, plate)
  SetVehicleDoorsLocked(vehicle, 2)
  return vehicle
end

function deleteRentalVehicle(rental)
  if rental.vehicle and DoesEntityExist(rental.vehicle) then
    Bridge.removeKeys(rental.source or 0, rental.vehicle, rental.plate)
    DeleteEntity(rental.vehicle)
  end
  rental.vehicle = nil
  rental.netId = nil
end

function endRental(rental, reasonKey)
  if not rental then
    return
  end

  local source = rental.source
  if rental.stationId and stationBusy[rental.stationId] and stationBusy[rental.stationId].rentalId == rental.id then
    clearStationCycle(rental.stationId)
  end

  deleteRentalVehicle(rental)
  rentalsById[rental.id] = nil
  if source and rentalsBySource[source] == rental then
    rentalsBySource[source] = nil
    pushRentalUpdate(source, nil)
    if reasonKey then
      notifyPlayer(source, ScootT(reasonKey))
    end
  end
  persistRentals()
end

function attachSourceToRental(source, rental)
  rental.source = source
  rentalsBySource[source] = rental
  pushRentalUpdate(source, rental)
end

function beginOpenCycle(source, stationId, mode, vehicle, rental)
  local token = nextCycleToken()
  local netId = vehicle and NetworkGetNetworkIdFromEntity(vehicle) or nil
  local state = {
    mode = mode,
    phase = "opening",
    frame = 0,
    target = HOLD_FRAME,
    token = token,
    src = source,
    netId = netId,
    rentalId = rental and rental.id or nil,
    startedAt = GetGameTimer(),
  }
  setStationCycle(stationId, state)

  SetTimeout(OPEN_MS, function()
    local current = stationBusy[stationId]
    if not current or current.token ~= token then
      return
    end
    current.phase = "hold"
    current.frame = HOLD_FRAME
    current.target = HOLD_FRAME
    setStationCycle(stationId, current)

    if mode == "rent" and rental then
      if rental.vehicle and DoesEntityExist(rental.vehicle) then
        SetVehicleDoorsLocked(rental.vehicle, 1)
        SetVehicleNumberPlateText(rental.vehicle, rental.plate)
      end
      -- One key grant when the capsule finishes opening (matches original timing).
      Bridge.giveKeys(source, rental.vehicle, rental.plate)

      -- Fallback: if the client never reports leaving the bay, close after grace + buffer.
      local graceMs = math.floor(((tonumber(Config.rental.pickupGraceSeconds) or 25) + 5) * 1000)
      SetTimeout(graceMs, function()
        local still = stationBusy[stationId]
        if still and still.token == token and still.phase == "hold" and still.mode == "rent" and not still.released then
          still.released = true
          beginCloseCycle(source, stationId, nil, rental)
        end
      end)
    end

    if mode == "return" then
      local timeout = (tonumber(Config.rental.returnTimeout) or 180) * 1000
      SetTimeout(timeout, function()
        local still = stationBusy[stationId]
        if still and still.token == token and still.phase == "hold" and still.mode == "return" then
          clearStationCycle(stationId)
        end
      end)
    end
  end)

  return state
end

function beginCloseCycle(source, stationId, vehicle, rental, onDone)
  local current = stationBusy[stationId]
  local token = nextCycleToken()
  local netId = nil
  if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
    netId = NetworkGetNetworkIdFromEntity(vehicle)
  end

  local state = {
    mode = current and current.mode or "return",
    phase = "closing",
    frame = HOLD_FRAME,
    target = CLOSE_FRAME,
    token = token,
    src = source,
    netId = netId,
    rentalId = rental and rental.id or nil,
    released = true,
    startedAt = GetGameTimer(),
  }
  setStationCycle(stationId, state)

  SetTimeout(CLOSE_MS, function()
    local still = stationBusy[stationId]
    if not still or still.token ~= token then
      return
    end
    clearStationCycle(stationId)
    if onDone then
      onDone()
    end
  end)

  return state
end

function buildMenu(source, stationId)
  local dist, entry = distanceToStation(source, stationId)
  if not entry then
    return fail("invalid")
  end
  if dist > ((Config.interactDistance or 3.0) + 2.0) then
    return fail("too_far")
  end

  local rental = activeRentalFor(source)
  local identifier = Bridge.getIdentifier(source)
  if not rental and identifier then
    local saved = findRentalByIdentifier(identifier)
    if saved and saved.endsAt > os.time() then
      rental = saved
      attachSourceToRental(source, rental)
    end
  end

  local balances = Bridge.getBalances(source)
  local vehicles = {}
  for _, vehicle in ipairs(Config.rental.vehicles or {}) do
    vehicles[#vehicles + 1] = {
      id = vehicle.id,
      model = vehicle.model,
      label = vehicle.label,
      category = vehicle.category,
      image = vehicle.image,
      multiplier = vehicle.multiplier or 1.0,
    }
  end

  local plans = {}
  for _, plan in ipairs(Config.rental.plans or {}) do
    plans[#plans + 1] = {
      id = plan.id,
      minutes = plan.minutes,
      price = plan.price,
    }
  end

  return {
    ok = true,
    station = {
      id = stationId,
      name = entry.name or ScootT("station"),
    },
    vehicles = vehicles,
    plans = plans,
    accounts = Config.rental.accounts or { "cash", "bank" },
    balance = balances,
    rental = rentalPayload(rental, source),
    busy = stationBusy[stationId] ~= nil,
  }
end

function startRent(source, payload)
  if rateLimited(source) then
    return fail("rate_limit")
  end
  if type(payload) ~= "table" then
    return fail("invalid")
  end

  local stationId = tostring(payload.id or payload.stationId or "")
  local vehicleDef = findVehicle(payload.vehicle)
  local plan = findPlan(payload.plan)
  local account = payload.account
  local allowed = false
  for _, name in ipairs(Config.rental.accounts or {}) do
    if name == account then
      allowed = true
      break
    end
  end

  if stationId == "" or not vehicleDef or not plan or not allowed then
    return fail("invalid")
  end

  local dist, entry = distanceToStation(source, stationId)
  if not entry then
    return fail("invalid")
  end
  if dist > ((Config.interactDistance or 3.0) + 4.0) then
    return fail("too_far")
  end
  if stationBusy[stationId] then
    return fail("busy")
  end
  if activeRentalFor(source) then
    return fail("already_rented")
  end

  local identifier = Bridge.getIdentifier(source)
  if not identifier then
    return fail("unavailable")
  end
  if findRentalByIdentifier(identifier) then
    return fail("already_rented")
  end

  local fit = ScootRuntime.callback.await("capsulerent:fit", source, vehicleDef.model)
  if type(fit) == "table" and fit.ok == false and (fit.reason == "model_missing" or fit.reason == "model_too_big") then
    return fail(fit.reason)
  end
  if type(fit) ~= "table" or fit.ok ~= true then
    print(("[allgamers_capsulerent] fit rpc failed for %s, using default offsets"):format(tostring(vehicleDef.model)))
    fit = { ok = true, x = 0.0, y = 0.0, z = 0.0 }
  end

  local price = rentalPrice(vehicleDef, plan)
  if not Bridge.removeMoney(source, account, price) then
    return fail("insufficient")
  end

  local plate = makePlate()
  local okSpawn, vehicleOrErr = pcall(spawnRentalVehicle, entry, vehicleDef, plate, fit)
  if not okSpawn then
    print(("[allgamers_capsulerent] spawn error: %s"):format(tostring(vehicleOrErr)))
    Bridge.addMoney(source, account, price)
    return fail("model_failed")
  end
  local vehicle = vehicleOrErr
  if not vehicle then
    Bridge.addMoney(source, account, price)
    return fail("model_failed")
  end

  local rental = {
    id = ("%s_%s"):format(identifier, os.time()),
    identifier = identifier,
    source = source,
    vehicleId = vehicleDef.id,
    model = vehicleDef.model,
    plate = plate,
    account = account,
    price = price,
    stationId = stationId,
    endsAt = os.time() + math.floor((tonumber(plan.minutes) or 15) * 60),
    vehicle = vehicle,
    netId = NetworkGetNetworkIdFromEntity(vehicle),
    warned = false,
  }

  rentalsById[rental.id] = rental
  rentalsBySource[source] = rental
  persistRentals()

  beginOpenCycle(source, stationId, "rent", vehicle, rental)
  pushRentalUpdate(source, rental)

  return {
    ok = true,
    rental = rentalPayload(rental, source),
  }
end

function recoverRental(source, stationId)
  if rateLimited(source) then
    return fail("rate_limit")
  end

  stationId = tostring(stationId or "")
  local dist, entry = distanceToStation(source, stationId)
  if not entry then
    return fail("invalid")
  end
  if dist > ((Config.interactDistance or 3.0) + 4.0) then
    return fail("too_far")
  end
  if stationBusy[stationId] then
    return fail("busy")
  end

  local rental = activeRentalFor(source)
  if not rental then
    local identifier = Bridge.getIdentifier(source)
    rental = identifier and findRentalByIdentifier(identifier) or nil
  end
  if not rental or rental.endsAt <= os.time() then
    return fail("expired")
  end
  if rental.vehicle and DoesEntityExist(rental.vehicle) then
    return fail("already_rented")
  end

  local vehicleDef = findVehicle(rental.vehicleId) or { id = rental.vehicleId, model = rental.model, multiplier = 1.0 }
  local fit = ScootRuntime.callback.await("capsulerent:fit", source, vehicleDef.model)
  if type(fit) == "table" and fit.ok == false and (fit.reason == "model_missing" or fit.reason == "model_too_big") then
    return fail(fit.reason)
  end
  if type(fit) ~= "table" or fit.ok ~= true then
    fit = { ok = true, x = 0.0, y = 0.0, z = 0.0 }
  end
  local plate = string.upper((tostring(rental.plate or ""):match("^%s*(.-)%s*$")) or "")
  if plate == "" then
    plate = makePlate()
  end
  rental.plate = plate

  local okSpawn, vehicle = pcall(spawnRentalVehicle, entry, vehicleDef, plate, fit)
  if not okSpawn or not vehicle then
    return fail("model_failed")
  end

  rental.vehicle = vehicle
  rental.netId = NetworkGetNetworkIdFromEntity(vehicle)
  rental.stationId = stationId
  attachSourceToRental(source, rental)
  persistRentals()
  Bridge.giveKeys(source, vehicle, plate)
  beginOpenCycle(source, stationId, "rent", vehicle, rental)

  return {
    ok = true,
    rental = rentalPayload(rental, source),
  }
end

function cancelOrphanRental(source)
  local rental = activeRentalFor(source)
  if not rental then
    local identifier = Bridge.getIdentifier(source)
    rental = identifier and findRentalByIdentifier(identifier) or nil
  end
  if not rental then
    return fail("invalid")
  end
  if rental.vehicle and DoesEntityExist(rental.vehicle) then
    return fail("bring_scooter")
  end

  endRental(rental, "returned")
  return { ok = true }
end

function requestReturn(source, stationId)
  if rateLimited(source) then
    return fail("rate_limit")
  end

  stationId = tostring(stationId or "")
  local dist, entry = distanceToStation(source, stationId)
  if not entry then
    return fail("invalid")
  end

  local rental = activeRentalFor(source)
  if not rental or not rental.vehicle or not DoesEntityExist(rental.vehicle) then
    return fail("bring_scooter")
  end

  local returnDistance = tonumber(Config.rental.returnDistance) or 18.0
  local vehicleCoords = GetEntityCoords(rental.vehicle)
  local stationCoords = vector3(entry.coords.x, entry.coords.y, entry.coords.z)
  if #(vehicleCoords - stationCoords) > returnDistance then
    return fail("bring_scooter")
  end
  if stationBusy[stationId] then
    return fail("busy")
  end

  -- Open the bay only — do not attach/teleport the car; player drives onto the platform.
  beginOpenCycle(source, stationId, "return", nil, rental)
  return { ok = true }
end

function confirmReturn(source, stationId)
  if rateLimited(source) then
    return fail("rate_limit")
  end

  stationId = tostring(stationId or "")
  local entry = publicLocations()[stationId]
  local busy = stationBusy[stationId]
  local rental = activeRentalFor(source)

  if not entry or not busy or busy.mode ~= "return" or busy.phase ~= "hold" or busy.src ~= source then
    return fail("invalid")
  end
  if not rental or not rental.vehicle or not DoesEntityExist(rental.vehicle) then
    return fail("bring_scooter")
  end

  local ped = GetPlayerPed(source)
  if ped ~= 0 and GetVehiclePedIsIn(ped, false) == rental.vehicle then
    return fail("exit_vehicle")
  end

  if not Capsule.bay(entry, GetEntityCoords(rental.vehicle), 0.35) then
    return fail("park_straight")
  end

  local speed = GetEntitySpeed(rental.vehicle)
  if speed > 0.35 then
    return fail("vehicle_moving")
  end

  beginCloseCycle(source, stationId, rental.vehicle, rental, function()
    endRental(rental, "returned")
  end)

  return { ok = true }
end

-------------------------------------------------------------------------------
-- Events + callbacks
-------------------------------------------------------------------------------

RegisterNetEvent("capsulerent:requestLocations", function()
  local source = source
  broadcastLocations(source)

  local identifier = Bridge.getIdentifier(source)
  if not identifier then
    return
  end

  local rental = findRentalByIdentifier(identifier)
  if rental and rental.endsAt > os.time() then
    attachSourceToRental(source, rental)
  else
    pushRentalUpdate(source, nil)
  end
end)

-- Client saw a different live plate than the rental plate; grant keys for it too.
RegisterNetEvent("capsulerent:server:syncKeyPlate", function(livePlate)
  local source = source
  livePlate = string.upper((tostring(livePlate or ""):match("^%s*(.-)%s*$")) or "")
  if livePlate == "" then
    return
  end
  local rental = activeRentalFor(source)
  if not rental then
    return
  end
  if rental.plate ~= livePlate then
    print(("[allgamers_capsulerent] syncKeyPlate %s -> %s"):format(tostring(rental.plate), livePlate))
    rental.plate = livePlate
    if rental.vehicle and DoesEntityExist(rental.vehicle) then
      SetVehicleNumberPlateText(rental.vehicle, livePlate)
    end
    persistRentals()
  end
  -- Direct silent grant — do not re-fire Bridge.giveKeys (would notify again if plate changed).
  if GetResourceState("qb-vehiclekeys") == "started" then
    pcall(function()
      exports["qb-vehiclekeys"]:GiveKeys(source, livePlate)
    end)
  end
end)

RegisterNetEvent("capsulerent:released", function(stationId, token)
  local source = source
  stationId = tostring(stationId or "")
  local busy = stationBusy[stationId]
  if not busy or busy.token ~= token or busy.src ~= source then
    return
  end
  if busy.mode ~= "rent" or busy.phase ~= "hold" then
    return
  end
  if busy.released then
    return
  end
  busy.released = true

  local rental = activeRentalFor(source)
  if not rental then
    clearStationCycle(stationId)
    return
  end

  if rental.vehicle and DoesEntityExist(rental.vehicle) then
    SetVehicleDoorsLocked(rental.vehicle, 1)
    SetVehicleNumberPlateText(rental.vehicle, rental.plate)
    rental.netId = NetworkGetNetworkIdFromEntity(rental.vehicle)
  end

  Bridge.giveKeys(source, rental.vehicle, rental.plate)

  -- Close empty (no vehicle netId) so the player can drive away while the capsule sinks.
  beginCloseCycle(source, stationId, nil, rental)
end)

ScootRuntime.callback.register("capsulerent:menu", function(source, stationId)
  return buildMenu(source, tostring(stationId or ""))
end)

ScootRuntime.callback.register("capsulerent:rent", function(source, payload)
  return startRent(source, payload)
end)

ScootRuntime.callback.register("capsulerent:recover", function(source, stationId)
  if type(stationId) == "table" then
    stationId = stationId.id or stationId
  end
  return recoverRental(source, stationId)
end)

ScootRuntime.callback.register("capsulerent:cancelRental", function(source)
  return cancelOrphanRental(source)
end)

ScootRuntime.callback.register("capsulerent:returnRental", function(source, stationId)
  if type(stationId) == "table" then
    stationId = stationId.id or stationId
  end
  return requestReturn(source, stationId)
end)

ScootRuntime.callback.register("capsulerent:confirmReturn", function(source, stationId)
  if type(stationId) == "table" then
    stationId = stationId.id or stationId
  end
  return confirmReturn(source, stationId)
end)

ScootRuntime.callback.register("capsulerent:status", function(source)
  local rental = activeRentalFor(source)
  if not rental then
    local identifier = Bridge.getIdentifier(source)
    rental = identifier and findRentalByIdentifier(identifier) or nil
    if rental and rental.endsAt > os.time() then
      attachSourceToRental(source, rental)
    end
  end
  return {
    ok = true,
    rental = rentalPayload(rental, source),
  }
end)

ScootRuntime.callback.register("capsulerent:creator", function(source)
  if not Bridge.canPlace(source) then
    return fail("no_permission")
  end
  return {
    ok = true,
    locations = locations,
  }
end)

ScootRuntime.callback.register("capsulerent:saveLocation", function(source, draft)
  if not Bridge.canPlace(source) then
    return fail("no_permission")
  end
  if type(draft) ~= "table" then
    return fail("invalid")
  end

  local normalized = normalizeLocation(draft, draft.id)
  if not normalized then
    return fail("invalid")
  end

  local creator = Config.creator or {}
  local count = 0
  for id, entry in pairs(locations) do
    count = count + 1
    if id ~= normalized.id then
      local dx = entry.coords.x - normalized.coords.x
      local dy = entry.coords.y - normalized.coords.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist < (tonumber(creator.minimumSpacing) or 12.0) then
        return fail("spacing")
      end
    end
  end

  if not locations[normalized.id] and count >= (tonumber(creator.maxLocations) or 100) then
    return fail("limit")
  end

  for stationId, busy in pairs(stationBusy) do
    if stationId == normalized.id then
      return fail("in_use")
    end
  end

  normalized.revision = (locations[normalized.id] and locations[normalized.id].revision or 0) + 1
  locations[normalized.id] = normalized
  if not persistLocations() then
    return fail("storage_failed")
  end
  return { ok = true, id = normalized.id, locations = locations }
end)

ScootRuntime.callback.register("capsulerent:deleteLocation", function(source, locationId)
  if not Bridge.canPlace(source) then
    return fail("no_permission")
  end

  if type(locationId) == "table" then
    locationId = locationId.id or locationId
  end

  locationId = tostring(locationId or "")
  if locations[locationId] == nil then
    return fail("no_station")
  end
  if stationBusy[locationId] then
    return fail("in_use")
  end

  locations[locationId] = nil
  if not persistLocations() then
    return fail("storage_failed")
  end
  return { ok = true, locations = locations }
end)

AddEventHandler("playerDropped", function()
  local source = source
  requestCooldown[source] = nil
  local rental = rentalsBySource[source]
  if rental then
    rental.source = nil
    rentalsBySource[source] = nil
    if rental.vehicle and DoesEntityExist(rental.vehicle) then
      deleteRentalVehicle(rental)
      persistRentals()
    end
  end

  for stationId, busy in pairs(stationBusy) do
    if busy.src == source then
      clearStationCycle(stationId)
    end
  end
end)

CreateThread(function()
  local storedLocations = loadJsonFile("locations.json", {})
  for id, entry in pairs(storedLocations) do
    local normalized = normalizeLocation(entry, id)
    if normalized then
      locations[normalized.id] = normalized
    end
  end

  local storedRentals = loadJsonFile("rentals.json", {})
  for id, entry in pairs(storedRentals) do
    if type(entry) == "table" and entry.identifier and (tonumber(entry.endsAt) or 0) > os.time() then
      local rental = {
        id = entry.id or id,
        identifier = entry.identifier,
        vehicleId = entry.vehicleId,
        model = entry.model,
        plate = entry.plate,
        account = entry.account,
        price = entry.price,
        stationId = entry.stationId,
        endsAt = tonumber(entry.endsAt),
        warned = entry.warned == true,
      }
      rentalsById[rental.id] = rental
    end
  end

  broadcastLocations()
end)

CreateThread(function()
  while true do
    Wait(1000)
    local warning = tonumber(Config.rental.warningSeconds) or 60
    local now = os.time()
    for _, rental in pairs(rentalsById) do
      if rental.endsAt <= now then
        endRental(rental, "expired")
      elseif rental.source and not rental.warned and (rental.endsAt - now) <= warning then
        rental.warned = true
        notifyPlayer(rental.source, ScootT("expiry_warning", tostring(rental.endsAt - now)))
        persistRentals()
      elseif rental.source and rental.vehicle and DoesEntityExist(rental.vehicle) then
        rental.netId = NetworkGetNetworkIdFromEntity(rental.vehicle)
      end
    end
  end
end)

exports("getLocations", function()
  return publicLocations()
end)

exports("getRentals", function()
  return rentalsById
end)
