'use strict';

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const MINUTE = 60_000;
const WINDOWS = { '5m': 5 * MINUTE, '1h': 60 * MINUTE, '24h': 24 * 60 * MINUTE };
const VIEWS = new Set(['client', 'local', 'handled', 'exports']);
const GROUP_LIMIT = 5000;

function viewOf(record) {
  if (record.kind === 'event') {
    if (record.phase === 'send-client' || record.phase === 'send-latent') return 'client';
    if (record.phase === 'send-local') return 'local';
    if (record.phase === 'handler') return 'handled';
  }
  if (record.kind === 'export' && (record.phase === 'call' || record.phase === 'invoke')) return 'exports';
  return null;
}

function useful(record) {
  return Boolean(record && typeof record.name === 'string' && !record.name.startsWith('__cfx_internal:') && viewOf(record));
}

function fresh() {
  return { groups: new Map(), total: 0, broadcast: 0, targeted: 0, overflow: 0,
    overflowBroadcast: 0, overflowTargeted: 0, earliest: null, latest: null };
}

function add(aggregate, record, limit = GROUP_LIMIT) {
  if (!useful(record)) return;
  const time = Date.parse(record.timestamp);
  if (!Number.isFinite(time)) return;
  const count = Number.isSafeInteger(record.count) && record.count > 0 ? Math.min(record.count, 1000000) : 1;
  aggregate.total += count;
  aggregate.earliest = aggregate.earliest === null ? time : Math.min(aggregate.earliest, time);
  aggregate.latest = aggregate.latest === null ? time : Math.max(aggregate.latest, time);
  const view = viewOf(record);
  const isBroadcast = view === 'client' && record.status === 'broadcast';
  const isTargeted = view === 'client' && !isBroadcast && (record.targeted === true ||
    (Number.isSafeInteger(record.playerSessionId) && record.playerSessionId > 0));
  if (isBroadcast) aggregate.broadcast += count;
  if (isTargeted) aggregate.targeted += count;
  const resource = record.resource || 'Không rõ';
  const phase = view === 'exports' ? record.phase : null;
  const key = JSON.stringify([record.name, resource, phase]);
  let group = aggregate.groups.get(key);
  if (!group) {
    if (aggregate.groups.size >= limit) {
      aggregate.overflow += count;
      if (isBroadcast) aggregate.overflowBroadcast += count;
      if (isTargeted) aggregate.overflowTargeted += count;
      return;
    }
    group = { name: record.name, resource, phase, count: 0, broadcast: 0, targeted: 0,
      targets: new Map(), senders: new Map(), lastAt: 0, errors: 0 };
    aggregate.groups.set(key, group);
  }
  group.count += count;
  group.lastAt = Math.max(group.lastAt, time);
  if (record.status === 'error') group.errors += count;
  if (isBroadcast) {
    group.broadcast += count;
    group.targets.set('-1', (group.targets.get('-1') || 0) + count);
  } else if (isTargeted) {
    group.targeted += count;
    const target = record.playerSessionId ? String(record.playerSessionId) : 'aggregate';
    group.targets.set(target, (group.targets.get(target) || 0) + count);
  } else if (view === 'handled' && Number.isSafeInteger(record.playerSessionId) && record.playerSessionId > 0) {
    const sender = String(record.playerSessionId);
    group.senders.set(sender, (group.senders.get(sender) || 0) + count);
  }
}

