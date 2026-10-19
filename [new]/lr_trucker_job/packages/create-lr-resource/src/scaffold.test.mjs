import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {afterEach, describe, expect, it} from 'vitest';
import {
  parseCliArguments,
  scaffoldResource,
  validateResourceName,
} from './scaffold.mjs';

const temporaryDirectories = [];

function createTemporaryDirectory() {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'create-lr-resource-'));
  temporaryDirectories.push(directory);
  return directory;
}

function writeFixture(root, relativePath, content) {
  const target = path.join(root, relativePath);
  fs.mkdirSync(path.dirname(target), {recursive: true});
  fs.writeFileSync(target, content, 'utf8');
}

function createTemplateFixture(root) {
  writeFixture(
    root,
    'fxmanifest.lua',
    "name 'lr_trucker_job'\nrepository 'https://github.com/Lorraxs/lr_trucker_job'\n",
  );
  writeFixture(
    root,
    'package.json',
    '{"name":"lr_trucker_job","scripts":{"package":"node package-resource.mjs --name lr_trucker_job"}}\n',
  );
  writeFixture(
    root,
    'lr_trucker_job.code-workspace',
    '{"folders":[{"name":"resource-root","path":"."}]}\n',
  );
  writeFixture(root, 'README.md', '# lr_trucker_job\n');
  writeFixture(root, 'client/boot.lua', 'return "lr_trucker_job"\n');
  writeFixture(root, 'node_modules/secret.txt', 'do not copy\n');
  writeFixture(root, 'web/build/index.html', 'do not copy\n');
  writeFixture(root, 'dist/release.zip', 'do not copy\n');
  writeFixture(root, '.git/config', 'do not copy\n');
}

afterEach(() => {
  for (const directory of temporaryDirectories.splice(0)) {
    fs.rmSync(directory, {recursive: true, force: true});
  }
});

describe('validateResourceName', () => {
  it.each(['inventory', 'my_inventory', 'jobs-v2', 'a'])('accepts %s', name => {
    expect(validateResourceName(name)).toBe(name);
  });

  it.each(['', '../escape', 'Bad Name', '-jobs', 'con', 'nul', 'com1', 'a'.repeat(65)])(
    'rejects unsafe resource name %j',
    name => {
      expect(() => validateResourceName(name)).toThrow(/resource name/i);
    },
  );
});

describe('parseCliArguments', () => {
  it('accepts the documented --name and --output interface', () => {
    expect(parseCliArguments(['--name', 'inventory', '--output', 'resources/inventory'])).toEqual({
      help: false,
      name: 'inventory',
      output: 'resources/inventory',
    });
  });

  it('accepts a positional resource name', () => {
    expect(parseCliArguments(['inventory'])).toEqual({
      help: false,
      name: 'inventory',
      output: undefined,
    });
  });

  it('accepts equals syntax, output alias and help', () => {
    expect(parseCliArguments(['--name=inventory', '--output=resources/inventory'])).toEqual({
      help: false,
      name: 'inventory',
      output: 'resources/inventory',
    });
    expect(parseCliArguments(['inventory', '-o', 'resources/inventory'])).toEqual({
      help: false,
      name: 'inventory',
      output: 'resources/inventory',
    });
    expect(parseCliArguments(['-h'])).toEqual({help: true, name: undefined, output: undefined});
    expect(parseCliArguments(['--', '--name', 'inventory'])).toEqual({
      help: false,
      name: 'inventory',
      output: undefined,
    });
  });

  it('rejects missing values and unknown flags', () => {
    expect(() => parseCliArguments(['--name'])).toThrow(/value/i);
    expect(() => parseCliArguments(['--unknown'])).toThrow(/unknown/i);
    expect(() => parseCliArguments(['inventory', 'extra'])).toThrow(/unexpected/i);
  });
});

