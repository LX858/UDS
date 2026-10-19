import path from 'node:path';
import {fileURLToPath} from 'node:url';

export const packageRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
);
export const sourceRoot = path.resolve(packageRoot, '..', '..');
export const templateRoot = path.join(packageRoot, 'template');
