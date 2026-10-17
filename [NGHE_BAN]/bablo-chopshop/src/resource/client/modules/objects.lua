if not IsDuplicityVersion() then
  return
end

Object = {}
Object.__index = Object

local resourceName = GetCurrentResourceName()

function Object:new(options)
  assert(
    type(options) == "table",
    ("options must be of type table. Got %s"):format(type(options))
  )

  local object
  object = setmetatable({
    eventHandler = AddEventHandler("onResourceStop", function(stoppedResource)
      if stoppedResource == resourceName then
        object:destroy()
      end
    end),
  }, Object)

  local model = options.model
  if type(model) == "number" then
    object.hash = model
  elseif type(model) == "string" then
    object.hash = joaat(model)
  end

  object.location = options.location
  object.rotation = type(options.rotation) == "vector3" and options.rotation or vector3(0, 0, 0)
  object.rotationOrder = type(options.rotationOrder) == "number" and options.rotationOrder or 2

  local created = promise.new()

  Citizen.CreateThread(function()
    object.handle = CreateObjectNoOffset(
      object.hash,
      object.location.x,
      object.location.y,
      object.location.z,
      true,
      true,
      false
    )

    while not DoesEntityExist(object.handle) do
      Citizen.Wait(50)
    end

    SetEntityRotation(
      object.handle,
      object.rotation.x,
      object.rotation.y,
      object.rotation.z,
      object.rotationOrder,
      false
    )

    created:resolve(object.handle)
  end)

  Citizen.Await(created)

  return object
end

function Object:exists()
  return DoesEntityExist(self.handle)
end

function Object:destroy()
  if self.eventHandler then
    RemoveEventHandler(self.eventHandler)
  end

  if self:exists() then
    DeleteEntity(self.handle)
  end
end
