"""Offline regression harness. Requires Python + lupa; never starts FXServer or SQL."""
from pathlib import Path
import os, re, subprocess, sys
from lupa.lua54 import LuaRuntime
ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
def read(path): return (ROOT / path).read_text(encoding='utf-8-sig')
def normalize(s):
    # FiveM syntax translation for parsing/harness only. Source files remain untouched.
    s = re.sub(r'`[A-Za-z0-9_]+`', '0', s)
    lhs = r'[A-Za-z_]\w*(?:\[[^\]\n]+\]|\.\w+)*'
    s = re.sub(r'('+lhs+r'(?:\([^\n]*?\))?)\?\.', r'(\1 or {}).', s)
    s = re.sub(r'('+lhs+r')\s*([+*/-])=\s*', r'\1 = \1 \2 ', s)
    return s

def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(COMMON)
    return lua

def section(path,start,end):
    s=read(path); return s[s.index(start):s.index(end,s.index(start))]

COMMON = r"""
now, tasks, timers = 0, {}, {}
function GetGameTimer() return now end
function Wait(ms) return coroutine.yield({tick=true, delay=ms}) end
function SetTimeout(ms, fn) timers[#timers+1] = {ms=ms, fn=fn} end
function spawn(fn)
    local task = {co=coroutine.create(fn)}; tasks[#tasks+1]=task; return task
end
function pump()
    for _=1,1000 do
        local progress=false
        for _,task in ipairs(tasks) do
            if not task.dead and (not task.wait or task.wait.done or task.wait.tick) then
                local wait=task.wait
                local ok,value=coroutine.resume(task.co,wait and wait.value)
                assert(ok,value)
                task.dead=coroutine.status(task.co)=='dead';task.wait=value
                progress=true
            end
        end
        if not progress then return end
    end
    error('harness did not quiesce')
end
promise={new=function()
    return {resolve=function(self,v) self.done=true; self.value=v end}
end}
Citizen={Await=function(p)
    if p.done then return p.value end
    return coroutine.yield(p)
end, CreateThreadNow=spawn, CreateThread=spawn, Wait=Wait, SetTimeout=SetTimeout}
function CreateThread(fn) return spawn(fn) end
function GetConvarInt(_, default) return default end
function GetCurrentResourceName() return 'test' end
function AddEventHandler() end
function RegisterNetEvent() end
function RegisterServerEvent() end
function RegisterCommand() end
function TriggerClientEvent() end
lib={print={error=function() end}, callback={register=function() end}}
json={encode=function(v)
    if type(v)~='table' then return tostring(v) end
    local keys={};for k in pairs(v) do keys[#keys+1]=k end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    local result={};for _,k in ipairs(keys) do result[#result+1]=tostring(k)..'='..json.encode(v[k]) end
    return '{'..table.concat(result,',')..'}'
end}
"""

# Parse changed Lua, plus restored source. Does not pretend this is a FiveM runtime test.
paths=subprocess.check_output(['git','diff','--name-only','3b4dec68795d82e54de8a266b5c716562dd99958'],text=True).splitlines()
paths += ['[standalone]/illenium-appearance/server/server.lua']
parser=LuaRuntime(unpack_returned_tuples=True).eval('function(s,n) local f,e=load(s,n);return f~=nil,e end')
for path in sorted(set(paths)):
    if path.endswith('.lua'):
        ok,err=parser(normalize(read(path)), '@'+path)
        assert ok,err
print('PASS changed Lua syntax (FiveM extensions normalized only in memory)')

# Run full existing airdrop gameplay harness, extended with disconnect coalescing.
os.chdir(ROOT/'[GANG]/vx_airdrop')
LuaRuntime().execute(read('[GANG]/vx_airdrop/tests/server-kill-score.lua'))
os.chdir(ROOT)