function merge(into, from, limit = GROUP_LIMIT) {
  into.total += from.total;
  into.broadcast += from.broadcast;
  into.targeted += from.targeted;
  into.overflow += from.overflow;
  into.overflowBroadcast += from.overflowBroadcast;
  into.overflowTargeted += from.overflowTargeted;
  if (from.earliest !== null) into.earliest = into.earliest === null ? from.earliest : Math.min(into.earliest, from.earliest);
  if (from.latest !== null) into.latest = into.latest === null ? from.latest : Math.max(into.latest, from.latest);
  for (const [key, source] of from.groups) {
    let target = into.groups.get(key);
    if (!target) {
      if (into.groups.size >= limit) {
        into.overflow += source.count;
        into.overflowBroadcast += source.broadcast;
        into.overflowTargeted += source.targeted;
        continue;
      }
      target = { name: source.name, resource: source.resource, phase: source.phase, count: 0,
        broadcast: 0, targeted: 0, targets: new Map(), senders: new Map(), lastAt: 0, errors: 0 };
      into.groups.set(key, target);
    }
    target.count += source.count;
    target.broadcast += source.broadcast;
    target.targeted += source.targeted;
    target.lastAt = Math.max(target.lastAt, source.lastAt);
    target.errors += source.errors;
    for (const [id, count] of source.targets) target.targets.set(id, (target.targets.get(id) || 0) + count);
    for (const [id, count] of source.senders) target.senders.set(id, (target.senders.get(id) || 0) + count);
  }
}

function filesSnapshot(logRoot) {
  const files = [];
  let days;
  try { days = fs.readdirSync(logRoot, { withFileTypes: true }); } catch { return files; }
  for (const day of days.filter(item => item.isDirectory() && /^\d{4}-\d{2}-\d{2}$/.test(item.name))) {
    const dir = path.join(logRoot, day.name);
    let items;
    try { items = fs.readdirSync(dir, { withFileTypes: true }); } catch { continue; }
    for (const item of items) {
      if (!item.isFile() || !/^\d{2}-\d{3}\.jsonl$/.test(item.name)) continue;
      const file = path.join(dir, item.name);
      let stat;
      try { stat = fs.statSync(file); } catch { continue; }
      files.push({ file, size: stat.size, hourStartMs: Date.parse(`${day.name}T${item.name.slice(0, 2)}:00:00.000Z`) });
    }
  }
  return files.sort((a, b) => a.file.localeCompare(b.file));
}

async function scanFiles(files, from, to, onRecord) {
  let scanned = 0;
  let earliest = null;
  let incomplete = false;
  for (const item of files) {
    if (item.hourStartMs + 60 * MINUTE < from || item.hourStartMs > to || item.size === 0) continue;
    let stream;
    try {
      stream = fs.createReadStream(item.file, { start: 0, end: item.size - 1, encoding: 'utf8' });
      for await (const line of readline.createInterface({ input: stream, crlfDelay: Infinity })) {
        let record;
        try { record = JSON.parse(line); } catch { continue; }
        const time = Date.parse(record.timestamp);
        if (!Number.isFinite(time)) continue;
        earliest = earliest === null ? time : Math.min(earliest, time);
        if (time >= from && time <= to) onRecord(record);
        if (++scanned % 2000 === 0) await new Promise(resolve => setImmediate(resolve));
      }
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
      incomplete = true;
    } finally { stream?.destroy(); }
  }
  return { earliest, incomplete };
}

