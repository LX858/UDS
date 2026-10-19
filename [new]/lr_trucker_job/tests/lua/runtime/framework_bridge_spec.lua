LR = nil

dofile("shared/core/lr.lua")
dofile("shared/core/logger_v2.lua")
dofile("shared/core/disposables.lua")
dofile("shared/core/module_registry.lua")
dofile("shared/core/application.lua")
dofile("client/bridges/framework.lua")
dofile("client/bridges/frameworks/esx.lua")
dofile("client/bridges/frameworks/qbcore.lua")
dofile("client/bridges/frameworks/qbx.lua")
dofile("server/bridges/framework.lua")
dofile("server/bridges/frameworks/esx.lua")
dofile("server/bridges/frameworks/qbcore.lua")
dofile("server/bridges/frameworks/qbx.lua")

local function assertEqual(actual, expected, message)
  if actual ~= expected then
    error(("%s: expected %s, got %s"):format(message, tostring(expected), tostring(actual)))
  end
end

local function assertTrue(value, message)
  if value ~= true then error(message) end
end

local function callable(callback)
  return setmetatable({}, {
    __call = function(_, ...) return callback(...) end,
  })
end

local function newEventBus()
  local handlers = {}
  local removed = {}
  local bus = {}

  function bus.add(name, handler)
    local token = #handlers + 1
    handlers[token] = { name = name, handler = handler }
    return token
  end

  function bus.remove(token)
    removed[token] = true
  end

  function bus.registerNet(name)
    bus.netEvents = bus.netEvents or {}
    bus.netEvents[name] = true
  end

  function bus.emit(name, ...)
    for token = 1, #handlers do
      local entry = handlers[token]
      if not removed[token] and entry.name == name then entry.handler(...) end
    end
  end

  function bus.removedCount()
    local count = 0
    for _ in pairs(removed) do count = count + 1 end
    return count
  end


  function bus.isNet(name)
    return bus.netEvents and bus.netEvents[name] == true or false
  end

  return bus
end

local function resourceStates(started)
  return function(resourceName)
    return started[resourceName] and "started" or "missing"
  end
end

local standalone = LR.CreateClientFrameworkServices({ name = "standalone" })
assertEqual(standalone.framework.name, "standalone", "standalone client name")
assertTrue(standalone.readiness:IsReady(), "standalone client readiness should be immediate")
standalone.framework:Dispose()

local ambiguousOk, ambiguousErr = pcall(function()
  LR.CreateClientFrameworkServices({
    name = "auto",
    getResourceState = resourceStates({ ["qb-core"] = true, qbx_core = true }),
  })
end)
if ambiguousOk or not tostring(ambiguousErr):find("ambiguous", 1, true) then
  error("auto detection must reject multiple active frameworks")
end

do
  local bus = newEventBus()
  local notifications = {}
  local core = {
    PlayerLoaded = false,
    PlayerData = {},
    ShowNotification = function(message, notificationType, duration, title)
      notifications[#notifications + 1] = {
        message = message,
        type = notificationType,
        duration = duration,
        title = title,
      }
    end,
  }
  local services = LR.CreateClientFrameworkServices({
    name = "esx",
    getResourceState = resourceStates({ es_extended = true }),
    exports = {
      es_extended = {
        getSharedObject = function() return core end,
      },
    },
    addEventHandler = bus.add,
    removeEventHandler = bus.remove,
    registerNetEvent = bus.registerNet,
  })
  local loadedPlayer
  local unloaded = 0
  services.framework:OnPlayerLoaded(function(player) loadedPlayer = player end)
  services.framework:OnPlayerUnloaded(function() unloaded = unloaded + 1 end)

  local playerData = {
    source = 7,
    identifier = "license:esx",
    firstName = "Ada",
    lastName = "Lovelace",
    job = { name = "police", grade = 3, grade_name = "sergeant" },
  }
  bus.emit("esx:playerLoaded", playerData)
  assertTrue(bus.isNet("esx:playerLoaded"), "ESX load event must be registered for network use")
  assertTrue(bus.isNet("esx:onPlayerLogout"), "ESX logout event must be registered for network use")
  assertTrue(services.readiness:IsReady(), "ESX load event should mark client readiness")
  assertEqual(loadedPlayer.name, "Ada Lovelace", "ESX normalized name")
  assertEqual(loadedPlayer.job.grade, 3, "ESX normalized grade")
  assertTrue(services.framework:Notify({
    message = "hello",
    type = "inform",
    duration = 1500,
    title = "ESX",
  }), "ESX notify should be available")
  assertEqual(notifications[1].type, "info", "ESX notification type mapping")
  bus.emit("esx:onPlayerLogout")
  assertEqual(unloaded, 1, "ESX unload signal")
  assertEqual(services.framework:GetPlayerData(), nil, "ESX data must clear after logout")
  services.framework:Dispose()
  assertEqual(bus.removedCount(), 3, "ESX client handlers should be removed")
