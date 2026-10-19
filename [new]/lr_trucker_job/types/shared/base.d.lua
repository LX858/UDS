---@meta

---@alias LRShared.Side "shared"|"client"|"server"
---@alias LRShared.Map<K, V> table<K, V>
---@alias LRShared.List<T> T[]
---@alias LRShared.Callback<T> fun(value: T)

---@class LRShared.ClassProperty<TInstance, TValue>
---@field storage? string
---@field readonly? boolean
---@field get? fun(instance: TInstance, stored?: TValue): TValue
---@field set? fun(instance: TInstance, value: TValue, previous?: TValue): TValue
---@field validate? fun(instance: TInstance, value: TValue): boolean, string?
---@field afterSet? fun(instance: TInstance, value: TValue, previous?: TValue)

---@class LRShared.ClassInstance
---@field IsA fun(self: LRShared.ClassInstance, target: LRShared.Class): boolean
---@field GetClass fun(self: LRShared.ClassInstance): LRShared.Class|nil

---@class LRShared.Class<TInstance, TInit> : table
---@field __name string
---@field __base? LRShared.Class
---@field __properties table<string, LRShared.ClassProperty<TInstance, unknown>>
---@field New fun(self: LRShared.Class<TInstance, TInit>, input: TInit): TInstance
---@field Extend fun<TChild, TChildInit>(self: LRShared.Class<TInstance, TInit>, name: string): LRShared.Class<TChild, TChildInit>
---@field Property fun<TValue>(self: LRShared.Class<TInstance, TInit>, name: string, definition?: LRShared.ClassProperty<TInstance, TValue>): LRShared.Class<TInstance, TInit>
---@field IsSubclassOf fun(self: LRShared.Class<TInstance, TInit>, target: LRShared.Class): boolean

---@class LRShared.ClassNamespace
---@field Define fun<TInstance, TInit>(self: LRShared.ClassNamespace, name: string, base?: LRShared.Class): LRShared.Class<TInstance, TInit>
---@field IsClass fun(self: LRShared.ClassNamespace, value: unknown): boolean
---@field IsInstance fun(self: LRShared.ClassNamespace, value: unknown, target: LRShared.Class): boolean

---@class LRShared.Duration
---@field parse fun(value: string): number|nil
---@field tostring fun(milliseconds: number): string

Ms = {} ---@type LRShared.Duration
Locales = {} ---@type table<string, table<string, string>>

---@param key string
---@param ... string|number|table<string, string|number>
---@return string
function L(key, ...) end

---@param localeKey string
---@return table<string, string>
function SetLocale(localeKey) end

---@class LRShared.Result<TValue, TError>
---@field ok boolean
---@field value? TValue
---@field error? TError

---@class LRShared.Disposable
---@field Dispose? fun(self: LRShared.Disposable)
---@field Stop? fun(self: LRShared.Disposable)

---@alias LRShared.DisposableValue LRShared.Disposable|fun()

---@class LRShared.LoggerOptions
---@field prefix? string
---@field debug? boolean
---@field sink? fun(message: string)

---@class LRShared.Logger
---@field prefix string
---@field debug boolean
---@field sink fun(message: string)
---@field Child fun(self: LRShared.Logger, scope: string): LRShared.Logger
---@field Format fun(self: LRShared.Logger, level: string, message: string, ...): string
---@field Write fun(self: LRShared.Logger, level: string, message: string, ...)
---@field Debug fun(self: LRShared.Logger, message: string, ...)
---@field Info fun(self: LRShared.Logger, message: string, ...)
---@field Warn fun(self: LRShared.Logger, message: string, ...)
---@field Error fun(self: LRShared.Logger, message: string, ...)

---@class LRShared.LoggerClass
---@field __index? table
---@field prefix? string
---@field debug? boolean
---@field sink? fun(message: string)
---@field new? fun(self: LRShared.LoggerClass, options?: LRShared.LoggerOptions): LRShared.Logger
---@field Child? fun(self: LRShared.Logger, scope: string): LRShared.Logger
---@field Format? fun(self: LRShared.Logger, level: string, message: string, ...): string
---@field Write? fun(self: LRShared.Logger, level: string, message: string, ...)
---@field Debug? fun(self: LRShared.Logger, message: string, ...)
---@field Info? fun(self: LRShared.Logger, message: string, ...)
---@field Warn? fun(self: LRShared.Logger, message: string, ...)
---@field Error? fun(self: LRShared.Logger, message: string, ...)

