export type RewardType =
	| 'common'
	| 'rare'
	| 'epic'
	| 'goldcommon'
	| 'goldrare'
	| 'goldepic'
	| 'specialgold'

export type RewardStatus =
	| 'undiscovered'
	| 'online_grinding'
	| 'online_ready'
	| 'usual'
	| 'missed_claimable'
	| 'missed_limit'
	| 'collected'
	| 'vip_locked'

export type CheckInTrack = 'normal' | 'vip'

export interface RewardConfig {
	type?: RewardType
	itemName: string
	itemLabel: string
	itemCount: number
	itemType: string
	clothComponent?: string
	clothDrawable?: number
	clothTexture?: number
	clothSex?: 'male' | 'female' | ''
}

export type ClothingComponentOption = {
	key: string
	label: string
	itemname?: string
	component?: number
	prop?: boolean
}

export interface Locales {
	Daily: string
	Rewards: string
	Description: string
	Day: string
	Hours: string
	Minutes: string
	Seconds: string
	Collect: string
	Open: string
	Progress?: string
	Checked?: string
	Today?: string
	TimerRemaining?: string
	Close?: string
	ClaimStreak?: string
	ResetDaily?: string
	MysteryReward?: string
	MissedLimitReached?: string
	MissedFreeClaim?: string
	ClaimBusy?: string
	ClaimFailed?: string
	AlreadyClaimed?: string
	MissedDayPrice?: string
	MissedDayHint?: string
	MissedDayNeedMoney?: string
	MissedDayPaid?: string
	TabNormal?: string
	TabVip?: string
	VipLocked?: string
	VipBuy?: string
	VipOwned?: string
	VipPrice?: string
	VipNeedPack?: string
	NotYetAvailable?: string
	NotYetEligible?: string
	StreakTitle?: string
	StreakCurrent?: string
	RuleOnline?: string
	RuleMissed?: string
	RuleVip?: string
	StatusReady?: string
	StatusDone?: string
	StatusNeedOnline?: string
}

export interface TimeParts {
	Hours: string | number
	Minutes: string | number
	Seconds: string | number
	OsTime: number
}

export interface PlayerRewardData {
	playerData: {
		collected: string
		usual: string
		daily_online?: string
	}
	todayReward: number
	tomorrowDate: TimeParts
	onlineMinutes?: number
	presentToday?: boolean
	items?: Record<string, RewardConfig>
	vipItems?: Record<string, RewardConfig>
	hasVipPack?: boolean
	vipPackPrice?: number
	missedDayClaimEnabled?: boolean
	missedDayClaimPrice?: number
	missedDayClaimBasePrice?: number
	missedDayClaimMultiplier?: number
	missedDayClaimMoneyType?: string
	missedClaimPricePreview?: Array<{ claim: number; price: number }>
	nextMissedClaimPrice?: number
	monthKey?: string
	daysInMonth?: number
	calendarYear?: number
	calendarMonth?: number
	monthCollected?: Record<string, boolean>
	vipMonthCollected?: Record<string, boolean>
	monthEligibleDays?: Record<string, boolean>
	monthFreeDays?: Record<string, boolean>
	missedClaimsCount?: number
	maxMissedClaimsPerMonth?: number
	streak?: StreakPayload
}

export interface OnlineSyncData {
	onlineMinutes: number
	todayReward?: number
	presentToday?: boolean
	monthEligibleDays?: Record<string, boolean>
	hasVipPack?: boolean
	vipPackPrice?: number
	streak?: StreakPayload
}

export interface StreakMilestoneState {
	days: number
	claimed: boolean
	ready: boolean
	reward?: RewardConfig
}

export interface StreakPayload {
	current: number
	milestones: StreakMilestoneState[]
	fromTemplate?: boolean
}

export interface VipPackBoughtData {
	ok: boolean
	hasVipPack?: boolean
	vipPackPrice?: number
	vipItems?: Record<string, RewardConfig>
	vipMonthCollected?: Record<string, boolean>
	error?: string
}

export interface SelectedReward {
	day: number
	type?: RewardType
	itemName: string
	itemLabel: string
	itemCount?: number
	itemType?: string
	clothComponent?: string
	clothDrawable?: number
	clothSex?: string
	kind: 'streak' | 'vip' | 'chain'
}

export interface NuiMessage {
	type: string
	bool?: 'open' | 'close' | 'update' | 'syncOnline' | 'milestoneHud' | 'vipPackBought'
	items?: Record<string, RewardConfig>
	data?: PlayerRewardData | OnlineSyncData | VipPackBoughtData | Record<string, unknown>
	minutes?: number
	locales?: Locales
	daysInMonth?: number
	monthKey?: string
	calendarYear?: number
	calendarMonth?: number
	mysteryImageUrl?: string
	inventoryImageTemplate?: string
	inventoryImageCdn?: string
	itemImageResourceTemplate?: string
	clothingImageUrl?: string
	clothingImageExt?: string
}

declare global {
	interface Window {
		GetParentResourceName?: () => string
	}
}

export {}
