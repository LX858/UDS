-- Tests use the real config and implementation files. Natives below simulate
-- lifecycle/phase only, not GTA clip geometry or OneSync replication.
local vecmt = {}
function vector3(x, y, z) return setmetatable({ x = x, y = y, z = z }, vecmt) end
vecmt.__sub = function(a, b) return vector3(a.x-b.x, a.y-b.y, a.z-b.z) end
vecmt.__add = function(a, b) return vector3(a.x+b.x, a.y+b.y, a.z+b.z) end
vecmt.__len = function(a) return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end
Locales = { default = {} }
function L(key) return key end
local now, nextScene, nextLocalScene, nextCam = 0, 100, 50000, 5000
local scenes, cams, attached, positions, activePed = {}, {}, {}, {}, {}
local pedTasks = {}
local events, threads, timers, menus, openMenu = {}, {}, {}, {}, nil
local currentPlayer, failCamera, stops, shown = 1, false, 0, 0
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
function Wait(ms) now = now + math.max(ms,20) end
function CreateThread(fn) threads[#threads+1] = fn end
function SetTimeout(ms,fn) timers[#timers+1] = fn end
function RegisterCommand() end
function GetGroundZFor_3dCoord() return true,0 end
function DoesAnimDictExist() return true end
function HasAnimDictLoaded() return true end
RequestAnimDict = noop
function GetAnimDuration() return 1 end
-- Deliberately not 180 degrees and not zero translation: detects hard-coded
-- origin/heading assumptions while verifying both peers use the same transform.
function GetAnimInitialOffsetRotation(dict,clip,x,y,z,rx,ry,rz)
  return vector3(0,0,clip == 'waterboard_idle_chair' and (137+rz)%360 or rz)
end
function GetAnimInitialOffsetPosition(dict,clip,x,y,z,rx,ry,rz)
  local r = math.rad(rz)
  return vector3(x+1.3*math.cos(r)+.4*math.sin(r), y+1.3*math.sin(r)-.4*math.cos(r),z+.25)
end
function NetworkCreateSynchronisedScene(x,y,z,rx,ry,rz,order,hold,looped)
  nextScene = nextScene+1
  scenes[nextScene] = { pos=vector3(x,y,z), heading=rz, hold=hold, looped=looped, tracks={} }
  return nextScene
end
function NetworkAddPedToSynchronisedScene(ped,scene,dict,clip,a,b,flags)
  local s=scenes[scene]; s.ped=ped; s.dict=dict; s.clip=clip; s.flags=flags
end
function NetworkAddEntityToSynchronisedScene(entity,scene,dict,clip,a,b,flags)
  scenes[scene].tracks[entity] = { dict=dict,clip=clip,flags=flags }
end
function NetworkStartSynchronisedScene(scene)
  local s=scenes[scene]; s.started=now; s.running=true
  if s.ped then activePed[s.ped]=scene; pedTasks[s.ped]={dict=s.dict,clip=s.clip} end
end
function NetworkStopSynchronisedScene(scene)
  stops=stops+1; scenes[scene].running=false
  if activePed[scenes[scene].ped] == scene then activePed[scenes[scene].ped]=nil end
end
function NetworkGetLocalSceneFromNetworkId(scene) return scene+1000 end
function CreateSynchronizedScene(x,y,z,rx,ry,rz)
  nextLocalScene=nextLocalScene+1
  scenes[nextLocalScene]={pos=vector3(x,y,z),heading=rz,tracks={},localScene=true}
  return nextLocalScene
end
local function sceneFor(id) return scenes[id>=50000 and id or id-1000] end
function SetSynchronizedSceneLooped(id,v) sceneFor(id).looped=v end
function SetSynchronizedSceneHoldLastFrame(id,v) sceneFor(id).hold=v end
function SetSynchronizedSceneRate(id,rate) sceneFor(id).rate=rate end
function SetSynchronizedScenePhase(id,phase) sceneFor(id).phase=phase end
function IsSynchronizedSceneRunning(id) return sceneFor(id) and sceneFor(id).running end
function GetSynchronizedScenePhase(id)
  local s=sceneFor(id); local phase=(s.phase or 0)+(now-s.started)/1000
  return s.looped and phase%1 or math.min(1,phase)
end
function IsEntityPlayingAnim(ped,dict,clip)
  local s=scenes[activePed[ped]]
  local task=pedTasks[ped]
  return s and s.running and task and task.dict==dict and task.clip==clip or false
end
function TaskSynchronizedScene(ped,localScene,dict,clip,a,b,flags,ragdoll,mover,ik)
  assert(scenes[localScene] and scenes[localScene].localScene,
    'victim must task its own local scene')
  assert((flags & 4)~=0 and (flags & 1024)~=0 and (flags & 2048)~=0)
  assert((flags & 8)==0, 'victim task must not abort the actor scene')
  assert(ragdoll==0 and mover==1000.0 and ik==0)
  scenes[localScene].running=true; scenes[localScene].started=now
  activePed[ped]=localScene; pedTasks[ped]={dict=dict,clip=clip}
end
function ClearPedTasks(ped)
  local id=activePed[ped]
  if id and scenes[id] and scenes[id].localScene then scenes[id].running=false end
  activePed[ped]=nil
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
  assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes[tool].select,false))
  assert(client:RunActorToolScene(setup,'token',Config.Torture.toolScenes[tool].idle,true))
  local scene=scenes[client.scene]
  assert(scene.looped and (scene.flags & 64)~=0)
  for _,track in pairs(scene.tracks) do assert((track.flags & 64)~=0) end
  local origin,heading=scene.pos,scene.heading
  assert(math.abs(heading-313)<.001, 'chair rotation must come from the animation track')
  client:ShowToolMenu(setup)
  assert(openMenu==client.toolMenuId)
  local menu=menus[openMenu]; local expected=1
  for _,action in pairs(Config.Torture.actions) do if action.tool==tool then expected=expected+1 end end
  assert(#menu.options==expected and menu.canClose==false)
  local before=stops
  for _=1,4 do Wait(7300); client:ShowToolMenu(setup) end
  assert(stops==before and scene.running and scene.looped, 'menu must not stop idle playback')
  lib.hideContext()
  local actorScene=client.scene; local count=nextScene; local localCount=nextLocalScene
  client.seated=7; currentPlayer=2
  assert(client:JoinVictimScene(setup,Config.Torture.toolScenes[tool].idle,actorScene,true,function() return true end))
  assert(client.victimMasterScene==actorScene and client.victimLocalScene==nextLocalScene)
  assert(nextScene==count and nextLocalScene==localCount+1,
    'victim must create only a local ped scene')
  assert(scenes[client.victimLocalScene].pos.x==origin.x
    and scenes[client.victimLocalScene].pos.y==origin.y
    and scenes[client.victimLocalScene].heading==heading,
    'victim and actor must use the same scene origin')
  assert(scene.rate~=0, 'actor scene must not pause while waiting for the victim')
  client:StopVictimScene(); assert(scene.running, 'victim cleanup must not stop the actor scene')
  client.seated=nil; currentPlayer=1
  client:StopStage() -- StopCamAnim deliberately does not exist in this environment.
  client.toolSession=nil
  cases=cases+1
end
print(('PASS: select -> looping idle/menu, camera cleanup, matching peer origins (%d tools)'):format(cases))
client.seated=7; currentPlayer=2
assert(client:PlayIdle(setup))
assert(scenes[client.victimScene].dict=='missfbi3_weapon_select')
assert(scenes[client.victimScene].tracks[setup.props.chair]==nil,
  'victim base idle must not compete for control of the chair')
ClearPedTasks(2)
local beforeRecovery=nextLocalScene
client.victimSceneStarting=true
client.intervals.seatControl()
assert(nextLocalScene==beforeRecovery, 'seat watchdog must not restart a scene still starting')
client.victimSceneStarting=false
client.nextSeatRecoveryAt=0
client.intervals.seatControl()
assert(nextLocalScene==beforeRecovery+1, 'seat watchdog must recover a lost task once')
client.intervals.seatControl()
assert(nextLocalScene==beforeRecovery+1, 'seat watchdog must be rate limited')
client:StopVictimScene(); client.seated=nil; currentPlayer=1

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

dofile(RESOURCE_ROOT .. '/server/impl/main.impl.lua')
local server=TEST_IMPL; server:Init(); server:OnReady()
setup.entities=setup.props; setup.bucket=0; setup.toolState='empty'; setup.tool=nil
setup.toolReady=false; setup.toolToken=nil; setup.toolEpoch=0; setup.busy=nil
server.setups[1]=setup; server.seated[2]=7
local function send(src,event,...)
  source=src; server.handlers[event](...)
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
bind(token,'select',0)
Wait(600); send(1,'toolSelected',7,token,true)
assert(setup.toolState=='idle' and not setup.toolReady)
bind(token,'idle',1)
send(1,'toolIdleReady',7,token,0,true); send(2,'toolIdleReady',7,token,0,true)
assert(not setup.toolReady)
send(1,'toolIdleReady',7,token,1,true); assert(not setup.toolReady)
send(2,'toolIdleReady',7,token,1,true); assert(setup.toolReady)
server:StartAction(3,7,2,'wrench_left'); assert(setup.toolState=='idle')
server:StartAction(1,7,2,'wrench_left'); local actionToken=setup.busy.token
assert(setup.toolState=='action')
send(1,'readyAction',7,actionToken,true); send(2,'readyAction',7,actionToken,true)
bind(actionToken,'action',1)
Wait(5000); send(1,'stageDone',7,actionToken,1,true)
assert(setup.toolState=='idle' and setup.toolEpoch==2 and not setup.toolReady)
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
