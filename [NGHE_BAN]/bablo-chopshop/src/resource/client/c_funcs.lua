Main = {
  Peds = {},
  Zones = {},
  Blips = {},
  contextElements = {},
  registeredMenus = {},
  currentZone = nil,
}

function Main:formatDisplayName(name)
  if type(name) ~= "string" or name == "" then
    return ""
  end

  return name:lower():gsub("^%l", string.upper)
end

function Main:getVehicleInfo(model)
  if not Config or type(Config.VehicleHashes) ~= "table" then
    Trace("Config or Config.VehicleHashes is not defined!")
    return {
      label = "",
      class = "",
    }
  end

  if type(model) ~= "string" or model == "" then
    return {
      label = "",
      class = "",
    }
  end

  local modelName = NormalizeVehicleModel(model)
  local vehicleData = Config.VehicleSpawnNames and Config.VehicleSpawnNames[modelName]

  if vehicleData then
    return {
      label = vehicleData.displayName or self:formatDisplayName(modelName),
      class = vehicleData.class or "",
    }
  end

  return {
    label = self:formatDisplayName(model),
    class = "",
  }
end

function Main:mapStatus(status)
  local normalizedStatus = tostring(status or ""):upper()
  if normalizedStatus == "COMPLETED" then
    return "completed"
  end

  if normalizedStatus == "ON_GOING" or normalizedStatus == "ONGOING" then
    return "ongoing"
  end

  return "available"
end

function Main:difficultyInfoFromCount(vehicleCount)
  local contractTypes = {}

  for contractKey, contractData in pairs(Config.Contracts or {}) do
    table.insert(contractTypes, {
      key = contractKey,
      min = tonumber(contractData.min) or 0,
    })
  end

  table.sort(contractTypes, function(left, right)
    if left.min == right.min then
      return tostring(left.key) < tostring(right.key)
    end

    return left.min < right.min
  end)

  local contractKey = GetContractTypeForCount(vehicleCount)
  local rank = 0

  for index, contractType in ipairs(contractTypes) do
    if contractType.key == contractKey then
      rank = index - 1
      break
    end
  end

  local contractConfig = Config.Contracts[contractKey] or {}
  return {
    key = contractKey,
    label = contractConfig.label or contractKey,
    rank = rank,
    total = #contractTypes,
  }
end

local function validVehicle(vehicle)
  return vehicle and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle)
end

local function isPartAlreadyMissing(vehicle, part)
  if part.type == "wheel" and part.wheelId then
    return IsVehicleWheelBrokenOff(vehicle, part.wheelId)
  end

  if part.door then
    return IsVehicleDoorDamaged(vehicle, part.door)
  end

  return false
end

local function partStateKey(part)
  return "CHOPPED_" .. part.bone
end

local function removeHeldEntity(self)
  if self.holdEntity and DoesEntityExist(self.holdEntity) then
    DetachEntity(self.holdEntity, true, true)
    SetEntityCollision(self.holdEntity, true, true)
    DeleteObject(self.holdEntity)
    self.holdEntity = nil
    Interaction.HideTextUI()

    SetTimeout(1000, function()
      ClearPedTasks(cache.ped)
    end)

    return true
  end

  self.holdEntity = nil
  return false
end

