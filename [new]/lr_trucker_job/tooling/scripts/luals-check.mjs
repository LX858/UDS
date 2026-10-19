import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const repoRoot = path.resolve(import.meta.dirname, '../..');
const bundledExecutable = path.join(
  repoRoot,
  '.tools',
  'lua-language-server',
  'bin',
  process.platform === 'win32' ? 'lua-language-server.exe' : 'lua-language-server'
);

function resolveExecutable() {
  if (process.env.LUA_LANGUAGE_SERVER) return process.env.LUA_LANGUAGE_SERVER;
  if (fs.existsSync(bundledExecutable)) return bundledExecutable;
  const finder = spawnSync(
    process.platform === 'win32' ? 'where.exe' : 'which',
    ['lua-language-server'],
    {encoding: 'utf8'}
  );
  if (finder.status === 0) return finder.stdout.trim().split(/\r?\n/)[0];
  throw new Error(
    'LuaLS 3.19.1 is required. Set LUA_LANGUAGE_SERVER or install it in .tools/lua-language-server.'
  );
}

function collectDiagnostics(value, output = [], fileHint) {
  if (Array.isArray(value)) {
    value.forEach(item => collectDiagnostics(item, output, fileHint));
    return output;
  }
  if (value && typeof value === 'object') {
    const ownFile = value.file ?? value.uri ?? fileHint;
    if ('message' in value && ('severity' in value || 'code' in value) && 'range' in value) {
      output.push({...value, file: ownFile});
      return output;
    }
    Object.entries(value).forEach(([key, item]) =>
      collectDiagnostics(item, output, key.endsWith('.lua') ? key : ownFile)
    );
  }
  return output;
}

function normalizeFile(file) {
  if (typeof file !== 'string') return '<unknown-report-file>';
  let resolved = file;
  if (resolved.startsWith('file://')) resolved = fileURLToPath(resolved);
  if (path.isAbsolute(resolved)) resolved = path.relative(repoRoot, resolved);
  return resolved.replaceAll('\\', '/');
}

function normalizeReportDiagnostics(diagnostics) {
  return diagnostics.map(diagnostic => ({
    file: normalizeFile(diagnostic.file),
    line: Number(diagnostic.range?.start?.line ?? 0) + 1,
    column: Number(diagnostic.range?.start?.character ?? 0) + 1,
    severity: diagnostic.severity === 1 ? 'Error' : 'Warning',
    message: String(diagnostic.message ?? ''),
    code: String(diagnostic.code ?? 'unknown'),
  }));
}

function mergeDiagnostics(...groups) {
  const unique = new Map();
  for (const diagnostic of groups.flat()) {
    const key = [
      diagnostic.file,
      diagnostic.line,
      diagnostic.column,
      diagnostic.code,
    ].join('|');
    unique.set(key, diagnostic);
  }
  return [...unique.values()];
}

function parseCliDiagnostics(output) {
  const diagnostics = [];
  const pattern = /^(.+?\.lua):(\d+):(\d+) \[(Warning|Error)\] ([\s\S]*?) \(([^)\r\n]+)\)$/gm;
  const normalized = output
    .replace(/\x1B\[[0-?]*[ -/]*[@-~]/g, '')
    .replaceAll('\\', '/');
  for (const match of normalized.matchAll(pattern)) {
    diagnostics.push({
      file: match[1],
      line: Number(match[2]),
      column: Number(match[3]),
      severity: match[4],
      message: match[5],
      code: match[6],
    });
  }
  return diagnostics;
}

function runCheck(workspace, label, configPath) {
  const logDirectory = fs.mkdtempSync(path.join(os.tmpdir(), `lr-luals-${label}-`));
  try {
    const args = [
      `--check=${workspace}`,
      '--checklevel=Warning',
      `--logpath=${logDirectory}`,
    ];
    if (configPath) args.push(`--configpath=${configPath}`);
    const result = spawnSync(
      executable,
      args,
      {cwd: repoRoot, encoding: 'utf8', timeout: 120_000}
    );
    const reportPath = path.join(logDirectory, 'check.json');
    const report = fs.existsSync(reportPath)
      ? JSON.parse(fs.readFileSync(reportPath, 'utf8'))
      : null;
    const cliOutput = `${result.stdout ?? ''}\n${result.stderr ?? ''}`;
    return {
      ...result,
      cliOutput,
      diagnostics: mergeDiagnostics(
        parseCliDiagnostics(cliOutput),
        normalizeReportDiagnostics(collectDiagnostics(report))
      ),
    };
  } finally {
    fs.rmSync(logDirectory, {recursive: true, force: true});
  }
}

