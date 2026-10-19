import {defineConfig} from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json-summary'],
      include: [
        'packages/contracts/src/index.ts',
        'packages/nui-store/src/index.ts',
        'tooling/codegen/generator.ts',
      ],
      exclude: ['**/*.test.ts', '**/generated/**'],
      thresholds: {
        lines: 80,
        functions: 80,
        statements: 80,
        branches: 80,
      },
    },
  },
});
