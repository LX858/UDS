#!/usr/bin/env node
import path from 'node:path';
import process from 'node:process';
import {fileURLToPath} from 'node:url';
import {
  parseCliArguments,
  scaffoldResource,
  usage,
  validateResourceName,
} from '../src/scaffold.mjs';

function main() {
  try {
    const arguments_ = parseCliArguments(process.argv.slice(2));
    if (arguments_.help) {
      console.log(usage());
      return;
    }

    const name = validateResourceName(arguments_.name);
    const packageRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
    const output = path.resolve(process.cwd(), arguments_.output ?? name);
    const result = scaffoldResource({
      name,
      output,
      templateRoot: path.join(packageRoot, 'template'),
    });

    console.log(`Created FiveM resource ${result.name} at ${result.output}`);
    console.log(`Open ${result.workspace}`);
    console.log('Next: pnpm install && pnpm generate && pnpm verify');
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    console.error(usage());
    process.exitCode = 1;
  }
}

main();
