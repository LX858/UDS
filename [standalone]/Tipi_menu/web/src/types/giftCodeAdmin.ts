export type GiftCreateMode = 'random' | 'fixed' | 'bundle'
export type GiftRewardType = 'item' | 'vehicle' | 'clothing'
export type GiftBundleItemType = 'item' | 'clothing'

export interface ClothingComponentOption {
	key: string
	label: string
	itemname?: string
}

export interface GiftBundleItem {
	type: GiftBundleItemType
	name: string
	count: number
	component?: string
	maleDrawable?: number
	femaleDrawable?: number
	texture?: number
	autoGender?: boolean
}

export interface GiftCodeCreatePayload {
	mode: GiftCreateMode
	code?: string
	type?: GiftRewardType
	name?: string
	count?: number
	component?: string
	maleDrawable?: number
	femaleDrawable?: number
	texture?: number
	autoGender?: boolean
	items?: GiftBundleItem[]
	remaining: number
	minLevel: number
	expireHours: number
	announceToPlayers?: boolean
	announceTitle?: string
}

export interface GiftCodeCreateResult {
	status: boolean
	message: string
	data?: { code?: string }
}

export interface GiftClothingComponentsResult {
	status: boolean
	message?: string
	components: ClothingComponentOption[]
}
