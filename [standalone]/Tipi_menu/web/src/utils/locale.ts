import { viLocale } from '../locales/vi'

/** Gộp locale từ game (Lua) — thiếu key thì dùng bản vi.ts */
export function mergeGameLocale(fromGame?: Record<string, string>): Record<string, string> {
	const merged: Record<string, string> = { ...viLocale }
	if (!fromGame || typeof fromGame !== 'object') {
		return merged
	}
	for (const [key, value] of Object.entries(fromGame)) {
		if (typeof value === 'string' && value.length > 0) {
			merged[key] = value
		}
	}
	return merged
}
