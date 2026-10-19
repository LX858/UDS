import {mkdir, readFile, readdir, unlink, writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {extractStoreContracts} from '../../packages/nui-store/src/index';
import {moduleBoundaries} from '../../packages/contracts/src/authoring/index';
import {storeModules} from '../../web/src/app/modules/registry';
import {
  findDuplicateValues,
  findStaleGeneratedModuleArtifacts,
  GENERATED_MODULE_DIRECTORIES,
  renderArtifacts,
} from './generator';

const toolingDirectory = path.dirname(fileURLToPath(import.meta.url));
const rootDirectory = path.resolve(toolingDirectory, '../..');
const checkOnly = process.argv.includes('--check');
const storeDirectory = path.join(rootDirectory, 'web', 'src', 'app', 'modules');
const authoringDirectory = path.join(
  rootDirectory,
  'packages',
  'contracts',
  'src',
  'authoring'
);
const moduleContracts = extractStoreContracts(storeModules, moduleBoundaries);
const authoredStoreIds = (await collectFiles(storeDirectory, '.store.ts'))
  .map(file => path.basename(file, '.store.ts'))
  .sort();
const authoredBoundaryIds = (await collectFiles(authoringDirectory, '.boundaries.ts'))
  .map(file => path.basename(file, '.boundaries.ts'))
  .sort();
const authoredSchemaIds = (await collectFiles(authoringDirectory, '.schemas.ts'))
  .map(file => path.basename(file, '.schemas.ts'))
  .sort();
const registeredIds = moduleContracts.map(contract => contract.id).sort();
const duplicateStoreIds = findDuplicateValues(authoredStoreIds);
const duplicateBoundaryIds = findDuplicateValues(authoredBoundaryIds);
const duplicateSchemaIds = findDuplicateValues(authoredSchemaIds);
const unregisteredStores = authoredStoreIds.filter(id => !registeredIds.includes(id));
const missingStores = registeredIds.filter(id => !authoredStoreIds.includes(id));
const unregisteredBoundaries = authoredBoundaryIds.filter(
  id => !registeredIds.includes(id)
);
const missingBoundaries = registeredIds.filter(
  id => !authoredBoundaryIds.includes(id)
);
const unregisteredSchemas = authoredSchemaIds.filter(id => !registeredIds.includes(id));
if (
  duplicateStoreIds.length > 0 ||
  duplicateBoundaryIds.length > 0 ||
  duplicateSchemaIds.length > 0 ||
  unregisteredStores.length > 0 ||
  missingStores.length > 0 ||
  unregisteredBoundaries.length > 0 ||
  missingBoundaries.length > 0 ||
  unregisteredSchemas.length > 0
) {
  throw new TypeError(
    `Contract authoring mismatch. Duplicate stores: ${duplicateStoreIds.join(', ') || 'none'}; duplicate boundaries: ${duplicateBoundaryIds.join(', ') || 'none'}; duplicate schemas: ${duplicateSchemaIds.join(', ') || 'none'}; unregistered stores: ${unregisteredStores.join(', ') || 'none'}; missing stores: ${missingStores.join(', ') || 'none'}; unregistered boundaries: ${unregisteredBoundaries.join(', ') || 'none'}; missing boundaries: ${missingBoundaries.join(', ') || 'none'}; unregistered schemas: ${unregisteredSchemas.join(', ') || 'none'}`
  );
}
const artifacts = renderArtifacts(moduleContracts);
const drift: string[] = [];
const staleArtifacts = findStaleGeneratedModuleArtifacts(
  await collectGeneratedModuleArtifacts(),
  artifacts.keys()
);

if (checkOnly) {
  drift.push(...staleArtifacts);
} else {
  await Promise.all(
    staleArtifacts.map(file => unlink(path.join(rootDirectory, file)))
  );
}

async function collectGeneratedModuleArtifacts(): Promise<string[]> {
  const files: string[] = [];
  for (const {directory, suffix} of GENERATED_MODULE_DIRECTORIES) {
    let entries;
    try {
      entries = await readdir(path.join(rootDirectory, directory), {
        withFileTypes: true,
      });
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === 'ENOENT') continue;
      throw error;
    }
    for (const entry of entries) {
      if (entry.isFile() && entry.name.endsWith(suffix)) {
        files.push(`${directory}/${entry.name}`);
      }
    }
  }
  return files.sort();
}

async function collectFiles(directory: string, suffix: string): Promise<string[]> {
  const files: string[] = [];
  for (const entry of await readdir(directory, {withFileTypes: true})) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectFiles(target, suffix)));
    } else if (entry.isFile() && entry.name.endsWith(suffix)) {
      files.push(target);
    }
  }
  return files;
}

for (const [relativePath, content] of artifacts) {
  const target = path.join(rootDirectory, relativePath);
  if (checkOnly) {
    const existing = await readFile(target, 'utf8').catch(() => null);
    if (existing?.replace(/\r\n/g, '\n') !== content) drift.push(relativePath);
    continue;
  }
  await mkdir(path.dirname(target), {recursive: true});
  await writeFile(target, content, 'utf8');
}

if (drift.length > 0) {
  console.error(`Generated contract drift:\n- ${drift.join('\n- ')}`);
  process.exitCode = 1;
} else {
  console.log(
    checkOnly
      ? `Contract artifacts are current (${artifacts.size} files)`
      : `Generated ${artifacts.size} contract artifacts`
  );
}
