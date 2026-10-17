local currentVehicle = nil
local vehicleType = nil

local currentCallsigns = {
  front = {},
  back = {},
  frontCount = {},
  backCount = {}
}

local previousCallsigns = {
  front = {},
  back = {},
}


local function checkVehicle(vehicle)
  if not vehicle or vehicle == 0 then
    return false
  end

  local vehicleModel = GetEntityModel(vehicle)

  for i = 1, #Config.Vehicles do
    if vehicleModel == joaat(Config.Vehicles[i]) then
      return 'oldGen'
    end
  end

  for i = 1, #Config.NewGenVehicles do
    if vehicleModel == joaat(Config.NewGenVehicles[i]) then
      return 'newGen'
    end
  end

  return false
end





RegisterNetEvent('nk_callsigns:client:openMenu', function()
  currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
  vehicleType = checkVehicle(currentVehicle)

  if not vehicleType then
    return lib.notify({
      title = 'Error',
      description = 'You must be in a vehicle to set a callsign.',
      type = 'error'
    })
  end

  if not Config.hasJob() then
    return lib.notify({
      title = 'Error',
      description = 'You do not have permission to set a callsign.',
      type = 'error'
    })
  end

  SetVehicleModKit(currentVehicle, 0)

  currentCallsigns.front = {
    ['8'] = GetVehicleMod(currentVehicle, 8),
    ['10'] = GetVehicleMod(currentVehicle, 10),
    ['9'] = GetVehicleMod(currentVehicle, 9)
  }
  previousCallsigns.front = currentCallsigns.front

  currentCallsigns.frontCount = {
    ['8'] = GetNumVehicleMods(currentVehicle, 8) - 1,
    ['10'] = GetNumVehicleMods(currentVehicle, 10) - 1,
    ['9'] = GetNumVehicleMods(currentVehicle, 9) - 1
  }

  if vehicleType == 'oldGen' then
    currentCallsigns.back = {}
    previousCallsigns.back = currentCallsigns.back

    currentCallsigns.backCount = {}
  elseif vehicleType == 'newGen' then
    currentCallsigns.back = {
      ['38'] = GetVehicleMod(currentVehicle, 38),
      ['25'] = GetVehicleMod(currentVehicle, 25)
    }
    previousCallsigns.back = currentCallsigns.back

    currentCallsigns.backCount = {
      ['38'] = GetNumVehicleMods(currentVehicle, 38) - 1,
      ['25'] = GetNumVehicleMods(currentVehicle, 25) - 1
    }
  end


  SendNUIMessage({
    eventName = "openMenu",
    payload = {
      currentCallsigns = currentCallsigns,
      locales = Config.Locale,
      vehicleType = vehicleType
    },
  })

  SetNuiFocus(true, true)
end)

RegisterNUICallback("closeMenu", function(_, cb)
  SetNuiFocus(false, false)

  if not currentVehicle then
    cb(0)
    return
  end

  for index, value in pairs(previousCallsigns.front) do
    local modId = tonumber(index) or 0
    SetVehicleMod(currentVehicle, modId, value, false)
  end

  for index, value in pairs(previousCallsigns.back) do
    local modId = tonumber(index) or 0
    SetVehicleMod(currentVehicle, modId, value, false)
  end

  currentVehicle = nil

  vehicleType = nil

  currentCallsigns = {
    front = {},
    back = {},
    frontCount = {},
    backCount = {}
  }

  previousCallsigns = {
    front = {},
    back = {},
  }

  cb(1)
end)

RegisterNUICallback("updateCallsign", function(data, cb)
  if not currentVehicle then
    cb(0)
    return
  end

  SetVehicleMod(currentVehicle, data.index, data.value, false)

  cb(1)
end)

RegisterNUICallback("revertCallsigns", function(_, cb)
  if not currentVehicle then
    cb(0)
    return
  end

  for index, value in pairs(previousCallsigns.front) do
    currentCallsigns.front[index] = value
    local modId = tonumber(index) or 0
    SetVehicleMod(currentVehicle, modId, value, false)
  end

  for index, value in pairs(previousCallsigns.back) do
    currentCallsigns.back[index] = value
    local modId = tonumber(index) or 0
    SetVehicleMod(currentVehicle, modId, value, false)
  end

  cb(currentCallsigns)
end)

RegisterNUICallback("saveCallsigns", function(_, cb)
  currentVehicle = nil

  vehicleType = nil

  currentCallsigns = {
    front = {},
    back = {},
    frontCount = {},
    backCount = {}
  }

  previousCallsigns = {
    front = {},
    back = {},
  }

  SetNuiFocus(false, false)

  cb(1)
end)
