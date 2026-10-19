---@meta

---@class LRClient.ApplicationOptions : LRShared.ApplicationOptions
---@field modules? table<string, boolean|{ enabled?: boolean }>
---@field services? LRClient.ApplicationServices

---@class LRClient.ModuleMap

---@class LRClient.ModuleContext
---@field app LRClient.Application
---@field descriptor LRClient.ModuleDescriptor
---@field id string
---@field side "client"
---@field resourceName string
---@field logger LRShared.Logger
---@field scheduler LRShared.Scheduler
---@field disposables LRShared.DisposableStack
---@field services LRClient.Services
---@field nui LRClient.Nui
---@field net LRClient.Net
---@field public LRClient.Public
---@field external LRClient.External
---@field modules LRClient.ModuleMap
---@field GetModule fun<T>(self: LRClient.ModuleContext, id: string): T

---@class LRClient.ModuleInstance : LRShared.ModuleInstance
---@field OnReady? fun(self: LRClient.ModuleInstance, context: LRClient.ModuleContext)
---@field Start? fun(self: LRClient.ModuleInstance, context: LRClient.ModuleContext)
---@field Stop? fun(self: LRClient.ModuleInstance, context: LRClient.ModuleContext)

---@class LRClient.ModuleDescriptor : LRShared.ModuleDescriptor
---@field create fun(context: LRClient.ModuleContext): LRClient.ModuleInstance

---@class LRClient.ModuleRegistry : LRShared.ModuleRegistry
---@field Register fun(self: LRClient.ModuleRegistry, descriptor: LRClient.ModuleDescriptor): LRClient.ModuleDescriptor

---@class LRClient.Application : LRShared.Application
---@field registry LRClient.ModuleRegistry
---@field RegisterModule fun(self: LRClient.Application, descriptor: LRClient.ModuleDescriptor): LRClient.ModuleDescriptor
---@field GetModule fun<T>(self: LRClient.Application, id: string): T

---@class LRClient.Namespace : LRShared.Namespace
---@field Modules LRClient.ModuleRegistry
---@field ClientModules LRClient.ModuleRegistry
---@field Nui? LRClient.Nui
---@field Net? LRClient.Net
---@field Public? LRClient.Public
---@field External? LRClient.External
---@field CreateClientApplication fun(options?: LRClient.ApplicationOptions): LRClient.Application
---@field CreateClientNui fun(options?: LRClient.NuiOptions): LRClient.Nui
---@field CreateClientNet fun(options?: LRClient.NetOptions): LRClient.Net
---@field CreateClientPublic fun(options?: LRClient.PublicOptions): LRClient.Public
---@field RegisterClientFrameworkBridge fun(descriptor: LRClient.FrameworkDescriptor): LRClient.FrameworkDescriptor
---@field CreateClientFrameworkServices fun(options?: LRClient.FrameworkBridgeOptions): LRClient.FrameworkServices

LRClient = {} ---@type LRClient.Namespace
LR = {} ---@type LRClient.Namespace
