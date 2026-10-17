import * as path from 'path'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import svgr from 'vite-plugin-svgr'

// https://vitejs.dev/config/
export default defineConfig({
	plugins: [react(), svgr()],
	base: './',
	publicDir: 'public',
	build: {
		outDir: 'build',
		target: 'esnext'
	},
	esbuild: {
		logOverride: { 'this-is-undefined-in-esm': 'silent' }
	},
	resolve: {
		/* alias:[
            { find: '@', replacement: '/src'}
        ] */
		alias: {
			'@': path.resolve(__dirname, './src')
		}
	}
})
