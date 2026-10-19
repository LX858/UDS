import path from 'node:path';
import {pathToFileURL} from 'node:url';

const repoRoot = path.resolve(import.meta.dirname, '../..');
const testFiles = [
  'tests/security/security-policy.test.mjs',
];

let failed = 0;

for (const testFile of testFiles) {
  const fileUrl = pathToFileURL(path.join(repoRoot, testFile));
  const module = await import(fileUrl.href);

  for (const testCase of module.tests ?? []) {
    try {
      await testCase.run({repoRoot});
      console.log(`PASS security ${testCase.name}`);
    } catch (error) {
      failed += 1;
      console.error(`FAIL security ${testCase.name}`);
      console.error(error?.message ?? error);
    }
  }
}

if (failed > 0) {
  console.error(`security-check failed: ${failed} test(s) failed`);
  process.exit(1);
}

console.log('security-check passed');
