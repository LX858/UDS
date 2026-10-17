'use strict';

const fs = require('fs');
const http = require('http');
const path = require('path');
const crypto = require('crypto');
const { MonitorStore } = require('./store');

const RESOURCE = GetCurrentResourceName();
const ROOT = GetResourcePath(RESOURCE);
const store = new MonitorStore(ROOT);
const host = GetConvar('vx_monitor_host', '127.0.0.1');
const port = Number.parseInt(GetConvar('vx_monitor_port', '32190'), 10);
const token = GetConvar('vx_monitor_token', '');
const bootTime = Date.now();
const schedulerPath = path.resolve(GetConvar('vx_monitor_scheduler_path',
  'C:/Users/Administrator/Desktop/UNS/antifact/citizen/scripting/lua/scheduler.lua'));
const rate = new Map();
let server;

function safeNative(callback, fallback = null) {
  try { return callback(); } catch { return fallback; }
}

function playerId(value) {
  const id = Number(value);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

function currentSource(fallback) {
  return playerId(global.source) || playerId(fallback);
}

function capturePlayer(id) {
  if (!id) return null;
  const name = safeNative(() => GetPlayerName(String(id))) || store.players.get(id)?.name || null;
  store.upsertPlayer(id, name);
  return name;
}

function captureEntity(handle) {
  handle = Number(handle);
  if (!Number.isSafeInteger(handle) || handle <= 0) return null;
  const typeId = safeNative(() => GetEntityType(handle));
  const type = ({ 1: 'ped', 2: 'vehicle', 3: 'object' })[typeId];
  if (!type) return null;
  const owner = safeNative(() => NetworkGetEntityOwner(handle));
  const model = safeNative(() => GetEntityModel(handle));
  const netId = safeNative(() => NetworkGetNetworkIdFromEntity(handle));
  return {
    handle,
    type,
    model: Number.isSafeInteger(model) && model !== 0 ? model : null,
    netId: playerId(netId),
    owner: playerId(owner),
    resource: safeNative(() => GetEntityScript(handle)) || null,
    seenAt: new Date().toISOString(),
  };
}

async function snapshot() {
  for (const value of safeNative(() => GetPlayers(), [])) capturePlayer(playerId(value));
  let checked = 0;
  for (const [type, getter] of [
    ['object', () => GetAllObjects()],
    ['ped', () => GetAllPeds()],
    ['vehicle', () => GetAllVehicles()],
  ]) {
    for (const handle of safeNative(getter, [])) {
      const entity = captureEntity(handle);
      if (entity) { entity.type = type; store.upsertEntity(entity); }
      if (++checked % 250 === 0) await new Promise(resolve => setImmediate(resolve));
    }
  }
}

function lifecycle(kind, phase, name, fields = {}) {
  store.record({ kind, phase, name, resource: RESOURCE, status: 'ok', ...fields });
}

on('__vx_runtime_monitor:batch', batch => store.acceptBatch(batch));

on('playerConnecting', (name, _setKickReason, _deferrals) => {
  const id = currentSource();
  lifecycle('player', 'connecting', 'playerConnecting', { playerSessionId: id, playerName: name });
});

on('playerJoining', (id) => {
  const finalId = currentSource(id);
  const name = capturePlayer(finalId);
  lifecycle('player', 'joined', 'playerJoining', { playerSessionId: finalId, playerName: name });
});

on('playerDropped', () => {
  const id = currentSource();
  const name = id && store.players.get(id)?.name;
  lifecycle('player', 'dropped', 'playerDropped', { playerSessionId: id, playerName: name });
  if (id) store.removePlayer(id);
});

on('entityCreated', (handle) => {
  setTimeout(() => {
    const entity = captureEntity(handle);
    if (!entity) return;
    store.upsertEntity(entity);
    lifecycle('entity', 'created', entity.type, { entityNetId: entity.netId, targetResource: entity.resource });
  }, 0);
});

on('entityRemoved', (handle) => {
  const entity = store.removeEntity(handle);
  lifecycle('entity', 'removed', entity?.type || 'unknown', {
    entityNetId: entity?.netId ?? null,
    targetResource: entity?.resource || null,
  });
});

on('onResourceStart', (name) => {
  lifecycle('resource', 'started', name);
});

on('onResourceStop', (name) => {
  lifecycle('resource', 'stopped', name);
  store.agents.delete(name);
  if (name === RESOURCE) {
    if (server) server.close();
    store.stop().catch(error => console.error(`[vx_runtime_monitor] Shutdown flush failed: ${error.message}`));
  }
});

function hookPresent() {
  return safeNative(() => fs.readFileSync(schedulerPath, 'utf8').includes('VX_RUNTIME_MONITOR_HOOK_V1_BEGIN'), false);
}

function health() {
  const now = Date.now();
  const fresh = [...store.agents.values()].filter(agent => now - agent.lastSeen <= 15000).length;
  const patched = hookPresent();
  const warming = now - bootTime < 15000;
  return {
    status: !patched || (!warming && fresh === 0) || store.diskError ? 'degraded' : warming ? 'warming' : 'ok',
    schedulerHookPresent: patched,
    freshAgents: fresh,
    knownAgents: store.agents.size,
    queue: store.queue.length,
    dropped: { agents: store.droppedAgents, agentsInitial: store.droppedAgentsInitial,
      agentsAfterStart: store.droppedAgentsAfterStart, collector: store.droppedCollector, disk: store.droppedDisk },
    diskError: store.diskError,
    uptimeSeconds: Math.floor((now - bootTime) / 1000),
  };
}

function allowedAddress(address) {
  const ip = String(address || '').replace(/^::ffff:/, '');
  return ip === '127.0.0.1' || ip === '::1';
}

function authorized(req) {
  if (token.length < 32) return false;
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return false;
  const supplied = Buffer.from(header.slice(7), 'utf8');
  const expected = Buffer.from(token, 'utf8');
  return supplied.length === expected.length && crypto.timingSafeEqual(supplied, expected);
}

function limited(ip) {
  const now = Date.now();
  const item = rate.get(ip);
  if (!item || now - item.since >= 60000) {
    rate.set(ip, { since: now, count: 1 });
    return false;
  }
  item.count++;
  return item.count > 600;
}

function response(res, status, data) {
  const text = JSON.stringify(data);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(text),
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
  });
  res.end(text);
}

