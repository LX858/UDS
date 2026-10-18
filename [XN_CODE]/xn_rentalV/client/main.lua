local config = ScootConfig
local bridge = ScootClientBridge
local locations = {}
local currentRental = nil
local locationsReady = false

RegisterNetEvent("capsulerent:setLocations", function(data)
  if source ~= 65535 then
    return
  end
  if type(data) ~= "table" then
    return
  end

  locationsReady = true

  for id, bunker in pairs(ScootBunker.list) do
    local incoming = data[id]
    if not incoming
      or incoming.revision ~= bunker.entry.revision
      or incoming.side ~= bunker.entry.side
    then
      ScootBunker.despawn(id)
    end
  end

  locations = data
  ScootBlips.refresh(locations)
end)

RegisterNetEvent("capsulerent:notify", function(message)
  if source ~= 65535 then
    return
  end
  if type(message) ~= "string" then
    return
  end

  ScootRuntime.notify({
    description = message,
    type = "inform",
  })
end)

RegisterNetEvent("capsulerent:rentalUpdate", function(rental)
  if source ~= 65535 then
    return
  end

  currentRental = rental or nil
  SendNUIMessage({
    action = "rentalUpdate",
    rental = rental or false,
    locale = ScootTranslations(),
    theme = ScootTheme(),
  })
end)

function getRentalVehicle()
  local netId = currentRental and currentRental.netId
  if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then
    return 0
  end
  return NetToVeh(netId)
end

function resolveStationAction(stationId, bunker, playerCoords, pedVehicle, rentalVehicle)
  local state = CapsuleStates[stationId]
  local action = nil
  local tip = nil
  local showMarker = nil

  if rentalVehicle ~= 0 then
    local distToStation = #(playerCoords - bunker.coords)
    if distToStation < 12.0 then
      local isOwner = state and state.src == ScootCache.serverId

      if isOwner then
        if state.phase == "hold" then
          showMarker = true
          if pedVehicle ~= 0 then
            tip = "tip_park_exit"
          else
            if Capsule.bay(bunker.entry, GetEntityCoords(rentalVehicle), 0) then
              action = "return"
            elseif state.mode == "return" then
              tip = "tip_drive_platform"
            end
          end
        elseif state.phase == "paused" then
          tip = "tip_stand_clear"
        else
          tip = "tip_moving"
        end
      elseif not state then
        local vehCoords = GetEntityCoords(rentalVehicle)
        if #(vehCoords - bunker.coords) < config.rental.returnDistance then
          if pedVehicle == rentalVehicle or #(playerCoords - vehCoords) < 5.0 then
            action = "prepare"
          end
        end
      end
    end
  end

  if not action and not tip and pedVehicle == 0 then
    if #(playerCoords - Capsule.service(bunker.entry)) < config.interactDistance then
      action = "open"
    end
  end

  return action, tip, showMarker
end

function runStationAction(action, stationId)
  if action == "open" then
    ScootUI.open(stationId)
    return
  end

  local eventName = action == "return" and "capsulerent:confirmReturn" or "capsulerent:returnRental"
  local ok, result = pcall(ScootRuntime.callback.await, eventName, false, stationId)
  local success = ok and type(result) == "table" and result

  local description
  if success then
    description = ScootT(action == "return" and "return_started" or "capsule_opening")
  elseif ok and type(result) == "table" and result.error then
    description = result.error
  else
    description = ScootT("connection_error")
  end

  ScootRuntime.notify({
    description = description,
    type = success and "success" or "error",
  })
end

CapsuleFlow = {
  act = runStationAction,
  can = function(stationId, action)
    local bunker = ScootBunker.list[stationId]
    if not bunker or ScootPlacement.active or ScootUI.visible then
      return false
    end

    local resolved = resolveStationAction(
      stationId,
      bunker,
      GetEntityCoords(ScootCache.ped),
      GetVehiclePedIsIn(ScootCache.ped, false),
      getRentalVehicle()
    )
    return resolved == action
  end,
}

