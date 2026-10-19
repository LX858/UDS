local TruckerNPC = assert(LRTruckerClient.NPC)
local TruckerMission = assert(LRTruckerClient.Mission)

---@param value unknown
---@return unknown
local function throughBoundary(value)
  return value
end

---@return LRTruckerStateSnapshot
local function emptySnapshot()
  return {
    player = { source = 0, citizenId = "", name = "", cash = 0, bank = 0, level = 1, xp = 0 },
    orderPage = { filter = "all", page = 1, pageSize = 20, total = 0, items = {} },
    business = {
      active = false, sourceOnline = false, businessId = "", label = "",
      balance = 0, distanceKm = 0.0, feeBase = 0, feePerKm = 0,
      feePerPackage = 0, feeMaximum = 0, feeRate = 0, catalog = {}, orders = {},
    },
    fleet = {
      bank = 0, ownedVehicles = {}, rentalOptions = {},
      rental = {
        active = false, status = "none", key = "", model = "", plate = "",
        startedAt = 0, expiresAt = 0, truckNetId = 0, overageDue = 0, debt = 0,
      },
    },
    mission = {
      active = false, status = "idle", id = "", routeIndex = 0, deliveryRouteIndex = 0,
      name = "", step = 0,
      itemLabel = "", destination = "", logisticsUnits = 0,
      vehicleMode = "", vehicleModel = "", ownedVehicleId = 0, vehiclePlate = "",
      packageAmount = 0, loaded = 0, delivered = 0, reward = 0, xp = 0,
      truckNetId = 0, trailerNetId = 0, escortNetId = 0, packages = {},
      orderKind = "market", cargoMode = "pallets", businessId = "", lines = {}, fuelLiters = 0,
      fuelProgress = 0,
      pickupCoords = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
      deliveryCoords = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },
    },
  }
end

---@class LRClient.TruckerServiceInput
---@field context LRClient.ModuleContext

---@class LRClient.TruckerService : LRClient.ModuleInstance
---@field context LRClient.ModuleContext
---@field snapshot LRTruckerStateSnapshot
---@field nui? LRClientTruckerNui
---@field net? LRClientTruckerNet
---@field npc LRClient.TruckerNPC
---@field mission LRClient.TruckerMission
---@field returnBlip integer
---@field stopped boolean
---@field Notify fun(self: LRClient.TruckerService, message: string, noticeType?: LRClient.FrameworkNotificationType)
---@field ApplySnapshot fun(self: LRClient.TruckerService, snapshot: LRTruckerStateSnapshot)
---@field RefreshState fun(self: LRClient.TruckerService): boolean, string
---@field CallServer fun(self: LRClient.TruckerService, endpoint: table, payload: table, silentSuccess?: boolean): { success: boolean, message: string }
---@field OpenUi fun(self: LRClient.TruckerService): LRTruckerExportClientOpenResponse
---@field OpenBusinessUi fun(self: LRClient.TruckerService, businessId: string): table
---@field ResetPlayerState fun(self: LRClient.TruckerService)
---@field OnReady fun(self: LRClient.TruckerService, context: LRClient.ModuleContext)
---@field Start fun(self: LRClient.TruckerService, context: LRClient.ModuleContext)
---@field Stop fun(self: LRClient.TruckerService)

---@class LRClient.TruckerServiceClass : LRShared.Class<LRClient.TruckerService, LRClient.TruckerServiceInput>
---@field init fun(self: LRClient.TruckerService, input: LRClient.TruckerServiceInput)
---@field Notify fun(self: LRClient.TruckerService, message: string, noticeType?: LRClient.FrameworkNotificationType)
---@field ApplySnapshot fun(self: LRClient.TruckerService, snapshot: LRTruckerStateSnapshot)
---@field RefreshState fun(self: LRClient.TruckerService): boolean, string
---@field CallServer fun(self: LRClient.TruckerService, endpoint: table, payload: table, silentSuccess?: boolean): { success: boolean, message: string }
---@field OpenUi fun(self: LRClient.TruckerService): LRTruckerExportClientOpenResponse
---@field OpenBusinessUi fun(self: LRClient.TruckerService, businessId: string): table
---@field ResetPlayerState fun(self: LRClient.TruckerService)
---@field OnReady fun(self: LRClient.TruckerService, context: LRClient.ModuleContext)
---@field Start fun(self: LRClient.TruckerService, context: LRClient.ModuleContext)
---@field Stop fun(self: LRClient.TruckerService)

---@type LRClient.TruckerServiceClass
local TruckerService = LR.Class:Define("ClientTruckerService")

---@param self LRClient.TruckerService
local function clearReturnBlip(self)
  if self.returnBlip ~= 0 then
    if DoesBlipExist(self.returnBlip) then
      ---@diagnostic disable-next-line: redundant-parameter
      RemoveBlip(self.returnBlip)
    end
    self.returnBlip = 0
  end
end

