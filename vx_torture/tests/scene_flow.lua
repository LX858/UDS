-- Tests use the real config and implementation files. Natives below simulate
-- lifecycle/phase only, not GTA clip geometry or OneSync replication.
local vecmt = {}
function vector3(x, y, z) return setmetatable({ x = x, y = y, z = z }, vecmt) end
vecmt.__sub = function(a, b) return vector3(a.x-b.x, a.y-b.y, a.z-b.z) end
vecmt.__add = function(a, b) return vector3(a.x+b.x, a.y+b.y, a.z+b.z) end
vecmt.__len = function(a) return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end
Locales = { default = {} }
json = { encode = function() return '<mock diagnostic>' end }
function L(key) return key end
local now, nextScene, nextCam = 0, 100, 5000
local scenes, cams, attached, positions, activePed = {}, {}, {}, {}, {}
local activeEntity={}
local handAnims={}
local pedTasks = {}
local advancedTasks, advancedCount = {}, 0
local events, threads, timers, menus, openMenu = {}, {}, {}, {}, nil
local currentPlayer, failCamera, stops, shown, clears = 1, false, 0, 0, 0
local failActorTask, loseActorAt, delayedStops = false, nil, {}
local loseActorAgainAt, failActorRecovery = nil, false
local frozenActorPhase, localHandleDelay = nil, 0
local numericAnimResult=false
local realClipLengths=false
local shortWaterTransitions=false
local retainStoppedSceneState=false
local autoAck = true
local function noop() end
function NewImpl()
  local impl = { handlers = {}, intervals = {} }
  function impl:OnNet(name, fn) self.handlers[name] = fn end
  function impl:EmitNet(target, name, ...)
    local args={...}; events[#events+1] = { name = name, args = args }
    if self.isClient and autoAck and name=='bindVictimScene' then
      self.handlers.victimSceneReady(args[2],args[3],args[4],args[5],true)
    end
  end
  function impl:Interval(name, ms, fn) self.intervals[name] = fn end
  function impl:RegisterCallback() end
  function impl:AddEventHandler() end
  function impl:Callback() return {} end
  _G.TEST_IMPL = impl
  return impl
end
lib = {
  notify = noop, getOpenContextMenu = function() return openMenu end,
  hideContext = function() openMenu = nil end,
  registerContext = function(menu) menus[menu.id] = menu end,
  showContext = function(id) openMenu = id; shown = shown + 1 end,
}
exports = { ox_target = { addEntity = noop, removeEntity = noop, removeZone = noop,
  addBoxZone = function(_, data) assert(data.debug == false); return 1 end },
  qbx_core = { CreateUseableItem = noop } }
LocalPlayer = { state = {} }
function Player() return { state = {} } end
function PlayerId() return 0 end
function PlayerPedId() return currentPlayer end
function GetPlayerServerId() return currentPlayer end
function GetPlayerFromServerId(id) return id end
function GetPlayerPed(id) return id end
function GetPlayerName(id) return 'player' .. id end
function GetPlayerRoutingBucket() return 0 end
function GetEntityHealth() return 200 end
function IsEntityDead() return false end
function DoesEntityExist(id) return id ~= 0 end
function NetworkDoesNetworkIdExist() return true end
function NetworkDoesEntityExistWithNetworkId() return true end
function NetworkGetEntityFromNetworkId(id) return id end
function NetworkGetNetworkIdFromEntity(id) return id end
function NetworkHasControlOfEntity() return true end
function GetEntityCoords(id) return positions[id] or vector3(0,0,0) end
function SetEntityCoordsNoOffset(id,x,y,z) positions[id] = vector3(x,y,z) end
function GetEntityHeading() return 90 end
function GetEntityModel(id) return id end
function GetModelDimensions() return vector3(-.5,-.4,0),vector3(.5,.4,1) end
function GetOffsetFromEntityInWorldCoords(id,x,y,z) return GetEntityCoords(id)+vector3(x,y,z) end
SetEntityHeading, SetEntityRotation, SetEntityCollision, FreezeEntityPosition = noop,noop,noop,noop
SetEntityNoCollisionEntity, DisableAllControlActions, EnableControlAction = noop,noop,noop
function GetGameTimer() return now end
function Wait(ms)
  now = now + math.max(ms,20)
  -- Model the reported delayed stop: stopping the old scene AFTER assigning
  -- the same ped/props to a successor can erase their tasks on the next tick.
  for _, stop in ipairs(delayedStops) do
    if stop.ped and not stop.retain then
      pedTasks[stop.ped]=nil; activePed[stop.ped]=nil
    end
    for entity in pairs(scenes[stop.scene].tracks) do activeEntity[entity]=nil end
  end
  delayedStops={}
  if loseActorAt and now>=loseActorAt then pedTasks[1]=nil; loseActorAt=nil end
  if loseActorAgainAt and now>=loseActorAgainAt then pedTasks[1]=nil; loseActorAgainAt=nil end
end
function CreateThread(fn) threads[#threads+1] = fn end
function SetTimeout(ms,fn) timers[#timers+1] = fn end
function RegisterCommand() end
function GetGroundZFor_3dCoord() return true,0 end
function DoesAnimDictExist() return true end
function HasAnimDictLoaded() return true end
RequestAnimDict = noop
function GetAnimDuration(dict,clip)
  if FBI3_CLIPS[dict] and not FBI3_CLIPS[dict][clip] then return 0 end
  if shortWaterTransitions and dict=='missfbi3_waterboard' then
    if clip=='waterboard_loop_rag' then return 13.333 end
    if clip=='waterboard_ready_to_loop_player' or clip=='waterboard_ready_to_loop_rag'
      or clip=='waterboard_loop_to_ready_player' then return 0.8 end
  end
  if realClipLengths and dict=='missfbi3_weapon_select' then
    if clip=='waterboard_idle_chair' or clip=='waterboard_idle_victim' then return 13.333 end
    if clip:find('^weapon_select_wrench_') then return 7.433 end
    if clip:find('^weapon_select_electrocute_') then return 8.333 end
    if clip:find('^weapon_select_waterboard_') then return 12.500 end
  end
  if realClipLengths and clip=='pull_tooth_intro_player' then return 6 end
  if realClipLengths and clip=='pull_tooth_intro_pliers' then return 6 end
  return 1
end
-- Deliberately not 180 degrees and not zero translation: detects hard-coded
-- origin/heading assumptions while verifying both peers use the same transform.
function GetAnimInitialOffsetRotation(dict,clip,x,y,z,rx,ry,rz)
  return vector3(0,0,clip == 'waterboard_idle_chair' and (137+rz)%360 or rz)
end
function GetAnimInitialOffsetPosition(dict,clip,x,y,z,rx,ry,rz)
  local r = math.rad(rz)
  local zOffset = clip:find('victim') and 1.05 or .25
  return vector3(x+1.3*math.cos(r)+.4*math.sin(r), y+1.3*math.sin(r)-.4*math.cos(r),z+zOffset)
end
function NetworkCreateSynchronisedScene(x,y,z,rx,ry,rz,order,hold,looped)
  nextScene = nextScene+1
  scenes[nextScene] = { pos=vector3(x,y,z), heading=rz, hold=hold, looped=looped, tracks={} }
  return nextScene
end
function NetworkAddPedToSynchronisedScene(ped,scene,dict,clip,a,b,flags)
  assert(not scenes[scene].started, 'register actor before starting network scene')
  assert((flags & 4)~=0 and (flags & 8)==0,
    'block external interruption without stopping the clock on task replacement')
  local s=scenes[scene]; s.ped=ped; s.dict=dict; s.clip=clip; s.flags=flags
end
function NetworkAddEntityToSynchronisedScene(entity,scene,dict,clip,a,b,flags)
  assert(GetAnimDuration(dict,clip)>0, 'unknown entity clip: '..dict..'/'..clip)
  scenes[scene].tracks[entity] = { dict=dict,clip=clip,flags=flags }
end
function NetworkStartSynchronisedScene(scene)
  local s=scenes[scene]; s.started=now; s.running=true
  s.duration=s.ped and GetAnimDuration(s.dict,s.clip)*1000 or 1
  for entity,track in pairs(s.tracks) do
    s.duration=math.max(s.duration,GetAnimDuration(track.dict,track.clip)*1000)
    activeEntity[entity]=scene
  end
  if s.ped and not failActorTask then activePed[s.ped]=scene; pedTasks[s.ped]={dict=s.dict,clip=s.clip,flags=s.flags} end
end
function NetworkStopSynchronisedScene(scene)
  stops=stops+1
  if not retainStoppedSceneState then scenes[scene].running=false end
  delayedStops[#delayedStops+1]={ped=scenes[scene].ped,scene=scene,retain=retainStoppedSceneState}
end
function NetworkGetLocalSceneFromNetworkId(scene)
  if scenes[scene] and now-scenes[scene].started<localHandleDelay then return -1 end
  return scene+1000
end
local function sceneFor(id) return scenes[id-1000] end
function TaskSynchronizedScene()
  error('do not mix local TaskSynchronizedScene into a running network scene')
end
function SetSynchronizedSceneLooped(id,v) sceneFor(id).looped=v end
function SetSynchronizedSceneHoldLastFrame(id,v) sceneFor(id).hold=v end
function SetSynchronizedSceneRate(id,rate) sceneFor(id).rate=rate end
function IsSynchronizedSceneRunning(id) return sceneFor(id) and sceneFor(id).running end
function GetSynchronizedScenePhase(id)
  local s=sceneFor(id); local phase=(now-s.started)/s.duration
  return s.looped and phase%1 or math.min(1,phase)
end
function IsEntityPlayingAnim(ped,dict,clip)
  local s=scenes[activePed[ped]]
  local task=pedTasks[ped]
  local playing = task and task.dict==dict and task.clip==clip
    and (task.advanced or s and s.running) or false
  if realClipLengths and s and not s.looped and now-s.started>=GetAnimDuration(dict,clip)*1000 then playing=false end
  if numericAnimResult then return playing and 1 or 0 end
  return playing
end
function GetEntityAnimCurrentTime(ped,dict,clip)
  if not IsEntityPlayingAnim(ped,dict,clip) then return 0 end
  if ped==1 and frozenActorPhase then return frozenActorPhase end
  if activePed[ped] then return GetSynchronizedScenePhase(activePed[ped]+1000) end
  return 0
end

function PlayEntityAnim(entity,clip,dict,blend,looped,hold)
  assert(attached[entity], 'hand-local prop animation must be attached')
  assert(GetAnimDuration(dict,clip)>0, 'unknown hand clip: '..dict..'/'..clip)
  handAnims[entity]={dict=dict,clip=clip,looped=looped,hold=hold}
  return true
end
function StopEntityAnim(entity) handAnims[entity]=nil end
function SetEntityAnimCurrentTime(entity,dict,clip,phase)
  assert(handAnims[entity] and handAnims[entity].clip==clip)
  handAnims[entity].phase=phase
end
function TaskPlayAnimAdvanced(ped,dict,clip,x,y,z,rx,ry,rz,blendIn,blendOut,duration,flags,phase,rotationOrder)
  if ped==1 and failActorRecovery then return end
  assert(duration==-1 and rotationOrder==2)
  assert((flags & 1024)~=0 and (flags & 4096)~=0 and (flags & 524288)~=0,
    'authored FBI3 tracks require physics override and initial/mover extraction')
  assert((flags & 3)==1 or (flags & 3)==2, 'loop or hold the final frame')
  assert(phase>=0 and phase<1)
  advancedCount=advancedCount+1
  local pos=vector3(x,y,z)
  advancedTasks[ped]={dict=dict,clip=clip,pos=pos,rot=vector3(rx,ry,rz),phase=phase,flags=flags}
  -- Advanced task with mover extraction consumes the common scene origin.
  -- Model its extracted world transform, including the authored vertical offset.
  positions[ped]=GetAnimInitialOffsetPosition(dict,clip,x,y,z,rx,ry,rz)
  activePed[ped]=nil
  pedTasks[ped]={dict=dict,clip=clip,advanced=true}
end
function ClearPedTasks(ped)
  clears=clears+1
  activePed[ped]=nil
  pedTasks[ped]=nil
end
ClearPedTasksImmediately=ClearPedTasks
function CreateCam() nextCam=nextCam+1; cams[nextCam]=true; return nextCam end
function DoesCamExist(id) return cams[id] end
function PlaySynchronizedCamAnim(cam,scene,clip,dict)
  assert(scenes[scene-1000], 'camera requires a LOCAL scene handle')
  return not failCamera
end
function DestroyCam(id) cams[id]=nil end
SetCamActive,RenderScriptCams=noop,noop
function DetachEntity(id) attached[id]=nil end
function GetPedBoneIndex(ped,bone) return bone end
function AttachEntityToEntity(id,ped) attached[id]=ped end
function IsEntityAttachedToEntity(id,ped) return attached[id]==ped end
function IsEntityAttached(id) return attached[id]~=nil end
function joaat(value) return value end
function IsPedInAnyVehicle() return false end

dofile(RESOURCE_ROOT .. '/config.lua')
dofile(RESOURCE_ROOT .. '/client/impl/main.impl.lua')
local client=TEST_IMPL
client.isClient=true
client:Init(); client:OnReady()
threads={} -- discard initial getSetups request
local setup={ id=7,owner=1,victim=2,heading=90,coords=vector3(0,0,0),
  positions={chair=vector3(0,0,0),trolley=vector3(0,0,0)},rotations={},props={},
  toolToken='token',toolState='idle',toolReady=true,toolEpoch=1,seatReady=true }
for i,key in ipairs(Config.Torture.propOrder) do
  setup.props[key]=10+i; setup.positions[key]=vector3(0,0,0)
end
client.setups[7]=setup
local function session(tool)
  setup.tool=tool
  client.toolSession={setupId=7,token='token',tool=tool,actor=true,phase='idle',idleEpoch=1,idleReady=true}
end
local function drain()
  while #threads>0 do table.remove(threads,1)() end
end
local cases=0
for _,tool in ipairs(Config.Torture.toolOrder) do
  session(tool)
  assert(client:ValidateSceneAssets(setup,Config.Torture.toolScenes[tool].select), tool..' select assets')
  assert(client:ValidateSceneAssets(setup,Config.Torture.toolScenes[tool].idle), tool..' idle assets')
  local transitionClears=clears
  assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes[tool].select,false))
  local selectedScene, selectedCamera = client.scene, client.camera
  assert(scenes[selectedScene].running and scenes[selectedScene].hold and cams[selectedCamera],
    'selection must keep its task and camera while waiting for the idle event')
  assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes[tool].idle,true))
  assert(clears==transitionClears, 'select-to-idle must not clear the actor task')
  for key,clip in pairs(Config.Torture.toolScenes[tool].idle.handProps or {}) do
    assert(attached[setup.props[key]] and handAnims[setup.props[key]].clip==clip)
    assert(not scenes[client.scene].tracks[setup.props[key]], 'hand clip must not enter world scene')
  end
  assert(not cams[selectedCamera] and cams[client.camera], 'replace the old camera without leaking it')
  local scene=scenes[client.scene]
  assert(scene.looped and (pedTasks[1].flags & 64)~=0 and scene.ped==1)
  for _,track in pairs(scene.tracks) do assert((track.flags & 64)~=0) end
  local origin,heading=scene.pos,scene.heading
  assert(math.abs(heading-313)<.001, 'chair rotation must come from the animation track')
  client:ShowToolMenu(setup)
  assert(openMenu==client.toolMenuId)
  local menu=menus[openMenu]; local expected=1
  for _,action in pairs(Config.Torture.actions) do if action.tool==tool then expected=expected+1 end end
  assert(#menu.options==expected and menu.canClose==false)
  if tool=='waterboard' then assert(#menu.options==2 and Config.Torture.actions.water_kick==nil) end
  drain() -- optional bench restoration runs after idle and menu are available
  local before=stops
  for _=1,4 do Wait(7300); client:ShowToolMenu(setup) end
  assert(stops==before and scene.running and scene.looped, 'menu must not stop idle playback')
  assert(IsEntityPlayingAnim(1,Config.Torture.toolScenes[tool].idle.dict,
    Config.Torture.toolScenes[tool].idle.actor), 'late old scene stops must not remove actor idle')
  lib.hideContext()
  local actorScene=client.scene; local count=nextScene
  client.seated=7; currentPlayer=2
  assert(client:JoinVictimScene(setup,Config.Torture.toolScenes[tool].idle,actorScene,true,function() return true end))
  assert(client.victimMasterScene==actorScene and client.victimScene)
  assert(nextScene==count,
    'victim must not create a competing synchronized scene')
  local expectedPos=GetAnimInitialOffsetPosition(Config.Torture.toolScenes[tool].idle.dict,
    Config.Torture.toolScenes[tool].idle.victim,origin.x,origin.y,origin.z,0,0,heading)
  assert(#(advancedTasks[2].pos-origin)<.001,
    'victim must pass the same scene root as actor, without pre-applying its track offset')
  assert(#(GetEntityCoords(2)-expectedPos)<.001,
    'victim authored offset must be applied exactly once, including height')
  assert((advancedTasks[2].flags & 1)~=0, 'victim idle must loop')
  assert(scene.rate~=0, 'actor scene must not pause while waiting for the victim')
  client:StopVictimScene(); assert(scene.running, 'victim cleanup must not stop the actor scene')
  client.seated=nil; currentPlayer=1
  client:StopStage() -- StopCamAnim deliberately does not exist in this environment.
  assert(next(handAnims)==nil, 'cleanup must stop all attached prop animations')
  client.toolSession=nil
  cases=cases+1
end
print(('PASS: select -> looping idle/menu, camera cleanup, matching peer origins (%d tools)'):format(cases))
local badIdle={}
for key,value in pairs(Config.Torture.toolScenes.electric.idle) do badIdle[key]=value end
badIdle.chair='clamp_wait_loop_chair'
assert(not client:ValidateSceneAssets(setup,badIdle), 'reject the old unsupported electric chair track')

-- A stopped local scene can retain its last pose/handle. Neither its running
-- query nor the old clip query is a network-stop acknowledgement.
session('wrench')
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.select,false))
local heldScene=client.scene
local heldCamera=client.camera
local handoffStart=now
retainStoppedSceneState=true
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.idle,true),
  'retained old scene state must not cancel the select-to-idle handoff')
