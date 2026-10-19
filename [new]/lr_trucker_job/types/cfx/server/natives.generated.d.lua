---@meta

-- Generated from pinned CitizenFX metadata snapshot 169c1c91b5f7-d9a24c719642. Do not edit.

---@param x number
---@param y number
---@param z number
---@param width number
---@param height number
---@return integer
function AddBlipForArea(x, y, z, width, height) end

---@param x number
---@param y number
---@param z number
---@return integer
function AddBlipForCoord(x, y, z) end

---@param entity Entity
---@return integer
function AddBlipForEntity(entity) end

---@param posX number
---@param posY number
---@param posZ number
---@param radius number
---@return integer
function AddBlipForRadius(posX, posY, posZ, radius) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function AddPedDecorationFromHashes(ped, collection, overlay) end

---@param entity Entity
---@param forceType integer
---@param x number
---@param y number
---@param z number
---@param offX number
---@param offY number
---@param offZ number
---@param nComponent integer
---@param bLocalForce boolean
---@param bLocalOffset boolean
---@param bScaleByMass boolean
---@param bPlayAudio boolean
---@param bScaleByTimeWarp boolean
function ApplyForceToEntity(entity, forceType, x, y, z, offX, offY, offZ, nComponent, bLocalForce, bLocalOffset, bScaleByMass, bPlayAudio, bScaleByTimeWarp) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function ApplyPedOverlay(ped, collection, overlay) end

---@param playerSrc string
---@return boolean
function CanPlayerStartCommerceSession(playerSrc) end

---@param ped Ped
---@param propId integer
function ClearPedProp(ped, propId) end

---@param ped Ped
function ClearPedSecondaryTask(ped) end

---@param ped Ped
function ClearPedTasks(ped) end

---@param ped Ped
function ClearPedTasksImmediately(ped) end

---@param player integer
function ClearPlayerWantedLevel(player) end

---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param isNetwork boolean
---@param netMissionEntity boolean
---@param doorFlag boolean
---@return Entity
function CreateObject(modelHash, x, y, z, isNetwork, netMissionEntity, doorFlag) end

---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param isNetwork boolean
---@param netMissionEntity boolean
---@param doorFlag boolean
---@return Entity
function CreateObjectNoOffset(modelHash, x, y, z, isNetwork, netMissionEntity, doorFlag) end

---@param pedType integer
---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param heading number
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@return Entity
function CreatePed(pedType, modelHash, x, y, z, heading, isNetwork, bScriptHostPed) end

---@param vehicle integer
---@param pedType integer
---@param modelHash Hash|string
---@param seat integer
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@return Entity
function CreatePedInsideVehicle(vehicle, pedType, modelHash, seat, isNetwork, bScriptHostPed) end

---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param heading number
---@param isNetwork boolean
---@param netMissionEntity boolean
---@return Entity
function CreateVehicle(modelHash, x, y, z, heading, isNetwork, netMissionEntity) end

---@param modelHash Hash|string
---@param type string
---@param x number
---@param y number
---@param z number
---@param heading number
---@return integer
function CreateVehicleServerSetter(modelHash, type, x, y, z, heading) end

---@param entity Entity
function DeleteEntity(entity) end

---@param entity Entity
function DeleteTrain(entity) end

---@param vehicle integer
---@return boolean
function DoesBoatSinkWhenWrecked(vehicle) end

---@param entity integer
---@return boolean
function DoesEntityExist(entity) end

---@param playerSrc string
---@return boolean
function DoesPlayerExist(playerSrc) end

---@param playerSrc string
---@param skuId integer
---@return boolean
function DoesPlayerOwnSku(playerSrc, skuId) end

---@param playerSrc string
---@param skuId integer
---@return boolean
function DoesPlayerOwnSkuExt(playerSrc, skuId) end

---@param playerSrc string
---@param reason string
function DropPlayer(playerSrc, reason) end

---@param enabled boolean
function EnableEnhancedHostSupport(enabled) end

