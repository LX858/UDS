LR.Modules:Register({
  id = "main",
  start = "player",
  dependencies = {},

  ---@param context LRClient.ModuleContext
  create = function(context)
    ---@class LRClient.ModuleMap
    ---@field main LRClient.MainModule
    ---@class LRClient.MainModule : LRClient.ModuleInstance
    local instance = {}

    ---@param readyContext LRClient.ModuleContext
    function instance:OnReady(readyContext)
      local playerId = PlayerId()
      readyContext.nui.Main().state.game:Set({
        playerName = GetPlayerName(playerId) or "",
        playerId = tostring(GetPlayerServerId(playerId)),
      })
    end

    ---@param _startContext LRClient.ModuleContext
    function instance:Start(_startContext) end

    ---@param _stopContext LRClient.ModuleContext
    function instance:Stop(_stopContext) end

    return instance
  end,
})