end

do
  local bus = newEventBus()
  local playerData = {
    source = 11,
    citizenid = "citizen-qb",
    license = "license:qb",
    charinfo = { firstname = "Grace", lastname = "Hopper" },
    job = {
      name = "mechanic",
      grade = { level = 2, name = "lead" },
      onduty = false,
    },
  }
  local notifiedType
  local core = {
    Functions = {
      GetPlayerData = function() return playerData end,
      Notify = function(_message, notificationType) notifiedType = notificationType end,
    },
  }
  local services = LR.CreateClientFrameworkServices({
    name = "qbcore",
    getResourceState = resourceStates({ ["qb-core"] = true }),
    exports = {
      ["qb-core"] = {
        GetCoreObject = function() return core end,
      },
    },
    addEventHandler = bus.add,
    removeEventHandler = bus.remove,
    registerNetEvent = bus.registerNet,
  })
  assertTrue(bus.isNet("QBCore:Client:OnPlayerLoaded"), "QBCore load event must be network-safe")
  assertTrue(bus.isNet("QBCore:Client:OnPlayerUnload"), "QBCore unload event must be network-safe")
  assertTrue(bus.isNet("QBCore:Client:OnPlayerUpdated"), "QBCore update event must be network-safe")
  assertTrue(services.readiness:IsReady(), "QBCore existing player should mark readiness")
  local player = services.framework:GetPlayerData()
  assertEqual(player.citizenId, "citizen-qb", "QBCore citizen ID")
  assertEqual(player.name, "Grace Hopper", "QBCore normalized name")
  assertEqual(player.job.onDuty, false, "QBCore off-duty value")
  services.framework:Notify({ message = "warning", type = "warning" })
  assertEqual(notifiedType, "primary", "QBCore warning notification mapping")
  playerData.job = { name = "doctor", grade = { level = 3 } }
  bus.emit("QBCore:Client:OnPlayerUpdated", "job", playerData.job)
  assertEqual(services.framework:GetPlayerData().job.name, "doctor", "QBCore keyed player update")
  bus.emit("QBCore:Client:OnPlayerUnload")
  assertEqual(services.framework:GetPlayerData(), nil, "QBCore data must clear after logout")
  services.framework:Dispose()
end

do
  local bus = newEventBus()
  local playerData = {
    source = 12,
    citizenid = "citizen-qbx",
    charinfo = { firstname = "Katherine", lastname = "Johnson" },
    gang = { name = "none", grade = { level = 0 }, onduty = true },
  }
  local notifiedText
  local services = LR.CreateClientFrameworkServices({
    name = "qbox",
    getResourceState = resourceStates({ qbx_core = true }),
    exports = {
      qbx_core = {
        GetPlayerData = function() return playerData end,
        Notify = function(_, text) notifiedText = text end,
      },
    },
    addEventHandler = bus.add,
    removeEventHandler = bus.remove,
    registerNetEvent = bus.registerNet,
  })
  assertEqual(bus.isNet("QBCore:Client:OnPlayerLoaded"), false, "Qbox load event is local")
  assertTrue(bus.isNet("qbx_core:client:playerLoggedOut"), "Qbox logout event must be network-safe")
  assertTrue(bus.isNet("QBCore:Player:SetPlayerData"), "Qbox player data event must be network-safe")
  assertTrue(bus.isNet("QBCore:Client:OnGangUpdate"), "Qbox gang event must be network-safe")
  assertEqual(services.framework.name, "qbx", "qbox alias should select qbx")
  assertEqual(services.framework:GetPlayerData().name, "Katherine Johnson", "Qbox player")
  services.framework:Notify({ message = "qbox message", title = "qbox title" })
  assertEqual(notifiedText.text, "qbox title", "Qbox client notification title")
  assertEqual(notifiedText.caption, "qbox message", "Qbox client notification message")
  bus.emit("qbx_core:client:playerLoggedOut")
  assertEqual(services.framework:GetPlayerData(), nil, "Qbox data must clear after logout")
  services.framework:Dispose()
