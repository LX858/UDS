import path from 'path';
import {configDefaults, defineConfig} from 'vitest/config';

export default defineConfig({
  esbuild: {jsx: 'automatic'},
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@lr/contracts/authoring': path.resolve(
        __dirname,
        '../packages/contracts/src/authoring'
      ),
      '@lr/contracts/modules': path.resolve(
        __dirname,
        '../packages/contracts/src/modules/index.ts'
      ),
      '@lr/contracts': path.resolve(
        __dirname,
        '../packages/contracts/src/index.ts'
      ),
    },
  },
  test: {
    environment: 'jsdom',
    exclude: [...configDefaults.exclude, 'e2e/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json-summary'],
      include: ['src/nui/**/*.ts', 'src/app/**/*.ts', 'src/app/**/*.tsx'],
      exclude: ['src/generated/**', 'src/components/ui/**'],
      thresholds: {
        lines: 80,
        functions: 80,
        statements: 80,
        branches: 80,
      },
    },
  },
});
