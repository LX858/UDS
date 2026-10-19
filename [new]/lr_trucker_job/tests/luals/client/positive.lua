SendNUIMessage({ event = "main:setShow", data = true })
AbortTextChat()

---@type vector3
local coords = GetEntityCoords(PlayerPedId())

---@return LRTruckerStateSnapshot
local function fixtureSnapshot()
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
end

local app = LR.CreateClientApplication({ resourceName = ResourceName, debug = true })
app:RegisterModule({
  id = "client_fixture",
  create = function(context)
    ---@class LRClient.FixtureModule : LRClient.ModuleInstance
    local instance = {}
    ---@param readyContext LRClient.ModuleContext
    function instance:OnReady(readyContext)
      readyContext.nui.Trucker().state.snapshot:Set(fixtureSnapshot())
    end
    ---@param startContext LRClient.ModuleContext
    function instance:Start(startContext)
      startContext.logger:Debug("client fixture %s", coords.x)
      context.logger:Debug("client side %s", context.side)
      local framework = startContext.services.framework
      local frameworkPlayer = framework and framework:GetPlayerData() or nil
      if frameworkPlayer and frameworkPlayer.job then
        startContext.logger:Debug("client job %s", frameworkPlayer.job.name or "unknown")
      end
    end
    return instance
  end,
})

local netResult = LR.Net.Trucker.rpc.getState:Call({})
if netResult.player.level < 0 then
  error("network player level must be non-negative")
end
local nui = LR.Nui.Trucker()
nui.state.snapshot:Set(fixtureSnapshot())
nui.state.visibility:Set({ visible = true })
nui.state.visibility:Patch({ visible = false })
nui.state.settings:Set({ locale = {}, dev = true })
local mainNui = LR.Nui.Main()
mainNui.state.game:Set({ playerName = "Ada", playerId = "42" })
local disposePublic = LR.Public.Trucker:Register({
  open = function(_request)
    return { success = true, message = "" }
  end,
  getSnapshot = function(request)
    return LR.External.Trucker("other_resource"):GetSnapshot(request)
  end,
})
local externalSnapshot = LR.External.Trucker("other_resource"):GetSnapshot({})
if externalSnapshot.player.level < 0 then
  error("external player level must be non-negative")
end
disposePublic()