---@param private_ boolean
function FlagServerAsPrivate(private_) end

function FlushResourceKvp() end

---@param entity Entity
---@param toggle boolean
function FreezeEntityPosition(entity, toggle) end

---@param playerSrc string
---@return number
function GetAirDragMultiplierForPlayersVehicle(playerSrc) end

---@return table
function GetAllObjects() end

---@return table
function GetAllPeds() end

---@return table
function GetAllVehicles() end

---@return string
function GetConsoleBuffer() end

---@param ped Ped
---@return Hash
function GetCurrentPedWeapon(ped) end

---@param entity Entity
---@return Entity
function GetEntityAttachedTo(entity) end

---@param entity Entity
---@return boolean
function GetEntityCollisionDisabled(entity) end

---@param entity Entity
---@return vector3
function GetEntityCoords(entity) end

---@param entity Entity
---@return number
function GetEntityHeading(entity) end

---@param entity Entity
---@return integer
function GetEntityHealth(entity) end

---@param entity Entity
---@return integer
function GetEntityMaxHealth(entity) end

---@param entity Entity
---@return Hash
function GetEntityModel(entity) end

---@param entity Entity
---@return integer
function GetEntityOrphanMode(entity) end

---@param entity Entity
---@return integer
function GetEntityPopulationType(entity) end

---@param entity Entity
---@return boolean
function GetEntityRemoteSyncedScenesAllowed(entity) end

---@param entity Entity
---@return vector3
function GetEntityRotation(entity) end

---@param entity Entity
---@return vector3
function GetEntityRotationVelocity(entity) end

---@param entity Entity
---@return integer
function GetEntityRoutingBucket(entity) end

---@param entity Entity
---@return string
function GetEntityScript(entity) end

---@param entity Entity
---@return number
function GetEntitySpeed(entity) end

---@param entity Entity
---@return integer
function GetEntityType(entity) end

---@param entity Entity
---@return vector3
function GetEntityVelocity(entity) end

---@param model string
---@return Hash
function GetHashKey(model) end

---@param heli integer
---@return integer
function GetHeliBodyHealth(heli) end

---@param heli integer
---@return boolean
function GetHeliDisableExplodeFromBodyDamage(heli) end

---@param heli integer
---@return integer
function GetHeliEngineHealth(heli) end

---@param heli integer
---@return integer
function GetHeliGasTankHealth(heli) end

---@param heli integer
---@return number
function GetHeliMainRotorDamageScale(heli) end

---@param vehicle integer
---@return number
function GetHeliMainRotorHealth(vehicle) end

---@param heli integer
---@return number
function GetHeliPitchControl(heli) end

---@param heli integer
---@return number
function GetHeliRearRotorDamageScale(heli) end

---@param vehicle integer
---@return number
function GetHeliRearRotorHealth(vehicle) end

---@param heli integer
---@return number
function GetHeliRollControl(heli) end

---@param heli integer
---@return number
function GetHeliTailRotorDamageScale(heli) end

---@param vehicle integer
---@return number
function GetHeliTailRotorHealth(vehicle) end

---@param heli integer
---@return number
function GetHeliThrottleControl(heli) end

---@param heli integer
---@return number
function GetHeliYawControl(heli) end

---@return string
function GetHostId() end

---@param heli integer
---@return boolean
function GetIsHeliEngineRunning(heli) end

---@param vehicle integer
---@return boolean
function GetIsVehicleEngineRunning(vehicle) end

---@param vehicle integer
---@return boolean
function GetIsVehiclePrimaryColourCustom(vehicle) end

---@param vehicle integer
---@return boolean
function GetIsVehicleSecondaryColourCustom(vehicle) end

---@param vehicle integer
---@return integer
function GetLandingGearState(vehicle) end

---@param vehicle integer
---@param seatIndex integer
---@return Entity
function GetLastPedInVehicleSeat(vehicle, seatIndex) end

---@param entity Entity
---@return integer
function GetNetTypeFromEntity(entity) end