function runIsolatedSharedApplicationCheck() {
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), 'lr-luals-shared-open-file-'));
  try {
    const sourceDirectory = path.join(workspace, 'shared', 'core');
    fs.mkdirSync(sourceDirectory, {recursive: true});
    fs.copyFileSync(
      path.join(repoRoot, 'shared', 'core', 'application.lua'),
      path.join(sourceDirectory, 'application.lua')
    );

    const configPath = path.join(workspace, '.luarc.json');
    fs.writeFileSync(
      configPath,
      `${JSON.stringify(
        {
          'runtime.version': 'Lua 5.4',
          'workspace.checkThirdParty': false,
          'workspace.library': [
            path.join(repoRoot, 'types', 'cfx', 'shared'),
            path.join(repoRoot, 'types', 'shared'),
          ],
          'diagnostics.globals': ['Config', 'ResourceName', 'lib'],
        },
        null,
        2
      )}\n`
    );
    return runCheck(workspace, 'shared-open-file', configPath);
  } finally {
    fs.rmSync(workspace, {recursive: true, force: true});
  }
}

function reportFailure(label, result, detail) {
  failures += 1;
  console.error(`FAIL LuaLS ${label}: ${detail}`);
  if (result.error) console.error(result.error.message);
  if (result.stdout) console.error(result.stdout.trim());
  if (result.stderr) console.error(result.stderr.trim());
}

const executable = resolveExecutable();
const version = spawnSync(executable, ['--version'], {encoding: 'utf8'});
if (version.status !== 0 || !version.stdout.includes('3.19.1')) {
  throw new Error(`Expected LuaLS 3.19.1, got ${version.stdout || version.stderr}`);
}

let failures = 0;
for (const side of ['client', 'server', 'shared']) {
  const workspace = path.join(repoRoot, side);
  const result = runCheck(workspace, side);
  if (
    result.status !== 0 ||
    result.error ||
    result.diagnostics.length > 0
  ) {
    reportFailure(side, result, 'authored source produced diagnostics');
  } else {
    console.log(`PASS LuaLS ${side}`);
  }
}

const isolatedSharedApplication = runIsolatedSharedApplicationCheck();
if (
  isolatedSharedApplication.status !== 0 ||
  isolatedSharedApplication.error ||
  isolatedSharedApplication.diagnostics.length > 0
) {
  reportFailure(
    'shared open-file',
    isolatedSharedApplication,
    'shared/core/application.lua produced diagnostics outside its side workspace'
  );
} else {
  console.log('PASS LuaLS shared open-file');
}

const fixtureExpectations = {
  client: {
    file: 'tests/luals/client/negative_server_leak.lua',
    typeProbe: {
      file: 'tests/luals/client/negative_unknown_return.lua',
      code: 'undefined-field',
      messages: [
        'DefinitelyMissingMethod',
        'DefinitelyMissingNuiMethod',
        'DefinitelyMissingNetMethod',
        'DefinitelyMissingPublicMethod',
      ],
    },
    injectionProbe: {
      file: 'tests/luals/client/negative_unknown_return.lua',
      code: 'inject-field',
      message: 'DefinitelyMissingInjectedField',
    },
    globals: [
      'AddEventHandler',
      'GetPlayerRoutingBucket',
      'LRServer',
      'RegisterRawNuiCallback',
      'RegisterResourceAsEventHandler',
      'SendNuiMessage',
      'TriggerClientEvent',
      'TriggerEvent',
      'TriggerLatentServerEventInternal',
      'TriggerServerEventInternal',
      'UnregisterRawNuiCallback',
      'source',
    ],
  },
  server: {
    file: 'tests/luals/server/negative_client_leak.lua',
    typeProbe: {
      file: 'tests/luals/server/negative_unknown_return.lua',
      code: 'undefined-field',
      messages: [
        'DefinitelyMissingMethod',
        'DefinitelyMissingNetMethod',
        'DefinitelyMissingPublicMethod',
      ],
    },
    injectionProbe: {
      file: 'tests/luals/server/negative_unknown_return.lua',
      code: 'inject-field',
      message: 'DefinitelyMissingInjectedField',
    },
    globals: [
      'AddEventHandler',
      'AbortTextChat',
      'LRClient',
      'RegisterResourceAsEventHandler',
      'SendNUIMessage',
      'TriggerClientEventInternal',
      'TriggerLatentClientEventInternal',
      'TriggerEvent',
    ],
  },
  shared: {
    file: 'tests/luals/shared/negative_side_leak.lua',
    diagnosticProbes: [
      {
        file: 'tests/luals/shared/negative_class_types.lua',
        line: 31,
        code: 'assign-type-mismatch',
        count: 2,
      },
      {
        file: 'tests/luals/shared/negative_class_types.lua',
        line: 32,
        code: 'assign-type-mismatch',
        count: 1,
      },
      {
        file: 'tests/luals/shared/negative_class_types.lua',
        line: 33,
        code: 'param-type-mismatch',
        count: 1,
      },
    ],
    typeProbe: {
      file: 'tests/luals/shared/negative_unknown_return.lua',
      code: 'undefined-field',
      messages: [
        'DefinitelyMissingMethod',
        'DefinitelyMissingRegistryMethod',
      ],
    },
    injectionProbe: {
      file: 'tests/luals/shared/negative_unknown_return.lua',
      code: 'inject-field',
      message: 'DefinitelyMissingInjectedField',
    },
    globals: [
      'AddEventHandler',
      'AbortTextChat',
      'GetPlayerRoutingBucket',
      'LRClient',
      'LRServer',
      'RegisterResourceAsEventHandler',
      'SendNUIMessage',
      'TriggerClientEvent',
      'TriggerEventInternal',
      'TriggerEvent',
      'source',
    ],
  },
};

