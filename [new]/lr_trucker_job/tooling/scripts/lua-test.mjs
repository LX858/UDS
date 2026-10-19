import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

const repoRoot = path.resolve(import.meta.dirname, '../..');
const testFiles = [
  'tests/lua/helpers/ms-parse.test.mjs',
];
const luaSpecs = [
  'tests/lua/runtime/class_spec.lua',
  'tests/lua/runtime/framework_bridge_spec.lua',
  'tests/lua/runtime/module_registry_spec.lua',
  'tests/lua/runtime/module_parts_spec.lua',
  'tests/lua/runtime/lifecycle_spec.lua',
  'tests/lua/runtime/readiness_spec.lua',
  'tests/lua/runtime/start_failure_rollback_spec.lua',
  'tests/lua/runtime/services_spec.lua',
  'tests/lua/runtime/side_application_spec.lua',
  'tests/lua/runtime/boot_resource_stop_spec.lua',
  'tests/lua/runtime/trucker_oop_spec.lua',
  'tests/lua/runtime/trucker_rental_lease_spec.lua',
  'tests/lua/runtime/trucker_mission_session_spec.lua',
  'tests/lua/runtime/trucker_economy_spec.lua',
  'tests/lua/runtime/trucker_business_order_spec.lua',
  'tests/lua/runtime/business_crafting_spec.lua',
  'tests/lua/runtime/fuel_procurement_spec.lua',
  'tests/lua/schema/schema_spec.lua',
  'tests/lua/schema/generated_contract_spec.lua',
  'tests/lua/security/transport_spec.lua',
  'tests/lua/security/nui_resilience_spec.lua',
  'tests/lua/security/net_resilience_spec.lua',
  'tests/lua/security/public_spec.lua',
];

let failed = 0;

for (const testFile of testFiles) {
  const fileUrl = pathToFileURL(path.join(repoRoot, testFile));
  const module = await import(fileUrl.href);

  for (const testCase of module.tests ?? []) {
    try {
      await testCase.run({repoRoot});
      console.log(`PASS lua ${testCase.name}`);
    } catch (error) {
      failed += 1;
      console.error(`FAIL lua ${testCase.name}`);
      console.error(error?.message ?? error);
    }
  }
}

const fengariCli = path.join(
  repoRoot,
  'node_modules',
  'fengari-node-cli',
  'src',
  'lua-cli.js'
);

for (const luaSpec of luaSpecs) {
  const result = spawnSync(process.execPath, [fengariCli, luaSpec], {
    cwd: repoRoot,
    encoding: 'utf8',
    stdio: 'pipe',
  });
  const output = `${result.stdout ?? ''}\n${result.stderr ?? ''}`;
  const expectedMarker = luaSpec.endsWith('transport_spec.lua')
    ? 'PASS transport security specification'
    : luaSpec.endsWith('nui_resilience_spec.lua')
      ? 'PASS NUI resilience specification'
      : luaSpec.endsWith('net_resilience_spec.lua')
        ? 'PASS network resilience specification'
        : luaSpec.endsWith('public_spec.lua')
          ? 'PASS public export security specification'
          : null;
  const hasExpectedMarker = expectedMarker === null || output.includes(expectedMarker);
  const hasLuaFailure =
    /stack traceback:|in main chunk|cannot open|^\s*[^\r\n]+\.lua:\d+:/m.test(output);
  if (
    result.status === 0 &&
    !result.error &&
    !hasLuaFailure &&
    hasExpectedMarker
  ) {
    console.log(`PASS lua ${luaSpec}`);
    continue;
  }
  failed += 1;
  console.error(`FAIL lua ${luaSpec}`);
  console.error((result.stderr || result.stdout || result.error?.message || '').trim());
}

if (failed > 0) {
  console.error(`lua-test failed: ${failed} test(s) failed`);
  process.exit(1);
}

console.log('lua-test passed');
