local trailerOffsets = {
  { x = 0.0, y = 4.9, z = 0.45 }, { x = 0.0, y = 3.2, z = 0.45 },
  { x = 0.0, y = 1.5, z = 0.45 }, { x = 0.0, y = -0.2, z = 0.45 },
  { x = 0.0, y = -1.9, z = 0.45 }, { x = 0.0, y = -3.5, z = 0.45 },
  { x = 0.0, y = -5.2, z = 0.45 }, { x = 0.0, y = 4.9, z = 1.45 },
  { x = 0.0, y = 3.2, z = 1.45 }, { x = 0.0, y = 1.5, z = 1.45 },
  { x = 0.0, y = -0.2, z = 1.45 }, { x = 0.0, y = -1.9, z = 1.45 },
  { x = 0.0, y = -3.5, z = 1.45 }, { x = 0.0, y = -5.2, z = 1.45 },
  { x = 0.0, y = 4.9, z = 2.45 }, { x = 0.0, y = 3.2, z = 2.45 },
  { x = 0.0, y = 1.5, z = 2.45 }, { x = 0.0, y = -0.2, z = 2.45 },
  { x = 0.0, y = -1.9, z = 2.45 }, { x = 0.0, y = -3.5, z = 2.45 },
  { x = 0.0, y = -5.2, z = 2.45 },
}

local boxTruckOffsets = {
  { x = -0.55, y = -0.75, z = 0.25 }, { x = 0.55, y = -0.75, z = 0.25 },
  { x = -0.55, y = -1.75, z = 0.25 }, { x = 0.55, y = -1.75, z = 0.25 },
  { x = -0.55, y = -2.75, z = 0.25 }, { x = 0.55, y = -2.75, z = 0.25 },
  { x = -0.55, y = -1.25, z = 1.15 }, { x = 0.55, y = -1.25, z = 1.15 },
}

local INTERACTION_CONTROL = 38

local function rearLoadingOffset(mission)
  if mission.vehicleMode ~= "rental" or mission.cargoMode == "tanker" then return nil end
  local fleet = Config.Fleet
  return fleet and fleet.RearLoading and fleet.RearLoading[mission.vehicleModel]
end

local function usesTrailer(mission)
  return mission.cargoMode == "tanker" or mission.vehicleMode ~= "rental"
    or (Config.Fleet.TrailerRentals or {})[mission.vehicleModel] == true
end

local function missionRoute(mission)
  if mission.orderKind == "market" then
    local pickup = Config.Routes[mission.routeIndex]
    local destination = Config.Routes[mission.deliveryRouteIndex]
    if not pickup or not destination then return nil end
    return { pickup = pickup.pickup, delivery = destination.delivery }
  end
  if mission.orderKind ~= "business" then return Config.Routes[mission.routeIndex] end
  local business = Config.BusinessOrders.Businesses[mission.businessId]
  return {
    pickup = Config.BusinessOrders.Pickup,
    delivery = business and business.delivery or {
      parking = vector4(
        mission.deliveryCoords.x, mission.deliveryCoords.y,
        mission.deliveryCoords.z, mission.deliveryCoords.w
      ),
      packages = vector3(
        mission.deliveryCoords.x, mission.deliveryCoords.y, mission.deliveryCoords.z
      ),
      forklifts = {},
    },
  }
end

local function distance(first, second, ignoreZ)
  if not first or not second then return math.huge end
  local x = first.x - second.x
  local y = first.y - second.y
  local z = ignoreZ and 0 or first.z - second.z
  return math.sqrt(x * x + y * y + z * z)
end

local function showHelp(message)
  BeginTextCommandDisplayHelp("STRING")
  AddTextComponentSubstringPlayerName(message)
  EndTextCommandDisplayHelp(0, false, true, 1)
end

local function drawWorldMarker(coords, red, green, blue, scale)
  DrawMarker(
    2,
    coords.x, coords.y, coords.z + 0.35,
    0.0, 0.0, 0.0,
    0.0, 180.0, 0.0,
    scale or 0.45, scale or 0.45, scale or 0.45,
    red or 238, green or 179, blue or 61, 210,
    true, true, 0, false,
    ---@diagnostic disable-next-line: param-type-mismatch
    nil, nil, false
  )
end

