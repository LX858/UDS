#!/usr/bin/env node
import {removeTemplateSnapshot} from '../src/template.mjs';
import {packageRoot, templateRoot} from './template-paths.mjs';

removeTemplateSnapshot({packageRoot, targetRoot: templateRoot});