# Daily SQL locking: unrelated characters progress; nested same-character calls don't deadlock;
# an error releases the lock, allowing queued operations to finish.
lua=runtime()
lua.execute("Config={SQLScript='oxmysql'}; MySQL={query={await=function() return {} end}}")
lua.execute(read('[standalone]/Tipi_Daily_Rewards/server/sql.lua'))
lua.execute(r"""
local gate=promise.new();local result={}
spawn(function() WithDailyOnlineLock('a',function()
    Citizen.Await(gate)
    WithDailyOnlineLock('a',function() result[#result+1]='nested' end)
    error('SQL failed')
end) end)
-- catch the expected failed caller while still exercising its queued successor
local first=tasks[1]; local original=first.co
first.co=coroutine.create(function()
    -- direct pcall must execute the original function in the same coroutine
    local ok=pcall(function() WithDailyOnlineLock('a',function()
        Citizen.Await(gate)
        WithDailyOnlineLock('a',function() result[#result+1]='nested' end)
        error('SQL failed')
    end) end)
    assert(not ok)
end)
spawn(function() WithDailyOnlineLock('a',function() result[#result+1]='after' end) end)
spawn(function() WithDailyOnlineLock('b',function() result[#result+1]='other' end) end)
pump();assert(#result==1 and result[1]=='other')
gate:resolve(true);pump();assert(table.concat(result,',')=='other,nested,after')
""")
print('PASS daily character locks: concurrency, reentrancy, error release')

# Actual DB adapter: preserve FIFO across periodic/disconnect saves and fence reconnect reads.
lua=runtime()
lua.execute(r"""
lib={print={error=function()end}}; shared={framework='qbx'}; server={bulkstashsave=false}
exports=function()end
calls={};gate=promise.new();shouldFail=false
MySQL={transaction={await=function(statements)
    calls[#calls+1]=statements[1].values[1]
    if #calls==1 then Citizen.Await(gate) end
    if shouldFail then return false end
    return true
end},prepare={await=function() calls[#calls+1]='load';return nil end}}
""")
# Skip startup schema probes, which are not part of this regression test.
chunk=section('[ox]/ox_inventory/modules/mysql/server.lua','db = {}','---@param rows')
lua.execute('local Query={UPDATE_PLAYER="player",SELECT_PLAYER="select",UPSERT_STASH="stash",UPDATE_TRUNK="trunk",UPDATE_GLOVEBOX="glove"}\n'+chunk)
lua.execute(r"""
spawn(function() assert(db.savePlayer('cid','old')) end)
spawn(function() assert(db.savePlayer('cid','new')) end)
spawn(function() db.loadPlayer('cid') end)
pump();assert(#calls==1 and calls[1]=='old')
gate:resolve(true);pump();assert(table.concat(calls,',')=='old,new,load')
shouldFail=true;spawn(function() assert(db.savePlayer('cid','failed')==false) end);pump()
shouldFail=false;spawn(function() assert(db.savePlayer('cid','recovered')) end);pump()
""")
print('PASS inventory SQL FIFO, reconnect fence and failure release')

# Periodic saver: multiple chunks; writes during SQL remain dirty; failed chunks remain dirty.
lua=runtime()
lua.execute(r"""
Inventories={};Inventory={Remove=function()error('must not remove dirty inventory')end}
Items=setmetatable({UpdateDurability=function()return false end},{__call=function()return {} end})
function table.wipe(t) for k in pairs(t) do t[k]=nil end end
shared={framework='qbx'};server={bulkstashsave=false}
local function make(i) return {id=i,owner='cid'..i,player=true,changed=true,items={{name='item',count=i,metadata={}}}} end
for i=1,45 do Inventories[i]=make(i) end
batchSizes={};db={saveInventories=function(p,t,g,s,total)
    batchSizes[#batchSizes+1]=total[5]
    for _,row in ipairs(p) do
        if row[2]=='cid1' then Inventories[1].changed=true end
    end
    return not failBatch
end}
""")
code=section('[ox]/ox_inventory/modules/inventory/server.lua','local function prepareInventorySave','\nlib.cron.new(\'*/5')
lua.execute(normalize(code)+'\nSaveUnderTest=saveInventories')
lua.execute(r"""
spawn(function() assert(SaveUnderTest(false)) end);pump()
assert(#batchSizes>=3);for _,n in ipairs(batchSizes) do assert(n<=20) end
assert(Inventories[1].changed==true,'new writes must remain dirty')
for i=2,45 do assert(Inventories[i].changed==false) end
Inventories[2].changed=true;failBatch=true
spawn(function() assert(not SaveUnderTest(true)) end);pump()
assert(Inventories[1].changed and Inventories[2].changed)
failBatch=false;spawn(function() assert(SaveUnderTest(false)) end);pump()
""")
print('PASS inventory chunk bounds, concurrent dirtiness, failed-save retention and retry')