local function parkingPoint(target, localX, localY)
  local heading = math.rad(target.w or 0.0)
  return vector3(
    target.x + localX * math.cos(heading) - localY * math.sin(heading),
    target.y + localX * math.sin(heading) + localY * math.cos(heading),
    target.z + 0.08
  )
end

local function drawParkingMarker(target, red, green)
  local halfWidth, halfLength = 1.4, 4.0
  local rearLeft = parkingPoint(target, -halfWidth, -halfLength)
  local rearRight = parkingPoint(target, halfWidth, -halfLength)
  local frontLeft = parkingPoint(target, -halfWidth, halfLength)
  local frontRight = parkingPoint(target, halfWidth, halfLength)
  local blue, alpha = 0, 220
  DrawLine(rearLeft.x, rearLeft.y, rearLeft.z,
    rearRight.x, rearRight.y, rearRight.z, red, green, blue, alpha)
  DrawLine(rearRight.x, rearRight.y, rearRight.z,
    frontRight.x, frontRight.y, frontRight.z, red, green, blue, alpha)
  DrawLine(frontRight.x, frontRight.y, frontRight.z,
    frontLeft.x, frontLeft.y, frontLeft.z, red, green, blue, alpha)
  DrawLine(frontLeft.x, frontLeft.y, frontLeft.z,
    rearLeft.x, rearLeft.y, rearLeft.z, red, green, blue, alpha)
  DrawMarker(
    28,
    target.x, target.y, target.z + 0.12,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    0.24, 0.24, 0.24,
    red, green, blue, alpha,
    false, false, 2, false,
    ---@diagnostic disable-next-line: param-type-mismatch
    nil, nil, false
  )
end

local function deliverySlot(route, index)
  local base = route.delivery.packages
  local localIndex = (index - 1) % 9
  local row = math.floor(localIndex / 3)
  local column = localIndex % 3
  local stack = math.floor((index - 1) / 9)
  return vector3(base.x + (column - 1) * 2.0, base.y + (row - 1) * 2.0, base.z + stack - 1.0)
end

local function removeBlipSafe(blip)
  if blip and blip ~= 0 and DoesBlipExist(blip) then
    ---@diagnostic disable-next-line: redundant-parameter
    RemoveBlip(blip)
  end
end

local function createCoordBlip(coords, label, sprite, colour, routeEnabled)
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, sprite)
  SetBlipColour(blip, colour)
  SetBlipScale(blip, 0.8)
  SetBlipAsShortRange(blip, not routeEnabled)
  if routeEnabled then
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, colour)
  end
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(label)
  EndTextCommandSetBlipName(blip)
  return blip
end

local function createEntityBlip(entity, label, sprite, colour)
  if not entity or entity == 0 or not DoesEntityExist(entity) then return 0 end
  local blip = AddBlipForEntity(entity)
  SetBlipSprite(blip, sprite)
  SetBlipColour(blip, colour)
  SetBlipScale(blip, 0.75)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(label)
  EndTextCommandSetBlipName(blip)
  return blip
end

local function netVehicle(netId)
  if not netId or netId <= 0 or not NetworkDoesEntityExistWithNetworkId(netId) then return 0 end
  return NetToVeh(netId)
end

local function netObject(netId)
  if not netId or netId <= 0 or not NetworkDoesEntityExistWithNetworkId(netId) then return 0 end
  return NetToObj(netId)
end

local function playerForklift()
  local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
  if vehicle == 0 or GetEntityModel(vehicle) ~= GetHashKey("forklift")
    or GetPedInVehicleSeat(vehicle, -1) ~= PlayerPedId() then return 0 end
  return vehicle
end

---@class LRClient.TruckerMissionInput
---@field snapshot LRTruckerStateSnapshotMission
---@field advance fun(request: LRTruckerNetClientToServerAdvanceRequest): unknown
---@field packageAction fun(request: LRTruckerNetClientToServerPackageActionRequest): unknown