CreateThread(function()
  Wait(1000)
  repeat
    TriggerServerEvent("capsulerent:requestLocations")
    Wait(3000)
  until locationsReady

  while true do
    local playerCoords = GetEntityCoords(ScootCache.ped)
    local nearest = nil
    local nearestDist = math.huge

    for id, station in pairs(locations) do
      local stationCoords = vector3(station.coords.x, station.coords.y, station.coords.z)
      local dist = #(playerCoords - stationCoords)

      if station.terminal then
        dist = math.min(dist, #(playerCoords - Capsule.service(station)))
      end

      if dist < nearestDist then
        nearestDist = dist
        nearest = station
      end

      if dist < config.spawnDistance then
        if not ScootBunker.list[id] then
          ScootBunker.spawn(id, station)
        end
      elseif dist > config.despawnDistance then
        if ScootBunker.list[id] then
          ScootBunker.despawn(id)
        end
      end
    end

    if nearest and next(ScootBunker.list) and not ScootPlacement.active then
      CapsuleDui.color(nearest.color or config.glow.color)
    end

    Wait(next(locations) and 750 or 2500)
  end
end)

CreateThread(function()
  local lastPromptKey = nil
  local usesKey = bridge.usesKey()

  while true do
    local waitMs = next(ScootBunker.list) and 250 or 1000
    local promptText = nil
    local promptLabel = nil
    local pendingAction = nil
    local pendingStationId = nil

    if next(ScootBunker.list) and not ScootPlacement.active and not ScootUI.visible and not IsPauseMenuActive() then
      local playerCoords = GetEntityCoords(ScootCache.ped)
      local pedVehicle = GetVehiclePedIsIn(ScootCache.ped, false)
      local rentalVehicle = getRentalVehicle()

      for id, bunker in pairs(ScootBunker.list) do
        local action, tip, showMarker = resolveStationAction(id, bunker, playerCoords, pedVehicle, rentalVehicle)

        if showMarker then
          waitMs = 0
          local center = Capsule.variant(bunker.entry.side).capsuleCenter
          local markerPos = Capsule.world(bunker.entry, center[1], center[2], 0.085)
          DrawMarker(
            1,
            markerPos.x, markerPos.y, markerPos.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, bunker.entry.heading,
            2.4, 4.8, 0.04,
            0, 229, 180, 65,
            false, false, 2, false, nil, nil, false
          )
        end

        if action and usesKey and not pendingAction then
          pendingAction = action
          pendingStationId = id
        end

        if tip and not promptText then
          promptText = ScootT(tip)
        end
      end

      if pendingAction then
        local promptKey
        if pendingAction == "return" then
          promptKey = "prompt_return"
        elseif pendingAction == "prepare" then
          promptKey = "prompt_prepare"
        else
          promptKey = "interact"
        end
        promptText = ScootT(promptKey)
        promptLabel = config.interactKeyLabel
        waitMs = 0
      elseif promptText and waitMs > 100 then
        waitMs = 100
      end
    end

    if IsPauseMenuActive() then
      promptText = nil
      pendingAction = nil
      if lastPromptKey then
        bridge.hidePrompt()
        lastPromptKey = nil
      end
      Wait(waitMs)
    elseif promptText then
      local promptKey = (promptLabel or "") .. "|" .. promptText
      if lastPromptKey ~= promptKey then
        bridge.showPrompt(promptText, promptLabel)
        lastPromptKey = promptKey
      end

      if pendingAction and IsControlJustReleased(0, config.interactKey) then
        bridge.hidePrompt()
        lastPromptKey = nil
        runStationAction(pendingAction, pendingStationId)
      end
      Wait(waitMs)
    elseif lastPromptKey then
      bridge.hidePrompt()
      lastPromptKey = nil
      Wait(waitMs)
    else
      Wait(waitMs)
    end
  end
end)

CreateThread(function()
  while true do
    Wait(60000)
    local ok, result = pcall(ScootRuntime.callback.await, "capsulerent:status", false)
    if ok and type(result) == "table" and result.ok then
      currentRental = result.rental or nil
      SendNUIMessage({
        action = "rentalUpdate",
        rental = result.rental or false,
        locale = ScootTranslations(),
        theme = ScootTheme(),
      })
    end
  end
end)

RegisterCommand("vaultdiag", function()
  for id, bunker in pairs(ScootBunker.list) do
    local state = CapsuleStates[id]
    print(("[capsulerent] %s side=%s phase=%s mech=%s"):format(
      id,
      bunker.entry.side,
      (state and state.phase) or "idle",
      bunker.mech
    ))

    for _, part in ipairs({ "obj", "plat", "roof", "wall", "frame" }) do
      print(
        "[capsulerent] " .. part,
        "physics", DoesEntityHavePhysics(bunker[part]),
        "collisionDisabled", GetEntityCollisionDisabled(bunker[part])
      )
    end

    if state and state.netId and NetworkDoesEntityExistWithNetworkId(state.netId) then
      local vehicle = NetToVeh(state.netId)
      print(
        "[capsulerent] vehicle", vehicle,
        "position", GetEntityCoords(vehicle),
        "control", NetworkHasControlOfEntity(vehicle),
        "collisionDisabled", GetEntityCollisionDisabled(vehicle),
        "travel", Entity(vehicle).state.capsuleTravel
      )
    end

    for _, boneName in ipairs({ "capsule", "wall_front", "wall_left" }) do
      local boneIndex = GetEntityBoneIndexByName(bunker.mech, boneName)
      print(
        boneName,
        boneIndex,
        boneIndex >= 0 and GetWorldPositionOfEntityBone(bunker.mech, boneIndex)
      )
    end
  end
end, false)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then
    return
  end

  ScootPlacement.close()
  ScootAudio.stopAll()

  for id in pairs(ScootBunker.list) do
    ScootBunker.despawn(id)
  end

  bridge.hidePrompt()
end)

