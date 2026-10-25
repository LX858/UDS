'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const net = require('net');

async function freePort() {
  const listener = net.createServer();
  await new Promise(resolve => listener.listen(0, '127.0.0.1', resolve));
  const port = listener.address().port;
  await new Promise(resolve => listener.close(resolve));
  return port;
}

test('loopback API rejects missing credentials and exposes only sanitized records', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vx-monitor-api-'));
  const handlers = new Map();
  const port = await freePort();
  const token = 'test-token-'.padEnd(64, 'x');
  global.GetCurrentResourceName = () => 'vx_runtime_monitor';
  global.GetResourcePath = () => root;
  global.GetConvarInt = (_name, fallback) => fallback;
  global.RegisterCommand = () => {};
  global.GetConvar = (name, fallback) => ({ vx_monitor_host: '127.0.0.1', vx_monitor_port: String(port), vx_monitor_token: token })[name] || fallback;
  global.GetPlayers = () => ['12'];
  global.GetPlayerName = () => 'Alice';
  global.GetAllObjects = () => [100];
  global.GetAllPeds = () => [];
  global.GetAllVehicles = () => [];
  global.GetEntityType = () => 3;
  global.GetEntityModel = () => 12345;
  global.NetworkGetNetworkIdFromEntity = () => 88;
  global.NetworkGetEntityOwner = () => 12;
  global.GetEntityScript = () => 'spawn_resource';
  global.on = (name, callback) => handlers.set(name, callback);
  const monitor = require('../server');
  try {
    if (!monitor.server.listening) await new Promise(resolve => monitor.server.once('listening', resolve));
    const base = `http://127.0.0.1:${port}`;
    assert.equal((await fetch(`${base}/health`)).status, 401);
    assert.equal((await fetch(`${base}/health`, { headers: { Authorization: `Bearer ${'wrong-'.padEnd(64, 'x')}` } })).status, 401);
    assert.equal((await fetch(`${base}/records`, { method: 'POST' })).status, 405);
    assert.equal(monitor.allowedAddress('8.8.8.8'), false);
    assert.equal(monitor.allowedAddress('192.168.1.42'), false);
    assert.equal(monitor.allowedAddress('::ffff:127.0.0.1'), true);
    handlers.get('__vx_runtime_monitor:batch')({ resource: 'sample', records: [
      { kind: 'event', phase: 'receive', name: 'sample:started', payload: { secret: 'hidden' } },
    ] });
    const headers = { Authorization: `Bearer ${token}` };
    assert.equal((await fetch(`${base}/stats?window=5m&view=client`)).status, 401);
    assert.equal((await fetch(`${base}/stats?window=wrong&view=client`, { headers })).status, 400);
    handlers.get('__vx_runtime_monitor:batch')({ resource: 'sample', dropped: 5, records: [
      { kind: 'event', phase: 'send-client', name: 'sample:notify', playerSessionId: 12, status: 'ok' },
      { kind: 'event', phase: 'send-client', name: 'sample:notify', status: 'broadcast' },
    ] });
    await monitor.store.flushAll();
    const stats = await (await fetch(`${base}/stats?window=5m&view=client&name=sample%3Anotify`, { headers })).json();
    assert.equal(stats.total, 2);
    assert.equal(stats.broadcast, 1);
    assert.deepEqual(stats.selected.targets.map(row => row.id).sort(), ['-1', '12']);
    assert.equal((await (await fetch(`${base}/summary`, { headers })).json()).dropped.agentsAfterStart, 5);
    const clean = await (await fetch(`${base}/records?clean=1`, { headers })).json();
    assert.equal(clean.records.some(row => row.phase === 'receive'), false);
    const response = await fetch(`${base}/records?limit=1000`, { headers });
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.limit, 200);
    assert.equal(body.records.some(row => row.name === 'sample:started'), true);
    assert.equal(JSON.stringify(body).includes('hidden'), false);
    const filtered = await (await fetch(`${base}/records?kind=export`, { headers })).json();
    assert.equal(filtered.records.length, 0);
    const players = await (await fetch(`${base}/players`, { headers })).json();
    assert.equal(players.items[0].name, 'Alice');
    const entities = await (await fetch(`${base}/entities`, { headers })).json();
    assert.equal(entities.items[0].type, 'object');
    assert.equal(entities.items[0].netId, 88);
    assert.equal(entities.items[0].resource, 'spawn_resource');
    handlers.get('entityRemoved')(100);
    assert.equal((await (await fetch(`${base}/entities`, { headers })).json()).total, 0);
    global.source = 12;
    handlers.get('playerDropped')();
    assert.equal((await (await fetch(`${base}/players`, { headers })).json()).total, 0);
  } finally {
    await new Promise(resolve => monitor.server.close(resolve));
    await monitor.store.stop();
    fs.rmSync(root, { recursive: true, force: true });
  }
});
