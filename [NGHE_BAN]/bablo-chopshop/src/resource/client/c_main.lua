local resourceName = GetCurrentResourceName()

if resourceName ~= "bablo-chopshop" then
  error("Resource name must be 'bablo-chopshop'")
  return
end

local function initializeMain()
  if not Main.__initialized then
    Main:Init()
    Main.__initialized = true

    Citizen.SetTimeout(1500, function()
      local activeMissionResult = TriggerServerCallback({
        eventName = eventName .. "server:getActiveMission",
      })
      if activeMissionResult and activeMissionResult.status and activeMissionResult.mission then
        StartVehicleSearch(activeMissionResult.mission)
      end
    end)
  end
end

Citizen.CreateThread(function()
  Citizen.Wait(1000)
  ClearPedTasks(PlayerPedId())

  if Framework:isCharacterLoaded() then
    initializeMain()
  end

  if Config.DEBUG then
    RegisterCommand("deletvdoor", function(_, args)
      local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
      if vehicle and DoesEntityExist(vehicle) then
        local doorIndex = tonumber(args[1]) or 0
        if doorIndex >= 0 and doorIndex < 8 then
          SetVehicleDoorBroken(vehicle, doorIndex, true)
        end
      end
    end, false)
  end

  RegisterCommand("bchop_debug_contracts", function()
    SendNUIMessage({
      action = "SET_VISIBLE",
      data = true,
    })

    SendNUIMessage({
      action = "CONTRACTS_OPEN",
      data = {
        difficultyKey = "medium",
        difficultyLabel = "Hoá đơn thường",
        difficultyRank = 1,
        difficultyTotal = 3,
        vehiclesLeft = 2,
        activeTargetModel = "jackal",
        contracts = {
          {
            id = "jackal",
            label = "Jackal",
            class = "Coupes",
            knownLocation = "",
            model = "jackal",
            status = "ongoing",
          },
          {
            id = "ninef",
            label = "9F",
            class = "Sports",
            knownLocation = "",
            model = "ninef",
            status = "ongoing",
          },
          {
            id = "sultan",
            label = "Karin Sultan",
            class = "Sports",
            knownLocation = "",
            model = "sultan",
            status = "completed",
          },
        },
      },
    })

    SetNuiFocus(true, true)
  end, false)
end)

RegisterNUICallback("locales/get", function(_, cb)
  cb({
    code = Config.Locale,
    dict = Locale.t or {},
  })
end)

RegisterNUICallback("contracts/close", function(_, cb)
  SetNuiFocus(false, false)
  SendNUIMessage({
    action = "SET_VISIBLE",
    data = false,
  })
  cb({ ok = true })
end)

RegisterNUICallback("contracts/startSearch", function(data, cb)
  local model = data and data.model
  if not model then
    cb({ ok = false, message = "Mẫu xe không hợp lệ" })
    return
  end

  local result = TriggerServerCallback({
    eventName = eventName .. "server:startSearchVehicle",
    args = { model },
  })

  if result and result.status then
    cb({ ok = true, activeModel = model })
  else
    cb({ ok = false, message = (result and result.message) or "Không thể bắt đầu tìm kiếm!" })
  end
end)

RegisterNUICallback("contracts/stopSearch", function(_, cb)
  local result = TriggerServerCallback({
    eventName = eventName .. "server:stopSearchVehicle",
  })
  cb({ ok = true })
end)


RegisterNetEvent(eventName .. "client:characterLoaded")
AddEventHandler(eventName .. "client:characterLoaded", initializeMain)

RegisterNetEvent(eventName .. "client:updateVehicles")
AddEventHandler(eventName .. "client:updateVehicles", function(chopShopId, vehicles)
  Trace("updateVehicles", chopShopId, vehicles)

  if Main.currentZone ~= chopShopId then
    return
  end

  local function isVehicleRegistered(entity)
    for _, menu in pairs(Main.registeredMenus) do
      if menu.entity == entity then
        return true
      end
    end

    return false
  end

  for _, vehicleData in pairs(vehicles) do
    local entity = NetworkGetEntityFromNetworkId(vehicleData.netId)
    if entity and DoesEntityExist(entity) and not isVehicleRegistered(entity) then
      Main:createContextMenu(entity, vehicleData)
    end
  end
end)

RegisterNetEvent(eventName .. "client:levelUp")
AddEventHandler(eventName .. "client:levelUp", function(data)
  Framework:Notify((Translate("LEVEL_UP")):format(data.newLevel), 5000, "success")
end)

RegisterNetEvent(eventName .. "client:levelDown")
AddEventHandler(eventName .. "client:levelDown", function(data)
  Framework:Notify((Translate("LEVEL_DOWN")):format(data.newLevel), 5000, "error")
end)

RegisterNetEvent(eventName .. "client:useContractItem")
AddEventHandler(eventName .. "client:useContractItem", function(item)
  local metadata = item and item.metadata or {}
  local vehicles = metadata.vehicles or {}
  local completedVehicles = metadata.completed_vehicles or {}
  local contracts = {}
  local vehiclesLeft = 0

  local function addContract(model, statusData)
    local status = Main:mapStatus(statusData)
    local normalizedModel = NormalizeVehicleModel(model)
    local vehicleInfo = Main:getVehicleInfo(normalizedModel)

    table.insert(contracts, {
      id = tostring(normalizedModel),
      label = vehicleInfo.label,
      class = vehicleInfo.class,
      knownLocation = "",
      model = normalizedModel,
      status = status,
    })

    return status
  end

  for model, statusData in pairs(vehicles) do
    if addContract(model, statusData) ~= "completed" then
      vehiclesLeft = vehiclesLeft + 1
    end
  end

  for model, statusData in pairs(completedVehicles) do
    addContract(model, statusData)
  end

  local originalCount = tonumber(metadata.original_count) or tonumber(metadata.vehicle_count) or 0
  local difficultyInfo = Main:difficultyInfoFromCount(originalCount)
  local currentSearchingModel = GetActiveSearchModel and GetActiveSearchModel() or nil

  SendNUIMessage({
    action = "SET_VISIBLE",
    data = true,
  })

  SendNUIMessage({
    action = "CONTRACTS_OPEN",
    data = {
      difficultyKey = difficultyInfo.key,
      difficultyLabel = difficultyInfo.label,
      difficultyRank = difficultyInfo.rank,
      difficultyTotal = difficultyInfo.total,
      vehiclesLeft = vehiclesLeft,
      activeTargetModel = currentSearchingModel,
      contracts = contracts,
    },
  })

  SetNuiFocus(true, true)
end)

AddEventHandler("onResourceStop", function(stoppedResource)
  if stoppedResource ~= resourceName then
    return
  end

  for _, pedData in pairs(Main.Peds) do
    if pedData.handle then
      DeletePed(pedData.handle)
    end
  end
  Main.Peds = {}

  for _, blip in pairs(Main.Blips) do
    RemoveBlip(blip)
  end
  Main.Blips = {}

  if TableLength(Main.contextElements) > 0 then
    for _, contextElement in pairs(Main.contextElements) do
      if contextElement == "START_CHOPPING" then
        Target:removeGlobalVehicle(contextElement)
      else
        Target:removeTargetEntity(contextElement)
      end
    end

    Main.contextElements = {}
  end

  if Main.holdEntity then
    DeleteEntity(Main.holdEntity)
    Main.holdEntity = nil
  end

  if StopVehicleSearch then
    StopVehicleSearch()
  end
end)