---@class LRShared.DisposableStack
---@field items LRShared.DisposableValue[]
---@field disposed boolean
---@field Add fun(self: LRShared.DisposableStack, disposable?: LRShared.DisposableValue): LRShared.DisposableValue|nil
---@field DisposeOne fun(self: LRShared.DisposableStack, disposable: LRShared.DisposableValue)
---@field DisposeAll fun(self: LRShared.DisposableStack)

---@class LRShared.DisposableStackClass
---@field __index? table
---@field items? LRShared.DisposableValue[]
---@field disposed? boolean
---@field new? fun(self: LRShared.DisposableStackClass): LRShared.DisposableStack
---@field Add? fun(self: LRShared.DisposableStack, disposable?: LRShared.DisposableValue): LRShared.DisposableValue|nil
---@field DisposeOne? fun(self: LRShared.DisposableStack, disposable: LRShared.DisposableValue)
---@field DisposeAll? fun(self: LRShared.DisposableStack)

---@alias LRShared.ModuleStart "resource"|"player"

---@class LRShared.ModuleInstance
---@field OnReady? fun(self: LRShared.ModuleInstance, context: LRShared.ModuleContext)
---@field Start? fun(self: LRShared.ModuleInstance, context: LRShared.ModuleContext)
---@field Stop? fun(self: LRShared.ModuleInstance, context: LRShared.ModuleContext)

---@class LRShared.ModuleMap

---@class LRShared.ModuleDescriptor
---@field id string
---@field start? LRShared.ModuleStart
---@field dependencies? string[]
---@field create? fun(context: LRShared.ModuleContext): LRShared.ModuleInstance

---@class LRShared.ModuleContext
---@field app LRShared.Application
---@field descriptor LRShared.ModuleDescriptor
---@field id string
---@field side LRShared.Side
---@field resourceName string
---@field logger LRShared.Logger
---@field scheduler LRShared.Scheduler
---@field disposables LRShared.DisposableStack
---@field services table<string, unknown>
---@field nui? unknown
---@field net? unknown
---@field public? unknown
---@field external? unknown
---@field modules LRShared.ModuleMap
---@field GetModule fun<T>(self: LRShared.ModuleContext, id: string): T

