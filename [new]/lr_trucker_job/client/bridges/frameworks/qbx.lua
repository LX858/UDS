LR = LR or {}

LR.RegisterClientFrameworkBridge({
  name = "qbx",
  resourceName = "qbx_core",
  create = function(context)
    local runtime = context.runtime
    local readiness = context.readiness
    local loadedSignal = runtime:CreateSignal()
    local unloadedSignal = runtime:CreateSignal()
    local changedSignal = runtime:CreateSignal()
    local bridge = {}
    local loaded = false
    local playerData = runtime:CallExport(context.resourceName, "GetPlayerData")
    if playerData ~= nil and type(playerData) ~= "table" then
      error("qbx_core GetPlayerData returned invalid player data")
    end

    local function readPlayerData()
      local ok, data = pcall(function()
        return runtime:CallExport(context.resourceName, "GetPlayerData")
      end)
      if ok and type(data) == "table" then playerData = data end
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
      local text = normalized.title and {
        text = normalized.title,
        caption = normalized.message,
      } or normalized.message
      runtime:CallExport(
        context.resourceName,
        "Notify",
        text,
        normalized.type,
        normalized.duration
      )
      return true
    end

    function bridge:OnPlayerLoaded(callback) return loadedSignal:Subscribe(callback) end
    function bridge:OnPlayerUnloaded(callback) return unloadedSignal:Subscribe(callback) end
    function bridge:OnPlayerDataChanged(callback) return changedSignal:Subscribe(callback) end

    runtime:On("QBCore:Client:OnPlayerLoaded", function()
      local wasLoaded = loaded
      loaded = true
      readPlayerData()
      readiness:MarkReady()
      if not wasLoaded then loadedSignal:Emit(snapshot()) end
    end)
    local function handleUnload()
      local wasLoaded = loaded
      loaded = false
      playerData = nil
      if wasLoaded then unloadedSignal:Emit() end
    end
    runtime:OnNet("QBCore:Client:OnPlayerUnload", handleUnload)
    runtime:OnNet("qbx_core:client:playerLoggedOut", handleUnload)
    runtime:OnNet("QBCore:Player:SetPlayerData", function(data)
      if type(data) == "table" then playerData = data end
      changedSignal:Emit(snapshot(), "playerData")
    end)
    runtime:OnNet("QBCore:Client:OnJobUpdate", function(job)
      local data = playerData
      if type(data) == "table" then data.job = job end
      changedSignal:Emit(snapshot(), "job")
    end)
    runtime:OnNet("QBCore:Client:OnGangUpdate", function(gang)
      local data = playerData
      if type(data) == "table" then data.gang = gang end
      changedSignal:Emit(snapshot(), "gang")
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
