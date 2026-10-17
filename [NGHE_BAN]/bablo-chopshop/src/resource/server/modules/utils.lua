function SpawnVehicle(model, location)
  local vehicle = CreateVehicleServerSetter(
    model,
    "automobile",
    location.x,
    location.y,
    location.z,
    location.w
  )

  local attempts = 0
  while not DoesEntityExist(vehicle) and attempts < 50 do
    attempts = attempts + 1
    Citizen.Wait(100)
  end

  if attempts >= 50 then
    return
  end

  local driver = GetPedInVehicleSeat(vehicle, -1)
  if driver and DoesEntityExist(driver) then
    DeleteEntity(driver)
  end

  return vehicle
end

function GetEmptyParkingSpot(parkingSpots)
  if not parkingSpots or #parkingSpots == 0 then
    return nil
  end

  local allVehicles = GetAllVehicles()
  for _, parkingSpot in ipairs(parkingSpots) do
    local spotCoords = vector3(parkingSpot.x, parkingSpot.y, parkingSpot.z)
    local isOccupied = false

    for _, veh in ipairs(allVehicles) do
      if DoesEntityExist(veh) then
        local vehCoords = GetEntityCoords(veh)
        if #(vehCoords - spotCoords) < 3.0 then
          isOccupied = true
          break
        end
      end
    end

    if not isOccupied then
      return parkingSpot
    end
  end

  return parkingSpots[1]
end