# Backend appearance transaction is atomic and serializes by character.
lua=runtime()
lua.execute(r"""
Framework={};calls={};gate=promise.new()
MySQL={transaction={await=function(statements)
    assert(#statements==3)
    local values=statements[3].values
    calls[#calls+1]=values[3]
    if #calls==1 then Citizen.Await(gate) end
    return not fail
end}}
""")
chunk=section('[standalone]/illenium-appearance/server/framework/qb/main.lua','local appearanceWrites','\nfunction Framework.GetAppearance')
lua.execute(chunk)
lua.execute(r"""
spawn(function() assert(Framework.SaveAppearance({model='first'},'cid')) end)
spawn(function() assert(Framework.SaveAppearance({model='second'},'cid')) end)
pump();assert(#calls==1)
gate:resolve(true);pump();assert(#calls==2 and calls[2]:find('second'))
fail=true;spawn(function() assert(not pcall(Framework.SaveAppearance,{model='fail'},'cid')) end);pump()
fail=false;spawn(function() assert(Framework.SaveAppearance({model='recover'},'cid')) end);pump()
""")
print('PASS appearance transaction ordering and failed-save lock release')


# Boombox: check rights without retrieving the full framework.
lua=runtime()
lua.execute(r"""
Config={AdminGroups={'admin','god'}};aces={};metadata={};lookups=0
function IsPlayerAceAllowed(_,name) return aces[name]==true end
exports={qbx_core={GetPlayer=function()lookups=lookups+1;return {PlayerData=metadata}end}}
setmetatable(exports,{__index=function() error('full framework lookup is forbidden')end})
""")
lua.execute(section('[XN_CODE]/1307_Boombox/server/main.lua','local function IsAdmin','local function setAdminState')+'\nCheckAdmin=IsAdmin')
lua.execute(r"""
assert(CheckAdmin(0));assert(not CheckAdmin(4))
aces['group.admin']=true;assert(CheckAdmin(4));aces={}
metadata.permissions={god=true};assert(CheckAdmin(4))
metadata={permission='admin'};assert(CheckAdmin(4))
metadata={};assert(not CheckAdmin(4),'revocation must be immediate')
""")
print('PASS boombox permission equivalence and immediate revocation without core serialization')

# HUD: targeted ping and one authoritative metadata write.
lua=runtime()
lua.execute(r"""
handlers={};sent={};callbacks={};stressWrites=0;fallbackWrites=0;states={}
lib.callback.register=function(name,fn)callbacks[name]=fn end
function AddEventHandler(name,fn)handlers[name]=fn end
function GetPlayers()return {'1','2'}end
function GetNumPlayerIndices()return 2 end
function GetPlayerPing(src)return tonumber(src)*10 end
function Player(src)
    states[src]=states[src] or {set=function(self,key,value)self[key]=value end}
    return {state=states[src]}
end
function GetResourceState()return 'started'end
function getPlayer()return {PlayerData={metadata={stress=0}},Functions={SetMetaData=function()fallbackWrites=fallbackWrites+1 end}}end
local ex={qbx_core={SetPlayerMetadata=function()stressWrites=stressWrites+1 end,GetPlayer=getPlayer}}
exports=setmetatable(ex,{__call=function(_,name,fn)ex[name]=fn end})
WS={TriggerClientEvent=function(name,target,data)sent[#sent+1]={target=target,data=data}end}
Config={UseStress=true}
""")
lua.execute(read('[UI]/Tipi_hud/server/server.lua'))
lua.execute(r"""
local co=tasks[1].co
assert(coroutine.resume(co));assert(coroutine.resume(co))
assert(#sent==2 and sent[1].target==1 and sent[2].target==2)
assert(sent[1].data.ping==10 and sent[2].data.ping==20 and not sent[1].data.pings)
exports.setStress(1,25)
assert(stressWrites==1 and fallbackWrites==0 and states[1].stress==25)
source=1;handlers['tipi-hud:gainStress'](5)
assert(stressWrites==2,'handler must not call a shadowed Player table')
""")
print('PASS HUD targeted ping and single metadata write')

