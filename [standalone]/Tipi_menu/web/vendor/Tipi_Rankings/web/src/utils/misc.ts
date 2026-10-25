export const isEnvBrowser = (): boolean => !(window as any).invokeNative

export const noop = () => {}

export function formatNumber(value: number): string {
	return new Intl.NumberFormat('vi-VN').format(value)
}

export function cn(...classes: (string | false | null | undefined)[]): string {
	return classes.filter(Boolean).join(' ')
}