---@class LRClient.TruckerMission : LRShared.ClassInstance
---@field snapshot LRTruckerStateSnapshotMission
---@field advance fun(request: LRTruckerNetClientToServerAdvanceRequest): unknown
---@field packageAction fun(request: LRTruckerNetClientToServerPackageActionRequest): unknown
---@field routeBlip integer
---@field vehicleBlips table<string, integer>
---@field vehicleNetIds table<string, integer>
---@field blipMissionId string
---@field blipStep integer
---@field entityRevision integer
---@field loopRevision integer
---@field requestPending boolean
---@field lastRequestAt integer
---@field stopped boolean
---@field ClearBlips fun(self: LRClient.TruckerMission)
---@field UpdateVehicleBlip fun(self: LRClient.TruckerMission, name: string, netId: integer, entity: integer, label: string, sprite: integer, colour: integer)
---@field WaitForNetEntity fun(self: LRClient.TruckerMission, netId: integer, vehicle: boolean, revision: integer): integer
---@field RequestControl fun(self: LRClient.TruckerMission, entity: integer): boolean
---@field AttachToForklift fun(self: LRClient.TruckerMission, packageEntity: integer, forklift: integer)
---@field SyncEntities fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission)
---@field UpdateRouteBlip fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission)
---@field ApplySnapshot fun(self: LRClient.TruckerMission, snapshot: LRTruckerStateSnapshotMission)
---@field AttemptGameplay fun(self: LRClient.TruckerMission, action: function, payload: table)
---@field CarriedPackage fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission, localSource: integer): LRTruckerStateSnapshotMissionPackagesItem?
---@field ClosestPackage fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission, forkliftCoords: vector3, expectedState: string): LRTruckerStateSnapshotMissionPackagesItem?, number, integer
---@field HandlePackages fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission, route: table)
---@field TrailerParked fun(self: LRClient.TruckerMission, trailer: integer, target: vector4): boolean
---@field HandleGameplay fun(self: LRClient.TruckerMission)
---@field RunGameplayLoop fun(self: LRClient.TruckerMission, revision: integer)
---@field Start fun(self: LRClient.TruckerMission)
---@field Stop fun(self: LRClient.TruckerMission)

---@class LRClient.TruckerMissionClass : LRShared.Class<LRClient.TruckerMission, LRClient.TruckerMissionInput>
---@field init fun(self: LRClient.TruckerMission, input: LRClient.TruckerMissionInput)
---@field ClearBlips fun(self: LRClient.TruckerMission)
---@field UpdateVehicleBlip fun(self: LRClient.TruckerMission, name: string, netId: integer, entity: integer, label: string, sprite: integer, colour: integer)
---@field WaitForNetEntity fun(self: LRClient.TruckerMission, netId: integer, vehicle: boolean, revision: integer): integer
---@field RequestControl fun(self: LRClient.TruckerMission, entity: integer): boolean
---@field AttachToForklift fun(self: LRClient.TruckerMission, packageEntity: integer, forklift: integer)
---@field SyncEntities fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission)
---@field UpdateRouteBlip fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission)
---@field ApplySnapshot fun(self: LRClient.TruckerMission, snapshot: LRTruckerStateSnapshotMission)
---@field AttemptGameplay fun(self: LRClient.TruckerMission, action: function, payload: table)
---@field CarriedPackage fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission, localSource: integer): LRTruckerStateSnapshotMissionPackagesItem?
---@field ClosestPackage fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission, forkliftCoords: vector3, expectedState: string): LRTruckerStateSnapshotMissionPackagesItem?, number, integer
---@field HandlePackages fun(self: LRClient.TruckerMission, mission: LRTruckerStateSnapshotMission, route: table)
---@field TrailerParked fun(self: LRClient.TruckerMission, trailer: integer, target: vector4): boolean
---@field HandleGameplay fun(self: LRClient.TruckerMission)
---@field RunGameplayLoop fun(self: LRClient.TruckerMission, revision: integer)
---@field Start fun(self: LRClient.TruckerMission)
---@field Stop fun(self: LRClient.TruckerMission)

---@type LRClient.TruckerMissionClass
local TruckerMission = LR.Class:Define("ClientTruckerMission")

---@param self LRClient.TruckerMission
---@param input LRClient.TruckerMissionInput
function TruckerMission:init(input)
  self.snapshot = input.snapshot
  self.advance = input.advance
  self.packageAction = input.packageAction
  self.routeBlip = 0
  self.vehicleBlips = {}
  self.vehicleNetIds = {}
  self.blipMissionId = ""
  self.blipStep = 0
  self.entityRevision = 0
  self.loopRevision = 0
  self.requestPending = false
  self.lastRequestAt = 0
  self.stopped = false
end

