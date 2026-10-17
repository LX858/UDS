'use strict';

const fs = require('fs');
const path = require('path');
const { StatsStore } = require('./stats');

const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;
const SEGMENT_BYTES = 128 * 1024 * 1024;
const MAX_DISK_BYTES = 2 * 1024 * 1024 * 1024;
const MAX_QUEUE = 50000;
const RECENT_SIZE = 10000;

function short(value, max = 160) {
  return typeof value === 'string' ? value.slice(0, max) : null;
}

function positiveInteger(value) {
  const number = Number(value);
  return Number.isSafeInteger(number) && number > 0 ? number : null;
}

function nonNegativeNumber(value) {
  if (value === null || value === undefined || value === '') return null;
  const number = Number(value);
  return Number.isFinite(number) && number >= 0 ? number : null;
}

function pageArgs(query) {
  const limit = Math.min(200, Math.max(1, Number.parseInt(query.limit, 10) || 100));
  const page = Math.min(50, Math.max(1, Number.parseInt(query.page, 10) || 1));
  return { limit, page };
}

function matches(record, query) {
  if (query.clean === '1' && ((record.name || '').startsWith('__cfx_internal:') ||
      (record.kind === 'event' && ['receive', 'register', 'unregister', 'net-register'].includes(record.phase)) ||
      (record.kind === 'export' && ['invoke', 'register'].includes(record.phase)))) return false;
  for (const field of ['kind', 'phase', 'resource', 'targetResource', 'status']) {
    if (query[field] && String(record[field] || '').toLowerCase() !== query[field].toLowerCase()) return false;
  }
  if (query.name && !String(record.name || '').toLowerCase().includes(query.name.toLowerCase())) return false;
  if (query.playerSessionId && record.playerSessionId !== Number(query.playerSessionId)) return false;
  if (query.entityNetId && record.entityNetId !== Number(query.entityNetId)) return false;
  const time = Date.parse(record.timestamp);
  if (query.from && time < Date.parse(query.from)) return false;
  if (query.to && time > Date.parse(query.to)) return false;
  return true;
}

async function* reverseLines(file) {
  const handle = await fs.promises.open(file, 'r');
  try {
    let position = (await handle.stat()).size;
    let remainder = Buffer.alloc(0);
    while (position > 0) {
      const size = Math.min(64 * 1024, position);
      position -= size;
      const chunk = Buffer.allocUnsafe(size);
      const { bytesRead } = await handle.read(chunk, 0, size, position);
      const combined = Buffer.concat([chunk.subarray(0, bytesRead), remainder]);
      let end = combined.length;
      for (let i = combined.length - 1; i >= 0; i--) {
        if (combined[i] !== 10) continue;
        if (end > i + 1) yield combined.subarray(i + 1, end).toString('utf8').replace(/\r$/, '');
        end = i;
      }
      remainder = combined.subarray(0, end);
    }
    if (remainder.length) yield remainder.toString('utf8').replace(/\r$/, '');
  } finally {
    await handle.close();
  }
}

class MonitorStore {
  constructor(root, options = {}) {
    this.root = root;
    this.logRoot = path.join(root, 'logs');
    this.now = options.now || Date.now;
    this.queueLimit = options.queueLimit || MAX_QUEUE;
    this.recentSize = options.recentSize || RECENT_SIZE;
    this.segmentBytes = options.segmentBytes || SEGMENT_BYTES;
    this.maxDiskBytes = options.maxDiskBytes || MAX_DISK_BYTES;
    this.retentionMs = options.retentionMs || DAY_MS;
    this.queue = [];
    this.recent = new Array(this.recentSize);
    this.recentWrite = 0;
    this.recentCount = 0;
    this.players = new Map();
    this.entities = new Map();
    this.agents = new Map();
    this.total = 0;
    this.droppedCollector = 0;
    this.droppedDisk = 0;
    this.droppedAgents = 0;
    this.droppedAgentsInitial = 0;
    this.droppedAgentsAfterStart = 0;
    this.countByKind = new Map();
    this.countByName = new Map();
    this.countByResource = new Map();
    this.segment = null;
    this.writing = null;
    this.diskError = null;
    this.retryAfter = 0;
    this.startedAt = new Date(this.now()).toISOString();
    this.timers = [];
    try {
      fs.mkdirSync(this.logRoot, { recursive: true });
    } catch (error) {
      this.diskError = String(error.message || error).slice(0, 300);
      this.retryAfter = this.now() + 5000;
      console.error(`[vx_runtime_monitor] Log directory unavailable: ${this.diskError}`);
    }
    this.stats = new StatsStore(this, { now: this.now });
    this.stats.ready = this.stats.initialize().catch(error => {
      this.stats.rebuilding = false;
      console.error(`[vx_runtime_monitor] Stats rebuild failed: ${error.message}`);
    });
  }

