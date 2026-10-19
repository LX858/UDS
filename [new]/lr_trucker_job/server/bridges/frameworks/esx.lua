LR = LR or {}

local function callMethod(runtime, target, name, ...)
  if type(target) ~= "table" or not runtime:IsCallable(target[name]) then return nil end
  local arguments = table.pack(...)
  local ok, value = pcall(function()
    return runtime:Call(target[name], table.unpack(arguments, 1, arguments.n))
  end)
  if not ok then return nil end
  return value
end

LR.RegisterServerFrameworkBridge({
  name = "esx",
  resourceName = "es_extended",
  create = function(context)
    local runtime = context.runtime
    local readiness = context.readiness
    local core = runtime:CallExport(context.resourceName, "getSharedObject")
    if type(core) ~= "table" or not runtime:IsCallable(core.GetPlayerFromId) then
      error("es_extended getSharedObject returned an invalid server core")
    end

    local loadedSignal = runtime:CreateSignal()
    local unloadedSignal = runtime:CreateSignal()
    local changedSignal = runtime:CreateSignal()
    local bridge = {}
    local knownLoaded = {}

    local function getRawPlayer(playerSource)
      local ok, player = pcall(function() return runtime:Call(core.GetPlayerFromId, playerSource) end)
      if not ok or type(player) ~= "table" then return nil end
      return player
    end

    local function normalizeExtendedPlayer(player, playerSource)
      if type(player) ~= "table" then return nil end
      return runtime:NormalizePlayer({
        source = player.source or playerSource,
        identifier = callMethod(runtime, player, "getIdentifier") or player.identifier,
        name = callMethod(runtime, player, "getName") or player.name,
        firstName = callMethod(runtime, player, "get", "firstName"),
        lastName = callMethod(runtime, player, "get", "lastName"),
        job = callMethod(runtime, player, "getJob") or player.job,
      }, playerSource)
    end

    function bridge:GetPlayer(playerSource)
      return normalizeExtendedPlayer(getRawPlayer(playerSource), playerSource)
    end

    function bridge:IsPlayerLoaded(playerSource)
      return getRawPlayer(playerSource) ~= nil
    end

    function bridge:Notify(playerSource, notification)
      local normalized = runtime:NormalizeNotification(notification)
      local player = getRawPlayer(playerSource)
      if not player or not runtime:IsCallable(player.showNotification) then return false end
      local esxType = normalized.type == "inform" and "info"
        or normalized.type == "warning" and "info"
        or normalized.type
      runtime:Call(player.showNotification, normalized.message, esxType, normalized.duration, normalized.title)
      return true
    end

    function bridge:GetMoney(playerSource, account)
      local player = getRawPlayer(playerSource)
      if not player then return 0 end
      if account == "cash" then
        return math.max(0, math.floor(tonumber(callMethod(runtime, player, "getMoney")) or 0))
      end
      local data = callMethod(runtime, player, "getAccount", account)
      return math.max(0, math.floor(tonumber(data and data.money) or 0))
    end

    function bridge:AddMoney(playerSource, account, amount, reason)
      local player = getRawPlayer(playerSource)
      if not player then return false end
      if account == "cash" and runtime:IsCallable(player.addMoney) then
        return pcall(function() runtime:Call(player.addMoney, math.floor(amount), reason) end)
      end
      if not runtime:IsCallable(player.addAccountMoney) then return false end
      return pcall(function() runtime:Call(player.addAccountMoney, account, math.floor(amount), reason) end)
    end

    function bridge:RemoveMoney(playerSource, account, amount, reason)
      local player = getRawPlayer(playerSource)
      if not player then return false end
      if account == "cash" and runtime:IsCallable(player.removeMoney) then
        return pcall(function() runtime:Call(player.removeMoney, math.floor(amount), reason) end)
      end
      if not runtime:IsCallable(player.removeAccountMoney) then return false end
      return pcall(function() runtime:Call(player.removeAccountMoney, account, math.floor(amount), reason) end)
    end

    function bridge:OnPlayerLoaded(callback) return loadedSignal:Subscribe(callback) end
    function bridge:OnPlayerUnloaded(callback) return unloadedSignal:Subscribe(callback) end
    function bridge:OnPlayerDataChanged(callback) return changedSignal:Subscribe(callback) end

    runtime:On("esx:playerLoaded", function(playerSource, player)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      player = type(player) == "table" and player or getRawPlayer(playerSource)
      if not player then return end
      local wasLoaded = knownLoaded[playerSource] == true
      knownLoaded[playerSource] = true
      if not wasLoaded then loadedSignal:Emit(playerSource, normalizeExtendedPlayer(player, playerSource)) end
    end)
    local function handleUnloaded(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      local shouldEmit = knownLoaded[playerSource] ~= false
      knownLoaded[playerSource] = false
      if shouldEmit then unloadedSignal:Emit(playerSource) end
    end
    runtime:On("esx:playerDropped", handleUnloaded)
    runtime:On("esx:playerLogout", handleUnloaded)
    runtime:On("esx:setJob", function(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      changedSignal:Emit(playerSource, bridge:GetPlayer(playerSource), "job")
    end)

    readiness:MarkReady()

    function bridge:Dispose()
      knownLoaded = {}
      loadedSignal:Dispose()
      unloadedSignal:Dispose()
      changedSignal:Dispose()
    end

    return bridge
  end,
})
