import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const LUA_EXTENSIONS = new Set(['.lua']);
const DYNAMIC_CODE_PATTERN = /\b(?:load|loadstring)\s*\(/;
const IMPL_CALL_PATTERN = /\bImplCall\b|exports\s*\(\s*["']ImplCall["']/;
const RAW_EXPORT_PATTERN = /(?<![.\w])exports\s*(?:\(|\[|\.)|=\s*exports\b/m;
const RAW_EXPORT_BOUNDARIES = new Set([
  'client/core/public.lua',
  'server/core/public.lua',
  'client/bridges/framework.lua',
  'server/bridges/framework.lua',
]);
const RAW_BOUNDARIES = new Map([
  [
    'AddEventHandler',
    new Set([
      'client/boot.lua',
      'server/boot.lua',
      'client/core/nui.lua',
      'client/core/net.lua',
      'server/core/net.lua',
      'client/core/public.lua',
      'server/core/public.lua',
      'client/bridges/framework.lua',
      'server/bridges/framework.lua',
    ]),
  ],
  ['TriggerEvent', new Set()],
  ['RegisterResourceAsEventHandler', new Set()],
  ['SendNuiMessage', new Set()],
  ['RegisterRawNuiCallback', new Set()],
  ['UnregisterRawNuiCallback', new Set()],
  ['SendNUIMessage', new Set(['client/core/nui.lua'])],
  ['RegisterNuiCallback', new Set(['client/core/nui.lua'])],
  ['RegisterNUICallback', new Set(['client/core/nui.lua'])],
  ['RegisterNuiCallbackType', new Set(['client/core/nui.lua'])],
  ['TriggerServerEvent', new Set(['client/core/net.lua'])],
  ['TriggerClientEvent', new Set(['server/core/net.lua'])],
  ['TriggerServerEventInternal', new Set()],
  ['TriggerLatentServerEventInternal', new Set()],
  ['TriggerClientEventInternal', new Set()],
  ['TriggerLatentClientEventInternal', new Set()],
  ['TriggerEventInternal', new Set()],
  [
    'RegisterNetEvent',
    new Set([
      'client/core/net.lua',
      'server/core/net.lua',
      'client/bridges/framework.lua',
      'server/bridges/framework.lua',
    ]),
  ],
  ['RegisterServerEvent', new Set()],
]);

function toRepoPath(filePath, repoRoot) {
  return path.relative(repoRoot, filePath).replaceAll(path.sep, '/');
}

function listFiles(root, repoRoot, predicate, result = []) {
  if (!fs.existsSync(root)) return result;

  for (const entry of fs.readdirSync(root, {withFileTypes: true})) {
    if (entry.name === '.git' || entry.name === 'node_modules' || entry.name === 'build') {
      continue;
    }

    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      listFiles(fullPath, repoRoot, predicate, result);
      continue;
    }

    if (predicate(fullPath, toRepoPath(fullPath, repoRoot))) {
      result.push(fullPath);
    }
  }

  return result;
}

function readRepoFile(repoRoot, repoPath) {
  return fs.readFileSync(path.join(repoRoot, repoPath), 'utf8');
}

function isRuntimeLua(filePath, repoPath) {
  return (
    LUA_EXTENSIONS.has(path.extname(filePath)) &&
    (/^(?:client|server|shared|utils|locales)\//.test(repoPath) || !repoPath.includes('/'))
  );
}

export const tests = [
  {
    name: 'dynamic Lua code APIs are absent',
    run({repoRoot}) {
      const violations = listFiles(
        repoRoot,
        repoRoot,
        isRuntimeLua
      )
        .map(filePath => {
          const repoPath = toRepoPath(filePath, repoRoot);
          const source = fs.readFileSync(filePath, 'utf8');
          return {repoPath, source};
        })
        .filter(({repoPath, source}) => {
          return DYNAMIC_CODE_PATTERN.test(source);
        })
        .map(({repoPath}) => repoPath);

      assert.deepEqual(
        violations,
        [],
        `load/loadstring must not appear in the resource: ${violations.join(', ')}`
      );
    },
  },
  {
    name: 'raw ImplCall export is absent',
    run({repoRoot}) {
      const violations = listFiles(
        repoRoot,
        repoRoot,
        isRuntimeLua
      )
        .map(filePath => {
          const repoPath = toRepoPath(filePath, repoRoot);
          const source = fs.readFileSync(filePath, 'utf8');
          return {repoPath, source};
        })
        .filter(({repoPath, source}) => {
          return IMPL_CALL_PATTERN.test(source);
        })
        .map(({repoPath}) => repoPath);

      assert.deepEqual(
        violations,
        [],
        `ImplCall must not be exposed: ${violations.join(', ')}`
      );
    },
  },
  {
    name: 'raw FiveM transports stay inside their fixed boundary files',
    run({repoRoot}) {
      const violations = [];
      for (const filePath of listFiles(
        repoRoot,
        repoRoot,
        (candidate, repoPath) =>
          LUA_EXTENSIONS.has(path.extname(candidate)) &&
          /^(?:client|server|shared)\//.test(repoPath)
      )) {
        const repoPath = toRepoPath(filePath, repoRoot);
        const source = fs.readFileSync(filePath, 'utf8');
        for (const [api, allowedFiles] of RAW_BOUNDARIES) {
          if (new RegExp(`\\b${api}\\b`).test(source) && !allowedFiles.has(repoPath)) {
            violations.push(`${repoPath}:${api}`);
          }
        }
      }
      assert.deepEqual(
        violations,
        [],
        `raw transport API escaped core boundary: ${violations.join(', ')}`
      );
    },
  },
  {
    name: 'raw export consumers stay inside fixed boundary files',
    run({repoRoot}) {
      const violations = listFiles(
        repoRoot,
        repoRoot,
        (candidate, repoPath) =>
          LUA_EXTENSIONS.has(path.extname(candidate)) &&
          /^(?:client|server|shared)\//.test(repoPath)
      )
        .map(filePath => ({
          repoPath: toRepoPath(filePath, repoRoot),
          source: fs.readFileSync(filePath, 'utf8'),
        }))
        .filter(({repoPath, source}) =>
          RAW_EXPORT_PATTERN.test(source) && !RAW_EXPORT_BOUNDARIES.has(repoPath)
        )
        .map(({repoPath}) => repoPath);

      assert.deepEqual(
        violations,
        [],
        `raw exports escaped fixed boundaries: ${violations.join(', ')}`
      );
    },
  },
  {
    name: 'manifest is framework-neutral and gta5-only',
    run({repoRoot}) {
      const manifest = readRepoFile(repoRoot, 'fxmanifest.lua');
      const forbidden = ['oxmysql', 'ox_lib', 'es_extended', 'qb-core', 'qbx_core', 'rdr3'];
      const matches = forbidden.filter(token =>
        new RegExp(`['"]${token}['"]|\\b${token}\\b`).test(manifest)
      );

      assert.deepEqual(
        matches,
        [],
        `fxmanifest.lua must not hard-require ox/framework/rdr3 entries: ${matches.join(', ')}`
      );
    },
  },
  {
    name: 'root package exposes verification command hooks',
    run({repoRoot}) {
      const packageJson = JSON.parse(readRepoFile(repoRoot, 'package.json'));
      const scripts = packageJson.scripts ?? {};
      const requiredScripts = [
        'generate',
        'check:contracts',
        'typecheck',
        'lint',
        'test',
        'test:coverage',
        'test:security',
        'test:lua',
        'check:luals',
        'build',
        'verify',
        'package',
      ];
      const missing = requiredScripts.filter(script => !scripts[script]);

      assert.deepEqual(
        missing,
        [],
        `package.json missing required verification hooks: ${missing.join(', ')}`
      );
    },
  },
  {
    name: 'GitHub Actions are pinned to immutable commit SHAs',
    run({repoRoot}) {
      const workflowRoot = path.join(repoRoot, '.github', 'workflows');
      const violations = listFiles(
        workflowRoot,
        repoRoot,
        candidate => /\.ya?ml$/.test(candidate)
      ).flatMap(filePath => {
        const repoPath = toRepoPath(filePath, repoRoot);
        return [...fs.readFileSync(filePath, 'utf8').matchAll(/\buses:\s*([^\s#]+)/g)]
          .map(match => match[1])
          .filter(reference => !/@[a-f0-9]{40}$/.test(reference))
          .map(reference => `${repoPath}:${reference}`);
      });

      assert.deepEqual(
        violations,
        [],
        `workflow actions must use immutable 40-character SHAs: ${violations.join(', ')}`
      );
    },
  },
  {
    name: 'typed NUI bridge does not expose any',
    run({repoRoot}) {
      const bridgeFiles = listFiles(
        path.join(repoRoot, 'web', 'src', 'nui'),
        repoRoot,
        candidate => ['.ts', '.tsx'].includes(path.extname(candidate))
      ).map(filePath => toRepoPath(filePath, repoRoot));
      const violations = bridgeFiles.filter(repoPath =>
        /\bany\b/.test(readRepoFile(repoRoot, repoPath))
      );
      assert.deepEqual(violations, [], `NUI bridge exposes any: ${violations.join(', ')}`);
    },
  },
];