---@param playerSrc string
---@return integer
function GetNumPlayerIdentifiers(playerSrc) end

---@return integer
function GetNumPlayerIndices() end

---@param playerSrc string
---@return integer
function GetNumPlayerTokens(playerSrc) end

---@param password string
---@return string
function GetPasswordHash(password) end

---@param ped Ped
---@return integer
function GetPedArmour(ped) end

---@param ped Ped
---@return Hash
function GetPedCauseOfDeath(ped) end

---@param ped Ped
---@return number
function GetPedDesiredHeading(ped) end

---@param vehicle integer
---@param seatIndex integer
---@return Entity
function GetPedInVehicleSeat(vehicle, seatIndex) end

---@param ped Ped
---@return integer
function GetPedMaxHealth(ped) end

---@param ped Ped
---@return Hash
function GetPedRelationshipGroupHash(ped) end

---@param ped Ped
---@return Hash
function GetPedScriptTaskCommand(ped) end

---@param ped Ped
---@return integer
function GetPedScriptTaskStage(ped) end

---@param ped Ped
---@return Entity
function GetPedSourceOfDamage(ped) end

---@param ped Ped
---@return Entity
function GetPedSourceOfDeath(ped) end

---@param ped Ped
---@param index integer
---@return integer
function GetPedSpecificTaskType(ped, index) end

---@param ped Ped
---@return boolean
function GetPedStealthMovement(ped) end

---@param playerSrc string
---@return vector3
function GetPlayerCameraRotation(playerSrc) end

---@param playerSrc string
---@return string
function GetPlayerEndpoint(playerSrc) end

---@param playerSrc string
---@return integer
function GetPlayerFakeWantedLevel(playerSrc) end

---@param playerSrc string
---@return vector3
function GetPlayerFocusPos(playerSrc) end

---@param index integer
---@return string
function GetPlayerFromIndex(index) end

---@param playerSrc string
---@return string
function GetPlayerGuid(playerSrc) end

---@param playerSrc string
---@param identiferIndex integer
---@return string
function GetPlayerIdentifier(playerSrc, identiferIndex) end

---@param playerSrc string
---@return boolean
function GetPlayerInvincible(playerSrc) end

---@param playerSrc string
---@return integer
function GetPlayerLastMsg(playerSrc) end

---@param playerSrc string
---@return integer
function GetPlayerMaxArmour(playerSrc) end

---@param playerSrc string
---@return integer
function GetPlayerMaxHealth(playerSrc) end

---@param playerSrc string
---@return string
function GetPlayerName(playerSrc) end

---@param playerSrc string
---@return Entity
function GetPlayerPed(playerSrc) end

---@param playerSrc string
---@param peerStatistic integer
---@return integer
function GetPlayerPeerStatistics(playerSrc, peerStatistic) end

---@param playerSrc string
---@return integer
function GetPlayerPing(playerSrc) end

---@param playerSrc string
---@return integer
function GetPlayerRoutingBucket(playerSrc) end

---@param playerSrc string
---@return integer
function GetPlayerTeam(playerSrc) end

---@param playerSrc string
---@param lastPursuit boolean
---@return integer
function GetPlayerTimeInPursuit(playerSrc, lastPursuit) end

---@param playerSrc string
---@return integer
function GetPlayerTimeOnline(playerSrc) end

---@param playerSrc string
---@param index integer
---@return string
function GetPlayerToken(playerSrc, index) end

---@param playerSrc string
---@return vector3
function GetPlayerWantedCentrePosition(playerSrc) end

---@param playerSrc string
---@return integer
function GetPlayerWantedLevel(playerSrc) end

---@param resourceName string
---@return string
function GetResourcePath(resourceName) end

---@param ped Ped
---@return integer
function GetSeatPedIsUsing(ped) end

---@param ped Ped
---@return Hash
function GetSelectedPedWeapon(ped) end

---@param jetpack integer
---@return number
function GetThrusterSideRcsThrottle(jetpack) end

---@param jetpack integer
---@return number
function GetThrusterThrottle(jetpack) end