---@param self LRClient.TruckerService
---@param input LRClient.TruckerServiceInput
function TruckerService:init(input)
  self.context = input.context
  self.snapshot = emptySnapshot()
  self.returnBlip = 0
  self.stopped = false
  self.mission = TruckerMission:New({
    snapshot = self.snapshot.mission,
    advance = function(request)
      local net = assert(self.net)
      return self:CallServer(net.rpc.advance, request, true)
    end,
    packageAction = function(request)
      local net = assert(self.net)
      return self:CallServer(net.rpc.packageAction, request, true)
    end,
  })
  self.npc = TruckerNPC:New({
    onInteract = function() return self:OpenUi() end,
    onBusinessInteract = function(businessId) return self:OpenBusinessUi(businessId) end,
  })
end

---@param self LRClient.TruckerService
---@param message string
---@param noticeType? LRClient.FrameworkNotificationType
function TruckerService:Notify(message, noticeType)
  local framework = assert(self.context.services.framework)
  framework:Notify({
    message = message,
    type = noticeType or "inform",
    duration = 5000,
  })
end

---@param self LRClient.TruckerService
---@param snapshot LRTruckerStateSnapshot
function TruckerService:ApplySnapshot(snapshot)
  self.snapshot = snapshot
  local nui = assert(self.nui)
  nui.state.snapshot:Set(snapshot)
  self.mission:ApplySnapshot(snapshot.mission)
end

---@param self LRClient.TruckerService
---@return boolean, string
function TruckerService:RefreshState()
  local net = assert(self.net)
  local ok, result = pcall(function() return net.rpc.getState:Call({}) end)
  if not ok then return false, "Khong the tai du lieu van chuyen" end
  if self.stopped then return false, "Khong the tai du lieu van chuyen" end
  ---@cast result LRTruckerStateSnapshot
  self:ApplySnapshot(result)
  return true, "Da cap nhat"
end

---@param self LRClient.TruckerService
---@param endpoint table
---@param payload table
---@param silentSuccess? boolean
---@return { success: boolean, message: string }
function TruckerService:CallServer(endpoint, payload, silentSuccess)
  local ok, response = pcall(function() return endpoint:Call(payload) end)
  if not ok then
    self:Notify("May chu khong phan hoi 1", "error")
    return { success = false, message = "May chu khong phan hoi" }
  end
  if self.stopped then return { success = false, message = "May chu khong phan hoi 2" } end
  self:ApplySnapshot(response.snapshot)
  if response.message ~= "" and (not response.success or not silentSuccess) then
    self:Notify(response.message, response.success and "success" or "error")
  end
  return { success = response.success, message = response.message }
end

---@param self LRClient.TruckerService
---@return LRTruckerExportClientOpenResponse
function TruckerService:OpenUi()
  local success, message = self:RefreshState()
  if not success then
    self:Notify(message, "error")
    return { success = false, message = message }
  end
  self.snapshot.business.active = false
  self:ApplySnapshot(self.snapshot)
  local nui = assert(self.nui)
  nui.state.visibility:Set({ visible = true })
  return { success = true, message = "" }
end

function TruckerService:OpenBusinessUi(businessId)
  local net = assert(self.net)
  local result = self:CallServer(net.rpc.getBusinessContext, { businessId = businessId }, true)
  if not result.success then return result end
  local nui = assert(self.nui)
  nui.state.visibility:Set({ visible = true })
  return result
end

---@param self LRClient.TruckerService
function TruckerService:ResetPlayerState()
  local nui = assert(self.nui)
  nui.state.visibility:Set({ visible = false })
  self.snapshot = emptySnapshot()
  nui.state.snapshot:Set(self.snapshot)
  self.mission:ApplySnapshot(self.snapshot.mission)
end

---@param self LRClient.TruckerService
---@param readyContext LRClient.ModuleContext
function TruckerService:OnReady(readyContext)
  local nui = readyContext.nui.Trucker()
  self.nui = nui
  nui.state.visibility:Set({ visible = false })
  nui.state.settings:Set({
    locale = type(Config.Settings) == "table" and Config.Settings.locale or {},
    dev = Config.Dev == true,
  })
  nui.state.snapshot:Set(self.snapshot)
end

