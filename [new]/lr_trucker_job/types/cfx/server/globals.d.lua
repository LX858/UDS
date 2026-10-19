---@meta

source = source ---@type PlayerId

---@param eventName string
---@param target PlayerId|PlayerId[]
---@param ... unknown
function TriggerClientEvent(eventName, target, ...) end

---@param eventName string
---@param target PlayerId|PlayerId[]
---@param bps integer
---@param ... unknown
function TriggerLatentClientEvent(eventName, target, bps, ...) end

---@param playerSrc PlayerId
---@param identifierType? string
---@return string|nil
function GetPlayerIdentifierByType(playerSrc, identifierType) end
