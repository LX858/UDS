import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');

function readJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(repoRoot, relativePath), 'utf8'));
}

function libraries(config) {
  return new Set(config['workspace.library'] ?? []);
}

function assertIncludesAll(actual, expected, label) {
  for (const value of expected) {
    assert.ok(actual.has(value), `${label} must include ${value}`);
  }
}

function assertExcludesAll(actual, excluded, label) {
  for (const value of excluded) {
    assert.ok(!actual.has(value), `${label} must not include ${value}`);
  }
}

test('root LuaLS configuration is portable and cannot bind a side LR namespace', () => {
  const config = readJson('.luarc.json');
  const configuredLibraries = config['workspace.library'] ?? [];

  assert.equal(config['runtime.plugin'], undefined);
  assert.equal(config['workspace.checkThirdParty'], false);
  assert.deepEqual(configuredLibraries, ['types/cfx/shared']);

  for (const library of configuredLibraries) {
    assert.doesNotMatch(library, /^[a-zA-Z]:[\\/]/, 'library paths must be repo-relative');
  }

  const ignored = new Set(config['workspace.ignoreDir'] ?? []);
  assertIncludesAll(ignored, ['client', 'server', 'shared', 'types', 'tests'], 'root ignores');
});

test('VS Code folder settings override user-level Lua libraries with the canonical side config', () => {
  const folders = [
    {config: '.luarc.json', settings: '.vscode/settings.json'},
    {config: 'client/.luarc.json', settings: 'client/.vscode/settings.json'},
    {config: 'server/.luarc.json', settings: 'server/.vscode/settings.json'},
    {config: 'shared/.luarc.json', settings: 'shared/.vscode/settings.json'},
  ];

  for (const folder of folders) {
    const config = readJson(folder.config);
    const settings = readJson(folder.settings);

    assert.equal(settings['Lua.runtime.version'], config['runtime.version'], folder.settings);
    assert.equal(
      settings['Lua.workspace.checkThirdParty'],
      config['workspace.checkThirdParty'],
      folder.settings,
    );
    assert.deepEqual(
      settings['Lua.workspace.library'],
      config['workspace.library'],
      folder.settings,
    );
    assert.deepEqual(
      settings['Lua.workspace.ignoreDir'],
      config['workspace.ignoreDir'],
      folder.settings,
    );
    assert.deepEqual(
      settings['Lua.diagnostics.globals'],
      config['diagnostics.globals'],
      folder.settings,
    );
  }
});

test('multi-root workspace exposes all isolated Lua sides', () => {
  const workspace = readJson('lr_trucker_job.code-workspace');
  const folderNames = new Set(workspace.folders.map((folder) => folder.name));

  assertIncludesAll(folderNames, ['lua-client', 'lua-server', 'lua-shared'], 'workspace folders');
});

test('each Lua side provides a typed module snippet', () => {
  const expectedTypes = {
    client: 'LRClient.ModuleInstance',
    server: 'LRServer.ModuleInstance',
    shared: 'LRShared.ModuleInstance',
  };

  for (const [side, instanceType] of Object.entries(expectedTypes)) {
    const snippets = readJson(`${side}/.vscode/lr-modules.code-snippets`);
    const entries = Object.values(snippets);
    assert.equal(entries.length, 1, `${side} must expose one module snippet`);
    assert.equal(entries[0].prefix, 'lr-module');
    assert.ok(
      entries[0].body.some(
        (line) => line.startsWith('    ---@class ') && line.endsWith(` : ${instanceType}`),
      ),
    );
    assert.ok(entries[0].body.some((line) => line.includes('instance:OnReady')));
    assert.ok(entries[0].body.some((line) => line.includes('instance:Start')));
    assert.ok(entries[0].body.some((line) => line.includes('instance:Stop')));
    assert.ok(entries[0].body.some((line) => line.includes('---@param context')));
  }
});

test('side workspaces load only their allowed declarations', () => {
  const client = libraries(readJson('client/.luarc.json'));
  const server = libraries(readJson('server/.luarc.json'));
  const shared = libraries(readJson('shared/.luarc.json'));

  assertIncludesAll(
    client,
    [
      '../shared',
      '../types/cfx/shared',
      '../types/cfx/client',
      '../types/shared/base.d.lua',
      '../types/shared/generated',
      '../types/client',
    ],
    'client libraries',
  );
  assertExcludesAll(
    client,
    ['../types/shared', '../types/shared/workspace.d.lua', '../types/cfx/server', '../types/server'],
    'client libraries',
  );

  assertIncludesAll(
    server,
    [
      '../shared',
      '../types/cfx/shared',
      '../types/cfx/server',
      '../types/shared/base.d.lua',
      '../types/shared/generated',
      '../types/server',
    ],
    'server libraries',
  );
  assertExcludesAll(
    server,
    ['../types/shared', '../types/shared/workspace.d.lua', '../types/cfx/client', '../types/client'],
    'server libraries',
  );

  assertIncludesAll(shared, ['../types/cfx/shared', '../types/shared'], 'shared libraries');
  assertExcludesAll(
    shared,
    ['../types/cfx/client', '../types/cfx/server', '../types/client', '../types/server'],
    'shared libraries',
  );
});

test('shared base declarations never bind the workspace-specific LR global', () => {
  const baseDeclarations = fs.readFileSync(
    path.join(repoRoot, 'types/shared/base.d.lua'),
    'utf8',
  );
  const sharedWorkspace = fs.readFileSync(
    path.join(repoRoot, 'types/shared/workspace.d.lua'),
    'utf8',
  );

  assert.doesNotMatch(baseDeclarations, /^LR\s*=/m);
  assert.match(sharedWorkspace, /^LR\s*=.*LRShared\.Namespace/m);
});

test('prototype methods use instance receivers instead of class-table receivers', () => {
  const baseDeclarations = fs.readFileSync(
    path.join(repoRoot, 'types/shared/base.d.lua'),
    'utf8',
  );
  const invalidReceivers = [
    ...baseDeclarations.matchAll(
      /^---@field\s+(?!new\??\s)([A-Za-z0-9_]+)\??\s+fun\(self:\s+(LRShared\.[A-Za-z0-9_]+Class)\b/gm,
    ),
  ].map((match) => `${match[1]}:${match[2]}`);

  assert.deepEqual(
    invalidReceivers,
    [],
    'only constructors may receive a class table; prototype methods must receive their instance type',
  );
});