---@param self LRClient.TruckerMission
function TruckerMission:ClearBlips()
  removeBlipSafe(self.routeBlip)
  self.routeBlip = 0
  for _, blip in pairs(self.vehicleBlips) do removeBlipSafe(blip) end
  self.vehicleBlips = {}
  self.vehicleNetIds = {}
  self.blipMissionId = ""
  self.blipStep = 0
end

---@param self LRClient.TruckerMission
---@param name string
---@param netId integer
---@param entity integer
---@param label string
---@param sprite integer
---@param colour integer
function TruckerMission:UpdateVehicleBlip(name, netId, entity, label, sprite, colour)
  local current = self.vehicleBlips[name]
  if self.vehicleNetIds[name] == netId
    and current and current ~= 0 and DoesBlipExist(current) then return end
  removeBlipSafe(current)
  self.vehicleBlips[name] = nil
  self.vehicleNetIds[name] = nil
  if netId <= 0 or entity == 0 then return end
  local blip = createEntityBlip(entity, label, sprite, colour)
  if blip ~= 0 then
    self.vehicleBlips[name] = blip
    self.vehicleNetIds[name] = netId
  end
end

---@param self LRClient.TruckerMission
---@param netId integer
---@param vehicle boolean
---@param revision integer
---@return integer
function TruckerMission:WaitForNetEntity(netId, vehicle, revision)
  if not netId or netId <= 0 then return 0 end
  local timeoutAt = GetGameTimer() + 5000
  while not self.stopped and self.entityRevision == revision and GetGameTimer() < timeoutAt do
    local entity = vehicle and netVehicle(netId) or netObject(netId)
    if entity ~= 0 and DoesEntityExist(entity) then return entity end
    Wait(100)
  end
  return 0
end

---@param self LRClient.TruckerMission
---@param entity integer
---@return boolean
function TruckerMission:RequestControl(entity)
  if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
  local timeoutAt = GetGameTimer() + 1000
  NetworkRequestControlOfEntity(entity)
  while not NetworkHasControlOfEntity(entity)
    and not self.stopped
    and GetGameTimer() < timeoutAt do
    Wait(25)
    NetworkRequestControlOfEntity(entity)
  end
  return NetworkHasControlOfEntity(entity)
end

---@param self LRClient.TruckerMission
---@param packageEntity integer
---@param forklift integer
function TruckerMission:AttachToForklift(packageEntity, forklift)
  if packageEntity == 0 or forklift == 0 then return end
  self:RequestControl(packageEntity)
  if self.stopped then return end
  FreezeEntityPosition(packageEntity, false)
  DetachEntity(packageEntity, true, true)
  local bone = GetEntityBoneIndexByName(forklift, "forks")
  if bone < 0 then bone = 4 end
  AttachEntityToEntity(
    packageEntity, forklift, bone,
    0.0, 0.55, 0.15,
    0.0, 0.0, 0.0,
    false, false, false, false, 2, true
  )
end

---@param self LRClient.TruckerMission
---@param mission LRTruckerStateSnapshotMission
function TruckerMission:SyncEntities(mission)
  self.entityRevision = self.entityRevision + 1
  local revision = self.entityRevision
  if not mission.active or mission.status == "idle" then
    self:ClearBlips()
    return
  end
  if self.blipMissionId ~= mission.id then
    self:ClearBlips()
    self.blipMissionId = mission.id
  end

  CreateThread(function()
    local truck = self:WaitForNetEntity(mission.truckNetId, true, revision)
    local trailer = self:WaitForNetEntity(mission.trailerNetId, true, revision)
    local escort = self:WaitForNetEntity(mission.escortNetId, true, revision)
    if revision ~= self.entityRevision or self.stopped then return end
    if truck ~= 0 then
      SetEntityInvincible(truck, true)
      FreezeEntityPosition(truck, mission.step == 3 or mission.step == 6)
    end
    if trailer ~= 0 then SetEntityInvincible(trailer, true) end
    if escort ~= 0 then SetEntityInvincible(escort, true) end

    self:UpdateVehicleBlip("truck", mission.truckNetId, truck, "Xe van chuyen", 477, 5)
    self:UpdateVehicleBlip("trailer", mission.trailerNetId, trailer, "Ro-mooc", 479, 5)
    self:UpdateVehicleBlip("escort", mission.escortNetId, escort, "Xe ho tong", 225, 5)

    local route = missionRoute(mission)
    if not route then return end
    local localSource = GetPlayerServerId(PlayerId())
    for index = 1, #mission.packages do
      local package = mission.packages[index]
      local entity = self:WaitForNetEntity(package.netId, false, revision)
      if revision ~= self.entityRevision or self.stopped then return end
      if entity ~= 0 then
        local cargoVehicle = usesTrailer(mission) and trailer or truck
        local cargoOffsets = usesTrailer(mission) and trailerOffsets or boxTruckOffsets
        if package.state == "loaded" and cargoVehicle ~= 0 then
          local offset = cargoOffsets[package.slot]
          if offset then
            self:RequestControl(entity)
            if self.stopped then return end
            FreezeEntityPosition(entity, false)
            DetachEntity(entity, true, true)
            AttachEntityToEntity(
              entity, cargoVehicle, 0,
              offset.x, offset.y, offset.z,
              0.0, 0.0, 0.0,
              true, true, false, true, 1, true
            )
          end
        elseif (package.state == "carried" or package.state == "unloading")
          and package.carrierSource == localSource then
          self:AttachToForklift(entity, playerForklift())
        elseif package.state == "delivered" then
          local coords = deliverySlot(route, package.slot)
          self:RequestControl(entity)
          if self.stopped then return end
          DetachEntity(entity, true, true)
          SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
          FreezeEntityPosition(entity, true)
        end
      end
    end
  end)