function Main:Init()
  if Main.__initialized then
    return
  end

  Main.__initialized = true

  for _, pedData in pairs(self.Peds) do
    if pedData.handle then
      DeletePed(pedData.handle)
    end
  end
  self.Peds = {}

  self.contextElements.START_CHOPPING = Target:addGlobalVehicle({
    label = Translate("START_CHOPPING"),
    icon = "fas fa-car-burst",
    action = function(vehicle)
      if not self:isVehicleInContract(vehicle) then
        Framework:Notify(Translate("CANNOT_SCRAP_NOT_IN_CONTRACT"), 3500)
        return
      end

      if not Framework:canChopVehicle(vehicle) then
        return
      end

      local requiredPolice = Config.PoliceOnDutyRequired or Config.PoliceRequired or 0
      if requiredPolice > 0 then
        local policeResult = TriggerServerCallback({
          eventName = eventName .. "server:getPoliceCount",
        })

        local currentPolice = (policeResult and policeResult.policeCount) or 0
        if currentPolice < requiredPolice then
          Framework:Notify((Translate("NOT_ENOUGH_POLICE")):format(requiredPolice), 5000, "error")
          return
        end
      end

      Framework:Notify(Translate("YOU_CAN_START_DISMANTLING"), 3500)
      self:setEntityStateBag(vehicle, {
        beingChopped = true,
        isChopped = false,
      })
      self:registerVehicle(vehicle)
    end,
    canInteract = function(vehicle)
      return self.currentZone ~= nil and self:canChopVehicle(vehicle)
    end,
  })

  for chopShopId, chopShop in pairs(Config.ChopShops) do
    if chopShop.blip then
      self:createBlip(chopShop)
    end

    if chopShop.ped then
      chopShop.ped.context = {
        menuElements = {
          {
            icon = "fas fa-car-crash",
            label = chopShop.ped.label or Translate("CHOPSHOP_BLIP_NAME"),
            action = function(ped)
              Main:openDialouge(ped, true)
            end,
            canInteract = function()
              return true
            end,
          },
        },
      }

      local pedObject = ConstructPed(chopShop.ped)
      if pedObject then
        table.insert(Main.Peds, pedObject)
        SetEntityInvincible(pedObject.handle, true)
        SetBlockingOfNonTemporaryEvents(pedObject.handle, true)
        FreezeEntityPosition(pedObject.handle, true)
        SetPedFleeAttributes(pedObject.handle, 0, false)
      end
    end

    local zone = lib.zones.poly({
      points = chopShop.points,
      thickness = 10.0,
      debug = false,
      onEnter = function()
        local result = TriggerServerCallback({
          eventName = eventName .. "server:enterZone",
          args = { chopShopId },
        })

        self.currentZone = chopShopId

        if result.status then
          self:onZoneEnter(result)
        else
          Trace("NO MENUS FOUND: " .. result.message)
        end
      end,
      onExit = function()
        if removeHeldEntity(self) then
          Framework:Notify(Translate("LEFT_CHOP_ZONE_MESSAGE"), 3500, "info")
        end

        TriggerServerEvent(eventName .. "server:leaveZone", self.currentZone)
        self.currentZone = nil

        for _, menu in pairs(self.registeredMenus) do
          if menu.menuId then
            Target:removeTargetEntity(menu.entity, menu.menuId)
          end
        end

        self.registeredMenus = {}
      end,
    })

    if zone then
      table.insert(self.Zones, zone)
    end
  end
end

function Main:createContextMenu(vehicle, vehicleData)
  local choppableParts = vehicleData.choppableParts or {}

  for _, part in pairs(choppableParts) do
    if part.bone then
      local menuId = Target:addTargetEntity(vehicle, {
        label = Translate("DISMANTLE") .. " " .. (part.label or part.bone),
        name = "dismantle_" .. part.bone,
        icon = "fas fa-hammer",
        bones = { part.bone },
        action = function(entity)
          self:startDismantlePart(entity, part)
        end,
        canInteract = function(entity)
          if not validVehicle(entity) then
            return false
          end

          local state = Entity(entity).state
          if state[partStateKey(part)] then
            return false
          end

          return not isPartAlreadyMissing(entity, part)
        end,
      })

      table.insert(self.registeredMenus, {
        menuId = menuId,
        entity = vehicle,
      })
    end
  end

  local finishMenuId = Target:addTargetEntity(vehicle, {
    label = Translate("VEHICLE_CHOPPED"),
    name = "finish_chopping",
    icon = "fas fa-check",
    action = function(entity)
      self:finishChoppingVehicle(entity)
    end,
    canInteract = function(entity)
      if not validVehicle(entity) then
        return false
      end

      if Config.DEBUG then
        return true
      end

      local partsToChop = Entity(entity).state.partsToChop
      return partsToChop and tonumber(partsToChop) < 1
    end,
  })

  table.insert(self.registeredMenus, {
    menuId = finishMenuId,
    entity = vehicle,
  })
end

