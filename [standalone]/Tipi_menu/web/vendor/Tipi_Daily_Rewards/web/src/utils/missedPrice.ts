export const MISSED_MAX_CLAIMS_HARD = 31

export function normalizeMissedMultiplier(raw: number | undefined | null) {
	const m = Number(raw)
	if (!Number.isFinite(m) || m < 1) return 1
	if (m > 100) return 100
	return m
}

export function clampMissedMaxClaims(raw: number | undefined | null, daysInMonth = MISSED_MAX_CLAIMS_HARD) {
	const maxDays = Math.max(1, Math.min(MISSED_MAX_CLAIMS_HARD, Math.floor(Number(daysInMonth) || MISSED_MAX_CLAIMS_HARD)))
	const n = Math.max(0, Math.floor(Number(raw) || 0))
	return Math.min(n, maxDays)
}

export function missedClaimPriceAt(basePrice: number, multiplier: number, claimIndex: number) {
	const base = Math.max(0, Math.floor(Number(basePrice) || 0))
	const mult = normalizeMissedMultiplier(multiplier)
	const index = Math.max(0, Math.min(MISSED_MAX_CLAIMS_HARD, Math.floor(Number(claimIndex) || 0)))
	return Math.max(0, Math.round(base * (1 + (mult - 1) * index)))
}

export function missedClaimPricePreview(basePrice: number, multiplier: number, maxClaims: number) {
	const max = clampMissedMaxClaims(maxClaims)
	const list: Array<{ claim: number; price: number }> = []
	for (let i = 0; i < max; i += 1) {
		list.push({ claim: i + 1, price: missedClaimPriceAt(basePrice, multiplier, i) })
	}
	return list
}
