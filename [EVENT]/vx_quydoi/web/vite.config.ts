/// <reference types="vitest" />
import {defineConfig} from 'vite';
import path from 'path';


// https://vitejs.dev/config/
export default defineConfig({
  plugins: [],
  base: './',
  build: {
    outDir: 'build',
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  
});
