---@class LRClient.TruckerNamespace
---@field NPC? LRClient.TruckerNPCClass
---@field Mission? LRClient.TruckerMissionClass
---@field Service? LRClient.TruckerServiceClass

LRTruckerClient = LRTruckerClient or {} ---@type LRClient.TruckerNamespace

local INTERACTION_CONTROL = 38
local INTERACTION_DISTANCE = 2.0

local function distance(first, second)
  if not first or not second then return math.huge end
  local x = first.x - second.x
  local y = first.y - second.y
  local z = first.z - second.z
  return math.sqrt(x * x + y * y + z * z)
end

local function showHelp(message)
  BeginTextCommandDisplayHelp("STRING")
  AddTextComponentSubstringPlayerName(message)
  EndTextCommandDisplayHelp(0, false, true, 1)
end

local function removeBlipSafe(blip)
  if blip and blip ~= 0 and DoesBlipExist(blip) then
    ---@diagnostic disable-next-line: redundant-parameter
    RemoveBlip(blip)
  end
end

local function createCoordBlip(coords, label, sprite, colour)
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, sprite)
  SetBlipColour(blip, colour)
  SetBlipScale(blip, 0.8)
  SetBlipAsShortRange(blip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(label)
  EndTextCommandSetBlipName(blip)
  return blip
end

---@class LRClient.TruckerNPCInput
---@field onInteract fun(): unknown
---@field onBusinessInteract fun(businessId: string): unknown

---@class LRClient.TruckerNPC : LRShared.ClassInstance
---@field onInteract fun(): unknown
---@field onBusinessInteract fun(businessId: string): unknown
---@field businessPoints table[]
---@field npc integer
---@field blip integer
---@field stopped boolean
---@field revision integer
---@field Spawn fun(self: LRClient.TruckerNPC, revision: integer)
---@field RunProximityLoop fun(self: LRClient.TruckerNPC, revision: integer)
---@field Start fun(self: LRClient.TruckerNPC)
---@field Stop fun(self: LRClient.TruckerNPC)

---@class LRClient.TruckerNPCClass : LRShared.Class<LRClient.TruckerNPC, LRClient.TruckerNPCInput>
---@field init fun(self: LRClient.TruckerNPC, input: LRClient.TruckerNPCInput)
---@field Spawn fun(self: LRClient.TruckerNPC, revision: integer)
---@field RunProximityLoop fun(self: LRClient.TruckerNPC, revision: integer)
---@field Start fun(self: LRClient.TruckerNPC)
---@field Stop fun(self: LRClient.TruckerNPC)

---@type LRClient.TruckerNPCClass
local TruckerNPC = LR.Class:Define("ClientTruckerNPC")

---@param self LRClient.TruckerNPC
---@param input LRClient.TruckerNPCInput
function TruckerNPC:init(input)
  self.onInteract = input.onInteract
  self.onBusinessInteract = input.onBusinessInteract
  self.businessPoints = LR.GetBusinessProcurementPoints and LR.GetBusinessProcurementPoints() or {}
  self.npc = 0
  self.blip = 0
  self.stopped = false
  self.revision = 0
end

---@param self LRClient.TruckerNPC
---@param revision integer
function TruckerNPC:Spawn(revision)
  local model = GetHashKey(Config.NPC.model)
  RequestModel(model)
  local timeoutAt = GetGameTimer() + 10000
  while not HasModelLoaded(model)
    and not self.stopped
    and self.revision == revision
    and GetGameTimer() < timeoutAt do
    Wait(50)
  end
  if self.stopped or self.revision ~= revision or not HasModelLoaded(model) then return end

  self.npc = CreatePed(
    4,
    model,
    Config.NPC.coords.x,
    Config.NPC.coords.y,
    Config.NPC.coords.z - 1.0,
    Config.NPC.coords.w,
    false,
    true
  )
  SetEntityInvincible(self.npc, true)
  FreezeEntityPosition(self.npc, true)
  SetBlockingOfNonTemporaryEvents(self.npc, true)
  SetModelAsNoLongerNeeded(model)

  self.blip = createCoordBlip(
    Config.NPC.coords,
    "VAN CHUYEN HANG",
    477,
    5
  )
end

---@param self LRClient.TruckerNPC
---@param revision integer
function TruckerNPC:RunProximityLoop(revision)
  while not self.stopped and self.revision == revision do
    local waitTime = 1000
    local coords = GetEntityCoords(PlayerPedId())
    local npcDistance = distance(coords, Config.NPC.coords)
    if npcDistance <= 20.0 then
      waitTime = 0
      if npcDistance <= INTERACTION_DISTANCE then
        showHelp("Nhan ~INPUT_CONTEXT~ de mo trung tam van chuyen")
        if IsControlJustReleased(0, INTERACTION_CONTROL) then
          self.onInteract()
        end
      end
    end
    for _, point in ipairs(self.businessPoints) do
      local businessDistance = distance(coords, point.coords)
      if businessDistance <= 20.0 then
        waitTime = 0
        if businessDistance <= Config.BusinessOrders.InteractionDistance then
          showHelp(("Nhan ~INPUT_CONTEXT~ de dat giao hang cho %s"):format(point.label))
          if IsControlJustReleased(0, INTERACTION_CONTROL) then
            self.onBusinessInteract(point.businessId)
          end
        end
      end
    end
    Wait(waitTime)
  end
end

---@param self LRClient.TruckerNPC
function TruckerNPC:Start()
  self.stopped = false
  self.revision = self.revision + 1
  local revision = self.revision
  self.businessPoints = LR.GetBusinessProcurementPoints and LR.GetBusinessProcurementPoints() or {}
  CreateThread(function() self:Spawn(revision) end)
  CreateThread(function() self:RunProximityLoop(revision) end)
end

---@param self LRClient.TruckerNPC
function TruckerNPC:Stop()
  self.stopped = true
  self.revision = self.revision + 1
  removeBlipSafe(self.blip)
  if self.npc ~= 0 and DoesEntityExist(self.npc) then
    ---@diagnostic disable-next-line: redundant-parameter
    DeleteEntity(self.npc)
  end
  self.npc, self.blip = 0, 0
end

LRTruckerClient.NPC = TruckerNPC
return TruckerNPC
