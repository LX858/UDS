import {createHash} from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

import {declaredFunctions, generateCfxDeclarations} from './generator.mjs';

const toolingDirectory = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(toolingDirectory, '..', '..');
const snapshotDirectory = path.join(toolingDirectory, 'snapshot');
const lockPath = path.join(toolingDirectory, 'snapshot.lock.json');
const sources = {
  gameNatives: {
    file: 'natives.json',
    url: 'https://runtime.fivem.net/doc/natives.json',
  },
  cfxNatives: {
    file: 'natives_cfx.json',
    url: 'https://runtime.fivem.net/doc/natives_cfx.json',
  },
};
const outputPaths = {
  client: path.join(repoRoot, 'types', 'cfx', 'client', 'natives.generated.d.lua'),
  server: path.join(repoRoot, 'types', 'cfx', 'server', 'natives.generated.d.lua'),
  shared: path.join(repoRoot, 'types', 'cfx', 'shared', 'natives.generated.d.lua'),
};

function sha256(content) {
  return createHash('sha256').update(content).digest('hex');
}

function parseMetadata(content, label) {
  if (content.length > 10 * 1024 * 1024) throw new Error(`${label} exceeds the 10 MiB limit`);
  const parsed = JSON.parse(content);
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error(`${label} must be a JSON object`);
  }
  return parsed;
}

async function refreshSnapshot() {
  const downloaded = {};
  for (const [key, source] of Object.entries(sources)) {
    const response = await fetch(source.url, {
      headers: {Accept: 'application/json', 'User-Agent': 'lr-boilerplate-v2-codegen'},
    });
    if (!response.ok) throw new Error(`failed to download ${source.url}: HTTP ${response.status}`);
    const content = await response.text();
    parseMetadata(content, source.file);
    const etag = response.headers.get('etag');
    if (!etag) throw new Error(`${source.url} did not provide an ETag source revision`);
    downloaded[key] = {
      content,
      lock: {
        url: source.url,
        file: source.file,
        sourceRevision: `etag:${etag}`,
        etag,
        lastModified: response.headers.get('last-modified'),
        sha256: sha256(content),
        bytes: Buffer.byteLength(content),
      },
    };
  }

  fs.mkdirSync(snapshotDirectory, {recursive: true});
  for (const entry of Object.values(downloaded)) {
    fs.writeFileSync(path.join(snapshotDirectory, entry.lock.file), entry.content);
  }
  const lock = {
    version: 1,
    game: 'gta5',
    sources: Object.fromEntries(
      Object.entries(downloaded).map(([key, entry]) => [key, entry.lock]),
    ),
  };
  fs.writeFileSync(lockPath, `${JSON.stringify(lock, null, 2)}\n`);
}

function readPinnedSnapshot() {
  const lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
  if (lock.version !== 1 || lock.game !== 'gta5') throw new Error('unsupported CFX snapshot lock');

  const metadata = {};
  for (const [key, expectedSource] of Object.entries(sources)) {
    const locked = lock.sources?.[key];
    if (!locked || locked.url !== expectedSource.url || locked.file !== expectedSource.file) {
      throw new Error(`invalid lock entry for ${key}`);
    }
    if (locked.sourceRevision !== `etag:${locked.etag}`) {
      throw new Error(`missing or invalid source revision for ${key}`);
    }
    const content = fs.readFileSync(path.join(snapshotDirectory, locked.file), 'utf8');
    if (Buffer.byteLength(content) !== locked.bytes || sha256(content) !== locked.sha256) {
      throw new Error(`snapshot integrity check failed for ${locked.file}`);
    }
    metadata[key] = parseMetadata(content, locked.file);
  }

  const snapshotId = Object.values(lock.sources)
    .map(source => source.sha256.slice(0, 12))
    .join('-');
  return {lock, metadata, snapshotId};
}

function readDeclaredFunctions(side) {
  return declaredFunctions(
    fs.readFileSync(path.join(repoRoot, 'types', 'cfx', side, 'globals.d.lua'), 'utf8'),
  );
}

function buildDeclarations(snapshot) {
  const shared = readDeclaredFunctions('shared');
  const ownClient = readDeclaredFunctions('client');
  const ownServer = readDeclaredFunctions('server');
  return generateCfxDeclarations({
    gameMetadata: snapshot.metadata.gameNatives,
    cfxMetadata: snapshot.metadata.cfxNatives,
    snapshotId: snapshot.snapshotId,
    handwritten: {
      client: new Set([...shared, ...ownClient]),
      server: new Set([...shared, ...ownServer]),
      shared,
    },
  });
}

function persistDeclarations(generated, check) {
  const drift = [];
  for (const [side, outputPath] of Object.entries(outputPaths)) {
    const current = fs.existsSync(outputPath) ? fs.readFileSync(outputPath, 'utf8') : undefined;
    const normalizedCurrent = current?.replace(/\r\n?/g, '\n');
    const normalizedGenerated = generated[side].replace(/\r\n?/g, '\n');
    if (normalizedCurrent === normalizedGenerated) continue;
    if (check) drift.push(path.relative(repoRoot, outputPath).replaceAll('\\', '/'));
    else fs.writeFileSync(outputPath, generated[side]);
  }
  if (drift.length > 0) throw new Error(`CFX declaration drift: ${drift.join(', ')}`);
}

const args = new Set(process.argv.slice(2));
const allowed = new Set(['--check', '--refresh']);
for (const arg of args) if (!allowed.has(arg)) throw new Error(`unknown option: ${arg}`);
if (args.has('--check') && args.has('--refresh')) {
  throw new Error('--check and --refresh cannot be combined');
}

if (args.has('--refresh')) await refreshSnapshot();
const snapshot = readPinnedSnapshot();
persistDeclarations(buildDeclarations(snapshot), args.has('--check'));
console.log(
  `${args.has('--check') ? 'CFX declarations are current' : 'Generated CFX declarations'} (${snapshot.snapshotId})`,
);
