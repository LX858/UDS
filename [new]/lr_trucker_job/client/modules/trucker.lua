LR = LR or {}
LRTruckerClient = LRTruckerClient or {}

local TruckerService = assert(LRTruckerClient.Service)

LR.Modules:Register({
  id = "trucker",
  start = "player",
  dependencies = {},
  ---@param context LRClient.ModuleContext
  create = function(context)
    return TruckerService:New({ context = context })
  end,
})
