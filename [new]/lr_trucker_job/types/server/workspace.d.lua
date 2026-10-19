---@meta

---@class LRServer.ApplicationOptions : LRShared.ApplicationOptions
---@field modules? table<string, boolean|{ enabled?: boolean }>
---@field services? LRServer.ApplicationServices

---@class LRServer.ModuleMap

---@class LRServer.ModuleContext
---@field app LRServer.Application
---@field descriptor LRServer.ModuleDescriptor
---@field id string
---@field side "server"
---@field resourceName string
---@field logger LRShared.Logger
---@field scheduler LRShared.Scheduler
---@field disposables LRShared.DisposableStack
---@field services LRServer.Services
---@field net LRServer.Net
---@field public LRServer.Public
---@field external LRServer.External
---@field modules LRServer.ModuleMap
---@field GetModule fun<T>(self: LRServer.ModuleContext, id: string): T

---@class LRServer.ModuleInstance : LRShared.ModuleInstance
---@field OnReady? fun(self: LRServer.ModuleInstance, context: LRServer.ModuleContext)
---@field Start? fun(self: LRServer.ModuleInstance, context: LRServer.ModuleContext)
---@field Stop? fun(self: LRServer.ModuleInstance, context: LRServer.ModuleContext)

---@class LRServer.ModuleDescriptor : LRShared.ModuleDescriptor
---@field create fun(context: LRServer.ModuleContext): LRServer.ModuleInstance

---@class LRServer.ModuleRegistry : LRShared.ModuleRegistry
---@field Register fun(self: LRServer.ModuleRegistry, descriptor: LRServer.ModuleDescriptor): LRServer.ModuleDescriptor

---@class LRServer.Application : LRShared.Application
---@field registry LRServer.ModuleRegistry
---@field RegisterModule fun(self: LRServer.Application, descriptor: LRServer.ModuleDescriptor): LRServer.ModuleDescriptor
---@field GetModule fun<T>(self: LRServer.Application, id: string): T

---@class LRServer.Namespace : LRShared.Namespace
---@field Modules LRServer.ModuleRegistry
---@field ServerModules LRServer.ModuleRegistry
---@field Net? LRServer.Net
---@field Public? LRServer.Public
---@field External? LRServer.External
---@field CreateServerApplication fun(options?: LRServer.ApplicationOptions): LRServer.Application
---@field CreateServerNet fun(options?: LRServer.NetOptions): LRServer.Net
---@field CreateServerPublic fun(options?: LRServer.PublicOptions): LRServer.Public
---@field RegisterServerFrameworkBridge fun(descriptor: LRServer.FrameworkDescriptor): LRServer.FrameworkDescriptor
---@field CreateServerFrameworkServices fun(options?: LRServer.FrameworkBridgeOptions): LRServer.FrameworkServices
---@field CreateDatabaseBridge fun(resourceName?: string): table

LRServer = {} ---@type LRServer.Namespace
LR = {} ---@type LRServer.Namespace
