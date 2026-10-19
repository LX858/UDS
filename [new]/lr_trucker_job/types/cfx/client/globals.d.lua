---@meta

---@alias NuiCallback fun(response: unknown)
---@alias NuiCallbackHandler fun(data: table|nil, cb: NuiCallback)

---@param message table
function SendNUIMessage(message) end

---@param name string
---@param handler NuiCallbackHandler
function RegisterNUICallback(name, handler) end

---@param name string
---@param handler NuiCallbackHandler
function RegisterNuiCallback(name, handler) end

---@param name string
function RegisterNuiCallbackType(name) end

---@param hasFocus boolean
---@param hasCursor boolean
function SetNuiFocus(hasFocus, hasCursor) end

---@return integer
function PlayerId() end

---@return Ped
function PlayerPedId() end

---@param player integer
---@return PlayerId
function GetPlayerServerId(player) end

---@param entity Entity
---@return vector3
function GetEntityCoords(entity) end

---@param entity Entity
---@return number
function GetEntityHeading(entity) end

---@param entity Entity
---@return Hash
function GetEntityModel(entity) end

---@param entity Entity
---@param rotationOrder integer
---@return vector3
function GetEntityRotation(entity, rotationOrder) end

---@param model Hash
---@return vector3 min
---@return vector3 max
function GetModelDimensions(model) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function DrawLine(x1, y1, z1, x2, y2, z2, r, g, b, a) end

---@param name string
---@param defaultValue integer
---@return integer
function GetConvarInt(name, defaultValue) end

---@param eventName string
---@param ... unknown
function TriggerServerEvent(eventName, ...) end
