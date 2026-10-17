'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { analyzeTrace } = require('../trace');
const { ProfilerMonitor } = require('../profiler');
const { createHandler } = require('../server');

async function tempRoot(t) {
  const root = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'vx-profiler-test-'));
  t.after(() => fs.promises.rm(root, { recursive: true, force: true }));
  return root;
}

function fixture(frameCount = 350, completeCount = 349) {
  const traceEvents = [];
  for (let i = 0; i < frameCount; i++) {
    const base = i * 100000;
    traceEvents.push({ name: 'BeginFrame', ph: 'I', tid: 1, ts: base });
    if (i < completeCount) {
      traceEvents.push({ name: 'tick (alpha)', ph: 'B', tid: 2, ts: base + 1000 });
      traceEvents.push({ name: 'outer', ph: 'B', tid: 2, ts: base + 2000 });
      traceEvents.push({ name: 'event:test (beta)', ph: 'B', tid: 2, ts: base + 3000 });
      traceEvents.push({ name: 'event:test (beta)', ph: 'E', tid: 2, ts: base + 5000 });
      traceEvents.push({ name: 'outer', ph: 'E', tid: 2, ts: base + 6000 });
      traceEvents.push({ name: 'tick (alpha)', ph: 'E', tid: 2, ts: base + 7000 });
      traceEvents.push({ name: 'DrawFrame', ph: 'I', tid: 1, ts: base + (i === 12 ? 60000 : 10000) });
    }
  }
  return JSON.stringify({ traceEvents });
}

test('stream parser counts 350 started frames and excludes nested resource time', async t => {
  const root = await tempRoot(t), file = path.join(root, 'trace.json');
  await fs.promises.writeFile(file, fixture());
  const result = await analyzeTrace(file, { knownResources: new Set(['alpha', 'beta']) });
  assert.equal(result.recordedFrames, 350);
  assert.equal(result.analyzedFrames, 349);
  assert.equal(result.frames.p50Ms, 10);
  assert.equal(result.frames.maxMs, 60);
  assert.equal(result.frames.over50Ms, 1);
  assert.equal(result.slowFrames[0].frame, 13);
  assert.equal(result.resources.find(item => item.resource === 'alpha').selfMs, 349 * 4);
  assert.equal(result.resources.find(item => item.resource === 'beta').selfMs, 349 * 2);
  assert.equal(result.scopes.find(item => item.name === 'outer').totalMs, 349 * 4);
});

test('truncated trace is rejected', async t => {
  const root = await tempRoot(t), file = path.join(root, 'trace.json');
  await fs.promises.writeFile(file, fixture().slice(0, -8));
  await assert.rejects(analyzeTrace(file), /trace_incomplete/);
});

test('capture skips external profiler and records valid samples; restart rebuilds summaries', async t => {
  const root = await tempRoot(t);
  let recording = true, commands = 0;
  const monitor = new ProfilerMonitor(root, {
    isRecording: () => recording,
    record: () => { commands++; recording = true; setTimeout(() => { recording = false; }, 150); },
    save: file => fs.writeFileSync(file, fixture()),
    knownResources: () => new Set(['alpha', 'beta']),
  });
  await fs.promises.mkdir(monitor.traceRoot, { recursive: true });
  await fs.promises.mkdir(monitor.sampleRoot, { recursive: true });
  await monitor.capture();
  assert.equal(monitor.skippedExternal, 1);
  assert.equal(commands, 0);
  monitor.busy = true;
  await monitor.capture();
  assert.equal(monitor.skippedBusy, 1);
  monitor.busy = false;
  recording = false;
  await monitor.capture();
  assert.equal(monitor.samples.length, 1);
  assert.equal(monitor.samples[0].recordedFrames, 350);
  assert.equal(monitor.traces.size, 1);
  const summary = await monitor.summary('5m');
  assert.equal(summary.samples, 1);
  assert.equal(summary.resources[0].resource, 'alpha');
  const restored = new ProfilerMonitor(root, { isRecording: () => true });
  await restored.start();
  restored.stop();
  assert.equal(restored.samples.length, 1);
  assert.equal(restored.traces.size, 1);
});

test('incomplete sample and denied command never enter statistics', async t => {
  const root = await tempRoot(t);
  let recording = false;
  const monitor = new ProfilerMonitor(root, {
    isRecording: () => recording,
    record: () => { recording = true; setTimeout(() => { recording = false; }, 150); },
    save: file => fs.writeFileSync(file, fixture(100, 99)),
    knownResources: () => new Set(['alpha', 'beta']),
  });
  await fs.promises.mkdir(monitor.traceRoot, { recursive: true });
  await fs.promises.mkdir(monitor.sampleRoot, { recursive: true });
  await monitor.capture();
  assert.equal(monitor.samples.length, 0);
  assert.match(monitor.lastError, /incomplete_capture/);
  const denied = new ProfilerMonitor(root, { isRecording: () => false, record: () => {},
    knownResources: () => new Set() });
  await denied.capture();
  assert.match(denied.lastError, /record_not_started/);
});