---@param self LRClient.TruckerService
---@param startContext LRClient.ModuleContext
function TruckerService:Start(startContext)
  self.stopped = false
  self.context = startContext
  local nui = startContext.nui.Trucker()
  local net = startContext.net.Trucker
  self.nui = nui
  self.net = net

  startContext.disposables:Add(nui.state.visibility:Watch(function(value)
    SetNuiFocus(value.visible, value.visible)
  end))
  startContext.disposables:Add(startContext.nui:WhenReady(function()
    local visible = nui.state.visibility:Get().visible
    SetNuiFocus(visible, visible)
  end))

  startContext.disposables:Add(net.events.sync:On(function(payload)
    local snapshot = throughBoundary(payload.snapshot)
    ---@cast snapshot LRTruckerStateSnapshot
    self:ApplySnapshot(snapshot)
  end))
  startContext.disposables:Add(net.events.notice:On(function(payload)
    self:Notify(payload.message, payload.type)
  end))

  startContext.disposables:Add(nui.rpc.close:Handle(function()
    nui.state.visibility:Set({ visible = false })
    return { success = true, message = "" }
  end))
  startContext.disposables:Add(nui.rpc.refresh:Handle(function()
    local success, message = self:RefreshState()
    return { success = success, message = message }
  end))
  startContext.disposables:Add(nui.rpc.acceptOrder:Handle(function(request)
    return self:CallServer(net.rpc.acceptOrder, request)
  end))
  startContext.disposables:Add(nui.rpc.cancelMission:Handle(function()
    return self:CallServer(net.rpc.cancelMission, {}, true)
  end))
  startContext.disposables:Add(nui.rpc.returnRental:Handle(function()
    return self:CallServer(net.rpc.returnRental, {})
  end))
  startContext.disposables:Add(nui.rpc.settleRentalDebt:Handle(function()
    return self:CallServer(net.rpc.settleRentalDebt, {})
  end))
  startContext.disposables:Add(nui.rpc.upgradeVehicle:Handle(function(request)
    return self:CallServer(net.rpc.upgradeVehicle, request)
  end))
  startContext.disposables:Add(nui.rpc.getBusinessContext:Handle(function(request)
    return self:CallServer(net.rpc.getBusinessContext, request, true)
  end))
  startContext.disposables:Add(nui.rpc.listOrderBoard:Handle(function(request)
    ---@type LRTruckerNetClientToServerListOrderBoardRequest
    local payload = { filter = request.filter, page = request.page, pageSize = request.pageSize }
    local ok, page = pcall(function() return net.rpc.listOrderBoard:Call(payload) end)
    if not ok then return { success = false, message = "Không thể tải bảng đơn hàng" } end
    ---@cast page LRTruckerStateSnapshotOrderPage
    self.snapshot.orderPage = page
    self:ApplySnapshot(self.snapshot)
    return { success = true, message = "" }
  end))
  startContext.disposables:Add(nui.rpc.createBusinessOrder:Handle(function(request)
    return self:CallServer(net.rpc.createBusinessOrder, request)
  end))
  startContext.disposables:Add(nui.rpc.cancelBusinessOrder:Handle(function(request)
    return self:CallServer(net.rpc.cancelBusinessOrder, request)
  end))

  startContext.disposables:Add(startContext.public.Trucker:Register({
    open = function() return self:OpenUi() end,
    getSnapshot = function()
      local snapshot = throughBoundary(self.snapshot)
      ---@cast snapshot LRTruckerExportClientGetSnapshotResponse
      return snapshot
    end,
  }))

  local framework = assert(startContext.services.framework)
  startContext.disposables:Add(framework:OnPlayerUnloaded(function()
    self:ResetPlayerState()
  end))
  startContext.disposables:Add(framework:OnPlayerDataChanged(function()
    CreateThread(function()
      if not self.stopped then self:RefreshState() end
    end)
  end))

  self.npc:Start()
  self.mission:Start()
  CreateThread(function()
    local returning = false
    while not self.stopped do
      local waitTime = 1000
      local rental = self.snapshot.fleet.rental
      local missionActive = self.snapshot.mission.active
      if rental.active and not missionActive and self.returnBlip == 0 then
        local point = Config.ReturnPoint
        local blip = AddBlipForCoord(point.x, point.y, point.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 5)
        SetBlipScale(blip, 0.85)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Điểm trả xe thuê")
        EndTextCommandSetBlipName(blip)
        self.returnBlip = blip
      elseif (not rental.active or missionActive) and self.returnBlip ~= 0 then
        clearReturnBlip(self)
      end
      if rental.active then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local point = Config.ReturnPoint
        local dx, dy, dz = coords.x - point.x, coords.y - point.y, coords.z - point.z
        local nearby = dx * dx + dy * dy + dz * dz < 3600.0
        if nearby then
          waitTime = 0
          DrawMarker(1, point.x, point.y, point.z + 0.1,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            3.0, 3.0, 0.35, 240, 178, 60, 180,
            false, false, 2, false, "", "", false)
          local truck = GetVehiclePedIsIn(ped, false)
          if dx * dx + dy * dy + dz * dz < 225.0
            and truck ~= 0 and GetPedInVehicleSeat(truck, -1) == ped
            and NetworkGetNetworkIdFromEntity(truck) == rental.truckNetId then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName(missionActive
              and "Hoàn thành hoặc hủy đơn trước khi trả xe thuê"
              or "Nhấn ~INPUT_CONTEXT~ để trả xe thuê")
            EndTextCommandDisplayHelp(0, false, false, -1)
            if not missionActive and not returning and not nui.state.visibility:Get().visible
              and IsControlJustReleased(0, 38) then
              returning = true
              self:CallServer(net.rpc.returnRental, {})
              returning = false
            end
          end
        end
      end
      Wait(waitTime)
    end
  end)
  CreateThread(function()
    Wait(500)
    if not self.stopped then self:RefreshState() end
  end)
  startContext.logger:Info("trucker client started")
end

---@param self LRClient.TruckerService
function TruckerService:Stop()
  self.stopped = true
  clearReturnBlip(self)
  SetNuiFocus(false, false)
  self.mission:Stop()
  self.npc:Stop()
end

LRTruckerClient.Service = TruckerService
return TruckerService