function PoliceCall()
  TriggerEvent('mini-mdt:client:setCooldown', 30, "Bị cấm vào Red Zone do vừa trong tình huống phó bản khác")
  local plyCoords = GetEntityCoords(cache.ped or PlayerPedId(), false)
  if GetResourceState('ld-dispatch') == 'started' then
    exports['ld-dispatch']:sendDispatch(
      {
        title = "Rã Xe",
        code = "11-10B",
        values = {
          {
            text = "RÃ XE",
            icon = "fa-solid fa-earth-americas",
          },
          {
            text = "2 sao",
            icon = "fa-solid fa-hashtag",
          },
        },
        valuestwo = {}, -- DON'T TOUCH
        jobs = {"police"},
        active = false, -- DON'T TOUCH
        dispatchnumber = nil, -- DON'T TOUCH
        coords = plyCoords,
        blip = {
          blipid = 562,
          blipcolor = 1,
        }
      }
    )
  end
end

function Main:startDismantlePart(vehicle, part)
  if self.holdEntity and DoesEntityExist(self.holdEntity) then
    Framework:Notify(Translate("CANNOT_DISMANTLE_WHILE_HOLDING"), 3500)
    return
  end

  local boneIndex = GetEntityBoneIndexByName(vehicle, part.bone)
  if boneIndex == -1 then
    return
  end

  local boneCoords = GetWorldPositionOfEntityBone(vehicle, boneIndex) or GetEntityCoords(vehicle)
  local playerCoords = GetEntityCoords(cache.ped)
  if #(playerCoords - boneCoords) > 3.0 then
    Framework:Notify(Translate("TOO_FAR_TO_DISMANTLE"), 3500)
    return
  end

  local state = Entity(vehicle).state
  if state[partStateKey(part)] then
    Framework:Notify(Translate("ALREADY_DISMANTLED_PART"), 3500)
    return
  end

  local animation = Config.Animations[part.type]
  TaskTurnPedToFaceEntity(cache.ped, vehicle, 3000)

  if part.type == "wheel" then
    playWheelDismountAnimation(cache.ped)
  end

  playAnimation({
    ped = cache.ped,
    dict = animation.dict,
    lib = animation.lib,
    flag = 49,
  })

  self:setEntityStateBag(vehicle, {
    [partStateKey(part)] = true,
  })

  local chance = Config.PoliceCallChance or 30
  if math.random(100) <= chance then
    PoliceCall()
    Framework:Notify(Translate("POLICE_ALERTED_WARNING"), 5000, "error")
  end

  Framework:doProgress({
    text = Translate("DISMANTLING"),
    time = Config.DEBUG and 1000 or math.random(12000, 15000),
  }, function(success)
    if not success then
      self:setEntityStateBag(vehicle, {
        [partStateKey(part)] = false,
      })
      ClearPedTasks(cache.ped)
      return
    end

    if part.type == "wheel" and part.wheelId then
      BreakOffVehicleWheel(vehicle, part.wheelId, true, true, true, false)
    elseif part.door then
      SetVehicleDoorBroken(vehicle, part.door, true)
    end

    local partsToChop = Entity(vehicle).state.partsToChop or 1
    self:setEntityStateBag(vehicle, {
      partsToChop = tonumber(partsToChop) - 1,
    })

    TriggerServerEvent(eventName .. "server:addStress", Config.StressPerPart or 1.0)

    self:pickupCarPart(vehicle, part)
    ClearPedTasks(cache.ped)
  end)
end

function Main:finishChoppingVehicle(vehicle)
  if not self:isVehicleInContract(vehicle) then
    Framework:Notify(Translate("CANNOT_SCRAP_NOT_IN_CONTRACT"), 3500)
    return
  end

  local state = Entity(vehicle).state
  if state.isChopped then
    Framework:Notify(Translate("VEHICLE_ALREADY_CHOPPED"), 3500)
    return
  end

  Citizen.CreateThread(function()
    self:setEntityStateBag(vehicle, {
      isChopped = true,
      beingChopped = false,
    })

    Citizen.Wait(500)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent(eventName .. "server:deleteVehicle", netId, self.currentZone)

    Citizen.CreateThread(function()
      for attempt = 1, 10 do
        Citizen.Wait(500)
        if not DoesEntityExist(vehicle) then
          break
        end

        Trace("Vehicle still exists, retrying delete... Attempt " .. attempt)
        TriggerServerEvent(eventName .. "server:deleteVehicle", netId)
      end

      if DoesEntityExist(vehicle) then
        Trace("Failed to delete vehicle after 10 attempts.")
      end
    end)

    self:removeVehicleFromContract(vehicle)
    Framework:onVehicleChopped(vehicle)
  end)

  Trace("Finishing chop for vehicle: " .. tostring(vehicle))
