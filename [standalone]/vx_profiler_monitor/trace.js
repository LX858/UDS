'use strict';

const fs = require('fs');

const MAX_TRACE_BYTES = 128 * 1024 * 1024;
const MAX_EVENT_BYTES = 2 * 1024 * 1024;

const yieldLoop = () => new Promise(resolve => setImmediate(resolve));

async function* traceEvents(file, maxBytes = MAX_TRACE_BYTES) {
  const stat = await fs.promises.stat(file);
  if (!stat.size || stat.size > maxBytes) throw new Error('trace_size_invalid');
  const stream = fs.createReadStream(file, { encoding: 'utf8', highWaterMark: 64 * 1024 });
  let state = 'key', prefix = '', object = '', depth = 0, quoted = false, escaped = false;
  try {
    for await (const chunk of stream) {
      for (let i = 0; i < chunk.length; i++) {
        const char = chunk[i];
        if (state === 'key') {
          prefix = (prefix + char).slice(-32);
          if (prefix.endsWith('"traceEvents"')) state = 'array';
        } else if (state === 'array') {
          if (char === '[') state = 'between';
          else if (char !== ':' && !/\s/.test(char)) throw new Error('trace_array_invalid');
        } else if (state === 'between') {
          if (char === ']') state = 'done';
          else if (char === '{') { state = 'object'; object = '{'; depth = 1; quoted = false; escaped = false; }
          else if (char !== ',' && !/\s/.test(char)) throw new Error('trace_event_invalid');
        } else if (state === 'object') {
          object += char;
          if (object.length > MAX_EVENT_BYTES) throw new Error('trace_event_too_large');
          if (escaped) { escaped = false; continue; }
          if (quoted && char === '\\') { escaped = true; continue; }
          if (char === '"') { quoted = !quoted; continue; }
          if (!quoted && char === '{') depth++;
          if (!quoted && char === '}' && --depth === 0) {
            yield JSON.parse(object);
            object = '';
            state = 'between';
          }
        }
      }
      await yieldLoop();
    }
  } finally {
    stream.destroy();
  }
  if (state !== 'done') throw new Error('trace_incomplete');
}

function resourceFromLabel(label, knownResources) {
  if (typeof label !== 'string' || !label.endsWith(')')) return null;
  const at = label.lastIndexOf(' (');
  if (at < 0) return null;
  const resource = label.slice(at + 2, -1);
  const reason = label.slice(0, at);
  if (knownResources && knownResources.has(resource)) return resource;
  if (reason === 'tick' || reason.startsWith('event:')) return resource;
  return null;
}

function percentile(sorted, p) {
  return sorted.length ? sorted[Math.max(0, Math.ceil(sorted.length * p) - 1)] : null;
}

function round(value) { return Math.round(value * 1000) / 1000; }

async function analyzeTrace(file, options = {}) {
  const knownResources = options.knownResources || null;
  const stacks = new Map(), frameStarts = new Map(), frameTimes = [], slowFrames = [];
  const resources = new Map(), scopes = new Map();
  let beginFrames = 0, unmatched = 0, invalidFrames = 0, eventCount = 0;
  for await (const event of traceEvents(file, options.maxBytes || MAX_TRACE_BYTES)) {
    eventCount++;
    const ts = Number(event.ts), tid = Number(event.tid);
    if (!Number.isFinite(ts) || !Number.isFinite(tid)) continue;
    if (event.name === 'BeginFrame' && event.ph === 'I') {
      beginFrames++;
      if (frameStarts.has(tid)) invalidFrames++;
      frameStarts.set(tid, { ts, index: beginFrames });
      continue;
    }
    if (event.name === 'DrawFrame' && event.ph === 'I') {
      const start = frameStarts.get(tid);
      frameStarts.delete(tid);
      if (!start || ts < start.ts) { invalidFrames++; continue; }
      const ms = round((ts - start.ts) / 1000);
      frameTimes.push(ms);
      slowFrames.push({ frame: start.index, ms });
      continue;
    }
    if (event.ph !== 'B' && event.ph !== 'E') continue;
    let stack = stacks.get(tid);
    if (!stack) { stack = []; stacks.set(tid, stack); }
    if (event.ph === 'B') {
      const resource = resourceFromLabel(event.name, knownResources);
      const activeResource = [...stack].reverse().find(item => item.kind === 'resource')?.resource || null;
      stack.push({ name: event.name, kind: resource ? 'resource' : 'scope',
        resource: resource || activeResource, start: ts, childResourceUs: 0 });
      continue;
    }
    const item = stack.pop();
    if (!item || item.name !== event.name || ts < item.start) { unmatched++; stack.length = 0; continue; }
    const durationUs = ts - item.start;
    if (item.kind === 'resource') {
      const selfUs = Math.max(0, durationUs - item.childResourceUs);
      const entry = resources.get(item.resource) || { resource: item.resource, selfMs: 0, inclusiveMs: 0, calls: 0, maxMs: 0 };
      entry.selfMs += selfUs / 1000;
      entry.inclusiveMs += durationUs / 1000;
      entry.calls++;
      entry.maxMs = Math.max(entry.maxMs, durationUs / 1000);
      resources.set(item.resource, entry);
      for (let j = stack.length - 1; j >= 0; j--) {
        if (stack[j].kind === 'resource') { stack[j].childResourceUs += durationUs; break; }
      }
    } else if (item.resource && item.name !== 'Resource Manager Tick') {
      const key = `${item.resource}\u0000${item.name}`;
      const entry = scopes.get(key) || { resource: item.resource, name: item.name, totalMs: 0, calls: 0, maxMs: 0 };
      entry.totalMs += durationUs / 1000;
      entry.calls++;
      entry.maxMs = Math.max(entry.maxMs, durationUs / 1000);
      scopes.set(key, entry);
    }
  }
  const sorted = [...frameTimes].sort((a, b) => a - b);
  const frameHistogram = {};
  for (const ms of frameTimes) {
    const bucket = String(Math.floor(ms));
    frameHistogram[bucket] = (frameHistogram[bucket] || 0) + 1;
  }
  return {
    recordedFrames: beginFrames,
    analyzedFrames: frameTimes.length,
    incompleteFrames: invalidFrames + frameStarts.size,
    unmatchedScopes: unmatched + [...stacks.values()].reduce((count, stack) => count + stack.length, 0),
    eventCount,
    frameTimes,
    frameHistogram,
    frames: { p50Ms: percentile(sorted, .5), p95Ms: percentile(sorted, .95),
      p99Ms: percentile(sorted, .99), maxMs: sorted.at(-1) ?? null,
      over50Ms: sorted.filter(ms => ms > 50).length },
    slowFrames: slowFrames.sort((a, b) => b.ms - a.ms).slice(0, 20),
    resources: [...resources.values()].map(item => ({ ...item,
      selfMs: round(item.selfMs), inclusiveMs: round(item.inclusiveMs), maxMs: round(item.maxMs) }))
      .sort((a, b) => b.selfMs - a.selfMs),
    scopes: [...scopes.values()].map(item => ({ ...item,
      totalMs: round(item.totalMs), maxMs: round(item.maxMs) }))
      .sort((a, b) => b.totalMs - a.totalMs).slice(0, 100),
    scopesPartial: scopes.size > 100,
  };
}

module.exports = { analyzeTrace, traceEvents, percentile, MAX_TRACE_BYTES };
