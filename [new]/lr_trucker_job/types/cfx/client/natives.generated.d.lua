---@meta

-- Generated from pinned CitizenFX metadata snapshot 169c1c91b5f7-d9a24c719642. Do not edit.

function AbortTextChat() end

---@param value number
---@return number
function Absf(value) end

---@param value integer
---@return integer
function Absi(value) end

---@param p0 number
---@return number
function Acos(p0) end

---@param mode string
function ActivateAudioSlowmoMode(mode) end

---@param camTo integer
---@param camFrom integer
---@param duration integer
---@param easeLocation integer
---@param easeRotation integer
---@param easeFove integer
function ActivateCamWithInterpAndFovCurve(camTo, camFrom, duration, easeLocation, easeRotation, easeFove) end

---@param netID integer
---@param toggle boolean
function ActivateDamageTrackerOnNetworkId(netID, toggle) end

---@param player integer
---@param toggle boolean
function ActivateDamageTrackerOnPlayer(player, toggle) end

---@param menuhash Hash|string
---@param togglePause boolean
---@param component integer
function ActivateFrontendMenu(menuhash, togglePause, component) end

---@param interior integer
---@param entitySetName string
function ActivateInteriorEntitySet(interior, entitySetName) end

---@param entity Entity
function ActivatePhysics(entity) end

function ActivateRockstarEditor() end

function ActivateTimecycleEditor() end

---@param captionString string
---@param condensedCaptionString string
function ActivityFeedCreate(captionString, condensedCaptionString) end

---@param plane integer
---@return boolean
function AddAMarkerOverVehicle(plane) end

---@param ped Ped
---@param weaponHash Hash|string
---@param ammo integer
function AddAmmoToPed(ped, weaponHash, ammo) end

---@param ped Ped
---@param ammoType Hash|string
---@param ammo integer
function AddAmmoToPedByType(ped, ammoType, ammo) end

---@param ped Ped
---@param amount integer
function AddArmourToPed(ped, amount) end

---@param submixId integer
---@param outputSubmixId integer
function AddAudioSubmixOutput(submixId, outputSubmixId) end

---@param modelNameHash integer
function AddAuthorizedParachuteModel(modelNameHash) end

---@param modelNameHash integer
function AddAuthorizedParachutePackModel(modelNameHash) end

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

---@param pickup integer
---@return integer
function AddBlipForPickup(pickup) end

---@param posX number
---@param posY number
---@param posZ number
---@param radius number
---@return integer
function AddBlipForRadius(posX, posY, posZ, radius) end

---@param camera integer
---@param x number
---@param y number
---@param z number
---@param xRot number
---@param yRot number
---@param zRot number
---@param length integer
---@param p8 integer
---@param transitionType integer
function AddCamSplineNode(camera, x, y, z, xRot, yRot, zRot, length, p8, transitionType) end

---@param cam integer
---@param cam2 integer
---@param length integer
---@param p3 integer
function AddCamSplineNodeUsingCamera(cam, cam2, length, p3) end

---@param cam integer
---@param cam2 integer
---@param p2 integer
---@param p3 integer
function AddCamSplineNodeUsingCameraFrame(cam, cam2, p2, p3) end

---@param cam integer
---@param p1 integer
---@param p2 integer
function AddCamSplineNodeUsingGameplayFrame(cam, p1, p2) end

---@param vehicle integer
---@param ped Ped
---@param boneIndex integer
---@param x1 number
---@param x2 number
---@param x3 number
---@param y1 number
---@param y2 number
---@param y3 number
---@param z1 number
---@param z2 number
---@param z3 number
---@param scale number
---@param p13 unknown
---@param alpha integer
---@return boolean
function AddClanDecalToVehicle(vehicle, ped, boneIndex, x1, x2, x3, y1, y2, y3, z1, z2, z3, scale, p13, alpha) end

---@param playerX number
---@param playerY number
---@param playerZ number
---@param radiusX number
---@param radiusY number
---@param radiusZ number
---@param p6 boolean
---@param p7 boolean
---@param p8 boolean
---@param p9 boolean
function AddCoverBlockingArea(playerX, playerY, playerZ, radiusX, radiusY, radiusZ, p6, p7, p8, p9) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 boolean
---@return integer
function AddCoverPoint(p0, p1, p2, p3, p4, p5, p6, p7) end

---@param xLow number
---@param yLow number
---@param xHigh number
---@param yHigh number
---@param height number
---@return integer
function AddCurrentRise(xLow, yLow, xHigh, yHigh, height) end

---@param decalType integer
---@param posX number
---@param posY number
---@param posZ number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param sideX number
---@param sideY number
---@param sideZ number
---@param width number
---@param height number
---@param rCoef number
---@param gCoef number
---@param bCoef number
---@param opacity number
---@param timeout number
---@param isLongRange boolean
---@param isDynamic boolean
---@param useComplexColn boolean
---@return integer
function AddDecal(decalType, posX, posY, posZ, dirX, dirY, dirZ, sideX, sideY, sideZ, width, height, rCoef, gCoef, bCoef, opacity, timeout, isLongRange, isDynamic, useComplexColn) end

---@param decalType integer
---@param textureDict string
---@param textureName string
function AddDecalToMarker(decalType, textureDict, textureName) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@return unknown
function AddDispatchSpawnBlockingAngledArea(x1, y1, z1, x2, y2, z2, width) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return unknown
function AddDispatchSpawnBlockingArea(x1, y1, x2, y2) end

---@param doorHash Hash|string
---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param p5 boolean
---@param scriptDoor boolean
---@param isLocal boolean
function AddDoorToSystem(doorHash, modelHash, x, y, z, p5, scriptDoor, isLocal) end

---@param entity Entity
---@param icon string
---@return unknown
function AddEntityIcon(entity, icon) end

---@param entity Entity
---@param groupName string
---@param fadeIn number
function AddEntityToAudioMixGroup(entity, groupName, fadeIn) end

---@param x number
---@param y number
---@param z number
---@param explosionType integer
---@param damageScale number
---@param isAudible boolean
---@param isInvisible boolean
---@param cameraShake number
function AddExplosion(x, y, z, explosionType, damageScale, isAudible, isInvisible, cameraShake) end

---@param x number
---@param y number
---@param z number
---@param explosionType integer
---@param explosionFx Hash|string
---@param damageScale number
---@param isAudible boolean
---@param isInvisible boolean
---@param cameraShake number
function AddExplosionWithUserVfx(x, y, z, explosionType, explosionFx, damageScale, isAudible, isInvisible, cameraShake) end

---@param xLow number
---@param yLow number
---@param xHigh number
---@param yHigh number
---@param height number
---@return integer
function AddExtraCalmingQuad(xLow, yLow, xHigh, yHigh, height) end

---@param hash Hash|string
function AddFrontendMenuContext(hash) end

---@param configName string
---@param defaultHealth number
---@param defaultArmor number
---@param defaultEndurance number
---@param fatiguedHealthThreshold number
---@param injuredHealthThreshold number
---@param dyingHealthThreshold number
---@param hurtHealthThreshold number
---@param dogTakedownThreshold number
---@param writheFromBulletThreshold number
---@param meleeCardinalFatalAttack boolean
---@param invincible boolean
function AddHealthConfig(configName, defaultHealth, defaultArmor, defaultEndurance, fatiguedHealthThreshold, injuredHealthThreshold, dyingHealthThreshold, hurtHealthThreshold, dogTakedownThreshold, writheFromBulletThreshold, meleeCardinalFatalAttack, invincible) end

---@param x number
---@param y number
---@param z number
---@param p3 number
---@param p4 unknown
---@return integer
function AddHospitalRestart(x, y, z, p3, p4) end

---@param speakerConversationIndex integer
---@param context string
---@param subtitle string
---@param listenerNumber integer
---@param volumeType integer
---@param isRandom boolean
---@param interruptible boolean
---@param ducksRadio boolean
---@param ducksScore boolean
---@param audibility integer
---@param headset boolean
---@param dontInterruptForSpecialAbility boolean
---@param isPadSpeakerRoute boolean
function AddLineToConversation(speakerConversationIndex, context, subtitle, listenerNumber, volumeType, isRandom, interruptible, ducksRadio, ducksScore, audibility, headset, dontInterruptForSpecialAbility, isPadSpeakerRoute) end

---@param name string
---@return integer
function AddMinimapOverlay(name) end

---@param name string
---@param depth integer
---@return integer
function AddMinimapOverlayWithDepth(name, depth) end

---@param modelHash Hash|string
---@return boolean
function AddModelToCreatorBudget(modelHash) end

---@param x number
---@param y number
---@param z number
---@param width number
---@param length number
---@param height number
---@param heading number
---@param bPermanent boolean
---@param flags integer
---@return unknown
function AddNavmeshBlockingObject(x, y, z, width, length, height, heading, bPermanent, flags) end

---@param x number
---@param y number
---@param radius number
function AddNavmeshRequiredRegion(x, y, radius) end

---@param addToBrief boolean
function AddNextMessageToPreviousBriefs(addToBrief) end

---@param x number
---@param y number
---@param z number
---@param groundLvl number
---@param width number
---@param transparency number
---@return integer
function AddOilDecal(x, y, z, groundLvl, width, transparency) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param explosionType integer
---@param damageScale number
---@param isAudible boolean
---@param isInvisible boolean
---@param cameraShake number
function AddOwnedExplosion(ped, x, y, z, explosionType, damageScale, isAudible, isInvisible, cameraShake) end

---@param id1 integer
---@param id2 integer
function AddPatrolRouteLink(id1, id2) end

---@param id integer
---@param guardScenario string
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param waitTime integer
function AddPatrolRouteNode(id, guardScenario, x1, y1, z1, x2, y2, z2, waitTime) end

---@param ped Ped
---@param ammoType Hash|string
---@param ammo integer
function AddPedAmmo(ped, ammoType, ammo) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function AddPedDecorationFromHashes(ped, collection, overlay) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function AddPedDecorationFromHashesInCorona(ped, collection, overlay) end

---@param speakerConversationIndex integer
---@param ped Ped
---@param voiceName string
function AddPedToConversation(speakerConversationIndex, ped, voiceName) end

---@param x number
---@param y number
---@param z number
---@param groundLvl number
---@param width number
---@param transparency number
---@return integer
function AddPetrolDecal(x, y, z, groundLvl, width, transparency) end

---@param x number
---@param y number
---@param z number
---@param p3 number
function AddPetrolTrailDecalInfo(x, y, z, p3) end

---@param pickup integer
---@param roomName string
function AddPickupToInteriorRoomByName(pickup, roomName) end

---@param x number
---@param y number
---@param z number
function AddPointToGpsCustomRoute(x, y, z) end

---@param x number
---@param y number
---@param z number
function AddPointToGpsMultiRoute(x, y, z) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 unknown
---@return unknown
function AddPoliceRestart(p0, p1, p2, p3, p4) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param p6 number
---@param p7 number
---@param p8 boolean
---@return integer
function AddPopMultiplierArea(x1, y1, z1, x2, y2, z2, p6, p7, p8) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param pedMultiplier number
---@param vehicleMultiplier number
---@param p6 boolean
---@param p7 boolean
---@return integer
function AddPopMultiplierSphere(x, y, z, radius, pedMultiplier, vehicleMultiplier, p6, p7) end

---@param name string
---@return unknown
---@return Hash groupHash
function AddRelationshipGroup(name) end

---@param origTxd string
---@param origTxn string
---@param newTxd string
---@param newTxn string
function AddReplaceTexture(origTxd, origTxn, newTxd, newTxn) end

---@param value unknown
function AddReplayStatValue(value) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param speed number
---@param p5 boolean
---@return integer
function AddRoadNodeSpeedZone(x, y, z, radius, speed, p5) end

---@param x number
---@param y number
---@param z number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param maxLength number
---@param ropeType integer
---@param initLength number
---@param minLength number
---@param lengthChangeRate number
---@param onlyPPU boolean
---@param collisionOn boolean
---@param lockFromFront boolean
---@param timeMultiplier number
---@param breakable boolean
---@return integer
---@return unknown unkPtr
function AddRope(x, y, z, rotX, rotY, rotZ, maxLength, ropeType, initLength, minLength, lengthChangeRate, onlyPPU, collisionOn, lockFromFront, timeMultiplier, breakable) end

---@param posMinX number
---@param posMinY number
---@param posMinZ number
---@param posMaxX number
---@param posMaxY number
---@param posMaxZ number
---@param network boolean
---@param cancelActive boolean
---@param blockPeds boolean
---@param blockVehicles boolean
---@return integer
function AddScenarioBlockingArea(posMinX, posMinY, posMinZ, posMaxX, posMaxY, posMaxZ, network, cancelActive, blockPeds, blockVehicles) end

---@param name string
---@param model Hash|string
---@param p2 number
---@param p3 number
function AddScriptToRandomPed(name, model, p2, p3) end

---@param eventType integer
---@param x number
---@param y number
---@param z number
---@param duration number
---@return integer
function AddShockingEventAtPosition(eventType, x, y, z, duration) end

---@param eventType integer
---@param entity Entity
---@param duration number
---@return integer
function AddShockingEventForEntity(eventType, entity, duration) end

---@param x number
---@param y number
---@param z number
---@param explosionType integer
---@param explosionFx Hash|string
---@param damageScale number
---@param isAudible boolean
---@param isInvisible boolean
---@param cameraShake number
function AddSpecfxExplosion(x, y, z, explosionType, explosionFx, damageScale, isAudible, isInvisible, cameraShake) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param speed number
---@param p5 boolean
---@return integer
function AddSpeedZoneForCoord(x, y, z, radius, speed, p5) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param x4 number
---@param y4 number
---@param z4 number
---@param camX number
---@param camY number
---@param camZ number
---@param unk1 integer
---@param unk2 integer
---@param unk3 integer
---@return integer
function AddStuntJump(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, camX, camY, camZ, unk1, unk2, unk3) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius1 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param x4 number
---@param y4 number
---@param z4 number
---@param radius2 number
---@param camX number
---@param camY number
---@param camZ number
---@param unk1 integer
---@param unk2 integer
---@param unk3 integer
---@return integer
function AddStuntJumpAngled(x1, y1, z1, x2, y2, z2, radius1, x3, y3, z3, x4, y4, z4, radius2, camX, camY, camZ, unk1, unk2, unk3) end

---@param x number
---@param y number
---@param z number
function AddTacticalAnalysisPoint(x, y, z) end

---@param modifierName1 string
---@param modifierName2 string
function AddTcmodifierOverride(modifierName1, modifierName2) end

---@param p0 string
---@param p1 integer
function AddTextComponentAppTitle(p0, p1) end

---@param value number
---@param decimalPlaces integer
function AddTextComponentFloat(value, decimalPlaces) end

---@param value integer
---@param commaSeparated boolean
function AddTextComponentFormattedInteger(value, commaSeparated) end

---@param value integer
function AddTextComponentInteger(value) end

---@param labelName string
function AddTextComponentItemString(labelName) end

---@param string string
function AddTextComponentScaleform(string) end

---@param text string
function AddTextComponentString(text) end

---@param website string
function AddTextComponentString2(website) end

---@param string string
function AddTextComponentString3(string) end

---@param blip integer
function AddTextComponentSubstringBlipName(blip) end

---@param string string
function AddTextComponentSubstringKeyboardDisplay(string) end

---@param p0 string
---@param p1 integer
function AddTextComponentSubstringPhoneNumber(p0, p1) end

---@param text string
function AddTextComponentSubstringPlayerName(text) end

---@param labelName string
function AddTextComponentSubstringTextLabel(labelName) end

---@param gxtEntryHash Hash|string
function AddTextComponentSubstringTextLabelHashKey(gxtEntryHash) end

---@param timestamp integer
---@param flags integer
function AddTextComponentSubstringTime(timestamp, flags) end

---@param website string
function AddTextComponentSubstringWebsite(website) end

---@param entryKey string
---@param entryText string
function AddTextEntry(entryKey, entryText) end

---@param entryKey Hash|string
---@param entryText string
function AddTextEntryByHash(entryKey, entryText) end

---@param hours integer
---@param minutes integer
---@param seconds integer
function AddToClockTime(hours, minutes, seconds) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
function AddToItemset(p0, p1) end

---@param gamerTagId integer
---@return boolean
function AddTrevorRandomModifier(gamerTagId) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@return unknown
function AddVehicleCombatAngledAvoidanceArea(p0, p1, p2, p3, p4, p5, p6) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@return unknown
function AddVehicleCombatAvoidanceArea(p0, p1, p2, p3, p4, p5, p6) end

---@param vehicle integer
---@param ped Ped
---@param boneIndex integer
---@param x1 number
---@param x2 number
---@param x3 number
---@param y1 number
---@param y2 number
---@param y3 number
---@param z1 number
---@param z2 number
---@param z3 number
---@param scale number
---@param p13 unknown
---@param alpha integer
---@return boolean
function AddVehicleCrewEmblem(vehicle, ped, boneIndex, x1, x2, x3, y1, y2, y3, z1, z2, z3, scale, p13, alpha) end

---@param vehicle integer
function AddVehiclePhoneExplosiveDevice(vehicle) end

---@param p0 unknown
---@param p1 number
---@param p2 unknown
---@param p3 boolean
---@param p4 boolean
---@param p5 boolean
---@param p6 unknown
function AddVehicleStuckCheckWithWarp(p0, p1, p2, p3, p4, p5, p6) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
function AddVehicleSubtaskAttackCoord(ped, x, y, z) end

---@param ped Ped
---@param ped2 Ped
function AddVehicleSubtaskAttackPed(ped, ped2) end

---@param vehicle integer
function AddVehicleUpsidedownCheck(vehicle) end

---@param hour integer
---@param minute integer
---@param second integer
function AdvanceClockTimeTo(hour, minute, second) end

---@param vehicle integer
function AllowAmbientVehiclesToAvoidAdverseConditions(vehicle) end

---@param toggle boolean
function AllowMissionCreatorWarp(toggle) end

function AllowPauseMenuWhenDeadThisFrame() end

function AllowPlayerSwitchAscent() end

function AllowPlayerSwitchDescent() end

function AllowPlayerSwitchOutro() end

function AllowPlayerSwitchPan() end

---@param toggle boolean
function AllowSonarBlips(toggle) end

---@param cam integer
---@param p1 string
---@param p2 string
---@param p3 string
---@param amplitude number
function AnimatedShakeCam(cam, p1, p2, p3, amplitude) end

---@param p0 string
---@param p1 string
---@param p2 string
---@param p3 number
function AnimatedShakeScriptGlobal(p0, p1, p2, p3) end

---@param p0 number
---@param distance number
function AnimateGameplayCamZoom(p0, distance) end

---@param effectName string
---@return number
function AnimpostfxGetUnk(effectName) end

---@param effectName string
---@return boolean
function AnimpostfxIsRunning(effectName) end

---@param effectName string
---@param duration integer
---@param looped boolean
function AnimpostfxPlay(effectName, duration, looped) end

---@param effectName string
function AnimpostfxStop(effectName) end

function AnimpostfxStopAll() end

---@param effectName string
function AnimpostfxStopAndDoUnk(effectName) end

---@param vehicle integer
---@return boolean
function AnyPassengersRappeling(vehicle) end

function AppClearBlock() end

function AppCloseApp() end

function AppCloseBlock() end

---@return boolean
function AppDataValid() end

---@param appName string
---@return boolean
function AppDeleteAppData(appName) end

---@return integer
function AppGetDeletedFileStatus() end

---@param property string
---@return number
function AppGetFloat(property) end

---@param property string
---@return integer
function AppGetInt(property) end

---@param property string
---@return string
function AppGetString(property) end

---@return boolean
function AppHasLinkedSocialClubAccount() end

---@param appName string
---@return boolean
function AppHasSyncedData(appName) end

---@param ped Ped
---@param damageAmount integer
---@param armorFirst boolean
function ApplyDamageToPed(ped, damageAmount, armorFirst) end

---@param entity Entity
---@param forceType integer
---@param x number
---@param y number
---@param z number
---@param offX number
---@param offY number
---@param offZ number
---@param boneIndex integer
---@param isDirectionRel boolean
---@param ignoreUpVec boolean
---@param isForceRel boolean
---@param p12 boolean
---@param p13 boolean
function ApplyForceToEntity(entity, forceType, x, y, z, offX, offY, offZ, boneIndex, isDirectionRel, ignoreUpVec, isForceRel, p12, p13) end

---@param entity Entity
---@param forceType integer
---@param x number
---@param y number
---@param z number
---@param p5 boolean
---@param isDirectionRel boolean
---@param isForceRel boolean
---@param p8 boolean
function ApplyForceToEntityCenterOfMass(entity, forceType, x, y, z, p5, isDirectionRel, isForceRel, p8) end

---@param posX number
---@param posY number
---@param posZ number
---@param vecX number
---@param vecY number
---@param vecZ number
---@param impulse number
function ApplyImpulseToCloth(posX, posY, posZ, vecX, vecY, vecZ, impulse) end

---@param ped Ped
---@param boneIndex integer
---@param xRot number
---@param yRot number
---@param zRot number
---@param woundType string
function ApplyPedBlood(ped, boneIndex, xRot, yRot, zRot, woundType) end

---@param ped Ped
---@param p1 unknown
---@param p2 number
---@param p3 number
---@return unknown p4
function ApplyPedBloodByZone(ped, p1, p2, p3) end

---@param ped Ped
---@param p1 unknown
---@param p2 number
---@param p3 number
---@param p4 unknown
function ApplyPedBloodDamageByZone(ped, p1, p2, p3, p4) end

---@param ped Ped
---@param component integer
---@param u number
---@param v number
---@param rotation number
---@param scale number
---@param forcedFrame integer
---@param preAge number
---@param bloodName string
function ApplyPedBloodSpecific(ped, component, u, v, rotation, scale, forcedFrame, preAge, bloodName) end

---@param ped Ped
---@param damageZone integer
---@param xOffset number
---@param yOffset number
---@param heading number
---@param scale number
---@param alpha number
---@param variation integer
---@param fadeIn boolean
---@param decalName string
function ApplyPedDamageDecal(ped, damageZone, xOffset, yOffset, heading, scale, alpha, variation, fadeIn, decalName) end

---@param ped Ped
---@param damagePack string
---@param damage number
---@param mult number
function ApplyPedDamagePack(ped, damagePack, damage, mult) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function ApplyPedOverlay(ped, collection, overlay) end

---@param numEntries integer
---@param msPerCycle integer
---@return boolean
function ApplyWeatherCycles(numEntries, msPerCycle) end

function AppSaveData() end

---@param appName string
function AppSetApp(appName) end

---@param blockName string
function AppSetBlock(blockName) end

---@param property string
---@param value number
function AppSetFloat(property, value) end

---@param property string
---@param value integer
function AppSetInt(property, value) end

---@param property string
---@param value string
function AppSetString(property, value) end

---@return boolean
function AreAllNavmeshRegionsLoaded() end

---@param vehicle integer
---@return boolean
function AreAllVehicleWindowsIntact(vehicle) end

---@param vehicle integer
---@return boolean
function AreAnyVehicleSeatsFree(vehicle) end

---@param aircraft integer
---@return boolean
function AreBombBayDoorsOpen(aircraft) end

---@param x number
---@param y number
---@param z number
---@return boolean
function AreCoordsCollidingWithExterior(x, y, z) end

---@param garageHash Hash|string
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p4 unknown
---@return boolean
function AreEntitiesEntirelyInsideGarage(garageHash, p1, p2, p3, p4) end

---@param vehicle integer
---@return boolean
function AreHeliStubWingsDeployed(vehicle) end

---@param timeA integer
---@param timeB integer
---@return boolean
function AreIntegersEqual(timeA, timeB) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return boolean
function AreNodesLoadedForArea(x1, y1, x2, y2) end

---@param vehicle integer
---@return boolean
function AreOutriggerLegsDeployed(vehicle) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return boolean
function ArePathNodesLoadedInArea(x1, y1, x2, y2) end

---@param vehicle integer
---@param checkForZeroHealth boolean
---@return boolean
function ArePlaneControlPanelsIntact(vehicle, checkForZeroHealth) end

---@param plane integer
---@return boolean
function ArePlanePropellersIntact(plane) end

---@param plane integer
---@return boolean
function ArePlaneWingsIntact(plane) end

---@param player integer
---@return boolean
function ArePlayerFlashingStarsAboutToDrop(player) end

---@param player integer
---@return boolean
function ArePlayerStarsGreyedOut(player) end

---@return boolean
function AreProfileSettingsValid() end

---@param plane integer
---@return boolean
function ArePropellersUndamaged(plane) end

---@param string1 string
---@param string2 string
---@return boolean
function AreStringsEqual(string1, string2) end

---@param plane integer
---@return boolean
function AreVehicleWingsIntact(plane) end

---@param value boolean
---@return unknown arrayData
function ArrayValueAddBoolean(value) end

---@param value number
---@return unknown arrayData
function ArrayValueAddFloat(value) end

---@param value integer
---@return unknown arrayData
function ArrayValueAddInteger(value) end

---@return unknown
---@return unknown arrayData
function ArrayValueAddObject() end

---@param value string
---@return unknown arrayData
function ArrayValueAddString(value) end

---@param valueX number
---@param valueY number
---@param valueZ number
---@return unknown arrayData
function ArrayValueAddVector3(valueX, valueY, valueZ) end

---@param arrayIndex integer
---@return boolean
---@return unknown arrayData
function ArrayValueGetBoolean(arrayIndex) end

---@param arrayIndex integer
---@return number
---@return unknown arrayData
function ArrayValueGetFloat(arrayIndex) end

---@param arrayIndex integer
---@return integer
---@return unknown arrayData
function ArrayValueGetInteger(arrayIndex) end

---@param arrayIndex integer
---@return unknown
---@return unknown arrayData
function ArrayValueGetObject(arrayIndex) end

---@return integer
---@return unknown arrayData
function ArrayValueGetSize() end

---@param arrayIndex integer
---@return string
---@return unknown arrayData
function ArrayValueGetString(arrayIndex) end

---@param arrayIndex integer
---@return integer
---@return unknown arrayData
function ArrayValueGetType(arrayIndex) end

---@param arrayIndex integer
---@return vector3
---@return unknown arrayData
function ArrayValueGetVector3(arrayIndex) end

---@param value number
---@return number
function Asin(value) end

---@param ped Ped
---@param targetPed Ped
function AssignPlayerToPed(ped, targetPed) end

function AssistedMovementCloseRoute() end

function AssistedMovementFlushRoute() end

---@param route string
---@return boolean
function AssistedMovementIsRouteLoaded(route) end

---@param dist number
function AssistedMovementOverrideLoadDistanceThisFrame(dist) end

---@param route string
function AssistedMovementRemoveRoute(route) end

---@param route string
function AssistedMovementRequestRoute(route) end

---@param route string
---@param props integer
function AssistedMovementSetRouteProperties(route, props) end

---@param p0 number
---@return number
function Atan(p0) end

---@param p0 number
---@param p1 number
---@return number
function Atan2(p0, p1) end

---@param cam integer
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param isRelative boolean
function AttachCamToEntity(cam, entity, xOffset, yOffset, zOffset, isRelative) end

---@param cam integer
---@param ped Ped
---@param boneIndex integer
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param isRelative boolean
function AttachCamToPedBone(cam, ped, boneIndex, xOffset, yOffset, zOffset, isRelative) end

---@param cam integer
---@param ped Ped
---@param boneIndex integer
---@param xRot number
---@param yRot number
---@param zRot number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param isRelative boolean
function AttachCamToPedBone_2(cam, ped, boneIndex, xRot, yRot, zRot, xOffset, yOffset, zOffset, isRelative) end

---@param cam integer
---@param vehicle integer
---@param boneIndex integer
---@param relativeRotation boolean
---@param rotX number
---@param rotY number
---@param rotZ number
---@param offX number
---@param offY number
---@param offZ number
---@param fixedDirection boolean
function AttachCamToVehicleBone(cam, vehicle, boneIndex, relativeRotation, rotX, rotY, rotZ, offX, offY, offZ, fixedDirection) end

---@param handler integer
---@param container Entity
function AttachContainerToHandlerFrame(handler, container) end

---@param ropeId integer
---@param ent1 Entity
---@param ent2 Entity
---@param ent1_x number
---@param ent1_y number
---@param ent1_z number
---@param ent2_x number
---@param ent2_y number
---@param ent2_z number
---@param length number
---@param p10 boolean
---@param p11 boolean
---@param boneName1 string
---@param boneName2 string
function AttachEntitiesToRope(ropeId, ent1, ent2, ent1_x, ent1_y, ent1_z, ent2_x, ent2_y, ent2_z, length, p10, p11, boneName1, boneName2) end

---@param entity1 Entity
---@param entity2 Entity
---@param entityBone integer
---@param entityBone2 integer
---@param p4 boolean
---@param p5 boolean
function AttachEntityBoneToEntityBone(entity1, entity2, entityBone, entityBone2, p4, p5) end

---@param entity1 Entity
---@param entity2 Entity
---@param entityBone integer
---@param entityBone2 integer
---@param p4 boolean
---@param p5 boolean
function AttachEntityBoneToEntityBonePhysically(entity1, entity2, entityBone, entityBone2, p4, p5) end

---@param vehicle integer
---@param entity Entity
---@param p2 integer
---@param x number
---@param y number
---@param z number
function AttachEntityToCargobob(vehicle, entity, p2, x, y, z) end

---@param entity1 Entity
---@param entity2 Entity
---@param boneIndex integer
---@param xPos number
---@param yPos number
---@param zPos number
---@param xRot number
---@param yRot number
---@param zRot number
---@param p9 boolean
---@param useSoftPinning boolean
---@param collision boolean
---@param isPed boolean
---@param rotationOrder integer
---@param syncRot boolean
function AttachEntityToEntity(entity1, entity2, boneIndex, xPos, yPos, zPos, xRot, yRot, zRot, p9, useSoftPinning, collision, isPed, rotationOrder, syncRot) end

---@param entity1 Entity
---@param entity2 Entity
---@param boneIndex1 integer
---@param boneIndex2 integer
---@param xPos1 number
---@param yPos1 number
---@param zPos1 number
---@param xPos2 number
---@param yPos2 number
---@param zPos2 number
---@param xRot number
---@param yRot number
---@param zRot number
---@param breakForce number
---@param fixedRot boolean
---@param p15 boolean
---@param collision boolean
---@param teleport boolean
---@param p18 integer
function AttachEntityToEntityPhysically(entity1, entity2, boneIndex1, boneIndex2, xPos1, yPos1, zPos1, xPos2, yPos2, zPos2, xRot, yRot, zRot, breakForce, fixedRot, p15, collision, teleport, p18) end

---@param pickupObject integer
---@param ped Ped
function AttachPortablePickupToPed(pickupObject, ped) end

---@param ropeId integer
---@param entity Entity
---@param x number
---@param y number
---@param z number
---@param p5 boolean
function AttachRopeToEntity(ropeId, entity, x, y, z, p5) end

---@param sceneID integer
---@param entity Entity
---@param boneIndex integer
function AttachSynchronizedSceneToEntity(sceneID, entity, boneIndex) end

---@param entity Entity
function AttachTvAudioToEntity(entity) end

---@param vehicle integer
---@param trailer integer
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param coordsX number
---@param coordsY number
---@param coordsZ number
---@param rotationX number
---@param rotationY number
---@param rotationZ number
---@param disableColls number
function AttachVehicleOnToTrailer(vehicle, trailer, offsetX, offsetY, offsetZ, coordsX, coordsY, coordsZ, rotationX, rotationY, rotationZ, disableColls) end

---@param cargobob integer
---@param vehicle integer
---@param vehicleBoneIndex integer
---@param x number
---@param y number
---@param z number
function AttachVehicleToCargobob(cargobob, vehicle, vehicleBoneIndex, x, y, z) end

---@param towTruck integer
---@param vehicle integer
---@param rear boolean
---@param hookOffsetX number
---@param hookOffsetY number
---@param hookOffsetZ number
function AttachVehicleToTowTruck(towTruck, vehicle, rear, hookOffsetX, hookOffsetY, hookOffsetZ) end

---@param vehicle integer
---@param trailer integer
---@param radius number
function AttachVehicleToTrailer(vehicle, trailer, radius) end

---@return boolean
function AudioIsScriptedMusicPlaying() end

---@param event integer
---@param amountReceived integer
---@return boolean
---@return integer networkHandle
function BadSportPlayerLeftDetected(event, amountReceived) end

function BeginEnumeratingThreads() end

---@param p0 unknown
---@param p1 unknown
function BeginReplayStats(p0, p1) end

---@param scaleform integer
---@param methodName string
---@return boolean
function BeginScaleformMovieMethod(scaleform, methodName) end

---@param hudComponent integer
---@param methodName string
---@return boolean
function BeginScaleformMovieMethodHudComponent(hudComponent, methodName) end

---@param functionName string
---@return boolean
function BeginScaleformMovieMethodN(functionName) end

---@param functionName string
---@return boolean
function BeginScaleformMovieMethodOnFrontend(functionName) end

---@param functionName string
---@return boolean
function BeginScaleformMovieMethodOnFrontendHeader(functionName) end

---@param functionName string
---@return boolean
function BeginScaleformMovieMethodV(functionName) end

---@param hudComponent integer
---@param methodName string
---@return boolean
function BeginScaleformScriptHudMovieMethod(hudComponent, methodName) end

function BeginSrl() end

---@return boolean
function BeginTakeHighQualityPhoto() end

---@return boolean
function BeginTakeMissionCreatorPhoto() end

---@param string string
function BeginTextCommandBusyspinnerOn(string) end

---@param string string
function BeginTextCommandBusyString(string) end

---@param text string
function BeginTextCommandClearPrint(text) end

---@param inputType string
function BeginTextCommandDisplayHelp(inputType) end

---@param text string
function BeginTextCommandDisplayText(text) end

---@param text string
function BeginTextCommandGetWidth(text) end

---@param text string
function BeginTextCommandIsMessageDisplayed(text) end

---@param labelName string
function BeginTextCommandIsThisHelpMessageBeingDisplayed(labelName) end

---@param entry string
function BeginTextCommandLineCount(entry) end

---@param p0 string
function BeginTextCommandObjective(p0) end

---@param gxtEntry string
function BeginTextCommandOverrideButtonText(gxtEntry) end

---@param GxtEntry string
function BeginTextCommandPrint(GxtEntry) end

---@param textLabel string
function BeginTextCommandScaleformString(textLabel) end

---@param textLabel string
function BeginTextCommandSetBlipName(textLabel) end

---@param text string
function BeginTextCommandThefeedPost(text) end

---@param gxtEntry string
function BeginTextCommandTimer(gxtEntry) end

---@param text string
function BeginTextCommandWidth(text) end

---@param textLabel string
function BeginTextComponent(textLabel) end

---@param contextName string
function BgEndContext(contextName) end

---@param contextHash Hash|string
function BgEndContextHash(contextHash) end

---@param contextName string
function BgStartContext(contextName) end

---@param contextHash Hash|string
function BgStartContextHash(contextHash) end

---@param vehicle integer
function BlipSiren(vehicle) end

---@param ped Ped
---@param shouldBlock boolean
---@param suppressOutgoingNetworkSpeech boolean
function BlockAllSpeechFromPed(ped, shouldBlock, suppressOutgoingNetworkSpeech) end

---@param blocked boolean
function BlockDeathJingle(blocked) end

---@param name Hash|string
---@param eventType integer
function BlockDecisionMakerEvent(name, eventType) end

---@param dispatchService integer
---@param toggle boolean
function BlockDispatchServiceResourceCreation(dispatchService, toggle) end

---@param ped Ped
---@param toggle boolean
function BlockPedDeadBodyShockingEvents(ped, toggle) end

---@param groupName string
---@param contextBlockTarget integer
function BlockSpeechContextGroup(groupName, contextBlockTarget) end

function BlockWeaponWheelThisFrame() end

---@param entity Entity
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 number
---@param p9 unknown
---@param p10 boolean
function BreakEntityGlass(entity, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) end

---@param p0 integer
---@param p1 unknown
---@param p2 boolean
function BreakObjectFragmentChild(p0, p1, p2) end

---@param vehicle integer
---@param wheelIndex integer
---@param leaveDebrisTrail boolean
---@param deleteWheel boolean
---@param unknownFlag boolean
---@param putOnFire boolean
function BreakOffVehicleWheel(vehicle, wheelIndex, leaveDebrisTrail, deleteWheel, unknownFlag, putOnFire) end

---@param vehicle integer
---@param distance number
---@param duration integer
---@param bControlVerticalVelocity boolean
function BringVehicleToHalt(vehicle, distance, duration, bControlVerticalVelocity) end

---@return boolean
function BusyspinnerIsDisplaying() end

---@return boolean
function BusyspinnerIsOn() end

function BusyspinnerOff() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function CalculateTravelDistanceBetweenPoints(x1, y1, z1, x2, y2, z2) end

---@param miniMap integer
---@param fnName string
---@return boolean
function CallMinimapScaleformFunction(miniMap, fnName) end

---@param scaleform integer
---@param methodName string
---@param param1 number
---@param param2 number
---@param param3 number
---@param param4 number
---@param param5 number
function CallScaleformMovieFunctionFloatParams(scaleform, methodName, param1, param2, param3, param4, param5) end

---@param scaleform integer
---@param methodName string
---@param floatParam1 number
---@param floatParam2 number
---@param floatParam3 number
---@param floatParam4 number
---@param floatParam5 number
---@param stringParam1 string
---@param stringParam2 string
---@param stringParam3 string
---@param stringParam4 string
---@param stringParam5 string
function CallScaleformMovieFunctionMixedParams(scaleform, methodName, floatParam1, floatParam2, floatParam3, floatParam4, floatParam5, stringParam1, stringParam2, stringParam3, stringParam4, stringParam5) end

---@param scaleform integer
---@param methodName string
---@param param1 string
---@param param2 string
---@param param3 string
---@param param4 string
---@param param5 string
function CallScaleformMovieFunctionStringParams(scaleform, methodName, param1, param2, param3, param4, param5) end

---@param scaleform integer
---@param method string
function CallScaleformMovieFunctionVoid(scaleform, method) end

---@param scaleform integer
---@param method string
function CallScaleformMovieMethod(scaleform, method) end

---@param scaleform integer
---@param methodName string
---@param param1 number
---@param param2 number
---@param param3 number
---@param param4 number
---@param param5 number
function CallScaleformMovieMethodWithNumber(scaleform, methodName, param1, param2, param3, param4, param5) end

---@param scaleform integer
---@param methodName string
---@param floatParam1 number
---@param floatParam2 number
---@param floatParam3 number
---@param floatParam4 number
---@param floatParam5 number
---@param stringParam1 string
---@param stringParam2 string
---@param stringParam3 string
---@param stringParam4 string
---@param stringParam5 string
function CallScaleformMovieMethodWithNumberAndString(scaleform, methodName, floatParam1, floatParam2, floatParam3, floatParam4, floatParam5, stringParam1, stringParam2, stringParam3, stringParam4, stringParam5) end

---@param scaleform integer
---@param methodName string
---@param param1 string
---@param param2 string
---@param param3 string
---@param param4 string
---@param param5 string
function CallScaleformMovieMethodWithString(scaleform, methodName, param1, param2, param3, param4, param5) end

---@param boat integer
---@return boolean
function CanAnchorBoatHere(boat) end

---@param boat integer
---@return boolean
function CanAnchorBoatHere_2(boat) end

---@param boat integer
---@return boolean
function CanAnchorBoatHereIgnorePlayers(boat) end

---@param boat integer
---@return boolean
function CanBoatBeAnchored(boat) end

---@param boat integer
---@return boolean
function CanBoatBeAnchored_2(boat) end

---@param cargobob integer
---@param entity Entity
---@return boolean
function CanCargobobPickUpEntity(cargobob, entity) end

function CancelAllPoliceReports() end

function CancelCurrentPoliceReport() end

---@param eventName string
---@return boolean
function CancelMusicEvent(eventName) end

function CancelOnscreenKeyboard() end

function CancelStuntJump() end

---@return boolean
function CanCreateRandomBikeRider() end

---@return boolean
function CanCreateRandomCops() end

---@return boolean
function CanCreateRandomDriver() end

---@param unk boolean
---@return boolean
function CanCreateRandomPed(unk) end

---@param ped Ped
---@return boolean
function CanKnockPedOffVehicle(ped) end

---@return boolean
function CanPayGoon() end

---@param player integer
---@param ped Ped
---@return boolean
function CanPedHearPlayer(player, ped) end

---@param ped Ped
---@param target Ped
---@return boolean
function CanPedInCombatSeeTarget(ped, target) end

---@param ped Ped
---@return boolean
function CanPedRagdoll(ped) end

---@param ped1 Ped
---@param ped2 Ped
---@return boolean
function CanPedSeeHatedPed(ped1, ped2) end

---@param ped1 Ped
---@param ped2 Ped
---@return boolean
function CanPedSeePed(ped1, ped2) end

---@param ped Ped
---@param speechName string
---@param allowBackupPVGs boolean
---@return boolean
function CanPedSpeak(ped, speechName, allowBackupPVGs) end

---@return boolean
function CanPhoneBeSeenOnScreen() end

---@param player integer
---@return boolean
function CanPlayerStartMission(player) end

---@return boolean
function CanPlayOnline() end

---@param ped_amt integer
---@param vehicle_amt integer
---@param object_amt integer
---@param pickup_amt integer
---@return boolean
function CanRegisterMissionEntities(ped_amt, vehicle_amt, object_amt, pickup_amt) end

---@param amount integer
---@return boolean
function CanRegisterMissionObjects(amount) end

---@param amount integer
---@return boolean
function CanRegisterMissionPeds(amount) end

---@param amount integer
---@return boolean
function CanRegisterMissionPickups(amount) end

---@param amount integer
---@return boolean
function CanRegisterMissionVehicles(amount) end

---@return boolean
function CanRequestAssetsForCutsceneEntity() end

---@param cutsceneEntName string
---@param modelHash Hash|string
---@return boolean
function CanSetEnterStateForRegisteredEntity(cutsceneEntName, modelHash) end

---@param p0 boolean
---@return boolean
function CanSetExitStateForCamera(p0) end

---@param cutsceneEntName string
---@param modelHash Hash|string
---@return boolean
function CanSetExitStateForRegisteredEntity(cutsceneEntName, modelHash) end

---@param vehicle integer
---@param seatIndex integer
---@return boolean
function CanShuffleSeat(vehicle, seatIndex) end

---@param weaponHash Hash|string
---@return boolean
function CanUseWeaponOnParachute(weaponHash) end

---@param vehicle integer
---@return boolean
function CanVehicleParachuteBeActivated(vehicle) end

---@param vehicle integer
---@return boolean
function CanVehicleReceiveCbRadio(vehicle) end

---@param interiorID integer
---@param toggle boolean
function CapInterior(interiorID, toggle) end

---@param cargobob integer
---@param isActive boolean
function CargobobMagnetGrabVehicle(cargobob, isActive) end

function CascadeShadowsClearShadowSampleType() end

---@param toggle boolean
function CascadeShadowsEnableEntityTracker(toggle) end

function CascadeShadowsInitSession() end

function CascadeshadowsResetType() end

---@param p0 boolean
function CascadeShadowsSetAircraftMode(p0) end

---@param p0 unknown
---@param p1 boolean
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 boolean
---@param p7 number
function CascadeShadowsSetCascadeBounds(p0, p1, p2, p3, p4, p5, p6, p7) end

---@param p0 number
function CascadeShadowsSetCascadeBoundsScale(p0) end

---@param p0 boolean
function CascadeShadowsSetDynamicDepthMode(p0) end

---@param p0 number
function CascadeShadowsSetDynamicDepthValue(p0) end

---@param p0 number
function CascadeShadowsSetEntityTrackerScale(p0) end

---@param type string
function CascadeShadowsSetShadowSampleType(type) end

---@param type string
function CascadeshadowsSetType(type) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number
---@param flags integer
---@param entity Entity
---@param p9 integer
---@return integer
function Cast_3dRayPointToPoint(x1, y1, z1, x2, y2, z2, radius, flags, entity, p9) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param flags integer
---@param entity Entity
---@param p8 integer
---@return integer
function CastRayPointToPoint(x1, y1, z1, x2, y2, z2, flags, entity, p8) end

---@param value number
---@return integer
function Ceil(value) end

---@param active boolean
---@param bGoFirstPerson boolean
function CellCamActivate(active, bGoFirstPerson) end

---@param toggle boolean
function CellCamActivateSelfieMode(toggle) end

---@param toggle boolean
function CellCamDisableThisFrame(toggle) end

---@param entity Entity
---@return boolean
function CellCamIsCharVisibleNoFaceCheck(entity) end

---@param direction integer
function CellCamMoveFinger(direction) end

---@param p0 number
function CellCamSetDistance(p0) end

---@param p0 number
function CellCamSetHeadHeight(p0) end

---@param p0 number
function CellCamSetHeadPitch(p0) end

---@param p0 number
function CellCamSetHeadRoll(p0) end

---@param p0 number
function CellCamSetHorizontalOffset(p0) end

---@param toggle boolean
function CellCamSetLean(toggle) end

---@param p0 number
function CellCamSetRoll(p0) end

---@param p0 number
function CellCamSetVerticalOffset(p0) end

function CenterPlayerOnRadarThisFrame() end

---@param cash integer
---@param bank integer
function ChangeFakeMpCash(cash, bank) end

---@param player integer
---@param ped Ped
---@param b2 boolean
---@param resetDamage boolean
function ChangePlayerPed(player, ped, b2, resetDamage) end

---@param minimum number
---@param maximum number
function ClampGameplayCamPitch(minimum, maximum) end

---@param minimum number
---@param maximum number
function ClampGameplayCamYaw(minimum, maximum) end

---@param p0 unknown
function CleanItemset(p0) end

function CleanupAsyncInstall() end

---@param p0 integer
---@param p1 boolean
function ClearAdditionalText(p0, p1) end

function ClearAllBlipRoutes() end

function ClearAllBrokenGlass() end

function ClearAllHelpMessages() end

---@param ped Ped
function ClearAllPedProps(ped) end

---@param ped Ped
function ClearAllPedVehicleForcedSeatUsage(ped) end

---@param zoneListName string
---@param forceUpdate boolean
function ClearAmbientZoneListState(zoneListName, forceUpdate) end

---@param zoneName string
---@param forceUpdate boolean
function ClearAmbientZoneState(zoneName, forceUpdate) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param p7 boolean
---@param p8 boolean
---@param p9 boolean
---@param p10 boolean
---@param p11 boolean
function ClearAngledAreaOfVehicles(x1, y1, z1, x2, y2, z2, width, p7, p8, p9, p10, p11) end

---@param X number
---@param Y number
---@param Z number
---@param radius number
---@param p4 boolean
---@param ignoreCopCars boolean
---@param ignoreObjects boolean
---@param p7 boolean
function ClearArea(X, Y, Z, radius, p4, ignoreCopCars, ignoreObjects, p7) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 boolean
---@param p5 boolean
---@param p6 boolean
---@param p7 boolean
function ClearAreaLeaveVehicleHealth(x, y, z, radius, p4, p5, p6, p7) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param createNetEvent boolean
function ClearAreaOfCops(x, y, z, radius, createNetEvent) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 boolean
---@param p5 boolean
---@param p6 boolean
---@param p7 boolean
function ClearAreaOfEverything(x, y, z, radius, p4, p5, p6, p7) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param flags integer
function ClearAreaOfObjects(x, y, z, radius, flags) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param createNetEvent boolean
function ClearAreaOfPeds(x, y, z, radius, createNetEvent) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param createNetEvent boolean
function ClearAreaOfProjectiles(x, y, z, radius, createNetEvent) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 boolean
---@param p5 boolean
---@param p6 boolean
---@param p7 boolean
---@param p8 boolean
function ClearAreaOfVehicles(x, y, z, radius, p4, p5, p6, p7, p8) end

---@param offset integer
---@return integer address
function ClearBit(offset) end

function ClearBrief() end

function ClearCloudHat() end

---@param radioStation string
function ClearCustomRadioTrackList(radioStation) end

---@param name Hash|string
---@param eventType integer
function ClearDecisionMakerEventResponse(name, eventType) end

function ClearDrawOrigin() end

---@param ped Ped
function ClearDrivebyTaskUnderneathDrivingTask(ped) end

function ClearDynamicPauseMenuErrorMessage() end

---@param entity Entity
function ClearEntityLastDamageEntity(entity) end

---@param entity Entity
function ClearEntityLastWeaponDamage(entity) end

function ClearExtraTimecycleModifier() end

---@param ped Ped
function ClearFacialClipsetOverride(ped) end

---@param ped Ped
function ClearFacialIdleAnimOverride(ped) end

---@param hudIndex integer
---@param p1 boolean
function ClearFloatingHelp(hudIndex, p1) end

function ClearFocus() end

---@param garageHash Hash|string
---@param isNetwork boolean
function ClearGarageArea(garageHash, isNetwork) end

function ClearGpsCustomRoute() end

---@param index integer
function ClearGpsDisabledZoneAtIndex(index) end

function ClearGpsFlags() end

function ClearGpsMultiRoute() end

function ClearGpsPlayerWaypoint() end

function ClearGpsRaceTrack() end

function ClearHdArea() end

---@param toggle boolean
function ClearHelp(toggle) end

---@param entity Entity
function ClearInteriorForEntity(entity) end

function ClearLastDrivenVehicle() end

function ClearLaunchParams() end

---@param vehicle integer
function ClearNitrous(vehicle) end

---@param pos number
function ClearNotificationsPos(pos) end

---@param garageHash Hash|string
---@param vehicles boolean
---@param peds boolean
---@param objects boolean
---@param isNetwork boolean
function ClearObjectsInsideGarage(garageHash, vehicles, peds, objects, isNetwork) end

function ClearOverrideWeather() end

---@param ped Ped
---@param stance integer
---@param p2 number
function ClearPedAlternateMovementAnim(ped, stance, p2) end

---@param ped Ped
---@param p1 number
function ClearPedAlternateWalkAnim(ped, p1) end

---@param ped Ped
function ClearPedBloodDamage(ped) end

---@param ped Ped
---@param p1 integer
function ClearPedBloodDamageByZone(ped, p1) end

---@param ped Ped
function ClearPedCoverClipsetOverride(ped) end

---@param ped Ped
---@param p1 integer
---@param p2 string
function ClearPedDamageDecalByZone(ped, p1, p2) end

---@param ped Ped
function ClearPedDecorations(ped) end

---@param ped Ped
function ClearPedDecorationsLeaveScars(ped) end

---@param ped Ped
function ClearPedDriveByClipsetOverride(ped) end

---@param ped Ped
function ClearPedEnvDirt(ped) end

---@param ped Ped
function ClearPedFacialDecorations(ped) end

function ClearPedInPauseMenu() end

---@param ped Ped
function ClearPedLastDamageBone(ped) end

---@param ped Ped
function ClearPedLastWeaponDamage(ped) end

function ClearPedNonCreationArea() end

---@param ped Ped
function ClearPedParachutePackVariation(ped) end

---@param ped Ped
---@param propId integer
function ClearPedProp(ped, propId) end

---@param ped Ped
function ClearPedScubaGearVariation(ped) end

---@param ped Ped
function ClearPedSecondaryTask(ped) end

---@param ped Ped
function ClearPedStoredHatProp(ped) end

---@param ped Ped
function ClearPedTasks(ped) end

---@param ped Ped
function ClearPedTasksImmediately(ped) end

---@param ped Ped
function ClearPedWetness(ped) end

---@param player integer
function ClearPlayerHasDamagedAtLeastOneNonAnimalPed(player) end

---@param player integer
function ClearPlayerHasDamagedAtLeastOnePed(player) end

---@param player integer
function ClearPlayerParachuteModelOverride(player) end

---@param player integer
function ClearPlayerParachutePackModelOverride(player) end

---@param player integer
function ClearPlayerParachuteVariationOverride(player) end

---@param player integer
function ClearPlayerReserveParachuteModelOverride(player) end

---@param player integer
function ClearPlayerWantedLevel(player) end

---@param scheduleId integer
function ClearPopscheduleOverrideVehicleModel(scheduleId) end

function ClearPrints() end

function ClearRaceGalleryBlips() end

---@param ped Ped
---@param flags integer
function ClearRagdollBlockingFlags(ped, flags) end

---@param relationship integer
---@param group1 Hash|string
---@param group2 Hash|string
function ClearRelationshipBetweenGroups(relationship, group1, group2) end

function ClearReminderMessage() end

function ClearReplayStats() end

function ClearRestartCustomPosition() end

---@param entity Entity
function ClearRoomForEntity(entity) end

function ClearRoomForGameViewport() end

---@return integer taskSequenceId
function ClearSequenceTask() end

function ClearSmallPrints() end

function ClearTacticalAnalysisPoints() end

---@param p0 string
function ClearThisPrint(p0) end

function ClearTimecycleModifier() end

---@param tvChannel integer
function ClearTvChannelPlaylist(tvChannel) end

---@param vehicle integer
function ClearVehicleCustomPrimaryColour(vehicle) end

---@param vehicle integer
function ClearVehicleCustomSecondaryColour(vehicle) end

function ClearVehicleGeneratorAreaOfInterest() end

function ClearVehiclePhoneExplosiveDevice() end

---@param vehicle integer
function ClearVehicleRouteHistory(vehicle) end

---@param vehicle integer
function ClearVehicleTasks(vehicle) end

---@param vehicle integer
function ClearVehicleXenonLightsCustomColor(vehicle) end

---@param transitionTimeInMs integer
function ClearWeatherTypeNowPersistNetwork(transitionTimeInMs) end

function ClearWeatherTypePersist() end

---@param ped Ped
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@param copyHeadBlendFlag boolean
---@return Ped
function ClonePed(ped, isNetwork, bScriptHostPed, copyHeadBlendFlag) end

---@param ped Ped
---@param heading number
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@param p4 unknown
---@return Ped
function ClonePed_2(ped, heading, isNetwork, bScriptHostPed, p4) end

---@param ped Ped
---@param heading number
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@param p4 unknown
---@return Ped
function ClonePedEx(ped, heading, isNetwork, bScriptHostPed, p4) end

---@param ped Ped
---@param targetPed Ped
function ClonePedToTarget(ped, targetPed) end

---@param ped Ped
---@param targetPed Ped
---@param p2 unknown
function ClonePedToTargetEx(ped, targetPed, p2) end

---@param sourceModifierName string
---@param clonedModifierName string
---@return integer
function CloneTimecycleModifier(sourceModifierName, clonedModifierName) end

---@param vehicle integer
function CloseBombBayDoors(vehicle) end

function CloseMultiplayerChat() end

function ClosePatrolRoute() end

---@param taskSequenceId integer
function CloseSequenceTask(taskSequenceId) end

function CloseSocialClubMenu() end

function CloudCheckAvailability() end

---@param p0 string
---@return integer
function CloudDeleteMemberFile(p0) end

---@param handle integer
---@return boolean
function CloudDidRequestSucceed(handle) end

---@return boolean
function CloudGetAvailabilityCheckResult() end

---@param handle integer
---@return boolean
function CloudHasRequestCompleted(handle) end

---@return boolean
function CloudIsCheckingAvailability() end

---@param tex integer
function CommitRuntimeTexture(tex) end

---@param str1 string
---@param str2 string
---@param matchCase boolean
---@param maxLength integer
---@return integer
function CompareStrings(str1, str2, matchCase, maxLength) end

---@param vehicle integer
---@param state integer
function ControlLandingGear(vehicle, state) end

---@param ped Ped
---@return boolean
function ControlMountedWeapon(ped) end

---@param posixTime integer
---@return unknown timeStructure
function ConvertPosixTime(posixTime) end

---@param src unknown
---@param size integer
---@return unknown dst
function CopyMemory(src, size) end

---@param sourceVehicle integer
---@param targetVehicle integer
function CopyVehicleDamages(sourceVehicle, targetVehicle) end

---@param value number
---@return number
function Cos(value) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 number
---@param p9 number
---@param weaponHash Hash|string
---@return integer
function CreateAirDefenseArea(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, weaponHash) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 number
---@param p5 number
---@param p6 number
---@param weaponHash Hash|string
---@return integer
function CreateAirDefenseSphere(x, y, z, radius, p4, p5, p6, weaponHash) end

---@param pickupHash Hash|string
---@param posX number
---@param posY number
---@param posZ number
---@param flags integer
---@param value integer
---@param modelHash Hash|string
---@param returnHandle boolean
---@param p8 boolean
---@return integer
function CreateAmbientPickup(pickupHash, posX, posY, posZ, flags, value, modelHash, returnHandle, p8) end

---@param name string
---@return integer
function CreateAudioSubmix(name) end

---@param camName string
---@param active boolean
---@return integer
function CreateCam(camName, active) end

---@param camHash Hash|string
---@param active boolean
---@return integer
function CreateCamera(camHash, active) end

---@param camHash Hash|string
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param fov number
---@param active boolean
---@param rotationOrder integer
---@return integer
function CreateCameraWithParams(camHash, posX, posY, posZ, rotX, rotY, rotZ, fov, active, rotationOrder) end

---@param camName string
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param fov number
---@param active boolean
---@param rotationOrder integer
---@return integer
function CreateCamWithParams(camName, posX, posY, posZ, rotX, rotY, rotZ, fov, active, rotationOrder) end

---@param type integer
---@param posX1 number
---@param posY1 number
---@param posZ1 number
---@param posX2 number
---@param posY2 number
---@param posZ2 number
---@param diameter number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param reserved integer
---@return integer
function CreateCheckpoint(type, posX1, posY1, posZ1, posX2, posY2, posZ2, diameter, red, green, blue, alpha, reserved) end

---@param p0 unknown
---@param p1 integer
---@param p2 unknown
---@param entity Entity
function CreateCinematicShot(p0, p1, p2, entity) end

---@param xMin number
---@param yMin number
---@param zMin number
---@param xMax number
---@param yMax number
---@param zMax number
---@return integer
function CreateDryVolume(xMin, yMin, zMin, xMax, yMax, zMax) end

---@param url string
---@param width integer
---@param height integer
---@return integer
function CreateDui(url, width, height) end

---@param ped Ped
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@return integer
function CreateFakeMpGamerTag(ped, username, crewIsPrivate, crewIsRockstar, crewName, crewRank) end

---@param x number
---@param y number
---@param z number
---@param p3 unknown
---@param modelHash Hash|string
---@param p5 boolean
function CreateForcedObject(x, y, z, p3, modelHash, p5) end

---@param unused integer
---@return integer
function CreateGroup(unused) end

---@param dispatchService integer
---@param x number
---@param y number
---@param z number
---@param numUnits integer
---@param radius number
---@return boolean
---@return integer outIncidentID
function CreateIncident(dispatchService, x, y, z, numUnits, radius) end

---@param dispatchService integer
---@param ped Ped
---@param numUnits integer
---@param radius number
---@return boolean
---@return integer outIncidentID
function CreateIncidentWithEntity(dispatchService, ped, numUnits, radius) end

---@param distri boolean
---@return integer
function CreateItemset(distri) end

function CreateLightningThunder() end

---@param variation integer
---@param x number
---@param y number
---@param z number
---@param direction boolean
---@return integer
function CreateMissionTrain(variation, x, y, z, direction) end

---@param phoneType integer
function CreateMobilePhone(phoneType) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param model Hash|string
---@param p5 boolean
function CreateModelHide(x, y, z, radius, model, p5) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param model Hash|string
---@param p5 boolean
function CreateModelHideExcludingScriptObjects(x, y, z, radius, model, p5) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param originalModel Hash|string
---@param newModel Hash|string
---@param p6 boolean
function CreateModelSwap(x, y, z, radius, originalModel, newModel, p6) end

---@param x number
---@param y number
---@param z number
---@param value integer
---@param amount integer
---@param model Hash|string
function CreateMoneyPickups(x, y, z, value, amount, model) end

---@param ped Ped
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@return integer
function CreateMpGamerTag(ped, username, crewIsPrivate, crewIsRockstar, crewName, crewRank) end

---@param player integer
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@param crewR integer
---@param crewG integer
---@param crewB integer
function CreateMpGamerTagColor(player, username, crewIsPrivate, crewIsRockstar, crewName, crewRank, crewR, crewG, crewB) end

---@param player integer
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@param crewR integer
---@param crewG integer
---@param crewB integer
function CreateMpGamerTagForNetPlayer(player, username, crewIsPrivate, crewIsRockstar, crewName, crewRank, crewR, crewG, crewB) end

---@param player integer
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@param crewR integer
---@param crewG integer
---@param crewB integer
function CreateMpGamerTagWithCrewColor(player, username, crewIsPrivate, crewIsRockstar, crewName, crewRank, crewR, crewG, crewB) end

function CreateNewScriptedConversation() end

---@param startImmediately boolean
---@param messageId integer
function CreateNmMessage(startImmediately, messageId) end

---@param pickupHash unknown
---@param posX number
---@param posY number
---@param posZ number
---@param flags integer
---@param value integer
---@param modelHash unknown
---@param p7 boolean
---@param p8 boolean
---@return unknown
function CreateNonNetworkedAmbientPickup(pickupHash, posX, posY, posZ, flags, value, modelHash, p7, p8) end

---@param pickupHash Hash|string
---@param x number
---@param y number
---@param z number
---@param placeOnGround boolean
---@param modelHash Hash|string
---@return integer
function CreateNonNetworkedPortablePickup(pickupHash, x, y, z, placeOnGround, modelHash) end

---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param isNetwork boolean
---@param netMissionEntity boolean
---@param doorFlag boolean
---@return integer
function CreateObject(modelHash, x, y, z, isNetwork, netMissionEntity, doorFlag) end

---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param isNetwork boolean
---@param netMissionEntity boolean
---@param doorFlag boolean
---@return integer
function CreateObjectNoOffset(modelHash, x, y, z, isNetwork, netMissionEntity, doorFlag) end

---@param ped Ped
---@param p1 boolean
---@param p2 boolean
---@return integer
function CreateParachuteBagObject(ped, p1, p2) end

---@param ped Ped
---@param p1 boolean
---@param p2 boolean
---@return integer
function CreateParachuteObject(ped, p1, p2) end

function CreatePatrolRoute() end

---@param pedType integer
---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param heading number
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@return Ped
function CreatePed(pedType, modelHash, x, y, z, heading, isNetwork, bScriptHostPed) end

---@param vehicle integer
---@param pedType integer
---@param modelHash Hash|string
---@param seat integer
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@return Ped
function CreatePedInsideVehicle(vehicle, pedType, modelHash, seat, isNetwork, bScriptHostPed) end

---@param pickupHash Hash|string
---@param posX number
---@param posY number
---@param posZ number
---@param p4 integer
---@param value integer
---@param p6 boolean
---@param modelHash Hash|string
---@return integer
function CreatePickup(pickupHash, posX, posY, posZ, p4, value, p6, modelHash) end

---@param cargobob integer
---@param state integer
function CreatePickUpRopeForCargobob(cargobob, state) end

---@param pickupHash Hash|string
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param flag integer
---@param amount integer
---@param p9 unknown
---@param p10 boolean
---@param modelHash Hash|string
---@return integer
function CreatePickupRotate(pickupHash, posX, posY, posZ, rotX, rotY, rotZ, flag, amount, p9, p10, modelHash) end

---@param pickupHash Hash|string
---@param x number
---@param y number
---@param z number
---@param placeOnGround boolean
---@param modelHash Hash|string
---@return integer
function CreatePortablePickup(pickupHash, x, y, z, placeOnGround, modelHash) end

---@param pickupHash Hash|string
---@param x number
---@param y number
---@param z number
---@param placeOnGround boolean
---@param modelHash Hash|string
---@return integer
function CreatePortablePickup_2(pickupHash, x, y, z, placeOnGround, modelHash) end

---@param posX number
---@param posY number
---@param posZ number
---@return Ped
function CreateRandomPed(posX, posY, posZ) end

---@param vehicle integer
---@param returnHandle boolean
---@return Ped
function CreateRandomPedAsDriver(vehicle, returnHandle) end

---@param txd integer
---@param txn string
---@param width integer
---@param height integer
---@return integer
function CreateRuntimeTexture(txd, txn, width, height) end

---@param txd integer
---@param txn string
---@param duiHandle string
---@return integer
function CreateRuntimeTextureFromDuiHandle(txd, txn, duiHandle) end

---@param txd integer
---@param txn string
---@param fileName string
---@return integer
function CreateRuntimeTextureFromImage(txd, txn, fileName) end

---@param name string
---@return integer
function CreateRuntimeTxd(name) end

---@param x number
---@param y number
---@param z number
---@param heading number
---@param p4 number
---@param p5 number
---@param modelHash Hash|string
---@param p7 integer
---@param p8 integer
---@param p9 integer
---@param p10 integer
---@param p11 boolean
---@param p12 boolean
---@param p13 boolean
---@param p14 boolean
---@param p15 boolean
---@param p16 integer
---@return integer
function CreateScriptVehicleGenerator(x, y, z, heading, p4, p5, modelHash, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16) end

---@param x number
---@param y number
---@param z number
---@param roll number
---@param pitch number
---@param yaw number
---@param p6 integer
---@return integer
function CreateSynchronizedScene(x, y, z, roll, pitch, yaw, p6) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param object Hash|string
---@return integer
function CreateSynchronizedScene_2(x, y, z, radius, object) end

---@param modifierName string
---@return integer
function CreateTimecycleModifier(modifierName) end

---@return integer
function CreateTrackedPoint() end

---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param heading number
---@param isNetwork boolean
---@param netMissionEntity boolean
---@return integer
function CreateVehicle(modelHash, x, y, z, heading, isNetwork, netMissionEntity) end

---@param weaponHash Hash|string
---@param ammoCount integer
---@param x number
---@param y number
---@param z number
---@param bCreateDefaultComponents boolean
---@param scale number
---@param customModelHash integer
---@return integer
function CreateWeaponObject(weaponHash, ammoCount, x, y, z, bCreateDefaultComponents, scale, customModelHash) end

---@param p0 number
function CustomMenuCoordinates(p0) end

---@param value boolean
---@return unknown arrayData
function DataarrayAddBool(value) end

---@return unknown
---@return unknown arrayData
function DataarrayAddDict() end

---@param value number
---@return unknown arrayData
function DataarrayAddFloat(value) end

---@param value integer
---@return unknown arrayData
function DataarrayAddInt(value) end

---@param value string
---@return unknown arrayData
function DataarrayAddString(value) end

---@param valueX number
---@param valueY number
---@param valueZ number
---@return unknown arrayData
function DataarrayAddVector(valueX, valueY, valueZ) end

---@param arrayIndex integer
---@return boolean
---@return unknown arrayData
function DataarrayGetBool(arrayIndex) end

---@return integer
---@return unknown arrayData
function DataarrayGetCount() end

---@param arrayIndex integer
---@return unknown
---@return unknown arrayData
function DataarrayGetDict(arrayIndex) end

---@param arrayIndex integer
---@return number
---@return unknown arrayData
function DataarrayGetFloat(arrayIndex) end

---@param arrayIndex integer
---@return integer
---@return unknown arrayData
function DataarrayGetInt(arrayIndex) end

---@param arrayIndex integer
---@return string
---@return unknown arrayData
function DataarrayGetString(arrayIndex) end

---@param arrayIndex integer
---@return integer
---@return unknown arrayData
function DataarrayGetType(arrayIndex) end

---@param arrayIndex integer
---@return vector3
---@return unknown arrayData
function DataarrayGetVector(arrayIndex) end

---@param key string
---@return unknown
---@return unknown objectData
function DatadictCreateArray(key) end

---@param key string
---@return unknown
---@return unknown objectData
function DatadictCreateDict(key) end

---@param key string
---@return unknown
---@return unknown objectData
function DatadictGetArray(key) end

---@param key string
---@return boolean
---@return unknown objectData
function DatadictGetBool(key) end

---@param key string
---@return unknown
---@return unknown objectData
function DatadictGetDict(key) end

---@param key string
---@return number
---@return unknown objectData
function DatadictGetFloat(key) end

---@param key string
---@return integer
---@return unknown objectData
function DatadictGetInt(key) end

---@param key string
---@return string
---@return unknown objectData
function DatadictGetString(key) end

---@param key string
---@return integer
---@return unknown objectData
function DatadictGetType(key) end

---@param key string
---@return vector3
---@return unknown objectData
function DatadictGetVector(key) end

---@param key string
---@param value boolean
---@return unknown objectData
function DatadictSetBool(key, value) end

---@param key string
---@param value number
---@return unknown objectData
function DatadictSetFloat(key, value) end

---@param key string
---@param value integer
---@return unknown objectData
function DatadictSetInt(key, value) end

---@param key string
---@param value string
---@return unknown objectData
function DatadictSetString(key, value) end

---@param key string
---@param valueX number
---@param valueY number
---@param valueZ number
---@return unknown objectData
function DatadictSetVector(key, valueX, valueY, valueZ) end

function DatafileClearWatchList() end

function DatafileCreate() end

function DatafileDelete() end

---@param p0 unknown
---@return boolean
function DatafileDeleteRequestedFile(p0) end

function DatafileFlushMissionHeader() end

---@return string
function DatafileGetFileDict() end

---@param p0 unknown
---@return boolean
function DatafileHasLoadedFileData(p0) end

---@param p0 unknown
---@return boolean
function DatafileHasValidFileData(p0) end

---@return boolean
function DatafileIsSavePending() end

---@param index integer
---@return boolean
function DatafileIsValidRequestId(index) end

---@param filename string
---@return boolean
function DatafileLoadOfflineUgc(filename) end

---@param p0 unknown
---@return boolean
function DatafileSelectActiveFile(p0) end

---@param p0 integer
---@return boolean
function DatafileSelectCreatorStats(p0) end

---@param p0 integer
---@return boolean
function DatafileSelectUgcData(p0) end

---@param p0 integer
---@return boolean
function DatafileSelectUgcPlayerData(p0) end

---@param p0 integer
---@param p1 boolean
---@return boolean
function DatafileSelectUgcStats(p0, p1) end

---@param filename string
---@return boolean
function DatafileStartSaveToCloud(filename) end

function DatafileStoreMissionHeader() end

---@return boolean
---@return boolean p0
function DatafileUpdateSaveToCloud() end

---@param id integer
function DatafileWatchRequestId(id) end

---@param mode string
function DeactivateAudioSlowmoMode(mode) end

---@param interior integer
---@param entitySetName string
function DeactivateInteriorEntitySet(interior, entitySetName) end

---@param entity Entity
---@param propertyName string
---@return boolean
function DecorExistOn(entity, propertyName) end

---@param entity Entity
---@param propertyName string
---@return boolean
function DecorGetBool(entity, propertyName) end

---@param entity Entity
---@param propertyName string
---@return number
function DecorGetFloat(entity, propertyName) end

---@param entity Entity
---@param propertyName string
---@return integer
function DecorGetInt(entity, propertyName) end

---@param propertyName string
---@param type integer
---@return boolean
function DecorIsRegisteredAsType(propertyName, type) end

---@param propertyName string
---@param type integer
function DecorRegister(propertyName, type) end

function DecorRegisterLock() end

---@param entity Entity
---@param propertyName string
---@return boolean
function DecorRemove(entity, propertyName) end

---@param entity Entity
---@param propertyName string
---@param value boolean
---@return boolean
function DecorSetBool(entity, propertyName, value) end

---@param entity Entity
---@param propertyName string
---@param value number
---@return boolean
function DecorSetFloat(entity, propertyName, value) end

---@param entity Entity
---@param propertyName string
---@param value integer
---@return boolean
function DecorSetInt(entity, propertyName, value) end

---@param entity Entity
---@param propertyName string
---@param timestamp integer
---@return boolean
function DecorSetTime(entity, propertyName, timestamp) end

function DeleteAllTrains() end

---@param checkpoint integer
function DeleteCheckpoint(checkpoint) end

---@param ropeId integer
function DeleteChildRope(ropeId) end

---@return Entity entity
function DeleteEntity() end

---@param incidentId integer
function DeleteIncident(incidentId) end

---@return integer train
function DeleteMissionTrain() end

---@return integer object
function DeleteObject() end

---@param patrolRoute string
function DeletePatrolRoute(patrolRoute) end

---@return Ped ped
function DeletePed() end

---@return integer ropeId
function DeleteRope() end

---@param vehicleGenerator integer
function DeleteScriptVehicleGenerator(vehicleGenerator) end

---@param p0 integer
function DeleteStuntJump(p0) end

---@return integer vehicle
function DeleteVehicle() end

function DeleteWaypoint() end

---@param amount integer
---@return boolean
function DepositVc(amount) end

---@param bScriptHostCam boolean
function DestroyAllCams(bScriptHostCam) end

---@param cam integer
---@param bScriptHostCam boolean
function DestroyCam(cam, bScriptHostCam) end

---@param duiObject integer
function DestroyDui(duiObject) end

---@param p0 unknown
function DestroyItemset(p0) end

function DestroyMobilePhone() end

---@return boolean
function DestroyPlayerInPauseMenu() end

---@param point integer
function DestroyTrackedPoint(point) end

---@param cam integer
function DetachCam(cam) end

---@param vehicle integer
function DetachContainerFromHandlerFrame(vehicle) end

---@param entity Entity
---@param dynamic boolean
---@param collision boolean
function DetachEntity(entity, dynamic, collision) end

---@param vehicle integer
---@param entity Entity
---@return unknown
function DetachEntityFromCargobob(vehicle, entity) end

---@param pickupObject integer
function DetachPortablePickupFromPed(pickupObject) end

---@param ropeId integer
---@param entity Entity
function DetachRopeFromEntity(ropeId, entity) end

---@param sceneID integer
function DetachSynchronizedScene(sceneID) end

---@param vehicle integer
---@return boolean
function DetachVehicleFromAnyCargobob(vehicle) end

---@param vehicle integer
---@return boolean
function DetachVehicleFromAnyTowTruck(vehicle) end

---@param cargobob integer
---@param vehicle integer
function DetachVehicleFromCargobob(cargobob, vehicle) end

---@param towTruck integer
---@param vehicle integer
function DetachVehicleFromTowTruck(towTruck, vehicle) end

---@param vehicle integer
function DetachVehicleFromTrailer(vehicle) end

---@param vehicle integer
function DetachVehicleWindscreen(vehicle) end

function DetonateVehiclePhoneExplosiveDevice() end

function DisableAimCamThisUpdate() end

---@param padIndex integer
function DisableAllControlActions(padIndex) end

---@param toggle boolean
function DisableAutomaticRespawn(toggle) end

---@return integer
function DisableBlipNameForVar() end

---@param entity Entity
function DisableCamCollisionForEntity(entity) end

---@param entity Entity
function DisableCamCollisionForObject(entity) end

---@param padIndex integer
---@param control integer
---@param disable boolean
function DisableControlAction(padIndex, control, disable) end

function DisableEditorRuntime() end

function DisableFirstPersonCamThisFrame() end

function DisableFrontendThisFrame() end

---@param ped Ped
function DisableHeadBlendPaletteColor(ped) end

---@param hospitalIndex integer
---@param toggle boolean
function DisableHospitalRestart(hospitalIndex, toggle) end

---@param state boolean
function DisableIdleCamera(state) end

---@param vehicle integer
---@param propeller integer
function DisableIndividualPlanePropeller(vehicle, propeller) end

---@param padIndex integer
function DisableInputGroup(padIndex) end

---@param interiorID integer
---@param toggle boolean
function DisableInterior(interiorID, toggle) end

---@param interior integer
---@param entitySetName string
function DisableInteriorProp(interior, entitySetName) end

function DisableMoonCycleOverride() end

---@param disable boolean
function DisableMultiplayerChat(disable) end

---@param posMinX number
---@param posMinY number
---@param posMinZ number
---@param posMaxX number
---@param posMaxY number
---@param posMaxZ number
---@param bDisable boolean
function DisableNavmeshInArea(posMinX, posMinY, posMinZ, posMaxX, posMaxY, posMaxZ, bDisable) end

function DisableOcclusionThisFrame() end

---@param ped Ped
function DisablePedHeatscaleOverride(ped) end

---@param ped Ped
---@param shouldDisable boolean
function DisablePedPainAudio(ped, shouldDisable) end

---@param toggle boolean
function DisablePhoneThisFrame(toggle) end

---@param vehicle integer
---@param p1 boolean
---@param p2 boolean
function DisablePlaneAileron(vehicle, p1, p2) end

---@param vehicle integer
---@param propeller integer
function DisablePlanePropeller(vehicle, propeller) end

---@param player integer
---@param toggle boolean
function DisablePlayerFiring(player, toggle) end

---@param player integer
function DisablePlayerVehicleRewards(player) end

function DisablePoliceReports() end

---@param policeIndex integer
---@param toggle boolean
function DisablePoliceRestart(policeIndex, toggle) end

function DisableRadarThisFrame() end

---@param rawKeyIndex integer
---@return boolean
function DisableRawKeyThisFrame(rawKeyIndex) end

function DisableRockstarEditorCameraChanges() end

function DisableScreenblurFade() end

---@param p0 unknown
function DisableScriptAmbientEffects(p0) end

---@param brainSet integer
function DisableScriptBrainSet(brainSet) end

---@param p0 integer
function DisableStuntJumpSet(p0) end

function DisableSwitchOutroFx() end

---@param toggle boolean
function DisableVehicleDistantlights(toggle) end

function DisableVehicleFirstPersonCamThisFrame() end

---@param vehicle integer
---@param toggle boolean
function DisableVehicleImpactExplosionActivation(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function DisableVehicleNeonLights(vehicle, toggle) end

---@param state boolean
function DisableVehiclePassengerIdleCamera(state) end

---@param vehicle integer
function DisableVehicleTurretMovementThisFrame(vehicle) end

---@param disabled boolean
---@param weaponHash Hash|string
---@param vehicle integer
---@param owner Ped
function DisableVehicleWeapon(disabled, weaponHash, vehicle, owner) end

---@param vehicle integer
function DisableVehicleWorldCollision(vehicle) end

---@param state boolean
function DisableWorldhorizonRendering(state) end

---@param display boolean
function DisplayAmmoThisFrame(display) end

---@param toggle boolean
function DisplayAreaName(toggle) end

---@param display boolean
function DisplayCash(display) end

---@param toggle boolean
function DisplayDistantVehicles(toggle) end

---@param shape integer
---@param loop boolean
---@param beep boolean
---@param duration integer
function DisplayHelpTextFromStringLabel(shape, loop, beep, duration) end

---@param pTextLabel string
---@param bCurvedWindow boolean
function DisplayHelpTextThisFrame(pTextLabel, bCurvedWindow) end

---@param toggle boolean
function DisplayHud(toggle) end

function DisplayHudWhenDeadThisFrame() end

function DisplayHudWhenPausedThisFrame() end

function DisplayJobReport() end

---@param keyboardType integer
---@param windowTitle string
---@param description string
---@param defaultText string
---@param defaultConcat1 string
---@param defaultConcat2 string
---@param defaultConcat3 string
---@param maxInputLength integer
function DisplayOnscreenKeyboard(keyboardType, windowTitle, description, defaultText, defaultConcat1, defaultConcat2, defaultConcat3, maxInputLength) end

---@param keyboardType integer
---@param windowTitle string
---@param description string
---@param defaultText string
---@param defaultConcat1 string
---@param defaultConcat2 string
---@param defaultConcat3 string
---@param defaultConcat4 string
---@param defaultConcat5 string
---@param defaultConcat6 string
---@param defaultConcat7 string
---@param maxInputLength integer
function DisplayOnscreenKeyboard_2(keyboardType, windowTitle, description, defaultText, defaultConcat1, defaultConcat2, defaultConcat3, defaultConcat4, defaultConcat5, defaultConcat6, defaultConcat7, maxInputLength) end

---@param keyboardType integer
---@param windowTitle string
---@param description string
---@param defaultText string
---@param defaultConcat1 string
---@param defaultConcat2 string
---@param defaultConcat3 string
---@param defaultConcat4 string
---@param defaultConcat5 string
---@param defaultConcat6 string
---@param defaultConcat7 string
---@param maxInputLength integer
function DisplayOnscreenKeyboardWithLongerInitialString(keyboardType, windowTitle, description, defaultText, defaultConcat1, defaultConcat2, defaultConcat3, defaultConcat4, defaultConcat5, defaultConcat6, defaultConcat7, maxInputLength) end

---@param toggle boolean
function DisplayPlayerNameTagsOnBlips(toggle) end

---@param toggle boolean
function DisplayRadar(toggle) end

function DisplaySniperScopeThisFrame() end

---@param unk boolean
function DisplaySystemSigninUi(unk) end

---@param scene integer
function DisposeSynchronizedScene(scene) end

---@param shouldPlay boolean
function DistantCopCarSirens(shouldPlay) end

function DoAutoSave() end

---@param zoneId integer
---@return boolean
function DoesAirDefenseZoneExist(zoneId) end

---@param animDict string
---@return boolean
function DoesAnimDictExist(animDict) end

---@param blip integer
---@return boolean
function DoesBlipExist(blip) end

---@param blip integer
---@return boolean
function DoesBlipHaveGpsRoute(blip) end

---@param cam integer
---@return boolean
function DoesCamExist(cam) end

---@param cargobob integer
---@return boolean
function DoesCargobobHavePickupMagnet(cargobob) end

---@param cargobob integer
---@return boolean
function DoesCargobobHavePickUpRope(cargobob) end

---@param ped Ped
---@param speechName string
---@param allowBackupPVGs boolean
---@return boolean
function DoesContextExistForThisPed(ped, speechName, allowBackupPVGs) end

---@param cutsceneEntName string
---@param modelHash Hash|string
---@return boolean
function DoesCutsceneEntityExist(cutsceneEntName, modelHash) end

---@param object integer
---@return boolean
function DoesDesObjectExist(object) end

---@param doorHash Hash|string
---@return boolean
function DoesDoorExist(doorHash) end

---@param entity Entity
---@param p2 boolean
---@return boolean
function DoesEntityBelongToThisScript(entity, p2) end

---@param entity Entity
---@return boolean
function DoesEntityExist(entity) end

---@param entity Entity
---@return boolean
function DoesEntityHaveAnimDirector(entity) end

---@param entity Entity
---@return boolean
function DoesEntityHaveDrawable(entity) end

---@param object integer
---@return boolean
function DoesEntityHaveFragInst(object) end

---@param entity Entity
---@return boolean
function DoesEntityHavePhysics(entity) end

---@param entity Entity
---@return boolean
function DoesEntityHaveSkeletonData(entity) end

---@param vehicle integer
---@param extraId integer
---@return boolean
function DoesExtraExist(vehicle, extraId) end

---@param groupId integer
---@return boolean
function DoesGroupExist(groupId) end

---@param briefValue integer
---@return boolean
function DoesLatestBriefStringExist(briefValue) end

---@param p0 unknown
---@return boolean
function DoesNavmeshBlockingObjectExist(p0) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param hash Hash|string
---@param p5 boolean
---@return boolean
function DoesObjectOfTypeExistAtCoords(x, y, z, radius, hash, p5) end

---@param ptfxHandle integer
---@return boolean
function DoesParticleFxLoopedExist(ptfxHandle) end

---@param ped Ped
---@return boolean
function DoesPedHaveAiBlip(ped) end

---@param pickup integer
---@return boolean
function DoesPickupExist(pickup) end

---@param pickupObject integer
---@return boolean
function DoesPickupObjectExist(pickupObject) end

---@param pickupHash Hash|string
---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function DoesPickupOfTypeExistInArea(pickupHash, x, y, z, radius) end

---@return boolean
function DoesPlayerVehHaveRadio() end

---@param id integer
---@return boolean
function DoesPopMultiplierAreaExist(id) end

---@param id integer
---@return boolean
function DoesPopMultiplierSphereExist(id) end

---@param object integer
---@return boolean
function DoesRayfireMapObjectExist(object) end

---@param groupHash Hash|string
---@return boolean
function DoesRelationshipGroupExist(groupHash) end

---@param ropeId integer
---@return boolean
function DoesRopeBelongToThisScript(ropeId) end

---@return boolean
---@return integer ropeId
function DoesRopeExist() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function DoesScenarioBlockingAreaExist(x1, y1, z1, x2, y2, z2) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param b boolean
---@return boolean
function DoesScenarioExistInArea(x, y, z, radius, b) end

---@param scenarioGroup string
---@return boolean
function DoesScenarioGroupExist(scenarioGroup) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 string
---@param p4 number
---@param p5 boolean
---@return boolean
function DoesScenarioOfTypeExistInArea(p0, p1, p2, p3, p4, p5) end

---@param x number
---@param y number
---@param z number
---@return boolean
function DoesScriptedCoverPointExistAtCoords(x, y, z) end

---@param scriptName string
---@return boolean
function DoesScriptExist(scriptName) end

---@param vehicleGenerator integer
---@return boolean
function DoesScriptVehicleGeneratorExist(vehicleGenerator) end

---@param scriptHash Hash|string
---@return boolean
function DoesScriptWithNameHashExist(scriptHash) end

---@param componentHash Hash|string
---@param restrictionTagHash Hash|string
---@param componentId integer
---@return boolean
function DoesShopPedApparelHaveRestrictionTag(componentHash, restrictionTagHash, componentId) end

---@param gxt string
---@return boolean
function DoesTextBlockExist(gxt) end

---@param gxt string
---@return boolean
function DoesTextLabelExist(gxt) end

---@param modifierName string
---@param varName string
---@return boolean
function DoesTimecycleModifierHasVar(modifierName, varName) end

---@param vehicle integer
---@return boolean
function DoesVehicleAllowRappel(vehicle) end

---@param decorator string
---@return boolean
function DoesVehicleExistWithDecorator(decorator) end

---@param vehicle integer
---@param p1 integer
---@return boolean
function DoesVehicleHaveCrewEmblem(vehicle, p1) end

---@param vehicle integer
---@param p1 integer
---@return boolean
function DoesVehicleHaveDecal(vehicle, p1) end

---@param vehicle integer
---@param doorIndex integer
---@return boolean
function DoesVehicleHaveDoor(vehicle, doorIndex) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveJumpingAbility(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveLandingGear(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveParachute(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveRetractableWheels(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveRocketBoost(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveRoof(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveSearchlight(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveStuckVehicleCheck(vehicle) end

---@param vehicle integer
---@return boolean
function DoesVehicleHaveWeapons(vehicle) end

---@param vehicle integer
---@param tyreIndex integer
---@return boolean
function DoesVehicleTyreExist(vehicle, tyreIndex) end

---@param vehicle integer
---@return boolean
function DoesVehicleUseFuel(vehicle) end

---@param weaponHash Hash|string
---@param componentHash Hash|string
---@return boolean
function DoesWeaponTakeWeaponComponent(weaponHash, componentHash) end

---@param p0 boolean
function DontRenderInGameUi(p0) end

function DontTiltMinimapThisFrame() end

---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param locked boolean
---@param xRotMult number
---@param yRotMult number
---@param zRotMult number
function DoorControl(modelHash, x, y, z, locked, xRotMult, yRotMult, zRotMult) end

---@param x number
---@param y number
---@param z number
---@param modelHash Hash|string
---@return boolean
---@return Hash doorOutPointer
function DoorSystemFindExistingDoor(x, y, z, modelHash) end

---@return table
function DoorSystemGetActive() end

---@param doorHash Hash|string
---@return number
function DoorSystemGetAutomaticDistance(doorHash) end

---@param doorHash Hash|string
---@return integer
function DoorSystemGetDoorPendingState(doorHash) end

---@param doorHash Hash|string
---@return integer
function DoorSystemGetDoorState(doorHash) end

---@param doorHash Hash|string
---@return boolean
function DoorSystemGetIsPhysicsLoaded(doorHash) end

---@param doorHash Hash|string
---@return number
function DoorSystemGetOpenRatio(doorHash) end

---@return integer
function DoorSystemGetSize() end

---@param doorHash Hash|string
---@param distance number
---@param requestDoor boolean
---@param forceUpdate boolean
function DoorSystemSetAutomaticDistance(doorHash, distance, requestDoor, forceUpdate) end

---@param doorHash Hash|string
---@param rate number
---@param requestDoor boolean
---@param forceUpdate boolean
function DoorSystemSetAutomaticRate(doorHash, rate, requestDoor, forceUpdate) end

---@param doorHash Hash|string
---@param state integer
---@param requestDoor boolean
---@param forceUpdate boolean
function DoorSystemSetDoorState(doorHash, state, requestDoor, forceUpdate) end

---@param doorHash Hash|string
---@param toggle boolean
function DoorSystemSetHoldOpen(doorHash, toggle) end

---@param doorHash Hash|string
---@param ajar number
---@param requestDoor boolean
---@param forceUpdate boolean
function DoorSystemSetOpenRatio(doorHash, ajar, requestDoor, forceUpdate) end

---@param doorHash Hash|string
---@param removed boolean
---@param requestDoor boolean
---@param forceUpdate boolean
function DoorSystemSetSpringRemoved(doorHash, removed, requestDoor, forceUpdate) end

---@param duration integer
function DoScreenFadeIn(duration) end

---@param duration integer
function DoScreenFadeOut(duration) end

function DownloadCheck() end

---@param binkMovie integer
---@param posX number
---@param posY number
---@param scaleX number
---@param scaleY number
---@param rotation number
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function DrawBinkMovie(binkMovie, posX, posY, scaleX, scaleY, rotation, r, g, b, a) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawBox(x1, y1, z1, x2, y2, z2, red, green, blue, alpha) end

---@param posX number
---@param posY number
---@param posZ number
---@param size number
---@param alpha integer
---@param red integer
---@param green integer
---@param blue integer
---@param intensity number
---@param zBias number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param viewThreshold number
---@param innerAngle number
---@param outerAngle number
---@param flags integer
function DrawCorona(posX, posY, posZ, size, alpha, red, green, blue, intensity, zBias, dirX, dirY, dirZ, viewThreshold, innerAngle, outerAngle, flags) end

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
function DrawDebugBox(x1, y1, z1, x2, y2, z2, r, g, b, a) end

---@param x number
---@param y number
---@param z number
---@param size number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawDebugCross(x, y, z, size, red, green, blue, alpha) end

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
function DrawDebugLine(x1, y1, z1, x2, y2, z2, r, g, b, a) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param r1 integer
---@param g1 integer
---@param b1 integer
---@param r2 integer
---@param g2 integer
---@param b2 integer
---@param alpha1 integer
---@param alpha2 integer
function DrawDebugLineWithTwoColours(x1, y1, z1, x2, y2, z2, r1, g1, b1, r2, g2, b2, alpha1, alpha2) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawDebugSphere(x, y, z, radius, red, green, blue, alpha) end

---@param text string
---@param x number
---@param y number
---@param z number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawDebugText(text, x, y, z, red, green, blue, alpha) end

---@param text string
---@param x number
---@param y number
---@param z number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawDebugText_2d(text, x, y, z, red, green, blue, alpha) end

---@param labelTitle string
---@param labelMsg string
---@param p2 integer
---@param p3 integer
---@param labelMsg2 string
---@param p5 boolean
---@param p6 integer
---@param p7 integer
---@param p8 string
---@param p9 string
---@param background boolean
---@param errorCode integer
function DrawFrontendAlert(labelTitle, labelMsg, p2, p3, labelMsg2, p5, p6, p7, p8, p9, background, errorCode) end

---@param matrixPtr integer
---@param id string
---@return boolean
function DrawGizmo(matrixPtr, id) end

---@param posX number
---@param posY number
---@param posZ number
---@param radius number
---@param colorR integer
---@param colorG integer
---@param colorB integer
---@param intensity number
---@param invert boolean
---@param marker boolean
function DrawGlowSphere(posX, posY, posZ, radius, colorR, colorG, colorB, intensity, invert, marker) end

---@param textureDict string
---@param textureName string
---@param screenX number
---@param screenY number
---@param width number
---@param height number
---@param heading number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawInteractiveSprite(textureDict, textureName, screenX, screenY, width, height, heading, red, green, blue, alpha) end

function DrawLight() end

---@param posX number
---@param posY number
---@param posZ number
---@param colorR integer
---@param colorG integer
---@param colorB integer
---@param range number
---@param intensity number
function DrawLightWithRange(posX, posY, posZ, colorR, colorG, colorB, range, intensity) end

---@param x number
---@param y number
---@param z number
---@param r integer
---@param g integer
---@param b integer
---@param range number
---@param intensity number
---@param shadow number
function DrawLightWithRangeAndShadow(x, y, z, r, g, b, range, intensity, shadow) end

---@param x number
---@param y number
---@param z number
---@param r integer
---@param g integer
---@param b integer
---@param range number
---@param intensity number
---@param shadow number
function DrawLightWithRangeWithShadow(x, y, z, r, g, b, range, intensity, shadow) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param width number
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function DrawLine_2d(x1, y1, x2, y2, width, r, g, b, a) end

---@param p0 boolean
---@param p1 boolean
function DrawLowQualityPhotoToPhone(p0, p1) end

---@param type integer
---@param posX number
---@param posY number
---@param posZ number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param bobUpAndDown boolean
---@param faceCamera boolean
---@param p19 integer
---@param rotate boolean
---@param textureDict string
---@param textureName string
---@param drawOnEnts boolean
function DrawMarker(type, posX, posY, posZ, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts) end

---@param type integer
---@param posX number
---@param posY number
---@param posZ number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param bobUpAndDown boolean
---@param faceCamera boolean
---@param p19 integer
---@param rotate boolean
---@param textureDict string
---@param textureName string
---@param drawOnEnts boolean
---@param p24 boolean
function DrawMarker_2(type, posX, posY, posZ, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts, p24) end

---@param isImportant boolean
---@param bHasTokens boolean
---@return integer
function DrawNotification(isImportant, bHasTokens) end

---@param blink boolean
---@param bHasTokens boolean
---@return integer
function DrawNotification_2(blink, bHasTokens) end

---@param isImportant boolean
---@param bHasTokens boolean
---@return integer
function DrawNotification_3(isImportant, bHasTokens) end

---@param blink boolean
---@param bHasTokens boolean
---@return integer
function DrawNotification_4(blink, bHasTokens) end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param hasFounderStatus boolean
---@param isImportant boolean
---@param clanHandle integer
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function DrawNotificationApartmentInvite(crewTypeIsPrivate, crewTagContainsRockstar, rank, hasFounderStatus, isImportant, clanHandle, r, g, b) end

---@param textureDict string
---@param textureName string
---@param rpBonus integer
---@param colorOverlay integer
---@param titleLabel string
---@return integer
function DrawNotificationAward(textureDict, textureName, rpBonus, colorOverlay, titleLabel) end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param isLeader boolean
---@param isImportant boolean
---@param clanHandle integer
---@param gamerStr string
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function DrawNotificationClanInvite(crewTypeIsPrivate, crewTagContainsRockstar, rank, isLeader, isImportant, clanHandle, gamerStr, r, g, b) end

---@param textureDict string
---@param textureName string
---@param rpBonus integer
---@param colorOverlay integer
---@param titleLabel string
---@return integer
function DrawNotificationIcon(textureDict, textureName, rpBonus, colorOverlay, titleLabel) end

---@param type integer
---@param button string
---@param text string
---@return integer
function DrawNotificationWithButton(type, button, text) end

---@param eType integer
---@param iIcon integer
---@param sTitle string
---@return integer
function DrawNotificationWithIcon(eType, iIcon, sTitle) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawPoly(x1, y1, z1, x2, y2, z2, x3, y3, z3, red, green, blue, alpha) end

---@param x number
---@param y number
---@param width number
---@param height number
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function DrawRect(x, y, width, height, r, g, b, a) end

---@param x number
---@param y number
---@param width number
---@param height number
---@param rotation number
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function DrawRectRotated(x, y, width, height, rotation, r, g, b, a) end

---@param scaleformHandle integer
---@param x number
---@param y number
---@param width number
---@param height number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param unk integer
function DrawScaleformMovie(scaleformHandle, x, y, width, height, red, green, blue, alpha, unk) end

---@param scaleform integer
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param p7 number
---@param sharpness number
---@param p9 number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param p13 unknown
function DrawScaleformMovie_3d(scaleform, posX, posY, posZ, rotX, rotY, rotZ, p7, sharpness, p9, scaleX, scaleY, scaleZ, p13) end

---@param scaleform integer
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param p7 number
---@param p8 number
---@param p9 number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param p13 unknown
function DrawScaleformMovie_3dNonAdditive(scaleform, posX, posY, posZ, rotX, rotY, rotZ, p7, p8, p9, scaleX, scaleY, scaleZ, p13) end

---@param scaleform integer
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param p7 number
---@param p8 number
---@param p9 number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param p13 unknown
function DrawScaleformMovie_3dSolid(scaleform, posX, posY, posZ, rotX, rotY, rotZ, p7, p8, p9, scaleX, scaleY, scaleZ, p13) end

---@param scaleform integer
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param unk integer
function DrawScaleformMovieFullscreen(scaleform, red, green, blue, alpha, unk) end

---@param scaleform1 integer
---@param scaleform2 integer
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawScaleformMovieFullscreenMasked(scaleform1, scaleform2, red, green, blue, alpha) end

---@param p0 string
---@param ped Ped
---@param p2 integer
---@param posX number
---@param posY number
---@param posZ number
---@return boolean
function DrawShowroom(p0, ped, p2, posX, posY, posZ) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param r integer
---@param g integer
---@param b integer
---@param opacity number
function DrawSphere(x, y, z, radius, r, g, b, opacity) end

---@param posX number
---@param posY number
---@param posZ number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param colorR integer
---@param colorG integer
---@param colorB integer
---@param distance number
---@param brightness number
---@param hardness number
---@param radius number
---@param falloff number
function DrawSpotLight(posX, posY, posZ, dirX, dirY, dirZ, colorR, colorG, colorB, distance, brightness, hardness, radius, falloff) end

---@param posX number
---@param posY number
---@param posZ number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param colorR integer
---@param colorG integer
---@param colorB integer
---@param distance number
---@param brightness number
---@param roundness number
---@param radius number
---@param falloff number
---@param shadowId integer
function DrawSpotLightWithShadow(posX, posY, posZ, dirX, dirY, dirZ, colorR, colorG, colorB, distance, brightness, roundness, radius, falloff, shadowId) end

---@param textureDict string
---@param textureName string
---@param screenX number
---@param screenY number
---@param width number
---@param height number
---@param heading number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawSprite(textureDict, textureName, screenX, screenY, width, height, heading, red, green, blue, alpha) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param textureDict string
---@param textureName string
---@param u1 number
---@param v1 number
---@param w1 number
---@param u2 number
---@param v2 number
---@param w2 number
---@param u3 number
---@param v3 number
---@param w3 number
function DrawSpritePoly(x1, y1, z1, x2, y2, z2, x3, y3, z3, red, green, blue, alpha, textureDict, textureName, u1, v1, w1, u2, v2, w2, u3, v3, w3) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param red1 number
---@param green1 number
---@param blue1 number
---@param alpha1 integer
---@param red2 number
---@param green2 number
---@param blue2 number
---@param alpha2 integer
---@param red3 number
---@param green3 number
---@param blue3 number
---@param alpha3 integer
---@param textureDict string
---@param textureName string
---@param u1 number
---@param v1 number
---@param w1 number
---@param u2 number
---@param v2 number
---@param w2 number
---@param u3 number
---@param v3 number
---@param w3 number
function DrawSpritePoly_2(x1, y1, z1, x2, y2, z2, x3, y3, z3, red1, green1, blue1, alpha1, red2, green2, blue2, alpha2, red3, green3, blue3, alpha3, textureDict, textureName, u1, v1, w1, u2, v2, w2, u3, v3, w3) end

---@param textureDict string
---@param textureName string
---@param x number
---@param y number
---@param width number
---@param height number
---@param u1 number
---@param v1 number
---@param u2 number
---@param v2 number
---@param heading number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawSpriteUv(textureDict, textureName, x, y, width, height, u1, v1, u2, v2, heading, red, green, blue, alpha) end

---@param duration integer
---@param drawImmediately boolean
function DrawSubtitleTimed(duration, drawImmediately) end

---@param x number
---@param y number
function DrawText(x, y) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param textureDict string
---@param textureName string
---@param u1 number
---@param v1 number
---@param w1 number
---@param u2 number
---@param v2 number
---@param w2 number
---@param u3 number
---@param v3 number
---@param w3 number
function DrawTexturedPoly(x1, y1, z1, x2, y2, z2, x3, y3, z3, red, green, blue, alpha, textureDict, textureName, u1, v1, w1, u2, v2, w2, u3, v3, w3) end

---@param xPos number
---@param yPos number
---@param xScale number
---@param yScale number
---@param rotation number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function DrawTvChannel(xPos, yPos, xScale, yScale, rotation, red, green, blue, alpha) end

---@param ped Ped
function DropAmbientProp(ped) end

---@param entity Entity
---@param groupName string
---@param fadeIn number
function DynamicMixerRelatedFn(entity, groupName, fadeIn) end

---@param vehicle integer
---@param x number
---@param y number
---@param z number
function EjectJb700Roof(vehicle, x, y, z) end

---@param vehicle integer
---@param avoidObstacles boolean
function EnableAircraftObstacleAvoidance(vehicle, avoidObstacles) end

---@param toggle boolean
function EnableAlienBloodVfx(toggle) end

---@param padIndex integer
function EnableAllControlActions(padIndex) end

---@param cargobob integer
---@param state integer
function EnableCargobobHook(cargobob, state) end

---@param toggle boolean
function EnableClownBloodVfx(toggle) end

---@param padIndex integer
---@param control integer
---@param enable boolean
function EnableControlAction(padIndex, control, enable) end

function EnableCrosshairThisFrame() end

---@param p0 integer
function EnableDeathbloodSeethrough(p0) end

---@param dispatchService integer
---@param toggle boolean
function EnableDispatchService(dispatchService, toggle) end

function EnableEditorRuntime() end

---@param entity Entity
function EnableEntityUnk(entity) end

---@param mapObjectHash Hash|string
function EnableExteriorCullModelThisFrame(mapObjectHash) end

---@param toggle boolean
function EnableGameplayCam(toggle) end

---@param interior integer
---@param entitySetName string
function EnableInteriorProp(interior, entitySetName) end

---@param toggle boolean
function EnableLaserSightRendering(toggle) end

---@param phase number
function EnableMoonCycleOverride(phase) end

---@param toggle boolean
function EnableMovieKeyframeWait(toggle) end

---@param toggle boolean
function EnableMovieSubtitles(toggle) end

---@param toggle integer
function EnableMpDlcMaps(toggle) end

---@param garageHash Hash|string
---@param toggle boolean
function EnableSavingInGarage(garageHash, toggle) end

---@param brainSet integer
function EnableScriptBrainSet(brainSet) end

---@param mapObjectHash Hash|string
function EnableScriptCullModelThisFrame(mapObjectHash) end

---@param player integer
---@param toggle boolean
function EnableSpecialAbility(player, toggle) end

---@param vehicle integer
---@param enable boolean
function EnableStallWarningSounds(vehicle, enable) end

function EnableStuntJumpAudio() end

---@param p0 integer
function EnableStuntJumpSet(p0) end

function EnableSwitchPauseBeforeDescent() end

---@param ped Ped
---@param toggle boolean
---@param p2 boolean
function EnableTennisMode(ped, toggle, p2) end

---@param vehicle integer
---@param toggle boolean
function EnableVehicleExhaustPops(vehicle, toggle) end

---@param vehicle integer
---@param enableFanbeltDamage boolean
function EnableVehicleFanbeltDamage(vehicle, enableFanbeltDamage) end

---@param findHandle integer
function EndFindObject(findHandle) end

---@param findHandle integer
function EndFindPed(findHandle) end

---@param findHandle integer
function EndFindPickup(findHandle) end

---@param findHandle integer
function EndFindVehicle(findHandle) end

function EndPetrolTrailDecals() end

function EndReplayStats() end

function EndScaleformMovieMethod() end

---@return integer
function EndScaleformMovieMethodReturn() end

---@return integer
function EndScaleformMovieMethodReturnValue() end

function EndSrl() end

---@param busySpinnerType integer
function EndTextCommandBusyspinnerOn(busySpinnerType) end

---@param busySpinnerType integer
function EndTextCommandBusyString(busySpinnerType) end

function EndTextCommandClearPrint() end

---@param shape integer
---@param loop boolean
---@param beep boolean
---@param duration integer
function EndTextCommandDisplayHelp(shape, loop, beep, duration) end

---@param x number
---@param y number
function EndTextCommandDisplayText(x, y) end

---@param x number
---@param y number
---@return integer
function EndTextCommandGetLineCount(x, y) end

---@param p0 boolean
---@return number
function EndTextCommandGetWidth(p0) end

---@return boolean
function EndTextCommandIsMessageDisplayed() end

---@param hudIndex integer
---@return boolean
function EndTextCommandIsThisHelpMessageBeingDisplayed(hudIndex) end

---@param x number
---@param y number
---@return integer
function EndTextCommandLineCount(x, y) end

---@param p0 boolean
function EndTextCommandObjective(p0) end

---@param buttonIndex integer
function EndTextCommandOverrideButtonText(buttonIndex) end

---@param duration integer
---@param drawImmediately boolean
function EndTextCommandPrint(duration, drawImmediately) end

function EndTextCommandScaleformString() end

function EndTextCommandScaleformString_2() end

---@param blip integer
function EndTextCommandSetBlipName(blip) end

---@param textureDict string
---@param textureName string
---@param rpBonus integer
---@param colorOverlay integer
---@param titleLabel string
---@return integer
function EndTextCommandThefeedPostAward(textureDict, textureName, rpBonus, colorOverlay, titleLabel) end

---@param chTitle string
---@param clanTxd string
---@param clanTxn string
---@param isImportant boolean
---@param showSubtitle boolean
---@return integer
function EndTextCommandThefeedPostCrewRankup(chTitle, clanTxd, clanTxn, isImportant, showSubtitle) end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param hasFounderStatus boolean
---@param isImportant boolean
---@param clanHandle integer
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function EndTextCommandThefeedPostCrewtag(crewTypeIsPrivate, crewTagContainsRockstar, rank, hasFounderStatus, isImportant, clanHandle, r, g, b) end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param isLeader boolean
---@param isImportant boolean
---@param clanHandle integer
---@param gamerStr string
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function EndTextCommandThefeedPostCrewtagWithGameName(crewTypeIsPrivate, crewTagContainsRockstar, rank, isLeader, isImportant, clanHandle, gamerStr, r, g, b) end

---@param textureDict string
---@param textureName string
---@param flash boolean
---@param iconType integer
---@param sender string
---@param subject string
---@return integer
function EndTextCommandThefeedPostMessagetext(textureDict, textureName, flash, iconType, sender, subject) end

---@param txdName string
---@param textureName string
---@param flash boolean
---@param iconType integer
---@param sender string
---@param subject string
---@return integer
function EndTextCommandThefeedPostMessagetextEntry(txdName, textureName, flash, iconType, sender, subject) end

---@param txdName string
---@param textureName string
---@param flash boolean
---@param iconType integer
---@param sender string
---@param subject string
---@return integer
function EndTextCommandThefeedPostMessagetextGxtEntry(txdName, textureName, flash, iconType, sender, subject) end

---@param picTxd string
---@param picTxn string
---@param flash boolean
---@param iconType integer
---@param nameStr string
---@param subtitleStr string
---@param durationMultiplier number
---@return integer
function EndTextCommandThefeedPostMessagetextTu(picTxd, picTxn, flash, iconType, nameStr, subtitleStr, durationMultiplier) end

---@param picTxd string
---@param picTxn string
---@param flash boolean
---@param iconType integer
---@param nameStr string
---@param subtitleStr string
---@param duration number
---@param crewPackedStr string
---@return integer
function EndTextCommandThefeedPostMessagetextWithCrewTag(picTxd, picTxn, flash, iconType, nameStr, subtitleStr, duration, crewPackedStr) end

---@param picTxd string
---@param picTxn string
---@param flash boolean
---@param iconType1 integer
---@param nameStr string
---@param subtitleStr string
---@param duration number
---@param crewPackedStr string
---@param iconType2 integer
---@param textColor integer
---@return integer
function EndTextCommandThefeedPostMessagetextWithCrewTagAndAdditionalIcon(picTxd, picTxn, flash, iconType1, nameStr, subtitleStr, duration, crewPackedStr, iconType2, textColor) end

---@param blink boolean
---@param bHasTokens boolean
---@return integer
function EndTextCommandThefeedPostMpticker(blink, bHasTokens) end

---@param eType integer
---@param iIcon integer
---@param sTitle string
---@return integer
function EndTextCommandThefeedPostReplayIcon(eType, iIcon, sTitle) end

---@param type integer
---@param button string
---@param text string
---@return integer
function EndTextCommandThefeedPostReplayInput(type, button, text) end

---@param statTitle string
---@param iconEnum integer
---@param stepVal boolean
---@param barValue integer
---@param isImportant boolean
---@param picTxd string
---@param picTxn string
---@return integer
function EndTextCommandThefeedPostStats(statTitle, iconEnum, stepVal, barValue, isImportant, picTxd, picTxn) end

---@param isImportant boolean
---@param bHasTokens boolean
---@return integer
function EndTextCommandThefeedPostTicker(isImportant, bHasTokens) end

---@param blink boolean
---@param bHasTokens boolean
---@return integer
function EndTextCommandThefeedPostTickerForced(blink, bHasTokens) end

---@param isImportant boolean
---@param bHasTokens boolean
---@return integer
function EndTextCommandThefeedPostTickerWithTokens(isImportant, bHasTokens) end

---@param chTitle string
---@param iconType integer
---@param chSubtitle string
---@return unknown
function EndTextCommandThefeedPostUnlock(chTitle, iconType, chSubtitle) end

---@param chTitle string
---@param iconType integer
---@param chSubtitle string
---@param isImportant boolean
---@return unknown
function EndTextCommandThefeedPostUnlockTu(chTitle, iconType, chSubtitle, isImportant) end

---@param chTitle string
---@param iconType integer
---@param chSubtitle string
---@param isImportant boolean
---@param titleColor integer
---@param p5 boolean
---@return unknown
function EndTextCommandThefeedPostUnlockTuWithColor(chTitle, iconType, chSubtitle, isImportant, titleColor, p5) end

---@param ch1TXD string
---@param ch1TXN string
---@param val1 integer
---@param ch2TXD string
---@param ch2TXN string
---@param val2 integer
---@return integer
function EndTextCommandThefeedPostVersusTu(ch1TXD, ch1TXN, val1, ch2TXD, ch2TXN, val2) end

---@param buttonIndex integer
function EndTextCommandTimer(buttonIndex) end

function EndTextCommandUnparsedScaleformString() end

function EndTextComponent() end

function EnterCursorMode() end

---@param entity Entity
function EntityDescriptionText(entity) end

---@param x number
---@param y number
---@param z number
function ExpandWorldLimits(x, y, z) end

---@param data string
---@param objectId integer
---@param tree string
---@return Entity
function ExperimentalLoadCloneCreate(data, objectId, tree) end

---@param entity Entity
---@param data string
function ExperimentalLoadCloneSync(entity, data) end

---@param entity Entity
---@return string
function ExperimentalSaveCloneCreate(entity) end

---@param entity Entity
---@return string
function ExperimentalSaveCloneSync(entity) end

---@param ped Ped
---@param weaponHash Hash|string
function ExplodePedHead(ped, weaponHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@param p2 boolean
function ExplodeProjectiles(ped, weaponHash, p2) end

---@param vehicle integer
---@param isAudible boolean
---@param isInvisible boolean
function ExplodeVehicle(vehicle, isAudible, isInvisible) end

---@param vehicle integer
---@param p1 boolean
function ExplodeVehicleInCutscene(vehicle, p1) end

---@param x number
---@param y number
---@param z number
function ExtendWorldBoundaryForPlayer(x, y, z) end

---@return boolean
function FacebookDoUnkCheck() end

---@return boolean
function FacebookIsAvailable() end

---@return boolean
function FacebookIsSendingData() end

---@return boolean
function FacebookSetCreateCharacterComplete() end

---@param heistName string
---@param cashEarned integer
---@param xpEarned integer
---@return boolean
function FacebookSetHeistComplete(heistName, cashEarned, xpEarned) end

---@param milestoneId integer
---@return boolean
function FacebookSetMilestoneComplete(milestoneId) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param duration number
function FadeDecalsInRange(x, y, z, radius, duration) end

---@param p0 boolean
function FadeOutLocalPlayer(p0) end

---@param p0 number
function FadeUpPedLight(p0) end

---@param p1 unknown
---@param p2 unknown
---@return boolean
---@return integer networkHandle
function FilloutPmPlayerList(p1, p2) end

---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return unknown p0
---@return unknown p1
function FilloutPmPlayerListWithNames(p2, p3) end

---@param ped Ped
function FinalizeHeadBlend(ped) end

---@param animDictionary string
---@param animName string
---@param p2 string
---@return boolean
---@return unknown p3
---@return unknown p4
function FindAnimEventPhase(animDictionary, animName, p2) end

---@return integer
---@return Entity outEntity
function FindFirstObject() end

---@return integer
---@return Entity outEntity
function FindFirstPed() end

---@return integer
---@return Entity outEntity
function FindFirstPickup() end

---@return integer
---@return Entity outEntity
function FindFirstVehicle() end

---@param findHandle integer
---@return boolean
---@return Entity outEntity
function FindNextObject(findHandle) end

---@param findHandle integer
---@return boolean
---@return Entity outEntity
function FindNextPed(findHandle) end

---@param findHandle integer
---@return boolean
---@return Entity outEntity
function FindNextPickup(findHandle) end

---@param findHandle integer
---@return boolean
---@return Entity outEntity
function FindNextVehicle(findHandle) end

---@param stationNameHash integer
---@return integer
function FindRadioStationIndex(stationNameHash) end

---@param ped Ped
---@return vector3
function FindRandomPointInSpace(ped) end

---@param posX number
---@param posY number
---@param posZ number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param distance number
---@return boolean
---@return vector3 spawnPoint
function FindSpawnPointInDirection(posX, posY, posZ, dirX, dirY, dirZ, distance) end

---@param entity Entity
---@return integer
function FindVehicleCarryingThisEntity(entity) end

---@param zoneId integer
---@param x number
---@param y number
---@param z number
function FireAirDefenseWeapon(zoneId, x, y, z) end

---@param object integer
function FixObjectFragment(object) end

---@param vehicle integer
---@param windowIndex integer
function FixVehicleWindow(vehicle, windowIndex) end

---@param toggle boolean
function FlagPlayerContextInTournament(toggle) end

---@param millisecondsToFlash integer
function FlashAbilityBar(millisecondsToFlash) end

function FlashMinimapDisplay() end

---@param hudColorIndex integer
function FlashMinimapDisplayWithColor(hudColorIndex) end

---@param p0 boolean
function FlashWantedDisplay(p0) end

---@param value number
---@return integer
function Floor(value) end

---@param shouldPlay boolean
function ForceAmbientSiren(shouldPlay) end

---@param p0 boolean
function ForceCinematicRenderingThisUpdate(p0) end

---@param cleanupFlags integer
function ForceCleanup(cleanupFlags) end

---@param name string
---@param cleanupFlags integer
function ForceCleanupForAllThreadsWithThisName(name, cleanupFlags) end

---@param id integer
---@param cleanupFlags integer
function ForceCleanupForThreadWithThisId(id, cleanupFlags) end

function ForceCloseReportugcMenu() end

function ForceCloseTextInputBox() end

---@param entity Entity
function ForceEntityAiAndAnimationUpdate(entity) end

function ForceGameStatePlaying() end

function ForceLightningFlash() end

---@param radioStation string
---@param trackListName string
---@param timeOffsetMilliseconds integer
function ForceMusicTrackList(radioStation, trackListName, timeOffsetMilliseconds) end

---@param ped Ped
---@param p1 boolean
---@param p2 boolean
function ForcePedAiAndAnimationUpdate(ped, p1, p2) end

---@param ped Ped
---@param motionStateHash Hash|string
---@param shouldReset boolean
---@param updateState integer
---@param forceAIPreCameraUpdate boolean
---@return boolean
function ForcePedMotionState(ped, motionStateHash, shouldReset, updateState, forceAIPreCameraUpdate) end

function ForcePedPanicWalla() end

---@param ped Ped
function ForcePedToOpenParachute(ped) end

---@param p0 unknown
function ForcePickupRegenerate(p0) end

---@param vehicle integer
---@param p1 boolean
function ForcePlaybackRecordedVehicleUpdate(vehicle, p1) end

---@param radioStation string
---@param trackListName string
---@param timeOffsetMilliseconds integer
function ForceRadioTrackListPosition(radioStation, trackListName, timeOffsetMilliseconds) end

---@param toggle boolean
function ForceRenderInGameUi(toggle) end

---@param entity Entity
---@param interior integer
---@param roomHashKey Hash|string
function ForceRoomForEntity(entity, interior, roomHashKey) end

---@param interiorID integer
---@param roomHashKey Hash|string
function ForceRoomForGameViewport(interiorID, roomHashKey) end

---@param enabled boolean
function ForceSnowPass(enabled) end

function ForceSocialClubUpdate() end

---@return unknown
function ForceSonarBlipsThisFrame() end

---@param submarine integer
---@param time integer
function ForceSubmarineNeurtalBuoyancy(submarine, time) end

---@param vehicle integer
---@param toggle boolean
function ForceSubmarineSurfaceMode(vehicle, toggle) end

---@param vehicle integer
---@param gameObjectName string
function ForceUseAudioGameObject(vehicle, gameObjectName) end

---@param vehicle integer
---@param gameObjectName string
function ForceVehicleEngineAudio(vehicle, gameObjectName) end

---@param vehicle integer
---@param force boolean
function ForceVehicleEngineSynth(vehicle, force) end

---@param x number
---@param y number
---@param z number
---@param rad number
---@param p4 unknown
---@param p5 unknown
---@return unknown
function FormatFocusHeading(x, y, z, rad, p4, p5) end

---@param time integer
---@return string
function FormatTime(time) end

function FreeMemoryForHighQualityPhoto() end

function FreeMemoryForLowQualityPhoto() end

function FreeMemoryForMissionCreatorPhoto() end

---@param entity Entity
---@param toggle boolean
function FreezeEntityPosition(entity, toggle) end

function FreezeMicrophone() end

---@param ped Ped
function FreezePedCameraRotation(ped) end

---@param radioStation string
function FreezeRadioStation(radioStation) end

---@param vehicle integer
function FullyChargeNitrous(vehicle) end

---@param x number
---@param y number
---@param z number
---@param p3 boolean
---@return integer
---@return integer direction
---@return number vehicle
---@return number distToNxJunction
function GenerateDirectionsToCoord(x, y, z, p3) end

---@param worldX number
---@param worldY number
---@param worldZ number
---@return boolean
---@return number screenX
---@return number screenY
function Get_2dCoordFrom_3dCoord(worldX, worldY, worldZ) end

---@param achievement integer
---@return integer
function GetAchievementProgress(achievement) end

---@param achievement integer
---@return integer
function GetAchievementProgression(achievement) end

---@return table
function GetActivePlayers() end

---@return integer x
---@return integer y
function GetActiveScreenResolution() end

---@param vehicle integer
---@return integer
function GetActiveVehicleMissionType(vehicle) end

---@return integer
function GetActiveWebsiteId() end

---@return integer x
---@return integer y
function GetActualScreenResolution() end

---@param ped Ped
---@return integer
function GetAiBlip(ped) end

---@param ped Ped
---@return integer
function GetAiBlip_2(ped) end

---@param aircraft integer
---@return integer
function GetAircraftBombCount(aircraft) end

---@param aircraft integer
---@return integer
function GetAircraftCountermeasureCount(aircraft) end

---@return integer
function GetAllocatedStackSize() end

---@return boolean
function GetAllowMovementWhileZoomed() end

---@return table
function GetAllRopes() end

---@return table
function GetAllTrackJunctions() end

---@return table
function GetAllVehicleModels() end

---@return integer
---@return integer vehArray
function GetAllVehicles() end

---@return number
function GetAmbientPedRangeMultiplier() end

---@return number
function GetAmbientVehicleRangeMultiplier() end

---@param ped Ped
---@return Hash
function GetAmbientVoiceNameHash(ped) end

---@param ped Ped
---@param weaponHash Hash|string
---@return boolean
---@return integer ammo
function GetAmmoInClip(ped, weaponHash) end

---@param ped Ped
---@param weaponhash Hash|string
---@return integer
function GetAmmoInPedWeapon(ped, weaponhash) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function GetAngleBetween_2dVectors(x1, y1, x2, y2) end

---@param animDict string
---@param animName string
---@return number
function GetAnimDuration(animDict, animName) end

---@param animDict string
---@param animName string
---@param x number
---@param y number
---@param z number
---@param xRot number
---@param yRot number
---@param zRot number
---@param p8 number
---@param p9 integer
---@return vector3
function GetAnimInitialOffsetPosition(animDict, animName, x, y, z, xRot, yRot, zRot, p8, p9) end

---@param animDict string
---@param animName string
---@param x number
---@param y number
---@param z number
---@param xRot number
---@param yRot number
---@param zRot number
---@param p8 number
---@param p9 integer
---@return vector3
function GetAnimInitialOffsetRotation(animDict, animName, x, y, z, xRot, yRot, zRot, p8, p9) end

---@param aircraft integer
---@return boolean
function GetAreBombBayDoorsOpen(aircraft) end

---@param physicalAspect boolean
---@return number
function GetAspectRatio(physicalAspect) end

---@return integer
function GetAudibleMusicTrackTextId() end

---@param p3 unknown
---@param p4 boolean
---@return boolean
---@return unknown p1
---@return unknown p2
function GetBaseElementMetadata(p3, p4) end

---@return integer
function GetBenchmarkIterationsFromCommandLine() end

---@return integer
function GetBenchmarkPassFromCommandLine() end

---@return number
function GetBenchmarkTime() end

---@param ped Ped
---@param ignoreAmmoCount boolean
---@return Hash
function GetBestPedWeapon(ped, ignoreAmmoCount) end

---@param binkMovie integer
---@return number
function GetBinkMovieTime(binkMovie) end

---@param var integer
---@param rangeStart integer
---@param rangeEnd integer
---@return integer
function GetBitsInRange(var, rangeStart, rangeEnd) end

---@param blip integer
---@return integer
function GetBlipAlpha(blip) end

---@param blip integer
---@return integer
function GetBlipColour(blip) end

---@param blip integer
---@return vector3
function GetBlipCoords(blip) end

---@param entity Entity
---@return integer
function GetBlipFromEntity(entity) end

---@param blip integer
---@return integer
function GetBlipHudColour(blip) end

---@param blip integer
---@return vector3
function GetBlipInfoIdCoord(blip) end

---@param blip integer
---@return integer
function GetBlipInfoIdDisplay(blip) end

---@param blip integer
---@return Entity
function GetBlipInfoIdEntityIndex(blip) end

---@return integer
function GetBlipInfoIdIterator() end

---@param blip integer
---@return integer
function GetBlipInfoIdPickupIndex(blip) end

---@param blip integer
---@return integer
function GetBlipInfoIdType(blip) end

---@param blip integer
---@return integer
function GetBlipRotation(blip) end

---@param blip integer
---@return integer
function GetBlipSprite(blip) end

---@param boat integer
---@return boolean
function GetBoatAnchor(boat) end

---@param vehicle integer
---@return number
function GetBoatBoomPositionRatio(vehicle) end

---@param vehicle integer
---@param p1 boolean
function GetBoatBoomPositionRatio_2(vehicle, p1) end

---@param vehicle integer
---@param p1 boolean
function GetBoatBoomPositionRatio_3(vehicle, p1) end

---@param modelHash Hash|string
---@return number
function GetBoatVehicleModelAgility(modelHash) end

---@param toggle boolean
function GetBroadcastFinshedLosSound(toggle) end

---@param x number
---@param y number
---@return integer
function GetCalmingQuadAtCoords(x, y) end

---@param waterQuad integer
---@return boolean
---@return integer minX
---@return integer minY
---@return integer maxX
---@return integer maxY
function GetCalmingQuadBounds(waterQuad) end

---@return integer
function GetCalmingQuadCount() end

---@param waterQuad integer
---@return boolean
---@return number calmingQuadDampening
function GetCalmingQuadDampening(waterQuad) end

---@return integer
function GetCamActiveViewModeContext() end

---@param cam integer
---@return number
function GetCamAnimCurrentPhase(cam) end

---@param cam integer
---@return vector3
function GetCamCoord(cam) end

---@param cam integer
---@return number
function GetCamDofStrength(cam) end

---@param cam integer
---@return number
function GetCamFarClip(cam) end

---@param cam integer
---@return number
function GetCamFarDof(cam) end

---@param cam integer
---@return number
function GetCamFov(cam) end

---@param camera integer
---@return vector3 rightVector
---@return vector3 forwardVector
---@return vector3 upVector
---@return vector3 position
function GetCamMatrix(camera) end

---@param cam integer
---@return number
function GetCamNearClip(cam) end

---@param cam integer
---@return number
function GetCamNearDof(cam) end

---@param cam integer
---@param rotationOrder integer
---@return vector3
function GetCamRot(cam, rotationOrder) end

---@param cam integer
---@return integer
function GetCamSplineNodeIndex(cam) end

---@param cam integer
---@return number
function GetCamSplineNodePhase(cam) end

---@param cam integer
---@return number
function GetCamSplinePhase(cam) end

---@param context integer
---@return integer
function GetCamViewModeForContext(context) end

---@param vehicle integer
---@return boolean
function GetCanVehicleJump(vehicle) end

---@param cargobob integer
---@return vector3
function GetCargobobHookPosition(cargobob) end

---@return integer
function GetCauseOfMostRecentForceCleanup() end

---@param entity Entity
---@return vector3
function GetCgoffset(entity) end

---@param p0 integer
---@return string
function GetClipSetForScriptedGunTask(p0) end

---@return integer
function GetClockDayOfMonth() end

---@return integer
function GetClockDayOfWeek() end

---@return integer
function GetClockHours() end

---@return integer
function GetClockMinutes() end

---@return integer
function GetClockMonth() end

---@return integer
function GetClockSeconds() end

---@return integer
function GetClockYear() end

---@param blipSprite integer
---@return integer
function GetClosestBlipOfType(blipSprite) end

---@param x number
---@param y number
---@param z number
---@return boolean
---@return vector3 outPosition
function GetClosestFirePos(x, y, z) end

---@param x number
---@param y number
---@param z number
---@param unknown1 number
---@param unknown2 integer
---@return boolean
---@return vector3 outPosition
function GetClosestMajorVehicleNode(x, y, z, unknown1, unknown2) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param isMission boolean
---@param p6 boolean
---@param p7 boolean
---@return integer
function GetClosestObjectOfType(x, y, z, radius, modelHash, isMission, p6, p7) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 boolean
---@param p5 boolean
---@param p7 boolean
---@param p8 boolean
---@param pedType integer
---@return boolean
---@return Ped outPed
function GetClosestPed(x, y, z, radius, p4, p5, p7, p8, pedType) end

---@param x number
---@param y number
---@param z number
---@param minimumEdgeLength number
---@param minimumLaneCount integer
---@param onlyMajorRoads boolean
---@return boolean
---@return vector3 srcNode
---@return vector3 targetNode
---@return integer laneCountForward
---@return integer laneCountBackward
---@return number width
function GetClosestRoad(x, y, z, minimumEdgeLength, minimumLaneCount, onlyMajorRoads) end

---@param position vector3
---@param radius number
---@return table
function GetClosestTrackNodes(position, radius) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param flags integer
---@return integer
function GetClosestVehicle(x, y, z, radius, modelHash, flags) end

---@param x number
---@param y number
---@param z number
---@param nodeType integer
---@param p5 number
---@param p6 number
---@return boolean
---@return vector3 outPosition
function GetClosestVehicleNode(x, y, z, nodeType, p5, p6) end

---@param x number
---@param y number
---@param z number
---@param nodeType integer
---@param p6 number
---@param p7 integer
---@return boolean
---@return vector3 outPosition
---@return number outHeading
function GetClosestVehicleNodeWithHeading(x, y, z, nodeType, p6, p7) end

---@return number
function GetCloudHatOpacity() end

---@return integer
function GetCloudTimeAsInt() end

---@return string
function GetCloudTimeAsString() end

---@param entity Entity
---@return vector3
function GetCollisionNormalOfLastHitForEntity(entity) end

---@param ped Ped
---@param p1 integer
---@return number
function GetCombatFloat(ped, p1) end

---@param index integer
---@param index2 integer
---@return string
function GetCommerceItemCat(index, index2) end

---@param index integer
---@return string
function GetCommerceItemId(index) end

---@param index integer
---@return string
function GetCommerceItemName(index) end

---@param index integer
---@return integer
function GetCommerceItemNumCats(index) end

---@param index integer
---@return string
function GetCommerceItemTexturename(index) end

---@param index integer
---@return string
function GetCommerceProductPrice(index) end

---@param p0 integer
---@return integer
function GetContentCategory(p0) end

---@param p0 unknown
---@return integer
function GetContentDescriptionHash(p0) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function GetContentFileVersion(p0, p1) end

---@param p0 integer
---@return string
function GetContentId(p0) end

---@param p0 integer
---@return string
function GetContentUserId(p0) end

---@param padIndex integer
---@param controlGroup integer
---@param p2 boolean
---@return string
function GetControlGroupInstructionalButton(padIndex, controlGroup, p2) end

---@param padIndex integer
---@param control integer
---@param p2 boolean
---@return string
function GetControlInstructionalButton(padIndex, control, p2) end

---@param padIndex integer
---@param control integer
---@return number
function GetControlNormal(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return number
function GetControlUnboundNormal(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return integer
function GetControlValue(padIndex, control) end

---@param vehicle integer
---@return integer
function GetConvertibleRoofState(vehicle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param rotationOrder integer
---@return unknown
---@return vector3 outPosition
---@return vector3 outRotation
function GetCoordsAndRotationOfClosestObjectOfType(x, y, z, radius, modelHash, rotationOrder) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param projectileHash Hash|string
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 projectilePos
function GetCoordsOfProjectileTypeInArea(x1, y1, z1, x2, y2, z2, projectileHash, ownedByPlayer) end

---@param ped Ped
---@param weaponHash Hash|string
---@param distance number
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 outCoords
function GetCoordsOfProjectileTypeWithinDistance(ped, weaponHash, distance, ownedByPlayer) end

---@return Hash
function GetCurrentFrontendMenu() end

---@return Hash
function GetCurrentFrontendMenuVersion() end

---@return string
function GetCurrentGameName() end

---@return number
function GetCurrentIntensity() end

---@return integer
function GetCurrentLanguage() end

---@return integer
function GetCurrentLanguageId() end

---@return integer
function GetCurrentNotification() end

---@return integer
function GetCurrentNumberOfCloudPhotos() end

---@return integer
function GetCurrentNumberOfPhotos() end

---@param ped Ped
---@return boolean
---@return Hash weaponHash
function GetCurrentPedVehicleWeapon(ped) end

---@param ped Ped
---@param p2 boolean
---@return boolean
---@return Hash weaponHash
function GetCurrentPedWeapon(ped, p2) end

---@param ped Ped
---@return Entity
function GetCurrentPedWeaponEntityIndex(ped) end

---@param vehicle integer
---@return integer
function GetCurrentPlaybackForVehicle(vehicle) end

---@param radioStationName string
---@return integer
function GetCurrentRadioStationHash(radioStationName) end

---@param radioStationName string
---@return Hash
function GetCurrentRadioTrackName(radioStationName) end

---@param radioStationName string
---@return integer
function GetCurrentRadioTrackPlaybackTime(radioStationName) end

---@return integer
function GetCurrentScriptedConversationLine() end

---@return string
function GetCurrentServerEndpoint() end

---@param radioStationName string
---@return Hash
function GetCurrentTrackSoundName(radioStationName) end

---@return integer
function GetCurrentWebpageId() end

---@return integer
function GetCurrentWebsiteId() end

---@param cutsceneName string
---@return integer
function GetCutFileNumSections(cutsceneName) end

---@return integer
function GetCutsceneEndTime() end

---@return integer
function GetCutscenePlayTime() end

---@return integer
function GetCutsceneSectionPlaying() end

---@return integer
function GetCutsceneTime() end

---@return integer
function GetCutsceneTotalDuration() end

---@param posixTime integer
---@return unknown timeStructure
function GetDateAndTimeFromUnixEpoch(posixTime) end

---@param ped Ped
---@param p1 number
---@param p2 number
---@return vector3
function GetDeadPedPickupCoords(ped, p1, p2) end

---@return integer
function GetDebugCamera() end

---@param decal integer
---@return number
function GetDecalWashLevel(decal) end

---@return number
function GetDeepOceanScaler() end

---@return integer
function GetDefaultScriptRendertargetRenderId() end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param name string
---@return integer
function GetDesObject(x, y, z, radius, name) end

---@param object integer
---@return number
function GetDesObjectAnimProgress(object) end

---@param object integer
---@return integer
function GetDesObjectState(object) end

---@param padIndex integer
---@param control integer
---@return number
function GetDisabledControlNormal(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return number
function GetDisabledControlUnboundNormal(padIndex, control) end

---@param modelHash Hash|string
---@return string
function GetDisplayNameFromVehicleModel(modelHash) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param useZ boolean
---@return number
function GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, useZ) end

---@param dlcVehicleIndex integer
---@return boolean
---@return unknown outData
function GetDlcVehicleData(dlcVehicleIndex) end

---@param dlcVehicleIndex integer
---@return integer
function GetDlcVehicleFlags(dlcVehicleIndex) end

---@param dlcVehicleIndex integer
---@return Hash
function GetDlcVehicleModel(dlcVehicleIndex) end

---@param hash Hash|string
---@return Hash
function GetDlcVehicleModLockHash(hash) end

---@param dlcWeaponIndex integer
---@param dlcWeapCompIndex integer
---@return boolean
---@return integer ComponentDataPtr
function GetDlcWeaponComponentData(dlcWeaponIndex, dlcWeapCompIndex) end

---@param dlcWeaponIndex integer
---@param dlcWeapCompIndex integer
---@return boolean
---@return integer ComponentDataPtr
function GetDlcWeaponComponentDataSp(dlcWeaponIndex, dlcWeapCompIndex) end

---@param dlcWeaponIndex integer
---@return boolean
---@return integer outData
function GetDlcWeaponData(dlcWeaponIndex) end

---@param dlcWeaponIndex integer
---@return boolean
---@return integer outData
function GetDlcWeaponDataSp(dlcWeaponIndex) end

---@param vehicle integer
---@return boolean
function GetDoesVehicleHaveTombstone(vehicle) end

---@param vehicle integer
---@return boolean
function GetDriftTyresEnabled(vehicle) end

---@param duiObject integer
---@return string
function GetDuiHandle(duiObject) end

---@param entity Entity
---@return unknown
function GetEntityAddress(entity) end

---@param entity Entity
---@return integer
function GetEntityAlpha(entity) end

---@param entity Entity
---@param animDict string
---@param animName string
---@return number
function GetEntityAnimCurrentTime(entity, animDict, animName) end

---@param entity Entity
---@param animDict string
---@param animName string
---@return number
function GetEntityAnimTotalTime(entity, animDict, animName) end

---@param entity Entity
---@return string
function GetEntityArchetypeName(entity) end

---@param entity Entity
---@return Entity
function GetEntityAttachedTo(entity) end

---@param vehicle integer
---@return Entity
function GetEntityAttachedToCargobob(vehicle) end

---@param towTruck integer
---@return Entity
function GetEntityAttachedToTowTruck(towTruck) end

---@param entity Entity
---@return integer
function GetEntityBoneCount(entity) end

---@param entity Entity
---@param boneName string
---@return integer
function GetEntityBoneIndexByName(entity, boneName) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function GetEntityBonePosition_2(entity, boneIndex) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function GetEntityBoneRotation(entity, boneIndex) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function GetEntityBoneRotationLocal(entity, boneIndex) end

---@param entity Entity
---@return boolean
function GetEntityCanBeDamaged(entity) end

---@param entity Entity
---@return boolean
function GetEntityCollisionDisabled(entity) end

---@param entity Entity
---@return boolean
function GetEntityCollisonDisabled(entity) end

---@param entity Entity
---@return vector3
function GetEntityForwardVector(entity) end

---@param entity Entity
---@return number
function GetEntityForwardX(entity) end

---@param entity Entity
---@return number
function GetEntityForwardY(entity) end

---@param entity Entity
---@return number
function GetEntityHeadingFromEulers(entity) end

---@param entity Entity
---@return integer
function GetEntityHealth(entity) end

---@param entity Entity
---@param X number
---@param Y number
---@param Z number
---@param atTop boolean
---@param inWorldCoords boolean
---@return number
function GetEntityHeight(entity, X, Y, Z, atTop, inWorldCoords) end

---@param entity Entity
---@return number
function GetEntityHeightAboveGround(entity) end

---@param mapdata integer
---@param entity integer
---@return integer
function GetEntityIndexFromMapdata(mapdata, entity) end

---@param cutsceneEntName string
---@param modelHash Hash|string
---@return Entity
function GetEntityIndexOfCutsceneEntity(cutsceneEntName, modelHash) end

---@param cutsceneEntName string
---@param modelHash Hash|string
---@return Entity
function GetEntityIndexOfRegisteredEntity(cutsceneEntName, modelHash) end

---@param explosionType integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number
---@return Entity
function GetEntityInsideExplosionArea(explosionType, x1, y1, z1, x2, y2, z2, radius) end

---@param explosionType integer
---@param x number
---@param y number
---@param z number
---@param radius number
---@return Entity
function GetEntityInsideExplosionSphere(explosionType, x, y, z, radius) end

---@param entity Entity
---@return integer
function GetEntityLodDist(entity) end

---@param entity Entity
---@return boolean
---@return integer mapdataHandle
---@return integer entityHandle
function GetEntityMapdataOwner(entity) end

---@param entity Entity
---@return vector3 forwardVector
---@return vector3 rightVector
---@return vector3 upVector
---@return vector3 position
function GetEntityMatrix(entity) end

---@param entity Entity
---@return integer
function GetEntityMaxHealth(entity) end

---@param entity Entity
---@return number
function GetEntityPhysicsHeading(entity) end

---@param entity Entity
---@param modelHash Hash|string
---@return Entity
function GetEntityPickup(entity, modelHash) end

---@param entity Entity
---@return number
function GetEntityPitch(entity) end

---@param player integer
---@return boolean
---@return Entity entity
function GetEntityPlayerIsFreeAimingAt(player) end

---@param entity Entity
---@return integer
function GetEntityPopulationType(entity) end

---@param entity Entity
---@return boolean
---@return boolean bulletProof
---@return boolean fireProof
---@return boolean explosionProof
---@return boolean collisionProof
---@return boolean meleeProof
---@return boolean steamProof
---@return boolean p7
---@return boolean drownProof
function GetEntityProofs(entity) end

---@param entity Entity
---@return number x
---@return number y
---@return number z
---@return number w
function GetEntityQuaternion(entity) end

---@param entity Entity
---@return number
function GetEntityRoll(entity) end

---@param entity Entity
---@return vector3
function GetEntityRotationVelocity(entity) end

---@param entity Entity
---@return string
---@return integer script
function GetEntityScript(entity) end

---@param entity Entity
---@return number
function GetEntitySpeed(entity) end

---@param entity Entity
---@param relative boolean
---@return vector3
function GetEntitySpeedVector(entity, relative) end

---@param entity Entity
---@return number
function GetEntitySubmergedLevel(entity) end

---@param entity Entity
---@return integer
function GetEntityType(entity) end

---@param entity Entity
---@return number
function GetEntityUprightValue(entity) end

---@param entity Entity
---@return vector3
function GetEntityVelocity(entity) end

---@param vehicle integer
---@param doorIndex integer
---@return vector3
function GetEntryPositionOfDoor(vehicle, doorIndex) end

---@param eventGroup integer
---@param eventIndex integer
---@return integer
function GetEventAtIndex(eventGroup, eventIndex) end

---@param eventGroup integer
---@param eventIndex integer
---@param eventDataSize integer
---@return boolean
---@return integer eventData
function GetEventData(eventGroup, eventIndex, eventDataSize) end

---@param eventGroup integer
---@param eventIndex integer
---@return boolean
function GetEventExists(eventGroup, eventIndex) end

---@param resource string
---@param key string
---@return number
function GetExternalKvpFloat(resource, key) end

---@param resource string
---@param key string
---@return integer
function GetExternalKvpInt(resource, key) end

---@param resource string
---@param key string
---@return string
function GetExternalKvpString(resource, key) end

---@return boolean
function GetExtraContentPackHasBeenInstalled() end

---@return integer
function GetExtraTimecycleModifierIndex() end

---@return integer
function GetFakeWantedLevel() end

---@return number
function GetFallDamageLandOnFootMultiplier() end

---@return number
function GetFallDamageMultiplier() end

---@param labelName string
---@return string
function GetFilenameForAudioConversation(labelName) end

---@return vector3
function GetFinalRenderedCamCoord() end

---@return number
function GetFinalRenderedCamFarClip() end

---@return number
function GetFinalRenderedCamFarDof() end

---@return number
function GetFinalRenderedCamFov() end

---@return number
function GetFinalRenderedCamMotionBlurStrength() end

---@return number
function GetFinalRenderedCamNearClip() end

---@return number
function GetFinalRenderedCamNearDof() end

---@param rotationOrder integer
---@return vector3
function GetFinalRenderedCamRot(rotationOrder) end

---@param player integer
---@return number
function GetFinalRenderedInWhenFriendlyFov(player) end

---@param player integer
---@param rotationOrder integer
---@return vector3
function GetFinalRenderedInWhenFriendlyRot(player, rotationOrder) end

---@param blipSprite integer
---@return integer
function GetFirstBlipInfoId(blipSprite) end

---@param type integer
---@return integer
function GetFirstParentIdForPedType(type) end

---@return number
function GetFirstPersonAimCamZoomFactor() end

---@param p0 number
---@param p1 integer
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 integer
---@param p8 integer
---@return Ped
function GetFocusPedOnScreen(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@return integer
function GetFollowPedCamViewMode() end

---@return integer
function GetFollowPedCamZoomLevel() end

---@return integer
function GetFollowVehicleCamViewMode() end

---@return integer
function GetFollowVehicleCamZoomLevel() end

---@param componentHash Hash|string
---@param forcedComponentIndex integer
---@return Hash nameHash
---@return integer enumValue
---@return integer componentType
function GetForcedComponent(componentHash, forcedComponentIndex) end

---@param componentHash Hash|string
---@param forcedPropIndex integer
---@return Hash nameHash
---@return integer enumValue
---@return integer anchorPoint
function GetForcedProp(componentHash, forcedPropIndex) end

---@return integer
function GetFrameCount() end

---@return number
function GetFrameTime() end

---@param stackSize integer
---@return integer
function GetFreeStackSlotsCount(stackSize) end

---@return number
function GetFuelConsumptionRateMultiplier() end

---@return boolean
function GetFuelConsumptionState() end

---@return vector3
function GetGameplayCamCoord() end

---@return vector3
function GetGameplayCamCoords() end

---@return number
function GetGameplayCamFarClip() end

---@return number
function GetGameplayCamFarClip_2() end

---@return number
function GetGameplayCamFarDof() end

---@return number
function GetGameplayCamFov() end

---@return number
function GetGameplayCamNearClip() end

---@return number
function GetGameplayCamNearDof() end

---@return number
function GetGameplayCamRelativeHeading() end

---@return number
function GetGameplayCamRelativePitch() end

---@param rotationOrder integer
---@return vector3
function GetGameplayCamRot(rotationOrder) end

---@param rotationOrder integer
---@return vector3
function GetGameplayCamRot_2(rotationOrder) end

---@return number
function GetGameplayCamZoom() end

---@return string
function GetGameVersion() end

---@param flagIndex integer
---@return integer
function GetGlobalActionscriptFlag(flagIndex) end

---@return string
function GetGlobalCharBuffer() end

---@return number
function GetGlobalPassengerMassMultiplier() end

---@return integer
function GetGlobalWaterType() end

---@return boolean
function GetGpsBlipRouteFound() end

---@return integer
function GetGpsBlipRouteLength() end

---@param bStartAtPlayerPos boolean
---@param fDistanceAlongRoute number
---@param slotType integer
---@return boolean
---@return vector3 result
function GetGpsWaypointRouteEnd(bStartAtPlayerPos, fDistanceAlongRoute, slotType) end

---@param x number
---@param y number
---@param z number
---@return boolean
---@return number groundZ
---@return vector3 normal
function GetGroundZAndNormalFor_3dCoord(x, y, z) end

---@param x number
---@param y number
---@param z number
---@return boolean
---@return number groundZ
---@return vector3 normal
function GetGroundZCoordWithOffsets(x, y, z) end

---@param x number
---@param y number
---@param z number
---@param waterAsGround boolean
---@return boolean
---@return number groundZ
function GetGroundZExcludingObjectsFor_3dCoord(x, y, z, waterAsGround) end

---@param x number
---@param y number
---@param z number
---@param includeWater boolean
---@return boolean
---@return number groundZ
function GetGroundZFor_3dCoord(x, y, z, includeWater) end

---@param x number
---@param y number
---@param z number
---@param waterAsGround boolean
---@return boolean
---@return number groundZ
function GetGroundZFor_3dCoord_2(x, y, z, waterAsGround) end

---@param groupID integer
---@return unknown unknown
---@return integer sizeInMembers
function GetGroupSize(groupID) end

---@param hairColorIndex integer
---@return integer outR
---@return integer outG
---@return integer outB
function GetHairRgbColor(hairColorIndex) end

---@param string string
---@return Hash
function GetHashKey(string) end

---@param entity Entity
---@param componentId integer
---@param drawableVariant integer
---@param textureVariant integer
---@return Hash
function GetHashNameForComponent(entity, componentId, drawableVariant, textureVariant) end

---@param entity Entity
---@param componentId integer
---@param propIndex integer
---@param propTextureIndex integer
---@return Hash
function GetHashNameForProp(entity, componentId, propIndex, propTextureIndex) end

---@param x number
---@param y number
---@param z number
---@return Hash
function GetHashOfMapAreaAtCoords(x, y, z) end

---@return Hash
function GetHashOfThisScriptName() end

---@param vehicle integer
---@return boolean
function GetHasLowerableWheels(vehicle) end

---@param object integer
---@return boolean
function GetHasObjectFragInst(object) end

---@param vehicle integer
---@return boolean
function GetHasRetractableWheels(vehicle) end

---@param vehicle integer
---@return boolean
function GetHasRocketBoost(vehicle) end

---@param dx number
---@param dy number
---@return number
function GetHeadingFromVector_2d(dx, dy) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function GetHeightmapBottomZForArea(x1, y1, x2, y2) end

---@param x number
---@param y number
---@return number
function GetHeightmapBottomZForPosition(x, y) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function GetHeightmapTopZForArea(x1, y1, x2, y2) end

---@param x number
---@param y number
---@return number
function GetHeightmapTopZForPosition(x, y) end

---@param vehicle integer
---@return number
function GetHeliEngineHealth(vehicle) end

---@param vehicle integer
---@return number
function GetHeliMainRotorHealth(vehicle) end

---@param vehicle integer
---@return number
function GetHeliTailBoomHealth(vehicle) end

---@param heli integer
---@return number
function GetHeliTailRotorHealth(heli) end

---@param hudColorIndex integer
---@return integer r
---@return integer g
---@return integer b
---@return integer a
function GetHudColour(hudColorIndex) end

---@param id integer
---@return integer horizontalAlign
---@return integer verticalAlign
function GetHudComponentAlign(id) end

---@param id integer
---@return string
function GetHudComponentName(id) end

---@param id integer
---@return vector3
function GetHudComponentPosition(id) end

---@param id integer
---@return vector3
function GetHudComponentSize(id) end

---@param worldX number
---@param worldY number
---@param worldZ number
---@return boolean
---@return number screenX
---@return number screenY
function GetHudScreenPositionFromWorldPosition(worldX, worldY, worldZ) end

---@param vehicle integer
---@param wheelId integer
---@return number
function GetHydraulicWheelValue(vehicle, wheelId) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return integer
function GetIdealPlayerSwitchType(x1, y1, z1, x2, y2, z2) end

---@return integer
function GetIdOfNextThreadInEnumeration() end

---@return integer
function GetIdOfThisThread() end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function GetIndexedItemInItemset(p0, p1) end

---@return integer
function GetIndexOfCurrentLevel() end

---@param x number
---@param y number
---@param z number
---@return integer
function GetInteriorAtCoords(x, y, z) end

---@param x number
---@param y number
---@param z number
---@param interiorType string
---@return integer
function GetInteriorAtCoordsWithType(x, y, z, interiorType) end

---@param x number
---@param y number
---@param z number
---@param typeHash Hash|string
---@return integer
function GetInteriorAtCoordsWithTypehash(x, y, z, typeHash) end

---@param interiorId integer
---@return number bbMinX
---@return number bbMinY
---@return number bbMinZ
---@return number bbMaxX
---@return number bbMaxY
---@return number bbMaxZ
function GetInteriorEntitiesExtents(interiorId) end

---@param x number
---@param y number
---@param z number
---@return integer
function GetInteriorFromCollision(x, y, z) end

---@param entity Entity
---@return integer
function GetInteriorFromEntity(entity) end

---@return integer
function GetInteriorFromGameplayCam() end

---@return integer
function GetInteriorFromPrimaryView() end

---@param interior integer
---@return integer
function GetInteriorGroupId(interior) end

---@param interior integer
---@return number
function GetInteriorHeading(interior) end

---@param interior integer
---@return vector3 position
---@return Hash nameHash
function GetInteriorInfo(interior) end

---@param interior integer
---@return vector3 position
---@return Hash nameHash
function GetInteriorLocationAndNamehash(interior) end

---@param interiorId integer
---@param portalIndex integer
---@param cornerIndex integer
---@return number posX
---@return number posY
---@return number posZ
function GetInteriorPortalCornerPosition(interiorId, portalIndex, cornerIndex) end

---@param interiorId integer
---@return integer
function GetInteriorPortalCount(interiorId) end

---@param interiorId integer
---@param portalIndex integer
---@param entityIndex integer
---@return integer
function GetInteriorPortalEntityArchetype(interiorId, portalIndex, entityIndex) end

---@param interiorId integer
---@param portalIndex integer
---@return integer
function GetInteriorPortalEntityCount(interiorId, portalIndex) end

---@param interiorId integer
---@param portalIndex integer
---@param entityIndex integer
---@return integer
function GetInteriorPortalEntityFlag(interiorId, portalIndex, entityIndex) end

---@param interiorId integer
---@param portalIndex integer
---@param entityIndex integer
---@return number posX
---@return number posY
---@return number posZ
function GetInteriorPortalEntityPosition(interiorId, portalIndex, entityIndex) end

---@param interiorId integer
---@param portalIndex integer
---@param entityIndex integer
---@return number rotX
---@return number rotY
---@return number rotZ
---@return number rotW
function GetInteriorPortalEntityRotation(interiorId, portalIndex, entityIndex) end

---@param interiorId integer
---@param portalIndex integer
---@return integer
function GetInteriorPortalFlag(interiorId, portalIndex) end

---@param interiorId integer
---@param portalIndex integer
---@return integer
function GetInteriorPortalRoomFrom(interiorId, portalIndex) end

---@param interiorId integer
---@param portalIndex integer
---@return integer
function GetInteriorPortalRoomTo(interiorId, portalIndex) end

---@param interiorId integer
---@return number posX
---@return number posY
---@return number posZ
function GetInteriorPosition(interiorId) end

---@param interiorId integer
---@return integer
function GetInteriorRoomCount(interiorId) end

---@param interiorId integer
---@param roomIndex integer
---@return number bbMinX
---@return number bbMinY
---@return number bbMinZ
---@return number bbMaxX
---@return number bbMaxY
---@return number bbMaxZ
function GetInteriorRoomExtents(interiorId, roomIndex) end

---@param interiorId integer
---@param roomIndex integer
---@return integer
function GetInteriorRoomFlag(interiorId, roomIndex) end

---@param interiorId integer
---@param roomHash integer
---@return integer
function GetInteriorRoomIndexByHash(interiorId, roomHash) end

---@param interiorId integer
---@param roomIndex integer
---@return string
function GetInteriorRoomName(interiorId, roomIndex) end

---@param interiorId integer
---@param roomIndex integer
---@return integer
function GetInteriorRoomTimecycle(interiorId, roomIndex) end

---@param interiorId integer
---@return number rotx
---@return number rotY
---@return number rotZ
---@return number rotW
function GetInteriorRotation(interiorId) end

---@param entity integer
---@param p1 unknown
---@return boolean
function GetIsArenaPropPhysicsDisabled(entity, p1) end

---@return boolean
function GetIsAutoSaveOff() end

---@param vehicle integer
---@return boolean
function GetIsBoatCapsized(vehicle) end

---@param vehicle integer
---@param doorIndex integer
---@return boolean
function GetIsDoorValid(vehicle, doorIndex) end

---@return boolean
function GetIsHidef() end

---@param vehicle integer
---@return boolean
function GetIsLeftVehicleHeadlightDamaged(vehicle) end

---@return boolean
function GetIsLoadingScreenActive() end

---@param toggle boolean
function GetIsMultiplayerBrief(toggle) end

---@param ped Ped
---@param gadgetHash Hash|string
---@return boolean
function GetIsPedGadgetEquipped(ped, gadgetHash) end

---@param xCoord number
---@param yCoord number
---@param zCoord number
---@param radius number
---@return boolean
function GetIsPetrolDecalInRange(xCoord, yCoord, zCoord, radius) end

---@param playerId integer
---@return boolean
function GetIsPlayerDrivingOnHighway(playerId) end

---@return boolean
function GetIsPlayerInAnimalForm() end

---@return boolean
function GetIsPreloadedConversationReady() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param projectileHash Hash|string
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 projectilePos
function GetIsProjectileTypeInArea(x1, y1, z1, x2, y2, z2, projectileHash, ownedByPlayer) end

---@param vehicle integer
---@return boolean
function GetIsRightVehicleHeadlightDamaged(vehicle) end

---@param nodeID integer
---@return boolean
function GetIsSlowRoadFlag(nodeID) end

---@param vehicle integer
---@return boolean
function GetIsSubmarineVehicleTransformed(vehicle) end

---@param ped Ped
---@param taskIndex integer
---@return boolean
function GetIsTaskActive(ped, taskIndex) end

---@return boolean
function GetIsUsingAlternateDriveby() end

---@param vehicleModel Hash|string
---@return boolean
function GetIsVehicleElectric(vehicleModel) end

---@param vehicle integer
---@return boolean
function GetIsVehicleEmpDisabled(vehicle) end

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
---@return boolean
function GetIsVehicleShuntBoostActive(vehicle) end

---@param name string
---@return boolean
function GetIsWaypointRecordingLoaded(name) end

---@param vehicle integer
---@return boolean
function GetIsWheelsLoweredStateActive(vehicle) end

---@return boolean
function GetIsWidescreen() end

---@param x integer
---@return unknown
function GetItemsetSize(x) end

---@param ped Ped
---@return Ped
function GetJackTarget(ped) end

---@param entity Entity
---@return Hash
function GetKeyForEntityInRoom(entity) end

---@return number
function GetKillFallHeight() end

---@param labelName string
---@return string
function GetLabelText(labelName) end

---@param vehicle integer
---@return integer
function GetLandingGearState(vehicle) end

---@return integer
function GetLastDrivenVehicle() end

---@param padIndex integer
---@return boolean
function GetLastInputMethod(padIndex) end

---@param entity Entity
---@return Hash
function GetLastMaterialHitByEntity(entity) end

---@param vehicle integer
---@param seatIndex integer
---@return Ped
function GetLastPedInVehicleSeat(vehicle, seatIndex) end

---@param vehicle integer
---@return integer
function GetLastRammedVehicle(vehicle) end

---@param string string
---@return integer
function GetLengthOfLiteralString(string) end

---@param string string
---@return integer
function GetLengthOfLiteralStringInBytes(string) end

---@param string string
---@return integer
function GetLengthOfString(string) end

---@param gxt string
---@return integer
function GetLengthOfStringWithThisTextLabel(gxt) end

---@return integer
function GetLevelBlipSprite() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param planeX number
---@param planeY number
---@param planeZ number
---@param planeNormalX number
---@param planeNormalY number
---@param planeNormalZ number
---@return boolean
---@return number intersectionParameter
function GetLinePlaneIntersection(x1, y1, z1, x2, y2, z2, planeX, planeY, planeZ, planeNormalX, planeNormalY, planeNormalZ) end

---@param vehicle integer
---@param liveryIndex integer
---@return string
function GetLiveryName(vehicle, liveryIndex) end

---@return integer
function GetLocalPlayerAimState() end

---@return integer
function GetLocalPlayerAimState_2() end

---@return integer year
---@return integer month
---@return integer day
---@return integer hour
---@return integer minute
---@return integer second
function GetLocalTime() end

---@param ped Ped
---@return number
function GetLockonDistanceOfCurrentPedWeapon(ped) end

---@param ped Ped
---@return number
function GetLockonRangeOfCurrentPedWeapon(ped) end

---@return number
function GetLodscale() end

---@return integer
function GetMainPlayerBlipId() end

---@param modelHash Hash|string
---@return string
function GetMakeNameFromVehicleModel(modelHash) end

---@param makeupColorIndex integer
---@return integer outR
---@return integer outG
---@return integer outB
function GetMakeupRgbColor(makeupColorIndex) end

---@param mapDataHash integer
---@param entityInternalIdx integer
---@return boolean
---@return integer entityHandle
function GetMapdataEntityHandle(mapDataHash, entityInternalIdx) end

---@param mapDataHash integer
---@param entityInternalIdx integer
---@param matrixPtr integer
---@return boolean
function GetMapdataEntityMatrix(mapDataHash, entityInternalIdx, matrixPtr) end

---@param mapdataHandle Hash|string
---@return integer
function GetMapdataFromHashKey(mapdataHandle) end

---@param index integer
---@return boolean
---@return number zoomScale
---@return number zoomSpeed
---@return number scrollSpeed
---@return number tilesX
---@return number tilesY
function GetMapZoomDataLevel(index) end

---@param ped Ped
---@param weaponHash Hash|string
---@return boolean
---@return integer ammo
function GetMaxAmmo(ped, weaponHash) end

---@param ped Ped
---@param ammoType Hash|string
---@return boolean
---@return integer ammo
function GetMaxAmmo_2(ped, ammoType) end

---@param ped Ped
---@param ammoType Hash|string
---@return boolean
---@return integer ammo
function GetMaxAmmoByType(ped, ammoType) end

---@param ped Ped
---@param weaponHash Hash|string
---@param p2 boolean
---@return integer
function GetMaxAmmoInClip(ped, weaponHash, p2) end

---@return integer
function GetMaximumNumberOfCloudPhotos() end

---@return integer
function GetMaximumNumberOfPhotos() end

---@return integer
function GetMaximumNumberOfPhotos_2() end

---@return integer
function GetMaxNumNetworkObjects() end

---@return integer
function GetMaxNumNetworkPeds() end

---@return integer
function GetMaxNumNetworkPickups() end

---@return integer
function GetMaxNumNetworkVehicles() end

---@param ped Ped
---@return number
function GetMaxRangeOfCurrentPedWeapon(ped) end

---@return integer
function GetMaxWantedLevel() end

---@param ped Ped
---@return Ped
function GetMeleeTargetForPed(ped) end

---@param p0 Hash|string
---@return boolean
---@return unknown p1
function GetMenuPedBoolStat(p0) end

---@param p0 unknown
---@return boolean
---@return number p1
function GetMenuPedFloatStat(p0) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function GetMenuPedIntStat(p0) end

---@param p0 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return unknown p1
function GetMenuPedMaskedIntStat(p0, p2, p3) end

---@return integer
function GetMillisecondsPerGameMinute() end

---@param x number
---@param y number
---@param z number
---@return boolean
function GetMinimapFowCoordinateIsRevealed(x, y, z) end

---@return number
function GetMinimapFowDiscoveryRatio() end

---@return number
function GetMinimapRevealPercentage() end

---@return boolean
function GetMissionFlag() end

---@return vector3 position
function GetMobilePhonePosition() end

---@return integer renderId
function GetMobilePhoneRenderId() end

---@param p1 integer
---@return vector3 rotation
function GetMobilePhoneRotation(p1) end

---@param vehicle integer
---@param modType integer
---@return string
function GetModSlotName(vehicle, modType) end

---@param vehicle integer
---@param modType integer
---@param modValue integer
---@return string
function GetModTextLabel(vehicle, modType, modValue) end

---@param ped Ped
---@return Ped
function GetMount(ped) end

---@return integer
function GetMusicPlaytime() end

---@return integer
function GetMusicVolSlider() end

---@param name string
---@return integer
function GetNamedRendertargetRenderId(name) end

---@param threadId integer
---@return string
function GetNameOfThread(threadId) end

---@param x number
---@param y number
---@param z number
---@return string
function GetNameOfZone(x, y, z) end

---@param ped Ped
---@return integer
---@return number distanceRemaining
---@return boolean isPathReady
function GetNavmeshRouteDistanceRemaining(ped) end

---@param ped Ped
---@return integer
function GetNavmeshRouteResult(ped) end

---@param entity Entity
---@return integer
function GetNearestPlayerToEntity(entity) end

---@param entity Entity
---@param team integer
---@return integer
function GetNearestPlayerToEntityOnTeam(entity, team) end

---@param soundId integer
---@return integer
function GetNetworkIdFromSoundId(soundId) end

---@return integer
function GetNetworkTime() end

---@return integer
function GetNetworkTimeAccurate() end

---@return integer
function GetNewSelectedMissionCreatorBlip() end

---@return boolean
---@return number timeInSeconds
---@return number bpm
---@return integer beatNum
function GetNextAudibleBeat() end

---@param blipSprite integer
---@return integer
function GetNextBlipInfoId(blipSprite) end

---@param index integer
---@return integer
function GetNextGpsDisabledZoneIndex(index) end

---@return Hash
function GetNextWeatherType() end

---@return Hash
function GetNextWeatherTypeHashName() end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@param section string
---@return Hash
function GetNgstatBoolHash(index, spStat, charStat, character, section) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@param section string
---@return Hash
function GetNgstatIntHash(index, spStat, charStat, character, section) end

---@return boolean
function GetNoLoadingScreen() end

---@return integer
function GetNorthRadarBlip() end

---@param x number
---@param y number
---@param z number
---@param nthClosest integer
---@param unknown1 unknown
---@param unknown2 unknown
---@param unknown3 unknown
---@return boolean
---@return vector3 outPosition
function GetNthClosestVehicleNode(x, y, z, nthClosest, unknown1, unknown2, unknown3) end

---@param x number
---@param y number
---@param z number
---@param desiredX number
---@param desiredY number
---@param desiredZ number
---@param nthClosest integer
---@param nodetype integer
---@param p10 number
---@param p11 unknown
---@return boolean
---@return vector3 outPosition
---@return number outHeading
function GetNthClosestVehicleNodeFavourDirection(x, y, z, desiredX, desiredY, desiredZ, nthClosest, nodetype, p10, p11) end

---@param x number
---@param y number
---@param z number
---@param nth integer
---@param nodetype integer
---@param p5 number
---@param p6 number
---@return integer
function GetNthClosestVehicleNodeId(x, y, z, nth, nodetype, p5, p6) end

---@param x number
---@param y number
---@param z number
---@param nthClosest integer
---@param p6 unknown
---@param p7 number
---@param p8 number
---@return integer
---@return vector3 outPosition
---@return number outHeading
function GetNthClosestVehicleNodeIdWithHeading(x, y, z, nthClosest, p6, p7, p8) end

---@param x number
---@param y number
---@param z number
---@param nthClosest integer
---@param searchFlags integer
---@param zMeasureMult number
---@param zTolerance number
---@return boolean
---@return vector3 outPosition
---@return number heading
---@return integer totalLanes
function GetNthClosestVehicleNodeWithHeading(x, y, z, nthClosest, searchFlags, zMeasureMult, zTolerance) end

---@return integer x
---@return integer y
function GetNuiCursorPosition() end

---@return integer
function GetNumberOfActiveBlips() end

---@param dispatchService integer
---@return integer
function GetNumberOfDispatchedUnitsForPlayer(dispatchService) end

---@param eventGroup integer
---@return integer
function GetNumberOfEvents(eventGroup) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@return integer
function GetNumberOfFiresInRange(x, y, z, radius) end

---@param stackSize integer
---@return integer
function GetNumberOfFreeStacksOfThisSize(stackSize) end

---@param scriptHash Hash|string
---@return integer
function GetNumberOfInstancesOfScriptWithNameHash(scriptHash) end

---@param scriptHash Hash|string
---@return integer
function GetNumberOfInstancesOfStreamedScript(scriptHash) end

---@param newsStory integer
---@return boolean
function GetNumberOfPassengerVoiceVariations(newsStory) end

---@param ped Ped
---@param componentId integer
---@param collection string
---@return integer
function GetNumberOfPedCollectionDrawableVariations(ped, componentId, collection) end

---@param ped Ped
---@param anchorPoint integer
---@param collection string
---@return integer
function GetNumberOfPedCollectionPropDrawableVariations(ped, anchorPoint, collection) end

---@param ped Ped
---@param anchorPoint integer
---@param collection string
---@param propIndex integer
---@return integer
function GetNumberOfPedCollectionPropTextureVariations(ped, anchorPoint, collection, propIndex) end

---@param ped Ped
---@param componentId integer
---@param collection string
---@param drawableId integer
---@return integer
function GetNumberOfPedCollectionTextureVariations(ped, componentId, collection, drawableId) end

---@param ped Ped
---@param componentId integer
---@return integer
function GetNumberOfPedDrawableVariations(ped, componentId) end

---@param ped Ped
---@param propId integer
---@return integer
function GetNumberOfPedPropDrawableVariations(ped, propId) end

---@param ped Ped
---@param propId integer
---@param drawableId integer
---@return integer
function GetNumberOfPedPropTextureVariations(ped, propId, drawableId) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@return integer
function GetNumberOfPedTextureVariations(ped, componentId, drawableId) end

---@return integer
function GetNumberOfPhotos() end

---@return integer
function GetNumberOfPlayers() end

---@param team integer
---@return integer
function GetNumberOfPlayersInTeam(team) end

---@param scriptHash Hash|string
---@return integer
function GetNumberOfReferencesOfScriptWithNameHash(scriptHash) end

---@return integer
function GetNumberOfStreamingRequests() end

---@param vehicle integer
---@return integer
function GetNumberOfVehicleColours(vehicle) end

---@param vehicle integer
---@return integer
function GetNumberOfVehicleDoors(vehicle) end

---@return integer
function GetNumberOfVehicleNumberPlates() end

---@return integer
function GetNumCommerceItems() end

---@param p0 boolean
---@return integer
function GetNumCreatedMissionObjects(p0) end

---@param p0 boolean
---@return integer
function GetNumCreatedMissionPeds(p0) end

---@param p0 boolean
---@return integer
function GetNumCreatedMissionVehicles(p0) end

---@param character integer
---@return integer
function GetNumDecorations(character) end

---@param dispatchService integer
---@return integer
function GetNumDispatchedUnitsForPlayer(dispatchService) end

---@return integer
function GetNumDlcVehicles() end

---@param dlcWeaponIndex integer
---@return integer
function GetNumDlcWeaponComponents(dlcWeaponIndex) end

---@param dlcWeaponIndex integer
---@return integer
function GetNumDlcWeaponComponentsSp(dlcWeaponIndex) end

---@return integer
function GetNumDlcWeapons() end

---@return integer
function GetNumDlcWeaponsSp() end

---@param componentHash Hash|string
---@return integer
function GetNumForcedComponents(componentHash) end

---@return integer
function GetNumHairColors() end

---@param overlayID integer
---@return integer
function GetNumHeadOverlayValues(overlayID) end

---@return integer
function GetNumMakeupColors() end

---@return integer
function GetNumMembershipDesc() end

---@param paintType integer
---@param p1 boolean
---@return integer
function GetNumModColors(paintType, p1) end

---@param vehicle integer
---@return integer
function GetNumModKits(vehicle) end

---@param posMinX number
---@param posMinY number
---@param posMinZ number
---@param posMaxX number
---@param posMaxY number
---@param posMaxZ number
---@return integer
function GetNumNavmeshesExistingInArea(posMinX, posMinY, posMinZ, posMaxX, posMaxY, posMaxZ) end

---@param type integer
---@return integer
function GetNumParentPedsOfType(type) end

---@param character integer
---@param p1 integer
---@param p2 integer
---@param p3 boolean
---@param p4 integer
---@param componentId integer
---@return integer
function GetNumPropsFromOutfit(character, p1, p2, p3, p4, componentId) end

---@param p0 boolean
---@return integer
function GetNumReservedMissionObjects(p0) end

---@param p0 boolean
---@return integer
function GetNumReservedMissionPeds(p0) end

---@param p0 boolean
---@return integer
function GetNumReservedMissionVehicles(p0) end

---@return integer
function GetNumSuccessfulStuntJumps() end

---@param character integer
---@return integer
function GetNumTattooShopDlcItems(character) end

---@return integer
function GetNumUnlockedRadioStations() end

---@param vehicle integer
---@param modType integer
---@return integer
function GetNumVehicleMods(vehicle, modType) end

---@return integer
function GetNumVehicleWindowTints() end

---@param p0 unknown
---@param p1 boolean
---@return number
function GetObjectFragmentDamageHealth(p0, p1) end

---@param entity Entity
---@return integer
function GetObjectIndexFromEntityIndex(entity) end

---@param xPos number
---@param yPos number
---@param zPos number
---@param heading number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@return vector3
function GetObjectOffsetFromCoords(xPos, yPos, zPos, heading, xOffset, yOffset, zOffset) end

---@param object integer
---@return integer
function GetObjectTextureVariation(object) end

---@param xPos number
---@param yPos number
---@param zPos number
---@param heading number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@return vector3
function GetOffsetFromCoordAndHeadingInWorldCoords(xPos, yPos, zPos, heading, xOffset, yOffset, zOffset) end

---@param entity Entity
---@param posX number
---@param posY number
---@param posZ number
---@return vector3
function GetOffsetFromEntityGivenWorldCoords(entity, posX, posY, posZ) end

---@param entity Entity
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@return vector3
function GetOffsetFromEntityInWorldCoords(entity, offsetX, offsetY, offsetZ) end

---@param interior integer
---@param x number
---@param y number
---@param z number
---@return vector3
function GetOffsetFromInteriorInWorldCoords(interior, x, y, z) end

---@return string
function GetOnlineVersion() end

---@return string
function GetOnscreenKeyboardResult() end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPackedBoolStatKey(index, spStat, charStat, character) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPackedIntStatKey(index, spStat, charStat, character) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPackedTitleUpdateBoolStatKey(index, spStat, charStat, character) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPackedTitleUpdateIntStatKey(index, spStat, charStat, character) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPackedTuBoolStatKey(index, spStat, charStat, character) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPackedTuIntStatKey(index, spStat, charStat, character) end

---@return number
function GetParkedVehicleDensityMultiplier() end

---@return vector3
function GetPauseMapPointerWorldPosition() end

---@return vector3
function GetPauseMenuCursorPosition() end

---@return integer lastItemMenuId
---@return integer selectedItemUniqueId
function GetPauseMenuSelection() end

---@return integer lastItemMenuId
---@return integer selectedItemMenuId
---@return integer selectedItemUniqueId
function GetPauseMenuSelectionData() end

---@return integer
function GetPauseMenuState() end

---@param ped Ped
---@return integer
function GetPedAccuracy(ped) end

---@param ped Ped
---@return integer
function GetPedAlertness(ped) end

---@param ped Ped
---@param ammoType Hash|string
---@return integer
function GetPedAmmoByType(ped, ammoType) end

---@param ped Ped
---@param weaponHash Hash|string
---@return Hash
function GetPedAmmoType(ped, weaponHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@return Hash
function GetPedAmmoTypeFromWeapon(ped, weaponHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@return Hash
function GetPedAmmoTypeFromWeapon_2(ped, weaponHash) end

---@param ped Ped
---@return integer
function GetPedArmour(ped) end

---@param groupID integer
---@return Ped
function GetPedAsGroupLeader(groupID) end

---@param groupID integer
---@param memberNumber integer
---@return Ped
function GetPedAsGroupMember(groupID, memberNumber) end

---@param ped Ped
---@param boneId integer
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@return vector3
function GetPedBoneCoords(ped, boneId, offsetX, offsetY, offsetZ) end

---@param ped Ped
---@param boneId integer
---@return integer
function GetPedBoneIndex(ped, boneId) end

---@param ped Ped
---@return Hash
function GetPedCauseOfDeath(ped) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@return integer
function GetPedCollectionLocalIndexFromDrawable(ped, componentId, drawableId) end

---@param ped Ped
---@param anchorPoint integer
---@param propIndex integer
---@return integer
function GetPedCollectionLocalIndexFromProp(ped, anchorPoint, propIndex) end

---@param ped Ped
---@param index integer
---@return string
function GetPedCollectionName(ped, index) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@return string
function GetPedCollectionNameFromDrawable(ped, componentId, drawableId) end

---@param ped Ped
---@param anchorPoint integer
---@param propIndex integer
---@return string
function GetPedCollectionNameFromProp(ped, anchorPoint, propIndex) end

---@param ped Ped
---@return integer
function GetPedCollectionsCount(ped) end

---@param ped Ped
---@return integer
function GetPedCombatMovement(ped) end

---@param ped Ped
---@return integer
function GetPedCombatRange(ped) end

---@param ped Ped
---@param flagId integer
---@param p2 boolean
---@return boolean
function GetPedConfigFlag(ped, flagId, p2) end

---@param ped Ped
---@return boolean
---@return number speedX
---@return number speedY
function GetPedCurrentMovementSpeed(ped) end

---@param ped Ped
---@return table
function GetPedDecorations(ped) end

---@param ped Ped
---@return integer
function GetPedDecorationsState(ped) end

---@param collection Hash|string
---@param overlay Hash|string
---@return integer
function GetPedDecorationZoneFromHashes(collection, overlay) end

---@param ped Ped
---@param p1 boolean
---@return vector3
function GetPedDefensiveAreaPosition(ped, p1) end

---@return number
function GetPedDensityMultiplier() end

---@param ped Ped
---@return number
function GetPedDesiredMoveBlendRatio(ped) end

---@param ped Ped
---@return boolean
function GetPedDiesInWater(ped) end

---@param ped Ped
---@param componentId integer
---@param collection string
---@param drawableId integer
---@return integer
function GetPedDrawableGlobalIndexFromCollection(ped, componentId, collection, drawableId) end

---@param ped Ped
---@param componentId integer
---@return integer
function GetPedDrawableVariation(ped, componentId) end

---@param ped Ped
---@param componentId integer
---@return integer
function GetPedDrawableVariationCollectionLocalIndex(ped, componentId) end

---@param ped Ped
---@param componentId integer
---@return string
function GetPedDrawableVariationCollectionName(ped, componentId) end

---@param ped Ped
---@return number
function GetPedEmissiveIntensity(ped) end

---@param ped Ped
---@return number
function GetPedEnveffScale(ped) end

---@param ped Ped
---@param eventType integer
---@return boolean
---@return unknown outData
function GetPedEventData(ped, eventType) end

---@param ped Ped
---@param worldSpace boolean
---@return vector3
function GetPedExtractedDisplacement(ped, worldSpace) end

---@param ped Ped
---@return integer
function GetPedEyeColor(ped) end

---@param ped Ped
---@param index integer
---@return number
function GetPedFaceFeature(ped, index) end

---@param ped Ped
---@param p1 boolean
function GetPedFloodInvincibility(ped, p1) end

---@param ped Ped
---@return integer
function GetPedGroupIndex(ped) end

---@param ped Ped
---@return integer
function GetPedHairColor(ped) end

---@param ped Ped
---@return integer
function GetPedHairHighlightColor(ped) end

---@param hairColorIndex integer
---@return integer outR
---@return integer outG
---@return integer outB
function GetPedHairRgbColor(hairColorIndex) end

---@param ped Ped
---@return boolean
---@return unknown headBlendData
function GetPedHeadBlendData(ped) end

---@param type integer
---@return integer
function GetPedHeadBlendFirstIndex(type) end

---@param type integer
---@return integer
function GetPedHeadBlendNumHeads(type) end

---@param ped Ped
---@param index integer
---@return boolean
---@return integer overlayValue
---@return integer colourType
---@return integer firstColour
---@return integer secondColour
---@return number overlayOpacity
function GetPedHeadOverlayData(ped, index) end

---@param overlayID integer
---@return integer
function GetPedHeadOverlayNum(overlayID) end

---@param ped Ped
---@param overlayID integer
---@return integer
function GetPedHeadOverlayValue(ped, overlayID) end

---@param id integer
---@return string
function GetPedheadshotTxdString(id) end

---@param ped Ped
---@return integer
function GetPedHelmetStoredHatPropIndex(ped) end

---@param ped Ped
---@return integer
function GetPedHelmetStoredHatTexIndex(ped) end

---@param ped Ped
---@return number
function GetPedIlluminatedClothingGlowIntensity(ped) end

---@param entity Entity
---@return Ped
function GetPedIndexFromEntityIndex(entity) end

---@param explosionType integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number
---@return Entity
function GetPedInsideExplosionArea(explosionType, x1, y1, z1, x2, y2, z2, radius) end

---@param vehicle integer
---@param seatIndex integer
---@return Ped
function GetPedInVehicleSeat(vehicle, seatIndex) end

---@param ped Ped
---@return Entity
function GetPedKiller(ped) end

---@param ped Ped
---@return boolean
---@return integer outBone
function GetPedLastDamageBone(ped) end

---@param ped Ped
---@return boolean
---@return vector3 coords
function GetPedLastWeaponImpactCoord(ped) end

---@param makeupColorIndex integer
---@return integer outR
---@return integer outG
---@return integer outB
function GetPedMakeupRgbColor(makeupColorIndex) end

---@param ped Ped
---@return integer
function GetPedMaxHealth(ped) end

---@param modelHash Hash|string
---@return Hash
function GetPedModelHealthConfig(modelHash) end

---@param modelHash Hash|string
---@return Hash
function GetPedModelPersonality(modelHash) end

---@param ped Ped
---@return integer
function GetPedMoney(ped) end

---@param ped Ped
---@return integer
function GetPedMovementClipset(ped) end

---@param ped Ped
---@param ignore integer
---@return integer
---@return integer sizeAndPeds
function GetPedNearbyPeds(ped, ignore) end

---@param ped Ped
---@return integer
---@return integer sizeAndVehs
function GetPedNearbyVehicles(ped) end

---@param ped Ped
---@param componentId integer
---@return integer
function GetPedPaletteVariation(ped, componentId) end

---@param ped Ped
---@return integer
function GetPedParachuteLandingType(ped) end

---@param ped Ped
---@return integer
function GetPedParachuteState(ped) end

---@param ped Ped
---@return integer outTintIndex
function GetPedParachuteTintIndex(ped) end

---@param ped Ped
---@param anchorPoint integer
---@return integer
function GetPedPropCollectionLocalIndex(ped, anchorPoint) end

---@param ped Ped
---@param anchorPoint integer
---@return string
function GetPedPropCollectionName(ped, anchorPoint) end

---@param ped Ped
---@param anchorPoint integer
---@param collection string
---@param propIndex integer
---@return integer
function GetPedPropGlobalIndexFromCollection(ped, anchorPoint, collection, propIndex) end

---@param ped Ped
---@param componentId integer
---@return integer
function GetPedPropIndex(ped, componentId) end

---@param ped Ped
---@param componentId integer
---@return integer
function GetPedPropTextureIndex(ped, componentId) end

---@param ped Ped
---@param bone integer
---@return integer
function GetPedRagdollBoneIndex(ped, bone) end

---@param ped Ped
---@return Hash
function GetPedRelationshipGroupDefaultHash(ped) end

---@param ped Ped
---@return Hash
function GetPedRelationshipGroupHash(ped) end

---@param ped Ped
---@param flagId integer
---@return boolean
function GetPedResetFlag(ped, flagId) end

---@param ped Ped
---@return Ped
function GetPedsJacker(ped) end

---@param ped Ped
---@return Entity
function GetPedSourceOfDeath(ped) end

---@param ped Ped
---@return boolean
function GetPedStealthMovement(ped) end

---@param ped Ped
---@return number
function GetPedSweat(ped) end

---@param ped Ped
---@param p1 unknown
---@return Entity
function GetPedTaskCombatTarget(ped, p1) end

---@param ped Ped
---@param componentId integer
---@return integer
function GetPedTextureVariation(ped, componentId) end

---@param ped Ped
---@return integer
function GetPedTimeOfDeath(ped) end

---@param ped Ped
---@return integer
function GetPedType(ped) end

---@param vehicle integer
---@param doorIndex integer
---@return Ped
function GetPedUsingVehicleDoor(vehicle, doorIndex) end

---@param ped Ped
---@return number
function GetPedVisualFieldCenterAngle(ped) end

---@param p0 unknown
---@return number
function GetPedWaypointDistance(p0) end

---@param ped Ped
---@return integer
function GetPedWaypointProgress(ped) end

---@param ped Ped
---@param weaponHash Hash|string
---@param camoComponentHash Hash|string
---@return integer
function GetPedWeaponLiveryColor(ped, weaponHash, camoComponentHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@return integer
function GetPedWeaponTintIndex(ped, weaponHash) end

---@param ped Ped
---@param weaponSlot Hash|string
---@return Hash
function GetPedWeapontypeInSlot(ped, weaponSlot) end

---@param ped Ped
---@return number
function GetPhoneGestureAnimCurrentTime(ped) end

---@param ped Ped
---@return number
function GetPhoneGestureAnimTotalTime(ped) end

---@param pickup integer
---@return vector3
function GetPickupCoords(pickup) end

---@return number
function GetPickupGenerationRangeMultiplier() end

---@param pickupHash Hash|string
---@return Hash
function GetPickupHash(pickupHash) end

---@param weapon Hash|string
---@return Hash
function GetPickupHashFromWeapon(weapon) end

---@param pickup integer
---@return integer
function GetPickupObject(pickup) end

---@param aircraft integer
---@return number
function GetPlaneHoverModePercentage(aircraft) end

---@param aircraft integer
---@return number
function GetPlaneVtolDirection(aircraft) end

---@param p0 integer
---@return string
function GetPlayerAdvancedModifierPrivileges(p0) end

---@param player integer
---@return number
function GetPlayerCurrentStealthNoise(player) end

---@param player integer
---@return integer
function GetPlayerFakeWantedLevel(player) end

---@param serverId integer
---@return integer
function GetPlayerFromServerId(serverId) end

---@param player integer
---@return integer
function GetPlayerGroup(player) end

---@param player integer
---@return boolean
function GetPlayerHasReserveParachute(player) end

---@param variableName string
---@param value number
function GetPlayerHeadsetSoundAlternate(variableName, value) end

---@param player integer
---@return number
function GetPlayerHealthRechargeLimit(player) end

---@return integer
function GetPlayerIndex() end

---@param player integer
---@return boolean
function GetPlayerInvincible(player) end

---@param player integer
---@return boolean
function GetPlayerInvincible_2(player) end

---@return number
function GetPlayerKillFallHeight() end

---@param player integer
---@return integer
function GetPlayerMaxArmour(player) end

---@param playerId integer
---@return number
function GetPlayerMaxStamina(playerId) end

---@param playerId integer
---@return number
function GetPlayerMeleeWeaponDefenseModifier(playerId) end

---@param player integer
---@return string
function GetPlayerName(player) end

---@param player integer
---@return Hash
function GetPlayerParachuteModelOverride(player) end

---@param player integer
---@return integer tintIndex
function GetPlayerParachutePackTintIndex(player) end

---@param player integer
---@return integer r
---@return integer g
---@return integer b
function GetPlayerParachuteSmokeTrailColor(player) end

---@param player integer
---@return integer tintIndex
function GetPlayerParachuteTintIndex(player) end

---@param playerId integer
---@return Ped
function GetPlayerPed(playerId) end

---@param ped Ped
---@return integer
function GetPlayerPedIsFollowing(ped) end

---@param player integer
---@return Ped
function GetPlayerPedScriptIndex(player) end

---@return integer
function GetPlayerRadioStationGenre() end

---@return integer
function GetPlayerRadioStationIndex() end

---@return string
function GetPlayerRadioStationName() end

---@param player integer
---@return Hash
function GetPlayerReserveParachuteModelOverride(player) end

---@param player integer
---@return integer index
function GetPlayerReserveParachuteTintIndex(player) end

---@param player integer
---@return integer r
---@return integer g
---@return integer b
function GetPlayerRgbColour(player) end

---@return integer
function GetPlayerShortSwitchState() end

---@return integer
function GetPlayersLastVehicle() end

---@param player integer
---@return number
function GetPlayerSprintStaminaRemaining(player) end

---@param player integer
---@return number
function GetPlayerSprintTimeRemaining(player) end

---@param playerId integer
---@return number
function GetPlayerStamina(playerId) end

---@return unknown
function GetPlayerSwitchInterpOutCurrentTime() end

---@return integer
function GetPlayerSwitchInterpOutDuration() end

---@return integer
function GetPlayerSwitchJumpCutIndex() end

---@return integer
function GetPlayerSwitchState() end

---@return integer
function GetPlayerSwitchType() end

---@param player integer
---@return boolean
---@return Entity entity
function GetPlayerTargetEntity(player) end

---@param player integer
---@return integer
function GetPlayerTeam(player) end

---@param player integer
---@return number
function GetPlayerUnderwaterTimeRemaining(player) end

---@param playerId integer
---@return number
function GetPlayerVehicleDamageModifier(playerId) end

---@param playerId integer
---@return number
function GetPlayerVehicleDefenseModifier(playerId) end

---@param player integer
---@return vector3
function GetPlayerWantedCentrePosition(player) end

---@param player integer
---@return integer
function GetPlayerWantedLevel(player) end

---@param x number
---@param y number
---@param z number
---@param p3 integer
---@return boolean
---@return vector3 outPosition
function GetPointOnRoadSide(x, y, z, p3) end

---@param bStartAtPlayerPos boolean
---@param fDistanceAlongRoute number
---@param slotType integer
---@return boolean
---@return vector3 result
function GetPosAlongGpsTypeRoute(bStartAtPlayerPos, fDistanceAlongRoute, slotType) end

---@param vehicle integer
---@return number
function GetPositionInRecording(vehicle) end

---@param recording integer
---@param time number
---@param script string
---@return vector3
function GetPositionOfVehicleRecordingAtTime(recording, time, script) end

---@param id integer
---@param time number
---@return vector3
function GetPositionOfVehicleRecordingIdAtTime(id, time) end

---@return integer year
---@return integer month
---@return integer day
---@return integer hour
---@return integer minute
---@return integer second
function GetPosixTime() end

---@return integer
function GetPowerSavingModeDuration() end

---@return Hash
function GetPrevWeatherType() end

---@return Hash
function GetPrevWeatherTypeHashName() end

---@param profileSetting integer
---@return integer
function GetProfileSetting(profileSetting) end

---@param ped Ped
---@param weaponHash Hash|string
---@param distance number
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 outCoords
---@return integer outProjectile
function GetProjectileNearPed(ped, weaponHash, distance, ownedByPlayer) end

---@param ped Ped
---@param weaponHash Hash|string
---@param distance number
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 outCoords
function GetProjectileNearPedCoords(ped, weaponHash, distance, ownedByPlayer) end

---@param outfit Hash|string
---@param slot integer
---@return boolean
---@return unknown outComponentVariant
function GetPropFromOutfit(outfit, slot) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPstatBoolHash(index, spStat, charStat, character) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetPstatIntHash(index, spStat, charStat, character) end

---@param stationIndex integer
---@return string
function GetRadioStationName(stationIndex) end

---@return number
function GetRainLevel() end

---@return boolean
function GetRandomEventFlag() end

---@param startRange number
---@param endRange number
---@return number
function GetRandomFloatInRange(startRange, endRange) end

---@param startRange integer
---@param endRange integer
---@return integer
function GetRandomIntInRange(startRange, endRange) end

---@param startRange integer
---@param endRange integer
---@return integer
function GetRandomIntInRange_2(startRange, endRange) end

---@param x number
---@param y number
---@param z number
---@param xRadius number
---@param yRadius number
---@param zRadius number
---@param pedType integer
---@return Ped
function GetRandomPedAtCoord(x, y, z, xRadius, yRadius, zRadius, pedType) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 integer
---@param p5 integer
---@param p6 integer
---@return integer
function GetRandomVehicleBackBumperInSphere(p0, p1, p2, p3, p4, p5, p6) end

---@return number
function GetRandomVehicleDensityMultiplier() end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 integer
---@param p5 integer
---@param p6 integer
---@return integer
function GetRandomVehicleFrontBumperInSphere(p0, p1, p2, p3, p4, p5, p6) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param flags integer
---@return integer
function GetRandomVehicleInSphere(x, y, z, radius, modelHash, flags) end

---@param p0 boolean
---@return Hash modelHash
---@return integer successIndicator
function GetRandomVehicleModelInMemory(p0) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 boolean
---@param p5 boolean
---@param p6 boolean
---@return boolean
---@return vector3 outPosition
---@return integer nodeId
function GetRandomVehicleNode(x, y, z, radius, p4, p5, p6) end

---@param shapeTestHandle integer
---@return integer
---@return boolean hit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return Entity entityHit
function GetRaycastResult(shapeTestHandle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param name string
---@return integer
function GetRayfireMapObject(x, y, z, radius, name) end

---@param object integer
---@return number
function GetRayfireMapObjectAnimPhase(object) end

---@param group1 Hash|string
---@param group2 Hash|string
---@return integer
function GetRelationshipBetweenGroups(group1, group2) end

---@param ped1 Ped
---@param ped2 Ped
---@return integer
function GetRelationshipBetweenPeds(ped1, ped2) end

---@param vehicle integer
---@return number
function GetRemainingNitrousDuration(vehicle) end

---@param size number
---@param font integer
---@return number
function GetRenderedCharacterHeight(size, font) end

---@return integer
function GetRenderingCam() end

---@param index integer
---@return integer
function GetReplayStatAtIndex(index) end

---@return integer
function GetReplayStatCount() end

---@return integer
function GetReplayStatMissionType() end

---@return boolean
function GetRequestingnightvision() end

---@param x number
---@param y number
---@param z number
---@param heading number
---@return boolean
---@return vector3 outPosition
function GetRoadBoundaryUsingHeading(x, y, z, heading) end

---@param x number
---@param y number
---@param z number
---@param heading number
---@return boolean
---@return vector3 outPosition
function GetRoadSidePointWithHeading(x, y, z, heading) end

---@return Hash
function GetRoomKeyForGameViewport() end

---@param entity Entity
---@return Hash
function GetRoomKeyFromEntity(entity) end

---@return Hash
function GetRoomKeyFromGameplayCam() end

---@param p0 integer
---@return string
function GetRootContentId(p0) end

---@param rope integer
---@return integer
function GetRopeFlags(rope) end

---@param ropeId integer
---@return vector3
function GetRopeLastVertexCoord(ropeId) end

---@param ropeId integer
---@return number
function GetRopeLength(ropeId) end

---@param rope integer
---@return number
function GetRopeLengthChangeRate(rope) end

---@param rope integer
---@return number
function GetRopeTimeMultiplier(rope) end

---@param rope integer
---@return integer
function GetRopeUpdateOrder(rope) end

---@param ropeId integer
---@param vertex integer
---@return vector3
function GetRopeVertexCoord(ropeId, vertex) end

---@param ropeId integer
---@return integer
function GetRopeVertexCount(ropeId) end

---@param recording integer
---@param time number
---@param script string
---@return vector3
function GetRotationOfVehicleRecordingAtTime(recording, time, script) end

---@param id integer
---@param time number
---@return vector3
function GetRotationOfVehicleRecordingIdAtTime(id, time) end

---@param tex integer
---@return integer
function GetRuntimeTextureHeight(tex) end

---@param tex integer
---@return integer
function GetRuntimeTexturePitch(tex) end

---@param tex integer
---@return integer
function GetRuntimeTextureWidth(tex) end

---@param x number
---@param y number
---@param z number
---@param onGround boolean
---@param flags integer
---@return boolean
---@return vector3 outPosition
function GetSafeCoordForPed(x, y, z, onGround, flags) end

---@param x number
---@param y number
---@param z number
---@param p3 number
---@param p4 number
---@return vector3
function GetSafePickupCoords(x, y, z, p3, p4) end

---@return number
function GetSafeZoneSize() end

---@param scaleformHandle integer
---@return boolean
---@return boolean received
---@return integer selectionType
---@return integer context
---@return integer slotIndex
function GetScaleformMovieCursorSelection(scaleformHandle) end

---@param method_return integer
---@return boolean
function GetScaleformMovieFunctionReturnBool(method_return) end

---@param method_return integer
---@return integer
function GetScaleformMovieFunctionReturnInt(method_return) end

---@param method_return integer
---@return string
function GetScaleformMovieFunctionReturnString(method_return) end

---@param methodReturn integer
---@return boolean
function GetScaleformMovieMethodReturnValueBool(methodReturn) end

---@param method_return integer
---@return integer
function GetScaleformMovieMethodReturnValueInt(method_return) end

---@param method_return integer
---@return string
function GetScaleformMovieMethodReturnValueString(method_return) end

---@return number
function GetScenarioPedDensityMultiplier() end

---@return integer x
---@return integer y
function GetScreenActiveResolution() end

---@param physicalAspect boolean
---@return number
function GetScreenAspectRatio(physicalAspect) end

---@return number
function GetScreenblurFadeCurrentTime() end

---@param worldX number
---@param worldY number
---@param worldZ number
---@return boolean
---@return number screenX
---@return number screenY
function GetScreenCoordFromWorldCoord(worldX, worldY, worldZ) end

---@param effectName string
---@return boolean
function GetScreenEffectIsActive(effectName) end

---@return integer x
---@return integer y
function GetScreenResolution() end

---@param coverpoint integer
---@return vector3
function GetScriptedCoverPointCoords(coverpoint) end

---@param x number
---@param y number
---@return number calculatedX
---@return number calculatedY
function GetScriptGfxPosition(x, y) end

---@param ped Ped
---@param taskHash Hash|string
---@return integer
function GetScriptTaskStatus(ped, taskHash) end

---@param ped Ped
---@return integer
function GetSeatPedIsTryingToEnter(ped) end

---@param ped Ped
---@return Hash
function GetSelectedPedWeapon(ped) end

---@param ped Ped
---@return integer
function GetSequenceProgress(ped) end

---@param shapeTestHandle integer
---@return integer
---@return boolean hit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return Entity entityHit
function GetShapeTestResult(shapeTestHandle) end

---@param shapeTestHandle integer
---@return integer
---@return boolean hit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return Hash materialHash
---@return Entity entityHit
function GetShapeTestResultEx(shapeTestHandle) end

---@param shapeTestHandle integer
---@return integer
---@return boolean hit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return Hash materialHash
---@return Entity entityHit
function GetShapeTestResultIncludingMaterial(shapeTestHandle) end

---@param componentHash Hash|string
---@return integer
function GetShopPedApparelForcedComponentCount(componentHash) end

---@param componentHash Hash|string
---@return integer
function GetShopPedApparelForcedPropCount(componentHash) end

---@param componentHash Hash|string
---@return integer
function GetShopPedApparelVariantComponentCount(componentHash) end

---@param propHash Hash|string
---@return integer
function GetShopPedApparelVariantPropCount(propHash) end

---@param componentHash Hash|string
---@return unknown outComponent
function GetShopPedComponent(componentHash) end

---@param p0 unknown
---@return unknown p1
function GetShopPedOutfit(p0) end

---@param outfit Hash|string
---@param slot integer
---@return boolean
---@return unknown outComponentVariant
function GetShopPedOutfitComponentVariant(outfit, slot) end

---@param p0 unknown
---@return integer
function GetShopPedOutfitLocate(p0) end

---@param outfitHash Hash|string
---@param variantIndex integer
---@return boolean
---@return unknown outPropVariant
function GetShopPedOutfitPropVariant(outfitHash, variantIndex) end

---@param componentHash Hash|string
---@return unknown outProp
function GetShopPedProp(componentHash) end

---@param componentId integer
---@return integer outComponent
function GetShopPedQueryComponent(componentId) end

---@param outfitIndex integer
---@return unknown outfit
function GetShopPedQueryOutfit(outfitIndex) end

---@param componentId integer
---@return unknown outProp
function GetShopPedQueryProp(componentId) end

---@param p0 boolean
---@return integer
function GetSizeOfSaveData(p0) end

---@return number
function GetSnowLevel() end

---@return integer
function GetSoundId() end

---@param netId integer
---@return integer
function GetSoundIdFromNetworkId(netId) end

---@return integer
function GetStandardBlipEnumId() end

---@param type Hash|string
---@param x number
---@param y number
---@param z number
---@return boolean locked
---@return number heading
function GetStateOfClosestDoorOfType(type, x, y, z) end

---@param object integer
---@return integer
function GetStateOfRayfireMapObject(object) end

---@param p0 string
---@return integer
function GetStatusOfLoadMissionCreatorPhoto(p0) end

---@return integer
function GetStatusOfMissionRepeatSave() end

---@return integer
function GetStatusOfSaveHighQualityPhoto() end

---@param scanForSaving boolean
---@return integer
function GetStatusOfSortedListOperation(scanForSaving) end

---@return integer
function GetStatusOfTakeHighQualityPhoto() end

---@return integer
function GetStatusOfTakeMissionCreatorPhoto() end

---@param p0 integer
---@return integer
function GetStatusOfTextureDownload(p0) end

---@return integer
function GetStreamPlayTime() end

---@param x number
---@param y number
---@param z number
---@return Hash streetName
---@return Hash crossingRoad
function GetStreetNameAtCoord(x, y, z) end

---@param hash Hash|string
---@return string
function GetStreetNameFromHashKey(hash) end

---@param submarine integer
---@return integer
function GetSubmarineCrushDepthWarningState(submarine) end

---@param submarine integer
---@return boolean
function GetSubmarineIsBelowFirstCrushDepth(submarine) end

---@param submarine integer
---@return boolean
function GetSubmarineIsUnderDesignDepth(submarine) end

---@param submarine integer
---@return integer
function GetSubmarineNumberOfAirLeaks(submarine) end

---@param nodeID integer
---@return boolean
function GetSupportsGpsRouteFlag(nodeID) end

---@param sceneID integer
---@return number
function GetSynchronizedScenePhase(sceneID) end

---@param sceneID integer
---@return number
function GetSynchronizedSceneRate(sceneID) end

---@param ped Ped
---@param eventName string
---@return boolean
function GetTaskMoveNetworkEvent(ped, eventName) end

---@param ped Ped
---@param signalName string
---@return boolean
function GetTaskMoveNetworkSignalBool(ped, signalName) end

---@param ped Ped
---@param signalName string
---@return number
function GetTaskMoveNetworkSignalFloat(ped, signalName) end

---@param ped Ped
---@return string
function GetTaskMoveNetworkState(ped) end

---@param characterType integer
---@param decorationIndex integer
---@return boolean
---@return unknown outComponent
function GetTattooCollectionData(characterType, decorationIndex) end

---@param characterType integer
---@param decorationIndex integer
---@return boolean
---@return unknown outComponent
function GetTattooShopDlcItemData(characterType, decorationIndex) end

---@param character integer
---@param collection integer
---@param preset integer
---@return integer
function GetTattooShopDlcItemIndex(character, collection, preset) end

---@param collection Hash|string
---@param overlay Hash|string
---@return integer
function GetTattooZone(collection, overlay) end

---@param ped Ped
---@return boolean
function GetTennisSwingAnimComplete(ped) end

---@param size number
---@param font integer
---@return number
function GetTextScaleHeight(size, font) end

---@param x number
---@param y number
---@return integer
function GetTextScreenLineCount(x, y) end

---@param p0 boolean
---@return number
function GetTextScreenWidth(p0) end

---@param text string
---@param position integer
---@param length integer
---@return string
function GetTextSubstring(text, position, length) end

---@param text string
---@param position integer
---@param length integer
---@param maxLength integer
---@return string
function GetTextSubstringSafe(text, position, length, maxLength) end

---@param text string
---@param startPosition integer
---@param endPosition integer
---@return string
function GetTextSubstringSlice(text, startPosition, endPosition) end

---@param textureDict string
---@param textureName string
---@return vector3
function GetTextureResolution(textureDict, textureName) end

---@return Hash
function GetThisScriptHash() end

---@return string
function GetThisScriptName() end

---@param threadId integer
---@return string
function GetThreadName(threadId) end

---@param time integer
---@return string
function GetTimeAsString(time) end

---@return integer
function GetTimecycleModifierCount() end

---@return integer
function GetTimecycleModifierIndex() end

---@param modifierName string
---@return integer
function GetTimecycleModifierIndexByName(modifierName) end

---@param modifierIndex integer
---@return string
function GetTimecycleModifierNameByIndex(modifierIndex) end

---@return number
function GetTimecycleModifierStrength() end

---@param modifierName string
---@param varName string
---@return boolean
---@return number value1
---@return number value2
function GetTimecycleModifierVar(modifierName, varName) end

---@param modifierName string
---@return integer
function GetTimecycleModifierVarCount(modifierName) end

---@param modifierName string
---@param modifierVarIndex integer
---@return string
function GetTimecycleModifierVarNameByIndex(modifierName, modifierVarIndex) end

---@return integer
function GetTimecycleTransitionModifierIndex() end

---@return integer
function GetTimecycleVarCount() end

---@param varIndex integer
---@return number
function GetTimecycleVarDefaultValueByIndex(varIndex) end

---@param varIndex integer
---@return string
function GetTimecycleVarNameByIndex(varIndex) end

---@param timeA integer
---@param timeB integer
---@return integer
function GetTimeDifference(timeA, timeB) end

---@param timeA integer
---@param timeB integer
---@return integer
function GetTimeOffset(timeA, timeB) end

---@param ped Ped
---@param weaponHash Hash|string
---@return integer
function GetTimeOfLastPedWeaponDamage(ped, weaponHash) end

---@param vehicle integer
---@return number
function GetTimePositionInRecording(vehicle) end

---@return integer
function GetTimeSinceLastArrest() end

---@return integer
function GetTimeSinceLastDeath() end

---@param padIndex integer
---@return integer
function GetTimeSinceLastInput(padIndex) end

---@param player integer
---@return integer
function GetTimeSincePlayerDroveAgainstTraffic(player) end

---@param player integer
---@return integer
function GetTimeSincePlayerDroveOnPavement(player) end

---@param player integer
---@return integer
function GetTimeSincePlayerHitPed(player) end

---@param player integer
---@return integer
function GetTimeSincePlayerHitVehicle(player) end

---@return boolean
function GetTogglePausedRenderphasesStatus() end

---@param recording integer
---@param script string
---@return number
function GetTotalDurationOfVehicleRecording(recording, script) end

---@param id integer
---@return number
function GetTotalDurationOfVehicleRecordingId(id) end

---@return integer
function GetTotalScInboxIds() end

---@return integer
function GetTotalSuccessfulStuntJumps() end

---@param track integer
---@return number
function GetTrackBrakingDistance(track) end

---@param track integer
---@return number
function GetTrackMaxSpeed(track) end

---@param trackIndex integer
---@param trackNode integer
---@return boolean
---@return vector3 coords
function GetTrackNodeCoords(trackIndex, trackNode) end

---@param trackIndex integer
---@return integer
function GetTrackNodeCount(trackIndex) end

---@param train integer
---@param trailerNumber integer
---@return Entity
function GetTrainCarriage(train, trailerNumber) end

---@param train integer
---@return integer
function GetTrainCurrentTrackNode(train) end

---@param train integer
---@return integer
function GetTrainDoorCount(train) end

---@param train integer
---@param doorIndex integer
---@return number
function GetTrainDoorOpenRatio(train, doorIndex) end

---@param train integer
---@return number
function GetTrainSpeed(train) end

---@param contentHash Hash|string
---@return integer
function GetTunablesContentModifierId(contentHash) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetTupstatBoolHash(index, spStat, charStat, character) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function GetTupstatIntHash(index, spStat, charStat, character) end

---@return integer
function GetTvChannel() end

---@return number
function GetTvVolume() end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetTyreHealth(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetTyreWearMultiplier(vehicle, wheelIndex) end

---@return integer
function GetUiLanguageId() end

---@return number
function GetUsedCreatorModelMemoryPercentage() end

---@return integer
function GetUserLanguageId() end

---@return boolean
function GetUsingnightvision() end

---@return boolean
function GetUsingseethrough() end

---@return integer year
---@return integer month
---@return integer day
---@return integer hour
---@return integer minute
---@return integer second
function GetUtcTime() end

---@param componentHash Hash|string
---@param variantComponentIndex integer
---@return Hash nameHash
---@return integer enumValue
---@return integer componentType
function GetVariantComponent(componentHash, variantComponentIndex) end

---@param componentHash Hash|string
---@param variantPropIndex integer
---@return Hash nameHash
---@return integer enumValue
---@return integer anchorPoint
function GetVariantProp(componentHash, variantPropIndex) end

---@param textLabel string
---@return integer
function GetVariationChosenForScriptedLine(textLabel) end

---@param vehicle integer
---@return number
function GetVehicleAcceleration(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleAlarmTimeLeft(vehicle) end

---@param cargobob integer
---@return integer
function GetVehicleAttachedToCargobob(cargobob) end

---@param entity Entity
---@return integer
function GetVehicleAttachedToEntity(entity) end

---@param vehicle integer
---@return number
function GetVehicleBodyHealth(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleBodyHealth_2(vehicle) end

---@param aircraft integer
---@return integer
function GetVehicleBombCount(aircraft) end

---@param vehicle integer
---@return boolean
function GetVehicleCanActivateParachute(vehicle) end

---@param vehicle integer
---@return Hash
function GetVehicleCauseOfDestruction(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleCheatPowerIncrease(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleClass(vehicle) end

---@param vehicleClass integer
---@return number
function GetVehicleClassEstimatedMaxSpeed(vehicleClass) end

---@param modelHash Hash|string
---@return integer
function GetVehicleClassFromName(modelHash) end

---@param vehicleClass integer
---@return number
function GetVehicleClassMaxAcceleration(vehicleClass) end

---@param vehicleClass integer
---@return number
function GetVehicleClassMaxAgility(vehicleClass) end

---@param vehicleClass integer
---@return number
function GetVehicleClassMaxBraking(vehicleClass) end

---@param vehicleClass integer
---@return number
function GetVehicleClassMaxSpeed(vehicleClass) end

---@param vehicleClass integer
---@return number
function GetVehicleClassMaxTraction(vehicleClass) end

---@param vehicle integer
---@return number
function GetVehicleClutch(vehicle) end

---@param vehicle integer
---@return integer r
---@return integer g
---@return integer b
function GetVehicleColor(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleColourCombination(vehicle) end

---@param vehicle integer
---@return integer colorPrimary
---@return integer colorSecondary
function GetVehicleColours(vehicle) end

---@param aircraft integer
---@return integer
function GetVehicleCountermeasureCount(aircraft) end

---@param vehicle integer
---@param p1 integer
---@return integer
function GetVehicleCrewEmblemRequestState(vehicle, p1) end

---@param vehicle integer
---@return number
function GetVehicleCurrentAcceleration(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleCurrentGear(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleCurrentRpm(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleCurrentSlipstreamDraft(vehicle) end

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

---@return number
function GetVehicleDashboardBoost() end

---@param vehicle integer
---@return integer color
function GetVehicleDashboardColor(vehicle) end

---@param vehicle integer
---@return integer color
function GetVehicleDashboardColour(vehicle) end

---@return number
function GetVehicleDashboardCurrentGear() end

---@return number
function GetVehicleDashboardFuel() end

---@return integer
function GetVehicleDashboardLights() end

---@return number
function GetVehicleDashboardOilPressure() end

---@return number
function GetVehicleDashboardOilTemp() end

---@return number
function GetVehicleDashboardRpm() end

---@param vehicle integer
---@return number
function GetVehicleDashboardSpeed(vehicle) end

---@return number
function GetVehicleDashboardTemp() end

---@return number
function GetVehicleDashboardVacuum() end

---@return number
function GetVehicleDashboardWaterTemp() end

---@param vehicle integer
---@return Hash
function GetVehicleDefaultHorn(vehicle) end

---@param vehicle integer
---@return Hash
function GetVehicleDefaultHornIgnoreMods(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleDefaultHornVariation(vehicle) end

---@param vehicle integer
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@return vector3
function GetVehicleDeformationAtPos(vehicle, offsetX, offsetY, offsetZ) end

---@param vehicle integer
---@param height number
function GetVehicleDeformationGetTree(vehicle, height) end

---@return number
function GetVehicleDensityMultiplier() end

---@param vehicle integer
---@return number
function GetVehicleDirtLevel(vehicle) end

---@param vehicle integer
---@param doorIndex integer
---@return number
function GetVehicleDoorAngleRatio(vehicle, doorIndex) end

---@param vehicle integer
---@param doorIndex integer
---@return integer
function GetVehicleDoorDestroyType(vehicle, doorIndex) end

---@param vehicle integer
---@return integer
function GetVehicleDoorLockStatus(vehicle) end

---@param vehicle integer
---@param player integer
---@return boolean
function GetVehicleDoorsLockedForPlayer(vehicle, player) end

---@param vehicle integer
---@return number
function GetVehicleDrawnWheelAngleMult(vehicle) end

---@param vehicleModel Hash|string
---@return integer
function GetVehicleDrivetrainType(vehicleModel) end

---@param vehicle integer
---@return number
function GetVehicleEngineHealth(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleEngineTemperature(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleEnveffScale(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleEstimatedMaxSpeed(vehicle) end

---@param vehicle integer
---@return integer pearlescentColor
---@return integer wheelColor
function GetVehicleExtraColours(vehicle) end

---@param aircraft integer
---@return number
function GetVehicleFlightNozzlePosition(aircraft) end

---@param vehicle integer
---@return number
function GetVehicleFuelLevel(vehicle) end

---@param vehicle integer
---@param gear integer
---@return number
function GetVehicleGearRatio(vehicle, gear) end

---@param vehicle integer
---@return number
function GetVehicleGravityAmount(vehicle) end

---@param vehicle integer
---@param class_ string
---@param fieldName string
---@return number
function GetVehicleHandlingFloat(vehicle, class_, fieldName) end

---@param vehicle integer
---@param class_ string
---@param fieldName string
---@return integer
function GetVehicleHandlingInt(vehicle, class_, fieldName) end

---@param vehicle integer
---@param class_ string
---@param fieldName string
---@return vector3
function GetVehicleHandlingVector(vehicle, class_, fieldName) end

---@param vehicle integer
---@param flagIndex integer
---@return boolean
function GetVehicleHasFlag(vehicle, flagIndex) end

---@param vehicle integer
---@return boolean
function GetVehicleHasKers(vehicle) end

---@param vehicle integer
---@return boolean
function GetVehicleHasLandingGear(vehicle) end

---@param vehicle integer
---@return boolean
function GetVehicleHasParachute(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleHeadlightsColour(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleHealthPercentage(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleHighGear(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleHomingLockonState(vehicle) end

---@param vehicle integer
---@return Hash
function GetVehicleHornHash(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleHornSoundIndex(vehicle) end

---@param aircraft integer
---@return number
function GetVehicleHoverModePercentage(aircraft) end

---@param entity Entity
---@return integer
function GetVehicleIndexFromEntityIndex(entity) end

---@param vehicle integer
---@return integer
function GetVehicleIndicatorLights(vehicle) end

---@param vehicle integer
---@param doorIndex integer
---@return integer
function GetVehicleIndividualDoorLockStatus(vehicle, doorIndex) end

---@param vehicle integer
---@return integer color
function GetVehicleInteriorColor(vehicle) end

---@param vehicle integer
---@return integer color
function GetVehicleInteriorColour(vehicle) end

---@param vehicle integer
---@return boolean
function GetVehicleIsMercenary(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleLandingGear(vehicle) end

---@param vehicle integer
---@return Hash
function GetVehicleLayoutHash(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleLightMultiplier(vehicle) end

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
function GetVehicleLiveryCount(vehicle) end

---@param vehicle integer
---@return boolean
---@return Entity entity
function GetVehicleLockOnTarget(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleMaxBraking(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleMaxNumberOfPassengers(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleMaxSpeed(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleMaxTraction(vehicle) end

---@param vehicle integer
---@param modType integer
---@return integer
function GetVehicleMod(vehicle, modType) end

---@param vehicle integer
---@return integer paintType
---@return integer color
---@return integer pearlescentColor
function GetVehicleModColor_1(vehicle) end

---@param vehicle integer
---@param p1 boolean
---@return string
function GetVehicleModColor_1Name(vehicle, p1) end

---@param vehicle integer
---@return integer paintType
---@return integer color
function GetVehicleModColor_2(vehicle) end

---@param vehicle integer
---@return string
function GetVehicleModColor_2Name(vehicle) end

---@param vehicle integer
---@param modType integer
---@param modIndex integer
---@return Hash
function GetVehicleModData(vehicle, modType, modIndex) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelAcceleration(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelDownForce(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelEstimatedAgility(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelEstimatedMaxSpeed(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelHandBrake(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelMaxBraking(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelMaxBrakingMaxMods(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelMaxKnots(modelHash) end

---@param modelHash Hash|string
---@return integer
function GetVehicleModelMaxNumberOfPassengers(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelMaxSpeed(modelHash) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelMaxTraction(modelHash) end

---@param vehicleModel Hash|string
---@return integer
function GetVehicleModelMonetaryValue(vehicleModel) end

---@param modelHash Hash|string
---@return number
function GetVehicleModelMoveResistance(modelHash) end

---@param modelHash Hash|string
---@return integer
function GetVehicleModelNumberOfSeats(modelHash) end

---@param vehicleModel Hash|string
---@return integer
function GetVehicleModelValue(vehicleModel) end

---@param vehicle integer
---@param modType integer
---@param modIndex integer
---@return Hash
function GetVehicleModIdentifierHash(vehicle, modType, modIndex) end

---@param vehicle integer
---@return integer
function GetVehicleModKit(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleModKitType(vehicle) end

---@param vehicle integer
---@param modType integer
---@param modIndex integer
---@return integer
function GetVehicleModModifierValue(vehicle, modType, modIndex) end

---@param vehicle integer
---@param modType integer
---@return boolean
function GetVehicleModVariation(vehicle, modType) end

---@param vehicle integer
---@return integer r
---@return integer g
---@return integer b
function GetVehicleNeonLightsColour(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleNextGear(vehicle) end

---@param nodeID integer
---@return boolean
function GetVehicleNodeIsGpsAllowed(nodeID) end

---@param nodeID integer
---@return boolean
function GetVehicleNodeIsSwitchedOff(nodeID) end

---@param nodeId integer
---@return vector3 outPosition
function GetVehicleNodePosition(nodeId) end

---@param x number
---@param y number
---@param z number
---@return boolean
---@return integer density
---@return integer flags
function GetVehicleNodeProperties(x, y, z) end

---@param vehicle integer
---@return integer
function GetVehicleNumberOfBrokenBones(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleNumberOfBrokenOffBones(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleNumberOfPassengers(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleNumberOfWheels(vehicle) end

---@param vehicle integer
---@return string
function GetVehicleNumberPlateText(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleNumberPlateTextIndex(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleOilLevel(vehicle) end

---@param vehicle integer
---@return boolean
---@return Entity entity
function GetVehicleOwner(vehicle) end

---@param vehicle integer
---@return number
function GetVehiclePaintFade(vehicle) end

---@param ped Ped
---@return integer
function GetVehiclePedIsEntering(ped) end

---@param ped Ped
---@param lastVehicle boolean
---@return integer
function GetVehiclePedIsIn(ped, lastVehicle) end

---@param ped Ped
---@return integer
function GetVehiclePedIsTryingToEnter(ped) end

---@param ped Ped
---@return integer
function GetVehiclePedIsUsing(ped) end

---@param vehicle integer
---@return number
function GetVehiclePetrolTankHealth(vehicle) end

---@param vehicle integer
---@return integer
function GetVehiclePlateType(vehicle) end

---@param recording integer
---@param script string
---@return integer
function GetVehicleRecordingId(recording, script) end

---@param vehicle integer
---@return integer
function GetVehicleRoofLivery(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleRoofLiveryCount(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleSteeringScale(vehicle) end

---@param vehicle integer
---@return vector3 out1
---@return vector3 out2
function GetVehicleSuspensionBounds(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleSuspensionHeight(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleThrottleOffset(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleTopSpeedModifier(vehicle) end

---@param vehicle integer
---@return boolean
---@return integer trailer
function GetVehicleTrailerVehicle(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleTurboPressure(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleTypeRaw(vehicle) end

---@param vehicle integer
---@return boolean
function GetVehicleTyresCanBurst(vehicle) end

---@param vehicle integer
---@return integer r
---@return integer g
---@return integer b
function GetVehicleTyreSmokeColor(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleWaypointProgress(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleWaypointTargetPoint(vehicle) end

---@param vehicle integer
---@param weaponIndex integer
---@return integer
function GetVehicleWeaponCapacity(vehicle, weaponIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelBrakePressure(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return integer
function GetVehicleWheelFlags(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelHealth(vehicle, wheelIndex) end

---@param vehicle integer
---@return integer
function GetVehicleWheelieState(vehicle) end

---@param vehicle integer
---@param wheelIndex integer
---@return boolean
function GetVehicleWheelIsPowered(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelPower(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelRimColliderSize(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelRotationSpeed(vehicle, wheelIndex) end

---@param vehicle integer
---@return number
function GetVehicleWheelSize(vehicle) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelSpeed(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelSteeringAngle(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return integer
function GetVehicleWheelSurfaceMaterial(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelSuspensionCompression(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelTireColliderSize(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelTireColliderWidth(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelTractionVectorLength(vehicle, wheelIndex) end

---@param vehicle integer
---@return integer
function GetVehicleWheelType(vehicle) end

---@param vehicle integer
---@return number
function GetVehicleWheelWidth(vehicle) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelXOffset(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelXrot(vehicle, wheelIndex) end

---@param vehicle integer
---@param wheelIndex integer
---@return number
function GetVehicleWheelYRotation(vehicle, wheelIndex) end

---@param vehicle integer
---@return integer
function GetVehicleWindowTint(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleXenonLightsColor(vehicle) end

---@param vehicle integer
---@return integer
function GetVehicleXenonLightsColour(vehicle) end

---@param vehicle integer
---@return boolean
---@return integer red
---@return integer green
---@return integer blue
function GetVehicleXenonLightsCustomColor(vehicle) end

---@return number
function GetVehicleXmasSnowFactor() end

---@param name string
---@return number
function GetVisualSettingFloat(name) end

---@return integer
function GetWantedLevelParoleDuration() end

---@param player integer
---@return number
function GetWantedLevelRadius(player) end

---@param wantedLevel integer
---@return integer
function GetWantedLevelThreshold(wantedLevel) end

---@return Hash
function GetWarningMessageTitleHash() end

---@param x number
---@param y number
---@param z number
---@return boolean
---@return number height
function GetWaterHeight(x, y, z) end

---@param x number
---@param y number
---@param z number
---@return boolean
---@return number height
function GetWaterHeightNoWaves(x, y, z) end

---@param waterQuad integer
---@return boolean
---@return integer a0
---@return integer a1
---@return integer a2
---@return integer a3
function GetWaterQuadAlpha(waterQuad) end

---@param x number
---@param y number
---@return integer
function GetWaterQuadAtCoords(x, y) end

---@param x number
---@param y number
---@param z number
---@return integer
function GetWaterQuadAtCoords_3d(x, y, z) end

---@param waterQuad integer
---@return boolean
---@return integer minX
---@return integer minY
---@return integer maxX
---@return integer maxY
function GetWaterQuadBounds(waterQuad) end

---@return integer
function GetWaterQuadCount() end

---@param waterQuad integer
---@return boolean
---@return integer hasLimitedDepth
function GetWaterQuadHasLimitedDepth(waterQuad) end

---@param waterQuad integer
---@return boolean
---@return integer isInvisible
function GetWaterQuadIsInvisible(waterQuad) end

---@param waterQuad integer
---@return boolean
---@return number waterQuadLevel
function GetWaterQuadLevel(waterQuad) end

---@param waterQuad integer
---@return boolean
---@return integer noStencil
function GetWaterQuadNoStencil(waterQuad) end

---@param waterQuad integer
---@return boolean
---@return integer waterType
function GetWaterQuadType(waterQuad) end

---@param waveQuad integer
---@return boolean
---@return number waveQuadAmplitude
function GetWaveQuadAmplitude(waveQuad) end

---@param x number
---@param y number
---@return integer
function GetWaveQuadAtCoords(x, y) end

---@param waveQuad integer
---@return boolean
---@return integer minX
---@return integer minY
---@return integer maxX
---@return integer maxY
function GetWaveQuadBounds(waveQuad) end

---@return integer
function GetWaveQuadCount() end

---@param waveQuad integer
---@return boolean
---@return number directionX
---@return number directionY
function GetWaveQuadDirection(waveQuad) end

---@return number
function GetWavesIntensity() end

---@return integer
function GetWaypointBlipEnumId() end

---@param p0 string
---@param p1 integer
---@return number
function GetWaypointDistanceAlongRoute(p0, p1) end

---@param weaponHash Hash|string
---@return number
function GetWeaponAccuracySpread(weaponHash) end

---@param ped Ped
---@return Hash
function GetWeaponAnimationOverride(ped) end

---@param weaponHash Hash|string
---@return integer
function GetWeaponClipSize(weaponHash) end

---@param componentHash Hash|string
---@return number
function GetWeaponComponentAccuracyModifier(componentHash) end

---@param componentHash Hash|string
---@return integer
function GetWeaponComponentCameraHash(componentHash) end

---@param componentHash Hash|string
---@return integer
function GetWeaponComponentClipSize(componentHash) end

---@param componentHash Hash|string
---@return number
function GetWeaponComponentDamageModifier(componentHash) end

---@param componentHash Hash|string
---@return boolean
---@return integer outData
function GetWeaponComponentHudStats(componentHash) end

---@param componentHash Hash|string
---@return number
function GetWeaponComponentRangeDamageModifier(componentHash) end

---@param componentHash Hash|string
---@return number
function GetWeaponComponentRangeModifier(componentHash) end

---@param componentHash Hash|string
---@return integer
function GetWeaponComponentReticuleHash(componentHash) end

---@param componentHash Hash|string
---@return Hash
function GetWeaponComponentTypeModel(componentHash) end

---@param componentHash Hash|string
---@return integer
function GetWeaponComponentVariantExtraComponentCount(componentHash) end

---@param componentHash Hash|string
---@param extraComponentIndex integer
---@return Hash
function GetWeaponComponentVariantExtraComponentModel(componentHash, extraComponentIndex) end

---@param weaponHash Hash|string
---@param componentHash Hash|string
---@return number
function GetWeaponDamage(weaponHash, componentHash) end

---@param weaponHash Hash|string
---@return number
function GetWeaponDamageModifier(weaponHash) end

---@param weaponHash Hash|string
---@return integer
function GetWeaponDamageType(weaponHash) end

---@param pickupHash Hash|string
---@return Hash
function GetWeaponHashFromPickup(pickupHash) end

---@param weaponHash Hash|string
---@return boolean
---@return unknown outData
function GetWeaponHudStats(weaponHash) end

---@param ped Ped
---@param p1 boolean
---@return integer
function GetWeaponObjectFromPed(ped, p1) end

---@param weaponObject integer
---@param camoComponentHash Hash|string
---@return integer
function GetWeaponObjectLiveryColor(weaponObject, camoComponentHash) end

---@param weapon integer
---@return integer
function GetWeaponObjectTintIndex(weapon) end

---@param weaponHash Hash|string
---@return number
function GetWeaponRecoilShakeAmplitude(weaponHash) end

---@param weaponHash Hash|string
---@return number
function GetWeaponTimeBetweenShots(weaponHash) end

---@param weaponHash Hash|string
---@return integer
function GetWeaponTintCount(weaponHash) end

---@param pickupHash Hash|string
---@return Hash
function GetWeaponTypeFromPickupType(pickupHash) end

---@param weaponHash Hash|string
---@return Hash
function GetWeapontypeGroup(weaponHash) end

---@param weaponHash Hash|string
---@return Hash
function GetWeapontypeModel(weaponHash) end

---@param weaponHash Hash|string
---@return Hash
function GetWeapontypeSlot(weaponHash) end

---@return Hash weatherType1
---@return Hash weatherType2
---@return number percentWeather2
function GetWeatherTypeTransition() end

---@return vector3
function GetWindDirection() end

---@return number
function GetWindSpeed() end

---@param screenX number
---@param screenY number
---@return vector3 worldVector
---@return vector3 normalVector
function GetWorldCoordFromScreenCoord(screenX, screenY) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function GetWorldPositionOfEntityBone(entity, boneIndex) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function GetWorldPositionOfEntityBone_2(entity, boneIndex) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function GetWorldRotationOfEntityBone(entity, boneIndex) end

---@param x number
---@param y number
---@param z number
---@return integer
function GetZoneAtCoords(x, y, z) end

---@param zoneName string
---@return integer
function GetZoneFromNameId(zoneName) end

---@param zoneId integer
---@return integer
function GetZonePopschedule(zoneId) end

---@param zoneId integer
---@return integer
function GetZoneScumminess(zoneId) end

---@param achievement integer
---@return boolean
function GiveAchievementToPlayer(achievement) end

---@param ped Ped
---@param weaponHash Hash|string
---@param ammoCount integer
---@param bForceInHand boolean
function GiveDelayedWeaponToPed(ped, weaponHash, ammoCount, bForceInHand) end

---@param ped Ped
---@param loadoutHash Hash|string
function GiveLoadoutToPed(ped, loadoutHash) end

---@param ped Ped
---@param cannotRemove boolean
---@param helmetFlag integer
---@param textureIndex integer
function GivePedHelmet(ped, cannotRemove, helmetFlag, textureIndex) end

---@param ped Ped
function GivePedNmMessage(ped) end

---@param ped Ped
---@param p1 integer
function GivePedToPauseMenu(ped, p1) end

---@param player integer
---@param toggle boolean
function GivePlayerRagdollControl(player, toggle) end

---@param ped Ped
---@param weaponHash Hash|string
---@param componentHash Hash|string
function GiveWeaponComponentToPed(ped, weaponHash, componentHash) end

---@param weaponObject integer
---@param addonHash Hash|string
function GiveWeaponComponentToWeaponObject(weaponObject, addonHash) end

---@param weaponObject integer
---@param ped Ped
function GiveWeaponObjectToPed(weaponObject, ped) end

---@param ped Ped
---@param weaponHash Hash|string
---@param ammoCount integer
---@param isHidden boolean
---@param bForceInHand boolean
function GiveWeaponToPed(ped, weaponHash, ammoCount, isHidden, bForceInHand) end

---@return number
function GolfTrailGetMaxHeight() end

---@param p0 integer
---@return vector3
function GolfTrailGetVisualControlPoint(p0) end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param p3 integer
---@param p4 integer
---@param p5 integer
---@param p6 integer
---@param p7 integer
---@param p8 integer
---@param p9 integer
---@param p10 integer
---@param p11 integer
function GolfTrailSetColour(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) end

---@param toggle boolean
function GolfTrailSetEnabled(toggle) end

---@param p0 boolean
function GolfTrailSetFacing(p0) end

---@param type integer
---@param xPos number
---@param yPos number
---@param zPos number
---@param p4 number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function GolfTrailSetFixedControlPoint(type, xPos, yPos, zPos, p4, red, green, blue, alpha) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 boolean
function GolfTrailSetPath(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@param p0 number
---@param p1 number
---@param p2 number
function GolfTrailSetRadius(p0, p1, p2) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
function GolfTrailSetShaderParams(p0, p1, p2, p3, p4) end

---@param p0 integer
---@param p1 integer
function GolfTrailSetTessellation(p0, p1) end

function GrassLodResetScriptAreas() end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 number
---@param p5 number
---@param p6 number
function GrassLodShrinkScriptAreas(x, y, z, radius, p4, p5, p6) end

---@param cam integer
---@param entity Entity
---@param xRot number
---@param yRot number
---@param zRot number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param isRelative boolean
function HardAttachCamToEntity(cam, entity, xRot, yRot, zRot, xOffset, yOffset, zOffset, isRelative) end

---@param cam integer
---@param ped Ped
---@param boneIndex integer
---@param xRot number
---@param yRot number
---@param zRot number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param isRelative boolean
function HardAttachCamToPedBone(cam, ped, boneIndex, xRot, yRot, zRot, xOffset, yOffset, zOffset, isRelative) end

---@param achievement integer
---@return boolean
function HasAchievementBeenPassed(achievement) end

---@param asset string
---@return boolean
function HasActionModeAssetLoaded(asset) end

---@param slot integer
---@return boolean
function HasAdditionalTextLoaded(slot) end

---@param animDict string
---@return boolean
function HasAnimDictLoaded(animDict) end

---@param entity Entity
---@param actionHash Hash|string
---@return boolean
function HasAnimEventFired(entity, actionHash) end

---@param animSet string
---@return boolean
function HasAnimSetLoaded(animSet) end

---@return boolean
function HasAsyncInstallFinished() end

---@return boolean
function HasBgScriptBeenDownloaded() end

---@param x number
---@param y number
---@param z number
---@param p3 number
---@param p4 boolean
---@param p5 boolean
---@return boolean
function HasBulletImpactedInArea(x, y, z, p3, p4, p5) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 boolean
---@param p7 boolean
---@return boolean
function HasBulletImpactedInBox(p0, p1, p2, p3, p4, p5, p6, p7) end

---@param hash Hash|string
---@param amount integer
---@return boolean
function HasButtonCombinationJustBeenEntered(hash, amount) end

---@param hash Hash|string
---@return boolean
function HasCheatStringJustBeenEntered(hash) end

---@param clipSet string
---@return boolean
function HasClipSetLoaded(clipSet) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param modelHash Hash|string
---@param p5 unknown
---@return boolean
function HasClosestObjectOfTypeBeenBroken(p0, p1, p2, p3, modelHash, p5) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param p5 boolean
---@return boolean
function HasClosestObjectOfTypeBeenCompletelyDestroyed(x, y, z, radius, modelHash, p5) end

---@param unused unknown
---@return boolean
---@return boolean variable
function HasCloudRequestsFinished(unused) end

---@param model Hash|string
---@return boolean
function HasCollisionForModelLoaded(model) end

---@param entity Entity
---@return boolean
function HasCollisionLoadedAroundEntity(entity) end

---@param cutsceneName string
---@return boolean
function HasCutFileLoaded(cutsceneName) end

---@return boolean
function HasCutsceneCutThisFrame() end

---@return boolean
function HasCutsceneFinished() end

---@return boolean
function HasCutsceneLoaded() end

---@return boolean
function HasDirectorModeBeenTriggered() end

---@param entity Entity
---@param animDict string
---@param animName string
---@param p3 integer
---@return boolean
function HasEntityAnimFinished(entity, animDict, animName, p3) end

---@param entity Entity
---@return boolean
function HasEntityBeenDamagedByAnyObject(entity) end

---@param entity Entity
---@return boolean
function HasEntityBeenDamagedByAnyPed(entity) end

---@param entity Entity
---@return boolean
function HasEntityBeenDamagedByAnyVehicle(entity) end

---@param entity Entity
---@param damager Entity
---@param bCheckDamagerVehicle boolean
---@return boolean
function HasEntityBeenDamagedByEntity(entity, damager, bCheckDamagerVehicle) end

---@param entity Entity
---@param weaponHash Hash|string
---@param weaponType integer
---@return boolean
function HasEntityBeenDamagedByWeapon(entity, weaponHash, weaponType) end

---@param entity1 Entity
---@param entity2 Entity
---@param flags integer
---@return boolean
function HasEntityClearLosToEntity(entity1, entity2, flags) end

---@param entity1 Entity
---@param entity2 Entity
---@param traceType integer
---@return unknown
function HasEntityClearLosToEntity_2(entity1, entity2, traceType) end

---@param entity1 Entity
---@param entity2 Entity
---@return boolean
function HasEntityClearLosToEntityInFront(entity1, entity2) end

---@param entity Entity
---@return boolean
function HasEntityCollidedWithAnything(entity) end

---@return boolean
function HasFilledVehiclePopulation() end

---@param cleanupFlags integer
---@return boolean
function HasForceCleanupOccurred(cleanupFlags) end

---@param hudComponent integer
---@return boolean
function HasHudScaleformLoaded(hudComponent) end

---@return boolean
function HasLoadedMpDataSet() end

---@return boolean
function HasLoadedSpDataSet() end

---@param id integer
---@return boolean
function HasMinimapOverlayLoaded(id) end

---@param model Hash|string
---@return boolean
function HasModelLoaded(model) end

---@return boolean
function HasMpGamerTag() end

---@param gamerTagId integer
---@return boolean
function HasMpGamerTag_2(gamerTagId) end

---@param gamerTagId integer
---@return boolean
function HasMpGamerTagCrewFlagsSet(gamerTagId) end

---@return boolean
function HasMultiplayerAudioDataLoaded() end

---@return boolean
function HasMultiplayerAudioDataUnloaded() end

---@param fxName string
---@return boolean
function HasNamedPtfxAssetLoaded(fxName) end

---@param scaleformName string
---@return boolean
function HasNamedScaleformMovieLoaded(scaleformName) end

---@return boolean
function HasNetworkTimeStarted() end

---@param object integer
---@return boolean
function HasObjectBeenBroken(object) end

---@param ped Ped
---@param weaponHash Hash|string
---@param weaponType integer
---@return boolean
function HasPedBeenDamagedByWeapon(ped, weaponHash, weaponType) end

---@param ped Ped
---@param weaponHash Hash|string
---@param p2 boolean
---@return boolean
function HasPedGotWeapon(ped, weaponHash, p2) end

---@param ped Ped
---@param weaponHash Hash|string
---@param componentHash Hash|string
---@return boolean
function HasPedGotWeaponComponent(ped, weaponHash, componentHash) end

---@param ped Ped
---@return boolean
function HasPedHeadBlendFinished(ped) end

---@return boolean
function HasPedheadshotImgUploadFailed() end

---@return boolean
function HasPedheadshotImgUploadSucceeded() end

---@param ped Ped
---@return boolean
function HasPedPreloadPropDataFinished(ped) end

---@param ped Ped
---@return boolean
function HasPedPreloadVariationDataFinished(ped) end

---@param ped Ped
---@param eventId integer
---@return boolean
function HasPedReceivedEvent(ped, eventId) end

---@param pickup integer
---@return boolean
function HasPickupBeenCollected(pickup) end

---@param player integer
---@param ms integer
---@param p2 boolean
---@return boolean
function HasPlayerBeenShotByCop(player, ms, p2) end

---@param player integer
---@return boolean
function HasPlayerBeenSpottedInStolenVehicle(player) end

---@param player integer
---@return boolean
function HasPlayerDamagedAtLeastOneNonAnimalPed(player) end

---@param player integer
---@return boolean
function HasPlayerDamagedAtLeastOnePed(player) end

---@param player integer
---@return boolean
function HasPlayerLeftTheWorld(player) end

---@param player integer
---@return boolean
function HasPlayerTeleportFinished(player) end

---@param p0 unknown
---@return boolean
function HasPreloadModsFinished(p0) end

---@return boolean
function HasPtfxAssetLoaded() end

---@return boolean
function HasResumedFromSuspend() end

---@param scaleformHandle integer
---@return boolean
function HasScaleformContainerMovieLoadedIntoParent(scaleformHandle) end

---@param scaleformName string
---@return boolean
function HasScaleformMovieFilenameLoaded(scaleformName) end

---@param scaleformHandle integer
---@return boolean
function HasScaleformMovieLoaded(scaleformHandle) end

---@param hudComponent integer
---@return boolean
function HasScaleformScriptHudMovieLoaded(hudComponent) end

---@param scriptName string
---@return boolean
function HasScriptLoaded(scriptName) end

---@param scriptHash Hash|string
---@return boolean
function HasScriptWithNameHashLoaded(scriptHash) end

---@param soundId integer
---@return boolean
function HasSoundFinished(soundId) end

---@param asset string
---@return boolean
function HasStealthModeAssetLoaded(asset) end

---@param ped Ped
---@return boolean
function HasStreamedPedAssetsLoaded(ped) end

---@param scriptHash Hash|string
---@return boolean
function HasStreamedScriptLoaded(scriptHash) end

---@param textureDict string
---@return boolean
function HasStreamedTextureDictLoaded(textureDict) end

---@param gxt string
---@param slot integer
---@return boolean
function HasThisAdditionalTextLoaded(gxt, slot) end

---@param cutsceneName string
---@return boolean
function HasThisCutsceneLoaded(cutsceneName) end

---@return boolean
function HasTunablesBeenDownloaded() end

---@param vehicleAsset integer
---@return boolean
function HasVehicleAssetLoaded(vehicleAsset) end

---@param vehicle integer
---@param p1 integer
---@return boolean
function HasVehicleGotDecal(vehicle, p1) end

---@param driver Ped
---@param vehicle integer
---@param weaponHash Hash|string
---@param p3 unknown
---@return boolean
function HasVehicleGotProjectileAttached(driver, vehicle, weaponHash, p3) end

---@param vehicle integer
---@return boolean
function HasVehicleJumpingAbility(vehicle) end

---@param vehicle integer
---@return boolean
function HasVehicleKersBoost(vehicle) end

---@param vehicle integer
---@return boolean
function HasVehicleParachute(vehicle) end

---@return boolean
function HasVehiclePhoneExplosiveDevice() end

---@param recording integer
---@param script string
---@return boolean
function HasVehicleRecordingBeenLoaded(recording, script) end

---@param vehicle integer
---@return boolean
function HasVehicleRocketBoost(vehicle) end

---@param weaponHash Hash|string
---@return boolean
function HasWeaponAssetLoaded(weaponHash) end

---@param weapon integer
---@param addonHash Hash|string
---@return boolean
function HasWeaponGotWeaponComponent(weapon, addonHash) end

---@param ped Ped
---@return boolean
function HaveAllStreamingRequestsCompleted(ped) end

---@return boolean
function HaveCreditsReachedEnd() end

---@param vehicle integer
---@return boolean
function HaveVehicleModsStreamedIn(vehicle) end

function HideAreaAndVehicleNameThisFrame() end

function HideHelpTextThisFrame() end

function HideHudAndRadarThisFrame() end

---@param id integer
function HideHudComponentThisFrame(id) end

function HideHudNotificationsThisFrame() end

function HideLoadingOnFadeThisFrame() end

---@param mapObjectHash Hash|string
function HideMapObjectThisFrame(mapObjectHash) end

function HideMinimapExteriorMapThisFrame() end

function HideMinimapInteriorMapThisFrame() end

---@param blip integer
function HideNumberOnBlip(blip) end

---@param ped Ped
---@param p1 unknown
---@param p2 boolean
function HidePedBloodDamageByZone(ped, p1, p2) end

---@param ped Ped
---@param toggle boolean
function HidePedWeaponForScriptedCutscene(ped, toggle) end

---@param pickup integer
---@param toggle boolean
function HidePickup(pickup, toggle) end

---@param pickup integer
---@param toggle boolean
function HidePortablePickupWhenDetached(pickup, toggle) end

---@param id integer
function HideScriptedHudComponentThisFrame(id) end

---@param ped Ped
---@param toggle boolean
function HideSpecialAbilityLockonOperation(ped, toggle) end

---@param vehicle integer
---@param toggle boolean
function HideVehicleTombstone(vehicle, toggle) end

---@param x number
---@param y number
---@param z number
---@param colorIndex integer
function HighlightPlacementCoords(x, y, z, colorIndex) end

---@param bankName string
---@param bOverNetwork boolean
---@return boolean
function HintAmbientAudioBank(bankName, bOverNetwork) end

---@param bankName string
---@param bOverNetwork boolean
---@param playerBits integer
---@return boolean
function HintMissionAudioBank(bankName, bOverNetwork, playerBits) end

---@param bankName string
---@param bOverNetwork boolean
---@return boolean
function HintScriptAudioBank(bankName, bOverNetwork) end

---@param p0 unknown
---@param p1 unknown
function HiredLimo(p0, p1) end

function HudDisplayLoadingScreenTips() end

---@param show boolean
function HudForceWeaponWheel(show) end

---@param weaponHash Hash|string
function HudSetWeaponWheelTopSlot(weaponHash) end

---@return Hash
function HudWeaponWheelGetSelectedHash() end

---@param weaponTypeIndex integer
---@return Hash
function HudWeaponWheelGetSlotHash(weaponTypeIndex) end

---@param toggle boolean
function HudWeaponWheelIgnoreControlInput(toggle) end

function HudWeaponWheelIgnoreSelection() end

---@param weaponHash Hash|string
function HudWeaponWheelSetSlotHash(weaponHash) end

---@param toggle boolean
function IgnoreNextRestart(toggle) end

function InitCreatorBudget() end

---@return integer outComponent
function InitShopPedComponent() end

---@return integer outProp
function InitShopPedProp() end

---@param audioName string
---@param entity Entity
function InitSynchSceneAudioWithEntity(audioName, entity) end

---@param audioName string
---@param x number
---@param y number
---@param z number
function InitSynchSceneAudioWithPosition(audioName, x, y, z) end

function InstantlyFillPedPopulation() end

function InstantlyFillVehiclePopulation() end

---@param camera integer
---@param camPosX number
---@param camPosY number
---@param camPosZ number
---@param camRotX number
---@param camRotY number
---@param camRotZ number
---@param fov number
---@param duration integer
---@param posCurveType integer
---@param rotCurveType integer
---@param rotOrder integer
---@param fovCurveType integer
function InterpolateCamWithParams(camera, camPosX, camPosY, camPosZ, camRotX, camRotY, camRotZ, fov, duration, posCurveType, rotCurveType, rotOrder, fovCurveType) end

---@param interrupterPed Ped
---@param context string
---@param voiceName string
function InterruptConversation(interrupterPed, context, voiceName) end

---@param interrupterPed Ped
---@param context string
---@param voiceName string
function InterruptConversationAndPause(interrupterPed, context, voiceName) end

---@param value integer
---@return integer
function IntToParticipantindex(value) end

---@param value integer
---@return integer
function IntToPlayerindex(value) end

function InvalidateIdleCam() end

function InvalidateVehicleIdleCam() end

---@param ped Ped
---@param toggle boolean
function IsAiBlipAlwaysShown(ped, toggle) end

---@return boolean
function IsAimCamActive() end

---@return boolean
function IsAimCamThirdPersonActive() end

---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
---@return integer SphereIndex
function IsAirDefenseZoneInsideSphere(x, y, z, radius) end

---@param alarmName string
---@return boolean
function IsAlarmPlaying(alarmName) end

---@param ped Ped
---@return boolean
function IsAmbientSpeechDisabled(ped) end

---@param ped Ped
---@return boolean
function IsAmbientSpeechPlaying(ped) end

---@param ambientZone string
---@return boolean
function IsAmbientZoneEnabled(ambientZone) end

---@param handle integer
---@return boolean
function IsAnEntity(handle) end

---@param pedHandle Ped
---@return boolean
function IsAnimalVocalizationPlaying(pedHandle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
---@return integer SphereIndex
function IsAnyAirDefenseZoneInsideSphere(x, y, z, radius) end

---@param vehicle integer
---@return boolean
function IsAnyEntityAttachedToHandlerFrame(vehicle) end

---@param garageHash Hash|string
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p4 unknown
---@return boolean
function IsAnyEntityEntirelyInsideGarage(garageHash, p1, p2, p3, p4) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function IsAnyHostilePedNearPoint(ped, x, y, z, radius) end

---@param x number
---@param y number
---@param z number
---@param range number
---@param p4 boolean
---@return boolean
function IsAnyObjectNearPoint(x, y, z, range, p4) end

---@param vehicle integer
---@return boolean
function IsAnyPassengerRappelingFromVehicle(vehicle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function IsAnyPedNearPoint(x, y, z, radius) end

---@param vehicle integer
---@return boolean
function IsAnyPedRappellingFromHeli(vehicle) end

---@param minX number
---@param minY number
---@param minZ number
---@param maxX number
---@param maxY number
---@param maxZ number
---@param bHighlightArea boolean
---@param bDo3DCheck boolean
---@return boolean
function IsAnyPedShootingInArea(minX, minY, minZ, maxX, maxY, maxZ, bHighlightArea, bDo3DCheck) end

---@return boolean
function IsAnyPositionalSpeechPlaying() end

---@param ped Ped
---@return boolean
function IsAnySpeechPlaying(ped) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function IsAnyVehicleNearPoint(x, y, z, radius) end

---@param vehicle integer
---@return boolean
function IsAnyVehicleSeatEmpty(vehicle) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 boolean
---@param p7 boolean
---@param p8 boolean
---@param p9 boolean
---@param p10 boolean
---@param p11 unknown
---@param p12 boolean
---@return boolean
function IsAreaOccupied(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12) end

---@param scene string
---@return boolean
function IsAudioSceneActive(scene) end

---@return boolean
function IsAussieVersion() end

---@return boolean
function IsAutoSaveInProgress() end

---@return boolean
function IsBigmapActive() end

---@return boolean
function IsBigmapFull() end

---@param vehicle integer
---@return boolean
function IsBigVehicle(vehicle) end

---@param address integer
---@param offset integer
---@return boolean
function IsBitSet(address, offset) end

---@param blip integer
---@return boolean
function IsBlipFlashing(blip) end

---@param blip integer
---@return boolean
function IsBlipOnMinimap(blip) end

---@param blip integer
---@return boolean
function IsBlipShortRange(blip) end

---@param boat integer
---@return boolean
function IsBoatAnchored(boat) end

---@param boat integer
---@return boolean
function IsBoatAnchoredAndFrozen(boat) end

---@return boolean
function IsBonnetCinematicCamRendering() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param ownedByPlayer boolean
---@return boolean
function IsBulletInAngledArea(x1, y1, z1, x2, y2, z2, width, ownedByPlayer) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param ownedByPlayer boolean
---@return boolean
function IsBulletInArea(x, y, z, radius, ownedByPlayer) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param ownedByPlayer boolean
---@return boolean
function IsBulletInBox(x1, y1, z1, x2, y2, z2, ownedByPlayer) end

---@param cam integer
---@return boolean
function IsCamActive(cam) end

---@param cam integer
---@return boolean
function IsCamInterpolating(cam) end

---@param cam integer
---@param animName string
---@param animDictionary string
---@return boolean
function IsCamPlayingAnim(cam, animName, animDictionary) end

---@param cam integer
---@return boolean
function IsCamRendering(cam) end

---@param cam integer
---@return boolean
function IsCamShaking(cam) end

---@param p0 unknown
---@return boolean
function IsCamSplinePaused(p0) end

---@param cargobob integer
---@return boolean
function IsCargobobHookActive(cargobob) end

---@param cargobob integer
---@return boolean
function IsCargobobMagnetActive(cargobob) end

---@return boolean
function IsCinematicCamActive() end

---@return boolean
function IsCinematicCamInputActive() end

---@return boolean
function IsCinematicCamRendering() end

---@return boolean
function IsCinematicCamShaking() end

---@return boolean
function IsCinematicIdleCamRendering() end

---@param p0 unknown
---@return boolean
function IsCinematicShotActive(p0) end

---@param x number
---@param y number
---@param z number
---@return boolean
function IsCollisionMarkedOutside(x, y, z) end

---@return boolean
function IsCommandLineBenchmarkValueSet() end

---@return boolean
function IsCommerceDataValid() end

---@return boolean
function IsCommerceStoreOpen() end

---@param itemHash Hash|string
---@return boolean
function IsContentItemLocked(itemHash) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsControlEnabled(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsControlJustPressed(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsControlJustReleased(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsControlPressed(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsControlReleased(padIndex, control) end

---@param ped Ped
---@return boolean
function IsConversationPedDead(ped) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function IsCopPedInArea_3d(x1, y1, z1, x2, y2, z2) end

---@param x1 number
---@param x2 number
---@param y1 number
---@param y2 number
---@param z1 number
---@param z2 number
---@return boolean
function IsCopVehicleInArea_3d(x1, x2, y1, y2, z1, z2) end

---@return boolean
function IsCutsceneActive() end

---@param flag integer
---@return boolean
function IsCutscenePlaybackFlagSet(flag) end

---@return boolean
function IsCutscenePlaying() end

---@param netID integer
---@return boolean
function IsDamageTrackerActiveOnNetworkId(netID) end

---@param player integer
---@return boolean
function IsDamageTrackerActiveOnPlayer(player) end

---@param decal integer
---@return boolean
function IsDecalAlive(decal) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsDisabledControlJustPressed(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsDisabledControlJustReleased(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsDisabledControlPressed(padIndex, control) end

---@param padIndex integer
---@param control integer
---@return boolean
function IsDisabledControlReleased(padIndex, control) end

---@param rawKeyIndex integer
---@return boolean
function IsDisabledRawKeyDown(rawKeyIndex) end

---@param rawKeyIndex integer
---@return boolean
function IsDisabledRawKeyPressed(rawKeyIndex) end

---@param rawKeyIndex integer
---@return boolean
function IsDisabledRawKeyReleased(rawKeyIndex) end

---@param rawKeyIndex integer
---@return boolean
function IsDisabledRawKeyUp(rawKeyIndex) end

---@param itemHash Hash|string
---@return boolean
function IsDlcDataEmpty(itemHash) end

---@param dlcHash Hash|string
---@return boolean
function IsDlcPresent(dlcHash) end

---@param hash Hash|string
---@return boolean
function IsDlcVehicleMod(hash) end

---@param doorHash Hash|string
---@return boolean
function IsDoorClosed(doorHash) end

---@param doorHash Hash|string
---@return boolean
function IsDoorRegisteredWithSystem(doorHash) end

---@param ped Ped
---@return boolean
function IsDrivebyTaskUnderneathDrivingTask(ped) end

---@param duiObject integer
---@return boolean
function IsDuiAvailable(duiObject) end

---@return boolean
function IsDurangoVersion() end

---@param entity Entity
---@return boolean
function IsEntityAGhost(entity) end

---@param entity Entity
---@return boolean
function IsEntityAMissionEntity(entity) end

---@param entity Entity
---@return boolean
function IsEntityAnObject(entity) end

---@param entity Entity
---@return boolean
function IsEntityAPed(entity) end

---@param entity Entity
---@param xPos number
---@param yPos number
---@param zPos number
---@param xSize number
---@param ySize number
---@param zSize number
---@param p7 boolean
---@param p8 boolean
---@param p9 integer
---@return boolean
function IsEntityAtCoord(entity, xPos, yPos, zPos, xSize, ySize, zSize, p7, p8, p9) end

---@param entity1 Entity
---@param entity2 Entity
---@param xSize number
---@param ySize number
---@param zSize number
---@param p5 boolean
---@param p6 boolean
---@param p7 integer
---@return boolean
function IsEntityAtEntity(entity1, entity2, xSize, ySize, zSize, p5, p6, p7) end

---@param entity Entity
---@return boolean
function IsEntityAttached(entity) end

---@param entity Entity
---@return boolean
function IsEntityAttachedToAnyObject(entity) end

---@param entity Entity
---@return boolean
function IsEntityAttachedToAnyPed(entity) end

---@param entity Entity
---@return boolean
function IsEntityAttachedToAnyVehicle(entity) end

---@param from Entity
---@param to Entity
---@return boolean
function IsEntityAttachedToEntity(from, to) end

---@param vehicle integer
---@param entity Entity
---@return boolean
function IsEntityAttachedToHandlerFrame(vehicle, entity) end

---@param entity Entity
---@return boolean
function IsEntityAVehicle(entity) end

---@param entity Entity
---@return boolean
function IsEntityDead(entity) end

---@param entity Entity
---@return boolean
function IsEntityFocus(entity) end

---@param entity Entity
---@return boolean
function IsEntityGhostedToLocalPlayer(entity) end

---@param entity Entity
---@return boolean
function IsEntityInAir(entity) end

---@param entity Entity
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param debug boolean
---@param includez boolean
---@param p10 unknown
---@return boolean
function IsEntityInAngledArea(entity, x1, y1, z1, x2, y2, z2, width, debug, includez, p10) end

---@param entity Entity
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param p7 boolean
---@param p8 boolean
---@param p9 unknown
---@return boolean
function IsEntityInArea(entity, x1, y1, z1, x2, y2, z2, p7, p8, p9) end

---@param entity Entity
---@return boolean
function IsEntityInWater(entity) end

---@param entity Entity
---@param zone string
---@return boolean
function IsEntityInZone(entity, zone) end

---@param entity Entity
---@return boolean
function IsEntityOccluded(entity) end

---@param entity Entity
---@return boolean
function IsEntityOnFire(entity) end

---@param entity Entity
---@return boolean
function IsEntityOnScreen(entity) end

---@param entity Entity
---@param animDict string
---@param animName string
---@param taskFlag integer
---@return boolean
function IsEntityPlayingAnim(entity, animDict, animName, taskFlag) end

---@param entity Entity
---@return boolean
function IsEntityStatic(entity) end

---@param entity Entity
---@param targetEntity Entity
---@return boolean
function IsEntityTouchingEntity(entity, targetEntity) end

---@param entity Entity
---@param modelHash Hash|string
---@return boolean
function IsEntityTouchingModel(entity, modelHash) end

---@param entity Entity
---@param angle number
---@return boolean
function IsEntityUpright(entity, angle) end

---@param entity Entity
---@return boolean
function IsEntityUpsidedown(entity) end

---@param entity Entity
---@return boolean
function IsEntityVisible(entity) end

---@param entity Entity
---@return boolean
function IsEntityVisibleToScript(entity) end

---@param entity Entity
---@return boolean
function IsEntityWaitingForWorldCollision(entity) end

---@param explosionType integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function IsExplosionActiveInArea(explosionType, x1, y1, z1, x2, y2, z2) end

---@param explosionType integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@return boolean
function IsExplosionInAngledArea(explosionType, x1, y1, z1, x2, y2, z2, width) end

---@param explosionType integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function IsExplosionInArea(explosionType, x1, y1, z1, x2, y2, z2) end

---@param explosionType integer
---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function IsExplosionInSphere(explosionType, x, y, z, radius) end

---@return boolean
function IsFirstPersonAimCamActive() end

---@param ped Ped
---@return boolean
function IsFlashLightOn(ped) end

---@param hudIndex integer
---@return boolean
function IsFloatingHelpTextOnScreen(hudIndex) end

---@return boolean
function IsFollowPedCamActive() end

---@return boolean
function IsFollowVehicleCamActive() end

---@return boolean
function IsFrontendFading() end

---@return boolean
function IsFrontendReadyForControl() end

---@return boolean
function IsGameEnhancedVersion() end

---@return boolean
function IsGameInControlOfMusic() end

---@return boolean
function IsGameplayCamLookingBehind() end

---@return boolean
function IsGameplayCamRendering() end

---@return boolean
function IsGameplayCamShaking() end

---@return boolean
function IsGameplayHintActive() end

---@return boolean
function IsGameUsingMetricMeasurementSystem() end

---@param garageHash Hash|string
---@param p1 boolean
---@param p2 integer
---@return boolean
function IsGarageEmpty(garageHash, p1, p2) end

---@param handler integer
---@param container Entity
---@return boolean
function IsHandlerFrameAboveContainer(handler, container) end

---@param vehicle integer
---@return boolean
function IsHeadlightLBroken(vehicle) end

---@param vehicle integer
---@return boolean
function IsHeadlightRBroken(vehicle) end

---@param vehicle integer
---@return boolean
function IsHeliLandingAreaBlocked(vehicle) end

---@param vehicle integer
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@return boolean
function IsHeliPartBroken(vehicle, p1, p2, p3) end

---@return boolean
function IsHelpMessageBeingDisplayed() end

---@return boolean
function IsHelpMessageFadingOut() end

---@return boolean
function IsHelpMessageOnScreen() end

---@param vehicle integer
---@return boolean
function IsHornActive(vehicle) end

---@return boolean
function IsHoveringOverMissionCreatorBlip() end

---@param id integer
---@return boolean
function IsHudComponentActive(id) end

---@return boolean
function IsHudHidden() end

---@return boolean
function IsHudPreferenceSwitchedOn() end

---@param incidentId integer
---@return boolean
function IsIncidentValid(incidentId) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
function IsInItemset(p0, p1) end

---@param toggle boolean
function IsInLoadingScreen(toggle) end

---@return boolean
function IsInPowerSavingMode() end

---@param padIndex integer
---@return boolean
function IsInputDisabled(padIndex) end

---@param padIndex integer
---@return boolean
function IsInputJustDisabled(padIndex) end

---@param interiorID integer
---@return boolean
function IsInteriorCapped(interiorID) end

---@param interior integer
---@return boolean
function IsInteriorDisabled(interior) end

---@param interior integer
---@param entitySetName string
---@return boolean
function IsInteriorEntitySetActive(interior, entitySetName) end

---@param interior integer
---@param entitySetName string
---@return boolean
function IsInteriorPropEnabled(interior, entitySetName) end

---@param interiorID integer
---@return boolean
function IsInteriorReady(interiorID) end

---@return boolean
function IsInteriorRenderingDisabled() end

---@return boolean
function IsInteriorScene() end

---@return boolean
function IsInVehicleCamDisabled() end

---@param iplName string
---@return boolean
function IsIplActive(iplName) end

---@param p0 unknown
---@return boolean
function IsItemsetValid(p0) end

---@return boolean
function IsJapaneseVersion() end

---@return boolean
function IsLoadingPromptBeingDisplayed() end

---@return boolean
function IsLookInverted() end

---@return boolean
function IsMedicalDisabled() end

---@return boolean
function IsMemoryCardInUse() end

---@return boolean
function IsMessageBeingDisplayed() end

---@return boolean
function IsMinigameInProgress() end

---@param x number
---@param y number
---@param z number
---@return boolean
function IsMinimapAreaRevealed(x, y, z) end

---@return boolean
function IsMinimapInInterior() end

---@return boolean
function IsMinimapRendering() end

---@return boolean
function IsMissionCompletePlaying() end

---@return boolean
function IsMissionCompleteReadyForUi() end

---@param blip integer
---@return boolean
function IsMissionCreatorBlip(blip) end

---@param newsStory integer
---@return boolean
function IsMissionNewsStoryUnlocked(newsStory) end

---@param vehicle integer
---@return boolean
function IsMissionTrain(vehicle) end

---@return boolean
function IsMobileInterferenceActive() end

---@return boolean
function IsMobilePhoneCallOngoing() end

---@return boolean
function IsMobilePhoneRadioActive() end

---@param model Hash|string
---@return boolean
function IsModelAPed(model) end

---@param model Hash|string
---@return boolean
function IsModelAVehicle(model) end

---@param model Hash|string
---@return boolean
function IsModelInCdimage(model) end

---@param model Hash|string
---@return boolean
function IsModelValid(model) end

---@param ped Ped
---@return boolean
function IsMountedWeaponTaskUnderneathDrivingTask(ped) end

---@return boolean
function IsMouseCursorAboveInstructionalButtons() end

---@return boolean
function IsMouseRolledOverInstructionalButtons() end

---@param ped Ped
---@return boolean
function IsMoveBlendRatioRunning(ped) end

---@param ped Ped
---@return boolean
function IsMoveBlendRatioSprinting(ped) end

---@param ped Ped
---@return boolean
function IsMoveBlendRatioStill(ped) end

---@param ped Ped
---@return boolean
function IsMoveBlendRatioWalking(ped) end

---@param gamerTagId integer
---@return boolean
function IsMpGamerTagActive(gamerTagId) end

---@param gamerTagId integer
---@return boolean
function IsMpGamerTagFree(gamerTagId) end

---@return boolean
function IsMpGamerTagMovieActive() end

---@return boolean
function IsMultiplayerChatActive() end

---@return boolean
function IsMusicOneshotPlaying() end

---@param modelHash Hash|string
---@return boolean
function IsNamedRendertargetLinked(modelHash) end

---@param name string
---@return boolean
function IsNamedRendertargetRegistered(name) end

---@return unknown
function IsNavigatingMenuContent() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function IsNavmeshLoadedInArea(x1, y1, z1, x2, y2, z2) end

---@return boolean
function IsNavmeshRequiredRegionOwnedByAnyThread() end

---@param netId integer
---@return boolean
function IsNetworkIdOwnedByParticipant(netId) end

---@return boolean
function IsNetworkLoadingScene() end

---@param x number
---@param y number
---@param z number
function IsNetworkVehicleBeenDamagedByAnyObject(x, y, z) end

---@return boolean
function IsNewLoadSceneActive() end

---@return boolean
function IsNewLoadSceneLoaded() end

---@param weatherType string
---@return boolean
function IsNextWeatherType(weatherType) end

---@return boolean
function IsNightvisionActive() end

---@return boolean
function IsNightvisionInactive() end

---@param vehicle integer
---@return boolean
function IsNitrousActive(vehicle) end

---@return boolean
function IsNuiFocused() end

---@return boolean
function IsNuiFocusKeepingInput() end

---@param object integer
---@return boolean
function IsObjectAPickup(object) end

---@param object integer
---@return boolean
function IsObjectAPortablePickup(object) end

---@param garageHash Hash|string
---@param entity Entity
---@param p2 number
---@param p3 integer
---@return boolean
function IsObjectEntirelyInsideGarage(garageHash, entity, p2, p3) end

---@param objectHash Hash|string
---@param x number
---@param y number
---@param z number
---@param range number
---@return boolean
function IsObjectNearPoint(objectHash, x, y, z, range) end

---@param garageHash Hash|string
---@param entity Entity
---@param p2 integer
---@return boolean
function IsObjectPartiallyInsideGarage(garageHash, entity, p2) end

---@param object integer
---@return boolean
function IsObjectVisible(object) end

---@param object integer
---@return boolean
function IsObjectWithinBrainActivationRange(object) end

---@return boolean
function IsOnlinePoliciesMenuActive() end

---@return boolean
function IsOrbisVersion() end

---@param itemHash Hash|string
---@return boolean
function IsOutfitEmpty(itemHash) end

---@return number
function IsParticleFxDelayedBlink() end

---@return boolean
function IsPausemapInInteriorMode() end

---@return boolean
function IsPauseMenuActive() end

---@return boolean
function IsPauseMenuRestarting() end

---@return boolean
function IsPcVersion() end

---@param ped Ped
---@return boolean
function IsPedActiveInScenario(ped) end

---@param ped Ped
---@return boolean
function IsPedAimingFromCover(ped) end

---@param ped Ped
---@return boolean
function IsPedAPlayer(ped) end

---@param ped Ped
---@param typeFlags integer
---@return boolean
function IsPedArmed(ped, typeFlags) end

---@param ped Ped
---@return boolean
function IsPedBeingArrested(ped) end

---@param ped Ped
---@return boolean
function IsPedBeingJacked(ped) end

---@param ped Ped
---@return boolean
function IsPedBeingStealthKilled(ped) end

---@param ped Ped
---@param p1 integer
---@return boolean
function IsPedBeingStunned(ped, p1) end

---@param colorID integer
---@return boolean
function IsPedBlushColorValid(colorID) end

---@param colorId integer
---@return boolean
function IsPedBlushColorValid_2(colorId) end

---@param colorID integer
---@return boolean
function IsPedBodyBlemishValid(colorID) end

---@param ped Ped
---@return boolean
function IsPedClimbing(ped) end

---@param ped Ped
---@param componentId integer
---@param collection string
---@param drawableId integer
---@return boolean
function IsPedCollectionComponentVariationGen9Exclusive(ped, componentId, collection, drawableId) end

---@param ped Ped
---@param componentId integer
---@param collection string
---@param drawableId integer
---@param textureId integer
---@return boolean
function IsPedCollectionComponentVariationValid(ped, componentId, collection, drawableId, textureId) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@return boolean
function IsPedComponentVariationGen9Exclusive(ped, componentId, drawableId) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@return boolean
function IsPedComponentVariationValid(ped, componentId, drawableId, textureId) end

---@param ped Ped
---@return boolean
function IsPedCuffed(ped) end

---@param ped Ped
---@return boolean
function IsPedCurrentWeaponSilenced(ped) end

---@param ped Ped
---@param checkMeleeDeathFlags boolean
---@return boolean
function IsPedDeadOrDying(ped, checkMeleeDeathFlags) end

---@param ped Ped
---@param p1 boolean
---@return boolean
function IsPedDefensiveAreaActive(ped, p1) end

---@param ped Ped
---@return boolean
function IsPedDiving(ped) end

---@param ped Ped
---@return boolean
function IsPedDoingBeastJump(ped) end

---@param ped Ped
---@return boolean
function IsPedDoingDriveby(ped) end

---@param ped Ped
---@return boolean
function IsPedDucking(ped) end

---@param ped Ped
---@return boolean
---@return Entity evadingEntity
function IsPedEvasiveDiving(ped) end

---@param ped Ped
---@param vehicle integer
---@return boolean
---@return integer outIndex
function IsPedExclusiveDriverOfVehicle(ped, vehicle) end

---@param ped Ped
---@param otherPed Ped
---@param angle number
---@return boolean
function IsPedFacingPed(ped, otherPed, angle) end

---@param ped Ped
---@return boolean
function IsPedFalling(ped) end

---@param ped Ped
---@return boolean
function IsPedFatallyInjured(ped) end

---@param ped Ped
---@return boolean
function IsPedFleeing(ped) end

---@param ped Ped
---@return boolean
function IsPedGettingIntoAVehicle(ped) end

---@param ped Ped
---@return boolean
function IsPedGettingUp(ped) end

---@param ped Ped
---@return boolean
function IsPedGoingIntoCover(ped) end

---@param ped Ped
---@param groupId integer
---@return boolean
function IsPedGroupMember(ped, groupId) end

---@param colorID integer
---@return boolean
function IsPedHairColorValid(colorID) end

---@param colorId integer
---@return boolean
function IsPedHairColorValid_2(colorId) end

---@param ped Ped
---@return boolean
function IsPedHangingOnToVehicle(ped) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param p4 number
---@return boolean
function IsPedHeadingTowardsPosition(ped, x, y, z, p4) end

---@return boolean
function IsPedheadshotImgUploadAvailable() end

---@param id integer
---@return boolean
function IsPedheadshotReady(id) end

---@param id integer
---@return boolean
function IsPedheadshotValid(id) end

---@param ped Ped
---@param entity Entity
---@return boolean
function IsPedHeadtrackingEntity(ped, entity) end

---@param ped1 Ped
---@param ped2 Ped
---@return boolean
function IsPedHeadtrackingPed(ped1, ped2) end

---@param ped Ped
---@return boolean
function IsPedHelmetUnk(ped) end

---@param ped Ped
---@return boolean
function IsPedHuman(ped) end

---@param ped Ped
---@return boolean
function IsPedHurt(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnyBoat(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnyHeli(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnyPlane(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnyPoliceVehicle(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnySub(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnyTaxi(ped) end

---@param ped Ped
---@return boolean
function IsPedInAnyTrain(ped) end

---@param ped Ped
---@param atGetIn boolean
---@return boolean
function IsPedInAnyVehicle(ped, atGetIn) end

---@param ped Ped
---@param target Ped
---@return boolean
function IsPedInCombat(ped, target) end

---@param ped Ped
---@param exceptUseWeapon boolean
---@return boolean
function IsPedInCover(ped, exceptUseWeapon) end

---@param ped Ped
---@return boolean
function IsPedInCoverFacingLeft(ped) end

---@param ped Ped
---@return boolean
function IsPedInCurrentConversation(ped) end

---@param ped Ped
---@return boolean
function IsPedInFlyingVehicle(ped) end

---@param ped Ped
---@return boolean
function IsPedInGroup(ped) end

---@param ped Ped
---@return boolean
function IsPedInHighCover(ped) end

---@param ped Ped
---@return boolean
function IsPedInjured(ped) end

---@param ped Ped
---@return boolean
function IsPedInMeleeCombat(ped) end

---@param ped Ped
---@param modelHash Hash|string
---@return boolean
function IsPedInModel(ped, modelHash) end

---@param ped Ped
---@return boolean
function IsPedInParachuteFreeFall(ped) end

---@param ped Ped
---@param vehicle integer
---@param atGetIn boolean
---@return boolean
function IsPedInVehicle(ped, vehicle, atGetIn) end

---@param ped Ped
---@return boolean
function IsPedInWrithe(ped) end

---@param ped Ped
---@return boolean
function IsPedJacking(ped) end

---@param ped Ped
---@return boolean
function IsPedJumping(ped) end

---@param ped Ped
---@return boolean
function IsPedJumpingOutOfVehicle(ped) end

---@param colorID integer
---@return boolean
function IsPedLipstickColorValid(colorID) end

---@param colorId integer
---@return boolean
function IsPedLipstickColorValid_2(colorId) end

---@param ped Ped
---@return boolean
function IsPedMale(ped) end

---@param ped Ped
---@param modelHash Hash|string
---@return boolean
function IsPedModel(ped, modelHash) end

---@param ped Ped
---@return boolean
function IsPedOnAnyBike(ped) end

---@param ped Ped
---@return boolean
function IsPedOnFoot(ped) end

---@param ped Ped
---@return boolean
function IsPedOnMount(ped) end

---@param ped Ped
---@param vehicle integer
---@return boolean
function IsPedOnSpecificVehicle(ped, vehicle) end

---@param ped Ped
---@return boolean
function IsPedOnVehicle(ped) end

---@param ped Ped
---@return boolean
function IsPedOpeningADoor(ped) end

---@param ped Ped
---@return boolean
function IsPedPerformingDependentComboLimit(ped) end

---@param ped Ped
---@return boolean
function IsPedPerformingMeleeAction(ped) end

---@param ped Ped
---@return boolean
function IsPedPerformingStealthKill(ped) end

---@param ped Ped
---@return boolean
function IsPedPlantingBomb(ped) end

---@param ped Ped
---@return boolean
function IsPedPlayingBaseClipInScenario(ped) end

---@param ped Ped
---@return boolean
function IsPedProne(ped) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@return boolean
function IsPedPropValid(ped, componentId, drawableId, textureId) end

---@param ped Ped
---@return boolean
function IsPedRagdoll(ped) end

---@param ped Ped
---@return boolean
function IsPedReloading(ped) end

---@param ped Ped
---@param event unknown
---@return boolean
function IsPedRespondingToEvent(ped, event) end

---@param ped Ped
---@return boolean
function IsPedRingtonePlaying(ped) end

---@param ped Ped
---@return boolean
function IsPedRunning(ped) end

---@param ped Ped
---@return boolean
function IsPedRunningArrestTask(ped) end

---@param ped Ped
---@return boolean
function IsPedRunningMeleeTask(ped) end

---@param ped Ped
---@return boolean
function IsPedRunningMobilePhoneTask(ped) end

---@param ped Ped
---@return boolean
function IsPedRunningRagdollTask(ped) end

---@param ped Ped
---@return boolean
function IsPedShaderEffectValid(ped) end

---@param ped Ped
---@return boolean
function IsPedShooting(ped) end

---@param ped Ped
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param p7 boolean
---@param p8 boolean
---@return boolean
function IsPedShootingInArea(ped, x1, y1, z1, x2, y2, z2, p7, p8) end

---@param ped Ped
---@return boolean
function IsPedSittingInAnyVehicle(ped) end

---@param ped Ped
---@param vehicle integer
---@return boolean
function IsPedSittingInVehicle(ped, vehicle) end

---@param ped Ped
---@return boolean
function IsPedSprinting(ped) end

---@param ped Ped
---@return boolean
function IsPedStandingInCover(ped) end

---@param ped Ped
---@return boolean
function IsPedStill(ped) end

---@param ped Ped
---@return boolean
function IsPedStopped(ped) end

---@param ped Ped
---@return boolean
function IsPedStrafing(ped) end

---@param Ped Ped
---@return boolean
function IsPedSwappingWeapon(Ped) end

---@param ped Ped
---@return boolean
function IsPedSwimming(ped) end

---@param ped Ped
---@return boolean
function IsPedSwimmingUnderWater(ped) end

---@param ped Ped
---@return boolean
function IsPedTakingOffHelmet(ped) end

---@param ped Ped
---@return boolean
function IsPedTracked(ped) end

---@param ped Ped
---@return boolean
function IsPedTryingToEnterALockedVehicle(ped) end

---@param ped Ped
---@return boolean
function IsPedUsingActionMode(ped) end

---@param ped Ped
---@return boolean
function IsPedUsingAnyScenario(ped) end

---@param ped Ped
---@param scenario string
---@return boolean
function IsPedUsingScenario(ped, scenario) end

---@param ped Ped
---@return boolean
function IsPedVaulting(ped) end

---@param ped Ped
---@return boolean
function IsPedWalking(ped) end

---@param ped Ped
---@param weaponHash Hash|string
---@param componentHash Hash|string
---@return boolean
function IsPedWeaponComponentActive(ped, weaponHash, componentHash) end

---@param ped Ped
---@return boolean
function IsPedWeaponReadyToShoot(ped) end

---@param ped Ped
---@return boolean
function IsPedWearingHelmet(ped) end

---@param object integer
---@return boolean
function IsPickupWeaponObjectValid(object) end

---@param pickupHash Hash|string
---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function IsPickupWithinRadius(pickupHash, x, y, z, radius) end

---@param plane integer
---@return boolean
function IsPlaneLandingGearIntact(plane) end

---@param vehicle integer
---@return boolean
function IsPlaybackGoingOnForVehicle(vehicle) end

---@param vehicle integer
---@return boolean
function IsPlaybackUsingAiGoingOnForVehicle(vehicle) end

---@return boolean
function IsPlayerBanned() end

---@param player integer
---@return boolean
function IsPlayerBattleAware(player) end

---@param player integer
---@param atArresting boolean
---@return boolean
function IsPlayerBeingArrested(player, atArresting) end

---@param player integer
---@return boolean
function IsPlayerBluetoothEnable(player) end

---@return boolean
function IsPlayerCamControlDisabled() end

---@param player integer
---@return boolean
function IsPlayerClimbing(player) end

---@param player integer
---@return boolean
function IsPlayerControlOn(player) end

---@param player integer
---@return boolean
function IsPlayerDead(player) end

---@param player integer
---@param type integer
---@return boolean
function IsPlayerDrivingDangerously(player, type) end

---@param garageHash Hash|string
---@param player integer
---@param p2 number
---@param p3 integer
---@return boolean
function IsPlayerEntirelyInsideGarage(garageHash, player, p2, p3) end

---@param player integer
---@return boolean
function IsPlayerFreeAiming(player) end

---@param player integer
---@param entity Entity
---@return boolean
function IsPlayerFreeAimingAtEntity(player, entity) end

---@param player integer
---@return boolean
function IsPlayerFreeForAmbientTask(player) end

---@param player integer
---@return boolean
function IsPlayerInCutscene(player) end

---@return boolean
function IsPlayerLoggingInNp() end

---@return boolean
function IsPlayerOnline() end

---@param garageHash Hash|string
---@param player integer
---@param p2 integer
---@return boolean
function IsPlayerPartiallyInsideGarage(garageHash, player, p2) end

---@param player integer
---@return boolean
function IsPlayerPlaying(player) end

---@param player integer
---@return boolean
function IsPlayerPressingHorn(player) end

---@param player integer
---@return boolean
function IsPlayerReadyForCutscene(player) end

---@param player integer
---@return boolean
function IsPlayerRidingTrain(player) end

---@param player integer
---@return boolean
function IsPlayerScriptControlOn(player) end

---@return boolean
function IsPlayerSwitchInProgress() end

---@param player integer
---@return boolean
function IsPlayerTargettingAnything(player) end

---@param player integer
---@param entity Entity
---@return boolean
function IsPlayerTargettingEntity(player, entity) end

---@return boolean
function IsPlayerTeleportActive() end

---@return boolean
function IsPlayerVehicleRadioEnabled() end

---@return boolean
function IsPlayerVehRadioEnable() end

---@param player integer
---@param wantedLevel integer
---@return boolean
function IsPlayerWantedLevelGreater(player, wantedLevel) end

---@param ped Ped
---@return boolean
function IsPlayingPhoneGestureAnim(ped) end

---@param tvChannel integer
---@param p1 unknown
---@return boolean
function IsPlaylistUnk(tvChannel, p1) end

---@param xPos number
---@param yPos number
---@param zPos number
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param p10 boolean
---@param includez boolean
---@return boolean
function IsPointInAngledArea(xPos, yPos, zPos, x1, y1, z1, x2, y2, z2, width, p10, includez) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 unknown
---@return boolean
function IsPointObscuredByAMissionEntity(p0, p1, p2, p3, p4, p5, p6) end

---@param x number
---@param y number
---@param z number
---@param vehicle integer
---@return boolean
function IsPointOnRoad(x, y, z, vehicle) end

---@param id integer
---@return boolean
function IsPopMultiplierAreaUnk(id) end

---@param x number
---@param y number
---@param z number
---@param range number
---@param p4 boolean
---@param checkVehicles boolean
---@param checkPeds boolean
---@param p7 boolean
---@param p8 boolean
---@param ignoreEntity Entity
---@param p10 boolean
---@return boolean
function IsPositionOccupied(x, y, z, range, p4, checkVehicles, checkPeds, p7, p8, ignoreEntity, p10) end

---@param weatherType string
---@return boolean
function IsPrevWeatherType(weatherType) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param ownedByPlayer boolean
---@return boolean
function IsProjectileInArea(x1, y1, z1, x2, y2, z2, ownedByPlayer) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param p7 number
---@param weaponHash Hash|string
---@param ownedByPlayer boolean
---@return boolean
function IsProjectileTypeInAngledArea(x1, y1, z1, x2, y2, z2, width, p7, weaponHash, ownedByPlayer) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param type integer
---@param ownedByPlayer boolean
---@return boolean
function IsProjectileTypeInArea(x1, y1, z1, x2, y2, z2, type, ownedByPlayer) end

---@param x number
---@param y number
---@param z number
---@param projHash Hash|string
---@param radius number
---@param ownedByPlayer boolean
---@return boolean
function IsProjectileTypeInRadius(x, y, z, projHash, radius, ownedByPlayer) end

---@param x number
---@param y number
---@param z number
---@param projHash Hash|string
---@param radius number
---@param ownedByPlayer boolean
---@return boolean
function IsProjectileTypeWithinDistance(x, y, z, projHash, radius, ownedByPlayer) end

---@return boolean
function IsPs3Version() end

---@return boolean
function IsRadarEnabled() end

---@return boolean
function IsRadarHidden() end

---@return boolean
function IsRadarPreferenceSwitchedOn() end

---@return boolean
function IsRadioFadedOut() end

---@return boolean
function IsRadioRetuning() end

---@param radioStation string
---@return boolean
function IsRadioStationFavourited(radioStation) end

---@param radioStation string
---@return boolean
function IsRadioStationVisible(radioStation) end

---@param rawKeyIndex integer
---@return boolean
function IsRawKeyDown(rawKeyIndex) end

---@param rawKeyIndex integer
---@return boolean
function IsRawKeyPressed(rawKeyIndex) end

---@param rawKeyIndex integer
---@return boolean
function IsRawKeyReleased(rawKeyIndex) end

---@param rawKeyIndex integer
---@return boolean
function IsRawKeyUp(rawKeyIndex) end

---@return boolean
function IsRecording() end

---@return boolean
function IsReportugcMenuOpen() end

---@return boolean
function IsRockstarBanned() end

---@return boolean
function IsRockstarMessageReadyForScript() end

---@param scaleformIndex integer
---@return boolean
function IsScaleformMovieDeleting(scaleformIndex) end

---@param method_return integer
---@return boolean
function IsScaleformMovieMethodReturnValueReady(method_return) end

---@param scenarioGroup string
---@return boolean
function IsScenarioGroupEnabled(scenarioGroup) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 boolean
---@return boolean
function IsScenarioOccupied(p0, p1, p2, p3, p4) end

---@param scenarioType string
---@return boolean
function IsScenarioTypeEnabled(scenarioType) end

---@param msgIndex integer
---@return boolean
function IsScInboxValid(msgIndex) end

---@return boolean
function IsScreenblurFadeRunning() end

---@return boolean
function IsScreenFadedIn() end

---@return boolean
function IsScreenFadedOut() end

---@return boolean
function IsScreenFadingIn() end

---@return boolean
function IsScreenFadingOut() end

---@return boolean
function IsScriptedConversationLoaded() end

---@return boolean
function IsScriptedConversationOngoing() end

---@param id integer
---@return boolean
function IsScriptedHudComponentActive(id) end

---@param id integer
---@return boolean
function IsScriptedHudComponentHiddenThisFrame(id) end

---@param ped Ped
---@param animDict string
---@param anim string
---@return boolean
function IsScriptedScenarioPedUsingConditionalAnim(ped, animDict, anim) end

---@param ped Ped
---@return boolean
function IsScriptedSpeechPlaying(ped) end

---@return boolean
function IsScriptGlobalShaking() end

---@param ped Ped
---@return boolean
function IsScubaGearLightEnabled(ped) end

---@param vehicle integer
---@param seatIndex integer
---@return boolean
function IsSeatWarpOnly(vehicle, seatIndex) end

---@return boolean
function IsSeethroughActive() end

---@param eventType integer
---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function IsShockingEventInSphere(eventType, x, y, z, radius) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function IsSniperBulletInArea(x1, y1, z1, x2, y2, z2) end

---@return boolean
function IsSniperInverted() end

---@return boolean
function IsSocialClubActive() end

---@return boolean
function IsSocialclubBanned() end

---@param player integer
---@return boolean
function IsSpecialAbilityActive(player) end

---@param player integer
---@return boolean
function IsSpecialAbilityEnabled(player) end

---@param player integer
---@return boolean
function IsSpecialAbilityMeterFull(player) end

---@param playerModel Hash|string
---@return boolean
function IsSpecialAbilityUnlocked(playerModel) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function IsSphereVisible(x, y, z, radius) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@return boolean
function IsSphereVisibleToAnotherMachine(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@return boolean
function IsSphereVisibleToPlayer(p0, p1, p2, p3, p4) end

---@return boolean
function IsSrlLoaded() end

---@return boolean
function IsSteamVersion() end

---@return boolean
function IsStoreAvailableToUser() end

---@param p0 integer
---@return boolean
function IsStreamingAdditionalText(p0) end

---@param registerAs string
---@return boolean
function IsStreamingFileReady(registerAs) end

---@return boolean
function IsStreamPlaying() end

---@return boolean
function IsStreamvolActive() end

---@param string string
---@return boolean
function IsStringNull(string) end

---@param string string
---@return boolean
function IsStringNullOrEmpty(string) end

---@return boolean
function IsStuntJumpInProgress() end

---@return boolean
function IsStuntJumpMessageShowing() end

---@return boolean
function IsSubtitlePreferenceSwitchedOn() end

---@return boolean
function IsSwitchReadyForDescent() end

---@return boolean
function IsSwitchSkippingDescent() end

---@param sceneID integer
---@return boolean
function IsSynchronizedSceneHoldLastFrame(sceneID) end

---@param sceneID integer
---@return boolean
function IsSynchronizedSceneLooped(sceneID) end

---@param sceneId integer
---@return boolean
function IsSynchronizedSceneRunning(sceneId) end

---@return boolean
function IsSystemUiBeingDisplayed() end

---@param ped Ped
---@return boolean
function IsTaskMoveNetworkActive(ped) end

---@param ped Ped
---@return boolean
function IsTaskMoveNetworkReadyForTransition(ped) end

---@param vehicle integer
---@return boolean
function IsTaxiLightOn(vehicle) end

---@param ped Ped
---@return boolean
function IsTennisMode(ped) end

---@return boolean
function IsTextChatActive() end

---@return boolean
function IsThisAMinigameScript() end

---@param model Hash|string
---@return boolean
function IsThisModelABicycle(model) end

---@param model Hash|string
---@return boolean
function IsThisModelABike(model) end

---@param model Hash|string
---@return boolean
function IsThisModelABoat(model) end

---@param model Hash|string
---@return boolean
function IsThisModelACar(model) end

---@param model Hash|string
---@return boolean
function IsThisModelAHeli(model) end

---@param model Hash|string
---@return boolean
function IsThisModelAJetski(model) end

---@param model Hash|string
---@return boolean
function IsThisModelAnAmphibiousCar(model) end

---@param model Hash|string
---@return boolean
function IsThisModelAnAmphibiousQuadbike(model) end

---@param model Hash|string
---@return boolean
function IsThisModelAnEmergencyBoat(model) end

---@param model Hash|string
---@return boolean
function IsThisModelAPlane(model) end

---@param model Hash|string
---@return boolean
function IsThisModelAQuadbike(model) end

---@param model Hash|string
---@return boolean
function IsThisModelASubmersible(model) end

---@param model Hash|string
---@return boolean
function IsThisModelATrain(model) end

---@param threadId integer
---@return boolean
function IsThreadActive(threadId) end

---@param timeA integer
---@param timeB integer
---@return boolean
function IsTimeEqualTo(timeA, timeB) end

---@param timeA integer
---@param timeB integer
---@return boolean
function IsTimeLessThan(timeA, timeB) end

---@param timeA integer
---@param timeB integer
---@return boolean
function IsTimeMoreThan(timeA, timeB) end

---@param vehicle integer
---@param modType integer
---@return boolean
function IsToggleModOn(vehicle, modType) end

---@param ped Ped
---@return boolean
function IsTrackedPedVisible(ped) end

---@param point integer
---@return boolean
function IsTrackedPointVisible(point) end

---@param track integer
---@return boolean
function IsTrackEnabled(track) end

---@param track integer
---@return boolean
function IsTrackSwitchedOff(track) end

---@param vehicle integer
---@param seatIndex integer
---@return boolean
function IsTurretSeat(vehicle, seatIndex) end

---@param videoCliphash Hash|string
---@return boolean
function IsTvPlaylistItemPlaying(videoCliphash) end

---@return boolean
function IsUiLoadingMultiplayer() end

---@param padIndex integer
---@return boolean
function IsUsingKeyboard(padIndex) end

---@param padIndex integer
---@return boolean
function IsUsingKeyboard_2(padIndex) end

---@param interior integer
---@return boolean
function IsValidInterior(interior) end

---@param gamerTagId integer
---@return boolean
function IsValidMpGamerTagMovie(gamerTagId) end

---@param vehicle integer
---@param checkRoofExtras boolean
---@return boolean
function IsVehicleAConvertible(vehicle, checkRoofExtras) end

---@param vehicle integer
---@return boolean
function IsVehicleAlarmActivated(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleAlarmSet(vehicle) end

---@param cargobob integer
---@param vehicleAttached integer
---@return boolean
function IsVehicleAttachedToCargobob(cargobob, vehicleAttached) end

---@param towTruck integer
---@param vehicle integer
---@return boolean
function IsVehicleAttachedToTowTruck(towTruck, vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleAttachedToTrailer(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleAudiblyDamaged(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleBeingHalted(vehicle) end

---@param vehicle integer
---@param frontBumper boolean
---@return boolean
function IsVehicleBumperBouncing(vehicle, frontBumper) end

---@param vehicle integer
---@param front boolean
---@return boolean
function IsVehicleBumperBrokenOff(vehicle, front) end

---@param vehicle integer
---@return boolean
function IsVehicleDamaged(vehicle) end

---@param veh integer
---@param doorID integer
---@return boolean
function IsVehicleDoorDamaged(veh, doorID) end

---@param vehicle integer
---@param doorIndex integer
---@return boolean
function IsVehicleDoorFullyOpen(vehicle, doorIndex) end

---@param vehicle integer
---@param isOnFireCheck boolean
---@return boolean
function IsVehicleDriveable(vehicle, isOnFireCheck) end

---@param vehicle integer
---@return boolean
function IsVehicleEngineOn(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleEngineOnFire(vehicle) end

---@param vehicle integer
---@param extraId integer
---@return boolean
function IsVehicleExtraTurnedOn(vehicle, extraId) end

---@param vehicle integer
---@return boolean
function IsVehicleHighDetail(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleInBurnout(vehicle) end

---@param garageName string
---@param vehicle integer
---@return boolean
function IsVehicleInGarageArea(garageName, vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleInSubmarineMode(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleInteriorLightOn(vehicle) end

---@param vehicle integer
---@param model Hash|string
---@return boolean
function IsVehicleModel(vehicle, model) end

---@param vehicle integer
---@param modType integer
---@param modIndex integer
---@return boolean
function IsVehicleModHswExclusive(vehicle, modType, modIndex) end

---@param vehicle integer
---@return boolean
function IsVehicleModLoadDone(vehicle) end

---@param vehicle integer
---@param entity Entity
---@return boolean
function IsVehicleNearEntity(vehicle, entity) end

---@param vehicle integer
---@return boolean
function IsVehicleNeedsToBeHotwired(vehicle) end

---@param vehicle integer
---@param index integer
---@return boolean
function IsVehicleNeonLightEnabled(vehicle, index) end

---@param vehicleNodeId integer
---@return boolean
function IsVehicleNodeIdValid(vehicleNodeId) end

---@param vehicle integer
---@return boolean
function IsVehicleOnAllWheels(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleParachuteActive(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehiclePreviouslyOwnedByPlayer(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleRadioEnabled(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleRadioLoud(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleRadioOn(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleRocketBoostActive(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleSearchlightOn(vehicle) end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
---@param side boolean
---@param onEnter boolean
---@return boolean
function IsVehicleSeatAccessible(ped, vehicle, seatIndex, side, onEnter) end

---@param vehicle integer
---@param seatIndex integer
---@return boolean
function IsVehicleSeatFree(vehicle, seatIndex) end

---@param vehicle integer
---@return boolean
function IsVehicleShopResprayAllowed(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleSirenAudioOn(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleSirenOn(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleSirenSoundOn(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleSlipstreamLeader(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleSprayable(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleStolen(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleStopped(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleStoppedAtTrafficLights(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleStuckOnRoof(vehicle) end

---@param vehicle integer
---@param p1 integer
---@param p2 integer
---@return boolean
function IsVehicleStuckTimerUp(vehicle, p1, p2) end

---@param vehicle integer
---@param wheelID integer
---@param isBurstToRim boolean
---@return boolean
function IsVehicleTyreBurst(vehicle, wheelID, isBurstToRim) end

---@param vehicle integer
---@return boolean
function IsVehicleVisible(vehicle) end

---@param vehicle integer
---@return boolean
function IsVehicleWanted(vehicle) end

---@param weaponHash Hash|string
---@param vehicle integer
---@param owner Ped
---@return boolean
function IsVehicleWeaponDisabled(weaponHash, vehicle, owner) end

---@param vehicle integer
---@param wheelIndex integer
---@return boolean
function IsVehicleWheelBrokenOff(vehicle, wheelIndex) end

---@param vehicle integer
---@param windowIndex integer
---@return boolean
function IsVehicleWindowIntact(vehicle, windowIndex) end

---@return boolean
function IsWarningMessageActive() end

---@return boolean
function IsWarningMessageActive_2() end

---@return boolean
function IsWaypointActive() end

---@param p0 unknown
---@return boolean
function IsWaypointPlaybackGoingOnForPed(p0) end

---@param vehicle integer
---@return boolean
function IsWaypointPlaybackGoingOnForVehicle(vehicle) end

---@param weaponHash Hash|string
---@return boolean
function IsWeaponValid(weaponHash) end

---@return boolean
function IsWorldPointWithinBrainActivationRange() end

---@return boolean
function IsXbox360Version() end

---@param vehicle integer
---@param toggle boolean
---@param depth1 number
---@param depth2 number
---@param depth3 number
function JitterVehicle(vehicle, toggle, depth1, depth2, depth3) end

---@param toggle boolean
---@param ped Ped
function KeyHudColour(toggle, ped) end

---@param ped Ped
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p4 boolean
function KnockOffPedProp(ped, p1, p2, p3, p4) end

---@param ped Ped
function KnockPedOffVehicle(ped) end

---@return boolean
function LandingMenuIsActive() end

---@return boolean
---@return unknown p0
---@return unknown p1
function Leaderboards2ReadByHandle() end

---@param gamerHandleCsv string
---@param platformName string
---@return boolean
---@return unknown p0
function Leaderboards2ReadByPlatform(gamerHandleCsv, platformName) end

---@param p1 unknown
---@return boolean
---@return unknown p0
---@return unknown p2
function Leaderboards2ReadByRadius(p1) end

---@param p1 unknown
---@param p2 unknown
---@return boolean
---@return unknown p0
function Leaderboards2ReadByRank(p1, p2) end

---@param p2 unknown
---@param p4 unknown
---@param p6 unknown
---@return boolean
---@return unknown p0
---@return unknown p1
---@return unknown p3
---@return unknown p5
function Leaderboards2ReadByRow(p2, p4, p6) end

---@param p1 number
---@param p2 unknown
---@return boolean
---@return unknown p0
function Leaderboards2ReadByScoreFloat(p1, p2) end

---@param p1 unknown
---@param p2 unknown
---@return boolean
---@return unknown p0
function Leaderboards2ReadByScoreInt(p1, p2) end

---@param p2 unknown
---@param p3 boolean
---@param p4 unknown
---@param p5 unknown
---@return boolean
---@return unknown p0
---@return unknown p1
function Leaderboards2ReadFriendsByRow(p2, p3, p4, p5) end

---@return boolean
---@return unknown p0
---@return unknown p1
---@return unknown p2
function Leaderboards2ReadRankPrediction() end

---@return boolean
---@return unknown p0
function Leaderboards2WriteData() end

---@return boolean
---@return unknown p0
---@return unknown p1
function Leaderboards2WriteDataForEventType() end

---@return boolean
---@return unknown p0
function LeaderboardsCacheDataRow() end

function LeaderboardsClearCacheData() end

---@param statName Hash|string
---@param value number
function LeaderboardsDeaths(statName, value) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
function LeaderboardsGetCacheDataRow(p0, p1) end

---@param p0 unknown
---@return boolean
function LeaderboardsGetCacheExists(p0) end

---@param p0 unknown
---@return integer
function LeaderboardsGetCacheNumberOfRows(p0) end

---@param p0 unknown
---@return unknown
function LeaderboardsGetCacheTime(p0) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return unknown
function LeaderboardsGetColumnId(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return unknown
function LeaderboardsGetColumnType(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function LeaderboardsGetNumberOfColumns(p0, p1) end

---@return boolean
function LeaderboardsReadAnyPending() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return unknown
function LeaderboardsReadClear(p0, p1, p2) end

---@return unknown
function LeaderboardsReadClearAll() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return boolean
function LeaderboardsReadPending(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return boolean
function LeaderboardsReadSuccessful(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 number
function LeaderboardsWriteAddColumn(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function LeaderboardsWriteAddColumnLong(p0, p1, p2) end

function LeaveCursorMode() end

---@param modelHash Hash|string
function LinkNamedRendertarget(modelHash) end

---@param emitterName string
---@param entity Entity
function LinkStaticEmitterToEntity(emitterName, entity) end

function LoadAllObjectsNow() end

---@param keepInMemory boolean
---@return boolean
function LoadAllPathNodes(keepInMemory) end

---@param name string
---@param transitionTime number
function LoadCloudHat(name, transitionTime) end

---@param hash Hash|string
function LoadContentChangeSetGroup(hash) end

---@param waterType integer
function LoadGlobalWaterType(waterType) end

---@return boolean
function LoadingscreenGetLoadFreemode() end

---@return boolean
function LoadingscreenGetLoadFreemodeWithEventName() end

---@return boolean
function LoadingscreenIsLoadingFreemode() end

---@param toggle boolean
function LoadingscreenSetIsLoadingFreemode(toggle) end

---@param toggle boolean
function LoadingscreenSetLoadFreemode(toggle) end

---@param toggle boolean
function LoadingscreenSetLoadFreemodeWithEventName(toggle) end

---@param interior integer
function LoadInterior(interior) end

function LoadMissionCreatorData() end

---@param p0 string
---@param p3 boolean
---@return boolean
---@return unknown p1
---@return unknown p2
function LoadMissionCreatorPhoto(p0, p3) end

---@param movieMeshSetName string
---@return integer
function LoadMovieMeshSet(movieMeshSetName) end

function LoadMpDlcMaps() end

---@param ropeId integer
---@param rope_preset string
function LoadRopeData(ropeId, rope_preset) end

---@param x number
---@param y number
---@param z number
function LoadScene(x, y, z) end

function LoadSpDlcMaps() end

---@param streamName string
---@param soundSet string
---@return boolean
function LoadStream(streamName, soundSet) end

---@param streamName string
---@param startOffset integer
---@param soundSet string
---@return boolean
function LoadStreamWithStartOffset(streamName, startOffset, soundSet) end

---@param videoCliphash Hash|string
---@return boolean
function LoadTvChannel(videoCliphash) end

---@param tvChannel integer
---@param playlistName string
---@param restart boolean
function LoadTvChannelSequence(tvChannel, playlistName, restart) end

---@param filename string
---@return boolean
function LoadUgcFile(filename) end

---@param resourceName string
---@param fileName string
---@return boolean
function LoadWaterFromPath(resourceName, fileName) end

---@return integer
function LocalizationGetSystemDateFormat() end

---@return integer
function LocalizationGetSystemLanguage() end

function LockLoadingScreenButtons() end

---@param angle integer
function LockMinimapAngle(angle) end

---@param x number
---@param y number
function LockMinimapPosition(x, y) end

---@param radioStationName string
---@param toggle boolean
function LockRadioStation(radioStationName, toggle) end

---@param radioStation string
---@param trackListName string
function LockRadioStationTrackList(radioStation, trackListName) end

---@param value number
---@return number
function Log10(value) end

---@param p0 string
function LogDebugInfo(p0) end

---@param vehicle integer
---@param instantlyLower boolean
function LowerConvertibleRoof(vehicle, instantlyLower) end

---@param toggle integer
function LowerMapPropDensity(toggle) end

---@param vehicle integer
function LowerRetractableWheels(vehicle) end

---@param ped Ped
---@return boolean
function MakePedReload(ped) end

---@param object integer
function MarkObjectForDeletion(object) end

---@return integer
function MaxRadioStationIndex() end

---@param vehicle integer
---@param value number
function ModifyVehicleTopSpeed(vehicle, value) end

---@param x number
---@param y number
---@param height number
---@param radius number
function ModifyWater(x, y, height, radius) end

---@param direction integer
function MoveFinger(direction) end

---@param p0 unknown
---@param p1 unknown
function MoveVehicleDecals(p0, p1) end

---@param channel integer
function MumbleAddVoiceChannelListen(channel) end

---@param targetId integer
---@param channel integer
function MumbleAddVoiceTargetChannel(targetId, channel) end

---@param targetId integer
---@param player integer
function MumbleAddVoiceTargetPlayer(targetId, player) end

---@param targetId integer
---@param serverId integer
function MumbleAddVoiceTargetPlayerByServerId(targetId, serverId) end

function MumbleClearVoiceChannel() end

---@param targetId integer
function MumbleClearVoiceTarget(targetId) end

---@param targetId integer
function MumbleClearVoiceTargetChannels(targetId) end

---@param targetId integer
function MumbleClearVoiceTargetPlayers(targetId) end

---@param channel integer
---@return boolean
function MumbleDoesChannelExist(channel) end

---@return number
function MumbleGetTalkerProximity() end

---@param serverId integer
---@return integer
function MumbleGetVoiceChannelFromServerId(serverId) end

---@return boolean
function MumbleIsActive() end

---@return boolean
function MumbleIsConnected() end

---@param player integer
---@return boolean
function MumbleIsPlayerTalking(player) end

---@param channel integer
function MumbleRemoveVoiceChannelListen(channel) end

---@param targetId integer
---@param channel integer
function MumbleRemoveVoiceTargetChannel(targetId, channel) end

---@param targetId integer
---@param player integer
function MumbleRemoveVoiceTargetPlayer(targetId, player) end

---@param targetId integer
---@param serverId integer
function MumbleRemoveVoiceTargetPlayerByServerId(targetId, serverId) end

---@param state boolean
function MumbleSetActive(state) end

---@param distance number
function MumbleSetAudioInputDistance(distance) end

---@param intentHash Hash|string
function MumbleSetAudioInputIntent(intentHash) end

---@param distance number
function MumbleSetAudioOutputDistance(distance) end

---@param address string
---@param port integer
function MumbleSetServerAddress(address, port) end

---@param serverId integer
---@param submixId integer
function MumbleSetSubmixForServerId(serverId, submixId) end

---@param value number
function MumbleSetTalkerProximity(value) end

---@param channel integer
function MumbleSetVoiceChannel(channel) end

---@param targetId integer
function MumbleSetVoiceTarget(targetId) end

---@param player integer
---@param volume number
function MumbleSetVolumeOverride(player, volume) end

---@param serverId integer
---@param volume number
function MumbleSetVolumeOverrideByServerId(serverId, volume) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x0035bb914316f1e3(p0, p1, p2, p3) end

---@param blip integer
---@return integer
function N_0x003e92ba477f9d7f(blip) end

---@param vehicleClass integer
---@return number
function N_0x00c09f246abedd82(vehicleClass) end

---@param p0 integer
---@return boolean
function N_0x01095c95cd46b624(p0) end

---@param makeupColorIndex integer
---@return integer outR
---@return integer outG
---@return integer outB
function N_0x013e5cfc38cd5387(makeupColorIndex) end

function N_0x0150b6ff25a9e2e5() end

---@param toggle boolean
function N_0x015c49a93e3e086e(toggle) end

---@param posMinX number
---@param posMinY number
---@param posMinZ number
---@param posMaxX number
---@param posMaxY number
---@param posMaxZ number
---@return integer
function N_0x01708e8dd3ff8c65(posMinX, posMinY, posMinZ, posMaxX, posMaxY, posMaxZ) end

---@param componentHash Hash|string
---@return integer
function N_0x017568a8182d98a6(componentHash) end

---@return integer
function N_0x01a358d9128b7a86() end

---@return integer
function N_0x01abce5e7cbda196() end

---@param vehicle integer
---@param intensity number
function N_0x01bb4d577d38bd9e(vehicle, intensity) end

---@param vehicle integer
---@param toggle boolean
function N_0x02398b627547189c(vehicle, toggle) end

---@param garageHash Hash|string
---@param player integer
---@param p2 number
---@param p3 integer
---@return boolean
function N_0x024a60deb0ea69f0(garageHash, player, p2, p3) end

---@param p1 unknown
---@return boolean
---@return unknown p0
function N_0x02a8bec6fd9af660(p1) end

---@param p0 number
function N_0x02ac28f3a01fa04a(p0) end

---@return boolean
function N_0x02ada21ea2f6918f() end

---@param netSceneId integer
---@return integer
function N_0x02c40bf885c567b6(netSceneId) end

---@param overrideSettingsName string
function N_0x02deaac8f8ea7fe7(overrideSettingsName) end

---@param radioStation string
---@param trackListName string
function N_0x031acb6aba18c729(radioStation, trackListName) end

---@param vehicle integer
---@param value integer
function N_0x0350e7e17ba767d0(vehicle, value) end

---@param object integer
---@return boolean
function N_0x0378c08504160d0d(object) end

---@param object integer
---@param enabled boolean
function N_0x0379daf89ba09aa5(object, enabled) end

---@return integer
function N_0x03a93ff1a2ca0864() end

---@param doorHash Hash|string
---@param rate number
---@param requestDoor boolean
---@param forceUpdate boolean
function N_0x03c27e13b42a0e82(doorHash, rate, requestDoor, forceUpdate) end

function N_0x03fc694ae06c5a20() end

---@param offset integer
---@param limit integer
function N_0x040addcbafa1018a(offset, limit) end

function N_0x042e4b70b93e6054() end

---@param oldPortalSettingsName string
---@param newPortalSettingsName string
function N_0x044dbad7a7fa2be5(oldPortalSettingsName, newPortalSettingsName) end

---@return boolean
function N_0x0467c11ed88b7d28() end

function N_0x047cbed6f6f8b63c() end

---@param padIndex integer
---@param control integer
---@param p2 boolean
---@return string
function N_0x0499d7b09fc9b407(padIndex, control, p2) end

---@return unknown data
function N_0x04d90ba8207ada2d() end

---@param colorID integer
---@return boolean
function N_0x0525a2c2562f3cd4(colorID) end

---@param entity Entity
---@param flags1 integer
---@param flags2 integer
---@return integer
function N_0x052837721a854ec7(entity, flags1, flags2) end

---@param p0 Hash|string
---@return boolean
---@return unknown p1
function N_0x052991e59076e4e4(p0) end

---@param cutsceneEntName string
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@param modelHash Hash|string
function N_0x0546524ade2e9723(cutsceneEntName, componentId, drawableId, textureId, modelHash) end

---@param hash Hash|string
---@return boolean
function N_0x0564b9ff9631b82c(hash) end

function N_0x058f43ec59a8631a() end

---@param x number
---@param y number
---@param z number
---@param interiorType string
---@return integer
function N_0x05b7a89bd78797fc(x, y, z, interiorType) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x05f04155a226fbbf(p0, p1, p2, p3) end

---@return boolean
function N_0x0626a247d2405330() end

function N_0x062d5ead4da2fa6a() end

---@param ped Ped
---@param toggle boolean
function N_0x0653b735bfbdfe87(ped, toggle) end

---@param vehicle integer
---@param toggle boolean
function N_0x06582aff74894c75(vehicle, toggle) end

---@param weaponHash Hash|string
---@return number
function N_0x065d2aacad8cf7a4(weaponHash) end

---@param vehicle integer
---@param toggle boolean
function N_0x068f64f2470f9656(vehicle, toggle) end

---@param maximumValue integer
function N_0x06a320535f5f0248(maximumValue) end

---@param cutsceneName string
function N_0x06a3524161c502ba(cutsceneName) end

---@param doorHash Hash|string
---@param toggle boolean
function N_0x06c0023bed16dd6b(doorHash, toggle) end

---@param p0 boolean
function N_0x06f761ea47c1d3ed(p0) end

---@param entity Entity
function N_0x06faacd625d80caa(entity) end

---@param hash Hash|string
---@param amount integer
---@return boolean
function N_0x071e2a839de82d90(hash, amount) end

---@param p0 unknown
---@return integer
function N_0x073ca26b079f956e(p0) end

---@return boolean
function N_0x075f1d57402c93ba() end

---@param unused unknown
---@return boolean
function N_0x07c313f94746702c(unused) end

---@param token integer
---@return boolean
function N_0x07c61676e5bb52cd(token) end

---@return boolean
---@return unknown networkHandle
function N_0x07dd29d5e22763f1() end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return boolean
function N_0x07fb139b592fa687(x1, y1, x2, y2) end

---@param p0 integer
---@param p1 integer
---@param amount integer
function N_0x08a1b82b91900682(p0, p1, amount) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0x08b0ca7a6ab3ac32(p0, p1, p2) end

---@return integer
function N_0x08c2d6c52a3104bb() end

---@param pickupHash Hash|string
---@return Hash
function N_0x08f96ca6c551ad51(pickupHash) end

---@param x number
---@param y number
---@param z number
function N_0x0923dbf87dff735e(x, y, z) end

function N_0x098760c7461724cd() end

---@param heistName string
---@param cashEarned integer
---@param xpEarned integer
---@return boolean
function N_0x098ab65b9ed9a9ec(heistName, cashEarned, xpEarned) end

---@param id integer
---@return boolean
function N_0x09c0403ed9a751c2(id) end

---@param colorID integer
---@return boolean
function N_0x09e7eca981d9b210(colorID) end

function N_0x0a123435a26c36cd() end

---@param labelName string
function N_0x0a24da3a41b718f5(labelName) end

---@param vehicle integer
---@param x number
---@param y number
---@param z number
function N_0x0a3f820a9a9a9ac5(vehicle, x, y, z) end

function N_0x0a436b8643716d14() end

function N_0x0a46af8a78dc5e0a() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function N_0x0a50d2604e05cb94(p0, p1, p2, p3, p4) end

---@param numCheckpoints integer
---@param numLaps integer
---@param numPlayers integer
---@param localPlayer integer
function N_0x0a60017f841a54f2(numCheckpoints, numLaps, numPlayers, localPlayer) end

---@param vehicle integer
---@param p1 boolean
function N_0x0a6a279f3aa4fd70(vehicle, p1) end

---@return integer
function N_0x0a6d923dffc9bd89() end

---@param cam integer
---@param cam2 integer
---@param p2 integer
---@param p3 integer
function N_0x0a9f2a468b328e74(cam, cam2, p2, p3) end

---@param cutsceneName string
---@return integer
function N_0x0abc54de641dc0fc(cutsceneName) end

---@param zoneId integer
---@return boolean
function N_0x0abf535877897560(zoneId) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 unknown
---@return unknown
function N_0x0ad9710cee2f590f(p0, p1, p2, p3, p4, p5, p6) end

---@param videoCliphash Hash|string
---@return boolean
function N_0x0ad973ca1e077b60(videoCliphash) end

---@param vehicle integer
---@param influenceWantedLevel boolean
function N_0x0ad9e8f87ff7c16f(vehicle, influenceWantedLevel) end

---@param milestoneId integer
---@return boolean
function N_0x0ae1f1653b554ab9(milestoneId) end

---@param distance number
function N_0x0af7b437918103b3(distance) end

function N_0x0afc4af510774b47() end

---@return integer
function N_0x0afce529f69b21ff() end

---@return boolean
function N_0x0b0cc10720653f3b() end

---@param FilePath string
---@param Name string
---@param p2 boolean
---@return integer
function N_0x0b203b4afde53a4f(FilePath, Name, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0x0b39cf0d53f1c883(p0, p1, p2) end

---@param enable boolean
function N_0x0b568201dd99f0eb(enable) end

---@param multiplier number
function N_0x0b919e1fb47cc4e0(multiplier) end

---@param vehicle integer
---@param damageSection integer
---@param damageScale number
function N_0x0bbb9a7a8ffe931b(vehicle, damageSection, damageScale) end

---@param modelHash Hash|string
---@return boolean
function N_0x0bc3144deb678666(modelHash) end

---@param p0 unknown
---@param p1 unknown
---@param p2 number
function N_0x0bca1d2c47b0d269(p0, p1, p2) end

---@param vehicle integer
---@return boolean
function N_0x0be4be946463f917(vehicle) end

---@param modelHash Hash|string
---@param p1 integer
function N_0x0bf3b3bd47d79c08(modelHash, p1) end

---@return integer
function N_0x0c0c4e81e1ac60a0() end

---@param object integer
---@return boolean
function N_0x0c112765300c7e1e(object) end

---@return number
function N_0x0c15b0e443b2349d() end

---@param scaleformName string
---@return boolean
function N_0x0c1c5d756fb5f337(scaleformName) end

---@return integer
function N_0x0c1f7d49c39d2289() end

---@param ped Ped
---@param toggle boolean
function N_0x0c4bbf625ca98c4e(ped, toggle) end

---@param index integer
---@param name string
---@param cash integer
---@param rp integer
---@param lvl integer
---@param colour integer
---@return boolean
function N_0x0c5a80a9e096d529(index, name, cash, rp, lvl, colour) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x0c82d21a77c22d49(p0, p1, p2, p3) end

---@param thickness number
function N_0x0c8fac83902a62df(thickness) end

---@param p0 boolean
---@param p1 boolean
function N_0x0c978fda19692c2c(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x0cb1be0633c024a8(p0, p1, p2, p3) end

---@param p0 boolean
---@return integer
function N_0x0cd9ab83489430ea(p0) end

---@param vehicle integer
---@param toggle boolean
function N_0x0cdda42f9e360ca6(vehicle, toggle) end

---@param transitionTimeInMs integer
function N_0x0cf97f497fe7d048(transitionTimeInMs) end

---@param vehicle integer
---@param state integer
function N_0x0d5f65a8f4ebdab5(vehicle, state) end

---@return integer
function N_0x0d6ca79eeebd8ca3() end

---@return boolean
function N_0x0dbd5d7e3c5bec3b() end

---@param player integer
---@return number
function N_0x0e3a041ed6ac2b45(player) end

---@param value integer
---@param commaSeparated boolean
function N_0x0e4c749ff9de9cc4(value, commaSeparated) end

---@param playerCount integer
function N_0x0e4f77f7b9d74d84(playerCount) end

---@return unknown data
function N_0x0eacdf8487d5155a() end

---@param p0 unknown
---@return boolean
function N_0x0eaeb0db4b132399(p0) end

---@param vehicle integer
---@param p1 boolean
function N_0x0f3b4d4e43177236(vehicle, p1) end

---@return boolean
function N_0x0f70731baccfbb96() end

---@param plateText string
---@return boolean
---@return integer tokenOut
function N_0x0f73393bac7e6730(plateText) end

---@param cam integer
---@param cam2 integer
---@param length integer
---@param p3 integer
function N_0x0fb82563989cf4fb(cam, cam2, length, p3) end

---@param name string
function N_0x0fde9dbfc0a6bc65(name) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x0fe8e1fcd2b86b33(p0, p1, p2, p3) end

---@param toggle boolean
function N_0x0ff2862b61a58af9(toggle) end

---@param character integer
---@param collection integer
---@param preset integer
---@return integer
function N_0x10144267dd22866c(character, collection, preset) end

---@param speedzone integer
---@return boolean
function N_0x1033371fc8e842a7(speedzone) end

---@param vehicle integer
---@param hash Hash|string
function N_0x10655fab9915623d(vehicle, hash) end

---@param p0 boolean
---@param p1 boolean
function N_0x1072f115dab0717e(p0, p1) end

---@param red integer
---@param green integer
---@param blue integer
function N_0x1086127b3a63505e(red, green, blue) end

---@param vehicle integer
---@param toggle boolean
function N_0x1087bc8ec540daeb(vehicle, toggle) end

---@param vehicle integer
---@param speed number
function N_0x1093408b4b9d1146(vehicle, speed) end

---@return boolean
function N_0x109697e2ffbac8a1() end

---@return integer
function N_0x10bd227a753b0d84() end

---@param hudIndex integer
---@return boolean
function N_0x10bddbfc529428dd(hudIndex) end

function N_0x10d373323e5b9c0d() end

---@return unknown
function N_0x1121bfa1a1a522a8() end

---@return boolean
function N_0x112cef1615a1139f() end

---@param p0 unknown
function N_0x113e6e3e50e286b0(p0) end

---@param state boolean
function N_0x1185a8087587322c(state) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x1187cb58d7f3bed7(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0x11b0a20c493f7e36(p0, p1, p2) end

---@param name string
function N_0x11b56fbbf7224868(name) end

---@param object integer
---@return boolean
function N_0x11d1e53a726891fe(object) end

---@param vehicleModel Hash|string
function N_0x11fa5d3479c7dd47(vehicleModel) end

---@param statHash Hash|string
---@param value integer
---@param p2 integer
function N_0x11ff1c80276097ed(statHash, value, p2) end

---@param vehicle integer
---@param toggle boolean
function N_0x1201e8a3290a3b98(vehicle, toggle) end

---@param dataSize integer
---@return integer
---@return unknown data
function N_0x120364de2845daf8(dataSize) end

---@param amount integer
---@param act integer
---@param player integer
---@param cm number
function N_0x121fb4dddc2d5291(amount, act, player, cm) end

---@param pickupHash Hash|string
---@param x number
---@param y number
---@param z number
---@param placeOnGround boolean
---@param modelHash Hash|string
---@return integer
function N_0x125494b98a21aaf7(pickupHash, x, y, z, placeOnGround, modelHash) end

---@param mode integer
function N_0x12561fcbb62d5b9c(mode) end

---@param player integer
---@return vector3
function N_0x125e6d638b8605d4(player) end

---@param ped Ped
function N_0x1280804f7cfd2d6c(ped) end

---@param ped Ped
---@param toggle boolean
function N_0x129466ed55140f8d(ped, toggle) end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param p3 integer
---@param p4 integer
---@param p5 integer
---@param p6 integer
---@param p7 integer
---@param p8 integer
---@param p9 integer
---@param p10 integer
---@param p11 integer
function N_0x12995f2e53ffa601(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) end

---@param p0 boolean
---@return integer
function N_0x12b6281b6c6706c0(p0) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x12d148d26538d0f9(p0, p1, p2, p3) end

---@param id integer
---@return boolean
function N_0x1327e2fe9746baee(id) end

---@param padIndex integer
---@return boolean
function N_0x13337b38db572509(padIndex) end

---@param p0 unknown
---@return boolean
function N_0x13518ff1c6b28938(p0) end

---@return boolean
function N_0x1353f87e89946207() end

---@return boolean
---@return unknown networkHandle
function N_0x135f9b7b7add2185() end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param isLeader boolean
---@param isImportant boolean
---@param clanHandle integer
---@param gamerStr string
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function N_0x137bc35589e34e1e(crewTypeIsPrivate, crewTagContainsRockstar, rank, isLeader, isImportant, clanHandle, gamerStr, r, g, b) end

---@return integer
function N_0x13c4b962653a5280() end

---@param ped Ped
---@return boolean
function N_0x14590ddbedb1ec85(ped) end

---@param ped Ped
---@return number
function N_0x1461b28a06717d68(ped) end

function N_0x14621bb1df14e2b2() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function N_0x1464e17207cd36e2(p0, p1, p2, p3, p4) end

---@return boolean
function N_0x14832bf2aba53fc5() end

---@param ped Ped
---@param targetPed Ped
---@param p2 unknown
function N_0x148b08c2d2acb884(ped, targetPed, p2) end

---@param cam integer
---@param ped Ped
---@param boneIndex integer
---@param xRot number
---@param yRot number
---@param zRot number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param isRelative boolean
function N_0x149916f50c34a40d(cam, ped, boneIndex, xRot, yRot, zRot, xOffset, yOffset, zOffset, isRelative) end

---@param density number
---@param applyValue number
function N_0x149aee66f0cb3a99(density, applyValue) end

---@param toggle boolean
function N_0x14c9fdcc41f81f63(toggle) end

---@return boolean
---@return unknown p0
---@return unknown p1
function N_0x152d90e4c1b4738a() end

---@param entity Entity
---@param groupName string
---@param fadeIn number
function N_0x153973ab99fe8980(entity, groupName, fadeIn) end

---@param gamerTagId integer
---@param health integer
---@param maximumHealth integer
function N_0x1563fe35e9928e67(gamerTagId, health, maximumHealth) end

---@param labelTitle string
---@param labelMsg string
---@param p2 integer
---@param p3 integer
---@param labelMsg2 string
---@param p5 boolean
---@param p6 integer
---@param p7 integer
---@param p8 string
---@param p9 string
---@param background boolean
---@param errorCode integer
function N_0x15803fec3b9a872b(labelTitle, labelMsg, p2, p3, labelMsg2, p5, p6, p7, p8, p9, background, errorCode) end

---@param contentId string
---@param latestVersion boolean
---@param contentTypeName string
---@return boolean
function N_0x158ec424f35ec469(contentId, latestVersion, contentTypeName) end

---@param signalLevel number
function N_0x159b7318403a1cd8(signalLevel) end

function N_0x15cfa549788d35ef() end

---@param p0 string
function N_0x15e33297c3e8dc60(p0) end

---@param p0 number
function N_0x15e69e2802c24b8d(p0) end

---@param entity Entity
---@param toggle boolean
function N_0x15f944730c832252(entity, toggle) end

---@param p0 unknown
---@return boolean
function N_0x15ff52b809db2353(p0) end

---@param level number
function N_0x1600fd8cf72ebc12(level) end

---@param doorHash Hash|string
---@return integer
function N_0x160aa1b32f6139b8(doorHash) end

---@return number
function N_0x162f9d995753dc19() end

---@param noise number
function N_0x1636d7fc127b10d2(noise) end

---@param xPos number
---@param yPos number
---@param zPos number
---@param heading number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@return vector3
function N_0x163e252de035a133(xPos, yPos, zPos, heading, xOffset, yOffset, zOffset) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param rotationOrder integer
---@return unknown
---@return vector3 outPosition
---@return vector3 outRotation
function N_0x163f8b586bc95f2a(x, y, z, radius, modelHash, rotationOrder) end

---@param radioStation string
function N_0x1654f24a88a8e3fe(radioStation) end

---@param p0 string
---@return integer
function N_0x1670f8d05056f257(p0) end

---@param r integer
---@param g integer
---@param b integer
---@param a integer
function N_0x16a304e6cb2bfab9(r, g, b, a) end

---@param vehicle integer
---@param trailer integer
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param coordsX number
---@param coordsY number
---@param coordsZ number
---@param rotationX number
---@param rotationY number
---@param rotationZ number
---@param disableColls number
function N_0x16b5e274bde402f8(vehicle, trailer, offsetX, offsetY, offsetZ, coordsX, coordsY, coordsZ, rotationX, rotationY, rotationZ, disableColls) end

---@param player integer
---@return boolean
function N_0x16d3d49902f697bb(player) end

---@param x number
---@param y number
---@param z number
---@param p3 integer
---@return boolean
---@return vector3 outPosition
function N_0x16f46fb18c8009e4(x, y, z, p3) end

---@param p0 boolean
function N_0x170f541e1cadd1de(p0) end

---@param id integer
---@return boolean
function N_0x171bafb3c60389f4(id) end

---@param p0 integer
---@param p1 integer
---@return integer
function N_0x171df6a0c07fb3dc(p0, p1) end

---@param gxtEntryHash Hash|string
function N_0x17299b63c7683a2b(gxtEntryHash) end

---@return integer
function N_0x172f75b6ee2233ba() end

function N_0x17330ebf2f2124a8() end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function N_0x17430b918701c342(red, green, blue, alpha) end

function N_0x17440aa15d1d3739() end

---@param token integer
---@return boolean
function N_0x1753344c770358ae(token) end

---@param garageHash Hash|string
---@param player integer
---@param p2 integer
---@return boolean
function N_0x1761dc5d8471cbaa(garageHash, player, p2) end

---@param count integer
function N_0x17ad8c9706bdd88a(count) end

---@param ped Ped
---@return boolean
function N_0x17df68d720aa77f8(ped) end

function N_0x17e0198b3882c2cb() end

---@param p0 unknown
function N_0x17f7471eaca78290(p0) end

---@param contentHash Hash|string
---@return integer
function N_0x187382f8a3e0a6c3(contentHash) end

function N_0x1888694923ef4591() end

---@param entity Entity
---@param fadeOut number
function N_0x18eb48cfc41f2ea0(entity, fadeOut) end

---@param garageHash Hash|string
---@param vehicles boolean
---@param peds boolean
---@param objects boolean
---@param isNetwork boolean
function N_0x190428512b240692(garageHash, vehicles, peds, objects, isNetwork) end

---@param vehicle integer
---@param toggle boolean
function N_0x192547247864dfdd(vehicle, toggle) end

---@param contextHash Hash|string
---@param nameHash Hash|string
---@return boolean
---@return number value
function N_0x1950dae9848a4739(contextHash, nameHash) end

---@param plateText string
---@param plateData string
---@return boolean
---@return integer tokenOut
function N_0x1989c6e6f67e76a8(plateText, plateData) end

---@return integer
function N_0x19cafa3c87f7c2ff() end

---@param ped Ped
---@param ped2 Ped
function N_0x19d1b791cb3670fe(ped, ped2) end

---@param intensity number
function N_0x19e50eb6e33e1d28(intensity) end

function N_0x1a31fe0049e542f6() end

---@param p0 unknown
function N_0x1a67dfbf1f5c3835(p0) end

---@param vehicle integer
---@param bLatched boolean
function N_0x1a78ad3d8240536f(vehicle, bLatched) end

---@param modifierName1 string
---@param modifierName2 string
function N_0x1a8e2c8b9cf4549c(modifierName1, modifierName2) end

---@param vehicle integer
---@param toggle boolean
function N_0x1aa8a837d2169d94(vehicle, toggle) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function N_0x1accfba3d8dab2ee(p0, p1) end

---@param player1 integer
---@param script string
---@param player2 integer
---@return boolean
function N_0x1ad5b71586b94820(player1, script, player2) end

---@param p0 number
function N_0x1b0b4aeed5b9b41c(p0) end

---@param vehicle integer
---@param toggle boolean
function N_0x1b212b26dd3c04df(vehicle, toggle) end

---@return integer
function N_0x1b2366c3f2a5c8df() end

---@param ped Ped
---@param pedRace integer
---@param pvgHash integer
function N_0x1b7abe26cbcbf8c7(ped, pedRace, pvgHash) end

---@param toggle boolean
function N_0x1b857666604b1a74(toggle) end

---@param ped Ped
---@param checkpoint integer
---@param lap integer
---@param time integer
function N_0x1bb299305c3e8c13(ped, checkpoint, lap, time) end

---@param vehicle integer
---@param toggle boolean
function N_0x1bbac99c0bc53656(vehicle, toggle) end

---@param vehicle integer
---@param enableFanbeltDamage boolean
function N_0x1c073274e065c6d2(vehicle, enableFanbeltDamage) end

---@param achievement integer
---@return integer
function N_0x1c186837d0619335(achievement) end

---@param p0 unknown
---@param p1 unknown
function N_0x1c1b69fae509ba97(p0, p1) end

---@return boolean
function N_0x1c2473301b1c66ba() end

---@param x number
---@param y number
---@param z number
---@param p3 number
---@param rotation number
---@param p5 number
---@param width number
---@param height number
---@param p8 number
---@param scale number
---@param glowIntensity number
---@param normalHeight number
---@param heightDiff number
function N_0x1c4fc5752bcd8e48(x, y, z, p3, rotation, p5, width, height, p8, scale, glowIntensity, normalHeight, heightDiff) end

---@param bStopImmediately boolean
function N_0x1c9d7949fa533490(bStopImmediately) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function N_0x1cae5d2e3f9a07f0(p0, p1, p2, p3, p4, p5) end

---@param hudColorIndex integer
---@param hudColorIndex2 integer
function N_0x1ccc708f0f850613(hudColorIndex, hudColorIndex2) end

---@param scaleform integer
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param p7 number
---@param p8 number
---@param p9 number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param p13 unknown
function N_0x1ce592fdc749d6f5(scaleform, posX, posY, posZ, rotX, rotY, rotZ, p7, p8, p9, scaleX, scaleY, scaleZ, p13) end

---@param vehicle integer
---@param toggle boolean
function N_0x1cf38d529d7441d9(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function N_0x1d97d1e3a70a649f(vehicle, toggle) end

---@param vehicle integer
---@return boolean
function N_0x1da0da9cb3f0c8bf(vehicle) end

---@return boolean
function N_0x1dd2139a9a20dce8() end

---@param vehicle integer
---@param canBeLockedOn boolean
---@param unk boolean
function N_0x1dda078d12879eee(vehicle, canBeLockedOn, unk) end

---@param contentId string
---@param baseContentId string
---@param contentTypeName string
---@return boolean
function N_0x1de0f5f50d723caa(contentId, baseContentId, contentTypeName) end

function N_0x1e45b34adebee48e() end

---@param picTxd string
---@param picTxn string
---@param flash boolean
---@param iconType integer
---@param nameStr string
---@param subtitleStr string
---@param durationMultiplier number
---@return integer
function N_0x1e6611149db3db6b(picTxd, picTxn, flash, iconType, nameStr, subtitleStr, durationMultiplier) end

---@param ped Ped
---@return integer
function N_0x1e98817b311ae98a(ped) end

---@param toggle boolean
function N_0x1eac5f91bcbc5073(toggle) end

---@param eventType integer
---@param enable boolean
function N_0x1eae0a6e978894a2(eventType, enable) end

---@param spriteId integer
function N_0x1eae6dd17b7a5efa(spriteId) end

---@param unused unknown
function N_0x1ee7d8df4425f053(unused) end

---@param attrHash Hash|string
---@param value integer
---@return boolean
function N_0x1f1e9682483697c7(attrHash, value) end

---@param vehicle integer
---@param p1 boolean
function N_0x1f2e4e06dea8992b(vehicle, p1) end

---@param cargobob integer
---@param entity Entity
function N_0x1f34b0626c594380(cargobob, entity) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 unknown
---@param p8 unknown
---@return unknown
function N_0x1f3f018bc3afa77c(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@return integer
function N_0x1f471b79acc90bef() end

---@param vehicle integer
---@param actHighSpeed boolean
function N_0x1f9fb66f3a3842d2(vehicle, actHighSpeed) end

---@param toggle boolean
function N_0x1fc289a0c3ff470f(toggle) end

---@param vehicle integer
---@param flag integer
function N_0x1fd09e7390a74d54(vehicle, flag) end

---@param p0 unknown
function N_0x1fda0aa679c9919b(p0) end

function N_0x1ff6bf9a63e5757f() end

---@param p2 string
---@return string
---@return integer p0
---@return integer p1
function N_0x20194d48eaec9a41(p2) end

---@param cam integer
---@param entity Entity
---@param xRot number
---@param yRot number
---@param zRot number
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param isRelative boolean
function N_0x202a5ed9ce01d6e7(cam, entity, xRot, yRot, zRot, xOffset, yOffset, zOffset, isRelative) end

---@return unknown data
function N_0x203b381133817079() end

---@param vehicle integer
---@param toggle boolean
function N_0x206bc5dc9d1ac70a(vehicle, toggle) end

---@return number
function N_0x20ac25e781ae4a84() end

function N_0x20fe7fdfeead38c0() end

---@param vehicle integer
---@param toggle boolean
function N_0x21115bcd6e44656a(vehicle, toggle) end

---@param src unknown
---@param size integer
---@return unknown dst
function N_0x213aeb2b90cba7ac(src, size) end

---@param p0 string
function N_0x2162c446dfdf38fd(p0) end

---@param vehicle integer
---@param doorIndex integer
---@return Ped
function N_0x218297bf0cfd853b(vehicle, doorIndex) end

---@param trackIndex integer
---@param frequency integer
function N_0x21973bbf8d17edfa(trackIndex, frequency) end

---@param x number
---@param y number
---@param z number
---@param rad number
---@param p4 unknown
---@param p5 unknown
---@return unknown
function N_0x219c7b8d53e429fd(x, y, z, rad, p4, p5) end

---@param entity Entity
---@return boolean
function N_0x21d04d7bc538c146(entity) end

---@param vehicleName string
function N_0x21e253a7f8da5dfb(vehicleName) end

---@param tvChannel integer
---@param playlistName string
---@param hour integer
function N_0x2201c576facaebe8(tvChannel, playlistName, hour) end

---@param ped Ped
---@param p1 boolean
---@param p2 boolean
function N_0x2208438012482a1a(ped, p1, p2) end

---@return boolean
function N_0x2272b0a1343129f4() end

---@param toggle boolean
function N_0x228e5c6ad4d74bfd(toggle) end

---@param p0 boolean
function N_0x22a249a53034450a(p0) end

---@param p0 unknown
---@return boolean
function N_0x22da66936e0fff37(p0) end

---@param vehicle integer
---@return integer
function N_0x22fecb546c276a30(vehicle) end

---@return Hash
function N_0x2309595ad6145265() end

---@param p1 integer
---@return integer p0
function N_0x236406f60cf216d6(p1) end

---@return integer
function N_0x23789e777d14ce44() end

---@param player integer
---@return boolean
function N_0x237d5336a9a54108(player) end

function N_0x23b59d8912f94246() end

---@param toggle boolean
function N_0x23ba6b0c2ad7b0d3(toggle) end

---@param blip integer
---@param toggle boolean
function N_0x23c3eb807312f01a(blip, toggle) end

---@param p0 string
function N_0x23d69e0465570028(p0) end

---@return boolean
function N_0x23dfb504655d0ce4() end

---@param hudIndex integer
---@return boolean
function N_0x2432784aca090da4(hudIndex) end

---@param p0 unknown
---@return string
function N_0x24409fc4c55cb22d(p0) end

---@param boat integer
---@return boolean
function N_0x2467a2d807d37ca3(boat) end

---@param ped Ped
---@param ammoType Hash|string
---@param ammo integer
function N_0x2472622ce1f2d45f(ped, ammoType, ammo) end

---@param hash Hash|string
---@return boolean
function N_0x247f0f73a182ea0b(hash) end

---@param p0 number
---@param p1 number
---@param p2 number
function N_0x2485d34e50a22e84(p0, p1, p2) end

---@return string
function N_0x24da7d7667fd7b09() end

---@param interior integer
---@return vector3 position
---@return Hash nameHash
function N_0x252bdc06b73fa6ea(interior) end

---@param vehicle integer
---@param toggle boolean
function N_0x25367de49d64cf16(vehicle, toggle) end

---@param blip integer
---@param toggle boolean
function N_0x25615540d894b814(blip, toggle) end

---@return unknown
function N_0x257ed0fadf750bcf() end

---@param toggle boolean
function N_0x2587a48bc88dfadf(toggle) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@return unknown
function N_0x25b99872d588a101(p0, p1, p2, p3, p4, p5) end

function N_0x25f87b30c382fca7() end

---@return unknown data
function N_0x2605663bd4f23b5d() end

---@param vehicle integer
---@param distance number
---@param duration integer
---@param bControlVerticalVelocity boolean
function N_0x260be8f09e326a20(vehicle, distance, duration, bControlVerticalVelocity) end

---@param object integer
---@return number
function N_0x260ee4fdbdf4db01(object) end

---@param p0 unknown
---@return boolean
function N_0x2615aa2a695930c1(p0) end

function N_0x2632482fd6b9ab87() end

---@param ped Ped
---@param flags integer
function N_0x26695ec767728d84(ped, flags) end

---@param entity Entity
---@param toggle boolean
function N_0x267c78c60e806b9a(entity, toggle) end

---@param player integer
---@param rotationOrder integer
---@return vector3
function N_0x26903d9cd1175f2c(player, rotationOrder) end

---@param ped Ped
---@return boolean
function N_0x26af0e8e30bd2a2c(ped) end

---@param disableExtraTrickForces boolean
function N_0x26d99d5a82fd18e8(disableExtraTrickForces) end

---@param vehicle integer
---@param disableExplode boolean
function N_0x26e13d440e7f6064(vehicle, disableExplode) end

---@param inviteIndex integer
---@return Hash
function N_0x26e1cd96b0903d60(inviteIndex) end

function N_0x2708fc083123f9ff() end

---@param vehicles boolean
---@param peds boolean
function N_0x271401846bd26e92(vehicles, peds) end

---@param ropeId integer
---@return boolean
function N_0x271c9d3aca5d6409(ropeId) end

---@param toggle boolean
function N_0x271cc6ab59ebf9a5(toggle) end

---@param contentId string
---@param bookmarked boolean
---@param contentTypeName string
---@return boolean
function N_0x274a1519dfc1094f(contentId, bookmarked, contentTypeName) end

---@param character integer
---@return integer
function N_0x278f76c3b0a8f109(character) end

---@param vehicle integer
---@param toggle boolean
function N_0x279d50de5652d935(vehicle, toggle) end

---@param vehicle integer
---@param frontBumper boolean
---@return boolean
function N_0x27b926779deb502d(vehicle, frontBumper) end

function N_0x27cb772218215325() end

---@param scale number
function N_0x27e32866e9a5c416(scale) end

---@return boolean
function N_0x27f76cc6c55ad30e() end

---@param index integer
function N_0x2801d0012266df07(index) end

---@param randomInt integer
---@return number x
---@return number y
---@return number z
function N_0x280c7e3ac7f56e90(randomInt) end

---@param attrHash Hash|string
---@param value string
---@return boolean
function N_0x287f1f75d2803595(attrHash, value) end

---@param vehicle integer
---@param toggle boolean
function N_0x28b18377eb6e25f6(vehicle, toggle) end

function N_0x2916a928514c9827() end

---@param vehicle integer
---@return boolean
function N_0x291e373d483e7ee7(vehicle) end

---@return boolean
function N_0x292564c735375edf() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param textureDict string
---@param textureName string
---@param u1 number
---@param v1 number
---@param w1 number
---@param u2 number
---@param v2 number
---@param w2 number
---@param u3 number
---@param v3 number
---@param w3 number
function N_0x29280002282f1928(x1, y1, z1, x2, y2, z2, x3, y3, z3, red, green, blue, alpha, textureDict, textureName, u1, v1, w1, u2, v2, w2, u3, v3, w3) end

---@param vehicle integer
---@param toggle boolean
function N_0x2970eaa18fd5e42f(vehicle, toggle) end

---@return boolean
function N_0x299ef3c576773506() end

---@param x number
---@param y number
---@return number
function N_0x29c24bfbed8ab8fb(x, y) end

---@param ped Ped
---@param enabled boolean
function N_0x29da3ca8d8b2692d(ped, enabled) end

---@param context integer
---@param viewMode integer
function N_0x2a2173e46daecd12(context, viewMode) end

---@return unknown
function N_0x2a25adc48f87841f() end

---@param name string
function N_0x2a2a52824db96700(name) end

---@param cutsceneEntName string
---@param ped Ped
---@param modelHash Hash|string
function N_0x2a56c06ebef2b0d9(cutsceneEntName, ped, modelHash) end

---@param heli integer
---@param isAudible boolean
---@param isInvisible boolean
---@param netScriptEntityId integer
function N_0x2a5e0621dd815a9a(heli, isAudible, isInvisible, netScriptEntityId) end

---@param vehicle integer
---@param instantly boolean
function N_0x2a69ffd1b42bff9e(vehicle, instantly) end

---@param index integer
---@return integer
function N_0x2a7776c709904ab0(index) end

---@param vehicle integer
---@param health number
function N_0x2a86a0475b6a1434(vehicle, health) end

---@param scanForSaving boolean
---@return boolean
function N_0x2a893980e96b659a(scanForSaving) end

---@param vehicle integer
---@param p1 number
function N_0x2a8f319b392e7b3f(vehicle, p1) end

---@param groupName string
function N_0x2acabed337622df2(groupName) end

---@param entity Entity
function N_0x2aed6301f67007d5(entity) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@return boolean
function N_0x2b16a3bff1fbce49(ped, componentId, drawableId, textureId) end

---@param p0 unknown
---@param p2 boolean
---@return unknown p1
function N_0x2b171e6b2f64d8df(p0, p2) end

---@param netID integer
---@param toggle boolean
function N_0x2b1813aba29016c5(netID, toggle) end

---@return number
function N_0x2b2a2cc86778b619() end

---@param entity Entity
function N_0x2b3334bca57cd799(entity) end

function N_0x2b3a8f7ca3a38fde() end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@param section string
---@return Hash
function N_0x2b4cdca6f07ff3da(index, spStat, charStat, character, section) end

---@param ped Ped
---@param toggle boolean
function N_0x2b5aa717a181fb4c(ped, toggle) end

---@return integer
function N_0x2b5e102e4a42f2bf() end

---@return integer
function N_0x2b626a0150e4d449() end

---@param vehicle integer
---@param toggle boolean
function N_0x2b6747faa9db9d6b(vehicle, toggle) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x2b69f5074c894811(p0, p1, p2, p3) end

---@param blip integer
---@param toggle boolean
function N_0x2b6d467dab714e8d(blip, toggle) end

---@param statTitle string
---@param iconEnum integer
---@param stepVal boolean
---@param barValue integer
---@param isImportant boolean
---@param picTxd string
---@param picTxn string
---@return integer
function N_0x2b7e9a4eaaa93c89(statTitle, iconEnum, stepVal, barValue, isImportant, picTxd, picTxn) end

---@return boolean
function N_0x2b949a1e6aec8f6a() end

---@param textureDict string
---@param textureName string
---@param screenX number
---@param screenY number
---@param width number
---@param height number
---@param heading number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function N_0x2bc54a8188768488(textureDict, textureName, screenX, screenY, width, height, heading, red, green, blue, alpha) end

---@param vehicle integer
---@param toggle boolean
function N_0x2be4bc731d039d5a(vehicle, toggle) end

function N_0x2bf72ad5b41aa739() end

---@param p0 integer
---@return boolean
function N_0x2c015348cf19ca1d(p0) end

---@param cargobob integer
---@param entity Entity
---@return boolean
function N_0x2c1d8b3b19e517cc(cargobob, entity) end

---@param entity Entity
---@param p1 boolean
function N_0x2c2e3dc128f44309(entity, p1) end

---@param phase number
function N_0x2c328af17210f009(phase) end

---@param camera integer
---@param p1 number
function N_0x2c654b4943bddf7c(camera, p1) end

---@param vehicle integer
---@return integer
function N_0x2c8cbfe1ea5fc631(vehicle) end

---@param amount integer
function N_0x2c8df5d129595281(amount) end

---@param fadeTime number
function N_0x2c96cdb04fca358e(fadeTime) end

---@param interior integer
function N_0x2ca429c029ccf247(interior) end

---@return boolean
function N_0x2cc848a861d01493() end

---@param statName Hash|string
---@return integer
function N_0x2ce056ff3723f00b(statName) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param speed number
---@param p5 boolean
---@return integer
function N_0x2ce544c68fb812a0(x, y, z, radius, speed, p5) end

---@param p0 integer
---@param p1 integer
---@param maxPlayers integer
---@param p3 boolean
---@return boolean
function N_0x2cfc76e0d087c994(p0, p1, maxPlayers, p3) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return unknown
function N_0x2d4259f1feb81da9(x1, y1, x2, y2) end

---@param ped Ped
---@param task string
---@param multiplier number
---@param p3 boolean
---@param animDict string
---@param flags integer
function N_0x2d537ba194896636(ped, task, multiplier, p3, animDict, flags) end

---@param enabled boolean
function N_0x2de6c5e2e996f178(enabled) end

---@param method_return integer
---@return integer
function N_0x2de7efa66b906036(method_return) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param interiorFlags integer
---@param scale number
---@param duration integer
function N_0x2df9038c90ad5264(p0, p1, p2, p3, p4, interiorFlags, scale, duration) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0x2e65248609523599(p0, p1, p2) end

---@param token integer
---@param plateIndex integer
---@return string
function N_0x2e89990ddff670c3(token, plateIndex) end

---@return boolean
function N_0x2eac52b4019e2782() end

function N_0x2ed61456317b8178() end

---@param xCoord number
---@param yCoord number
---@param zCoord number
---@param radius number
---@return boolean
function N_0x2f09f7976c512404(xCoord, yCoord, zCoord, radius) end

---@param charSlot integer
---@return boolean
function N_0x2f41d51ba3bcd1f1(charSlot) end

---@return boolean
function N_0x2fc5650b0271cb57() end

---@param vehicle integer
---@param toggle boolean
function N_0x300504b23bd3b711(vehicle, toggle) end

function N_0x302c91ab2d477f7e() end

---@param player integer
---@param toggle boolean
function N_0x3039ae5ad2c9c0c4(player, toggle) end

---@param p0 unknown
---@return boolean
function N_0x3054f114121c21ea(p0) end

---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p5 boolean
---@return unknown
---@return unknown p0
---@return unknown p4
function N_0x308f96458b7087cc(p1, p2, p3, p5) end

---@param statHash Hash|string
---@param value number
---@param p2 integer
function N_0x30a6614c1f7799b8(statHash, value, p2) end

---@return integer
function N_0x30b4fa1c82dd4b9f() end

---@return boolean
function N_0x30ca2ef91d15adf8() end

---@param vehicle integer
---@param angleRatio number
function N_0x30d779de7c4f6dd3(vehicle, angleRatio) end

---@param p0 unknown
function N_0x30de938b516f0ad2(p0) end

---@param ped Ped
---@return boolean
function N_0x30ed88d5e0c56a37(ped) end

---@param p0 integer
---@param p1 integer
---@param p2 Hash|string
---@param p3 boolean
---@param p4 boolean
function N_0x30fd873ece50e9f6(p0, p1, p2, p3, p4) end

---@param x number
---@param y number
---@param z number
function N_0x311438a071dd9b1a(x, y, z) end

---@param p0 number
function N_0x3117d84efa60f77b(p0) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 boolean
function N_0x312342e1a4874f3f(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@param weaponHash Hash|string
---@param componentHash Hash|string
---@return number
function N_0x3133b907d8b32053(weaponHash, componentHash) end

---@param gamerTagId integer
---@param hudColorIndex integer
function N_0x3158c77a7e888ab4(gamerTagId, hudColorIndex) end

---@param gamerTagId integer
function N_0x31698aa80e0223f8(gamerTagId) end

---@param minAmplitude number
function N_0x31727907b2c43c55(minAmplitude) end

---@param txdString1 string
---@param txnString1 string
---@param txdString2 string
---@param txnString2 string
function N_0x317eba71d7543f52(txdString1, txnString1, txdString2, txnString2) end

---@param multiplier number
function N_0x318516e02de3ece2(multiplier) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function N_0x3195f8dd0d531052(p0, p1) end

---@param contentId Hash|string
---@param srcPlatform string
---@param srcGamerHandle string
---@return boolean
function N_0x3270f67eed31fbc1(contentId, srcPlatform, srcGamerHandle) end

function N_0x32888337579a5970() end

---@param ped Ped
---@param p1 unknown
---@return Entity
function N_0x32c27a11307b01cc(ped, p1) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param pedMultiplier number
---@param vehicleMultiplier number
---@param p6 boolean
---@param p7 boolean
---@return integer
function N_0x32c7a7e8c43a1f80(x, y, z, radius, pedMultiplier, vehicleMultiplier, p6, p7) end

---@param vehicle integer
function N_0x32caedf24a583345(vehicle) end

---@param p0 unknown
---@return unknown
function N_0x32dd916f3f7c9672(p0) end

---@param scaleformMovieId integer
---@param useLargeRT boolean
function N_0x32f34ff7f617643b(scaleformMovieId, useLargeRT) end

---@param ped Ped
---@param p1 unknown
---@param p2 number
---@param p3 number
---@return unknown p4
function N_0x3311e47b91edcbbc(ped, p1, p2, p3) end

---@param vehicle integer
---@param toggle boolean
function N_0x33506883545ac0df(vehicle, toggle) end

function N_0x3353d13f09307691() end

---@param x number
---@param y number
---@return number
function N_0x336511a34f2e5185(x, y) end

---@param amount integer
---@param data unknown
---@param p2 boolean
---@param p3 boolean
function N_0x33981d6804e62f49(amount, data, p2, p3) end

---@param ped Ped
---@param p1 boolean
function N_0x33a60d8bdd6e508c(ped, p1) end

---@param entity Entity
---@return vector3
function N_0x33de49edf4dde77a(entity) end

---@param speakerConversationIndex integer
---@param x number
---@param y number
---@param z number
function N_0x33e3c6c6f2f0b506(speakerConversationIndex, x, y, z) end

---@param chTitle string
---@param iconType integer
---@param chSubtitle string
---@return unknown
function N_0x33ee12743ccd6343(chTitle, iconType, chSubtitle) end

---@param componentHash Hash|string
---@param restrictionTagHash Hash|string
---@param componentId integer
---@return boolean
function N_0x341de7ed1d2a1bfd(componentHash, restrictionTagHash, componentId) end

---@param x number
---@param y number
---@param z number
---@param colorIndex integer
function N_0x3430676b11cdf21d(x, y, z, colorIndex) end

---@param x number
---@param y number
---@param z number
---@param projHash Hash|string
---@param radius number
---@param ownedByPlayer boolean
---@return boolean
function N_0x34318593248c8fb2(x, y, z, projHash, radius, ownedByPlayer) end

---@param radioStationName string
---@return Hash
function N_0x34d66bc058019ce0(radioStationName) end

---@return integer
function N_0x350aa5ebc03d3bd2() end

---@param player integer
---@return number
function N_0x350c23949e43686c(player) end

---@param vehicle integer
function N_0x3556041742a0dc74(vehicle) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function N_0x3599d741c9ac6310(x1, y1, x2, y2) end

---@return integer
function N_0x359af31a4b52f5ed() end

---@param inventory boolean
---@param playerbalance boolean
---@return boolean
function N_0x35a1b3e1d1315cfa(inventory, playerbalance) end

function N_0x35edd5b2e3ff01c0() end

---@return boolean
function N_0x35f0b98a8387274d() end

---@param interior integer
---@param entitySetName string
---@return boolean
function N_0x35f7dd45e8c0a16d(interior, entitySetName) end

---@return boolean
function N_0x35fb78dc42b7bd21() end

---@param vehicle integer
---@return number
function N_0x36492c2f0d134c56(vehicle) end

---@param p1 unknown
---@param p2 unknown
---@return integer
---@return unknown p0
function N_0x3658e8cd94fc121a(p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x365e877c61d6988b(p0, p1, p2, p3) end

function N_0x3669f1b198dcaa4f() end

---@param p0 unknown
---@param p1 unknown
function N_0x36a7fd5a7194b03e(p0, p1) end

---@param ped Ped
---@param weaponHash Hash|string
---@return integer
function N_0x36b77bb84687c318(ped, weaponHash) end

---@return integer lastItemMenuId
---@return integer selectedItemUniqueId
function N_0x36c1451a88a09630() end

---@param ped Ped
function N_0x36c6984c3ed0c911(ped) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function N_0x37025b27d9b658b1(p0, p1) end

---@param entity Entity
---@param flags1 integer
---@param flags2 integer
---@return integer
function N_0x37181417ce7c8900(entity, flags1, flags2) end

---@param garageHash Hash|string
---@param entity Entity
---@param p2 number
---@param p3 integer
---@return boolean
function N_0x372ef6699146a1e4(garageHash, entity, p2, p3) end

---@param vehicle integer
---@param entity Entity
---@param p2 number
function N_0x374706271354cb18(vehicle, entity, p2) end

---@param toggle boolean
function N_0x375a706a5c2fd084(toggle) end

---@param entity Entity
---@return integer
function N_0x375e7fc44f21c8ab(entity) end

---@param player integer
---@return integer
function N_0x3765c3a3e8192e10(player) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@return unknown
function N_0x376c6375ba60293a(x1, y1, z1, x2, y2, z2, width) end

---@param Ped Ped
---@return boolean
function N_0x3795688a307e1eb6(Ped) end

---@return boolean
function N_0x37a4494483b9f5c9() end

function N_0x37deb0aa183fb6d8() end

---@param vehicle integer
---@param height number
function N_0x37ebbf3117bd6a25(vehicle, height) end

---@param headerTextLabel string
---@param line1TextLabel string
---@param buttonsBitField integer
---@param buttonsBitFieldUpper integer
---@param line2TextLabel string
---@param addNumber boolean
---@param numberToAdd integer
---@param firstSubstring string
---@param secondSubstring string
---@param showBackground boolean
---@param errorCode integer
function N_0x38b55259c2e078ed(headerTextLabel, line1TextLabel, buttonsBitField, buttonsBitFieldUpper, line2TextLabel, addNumber, numberToAdd, firstSubstring, secondSubstring, showBackground, errorCode) end

---@param player integer
---@return boolean
function N_0x38d28da81e4e9bf9(player) end

---@param entity Entity
---@param toggle boolean
function N_0x3910051ccecdb00c(entity, toggle) end

---@param vehicle integer
---@param wheelIndex integer
---@param multiplier number
function N_0x392183bb9ea57697(vehicle, wheelIndex, multiplier) end

---@param sceneID integer
---@param toggle boolean
function N_0x394b9cd12435c981(sceneID, toggle) end

---@param entity1 Entity
---@param entity2 Entity
---@param traceType integer
---@return unknown
function N_0x394bde2a7bba031e(entity1, entity2, traceType) end

---@param hudColor integer
function N_0x39bbf623fc803eac(hudColor) end

---@param transactionId integer
---@return boolean
function N_0x39be7cea8d9cc8e6(transactionId) end

---@param ped Ped
---@param slot integer
---@param drawableId integer
---@param textureId integer
---@return unknown
function N_0x39d55a620fcb6a3a(ped, slot, drawableId, textureId) end

---@return Hash
function N_0x3a17a27d75c74887() end

---@param handle integer
---@return boolean
function N_0x3a3d5568af297cd5(handle) end

---@return integer
function N_0x3a48ab4445d499be() end

---@param amount integer
---@return boolean
function N_0x3a54e33660ded67f(amount) end

---@param contextHash Hash|string
---@param nameHash Hash|string
---@return boolean
---@return integer value
function N_0x3a8b55fda4c8ddef(contextHash, nameHash) end

---@param vehicle integer
---@return boolean
function N_0x3a9128352eac9e85(vehicle) end

---@param player integer
---@return integer
function N_0x3b39236746714134(player) end

---@return boolean
function N_0x3bab9a4e4f2ff5c7() end

---@return boolean
function N_0x3bbbd13e5041a79e() end

---@return boolean
function N_0x3c4487461e9b0dcb() end

---@param categoryHash Hash|string
---@param itemHash Hash|string
---@param actionTypeHash Hash|string
---@param value integer
---@param flags integer
---@return boolean
---@return integer transactionId
function N_0x3c5fd37b5499582e(categoryHash, itemHash, actionTypeHash, value, flags) end

---@return boolean
function N_0x3c67506996001f5e() end

---@return unknown
---@return unknown p0
function N_0x3c891a251567dfce() end

---@param state boolean
function N_0x3ca6050692bc61b0(state) end

---@return boolean
function N_0x3d120012440e6683() end

---@param hudColor integer
---@param routeFromPlayer boolean
---@param displayOnFoot boolean
function N_0x3d3d15af7bcaaf83(hudColor, routeFromPlayer, displayOnFoot) end

---@return number
function N_0x3d3d8b3be5a83d35() end

---@param name string
---@return boolean
function N_0x3d42b92563939375(name) end

---@return boolean
function N_0x3d9acb1eb139e702() end

---@param wallet integer
---@param bank integer
function N_0x3da5ecd1a56cba6d(wallet, bank) end

---@param p0 unknown
---@return boolean
function N_0x3dbf2df0aeb7d289(p0) end

---@param toggle boolean
function N_0x3dda37128dd1aca8(toggle) end

---@param vehicle integer
---@return boolean
function N_0x3de51e9c80b116cf(vehicle) end

---@param unused integer
---@return boolean
function N_0x3dec726c25a11bac(unused) end

---@param vehicle integer
---@return integer
function N_0x3dff319a831e0cdb(vehicle) end

---@param p0 integer
---@param textLabel string
function N_0x3e200c2bcf4164eb(p0, textLabel) end

---@param vehicle integer
function N_0x3e45765f3fbb582f(vehicle) end

function N_0x3e4adaff1830f146() end

---@param radioStationName string
---@return integer
function N_0x3e65cde5215832c1(radioStationName) end

---@param colorId integer
---@return boolean
function N_0x3e802f11fbe27674(colorId) end

---@param heli integer
---@param toggle boolean
function N_0x3ec8bf18aa453fe9(heli, toggle) end

---@param fontBitField integer
function N_0x3ed1438c1f5c6612(fontBitField) end

---@param p0 unknown
---@param p1 unknown
function N_0x3ed2b83ab2e82799(p0, p1) end

---@return integer
function N_0x3f0cf9cb7e589b88() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
function N_0x3f4d00167e41e0ad(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@param p0 boolean
function N_0x3f52e880aaf6c8ca(p0) end

---@param health integer
---@param capacity integer
---@param wasAdded boolean
function N_0x3f5cc444dcaaa8f2(health, capacity, wasAdded) end

---@param ped Ped
---@param p1 boolean
---@param p2 integer
---@param p3 integer
function N_0x3f7325574e41b44d(ped, p1, p2, p3) end

---@return boolean
---@return integer networkHandle
function N_0x3f9990bf5f22759c() end

function N_0x402f9ed62087e898() end

---@param amplitude number
function N_0x405591ec8fd9096d(amplitude) end

---@param vehicle integer
---@param health number
function N_0x4056ea1105f5abd7(vehicle, health) end

---@param netID integer
function N_0x407091cf6037118e(netID) end

---@param bankName string
---@param bOverNetwork boolean
---@param playerBits integer
---@return boolean
function N_0x40763ea7b9b783e7(bankName, bOverNetwork, playerBits) end

---@param toggle boolean
function N_0x40aefd1a244741f2(toggle) end

---@param p0 integer
---@return integer
function N_0x40afb081f8add4ee(p0) end

---@param ped Ped
function N_0x40cf0d12d142a9e8(ped) end

---@param p0 unknown
---@param p1 unknown
---@return string
function N_0x40f7e66472df3e5c(p0, p1) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
---@return integer value
function N_0x40fce03e50e8dbe8(tunableContext, tunableName) end

---@param vehicle integer
---@param toggle boolean
function N_0x41062318f23ed854(vehicle, toggle) end

---@return boolean
function N_0x4167efe0527d706e() end

---@param achievement integer
---@return boolean
function N_0x418dc16fae452c1c(achievement) end

---@param toggle boolean
---@param playerPed Ped
---@param p2 boolean
function N_0x419594e137637120(toggle, playerPed, p2) end

---@param plane integer
---@return boolean
function N_0x4198ab0022b15f87(plane) end

---@param vehicle integer
---@param useAlternateInput boolean
function N_0x41b9fb92eded32a6(vehicle, useAlternateInput) end

---@param p0 boolean
function N_0x41faa8fb2ece8720(p0) end

---@param interior integer
---@param entitySetName string
function N_0x420bd37289eee162(interior, entitySetName) end

---@param distance number
function N_0x42156508606de65e(distance) end

---@return boolean
function N_0x422d396f80a96547() end

---@param entity Entity
---@return boolean
function N_0x422f32cc7e56abad(entity) end

---@param camName string
function N_0x425a920fdb9a0dda(camName) end

---@param amount integer
function N_0x42613035157e4208(amount) end

---@param vehicle integer
---@param toggle boolean
function N_0x428baccdf5e26ead(vehicle, toggle) end

---@param statName Hash|string
---@param value number
function N_0x428eaf89e24f6c36(statName, value) end

---@param vehicle integer
---@return integer
function N_0x42a4beb35d372407(vehicle) end

---@param priority integer
function N_0x42b65deef2edf2a1(priority) end

function N_0x42fb3b532d526e6c() end

---@param p0 unknown
function N_0x42fce14f50f27291(p0) end

---@param amount integer
function N_0x4337511fa8221d36(amount) end

function N_0x437138b6a830166a() end

---@return boolean
function N_0x43865688ae10f0d7() end

---@param player integer
function N_0x438822c279b73b93(player) end

---@param vehicle integer
---@param state number
function N_0x438b3d7ca026fe91(vehicle, state) end

---@return unknown
function N_0x439bfde3cd0610f6() end

---@param entity integer
---@param p1 unknown
---@return boolean
function N_0x43c677f1e1158005(entity, p1) end

function N_0x43d1680c6d19a8e9() end

---@param string string
---@return integer
function N_0x43e4111189e54f0e(string) end

function N_0x43f4dba69710e01e() end

---@param checkpoint integer
---@param scale number
function N_0x44621483ff966526(checkpoint, scale) end

---@return boolean
function N_0x44a0bdc559b35f6e() end

---@param friendDataIndex integer
---@return boolean
---@return integer networkHandle
function N_0x44b37cdcae765aae(friendDataIndex) end

---@param vehicle integer
---@param weaponIndex integer
---@param capacity integer
function N_0x44cd1f493db2a0a6(vehicle, weaponIndex, capacity) end

---@param zoneId integer
---@param x number
---@param y number
---@param z number
function N_0x44f1012b69313374(zoneId, x, y, z) end

---@param ped Ped
---@return integer
function N_0x451294e859ecc018(ped) end

---@param ped Ped
---@return boolean
function N_0x451d05012ccec234(ped) end

---@param vehicle integer
---@param modType integer
---@param modIndex integer
---@return Hash
function N_0x4593cf82aa179706(vehicle, modType, modIndex) end

---@return integer
function N_0x459fd2c8d0ab78bc() end

---@param vehicle integer
---@param multiplier number
function N_0x45a561a9421ab6ad(vehicle, multiplier) end

function N_0x45a83257ed02d9bc() end

---@param netScene integer
---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param animDict string
---@param animName string
---@param blendInSpeed number
---@param blendOutSpeed number
---@param flags integer
function N_0x45f35c0edc33b03b(netScene, modelHash, x, y, z, animDict, animName, blendInSpeed, blendOutSpeed, flags) end

---@return unknown p0
function N_0x46326e13da4e0546() end

---@param contentId string
---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@return boolean
function N_0x4645de9980999e93(contentId, contentName, description, tagsCsv, contentTypeName) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param p5 boolean
---@return boolean
function N_0x46494a2475701343(x, y, z, radius, modelHash, p5) end

---@param vehicle integer
---@param toggle boolean
function N_0x465bf26ab9684352(vehicle, toggle) end

---@param ped Ped
function N_0x4668d80430d6c299(ped) end

---@param p0 number
function N_0x466da42c89865553(p0) end

---@return boolean
function N_0x46718aceedeafc84() end

---@param name string
---@return boolean
function N_0x4683149ed1dde7a1(name) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function N_0x46f8696933a63c9b(entity, boneIndex) end

---@param player integer
---@param p1 integer
---@param scriptHash Hash|string
---@return boolean
function N_0x46fb3ed415c7641c(player, p1, scriptHash) end

---@return boolean
function N_0x472841a026d26d8b() end

---@return integer
function N_0x473151ebc762c6da() end

---@return integer
function N_0x4750fc27570311ec() end

---@param weaponHash Hash|string
---@param damageMultiplier number
function N_0x4757f00bc6323cfe(weaponHash, damageMultiplier) end

function N_0x4759cc730f947c81() end

---@param id integer
function N_0x47b32f5611e6e483(id) end

---@param camera integer
---@param multiplier number
function N_0x47b595d60664cffa(camera, multiplier) end

---@param hairColorIndex integer
---@return integer outR
---@return integer outG
---@return integer outB
function N_0x4852fc386e2e1bb5(hairColorIndex) end

---@param roll number
---@param pitch number
---@param yaw number
function N_0x48608c3464f58ab4(roll, pitch, yaw) end

---@param p0 string
---@param p3 boolean
---@return boolean
---@return unknown p1
---@return unknown p2
function N_0x4862437a486f91b0(p0, p3) end

---@param p0 number
function N_0x487a82c650eb7799(p0) end

function N_0x488043841bbe156f() end

---@param p0 integer
function N_0x4895bdea16e7c080(p0) end

function N_0x48adc8a773564670() end

---@param vehicle integer
---@return boolean
function N_0x48c633e94a8142a7(vehicle) end

---@param entity Entity
function N_0x49482f9fcd825aaa(entity) end

---@param inviteIndex integer
---@return string
function N_0x4962cc4aa2f345b7(inviteIndex) end

---@param vehicle integer
---@return string
function N_0x4967a516ed23a5a1(vehicle) end

---@return integer
function N_0x497420e022796b3f() end

---@param vehicle integer
---@param transformRate number
function N_0x498218259fb7c72d(vehicle, transformRate) end

---@return boolean
function N_0x498c1e05ce5f7877() end

---@param player integer
---@param wantedLevel integer
---@param lossTime integer
function N_0x49b856b1360c47c7(player, wantedLevel, lossTime) end

---@param ped Ped
---@param speechName string
---@param allowBackupPVGs boolean
---@return boolean
function N_0x49b99bf3fda89a7a(ped, speechName, allowBackupPVGs) end

function N_0x49da8145672b2725() end

---@param matchmakingGroup integer
function N_0x49ec8030f5015f8b(matchmakingGroup) end

---@param toggle boolean
function N_0x4a0c7c9bb10abb36(toggle) end

---@param areaHandle integer
---@return boolean
function N_0x4a2d4e8bf4265b0f(areaHandle) end

---@param object integer
function N_0x4a39db43e47cf3aa(object) end

---@return integer
function N_0x4a9923385bdb9dad() end

---@param opponentPed Ped
function N_0x4ada3f19be4a6047(opponentPed) end

---@param checkpoint integer
---@param height_multiplier number
function N_0x4b5b4da5d79f1943(checkpoint, height_multiplier) end

function N_0x4b5cfc83122df602() end

---@param entity Entity
---@param p1 boolean
function N_0x4ba166079d658ed4(entity, p1) end

---@param player integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param p8 number
---@param p9 number
---@param p10 number
---@param flags integer
---@return boolean
function N_0x4ba92a18502bca61(player, x1, y1, z1, x2, y2, z2, width, p8, p9, p10, flags) end

---@param doorHash Hash|string
---@return integer
function N_0x4bc2854478f3a749(doorHash) end

---@param handle integer
---@return boolean
function N_0x4c61b39930d045da(handle) end

---@param cutsceneEntName string
---@param p1 integer
---@param p2 integer
function N_0x4c61c75bee8184c2(cutsceneEntName, p1, p2) end

---@param plane integer
---@param health number
function N_0x4c815eb175086f84(plane, health) end

---@return integer
function N_0x4c9296cbcd1b971e() end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return Hash weaponHash
function N_0x4caca84440fa26f6(p0, p1) end

---@param componentHash Hash|string
---@param extraComponentIndex integer
---@return Hash
function N_0x4d1cb8dc40208a17(componentHash, extraComponentIndex) end

---@param object integer
---@param toggle boolean
function N_0x4d89d607cb3dd1d2(object, toggle) end

---@param captionString string
---@param condensedCaptionString string
function N_0x4dcdf92bf64236cd(captionString, condensedCaptionString) end

---@return boolean
---@return boolean p0
function N_0x4dfdd9eb705f8140() end

---@param justifyType integer
function N_0x4e096588b13ffeca(justifyType) end

---@param radioStation string
---@param trackListName string
---@param timeOffsetMilliseconds integer
function N_0x4e0af9114608257c(radioStation, trackListName, timeOffsetMilliseconds) end

---@param vehicle integer
---@param p1 number
---@return unknown
function N_0x4e20d2a627011e8e(vehicle, p1) end

---@return unknown
function N_0x4e3cd0ef8a489541() end

---@param radioStation string
---@param trackListName string
---@param forceNow boolean
function N_0x4e404a9361f75bb2(radioStation, trackListName, forceNow) end

---@param vehicle integer
---@return boolean
function N_0x4e417c547182c84d(vehicle) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function N_0x4e548c0d7ae39ff9(p0, p1) end

---@param vehicle integer
---@param p1 boolean
function N_0x4e74e62e0a97e901(vehicle, p1) end

---@param ped Ped
---@param intensity number
function N_0x4e90d746056e273d(ped, intensity) end

---@param gamerTagId integer
---@return boolean
function N_0x4e929e7a5796fd26(gamerTagId) end

---@param toggle boolean
function N_0x4ebb7e87aa0dbed4(toggle) end

---@param vehicle integer
---@param gameObjectName string
function N_0x4f0c413926060b38(vehicle, gameObjectName) end

function N_0x4f18196c8d38768d() end

---@return boolean
function N_0x4f32c0d5a90a9b40() end

---@param nodeID integer
---@return boolean
function N_0x4f5070aa58f69279(nodeID) end

---@param padIndex integer
---@param control integer
---@return number
function N_0x4f8a26a890fd62fb(padIndex, control) end

---@return boolean
function N_0x4fef53183c3c6414() end

---@param x number
---@param y number
---@param z number
function N_0x5006d96c995a5827(x, y, z) end

---@param vehicle integer
---@param propeller integer
function N_0x500873a45724c863(vehicle, propeller) end

---@param action string
---@param value integer
function N_0x5009dfd741329729(action, value) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function N_0x501478855a6074ce(p0, p1, p2, p3, p4, p5) end

---@param cam integer
---@param p1 number
---@param p2 number
---@param p3 number
function N_0x503f5920162365b2(cam, p1, p2, p3) end

---@param toggle boolean
function N_0x504dfe62a1692296(toggle) end

---@param vehicle integer
---@return boolean
function N_0x50634e348c8d44ef(vehicle) end

---@param pickup integer
---@return integer
function N_0x5099bc55630b25ae(pickup) end

---@param mapObjectHash Hash|string
function N_0x50c375537449f369(mapObjectHash) end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param p3 integer
---@return integer
function N_0x50f457823ce6eb5f(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
function N_0x515b4a22e4d3c6d7(p0, p1) end

---@param p0 integer
function N_0x516fc96eb88eefe5(p0) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0x5182a339a3474510(p0, p1, p2) end

---@param vehicle integer
---@param toggle boolean
function N_0x51bb2d88d31a914b(vehicle, toggle) end

---@param slot integer
---@param transfer boolean
---@param reason Hash|string
---@return boolean
function N_0x51f1a8e48c3d2f6d(slot, transfer, reason) end

---@param p0 integer
---@param p1 integer
function N_0x521638ada1ba0d18(p0, p1) end

function N_0x523a590c1a3cc0d3() end

---@param ped Ped
---@param p1 integer
---@param p2 string
function N_0x523c79aeefcc4a2a(ped, p1, p2) end

---@param toggle boolean
function N_0x524ff0aeff9c3973(toggle) end

---@param p0 integer
---@return boolean
function N_0x52818819057f2b40(p0) end

---@param object integer
---@return boolean
function N_0x52af537a0c5b8aad(object) end

---@param ped Ped
---@param toggle boolean
function N_0x52d59ab61ddc05dd(ped, toggle) end

---@param p0 unknown
---@param p1 unknown
function N_0x533073e8a596008c(p0, p1) end

---@param vehicle integer
function N_0x5335be58c083e74e(vehicle) end

---@param modelHash Hash|string
---@return number
function N_0x53409b5163d5b846(modelHash) end

---@param vehicle integer
---@param tyreIndex integer
---@return boolean
function N_0x534e36d4db9ecc5d(vehicle, tyreIndex) end

---@param toggle boolean
function N_0x5354c5ba2ea868a4(toggle) end

---@param vehicle integer
---@return number
function N_0x53af99baa671ca47(vehicle) end

---@return integer
function N_0x53afd64c6758f2f9() end

---@param p0 number
function N_0x53f4892d18ec90a4(p0) end

---@param blip integer
---@param toggle boolean
function N_0x54318c915d27e4ce(blip, toggle) end

---@return boolean
function N_0x544810ed9db6bbe6() end

---@param vehicle integer
---@param extend boolean
function N_0x544996c0081abdeb(vehicle, extend) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@return unknown
function N_0x54b0f614960f4a5f(p0, p1, p2, p3, p4, p5, p6) end

---@param x number
---@param y number
---@param z number
---@return unknown
function N_0x551df99658db6ee8(x, y, z) end

---@param shouldPlay boolean
function N_0x552369f549563ad5(shouldPlay) end

---@param pos number
function N_0x55598d21339cb998(pos) end

---@param hash Hash|string
---@return boolean
function N_0x557e43c447e700a8(hash) end

---@param p0 integer
---@return string
function N_0x55aa95f481d694d2(p0) end

function N_0x55df6db45179236e() end

---@param interior integer
---@param entitySetName string
function N_0x55e86af2712b36a1(interior, entitySetName) end

---@param player integer
---@return integer
function N_0x56105e599cab0efa(player) end

---@param group Hash|string
---@param p1 boolean
function N_0x5615e0c5eb2bc6e2(group, p1) end

---@param ped Ped
---@return integer
function N_0x56176892826a4fe8(ped) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function N_0x5619bfa07cfd7833(ped, collection, overlay) end

function N_0x5626d9d6810730d5() end

---@param weaponHash Hash|string
---@param vehicle integer
---@param owner Ped
---@return boolean
function N_0x563b65a643ed072e(weaponHash, vehicle, owner) end

---@param player integer
---@return boolean
function N_0x565e430db3b05bec(player) end

---@return integer
function N_0x567384dfa67029e6() end

---@param ped Ped
---@param animDict string
function N_0x5687c7f05b39e401(ped, animDict) end

---@param vehicle integer
---@param position number
---@param p2 boolean
function N_0x56b94c6d7127dfba(vehicle, position, p2) end

function N_0x56c8b608cfd49854() end

---@param p0 integer
---@return integer
function N_0x56ce820830ef040b(p0) end

---@param ped Ped
---@param p1 integer
function N_0x56e3b78c5408d9f4(ped, p1) end

---@param targetLevel integer
function N_0x5702b917b99db1cd(targetLevel) end

---@param ped Ped
function N_0x570389d1c3de3c6b(ped) end

---@param cargobob integer
---@param toggle boolean
function N_0x571feb383f629926(cargobob, toggle) end

---@param ped Ped
---@param toggle boolean
function N_0x576594e8d64375e2(ped, toggle) end

---@param allow boolean
function N_0x577599cced639ca2(allow) end

---@param p0 integer
---@return boolean
function N_0x5776ed562c134687(p0) end

---@param toggle boolean
function N_0x57b192b4d4ad23d5(toggle) end

function N_0x583049884a2eee3c() end

---@param txdName string
---@return boolean
---@return unknown netHandle
function N_0x5835d9cd92e83184(txdName) end

---@return Hash
---@return integer networkHandle
function N_0x58575ac3cf2ca8ec() end

---@param ped Ped
---@param ammoType Hash|string
---@return boolean
---@return integer ammo
function N_0x585847c5e4e11709(ped, ammoType) end

---@param vehicleModel Hash|string
---@return integer
function N_0x5873c14a52d74236(vehicleModel) end

---@param x number
---@param y number
---@param z number
---@param modelHash Hash|string
---@return boolean
---@return Hash doorOutPointer
function N_0x589f80b325cc82c5(x, y, z, modelHash) end

function N_0x58a39be597ce99cd() end

---@param p0 unknown
---@return integer
function N_0x58a651cd201d89ad(p0) end

---@param p0 string
---@param p1 string
function N_0x58c21165f6545892(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return integer
function N_0x58cc181719256197(p0, p1, p2) end

---@return boolean
function N_0x593570c289a77688() end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@return boolean
function N_0x595f028698072dd9(p0, p1, p2) end

---@return unknown
function N_0x597f8dba9b206fc7() end

---@param plane integer
---@return boolean
function N_0x5991a01434ce9677(plane) end

---@return integer
function N_0x599e4fa1f87eb5ff() end

---@return integer
function N_0x59b9a7af4c95133c() end

---@return boolean
function N_0x59df79317f85a7e0() end

---@param vehicle integer
---@param damageFactor number
function N_0x59e7b488451f4d3a(vehicle, damageFactor) end

---@return unknown
function N_0x5a0a3d1a186a5508() end

---@return boolean
function N_0x5a6aa44ff8e931e6() end

---@param player integer
---@param x number
---@param y number
---@param z number
---@param radius number
---@param p5 number
---@param p6 number
---@param p7 number
---@param flags integer
---@return boolean
function N_0x5a6ffa2433e2f14c(player, x, y, z, radius, p5, p6, p7, flags) end

---@return boolean
function N_0x5aa3befa29f03ad4() end

---@param modelHash Hash|string
---@return number
function N_0x5aa3f878a178c4fc(modelHash) end

---@param ped Ped
function N_0x5aab586ffec0fd96(ped) end

---@return boolean
function N_0x5ae17c6b0134b7f1() end

---@return unknown
function N_0x5b48a06dd0e792a5() end

---@return unknown
function N_0x5b4f04f19376a0ba() end

---@return boolean
function N_0x5b50abb1fe3746f4() end

---@param padIndex integer
---@param control integer
---@return number
function N_0x5b84d09cec5209c5(padIndex, control) end

---@param timeout integer
function N_0x5b8ed3db018927b1(timeout) end

---@param vehicle integer
---@param state boolean
function N_0x5b91b229243351a8(vehicle, state) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x5bcde0f640c773d2(p0, p1, p2, p3) end

---@return vector3
function N_0x5bff36d6ed83e0ae() end

---@param object integer
---@param state integer
function N_0x5c29f698d404c5e1(object, state) end

---@param entity1 Entity
---@param entity2 Entity
---@param entityBone integer
---@param entityBone2 integer
---@param p4 boolean
---@param p5 boolean
function N_0x5c48b75732c8456c(entity1, entity2, entityBone, entityBone2, p4, p5) end

---@param token integer
---@return integer
function N_0x5c4ebffa98bdb41c(token) end

---@param toggle boolean
---@param player integer
function N_0x5c707a667df8b9fa(toggle, player) end

---@return integer
function N_0x5c90988e7c8e1af4() end

---@param seatIndex integer
function N_0x5c90cab09951a12f(seatIndex) end

---@param p0 unknown
---@return boolean
function N_0x5cae833b0ee0c500(p0) end

---@return integer
function N_0x5cbad97e059e1b94() end

---@param lowR integer
---@param lowG integer
---@param lowB integer
---@param lowAlpha integer
---@param R integer
---@param G integer
---@param B integer
---@param Alpha integer
---@param highR integer
---@param highG integer
---@param highB integer
---@param highAlpha integer
function N_0x5ce62918f8d703c7(lowR, lowG, lowB, lowAlpha, R, G, B, Alpha, highR, highG, highB, highAlpha) end

---@return boolean
function N_0x5d10b3795f3fc886() end

function N_0x5d2bfaab8d956e0e() end

---@param id integer
function N_0x5d517b27cf6ecd04(id) end

---@param componentHash Hash|string
---@return unknown outProp
function N_0x5d5caff661ddf6fc(componentHash) end

---@param xOffset number
function N_0x5d7b620dae436138(xOffset) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function N_0x5d97630a8a0ef123(amount, p1, p2) end

---@param time integer
function N_0x5da3a8de8cb6226f(time) end

---@param weaponObject integer
---@param camoComponentHash Hash|string
---@param colorIndex integer
function N_0x5da825a85d0ea6e6(weaponObject, camoComponentHash, colorIndex) end

---@param vehicle integer
---@return boolean
function N_0x5db8010ee71fdef2(vehicle) end

---@param player integer
---@param state boolean
function N_0x5dc40a8869c22141(player, state) end

---@return boolean
function N_0x5dc577201723960a() end

---@param p0 integer
---@return integer
function N_0x5e0165278f6339ee(p0) end

---@param ped Ped
---@return Hash
function N_0x5e203da2ba15d436(ped) end

---@return boolean
function N_0x5e24341a7f92a74b() end

function N_0x5e5e99285ae812db() end

---@param briefValue integer
---@return boolean
function N_0x5e657ef1099edd65(briefValue) end

---@param p0 number
function N_0x5e9daf5a20f15908(p0) end

---@return boolean
function N_0x5ea784d197556507() end

---@param pickupHash Hash|string
---@return Hash
function N_0x5eaad83f8cfb4575(pickupHash) end

---@param vehicle integer
---@return integer
function N_0x5ecb40269053c0d4(vehicle) end

---@return integer
function N_0x5ed0356a0ce3a34f() end

---@param p0 number
function N_0x5f0f3f56635809ef(p0) end

---@param style integer
function N_0x5f2013f8bc24ee69(style) end

---@param player integer
---@return number
function N_0x5f35f6732c3fbba0(player) end

---@return boolean
function N_0x5f43d83fd6738741() end

---@param blip integer
---@param toggle boolean
function N_0x5fbca48327b914df(blip, toggle) end

---@param p0 unknown
---@return boolean
---@return number p1
function N_0x5fbd7095fe7ae57f(p0) end

---@param playerId integer
---@return boolean
function N_0x5fc472c501ccadb3(playerId) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function N_0x5fd5ed82cbbe9989(p0, p1, p2) end

---@param ped Ped
function N_0x600048c60d5c2c51(ped) end

---@param vehicle integer
---@return integer
function N_0x60190048c0764a26(vehicle) end

---@param colorID integer
---@return boolean
function N_0x604e810189ee3a59(colorID) end

---@return boolean
function N_0x606e4d3e3cccf3eb() end

---@param explosionType integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function N_0x6070104b699b2ef4(explosionType, x1, y1, z1, x2, y2, z2) end

---@param toggle boolean
function N_0x60734cc207c9833c(toggle) end

---@param cam integer
---@param p1 integer
---@param p2 integer
function N_0x609278246a29ca34(cam, p1, p2) end

function N_0x60e892ba4f5bdca4() end

---@param amount integer
---@param heistHash string
function N_0x61326ee6df15b0ca(amount, heistHash) end

---@param gamerTagId integer
---@param component integer
---@param hudColorIndex integer
function N_0x613ed644950626ae(gamerTagId, component, hudColorIndex) end

---@param player integer
---@param pickupHash Hash|string
---@param toggle boolean
function N_0x616093ec6b139dd9(player, pickupHash, toggle) end

---@param isPlaceHolder boolean
function N_0x61631f5df50d1c34(isPlaceHolder) end

---@param ped Ped
---@return boolean
function N_0x61767f73eaceed21(ped) end

function N_0x61a885d3f7cfee9a() end

---@param order integer
function N_0x61bb1d9b3a95d802(order) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function N_0x61e111e323419e07(index, spStat, charStat, character) end

---@param minBumpiness number
function N_0x6216b116083a7cb4(minBumpiness) end

---@param ped Ped
---@return boolean
function N_0x621c6e4729388e41(ped) end

---@param vehicle integer
---@param toggle boolean
function N_0x6274c4712850841e(vehicle, toggle) end

---@return boolean
function N_0x62a0296c1bb1ceb3() end

---@param ped Ped
---@param p1 unknown
---@param p2 boolean
function N_0x62ab793144de75dc(ped, p1, p2) end

---@return boolean
function N_0x62b9fec9a11f10ef() end

---@param vehicle integer
---@return boolean
function N_0x62ca17b74c435651(vehicle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param object Hash|string
---@return integer
function N_0x62ec273d00187dca(x, y, z, radius, object) end

---@param player integer
---@return boolean
function N_0x631dc5dff4b110e3(player) end

---@param scaleformHandle integer
---@return boolean
---@return boolean received
---@return integer selectionType
---@return integer context
---@return integer slotIndex
function N_0x632b2940c67f4ea9(scaleformHandle) end

---@param vehicle integer
---@return boolean
function N_0x634148744f385576(vehicle) end

---@param ped Ped
function N_0x637822dc2afeebf8(ped) end

---@return integer
function N_0x638a3a81733086db() end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
---@param side boolean
---@param onEnter boolean
---@return boolean
function N_0x639431e895b9aa57(ped, vehicle, seatIndex, side, onEnter) end

---@param gamerTagId integer
---@param component integer
---@param toggle boolean
function N_0x63bb75abedc1f6a0(gamerTagId, component, toggle) end

function N_0x643ed62d5ea3bebd() end

---@return boolean
function N_0x644546ec5287471b() end

---@param contentId string
---@param dataCount integer
---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@return boolean
---@return unknown data
function N_0x648e7a5434af7969(contentId, dataCount, contentName, description, tagsCsv, contentTypeName) end

function N_0x6493cf69859b116a() end

function N_0x64f62afb081e260d() end

---@return boolean
function N_0x6512765e3be78c50() end

---@param emitterName string
---@param entity Entity
function N_0x651d3228960d08af(emitterName, entity) end

---@param shapeTestHandle integer
---@return integer
---@return boolean hit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return Hash materialHash
---@return Entity entityHit
function N_0x65287525d951f6be(shapeTestHandle) end

---@param doorHash Hash|string
---@return number
function N_0x65499865fca6e5ec(doorHash) end

---@param componentHash Hash|string
---@return integer
function N_0x6558ac7c17bfef58(componentHash) end

---@param alpha integer
function N_0x658500ae6d723a7e(alpha) end

---@param ped Ped
function N_0x6585d955a68452a5(ped) end

---@return boolean
function N_0x659cf2ef7f550c4f() end

---@param scaleformName string
---@return integer
function N_0x65e7e78842e74cdb(scaleformName) end

---@param player integer
---@return boolean
function N_0x65faee425de637b0(player) end

---@param cam integer
---@param toggle boolean
function N_0x661b5c8654add825(cam, toggle) end

---@param index integer
---@return string
function N_0x662635855957c411(index) end

---@param vehicle integer
---@return number
function N_0x6636c535f6cc2725(vehicle) end

---@param ped Ped
---@param p1 boolean
function N_0x6647c5f6f5792496(ped, p1) end

---@param ped Ped
---@return boolean
function N_0x66680a92700f43df(ped) end

---@param ped Ped
---@param heading number
---@param isNetwork boolean
---@param bScriptHostPed boolean
---@param p4 unknown
---@return Ped
function N_0x668fd40bcba5de48(ped, heading, isNetwork, bScriptHostPed, p4) end

---@param cargobob integer
---@param p1 number
function N_0x66979acf5102fd2f(cargobob, p1) end

---@return boolean
function N_0x66b59cffd78467af() end

---@param vehicle integer
function N_0x66c3fb05206041ba(vehicle) end

---@return integer networkHandle
function N_0x66f010a4b031a331() end

---@param garageHash Hash|string
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p4 unknown
---@return boolean
function N_0x673ed815d6e323b7(garageHash, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return boolean
---@return unknown p3
---@return unknown p4
function N_0x678bb03c1a3bd51e(p0, p1, p2) end

---@return boolean
function N_0x67a5589628e0cff6() end

function N_0x67eedea1b9bafd94() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param p6 number
---@param p7 number
---@param p8 boolean
---@return integer
function N_0x67f6413d3220e18d(x1, y1, z1, x2, y2, z2, p6, p7, p8) end

---@param binkMovie integer
---@param shouldSkip boolean
function N_0x6805d58caa427b72(binkMovie, shouldSkip) end

---@param p0 unknown
---@return unknown p1
---@return unknown p2
function N_0x6816fb4416760775(p0) end

---@return boolean
function N_0x684a41975f077262() end

---@return integer
function N_0x6856ec3d35c81ea4() end

---@param vehicle integer
---@param p1 number
function N_0x685d5561680d088b(vehicle, p1) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
function N_0x68772db2b2526f9f(ped, x, y, z, radius) end

---@param ped Ped
function N_0x687c0b594907d2e8(ped) end

---@param profileSetting integer
---@param value integer
function N_0x68f01422be1d838f(profileSetting, value) end

---@param ped Ped
---@param loadoutHash Hash|string
function N_0x68f8be6af5cdf8a6(ped, loadoutHash) end

---@param contentId string
---@param rating number
---@param contentTypeName string
---@return boolean
function N_0x692d808c34a82143(contentId, rating, contentTypeName) end

---@param entity Entity
---@param toggle boolean
function N_0x694e00132f2823ed(entity, toggle) end

---@param contextHash Hash|string
---@param nameHash Hash|string
---@return boolean
---@return boolean value
function N_0x697f508861875b42(contextHash, nameHash) end

---@param p0 unknown
---@param p1 unknown
function N_0x69c922b677621428(p0, p1) end

---@param value unknown
function N_0x69fe6dc87bd2a5e9(value) end

---@param ped Ped
---@return boolean
function N_0x6a03bf943d767c93(ped) end

function N_0x6a12d88881435dca() end

---@param gxtEntryHash Hash|string
function N_0x6a1738b4323fe2d9(gxtEntryHash) end

---@param bank integer
---@param p1 boolean
---@param p2 boolean
function N_0x6a445b64ed7abeb5(bank, p1, p2) end

---@return boolean
function N_0x6adaabd3068c5235() end

---@param data string
---@return boolean
function N_0x6afd2cd753feef83(data) end

---@param p0 boolean
function N_0x6b07b9ce4d390375(p0) end

---@param p0 boolean
function N_0x6b0e6172c9a4d902(p0) end

---@param hudColorIndex integer
function N_0x6b1de27ee78e6a19(hudColorIndex) end

---@param doorHash Hash|string
---@param state integer
---@param requestDoor boolean
---@param forceUpdate boolean
function N_0x6bab9442830c7f53(doorHash, state, requestDoor, forceUpdate) end

---@param player integer
---@param toggle boolean
function N_0x6bc97f4f4bb3c04b(player, toggle) end

---@param ped Ped
---@return integer
function N_0x6c0e2e0125610278(ped) end

---@param p0 unknown
---@return unknown
function N_0x6c34f1208b8923fd(p0) end

function N_0x6cc86e78358d5119() end

---@param ped1 Ped
---@param ped2 Ped
---@return boolean
function N_0x6cd5a433374d4cfb(ped1, ped2) end

---@param toggle boolean
function N_0x6cdd58146a436083(toggle) end

---@param entity Entity
function N_0x6ce177d014502e8a(entity) end

---@return integer hours
---@return integer minutes
---@return integer seconds
function N_0x6d03bfbd643b2a02() end

---@param offset integer
---@param count integer
---@param contentTypeName string
---@param p3 integer
---@return boolean
function N_0x6d4cb481fac835e8(offset, count, contentTypeName, p3) end

---@param vehicle integer
function N_0x6d6af961b72728ae(vehicle) end

---@param cargobob integer
---@param p1 number
function N_0x6d8eac07506291fb(cargobob, p1) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 number
---@param p5 number
---@param p6 number
function N_0x6d955f6a9e0295b1(x, y, z, radius, p4, p5, p6) end

---@param player integer
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@param crewR integer
---@param crewG integer
---@param crewB integer
function N_0x6dd05e9d83efa4c9(player, username, crewIsPrivate, crewIsRockstar, crewName, crewRank, crewR, crewG, crewB) end

---@param x number
---@param y number
---@return number calculatedX
---@return number calculatedY
function N_0x6dd8f5aa635eb4b2(x, y) end

---@param p0 boolean
function N_0x6ddbf9dffc4ac080(p0) end

---@param vehicle integer
---@param val integer
function N_0x6dee944e1ee90cfb(vehicle, val) end

---@return boolean
function N_0x6e04f06094c87047() end

---@return boolean
function N_0x6e0eb3eb47c8d7aa() end

---@param x number
---@param y number
---@param z number
---@return boolean
function N_0x6e31b91145873922(x, y, z) end

---@param p0 integer
---@param p1 string
---@param p2 integer
function N_0x6ea318c91c1a8786(p0, p1, p2) end

function N_0x6ef54ab721dc6242() end

---@param toggle boolean
function N_0x6f1554b0cc2089fa(toggle) end

---@return boolean
function N_0x6f259f82d873b8b8() end

---@param index integer
---@param index2 integer
---@return string
function N_0x6f44cbf56d79fac0(index, index2) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function N_0x6f60e89a7b64ee1d(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis) end

---@param team integer
---@param toggle boolean
function N_0x6f697a66ce78674e(team, toggle) end

---@return boolean
function N_0x6f72cd94f7b5b68c() end

---@param name string
---@return unknown p0
function N_0x6f7794f28c6b2535(name) end

---@param vehicle integer
---@param active boolean
function N_0x6fddad856e36988a(vehicle, active) end

---@param token integer
---@return integer
function N_0x700569dba175a77c(token) end

---@param p0 unknown
---@return string
function N_0x703f12425eca8bf5(p0) end

---@return boolean
function N_0x705a844002b39dc0() end

---@param x number
---@param y number
---@param z number
---@param heading number
function N_0x706b5edcaa7fa663(x, y, z, heading) end

---@param zoomFactor number
function N_0x70894bd0915c5bca(zoomFactor) end

---@return boolean
function N_0x708bdd8cd795b043() end

---@param override boolean
---@param windElevationHashName Hash|string
function N_0x70b8ec8fc108a634(override, windElevationHashName) end

---@param p0 unknown
---@return boolean
function N_0x70ea8da57840f9be(p0) end

---@param entity Entity
function N_0x715135f4b82ac90d(entity) end

---@param ped Ped
---@return string
function N_0x717e4d1f2048376d(ped) end

---@param name string
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x71862b1d855f32e1(name, p1, p2, p3) end

---@param flag integer
---@return boolean
function N_0x71b74d2ae19338d0(flag) end

---@param hole integer
function N_0x71bdb63dbaf8da59(hole) end

---@return boolean
---@return integer networkHandle
function N_0x71dc455f5cd1c2b1() end

---@param ped Ped
---@return integer
function N_0x71eab450d86954a1(ped) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
function N_0x71fb0ebcd4915d56(p0, p1, p2, p3) end

---@param index integer
---@return string
function N_0x722f5d28b61c5ea8(index) end

---@param netId integer
---@return boolean
function N_0x7242f8b741ce1086(netId) end

function N_0x726e0375c7a26368() end

---@param p0 unknown
---@return unknown
function N_0x728c4cc7920cd102(p0) end

---@param animDict string
---@param animName string
---@return boolean
function N_0x729e3401f0430686(animDict, animName) end

---@param weaponHash Hash|string
function N_0x72c1056d678bb7d8(weaponHash) end

function N_0x72d0706cd6ccdb58() end

---@param p0 integer
---@return boolean
function N_0x72d918c99bcacc54(p0) end

---@param posX number
---@param posY number
---@param posZ number
---@param radius number
---@param p4 integer
function N_0x72dd432f3cdfc0ee(posX, posY, posZ, radius, p4) end

---@return boolean
function N_0x72de52178c291cb5() end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p5 unknown
---@return boolean
---@return unknown p4
function N_0x7303e27cc6532080(p0, p1, p2, p3, p5) end

---@param variableName string
---@param value number
function N_0x733adf241531e5c2(variableName, value) end

---@param ped Ped
---@return boolean
function N_0x7350823473013c02(ped) end

---@param entity Entity
function N_0x7368e683bb9038d6(entity) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
---@param red1 number
---@param green1 number
---@param blue1 number
---@param alpha1 integer
---@param red2 number
---@param green2 number
---@param blue2 number
---@param alpha2 integer
---@param red3 number
---@param green3 number
---@param blue3 number
---@param alpha3 integer
---@param textureDict string
---@param textureName string
---@param u1 number
---@param v1 number
---@param w1 number
---@param u2 number
---@param v2 number
---@param w2 number
---@param u3 number
---@param v3 number
---@param w3 number
function N_0x736d7aa1b750856b(x1, y1, z1, x2, y2, z2, x3, y3, z3, red1, green1, blue1, alpha1, red2, green2, blue2, alpha2, red3, green3, blue3, alpha3, textureDict, textureName, u1, v1, w1, u2, v2, w2, u3, v3, w3) end

---@param blip integer
---@param toggle boolean
function N_0x74513ea3e505181e(blip, toggle) end

---@return boolean
function N_0x74698374c45701d2() end

---@return boolean
function N_0x74732c6ca90da2b4() end

---@return boolean
function N_0x74bd83ea840f6bc9() end

---@param toggle boolean
function N_0x74c180030fde4b69(toggle) end

function N_0x74de2e8739086740() end

---@param netId integer
---@return integer
function N_0x75262fd12d0a1c84(netId) end

---@param bufferSize integer
---@return boolean
---@return integer clanDesc
function N_0x7543bb439f63792b(bufferSize) end

---@param plane integer
---@return boolean
function N_0x755d6d5267cbbd7e(plane) end

---@param vehicle integer
function N_0x75627043c6aa90ad(vehicle) end

---@param string string
---@return boolean
---@return integer token
function N_0x75632c5ecd7ed843(string) end

---@param vehicle integer
---@param toggle boolean
function N_0x756ae6e962168a04(vehicle, toggle) end

---@param hash Hash|string
---@param toggle boolean
function N_0x75773e11ba459e90(hash, toggle) end

---@param statName Hash|string
---@return integer
function N_0x7583b4be4c5a41b5(statName) end

---@param p0 unknown
function N_0x758a5c1b3b1e1990(p0) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function N_0x759299c5bb31d2a9(p0, p1) end

---@param blip integer
---@param toggle boolean
function N_0x75a16c3da34f1245(blip, toggle) end

function N_0x75d3691713c3b05a() end

---@param p0 string
---@param p1 integer
function N_0x761b77454205a61d(p0, p1) end

function N_0x7669f9e39dc17063() end

---@param hudIndex integer
---@param x number
---@param y number
function N_0x7679cc1bcebe3d4c(hudIndex, x, y) end

---@param method_return integer
---@return boolean
function N_0x768ff8961ba904d6(method_return) end

---@return unknown
function N_0x769951e2455e2eb5() end

---@param ped Ped
---@return integer
function N_0x76bba2cee66d47e9(ped) end

---@return boolean
function N_0x76bf03fadbf154f5() end

---@return boolean
function N_0x76d9b976c4c09fde() end

---@return integer
function N_0x76ef28da05ea395a() end

---@param radioStation string
---@param toggle boolean
function N_0x774bd811f656a122(radioStation, toggle) end

function N_0x7792424aa0eac32e() end

---@return integer
function N_0x77c3cec46be286f6() end

---@param x number
---@param y number
function N_0x77e2dd177910e1cf(x, y) end

---@param pageId integer
function N_0x77f16b447824da6c(pageId) end

---@param object integer
---@param toggle boolean
function N_0x77f33f2ccf64b3aa(object, toggle) end

---@param string string
function N_0x77fe3402004cd1b0(string) end

---@param ped Ped
---@param name string
function N_0x781de8fa214e87d2(ped, name) end

---@param ped Ped
---@return boolean
function N_0x784002a632822099(ped) end

---@param hudIndex integer
---@param x number
---@param y number
---@param z number
function N_0x784ba7e0eceb4178(hudIndex, x, y, z) end

---@param p0 boolean
function N_0x78857fc65cadb909(p0) end

---@param hudIndex integer
---@param style integer
---@param hudColor integer
---@param alpha integer
---@param arrowPosition integer
---@param boxOffset integer
function N_0x788e7fd431bd67f1(hudIndex, style, hudColor, alpha, arrowPosition, boxOffset) end

---@return integer
function N_0x78c0d93253149435() end

---@param ped Ped
---@param p1 integer
function N_0x78c4e9961db3eb5b(ped, p1) end

---@param p0 unknown
---@param p1 unknown
function N_0x792271ab35c356a4(p0, p1) end

---@return boolean
---@return unknown p0
function N_0x796a87b3b68d1f3d() end

---@param amount integer
function N_0x797f9c5e661d920e(amount) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param r integer
---@param g integer
---@param b integer
---@param opacity number
function N_0x799017f9e3b10112(x, y, z, radius, r, g, b, opacity) end

---@param p0 unknown
function N_0x79ab33f0fbfac40c(p0) end

---@param hash Hash|string
---@return boolean
function N_0x79c0e43eb9b944e2(hash) end

---@param vehicle integer
---@param range integer
function N_0x79df7e806202ce01(vehicle, range) end

---@param ped Ped
function N_0x7a73d05a607734c7(ped) end

---@param toggle boolean
function N_0x7ac752103856fb20(toggle) end

---@param chTitle string
---@param iconType integer
---@param chSubtitle string
---@param isImportant boolean
---@param titleColor integer
---@param p5 boolean
---@return unknown
function N_0x7ae0589093a2e088(chTitle, iconType, chSubtitle, isImportant, titleColor, p5) end

---@param color integer
function N_0x7b21e0bb01e8224a(color) end

---@return boolean
function N_0x7b226c785a52a0a9() end

---@param labelName string
---@return string
function N_0x7b5280eba9840c72(labelName) end

---@param gamerTagId integer
---@param string string
function N_0x7b7723747ccb55b6(gamerTagId, string) end

---@param cam integer
---@param p1 integer
---@param flags integer
function N_0x7bf1a54ae67ac070(cam, p1, flags) end

---@param vehicle integer
function N_0x7c0043fdff6436bc(vehicle) end

---@param vehicle integer
function N_0x7c06330bfdda182e(vehicle) end

---@return boolean
function N_0x7c814d2fb49f40c0() end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@param p3 boolean
function N_0x7c99101f7fce2ee5(p0, p1, p2, p3) end

---@param bumpiness number
function N_0x7c9c0b1eeb1f9072(bumpiness) end

---@param ped Ped
---@return integer
function N_0x7cd934010e115c2c(ped) end

---@param ped Ped
---@param voiceGroupHash Hash|string
function N_0x7cdc8c3b89f661b3(ped, voiceGroupHash) end

---@param p0 unknown
---@return integer
function N_0x7cf0448787b23758(p0) end

---@param unused unknown
---@return boolean
function N_0x7d41e9d2d17c5b2d(unused) end

---@param ped Ped
function N_0x7d7a2e43e74e2eb8(ped) end

---@param camera integer
---@param p1 number
function N_0x7dd234d6f3914c5b(camera, p1) end

---@return integer lastItemMenuId
---@return integer selectedItemMenuId
---@return integer selectedItemUniqueId
function N_0x7e17be53e1aaabaf() end

---@param soundId integer
---@param x number
---@param y number
---@param z number
function N_0x7ec3c679d0e7e46b(soundId, x, y, z) end

---@param toggle boolean
function N_0x7ec8aba5e74b3d7a(toggle) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param traceFlags integer
---@param entity Entity
---@param options integer
---@return integer
function N_0x7ee9f5d83dd4f90e(x1, y1, z1, x2, y2, z2, traceFlags, entity, options) end

---@param sceneID integer
---@return boolean
function N_0x7f2f4f13ac5257ef(sceneID) end

---@param padIndex integer
function N_0x7f4724035fdca1dd(padIndex) end

---@param contentTypeName string
---@param contentId string
---@param p2 integer
---@param p3 integer
---@param p4 integer
---@return integer
function N_0x7fd2990af016795e(contentTypeName, contentId, p2, p3, p4) end

function N_0x806058bbdc136e06() end

---@param toggle boolean
function N_0x808519373fd336a3(toggle) end

---@param index integer
---@return integer
function N_0x8098c8d6597aae18(index) end

---@param padIndex integer
---@param controlGroup integer
---@param p2 boolean
---@return string
function N_0x80c2fd58d720c801(padIndex, controlGroup, p2) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function N_0x80c75307b1c42837(index, spStat, charStat, character) end

---@param blip integer
function N_0x80ead8e2e1d5d52e(blip) end

---@return number
function N_0x80ec114669daeff4() end

function N_0x80fe4f3ab4e1b62a() end

---@return boolean
function N_0x810e8431c0614bf9() end

---@return boolean
function N_0x8132c0eb8b2b3293() end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
---@return boolean
function N_0x81404f3dc124fe5b(amount, p1, p2) end

---@param token integer
---@return integer
function N_0x8147fff6a718e1ad(token) end

---@param entity Entity
---@return integer
function N_0x815f18ad865f057f(entity) end

---@param ped Ped
---@param p1 unknown
---@param p2 number
---@param p3 number
---@param p4 unknown
function N_0x816f6981c60bf53b(ped, p1, p2, p3, p4) end

---@param vehicle integer
---@param weaponIndex integer
---@return integer
function N_0x8181ce2f25cb9bb7(vehicle, weaponIndex) end

---@param ped Ped
---@return boolean
function N_0x81aa517fbba05d39(ped) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function N_0x8204da7934df3155(p0, p1, p2) end

---@param characterSlot integer
function N_0x821418c727fcacd7(characterSlot) end

---@param player unknown
function N_0x821fdc827d6f4090(player) end

---@return integer
function N_0x82352748437638ca() end

---@param player integer
---@return boolean
function N_0x82377b65e943f72d(player) end

---@param padIndex integer
---@param red integer
---@param green integer
---@param blue integer
function N_0x8290252fff36acb5(padIndex, red, green, blue) end

---@return boolean
function N_0x82a2b386716608f1() end

---@param p0 unknown
---@param p1 unknown
function N_0x82a3d6d9cc2cb8e3(p0, p1) end

---@param toggle boolean
function N_0x82cedc33687e1f50(toggle) end

---@param token integer
---@return boolean
function N_0x82e4a58babc15ae7(token) end

---@param ped Ped
---@param weaponHash Hash|string
---@param distance number
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 outCoords
---@return integer outProjectile
function N_0x82fde6a57ee4ee44(ped, weaponHash, distance, ownedByPlayer) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
function N_0x8339643499d1222e(entity, x, y, z) end

---@param vehicle integer
---@param toggle boolean
function N_0x838da0936a24ed4d(vehicle, toggle) end

---@param ped Ped
---@param index integer
function N_0x83a169eabcdb10a2(ped, index) end

---@param cam integer
---@param p1 integer
---@param p2 integer
---@param p3 number
function N_0x83b8201ed82a9a2d(cam, p1, p2, p3) end

---@param filename string
---@return boolean
function N_0x83bcce3224735f05(filename) end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@return boolean
function N_0x83f28ce49fbbffba(p0, p1, p2) end

---@param vehicle integer
---@param toggle boolean
function N_0x83f813570ff519de(vehicle, toggle) end

---@param ped Ped
---@return number
function N_0x840f03e9041e2c9c(ped) end

---@param name string
---@return boolean
function N_0x8416fe4e4629d7d7(name) end

---@param ped Ped
---@param itemSet unknown
function N_0x8421eb4da7e391b9(ped, itemSet) end

---@param contextHash Hash|string
---@return boolean
function N_0x84698ab38d0c6636(contextHash) end

---@param entity Entity
---@return number
function N_0x846bf6291198a71e(entity) end

---@return unknown data
function N_0x848b66100ee33b05() end

---@param p0 unknown
function N_0x84c0116d012e8fc2(p0) end

---@param vehicle integer
---@param wheelId integer
---@param value number
function N_0x84ea99c62cb3ef0c(vehicle, wheelId, value) end

---@param multiplier number
function N_0x84fd40f56075e816(multiplier) end

---@param text string
function N_0x853648fd1063a213(text) end

---@return boolean
function N_0x85443ff4c328f53b() end

---@param token integer
---@return boolean
function N_0x85535acf97fc0969(token) end

---@return boolean
function N_0x855bc38818f6f684() end

---@param amount integer
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x8586789730b10caf(amount, p1, p2, p3) end

---@return boolean
---@return unknown p0
function N_0x85a0ef54a500882c() end

---@param garageHash Hash|string
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p4 unknown
---@return boolean
function N_0x85b6c850546fdde2(garageHash, p1, p2, p3, p4) end

---@param scaleformIndex integer
---@return boolean
function N_0x86255b1fc929e33e(scaleformIndex) end

---@param pickup integer
---@param toggle boolean
function N_0x867458251d47ccb2(pickup, toggle) end

---@return boolean
function N_0x869daacbbe9fa006() end

---@param vehicle integer
---@param weaponSlot integer
function N_0x86b4b6212cb8b627(vehicle, weaponSlot) end

function N_0x86e0660e4f5c956d() end

---@return boolean
function N_0x876928dddfccc9cd() end

---@param cargobob integer
---@param length1 number
---@param length2 number
---@param state boolean
function N_0x877c1eaeac531023(cargobob, length1, length2, state) end

function N_0x878c75c09fbdb942() end

---@param scaleform integer
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param p7 number
---@param sharpness number
---@param p9 number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param p13 unknown
function N_0x87d51d72255d4e78(scaleform, posX, posY, posZ, rotX, rotY, rotZ, p7, sharpness, p9, scaleX, scaleY, scaleZ, p13) end

---@param index integer
---@return boolean
---@return integer outData
function N_0x87e0052f08bd64e6(index) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function N_0x87e5c46c187fe0ae(p0, p1) end

---@return boolean
---@return integer networkHandle
function N_0x87eb7a3ffcb314db() end

---@param p0 unknown
---@return boolean
function N_0x8806cebfabd3ce05(p0) end

function N_0x8817605c2ba76200() end

---@return boolean
function N_0x883d79c4071e18b3() end

---@return integer
---@return unknown data
function N_0x886913bbeaca68c1() end

function N_0x88bb3507ed41a240() end

---@param ped Ped
---@param modifier number
function N_0x88e32db8c1a4aa4b(ped, modifier) end

---@param modelHash Hash|string
---@param toggle boolean
function N_0x88eaec617cd26926(modelHash, toggle) end

---@return integer
function N_0x89023fbbf9200e9f() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x89049a84065ce68e(p0, p1, p2, p3) end

---@param ped Ped
function N_0x89049dd63c08b5d1(ped) end

---@param vehicle integer
---@param toggle boolean
function N_0x890e2c5abed7236d(vehicle, toggle) end

---@param p0 number
---@param p1 integer
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 integer
---@param p8 integer
---@return Ped
function N_0x89215ec747df244a(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@param speakerConversationIndex integer
---@param entity Entity
function N_0x892b6ab8f33606f5(speakerConversationIndex, entity) end

---@return boolean
---@return integer p0
---@return boolean p1
function N_0x897433d292b44130() end

---@param object integer
---@return integer
function N_0x899ba936634a322e(object) end

---@param name string
function N_0x89c8553dd3274aae(name) end

---@param handler integer
---@param container Entity
---@return boolean
function N_0x89d630cf5ea96d23(handler, container) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
function N_0x8a24b067d175a7bd(x1, y1, z1, x2, y2, z2) end

---@param decalType integer
---@param textureDict string
---@param textureName string
function N_0x8a35c742130c6080(decalType, textureDict, textureName) end

---@param interrupterPed Ped
---@param context string
---@param voiceName string
function N_0x8a694d7a68f8dc38(interrupterPed, context, voiceName) end

---@param interior integer
---@param roomName string
function N_0x8a7a40100edfec58(interior, roomName) end

---@param amountSpent integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function N_0x8a7b3952dd64d2b5(amountSpent, p1, p2, p3) end

function N_0x8a800daccc0da55d() end

---@return boolean
function N_0x8a9ba1ab3e237613() end

---@return boolean
function N_0x8aa464d4e0f6accd() end

---@param vehicle integer
---@param avoidObstacles boolean
function N_0x8aa9180de2fedd45(vehicle, avoidObstacles) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function N_0x8abe8608576d9ce3(x1, y1, x2, y2) end

---@param playerType integer
---@param playerCount integer
function N_0x8b6a4dd0af9ce215(playerType, playerCount) end

---@param ped Ped
function N_0x8bbacbf51da047a8(ped) end

---@param player integer
---@return number
function N_0x8bc515bae4aaf8ff(player) end

---@param p0 integer
---@return integer
function N_0x8bd6c6dea20e82c6(p0) end

---@param x number
---@param y number
---@param z number
---@return boolean
---@return number groundZ
---@return vector3 normal
function N_0x8bdc7bfc57a81e76(x, y, z) end

---@param tunableContext string
---@param tunableName string
---@return boolean
---@return integer value
function N_0x8be1146dfd5d4468(tunableContext, tunableName) end

---@return number
function N_0x8bfceb5ea1b161b6() end

---@param ped Ped
---@param taskSequenceId integer
function N_0x8c33220c8d78ca0d(ped, taskSequenceId) end

---@param ped Ped
---@param p1 boolean
---@param p2 boolean
---@return integer
function N_0x8c4f3bf23b6237db(ped, p1, p2) end

---@return boolean
function N_0x8d11e61a4abf49cc() end

---@return boolean
function N_0x8d30f648014a92b5() end

---@param vehicle integer
---@return boolean
function N_0x8d474c8faeff6cde(vehicle) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param projectileHash Hash|string
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 projectilePos
function N_0x8d7a43ec6a5fea45(x1, y1, z1, x2, y2, z2, projectileHash, ownedByPlayer) end

---@param cam integer
---@param vehicle integer
---@param boneIndex integer
---@param relativeRotation boolean
---@param rotX number
---@param rotY number
---@param rotZ number
---@param offX number
---@param offY number
---@param offZ number
---@param fixedDirection boolean
function N_0x8db3f12a02caef72(cam, vehicle, boneIndex, relativeRotation, rotX, rotY, rotZ, offX, offY, offZ, fixedDirection) end

---@param style integer
function N_0x8db8cffd58b62552(style) end

---@param ped Ped
---@return vector3
function N_0x8dc9675797123522(ped) end

function N_0x8e2a065abdae6994() end

---@param vehicle integer
---@param state integer
function N_0x8ea86df356801c7d(vehicle, state) end

---@param player integer
---@return boolean
---@return integer p1
---@return integer p2
function N_0x8ef5573a1f801a5c(player) end

---@param chTitle string
---@param clanTxd string
---@param clanTxn string
---@param isImportant boolean
---@param showSubtitle boolean
---@return integer
function N_0x8efccf6ec66d85e4(chTitle, clanTxd, clanTxn, isImportant, showSubtitle) end

---@return boolean
---@return unknown networkHandle
function N_0x8f5d1ad832aeb06c() end

---@param p0 unknown
---@return boolean
function N_0x8f5ea1c01d65a100(p0) end

---@param vehicle integer
---@param toggle boolean
function N_0x8f719973e1445ba2(vehicle, toggle) end

---@param gxtEntry string
function N_0x8f9ee5687f8eeccd(gxtEntry) end

---@param ped Ped
---@param p1 integer
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 boolean
function N_0x8fa9c42fc5d7c64b(ped, p1, p2, p3, p4, p5) end

---@param ped Ped
---@param bBlockIdleClips boolean
---@param bRemoveIdleClipIfPlaying boolean
function N_0x8fd89a6240813fd0(ped, bBlockIdleClips, bRemoveIdleClipIfPlaying) end

---@param toggle boolean
---@param radarThickness integer
---@param mapThickness integer
function N_0x900086f371220b6f(toggle, radarThickness, mapThickness) end

---@param vehicle integer
---@param scalar number
function N_0x9007a2f21dc108d4(vehicle, scalar) end

---@param x number
---@param y number
---@return integer
function N_0x9040dfb09be75706(x, y) end

---@return boolean
function N_0x9049fe339d5f6f6f() end

---@return string
function N_0x906b778ca1dc72b6() end

---@param p0 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return unknown p1
function N_0x90a6526cf0381030(p0, p2, p3) end

---@return integer
function N_0x90a78ecaa4e78453() end

---@param range number
function N_0x90b6da738a9a25da(range) end

---@param element integer
---@param item string
function N_0x90d0622866e80445(element, item) end

---@param entity integer
---@param toggle boolean
---@param p2 integer
function N_0x911024442f4898f0(entity, toggle, p2) end

---@return boolean
function N_0x9135584d09a3437e() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@return unknown
function N_0x918c7b2d2ff3928b(x1, y1, z1, x2, y2, z2, width) end

---@param vehicle integer
---@param toggle boolean
function N_0x91a0bd635321f145(vehicle, toggle) end

---@return boolean
function N_0x91b87c55093de351() end

---@return boolean
function N_0x91d6dd290888cbab() end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 number
---@param p5 number
---@param p6 number
---@param weaponHash Hash|string
---@return integer
function N_0x91ef34584710be99(x, y, z, radius, p4, p5, p6, weaponHash) end

---@param interiorID integer
---@param roomHashKey Hash|string
function N_0x920d853f3e17f1da(interiorID, roomHashKey) end

---@param ped Ped
---@return boolean
function N_0x921ce12c489c4c41(ped) end

---@return boolean
function N_0x924426bffd82e915() end

---@param toggle boolean
function N_0x9245e81072704b8a(toggle) end

---@param amount integer
---@param bunkerHash Hash|string
function N_0x9251b6abf2d0a5b4(amount, bunkerHash) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
---@param p3 unknown
function N_0x925227803a0eaa1b(p0, p1, p2, p3) end

---@param id integer
---@param time number
---@return vector3
function N_0x92523b76657a517d(id, time) end

function N_0x92790862e36c2ada() end

function N_0x928dbfb892638ef3() end

---@param object integer
---@param p1 boolean
---@param p2 boolean
function N_0x92aefb5f6e294023(object, p1, p2) end

---@param pilot Ped
---@param aircraft integer
---@param xPos number
---@param yPos number
---@param zPos number
---@param fCruiseSpeed number
---@param fTargetReachedDist number
function N_0x92c360b5f15d2302(pilot, aircraft, xPos, yPos, zPos, fCruiseSpeed, fTargetReachedDist) end

function N_0x92ccc17a7a2285da() end

---@param hudColorIndex integer
function N_0x92f0da1e27db96dc(hudColorIndex) end

---@param msgIndex integer
---@return boolean
function N_0x93028f1db42bfd08(msgIndex) end

---@param hudComponent integer
function N_0x9304881d6f6537ea(hudComponent) end

---@param token integer
---@return integer
function N_0x930de22f07b1cce3(token) end

---@param amount integer
---@param matchId string
---@param p2 boolean
---@param p3 boolean
function N_0x9346e14f2af74d46(amount, matchId, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0x93aa4165cb67e925(p0, p1, p2, p3) end

---@return unknown
function N_0x941e5306bcd7c2c7() end

---@param vehicle integer
---@param toggle boolean
function N_0x94a68da412c4007d(vehicle, toggle) end

---@return boolean
function N_0x94a8394d150b013a() end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param maxPlayers integer
---@param p4 boolean
---@return boolean
function N_0x94bc51e9449d917f(p0, p1, p2, maxPlayers, p4) end

---@param p0 integer
---@return integer
function N_0x94f12abf9c79e339(p0) end

---@param radioStationName string
---@param toggle boolean
function N_0x94f2e83ead7e6b82(radioStationName, toggle) end

---@param p0 integer
---@return boolean
function N_0x9507d4271988e1ae(p0) end

---@param audioName string
---@param entity Entity
function N_0x950a154b8dab6185(audioName, entity) end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
---@param flags integer
function N_0x952f06beecd775cc(ped, vehicle, seatIndex, flags) end

---@param ped Ped
---@return integer
function N_0x953563ce563143af(ped) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 boolean
---@param p5 boolean
---@param p6 boolean
---@param p7 boolean
function N_0x957838aaf91bd12d(x, y, z, radius, p4, p5, p6, p7) end

---@param vehicle integer
function N_0x95cf53b3d687f9fa(vehicle) end

function N_0x95cf81bd06ee1887() end

---@param ped Ped
---@param txd string
---@param txn string
---@return boolean
function N_0x95eb5e34f821babe(ped, txd, txn) end

---@return integer
function N_0x9614b71f8adb982b() end

function N_0x966dd84fb6a46017() end

---@param x number
---@param y number
---@param z number
---@param p3 number
function N_0x967278682cb6967a(x, y, z, p3) end

---@return boolean
function N_0x9689123e3f213aa5() end

---@param object integer
---@param intensity integer
function N_0x96ee0eba0163df80(object, intensity) end

---@return integer
function N_0x971d7b15bcdbef99() end

---@param object integer
---@param textureVariation integer
function N_0x971da0055324d033(object, textureVariation) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
---@return number value
function N_0x972bc203bbc4c4d5(tunableContext, tunableName) end

---@param vehicle integer
---@param toggle boolean
function N_0x9737a37136f07e75(vehicle, toggle) end

---@return boolean
function N_0x9747292807126eda() end

---@param maximumValue integer
function N_0x975d66a0bc17064c(maximumValue) end

---@param player integer
---@param x number
---@param y number
---@param z number
---@param p4 boolean
---@param p5 boolean
function N_0x9769f811d1785b03(player, x, y, z, p4, p5) end

---@return boolean
function N_0x9777734dad16992f() end

---@return number
function N_0x9780f32bcaf72431() end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function N_0x97a770beef227e2b(p0, p1) end

---@param ped Ped
---@param range number
function N_0x97c65887d4b37fa9(ped, range) end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param hasFounderStatus boolean
---@param isImportant boolean
---@param clanHandle integer
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function N_0x97c9e4e7024a8f2c(crewTypeIsPrivate, crewTagContainsRockstar, rank, hasFounderStatus, isImportant, clanHandle, r, g, b) end

---@param vehicle integer
---@param toggle boolean
function N_0x97ce68cb032583f0(vehicle, toggle) end

---@param player integer
---@param toggle boolean
function N_0x97dd4c5944cc2e6a(player, toggle) end

---@param isVisible boolean
function N_0x98215325a695e78a(isVisible) end

---@param p0 string
---@param ped Ped
---@param p2 integer
---@param posX number
---@param posY number
---@param posZ number
---@return boolean
function N_0x98c4fe6ec34154ca(p0, ped, p2, posX, posY, posZ) end

---@param vehicle integer
---@return Entity
function N_0x99093f60746708ca(vehicle) end

---@param p0 unknown
---@return boolean
function N_0x993cbe59d350d225(p0) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function N_0x995a65f15f581359(amount, p1, p2) end

---@return integer
function N_0x996dd1e1e02f1008() end

---@param p0 number
function N_0x99ac7f0d8b9c893d(p0) end

---@param vehicle integer
function N_0x99ad4cccb128cbc9(vehicle) end

---@param ped Ped
---@param player integer
---@return boolean
function N_0x99b72c7abde5c910(ped, player) end

---@param vehicle integer
---@param toggle boolean
function N_0x99c82f8a139f3e4e(vehicle, toggle) end

---@param p0 integer
---@return boolean
function N_0x9a2c8064b6c1e41a(p0) end

---@param ped Ped
---@param hash Hash|string
function N_0x9a53ded9921de990(ped, hash) end

---@return integer
function N_0x9a73240b49945c76() end

---@param x number
---@param y number
---@param z number
---@param radius number
function N_0x9a75585fb2e54fad(x, y, z, radius) end

---@param vehicle integer
---@return boolean
function N_0x9a83f5f9963775ef(vehicle) end

---@param player integer
---@param crimeType integer
function N_0x9a987297ed8bd838(player, crimeType) end

---@return unknown
function N_0x9aa46badad0e27ed() end

---@param vehicle integer
---@param angle number
function N_0x9aa47fff660cb932(vehicle, angle) end

---@param dispatchService integer
---@param toggle boolean
function N_0x9b2bd3773123ea2f(dispatchService, toggle) end

---@param p0 unknown
---@return unknown
function N_0x9b6e70c5ceef4eeb(p0) end

---@param gamerTagId integer
---@param count integer
function N_0x9b9aa95688f78dd3(gamerTagId, count) end

---@param doorHash Hash|string
---@param distance number
---@param requestDoor boolean
---@param forceUpdate boolean
function N_0x9ba001cb45cbf627(doorHash, distance, requestDoor, forceUpdate) end

---@param aircraft integer
---@param count integer
function N_0x9bda23bf666f0855(aircraft, count) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function N_0x9bea350d7c48061b(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@return boolean
---@return unknown p2
function N_0x9bf438815f5d96ea(p0, p1, p3, p4, p5) end

---@param vehicle integer
function N_0x9c11908013ea4715(vehicle) end

---@param pickupHash unknown
---@param posX number
---@param posY number
---@param posZ number
---@param flags integer
---@param value integer
---@param modelHash unknown
---@param p7 boolean
---@param p8 boolean
---@return unknown
function N_0x9c93764223e29c50(pickupHash, posX, posY, posZ, flags, value, modelHash, p7, p8) end

---@param p0 integer
---@param p1 boolean
---@return boolean
function N_0x9cb0bfa7a9342c3d(p0, p1) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
function N_0x9cfdd90b2b844bf7(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function N_0x9d26502bb97bfe62(p0, p1, p2) end

---@param vehicle integer
---@param toggle boolean
function N_0x9d44fcce98450843(vehicle, toggle) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0x9d4fdbb035229669(p0, p1, p2) end

---@param ped Ped
---@return integer
function N_0x9d728c1e12bf5518(ped) end

---@param distance number
function N_0x9d75795b9dc6ebbf(distance) end

---@param toggle boolean
function N_0x9d8d44adbba61ef2(toggle) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 number
---@param p9 number
---@param weaponHash Hash|string
---@return integer
function N_0x9da58cdbf6bdbc08(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, weaponHash) end

---@param ped Ped
---@param p1 string
function N_0x9dba107b4937f809(ped, p1) end

---@param toggle boolean
function N_0x9dce1f0f78260875(toggle) end

---@param player integer
---@param toggle boolean
function N_0x9dd368bf06983221(player, toggle) end

---@param player integer
---@param index integer
---@return boolean
function N_0x9de986fc9a87c474(player, index) end

function N_0x9e4cfff989258472() end

---@param name string
function N_0x9e778248d6685fe0(name) end

---@param x number
---@param y number
---@param z number
---@param waterAsGround boolean
---@return boolean
---@return number groundZ
function N_0x9e82f0f362881b29(x, y, z, waterAsGround) end

---@param entity Entity
---@param toggle boolean
---@param keepPhysics boolean
function N_0x9ebc85ed0fffe51c(entity, toggle, keepPhysics) end

---@return boolean
function N_0x9eca15adfe141431() end

---@param maxBumpiness number
function N_0x9f5e6bb6b34540da(maxBumpiness) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return boolean
---@return unknown p3
---@return unknown p4
function N_0x9f6e2821885caee2(p0, p1, p2) end

---@param ped Ped
---@param weaponHash Hash|string
---@param camoComponentHash Hash|string
---@param colorIndex integer
function N_0x9fe5633880ecd8ed(ped, weaponHash, camoComponentHash, colorIndex) end

---@param model Hash|string
function N_0xa0261aef7acfc51e(model) end

---@return number
function N_0xa03502fc581f7d9b() end

---@param amount integer
function N_0xa03d4ace0a3284ce(amount) end

---@return boolean
function N_0xa049a5be0f04f2f8() end

---@return unknown
function N_0xa06509a691d12be4() end

---@param p0 unknown
---@param p1 unknown
function N_0xa071e0ed98f91286(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
function N_0xa091a5e44f0072e5(p0, p1, p2, p3) end

---@return boolean
function N_0xa097ab275061fb21() end

---@param p0 boolean
---@return integer
function N_0xa09f896ce912481f(p0) end

---@param player integer
---@param percentage number
---@return unknown
function N_0xa0d3e4f7aafb7e78(player, percentage) end

---@param x number
---@param y number
---@param z number
---@param heading number
---@return boolean
---@return vector3 outPosition
function N_0xa0f8a7517a273c05(x, y, z, heading) end

---@param player integer
function N_0xa1183bcfee0f93d1(player) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function N_0xa134777ff7f33331(p0) end

---@param charSlot integer
---@return boolean
function N_0xa135ac892a58fc07(charSlot) end

function N_0xa13c11e1b5c06bfc() end

---@param weaponTypeIndex integer
---@return Hash
function N_0xa13e93403f26c812(weaponTypeIndex) end

---@param netId integer
---@return boolean
function N_0xa1607996431332df(netId) end

---@param vehicle integer
---@param p1 number
function N_0xa17bad153b51547e(vehicle, p1) end

---@param model Hash|string
---@return boolean
function N_0xa1a9fc1c76a6730d(model) end

---@param cutsceneName string
---@return boolean
function N_0xa1c996c2a744262e(cutsceneName) end

---@param vehicle integer
---@param entity Entity
---@param p2 integer
---@param x number
---@param y number
---@param z number
function N_0xa1dd82f3ccf9a01e(vehicle, entity, p2, x, y, z) end

function N_0xa1e5e0204a6fcc70() end

---@param ped Ped
function N_0xa21c118553bbdf02(ped) end

function N_0xa2716d40842eaf79() end

---@return boolean
function N_0xa277800a9eae340e() end

function N_0xa29177f7703b5644() end

---@param vehicle integer
---@param multiplier number
function N_0xa2a707979fe754dc(vehicle, multiplier) end

---@param nodeID integer
---@return boolean
function N_0xa2ae5c478b96e3b6(nodeID) end

---@param index integer
---@return boolean
function N_0xa2f952104fc6dd4b(index) end

---@return boolean
function N_0xa31fd15197b192bd() end

---@param toggle boolean
function N_0xa356990e161c9e65(toggle) end

---@param ped Ped
function N_0xa3a9299c4f2adb98(ped) end

---@param eventGroup integer
---@param eventDataSize integer
---@param playerBits integer
---@return integer eventData
function N_0xa40cc53df8e50837(eventGroup, eventDataSize, playerBits) end

---@param characterSlot integer
---@return integer
function N_0xa40f9c2623f6a8b5(characterSlot) end

---@param p0 boolean
function N_0xa41bcd7213805aac(p0) end

function N_0xa44ff770dfbc5dae() end

---@param p0 integer
---@return vector3
function N_0xa4664972a9b8f8ba(p0) end

---@return number
function N_0xa4819f5e23e2ffad() end

---@return Hash
function N_0xa48931185f0536fe() end

function N_0xa4dede28b1814289() end

---@param toggle boolean
function N_0xa51c4b86b71652ae(toggle) end

---@param ped Ped
---@param p1 boolean
function N_0xa5342d390cda41d6(ped, p1) end

---@return boolean
function N_0xa586fbeb32a53dbb() end

---@param platformName string
---@return boolean
function N_0xa5c80d8e768a9e66(platformName) end

---@param ped Ped
---@param netSceneID integer
---@param animDict string
---@param animClip string
---@param blendIn number
---@param blendOut number
---@param sceneFlags integer
---@param ragdollFlags integer
---@param moverBlendInDelta number
---@param ikFlags integer
function N_0xa5eafe473e45c442(ped, netSceneID, animDict, animClip, blendIn, blendOut, sceneFlags, ragdollFlags, moverBlendInDelta, ikFlags) end

---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@param publish boolean
---@return boolean
function N_0xa5efc3e847d60507(contentName, description, tagsCsv, contentTypeName, publish) end

---@param timeMs integer
function N_0xa5f377b175a699c5(timeMs) end

---@return integer
function N_0xa635c11b8c44afc2() end

---@param cam integer
---@param p1 integer
---@param scale number
function N_0xa6385deb180f319f(cam, p1, scale) end

---@return boolean
function N_0xa65568121df2ea26() end

---@return Hash
function N_0xa6575914d2a0b450() end

---@return boolean
function N_0xa67c35c56eb1bd9d() end

---@param gamerTagId integer
---@param toggle boolean
function N_0xa67f9c46d612b6f1(gamerTagId, toggle) end

---@param data string
function N_0xa68d3d229f4f3b06(data) end

---@param index integer
---@return boolean
function N_0xa699957e60d80214(index) end

---@param p0 integer
---@return boolean
function N_0xa69ac4ade82b57a4(p0) end

---@param hash Hash|string
---@param p1 boolean
function N_0xa6a12939f16d85be(hash, p1) end

---@param vehicle integer
---@param livery integer
function N_0xa6d3a8750dc73270(vehicle, livery) end

---@return string
function N_0xa6fa3979bed01b81() end

---@return integer
function N_0xa72200f51875fea4() end

---@return integer
function N_0xa72835064dd63e4c() end

---@param name string
---@return unknown p0
function N_0xa735353c77334ea0(name) end

---@param toggle boolean
function N_0xa73667484d7037c3(toggle) end

---@param name string
---@param p1 number
function N_0xa74802fb8d0b7814(name, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
function N_0xa75ccf58a60a5fd1(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

---@return boolean
function N_0xa75e2b6733da5142() end

---@param p0 unknown
function N_0xa75eac69f59e96e7(p0) end

---@param scaling number
function N_0xa76359fc80b2438e(scaling) end

---@param name string
---@return boolean
---@return number outValue
function N_0xa770c8eec6fb2ac5(name) end

---@param distance number
function N_0xa78de25577300ba1(distance) end

---@param maxAmplitude number
function N_0xa7a1127490312c36(maxAmplitude) end

---@param p0 integer
---@return integer
function N_0xa7bab11e7c9c6c5a(p0) end

---@param player integer
---@param p1 boolean
function N_0xa7c511fa1c5bda38(player, p1) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
---@param heading number
function N_0xa7e30de9272b6d49(entity, x, y, z, heading) end

---@param ped Ped
---@param signalName string
---@return boolean
function N_0xa7ffba498e4aaf67(ped, signalName) end

---@param entity Entity
---@param toggle boolean
function N_0xa80ae305e0a3044f(entity, toggle) end

---@param p0 number
function N_0xa8434f1dff41d6e7(p0) end

---@param buttonIndex integer
function N_0xa86911979638106f(buttonIndex) end

---@param netId integer
---@param player integer
---@param toggle boolean
function N_0xa8a024587329f36a(netId, player, toggle) end

---@param groupName string
---@param contextBlockTarget integer
function N_0xa8a7d434afb4b97b(groupName, contextBlockTarget) end

---@param blip integer
---@param heading number
function N_0xa8b6afdac320ac87(blip, heading) end

function N_0xa8fdb297a8d25fba() end

---@param x number
---@param y number
---@param z number
function N_0xa905192a6781c41b(x, y, z) end

---@param p0 unknown
function N_0xa90e7227a9303fa9(p0) end

---@param characterSlot integer
function N_0xa921ded15fdf28f5(characterSlot) end

---@param p0 unknown
---@return boolean
function N_0xa9240a96c74cca13(p0) end

---@param mapObjectHash Hash|string
function N_0xa97f257d0151a6ab(mapObjectHash) end

---@return boolean
function N_0xa9cbfd40b3fa3010() end

---@param outfitHash Hash|string
---@param variantIndex integer
---@return boolean
---@return unknown outPropVariant
function N_0xa9f9c2e0fde11cbb(outfitHash, variantIndex) end

---@param textLabel string
---@return integer
function N_0xaa19f5572c38b564(textLabel) end

---@param textureDict string
---@param textureName string
---@param rpBonus integer
---@param colorOverlay integer
---@param titleLabel string
---@return integer
function N_0xaa295b6f28bd587d(textureDict, textureName, rpBonus, colorOverlay, titleLabel) end

function N_0xaa3f739abddcf21f() end

---@param tunableContext string
---@param tunableName string
---@return boolean
function N_0xaa6a47a573abb75a(tunableContext, tunableName) end

---@param toggle boolean
function N_0xaa6a6098851c396f(toggle) end

---@param toggle boolean
function N_0xaaa553e7dd28a457(toggle) end

---@param ped Ped
---@param flags integer
---@param switchType integer
function N_0xaab3200ed59016bc(ped, flags, switchType) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p4 unknown
---@return boolean
function N_0xab3caa6b422164da(p0, p1, p2, p3, p4) end

---@param functionName string
---@return boolean
function N_0xab58c27c2e6123c6(functionName) end

---@param ped Ped
---@param shouldDisable boolean
function N_0xab6781a5f3101470(ped, shouldDisable) end

---@param string string
function N_0xaba17d7ce615adbf(string) end

---@return integer
function N_0xabb2fa71c83a1b72() end

---@return unknown globalPtr
function N_0xabd5e88b8a2d3db2() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xac272c0ae01b4bd8(p0, p1, p2, p3) end

---@param vehicle integer
---@return Hash
function N_0xacb5dcca1ec76840(vehicle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 unknown
---@return boolean
function N_0xaccfb4acf53551b0(x, y, z, radius, p4) end

---@param vehicle integer
function N_0xacfb2463cc22bed2(vehicle) end

---@param vehicle integer
---@param multiplier number
function N_0xad2d28a1afdff131(vehicle, multiplier) end

function N_0xad5fdf34b81bfe79() end

---@param id integer
function N_0xad6875bbc0fc899c(id) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
function N_0xaddd1c754e2e2914(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

function N_0xaded7f5748acafe6() end

function N_0xae4e8157d9ecf087() end

---@param p0 integer
---@param player integer
---@return boolean
function N_0xaeef48cdf5b6ce7c(p0, player) end

---@param vehicle integer
---@return boolean
function N_0xaef12960fa943792(vehicle) end

---@param vehicle integer
---@param entity Entity
---@return unknown
function N_0xaf03011701811146(vehicle, entity) end

---@param name string
---@param toggle boolean
function N_0xaf12610c644a35c9(name, toggle) end

---@return boolean
function N_0xaf42195a42c63bba() end

---@return boolean
---@return integer loadingState
function N_0xaf50da1a3f8b1ba4() end

---@param p0 boolean
function N_0xaf66059a131aa269(p0) end

function N_0xaf66dcee6609b148() end

---@return boolean
function N_0xaf754f20eb5cd51a() end

---@param p0 number
---@param p1 number
---@param p2 number
function N_0xafc7e5e075a96f46(p0, p1, p2) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function N_0xafe08b35ec0c9eae(amount, p1, p2) end

---@param ped Ped
function N_0xaff4710e2a0a6c12(ped) end

---@param vehicle integer
---@param toggle boolean
function N_0xb055a34527cb8fd7(vehicle, toggle) end

---@param entity Entity
---@return boolean
function N_0xb07d3185e11657a5(entity) end

---@param vehicle integer
---@param p1 boolean
function N_0xb088e9a47ae6edd5(vehicle, p1) end

---@param incidentId integer
---@param dispatchService integer
---@param numUnits integer
function N_0xb08b85d860e7ba3c(incidentId, dispatchService, numUnits) end

---@param hudIndex integer
---@param entity Entity
---@param offsetX number
---@param offsetY number
function N_0xb094bc1db4018240(hudIndex, entity, offsetX, offsetY) end

---@param ped Ped
---@param vehicle integer
---@return boolean
---@return integer outIndex
function N_0xb09d25e77c33eb3f(ped, vehicle) end

---@param ped Ped
---@param signalName string
---@param value boolean
function N_0xb0a6cfd2c69c1088(ped, signalName, value) end

---@param boat integer
---@return boolean
function N_0xb0ad1238a709b1a2(boat) end

---@param toggle boolean
function N_0xb0c56bd3d808d863(toggle) end

---@param type string
function N_0xb11d94bc55f41932(type) end

---@param p0 integer
function N_0xb1252e3e59a82aaf(p0) end

---@param id integer
---@param p1 boolean
function N_0xb129e447a2eda4bf(id, p1) end

---@param ped Ped
---@param hasCone boolean
---@param color integer
function N_0xb13dcb4c6faad238(ped, hasCone, color) end

function N_0xb1577667c3708f9b() end

---@param type integer
---@param xPos number
---@param yPos number
---@param zPos number
---@param p4 number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function N_0xb1bb03742917a5d6(type, xPos, yPos, zPos, p4, red, green, blue, alpha) end

---@param amount integer
function N_0xb1cc1b9ec3007a2a(amount) end

---@param entity integer
---@param toggle boolean
---@param p2 integer
---@param ped Ped
function N_0xb20834a7dd3d8896(entity, toggle, p2, ped) end

---@param player integer
---@return boolean
function N_0xb2092a1eaa7fd45f(player) end

---@param player integer
---@param p1 integer
function N_0xb214d570ead7f81a(player, p1) end

---@param charSlot integer
---@return boolean
function N_0xb24f0944da203d9e(charSlot) end

---@param vehicle integer
---@param deploy boolean
---@param p2 boolean
function N_0xb251e0b33e58b424(vehicle, deploy, p2) end

---@param vehicle integer
function N_0xb264c4d2f2b0a78b(vehicle) end

---@param boat integer
---@param toggle boolean
function N_0xb28b1fe5bfadd7f5(boat, toggle) end

---@return boolean
function N_0xb2a592b04648a9cb() end

---@param x number
---@param y number
---@param z number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param interiorFlags integer
---@param scale number
---@param duration integer
function N_0xb2aff10216defa2f(x, y, z, p3, p4, p5, p6, interiorFlags, scale, duration) end

---@return integer
function N_0xb2d06faede65b577() end

---@param entity Entity
---@return integer
function N_0xb328dcc3a3aa401b(entity) end

---@param p3 unknown
---@param p4 boolean
---@return boolean
---@return unknown p1
---@return unknown p2
function N_0xb335f761606db47c(p3, p4) end

function N_0xb3cd58cca6cda852() end

---@param maxAmplitude number
function N_0xb3e6360dde733e82(maxAmplitude) end

---@param weaponObject integer
---@param camoComponentHash Hash|string
---@return integer
function N_0xb3ea4feabf41464b(weaponObject, camoComponentHash) end

---@return number
function N_0xb3eca65c7317f174() end

---@return boolean
function N_0xb3f64a6a91432477() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xb40f96d6d252839b(p0, p1, p2, p3) end

---@param index integer
---@return string
function N_0xb4271092ca7edf48(index) end

---@param vehicle integer
---@param p1 boolean
---@return string
function N_0xb45085b721efd38c(vehicle, p1) end

function N_0xb475f27c6a994d65() end

---@param ped Ped
---@param weaponHash Hash|string
---@param toggle boolean
function N_0xb4771b9aaf4e68e4(ped, weaponHash, toggle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param name string
---@return integer
function N_0xb48fced898292e52(x, y, z, radius, name) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xb49eca122467d05f(p0, p1, p2, p3) end

---@param p0 integer
---@param p1 boolean
function N_0xb4ab419e0d86acae(p0, p1) end

---@param portalSettingsName string
function N_0xb4bbfd9cd8b3922b(portalSettingsName) end

---@param ped Ped
---@param p1 number
---@return integer
function N_0xb4c8d77c80c0421e(ped, p1) end

---@param ped Ped
---@param eventName string
---@return boolean
function N_0xb4f47213df45a64c(ped, eventName) end

function N_0xb4f90faf7670b16f() end

---@return unknown
function N_0xb5074db804e28ce7() end

---@param ped Ped
function N_0xb50eb4ccb29704ac(ped) end

---@return boolean
function N_0xb56bbbcc2955d9cb() end

---@return boolean
---@return unknown networkHandle
function N_0xb57a49545ba53ce7() end

function N_0xb57d8dd645cfa2cf() end

function N_0xb5a4db34fe89b88a() end

---@param vehicle integer
---@param ped Ped
---@param index integer
function N_0xb5c51b5502e85e83(vehicle, ped, index) end

---@param vehicle integer
---@return boolean
function N_0xb5cc40fbcb586380(vehicle) end

---@param ch1TXD string
---@param ch1TXN string
---@param val1 integer
---@param ch2TXD string
---@param ch2TXN string
---@param val2 integer
---@return integer
function N_0xb6871b0555b02996(ch1TXD, ch1TXN, val1, ch2TXD, ch2TXN, val2) end

function N_0xb695e2cd0a2da9ee() end

---@param doorHash Hash|string
---@param ajar number
---@param requestDoor boolean
---@param forceUpdate boolean
function N_0xb6e6fba95c7324ac(doorHash, ajar, requestDoor, forceUpdate) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
function N_0xb7257ba2550ea10a(p0, p1, p2, p3, p4, p5, p6) end

---@param p0 unknown
---@return unknown p1
function N_0xb782f8238512bad5(p0) end

function N_0xb7c7f6ad6424304b() end

---@param decalType integer
function N_0xb7ed70c49521a61d(decalType) end

---@param blip integer
---@param toggle boolean
function N_0xb81656bc81fe24d1(blip, toggle) end

function N_0xb81cf134aeb56ffb() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0xb846f547d3792df6(p0, p1, p2) end

---@param x number
---@param y number
---@param z number
function N_0xb8721407ee9c3ff6(x, y, z) end

---@param plane integer
---@param height integer
function N_0xb893215d8d4c015b(plane, height) end

---@param amplitude number
function N_0xb8f87ead7533b176(amplitude) end

---@param vehicle integer
---@param toggle boolean
function N_0xb8fbc8b1330ca9b4(vehicle, toggle) end

---@param functionName string
---@return boolean
function N_0xb9449845f73f5e9c(functionName) end

---@param ped Ped
---@return boolean
function N_0xb9496ce47546db2c(ped) end

---@param intensity number
function N_0xb96b00e976be977f(intensity) end

---@param disturb number
function N_0xb9854dfde0d833d6(disturb) end

---@param flagIndex integer
function N_0xb99c4e4d9499df29(flagIndex) end

---@param style integer
---@param hudColor integer
---@param alpha integer
---@param p3 integer
---@param p4 integer
function N_0xb9c362babecddc7a(style, hudColor, alpha, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 boolean
function N_0xb9f7a469460e7a4a(p0, p1, p2, p3) end

---@param p0 boolean
---@param p1 boolean
---@param nearplaneOut number
---@param nearplaneIn number
---@param farplaneOut number
---@param farplaneIn number
function N_0xba3d65906822bed5(p0, p1, nearplaneOut, nearplaneIn, farplaneOut, farplaneIn) end

---@return boolean
function N_0xba416d68c631496a() end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@param section string
---@return Hash
function N_0xba52ff538ed2bc71(index, spStat, charStat, character, section) end

---@param ped Ped
---@param p1 boolean
---@return boolean
function N_0xba63d9fe45412247(ped, p1) end

function N_0xba751764f0821256() end

---@param ped Ped
---@return integer
function N_0xba8805a1108a2515(ped) end

---@param vehicle integer
---@return boolean
function N_0xba91d045575699ad(vehicle) end

function N_0xba96394a0eecfa65() end

---@return boolean
function N_0xba9775570db788cf() end

---@param vehicle integer
---@param speed number
function N_0xbaa045b4e42f3c06(vehicle, speed) end

---@param friendIndex integer
---@return boolean
function N_0xbad8f2a42b844821(friendIndex) end

---@param toggle boolean
function N_0xbae4f9b97cd43b30(toggle) end

---@param p0 integer
---@param p1 integer
---@return string
function N_0xbaf6babf9e7ccc13(p0, p1) end

---@return integer
function N_0xbb0527ec6341496d() end

---@param msgIndex integer
---@return Hash
function N_0xbb8ea16ecbc976c4(msgIndex) end

---@param p0 unknown
function N_0xbba55be9aaaabf44(p0) end

---@return integer
function N_0xbbb45c3cf5c8aa85() end

---@param modifierName string
function N_0xbbf327ded94e4deb(modifierName) end

---@param player integer
---@param ms integer
---@param p2 boolean
---@return boolean
function N_0xbc0753c9ca14b506(player, ms, p2) end

---@return boolean
function N_0xbc1cc91205ec8d6e() end

---@param player integer
---@return Hash
function N_0xbc1d768f2f5d6c05(player) end

---@param distance number
function N_0xbc3cca5844452b06(distance) end

---@param p0 unknown
function N_0xbc6227792a188e2e(p0) end

---@return boolean
function N_0xbc9823ab80a3dcac() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function N_0xbcb266247193ac61(p0, p1, p2, p3, p4) end

---@param cargobob integer
---@param strength number
function N_0xbcbfcd9d1dac19e2(cargobob, strength) end

---@param object integer
---@param toggle boolean
function N_0xbce595371a5fbaaf(object, toggle) end

---@param minAngle number
---@param maxAngle number
function N_0xbcfc632db7673bf0(minAngle, maxAngle) end

---@param player integer
---@param modifier number
function N_0xbcfde9ede4cf27dc(player, modifier) end

function N_0xbd0be0bfc927eac1() end

---@param busySpinnerType integer
function N_0xbd12f8228410d9b4(busySpinnerType) end

---@param vehicle integer
function N_0xbd32e46aa95c1dd2(vehicle) end

---@param name string
---@return boolean
function N_0xbd4d7eaf8a30f637(name) end

function N_0xbd605b8e0e18b3bb() end

---@param value number
function N_0xbdeb86f4d5809204(value) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
function N_0xbe3e347a87aceb82(p0, p1, p2, p3) end

---@param vehicle integer
---@param instantly boolean
function N_0xbe4c854ffdb6eebe(vehicle, instantly) end

---@param amount integer
function N_0xbe509b0a3693de8b(amount) end

---@param tvChannel integer
function N_0xbeb3d46bb7f043c0(tvChannel) end

---@param player integer
---@param toggle boolean
function N_0xbec0816ff5acbcda(player, toggle) end

---@return boolean
function N_0xbedb96a7584aa8cf() end

---@param p0 unknown
---@return string
function N_0xbf09786a7fcab582(p0) end

---@param ped Ped
---@param useSweetner boolean
---@param soundSetHash Hash|string
function N_0xbf4dc1784be94dfa(ped, useSweetner, soundSetHash) end

---@param modifierName string
function N_0xbf59707b3e5ed531(modifierName) end

---@param toggle boolean
function N_0xbfa0a56a817c6c7d(toggle) end

---@param modelHash Hash|string
---@return number
function N_0xbfba3ba79cff7ebf(modelHash) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param damage integer
---@param p7 boolean
---@param weaponHash Hash|string
---@param ownerPed Ped
---@param isAudible boolean
---@param isInvisible boolean
---@param speed number
---@param entity Entity
---@param p14 boolean
---@param p15 boolean
---@param p16 boolean
---@param p17 boolean
function N_0xbfe5756e7407064a(x1, y1, z1, x2, y2, z2, damage, p7, weaponHash, ownerPed, isAudible, isInvisible, speed, entity, p14, p15, p16, p17) end

---@param ped Ped
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@return integer
function N_0xbfefe3321a3f5015(ped, username, crewIsPrivate, crewIsRockstar, crewName, crewRank) end

---@param p0 integer
---@return string
function N_0xc0173d6bff4e0348(p0) end

---@param doorHash Hash|string
---@return boolean
function N_0xc01e93fac20c3346(doorHash) end

---@param hash Hash|string
---@return Hash
function N_0xc098810437312fff(hash) end

---@return boolean
function N_0xc0d2af00bcc234ca() end

---@param p0 unknown
---@param p1 unknown
function N_0xc10322a8d3e061ee(p0, p1) end

---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return unknown p0
---@return unknown p1
function N_0xc116ff9b4d488291(p2, p3) end

---@param p0 unknown
---@param p1 unknown
function N_0xc1447451ddb512f0(p0, p1) end

---@param doorHash Hash|string
---@return boolean
function N_0xc153c43ea202c8c1(doorHash) end

---@param vehicle integer
---@param enable boolean
function N_0xc15907d667f7cfb2(vehicle, enable) end

---@param componentHash Hash|string
---@return integer
function N_0xc17ad0e5752becda(componentHash) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0xc1952f3773ba18fe(p0, p1, p2) end

---@param p0 boolean
function N_0xc19f6c8e7865a6ff(p0) end

---@param ped Ped
---@param heatScale number
function N_0xc1f6ebf9a3d55538(ped, heatScale) end

---@param vehicle integer
---@param p1 boolean
function N_0xc1f981a6f74f0c23(vehicle, p1) end

---@param cameraCoordX number
---@param cameraCoordY number
---@param cameraCoordZ number
---@param camRotationX number
---@param camRotationY number
---@param camRotationZ number
---@param camFov number
---@param camFarClip number
---@param rotationOrder integer
function N_0xc208b673ce446b61(cameraCoordX, cameraCoordY, cameraCoordZ, camRotationX, camRotationY, camRotationZ, camFov, camFarClip, rotationOrder) end

---@param privilege integer
---@return boolean
---@return integer banType
---@return vector3 timeData
function N_0xc22912b1d85f26b1(privilege) end

---@param cutsceneName string
---@param playbackFlags integer
---@param flags integer
function N_0xc23de0e91c30b58c(cutsceneName, playbackFlags, flags) end

---@param vehicle integer
---@param wheelId integer
---@param state integer
---@param value number
---@param p4 number
function N_0xc24075310a8b9cd1(vehicle, wheelId, state, value, p4) end

---@param pedHandle Ped
---@return boolean
function N_0xc265df9fb44a9fbd(pedHandle) end

---@param achievement integer
---@param progress integer
---@return boolean
function N_0xc2afffdabbdc2c5c(achievement, progress) end

function N_0xc2b82527ca77053e() end

function N_0xc2d15bef167e27bc() end

---@param p0 string
---@param p1 string
---@param p2 string
---@param p3 number
function N_0xc2eae3fb8cdbed31(p0, p1, p2, p3) end

---@param charSlot integer
---@param amount integer
---@return boolean
function N_0xc2f7fe5309181c7d(charSlot, amount) end

---@param camera integer
---@param p1 number
function N_0xc3654a441402562d(camera, p1) end

---@param player integer
---@param limit number
function N_0xc388a0f065f5bc34(player, limit) end

---@return boolean
---@return unknown p0
---@return unknown p1
---@return unknown p2
function N_0xc38dc1e90d22547c() end

---@param mode integer
function N_0xc3ac2fff9612ac81(mode) end

---@param hash Hash|string
---@param p1 integer
---@param p2 integer
---@param state integer
---@param p4 integer
function N_0xc3bfed92026a2aad(hash, p1, p2, state, p4) end

---@param p0 number
function N_0xc3c221addde31a11(p0) end

---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return integer networkHandle
---@return unknown p1
function N_0xc3c7a6afdb244624(p2, p3) end

---@param minAmplitude number
function N_0xc3ead29ab273ece8(minAmplitude) end

---@return boolean
function N_0xc406be343fc4b9af() end

---@param blip integer
---@param toggle boolean
function N_0xc4278f70131baa6d(blip, toggle) end

---@param vehicle integer
---@param toggle boolean
function N_0xc45c27ef50f36adc(vehicle, toggle) end

---@param doorHash Hash|string
---@param removed boolean
---@param requestDoor boolean
---@param forceUpdate boolean
function N_0xc485e07e4f0b7958(doorHash, removed, requestDoor, forceUpdate) end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function N_0xc4bb08ee7907471e(index, spStat, charStat, character) end

---@return boolean
function N_0xc4c4575f62534a24() end

---@param toggle boolean
function N_0xc505036a35afd01b(toggle) end

---@param p0 unknown
function N_0xc5156361f26e2212(p0) end

---@param strength number
function N_0xc54a08c85ae4d410(strength) end

function N_0xc55854c7d7274882() end

---@return string
function N_0xc55a0b40ffb1ed23() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function N_0xc5be134ec7ba96a0(p0, p1, p2, p3, p4) end

---@param vehicle integer
---@param index integer
---@param toggle boolean
function N_0xc60060eb0d8ac7b1(vehicle, index, toggle) end

---@param flag boolean
function N_0xc6372ecd45d73bcd(flag) end

---@return boolean
---@return number timeInSeconds
---@return number bpm
---@return integer beatNum
function N_0xc64a06d939f826f5() end

---@param p0 string
---@return integer
function N_0xc64ded7ef0d2fe37(p0) end

function N_0xc65ab383cd91df98() end

---@param camera integer
---@param p1 number
function N_0xc669eea5d031b7de(camera, p1) end

---@param p0 unknown
function N_0xc66d1cf99ed7fe25(p0) end

---@param submarine integer
---@param time integer
function N_0xc67db108a9ade3be(submarine, time) end

---@param vehicle integer
---@return boolean
function N_0xc69bb1d832a710ef(vehicle) end

---@param modelHash Hash|string
---@return number
function N_0xc6ad107ddc9054cc(modelHash) end

---@return boolean
function N_0xc6dc823253fbb366() end

---@param txdName string
---@param textureName string
---@param flash boolean
---@param iconType integer
---@param sender string
---@param subject string
---@return integer
function N_0xc6f580e4c94926ac(txdName, textureName, flash, iconType, sender, subject) end

---@return boolean
function N_0xc70ddce56d0d3a99() end

---@return unknown data
function N_0xc729991a9065376e() end

---@param count integer
---@param latestVersion boolean
---@param contentTypeName string
---@return boolean
---@return unknown data
function N_0xc7397a83f7a2a462(count, latestVersion, contentTypeName) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@param defaultValue boolean
---@return boolean
function N_0xc7420099936ce286(tunableContext, tunableName, defaultValue) end

---@param entity Entity
---@return boolean
function N_0xc7827959479dcc78(entity) end

---@param bVisible boolean
---@param iColumnID integer
---@param iSpinnerIndex integer
function N_0xc78e239ac5b2ddb9(bVisible, iColumnID, iSpinnerIndex) end

---@param ped Ped
function N_0xc79196dcb36f6121(ped) end

function N_0xc79ae21974b01fb2() end

---@return boolean
function N_0xc7abac5de675ee3b() end

---@return integer
function N_0xc7be335216b5ec7c() end

function N_0xc7db36c24634f52b() end

---@param toggle boolean
function N_0xc7e7181c09f33b69(toggle) end

---@param bShouldApplyAcrossAllThreads boolean
---@param distanceToBlend number
---@param blendType integer
function N_0xc819f3cbb62bf692(bShouldApplyAcrossAllThreads, distanceToBlend, blendType) end

---@param amount integer
---@param p1 string
function N_0xc8407624cef2354b(amount, p1) end

---@param data string
---@param dataCount integer
---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@param publish boolean
---@return boolean
function N_0xc84527e235fca219(data, dataCount, contentName, description, tagsCsv, contentTypeName, publish) end

---@param name string
---@return boolean
---@return integer outValue
function N_0xc85a7127e7ad02aa(name) end

---@return unknown
function N_0xc88156ebb786f8d5() end

---@return boolean
function N_0xc8b1b2425604cdd0() end

---@param audioName string
---@param x number
---@param y number
---@param z number
function N_0xc8ede9bdbccba6d4(audioName, x, y, z) end

---@param chTitle string
---@param iconType integer
---@param chSubtitle string
---@param isImportant boolean
---@return unknown
function N_0xc8f3aaf93d0600bf(chTitle, iconType, chSubtitle, isImportant) end

---@return boolean
function N_0xc912af078af19212() end

---@param cam integer
---@param x number
---@param y number
---@param z number
function N_0xc91c6c55199308ca(cam, x, y, z) end

---@param yOffset number
function N_0xc92717ef615b6704(yOffset) end

---@param vehicle integer
---@param wheelIndex integer
---@param multiplier number
function N_0xc970d0e0fc31d768(vehicle, wheelIndex, multiplier) end

---@return boolean
---@return unknown p0
---@return unknown p1
function N_0xc980e62e33df1d5c() end

---@param player integer
function N_0xc9a763d8fe87436a(player) end

---@param p0 number
function N_0xc9b18b4619f48f7b(p0) end

---@param sceneId integer
function N_0xc9b43a33d09cada7(sceneId) end

---@param vehicle integer
---@param doorIndex integer
---@return integer
function N_0xca4ac3eaae46ec7b(vehicle, doorIndex) end

---@param model Hash|string
function N_0xca4cea6ae0000a7e(model) end

---@param keyboardType integer
---@param windowTitle string
---@param description string
---@param defaultText string
---@param defaultConcat1 string
---@param defaultConcat2 string
---@param defaultConcat3 string
---@param defaultConcat4 string
---@param defaultConcat5 string
---@param defaultConcat6 string
---@param defaultConcat7 string
---@param maxInputLength integer
function N_0xca78cfa0366592fe(keyboardType, windowTitle, description, defaultText, defaultConcat1, defaultConcat2, defaultConcat3, defaultConcat4, defaultConcat5, defaultConcat6, defaultConcat7, maxInputLength) end

---@param index integer
---@return string
function N_0xca94551b50b4932c(index) end

---@return boolean
function N_0xca9d2aa3e326d720() end

---@param vehicle integer
---@param toggle boolean
function N_0xcac66558b944da67(vehicle, toggle) end

---@param soundName string
---@param soundsetName string
function N_0xcada5a0d0702381e(soundName, soundsetName) end

---@param groupId integer
function N_0xcae55f48d3d7875c(groupId) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xcb00196b31c39eb1(p0, p1, p2, p3) end

---@param p0 boolean
---@return integer
function N_0xcb215c4b56a7fae7(p0) end

---@param ped Ped
---@param p1 boolean
---@param type integer
---@param p3 integer
function N_0xcb968b53fc7f916d(ped, p1, type, p3) end

---@param cargobob integer
---@return vector3
function N_0xcbdb9b923cacc92d(cargobob) end

function N_0xcc3fdded67bcfc63() end

---@param groupHash Hash|string
---@return boolean
function N_0xcc6e3b6bb69501f1(groupHash) end

---@param ped Ped
---@param r integer
---@param g integer
---@param b integer
---@param id integer
function N_0xcc9682b8951c5229(ped, r, g, b, id) end

---@return boolean
---@return unknown networkHandle
function N_0xcca4318e1ab03f1f() end

function N_0xcce26000e9a6fad7() end

---@param entity Entity
---@return boolean
function N_0xccf1e97befdae480(entity) end

---@param p0 integer
---@return string
function N_0xcd67ad041a394c9c(p0) end

---@param entity Entity
function N_0xcd71a4ecab22709e(entity) end

---@param zoneId integer
---@return boolean
function N_0xcd79a550999d7d4f(zoneId) end

---@param scene integer
function N_0xcd9cc7e200a52a6f(scene) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0xcda1c62be2777802(p0, p1, p2) end

---@param vehicle integer
---@param value integer
function N_0xcda42c4bb9bde779(vehicle, value) end

function N_0xcdca26e80faecb8f() end

---@return integer
---@return integer p0
function N_0xce5aa445aba8dee0() end

---@param x number
---@param y number
---@param z number
---@param width number
---@param height number
---@return integer
function N_0xce5d0e5e315db238(x, y, z, width, height) end

---@param entity Entity
---@param boneIndex integer
---@return vector3
function N_0xce6294a232d03786(entity, boneIndex) end

---@param p0 unknown
---@param p1 unknown
---@param vehicleHash Hash|string
function N_0xcea553e35c2246e1(p0, p1, vehicleHash) end

---@param toggle boolean
function N_0xcef214315d276fd1(toggle) end

---@return boolean
function N_0xcef70aa5b3f89ba1() end

---@return integer
function N_0xcefa968912d0f78d() end

---@param cargobob integer
---@param p1 number
function N_0xcf1182f682f65307(cargobob, p1) end

---@param gamerTagId integer
---@param wantedlvl integer
function N_0xcf228e2aa03099c3(gamerTagId, wantedlvl) end

---@return boolean
---@return integer state
function N_0xcf38dafbb49ede5e() end

---@return integer
function N_0xcf61d4b4702ee9eb() end

---@param netScene integer
---@param animDict string
---@param animName string
function N_0xcf8bd3b0bd6d42d7(netScene, animDict, animName) end

---@param p0 unknown
---@return unknown p1
function N_0xcfd115b373c0df63(p0) end

---@param p0 boolean
function N_0xcfdbdf5ae59ba0f4(p0) end

---@param toggle boolean
function N_0xcfeb8af24fc1d0bb(toggle) end

---@return number
function N_0xd0082607100d7193() end

---@param cutsceneName string
function N_0xd00d76a7dfc9d852(cutsceneName) end

---@param mode string
function N_0xd01005d2ba2eb778(mode) end

---@param ped Ped
---@param name string
---@return boolean
function N_0xd01015c7316ae176(ped, name) end

---@param p1 boolean
---@return boolean
---@return unknown p0
---@return unknown p2
function N_0xd05d1a6c74da3498(p1) end

---@param aircraft integer
---@return boolean
function N_0xd0917a423314bba8(aircraft) end

---@return boolean
function N_0xd0a484cb2f829fbe() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param index integer
function N_0xd0bc1c6fb18ee154(x1, y1, z1, x2, y2, z2, index) end

---@param oldPlateText string
---@param newPlateText string
---@param plateData string
---@return boolean
function N_0xd0ee05fe193646ea(oldPlateText, newPlateText, plateData) end

---@param joinType integer
function N_0xd1032e482629049e(joinType) end

---@param x number
---@param y number
---@param z number
function N_0xd10f442036302d50(x, y, z) end

---@param p0 unknown
---@param p1 boolean
---@param p2 unknown
---@return boolean
function N_0xd1110739eeadb592(p0, p1, p2) end

function N_0xd12882d3ff82bf11() end

---@param index integer
---@param spStat boolean
---@param charStat boolean
---@param character integer
---@return Hash
function N_0xd16c2ad6b8e32854(index, spStat, charStat, character) end

---@param ped Ped
---@return boolean
function N_0xd1871251f3b5acd7(ped) end

---@param cam integer
---@param smoothingStyle integer
function N_0xd1b0f412f109ea5d(cam, smoothingStyle) end

---@param scaleformHandle integer
---@return boolean
function N_0xd1c7cb175e012964(scaleformHandle) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xd1e46824e6fb92b5(p0, p1, p2, p3) end

---@return integer
function N_0xd1f7ca1535d22818() end

---@param value number
function N_0xd1f8363dfad03848(value) end

---@param eType integer
---@param iIcon integer
---@param sTitle string
---@return integer
function N_0xd202b92cbf1d816f(eType, iIcon, sTitle) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0xd20d79671a598594(p0, p1, p2) end

---@param effectName string
function N_0xd2209be128b5418c(effectName) end

---@param vehicle integer
---@param p1 integer
function N_0xd2300034310557e4(vehicle, p1) end

---@param incidentId integer
---@param p1 number
function N_0xd261ba3e7e998072(incidentId, p1) end

---@param p0 unknown
---@param p1 boolean
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 boolean
---@param p7 number
function N_0xd2936cab8b58fcbd(p0, p1, p2, p3, p4, p5, p6, p7) end

---@param gamerTagId integer
---@param toggle boolean
function N_0xd29ec58c2f6b5014(gamerTagId, toggle) end

---@param player integer
---@param toggle boolean
function N_0xd2b315b6689d537d(player, toggle) end

function N_0xd2b32be3fc1626c6() end

---@param overriddenMaterialHash Hash|string
---@param scriptOverrides boolean
function N_0xd2cc78cd3d0b50f9(overriddenMaterialHash, scriptOverrides) end

---@param vehicle integer
function N_0xd2dccd8e16e20997(vehicle) end

---@param token integer
---@return boolean
function N_0xd302e99edf0449cf(token) end

---@param ped Ped
---@param hasCone boolean
function N_0xd30c50df888d58b5(ped, hasCone) end

---@return integer
function N_0xd38c4a6d047c019d() end

---@param p0 unknown
---@return unknown
function N_0xd39b3fff8ffdd5bf(p0) end

---@param p0 boolean
function N_0xd39d13c9febf0511(p0) end

---@return boolean
function N_0xd3a10fc7fd8d98cd() end

---@param index integer
---@return integer
function N_0xd3a6a0ef48823a8c(index) end

---@return boolean
function N_0xd3d15555431ab793() end

---@param propHash Hash|string
---@return integer
function N_0xd40aac51e8e4c663(propHash) end

---@param player integer
---@return number
function N_0xd414be129bb81b32(player) end

---@return boolean
function N_0xd422fcc5f239a915() end

function N_0xd4438c0564490e63() end

function N_0xd4793dff3af2abcd() end

---@param charSlot integer
---@param amount integer
---@return boolean
function N_0xd47a2c1ba117471d(charSlot, amount) end

---@param blipSprite integer
---@return integer
function N_0xd484bf71050ca1ee(blipSprite) end

---@param gamerTagId integer
---@param component integer
---@param alpha integer
function N_0xd48fe545cd46f857(gamerTagId, component, alpha) end

---@param toggle boolean
function N_0xd4b8e3d1917bc86b(toggle) end

---@param vehicle integer
---@return boolean
function N_0xd4c4642cb7f50b5d(vehicle) end

---@return boolean
function N_0xd53acdbef24a46e8() end

---@param vehicle integer
---@return integer
function N_0xd53f3a29bce2580e(vehicle) end

function N_0xd57aaae0e2214d11() end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function N_0xd5a4b59980401588(p0, p1) end

---@param ped Ped
---@param p1 string
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 unknown
---@param p9 number
---@param p10 boolean
---@param animDict string
---@param flags integer
function N_0xd5b35bea41919acb(ped, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, animDict, flags) end

---@param ped Ped
---@param signalName string
---@param value number
function N_0xd5bb4025ae449a4e(ped, signalName, value) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function N_0xd5bb406f4e04019f(p0, p1, p2) end

---@param weapon Hash|string
---@return Hash
function N_0xd6429a016084f1a5(weapon) end

---@param p1 unknown
---@return integer
---@return unknown p0
function N_0xd66c9e72b3cc4982(p1) end

---@return unknown data
function N_0xd6781e42755531f7() end

---@param r integer
---@param g integer
---@param b integer
---@param a integer
function N_0xd68a5ff8a3a89874(r, g, b, a) end

---@param ped Ped
---@param r integer
---@param g integer
---@param b integer
function N_0xd69411aa0cebf9e9(ped, r, g, b) end

---@param p0 number
function N_0xd6ade981781fca09(p0) end

---@param timecycleModifierName string
function N_0xd7021272eb0a451e(timecycleModifierName) end

---@return boolean
function N_0xd7360051c885628b() end

---@param object integer
---@return boolean
function N_0xd76eeef746057fd6(object) end

---@param toggle boolean
function N_0xd79185689f8fd5df(toggle) end

---@param entity Entity
---@param toggle boolean
function N_0xd7b80e7c3befc396(entity, toggle) end

function N_0xd7c10c4a637992c9() end

---@return boolean
function N_0xd7c95d322ff57522() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function N_0xd7cccba28c4ecaf0(p0, p1, p2, p3, p4) end

---@param index integer
---@param heatScale number
function N_0xd7d0b00177485411(index, heatScale) end

---@param padIndex integer
---@return integer
function N_0xd7d22f5592aed8ba(padIndex) end

function N_0xd801cc02177fa3f1() end

---@param methodReturn integer
---@return boolean
function N_0xd80a80346a45d761(methodReturn) end

---@param componentHash Hash|string
---@param variantPropIndex integer
---@return Hash nameHash
---@return integer enumValue
---@return integer anchorPoint
function N_0xd81b7f27bc773e66(componentHash, variantPropIndex) end

---@param ped Ped
function N_0xd8295af639fd9cb8(ped) end

---@param ped Ped
---@param flags integer
function N_0xd86d101fcfd00a4b(ped, flags) end

---@param x number
---@param y number
---@param z number
---@param min number
---@param max number
function N_0xd8c3be3ee94caf2d(x, y, z, min, max) end

function N_0xd8e694757bcea8e9() end

function N_0xd9454b5752c857dc() end

---@param entity Entity
---@return boolean
function N_0xd95cc5d2ab15a09f(entity) end

function N_0xd972df67326f966e() end

---@param p0 unknown
---@param p1 unknown
---@param amount integer
function N_0xd99db210089617fe(p0, p1, amount) end

---@param doorHash Hash|string
---@param toggle boolean
function N_0xd9b71952f78a2640(doorHash, toggle) end

---@return boolean
function N_0xd9d2cfff49fab35f() end

---@return integer networkHandle
function N_0xda024bdbd600f44a() end

---@param garageHash Hash|string
---@param isNetwork boolean
function N_0xda05194260cdcdf9(garageHash, isNetwork) end

---@param enabled boolean
function N_0xda07819e452ffe8f(enabled) end

---@param aircraft integer
---@return number
function N_0xda62027c8bdb326e(aircraft) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@return boolean
---@return integer SphereIndex
function N_0xdab963831dbfd3f4(x, y, z, radius) end

---@param value integer
function N_0xdac073c7901f9e15(value) end

function N_0xdadfada5a20143a8() end

---@param hudColor integer
---@param displayOnFoot boolean
---@param followPlayer boolean
function N_0xdb34e8d56fc13b08(hudColor, displayOnFoot, followPlayer) end

---@param size number
---@param font integer
---@return number
function N_0xdb88a37483346780(size, font) end

---@param vehicle integer
function N_0xdba3c090e3d74690(vehicle) end

---@param p0 integer
---@param p1 integer
function N_0xdbaa5ec848ba2d46(p0, p1) end

---@param vehicle integer
function N_0xdbbc7a2432524127(vehicle) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0xdbc966a01c02bca7(p0, p1, p2) end

---@param dispatchService integer
---@param toggle boolean
function N_0xdc0f817884cdd856(dispatchService, toggle) end

---@param amount integer
---@param characterSlot integer
---@return boolean
function N_0xdc18531d7019a535(amount, characterSlot) end

---@param toggle boolean
function N_0xdc459cfa0cce245b(toggle) end

---@return boolean
function N_0xdc48473142545431() end

---@return integer
function N_0xdc54a7af8b3a14ef() end

---@param ropeId integer
---@param p1 unknown
function N_0xdc57a637a20006ed(ropeId, p1) end

---@param player integer
function N_0xdc64d2c53493ed12(player) end

---@param entity Entity
---@param toggle boolean
function N_0xdc6f8601faf2e893(entity, toggle) end

---@return integer
function N_0xdc9274a7ef6b2867() end

function N_0xdc9da9e8789f5246() end

---@param ped Ped
---@return boolean
function N_0xdcca191df9980fd7(ped) end

---@param blip integer
---@param toggle boolean
function N_0xdcfb5d4db8bf367e(blip, toggle) end

---@param blip integer
---@return boolean
function N_0xdd2238f57b977751(blip) end

---@param hash Hash|string
function N_0xdd564bdd0472c936(hash) end

---@param type integer
---@param button string
---@param text string
---@return integer
function N_0xdd6cb2cce7c2735c(type, button, text) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xdd829aa198fdc46c(p0, p1, p2, p3) end

---@param mode string
function N_0xddc635d5b3262c56(mode) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param boneIndex integer
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function N_0xdde23f30cc5a0f03(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, boneIndex, scale, xAxis, yAxis, zAxis) end

---@param scaleformHash Hash|string
---@param p1 integer
function N_0xddf24d535060f811(scaleformHash, p1) end

---@param entity Entity
---@param p1 number
---@param p2 unknown
---@param p3 boolean
function N_0xddf3cb5a0a4c0b49(entity, p1, p2, p3) end

---@param player integer
---@param toggle boolean
function N_0xddf73e2b1fec5ab4(player, toggle) end

function N_0xde81239437e8c5a8() end

---@param gamerTagId integer
---@param string string
function N_0xdea2b8283baa3944(gamerTagId, string) end

---@param toggle boolean
function N_0xdea36202fc3382df(toggle) end

---@param entity Entity
function N_0xdeadc0dedeadc0de(entity) end

---@param netHandle unknown
---@return integer
function N_0xdeb2b99a1af1a2a6(netHandle) end

---@param driver Ped
---@param modifier number
function N_0xded5af5a0ea4b297(driver, modifier) end

---@return string
function N_0xdf649c4e9afdd788() end

---@param object integer
---@param duration number
function N_0xdf6ca0330f2e737b(object, duration) end

---@param vehicle integer
---@return vector3 out1
---@return vector3 out2
function N_0xdf7e3eeb29642c38(vehicle) end

---@param doorHash Hash|string
---@return boolean
function N_0xdf97cdd4fc08fd34(doorHash) end

---@return boolean
function N_0xdfa80cb25d0a19b3() end

---@param ped Ped
---@param weaponHash Hash|string
---@param distance number
---@param ownedByPlayer boolean
---@return boolean
---@return vector3 outCoords
function N_0xdfb4138eefed7b81(ped, weaponHash, distance, ownedByPlayer) end

---@return number
function N_0xdfc8cbc606fdb0fc() end

---@param p0 unknown
---@return unknown
function N_0xdff09646e12ec386(p0) end

---@return integer
function N_0xdffa5be8381c3314() end

---@param vehicle integer
---@param toggle boolean
function N_0xdffcef48e511db48(vehicle, toggle) end

---@return number
function N_0xe0130b41d3cf4574() end

function N_0xe01903c47c7ac89e() end

---@param p0 integer
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@return unknown
function N_0xe023e8ac4ef7c117(p0, p1, p2, p3) end

function N_0xe036a705f989e049() end

---@return unknown
function N_0xe0a6138401bcb837() end

---@param colorID integer
---@return boolean
function N_0xe0d36e5d9e99cc21(colorID) end

---@param statName Hash|string
---@return integer
function N_0xe0e854f5280fb769(statName) end

---@param text string
function N_0xe124fa80a759019c(text) end

---@param entity Entity
---@param toggle boolean
function N_0xe12abe5e3a389a6c(entity, toggle) end

---@param vehicle integer
---@param toggle boolean
function N_0xe16142b94664defd(vehicle, toggle) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function N_0xe1a0450ed46a7812(p0) end

function N_0xe1c8709406f2c41c() end

---@param componentHash Hash|string
---@param forcedPropIndex integer
---@return Hash nameHash
---@return integer enumValue
---@return integer anchorPoint
function N_0xe1ca84ebf72e691d(componentHash, forcedPropIndex) end

function N_0xe1cd1e48e025e661() end

---@param player integer
---@return boolean
function N_0xe23d5873c2394c61(player) end

---@param amount integer
---@return boolean
function N_0xe260e0bb9cd995ac(amount) end

---@param ped Ped
---@param animDict string
---@param animName string
---@param p3 number
---@param p4 number
---@param p5 boolean
function N_0xe266ed23311f24d4(ped, animDict, animName, p3, p4, p5) end

---@param p0 integer
---@return boolean
function N_0xe26ccff8094d8c74(p0) end

---@param transactionId integer
---@return boolean
function N_0xe2a99a9b524befff(transactionId) end

---@param cargobob integer
---@param vehicle integer
function N_0xe301bd63e9e13cf0(cargobob, vehicle) end

---@param p0 unknown
function N_0xe30524e1871f481d(p0) end

---@param rangeStart integer
---@param rangeEnd integer
---@return integer
function N_0xe30cf56f1efa5f43(rangeStart, rangeEnd) end

---@param vehicle integer
---@param seatIndex integer
---@return boolean
function N_0xe33ffa906ce74880(vehicle, seatIndex) end

---@param toggle boolean
function N_0xe3433eadaaf7ee40(toggle) end

---@param effectName string
---@return number
function N_0xe35b38a27e8e7179(effectName) end

---@param vehicle integer
---@param x number
---@param y number
---@param z number
function N_0xe38cb9d7d39fdbcc(vehicle, x, y, z) end

function N_0xe3a3db414a373dab() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param damage integer
---@param p7 boolean
---@param weaponHash Hash|string
---@param ownerPed Ped
---@param isAudible boolean
---@param isInvisible boolean
---@param speed number
---@param entity Entity
function N_0xe3a7742e0b7a2f8b(x1, y1, z1, x2, y2, z2, damage, p7, weaponHash, ownerPed, isAudible, isInvisible, speed, entity) end

---@param flagIndex integer
---@return integer
function N_0xe3b05614dce1d014(flagIndex) end

---@param ped Ped
function N_0xe3b27e70ceab9f0c(ped) end

---@param boat integer
---@param toggle boolean
function N_0xe3ebaae484798530(boat, toggle) end

---@param vehicle integer
---@param color integer
function N_0xe41033b25d003a07(vehicle, color) end

---@param vehicle integer
---@return boolean
function N_0xe43701c36caff1a4(vehicle) end

---@param ped Ped
---@param toggle boolean
function N_0xe43a13c9e4cccbcf(ped, toggle) end

---@param sourceVehicle integer
---@param targetVehicle integer
function N_0xe44a982368a4af23(sourceVehicle, targetVehicle) end

---@param p0 boolean
---@param name string
function N_0xe45087d85f468bc2(p0, name) end

---@param ped Ped
---@param target integer
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param radius number
---@param p6 boolean
function N_0xe4723db6e736ccff(ped, target, xOffset, yOffset, zOffset, radius, p6) end

---@param vehicle integer
---@param toggle boolean
function N_0xe4e2fd323574965c(vehicle, toggle) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
function N_0xe4e53e1419d81127(tunableContext, tunableName) end

function N_0xe4e6dd5566d28c82() end

---@param ped Ped
---@param gangId integer
function N_0xe52b8e7f85d39a08(ped, gangId) end

---@param p0 unknown
---@return boolean
function N_0xe532d6811b3a4d2a(p0) end

---@return boolean
function N_0xe547e9114277098f() end

---@param tunableContext string
---@param tunableName string
---@return boolean
---@return number value
function N_0xe5608ca7bc163a5f(tunableContext, tunableName) end

function N_0xe574a662acaefbb1() end

---@return number
function N_0xe599a503b3837e1b() end

---@param vehicle integer
---@param turretIdx integer
function N_0xe615bb7a7752c76a(vehicle, turretIdx) end

---@param p0 number
function N_0xe620fd3512a04f18(p0) end

---@param areaHandle integer
---@return boolean
function N_0xe64a3ca08dfa37a9(areaHandle) end

---@param ped Ped
---@param p1 integer
function N_0xe66c690248f11150(ped, p1) end

---@param id integer
---@param p1 boolean
function N_0xe6869becdd8f2403(id, p1) end

---@param scaleformHandle integer
---@param toggle boolean
function N_0xe6a9f00d4240b519(scaleformHandle, toggle) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number
---@param flags integer
---@param entity Entity
---@param p9 integer
---@return integer
function N_0xe6ac6c45fbe83004(x1, y1, z1, x2, y2, z2, radius, flags, entity, p9) end

---@param vehicle integer
---@return integer
function N_0xe6b0e8cfc3633bf0(vehicle) end

---@param toggle boolean
function N_0xe6c0c80b8c867537(toggle) end

---@param ped Ped
function N_0xe6ca85e7259ce16b(ped) end

function N_0xe6de0561d9232a64() end

---@param vehicle integer
---@param p1 number
function N_0xe6f13851780394da(vehicle, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 boolean
---@param p3 unknown
function N_0xe70ba7b90f8390dc(p0, p1, p2, p3) end

---@return boolean
function N_0xe73364db90778ffa() end

---@return integer
function N_0xe7d267ec6ca966c3() end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function N_0xe7df4e0545dfb56e(amount, p1, p2) end

---@param p0 integer
---@param p1 unknown
---@param p2 boolean
function N_0xe7e4c198b0185900(p0, p1, p2) end

---@param type integer
---@param posX number
---@param posY number
---@param posZ number
---@param dirX number
---@param dirY number
---@param dirZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
---@param bobUpAndDown boolean
---@param faceCamera boolean
---@param p19 integer
---@param rotate boolean
---@param textureDict string
---@param textureName string
---@param drawOnEnts boolean
---@param p24 boolean
function N_0xe82728f0de75d13a(type, posX, posY, posZ, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts, p24) end

---@param cam integer
---@param p1 number
---@param p2 number
---@param p3 number
function N_0xe827b9382cfb41ba(cam, p1, p2, p3) end

---@param string string
function N_0xe83a3e3557a56640(string) end

---@param boat integer
---@param value number
function N_0xe842a9398079bd82(boat, value) end

---@param object integer
---@return integer
function N_0xe84eb93729c5f36a(object) end

---@param ped Ped
---@param loseProps boolean
---@param p2 integer
function N_0xe861d0b05c7662b8(ped, loseProps, p2) end

---@return boolean
function N_0xe8a169e666cbc541() end

---@param padIndex integer
---@param control integer
---@param amount number
---@return boolean
function N_0xe8a25867fba3b05e(padIndex, control, amount) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xe8b0b270b6e7c76e(p0, p1, p2, p3) end

---@return boolean
function N_0xe8b9c0ec9e183f35() end

---@param weaponHash Hash|string
---@param componentHashTo Hash|string
---@param componentHashFrom Hash|string
function N_0xe95c8a1875a02ca4(weaponHash, componentHashTo, componentHashFrom) end

function N_0xe9b99b6853181409() end

---@param p0 integer
---@param p1 integer
function N_0xe9ea16d6e54cdca4(p0, p1) end

---@param aircraft integer
---@return integer
function N_0xea12bd130d7569a1(aircraft) end

---@return boolean
function N_0xea14eef5b7cd2c30() end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
function N_0xea16b69d93d71a45(tunableContext, tunableName) end

---@return boolean
function N_0xea2f2061875eed90() end

---@param ped Ped
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param minZ number
---@param ropeId integer
---@param clipset string
---@param p10 unknown
function N_0xeaf66acddc794793(ped, x1, y1, z1, x2, y2, z2, minZ, ropeId, clipset, p10) end

---@param string string
---@return boolean
---@return integer token
function N_0xeb2bf817463dfa28(string) end

function N_0xeb2d525b57f42b40() end

---@param show boolean
function N_0xeb354e5376bc81a7(show) end

---@return boolean
function N_0xeb3dac2c86001e5e() end

---@param dispatchService integer
---@return integer
function N_0xeb4a0c2d56441717(dispatchService) end

function N_0xeb6891f03362fb12() end

---@param gamerTagId integer
---@return boolean
function N_0xeb709a36958abe0d(gamerTagId) end

---@return boolean
function N_0xebb376779a760aa8() end

---@param ped Ped
---@return boolean
function N_0xebd0edba5be957cf(ped) end

---@param p0 integer
---@param string string
---@param p2 boolean
function N_0xebefc2e77084f599(p0, string, p2) end

---@param vehicle integer
---@param toggle boolean
function N_0xec0c1d4922af9754(vehicle, toggle) end

---@param value integer
function N_0xec52c631a1831c03(value) end

---@param event integer
---@param amountReceived integer
---@return boolean
---@return integer networkHandle
function N_0xec5e3af5289dca81(event, amountReceived) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@return boolean
function N_0xec6935ebe0847b90(ped, x, y, z) end

---@param vehicle integer
---@return boolean
function N_0xec69adf931aae0c3(vehicle) end

function N_0xec9264727eec0f28() end

---@param amount integer
---@param p1 unknown
function N_0xeca658ce2a4e5a72(amount, p1) end

---@param player integer
---@param zoneId integer
---@param enable boolean
function N_0xecdc202b25e5cf48(player, zoneId, enable) end

---@param state boolean
function N_0xecf128344e9ff9f1(state) end

---@param p0 integer
---@param maxPlayers integer
---@return boolean
function N_0xed34c0c02c098bb7(p0, maxPlayers) end

---@param speechName string
---@param voiceName string
---@param x number
---@param y number
---@param z number
---@param speechParam string
function N_0xed640017ed337e45(speechName, voiceName, x, y, z, speechParam) end

---@param colorId integer
---@return boolean
function N_0xed6d8e27a43b8cde(colorId) end

---@param cargobob integer
---@param p1 number
function N_0xed8286f71a819baa(cargobob, p1) end

---@param helicopter integer
---@param disableExplode boolean
function N_0xedbc8405b3895cc9(helicopter, disableExplode) end

---@param amount integer
---@param p1 unknown
---@param p2 unknown
function N_0xedead9a91ec768b3(amount, p1, p2) end

---@return unknown
function N_0xedf7f927136c224b() end

---@param pedHandle Ped
---@param animalType integer
---@param speechName string
function N_0xee066c7006c49c0a(pedHandle, animalType, speechName) end

function N_0xee4c0e6dbc6f2c6f() end

---@param player integer
---@param p1 boolean
function N_0xee4ebdd2593ba844(player, p1) end

---@param gamerTagId integer
---@param toggle boolean
function N_0xee76ff7e6a0166b0(gamerTagId, toggle) end

---@param context integer
---@return integer
function N_0xee778f8c7e1142e2(context) end

---@param p0 unknown
---@param p1 boolean
---@param p2 unknown
---@param p3 boolean
function N_0xee99784e4467689c(p0, p1, p2, p3) end

---@param x number
---@param y number
---@param z number
---@return boolean
function N_0xeea5ac2eda7c33e8(x, y, z) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function N_0xeeb7e5d1feb20869(p0, p1, p2, p3) end

---@param ped Ped
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return unknown
function N_0xeeed8fafec331a70(ped, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
function N_0xeeeda5e6d7080987(p0, p1) end

---@return boolean
function N_0xef0912ddf7c4cb4b() end

---@param ped Ped
---@param component integer
---@param u number
---@param v number
---@param rotation number
---@param scale number
---@param forcedFrame integer
---@param preAge number
---@param bloodName string
function N_0xef0d582cbf2d9b0f(ped, component, u, v, rotation, scale, forcedFrame, preAge, bloodName) end

function N_0xef49cf0270307cbe() end

---@param p0 unknown
---@return boolean
---@return unknown p1
function N_0xef4ced81cebedc6d(p0) end

---@return boolean
function N_0xef7d17bc6c85264c() end

function N_0xefb55e7c25d3b3be() end

---@param vehicle integer
---@param p1 number
function N_0xefc13b1ce30d755d(vehicle, p1) end

---@param player integer
---@param distance number
function N_0xefd79fa81dfba9cb(player, distance) end

---@param p0 unknown
function N_0xefd97ff47b745b8d(p0) end

---@param ped Ped
---@param toggle boolean
function N_0xeff296097ff1e509(ped, toggle) end

---@return boolean
function N_0xeffb25453d8600f9() end

---@param p0 unknown
---@return boolean
function N_0xf0210268db0974b1(p0) end

function N_0xf03755696450470c() end

---@param vehicle integer
---@param toggle boolean
function N_0xf06a16ca55d138d8(vehicle, toggle) end

---@param setWarn boolean
function N_0xf06ebb91a81e09e3(setWarn) end

---@param modelHash Hash|string
function N_0xf086ad9354fac3a3(modelHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@param camoComponentHash Hash|string
---@return integer
function N_0xf0a60040be558f2d(ped, weaponHash, camoComponentHash) end

---@param ped Ped
function N_0xf0bc9bcd24a511d5(ped) end

---@param id integer
---@return boolean
function N_0xf0daef2f545bee25(id) end

---@param vehicle integer
---@param p1 integer
---@param p2 integer
function N_0xf0e4ba16d1db546c(vehicle, p1, p2) end

---@param garageHash Hash|string
---@param entity Entity
---@param p2 integer
---@return boolean
function N_0xf0eed5a6bc7b237a(garageHash, entity, p2) end

---@param id integer
---@param time number
---@return vector3
function N_0xf0f2103efaf8cba7(id, time) end

---@param x number
---@param y number
---@param z number
---@param typeHash Hash|string
---@return integer
function N_0xf0f77adb9f67e79d(x, y, z, typeHash) end

---@param player integer
---@param type integer
---@return boolean
function N_0xf10b44fd479d69f3(player, type) end

---@param vehicle integer
---@param toggle boolean
function N_0xf1211889df15a763(vehicle, toggle) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param textureVariation integer
---@return boolean
function N_0xf12e33034d887f66(x, y, z, radius, modelHash, textureVariation) end

---@return string
function N_0xf12e6cd06c73d69e() end

---@param blocked boolean
function N_0xf154b8d1775b2dec(blocked) end

---@param p0 boolean
function N_0xf1a6c18b35bcade6(p0) end

---@param gamerHandleCsv string
---@param platformName string
---@return boolean
---@return unknown p0
function N_0xf1ae5dcdbfca2721(gamerHandleCsv, platformName) end

---@param seed integer
function N_0xf1b84178f8674195(seed) end

---@param ped Ped
function N_0xf1c03a5352243a30(ped) end

---@param entity Entity
---@param toggle boolean
function N_0xf1ca12b18aef5298(entity, toggle) end

---@param presetName string
---@return boolean
function N_0xf1cea8a4198d8e9a(presetName) end

---@param p0 number
function N_0xf1e22dc13f5eebad(p0) end

---@param p0 unknown
function N_0xf1eea2dda9ffa69d(p0) end

---@param vehicle integer
---@param soundName string
---@param setName string
function N_0xf1f8157b8c3f171c(vehicle, soundName, setName) end

---@param statName Hash|string
---@return integer
function N_0xf2d4b2fe415aafc3(statName) end

---@param garageHash Hash|string
---@param toggle boolean
function N_0xf2e1a7133dd356a6(garageHash, toggle) end

---@return integer
function N_0xf2eac213d5ea0623() end

---@param t number
---@param x number
---@param y number
---@param z number
---@param w number
---@param x1 number
---@param y1 number
---@param z1 number
---@param w1 number
---@return number outX
---@return number outY
---@return number outZ
---@return number outW
function N_0xf2f6a2fa49278625(t, x, y, z, w, x1, y1, z1, w1) end

---@param quantity integer
---@return boolean
---@return unknown itemData
function N_0xf30980718c8ed876(quantity) end

---@param hudColorIndex integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function N_0xf314cf4f0211894e(hudColorIndex, r, g, b, a) end

---@param bStartAtPlayerPos boolean
---@param fDistanceAlongRoute number
---@param slotType integer
---@return boolean
---@return vector3 result
function N_0xf3162836c28f9da5(bStartAtPlayerPos, fDistanceAlongRoute, slotType) end

---@param opacity number
function N_0xf36199225d6d8c86(opacity) end

---@return boolean
function N_0xf3929c2379b60cce() end

---@param p0 integer
---@return string
function N_0xf3e31d16cbdcb304(p0) end

---@param character integer
---@param p1 boolean
---@return integer
function N_0xf3fbe2d50a6a8c28(character, p1) end

---@param colorId integer
---@return boolean
function N_0xf41b5d290c99a3d6(colorId) end

---@param toggle boolean
function N_0xf434a10ba01c37d0(toggle) end

---@return boolean
function N_0xf445de8da80a1792() end

---@param hudComponent integer
function N_0xf44a5456ac3f4f97(hudComponent) end

---@param bufferSize integer
---@param formattedTag string
---@return integer clanDesc
function N_0xf45352426ff3a4f0(bufferSize, formattedTag) end

---@param toggle boolean
function N_0xf46a1e03e8755980(toggle) end

---@param p0 integer
---@param hudColor integer
function N_0xf47e567b3630dd12(p0, hudColor) end

---@param vehicle integer
---@param ratio number
function N_0xf488c566413b4232(vehicle, ratio) end

---@param aircraft integer
---@param bombCount integer
function N_0xf4b2ed59deb5d774(aircraft, bombCount) end

---@param p0 string
---@param p1 number
function N_0xf4c8cf9e353afeca(p0, p1) end

---@param p0 integer
---@return integer
function N_0xf4d8e7ac2a27758c(p0) end

function N_0xf4f2c0d4ee209e20() end

---@param hash Hash|string
---@param p1 integer
function N_0xf4ff020a08bc8863(hash, p1) end

---@param amount integer
function N_0xf514621e8ea463d0(amount) end

---@param p0 unknown
---@return boolean
function N_0xf53e48461b71eecb(p0) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param planeX number
---@param planeY number
---@param planeZ number
---@param planeNormalX number
---@param planeNormalY number
---@param planeNormalZ number
---@return boolean
---@return number intersectionParameter
function N_0xf56dfb7b61be7276(x1, y1, z1, x2, y2, z2, planeX, planeY, planeZ, planeNormalX, planeNormalY, planeNormalZ) end

---@param ped Ped
---@param p1 boolean
function N_0xf5846edb26a98a24(ped, p1) end

---@param vehicle integer
---@param toggle boolean
function N_0xf584cf8529b51434(vehicle, toggle) end

---@param x number
---@param y number
---@param w number
---@param h number
function N_0xf5a2c681787e579d(x, y, w, h) end

---@return unknown p0
---@return unknown p1
---@return unknown p2
---@return unknown p3
function N_0xf5bb8dac426a52c0() end

---@param scanForSaving boolean
---@return integer
function N_0xf5bed327cea362b1(scanForSaving) end

---@return boolean
function N_0xf5f1e89a970b7796() end

---@param ped Ped
---@return boolean
---@return number speedX
---@return number speedY
function N_0xf60165e1d2c5370b(ped) end

---@param transactionId integer
function N_0xf6792800ac95350d(transactionId) end

---@param p0 unknown
function N_0xf6b170f9a02e9e87(p0) end

---@param amount integer
---@return integer
function N_0xf70efa14fe091429(amount) end

---@param minAmplitude number
function N_0xf751b16fb32abc1d(minAmplitude) end

---@param vehicle integer
---@param checkForZeroHealth boolean
---@return boolean
function N_0xf78f94d60248c737(vehicle, checkForZeroHealth) end

---@param toggle boolean
function N_0xf796359a959df65d(toggle) end

---@param ped Ped
function N_0xf79f9def0aade61a(ped) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@return boolean
function N_0xf7b2cfde5c9f700d(p0, p1, p2, p3) end

---@param tvChannel integer
---@param playlistName string
---@param restart boolean
function N_0xf7b38b8305f1fe8b(tvChannel, playlistName, restart) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return boolean
function N_0xf7b79a50b905a30d(x1, y1, x2, y2) end

---@param vehicle integer
---@param seatIndex integer
---@return boolean
function N_0xf7f203e31f96f6a1(vehicle, seatIndex) end

---@param aircraft integer
---@return integer
function N_0xf846aa63df56b804(aircraft) end

---@param scriptHash Hash|string
---@return boolean
function N_0xf86aa3c56ba31381(scriptHash) end

---@param vehicle integer
function N_0xf87d9f2301f7d206(vehicle) end

---@param ped Ped
---@param shouldBlock boolean
---@param suppressOutgoingNetworkSpeech boolean
function N_0xf8ad2eed7c47e8fe(ped, shouldBlock, suppressOutgoingNetworkSpeech) end

---@param value number
function N_0xf8bdbf3d573049a1(value) end

---@param p0 unknown
---@return boolean
function N_0xf8cc1ebe0b62e29f(p0) end

---@param toggle boolean
function N_0xf8dee0a5600cbb93(toggle) end

---@param vehicle integer
---@param position number
---@param p2 boolean
function N_0xf8ebccc96adb9fb7(vehicle, position, p2) end

---@param p0 boolean
function N_0xf98dde0a8ed09323(p0) end

---@param blip integer
---@param zoom number
function N_0xf98e4b3e56afc7b1(blip, zoom) end

---@param worldX number
---@param worldY number
---@param worldZ number
---@return boolean
---@return number screenX
---@return number screenY
function N_0xf9904d11f1acbec3(worldX, worldY, worldZ) end

---@param ped Ped
---@param noCollisionUntilClear boolean
function N_0xf9acf4a08098ea25(ped, noCollisionUntilClear) end

---@return boolean
function N_0xf9b83b77929d8863() end

---@param ped Ped
---@param target Ped
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param radius number
---@param p6 boolean
function N_0xf9b8f91aad3b953e(ped, target, xOffset, yOffset, zOffset, radius, p6) end

---@param object integer
function N_0xf9c1681347c8bd15(object) end

---@param index integer
---@param context string
---@param reason string
---@param unk boolean
function N_0xf9c812cd7c46e817(index, context, reason, unk) end

---@param cam integer
---@param height number
function N_0xf9d02130ecdd1d77(cam, height) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function N_0xf9e1ccae8ba4c281(p0, p1) end

---@param p0 unknown
function N_0xfa5b74bab8a7ef99(p0) end

---@return boolean
function N_0xfafc23aee23868db() end

---@param padIndex integer
---@param control integer
---@return boolean
function N_0xfb6c4072e9a32e92(padIndex, control) end

---@param p0 integer
---@param p1 string
---@return unknown p2
function N_0xfb6db092fbae29e6(p0, p1) end

---@param toggle boolean
function N_0xfb80ab299d2ee1bd(toggle) end

function N_0xfb8f2a6f3df08cbe() end

---@return unknown
function N_0xfbc5e768c7a77a6a() end

---@return boolean
function N_0xfbcfa2ea2e206890() end

---@param x number
---@param y number
---@param z number
---@param radius number
function N_0xfbe20329593dec9d(x, y, z, radius) end

---@param toggle boolean
function N_0xfc18db55ae19e046(toggle) end

---@param toggle boolean
function N_0xfc309e94546fcdb5(toggle) end

---@param vehicle integer
function N_0xfc40cbf7b90ca77c(vehicle) end

---@param object integer
---@return boolean
function N_0xfc481c641ebbd27d(object) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function N_0xfc4ee00a7b3bfb76(p0, p1, p2) end

---@param x number
---@param y number
---@return boolean
function N_0xfc695459d4d0e219(x, y) end

---@return boolean
function N_0xfc859e2374407556() end

function N_0xfcc75460aba29378() end

---@param index integer
---@return boolean
function N_0xfccae5b92a830878(index) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param p4 number
---@return boolean
function N_0xfcf37a457cb96dc0(ped, x, y, z, p4) end

---@param ped Ped
---@param spriteId integer
function N_0xfcfacd0db9d7a57d(ped, spriteId) end

---@param entity1 Entity
---@param entity2 Entity
---@param entityBone integer
---@param entityBone2 integer
---@param p4 boolean
---@param p5 boolean
function N_0xfd1695c5d3b05439(entity1, entity2, entityBone, entityBone2, p4, p5) end

---@return boolean
function N_0xfd8b834a8ba05048() end

function N_0xfdb423997fa30340() end

---@param xLow number
---@param yLow number
---@param xHigh number
---@param yHigh number
---@param height number
---@return integer
function N_0xfdbf4cdbc07e1706(xLow, yLow, xHigh, yHigh, height) end

function N_0xfdd85225b2dea55e() end

---@param ped Ped
function N_0xfddb234cf74073d9(ped) end

function N_0xfdec055ab549e328() end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@return unknown
function N_0xfe07ff6495d52e2a(ped, x, y, z) end

---@param vehicle integer
---@param health number
function N_0xfe205f38aaa58e5b(vehicle, health) end

---@param vehicle integer
---@param p1 integer
---@return integer
function N_0xfe26117a5841b2ff(vehicle, p1) end

---@param x number
---@param y number
---@param z number
---@param x1 number
---@param y1 number
---@param z1 number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param p9 integer
---@param flags integer
---@param entity Entity
---@param p12 integer
---@return integer
function N_0xfe466162c4401d18(x, y, z, x1, y1, z1, rotX, rotY, rotZ, p9, flags, entity, p12) end

---@param p0 unknown
function N_0xfe65afe7308e32b2(p0) end

---@param amount number
function N_0xfebfbfdfb66039de(amount) end

function N_0xfee4a5459472a9f8() end

---@param p0 unknown
function N_0xff14d6feec507bbe(p0) end

---@param ped Ped
function N_0xff287323b0e2c69a(ped) end

---@param player integer
---@param toggle boolean
function N_0xff300c7649724a0b(player, toggle) end

---@param characterType integer
---@param decorationIndex integer
---@return boolean
---@return unknown outComponent
function N_0xff56381874f82086(characterType, decorationIndex) end

---@param amount number
function N_0xff5992e1c9e65d05(amount) end

---@param flag integer
---@param entity Entity
---@param flag2 integer
---@return integer
---@return vector3 pVec1
---@return vector3 pVec2
function N_0xff6be494c7987f34(flag, entity, flag2) end

---@return boolean
function N_0xffbe02cd385356bd() end

---@return boolean
function N_0xffe1e5b792d92b34() end

---@param p0 integer
---@param p1 string
---@return boolean
function N_0xffe5c16f402d851d(p0, p1) end

---@param p0 unknown
function N_0xfffba1b1f7c0b6f4(p0) end

---@param quantity integer
---@return boolean
---@return unknown itemData
function NetGameserverBasketAddItem(quantity) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function NetGameserverBasketApplyServerData(p0) end

---@return boolean
function NetGameserverBasketDelete() end

---@return boolean
function NetGameserverBasketEnd() end

---@return boolean
function NetGameserverBasketIsFull() end

---@param categoryHash Hash|string
---@param actionHash Hash|string
---@param flags integer
---@return boolean
---@return integer transactionId
function NetGameserverBasketStart(categoryHash, actionHash, flags) end

---@param categoryHash Hash|string
---@param itemHash Hash|string
---@param actionTypeHash Hash|string
---@param value integer
---@param flags integer
---@return boolean
---@return integer transactionId
function NetGameserverBeginService(categoryHash, itemHash, actionTypeHash, value, flags) end

---@return boolean
function NetGameserverCatalogIsReady() end

---@param name string
---@return boolean
function NetGameserverCatalogItemExists(name) end

---@param hash Hash|string
---@return boolean
function NetGameserverCatalogItemExistsHash(hash) end

---@param transactionId integer
---@return boolean
function NetGameserverCheckoutStart(transactionId) end

---@param slot integer
---@param transfer boolean
---@param reason Hash|string
---@return boolean
function NetGameserverDeleteCharacterSlot(slot, transfer, reason) end

---@return integer
function NetGameserverDeleteCharacterSlotGetStatus() end

---@return boolean
function NetGameserverDeleteSetTelemetryNonceSeed() end

---@param transactionId integer
---@return boolean
function NetGameserverEndService(transactionId) end

---@param inventory boolean
---@param playerbalance boolean
---@return boolean
function NetGameserverGetBalance(inventory, playerbalance) end

---@return boolean
---@return integer state
function NetGameserverGetCatalogState() end

---@param itemHash Hash|string
---@param categoryHash Hash|string
---@param p2 boolean
---@return integer
function NetGameserverGetPrice(itemHash, categoryHash, p2) end

---@return boolean
---@return integer p0
---@return boolean p1
function NetGameserverGetTransactionManagerData() end

---@return boolean
function NetGameserverIsCatalogValid() end

---@return boolean
function NetGameserverIsSessionRefreshPending() end

---@param charSlot integer
---@return boolean
function NetGameserverIsSessionValid(charSlot) end

---@param charSlot integer
---@return boolean
function NetGameserverSessionApplyReceivedData(charSlot) end

---@param p0 integer
---@return boolean
function NetGameserverSetTelemetryNonceSeed(p0) end

---@param charSlot integer
---@return boolean
function NetGameserverStartSession(charSlot) end

---@param charSlot integer
---@param amount integer
---@return boolean
function NetGameserverTransferBankToWallet(charSlot, amount) end

---@return integer
function NetGameserverTransferCashGetStatus() end

---@return integer
function NetGameserverTransferCashGetStatus_2() end

---@return boolean
function NetGameserverTransferCashSetTelemetryNonceSeed() end

---@param charSlot integer
---@param amount integer
---@return boolean
function NetGameserverTransferWalletToBank(charSlot, amount) end

---@return boolean
function NetGameserverUseServerTransactions() end

---@param netHandle integer
---@return Entity
function NetToEnt(netHandle) end

---@param netHandle integer
---@return integer
function NetToObj(netHandle) end

---@param netHandle integer
---@return Ped
function NetToPed(netHandle) end

---@param netHandle integer
---@return integer
function NetToVeh(netHandle) end

---@return boolean
function NetworkAcceptInvite() end

---@param p0 unknown
---@return boolean
function NetworkAcceptPresenceInvite(p0) end

---@param tunableContext string
---@param tunableName string
---@return boolean
function NetworkAccessTunableBool(tunableContext, tunableName) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
function NetworkAccessTunableBoolHash(tunableContext, tunableName) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@param defaultValue boolean
---@return boolean
function NetworkAccessTunableBoolHashFailVal(tunableContext, tunableName, defaultValue) end

---@param tunableContext string
---@param tunableName string
---@return boolean
---@return number value
function NetworkAccessTunableFloat(tunableContext, tunableName) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
---@return number value
function NetworkAccessTunableFloatHash(tunableContext, tunableName) end

---@param tunableContext string
---@param tunableName string
---@return boolean
---@return integer value
function NetworkAccessTunableInt(tunableContext, tunableName) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
---@return integer value
function NetworkAccessTunableIntHash(tunableContext, tunableName) end

---@return unknown
function NetworkActionFollowInvite() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@return unknown
function NetworkAddEntityAngledArea(x1, y1, z1, x2, y2, z2, width) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@return unknown
function NetworkAddEntityArea(p0, p1, p2, p3, p4, p5) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@return unknown
function NetworkAddEntityDisplayedBoundaries(p0, p1, p2, p3, p4, p5) end

---@param entity Entity
---@param netScene integer
---@param animDict string
---@param animName string
---@param blendIn number
---@param blendOut number
---@param flag integer
function NetworkAddEntityToSynchronisedScene(entity, netScene, animDict, animName, blendIn, blendOut, flag) end

---@param p1 integer
---@return integer p0
function NetworkAddFollowers(p1) end

---@param message string
---@return boolean
---@return integer networkHandle
function NetworkAddFriend(message) end

---@param netScene integer
---@param modelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param animDict string
---@param animName string
---@param blendInSpeed number
---@param blendOutSpeed number
---@param flags integer
function NetworkAddMapEntityToSynchronisedScene(netScene, modelHash, x, y, z, animDict, animName, blendInSpeed, blendOutSpeed, flags) end

---@param ped Ped
---@param netScene integer
---@param animDict string
---@param animClip string
---@param blendInSpeed number
---@param blendOutSpeed number
---@param syncedSceneFlags integer
---@param ragdollFlags integer
---@param moverBlendInDelta number
---@param ikFlags integer
function NetworkAddPedToSynchronisedScene(ped, netScene, animDict, animClip, blendInSpeed, blendOutSpeed, syncedSceneFlags, ragdollFlags, moverBlendInDelta, ikFlags) end

---@param ped Ped
---@param netSceneID integer
---@param animDict string
---@param animClip string
---@param blendIn number
---@param blendOut number
---@param sceneFlags integer
---@param ragdollFlags integer
---@param moverBlendInDelta number
---@param ikFlags integer
function NetworkAddPedToSynchronisedSceneWithIk(ped, netSceneID, animDict, animClip, blendIn, blendOut, sceneFlags, ragdollFlags, moverBlendInDelta, ikFlags) end

---@param netScene integer
---@param animDict string
---@param animName string
function NetworkAddSynchronisedSceneCamera(netScene, animDict, animName) end

---@return boolean
function NetworkAllocateTunablesRegistrationDataMap() end

---@param entity Entity
---@param toggle boolean
function NetworkAllowLocalEntityAttachment(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function NetworkAllowRemoteAttachmentModification(entity, toggle) end

---@return boolean
---@return unknown networkHandle
function NetworkAmIBlockedByGamer() end

---@param player integer
---@return boolean
function NetworkAmIBlockedByPlayer(player) end

---@return boolean
---@return unknown networkHandle
function NetworkAmIMutedByGamer() end

---@param player integer
---@return boolean
function NetworkAmIMutedByPlayer(player) end

---@param ped Ped
---@param player integer
---@return boolean
function NetworkApplyCachedPlayerHeadBlendData(ped, player) end

---@param ped Ped
---@param p1 integer
function NetworkApplyPedScarData(ped, p1) end

---@param p0 integer
---@param p1 integer
function NetworkApplyTransitionParameter(p0, p1) end

---@param p0 integer
---@param string string
---@param p2 boolean
function NetworkApplyTransitionParameterString(p0, string, p2) end

---@param x number
---@param y number
---@param z number
function NetworkApplyVoiceProximityOverride(x, y, z) end

---@return boolean
function NetworkAreCutsceneEntities() end

---@return boolean
---@return integer netHandle1
---@return integer netHandle2
function NetworkAreHandlesTheSame() end

---@return boolean
function NetworkAreRosAvailable() end

---@return boolean
function NetworkAreSocialClubPoliciesCurrent() end

---@param p0 unknown
---@return boolean
function NetworkAreTransitionDetailsValid(p0) end

---@param netScene integer
---@param entity Entity
---@param bone integer
function NetworkAttachSynchronisedSceneToEntity(netScene, entity, bone) end

function NetworkBail() end

function NetworkBailTransition() end

function NetworkBailTransitionQuickmatch() end

---@param toggle boolean
function NetworkBlockInvites(toggle) end

---@param toggle boolean
function NetworkBlockInvites_2(toggle) end

---@param toggle boolean
function NetworkBlockJoinQueueInvites(toggle) end

---@param p0 boolean
function NetworkBlockKickedPlayers(p0) end

---@param cost integer
---@param p1 boolean
---@param p2 boolean
function NetworkBuyAirstrike(cost, p1, p2) end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@param p3 boolean
function NetworkBuyBackupGang(p0, p1, p2, p3) end

---@param amount integer
---@param victim integer
---@param p2 boolean
---@param p3 boolean
function NetworkBuyBounty(amount, victim, p2, p3) end

---@param p0 integer
---@param p1 integer
---@param p2 Hash|string
---@param p3 boolean
---@param p4 boolean
function NetworkBuyContraband(p0, p1, p2, p3, p4) end

---@param amountSpent integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkBuyFairgroundRide(amountSpent, p1, p2, p3) end

---@param cost integer
---@param p1 boolean
---@param p2 boolean
function NetworkBuyHealthcare(cost, p1, p2) end

---@param cost integer
---@param p1 boolean
---@param p2 boolean
function NetworkBuyHeliStrike(cost, p1, p2) end

---@param amount integer
---@param item Hash|string
---@param p2 unknown
---@param p3 unknown
---@param p4 boolean
---@param item_name string
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 boolean
function NetworkBuyItem(amount, item, p2, p3, p4, item_name, p6, p7, p8, p9) end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@param p3 boolean
function NetworkBuyLotteryTicket(p0, p1, p2, p3) end

---@param propertyCost integer
---@param propertyName Hash|string
---@param p2 boolean
---@param p3 boolean
function NetworkBuyProperty(propertyCost, propertyName, p2, p3) end

---@param p0 integer
---@param p1 boolean
---@param p2 boolean
function NetworkBuySmokes(p0, p1, p2) end

function NetworkCacheLocalPlayerHeadBlendData() end

---@return boolean
---@return integer loadingState
function NetworkCanAccessMultiplayer() end

---@return boolean
function NetworkCanBail() end

---@param amount integer
---@return boolean
function NetworkCanBet(amount) end

---@param cost integer
---@return boolean
function NetworkCanBuyLotteryTicket(cost) end

function NetworkCancelRespawnSearch() end

---@return boolean
---@return integer networkHandle
function NetworkCanCommunicateWithGamer() end

---@return boolean
---@return unknown networkHandle
function NetworkCanCommunicateWithGamer_2() end

---@return boolean
function NetworkCanEnterMultiplayer() end

---@return boolean
---@return unknown networkHandle
function NetworkCanGamerPlayMultiplayerWithMe() end

---@param netId integer
---@return boolean
function NetworkCanNetworkIdBeSeen(netId) end

---@return boolean
---@return unknown networkHandle
function NetworkCanPlayMultiplayerWithGamer() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
function NetworkCanReceivePlayerCash(p0, p1, p2, p3) end

---@return boolean
function NetworkCanSessionEnd() end

---@return boolean
function NetworkCanSetWaypoint() end

---@return boolean
function NetworkCanShareJobCash() end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p4 unknown
---@return boolean
function NetworkCanSpendMoney(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@param p5 unknown
---@return boolean
---@return unknown p4
function NetworkCanSpendMoney_2(p0, p1, p2, p3, p5) end

---@return boolean
---@return unknown networkHandle
function NetworkCanViewGamerUserContent() end

---@param p0 unknown
---@return boolean
function NetworkCasinoCanGamble(p0) end

---@return boolean
function NetworkCasinoCanPurchaseChipsWithPvc() end

---@return boolean
function NetworkCasinoCanPurchaseChipsWithPvc_2() end

---@param hash Hash|string
---@return boolean
function NetworkCasinoCanUseGamblingType(hash) end

---@param p0 integer
---@param p1 integer
---@return boolean
function NetworkCasinoPurchaseChips(p0, p1) end

---@param p0 integer
---@param p1 integer
---@return boolean
function NetworkCasinoSellChips(p0, p1) end

---@param p0 unknown
---@param p1 unknown
function NetworkChangeTransitionSlots(p0, p1) end

---@param toggle boolean
function NetworkChatMute(toggle) end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@return boolean
function NetworkCheckCommunicationPrivileges(p0, p1, p2) end

---@return boolean
---@return unknown p0
function NetworkCheckDataManagerForHandle() end

---@param friendDataIndex integer
---@return boolean
---@return integer networkHandle
function NetworkCheckDataManagerSucceededForHandle(friendDataIndex) end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@return boolean
function NetworkCheckUserContentPrivileges(p0, p1, p2) end

---@param animDict string
---@param animName string
---@return boolean
function NetworkClanAnimation(animDict, animName) end

---@return boolean
function NetworkClanAnyDownloadMembershipPending() end

---@return boolean
---@return integer networkHandle
function NetworkClanDownloadMembership() end

---@return boolean
---@return unknown p0
function NetworkClanDownloadMembershipPending() end

---@param txdName string
---@return boolean
---@return unknown netHandle
function NetworkClanGetEmblemTxdName(txdName) end

---@return integer
function NetworkClanGetLocalMembershipsCount() end

---@param membershipIndex integer
---@return boolean
---@return integer networkHandle
---@return integer clanMembership
function NetworkClanGetMembership(membershipIndex) end

---@return integer
---@return integer p0
function NetworkClanGetMembershipCount() end

---@param p1 integer
---@return boolean
---@return integer memberDesc
function NetworkClanGetMembershipDesc(p1) end

---@param membershipIndex integer
---@return boolean
---@return integer networkHandle
function NetworkClanGetMembershipValid(membershipIndex) end

---@return integer
function NetworkClanGetNumMembershipDesc() end

---@param bufferSize integer
---@param formattedTag string
---@return integer clanDesc
function NetworkClanGetUiFormattedTag(bufferSize, formattedTag) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function NetworkClanIsEmblemReady(p0) end

---@param bufferSize integer
---@return boolean
---@return integer clanDesc
function NetworkClanIsRockstarClan(bufferSize) end

---@param clanDesc integer
---@return boolean
function NetworkClanJoin(clanDesc) end

---@param bufferSize integer
---@return boolean
---@return integer clanDesc
---@return integer networkHandle
function NetworkClanPlayerGetDesc(bufferSize) end

---@return boolean
---@return integer networkHandle
function NetworkClanPlayerIsActive() end

---@param p0 unknown
function NetworkClanReleaseEmblem(p0) end

---@return boolean
---@return integer p0
function NetworkClanRemoteMembershipsAreInCache() end

---@param p0 unknown
---@return boolean
function NetworkClanRequestEmblem(p0) end

---@return boolean
function NetworkClanServiceIsValid() end

---@param characterSlot integer
function NetworkClearCharacterWallet(characterSlot) end

function NetworkClearClockTimeOverride() end

function NetworkClearFollowers() end

---@return unknown
function NetworkClearFollowInvite() end

function NetworkClearFoundGamers() end

function NetworkClearGetGamerStatus() end

function NetworkClearGroupActivity() end

function NetworkClearPropertyId() end

function NetworkClearTransitionCreatorHandle() end

function NetworkClearVoiceChannel() end

function NetworkClearVoiceProximityOverride() end

function NetworkCloseTransitionMatchmaking() end

---@param entity Entity
---@param toggle boolean
function NetworkConcealEntity(entity, toggle) end

---@param player integer
---@param toggle boolean
---@param bAllowDamagingWhileConcealed boolean
function NetworkConcealPlayer(player, toggle, bAllowDamagingWhileConcealed) end

---@param netSceneId integer
---@return integer
function NetworkConvertSynchronisedSceneToSynchronizedScene(netSceneId) end

---@param ped Ped
---@param player integer
---@return boolean
function NetworkCopyPedBlendData(ped, player) end

---@param x number
---@param y number
---@param z number
---@param xRot number
---@param yRot number
---@param zRot number
---@param rotationOrder integer
---@param holdLastFrame boolean
---@param looped boolean
---@param phaseToStopScene number
---@param phaseToStartScene number
---@param animSpeed number
---@return integer
function NetworkCreateSynchronisedScene(x, y, z, xRot, yRot, zRot, rotationOrder, holdLastFrame, looped, phaseToStopScene, phaseToStartScene, animSpeed) end

---@param amount integer
---@param p1 string
---@param p2 string
---@param p3 boolean
---@param p4 boolean
---@param p5 boolean
function NetworkDeductCash(amount, p1, p2, p3, p4, p5) end

---@param characterSlot integer
---@param p1 boolean
---@param p2 boolean
function NetworkDeleteCharacter(characterSlot, p1, p2) end

---@return boolean
function NetworkDidFindGamersSucceed() end

---@return boolean
function NetworkDidGetGamerStatusSucceed() end

---@param player integer
---@param toggle boolean
function NetworkDisableInvincibleFlashing(player, toggle) end

---@param toggle boolean
function NetworkDisableLeaveRemotePedBehind(toggle) end

---@param netID integer
function NetworkDisableProximityMigration(netID) end

---@param p1 unknown
---@return integer
---@return unknown p0
function NetworkDisplaynamesFromHandlesStart(p1) end

---@param netId integer
---@return boolean
function NetworkDoesEntityExistWithNetworkId(netId) end

---@param netId integer
---@return boolean
function NetworkDoesNetworkIdExist(netId) end

---@param tunableContext string
---@param tunableName string
---@return boolean
function NetworkDoesTunableExist(tunableContext, tunableName) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@return boolean
function NetworkDoesTunableExistHash(tunableContext, tunableName) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
function NetworkDoTransitionQuickmatch(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
function NetworkDoTransitionQuickmatchAsync(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p5 unknown
---@return boolean
---@return unknown p4
function NetworkDoTransitionQuickmatchWithGroup(p0, p1, p2, p3, p5) end

---@param p1 unknown
---@param p2 boolean
---@param players integer
---@param p4 boolean
---@return boolean
---@return unknown p0
function NetworkDoTransitionToFreemode(p1, p2, players, p4) end

---@param p0 boolean
---@param maxPlayers integer
---@return boolean
function NetworkDoTransitionToGame(p0, maxPlayers) end

---@param players integer
---@param p3 boolean
---@param p4 boolean
---@param p5 boolean
---@return boolean
---@return unknown p0
---@return unknown p1
function NetworkDoTransitionToNewFreemode(players, p3, p4, p5) end

---@param p0 boolean
---@param maxPlayers integer
---@param p2 boolean
---@return boolean
function NetworkDoTransitionToNewGame(p0, maxPlayers, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkEarnBoss(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkEarnBossAgency(p0, p1, p2, p3) end

---@param p0 unknown
function NetworkEarnBountyHunterReward(p0) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
function NetworkEarnCasinoHeist(p0, p1, p2, p3, p4, p5, p6) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkEarnCasinoHeistBonus(p0, p1, p2, p3, p4) end

---@param amount integer
---@param p1 unknown
function NetworkEarnCollectableCompletedCollection(amount, p1) end

---@param p0 unknown
function NetworkEarnFmbbWageBonus(p0) end

---@param p0 unknown
---@param p1 unknown
function NetworkEarnFromAiTargetKill(p0, p1) end

---@param p0 integer
---@param p1 string
---@return unknown p2
function NetworkEarnFromAmbientJob(p0, p1) end

---@param amount integer
---@param p1 unknown
function NetworkEarnFromArenaCareerProgression(amount, p1) end

---@param amount integer
---@param p1 unknown
function NetworkEarnFromArenaSkillLevelProgression(amount, p1) end

---@param amount integer
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkEarnFromArenaWar(amount, p1, p2, p3) end

---@param amount integer
function NetworkEarnFromArmourTruck(amount) end

---@param amount integer
function NetworkEarnFromAssassinateTargetKilled(amount) end

---@param amount integer
function NetworkEarnFromAssassinateTargetKilled_2(amount) end

---@param p0 unknown
---@param p1 unknown
function NetworkEarnFromAutoshopBusiness(p0, p1) end

---@param p0 unknown
function NetworkEarnFromAutoshopIncome(p0) end

---@param amount integer
function NetworkEarnFromBbEventBonus(amount) end

---@param amount integer
function NetworkEarnFromBbEventCargo(amount) end

---@param amount integer
---@param heistHash string
function NetworkEarnFromBendJob(amount, heistHash) end

---@param amount integer
---@param p1 string
function NetworkEarnFromBetting(amount, p1) end

---@param p0 unknown
function NetworkEarnFromBikerIncome(p0) end

---@param p0 unknown
---@param p1 unknown
function NetworkEarnFromBikeShopBusiness(p0, p1) end

---@param amount integer
---@param p3 unknown
---@return integer networkHandle
---@return unknown p2
function NetworkEarnFromBounty(amount, p3) end

---@param p0 unknown
function NetworkEarnFromBusinessBattle(p0) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkEarnFromBusinessHubSell(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkEarnFromBusinessHubSource(p0, p1, p2, p3) end

---@param amount integer
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkEarnFromBusinessProduct(amount, p1, p2, p3) end

---@param p0 unknown
function NetworkEarnFromCarclubMembership(p0) end

---@param amount integer
function NetworkEarnFromCashingOut(amount) end

---@param amount integer
---@param hash Hash|string
function NetworkEarnFromCasinoAward(amount, hash) end

---@param amount integer
function NetworkEarnFromCasinoMissionParticipation(amount) end

---@param amount integer
function NetworkEarnFromCasinoMissionReward(amount) end

---@param amount integer
function NetworkEarnFromCasinoStoryMissionReward(amount) end

---@param p0 unknown
---@param p2 boolean
---@return unknown p1
function NetworkEarnFromChallengeWin(p0, p2) end

---@param p0 unknown
function NetworkEarnFromClubManagementParticipation(p0) end

---@param amount integer
function NetworkEarnFromCollectablesActionFigures(amount) end

---@param amount integer
---@param p1 unknown
function NetworkEarnFromCollectionItem(amount, p1) end

---@param amount integer
function NetworkEarnFromCompleteCollection(amount) end

---@param amount integer
---@param p1 unknown
function NetworkEarnFromContraband(amount, p1) end

---@param amount integer
function NetworkEarnFromCrateDrop(amount) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkEarnFromCriminalMastermindBonus(p0, p1, p2) end

---@param p0 integer
---@param p1 string
---@param p2 integer
function NetworkEarnFromDailyObjective(p0, p1, p2) end

---@param amount integer
function NetworkEarnFromDailyObjectiveEvent(amount) end

---@param p0 integer
---@param p1 string
---@param p2 integer
function NetworkEarnFromDailyObjectives(p0, p1, p2) end

---@param amount integer
---@param p1 unknown
function NetworkEarnFromDarChallenge(amount, p1) end

---@param p0 unknown
function NetworkEarnFromDestroyingContraband(p0) end

---@param amount integer
---@param vehicleHash Hash|string
function NetworkEarnFromDoomsdayFinaleBonus(amount, vehicleHash) end

---@param p0 unknown
function NetworkEarnFromFmbbBossWork(p0) end

---@param p0 unknown
function NetworkEarnFromFmbbPhonecallMission(p0) end

---@param amount integer
---@param unk string
---@param p2 unknown
function NetworkEarnFromGangopsAwards(amount, unk, p2) end

---@param amount integer
---@param unk string
---@param actIndex integer
function NetworkEarnFromGangopsElite(amount, unk, actIndex) end

---@param amount integer
---@param unk string
function NetworkEarnFromGangopsJobsFinale(amount, unk) end

---@param amount integer
function NetworkEarnFromGangopsJobsPrepParticipation(amount) end

---@param amount integer
---@param unk string
function NetworkEarnFromGangopsJobsSetup(amount, unk) end

---@param amount integer
---@param p1 integer
function NetworkEarnFromGangopsWages(amount, p1) end

---@param amount integer
---@param p1 integer
function NetworkEarnFromGangopsWagesBonus(amount, p1) end

---@param amount integer
function NetworkEarnFromGangPickup(amount) end

---@param p0 unknown
---@param amount integer
---@param p2 unknown
---@param p3 unknown
function NetworkEarnFromHackerTruckMission(p0, amount, p2, p3) end

---@param amount integer
function NetworkEarnFromHoldups(amount) end

---@param amount integer
---@param modelHash Hash|string
function NetworkEarnFromImportExport(amount, modelHash) end

---@param amount integer
---@param p1 string
function NetworkEarnFromJob(amount, p1) end

---@param p0 unknown
---@return unknown p1
---@return unknown p2
function NetworkEarnFromJobBonus(p0) end

---@param amount integer
---@param p1 string
function NetworkEarnFromJobX2(amount, p1) end

---@param amount integer
---@param heistHash string
function NetworkEarnFromMissionH(amount, heistHash) end

---@param amount integer
function NetworkEarnFromNotBadsport(amount) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
function NetworkEarnFromPersonalVehicle(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@param amount integer
function NetworkEarnFromPickup(amount) end

---@param amount integer
---@param p1 string
function NetworkEarnFromPremiumJob(amount, p1) end

---@param amount integer
---@param propertyName Hash|string
function NetworkEarnFromProperty(amount, propertyName) end

---@param amount integer
function NetworkEarnFromRcTimeTrial(amount) end

---@param amount integer
---@param p1 unknown
function NetworkEarnFromRdrBonus(amount, p1) end

---@param amount integer
function NetworkEarnFromRockstar(amount) end

---@param amount integer
---@param baseNameHash Hash|string
function NetworkEarnFromSellBase(amount, baseNameHash) end

---@param amount integer
---@param bunkerHash Hash|string
function NetworkEarnFromSellBunker(amount, bunkerHash) end

---@param amount integer
function NetworkEarnFromSellingVehicle(amount) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkEarnFromSightseeing(p0, p1, p2, p3) end

---@param amount integer
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkEarnFromSmuggling(amount, p1, p2, p3) end

---@param amount integer
function NetworkEarnFromSpinTheWheelCash(amount) end

---@param amount integer
---@param p1 integer
function NetworkEarnFromTargetRefund(amount, p1) end

---@param amount integer
function NetworkEarnFromTimeTrialWin(amount) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkEarnFromTunerAward(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkEarnFromTunerFinale(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
function NetworkEarnFromUpgradeAutoshopLocation(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
function NetworkEarnFromVehicle(p0, p1, p2, p3, p4, p5, p6, p7) end

---@param p0 unknown
---@param p1 unknown
function NetworkEarnFromVehicleAutoshop(p0, p1) end

---@param p0 unknown
function NetworkEarnFromVehicleAutoshopBonus(p0) end

---@param amount integer
---@param p1 unknown
---@param p2 unknown
function NetworkEarnFromVehicleExport(amount, p1, p2) end

---@param amount integer
function NetworkEarnFromWagePayment(amount) end

---@param amount integer
function NetworkEarnFromWagePaymentBonus(amount) end

function NetworkEarnFromWarehouse() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkEarnGoon(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function NetworkEarnIslandHeist(p0, p1, p2, p3, p4, p5) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkEarnJobBonusFirstTimeBonus(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkEarnJobBonusHeistAward(p0, p1, p2) end

---@return boolean
function NetworkEnableMotionDrugged() end

function NetworkEndTutorialSession() end

---@param areaHandle integer
---@return boolean
function NetworkEntityAreaDoesExist(areaHandle) end

---@param areaHandle integer
---@return boolean
function NetworkEntityAreaIsOccupied(areaHandle) end

---@param heli integer
---@param isAudible boolean
---@param isInvisible boolean
---@param netScriptEntityId integer
function NetworkExplodeHeli(heli, isAudible, isInvisible, netScriptEntityId) end

---@param vehicle integer
---@param isAudible boolean
---@param isInvisible boolean
---@param p3 boolean
function NetworkExplodeVehicle(vehicle, isAudible, isInvisible, p3) end

---@param entity Entity
---@param bNetwork boolean
function NetworkFadeInEntity(entity, bNetwork) end

---@param entity Entity
---@param normal boolean
---@param slow boolean
function NetworkFadeOutEntity(entity, normal, slow) end

---@param p0 unknown
---@return boolean
function NetworkFindGamersInCrew(p0) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@return boolean
function NetworkFindMatchedGamers(p0, p1, p2, p3) end

function NetworkFinishBroadcastingData() end

---@param sceneId integer
function NetworkForceLocalUseOfSyncedSceneCamera(sceneId) end

---@return boolean
---@return unknown networkHandle
function NetworkGamerHasHeadset() end

---@return boolean
function NetworkGamertagFromHandlePending() end

---@return boolean
---@return integer networkHandle
function NetworkGamertagFromHandleStart() end

---@return boolean
function NetworkGamertagFromHandleSucceeded() end

---@param p0 boolean
---@return integer
function NetworkGetActivityPlayerNum(p0) end

---@return integer
function NetworkGetAgeGroup() end

---@param player integer
---@return number
function NetworkGetAverageLatencyForPlayer(player) end

---@param player integer
---@return number
function NetworkGetAverageLatencyForPlayer_2(player) end

---@param player integer
---@return number
function NetworkGetAveragePacketLossForPlayer(player) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function NetworkGetBackgroundLoadingRecipients(p0, p1) end

---@param privilege integer
---@return boolean
---@return integer banType
---@return vector3 timeData
function NetworkGetBanData(privilege) end

---@return string
function NetworkGetBankBalanceString() end

---@param contentHash Hash|string
---@return integer
function NetworkGetContentModifierListId(contentHash) end

---@return boolean
---@return unknown p0
function NetworkGetCurrentlySelectedGamerHandleFromInviteMenu() end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return Hash weaponHash
function NetworkGetDesroyerOfEntity(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return Hash weaponHash
function NetworkGetDestroyerOfEntity(p0, p1) end

---@param netId integer
---@return integer
---@return Hash weaponHash
function NetworkGetDestroyerOfNetworkId(netId) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return integer
function NetworkGetDisplaynamesFromHandles(p0, p1, p2) end

---@param netId integer
---@return Entity
function NetworkGetEntityFromNetworkId(netId) end

---@param entity Entity
---@return boolean
function NetworkGetEntityIsLocal(entity) end

---@param entity Entity
---@return boolean
function NetworkGetEntityIsNetworked(entity) end

---@param player integer
---@return Entity
---@return Hash weaponHash
function NetworkGetEntityKillerOfPlayer(player) end

---@param entity Entity
---@return integer
function NetworkGetEntityNetScriptId(entity) end

---@return integer
function NetworkGetEvcBalance() end

---@param p1 unknown
---@return boolean
---@return unknown p0
function NetworkGetFoundGamer(p1) end

---@return integer
function NetworkGetFriendCount() end

---@param friendIndex integer
---@return string
function NetworkGetFriendName(friendIndex) end

---@param friendIndex integer
---@return string
function NetworkGetFriendNameFromIndex(friendIndex) end

---@return boolean
---@return unknown p0
function NetworkGetGamerStatus() end

---@return boolean
function NetworkGetGamerStatusFromQueue() end

---@param p1 unknown
---@return boolean
---@return unknown p0
function NetworkGetGamerStatusResult(p1) end

---@return string
---@return integer networkHandle
function NetworkGetGamertagFromHandle() end

---@return integer hours
---@return integer minutes
---@return integer seconds
function NetworkGetGlobalMultiplayerClock() end

---@param scriptName string
---@param p1 integer
---@param p2 integer
---@return integer
function NetworkGetHostOfScript(scriptName, p1, p2) end

---@return integer
function NetworkGetHostOfThisScript() end

---@return integer
function NetworkGetInstanceIdOfThisScript() end

---@return boolean
function NetworkGetIsHighEarner() end

---@param entity Entity
---@return vector3
function NetworkGetLastVelocityReceived(entity) end

---@param bufferSize integer
---@return integer networkHandle
function NetworkGetLocalHandle(bufferSize) end

---@param netSceneId integer
---@return integer
function NetworkGetLocalSceneFromNetworkId(netSceneId) end

---@return integer
function NetworkGetMaxFriends() end

---@return integer
function NetworkGetMaxNumParticipants() end

---@param entity Entity
---@return integer
function NetworkGetNetworkIdFromEntity(entity) end

---@return integer
function NetworkGetNumBodyTrackers() end

---@return integer
function NetworkGetNumConnectedPlayers() end

---@return integer
function NetworkGetNumFoundGamers() end

---@return integer
function NetworkGetNumParticipants() end

---@return integer
function NetworkGetNumParticipantsHost() end

---@return integer
function NetworkGetNumPresenceInvites() end

---@param p1 unknown
---@param p2 unknown
---@return integer
---@return unknown p0
function NetworkGetNumScriptParticipants(p1, p2) end

---@param player integer
---@return integer
function NetworkGetNumUnackedForPlayer(player) end

---@param player integer
---@return integer
function NetworkGetOldestResendCountForPlayer(player) end

---@param index integer
---@return integer
function NetworkGetParticipantIndex(index) end

---@param dataSize integer
---@return integer
---@return unknown data
function NetworkGetPlatformPartyMembers(dataSize) end

---@return integer
function NetworkGetPlatformPartyUnk() end

---@param player integer
---@return vector3
function NetworkGetPlayerCoords(player) end

---@param txdName string
---@return boolean
---@return unknown netHandle
function NetworkGetPlayerCrewEmblemTxdName(txdName) end

---@return integer
---@return integer networkHandle
function NetworkGetPlayerFromGamerHandle() end

---@param player integer
---@return integer
function NetworkGetPlayerIndex(player) end

---@param ped Ped
---@return integer
function NetworkGetPlayerIndexFromPed(ped) end

---@param player integer
---@return number
function NetworkGetPlayerLoudness(player) end

---@param player integer
---@return boolean
function NetworkGetPlayerOwnsWaypoint(player) end

---@param player integer
---@return integer
function NetworkGetPlayerTutorialSessionInstance(player) end

---@return unknown
function NetworkGetPositionHashOfThisScript() end

---@param p0 unknown
---@return string
function NetworkGetPresenceInviteContentId(p0) end

---@param p0 unknown
---@return boolean
function NetworkGetPresenceInviteFromAdmin(p0) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function NetworkGetPresenceInviteHandle(p0) end

---@param p0 unknown
---@return unknown
function NetworkGetPresenceInviteId(p0) end

---@param inviteIndex integer
---@return string
function NetworkGetPresenceInviteInviter(inviteIndex) end

---@param p0 unknown
---@return boolean
function NetworkGetPresenceInviteIsTournament(p0) end

---@param p0 unknown
---@return unknown
function NetworkGetPresenceInvitePlaylistCurrent(p0) end

---@param p0 unknown
---@return unknown
function NetworkGetPresenceInvitePlaylistLength(p0) end

---@param inviteIndex integer
---@return Hash
function NetworkGetPresenceInviteSessionId(inviteIndex) end

function NetworkGetPrimaryClanDataCancel() end

---@return unknown
function NetworkGetPrimaryClanDataClear() end

---@return boolean
---@return unknown p0
---@return unknown p1
function NetworkGetPrimaryClanDataNew() end

---@return unknown
function NetworkGetPrimaryClanDataPending() end

---@param p1 unknown
---@return boolean
---@return unknown p0
function NetworkGetPrimaryClanDataStart(p1) end

---@return unknown
function NetworkGetPrimaryClanDataSuccess() end

---@return integer
function NetworkGetPvcBalance() end

---@return integer
function NetworkGetPvcTransferBalance() end

---@return integer
function NetworkGetRandomInt() end

---@param rangeStart integer
---@param rangeEnd integer
---@return integer
function NetworkGetRandomIntInRange(rangeStart, rangeEnd) end

---@param rangeStart integer
---@param rangeEnd integer
---@return integer
function NetworkGetRandomIntRanged(rangeStart, rangeEnd) end

---@return integer
function NetworkGetRemainingTransferBalance() end

---@return integer
function NetworkGetRemainingVcDailyTransfers() end

---@return integer
function NetworkGetRemainingVcDailyTransfers_2() end

---@param randomInt integer
---@return vector3 coordinates
---@return number heading
function NetworkGetRespawnResult(randomInt) end

---@param p0 unknown
---@return unknown
function NetworkGetRespawnResultFlags(p0) end

---@return boolean
function NetworkGetRosPrivilege_10() end

---@return boolean
function NetworkGetRosPrivilege_24() end

---@return boolean
function NetworkGetRosPrivilege_25() end

---@return boolean
function NetworkGetRosPrivilege_3() end

---@return boolean
function NetworkGetRosPrivilege_4() end

---@return boolean
function NetworkGetRosPrivilege_9() end

---@return integer
function NetworkGetScriptStatus() end

---@return integer hours
---@return integer minutes
---@return integer seconds
function NetworkGetServerTime() end

---@return string
function NetworkGetStringBankBalance() end

---@return string
function NetworkGetStringBankWalletBalance() end

---@param characterSlot integer
---@return string
function NetworkGetStringWalletBalance(characterSlot) end

---@return number
function NetworkGetTalkerProximity() end

---@return integer
function NetworkGetTargetingMode() end

---@return boolean
function NetworkGetThisScriptIsNetworkScript() end

---@return integer
function NetworkGetTimeoutTime() end

---@return integer
function NetworkGetTotalNumPlayers() end

---@return boolean
---@return integer networkHandle
function NetworkGetTransitionHost() end

---@param dataCount integer
---@return integer
---@return unknown data
function NetworkGetTransitionMembers(dataCount) end

---@return integer
function NetworkGetTunableCloudCrc() end

---@return integer
function NetworkGetTunablesVersion() end

---@param player integer
---@return integer
function NetworkGetUnreliableResendCountForPlayer(player) end

---@return integer
function NetworkGetVcBalance() end

---@return integer
function NetworkGetVcBankBalance() end

---@param amount integer
---@return boolean
function NetworkGetVcBankBalanceIsNotLessThan(amount) end

---@param amount integer
---@param characterSlot integer
---@return boolean
function NetworkGetVcBankWalletBalanceIsNotLessThan(amount, characterSlot) end

---@param characterSlot integer
---@return integer
function NetworkGetVcWalletBalance(characterSlot) end

---@param amount integer
---@param characterSlot integer
---@return boolean
function NetworkGetVcWalletBalanceIsNotLessThan(amount, characterSlot) end

---@param amount integer
---@return integer networkHandle
function NetworkGivePlayerJobshareCash(amount) end

---@param friendIndex integer
---@param bufferSize integer
---@return integer networkHandle
function NetworkHandleFromFriend(friendIndex, bufferSize) end

---@param memberId string
---@param bufferSize integer
---@return integer networkHandle
function NetworkHandleFromMemberId(memberId, bufferSize) end

---@param player integer
---@param bufferSize integer
---@return integer networkHandle
function NetworkHandleFromPlayer(player, bufferSize) end

---@param userId string
---@param bufferSize integer
---@return integer networkHandle
function NetworkHandleFromUserId(userId, bufferSize) end

---@return boolean
function NetworkHasAgeRestrictedProfile() end

---@param player integer
---@return boolean
function NetworkHasCachedPlayerHeadBlendData(player) end

---@param doorHash Hash|string
---@return boolean
function NetworkHasControlOfDoor(doorHash) end

---@param entity Entity
---@return boolean
function NetworkHasControlOfEntity(entity) end

---@param netId integer
---@return boolean
function NetworkHasControlOfNetworkId(netId) end

---@param doorHash Hash|string
---@return boolean
function NetworkHasControlOfPavementStats(doorHash) end

---@param pickup integer
---@return boolean
function NetworkHasControlOfPickup(pickup) end

---@param entity Entity
---@return boolean
function NetworkHasEntityBeenRegisteredWithThisThread(entity) end

---@return boolean
function NetworkHasFollowInvite() end

---@return boolean
function NetworkHasGameBeenAltered() end

---@return boolean
function NetworkHasHeadset() end

---@return Hash
---@return integer networkHandle
function NetworkHashFromGamerHandle() end

---@param player integer
---@return Hash
function NetworkHashFromPlayerHandle(player) end

---@return boolean
---@return integer networkHandle
function NetworkHasInviteBeenAcked() end

---@return boolean
---@return unknown p0
function NetworkHasInvitedGamer() end

---@return boolean
---@return unknown p0
function NetworkHasInvitedGamerToTransition() end

---@return boolean
function NetworkHasPendingInvite() end

---@return boolean
function NetworkHasPlayerBeenBanned() end

---@param player integer
---@return boolean
function NetworkHasPlayerStartedTransition(player) end

---@return boolean
function NetworkHasReceivedHostBroadcastData() end

---@param index integer
---@return boolean
function NetworkHasRosPrivilege(index) end

---@param privilege integer
---@return boolean
---@return integer banType
---@return vector3 timeData
function NetworkHasRosPrivilegeEndDate(privilege) end

---@return boolean
function NetworkHasSocialClubAccount() end

---@return boolean
function NetworkHasSocialNetworkingSharingPriv() end

---@return boolean
---@return integer networkHandle
function NetworkHasTransitionInviteBeenAcked() end

---@return boolean
function NetworkHasValidRosCredentials() end

---@return boolean
---@return unknown networkHandle
function NetworkHasViewGamerUserContentResult() end

---@param p0 integer
---@param player integer
---@return boolean
function NetworkHaveCommunicationPrivileges(p0, player) end

---@return boolean
function NetworkHaveJustUploadLater() end

---@return boolean
function NetworkHaveOnlinePrivilege_2() end

---@return boolean
function NetworkHaveOnlinePrivileges() end

---@return boolean
function NetworkHaveRosBannedPriv() end

---@return boolean
function NetworkHaveRosCreateTicketPriv() end

---@return boolean
function NetworkHaveRosLeaderboardWritePriv() end

---@return boolean
function NetworkHaveRosMultiplayerPriv() end

---@return boolean
function NetworkHaveRosSocialClubPriv() end

---@return boolean
function NetworkHaveSocialClubPrivilege() end

---@param p0 integer
---@return boolean
function NetworkHaveUserContentPrivileges(p0) end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param p3 integer
---@param p4 unknown
---@param p5 boolean
---@param p6 boolean
---@param p7 integer
---@param p8 unknown
---@param p9 integer
---@return boolean
function NetworkHostTransition(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

---@param wallet integer
---@param bank integer
function NetworkInitializeCash(wallet, bank) end

---@param p1 unknown
---@return boolean
---@return unknown p0
---@return unknown p2
---@return unknown p3
function NetworkInviteGamers(p1) end

---@param p1 unknown
---@return boolean
---@return unknown p0
function NetworkInviteGamersToTransition(p1) end

---@return boolean
function NetworkIsActivitySession() end

---@return boolean
function NetworkIsActivitySpectator() end

---@return boolean
---@return integer networkHandle
function NetworkIsActivitySpectatorFromHandle() end

---@return unknown
function NetworkIsAddingFriend() end

---@return boolean
function NetworkIsCableConnected() end

---@return boolean
---@return integer networkHandle
function NetworkIsChattingInPlatformParty() end

---@return boolean
function NetworkIsClanMembershipFinishedDownloading() end

---@return boolean
function NetworkIsClockTimeOverridden() end

---@return boolean
function NetworkIsCloudAvailable() end

---@return boolean
function NetworkIsCloudBackgroundScriptRequestPending() end

---@return boolean
function NetworkIsCloudBackgroundScriptsRequestPending() end

---@param player integer
---@return boolean
function NetworkIsConnectionEndpointRelayServer(player) end

---@param doorHash Hash|string
---@return boolean
function NetworkIsDoorNetworked(doorHash) end

---@param entity Entity
---@return boolean
function NetworkIsEntityConcealed(entity) end

---@param entity Entity
---@return boolean
function NetworkIsEntityFading(entity) end

---@return boolean
function NetworkIsFindingGamers() end

---@return boolean
---@return integer networkHandle
function NetworkIsFriend() end

---@return boolean
---@return integer networkHandle
function NetworkIsFriendHandleOnline() end

---@param friendIndex integer
---@return boolean
function NetworkIsFriendIndexOnline(friendIndex) end

---@param friendName string
---@return boolean
function NetworkIsFriendInMultiplayer(friendName) end

---@param friendName string
---@return boolean
function NetworkIsFriendInSameTitle(friendName) end

---@param name string
---@return boolean
function NetworkIsFriendOnline(name) end

---@return boolean
---@return integer networkHandle
function NetworkIsFriendOnline_2() end

---@return boolean
function NetworkIsGameInProgress() end

---@return boolean
---@return unknown networkHandle
function NetworkIsGamerBlockedByMe() end

---@return boolean
---@return integer networkHandle
function NetworkIsGamerInMySession() end

---@return boolean
---@return integer networkHandle
function NetworkIsGamerMutedByMe() end

---@return boolean
---@return integer networkHandle
function NetworkIsGamerTalking() end

---@return boolean
function NetworkIsGettingGamerStatus() end

---@param bufferSize integer
---@return boolean
---@return integer networkHandle
function NetworkIsHandleValid(bufferSize) end

---@return boolean
function NetworkIsHost() end

---@return boolean
function NetworkIsHostOfThisScript() end

---@return boolean
---@return integer networkHandle
function NetworkIsInactiveProfile() end

---@return boolean
function NetworkIsInMpCutscene() end

---@return boolean
function NetworkIsInParty() end

---@return boolean
function NetworkIsInPlatformParty() end

---@return boolean
function NetworkIsInPlatformPartyChat() end

---@return boolean
function NetworkIsInSession() end

---@return boolean
function NetworkIsInSpectatorMode() end

---@return boolean
function NetworkIsInTransition() end

---@return boolean
function NetworkIsInTutorialSession() end

---@return boolean
function NetworkIsLocalPlayerInvincible() end

---@return boolean
function NetworkIsLocalTalking() end

---@return boolean
function NetworkIsMultiplayerDisabled() end

---@param netId integer
---@return boolean
function NetworkIsNetworkIdAClone(netId) end

---@return boolean
function NetworkIsOfflineInvitePending() end

---@param p0 integer
---@return boolean
function NetworkIsParticipantActive(p0) end

---@return boolean
---@return integer networkHandle
function NetworkIsPartyMember() end

---@param p0 unknown
---@return unknown
function NetworkIsPendingFriend(p0) end

---@param player integer
---@return boolean
function NetworkIsPlayerActive(player) end

function NetworkIsPlayerAnimationDrawingSynchronized() end

---@param player integer
---@return boolean
function NetworkIsPlayerAParticipant(player) end

---@param player1 integer
---@param script string
---@param player2 integer
---@return boolean
function NetworkIsPlayerAParticipantOnScript(player1, script, player2) end

---@param player integer
---@return boolean
function NetworkIsPlayerBlockedByMe(player) end

---@param player integer
---@return boolean
function NetworkIsPlayerConcealed(player) end

---@param player integer
---@return boolean
function NetworkIsPlayerConnected(player) end

---@param player integer
---@param index integer
---@return boolean
function NetworkIsPlayerEqualToIndex(player, index) end

---@param player integer
---@return boolean
function NetworkIsPlayerFading(player) end

---@param player integer
---@return boolean
function NetworkIsPlayerInMpCutscene(player) end

---@param player integer
---@param p1 integer
---@param scriptHash Hash|string
---@return boolean
function NetworkIsPlayerInScript(player, p1, scriptHash) end

---@param player integer
---@return boolean
function NetworkIsPlayerMutedByMe(player) end

---@param player integer
---@return boolean
function NetworkIsPlayerTalking(player) end

---@return boolean
function NetworkIsPsnAvailable() end

---@param scriptName string
---@param player integer
---@param p2 boolean
---@param p3 unknown
---@return boolean
function NetworkIsScriptActive(scriptName, player, p2, p3) end

---@param scriptHash Hash|string
---@param p1 integer
---@param p2 boolean
---@param p3 integer
---@return boolean
function NetworkIsScriptActiveByHash(scriptHash, p1, p2, p3) end

---@return boolean
function NetworkIsSessionActive() end

---@return boolean
function NetworkIsSessionBusy() end

---@return boolean
function NetworkIsSessionStarted() end

---@return boolean
function NetworkIsSignedIn() end

---@return boolean
function NetworkIsSignedOnline() end

---@return boolean
function NetworkIsTextChatActive() end

---@param p0 unknown
---@param p1 boolean
---@param p2 unknown
---@return boolean
function NetworkIsThisScriptMarked(p0, p1, p2) end

---@return boolean
function NetworkIsTransitionBusy() end

---@return boolean
function NetworkIsTransitionClosedCrew() end

---@return boolean
function NetworkIsTransitionClosedFriends() end

---@return boolean
function NetworkIsTransitionHost() end

---@return boolean
---@return integer networkHandle
function NetworkIsTransitionHostFromHandle() end

---@return boolean
function NetworkIsTransitionMatchmaking() end

---@return boolean
function NetworkIsTransitionOpenToMatchmaking() end

---@return boolean
function NetworkIsTransitionPrivate() end

---@return boolean
function NetworkIsTransitionSolo() end

---@return boolean
function NetworkIsTransitionStarted() end

---@return boolean
function NetworkIsTransitionToGame() end

---@return boolean
function NetworkIsTransitionVisibilityLocked() end

---@return boolean
function NetworkIsTunableCloudRequestPending() end

---@return boolean
function NetworkIsTutorialSessionChangePending() end

---@return unknown
function NetworkJoinGroupActivity() end

---@return boolean
function NetworkJoinPreviouslyFailedSession() end

---@return boolean
function NetworkJoinPreviouslyFailedTransition() end

---@param player integer
---@return boolean
function NetworkJoinTransition(player) end

---@return boolean
function NetworkLaunchTransition() end

---@return boolean
function NetworkLeaveTransition() end

---@param characterSlot integer
function NetworkManualDeleteCharacter(characterSlot) end

---@return boolean
---@return unknown p0
function NetworkMarkTransitionGamerAsFullyJoined() end

---@return string
---@return integer networkHandle
function NetworkMemberIdFromGamerHandle() end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
---@return boolean
function NetworkMoneyCanBet(amount, p1, p2) end

function NetworkOpenTransitionMatchmaking() end

---@param player integer
---@param toggle boolean
function NetworkOverrideChatRestrictions(player, toggle) end

---@param ms integer
function NetworkOverrideClockMillisecondsPerGameMinute(ms) end

---@param hours integer
---@param minutes integer
---@param seconds integer
function NetworkOverrideClockTime(hours, minutes, seconds) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
---@param heading number
function NetworkOverrideCoordsAndHeading(entity, x, y, z, heading) end

---@param player integer
---@param toggle boolean
function NetworkOverrideReceiveRestrictions(player, toggle) end

---@param toggle boolean
function NetworkOverrideReceiveRestrictionsAll(toggle) end

---@param player integer
---@param toggle boolean
function NetworkOverrideSendRestrictions(player, toggle) end

---@param toggle boolean
function NetworkOverrideSendRestrictionsAll(toggle) end

---@param team integer
---@param toggle boolean
function NetworkOverrideTeamRestrictions(team, toggle) end

---@param p0 boolean
function NetworkOverrideTransitionChat(p0) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkPayEmployeeWage(p0, p1, p2) end

---@param amount integer
---@param matchId string
---@param p2 boolean
---@param p3 boolean
function NetworkPayMatchEntryFee(amount, matchId, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkPayUtilityBill(amount, p1, p2) end

---@param ped Ped
function NetworkPedForceGameStateUpdate(ped) end

---@return integer
function NetworkPlayerGetCheaterReason() end

---@param player integer
---@return string
function NetworkPlayerGetName(player) end

---@param player integer
---@return string
---@return integer userID
function NetworkPlayerGetUserid(player) end

---@param player integer
---@return string
---@return integer userID
function NetworkPlayerGetUserId(player) end

---@param player integer
---@return boolean
function NetworkPlayerHasHeadset(player) end

---@return integer
function NetworkPlayerIdToInt() end

---@param player integer
---@return boolean
function NetworkPlayerIndexIsCheater(player) end

---@return boolean
function NetworkPlayerIsBadsport() end

---@return boolean
function NetworkPlayerIsCheater() end

---@return boolean
function NetworkPlayerIsInClan() end

---@param player integer
---@return boolean
function NetworkPlayerIsRockstarDev(player) end

---@return integer
function NetworkPlayerIsUnk() end

---@param player integer
---@return boolean
function NetworkPlayerSomething(player) end

---@return unknown
---@return unknown p0
function NetworkQueryRespawnResults() end

---@return boolean
---@return unknown p0
function NetworkQueueGamerForStatus() end

function NetworkQuitMpToDesktop() end

---@param value integer
---@return integer networkHandle
function NetworkReceivePlayerJobshareCash(value) end

---@param index integer
---@param context string
---@param reason string
---@param unk boolean
function NetworkRefundCash(index, context, reason, unk) end

---@param entity Entity
function NetworkRegisterEntityAsNetworked(entity) end

---@param numVars integer
---@return integer vars
function NetworkRegisterHostBroadcastVariables(numVars) end

---@param numVars integer
---@return integer vars
function NetworkRegisterPlayerBroadcastVariables(numVars) end

---@param contextHash Hash|string
---@param nameHash Hash|string
---@return boolean
---@return boolean value
function NetworkRegisterTunableBoolHash(contextHash, nameHash) end

---@param contextHash Hash|string
---@param nameHash Hash|string
---@return boolean
---@return number value
function NetworkRegisterTunableFloatHash(contextHash, nameHash) end

---@param contextHash Hash|string
---@param nameHash Hash|string
---@return boolean
---@return integer value
function NetworkRegisterTunableIntHash(contextHash, nameHash) end

function NetworkRemoveAllTransitionInvite() end

---@param p0 unknown
---@return boolean
function NetworkRemoveEntityArea(p0) end

---@param p0 unknown
---@return boolean
function NetworkRemovePresenceInvite(p0) end

---@return unknown p0
function NetworkRemoveTransitionInvite() end

function NetworkReportMyself() end

---@return boolean
function NetworkRequestCloudBackgroundScripts() end

function NetworkRequestCloudTunables() end

---@param doorID integer
---@return boolean
function NetworkRequestControlOfDoor(doorID) end

---@param entity Entity
---@return boolean
function NetworkRequestControlOfEntity(entity) end

---@param netId integer
---@return boolean
function NetworkRequestControlOfNetworkId(netId) end

function NetworkResetBodyTracker() end

---@param player integer
---@param x number
---@param y number
---@param z number
---@param p4 boolean
---@param p5 boolean
function NetworkRespawnCoords(player, x, y, z, p4, p5) end

---@param x number
---@param y number
---@param z number
---@param heading number
---@param nInvincibilityTime integer
---@param bLeaveDeadPed boolean
function NetworkResurrectLocalPlayer(x, y, z, heading, nInvincibilityTime, bLeaveDeadPed) end

---@param earnedMoney integer
function NetworkRivalDeliveryCompleted(earnedMoney) end

---@param matchmakingGroup integer
function NetworkSctvSlots(matchmakingGroup) end

---@param seed integer
function NetworkSeedRandomNumberGenerator(seed) end

---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return integer networkHandle
---@return unknown p1
function NetworkSendInviteViaPresence(p2, p3) end

---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return integer networkHandle
---@return unknown p1
function NetworkSendPresenceInvite(p2, p3) end

---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return unknown p0
---@return unknown p1
function NetworkSendPresenceTransitionInvite(p2, p3) end

---@param message string
---@return boolean
---@return integer networkHandle
function NetworkSendTextMessage(message) end

---@param p1 string
---@param p2 integer
---@param p3 integer
---@param p4 boolean
---@return boolean
---@return integer networkHandle
function NetworkSendTransitionGamerInstruction(p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return boolean
function NetworkSessionActivityQuickmatch(p0, p1, p2, p3) end

---@param groupId integer
function NetworkSessionAddActiveMatchmakingGroup(groupId) end

---@param player integer
---@return boolean
function NetworkSessionArePlayersVotingToKick(player) end

---@param toggle boolean
function NetworkSessionBlockJoinRequests(toggle) end

function NetworkSessionCancelInvite() end

---@param p0 integer
---@param p1 boolean
function NetworkSessionChangeSlots(p0, p1) end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param maxPlayers integer
---@param p4 boolean
---@return boolean
function NetworkSessionCrewMatchmaking(p0, p1, p2, maxPlayers, p4) end

---@param p0 boolean
---@param p1 boolean
---@return boolean
function NetworkSessionEnd(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param maxPlayers integer
---@param p4 unknown
---@param p5 unknown
---@return unknown
function NetworkSessionEnter(p0, p1, p2, maxPlayers, p4, p5) end

function NetworkSessionForceCancelInvite() end

---@param p0 integer
---@param p1 integer
---@param maxPlayers integer
---@param p3 boolean
---@return boolean
function NetworkSessionFriendMatchmaking(p0, p1, maxPlayers, p3) end

---@return integer networkHandle
function NetworkSessionGetInviter() end

---@param player integer
---@return boolean
function NetworkSessionGetKickVote(player) end

---@param p0 integer
---@return integer
function NetworkSessionGetMatchmakingGroupFree(p0) end

---@return integer
function NetworkSessionGetPrivateSlots() end

---@param p0 integer
---@return integer
function NetworkSessionGetUnk(p0) end

---@param p0 integer
---@param maxPlayers integer
---@param p2 boolean
---@return boolean
function NetworkSessionHost(p0, maxPlayers, p2) end

---@param p0 integer
---@param maxPlayers integer
---@return boolean
function NetworkSessionHostClosed(p0, maxPlayers) end

---@param p0 boolean
function NetworkSessionHosted(p0) end

---@param p0 integer
---@param maxPlayers integer
---@return boolean
function NetworkSessionHostFriendsOnly(p0, maxPlayers) end

---@param p0 integer
function NetworkSessionHostSinglePlayer(p0) end

---@return boolean
function NetworkSessionIsClosedCrew() end

---@return boolean
function NetworkSessionIsClosedFriends() end

---@return boolean
function NetworkSessionIsInVoiceSession() end

---@param player integer
---@return boolean
function NetworkSessionIsPlayerVotedToKick(player) end

---@return boolean
function NetworkSessionIsPrivate() end

---@return boolean
function NetworkSessionIsSolo() end

---@return boolean
function NetworkSessionIsVisible() end

---@return boolean
function NetworkSessionIsVoiceSessionBusy() end

function NetworkSessionJoinInvite() end

---@param player integer
function NetworkSessionKickPlayer(player) end

function NetworkSessionLeaveSinglePlayer() end

---@param toggle boolean
function NetworkSessionMarkVisible(toggle) end

---@param matchmakingGroup integer
function NetworkSessionSetMatchmakingGroup(matchmakingGroup) end

---@param playerType integer
---@param playerCount integer
function NetworkSessionSetMatchmakingGroupMax(playerType, playerCount) end

---@param p0 unknown
function NetworkSessionSetMatchmakingMentalState(p0) end

---@param p0 boolean
function NetworkSessionSetMatchmakingPropertyId(p0) end

---@param playerType integer
---@param playerCount integer
function NetworkSessionSetMaxPlayers(playerType, playerCount) end

---@param p0 boolean
function NetworkSessionValidateJoin(p0) end

---@return unknown globalPtr
function NetworkSessionVoiceConnectToPlayer() end

function NetworkSessionVoiceHost() end

function NetworkSessionVoiceLeave() end

---@param p0 boolean
---@param p1 integer
function NetworkSessionVoiceRespondToRequest(p0, p1) end

---@param timeout integer
function NetworkSessionVoiceSetTimeout(timeout) end

---@return boolean
function NetworkSessionWasInvited() end

---@param playerCount integer
function NetworkSetActivityPlayerMax(playerCount) end

---@param toggle boolean
function NetworkSetActivitySpectator(toggle) end

---@param maxSpectators integer
function NetworkSetActivitySpectatorMax(maxSpectators) end

---@param toggle boolean
---@param player integer
function NetworkSetChoiceMigrateOptions(toggle, player) end

---@return boolean
---@return unknown p0
function NetworkSetCurrentDataManagerHandle() end

---@return boolean
---@return unknown p0
function NetworkSetCurrentlySelectedGamerHandleFromInviteMenu() end

---@param missionId string
function NetworkSetCurrentMissionId(missionId) end

---@param mpSettingSpawn Hash|string
function NetworkSetCurrentSpawnSetting(mpSettingSpawn) end

---@param entity Entity
---@param toggle boolean
function NetworkSetEntityCanBlend(entity, toggle) end

---@param entity Entity
---@param p1 boolean
function NetworkSetEntityGhostedWithOwner(entity, p1) end

---@param entity Entity
---@param toggle boolean
function NetworkSetEntityInvisibleToNetwork(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function NetworkSetEntityVisibleToNetwork(entity, toggle) end

---@param toggle boolean
function NetworkSetFriendlyFireOption(toggle) end

---@return integer networkHandle
function NetworkSetGamerInvitedToTransition() end

---@param toggle boolean
function NetworkSetInFreeCamMode(toggle) end

---@param p0 boolean
---@param p1 boolean
function NetworkSetInMpCutscene(p0, p1) end

---@param toggle boolean
---@param playerPed Ped
function NetworkSetInSpectatorMode(toggle, playerPed) end

---@param toggle boolean
---@param playerPed Ped
---@param p2 boolean
function NetworkSetInSpectatorModeExtended(toggle, playerPed, p2) end

---@return integer networkHandle
function NetworkSetInviteOnCallForInviteMenu() end

---@param p0 boolean
---@param p1 integer
function NetworkSetKeepFocuspoint(p0, p1) end

---@param time integer
function NetworkSetLocalPlayerInvincibleTime(time) end

---@param toggle boolean
function NetworkSetLocalPlayerSyncLookAt(toggle) end

function NetworkSetMissionFinished() end

---@param netID integer
---@param toggle boolean
function NetworkSetNetworkIdDynamic(netID, toggle) end

---@param toggle boolean
function NetworkSetNoSpectatorChat(toggle) end

---@param object integer
---@param enabled boolean
function NetworkSetObjectForceStaticBlend(object, enabled) end

---@param toggle boolean
function NetworkSetOverrideSpectatorMode(toggle) end

---@param toggle boolean
function NetworkSetPlayerIsPassive(toggle) end

---@param id integer
function NetworkSetPropertyId(id) end

---@param p0 integer
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSetRichPresence(p0, p1, p2, p3) end

---@param p0 integer
---@param textLabel string
function NetworkSetRichPresence_2(p0, textLabel) end

---@param p0 integer
---@param textLabel string
function NetworkSetRichPresenceString(p0, textLabel) end

function NetworkSetScriptIsSafeForNetworkGame() end

---@param toggle boolean
function NetworkSetScriptReadyForEvents(toggle) end

---@param value number
function NetworkSetTalkerProximity(value) end

---@param toggle boolean
function NetworkSetTeamOnlyChat(toggle) end

---@param maxNumMissionParticipants integer
---@param p1 boolean
---@param instanceId integer
function NetworkSetThisScriptIsNetworkScript(maxNumMissionParticipants, p1, instanceId) end

---@param p0 unknown
---@param p1 boolean
---@param p2 unknown
---@return boolean
function NetworkSetThisScriptMarked(p0, p1, p2) end

---@param p0 unknown
function NetworkSetTransitionActivityId(p0) end

---@return unknown p0
function NetworkSetTransitionCreatorHandle() end

---@param p0 boolean
---@param p1 boolean
function NetworkSetTransitionVisibilityLock(p0, p1) end

---@param toggle boolean
function NetworkSetVehicleTestDrive(toggle) end

---@param vehicle integer
---@param toggle boolean
function NetworkSetVehicleWheelsDestructible(vehicle, toggle) end

---@param toggle boolean
function NetworkSetVoiceActive(toggle) end

---@param channel integer
function NetworkSetVoiceChannel(channel) end

---@param quantity integer
---@return boolean
---@return unknown itemData
function NetworkShopBasketAddItem(quantity) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function NetworkShopBasketApplyServerData(p0) end

---@return boolean
function NetworkShopBasketEnd() end

---@return boolean
function NetworkShopBasketIsFull() end

---@param categoryHash Hash|string
---@param actionHash Hash|string
---@param flags integer
---@return boolean
---@return integer transactionId
function NetworkShopBasketStart(categoryHash, actionHash, flags) end

---@param categoryHash Hash|string
---@param itemHash Hash|string
---@param actionTypeHash Hash|string
---@param value integer
---@param flags integer
---@return boolean
---@return integer transactionId
function NetworkShopBeginService(categoryHash, itemHash, actionTypeHash, value, flags) end

---@return boolean
function NetworkShopCashTransferSetTelemetryNonceSeed() end

---@param transactionId integer
---@return boolean
function NetworkShopCheckoutStart(transactionId) end

---@return boolean
function NetworkShopDeleteSetTelemetryNonceSeed() end

---@param name string
---@return boolean
function NetworkShopDoesItemExist(name) end

---@param hash Hash|string
---@return boolean
function NetworkShopDoesItemExistHash(hash) end

---@param transactionId integer
---@return boolean
function NetworkShopEndService(transactionId) end

---@param itemHash Hash|string
---@param categoryHash Hash|string
---@param p2 boolean
---@return integer
function NetworkShopGetPrice(itemHash, categoryHash, p2) end

---@return boolean
function NetworkShopGetTransactionsDisabled() end

---@param charSlot integer
---@return boolean
function NetworkShopGetTransactionsEnabledForCharacter(charSlot) end

---@param name string
---@return boolean
function NetworkShopIsItemUnlocked(name) end

---@param hash Hash|string
---@return boolean
function NetworkShopIsItemUnlockedHash(hash) end

---@param charSlot integer
---@return boolean
function NetworkShopSessionApplyReceivedData(charSlot) end

---@param p0 integer
---@return boolean
function NetworkShopSetTelemetryNonceSeed(p0) end

---@param charSlot integer
---@return boolean
function NetworkShopStartSession(charSlot) end

---@param transactionId integer
---@return boolean
function NetworkShopTerminateService(transactionId) end

---@return boolean
function NetworkShouldShowConnectivityTroubleshooting() end

---@return integer networkHandle
function NetworkShowProfileUi() end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentAmmoDrop(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkSpentArcadeGame(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkSpentArcadeGeneric(p0, p1, p2, p3, p4) end

---@param amount integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentArenaJoinSpectator(amount, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentArenaPremium(amount, p1, p2) end

---@param amount integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentArenaSpectatorBox(amount, p1, p2, p3) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentArrestBail(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkSpentAutoshopModifications(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentAutoshopPropertyUtilityFee(p0, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBallisticEquipment(amount, p1, p2) end

---@param p0 integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBankInterest(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkSpentBaService(p0, p1, p2, p3, p4) end

---@param p0 unknown
function NetworkSpentBeachPartyGeneric(p0) end

---@param amount integer
---@param p1 integer
---@param matchId string
---@param p3 boolean
---@param p4 boolean
function NetworkSpentBetting(amount, p1, matchId, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentBikeShopModify(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBoatPickup(p0, p1, p2) end

---@return boolean
function NetworkSpentBoss() end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBounty(p0, p1, p2) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBountyHunterMission(amount, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBullShark(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentBusiness(p0, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
---@param p3 string
function NetworkSpentBuyArena(amount, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentBuyAutoshop(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentBuyBase(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentBuyBunker(p0, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
---@return unknown data
function NetworkSpentBuyCasino(amount, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBuyOfftheradar(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBuyPassiveMode(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentBuyRevealPlayers(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentBuyTiltrotor(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentBuyTruck(p0, p1, p2, p3) end

---@param p0 unknown
---@param p2 boolean
---@param p3 boolean
---@return unknown p1
function NetworkSpentBuyWantedlevel(p0, p2, p3) end

---@param p0 unknown
---@param p2 boolean
---@param p3 boolean
---@return unknown p1
function NetworkSpentCallPlayer(p0, p2, p3) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
---@param p3 unknown
function NetworkSpentCarclub(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkSpentCarclubMembership(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentCarclubTakeover(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function NetworkSpentCargoSourcing(p0, p1, p2, p3, p4, p5) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 boolean
---@param p4 boolean
function NetworkSpentCarwash(p0, p1, p2, p3, p4) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentCashDrop(amount, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
function NetworkSpentCasinoClubGeneric(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@param amount integer
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkSpentCasinoGeneric(amount, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
---@param p10 unknown
function NetworkSpentCasinoHeist(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentCasinoHeistSkipMission(p0, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
---@param p3 integer
function NetworkSpentCasinoMembership(amount, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentCinema(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentEmployAssassins(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 boolean
function NetworkSpentFromBank(p0, p1, p2, p3) end

---@param bank integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentFromRockstar(bank, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentGangopsCannon(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentGangopsStartMission(p0, p1, p2, p3) end

---@param type integer
---@param amount integer
---@param p2 boolean
---@param p3 boolean
function NetworkSpentGangopsStartStrand(type, amount, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentGangopsTripSkip(amount, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentGunrunningContactService(p0, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentHangarStaffCharges(amount, p1, p2) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentHangarUtilityCharges(amount, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentHeliPickup(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentHireMercenary(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentHireMugger(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentHoldups(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentImAbility(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkSpentImportExportRepair(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 unknown
---@param p3 boolean
function NetworkSpentInStripclub(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentIslandHeist(p0, p1, p2, p3) end

---@param amount integer
---@param matchId string
---@param p2 boolean
---@param p3 boolean
function NetworkSpentJobSkip(amount, matchId, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentJukebox(p0, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentMakeItRain(amount, p1, p2) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentMoveYacht(amount, p1, p2) end

---@param amount integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentNightclubBarDrink(amount, p1, p2, p3) end

---@param player integer
---@param amount integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentNightclubEntryFee(player, amount, p1, p2, p3) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentNoCops(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentOrderBodyguardVehicle(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentOrderWarehouseVehicle(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentPaServiceDancer(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentPaServiceHeliPickup(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkSpentPayBoss(p0, p1, p2) end

---@param p0 integer
---@param p1 integer
---@param amount integer
function NetworkSpentPayGoon(p0, p1, amount) end

---@param amount integer
---@param vehicleModel Hash|string
---@param notBankrupt boolean
---@param hasTheMoney boolean
---@return integer networkHandle
function NetworkSpentPayVehicleInsurancePremium(amount, vehicleModel, notBankrupt, hasTheMoney) end

---@param p0 integer
---@param p1 integer
---@param p2 boolean
---@param p3 boolean
function NetworkSpentPlayerHealthcare(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentProstitutes(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentPurchaseHangar(p0, p1, p2, p3) end

---@param amount integer
---@param data unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentPurchaseWarehouse(amount, data, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentRdrhatchetBonus(amount, p1, p2) end

---@param amount integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentRehireDj(amount, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkSpentRenameOrganization(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentRequestHeist(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentRequestJob(p0, p1, p2) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentRobbedByMugger(amount, p1, p2) end

---@param p0 boolean
function NetworkSpentSalesDisplay(p0) end

---@param amount integer
---@param p1 unknown
---@param p2 boolean
---@param p3 boolean
function NetworkSpentSpinTheWheelPayment(amount, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function NetworkSpentSubmarine(p0, p1, p2, p3, p4, p5) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
function NetworkSpentTaxi(amount, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function NetworkSpentTelescope(p0, p1, p2) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
---@param p3 string
function NetworkSpentUpgradeArena(amount, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentUpgradeAutoshop(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentUpgradeBase(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentUpgradeBunker(p0, p1, p2, p3) end

---@param amount integer
---@param p1 boolean
---@param p2 boolean
---@return unknown data
function NetworkSpentUpgradeCasino(amount, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentUpgradeHangar(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentUpgradeSub(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentUpgradeTiltrotor(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function NetworkSpentUpgradeTruck(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
function NetworkSpentVehicleExportMods(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function NetworkSpentVehicleRequested(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function NetworkSpentVipUtilityCharges(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param amount integer
function NetworkSpentWager(p0, p1, amount) end

---@param player integer
---@param x number
---@param y number
---@param z number
---@param radius number
---@param p5 number
---@param p6 number
---@param p7 number
---@param flags integer
---@return boolean
function NetworkStartRespawnSearchForPlayer(player, x, y, z, radius, p5, p6, p7, flags) end

---@param player integer
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param p8 number
---@param p9 number
---@param p10 number
---@param flags integer
---@return boolean
function NetworkStartRespawnSearchInAngledAreaForPlayer(player, x1, y1, z1, x2, y2, z2, width, p8, p9, p10, flags) end

function NetworkStartSoloTutorialSession() end

---@param netScene integer
function NetworkStartSynchronisedScene(netScene) end

---@param netHandle unknown
---@return integer
function NetworkStartUserContentPermissionsCheck(netHandle) end

function NetworkStopLoadScene() end

---@param netScene integer
function NetworkStopSynchronisedScene(netScene) end

---@param toggle boolean
function NetworkSuppressInvite(toggle) end

---@param charSlot integer
---@param amount integer
---@return boolean
function NetworkTransferBankToWallet(charSlot, amount) end

---@param charSlot integer
---@param amount integer
---@return boolean
function NetworkTransferWalletToBank(charSlot, amount) end

---@param hash Hash|string
---@param p1 integer
---@param p2 integer
---@param state integer
---@param p4 integer
function NetworkTransitionTrack(hash, p1, p2, state, p4) end

---@param tunableContext Hash|string
---@param tunableName Hash|string
---@param defaultValue boolean
---@return boolean
function NetworkTryAccessTunableBoolHash(tunableContext, tunableName, defaultValue) end

---@param p0 unknown
---@param p1 unknown
function NetworkUgcNav(p0, p1) end

---@param netSceneId integer
---@return integer
function NetworkUnlinkNetworkedSynchronisedScene(netSceneId) end

---@param entity Entity
function NetworkUnregisterNetworkedEntity(entity) end

---@return boolean
function NetworkUpdateLoadScene() end

function NetworkUpdatePlayerScars() end

---@param netID integer
---@param toggle boolean
function NetworkUseHighPrecisionBlending(netID, toggle) end

---@param vehicle integer
---@param toggle boolean
function NetworkUseHighPrecisionVehicleBlending(vehicle, toggle) end

---@param entity Entity
function NetworkUseLogarithmicBlendingThisFrame(entity) end

---@return unknown globalPtr
function NetworkVoiceConnectToPlayer() end

---@param p0 unknown
---@return boolean
function NetworkXAffectsGamers(p0) end

---@param posX number
---@param posY number
---@param posZ number
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param radius number
---@param p7 integer
---@return boolean
function NewLoadSceneStart(posX, posY, posZ, offsetX, offsetY, offsetZ, radius, p7) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param p4 unknown
---@return boolean
function NewLoadSceneStartSphere(x, y, z, radius, p4) end

function NewLoadSceneStop() end

---@param fontBitField integer
function NextOnscreenKeyboardResultWillDisplayUsingTheseFonts(fontBitField) end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param hasFounderStatus boolean
---@param isImportant boolean
---@param clanHandle integer
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function NotificationSendApartmentInvite(crewTypeIsPrivate, crewTagContainsRockstar, rank, hasFounderStatus, isImportant, clanHandle, r, g, b) end

---@param crewTypeIsPrivate boolean
---@param crewTagContainsRockstar boolean
---@param rank integer
---@param isLeader boolean
---@param isImportant boolean
---@param clanHandle integer
---@param gamerStr string
---@param r integer
---@param g integer
---@param b integer
---@return integer
---@return integer crewTag
function NotificationSendClanInvite(crewTypeIsPrivate, crewTagContainsRockstar, rank, isLeader, isImportant, clanHandle, gamerStr, r, g, b) end

---@param unused unknown
---@return boolean
---@return boolean variable
function Nullify(unused) end

---@param contextHash Hash|string
function ObjectDecalToggle(contextHash) end

---@param key string
---@return unknown
---@return unknown objectData
function ObjectValueAddArray(key) end

---@param key string
---@param value boolean
---@return unknown objectData
function ObjectValueAddBoolean(key, value) end

---@param key string
---@param value number
---@return unknown objectData
function ObjectValueAddFloat(key, value) end

---@param key string
---@param value integer
---@return unknown objectData
function ObjectValueAddInteger(key, value) end

---@param key string
---@return unknown
---@return unknown objectData
function ObjectValueAddObject(key) end

---@param key string
---@param value string
---@return unknown objectData
function ObjectValueAddString(key, value) end

---@param key string
---@param valueX number
---@param valueY number
---@param valueZ number
---@return unknown objectData
function ObjectValueAddVector3(key, valueX, valueY, valueZ) end

---@param key string
---@return unknown
---@return unknown objectData
function ObjectValueGetArray(key) end

---@param key string
---@return boolean
---@return unknown objectData
function ObjectValueGetBoolean(key) end

---@param key string
---@return number
---@return unknown objectData
function ObjectValueGetFloat(key) end

---@param key string
---@return integer
---@return unknown objectData
function ObjectValueGetInteger(key) end

---@param key string
---@return unknown
---@return unknown objectData
function ObjectValueGetObject(key) end

---@param key string
---@return string
---@return unknown objectData
function ObjectValueGetString(key) end

---@param key string
---@return integer
---@return unknown objectData
function ObjectValueGetType(key) end

---@param key string
---@return vector3
---@return unknown objectData
function ObjectValueGetVector3(key) end

---@param object integer
---@return integer
function ObjToNet(object) end

function OnEnterMp() end

function OnEnterSp() end

---@param enable boolean
function OnesyncEnableRemoteAttachmentSanitization(enable) end

---@param vehicle integer
function OpenBombBayDoors(vehicle) end

---@param p0 string
---@param p1 string
function OpenCommerceStore(p0, p1) end

function OpenOnlinePoliciesMenu() end

---@param patrolRoute string
function OpenPatrolRoute(patrolRoute) end

function OpenReportugcMenu() end

---@return integer taskSequenceId
function OpenSequenceTask() end

function OpenSocialClubMenu() end

---@param vehicle integer
function OpenVehicleBombBay(vehicle) end

---@param p0 unknown
---@param p1 unknown
---@param vehicleHash Hash|string
function OrderedBossVehicle(p0, p1, vehicleHash) end

---@param cam integer
---@param p1 integer
---@param p2 number
---@param p3 number
function OverrideCamSplineMotionBlur(cam, p1, p2, p3) end

---@param cam integer
---@param p1 integer
---@param p2 number
---@param p3 number
function OverrideCamSplineVelocity(cam, p1, p2, p3) end

---@param decalType integer
---@param textureDict string
---@param textureName string
function OverrideDecalTexture(decalType, textureDict, textureName) end

function OverrideInteriorSmokeEnd() end

---@param level number
function OverrideInteriorSmokeLevel(level) end

---@param name string
function OverrideInteriorSmokeName(name) end

---@param scaling number
function OverrideLodscaleThisFrame(scaling) end

---@param hash Hash|string
---@param toggle boolean
function OverrideMicrophoneSettings(hash, toggle) end

---@param p0 integer
---@param hudColor integer
function OverrideMultiplayerChatColour(p0, hudColor) end

---@param gxtEntryHash Hash|string
function OverrideMultiplayerChatPrefix(gxtEntryHash) end

---@param ped Ped
---@param txd string
---@param txn string
---@return boolean
function OverridePedBadgeTexture(ped, txd, txn) end

---@param flag boolean
function OverridePedsCanStandOnTopFlag(flag) end

---@param flag boolean
function OverridePedsUseDefaultDriveByClipset(flag) end

---@param overriddenMaterialHash Hash|string
---@param scriptOverrides boolean
function OverridePlayerGroundMaterial(overriddenMaterialHash, scriptOverrides) end

---@param path string
function OverridePopGroups(path) end

---@param scheduleId integer
---@param vehicleHash Hash|string
function OverridePopscheduleVehicleModel(scheduleId, vehicleHash) end

---@param state boolean
---@param reaction integer
function OverrideReactionToVehicleSiren(state, reaction) end

---@param p0 boolean
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 boolean
---@return boolean
---@return vector3 p6
---@return number p7
function OverrideSaveHouse(p0, p1, p2, p3, p4, p5) end

---@param voiceEffect string
function OverrideTrevorRage(voiceEffect) end

---@param streamName string
---@param override boolean
function OverrideUnderwaterStream(streamName, override) end

---@param vehicle integer
---@param override boolean
---@param hornHash integer
function OverrideVehHorn(vehicle, override, hornHash) end

---@param vehicle integer
---@param can boolean
function OverrideVehiclePedsCanStandOnTopFlag(vehicle, can) end

---@return integer
function ParticipantId() end

---@return integer
function ParticipantIdToInt() end

---@param scaleformHandle integer
---@return boolean
function PassKeyboardInputToScaleform(scaleformHandle) end

---@param decalType integer
---@param textureDict string
---@param textureName string
function PatchDecalDiffuseMap(decalType, textureDict, textureName) end

---@param toggle boolean
function PauseClock(toggle) end

---@param toggle boolean
function PauseDeathArrestRestart(toggle) end

function PausedScreenblurLoaded() end

---@param hash Hash|string
function PauseMenuActivateContext(hash) end

---@param pageId integer
function PauseMenuceptionGoDeeper(pageId) end

function PauseMenuceptionTheKick() end

---@param contextHash Hash|string
function PauseMenuDeactivateContext(contextHash) end

---@param toggle boolean
function PauseMenuDisableBusyspinner(toggle) end

---@return integer
function PauseMenuGetIndexOfMouseHoveredSlot() end

---@return integer
function PauseMenuGetUniqueIdOfMouseHoveredSlot() end

---@param contextHash Hash|string
---@return boolean
function PauseMenuIsContextActive(contextHash) end

---@return unknown
function PauseMenuIsContextMenuActive() end

---@param p0 integer
function PauseMenuRedrawInstructionalButtons(p0) end

---@param bVisible boolean
---@param iColumnID integer
---@param iSpinnerIndex integer
function PauseMenuSetBusySpinner(bVisible, iColumnID, iSpinnerIndex) end

---@param setWarn boolean
function PauseMenuSetWarnOnTabChange(setWarn) end

---@param vehicle integer
function PausePlaybackRecordedVehicle(vehicle) end

---@param finishCurrentLine boolean
function PauseScriptedConversation(finishCurrentLine) end

---@param enabled boolean
function PauseToggleFullscreenMap(enabled) end

---@param ped Ped
---@return boolean
function PedHasUseScenarioTask(ped) end

---@param ped Ped
---@return boolean
function PedSkipNextReloading(ped) end

---@param ped Ped
---@return integer
function PedToNet(ped) end

---@param interior integer
function PinInteriorInMemory(interior) end

---@param ropeId integer
---@param vertex integer
---@param x number
---@param y number
---@param z number
function PinRopeVertex(ropeId, vertex, x, y, z) end

---@param object integer
---@return boolean
function PlaceObjectOnGroundProperly(object) end

---@param object integer
---@return boolean
function PlaceObjectOnGroundProperly_2(object) end

---@param ped Ped
---@param speechName string
---@param speechParam string
function PlayAmbientSpeech1(ped, speechName, speechParam) end

---@param ped Ped
---@param speechName string
---@param speechParam string
function PlayAmbientSpeech2(ped, speechName, speechParam) end

---@param speechName string
---@param voiceName string
---@param x number
---@param y number
---@param z number
---@param speechParam string
function PlayAmbientSpeechAtCoords(speechName, voiceName, x, y, z, speechParam) end

---@param speechName string
---@param voiceName string
---@param x number
---@param y number
---@param z number
---@param speechParam string
function PlayAmbientSpeechFromPositionNative(speechName, voiceName, x, y, z, speechParam) end

---@param ped Ped
---@param speechName string
---@param voiceName string
---@param speechParam string
---@param p4 boolean
function PlayAmbientSpeechWithVoice(ped, speechName, voiceName, speechParam, p4) end

---@param pedHandle Ped
---@param animalType integer
---@param speechName string
function PlayAnimalVocalization(pedHandle, animalType, speechName) end

---@param ped Ped
---@param animDict string
---@param animName string
function PlayAnimOnRunningScenario(ped, animDict, animName) end

---@param binkMovie integer
function PlayBinkMovie(binkMovie) end

---@param cam integer
---@param animName string
---@param animDictionary string
---@param x number
---@param y number
---@param z number
---@param xRot number
---@param yRot number
---@param zRot number
---@param p9 boolean
---@param p10 integer
---@return boolean
function PlayCamAnim(cam, animName, animDictionary, x, y, z, xRot, yRot, zRot, p9, p10) end

---@param soundName string
---@param soundsetName string
function PlayDeferredSoundFrontend(soundName, soundsetName) end

---@param bActive boolean
function PlayEndCreditsMusic(bActive) end

---@param entity Entity
---@param animName string
---@param animDict string
---@param p3 number
---@param loop boolean
---@param stayInAnim boolean
---@param p6 boolean
---@param delta number
---@param bitset unknown
---@return boolean
function PlayEntityAnim(entity, animName, animDict, p3, loop, stayInAnim, p6, delta, bitset) end

---@param p0 unknown
---@param p4 number
---@param p5 number
---@return unknown p1
---@return unknown p2
---@return unknown p3
function PlayEntityScriptedAnim(p0, p4, p5) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
function PlayerAttachVirtualBound(p0, p1, p2, p3, p4, p5, p6, p7) end

function PlayerDetachVirtualBound() end

---@param ped Ped
---@param animName string
---@param animDict string
function PlayFacialAnim(ped, animName, animDict) end

---@param audioName string
function PlayMissionCompleteAudio(audioName) end

---@param ped Ped
---@param damageReason integer
---@param rawDamage number
function PlayPain(ped, damageReason, rawDamage) end

---@param ped Ped
---@param speechName string
---@param speechParam string
function PlayPedAmbientSpeechAndCloneNative(ped, speechName, speechParam) end

---@param ped Ped
---@param speechName string
---@param speechParam string
function PlayPedAmbientSpeechNative(ped, speechName, speechParam) end

---@param ped Ped
---@param speechName string
---@param voiceName string
---@param speechParam string
---@param p4 boolean
function PlayPedAmbientSpeechWithVoiceNative(ped, speechName, voiceName, speechParam, p4) end

---@param ringtoneName string
---@param ped Ped
---@param p2 boolean
function PlayPedRingtone(ringtoneName, ped, p2) end

---@param name string
---@param p1 number
---@return integer
function PlayPoliceReport(name, p1) end

---@param soundId integer
---@param audioName string
---@param audioRef string
---@param p3 boolean
---@param p4 unknown
---@param p5 boolean
function PlaySound(soundId, audioName, audioRef, p3, p4, p5) end

---@param soundId integer
---@param audioName string
---@param x number
---@param y number
---@param z number
---@param audioRef string
---@param isNetwork boolean
---@param range integer
---@param p8 boolean
function PlaySoundFromCoord(soundId, audioName, x, y, z, audioRef, isNetwork, range, p8) end

---@param soundId integer
---@param audioName string
---@param entity Entity
---@param audioRef string
---@param isNetwork boolean
---@param p5 unknown
function PlaySoundFromEntity(soundId, audioName, entity, audioRef, isNetwork, p5) end

---@param soundId integer
---@param audioName string
---@param audioRef string
---@param p3 boolean
function PlaySoundFrontend(soundId, audioName, audioRef, p3) end

---@param p0 unknown
function PlaystatsAcquiredHiddenPackage(p0) end

---@param p0 unknown
---@param p1 unknown
function PlaystatsActivityDone(p0, p1) end

---@param p0 number
---@param p1 number
---@param p2 number
function PlaystatsAmbientMissionCrateCreated(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function PlaystatsArcadegame(p0, p1, p2, p3, p4, p5) end

---@return unknown data
function PlaystatsArenaWarsEnded() end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param p3 integer
---@param p4 integer
function PlaystatsArenaWarSpectator(p0, p1, p2, p3, p4) end

---@param id integer
function PlaystatsAwardBadsport(id) end

---@param amount integer
---@param type Hash|string
---@param category Hash|string
function PlaystatsAwardXp(amount, type, category) end

---@param action string
---@param value integer
function PlaystatsBackgroundScriptAction(action, value) end

---@param p0 integer
function PlaystatsBanAlert(p0) end

---@return unknown data
function PlaystatsBuyContraband() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function PlaystatsCarclubChallenge(p0, p1, p2, p3) end

---@param p0 unknown
function PlaystatsCarclubPoints(p0) end

---@param p0 unknown
---@param p1 unknown
function PlaystatsCarclubPrize(p0, p1) end

---@param p0 unknown
function PlaystatsCasinoBlackjack(p0) end

---@param p0 unknown
function PlaystatsCasinoBlackjackLight(p0) end

---@param p0 unknown
function PlaystatsCasinoChip(p0) end

---@param p0 unknown
function PlaystatsCasinoInsidetrack(p0) end

---@param p0 unknown
function PlaystatsCasinoInsidetrackLight(p0) end

---@param p0 unknown
function PlaystatsCasinoLuckyseven(p0) end

---@return unknown data
function PlaystatsCasinoMissionEnded() end

---@param p0 unknown
function PlaystatsCasinoRoulette(p0) end

---@param p0 unknown
function PlaystatsCasinoRouletteLight(p0) end

---@param p0 unknown
function PlaystatsCasinoSlotmachine(p0) end

---@param p0 unknown
function PlaystatsCasinoSlotmachineLight(p0) end

---@param p0 unknown
---@param p1 unknown
function PlaystatsCasinoStoryMissionEnded(p0, p1) end

---@param p0 unknown
function PlaystatsCasinoThreecardpoker(p0) end

---@param p0 unknown
function PlaystatsCasinoThreecardpokerLight(p0) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function PlaystatsChangeMcEmblem(p0, p1, p2, p3, p4) end

---@param cheat string
function PlaystatsCheatApplied(cheat) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function PlaystatsClothChange(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
function PlaystatsCollectible(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
function PlaystatsCopyRankIntoNewSlot(p0, p1, p2, p3, p4, p5, p6) end

---@param p0 number
---@param p1 number
---@param p2 number
function PlaystatsCrateCreated(p0, p1, p2) end

---@param p0 number
---@param p1 number
---@param p2 number
function PlaystatsCrateCreatedMissionDone(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function PlaystatsCrateDrop(p0, p1, p2, p3, p4, p5) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function PlaystatsCrateDropMissionDone(p0, p1, p2, p3, p4, p5) end

---@return unknown data
function PlaystatsDarMissionEnd() end

---@return unknown data
function PlaystatsDefendContraband() end

---@return unknown p0
function PlaystatsDirectorMode() end

---@param p0 integer
---@param p1 integer
---@param p2 integer
function PlaystatsDroneUsage(p0, p1, p2) end

---@return unknown data
function PlaystatsDupeDetection() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function PlaystatsEarnedMcPoints(p0, p1, p2, p3, p4, p5) end

---@return unknown data
function PlaystatsEnterSessionPack() end

---@param p0 unknown
function PlaystatsExtraEvent(p0) end

---@param p0 unknown
---@param p1 unknown
function PlaystatsFriendActivity(p0, p1) end

---@return unknown data
function PlaystatsGunrunMissionEnded() end

---@return unknown data
function PlaystatsH2FmprepEnd() end

---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return unknown data
function PlaystatsH2InstanceEnd(p1, p2, p3) end

---@param hash Hash|string
---@param p1 integer
function PlaystatsHeistSaveCheat(hash, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function PlaystatsHoldUp(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function PlaystatsHoldUpMissionDone(p0, p1, p2, p3) end

---@param time integer
function PlaystatsIdleKick(time) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function PlaystatsImpExp(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function PlaystatsImportExportMissionDone(p0, p1, p2, p3) end

---@param p0 unknown
function PlaystatsInventory(p0) end

---@return unknown p0
---@return unknown p1
---@return unknown p2
---@return unknown p3
function PlaystatsJobBend() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function PlaystatsLeaveJobChain(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
function PlaystatsMatchStarted(p0, p1, p2, p3, p4, p5, p6) end

---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return unknown p0
function PlaystatsMissionCheckpoint(p1, p2, p3) end

---@param p1 unknown
---@param p2 unknown
---@param p3 boolean
---@param p4 boolean
---@param p5 boolean
---@return unknown p0
function PlaystatsMissionOver(p1, p2, p3, p4, p5) end

---@param p1 unknown
---@param p2 unknown
---@param p3 boolean
---@return unknown p0
function PlaystatsMissionStarted(p1, p2, p3) end

---@return unknown p0
function PlaystatsNpcInvite() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
function PlaystatsOddjobDone(p0, p1, p2) end

---@param p0 boolean
---@param p1 integer
---@param p2 integer
---@param p3 integer
function PlaystatsPassiveMode(p0, p1, p2, p3) end

---@param modelHash Hash|string
function PlaystatsPegasaircraft(modelHash) end

---@return unknown data
function PlaystatsPiMenuHideSettings() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function PlaystatsPropChange(p0, p1, p2, p3) end

---@param element integer
---@param item string
function PlaystatsQuickfixTool(element, item) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function PlaystatsRaceCheckpoint(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
function PlaystatsRaceToPoint(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
function PlaystatsRaceToPointMissionDone(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

---@param name string
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function PlaystatsRandomMissionDone(name, p1, p2, p3) end

---@param rank integer
function PlaystatsRankUp(rank) end

---@return unknown data
function PlaystatsRecoverContraband() end

---@param p0 unknown
function PlaystatsRobberyFinale(p0) end

---@param p0 unknown
function PlaystatsRobberyPrep(p0) end

---@param amount integer
---@param act integer
---@param player integer
---@param cm number
function PlaystatsRosBet(amount, act, player, cm) end

---@return unknown data
function PlaystatsSellContraband() end

---@param joinType integer
function PlaystatsSetJoinType(joinType) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function PlaystatsShopItem(p0, p1, p2, p3, p4) end

---@return unknown data
function PlaystatsSmugMissionEnded() end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param p3 integer
function PlaystatsSpectatorWheelSpin(p0, p1, p2, p3) end

---@param amount integer
function PlaystatsSpentPiCustomLoadout(amount) end

function PlaystatsStartOfflineMode() end

function PlaystatsStartTrackingStunts() end

---@return unknown data
function PlaystatsStoneHatchetEnd() end

function PlaystatsStopTrackingStunts() end

function PlaystatsStuntPerformedEventAllowTrigger() end

function PlaystatsStuntPerformedEventDisallowTrigger() end

---@param weaponHash Hash|string
---@param componentHashTo Hash|string
---@param componentHashFrom Hash|string
function PlaystatsWeaponModeChange(weaponHash, componentHashTo, componentHashFrom) end

---@param scaleformHash Hash|string
---@param p1 integer
function PlaystatsWebsiteVisited(scaleformHash, p1) end

---@param object integer
function PlayStreamFromObject(object) end

---@param ped Ped
function PlayStreamFromPed(ped) end

---@param x number
---@param y number
---@param z number
function PlayStreamFromPosition(x, y, z) end

---@param vehicle integer
function PlayStreamFromVehicle(vehicle) end

function PlayStreamFrontend() end

---@param sceneId integer
---@return boolean
function PlaySynchronizedAudioEvent(sceneId) end

---@param camera integer
---@param scene integer
---@param animName string
---@param animDictionary string
---@return boolean
function PlaySynchronizedCamAnim(camera, scene, animName, animDictionary) end

---@param entity Entity
---@param syncedScene integer
---@param animation string
---@param propName string
---@param p4 number
---@param p5 number
---@param p6 unknown
---@param p7 number
---@return boolean
function PlaySynchronizedEntityAnim(entity, syncedScene, animation, propName, p4, p5, p6, p7) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 unknown
---@param p5 unknown
---@param p8 number
---@param p9 number
---@param p10 unknown
---@param p11 number
---@return boolean
---@return unknown p6
---@return unknown p7
function PlaySynchronizedMapEntityAnim(p0, p1, p2, p3, p4, p5, p8, p9, p10, p11) end

---@param ped Ped
---@param p1 integer
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 boolean
function PlayTennisDiveAnim(ped, p1, p2, p3, p4, p5) end

---@param ped Ped
---@param animDict string
---@param animName string
---@param p3 number
---@param p4 number
---@param p5 boolean
function PlayTennisSwingAnim(ped, animDict, animName, p3, p4, p5) end

---@param vehicle integer
---@param doorIndex integer
function PlayVehicleDoorCloseSound(vehicle, doorIndex) end

---@param vehicle integer
---@param doorIndex integer
function PlayVehicleDoorOpenSound(vehicle, doorIndex) end

---@param cam integer
---@param x number
---@param y number
---@param z number
function PointCamAtCoord(cam, x, y, z) end

---@param cam integer
---@param entity Entity
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param p5 boolean
function PointCamAtEntity(cam, entity, offsetX, offsetY, offsetZ, p5) end

---@param cam integer
---@param ped Ped
---@param boneIndex integer
---@param x number
---@param y number
---@param z number
---@param p6 boolean
function PointCamAtPedBone(cam, ped, boneIndex, x, y, z, p6) end

---@param vehicle integer
function PopOutVehicleWindscreen(vehicle) end

---@return integer
function PopScaleformMovieFunction() end

function PopScaleformMovieFunctionVoid() end

function PopTimecycleModifier() end

function PopulateNow() end

---@param base number
---@param exponent number
---@return number
function Pow(base, exponent) end

---@param srl string
function PrefetchSrl(srl) end

function PreloadBusyspinner() end

---@param name string
function PreloadCloudHat(name) end

---@param displaySubtitles boolean
---@param addToBriefScreen boolean
---@param cloneConversation boolean
---@param interruptible boolean
function PreloadScriptConversation(displaySubtitles, addToBriefScreen, cloneConversation, interruptible) end

---@param displaySubtitles boolean
---@param addToBriefScreen boolean
function PreloadScriptPhoneConversation(displaySubtitles, addToBriefScreen) end

---@param model Hash|string
function PreloadVehicleAudio(model) end

---@param model Hash|string
function PreloadVehicleAudioBank(model) end

---@param p0 unknown
---@param modType integer
---@param p2 unknown
function PreloadVehicleMod(p0, modType, p2) end

---@param alarmName string
---@return boolean
function PrepareAlarm(alarmName) end

---@param lightType integer
---@param flags integer
---@param x number
---@param y number
---@param z number
---@param r integer
---@param g integer
---@param b integer
---@param intensity number
function PrepareLight(lightType, flags, x, y, z, r, g, b, intensity) end

---@param eventName string
---@return boolean
function PrepareMusicEvent(eventName) end

---@param audioEvent string
---@param startOffsetMs integer
---@return boolean
function PrepareSynchronizedAudioEvent(audioEvent, startOffsetMs) end

---@param sceneId integer
---@param audioEvent string
---@return boolean
function PrepareSynchronizedAudioEventForScene(sceneId, audioEvent) end

---@param statHash Hash|string
---@param value number
---@param p2 integer
function PresenceEventUpdatestatFloat(statHash, value, p2) end

---@param statHash Hash|string
---@param value integer
---@param p2 integer
function PresenceEventUpdatestatInt(statHash, value, p2) end

---@param timecycleModifierName string
function PresetInteriorAmbientCache(timecycleModifierName) end

---@param object integer
---@param p1 boolean
---@param p2 boolean
function PreventCollectionOfPortablePickup(object, p1, p2) end

---@param p2 string
---@return string
---@return integer p0
---@return integer p1
function ProcessCashGift(p2) end

---@param entity Entity
function ProcessEntityAttachments(entity) end

---@param blip integer
function PulseBlip(blip) end

---@param scaleform integer
---@param methodName string
---@return boolean
function PushScaleformMovieFunction(scaleform, methodName) end

---@param hudComponent integer
---@param methodName string
---@return boolean
function PushScaleformMovieFunctionFromHudComponent(hudComponent, methodName) end

---@param functionName string
---@return boolean
function PushScaleformMovieFunctionN(functionName) end

---@param value boolean
function PushScaleformMovieFunctionParameterBool(value) end

---@param value number
function PushScaleformMovieFunctionParameterFloat(value) end

---@param value integer
function PushScaleformMovieFunctionParameterInt(value) end

---@param string string
function PushScaleformMovieFunctionParameterString(string) end

---@param value boolean
function PushScaleformMovieMethodParameterBool(value) end

---@param string string
function PushScaleformMovieMethodParameterButtonName(string) end

---@param value number
function PushScaleformMovieMethodParameterFloat(value) end

---@param value integer
function PushScaleformMovieMethodParameterInt(value) end

---@param string string
function PushScaleformMovieMethodParameterString(string) end

---@param string string
function PushScaleformMovieMethodParameterString_2(string) end

function PushTimecycleModifier() end

---@param p0 unknown
---@return unknown
function QueryMovieMeshSetState(p0) end

---@return boolean
function QueueMissionRepeatLoad() end

---@return boolean
function QueueMissionRepeatSave() end

---@param scanForSaving boolean
---@return boolean
function QueueOperationToCreateSortedListOfPhotos(scanForSaving) end

function QuitGame() end

---@param x number
---@param y number
---@param z number
---@return unknown
function RaceGalleryAddBlip(x, y, z) end

---@param toggle boolean
function RaceGalleryFullscreen(toggle) end

---@param spriteId integer
function RaceGalleryNextBlipSprite(spriteId) end

---@param vehicle integer
---@param instantlyRaise boolean
function RaiseConvertibleRoof(vehicle, instantlyRaise) end

---@param vehicle integer
function RaiseLowerableWheels(vehicle) end

---@param vehicle integer
function RaiseRetractableWheels(vehicle) end

---@param x number
---@param y number
---@param z number
---@param radius number
function RecordBrokenGlass(x, y, z, radius) end

---@param ped Ped
---@return boolean
function RefillAmmoInstantly(ped) end

function RefreshClosestOceanShoreline() end

---@param interiorID integer
function RefreshInterior(interiorID) end

---@param p0 integer
---@return boolean
function RefreshPlayerListStats(p0) end

function RefreshWaypoint() end

---@param factory function
function RegisterArchetypes(factory) end

---@param name string
---@return unknown p0
function RegisterBoolToSave(name) end

---@param cutsceneEntity Entity
---@param cutsceneEntName string
---@param p2 integer
---@param modelHash Hash|string
---@param p4 integer
function RegisterEntityForCutscene(cutsceneEntity, cutsceneEntName, p2, modelHash, p4) end

---@param name string
---@return unknown p0
function RegisterEnumToSave(name) end

---@param name string
---@return unknown p0
function RegisterFloatToSave(name) end

---@param fileName string
function RegisterFontFile(fileName) end

---@param fontName string
---@return integer
function RegisterFontId(fontName) end

---@param ped Ped
---@param radius number
function RegisterHatedTargetsAroundPed(ped, radius) end

---@param name string
---@return unknown p0
function RegisterInt64ToSave(name) end

---@param name string
---@return unknown p0
function RegisterIntToSave(name) end

---@param commandString string
---@param description string
---@param defaultMapper string
---@param defaultParameter string
function RegisterKeyMapping(commandString, description, defaultMapper, defaultParameter) end

---@param name string
---@param p1 boolean
---@return boolean
function RegisterNamedRendertarget(name, p1) end

function RegisterNoirScreenEffectThisFrame() end

---@param scriptName string
---@param modelHash Hash|string
---@param p2 integer
---@param activationRange number
---@param p4 integer
---@param p5 integer
function RegisterObjectScriptBrain(scriptName, modelHash, p2, activationRange, p4, p5) end

---@param ped Ped
---@return integer
function RegisterPedheadshot(ped) end

---@param ped Ped
---@return integer
function RegisterPedheadshot_3(ped) end

---@param ped Ped
---@return integer
function RegisterPedheadshotTransparent(ped) end

---@param numSections integer
---@param radius number
---@param diffuseTextureName string
---@param normalMapName string
---@param distanceMappingScale number
---@param uvScaleX number
---@param uvScaleY number
---@param specularFresnel number
---@param specularFalloff number
---@param specularIntensity number
---@param bumpiness number
---@param color integer
---@return integer
function RegisterRopeData(numSections, radius, diffuseTextureName, normalMapName, distanceMappingScale, uvScaleX, uvScaleY, specularFresnel, specularFalloff, specularIntensity, bumpiness, color) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p5 unknown
---@param p6 unknown
---@return unknown
---@return unknown p4
function RegisterSaveHouse(p0, p1, p2, p3, p5, p6) end

---@param inChargeOfAudio boolean
function RegisterScriptWithAudio(inChargeOfAudio) end

---@param resourceName string
---@param fileName string
---@param cacheString string
function RegisterStreamingFileFromCache(resourceName, fileName, cacheString) end

---@param kvsKey string
function RegisterStreamingFileFromKvs(kvsKey) end

---@param registerAs string
---@param url string
function RegisterStreamingFileFromUrl(registerAs, url) end

function RegisterSynchronisedScriptSpeech() end

---@param ped Ped
---@param target Ped
function RegisterTarget(ped, target) end

---@param name string
---@return unknown p0
function RegisterTextLabelToSave(name) end

---@param name string
---@return unknown p0
function RegisterTextLabelToSave_2(name) end

---@param trackIndex integer
---@param trackNode integer
---@param newIndex integer
---@param newNode integer
---@param direction boolean
---@return integer
function RegisterTrackJunction(trackIndex, trackNode, newIndex, newNode, direction) end

---@param scriptName string
---@param activationRange number
---@param p2 integer
function RegisterWorldPointScriptBrain(scriptName, activationRange, p2) end

function ReleaseAllCommerceItemImages() end

function ReleaseAmbientAudioBank() end

---@param binkMovie integer
function ReleaseBinkMovie(binkMovie) end

function ReleaseControlOfFrontend() end

function ReleaseMissionAudioBank() end

---@param movieMeshSet integer
function ReleaseMovieMeshSet(movieMeshSet) end

---@param name string
---@return boolean
function ReleaseNamedRendertarget(name) end

---@param audioBank string
function ReleaseNamedScriptAudioBank(audioBank) end

---@param id integer
function ReleasePedheadshotImgUpload(id) end

---@param ped Ped
function ReleasePedPreloadPropData(ped) end

---@param ped Ped
function ReleasePedPreloadVariationData(ped) end

---@param vehicle integer
function ReleasePreloadMods(vehicle) end

function ReleaseScriptAudioBank() end

---@param entity Entity
function ReleaseScriptGuidFromEntity(entity) end

---@param soundId integer
function ReleaseSoundId(soundId) end

function ReleaseWeaponAudio() end

function ReloadMapMenu() end

---@return boolean
function RemoteCheatDetected() end

---@param asset string
function RemoveActionModeAsset(asset) end

---@param zoneId integer
---@return boolean
function RemoveAirDefenseZone(zoneId) end

function RemoveAllAirDefenseZones() end

function RemoveAllCoverBlockingAreas() end

---@param ped Ped
---@param p1 boolean
function RemoveAllPedWeapons(ped, p1) end

---@param pickupHash Hash|string
function RemoveAllPickupsOfType(pickupHash) end

---@param weaponHash Hash|string
---@param explode boolean
function RemoveAllProjectilesOfType(weaponHash, explode) end

---@param p0 boolean
function RemoveAllShockingEvents(p0) end

---@param entity Entity
function RemoveAllStickyBombsFromEntity(entity) end

---@param animDict string
function RemoveAnimDict(animDict) end

---@param animSet string
function RemoveAnimSet(animSet) end

---@return integer blip
function RemoveBlip() end

---@param clipSet string
function RemoveClipSet(clipSet) end

---@param coverpoint integer
function RemoveCoverPoint(coverpoint) end

---@param p0 integer
function RemoveCurrentRise(p0) end

---@param cutsceneName string
function RemoveCutFile(cutsceneName) end

function RemoveCutscene() end

---@param decal integer
function RemoveDecal(decal) end

---@param obj integer
function RemoveDecalsFromObject(obj) end

---@param obj integer
---@param x number
---@param y number
---@param z number
function RemoveDecalsFromObjectFacing(obj, x, y, z) end

---@param vehicle integer
function RemoveDecalsFromVehicle(vehicle) end

---@param x number
---@param y number
---@param z number
---@param range number
function RemoveDecalsInRange(x, y, z, range) end

---@param p0 unknown
function RemoveDispatchSpawnBlockingArea(p0) end

---@param doorHash Hash|string
function RemoveDoorFromSystem(doorHash) end

---@param handle integer
function RemoveDryVolume(handle) end

---@param entity Entity
---@param fadeOut number
function RemoveEntityFromAudioMixGroup(entity, fadeOut) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function RemoveForcedObject(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
function RemoveFromItemset(p0, p1) end

---@param groupId integer
function RemoveGroup(groupId) end

---@param configName string
function RemoveHealthConfig(configName) end

---@param iplName string
function RemoveIpl(iplName) end

function RemoveLoadingPrompt() end

---@param modelHash Hash|string
function RemoveModelFromCreatorBudget(modelHash) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param model Hash|string
---@param p5 boolean
function RemoveModelHide(x, y, z, radius, model, p5) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param originalModel Hash|string
---@param newModel Hash|string
---@param p6 boolean
function RemoveModelSwap(x, y, z, radius, originalModel, newModel, p6) end

---@param gamerTagId integer
function RemoveMpGamerTag(gamerTagId) end

function RemoveMultiplayerBankCash() end

function RemoveMultiplayerHudCash() end

function RemoveMultiplayerWalletCash() end

---@param fxName string
function RemoveNamedPtfxAsset(fxName) end

---@param p0 unknown
function RemoveNavmeshBlockingObject(p0) end

function RemoveNavmeshRequiredRegions() end

---@param notificationId integer
function RemoveNotification(notificationId) end

---@param object integer
function RemoveObjectHighDetailModel(object) end

---@param ptfxHandle integer
---@param p1 boolean
function RemoveParticleFx(ptfxHandle, p1) end

---@param entity Entity
function RemoveParticleFxFromEntity(entity) end

---@param X number
---@param Y number
---@param Z number
---@param radius number
function RemoveParticleFxInRange(X, Y, Z, radius) end

---@param ped Ped
---@param toggle boolean
function RemovePedDefensiveArea(ped, toggle) end

---@return Ped ped
function RemovePedElegantly() end

---@param ped Ped
function RemovePedFromGroup(ped) end

---@param ped Ped
---@param instantly boolean
function RemovePedHelmet(ped, instantly) end

---@param ped Ped
function RemovePedPreferredCoverSet(ped) end

---@param ped Ped
function RemovePedScubaGearNow(ped) end

---@param pickup integer
function RemovePickup(pickup) end

---@param cargobob integer
function RemovePickUpRopeForCargobob(cargobob) end

---@param player integer
---@param p2 boolean
function RemovePlayerHelmet(player, p2) end

---@param id integer
---@param p1 boolean
function RemovePopMultiplierArea(id, p1) end

---@param id integer
---@param p1 boolean
function RemovePopMultiplierSphere(id, p1) end

---@param portalSettingsName string
function RemovePortalSettingsOverride(portalSettingsName) end

function RemovePtfxAsset() end

---@param groupHash Hash|string
function RemoveRelationshipGroup(groupHash) end

---@param origTxd string
---@param origTxn string
function RemoveReplaceTexture(origTxd, origTxn) end

---@param speedzone integer
---@return boolean
function RemoveRoadNodeSpeedZone(speedzone) end

---@param hudComponent integer
function RemoveScaleformScriptHudMovie(hudComponent) end

---@param scenarioBlockingIndex integer
---@param bNetwork boolean
function RemoveScenarioBlockingArea(scenarioBlockingIndex, bNetwork) end

function RemoveScenarioBlockingAreas() end

---@param fireHandle integer
function RemoveScriptFire(fireHandle) end

---@param event integer
---@return boolean
function RemoveShockingEvent(event) end

function RemoveShockingEventSpawnBlockingAreas() end

---@param speedzone integer
---@return boolean
function RemoveSpeedZone(speedzone) end

---@param hash Hash|string
---@param p1 boolean
function RemoveStealthKill(hash, p1) end

---@param asset string
function RemoveStealthModeAsset(asset) end

---@param p0 string
function RemoveTcmodifierOverride(p0) end

---@param modifierName string
function RemoveTimecycleModifier(modifierName) end

---@param modifierName string
---@param varName string
function RemoveTimecycleModifierVar(modifierName, varName) end

---@param junctionIndex integer
---@return boolean
function RemoveTrackJunction(junctionIndex) end

---@param vehicleAsset integer
function RemoveVehicleAsset(vehicleAsset) end

---@param p0 unknown
function RemoveVehicleCombatAvoidanceArea(p0) end

---@param vehicle integer
---@param p1 integer
function RemoveVehicleCrewEmblem(vehicle, p1) end

---@param vehicle integer
function RemoveVehicleHighDetailModel(vehicle) end

---@param vehicle integer
---@param modType integer
function RemoveVehicleMod(vehicle, modType) end

---@param recording integer
---@param script string
function RemoveVehicleRecording(recording, script) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param unk unknown
function RemoveVehiclesFromGeneratorsInArea(x1, y1, z1, x2, y2, z2, unk) end

---@param vehicle integer
function RemoveVehicleShadowEffect(vehicle) end

---@param vehicle integer
function RemoveVehicleStuckCheck(vehicle) end

---@param vehicle integer
function RemoveVehicleUpsidedownCheck(vehicle) end

---@param vehicle integer
---@param windowIndex integer
function RemoveVehicleWindow(vehicle, windowIndex) end

function RemoveWarningMessageListItems() end

---@param name string
function RemoveWaypointRecording(name) end

---@param weaponHash Hash|string
function RemoveWeaponAsset(weaponHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@param componentHash Hash|string
function RemoveWeaponComponentFromPed(ped, weaponHash, componentHash) end

---@param weaponObject integer
---@param addonHash Hash|string
function RemoveWeaponComponentFromWeaponObject(weaponObject, addonHash) end

---@param ped Ped
---@param weaponHash Hash|string
function RemoveWeaponFromPed(ped, weaponHash) end

---@param x number
---@param y number
---@param z number
---@param colorIndex integer
function RenderFakePickupGlow(x, y, z, colorIndex) end

---@param bShouldApplyAcrossAllThreads boolean
---@param distanceToBlend number
---@param blendType integer
function RenderFirstPersonCam(bShouldApplyAcrossAllThreads, distanceToBlend, blendType) end

---@param render boolean
---@param ease boolean
---@param easeTime integer
---@param easeCoordsAnim boolean
---@param p4 boolean
function RenderScriptCams(render, ease, easeTime, easeCoordsAnim, p4) end

---@param hudColorIndex integer
---@param hudColorIndex2 integer
function ReplaceHudColour(hudColorIndex, hudColorIndex2) end

---@param hudColorIndex integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function ReplaceHudColourWithRgba(hudColorIndex, r, g, b, a) end

---@return number
function ReplayFreeCamGetMaxRange() end

---@param player integer
---@param crimeType integer
---@param wantedLvlThresh integer
function ReportCrime(player, crimeType, wantedLvlThresh) end

---@param player integer
function ReportPoliceSpottedPlayer(player) end

---@param asset string
function RequestActionModeAsset(asset) end

---@param x number
---@param y number
---@param z number
function RequestAdditionalCollisionAtCoord(x, y, z) end

---@param gxt string
---@param slot integer
function RequestAdditionalText(gxt, slot) end

---@param gxt string
---@param slot integer
function RequestAdditionalText_2(gxt, slot) end

---@param gxt string
---@param slot integer
function RequestAdditionalTextForDlc(gxt, slot) end

---@param bankName string
---@param bOverNetwork boolean
---@return boolean
function RequestAmbientAudioBank(bankName, bOverNetwork) end

---@param animDict string
function RequestAnimDict(animDict) end

---@param animSet string
function RequestAnimSet(animSet) end

---@param clipSet string
function RequestClipSet(clipSet) end

---@param x number
---@param y number
---@param z number
function RequestCollisionAtCoord(x, y, z) end

---@param model Hash|string
function RequestCollisionForModel(model) end

---@param index integer
---@return boolean
function RequestCommerceItemImage(index) end

---@param cutsceneName string
function RequestCutFile(cutsceneName) end

---@param cutsceneName string
---@param flags integer
function RequestCutscene(cutsceneName, flags) end

---@param cutsceneName string
---@param playbackFlags integer
---@param flags integer
function RequestCutsceneEx(cutsceneName, playbackFlags, flags) end

---@param cutsceneName string
---@param playbackFlags integer
---@param flags integer
function RequestCutsceneWithPlaybackList(cutsceneName, playbackFlags, flags) end

---@param hudComponent integer
function RequestHudScaleform(hudComponent) end

---@param interior integer
---@param roomName string
function RequestInteriorRoomByName(interior, roomName) end

---@param iplName string
function RequestIpl(iplName) end

---@param model Hash|string
function RequestMenuPedModel(model) end

---@param bankName string
---@param bOverNetwork boolean
---@return boolean
function RequestMissionAudioBank(bankName, bOverNetwork) end

---@param model Hash|string
function RequestModel(model) end

---@param interior integer
---@param roomName string
function RequestModelsInRoom(interior, roomName) end

---@param fxName string
function RequestNamedPtfxAsset(fxName) end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return boolean
function RequestPathsPreferAccurateBoundingstruct(x1, y1, x2, y2) end

---@param id integer
---@return boolean
function RequestPedheadshotImgUpload(id) end

---@param ped Ped
---@param p1 boolean
function RequestPedVehicleVisibilityTracking(ped, p1) end

---@param ped Ped
function RequestPedVisibilityTracking(ped) end

function RequestPtfxAsset() end

---@param setName string
---@return boolean
function RequestResourceFileSet(setName) end

---@param scaleformName string
---@return integer
function RequestScaleformMovie(scaleformName) end

---@param scaleformName string
---@return integer
function RequestScaleformMovie_2(scaleformName) end

---@param scaleformName string
---@return integer
function RequestScaleformMovie3(scaleformName) end

---@param scaleformName string
---@return integer
function RequestScaleformMovieInstance(scaleformName) end

---@param scaleformName string
---@return integer
function RequestScaleformMovieInteractive(scaleformName) end

---@param scaleformName string
---@return integer
function RequestScaleformMovieSkipRenderWhilePaused(scaleformName) end

---@param scaleformName string
---@return integer
function RequestScaleformMovieWithIgnoreSuperWidescreen(scaleformName) end

---@param hudComponent integer
function RequestScaleformScriptHudMovie(hudComponent) end

---@param scriptName string
function RequestScript(scriptName) end

---@param bankName string
---@param bOverNetwork boolean
---@return boolean
function RequestScriptAudioBank(bankName, bOverNetwork) end

---@param scriptHash Hash|string
function RequestScriptWithNameHash(scriptHash) end

---@param asset string
function RequestStealthModeAsset(asset) end

---@param scriptHash Hash|string
function RequestStreamedScript(scriptHash) end

---@param textureDict string
---@param p1 boolean
function RequestStreamedTextureDict(textureDict, p1) end

---@param ped Ped
---@param name string
---@return boolean
function RequestTaskMoveNetworkStateTransition(ped, name) end

---@param opponentPed Ped
function RequestTennisBanks(opponentPed) end

---@param vehicleHash Hash|string
---@param vehicleAsset integer
function RequestVehicleAsset(vehicleHash, vehicleAsset) end

---@param vehicle integer
function RequestVehicleDashboardScaleformMovie(vehicle) end

---@param vehicle integer
function RequestVehicleHighDetailModel(vehicle) end

function RequestVehiclePhoneExplosion() end

---@param recording integer
---@param script string
function RequestVehicleRecording(recording, script) end

---@param name string
function RequestWaypointRecording(name) end

---@param weaponHash Hash|string
---@param p1 integer
---@param p2 integer
function RequestWeaponAsset(weaponHash, p1, p2) end

---@param weaponObject Entity
function RequestWeaponHighDetailModel(weaponObject) end

---@param amount integer
function ReserveNetworkLocalObjects(amount) end

---@param amount integer
function ReserveNetworkLocalPeds(amount) end

---@param amount integer
function ReserveNetworkLocalVehicles(amount) end

---@param amount integer
function ReserveNetworkMissionObjects(amount) end

---@param amount integer
function ReserveNetworkMissionPeds(amount) end

---@param amount integer
function ReserveNetworkMissionVehicles(amount) end

function ResetAiMeleeWeaponDamageModifier() end

function ResetAiWeaponDamageModifier() end

function ResetBenchmarkRecording() end

function ResetCurrentIntensity() end

function ResetDeepOceanScaler() end

function ResetDispatchIdealSpawnDistance() end

function ResetDispatchSpawnBlockingAreas() end

function ResetDispatchSpawnLocation() end

---@param p0 unknown
function ResetDispatchTimeBetweenSpawnAttempts(p0) end

function ResetEditorValues() end

---@param entity Entity
function ResetEntityAlpha(entity) end

function ResetEntityDrawOutlineRenderTechnique() end

function ResetExclusiveScenarioGroup() end

function ResetExtraTimecycleModifierStrength() end

function ResetFlyThroughWindscreenParams() end

function ResetGhostedEntityAlpha() end

---@param flagIndex integer
function ResetGlobalActionscriptFlag(flagIndex) end

---@param groupHandle integer
function ResetGroupFormationDefaultSpacing(groupHandle) end

---@param id integer
function ResetHudComponentValues(id) end

function ResetInputMappingScheme() end

function ResetLocalplayerState() end

---@param mapDataHash integer
---@param entityInternalIdx integer
---@return boolean
function ResetMapdataEntityMatrix(mapDataHash, entityInternalIdx) end

---@param index integer
function ResetMapZoomDataLevel(index) end

---@param name string
function ResetParticleFxAssetOldToNew(name) end

---@param name string
function ResetParticleFxOverride(name) end

function ResetPausedRenderphases() end

---@param ped Ped
function ResetPedAudioFlags(ped) end

---@param ped Ped
function ResetPedInVehicleContext(ped) end

---@param ped Ped
function ResetPedLastVehicle(ped) end

---@param modelHash Hash|string
function ResetPedModelPersonality(modelHash) end

---@param ped Ped
---@param transitionSpeed number
function ResetPedMovementClipset(ped, transitionSpeed) end

---@param ped Ped
---@param flags integer
function ResetPedRagdollBlockingFlags(ped, flags) end

---@param ped Ped
function ResetPedRagdollTimer(ped) end

---@param ped Ped
function ResetPedStrafeClipset(ped) end

---@param ped Ped
function ResetPedVisibleDamage(ped) end

---@param ped Ped
function ResetPedWeaponMovementClipset(ped) end

---@param player integer
function ResetPlayerArrestState(player) end

---@param player integer
function ResetPlayerInputGait(player) end

---@param player integer
function ResetPlayerStamina(player) end

function ResetReticuleValues() end

function ResetScenarioGroupsEnabled() end

function ResetScenarioTypesEnabled() end

function ResetScriptGfxAlign() end

---@param player integer
---@param normalizedValue number
---@param p2 boolean
function ResetSpecialAbilityControlsCinematic(player, normalizedValue, p2) end

function ResetTrevorRage() end

---@param vehicle integer
function ResetVehiclePedsCanStandOnTopFlag(vehicle) end

---@param vehicle integer
function ResetVehicleStartupRevSound(vehicle) end

---@param vehicle integer
---@param nullAttributes integer
function ResetVehicleStuckTimer(vehicle, nullAttributes) end

---@param vehicle integer
---@param toggle boolean
function ResetVehicleWheels(vehicle, toggle) end

---@param player integer
function ResetWantedLevelDifficulty(player) end

function ResetWater() end

function ResetWavesIntensity() end

function ResetWorldBoundaryForPlayer() end

---@param zoom number
function RespondingAsTemp(zoom) end

---@param menuHash Hash|string
---@param highlightedTab integer
function RestartFrontendMenu(menuHash, highlightedTab) end

function RestartGame() end

function RestartScriptedConversation() end

---@param player integer
---@param percentage number
function RestorePlayerStamina(player, percentage) end

---@param ped Ped
function ResurrectPed(ped) end

---@param cargobob integer
function RetractCargobobHook(cargobob) end

---@param p0 integer
---@return integer
function ReturnTwo(p0) end

---@return integer
function ReturnZero() end

---@param ped Ped
function ReviveInjuredPed(ped) end

---@return string
function RockstarMessageGetString() end

---@param vehicle integer
---@param windowIndex integer
function RollDownWindow(vehicle, windowIndex) end

---@param vehicle integer
function RollDownWindows(vehicle) end

---@param vehicle integer
---@param windowIndex integer
function RollUpWindow(vehicle, windowIndex) end

---@return boolean
function RopeAreTexturesLoaded() end

---@param ropeId integer
function RopeConvertToSimple(ropeId) end

---@param toggle boolean
---@return integer ropeId
function RopeDrawShadowEnabled(toggle) end

---@param ropeId integer
---@param length number
function RopeForceLength(ropeId, length) end

---@param ropeId integer
---@return number
function RopeGetDistanceBetweenEnds(ropeId) end

function RopeLoadTextures() end

---@param ropeId integer
---@param length number
function RopeResetLength(ropeId, length) end

---@param ropeId integer
---@param p1 unknown
function RopeSetUpdateOrder(ropeId, p1) end

---@param ropeId integer
function RopeSetUpdatePinverts(ropeId) end

function RopeUnloadTextures() end

---@param value number
---@return integer
function Round(value) end

function SaveBenchmarkRecording() end

---@param unused integer
---@return boolean
function SaveHighQualityPhoto(unused) end

---@return boolean
function SaveRecordingClip() end

---@param value boolean
function ScaleformMovieMethodAddParamBool(value) end

---@param value number
function ScaleformMovieMethodAddParamFloat(value) end

---@param value integer
function ScaleformMovieMethodAddParamInt(value) end

---@param value integer
function ScaleformMovieMethodAddParamIntString(value) end

---@param value integer
function ScaleformMovieMethodAddParamLatestBriefString(value) end

---@param string string
function ScaleformMovieMethodAddParamLiteralString(string) end

---@param string string
function ScaleformMovieMethodAddParamPlayerNameString(string) end

---@param string string
function ScaleformMovieMethodAddParamTextureNameString(string) end

---@param string string
function ScaleformMovieMethodAddParamTextureNameString_2(string) end

function ScEmailMessageClearRecipList() end

---@return integer networkHandle
function ScEmailMessagePushGamerToRecipList() end

---@param name string
---@return boolean
function ScGamerdataGetBool(name) end

---@param name string
---@return boolean
---@return number outValue
function ScGamerdataGetFloat(name) end

---@param name string
---@return boolean
---@return integer outValue
function ScGamerdataGetInt(name) end

---@param token integer
---@return boolean
function ScGetCheckStringStatus(token) end

---@param achievement integer
---@return boolean
function ScGetHasAchievementBeenPassed(achievement) end

---@param name string
---@return boolean
function ScGetIsProfileAttributeSet(name) end

---@return string
function ScGetNickname() end

---@param token integer
---@return boolean
function ScHasCheckStringTaskCompleted(token) end

---@param offset integer
---@param limit integer
function ScInboxGetEmails(offset, limit) end

---@param msgIndex integer
---@return boolean
function ScInboxGetMessageIsReadAtIndex(msgIndex) end

---@param msgIndex integer
---@return Hash
function ScInboxGetMessageTypeAtIndex(msgIndex) end

---@return integer
function ScInboxGetTotalNumMessages() end

---@param p0 integer
---@return boolean
function ScInboxMessageDoApply(p0) end

---@param index integer
---@return boolean
---@return integer outData
function ScInboxMessageGetBountyData(index) end

---@param p0 integer
---@param p1 string
---@return boolean
function ScInboxMessageGetDataBool(p0, p1) end

---@param p0 integer
---@param context string
---@return boolean
---@return integer out
function ScInboxMessageGetDataInt(p0, context) end

---@param p0 integer
---@param context string
---@param out string
---@return boolean
function ScInboxMessageGetDataString(p0, context, out) end

---@param p0 integer
---@return string
function ScInboxMessageGetString(p0) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function ScInboxMessageGetUgcdata(p0) end

---@param msgIndex integer
---@return Hash
function ScInboxMessageInit(msgIndex) end

---@param p0 integer
---@return boolean
function ScInboxMessagePop(p0) end

---@param p0 integer
---@return boolean
function ScInboxMessagePush(p0) end

---@return integer networkHandle
function ScInboxMessagePushGamerToEventRecipList() end

---@param data string
---@return boolean
function ScInboxMessageSendBountyPresenceEvent(data) end

---@param data string
function ScInboxMessageSendUgcStatUpdateEvent(data) end

---@param plateText string
---@param plateData string
---@return boolean
---@return integer tokenOut
function ScLicenseplateAdd(plateText, plateData) end

---@param token integer
---@return boolean
function ScLicenseplateGetAddIsPending(token) end

---@param token integer
---@return integer
function ScLicenseplateGetAddStatus(token) end

---@param token integer
---@return integer
function ScLicenseplateGetCount(token) end

---@param token integer
---@return boolean
function ScLicenseplateGetIsvalidIsPending(token) end

---@param token integer
---@return integer
function ScLicenseplateGetIsvalidStatus(token) end

---@param token integer
---@param plateIndex integer
---@return string
function ScLicenseplateGetPlate(token, plateIndex) end

---@param token integer
---@param plateIndex integer
---@return string
function ScLicenseplateGetPlateData(token, plateIndex) end

---@param plateText string
---@return boolean
---@return integer tokenOut
function ScLicenseplateIsvalid(plateText) end

---@param oldPlateText string
---@param newPlateText string
---@param plateData string
---@return boolean
function ScLicenseplateSetPlateData(oldPlateText, newPlateText, plateData) end

---@return boolean
function ScPresenceAttrSetFloat() end

---@param attrHash Hash|string
---@param value integer
---@return boolean
function ScPresenceAttrSetInt(attrHash, value) end

---@param attrHash Hash|string
---@param value string
---@return boolean
function ScPresenceAttrSetString(attrHash, value) end

---@param string string
---@return boolean
---@return integer token
function ScProfanityCheckString(string) end

---@param string string
---@return boolean
---@return integer token
function ScProfanityCheckUgcString(string) end

---@param token integer
---@return boolean
function ScProfanityGetCheckIsPending(token) end

---@param token integer
---@return boolean
function ScProfanityGetCheckIsValid(token) end

---@param token integer
---@return boolean
function ScProfanityGetStringPassed(token) end

---@param token integer
---@return integer
function ScProfanityGetStringStatus(token) end

---@param horizontalAlign integer
---@param verticalAlign integer
function ScreenDrawPositionBegin(horizontalAlign, verticalAlign) end

function ScreenDrawPositionEnd() end

---@param x number
---@param y number
---@param w number
---@param h number
function ScreenDrawPositionRatio(x, y, w, h) end

---@param toggle boolean
function ScriptIsMovingMobilePhoneOffscreen(toggle) end

---@param override boolean
---@param windElevationHashName Hash|string
function ScriptOverridesWindElevation(override, windElevationHashName) end

---@param player integer
---@return boolean
---@return integer p1
---@return integer p2
function ScriptRaceGetPlayerSplitTime(player) end

---@param numCheckpoints integer
---@param numLaps integer
---@param numPlayers integer
---@param localPlayer integer
function ScriptRaceInit(numCheckpoints, numLaps, numPlayers, localPlayer) end

---@param ped Ped
---@param checkpoint integer
---@param lap integer
---@param time integer
function ScriptRacePlayerHitCheckpoint(ped, checkpoint, lap, time) end

function ScriptRaceShutdown() end

---@return integer
function ScriptThreadIteratorGetNextThreadId() end

function ScriptThreadIteratorReset() end

---@param string string
---@return boolean
---@return integer token
function ScStartCheckStringTask(string) end

---@return number
function SeethroughGetMaxThickness() end

function SeethroughReset() end

---@param red integer
---@param green integer
---@param blue integer
function SeethroughSetColorNear(red, green, blue) end

---@param distance number
function SeethroughSetFadeEndDistance(distance) end

---@param distance number
function SeethroughSetFadeStartDistance(distance) end

---@param index integer
---@param heatScale number
function SeethroughSetHeatscale(index, heatScale) end

---@param intensity number
function SeethroughSetHiLightIntensity(intensity) end

---@param noise number
function SeethroughSetHiLightNoise(noise) end

---@param thickness number
function SeethroughSetMaxThickness(thickness) end

---@param amount number
function SeethroughSetNoiseAmountMax(amount) end

---@param amount number
function SeethroughSetNoiseAmountMin(amount) end

---@param hitFlags integer
---@param precise boolean
---@return Entity
function SelectEntityAtCursor(hitFlags, precise) end

---@param fracX number
---@param fracY number
---@param hitFlags integer
---@param precise boolean
---@return Entity
function SelectEntityAtPos(fracX, fracY, hitFlags, precise) end

---@param duiObject integer
---@param jsonString string
function SendDuiMessage(duiObject, jsonString) end

---@param duiObject integer
---@param button string
function SendDuiMouseDown(duiObject, button) end

---@param duiObject integer
---@param x integer
---@param y integer
function SendDuiMouseMove(duiObject, x, y) end

---@param duiObject integer
---@param button string
function SendDuiMouseUp(duiObject, button) end

---@param duiObject integer
---@param deltaY integer
---@param deltaX integer
function SendDuiMouseWheel(duiObject, deltaY, deltaX) end

---@param jsonString string
---@return boolean
function SendLoadingScreenMessage(jsonString) end

---@param order integer
function Set_2dLayer(order) end

---@param value number
---@param maxValue number
function SetAbilityBarValue(value, maxValue) end

---@param visible boolean
function SetAbilityBarVisibilityInMultiplayer(visible) end

---@param achievement integer
---@param progress integer
---@return boolean
function SetAchievementProgress(achievement, progress) end

---@param achievement integer
---@param progress integer
---@return boolean
function SetAchievementProgression(achievement, progress) end

---@param object integer
---@param toggle boolean
function SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(object, toggle) end

---@param toggle boolean
function SetAggressiveHorns(toggle) end

---@param ped Ped
---@param range number
function SetAiBlipMaxDistance(ped, range) end

---@param ped Ped
---@param gangId integer
function SetAiBlipType(ped, gangId) end

---@param type integer
function SetAiGlobalPathNodesType(type) end

---@param value integer
function SetAimCooldown(value) end

---@param modifier number
function SetAiMeleeWeaponDamageModifier(modifier) end

---@param aircraft integer
---@param bombCount integer
function SetAircraftBombCount(aircraft, bombCount) end

---@param aircraft integer
---@param count integer
function SetAircraftCountermeasureCount(aircraft, count) end

---@param player integer
---@param multiplier number
function SetAirDragMultiplierForPlayersVehicle(player, multiplier) end

---@param value number
function SetAiWeaponDamageModifier(value) end

---@param active boolean
function SetAllLowPriorityVehicleGeneratorsActive(active) end

---@param toggle boolean
function SetAllowAbilityBarInMultiplayer(toggle) end

---@param allow boolean
function SetAllowCommaOnTextInput(allow) end

---@param toggle boolean
function SetAllPathsCacheBoundingstruct(toggle) end

---@param player integer
---@param toggle boolean
function SetAllRandomPedsFlee(player, toggle) end

---@param player integer
function SetAllRandomPedsFleeThisFrame(player) end

function SetAllVehicleGeneratorsActive() end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param p6 boolean
---@param p7 boolean
function SetAllVehicleGeneratorsActiveInArea(x1, y1, z1, x2, y2, z2, p6, p7) end

---@param p0 integer
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@return unknown
function SetAllVehiclesSpawn(p0, p1, p2, p3) end

---@param multiplier number
function SetAmbientPedRangeMultiplierThisFrame(multiplier) end

---@param p0 boolean
function SetAmbientPedsDropMoney(p0) end

---@param range number
function SetAmbientVehicleRangeMultiplierThisFrame(range) end

---@param ped Ped
---@param voiceName string
function SetAmbientVoiceName(ped, voiceName) end

---@param ped Ped
---@param hash Hash|string
function SetAmbientVoiceNameHash(ped, hash) end

---@param zoneListName string
---@param enabled boolean
---@param forceUpdate boolean
function SetAmbientZoneListState(zoneListName, enabled, forceUpdate) end

---@param ambientZone string
---@param enabled boolean
---@param forceUpdate boolean
function SetAmbientZoneListStatePersistent(ambientZone, enabled, forceUpdate) end

---@param zoneName string
---@param enabled boolean
---@param forceUpdate boolean
function SetAmbientZoneState(zoneName, enabled, forceUpdate) end

---@param zoneName string
---@param enabled boolean
---@param forceUpdate boolean
function SetAmbientZoneStatePersistent(zoneName, enabled, forceUpdate) end

---@param ped Ped
---@param weaponHash Hash|string
---@param ammo integer
---@return boolean
function SetAmmoInClip(ped, weaponHash, ammo) end

---@param animal Ped
---@param mood integer
function SetAnimalMood(animal, mood) end

---@param p0 unknown
---@param p1 boolean
---@param p2 unknown
---@param p3 boolean
function SetAnimLooped(p0, p1, p2, p3) end

---@param entity Entity
---@param p1 number
---@param p2 unknown
---@param p3 boolean
function SetAnimPhase(entity, p1, p2, p3) end

---@param entity Entity
---@param p1 number
---@param p2 unknown
---@param p3 boolean
function SetAnimPlaybackTime(entity, p1, p2, p3) end

---@param p0 unknown
---@param p1 number
---@param p2 unknown
---@param p3 boolean
function SetAnimRate(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 number
---@param p2 unknown
---@param p3 unknown
---@param p4 boolean
function SetAnimWeight(p0, p1, p2, p3, p4) end

---@param player integer
function SetAreasGeneratorOrientation(player) end

---@param state boolean
function SetArtificialLightsState(state) end

---@param toggle boolean
function SetArtificialLightsStateAffectsVehicles(toggle) end

---@param flagName string
---@param toggle boolean
function SetAudioFlag(flagName, toggle) end

---@param scene string
---@param variableName string
---@param value number
function SetAudioSceneVariable(scene, variableName, value) end

---@param timeMs integer
function SetAudioScriptCleanupTime(timeMs) end

---@param mode integer
function SetAudioSpecialEffectMode(mode) end

---@param submixId integer
---@param effectSlot integer
---@param paramIndex integer
---@param paramValue number
function SetAudioSubmixEffectParamFloat(submixId, effectSlot, paramIndex, paramValue) end

---@param submixId integer
---@param effectSlot integer
---@param paramIndex integer
---@param paramValue integer
function SetAudioSubmixEffectParamInt(submixId, effectSlot, paramIndex, paramValue) end

---@param submixId integer
---@param effectSlot integer
function SetAudioSubmixEffectRadioFx(submixId, effectSlot) end

---@param submixId integer
---@param outputSlot integer
---@param frontLeftVolume number
---@param frontRightVolume number
---@param rearLeftVolume number
---@param rearRightVolume number
---@param channel5Volume number
---@param channel6Volume number
function SetAudioSubmixOutputVolumes(submixId, outputSlot, frontLeftVolume, frontRightVolume, rearLeftVolume, rearRightVolume, channel5Volume, channel6Volume) end

---@param vehicle integer
---@param priority integer
function SetAudioVehiclePriority(vehicle, priority) end

---@param player integer
---@param toggle boolean
function SetAutoGiveParachuteWhenEnterPlane(player, toggle) end

---@param player integer
---@param toggle boolean
function SetAutoGiveScubaGearWhenExitVehicle(player, toggle) end

---@param toggle boolean
function SetBackfaceculling(toggle) end

---@param contentId string
---@param contentTypeName string
---@return boolean
function SetBalanceAddMachine(contentId, contentTypeName) end

---@param dataCount integer
---@param contentTypeName string
---@return boolean
---@return unknown data
function SetBalanceAddMachines(dataCount, contentTypeName) end

---@param player integer
function SetBeastModeActive(player) end

---@param toggleBigMap boolean
---@param showFullMap boolean
function SetBigmapActive(toggleBigMap, showFullMap) end

---@param vehicle integer
---@param x number
---@param y number
function SetBikeLeanAngle(vehicle, x, y) end

---@param vehicle integer
---@param x number
---@param y number
function SetBikeOnStand(vehicle, x, y) end

---@param name string
---@return integer
function SetBinkMovie(name) end

---@param binkMovie integer
---@param progress number
function SetBinkMovieProgress(binkMovie, progress) end

---@param name string
---@return integer
function SetBinkMovieRequested(name) end

---@param binkMovie integer
---@param progress number
function SetBinkMovieTime(binkMovie, progress) end

---@param binkMovie integer
---@param value number
function SetBinkMovieUnk(binkMovie, value) end

---@param binkMovie integer
---@param p1 boolean
function SetBinkMovieUnk_2(binkMovie, p1) end

---@param binkMovie integer
---@param value number
function SetBinkMovieVolume(binkMovie, value) end

---@param binkMovie integer
---@param shouldSkip boolean
function SetBinkShouldSkip(binkMovie, shouldSkip) end

---@param offset integer
---@return integer address
function SetBit(offset) end

---@param rangeStart integer
---@param rangeEnd integer
---@param p3 integer
---@return integer var
function SetBitsInRange(rangeStart, rangeEnd, p3) end

---@param state boolean
function SetBlackout(state) end

---@param blip integer
---@param alpha integer
function SetBlipAlpha(blip, alpha) end

---@param blip integer
---@param toggle boolean
function SetBlipAsFriendly(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipAsMissionCreatorBlip(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipAsShortRange(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipBright(blip, toggle) end

---@param blip integer
---@param index integer
function SetBlipCategory(blip, index) end

---@param blip integer
---@param toggle boolean
function SetBlipChecked(blip, toggle) end

---@param blip integer
---@param color integer
function SetBlipColour(blip, color) end

---@param blip integer
---@param posX number
---@param posY number
---@param posZ number
function SetBlipCoords(blip, posX, posY, posZ) end

---@param blip integer
---@param toggle boolean
function SetBlipCrew(blip, toggle) end

---@param blip integer
---@param displayId integer
function SetBlipDisplay(blip, displayId) end

---@param blip integer
---@param toggle boolean
function SetBlipDisplayIndicatorOnBlip(blip, toggle) end

---@param blip integer
---@param opacity integer
---@param duration integer
function SetBlipFade(blip, opacity, duration) end

---@param blip integer
---@param toggle boolean
function SetBlipFlashes(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipFlashesAlternate(blip, toggle) end

---@param blip integer
---@param interval integer
function SetBlipFlashInterval(blip, interval) end

---@param blip integer
---@param duration integer
function SetBlipFlashTimer(blip, duration) end

---@param blip integer
---@param toggle boolean
function SetBlipFriend(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipFriendly(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipHiddenOnLegend(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipHighDetail(blip, toggle) end

---@param blip integer
---@param gxtEntry string
function SetBlipNameFromTextFile(blip, gxtEntry) end

---@param blip integer
---@param player integer
function SetBlipNameToPlayerName(blip, player) end

---@param blip integer
---@param priority integer
function SetBlipPriority(blip, priority) end

---@param blip integer
---@param rotation integer
function SetBlipRotation(blip, rotation) end

---@param blip integer
---@param enabled boolean
function SetBlipRoute(blip, enabled) end

---@param blip integer
---@param colour integer
function SetBlipRouteColour(blip, colour) end

---@param blip integer
---@param scale number
function SetBlipScale(blip, scale) end

---@param blip integer
---@param xScale number
---@param yScale number
function SetBlipScaleTransformation(blip, xScale, yScale) end

---@param blip integer
---@param r integer
---@param g integer
---@param b integer
function SetBlipSecondaryColour(blip, r, g, b) end

---@param blip integer
---@param toggle boolean
function SetBlipShowCone(blip, toggle) end

---@param blip integer
---@param toggle boolean
function SetBlipShrink(blip, toggle) end

---@param blip integer
---@param spriteId integer
function SetBlipSprite(blip, spriteId) end

---@param blip integer
---@param heading number
function SetBlipSquaredRotation(blip, heading) end

function SetBlockAmbientPedsFromDroppingWeaponsThisFrame() end

---@param ped Ped
---@param toggle boolean
function SetBlockingOfNonTemporaryEvents(ped, toggle) end

---@param boat integer
---@param toggle boolean
function SetBoatAnchor(boat, toggle) end

---@param boat integer
---@param value number
function SetBoatAnchorBuoyancyCoefficient(boat, value) end

---@param vehicle integer
---@param ratio number
function SetBoatBoomPositionRatio(vehicle, ratio) end

---@param vehicle integer
---@param p1 boolean
function SetBoatDisableAvoidance(vehicle, p1) end

---@param vehicle integer
---@param toggle boolean
function SetBoatExplodesOnWreckedAction(vehicle, toggle) end

---@param boat integer
---@param toggle boolean
function SetBoatFrozenWhenAnchored(boat, toggle) end

---@param vehicle integer
function SetBoatIsSinking(vehicle) end

---@param boat integer
---@param value number
function SetBoatLowLodAnchorDistance(boat, value) end

---@param boat integer
---@param value number
function SetBoatMovementResistance(boat, value) end

---@param boat integer
---@param toggle boolean
function SetBoatRemainsAnchoredWhilePlayerIsDriver(boat, toggle) end

---@param vehicle integer
function SetBoatSinking(vehicle) end

---@param vehicle integer
---@param toggle boolean
function SetBoatSinksWhenWrecked(vehicle, toggle) end

---@param waterQuad integer
---@param minX integer
---@param minY integer
---@param maxX integer
---@param maxY integer
---@return boolean
function SetCalmingQuadBounds(waterQuad, minX, minY, maxX, maxY) end

---@param calmingQuad integer
---@param dampening number
---@return boolean
function SetCalmingQuadDampening(calmingQuad, dampening) end

---@param cam integer
---@param active boolean
function SetCamActive(cam, active) end

---@param camTo integer
---@param camFrom integer
---@param duration integer
---@param easeLocation integer
---@param easeRotation integer
function SetCamActiveWithInterp(camTo, camFrom, duration, easeLocation, easeRotation) end

---@param cam integer
---@param toggle boolean
function SetCamAffectsAiming(cam, toggle) end

---@param cam integer
---@param phase number
function SetCamAnimCurrentPhase(cam, phase) end

---@param vehicle integer
---@param toggle boolean
function SetCamberedWheelsDisabled(vehicle, toggle) end

---@param cam integer
---@param toggle boolean
function SetCamControlsMiniMapHeading(cam, toggle) end

---@param cam integer
---@param posX number
---@param posY number
---@param posZ number
function SetCamCoord(cam, posX, posY, posZ) end

---@param camera integer
---@param name string
function SetCamDebugName(camera, name) end

---@param camera integer
---@param p1 number
function SetCamDofFnumberOfLens(camera, p1) end

---@param camera integer
---@param multiplier number
function SetCamDofFocalLengthMultiplier(camera, multiplier) end

---@param camera integer
---@param p1 number
function SetCamDofFocusDistanceBias(camera, p1) end

---@param camera integer
---@param p1 number
function SetCamDofMaxNearInFocusDistance(camera, p1) end

---@param camera integer
---@param p1 number
function SetCamDofMaxNearInFocusDistanceBlendLevel(camera, p1) end

---@param cam integer
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
function SetCamDofPlanes(cam, p1, p2, p3, p4) end

---@param cam integer
---@param dofStrength number
function SetCamDofStrength(cam, dofStrength) end

---@param p0 integer
function SetCamEffect(p0) end

---@param toggle boolean
function SetCameraEndtime(toggle) end

---@param cam integer
---@param height number
function SetCameraRange(cam, height) end

---@param cam integer
---@param farClip number
function SetCamFarClip(cam, farClip) end

---@param cam integer
---@param farDOF number
function SetCamFarDof(cam, farDOF) end

---@param cam integer
---@param fieldOfView number
function SetCamFov(cam, fieldOfView) end

---@param cam integer
---@param p1 boolean
function SetCamInheritRollVehicle(cam, p1) end

---@param cam integer
---@param strength number
function SetCamMotionBlurStrength(cam, strength) end

---@param cam integer
---@param nearClip number
function SetCamNearClip(cam, nearClip) end

---@param cam integer
---@param nearDOF number
function SetCamNearDof(cam, nearDOF) end

---@param cam integer
---@param posX number
---@param posY number
---@param posZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param fieldOfView number
---@param transitionSpeed integer
---@param p9 integer
---@param p10 integer
---@param rotationOrder integer
function SetCamParams(cam, posX, posY, posZ, rotX, rotY, rotZ, fieldOfView, transitionSpeed, p9, p10, rotationOrder) end

---@param cam integer
---@param rotX number
---@param rotY number
---@param rotZ number
---@param rotationOrder integer
function SetCamRot(cam, rotX, rotY, rotZ, rotationOrder) end

---@param cam integer
---@param amplitude number
function SetCamShakeAmplitude(cam, amplitude) end

---@param cam integer
---@param timeDuration integer
function SetCamSplineDuration(cam, timeDuration) end

---@param cam integer
---@param p1 integer
---@param p2 integer
---@param p3 number
function SetCamSplineNodeEase(cam, p1, p2, p3) end

---@param cam integer
---@param p1 integer
---@param flags integer
function SetCamSplineNodeExtraFlags(cam, p1, flags) end

---@param cam integer
---@param p1 integer
---@param scale number
function SetCamSplineNodeVelocityScale(cam, p1, scale) end

---@param cam integer
---@param p1 number
function SetCamSplinePhase(cam, p1) end

---@param cam integer
---@param smoothingStyle integer
function SetCamSplineSmoothingStyle(cam, smoothingStyle) end

---@param cam integer
---@param toggle boolean
function SetCamUseShallowDofMode(cam, toggle) end

---@param context integer
---@param viewMode integer
function SetCamViewModeForContext(context, viewMode) end

---@param ped Ped
---@param toggle boolean
---@param p2 boolean
function SetCanAttackFriendly(ped, toggle, p2) end

---@param entity Entity
---@param toggle boolean
function SetCanAutoVaultOnEntity(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function SetCanClimbOnEntity(entity, toggle) end

---@param ped Ped
---@param toggle boolean
function SetCanPedEquipAllWeapons(ped, toggle) end

---@param ped Ped
---@param weaponHash Hash|string
---@param toggle boolean
function SetCanPedEquipWeapon(ped, weaponHash, toggle) end

---@param ped Ped
---@param weaponHash Hash|string
---@param toggle boolean
function SetCanPedSelectWeapon(ped, weaponHash, toggle) end

---@param vehicle integer
---@param state boolean
function SetCanResprayVehicle(vehicle, state) end

---@param vehicle integer
function SetCarBootOpen(vehicle) end

---@param cargobob integer
---@param entity Entity
function SetCargobobExcludeFromPickupEntity(cargobob, entity) end

---@param cargobob integer
---@param toggle boolean
function SetCargobobForceDontDetachVehicle(cargobob, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetCargobobHookCanAttach(vehicle, toggle) end

---@param cargobob integer
---@param toggle boolean
function SetCargobobHookCanDetach(cargobob, toggle) end

---@param cargobob integer
---@param length1 number
---@param length2 number
---@param state boolean
function SetCargobobHookPosition(cargobob, length1, length2, state) end

---@param cargobob integer
---@param isActive boolean
function SetCargobobPickupMagnetActive(cargobob, isActive) end

---@param vehicle integer
---@param p1 number
function SetCargobobPickupMagnetEffectRadius(vehicle, p1) end

---@param vehicle integer
---@param p1 number
function SetCargobobPickupMagnetFalloff(vehicle, p1) end

---@param cargobob integer
---@param p1 number
function SetCargobobPickupMagnetPullRopeLength(cargobob, p1) end

---@param cargobob integer
---@param p1 number
function SetCargobobPickupMagnetPullStrength(cargobob, p1) end

---@param cargobob integer
---@param p1 number
function SetCargobobPickupMagnetReducedFalloff(cargobob, p1) end

---@param cargobob integer
---@param vehicle integer
function SetCargobobPickupMagnetReducedStrength(cargobob, vehicle) end

---@param cargobob integer
---@param strength number
function SetCargobobPickupMagnetStrength(cargobob, strength) end

---@param cargobob integer
---@param p1 number
function SetCargobobPickupRopeDampingMultiplier(cargobob, p1) end

---@param vehicle integer
---@param state integer
function SetCargobobPickupRopeType(vehicle, state) end

---@param multiplier number
function SetCarHighSpeedBumpSeverityMultiplier(multiplier) end

---@param entity Entity
function SetCgAtBoundcenter(entity) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
function SetCgoffset(entity, x, y, z) end

---@param checkpoint integer
---@param nearHeight number
---@param farHeight number
---@param radius number
function SetCheckpointCylinderHeight(checkpoint, nearHeight, farHeight, radius) end

---@param checkpoint integer
---@param height_multiplier number
function SetCheckpointIconHeight(checkpoint, height_multiplier) end

---@param checkpoint integer
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SetCheckpointIconRgba(checkpoint, red, green, blue, alpha) end

---@param checkpoint integer
---@param scale number
function SetCheckpointIconScale(checkpoint, scale) end

---@param checkpoint integer
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SetCheckpointRgba(checkpoint, red, green, blue, alpha) end

---@param checkpoint integer
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SetCheckpointRgba2(checkpoint, red, green, blue, alpha) end

---@param checkpoint integer
---@param height_multiplier number
function SetCheckpointScale(checkpoint, height_multiplier) end

---@param p0 boolean
function SetCinematicButtonActive(p0) end

---@param p0 number
function SetCinematicCamShakeAmplitude(p0) end

---@param toggle boolean
function SetCinematicModeActive(toggle) end

function SetCinematicNewsChannelActiveThisUpdate() end

---@param day integer
---@param month integer
---@param year integer
function SetClockDate(day, month, year) end

---@param hour integer
---@param minute integer
---@param second integer
function SetClockTime(hour, minute, second) end

---@param opacity number
function SetCloudHatOpacity(opacity) end

---@param name string
---@param transitionTime number
function SetCloudHatTransition(name, transitionTime) end

---@param opacity number
function SetCloudsAlpha(opacity) end

---@param overrideSettingsName string
function SetCloudSettingsOverride(overrideSettingsName) end

---@param hudColor integer
function SetColourOfNextTextComponent(hudColor) end

---@param ped Ped
---@param combatType integer
---@param p2 number
function SetCombatFloat(ped, combatType, p2) end

---@param padIndex integer
---@param red integer
---@param green integer
---@param blue integer
function SetControlGroupColor(padIndex, red, green, blue) end

---@param padIndex integer
---@param red integer
---@param green integer
---@param blue integer
function SetControlLightEffectColor(padIndex, red, green, blue) end

---@param padIndex integer
---@param control integer
---@param amount number
---@return boolean
function SetControlNormal(padIndex, control, amount) end

---@param enable boolean
function SetConversationAudioControlledByAnim(enable) end

---@param isPlaceHolder boolean
function SetConversationAudioPlaceholder(isPlaceHolder) end

---@param vehicle integer
---@param toggle boolean
function SetConvertibleRoof(vehicle, toggle) end

---@param vehicle integer
---@param bLatched boolean
function SetConvertibleRoofLatchState(vehicle, bLatched) end

---@param toggle boolean
function SetCreateRandomCops(toggle) end

---@param toggle boolean
function SetCreateRandomCopsNotOnScenarios(toggle) end

---@param toggle boolean
function SetCreateRandomCopsOnScenarios(toggle) end

---@param object integer
---@param toggle boolean
function SetCreateWeaponObjectLightSource(object, toggle) end

---@param toggle boolean
function SetCreditsActive(toggle) end

---@param intensity number
function SetCurrentIntensity(intensity) end

---@param ped Ped
---@param weaponHash Hash|string
---@return boolean
function SetCurrentPedVehicleWeapon(ped, weaponHash) end

---@param ped Ped
---@param weaponHash Hash|string
---@param bForceInHand boolean
function SetCurrentPedWeapon(ped, weaponHash, bForceInHand) end

---@param modifierName string
function SetCurrentPlayerTcmodifier(modifierName) end

---@param x number
---@param y number
---@return boolean
function SetCursorLocation(x, y) end

---@param style integer
function SetCursorSprite(style) end

---@param hudColorId integer
function SetCustomMpHudColor(hudColorId) end

---@param radioStation string
---@param trackListName string
---@param forceNow boolean
function SetCustomRadioTrackList(radioStation, trackListName, forceNow) end

---@param x number
---@param y number
---@param z number
---@param heading number
function SetCustomRespawnPosition(x, y, z, heading) end

---@param name string
function SetCutsceneAudioOverride(name) end

---@param p0 boolean
function SetCutsceneCanBeSkipped(p0) end

---@param cutsceneEntName string
---@param p1 integer
---@param p2 integer
function SetCutsceneEntityStreamingFlags(cutsceneEntName, p1, p2) end

---@param p0 boolean
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
function SetCutsceneFadeValues(p0, p1, p2, p3) end

---@param x number
---@param y number
---@param z number
---@param heading number
---@param p4 integer
function SetCutsceneOrigin(x, y, z, heading, p4) end

---@param cutsceneEntName string
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@param modelHash Hash|string
function SetCutscenePedComponentVariation(cutsceneEntName, componentId, drawableId, textureId, modelHash) end

---@param cutsceneEntName string
---@param ped Ped
---@param modelHash Hash|string
function SetCutscenePedComponentVariationFromPed(cutsceneEntName, ped, modelHash) end

---@param cutsceneEntName string
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@param modelHash Hash|string
function SetCutscenePedPropVariation(cutsceneEntName, componentId, drawableId, textureId, modelHash) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
function SetCutsceneTriggerArea(p0, p1, p2, p3, p4, p5) end

---@param entity Entity
---@param vertex integer
---@param value number
function SetDamping(entity, vertex, value) end

---@param enabled boolean
function SetDebugLinesAndSpheresDrawingActive(enabled) end

---@param ped Ped
---@param name Hash|string
function SetDecisionMaker(ped, name) end

---@param intensity number
function SetDeepOceanScaler(intensity) end

---@param plateIndex integer
---@param pattern string
function SetDefaultVehicleNumberPlateTextPattern(plateIndex, pattern) end

---@param vehicle integer
---@param deploy boolean
---@param p2 boolean
function SetDeployHeliStubWings(vehicle, deploy, p2) end

---@param vehicle integer
---@param angleRatio number
function SetDesiredVerticalFlightPhase(vehicle, angleRatio) end

---@param object integer
---@param state integer
function SetDesObjectState(object, state) end

---@param toggle boolean
function SetDirectorMode(toggle) end

function SetDirectorModeClearTriggeredFlag() end

---@param player integer
---@param toggle boolean
function SetDisableAmbientMeleeMove(player, toggle) end

---@param disableExtraTrickForces boolean
function SetDisableBmxExtraTrickForces(disableExtraTrickForces) end

---@param object integer
---@param toggle boolean
function SetDisableBreaking(object, toggle) end

function SetDisableDecalRenderingThisFrame() end

---@param vehicle integer
---@param disableExplode boolean
function SetDisableExplodeFromBodyDamageOnCollision(vehicle, disableExplode) end

---@param object integer
---@param toggle boolean
function SetDisableFragDamage(object, toggle) end

---@param helicopter integer
---@param disableExplode boolean
function SetDisableHeliExplodeFromBodyDamage(helicopter, disableExplode) end

---@param vehicle integer
---@param toggle boolean
function SetDisableHoverModeFlight(vehicle, toggle) end

function SetDisablePetrolDecalsIgnitingThisFrame() end

---@param vehicle integer
---@param toggle boolean
function SetDisablePretendOccupants(vehicle, toggle) end

---@param toggle boolean
function SetDisableRandomTrainsThisFrame(toggle) end

---@param vehicle integer
---@param p1 boolean
function SetDisableSuperdummyMode(vehicle, p1) end

---@param vehicle integer
---@param turretIdx integer
function SetDisableTurretMovement(vehicle, turretIdx) end

---@param vehicle integer
---@param turretIdx integer
function SetDisableTurretMovementThisFrame(vehicle, turretIdx) end

---@param vehicle integer
---@param toggle boolean
function SetDisableVehicleEngineFires(vehicle, toggle) end

---@param vehicle integer
---@param direction boolean
function SetDisableVehicleFlightNozzlePosition(vehicle, direction) end

---@param vehicle integer
---@param toggle boolean
function SetDisableVehiclePetrolTankDamage(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetDisableVehiclePetrolTankFires(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetDisableVehicleSirenSound(vehicle, toggle) end

---@param toggle boolean
function SetDisableVehicleUnk(toggle) end

---@param toggle boolean
function SetDisableVehicleUnk_2(toggle) end

---@param vehicle integer
---@param toggle boolean
function SetDisableVehicleWindowCollisions(vehicle, toggle) end

---@param appId string
function SetDiscordAppId(appId) end

---@param index integer
---@param label string
---@param url string
function SetDiscordRichPresenceAction(index, label, url) end

---@param assetName string
function SetDiscordRichPresenceAsset(assetName) end

---@param assetName string
function SetDiscordRichPresenceAssetSmall(assetName) end

---@param text string
function SetDiscordRichPresenceAssetSmallText(text) end

---@param text string
function SetDiscordRichPresenceAssetText(text) end

---@param player integer
---@param toggle boolean
function SetDispatchCopsForPlayer(player, toggle) end

---@param p0 number
function SetDispatchIdealSpawnDistance(p0) end

---@param x number
---@param y number
---@param z number
function SetDispatchSpawnLocation(x, y, z) end

---@param p0 unknown
---@param p1 number
function SetDispatchTimeBetweenSpawnAttempts(p0, p1) end

---@param p0 unknown
---@param p1 number
function SetDispatchTimeBetweenSpawnAttemptsMultiplier(p0, p1) end

---@param toggle boolean
function SetDistantCarsEnabled(toggle) end

---@param toggle boolean
function SetDitchPoliceModels(toggle) end

---@param doorHash Hash|string
---@param state integer
---@param requestDoor boolean
---@param forceUpdate boolean
function SetDoorAccelerationLimit(doorHash, state, requestDoor, forceUpdate) end

---@param doorHash Hash|string
---@param ajar number
---@param requestDoor boolean
---@param forceUpdate boolean
function SetDoorAjarAngle(doorHash, ajar, requestDoor, forceUpdate) end

---@param toggle boolean
function SetDrawMapVisible(toggle) end

---@param x number
---@param y number
---@param z number
---@param p3 unknown
function SetDrawOrigin(x, y, z, p3) end

---@param vehicle integer
---@param toggle boolean
function SetDriftTyresEnabled(vehicle, toggle) end

---@param shootingPed Ped
---@param targetPed Ped
---@param targetVehicle integer
---@param x number
---@param y number
---@param z number
function SetDrivebyTaskTarget(shootingPed, targetPed, targetVehicle, x, y, z) end

---@param driver Ped
---@param ability number
function SetDriverAbility(driver, ability) end

---@param driver Ped
---@param aggressiveness number
function SetDriverAggressiveness(driver, aggressiveness) end

---@param driver Ped
---@param modifier number
function SetDriverRacingModifier(driver, modifier) end

---@param driver Ped
---@param cruiseSpeed number
function SetDriveTaskCruiseSpeed(driver, cruiseSpeed) end

---@param ped Ped
---@param drivingStyle integer
function SetDriveTaskDrivingStyle(ped, drivingStyle) end

---@param p0 unknown
---@param p1 number
function SetDriveTaskMaxCruiseSpeed(p0, p1) end

---@param duiObject integer
---@param url string
function SetDuiUrl(duiObject, url) end

---@param probeLength number
function SetEmitterProbeLength(probeLength) end

---@param emitterName string
---@param radioStation string
function SetEmitterRadioStation(emitterName, radioStation) end

---@param entity integer
---@param toggle boolean
---@param p2 integer
function SetEnableArenaPropPhysics(entity, toggle, p2) end

---@param entity integer
---@param toggle boolean
---@param p2 integer
---@param ped Ped
function SetEnableArenaPropPhysicsOnPed(entity, toggle, p2, ped) end

---@param ped Ped
---@param toggle boolean
function SetEnableBoundAnkles(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetEnableHandcuffs(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetEnablePedEnveffScale(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetEnableScuba(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetEnableScubaGearLight(ped, toggle) end

---@param toggle boolean
function SetEnableVehicleSlipstreaming(toggle) end

---@param entity Entity
---@param alphaLevel integer
---@param skin boolean
function SetEntityAlpha(entity, alphaLevel, skin) end

---@param entity Entity
---@param toggle boolean
function SetEntityAlwaysPrerender(entity, toggle) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
function SetEntityAngularVelocity(entity, x, y, z) end

---@param entity Entity
---@param animDictionary string
---@param animName string
---@param time number
function SetEntityAnimCurrentTime(entity, animDictionary, animName, time) end

---@param entity Entity
---@param animDictionary string
---@param animName string
---@param speedMultiplier number
function SetEntityAnimSpeed(entity, animDictionary, animName, speedMultiplier) end

---@param entity Entity
---@param scriptHostObject boolean
---@param bGrabFromOtherScript boolean
function SetEntityAsMissionEntity(entity, scriptHostObject, bGrabFromOtherScript) end

---@return Entity entity
function SetEntityAsNoLongerNeeded() end

---@param entity Entity
---@param toggle boolean
function SetEntityCanBeDamaged(entity, toggle) end

---@param entity Entity
---@param bCanBeDamaged boolean
---@param relGroup integer
function SetEntityCanBeDamagedByRelationshipGroup(entity, bCanBeDamaged, relGroup) end

---@param entity Entity
---@param toggle boolean
function SetEntityCanBeTargetedWithoutLos(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function SetEntityCleanupByEngine(entity, toggle) end

---@param entity Entity
---@param toggle boolean
---@param keepPhysics boolean
function SetEntityCollision(entity, toggle, keepPhysics) end

---@param entity Entity
---@param toggle boolean
---@param keepPhysics boolean
function SetEntityCollision_2(entity, toggle, keepPhysics) end

---@param entity Entity
---@param toggle boolean
---@param keepPhysics boolean
function SetEntityCompletelyDisableCollision(entity, toggle, keepPhysics) end

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
---@param xPos number
---@param yPos number
---@param zPos number
---@param alive boolean
---@param deadFlag boolean
---@param ragdollFlag boolean
---@param clearArea boolean
function SetEntityCoords_2(entity, xPos, yPos, zPos, alive, deadFlag, ragdollFlag, clearArea) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
---@param keepTasks boolean
---@param keepIK boolean
---@param doWarp boolean
function SetEntityCoordsNoOffset(entity, x, y, z, keepTasks, keepIK, doWarp) end

---@param entity Entity
---@param xPos number
---@param yPos number
---@param zPos number
---@param alive boolean
---@param deadFlag boolean
---@param ragdollFlag boolean
---@param clearArea boolean
function SetEntityCoordsWithoutPlantsReset(entity, xPos, yPos, zPos, alive, deadFlag, ragdollFlag, clearArea) end

---@param entity Entity
---@param p1 boolean
function SetEntityDecalsDisabled(entity, p1) end

---@param entity Entity
---@param enabled boolean
function SetEntityDrawOutline(entity, enabled) end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SetEntityDrawOutlineColor(red, green, blue, alpha) end

---@param techniqueGroup string
function SetEntityDrawOutlineRenderTechnique(techniqueGroup) end

---@param shader integer
function SetEntityDrawOutlineShader(shader) end

---@param entity Entity
---@param toggle boolean
function SetEntityDynamic(entity, toggle) end

---@param speakerConversationIndex integer
---@param entity Entity
function SetEntityForNullConvPed(speakerConversationIndex, entity) end

---@param entity Entity
---@param toggle boolean
function SetEntityHasGravity(entity, toggle) end

---@param entity Entity
---@param heading number
function SetEntityHeading(entity, heading) end

---@param entity Entity
---@param health integer
function SetEntityHealth(entity, health) end

---@param entity Entity
---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SetEntityIconColor(entity, red, green, blue, alpha) end

---@param entity Entity
---@param toggle boolean
function SetEntityIconVisibility(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function SetEntityInvincible(entity, toggle) end

---@param entity Entity
---@param p1 boolean
---@param p2 number
function SetEntityIsTargetPriority(entity, p1, p2) end

---@param entity Entity
---@param toggle boolean
function SetEntityLights(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function SetEntityLoadCollisionFlag(entity, toggle) end

---@param entity Entity
function SetEntityLocallyInvisible(entity) end

---@param entity Entity
function SetEntityLocallyVisible(entity) end

---@param entity Entity
---@param value integer
function SetEntityLodDist(entity, value) end

---@param entity Entity
---@param forwardX number
---@param forwardY number
---@param forwardZ number
---@param rightX number
---@param rightY number
---@param rightZ number
---@param upX number
---@param upY number
---@param upZ number
---@param atX number
---@param atY number
---@param atZ number
function SetEntityMatrix(entity, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ, atX, atY, atZ) end

---@param entity Entity
---@param value integer
function SetEntityMaxHealth(entity, value) end

---@param entity Entity
---@param speed number
function SetEntityMaxSpeed(entity, speed) end

---@param entity Entity
---@param toggle boolean
function SetEntityMotionBlur(entity, toggle) end

---@param entity1 Entity
---@param entity2 Entity
---@param thisFrameOnly boolean
function SetEntityNoCollisionEntity(entity1, entity2, thisFrameOnly) end

---@param entity Entity
---@param toggle boolean
function SetEntityOnlyDamagedByPlayer(entity, toggle) end

---@param entity Entity
---@param p1 boolean
---@param relationshipHash Hash|string
function SetEntityOnlyDamagedByRelationshipGroup(entity, p1, relationshipHash) end

---@param entity Entity
---@param bulletProof boolean
---@param fireProof boolean
---@param explosionProof boolean
---@param collisionProof boolean
---@param meleeProof boolean
---@param steamProof boolean
---@param p7 boolean
---@param drownProof boolean
function SetEntityProofs(entity, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof) end

---@param entity Entity
---@param toggle boolean
function SetEntityProofUnk(entity, toggle) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
---@param w number
function SetEntityQuaternion(entity, x, y, z, w) end

---@param entity Entity
---@param toggle boolean
function SetEntityRecordsCollisions(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function SetEntityRegister(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function SetEntityRenderScorched(entity, toggle) end

---@param entity Entity
---@param toggle boolean
function SetEntityRequiresMoreExpensiveRiverCheck(entity, toggle) end

---@param entity Entity
---@param pitch number
---@param roll number
---@param yaw number
---@param rotationOrder integer
---@param bDeadCheck boolean
function SetEntityRotation(entity, pitch, roll, yaw, rotationOrder, bDeadCheck) end

---@param entity Entity
---@param toggle boolean
function SetEntitySomething(entity, toggle) end

---@param entity Entity
---@param state integer
function SetEntityTrafficlightOverride(entity, state) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
function SetEntityVelocity(entity, x, y, z) end

---@param entity Entity
---@param toggle boolean
---@param unk boolean
function SetEntityVisible(entity, toggle, unk) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function SetEntityVisibleInCutscene(p0, p1, p2) end

---@param player integer
---@param toggle boolean
function SetEveryoneIgnorePlayer(player, toggle) end

---@param ped Ped
---@return integer
function SetExclusivePhoneRelationships(ped) end

---@param scenarioGroup string
function SetExclusiveScenarioGroup(scenarioGroup) end

---@param player integer
function SetExplosiveAmmoThisFrame(player) end

---@param player integer
function SetExplosiveMeleeThisFrame(player) end

---@param modifierName string
function SetExtraTimecycleModifier(modifierName) end

---@param phase number
function SetExtraTimecycleModifierStrength(phase) end

---@param ped Ped
---@param animDict string
function SetFacialClipsetOverride(ped, animDict) end

---@param ped Ped
---@param animName string
---@param animDict string
function SetFacialIdleAnimOverride(ped, animName, animDict) end

---@param toggle boolean
function SetFadeInAfterDeathArrest(toggle) end

---@param toggle boolean
function SetFadeInAfterLoad(toggle) end

---@param toggle boolean
function SetFadeOutAfterArrest(toggle) end

---@param toggle boolean
function SetFadeOutAfterDeath(toggle) end

---@param x number
---@param y number
function SetFakePausemapPlayerPositionThisFrame(x, y) end

---@param fakeWantedLevel integer
function SetFakeWantedLevel(fakeWantedLevel) end

---@param multiplier number
function SetFallDamageLandOnFootMultiplier(multiplier) end

---@param multiplier number
function SetFallDamageMultiplier(multiplier) end

---@param toggle boolean
function SetFarDrawVehicles(toggle) end

---@param toggle boolean
function SetFarShadowsSuppressed(toggle) end

---@param player integer
function SetFireAmmoThisFrame(player) end

---@param p0 number
function SetFireSpreadRate(p0) end

---@param distance number
function SetFirstPersonAimCamNearClipThisUpdate(distance) end

---@param zoomFactor number
function SetFirstPersonAimCamZoomFactor(zoomFactor) end

---@param distance number
function SetFirstPersonCamNearClip(distance) end

---@param minAngle number
---@param maxAngle number
function SetFirstPersonCamPitchRange(minAngle, maxAngle) end

---@param p0 number
---@param p1 number
---@param fadeIn number
---@param duration number
---@param fadeOut number
function SetFlash(p0, p1, fadeIn, duration, fadeOut) end

---@param ped Ped
---@param toggle boolean
function SetFlashLightEnabled(ped, toggle) end

---@param distance number
---@return unknown
function SetFlashLightFadeDistance(distance) end

---@param state boolean
function SetFlashLightKeepOnWhileMoving(state) end

---@param hudIndex integer
---@param x number
---@param y number
function SetFloatingHelpTextScreenPosition(hudIndex, x, y) end

---@param hudIndex integer
---@param style integer
---@param hudColor integer
---@param alpha integer
---@param arrowPosition integer
---@param boxOffset integer
function SetFloatingHelpTextStyle(hudIndex, style, hudColor, alpha, arrowPosition, boxOffset) end

---@param hudIndex integer
---@param entity Entity
---@param offsetX number
---@param offsetY number
function SetFloatingHelpTextToEntity(hudIndex, entity, offsetX, offsetY) end

---@param hudIndex integer
---@param x number
---@param y number
---@param z number
function SetFloatingHelpTextWorldPosition(hudIndex, x, y, z) end

---@param cam integer
---@param x number
---@param y number
---@param z number
function SetFlyCamCoordAndConstrain(cam, x, y, z) end

---@param cam integer
---@param p1 number
---@param p2 number
---@param p3 number
function SetFlyCamHorizontalResponse(cam, p1, p2, p3) end

---@param cam integer
---@param height number
function SetFlyCamMaxHeight(cam, height) end

---@param cam integer
---@param p1 number
---@param p2 number
---@param p3 number
function SetFlyCamVerticalSpeedMultiplier(cam, p1, p2, p3) end

---@param vehMinSpeed number
---@param unkMinSpeed number
---@param unkModifier number
---@param minDamage number
---@return boolean
function SetFlyThroughWindscreenParams(vehMinSpeed, unkMinSpeed, unkModifier, minDamage) end

---@param x number
---@param y number
---@param z number
---@param offsetX number
---@param offsetY number
---@param offsetZ number
function SetFocusArea(x, y, z, offsetX, offsetY, offsetZ) end

---@param entity Entity
function SetFocusEntity(entity) end

---@param x number
---@param y number
---@param z number
---@param offsetX number
---@param offsetY number
---@param offsetZ number
function SetFocusPosAndVel(x, y, z, offsetX, offsetY, offsetZ) end

---@param state boolean
function SetFogVolumeRenderDisabled(state) end

---@param camName string
---@param easeTime integer
---@return boolean
function SetFollowPedCamCutsceneChat(camName, easeTime) end

---@param camName string
---@param easeTime integer
---@return boolean
function SetFollowPedCamThisUpdate(camName, easeTime) end

---@param viewMode integer
function SetFollowPedCamViewMode(viewMode) end

---@param seatIndex integer
function SetFollowTurretSeatCam(seatIndex) end

---@param viewMode integer
function SetFollowVehicleCamViewMode(viewMode) end

---@param zoomLevel integer
function SetFollowVehicleCamZoomLevel(zoomLevel) end

---@param boat integer
---@param toggle boolean
function SetForcedBoatLocationWhenAnchored(boat, toggle) end

---@param ped Ped
---@param toggle boolean
function SetForceFootstepUpdate(ped, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetForceHdVehicle(vehicle, toggle) end

---@param boat integer
---@param toggle boolean
function SetForceLowLodAnchorMode(boat, toggle) end

---@param x number
---@param y number
---@param z number
---@param p3 number
function SetForceObjectThisFrame(x, y, z, p3) end

---@param toggle boolean
function SetForcePedFootstepsTracks(toggle) end

---@param player integer
function SetForcePlayerToJump(player) end

---@param ped Ped
---@param p1 boolean
---@param type integer
---@param p3 integer
function SetForceStepType(ped, p1, type, p3) end

---@param toggle boolean
function SetForceVehicleTrails(toggle) end

---@param vehicle integer
---@param height number
function SetForkliftForkHeight(vehicle, height) end

---@param active boolean
function SetFrontendActive(active) end

---@param active boolean
function SetFrontendRadioActive(active) end

---@param toggle boolean
function SetFrozenRenderingDisabled(toggle) end

---@param multiplier number
function SetFuelConsumptionRateMultiplier(multiplier) end

---@param state boolean
function SetFuelConsumptionState(state) end

---@param toggle boolean
function SetGamePaused(toggle) end

---@param toggle boolean
function SetGamePausesForStreaming(toggle) end

---@param ped Ped
function SetGameplayCamFollowPedThisUpdate(ped) end

---@param camName string
function SetGameplayCamHash(camName) end

---@param pitch number
function SetGameplayCamRawPitch(pitch) end

---@param yaw number
function SetGameplayCamRawYaw(yaw) end

---@param heading number
function SetGameplayCamRelativeHeading(heading) end

---@param angle number
---@param scalingFactor number
function SetGameplayCamRelativePitch(angle, scalingFactor) end

---@param roll number
---@param pitch number
---@param yaw number
function SetGameplayCamRelativeRotation(roll, pitch, yaw) end

---@param amplitude number
function SetGameplayCamShakeAmplitude(amplitude) end

---@param vehicleName string
function SetGameplayCamVehicleCamera(vehicleName) end

---@param vehicleModel Hash|string
function SetGameplayCamVehicleCameraName(vehicleModel) end

---@param x number
---@param y number
---@param z number
---@param duration integer
---@param blendOutDuration integer
---@param blendInDuration integer
---@param unk integer
function SetGameplayCoordHint(x, y, z, duration, blendOutDuration, blendInDuration, unk) end

---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param p4 boolean
---@param p5 integer
---@param p6 integer
---@param p7 integer
---@param p8 unknown
function SetGameplayEntityHint(entity, xOffset, yOffset, zOffset, p4, p5, p6, p7, p8) end

---@param value number
function SetGameplayHintAngle(value) end

---@param toggle boolean
function SetGameplayHintAnimCloseup(toggle) end

---@param xOffset number
function SetGameplayHintAnimOffsetx(xOffset) end

---@param yOffset number
function SetGameplayHintAnimOffsety(yOffset) end

---@param value number
function SetGameplayHintAnimOffsetz(value) end

---@param value number
function SetGameplayHintBaseOrbitPitchOffset(value) end

---@param value number
function SetGameplayHintFollowDistanceScalar(value) end

---@param FOV number
function SetGameplayHintFov(FOV) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 boolean
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
function SetGameplayObjectHint(p0, p1, p2, p3, p4, p5, p6, p7) end

---@param p0 Ped
---@param x1 number
---@param y1 number
---@param z1 number
---@param p4 boolean
---@param duration integer
---@param blendOutDuration integer
---@param blendInDuration integer
function SetGameplayPedHint(p0, x1, y1, z1, p4, duration, blendOutDuration, blendInDuration) end

---@param vehicle integer
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param p4 boolean
---@param time integer
---@param easeInTime integer
---@param easeOutTime integer
function SetGameplayVehicleHint(vehicle, offsetX, offsetY, offsetZ, p4, time, easeInTime, easeOutTime) end

---@param toggle boolean
function SetGarbageTrucks(toggle) end

---@param alpha integer
function SetGhostedEntityAlpha(alpha) end

---@param height number
function SetGlobalMinBirdFlightHeight(height) end

---@param massMul number
function SetGlobalPassengerMassMultiplier(massMul) end

---@param signalLevel number
function SetGlobalRadioSignalLevel(signalLevel) end

---@param active boolean
function SetGpsActive(active) end

---@param toggle boolean
---@param radarThickness integer
---@param mapThickness integer
function SetGpsCustomRouteRender(toggle, radarThickness, mapThickness) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
function SetGpsDisabledZone(x1, y1, z1, x2, y2, z2) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param index integer
function SetGpsDisabledZoneAtIndex(x1, y1, z1, x2, y2, z2, index) end

---@param p0 integer
---@param p1 number
function SetGpsFlags(p0, p1) end

---@param toggle boolean
function SetGpsFlashes(toggle) end

---@param toggle boolean
function SetGpsMultiRouteRender(toggle) end

---@param level integer
function SetGravityLevel(level) end

---@param groupId integer
---@param formationType integer
function SetGroupFormation(groupId, formationType) end

---@param groupId integer
---@param p1 number
---@param p2 number
---@param p3 number
function SetGroupFormationSpacing(groupId, p1, p2, p3) end

---@param groupHandle integer
---@param separationRange number
function SetGroupSeparationRange(groupHandle, separationRange) end

---@param toggle boolean
function SetHandleRockstarMessageViaScript(toggle) end

---@param vehicle string
---@param class_ string
---@param fieldName string
---@param value unknown
function SetHandlingField(vehicle, class_, fieldName, value) end

---@param vehicle string
---@param class_ string
---@param fieldName string
---@param value number
function SetHandlingFloat(vehicle, class_, fieldName, value) end

---@param vehicle string
---@param class_ string
---@param fieldName string
---@param value integer
function SetHandlingInt(vehicle, class_, fieldName, value) end

---@param vehicle string
---@param class_ string
---@param fieldName string
---@param value vector3
function SetHandlingVector(vehicle, class_, fieldName, value) end

---@param value integer
function SetHasContentUnlocksFlags(value) end

---@param x number
---@param y number
---@param z number
---@param radius number
function SetHdArea(x, y, z, radius) end

---@param ped Ped
---@param r integer
---@param g integer
---@param b integer
---@param id integer
function SetHeadBlendPaletteColor(ped, r, g, b, id) end

---@param configName string
---@param newValue number
function SetHealthConfigDefaultArmor(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigDefaultEndurance(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigDefaultHealth(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigDogTakedownThreshold(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigDyingThreshold(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigFatiguedThreshold(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigHurtThreshold(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigInjuredThreshold(configName, newValue) end

---@param configName string
---@param newValue boolean
function SetHealthConfigInvincible(configName, newValue) end

---@param configName string
---@param newValue boolean
function SetHealthConfigMeleeFatalAttack(configName, newValue) end

---@param configName string
---@param newValue number
function SetHealthConfigWritheFromBulletThreshold(configName, newValue) end

---@param health integer
---@param capacity integer
---@param wasAdded boolean
function SetHealthHudDisplayValues(health, capacity, wasAdded) end

---@param vehicle integer
function SetHeliBladesFullSpeed(vehicle) end

---@param vehicle integer
---@param speed number
function SetHeliBladesSpeed(vehicle, speed) end

---@param vehicle integer
---@param x number
---@param y number
---@param z number
function SetHeliCombatOffset(vehicle, x, y, z) end

---@param helicopter integer
---@param multiplier number
function SetHelicopterRollPitchYawMult(helicopter, multiplier) end

---@param vehicle integer
---@param health number
function SetHeliMainRotorHealth(vehicle, health) end

---@param helicopter integer
---@param bResistToExplosion boolean
function SetHeliResistToExplosion(helicopter, bResistToExplosion) end

---@param heli integer
---@param toggle boolean
function SetHeliTailBoomCanBreakOff(heli, toggle) end

---@param heli integer
---@param toggle boolean
function SetHeliTailExplodeThrowDashboard(heli, toggle) end

---@param vehicle integer
---@param health number
function SetHeliTailRotorHealth(vehicle, health) end

---@param vehicle integer
---@param p1 number
function SetHeliTurbulenceScalar(vehicle, p1) end

---@param style integer
---@param hudColor integer
---@param alpha integer
---@param p3 integer
---@param p4 integer
function SetHelpMessageTextStyle(style, hudColor, alpha, p3, p4) end

---@param p0 boolean
---@param p1 boolean
---@param nearplaneOut number
---@param nearplaneIn number
---@param farplaneOut number
---@param farplaneIn number
function SetHidofEnvBlurParams(p0, p1, nearplaneOut, nearplaneIn, farplaneOut, farplaneIn) end

---@param p0 boolean
---@param p1 boolean
---@param nearplaneOut number
---@param nearplaneIn number
---@param farplaneOut number
---@param farplaneIn number
function SetHidofOverride(p0, p1, nearplaneOut, nearplaneIn, farplaneOut, farplaneIn) end

---@param ped Ped
---@param duration unknown
---@param p2 unknown
---@param p3 unknown
function SetHighFallTask(ped, duration, p2, p3) end

---@param vehicle integer
---@param toggle boolean
function SetHornEnabled(vehicle, toggle) end

---@param vehicle integer
---@param ratio number
function SetHoverModeWingRatio(vehicle, ratio) end

---@param player integer
---@param toggle boolean
function SetHudAnimStopLevel(player, toggle) end

---@param hudColorIndex integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function SetHudColour(hudColorIndex, r, g, b, a) end

---@param hudColorIndex integer
---@param hudColorIndex2 integer
function SetHudColoursSwitch(hudColorIndex, hudColorIndex2) end

---@param id integer
---@param horizontalAlign integer
---@param verticalAlign integer
function SetHudComponentAlign(id, horizontalAlign, verticalAlign) end

---@param id integer
---@param x number
---@param y number
function SetHudComponentPosition(id, x, y) end

---@param id integer
---@param x number
---@param y number
function SetHudComponentSize(id, x, y) end

---@param vehicle integer
---@param toggle boolean
function SetHydraulicRaised(vehicle, toggle) end

---@param vehicle integer
---@param wheelId integer
---@param value number
function SetHydraulicState(vehicle, wheelId, value) end

---@param vehicle integer
---@param state integer
function SetHydraulicWheelState(vehicle, state) end

---@param vehicle integer
---@param wheelId integer
---@param state integer
---@param value number
---@param p4 number
function SetHydraulicWheelStateTransition(vehicle, wheelId, state, value, p4) end

---@param vehicle integer
---@param wheelId integer
---@param value number
function SetHydraulicWheelValue(vehicle, wheelId, value) end

---@param player integer
---@param toggle boolean
function SetIgnoreLowPriorityShockingEvents(player, toggle) end

---@param toggle boolean
function SetIgnoreNoGpsFlag(toggle) end

---@param toggle boolean
function SetIgnoreSecondaryRouteNodes(toggle) end

---@param ped Ped
---@param ikIndex integer
---@param entityLookAt Entity
---@param boneLookAt integer
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param ikTargetFlags integer
---@param blendInDuration integer
---@param blendOutDuration integer
function SetIkTarget(ped, ikIndex, entityLookAt, boneLookAt, offsetX, offsetY, offsetZ, ikTargetFlags, blendInDuration, blendOutDuration) end

---@param incidentId integer
---@param dispatchService integer
---@param numUnits integer
function SetIncidentRequestedUnits(incidentId, dispatchService, numUnits) end

---@param incidentId integer
---@param p1 number
function SetIncidentUnk(incidentId, p1) end

---@param radioStation string
function SetInitialPlayerStation(radioStation) end

---@param padIndex integer
---@param control integer
function SetInputExclusive(padIndex, control) end

---@param flag integer
function SetInstancePriorityHint(flag) end

---@param toggle integer
function SetInstancePriorityMode(toggle) end

---@param interiorID integer
---@param toggle boolean
function SetInteriorActive(interiorID, toggle) end

---@param interior integer
---@param entitySetName string
---@param color integer
function SetInteriorEntitySetColor(interior, entitySetName, color) end

---@param interiorId integer
---@param portalIndex integer
---@param cornerIndex integer
---@param posX number
---@param posY number
---@param posZ number
function SetInteriorPortalCornerPosition(interiorId, portalIndex, cornerIndex, posX, posY, posZ) end

---@param interiorId integer
---@param portalIndex integer
---@param entityIndex integer
---@param flag integer
function SetInteriorPortalEntityFlag(interiorId, portalIndex, entityIndex, flag) end

---@param interiorId integer
---@param portalIndex integer
---@param flag integer
function SetInteriorPortalFlag(interiorId, portalIndex, flag) end

---@param interiorId integer
---@param portalIndex integer
---@param roomFrom integer
function SetInteriorPortalRoomFrom(interiorId, portalIndex, roomFrom) end

---@param interiorId integer
---@param portalIndex integer
---@param roomTo integer
function SetInteriorPortalRoomTo(interiorId, portalIndex, roomTo) end

---@param probeLength number
function SetInteriorProbeLength(probeLength) end

---@param interior integer
---@param entitySetName string
---@param color integer
function SetInteriorPropColor(interior, entitySetName, color) end

---@param interiorId integer
---@param roomIndex integer
---@param bbMinX number
---@param bbMinY number
---@param bbMinZ number
---@param bbMaxX number
---@param bbMaxY number
---@param bbMaxZ number
function SetInteriorRoomExtents(interiorId, roomIndex, bbMinX, bbMinY, bbMinZ, bbMaxX, bbMaxY, bbMaxZ) end

---@param interiorId integer
---@param roomIndex integer
---@param flag integer
function SetInteriorRoomFlag(interiorId, roomIndex, flag) end

---@param interiorId integer
---@param roomIndex integer
---@param timecycleHash integer
function SetInteriorRoomTimecycle(interiorId, roomIndex, timecycleHash) end

---@param toggle boolean
function SetInteriorZoomLevelDecreased(toggle) end

---@param toggle boolean
function SetInteriorZoomLevelIncreased(toggle) end

---@param p0 integer
---@param p1 integer
function SetInVehicleCamStateThisUpdate(p0, p1) end

---@param toggle boolean
function SetIsInTournament(toggle) end

---@param islandName string
---@param toggle boolean
function SetIslandEnabled(islandName, toggle) end

---@param islandName string
---@param toggle boolean
function SetIslandHopperEnabled(islandName, toggle) end

---@param hide boolean
function SetKeyMappingHideResources(hide) end

---@param height number
function SetKillFallHeight(height) end

---@param vehicle integer
function SetLastDrivenVehicle(vehicle) end

---@param toggle boolean
function SetLaunchControlEnabled(toggle) end

---@param alpha number
function SetLightAlpha(alpha) end

---@param intensity number
---@param radius number
---@param bias number
---@param intensity2 number
function SetLightAo(intensity, radius, bias, intensity2) end

---@param size number
function SetLightCapsuleSize(size) end

---@param x integer
---@param y integer
---@param width integer
---@param height integer
function SetLightClipRect(x, y, width, height) end

---@param r integer
---@param g integer
---@param b integer
function SetLightColor(r, g, b) end

---@param innerConeAngle number
---@param outerConeAngle number
function SetLightCone(innerConeAngle, outerConeAngle) end

---@param x number
---@param y number
---@param z number
function SetLightCoords(x, y, z) end

---@param xDir number
---@param yDir number
---@param zDir number
---@param xTanDir number
---@param yTanDir number
---@param zTanDir number
function SetLightDirection(xDir, yDir, zDir, xTanDir, yTanDir, zTanDir) end

---@param extraFlags integer
function SetLightExtraflags(extraFlags) end

---@param fadeDistance integer
function SetLightFadeDistance(fadeDistance) end

---@param falloff number
function SetLightFalloff(falloff) end

---@param flags integer
function SetLightFlags(flags) end

---@param intensity number
---@param range number
function SetLightHeadlight(intensity, range) end

---@param intensity number
function SetLightIntensity(intensity) end

---@param interiorId integer
---@param isPortal boolean
---@param roomIndex integer
function SetLightInterior(interiorId, isPortal, roomIndex) end

---@param x number
---@param y number
---@param z number
---@param w number
function SetLightPlane(x, y, z, w) end

---@param radius number
function SetLightRadius(radius) end

---@param distance number
function SetLightsCutoffDistanceTweak(distance) end

---@param shadowFlags integer
---@param shadowDistance number
---@param shadowFade number
---@param shadowDepthBiasScale number
function SetLightShadowDetails(shadowFlags, shadowDistance, shadowFade, shadowDepthBiasScale) end

---@param fadeDistance integer
function SetLightShadowFadeDistance(fadeDistance) end

---@param fadeDistance integer
function SetLightSpecularFadeDistance(fadeDistance) end

---@param textureDict string
---@param textureHash integer
function SetLightTexture(textureDict, textureHash) end

---@param lightType integer
function SetLightType(lightType) end

---@param volIntensity number
---@param volSizeScale number
---@param r number
---@param g number
---@param b number
---@param i number
---@param outerExponent number
function SetLightVolumeDetails(volIntensity, volSizeScale, r, g, b, i, outerExponent) end

---@param volumetricFadeDistance integer
function SetLightVolumetricFadeDistance(volumetricFadeDistance) end

---@param string string
function SetLoadingPromptTextEntry(string) end

---@param toggle boolean
function SetLocalPlayerAsGhost(toggle) end

---@param p0 boolean
function SetLocalPlayerCanCollectPortablePickups(p0) end

---@param modelHash Hash|string
---@param toggle boolean
function SetLocalPlayerCanUsePickupsWithThisModel(modelHash, toggle) end

---@param p0 boolean
function SetLocalPlayerInvisibleLocally(p0) end

---@param p0 boolean
---@param p1 boolean
function SetLocalPlayerVisibleInCutscene(p0, p1) end

---@param p0 boolean
function SetLocalPlayerVisibleLocally(p0) end

---@param color integer
function SetMainPlayerBlipColour(color) end

---@param manualShutdown boolean
function SetManualShutdownLoadingScreenNui(manualShutdown) end

---@param name string
---@param toggle boolean
function SetMapdatacullboxEnabled(name, toggle) end

---@param toggle boolean
function SetMapFullScreen(toggle) end

---@param index integer
---@param zoomScale number
---@param zoomSpeed number
---@param scrollSpeed number
---@param tilesX number
---@param tilesY number
function SetMapZoomDataLevel(index, zoomScale, zoomSpeed, scrollSpeed, tilesX, tilesY) end

---@param maximumValue integer
function SetMaxArmourHudDisplay(maximumValue) end

---@param maximumValue integer
function SetMaxHealthHudDisplay(maximumValue) end

---@param modelHash Hash|string
---@param p1 integer
function SetMaxNumPortablePickupsCarriedByPlayer(modelHash, p1) end

---@param maxWantedLevel integer
function SetMaxWantedLevel(maxWantedLevel) end

---@param p0 boolean
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param x3 number
---@param y3 number
---@param z3 number
function SetMicrophonePosition(p0, x1, y1, z1, x2, y2, z2, x3, y3, z3) end

---@param value integer
function SetMillisecondsPerGameMinute(value) end

---@param toggle boolean
function SetMinigameInProgress(toggle) end

---@param altitude number
---@param p1 boolean
function SetMinimapAltitudeIndicatorLevel(altitude, p1) end

---@param altitude number
---@param p1 boolean
function SetMinimapAttitudeIndicatorLevel(altitude, p1) end

---@param toggle boolean
function SetMinimapBlockWaypoint(toggle) end

---@param type integer
function SetMinimapClipType(type) end

---@param componentID integer
---@param toggle boolean
---@param hudColor integer
---@return integer
function SetMinimapComponent(componentID, toggle, hudColor) end

---@param name string
---@param alignX string
---@param alignY string
---@param posX number
---@param posY number
---@param sizeX number
---@param sizeY number
function SetMinimapComponentPosition(name, alignX, alignY, posX, posY, sizeX, sizeY) end

---@param x number
---@param y number
---@param z number
function SetMinimapFowRevealCoordinate(x, y, z) end

---@param hole integer
function SetMinimapGolfCourse(hole) end

function SetMinimapGolfCourseOff() end

---@param toggle boolean
function SetMinimapHideFow(toggle) end

---@param toggle boolean
function SetMinimapInPrologue(toggle) end

---@param toggle boolean
---@param ped Ped
function SetMinimapInSpectatorMode(toggle, ped) end

---@param miniMap integer
---@param x number
---@param y number
---@param xScale number
---@param yScale number
---@param alpha number
function SetMinimapOverlayDisplay(miniMap, x, y, xScale, yScale, alpha) end

---@param toggle boolean
function SetMinimapRevealed(toggle) end

---@param toggle boolean
function SetMinimapSonarEnabled(toggle) end

---@param toggle boolean
function SetMinimapSonarSweep(toggle) end

---@param toggle boolean
function SetMissionFlag(toggle) end

---@param p0 boolean
---@param name string
function SetMissionName(p0, name) end

---@param p0 boolean
---@param name string
function SetMissionName_2(p0, name) end

---@param p1 boolean
---@return integer train
function SetMissionTrainAsNoLongerNeeded(p1) end

---@param train integer
---@param x number
---@param y number
---@param z number
function SetMissionTrainCoords(train, x, y, z) end

---@param toggle boolean
function SetMobilePhoneDofState(toggle) end

---@param posX number
---@param posY number
---@param posZ number
function SetMobilePhonePosition(posX, posY, posZ) end

---@param state boolean
function SetMobilePhoneRadioState(state) end

---@param rotX number
---@param rotY number
---@param rotZ number
---@param p3 unknown
function SetMobilePhoneRotation(rotX, rotY, rotZ, p3) end

---@param scale number
function SetMobilePhoneScale(scale) end

---@param toggle boolean
function SetMobilePhoneUnk(toggle) end

---@param toggle boolean
function SetMobileRadioEnabledDuringGameplay(toggle) end

---@param model Hash|string
function SetModelAsNoLongerNeeded(model) end

---@param modelHash Hash|string
---@param ratePerSecond number
---@param headlightRotation number
---@param invertRotation boolean
function SetModelHeadlightConfiguration(modelHash, ratePerSecond, headlightRotation, invertRotation) end

---@param shootingPed Ped
---@param targetPed Ped
---@param targetVehicle integer
---@param x number
---@param y number
---@param z number
function SetMountedWeaponTarget(shootingPed, targetPed, targetVehicle, x, y, z) end

function SetMouseCursorActiveThisFrame() end

---@param style integer
function SetMouseCursorSprite(style) end

---@param style integer
function SetMouseCursorStyle(style) end

function SetMouseCursorThisFrame() end

---@param isVisible boolean
function SetMouseCursorVisible(isVisible) end

---@param isVisible boolean
function SetMouseCursorVisibleInMenus(isVisible) end

---@param ped Ped
---@param name string
function SetMovementModeOverride(ped, name) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerHealthBarDisplay(gamerTagId, toggle) end

---@param gamerTagId integer
---@param health integer
---@param maximumHealth integer
function SetMpGamerHealthBarMax(gamerTagId, health, maximumHealth) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerTag(gamerTagId, toggle) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerTag_(gamerTagId, toggle) end

---@param gamerTagId integer
---@param component integer
---@param alpha integer
function SetMpGamerTagAlpha(gamerTagId, component, alpha) end

---@param gamerTagId integer
---@param string string
function SetMpGamerTagBigText(gamerTagId, string) end

---@param gamerTagId integer
---@param string string
function SetMpGamerTagChatting(gamerTagId, string) end

---@param player integer
---@param username string
---@param crewIsPrivate boolean
---@param crewIsRockstar boolean
---@param crewName string
---@param crewRank integer
---@param crewR integer
---@param crewG integer
---@param crewB integer
function SetMpGamerTagColor(player, username, crewIsPrivate, crewIsRockstar, crewName, crewRank, crewR, crewG, crewB) end

---@param gamerTagId integer
---@param component integer
---@param hudColorIndex integer
function SetMpGamerTagColour(gamerTagId, component, hudColorIndex) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerTagDisablePlayerHealthSync(gamerTagId, toggle) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerTagEnabled(gamerTagId, toggle) end

---@param gamerTagId integer
---@param hudColorIndex integer
function SetMpGamerTagHealthBarColor(gamerTagId, hudColorIndex) end

---@param gamerTagId integer
---@param hudColorIndex integer
function SetMpGamerTagHealthBarColour(gamerTagId, hudColorIndex) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerTagIcons(gamerTagId, toggle) end

---@param gamerTagId integer
---@param count integer
function SetMpGamerTagMpBagLargeCount(gamerTagId, count) end

---@param gamerTagId integer
---@param string string
function SetMpGamerTagName(gamerTagId, string) end

---@param gamerTagId integer
---@param health integer
---@param maximumHealth integer
function SetMpGamerTagOverridePlayerHealth(gamerTagId, health, maximumHealth) end

---@param enabled boolean
function SetMpGamerTagsUseVehicleBehavior(enabled) end

---@param distance number
function SetMpGamerTagsVisibleDistance(distance) end

---@param gamerTagId integer
---@param count integer
function SetMpGamerTagUnk(gamerTagId, count) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerTagUseVehicleHealth(gamerTagId, toggle) end

---@param gamerTagId integer
---@param component integer
---@param toggle boolean
function SetMpGamerTagVisibility(gamerTagId, component, toggle) end

---@param gamerTagId integer
---@param toggle boolean
function SetMpGamerTagVisibilityAll(gamerTagId, toggle) end

---@param gamerTagId integer
---@param wantedlvl integer
function SetMpGamerTagWantedLevel(gamerTagId, wantedlvl) end

function SetMultiplayerBankCash() end

---@param p0 integer
---@param p1 integer
function SetMultiplayerHudCash(p0, p1) end

function SetMultiplayerWalletCash() end

---@param toggle boolean
function SetNetworkCutsceneEntities(toggle) end

---@param vehicle integer
---@param toggle boolean
function SetNetworkEnableVehiclePositionCorrection(vehicle, toggle) end

---@param netId integer
---@param player integer
---@param toggle boolean
function SetNetworkIdAlwaysExistsForPlayer(netId, player, toggle) end

---@param netId integer
---@param toggle boolean
function SetNetworkIdCanMigrate(netId, toggle) end

---@param netId integer
---@param toggle boolean
function SetNetworkIdExistsOnAllMachines(netId, toggle) end

---@param netId integer
---@param player integer
---@param toggle boolean
function SetNetworkIdSyncToPlayer(netId, player, toggle) end

---@param netId integer
---@param p1 boolean
---@param p2 boolean
function SetNetworkIdVisibleInCutscene(netId, p1, p2) end

---@param vehicle integer
---@param toggle boolean
function SetNetworkObjectNonContact(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetNetworkVehicleAsGhost(vehicle, toggle) end

---@param vehicle integer
---@param multiplier number
function SetNetworkVehicleBlenderDistanceMultiplier(vehicle, multiplier) end

---@param vehicle integer
---@param multiplier number
function SetNetworkVehiclePositionUpdateMultiplier(vehicle, multiplier) end

---@param netId integer
---@param time integer
function SetNetworkVehicleRespotTimer(netId, time) end

---@param x number
---@param y number
function SetNewWaypoint(x, y) end

---@param p0 number
function SetNextDesiredMoveState(p0) end

---@param modifierName string
function SetNextPlayerTcmodifier(modifierName) end

function SetNextRespawnToCustom() end

---@param toggle boolean
function SetNightvision(toggle) end

---@param vehicle integer
---@param isActive boolean
function SetNitrousIsActive(vehicle, isActive) end

---@param toggle boolean
function SetNoiseoveride(toggle) end

---@param value number
function SetNoisinessoveride(value) end

---@param toggle boolean
function SetNoLoadingScreen(toggle) end

---@param toggle boolean
function SetNorthYanktonMap(toggle) end

---@param hudColorIndex integer
function SetNotificationBackgroundColor(hudColorIndex) end

---@param hudColor integer
function SetNotificationColorNext(hudColor) end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SetNotificationFlashColor(red, green, blue, alpha) end

---@param textureDict string
---@param textureName string
---@param flash boolean
---@param iconType integer
---@param sender string
---@param subject string
---@return integer
function SetNotificationMessage(textureDict, textureName, flash, iconType, sender, subject) end

---@param statTitle string
---@param iconEnum integer
---@param stepVal boolean
---@param barValue integer
---@param isImportant boolean
---@param picTxd string
---@param picTxn string
---@return integer
function SetNotificationMessage_2(statTitle, iconEnum, stepVal, barValue, isImportant, picTxd, picTxn) end

---@param txdName string
---@param textureName string
---@param flash boolean
---@param iconType integer
---@param sender string
---@param subject string
---@return integer
function SetNotificationMessage_3(txdName, textureName, flash, iconType, sender, subject) end

---@param picTxd string
---@param picTxn string
---@param flash boolean
---@param iconType integer
---@param nameStr string
---@param subtitleStr string
---@param durationMultiplier number
---@return integer
function SetNotificationMessage_4(picTxd, picTxn, flash, iconType, nameStr, subtitleStr, durationMultiplier) end

---@param picTxd string
---@param picTxn string
---@param flash boolean
---@param iconType integer
---@param nameStr string
---@param subtitleStr string
---@param duration number
---@param crewPackedStr string
---@return integer
function SetNotificationMessageClanTag(picTxd, picTxn, flash, iconType, nameStr, subtitleStr, duration, crewPackedStr) end

---@param picTxd string
---@param picTxn string
---@param flash boolean
---@param iconType1 integer
---@param nameStr string
---@param subtitleStr string
---@param duration number
---@param crewPackedStr string
---@param iconType2 integer
---@param textColor integer
---@return integer
function SetNotificationMessageClanTag_2(picTxd, picTxn, flash, iconType1, nameStr, subtitleStr, duration, crewPackedStr, iconType2, textColor) end

---@param text string
function SetNotificationTextEntry(text) end

---@param keepInput boolean
function SetNuiFocusKeepInput(keepInput) end

---@param zIndex integer
function SetNuiZindex(zIndex) end

---@param value integer
function SetNumberOfParkedVehicles(value) end

---@param object integer
---@param toggle boolean
function SetObjectAllowLowLodBuoyancy(object, toggle) end

---@return integer object
function SetObjectAsNoLongerNeeded() end

---@param object integer
---@param toggle boolean
function SetObjectCanClimbOn(object, toggle) end

---@param object integer
---@param toggle boolean
---@param R integer
---@param G integer
---@param B integer
function SetObjectColour(object, toggle, R, G, B) end

---@param object integer
---@param toggle boolean
function SetObjectForceVehiclesToAvoid(object, toggle) end

---@param object integer
---@param p1 boolean
---@param r integer
---@param g integer
---@param b integer
---@return unknown
function SetObjectLightColor(object, p1, r, g, b) end

---@param object integer
---@param mass number
---@param gravityFactor number
---@param linearC number
---@param linearV number
---@param linearV2 number
---@param angularC number
---@param angularV number
---@param angularV2 number
---@param p9 number
---@param maxAngSpeed number
---@param buoyancyFactor number
function SetObjectPhysicsParams(object, mass, gravityFactor, linearC, linearV, linearV2, angularC, angularV, angularV2, p9, maxAngSpeed, buoyancyFactor) end

---@param object integer
---@param toggle boolean
function SetObjectSomething(object, toggle) end

---@param object integer
---@param duration number
function SetObjectStuntPropDuration(object, duration) end

---@param object integer
---@param intensity integer
function SetObjectStuntPropSpeedup(object, intensity) end

---@param object integer
---@param targettable boolean
function SetObjectTargettable(object, targettable) end

---@param object integer
---@param setFlag34 boolean
---@param setFlag35 boolean
function SetObjectTargettableByPlayer(object, setFlag34, setFlag35) end

---@param object integer
---@param textureVariation integer
function SetObjectTextureVariant(object, textureVariation) end

---@param object integer
---@param textureVariation integer
function SetObjectTextureVariation(object, textureVariation) end

---@param vehicle integer
---@param toggle boolean
function SetOpenRearDoorsOnExplosion(vehicle, toggle) end

---@param vehicle integer
---@param extend boolean
function SetOppressorTransformState(vehicle, extend) end

---@param vehicle integer
---@param override boolean
function SetOverrideNitrousLevel(vehicle, override) end

---@param weatherType string
function SetOverrideWeather(weatherType) end

---@param padIndex integer
---@param duration integer
---@param frequency integer
function SetPadShake(padIndex, duration, frequency) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
function SetParachuteTaskTarget(ped, x, y, z) end

---@param ped Ped
---@param thrust number
function SetParachuteTaskThrust(ped, thrust) end

---@param multiplier number
function SetParkedVehicleDensityMultiplierThisFrame(multiplier) end

---@param oldAsset string
---@param newAsset string
function SetParticleFxAssetOldToNew(oldAsset, newAsset) end

---@param toggle boolean
function SetParticleFxBloodScale(toggle) end

---@param scale number
function SetParticleFxBulletImpactScale(scale) end

---@param vehicle integer
---@param p1 boolean
function SetParticleFxCamInsideNonplayerVehicle(vehicle, p1) end

---@param p0 boolean
function SetParticleFxCamInsideVehicle(p0) end

---@param ptfxHandle integer
---@param alpha number
function SetParticleFxLoopedAlpha(ptfxHandle, alpha) end

---@param ptfxHandle integer
---@param r number
---@param g number
---@param b number
---@param bLocalOnly boolean
function SetParticleFxLoopedColour(ptfxHandle, r, g, b, bLocalOnly) end

---@param ptfxHandle integer
---@param propertyName string
---@param amount number
---@param noNetwork boolean
function SetParticleFxLoopedEvolution(ptfxHandle, propertyName, amount, noNetwork) end

---@param ptfxHandle integer
---@param range number
function SetParticleFxLoopedFarClipDist(ptfxHandle, range) end

---@param ptfxHandle integer
---@param x number
---@param y number
---@param z number
---@param rotX number
---@param rotY number
---@param rotZ number
function SetParticleFxLoopedOffsets(ptfxHandle, x, y, z, rotX, rotY, rotZ) end

---@param ptfxHandle integer
---@param range number
function SetParticleFxLoopedRange(ptfxHandle, range) end

---@param ptfxHandle integer
---@param scale number
function SetParticleFxLoopedScale(ptfxHandle, scale) end

---@param alpha number
function SetParticleFxNonLoopedAlpha(alpha) end

---@param r number
---@param g number
---@param b number
function SetParticleFxNonLoopedColour(r, g, b) end

---@param p0 number
---@param p1 number
---@param scale number
function SetParticleFxNonLoopedEmitterScale(p0, p1, scale) end

---@param oldAsset string
---@param newAsset string
function SetParticleFxOverride(oldAsset, newAsset) end

---@param p0 unknown
function SetParticleFxShootoutBoat(p0) end

---@param toggle boolean
function SetPauseMenuActive(toggle) end

---@param state boolean
function SetPauseMenuPedLighting(state) end

---@param state boolean
function SetPauseMenuPedSleepState(state) end

---@param ped Ped
---@param accuracy integer
function SetPedAccuracy(ped, accuracy) end

---@param ped Ped
---@param hasCone boolean
function SetPedAiBlip(ped, hasCone) end

---@param ped Ped
---@param toggle boolean
function SetPedAiBlipForcedOn(ped, toggle) end

---@param ped Ped
---@param gangId integer
function SetPedAiBlipGangId(ped, gangId) end

---@param ped Ped
---@param toggle boolean
function SetPedAiBlipHasCone(ped, toggle) end

---@param ped Ped
---@param range number
function SetPedAiBlipNoticeRange(ped, range) end

---@param ped Ped
---@param spriteId integer
function SetPedAiBlipSprite(ped, spriteId) end

---@param ped Ped
---@param value integer
function SetPedAlertness(ped, value) end

---@param ped Ped
---@param toggle boolean
function SetPedAllowedToDuck(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedAllowVehiclesOverride(ped, toggle) end

---@param ped Ped
---@param stance integer
---@param animDictionary string
---@param animationName string
---@param p4 number
---@param p5 boolean
function SetPedAlternateMovementAnim(ped, stance, animDictionary, animationName, p4, p5) end

---@param ped Ped
---@param animDict string
---@param animName string
---@param p3 number
---@param p4 boolean
function SetPedAlternateWalkAnim(ped, animDict, animName, p3, p4) end

---@param ped Ped
---@param weaponHash Hash|string
---@param ammo integer
function SetPedAmmo(ped, weaponHash, ammo) end

---@param ped Ped
---@param ammoType Hash|string
---@param ammo integer
function SetPedAmmoByType(ped, ammoType, ammo) end

---@param ped Ped
---@param ammo integer
function SetPedAmmoToDrop(ped, ammo) end

---@param ped Ped
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 boolean
---@param p9 boolean
function SetPedAngledDefensiveArea(ped, p1, p2, p3, p4, p5, p6, p7, p8, p9) end

---@param ped Ped
---@param toggle boolean
function SetPedAoBlobRendering(ped, toggle) end

---@param ped Ped
---@param amount integer
function SetPedArmour(ped, amount) end

---@param ped Ped
---@param toggle boolean
function SetPedAsCop(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedAsEnemy(ped, toggle) end

---@param ped Ped
---@param groupId integer
function SetPedAsGroupLeader(ped, groupId) end

---@param ped Ped
---@param groupId integer
function SetPedAsGroupMember(ped, groupId) end

---@return Ped ped
function SetPedAsNoLongerNeeded() end

---@param ped Ped
---@param toggle boolean
function SetPedAudioFootstepLoud(ped, toggle) end

---@param ped Ped
---@param enabled boolean
function SetPedAudioFootstepQuiet(ped, enabled) end

---@param ped Ped
---@param p1 boolean
function SetPedAudioGender(ped, p1) end

---@param ped Ped
---@param father Ped
---@param mother Ped
---@param fathersSide number
---@param mothersSide number
function SetPedBlendFromParents(ped, father, mother, fathersSide, mothersSide) end

---@param ped Ped
---@param toggle boolean
function SetPedBlocksPathingWhenDead(ped, toggle) end

---@param ped Ped
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
function SetPedBoundsOrientation(ped, p1, p2, p3, p4, p5) end

---@param ped Ped
---@param toggle boolean
function SetPedCanArmIk(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanBeDraggedOut(ped, toggle) end

---@param ped Ped
---@param state integer
function SetPedCanBeKnockedOffVehicle(ped, state) end

---@param ped Ped
---@param toggle boolean
function SetPedCanBeShotInVehicle(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanBeTargetedWhenInjured(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanBeTargetedWithoutLos(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanBeTargetted(ped, toggle) end

---@param ped Ped
---@param player integer
---@param toggle boolean
function SetPedCanBeTargettedByPlayer(ped, player, toggle) end

---@param ped Ped
---@param team integer
---@param toggle boolean
function SetPedCanBeTargettedByTeam(ped, team, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanCowerInCover(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanEvasiveDive(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanHeadIk(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanLegIk(ped, toggle) end

---@param ped Ped
---@param loseProps boolean
---@param p2 integer
function SetPedCanLosePropsOnDamage(ped, loseProps, p2) end

---@param ped Ped
---@param toggle boolean
function SetPedCanPeekInCover(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanPlayAmbientAnims(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanPlayAmbientBaseAnims(ped, toggle) end

---@param ped Ped
---@param bBlockIdleClips boolean
---@param bRemoveIdleClipIfPlaying boolean
function SetPedCanPlayAmbientIdles(ped, bBlockIdleClips, bRemoveIdleClipIfPlaying) end

---@param ped Ped
---@param toggle boolean
function SetPedCanPlayGestureAnims(ped, toggle) end

---@param ped Ped
---@param p1 boolean
function SetPedCanPlayInjuredAnims(ped, p1) end

---@param ped Ped
---@param toggle boolean
---@param p2 boolean
function SetPedCanPlayVisemeAnims(ped, toggle, p2) end

---@param ped Ped
---@param toggle boolean
function SetPedCanRagdoll(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanRagdollFromPlayerImpact(ped, toggle) end

---@param ped Ped
---@param p1 boolean
---@param p2 boolean
function SetPedCanSmashGlass(ped, p1, p2) end

---@param ped Ped
---@param toggle boolean
function SetPedCanSwitchWeapon(ped, toggle) end

---@param pedHandle Ped
---@param groupHandle integer
---@param toggle boolean
function SetPedCanTeleportToGroupLeader(pedHandle, groupHandle, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedCanTorsoIk(ped, toggle) end

---@param ped Ped
---@param p1 boolean
function SetPedCanTorsoReactIk(ped, p1) end

---@param ped Ped
---@param p1 boolean
function SetPedCanTorsoVehicleIk(ped, p1) end

---@param ped Ped
---@param toggle boolean
function SetPedCanUseAutoConversationLookat(ped, toggle) end

---@param ped Ped
---@param value number
function SetPedCapsule(ped, value) end

---@param ped Ped
---@param xBias number
---@param yBias number
function SetPedChanceOfFiringBlanks(ped, xBias, yBias) end

---@param ped Ped
---@param enabled boolean
function SetPedClothEventsEnabled(ped, enabled) end

---@param ped Ped
---@param p1 integer
function SetPedClothPackageIndex(ped, p1) end

---@param p0 unknown
---@param p1 unknown
function SetPedClothProne(p0, p1) end

---@param ped Ped
---@param componentId integer
---@param collection string
---@param drawableId integer
---@param textureId integer
---@param paletteId integer
function SetPedCollectionComponentVariation(ped, componentId, collection, drawableId, textureId, paletteId) end

---@param ped Ped
---@param anchorPoint integer
---@param collection string
---@param propIndex integer
---@param textureId integer
function SetPedCollectionPreloadPropData(ped, anchorPoint, collection, propIndex, textureId) end

---@param ped Ped
---@param componentId integer
---@param collection string
---@param drawableId integer
---@param textureId integer
function SetPedCollectionPreloadVariationData(ped, componentId, collection, drawableId, textureId) end

---@param ped Ped
---@param anchorPoint integer
---@param collection string
---@param propIndex integer
---@param textureId integer
---@param attach boolean
function SetPedCollectionPropIndex(ped, anchorPoint, collection, propIndex, textureId, attach) end

---@param ped Ped
---@param p1 integer
function SetPedCombatAbility(ped, p1) end

---@param ped Ped
---@param attributeIndex integer
---@param enabled boolean
function SetPedCombatAttributes(ped, attributeIndex, enabled) end

---@param ped Ped
---@param combatMovement integer
function SetPedCombatMovement(ped, combatMovement) end

---@param ped Ped
---@param range integer
function SetPedCombatRange(ped, range) end

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
---@param posX number
---@param posY number
---@param posZ number
function SetPedCoordsKeepVehicle(ped, posX, posY, posZ) end

---@param ped Ped
---@param posX number
---@param posY number
---@param posZ number
function SetPedCoordsNoGang(ped, posX, posY, posZ) end

---@param ped Ped
---@param p1 string
function SetPedCoverClipsetOverride(ped, p1) end

---@param ped Ped
---@param p1 string
function SetPedCowerHash(ped, p1) end

---@param ped Ped
---@param visible boolean
---@param deselectWeapon boolean
---@param p3 boolean
---@param p4 boolean
function SetPedCurrentWeaponVisible(ped, visible, deselectWeapon, p3, p4) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function SetPedDecoration(ped, collection, overlay) end

---@param ped Ped
function SetPedDefaultComponentVariation(ped) end

---@param ped Ped
---@param attachPed Ped
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 number
---@param p9 boolean
---@param p10 boolean
function SetPedDefensiveAreaAttachedToPed(ped, attachPed, p2, p3, p4, p5, p6, p7, p8, p9, p10) end

---@param ped Ped
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 boolean
function SetPedDefensiveAreaDirection(ped, p1, p2, p3, p4) end

---@param ped Ped
---@param target Ped
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param radius number
---@param p6 boolean
function SetPedDefensiveSphereAttachedToPed(ped, target, xOffset, yOffset, zOffset, radius, p6) end

---@param ped Ped
---@param target integer
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param radius number
---@param p6 boolean
function SetPedDefensiveSphereAttachedToVehicle(ped, target, xOffset, yOffset, zOffset, radius, p6) end

---@param multiplier number
function SetPedDensityMultiplierThisFrame(multiplier) end

---@param ped Ped
---@param heading number
function SetPedDesiredHeading(ped, heading) end

---@param ped Ped
---@param p1 number
function SetPedDesiredMoveBlendRatio(ped, p1) end

---@param ped Ped
---@param toggle boolean
function SetPedDiesInSinkingVehicle(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedDiesInstantlyInWater(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedDiesInVehicle(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedDiesInWater(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedDiesWhenInjured(ped, toggle) end

---@param ped Ped
---@param clipset string
function SetPedDriveByClipsetOverride(ped, clipset) end

---@param ped Ped
---@param weaponHash Hash|string
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param ammoCount integer
function SetPedDropsInventoryWeapon(ped, weaponHash, xOffset, yOffset, zOffset, ammoCount) end

---@param ped Ped
function SetPedDropsWeapon(ped) end

---@param ped Ped
---@param toggle boolean
function SetPedDropsWeaponsWhenDead(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedDucking(ped, toggle) end

---@param ped Ped
---@param intensity number
function SetPedEmissiveIntensity(ped, intensity) end

---@param vehicle integer
---@param entity Entity
---@return boolean
function SetPedEnabledBikeRingtone(vehicle, entity) end

---@param ped Ped
---@param toggle boolean
function SetPedEnableWeaponBlocking(ped, toggle) end

---@param ped Ped
---@param hasCone boolean
function SetPedEnemyAiBlip(ped, hasCone) end

---@param ped Ped
---@param r integer
---@param g integer
---@param b integer
function SetPedEnveffColorModulator(ped, r, g, b) end

---@param ped Ped
---@param value number
function SetPedEnveffScale(ped, value) end

---@param ped Ped
---@param index integer
function SetPedEyeColor(ped, index) end

---@param ped Ped
---@param index integer
---@param scale number
function SetPedFaceFeature(ped, index, scale) end

---@param ped Ped
---@param collection Hash|string
---@param overlay Hash|string
function SetPedFacialDecoration(ped, collection, overlay) end

---@param ped Ped
---@param patternHash Hash|string
function SetPedFiringPattern(ped, patternHash) end

---@param ped Ped
---@param attributeFlags integer
---@param enable boolean
function SetPedFleeAttributes(ped, attributeFlags, enable) end

---@param ped Ped
---@param gadgetHash Hash|string
---@param p2 boolean
function SetPedGadget(ped, gadgetHash, p2) end

---@param ped Ped
---@param toggle boolean
function SetPedGeneratesDeadBodyEvents(ped, toggle) end

---@param ped Ped
---@param animGroupGesture string
function SetPedGestureGroup(ped, animGroupGesture) end

---@param ped Ped
---@param toggle boolean
function SetPedGetOutUpsideDownVehicle(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedGravity(ped, toggle) end

---@param ped Ped
---@param index integer
function SetPedGroupMemberPassengerIndex(ped, index) end

---@param ped Ped
---@param colorID integer
---@param highlightColorID integer
function SetPedHairColor(ped, colorID, highlightColorID) end

---@param ped Ped
---@param colorID integer
---@param highlightColorID integer
function SetPedHairTint(ped, colorID, highlightColorID) end

---@param ped Ped
---@param hasCone boolean
function SetPedHasAiBlip(ped, hasCone) end

---@param ped Ped
---@param hasCone boolean
---@param color integer
function SetPedHasAiBlipWithColor(ped, hasCone, color) end

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
---@param value number
function SetPedHearingRange(ped, value) end

---@param ped Ped
---@param heatScale number
function SetPedHeatscaleOverride(ped, heatScale) end

---@param ped Ped
---@param bEnable boolean
function SetPedHelmet(ped, bEnable) end

---@param ped Ped
---@param helmetFlag integer
function SetPedHelmetFlag(ped, helmetFlag) end

---@param ped Ped
---@param propIndex integer
function SetPedHelmetPropIndex(ped, propIndex) end

---@param ped Ped
---@param textureIndex integer
function SetPedHelmetTextureIndex(ped, textureIndex) end

---@param ped Ped
---@param p1 boolean
---@param p2 integer
---@param p3 integer
function SetPedHelmetUnk(ped, p1, p2, p3) end

---@param ped Ped
---@param toggle boolean
function SetPedHighlyPerceptive(ped, toggle) end

---@param ped Ped
---@param value number
function SetPedIdRange(ped, value) end

---@param ped Ped
---@param intensity number
function SetPedIlluminatedClothingGlowIntensity(ped, intensity) end

---@param ped Ped
function SetPedIncreasedAvoidanceRadius(ped) end

---@param ped Ped
---@param toggle boolean
---@param weaponHash Hash|string
function SetPedInfiniteAmmo(ped, toggle, weaponHash) end

---@param ped Ped
---@param toggle boolean
function SetPedInfiniteAmmoClip(ped, toggle) end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
function SetPedIntoVehicle(ped, vehicle, seatIndex) end

---@param ped Ped
---@param context Hash|string
function SetPedInVehicleContext(ped, context) end

---@param ped Ped
---@param toggle boolean
function SetPedIsDrunk(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedKeepTask(ped, toggle) end

---@param ped Ped
---@param mode integer
function SetPedLegIkMode(ped, mode) end

---@param ped Ped
---@param multiplier number
function SetPedLodMultiplier(ped, multiplier) end

---@param ped Ped
---@param value integer
function SetPedMaxHealth(ped, value) end

---@param ped Ped
---@param value number
function SetPedMaxMoveBlendRatio(ped, value) end

---@param ped Ped
---@param value number
function SetPedMaxTimeInWater(ped, value) end

---@param ped Ped
---@param value number
function SetPedMaxTimeUnderwater(ped, value) end

---@param primaryCount integer
---@param secondaryCount integer
---@param populationPedCount integer
function SetPedMeleeCombatLimits(primaryCount, secondaryCount, populationPedCount) end

---@param ped Ped
---@param minTimeInMs integer
function SetPedMinGroundTimeForStungun(ped, minTimeInMs) end

---@param ped Ped
---@param value number
function SetPedMinMoveBlendRatio(ped, value) end

---@param modelHash Hash|string
---@param configName string
function SetPedModelHealthConfig(modelHash, configName) end

---@param model Hash|string
---@param toggle boolean
function SetPedModelIsSuppressed(model, toggle) end

---@param modelHash Hash|string
---@param personalityHash Hash|string
function SetPedModelPersonality(modelHash, personalityHash) end

---@param ped Ped
---@param amount integer
function SetPedMoney(ped, amount) end

---@param ped Ped
---@param toggle boolean
function SetPedMotionBlur(ped, toggle) end

---@param ped Ped
function SetPedMoveAnimsBlendOut(ped) end

---@param ped Ped
---@param clipSet string
---@param transitionSpeed number
function SetPedMovementClipset(ped, clipSet, transitionSpeed) end

---@param ped Ped
---@param value number
function SetPedMoveRateOverride(ped, value) end

---@param ped Ped
function SetPedMute(ped) end

---@param ped Ped
---@param name string
function SetPedNameDebug(ped, name) end

---@param ped Ped
---@param toggle boolean
function SetPedNeverLeavesGroup(ped, toggle) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
function SetPedNonCreationArea(x1, y1, z1, x2, y2, z2) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@return unknown
function SetPedPanicExitScenario(ped, x, y, z) end

---@param ped Ped
---@param tintIndex integer
function SetPedParachuteTintIndex(ped, tintIndex) end

---@param ped Ped
---@param avoidFire boolean
function SetPedPathAvoidFire(ped, avoidFire) end

---@param ped Ped
---@param Toggle boolean
function SetPedPathCanDropFromHeight(ped, Toggle) end

---@param ped Ped
---@param Toggle boolean
function SetPedPathCanUseClimbovers(ped, Toggle) end

---@param ped Ped
---@param Toggle boolean
function SetPedPathCanUseLadders(ped, Toggle) end

---@param ped Ped
---@param modifier number
function SetPedPathClimbCostModifier(ped, modifier) end

---@param ped Ped
---@param mayEnterWater boolean
function SetPedPathMayEnterWater(ped, mayEnterWater) end

---@param ped Ped
---@param avoidWater boolean
function SetPedPathPreferToAvoidWater(ped, avoidWater) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
function SetPedPathsBackToOriginal(p0, p1, p2, p3, p4, p5) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param unknown boolean
function SetPedPathsInArea(x1, y1, z1, x2, y2, z2, unknown) end

---@param ped Ped
---@param mayEnterWater boolean
function SetPedPathsWidthPlant(ped, mayEnterWater) end

---@param ped Ped
---@param index integer
function SetPedPhonePaletteIdx(ped, index) end

---@param ped Ped
---@param pinned boolean
---@param i integer
---@return unknown
function SetPedPinnedDown(ped, pinned, i) end

---@param ped Ped
---@param toggle boolean
function SetPedPlaysHeadOnHornAnimWhenDiesInVehicle(ped, toggle) end

---@param budgetLevel integer
function SetPedPopulationBudget(budgetLevel) end

---@param ped Ped
---@param itemSet unknown
function SetPedPreferredCoverSet(ped, itemSet) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@return boolean
function SetPedPreloadPropData(ped, componentId, drawableId, textureId) end

---@param ped Ped
---@param slot integer
---@param drawableId integer
---@param textureId integer
---@return unknown
function SetPedPreloadVariationData(ped, slot, drawableId, textureId) end

---@param ped Ped
---@param lookAt Ped
function SetPedPrimaryLookat(ped, lookAt) end

---@param ped Ped
---@param componentId integer
---@param drawableId integer
---@param textureId integer
---@param attach boolean
function SetPedPropIndex(ped, componentId, drawableId, textureId, attach) end

---@param ped Ped
---@param pedRace integer
---@param pvgHash integer
function SetPedRaceAndVoiceGroup(ped, pedRace, pvgHash) end

---@param ped Ped
---@param flags integer
function SetPedRagdollBlockingFlags(ped, flags) end

---@param ped Ped
function SetPedRagdollForceFall(ped) end

---@param ped Ped
---@param toggle boolean
function SetPedRagdollOnCollision(ped, toggle) end

---@param ped Ped
---@param p1 integer
function SetPedRandomComponentVariation(ped, p1) end

---@param ped Ped
function SetPedRandomProps(ped) end

---@param ped Ped
---@param hash Hash|string
function SetPedRelationshipGroupDefaultHash(ped, hash) end

---@param ped Ped
---@param hash Hash|string
function SetPedRelationshipGroupHash(ped, hash) end

---@param ped Ped
---@param p1 unknown
function SetPedReserveParachuteTintIndex(ped, p1) end

---@param ped Ped
---@param flagId integer
---@param doReset boolean
function SetPedResetFlag(ped, flagId, doReset) end

---@param ped Ped
function SetPedScream(ped) end

---@param ped Ped
function SetPedScubaGearVariation(ped) end

---@param ped Ped
---@param value number
function SetPedSeeingRange(ped, value) end

---@param ped Ped
---@param p1 number
---@return integer
function SetPedShootOrdnanceWeapon(ped, p1) end

---@param ped Ped
---@param shootRate integer
function SetPedShootRate(ped, shootRate) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param toggle boolean
function SetPedShootsAtCoord(ped, x, y, z, toggle) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@return boolean
function SetPedShouldPlayDirectedScenarioExit(ped, x, y, z) end

---@param ped Ped
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return unknown
function SetPedShouldPlayFleeScenarioExit(ped, p1, p2, p3) end

---@param ped Ped
function SetPedShouldPlayImmediateScenarioExit(ped) end

---@param ped Ped
function SetPedShouldPlayNormalScenarioExit(ped) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param radius number
---@param p5 boolean
---@param p6 boolean
function SetPedSphereDefensiveArea(ped, x, y, z, radius, p5, p6) end

---@param ped Ped
---@param toggle boolean
function SetPedStayInVehicleWhenJacked(ped, toggle) end

---@param ped Ped
---@param p1 boolean
---@param action string
function SetPedStealthMovement(ped, p1, action) end

---@param ped Ped
---@param toggle boolean
function SetPedSteersAroundObjects(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedSteersAroundPeds(ped, toggle) end

---@param ped Ped
---@param toggle boolean
function SetPedSteersAroundVehicles(ped, toggle) end

---@param ped Ped
---@param clipSet string
function SetPedStrafeClipset(ped, clipSet) end

---@param ped Ped
---@param toggle boolean
function SetPedSuffersCriticalHits(ped, toggle) end

---@param ped Ped
---@param sweat number
function SetPedSweat(ped, sweat) end

---@param opponentPed Ped
function SetPedTalk(opponentPed) end

---@param ped Ped
---@param responseType integer
function SetPedTargetLossResponse(ped, responseType) end

---@param vehicle integer
---@param doorIndex integer
---@param doorLockStatus integer
function SetPedTargettableVehicleDestroy(vehicle, doorIndex, doorLockStatus) end

---@param ped Ped
---@param radius number
---@param maxFriends integer
function SetPedToInformRespectedFriends(ped, radius, maxFriends) end

---@param ped Ped
---@param toggle boolean
function SetPedToLoadCover(ped, toggle) end

---@param ped Ped
---@param time1 integer
---@param time2 integer
---@param ragdollType integer
---@param p4 boolean
---@param p5 boolean
---@param p6 boolean
---@return boolean
function SetPedToRagdoll(ped, time1, time2, ragdollType, p4, p5, p6) end

---@param ped Ped
---@param time integer
---@param p2 integer
---@param ragdollType integer
---@param x number
---@param y number
---@param z number
---@param p7 number
---@param p8 number
---@param p9 number
---@param p10 number
---@param p11 number
---@param p12 number
---@param p13 number
---@return boolean
function SetPedToRagdollWithFall(ped, time, p2, ragdollType, x, y, z, p7, p8, p9, p10, p11, p12, p13) end

---@param min number
---@param max number
function SetPedTurningThresholds(min, max) end

---@param ped Ped
---@param p1 boolean
---@param p2 integer
---@param action string
function SetPedUsingActionMode(ped, p1, p2, action) end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
---@param flags integer
function SetPedVehicleForcedSeatUsage(ped, vehicle, seatIndex, flags) end

---@param ped Ped
---@param angle number
function SetPedVisualFieldCenterAngle(ped, angle) end

---@param ped Ped
---@param value number
function SetPedVisualFieldMaxAngle(ped, value) end

---@param ped Ped
---@param angle number
function SetPedVisualFieldMaxElevationAngle(ped, angle) end

---@param ped Ped
---@param value number
function SetPedVisualFieldMinAngle(ped, value) end

---@param ped Ped
---@param angle number
function SetPedVisualFieldMinElevationAngle(ped, angle) end

---@param ped Ped
---@param range number
function SetPedVisualFieldPeripheralRange(ped, range) end

---@param ped Ped
function SetPedVoiceFull(ped) end

---@param ped Ped
---@param voiceGroupHash Hash|string
function SetPedVoiceGroup(ped, voiceGroupHash) end

---@param ped Ped
---@param voiceGroupHash Hash|string
function SetPedVoiceGroupRace(ped, voiceGroupHash) end

---@param density number
---@param applyValue number
function SetPedWallaDensity(density, applyValue) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@return unknown
function SetPedWaypointRouteOffset(p0, p1, p2, p3) end

---@param ped Ped
---@param weaponHash Hash|string
---@param camoComponentHash Hash|string
---@param colorIndex integer
function SetPedWeaponLiveryColor(ped, weaponHash, camoComponentHash, colorIndex) end

---@param ped Ped
---@param clipSet string
function SetPedWeaponMovementClipset(ped, clipSet) end

---@param ped Ped
---@param weaponHash Hash|string
---@param tintIndex integer
function SetPedWeaponTintIndex(ped, weaponHash, tintIndex) end

---@param ped Ped
function SetPedWetnessEnabledThisFrame(ped) end

---@param ped Ped
---@param height number
function SetPedWetnessHeight(ped, height) end

---@param toggle boolean
function SetPhoneLean(toggle) end

---@param p0 number
function SetPickupAmmoAmountScaler(p0) end

---@param entity Entity
---@param toggle boolean
function SetPickUpByCargobobDisabled(entity, toggle) end

---@param multiplier number
function SetPickupGenerationRangeMultiplier(multiplier) end

---@param p0 unknown
---@param p1 unknown
function SetPickupHiddenWhenUncollectable(p0, p1) end

---@param pickup integer
---@param duration integer
function SetPickupRegenerationTime(pickup, duration) end

---@param cargobob integer
---@param length1 number
---@param length2 number
---@param state boolean
function SetPickupRopeLengthForCargobob(cargobob, length1, length2, state) end

---@param p0 unknown
---@param p1 unknown
function SetPickupUncollectable(p0, p1) end

---@param vehicle integer
---@param health number
function SetPlaneEngineHealth(vehicle, health) end

---@param plane integer
---@param height integer
function SetPlaneMinHeightAboveGround(plane, height) end

---@param plane integer
---@param height integer
function SetPlaneMinHeightAboveTerrain(plane, height) end

---@param plane integer
---@param health number
function SetPlanePropellersHealth(plane, health) end

---@param vehicle integer
---@param toggle boolean
function SetPlaneResistToExplosion(vehicle, toggle) end

---@param vehicle integer
---@param damageSection integer
---@param damageScale number
function SetPlaneSectionDamageScale(vehicle, damageSection, damageScale) end

---@param vehicle integer
---@param multiplier number
function SetPlaneTurbulenceMultiplier(vehicle, multiplier) end

---@param vehicle integer
---@param direction boolean
function SetPlaneVtolAnimationDisabled(vehicle, direction) end

---@param vehicle integer
---@param angleRatio number
function SetPlaneVtolDesiredDirection(vehicle, angleRatio) end

---@param vehicle integer
---@param angle number
function SetPlaneVtolDirection(vehicle, angle) end

---@param vehicle integer
---@param speed number
function SetPlaybackSpeed(vehicle, speed) end

---@param vehicle integer
---@param drivingStyle integer
function SetPlaybackToUseAi(vehicle, drivingStyle) end

---@param vehicle integer
---@param time integer
---@param drivingStyle integer
---@param p3 boolean
function SetPlaybackToUseAiTryToRevertBackLater(vehicle, time, drivingStyle, p3) end

---@param player integer
---@param zoneId integer
---@param enable boolean
function SetPlayerAirDefenseZoneFlag(player, zoneId, enable) end

---@param ped Ped
---@param isAngry boolean
function SetPlayerAngry(ped, isAngry) end

---@param x number
---@param y number
function SetPlayerBlipPositionThisFrame(x, y) end

---@param player integer
---@param state boolean
function SetPlayerBluetoothState(player, state) end

---@param player integer
---@param toggle boolean
function SetPlayerCanBeHassledByGangs(player, toggle) end

---@param player integer
---@param toggle boolean
function SetPlayerCanDoDriveBy(player, toggle) end

---@param player integer
---@param enabled boolean
function SetPlayerCanLeaveParachuteSmokeTrail(player, enabled) end

---@param player integer
---@param toggle boolean
function SetPlayerCanUseCover(player, toggle) end

---@param cash integer
---@param bank integer
function SetPlayerCashChange(cash, bank) end

---@param value integer
function SetPlayerClothLockCounter(value) end

---@param index integer
function SetPlayerClothPackageIndex(index) end

---@param player integer
---@param p1 integer
function SetPlayerClothPinFrames(player, p1) end

---@param player integer
---@param bHasControl boolean
---@param flags integer
function SetPlayerControl(player, bHasControl, flags) end

---@param player integer
---@param distance number
function SetPlayerFallDistance(player, distance) end

---@param player integer
---@param toggle boolean
function SetPlayerForcedAim(player, toggle) end

---@param player integer
---@param toggle boolean
function SetPlayerForcedZoom(player, toggle) end

---@param player integer
---@param toggle boolean
function SetPlayerForceSkipAimIntro(player, toggle) end

---@param player integer
function SetPlayerHasReserveParachute(player) end

---@param player integer
---@param limit number
function SetPlayerHealthRechargeLimit(player, limit) end

---@param player integer
---@param regenRate number
function SetPlayerHealthRechargeMultiplier(player, regenRate) end

---@param player integer
---@param p1 boolean
function SetPlayerHomingRocketDisabled(player, p1) end

---@return integer
function SetPlayerInvertedUp() end

---@param player integer
---@param bInvincible boolean
function SetPlayerInvincible(player, bInvincible) end

---@param player integer
---@param toggle boolean
function SetPlayerInvincibleKeepRagdollEnabled(player, toggle) end

---@param player integer
---@param toggle boolean
function SetPlayerInvisibleLocally(player, toggle) end

---@param toggle boolean
function SetPlayerIsInAnimalForm(toggle) end

---@param toggle boolean
function SetPlayerIsInDirectorMode(toggle) end

---@param height number
function SetPlayerKillFallHeight(height) end

---@param player integer
---@param toggle boolean
function SetPlayerLeavePedBehind(player, toggle) end

---@param player integer
---@param toggle boolean
function SetPlayerLockon(player, toggle) end

---@param player integer
---@param range number
function SetPlayerLockonRangeOverride(player, range) end

---@param player integer
---@param value integer
function SetPlayerMaxArmour(player, value) end

---@param playerId integer
---@param maxStamina number
---@return boolean
function SetPlayerMaxStamina(playerId, maxStamina) end

---@param player integer
function SetPlayerMayNotEnterAnyVehicle(player) end

---@param player integer
---@param vehicle integer
function SetPlayerMayOnlyEnterThisVehicle(player, vehicle) end

---@param player integer
---@param modifier number
function SetPlayerMeleeWeaponDamageModifier(player, modifier) end

---@param player integer
---@param modifier number
function SetPlayerMeleeWeaponDefenseModifier(player, modifier) end

---@param player integer
---@param model Hash|string
function SetPlayerModel(player, model) end

---@param player integer
---@param multiplier number
function SetPlayerNoiseMultiplier(player, multiplier) end

---@param toggle boolean
function SetPlayerpadShakesWhenControllerDisabled(toggle) end

---@param player integer
---@param model Hash|string
function SetPlayerParachuteModelOverride(player, model) end

---@param player integer
---@param model Hash|string
function SetPlayerParachutePackModelOverride(player, model) end

---@param player integer
---@param tintIndex integer
function SetPlayerParachutePackTintIndex(player, tintIndex) end

---@param player integer
---@param r integer
---@param g integer
---@param b integer
function SetPlayerParachuteSmokeTrailColor(player, r, g, b) end

---@param player integer
---@param tintIndex integer
function SetPlayerParachuteTintIndex(player, tintIndex) end

---@param player integer
---@param p1 integer
---@param p2 unknown
---@param p3 unknown
---@param p4 boolean
function SetPlayerParachuteVariationOverride(player, p1, p2, p3, p4) end

---@param player integer
---@param model Hash|string
function SetPlayerReserveParachuteModelOverride(player, model) end

---@param player integer
---@param index integer
function SetPlayerReserveParachuteTintIndex(player, index) end

---@param player integer
---@param flags integer
function SetPlayerResetFlagPreferRearSeats(player, flags) end

---@param toggle boolean
function SetPlayerRockstarEditorDisabled(toggle) end

---@param style integer
function SetPlayerShortSwitchStyle(style) end

---@param player integer
---@param toggle boolean
function SetPlayerSimulateAiming(player, toggle) end

---@param vehicle integer
function SetPlayersLastVehicle(vehicle) end

---@param player integer
---@param multiplier number
function SetPlayerSneakingNoiseMultiplier(player, multiplier) end

---@param player integer
---@param toggle boolean
function SetPlayerSprint(player, toggle) end

---@param playerId integer
---@param stamina number
---@return boolean
function SetPlayerStamina(playerId, stamina) end

---@param player integer
---@param value number
function SetPlayerStealthPerceptionModifier(player, value) end

---@param name string
function SetPlayerSwitchEstablishingShot(name) end

---@param cameraCoordX number
---@param cameraCoordY number
---@param cameraCoordZ number
---@param camRotationX number
---@param camRotationY number
---@param camRotationZ number
---@param camFov number
---@param camFarClip number
---@param rotationOrder integer
function SetPlayerSwitchOutro(cameraCoordX, cameraCoordY, cameraCoordZ, camRotationX, camRotationY, camRotationZ, camFov, camFarClip, rotationOrder) end

---@param player integer
---@param state boolean
function SetPlayerTalkingOverride(player, state) end

---@param targetMode integer
function SetPlayerTargetingMode(targetMode) end

---@param targetLevel integer
function SetPlayerTargetLevel(targetLevel) end

---@param value number
function SetPlayerTcmodifierTransition(value) end

---@param player integer
---@param team integer
function SetPlayerTeam(player, team) end

---@param player integer
---@param percentage number
---@return unknown
function SetPlayerUnderwaterTimeRemaining(player, percentage) end

---@param vehicle integer
---@param active boolean
function SetPlayerVehicleAlarmAudioActive(vehicle, active) end

---@param player integer
---@param modifier number
function SetPlayerVehicleDamageModifier(player, modifier) end

---@param player integer
---@param modifier number
function SetPlayerVehicleDefenseModifier(player, modifier) end

---@param player integer
---@param toggle boolean
function SetPlayerVisibleLocally(player, toggle) end

---@param player integer
---@param p2 boolean
---@param p3 boolean
---@return vector3 position
function SetPlayerWantedCentrePosition(player, p2, p3) end

---@param player integer
---@param wantedLevel integer
---@param delayedResponse boolean
function SetPlayerWantedLevel(player, wantedLevel, delayedResponse) end

---@param player integer
---@param wantedLevel integer
---@param delayedResponse boolean
function SetPlayerWantedLevelNoDrop(player, wantedLevel, delayedResponse) end

---@param player integer
---@param p1 boolean
function SetPlayerWantedLevelNow(player, p1) end

---@param player integer
---@param modifier number
function SetPlayerWeaponDamageModifier(player, modifier) end

---@param player integer
---@param modifier number
function SetPlayerWeaponDefenseModifier(player, modifier) end

---@param player integer
---@param modifier number
function SetPlayerWeaponDefenseModifier_2(player, modifier) end

---@param vehicle integer
---@param p1 boolean
function SetPoliceFocusWillTrackVehicle(vehicle, p1) end

---@param player integer
---@param toggle boolean
function SetPoliceIgnorePlayer(player, toggle) end

---@param toggle boolean
function SetPoliceRadarBlips(toggle) end

---@param x number
---@param y number
---@param z number
---@param min number
---@param max number
function SetPopControlSphereThisFrame(x, y, z, min, max) end

---@param oldPortalSettingsName string
---@param newPortalSettingsName string
function SetPortalSettingsOverride(oldPortalSettingsName, newPortalSettingsName) end

---@param enabled boolean
function SetPositionedPlayerVehicleRadioEmitterEnabled(enabled) end

---@param speakerConversationIndex integer
---@param x number
---@param y number
---@param z number
function SetPositionForNullConvPed(speakerConversationIndex, x, y, z) end

function SetProfileSettingPrologueComplete() end

---@param name string
function SetPtfxAssetNextCall(name) end

---@param oldAsset string
---@param newAsset string
function SetPtfxAssetOld_2New(oldAsset, newAsset) end

---@param toggle boolean
function SetRaceTrackRender(toggle) end

function SetRadarAsExteriorThisFrame() end

---@param interior Hash|string
---@param x number
---@param y number
---@param heading integer
---@param zoom integer
function SetRadarAsInteriorThisFrame(interior, x, y, heading, zoom) end

---@param toggleBigMap boolean
---@param showFullMap boolean
function SetRadarBigmapEnabled(toggleBigMap, showFullMap) end

---@param zoomLevel integer
function SetRadarZoom(zoomLevel) end

---@param zoom number
function SetRadarZoomLevelThisFrame(zoom) end

---@param zoom number
function SetRadarZoomPrecise(zoom) end

---@param blip integer
---@param zoom number
function SetRadarZoomToBlip(blip, zoom) end

---@param zoom number
function SetRadarZoomToDistance(zoom) end

---@param toggle boolean
function SetRadioAutoUnfreeze(toggle) end

---@param fadeTime number
function SetRadioFrontendFadeTime(fadeTime) end

---@param radioStationName string
---@param toggle boolean
function SetRadioStationDisabled(radioStationName, toggle) end

---@param radioStation string
---@param toggle boolean
function SetRadioStationIsVisible(radioStation, toggle) end

---@param radioStation string
---@param toggle boolean
function SetRadioStationMusicOnly(radioStation, toggle) end

---@param radioStation integer
function SetRadioToStationIndex(radioStation) end

---@param stationName string
function SetRadioToStationName(stationName) end

---@param radioStation string
---@param radioTrack string
function SetRadioTrack(radioStation, radioTrack) end

---@param radioStationName string
---@param mixName string
---@param p2 integer
function SetRadioTrackMix(radioStationName, mixName, p2) end

---@param blip integer
---@param toggle boolean
function SetRadiusBlipEdge(blip, toggle) end

---@param ped Ped
---@param flags integer
function SetRagdollBlockingFlags(ped, flags) end

---@param level number
function SetRainFxIntensity(level) end

---@param level number
function SetRainLevel(level) end

---@param vehicle integer
---@param toggle boolean
function SetRampVehicleReceivesRampDamage(vehicle, toggle) end

---@param toggle boolean
function SetRandomBoats(toggle) end

---@param toggle boolean
function SetRandomBoatsInMp(toggle) end

---@param toggle boolean
function SetRandomEventFlag(toggle) end

---@param seed integer
function SetRandomSeed(seed) end

---@param toggle boolean
function SetRandomTrains(toggle) end

---@param multiplier number
function SetRandomVehicleDensityMultiplierThisFrame(multiplier) end

function SetRandomWeatherType() end

---@param state boolean
function SetReactionToVehicleSirenDisabled(state) end

---@param state boolean
function SetReactionToVehicleWithSirenDisabled(state) end

---@param vehicle integer
---@param enable boolean
function SetReduceDriftVehicleSuspension(vehicle, enable) end

---@param toggle boolean
function SetReducePedModelBudget(toggle) end

---@param toggle boolean
function SetReduceVehicleModelBudget(toggle) end

---@param relationship integer
---@param group1 Hash|string
---@param group2 Hash|string
function SetRelationshipBetweenGroups(relationship, group1, group2) end

---@param group Hash|string
---@param p1 boolean
function SetRelationshipGroupDontAffectWantedLevel(group, p1) end

---@param player integer
---@param p1 boolean
function SetRelationshipToPlayer(player, p1) end

---@param toggle boolean
function SetRenderHdOnly(toggle) end

---@param train integer
---@param toggle boolean
function SetRenderTrainAsDerailed(train, toggle) end

---@param x number
---@param y number
---@param z number
---@param heading number
function SetRestartCustomPosition(x, y, z, heading) end

---@param presenceState string
function SetRichPresence(presenceState) end

---@param toggle boolean
function SetRiotModeEnabled(toggle) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
function SetRoadsBackToOriginal(p0, p1, p2, p3, p4, p5) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
function SetRoadsBackToOriginalInAngledArea(x1, y1, z1, x2, y2, z2, width) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param width number
---@param unknown1 boolean
---@param unknown2 boolean
---@param unknown3 boolean
function SetRoadsInAngledArea(x1, y1, z1, x2, y2, z2, width, unknown1, unknown2, unknown3) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param nodeEnabled boolean
---@param unknown2 boolean
function SetRoadsInArea(x1, y1, z1, x2, y2, z2, nodeEnabled, unknown2) end

---@param rope integer
---@param lengthChangeRate number
function SetRopeLengthChangeRate(rope, lengthChangeRate) end

---@param shouldCreate boolean
function SetRopesCreateNetworkWorldState(shouldCreate) end

---@param player integer
---@param multiplier number
function SetRunSprintMultiplierForPlayer(player, multiplier) end

---@param tex integer
---@param buffer string
---@param length integer
---@return boolean
function SetRuntimeTextureArgbData(tex, buffer, length) end

---@param tex integer
---@param fileName string
---@return boolean
function SetRuntimeTextureImage(tex, fileName) end

---@param tex integer
---@param x integer
---@param y integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function SetRuntimeTexturePixel(tex, x, y, r, g, b, a) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function SetSaveHouse(p0, p1, p2) end

---@param ignoreVehicle boolean
function SetSaveMenuActive(ignoreVehicle) end

---@param transactionId integer
function SetSaveMigrationTransactionId(transactionId) end

---@param scaleformHandle integer
---@param toggle boolean
function SetScaleformFitRendertarget(scaleformHandle, toggle) end

---@return integer scaleformHandle
function SetScaleformMovieAsNoLongerNeeded() end

---@param scaleformMovieId integer
---@param useLargeRT boolean
function SetScaleformMovieToUseLargeRt(scaleformMovieId, useLargeRT) end

---@param scaleformHandle integer
---@param toggle boolean
function SetScaleformMovieToUseSuperLargeRt(scaleformHandle, toggle) end

---@param scaleform integer
---@param toggle boolean
function SetScaleformMovieToUseSystemTime(scaleform, toggle) end

---@param scenarioGroup string
---@param p1 boolean
function SetScenarioGroupEnabled(scenarioGroup, p1) end

---@param interiorMult number
---@param exteriorMult number
function SetScenarioPedDensityMultiplierThisFrame(interiorMult, exteriorMult) end

---@param x number
---@param y number
---@param z number
---@param range number
---@param p4 integer
function SetScenarioPedsSpawnInSphereArea(x, y, z, range, p4) end

---@param value boolean
function SetScenarioPedsToBeReturnedByNextCommand(value) end

---@param scenarioType string
---@param toggle boolean
function SetScenarioTypeEnabled(scenarioType, toggle) end

---@param horizontalAlign integer
---@param verticalAlign integer
function SetScreenDrawPosition(horizontalAlign, verticalAlign) end

---@param scriptName string
function SetScriptAsNoLongerNeeded(scriptName) end

---@param ped Ped
---@param p1 number
function SetScriptedAnimSeatOffset(ped, p1) end

---@param x number
---@param y number
---@param z number
function SetScriptedConversionCoordThisFrame(x, y, z) end

---@param horizontalAlign integer
---@param verticalAlign integer
function SetScriptGfxAlign(horizontalAlign, verticalAlign) end

---@param x number
---@param y number
---@param w number
---@param h number
function SetScriptGfxAlignParams(x, y, w, h) end

---@param flag boolean
function SetScriptGfxDrawBehindPausemenu(flag) end

---@param order integer
function SetScriptGfxDrawOrder(order) end

---@param doorHash Hash|string
---@param toggle boolean
function SetScriptUpdateDoorAudio(doorHash, toggle) end

---@param r integer
---@param g integer
---@param b integer
---@param a integer
function SetScriptVariable_2HudColour(r, g, b, a) end

---@param r integer
---@param g integer
---@param b integer
---@param a integer
function SetScriptVariableHudColour(r, g, b, a) end

---@param vehicleGenerator integer
---@param enabled boolean
function SetScriptVehicleGenerator(vehicleGenerator, enabled) end

---@param scriptHash Hash|string
function SetScriptWithNameHashAsNoLongerNeeded(scriptHash) end

---@param toggle boolean
function SetSeethrough(toggle) end

---@param taskSequenceId integer
---@param repeat_ boolean
function SetSequenceToRepeat(taskSequenceId, repeat_) end

---@param cash integer
---@param bank integer
function SetSingleplayerHudCash(cash, bank) end

---@param vehicle integer
---@param toggle boolean
function SetSirenKeepOn(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetSirenWithNoDriver(vehicle, toggle) end

---@param name string
---@param path string
---@param data string
function SetSnakeoilForEntry(name, path, data) end

---@param level number
function SetSnowLevel(level) end

---@param name string
function SetSocialClubTour(name) end

---@param toggle boolean
function SetSomethingMultiplierThisFrame(toggle) end

---@param range number
function SetSomeVehicleDensityMultiplierThisFrame(range) end

---@param player integer
---@param p1 integer
function SetSpecialAbility(player, p1) end

---@param multiplier number
function SetSpecialAbilityMultiplier(multiplier) end

---@param vehicle integer
---@param toggle boolean
function SetSpecialFlightModeAllowed(vehicle, toggle) end

---@param vehicle integer
---@param ratio number
function SetSpecialFlightModeRatio(vehicle, ratio) end

---@param vehicle integer
---@param state number
function SetSpecialFlightModeTargetRatio(vehicle, state) end

---@param vehicle integer
---@param ratio number
function SetSpecialflightWingRatio(vehicle, ratio) end

---@param p0 number
function SetSrlTime(p0) end

---@param type Hash|string
---@param x number
---@param y number
---@param z number
---@param locked boolean
---@param heading number
---@param p6 boolean
function SetStateOfClosestDoorOfType(type, x, y, z, locked, heading, p6) end

---@param object integer
---@param state integer
function SetStateOfRayfireMapObject(object, state) end

---@param emitterName string
---@param toggle boolean
function SetStaticEmitterEnabled(emitterName, toggle) end

---@param toggle boolean
function SetStoreEnabled(toggle) end

---@param scriptHash Hash|string
function SetStreamedScriptAsNoLongerNeeded(scriptHash) end

---@param textureDict string
function SetStreamedTextureDictAsNoLongerNeeded(textureDict) end

---@param toggle boolean
function SetStreaming(toggle) end

---@param toggle boolean
function SetStuntJumpsCanTrigger(toggle) end

---@param vehicle integer
---@param toggle boolean
---@param depth1 number
---@param depth2 number
---@param depth3 number
function SetSubmarineCrushDepths(vehicle, toggle, depth1, depth2, depth3) end

---@param player integer
function SetSuperJumpThisFrame(player) end

---@param player integer
---@param multiplier number
function SetSwimMultiplierForPlayer(player, multiplier) end

---@param audioName string
---@param entity Entity
function SetSynchronizedAudioEventPositionThisFrame(audioName, entity) end

---@param sceneID integer
---@param toggle boolean
function SetSynchronizedSceneHoldLastFrame(sceneID, toggle) end

---@param sceneID integer
---@param toggle boolean
function SetSynchronizedSceneLooped(sceneID, toggle) end

---@param sceneID integer
---@param toggle boolean
function SetSynchronizedSceneOcclusionPortal(sceneID, toggle) end

---@param sceneID integer
---@param x number
---@param y number
---@param z number
---@param roll number
---@param pitch number
---@param yaw number
---@param p7 boolean
function SetSynchronizedSceneOrigin(sceneID, x, y, z, roll, pitch, yaw, p7) end

---@param sceneID integer
---@param phase number
function SetSynchronizedScenePhase(sceneID, phase) end

---@param sceneID integer
---@param rate number
function SetSynchronizedSceneRate(sceneID, rate) end

---@param hash Hash|string
---@return boolean
function SetTableGamesCameraThisUpdate(hash) end

---@param ped Ped
---@param signalName string
---@param value boolean
function SetTaskMoveNetworkSignalBool(ped, signalName, value) end

---@param ped Ped
---@param signalName string
---@param value number
function SetTaskMoveNetworkSignalFloat(ped, signalName, value) end

---@param ped Ped
---@param signalName string
---@param value number
function SetTaskMoveNetworkSignalFloat_2(ped, signalName, value) end

---@param ped Ped
---@param signalName string
---@param value boolean
function SetTaskPropertyBool(ped, signalName, value) end

---@param ped Ped
---@param signalName string
---@param value number
function SetTaskPropertyFloat(ped, signalName, value) end

---@param ped Ped
---@param flag integer
---@param set boolean
function SetTaskVehicleChaseBehaviorFlag(ped, flag, set) end

---@param ped Ped
---@param distance number
function SetTaskVehicleChaseIdealPursuitDistance(ped, distance) end

---@param plane integer
---@param height integer
function SetTaskVehicleGotoPlaneMinHeightAboveTerrain(plane, height) end

---@param vehicle integer
---@param state boolean
function SetTaxiLights(vehicle, state) end

---@param object integer
---@param p1 unknown
---@param p2 boolean
function SetTeamPickupObject(object, p1, p2) end

---@param align boolean
function SetTextCentre(align) end

---@param enabled boolean
---@return boolean
function SetTextChatEnabled(enabled) end

---@param disable boolean
function SetTextChatUnk(disable) end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function SetTextColour(red, green, blue, alpha) end

---@param inputType string
function SetTextComponentFormat(inputType) end

---@param distance integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function SetTextDropshadow(distance, r, g, b, a) end

function SetTextDropShadow() end

---@param p0 integer
---@param r integer
---@param g integer
---@param b integer
---@param a integer
function SetTextEdge(p0, r, g, b, a) end

---@param text string
function SetTextEntry(text) end

---@param GxtEntry string
function SetTextEntry_2(GxtEntry) end

---@param text string
function SetTextEntryForWidth(text) end

---@param fontType integer
function SetTextFont(fontType) end

---@param entry string
function SetTextGxtEntry(entry) end

---@param state boolean
function SetTextInputBoxEnabled(state) end

---@param justifyType integer
function SetTextJustification(justifyType) end

---@param p0 integer
function SetTextLeading(p0) end

function SetTextOutline() end

---@param p0 boolean
function SetTextProportional(p0) end

---@param renderId integer
function SetTextRenderId(renderId) end

---@param toggle boolean
function SetTextRightJustify(toggle) end

---@param scale number
---@param size number
function SetTextScale(scale, size) end

---@param x number
---@param y number
---@param z number
---@param radius number
---@param modelHash Hash|string
---@param textureVariation integer
---@return boolean
function SetTextureVariationOfClosestObjectOfType(x, y, z, radius, modelHash, textureVariation) end

---@param start number
---@param end_ number
function SetTextWrap(start, end_) end

---@param distance number
function SetThirdPersonAimCamNearClip(distance) end

---@param distance number
function SetThirdPersonAimCamNearClipThisUpdate(distance) end

---@param toggle boolean
function SetThisScriptCanBePaused(toggle) end

---@param toggle boolean
function SetThisScriptCanRemoveBlipsCreatedByAnyScript(toggle) end

---@param priority integer
function SetThreadPriority(priority) end

---@param modifierName string
function SetTimecycleModifier(modifierName) end

---@param strength number
function SetTimecycleModifierStrength(strength) end

---@param modifierName string
---@param varName string
---@param value1 number
---@param value2 number
function SetTimecycleModifierVar(modifierName, varName, value1, value2) end

---@param ped Ped
---@param toggle boolean
function SetTimeExclusiveDisplayTexture(ped, toggle) end

---@param p0 boolean
---@param p1 boolean
function SetTimeIdleDrop(p0, p1) end

---@param value integer
function Settimera(value) end

---@param value integer
function Settimerb(value) end

---@param timeScale number
function SetTimeScale(timeScale) end

---@param toggle boolean
function SetToggleMinimapHeistIsland(toggle) end

---@param vehicle integer
---@param position number
function SetTowTruckCraneHeight(vehicle, position) end

---@param vehicle integer
---@param position number
function SetTowTruckCraneRaised(vehicle, position) end

---@param track integer
---@param brakingDistance number
function SetTrackBrakingDistance(track, brakingDistance) end

---@param point integer
---@param x number
---@param y number
---@param z number
---@param radius number
function SetTrackedPointInfo(point, x, y, z, radius) end

---@param track integer
---@param enabled boolean
function SetTrackEnabled(track, enabled) end

---@param junctionIndex integer
---@param state boolean
---@return boolean
function SetTrackJunctionActive(junctionIndex, state) end

---@param track integer
---@param newSpeed integer
function SetTrackMaxSpeed(track, newSpeed) end

---@param vehicle integer
---@param p1 number
function SetTrailerInverseMassScale(vehicle, p1) end

function SetTrailerLegsLowered() end

---@param vehicle integer
function SetTrailerLegsRaised(vehicle) end

---@param train integer
---@param speed number
function SetTrainCruiseSpeed(train, speed) end

---@param train integer
---@param doorIndex integer
---@param ratio number
function SetTrainDoorOpenRatio(train, doorIndex, ratio) end

---@param forceOpen boolean
function SetTrainsForceDoorsOpen(forceOpen) end

---@param train integer
---@param speed number
function SetTrainSpeed(train, speed) end

---@param train integer
---@param state integer
function SetTrainState(train, state) end

---@param train integer
---@param state boolean
function SetTrainStopAtStations(train, state) end

---@param trackIndex integer
---@param frequency integer
function SetTrainTrackSpawnFrequency(trackIndex, frequency) end

---@param vehicle integer
---@param transformRate number
function SetTransformRateForAnimation(vehicle, transformRate) end

---@param vehicle integer
---@param useAlternateInput boolean
function SetTransformToSubmarineUsesAlternateInput(vehicle, useAlternateInput) end

---@param modifierName string
---@param transition number
function SetTransitionTimecycleModifier(modifierName, transition) end

---@param toggle boolean
function SetTvAudioFrontend(toggle) end

---@param channel integer
function SetTvChannel(channel) end

---@param tvChannel integer
---@param playlistName string
---@param restart boolean
function SetTvChannelPlaylist(tvChannel, playlistName, restart) end

---@param tvChannel integer
---@param playlistName string
---@param hour integer
function SetTvChannelPlaylistAtHour(tvChannel, playlistName, hour) end

---@param volume number
function SetTvVolume(volume) end

---@param vehicle integer
---@param wheelIndex integer
---@param health number
function SetTyreHealth(vehicle, wheelIndex, health) end

---@param vehicle integer
---@param wheelIndex integer
---@param multiplier number
function SetTyreSoftnessMultiplier(vehicle, wheelIndex, multiplier) end

---@param vehicle integer
---@param wheelIndex integer
---@param multiplier number
function SetTyreTractionLossMultiplier(vehicle, wheelIndex, multiplier) end

---@param vehicle integer
---@param wheelIndex integer
---@param multiplier number
function SetTyreWearMultiplier(vehicle, wheelIndex, multiplier) end

---@param order integer
function SetUiLayer(order) end

---@param vehicle integer
---@param useAlternateInput boolean
function SetUnkBoolN_0x102ForSubmarineVehicleTask(vehicle, useAlternateInput) end

---@param vehicle integer
---@param transformRate number
function SetUnkFloatN_0x104ForSubmarineVehicleTask(vehicle, transformRate) end

---@param value boolean
function SetUnkGlobalBoolRelatedToDamage(value) end

---@param flag integer
function SetUnkMapFlag(flag) end

---@param p0 integer
---@param p1 integer
---@param p2 integer
---@param p3 integer
---@return integer
function SetupShopPedApparelQuery(p0, p1, p2, p3) end

---@param character integer
---@param p1 integer
---@param p2 integer
---@param p3 boolean
---@param p4 integer
---@param componentId integer
---@return integer
function SetupShopPedApparelQueryTu(character, p1, p2, p3, p4, componentId) end

---@param character integer
---@param p1 boolean
---@return integer
function SetupShopPedOutfitQuery(character, p1) end

function SetUseHiDof() end

function SetUseHiDofInCutscene() end

---@param vehicle integer
---@param toggle boolean
function SetUseHigherVehicleJumpForce(vehicle, toggle) end

---@param toggle boolean
function SetUseIslandMap(toggle) end

---@param p0 unknown
---@return boolean
---@return unknown p1
function SetUseridsUihidden(p0) end

---@param toggle boolean
function SetUserRadioControlEnabled(toggle) end

---@param toggle boolean
function SetUseWaypointAsDestination(toggle) end

---@param variableName string
---@param value number
function SetVariableOnCutsceneAudio(variableName, value) end

---@param soundId integer
---@param variableName string
---@param value number
function SetVariableOnSound(soundId, variableName, value) end

---@param p0 string
---@param p1 number
function SetVariableOnStream(p0, p1) end

---@param variableName string
---@param value number
function SetVariableOnUnderWaterStream(variableName, value) end

---@param vehicle integer
function SetVehHasRadioOverride(vehicle) end

---@param vehicle integer
---@param actHighSpeed boolean
function SetVehicleActAsIfHighSpeedForFragSmashing(vehicle, actHighSpeed) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleActiveDuringPlayback(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleActiveForPedNavigation(vehicle, toggle) end

---@param vehicle integer
---@param state boolean
function SetVehicleAlarm(vehicle, state) end

---@param vehicle integer
---@param time integer
function SetVehicleAlarmTimeLeft(vehicle, time) end

---@param veh integer
---@param toggle boolean
function SetVehicleAllowNoPassengersLockon(veh, toggle) end

---@return integer vehicle
function SetVehicleAsNoLongerNeeded() end

---@param vehicle integer
---@param gameObjectName string
function SetVehicleAudio(vehicle, gameObjectName) end

---@param vehicle integer
---@param intensity number
function SetVehicleAudioBodyDamageFactor(vehicle, intensity) end

---@param vehicle integer
---@param damageFactor number
function SetVehicleAudioEngineDamageFactor(vehicle, damageFactor) end

---@param vehicle integer
---@param p1 boolean
---@param p2 unknown
---@return unknown
function SetVehicleAutomaticallyAttaches(vehicle, p1, p2) end

---@param vehicle integer
---@param value boolean
function SetVehicleAutoRepairDisabled(vehicle, value) end

---@param vehicle integer
---@param value number
function SetVehicleBodyHealth(vehicle, value) end

---@param aircraft integer
---@param bombCount integer
function SetVehicleBombCount(aircraft, bombCount) end

---@param aircraft integer
---@param bombCount integer
function SetVehicleBombs(aircraft, bombCount) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleBoostActive(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleBrake(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleBrakeLights(vehicle, toggle) end

---@param vehicle integer
---@param position number
---@param p2 boolean
function SetVehicleBulldozerArmPosition(vehicle, position, p2) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleBurnout(vehicle, toggle) end

---@param vehicle integer
---@param canBeLockedOn boolean
---@param unk boolean
function SetVehicleCanBeLockedOn(vehicle, canBeLockedOn, unk) end

---@param vehicle integer
---@param state boolean
function SetVehicleCanBeTargetted(vehicle, state) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCanBeUsedByFleeingPeds(vehicle, toggle) end

---@param vehicle integer
---@param state boolean
function SetVehicleCanBeVisiblyDamaged(vehicle, state) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCanBreak(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCanDeformWheels(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCanEngineOperateOnFire(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCanLeakOil(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCanLeakPetrol(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCanSaveInGarage(vehicle, toggle) end

---@param vehicle integer
---@param height number
function SetVehicleCeilingHeight(vehicle, height) end

---@param vehicle integer
---@param value number
function SetVehicleCheatPowerIncrease(vehicle, value) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCloseDoorDeferedAction(vehicle, toggle) end

---@param vehicle integer
---@param clutch number
function SetVehicleClutch(vehicle, clutch) end

---@param vehicle integer
---@param colorCombination integer
function SetVehicleColourCombination(vehicle, colorCombination) end

---@param vehicle integer
---@param colorPrimary integer
---@param colorSecondary integer
function SetVehicleColours(vehicle, colorPrimary, colorSecondary) end

---@param vehicle integer
---@param state boolean
function SetVehicleControlsInverted(vehicle, state) end

---@param aircraft integer
---@param count integer
function SetVehicleCountermeasureCount(aircraft, count) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleCreatesMoneyPickupsWhenExploded(vehicle, toggle) end

---@param vehicle integer
---@param gear integer
function SetVehicleCurrentGear(vehicle, gear) end

---@param vehicle integer
---@param rpm number
function SetVehicleCurrentRpm(vehicle, rpm) end

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
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param damage number
---@param radius number
---@param focusOnModel boolean
function SetVehicleDamage(vehicle, xOffset, yOffset, zOffset, damage, radius, focusOnModel) end

---@param vehicle integer
---@param p1 number
---@return unknown
function SetVehicleDamageModifier(vehicle, p1) end

---@param vehicle integer
---@param color integer
function SetVehicleDashboardColor(vehicle, color) end

---@param vehicle integer
---@param color integer
function SetVehicleDashboardColour(vehicle, color) end

---@param vehicle integer
function SetVehicleDeformationFixed(vehicle) end

---@param multiplier number
function SetVehicleDensityMultiplierThisFrame(multiplier) end

---@param vehicle integer
---@param dirtLevel number
function SetVehicleDirtLevel(vehicle, dirtLevel) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleDisableTowing(vehicle, toggle) end

---@param vehicle integer
---@param doorIndex integer
---@param isBreakable boolean
function SetVehicleDoorBreakable(vehicle, doorIndex, isBreakable) end

---@param vehicle integer
---@param doorIndex integer
---@param deleteDoor boolean
function SetVehicleDoorBroken(vehicle, doorIndex, deleteDoor) end

---@param vehicle integer
---@param doorIndex integer
---@param isBreakable boolean
function SetVehicleDoorCanBreak(vehicle, doorIndex, isBreakable) end

---@param vehicle integer
---@param doorIndex integer
---@param speed integer
---@param angle number
function SetVehicleDoorControl(vehicle, doorIndex, speed, angle) end

---@param vehicle integer
---@param doorIndex integer
---@param doorLockStatus integer
function SetVehicleDoorDestroyType(vehicle, doorIndex, doorLockStatus) end

---@param vehicle integer
---@param doorIndex integer
---@param forceClose boolean
---@param lock boolean
---@param p4 boolean
function SetVehicleDoorLatched(vehicle, doorIndex, forceClose, lock, p4) end

---@param vehicle integer
---@param doorIndex integer
---@param loose boolean
---@param openInstantly boolean
function SetVehicleDoorOpen(vehicle, doorIndex, loose, openInstantly) end

---@param vehicle integer
---@param doorIndex integer
---@param closeInstantly boolean
function SetVehicleDoorShut(vehicle, doorIndex, closeInstantly) end

---@param vehicle integer
---@param doorLockStatus integer
function SetVehicleDoorsLocked(vehicle, doorLockStatus) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleDoorsLockedForAllPlayers(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleDoorsLockedForNonScriptPlayers(vehicle, toggle) end

---@param vehicle integer
---@param player integer
---@param toggle boolean
function SetVehicleDoorsLockedForPlayer(vehicle, player, toggle) end

---@param vehicle integer
---@param team integer
---@param toggle boolean
function SetVehicleDoorsLockedForTeam(vehicle, team, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleDoorsLockedForUnk(vehicle, toggle) end

---@param vehicle integer
---@param closeInstantly boolean
function SetVehicleDoorsShut(vehicle, closeInstantly) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleDropsMoneyWhenBlownUp(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleEngineCanDegrade(vehicle, toggle) end

---@param vehicle integer
---@param health number
function SetVehicleEngineHealth(vehicle, health) end

---@param vehicle integer
---@param value boolean
---@param instantly boolean
---@param disableAutoStart boolean
function SetVehicleEngineOn(vehicle, value, instantly, disableAutoStart) end

---@param vehicle integer
---@param value number
function SetVehicleEnginePowerMultiplier(vehicle, value) end

---@param vehicle integer
---@param temperature number
function SetVehicleEngineTemperature(vehicle, temperature) end

---@param vehicle integer
---@param value number
function SetVehicleEngineTorqueMultiplier(vehicle, value) end

---@param vehicle integer
---@param fade number
function SetVehicleEnveffScale(vehicle, fade) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleExclusiveDriver(vehicle, toggle) end

---@param vehicle integer
---@param ped Ped
---@param index integer
function SetVehicleExclusiveDriver_2(vehicle, ped, index) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleExplodesOnHighExplosionDamage(vehicle, toggle) end

---@param vehicle integer
---@param range integer
function SetVehicleExtendedRemovalRange(vehicle, range) end

---@param vehicle integer
---@param extraId integer
---@param disable boolean
function SetVehicleExtra(vehicle, extraId, disable) end

---@param vehicle integer
---@param pearlescentColor integer
---@param wheelColor integer
function SetVehicleExtraColours(vehicle, pearlescentColor, wheelColor) end

---@param vehicle integer
function SetVehicleFixed(vehicle) end

---@param vehicle integer
---@param flagIndex integer
---@param value boolean
---@return boolean
function SetVehicleFlag(vehicle, flagIndex, value) end

---@param vehicle integer
---@param angleRatio number
function SetVehicleFlightNozzlePosition(vehicle, angleRatio) end

---@param vehicle integer
---@param angle number
function SetVehicleFlightNozzlePositionImmediate(vehicle, angle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleForceAfterburner(vehicle, toggle) end

---@param vehicle integer
---@param speed number
function SetVehicleForwardSpeed(vehicle, speed) end

---@param vehicle integer
---@param friction number
function SetVehicleFrictionOverride(vehicle, friction) end

---@param vehicle integer
---@param level number
function SetVehicleFuelLevel(vehicle, level) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleFullbeam(vehicle, toggle) end

---@param vehicle integer
---@param gear integer
---@param ratio number
function SetVehicleGearRatio(vehicle, gear, ratio) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleGeneratesEngineShockingEvents(vehicle, toggle) end

---@param x number
---@param y number
---@param z number
---@param radius number
function SetVehicleGeneratorAreaOfInterest(x, y, z, radius) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleGravity(vehicle, toggle) end

---@param vehicle integer
---@param gravity number
function SetVehicleGravityAmount(vehicle, gravity) end

---@param vehicle integer
---@param distance number
---@param duration integer
---@param bControlVerticalVelocity boolean
function SetVehicleHalt(vehicle, distance, duration, bControlVerticalVelocity) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHandbrake(vehicle, toggle) end

---@param vehicle integer
---@param class_ string
---@param fieldName string
---@param value unknown
function SetVehicleHandlingField(vehicle, class_, fieldName, value) end

---@param vehicle integer
---@param class_ string
---@param fieldName string
---@param value number
function SetVehicleHandlingFloat(vehicle, class_, fieldName, value) end

---@param vehicle integer
---@param hash Hash|string
function SetVehicleHandlingHashForAi(vehicle, hash) end

---@param vehicle integer
---@param class_ string
---@param fieldName string
---@param value integer
function SetVehicleHandlingInt(vehicle, class_, fieldName, value) end

---@param vehicle integer
---@param class_ string
---@param fieldName string
---@param value vector3
function SetVehicleHandlingVector(vehicle, class_, fieldName, value) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHasBeenDrivenFlag(vehicle, toggle) end

---@param vehicle integer
---@param owned boolean
function SetVehicleHasBeenOwnedByPlayer(vehicle, owned) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHasMutedSirens(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHasStrongAxles(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHasUnbreakableLights(vehicle, toggle) end

---@param vehicle integer
---@param color integer
function SetVehicleHeadlightsColour(vehicle, color) end

---@param vehicle integer
---@param flag integer
function SetVehicleHeadlightShadows(vehicle, flag) end

---@param vehicle integer
---@param gear integer
function SetVehicleHighGear(vehicle, gear) end

---@param vehicle integer
---@param value integer
function SetVehicleHornVariation(vehicle, value) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHoverTransformActive(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHoverTransformEnabled(vehicle, toggle) end

---@param vehicle integer
---@param state number
function SetVehicleHoverTransformPercentage(vehicle, state) end

---@param vehicle integer
---@param ratio number
function SetVehicleHoverTransformRatio(vehicle, ratio) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleHudSpecialAbilityBarActive(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleInactiveDuringPlayback(vehicle, toggle) end

---@param vehicle integer
---@param turnSignal integer
---@param toggle boolean
function SetVehicleIndicatorLights(vehicle, turnSignal, toggle) end

---@param vehicle integer
---@param doorIndex integer
---@param doorLockStatus integer
function SetVehicleIndividualDoorsLocked(vehicle, doorIndex, doorLockStatus) end

---@param vehicle integer
---@param influenceWantedLevel boolean
function SetVehicleInfluencesWantedLevel(vehicle, influenceWantedLevel) end

---@param vehicle integer
---@param color integer
function SetVehicleInteriorColor(vehicle, color) end

---@param vehicle integer
---@param color integer
function SetVehicleInteriorColour(vehicle, color) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleInteriorlight(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleIsConsideredByPlayer(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleIsRacing(vehicle, toggle) end

---@param vehicle integer
---@param isStolen boolean
function SetVehicleIsStolen(vehicle, isStolen) end

---@param vehicle integer
---@param state boolean
function SetVehicleIsWanted(vehicle, state) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleJetEngineOn(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleKeepEngineOnWhenAbandoned(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleKersAllowed(vehicle, toggle) end

---@param vehicle integer
---@param state integer
function SetVehicleLandingGear(vehicle, state) end

---@param vehicle integer
---@param multiplier number
function SetVehicleLightMultiplier(vehicle, multiplier) end

---@param vehicle integer
---@param state integer
function SetVehicleLights(vehicle, state) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleLightsCanBeVisiblyDamaged(vehicle, toggle) end

---@param vehicle integer
---@param flag integer
function SetVehicleLightsMode(vehicle, flag) end

---@param vehicle integer
---@param livery integer
function SetVehicleLivery(vehicle, livery) end

---@param vehicle integer
---@param multiplier number
function SetVehicleLodMultiplier(vehicle, multiplier) end

---@param vehicle integer
---@param speed number
function SetVehicleMaxSpeed(vehicle, speed) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleMaxStrTrap(vehicle, toggle) end

---@param vehicle integer
---@param modType integer
---@param modIndex integer
---@param customTires boolean
function SetVehicleMod(vehicle, modType, modIndex, customTires) end

---@param vehicle integer
---@param paintType integer
---@param color integer
---@param pearlescentColor integer
function SetVehicleModColor_1(vehicle, paintType, color, pearlescentColor) end

---@param vehicle integer
---@param paintType integer
---@param color integer
function SetVehicleModColor_2(vehicle, paintType, color) end

---@param model Hash|string
---@param suppressed boolean
function SetVehicleModelIsSuppressed(model, suppressed) end

---@param vehicle integer
---@param modKit integer
function SetVehicleModKit(vehicle, modKit) end

---@param vehicle integer
---@param name string
function SetVehicleNameDebug(vehicle, name) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleNeedsToBeHotwired(vehicle, toggle) end

---@param vehicle integer
---@param index integer
---@param toggle boolean
function SetVehicleNeonLightEnabled(vehicle, index, toggle) end

---@param vehicle integer
---@param color integer
function SetVehicleNeonLightsColor_2(vehicle, color) end

---@param vehicle integer
---@param r integer
---@param g integer
---@param b integer
function SetVehicleNeonLightsColour(vehicle, r, g, b) end

---@param vehicle integer
---@param nextGear integer
function SetVehicleNextGear(vehicle, nextGear) end

---@param vehicle integer
---@param override boolean
function SetVehicleNitroEnabled(vehicle, override) end

---@param range number
function SetVehicleNitroPtfxRange(range) end

---@param vehicle integer
---@param plateText string
function SetVehicleNumberPlateText(vehicle, plateText) end

---@param vehicle integer
---@param plateIndex integer
function SetVehicleNumberPlateTextIndex(vehicle, plateIndex) end

---@param vehicle integer
---@param level number
function SetVehicleOilLevel(vehicle, level) end

---@param vehicle integer
---@return boolean
function SetVehicleOnGroundProperly(vehicle) end

---@param vehicle integer
---@param killDriver boolean
---@param explodeOnImpact boolean
function SetVehicleOutOfControl(vehicle, killDriver, explodeOnImpact) end

---@param vehicle integer
---@param fade number
function SetVehiclePaintFade(vehicle, fade) end

---@param vehicle integer
---@param active boolean
function SetVehicleParachuteActive(vehicle, active) end

---@param vehicle integer
---@param modelHash Hash|string
function SetVehicleParachuteModel(vehicle, modelHash) end

---@param vehicle integer
---@param textureVariation integer
function SetVehicleParachuteTextureVariatiion(vehicle, textureVariation) end

---@param vehicle integer
---@param textureVariation integer
function SetVehicleParachuteTextureVariation(vehicle, textureVariation) end

---@param vehicle integer
---@param health number
function SetVehiclePetrolTankHealth(vehicle, health) end

---@param vehicle integer
---@param value number
function SetVehiclePitchBias(vehicle, value) end

---@param p0 integer
function SetVehiclePopulationBudget(p0) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleProvidesCover(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleRadioEnabled(vehicle, toggle) end

---@param vehicle integer
---@param loud boolean
function SetVehicleRadioLoud(vehicle, loud) end

---@param vehicle integer
---@param p1 number
function SetVehicleRampLaunchModifier(vehicle, p1) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleRampSidewaysLaunchMotion(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleRampUpwardsLaunchMotion(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleReceivesRampDamage(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleReduceGrip(vehicle, toggle) end

---@param vehicle integer
---@param val integer
function SetVehicleReduceTraction(vehicle, val) end

---@param vehicle integer
---@param active boolean
function SetVehicleRocketBoostActive(vehicle, active) end

---@param vehicle integer
---@param percentage number
function SetVehicleRocketBoostPercentage(vehicle, percentage) end

---@param vehicle integer
---@param time number
function SetVehicleRocketBoostRefillTime(vehicle, time) end

---@param vehicle integer
---@param value number
function SetVehicleRollBias(vehicle, value) end

---@param vehicle integer
---@param livery integer
function SetVehicleRoofLivery(vehicle, livery) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleRudderBroken(vehicle, toggle) end

---@param heli integer
---@param toggle boolean
---@param canBeUsedByAI boolean
function SetVehicleSearchlight(heli, toggle, canBeUsedByAI) end

---@param vehicle integer
---@param p1 integer
---@param p2 integer
function SetVehicleShadowEffect(vehicle, p1, p2) end

---@param driver Ped
---@param entity Entity
---@param xTarget number
---@param yTarget number
---@param zTarget number
function SetVehicleShootAtTarget(driver, entity, xTarget, yTarget, zTarget) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleSilent(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleSiren(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleSt(vehicle, toggle) end

---@param vehicle integer
---@param soundName string
---@param setName string
function SetVehicleStartupRevSound(vehicle, soundName, setName) end

---@param vehicle integer
---@param value number
function SetVehicleSteerBias(vehicle, value) end

---@param vehicle integer
---@param angle number
function SetVehicleSteeringAngle(vehicle, angle) end

---@param vehicle integer
---@param scalar number
function SetVehicleSteeringBiasScalar(vehicle, scalar) end

---@param vehicle integer
---@param scale number
function SetVehicleSteeringScale(vehicle, scale) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleStrong(vehicle, toggle) end

---@param vehicle integer
---@param newHeight number
function SetVehicleSuspensionHeight(vehicle, newHeight) end

---@param vehicle integer
---@param position number
---@param p2 boolean
function SetVehicleTankTurretPosition(vehicle, position, p2) end

---@param vehicle integer
---@param ped Ped
---@param toggle boolean
function SetVehicleTimedExplosion(vehicle, ped, toggle) end

---@param vehicle integer
---@param position number
function SetVehicleTowTruckArmPosition(vehicle, position) end

---@param vehicle integer
---@param state number
function SetVehicleTransformState(vehicle, state) end

---@param vehicle integer
---@param pressure number
function SetVehicleTurboPressure(vehicle, pressure) end

---@param vehicle integer
---@param speed number
function SetVehicleTurretSpeedThisFrame(vehicle, speed) end

---@param vehicle integer
---@param index integer
---@param toggle boolean
function SetVehicleTurretUnk(vehicle, index, toggle) end

---@param vehicle integer
---@param index integer
---@param onRim boolean
---@param p3 number
function SetVehicleTyreBurst(vehicle, index, onRim, p3) end

---@param vehicle integer
---@param tyreIndex integer
function SetVehicleTyreFixed(vehicle, tyreIndex) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleTyresCanBurst(vehicle, toggle) end

---@param vehicle integer
---@param r integer
---@param g integer
---@param b integer
function SetVehicleTyreSmokeColor(vehicle, r, g, b) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleUndriveable(vehicle, toggle) end

---@param vehicle integer
---@param multiplier number
function SetVehicleUnkDamageMultiplier(vehicle, multiplier) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleUseAlternateHandling(vehicle, toggle) end

---@param p0 integer
---@param p1 boolean
---@param p2 boolean
---@param p3 boolean
---@return unknown
function SetVehicleUseCutsceneWheelCompression(p0, p1, p2, p3) end

---@param vehicle integer
---@param bToggle boolean
function SetVehicleUseHornButtonForNitrous(vehicle, bToggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleUsePlayerLightSettings(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleUsesLargeRearRamp(vehicle, toggle) end

---@param vehicle integer
---@param weaponIndex integer
---@param capacity integer
function SetVehicleWeaponCapacity(vehicle, weaponIndex, capacity) end

---@param vehicle integer
---@param weaponSlot integer
function SetVehicleWeaponsDisabled(vehicle, weaponSlot) end

---@param vehicle integer
---@param wheelIndex integer
---@param pressure number
function SetVehicleWheelBrakePressure(vehicle, wheelIndex, pressure) end

---@param vehicle integer
---@param wheelIndex integer
---@param flags integer
function SetVehicleWheelFlags(vehicle, wheelIndex, flags) end

---@param vehicle integer
---@param wheelIndex integer
---@param health number
function SetVehicleWheelHealth(vehicle, wheelIndex, health) end

---@param vehicle integer
---@param state integer
function SetVehicleWheelieState(vehicle, state) end

---@param vehicle integer
---@param wheelIndex integer
---@param powered boolean
function SetVehicleWheelIsPowered(vehicle, wheelIndex, powered) end

---@param vehicle integer
---@param wheelIndex integer
---@param power number
function SetVehicleWheelPower(vehicle, wheelIndex, power) end

---@param vehicle integer
---@param wheelIndex integer
---@param value number
function SetVehicleWheelRimColliderSize(vehicle, wheelIndex, value) end

---@param vehicle integer
---@param wheelIndex integer
---@param speed number
function SetVehicleWheelRotationSpeed(vehicle, wheelIndex, speed) end

---@param vehicle integer
---@param enabled boolean
function SetVehicleWheelsCanBreak(vehicle, enabled) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleWheelsCanBreakOffWhenBlowUp(vehicle, toggle) end

---@param vehicle integer
---@param toggle boolean
function SetVehicleWheelsDealDamage(vehicle, toggle) end

---@param vehicle integer
---@param size number
---@return boolean
function SetVehicleWheelSize(vehicle, size) end

---@param vehicle integer
---@param wheelIndex integer
---@param value number
function SetVehicleWheelTireColliderSize(vehicle, wheelIndex, value) end

---@param vehicle integer
---@param wheelIndex integer
---@param value number
function SetVehicleWheelTireColliderWidth(vehicle, wheelIndex, value) end

---@param vehicle integer
---@param wheelIndex integer
---@param length number
function SetVehicleWheelTractionVectorLength(vehicle, wheelIndex, length) end

---@param vehicle integer
---@param wheelType integer
function SetVehicleWheelType(vehicle, wheelType) end

---@param vehicle integer
---@param width number
---@return boolean
function SetVehicleWheelWidth(vehicle, width) end

---@param vehicle integer
---@param wheelIndex integer
---@param offset number
function SetVehicleWheelXOffset(vehicle, wheelIndex, offset) end

---@param vehicle integer
---@param wheelIndex integer
---@param value number
function SetVehicleWheelXrot(vehicle, wheelIndex, value) end

---@param vehicle integer
---@param wheelIndex integer
---@param value number
function SetVehicleWheelYRotation(vehicle, wheelIndex, value) end

---@param vehicle integer
---@param tint integer
function SetVehicleWindowTint(vehicle, tint) end

---@param vehicle integer
---@param color integer
function SetVehicleXenonLightsColor(vehicle, color) end

---@param vehicle integer
---@param color integer
function SetVehicleXenonLightsColour(vehicle, color) end

---@param vehicle integer
---@param red integer
---@param green integer
---@param blue integer
function SetVehicleXenonLightsCustomColor(vehicle, red, green, blue) end

---@param gripFactor number
function SetVehicleXmasSnowFactor(gripFactor) end

---@param vehicle integer
---@param radioStation string
function SetVehRadioStation(vehicle, radioStation) end

---@param vehicle integer
---@param angle number
function SetVerticalFlightPhase(vehicle, angle) end

---@param name string
---@param value number
function SetVisualSettingFloat(name, value) end

---@param entity Entity
---@param toggle boolean
function SetWaitForCollisionsBeforeProbe(entity, toggle) end

---@param player integer
---@param difficulty number
function SetWantedLevelDifficulty(player, difficulty) end

---@param player integer
---@param wantedLevel integer
---@param lossTime integer
function SetWantedLevelHiddenEvasionTime(player, wantedLevel, lossTime) end

---@param multiplier number
function SetWantedLevelMultiplier(multiplier) end

---@param entryLine1 string
---@param instructionalKey integer
---@param entryLine2 string
---@param p3 boolean
---@param p4 integer
---@param background string
---@param p6 string
---@param showBg boolean
---@param errorCode integer
function SetWarningMessage(entryLine1, instructionalKey, entryLine2, p3, p4, background, p6, showBg, errorCode) end

---@param titleMsg string
---@param entryLine1 string
---@param flags integer
---@param promptMsg string
---@param p4 boolean
---@param p5 unknown
---@param background boolean
---@param showBg boolean
---@return unknown p7
function SetWarningMessage_2(titleMsg, entryLine1, flags, promptMsg, p4, p5, background, showBg) end

---@param entryHeader string
---@param entryLine1 string
---@param instructionalKey unknown
---@param entryLine2 string
---@param p4 boolean
---@param p5 unknown
---@param p6 unknown
---@param p9 boolean
---@return unknown p7
---@return unknown p8
function SetWarningMessage_3(entryHeader, entryLine1, instructionalKey, entryLine2, p4, p5, p6, p9) end

---@param index integer
---@param name string
---@param cash integer
---@param rp integer
---@param lvl integer
---@param colour integer
---@return boolean
function SetWarningMessageListRow(index, name, cash, rp, lvl, colour) end

---@param labelTitle string
---@param labelMsg string
---@param p2 integer
---@param p3 integer
---@param labelMsg2 string
---@param p5 boolean
---@param p6 integer
---@param p7 integer
---@param p8 string
---@param p9 string
---@param background boolean
---@param errorCode integer
function SetWarningMessageWithAlert(labelTitle, labelMsg, p2, p3, labelMsg2, p5, p6, p7, p8, p9, background, errorCode) end

---@param titleMsg string
---@param entryLine1 string
---@param flags integer
---@param promptMsg string
---@param p4 boolean
---@param p5 unknown
---@param background boolean
---@param showBg boolean
---@return unknown p7
function SetWarningMessageWithHeader(titleMsg, entryLine1, flags, promptMsg, p4, p5, background, showBg) end

---@param entryHeader string
---@param entryLine1 string
---@param instructionalKey unknown
---@param entryLine2 string
---@param p4 boolean
---@param p5 unknown
---@param p6 unknown
---@param p9 boolean
---@return unknown p7
---@return unknown p8
function SetWarningMessageWithHeaderAndSubstringFlags(entryHeader, entryLine1, instructionalKey, entryLine2, p4, p5, p6, p9) end

---@param headerTextLabel string
---@param line1TextLabel string
---@param buttonsBitField integer
---@param buttonsBitFieldUpper integer
---@param line2TextLabel string
---@param addNumber boolean
---@param numberToAdd integer
---@param firstSubstring string
---@param secondSubstring string
---@param showBackground boolean
---@param errorCode integer
function SetWarningMessageWithHeaderExtended(headerTextLabel, line1TextLabel, buttonsBitField, buttonsBitFieldUpper, line2TextLabel, addNumber, numberToAdd, firstSubstring, secondSubstring, showBackground, errorCode) end

---@param headerTextLabel string
---@param line1TextLabel string
---@param buttonsBitField integer
---@param buttonsBitFieldUpper integer
---@param line2TextLabel string
---@param addNumber boolean
---@param numberToAdd integer
---@param firstSubstring string
---@param secondSubstring string
---@param showBackground boolean
---@param errorCode integer
function SetWarningMessageWithHeaderUnk(headerTextLabel, line1TextLabel, buttonsBitField, buttonsBitFieldUpper, line2TextLabel, addNumber, numberToAdd, firstSubstring, secondSubstring, showBackground, errorCode) end

---@param minX integer
---@param minY integer
---@param maxX integer
---@param maxY integer
function SetWaterAreaClipRect(minX, minY, maxX, maxY) end

---@param waterQuad integer
---@param a0 integer
---@param a1 integer
---@param a2 integer
---@param a3 integer
---@return boolean
function SetWaterQuadAlpha(waterQuad, a0, a1, a2, a3) end

---@param waterQuad integer
---@param minX integer
---@param minY integer
---@param maxX integer
---@param maxY integer
---@return boolean
function SetWaterQuadBounds(waterQuad, minX, minY, maxX, maxY) end

---@param waterQuad integer
---@param hasLimitedDepth boolean
---@return boolean
function SetWaterQuadHasLimitedDepth(waterQuad, hasLimitedDepth) end

---@param waterQuad integer
---@param isInvisible boolean
---@return boolean
function SetWaterQuadIsInvisible(waterQuad, isInvisible) end

---@param waterQuad integer
---@param level number
---@return boolean
function SetWaterQuadLevel(waterQuad, level) end

---@param waterQuad integer
---@param noStencil boolean
---@return boolean
function SetWaterQuadNoStencil(waterQuad, noStencil) end

---@param waterQuad integer
---@param type integer
---@return boolean
function SetWaterQuadType(waterQuad, type) end

---@param waveQuad integer
---@param amplitude number
---@return boolean
function SetWaveQuadAmplitude(waveQuad, amplitude) end

---@param waveQuad integer
---@param minX integer
---@param minY integer
---@param maxX integer
---@param maxY integer
---@return boolean
function SetWaveQuadBounds(waveQuad, minX, minY, maxX, maxY) end

---@param waveQuad integer
---@param directionX number
---@param directionY number
---@return boolean
function SetWaveQuadDirection(waveQuad, directionX, directionY) end

---@param intensity number
function SetWavesIntensity(intensity) end

function SetWaypointOff() end

---@param weaponHash Hash|string
---@param spread number
function SetWeaponAccuracySpread(weaponHash, spread) end

---@param ped Ped
---@param animStyle Hash|string
function SetWeaponAnimationOverride(ped, animStyle) end

---@param weaponHash Hash|string
---@param damageMultiplier number
function SetWeaponDamageModifier(weaponHash, damageMultiplier) end

---@param weaponHash Hash|string
---@param damageMultiplier number
function SetWeaponDamageModifierThisFrame(weaponHash, damageMultiplier) end

---@param weaponHash Hash|string
---@param multiplier number
function SetWeaponExplosionRadiusMultiplier(weaponHash, multiplier) end

---@param weaponObject integer
---@param camoComponentHash Hash|string
---@param colorIndex integer
function SetWeaponObjectLiveryColor(weaponObject, camoComponentHash, colorIndex) end

---@param weapon integer
---@param tintIndex integer
function SetWeaponObjectTintIndex(weapon, tintIndex) end

---@param weaponHash Hash|string
---@param amplitude number
function SetWeaponRecoilShakeAmplitude(weaponHash, amplitude) end

---@param ped Ped
---@return boolean
function SetWeaponSmokegrenadeAssigned(ped) end

---@param state boolean
function SetWeaponsNoAimBlocking(state) end

---@param state boolean
function SetWeaponsNoAutoreload(state) end

---@param state boolean
function SetWeaponsNoAutoswap(state) end

---@param index integer
---@param typeName string
---@param timeMult integer
---@return boolean
function SetWeatherCycleEntry(index, typeName, timeMult) end

---@param network boolean
function SetWeatherOwnedByNetwork(network) end

---@param weatherType string
function SetWeatherTypeNow(weatherType) end

---@param weatherType string
function SetWeatherTypeNowPersist(weatherType) end

---@param weatherType string
---@param time number
function SetWeatherTypeOverTime(weatherType, time) end

---@param weatherType string
---@param time number
function SetWeatherTypeOvertimePersist(weatherType, time) end

---@param weatherType string
function SetWeatherTypePersist(weatherType) end

---@param weatherType1 Hash|string
---@param weatherType2 Hash|string
---@param percentWeather2 number
function SetWeatherTypeTransition(weatherType1, weatherType2, percentWeather2) end

---@param scale number
function SetWetClothPinRadiusScale(scale) end

---@param p0 boolean
---@param p1 integer
function SetWidescreenBorders(p0, p1) end

---@param p0 unknown
function SetWidescreenFormat(p0) end

---@param speed number
function SetWind(speed) end

---@param direction number
function SetWindDirection(direction) end

---@param speed number
function SetWindSpeed(speed) end

---@param zoneId integer
---@param toggle boolean
function SetZoneEnabled(zoneId, toggle) end

---@param cam integer
---@param type string
---@param amplitude number
function ShakeCam(cam, type, amplitude) end

---@param p0 string
---@param p1 number
function ShakeCinematicCam(p0, p1) end

---@param shakeName string
---@param intensity number
function ShakeGameplayCam(shakeName, intensity) end

---@param p0 string
---@param p1 number
function ShakeScriptGlobal(p0, p1) end

---@param entity Entity
function ShapeTestResultEntity(entity) end

---@param value integer
---@param bitShift integer
---@return integer
function ShiftLeft(value, bitShift) end

---@param value integer
---@param bitShift integer
---@return integer
function ShiftRight(value, bitShift) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param damage integer
---@param pureAccuracy boolean
---@param weaponHash Hash|string
---@param ownerPed Ped
---@param isAudible boolean
---@param isInvisible boolean
---@param speed number
function ShootSingleBulletBetweenCoords(x1, y1, z1, x2, y2, z2, damage, pureAccuracy, weaponHash, ownerPed, isAudible, isInvisible, speed) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param damage integer
---@param p7 boolean
---@param weaponHash Hash|string
---@param ownerPed Ped
---@param isAudible boolean
---@param isInvisible boolean
---@param speed number
---@param entity Entity
function ShootSingleBulletBetweenCoordsIgnoreEntity(x1, y1, z1, x2, y2, z2, damage, p7, weaponHash, ownerPed, isAudible, isInvisible, speed, entity) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param damage integer
---@param p7 boolean
---@param weaponHash Hash|string
---@param ownerPed Ped
---@param isAudible boolean
---@param isInvisible boolean
---@param speed number
---@param entity Entity
---@param p14 boolean
---@param p15 boolean
---@param p16 boolean
---@param p17 boolean
function ShootSingleBulletBetweenCoordsIgnoreEntityNew(x1, y1, z1, x2, y2, z2, damage, p7, weaponHash, ownerPed, isAudible, isInvisible, speed, entity, p14, p15, p16, p17) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param damage integer
---@param p7 boolean
---@param weaponHash Hash|string
---@param ownerPed Ped
---@param isAudible boolean
---@param isInvisible boolean
---@param speed number
---@param entity Entity
function ShootSingleBulletBetweenCoordsPresetParams(x1, y1, z1, x2, y2, z2, damage, p7, weaponHash, ownerPed, isAudible, isInvisible, speed, entity) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param damage integer
---@param p7 boolean
---@param weaponHash Hash|string
---@param ownerPed Ped
---@param isAudible boolean
---@param isInvisible boolean
---@param speed number
---@param entity Entity
---@param p14 boolean
---@param p15 boolean
---@param p16 boolean
---@param p17 boolean
function ShootSingleBulletBetweenCoordsWithExtraParams(x1, y1, z1, x2, y2, z2, damage, p7, weaponHash, ownerPed, isAudible, isInvisible, speed, entity, p14, p15, p16, p17) end

---@return boolean
function ShouldUseMetricMeasurements() end

---@param toggle boolean
function ShowContactInstructionalButton(toggle) end

---@param blip integer
---@param toggle boolean
function ShowCrewIndicatorOnBlip(blip, toggle) end

function ShowCursorThisFrame() end

---@param blip integer
---@param toggle boolean
function ShowFriendIndicatorOnBlip(blip, toggle) end

---@param blip integer
---@param toggle boolean
function ShowHasCompletedIndicatorOnBlip(blip, toggle) end

---@param blip integer
---@param toggle boolean
function ShowHeadingIndicatorOnBlip(blip, toggle) end

---@param blip integer
---@param toggle boolean
function ShowHeightOnBlip(blip, toggle) end

---@param id integer
function ShowHudComponentThisFrame(id) end

---@param busySpinnerType integer
function ShowLoadingPrompt(busySpinnerType) end

---@param blip integer
---@param number integer
function ShowNumberOnBlip(blip, number) end

---@param blip integer
---@param toggle boolean
function ShowOutlineIndicatorOnBlip(blip, toggle) end

---@param toggle boolean
function ShowPedInPauseMenu(toggle) end

---@param id integer
function ShowScriptedHudComponentThisFrame(id) end

function ShowSigninUi() end

function ShowSocialClubLegalScreen() end

---@param p0 boolean
function ShowStartMissionInstructionalButton(p0) end

---@param blip integer
---@param toggle boolean
function ShowTickOnBlip(blip, toggle) end

---@param show boolean
function ShowWeaponWheel(show) end

function ShutdownAndLaunchSinglePlayerGame() end

---@return boolean
function ShutdownAndLoadMostRecentSave() end

function ShutdownCreatorBudget() end

function ShutdownLoadingScreen() end

function ShutdownLoadingScreenNui() end

---@param player integer
---@param amount number
---@param gaitType integer
---@param rotationSpeed number
---@param p4 boolean
---@param p5 boolean
function SimulatePlayerInputGait(player, amount, gaitType, rotationSpeed, p4, p5) end

---@param value number
---@return number
function Sin(value) end

---@param method_return integer
---@return string
function SittingTv(method_return) end

function SkipRadioForward() end

---@param vehicle integer
---@param time number
function SkipTimeInPlaybackRecordedVehicle(vehicle, time) end

---@param vehicle integer
function SkipToEndAndStopPlaybackRecordedVehicle(vehicle) end

function SkipToNextScriptedConversationLine() end

---@param t number
---@param x number
---@param y number
---@param z number
---@param w number
---@param x1 number
---@param y1 number
---@param z1 number
---@param w1 number
---@return number outX
---@return number outY
---@return number outZ
---@return number outW
function SlerpNearQuaternion(t, x, y, z, w, x1, y1, z1, w1) end

---@param object integer
---@param toX number
---@param toY number
---@param toZ number
---@param speedX number
---@param speedY number
---@param speedZ number
---@param collision boolean
---@return boolean
function SlideObject(object, toX, toY, toZ, speedX, speedY, speedZ, collision) end

---@param vehicle integer
---@param windowIndex integer
function SmashVehicleWindow(vehicle, windowIndex) end

---@param vehicle integer
function SoundVehicleHornThisFrame(vehicle) end

function SpawnpointsCancelSearch() end

---@return integer
function SpawnpointsGetNumSearchResults() end

---@param randomInt integer
---@return number x
---@return number y
---@return number z
function SpawnpointsGetSearchResult(randomInt) end

---@param p0 unknown
---@return unknown p1
function SpawnpointsGetSearchResultFlags(p0) end

---@return boolean
function SpawnpointsIsSearchActive() end

---@return boolean
function SpawnpointsIsSearchComplete() end

---@return boolean
function SpawnpointsIsSearchFailed() end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param interiorFlags integer
---@param scale number
---@param duration integer
function SpawnpointsStartSearch(p0, p1, p2, p3, p4, interiorFlags, scale, duration) end

---@param x number
---@param y number
---@param z number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param interiorFlags integer
---@param scale number
---@param duration integer
function SpawnpointsStartSearchInAngledArea(x, y, z, p3, p4, p5, p6, interiorFlags, scale, duration) end

---@param player unknown
function SpecialAbilityActivate(player) end

---@param player integer
---@param p1 integer
---@param p2 boolean
function SpecialAbilityChargeAbsolute(player, p1, p2) end

---@param player integer
---@param p2 Ped
function SpecialAbilityChargeContinuous(player, p2) end

---@param player integer
---@param p1 boolean
---@param p2 boolean
function SpecialAbilityChargeLarge(player, p1, p2) end

---@param player integer
---@param p1 boolean
---@param p2 boolean
function SpecialAbilityChargeMedium(player, p1, p2) end

---@param player integer
---@param normalizedValue number
---@param p2 boolean
function SpecialAbilityChargeNormalized(player, normalizedValue, p2) end

---@param player integer
function SpecialAbilityChargeOnMissionFailed(player) end

---@param player integer
---@param p1 boolean
---@param p2 boolean
function SpecialAbilityChargeSmall(player, p1, p2) end

---@param player integer
function SpecialAbilityDeactivate(player) end

---@param player integer
function SpecialAbilityDeactivateFast(player) end

---@param p0 unknown
function SpecialAbilityDeplete(p0) end

---@param player integer
---@param p1 boolean
function SpecialAbilityDepleteMeter(player, p1) end

---@param player integer
---@param p1 boolean
function SpecialAbilityFillMeter(player, p1) end

---@param playerModel Hash|string
function SpecialAbilityLock(playerModel) end

---@param player integer
function SpecialAbilityReset(player) end

---@param playerModel Hash|string
function SpecialAbilityUnlock(playerModel) end

---@param x number
---@param y number
---@param z number
function SpecialFrontendEqual(x, y, z) end

---@param ped Ped
---@param noCollisionUntilClear boolean
function SpecialFunctionDoNotUse(ped, noCollisionUntilClear) end

---@param value number
---@return number
function Sqrt(value) end

---@param vehicle integer
---@param entity Entity
---@param p2 number
function StabiliseEntityAttachedToHeli(vehicle, entity, p2) end

---@param alarmName string
---@param skipStartup boolean
function StartAlarm(alarmName, skipStartup) end

---@param scene string
---@return boolean
function StartAudioScene(scene) end

function StartBenchmarkRecording() end

---@param flags integer
function StartCutscene(flags) end

---@param x number
---@param y number
---@param z number
---@param flags integer
function StartCutsceneAtCoords(x, y, z, flags) end

---@param entity Entity
---@return integer
function StartEntityFire(entity) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param flags integer
---@param entity Entity
---@param p8 integer
---@return integer
function StartExpensiveSynchronousShapeTestLosProbe(x1, y1, z1, x2, y2, z2, flags, entity, p8) end

---@param resourceName string
---@param prefix string
---@return integer
function StartFindExternalKvp(resourceName, prefix) end

---@param duration integer
function StartFiringAmnesty(duration) end

---@param hudColor integer
---@param displayOnFoot boolean
---@param followPlayer boolean
function StartGpsCustomRoute(hudColor, displayOnFoot, followPlayer) end

---@param hudColor integer
---@param routeFromPlayer boolean
---@param displayOnFoot boolean
function StartGpsMultiRoute(hudColor, routeFromPlayer, displayOnFoot) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartNetworkedParticleFxLoopedOnEntity(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param boneIndex integer
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartNetworkedParticleFxLoopedOnEntityBone(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, boneIndex, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param xPos number
---@param yPos number
---@param zPos number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return boolean
function StartNetworkedParticleFxNonLoopedAtCoord(effectName, xPos, yPos, zPos, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param entity Entity
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param scale number
---@param axisX boolean
---@param axisY boolean
---@param axisZ boolean
---@return boolean
function StartNetworkedParticleFxNonLoopedOnEntity(effectName, entity, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale, axisX, axisY, axisZ) end

---@param effectName string
---@param entity Entity
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param boneIndex integer
---@param scale number
---@param axisX boolean
---@param axisY boolean
---@param axisZ boolean
---@return boolean
function StartNetworkedParticleFxNonLoopedOnEntityBone(effectName, entity, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, boneIndex, scale, axisX, axisY, axisZ) end

---@param effectName string
---@param ped Ped
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param boneIndex integer
---@param scale number
---@param axisX boolean
---@param axisY boolean
---@param axisZ boolean
---@return boolean
function StartNetworkedParticleFxNonLoopedOnPedBone(effectName, ped, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, boneIndex, scale, axisX, axisY, axisZ) end

---@param scriptName string
---@param stackSize integer
---@return integer
function StartNewScript(scriptName, stackSize) end

---@param scriptName string
---@param argCount integer
---@param stackSize integer
---@return integer
---@return unknown args
function StartNewScriptWithArgs(scriptName, argCount, stackSize) end

---@param scriptHash Hash|string
---@param stackSize integer
---@return integer
function StartNewScriptWithNameHash(scriptHash, stackSize) end

---@param scriptHash Hash|string
---@param argCount integer
---@param stackSize integer
---@return integer
---@return unknown args
function StartNewScriptWithNameHashAndArgs(scriptHash, argCount, stackSize) end

---@param scriptHash Hash|string
---@param stackSize integer
---@return integer
function StartNewStreamedScript(scriptHash, stackSize) end

---@param scriptHash Hash|string
---@param argCount integer
---@param stackSize integer
---@return integer
---@return unknown args
function StartNewStreamedScriptWithArgs(scriptHash, argCount, stackSize) end

---@param effectName string
---@param x number
---@param y number
---@param z number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@param p11 boolean
---@return integer
function StartParticleFxLoopedAtCoord(effectName, x, y, z, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis, p11) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartParticleFxLoopedOnEntity(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartParticleFxLoopedOnEntity_2(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param boneIndex integer
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartParticleFxLoopedOnEntityBone(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, boneIndex, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param entity Entity
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param boneIndex integer
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartParticleFxLoopedOnEntityBone_2(effectName, entity, xOffset, yOffset, zOffset, xRot, yRot, zRot, boneIndex, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param ped Ped
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param xRot number
---@param yRot number
---@param zRot number
---@param boneIndex integer
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartParticleFxLoopedOnPedBone(effectName, ped, xOffset, yOffset, zOffset, xRot, yRot, zRot, boneIndex, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param xPos number
---@param yPos number
---@param zPos number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return integer
function StartParticleFxNonLoopedAtCoord(effectName, xPos, yPos, zPos, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param xPos number
---@param yPos number
---@param zPos number
---@param xRot number
---@param yRot number
---@param zRot number
---@param scale number
---@param xAxis boolean
---@param yAxis boolean
---@param zAxis boolean
---@return boolean
function StartParticleFxNonLoopedAtCoord_2(effectName, xPos, yPos, zPos, xRot, yRot, zRot, scale, xAxis, yAxis, zAxis) end

---@param effectName string
---@param entity Entity
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param scale number
---@param axisX boolean
---@param axisY boolean
---@param axisZ boolean
---@return boolean
function StartParticleFxNonLoopedOnEntity(effectName, entity, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale, axisX, axisY, axisZ) end

---@param effectName string
---@param entity Entity
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param scale number
---@param axisX boolean
---@param axisY boolean
---@param axisZ boolean
---@return boolean
function StartParticleFxNonLoopedOnEntity_2(effectName, entity, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale, axisX, axisY, axisZ) end

---@param effectName string
---@param ped Ped
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param boneIndex integer
---@param scale number
---@param axisX boolean
---@param axisY boolean
---@param axisZ boolean
---@return boolean
function StartParticleFxNonLoopedOnPedBone(effectName, ped, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, boneIndex, scale, axisX, axisY, axisZ) end

---@param effectName string
---@param ped Ped
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param boneIndex integer
---@param scale number
---@param axisX boolean
---@param axisY boolean
---@param axisZ boolean
---@return boolean
function StartParticleFxNonLoopedOnPedBone_2(effectName, ped, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, boneIndex, scale, axisX, axisY, axisZ) end

---@param p0 number
function StartPetrolTrailDecals(p0) end

---@param vehicle integer
---@param recording integer
---@param script string
---@param p3 boolean
function StartPlaybackRecordedVehicle(vehicle, recording, script, p3) end

---@param vehicle integer
---@param recording integer
---@param script string
---@param speed number
---@param drivingStyle integer
function StartPlaybackRecordedVehicleUsingAi(vehicle, recording, script, speed, drivingStyle) end

---@param vehicle integer
---@param recording integer
---@param script string
---@param flags integer
---@param time integer
---@param drivingStyle integer
function StartPlaybackRecordedVehicleWithFlags(vehicle, recording, script, flags, time, drivingStyle) end

---@param from Ped
---@param to Ped
---@param flags integer
---@param switchType integer
function StartPlayerSwitch(from, to, flags, switchType) end

---@param player integer
---@param x number
---@param y number
---@param z number
---@param heading number
---@param teleportWithVehicle boolean
---@param findCollisionLand boolean
---@param p7 boolean
function StartPlayerTeleport(player, x, y, z, heading, teleportWithVehicle, findCollisionLand, p7) end

function StartPreloadedConversation() end

---@param mode integer
function StartRecording(mode) end

---@param ropeId integer
function StartRopeUnwindingFront(ropeId) end

---@param ropeId integer
function StartRopeWinding(ropeId) end

---@param size integer
---@param arrayName string
---@return unknown p0
function StartSaveArray(size, arrayName) end

---@param size integer
---@param arrayName string
---@return unknown p0
function StartSaveArrayWithSize(size, arrayName) end

---@param p1 unknown
---@param p2 boolean
---@return unknown p0
function StartSaveData(p1, p2) end

---@param size integer
---@param structName string
---@return unknown p0
function StartSaveStruct(size, structName) end

---@param size integer
---@param structName string
---@return unknown p0
function StartSaveStructWithSize(size, structName) end

---@param effectName string
---@param duration integer
---@param looped boolean
function StartScreenEffect(effectName, duration, looped) end

---@param displaySubtitles boolean
---@param addToBriefScreen boolean
---@param cloneConversation boolean
---@param interruptible boolean
function StartScriptConversation(displaySubtitles, addToBriefScreen, cloneConversation, interruptible) end

---@param X number
---@param Y number
---@param Z number
---@param maxChildren integer
---@param isGasFire boolean
---@return integer
function StartScriptFire(X, Y, Z, maxChildren, isGasFire) end

---@param displaySubtitles boolean
---@param addToBriefScreen boolean
function StartScriptPhoneConversation(displaySubtitles, addToBriefScreen) end

---@param entity Entity
---@param flags1 integer
---@param flags2 integer
---@return integer
function StartShapeTestBound(entity, flags1, flags2) end

---@param entity Entity
---@param flags1 integer
---@param flags2 integer
---@return integer
function StartShapeTestBoundingBox(entity, flags1, flags2) end

---@param x number
---@param y number
---@param z number
---@param x1 number
---@param y1 number
---@param z1 number
---@param rotX number
---@param rotY number
---@param rotZ number
---@param p9 integer
---@param flags integer
---@param entity Entity
---@param p12 integer
---@return integer
function StartShapeTestBox(x, y, z, x1, y1, z1, rotX, rotY, rotZ, p9, flags, entity, p12) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number
---@param flags integer
---@param entity Entity
---@param p9 integer
---@return integer
function StartShapeTestCapsule(x1, y1, z1, x2, y2, z2, radius, flags, entity, p9) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number
---@param flags integer
---@param entity Entity
---@param p9 integer
---@return integer
function StartShapeTestCapsule_2(x1, y1, z1, x2, y2, z2, radius, flags, entity, p9) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param traceFlags integer
---@param entity Entity
---@param options integer
---@return integer
function StartShapeTestLosProbe(x1, y1, z1, x2, y2, z2, traceFlags, entity, options) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param flags integer
---@param entity Entity
---@param p8 integer
---@return integer
function StartShapeTestRay(x1, y1, z1, x2, y2, z2, flags, entity, p8) end

---@param flag integer
---@param entity Entity
---@param flag2 integer
---@return integer
---@return vector3 pVec1
---@return vector3 pVec2
function StartShapeTestSurroundingCoords(flag, entity, flag2) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param radius number
---@param flags integer
---@param entity Entity
---@param p9 integer
---@return integer
function StartShapeTestSweptSphere(x1, y1, z1, x2, y2, z2, radius, flags, entity, p9) end

---@param vehicle integer
function StartVehicleAlarm(vehicle) end

---@param vehicle integer
---@param duration integer
---@param mode Hash|string
---@param forever boolean
function StartVehicleHorn(vehicle, duration, mode, forever) end

---@param statSlot integer
---@return unknown
function StatClearSlotForReload(statSlot) end

---@param p0 unknown
---@return unknown
function StatDeleteSlot(p0) end

---@param statHash Hash|string
---@param p2 unknown
---@return boolean
---@return boolean outValue
function StatGetBool(statHash, p2) end

---@param statName Hash|string
---@param mask integer
---@param p2 integer
---@return boolean
function StatGetBoolMasked(statName, mask, p2) end

---@return integer
function StatGetCancelSaveMigrationStatus() end

---@param statHash Hash|string
---@param p2 unknown
---@param p3 unknown
---@return boolean
---@return unknown p1
function StatGetDate(statHash, p2, p3) end

---@param statHash Hash|string
---@param p2 unknown
---@return boolean
---@return number outValue
function StatGetFloat(statHash, p2) end

---@param statHash Hash|string
---@param p2 integer
---@return boolean
---@return integer outValue
function StatGetInt(statHash, p2) end

---@param statName Hash|string
---@return string
function StatGetLicensePlate(statName) end

---@param p0 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@return boolean
---@return unknown p1
function StatGetMaskedInt(p0, p2, p3, p4) end

---@param statName Hash|string
---@return integer
function StatGetNumberOfDays(statName) end

---@param statName Hash|string
---@return integer
function StatGetNumberOfHours(statName) end

---@param statName Hash|string
---@return integer
function StatGetNumberOfMinutes(statName) end

---@param statName Hash|string
---@return integer
function StatGetNumberOfSeconds(statName) end

---@param p0 integer
---@return integer
function StatGetPackedBoolMask(p0) end

---@param p0 integer
---@return integer
function StatGetPackedIntMask(p0) end

---@param p0 unknown
---@param p4 unknown
---@return boolean
---@return unknown p1
---@return unknown p2
---@return unknown p3
function StatGetPos(p0, p4) end

---@return integer
---@return integer p0
function StatGetSaveMigrationConsumeContentUnlockStatus() end

---@return integer
---@return unknown data
function StatGetSaveMigrationStatus() end

---@param statHash Hash|string
---@param p1 integer
---@return string
function StatGetString(statHash, p1) end

---@param p0 unknown
---@return string
function StatGetUserId(p0) end

---@param statName Hash|string
---@param value number
function StatIncrement(statName, value) end

---@param p0 integer
---@return boolean
function StatLoad(p0) end

---@param p0 unknown
---@return boolean
function StatLoadPending(p0) end

---@param platformName string
---@return boolean
function StatMigrateSave(platformName) end

---@param p0 integer
---@param p1 boolean
---@param p2 integer
---@return boolean
function StatSave(p0, p1, p2) end

---@return boolean
function StatSaveMigrationCancel() end

---@param contentId Hash|string
---@param srcPlatform string
---@param srcGamerHandle string
---@return boolean
function StatSaveMigrationConsumeContentUnlock(contentId, srcPlatform, srcGamerHandle) end

---@return boolean
function StatSaveMigrationStatusStart() end

---@return boolean
function StatSavePending() end

---@return boolean
function StatSavePendingOrRequested() end

---@param toggle boolean
function StatSetBlockSaves(toggle) end

---@param statName Hash|string
---@param value boolean
---@param save boolean
---@return boolean
function StatSetBool(statName, value, save) end

---@param statName Hash|string
---@param value boolean
---@param mask integer
---@param save boolean
---@return boolean
function StatSetBoolMasked(statName, value, mask, save) end

function StatSetCheatIsActive() end

---@param statName Hash|string
---@param p1 boolean
---@return boolean
function StatSetCurrentPosixTime(statName, p1) end

---@param statName Hash|string
---@param numFields integer
---@param save boolean
---@return boolean
---@return unknown value
function StatSetDate(statName, numFields, save) end

---@param statName Hash|string
---@param value number
---@param save boolean
---@return boolean
function StatSetFloat(statName, value, save) end

---@param statName Hash|string
---@param value string
---@param save boolean
---@return boolean
function StatSetGxtLabel(statName, value, save) end

---@param statName Hash|string
---@param value integer
---@param save boolean
---@return boolean
function StatSetInt(statName, value, save) end

---@param statName Hash|string
---@param str string
---@return boolean
function StatSetLicensePlate(statName, str) end

---@param statName Hash|string
---@param p1 unknown
---@param p2 unknown
---@param p3 integer
---@param save boolean
---@return boolean
function StatSetMaskedInt(statName, p1, p2, p3, save) end

---@param statName Hash|string
---@param x number
---@param y number
---@param z number
---@param save boolean
---@return boolean
function StatSetPos(statName, x, y, z, save) end

---@param profileSetting integer
---@param value integer
function StatSetProfileSetting(profileSetting, value) end

---@param profileSetting integer
---@param value integer
function StatSetProfileSettingValue(profileSetting, value) end

---@param statName Hash|string
---@param value string
---@param save boolean
---@return boolean
function StatSetString(statName, value, save) end

---@param statName Hash|string
---@param value string
---@param save boolean
---@return boolean
function StatSetUserId(statName, value, save) end

---@param p0 unknown
---@return boolean
function StatSlotIsLoaded(p0) end

---@param vehicle integer
---@param toggle boolean
function SteerUnlockBias(vehicle, toggle) end

---@param alarmName string
---@param instantStop boolean
function StopAlarm(alarmName, instantStop) end

---@param instantStop boolean
function StopAllAlarms(instantStop) end

function StopAllGarageActivity() end

function StopAllScreenEffects() end

---@param ped Ped
---@param p1 integer
---@param p2 boolean
function StopAnimPlayback(ped, p1, p2) end

---@param ped Ped
---@param animDictionary string
---@param animationName string
---@param animExitSpeed number
function StopAnimTask(ped, animDictionary, animationName, animExitSpeed) end

function StopAnyPedModelBeingSuppressed() end

---@param sceneName string
function StopAudioScene(sceneName) end

function StopAudioScenes() end

function StopBenchmarkRecording() end

---@param binkMovie integer
function StopBinkMovie(binkMovie) end

---@param vehicle integer
function StopBringVehicleToHalt(vehicle) end

---@param cam integer
function StopCamPointing(cam) end

---@param cam integer
---@param p1 boolean
function StopCamShaking(cam, p1) end

---@param p0 boolean
function StopCinematicCamShaking(p0) end

---@param p0 Hash|string
function StopCinematicShot(p0) end

---@param ped Ped
function StopCurrentPlayingAmbientSpeech(ped) end

---@param ped Ped
function StopCurrentPlayingSpeech(ped) end

---@param p0 boolean
function StopCutscene(p0) end

function StopCutsceneAudio() end

function StopCutsceneCamShaking() end

function StopCutsceneImmediately() end

---@param entity Entity
---@param animation string
---@param animGroup string
---@param p3 number
---@return unknown
function StopEntityAnim(entity, animation, animGroup, p3) end

---@param entity Entity
function StopEntityFire(entity) end

---@param x number
---@param y number
---@param z number
---@param radius number
function StopFireInRange(x, y, z, radius) end

---@param bStopImmediately boolean
function StopGameplayCamShaking(bStopImmediately) end

---@param bStopImmediately boolean
function StopGameplayHint(bStopImmediately) end

---@param padIndex integer
function StopPadShake(padIndex) end

---@param ptfxHandle integer
---@param p1 boolean
function StopParticleFxLooped(ptfxHandle, p1) end

---@param ped Ped
function StopPedRingtone(ped) end

---@param ped Ped
---@param shouldDisable boolean
function StopPedSpeaking(ped, shouldDisable) end

---@param ped Ped
---@param shouldDisable boolean
function StopPedSpeakingSynced(ped, shouldDisable) end

---@param ped Ped
function StopPedWeaponFiringWhenDropped(ped) end

---@param vehicle integer
function StopPlaybackRecordedVehicle(vehicle) end

function StopPlayerSwitch() end

function StopPlayerTeleport() end

function StopRecording() end

function StopRecordingAndDiscardClip() end

function StopRecordingAndSaveClip() end

function StopRecordingThisFrame() end

---@param bShouldApplyAcrossAllThreads boolean
---@param distanceToBlend number
---@param blendType integer
function StopRenderingScriptCamsUsingCatchUp(bShouldApplyAcrossAllThreads, distanceToBlend, blendType) end

---@param ropeId integer
function StopRopeUnwindingFront(ropeId) end

---@param ropeId integer
function StopRopeWinding(ropeId) end

function StopSaveArray() end

function StopSaveData() end

function StopSaveStruct() end

---@param effectName string
function StopScreenEffect(effectName) end

---@param finishCurrentLine boolean
---@return integer
function StopScriptedConversation(finishCurrentLine) end

---@param bStopImmediately boolean
function StopScriptGlobalShaking(bStopImmediately) end

function StopSmokeGrenadeExplosionSounds() end

---@param soundId integer
function StopSound(soundId) end

function StopStream() end

---@param p0 unknown
---@return boolean
function StopSynchronizedAudioEvent(p0) end

---@param entity Entity
---@param p1 number
---@param p2 boolean
---@return boolean
function StopSynchronizedEntityAnim(entity, p1, p2) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 unknown
---@param p5 number
---@return boolean
function StopSynchronizedMapEntityAnim(p0, p1, p2, p3, p4, p5) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 unknown
---@param p8 unknown
---@return unknown
function StreamvolCreateFrustum(p0, p1, p2, p3, p4, p5, p6, p7, p8) end

---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 unknown
---@return unknown
function StreamvolCreateLine(p0, p1, p2, p3, p4, p5, p6) end

---@param x number
---@param y number
---@param z number
---@param rad number
---@param p4 unknown
---@param p5 unknown
---@return unknown
function StreamvolCreateSphere(x, y, z, rad, p4, p5) end

---@param unused unknown
function StreamvolDelete(unused) end

---@param unused unknown
---@return boolean
function StreamvolHasLoaded(unused) end

---@param unused unknown
---@return boolean
function StreamvolIsValid(unused) end

---@param string string
---@return boolean
---@return integer outInteger
function StringToInt(string) end

---@param timeA integer
---@param timeB integer
---@return boolean
function SubtractAFromBAndCheckIfNegative(timeA, timeB) end

---@param timeA integer
---@param timeB integer
---@return boolean
function SubtractBFromAAndCheckIfNegative(timeA, timeB) end

function SuppressAgitationEventsNextFrame() end

---@param player integer
---@param crimeType integer
function SuppressCrimeThisFrame(player, crimeType) end

function SuppressFrontendRenderingThisFrame() end

function SuppressShockingEventsNextFrame() end

---@param eventType integer
function SuppressShockingEventTypeNextFrame(eventType) end

---@param eventType integer
---@param enable boolean
function SupressRandomEventThisFrame(eventType, enable) end

---@param player integer
---@param crimeType integer
function SwitchCrimeType(player, crimeType) end

---@param ped Ped
function SwitchInPlayer(ped) end

---@param ped Ped
---@param flags integer
---@param switchType integer
function SwitchOutPlayer(ped, flags, switchType) end

---@param name string
---@return boolean
function SwitchToInputMappingScheme(name) end

---@param name string
---@return boolean
function SwitchToInputMappingScheme_2(name) end

---@param ped Ped
---@param flags integer
---@param switchType integer
function SwitchToMultiFirstpart(ped, flags, switchType) end

---@param ped Ped
function SwitchToMultiSecondpart(ped) end

---@param trackId integer
---@param state boolean
function SwitchTrainTrack(trackId, state) end

function TakeControlOfFrontend() end

---@param scene integer
function TakeOwnershipOfSynchronizedScene(scene) end

---@param p0 number
---@return number
function Tan(p0) end

---@param ped Ped
---@param heading number
---@param timeout integer
function TaskAchieveHeading(ped, heading, timeout) end

---@param ped Ped
---@param ped2 Ped
function TaskAgitatedAction(ped, ped2) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param time integer
---@param bInstantBlendToAim boolean
---@param bPlayAimIntro boolean
function TaskAimGunAtCoord(ped, x, y, z, time, bInstantBlendToAim, bPlayAimIntro) end

---@param ped Ped
---@param entity Entity
---@param duration integer
---@param bInstantBlendToAim boolean
function TaskAimGunAtEntity(ped, entity, duration, bInstantBlendToAim) end

---@param ped Ped
---@param scriptTask Hash|string
---@param bDisableBlockingClip boolean
---@param bInstantBlendToAim boolean
function TaskAimGunScripted(ped, scriptTask, bDisableBlockingClip, bInstantBlendToAim) end

---@param ped Ped
---@param targetPed Ped
---@param x number
---@param y number
---@param z number
---@param iGunTaskType Hash|string
---@param bDisableBlockingClip boolean
---@param bForceAim boolean
function TaskAimGunScriptedWithTarget(ped, targetPed, x, y, z, iGunTaskType, bDisableBlockingClip, bForceAim) end

---@param ped Ped
---@param target Ped
function TaskArrestPed(ped, target) end

---@param ped Ped
---@param boat integer
---@param vehicleTarget integer
---@param pedTarget Ped
---@param x number
---@param y number
---@param z number
---@param missionType integer
---@param speed number
---@param drivingStyle integer
---@param radius number
---@param missionFlags integer
function TaskBoatMission(ped, boat, vehicleTarget, pedTarget, x, y, z, missionType, speed, drivingStyle, radius, missionFlags) end

---@param ped Ped
---@param target Ped
---@param p2 unknown
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
function TaskChatToPed(ped, target, p2, p3, p4, p5, p6, p7) end

---@param p0 unknown
function TaskClearDefensiveArea(p0) end

---@param ped Ped
function TaskClearLookAt(ped) end

---@param ped Ped
---@param unused boolean
function TaskClimb(ped, unused) end

---@param ped Ped
---@param p1 integer
function TaskClimbLadder(ped, p1) end

---@param ped Ped
---@param radius number
---@param p2 integer
function TaskCombatHatedTargetsAroundPed(ped, radius, p2) end

---@param p0 unknown
---@param p1 number
---@param p2 unknown
---@param p3 unknown
function TaskCombatHatedTargetsAroundPedTimed(p0, p1, p2, p3) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param radius number
---@param p5 unknown
function TaskCombatHatedTargetsInArea(ped, x, y, z, radius, p5) end

---@param ped Ped
---@param targetPed Ped
---@param p2 integer
---@param p3 integer
function TaskCombatPed(ped, targetPed, p2, p3) end

---@param p0 unknown
---@param ped Ped
---@param p2 integer
---@param p3 unknown
function TaskCombatPedTimed(p0, ped, p2, p3) end

---@param ped Ped
---@param duration integer
function TaskCower(ped, duration) end

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

---@param p0 unknown
---@param p1 unknown
---@param p2 number
---@param p3 number
---@param p4 number
function TaskExitCover(p0, p1, p2, p3, p4) end

---@param x number
---@param y number
---@param z number
function TaskExtendRoute(x, y, z) end

function TaskFlushRoute() end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param moveBlendRatio number
---@param time integer
---@param radius number
---@param flags integer
---@param finalHeading number
function TaskFollowNavMeshToCoord(ped, x, y, z, moveBlendRatio, time, radius, flags, finalHeading) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param speed number
---@param timeout integer
---@param unkFloat number
---@param unkInt integer
---@param unkX number
---@param unkY number
---@param unkZ number
---@param unk_40000f number
function TaskFollowNavMeshToCoordAdvanced(ped, x, y, z, speed, timeout, unkFloat, unkInt, unkX, unkY, unkZ, unk_40000f) end

---@param ped Ped
---@param speed number
---@param routeMode integer
function TaskFollowPointRoute(ped, speed, routeMode) end

---@param ped Ped
---@param entity Entity
---@param offsetX number
---@param offsetY number
---@param offsetZ number
---@param movementSpeed number
---@param timeout integer
---@param stoppingRange number
---@param persistFollowing boolean
function TaskFollowToOffsetOfEntity(ped, entity, offsetX, offsetY, offsetZ, movementSpeed, timeout, stoppingRange, persistFollowing) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function TaskFollowWaypointRecording(p0, p1, p2, p3, p4) end

---@param ped Ped
---@param state Hash|string
---@param p2 boolean
function TaskForceMotionState(ped, state, p2) end

---@param ped Ped
---@param boat integer
function TaskGetOffBoat(ped, boat) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param speed number
---@param timeout integer
---@param targetHeading number
---@param distanceToSlide number
function TaskGoStraightToCoord(ped, x, y, z, speed, timeout, targetHeading, distanceToSlide) end

---@param entity1 Entity
---@param entity2 Entity
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 unknown
function TaskGoStraightToCoordRelativeToEntity(entity1, entity2, p2, p3, p4, p5, p6) end

---@param pedHandle Ped
---@param goToLocationX number
---@param goToLocationY number
---@param goToLocationZ number
---@param focusLocationX number
---@param focusLocationY number
---@param focusLocationZ number
---@param speed number
---@param shootAtEnemies boolean
---@param distanceToStopAt number
---@param noRoadsDistance number
---@param unkTrue boolean
---@param unkFlag integer
---@param aimingFlag integer
---@param firingPattern Hash|string
function TaskGoToCoordAndAimAtHatedEntitiesNearCoord(pedHandle, goToLocationX, goToLocationY, goToLocationZ, focusLocationX, focusLocationY, focusLocationZ, speed, shootAtEnemies, distanceToStopAt, noRoadsDistance, unkTrue, unkFlag, aimingFlag, firingPattern) end

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

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param speed number
---@param p5 unknown
---@param p6 boolean
---@param walkingStyle integer
---@param p8 number
---@param p9 unknown
---@param p10 unknown
---@param p11 unknown
function TaskGoToCoordAnyMeansExtraParams(ped, x, y, z, speed, p5, p6, walkingStyle, p8, p9, p10, p11) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param speed number
---@param p5 unknown
---@param p6 boolean
---@param walkingStyle integer
---@param p8 number
---@param p9 unknown
---@param p10 unknown
---@param p11 unknown
---@param p12 unknown
function TaskGoToCoordAnyMeansExtraParamsWithCruiseSpeed(ped, x, y, z, speed, p5, p6, walkingStyle, p8, p9, p10, p11, p12) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param aimAtX number
---@param aimAtY number
---@param aimAtZ number
---@param moveSpeed number
---@param shoot boolean
---@param p9 number
---@param p10 number
---@param p11 boolean
---@param flags unknown
---@param p13 boolean
---@param firingPattern Hash|string
function TaskGoToCoordWhileAimingAtCoord(ped, x, y, z, aimAtX, aimAtY, aimAtZ, moveSpeed, shoot, p9, p10, p11, flags, p13, firingPattern) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param entityToAimAt Entity
---@param moveSpeed number
---@param shoot boolean
---@param targetRadius number
---@param slowDistance number
---@param useNavMesh boolean
---@param navFlags integer
---@param instantBlendAtAim boolean
---@param firingPattern Hash|string
---@param time integer
function TaskGoToCoordWhileAimingAtEntity(ped, x, y, z, entityToAimAt, moveSpeed, shoot, targetRadius, slowDistance, useNavMesh, navFlags, instantBlendAtAim, firingPattern, time) end

---@param entity Entity
---@param target Entity
---@param duration integer
---@param distance number
---@param speed number
---@param p5 number
---@param p6 integer
function TaskGoToEntity(entity, target, duration, distance, speed, p5, p6) end

---@param ped Ped
---@param target Entity
---@param distanceToStopAt number
---@param StartAimingDist number
function TaskGotoEntityAiming(ped, target, distanceToStopAt, StartAimingDist) end

---@param ped Ped
---@param p1 unknown
---@param p2 unknown
---@param x number
---@param y number
---@param z number
---@param duration integer
function TaskGotoEntityOffset(ped, p1, p2, x, y, z, duration) end

---@param ped Ped
---@param entity Entity
---@param duration integer
---@param xOffset number
---@param yOffset number
---@param zOffset number
---@param moveBlendRatio number
---@param useNavmesh boolean
function TaskGotoEntityOffsetXy(ped, entity, duration, xOffset, yOffset, zOffset, moveBlendRatio, useNavmesh) end

---@param p0 unknown
---@param p1 unknown
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 boolean
---@param p7 number
---@param p8 number
---@param p9 boolean
---@param p10 boolean
---@param p11 unknown
function TaskGoToEntityWhileAimingAtCoord(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) end

---@param ped Ped
---@param entityToWalkTo Entity
---@param entityToAimAt Entity
---@param speed number
---@param shootatEntity boolean
---@param p5 number
---@param p6 number
---@param p7 boolean
---@param p8 boolean
---@param firingPattern Hash|string
function TaskGoToEntityWhileAimingAtEntity(ped, entityToWalkTo, entityToAimAt, speed, shootatEntity, p5, p6, p7, p8, firingPattern) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 unknown
function TaskGuardAssignedDefensiveArea(p0, p1, p2, p3, p4, p5, p6) end

---@param p0 Ped
---@param p1 number
---@param p2 number
---@param p3 boolean
function TaskGuardCurrentPosition(p0, p1, p2, p3) end

---@param p0 Ped
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 unknown
---@param p7 number
---@param p8 number
---@param p9 number
---@param p10 number
function TaskGuardSphereDefensiveArea(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) end

---@param ped Ped
---@param duration integer
---@param facingPed Ped
---@param p3 integer
---@param p4 boolean
function TaskHandsUp(ped, duration, facingPed, p3, p4) end

---@param pilot Ped
---@param entityToFollow Entity
---@param x number
---@param y number
---@param z number
function TaskHeliChase(pilot, entityToFollow, x, y, z) end

---@param pilot Ped
---@param heli1 integer
---@param heli2 integer
---@param p3 number
---@param p4 number
---@param p5 number
function TaskHeliEscortHeli(pilot, heli1, heli2, p3, p4, p5) end

---@param ped Ped
---@param heli integer
---@param vehicleTarget integer
---@param pedTarget Ped
---@param x number
---@param y number
---@param z number
---@param missionType integer
---@param speed number
---@param radius number
---@param heading number
---@param height number
---@param minHeight number
---@param slowDist number
---@param missionFlags integer
function TaskHeliMission(ped, heli, vehicleTarget, pedTarget, x, y, z, missionType, speed, radius, heading, height, minHeight, slowDist, missionFlags) end

---@param ped Ped
---@param unused boolean
function TaskJump(ped, unused) end

---@param ped Ped
---@param p1 integer
---@param flags integer
function TaskLeaveAnyVehicle(ped, p1, flags) end

---@param ped Ped
---@param vehicle integer
---@param flags integer
function TaskLeaveVehicle(ped, vehicle, flags) end

---@param entity Entity
---@param x number
---@param y number
---@param z number
---@param duration integer
---@param p5 unknown
---@param p6 unknown
function TaskLookAtCoord(entity, x, y, z, duration, p5, p6) end

---@param ped Ped
---@param lookAt Entity
---@param duration integer
---@param unknown1 integer
---@param unknown2 integer
function TaskLookAtEntity(ped, lookAt, duration, unknown1, unknown2) end

---@param ped Ped
---@param task string
---@param multiplier number
---@param p3 boolean
---@param animDict string
---@param flags integer
function TaskMoveNetwork(ped, task, multiplier, p3, animDict, flags) end

---@param ped Ped
---@param p1 string
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 unknown
---@param p9 number
---@param p10 boolean
---@param animDict string
---@param flags integer
function TaskMoveNetworkAdvanced(ped, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, animDict, flags) end

---@param ped Ped
---@param p1 string
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 number
---@param p6 number
---@param p7 number
---@param p8 unknown
---@param p9 number
---@param p10 boolean
---@param animDict string
---@param flags integer
function TaskMoveNetworkAdvancedByName(ped, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, animDict, flags) end

---@param ped Ped
---@param task string
---@param multiplier number
---@param p3 boolean
---@param animDict string
---@param flags integer
function TaskMoveNetworkByName(ped, task, multiplier, p3, animDict, flags) end

---@param ped Ped
---@param p1 string
---@param p3 number
---@param p4 boolean
---@param animDict string
---@param flags integer
---@return unknown data
function TaskMoveNetworkByNameWithInitParams(ped, p1, p3, p4, animDict, flags) end

---@param ped Ped
---@param p1 string
---@param p3 number
---@param p4 boolean
---@param animDict string
---@param flags integer
---@return unknown data
function TaskMoveNetworkScripted(ped, p1, p3, p4, animDict, flags) end

---@param ped Ped
---@param vehicle integer
---@param timeOut integer
---@param seat integer
---@param speed number
function TaskOpenVehicleDoor(ped, vehicle, timeOut, seat, speed) end

---@param ped Ped
---@param p1 boolean
function TaskParachute(ped, p1) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
function TaskParachuteToTarget(ped, x, y, z) end

---@param ped Ped
---@param p1 string
---@param p2 unknown
---@param p3 boolean
---@param p4 boolean
function TaskPatrol(ped, p1, p2, p3, p4) end

---@param ped Ped
---@param ms integer
function TaskPause(ped, ms) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param heading number
---@param duration number
function TaskPedSlideToCoord(ped, x, y, z, heading, duration) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param heading number
---@param p5 number
---@param p6 number
function TaskPedSlideToCoordHdgRate(ped, x, y, z, heading, p5, p6) end

---@param ped Ped
---@param taskSequenceId integer
function TaskPerformSequence(ped, taskSequenceId) end

---@param ped Ped
---@param taskIndex integer
---@param progress1 integer
---@param progress2 integer
function TaskPerformSequenceFromProgress(ped, taskIndex, progress1, progress2) end

---@param ped Ped
---@param taskSequenceId integer
function TaskPerformSequenceLocally(ped, taskSequenceId) end

---@param pilot Ped
---@param entityToFollow Entity
---@param x number
---@param y number
---@param z number
function TaskPlaneChase(pilot, entityToFollow, x, y, z) end

---@param ped Ped
---@param vehicle integer
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@param p6 unknown
---@param p7 unknown
---@param p8 unknown
---@param p9 unknown
function TaskPlaneGotoPreciseVtol(ped, vehicle, p2, p3, p4, p5, p6, p7, p8, p9) end

---@param pilot Ped
---@param plane integer
---@param runwayStartX number
---@param runwayStartY number
---@param runwayStartZ number
---@param runwayEndX number
---@param runwayEndY number
---@param runwayEndZ number
function TaskPlaneLand(pilot, plane, runwayStartX, runwayStartY, runwayStartZ, runwayEndX, runwayEndY, runwayEndZ) end

---@param pilot Ped
---@param aircraft integer
---@param targetVehicle integer
---@param targetPed Ped
---@param destinationX number
---@param destinationY number
---@param destinationZ number
---@param missionFlag integer
---@param angularDrag number
---@param unk number
---@param targetHeading number
---@param maxZ number
---@param minZ number
function TaskPlaneMission(pilot, aircraft, targetVehicle, targetPed, destinationX, destinationY, destinationZ, missionFlag, angularDrag, unk, targetHeading, maxZ, minZ) end

---@param pilot Ped
---@param aircraft integer
---@param xPos number
---@param yPos number
---@param zPos number
---@param fCruiseSpeed number
---@param fTargetReachedDist number
function TaskPlaneTaxi(pilot, aircraft, xPos, yPos, zPos, fCruiseSpeed, fTargetReachedDist) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param heading number
function TaskPlantBomb(ped, x, y, z, heading) end

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
---@param animDict string
---@param animation string
---@param boneMaskType string
---@param p4 number
---@param p5 number
---@param p6 boolean
---@param p7 boolean
function TaskPlayPhoneGestureAnimation(ped, animDict, animation, boneMaskType, p4, p5, p6, p7) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param timeout unknown
---@param p5 boolean
---@param p6 number
---@param p7 boolean
---@param p8 boolean
---@param p9 unknown
---@param p10 boolean
function TaskPutPedDirectlyIntoCover(ped, x, y, z, timeout, p5, p6, p7, p8, p9, p10) end

---@param ped Ped
---@param meleeTarget Ped
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 boolean
function TaskPutPedDirectlyIntoMelee(ped, meleeTarget, p2, p3, p4, p5) end

---@param ped Ped
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param minZ number
---@param ropeId integer
---@param clipset string
---@param p10 unknown
function TaskRappelDownWall(ped, x1, y1, z1, x2, y2, z2, minZ, ropeId, clipset, p10) end

---@param ped Ped
---@param unused number
function TaskRappelFromHeli(ped, unused) end

---@param ped Ped
---@param fleeTarget Ped
function TaskReactAndFleePed(ped, fleeTarget) end

---@param ped Ped
---@param unused boolean
function TaskReloadWeapon(ped, unused) end

---@param ped Ped
---@param p4 number
---@param p5 number
---@return unknown p1
---@return unknown p2
---@return unknown p3
function TaskScriptedAnimation(ped, p4, p5) end

---@param ped Ped
---@param target Ped
---@param duration integer
---@param p3 boolean
function TaskSeekCoverFromPed(ped, target, duration, p3) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param duration integer
---@param p5 boolean
function TaskSeekCoverFromPos(ped, x, y, z, duration, p5) end

---@param ped Ped
---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param p7 unknown
---@param p8 boolean
function TaskSeekCoverToCoords(ped, x1, y1, z1, x2, y2, z2, p7, p8) end

---@param p0 unknown
---@param p1 unknown
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 unknown
---@param p6 boolean
function TaskSeekCoverToCoverPoint(p0, p1, p2, p3, p4, p5, p6) end

---@param ped Ped
---@param toggle boolean
function TaskSetBlockingOfNonTemporaryEvents(ped, toggle) end

---@param ped Ped
---@param p1 Hash|string
function TaskSetDecisionMaker(ped, p1) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
function TaskSetSphereDefensiveArea(p0, p1, p2, p3, p4) end

---@param ped Ped
---@param eventHandle integer
function TaskShockingEventReact(ped, eventHandle) end

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
function TaskShuffleToNextVehicleSeat(ped, vehicle) end

---@param ped Ped
function TaskSkyDive(ped) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param distance number
---@param time integer
---@param p6 boolean
---@param p7 boolean
function TaskSmartFleeCoord(ped, x, y, z, distance, time, p6, p7) end

---@param ped Ped
---@param fleeTarget Ped
---@param distance number
---@param fleeTime unknown
---@param p4 boolean
---@param p5 boolean
function TaskSmartFleePed(ped, fleeTarget, distance, fleeTime, p4, p5) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param heading number
---@param scenarioName string
function TaskStandGuard(ped, x, y, z, heading, scenarioName) end

---@param ped Ped
---@param time integer
function TaskStandStill(ped, time) end

---@param ped Ped
---@param scenarioName string
---@param x number
---@param y number
---@param z number
---@param heading number
---@param timeToLeave integer
---@param playIntro boolean
---@param warp boolean
function TaskStartScenarioAtPosition(ped, scenarioName, x, y, z, heading, timeToLeave, playIntro, warp) end

---@param ped Ped
---@param scenarioName string
---@param timeToLeave integer
---@param playIntroClip boolean
function TaskStartScenarioInPlace(ped, scenarioName, timeToLeave, playIntroClip) end

---@param ped Ped
function TaskStayInCover(ped) end

---@param killer Ped
---@param target Ped
---@param actionType Hash|string
---@param p3 number
---@param p4 unknown
function TaskStealthKill(killer, target, actionType, p3, p4) end

---@param ped Ped
function TaskStopPhoneGestureAnimation(ped) end

---@param p0 unknown
---@param submarine integer
---@param x number
---@param y number
---@param z number
---@param p5 unknown
function TaskSubmarineGotoAndStop(p0, submarine, x, y, z, p5) end

---@param ped Ped
---@param p1 boolean
function TaskSwapWeapon(ped, p1) end

---@param ped Ped
---@param anim string
---@param p2 string
---@param p3 string
---@param p4 string
---@param p5 integer
---@param vehicle integer
---@param p7 number
---@param p8 number
function TaskSweepAimEntity(ped, anim, p2, p3, p4, p5, vehicle, p7, p8) end

---@param p0 unknown
---@param p5 unknown
---@param p6 number
---@param p7 number
---@param p8 number
---@param p9 number
---@param p10 number
---@return unknown p1
---@return unknown p2
---@return unknown p3
---@return unknown p4
function TaskSweepAimPosition(p0, p5, p6, p7, p8, p9, p10) end

---@param ped Ped
---@param scene integer
---@param animDictionary string
---@param animationName string
---@param speed number
---@param speedMultiplier number
---@param duration integer
---@param flag integer
---@param playbackRate number
---@param p9 unknown
function TaskSynchronizedScene(ped, scene, animDictionary, animationName, speed, speedMultiplier, duration, flag, playbackRate, p9) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
function TaskThrowProjectile(ped, x, y, z) end

---@param p0 boolean
---@param p1 boolean
function TaskToggleDuck(p0, p1) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param duration integer
function TaskTurnPedToFaceCoord(ped, x, y, z, duration) end

---@param ped Ped
---@param entity Entity
---@param duration integer
function TaskTurnPedToFaceEntity(ped, entity, duration) end

---@param ped Ped
---@param p1 integer
function TaskUseMobilePhone(ped, p1) end

---@param ped Ped
---@param duration integer
function TaskUseMobilePhoneTimed(ped, duration) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 unknown
function TaskUseNearestScenarioChainToCoord(p0, p1, p2, p3, p4, p5) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 unknown
function TaskUseNearestScenarioChainToCoordWarp(p0, p1, p2, p3, p4, p5) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param distance number
---@param duration integer
function TaskUseNearestScenarioToCoord(ped, x, y, z, distance, duration) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param radius number
---@param p5 unknown
function TaskUseNearestScenarioToCoordWarp(ped, x, y, z, radius, p5) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
function TaskVehicleAimAtCoord(ped, x, y, z) end

---@param ped Ped
---@param target Ped
function TaskVehicleAimAtPed(ped, target) end

---@param driver Ped
---@param targetEnt Entity
function TaskVehicleChase(driver, targetEnt) end

---@param ped Ped
---@param vehicle integer
---@param x number
---@param y number
---@param z number
---@param speed number
---@param p6 unknown
---@param vehicleModel Hash|string
---@param drivingMode integer
---@param stopRange number
---@param p10 number
function TaskVehicleDriveToCoord(ped, vehicle, x, y, z, speed, p6, vehicleModel, drivingMode, stopRange, p10) end

---@param ped Ped
---@param vehicle integer
---@param x number
---@param y number
---@param z number
---@param speed number
---@param drivingStyle integer
---@param stopRange number
function TaskVehicleDriveToCoordLongrange(ped, vehicle, x, y, z, speed, drivingStyle, stopRange) end

---@param ped Ped
---@param vehicle integer
---@param speed number
---@param drivingStyle integer
function TaskVehicleDriveWander(ped, vehicle, speed, drivingStyle) end

---@param ped Ped
---@param vehicle integer
---@param targetVehicle integer
---@param mode integer
---@param speed number
---@param drivingStyle integer
---@param minDistance number
---@param p7 integer
---@param noRoadsDistance number
function TaskVehicleEscort(ped, vehicle, targetVehicle, mode, speed, drivingStyle, minDistance, p7, noRoadsDistance) end

---@param driver Ped
---@param vehicle integer
---@param targetEntity Entity
---@param speed number
---@param drivingStyle integer
---@param minDistance integer
function TaskVehicleFollow(driver, vehicle, targetEntity, speed, drivingStyle, minDistance) end

---@param ped Ped
---@param vehicle integer
---@param WPRecording string
---@param p3 integer
---@param p4 integer
---@param p5 integer
---@param p6 integer
---@param p7 number
---@param p8 boolean
---@param p9 number
function TaskVehicleFollowWaypointRecording(ped, vehicle, WPRecording, p3, p4, p5, p6, p7, p8, p9) end

---@param ped Ped
---@param vehicle integer
---@param x number
---@param y number
---@param z number
---@param speed number
---@param behaviorFlag integer
---@param stoppingRange number
function TaskVehicleGotoNavmesh(ped, vehicle, x, y, z, speed, behaviorFlag, stoppingRange) end

---@param pilot Ped
---@param vehicle integer
---@param entityToFollow Entity
---@param targetSpeed number
---@param p4 integer
---@param radius number
---@param altitude integer
---@param p7 integer
function TaskVehicleHeliProtect(pilot, vehicle, entityToFollow, targetSpeed, p4, radius, altitude, p7) end

---@param ped Ped
---@param vehicle integer
---@param vehicleTarget integer
---@param missionType integer
---@param speed number
---@param drivingStyle integer
---@param radius number
---@param straightLineDist number
---@param DriveAgainstTraffic boolean
function TaskVehicleMission(ped, vehicle, vehicleTarget, missionType, speed, drivingStyle, radius, straightLineDist, DriveAgainstTraffic) end

---@param ped Ped
---@param vehicle integer
---@param x number
---@param y number
---@param z number
---@param missionType integer
---@param speed number
---@param drivingStyle integer
---@param radius number
---@param straightLineDist number
---@param DriveAgainstTraffic boolean
function TaskVehicleMissionCoorsTarget(ped, vehicle, x, y, z, missionType, speed, drivingStyle, radius, straightLineDist, DriveAgainstTraffic) end

---@param ped Ped
---@param vehicle integer
---@param pedTarget Ped
---@param missionType integer
---@param speed number
---@param drivingStyle integer
---@param radius number
---@param straightLineDist number
---@param DriveAgainstTraffic boolean
function TaskVehicleMissionPedTarget(ped, vehicle, pedTarget, missionType, speed, drivingStyle, radius, straightLineDist, DriveAgainstTraffic) end

---@param ped Ped
---@param vehicle integer
---@param x number
---@param y number
---@param z number
---@param heading number
---@param mode integer
---@param radius number
---@param keepEngineOn boolean
function TaskVehiclePark(ped, vehicle, x, y, z, heading, mode, radius, keepEngineOn) end

---@param vehicle integer
---@param animationSet string
---@param animationName string
function TaskVehiclePlayAnim(vehicle, animationSet, animationName) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param p4 number
function TaskVehicleShootAtCoord(ped, x, y, z, p4) end

---@param ped Ped
---@param target Ped
---@param p2 number
function TaskVehicleShootAtPed(ped, target, p2) end

---@param driver Ped
---@param vehicle integer
---@param action integer
---@param time integer
function TaskVehicleTempAction(driver, vehicle, action, time) end

---@param ped Ped
---@param x number
---@param y number
---@param z number
---@param radius number
---@param minimalLength integer
---@param timeBetweenWalks number
function TaskWanderInArea(ped, x, y, z, radius, minimalLength, timeBetweenWalks) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
function TaskWanderSpecific(p0, p1, p2, p3) end

---@param ped Ped
---@param p1 number
---@param p2 integer
function TaskWanderStandard(ped, p1, p2) end

---@param ped Ped
---@param time integer
---@param canPeekAndAim boolean
---@param forceInitialFacingDirection boolean
---@param forceFaceLeft boolean
---@param coverIndex integer
function TaskWarpPedDirectlyIntoCover(ped, time, canPeekAndAim, forceInitialFacingDirection, forceFaceLeft, coverIndex) end

---@param ped Ped
---@param vehicle integer
---@param seatIndex integer
function TaskWarpPedIntoVehicle(ped, vehicle, seatIndex) end

---@param ped Ped
---@param target Ped
---@param time integer
---@param p3 integer
function TaskWrithe(ped, target, time, p3) end

---@param scriptName string
function TerminateAllScriptsWithThisName(scriptName) end

function TerminateThisThread() end

---@param threadId integer
function TerminateThread(threadId) end

---@param toggle boolean
function TerraingridActivate(toggle) end

---@param lowR integer
---@param lowG integer
---@param lowB integer
---@param lowAlpha integer
---@param R integer
---@param G integer
---@param B integer
---@param Alpha integer
---@param highR integer
---@param highG integer
---@param highB integer
---@param highAlpha integer
function TerraingridSetColours(lowR, lowG, lowB, lowAlpha, R, G, B, Alpha, highR, highG, highB, highAlpha) end

---@param x number
---@param y number
---@param z number
---@param p3 number
---@param rotation number
---@param p5 number
---@param width number
---@param height number
---@param p8 number
---@param scale number
---@param glowIntensity number
---@param normalHeight number
---@param heightDiff number
function TerraingridSetParams(x, y, z, p3, rotation, p5, width, height, p8, scale, glowIntensity, normalHeight, heightDiff) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@param flag integer
---@return boolean
---@return vector3 result
function TestProbeAgainstAllWater(x1, y1, z1, x2, y2, z2, flag) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return boolean
---@return vector3 result
function TestProbeAgainstWater(x1, y1, z1, x2, y2, z2) end

---@param x number
---@param y number
---@param z number
---@param flag integer
---@return boolean
---@return number height
function TestVerticalProbeAgainstAllWater(x, y, z, flag) end

---@param p0 integer
---@return string
function TextureDownloadGetName(p0) end

---@param p0 integer
---@return boolean
function TextureDownloadHasFailed(p0) end

---@param p0 integer
function TextureDownloadRelease(p0) end

---@param FilePath string
---@param Name string
---@param p3 boolean
---@return integer
---@return integer PlayerHandle
function TextureDownloadRequest(FilePath, Name, p3) end

---@param txdString1 string
---@param txnString1 string
---@param txdString2 string
---@param txnString2 string
function ThefeedAddTxdRef(txdString1, txnString1, txdString2, txnString2) end

function ThefeedClearAnimpostfx() end

function ThefeedClearFrozenPost() end

function ThefeedCommentTeleportPoolOff() end

function ThefeedCommentTeleportPoolOn() end

function ThefeedDisable() end

function ThefeedDisableBaselineOffset() end

function ThefeedDisableLoadingScreenTips() end

function ThefeedDisplayLoadingScreenTips() end

function ThefeedEnable() end

function ThefeedEnableBaselineOffset() end

function ThefeedFlushPersistent() end

function ThefeedFlushQueue() end

function ThefeedForceRenderOff() end

function ThefeedForceRenderOn() end

function ThefeedFreezeNextPost() end

---@return integer
function ThefeedGetCurrentNotification() end

---@return integer
function ThefeedGetFirstVisibleDeleteRemaining() end

function ThefeedHideGtaoTooltips() end

function ThefeedHideThisFrame() end

---@return boolean
function ThefeedIsPaused() end

---@param hudColorIndex integer
function ThefeedNextPostBackgroundColor(hudColorIndex) end

---@param toggle boolean
function ThefeedOnlyShowTooltips(toggle) end

function ThefeedPause() end

---@param notificationId integer
function ThefeedRemoveItem(notificationId) end

function ThefeedResetAllParameters() end

function ThefeedResume() end

---@param red integer
---@param green integer
---@param blue integer
---@param alpha integer
function ThefeedSetAnimpostfxColor(red, green, blue, alpha) end

---@param count integer
function ThefeedSetAnimpostfxCount(count) end

---@param toggle boolean
function ThefeedSetAnimpostfxSound(toggle) end

---@param toggle boolean
function ThefeedSetFlushAnimpostfx(toggle) end

---@param hudColorIndex integer
function ThefeedSetNextPostBackgroundColor(hudColorIndex) end

function ThefeedSetNextPostPersistent() end

---@param pos number
function ThefeedSetScriptedMenuHeight(pos) end

function ThefeedShowGtaoTooltips() end

function ThefeedSpsExtendWidescreenOff() end

function ThefeedSpsExtendWidescreenOn() end

---@param txdString1 string
---@param txnString1 string
---@param txdString2 string
---@param txnString2 string
function ThefeedUpdateItemTexture(txdString1, txnString1, txdString2, txnString2) end

---@return integer
function Timera() end

---@return integer
function Timerb() end

---@return number
function Timestep() end

---@param FilePath string
---@param Name string
---@param p2 boolean
---@return integer
function TitleTextureDownloadRequest(FilePath, Name, p2) end

---@param value integer
---@return number
function ToFloat(value) end

---@param toggle boolean
function TogglePausedRenderphases(toggle) end

---@param toggle boolean
function ToggleShowOptionalStuntJumpCamera(toggle) end

---@param toggle boolean
function ToggleStealthRadar(toggle) end

---@param player integer
---@param pickupHash Hash|string
---@param toggle boolean
function ToggleUsePickupsForPlayer(player, pickupHash, toggle) end

---@param vehicle integer
---@param modType integer
---@param toggle boolean
function ToggleVehicleMod(vehicle, modType, toggle) end

---@param object integer
function TrackObjectVisibility(object) end

---@param vehicle integer
function TrackVehicleVisibility(vehicle) end

---@param vehicle integer
---@param instantly boolean
function TransformStormbergToRoadVehicle(vehicle, instantly) end

---@param vehicle integer
---@param instantly boolean
function TransformStormbergToWaterVehicle(vehicle, instantly) end

---@param vehicle integer
---@param instantly boolean
function TransformSubmarineToVehicle(vehicle, instantly) end

---@param vehicle integer
---@param instantly boolean
function TransformToCar(vehicle, instantly) end

---@param vehicle integer
---@param instantly boolean
function TransformToSubmarine(vehicle, instantly) end

---@param vehicle integer
---@param instantly boolean
function TransformVehicleToSubmarine(vehicle, instantly) end

---@param transitionTime number
---@return boolean
function TransitionFromBlurred(transitionTime) end

---@param transitionTime number
---@return boolean
function TransitionToBlurred(transitionTime) end

---@param eventName string
---@return boolean
function TriggerMusicEvent(eventName) end

---@param transitionTime number
---@return boolean
function TriggerScreenblurFadeIn(transitionTime) end

---@param transitionTime number
---@return boolean
function TriggerScreenblurFadeOut(transitionTime) end

---@param player integer
---@param p1 integer
---@param scriptHash Hash|string
---@return boolean
function TriggerScriptCrcCheckOnPlayer(player, p1, scriptHash) end

---@param eventGroup integer
---@param eventDataSize integer
---@param playerBits integer
---@return integer eventData
function TriggerScriptEvent(eventGroup, eventDataSize, playerBits) end

---@param eventGroup integer
---@param eventDataSize integer
---@param playerBits integer
---@return integer eventData
function TriggerScriptEvent_2(eventGroup, eventDataSize, playerBits) end

---@param vehicle integer
function TriggerSiren(vehicle) end

---@param posX number
---@param posY number
---@param posZ number
---@param radius number
---@param p4 integer
function TriggerSonarBlip(posX, posY, posZ, radius, p4) end

function UgcCancelQuery() end

function UgcClearCreateResult() end

function UgcClearModifyResult() end

function UgcClearOfflineQuery() end

function UgcClearQueryResults() end

---@return boolean
---@return unknown p0
---@return unknown p1
function UgcCopyContent() end

---@param data string
---@param dataCount integer
---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@param publish boolean
---@return boolean
function UgcCreateContent(data, dataCount, contentName, description, tagsCsv, contentTypeName, publish) end

---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@param publish boolean
---@return boolean
function UgcCreateMission(contentName, description, tagsCsv, contentTypeName, publish) end

---@return unknown
function UgcDidGetSucceed() end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function UgcGetBookmarkedContent(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@return string
function UgcGetCachedDescription(p0, p1) end

---@param p0 integer
---@param p1 integer
---@return string
function UgcGetCloudPath(p0, p1) end

---@param p0 integer
---@return integer
function UgcGetContentCategory(p0) end

---@param p0 unknown
---@return integer
function UgcGetContentDescriptionHash(p0) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function UgcGetContentFileVersion(p0, p1) end

---@return Hash
function UgcGetContentHash() end

---@param p0 unknown
---@return boolean
function UgcGetContentHasPlayerBookmarked(p0) end

---@param p0 unknown
---@return boolean
function UgcGetContentHasPlayerRecord(p0) end

---@param p0 integer
---@return string
function UgcGetContentId(p0) end

---@param p0 unknown
---@return boolean
function UgcGetContentIsPublished(p0) end

---@param p0 unknown
---@return boolean
function UgcGetContentIsVerified(p0) end

---@param p0 unknown
---@return unknown
function UgcGetContentLanguage(p0) end

---@param p0 unknown
---@return string
function UgcGetContentName(p0) end

---@return unknown
function UgcGetContentNum() end

---@param p0 integer
---@param p1 integer
---@return string
function UgcGetContentPath(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function UgcGetContentRating(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function UgcGetContentRatingCount(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function UgcGetContentRatingNegativeCount(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@return unknown
function UgcGetContentRatingPositiveCount(p0, p1) end

---@return unknown
function UgcGetContentTotal() end

---@param p0 unknown
---@return unknown p1
function UgcGetContentUpdatedDate(p0) end

---@param p0 integer
---@return string
function UgcGetContentUserId(p0) end

---@param p0 unknown
---@return string
function UgcGetContentUserName(p0) end

---@return string
function UgcGetCreateContentId() end

---@return unknown
function UgcGetCreateResult() end

---@return unknown
function UgcGetCreatorNum() end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return boolean
---@return unknown p3
---@return unknown p4
function UgcGetCrewContent(p0, p1, p2) end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function UgcGetFriendContent(p0, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@return boolean
---@return unknown p3
---@return unknown p4
function UgcGetGetByCategory(p0, p1, p2) end

---@return unknown
function UgcGetModifyResult() end

---@param p0 unknown
---@param p1 unknown
---@return boolean
---@return unknown p2
---@return unknown p3
function UgcGetMyContent(p0, p1) end

---@return unknown
function UgcGetQueryResult() end

---@param p0 integer
---@return string
function UgcGetRootContentId(p0) end

---@return boolean
function UgcHasCreateFinished() end

---@return boolean
function UgcHasGetFinished() end

---@return boolean
function UgcHasModifyFinished() end

---@return boolean
function UgcIsGetting() end

---@param p0 unknown
---@return boolean
function UgcIsLanguageSupported(p0) end

---@param p0 unknown
---@return boolean
function UgcPoliciesMakePrivate(p0) end

---@param contentId string
---@param baseContentId string
---@param contentTypeName string
---@return boolean
function UgcPublish(contentId, baseContentId, contentTypeName) end

---@param contentId string
---@param latestVersion boolean
---@param contentTypeName string
---@return boolean
function UgcQueryByContentId(contentId, latestVersion, contentTypeName) end

---@param count integer
---@param latestVersion boolean
---@param contentTypeName string
---@return boolean
---@return unknown data
function UgcQueryByContentIds(count, latestVersion, contentTypeName) end

---@param p0 unknown
---@param p1 unknown
---@param p3 unknown
---@param p4 unknown
---@param p5 unknown
---@return boolean
---@return unknown p2
function UgcQueryMyContent(p0, p1, p3, p4, p5) end

---@param offset integer
---@param count integer
---@param contentTypeName string
---@param p3 integer
---@return boolean
function UgcQueryRecentlyCreatedContent(offset, count, contentTypeName, p3) end

---@param p0 integer
---@return integer
function UgcRequestCachedDescription(p0) end

---@param p0 integer
---@param p1 integer
---@return integer
function UgcRequestContentDataFromIndex(p0, p1) end

---@param contentTypeName string
---@param contentId string
---@param p2 integer
---@param p3 integer
---@param p4 integer
---@return integer
function UgcRequestContentDataFromParams(contentTypeName, contentId, p2, p3, p4) end

---@param contentId string
---@param bookmarked boolean
---@param contentTypeName string
---@return boolean
function UgcSetBookmarked(contentId, bookmarked, contentTypeName) end

---@param p1 boolean
---@return boolean
---@return unknown p0
---@return unknown p2
function UgcSetDeleted(p1) end

---@param contentId string
---@param rating number
---@param contentTypeName string
---@return boolean
function UgcSetPlayerData(contentId, rating, contentTypeName) end

---@param p0 boolean
function UgcSetQueryDataFromOffline(p0) end

---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p5 boolean
---@return unknown
---@return unknown p0
---@return unknown p4
function UgcTextureDownloadRequest(p1, p2, p3, p5) end

---@param contentId string
---@param dataCount integer
---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@return boolean
---@return unknown data
function UgcUpdateContent(contentId, dataCount, contentName, description, tagsCsv, contentTypeName) end

---@param contentId string
---@param contentName string
---@param description string
---@param tagsCsv string
---@param contentTypeName string
---@return boolean
function UgcUpdateMission(contentId, contentName, description, tagsCsv, contentTypeName) end

---@return boolean
function Ui3dsceneIsAvailable() end

---@param presetName string
---@return boolean
function Ui3dscenePushPreset(presetName) end

---@return boolean
function UiIsSingleplayerPauseMenuActive() end

---@return boolean
function UiStartedEndUserBenchmark() end

---@param name Hash|string
---@param eventType integer
function UnblockDecisionMakerEvent(name, eventType) end

---@param groupName string
function UnblockSpeechContextGroup(groupName) end

---@param ped Ped
function UncuffPed(ped) end

---@param decalType integer
function UndoDecalTextureOverride(decalType) end

---@param radioStation string
function UnfreezeRadioStation(radioStation) end

---@param x number
---@param y number
---@param z number
---@param typeHash Hash|string
---@return integer
function UnkGetInteriorAtCoords(x, y, z, typeHash) end

---@param name string
---@param p1 number
function UnloadCloudHat(name, p1) end

---@param hash Hash|string
function UnloadContentChangeSetGroup(hash) end

function UnlockMinimapAngle() end

function UnlockMinimapPosition() end

---@param newsStory integer
function UnlockMissionNewsStory(newsStory) end

---@param radioStation string
---@param trackListName string
function UnlockRadioStationTrackList(radioStation, trackListName) end

---@param decalType integer
function UnpatchDecalDiffuseMap(decalType) end

---@param vehicle integer
function UnpausePlaybackRecordedVehicle(vehicle) end

---@param interior integer
function UnpinInterior(interior) end

---@param ropeId integer
---@param vertex integer
function UnpinRopeVertex(ropeId, vertex) end

---@param id integer
function UnregisterPedheadshot(id) end

function UnregisterScriptWithAudio() end

function UnrequestTennisBanks() end

---@param entity Entity
function UpdateLightsOnEntity(entity) end

---@param allowTrackReprioritization boolean
function UpdateLsur(allowTrackReprioritization) end

---@param mapdata integer
---@param entity integer
---@param entityDef table
function UpdateMapdataEntity(mapdata, entity, entityDef) end

---@param object integer
---@param posX number
---@param posY number
---@param posZ number
---@param scaleX number
---@param scaleY number
---@param scaleZ number
---@param heading number
---@param flags integer
function UpdateNavmeshBlockingObject(object, posX, posY, posZ, scaleX, scaleY, scaleZ, heading, flags) end

---@return integer
function UpdateOnscreenKeyboard() end

---@param ped Ped
---@param shapeMix number
---@param skinMix number
---@param thirdMix number
function UpdatePedHeadBlendData(ped, shapeMix, skinMix, thirdMix) end

---@param player integer
---@return boolean
function UpdatePlayerTeleport(player) end

---@param soundId integer
---@param x number
---@param y number
---@param z number
function UpdateSoundCoord(soundId, x, y, z) end

---@param statHash Hash|string
---@param value number
---@param p2 integer
function UpdateStatFloat(statHash, value, p2) end

---@param statHash Hash|string
---@param value integer
---@param p2 integer
function UpdateStatInt(statHash, value, p2) end

---@param p0 Ped
---@param p1 Ped
---@param p2 number
---@param p3 number
---@param p4 number
---@param p5 boolean
function UpdateTaskAimGunScriptedTarget(p0, p1, p2, p3, p4, p5) end

---@param ped Ped
---@param duration integer
function UpdateTaskHandsUpDuration(ped, duration) end

---@param ped Ped
---@param entity Entity
function UpdateTaskSweepAimEntity(ped, entity) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
function UpdateTaskSweepAimPosition(p0, p1, p2, p3) end

---@param allowTrackReprioritization boolean
function UpdateUnlockableDjRadioTracks(allowTrackReprioritization) end

---@param p0 boolean
function UseFakeMpCash(p0) end

---@param ped Ped
---@param useSweetner boolean
---@param soundSetHash Hash|string
function UseFootstepScriptSweeteners(ped, useSweetner, soundSetHash) end

---@param toggle integer
function UseFreemodeMapBehavior(toggle) end

---@param name string
function UseParticleFxAsset(name) end

---@param name string
function UseParticleFxAssetNextCall(name) end

---@param toggle boolean
function UsePlayerColourInsteadOfTeamColour(toggle) end

---@param vehicles boolean
---@param peds boolean
function UseScriptCamForAmbientPopulationOriginThisFrame(vehicles, peds) end

---@param vehicle integer
---@param sirenAsHorn boolean
function UseSirenAsHorn(vehicle, sirenAsHorn) end

function UseStuntCameraThisFrame() end

function UseVehicleCamStuntSettingsThisUpdate() end

---@param name string
---@param p1 boolean
---@param p2 number
---@param p3 number
function UseWaypointRecordingAsAssistedMovementRoute(name, p1, p2, p3) end

---@param toggle boolean
function UsingMissionCreator(toggle) end

---@param p0 integer
---@return boolean
function UsingNetworkWeapontype(p0) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function Vdist(x1, y1, z1, x2, y2, z2) end

---@param x1 number
---@param y1 number
---@param z1 number
---@param x2 number
---@param y2 number
---@param z2 number
---@return number
function Vdist2(x1, y1, z1, x2, y2, z2) end

---@param plane integer
---@return boolean
function VehicleHasLandingGear(plane) end

---@param vehicle integer
---@param modelHash Hash|string
function VehicleSetCustomParachuteModel(vehicle, modelHash) end

---@param vehicle integer
---@param textureVariation integer
function VehicleSetCustomParachuteTexture(vehicle, textureVariation) end

---@param vehicle integer
---@param speed number
function VehicleWaypointPlaybackOverrideSpeed(vehicle, speed) end

---@param vehicle integer
function VehicleWaypointPlaybackPause(vehicle) end

---@param vehicle integer
function VehicleWaypointPlaybackResume(vehicle) end

---@param vehicle integer
function VehicleWaypointPlaybackUseDefaultSpeed(vehicle) end

---@param vehicle integer
---@return integer
function VehToNet(vehicle) end

---@param x number
---@param y number
---@param z number
---@return number
function Vmag(x, y, z) end

---@param x number
---@param y number
---@param z number
---@return number
function Vmag2(x, y, z) end

---@param heli integer
---@param toggle boolean
function WasCounterActivated(heli, toggle) end

---@return boolean
function WasCutsceneSkipped() end

---@param vehicle integer
---@param p1 number
function WashDecalsFromVehicle(vehicle, p1) end

---@param p0 unknown
---@param p1 unknown
---@param p2 unknown
---@param p3 unknown
---@param p4 unknown
function WashDecalsInRange(p0, p1, p2, p3, p4) end

---@param ped Ped
---@return boolean
function WasPedKilledByStealth(ped) end

---@param ped Ped
---@return boolean
function WasPedKilledByTakedown(ped) end

---@param ped Ped
---@return boolean
function WasPedKnockedOut(ped) end

---@param ped Ped
---@return boolean
function WasPedSkeletonUpdated(ped) end

---@param p0 number
function WaterOverrideFadeIn(p0) end

---@param p0 number
function WaterOverrideFadeOut(p0) end

---@param minAmplitude number
function WaterOverrideSetOceannoiseminamplitude(minAmplitude) end

---@param amplitude number
function WaterOverrideSetOceanwaveamplitude(amplitude) end

---@param maxAmplitude number
function WaterOverrideSetOceanwavemaxamplitude(maxAmplitude) end

---@param minAmplitude number
function WaterOverrideSetOceanwaveminamplitude(minAmplitude) end

---@param bumpiness number
function WaterOverrideSetRipplebumpiness(bumpiness) end

---@param disturb number
function WaterOverrideSetRippledisturb(disturb) end

---@param maxBumpiness number
function WaterOverrideSetRipplemaxbumpiness(maxBumpiness) end

---@param minBumpiness number
function WaterOverrideSetRippleminbumpiness(minBumpiness) end

---@param amplitude number
function WaterOverrideSetShorewaveamplitude(amplitude) end

---@param maxAmplitude number
function WaterOverrideSetShorewavemaxamplitude(maxAmplitude) end

---@param minAmplitude number
function WaterOverrideSetShorewaveminamplitude(minAmplitude) end

---@param strength number
function WaterOverrideSetStrength(strength) end

---@param p0 unknown
---@return boolean
function WaypointPlaybackGetIsPaused(p0) end

---@param p0 unknown
---@param p1 number
---@param p2 boolean
function WaypointPlaybackOverrideSpeed(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 boolean
function WaypointPlaybackPause(p0, p1, p2) end

---@param p0 unknown
---@param p1 boolean
---@param p2 unknown
---@param p3 unknown
function WaypointPlaybackResume(p0, p1, p2, p3) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 boolean
function WaypointPlaybackStartAimingAtCoord(p0, p1, p2, p3, p4) end

---@param p0 unknown
---@param p1 unknown
---@param p2 boolean
function WaypointPlaybackStartAimingAtPed(p0, p1, p2) end

---@param p0 unknown
---@param p1 number
---@param p2 number
---@param p3 number
---@param p4 boolean
---@param p5 unknown
function WaypointPlaybackStartShootingAtCoord(p0, p1, p2, p3, p4, p5) end

---@param p0 unknown
---@param p1 unknown
---@param p2 boolean
---@param p3 unknown
function WaypointPlaybackStartShootingAtPed(p0, p1, p2, p3) end

---@param p0 unknown
function WaypointPlaybackStopAimingOrShooting(p0) end

---@param p0 unknown
function WaypointPlaybackUseDefaultSpeed(p0) end

---@param name string
---@param x number
---@param y number
---@param z number
---@return boolean
---@return integer point
function WaypointRecordingGetClosestWaypoint(name, x, y, z) end

---@param name string
---@param point integer
---@return boolean
---@return vector3 coord
function WaypointRecordingGetCoord(name, point) end

---@param name string
---@return boolean
---@return integer points
function WaypointRecordingGetNumPoints(name) end

---@param name string
---@param point integer
---@return number
function WaypointRecordingGetSpeedAtPoint(name, point) end

---@param amount integer
---@return integer
function WithdrawVc(amount) end

---@param worldX number
---@param worldY number
---@param worldZ number
---@return boolean
---@return number screenX
---@return number screenY
function World3dToScreen2d(worldX, worldY, worldZ) end

---@param entityModelHash Hash|string
---@param x number
---@param y number
---@param z number
---@param p4 boolean
---@return boolean
function WouldEntityBeOccluded(entityModelHash, x, y, z, p4) end