end

function Main:pickupCarPart(_, part)
  local currentZone = self.currentZone
  if not currentZone or not Config.ChopShops[currentZone] then
    return
  end

  local playerCoords = GetEntityCoords(cache.ped)
  local model = GetHashKey(part.prop)

  LoadModels({ model })

  self.holdEntity = CreateObjectNoOffset(model, playerCoords.x, playerCoords.y, playerCoords.z + 5.0, true, true, false)
  SetEntityAsMissionEntity(self.holdEntity, true, true)
  NetworkRegisterEntityAsNetworked(self.holdEntity)

  local netId = 0
  for _ = 1, 50 do
    netId = NetworkGetNetworkIdFromEntity(self.holdEntity)
    if netId ~= 0 then
      break
    end

    Citizen.Wait(0)
  end

  if netId ~= 0 then
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    NetworkSetNetworkIdDynamic(netId, false)
  end

  for _ = 1, 100 do
    if NetworkHasControlOfEntity(self.holdEntity) then
      break
    end

    NetworkRequestControlOfEntity(self.holdEntity)
    Citizen.Wait(0)
  end

  Citizen.Wait(100)

  local alignment = self:getPropAlignment(part.prop)
  if not alignment then
    Trace("No prop alignment found for " .. part.prop .. ", using fallback")
  end

  AttachEntityToEntity(
    self.holdEntity,
    cache.ped,
    GetPedBoneIndex(cache.ped, alignment.bone),
    alignment.offset.x,
    alignment.offset.y,
    alignment.offset.z,
    alignment.rotation.x,
    alignment.rotation.y,
    alignment.rotation.z,
    true,
    true,
    false,
    true,
    1,
    true
  )

  SetModelAsNoLongerNeeded(model)

  playAnimation({
    ped = cache.ped,
    dict = "anim@heists@box_carry@",
    lib = "idle",
    flag = 49,
  })

  Citizen.CreateThread(function()
    local helpVisible = false
    local textUiOptions = {
      position = "bottom-center",
      icon = "fas fa-car",
    }

    Interaction.ShowTextUI(Translate("TURN_IN_PART"), textUiOptions)

    while self.holdEntity and DoesEntityExist(self.holdEntity) do
      Citizen.Wait(0)

      if not IsEntityPlayingAnim(cache.ped, "anim@heists@box_carry@", "idle", 3) then
        playAnimation({
          ped = cache.ped,
          dict = "anim@heists@box_carry@",
          lib = "idle",
          flag = 49,
        })
      end

      for _, control in ipairs({ 22, 23, 36, 24, 25, 47, 58, 263, 264, 257, 140, 141, 142, 143 }) do
        DisableControlAction(0, control, true)
      end

      local distance = #(GetEntityCoords(cache.ped) - Config.ChopShops[currentZone].dropOff)
      if distance < 200.0 then
        drawscriptmarker({
          type = 20,
          rotate = true,
          pos = Config.ChopShops[currentZone].dropOff + vector3(0.0, 0.0, 0.5),
          alpha = 200,
          color = vector3(255, 0, 0),
          size = vector3(0.3, 0.3, 0.3),
          bob = true,
        })

        if distance < 1.5 then
          if not helpVisible then
            Interaction.ShowTextUI(Translate("TURN_IN_PART_HELP"), textUiOptions)
            helpVisible = true
          end

          if IsControlJustReleased(0, 38) then
            removeHeldEntity(self)
            ClearPedTasksImmediately(cache.ped)
            Interaction.HideTextUI()
            return
          end
        elseif helpVisible then
          helpVisible = false
          Interaction.HideTextUI()
        end
      end
    end
  end)
end

