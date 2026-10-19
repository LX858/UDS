export const secondsToHms = (d: number, type = 3) => {
	d = Number(d)
	const h = Math.floor(d / 3600)
	const m = Math.floor((d % 3600) / 60)
	const s = Math.floor((d % 3600) % 60)

	const hDisplay = h > 0 ? (h < 10 ? '0' + h + (h === 1 ? ':' : ':') : h + (h === 1 ? ':' : ':')) : ''
	const mDisplay = m > 0 ? (m < 10 ? '0' + m + (m === 1 ? ':' : ':') : m + (m === 1 ? ':' : ':')) : '00:'
	const sDisplay = s > 0 ? (s < 10 ? '0' + s : s) : '00'

	if (type === 3) {
		return hDisplay + mDisplay + sDisplay
	} else if (type === 2) {
		return hDisplay + mDisplay
	}
}

export const secondsToHms2 = (d: number) => {
	d = Number(d)
	const day = Math.floor(d / (24 * 3600))
	const h = Math.floor(d / 3600)
	const m = Math.floor((d % 3600) / 60)
	const s = Math.floor((d % 3600) % 60)
	if (day > 0) {
		return `${day}d`
	} else if (h > 0) {
		return `${h}h`
	} else if (m > 0) {
		return `${m}m`
	} else if (s > 0) {
		return `${s}s`
	} else {
		return null
	}
}