end

do
  local bus = newEventBus()
  local xPlayer = {
    source = 21,
    identifier = "license:server-esx",
    getIdentifier = callable(function() return "license:server-esx" end),
    getName = callable(function() return "Margaret Hamilton" end),
    get = callable(function(key)
      if key == "firstName" then return "Margaret" end
      if key == "lastName" then return "Hamilton" end
    end),
    getJob = callable(function() return { name = "engineer", grade = 4, onDuty = false } end),
    showNotification = callable(function() end),
  }
  local core = {
    GetPlayerFromId = callable(function(playerSource)
      if playerSource == 21 then return xPlayer end
    end),
  }
  local services = LR.CreateServerFrameworkServices({
    name = "esx",
    getResourceState = resourceStates({ es_extended = true }),
    exports = {
      es_extended = {
        getSharedObject = function() return core end,
      },
    },
    addEventHandler = bus.add,
    removeEventHandler = bus.remove,
    registerNetEvent = bus.registerNet,
  })
  assertTrue(services.readiness:IsReady(), "ESX server bridge should be ready after core acquisition")
  assertEqual(services.framework:GetPlayer(21).job.name, "engineer", "ESX server player")
  assertEqual(services.framework:GetPlayer(21).job.onDuty, false, "ESX server duty state")
  local loadCount = 0
  services.framework:OnPlayerLoaded(function() loadCount = loadCount + 1 end)
  bus.emit("esx:playerLoaded", 21, xPlayer)
  bus.emit("esx:playerLogout", 21)
  bus.emit("esx:playerLoaded", 21, xPlayer)
  assertEqual(loadCount, 2, "ESX logout must permit the next character load")
  services.framework:Dispose()
end

do
  local bus = newEventBus()
  local eventSource
  local notifiedSource
  local players = {
    [31] = {
      PlayerData = {
        source = 31,
        citizenid = "citizen-server-qb",
        charinfo = { firstname = "Dorothy", lastname = "Vaughan" },
        job = { name = "analyst", grade = { level = 5 } },
      },
    },
  }
  local core = {
    Functions = {
      GetPlayer = callable(function(playerSource) return players[playerSource] end),
      Notify = callable(function(playerSource) notifiedSource = playerSource end),
    },
  }
  local services = LR.CreateServerFrameworkServices({
    name = "qbcore",
    getResourceState = resourceStates({ ["qb-core"] = true }),
    exports = {
      ["qb-core"] = {
        GetCoreObject = function() return core end,
      },
    },
    addEventHandler = bus.add,
    removeEventHandler = bus.remove,
    registerNetEvent = bus.registerNet,
    getEventSource = function() return eventSource end,
  })
  local loadedSource
  services.framework:OnPlayerLoaded(function(playerSource) loadedSource = playerSource end)
  eventSource = 31
  bus.emit("QBCore:Server:OnPlayerLoaded")
  assertEqual(loadedSource, 31, "QBCore server load source")
  assertTrue(bus.isNet("QBCore:Server:OnPlayerLoaded"), "QBCore server load must be network-safe")
  assertEqual(services.framework:GetPlayer(31).name, "Dorothy Vaughan", "QBCore server player")
  local changeCount = 0
  services.framework:OnPlayerDataChanged(function() changeCount = changeCount + 1 end)
  bus.emit("QBCore:Server:OnPlayerUpdated", 31, "job")
  assertEqual(changeCount, 1, "QBCore server update must emit once")
  services.framework:Notify(31, { message = "qb server" })
  assertEqual(notifiedSource, 31, "QBCore callable notification")
  services.framework:Dispose()
end

