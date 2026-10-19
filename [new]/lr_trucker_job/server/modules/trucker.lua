LR = LR or {}
LRTruckerServer = LRTruckerServer or {}

local TruckerService = assert(LRTruckerServer.TruckerService)

LR.Modules:Register({
  id = "trucker",
  start = "resource",
  dependencies = {},
  ---@param context LRServer.ModuleContext
  create = function(context)
    return TruckerService:New({ context = context })
  end,
})
