'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { MonitorStore } = require('../store');
const { StatsStore } = require('../stats');

function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vx-stats-'));
  let now = Date.parse('2026-10-16T10:05:30.000Z');
  const store = new MonitorStore(root, { now: () => now });
  return { root, store, get now() { return now; }, set now(value) { now = value; },
    cleanup: () => fs.rmSync(root, { recursive: true, force: true }) };
}

test('counts each client send once and keeps local, handler and export phases separate', async () => {
  const item = fixture();
  const { store } = item;
  try {
    await store.stats.ready;
    const stamp = '2026-10-16T10:04:00.000Z';
    for (const resource of ['a', 'a', 'b']) store.record({ timestamp: stamp, kind: 'event', phase: 'send-client', name: 'job:update', resource, playerSessionId: 12, status: 'ok' });
    store.record({ timestamp: stamp, kind: 'event', phase: 'send-client', name: 'job:update', resource: 'a', status: 'broadcast' });
    store.record({ timestamp: stamp, kind: 'event', phase: 'send-latent', name: 'job:update', resource: 'b', status: 'broadcast' });
    store.record({ timestamp: stamp, kind: 'event', phase: 'send-local', name: 'job:update', resource: 'a' });
    store.record({ timestamp: stamp, kind: 'event', phase: 'receive', name: 'job:update', resource: 'a' });
    store.record({ timestamp: stamp, kind: 'event', phase: 'handler', name: 'job:update', resource: 'a', playerSessionId: 7 });
    store.record({ timestamp: stamp, kind: 'event', phase: 'handler', name: 'job:update', resource: 'a', playerSessionId: 7 });
    store.record({ timestamp: stamp, kind: 'export', phase: 'call', name: 'getDuty', resource: 'a' });
    store.record({ timestamp: stamp, kind: 'export', phase: 'invoke', name: 'getDuty', resource: 'b' });
    store.record({ timestamp: stamp, kind: 'event', phase: 'send-client', name: '__cfx_internal:httpResponse', resource: 'a' });
    await store.flushAll();
    const client = await store.stats.get({ window: '5m', view: 'client', name: 'job:update' });
    assert.equal(client.total, 5);
    assert.equal(client.broadcast, 2);
    assert.equal(client.targeted, 3);
    assert.equal(client.top[0].topResource, 'a');
    assert.deepEqual(client.selected.resources.map(row => [row.resource, row.count]), [['a', 3], ['b', 2]]);
    assert.deepEqual(client.selected.targets.map(row => [row.id, row.count]), [['12', 3], ['-1', 2]]);
    assert.equal((await store.stats.get({ window: '5m', view: 'local' })).total, 1);
    const handled = await store.stats.get({ window: '5m', view: 'handled', name: 'job:update' });
    assert.equal(handled.total, 2);
    assert.deepEqual(handled.selected.senders.map(row => [row.id, row.count]), [['7', 2]]);
    const exports = await store.stats.get({ window: '5m', view: 'exports' });
    assert.equal(exports.total, 2);
    assert.deepEqual(exports.top.map(row => [row.phase, row.count]).sort(), [['call', 1], ['invoke', 1]]);
    assert.equal(store.recentRecords({ clean: '1' }).records.some(row => row.name.startsWith('__cfx_internal:') || row.phase === 'receive' || row.phase === 'invoke'), false);
    assert.equal((await store.historicalRecords({ limit: '200' })).records.length, 12);
  } finally { item.cleanup(); }
});

test('rebuilds minute buckets from JSONL after restart; 24h scans persisted history', async () => {
  const item = fixture();
  try {
    await item.store.stats.ready;
    item.store.record({ timestamp: '2026-10-16T09:30:00.000Z', kind: 'event', phase: 'send-client', name: 'old', resource: 'a', status: 'broadcast' });
    item.store.record({ timestamp: '2026-10-16T10:04:00.000Z', kind: 'event', phase: 'send-client', name: 'recent', resource: 'a', playerSessionId: 44 });
    item.store.record({ timestamp: '2026-10-15T12:00:00.000Z', kind: 'event', phase: 'send-client', name: 'yesterday', resource: 'b', playerSessionId: 55 });
    await item.store.flushAll();
    const rebuilt = new MonitorStore(item.root, { now: () => item.now });
    await rebuilt.stats.ready;
    assert.deepEqual((await rebuilt.stats.get({ window: '5m', view: 'client' })).top.map(row => row.name), ['recent']);
    assert.equal((await rebuilt.stats.get({ window: '1h', view: 'client' })).total, 2);
    const day = await rebuilt.stats.get({ window: '24h', view: 'client' });
    assert.equal(day.total, 3);
    assert.deepEqual(day.top.map(row => row.name).sort(), ['old', 'recent', 'yesterday']);
    assert.equal(rebuilt.stats.cache.has('client'), true);
  } finally { item.cleanup(); }
});

test('startup rebuild and fresh flush do not count the same persisted call twice', async () => {
  const item = fixture();
  try {
    await item.store.stats.ready;
    item.store.record({ timestamp: '2026-10-16T10:04:00.000Z', kind: 'event', phase: 'send-client', name: 'before', resource: 'a', playerSessionId: 12 });
    await item.store.flushAll();
    const restarted = new MonitorStore(item.root, { now: () => item.now });
    restarted.record({ timestamp: '2026-10-16T10:04:10.000Z', kind: 'event', phase: 'send-client', name: 'after', resource: 'a', playerSessionId: 12 });
    await restarted.flushAll();
    await restarted.stats.ready;
    const result = await restarted.stats.get({ window: '5m', view: 'client' });
    assert.equal(result.total, 2);
    assert.deepEqual(result.top.map(row => row.name).sort(), ['after', 'before']);
  } finally { item.cleanup(); }
});

