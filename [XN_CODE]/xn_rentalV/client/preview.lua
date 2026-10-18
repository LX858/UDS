CapsulePreview = {}

local config = ScootConfig
local previewVehicles = {}

function getPreviewState(stationId, token)
  local state = CapsuleStates[stationId]
  if state and state.token == token then
    return state
  end
  return nil
end

function spawnPreviewVehicle(bunker, modelName)
  local model = joaat(modelName)
  if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
    return
  end
  if not ScootRuntime.requestModel(model, 10000) then
    return
  end

  local minDim, maxDim = GetModelDimensions(model)
  local center = Capsule.variant(bunker.entry.side).capsuleCenter
  local pos = Capsule.world(
    bunker.entry,
    center[1] - ((minDim.x + maxDim.x) / 2),
    center[2] - ((minDim.y + maxDim.y) / 2),
    Capsule.curves[1].platformTopZ - minDim.z
  )

  local vehicle = CreateVehicle(
    model,
    pos.x, pos.y, pos.z,
    bunker.entry.heading or 0.0,
    false,
    false
  )
  SetModelAsNoLongerNeeded(model)

  if vehicle == 0 then
    return
  end

  SetEntityVisible(vehicle, false, false)
  SetEntityCollision(vehicle, false, false)
  FreezeEntityPosition(vehicle, true)
  SetVehicleNeedsToBeHotwired(vehicle, false)
  SetVehicleNumberPlateText(vehicle, "ALLGAMERS")
  SetVehicleDoorsLocked(vehicle, 2)
  SetVehicleFuelLevel(vehicle, 100.0)

  return vehicle
end

function setPreviewState(stationId, token, vehicle, phase, frame, target)
  CapsuleStates[stationId] = {
    preview = true,
    token = token,
    mode = "rent",
    phase = phase,
    frame = frame,
    target = target,
    vehicle = vehicle,
    received = GetGameTimer(),
  }

  if CapsuleDui then
    CapsuleDui.busy(stationId, true)
  end
end

function waitPreviewFrame(stationId, token)
  while true do
    local state = getPreviewState(stationId, token)
    if not state then
      return false
    end

    local frame = Capsule.frame(state, GetGameTimer() - state.received)
    if frame >= state.target then
      return true
    end

    Wait(50)
  end
end

function clearPreviewToken(stationId, token)
  if not getPreviewState(stationId, token) then
    return
  end

  CapsuleStates[stationId] = nil
  if CapsuleDui then
    CapsuleDui.busy(stationId, false)
  end
end

function CapsulePreview.start(stationId, delaySec, options)
  local bunker = ScootBunker.list[stationId]
  if not bunker or CapsuleStates[stationId] then
    return false
  end

  options = options or {}
  CapsulePreview.clear(stationId)

  CreateThread(function()
    if delaySec and delaySec > 0 then
      Wait(math.floor(delaySec * 1000))
    end

    bunker = ScootBunker.list[stationId]
    if not bunker or CapsuleStates[stationId] then
      return
    end

    local vehicleModel = options.vehicle
    if not vehicleModel then
      vehicleModel = config.rental.vehicles[1]
      vehicleModel = vehicleModel ~= false and vehicleModel
    end

    local vehicle = nil
    if vehicleModel then
      vehicle = spawnPreviewVehicle(bunker, vehicleModel)
    end

    local token = "preview:" .. GetGameTimer()
    if vehicle then
      previewVehicles[stationId] = vehicle
    end

    setPreviewState(stationId, token, vehicle, "opening", 0, 250)
    if not waitPreviewFrame(stationId, token) then
      CapsulePreview.clear(stationId)
      return
    end

    setPreviewState(stationId, token, vehicle, "hold", 250, 250)

    if options.close == false then
      return
    end

    Wait(math.floor((options.hold or 6) * 1000))

    if not getPreviewState(stationId, token) then
      CapsulePreview.clear(stationId)
      return
    end

    setPreviewState(stationId, token, vehicle, "closing", 350, 600)
    if not waitPreviewFrame(stationId, token) then
      CapsulePreview.clear(stationId)
      return
    end

    clearPreviewToken(stationId, token)

    if not vehicle or options.keep then
      return
    end

    SetTimeout(math.floor((options.cleanup or 45) * 1000), function()
      if previewVehicles[stationId] == vehicle then
        CapsulePreview.clear(stationId)
      end
    end)
  end)

  return true
end

function CapsulePreview.clear(stationId)
  local state = CapsuleStates[stationId]
  if state and state.preview then
    CapsuleStates[stationId] = nil
    if CapsuleDui then
      CapsuleDui.busy(stationId, false)
    end
  end

  local vehicle = previewVehicles[stationId]
  if vehicle and DoesEntityExist(vehicle) then
    if IsVehicleSeatFree(vehicle, -1) then
      DeleteEntity(vehicle)
    end
  end

  previewVehicles[stationId] = nil
end

function CapsulePreview.clearAll()
  for id in pairs(previewVehicles) do
    CapsulePreview.clear(id)
  end

  for id, state in pairs(CapsuleStates) do
    if state.preview then
      CapsulePreview.clear(id)
    end
  end
end

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end
  CapsulePreview.clearAll()
end)
