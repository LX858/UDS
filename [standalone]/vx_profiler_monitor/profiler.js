'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { analyzeTrace, MAX_TRACE_BYTES } = require('./trace');

const DAY_MS = 24 * 60 * 60 * 1000;
const CADENCE_MS = 30 * 1000;
const TRACE_LIMIT = 20;
const TRACE_BYTES_LIMIT = 512 * 1024 * 1024;
const WINDOWS = { '5m': 5 * 60 * 1000, '1h': 60 * 60 * 1000, '24h': DAY_MS };
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
function captureContext() {
  const read = fn => { try { return fn(); } catch { return null; } };
  const mode = read(() => GetConvar('vx_monitor_mode', 'light'));
  const detailUntil = read(() => GetConvarInt('vx_monitor_detail_until', 0));
  return {
    players: read(() => GetNumPlayerIndices()),
    entities: { vehicles: read(() => GetAllVehicles().length), peds: read(() => GetAllPeds().length),
      objects: read(() => GetAllObjects().length) },
    monitor: read(() => GetResourceState('vx_runtime_monitor')),
    monitorMode: mode === 'detail' && detailUntil <= Math.floor(Date.now() / 1000) ? 'light' : mode,
    build: read(() => GetConvar('version', 'unknown')),
    codeRevision: read(() => GetConvar('vx_profiler_revision', 'unknown')),
  };
}
const round = value => Math.round(value * 1000) / 1000;

function histogramPercentile(histogram, p) {
  const values = [...histogram].sort((a, b) => a[0] - b[0]);
  const total = values.reduce((sum, [, count]) => sum + count, 0);
  if (!total) return null;
  const wanted = Math.max(1, Math.ceil(total * p));
  let count = 0;
  for (const [ms, amount] of values) {
    count += amount;
    if (count >= wanted) return ms;
  }
  return values.at(-1)[0];
}

function mergeHistogram(target, source) {
  for (const [bucket, count] of Object.entries(source || {})) {
    const ms = Number(bucket);
    if (Number.isFinite(ms) && Number.isFinite(count)) target.set(ms, (target.get(ms) || 0) + count);
  }
}

function windowMs(value) {
  if (!Object.hasOwn(WINDOWS, value)) throw new RangeError('invalid_window');
  return WINDOWS[value];
}

class ProfilerMonitor {
  constructor(root, options = {}) {
    this.root = root;
    this.traceRoot = path.join(root, 'data', 'traces');
    this.sampleRoot = path.join(root, 'data', 'samples');
    this.now = options.now || Date.now;
    this.record = options.record || (() => ExecuteCommand('profiler record 350'));
    this.save = options.save || (file => ExecuteCommand(`profiler saveJSON "${file.replace(/\\/g, '/')}"`));
    this.isRecording = options.isRecording || (() => ProfilerIsRecording());
    this.knownResources = options.knownResources || (() => {
      const result = new Set();
      for (let i = 0, count = GetNumResources(); i < count; i++) result.add(GetResourceByFindIndex(i));
      return result;
    });
    this.analyze = options.analyze || analyzeTrace;
    this.cadenceMs = options.cadenceMs || CADENCE_MS;
    this.samples = [];
    this.traces = new Set();
    this.phase = 'initializing';
    this.lastError = null;
    this.busy = false;
    this.stopped = false;
    this.timer = null;
    this.cleanupTimer = null;
    this.activeId = null;
    this.nextAt = null;
    this.startedAt = null;
    this.skippedBusy = 0;
    this.skippedExternal = 0;
    this.failures = 0;
    this.summaryCache = new Map();
    this.cleaning = null;
  }

