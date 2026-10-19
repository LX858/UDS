---@meta

---@alias LRClient.Unregister fun()
---@alias LRClient.PayloadSize fun(value: unknown): integer
---@alias LRClient.TimerSetter fun(milliseconds: integer, callback: fun()): integer
---@alias LRClient.TimerClearer fun(timer?: integer)
---@alias LRClient.TransportCallback<TPayload, TResult> fun(result?: TResult, error?: { code: string })

---@class LRClient.NuiOptions
---@field app? LRShared.Application
---@field side? "client"
---@field resourceName? string
---@field logger? LRShared.Logger
---@field registerCallback? fun(name: string, handler: fun(envelope: table, reply: fun(response: table))): LRClient.Unregister|nil
---@field send? fun(envelope: table): boolean
---@field sizeOf? LRClient.PayloadSize
---@field setTimeout? LRClient.TimerSetter
---@field clearTimeout? LRClient.TimerClearer
---@field maxPayload? integer
---@field incomingRpcLimit? integer
---@field stateReplayLimit? integer
---@field stateReplayMaxBytes? integer
---@field sessionSalt? string
---@field contracts? table<string, LRShared.CompiledContract>

---@class LRClient.NuiState<TPayload>
---@field Get fun(self: LRClient.NuiState<TPayload>): TPayload
---@field Set fun(self: LRClient.NuiState<TPayload>, value: TPayload)
---@field Patch fun(self: LRClient.NuiState<TPayload>, patch: table)
---@field Watch fun(self: LRClient.NuiState<TPayload>, callback: fun(value: TPayload, previous?: TPayload)): LRClient.Unregister

---@class LRClient.NuiOutgoingEvent<TPayload>
---@field Emit fun(self: LRClient.NuiOutgoingEvent<TPayload>, payload: TPayload): boolean

---@class LRClient.NuiIncomingEvent<TPayload>
---@field On fun(self: LRClient.NuiIncomingEvent<TPayload>, callback: fun(payload: TPayload)): LRClient.Unregister

---@class LRClient.NuiOutgoingRpc<TRequest, TResponse>
---@field Call fun(self: LRClient.NuiOutgoingRpc<TRequest, TResponse>, payload: TRequest, callback?: LRClient.TransportCallback<TRequest, TResponse>): TResponse|string|nil

---@class LRClient.NuiIncomingRpc<TRequest, TResponse>
---@field Handle fun(self: LRClient.NuiIncomingRpc<TRequest, TResponse>, handler: fun(request: TRequest): TResponse): LRClient.Unregister

---@class LRClient.NuiModule
---@field state table<string, LRClient.NuiState<unknown>>
---@field events table<string, LRClient.NuiOutgoingEvent<unknown>|LRClient.NuiIncomingEvent<unknown>>
---@field rpc table<string, LRClient.NuiOutgoingRpc<unknown, unknown>|LRClient.NuiIncomingRpc<unknown, unknown>>

---@class LRClient.Nui
---@field RegisterModule fun(self: LRClient.Nui, id: string, contractSection?: table): LRClient.NuiModule
---@field Module fun(self: LRClient.Nui, id: string): LRClient.NuiModule
---@field IsReady fun(self: LRClient.Nui): boolean
---@field WhenReady fun(self: LRClient.Nui, callback: fun()): LRClient.Unregister
---@field MarkReady fun(self: LRClient.Nui, sessionId?: string): boolean
---@field Dispose fun(self: LRClient.Nui)

---@class LRClient.NetOptions
---@field app? LRShared.Application
---@field side? "client"
---@field resourceName? string
---@field logger? LRShared.Logger
---@field registerEvent? fun(name: string, handler: fun(envelope: table)): LRClient.Unregister|nil
---@field emitServer? fun(name: string, envelope: table)
---@field sizeOf? LRClient.PayloadSize
---@field schedule? LRClient.TimerSetter
---@field cancel? LRClient.TimerClearer
---@field maxPayload? integer
---@field incomingLimit? integer
---@field now? fun(): integer
---@field sessionSalt? string
---@field contracts? table<string, LRShared.CompiledContract>

---@class LRClient.NetIncomingEvent<TPayload>
---@field On fun(self: LRClient.NetIncomingEvent<TPayload>, callback: fun(payload: TPayload)): LRClient.Unregister

---@class LRClient.NetOutgoingEvent<TPayload>
---@field Emit fun(self: LRClient.NetOutgoingEvent<TPayload>, payload: TPayload)

---@class LRClient.NetOutgoingRpc<TRequest, TResponse>
---@field Call fun(self: LRClient.NetOutgoingRpc<TRequest, TResponse>, payload: TRequest, callback?: LRClient.TransportCallback<TRequest, TResponse>): TResponse|string|nil

---@class LRClient.NetIncomingRpc<TRequest, TResponse>
---@field Handle fun(self: LRClient.NetIncomingRpc<TRequest, TResponse>, handler: fun(request: TRequest): TResponse): LRClient.Unregister

---@class LRClient.NetModule
---@field events table<string, LRClient.NetIncomingEvent<unknown>|LRClient.NetOutgoingEvent<unknown>>
---@field rpc table<string, LRClient.NetOutgoingRpc<unknown, unknown>|LRClient.NetIncomingRpc<unknown, unknown>>

---@class LRClient.Net
---@field RegisterModule fun(self: LRClient.Net, id: string, contractSection?: table): LRClient.NetModule
---@field Module fun(self: LRClient.Net, id: string): LRClient.NetModule
---@field Dispose fun(self: LRClient.Net)

---@class LRClient.PublicOptions
---@field app? LRShared.Application
---@field side? "client"
---@field resourceName? string
---@field logger? LRShared.Logger
---@field contracts? table<string, LRShared.CompiledContract>
---@field getInvokingResource? fun(): string|nil
---@field sizeOf? LRClient.PayloadSize
---@field maxPayload? integer
---@field registerExport? fun(name: string, handler: fun(payload: unknown): unknown): LRClient.Unregister|nil
---@field invokeExport? fun(resource: string, name: string, payload: unknown): unknown

---@class LRClient.Public
---@field Register fun(self: LRClient.Public, module: string, handlers: table<string, fun(payload: unknown): unknown>): LRClient.Unregister
---@field External LRClient.External
---@field Dispose fun(self: LRClient.Public)

---@class LRClient.External
