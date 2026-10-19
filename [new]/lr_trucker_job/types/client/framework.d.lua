---@meta

---@alias LRClient.FrameworkName "standalone"|"esx"|"qbcore"|"qbx"
---@alias LRClient.FrameworkNotificationType "inform"|"success"|"warning"|"error"

---@class LRClient.FrameworkGroup
---@field name? string
---@field label? string
---@field type? string
---@field grade? integer
---@field gradeName? string
---@field gradeLabel? string
---@field onDuty? boolean
---@field isBoss boolean

---@class LRClient.FrameworkPlayer
---@field source? integer
---@field identifier? string
---@field citizenId? string
---@field name? string
---@field firstName? string
---@field lastName? string
---@field job? LRClient.FrameworkGroup
---@field gang? LRClient.FrameworkGroup

---@class LRClient.FrameworkNotification
---@field message string
---@field type? LRClient.FrameworkNotificationType
---@field duration? integer
---@field title? string

---@class LRClient.FrameworkAdapter
---@field GetPlayerData fun(self: LRClient.FrameworkAdapter): LRClient.FrameworkPlayer?
---@field IsPlayerLoaded fun(self: LRClient.FrameworkAdapter): boolean
---@field Notify fun(self: LRClient.FrameworkAdapter, notification: LRClient.FrameworkNotification): boolean
---@field OnPlayerLoaded fun(self: LRClient.FrameworkAdapter, callback: fun(player: LRClient.FrameworkPlayer?)): fun()
---@field OnPlayerUnloaded fun(self: LRClient.FrameworkAdapter, callback: fun()): fun()
---@field OnPlayerDataChanged fun(self: LRClient.FrameworkAdapter, callback: fun(player: LRClient.FrameworkPlayer?, key?: string)): fun()
---@field Dispose? fun(self: LRClient.FrameworkAdapter)

---@class LRClient.FrameworkBridge : LRClient.FrameworkAdapter
---@field name LRClient.FrameworkName
---@field resourceName? string
---@field Dispose fun(self: LRClient.FrameworkBridge)

---@class LRClient.FrameworkSignal
---@field Subscribe fun(self: LRClient.FrameworkSignal, callback: function): fun()
---@field Emit fun(self: LRClient.FrameworkSignal, ...)
---@field Dispose fun(self: LRClient.FrameworkSignal)

---@class LRClient.FrameworkRuntime
---@field GetResourceState fun(self: LRClient.FrameworkRuntime, resourceName: string): string?
---@field CallExport fun(self: LRClient.FrameworkRuntime, resourceName: string, exportName: string, ...): unknown
---@field IsCallable fun(self: LRClient.FrameworkRuntime, value: unknown): boolean
---@field Call fun(self: LRClient.FrameworkRuntime, callable: unknown, ...): unknown
---@field On fun(self: LRClient.FrameworkRuntime, eventName: string, callback: function): fun()
---@field OnNet fun(self: LRClient.FrameworkRuntime, eventName: string, callback: function): fun()
---@field CreateSignal fun(self: LRClient.FrameworkRuntime): LRClient.FrameworkSignal
---@field NormalizePlayer fun(self: LRClient.FrameworkRuntime, raw: table?, fallbackSource?: integer): LRClient.FrameworkPlayer?
---@field NormalizeNotification fun(self: LRClient.FrameworkRuntime, notification: LRClient.FrameworkNotification): LRClient.FrameworkNotification
---@field Dispose fun(self: LRClient.FrameworkRuntime)

---@class LRClient.FrameworkFactoryContext
---@field name LRClient.FrameworkName
---@field resourceName? string
---@field runtime LRClient.FrameworkRuntime
---@field readiness LRShared.StandaloneReadinessProvider

---@class LRClient.FrameworkDescriptor
---@field name LRClient.FrameworkName|string
---@field resourceName? string
---@field create fun(context: LRClient.FrameworkFactoryContext): LRClient.FrameworkAdapter

---@class LRClient.FrameworkConfig
---@field Name? "standalone"|"auto"|"esx"|"qbcore"|"qbx"|"qbox"
---@field Resource? string

---@class LRClient.FrameworkBridgeOptions
---@field name? string
---@field resourceName? string
---@field config? string|LRClient.FrameworkConfig
---@field getResourceState? fun(resourceName: string): string
---@field exports? table<string, table<string, unknown>>
---@field addEventHandler? fun(eventName: string, callback: function): unknown
---@field removeEventHandler? fun(token: unknown)
---@field registerNetEvent? fun(eventName: string)

---@class LRClient.ApplicationServices : table<string, unknown>
---@field framework? LRClient.FrameworkBridge
---@field readiness? LRShared.ReadinessProvider
---@field scheduler? LRShared.Scheduler

---@class LRClient.FrameworkServices : LRClient.ApplicationServices
---@field framework LRClient.FrameworkBridge
---@field readiness LRShared.ReadinessProvider

---@class LRClient.Services : LRClient.ApplicationServices
---@field framework? LRClient.FrameworkBridge
---@field readiness LRShared.ReadinessProvider
---@field scheduler LRShared.Scheduler
---@field nui LRClient.Nui
---@field net LRClient.Net
---@field public LRClient.Public
---@field external LRClient.External