  start() {
    this.timers.push(setInterval(() => { this.flush().catch(() => {}); }, 250));
    this.timers.push(setInterval(() => { this.cleanup().catch(() => {}); }, 60000));
  }

  async stop() {
    for (const timer of this.timers) clearInterval(timer);
    this.timers = [];
    await this.flushAll();
    if (this.queue.length) {
      this.droppedDisk += this.queue.length;
      this.queue = [];
    }
  }

  normalize(input) {
    if (!input || typeof input !== 'object') return null;
    const kind = short(input.kind, 20);
    const phase = short(input.phase, 32);
    const name = short(input.name, 160);
    if (!kind || !phase || !name) return null;
    const playerSessionId = positiveInteger(input.playerSessionId);
    const suppliedTime = Date.parse(input.timestamp);
    return {
      timestamp: new Date(Number.isFinite(suppliedTime) ? suppliedTime : this.now()).toISOString(),
      kind, phase, name,
      resource: short(input.resource, 100),
      targetResource: short(input.targetResource, 100),
      callerResource: short(input.callerResource, 100),
      playerSessionId,
      playerName: short(input.playerName, 80) || (playerSessionId && this.players.get(playerSessionId)?.name) || null,
      entityNetId: nonNegativeNumber(input.entityNetId),
      payloadBytes: nonNegativeNumber(input.payloadBytes),
      wallMs: nonNegativeNumber(input.wallMs),
      monoMs: nonNegativeNumber(input.monoMs),
      status: short(input.status, 32),
    };
  }

  record(input) {
    const record = this.normalize(input);
    if (!record) return false;
    if (this.queue.length >= this.queueLimit) {
      this.droppedCollector++;
      return false;
    }
    this.queue.push(record);
    this.recent[this.recentWrite] = record;
    this.recentWrite = (this.recentWrite + 1) % this.recentSize;
    this.recentCount = Math.min(this.recentCount + 1, this.recentSize);
    this.total++;
    this.increment(this.countByKind, kindKey(record));
    this.increment(this.countByName, `${record.kind}:${record.name}`);
    this.increment(this.countByResource, record.resource || 'unknown');
    return true;
  }

  increment(map, key) {
    if (map.has(key)) map.set(key, map.get(key) + 1);
    else if (map.size < 5000) map.set(key, 1);
    else map.set('other', (map.get('other') || 0) + 1);
  }

  acceptBatch(batch) {
    if (!batch || typeof batch !== 'object' || !Array.isArray(batch.records)) return;
    const resource = short(batch.resource, 100);
    if (!resource || batch.records.length > 4096) return;
    const prior = this.agents.get(resource);
    const reportedDropped = nonNegativeNumber(batch.dropped) || 0;
    const increase = prior && reportedDropped < prior.reportedDropped
      ? reportedDropped : Math.max(0, reportedDropped - (prior?.reportedDropped || 0));
    this.droppedAgents += increase;
    if (prior) this.droppedAgentsAfterStart += increase;
    else this.droppedAgentsInitial += increase;
    this.agents.set(resource, { lastSeen: this.now(), reportedDropped });
    const batchMono = nonNegativeNumber(batch.monoMs);
    const receivedAt = this.now();
    for (const input of batch.records) {
      if (!input || typeof input !== 'object') continue;
      const eventMono = nonNegativeNumber(input.monoMs);
      const age = batchMono !== null && eventMono !== null ? Math.max(0, Math.min(60000, batchMono - eventMono)) : 0;
      this.record({ ...input, resource, timestamp: new Date(receivedAt - age).toISOString() });
    }
  }