assert(now-handoffStart<250, 'handoff must not wait one second for old native flags')
assert(scenes[heldScene].running and activePed[1]==client.scene,
  'new actor task must replace the old task even if old handle still reports running')
assert(not scenes[heldScene].hold and not scenes[heldScene].looped)
assert(not cams[heldCamera] and cams[client.camera])
Wait(40)
assert(client:ActorTrackRunning(client.scene))
for entity in pairs(scenes[client.scene].tracks) do assert(activeEntity[entity]==client.scene) end
retainStoppedSceneState=false
drain(); client:StopStage(); client.toolSession=nil
print('PASS: retained stopped scene state cannot abort idle or leave old actor/prop tasks')

-- Emulate slow control acquisition while returning unused props. It may take
-- seconds, but must happen after the idle scene and menu, with the actor held.
session('wrench')
local originalPutPropBack = client.PutPropBack
local restored=0
client.PutPropBack=function(self,...)
  assert(openMenu==self.toolMenuId, 'bench restoration must not gate the menu')
  restored=restored+1
  Wait(1500)
  return originalPutPropBack(self,...)
end
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.select,false))
local selectDoneAt=now
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.idle,true))
client:ShowToolMenu(setup)
assert(now-selectDoneAt<=250 and restored==0 and openMenu==client.toolMenuId,
  'no synchronous bench/control waits between selection and the ready menu')