test('bounded group count records overflow as Khác and distinguishes initial agent loss', async () => {
  const item = fixture();
  try {
    await item.store.stats.ready;
    const bounded = new StatsStore(item.store, { now: () => item.now, groupLimit: 2 });
    await bounded.initialize();
    for (const name of ['one', 'two', 'three']) {
      const record = item.store.normalize({ timestamp: '2026-10-16T10:04:00.000Z', kind: 'event', phase: 'send-client', name, resource: 'a', status: 'broadcast' });
      bounded.ingest(record);
    }
    const result = await bounded.get({ window: '5m', view: 'client' });
    assert.equal(result.total, 3);
    assert.equal(result.broadcast, 3);
    assert.equal(result.partial, true);
    assert.ok(result.partialReasons.includes('group_limit'));
    assert.equal(result.top.find(row => row.name === 'Khác').count, 1);
    item.store.acceptBatch({ resource: 'a', dropped: 10, records: [] });
    item.store.acceptBatch({ resource: 'a', dropped: 12, records: [] });
    assert.equal(item.store.summary().dropped.agentsInitial, 10);
    assert.equal(item.store.summary().dropped.agentsAfterStart, 2);
  } finally { item.cleanup(); }
});

test('5m group cap releases old names independently of 1h window', async () => {
  const item = fixture();
  try {
    await item.store.stats.ready;
    const bounded = new StatsStore(item.store, { now: () => item.now, groupLimit: 2 });
    await bounded.initialize();
    for (const name of ['one', 'two']) bounded.ingest(item.store.normalize({
      timestamp: '2026-10-16T10:05:00.000Z', kind: 'event', phase: 'send-client', name, resource: 'a', status: 'broadcast',
    }));
    item.now = Date.parse('2026-10-16T10:11:30.000Z');
    bounded.ingest(item.store.normalize({ timestamp: '2026-10-16T10:11:00.000Z', kind: 'event', phase: 'send-client', name: 'three', resource: 'a', status: 'broadcast' }));
    const short = await bounded.get({ window: '5m', view: 'client' });
    assert.equal(short.total, 1);
    assert.deepEqual(short.top.map(row => row.name), ['three']);
    assert.equal(short.partialReasons.includes('group_limit'), false);
    const hour = await bounded.get({ window: '1h', view: 'client' });
    assert.equal(hour.total, 3);
    assert.equal(hour.top.find(row => row.name === 'Khác').count, 1);
  } finally { item.cleanup(); }
});

test('24h scan yields the event loop, coalesces concurrent requests and caches for 60 seconds', async () => {
  const item = fixture();
  try {
    await item.store.stats.ready;
    const dir = path.join(item.root, 'logs', '2026-10-16');
    fs.mkdirSync(dir, { recursive: true });
    const line = JSON.stringify({ timestamp: '2026-10-16T10:00:00.000Z', kind: 'event', phase: 'send-client',
      name: 'load:notify', resource: 'load', playerSessionId: 12, status: 'ok' }) + '\n';
    fs.writeFileSync(path.join(dir, '10-000.jsonl'), line.repeat(30_000));
    const original = item.store.segments.bind(item.store);
    let scans = 0, ticks = 0;
    item.store.segments = async () => { scans++; return original(); };
    const timer = setInterval(() => ticks++, 1);
    try {
      const [first, second, local] = await Promise.all([
        item.store.stats.get({ window: '24h', view: 'client' }),
        item.store.stats.get({ window: '24h', view: 'client' }),
        item.store.stats.get({ window: '24h', view: 'local' }),
      ]);
      assert.equal(first.total, 30_000);
      assert.equal(second.total, 30_000);
      assert.equal(local.total, 0);
      assert.equal(scans, 1);
      assert.ok(ticks > 0, 'scan should let the event loop run');
      await item.store.stats.get({ window: '24h', view: 'client', name: 'load:notify' });
      assert.equal(scans, 1, 'detail query should use cached aggregation');
    } finally { clearInterval(timer); }
  } finally { item.cleanup(); }
});

test('retention cap makes 24h result partial without inventing lost calls', async () => {
  const item = fixture();
  try {
    await item.store.stats.ready;
    item.store.maxDiskBytes = 200;
    item.now = Date.parse('2026-10-16T04:00:00.000Z');
    item.store.record({ kind: 'event', phase: 'send-client', name: 'old', resource: 'a', status: 'broadcast' });
    await item.store.flushAll();
    item.now = Date.parse('2026-10-16T10:05:30.000Z');
    item.store.record({ kind: 'event', phase: 'send-client', name: 'new', resource: 'a', playerSessionId: 12 });
    await item.store.flushAll();
    await item.store.cleanup();
    const result = await item.store.stats.get({ window: '24h', view: 'client' });
    assert.equal(result.total, 1);
    assert.equal(result.top[0].name, 'new');
    assert.equal(result.partial, true);
    assert.ok(result.partialReasons.includes('retention'));
  } finally { item.cleanup(); }
});