# Grappler: owner transfers and deleted entries cannot leak into another scope.
lua=runtime()
lua.execute(r"""
handlers={};sent={};entities={[101]=1001,[102]=1002}
function AddEventHandler(name,fn)handlers[name]=fn end
function SetConvarReplicated()end
function NetworkGetEntityFromNetworkId(id)return entities[id] or 0 end
function TriggerClientEvent(name,target,data,netId)sent[#sent+1]={name=name,target=target,data=data,id=netId}end
grapplerCommand={enabled=false}
""")
lua.execute(read('[qbx]/[POLICETOOL]/Police_Grappler/sv_grappler.lua'))
lua.execute(r"""
source=1;handlers['Server:updateGrapplerTable'](eventKey,101,'installed','car')
source=2;handlers['Server:updateGrapplerTable'](eventKey,102,'installed','car')
sent={};handlers.playerEnteredScope({player='9',['for']='1'})
assert(#sent==1 and sent[1].data[101] and not sent[1].data[102])
source=2;handlers['Server:updateGrapplerTable'](eventKey,101,'installed','car')
sent={};handlers.playerEnteredScope({player='9',['for']='1'});assert(#sent==0)
handlers['Server:updateGrapplerTable'](eventKey,101,'inactive')
assert(not grapplers[101])
source=2;handlers.playerDropped();assert(not next(grapplers))
""")
print('PASS grappler scope index, owner transfer and disconnect cleanup')

# Hook: aggregation is exact, detail expires and off bypasses collection.
lua=runtime()
lua.execute(r"""
isDuplicityVersion=true;mode='off';untilTime=0;batches={};table_pack=table.pack;table_unpack=table.unpack
function GetConvar(_,fallback)return mode or fallback end
function GetConvarInt()return untilTime end
function GetResourceState()return 'started'end
function GetInvokingResource()return 'caller'end
function msgpack_pack_args(batch)batch.len=function()return 1 end;return batch end
function TriggerEventInternal(_,payload)batches[#batches+1]=payload end
""")
lua.execute(read('[standalone]/vx_runtime_monitor/patch/scheduler-hook.lua')+'\nHook={push=vxMonitorPush,flush=vxMonitorFlush,refresh=vxMonitorRefreshMode,wrap=vxMonitorWrapExport}')
lua.execute(r"""
local fn=Hook.wrap('test',function()return 1,nil,3 end)
local a,b,c=fn();assert(a==1 and b==nil and c==3)
mode='light';Hook.refresh()
for _=1,10000 do Hook.push('event','handler','scope',nil,5,10,1,'ok')end
Hook.flush();assert(#batches==1 and #batches[1].records==1 and batches[1].records[1].count==10000)
mode='detail';untilTime=os.time()+60;Hook.refresh()
Hook.push('event','handler','scope',nil,5,10,1,'ok');Hook.flush()
assert(batches[#batches].records[1].playerSessionId==5)
untilTime=0;Hook.refresh()
Hook.push('event','handler','scope',nil,5,10,1,'ok');Hook.flush()
assert(batches[#batches].records[1].aggregate==true)
mode='off';Hook.refresh();local count=#batches
for _=1,10000 do Hook.push('event','handler','scope',nil,5,10,1,'ok')end
fn();Hook.flush();assert(#batches==count)
mode='light';Hook.refresh()
local send=TriggerEventInternal
TriggerEventInternal=function()error('collector unavailable')end
for _=1,10000 do Hook.push('event','handler','scope',nil,5,10,1,'ok')end
Hook.flush();TriggerEventInternal=send
Hook.push('event','handler','scope',nil,5,10,1,'ok');Hook.flush()
assert(batches[#batches].dropped==10000,'dropped aggregates must count events, not groups')
""")
print('PASS monitor hook exact aggregation, detail expiry, off fast path and return values')


# Daily counters retain failed writes and previous-day minutes through midnight.
lua=runtime()
lua.execute(r"""
Config={MonthClaimMinMinutes=2};DailyOnlineRows={};saved={};dateKey='2026-10-25';fail=false
os.date=function() return dateKey end
function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
json.encode=copy
function decodeJson(v,fallback) return v or fallback end
function ExecuteSql(query,args)
    if query:find('SELECT') then return {{daily_online=copy(saved)}} end
    if fail then error('database unavailable')end
    if query:find('UPDATE') then saved=copy(args[1]) end
    return 1
end
function WithDailyOnlineLock(_,fn,...)return fn(...)end
""")
s=read('[standalone]/Tipi_Daily_Rewards/server/online.lua')
lua.execute(s[:s.index('local onlineSources = {}')]+'\nTestCache=OnlineCache')
lua.execute(r"""
local minutes,ready=OnlineAddMinute('cid',1)
assert(minutes==1 and not ready and saved[dateKey].minutes==1)
fail=true;minutes,ready=OnlineAddMinute('cid',2)
assert(minutes==3 and ready and saved[dateKey].minutes==1 and TestCache.cid.dirty)
-- Same cached record is retained after disconnect until its retry succeeds.
TestCache.cid.disconnected=true;fail=false;dateKey='2026-10-26'
timers[1].fn();assert(saved['2026-10-25'].minutes==3 and not TestCache.cid)
OnlineAddMinute('cid',1)
assert(saved['2026-10-25'].minutes==3 and saved['2026-10-26'].minutes==1)
""")
print('PASS daily failed-write retry, disconnect retention and midnight rollover')

