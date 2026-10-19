import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import test from 'node:test';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const packageRoot = path.join(repoRoot, 'packages', 'create-lr-resource');

function resolveNpmInvocation() {
  if (process.platform !== 'win32') return {command: 'npm', prefix: []};

  const adjacentCli = path.join(
    path.dirname(process.execPath),
    'node_modules',
    'npm',
    'bin',
    'npm-cli.js',
  );
  if (fs.existsSync(adjacentCli)) return {command: process.execPath, prefix: [adjacentCli]};

  const lookup = spawnSync('where.exe', ['npm.cmd'], {encoding: 'utf8'});
  const commandShim = lookup.stdout?.trim().split(/\r?\n/)[0];
  const discoveredCli = commandShim
    ? path.join(path.dirname(commandShim), 'node_modules', 'npm', 'bin', 'npm-cli.js')
    : '';
  assert.ok(discoveredCli && fs.existsSync(discoveredCli), 'Unable to locate npm CLI.');
  return {command: process.execPath, prefix: [discoveredCli]};
}

const npmInvocation = resolveNpmInvocation();

function runNpm(arguments_, options) {
  return spawnSync(npmInvocation.command, [...npmInvocation.prefix, ...arguments_], {
    encoding: 'utf8',
    timeout: 120_000,
    ...options,
  });
}

test('packed create-lr-resource CLI scaffolds a self-hosting FiveM resource', () => {
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), 'lr-create-package-'));
  try {
    const packDirectory = path.join(sandbox, 'pack');
    const output = path.join(sandbox, 'smoke_resource');
    fs.mkdirSync(packDirectory, {recursive: true});

    const pack = runNpm(['pack', '--json', '--pack-destination', packDirectory], {
      cwd: packageRoot,
    });
    assert.equal(pack.status, 0, `${pack.error ?? ''}\n${pack.stdout}\n${pack.stderr}`);

    const tarballs = fs.readdirSync(packDirectory).filter(file => file.endsWith('.tgz'));
    assert.equal(tarballs.length, 1, `Expected one tarball, found: ${tarballs.join(', ')}`);
    const tarball = path.join(packDirectory, tarballs[0]);

    const execute = runNpm(
      [
        'exec',
        '--yes',
        `--package=${tarball}`,
        '--',
        'create-lr-resource',
        '--name',
        'smoke_resource',
        '--output',
        output,
      ],
      {
        cwd: sandbox,
        env: {...process.env, npm_config_cache: path.join(sandbox, 'npm-cache')},
      },
    );
    assert.equal(execute.status, 0, `${execute.stdout}\n${execute.stderr}`);

    const generatedPackage = JSON.parse(
      fs.readFileSync(path.join(output, 'package.json'), 'utf8'),
    );
    assert.equal(generatedPackage.name, 'smoke_resource');
    assert.match(generatedPackage.scripts.package, /--name smoke_resource/);
    assert.equal(fs.existsSync(path.join(output, 'smoke_resource.code-workspace')), true);
    assert.equal(
      fs.existsSync(path.join(output, 'packages/create-lr-resource/package.json')),
      true,
    );
    assert.equal(fs.existsSync(path.join(output, 'packages/create-lr-resource/template')), false);
    assert.equal(fs.existsSync(path.join(output, 'web/build')), false);
    assert.equal(fs.existsSync(path.join(output, '.git')), false);
    assert.equal(fs.existsSync(path.join(output, 'client/bridges/framework.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'client/bridges/frameworks/esx.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'client/bridges/frameworks/qbcore.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'client/bridges/frameworks/qbx.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'server/bridges/framework.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'server/bridges/frameworks/esx.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'server/bridges/frameworks/qbcore.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'server/bridges/frameworks/qbx.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'types/client/framework.d.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'types/server/framework.d.lua')), true);
    assert.equal(fs.existsSync(path.join(output, 'docs/FRAMEWORK_BRIDGES.md')), true);
    assert.match(fs.readFileSync(path.join(output, 'config.lua'), 'utf8'), /Framework\s*=/);
    const manifest = fs.readFileSync(path.join(output, 'fxmanifest.lua'), 'utf8');
    assert.doesNotMatch(manifest, /dependency\s+['"](?:es_extended|qb-core|qbx_core)['"]/);
  } finally {
    fs.rmSync(sandbox, {recursive: true, force: true});
  }
}, 120_000);