test('disk save failure leaves no sample and the next capture recovers', async t => {
  const root = await tempRoot(t);
  let recording = false, fail = true;
  const monitor = new ProfilerMonitor(root, {
    isRecording: () => recording,
    record: () => { recording = true; setTimeout(() => { recording = false; }, 150); },
    save: file => { if (fail) throw new Error('disk_unavailable'); fs.writeFileSync(file, fixture()); },
    knownResources: () => new Set(['alpha', 'beta']),
  });
  await fs.promises.mkdir(monitor.traceRoot, { recursive: true });
  await fs.promises.mkdir(monitor.sampleRoot, { recursive: true });
  await monitor.capture();
  assert.equal(monitor.samples.length, 0);
  assert.equal(monitor.lastError, 'disk_unavailable');
  fail = false;
  await monitor.capture();
  assert.equal(monitor.samples.length, 1);
  assert.equal(monitor.lastError, null);
});

test('summary windows include only samples in their time range', async t => {
  const root = await tempRoot(t), now = Date.now();
  const monitor = new ProfilerMonitor(root, { now: () => now });
  for (const offset of [2 * 60 * 60 * 1000, 30 * 60 * 1000, 60 * 1000]) {
    monitor.samples.push({ id: String(offset), at: new Date(now - offset).toISOString(), atMs: now - offset,
      analyzedFrames: 2, frames: { over50Ms: 1, maxMs: 60 }, frameHistogram: { 10: 1, 60: 1 },
      resources: [{ resource: 'alpha', selfMs: 5, calls: 1, maxMs: 5 }], scopes: [], slowFrames: [] });
  }
  assert.equal((await monitor.summary('5m')).samples, 1);
  assert.equal((await monitor.summary('1h')).samples, 2);
  const day = await monitor.summary('24h');
  assert.equal(day.samples, 3);
  assert.equal(day.analyzedFrames, 6);
  assert.equal(day.resources[0].selfMs, 15);
  assert.equal(day.p95Ms, 60);
});

test('retention keeps last 20 traces and removes expired summaries', async t => {
  const root = await tempRoot(t), now = Date.now();
  const monitor = new ProfilerMonitor(root, { now: () => now });
  await fs.promises.mkdir(monitor.traceRoot, { recursive: true });
  await fs.promises.mkdir(monitor.sampleRoot, { recursive: true });
  monitor.samples.push({ id: 'expired', atMs: now - 25 * 60 * 60 * 1000 });
  await fs.promises.writeFile(path.join(monitor.sampleRoot, 'expired.json'), '{}');
  for (let i = 0; i < 22; i++) {
    monitor.samples.push({ id: `trace-${i}`, atMs: now - (22 - i) * 1000 });
    const file = path.join(monitor.traceRoot, `trace-${i}.json`);
    await fs.promises.writeFile(file, 'x');
    await fs.promises.utimes(file, new Date(now - (22 - i) * 1000), new Date(now - (22 - i) * 1000));
  }
  await monitor.cleanup();
  assert.equal(monitor.traces.size, 20);
  assert.equal(monitor.traces.has('trace-0'), false);
  assert.equal(monitor.traces.has('trace-21'), true);
  assert.equal(monitor.samples.length, 22);
  assert.equal(fs.existsSync(path.join(monitor.sampleRoot, 'expired.json')), false);
});

test('retention enforces 512 MB independently of the 20 trace limit', async t => {
  const root = await tempRoot(t), now = Date.now();
  const monitor = new ProfilerMonitor(root, { now: () => now });
  await fs.promises.mkdir(monitor.traceRoot, { recursive: true });
  await fs.promises.mkdir(monitor.sampleRoot, { recursive: true });
  for (let i = 0; i < 3; i++) {
    monitor.samples.push({ id: `large-${i}`, atMs: now - (3 - i) * 1000 });
    const file = path.join(monitor.traceRoot, `large-${i}.json`);
    const handle = await fs.promises.open(file, 'w');
    await handle.truncate(200 * 1024 * 1024);
    await handle.close();
    await fs.promises.utimes(file, new Date(now - (3 - i) * 1000), new Date(now - (3 - i) * 1000));
  }
  await monitor.cleanup();
  assert.equal(monitor.traces.size, 2);
  assert.equal(monitor.traces.has('large-0'), false);
  assert.equal(monitor.traces.has('large-2'), true);
});

test('API requires Bearer token and serves only known trace IDs', async t => {
  const root = await tempRoot(t), token = 'a'.repeat(40);
  const file = path.join(root, 'trace.json'); await fs.promises.writeFile(file, '{}');
  const monitor = { status: () => ({ phase: 'idle' }), summary: async () => ({ samples: 1 }),
    listSamples: () => ({ items: [] }), tracePath: id => id === 'known' ? file : null };
  const handler = createHandler({ root, token, monitor });
  const server = http.createServer((req, res) => handler(req, res));
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(`${base}/profiler/status`)).status, 401);
  const headers = { Authorization: `Bearer ${token}` };
  assert.equal((await fetch(`${base}/profiler/status`, { headers })).status, 200);
  assert.equal((await fetch(`${base}/profiler/summary?window=5m`, { headers })).status, 200);
  assert.equal((await fetch(`${base}/profiler/trace/missing`, { headers })).status, 404);
  const response = await fetch(`${base}/profiler/trace/known`, { headers });
  assert.equal(response.status, 200);
  assert.equal(await response.text(), '{}');
  assert.equal((await fetch(`${base}/profiler/status`, { headers, method: 'POST' })).status, 405);
});