drain()
assert(restored>0 and now>selectDoneAt)
client.PutPropBack=originalPutPropBack
lib.hideContext()

-- A queued bench job from a removed session cannot move the next session's props.
client:StopStage()
session('wrench')
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.select,false))
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.idle,true))
local staleSession=client.toolSession
session('wrench')
client.PutPropBack=function() error('stale bench coroutine moved a prop') end
drain()
client.PutPropBack=originalPutPropBack
client.toolSession=staleSession

-- Action completion uses the same held-frame handoff. A genuine stop still
-- clears the scene/camera, so release/restart cannot leave the actor locked.
client.activeAction={setupId=7,token='attack',key='wrench_left',actor=true,stage=1}
local beforeActionClears=clears
assert(client:RunActorStage(setup,'attack','wrench_left',1))
local actionScene,actionCamera=client.scene,client.camera
assert(scenes[actionScene].running and scenes[actionScene].hold and cams[actionCamera])
client.handlers.stopAction(7,'attack',true)
assert(client.scene==actionScene and client.camera==actionCamera and clears==beforeActionClears)
client.activeAction={setupId=7,token='release',key='wrench_left',actor=true}
client.handlers.stopAction(7,'release',false)
assert(client.scene==nil and client.camera==nil and not cams[actionCamera])
client.toolSession=nil
print('PASS: slow bench cleanup does not delay menu; action handoff preserves pose/camera; release cleans up')

