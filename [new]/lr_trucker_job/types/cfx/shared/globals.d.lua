---@meta

---@alias PlayerId integer
---@alias Entity integer
---@alias Ped integer
---@alias Hash integer
---@alias ResourceName string
---@alias EventHandlerToken integer

---@class vector3
---@field x number
---@field y number
---@field z number

---@class vector4 : vector3
---@field w number

---@class CfxPromise<T>
---@field resolve fun(self: CfxPromise<T>, value?: T)
---@field reject fun(self: CfxPromise<T>, reason?: unknown)
---@field next fun(self: CfxPromise<T>, onResolved: fun(value: T), onRejected?: fun(reason: unknown))

---@class promise
---@generic T
---@field new fun(): CfxPromise<T>
promise = promise

---@class Citizen
---@field CreateThread fun(handler: fun())
---@field Wait fun(ms: integer)
---@generic T
---@field Await fun(promise: CfxPromise<T>): T
Citizen = Citizen

---@class CfxJson
---@field encode fun(value: unknown): string
---@field decode fun(value: string): unknown
json = json ---@type CfxJson

---@param x number
---@param y number
---@param z number
---@return vector3
function vector3(x, y, z) end

---@param x number
---@param y number
---@param z number
---@param w number
---@return vector4
function vector4(x, y, z, w) end

---@return boolean
function IsDuplicityVersion() end

---@return ResourceName
function GetCurrentResourceName() end

---@param resourceName string
---@return string
function GetResourceState(resourceName) end

---@return integer
function GetGameTimer() end

---@return string|nil
function GetInvokingResource() end

---@param ms integer
function Wait(ms) end

---@param handler fun()
function CreateThread(handler) end

---@param commandName string
---@param handler fun(source: PlayerId, args: string[], rawCommand: string)
---@param restricted boolean
function RegisterCommand(commandName, handler, restricted) end

---@param handler EventHandlerToken
function RemoveEventHandler(handler) end

---@param eventName string
---@param handler? fun(...)
---@return EventHandlerToken
function RegisterNetEvent(eventName, handler) end

---@param milliseconds integer
---@param callback fun()
---@return integer
function SetTimeout(milliseconds, callback) end

---@param timer integer
function ClearTimeout(timer) end

---@param resourceName string
---@param fileName string
---@return string|nil
function LoadResourceFile(resourceName, fileName) end

---@param message unknown
function warn(message) end

---@class CfxExportsResource
---@field [string] fun(...): unknown

---@class CfxExports
---@field [string] CfxExportsResource
---@overload fun(exportName: string, handler: function)
exports = exports ---@type CfxExports
