LR = LR or {}

LR.RegisterClientFrameworkBridge({
  name = "qbcore",
  resourceName = "qb-core",
  create = function(context)
    local runtime = context.runtime
    local readiness = context.readiness
    local core = runtime:CallExport(context.resourceName, "GetCoreObject")
    if type(core) ~= "table" or type(core.Functions) ~= "table"
      or not runtime:IsCallable(core.Functions.GetPlayerData) then
      error("qb-core GetCoreObject returned an invalid core")
    end

    local loadedSignal = runtime:CreateSignal()
    local unloadedSignal = runtime:CreateSignal()
    local changedSignal = runtime:CreateSignal()
    local bridge = {}
    local playerData
    local loaded = false

    local function readPlayerData()
      local ok, data = pcall(function() return runtime:Call(core.Functions.GetPlayerData) end)
      if ok and type(data) == "table" then playerData = data end
      if not playerData and type(core.PlayerData) == "table" then playerData = core.PlayerData end
      return playerData
    end

    local function snapshot()
      if not loaded then return nil end
      return runtime:NormalizePlayer(playerData)
    end

    local initialData = readPlayerData()
    loaded = type(initialData) == "table"
      and type(initialData.citizenid) == "string"
      and initialData.citizenid ~= ""

    function bridge:GetPlayerData()
      if not loaded then return nil end
      readPlayerData()
      return snapshot()
    end

    function bridge:IsPlayerLoaded() return loaded end

    function bridge:Notify(notification)
      local normalized = runtime:NormalizeNotification(notification)
      if not runtime:IsCallable(core.Functions.Notify) then return false end
      local qbType = normalized.type == "inform" and "primary"
        or normalized.type == "warning" and "primary"
        or normalized.type
      local text = normalized.title and {
        text = normalized.title,
        caption = normalized.message,
      } or normalized.message
      runtime:Call(core.Functions.Notify, text, qbType, normalized.duration)
      return true
    end

    function bridge:OnPlayerLoaded(callback) return loadedSignal:Subscribe(callback) end
    function bridge:OnPlayerUnloaded(callback) return unloadedSignal:Subscribe(callback) end
    function bridge:OnPlayerDataChanged(callback) return changedSignal:Subscribe(callback) end

    runtime:OnNet("QBCore:Client:OnPlayerLoaded", function()
      local wasLoaded = loaded
      loaded = true
      readPlayerData()
      readiness:MarkReady()
      if not wasLoaded then loadedSignal:Emit(snapshot()) end
    end)
    runtime:OnNet("QBCore:Client:OnPlayerUnload", function()
      local wasLoaded = loaded
      loaded = false
      playerData = nil
      if wasLoaded then unloadedSignal:Emit() end
    end)
    runtime:OnNet("QBCore:Client:OnPlayerUpdated", function(key, value)
      if key == "all" and type(value) == "table" then
        playerData = value
      elseif type(key) == "string" then
        playerData = type(playerData) == "table" and playerData or {}
        playerData[key] = value
      end
      changedSignal:Emit(snapshot(), key)
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