  async start() {
    await fs.promises.mkdir(this.traceRoot, { recursive: true });
    await fs.promises.mkdir(this.sampleRoot, { recursive: true });
    const names = await fs.promises.readdir(this.sampleRoot);
    for (const name of names) {
      if (!/^[\w-]+\.json$/.test(name)) continue;
      try {
        const sample = JSON.parse(await fs.promises.readFile(path.join(this.sampleRoot, name), 'utf8'));
        if (sample.id && Number.isFinite(sample.atMs)) this.samples.push(sample);
      } catch (error) { console.warn(`[vx_profiler_monitor] Ignored invalid summary ${name}: ${error.message}`); }
      if (this.samples.length % 100 === 0) await new Promise(resolve => setImmediate(resolve));
    }
    this.samples.sort((a, b) => a.atMs - b.atMs);
    await this.cleanup();
    this.phase = 'idle';
    this.nextAt = this.now();
    this.timer = setInterval(() => {
      this.nextAt = this.now() + this.cadenceMs;
      void this.capture();
    }, this.cadenceMs);
    this.cleanupTimer = setInterval(() => {
      this.cleanup().catch(error => console.error(`[vx_profiler_monitor] Cleanup failed: ${error.message}`));
    }, 5 * 60 * 1000);
    void this.capture();
  }

  stop() {
    this.stopped = true;
    if (this.timer) clearInterval(this.timer);
    if (this.cleanupTimer) clearInterval(this.cleanupTimer);
    this.timer = null;
    this.cleanupTimer = null;
    this.nextAt = null;
  }

  async waitForCapture() {
    const until = this.now() + 120000;
    while (!this.stopped && this.isRecording()) {
      if (this.now() > until) throw new Error('recording_timeout');
      await sleep(250);
    }
    if (this.stopped) throw new Error('resource_stopped');
  }

  async waitForFile(file) {
    const until = this.now() + 30000;
    let previous = -1, stable = 0;
    while (!this.stopped && this.now() <= until) {
      const stat = await fs.promises.stat(file).catch(() => null);
      if (stat && stat.size > MAX_TRACE_BYTES) throw new Error('trace_too_large');
      if (stat && stat.size > 0 && stat.size === previous) stable++;
      else stable = 0;
      if (stable >= 2) return;
      previous = stat?.size ?? -1;
      await sleep(250);
    }
    throw new Error(this.stopped ? 'resource_stopped' : 'save_timeout_or_invalid_path');
  }

  async capture() {
    if (this.stopped) return;
    if (this.busy) { this.skippedBusy++; return; }
    try {
      if (this.isRecording()) { this.skippedExternal++; return; }
    } catch (error) { this.lastError = `profiler_native_unavailable: ${error.message}`; this.phase = 'error'; return; }
    this.busy = true;
    this.startedAt = new Date(this.now()).toISOString();
    const id = `${new Date(this.now()).toISOString().replace(/[-:.]/g, '')}-${crypto.randomBytes(3).toString('hex')}`;
    const file = path.join(this.traceRoot, `${id}.json`);
    this.activeId = id;
    try {
      const knownResources = this.knownResources();
      const context = captureContext();
      this.phase = 'recording';
      this.record();
      await sleep(100);
      if (!this.isRecording()) throw new Error('record_not_started_check_command_ace');
      await this.waitForCapture();
      if (this.isRecording()) throw new Error('profiler_taken_by_other_capture');
      this.phase = 'saving';
      this.save(file);
      await this.waitForFile(file);
      this.phase = 'analyzing';
      let result;
      const analysisDeadline = this.now() + 30000;
      for (const resource of this.knownResources()) knownResources.add(resource);
      while (!result) {
        try { result = await this.analyze(file, { knownResources }); }
        catch (error) {
          if (error.message !== 'trace_incomplete' || this.now() >= analysisDeadline) throw error;
          await sleep(500);
        }
      }
      if (result.recordedFrames < 350 || result.analyzedFrames < 349) {
        throw new Error(`incomplete_capture_${result.recordedFrames}_${result.analyzedFrames}`);
      }
      const sample = { id, at: this.startedAt, atMs: Date.parse(this.startedAt), context,
        recordedFrames: result.recordedFrames, analyzedFrames: result.analyzedFrames,
        incompleteFrames: result.incompleteFrames, unmatchedScopes: result.unmatchedScopes,
        eventCount: result.eventCount, frames: result.frames, frameHistogram: result.frameHistogram,
        slowFrames: result.slowFrames, resources: result.resources, scopes: result.scopes,
        scopesPartial: result.scopesPartial };
      if (this.stopped) throw new Error('resource_stopped');
      const target = path.join(this.sampleRoot, `${id}.json`);
      const temporary = `${target}.tmp`;
      await fs.promises.writeFile(temporary, JSON.stringify(sample));
      await fs.promises.rename(temporary, target);
      this.samples.push(sample);
      this.traces.add(id);
      this.summaryCache.clear();
      this.lastError = null;
      await this.cleanup();
      this.traces.add(id);
      this.phase = this.lastError ? 'error' : 'idle';
      console.log(`[vx_profiler_monitor] Sample ${id}: ${result.recordedFrames} recorded, ${result.analyzedFrames} complete frames, P95 ${result.frames.p95Ms} ms`);
    } catch (error) {
      this.failures++;
      this.lastError = String(error?.message || error).slice(0, 300);
      this.phase = 'error';
      await fs.promises.unlink(file).catch(() => {});
      console.error(`[vx_profiler_monitor] Capture failed: ${this.lastError}`);
    } finally { this.busy = false; this.activeId = null; }
  }