client.seated=7; currentPlayer=2
assert(client:PlayIdle(setup))
assert(client.victimScene.dict=='missfbi3_weapon_select')
assert(advancedTasks[2].clip=='waterboard_idle_victim')
local beforeTransition=clears
assert(client:PlayVictimTrack(setup,Config.Torture.toolScenes.wrench.idle,true,0.0,123))
assert(clears==beforeTransition, 'victim clip change must not clear ped tasks')
client:StopStage(true)
assert(clears==beforeTransition and client.victimScene,
  'return-to-seat transition must retain the seated task')
assert(client:PlayIdle(setup))
assert(clears==beforeTransition, 'return to base seat must not flash a standing frame')
assert(client:PlayVictimTrack(setup,Config.Torture.actions.wrench_left.stages[1],false,0.35,124))
assert((advancedTasks[2].flags & 3)==2, 'finite victim tracks hold until the next stage')
assert(advancedTasks[2].phase==0.35, 'late victim starts at the sampled actor phase')
ClearPedTasks(2)
local beforeRecovery=advancedCount
client.victimSceneStarting=true
client.intervals.seatControl()
assert(advancedCount==beforeRecovery, 'seat watchdog must not restart a scene still starting')
client.victimSceneStarting=false
client.nextSeatRecoveryAt=0
client.intervals.seatControl()
assert(advancedCount==beforeRecovery+1, 'seat watchdog must recover a lost task once')
client.intervals.seatControl()
assert(advancedCount==beforeRecovery+1, 'seat watchdog must be rate limited')
client:StopVictimScene(); client.seated=nil; currentPlayer=1

