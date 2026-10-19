TriggerClientEvent("fixture:client", 1, {})
local routingBucket = GetPlayerRoutingBucket("1")
if routingBucket < 0 then
  error("routing bucket must be non-negative")
end
local serverSource = source
if serverSource < 0 then
  error("server source must be non-negative")
end

local app = LR.CreateServerApplication({ resourceName = ResourceName, debug = true })
app:RegisterModule({
  id = "server_fixture",
  create = function(context)
    ---@class LRServer.FixtureModule : LRServer.ModuleInstance
    local instance = {}
    ---@param readyContext LRServer.ModuleContext
    function instance:OnReady(readyContext)
      readyContext.net.Trucker.events.notice:Emit(1, { type = "inform", message = "ready" })
    end
    ---@param startContext LRServer.ModuleContext
    function instance:Start(startContext)
      startContext.logger:Debug("server fixture")
      context.logger:Debug("server side %s", context.side)
      local framework = startContext.services.framework
      local frameworkPlayer = framework and framework:GetPlayer(1) or nil
      if frameworkPlayer then
        startContext.logger:Debug("framework player %s", frameworkPlayer.name or "unknown")
      end
    end
    return instance
  end,
})

local disposeRpc = LR.Net.Trucker.rpc.getState:Handle(function(_playerSource, _request)
  return {
    player = { source = 1, citizenId = "fixture", name = "Fixture", cash = 0, level = 1, xp = 0 },
    orders = {},
    team = { id = "", hostCitizenId = "", members = {} },
    mission = {
      active = false,
      status = "idle",
      id = "",
      routeIndex = 0,
      name = "",
      itemLabel = "",
      destination = "",
      logisticsUnits = 0,
      step = 0,
      packageAmount = 0,
      loaded = 0,
      delivered = 0,
      reward = 0,
      xp = 0,
      truckNetId = 0,
      trailerNetId = 0,
      escortNetId = 0,
      packages = {},
    },
  }
end)
LR.Net.Trucker.events.notice:Emit(1, { type = "inform", message = "typed server event" })
disposeRpc()
