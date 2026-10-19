LR = LR or {}

LR.RegisterClientFrameworkBridge({
  name = "esx",
  resourceName = "es_extended",
  create = function(context)
    local runtime = context.runtime
    local readiness = context.readiness
    local core = runtime:CallExport(context.resourceName, "getSharedObject")
    if type(core) ~= "table" then error("es_extended getSharedObject returned an invalid core") end

    local loadedSignal = runtime:CreateSignal()
    local unloadedSignal = runtime:CreateSignal()
    local changedSignal = runtime:CreateSignal()
    local bridge = {}
    local playerData = type(core.PlayerData) == "table" and core.PlayerData or nil
    local loaded = core.PlayerLoaded == true

    if runtime:IsCallable(core.IsPlayerLoaded) then
      local ok, result = pcall(function() return runtime:Call(core.IsPlayerLoaded) end)
      loaded = ok and result == true or loaded
    end
    if not loaded then playerData = nil end

    function bridge:GetPlayerData()
      if not loaded then return nil end
      return runtime:NormalizePlayer(playerData)
    end

    function bridge:IsPlayerLoaded()
      return loaded
    end

    function bridge:Notify(notification)
      local normalized = runtime:NormalizeNotification(notification)
      if not runtime:IsCallable(core.ShowNotification) then return false end
      local esxType = normalized.type == "inform" and "info"
        or normalized.type == "warning" and "info"
        or normalized.type
      runtime:Call(core.ShowNotification, normalized.message, esxType, normalized.duration, normalized.title)
      return true
    end

    function bridge:OnPlayerLoaded(callback) return loadedSignal:Subscribe(callback) end
    function bridge:OnPlayerUnloaded(callback) return unloadedSignal:Subscribe(callback) end
    function bridge:OnPlayerDataChanged(callback) return changedSignal:Subscribe(callback) end

    runtime:OnNet("esx:playerLoaded", function(data)
      playerData = type(data) == "table" and data
        or type(core.PlayerData) == "table" and core.PlayerData
        or nil
      loaded = true
      readiness:MarkReady()
      loadedSignal:Emit(bridge:GetPlayerData())
    end)
    runtime:OnNet("esx:onPlayerLogout", function()
      local wasLoaded = loaded
      loaded = false
      playerData = nil
      if wasLoaded then unloadedSignal:Emit() end
    end)
    runtime:On("esx:setPlayerData", function(key, value)
      if type(playerData) == "table" and type(key) == "string" then playerData[key] = value end
      changedSignal:Emit(bridge:GetPlayerData(), key)
    end)

    if loaded then readiness:MarkReady() end

    function bridge:Dispose()
      loadedSignal:Dispose()
      unloadedSignal:Dispose()
      changedSignal:Dispose()
    end

    return bridge
  end,
})
