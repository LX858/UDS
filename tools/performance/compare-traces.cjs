'use strict';

// Read-only comparison. Historical captures without load/context are not an A/B proof.
const fs = require('node:fs/promises');
const path = require('node:path');
const { analyzeTrace } = require('../../[standalone]/vx_profiler_monitor/trace');

async function summarize(directory) {
  const files = (await fs.readdir(directory)).filter(name => /^\d{8}T.*\.json$/.test(name)).sort();
  if (!files.length) throw new Error(`No profiler captures: ${directory}`);
  const frames = [], resources = new Map(), contexts = [];
  let recorded = 0, incomplete = 0;
  for (const file of files) {
    const sample = await analyzeTrace(path.join(directory, file));
    frames.push(...sample.frameTimes);
    recorded += sample.recordedFrames;
    incomplete += sample.incompleteFrames;
    for (const item of sample.resources) {
      const row = resources.get(item.resource) || { resource: item.resource, selfMs: 0, maxMs: 0 };
      row.selfMs += item.selfMs;
      row.maxMs = Math.max(row.maxMs, item.maxMs);
      resources.set(item.resource, row);
    }
    try {
      const metadata = JSON.parse(await fs.readFile(path.resolve(directory, '../samples', file), 'utf8'));
      contexts.push(metadata.context || null);
    } catch { contexts.push(null); }
  }
  frames.sort((a, b) => a - b);
  const percentile = p => frames[Math.max(0, Math.ceil(frames.length * p) - 1)] ?? null;
  return { directory: path.resolve(directory), files, recordedFrames: recorded, completeFrames: frames.length,
    unfinishedStartedFrames: recorded - frames.length, parserBoundaryMarkers: incomplete,
    p50Ms: percentile(.5), p95Ms: percentile(.95), p99Ms: percentile(.99),
    maxMs: frames.at(-1) ?? null, over50: frames.filter(ms => ms > 50).length,
    over100: frames.filter(ms => ms > 100).length, contexts,
    resources: [...resources.values()].sort((a, b) => b.selfMs - a.selfMs).map(row => ({ ...row,
      selfMs: Number(row.selfMs.toFixed(3)), selfMsPerCompleteFrame: Number((row.selfMs / frames.length).toFixed(4)) })) };
}

(async () => {
  const [beforeDir, afterDir] = process.argv.slice(2);
  if (!beforeDir) throw new Error('Usage: node tools/performance/compare-traces.cjs BASELINE_DIR [AFTER_DIR]');
  const before = await summarize(beforeDir);
  if (!afterDir) return console.log(JSON.stringify(before, null, 2));
  const after = await summarize(afterDir);
  console.log(JSON.stringify({ before, after,
    overlappingFiles: before.files.filter(file => after.files.includes(file)),
    interpretation: 'Compare only distinct captures with similar players/entities/activity and explicit monitor modes. These timings are not machine CPU or database latency.'
  }, null, 2));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