exports("getLocations", function()
  return locations
end)

exports("openStation", function(stationId)
  ScootUI.open(stationId)
end)

function getNearestStation(fromCoords)
  local origin = fromCoords
  if not origin then
    origin = GetEntityCoords(ScootCache.ped)
  end

  local nearestId = nil
  local nearestDist = nil

  for id, station in pairs(locations) do
    local stationCoords = vector3(station.coords.x, station.coords.y, station.coords.z)
    local dist = #(origin - stationCoords)
    if not nearestDist or dist < nearestDist then
      nearestDist = dist
      nearestId = id
    end
  end

  return nearestId, nearestDist
end

exports("getNearestStation", function()
  return getNearestStation()
end)

exports("previewStation", function(stationId, delaySec, options, holdArg)
  if stationId == nil or stationId == "near" then
    stationId = getNearestStation(GetFinalRenderedCamCoord())
  end

  if type(stationId) == "number" then
    stationId = tostring(stationId)
  end

  if type(options) ~= "table" then
    local vehicle = options
    if vehicle == "none" or vehicle == "false" then
      vehicle = false
    end
    options = {
      vehicle = vehicle,
      hold = tonumber(holdArg),
    }
  end

  if stationId ~= nil then
    return CapsulePreview.start(stationId, tonumber(delaySec) or 0, options) or false
  end

  return false
end)

exports("clearPreview", function(stationId)
  if stationId then
    CapsulePreview.clear(stationId)
  else
    CapsulePreview.clearAll()
  end
end)

RegisterCommand("vaultpreview", function(_, args)
  if args[1] == "clear" then
    CapsulePreview.clearAll()
    return
  end

  exports[GetCurrentResourceName()]:previewStation(args[1], args[3], args[2], args[4])
end, false)
