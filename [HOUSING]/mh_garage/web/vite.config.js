import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: './',
  publicDir: 'images',
  build: {
    outDir: '../html',
    emptyOutDir: true,
    copyPublicDir: true
  }
})
