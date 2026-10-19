import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

function extractMsParsePatterns(source) {
  const parseStart = source.indexOf('parse = function');
  const tostringStart = source.indexOf('tostring = function');
  assert.notEqual(parseStart, -1, 'Ms.parse function must exist');
  assert.notEqual(tostringStart, -1, 'Ms.tostring function must exist');

  const parseSource = source.slice(parseStart, tostringStart);
  const patterns = [...parseSource.matchAll(/\{\s*"([^"]+)"\s*,\s*(\d+)\s*\}/g)]
    .map(match => ({unit: match[1], multiplier: Number(match[2])}));

  assert.ok(patterns.length > 0, 'Ms.parse unit patterns must be discoverable');
  return patterns;
}

function simulateLuaMsParse(patterns, input) {
  for (const {unit, multiplier} of patterns) {
    const match = input.match(new RegExp(`(\\d+)${unit}`));
    if (match) return Number(match[1]) * multiplier;
  }

  return null;
}

export const tests = [
  {
    name: "Ms.parse('500ms') returns milliseconds, not minutes",
    run({repoRoot}) {
      const source = fs.readFileSync(path.join(repoRoot, 'utils/ms.lua'), 'utf8');
      const patterns = extractMsParsePatterns(source);

      assert.equal(simulateLuaMsParse(patterns, '500ms'), 500);
    },
  },
  {
    name: "Ms.parse('5m') still returns minutes",
    run({repoRoot}) {
      const source = fs.readFileSync(path.join(repoRoot, 'utils/ms.lua'), 'utf8');
      const patterns = extractMsParsePatterns(source);

      assert.equal(simulateLuaMsParse(patterns, '5m'), 300000);
    },
  },
];
