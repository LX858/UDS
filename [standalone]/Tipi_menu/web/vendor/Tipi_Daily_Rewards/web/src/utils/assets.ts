import type { ClothingComponentOption, RewardType } from '../types'
import { isEnvBrowser } from './nui'

let embeddedResourceName: string | null = null
let embedAssetBase: string | null = null
let assetRevision = 0
const assetRevisionListeners = new Set<() => void>()
let mysteryImageUrl = ''
let inventoryImageTemplate = 'nui://ox_inventory/web/images/%s.webp'
let inventoryImageCdn =
	'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp'
let itemImageResourceTemplate = ''
let clothingImageUrl = 'https://raw.githubusercontent.com/xuannguyen995/miniclothing/refs/heads/main'
let clothingImageExt = 'webp'
let clothingCatalog: ClothingComponentOption[] = []

const BROWSER_EMBED_BASE = '/images/daily-rewards'
const GAME_EMBED_BASE = './images/daily-rewards'
const BROWSER_STANDALONE_BASE = '/images'
const DEFAULT_CLOTHING_MAP: Record<string, { component: number; prop: boolean }> = {
	hat: { component: 0, prop: true },
	mask: { component: 1, prop: false },
	glasses: { component: 1, prop: true },
	chain: { component: 7, prop: false },
	gloves: { component: 3, prop: false },
	torso: { component: 11, prop: false },
	watch: { component: 6, prop: true },
	pants: { component: 4, prop: false },
	earrings: { component: 2, prop: true },
	bag: { component: 5, prop: false },
	shirt: { component: 8, prop: false },
	vest: { component: 9, prop: false },
	bracelets: { component: 7, prop: true },
	shoes: { component: 6, prop: false },
}

function bumpAssetRevision() {
	assetRevision += 1
	assetRevisionListeners.forEach((listener) => listener())
}

export function getAssetRevision() {
	return assetRevision
}

export function subscribeAssetRevision(listener: () => void) {
	assetRevisionListeners.add(listener)
	return () => {
		assetRevisionListeners.delete(listener)
	}
}

export function setEmbeddedResourceName(name: string | null) {
	if (embeddedResourceName === name) return
	embeddedResourceName = name
	bumpAssetRevision()
}

export function setEmbedAssetBase(base: string | null) {
	if (embedAssetBase === base) return
	embedAssetBase = base
	bumpAssetRevision()
}

function getEmbedBase() {
	if (embedAssetBase) return embedAssetBase
	if (embeddedResourceName) return isEnvBrowser() ? BROWSER_EMBED_BASE : GAME_EMBED_BASE
	return null
}

function getStandaloneImageBase() {
	return isEnvBrowser() ? BROWSER_STANDALONE_BASE : './images'
}