function staticFile(res, file, mime) {
  fs.readFile(path.join(ROOT, 'web', file), (error, data) => {
    if (error) return response(res, 404, { error: 'not_found' });
    res.writeHead(200, {
      'Content-Type': mime,
      'Content-Length': data.length,
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
      'Content-Security-Policy': "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self'; frame-ancestors 'none'",
    });
    res.end(data);
  });
}

async function handle(req, res) {
  const ip = String(req.socket.remoteAddress || '');
  if (!allowedAddress(ip)) return response(res, 403, { error: 'network_denied' });
  if (limited(ip)) return response(res, 429, { error: 'rate_limited' });
  if (req.method !== 'GET') return response(res, 405, { error: 'method_not_allowed' });
  const url = new URL(req.url, `http://${host}:${port}`);
  if (url.pathname === '/') return staticFile(res, 'index.html', 'text/html; charset=utf-8');
  if (url.pathname === '/app.css') return staticFile(res, 'app.css', 'text/css; charset=utf-8');
  if (url.pathname === '/app.js') return staticFile(res, 'app.js', 'application/javascript; charset=utf-8');
  if (!authorized(req)) return response(res, 401, { error: 'unauthorized' });
  const query = Object.fromEntries(url.searchParams.entries());
  for (const key of ['kind', 'phase', 'resource', 'targetResource', 'status', 'name', 'search', 'type']) {
    if (query[key] && query[key].length > 160) return response(res, 400, { error: 'filter_too_long' });
  }
  if (url.pathname === '/health') return response(res, 200, health());
  if (url.pathname === '/summary') return response(res, 200, store.summary());
  if (url.pathname === '/players') return response(res, 200, store.listPlayers(query));
  if (url.pathname === '/entities') return response(res, 200, store.listEntities(query));
  if (url.pathname === '/stats') {
    if (query.name && query.name.length > 160) return response(res, 400, { error: 'filter_too_long' });
    try { return response(res, 200, await store.stats.get(query)); }
    catch (error) {
      if (error instanceof RangeError) return response(res, 400, { error: error.message });
      throw error;
    }
  }
  if (url.pathname === '/records') {
    if (query.from && !Number.isFinite(Date.parse(query.from))) return response(res, 400, { error: 'invalid_from' });
    if (query.to && !Number.isFinite(Date.parse(query.to))) return response(res, 400, { error: 'invalid_to' });
    const result = query.history === '1' ? await store.historicalRecords(query) : store.recentRecords(query);
    return response(res, 200, result);
  }
  return response(res, 404, { error: 'not_found' });
}

snapshot().catch(error => console.error(`[vx_runtime_monitor] Initial snapshot failed: ${error.message}`));
store.start();
store.cleanup().catch(error => console.error(`[vx_runtime_monitor] Initial log cleanup failed: ${error.message}`));

if (token.length < 32) {
  console.error('[vx_runtime_monitor] vx_monitor_token must contain at least 32 characters; dashboard disabled. Logging remains active.');
} else if (!Number.isInteger(port) || port < 1 || port > 65535) {
  console.error('[vx_runtime_monitor] Invalid vx_monitor_port; dashboard disabled.');
} else if (host !== '127.0.0.1' && host !== '::1') {
  console.error('[vx_runtime_monitor] Dashboard host must be loopback (127.0.0.1 or ::1); dashboard disabled.');
} else {
  server = http.createServer((req, res) => {
    handle(req, res).catch(error => {
      console.error(`[vx_runtime_monitor] HTTP error: ${error.message}`);
      if (!res.headersSent) response(res, 500, { error: 'internal_error' });
      else res.end();
    });
  });
  server.on('error', error => console.error(`[vx_runtime_monitor] Dashboard failed on ${host}:${port}: ${error.message}`));
  server.listen(port, host, () => console.log(`[vx_runtime_monitor] Dashboard listening on ${host}:${port}`));
}

module.exports = { store, server, health, allowedAddress, authorized, handle, captureEntity };