-- The bind packet may arrive before the victim's phase packet. It must wait
-- for the current token instead of silently dropping that scene.
client.seated=7; currentPlayer=2
client.toolSession={setupId=7,token='token',tool='wrench',actor=false,phase='prepare'}
local delayedEvents=#events
client.handlers.joinVictimScene(setup,'token','select',0,444,
  Config.Torture.toolScenes.wrench.select,true)
assert(#threads==1 and #events==delayedEvents)
client.toolSession.phase='select'
drain()
assert(events[#events].name=='victimSceneReady' and events[#events].args[6]==true,
  'victim must acknowledge a bind delivered before its select phase')
client:StopVictimScene(); client.toolSession=nil; client.seated=nil; currentPlayer=1

session('wrench'); client.toolSession.phase='select'; setup.toolReady=false
client.handlers.startToolIdle(setup,'token',2)
client:ShowToolMenu(setup); assert(openMenu==nil)
drain(); assert(client.toolSession.phase=='idle' and client.toolSession.idleReady)
assert(openMenu==nil, 'one client ready must not authorize menu')
setup.toolEpoch=2; setup.toolReady=true; client:UpdateSetup(setup)
assert(openMenu==client.toolMenuId)
local menu=menus[openMenu]
menu.options[1].onSelect(); assert(events[#events].name=='startAction')
lib.hideContext(); client:ShowToolMenu(setup); assert(openMenu==nil, 'pending request blocks duplicate menu')
client.handlers.notify('invalid_state'); assert(openMenu==client.toolMenuId)
lib.hideContext(); client:StopStage()
-- Ready snapshot arriving before local scene startup finishes.
session('wrench'); setup.toolEpoch=3; client.handlers.startToolIdle(setup,'token',3)
client:ShowToolMenu(setup); assert(openMenu==nil)
drain(); assert(openMenu==client.toolMenuId)
client.handlers.startToolIdle(setup,'token',2); assert(#threads==0, 'stale idle epoch rejected')
lib.hideContext(); client:StopStage()
failCamera=true; assert(not client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.idle,true))
assert(client.scene==nil and client.camera==nil)
failCamera=false
autoAck=false
assert(not client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.idle,true))
assert(client.scene==nil and client.camera==nil, 'missing victim ack must clean up scene/camera')
autoAck=true
print('PASS: readiness ordering, stale epochs, action menu, rejection recovery, camera failure cleanup')

-- Startup used truthiness while ActorTrackRunning used `== true`: the same
-- native result of 1 passed startup but immediately failed the peer handshake.
numericAnimResult=true
session('wrench')
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.select,false),
  'native integer true must not falsely cancel the actor and victim sessions')
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.idle,true))
client.activeAction={setupId=7,token='numeric-bool',key='wrench_left',actor=true,stage=1}
assert(client:RunActorStage(setup,'numeric-bool','wrench_left',1))
pedTasks[1]=nil
assert(not client:ActorTrackRunning(client.scene), 'native integer zero must fail')
client:StopStage(); client.activeAction=nil; numericAnimResult=false