end

---@param self LRClient.TruckerMission
---@param mission LRTruckerStateSnapshotMission
function TruckerMission:UpdateRouteBlip(mission)
  if not mission.active or mission.status ~= "active" then
    removeBlipSafe(self.routeBlip)
    self.routeBlip = 0
    return
  end
  if self.blipMissionId == mission.id and self.blipStep == mission.step then return end
  removeBlipSafe(self.routeBlip)
  self.routeBlip = 0
  self.blipStep = mission.step
  local route = missionRoute(mission)
  if not route then return end
  if mission.step == 1 then
    self.routeBlip = createCoordBlip(route.pickup.parking, "Diem nhan hang", 1, 5, true)
  elseif mission.step == 4 then
    self.routeBlip = createCoordBlip(route.delivery.parking, "Diem giao hang", 1, 5, true)
  elseif mission.step == 7 then
    self.routeBlip = createCoordBlip(Config.ReturnPoint, "Diem hoan thanh don", 1, 5, true)
  end
end

---@param self LRClient.TruckerMission
---@param snapshot LRTruckerStateSnapshotMission
function TruckerMission:ApplySnapshot(snapshot)
  self.snapshot = snapshot
  self:SyncEntities(snapshot)
  self:UpdateRouteBlip(snapshot)
end

---@param self LRClient.TruckerMission
---@param action function
---@param payload table
function TruckerMission:AttemptGameplay(action, payload)
  if self.requestPending or GetGameTimer() - self.lastRequestAt < 1200 then return end
  self.requestPending = true
  self.lastRequestAt = GetGameTimer()
  action(payload)
  self.requestPending = false
end

---@param self LRClient.TruckerMission
---@param mission LRTruckerStateSnapshotMission
---@param localSource integer
---@return LRTruckerStateSnapshotMissionPackagesItem?
function TruckerMission:CarriedPackage(mission, localSource)
  for index = 1, #mission.packages do
    local package = mission.packages[index]
    if package.carrierSource == localSource
      and (package.state == "carried" or package.state == "unloading") then
      return package
    end
  end
  return nil
end

---@param self LRClient.TruckerMission
---@param mission LRTruckerStateSnapshotMission
---@param forkliftCoords vector3
---@param expectedState string
---@return LRTruckerStateSnapshotMissionPackagesItem?, number, integer
function TruckerMission:ClosestPackage(mission, forkliftCoords, expectedState)
  local closest, closestDistance, closestEntity = nil, math.huge, 0
  for index = 1, #mission.packages do
    local package = mission.packages[index]
    if package.state == expectedState then
      local entity = netObject(package.netId)
      if entity ~= 0 then
        local currentDistance = distance(forkliftCoords, GetEntityCoords(entity), true)
        if currentDistance < closestDistance then
          closest, closestDistance, closestEntity = package, currentDistance, entity
        end
      end
    end
  end
  return closest, closestDistance, closestEntity
end

