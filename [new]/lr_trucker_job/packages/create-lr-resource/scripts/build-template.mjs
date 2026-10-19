#!/usr/bin/env node
import {buildTemplateSnapshot, removeTemplateSnapshot} from '../src/template.mjs';
import {
  packageRoot,
  sourceRoot,
  templateRoot,
} from './template-paths.mjs';

removeTemplateSnapshot({packageRoot, targetRoot: templateRoot});
const result = buildTemplateSnapshot({sourceRoot, targetRoot: templateRoot});
console.log(`Prepared create-lr-resource template (${result.files.length} files).`);