do
  local bus = newEventBus()
  local notifiedSource
  local notifiedText
  local players = {
    [41] = {
      PlayerData = {
        source = 41,
        name = "connection-name",
        citizenid = "citizen-server-qbx",
        charinfo = { firstname = "Mary", lastname = "Jackson" },
        job = { name = "aerospace", grade = { level = 6 } },
        money = { cash = 200 },
        metadata = { trucker_xp = 15 },
      },
    },
  }
  local services = LR.CreateServerFrameworkServices({
    name = "qbx",
    getResourceState = resourceStates({ qbx_core = true }),
    exports = {
      qbx_core = {
        GetPlayer = function(_, playerSource) return players[playerSource] end,
        Notify = function(_, playerSource, text)
          notifiedSource = playerSource
          notifiedText = text
        end,
        GetMoney = function(_, playerSource, account)
          return players[playerSource].PlayerData.money[account]
        end,
        AddMoney = function(_, playerSource, account, amount)
          local money = players[playerSource].PlayerData.money
          money[account] = money[account] + amount
          return true
        end,
        GetMetadata = function(_, playerSource, key)
          return players[playerSource].PlayerData.metadata[key]
        end,
        SetMetadata = function(_, playerSource, key, value)
          players[playerSource].PlayerData.metadata[key] = value
        end,
      },
    },
    addEventHandler = bus.add,
    removeEventHandler = bus.remove,
    registerNetEvent = bus.registerNet,
    getEventSource = function() return 41 end,
  })
  assertTrue(bus.isNet("QBCore:Server:OnPlayerLoaded"), "Qbox server load must be network-safe")
  assertEqual(services.framework:GetPlayer(41).citizenId, "citizen-server-qbx", "Qbox server player")
  assertEqual(services.framework:GetPlayer(41).name, "Mary Jackson", "Qbox character name precedence")
  local changedKey
  services.framework:OnPlayerDataChanged(function(_source, _player, key) changedKey = key end)
  bus.emit("QBCore:Server:OnGangUpdate", 41)
  assertEqual(changedKey, "gang", "Qbox server gang update")
  assertTrue(services.framework:Notify(41, {
    message = "server qbox message",
    title = "server qbox title",
  }), "Qbox server notify")
  assertEqual(notifiedSource, 41, "Qbox notification source")
  assertEqual(notifiedText.text, "server qbox title", "Qbox server notification title")
  assertEqual(notifiedText.caption, "server qbox message", "Qbox server notification message")
  assertEqual(services.framework:GetMoney(41, "cash"), 200, "Qbox money export read")
  assertTrue(services.framework:AddMoney(41, "cash", 75, "trucker"), "Qbox money export write")
  assertEqual(services.framework:GetMoney(41, "cash"), 275, "Qbox money export update")
  assertEqual(services.framework:GetMetadata(41, "trucker_xp"), 15, "Qbox metadata export read")
  assertTrue(services.framework:SetMetadata(41, "trucker_xp", 40), "Qbox metadata export write")
  assertEqual(services.framework:GetMetadata(41, "trucker_xp"), 40, "Qbox metadata export update")
  local qbxLoadCount = 0
  services.framework:OnPlayerLoaded(function() qbxLoadCount = qbxLoadCount + 1 end)
  bus.emit("QBCore:Server:OnPlayerLoaded")
  bus.emit("playerDropped", "quit")
  bus.emit("QBCore:Server:OnPlayerLoaded")
  assertEqual(qbxLoadCount, 2, "Qbox disconnect must permit source reuse")
  services.framework:Dispose()
end

