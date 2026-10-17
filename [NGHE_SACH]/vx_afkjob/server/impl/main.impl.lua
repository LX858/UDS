---@class MainImpl : Impl
local Impl = NewImpl("Main")

function Impl:Init()
  self.config = Config.AFKJob
  self.farmSessions = {}

  self:OnNet("startFarm", function()
    self:StartFarm(source)
  end)

  self:OnNet("updateFarmProgress", function(progress)
    self:UpdateFarmProgress(source, progress)
  end)

  self:OnNet("finishFarm", function(progress)
    self:FinishFarm(source, progress)
  end)

  self:AddEventHandler("playerDropped", function()
    self:PayoutDroppedPlayer(source)
  end)

  self:LogInfo("%s initialized", self:GetName())
end

function Impl:StartFarm(playerSrc)
  if not self:IsPlayerNear(playerSrc, self.config.StartCoords, self.config.ZoneRadius + 5.0) then
    return
  end

  self.farmSessions[playerSrc] = {
    startedAt = os.time(),
    progress = 0,
    paidProgress = 0,
    earnedItems = 0,
  }
end

function Impl:UpdateFarmProgress(playerSrc, progress)
  local session = self.farmSessions[playerSrc]
  if not session then return end
  if not self:IsPlayerNear(playerSrc, self.config.StartCoords, self.config.ZoneRadius + 20.0) then return end

  self:RecordProgress(session, progress)
  self:PayProgressDelta(session, GetPlayerFromId(playerSrc))
end

function Impl:FinishFarm(playerSrc, progress)
  local player = GetPlayerFromId(playerSrc)
  if not player then return end

  local session = self.farmSessions[playerSrc]
  if not session then
    return ShowNotification(playerSrc, "Chưa bắt đầu farm", "error")
  end

  if not self:IsPlayerNear(playerSrc, self.config.StartCoords, self.config.ZoneRadius + 20.0) then
    return ShowNotification(playerSrc, "Bạn đã rời khỏi khu vực farm", "error")
  end

  self:RecordProgress(session, progress)
  self:PayoutFarmReward(playerSrc, player, session, true)
  self.farmSessions[playerSrc] = nil
end

function Impl:PayoutDroppedPlayer(playerSrc)
  local session = self.farmSessions[playerSrc]
  if not session then return end

  local player = GetPlayerFromId(playerSrc)
  if not player then
    if (session.progress or 0) > (session.paidProgress or 0) then
      self:LogWarning("Can not give pending farm items for dropped player %s because player object was not found", playerSrc)
    end
    self.farmSessions[playerSrc] = nil
    return
  end

  self:PayoutFarmReward(playerSrc, player, session, false)
  self.farmSessions[playerSrc] = nil
end

function Impl:PayoutFarmReward(playerSrc, player, session, notify)
  self:PayProgressDelta(session, player)

  local farmProgress = session.progress or 0
  local earnedItems = session.earnedItems or 0

  if farmProgress >= self.config.MaxProgress then
    local added = AddItem(player, self.config.RareItem, self.config.RareAmount)
    if added then
      if notify then
        self:TriggerItemBox(playerSrc, self.config.RareItem, "add")
      end
      if not notify then return end
      return ShowNotification(playerSrc, ("Hoàn thành 200/200, nhận %sx %s và %sx vật phẩm hiếm"):format(earnedItems, self.config.FarmItem, self.config.RareAmount), "success")
    end

    if not notify then return end
    return ShowNotification(playerSrc, ("Nhận %sx %s, nhưng không thể nhận vật phẩm hiếm vì túi đồ đầy"):format(earnedItems, self.config.FarmItem), "error")
  end

  if earnedItems > 0 then
    if not notify then return end
    return ShowNotification(playerSrc, ("Kết thúc công việc, nhận %sx %s"):format(earnedItems, self.config.FarmItem), "success")
  end

  if not notify then return end
  ShowNotification(playerSrc, "Kết thúc công việc, chưa có vật phẩm", "primary")
end

function Impl:RecordProgress(session, progress)
  local validProgress = self:GetValidProgress(session, progress)
  session.progress = math.max(session.progress or 0, validProgress)
  return session.progress
end

function Impl:PayProgressDelta(session, player)
  if not player then return 0 end

  local progress = session.progress or 0
  local paidProgress = session.paidProgress or 0
  local delta = progress - paidProgress
  if delta <= 0 then return 0 end

  local amount = delta * self.config.FarmItemAmount
  local added = AddItem(player, self.config.FarmItem, amount)
  if not added then return 0 end

  session.paidProgress = progress
  session.earnedItems = (session.earnedItems or 0) + amount

  return amount
end

function Impl:GetValidProgress(session, progress)
  local clientProgress = math.floor(tonumber(progress) or 0)
  clientProgress = math.max(0, math.min(clientProgress, self.config.MaxProgress))

  local elapsedMs = (os.time() - session.startedAt) * 1000
  local maxByTime = math.floor((elapsedMs + 5000) / self.config.FarmDuration)
  maxByTime = math.max(0, math.min(maxByTime, self.config.MaxProgress))

  return math.min(clientProgress, maxByTime)
end

function Impl:IsPlayerNear(playerSrc, coords, radius)
  local ped = GetPlayerPed(playerSrc)
  if not ped or ped == 0 then return false end

  local playerCoords = GetEntityCoords(ped)
  return #(playerCoords - coords) <= radius
end

function Impl:TriggerItemBox(playerSrc, itemName, action)
  if Config.Framework ~= "qb" then return end
  if not Framework.Shared or not Framework.Shared.Items or not Framework.Shared.Items[itemName] then return end

  TriggerClientEvent("inventory:client:ItemBox", playerSrc, Framework.Shared.Items[itemName], action)
end

function Impl:OnDestroy()
  self.farmSessions = {}
end

function Impl:OnResourceStop()
  self.farmSessions = {}
end