export function assetUrl(path: string) {
	const clean = path.replace(/^\.\//, '').replace(/^\//, '')
	const embedBase = getEmbedBase()

	if (embedBase) {
		if (clean.startsWith('images/')) {
			return `${embedBase}/${clean.replace(/^images\//, '')}`
		}
		return `${embedBase}/${clean}`
	}

	if (isEnvBrowser()) {
		return `/${clean}`
	}

	if (embeddedResourceName) {
		return `nui://${embeddedResourceName}/web/build/${clean}`
	}

	return `./${clean}`
}

export function getMysteryRewardImage() {
	if (mysteryImageUrl) return mysteryImageUrl
	const localBase = getEmbedBase()
	if (localBase) return `${localBase}/common.png`
	return `${getStandaloneImageBase()}/common.png`
}

export const DEFAULT_MYSTERY_REWARD_IMAGE = `${BROWSER_STANDALONE_BASE}/common.png`
export const DEFAULT_INVENTORY_IMAGE_TEMPLATE = 'nui://ox_inventory/web/images/%s.webp'
export const DEFAULT_INVENTORY_IMAGE_CDN =
	'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp'
export const MYSTERY_GIFT_IMAGE = DEFAULT_MYSTERY_REWARD_IMAGE

export function setAssetConfig(config: {
	mysteryImageUrl?: string
	inventoryImageTemplate?: string
	inventoryImageCdn?: string
	itemImageResourceTemplate?: string
	clothingImageUrl?: string
	clothingImageExt?: string
	clothingComponents?: ClothingComponentOption[]
}) {
	let changed = false
	if (config.mysteryImageUrl?.trim() && mysteryImageUrl !== config.mysteryImageUrl.trim()) {
		mysteryImageUrl = config.mysteryImageUrl.trim()
		changed = true
	}
	if (config.inventoryImageTemplate && inventoryImageTemplate !== config.inventoryImageTemplate) {
		inventoryImageTemplate = config.inventoryImageTemplate
		changed = true
	}
	if (config.inventoryImageCdn && inventoryImageCdn !== config.inventoryImageCdn) {
		inventoryImageCdn = config.inventoryImageCdn
		changed = true
	}
	if (config.itemImageResourceTemplate && itemImageResourceTemplate !== config.itemImageResourceTemplate) {
		itemImageResourceTemplate = config.itemImageResourceTemplate
		changed = true
	}
	if (config.clothingImageUrl?.trim()) {
		const next = config.clothingImageUrl.trim().replace(/\/$/, '')
		if (clothingImageUrl !== next) {
			clothingImageUrl = next
			changed = true
		}
	}
	if (config.clothingImageExt?.trim()) {
		const next = config.clothingImageExt.trim().replace(/^\./, '')
		if (clothingImageExt !== next) {
			clothingImageExt = next
			changed = true
		}
	}
	if (config.clothingComponents?.length) {
		clothingCatalog = config.clothingComponents
		changed = true
	}
	if (changed) bumpAssetRevision()
}

export function getClaimSoundUrl() {
	return assetUrl('sounds/effect.mp3')
}

function resolveClothingMeta(key?: string) {
	const clean = (key || '').trim()
	if (!clean) return null
	const fromCatalog = clothingCatalog.find((item) => item.key === clean)
	if (fromCatalog && typeof fromCatalog.component === 'number') {
		return { component: fromCatalog.component, prop: Boolean(fromCatalog.prop) }
	}
	return DEFAULT_CLOTHING_MAP[clean] || null
}

function clothingFileName(sex: 'male' | 'female', componentId: number, drawable: number, isProp: boolean) {
	const mid = isProp ? '_prop_' : '_'
	return `${sex}${mid}${componentId}_${drawable}.${clothingImageExt}`
}

export type ClothingImageOpts = {
	clothComponent?: string
	itemName?: string
	clothDrawable?: number
	clothSex?: string
}

export function getClothingImageCandidates(opts: ClothingImageOpts) {
	const candidates: string[] = []
	const key = opts.clothComponent || opts.itemName
	const meta = resolveClothingMeta(key)
	const drawable = Math.max(1, Math.floor(Number(opts.clothDrawable) || 1))
	const preferredSex = opts.clothSex === 'female' ? 'female' : opts.clothSex === 'male' ? 'male' : null

	if (meta && clothingImageUrl) {
		const sexes: Array<'male' | 'female'> = preferredSex
			? [preferredSex, preferredSex === 'male' ? 'female' : 'male']
			: ['male', 'female']
		for (const sex of sexes) {
			candidates.push(
				`${clothingImageUrl}/${clothingFileName(sex, meta.component, drawable, meta.prop)}`,
			)
		}
	}

	candidates.push(getMysteryRewardImage())
	return [...new Set(candidates.filter(Boolean))]
}	

function isMoneyRewardImage(opts: { itemType?: string; itemName?: string }) {
	const type = (opts.itemType || '').toLowerCase()
	const name = (opts.itemName || '').toLowerCase()
	return type === 'cash' || type === 'money' || name === 'cash' || name === 'money'
}

export function getRewardImageCandidates(opts: {
	itemType?: string
	itemName?: string
	clothComponent?: string
	clothDrawable?: number
	clothSex?: string
	mystery?: boolean
}) {
	if (opts.mystery) return [getMysteryRewardImage()]
	if (opts.itemType === 'clothing') {
		return getClothingImageCandidates(opts)
	}
	if (isMoneyRewardImage(opts)) {
		return [
			// CDN trước — ổn định khi embed Tipi_menu thiếu file local
			'https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/money.webp',
			assetUrl('images/money.svg'),
			inventoryImageTemplate.replace('%s', 'money'),
			getMysteryRewardImage(),
		]
	}
	return getInventoryItemImageCandidates(opts.itemName || '')
}

export function getInventoryItemImageCandidates(itemName: string) {
	const candidates: string[] = []
	const localBase = getEmbedBase()
	const safeName = (itemName || '').trim()

	if (!isEnvBrowser()) {
		if (safeName) {
			candidates.push(inventoryImageTemplate.replace('%s', safeName))
			if (itemImageResourceTemplate) {
				candidates.push(itemImageResourceTemplate.replace('%s', safeName))
			} else if (embeddedResourceName && !localBase) {
				candidates.push(`nui://${embeddedResourceName}/config/itemimages/${safeName}.png`)
			} else if (!localBase) {
				candidates.push(`../config/itemimages/${safeName}.png`)
			}
		}
	}

	if (localBase && safeName) {
		candidates.push(`${localBase}/items/${safeName}.png`)
	}

	if (safeName) {
		candidates.push(inventoryImageCdn.replace('%s', safeName))
	}

	// Browser / thiếu icon item → fallback hộp chung (tránh broken image)
	if (isEnvBrowser()) {
		candidates.push(`${localBase || getStandaloneImageBase()}/common.png`)
	} else if (localBase) {
		candidates.push(`${localBase}/common.png`)
	} else {
		candidates.push(getMysteryRewardImage())
	}

	return [...new Set(candidates.filter(Boolean))]
}

export function getInventoryItemImageUrl(itemName: string) {
	return getInventoryItemImageCandidates(itemName)[0]
}

export function getItemImageUrl(itemName: string, _type?: RewardType) {
	return getInventoryItemImageUrl(itemName)
}

export function getSpecialStarsEffectImage() {
	return assetUrl('images/specialstars_.png')
}

export function getSlicedCommonUpperImage() {
	return assetUrl('images/sliced-common_upper.png')
}

export function getSlicedCommonBottomImage() {
	return assetUrl('images/sliced-common_bottom.png')
}

export function getBackgroundImage() {
	return assetUrl('images/background.png')
}

export function getExitImage() {
	return assetUrl('images/exit.png')
}

export function getSpecialStarsImage() {
	return assetUrl('images/special-stars.png')
}

export const SPECIAL_STARS_EFFECT_IMAGE = `${BROWSER_STANDALONE_BASE}/specialstars_.png`
export const SLICED_COMMON_UPPER_IMAGE = `${BROWSER_STANDALONE_BASE}/sliced-common_upper.png`
export const SLICED_COMMON_BOTTOM_IMAGE = `${BROWSER_STANDALONE_BASE}/sliced-common_bottom.png`
export const BACKGROUND_IMAGE = `${BROWSER_STANDALONE_BASE}/background.png`
export const EXIT_IMAGE = `${BROWSER_STANDALONE_BASE}/exit.png`
export const SPECIAL_STARS_IMAGE = `${BROWSER_STANDALONE_BASE}/special-stars.png`
