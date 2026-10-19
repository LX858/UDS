#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import {fileURLToPath} from 'node:url';
import {verifyManifest} from './verify-manifest.mjs';

const FIXED_ARCHIVE_TIME = new Date('2024-01-01T00:00:00Z');
const ZIP_DOS_TIME = 0;
const ZIP_DOS_DATE = ((2024 - 1980) << 9) | (1 << 5) | 1;
const OPTIONAL_RELEASE_FILES = [
  'README.md',
  'LICENSE',
  '.luarc.json',
  'client/.luarc.json',
  'server/.luarc.json',
  'shared/.luarc.json',
  'lr_trucker_job.code-workspace',
];
const OPTIONAL_RELEASE_GLOBS = [
  /^docs\/.+\.md$/,
  /^types\/.+\.d\.lua$/,
];

function usage() {
  return `Usage: node tooling/scripts/package-resource.mjs --name <resource> [--root <path>] [--out <path>] [--no-zip]

Stages a FiveM resource from fxmanifest.lua local references and optionally
creates a deterministic zip without requiring a platform-specific zip CLI.`;
}

function parseArgs(argv) {
  const args = {
    root: process.cwd(),
    out: path.join(process.cwd(), 'dist', 'release'),
    noZip: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--root') {
      args.root = argv[++i];
    } else if (arg === '--out') {
      args.out = argv[++i];
    } else if (arg === '--name') {
      args.name = argv[++i];
    } else if (arg === '--no-zip') {
      args.noZip = true;
    } else if (arg === '--help' || arg === '-h') {
      args.help = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

function toPosix(value) {
  return value.split(path.sep).join('/');
}

function resolveInside(root, relativeFile, label) {
  const resolvedRoot = path.resolve(root);
  const resolved = path.resolve(resolvedRoot, relativeFile);
  const relative = path.relative(resolvedRoot, resolved);
  if (
    relative === '..' ||
    relative.startsWith(`..${path.sep}`) ||
    path.isAbsolute(relative)
  ) {
    throw new Error(`${label} escapes its root: ${relativeFile}`);
  }
  return resolved;
}

function walkFiles(root) {
  const files = [];
  const ignoredDirectories = new Set([
    '.git',
    'node_modules',
    'dist',
    'coverage',
    '.turbo',
    '.vite',
  ]);

  function visit(directory) {
    for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory() && ignoredDirectories.has(entry.name)) {
        continue;
      }

      if (entry.isDirectory()) {
        visit(absolute);
      } else if (entry.isFile()) {
        files.push(toPosix(path.relative(root, absolute)));
      }
    }
  }

  visit(root);
  return files.sort();
}

function copyFileDeterministic(sourceRoot, stageRoot, relativeFile) {
  const source = resolveInside(sourceRoot, relativeFile, 'Package source');
  const realSource = fs.realpathSync(source);
  resolveInside(
    sourceRoot,
    path.relative(path.resolve(sourceRoot), realSource),
    'Resolved package source'
  );
  const target = resolveInside(stageRoot, relativeFile, 'Package target');

  fs.mkdirSync(path.dirname(target), {recursive: true});
  fs.copyFileSync(realSource, target);
  fs.utimesSync(target, FIXED_ARCHIVE_TIME, FIXED_ARCHIVE_TIME);
}

function assertSafeTarget(root, out, stageRoot) {
  const resolvedRoot = path.resolve(root);
  const resolvedOut = path.resolve(out);
  const resolvedStage = path.resolve(stageRoot);
  const driveRoot = path.parse(resolvedStage).root;

  if (resolvedStage === driveRoot) {
    throw new Error(`Refusing to use drive root as stage target: ${resolvedStage}`);
  }

  if (resolvedStage === resolvedRoot || resolvedOut === resolvedRoot) {
    throw new Error('Refusing to stage directly into the resource root.');
  }

  if (!resolvedStage.startsWith(`${resolvedOut}${path.sep}`)) {
    throw new Error('Stage target must be inside the output directory.');
  }
}

function assertNoLinkedAncestor(target, label) {
  const resolvedTarget = path.resolve(target);
  let existing = resolvedTarget;
  while (!fs.existsSync(existing)) {
    const parent = path.dirname(existing);
    if (parent === existing) break;
    existing = parent;
  }
  if (!fs.existsSync(existing)) {
    throw new Error(`${label} has no resolvable filesystem ancestor.`);
  }
  const realExisting = fs.realpathSync.native(existing);
  if (normalizePath(realExisting) !== normalizePath(existing)) {
    throw new Error(
      `${label} traverses a symbolic link or junction: ${resolvedTarget}`,
    );
  }
}

function normalizePath(value) {
  const normalized = path.resolve(value);
  return process.platform === 'win32' ? normalized.toLowerCase() : normalized;
}

function collectReleaseFiles(root, manifestFiles) {
  const files = new Set(manifestFiles);
  const allFiles = walkFiles(root);

  for (const optionalFile of OPTIONAL_RELEASE_FILES) {
    if (fs.existsSync(path.join(root, optionalFile))) {
      files.add(optionalFile);
    }
  }

  for (const file of allFiles) {
    if (OPTIONAL_RELEASE_GLOBS.some(pattern => pattern.test(file))) {
      files.add(file);
    }
  }

  return [...files]
    .filter(file => !file.startsWith('web/src/'))
    .filter(file => !file.includes('/node_modules/'))
    .sort();
}

function writeManifest(stageRoot, files) {
  fs.writeFileSync(
    path.join(stageRoot, 'release-manifest.txt'),
    `${files.join('\n')}\n`,
    'utf8'
  );
  fs.utimesSync(
    path.join(stageRoot, 'release-manifest.txt'),
    FIXED_ARCHIVE_TIME,
    FIXED_ARCHIVE_TIME
  );
}

