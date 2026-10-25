'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { MonitorStore } = require('../store');

function fixture(options = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'vx-monitor-'));
  const store = new MonitorStore(root, options);
  return { root, store, cleanup: () => fs.rmSync(root, { recursive: true, force: true }) };
}

test('batch records keep metadata, time ordering and player name without payload data', async () => {
  const { store, cleanup } = fixture({ now: () => Date.parse('2026-10-16T10:00:00.000Z') });
  try {
    store.upsertPlayer(24, 'Test player');
    store.acceptBatch({ resource: 'job_a', dropped: 2, monoMs: 1200, records: [
      { kind: 'event', phase: 'receive', name: 'work:start', playerSessionId: 24, payloadBytes: 99, monoMs: 1000, payload: { secret: 'must not log' } },
      { kind: 'export', phase: 'call', name: 'getWork', targetResource: 'job_b', wallMs: 18, monoMs: 1100 },
    ] });
    assert.equal(store.recentRecords({ limit: '10' }).records[1].playerName, 'Test player');
    assert.equal(store.droppedAgents, 2);
    await store.flushAll();
    const result = await store.historicalRecords({ limit: '10' });
    assert.equal(result.records.length, 2);
    assert.ok(Date.parse(result.records[0].timestamp) > Date.parse(result.records[1].timestamp));
    assert.equal(JSON.stringify(result.records).includes('must not log'), false);
    assert.equal(result.records[0].targetResource, 'job_b');
    assert.equal(result.records[0].payloadBytes, null);
    assert.equal(result.records[1].entityNetId, null);
  } finally { cleanup(); }
});

test('bounded collector queue reports loss and keeps gameplay-facing accept path finite', async () => {
  const { store, cleanup } = fixture({ queueLimit: 2 });
  try {
    for (let i = 0; i < 4; i++) store.record({ kind: 'event', phase: 'handler', name: `event:${i}` });
    assert.equal(store.total, 2);
    assert.equal(store.droppedCollector, 2);
    await store.flushAll();
    assert.equal((await store.historicalRecords({ limit: '10' })).records.length, 2);
  } finally { cleanup(); }
});

test('segment rotation, paging and retention remove old segments', async () => {
  let now = Date.parse('2026-10-16T10:00:00.000Z');
  const { store, cleanup } = fixture({ now: () => now, segmentBytes: 380, retentionMs: 60 * 60 * 1000 });
  try {
    for (let i = 0; i < 5; i++) {
      store.record({ kind: 'event', phase: 'send-local', name: `trace:${i}`, resource: 'demo' });
      await store.flushAll();
    }
    const before = await store.segments();
    assert.ok(before.length > 1, 'small segment limit should rotate');
    const page2 = await store.historicalRecords({ limit: '2', page: '2' });
    assert.deepEqual(page2.records.map(item => item.name), ['trace:2', 'trace:1']);
    now += 2 * 60 * 60 * 1000;
    await store.cleanup();
    assert.equal((await store.segments()).length, 0, 'idle expired segment must be removed');
    store.record({ kind: 'event', phase: 'send-local', name: 'newer', resource: 'demo' });
    await store.flushAll();
    await store.cleanup();
    const after = await store.segments();
    assert.ok(after.length < before.length + 1);
    assert.equal((await store.historicalRecords({ limit: '10' })).records[0].name, 'newer');
  } finally { cleanup(); }
});

test('disk failure counts loss, backs off and recovers when storage returns', async () => {
  let now = Date.parse('2026-10-16T10:00:00.000Z');
  const { root, store, cleanup } = fixture({ now: () => now });
  try {
    await store.stats.ready;
    fs.rmSync(path.join(root, 'logs'), { recursive: true });
    fs.writeFileSync(path.join(root, 'logs'), 'blocked');
    store.record({ kind: 'event', phase: 'handler', name: 'first' });
    await store.flushAll();
    assert.equal(store.droppedDisk, 1);
    assert.equal((await store.stats.get({ window: '5m', view: 'handled' })).total, 0, 'failed write is absent from stats');
    assert.ok(store.diskError);
    store.record({ kind: 'event', phase: 'handler', name: 'second' });
    await store.flushAll();
    assert.equal(store.queue.length, 1, 'retry backoff keeps pending work bounded in queue');
    fs.rmSync(path.join(root, 'logs'));
    now += 5001;
    await store.flushAll();
    assert.equal(store.diskError, null);
    assert.equal((await store.stats.get({ window: '5m', view: 'handled' })).total, 1);
    assert.equal((await store.historicalRecords({ limit: '10' })).records[0].name, 'second');
  } finally { cleanup(); }
});


test('light aggregates preserve exact event counts and targeted totals after deferred intake', async () => {
  const { store, cleanup } = fixture();
  try {
    store.enqueueBatch({ resource: 'busy', records: [
      { kind: 'event', phase: 'send-client', name: 'ping', aggregate: true, targeted: true, count: 1000 },
      { kind: 'event', phase: 'send-client', name: 'ping', aggregate: true, status: 'broadcast', count: 50 },
    ] });
    assert.equal(store.total, 0, 'native-facing callback must defer normalization');
    await store.flushAll();
    const stats = await store.stats.get({ window: '5m', view: 'client' });
    assert.equal(store.total, 1050);
    assert.equal(stats.total, 1050);
    assert.equal(stats.targeted, 1000);
    assert.equal(stats.broadcast, 50);
    assert.equal(store.inputCount, 0);
  } finally { cleanup(); }
});

test('overflow counts lost underlying events instead of aggregate rows', async () => {
  const { store, cleanup } = fixture({ queueLimit: 1 });
  try {
    store.record({ kind: 'event', phase: 'handler', name: 'first', count: 9 });
    store.record({ kind: 'event', phase: 'handler', name: 'second', count: 500 });
    assert.equal(store.droppedCollector, 500);
    await store.flushAll();
  } finally { cleanup(); }
});
