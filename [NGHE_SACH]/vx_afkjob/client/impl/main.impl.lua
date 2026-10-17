---@class MainImpl : Impl
local Impl = NewImpl("Main")

local function ShowHelpText(message)
  -- BeginTextCommandDisplayHelp("STRING")
  -- AddTextComponentSubstringPlayerName(message)
  -- EndTextCommandDisplayHelp(0, false, true, -1)
end

function Impl:Init()
  self.config = Config.AFKJob
  self.point = nil
  self.blip = nil
  self.farming = false
  self.progress = 0
  self.farmPoints = {}
  self.farmProps = {}
  self.farmThread = nil
  self.finishSubmitted = false
  self.uiVisible = false
  self.uiStatus = "idle"

  math.randomseed(GetGameTimer())
  self:CreatePoint()
  self:CreateBlip()
  self:UpdateUI(false, "idle")
  self:LogInfo("%s initialized", self:GetName())
end

function Impl:CreatePoint()
  local cfg = self.config
  self.point = lib.points.new({
    coords = cfg.StartCoords,
    distance = cfg.ZoneRadius,
    onEnter = function()
      if not self.farming then
        self:UpdateUI(true, "ready")
      end
    end,
    onExit = function()
      if not self.farming then
        self:UpdateUI(false, "idle")
      end
    end,
    nearby = function(point)
      -- DrawMarker(1, point.coords.x, point.coords.y, point.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, cfg.ZoneRadius * 2.0, cfg.ZoneRadius * 2.0, 1.0, 20, 180, 90, 35, false, false, 2, false, nil, nil, false)
      DrawMarker(2, point.coords.x, point.coords.y, point.coords.z + 0.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0, 1.0, 200, 20, 20, 90, false, true, 2, false, nil, nil, false)

      if self.farming then
        -- ShowHelpText(("[X] Dừng công việc | Đang treo: %s/%s"):format(self.progress, cfg.MaxProgress))
        return
      end

      -- ShowHelpText("[E] Bắt đầu treo")
      Draw3DText(point.coords.x, point.coords.y, point.coords.z + 1.0, 0.5, "[~g~E~s~] Bắt đầu treo")
      if IsControlJustReleased(0, 38) then
        self:StartFarm()
      end
    end
  })
end