const CRC32_TABLE = new Uint32Array(256);
for (let i = 0; i < CRC32_TABLE.length; i += 1) {
  let value = i;
  for (let bit = 0; bit < 8; bit += 1) {
    value = (value & 1) === 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
  }
  CRC32_TABLE[i] = value >>> 0;
}

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const byte of buffer) {
    crc = CRC32_TABLE[(crc ^ byte) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function localZipHeader(fileName, data, checksum) {
  const name = Buffer.from(fileName, 'utf8');
  const header = Buffer.alloc(30);
  header.writeUInt32LE(0x04034b50, 0);
  header.writeUInt16LE(20, 4);
  header.writeUInt16LE(0, 6);
  header.writeUInt16LE(0, 8);
  header.writeUInt16LE(ZIP_DOS_TIME, 10);
  header.writeUInt16LE(ZIP_DOS_DATE, 12);
  header.writeUInt32LE(checksum, 14);
  header.writeUInt32LE(data.length, 18);
  header.writeUInt32LE(data.length, 22);
  header.writeUInt16LE(name.length, 26);
  header.writeUInt16LE(0, 28);
  return Buffer.concat([header, name, data]);
}

function centralZipHeader(fileName, data, checksum, offset) {
  const name = Buffer.from(fileName, 'utf8');
  const header = Buffer.alloc(46);
  header.writeUInt32LE(0x02014b50, 0);
  header.writeUInt16LE(20, 4);
  header.writeUInt16LE(20, 6);
  header.writeUInt16LE(0, 8);
  header.writeUInt16LE(0, 10);
  header.writeUInt16LE(ZIP_DOS_TIME, 12);
  header.writeUInt16LE(ZIP_DOS_DATE, 14);
  header.writeUInt32LE(checksum, 16);
  header.writeUInt32LE(data.length, 20);
  header.writeUInt32LE(data.length, 24);
  header.writeUInt16LE(name.length, 28);
  header.writeUInt16LE(0, 30);
  header.writeUInt16LE(0, 32);
  header.writeUInt16LE(0, 34);
  header.writeUInt16LE(0, 36);
  header.writeUInt32LE(0, 38);
  header.writeUInt32LE(offset, 42);
  return Buffer.concat([header, name]);
}

function endOfCentralDirectory(fileCount, centralSize, centralOffset) {
  const footer = Buffer.alloc(22);
  footer.writeUInt32LE(0x06054b50, 0);
  footer.writeUInt16LE(0, 4);
  footer.writeUInt16LE(0, 6);
  footer.writeUInt16LE(fileCount, 8);
  footer.writeUInt16LE(fileCount, 10);
  footer.writeUInt32LE(centralSize, 12);
  footer.writeUInt32LE(centralOffset, 16);
  footer.writeUInt16LE(0, 20);
  return footer;
}

function createZip(stageRoot, out, name) {
  const zipPath = path.join(out, `${name}.zip`);
  const files = walkFiles(stageRoot);
  if (fs.existsSync(zipPath)) {
    fs.rmSync(zipPath, {force: true});
  }

  const localParts = [];
  const centralParts = [];
  let offset = 0;
  for (const file of files) {
    const data = fs.readFileSync(path.join(stageRoot, file));
    const checksum = crc32(data);
    const local = localZipHeader(file, data, checksum);
    localParts.push(local);
    centralParts.push(centralZipHeader(file, data, checksum, offset));
    offset += local.length;
  }

  const centralDirectory = Buffer.concat(centralParts);
  const footer = endOfCentralDirectory(files.length, centralDirectory.length, offset);
  fs.writeFileSync(zipPath, Buffer.concat([...localParts, centralDirectory, footer]));
  fs.utimesSync(zipPath, FIXED_ARCHIVE_TIME, FIXED_ARCHIVE_TIME);
  return zipPath;
}

export function packageResource(options) {
  const root = path.resolve(options.root ?? process.cwd());
  const out = path.resolve(options.out ?? path.join(root, 'dist', 'release'));
  const name = options.name;

  if (!name) {
    throw new Error('Missing required --name argument.');
  }

  const manifestResult = verifyManifest(root);
  if (!manifestResult.ok) {
    throw new Error(
      `Manifest is invalid: ${[
        ...manifestResult.missing,
        ...manifestResult.unmatchedGlobs.map(glob => `unmatched glob ${glob}`),
      ].join(', ')}`
    );
  }

  const stageRoot = path.join(out, name);
  assertSafeTarget(root, out, stageRoot);
  assertNoLinkedAncestor(out, 'Output directory');
  assertNoLinkedAncestor(stageRoot, 'Stage target');

  fs.rmSync(stageRoot, {recursive: true, force: true});
  fs.mkdirSync(stageRoot, {recursive: true});
  assertNoLinkedAncestor(out, 'Output directory');
  assertNoLinkedAncestor(stageRoot, 'Stage target');

  const releaseFiles = collectReleaseFiles(root, manifestResult.included);
  for (const relativeFile of releaseFiles) {
    copyFileDeterministic(root, stageRoot, relativeFile);
  }
  writeManifest(stageRoot, releaseFiles);

  const zipPath = options.noZip ? null : createZip(stageRoot, out, name);

  return {
    ok: true,
    root,
    out,
    stageRoot,
    zipPath,
    files: [...releaseFiles, 'release-manifest.txt'].sort(),
  };
}

function main() {
  try {
    const args = parseArgs(process.argv.slice(2));
    if (args.help) {
      console.log(usage());
      return;
    }

    const result = packageResource(args);
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  main();
}
