---@class CLWsCallback
---@field await fun(event:string, delay: number|boolean, ...): any
---@field register fun(name:string, cb:function): any

---@class SVWsCallback
---@field await fun(event:string, playerId: number, ...): any
---@field register fun(name:string, cb:function): any

---@class WS
---@field OnReady fun(cb:fun())
---@field TriggerClientEvent fun(eventName:string, playerId:number, ...)
---@field RegisterEventHandler fun(eventName:string, handler:fun( ...))
---@field RegisterClientEvent fun(eventName:string, handler:fun( ...))
---@field TriggerServerEvent fun(eventName:string, ...)
---@field RegisterServerEvent fun(eventName:string, handler:fun( playerId:number,...))
---@overload fun(event: string, delay: number | false, cb: function, ...)
---@field CLCallback CLWsCallback
---@field SVCallback SVWsCallback

WS = WS ---@type WS