  cleanup() {
    if (this.cleaning) return this.cleaning;
    this.cleaning = this.performCleanup().finally(() => { this.cleaning = null; });
    return this.cleaning;
  }

  async performCleanup() {
    const cutoff = this.now() - DAY_MS;
    const keep = [];
    for (const sample of this.samples) {
      if (sample.atMs >= cutoff) keep.push(sample);
      else await fs.promises.unlink(path.join(this.sampleRoot, `${sample.id}.json`)).catch(() => {});
    }
    this.samples = keep;
    const files = [];
    const validIds = new Set(keep.map(item => item.id));
    for (const name of await fs.promises.readdir(this.traceRoot)) {
      if (!/^[\w-]+\.json$/.test(name)) continue;
      const full = path.join(this.traceRoot, name);
      const id = name.slice(0, -5);
      if (id === this.activeId && !validIds.has(id)) continue;
      if (!validIds.has(id)) { await fs.promises.unlink(full).catch(() => {}); continue; }
      const stat = await fs.promises.stat(full).catch(() => null);
      if (stat) files.push({ full, id, size: stat.size, mtimeMs: stat.mtimeMs });
    }
    files.sort((a, b) => a.mtimeMs - b.mtimeMs);
    let bytes = files.reduce((sum, file) => sum + file.size, 0);
    const failed = [];
    while (files.length && (files.length + failed.length > TRACE_LIMIT || bytes > TRACE_BYTES_LIMIT ||
      files[0].mtimeMs < cutoff)) {
      const oldest = files.shift();
      try { await fs.promises.unlink(oldest.full); bytes -= oldest.size; }
      catch (error) {
        failed.push(oldest);
        this.lastError = `trace_cleanup_failed: ${error.message}`;
        console.error(`[vx_profiler_monitor] Trace cleanup: ${error.message}`);
      }
    }
    this.traces = new Set([...files, ...failed].map(file => file.id));
    this.summaryCache.clear();
  }

  status() {
    return { phase: this.phase, busy: this.busy, startedAt: this.startedAt,
      nextAt: this.nextAt ? new Date(this.nextAt).toISOString() : null,
      lastSampleAt: this.samples.at(-1)?.at || null, lastError: this.lastError,
      samples24h: this.samples.length, retainedTraces: this.traces.size,
      skippedBusy: this.skippedBusy, skippedExternal: this.skippedExternal, failures: this.failures,
      cadenceSeconds: this.cadenceMs / 1000, framesPerSample: 350 };
  }

  listSamples(query = {}) {
    const duration = windowMs(query.window || '24h');
    const page = Math.min(100, Math.max(1, Number.parseInt(query.page, 10) || 1));
    const limit = Math.min(100, Math.max(1, Number.parseInt(query.limit, 10) || 20));
    const items = this.samples.filter(item => item.atMs >= this.now() - duration).reverse();
    return { total: items.length, page, limit, items: items.slice((page - 1) * limit, page * limit)
      .map(item => ({ id: item.id, at: item.at, recordedFrames: item.recordedFrames,
        analyzedFrames: item.analyzedFrames, frames: item.frames,
        topResource: item.resources[0]?.resource || null, hasTrace: this.traces.has(item.id) })) };
  }

  async summary(windowName = '5m') {
    const duration = windowMs(windowName);
    const now = this.now();
    const cached = this.summaryCache.get(windowName);
    if (cached && now - cached.at < 5000) return cached.promise;
    const promise = this.buildSummary(windowName, duration, now);
    this.summaryCache.set(windowName, { at: now, promise });
    return promise;
  }

