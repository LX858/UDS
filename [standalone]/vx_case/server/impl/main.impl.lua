---@class MainImpl : Impl
local Impl = NewImpl("Main")

function Impl:Init()
  self.rewards = Config.Rewards
  self.percentages = {}
  self.activeCaseItems = {}

  for caseItem, rewards in pairs(self.rewards) do
    self.percentages[caseItem] = Percentage(caseItem, 1000, rewards)
  end

  self:EventHandlers()
  self:LogInfo("%s initialized", self:GetName())
end

---@param playerId number
---@param item string
---@param count number
---@param metadata table|nil
---@return boolean, string|nil
function Impl:AddRewardItem(playerId, item, count, metadata)
  local added, inventoryMessage = exports.ox_inventory:AddItem(playerId, item, count, metadata or {})
  if added then
    return true
  end

  -- Nếu túi đồ đầy, chuyển phần thưởng vào kho cá nhân của buucuc.
  -- Kiểm tra resource trước để tránh lỗi nếu buucuc chưa được chạy.
  if GetResourceState("xn_buucuc") == "started" then
    local player = exports.qbx_core:GetPlayer(playerId)
    local citizenid = player and player.PlayerData and player.PlayerData.citizenid

    if citizenid then
      local canAdd, canAddMessage = exports.xn_buucuc:CanAddToPersonalStorage(
        citizenid,
        item,
        count
      )

      if canAdd then
        local stored, storageMessage = exports.xn_buucuc:AddItemToPersonalStorage(
          citizenid,
          item,
          count,
          metadata or {}
        )

        if stored then
          TriggerClientEvent(
            "vongquaytrungthu:client:showNotify",
            playerId,
            "Túi đồ đầy, phần thưởng đã được chuyển vào bưu cục"
          )
          return true
        end

        inventoryMessage = storageMessage or inventoryMessage
      else
        inventoryMessage = canAddMessage or inventoryMessage
      end
    end
  end

  TriggerClientEvent(
    "vongquaytrungthu:client:showNotify",
    playerId,
    "Không thể thêm phần thưởng vào túi đồ hoặc bưu cục"
  )
  self:LogWarning(
    "Không thể thêm reward %s x%s cho player %s: %s",
    item,
    count,
    playerId,
    inventoryMessage or "unknown error"
  )
  return false, inventoryMessage
end

---@param playerId number
---@param caseItem string
---@param count number
function Impl:RefundCaseItem(playerId, caseItem, count)
  local refunded, refundMessage = exports.ox_inventory:AddItem(playerId, caseItem, count)
  if refunded then
    TriggerClientEvent(
      "vongquaytrungthu:client:showNotify",
      playerId,
      "Không thể trao phần thưởng, hòm đã được hoàn trả"
    )
    return
  end

  self:LogWarning(
    "Không thể hoàn trả %s x%s cho player %s: %s",
    caseItem,
    count,
    playerId,
    refundMessage or "unknown error"
  )
end

function Impl:EventHandlers()
  for caseItem in pairs(self.rewards) do
    local itemName = caseItem
    exports.qbx_core:CreateUseableItem(itemName, function(playerSrc)
      local source = tonumber(playerSrc)
      local player = exports.qbx_core:GetPlayer(source)
      if not player then return end
      if exports.ox_inventory:GetItemCount(source, itemName) <= 0 then
        return
      end

      self.activeCaseItems[source] = itemName
      TriggerClientEvent("vongquaytrungthu:client:show", source, itemName)
    end)
  end

  lib.callback.register("vongquaytrungthu:server:getRewards", function(playerId)
    local caseItem = self.activeCaseItems[playerId]
    return caseItem and self.rewards[caseItem] or {}
  end)

  lib.callback.register("vongquaytrungthu:server:getItemCount", function(playerId)
    local caseItem = self.activeCaseItems[playerId]
    if not caseItem or not self.rewards[caseItem] then return 0 end
    return exports.ox_inventory:GetItemCount(playerId, caseItem) or 0
  end)

  lib.callback.register("vongquaytrungthu:server:getReward", function(playerId, multiplier)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return nil, "Người chơi không tồn tại" end

    local caseItem = self.activeCaseItems[playerId]
    local percentage = caseItem and self.percentages[caseItem]
    if not percentage then
      return nil, "Hòm không hợp lệ, vui lòng sử dụng lại vật phẩm"
    end

    local amount = math.max(1, math.floor(tonumber(multiplier) or 1))
    if not exports.ox_inventory:RemoveItem(playerId, caseItem, amount) then
      return nil, "Bạn không có đủ hòm để mở"
    end

    local result = nil
    percentage:GetReward(amount, function(rewards)
      for i = 1, #rewards do
        local reward = rewards[i]
        if reward.type == "account" then
          player.Functions.AddMoney(reward.name, reward.amount or 0, "trung-thu-reward")
        else
          local rewardName = reward.name
          local rewardAmount = reward.amount or 1
          local rewardMetadata = reward.metadata or {}
          SetTimeout(10000, function()
            local added = self:AddRewardItem(playerId, rewardName, rewardAmount, rewardMetadata)
            if not added then
              self:RefundCaseItem(playerId, caseItem, 1)
            end
          end)
        end
        percentage:RemoveRate(reward.id)
      end
      table.sort(rewards, function(a, b)
        return (a.percent or 0) < (b.percent or 0)
      end)
      result = rewards
    end)
    while result == nil do
      Citizen.Wait(10)
    end
    return result, "Bắt đầu quay, chúc bạn may mắn!"
  end)

  RegisterNetEvent("vongquaytrungthu:server:close", function()
    self.activeCaseItems[source] = nil
  end)

  AddEventHandler("playerDropped", function()
    self.activeCaseItems[source] = nil
  end)
end

function Impl:GetResultLabels(results)
  if not results or #results == 0 then return "" end
  local grouped = {}
  for _, item in ipairs(results) do
    local key = item.label or item.name
    if not grouped[key] then
      grouped[key] = { label = key, amount = item.amount or 1 }
    else
      grouped[key].amount = grouped[key].amount + (item.amount or 1)
    end
  end
  local labels = {}
  for _, item in pairs(grouped) do
    if item.amount > 1 then
      table.insert(labels, string.format("%d %s", item.amount, item.label))
    else
      table.insert(labels, item.label)
    end
  end
  return table.concat(labels, ", ")
end