session('wrench'); client.toolSession.revision=20
local currentSession=client.toolSession
local oldSnapshot={}
for key,value in pairs(setup) do oldSnapshot[key]=value end
oldSnapshot.revision=19; oldSnapshot.toolState='empty'; oldSnapshot.toolToken=nil
client:UpdateSetup(oldSnapshot)
assert(client.toolSession==currentSession, 'old snapshot must not cancel prepared session')
oldSnapshot.revision=21
client:UpdateSetup(oldSnapshot)
assert(client.toolSession==nil, 'new authoritative release must still cancel session')
drain()
client.setups[7]=setup
print('PASS: integer native animation results and command/broadcast revision ordering')

-- The network scene is the completion clock. A separate entity-time query
-- returning zero must not time out an otherwise playing synchronized track.
frozenActorPhase=0
localHandleDelay=120
session('wrench')
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.select,false))
assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.idle,true))
local stageCount=0
for key,action in pairs(Config.Torture.actions) do
  session(action.tool)
  for index in ipairs(action.stages) do
    local stage=action.stages[index]
    assert(client:ValidateSceneAssets(setup,stage),key..'/'..index..' assets')
    client.activeAction={setupId=7,token='all-actions',key=key,actor=true,stage=index}
    local started=now
    assert(client:RunActorStage(setup,'all-actions',key,index), key..'/'..index)
    if stage.loopMs then assert(now-started>=stage.loopMs and scenes[client.scene].looped) end
    if stage.victimLoop then assert(client.chairScene and client.chairScene~=client.scene) end
    for propKey,clip in pairs(stage.handProps or {}) do
      assert(attached[setup.props[propKey]] and handAnims[setup.props[propKey]].clip==clip)
      assert(not scenes[client.scene].tracks[setup.props[propKey]])
    end
    if action.tool=='waterboard' then assert(attached[setup.props.waterboard]) end
    stageCount=stageCount+1
  end
end
client:StopStage(); client.activeAction=nil
frozenActorPhase=nil; localHandleDelay=0
session('wrench'); failActorTask=true
assert(not client:RunActorToolScene(setup,'token',Config.Torture.toolScenes.wrench.select,false))
assert(client.scene==nil and client.camera==nil and client.actorTrack==nil)
failActorTask=false
client.activeAction={setupId=7,token='lost-actor',key='wrench_left',actor=true,stage=1}
loseActorAt=now+300
local beforeLost=advancedCount
assert(not client:RunActorStage(setup,'lost-actor','wrench_left',1),
  'actual task loss must abort; do not create an independent actor animation clock')
assert(client.scene==nil and client.camera==nil and advancedCount==beforeLost)
client.activeAction=nil; client.toolSession=nil
print(('PASS: delayed handles, %d action stages and failure cleanup'):format(stageCount))

shortWaterTransitions=true
session('waterboard')
for _,index in ipairs({2,4}) do
  client.activeAction={setupId=7,token='short-water',key='water_pour',actor=true,stage=index}
  local start=now
  assert(client:RunActorStage(setup,'short-water','water_pour',index))
  assert(now-start<1000, 'short actor transition must not wait for a background rag loop')
  if index==4 then
    assert(scenes[client.scene].tracks[setup.props.rag]==nil)
    assert(scenes[client.chairScene].tracks[setup.props.rag].clip=='waterboard_loop_rag')
    assert(scenes[client.chairScene].looped)
  end
end
client:StopStage(); client.activeAction=nil; client.toolSession=nil
shortWaterTransitions=false
print('PASS: short water transitions and independent finishing rag/victim clock')

-- Reproduce the reported ~13.33s clock: finite actor/tool clips finish at
-- 7.43/8.33/12.50s, whereas the seated chair loop lasts 13.33s. They must not
-- share a scene clock. No local actor recovery is permitted to hide a failure.
realClipLengths=true
for _,tool in ipairs({'wrench','electric','waterboard'}) do
  session(tool)
  local select=Config.Torture.toolScenes[tool].select
  local start=now
  local beforeActorAdvanced=advancedCount
  assert(client:RunActorToolScene(setup,'token',select,false), tool..' selection clock')
  local main,chairClock=client.scene,client.chairScene
  assert(chairClock and chairClock~=main and scenes[chairClock].looped)
  assert(scenes[main].tracks[setup.props.chair]==nil, 'chair loop must not extend selection')
  assert(scenes[main].duration==GetAnimDuration(select.dict,select.actor)*1000)
  assert(now-start<GetAnimDuration(select.dict,select.actor)*1000+100,
    'selection should hand off before the actor clip naturally expires')
  assert(advancedCount==beforeActorAdvanced, 'never replace actor with independent advanced task')
  currentPlayer=2; client.seated=7
  local expectedVictimPhase=GetSynchronizedScenePhase(chairClock+1000)
  assert(client:JoinVictimScene(setup,select,main,true,function() return true end,chairClock))
  assert(math.abs(advancedTasks[2].phase-expectedVictimPhase)<.001,
    'victim must sample the independent chair clock')
  client:StopVictimScene(); client.seated=nil; currentPlayer=1
  assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes[tool].idle,true))
  local idleScene=client.scene
  Wait(40) -- delayed old-scene teardown must already have happened
  assert(client:ActorTrackRunning(idleScene) and not scenes[chairClock].running)
  for entity in pairs(scenes[idleScene].tracks) do
    assert(activeEntity[entity]==idleScene, 'old stop must not detach/freeze the new tool track')
  end
  drain()
  client:StopStage()
