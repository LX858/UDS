LR = LR or {}

LR.RegisterServerFrameworkBridge({
  name = "qbx",
  resourceName = "qbx_core",
  create = function(context)
    local runtime = context.runtime
    local readiness = context.readiness
    runtime:CallExport(context.resourceName, "GetPlayer", 0)
    local loadedSignal = runtime:CreateSignal()
    local unloadedSignal = runtime:CreateSignal()
    local changedSignal = runtime:CreateSignal()
    local bridge = {}
    local knownLoaded = {}

    local function getRawPlayer(playerSource)
      local ok, player = pcall(function()
        return runtime:CallExport(context.resourceName, "GetPlayer", playerSource)
      end)
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
      if not getRawPlayer(playerSource) then return false end
      local text = normalized.title and {
        text = normalized.title,
        caption = normalized.message,
      } or normalized.message
      runtime:CallExport(
        context.resourceName,
        "Notify",
        playerSource,
        text,
        normalized.type,
        normalized.duration
      )
      return true
    end

    function bridge:GetMoney(playerSource, account)
      local ok, amount = pcall(function()
        return runtime:CallExport(context.resourceName, "GetMoney", playerSource, account)
      end)
      return ok and math.max(0, math.floor(tonumber(amount) or 0)) or 0
    end

    function bridge:AddMoney(playerSource, account, amount, reason)
      local ok, result = pcall(function()
        return runtime:CallExport(
          context.resourceName,
          "AddMoney",
          playerSource,
          account,
          math.floor(amount),
          reason
        )
      end)
      return ok and result ~= false
    end

    function bridge:RemoveMoney(playerSource, account, amount, reason)
      local ok, result = pcall(function()
        return runtime:CallExport(
          context.resourceName,
          "RemoveMoney",
          playerSource,
          account,
          math.floor(amount),
          reason
        )
      end)
      return ok and result ~= false
    end

    function bridge:GetMetadata(playerSource, key)
      local ok, value = pcall(function()
        return runtime:CallExport(context.resourceName, "GetMetadata", playerSource, key)
      end)
      return ok and value or nil
    end

    function bridge:SetMetadata(playerSource, key, value)
      local ok = pcall(function()
        runtime:CallExport(context.resourceName, "SetMetadata", playerSource, key, value)
      end)
      return ok
    end

    function bridge:GiveVehicleKeys(playerSource, vehicle)
      if runtime:GetResourceState("Renewed-Vehiclekeys") == "started" then 
        local ok, result = pcall(function()
          return runtime:CallExport(
            "Renewed-Vehiclekeys",
            "addKey",
            playerSource,
            GetVehicleNumberPlateText(vehicle)
          )
        end)
        return ok and result ~= false
      end
      if runtime:GetResourceState("qbx_vehiclekeys") ~= "started" then return true end
      local ok, result = pcall(function()
        return runtime:CallExport("qbx_vehiclekeys", "GiveKeys", playerSource, vehicle)
      end)
      return ok and result ~= false
    end

    function bridge:PrepareOwnedVehicle(vehicle, data)
      if not vehicle or vehicle == 0 or type(data) ~= "table" then return false end
      ---@diagnostic disable-next-line: undefined-global
      if type(Entity) == "function" then
        ---@diagnostic disable-next-line: undefined-global
        local state = Entity(vehicle).state
        state:set("vehicleid", data.vehicleId, false)
        if type(data.props) == "table" then
          state:set("ox_lib:setVehicleProperties", data.props, true)
        end
      end
      if data.plate and type(SetVehicleNumberPlateText) == "function" then
        SetVehicleNumberPlateText(vehicle, data.plate)
      end
      return true
    end

    function bridge:OnPlayerLoaded(callback) return loadedSignal:Subscribe(callback) end
    function bridge:OnPlayerUnloaded(callback) return unloadedSignal:Subscribe(callback) end
    function bridge:OnPlayerDataChanged(callback) return changedSignal:Subscribe(callback) end

    local function handleLoaded(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource or not getRawPlayer(playerSource) then return end
      local wasLoaded = knownLoaded[playerSource] == true
      knownLoaded[playerSource] = true
      if not wasLoaded then loadedSignal:Emit(playerSource, bridge:GetPlayer(playerSource)) end
    end
    runtime:OnNet("QBCore:Server:OnPlayerLoaded", function()
      handleLoaded(runtime:GetEventSource())
    end)
    local function handleUnloaded(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      local shouldEmit = knownLoaded[playerSource] ~= false
      knownLoaded[playerSource] = false
      if shouldEmit then unloadedSignal:Emit(playerSource) end
    end
    runtime:On("QBCore:Server:OnPlayerUnload", handleUnloaded)
    runtime:On("playerDropped", function()
      handleUnloaded(runtime:GetEventSource())
    end)
    runtime:On("QBCore:Server:OnJobUpdate", function(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      changedSignal:Emit(playerSource, bridge:GetPlayer(playerSource), "job")
    end)
    runtime:On("QBCore:Server:SetDuty", function(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      changedSignal:Emit(playerSource, bridge:GetPlayer(playerSource), "job")
    end)
    runtime:On("QBCore:Server:OnGangUpdate", function(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      changedSignal:Emit(playerSource, bridge:GetPlayer(playerSource), "gang")
    end)
    runtime:On("qbx_core:server:onGroupUpdate", function(playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      changedSignal:Emit(playerSource, bridge:GetPlayer(playerSource), "groups")
    end)
    runtime:On("qbx_core:server:onSetMetaData", function(_key, _oldValue, _newValue, playerSource)
      playerSource = tonumber(playerSource)
      if not playerSource then return end
      changedSignal:Emit(playerSource, bridge:GetPlayer(playerSource), "metadata")
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