do
  local originalExports, originalState, originalTimer, originalPrint = exports, GetResourceState, GetGameTimer, print
  local state, mode, now = "started", "catalog", 1000
  local messages = {}
  GetResourceState = function() return state end
  GetGameTimer = function() return now end
  print = function(message) messages[#messages + 1] = message end
  exports = setmetatable({}, {
    __index = function(_, resourceName)
      assertEqual(resourceName, "xn-sellitem", "catalog provider")
      return setmetatable({}, {
        __index = function(_, method)
          assertTrue(method == "IsTruckerjobEnabled" or method == "GetBusinessDeliveryCatalog" or method == "ReserveCleanDelivery", "unexpected business export")
          if mode == "missing" then error("No such export GetBusinessDeliveryCatalog") end
          return function()
            if mode == "throw" then error("test provider database failure") end
            if mode == "nil" then return nil end
            if method == "IsTruckerjobEnabled" then return mode ~= "disabled" end
            if method == "ReserveCleanDelivery" then
              if mode == "reject" then return { success = false, error = "" } end
              if mode == "stock" then return { success = false, error = "STOCK_UNAVAILABLE" } end
              return { success = true, error = "" }
            end
            if mode == "empty" then return {} end
            return {{ itemName = "coconut", availableAmount = 0 }}
          end
        end,
      })
    end,
  })
  local bridge = LR.CreateBusinessIntegrationBridge()
  assertTrue(bridge:IsSourceOnline(), "started provider was reported stopped")
  mode = "disabled"
  assertTrue(bridge:IsSourceOnline(), "disabled provider must remain online for cleanup")
  mode = "catalog"
  assertEqual(bridge:GetCatalog()[1].availableAmount, 0, "zero stock must not mean source unavailable")
  mode = "missing"
  assertEqual(bridge:GetCatalog(), nil, "missing export must degrade safely")
  assertTrue(messages[#messages]:find("No such export", 1, true) ~= nil, "export lookup error was swallowed")
  local count = #messages
  bridge:GetCatalog()
  assertEqual(#messages, count, "repeated failures spammed the console")
  now = now + 30001
  bridge:GetCatalog()
  assertEqual(#messages, count + 1, "persistent failure was never logged again")
  mode = "throw"
  assertEqual(bridge:GetCatalog(), nil, "provider exception escaped the bridge")
  assertTrue(messages[#messages]:find("test provider database failure", 1, true) ~= nil, "provider error was swallowed")
  mode = "nil"
  assertEqual(bridge:GetCatalog(), nil, "invalid catalog was accepted")
  assertTrue(messages[#messages]:find("INVALID_CATALOG: nil", 1, true) ~= nil, "invalid response was not diagnosed")
  count = #messages
  bridge:GetCatalog()
  assertEqual(#messages, count, "invalid response logging was not throttled")
  state = "stopped"
  assertEqual(bridge:GetCatalog(), nil, "stopped source was accepted")
  assertTrue(messages[#messages]:find("RESOURCE_NOT_STARTED: stopped", 1, true) ~= nil, "resource state was hidden")
  state, mode = "started", "empty"
  assertTrue(type(bridge:GetCatalog()) == "table", "empty catalog must not report an outage")
  mode = "catalog"
  assertEqual(bridge:GetCatalog()[1].itemName, "coconut", "bridge did not recover after restart")
  mode = "reject"
  local reserved, reason = bridge:ReserveLine("order:v2:1", "coconut", 2)
  assertEqual(reserved, false, "provider rejection was accepted")
  assertEqual(reason, "RESERVATION_REJECTED", "empty provider error was classified as an outage")
  mode = "stock"
  reserved, reason = bridge:ReserveLine("order:v2:1", "coconut", 2)
  assertEqual(reason, "STOCK_UNAVAILABLE", "business reason was lost")
  mode = "nil"
  reserved, reason = bridge:ReserveLine("order:v2:1", "coconut", 2)
  assertEqual(reason, "SOURCE_PROTOCOL_ERROR", "invalid response was confused with transport failure")
  mode = "throw"
  reserved, reason = bridge:ReserveLine("order:v2:1", "coconut", 2)
  assertEqual(reason, "SOURCE_UNAVAILABLE", "transport failure was not classified")
  exports, GetResourceState, GetGameTimer, print = originalExports, originalState, originalTimer, originalPrint
end

do
  local savedExports, savedState = exports, GetResourceState
  GetResourceState = function() return 'started' end
  local inventory = { weight = 0, maxWeight = 250, slots = 2, items = {} }
  exports = { ox_inventory = {
    GetInventory = function() return inventory end,
    Items = function(_, id)
      if id == 'gao' or id == 'dua_soche' then return { weight = 100, stack = true } end
    end,
  } }
  local bridge = LR.CreateBusinessIntegrationBridge()
  local lines = {
    { destinationItemId = 'gao', destinationAmount = 2, destinationUnit = 'item' },
    { destinationItemId = 'dua_soche', destinationAmount = 1, destinationUnit = 'item' },
  }
  assertEqual(bridge:CanCarryStashBasket('restaurant_shop', lines), false, 'aggregate weight ignored')
  inventory.maxWeight, inventory.slots = 1000, 1
  assertEqual(bridge:CanCarryStashBasket('restaurant_shop', lines), false, 'aggregate slots ignored')
  inventory.slots = 2
  assertTrue(bridge:CanCarryStashBasket('restaurant_shop', lines))
  inventory.items = {{ name = 'gao', count = 1 }}
  assertEqual(bridge:CanCarryStashBasket('restaurant_shop', lines), false, 'delivery metadata improperly stacked')
  inventory.items = {}
  lines[1].destinationItemId = 'missing'
  assertEqual(bridge:CanCarryStashBasket('restaurant_shop', lines), false, 'unknown output accepted')
  exports, GetResourceState = savedExports, savedState
end

print("PASS framework bridge specification")
