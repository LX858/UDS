import assert from 'node:assert/strict';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import test from 'node:test';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const webRoot = path.join(repoRoot, 'web');

test('contract package subpaths load through native Node ESM', () => {
  const script = `
    const authoring = await import('@lr/contracts/authoring/trucker');
    const modules = await import('@lr/contracts/modules');
    if (!authoring.TruckerSnapshotSchema || !modules.truckerContract || !modules.mainContract) {
      process.exitCode = 1;
    }
  `;
  const result = spawnSync(
    process.execPath,
    ['--input-type=module', '--eval', script],
    {cwd: webRoot, encoding: 'utf8'}
  );

  assert.equal(result.status, 0, result.stderr || result.stdout);
});
