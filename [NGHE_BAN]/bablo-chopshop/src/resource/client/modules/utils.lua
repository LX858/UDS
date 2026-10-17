function SpawnVehicle(model, vehicleData)
  LoadModels({ model })

  local position = vehicleData.Position
  local heading = GetHeadingFromVector_2d(position.OrientX, position.OrientY)
  local vehicle = CreateVehicle(model, position.X, position.Y, position.Z, heading, true)

  SetEntityAsMissionEntity(vehicle, true, true)
  Entity(vehicle).state:set("CHOP_MISSION", true, true)
  CleanupModels({ model })

  return vehicle
end

function CleanupModels(models)
  for _, model in ipairs(models) do
    if IsModelValid(model) then
      SetModelAsNoLongerNeeded(model)
    else
      RemoveAnimDict(model)
    end
  end
end

function LoadModels(models)
  for _, model in ipairs(models) do
    if IsModelValid(model) then
      while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
      end
    elseif DoesAnimDictExist(model) then
      while not HasAnimDictLoaded(model) do
        RequestAnimDict(model)
        Citizen.Wait(10)
      end
    else
      Trace("Tried loading a non-existent model:", model)
    end
  end
end

function loadanimDict(animDict)
  RequestAnimDict(animDict)

  while not HasAnimDictLoaded(animDict) do
    Citizen.Wait(100)
  end
end

function playAnimation(data)
  if IsEntityPlayingAnim(data.ped, data.dict, data.lib, 3) then
    return
  end

  data.flag = data.flag or 49
  data.time = data.time or -1

  loadanimDict(data.dict)
  TaskPlayAnim(data.ped, data.dict, data.lib, 2.0, -1.0, data.time, data.flag, 0, 0, 0, 0)
end

function drawscriptmarker(options)
  local markerType = options.type or 1
  local position = options.pos

  if not position or not position.x or not position.y or not position.z then
    return
  end

  local size = options.size or vector3(1.0, 1.0, 1.0)
  local color = options.color or { x = 255, y = 255, z = 255 }
  local alpha = options.alpha or 255
  local bob = options.bob or false
  local rotate = options.rotate or false

  DrawMarker(
    markerType,
    position.x,
    position.y,
    position.z,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    size.x,
    size.y,
    size.z,
    color.x,
    color.y,
    color.z,
    alpha,
    bob,
    true,
    2,
    rotate,
    nil,
    nil,
    false
  )
end

function PlayAnimation(ped, animDict, animName, options)
  if animDict then
    Citizen.CreateThread(function()
      RequestAnimDict(animDict)

      while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
      end

      if options == nil then
        TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, 1.0, 0, 0, false, false, false)
      else
        TaskPlayAnim(
          ped,
          animDict,
          animName,
          options.speed or 1.0,
          options.speedMultiplier or -1.0,
          options.duration or 1.0,
          options.flag or 0,
          options.playbackRate or 0,
          false,
          false,
          false
        )
      end

      RemoveAnimDict(animDict)
    end)
  else
    TaskStartScenarioInPlace(ped, animName, 0, true)
  end
end

function RequestNetworkControl(entities)
  for _, entity in ipairs(entities) do
    while not NetworkHasControlOfEntity(entity) do
      NetworkRequestControlOfEntity(entity)
      Citizen.Wait(0)
    end
  end
end