end
session('pliers')
client.activeAction={setupId=7,token='long-clip',key='pliers_pull',actor=true,stage=1}
local longStart=now
assert(client:RunActorStage(setup,'long-clip','pliers_pull',1),
  '6-second loaded clip must not time out at configured 2 seconds plus 2.5')
assert(now-longStart>4500)
client:StopStage(); client.activeAction=nil; client.toolSession=nil
realClipLengths=false
print('PASS: distinct chair/actor clocks, stop-before-start for ped/props, long action clip completion')

dofile(RESOURCE_ROOT .. '/server/impl/main.impl.lua')
local server=TEST_IMPL; server:Init(); server:OnReady()
setup.entities=setup.props; setup.bucket=0; setup.toolState='empty'; setup.tool=nil
setup.toolReady=false; setup.toolToken=nil; setup.toolEpoch=0; setup.busy=nil
server.setups[1]=setup; server.seated[2]=7
local function send(src,event,...)
  source=src; server.handlers[event](...)
end
local function assertVictimFirst(name)
  local recipients={}
  for _,event in ipairs(events) do
    if event.name==name then recipients[#recipients+1]=event.args[1] end
  end
  assert(recipients[#recipients-1]==2 and recipients[#recipients]==1,
    name..' must arm the victim before starting the actor scene')
end
local function bind(token,kind,step)
  send(1,'bindVictimScene',7,token,kind,step,999)
  assert(setup.peerScene and not setup.peerScene.ready)
  send(1,'victimSceneReady',7,token,kind,step,999,true)
  assert(not setup.peerScene.ready, 'actor cannot acknowledge for victim')
  send(2,'victimSceneReady',7,token,kind,step,999,true)
  assert(setup.peerScene.ready)
end
server:TakeTool(1,7,'wrench'); local token=setup.toolToken
assert(setup.toolState=='selecting')
send(1,'readyTool',7,token,true); send(2,'readyTool',7,token,true)
assertVictimFirst('playToolSelect')
bind(token,'select',0)
Wait(600); send(1,'toolSelected',7,token,true)
assert(setup.toolState=='idle' and not setup.toolReady)
assertVictimFirst('startToolIdle')
bind(token,'idle',1)
send(1,'toolIdleReady',7,token,0,true); send(2,'toolIdleReady',7,token,0,true)
assert(not setup.toolReady)
send(1,'toolIdleReady',7,token,1,true); assert(not setup.toolReady)
send(2,'toolIdleReady',7,token,1,true); assert(setup.toolReady)
server:StartAction(3,7,2,'wrench_left'); assert(setup.toolState=='idle')
server:StartAction(1,7,2,'wrench_left'); local actionToken=setup.busy.token
assert(setup.toolState=='action')
send(1,'readyAction',7,actionToken,true); send(2,'readyAction',7,actionToken,true)
assertVictimFirst('playStage')
bind(actionToken,'action',1)
Wait(5000); send(1,'stageDone',7,actionToken,1,true)
assert(setup.toolState=='idle' and setup.toolEpoch==2 and not setup.toolReady)
local resumeMessages=0
for _,event in ipairs(events) do
  if event.name=='stopAction' and event.args[3]==actionToken then
    assert(event.args[4]==true, 'completed damage action must preserve the pose until next idle')
    resumeMessages=resumeMessages+1
  end
end
assert(resumeMessages==2, 'both players receive the same transition contract')
bind(token,'idle',2)
local function damageCount()
  local n=0; for _,event in ipairs(events) do if event.name=='applyDamage' then n=n+1 end end; return n
end
assert(damageCount()==1)
send(1,'stageDone',7,actionToken,1,true); assert(damageCount()==1)
send(1,'toolIdleReady',7,token,1,true); send(2,'toolIdleReady',7,token,1,true); assert(not setup.toolReady)
send(1,'toolIdleReady',7,token,2,true); send(2,'toolIdleReady',7,token,2,true)
send(1,'exitTool',7,token); assert(setup.toolState=='exiting')
send(1,'toolExited',7,token,true); assert(setup.toolState=='empty' and setup.tool==nil)
print('PASS: server select -> idle -> action -> idle -> exit, two-peer readiness and damage once')

-- A completed actor animation without a matching victim handshake cannot deal damage.
setup.tool='wrench'; setup.toolState='idle'; setup.toolReady=true; setup.toolToken='second'
server:StartAction(1,7,2,'wrench_left'); actionToken=setup.busy.token
send(1,'readyAction',7,actionToken,true); send(2,'readyAction',7,actionToken,true)
Wait(5000); send(1,'stageDone',7,actionToken,1,true)
assert(damageCount()==1 and setup.toolState=='idle')
print('PASS: missing victim scene acknowledgement prevents damage')

-- Exercise every repaired option through server authority, including its loop
-- duration and the separate victim/chair clock on water transitions.
for key,action in pairs(Config.Torture.actions) do
  if action.tool=='pliers' or action.tool=='electric' or action.tool=='waterboard' then
    setup.tool=action.tool; setup.toolState='idle'; setup.toolReady=true; setup.toolToken='flow-'..key
    local damageBefore=damageCount()
    server:StartAction(1,7,2,key)
    local t=setup.busy.token
    send(1,'readyAction',7,t,true); send(2,'readyAction',7,t,true)
    for index,stage in ipairs(action.stages) do
      send(1,'bindVictimScene',7,t,'action',index,999,stage.victimLoop and 1001 or nil)
      assert(setup.peerScene and not setup.peerScene.ready)
      local join=events[#events]
      assert(join.name=='joinVictimScene' and join.args[8]==(stage.loopMs~=nil or stage.victimLoop==true))
      if stage.victimLoop then assert(join.args[9]==1001) end
      send(2,'victimSceneReady',7,t,'action',index,999,true)
      assert(setup.peerScene.ready)
      -- The old server rejected the short open/close-can clips before 1000ms.
      Wait(stage.minimumMs==0 and 800 or math.max(stage.loopMs or 0,5000))
      send(1,'stageDone',7,t,index,true)
      assert(setup.toolState==(index==#action.stages and 'idle' or 'action'))
    end
    assert(damageCount()==damageBefore+1, key..' must deal damage only once after the whole sequence')
    send(1,'stageDone',7,t,#action.stages,true)
    assert(damageCount()==damageBefore+1)
  end
end
setup.tool='waterboard'; setup.toolState='idle'; setup.toolReady=true; setup.toolToken='removed-option'
local damageBeforeRemoved=damageCount()
server:StartAction(1,7,2,'water_kick')
assert(setup.busy==nil and damageCount()==damageBeforeRemoved, 'removed kick event must not authorize an action')
setup.tool='electric'; setup.toolState='idle'; setup.toolReady=true; setup.toolToken='early-loop'
server:StartAction(1,7,2,'electric_left'); local early=setup.busy.token
send(1,'readyAction',7,early,true); send(2,'readyAction',7,early,true)
bind(early,'action',1)
local damageBefore=damageCount()
Wait(1500); send(1,'stageDone',7,early,1,true)
assert(setup.busy==nil and damageCount()==damageBefore, 'cannot skip configured loop duration')
print('PASS: all repaired options, water clock relay, loop deadlines, damage once and early completion rejection')

-- The reported scene handle is larger than an entity net ID. It is an opaque
-- scene handle, and the same handle may legitimately recur in a new token.
setup.tool='wrench'; setup.toolState='selecting'; setup.toolPhase='playing'
setup.toolToken='peer-test'; setup.peerScene=nil
positions[1]=vector3(0,0,0)
send(1,'bindVictimScene',7,'peer-test','select',0,374720,374722)
assert(setup.peerScene and setup.peerScene.netScene==374720)
assert(setup.peerScene.victimClock==374722 and events[#events].args[9]==374722,
  'server must relay the separate chair clock for the matching selection')
send(2,'victimSceneReady',7,'old-token','select',0,374720,true)
assert(not setup.peerScene.ready, 'reused scene ID cannot accept an old token ack')
send(2,'victimSceneReady',7,'peer-test','select',0,374720,false,'victim_wrong_seat')
assert(events[#events].name=='victimSceneReady' and events[#events].args[7]=='victim_wrong_seat',
  'victim rejection reason must reach the actor')
setup.peerScene=nil
positions[1]=vector3(20,0,0)
send(1,'bindVictimScene',7,'peer-test','select',0,374720)
assert(setup.peerScene==nil and events[#events].args[7]=='actor_distance',
  'distance validation must reject explicitly without authorizing a scene')
positions[1]=vector3(0,0,0)
send(1,'bindVictimScene',7,'old-token','select',0,374720)
assert(events[#events].args[7]=='server_stage_mismatch')

-- Cleanup used to erase the pending handshake and hide the original failure.
currentPlayer=1
local pending={token='peer-test',ready=nil}
client.peerScene=pending
client:StopStage()
assert(pending.reason=='session_stopped_before_ack')
client.peerScene={token='peer-test',kind='select',step=0,scene=374720}
client.handlers.victimSceneReady('peer-test','select',0,374720,false,'victim_track_failed')
pending=client.peerScene
client:StopStage()
assert(pending.reason=='victim_track_failed', 'cleanup must preserve the actual rejection')
print('PASS: peer rejection reasons, large/reused scene IDs, stale ack rejection and cleanup diagnostics')
