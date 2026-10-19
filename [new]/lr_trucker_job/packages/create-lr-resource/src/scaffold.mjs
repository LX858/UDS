import fs from 'node:fs';
import path from 'node:path';

const TEMPLATE_RESOURCE_NAMES = ['lr_trucker_job', 'lr_trucker_job'];
const RESOURCE_NAME_PATTERN = /^[a-z][a-z0-9_-]{0,63}$/;
const RESERVED_FILE_NAMES = /^(?:aux|con|nul|prn|com[1-9]|lpt[1-9])$/;
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
const TEXT_EXTENSIONS = new Set([
  '.cjs',
  '.css',
  '.html',
  '.js',
  '.json',
  '.lua',
  '.md',
  '.mjs',
  '.toml',
  '.ts',
  '.tsx',
  '.txt',
  '.yaml',
  '.yml',
]);
const TEXT_FILE_NAMES = new Set([
  '.editorconfig',
  '.eslintignore',
  '.gitignore',
  '.npmrc',
]);

export function validateResourceName(name) {
  if (
    typeof name !== 'string' ||
    !RESOURCE_NAME_PATTERN.test(name) ||
    RESERVED_FILE_NAMES.test(name)
  ) {
    throw new Error(
      'Resource name must start with a lowercase letter, contain only lowercase letters, numbers, underscores or hyphens, and be at most 64 characters.',
    );
  }
  return name;
}

function readArgumentValue(argv, index, flag) {
  const value = argv[index + 1];
  if (value === undefined || value.startsWith('-')) {
    throw new Error(`${flag} requires a value.`);
  }
  return value;
}

export function parseCliArguments(argv) {
  let name;
  let output;
  let help = false;

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--') {
      continue;
    } else if (argument === '--help' || argument === '-h') {
      help = true;
    } else if (argument === '--name') {
      name = readArgumentValue(argv, index, '--name');
      index += 1;
    } else if (argument.startsWith('--name=')) {
      name = argument.slice('--name='.length);
    } else if (argument === '--output' || argument === '-o') {
      output = readArgumentValue(argv, index, '--output');
      index += 1;
    } else if (argument.startsWith('--output=')) {
      output = argument.slice('--output='.length);
    } else if (argument.startsWith('-')) {
      throw new Error(`Unknown argument: ${argument}`);
    } else if (name === undefined) {
      name = argument;
    } else {
      throw new Error(`Unexpected positional argument: ${argument}`);
    }
  }

  return {help, name, output};
}

function collectTemplateFiles(templateRoot) {
  const files = [];

  function visit(directory, relativeDirectory) {
    const entries = fs.readdirSync(directory, {withFileTypes: true});
    for (const entry of entries) {
      if (entry.isDirectory() && IGNORED_DIRECTORIES.has(entry.name)) continue;

      const relativePath = path.join(relativeDirectory, entry.name);
      const absolutePath = path.join(directory, entry.name);
      if (entry.isSymbolicLink()) {
        throw new Error(`Template contains a symbolic link: ${relativePath}`);
      }
      if (entry.isDirectory()) {
        visit(absolutePath, relativePath);
      } else if (entry.isFile()) {
        files.push(relativePath);
      }
    }
  }

  visit(templateRoot, '');
  return files.sort((left, right) => left.localeCompare(right));
}

function isTextFile(relativePath) {
  const fileName = path.basename(relativePath);
  return TEXT_FILE_NAMES.has(fileName) || TEXT_EXTENSIONS.has(path.extname(fileName));
}

function renameTemplatePath(relativePath, resourceName) {
  return TEMPLATE_RESOURCE_NAMES.reduce(
    (renamed, templateName) => renamed.replaceAll(templateName, resourceName),
    relativePath,
  );
}

function transformText(relativePath, content, resourceName) {
  let transformed = content;
  if (relativePath === 'fxmanifest.lua') {
    transformed = transformed.replace(/^repository\s+['"][^'"\r\n]*['"]\s*\r?\n?/m, '');
  }
  return TEMPLATE_RESOURCE_NAMES.reduce(
    (result, templateName) => result.replaceAll(templateName, resourceName),
    transformed,
  );
}

function assertDestinationAvailable(output) {
  if (!fs.existsSync(output)) return;
  const stats = fs.lstatSync(output);
  if (stats.isSymbolicLink()) {
    throw new Error(`Destination must not be a symbolic link: ${output}`);
  }
  if (!stats.isDirectory() || fs.readdirSync(output).length > 0) {
    throw new Error(`Destination is not empty: ${output}`);
  }
}

function assertUniqueTargets(files, resourceName) {
  const targets = new Set();
  for (const relativePath of files) {
    const target = renameTemplatePath(relativePath, resourceName);
    if (targets.has(target)) {
      throw new Error(`Template paths collide after renaming: ${target}`);
    }
    targets.add(target);
  }
}

function copyTemplateFile(templateRoot, stageRoot, relativePath, resourceName) {
  const source = path.join(templateRoot, relativePath);
  const renamedPath = renameTemplatePath(relativePath, resourceName);
  const target = path.join(stageRoot, renamedPath);
  fs.mkdirSync(path.dirname(target), {recursive: true});

  if (isTextFile(relativePath)) {
    const content = fs.readFileSync(source, 'utf8');
    fs.writeFileSync(target, transformText(relativePath, content, resourceName), 'utf8');
  } else {
    fs.copyFileSync(source, target);
  }
}

export function scaffoldResource(options) {
  const name = validateResourceName(options.name);
  const templateRoot = path.resolve(options.templateRoot);
  const output = path.resolve(options.output);

  if (!fs.existsSync(templateRoot) || !fs.statSync(templateRoot).isDirectory()) {
    throw new Error(`Template directory does not exist: ${templateRoot}`);
  }

  const files = collectTemplateFiles(templateRoot);
  if (files.length === 0) throw new Error('Template directory is empty.');
  assertUniqueTargets(files, name);
  assertDestinationAvailable(output);

  const parent = path.dirname(output);
  fs.mkdirSync(parent, {recursive: true});
  const stageRoot = fs.mkdtempSync(path.join(parent, `.${path.basename(output)}-`));

  try {
    for (const relativePath of files) {
      copyTemplateFile(templateRoot, stageRoot, relativePath, name);
    }
    if (fs.existsSync(output)) fs.rmdirSync(output);
    fs.renameSync(stageRoot, output);
  } catch (error) {
    fs.rmSync(stageRoot, {recursive: true, force: true});
    throw error;
  }

  return {
    name,
    output,
    workspace: path.join(output, `${name}.code-workspace`),
    files: files.length,
  };
}

export function usage() {
  return `Usage: create-lr-resource --name <resource_name> [--output <directory>]

Creates an isolated, typed FiveM resource from the LR v2 template.

Examples:
  npx create-lr-resource@latest --name my_inventory
  npm create lr-resource@latest -- --name my_inventory
  pnpm dlx create-lr-resource@latest my_inventory`;
}
