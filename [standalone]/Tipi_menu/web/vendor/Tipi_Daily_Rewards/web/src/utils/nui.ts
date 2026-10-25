export const RESOURCE_NAME =
	typeof window.GetParentResourceName === 'function'
		? window.GetParentResourceName()
		: 'Tipi_Daily_Rewards'

let nuiEventPrefix = ''

export function setNuiEventPrefix(prefix: string) {
	nuiEventPrefix = prefix
}

export function getNuiEventPrefix() {
	return nuiEventPrefix
}

export function isEnvBrowser() {
	return !(window as Window & { invokeNative?: unknown }).invokeNative
}

const NUI_TIMEOUT_MS = 5_000

async function fetchWithTimeout<T>(url: string, options: RequestInit): Promise<T> {
	const controller = new AbortController()
	const timer = setTimeout(() => controller.abort(), NUI_TIMEOUT_MS)

	try {
		const response = await fetch(url, { ...options, signal: controller.signal })
		if (!response.ok) {
			throw new Error(`NUI callback failed: ${url}`)
		}
		try {
			return (await response.json()) as T
		} catch {
			return {} as T
		}
	} finally {
		clearTimeout(timer)
	}
}

export async function fetchParentNui<T = unknown>(event: string, data?: unknown): Promise<T> {
	if (isEnvBrowser()) {
		return {} as T
	}

	return fetchWithTimeout<T>(`https://${RESOURCE_NAME}/${event}`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json; charset=UTF-8' },
		body: JSON.stringify(data ?? {}),
	})
}

export async function fetchNui<T = unknown>(event: string, data?: unknown): Promise<T> {
	if (isEnvBrowser()) {
		return {} as T
	}

	const callbackName = nuiEventPrefix ? `${nuiEventPrefix}${event}` : event

	return fetchWithTimeout<T>(`https://${RESOURCE_NAME}/${callbackName}`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json; charset=UTF-8' },
		body: JSON.stringify(data ?? {}),
	})
}

export function padTime(value: number | string) {
	const num = Number(value)
	if (Number.isNaN(num)) return String(value)
	return num < 10 ? `0${num}` : String(num)
}

export function dispTime(time: number) {
	const days = Math.floor(time / 86400)
	let remaining = time % 86400
	let hours = Math.floor(remaining / 3600)
	remaining %= 3600
	const minutes = Math.floor(remaining / 60)
	remaining %= 60
	const seconds = remaining

	if (days > 0) {
		hours += days * 24
	}

	return {
		Hours: padTime(hours),
		Minutes: padTime(minutes),
		Seconds: padTime(seconds),
		OsTime: time,
	}
}