function playWheelDismountAnimation()
  playAnimation({
    ped = cache.ped,
    dict = "move_crouch_proto",
    lib = "idle_intro",
    flag = 1,
  })
  Wait(1000)
end

function Main:getPropAlignment(prop)
  local alignment = Config.PropsAlignment[prop]
  if alignment then
    return alignment
  end

  Trace(("No alignment for '%s', using fallback"):format(prop))
  return {
    offset = {
      x = 0.0,
      y = -0.3,
      z = 0.0,
    },
    rotation = {
      x = 0.0,
      y = 0.0,
      z = 0.0,
    },
    bone = 4090,
  }
end

function Main:registerVehicle(vehicle)
  if not validVehicle(vehicle) then
    return
  end

  local choppableParts = {}

  for _, part in pairs(Config.Parts) do
    if part.bone then
      local boneIndex = GetEntityBoneIndexByName(vehicle, part.bone)
      if boneIndex ~= -1 and not isPartAlreadyMissing(vehicle, part) then
        table.insert(choppableParts, {
          label = part.label,
          bone = part.bone,
          door = part.door,
          wheelId = part.wheelId,
          type = part.type,
          prop = part.prop or "imp_prop_impexp_car_door_04a",
        })
      end
    end
  end

  SetVehicleUndriveable(vehicle, true)
  SetVehicleDoorsLocked(vehicle, 2)
  NetworkRequestControlOfEntity(vehicle)

  while not NetworkHasControlOfEntity(vehicle) do
    Citizen.Wait(0)
  end

  local state = Entity(vehicle).state
  state:set("choppableParts", choppableParts, true)
  state:set("partsToChop", TableLength(choppableParts), true)

  for _, part in pairs(choppableParts) do
    state:set(partStateKey(part), false, true)
  end

  self:createContextMenu(vehicle, {
    choppableParts = choppableParts,
  })

  TriggerServerEvent(eventName .. "server:registerVehicle", self.currentZone, {
    netId = NetworkGetNetworkIdFromEntity(vehicle),
    choppableParts = choppableParts,
  })
end

function Main:onZoneEnter(result)
  if not result.status then
    Framework:Notify((Translate("ERROR_FETCHING_ZONE")):format(result.message), 5000)
    Trace("Error entering zone: " .. result.message)
    return
  end

  if not result.vehicles then
    return
  end

  self.registeredMenus = {}

  for _, vehicleData in pairs(result.vehicles) do
    local entity = NetworkGetEntityFromNetworkId(vehicleData.netId)
    self:createContextMenu(entity, vehicleData)
  end
end

