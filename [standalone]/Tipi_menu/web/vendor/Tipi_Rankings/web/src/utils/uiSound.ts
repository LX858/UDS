import { fetchNui } from './fetchNui'
import { isEnvBrowser } from './misc'

let audioCtx: AudioContext | null = null

function getCtx() {
	if (!audioCtx) audioCtx = new AudioContext()
	return audioCtx
}

export function playUiClick() {
	if (isEnvBrowser()) {
		try {
			const ctx = getCtx()
			const osc = ctx.createOscillator()
			const gain = ctx.createGain()
			osc.connect(gain)
			gain.connect(ctx.destination)
			osc.frequency.value = 720
			gain.gain.value = 0.04
			osc.start()
			gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.06)
			osc.stop(ctx.currentTime + 0.07)
		} catch {
		}
		return
	}
	fetchNui('playClick').catch(() => {})
}
