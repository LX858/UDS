export type BoardThemeId = 'gang' | 'bus' | 'police' | 'ems' | 'mechanic' | 'player' | 'default'

export interface BoardSummary {
	id: string
	label: string
	description?: string
	icon?: string
	order?: number
	theme?: BoardThemeId
}

export interface LeaderboardEntry {
	rank: number
	name: string
	label: string
	level: number
	value: number
	logoUrl?: string
	slogan?: string
	rankDelta?: number
}

export interface LeaderboardBranding {
	seasonTagline?: string
	logoUrl?: string
}

export interface LeaderboardPlayerContext {
	myEntryKey?: string
	myRank?: number
	myValue?: number
	myLabel?: string
	inTopList?: boolean
}

export interface LeaderboardData {
	boardId: string
	label: string
	description?: string
	entryType: 'gang' | 'player'
	valueLabel: string
	entries: LeaderboardEntry[]
	listLimit?: number
	updatedAt: number
	theme?: BoardThemeId
	branding?: LeaderboardBranding
	player?: LeaderboardPlayerContext
}

export interface LeaderboardResponse {
	success: boolean
	data?: LeaderboardData
	error?: string
}

export interface VisiblePayload {
	visible: boolean
	boardId?: string
	boards?: BoardSummary[]
	branding?: LeaderboardBranding
}
