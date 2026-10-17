

local isUpdatingCoords = false
local playerPed = PlayerPedId()
local zeroVector = vector3(0, 0, 0)

local SavedLocations = {}

local function AddLocation(locationName, locationCoords)
  if not locationName then
    return false
  end

  local coords
  if locationCoords then
    coords = vector2(locationCoords[2], locationCoords[1])
  else
    coords = GetEntityCoords(PlayerPedId())
  end

  local serverId = AwaitCallback("maps:addLocation", locationName, coords.x, coords.y)
  if not serverId then
    return false
  end

  local newLocation = {}
  newLocation.id = serverId
  newLocation.name = locationName
  newLocation.position = {coords.y, coords.x}

  local locationCount = #SavedLocations
  SavedLocations[locationCount + 1] = newLocation
  return newLocation
end

local function UpdatePlayerCoordinates()
  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed)
  local lastCoords = playerCoords

  SendReactMessage("maps:updateCoords", {
    x = math.floor(playerCoords.x + 0.5),
    y = math.floor(playerCoords.y + 0.5)
  })

  while true do
    if not isUpdatingCoords then
      break
    end

    local currentCoords = GetEntityCoords(playerPed)
    if phoneOpen then
      local distance = currentCoords - lastCoords
      if #distance > 1.0 then
        lastCoords = currentCoords
        SendReactMessage("maps:updateCoords", {
          x = math.floor(currentCoords.x + 0.5),
          y = math.floor(currentCoords.y + 0.5)
        })
      end
    end

    Wait(250)
  end
end

local function HandleNUIEvent(data, callback)
  local action = data.action
  debugprint("Maps:" .. (action or ""))

  if action == "getCurrentLocation" then
    local playerCoords = GetEntityCoords(PlayerPedId())
    callback({x = playerCoords.x, y = playerCoords.y})
  elseif action == "toggleUpdateCoords" then
    callback("ok")
    if isUpdatingCoords == data.toggle then
      return
    end

    isUpdatingCoords = data.toggle == true
    UpdatePlayerCoordinates()
  elseif action == "setWaypoint" then
    callback("ok")
    local waypointData = data.data
    local x = tonumber(waypointData.x)
    local y = tonumber(waypointData.y)

    if not x or not y then
      return
    end

    SetNewWaypoint(x / 1, y / 1)
  elseif action == "getLocations" then
    callback(SavedLocations)
  elseif action == "addLocation" then
    local locationData = AddLocation(data.name, data.location)
    callback(locationData)
  elseif action == "renameLocation" then
    local newName = data.name
    if newName then
      local serverResponse = AwaitCallback("maps:renameLocation", data.id, newName)
    end
    if not serverResponse then
      callback(false)
      return
    end

    for i = 1, #SavedLocations do
      if SavedLocations[i].id == data.id then
        SavedLocations[i].name = newName
        break
      end
    end
    callback(true)
  elseif action == "removeLocation" then
    local serverResponse = AwaitCallback("maps:removeLocation", data.id)
    if not serverResponse then
      callback(false)
      return
    end

    for i = 1, #SavedLocations do
      if SavedLocations[i].id == data.id then
        table.remove(SavedLocations, i)
        break
      end
    end
    callback(true)
  end
end

RegisterNUICallback("Maps", HandleNUIEvent)
