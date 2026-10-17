export const formatCurrency = (value: number) => {
	return value.toLocaleString('vi-VN', {
		minimumFractionDigits: 0,
		maximumFractionDigits: 0
	})
}

export const formatNumber = (value: number | string): string => {
	return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
}

export const isValidNumber = (value: any): boolean => {
	return typeof value === 'number' && !isNaN(value) && isFinite(value)
}

export const parseCurrencyInput = (value: string): number => {
	const cleanValue = value.replace(/[^0-9]/g, '')
	return parseInt(cleanValue) || 0
}

export const formatCurrencyInput = (value: string): string => {
	const numericOnly = value.replace(/[^0-9]/g, '')
	if (!numericOnly) return ''

	const numericValue = parseInt(numericOnly)
	return `$${formatCurrency(numericValue)}`
}

export const getLevelName = (level: string | number) => {
	const levelMap: Record<string, string> = {
		'1': 'Cửu phẩm',
		'2': 'Bát phẩm',
		'3': 'Thất phẩm',
		'4': 'Lục phẩm',
		'5': 'Ngũ phẩm',
		'6': 'Tứ phẩm',
		'7': 'Tam phẩm',
		'8': 'Nhị phẩm',
		'9': 'Nhất phẩm',
		'10': 'Hoàng đế'
	}
	return levelMap[level.toString()] || level.toString()
}
