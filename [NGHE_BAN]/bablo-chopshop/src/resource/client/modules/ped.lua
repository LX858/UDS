Peds = {}

local function resolvePosition(position)
  return position.x or position[1], position.y or position[2], position.z or position[3]
end

local function getGroundedPosition(position)
  local x, y, z = resolvePosition(position)
  local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z + 1.0, 0)

  if foundGround then
    z = groundZ
  end

  return x, y, z
end

local function createScenarioCallback(ped)
  return function()
    TaskTurnPedToFaceEntity(cache.ped, ped, 1500)
    TaskTurnPedToFaceEntity(ped, cache.ped, 1500)
  end
end

local function spawnPedVehicle(vehicleConfig)
  if not vehicleConfig then
    return nil
  end

  LoadModels({ vehicleConfig.model })

  local x, y, z = getGroundedPosition(vehicleConfig.position)
  local vehicle = CreateVehicle(vehicleConfig.model, x, y, z, vehicleConfig.heading or 0.0, false, true)

  if not DoesEntityExist(vehicle) then
    CleanupModels({ vehicleConfig.model })
    return nil
  end

  SetEntityAsMissionEntity(vehicle, true, true)
  SetBlockingOfNonTemporaryEvents(vehicle, true)
  Entity(vehicle).state.mission = true

  if vehicleConfig.plate then
    SetVehicleNumberPlateText(vehicle, vehicleConfig.plate)
  end

  if vehicleConfig.primarycolour then
    SetVehicleColours(vehicle, vehicleConfig.primarycolour, vehicleConfig.secondarycolour or 0)
  end

  if vehicleConfig.freeze then
    FreezeEntityPosition(vehicle, true)
  end

  if vehicleConfig.engineOff then
    SetVehicleEngineOn(vehicle, false, true, true)
  end

  if vehicleConfig.livery then
    SetVehicleLivery(vehicle, vehicleConfig.livery)
  end

  if vehicleConfig.doorOpen then
    SetVehicleDoorOpen(vehicle, vehicleConfig.doorOpen, false, false)
  end

  if vehicleConfig.anchor then
    SetBoatAnchor(vehicle, true)
    SetBoatFrozenWhenAnchored(vehicle, true)
    SetForcedBoatLocationWhenAnchored(vehicle, true)
  end

  if vehicleConfig.clean then
    SetVehicleDirtLevel(vehicle, 0.0)
  end

  SetVehicleDoorsLocked(vehicle, 2)
  CleanupModels({ vehicleConfig.model })

  return vehicle
end

local function playPedAnimation(ped, animation)
  if not animation then
    return
  end

  if animation.prop then
    exports["tp-animations"]:playAnimation(ped, animation.prop)
  elseif not animation.dict then
    TaskStartScenarioInPlace(ped, animation.anim, 0, true)
  else
    LoadModels({ animation.dict })
    PlayAnimation(ped, animation.dict, animation.anim, animation.data)
    CleanupModels({ animation.dict })
  end
end

function ConstructPed(data)
  if not data or not data.model or not data.position then
    return
  end

  if not IsModelValid(data.model) then
    Trace("[ConstructPed] Invalid model:", data.model)
    return
  end

  LoadModels({ data.model })

  local x, y, z = getGroundedPosition(data.position)
  local ped = CreatePed(5, data.model, x, y, z, data.heading or 0.0, false, false)

  if not DoesEntityExist(ped) then
    return
  end

  PlaceObjectOnGroundProperly(ped)
  SetEntityAsMissionEntity(ped, true, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  TaskSetBlockingOfNonTemporaryEvents(ped, true)

  if data.freeze then
    FreezeEntityPosition(ped, true)
  end

  data.callback = data.callback or createScenarioCallback(ped)

  local vehicle = spawnPedVehicle(data.vehicle)
  playPedAnimation(ped, data.animation)

  local pedObject = {
    handle = ped,
    vehicleHandle = vehicle,
    data = data,
    context = data.context or {},
  }

  function pedObject:destroy()
    if DoesEntityExist(ped) then
      DeleteEntity(ped)
    end

    if DoesEntityExist(vehicle) then
      DeleteEntity(vehicle)
    end

    Peds[ped] = nil

    if data.callback then
      Target:removeTargetEntity(ped, ("pedstream-%s"):format(ped))
    end
  end

  function pedObject:interact()
    if data.callback then
      data.callback(ped)
    end
  end

  Peds[ped] = pedObject
  CleanupModels({ data.model })

  Trace(("[ConstructPed] Spawned ped: %s at %.2f, %.2f, %.2f"):format(data.model, x, y, z))
  AddContext(pedObject)

  return pedObject
end

function AddContext(pedObject)
  if not DoesEntityExist(pedObject.handle) then
    return
  end

  local menuElements = pedObject.context and pedObject.context.menuElements
  if not menuElements or #menuElements == 0 then
    Trace("[AddContext] No context menu elements found for ped.")
    return
  end

  local menuElement = menuElements[1]
  if not menuElement.label then
    Trace("[AddContext] Incomplete context menu element found for ped.")
    return
  end

  Target:addTargetEntity(pedObject.handle, {
    label = menuElement.label,
    name = ("pedstream-%s"):format(pedObject.handle),
    icon = menuElement.icon or "fas fa-car-burst",
    distance = 2.5,
    action = function(entity)
      if entity and DoesEntityExist(entity) then
        menuElement.action(entity)
      end
    end,
    canInteract = function()
      return true
    end,
  })
end
