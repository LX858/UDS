---@meta

---@alias LRServer.FrameworkName "standalone"|"esx"|"qbcore"|"qbx"
---@alias LRServer.FrameworkNotificationType "inform"|"success"|"warning"|"error"

---@class LRServer.FrameworkGroup
---@field name? string
---@field label? string
---@field type? string
---@field grade? integer
---@field gradeName? string
---@field gradeLabel? string
---@field onDuty? boolean
---@field isBoss boolean

---@class LRServer.FrameworkPlayer
---@field source? integer
---@field identifier? string
---@field citizenId? string
---@field name? string
---@field firstName? string
---@field lastName? string
---@field job? LRServer.FrameworkGroup
---@field gang? LRServer.FrameworkGroup

---@class LRServer.FrameworkNotification
---@field message string
---@field type? LRServer.FrameworkNotificationType
---@field duration? integer
---@field title? string

---@class LRServer.FrameworkAdapter
---@field GetPlayer fun(self: LRServer.FrameworkAdapter, source: integer): LRServer.FrameworkPlayer?
---@field IsPlayerLoaded fun(self: LRServer.FrameworkAdapter, source: integer): boolean
---@field Notify fun(self: LRServer.FrameworkAdapter, source: integer, notification: LRServer.FrameworkNotification): boolean
---@field GetMoney? fun(self: LRServer.FrameworkAdapter, source: integer, account: string): integer
---@field AddMoney? fun(self: LRServer.FrameworkAdapter, source: integer, account: string, amount: integer, reason: string): boolean
---@field RemoveMoney? fun(self: LRServer.FrameworkAdapter, source: integer, account: string, amount: integer, reason: string): boolean
---@field GetMetadata? fun(self: LRServer.FrameworkAdapter, source: integer, key: string): unknown
---@field SetMetadata? fun(self: LRServer.FrameworkAdapter, source: integer, key: string, value: unknown): boolean
---@field GiveVehicleKeys? fun(self: LRServer.FrameworkAdapter, source: integer, vehicle: integer): boolean
---@field PrepareOwnedVehicle? fun(self: LRServer.FrameworkAdapter, vehicle: integer, data: table): boolean
---@field OnPlayerLoaded fun(self: LRServer.FrameworkAdapter, callback: fun(source: integer, player: LRServer.FrameworkPlayer?)): fun()
---@field OnPlayerUnloaded fun(self: LRServer.FrameworkAdapter, callback: fun(source: integer)): fun()
---@field OnPlayerDataChanged fun(self: LRServer.FrameworkAdapter, callback: fun(source: integer, player: LRServer.FrameworkPlayer?, key?: string)): fun()
---@field Dispose? fun(self: LRServer.FrameworkAdapter)

---@class LRServer.FrameworkBridge : LRServer.FrameworkAdapter
---@field name LRServer.FrameworkName
---@field resourceName? string
---@field Dispose fun(self: LRServer.FrameworkBridge)

---@class LRServer.FrameworkSignal
---@field Subscribe fun(self: LRServer.FrameworkSignal, callback: function): fun()
---@field Emit fun(self: LRServer.FrameworkSignal, ...)
---@field Dispose fun(self: LRServer.FrameworkSignal)

---@class LRServer.FrameworkRuntime
---@field GetResourceState fun(self: LRServer.FrameworkRuntime, resourceName: string): string?
---@field GetEventSource fun(self: LRServer.FrameworkRuntime): integer?
---@field CallExport fun(self: LRServer.FrameworkRuntime, resourceName: string, exportName: string, ...): unknown
---@field IsCallable fun(self: LRServer.FrameworkRuntime, value: unknown): boolean
---@field Call fun(self: LRServer.FrameworkRuntime, callable: unknown, ...): unknown
---@field On fun(self: LRServer.FrameworkRuntime, eventName: string, callback: function): fun()
---@field OnNet fun(self: LRServer.FrameworkRuntime, eventName: string, callback: function): fun()
---@field CreateSignal fun(self: LRServer.FrameworkRuntime): LRServer.FrameworkSignal
---@field NormalizePlayer fun(self: LRServer.FrameworkRuntime, raw: table?, fallbackSource?: integer): LRServer.FrameworkPlayer?
---@field NormalizeNotification fun(self: LRServer.FrameworkRuntime, notification: LRServer.FrameworkNotification): LRServer.FrameworkNotification
---@field Dispose fun(self: LRServer.FrameworkRuntime)

---@class LRServer.FrameworkFactoryContext
---@field name LRServer.FrameworkName
---@field resourceName? string
---@field runtime LRServer.FrameworkRuntime
---@field readiness LRShared.StandaloneReadinessProvider

---@class LRServer.FrameworkDescriptor
---@field name LRServer.FrameworkName|string
---@field resourceName? string
---@field create fun(context: LRServer.FrameworkFactoryContext): LRServer.FrameworkAdapter

---@class LRServer.FrameworkConfig
---@field Name? "standalone"|"auto"|"esx"|"qbcore"|"qbx"|"qbox"
---@field Resource? string

---@class LRServer.FrameworkBridgeOptions
---@field name? string
---@field resourceName? string
---@field config? string|LRServer.FrameworkConfig
---@field getResourceState? fun(resourceName: string): string
---@field exports? table<string, table<string, unknown>>
---@field addEventHandler? fun(eventName: string, callback: function): unknown
---@field removeEventHandler? fun(token: unknown)
---@field registerNetEvent? fun(eventName: string)
---@field getEventSource? fun(): integer?

---@class LRServer.ApplicationServices : table<string, unknown>
---@field framework? LRServer.FrameworkBridge
---@field readiness? LRShared.ReadinessProvider
---@field scheduler? LRShared.Scheduler

---@class LRServer.FrameworkServices : LRServer.ApplicationServices
---@field framework LRServer.FrameworkBridge
---@field readiness LRShared.ReadinessProvider

---@class LRServer.Services : LRServer.ApplicationServices
---@field framework? LRServer.FrameworkBridge
---@field readiness LRShared.ReadinessProvider
---@field scheduler LRShared.Scheduler
---@field net LRServer.Net
---@field public LRServer.Public
---@field external LRServer.External
