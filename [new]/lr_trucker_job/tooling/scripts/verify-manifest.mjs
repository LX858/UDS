#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import {fileURLToPath} from 'node:url';

const MANIFEST_BLOCKS = [
  'files',
  'shared_scripts',
  'client_scripts',
  'server_scripts',
];

function usage() {
  return `Usage: node tooling/scripts/verify-manifest.mjs [--root <path>] [--json]

Checks local file references in fxmanifest.lua. External at-paths such as
@oxmysql/lib/MySQL.lua and runtime dependency constraints are ignored.`;
}

function parseArgs(argv) {
  const args = {
    root: process.cwd(),
    json: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--root') {
      args.root = argv[++i];
    } else if (arg === '--json') {
      args.json = true;
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

function assertPathInside(root, candidate, label) {
  const relative = path.relative(root, path.resolve(candidate));
  if (
    relative === '..' ||
    relative.startsWith(`..${path.sep}`) ||
    path.isAbsolute(relative)
  ) {
    throw new Error(`${label} escapes resource root`);
  }
}

function isExternalReference(value) {
  return (
    value.startsWith('@') ||
    value.startsWith('/') ||
    value.includes(':') ||
    value.startsWith('http://') ||
    value.startsWith('https://')
  );
}

function hasGlob(value) {
  return value.includes('*') || value.includes('?');
}

function escapeRegex(value) {
  return value.replace(/[|\\{}()[\]^$+?.]/g, '\\$&');
}

function globToRegex(pattern) {
  const normalized = toPosix(pattern);
  let source = '';

  for (let i = 0; i < normalized.length; i += 1) {
    const char = normalized[i];
    const next = normalized[i + 1];

    if (char === '*' && next === '*') {
      const afterNext = normalized[i + 2];
      if (afterNext === '/') {
        source += '(?:.*/)?';
        i += 2;
      } else {
        source += '.*';
        i += 1;
      }
    } else if (char === '*') {
      source += '[^/]*';
    } else if (char === '?') {
      source += '[^/]';
    } else {
      source += escapeRegex(char);
    }
  }

  return new RegExp(`^${source}$`);
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
      if (entry.isDirectory() && ignoredDirectories.has(entry.name)) {
        continue;
      }

      const absolute = path.join(directory, entry.name);

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

function extractManifestReferences(manifestText) {
  const references = [];

  for (const blockName of MANIFEST_BLOCKS) {
    const blockRegex = new RegExp(`${blockName}\\s*\\{([\\s\\S]*?)\\}`, 'g');
    for (const blockMatch of manifestText.matchAll(blockRegex)) {
      const block = blockMatch[1];
      const stringRegex = /['"]([^'"]+)['"]/g;
      for (const stringMatch of block.matchAll(stringRegex)) {
        const value = stringMatch[1].trim();
        if (value && !isExternalReference(value)) {
          references.push(value);
        }
      }
    }
  }

  return [...new Set(references)].sort();
}

export function verifyManifest(rootInput = process.cwd()) {
  const root = path.resolve(rootInput);
  const manifestPath = path.join(root, 'fxmanifest.lua');

  if (!fs.existsSync(manifestPath)) {
    throw new Error(`Missing fxmanifest.lua at ${manifestPath}`);
  }

  const manifestText = fs.readFileSync(manifestPath, 'utf8');
  const references = extractManifestReferences(manifestText);
  const allFiles = walkFiles(root);
  const included = new Set(['fxmanifest.lua']);
  const missing = [];
  const unmatchedGlobs = [];

  for (const reference of references) {
    const normalized = toPosix(reference);
    assertPathInside(root, path.resolve(root, normalized), `Manifest reference ${normalized}`);

    if (hasGlob(normalized)) {
      const matcher = globToRegex(normalized);
      const matches = allFiles.filter(file => matcher.test(file));
      if (matches.length === 0) {
        unmatchedGlobs.push(normalized);
      } else {
        for (const match of matches) {
          included.add(match);
        }
      }
      continue;
    }

    const absolute = path.resolve(root, normalized);
    if (!fs.existsSync(absolute)) {
      missing.push(normalized);
    } else if (fs.statSync(absolute).isDirectory()) {
      const prefix = `${normalized.replace(/\/$/, '')}/`;
      for (const file of allFiles) {
        if (file.startsWith(prefix)) {
          included.add(file);
        }
      }
    } else {
      included.add(normalized);
    }
  }

  return {
    ok: missing.length === 0 && unmatchedGlobs.length === 0,
    root,
    manifest: 'fxmanifest.lua',
    references,
    included: [...included].sort(),
    missing: missing.sort(),
    unmatchedGlobs: unmatchedGlobs.sort(),
  };
}

function main() {
  try {
    const args = parseArgs(process.argv.slice(2));
    if (args.help) {
      console.log(usage());
      return;
    }

    const result = verifyManifest(args.root);
    if (args.json) {
      console.log(JSON.stringify(result, null, 2));
    } else if (result.ok) {
      console.log(`Manifest OK: ${result.included.length} local files matched.`);
      if (result.unmatchedGlobs.length > 0) {
        console.log(`Unmatched optional globs: ${result.unmatchedGlobs.length}`);
      }
    } else {
      console.error('Manifest references are invalid:');
      for (const missing of result.missing) {
        console.error(`- ${missing}`);
      }
      for (const unmatched of result.unmatchedGlobs) {
        console.error(`- unmatched glob: ${unmatched}`);
      }
    }

    if (!result.ok) {
      process.exitCode = 1;
    }
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  main();
}
