-- VX_RUNTIME_MONITOR_HOOK_V1_BEGIN
local vxMonitorResource = isDuplicityVersion and GetCurrentResourceName() or nil
local vxMonitorEligible = vxMonitorResource and vxMonitorResource ~= 'vx_runtime_monitor'
local vxMonitorEnabled = false
local vxMonitorMode = 'off'
local vxMonitorGroups = {}
local vxMonitorGroupCount = 0
local vxMonitorEvent = '__vx_runtime_monitor:batch'
local vxMonitorQueue = {}
local vxMonitorCount = 0
local vxMonitorDropped = 0
local vxMonitorLastHeartbeat = 0
local vxMonitorMaxQueue = 4096
local vxMonitorFlush

local function vxMonitorPlayer(value)
	local player = tonumber(value)
	if player and player > 0 then return player end
	if type(value) == 'string' then
		return tonumber(value:match('^net:(%d+)$') or value:match('^internal%-net:(%d+)$'))
	end
	return nil
end

local function vxMonitorIgnore(name)
	return type(name) ~= 'string' or name == vxMonitorEvent or name:sub(1, 13) == '__cfx_export_'
end

local function vxMonitorPush(kind, phase, name, target, player, bytes, wall, status, caller)
	if not vxMonitorEnabled or vxMonitorIgnore(name) then return end
	if vxMonitorMode == 'light' then
		local key = table.concat({kind, phase, name, target or '', status or '', caller or '', player == -1 and 'broadcast' or 'targeted'}, '\0')
		local item = vxMonitorGroups[key]
		if item then
			item.count = item.count + 1
			item.payloadBytes = (item.payloadBytes or 0) + (bytes or 0)
			item.wallMs = math.max(item.wallMs or 0, wall or 0)
		else
			if vxMonitorGroupCount >= 512 then vxMonitorDropped = vxMonitorDropped + 1 return end
			vxMonitorGroupCount = vxMonitorGroupCount + 1
			vxMonitorGroups[key] = {kind = kind, phase = phase, name = name, resource = vxMonitorResource,
				targetResource = target, callerResource = caller, status = status, count = 1, aggregate = true,
				targeted = (phase == 'send-client' or phase == 'send-latent') and player ~= -1,
				payloadBytes = bytes, wallMs = wall, monoMs = GetGameTimer()}
		end
		return
	end
	if vxMonitorCount >= vxMonitorMaxQueue then
		vxMonitorDropped = vxMonitorDropped + 1
		return
	end
	vxMonitorCount = vxMonitorCount + 1
	vxMonitorQueue[vxMonitorCount] = {
		kind = kind, phase = phase, name = name,
		resource = vxMonitorResource, targetResource = target,
		playerSessionId = vxMonitorPlayer(player),
		payloadBytes = bytes, wallMs = wall, status = status,
		callerResource = caller, monoMs = GetGameTimer()
	}
	if vxMonitorCount == 1 then Citizen.SetTimeout(200, vxMonitorFlush) end
	if vxMonitorCount == 256 then Citizen.SetTimeout(0, vxMonitorFlush) end
end

vxMonitorFlush = function()
	if not vxMonitorEnabled then return end
	for _, item in pairs(vxMonitorGroups) do
		vxMonitorCount = vxMonitorCount + 1
		vxMonitorQueue[vxMonitorCount] = item
	end
	vxMonitorGroups, vxMonitorGroupCount = {}, 0
	local now = GetGameTimer()
	if vxMonitorCount == 0 and now - vxMonitorLastHeartbeat < 5000 then return end
	vxMonitorLastHeartbeat = now
	local batch = vxMonitorQueue
	local eventCount = 0
	for _, item in ipairs(batch) do eventCount = eventCount + (item.count or 1) end
	vxMonitorQueue = {}
	vxMonitorCount = 0
	if GetResourceState('vx_runtime_monitor') ~= 'started' then
		vxMonitorDropped = vxMonitorDropped + eventCount
		return
	end
	local ok = pcall(function()
		local payload = msgpack_pack_args({resource = vxMonitorResource, records = batch, dropped = vxMonitorDropped, monoMs = now})
		TriggerEventInternal(vxMonitorEvent, payload, payload:len())
	end)
	if not ok then vxMonitorDropped = vxMonitorDropped + eventCount end
end

local function vxMonitorWrapExport(name, fn)
	if not vxMonitorEligible or type(fn) ~= 'function' then return fn end
	return function(...)
		if not vxMonitorEnabled then return fn(...) end
		local started = GetGameTimer()
		local caller = GetInvokingResource()
		local result = table_pack(xpcall(fn, debug.traceback, ...))
		vxMonitorPush('export', 'invoke', name, nil, _G.source, nil,
			GetGameTimer() - started, result[1] and 'ok' or 'error', caller)
		if not result[1] then error(result[2], 0) end
		return table_unpack(result, 2, result.n)
	end
end

local function vxMonitorRefreshMode()
	local mode = GetConvar('vx_monitor_mode', 'light')
	if mode == 'detail' and GetConvarInt('vx_monitor_detail_until', 0) <= os.time() then mode = 'light' end
	if mode ~= 'detail' and mode ~= 'light' then mode = 'off' end
	local enabled = vxMonitorEligible and mode ~= 'off' and GetResourceState('vx_runtime_monitor') == 'started'
	if vxMonitorEnabled and (not enabled or mode ~= vxMonitorMode) then vxMonitorFlush() end
	vxMonitorMode, vxMonitorEnabled = mode, enabled
	if not enabled then
		vxMonitorQueue, vxMonitorCount, vxMonitorGroups, vxMonitorGroupCount = {}, 0, {}, 0
	end
end

if vxMonitorEligible then
	vxMonitorRefreshMode()
	local function vxMonitorHeartbeat()
		vxMonitorRefreshMode()
		vxMonitorFlush()
		Citizen.SetTimeout(1000, vxMonitorHeartbeat)
	end
	Citizen.SetTimeout(1000, vxMonitorHeartbeat)
end
-- VX_RUNTIME_MONITOR_HOOK_V1_END