function summarize(aggregate, view, window, from, to, retainedFrom, incomplete, selectedName, search) {
  const names = new Map();
  for (const group of aggregate.groups.values()) {
    if (search && !group.name.toLowerCase().includes(search.toLowerCase()) &&
        !group.resource.toLowerCase().includes(search.toLowerCase())) continue;
    const key = JSON.stringify([group.name, group.phase]);
    let row = names.get(key);
    if (!row) {
      row = { name: group.name, phase: group.phase, count: 0, broadcast: 0, targeted: 0,
        topResource: null, topResourceCount: 0, lastAt: null, errors: 0, resources: [], targets: new Map(), senders: new Map() };
      names.set(key, row);
    }
    row.count += group.count;
    row.broadcast += group.broadcast;
    row.targeted += group.targeted;
    row.errors += group.errors;
    row.lastAt = Math.max(row.lastAt || 0, group.lastAt);
    row.resources.push({ resource: group.resource, count: group.count });
    if (group.count > row.topResourceCount) { row.topResource = group.resource; row.topResourceCount = group.count; }
    for (const [id, count] of group.targets) row.targets.set(id, (row.targets.get(id) || 0) + count);
    for (const [id, count] of group.senders) row.senders.set(id, (row.senders.get(id) || 0) + count);
  }
  if (aggregate.overflow && !search) names.set('other', { name: 'Khác', phase: null, count: aggregate.overflow,
    broadcast: aggregate.overflowBroadcast, targeted: aggregate.overflowTargeted,
    topResource: null, lastAt: null, errors: 0, resources: [], targets: new Map(), senders: new Map() });
  const rows = [...names.values()].sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
  const top = rows.slice(0, 50);
  if (aggregate.overflow && !search && !top.some(row => row.name === 'Khác')) {
    const other = rows.find(row => row.name === 'Khác');
    if (other) top[Math.min(49, top.length)] = other;
  }
  const plain = row => ({ name: row.name, phase: row.phase, count: row.count, broadcast: row.broadcast,
    targeted: row.targeted, topResource: row.topResource, lastAt: row.lastAt ? new Date(row.lastAt).toISOString() : null, errors: row.errors });
  const chosen = selectedName ? rows.filter(row => row.name === selectedName) : [];
  const breakdown = chosen.length ? {
    name: selectedName,
    phases: chosen.map(plain),
    resources: chosen.flatMap(row => row.resources.map(entry => ({ ...entry, phase: row.phase }))).sort((a, b) => b.count - a.count),
    targets: [...chosen.reduce((map, row) => { for (const [id, count] of row.targets) map.set(id, (map.get(id) || 0) + count); return map; }, new Map())]
      .map(([id, count]) => ({ id, count })).sort((a, b) => b.count - a.count),
    senders: [...chosen.reduce((map, row) => { for (const [id, count] of row.senders) map.set(id, (map.get(id) || 0) + count); return map; }, new Map())]
      .map(([id, count]) => ({ id, count })).sort((a, b) => b.count - a.count),
  } : null;
  const partialReasons = [];
  if (retainedFrom !== null && retainedFrom > from + MINUTE) partialReasons.push('retention');
  if (aggregate.overflow) partialReasons.push('group_limit');
  if (incomplete) partialReasons.push('scan_incomplete');
  const shownTotal = search ? rows.reduce((sum, row) => sum + row.count, 0) : aggregate.total;
  const shownBroadcast = search ? rows.reduce((sum, row) => sum + row.broadcast, 0) : aggregate.broadcast;
  const shownTargeted = search ? rows.reduce((sum, row) => sum + row.targeted, 0) : aggregate.targeted;
  return { window, view, from: new Date(from).toISOString(), to: new Date(to).toISOString(),
    availableFrom: new Date(Math.max(from, retainedFrom ?? from)).toISOString(),
    retainedFrom: retainedFrom === null ? null : new Date(retainedFrom).toISOString(),
    total: shownTotal, broadcast: shownBroadcast, targeted: shownTargeted,
    partial: partialReasons.length > 0, partialReasons, top: top.map(plain), selected: breakdown };
}

class StatsStore {
  constructor(store, options = {}) {
    this.store = store;
    this.now = options.now || store.now;
    this.groupLimit = options.groupLimit || GROUP_LIMIT;
    this.minutes = new Map();
    this.knownGroups = new Map();
    this.shortMinutes = new Map();
    this.shortKnownGroups = new Map();
    this.lastPruned = 0;
    this.shortLastPruned = 0;
    this.rebuilding = true;
    this.retainedFrom = null;
    this.cache = new Map();
    this.dayScan = null;
    this.snapshot = filesSnapshot(store.logRoot);
  }

  async initialize() {
    const from = this.now() - 60 * MINUTE;
    const result = await scanFiles(this.snapshot, from, this.now(), record => this.ingest(record));
    if (result.earliest !== null) this.retainedFrom = this.retainedFrom === null
      ? result.earliest : Math.min(this.retainedFrom, result.earliest);
    this.rebuilding = false;
    this.snapshot = [];
  }

  onPersisted(batch) {
    for (const record of batch) this.ingest(record);
  }

  ingest(record) {
    if (!useful(record)) return;
    const time = Date.parse(record.timestamp);
    if (!Number.isFinite(time)) return;
    const minute = Math.floor(time / MINUTE) * MINUTE;
    this.ingestWindow(record, minute, 60, this.minutes, this.knownGroups, 'lastPruned');
    this.ingestWindow(record, minute, 5, this.shortMinutes, this.shortKnownGroups, 'shortLastPruned');
    if (this.retainedFrom === null || time < this.retainedFrom) this.retainedFrom = time;
  }

