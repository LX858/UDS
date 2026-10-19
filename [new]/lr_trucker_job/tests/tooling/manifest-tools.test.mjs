import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const verifyScript = path.join(repoRoot, 'tooling', 'scripts', 'verify-manifest.mjs');
const packageScript = path.join(repoRoot, 'tooling', 'scripts', 'package-resource.mjs');

test('CI builds the NUI before validating manifest build artifacts', () => {
  const workflow = fs.readFileSync(
    path.join(repoRoot, '.github', 'workflows', 'autorelease.yml'),
    'utf8',
  );
  const smokeStep = workflow.match(
    /- name: Cross-platform smoke[\s\S]*?(?=\n\s+- name: Stage resource)/,
  )?.[0];

  assert.ok(smokeStep, 'Windows smoke step must exist');
  assert.ok(
    smokeStep.indexOf('pnpm build') < smokeStep.indexOf('pnpm verify:manifest'),
    'Windows smoke must build web/build before verifying manifest paths',
  );
});

test('CI verifies pinned LuaLS checksums before extracting binaries', () => {
  const workflow = fs.readFileSync(
    path.join(repoRoot, '.github', 'workflows', 'autorelease.yml'),
    'utf8',
  );
  const ubuntuInstall = workflow.match(
    /- name: Install pinned LuaLS[\s\S]*?(?=\n\s+- name: Install Chromium)/,
  )?.[0];
  const windowsInstall = workflow.match(
    /- name: Install pinned LuaLS[\s\S]*?(?=\n\s+- name: Cross-platform smoke)/,
  )?.[0];

  assert.ok(ubuntuInstall, 'Ubuntu LuaLS install step must exist');
  assert.ok(windowsInstall, 'Windows LuaLS install step must exist');
  assert.match(workflow, /LUALS_LINUX_X64_SHA256:/);
  assert.match(workflow, /LUALS_WIN32_X64_SHA256:/);
  assert.ok(
    ubuntuInstall.indexOf('sha256sum') < ubuntuInstall.indexOf('tar -xz'),
    'Ubuntu must verify LuaLS before extraction',
  );
  assert.ok(
    windowsInstall.indexOf('Get-FileHash') < windowsInstall.indexOf('Expand-Archive'),
    'Windows must verify LuaLS before extraction',
  );
});

test('main publishes new npm versions through trusted publishing after verification', () => {
  const workflow = fs.readFileSync(
    path.join(repoRoot, '.github', 'workflows', 'autorelease.yml'),
    'utf8',
  );
  const publishJob = workflow.match(
    /\n  publish-npm:[\s\S]*?(?=\n  github-release:)/,
  )?.[0];

  assert.ok(publishJob, 'npm publish job must exist');
  assert.match(publishJob, /needs: \[verify-ubuntu, smoke-windows\]/);
  assert.match(publishJob, /id-token: write/);
  assert.match(publishJob, /github\.ref == 'refs\/heads\/main'/);
  assert.match(publishJob, /response\.status === 404/);
  assert.match(publishJob, /npm publish \.\/packages\/create-lr-resource --access public/);
  assert.doesNotMatch(publishJob, /NPM_TOKEN|NODE_AUTH_TOKEN/);
});

test('resource manifest loads side framework bridges after core and before modules', () => {
  const manifest = fs.readFileSync(path.join(repoRoot, 'fxmanifest.lua'), 'utf8');
  for (const side of ['client', 'server']) {
    const core = manifest.indexOf(`'${side}/core/application.lua'`);
    const bridge = manifest.indexOf(`'${side}/bridges/framework.lua'`);
    const variants = manifest.indexOf(`'${side}/bridges/frameworks/*.lua'`);
    const modules = manifest.indexOf(`'${side}/modules/*.lua'`);
    const boot = manifest.indexOf(`'${side}/boot.lua'`);
    assert.ok(core >= 0 && core < bridge, `${side} bridge must load after application core`);
    assert.ok(bridge < variants, `${side} framework registry must load before adapters`);
    assert.ok(variants < modules, `${side} adapters must load before feature modules`);
    assert.ok(modules < boot, `${side} modules must load before boot`);
  }
});

function makeFixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'lr-manifest-tools-'));

  fs.mkdirSync(path.join(root, 'client', 'impl'), {recursive: true});
  fs.mkdirSync(path.join(root, 'server', 'impl'), {recursive: true});
  fs.mkdirSync(path.join(root, 'shared', 'core'), {recursive: true});
  fs.mkdirSync(path.join(root, 'web', 'build', 'assets'), {recursive: true});
  fs.mkdirSync(path.join(root, 'web', 'src'), {recursive: true});
  fs.mkdirSync(path.join(root, 'types', 'client'), {recursive: true});

  fs.writeFileSync(path.join(root, 'fxmanifest.lua'), `
fx_version 'cerulean'
lua54 'yes'

files {
  'web/build/index.html',
  'web/build/**/*',
}

shared_scripts {
  'shared/**/*.lua',
}

client_scripts {
  'client/impl/*',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/impl/*',
}
`);
  fs.writeFileSync(path.join(root, 'web', 'build', 'index.html'), '<div></div>');
  fs.writeFileSync(path.join(root, 'web', 'build', 'assets', 'app.js'), 'console.log(1);');
  fs.writeFileSync(path.join(root, 'web', 'src', 'dev-only.ts'), 'export {};');
  fs.writeFileSync(path.join(root, 'shared', 'core', 'main.lua'), 'Shared = true');
  fs.writeFileSync(path.join(root, 'client', 'impl', 'test.impl.lua'), 'Client = true');
  fs.writeFileSync(path.join(root, 'server', 'impl', 'test.impl.lua'), 'Server = true');
  fs.writeFileSync(path.join(root, 'types', 'client', 'api.d.lua'), '---@meta');

  return root;
}

test('verify-manifest validates local manifest references and ignores external at-files', () => {
  const fixture = makeFixture();

  const output = execFileSync(process.execPath, [verifyScript, '--root', fixture, '--json'], {
    encoding: 'utf8',
  });
  const result = JSON.parse(output);

  assert.equal(result.ok, true);
  assert.equal(result.missing.length, 0);
  assert.match(result.included.join('\n'), /web\/build\/assets\/app\.js/);
  assert.doesNotMatch(result.included.join('\n'), /oxmysql/);
});

test('verify-manifest rejects references that escape the resource root', () => {
  const fixture = makeFixture();
  const outsideFile = path.join(path.dirname(fixture), 'outside-secret.txt');
  fs.writeFileSync(outsideFile, 'secret');
  fs.appendFileSync(
    path.join(fixture, 'fxmanifest.lua'),
    `\nfiles { '../outside-secret.txt' }\n`,
  );

  assert.throws(
    () => execFileSync(process.execPath, [verifyScript, '--root', fixture, '--json']),
    /escapes resource root/i,
  );
});

test('verify-manifest treats unmatched globs as release-blocking errors', () => {
  const fixture = makeFixture();
  fs.appendFileSync(
    path.join(fixture, 'fxmanifest.lua'),
    `\nfiles { 'web/build/missing-assets\/*\/*' }\n`,
  );

  assert.throws(
    () => execFileSync(process.execPath, [verifyScript, '--root', fixture, '--json']),
    /Command failed/,
  );
});

test('package-resource stages only release files and keeps nested manifest paths', () => {
  const fixture = makeFixture();
  const outputDir = path.join(fixture, 'out');

  execFileSync(process.execPath, [
    packageScript,
    '--root',
    fixture,
    '--out',
    outputDir,
    '--name',
    'fixture_resource',
    '--no-zip',
  ]);

  const stageRoot = path.join(outputDir, 'fixture_resource');
  assert.equal(fs.existsSync(path.join(stageRoot, 'fxmanifest.lua')), true);
  assert.equal(fs.existsSync(path.join(stageRoot, 'web', 'build', 'assets', 'app.js')), true);
  assert.equal(fs.existsSync(path.join(stageRoot, 'shared', 'core', 'main.lua')), true);
  assert.equal(fs.existsSync(path.join(stageRoot, 'client', 'impl', 'test.impl.lua')), true);
  assert.equal(fs.existsSync(path.join(stageRoot, 'server', 'impl', 'test.impl.lua')), true);
  assert.equal(fs.existsSync(path.join(stageRoot, 'types', 'client', 'api.d.lua')), true);
  assert.equal(fs.existsSync(path.join(stageRoot, 'web', 'src', 'dev-only.ts')), false);
});

test('package-resource rejects output paths that traverse a symlink or junction', () => {
  const fixture = makeFixture();
  const external = fs.mkdtempSync(path.join(os.tmpdir(), 'lr-package-outside-'));
  const outputLink = path.join(fixture, 'linked-output');
  fs.symlinkSync(
    external,
    outputLink,
    process.platform === 'win32' ? 'junction' : 'dir',
  );

  assert.throws(
    () =>
      execFileSync(process.execPath, [
        packageScript,
        '--root',
        fixture,
        '--out',
        outputLink,
        '--name',
        'fixture_resource',
        '--no-zip',
      ]),
    /symbolic link or junction/i,
  );
  assert.equal(fs.existsSync(path.join(external, 'fixture_resource')), false);
});
