---@meta

-- Generated from pinned CitizenFX metadata snapshot 169c1c91b5f7-d9a24c719642. Do not edit.

---@param conVarFilter string
---@param handler function
---@return integer
function AddConvarChangeListener(conVarFilter, handler) end

---@param keyFilter string
---@param bagFilter string
---@param handler function
---@return integer
function AddStateBagChangeHandler(keyFilter, bagFilter, handler) end

function CancelEvent() end

---@param referenceIdentity string
function DeleteFunctionReference(referenceIdentity) end

---@param key string
function DeleteResourceKvp(key) end

---@param key string
function DeleteResourceKvpNoSync(key) end

---@param train integer
---@return boolean
function DoesTrainStopAtStations(train) end

---@param referenceIdentity string
---@return string
function DuplicateFunctionReference(referenceIdentity) end

---@param handle integer
function EndFindKvp(handle) end

---@param entity Entity
function EnsureEntityStateBag(entity) end

---@param commandString string
function ExecuteCommand(commandString) end

---@param handle integer
---@return string
function FindKvp(handle) end

---@param traceData table
---@return string
function FormatStackTrace(traceData) end

---@param varName string
---@param default_ string
---@return string
function GetConvar(varName, default_) end

---@param varName string
---@param defaultValue boolean
---@return boolean
function GetConvarBool(varName, defaultValue) end

---@param varName string
---@param defaultValue number
---@return number
function GetConvarFloat(varName, defaultValue) end

---@param varName string
---@param default_ integer
---@return integer
function GetConvarInt(varName, default_) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param entityType integer
---@param sortByDistance boolean
---@param models table
---@return table
function GetEntitiesInRadius(x, y, z, radius, entityType, sortByDistance, models) end

---@param bagName string
---@return Entity
function GetEntityFromStateBagName(bagName) end

---@return integer
function GetGameBuildNumber() end

---@return string
function GetGameName() end

---@param poolName string
---@return table
function GetGamePool(poolName) end

---@return integer
function GetInstanceId() end

---@param resourceName string
---@param metadataKey string
---@return integer
function GetNumResourceMetadata(resourceName, metadataKey) end

---@return integer
function GetNumResources() end

---@param bagName string
---@return integer
function GetPlayerFromStateBagName(bagName) end

---@param playerId integer
---@return number
function GetPlayerMeleeWeaponDamageModifier(playerId) end

---@param playerId integer
---@return number
function GetPlayerWeaponDamageModifier(playerId) end

---@param playerId integer
---@return number
function GetPlayerWeaponDefenseModifier(playerId) end

---@param playerId integer
---@return number
function GetPlayerWeaponDefenseModifier_2(playerId) end

---@return table
function GetRegisteredCommands() end

---@param findIndex integer
---@return string
function GetResourceByFindIndex(findIndex) end

---@param resource string
---@return table
function GetResourceCommands(resource) end

---@param key string
---@return number
function GetResourceKvpFloat(key) end

---@param key string
---@return integer
function GetResourceKvpInt(key) end

---@param key string
---@return string
function GetResourceKvpString(key) end

---@param resourceName string
---@param metadataKey string
---@param index integer
---@return string
function GetResourceMetadata(resourceName, metadataKey, index) end

---@param bagName string
---@return table
function GetStateBagKeys(bagName) end

---@param bagName string
---@param key string
---@return table
function GetStateBagValue(bagName, key) end

---@param train integer
---@return number
function GetTrainCruiseSpeed(train) end

---@param train integer
---@return boolean
function GetTrainDirection(train) end

---@param train integer
---@return integer
function GetTrainState(train) end

---@param train integer
---@return integer
function GetTrainTrackIndex(train) end

---@param vehicle integer
---@return boolean
function GetVehicleHandbrake(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleSteeringAngle(vehicle) end

---@param vehicle integer
---@return string
function GetVehicleType(vehicle) end

---@param object string
---@return boolean
function IsAceAllowed(object) end

---@param entity Entity
---@return boolean
function IsEntityPositionFrozen(entity) end

---@param principal string
---@param object string
---@return boolean
function IsPrincipalAceAllowed(principal, object) end

---@param vehicle integer
---@return boolean
function IsVehicleEngineStarting(vehicle) end

---@param entity Entity
---@return integer
function NetworkGetEntityOwner(entity) end

---@param scopeName string
function ProfilerEnterScope(scopeName) end

function ProfilerExitScope() end

---@return boolean
function ProfilerIsRecording() end

---@param cookie integer
function RemoveConvarChangeListener(cookie) end

---@param cookie integer
function RemoveStateBagChangeHandler(cookie) end

---@param key string
---@param value string
function SetResourceKvp(key, value) end

---@param key string
---@param value number
function SetResourceKvpFloat(key, value) end

---@param key string
---@param value number
function SetResourceKvpFloatNoSync(key, value) end

---@param key string
---@param value integer
function SetResourceKvpInt(key, value) end

---@param key string
---@param value integer
function SetResourceKvpIntNoSync(key, value) end

---@param key string
---@param value string
function SetResourceKvpNoSync(key, value) end

---@param bagName string
---@param keyName string
---@param valueData string
---@param valueLength integer
---@param replicated boolean
function SetStateBagValue(bagName, keyName, valueData, valueLength, replicated) end

---@param prefix string
---@return integer
function StartFindKvp(prefix) end

---@param bagName string
---@param key string
---@return boolean
function StateBagHasKey(bagName, key) end

---@return boolean
function WasEventCanceled() end