  ingestWindow(record, minute, count, buckets, knownGroups, pruneField) {
    const currentMinute = Math.floor(this.now() / MINUTE) * MINUTE;
    const firstMinute = currentMinute - (count - 1) * MINUTE;
    if (this[pruneField] !== currentMinute) {
      this[pruneField] = currentMinute;
      for (const [bucketKey, bucket] of buckets) {
        const [bucketMinute, bucketView] = bucketKey.split(':');
        if (Number(bucketMinute) >= firstMinute) continue;
        const refs = knownGroups.get(bucketView);
        for (const groupKey of bucket.groups.keys()) {
          const next = (refs.get(groupKey) || 0) - 1;
          if (next > 0) refs.set(groupKey, next); else refs.delete(groupKey);
        }
        buckets.delete(bucketKey);
      }
    }
    if (minute < firstMinute || minute > currentMinute) return;
    const view = viewOf(record);
    const key = `${minute}:${view}`;
    let aggregate = buckets.get(key);
    if (!aggregate) { aggregate = fresh(); buckets.set(key, aggregate); }
    const groupKey = JSON.stringify([record.name, record.resource || 'Không rõ', view === 'exports' ? record.phase : null]);
    let known = knownGroups.get(view);
    if (!known) { known = new Map(); knownGroups.set(view, known); }
    const alreadyInBucket = aggregate.groups.has(groupKey);
    const overWindowLimit = !alreadyInBucket && !known.has(groupKey) && known.size >= this.groupLimit;
    add(aggregate, record, overWindowLimit ? 0 : this.groupLimit);
    if (!alreadyInBucket && aggregate.groups.has(groupKey)) known.set(groupKey, (known.get(groupKey) || 0) + 1);
  }

  async get(query) {
    const window = query.window || '5m';
    const view = query.view || 'client';
    if (!WINDOWS[window] || !VIEWS.has(view)) throw new RangeError('invalid_stats_query');
    const selectedName = query.name || null;
    const search = query.search || null;
    const to = this.now();
    const from = window === '24h' ? to - WINDOWS[window]
      : Math.floor(to / MINUTE) * MINUTE - WINDOWS[window] + MINUTE;
    if (window !== '24h') {
      if (this.rebuilding) await this.ready;
      const aggregate = fresh();
      const buckets = window === '5m' ? this.shortMinutes : this.minutes;
      for (const [key, bucket] of buckets) {
        const [minute, bucketView] = key.split(':');
        if (bucketView === view && Number(minute) + MINUTE > from && Number(minute) <= to) merge(aggregate, bucket, this.groupLimit);
      }
      return summarize(aggregate, view, window, from, to, this.retainedFrom, false, selectedName, search);
    }
    let cached = this.cache.get(view);
    if (!cached || cached.expires <= to) {
      if (!this.dayScan) {
        this.dayScan = (async () => {
          if (this.store.writing) await this.store.writing;
          const files = await this.store.segments();
          const aggregates = new Map([...VIEWS].map(item => [item, fresh()]));
          const scan = await scanFiles(files, from, to, record => {
            const itemView = viewOf(record);
            if (itemView) add(aggregates.get(itemView), record, this.groupLimit);
          });
          const expires = this.now() + 60_000;
          for (const itemView of VIEWS) {
            this.cache.set(itemView, { expires, value: {
              aggregate: aggregates.get(itemView), retainedFrom: scan.earliest,
              incomplete: scan.incomplete, from, to,
            } });
          }
        })();
        this.dayScan.finally(() => { this.dayScan = null; }).catch(() => {});
      }
      await this.dayScan;
      cached = this.cache.get(view);
    }
    const result = cached.value;
    return summarize(result.aggregate, view, window, result.from, result.to, result.retainedFrom, result.incomplete, selectedName, search);
  }
}

module.exports = { StatsStore, viewOf, useful, add, fresh, merge, summarize, scanFiles };