---@param self LRClient.TruckerMission
---@param mission LRTruckerStateSnapshotMission
---@param route table
function TruckerMission:HandlePackages(mission, route)
  local forklift = playerForklift()
  if forklift == 0 then return end
  local localSource = GetPlayerServerId(PlayerId())
  local carried = self:CarriedPackage(mission, localSource)
  local forkliftCoords = GetEntityCoords(forklift)
  local rearOffset = rearLoadingOffset(mission)
  if rearOffset and ((mission.step == 3 and carried) or (mission.step == 6 and not carried)) then
    local truck = netVehicle(mission.truckNetId)
    if truck == 0 then return end
    local target = GetOffsetFromEntityInWorldCoords(truck, rearOffset.x, rearOffset.y, rearOffset.z)
    local package = carried
    if not package then
      for _, candidate in ipairs(mission.packages) do
        if candidate.state == "loaded" and (not package or candidate.index < package.index) then
          package = candidate
        end
      end
    end
    if not package then return end
    drawWorldMarker(target, 70, 211, 149, 0.5)
    if distance(forkliftCoords, target) <= 3.0 then
      showHelp(self.requestPending and "Dang xu ly kien hang..."
        or (carried and "~INPUT_CONTEXT~ — Cất kiện vào xe" or "~INPUT_CONTEXT~ — Lấy kiện khỏi xe"))
      if IsControlJustReleased(0, INTERACTION_CONTROL) then
        self:AttemptGameplay(self.packageAction, {
          action = carried and "load" or "lift", packageIndex = package.index,
        })
      end
    end
    -- Keep a carried box on the forks while approaching the rear marker.
    if carried then
      local entity = netObject(carried.netId)
      if entity ~= 0 and not IsEntityAttachedToEntity(entity, forklift) then
        self:AttachToForklift(entity, forklift)
      end
    end
    return
  end
  if not carried then
    local expectedState = mission.step == 3 and "waiting" or "loaded"
    local package, packageDistance, entity = self:ClosestPackage(mission, forkliftCoords, expectedState)
    if package and packageDistance <= 12.0 then
      drawWorldMarker(GetEntityCoords(entity), 238, 179, 61, 0.4)
      if packageDistance <= 3.0 then
        showHelp("Nhan ~INPUT_CONTEXT~ de nang kien hang")
        if IsControlJustReleased(0, INTERACTION_CONTROL) then
          self:AttemptGameplay(self.packageAction, { action = "lift", packageIndex = package.index })
        end
      end
    end
    return
  end

  local packageEntity = netObject(carried.netId)
  if packageEntity ~= 0 and not IsEntityAttachedToEntity(packageEntity, forklift) then
    self:AttachToForklift(packageEntity, forklift)
  end
  if mission.step == 3 then
    local cargoVehicle = usesTrailer(mission)
      and netVehicle(mission.trailerNetId) or netVehicle(mission.truckNetId)
    local offsets = usesTrailer(mission) and trailerOffsets or boxTruckOffsets
    local offset = offsets[mission.loaded + 1]
    if cargoVehicle == 0 or not offset then return end
    local target = GetOffsetFromEntityInWorldCoords(cargoVehicle, offset.x, offset.y, offset.z)
    drawWorldMarker(target, 70, 211, 149, 0.5)
    if distance(forkliftCoords, target, true) <= 3.0 then
      showHelp(not usesTrailer(mission)
        and "Nhan ~INPUT_CONTEXT~ de dat kien hang vao khoang xe"
        or "Nhan ~INPUT_CONTEXT~ de dat kien hang len ro-mooc")
      if IsControlJustReleased(0, INTERACTION_CONTROL) then
        self:AttemptGameplay(self.packageAction, { action = "load", packageIndex = carried.index })
      end
    end
  elseif mission.step == 6 then
    local target = deliverySlot(route, mission.delivered + 1)
    drawWorldMarker(target, 70, 211, 149, 0.5)
    if distance(forkliftCoords, target, true) <= 3.0 then
      showHelp("Nhan ~INPUT_CONTEXT~ de giao kien hang")
      if IsControlJustReleased(0, INTERACTION_CONTROL) then
        self:AttemptGameplay(self.packageAction, { action = "deliver", packageIndex = carried.index })
      end
    end
  end
end