function Impl:CreateBlip()
  local cfg = self.config
  self.blip = AddBlipForCoord(cfg.StartCoords)
  SetBlipSprite(self.blip, 280)
  SetBlipDisplay(self.blip, 4)
  SetBlipScale(self.blip, 0.8)
  SetBlipColour(self.blip, 5)
  SetBlipAsShortRange(self.blip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString("Cong viec AFK")
  EndTextCommandSetBlipName(self.blip)
end

function Impl:StartFarm()
  if self.farming then return end

  local ped = PlayerPedId()
  if IsEntityDead(ped) then
    return ShowNotification("Không thể bắt đầu khi nhân vật đã chết", "error")
  end

  self.farmPoints = self:GenerateRandomPoints()
  if #self.farmPoints == 0 then
    return ShowNotification("Không tìm được điểm farm hợp lệ", "error")
  end

  self:SpawnFarmProps()

  self.farming = true
  self.progress = 0
  self.finishSubmitted = false
  self:UpdateUI(true, "moving")
  self:EmitNet("Main", "startFarm")
  ShowNotification("Bat dau treo", "success")

  self.farmThread = Citizen.CreateThread(function()
    self:FarmLoop()
  end)
end

function Impl:GenerateRandomPoints()
  local cfg = self.config
  local points = {}
  local attempts = 0
  local maxAttempts = cfg.RandomPointCount * 25

  while #points < cfg.RandomPointCount and attempts < maxAttempts do
    attempts = attempts + 1
    local angle = math.random() * math.pi * 2.0
    local radius = math.sqrt(math.random()) * cfg.ZoneRadius
    local x = cfg.StartCoords.x + math.cos(angle) * radius
    local y = cfg.StartCoords.y + math.sin(angle) * radius
    local z = self:GetGroundZ(x, y)

    if z then
      points[#points + 1] = vector3(x, y, z)
    end
  end

  return points
end

function Impl:GetGroundZ(x, y)
  local heights = { 50.0, 75.0, 100.0, 150.0, 250.0, 500.0 }

  for _, height in ipairs(heights) do
    RequestCollisionAtCoord(x, y, height)
    Wait(0)

    local found, z = GetGroundZFor_3dCoord(x, y, height, false)
    if found then
      return z
    end
  end

  return nil
end

function Impl:SpawnFarmProps()
  self:CleanupFarmProps()

  local model = joaat(self.config.FarmPropModel)
  RequestModel(model)

  local timeout = GetGameTimer() + 10000
  while not HasModelLoaded(model) and GetGameTimer() < timeout do
    Wait(50)
  end

  if not HasModelLoaded(model) then
    ShowNotification("Khong load duoc prop farm", "error")
    return self:LogError("Failed to load farm prop model %s", self.config.FarmPropModel)
  end

  for _, point in ipairs(self.farmPoints) do
    local prop = CreateObject(model, point.x, point.y, point.z, false, false, false)
    if DoesEntityExist(prop) then
      SetEntityHeading(prop, math.random(0, 359) + 0.0)
      PlaceObjectOnGroundProperly(prop)
      FreezeEntityPosition(prop, true)
      self.farmProps[#self.farmProps + 1] = prop
    end
  end

  SetModelAsNoLongerNeeded(model)
end

function Impl:FarmLoop()
  local pointIndex = 1

  while self.farming and self.progress < self.config.MaxProgress and not self.destroyed do
    local point = self.farmPoints[pointIndex]
    if not point then
      pointIndex = 1
      point = self.farmPoints[pointIndex]
    end

    if not self:MoveToFarmPoint(point) then
      self:FinishFarm(false, "Đã dừng công việc")
      return
    end

    if not self:FarmCurrentPoint() then
      self:FinishFarm(false, "Đã dừng công việc")
      return
    end

    self.progress = self.progress + 1
    self:UpdateUI(true, "moving")
    self:EmitNet("Main", "updateFarmProgress", self.progress)
    pointIndex = pointIndex + 1
  end

  if self.progress >= self.config.MaxProgress then
    self:FinishFarm(true)
  end
end

function Impl:MoveToFarmPoint(point)
  local ped = PlayerPedId()
  if IsEntityDead(ped) then return false end

  self:UpdateUI(true, "moving")
  TaskGoStraightToCoord(ped, point.x, point.y, point.z, 5.0, -1, 0.0, 0.0)

  local timeout = GetGameTimer() + 45000
  while self.farming and not self.destroyed and GetGameTimer() < timeout do
    ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local distance = #(coords - point)
    -- DrawLine(coords.x, coords.y, coords.z, point.x, point.y, point.z, 25, 125, 25, 125)
    DrawMarker(2, point.x, point.y, point.z + 0.5, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.6, 0.6, 0.6, 20, 180, 90, 120, false, true, 2, false, nil, nil, false)
    -- ShowHelpText(("[X] Dừng Công Việc | Đang di chuyển: %s/%s"):format(self.progress, self.config.MaxProgress))

    if IsEntityDead(ped) then return false end
    if IsControlJustReleased(0, 73) then return false end
    if distance < 1.6 then return true end
    
    Wait(0)
  end

  return false
end

function Impl:FarmCurrentPoint()
  local ped = PlayerPedId()
  if IsEntityDead(ped) then return false end

  self:UpdateUI(true, "farming")
  TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GARDENER_PLANT", 0, true)

  local startedAt = GetGameTimer()
  while self.farming and not self.destroyed and GetGameTimer() - startedAt < self.config.FarmDuration do
    if IsEntityDead(PlayerPedId()) then
      ClearPedTasks(PlayerPedId())
      return false
    end

    ShowHelpText(("[X] ừng Công Việc | Đang farm: %s/%s"):format(self.progress, self.config.MaxProgress))
    if IsControlJustReleased(0, 73) then
      ClearPedTasks(PlayerPedId())
      return false
    end

    Wait(0)
  end

  ClearPedTasks(PlayerPedId())
  return self.farming and not self.destroyed
end

function Impl:FinishFarm(completed, message)
  if not self.finishSubmitted then
    self.finishSubmitted = true
    self:EmitNet("Main", "finishFarm", self.progress)
  end

  self:StopFarm(completed, message)
end

function Impl:StopFarm(completed, message)
  self.farming = false
  ClearPedTasks(PlayerPedId())
  self:CleanupFarmProps()
  self:UpdateUI(true, completed and "completed" or "stopped")

  Citizen.SetTimeout(2000, function()
    if not self.farming then
      self:UpdateUI(false, "idle")
    end
  end)

  if message then
    ShowNotification(message, completed and "success" or "primary")
  end
end

function Impl:UpdateUI(visible, status)
  self.uiVisible = visible
  self.uiStatus = status or self.uiStatus

  SendNUIMessage({
    action = "afkjob:update",
    data = {
      visible = self.uiVisible,
      status = self.uiStatus,
      progress = self.progress,
      maxProgress = self.config.MaxProgress,
    }
  })
end

function Impl:OnDestroy()
  self:Cleanup()
end

function Impl:OnResourceStop()
  self:Cleanup()
end

function Impl:Cleanup()
  self.farming = false
  self:CleanupFarmProps()
  self:UpdateUI(false, "idle")

  if self.point and self.point.remove then
    self.point:remove()
    self.point = nil
  end

  if self.blip and DoesBlipExist(self.blip) then
    RemoveBlip(self.blip)
    self.blip = nil
  end

end

function Impl:CleanupFarmProps()
  for _, prop in ipairs(self.farmProps or {}) do
    if DoesEntityExist(prop) then
      DeleteEntity(prop)
    end
  end

  self.farmProps = {}
end
