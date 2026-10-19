import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const guidePath = path.join(repoRoot, 'docs', 'USAGE_GUIDE.md');
const guide = fs.readFileSync(guidePath, 'utf8');
const readme = fs.readFileSync(path.join(repoRoot, 'README.md'), 'utf8');
const agents = fs.readFileSync(path.join(repoRoot, 'AGENTS.md'), 'utf8');

test('README links the complete usage guide', () => {
  assert.match(readme, /\[Hướng dẫn sử dụng đầy đủ\]\(\.\/docs\/USAGE_GUIDE\.md\)/);
  assert.ok(
    readme.includes('packages/contracts/src/authoring/<module_id>/'),
    'README must identify the neutral contract authoring root'
  );
  assert.ok(
    readme.includes("@Store({id: 'inventory'})"),
    'README must use the state-only Store API'
  );
  assert.ok(
    readme.includes('@lr/contracts/authoring/inventory'),
    'README must use the public per-module authoring subpath'
  );
  assert.ok(
    readme.includes('authoring/<module_id>/index.ts'),
    'README must document the schemas-only per-module index'
  );
  assert.ok(
    readme.includes('moduleBoundaries'),
    'README must document the explicit boundary registry'
  );
  assert.doesNotMatch(
    readme,
    /from '@lr\/contracts\/authoring\/[^']+\.schemas';/,
    'README web stores must not import direct schema-file subpaths'
  );
});

test('usage guide covers every author-facing API group', () => {
  const requiredSections = [
    'Module descriptor và lifecycle',
    'ModuleContext',
    'Gọi module nội bộ',
    'Shared/client/server composition',
    'Logger',
    'DisposableStack',
    'Scheduler',
    'Readiness provider',
    'built-in framework bridge',
    'Locale và thời gian',
    'Domain OOP với `LR.Class`',
    'Contract TypeBox',
    'NUI từ Lua client',
    'NUI từ React/TypeScript',
    'Client/server network',
    'Public và External API',
    'Application và service API',
    'Validation, timeout và giới hạn',
    'Ví dụ end-to-end',
    'API reference bổ sung',
    'Checklist module mới',
  ];

  for (const section of requiredSections) {
    assert.ok(guide.includes(section), `usage guide must cover ${section}`);
  }

  const requiredApis = [
    'LR.Modules:Register',
    'startContext.modules.inventory',
    'context.disposables:Add',
    'packages/contracts/src/authoring/inventory/inventory.schemas.ts',
    'packages/contracts/src/authoring/inventory/inventory.boundaries.ts',
    'packages/contracts/src/authoring/inventory/index.ts',
    'inventoryNuiBoundary',
    'inventoryNetworkBoundary',
    'inventoryExportBoundary',
    'inventoryBoundaries',
    'moduleBoundaries',
    'inventory: inventoryBoundaries',
    '@lr/contracts/authoring/inventory',
    "@Store({id: 'inventory'})",
    '@State(schema, default)',
    'web/src/app/modules/registry.ts',
    'packages/contracts/src/modules/',
    'one-to-one parity',
    'package-export cho browser',
    'contracts chỉ chứa synchronized state và NUI',
    'appRuntime.stores.trucker',
    'trucker.state.visibility.set',
    'appRuntime.flush()',
    'core.synced',
    'Nui.events.toast:Emit',
    'trucker.rpc.refresh.call',
    'getState:Handle',
    'startContext.public.Trucker:Register',
    'startContext.external.Trucker',
    'LR.StandaloneReadinessProvider:new',
    'Config.Framework.Name',
    'context.services.framework',
    'GetPlayerData()',
    'GetPlayer(source)',
    'OnPlayerUnloaded()',
    'LR.Class:Define',
    'LRShared.Class<TInstance, TInit>',
    'instance:IsA(target)',
  ];

  for (const api of requiredApis) {
    assert.ok(guide.includes(api), `usage guide must include ${api}`);
  }
});