  upsertPlayer(id, name) {
    id = positiveInteger(id);
    if (!id) return;
    this.players.set(id, { id, name: short(name, 80) || null, joinedAt: new Date(this.now()).toISOString() });
  }

  removePlayer(id) {
    this.players.delete(Number(id));
  }

  upsertEntity(entity) {
    if (!entity || !positiveInteger(entity.handle)) return;
    this.entities.set(entity.handle, entity);
  }

  removeEntity(handle) {
    const existing = this.entities.get(Number(handle)) || null;
    this.entities.delete(Number(handle));
    return existing;
  }

  async flush() {
    if (this.writing || !this.queue.length || this.now() < this.retryAfter) return this.writing;
    const batch = this.queue.splice(0, 5000);
    this.writing = (async () => {
      try {
        const text = batch.map(record => JSON.stringify(record)).join('\n') + '\n';
        const bytes = Buffer.byteLength(text);
        const file = await this.nextSegment(bytes);
        await fs.promises.appendFile(file, text, 'utf8');
        this.segment.bytes += bytes;
        this.stats.onPersisted(batch);
        this.diskError = null;
        this.retryAfter = 0;
      } catch (error) {
        this.droppedDisk += batch.length;
        this.diskError = String(error.message || error).slice(0, 300);
        this.retryAfter = this.now() + 5000;
        this.segment = null;
        if (this.droppedDisk === batch.length || this.droppedDisk % 10000 < batch.length) {
          console.error(`[vx_runtime_monitor] Log write failed; dropped ${this.droppedDisk} records: ${this.diskError}`);
        }
      } finally {
        this.writing = null;
        if (this.queue.length && this.now() >= this.retryAfter) setImmediate(() => { this.flush().catch(() => {}); });
      }
    })();
    return this.writing;
  }

  async flushAll() {
    while (this.writing || this.queue.length) {
      if (this.writing) await this.writing;
      else if (this.now() < this.retryAfter) break;
      else await this.flush();
    }
  }

  async nextSegment(incomingBytes) {
    const date = new Date(this.now());
    const day = date.toISOString().slice(0, 10);
    const hour = date.toISOString().slice(11, 13);
    if (this.segment && this.segment.day === day && this.segment.hour === hour &&
        this.segment.bytes + incomingBytes <= this.segmentBytes) return this.segment.file;
    const dir = path.join(this.logRoot, day);
    await fs.promises.mkdir(dir, { recursive: true });
    const files = (await fs.promises.readdir(dir)).filter(name => name.startsWith(`${hour}-`) && name.endsWith('.jsonl')).sort();
    let index = files.length ? Number(files[files.length - 1].slice(3, 6)) : 0;
    let file = path.join(dir, `${hour}-${String(index).padStart(3, '0')}.jsonl`);
    let bytes = (await fs.promises.stat(file).catch(() => ({ size: 0 }))).size;
    if (bytes + incomingBytes > this.segmentBytes && bytes > 0) {
      index++;
      file = path.join(dir, `${hour}-${String(index).padStart(3, '0')}.jsonl`);
      bytes = 0;
    }
    this.segment = { day, hour, file, bytes };
    return file;
  }

