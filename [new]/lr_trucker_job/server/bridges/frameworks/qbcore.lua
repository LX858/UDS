LR = LR or {}

LR.RegisterServerFrameworkBridge({
  name = "qbcore",
  resourceName = "qb-core",
  create = function(context)
    local runtime = context.runtime
    local readiness = context.readiness
    local core = runtime:CallExport(context.resourceName, "GetCoreObject")
    if type(core) ~= "table" or type(core.Functions) ~= "table"
      or not runtime:IsCallable(core.Functions.GetPlayer) then
      error("qb-core GetCoreObject returned an invalid server core")
    end

    local loadedSignal = runtime:CreateSignal()
    local unloadedSignal = runtime:CreateSignal()
    local changedSignal = runtime:CreateSignal()
    local bridge = {}
    local knownLoaded = {}

    local function getRawPlayer(playerSource)
      local ok, player = pcall(function() return runtime:Call(core.Functions.GetPlayer, playerSource) end)
      if not ok or type(player) ~= "table" then return nil end
      return player
    end

    function bridge:GetPlayer(playerSource)
      local player = getRawPlayer(playerSource)
      return player and runtime:NormalizePlayer(player.PlayerData, playerSource) or nil
    end

    function bridge:IsPlayerLoaded(playerSource)
      return getRawPlayer(playerSource) ~= nil
    end

    function bridge:Notify(playerSource, notification)
      local normalized = runtime:NormalizeNotification(notification)
      if not getRawPlayer(playerSource) or not runtime:IsCallable(core.Functions.Notify) then return false end
      local qbType = normalized.type == "inform" and "primary"
        or normalized.type == "warning" and "primary"
        or normalized.type
      local text = normalized.title and {
        text = normalized.title,
        caption = normalized.message,
      } or normalized.message
      runtime:Call(core.Functions.Notify, playerSource, text, qbType, normalized.duration)
      return true
    end

    function bridge:GetMoney(playerSource, account)
      local player = getRawPlayer(playerSource)
      local money = player and player.PlayerData and player.PlayerData.money
      return math.max(0, math.floor(tonumber(money and money[account]) or 0))
    end

    function bridge:AddMoney(playerSource, account, amount, reason)
      local player = getRawPlayer(playerSource)
      if not player or type(player.Functions) ~= "table"
        or not runtime:IsCallable(player.Functions.AddMoney) then return false end
      local ok, result = pcall(function()
        return runtime:Call(player.Functions.AddMoney, account, math.floor(amount), reason)
      end)
      return ok and result ~= false
    end

    function bridge:RemoveMoney(playerSource, account, amount, reason)
      local player = getRawPlayer(playerSource)
      if not player or type(player.Functions) ~= "table"
        or not runtime:IsCallable(player.Functions.RemoveMoney) then return false end
      local ok, result = pcall(function()
        return runtime:Call(player.Functions.RemoveMoney, account, math.floor(amount), reason)
      end)
      return ok and result ~= false
    end

    function bridge:GetMetadata(playerSource, key)
      local player = getRawPlayer(playerSource)
      local metadata = player and player.PlayerData and player.PlayerData.metadata
      return metadata and metadata[key] or nil
    end

    function bridge:SetMetadata(playerSource, key, value)
      local player = getRawPlayer(playerSource)
      if not player or type(player.Functions) ~= "table"
        or not runtime:IsCallable(player.Functions.SetMetaData) then return false end
      return pcall(function() runtime:Call(player.Functions.SetMetaData, key, value) end)
    end

    function bridge:OnPlayerLoaded(callback) return loadedSignal:Subscribe(callback) end
    function bridge:OnPlayerUnloaded(callback) return unloadedSignal:Subscribe(callback) end
    function bridge:OnPlayerDataChanged(callback) return changedSignal:Subscribe(callback) end

    local function handleLoaded(playerSource, player)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      player = type(player) == "table" and player or getRawPlayer(playerSource)
      if not player then return end
      local wasLoaded = knownLoaded[playerSource] == true
      knownLoaded[playerSource] = true
      if not wasLoaded then loadedSignal:Emit(playerSource, bridge:GetPlayer(playerSource)) end
    end
    runtime:OnNet("QBCore:Server:OnPlayerLoaded", function()
      handleLoaded(runtime:GetEventSource())
    end)
    runtime:On("QBCore:Server:PlayerLoaded", function(player)
      local data = type(player) == "table" and player.PlayerData or nil
      handleLoaded(data and data.source, player)
    end)
    runtime:On("QBCore:Server:OnPlayerUnload", function(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      local shouldEmit = knownLoaded[playerSource] ~= false
      knownLoaded[playerSource] = false
      if shouldEmit then unloadedSignal:Emit(playerSource) end
    end)
    runtime:On("QBCore:Server:OnPlayerUpdated", function(playerSource, key)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      changedSignal:Emit(playerSource, bridge:GetPlayer(playerSource), key)
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
