---@meta

---@alias LRServer.Unregister fun()
---@alias LRServer.PayloadSize fun(value: unknown): integer
---@alias LRServer.TimerSetter fun(milliseconds: integer, callback: fun()): integer
---@alias LRServer.TimerClearer fun(timer?: integer)
---@alias LRServer.TransportCallback<TPayload, TResult> fun(result?: TResult, error?: { code: string })

---@class LRServer.NetOptions
---@field app? LRShared.Application
---@field side? "server"
---@field resourceName? string
---@field logger? LRShared.Logger
---@field registerEvent? fun(name: string, handler: fun(source: integer, envelope: table)): LRServer.Unregister|nil
---@field emitClient? fun(name: string, source: integer, envelope: table)
---@field sizeOf? LRServer.PayloadSize
---@field schedule? LRServer.TimerSetter
---@field cancel? LRServer.TimerClearer
---@field registerPlayerDropped? fun(handler: fun(source: integer)): LRServer.Unregister|nil
---@field now? fun(): integer
---@field maxPayload? integer
---@field rate? number
---@field burst? integer
---@field ingressRate? number
---@field ingressBurst? integer
---@field sessionSalt? string
---@field contracts? table<string, LRShared.CompiledContract>

---@class LRServer.NetIncomingHandler<TRequest, TResponse>
---@field Authorize? fun(source: integer, request: TRequest): boolean
---@field Execute fun(source: integer, request: TRequest): TResponse

---@class LRServer.NetIncomingEndpoint<TRequest, TResponse>
---@field Handle fun(self: LRServer.NetIncomingEndpoint<TRequest, TResponse>, handler: LRServer.NetIncomingHandler<TRequest, TResponse>|fun(source: integer, request: TRequest): TResponse): LRServer.Unregister

---@class LRServer.NetOutgoingEvent<TPayload>
---@field Emit fun(self: LRServer.NetOutgoingEvent<TPayload>, source: integer, payload: TPayload)

---@class LRServer.NetOutgoingRpc<TRequest, TResponse>
---@field Call fun(self: LRServer.NetOutgoingRpc<TRequest, TResponse>, source: integer, payload: TRequest, callback?: LRServer.TransportCallback<TRequest, TResponse>): TResponse|string|nil

---@class LRServer.NetModule
---@field events table<string, LRServer.NetIncomingEndpoint<unknown, unknown>|LRServer.NetOutgoingEvent<unknown>>
---@field rpc table<string, LRServer.NetIncomingEndpoint<unknown, unknown>|LRServer.NetOutgoingRpc<unknown, unknown>>

---@class LRServer.Net
---@field RegisterModule fun(self: LRServer.Net, id: string, contractSection?: table): LRServer.NetModule
---@field Module fun(self: LRServer.Net, id: string): LRServer.NetModule
---@field ForgetPlayer fun(self: LRServer.Net, source: integer)
---@field Dispose fun(self: LRServer.Net)

---@class LRServer.PublicOptions
---@field app? LRShared.Application
---@field side? "server"
---@field resourceName? string
---@field logger? LRShared.Logger
---@field contracts? table<string, LRShared.CompiledContract>
---@field getInvokingResource? fun(): string|nil
---@field sizeOf? LRServer.PayloadSize
---@field maxPayload? integer
---@field registerExport? fun(name: string, handler: fun(payload: unknown): unknown): LRServer.Unregister|nil
---@field invokeExport? fun(resource: string, name: string, payload: unknown): unknown

---@class LRServer.Public
---@field Register fun(self: LRServer.Public, module: string, handlers: table<string, fun(payload: unknown): unknown>): LRServer.Unregister
---@field External LRServer.External
---@field Dispose fun(self: LRServer.Public)

---@class LRServer.External