---@param self LRClient.TruckerMission
---@param trailer integer
---@param target vector4
---@return boolean
function TruckerMission:TrailerParked(trailer, target)
  if trailer == 0 or not DoesEntityExist(trailer) then return false end
  local maxDistance = 10.0
  local maxHeadingDifference = 20.0
  local trailerCoords = GetEntityCoords(trailer)
  local trailerDistance = distance(trailerCoords, target)
  local headingDifference = math.abs(GetEntityHeading(trailer) - target.w) % 360.0
  headingDifference = math.min(headingDifference, 360.0 - headingDifference)
  headingDifference = math.min(headingDifference, 180.0 - headingDifference)
  local score = math.max(0.0,
    100.0 - headingDifference / maxHeadingDifference * 50.0 - trailerDistance / maxDistance * 50.0)
  local red = math.floor(255 * (1.0 - score / 100.0))
  local green = 255 - red
  drawParkingMarker(target, red, green)
  return trailerDistance <= maxDistance and headingDifference <= maxHeadingDifference
end
local function cargoParked(self, mission, truck, trailer, target)
  return self:TrailerParked(
    usesTrailer(mission) and trailer or truck,
    target
  )
end
---@param self LRClient.TruckerMission
function TruckerMission:HandleGameplay()
  local mission = self.snapshot
  if not mission.active or mission.status ~= "active" then return end
  local route = missionRoute(mission)
  if not route then return end
  local truck = netVehicle(mission.truckNetId)
  local trailer = netVehicle(mission.trailerNetId)
  local ped = PlayerPedId()
  local isDriver = truck ~= 0 and GetPedInVehicleSeat(truck, -1) == ped
  if mission.step == 1 and isDriver
    and distance(GetEntityCoords(truck), route.pickup.parking) <= 20.0 then
    self:AttemptGameplay(self.advance, { expectedStep = 1 })
  elseif mission.step == 2 then
    if cargoParked(self, mission, truck, trailer, route.pickup.parking) and isDriver then
      showHelp("Nhan ~INPUT_CONTEXT~ de bat dau boc hang")
      if IsControlJustReleased(0, INTERACTION_CONTROL) then
        self:AttemptGameplay(self.advance, { expectedStep = 2 })
      end
    end
  elseif mission.step == 3 or (mission.step == 6 and mission.cargoMode ~= "tanker") then
    self:HandlePackages(mission, route)
  elseif mission.step == 4 and isDriver
    and distance(GetEntityCoords(truck), route.delivery.parking) <= 20.0 then
    self:AttemptGameplay(self.advance, { expectedStep = 4 })
  elseif mission.step == 5 then
    if cargoParked(self, mission, truck, trailer, route.delivery.parking) and isDriver then
      showHelp("Nhan ~INPUT_CONTEXT~ de bat dau giao hang")
      if IsControlJustReleased(0, INTERACTION_CONTROL) then
        self:AttemptGameplay(self.advance, { expectedStep = 5 })
      end
    end
  elseif mission.step == 6 and mission.cargoMode == "tanker" then
    drawWorldMarker(route.delivery.parking, 36, 174, 186, 0.7)
    showHelp("Dang giao dau tho...")
  elseif mission.step == 7 then
    if cargoParked(self, mission, truck, trailer, Config.ReturnPoint) and isDriver then
      showHelp("Nhan ~INPUT_CONTEXT~ de hoan thanh don; xe thue van duoc giu")
      if IsControlJustReleased(0, INTERACTION_CONTROL) then
        self:AttemptGameplay(self.advance, { expectedStep = 7 })
      end
    end
  end
end

---@param self LRClient.TruckerMission
---@param revision integer
function TruckerMission:RunGameplayLoop(revision)
  while not self.stopped and self.loopRevision == revision do
    local waitTime = 1000
    if self.snapshot.active and self.snapshot.status == "active" then
      waitTime = 0
      self:HandleGameplay()
    end
    Wait(waitTime)
  end
end

---@param self LRClient.TruckerMission
function TruckerMission:Start()
  self.stopped = false
  self.loopRevision = self.loopRevision + 1
  local revision = self.loopRevision
  CreateThread(function() self:RunGameplayLoop(revision) end)
end

---@param self LRClient.TruckerMission
function TruckerMission:Stop()
  self.stopped = true
  self.loopRevision = self.loopRevision + 1
  self.entityRevision = self.entityRevision + 1
  self:ClearBlips()
end

LRTruckerClient.Mission = TruckerMission
return TruckerMission