---@class LRShared.ModuleRegistry
---@field descriptors table<string, LRShared.ModuleDescriptor>
---@field order string[]
---@field ValidateId fun(self: LRShared.ModuleRegistry, id: string)
---@field ValidateDescriptor fun(self: LRShared.ModuleRegistry, descriptor: LRShared.ModuleDescriptor)
---@field Register fun(self: LRShared.ModuleRegistry, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleDescriptor
---@field Get fun(self: LRShared.ModuleRegistry, id: string): LRShared.ModuleDescriptor|nil
---@field Descriptors fun(self: LRShared.ModuleRegistry): LRShared.ModuleDescriptor[]
---@field ResolveStartOrder fun(self: LRShared.ModuleRegistry): LRShared.ModuleDescriptor[]

---@class LRShared.ModuleRegistryClass
---@field __index? table
---@field descriptors? table<string, LRShared.ModuleDescriptor>
---@field order? string[]
---@field new? fun(self: LRShared.ModuleRegistryClass): LRShared.ModuleRegistry
---@field ValidateId? fun(self: LRShared.ModuleRegistry, id: string)
---@field ValidateDescriptor? fun(self: LRShared.ModuleRegistry, descriptor: LRShared.ModuleDescriptor)
---@field Register? fun(self: LRShared.ModuleRegistry, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleDescriptor
---@field Get? fun(self: LRShared.ModuleRegistry, id: string): LRShared.ModuleDescriptor|nil
---@field Descriptors? fun(self: LRShared.ModuleRegistry): LRShared.ModuleDescriptor[]
---@field ResolveStartOrder? fun(self: LRShared.ModuleRegistry): LRShared.ModuleDescriptor[]

---@class LRShared.ReadinessProvider
---@field IsReady fun(self: LRShared.ReadinessProvider): boolean
---@field WhenReady fun(self: LRShared.ReadinessProvider, callback: fun()): fun()

---@class LRShared.StandaloneReadinessProvider : LRShared.ReadinessProvider
---@field ready boolean
---@field callbacks { active: boolean, callback: fun() }[]
---@field MarkReady fun(self: LRShared.StandaloneReadinessProvider)

---@class LRShared.StandaloneReadinessProviderClass
---@field __index? table
---@field new? fun(self: LRShared.StandaloneReadinessProviderClass, options?: { ready?: boolean }): LRShared.StandaloneReadinessProvider
---@field IsReady? fun(self: LRShared.StandaloneReadinessProvider): boolean
---@field WhenReady? fun(self: LRShared.StandaloneReadinessProvider, callback: fun()): fun()
---@field MarkReady? fun(self: LRShared.StandaloneReadinessProvider)

---@class LRShared.Scheduler
---@field setTimeout? fun(milliseconds: integer, callback: fun()): integer
---@field clearTimeout? fun(timer: integer)
---@field Delay fun(self: LRShared.Scheduler, milliseconds: integer, callback: fun()): integer|nil
---@field Cancel fun(self: LRShared.Scheduler, timer?: integer)

---@class LRShared.SchedulerOptions
---@field setTimeout? fun(milliseconds: integer, callback: fun()): integer
---@field clearTimeout? fun(timer: integer)

---@class LRShared.SchedulerClass
---@field __index? table
---@field new? fun(self: LRShared.SchedulerClass, options?: LRShared.SchedulerOptions): LRShared.Scheduler
---@field Delay? fun(self: LRShared.Scheduler, milliseconds: integer, callback: fun()): integer|nil
---@field Cancel? fun(self: LRShared.Scheduler, timer?: integer)

---@class LRShared.ApplicationOptions
---@field name? string
---@field side? LRShared.Side
---@field resourceName? string
---@field logger? LRShared.Logger
---@field registry? LRShared.ModuleRegistry
---@field debug? boolean
---@field services? table<string, unknown>
---@field serviceOrder? string[]
---@field scheduler? LRShared.Scheduler
---@field schedulerOptions? LRShared.SchedulerOptions
---@field readiness? LRShared.ReadinessProvider

---@class LRShared.Application
---@field name string
---@field side LRShared.Side
---@field resourceName string
---@field logger LRShared.Logger
---@field registry LRShared.ModuleRegistry
---@field started LRShared.ModuleDescriptor[]
---@field activeModules table<string, boolean>
---@field instances table<string, LRShared.ModuleInstance>
---@field moduleContexts table<string, LRShared.ModuleContext>
---@field playerStarted boolean
---@field stopped boolean
---@field services table<string, unknown>
---@field serviceOrder string[]
---@field globalServices table<string, { key: string, service: unknown }>
---@field servicesDisposed boolean
---@field scheduler LRShared.Scheduler
---@field readiness LRShared.ReadinessProvider
---@field readinessDisposer? fun()
---@field RegisterModule fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleDescriptor
---@field RegisterService fun(self: LRShared.Application, name: string, service: unknown): unknown
---@field RegisterGlobalService fun(self: LRShared.Application, name: string, globalName: string, service: unknown): unknown
---@field GetService fun(self: LRShared.Application, name: string): unknown
---@field HasService fun(self: LRShared.Application, name: string): boolean
---@field GetModule fun<T>(self: LRShared.Application, id: string): T
---@field DisposeService fun(self: LRShared.Application, service: unknown)
---@field ClearGlobalService fun(self: LRShared.Application, name: string)
---@field DisposeServices fun(self: LRShared.Application)
---@field CreateModuleContext fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleContext
---@field CreateModule fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleInstance, LRShared.ModuleContext
---@field StartModule fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor)
---@field ReadyModule fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor)
---@field StartMatchingModules fun(self: LRShared.Application, predicate: fun(descriptor: LRShared.ModuleDescriptor): boolean)
---@field StartPlayerModules fun(self: LRShared.Application)
---@field Start fun(self: LRShared.Application)
---@field Stop fun(self: LRShared.Application)
---@field IsStopped fun(self: LRShared.Application): boolean