# Appearance burst replaces pending snapshots, but never loses a newer in-flight update.
lua=runtime()
lua.execute(r"""
handlers={};saved={};gate=promise.new();fail=false
function RegisterServerEvent(name,fn)handlers[name]=fn end
function AddEventHandler(name,fn)handlers[name]=fn end
Framework={GetPlayerID=function()return 'cid'end,SaveAppearance=function(value)
    if fail then error('SQL unavailable')end
    saved[#saved+1]=value.model
    if value.model=='first' then Citizen.Await(gate)end
    return true
end}
""")
lua.execute(section('[standalone]/illenium-appearance/server/server.lua','local appearanceQueue','\nRegisterServerEvent("illenium-appearance:server:chargeCustomer"'))
lua.execute(r"""
source=1;local save=handlers['illenium-appearance:server:saveAppearance']
save({model='discarded'});save({model='first'})
spawn(timers[1].fn);pump();assert(#saved==1 and saved[1]=='first')
save({model='middle'});save({model='latest'})
gate:resolve(true);pump();assert(#saved==2 and saved[2]=='latest')
save({model='latest'});spawn(timers[#timers].fn);pump();assert(#saved==2,'unchanged payload must not write again')
fail=true;save({model='retry'});spawn(timers[#timers].fn);pump();assert(#saved==2)
fail=false;spawn(timers[#timers].fn);pump();assert(#saved==3 and saved[3]=='retry')
save({model='disconnect'});spawn(handlers.playerDropped);pump();assert(saved[#saved]=='disconnect')
""")
print('PASS appearance coalescing, in-flight latest update, deduplication, SQL retry and disconnect flush')

# Motel client overlays cannot overwrite a newer authoritative full snapshot.
lua=runtime()
lua.execute(r"""
GlobalState={Motels={hotel={rooms={[1]={trashCount=2,lastCleaned=10}}}},
 ['MotelCleaning:hotel']={['1']={trashCount=0,lastCleaned=20}}}
function AddStateBagChangeHandler(_,_,fn)stateHandler=fn end
""")
s=read('[XN_CODE]/xn_motels/client/main.lua');lua.execute(s[:s.index('local kvpname')])
lua.execute(r"""
assert(GetMotelSnapshot().hotel.rooms[1].trashCount==0)
stateHandler('global','Motels',{hotel={rooms={[1]={trashCount=5,lastCleaned=20}}}})
assert(GetMotelSnapshot().hotel.rooms[1].trashCount==5,'old cleaning delta must not erase newly accumulated trash')
stateHandler('global','MotelCleaning:hotel',{['1']={trashCount=0,lastCleaned=19}})
assert(GetMotelSnapshot().hotel.rooms[1].trashCount==5)
stateHandler('global','MotelCleaning:hotel',{['1']={trashCount=0,lastCleaned=21}})
assert(GetMotelSnapshot().hotel.rooms[1].trashCount==0)
""")
print('PASS motel delta merge and stale-delta rejection')

# Motel server coalesces room saves, validates bucket and retains failed writes.
lua=runtime()
lua.execute(r"""
GlobalState={};ServerMotels={hotel={rooms={[1]={trashCount=1,lastCleaned=1},[2]={trashCount=1,lastCleaned=1}}}}
routings={[1]=0};callbacks={};bucket=10001;writes=0;fail=false
lib.callback.register=function(name,fn)callbacks[name]=fn end
function GetMotelUniqueId()return 1 end
function GetPlayerRoutingBucket()return bucket end
function GetPlayerFromId()return {name='test'}end
function LogCleanup()end
MySQL={update={await=function()if fail then error('offline')end;writes=writes+1;return 1 end}}
""")
lua.execute(section('[XN_CODE]/xn_motels/server/main.lua','local cleaningStates, cleaningWrites','lib.callback.register(\'renzu_motels:autoCleanRoom\''))
lua.execute(r"""
local clean=callbacks['renzu_motels:cleanTrashPile']
assert(clean(1,'hotel',0)==nil and clean(1,'hotel',1.5)==nil)
assert(clean(1,'hotel',2)==nil and ServerMotels.hotel.rooms[2].trashCount==1)
assert(clean(1,'hotel','01')==true)
now=4000;bucket=10002;assert(clean(1,'hotel',2)==true)
assert(#timers==1 and writes==0)
fail=true;spawn(timers[1].fn);pump();assert(writes==0 and #timers==2)
fail=false;spawn(timers[2].fn);pump();assert(writes==1)
assert(GlobalState.Motels==nil and GlobalState['MotelCleaning:hotel']['2'].trashCount==0)
""")
print('PASS motel bucket validation, coalesced persistence and SQL retry')