for (const [side, expectation] of Object.entries(fixtureExpectations)) {
  const workspace = path.join(repoRoot, 'tests', 'luals', side);
  const result = runCheck(workspace, `${side}-fixtures`);
  const positiveDiagnostics = result.diagnostics.filter(diagnostic =>
    diagnostic.file.endsWith('/positive.lua')
  );
  const matchesTypeProbe = diagnostic =>
    expectation.typeProbe !== undefined &&
    diagnostic.file === expectation.typeProbe.file &&
    diagnostic.code === expectation.typeProbe.code &&
    expectation.typeProbe.messages.some(message =>
      diagnostic.message.includes(message)
    );
  const matchesInjectionProbe = diagnostic =>
    expectation.injectionProbe !== undefined &&
    diagnostic.file === expectation.injectionProbe.file &&
    diagnostic.code === expectation.injectionProbe.code &&
    diagnostic.message.includes(expectation.injectionProbe.message);
  const matchesDiagnosticProbe = diagnostic =>
    (expectation.diagnosticProbes ?? []).some(
      probe =>
        diagnostic.file === probe.file &&
        diagnostic.line === probe.line &&
        diagnostic.code === probe.code
    );
  const unexpectedDiagnostics = result.diagnostics.filter(
    diagnostic =>
      !(
        (diagnostic.file === expectation.file &&
          diagnostic.code === 'undefined-global') ||
        matchesTypeProbe(diagnostic) ||
        matchesInjectionProbe(diagnostic) ||
        matchesDiagnosticProbe(diagnostic)
      )
  );
  const typeProbeDiagnostics = result.diagnostics.filter(matchesTypeProbe);
  const injectionProbeDiagnostics = result.diagnostics.filter(matchesInjectionProbe);
  const exactTypeProbes =
    expectation.typeProbe === undefined ||
    (typeProbeDiagnostics.length === expectation.typeProbe.messages.length &&
      expectation.typeProbe.messages.every(
        message =>
          typeProbeDiagnostics.filter(diagnostic =>
            diagnostic.message.includes(message)
          ).length === 1
      ));
  const exactInjectionProbe = injectionProbeDiagnostics.length === 1;
  const diagnosticProbeResults = (expectation.diagnosticProbes ?? []).map(
    probe => ({
      ...probe,
      actual: result.diagnostics.filter(
        diagnostic =>
          diagnostic.file === probe.file &&
          diagnostic.line === probe.line &&
          diagnostic.code === probe.code
      ).length,
    })
  );
  const exactDiagnosticProbes = diagnosticProbeResults.every(
    probe => probe.actual >= probe.count
  );
  const actualGlobals = result.diagnostics
    .filter(diagnostic => diagnostic.file === expectation.file)
    .map(diagnostic => diagnostic.message.match(/`([^`]+)`/)?.[1] ?? diagnostic.message)
    .sort();
  const expectedGlobals = [...expectation.globals].sort();
  const exactGlobals = JSON.stringify(actualGlobals) === JSON.stringify(expectedGlobals);
  const failedChecks = [
    result.error && `spawn error: ${result.error.message}`,
    result.status !== 1 && `exit status ${result.status}`,
    positiveDiagnostics.length > 0 && `${positiveDiagnostics.length} positive diagnostics`,
    unexpectedDiagnostics.length > 0 && `${unexpectedDiagnostics.length} unexpected diagnostics`,
    !exactGlobals && `globals ${JSON.stringify(actualGlobals)}`,
    !exactTypeProbes && `type probes ${typeProbeDiagnostics.length}`,
    !exactInjectionProbe && `injection probes ${injectionProbeDiagnostics.length}`,
    !exactDiagnosticProbes &&
      `class type probes ${JSON.stringify(diagnosticProbeResults)}`,
  ].filter(Boolean);

  if (failedChecks.length > 0) {
    reportFailure(
      `${side} fixtures`,
      result,
      `expected ${expectation.file}: ${expectedGlobals.join(', ')}; failed ${failedChecks.join('; ')}`
    );
  } else {
    console.log(`PASS LuaLS ${side} fixtures`);
  }
}

if (failures > 0) process.exit(1);