  async buildSummary(windowName, duration, now) {
    const selected = this.samples.filter(item => item.atMs >= now - duration);
    const histogram = new Map(), resources = new Map(), scopes = new Map(), buckets = new Map();
    const bucketMs = windowName === '24h' ? 30 * 60 * 1000 : windowName === '1h' ? 5 * 60 * 1000 : 60 * 1000;
    let analyzedFrames = 0, over50Ms = 0, maxMs = 0, partialScopes = false;
    for (let index = 0; index < selected.length; index++) {
      const sample = selected[index];
      analyzedFrames += sample.analyzedFrames;
      over50Ms += sample.frames.over50Ms;
      maxMs = Math.max(maxMs, sample.frames.maxMs || 0);
      partialScopes ||= !!sample.scopesPartial;
      mergeHistogram(histogram, sample.frameHistogram);
      const bucketAt = Math.floor(sample.atMs / bucketMs) * bucketMs;
      const bucket = buckets.get(bucketAt) || { at: new Date(bucketAt).toISOString(), samples: 0, frames: 0,
        over50Ms: 0, maxMs: 0, histogram: new Map() };
      bucket.samples++; bucket.frames += sample.analyzedFrames;
      bucket.over50Ms += sample.frames.over50Ms;
      bucket.maxMs = Math.max(bucket.maxMs, sample.frames.maxMs || 0);
      mergeHistogram(bucket.histogram, sample.frameHistogram);
      buckets.set(bucketAt, bucket);
      for (const item of sample.resources) {
        const entry = resources.get(item.resource) || { resource: item.resource, selfMs: 0, calls: 0, maxMs: 0 };
        entry.selfMs += item.selfMs; entry.calls += item.calls; entry.maxMs = Math.max(entry.maxMs, item.maxMs);
        resources.set(item.resource, entry);
      }
      for (const item of sample.scopes) {
        const key = `${item.resource}\u0000${item.name}`;
        const entry = scopes.get(key) || { resource: item.resource, name: item.name, totalMs: 0, calls: 0, maxMs: 0 };
        entry.totalMs += item.totalMs; entry.calls += item.calls; entry.maxMs = Math.max(entry.maxMs, item.maxMs);
        scopes.set(key, entry);
      }
      if (index % 32 === 31) await new Promise(resolve => setImmediate(resolve));
    }
    const value = { window: windowName, from: new Date(now - duration).toISOString(),
      to: new Date(now).toISOString(), availableFrom: selected[0]?.at || null,
      samples: selected.length, analyzedFrames, over50Ms,
      p50Ms: histogramPercentile(histogram, .5), p95Ms: histogramPercentile(histogram, .95),
      p99Ms: histogramPercentile(histogram, .99), maxMs: selected.length ? maxMs : null,
      percentileResolutionMs: 1, partialScopes,
      resources: [...resources.values()].map(item => ({ ...item, selfMs: round(item.selfMs),
        maxMs: round(item.maxMs), perFrameMs: analyzedFrames ? round(item.selfMs / analyzedFrames) : 0 }))
        .sort((a, b) => b.selfMs - a.selfMs).slice(0, 50),
      scopes: [...scopes.values()].map(item => ({ ...item, totalMs: round(item.totalMs), maxMs: round(item.maxMs) }))
        .sort((a, b) => b.totalMs - a.totalMs).slice(0, 30),
      trend: [...buckets.values()].sort((a, b) => a.at.localeCompare(b.at)).map(item => ({
        at: item.at, samples: item.samples, frames: item.frames, over50Ms: item.over50Ms,
        p95Ms: histogramPercentile(item.histogram, .95), maxMs: round(item.maxMs) })),
      slowFrames: selected.flatMap(sample => sample.slowFrames.map(frame => ({ ...frame, sampleId: sample.id, at: sample.at })))
        .sort((a, b) => b.ms - a.ms).slice(0, 20),
    };
    return value;
  }

  tracePath(id) {
    if (!/^[A-Za-z0-9_-]+$/.test(id) || !this.traces.has(id)) return null;
    return path.join(this.traceRoot, `${id}.json`);
  }
}

module.exports = { ProfilerMonitor, histogramPercentile, WINDOWS, TRACE_LIMIT, TRACE_BYTES_LIMIT };
