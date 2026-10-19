import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [
          ['@babel/plugin-proposal-decorators', {version: '2023-11'}],
        ],
      },
    }),
  ],
  base: './',
  build: {
    outDir: 'build',
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) return undefined;
          if (id.includes('typebox')) return 'contracts-runtime';
          if (id.includes('react') || id.includes('mobx')) return 'app-runtime';
          if (id.includes('@radix-ui') || id.includes('@base-ui')) {
            return 'ui-runtime';
          }
          return 'vendor';
        },
      },
    },
  },
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
});