---@class LRShared.ApplicationClass
---@field __index? table
---@field new? fun(self: LRShared.ApplicationClass, options?: LRShared.ApplicationOptions): LRShared.Application
---@field RegisterModule? fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleDescriptor
---@field RegisterService? fun(self: LRShared.Application, name: string, service: unknown): unknown
---@field RegisterGlobalService? fun(self: LRShared.Application, name: string, globalName: string, service: unknown): unknown
---@field GetService? fun(self: LRShared.Application, name: string): unknown
---@field HasService? fun(self: LRShared.Application, name: string): boolean
---@field GetModule? fun<T>(self: LRShared.Application, id: string): T
---@field DisposeService? fun(self: LRShared.Application, service: unknown)
---@field ClearGlobalService? fun(self: LRShared.Application, name: string)
---@field DisposeServices? fun(self: LRShared.Application)
---@field CreateModuleContext? fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleContext
---@field CreateModule? fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor): LRShared.ModuleInstance, LRShared.ModuleContext
---@field StartModule? fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor)
---@field ReadyModule? fun(self: LRShared.Application, descriptor: LRShared.ModuleDescriptor)
---@field StartMatchingModules? fun(self: LRShared.Application, predicate: fun(descriptor: LRShared.ModuleDescriptor): boolean)
---@field StartPlayerModules? fun(self: LRShared.Application)
---@field Start? fun(self: LRShared.Application)
---@field Stop? fun(self: LRShared.Application)
---@field IsStopped? fun(self: LRShared.Application): boolean

---@class LRShared.JsonSchema
---@field type? string|string[]
---@field properties? table<string, LRShared.JsonSchema>
---@field patternProperties? table<string, LRShared.JsonSchema>
---@field required? string[]
---@field additionalProperties? boolean|LRShared.JsonSchema
---@field items? LRShared.JsonSchema
---@field anyOf? LRShared.JsonSchema[]
---@field enum? unknown[]
---@field const? unknown
---@field default? unknown
---@field minimum? number
---@field maximum? number
---@field exclusiveMinimum? number
---@field exclusiveMaximum? number
---@field minLength? integer
---@field maxLength? integer
---@field minItems? integer
---@field maxItems? integer
---@field pattern? string

---@alias LRShared.Validator fun(value: unknown): boolean, string?

---@class LRShared.SchemaStateDefinition
---@field default unknown
---@field validate LRShared.Validator
---@field patchValidate? LRShared.Validator
---@field object boolean

---@class LRShared.SchemaEventDefinition
---@field validate LRShared.Validator

---@class LRShared.SchemaRateLimit
---@field requestsPerSecond number
---@field burst integer

---@class LRShared.SchemaRpcDefinition
---@field request LRShared.Validator
---@field response LRShared.Validator
---@field timeoutMs? integer
---@field timeout? integer
---@field mutating? boolean
---@field rateLimit? LRShared.SchemaRateLimit

---@class LRShared.CompiledContract
---@field id string
---@field version integer
---@field state table<string, LRShared.SchemaStateDefinition>
---@field nui { state: table<string, LRShared.SchemaStateDefinition>, events: table<string, table<string, LRShared.SchemaEventDefinition>>, rpc: table<string, table<string, LRShared.SchemaRpcDefinition>> }
---@field net { events: table<string, table<string, LRShared.SchemaEventDefinition>>, rpc: table<string, table<string, LRShared.SchemaRpcDefinition>> }
---@field exports table<string, table<string, LRShared.SchemaRpcDefinition>>

---@class LRShared.SchemaNamespace
---@field Compile fun(schema: LRShared.JsonSchema): LRShared.Validator
---@field CompileContract fun(contract: table): LRShared.CompiledContract

---@class LRShared.GeneratedNamespace
---@field Contracts table<string, LRShared.CompiledContract>

---@class LRShared.Namespace
---@field VERSION string
---@field Class LRShared.ClassNamespace
---@field MODULE_ID_PATTERN? string
---@field JSON_NULL? table
---@field Logger LRShared.LoggerClass
---@field DisposableStack LRShared.DisposableStackClass
---@field ModuleRegistry LRShared.ModuleRegistryClass
---@field Modules LRShared.ModuleRegistry
---@field SharedModules LRShared.ModuleRegistry
---@field CreateSideModuleRegistry fun(sharedRegistry: LRShared.ModuleRegistry, sideRegistry: LRShared.ModuleRegistry, isEnabled?: fun(id: string): boolean): LRShared.ModuleRegistry
---@field StandaloneReadinessProvider LRShared.StandaloneReadinessProviderClass
---@field Scheduler LRShared.SchedulerClass
---@field Application LRShared.ApplicationClass
---@field Schema LRShared.SchemaNamespace
---@field Generated LRShared.GeneratedNamespace
---@field extend fun(target?: table, source?: table): table
---@field shallowCopy fun(source?: table): table
---@field assertName fun(name: string, label?: string)
---@field CreateApplication fun(options?: LRShared.ApplicationOptions): LRShared.Application
