export const PRIME_ITEM_IMAGE_BASE =
	'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/'

export function getPrimeItemImageUrl(itemName: string): string {
	const id = String(itemName ?? '').trim()
	if (!id) return ''
	return `${PRIME_ITEM_IMAGE_BASE}${encodeURIComponent(id)}.webp`
}
