import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {afterEach, describe, expect, it} from 'vitest';
import {buildTemplateSnapshot, removeTemplateSnapshot} from './template.mjs';

const temporaryDirectories = [];

function createTemporaryDirectory() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'lr-template-snapshot-'));
  temporaryDirectories.push(directory);
  return directory;
}

function writeFixture(root, relativePath, content = `${relativePath}\n`) {
  const target = path.join(root, relativePath);
  fs.mkdirSync(path.dirname(target), {recursive: true});
  fs.writeFileSync(target, content, 'utf8');
}

afterEach(() => {
  for (const directory of temporaryDirectories.splice(0)) {
    fs.rmSync(directory, {recursive: true, force: true});
  }
});

describe('buildTemplateSnapshot', () => {
  it('copies the authored resource source and excludes local or recursive package artifacts', () => {
    const sandbox = createTemporaryDirectory();
    const sourceRoot = path.join(sandbox, 'source');
    const targetRoot = path.join(sandbox, 'template');

    writeFixture(sourceRoot, 'fxmanifest.lua');
    writeFixture(sourceRoot, 'package.json');
    writeFixture(sourceRoot, '.gitignore');
    writeFixture(sourceRoot, '.github/workflows/ci.yml');
    writeFixture(sourceRoot, 'client/boot.lua');
    writeFixture(sourceRoot, 'client/bridges/framework.lua');
    writeFixture(sourceRoot, 'packages/contracts/package.json');
    writeFixture(sourceRoot, 'packages/create-lr-resource/package.json');
    writeFixture(sourceRoot, 'packages/create-lr-resource/template/recursive.txt');
    writeFixture(sourceRoot, 'web/src/main.tsx');
    writeFixture(sourceRoot, 'web/build/index.html');
    writeFixture(sourceRoot, 'web/.env.local', 'SECRET=nested\n');
    writeFixture(sourceRoot, 'web/.npmrc', '//registry.npmjs.org/:_authToken=secret\n');
    writeFixture(sourceRoot, 'node_modules/private.txt');
    writeFixture(sourceRoot, '.env', 'SECRET=value\n');

    const result = buildTemplateSnapshot({sourceRoot, targetRoot});

    expect(result.files).toContain('fxmanifest.lua');
    expect(result.files).toContain('client/boot.lua');
    expect(result.files).toContain('client/bridges/framework.lua');
    expect(result.files).toContain('packages/contracts/package.json');
    expect(result.files).toContain('web/src/main.tsx');
    expect(fs.existsSync(path.join(targetRoot, '.github/workflows/ci.yml'))).toBe(true);
    expect(fs.existsSync(path.join(targetRoot, 'packages/create-lr-resource/package.json'))).toBe(true);
    expect(fs.existsSync(path.join(targetRoot, 'packages/create-lr-resource/template'))).toBe(false);
    expect(fs.existsSync(path.join(targetRoot, 'web/build'))).toBe(false);
    expect(fs.existsSync(path.join(targetRoot, 'web/.env.local'))).toBe(false);
    expect(fs.existsSync(path.join(targetRoot, 'web/.npmrc'))).toBe(false);
    expect(fs.existsSync(path.join(targetRoot, 'node_modules'))).toBe(false);
    expect(fs.existsSync(path.join(targetRoot, '.env'))).toBe(false);
  });

  it('refuses linked source entries', () => {
    const sandbox = createTemporaryDirectory();
    const sourceRoot = path.join(sandbox, 'source');
    const targetRoot = path.join(sandbox, 'template');
    writeFixture(sourceRoot, 'fxmanifest.lua');
    const outside = path.join(sandbox, 'outside.lua');
    writeFixture(sandbox, 'outside.lua', 'private\n');

    try {
      fs.symlinkSync(outside, path.join(sourceRoot, 'client'), 'junction');
    } catch (error) {
      if (error && typeof error === 'object' && 'code' in error && error.code === 'EPERM') return;
      throw error;
    }

    expect(() => buildTemplateSnapshot({sourceRoot, targetRoot})).toThrow(/symbolic link/i);
    expect(fs.existsSync(targetRoot)).toBe(false);
  });

  it('refuses a non-empty snapshot destination', () => {
    const sandbox = createTemporaryDirectory();
    const sourceRoot = path.join(sandbox, 'source');
    const targetRoot = path.join(sandbox, 'template');
    writeFixture(sourceRoot, 'fxmanifest.lua');
    writeFixture(targetRoot, 'keep.txt', 'keep\n');

    expect(() => buildTemplateSnapshot({sourceRoot, targetRoot})).toThrow(/not empty/i);
    expect(fs.readFileSync(path.join(targetRoot, 'keep.txt'), 'utf8')).toBe('keep\n');
  });
});

describe('removeTemplateSnapshot', () => {
  it('only removes the literal template directory under its package root', () => {
    const sandbox = createTemporaryDirectory();
    const packageRoot = path.join(sandbox, 'package');
    const templateRoot = path.join(packageRoot, 'template');
    const outside = path.join(packageRoot, 'outside');
    writeFixture(templateRoot, 'generated.txt');
    writeFixture(outside, 'keep.txt', 'keep\n');

    removeTemplateSnapshot({packageRoot, targetRoot: templateRoot});

    expect(fs.existsSync(templateRoot)).toBe(false);
    expect(() => removeTemplateSnapshot({packageRoot, targetRoot: outside})).toThrow(/refusing/i);
    expect(fs.readFileSync(path.join(outside, 'keep.txt'), 'utf8')).toBe('keep\n');
  });

  it('rejects a linked template target without touching its destination', () => {
    const sandbox = createTemporaryDirectory();
    const packageRoot = path.join(sandbox, 'package');
    const templateRoot = path.join(packageRoot, 'template');
    const outside = path.join(sandbox, 'outside');
    writeFixture(outside, 'keep.txt', 'keep\n');
    fs.mkdirSync(packageRoot, {recursive: true});

    try {
      fs.symlinkSync(outside, templateRoot, 'junction');
    } catch (error) {
      if (error && typeof error === 'object' && 'code' in error && error.code === 'EPERM') return;
      throw error;
    }

    expect(() => removeTemplateSnapshot({packageRoot, targetRoot: templateRoot})).toThrow(
      /symbolic link/i,
    );
    expect(fs.readFileSync(path.join(outside, 'keep.txt'), 'utf8')).toBe('keep\n');
  });
});
