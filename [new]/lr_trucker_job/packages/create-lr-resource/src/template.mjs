import fs from 'node:fs';
import path from 'node:path';

const TEMPLATE_ENTRIES = [
  '.github',
  '.vscode',
  'client',
  'docs',
  'locales',
  'packages',
  'server',
  'shared',
  'tests',
  'tooling',
  'types',
  'utils',
  'web',
  '.gitignore',
  '.luarc.json',
  'config.lua',
  'fxmanifest.lua',
  'LICENSE',
  'lr_trucker_job.code-workspace',
  'package.json',
  'pnpm-lock.yaml',
  'pnpm-workspace.yaml',
  'README.md',
  'vitest.config.ts',
];
const IGNORED_DIRECTORIES = new Set([
  '.git',
  '.idea',
  '.tools',
  '.turbo',
  '.vite',
  'build',
  'coverage',
  'dist',
  'node_modules',
  'playwright-report',
  'test-results',
]);
const SAFE_ENV_EXAMPLES = new Set(['.env.example', '.env.sample', '.env.template']);
const SENSITIVE_FILE_NAMES = new Set(['.npmrc', '.pnpmfile.cjs']);
const SENSITIVE_FILE_EXTENSION = /\.(?:key|p12|pem|pfx)$/i;

function toPosix(relativePath) {
  return relativePath.split(path.sep).join('/');
}

function isInside(parent, candidate) {
  const relative = path.relative(parent, candidate);
  return relative === '' || (!relative.startsWith(`..${path.sep}`) && relative !== '..' && !path.isAbsolute(relative));
}

function assertTargetOutsideIncludedEntries(sourceRoot, targetRoot) {
  const relativeTarget = toPosix(path.relative(sourceRoot, targetRoot));
  if (relativeTarget === 'packages/create-lr-resource/template') return;
  for (const entry of TEMPLATE_ENTRIES) {
    const includedPath = path.resolve(sourceRoot, entry);
    if (isInside(includedPath, targetRoot)) {
      throw new Error(`Template snapshot target overlaps included source: ${entry}`);
    }
  }
}

function collectEntry(sourceRoot, relativeEntry, files) {
  const posixEntry = toPosix(relativeEntry);
  const fileName = path.basename(relativeEntry);
  if (posixEntry === 'packages/create-lr-resource/template') return;
  if (posixEntry.startsWith('packages/create-lr-resource/template/')) return;
  if (posixEntry.endsWith('.tgz')) return;
  if (
    (fileName.startsWith('.env') && !SAFE_ENV_EXAMPLES.has(fileName)) ||
    SENSITIVE_FILE_NAMES.has(fileName) ||
    SENSITIVE_FILE_EXTENSION.test(fileName)
  ) return;
  const absoluteEntry = path.join(sourceRoot, relativeEntry);
  let stats;
  try {
    stats = fs.lstatSync(absoluteEntry);
  } catch (error) {
    if (error && typeof error === 'object' && 'code' in error && error.code === 'ENOENT') return;
    throw error;
  }
  if (stats.isSymbolicLink()) {
    throw new Error(`Template source contains a symbolic link: ${relativeEntry}`);
  }
  if (stats.isFile()) {
    files.push(relativeEntry);
    return;
  }
  if (!stats.isDirectory()) return;

  for (const entry of fs.readdirSync(absoluteEntry, {withFileTypes: true})) {
    if (entry.isDirectory() && IGNORED_DIRECTORIES.has(entry.name)) continue;
    collectEntry(sourceRoot, path.join(relativeEntry, entry.name), files);
  }
}

function collectSnapshotFiles(sourceRoot) {
  const files = [];
  for (const entry of TEMPLATE_ENTRIES) collectEntry(sourceRoot, entry, files);
  return [...new Set(files)].sort((left, right) => left.localeCompare(right));
}

function assertDestinationAvailable(targetRoot) {
  if (!fs.existsSync(targetRoot)) return;
  const stats = fs.lstatSync(targetRoot);
  if (stats.isSymbolicLink()) {
    throw new Error(`Template snapshot target must not be a symbolic link: ${targetRoot}`);
  }
  if (!stats.isDirectory() || fs.readdirSync(targetRoot).length > 0) {
    throw new Error(`Template snapshot target is not empty: ${targetRoot}`);
  }
}

function normalizePath(value) {
  const resolved = path.resolve(value);
  return process.platform === 'win32' ? resolved.toLowerCase() : resolved;
}

export function removeTemplateSnapshot(options) {
  const packageRoot = path.resolve(options.packageRoot);
  const targetRoot = path.resolve(options.targetRoot);
  const expectedTarget = path.join(packageRoot, 'template');
  if (normalizePath(targetRoot) !== normalizePath(expectedTarget)) {
    throw new Error(`Refusing to remove non-canonical template target: ${targetRoot}`);
  }
  if (!fs.existsSync(targetRoot)) return false;

  const stats = fs.lstatSync(targetRoot);
  if (stats.isSymbolicLink()) {
    throw new Error(`Refusing to remove symbolic link template target: ${targetRoot}`);
  }
  if (!stats.isDirectory()) {
    throw new Error(`Refusing to remove non-directory template target: ${targetRoot}`);
  }
  fs.rmSync(targetRoot, {recursive: true, force: true});
  return true;
}

export function buildTemplateSnapshot(options) {
  const sourceRoot = path.resolve(options.sourceRoot);
  const targetRoot = path.resolve(options.targetRoot);
  if (!fs.existsSync(sourceRoot) || !fs.statSync(sourceRoot).isDirectory()) {
    throw new Error(`Template source does not exist: ${sourceRoot}`);
  }

  assertTargetOutsideIncludedEntries(sourceRoot, targetRoot);
  assertDestinationAvailable(targetRoot);
  const files = collectSnapshotFiles(sourceRoot);
  if (!files.includes('fxmanifest.lua') || !files.includes('package.json')) {
    throw new Error('Template source is missing fxmanifest.lua or package.json.');
  }

  const parent = path.dirname(targetRoot);
  fs.mkdirSync(parent, {recursive: true});
  const stageRoot = fs.mkdtempSync(path.join(parent, '.template-snapshot-'));
  try {
    for (const relativeFile of files) {
      const target = path.join(stageRoot, relativeFile);
      fs.mkdirSync(path.dirname(target), {recursive: true});
      fs.copyFileSync(path.join(sourceRoot, relativeFile), target);
    }
    if (fs.existsSync(targetRoot)) fs.rmdirSync(targetRoot);
    fs.renameSync(stageRoot, targetRoot);
  } catch (error) {
    fs.rmSync(stageRoot, {recursive: true, force: true});
    throw error;
  }

  return {
    sourceRoot,
    targetRoot,
    files: files.map(toPosix),
  };
}