# Disconnect while a periodic save is in flight must retain the inventory on SQL failure.
lua=runtime()
lua.execute(r"""
Inventories={};activeIdentifiers={cid=1};exports=function()end
Inventory=setmetatable({},{__call=function(_,v)return type(v)=='table' and v or Inventories[v]end})
Items=setmetatable({UpdateDurability=function()return false end},{__call=function()return {}end})
function table.wipe(t)for k in pairs(t)do t[k]=nil end end
shared={framework='qbx'};server={bulkstashsave=false};gate=promise.new();fail=true
Inventories[1]={id=1,owner='cid',player=true,changed=true,openedBy={},items={{name='item',count=9,metadata={}}}}
db={saveInventories=function()Citizen.Await(gate);return not fail end,savePlayer=function()return not fail end}
""")
lua.execute(normalize(section('[ox]/ox_inventory/modules/inventory/server.lua','function Inventory.Save(inv)','\n---@alias RandomLoot')))
lua.execute(normalize(section('[ox]/ox_inventory/modules/inventory/server.lua','function Inventory.Remove(inv)',"exports('RemoveInventory'")))
lua.execute(normalize(section('[ox]/ox_inventory/modules/inventory/server.lua','local function prepareInventorySave',"\nlib.cron.new('*/5"))+'\nSaveUnderTest=saveInventories')
lua.execute(r"""
spawn(function()SaveUnderTest(false)end);pump()
assert(Inventories[1].savePending and not Inventories[1].changed)
spawn(function()Inventory.Remove(1)end);pump()
assert(Inventories[1] and activeIdentifiers.cid==1,'disconnect must wait on periodic save')
gate:resolve(true);pump()
assert(Inventories[1] and Inventories[1].changed and activeIdentifiers.cid==1,'failure must retain recoverable inventory')
fail=false;spawn(function()Inventory.Remove(1)end);pump()
assert(not Inventories[1] and not activeIdentifiers.cid,'successful retry can release identity')
""")
print('PASS disconnect during periodic save: SQL failure retains inventory and successful retry releases it')


# Paychecks: one society debit, re-entry rejected, insufficient balance pays nobody.
lua=runtime()
lua.execute(r"""
ex={};exports=function(name,fn)ex[name]=fn end
function CreateThread()end
function require()return config end
function GetJob()return {grades={[0]={payment=100}},offDutyPay=false}end
function locale(name)return name end
function Notify()end
QBX={Players={}}
for src=1,2 do QBX.Players[src]={PlayerData={job={name='police',grade={level=0},onduty=true}},paid=0}end
balance=1000;debits=0
config={money={paycheckSociety=true,paycheckTimeout=10},
getSocietyAccount=function()return balance end,
removeSocietyMoney=function(_,amount)debits=debits+1;balance=balance-amount;return true end,
sendPaycheck=function(player,amount)
    assert(ex.ProcessPaychecks()==false,'a nested payroll must not start')
    player.paid=player.paid+amount
end}
""")
lua.execute(normalize(read('[qbx]/qbx_core/server/loops.lua')))
lua.execute(r"""
spawn(function()assert(ex.ProcessPaychecks())end);pump()
assert(debits==1 and balance==800 and QBX.Players[1].paid==100 and QBX.Players[2].paid==100)
balance=0;spawn(function()assert(ex.ProcessPaychecks())end);pump()
assert(debits==1 and QBX.Players[1].paid==100 and QBX.Players[2].paid==100)
assert(ex.GetPaycheckProfile().payment.calls==2)
""")
print('PASS paycheck re-entry guard, one society debit, payout amounts and insufficient funds')