---@param train integer
---@return integer
function GetTrainBackwardCarriage(train) end

---@param train integer
---@return integer
function GetTrainCarriageEngine(train) end

---@param train integer
---@return integer
function GetTrainCarriageIndex(train) end

---@param train integer
---@return integer
function GetTrainForwardCarriage(train) end

---@param vehicle integer
---@return number
function GetVehicleBodyHealth(vehicle) end

---@param vehicle integer
---@return integer colorPrimary
---@return integer colorSecondary
function GetVehicleColours(vehicle) end

---@param vehicle integer
---@return integer r
---@return integer g
---@return integer b
function GetVehicleCustomPrimaryColour(vehicle) end

---@param vehicle integer
---@return integer r
---@return integer g
---@return integer b
function GetVehicleCustomSecondaryColour(vehicle) end

---@param vehicle integer
---@return integer color
function GetVehicleDashboardColour(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleDirtLevel(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleDoorLockStatus(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleDoorsLockedForPlayer(vehicle) end

---@param vehicle integer
---@param doorIndex integer
---@return integer
function GetVehicleDoorStatus(vehicle, doorIndex) end

---@param vehicle integer
---@return number
function GetVehicleEngineHealth(vehicle) end

---@param vehicle integer
---@return integer pearlescentColor
---@return integer wheelColor
function GetVehicleExtraColours(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleFlightNozzlePosition(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleHeadlightsColour(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleHomingLockonState(vehicle) end

---@param vehicle integer
---@return Hash
function GetVehicleHornType(vehicle) end

---@param vehicle integer
---@return integer color
function GetVehicleInteriorColour(vehicle) end

---@param vehicle integer
---@return boolean
---@return boolean lightsOn
---@return boolean highbeamsOn
function GetVehicleLightsState(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleLivery(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleLockOnTarget(vehicle) end

---@param vehicle integer
---@return integer red
---@return integer green
---@return integer blue
function GetVehicleNeonColour(vehicle) end

---@param vehicle integer
---@param neonIndex integer
---@return boolean
function GetVehicleNeonEnabled(vehicle, neonIndex) end

---@param vehicle integer
---@return string
function GetVehicleNumberPlateText(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleNumberPlateTextIndex(vehicle) end

---@param ped Ped
---@param lastVehicle boolean
---@return integer
function GetVehiclePedIsIn(ped, lastVehicle) end

---@param vehicle integer
---@return number
function GetVehiclePetrolTankHealth(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleRadioStationIndex(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleRoofLivery(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleTotalRepairs(vehicle) end

---@param vehicle integer
---@return integer r
---@return integer g
---@return integer b
function GetVehicleTyreSmokeColor(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleWheelType(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleWindowTint(vehicle) end

---@param ped Ped
---@param weaponHash Hash|string
---@param componentHash Hash|string
function GiveWeaponComponentToPed(ped, weaponHash, componentHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@param ammoCount integer
---@param isHidden boolean
---@param bForceInHand boolean
function GiveWeaponToPed(ped, weaponHash, ammoCount, isHidden, bForceInHand) end

---@param vehicle integer
---@return boolean
function HasEntityBeenMarkedAsNoLongerNeeded(vehicle) end

---@param vehicle integer
---@return boolean
function HasVehicleBeenDamagedByBullets(vehicle) end

---@param vehicle integer
---@return boolean
function HasVehicleBeenOwnedByPlayer(vehicle) end

---@param vehicle integer
---@return boolean
function IsBoatAnchoredAndFrozen(vehicle) end

---@param vehicle integer
---@return boolean
function IsBoatWrecked(vehicle) end

---@param entity Entity
---@return boolean
function IsEntityVisible(entity) end

---@param ped Ped
---@return boolean
function IsFlashLightOn(ped) end

---@param heli integer
---@return boolean
function IsHeliTailBoomBreakable(heli) end

---@param heli integer
---@return boolean
function IsHeliTailBoomBroken(heli) end

---@param ped Ped
---@return boolean
function IsPedAPlayer(ped) end

---@param ped Ped
---@return boolean
function IsPedHandcuffed(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnyVehicle(ped) end

---@param ped Ped
---@param vehicle integer
---@return boolean
function IsPedInVehicle(ped, vehicle) end

---@param ped Ped
---@return boolean
function IsPedRagdoll(ped) end

---@param ped Ped
---@return boolean
function IsPedStrafing(ped) end

---@param ped Ped
---@return boolean
function IsPedUsingActionMode(ped) end

---@param playerSrc string
---@param object string
---@return boolean
function IsPlayerAceAllowed(playerSrc, object) end

---@param playerSrc string
---@return boolean
function IsPlayerCommerceInfoLoaded(playerSrc) end

---@param playerSrc string
---@return boolean
function IsPlayerCommerceInfoLoadedExt(playerSrc) end

---@param playerSrc string
---@return boolean
function IsPlayerEvadingWantedLevel(playerSrc) end

---@param playerSrc string
---@return boolean
function IsPlayerInFreeCamMode(playerSrc) end

---@param playerSrc string
---@return boolean
function IsPlayerUsingSuperJump(playerSrc) end

---@param train integer
---@return boolean
function IsTrainCaboose(train) end

---@param vehicle integer
---@param extraId integer
---@return boolean
function IsVehicleExtraTurnedOn(vehicle, extraId) end

---@param vehicle integer
---@return boolean
function IsVehicleSirenOn(vehicle) end

---@param vehicle integer
---@param wheelID integer
---@param completely boolean
---@return boolean
function IsVehicleTyreBurst(vehicle, wheelID, completely) end

---@param vehicle integer
---@param windowIndex integer
---@return boolean
function IsVehicleWindowIntact(vehicle, windowIndex) end

---@param playerSrc string
function LoadPlayerCommerceData(playerSrc) end

---@param playerSrc string
function LoadPlayerCommerceDataExt(playerSrc) end

---@param id integer
function MumbleCreateChannel(id) end

---@param playerSrc integer
---@return boolean
function MumbleIsPlayerMuted(playerSrc) end

---@param playerSrc integer
---@param toggle boolean
function MumbleSetPlayerMuted(playerSrc, toggle) end

---@param x number
---@param y number
---@param z number
---@param width number
---@param height number
---@return integer
function N_0xce5d0e5e315db238(x, y, z, width, height) end

---@param netId integer
---@return Entity
function NetworkGetEntityFromNetworkId(netId) end

---@param entity Entity
---@return integer
function NetworkGetFirstEntityOwner(entity) end

---@param entity Entity
---@return integer
function NetworkGetNetworkIdFromEntity(entity) end

---@param playerSrc string
---@return vector3
function NetworkGetVoiceProximityOverrideForPlayer(playerSrc) end

---@param requestData string
---@param requestDataLength integer
---@return integer
function PerformHttpRequestInternal(requestData, requestDataLength) end

---@param requestData table
---@return integer
function PerformHttpRequestInternalEx(requestData) end

---@param jsonString string
function PrintStructuredTrace(jsonString) end

---@param listener function
function RegisterConsoleListener(listener) end

---@param resourceName string
---@param fileName string
---@return string
function RegisterResourceAsset(resourceName, fileName) end

---@param factoryId string
---@param factoryFn function
function RegisterResourceBuildTaskFactory(factoryId, factoryFn) end

---@param ped Ped
---@param p1 boolean
function RemoveAllPedWeapons(ped, p1) end

---@return integer blip
function RemoveBlip() end

---@param ped Ped
---@param weaponHash Hash|string
---@param componentHash Hash|string
function RemoveWeaponComponentFromPed(ped, weaponHash, componentHash) end

---@param ped Ped
---@param weaponHash Hash|string
function RemoveWeaponFromPed(ped, weaponHash) end

---@param playerSrc string
---@param skuId integer
function RequestPlayerCommerceSession(playerSrc, skuId) end

---@param resourceName string
---@param fileName string
---@param data string
---@param dataLength integer
---@return boolean
function SaveResourceFile(resourceName, fileName, data, dataLength) end

---@param rootPath string
---@param callback function
function ScanResourceRoot(rootPath, callback) end

---@param resourceName string
function ScheduleResourceTick(resourceName) end

---@param blip integer
---@param spriteId integer
function SetBlipSprite(blip, spriteId) end

---@param varName string
---@param value string
function SetConvar(varName, value) end

---@param varName string
---@param value string
function SetConvarReplicated(varName, value) end

---@param varName string
---@param value string
function SetConvarServerInfo(varName, value) end

---@param ped Ped
---@param weaponHash Hash|string
---@param bForceInHand boolean
function SetCurrentPedWeapon(ped, weaponHash, bForceInHand) end

---@param entity Entity
---@param xPos number
---@param yPos number
---@param zPos number
---@param alive boolean
---@param deadFlag boolean
---@param ragdollFlag boolean
---@param clearArea boolean
function SetEntityCoords(entity, xPos, yPos, zPos, alive, deadFlag, ragdollFlag, clearArea) end

---@param entity Entity
---@param radius number
function SetEntityDistanceCullingRadius(entity, radius) end

---@param entity Entity
---@param heading number
function SetEntityHeading(entity, heading) end

---@param entity Entity
---@param ignore boolean
function SetEntityIgnoreRequestControlFilter(entity, ignore) end

---@param entity Entity
---@param orphanMode integer
function SetEntityOrphanMode(entity, orphanMode) end

---@param entity Entity
---@param allow boolean
function SetEntityRemoteSyncedScenesAllowed(entity, allow) end

---@param entity Entity
---@param pitch number
---@param roll number
---@param yaw number
---@param rotationOrder integer
---@param bDeadCheck boolean
function SetEntityRotation(entity, pitch, roll, yaw, rotationOrder, bDeadCheck) end

---@param entity Entity
---@param bucket integer
function SetEntityRoutingBucket(entity, bucket) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
function SetEntityVelocity(entity, x, y, z) end

---@param gametypeName string
function SetGameType(gametypeName) end

---@param handler function
function SetHttpHandler(handler) end

---@param mapName string
function SetMapName(mapName) end

---@param ped Ped
---@param weaponHash Hash|string
---@param ammo integer
function SetPedAmmo(ped, weaponHash, ammo) end

---@param ped Ped
---@param amount integer
function SetPedArmour(ped, amount) end

---@param ped Ped
---@param toggle boolean
function SetPedCanRagdoll(ped, toggle) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@param paletteId integer
function SetPedComponentVariation(ped, componentId, drawableId, textureId, paletteId) end

---@param ped Ped
---@param flagId integer
---@param value boolean
function SetPedConfigFlag(ped, flagId, value) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function SetPedDecoration(ped, collection, overlay) end

---@param ped Ped
function SetPedDefaultComponentVariation(ped) end

---@param ped Ped
---@param index integer
function SetPedEyeColor(ped, index) end

---@param ped Ped
---@param index integer
---@param scale number
function SetPedFaceFeature(ped, index, scale) end

---@param ped Ped
---@param colorID integer
---@param highlightColorID integer
function SetPedHairColor(ped, colorID, highlightColorID) end

---@param ped Ped
---@param colorID integer
---@param highlightColorID integer
function SetPedHairTint(ped, colorID, highlightColorID) end

---@param ped Ped
---@param shapeFirstID integer
---@param shapeSecondID integer
---@param shapeThirdID integer
---@param skinFirstID integer
---@param skinSecondID integer
---@param skinThirdID integer
---@param shapeMix number
---@param skinMix number
---@param thirdMix number
---@param isParent boolean
function SetPedHeadBlendData(ped, shapeFirstID, shapeSecondID, shapeThirdID, skinFirstID, skinSecondID, skinThirdID, shapeMix, skinMix, thirdMix, isParent) end

---@param ped Ped
---@param overlayID integer
---@param index integer
---@param opacity number
function SetPedHeadOverlay(ped, overlayID, index, opacity) end

---@param ped Ped
---@param overlayID integer
---@param colorType integer
---@param colorID integer
---@param secondColorID integer
function SetPedHeadOverlayColor(ped, overlayID, colorType, colorID, secondColorID) end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
function SetPedIntoVehicle(ped, vehicle, seatIndex) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@param attach boolean
function SetPedPropIndex(ped, componentId, drawableId, textureId, attach) end

---@param ped Ped
---@param p1 integer
function SetPedRandomComponentVariation(ped, p1) end

---@param ped Ped
function SetPedRandomProps(ped) end

---@param ped Ped
---@param flagId integer
---@param doReset boolean
function SetPedResetFlag(ped, flagId, doReset) end

---@param ped Ped
---@param minTime integer
---@param maxTime integer
---@param ragdollType integer
---@param bAbortIfInjured boolean
---@param bAbortIfDead boolean
---@param bForceScriptControl boolean
function SetPedToRagdoll(ped, minTime, maxTime, ragdollType, bAbortIfInjured, bAbortIfDead, bForceScriptControl) end

---@param ped Ped
---@param minTime integer
---@param maxTime integer
---@param nFallType integer
---@param dirX number
---@param dirY number
---@param dirZ number
---@param fGroundHeight number
---@param grab1X number
---@param grab1Y number
---@param grab1Z number
---@param grab2X number
---@param grab2Y number
---@param grab2Z number
function SetPedToRagdollWithFall(ped, minTime, maxTime, nFallType, dirX, dirY, dirZ, fGroundHeight, grab1X, grab1Y, grab1Z, grab2X, grab2Y, grab2Z) end

---@param player integer
---@param bHasControl boolean
---@param flags integer
function SetPlayerControl(player, bHasControl, flags) end

---@param playerSrc string
---@param radius number
function SetPlayerCullingRadius(playerSrc, radius) end

---@param player integer
---@param bInvincible boolean
function SetPlayerInvincible(player, bInvincible) end

---@param player integer
---@param model Hash|string
function SetPlayerModel(player, model) end

---@param playerSrc string
---@param bucket integer
function SetPlayerRoutingBucket(playerSrc, bucket) end

---@param player integer
---@param wantedLevel integer
---@param delayedResponse boolean
function SetPlayerWantedLevel(player, wantedLevel, delayedResponse) end

---@param bucketId integer
---@param mode string
function SetRoutingBucketEntityLockdownMode(bucketId, mode) end

---@param bucketId integer
---@param mode boolean
function SetRoutingBucketPopulationEnabled(bucketId, mode) end

---@param vehicle integer
---@param state boolean
function SetVehicleAlarm(vehicle, state) end

---@param vehicle integer
---@param value number
function SetVehicleBodyHealth(vehicle, value) end

---@param vehicle integer
---@param colorCombination integer
function SetVehicleColourCombination(vehicle, colorCombination) end

---@param vehicle integer
---@param colorPrimary integer
---@param colorSecondary integer
function SetVehicleColours(vehicle, colorPrimary, colorSecondary) end

---@param vehicle integer
---@param r integer
---@param g integer
---@param b integer
function SetVehicleCustomPrimaryColour(vehicle, r, g, b) end

---@param vehicle integer
---@param r integer
---@param g integer
---@param b integer
function SetVehicleCustomSecondaryColour(vehicle, r, g, b) end

---@param vehicle integer
---@param dirtLevel number
function SetVehicleDirtLevel(vehicle, dirtLevel) end

---@param vehicle integer
---@param doorIndex integer
---@param deleteDoor boolean
function SetVehicleDoorBroken(vehicle, doorIndex, deleteDoor) end

---@param vehicle integer
---@param doorLockStatus integer
function SetVehicleDoorsLocked(vehicle, doorLockStatus) end

---@param vehicle integer
---@param plateText string
function SetVehicleNumberPlateText(vehicle, plateText) end

---@param resourceName string
---@return boolean
function StartResource(resourceName) end

---@param resourceName string
---@return boolean
function StopResource(resourceName) end

---@param ped Ped
---@param targetPed Ped
---@param p2 integer
---@param p3 integer
function TaskCombatPed(ped, targetPed, p2, p3) end

---@param driverPed Ped
---@param targetPed Ped
---@param targetVehicle integer
---@param targetX number
---@param targetY number
---@param targetZ number
---@param distanceToShoot number
---@param pedAccuracy integer
---@param p8 boolean
---@param firingPattern Hash|string
function TaskDriveBy(driverPed, targetPed, targetVehicle, targetX, targetY, targetZ, distanceToShoot, pedAccuracy, p8, firingPattern) end

---@param ped Ped
---@param vehicle integer
---@param timeout integer
---@param seatIndex integer
---@param speed number
---@param flag integer
---@param p6 unknown
function TaskEnterVehicle(ped, vehicle, timeout, seatIndex, speed, flag, p6) end

---@param vehicle integer
function TaskEveryoneLeaveVehicle(vehicle) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param speed number
---@param timeout integer
---@param targetHeading number
---@param distanceToSlide number
function TaskGoStraightToCoord(ped, x, y, z, speed, timeout, targetHeading, distanceToSlide) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param fMoveBlendRatio number
---@param vehicle integer
---@param bUseLongRangeVehiclePathing boolean
---@param drivingFlags integer
---@param fMaxRangeToShootTargets number
function TaskGoToCoordAnyMeans(ped, x, y, z, fMoveBlendRatio, vehicle, bUseLongRangeVehiclePathing, drivingFlags, fMaxRangeToShootTargets) end

---@param entity Entity
---@param target Entity
---@param duration integer
---@param distance number
---@param speed number
---@param p5 number
---@param p6 integer
function TaskGoToEntity(entity, target, duration, distance, speed, p5, p6) end

---@param ped Ped
---@param duration integer
---@param facingPed Ped
---@param p3 integer
---@param p4 boolean
function TaskHandsUp(ped, duration, facingPed, p3, p4) end

---@param ped Ped
---@param p1 integer
---@param flags integer
function TaskLeaveAnyVehicle(ped, p1, flags) end

---@param ped Ped
---@param vehicle integer
---@param flags integer
function TaskLeaveVehicle(ped, vehicle, flags) end

---@param ped Ped
---@param animDictionary string
---@param animationName string
---@param blendInSpeed number
---@param blendOutSpeed number
---@param duration integer
---@param flag integer
---@param playbackRate number
---@param lockX boolean
---@param lockY boolean
---@param lockZ boolean
function TaskPlayAnim(ped, animDictionary, animationName, blendInSpeed, blendOutSpeed, duration, flag, playbackRate, lockX, lockY, lockZ) end

---@param ped Ped
---@param animDictionary string
---@param animationName string
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param blendInSpeed number
---@param blendOutSpeed number
---@param duration integer
---@param flag unknown
---@param animTime number
---@param p14 unknown
---@param p15 unknown
function TaskPlayAnimAdvanced(ped, animDictionary, animationName, posX, posY, posZ, rotX, rotY, rotZ, blendInSpeed, blendOutSpeed, duration, flag, animTime, p14, p15) end

---@param ped Ped
---@param fleeTarget Ped
function TaskReactAndFleePed(ped, fleeTarget) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param duration integer
---@param firingPattern Hash|string
function TaskShootAtCoord(ped, x, y, z, duration, firingPattern) end

---@param entity Entity
---@param target Entity
---@param duration integer
---@param firingPattern Hash|string
function TaskShootAtEntity(entity, target, duration, firingPattern) end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
function TaskWarpPedIntoVehicle(ped, vehicle, seatIndex) end

---@param playerSrc string
---@param reason string
function TempBanPlayer(playerSrc, reason) end

---@param password string
---@param hash string
---@return boolean
function VerifyPasswordHash(password, hash) end