test('usage guide has balanced code fences and valid relative links', () => {
  const fenceCount = [...guide.matchAll(/^```/gm)].length;
  assert.equal(fenceCount % 2, 0, 'Markdown code fences must be balanced');

  for (const match of guide.matchAll(/\]\((\.\/[^)#]+)(?:#[^)]+)?\)/g)) {
    const target = path.resolve(path.dirname(guidePath), match[1]);
    assert.ok(fs.existsSync(target), `missing guide link target: ${match[1]}`);
  }

  assert.doesNotMatch(guide, /`lr:bridge`/, 'guide must use the safe lr_bridge endpoint');
  assert.doesNotMatch(
    guide,
    /state\.(?:client|nui)/,
    'guide must document ownerless synchronized state'
  );
  assert.doesNotMatch(guide, /\bsurfaces?\b/i, 'guide must use boundary terminology');
  assert.doesNotMatch(
    guide,
    /@Store\(\{id,\s*nui,\s*net,\s*exports\}\)/,
    'guide Store metadata must contain only id'
  );
  assert.doesNotMatch(
    guide,
    /@Store\(\{id:[^\n}]+,\s*\.\.\./,
    'guide Store metadata must not use object expansion'
  );
  assert.doesNotMatch(
    guide,
    /@Store\(\{[^)]*\bboundaries\s*:/s,
    'guide Store metadata must remain state-only'
  );
  assert.doesNotMatch(
    guide,
    /from '@lr\/contracts\/authoring';/,
    'guide web stores must not import the authoring root'
  );
  assert.doesNotMatch(
    guide,
    /from '@lr\/contracts\/authoring\/[^']+\.schemas';/,
    'guide web stores must not import direct schema-file subpaths'
  );
  assert.doesNotMatch(
    guide,
    /from '@lr\/contracts\/authoring\/[^']+\.boundaries';/,
    'guide web stores must not import boundary files'
  );
});

test('AGENTS.md captures codebase rules for coding agents', () => {
  const requiredRules = [
    'Never manually edit generated artifacts',
    'Create all',
    'startContext.modules.inventory',
    'packages/contracts/src/authoring/<module_id>/<module_id>.schemas.ts',
    'packages/contracts/src/authoring/<module_id>/<module_id>.boundaries.ts',
    'packages/contracts/src/authoring/<module_id>/index.ts',
    '<id>NuiBoundary',
    '<id>NetworkBoundary',
    '<id>ExportBoundary',
    '<id>Boundaries',
    'moduleBoundaries',
    '@lr/contracts/authoring/inventory',
    "@Store({id: 'inventory'})",
    '@State(TypeBoxSchema, default)',
    'web/src/app/modules/registry.ts',
    'packages/contracts/src/modules/',
    'one-to-one parity',
    'package-exported to browser code',
    'Browser generated contracts contain',
    'only synchronized state and NUI',
    'Synchronized state has no owner',
    'AppRuntime.flush()',
    'core.synced',
    'pnpm check:luals',
    'overextended.cfxlua-vscode',
    'Constructors accept at most one typed input value',
    'Do not revert unrelated changes',
  ];

  for (const rule of requiredRules) {
    assert.ok(agents.includes(rule), `AGENTS.md must include ${rule}`);
  }

  const fenceCount = [...agents.matchAll(/^```/gm)].length;
  assert.equal(fenceCount % 2, 0, 'AGENTS.md code fences must be balanced');
  assert.doesNotMatch(
    agents,
    /state\.(?:client|nui)/,
    'AGENTS.md must document ownerless synchronized state'
  );
  assert.doesNotMatch(agents, /\bsurfaces?\b/i, 'AGENTS.md must use boundary terminology');
  assert.doesNotMatch(
    agents,
    /@Store\(\{id,\s*nui,\s*net,\s*exports\}\)/,
    'AGENTS.md Store metadata must contain only id'
  );
  assert.doesNotMatch(
    agents,
    /@Store\(\{[^)]*\bboundaries\s*:/s,
    'AGENTS.md Store metadata must remain state-only'
  );
  assert.doesNotMatch(
    agents,
    /from '@lr\/contracts\/authoring';/,
    'AGENTS.md web stores must not import the authoring root'
  );
  assert.doesNotMatch(
    agents,
    /from '@lr\/contracts\/authoring\/[^']+\.schemas';/,
    'AGENTS.md web stores must not import direct schema-file subpaths'
  );
  assert.doesNotMatch(
    agents,
    /from '@lr\/contracts\/authoring\/[^']+\.boundaries';/,
    'AGENTS.md web stores must not import boundary files'
  );
});