function Main:createBlip(chopShop)
  local blip = AddBlipForCoord(chopShop.dropOff.x, chopShop.dropOff.y, chopShop.dropOff.z)
  SetBlipSprite(blip, 527)
  SetBlipDisplay(blip, 4)
  SetBlipScale(blip, 0.8)
  SetBlipColour(blip, 17)
  SetBlipAsShortRange(blip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(Translate("CHOPSHOP_BLIP_NAME"))
  EndTextCommandSetBlipName(blip)
  table.insert(self.Blips, blip)
end

function Main:canChopVehicle(vehicle)
  if not validVehicle(vehicle) then
    return false
  end

  local state = Entity(vehicle).state
  if state.beingChopped or state.VEHICLE_VIN or state.VEHICLE_OWNER or state.isChopped then
    return false
  end

  return true
end

function Main:openDialouge(_, criminalStatus)
  self.dialogueCriminalStatus = criminalStatus
  self:showMainDialogue(criminalStatus)
end

local function goBackItem(self)
  return {
    icon = "fas fa-arrow-left",
    label = Translate("GO_BACK"),
    description = Translate("GO_BACK_DESC"),
    action = function()
      self:showMainDialogue(self.dialogueCriminalStatus or false)
    end,
  }
end

function Main:showMainDialogue()
  local elements = {}
  local dialogueData = TriggerServerCallback({
    eventName = eventName .. "server:getDialougeData",
    args = {},
  })

  if dialogueData.status then
    if dialogueData.hasContracts then
      table.insert(elements, {
        icon = "fas fa-trophy",
        label = Translate("TURN_IN_COMPLETED_CONTRACT"),
        description = Translate("TURN_IN_COMPLETED_CONTRACT_DESC"),
        action = function()
          self:giveReward()
        end,
      })
    end

    if dialogueData.user then
      local level = dialogueData.user.level or 1
      self.playerLevel = level

      local progress = 100
      if level < #Config.Levels and Config.Levels[level + 1] then
        local xp = dialogueData.user.xp or 0
        local nextLevelXp = Config.Levels[level + 1].xp or 1
        progress = math.min(100, math.max(0, xp / nextLevelXp * 100))
      end

      table.insert(elements, {
        icon = "fas fa-chart-simple",
        label = (Translate("LEVEL_LABEL")):format(level, #Config.Levels),
        description = (Translate("LEVEL_PROGRESS_DESC")):format(dialogueData.user.xp, math.floor(progress)),
        progress = progress,
      })
    end
  end

  local zoneId = self.currentZone
  if not zoneId or not Config.ChopShops[zoneId] then
    Framework:Notify(Translate("ERROR_OPENING_DIALOGUE_INVALID_ZONE"), 5000)
    Trace("Error opening dialogue: Invalid zone index")
    return
  end

  table.insert(elements, {
    icon = "fas fa-ranking-star",
    label = Translate("LEADERBOARDS"),
    description = Translate("LEADERBOARDS_DESC"),
    action = function()
      self:showLeaderboards()
    end,
  })

  table.insert(elements, {
    icon = "fas fa-chart-bar",
    label = Translate("MY_STATISTICS"),
    description = Translate("MY_STATISTICS_DESC"),
    action = function()
      self:showAnalytics()
    end,
  })

  table.insert(elements, {
    icon = "fas fa-file-contract",
    label = Translate("GET_NEW_CONTRACT"),
    description = Translate("GET_NEW_CONTRACT_DESC"),
    action = function()
      self:showContractMenu()
    end,
  })

  Menus:openMenu(Config.ChopShops[zoneId].ped.label, elements)
end

function Main:showContractMenu()
  local elements = { goBackItem(self) }
  local contractTypes = {}

  for contractKey, contractData in pairs(Config.Contracts) do
    table.insert(contractTypes, {
      key = contractKey,
      data = contractData,
    })
  end

  table.sort(contractTypes, function(left, right)
    if left.data.min == right.data.min then
      return tostring(left.key) < tostring(right.key)
    end

    return left.data.min < right.data.min
  end)

  local playerLevel = self.playerLevel or 1

  for _, contractType in ipairs(contractTypes) do
    local contractKey = contractType.key
    local contractData = contractType.data
    local translationKey = "CONTRACT_DIFFICULTY_" .. contractKey:upper()
    local label = Translate(translationKey)

    if label == translationKey or not label then
      label = contractData.label or contractKey
    end

    local vehicleRange
    if contractData.min == contractData.max then
      vehicleRange = tostring(contractData.min)
    else
      vehicleRange = tostring(contractData.min) .. "-" .. tostring(contractData.max)
    end

    local plural = contractData.max and contractData.max > 1 and "s" or ""
    local description = (Translate("CONTRACT_REQUIREMENTS")):format(vehicleRange, plural)
    local price = contractData.price
    if type(price) == "number" and price > 0 then
      description = description .. " | " .. (Translate("CONTRACT_FEE")):format(price)
    end
    local minLevelRequired = contractData.minLevelRequired or 1

    if playerLevel < minLevelRequired then
      table.insert(elements, {
        icon = "fas fa-lock",
        label = (Translate("CONTRACT_TITLE")):format(label),
        description = (Translate("CONTRACT_LOCKED_LEVEL")):format(minLevelRequired),
        disabled = true,
      })
    else
      table.insert(elements, {
        icon = "fas fa-clipboard-list",
        label = (Translate("CONTRACT_TITLE")):format(label),
        description = description,
        action = function()
          self:giveContract(contractKey)
        end,
      })
    end
  end

  Menus:openMenu(Translate("SELECT_CONTRACT_DIFFICULTY"), elements)
end

function Main:giveContract(contractType)
  local result = TriggerServerCallback({
    eventName = eventName .. "server:giveContract",
    args = { contractType },
  })

  if result.status then
    Framework:Notify(Translate("NEW_CONTRACT_GIVEN"), 5000, "success")
    Trace("New contract given: " .. json.encode(result.contract))
  else
    Framework:Notify(result.message, 5000, "error")
    Trace("Error giving contract: " .. result.message)
  end

  return result.vehicleModel
end

function Main:isVehicleInContract(vehicle)
  if not validVehicle(vehicle) then
    return false
  end

  local result = TriggerServerCallback({
    eventName = eventName .. "server:isVehicleInContract",
    args = { GetEntityModel(vehicle) },
  })

  return result.status
end

function Main:removeVehicleFromContract(vehicle)
  if not validVehicle(vehicle) then
    return
  end

  TriggerServerEvent(eventName .. "server:removeVehicleFromContract", GetEntityModel(vehicle))
end

function Main:giveReward()
  local result = TriggerServerCallback({
    eventName = eventName .. "server:giveReward",
    args = {},
  })

  if result.status then
    Framework:Notify(Translate("REWARD_SUBMIT_SUCCESS"), 7000, "success")
    Trace("Reward given: " .. json.encode(result.reward))
  else
    Framework:Notify((Translate("REWARD_SUBMIT_ERROR")):format(result.message), 5000, "error")
    Trace("Error giving reward: " .. result.message)
  end
end

function Main:showLeaderboards()
  local result = TriggerServerCallback({
    eventName = eventName .. "server:getLeaderboards",
    args = {},
  })

  if not result.status then
    Framework:Notify((Translate("FAILED_TO_LOAD_LEADERBOARDS")):format(result.message), 5000, "error")
    return
  end

  local elements = { goBackItem(self) }

  for rank, player in ipairs(result.leaderboard) do
    local playerName = player.firstname and player.lastname and (player.firstname .. " " .. player.lastname)
      or Translate("UNKNOWN_PLAYER")

    table.insert(elements, {
      icon = self:getRankIcon(rank),
      label = ("#%d %s"):format(rank, playerName),
      description = (Translate("LEADERBOARD_PLAYER_DESC")):format(
        player.level or 1,
        player.xp or 0,
        player.finished_contracts or 0
      ),
    })
  end

  Menus:openMenu(Translate("LEADERBOARDS_TITLE"), elements)
end

function Main:getRankIcon(rank)
  if rank == 1 then
    return "fas fa-trophy"
  elseif rank == 2 then
    return "fas fa-medal"
  elseif rank == 3 then
    return "fas fa-award"
  end

  return "fas fa-user"
end

function Main:showAnalytics()
  local result = TriggerServerCallback({
    eventName = eventName .. "server:getPlayerAnalytics",
    args = {},
  })

  if not result.status then
    Framework:Notify((Translate("FAILED_TO_LOAD_STATS")):format(result.message), 5000, "error")
    return
  end

  local analytics = result.analytics
  local elements = { goBackItem(self) }

  table.insert(elements, {
    icon = "fas fa-clipboard-check",
    label = (Translate("CONTRACTS_COMPLETED")):format(analytics.contracts_completed or 0),
    description = Translate("CONTRACTS_COMPLETED_DESC"),
  })

  table.insert(elements, {
    icon = "fas fa-car-crash",
    label = (Translate("VEHICLES_CHOPPED")):format(analytics.vehicles_chopped or 0),
    description = Translate("VEHICLES_CHOPPED_DESC"),
  })

  if analytics.rank then
    table.insert(elements, {
      icon = self:getRankIcon(analytics.rank),
      label = (Translate("LEADERBOARD_RANK")):format(analytics.rank),
      description = Translate("LEADERBOARD_RANK_DESC"),
    })
  end

  Menus:openMenu(Translate("MY_STATISTICS_TITLE"), elements)
end

function Main:setEntityStateBag(entity, values)
  if not entity or not DoesEntityExist(entity) then
    return
  end

  if IsEntityAVehicle(entity) then
    Statebags:bulkSetVehicleStateBag(entity, values, true)
  else
    Statebags:bulkSetEntityStateBag(entity, values, true)
  end
end