  async segments() {
    const result = [];
    for (const day of await fs.promises.readdir(this.logRoot).catch(() => [])) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) continue;
      const dir = path.join(this.logRoot, day);
      for (const name of await fs.promises.readdir(dir).catch(() => [])) {
        if (!/^\d{2}-\d{3}\.jsonl$/.test(name)) continue;
        const file = path.join(dir, name);
        const stat = await fs.promises.stat(file).catch(() => null);
        if (stat) result.push({
          file, size: stat.size, mtimeMs: stat.mtimeMs,
          hourStartMs: Date.parse(`${day}T${name.slice(0, 2)}:00:00.000Z`),
        });
      }
    }
    result.sort((a, b) => a.file.localeCompare(b.file));
    return result;
  }

  async cleanup() {
    const currentHour = new Date(this.now()).toISOString().slice(0, 13);
    if (!this.writing && this.segment && `${this.segment.day}T${this.segment.hour}` !== currentHour) {
      this.segment = null;
    }
    const files = await this.segments();
    let total = files.reduce((sum, file) => sum + file.size, 0);
    const cutoff = this.now() - this.retentionMs;
    for (const item of files) {
      if (item.file === this.segment?.file) continue;
      if (item.hourStartMs >= cutoff && total <= this.maxDiskBytes) continue;
      try {
        await fs.promises.unlink(item.file);
        total -= item.size;
      } catch (error) {
        console.error(`[vx_runtime_monitor] Log cleanup failed: ${error.message}`);
      }
    }
    return total;
  }

  recentRecords(query) {
    const { page, limit } = pageArgs(query);
    const skip = (page - 1) * limit;
    const records = [];
    let found = 0;
    for (let i = 0; i < this.recentCount; i++) {
      const index = (this.recentWrite - i - 1 + this.recentSize) % this.recentSize;
      const record = this.recent[index];
      if (!matches(record, query)) continue;
      if (found++ < skip) continue;
      records.push(record);
      if (records.length > limit) break;
    }
    return { records: records.slice(0, limit), page, limit, hasMore: records.length > limit, source: 'recent' };
  }

  async historicalRecords(query) {
    if (this.writing) await this.writing;
    else await this.flush();
    const { page, limit } = pageArgs(query);
    const skip = (page - 1) * limit;
    const records = [];
    let found = 0;
    const files = await this.segments();
    for (let fileIndex = files.length - 1; fileIndex >= 0; fileIndex--) {
      for await (const line of reverseLines(files[fileIndex].file)) {
        if (!line) continue;
        let record;
        try { record = JSON.parse(line); } catch { continue; }
        if (!matches(record, query)) continue;
        if (found++ < skip) continue;
        records.push(record);
        if (records.length > limit) {
          return { records: records.slice(0, limit), page, limit, hasMore: true, source: 'disk' };
        }
      }
    }
    return { records, page, limit, hasMore: false, source: 'disk' };
  }

  listPlayers(query) {
    const { page, limit } = pageArgs(query);
    const items = [...this.players.values()].sort((a, b) => a.id - b.id);
    return { items: items.slice((page - 1) * limit, page * limit), total: items.length, page, limit };
  }

  listEntities(query) {
    const { page, limit } = pageArgs(query);
    let items = [...this.entities.values()];
    if (query.type) items = items.filter(entity => entity.type === query.type);
    if (query.resource) items = items.filter(entity => entity.resource === query.resource);
    items.sort((a, b) => a.handle - b.handle);
    return { items: items.slice((page - 1) * limit, page * limit), total: items.length, page, limit };
  }

  summary() {
    const top = map => [...map.entries()].sort((a, b) => b[1] - a[1]).slice(0, 15).map(([name, count]) => ({ name, count }));
    return {
      startedAt: this.startedAt,
      total: this.total,
      queue: this.queue.length,
      players: this.players.size,
      entities: this.entities.size,
      agents: this.agents.size,
      dropped: { agents: this.droppedAgents, agentsInitial: this.droppedAgentsInitial,
        agentsAfterStart: this.droppedAgentsAfterStart, collector: this.droppedCollector, disk: this.droppedDisk },
      diskError: this.diskError,
      byKind: top(this.countByKind),
      byName: top(this.countByName),
      byResource: top(this.countByResource),
    };
  }
}

function kindKey(record) { return record.kind; }

module.exports = { MonitorStore, pageArgs, matches };
