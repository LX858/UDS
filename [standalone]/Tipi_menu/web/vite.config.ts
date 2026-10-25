import path from 'path'
import fs from 'fs'
import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'

const tipiRankingsSrc = path.resolve(__dirname, './vendor/Tipi_Rankings/web/src')
const tipiDailyRewardsSrc = path.resolve(__dirname, './vendor/Tipi_Daily_Rewards/web/src')
const claimSoundSrc = path.resolve(
	__dirname,
	'../../Tipi_Daily_Rewards/web/public/sounds/effect.mp3',
)
const claimSoundDest = path.resolve(__dirname, 'public/images/daily-rewards/sounds/effect.mp3')
const moneySvgSrc = path.resolve(__dirname, '../../Tipi_Daily_Rewards/web/public/images/money.svg')
const moneySvgDest = path.resolve(__dirname, 'public/images/daily-rewards/money.svg')

function syncDailyRewardAssets(): Plugin {
	const sync = () => {
		if (fs.existsSync(claimSoundSrc)) {
			fs.mkdirSync(path.dirname(claimSoundDest), { recursive: true })
			fs.copyFileSync(claimSoundSrc, claimSoundDest)
		}
		if (fs.existsSync(moneySvgSrc)) {
			fs.mkdirSync(path.dirname(moneySvgDest), { recursive: true })
			fs.copyFileSync(moneySvgSrc, moneySvgDest)
		}
	}
	return {
		name: 'sync-daily-reward-assets',
		buildStart: sync,
		configureServer() {
			sync()
		},
	}
}

// https://vitejs.dev/config/
export default defineConfig({
	plugins: [react(), syncDailyRewardAssets()],
	base: './',
	build: {
		outDir: 'build',
		rollupOptions: {
			output: {
				manualChunks(id) {
					if (id.includes('Tipi_Rankings/web/src')) {
						return 'leaderboard'
					}
					if (id.includes('Tipi_Daily_Rewards/web/src')) {
						return 'daily-rewards'
					}
				},
			},
		},
	},
	resolve: {
		alias: {
			'@': tipiRankingsSrc,
			'@tipi-rankings': tipiRankingsSrc,
			'@uls-lb': tipiRankingsSrc,
			'@tipi-daily-rewards': tipiDailyRewardsSrc,
		},
	},
})