describe('scaffoldResource', () => {
  it('creates a renamed resource without copying generated or private artifacts', () => {
    const sandbox = createTemporaryDirectory();
    const templateRoot = path.join(sandbox, 'template');
    const outputRoot = path.join(sandbox, 'inventory');
    createTemplateFixture(templateRoot);

    const result = scaffoldResource({
      name: 'inventory',
      output: outputRoot,
      templateRoot,
    });

    expect(result).toMatchObject({name: 'inventory', output: outputRoot});
    expect(fs.readFileSync(path.join(outputRoot, 'fxmanifest.lua'), 'utf8')).toBe(
      "name 'inventory'\n",
    );
    expect(fs.readFileSync(path.join(outputRoot, 'package.json'), 'utf8')).toContain(
      '--name inventory',
    );
    expect(fs.existsSync(path.join(outputRoot, 'inventory.code-workspace'))).toBe(true);
    expect(fs.existsSync(path.join(outputRoot, 'lr_trucker_job.code-workspace'))).toBe(false);
    expect(fs.readFileSync(path.join(outputRoot, 'client/boot.lua'), 'utf8')).toContain(
      'inventory',
    );
    expect(fs.existsSync(path.join(outputRoot, 'node_modules'))).toBe(false);
    expect(fs.existsSync(path.join(outputRoot, 'web/build'))).toBe(false);
    expect(fs.existsSync(path.join(outputRoot, 'dist'))).toBe(false);
    expect(fs.existsSync(path.join(outputRoot, '.git'))).toBe(false);
  });

  it('refuses to write into a non-empty destination', () => {
    const sandbox = createTemporaryDirectory();
    const templateRoot = path.join(sandbox, 'template');
    const outputRoot = path.join(sandbox, 'inventory');
    createTemplateFixture(templateRoot);
    writeFixture(outputRoot, 'keep.txt', 'user data\n');

    expect(() => scaffoldResource({name: 'inventory', output: outputRoot, templateRoot})).toThrow(
      /not empty/i,
    );
    expect(fs.readFileSync(path.join(outputRoot, 'keep.txt'), 'utf8')).toBe('user data\n');
  });

  it('rejects symbolic links from the template instead of following them', () => {
    const sandbox = createTemporaryDirectory();
    const templateRoot = path.join(sandbox, 'template');
    const outputRoot = path.join(sandbox, 'inventory');
    createTemplateFixture(templateRoot);
    const outside = path.join(sandbox, 'outside.txt');
    fs.writeFileSync(outside, 'private\n', 'utf8');

    try {
      fs.symlinkSync(outside, path.join(templateRoot, 'linked.txt'), 'file');
    } catch (error) {
      if (error && typeof error === 'object' && 'code' in error && error.code === 'EPERM') return;
      throw error;
    }

    expect(() => scaffoldResource({name: 'inventory', output: outputRoot, templateRoot})).toThrow(
      /symbolic link/i,
    );
    expect(fs.existsSync(path.join(outputRoot, 'linked.txt'))).toBe(false);
  });

  it('supports an existing empty destination and preserves binary assets', () => {
    const sandbox = createTemporaryDirectory();
    const templateRoot = path.join(sandbox, 'template');
    const outputRoot = path.join(sandbox, 'inventory');
    createTemplateFixture(templateRoot);
    fs.mkdirSync(outputRoot);
    fs.mkdirSync(path.join(templateRoot, 'web/public'), {recursive: true});
    const binary = Buffer.from([0, 255, 1, 254]);
    fs.writeFileSync(path.join(templateRoot, 'web/public/icon.png'), binary);

    scaffoldResource({name: 'inventory', output: outputRoot, templateRoot});

    expect(fs.readFileSync(path.join(outputRoot, 'web/public/icon.png'))).toEqual(binary);
  });

  it('rejects missing, empty and colliding templates', () => {
    const sandbox = createTemporaryDirectory();
    const missing = path.join(sandbox, 'missing');
    const empty = path.join(sandbox, 'empty');
    fs.mkdirSync(empty);

    expect(() =>
      scaffoldResource({name: 'inventory', output: path.join(sandbox, 'one'), templateRoot: missing}),
    ).toThrow(/does not exist/i);
    expect(() =>
      scaffoldResource({name: 'inventory', output: path.join(sandbox, 'two'), templateRoot: empty}),
    ).toThrow(/empty/i);

    const collision = path.join(sandbox, 'collision');
    createTemplateFixture(collision);
    writeFixture(collision, 'inventory.code-workspace', '{}\n');
    expect(() =>
      scaffoldResource({
        name: 'inventory',
        output: path.join(sandbox, 'three'),
        templateRoot: collision,
      }),
    ).toThrow(/collide/i);
  });
});
